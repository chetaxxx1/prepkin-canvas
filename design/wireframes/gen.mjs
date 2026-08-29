// Generates the wireframe .dc.html artboards from a shared kit.
import { writeFileSync } from 'node:fs';

const flex = (dir, gap, extra = '') =>
  `display: flex; flex-direction: ${dir}; gap: ${gap}px; ${extra}`;
const bar = (w, h, c = '#dcdcdc') =>
  `<div style="width: ${w}px; height: ${h}px; background: ${c}; border-radius: ${Math.ceil(h / 2)}px;"></div>`;
const card = (inner, extra = '') =>
  `<div style="border: 1.5px solid #d8d8d8; border-radius: 16px; padding: 14px; ${flex('column', 10)} ${extra}">${inner}</div>`;
const lbl = (t) =>
  `<div style="font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; color: #9a9a9a;">${t}</div>`;
const btn = (t) =>
  `<div style="background: #f26b4f; color: #fff; border-radius: 999px; padding: 10px 18px; font-size: 13px; font-weight: 600; text-align: center;">${t}</div>`;
const ghost = (t) =>
  `<div style="border: 1.5px solid #d8d8d8; border-radius: 999px; padding: 10px 18px; font-size: 13px; color: #888; text-align: center;">${t}</div>`;
const pill = (t) =>
  `<div style="border: 1.5px solid #d8d8d8; border-radius: 999px; padding: 6px 14px; font-size: 12px; color: #777;">${t}</div>`;
const blob = (w, h, c = '#e9e9e9') =>
  `<div style="width: ${w}px; height: ${h}px; background: ${c}; border-radius: 48% 48% 46% 46% / 58% 58% 40% 40%;"></div>`;
const circle = (d, c = '#e6e6e6') =>
  `<div style="width: ${d}px; height: ${d}px; border-radius: 50%; background: ${c};"></div>`;
const big = (t) =>
  `<div style="font-size: 44px; font-weight: 700; color: #4a4a4a;">${t}</div>`;
const back = (t) =>
  `<div style="display: flex; align-items: center; gap: 10px;"><div style="font-size: 18px; color: #999;">‹</div><div style="font-size: 15px; font-weight: 600; color: #555;">${t}</div></div>`;
const listRow = (wTitle, wSub, right) =>
  `<div style="display: flex; align-items: center; gap: 10px;">
     <div style="width: 20px; height: 20px; border: 1.5px solid #cfcfcf; border-radius: 50%;"></div>
     <div style="flex: 1; ${flex('column', 5)}">${bar(wTitle, 9)}${bar(wSub, 7, '#efefef')}</div>
     <div style="font-size: 12px; color: #f26b4f; font-weight: 600;">${right}</div>
   </div>`;

const TABS = ['Home', 'Focus', 'Games', 'Learn', 'Friends', 'Shop'];
const tabbar = (active) =>
  `<div style="display: flex; border-top: 1.5px solid #e2e2e2;">` +
  TABS.map((t) => {
    const on = t === active;
    return `<div style="flex: 1; ${flex('column', 4, 'align-items: center;')} font-size: 9px; color: ${on ? '#f26b4f' : '#aaa'}; padding: 10px 0;"><div style="width: 20px; height: 20px; border-radius: 6px; background: ${on ? '#f26b4f' : '#e6e6e6'};"></div>${t}</div>`;
  }).join('') +
  `</div>`;

const page = (content, tab, bg = '#ffffff') => `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <style>
    body { margin: 0; background: #fff; font-family: system-ui, sans-serif; color: #555; }
    a { color: #f26b4f; } a:hover { color: #d3532f; }
  </style>
</helmet>
<div style="width: 390px; height: 844px; ${flex('column', 0)} background: ${bg};">
  <div style="flex: 1; ${flex('column', 14)} padding: 20px 16px; overflow: hidden;">
${content}
  </div>
${tab ? tabbar(tab) : ''}
</div>
</x-dc>
</body>
</html>
`;

const files = {};

