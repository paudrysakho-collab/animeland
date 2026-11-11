"use strict";
const $=s=>document.querySelector(s);
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const rnd=(a,b)=>a+Math.random()*(b-a);
const rint=(a,b)=>Math.floor(rnd(a,b+1));
const pick=a=>a[Math.floor(Math.random()*a.length)];
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
function store(k,v){try{if(v===undefined)return JSON.parse(localStorage.getItem(k));if(v===null)localStorage.removeItem(k);else localStorage.setItem(k,JSON.stringify(v))}catch(e){return null}}
function wpick(list){let t=list.reduce((s,x)=>s+(x.w||1),0),r=Math.random()*t;for(const x of list){if((r-=(x.w||1))<0)return x}return list[0]}

/* ================= DONNÉES DE NAISSANCE ================= */
const EL={feu:"Feu",glace:"Glace",foudre:"Foudre",lumiere:"Lumière",ombre:"Ombre",phys:"Physique"};
const ELS=["feu","glace","foudre","lumiere","ombre"];
const STATS=[["FOR","Force"],["VIT","Vitalité"],["INT","Intelligence"],["ESP","Esprit"],["AGI","Agilité"],["CHA","Charisme"],["CHN","Chance"]];
const RACES=[
 {id:"humain",n:"Humain",w:34,d:"Polyvalent, sans faiblesse.",delta:{CHA:1,CHN:1,VIT:1},look:{skin:"#e9c3a0"}},
 {id:"elfe",n:"Elfe",w:10,d:"Magie vive, corps fragile.",delta:{INT:3,ESP:2,AGI:1,VIT:-2,FOR:-1},elb:{lumiere:12},look:{skin:"#f1d9bf",ears:"elf"}},
 {id:"nain",n:"Nain",w:10,d:"Solide comme la roche.",delta:{VIT:3,FOR:2,AGI:-2,CHA:-1},elb:{feu:10},look:{skin:"#d9a98a",beard:1}},
 {id:"loup",n:"Homme-loup",w:8,d:"Force et sens aiguisés.",delta:{FOR:3,AGI:2,INT:-2},look:{skin:"#d4b08c",ears:"beast",tail:"#8a8a94"}},
 {id:"chat",n:"Homme-chat",w:8,d:"Agile et chanceux.",delta:{AGI:4,CHN:2,VIT:-2},look:{skin:"#e2bd98",ears:"beast",tail:"#d9a35a"}},
 {id:"renard",n:"Homme-renard",w:6,d:"Rusé, bon avec les esprits.",delta:{ESP:3,CHA:2,FOR:-1},elb:{feu:10,ombre:8},look:{skin:"#e8c8a6",ears:"beast",tail:"#d6702e"}},
 {id:"lezard",n:"Homme-lézard",w:5,d:"Écailles dures, sang froid.",delta:{VIT:3,FOR:2,CHA:-3},elb:{foudre:8},look:{skin:"#7fae7a",tail:"#6a9a66"}},
 {id:"esprit",n:"Demi-esprit",w:5,d:"Né de la magie pure.",delta:{INT:4,ESP:4,VIT:-3,FOR:-2},elb:{lumiere:10,ombre:10,glace:10,feu:10,foudre:10},look:{skin:"#cfe3f2",ears:"elf"}},
 {id:"dragon",n:"Demi-dragon",w:3,d:"Sang de dragon, puissance brute.",delta:{FOR:4,VIT:3,INT:1,CHA:-1},elb:{feu:25},look:{skin:"#d9a98a",horns:1,tail:"#b0452e"}},
 {id:"ange",n:"Demi-ange",w:1,d:"Un souffle céleste. Très rare.",delta:{ESP:5,INT:3,CHA:3,CHN:2},elb:{lumiere:30},look:{skin:"#f6e8d4",wings:"#f4f0e2"}},
 {id:"demon",n:"Demi-démon",w:1,d:"Une ombre dans le sang. Très rare.",delta:{INT:4,FOR:3,CHA:-2,CHN:-1},elb:{ombre:30,feu:10},look:{skin:"#c9a0a8",horns:1,wings:"#4a2a5a",tail:"#4a2a5a"}}];
const PLACES=[
 {id:"capitale",n:"Capitale du royaume",w:10,d:"Écoles, guildes, intrigues.",delta:{INT:1,CHA:1}},
 {id:"village",n:"Village paisible",w:20,d:"Une enfance simple.",delta:{VIT:1,CHN:1}},
 {id:"foret",n:"Forêt ancienne",w:12,d:"Les esprits murmurent.",delta:{ESP:2,AGI:1},elb:{lumiere:6}},
 {id:"montagne",n:"Montagne glacée",w:10,d:"Le froid forge le corps.",delta:{VIT:2,FOR:1},elb:{glace:12}},
 {id:"desert",n:"Désert aride",w:8,d:"Chaleur et survie.",delta:{VIT:1,AGI:1,ESP:1},elb:{feu:12}},
 {id:"ile",n:"Île lointaine",w:9,d:"Marins et orages.",delta:{AGI:1,CHN:1},elb:{foudre:12}},
 {id:"port",n:"Ville portuaire",w:14,d:"Commerce et rencontres.",delta:{CHA:2,CHN:1}},
 {id:"ruines",n:"Ruines maudites",w:3,d:"Les morts n'y dorment pas.",delta:{ESP:2,CHN:-1},elb:{ombre:18}}];
const FAMILIES=[
 {id:"royale",n:"Famille royale",w:1.5,d:"Pouvoir et dangers.",delta:{CHA:4,INT:2,VIT:-1},gold:900},
 {id:"noble",n:"Famille noble",w:6,d:"Éducation soignée.",delta:{INT:2,CHA:2},gold:400},
 {id:"marchand",n:"Famille de marchands",w:14,d:"Le sens des affaires.",delta:{CHA:3,CHN:1},gold:300},
 {id:"aventurier",n:"Famille d'aventuriers",w:12,d:"Récits de donjons.",delta:{FOR:2,AGI:2},gold:150},
 {id:"paysan",n:"Famille de paysans",w:24,d:"Corps endurci.",delta:{VIT:3,FOR:1},gold:60},
 {id:"forgeron",n:"Famille de forgerons",w:8,d:"Bras puissants.",delta:{FOR:3,VIT:1},gold:120},
 {id:"mage",n:"Famille de mages de cour",w:5,d:"La magie dès le berceau.",delta:{INT:4,ESP:1},gold:350},
 {id:"clerge",n:"Famille du clergé",w:6,d:"Foi et soins.",delta:{ESP:3,INT:1},gold:100},
 {id:"voleur",n:"Famille de voleurs",w:5,d:"Mains agiles.",delta:{AGI:4,CHN:1},gold:80},
 {id:"orphelin",n:"Orphelin des rues",w:9,d:"Instinct de survie.",delta:{CHN:2,VIT:1,AGI:1},gold:0}];
const GODS=[
 {id:"aucun",n:"Aucune divinité",w:30,d:"Tu n'as vu personne avant de naître.",delta:{}},
 {id:"chance",n:"Déesse de la chance",w:8,d:"Elle t'a souri.",delta:{CHN:5}},
 {id:"guerre",n:"Dieu de la guerre",w:8,d:"Il aime les combattants.",delta:{FOR:3,VIT:2}},
 {id:"sagesse",n:"Déesse de la sagesse",w:8,d:"Elle t'a offert sa mémoire.",delta:{INT:4,ESP:1}},
 {id:"nature",n:"Esprit de la nature",w:8,d:"Une brise dans ton âme.",delta:{ESP:3,AGI:2}},
 {id:"marchands",n:"Dieu du commerce",w:6,d:"Il rit et te tend la main.",delta:{CHA:4,CHN:1}},
 {id:"lune",n:"Déesse de la lune",w:5,d:"Ombre et douceur.",delta:{ESP:2,INT:1},elb:{ombre:25}},
 {id:"soleil",n:"Dieu du soleil",w:5,d:"Il éclaire ta route.",delta:{VIT:2,CHA:1},elb:{lumiere:25}},
 {id:"forge",n:"Dieu de la forge",w:5,d:"Le feu est ton ami.",delta:{FOR:2,VIT:1},elb:{feu:25}},
 {id:"tempete",n:"Dieu de la tempête",w:4,d:"Le tonnerre te suit.",delta:{AGI:2,ESP:1},elb:{foudre:25}},
 {id:"hiver",n:"Déesse de l'hiver",w:4,d:"Calme et glaciale.",delta:{INT:2,VIT:1},elb:{glace:25}}];
const TRAITS=[
 {n:"Courageux",d:"Force +2",delta:{FOR:2}},{n:"Peureux",d:"Force -2, Agilité +2",delta:{FOR:-2,AGI:2}},
 {n:"Prodige précoce",d:"Intelligence +4",delta:{INT:4}},{n:"Santé fragile",d:"Vitalité -4",delta:{VIT:-4}},
 {n:"Corps d'acier",d:"Vitalité +3",delta:{VIT:3}},{n:"Œil de lynx",d:"Agilité +3",delta:{AGI:3}},
 {n:"Charmeur né",d:"Charisme +4",delta:{CHA:4}},{n:"Timide",d:"Charisme -3, Esprit +2",delta:{CHA:-3,ESP:2}},
 {n:"Maladroit",d:"Agilité -3",delta:{AGI:-3}},{n:"Méditatif",d:"Esprit +3",delta:{ESP:3}},
 {n:"Né sous une bonne étoile",d:"Chance +4",delta:{CHN:4}},{n:"Poisse chronique",d:"Chance -4, Vitalité +1",delta:{CHN:-4,VIT:1}},
 {n:"Têtu",d:"Intelligence -2, Vitalité +2",delta:{INT:-2,VIT:2}},{n:"Curieux",d:"Intelligence +2, Chance +1",delta:{INT:2,CHN:1}},
 {n:"Colérique",d:"Force +3, Esprit -2",delta:{FOR:3,ESP:-2}},{n:"Rêveur",d:"Esprit +2, Force -1",delta:{ESP:2,FOR:-1}},
 {n:"Mémoire d'une autre vie",d:"Intelligence +2, Esprit +1",delta:{INT:2,ESP:1}},{n:"Insomniaque",d:"Esprit +1, Vitalité -1",delta:{ESP:1,VIT:-1}}];
