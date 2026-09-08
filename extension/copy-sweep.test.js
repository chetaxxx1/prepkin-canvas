// Run with: node --test extension/copy-sweep.test.js
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const BANNED = /\b(sync|syncing|bridge|endpoint|selector|api|token|schema|payload)\b/i;
const DIR = __dirname;

/// Exact literals that cannot be reworded away. Prefer fixing copy instead.
const ALLOWLIST = new Map([
  // Bundled-config console line — path mention, never UI.
  ['Prepkin: no config.js — run bridge/apply-config.sh', 'setup path in console.warn only'],
]);

function stripComments(text) {
  let out = '';
  let i = 0;
  while (i < text.length) {
    if (text.startsWith('<!--', i)) {
      const end = text.indexOf('-->', i + 4);
      i = end < 0 ? text.length : end + 3;
      continue;
    }
    if (text.startsWith('/*', i)) {
      const end = text.indexOf('*/', i + 2);
      i = end < 0 ? text.length : end + 2;
      continue;
    }
    if (text.startsWith('//', i)) {
      const end = text.indexOf('\n', i);
      i = end < 0 ? text.length : end;
      continue;
    }
    // Keep string bodies intact so `https://` is not eaten as a comment.
    if (text[i] == "'" || text[i] == '"') {
      const end = skipQuoted(text, i);
      out += text.slice(i, end);
      i = end;
      continue;
    }
    if (text[i] == '`') {
      const { end } = readTemplate(text, i);
      out += text.slice(i, end);
      i = end;
      continue;
    }
    out += text[i];
    i += 1;
  }
  return out;
}

/// Skip a quoted string starting at i (quote already at text[i]). Returns end index.
/// A quote with no partner on its line (a `"` inside a regex literal, say) is
/// not a string: the caller gets `start + 1` and moves on.
function skipQuoted(text, i) {
  const q = text[i];
  const start = i;
  i += 1;
  while (i < text.length) {
    if (text[i] == '\n') return start + 1;
    if (text[i] == '\\') { i += 2; continue; }
    if (text[i] == q) return i + 1;
    i += 1;
  }
  return start + 1;
}

/// Skip a template literal starting at backtick text[i]. Returns { end, staticText }.
function readTemplate(text, i) {
  let staticText = '';
  i += 1; // past `
  while (i < text.length) {
    if (text[i] == '\\') {
      staticText += text[i] + (text[i + 1] ?? '');
      i += 2;
      continue;
    }
    if (text[i] == '`') return { end: i + 1, staticText };
    if (text[i] == '$' && text[i + 1] == '{') {
      i += 2;
      let depth = 1;
      while (i < text.length && depth > 0) {
        const c = text[i];
        if (c == "'" || c == '"') { i = skipQuoted(text, i); continue; }
        if (c == '`') {
          const nested = readTemplate(text, i);
          i = nested.end;
          continue;
        }
        if (c == '{') depth += 1;
        if (c == '}') {
          depth -= 1;
          if (depth == 0) { i += 1; break; }
        }
        i += 1;
      }
      continue;
    }
    staticText += text[i];
    i += 1;
  }
  return { end: i, staticText };
}

function extractJsStrings(text) {
  const found = [];
  let i = 0;
  while (i < text.length) {
    const c = text[i];
    if (c == "'" || c == '"') {
      const before = text.slice(Math.max(0, i - 40), i);
      const start = i;
      i = skipQuoted(text, i);
      if (i == start + 1) continue;
      let raw = text.slice(start + 1, i - 1);
      raw = raw.replace(/\\(.)/g, '$1');
      found.push({ value: raw, before });
      continue;
    }
    if (c == '`') {
      const before = text.slice(Math.max(0, i - 40), i);
      const { end, staticText } = readTemplate(text, i);
      found.push({ value: staticText.replace(/\\(.)/g, '$1'), before });
      i = end;
      continue;
    }
    i += 1;
  }
  return found;
}

function skipJsLiteral(value, before) {
  if (ALLOWLIST.has(value)) return true;
  if (/console\.(warn|log|error)\s*\(\s*$/.test(before)) return true;
  if (value.startsWith('/') || value.startsWith('http') || value.startsWith('https')) return true;
  if (!/\s/.test(value)) return true;
  return false;
}

function extractHtmlCopy(html) {
  const without = html
    .replace(/<style\b[\s\S]*?<\/style>/gi, '')
    .replace(/<script\b[\s\S]*?<\/script>/gi, '');
  const attrs = [];
  for (const m of without.matchAll(/\b(?:title|placeholder|aria-label|alt)\s*=\s*("([^"]*)"|'([^']*)')/gi)) {
    attrs.push(m[2] ?? m[3] ?? '');
  }
  const texts = [];
  const stripped = without.replace(/<[^>]+>/g, '\0');
  for (const part of stripped.split('\0')) {
    const t = part.replace(/\s+/g, ' ').trim();
    if (t) texts.push(t);
  }
  return [...attrs, ...texts];
}

function violationsIn(value) {
  const hits = [];
  if (value.includes('!')) hits.push('!');
  const m = value.match(BANNED);
  if (m) hits.push(m[0]);
  return hits;
}

test('extension copy has no ! or banned engineering words', () => {
  const files = fs.readdirSync(DIR)
    .filter((n) => (n.endsWith('.js') || n.endsWith('.html')) && !n.endsWith('.test.js'))
    .map((n) => path.join(DIR, n))
    .filter((p) => fs.statSync(p).isFile());

  const failures = [];
  for (const file of files) {
    const name = path.basename(file);
    const raw = fs.readFileSync(file, 'utf8');
    const text = stripComments(raw);

    if (name.endsWith('.js')) {
      for (const { value, before } of extractJsStrings(text)) {
        if (skipJsLiteral(value, before)) continue;
        const hits = violationsIn(value);
        if (hits.length) {
          failures.push(`${name}: ${hits.join(',')}: ${JSON.stringify(value).slice(0, 100)}`);
        }
      }
    }

    if (name.endsWith('.html')) {
      for (const value of extractHtmlCopy(text)) {
        if (ALLOWLIST.has(value)) continue;
        const hits = violationsIn(value);
        if (hits.length) {
          failures.push(`${name}: ${hits.join(',')}: ${JSON.stringify(value).slice(0, 100)}`);
        }
      }
    }
  }

  assert.equal(failures.length, 0, failures.join('\n'));
});
