// Two real players against the real bridge, end to end.
//
// `fake-friend.js` plays a second person you can add by hand from the phone. This
// one needs no phone at all: it mints both sides, walks the whole friendship —
// code, add, list, shift, today, wave, board, report, block — and deletes both
// players afterwards, so running it twice leaves nothing behind.
//
//   node test/live-friends.js
//
// It calls every function with the exact parameter names ios/Sources/FriendSync.swift
// sends, so it fails if the Swift client and the SQL ever drift apart. It reads
// ios/Resources/bridge-config.json, the same file the app reads.
//
// Three of these checks exist because the allowlists had already drifted once:
// a `dusk` scene and a `ninja` costume have to survive `set_tank`, and all six
// shipped games have to survive `push_result` — `sort` and `weave` were rejected
// outright until bridge/schema-social.sql was fixed on 2026-09-10.
//
// Exits non-zero on the first thing that is wrong.

const fs=require('fs');
const {url,publishableKey:key}=JSON.parse(fs.readFileSync('ios/Resources/bridge-config.json','utf8'));
const base=url.replace(/\/$/,'');
let fails=0;
async function rpc(fn, body){
  const res=await fetch(`${base}/rest/v1/rpc/${fn}`,{method:'POST',
    headers:{apikey:key,Authorization:`Bearer ${key}`,'Content-Type':'application/json'},
    body:JSON.stringify(body)});
  const t=await res.text();
  let v=null; try{v=t?JSON.parse(t):null;}catch{v=t;}
  if(res.status<200||res.status>=300){ fails++; console.log(`  FAIL ${fn} ${res.status} ${String(t).slice(0,120)}`); }
  return v;
}
const ok=(label,cond,extra='')=>{ if(!cond) fails++; console.log(`${cond?'  ok  ':'  FAIL'} ${label}${extra?'  '+extra:''}`); };
const day=(d=new Date())=>`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;

(async()=>{
  const A=await rpc('create_player',{}); const B=await rpc('create_player',{});
  const a={p_player:A.id,p_token:A.token}, b={p_player:B.id,p_token:B.token};
  console.log(`two players minted`);

  // A sets a kin and a tank, exactly as the app does.
  await rpc('join_pod',{...a,p_species:'ember',p_look:'classic',p_level:3});
  await rpc('set_tank',{...a,p_costume:'ninja',p_scene:'dusk'});

  const code=await rpc('my_code',a);
  ok('my_code returns 8 characters', typeof code==='string'&&code.length===8, String(code));

  // B adds A by code.
  const added=await rpc('add_friend',{...b,p_code:code});
  ok('add_friend returns the public row', added&&added.id===A.id);
  ok('  ...carrying the scene that was set', added&&added.scene==='dusk',
     `got ${added&&added.scene}`);
  ok('  ...and the costume', added&&added.costume==='ninja', `got ${added&&added.costume}`);
  ok('  ...and the kin', added&&added.species==='ember'&&added.level===3,
     `got ${added&&added.species}/${added&&added.level}`);

  const wrong=await rpc('add_friend',{...b,p_code:'ZZZZZZZZ'});
  ok('a wrong code opens nothing', wrong===null);

  // Both directions.
  const listB=await rpc('fetch_friends',b), listA=await rpc('fetch_friends',a);
  ok('fetch_friends: B sees A', Array.isArray(listB)&&listB.length===1&&listB[0].id===A.id);
  ok('fetch_friends: A sees B without accepting', Array.isArray(listA)&&listA.length===1);
  ok('the row carries a friendship date', listB[0]&&typeof listB[0].since==='string');

  // On shift shows up in the list.
  await rpc('start_focus',{...a,p_minutes:25});
  const onShift=await rpc('fetch_friends',b);
  ok('a shift shows on the friend row', onShift[0]&&typeof onShift[0].shift==='string');

  // Today, both ways round the new default.
  await rpc('push_today',{...a,p_day:day(),p_tasks:4,p_focus:75,p_lessons:2,p_games:3});
  let seen=await rpc('fetch_today',{...b,p_from:day(),p_to:day()});
  const rowsOfA=(x)=>(Array.isArray(x)?x:[]).filter(r=>r.id===A.id);
  ok('share_today defaults OFF, so B sees nothing', rowsOfA(seen).length===0,
     `rows: ${rowsOfA(seen).length}`);
  await rpc('set_sharing',{...a,p_today:true,p_board:true});
  seen=await rpc('fetch_today',{...b,p_from:day(),p_to:day()});
  ok('after turning it on, B sees the four counts', rowsOfA(seen).length===1);
  ok('  ...with the right numbers', rowsOfA(seen)[0]&&rowsOfA(seen)[0].focus===75,
     JSON.stringify(rowsOfA(seen)[0]||{}));

  // The wave.
  const sent1=await rpc('send_vibe',{...a,p_friend:B.id,p_kind:0,p_day:day()});
  const sent2=await rpc('send_vibe',{...a,p_friend:B.id,p_kind:0,p_day:day()});
  ok('the first wave lands', sent1===true);
  ok('the second the same day does not', sent2===false);
  const visits=await rpc('fetch_visits',{...b,p_day:day()});
  ok('B sees the wave', Array.isArray(visits)&&visits.length===1&&visits[0].id===A.id);
  ok('  ...carrying the card index', visits[0]&&visits[0].kind===0);
  const mine=await rpc('fetch_sent',{...a,p_day:day()});
  ok('A sees who they waved at', Array.isArray(mine)&&mine.includes(B.id));

  // The board, including the two games the old constraint would have thrown on.
  for(const g of ['word','balance','pearls','trace','sort','weave']){
    await rpc('push_result',{...a,p_puzzle:253,p_game:g,p_solved:true,p_seconds:90});
  }
  const board=await rpc('friend_board',{...b,p_puzzle:253});
  const rowA=(board||[]).find(r=>r.id===A.id);
  ok('all six games push, sort and weave included',
     rowA&&Object.keys(rowA.games||{}).length===6, `got ${rowA?Object.keys(rowA.games||{}).length:0}`);

  // Report leaves the friendship; block ends it.
  await rpc('report_player',{...b,p_other:A.id});
  ok('report leaves them on the list', (await rpc('fetch_friends',b)).length===1);
  await rpc('block_player',{...b,p_other:A.id});
  ok('block ends the friendship', (await rpc('fetch_friends',b)).length===0);
  const reAdd=await rpc('add_friend',{...b,p_code:code});
  ok('a blocked code opens nothing, same answer as a wrong one', reAdd===null);

  // Clean up after ourselves.
  await rpc('forget_player',a); await rpc('forget_player',b);
  console.log(fails===0?'\nall checks passed':`\n${fails} FAILED`);
  process.exit(fails===0?0:1);
})();
