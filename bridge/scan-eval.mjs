#!/usr/bin/env node
// Scores the syllabus scanner against a folder of photos with answer keys.
//
//   node bridge/scan-eval.mjs [bridge/scan-fixtures]
//
// Each fixture is a photo (jpg/jpeg/png) next to a JSON file of the same name:
//   { "today": "2026-09-09", "rows": [ { "title": "Bio quiz ch 3-4", "date": "2026-09-12" }, ... ] }
//
// Needs bridge/config.local.json for the URL and key, and PREPKIN_SCAN_DEV_TOKEN
// in the environment (the same value set as the function's
// PARSE_SCHEDULE_DEV_TOKEN secret), so no App Store receipt is needed.
//
// A date is right when it matches exactly. A title is right when the expected
// title's words are mostly in the returned one. The plan's bar: 90% of dates.

import fs from "node:fs";
import path from "node:path";

const dir = process.argv[2] ?? path.join(path.dirname(new URL(import.meta.url).pathname), "scan-fixtures");
const cfgPath = path.join(path.dirname(new URL(import.meta.url).pathname), "config.local.json");
if (!fs.existsSync(cfgPath)) { console.error("bridge/config.local.json missing"); process.exit(2); }
const cfg = JSON.parse(fs.readFileSync(cfgPath, "utf8"));
const token = process.env.PREPKIN_SCAN_DEV_TOKEN;
if (!token) { console.error("PREPKIN_SCAN_DEV_TOKEN not set"); process.exit(2); }

const photos = fs.existsSync(dir)
  ? fs.readdirSync(dir).filter((f) => /\.(jpe?g|png)$/i.test(f)).sort()
  : [];
if (photos.length === 0) { console.error(`No photos in ${dir}. Add 20 syllabi and planner pages with answer keys first.`); process.exit(2); }

const norm = (s) => s.toLowerCase().replace(/[^a-z0-9 ]+/g, " ").split(/\s+/).filter(Boolean);
const titleMatches = (want, got) => {
  const w = norm(want), g = new Set(norm(got));
  const hit = w.filter((x) => g.has(x)).length;
  return w.length > 0 && hit / w.length >= 0.6;
};

let dates = 0, titles = 0, expected = 0, extra = 0;
for (const photo of photos) {
  const key = path.join(dir, photo.replace(/\.[^.]+$/, ".json"));
  if (!fs.existsSync(key)) { console.log(`skip ${photo}: no answer key`); continue; }
  const answer = JSON.parse(fs.readFileSync(key, "utf8"));
  const image = fs.readFileSync(path.join(dir, photo)).toString("base64");
  const res = await fetch(`${cfg.url}/functions/v1/parse_schedule`, {
    method: "POST",
    headers: { "Content-Type": "application/json", apikey: cfg.publishableKey, Authorization: `Bearer ${cfg.publishableKey}` },
    body: JSON.stringify({
      image, mediaType: /png$/i.test(photo) ? "image/png" : "image/jpeg",
      today: answer.today ?? new Date().toISOString().slice(0, 10),
      timeZone: "America/New_York", jws: "", devToken: token,
    }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) { console.log(`${photo}: ${res.status} ${body.error ?? ""}`); continue; }
  const got = body.rows ?? [];
  let d = 0, t = 0;
  const used = new Set();
  for (const want of answer.rows) {
    expected += 1;
    const i = got.findIndex((r, idx) => !used.has(idx) && r.date === want.date && titleMatches(want.title, r.title));
    if (i >= 0) { used.add(i); d += 1; t += 1; continue; }
    const j = got.findIndex((r, idx) => !used.has(idx) && r.date === want.date);
    if (j >= 0) { used.add(j); d += 1; }
  }
  dates += d; titles += t; extra += got.length - used.size;
  console.log(`${photo}: dates ${d}/${answer.rows.length}, titles ${t}/${answer.rows.length}, extra ${got.length - used.size}`);
}

const pct = (n) => expected ? `${Math.round((100 * n) / expected)}%` : "n/a";
console.log(`\nDates ${pct(dates)} (${dates}/${expected}), titles ${pct(titles)}, ${extra} rows nobody asked for.`);
console.log(dates / Math.max(expected, 1) >= 0.9 ? "Bar met: 90% of dates." : "Under the bar. The prompt is not done.");
