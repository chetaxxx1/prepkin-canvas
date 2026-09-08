// Themes: what a Look does to the page, beyond the paper.
//
// A theme names a paper pair (the reading surface, from receipt.js, every one
// measured), an accent (links and marks), a card-header treatment, and an
// optional texture on the page ground. Textures are tiny SVGs shipped inline:
// no request ever leaves the laptop. Course colours are never written; the
// gradient treatment washes the course's own band, it does not replace it.
//
// Accents are held to 4.5:1 on their paper (receipt.test.js checks every pair).

const TEXTURES = {
  none: null,
  dots: (ink) => `<svg xmlns='http://www.w3.org/2000/svg' width='18' height='18'><circle cx='2' cy='2' r='1' fill='${ink}' fill-opacity='.10'/></svg>`,
  grid: (ink) => `<svg xmlns='http://www.w3.org/2000/svg' width='28' height='28'><path d='M28 0H0v28' fill='none' stroke='${ink}' stroke-opacity='.07'/></svg>`,
  // Grain reads heavier in a dark ink on a light paper than the other way
  // round, so it is capped at 4% there and 7% on dark papers.
  grain: (ink) => { const a = parseInt(ink.slice(1, 3), 16) < 128 ? '.04' : '.07'; return `<svg xmlns='http://www.w3.org/2000/svg' width='120' height='120'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.9' numOctaves='2' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 ${a} 0'/></filter><rect width='120' height='120' filter='url(#n)' fill='${ink}'/></svg>`; },
  waves: (ink) => `<svg xmlns='http://www.w3.org/2000/svg' width='48' height='16'><path d='M0 8c6-6 12-6 18 0s12 6 18 0 12-6 18 0' fill='none' stroke='${ink}' stroke-opacity='.08'/></svg>`,
  // Gingham, drawn as lines rather than blocks. Blocks at any opacity read as a
  // grey plaid over the whole page and swallow the paper underneath; two thin
  // crossing lines say "check" and leave the stock the thing you see.
  checks: (ink) => `<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'><path d='M0 .75h16M.75 0v16' stroke='${ink}' stroke-opacity='.07' stroke-width='1.5'/></svg>`,
  stars: (ink) => `<svg xmlns='http://www.w3.org/2000/svg' width='36' height='36'><path d='M9 4 L10 8 L14 9 L10 10 L9 14 L8 10 L4 9 L8 8 Z M27 20 L27.7 22.7 L30.5 23.5 L27.7 24.3 L27 27 L26.3 24.3 L23.5 23.5 L26.3 22.7 Z' fill='${ink}' fill-opacity='.09'/></svg>`,
};