const CURSE={n:"Sang maudit",d:"Quelque chose dort en toi... Immense magie, corps rongé.",delta:{INT:5,VIT:-4,CHN:-2},elb:{ombre:30}};
const CHEATS=[
 {id:"barriere",n:"Barrière innée",r:"commun",d:"Commence chaque combat avec un bouclier de 30."},
 {id:"regen",n:"Régénération",r:"commun",d:"Te soigne de 5 % de ta vie chaque tour."},
 {id:"memoire",n:"Mémoire de vie passée",r:"commun",d:"+2 énergie au début du combat."},
 {id:"oeil",n:"Œil du système",r:"rare",d:"+15 % de dégâts sur les points faibles."},
 {id:"critique",n:"Chance du démon",r:"rare",d:"+15 % de coups critiques."},
 {id:"absorption",n:"Absorption vitale",r:"rare",d:"Soigne 20 % de ta vie quand un ennemi tombe."},
 {id:"flux",n:"Flux de mana infini",r:"epique",d:"+1 énergie de plus à chaque tour."},
 {id:"boucle",n:"Boucle temporelle",r:"legendaire",d:"Une fois par combat, tu reviens à 50 % de vie."}];
const CHEAT_R={commun:{n:"Commun",w:52,s:0},rare:{n:"Rare",w:30,s:6},epique:{n:"Épique",w:14,s:12},legendaire:{n:"Légendaire",w:4,s:20}};
const HAIR=["#2a1d17","#6b4a2f","#c8a45a","#e8e2d0","#b0352e","#3b4f9c","#2f7a58","#7a4aa8"];
const EYES=["#5a3b24","#2f6aa3","#3a8f4e","#a8742a","#7a4aa8","#b0352e"];
const SIB=["fils unique","un frère","une sœur","deux frères","deux sœurs","un frère et une sœur","quatre frères et sœurs"];

function rollBirth(name){
  const race=wpick(RACES),place=wpick(PLACES),fam=wpick(FAMILIES),god=wpick(GODS);
  const traitPool=[...TRAITS].sort(()=>Math.random()-.5);
  const nt=Math.random()<.3?3:2;const traits=traitPool.slice(0,nt).map(t=>t.n);
  const cursed=Math.random()<.07;
  const cr=wpick(Object.entries(CHEAT_R).map(([id,v])=>({id,w:v.w})));
  const cheat=pick(CHEATS.filter(c=>c.r===cr.id));
  const base={};STATS.forEach(([k])=>base[k]=6+rint(0,6)+rint(0,6));
  const aff={};ELS.forEach(e=>aff[e]=rint(0,38));
  const main=pick(ELS);aff[main]=rint(52,100);
  const sec=pick(ELS.filter(e=>e!==main));aff[sec]=Math.max(aff[sec],rint(30,60));
  return{v:2,name:(name||"").trim()||"Voyageur",race:race.id,place:place.id,fam:fam.id,god:god.id,traits,cursed,cheat:cheat.id,
    base,aff,hair:pick(HAIR),eyes:pick(EYES),sib:rint(0,SIB.length-1),seed:Date.now()};
}
const byId=(a,id)=>a.find(x=>x.id===id);
const byName=(a,n)=>a.find(x=>x.n===n);
/* applique toutes les sources de bonus */
function computeChar(b){
  const race=byId(RACES,b.race),place=byId(PLACES,b.place),fam=byId(FAMILIES,b.fam),god=byId(GODS,b.god),cheat=byId(CHEATS,b.cheat);
  const sources=[race,place,fam,god,...b.traits.map(n=>byName(TRAITS,n))];if(b.cursed)sources.push(CURSE);
  const st={};STATS.forEach(([k])=>st[k]=b.base[k]);
  const aff={...b.aff};
  sources.forEach(s=>{for(const k in (s.delta||{}))st[k]+=s.delta[k];for(const e in (s.elb||{}))aff[e]=(aff[e]||0)+s.elb[e]});
  STATS.forEach(([k])=>st[k]=clamp(st[k],1,30));ELS.forEach(e=>aff[e]=clamp(aff[e],0,100));
  const total=STATS.reduce((s,[k])=>s+st[k],0);
  const top=Math.max(...ELS.map(e=>aff[e]));
  const score=total+top/5+CHEAT_R[cheat.r].s+(b.cursed?8:0);
  const grade=score<98?"D":score<108?"C":score<118?"B":score<130?"A":score<142?"S":"SS";
  return{race,place,fam,god,cheat,st,aff,total,score,grade,gold:fam.gold};
}
const sortedEl=aff=>[...ELS].sort((a,b)=>aff[b]-aff[a]);

/* ================= SPRITES (images provisoires dessinées en SVG) ================= */
function heroSVG(o){
  const s=o.skin,hair=o.hair,out=o.outfit,dk=o.outfitDark,eye=o.eyes||"#222";
  let g='<svg viewBox="0 0 100 130" xmlns="http://www.w3.org/2000/svg"><ellipse cx="50" cy="124" rx="28" ry="6" fill="rgba(0,0,0,.45)"/>';
  if(o.wings)g+='<path d="M40 56 Q4 22 6 74 Q22 62 42 86Z" fill="'+o.wings+'" opacity=".85"/>';
  if(o.tail)g+='<path d="M32 98 Q8 96 12 70" stroke="'+o.tail+'" stroke-width="7" fill="none" stroke-linecap="round"/>';
  g+='<path d="M36 52 Q22 88 28 118 L74 118 Q70 84 64 52Z" fill="'+dk+'"/>';
  g+='<rect x="40" y="96" width="9" height="24" rx="3" fill="#2a2230"/><rect x="54" y="96" width="9" height="24" rx="3" fill="#2a2230"/>';
  g+='<path d="M34 52 H68 L74 100 H30Z" fill="'+out+'"/><rect x="31" y="78" width="42" height="5" fill="'+dk+'"/>';
  g+='<path d="M62 60 L82 72" stroke="'+s+'" stroke-width="7" stroke-linecap="round"/>';
  if(o.weapon==="sword")g+='<rect x="80" y="30" width="4" height="48" rx="1.5" fill="#d6dbe3"/><rect x="74" y="74" width="16" height="4" rx="1.5" fill="#8a6a2c"/>';
  else if(o.weapon==="bow")g+='<path d="M84 30 Q104 76 84 122" stroke="#7b5a34" stroke-width="3.5" fill="none"/><line x1="84" y1="30" x2="84" y2="122" stroke="#ddd" stroke-width="1"/>';else g+='<line x1="86" y1="30" x2="82" y2="122" stroke="#7b5a34" stroke-width="4" stroke-linecap="round"/><circle cx="86" cy="26" r="8" fill="'+o.orb+'"/><circle cx="86" cy="26" r="13" fill="'+o.orb+'" opacity=".25"/>';
  g+='<circle cx="52" cy="34" r="16" fill="'+s+'"/>';
  if(o.beard)g+='<path d="M42 40 Q52 70 66 40Z" fill="'+hair+'"/>';
  g+='<path d="M35 34 Q34 12 54 14 Q72 16 68 34 Q60 22 48 24 Q40 26 35 34Z" fill="'+hair+'"/><path d="M36 32 Q28 50 36 64 Q44 58 44 44Z" fill="'+hair+'"/>';
  if(o.ears==="elf")g+='<path d="M40 32 L24 26 L38 42Z" fill="'+s+'"/>';
  if(o.ears==="beast")g+='<path d="M42 22 L38 6 L54 16Z" fill="'+hair+'"/><path d="M56 17 L66 6 L68 24Z" fill="'+hair+'"/>';
  if(o.horns)g+='<path d="M48 19 Q44 4 54 2 Q50 10 54 19Z" fill="#e8dcc0"/><path d="M58 19 Q60 6 68 6 Q62 12 64 21Z" fill="#e8dcc0"/>';
  g+='<circle cx="62" cy="36" r="2.4" fill="'+eye+'"/><path d="M58 44 Q62 46 65 43" stroke="#5a3b3b" stroke-width="1.4" fill="none"/></svg>';
  return g;
}
function darken(hex,f){const n=parseInt(hex.slice(1),16),r=(n>>16)&255,g=(n>>8)&255,b=n&255;return"#"+[r,g,b].map(v=>Math.round(v*f).toString(16).padStart(2,"0")).join("")}
const ELCOL={feu:"#e8743b",glace:"#6cc4e8",foudre:"#f2d64b",lumiere:"#fff2b0",ombre:"#9a6bd6",phys:"#cfc7b4"};
function heroLook(b,c){
  const el=sortedEl(c.aff)[0],col=ELCOL[el];
  return{...c.race.look,hair:b.hair,eyes:b.eyes,outfit:darken(col,.62),outfitDark:darken(col,.34),orb:col,weapon:"staff"};
}
const KAEL_LOOK={skin:"#d9b08c",hair:"#3a2a22",eyes:"#5a3b24",outfit:"#7a3b34",outfitDark:"#4a2420",weapon:"sword"};
const LYSA_LOOK={skin:"#f1d9bf",hair:"#e8e2d0",eyes:"#2f6aa3",outfit:"#d8cba0",outfitDark:"#8f8458",orb:"#fff2b0",weapon:"staff",ears:"elf"};
const ENEMY_SVG={
 loup:'<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><ellipse cx="60" cy="114" rx="40" ry="6" fill="rgba(0,0,0,.45)"/><path d="M92 74 Q116 64 114 36 Q102 54 88 58Z" fill="#7fa6c4"/><ellipse cx="68" cy="78" rx="32" ry="20" fill="#9cc0da"/><rect x="42" y="90" width="9" height="22" rx="3" fill="#7fa6c4"/><rect x="56" y="92" width="9" height="20" rx="3" fill="#6b92b0"/><rect x="76" y="90" width="9" height="22" rx="3" fill="#7fa6c4"/><rect x="88" y="92" width="9" height="20" rx="3" fill="#6b92b0"/><circle cx="38" cy="64" r="20" fill="#b4d3e8"/><ellipse cx="18" cy="72" rx="15" ry="9" fill="#cfe6f4"/><path d="M30 48 L26 28 L44 42Z M46 44 L56 28 L58 48Z" fill="#9cc0da"/><circle cx="34" cy="60" r="3.2" fill="#8ff"/><circle cx="10" cy="70" r="2.6" fill="#223"/><path d="M60 62 L64 50 L70 62 L78 54 L80 66Z" fill="#e6f6ff"/></svg>',
 spectre:'<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg"><ellipse cx="60" cy="114" rx="30" ry="5" fill="rgba(0,0,0,.35)"/><path d="M24 104 Q18 36 60 14 Q102 36 96 104 L86 94 L74 106 L60 94 L46 106 L34 94Z" fill="#9a6bd6" opacity=".9"/><path d="M34 98 Q30 48 60 26 Q90 48 86 98Z" fill="#c2a2ef" opacity=".5"/><ellipse cx="46" cy="52" rx="7" ry="10" fill="#120a1f"/><ellipse cx="74" cy="52" rx="7" ry="10" fill="#120a1f"/><circle cx="46" cy="52" r="3" fill="#fff2b0"/><circle cx="74" cy="52" r="3" fill="#fff2b0"/><ellipse cx="60" cy="76" rx="8" ry="10" fill="#120a1f"/></svg>',
 golem:'<svg viewBox="0 0 160 160" xmlns="http://www.w3.org/2000/svg"><ellipse cx="80" cy="152" rx="56" ry="7" fill="rgba(0,0,0,.5)"/><rect x="46" y="96" width="30" height="52" rx="6" fill="#4d4a58"/><rect x="84" y="96" width="30" height="52" rx="6" fill="#42404d"/><rect x="38" y="46" width="84" height="66" rx="10" fill="#5d5a6a"/><rect x="14" y="52" width="26" height="62" rx="8" fill="#4d4a58"/><rect x="120" y="52" width="26" height="62" rx="8" fill="#4d4a58"/><rect x="58" y="14" width="44" height="40" rx="8" fill="#6b6879"/><rect x="66" y="28" width="10" height="8" fill="#f2d64b"/><rect x="84" y="28" width="10" height="8" fill="#f2d64b"/><path d="M80 52 L70 74 L82 74 L74 100 L96 70 L84 70 L92 52Z" fill="#f2d64b"/><path d="M44 60 L52 74 L46 86" stroke="#f2d64b" stroke-width="3" fill="none"/><path d="M118 62 L110 76 L116 90" stroke="#f2d64b" stroke-width="3" fill="none"/></svg>'};

