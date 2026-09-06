// Drives the extension's real action popup.
//
// Playwright never attaches to an action popup, and opening popup.html in a
// tab is refused by the service worker's sender gate — correctly, since a tab
// is not the popup. So the popup is opened for real with chrome.action.openPopup()
// and driven over Chrome's own DevTools protocol through the debugging port the
// harness turns on.

const fs = require('fs');
const path = require('path');

const wait = (ms) => new Promise((r) => setTimeout(r, ms));

async function openPopup(h) {
  const port = fs.readFileSync(path.join(h.tmp, 'profile', 'DevToolsActivePort'), 'utf8').split('\n')[0];
  await h.sw(() => chrome.action.openPopup());
  let target = null;
  for (let i = 0; i < 50 && !target; i += 1) {
    const list = await fetch(`http://127.0.0.1:${port}/json/list`).then((r) => r.json());
    target = list.find((t) => t.url.includes('popup.html'));
    if (!target) await wait(100);
  }
  if (!target) throw new Error('the popup never appeared');

  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });
  let seq = 0;
  const pending = new Map();
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && pending.has(d.id)) { pending.get(d.id)(d); pending.delete(d.id); }
  };
  // The popup can close itself (window.close after a click). Anything still
  // waiting on it gets an empty answer instead of hanging forever.
  ws.onclose = () => { for (const f of pending.values()) f({ closed: true }); pending.clear(); };
  const send = (method, params) => new Promise((r) => {
    const id = ++seq;
    pending.set(id, r);
    ws.send(JSON.stringify({ id, method, params }));
  });
  const evaluate = async (expression) => {
    const r = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    if (r.result?.exceptionDetails) throw new Error(r.result.exceptionDetails.text);
    return r.result?.result?.value;
  };
  const q = (sel) => `document.querySelector(${JSON.stringify(sel)})`;

  const p = {
    evaluate,
    text: (sel) => evaluate(`${q(sel)}?.textContent ?? null`),
    value: (sel) => evaluate(`${q(sel)}?.value ?? null`),
    fill: (sel, v) => evaluate(`(() => { const el = ${q(sel)}; el.value = ${JSON.stringify(v)}; el.dispatchEvent(new Event('input', { bubbles: true })); return true; })()`),
    click: (sel) => evaluate(`(() => { const el = ${q(sel)}; if (!el) throw new Error('no ' + ${JSON.stringify(sel)}); el.click(); return true; })()`),
    /// Waits for `sel` to exist, and if `re` is given, for its text to match.
    waitFor: async (sel, re = null, ms = 8000) => {
      const t0 = Date.now();
      while (Date.now() - t0 < ms) {
        const t = await p.text(sel);
        if (t != null && (!re || re.test(t))) return t;
        await wait(100);
      }
      throw new Error(`timed out on ${sel} ${re ?? ''}; last: ${JSON.stringify(await p.text(sel))}`);
    },
    /// A picture of the popup itself, for sign-off.
    screenshot: async (file) => {
      const r = await send('Page.captureScreenshot', { format: 'png' });
      if (r.result?.data) fs.writeFileSync(file, Buffer.from(r.result.data, 'base64'));
    },
    close: async () => {
      if (ws.readyState === 1) { try { await send('Runtime.evaluate', { expression: 'window.close()' }); } catch {} }
      ws.close();
      await wait(100);
    },
  };
  return p;
}

module.exports = { openPopup };
