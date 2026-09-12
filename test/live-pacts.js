// The race handshake against the real bridge, end to end.
//
// Mints two players, makes them friends, and walks the pact: invite, invite again
// (same row), the other side sees it, accepts, both see it on, a stranger cannot
// invite, the proposer cannot answer their own invite, decline hides it. Deletes
// both players afterwards, so running it twice leaves nothing behind.
//
//   node test/live-pacts.js
//
// Needs bridge/schema-pacts.sql pasted after schema-friends.sql. Calls every
// function with the exact parameter names ios/Sources/FriendSync.swift sends, so
// it fails if the Swift client and the SQL ever drift apart. Exits non-zero on the
// first thing that is wrong.

const fs=require('fs');
const {url,publishableKey:key}=JSON.parse(fs.readFileSync('ios/Resources/bridge-config.json','utf8'));
const base=url.replace(/\/$/,'');
let fails=0;
async function rpc(fn, body, expectFail=false){
  const res=await fetch(`${base}/rest/v1/rpc/${fn}`,{method:'POST',
    headers:{apikey:key,Authorization:`Bearer ${key}`,'Content-Type':'application/json'},
    body:JSON.stringify(body)});
  const t=await res.text();
  let v=null; try{v=t?JSON.parse(t):null;}catch{v=t;}
  const bad=res.status<200||res.status>=300;
  if(bad&&!expectFail){ fails++; console.log(`  FAIL ${fn} ${res.status} ${String(t).slice(0,120)}`); }
  return expectFail?{status:res.status,body:v}:v;
}
const ok=(label,cond,extra='')=>{ if(!cond) fails++; console.log(`${cond?'  ok  ':'  FAIL'} ${label}${extra?'  '+extra:''}`); };

// The ISO week, the way ios/Sources/Core/DayKey.swift writes it: '2026-W37'.
function isoWeek(d=new Date()){
  const t=new Date(Date.UTC(d.getFullYear(),d.getMonth(),d.getDate()));
  const day=t.getUTCDay()||7; t.setUTCDate(t.getUTCDate()+4-day);
  const y=t.getUTCFullYear(); const w=Math.ceil((((t-Date.UTC(y,0,1))/86400000)+1)/7);
  return `${y}-W${String(w).padStart(2,'0')}`;
}

(async()=>{
  const A=await rpc('create_player',{}); const B=await rpc('create_player',{}); const C=await rpc('create_player',{});
  const a={p_player:A.id,p_token:A.token}, b={p_player:B.id,p_token:B.token}, c={p_player:C.id,p_token:C.token};
  console.log('three players minted');
  const week=isoWeek();

  // A and B are friends; C is a stranger.
  const code=await rpc('my_code',a);
  await rpc('add_friend',{...b,p_code:code});

  // A invites B.
  const p1=await rpc('propose_pact',{...a,p_other:B.id,p_week:week});
  ok('propose_pact returns the pact', p1&&typeof p1.id==='string'&&p1.week===week, JSON.stringify(p1));
  ok('  ...as mine, not yet accepted', p1&&p1.mine===true&&p1.accepted===false);
  ok('  ...carrying the other side', p1&&p1.other&&p1.other.id===B.id);
  const p2=await rpc('propose_pact',{...a,p_other:B.id,p_week:week});
  ok('inviting twice is the same invite', p2&&p2.id===p1.id);

  // A stranger cannot.
  const s=await rpc('propose_pact',{...c,p_other:A.id,p_week:week},true);
  ok('a stranger cannot invite', s.status>=400, `status ${s.status}`);

  // B sees it, A cannot answer it.
  const seenB=await rpc('fetch_pacts',{...b,p_from:week});
  ok('B sees the invite, not as theirs', Array.isArray(seenB)&&seenB.length===1&&seenB[0].mine===false);
  const self=await rpc('answer_pact',{...a,p_id:p1.id,p_accept:true},true);
  ok('the proposer cannot answer their own invite', self.status>=400, `status ${self.status}`);

  // B accepts; both see it on.
  const acc=await rpc('answer_pact',{...b,p_id:p1.id,p_accept:true});
  ok('answer_pact accepts', acc&&acc.accepted===true&&acc.declined===false);
  const onA=await rpc('fetch_pacts',{...a,p_from:week});
  ok('A sees the race on', onA&&onA.length===1&&onA[0].accepted===true&&onA[0].other.id===B.id);
  const again=await rpc('answer_pact',{...b,p_id:p1.id,p_accept:false});
  ok('an answer is final', again&&again.accepted===true, 'declining after accepting changes nothing');

  // A second pair, declined, disappears from both lists.
  const codeC=await rpc('my_code',c);
  await rpc('add_friend',{...b,p_code:codeC});
  const p3=await rpc('propose_pact',{...c,p_other:B.id,p_week:week});
  await rpc('answer_pact',{...b,p_id:p3.id,p_accept:false});
  const afterB=await rpc('fetch_pacts',{...b,p_from:week});
  ok('a declined invite is not listed', afterB&&afterB.every(p=>p.id!==p3.id));

  // Clean up after ourselves.
  await rpc('forget_player',a); await rpc('forget_player',b); await rpc('forget_player',c);
  console.log(fails===0?'\nall checks passed':`\n${fails} FAILED`);
  process.exit(fails===0?0:1);
})();