/* ================= PERSONNAGES ET ENNEMIS ================= */
function buildHero(b){
  const c=computeChar(b),st=c.st,order=sortedEl(c.aff),m=order[0],m2=order[1];
  const hp=Math.round(55+st.VIT*5);
  const mult=e=>.9+c.aff[e]/100*.6;
  const sk=[
   {id:"frappe",n:"Frappe",cost:0,stat:"atk",power:1.0,el:"phys",t:"enemy",d:"Gratuit. +1 énergie."},
   {id:"sort1",n:"Sort de "+EL[m].toLowerCase(),cost:2,stat:"mag",power:1.6,el:m,t:"enemy",d:"Ton élément principal."}];
  sk.push(c.aff[m2]>=35?{id:"sort2",n:"Sort de "+EL[m2].toLowerCase(),cost:2,stat:"mag",power:1.5,el:m2,t:"enemy",d:"Ton élément secondaire."}
    :{id:"sort2",n:"Étincelle",cost:2,stat:"mag",power:1.4,el:"phys",t:"enemy",d:"Magie brute, sans élément."});
  sk.push({id:"nova",n:"Nova",cost:4,stat:"mag",power:1.1,el:m,t:"all",d:"Touche tous les ennemis."});
  sk.push({id:"eveil",n:"Éveil",cost:6,stat:"mag",power:3.2,el:m,t:"enemy",d:"Coup décisif."});
  return{id:"hero",name:b.name,el:m,maxHp:hp,hp,atk:Math.round(st.FOR*1.7),mag:Math.round(st.INT*1.7),def:clamp(Math.round(st.VIT/2),0,15),
    agi:st.AGI,crit:st.CHN*.01+(c.cheat.id==="critique"?.15:0),esp:st.ESP,shield:0,cheat:c.cheat.id,affMult:mult,
    look:heroLook(b,c),skills:sk};
}
const KAEL={id:"kael",name:"Kael",el:"phys",maxHp:130,hp:130,atk:24,mag:10,def:8,agi:12,crit:.08,esp:8,shield:0,look:KAEL_LOOK,skills:[
  {id:"frappe",n:"Taille",cost:0,stat:"atk",power:1.0,el:"phys",t:"enemy",d:"Gratuit. +1 énergie."},
  {id:"entaille",n:"Entaille",cost:2,stat:"atk",power:1.8,el:"phys",t:"enemy",d:"Gros coup."},
  {id:"brise",n:"Brise-garde",cost:2,stat:"atk",power:1.2,el:"phys",t:"enemy",brk:30,d:"Fait craquer la garde."},
  {id:"tourbillon",n:"Tourbillon",cost:3,stat:"atk",power:1.0,el:"phys",t:"all",d:"Touche tous les ennemis."}]};
const LYSA={id:"lysa",name:"Lysa",el:"lumiere",maxHp:95,hp:95,atk:12,mag:24,def:3,agi:14,crit:.06,esp:14,shield:0,look:LYSA_LOOK,skills:[
  {id:"trait",n:"Trait de lumière",cost:0,stat:"mag",power:.9,el:"lumiere",t:"enemy",d:"Gratuit. +1 énergie."},
  {id:"soin",n:"Soin",cost:2,heal:2.0,t:"ally",d:"Soigne un allié."},
  {id:"aegis",n:"Égide",cost:2,shield:28,t:"allies",d:"Bouclier de 28 pour tous."},
  {id:"jugement",n:"Jugement",cost:4,stat:"mag",power:1.5,el:"lumiere",t:"all",d:"Lumière sur tous."}]};
const BEST={
 bandit:{name:"Bandit",el:"phys",weak:"feu",resist:null,hp:85,atk:17,hits:1,speed:1000,inflict:{fx:"poison",chance:.35},immune:[]},
 archer:{name:"Archer bandit",el:"phys",weak:"foudre",resist:null,hp:70,atk:16,hits:1,speed:900,inflict:{fx:"brulure",chance:.35},immune:["brulure"]},
 sorcier:{name:"Sorcier bandit",el:"ombre",weak:"lumiere",resist:"ombre",hp:75,atk:14,hits:2,speed:950,inflict:{fx:"malediction",chance:.4},immune:["malediction"]},
 chef:{name:"Chef des bandits",el:"phys",weak:"glace",resist:null,hp:340,atk:25,hits:3,speed:800,boss:true,inflict:{fx:"paralysie",chance:.3},immune:[]}};
function mirror(svg){return svg.replace(/(<svg[^>]*>)/,'$1<g transform="translate(100,0) scale(-1,1)">').replace('</svg>','</g></svg>')}
ENEMY_SVG.bandit=mirror(heroSVG({skin:"#d4b08c",hair:"#2a1d17",eyes:"#222",outfit:"#5a4a32",outfitDark:"#2e2418",weapon:"sword"}));
ENEMY_SVG.archer=mirror(heroSVG({skin:"#e2bd98",hair:"#6b4a2f",eyes:"#222",outfit:"#3e5a3a",outfitDark:"#22351f",weapon:"bow"}));
ENEMY_SVG.sorcier=mirror(heroSVG({skin:"#cdb3a0",hair:"#3a2450",eyes:"#c8a0ff",outfit:"#4a2a6a",outfitDark:"#2a1640",weapon:"staff",orb:"#9a6bd6"}));
ENEMY_SVG.chef=mirror(heroSVG({skin:"#c99a78",hair:"#6b2a20",eyes:"#222",beard:1,outfit:"#7a2a24",outfitDark:"#3e1512",weapon:"sword"}));
const WAVES=[["bandit","archer","sorcier"],["chef"]];
const ITEMS=[{id:"potion",n:"Potion",d:"Soigne 60 PV.",qty:3,t:"ally"},{id:"antidote",n:"Antidote",d:"Retire poison et brûlure.",qty:2,t:"ally"},{id:"panacee",n:"Panacée",d:"Retire tous les statuts négatifs.",qty:1,t:"ally"},{id:"ether",n:"Éther",d:"+3 énergie.",qty:2,t:"none"},{id:"plume",n:"Plume de phénix",d:"Relève un allié (50 %).",qty:1,t:"down"}];


