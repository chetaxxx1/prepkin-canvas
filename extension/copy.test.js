const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const ALLOWLIST = [
  // This allowlist must stay empty.
];

test('extension copy avoids forbidden progress language', () => {
  const forbidden = new RegExp(`\\b${'stre'}${'ak'}\\b`, 'i');
  const files = fs.readdirSync(__dirname, { withFileTypes: true })
    .filter((entry) => entry.isFile() && ['.js', '.html', '.css'].includes(path.extname(entry.name)))
    .map((entry) => entry.name)
    .filter((name) => !ALLOWLIST.includes(name));
  for (const file of files) {
    const source = fs.readFileSync(path.join(__dirname, file), 'utf8')
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/<!--[\s\S]*?-->/g, '')
      .replace(/\/\/.*$/gm, '');
    assert.ok(!forbidden.test(source), file);
  }
});
