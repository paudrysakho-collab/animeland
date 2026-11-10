"use strict";
/* Magicaland : musique orchestrale sombre et bruitages, entièrement générés (Web Audio). */
const Sound=(()=>{
let AC=null,master,musicBus,sfxBus,reverb,comp,noiseBuf,muted=false,started=false;
let state="off",bpm=60,step=0,nextT=0,timer=null,loopN=0,danger=false,dangerT=0,accentBars=0;
const mtof=m=>440*Math.pow(2,(m-69)/12);
// progression en ré mineur : i | i | VI | VI | III | VII | i | V
const CH=[{b:38,n:[50,53,57]},{b:38,n:[50,53,57]},{b:34,n:[50,53,58]},{b:34,n:[46,53,58]},{b:41,n:[48,53,57]},{b:36,n:[48,52,55]},{b:38,n:[50,53,57]},{b:33,n:[49,52,57]}];
// thème héroïque (mesure, temps, durée en temps, note)
const THEME=[[0,0,2,62],[0,2,1,65],[0,3,1,69],[1,0,3,67],[1,3,1,65],[2,0,2,65],[2,2,1,70],[2,3,1,74],[3,0,4,72],[4,0,2,69],[4,2,1,72],[4,3,1,77],[5,0,3,76],[5,3,1,72],[6,0,2,74],[6,2,2,69],[7,0,2,73],[7,2,2,69]];
const TAIKO={battle:[1,0,0,1,0,0,1,0,1,0,0,1,0,1,0,0],boss:[1,0,1,1,0,1,1,0,1,0,1,1,0,1,1,1],cine:[1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0]};

function ensure(){
  if(AC)return true;
  try{AC=new (window.AudioContext||window.webkitAudioContext)()}catch(e){return false}
  master=AC.createGain();master.gain.value=muted?0:.9;
  comp=AC.createDynamicsCompressor();comp.threshold.value=-14;comp.ratio.value=4;comp.attack.value=.004;comp.release.value=.22;
  master.connect(comp).connect(AC.destination);
  musicBus=AC.createGain();musicBus.gain.value=.5;sfxBus=AC.createGain();sfxBus.gain.value=.85;
  musicBus.connect(master);sfxBus.connect(master);
  // réverbération : impulsion de bruit décroissant
  const len=AC.sampleRate*2.8,ib=AC.createBuffer(2,len,AC.sampleRate);
  for(let c=0;c<2;c++){const d=ib.getChannelData(c);for(let i=0;i<len;i++)d[i]=(Math.random()*2-1)*Math.pow(1-i/len,2.6)}
  reverb=AC.createConvolver();reverb.buffer=ib;const rg=AC.createGain();rg.gain.value=.34;reverb.connect(rg).connect(master);
  noiseBuf=AC.createBuffer(1,AC.sampleRate*2,AC.sampleRate);const nd=noiseBuf.getChannelData(0);for(let i=0;i<nd.length;i++)nd[i]=Math.random()*2-1;
  return true}
function out(bus,wet){const g=AC.createGain();g.connect(bus);if(wet){const w=AC.createGain();w.gain.value=wet;g.connect(w).connect(reverb)}return g}
function env(g,t,a,peak,d,sus,r,hold){g.gain.setValueAtTime(.0001,t);g.gain.linearRampToValueAtTime(peak,t+a);g.gain.linearRampToValueAtTime(peak*sus,t+a+d);g.gain.setValueAtTime(peak*sus,t+a+d+hold);g.gain.linearRampToValueAtTime(.0001,t+a+d+hold+r)}
function osc(type,f,t,dur,dest,det){const o=AC.createOscillator();o.type=type;o.frequency.setValueAtTime(f,t);if(det)o.detune.value=det;o.connect(dest);o.start(t);o.stop(t+dur);return o}
function noise(t,dur,dest){const s=AC.createBufferSource();s.buffer=noiseBuf;s.loop=true;s.connect(dest);s.start(t,Math.random());s.stop(t+dur);return s}

/* ---------- instruments ---------- */
function strings(t,midi,dur,vol){ // nappe de cordes
  const g=out(musicBus,.5),f=AC.createBiquadFilter();f.type="lowpass";f.frequency.value=1100;f.Q.value=.4;f.connect(g);
  env(g,t,.35,vol,.2,.85,.7,Math.max(0,dur-.55));
  for(const d of[-9,0,8])osc("sawtooth",mtof(midi),t,dur+.8,f,d)}
function spicc(t,midi,vol){ // cordes staccato
  const g=out(musicBus,.3),f=AC.createBiquadFilter();f.type="lowpass";f.frequency.setValueAtTime(2600,t);f.frequency.exponentialRampToValueAtTime(500,t+.14);f.connect(g);
  env(g,t,.008,vol,.09,.12,.08,0);osc("sawtooth",mtof(midi),t,.3,f,-6);osc("sawtooth",mtof(midi),t,.3,f,7)}
function bass(t,midi,dur,vol){
  const g=out(musicBus,.12),f=AC.createBiquadFilter();f.type="lowpass";f.frequency.value=260;f.connect(g);
  env(g,t,.02,vol,.1,.8,.2,Math.max(0,dur-.3));osc("sawtooth",mtof(midi),t,dur+.3,f);osc("sine",mtof(midi-12),t,dur+.3,g)}
function horn(t,midi,dur,vol){ // cuivres
  const g=out(musicBus,.55),f=AC.createBiquadFilter();f.type="lowpass";f.Q.value=1.2;
  f.frequency.setValueAtTime(350,t);f.frequency.linearRampToValueAtTime(1900,t+.12);f.frequency.linearRampToValueAtTime(1100,t+dur);f.connect(g);
  env(g,t,.07,vol,.12,.8,.25,Math.max(0,dur-.3));
  const l=AC.createOscillator(),lg=AC.createGain();l.frequency.value=5.2;lg.gain.value=5;l.connect(lg);l.start(t);l.stop(t+dur+.4);
  for(const d of[-7,6]){const o=osc("sawtooth",mtof(midi),t,dur+.4,f,d);lg.connect(o.detune)}
  osc("square",mtof(midi-12),t,dur+.4,f).detune.value=3}
function choir(t,midi,dur,vol){ // chœur synthétique (formants « ah »)
  const g=out(musicBus,.75);env(g,t,.6,vol,.3,.9,1.1,Math.max(0,dur-.7));
  const src=AC.createGain();
  for(const d of[-11,0,10])osc("sawtooth",mtof(midi),t,dur+1.4,src,d);
  for(const[fq,q,gn]of[[760,7,1],[1180,8,.6],[2700,9,.22]]){const b=AC.createBiquadFilter();b.type="bandpass";b.frequency.value=fq;b.Q.value=q;const bg=AC.createGain();bg.gain.value=gn;src.connect(b).connect(bg).connect(g)}}
function taiko(t,vol,low){
  const g=out(musicBus,.42);g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.0001,t+.5);
  const o=AC.createOscillator();o.frequency.setValueAtTime(low?96:140,t);o.frequency.exponentialRampToValueAtTime(low?38:52,t+.22);o.connect(g);o.start(t);o.stop(t+.55);
  const ng=AC.createGain();ng.gain.setValueAtTime(vol*.55,t);ng.gain.exponentialRampToValueAtTime(.0001,t+.09);const f=AC.createBiquadFilter();f.type="lowpass";f.frequency.value=900;noise(t,.12,f);f.connect(ng).connect(g)}
function snare(t,vol){const g=out(musicBus,.3);g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.0001,t+.13);const f=AC.createBiquadFilter();f.type="bandpass";f.frequency.value=1900;f.Q.value=.8;noise(t,.15,f);f.connect(g)}
function cymbal(t,vol,dur){const g=out(musicBus,.5);g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(vol,t+dur*.9);g.gain.exponentialRampToValueAtTime(.0001,t+dur+.9);const f=AC.createBiquadFilter();f.type="highpass";f.frequency.value=5200;noise(t,dur+1,f);f.connect(g)}