/* ================= ÉCRAN DE NAISSANCE ================= */
let BIRTH=store("isekai.birth.v2");
function statBars(st,max){return STATS.map(([k,n])=>"<div class='stat'><span>"+n+"</span><div class='bar hp'><div style='width:"+(st[k]/max*100)+"%;background:var(--gold)'></div></div><b>"+st[k]+"</b></div>").join("")}
function sheetCards(b){
  const c=computeChar(b),cr=CHEAT_R[c.cheat.r];
  const eo=sortedEl(c.aff);
  const traits=b.traits.map(n=>byName(TRAITS,n));
  const cards=[];
  cards.push("<small>Identité</small><div class='row'><span>Nom</span><span>"+b.name+"</span></div>"+
    "<div class='row'><span>Race</span><span>"+c.race.n+"</span></div><p class='desc'>"+c.race.d+"</p>");
  cards.push("<small>Naissance</small><div class='row'><span>Lieu</span><span>"+c.place.n+"</span></div><p class='desc'>"+c.place.d+"</p>"+
    "<div class='row'><span>Famille</span><span>"+c.fam.n+"</span></div><p class='desc'>"+c.fam.d+"</p>"+
    "<div class='row'><span>Fratrie</span><span>"+SIB[b.sib]+"</span></div>"+
    "<div class='row'><span>Argent de départ</span><span>"+c.gold+" or</span></div>");
  cards.push("<small>Divinité de la réincarnation</small><div class='row'><span>"+c.god.n+"</span></div><p class='desc'>"+c.god.d+"</p>");
  cards.push("<small>Caractéristiques</small>"+statBars(c.st,30));
  cards.push("<small>Affinités de magie</small>"+eo.map(e=>"<div class='stat'><span style='color:var(--"+e+")'>"+EL[e]+"</span><div class='bar hp'><div style='width:"+c.aff[e]+"%;background:var(--"+e+")'></div></div><b>"+c.aff[e]+"</b></div>").join("")+
    "<p class='desc'>Tu ne choisis pas ta magie : elle s'est tirée à ta naissance.</p>");
  cards.push("<small>Don d'isekai</small><div class='row'><span class='rar-"+(c.cheat.r==="rare"?"rare":c.cheat.r==="commun"?"commun":c.cheat.r==="epique"?"epique":"legendaire")+"'>"+c.cheat.n+"</span><span>"+cr.n+"</span></div><p class='desc'>"+c.cheat.d+"</p>");
  cards.push("<small>Traits de caractère</small>"+traits.map(t=>"<div class='row'><span>"+t.n+"</span><span class='"+(Object.values(t.delta).reduce((s,x)=>s+x,0)>=0?"pos":"neg")+"'>"+t.d+"</span></div>").join("")+
    (b.cursed?"<div class='row'><span class='rar-maudit'>???</span><span class='rar-maudit'>Quelque chose dort en toi...</span></div>":""));
  cards.push("<small>Rang de naissance</small><div class='grade'>"+c.grade+"</div><p class='desc' style='text-align:center'>Total des caractéristiques : "+c.total+"</p>");
  return cards;
}
function showBirth(b,animate){
  const c=computeChar(b);
  const sp=$("#birthSprite");sp.style.display="flex";sp.innerHTML=heroSVG(heroLook(b,c));
  $("#nameBox").style.display="none";
  const box=$("#sheet");box.innerHTML="";
  sheetCards(b).forEach((html,i)=>{const d=document.createElement("div");d.className="bcard";d.innerHTML=html;box.appendChild(d);
    setTimeout(()=>{d.classList.add("show");if(animate){sfx.tick();d.scrollIntoView({block:"nearest",behavior:"smooth"})}},animate?400+i*800:20)});
  const wait=animate?400+8*800:0;
  setTimeout(()=>{$("#btnStart").style.display="";$("#btnNew").style.display=""},wait);
  $("#btnRoll").style.display="none";
  $("#birthSub").textContent=animate?"Tu naîs bébé, "+b.name+". Pour cette démo, on saute directement à tes 18 ans.":"Tu es né dans ce monde, "+b.name+". Démo : tu as 18 ans.";
}
$("#btnRoll").onclick=()=>{BIRTH=rollBirth($("#nameIn").value);store("isekai.birth.v2",BIRTH);sfx.heal();showBirth(BIRTH,true)};
$("#btnNew").onclick=()=>{store("isekai.birth.v2",null);BIRTH=null;$("#sheet").innerHTML="";$("#birthSprite").style.display="none";$("#nameBox").style.display="";
  $("#btnRoll").style.display="";$("#btnStart").style.display="none";$("#btnNew").style.display="none";
  $("#birthSub").textContent="Tu fermes les yeux. Une lumière froide t'enveloppe. Tu ne choisiras ni ta race, ni ta magie, ni ton destin. Seulement ton nom."};
$("#btnStart").onclick=()=>startIntro();
$("#btnAgain").onclick=()=>startBattle();
if(BIRTH&&BIRTH.v===2)showBirth(BIRTH,false);else BIRTH=null;


/* ================= COMBAT : règles ================= */
let S=null;
function show(id){document.querySelectorAll(".screen").forEach(s=>s.classList.toggle("on",s.id===id))}
function easy(){return $("#easy").checked}
async function banner(t,ms=1100){const b=$("#banner");b.textContent=t;b.classList.add("on");await sleep(ms);b.classList.remove("on");await sleep(250)}
function msg(t){$("#msg").textContent=t}
const alive=a=>a.filter(x=>x.hp>0);
const uid=u=>S.party.includes(u)?"#ua"+S.party.indexOf(u):"#ue"+S.enemies.indexOf(u);

/* ---- statuts (durée fixe en tours, comme FFX) ---- */
const FX={
 poison:{n:"Poison",ic:"☠️",neg:1,turns:3,dot:.06},
 brulure:{n:"Brûlure",ic:"🔥",neg:1,turns:3,dot:.08},
 gel:{n:"Gel",ic:"❄️",neg:1,turns:1,ctrl:1},
 paralysie:{n:"Paralysie",ic:"⚡",neg:1,turns:2,ctrl:1},
 sommeil:{n:"Sommeil",ic:"💤",neg:1,turns:2,ctrl:1},
 malediction:{n:"Malédiction",ic:"🌑",neg:1,turns:3},
 regen:{n:"Régénération",ic:"🌿",turns:3,heal:.08},
 force:{n:"Bénédiction",ic:"✨",turns:3},
 carapace:{n:"Carapace",ic:"🛡️",turns:3}};
const EL_FX={feu:["brulure",.3],glace:["gel",.25],foudre:["paralysie",.3],ombre:[["poison","sommeil","malediction"],.3],lumiere:["regen",.3]};
const has=(u,id)=>(u.fx||[]).some(f=>f.id===id);
function fxIcons(u){return (u.fx||[]).map(f=>"<span class='"+(FX[f.id].neg?"neg":"pos")+"' title='"+FX[f.id].n+"'>"+FX[f.id].ic+f.t+"</span>").join("")}
function removeFx(u,id){u.fx=(u.fx||[]).filter(f=>f.id!==id)}
function cleanse(u,ids){const n=(u.fx||[]).length;u.fx=(u.fx||[]).filter(f=>!(FX[f.id].neg&&(!ids||ids.includes(f.id))));return n-u.fx.length}
function addFx(u,id,turns){
  u.fx=u.fx||[];const d=FX[id];
  if((u.immune||[]).includes(id))return "immune";
  if(d.ctrl&&(u.grace||0)>0)return "protege";
  const t=turns||d.turns,f=u.fx.find(x=>x.id===id);
  if(f)f.t=Math.max(f.t,t);else u.fx.push({id,t});
  return true}
function skipTurn(u){
  if(has(u,"gel"))return "gelé";if(has(u,"sommeil"))return "endormi";
  if(has(u,"paralysie")&&Math.random()<.5)return "paralysé";return null}
async function tickPhase(units){
  for(const u of units){
    if(u.hp<=0)continue;let did=false;
    for(const f of (u.fx||[])){const d=FX[f.id];
      if(d.dot){const x=Math.max(2,Math.round(u.maxHp*d.dot));u.hp=Math.max(0,u.hp-x);floatText(uid(u),d.ic+" -"+x,"var(--ombre)");did=true;msg(u.name+" subit "+d.n.toLowerCase()+".")}
      if(d.heal&&u.hp>0){const x=Math.round(u.maxHp*d.heal);u.hp=Math.min(u.maxHp,u.hp+x);floatText(uid(u),d.ic+" +"+x,"var(--ok)");did=true}}
    if(did){renderAll();await sleep(650)}
    if(u.hp<=0)msg(u.name+" succombe.")}}
function tickEnd(units){
  units.forEach(u=>{if((u.grace||0)>0)u.grace--;
    u.fx=(u.fx||[]).map(f=>({...f,t:f.t-1})).filter(f=>{if(f.t>0)return true;if(FX[f.id].ctrl)u.grace=1;return false})});
  renderAll()}
function procOnHit(actor,skill,e){
  const m=EL_FX[skill.el];if(!m)return"";
  let ch=m[1]+(skill.cost>=3?.1:0);if(e.resist===skill.el)ch*=.5;
  if(Math.random()>=ch)return"";
  if(skill.el==="lumiere"){const t=pick(alive(S.party));const id=pick(["regen","force"]);
    if(addFx(t,id)===true){floatText("#ua"+S.party.indexOf(t),FX[id].ic+" "+FX[id].n,"var(--lumiere)");return" "+t.name+" : "+FX[id].n+" !"}return""}
  const id=Array.isArray(m[0])?pick(m[0]):m[0],d=FX[id];
  if(d.ctrl&&e.boss&&Math.random()>1/3)return"";
  const r=addFx(e,id);
  if(r===true){floatText("#ue"+S.enemies.indexOf(e),d.ic+" "+d.n,"var(--ombre)");return" "+d.n+" !"}
  return r==="immune"?" Immunisé.":" Protégé."}