// ---- Focus (setup)
files['Focus.dc.html'] = page(
  `<div style="font-size: 20px; font-weight: 700; color: #4a4a4a;">Focus</div>
   <div style="flex: 1; ${flex('column', 18, 'align-items: center; justify-content: center;')}">
     ${blob(150, 120)}
     ${big('25 min')}
     <div style="display: flex; align-items: center; gap: 16px;">${pill('−')}${bar(70, 8)}${pill('+')}</div>
     ${bar(190, 8, '#ececec')}
   </div>
   ${btn('Start focus')}`,
  'Focus');

// ---- Focus (running)
files['FocusRunning.dc.html'] = page(
  `<div style="flex: 1; ${flex('column', 18, 'align-items: center; justify-content: center;')}">
     <div style="position: relative;">${blob(150, 120)}<div style="position: absolute; top: -14px; right: -26px; font-size: 13px; color: #b5b5b5;">z z z</div></div>
     ${big('18:42')}
     ${bar(210, 8, '#ececec')}
   </div>
   ${ghost('Give up')}`,
  null);

// ---- Weekly summary
files['Weekly.dc.html'] = page(
  `${back('Your week')}
   ${card(`${lbl('mon – sun')}
     <div style="${flex('column', 14)}">
       ${['tasks done', 'focus minutes', 'words solved', 'lessons finished', 'coins earned'].map((t) =>
         `<div style="display: flex; align-items: center; gap: 10px;"><div style="flex: 1; ${flex('column', 5)}${''}">${bar(90, 8, '#ececec')}</div>${bar(120, 10)}<div style="font-size: 15px; font-weight: 700; color: #4a4a4a;">12</div></div>`).join('')}
     </div>`)}
   ${card(`${lbl('chibi moment')}<div style="${flex('row', 12, 'align-items: center;')}">${blob(64, 52)}${bar(180, 8, '#ececec')}</div>`)}
   ${btn('Share my week')}`,
  null);

// ---- Grade calculator
files['GradeCalc.dc.html'] = page(
  `${back('Grade calculator')}
   ${card(['Current grade', 'Grade I want', 'Final is worth'].map((t) =>
     `<div style="${flex('column', 8)}">
        <div style="display: flex; justify-content: space-between; font-size: 12px; color: #777;"><span>${t}</span><span style="color: #f26b4f; font-weight: 700;">88%</span></div>
        <div style="position: relative; height: 18px;"><div style="position: absolute; top: 7px; left: 0; right: 0; height: 4px; background: #e6e6e6; border-radius: 2px;"></div><div style="position: absolute; top: 0; left: 60%; width: 18px; height: 18px; border-radius: 50%; background: #fff; border: 1.5px solid #bbb;"></div></div>
      </div>`).join(''))}
   ${card(`<div style="${flex('column', 8, 'align-items: center;')}">${lbl('you need')}${big('94.2%')}${bar(200, 8, '#ececec')}${bar(150, 8, '#ececec')}</div>`)}`,
  null);

// ---- Canvas pairing (onboarding)
files['Pairing.dc.html'] = page(
  `<div style="font-size: 20px; font-weight: 700; color: #4a4a4a;">Connect Canvas</div>
   ${bar(240, 8, '#ececec')}
   ${card([1, 2, 3].map((n) =>
     `<div style="display: flex; align-items: center; gap: 12px;"><div style="width: 24px; height: 24px; border-radius: 50%; background: #efefef; display: flex; align-items: center; justify-content: center; font-size: 12px; color: #888;">${n}</div><div style="${flex('column', 5)}">${bar(190, 8)}${bar(140, 7, '#efefef')}</div></div>`).join(''))}
   <div style="border: 1.5px dashed #c9c9c9; border-radius: 16px; padding: 24px; ${flex('column', 8, 'align-items: center;')}">
     ${lbl('pairing code')}
     <div style="font-size: 34px; font-weight: 700; letter-spacing: 0.2em; color: #4a4a4a;">A7X 99Q</div>
   </div>
   <div style="flex: 1;"></div>
   ${ghost("I'll do this later")}`,
  null);