/* ---------- séquenceur ---------- */
function schedule(){
  if(!AC||state==="off")return;
  while(nextT<AC.currentTime+.18){playStep(step,nextT);nextT+=60/bpm/4;step++;if(step>=128){step=0;loopN++}}
}
function playStep(s,t){
  const bar=(s>>4)%8,st=s&15,c=CH[bar],sd=60/bpm/4,barDur=sd*16,boss=state==="boss",fight=state==="battle"||boss,hot=boss||accentBars>0;
  if(st===0){
    if(accentBars>0)accentBars--;
    if(state==="title"||state==="cine"){c.n.forEach(n=>strings(t,n,barDur,.05));strings(t,c.b,barDur,.07);if(bar%2===0)choir(t,c.n[2]+12,barDur*2,state==="cine"?.05:.032);
      if(state==="cine"){taiko(t,.5,true);if(bar===3||bar===7)cymbal(t+barDur*.55,.05,barDur*.4)}}
    if(fight){c.n.forEach(n=>strings(t,n,barDur,.034));bass(t,c.b,sd*6,.2);bass(t+sd*8,c.b,sd*5,.17);
      if(hot&&bar%2===0)choir(t,c.n[1]+12,barDur*2,.042);
      if(bar===7)cymbal(t+barDur*.5,.05,barDur*.45)}
    if(state==="victory"){[62,66,69].forEach(n=>strings(t,n,barDur,.05));choir(t,74,barDur,.03)}
    if(state==="defeat"){strings(t,38,barDur,.08);strings(t,45,barDur,.04)}
  }
  if(fight){
    const tk=TAIKO[boss?"boss":"battle"][st];if(tk)taiko(t,st===0?.62:.4,st%8===0);
    if(boss&&(st===4||st===12))snare(t,.2);
    if(hot&&st%2===1&&bar>=6)snare(t,.07);
    // ostinato de cordes : croches, doubles-croches quand la tension monte
    const pat=[c.n[0],c.n[2],c.n[1],c.n[2],c.n[0]+12,c.n[2],c.n[1],c.n[2]];
    if(st%2===0)spicc(t,pat[st/2],.085);else if(hot)spicc(t,pat[(st-1)/2]+12,.042);
    // thème aux cuivres : une boucle sur deux en combat, toujours face au chef
    if(boss||loopN%2===1)for(const[b,bt,d,n]of THEME)if(b===bar&&bt*4===st){horn(t,n,d*sd*4,.085);if(boss)horn(t,n-12,d*sd*4,.05)}
  }
  if(state==="cine"&&st===8&&bar%2===1)taiko(t,.3,false);
  if(danger&&AC.currentTime-dangerT>.1&&st%8===0){heart(t)}
}
function heart(t){for(const[o,v]of[[0,.5],[.16,.34]]){const g=out(sfxBus,0);g.gain.setValueAtTime(v,t+o);g.gain.exponentialRampToValueAtTime(.0001,t+o+.22);const os=AC.createOscillator();os.frequency.setValueAtTime(72,t+o);os.frequency.exponentialRampToValueAtTime(40,t+o+.16);os.connect(g);os.start(t+o);os.stop(t+o+.25)}}
function music(s){
  if(!ensure())return;if(AC.state==="suspended")AC.resume();
  if(s===state)return;state=s;
  bpm=s==="title"?56:s==="cine"?66:s==="battle"?112:s==="boss"?126:s==="victory"?80:54;
  step=0;loopN=s==="boss"?1:0;nextT=AC.currentTime+.08;
  if(!timer)timer=setInterval(schedule,40);
  if(s==="victory"){const t=AC.currentTime+.05;[[0,62],[.18,66],[.36,69],[.54,74]].forEach(([o,n])=>horn(t+o,n,o===.54?1.6:.2,.11));taiko(t,.6,true);taiko(t+.54,.7,true);cymbal(t,.07,.5)}
  if(s==="boss"){const t=AC.currentTime+.02;taiko(t,.8,true);cymbal(t,.06,.2)}
}
function stinger(){ // coup d'orchestre pour les plans de la cinématique
  if(!ensure())return;const t=AC.currentTime+.02;taiko(t,.85,true);[38,50,57,62].forEach(n=>horn(t,n,1.5,.07));cymbal(t,.05,.15)}