/* ---- menu de commandes (style Pokémon / Final Fantasy) ---- */
function chooseAction(actor){
  return new Promise(res=>{
    const cmd=$("#cmd");
    function clearTargets(){document.querySelectorAll(".targetable").forEach(e=>{e.classList.remove("targetable");e.onclick=null})}
    function done(a){clearTargets();cmd.innerHTML="";res(a)}
    function btn(label,sub,cost,fn,dis,cls){const b=document.createElement("button");if(cls)b.className=cls;
      b.innerHTML="<b>"+label+(cost!==undefined?"<span class='c'>"+cost+"</span>":"")+"</b>"+(sub?"<span>"+sub+"</span>":"");b.disabled=!!dis;b.onclick=fn;cmd.appendChild(b);return b}
    function head(t){const h=document.createElement("div");h.className="head";h.textContent=t;cmd.appendChild(h)}
    function mainMenu(){
      clearTargets();cmd.innerHTML="";cmd.className="menu-main";
      msg("Que doit faire "+actor.name+" ?");
      btn("Attaque","",undefined,()=>useSkill(actor.skills[0]));
      btn("Compétences","",undefined,skillMenu);
      btn("Objets","",undefined,itemMenu);
      btn("Défense","Bouclier 20, +1 énergie",undefined,()=>done({kind:"guard"}));
    }
    function skillMenu(){
      clearTargets();cmd.innerHTML="";cmd.className="";head("Compétences");
      actor.skills.slice(1).forEach(s=>btn(s.n,s.d,s.cost+" ⚡",()=>useSkill(s),s.cost>S.pm,"sm"));
      btn("← Retour","",undefined,mainMenu,false,"back");
      msg("Choisis une compétence. Énergie : "+S.pm+".");
    }
    function itemMenu(){
      clearTargets();cmd.innerHTML="";cmd.className="";head("Objets");
      S.items.forEach(it=>btn(it.n+" ×"+it.qty,it.d,undefined,()=>useItem(it),it.qty<=0,"sm"));
      btn("← Retour","",undefined,mainMenu,false,"back");msg("Choisis un objet.");
    }
    function useSkill(s){
      if(s.cost>S.pm)return;
      if(s.t==="all"||s.t==="self"||s.t==="allies")return done({kind:"skill",skill:s});
      if(s.t==="enemy")return target(alive(S.enemies).map(e=>[e,"#ue"+S.enemies.indexOf(e)]),"Choisis un ennemi.",t=>done({kind:"skill",skill:s,target:t}));
      target(alive(S.party).map(a=>[a,"#ua"+S.party.indexOf(a),"#sr"+S.party.indexOf(a)]),"Choisis un allié.",t=>done({kind:"skill",skill:s,target:t}));
    }
    function useItem(it){
      if(it.t==="none")return done({kind:"item",item:it});
      const list=it.t==="down"?S.party.filter(a=>a.hp<=0):alive(S.party);
      if(!list.length){msg("Personne n'a besoin de cet objet.");return}
      target(list.map(a=>[a,"#ua"+S.party.indexOf(a),"#sr"+S.party.indexOf(a)]),"Choisis un allié.",t=>done({kind:"item",item:it,target:t}));
    }
    function target(list,text,cb){
      clearTargets();msg(text);
      cmd.innerHTML="";head("Cible");btn("← Annuler","",undefined,mainMenu,false,"back");
      list.forEach(([u,...sels])=>sels.forEach(s=>{const el=$(s);el.classList.add("targetable");el.onclick=()=>cb(u)}));
    }
    mainMenu();
  });
}



/* ================= SCÈNE 3D : distribution et repères ================= */
const PI=Math.PI,PANEL_H=262;
const ALLY_MARK=[[-2.3,2.7],[0,3.2],[2.3,2.7]];
const ENEMY_MARK={1:[[0,-3.4]],2:[[-1.5,-3.2],[1.5,-3.2]],3:[[-2.5,-3.0],[0,-3.6],[2.5,-3.0]]};
const SPEC={
 kael:{model:"Sakurada_Fumiriya",weapon:"sword"},
 lysa:{model:"Victoria_Rubin",weapon:"staff",orbCol:0xfff2b0},
 bandit:{model:"Vita",weapon:"sword",tint:0xa59a94},
 archer:{model:"Vivi",tint:0x9aa694},
 sorcier:{model:"Darkness_Shibu",weapon:"staff",orbCol:0x9a6bd6},
 chef:{model:"HairSample_Male",weapon:"greatsword",tint:0xd09080,scale:1.2,idle:"2H_Melee_Idle"}};
function heroSpec(b){const c=computeChar(b),el=sortedEl(c.aff)[0],lk=c.race.look;
  return{model:"Sendagaya_Shibu",orb:ELCOL[el],extras:{ears:lk.ears,horns:lk.horns,tail:lk.tail,wings:lk.wings,hair:b.hair,skin:lk.skin}}}
function spawnParty(){[heroSpec(BIRTH),SPEC.kael,SPEC.lysa].forEach((sp,i)=>Stage.spawn("a"+i,{...sp,x:ALLY_MARK[i][0],z:ALLY_MARK[i][1],face:PI}))}
function spawnWave(w){Stage.removeWhere(id=>id[0]==="e");const ks=WAVES[w],mk=ENEMY_MARK[ks.length];ks.forEach((k,i)=>Stage.spawn("e"+i,{...SPEC[k],x:mk[i][0],z:mk[i][1],face:0}))}
const RANGED={archer:0xff8a3a,sorcier:0x9a6bd6};
function meleeAnim(key,all){
  if(all)return"2H_Melee_Attack_Spin";
  if(key==="chef")return pick(["2H_Melee_Attack_Chop","2H_Melee_Attack_Slice","2H_Melee_Attack_Spin"]);
  return pick(["1H_Melee_Attack_Chop","1H_Melee_Attack_Slice_Diagonal","1H_Melee_Attack_Stab"])}

/* ================= OPTIONS, TITRE ================= */
const QS=new URLSearchParams(location.search),FORCED_Q=QS.has("q")?+QS.get("q"):null;
let stageOK=false;
const sfx=Sound.sfx;
function initStage(){
  try{Stage.init($("#gl"),$("#app"),{quality:FORCED_Q});stageOK=true}catch(e){stageOK=false}
  const bt=$("#btnTitle");
  if(!stageOK){$("#loadTxt").textContent="La 3D n'est pas disponible sur cet appareil.";return}
  Stage.setOnFrame(syncUnits);
  Stage.onFlash(()=>{const f=$("#flash");f.classList.remove("on");void f.offsetWidth;f.classList.add("on")});
  Stage.load(p=>{$("#loadTxt").textContent="Chargement du monde… "+Math.round(p*100)+" %"})
    .then(()=>{$("#loadTxt").textContent="";bt.disabled=false;bt.textContent=BIRTH?"Continuer":"Commencer"})
    .catch(()=>{$("#loadTxt").textContent="Les modèles 3D n'ont pas pu être chargés."})}
$("#logo").innerHTML=[..."MAGICALAND"].map((c,i)=>"<span style='animation-delay:"+(.3+.15*i)+"s'>"+c+"</span>").join("");
$("#btnTitle").onclick=()=>{Sound.unlock();Sound.music("title");Sound.fire(true);sfx.tick();show("birth")};
const QN=["Basse","Moyenne","Haute"];
let muted=store("magicaland.muted")===true;Sound.mute(muted);
function drawOpts(){$("#btnSnd").textContent=muted?"🔇 Son coupé":"🔊 Son";$("#btnQ").textContent="Qualité : "+(stageOK?QN[Stage.quality()]:"-")}
$("#btnSnd").onclick=()=>{muted=!muted;Sound.mute(muted);store("magicaland.muted",muted);drawOpts()};
$("#btnQ").onclick=()=>{if(!stageOK)return;Stage.setQuality((Stage.quality()+2)%3,true);drawOpts()};
setInterval(drawOpts,1500);

/* ================= CINÉMATIQUE D'INTRO ================= */
function introLines(b){
  const c=computeChar(b),tr=b.traits.join(", ").toLowerCase();
  return[
   "Magicaland. Dix-huit ans après ta réincarnation.",
   "Tu es venu au monde en tant que "+c.race.n+". Lieu : "+c.place.n+". Famille : "+c.fam.n.toLowerCase()+".",
   (c.god.id==="aucun"?"Aucun dieu ne t'a parlé, mais un don dormait en toi : ":c.god.n+" t'a murmuré un don : ")+c.cheat.n+".",
   "On disait de toi : "+tr+".",
   "Deux compagnons ont grandi à tes côtés : Kael et Lysa.",
   "Cette nuit, les bandits et leur chef attaquent le village."]}
function caption(t){const el=$("#cineText");el.classList.remove("in");void el.offsetWidth;el.textContent=t;if(t)el.classList.add("in")}
async function startIntro(){
  Sound.unlock();
  if(!stageOK||!Stage.isReady()){startBattle();return}
  const V=(x,y,z)=>new Stage.V3(x,y,z),cam=Stage.cam,L=introLines(BIRTH);
  show("cine");Stage.setInset(0);Stage.setSat(1.08);Stage.setRed(0);Sound.music("cine");Sound.fire(true);
  $("#btnSkip").onclick=()=>{Stage.setRush(true)};
  Stage.removeWhere(()=>true);spawnParty();spawnWave(0);
  Stage.spawn("chefc",{...SPEC.chef,x:0,z:-11.5,face:0});
  // placement de départ
  Stage.place("a0",0,27,PI);Stage.place("a1",-11,8.5,PI);Stage.place("a2",11,9.5,PI);
  const mk=ENEMY_MARK[3];[[15,-10],[18,-8],[21,-11]].forEach((p,i)=>Stage.place("e"+i,p[0],p[1],0));
  // plan 1 : le village brûle, vu du ciel
  caption(L[0]);Sound.stinger();cam.snap(V(2,30,42),V(0,2,-6));cam.zoom(50);
  [0,1,2].forEach(i=>Stage.wait(900+i*500).then(()=>Stage.moveTo("e"+i,mk[i][0],mk[i][1],4.6-i*.3,{face:0})));
  await cam.move(V(-10,12,23),V(0,2,-6),6.2);
  // plan 2 : les bandits, au ras du sol
  caption(L[1]);Sound.stinger();sfx.shout(true);cam.snap(V(7.8,1.0,1.4),V(0,1.5,-3.4));cam.zoom(46);
  [0,1,2].forEach(i=>Stage.wait(600+i*350).then(()=>{Stage.playOnce("e"+i,"Cheer");if(i===1)sfx.shout(true)}));
  await cam.move(V(5.4,1.4,.6),V(.2,1.6,-3.3),4.8);
  // plan 3 : tu cours vers le village
  caption(L[2]);cam.zoom(52);
  const run=Stage.moveTo("a0",ALLY_MARK[0][0],ALLY_MARK[0][1],5.6,{face:PI});
  Stage.wait(2800).then(()=>caption(L[3]));
  await Stage.tween(5.6,t=>{const p=Stage.posOf("a0",0);cam.snap(V(p.x+1.5-t*.6,1.05+t*.5,p.z-4.4+t*1.1),V(p.x,1.3,p.z))},Stage.ease.lin);
  await run;
  // plan 4 : Kael et Lysa te rejoignent
  caption(L[4]);Sound.stinger();cam.snap(V(-7.2,1.5,5.4),V(0,1.3,3.0));cam.zoom(48);
  Stage.moveTo("a1",ALLY_MARK[1][0],ALLY_MARK[1][1],2.3,{face:PI}).then(()=>Stage.playOnce("a1","Block"));
  Stage.moveTo("a2",ALLY_MARK[2][0],ALLY_MARK[2][1],2.6,{face:PI}).then(()=>{Stage.playOnce("a2","Spellcast_Raise");Stage.fx.aura("a2",0xfff2b0)});
  await cam.move(V(-5.0,1.8,7.6),V(.3,1.3,2.7),4.6);
  // plan 5 : le chef des bandits
  caption(L[5]);Sound.stinger();sfx.rumble();cam.snap(V(2.4,.5,-4.2),V(0,2.2,-11.5));cam.zoom(46);
  Stage.wait(1300).then(()=>{Stage.playOnce("chefc","Cheer");sfx.shout(true);Stage.fx.ring(Stage.posOf("chefc",0),0xff6a2a,.5,5,.9);cam.shake(.25)});
  await cam.move(V(1.2,1.3,-3.0),V(0,2.0,-11.5),4.8);
  // plan 6 : face à face
  caption("");Stage.remove("chefc");cam.snap(V(-9,2.2,0),V(0,1.3,0));
  Stage.setRush(false);
  startBattle({keep:true});
}