// ---- Games hub
files['Games.dc.html'] = page(
  `<div style="font-size: 20px; font-weight: 700; color: #4a4a4a;">Games</div>
   ${card(`<div style="display: flex; align-items: center; gap: 12px;"><div style="width: 44px; height: 44px; background: #efefef; border-radius: 12px;"></div><div style="flex: 1; ${flex('column', 5)}"><div style="font-size: 14px; font-weight: 600; color: #555;">Daily Word</div>${bar(140, 7, '#efefef')}</div><div style="color: #bbb;">›</div></div>`)}
   ${card(`<div style="display: flex; align-items: center; gap: 12px; opacity: 0.55;"><div style="width: 44px; height: 44px; background: #efefef; border-radius: 12px;"></div><div style="flex: 1; ${flex('column', 5)}"><div style="font-size: 14px; font-weight: 600; color: #555;">Versus</div>${bar(170, 7, '#efefef')}</div>${pill('locked')}</div>`)}
   ${card(`${lbl("today's leaderboard")}` +
     [1, 2, 3, 4].map((n) =>
       `<div style="display: flex; align-items: center; gap: 10px;"><div style="width: 18px; font-size: 12px; color: #999;">${n}</div>${circle(26)}${bar(90, 9)}<div style="flex: 1;"></div><div style="font-size: 12px; font-weight: 700; color: #4a4a4a;">${n + 1}/6</div></div>`).join(''))}`,
  'Games');

// ---- Daily word (wordle)
const tile = (c) => `<div style="width: 44px; height: 44px; border: 1.5px solid ${c === '#fff' ? '#d8d8d8' : c}; background: ${c}; border-radius: 8px;"></div>`;
const tiles = (row) => `<div style="display: flex; gap: 6px; justify-content: center;">${row.map(tile).join('')}</div>`;
const keys = (n) => `<div style="display: flex; gap: 4px; justify-content: center;">${Array.from({ length: n }, () => `<div style="width: 28px; height: 40px; background: #efefef; border-radius: 6px;"></div>`).join('')}</div>`;
files['DailyWord.dc.html'] = page(
  `${back('Daily Word')}
   <div style="${flex('column', 6)}">
     ${tiles(['#c9c9c9', '#8fbf9f', '#c9c9c9', '#e6c98a', '#c9c9c9'])}
     ${tiles(['#8fbf9f', '#8fbf9f', '#c9c9c9', '#c9c9c9', '#8fbf9f'])}
     ${tiles(['#fff', '#fff', '#fff', '#fff', '#fff'])}
     ${tiles(['#fff', '#fff', '#fff', '#fff', '#fff'])}
     ${tiles(['#fff', '#fff', '#fff', '#fff', '#fff'])}
     ${tiles(['#fff', '#fff', '#fff', '#fff', '#fff'])}
   </div>
   <div style="border: 1.5px dashed #c9c9c9; border-radius: 12px; padding: 10px; text-align: center; font-size: 12px; color: #999;">result banner · +30 once a day</div>
   <div style="flex: 1;"></div>
   <div style="${flex('column', 6)}">${keys(10)}${keys(9)}${keys(9)}</div>`,
  null);

// ---- Learn
const lessonRow = (done) =>
  `<div style="display: flex; align-items: center; gap: 12px;"><div style="width: 38px; height: 38px; background: #efefef; border-radius: 10px;"></div><div style="flex: 1; ${flex('column', 5)}">${bar(160, 9)}${bar(90, 7, '#efefef')}</div><div style="font-size: 12px; font-weight: 600; color: ${done ? '#8fbf9f' : '#f26b4f'};">${done ? '✓' : '+20'}</div></div>`;
files['Learn.dc.html'] = page(
  `<div style="font-size: 20px; font-weight: 700; color: #4a4a4a;">Learn</div>
   ${lbl('personal finance')}
   ${card(lessonRow(true) + lessonRow(false))}
   ${lbl('philosophy')}
   ${card(lessonRow(false) + lessonRow(false))}
   ${lbl('study skills')}
   ${card(lessonRow(false))}`,
  'Learn');

