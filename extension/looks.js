// Looks: a palette plus something the slime wears.
//
// Earned with coins from verified work, never bought with money. The catalog is
// static and ships with the extension; what you own and what you are wearing
// come from the phone, because the coin ledger lives there.
//
// PROVISIONAL ART: the four accessories below are drawn in the slime's own
// normalised coordinate space (0..1, the same one bridge/port-slime.py emits).
// They are new mascot art and need George's sign-off. Everything about them is
// contained in this file, so swapping in approved renders is a one-file change.
// The slime's body, belly and face are never touched by a look.

/// Accessories are drawn after the face, in the slime's 0..1 space.
const LOOK_ACCESSORIES = {
  sprout: (c) => `
    <path d="M0.598 0.075 C0.596 0.045 0.596 0.020 0.600 0.000"
          stroke="${c.stem}" stroke-width="0.016" fill="none" stroke-linecap="round"/>
    <path d="M0.598 0.041 C0.556 0.049 0.520 0.030 0.512 -0.004 C0.552 -0.018 0.590 0.005 0.598 0.041 Z"
          fill="${c.leafA}"/>
    <path d="M0.601 0.028 C0.628 -0.004 0.669 -0.011 0.694 0.005 C0.678 0.040 0.635 0.049 0.601 0.028 Z"
          fill="${c.leafB}"/>`,
  beanie: (c) => `
    <path d="M0.168 0.300 C0.196 0.140 0.330 0.052 0.500 0.052 C0.670 0.052 0.804 0.140 0.832 0.300 Z"
          fill="${c.cap}"/>
    <rect x="0.150" y="0.283" width="0.700" height="0.062" rx="0.031" fill="${c.brim}"/>
    <circle cx="0.500" cy="0.045" r="0.043" fill="${c.brim}"/>`,
  glasses: (c) => `
    <circle cx="0.332" cy="0.433" r="0.088" fill="none" stroke="${c.frame}" stroke-width="0.018"/>
    <circle cx="0.668" cy="0.433" r="0.088" fill="none" stroke="${c.frame}" stroke-width="0.018"/>
    <path d="M0.420 0.433 L0.580 0.433" stroke="${c.frame}" stroke-width="0.018" stroke-linecap="round"/>`,
  scarf: (c) => `
    <path d="M0.152 0.615 C0.300 0.690 0.700 0.690 0.848 0.615 L0.848 0.688 C0.700 0.762 0.300 0.762 0.152 0.688 Z"
          fill="${c.wrap}"/>
    <path d="M0.690 0.690 C0.742 0.706 0.772 0.742 0.778 0.792 C0.742 0.806 0.700 0.788 0.678 0.750 Z"
          fill="${c.tail}"/>`,
};

/// Every look. `tints` are the page-level variables a look is allowed to move:
/// surfaces, borders and the accent. Type, layout and spacing never change, and
/// course colours stay Canvas's own — students navigate by them.
const LOOKS = [
  {
    id: 'classic', name: 'Classic Cream', price: 0, free: true,
    swatch: '#F4F1EA', accessory: null,
    tints: {},
  },
  {
    id: 'woodland', name: 'Woodland', price: 300,
    swatch: '#EDF1E6', accessory: 'sprout',
    colors: { stem: '#4E6E3E', leafA: '#6B8F5A', leafB: '#84A96F' },
    tints: {
      '--pk-page': '#EDF1E6', '--pk-inset': '#E3EAD9', '--pk-line': '#DEE4D4',
      '--pk-text-2': '#7C8468', '--pk-mint': '#6B8F5A', '--pk-mint-edge': '#547340',
      '--pk-green': '#4E6E3E',
      '--pk-mint-tint': 'rgba(107,143,90,.12)', '--pk-mint-tint-strong': 'rgba(107,143,90,.18)',
      '--pk-mint-border': 'rgba(107,143,90,.35)',
    },
  },
  {
    id: 'beanie', name: 'Cozy Beanie', price: 300,
    swatch: '#EDE9F2', accessory: 'beanie',
    colors: { cap: '#7A6BA8', brim: '#635591' },
    tints: {
      '--pk-page': '#EDE9F2', '--pk-inset': '#E5E0EC', '--pk-line': '#DCD6E6',
      '--pk-text-2': '#7A7288', '--pk-mint': '#7A6BA8', '--pk-mint-edge': '#5E5189',
      '--pk-green': '#5E5189',
      '--pk-mint-tint': 'rgba(122,107,168,.12)', '--pk-mint-tint-strong': 'rgba(122,107,168,.18)',
      '--pk-mint-border': 'rgba(122,107,168,.35)',
    },
  },
  {
    id: 'tidepool', name: 'Tidepool', price: 450,
    swatch: '#E4EFEE', accessory: 'glasses',
    colors: { frame: '#2B6E68' },
    tints: {
      '--pk-page': '#E4EFEE', '--pk-inset': '#DAE8E6', '--pk-line': '#D0E0DE',
      '--pk-text-2': '#6C8380', '--pk-mint': '#3E9089', '--pk-mint-edge': '#2B6E68',
      '--pk-green': '#2B6E68',
      '--pk-mint-tint': 'rgba(62,144,137,.12)', '--pk-mint-tint-strong': 'rgba(62,144,137,.18)',
      '--pk-mint-border': 'rgba(62,144,137,.35)',
    },
  },
  {
    id: 'butterscotch', name: 'Butterscotch', price: 300,
    swatch: '#F5EBDD', accessory: 'scarf',
    colors: { wrap: '#C86E4B', tail: '#A9563A' },
    tints: {
      '--pk-page': '#F5EBDD', '--pk-inset': '#EEE1CE', '--pk-line': '#E5D7C2',
      '--pk-text-2': '#8B7660', '--pk-mint': '#C86E4B', '--pk-mint-edge': '#A9563A',
      '--pk-green': '#A9563A',
      '--pk-mint-tint': 'rgba(200,110,75,.12)', '--pk-mint-tint-strong': 'rgba(200,110,75,.18)',
      '--pk-mint-border': 'rgba(200,110,75,.35)',
    },
  },
  {
    // The one look that carries a whole theme: wearing it turns dark mode on.
    id: 'nightshift', name: 'Night Shift', price: 500, dark: true,
    swatch: '#2C322B', accessory: 'beanie',
    colors: { cap: '#3E5A8C', brim: '#2E4368' },
    tints: {},
  },
];

const LOOKS_BY_ID = Object.fromEntries(LOOKS.map((l) => [l.id, l]));

/// The accessory markup for a look, or '' for a bare slime.
function lookAccessorySVG(lookId) {
  const look = LOOKS_BY_ID[lookId];
  if (!look?.accessory) return '';
  const draw = LOOK_ACCESSORIES[look.accessory];
  return draw ? draw(look.colors ?? {}) : '';
}

/// Turns a look's tints into inline custom properties for a root element.
function lookVars(lookId) {
  const tints = LOOKS_BY_ID[lookId]?.tints ?? {};
  return Object.entries(tints).map(([k, v]) => `${k}:${v}`).join(';');
}

if (typeof module !== 'undefined') {
  module.exports = { LOOKS, LOOKS_BY_ID, LOOK_ACCESSORIES, lookAccessorySVG, lookVars };
}