/// `header`: 'band' keeps Canvas's course-colour strip; 'wash' lays a soft
/// gradient of the accent over it, course colour still underneath.
const THEMES = [
  { id: 'classic', name: 'Classic Cream', vibe: 'the default, calm',
    paper: { light: 'newsprint', dark: 'carbon' }, accent: { light: '#2F6BAA', dark: '#6FA8DC' },
    rail: { light: '#2F4A66', dark: '#1B2733' },
    header: 'band', texture: 'none', accessory: null, price: 0, free: true },
  { id: 'academia', name: 'Dark Academia', vibe: 'parchment, oxblood, old library',
    paper: { light: 'vellum', dark: 'ink' }, accent: { light: '#7A2E2E', dark: '#D08A8A' },
    rail: { light: '#4A1F1F', dark: '#2A1414' },
    header: 'wash', texture: 'grain', accessory: 'glasses', colors: { frame: '#5A2B2B' }, price: 350 },
  { id: 'blush', name: 'Blush', vibe: 'soft pink, bows, matcha lattes',
    paper: { light: 'rose', dark: 'ink' }, accent: { light: '#B04A6E', dark: '#F0A3BE' },
    rail: { light: '#8A3355', dark: '#3A1A28' },
    header: 'wash', texture: 'dots', accessory: 'scarf', colors: { wrap: '#D98BA6', tail: '#B04A6E' }, price: 300 },
  { id: 'haze', name: 'Lavender Haze', vibe: 'lilac, late night, headphones on',
    paper: { light: 'lavender', dark: 'ink' }, accent: { light: '#6A4FB0', dark: '#B9A6F0' },
    rail: { light: '#4E3A8C', dark: '#241C40' },
    header: 'wash', texture: 'dots', accessory: 'beanie', colors: { cap: '#6A4FB0', brim: '#553E93' }, price: 300 },
  { id: 'matcha', name: 'Matcha', vibe: 'sage, clay, quiet morning',
    paper: { light: 'sage', dark: 'moss' }, accent: { light: '#3F7A52', dark: '#9BD6AE' },
    rail: { light: '#2F5A3C', dark: '#1B3324' },
    header: 'band', texture: 'grid', accessory: 'sprout', colors: { stem: '#3F7A52', leafA: '#6BAA7D', leafB: '#8DC49B' }, price: 350 },
  { id: 'coastal', name: 'Coastal', vibe: 'sea glass, linen, open window',
    paper: { light: 'sky', dark: 'blueprint' }, accent: { light: '#2C6FA8', dark: '#8FC1EA' },
    rail: { light: '#245A85', dark: '#152F45' },
    header: 'band', texture: 'waves', accessory: null, price: 300 },
  { id: 'midnight', name: 'Midnight', vibe: 'navy, electric blue, 2am',
    paper: { light: 'bond', dark: 'ink' }, accent: { light: '#1F5FA8', dark: '#6FA3F5' },
    rail: { light: '#152A4D', dark: '#0D1A30' },
    header: 'wash', texture: 'none', accessory: 'beanie', colors: { cap: '#1F5FA8', brim: '#184A82' }, price: 400 },
  { id: 'sunset', name: 'Sunset', vibe: 'peach to coral, golden hour',
    paper: { light: 'manila', dark: 'carbon' }, accent: { light: '#9E4527', dark: '#F0A07C' },
    rail: { light: '#7A3319', dark: '#3A1A0E' },
    header: 'wash', texture: 'none', accessory: 'scarf', colors: { wrap: '#E07A52', tail: '#B4532F' }, price: 350 },
  { id: 'blossom', name: 'Cherry Blossom', vibe: 'petals, spring, pink on navy at night',
    paper: { light: 'rose', dark: 'blueprint' }, accent: { light: '#A93C68', dark: '#F2A6C6' },
    rail: { light: '#7E2A4E', dark: '#1D2A44' },
    header: 'wash', texture: 'dots', accessory: 'sprout', colors: { stem: '#8E6A72', leafA: '#E39AB6', leafB: '#F2BBD0' }, price: 350 },
  { id: 'lofi', name: 'Lo-fi', vibe: 'muted purple, rain on the window',
    paper: { light: 'lavender', dark: 'ink' }, accent: { light: '#5F5A8C', dark: '#AFA8E6' },
    rail: { light: '#4A4670', dark: '#22203A' },
    header: 'band', texture: 'grain', accessory: 'glasses', colors: { frame: '#5F5A8C' }, price: 300 },
  { id: 'cottage', name: 'Cottage', vibe: 'cream, moss, terracotta',
    paper: { light: 'manila', dark: 'moss' }, accent: { light: '#9E4B2E', dark: '#E8A184' },
    rail: { light: '#5A3A2A', dark: '#243026' },
    header: 'band', texture: 'grid', accessory: 'sprout', colors: { stem: '#4E6E3E', leafA: '#6B8F5A', leafB: '#84A96F' }, price: 350 },
  { id: 'nightshift', name: 'Night Shift', vibe: 'the blue-grey dark, for the late shift',
    paper: { light: 'bond', dark: 'blueprint' }, accent: { light: '#1F5FA8', dark: '#7FB2E0' },
    rail: { light: '#26364A', dark: '#182230' },
    header: 'band', texture: 'none', accessory: 'beanie', colors: { cap: '#3E5A8C', brim: '#2E4368' }, price: 500 },
  // The third six, 2026-09-06. Chosen against what students actually pick in the
  // public theme galleries — sea foam, study beige, strawberry, Y2K cyan, park
  // green, plum — on stocks that already clear the reading floor.
  { id: 'seafoam', name: 'Sea Foam', vibe: 'pale mint, salt air, clean desk',
    paper: { light: 'seafoam', dark: 'moss' }, accent: { light: '#0F6B57', dark: '#7FD8BE' },
    rail: { light: '#1B4A40', dark: '#16302A' },
    header: 'band', texture: 'waves', accessory: 'sprout', colors: { stem: '#0F6B57', leafA: '#4FB598', leafB: '#7FD8BE' }, price: 300 },
  { id: 'beigestudy', name: 'Study Beige', vibe: 'oat paper, brown pen, nothing loud',
    paper: { light: 'oat', dark: 'carbon' }, accent: { light: '#7A5230', dark: '#D9A97A' },
    rail: { light: '#4A3826', dark: '#241C14' },
    header: 'band', texture: 'grain', accessory: 'glasses', colors: { frame: '#7A5230' }, price: 300 },
  { id: 'strawberry', name: 'Strawberry Matcha', vibe: 'pink and green, iced, summer',
    paper: { light: 'peach', dark: 'moss' }, accent: { light: '#B03A46', dark: '#F0959E' },
    rail: { light: '#7A2A34', dark: '#33181C' },
    header: 'wash', texture: 'checks', accessory: 'scarf', colors: { wrap: '#E4808C', tail: '#B03A46' }, price: 350 },
  { id: 'frutiger', name: 'Frutiger', vibe: 'glossy 2000s cyan, bubbles, a fresh install',
    paper: { light: 'sky', dark: 'blueprint' }, accent: { light: '#0E6E8C', dark: '#66D3E8' },
    rail: { light: '#0C4C60', dark: '#0A2C38' },
    header: 'wash', texture: 'dots', accessory: 'glasses', colors: { frame: '#0E6E8C' }, price: 350 },
  { id: 'parks', name: 'National Parks', vibe: 'pine, canvas tent, a printed map',
    paper: { light: 'sage', dark: 'moss' }, accent: { light: '#3B6B3A', dark: '#9AD08E' },
    rail: { light: '#2C4E2B', dark: '#1A2E1A' },
    header: 'band', texture: 'grid', accessory: 'beanie', colors: { cap: '#3B6B3A', brim: '#2C4E2B' }, price: 350 },
  { id: 'plumnight', name: 'Plum Night', vibe: 'aubergine dark, one soft star',
    paper: { light: 'lavender', dark: 'plum' }, accent: { light: '#6A4FB0', dark: '#C3A6EE' },
    rail: { light: '#3A2A55', dark: '#221A2E' },
    header: 'wash', texture: 'stars', accessory: 'beanie', colors: { cap: '#6A4FB0', brim: '#4E3A8C' }, price: 400 },
];