// ---- Lesson player
files['Lesson.dc.html'] = page(
  `${back('Why compound interest wins')}
   <div style="flex: 1; ${flex('column', 16, 'justify-content: center;')}">
     ${card(`<div style="${flex('column', 10, 'align-items: center; padding: 24px 8px;')}">
       <div style="width: 44px; height: 44px; background: #efefef; border-radius: 12px;"></div>
       ${bar(240, 9, '#ececec')}${bar(220, 9, '#ececec')}${bar(180, 9, '#ececec')}
     </div>`)}
     <div style="display: flex; gap: 6px; justify-content: center;">${circle(7, '#bbb')}${circle(7, '#e3e3e3')}${circle(7, '#e3e3e3')}${circle(7, '#e3e3e3')}</div>
   </div>
   ${btn('Finish · +20 coins')}`,
  null);

// ---- Friends
const friendRow = () =>
  `<div style="display: flex; align-items: center; gap: 12px;">${blob(40, 32)}<div style="flex: 1; ${flex('column', 5)}">${bar(80, 9)}${bar(130, 7, '#efefef')}</div></div>`;
files['Friends.dc.html'] = page(
  `<div style="display: flex; align-items: center; justify-content: space-between;"><div style="font-size: 20px; font-weight: 700; color: #4a4a4a;">Friends</div>${pill('+ add')}</div>
   <div style="display: flex; gap: 14px;">
     ${['You', 'Maya', 'Josh', 'Ava', 'Sam'].map((n, i) =>
       `<div style="${flex('column', 5, 'align-items: center;')}"><div style="width: 58px; height: 58px; border-radius: 50%; border: 2px solid ${i === 0 ? '#d8d8d8' : '#f26b4f'}; display: flex; align-items: center; justify-content: center;">${blob(38, 30)}</div><div style="font-size: 10px; color: #888;">${n}</div></div>`).join('')}
   </div>
   ${card(`${lbl("this week's coins")}` +
     [1, 2, 3, 4].map((n) =>
       `<div style="display: flex; align-items: center; gap: 10px;"><div style="width: 18px; font-size: 12px; color: #999;">${n}</div>${circle(24)}${bar(80, 9)}<div style="flex: 1;"></div>${bar(34, 10)}</div>`).join(''))}
   ${card(lbl('friends') + friendRow() + friendRow() + friendRow())}`,
  'Friends');

// ---- Story viewer
files['Story.dc.html'] = page(
  `<div style="display: flex; gap: 4px;">${Array.from({ length: 4 }, (_, i) => `<div style="flex: 1; height: 3px; border-radius: 2px; background: ${i < 2 ? '#bbb' : '#e6e6e6'};"></div>`).join('')}</div>
   <div style="display: flex; align-items: center; gap: 10px;">${circle(34)}${bar(70, 9)}${bar(40, 7, '#efefef')}</div>
   <div style="flex: 1; border: 1.5px dashed #c9c9c9; border-radius: 20px; ${flex('column', 12, 'align-items: center; justify-content: center;')}">
     ${blob(110, 88)}
     ${bar(180, 10)}
     ${bar(130, 8, '#ececec')}
   </div>
   <div style="border: 1.5px solid #d8d8d8; border-radius: 999px; padding: 12px 16px; font-size: 12px; color: #aaa;">Send a cheer…</div>`,
  null);

// ---- Shop
const speciesCard = (owned) =>
  `<div style="border: 1.5px solid #d8d8d8; border-radius: 16px; padding: 16px; ${flex('column', 8, 'align-items: center;')}">
     ${blob(80, 64)}
     ${bar(60, 9)}
     ${owned ? pill('Use') : btn('300')}
   </div>`;
files['Shop.dc.html'] = page(
  `<div style="display: flex; align-items: center; justify-content: space-between;"><div style="font-size: 20px; font-weight: 700; color: #4a4a4a;">Shop</div>${pill('coins 120')}</div>
   <div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px;">
     ${speciesCard(true)}${speciesCard(false)}${speciesCard(false)}${speciesCard(false)}
   </div>
   ${card(`${lbl('coming later')}${bar(200, 8, '#ececec')}`)}`,
  'Shop');

for (const [name, html] of Object.entries(files)) writeFileSync(name, html);
console.log('wrote', Object.keys(files).length, 'artboards');