function accent(){accentBars=4}
function setDanger(v){if(v&&!danger)dangerT=AC?AC.currentTime:0;danger=v}

/* ---------- bruitages ---------- */
function S(fn){return function(a,b){if(!ensure())return;if(AC.state==="suspended")AC.resume();try{fn(AC.currentTime+.005,a,b)}catch(e){}}}
function whoosh(t,f0,f1,dur,vol){const g=out(sfxBus,.2);g.gain.setValueAtTime(.0001,t);g.gain.linearRampToValueAtTime(vol,t+dur*.4);g.gain.exponentialRampToValueAtTime(.0001,t+dur);
  const f=AC.createBiquadFilter();f.type="bandpass";f.Q.value=1.6;f.frequency.setValueAtTime(f0,t);f.frequency.exponentialRampToValueAtTime(f1,t+dur);noise(t,dur+.05,f);f.connect(g)}
function thump(t,f0,vol,dur){const g=out(sfxBus,.2);g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.0001,t+dur);const o=AC.createOscillator();o.frequency.setValueAtTime(f0,t);o.frequency.exponentialRampToValueAtTime(f0*.3,t+dur*.8);o.connect(g);o.start(t);o.stop(t+dur+.05)}
function crack(t,vol){const g=out(sfxBus,.25);g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.0001,t+.12);const f=AC.createBiquadFilter();f.type="highpass";f.frequency.value=1400;noise(t,.14,f);f.connect(g)}
const sfx={
  tick:S(t=>{const g=out(sfxBus,.1);env(g,t,.004,.12,.03,.1,.04,0);osc("triangle",880,t,.1,g)}),
  slash:S(t=>{whoosh(t,3600,700,.2,.5)}),
  hit:S(t=>{thump(t,170,.75,.22);crack(t,.4)}),
  hurt:S(t=>{thump(t,120,.85,.3);crack(t,.3);whoosh(t,500,150,.25,.3)}),
  crit:S(t=>{thump(t,200,.9,.3);crack(t,.55);const g=out(sfxBus,.4);env(g,t,.005,.2,.1,.2,.4,0);osc("square",1568,t,.6,g);osc("square",2093,t+.05,.55,g)}),
  cast:S((t,el)=>{const base={feu:300,glace:900,foudre:1400,lumiere:700,ombre:160}[el]||500;const g=out(sfxBus,.5);env(g,t,.12,.22,.1,.6,.3,.1);
    const o=AC.createOscillator();o.type=el==="foudre"?"square":"sawtooth";o.frequency.setValueAtTime(base*.5,t);o.frequency.exponentialRampToValueAtTime(base*2,t+.45);const f=AC.createBiquadFilter();f.type="bandpass";f.frequency.value=base*2;f.Q.value=3;o.connect(f).connect(g);o.start(t);o.stop(t+.7);whoosh(t,base,base*4,.45,.25)}),
  boom:S((t,el)=>{thump(t,el==="ombre"?70:110,1,.55);const g=out(sfxBus,.5);g.gain.setValueAtTime(.6,t);g.gain.exponentialRampToValueAtTime(.0001,t+.7);
    const f=AC.createBiquadFilter();f.type="lowpass";f.frequency.setValueAtTime(el==="glace"||el==="lumiere"?6000:2400,t);f.frequency.exponentialRampToValueAtTime(200,t+.6);noise(t,.75,f);f.connect(g);
    if(el==="glace"||el==="lumiere"){const c=out(sfxBus,.6);env(c,t,.004,.16,.2,.2,.6,0);[2093,2637,3136].forEach(fq=>osc("sine",fq,t,.9,c))}
    if(el==="foudre"){crack(t,.8);crack(t+.07,.5)}}),
  parry:S(t=>{const g=out(sfxBus,.6);g.gain.setValueAtTime(.34,t);g.gain.exponentialRampToValueAtTime(.0001,t+.9);[1240,1730,2890,3640,5120].forEach((f,i)=>{const o=osc("sine",f,t,.95,g);o.detune.value=i*7});crack(t,.5)}),
  dodge:S(t=>{whoosh(t,900,2800,.22,.4)}),
  heal:S(t=>{const g=out(sfxBus,.7);env(g,t,.01,.16,.2,.4,.8,.2);[523,659,784,1047].forEach((f,i)=>osc("sine",f,t+i*.07,1.2,g))}),
  shield:S(t=>{const g=out(sfxBus,.6);env(g,t,.05,.14,.2,.5,.6,.1);osc("triangle",392,t,1,g);osc("triangle",587,t+.04,1,g);whoosh(t,400,1600,.35,.18)}),
  brk:S(t=>{crack(t,.9);thump(t,150,.9,.45);const g=out(sfxBus,.5);g.gain.setValueAtTime(.3,t);g.gain.exponentialRampToValueAtTime(.0001,t+.8);const f=AC.createBiquadFilter();f.type="highpass";f.frequency.value=4200;noise(t,.8,f);f.connect(g)}),
  status:S(t=>{const g=out(sfxBus,.4);env(g,t,.01,.14,.1,.4,.3,0);const o=osc("sawtooth",330,t,.5,g);o.frequency.exponentialRampToValueAtTime(140,t+.4)}),
  shout:S((t,low)=>{const g=out(sfxBus,.3);env(g,t,.02,.3,.05,.6,.12,.05);const src=AC.createGain();const o=AC.createOscillator();o.type="sawtooth";const f0=low?105:175;o.frequency.setValueAtTime(f0*1.15,t);o.frequency.exponentialRampToValueAtTime(f0*.8,t+.25);o.connect(src);o.start(t);o.stop(t+.3);
    const n=AC.createGain();n.gain.value=.25;noise(t,.3,n);n.connect(src);for(const[fq,q]of[[850,5],[1350,6]]){const b=AC.createBiquadFilter();b.type="bandpass";b.frequency.value=fq;b.Q.value=q;src.connect(b).connect(g)}}),
  step:S(t=>{thump(t,90,.22,.08)}),
  rumble:S(t=>{const g=out(sfxBus,.4);g.gain.setValueAtTime(.0001,t);g.gain.linearRampToValueAtTime(.5,t+.6);g.gain.exponentialRampToValueAtTime(.0001,t+2.4);const f=AC.createBiquadFilter();f.type="lowpass";f.frequency.value=140;noise(t,2.5,f);f.connect(g)}),
  slow:S(t=>{const g=out(sfxBus,.7);env(g,t,.01,.2,.3,.3,.5,0);const o=osc("sine",880,t,.9,g);o.frequency.exponentialRampToValueAtTime(220,t+.8)})
};
/* crépitement du feu en fond */
let fireOn=false;
function fire(on){if(!ensure())return;if(on&&!fireOn){fireOn=true;const s=AC.createBufferSource();s.buffer=noiseBuf;s.loop=true;const f=AC.createBiquadFilter();f.type="bandpass";f.frequency.value=420;f.Q.value=.5;const g=AC.createGain();g.gain.value=.05;
    const l=AC.createOscillator(),lg=AC.createGain();l.frequency.value=.7;lg.gain.value=.02;l.connect(lg).connect(g.gain);l.start();s.connect(f).connect(g).connect(sfxBus);s.start();
    setInterval(()=>{if(AC.state==="running"&&Math.random()<.5){const t=AC.currentTime+.01,c=out(sfxBus,.1);c.gain.setValueAtTime(.05+Math.random()*.06,t);c.gain.exponentialRampToValueAtTime(.0001,t+.04);const h=AC.createBiquadFilter();h.type="highpass";h.frequency.value=2500;noise(t,.05,h);h.connect(c)}},170)}}
return{music,stinger,accent,setDanger,sfx,fire,unlock(){if(ensure()&&AC.state==="suspended")AC.resume()},
  mute(v){muted=v;if(master)master.gain.value=v?0:.9},isMuted:()=>muted,state:()=>state};
})();
