// parse_schedule — a photo of a syllabus, whiteboard or planner page in, dated
// rows out. Plus only, 50 a month per subscriber.
//
// Supabase edge function (Deno). Deploy and secrets: design/CALENDAR-PLAN.md,
// "Deploying the scanner".
//
// What comes in:  { image (base64 JPEG/PNG), mediaType, today (YYYY-MM-DD),
//                   timeZone, jws (signed App Store transaction), devToken }
// What goes out:  { rows: [{title, date, time?, course?, confidence}],
//                   remaining, limit, note? }
//
// The photo is read once and never stored. The only thing this function keeps
// is a count per subscriber per month, keyed on the App Store's
// originalTransactionId, so a reinstall or a second phone shares the same 50.

import Anthropic from "npm:@anthropic-ai/sdk@0.60.0";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";
import { X509Certificate } from "npm:@peculiar/x509@1";

const LIMIT = 50;
const MODEL = "claude-sonnet-5";
const BUNDLE_ID = "com.prepkin.canvas";
const PRODUCT_PREFIX = "com.prepkin.canvas.plus.";
// Apple Root CA - G3, the root every App Store transaction chain ends in.
// Overridable so a rotated root is a secret change, not a redeploy.
const APPLE_ROOT_SHA256 = (Deno.env.get("APPLE_ROOT_SHA256") ??
  "63343ABFB89A6A03EBB57E9B3F5FA7BE7C4F5C756F3017B3A8C488C3653E9179").toUpperCase();

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Row = { title: string; date: string; time?: string | null; course?: string | null; confidence: number };

const SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["rows", "note"],
  properties: {
    rows: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["title", "date", "time", "course", "confidence"],
        properties: {
          title: { type: "string", description: "Short, as a student would write it. 'Bio quiz ch 3-4', not 'Quiz covering chapters three and four'." },
          date: { type: "string", description: "YYYY-MM-DD. The day it is due or happens." },
          time: { type: ["string", "null"], description: "HH:MM 24-hour, only when the page says a time." },
          course: { type: ["string", "null"], description: "Course name if the page names one, else null." },
          confidence: { type: "number", description: "0 to 1. Below 0.5 means you guessed the date or the title." },
        },
      },
    },
    note: { type: ["string", "null"], description: "One short line when there are no rows: what the page is instead." },
  },
} as const;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function fail(status: number, code: string, error: string, extra: Record<string, unknown> = {}): Response {
  return json(status, { code, error, ...extra });
}

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  const d = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
}

/// Checks a StoreKit 2 signed transaction the way Apple's server library does:
/// the x5c chain ends in Apple's root, each link signs the next, and the leaf
/// key signs the JWS. Returns the subscriber id, or a reason it failed.
async function verifyPlus(jws: string, allowSandbox: boolean): Promise<{ subscriber: string } | { reason: string }> {
  let header: jose.ProtectedHeaderParameters;
  try {
    header = jose.decodeProtectedHeader(jws);
  } catch {
    return { reason: "unreadable" };
  }
  const chain = header.x5c;
  if (!Array.isArray(chain) || chain.length < 2 || header.alg !== "ES256") return { reason: "no chain" };

  const certs = chain.map((b64) => new X509Certificate(b64));
  const root = certs[certs.length - 1];
  const rootHash = await sha256Hex(new Uint8Array(root.rawData));
  if (rootHash !== APPLE_ROOT_SHA256) return { reason: "not Apple's root" };

  const now = new Date();
  for (let i = 0; i < certs.length; i += 1) {
    const cert = certs[i];
    if (cert.notBefore > now || cert.notAfter < now) return { reason: "certificate expired" };
    const issuer = certs[i + 1] ?? cert; // the root signs itself
    const ok = await cert.verify({ publicKey: await issuer.publicKey.export(), signatureOnly: true });
    if (!ok) return { reason: "broken chain" };
  }

  let payload: Record<string, unknown>;
  try {
    const leafKey = await jose.importX509(certs[0].toString("pem"), "ES256");
    const verified = await jose.compactVerify(jws, leafKey);
    payload = JSON.parse(new TextDecoder().decode(verified.payload));
  } catch {
    return { reason: "bad signature" };
  }

  if (payload.bundleId !== BUNDLE_ID) return { reason: "wrong app" };
  if (typeof payload.productId !== "string" || !payload.productId.startsWith(PRODUCT_PREFIX)) return { reason: "not a Plus product" };
  if (payload.revocationDate) return { reason: "refunded" };
  if (typeof payload.expiresDate === "number" && payload.expiresDate < Date.now()) return { reason: "expired" };
  if (payload.environment === "Sandbox" && !allowSandbox) return { reason: "sandbox" };
  const original = payload.originalTransactionId;
  if (typeof original !== "string" && typeof original !== "number") return { reason: "no subscriber id" };
  return { subscriber: `apple:${original}` };
}

