// The pod name lists, copied from ios/Resources/Content/podnames.json so the
// laptop spells a stranger exactly the way the phone does. Two indexes in,
// one safe name out; nothing here was typed by a student.
const POD_NAMES = {"adjectives": ["Quiet", "Calm", "Steady", "Patient", "Gentle", "Kind", "Cheerful", "Merry", "Sunny", "Clear", "Bright", "Fresh", "Crisp", "Cool", "Mild", "Still", "Silent", "Hushed", "Snowy", "Frosty", "Tranquil", "Watchful", "Sunlit", "Moonlit", "Starlit", "Early", "Brave", "Bold", "Eager", "Ready", "Keen", "Swift", "Nimble", "Lively", "Spirited", "Curious", "Clever", "Thoughtful", "Careful", "Mindful", "Honest", "Loyal", "Friendly", "Helpful", "Hopeful", "Joyful", "Peaceful", "Restful", "Seaside", "Coastal", "Northern", "Southern", "Eastern", "Western", "Faraway", "Drifting", "Sailing", "Roaming", "Wandering", "Rising", "Morning", "Evening", "Winter", "Autumn"], "nouns": ["Otter", "Heron", "Egret", "Tern", "Gull", "Osprey", "Albatross", "Pelican", "Plover", "Sandpiper", "Kingfisher", "Curlew", "Petrel", "Cormorant", "Turtle", "Dolphin", "Narwhal", "Seal", "Marlin", "Sailfish", "Herring", "Salmon", "Sturgeon", "Halibut", "Seahorse", "Cuttlefish", "Nautilus", "Octopus", "Manta", "Stingray", "Harbor", "Cove", "Inlet", "Atoll", "Fjord", "Shoal", "Sandbar", "Tide", "Current", "Eddy", "Channel", "Crest", "Breaker", "Ripple", "Wave", "Surf", "Foam", "Mist", "Drizzle", "Squall", "Gale", "Breeze", "Zephyr", "Thunder", "Cirrus", "Cumulus", "Nimbus", "Aurora", "Beacon", "Lantern", "Compass", "Anchor", "Skiff", "Ferry"]};
function podName(adjective, noun) {
  const wrap = (i, n) => { const m = Number(i) % n; return Number.isFinite(m) ? (m < 0 ? m + n : m) : 0; };
  const a = POD_NAMES.adjectives, b = POD_NAMES.nouns;
  if (!a.length || !b.length) return 'Someone';
  return `${a[wrap(adjective, a.length)]} ${b[wrap(noun, b.length)]}`;
}
if (typeof module !== 'undefined') module.exports = { POD_NAMES, podName };