/* ================= COMBAT : mise en scène ================= */
function startBattle(o){
  o=o||{};
  const hero=buildHero(BIRTH);
  S={party:[hero,structuredClone(KAEL),structuredClone(LYSA)],pm:2+Math.min(3,Math.floor(hero.esp/6)),wave:0,enemies:[],over:false,round:0,
     items:structuredClone(ITEMS),revived:false,active:null,guard:{}};
  if(hero.cheat==="memoire")S.pm+=2;
  if(hero.cheat==="barriere")hero.shield=30;
  S.pm=Math.min(9,S.pm);
  show("battle");Sound.unlock();Sound.fire(true);
  if(stageOK){Stage.setRush(false);Stage.setInset(PANEL_H);Stage.setSat(1.08);Stage.setRed(0);
    if(!o.keep){Stage.removeWhere(()=>true);spawnParty();Stage.cam.snap(new Stage.V3(-9,2.4,2),new Stage.V3(0,1.3,0))}
    Stage.cam.wide(1.5)}
  $("#danger").classList.remove("on");
  buildScene();loadWave(o.keep);Sound.music("battle");renderAll();
  banner("Le village est attaqué !",1400).then(loop);
}
function buildScene(){
  const sc=$("#scene");sc.querySelectorAll(".unit").forEach(e=>e.remove());
  S.party.forEach((a,i)=>{
    const d=document.createElement("div");d.className="unit ally";d.id="ua"+i;
    d.innerHTML="<div class='arrow'>▼</div><div class='plate'><div class='fx'></div></div>";sc.appendChild(d)});
}
function loadWave(keep){
  const sc=$("#scene");sc.querySelectorAll(".unit.enemy").forEach(e=>e.remove());
  S.enemies=WAVES[S.wave].map(k=>({...BEST[k],key:k,maxHp:BEST[k].hp,hp:BEST[k].hp,brk:0,broken:false}));
  if(stageOK&&!keep)spawnWave(S.wave);
  S.enemies.forEach((e,i)=>{
    const d=document.createElement("div");d.className="unit enemy"+(e.boss?" boss":"");d.id="ue"+i;
    d.innerHTML="<div class='plate'><div>"+e.name+"</div><div class='bar hp'><div></div></div><div class='bar brk'><div></div></div><div class='fx'></div></div>";sc.appendChild(d)});
  $("#wave").textContent="Vague "+(S.wave+1)+" / "+WAVES.length;
  renderAll();
}
function syncUnits(){
  if(!S||!$("#battle").classList.contains("on"))return;
  const f=(el,id)=>{if(!el)return;const p=Stage.project(id);if(!p){el.style.visibility="hidden";return}
    el.style.visibility="";const w=Math.max(48,p.h*.55);el.style.left=(p.x-w/2)+"px";el.style.top=p.y+"px";el.style.width=w+"px";el.style.height=p.h+"px"};
  S.party.forEach((a,i)=>f(document.getElementById("ua"+i),"a"+i));S.enemies.forEach((e,i)=>f(document.getElementById("ue"+i),"e"+i));
}
function renderAll(){renderPm();renderUnits();renderStatus();updateDanger()}
function renderPm(){const p=$("#pm");p.innerHTML="Énergie ";for(let i=0;i<9;i++)p.innerHTML+="<i class='"+(i<S.pm?"on":"")+"'></i>"}
function renderUnits(){
  S.enemies.forEach((e,i)=>{const d=$("#ue"+i);if(!d)return;
    d.classList.toggle("dead",e.hp<=0);d.classList.toggle("broken",e.broken);
    const bars=d.querySelectorAll(".plate .bar>div");bars[0].style.width=(100*e.hp/e.maxHp)+"%";bars[1].style.width=Math.min(100,e.brk)+"%";d.querySelector(".fx").innerHTML=fxIcons(e);
    if(stageOK){Stage.setGray("e"+i,e.broken);if(e.hp<=0&&!e.gone){e.gone=true;Stage.die("e"+i,true)}}});
  S.party.forEach((a,i)=>{const d=$("#ua"+i);if(!d)return;d.classList.toggle("down",a.hp<=0);d.classList.toggle("active",S.active===a);d.querySelector(".fx").innerHTML=fxIcons(a);
    if(stageOK){if(a.hp<=0&&!a.gone){a.gone=true;Stage.die("a"+i,false);Sound.accent()}else if(a.hp>0&&a.gone){a.gone=false;Stage.revive("a"+i)}}});
}
function renderStatus(){
  const box=$("#status");box.innerHTML="";
  S.party.forEach((a,i)=>{
    const d=document.createElement("div");d.className="srow"+(a.hp<=0?" down":"")+(S.active===a?" active":"");d.id="sr"+i;
    d.innerHTML="<div class='l1'><span><i style='background:var(--"+a.el+")'></i>"+a.name+"</span><span class='sh'>"+(a.shield?"<span>🛡"+a.shield+"</span>":"")+fxIcons(a)+"</span></div>"+
      "<div class='bar hp'><div style='width:"+(100*Math.max(0,a.hp)/a.maxHp)+"%'></div></div><div class='nums'><span>PV</span><span>"+Math.max(0,a.hp)+" / "+a.maxHp+"</span></div>";
    box.appendChild(d)});
}
function updateDanger(){
  const low=!S.over&&S.party.some(a=>a.hp>0&&a.hp/a.maxHp<.3);
  $("#danger").classList.toggle("on",low);Sound.setDanger(low);if(stageOK)Stage.setRed(low?.55:0)}
function floatText(unitId,text,color){
  const el=$(unitId);if(!el)return;const f=document.createElement("div");f.className="float";f.textContent=text;f.style.color=color||"#fff";
  el.appendChild(f);setTimeout(()=>f.remove(),1000)}

async function loop(){
  const hero=S.party[0];
  while(!S.over){
    S.round++;
    if(S.round>1){S.pm=Math.min(9,S.pm+1+(hero.cheat==="flux"?1:0)+(hero.esp>=19?1:0));
      if(hero.cheat==="regen"&&hero.hp>0){const h=Math.round(hero.maxHp*.05);hero.hp=Math.min(hero.maxHp,hero.hp+h);floatText("#ua0","+"+h,"var(--ok)")}}
    renderAll();
    await banner("Ton tour",700);
    await tickPhase(S.party);if(!alive(S.party).length)return end(false);
    for(let i=0;i<S.party.length;i++){
      const a=S.party[i];
      if(a.hp<=0)continue;
      if(!alive(S.enemies).length)break;
      const sk=skipTurn(a);
      if(sk){S.active=a;renderAll();msg(a.name+" est "+sk+" et passe son tour.");await sleep(1000);continue}
      S.active=a;S.guard[a.id]=0;renderAll();
      const act=await chooseAction(a);
      await perform(a,act);
      if(!alive(S.enemies).length)break;
    }
    S.active=null;tickEnd(S.party);
    let v=await checkVictory();if(v==="win")return;if(v==="next")continue;
    await banner("Tour ennemi",800);
    await enemyPhase();
    if(!alive(S.party).length)return end(false);
    v=await checkVictory();if(v==="win")return;if(v==="next")continue;
  }
}
async function checkVictory(){
  if(alive(S.enemies).length)return null;
  if(S.wave<WAVES.length-1){
    S.wave++;await banner("Vague terminée",1000);
    S.party.forEach(a=>{if(a.hp>0)a.hp=Math.min(a.maxHp,a.hp+Math.round(a.maxHp*.3));a.shield=0;a.fx=[];a.grace=0});
    S.pm=Math.min(9,S.pm+2);loadWave();S.round=0;
    if(stageOK){ // entrée du chef
      const cam=Stage.cam,V=(x,y,z)=>new Stage.V3(x,y,z),m=ENEMY_MARK[1][0];
      Stage.place("e0",0,-14,0);Sound.music("boss");sfx.rumble();
      cam.snap(V(1.4,.5,-8.2),V(0,2.4,-13));cam.zoom(46);
      const w=Stage.moveTo("e0",m[0],m[1],3.4,{anim:"Walking_A",speed:1.15,face:0});
      cam.move(V(-2.4,1.4,2.6),V(0,2.0,-3.6),3.4);
      await banner("Le chef des bandits",2200);await w;
      Stage.playOnce("e0","Cheer");sfx.shout(true);Stage.fx.ring(Stage.posOf("e0",0),0xff6a2a,.5,5,.8);cam.shake(.3);await sleep(900);
      cam.wide(2);
    }else await banner("Le chef des bandits approche...",1400);
    return "next"}
  end(true);return "win"}