/// "2026-09-09" → "2026-09", and the first of next month for the reset line.
function monthOf(today: string): { month: string; resetsOn: string } {
  const [y, m] = today.split("-").map(Number);
  const month = `${y}-${String(m).padStart(2, "0")}`;
  const next = new Date(Date.UTC(y, m, 1)); // month is 1-based here, so this is next month
  const resetsOn = next.toLocaleDateString("en-US", { month: "short", day: "numeric", timeZone: "UTC" });
  return { month, resetsOn };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return fail(405, "method", "POST only");

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return fail(400, "bad_request", "Body must be JSON.");
  }
  const image = typeof body.image === "string" ? body.image : "";
  const mediaType = body.mediaType === "image/png" ? "image/png" : "image/jpeg";
  const today = typeof body.today === "string" && /^\d{4}-\d{2}-\d{2}$/.test(body.today)
    ? body.today
    : new Date().toISOString().slice(0, 10);
  const timeZone = typeof body.timeZone === "string" ? body.timeZone : "UTC";
  if (!image || image.length < 1000) return fail(400, "bad_image", "No photo in the request.");
  if (image.length > 8_000_000) return fail(413, "bad_image", "That photo is too big.");

  // Who is asking, and are they Plus.
  const devToken = Deno.env.get("PARSE_SCHEDULE_DEV_TOKEN");
  let subscriber: string;
  if (devToken && typeof body.devToken === "string" && body.devToken.length > 0 && body.devToken === devToken) {
    subscriber = `dev:${await sha256Hex(new TextEncoder().encode(devToken))}`;
  } else {
    const jws = typeof body.jws === "string" ? body.jws : "";
    if (!jws) return fail(402, "not_plus", "Scanning is a Plus feature.");
    const check = await verifyPlus(jws, Deno.env.get("ALLOW_SANDBOX_RECEIPTS") === "true");
    if ("reason" in check) return fail(402, "not_plus", `Plus didn't check out (${check.reason}).`);
    subscriber = check.subscriber;
  }

  // The monthly tally, in the student's own month.
  const { month, resetsOn } = monthOf(today);
  const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: count, error: tallyError } = await supabase.rpc("bump_scan", {
    p_subscriber: subscriber,
    p_month: month,
    p_limit: LIMIT,
  });
  if (tallyError) return fail(500, "server", "Couldn't check the monthly count.");
  if (typeof count !== "number" || count < 0) {
    return fail(429, "limit", `That's ${LIMIT} this month. Resets ${resetsOn}.`, { resetsOn, limit: LIMIT, remaining: 0 });
  }
  const remaining = Math.max(0, LIMIT - count);

  // Read the page.
  const client = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });
  const prompt = [
    `Today is ${today} in the ${timeZone} time zone. Read this photo of a page a student took: a syllabus, a course schedule, a whiteboard, a planner, a handout. It may be printed or handwritten.`,
    `Pull out every dated thing a student has to do or be at: assignments, readings, quizzes, tests, exams, projects, presentations, labs, class meetings with a stated date, deadlines. One row each.`,
    `Rules:`,
    `- Resolve every date to YYYY-MM-DD. "Fri 9/12" → the Friday nearest today's academic year. "Next Monday" is relative to today. A weekday with no date is the next one on or after today. If only a month and day are given, pick the year that puts it on or after ${today.slice(0, 4)}-08-01 and before the following August.`,
    `- A time only when the page says one, as HH:MM in 24-hour.`,
    `- Keep titles short and in the student's words. Include chapter or section numbers.`,
    `- Skip rows with no date at all. Skip grading policies, office hours with no date, and general rules.`,
    `- Course: the course name if the page shows one, else null.`,
    `- confidence: 1.0 when the date and title are clearly printed, lower when you inferred either, below 0.5 when it is a guess.`,
    `- If the page has no dated items, return an empty rows list and one short note saying what the page is instead.`,
  ].join("\n");

  let parsed: { rows: Row[]; note: string | null };
  try {
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 4096,
      messages: [{
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: mediaType, data: image } },
          { type: "text", text: prompt },
        ],
      }],
      output_config: { format: { type: "json_schema", schema: SCHEMA } },
    });
    const text = response.content.find((b) => b.type === "text");
    if (!text || text.type !== "text") throw new Error("no text");
    parsed = JSON.parse(text.text);
  } catch (err) {
    console.error("claude", err);
    return fail(502, "server", "The reader is down. Try again in a bit.");
  }

  const rows = (parsed.rows ?? [])
    .filter((r) => r && typeof r.title === "string" && r.title.trim() && /^\d{4}-\d{2}-\d{2}$/.test(r.date))
    .map((r) => ({
      title: r.title.trim().slice(0, 120),
      date: r.date,
      time: typeof r.time === "string" && /^\d{2}:\d{2}$/.test(r.time) ? r.time : null,
      course: typeof r.course === "string" && r.course.trim() ? r.course.trim().slice(0, 60) : null,
      confidence: typeof r.confidence === "number" ? Math.min(1, Math.max(0, r.confidence)) : 0.5,
    }))
    .slice(0, 80);

  return json(200, { rows, remaining, limit: LIMIT, note: rows.length ? null : parsed.note ?? null });
});
