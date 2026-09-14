// The visual floor, measured in the page: what a student sees, not what a
// stylesheet says. `audit(opts)` runs inside the tab (page.evaluate) and
// returns findings; nothing here touches Playwright.
//
//   const { auditSource } = require('./page-audit');
//   const r = await page.evaluate(auditSource({ dark: true }));
//
// Checks (each a list of findings with a selector-ish path and the numbers):
//   text      — every visible text node ≥ 4.5:1 against its effective ground
//               (3:1 for large text); disabled controls and placeholders skip
//   blocks    — dark mode only: no visible box ≥ 120×40 with a light ground
//   controls  — buttons, links and tabs: their own text ≥ 3:1 on their own ground
//   words     — no .pk-* text with a word wider than its box (it would break mid-word)
//   uppercase — no .pk-* element that is uppercase with letter-spacing
//   red       — no .pk-* ink, ground or edge near Canvas's red
// Skipped on purpose: text under a non-root background-image (unknown ground),
// closed shadow roots (the buddy panel), iframes.

function audit({ dark = false } = {}) {
  const findings = { text: [], blocks: [], controls: [], words: [], uppercase: [], red: [], skipped: 0, counted: 0 };
  const vw = document.documentElement.clientWidth, vh = document.documentElement.clientHeight;

  const parse = (s) => {
    const m = /rgba?\(([^)]+)\)/.exec(s || '');
    if (!m) return null;
    const p = m[1].split(/[,\s/]+/).filter(Boolean).map(Number);
    return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 };
  };
  const lum = ({ r, g, b }) => {
    const f = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  };
  const ratio = (a, b) => { const [h, l] = [lum(a), lum(b)].sort((x, y) => y - x); return (h + 0.05) / (l + 0.05); };
  const over = (top, under) => ({
    r: top.r * top.a + under.r * (1 - top.a), g: top.g * top.a + under.g * (1 - top.a), b: top.b * top.a + under.b * (1 - top.a), a: 1,
  });
  const path = (el) => {
    const bits = [];
    for (let e = el, n = 0; e && e.nodeType === 1 && n < 4; e = e.parentElement, n++) {
      let s = e.tagName.toLowerCase();
      if (e.id) s += '#' + e.id;
      else if (e.classList.length) s += '.' + [...e.classList].slice(0, 2).join('.');
      bits.unshift(s);
    }
    return bits.join(' > ');
  };
  // Ours: anything under an element we id or class with pk-. <html> carries
  // pk-on and is not "ours" in that sense, so the search starts under body.
  const isPk = (el) => !!el.closest('body [id^="pk-"], body [class*="pk-"], body [id^="prepkin"]');
  // Canvas's own buttons keep Canvas's colours (the skin never writes a
  // property on one), so they are read for legibility but never as "a block".
  const isButton = (el) => !!el.closest('button, .btn, .Button, [role="button"], [class*="baseButton"], input[type="submit"], input[type="button"]');
  const disabled = (el) => !!el.closest('[disabled], [aria-disabled="true"], .disabled, [aria-hidden="true"]');
  const offscreen = (el) => !!el.closest('.screenreader-only, [class*="screenReader"], .sr-only');
  const visible = (el) => {
    if (!el.checkVisibility || !el.checkVisibility({ opacityProperty: true, visibilityProperty: true })) return false;
    const r = el.getBoundingClientRect();
    return r.width > 0 && r.height > 0 && r.bottom > 0 && r.right > 0 && r.top < document.documentElement.scrollHeight;
  };

  // The ground behind an element: the first painted background walking up,
  // rgba composited; `null` when an ancestor paints an image we cannot read.
  const rootBg = () => {
    const b = parse(getComputedStyle(document.body).backgroundColor);
    const h = parse(getComputedStyle(document.documentElement).backgroundColor);
    if (b && b.a > 0) return h && h.a > 0 ? over(b, h) : over(b, { r: 255, g: 255, b: 255, a: 1 });
    if (h && h.a > 0) return h;
    return { r: 255, g: 255, b: 255, a: 1 };
  };
  const ROOT_BG = rootBg();
  const composite = (els) => {
    const layers = [];
    for (const e of els) {
      const cs = getComputedStyle(e);
      const bg = parse(cs.backgroundColor);
      const img = cs.backgroundImage && cs.backgroundImage !== 'none';
      if (img && e !== document.documentElement && e !== document.body) return null;
      if (bg && bg.a > 0) { layers.push(bg); if (bg.a >= 1) break; }
    }
    let g = ROOT_BG;
    for (const l of layers.reverse()) g = over(l, g);
    return g;
  };
  // The ground behind an element: what is painted under the middle of it, in
  // stacking order (so a sibling pill behind a toggle's label counts, not just
  // ancestors). Falls back to the ancestor chain when the point misses.
  const ground = (el, rect) => {
    const r = rect || el.getBoundingClientRect();
    const cx = r.left + Math.min(r.width, 40) / 2, cy = r.top + r.height / 2;
    if (cx >= 0 && cy >= 0 && cx < vw && cy < vh) {
      const stack = document.elementsFromPoint(cx, cy);
      const i = stack.indexOf(el);
      if (i >= 0) return composite(stack.slice(i));
    }
    const chain = [];
    for (let e = el; e && e.nodeType === 1; e = e.parentElement) chain.push(e);
    return composite(chain);
  };
  // Bring a thing on screen so elementsFromPoint can see it.
  const onScreen = (el) => {
    const r = el.getBoundingClientRect();
    if (r.top < 0 || r.bottom > vh) el.scrollIntoView({ block: 'center', behavior: 'instant' });
    return el.getBoundingClientRect();
  };
  // The element that actually holds a control's words (a button's inner span,
  // a link's text div): its colour and its ground are what a student reads.
  const textHolder = (el) => {
    const w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      if (n.nodeValue.trim() && n.parentElement && !offscreen(n.parentElement) && visible(n.parentElement)) return n.parentElement;
    }
    return el;
  };

  // ---- text ----
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  const seen = new Set();
  for (let n = walker.nextNode(); n; n = walker.nextNode()) {
    if (!n.nodeValue.trim()) continue;
    const el = n.parentElement;
    if (!el || seen.has(el)) continue;
    seen.add(el);
    if (el.closest('script, style, noscript, template, svg')) continue;
    if (offscreen(el) || disabled(el) || !visible(el)) continue;
    const cs = getComputedStyle(el);
    const fg = parse(cs.color);
    if (!fg || fg.a === 0) continue;
    const bg = ground(el, onScreen(el));
    if (!bg) { findings.skipped++; continue; }
    findings.counted++;
    const size = parseFloat(cs.fontSize), bold = parseInt(cs.fontWeight, 10) >= 700;
    const large = size >= 24 || (size >= 18.66 && bold);
    const need = large ? 3 : 4.5;
    const r = ratio(over(fg, bg), bg);
    if (r < need) {
      findings.text.push({ path: path(el), text: n.nodeValue.trim().slice(0, 40), ratio: +r.toFixed(2), need, pk: isPk(el) });
    }
  }

  // ---- blocks (dark only) ----
  if (dark) {
    for (const el of document.body.querySelectorAll('*')) {
      if (el.closest('img, video, canvas, iframe, svg, picture, [class*="pk-w-tank"], .ic-DashboardCard__header_hero, .ic-DashboardCard__header')) continue;
      if (el.matches('img, video, canvas, iframe, svg, picture') || isButton(el)) continue;
      if (!visible(el)) continue;
      const r = el.getBoundingClientRect();
      if (r.width < 120 || r.height < 40) continue;
      const cs = getComputedStyle(el);
      const bg = parse(cs.backgroundColor);
      if (!bg || bg.a < 0.9) continue;
      if (lum(bg) > 0.7) findings.blocks.push({ path: path(el), size: `${Math.round(r.width)}×${Math.round(r.height)}`, bg: cs.backgroundColor, pk: isPk(el) });
    }
  }

  // ---- controls ----
  for (const el of document.body.querySelectorAll('button, a[href], [role="button"], [role="tab"], input[type="submit"], input[type="button"]')) {
    if (offscreen(el) || disabled(el) || !visible(el)) continue;
    const label = (el.innerText || el.value || '').trim();
    if (!label) continue;
    const holder = textHolder(el);
    // An icon-only control (its words are for a screen reader) has no text to
    // read; its icon is Canvas's own, left alone by the skin's button rule.
    if (holder === el && !(el.innerText || '').trim()) continue;
    if (holder === el && [...el.childNodes].every((n) => n.nodeType !== 3 || !n.nodeValue.trim())) continue;
    const cs = getComputedStyle(holder);
    const fg = parse(cs.color); const bg = ground(holder, onScreen(holder));
    if (!fg || !bg) continue;
    const r = ratio(over(fg, bg), bg);
    if (r < 3) findings.controls.push({ path: path(el), text: label.slice(0, 30), ratio: +r.toFixed(2), pk: isPk(el) });
  }

  // ---- words, uppercase, red: our own elements only ----
  const canvas = document.createElement('canvas').getContext('2d');
  const RED = ({ r, g, b }) => {
    const max = Math.max(r, g, b) / 255, min = Math.min(r, g, b) / 255;
    if (max === 0) return false;
    const l = (max + min) / 2, s = max === min ? 0 : (max - min) / (1 - Math.abs(2 * l - 1));
    let h = 0; const R = r / 255, G = g / 255, B = b / 255;
    if (max !== min) {
      if (max === R) h = ((G - B) / (max - min)) % 6;
      else if (max === G) h = (B - R) / (max - min) + 2;
      else h = (R - G) / (max - min) + 4;
      h = (h * 60 + 360) % 360;
    }
    return (h >= 345 || h <= 12) && s > 0.55 && l > 0.28 && l < 0.62;
  };
  // "body [class*=pk-] *", not "[class*=pk-] *": <html> carries pk-on, and a
  // selector with no body anchor would make every element on the page ours.
  for (const el of document.body.querySelectorAll('body [id^="pk-"], body [id^="pk-"] *, body [class*="pk-"], body [class*="pk-"] *, body [id^="prepkin"]')) {
    if (!visible(el) || el.closest('svg')) continue;
    const cs = getComputedStyle(el);
    if (cs.textTransform === 'uppercase' && parseFloat(cs.letterSpacing) > 0 && (el.innerText || '').trim()) {
      findings.uppercase.push({ path: path(el), text: el.innerText.trim().slice(0, 30) });
    }
    // A class tile wears the school's course colour, which is theirs, not ours.
    for (const prop of el.hasAttribute('data-pk-course-color') ? [] : ['color', 'backgroundColor', 'borderTopColor', 'borderLeftColor']) {
      const c = parse(cs[prop]);
      if (c && c.a > 0.5 && RED(c)) { findings.red.push({ path: path(el), prop, value: cs[prop] }); break; }
    }
    // A word wider than its box breaks mid-word.
    const own = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.nodeValue).join(' ').trim();
    if (own && el.getClientRects().length > 1) {
      canvas.font = `${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`;
      const width = el.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight);
      const longest = own.split(/\s+/).reduce((a, w) => (canvas.measureText(w).width > canvas.measureText(a).width ? w : a), '');
      if (canvas.measureText(longest).width > width + 1 && cs.overflowWrap !== 'normal' || (cs.wordBreak === 'break-all')) {
        findings.words.push({ path: path(el), word: longest.slice(0, 30), box: Math.round(width) });
      }
    }
  }
  window.scrollTo(0, 0);
  return findings;
}

/// The call as one expression string: Playwright evaluates a string as an
/// expression (a function string would come back uncalled).
const auditSource = (opts = {}) => `(${audit.toString()})(${JSON.stringify(opts)})`;
module.exports = { audit, auditSource };