function end(win){
  S.over=true;updateDanger();
  if(stageOK){
    if(win){S.party.forEach((a,i)=>{if(a.hp>0)Stage.loopAnim("a"+i,"Victory")});Stage.cam.zoom(50);Stage.cam.setOrbit(new Stage.V3(0,1.2,2.9),8.5,3.1,.2)}
    else{Stage.setSat(.1);Stage.cam.zoom(50);Stage.cam.setOrbit(new Stage.V3(0,1,1),9,3.2,.08)}}
  Sound.music(win?"victory":"defeat");
  setTimeout(()=>{if(stageOK)Stage.setInset(0);show("end");
    $("#endT").textContent=win?"VICTOIRE":"DÉFAITE";
    $("#endP").textContent=win?"Les bandits fuient. Le village est sauvé. Ce n'est que le début de ton histoire.":"Tu t'effondres. Dans ce monde, la mort est aussi une histoire.";
  },1500);
}

/* ---- exécution d'une action alliée ---- */
const enemyIndex=e=>S.enemies.indexOf(e);
function critRoll(a){return Math.random()<(a.crit||0)}
function addBreak(e,n){e.brk+=n;if(e.brk>=100&&!e.broken&&e.hp>0){e.broken=true;e.brk=100;sfx.brk();Sound.accent();return true}return false}
async function perform(actor,act){
  const ai=S.party.indexOf(actor),aid="a"+ai,hero=S.party[0],cam=Stage.cam;
  if(act.kind==="guard"){
    S.pm=Math.min(9,S.pm+1);actor.shield+=20;addFx(actor,"carapace",1);
    Stage.playOnce(aid,"Block");Stage.fx.shield(aid,0x6cc4e8);sfx.shield();renderAll();floatText("#ua"+ai,"🛡20","var(--glace)");msg(actor.name+" se met en garde.");await sleep(800);return}
  if(act.kind==="item"){
    const it=act.item;it.qty--;cam.close(aid,3.5);Stage.playOnce(aid,"Use_Item");await sleep(550);
    const t=act.target,ti=t?S.party.indexOf(t):-1,P=t?Stage.posOf("a"+ti,0):Stage.posOf(aid,0);
    if(it.id==="potion"){t.hp=Math.min(t.maxHp,t.hp+60);Stage.fx.pillar(P,0x6fcf8f);floatText("#ua"+ti,"+60","var(--ok)");msg(actor.name+" utilise une Potion sur "+t.name+".")}
    if(it.id==="ether"){S.pm=Math.min(9,S.pm+3);Stage.fx.pillar(P,0x5aa5d8);msg(actor.name+" boit un Éther (+3 énergie).")}
    if(it.id==="antidote"){const n=cleanse(t,["poison","brulure"]);Stage.fx.pillar(P,0x6fcf8f);floatText("#ua"+ti,n?"Soigné":"Rien","var(--ok)");msg(actor.name+" donne un Antidote à "+t.name+".")}
    if(it.id==="panacee"){const n=cleanse(t);Stage.fx.pillar(P,0xfff2b0);floatText("#ua"+ti,n?"Purifié":"Rien","var(--ok)");msg(actor.name+" donne une Panacée à "+t.name+".")}
    if(it.id==="plume"){t.hp=Math.round(t.maxHp*.5);Stage.fx.pillar(P,0xd9b25f);msg(actor.name+" relève "+t.name+" !");floatText("#ua"+ti,"Relevé","var(--ok)")}
    sfx.heal();renderAll();await sleep(900);cam.wide();return}
  const skill=act.skill,target=act.target;
  S.pm=Math.min(9,S.pm-skill.cost+(skill.cost===0?1:0));renderPm();
  if(skill.heal){
    const t=target,ti=S.party.indexOf(t);cam.close(aid,3.5);sfx.cast("lumiere");Stage.playOnce(aid,"Spellcast_Raise");await sleep(650);
    const amt=Math.round(skill.heal*actor.mag);t.hp=Math.min(t.maxHp,t.hp+amt);const cl=cleanse(t);
    cam.close("a"+ti,4);Stage.fx.pillar(Stage.posOf("a"+ti,0),0x6fcf8f);sfx.heal();msg(actor.name+" soigne "+t.name+" (+"+amt+")."+(cl?" Statuts retirés.":""));renderAll();floatText("#ua"+ti,"+"+amt,"var(--ok)");await sleep(900);cam.wide();return}
  if(skill.shield){
    cam.close(aid,3.5);sfx.cast("lumiere");Stage.playOnce(aid,"Spellcast_Raise");await sleep(600);cam.wide(3);
    const list=skill.t==="self"?[actor]:alive(S.party);
    list.forEach(t=>{const ti=S.party.indexOf(t);t.shield+=skill.shield;Stage.fx.shield("a"+ti,0xfff2b0);floatText("#ua"+ti,"🛡"+skill.shield,"var(--glace)")});
    sfx.shield();msg(actor.name+" lève un bouclier.");renderAll();await sleep(900);return}
  /* attaque */
  const targets=skill.t==="all"?alive(S.enemies):[target],eids=targets.map(e=>"e"+enemyIndex(e));
  const magic=skill.stat==="mag",color=ELCOL[skill.el],home=ALLY_MARK[ai];
  msg(actor.name+" : "+skill.n+" !");
  if(skill.cost>=6){cam.close(aid,5);Stage.fx.charge(aid,color,1);sfx.rumble();Stage.playOnce(aid,"Spellcast_Raise");await sleep(1000)}
  cam.attack(aid,eids[0]);
  if(magic){
    const an=skill.t==="all"?"Spellcast_Long":"Spellcast_Shoot";
    sfx.cast(skill.el);Stage.fx.charge(aid,color,.45);Stage.playOnce(aid,an,{speed:1.15});
    await Stage.wait(Stage.clipDur(an)*(skill.t==="all"?.5:.42)/1.15*1000);
    const from=Stage.posOf(aid,1.35);from.z-=.6;
    await Promise.all(eids.map((id,k)=>Stage.wait(k*70).then(()=>Stage.fx.spellTravel(skill.el,from.clone(),Stage.posOf(id),skill.t==="all"?1.6:.25))));
  }else{
    const T=skill.t==="all"?new Stage.V3(0,0,-1.2):Stage.posOf(eids[0],0),all=skill.t==="all";
    await Stage.moveTo(aid,all?0:T.x*.88+home[0]*.12,all?-1.1:T.z+1.55,.3,{speed:1.7});
    if(!all)Stage.faceTo(aid,T.x,T.z);
    const an=meleeAnim(actor.id,all);sfx.shout(actor.id==="kael");Stage.playOnce(aid,an,{speed:1.3});
    await Stage.wait(Stage.clipDur(an)*.4/1.3*1000);sfx.slash();
  }
  for(const e of targets){
    const ei=enemyIndex(e),eid="e"+ei,id="#ue"+ei;
    let mult=1,txt="",weak=false;
    if(e.weak===skill.el){mult=1.5*(hero.cheat==="oeil"?1.15:1);e.brk+=35;txt=" Point faible !";weak=true}
    else if(e.resist===skill.el){mult=.6;e.brk+=5;txt=" Résisté."}
    else e.brk+=10;
    if(skill.cost>=3)e.brk+=10;
    if(skill.brk)e.brk+=skill.brk;
    if(actor.affMult&&skill.el!=="phys")mult*=actor.affMult(skill.el);
    if(e.broken)mult*=1.5;
    if(skill.el==="feu"&&has(e,"gel")){mult*=1.5;removeFx(e,"gel");txt+=" Fonte !"}
    else if(skill.el==="foudre"&&has(e,"gel")){mult*=1.4;txt+=" Choc !"}
    if(skill.el==="glace"&&has(e,"brulure")){removeFx(e,"brulure");txt+=" Éteint."}
    if(has(actor,"malediction"))mult*=.75;
    if(has(actor,"force"))mult*=1.25;
    let crit=false;if(critRoll(actor)){mult*=1.5;crit=true;txt+=" Critique !"}
    const dmg=Math.max(1,Math.round(actor[skill.stat]*skill.power*mult*rnd(.9,1.1)));
    e.hp=Math.max(0,e.hp-dmg);
    const heavy=crit||weak||skill.cost>=4,P=Stage.posOf(eid);
    if(magic){Stage.fx.spellHit(skill.el,eid,heavy);sfx.boom(skill.el)}else{Stage.fx.slash(P,0xfff2c0);Stage.fx.burst(P,0xffb060,heavy?22:10,5,.4,.4);crit?sfx.crit():sfx.hit()}
    if(crit&&magic)sfx.crit();
    Stage.hit(eid,{heavy,color});cam.shake(heavy?.42:.18);if(crit||weak)Stage.hitStop(95);
    floatText(id,(crit?"★ ":"")+dmg,crit?"var(--gold)":"var(--"+skill.el+")");
    if(has(e,"sommeil")&&dmg>0){removeFx(e,"sommeil");txt+=" Réveillé !"}
    const ps=e.hp>0?procOnHit(actor,skill,e):"";
    if(ps&&ps.indexOf("!")>0&&e.hp>0){sfx.status();Stage.fx.aura(eid,0x9a6bd6)}
    msg(actor.name+" : "+skill.n+", "+dmg+" dégâts."+txt+ps);
    if(e.brk>=100&&!e.broken&&e.hp>0){e.broken=true;e.brk=100;sfx.brk();Sound.accent();Stage.fx.ring(Stage.posOf(eid,0),0xe8b23b,.4,3.8,.6);renderAll();await banner("BRISÉ !",700)}
    renderAll();
    if(e.hp<=0){msg(e.name+" est vaincu.");if(hero.cheat==="absorption"&&hero.hp>0){hero.hp=Math.min(hero.maxHp,hero.hp+Math.round(hero.maxHp*.2));floatText("#ua0","+","var(--ok)")}}
    renderAll();
    if(targets.length>1)await sleep(150);
  }
  await sleep(520);
  if(!magic)await Stage.moveTo(aid,home[0],home[1],.32,{speed:1.6,face:PI});
  cam.wide();await sleep(380);
}