/// Image themes: everything above plus a wallpaper under a paper wash and four
/// banners that rotate across the course cards. The art ships inside the
/// extension (`extension/art/<theme>/`), never fetched. Until Grok's files land
/// they point at the placeholder set, so the plumbing is real and tested.
const IMAGE_THEMES = [
  { id: 'graffiti', name: 'Graffiti', vibe: 'spray paint on brick, pink and cyan, night',
    paper: { light: 'newsprint', dark: 'carbon' }, accent: { light: '#B4287A', dark: '#FF7AC6' },
    rail: { light: '#231226', dark: '#120A16' },
    header: 'band', texture: 'none', accessory: 'beanie', colors: { cap: '#B4287A', brim: '#8E1F60' }, price: 450,
    art: 'graffiti', wash: { light: 0.82, dark: 0.72 } },
  { id: 'neoncity', name: 'Anime Night City', vibe: 'rainy Tokyo, neon, lavender dusk',
    paper: { light: 'lavender', dark: 'ink' }, accent: { light: '#6A4FB0', dark: '#B9A6F0' },
    rail: { light: '#1E1740', dark: '#0F0C24' },
    header: 'band', texture: 'none', accessory: 'glasses', colors: { frame: '#6A4FB0' }, price: 450,
    art: 'neoncity', wash: { light: 0.82, dark: 0.7 } },
  { id: 'vaporwave', name: 'Vaporwave', vibe: 'sunset grid, palms, magenta to teal',
    paper: { light: 'rose', dark: 'ink' }, accent: { light: '#A93C68', dark: '#F2A6C6' },
    rail: { light: '#3A1A4A', dark: '#1A0C26' },
    header: 'band', texture: 'none', accessory: 'scarf', colors: { wrap: '#D98BA6', tail: '#A93C68' }, price: 450,
    art: 'vaporwave', wash: { light: 0.82, dark: 0.72 } },
  { id: 'deepsea', name: 'Deep Sea', vibe: 'light through deep water, kelp, jellyfish',
    paper: { light: 'sky', dark: 'blueprint' }, accent: { light: '#2C6FA8', dark: '#8FC1EA' },
    rail: { light: '#0F3550', dark: '#081E30' },
    header: 'band', texture: 'none', accessory: null, price: 450,
    art: 'deepsea', wash: { light: 0.82, dark: 0.7 } },
  { id: 'forest', name: 'Spirit Forest', vibe: 'mossy roots, gold light, tiny glowing spirits',
    paper: { light: 'sage', dark: 'moss' }, accent: { light: '#3F7A52', dark: '#9BD6AE' },
    rail: { light: '#2F5A3C', dark: '#1B3324' },
    header: 'band', texture: 'none', accessory: 'sprout', colors: { cap: '#3F7A52', brim: '#2F5A3C' }, price: 450,
    art: 'forest', wash: { light: 0.72, dark: 0.74 } },
  { id: 'spring', name: 'Spring Day', vibe: 'daisies, petals, a picnic, pastel everything',
    paper: { light: 'rose', dark: 'ink' }, accent: { light: '#B04A6E', dark: '#F0A3BE' },
    rail: { light: '#8A3355', dark: '#3A1A28' },
    header: 'band', texture: 'none', accessory: 'glasses', colors: { cap: '#B04A6E', brim: '#8A3355' }, price: 450,
    art: 'spring', wash: { light: 0.7, dark: 0.76 } },
  { id: 'cafe', name: 'Rainy Cafe', vibe: 'window seat, latte, string lights, rain',
    paper: { light: 'manila', dark: 'carbon' }, accent: { light: '#9E4B2E', dark: '#E8A184' },
    rail: { light: '#5A3A2A', dark: '#243026' },
    header: 'band', texture: 'none', accessory: 'scarf', colors: { cap: '#9E4B2E', brim: '#5A3A2A' }, price: 450,
    art: 'cafe', wash: { light: 0.74, dark: 0.74 } },
  { id: 'nebula', name: 'Nebula', vibe: 'indigo and plum, one gold star, quiet',
    paper: { light: 'lavender', dark: 'ink' }, accent: { light: '#6A4FB0', dark: '#B9A6F0' },
    rail: { light: '#4E3A8C', dark: '#241C40' },
    header: 'band', texture: 'none', accessory: 'beanie', colors: { cap: '#6A4FB0', brim: '#4E3A8C' }, price: 450,
    art: 'nebula', wash: { light: 0.82, dark: 0.7 } },
];
for (const t of IMAGE_THEMES) THEMES.push(t);

const THEMES_BY_ID = Object.fromEntries(THEMES.map((t) => [t.id, t]));

/// The left menu takes the theme's rail colour. White text and icons sit on
/// it, so every rail is deep; an image theme shows its wallpaper through a
/// wash of the same colour.

/// The files an image theme uses, as extension URLs. Falls back to the
/// placeholder set until the theme's own folder exists (art/manifest.json
/// lists the folders that do).
function artFor(theme, available, toURL) {
  if (!theme?.art) return null;
  const folder = available.includes(theme.art) ? theme.art : '_placeholder';
  const ext = folder === '_placeholder' ? 'svg' : 'webp';
  return {
    wallpaper: toURL(`art/${folder}/wallpaper.${ext}`),
    cards: [1, 2, 3, 4].map((i) => toURL(`art/${folder}/card-${i}.${ext}`)),
  };
}

/// The CSS background-image for a texture, in the paper's ink.
function textureImage(kind, ink) {
  const draw = TEXTURES[kind];
  if (!draw) return 'none';
  return `url("data:image/svg+xml,${encodeURIComponent(draw(ink))}")`;
}

if (typeof module !== 'undefined') module.exports = { THEMES, THEMES_BY_ID, IMAGE_THEMES, TEXTURES, textureImage, artFor };