/* ---- phase ennemie : la menace se voit avant de frapper ---- */
async function enemyPhase(){
  await tickPhase(S.enemies);
  if(alive(S.enemies).length&&alive(S.party).length)await enemyPhaseInner();
  tickEnd(S.enemies)}
async function enemyPhaseInner(){
  const hero=S.party[0],cam=Stage.cam;
  for(let i=0;i<S.enemies.length;i++){
    const e=S.enemies[i];if(e.hp<=0)continue;
    const eid="e"+i,emk=ENEMY_MARK[S.enemies.length][i],ranged=RANGED[e.key];
    const sk=skipTurn(e);if(sk){msg(e.name+" est "+sk+" et ne peut pas attaquer.");await sleep(900);continue}
    if(e.broken){msg(e.name+" est brisé et ne peut pas attaquer.");await sleep(900);e.broken=false;e.brk=0;renderAll();continue}
    let moved=false,lastT=-1;
    for(let h=0;h<e.hits;h++){
      const targets=alive(S.party);if(!targets.length)break;
      const t=pick(targets),ti=S.party.indexOf(t),tid="a"+ti,am=ALLY_MARK[ti];
      $("#ua"+ti).classList.add("targeted");
      msg(e.name+" attaque "+t.name+(e.hits>1?" ("+(h+1)+"/"+e.hits+")":"")+" !");
      cam.threat(eid,tid);
      if(!ranged){if(!moved||lastT!==ti){moved=true;await Stage.moveTo(eid,am[0]*.9+emk[0]*.1,am[1]-1.6,moved&&lastT>=0?.3:.5,{speed:1.5});Stage.faceTo(eid,am[0],am[1])}}
      else Stage.faceTo(eid,am[0],am[1]);
      lastT=ti;
      const r=await dodgeGame(e,t,{onStart(dur){
        if(ranged){const an=e.key==="archer"?"2H_Ranged_Shoot":"Spellcast_Shoot",fl=Math.min(420,dur*.5);
          Stage.playOnce(eid,an,{speed:1.2});if(e.key==="sorcier"){sfx.cast("ombre");Stage.fx.charge(eid,ranged,(dur-fl)/1000)}
          setTimeout(()=>{const from=Stage.posOf(eid,1.35);from.z+=.6;if(e.key==="archer")sfx.dodge();Stage.fx.projectile(from,Stage.posOf(tid,1.1),ranged,fl/1000,.15)},Math.max(0,dur-fl))}
        else{const an=meleeAnim(e.key,false),sp=clamp(Stage.clipDur(an)*.42/(dur/1000),.45,2.4);Stage.playOnce(eid,an,{speed:sp});sfx.shout(true);setTimeout(()=>sfx.slash(),Math.max(0,dur-140))}}});
      $("#ua"+ti).classList.remove("targeted");
      let dmg=Math.round(e.atk*rnd(.9,1.1)*(1-t.def/100));
      if(has(e,"malediction"))dmg=Math.round(dmg*.75);
      if(has(t,"carapace"))dmg=Math.round(dmg*.7);
      const mid=Stage.posOf(tid,1.2).lerp(Stage.posOf(eid,1.2),.3);
      if(r==="parry"){
        sfx.parry();sfx.slow();floatText("#ua"+ti,"PARADE","var(--gold)");
        Stage.playOnce(tid,"Block_Hit",{fade:.04});Stage.fx.sparks(mid,0xfff2c0,36);Stage.fx.flare(mid,0xfff2c0);Stage.fx.ring(Stage.posOf(tid,0),0xd9b25f,.3,2.6,.5);Stage.fx.light(mid,0xfff2c0,8,.4);
        $("#flash").classList.remove("on");void $("#flash").offsetWidth;$("#flash").classList.add("on");
        cam.zoom(cam.fov-12);await Stage.slowmo(.12,460);cam.zoom(cam.fov+8);
        const c=Math.round(t.atk*.8);e.hp=Math.max(0,e.hp-c);S.pm=Math.min(9,S.pm+1);
        if(!ranged){Stage.playOnce(tid,meleeAnim(t.id,false),{speed:1.7});await sleep(240);sfx.slash();sfx.hit();Stage.fx.slash(Stage.posOf(eid),0xfff2c0);Stage.hit(eid,{heavy:true});cam.shake(.3)}
        else{await Stage.fx.projectile(mid,Stage.posOf(eid),0xfff2c0,.22,.2);sfx.hit();Stage.fx.impact(Stage.posOf(eid),0xfff2c0,false);Stage.hit(eid,{heavy:false})}
        const b=addBreak(e,20);floatText("#ue"+i,c,"var(--phys)");msg(t.name+" pare et riposte : "+c+" dégâts !");
        if(b)Stage.fx.ring(Stage.posOf(eid,0),0xe8b23b,.4,3.8,.6);
        if(e.hp<=0&&hero.cheat==="absorption"&&hero.hp>0)hero.hp=Math.min(hero.maxHp,hero.hp+Math.round(hero.maxHp*.2));
        renderAll();
      }else{
        if(r==="dodge"){dmg=Math.round(dmg*.35);sfx.dodge();Stage.playOnce(tid,pick(["Dodge_Backward","Dodge_Left"]),{fade:.04,speed:1.3})}
        else{sfx.hurt();Stage.hit(tid,{heavy:true,color:0xff5040});Stage.fx.burst(Stage.posOf(tid),ranged||0xff7050,18,5,.45,.45);cam.shake(.5);Stage.hitStop(80);
          $("#app").classList.add("flash");setTimeout(()=>$("#app").classList.remove("flash"),350)}
        let absorbed=0;if(t.shield){absorbed=Math.min(t.shield,dmg);t.shield-=absorbed;dmg-=absorbed;if(absorbed)Stage.fx.shield(tid,0x6cc4e8)}
        t.hp=Math.max(0,t.hp-dmg);
        floatText("#ua"+ti,dmg>0?"-"+dmg:(absorbed?"🛡":"0"),r==="dodge"?"var(--glace)":"var(--hp)");
        if(t.hp<=0&&t.cheat==="boucle"&&!S.revived){S.revived=true;t.hp=Math.round(t.maxHp*.5);Stage.fx.pillar(Stage.posOf(tid,0),0xd9b25f);floatText("#ua"+ti,"Boucle !","var(--gold)");msg("La boucle temporelle te ramène à la vie !")}
        else if(t.hp<=0)msg(t.name+" s'effondre...");
      }
      if(r!=="parry"&&e.inflict&&t.hp>0){
        const ch=e.inflict.chance*(r==="dodge"?.5:1)*(1-clamp(t.esp*.02,0,.4));
        if(Math.random()<ch){const res=addFx(t,e.inflict.fx),d=FX[e.inflict.fx];
          if(res===true){sfx.status();Stage.fx.aura(tid,0x9a6bd6);floatText("#ua"+ti,d.ic+" "+d.n,"var(--ombre)");msg(t.name+" subit : "+d.n+" !")}
          else if(res==="protege")msg(t.name+" résiste au "+d.n.toLowerCase()+".")}}
      renderAll();await sleep(700);
      if(e.hp<=0)break;
    }
    if(e.hp>0&&moved)await Stage.moveTo(eid,emk[0],emk[1],.4,{speed:1.5,face:0});
    else if(e.hp>0)Stage.actor(eid).root.rotation.y=0;
    cam.wide(3);await sleep(250);
  }
}
function dodgeGame(enemy,target,hooks){
  hooks=hooks||{};
  return new Promise(res=>{
    const box=$("#dodge"),ring=$("#ring"),resEl=$("#dodgeRes");
    const bonus=((target.agi||12)-12);
    const perfect=(easy()?170:90)+bonus*4,good=(easy()?340:210)+bonus*8;
    $("#dodgeInfo").innerHTML="<em>"+enemy.name+"</em> attaque <em>"+target.name+"</em>";
    resEl.textContent="";ring.style.transition="none";ring.style.transform="scale(1)";ring.style.opacity=".9";
    box.classList.add("on");
    const dur=enemy.speed*(easy()?1.25:1),prep=450;
    let start=0,finished=false;
    function finish(r){
      if(finished)return;finished=true;
      document.removeEventListener("keydown",onKey);box.onpointerdown=null;
      resEl.textContent=r==="parry"?"PARADE !":r==="dodge"?"ESQUIVE":"RATÉ";
      resEl.style.color=r==="parry"?"var(--gold)":r==="dodge"?"var(--glace)":"var(--hp)";
      setTimeout(()=>{box.classList.remove("on");res(r)},r==="parry"?120:300);
    }
    function tap(){
      if(!start)return;
      const d=Math.abs(performance.now()-(start+dur));
      finish(d<=perfect?"parry":d<=good?"dodge":"miss");
    }
    const onKey=ev=>{if(ev.code==="Space"||ev.key==="Enter"){ev.preventDefault();tap()}};
    document.addEventListener("keydown",onKey);box.onpointerdown=tap;
    setTimeout(()=>{
      start=performance.now();
      ring.style.transition="transform "+dur+"ms linear";ring.style.transform="scale("+(70/220)+")";
      if(hooks.onStart)hooks.onStart(dur);
      setTimeout(()=>{ring.style.opacity=".35"},dur);
      setTimeout(()=>finish("miss"),dur+good+30);
    },prep);
  });
}
initStage();drawOpts();
