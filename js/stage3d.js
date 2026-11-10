"use strict";
/* Magicaland : scène 3D (Three.js r147). Village de nuit, acteurs animés, caméra, effets. */
const Stage=(()=>{
const V3=THREE.Vector3;
const EQ={
 Knight:["1H_Sword_Offhand","Badge_Shield","Rectangle_Shield","Round_Shield","Spike_Shield","1H_Sword","2H_Sword"],
 Mage:["Spellbook","Spellbook_open","1H_Wand","2H_Staff"],
 Rogue:["Knife_Offhand","1H_Crossbow","2H_Crossbow","Knife","Throwable"],
 Rogue_Hooded:["Knife_Offhand","1H_Crossbow","2H_Crossbow","Knife","Throwable"],
 Barbarian:["1H_Axe_Offhand","Barbarian_Round_Shield","1H_Axe","2H_Axe","Mug"]};
const NAMES=Object.keys(EQ);
const ease={io:t=>t<.5?2*t*t:1-Math.pow(-2*t+2,2)/2,out:t=>1-Math.pow(1-t,3),in:t=>t*t,lin:t=>t};
let renderer,scene,camera,composer,bloomPass,finalPass,canvas,host;
let W=2,H=2,inset=0,quality=2,autoQ=true,baseScale=1,ready=false,rush=false,timeScale=1,elapsed=0;
const clock=new THREE.Clock(),models={},clips={},actors={},tweens=[],emitters=[],fireLights=[],fxLights=[],temps=[];
let fxAdd,fxSmoke,onFrame=null,perf={t:0,n:0};
const HEIGHT=1.9;

/* ---------- utilitaires ---------- */
function wait(ms){return rush?Promise.resolve():new Promise(r=>setTimeout(r,ms))}
function tween(dur,fn,e,scaled){
  if(rush||dur<=0){fn(1);return Promise.resolve()}
  return new Promise(res=>tweens.push({t:0,dur,fn,e:e||ease.io,res,scaled:!!scaled}))}
function glowTex(){
  const c=document.createElement("canvas");c.width=c.height=64;const g=c.getContext("2d");
  const r=g.createRadialGradient(32,32,0,32,32,32);r.addColorStop(0,"rgba(255,255,255,1)");r.addColorStop(.35,"rgba(255,255,255,.55)");r.addColorStop(1,"rgba(255,255,255,0)");
  g.fillStyle=r;g.fillRect(0,0,64,64);return new THREE.CanvasTexture(c)}

/* ---------- particules ---------- */
class PSys{
  constructor(max,tex,blending){
    this.max=max;this.cur=0;
    this.pos=new Float32Array(max*3);this.col=new Float32Array(max*3);this.size=new Float32Array(max);this.alpha=new Float32Array(max);
    this.vel=new Float32Array(max*3);this.life=new Float32Array(max);this.ml=new Float32Array(max);this.s0=new Float32Array(max);this.s1=new Float32Array(max);
    this.a0=new Float32Array(max);this.grav=new Float32Array(max);this.drag=new Float32Array(max);
    const g=this.geo=new THREE.BufferGeometry();
    g.setAttribute("position",new THREE.BufferAttribute(this.pos,3));g.setAttribute("color",new THREE.BufferAttribute(this.col,3));
    g.setAttribute("size",new THREE.BufferAttribute(this.size,1));g.setAttribute("alpha",new THREE.BufferAttribute(this.alpha,1));
    this.mat=new THREE.ShaderMaterial({uniforms:{map:{value:tex},scale:{value:300}},transparent:true,depthWrite:false,blending,
      vertexShader:"attribute float size;attribute float alpha;attribute vec3 color;varying vec3 vC;varying float vA;uniform float scale;void main(){vC=color;vA=alpha;vec4 mv=modelViewMatrix*vec4(position,1.);gl_PointSize=size*scale/max(.1,-mv.z);gl_Position=projectionMatrix*mv;}",
      fragmentShader:"uniform sampler2D map;varying vec3 vC;varying float vA;void main(){vec4 t=texture2D(map,gl_PointCoord);gl_FragColor=vec4(vC,1.)*t*vA;gl_FragColor.rgb*=1.;}"});
    this.pts=new THREE.Points(g,this.mat);this.pts.frustumCulled=false;this.pts.renderOrder=5;
  }
  emit(x,y,z,vx,vy,vz,r,g,b,life,s0,s1,a0,grav,drag){
    const i=this.cur;this.cur=(this.cur+1)%this.max;const j=i*3;
    this.pos[j]=x;this.pos[j+1]=y;this.pos[j+2]=z;this.vel[j]=vx;this.vel[j+1]=vy;this.vel[j+2]=vz;
    this.col[j]=r;this.col[j+1]=g;this.col[j+2]=b;this.life[i]=this.ml[i]=life;this.s0[i]=s0;this.s1[i]=s1;this.a0[i]=a0;this.grav[i]=grav||0;this.drag[i]=drag||0;
  }
  update(dt){
    const n=this.max;
    for(let i=0;i<n;i++){
      if(this.life[i]<=0){this.alpha[i]=0;continue}
      this.life[i]-=dt;const j=i*3,t=1-Math.max(0,this.life[i])/this.ml[i];
      const d=Math.max(0,1-this.drag[i]*dt);this.vel[j]*=d;this.vel[j+1]=this.vel[j+1]*d+this.grav[i]*dt;this.vel[j+2]*=d;
      this.pos[j]+=this.vel[j]*dt;this.pos[j+1]+=this.vel[j+1]*dt;this.pos[j+2]+=this.vel[j+2]*dt;
      this.size[i]=this.s0[i]+(this.s1[i]-this.s0[i])*t;
      this.alpha[i]=this.a0[i]*(t<.15?t/.15:1-(t-.15)/.85);
    }
    const a=this.geo.attributes;a.position.needsUpdate=a.color.needsUpdate=a.size.needsUpdate=a.alpha.needsUpdate=true;
  }
}
const R=(a,b)=>a+Math.random()*(b-a);
function col(hex){const c=new THREE.Color(hex);return c}

/* ---------- monde : village de nuit ---------- */
function buildWorld(){
  scene.background=new THREE.Color(0x05040a);
  scene.fog=new THREE.FogExp2(0x1c0f0e,0.022);
  const sky=new THREE.Mesh(new THREE.SphereGeometry(190,24,12),new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,fog:false,
    vertexShader:"varying vec3 vP;void main(){vP=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}",
    fragmentShader:"varying vec3 vP;void main(){float h=normalize(vP).y;vec3 top=vec3(.010,.012,.040);vec3 mid=vec3(.06,.03,.07);vec3 hor=vec3(.20,.065,.025);vec3 c=mix(hor,mid,smoothstep(-.02,.16,h));c=mix(c,top,smoothstep(.12,.55,h));gl_FragColor=vec4(c,1.);}"}));
  scene.add(sky);
  const sp=new Float32Array(900*3);for(let i=0;i<900;i++){const a=Math.random()*Math.PI*2,e=R(.12,1.45),r=175;sp[i*3]=Math.cos(a)*Math.cos(e)*r;sp[i*3+1]=Math.sin(e)*r;sp[i*3+2]=Math.sin(a)*Math.cos(e)*r}
  const sg=new THREE.BufferGeometry();sg.setAttribute("position",new THREE.BufferAttribute(sp,3));
  scene.add(new THREE.Points(sg,new THREE.PointsMaterial({color:0xcfd8ff,size:1.6,sizeAttenuation:false,fog:false,transparent:true,opacity:.85})));
  const moon=new THREE.Mesh(new THREE.SphereGeometry(9,24,16),new THREE.MeshBasicMaterial({fog:false}));moon.material.color.setRGB(2.6,2.7,3.4);moon.position.set(-58,74,-130);scene.add(moon);

  scene.add(new THREE.HemisphereLight(0x4a55a8,0x3a1c0c,.2));
  const ml=new THREE.DirectionalLight(0x9db4ff,.42);ml.position.set(-14,26,-22);ml.castShadow=true;
  ml.shadow.mapSize.set(2048,2048);const sc=ml.shadow.camera;sc.left=-22;sc.right=22;sc.top=22;sc.bottom=-22;sc.near=1;sc.far=80;ml.shadow.bias=-.0004;ml.shadow.normalBias=.03;scene.add(ml);scene.add(ml.target);
  Stage_moon=ml;
  const fill=new THREE.DirectionalLight(0xffb27a,.16);fill.position.set(7,7,12);scene.add(fill);

  const mGround=new THREE.MeshStandardMaterial({color:0x1d1916,roughness:1});
  const ground=new THREE.Mesh(new THREE.PlaneGeometry(260,260),mGround);ground.rotation.x=-Math.PI/2;ground.receiveShadow=true;scene.add(ground);
  const plaza=new THREE.Mesh(new THREE.CircleGeometry(11.5,56),new THREE.MeshStandardMaterial({color:0x2f2924,roughness:.95}));plaza.rotation.x=-Math.PI/2;plaza.position.y=.012;plaza.receiveShadow=true;scene.add(plaza);
  const ringM=new THREE.Mesh(new THREE.RingGeometry(11.5,12.1,56),new THREE.MeshStandardMaterial({color:0x221c18,roughness:1}));ringM.rotation.x=-Math.PI/2;ringM.position.y=.014;scene.add(ringM);
  const road=new THREE.Mesh(new THREE.PlaneGeometry(6.5,60),new THREE.MeshStandardMaterial({color:0x27221e,roughness:1}));road.rotation.x=-Math.PI/2;road.position.set(0,.01,36);road.receiveShadow=true;scene.add(road);

  const mWall=[new THREE.MeshStandardMaterial({color:0x4c4034,roughness:.95}),new THREE.MeshStandardMaterial({color:0x41362c,roughness:.95}),new THREE.MeshStandardMaterial({color:0x54473a,roughness:.95})];
  const mRoof=[new THREE.MeshStandardMaterial({color:0x3a2422,roughness:.9}),new THREE.MeshStandardMaterial({color:0x2c2a36,roughness:.9})];
  const mBeam=new THREE.MeshStandardMaterial({color:0x2a1f18,roughness:1});
  const mWin=new THREE.MeshBasicMaterial({fog:false});mWin.color.setRGB(2.6,1.35,.42);
  const mDark=new THREE.MeshStandardMaterial({color:0x14100d,roughness:1});
  const roofGeo=new THREE.ConeGeometry(1,1,4);roofGeo.rotateY(Math.PI/4);
  function house(x,z,ry,w,d,h,burn){
    const g=new THREE.Group();
    const wall=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),mWall[(Math.random()*3)|0]);wall.position.y=h/2;wall.castShadow=wall.receiveShadow=true;g.add(wall);
    const rh=h*.8,roof=new THREE.Mesh(roofGeo,mRoof[(Math.random()*2)|0]);roof.scale.set(w*.82,rh,d*.82);roof.position.y=h+rh/2;roof.castShadow=true;g.add(roof);
    for(const sx of[-1,1]){const b=new THREE.Mesh(new THREE.BoxGeometry(.18,h,.18),mBeam);b.position.set(sx*(w/2),h/2,d/2);g.add(b)}
    const tb=new THREE.Mesh(new THREE.BoxGeometry(w+.1,.18,.18),mBeam);tb.position.set(0,h*.62,d/2);g.add(tb);
    const door=new THREE.Mesh(new THREE.PlaneGeometry(.9,1.7),mDark);door.position.set(0,.85,d/2+.02);g.add(door);
    for(const sx of[-1,1]){if(Math.random()<.8){const wn=new THREE.Mesh(new THREE.PlaneGeometry(.55,.7),mWin);wn.position.set(sx*w*.3,h*.58,d/2+.02);g.add(wn)}}
    g.position.set(x,0,z);g.rotation.y=ry;scene.add(g);
    if(burn){const p=new V3(R(-w*.2,w*.2),h+rh*.55,0).applyAxisAngle(new V3(0,1,0),ry).add(g.position);emitters.push({p,r:w*.32,rate:burn*46,size:burn*1.25,up:3.2,smoke:.5})}
    return g}
  // fond derrière les ennemis
  house(-13,-15,.25,6,5,4.2,1.5);house(-4.5,-17,-.08,5.5,5,3.8,0);house(4.5,-16.5,.12,6,5.5,4.6,1.25);house(13.5,-14,-.3,5.5,5,3.9,0);
  house(-20,-25,.2,7,6,5,0);house(-7,-27,0,6,6,5.4,1.1);house(9,-28,-.1,7,6,5,0);house(22,-24,-.25,6,6,4.6,.9);
  // côtés de la place
  house(-17,-5,Math.PI/2+.1,5.5,5,4,0);house(-17.5,5,Math.PI/2-.08,6,5,3.8,.9);house(17,-4,-Math.PI/2+.1,5.5,5,4.2,1);house(17.5,6,-Math.PI/2-.1,6,5,3.7,0);
  // rue derrière les héros
  for(let i=0;i<5;i++){const z=16+i*8.5;house(-8-R(0,1.5),z,Math.PI/2+R(-.1,.1),5.5,5,R(3.6,4.6),i===2?1:0);house(8+R(0,1.5),z+R(-1.5,1.5),-Math.PI/2+R(-.1,.1),5.5,5,R(3.6,4.6),i===4?.9:0)}
  // arbres
  const mTree=new THREE.MeshStandardMaterial({color:0x10201a,roughness:1}),mTrunk=new THREE.MeshStandardMaterial({color:0x1c140f,roughness:1});
  for(let i=0;i<46;i++){const a=Math.random()*Math.PI*2,r=R(36,62),x=Math.cos(a)*r,z=Math.sin(a)*r;if(Math.abs(x)<10&&z>0)continue;
    const h=R(5,9),t=new THREE.Mesh(new THREE.ConeGeometry(R(1.6,2.6),h,7),mTree);t.position.set(x,h/2+1.2,z);scene.add(t);
    const tr=new THREE.Mesh(new THREE.CylinderGeometry(.25,.35,1.6,6),mTrunk);tr.position.set(x,.8,z);scene.add(tr)}
  // tonneaux, caisses, barrières
  const mWood=new THREE.MeshStandardMaterial({color:0x5a4330,roughness:.9});
  [[-9,-8],[-9.8,-7.2],[10,-7.5],[12.5,2],[-12.5,1.5],[-12,2.6],[9.5,9],[-10,10]].forEach(([x,z],i)=>{
    const m=i%2?new THREE.Mesh(new THREE.CylinderGeometry(.45,.45,1,10),mWood):new THREE.Mesh(new THREE.BoxGeometry(.9,.9,.9),mWood);
    m.position.set(x,i%2?.5:.45,z);m.rotation.y=R(0,1.5);m.castShadow=m.receiveShadow=true;scene.add(m)});
  for(let i=0;i<10;i++){const p=new THREE.Mesh(new THREE.BoxGeometry(.14,1,.14),mBeam);p.position.set(-13+i*.9,.5,10.5);p.castShadow=true;scene.add(p)}
  const rail=new THREE.Mesh(new THREE.BoxGeometry(8.4,.1,.1),mBeam);rail.position.set(-9,.75,10.5);scene.add(rail);
  // braseros : éclairent les combattants
  const mIron=new THREE.MeshStandardMaterial({color:0x1c1a1a,roughness:.6,metalness:.6});
  [[-6.2,-6.4],[6.4,-6.0],[-7.5,6.5],[7.6,7]].forEach(([x,z],i)=>{
    const st=new THREE.Mesh(new THREE.CylinderGeometry(.09,.16,1.5,6),mIron);st.position.set(x,.75,z);st.castShadow=true;scene.add(st);
    const bw=new THREE.Mesh(new THREE.CylinderGeometry(.42,.22,.32,10),mIron);bw.position.set(x,1.6,z);scene.add(bw);
    emitters.push({p:new V3(x,1.78,z),r:.2,rate:26,size:.5,up:1.9,smoke:.12});
    if(i<2){const l=new THREE.PointLight(0xff8a3a,1.0,22,1.5);l.position.set(x,2.5,z);scene.add(l);fireLights.push({l,b:1.0})}});
  const big=new THREE.PointLight(0xff6a2a,1.1,55,1.3);big.position.set(3,9,-18);scene.add(big);fireLights.push({l:big,b:1.1});
  // lumières d'effets réutilisées (évite les recompilations)
  for(let i=0;i<3;i++){const l=new THREE.PointLight(0xffffff,0,14,1.6);l.position.set(0,-50,0);scene.add(l);fxLights.push({l,busy:false})}
  const tex=glowTex();
  fxAdd=new PSys(2600,tex,THREE.AdditiveBlending);scene.add(fxAdd.pts);
  fxSmoke=new PSys(420,tex,THREE.NormalBlending);fxSmoke.pts.renderOrder=4;scene.add(fxSmoke.pts);
}
let Stage_moon=null;
function updateEmitters(dt){
  const dens=quality===0?.45:quality===1?.75:1;
  for(const e of emitters){
    e.acc=(e.acc||0)+e.rate*dens*dt;
    while(e.acc>=1){e.acc--;
      const a=Math.random()*Math.PI*2,rr=Math.sqrt(Math.random())*e.r,x=e.p.x+Math.cos(a)*rr,z=e.p.z+Math.sin(a)*rr;
      const k=Math.random();
      fxAdd.emit(x,e.p.y+R(0,.2),z,R(-.3,.3),R(e.up*.6,e.up),R(-.3,.3),k<.3?2.2:2.0,k<.3?1.25:k<.7?.7:.38,k<.3?.45:.12,R(.5,1.05),e.size*R(1.6,2.4),e.size*.3,.55,.6,.6);
      if(Math.random()<.10)fxAdd.emit(x,e.p.y+.3,z,R(-1,1),R(e.up,e.up*2.2),R(-1,1),2.4,1.2,.4,R(1.5,3.2),.16,.05,1,-.3,.25);
      if(Math.random()<e.smoke*.35)fxSmoke.emit(x,e.p.y+e.up*.5,z,R(-.4,.6),R(1.2,2.2),R(-.3,.3),.05,.045,.045,R(2.5,4.5),e.size*2.5,e.size*7,.42,.1,.1);
    }
  }
  // braises dans l'air
  if(Math.random()<dt*22*dens)fxAdd.emit(R(-16,16),R(0,3),R(-18,12),R(-.4,.8),R(.5,1.6),R(-.3,.3),2.3,1.0,.3,R(3,6),.12,.03,.9,0,.05);
  for(const f of fireLights)f.l.intensity=f.b*(.82+.18*Math.sin(elapsed*9+f.b*7)+.1*Math.sin(elapsed*23.7+f.b))*(.94+Math.random()*.12);
}

/* ---------- chargement ---------- */
function load(onP){
  const L=new THREE.GLTFLoader();let done=0;
  return Promise.all(NAMES.map(n=>new Promise((res,rej)=>L.load("assets/"+n+".glb",g=>{
    models[n]=g.scene;g.animations.forEach(c=>{clips[c.name]=c});done++;onP&&onP(done/NAMES.length);res()},undefined,rej)))).then(()=>{
    const box=new THREE.Box3().setFromObject(models.Knight);baseScale=HEIGHT/Math.max(.5,box.max.y-box.min.y);
    ready=true})}

/* ---------- acteurs ---------- */
function spawn(id,o){
  remove(id);
  const root=new THREE.Group(),m=THREE.SkeletonUtils.clone(models[o.model]);
  m.scale.setScalar(baseScale*(o.scale||1));root.add(m);
  const eq=EQ[o.model],show=o.show||[],mats=[];
  m.traverse(n=>{
    if(eq.includes(n.name))n.visible=show.includes(n.name);
    if(n.isMesh){n.castShadow=true;n.frustumCulled=false;n.material=n.material.clone();
      if(o.tint)n.material.color.multiply(col(o.tint));
      n.userData.base=n.material.color.clone();mats.push(n.material)}});
  root.position.set(o.x,0,o.z);root.rotation.y=o.face||0;scene.add(root);
  const a={id,root,m,mixer:new THREE.AnimationMixer(m),acts:{},cur:null,idle:o.idle||"Idle",home:new V3(o.x,0,o.z),face:o.face||0,
    h:HEIGHT*(o.scale||1),dead:false,mats,flash:0,gray:0,opt:o};
  actors[id]=a;setAnim(a,a.idle,0);
  if(o.orb){const g=new THREE.Mesh(new THREE.SphereGeometry(.11,12,8),new THREE.MeshBasicMaterial());const c=col(o.orb);g.material.color.setRGB(c.r*3,c.g*3,c.b*3);
    const hand=m.getObjectByName("handslotl")||m.getObjectByName("handl");if(hand){g.scale.setScalar(1/(baseScale*(o.scale||1)));hand.add(g);a.orb=g}}
  if(o.extras)decorate(a,o.extras);
  return a}
function decorate(a,x){
  const head=a.m.getObjectByName("head");if(!head)return;const u=1/baseScale;
  const mk=(geo,c)=>{const m=new THREE.Mesh(geo,new THREE.MeshStandardMaterial({color:c,roughness:.8}));m.castShadow=true;return m};
  if(x.ears==="beast")for(const s of[-1,1]){const e=mk(new THREE.ConeGeometry(.11*u,.28*u,4),x.hair||0x8a8a94);e.position.set(s*.2*u,.62*u,-.02*u);e.rotation.z=-s*.25;head.add(e)}
  if(x.ears==="elf")for(const s of[-1,1]){const e=mk(new THREE.ConeGeometry(.05*u,.3*u,4),x.skin||0xf1d9bf);e.position.set(s*.32*u,.3*u,0);e.rotation.z=-s*1.15;head.add(e)}
  if(x.horns)for(const s of[-1,1]){const e=mk(new THREE.ConeGeometry(.06*u,.34*u,6),0xe8dcc0);e.position.set(s*.16*u,.66*u,.08*u);e.rotation.z=-s*.35;e.rotation.x=.3;head.add(e)}
  const hips=a.m.getObjectByName("hips");
  if(x.tail&&hips){const t=mk(new THREE.CylinderGeometry(.03*u,.06*u,.6*u,6),x.tail);t.position.set(0,.05*u,-.34*u);t.rotation.x=-1.0;hips.add(t)}
  const chest=a.m.getObjectByName("chest");
  if(x.wings&&chest)for(const s of[-1,1]){const g=new THREE.BufferGeometry();g.setAttribute("position",new THREE.BufferAttribute(new Float32Array([0,0,0, s*.9*u,.55*u,-.2*u, s*.7*u,-.5*u,-.25*u]),3));g.computeVertexNormals();
    const w=new THREE.Mesh(g,new THREE.MeshStandardMaterial({color:x.wings,side:THREE.DoubleSide,roughness:.7,transparent:true,opacity:.92}));w.position.set(s*.08*u,.1*u,-.18*u);chest.add(w)}
}
function remove(id){const a=actors[id];if(!a)return;scene.remove(a.root);a.mixer.stopAllAction();delete actors[id]}
function removeWhere(fn){Object.keys(actors).filter(fn).forEach(remove)}
function action(a,name){if(!a.acts[name]){const c=clips[name];if(!c)return null;a.acts[name]=a.mixer.clipAction(c)}return a.acts[name]}
function setAnim(a,name,fade,opt){
  opt=opt||{};const act=action(a,name);if(!act)return null;
  act.reset();act.setLoop(opt.once?THREE.LoopOnce:THREE.LoopRepeat,opt.once?1:Infinity);act.clampWhenFinished=!!opt.once;act.timeScale=opt.speed||1;act.enabled=true;act.setEffectiveWeight(1);
  if(a.cur&&a.cur!==act&&fade>0)act.crossFadeFrom(a.cur,fade,false);else if(a.cur&&a.cur!==act)a.cur.stop();
  act.play();a.cur=act;return act}
function clipDur(name){return clips[name]?clips[name].duration:1}
function playOnce(id,name,opt){
  opt=opt||{};const a=actors[id];if(!a||!clips[name])return Promise.resolve();
  const sp=opt.speed||1,act=setAnim(a,name,opt.fade===undefined?.12:opt.fade,{once:true,speed:sp}),dur=act.getClip().duration/sp;
  if(rush){if(!opt.hold&&!a.dead)setAnim(a,a.idle,0);return Promise.resolve()}
  return new Promise(res=>{let done=false;
    const fin=()=>{if(done)return;done=true;a.mixer.removeEventListener("finished",h);if(!opt.hold&&!a.dead&&a.cur===act)setAnim(a,a.idle,.2);res()};
    const h=e=>{if(e.action===act)fin()};a.mixer.addEventListener("finished",h);
    setTimeout(fin,dur*1000/Math.max(.15,timeScale)+700)})}
function loopAnim(id,name,speed){const a=actors[id];if(a)setAnim(a,name,.15,{speed})}
function idle(id){const a=actors[id];if(a&&!a.dead)setAnim(a,a.idle,.2)}
function faceTo(id,x,z){const a=actors[id];if(a)a.root.rotation.y=Math.atan2(x-a.root.position.x,z-a.root.position.z)}
async function moveTo(id,x,z,dur,opt){
  opt=opt||{};const a=actors[id];if(!a)return;const p=a.root.position,sx=p.x,sz=p.z;
  if(Math.hypot(x-sx,z-sz)>.05)faceTo(id,x,z);
  if(!rush)setAnim(a,opt.anim||"Running_A",.12,{speed:opt.speed||1});
  await tween(dur,t=>{p.x=sx+(x-sx)*t;p.z=sz+(z-sz)*t},opt.ease||ease.lin,true);
  if(opt.face!==undefined)a.root.rotation.y=opt.face;
  if(!a.dead)setAnim(a,a.idle,.18)}
function place(id,x,z,face){const a=actors[id];if(!a)return;a.root.position.set(x,0,z);if(face!==undefined)a.root.rotation.y=face}
function posOf(id,y){const a=actors[id];return a?new V3(a.root.position.x,y===undefined?a.h*.6:y,a.root.position.z):new V3()}
function hit(id,opt){
  opt=opt||{};const a=actors[id];if(!a)return;a.flash=1;a.flashCol=col(opt.color||0xffffff);
  if(!a.dead)playOnce(id,opt.heavy?"Hit_B":"Hit_A",{fade:.05});
  const p=a.root.position,d=new V3(Math.sin(a.root.rotation.y),0,Math.cos(a.root.rotation.y)).multiplyScalar(-(opt.heavy?.45:.22)),bx=p.x,bz=p.z;
  tween(.28,t=>{const k=Math.sin(t*Math.PI);p.x=bx+d.x*k;p.z=bz+d.z*k},ease.lin,true)}
function die(id,vanish){
  const a=actors[id];if(!a||a.dead)return;a.dead=true;
  playOnce(id,"Death_A",{hold:true}).then(()=>{if(vanish&&actors[id]===a)tween(.9,t=>{a.root.position.y=-t*2.2},ease.in,true).then(()=>{a.root.visible=false})})}
function revive(id){const a=actors[id];if(!a)return;a.dead=false;a.root.visible=true;a.root.position.y=0;setAnim(a,a.idle,.3)}
function setGray(id,on){const a=actors[id];if(a)a.gray=on?1:0}
function updateActors(dt){
  for(const k in actors){const a=actors[k];a.mixer.update(dt);
    if(a.flash>0||a.grayNow!==a.gray){a.flash=Math.max(0,a.flash-dt*4.5);a.grayNow=a.gray;
      for(const m of a.mats){if(m.emissive)m.emissive.copy(a.flashCol||col(0xffffff)).multiplyScalar(a.flash*.9);}
      a.m.traverse(n=>{if(n.isMesh&&n.userData.base){n.material.color.copy(n.userData.base);if(a.gray){const l=n.material.color.r*.3+n.material.color.g*.5+n.material.color.b*.2;n.material.color.setRGB(l*.75,l*.8,l*.95)}}})}
    if(a.orb)a.orb.scale.setScalar((1/(baseScale*(a.opt.scale||1)))*(1+.18*Math.sin(elapsed*5)))}}
function project(id){
  const a=actors[id];if(!a||!a.root.visible)return null;
  const top=new V3(a.root.position.x,a.h+.15,a.root.position.z).project(camera),bot=new V3(a.root.position.x,0,a.root.position.z).project(camera);
  if(top.z>1||bot.z>1)return null;
  const x=(top.x*.5+.5)*W,y=(-top.y*.5+.5)*H,yb=(-bot.y*.5+.5)*H;return{x,y,h:Math.max(20,yb-y)}}

/* ---------- caméra ---------- */
const cam={pos:new V3(0,14,26),look:new V3(0,2,0),tp:new V3(0,14,26),tl:new V3(0,2,0),k:2.6,sh:0,fov:50,tfov:50,busy:false,orbit:null};
cam.snap=(p,l)=>{cam.pos.copy(p);cam.tp.copy(p);cam.look.copy(l);cam.tl.copy(l);cam.orbit=null};
cam.go=(p,l,k)=>{cam.tp.copy(p);cam.tl.copy(l);cam.k=k||2.6;cam.orbit=null};
cam.move=(p,l,dur,e)=>{const p0=cam.pos.clone(),l0=cam.look.clone();cam.busy=true;cam.orbit=null;
  return tween(dur,t=>{cam.pos.lerpVectors(p0,p,t);cam.look.lerpVectors(l0,l,t);cam.tp.copy(cam.pos);cam.tl.copy(cam.look)},e||ease.io).then(()=>{cam.busy=false})};
cam.shake=a=>{cam.sh=Math.max(cam.sh,a)};
cam.zoom=f=>{cam.tfov=f};
cam.setOrbit=(center,r,h,speed)=>{cam.orbit={center,r,h,speed,a:Math.atan2(cam.pos.x-center.x,cam.pos.z-center.z)}};
function portrait(){return W/H<.95}
function baseFov(){return portrait()?60:42}
cam.wide=k=>{cam.zoom(baseFov());portrait()?cam.go(new V3(-2.7,5.4,11.6),new V3(-.05,1.55,-.6),k):cam.go(new V3(-7.5,4.2,9.2),new V3(.4,1.1,-.6),k)};
cam.attack=(att,tgt,k)=>{const A=posOf(att,0),T=posOf(tgt,0),d=T.clone().sub(A).setY(0).normalize(),s=new V3(d.z,0,-d.x);
  cam.zoom(baseFov()-8);cam.go(A.clone().addScaledVector(d,-3.4).addScaledVector(s,1.9).setY(2.3),A.clone().lerp(T,.62).setY(1.25),k||4)};
cam.threat=(en,al,k)=>{const E=posOf(en,0),A=posOf(al,0),d=E.clone().sub(A).setY(0).normalize(),s=new V3(d.z,0,-d.x);
  cam.zoom(baseFov()-4);cam.go(A.clone().addScaledVector(d,-3.3).addScaledVector(s,-1.5).setY(2.4),A.clone().lerp(E,.6).setY(1.2),k||4.5)};
cam.close=(id,k)=>{const a=actors[id];if(!a)return;const P=posOf(id,0),f=new V3(Math.sin(a.root.rotation.y),0,Math.cos(a.root.rotation.y)),s=new V3(f.z,0,-f.x);
  cam.zoom(baseFov()-12);cam.go(P.clone().addScaledVector(f,3).addScaledVector(s,1.1).setY(a.h*.78),P.clone().setY(a.h*.7),k||4)};
function updateCam(dt){
  if(cam.orbit){const o=cam.orbit;o.a+=o.speed*dt;cam.tp.set(o.center.x+Math.sin(o.a)*o.r,o.h,o.center.z+Math.cos(o.a)*o.r);cam.tl.copy(o.center)}
  if(!cam.busy){const f=1-Math.exp(-cam.k*dt);cam.pos.lerp(cam.tp,f);cam.look.lerp(cam.tl,f)}
  cam.fov+=(cam.tfov-cam.fov)*(1-Math.exp(-5*dt));
  if(Math.abs(camera.fov-cam.fov)>.01){camera.fov=cam.fov;camera.updateProjectionMatrix()}
  cam.sh=Math.max(0,cam.sh-dt*2.2*(cam.sh+.15));
  const s=cam.sh;
  camera.position.set(cam.pos.x+Math.sin(elapsed*.45)*.12+(Math.random()-.5)*s,cam.pos.y+Math.sin(elapsed*.33)*.07+(Math.random()-.5)*s,cam.pos.z+(Math.random()-.5)*s);
  camera.lookAt(cam.look);
}

/* ---------- effets ---------- */
function fxLight(pos,color,intensity,dur){
  const f=fxLights.find(x=>!x.busy);if(!f)return;f.busy=true;f.l.color.set(color);f.l.position.copy(pos);
  tween(dur,t=>{f.l.intensity=intensity*(1-t)},ease.out,true).then(()=>{f.l.intensity=0;f.busy=false})}
const fx={
  burst(pos,color,n,speed,size,life){const c=col(color);n=Math.round(n*(quality===0?.5:1));
    for(let i=0;i<n;i++){const a=Math.random()*Math.PI*2,e=R(-.6,1.2),v=R(speed*.3,speed);
      fxAdd.emit(pos.x,pos.y,pos.z,Math.cos(a)*Math.cos(e)*v,Math.sin(e)*v,Math.sin(a)*Math.cos(e)*v,c.r*2.4,c.g*2.4,c.b*2.4,R(life*.5,life),size*R(.6,1.3),size*.1,1,-4,1.6)}},
  sparks(pos,color,n){const c=col(color);for(let i=0;i<n;i++){const a=Math.random()*Math.PI*2,v=R(3,9);
    fxAdd.emit(pos.x,pos.y,pos.z,Math.cos(a)*v,R(1,6),Math.sin(a)*v,c.r*3,c.g*3,c.b*3,R(.25,.6),.16,.03,1,-14,.8)}},
  ring(pos,color,r0,r1,dur){
    const m=new THREE.Mesh(new THREE.RingGeometry(.82,1,48),new THREE.MeshBasicMaterial({transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,side:THREE.DoubleSide,fog:false}));
    const c=col(color);m.material.color.setRGB(c.r*2.2,c.g*2.2,c.b*2.2);m.rotation.x=-Math.PI/2;m.position.set(pos.x,.06,pos.z);scene.add(m);
    tween(dur,t=>{const r=r0+(r1-r0)*t;m.scale.setScalar(r);m.material.opacity=1-t},ease.out,true).then(()=>{scene.remove(m);m.geometry.dispose();m.material.dispose()})},
  slash(pos,color){
    const m=new THREE.Mesh(new THREE.RingGeometry(.72,1,40,1,0,2.6),new THREE.MeshBasicMaterial({transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,side:THREE.DoubleSide,fog:false}));
    const c=col(color);m.material.color.setRGB(c.r*2.6,c.g*2.6,c.b*2.6);m.position.copy(pos);m.lookAt(camera.position);m.rotateZ(R(0,6.28));scene.add(m);
    tween(.26,t=>{m.scale.setScalar(.5+t*1.3);m.rotateZ(.22);m.material.opacity=1-t*t},ease.out,true).then(()=>{scene.remove(m);m.geometry.dispose();m.material.dispose()});
    fx.sparks(pos,color,14)},
  impact(pos,color,big){fx.burst(pos,color,big?46:24,big?8:5.5,big?.75:.5,big?.75:.5);fx.sparks(pos,0xfff2c0,big?20:10);fxLight(pos,color,big?9:5,big?.5:.3);if(big)fx.ring(pos,color,.4,4.2,.5)},
  projectile(from,to,color,dur,arc){
    const c=col(color),m=new THREE.Mesh(new THREE.SphereGeometry(.2,12,8),new THREE.MeshBasicMaterial({fog:false}));m.material.color.setRGB(c.r*3.2,c.g*3.2,c.b*3.2);scene.add(m);
    const f=fxLights.find(x=>!x.busy);if(f){f.busy=true;f.l.color.set(color);f.l.intensity=4}
    return tween(dur,t=>{m.position.lerpVectors(from,to,t);m.position.y+=Math.sin(t*Math.PI)*(arc||0);if(f)f.l.position.copy(m.position);
      for(let i=0;i<3;i++)fxAdd.emit(m.position.x+R(-.1,.1),m.position.y+R(-.1,.1),m.position.z+R(-.1,.1),R(-.6,.6),R(-.3,.8),R(-.6,.6),c.r*2.2,c.g*2.2,c.b*2.2,R(.25,.55),.55,.05,.9,0,1)},ease.in,true)
      .then(()=>{scene.remove(m);m.geometry.dispose();m.material.dispose();if(f){f.l.intensity=0;f.busy=false}})},
  charge(id,color,dur){const c=col(color),a=actors[id];if(!a)return;const n=Math.round(dur*60);let i=0;
    const iv=setInterval(()=>{if(i++>n||!actors[id]){clearInterval(iv);return}const p=posOf(id,a.h*.62),an=Math.random()*Math.PI*2,r=R(.9,1.5),y=R(-.6,.9);
      fxAdd.emit(p.x+Math.cos(an)*r,p.y+y,p.z+Math.sin(an)*r,-Math.cos(an)*r*2.4,-y*2.2,-Math.sin(an)*r*2.4,c.r*2.4,c.g*2.4,c.b*2.4,.42,.3,.05,1,0,0)},16)},
  pillar(pos,color){const c=col(color);fx.ring(pos,color,.3,1.9,.8);fxLight(new V3(pos.x,1.4,pos.z),color,5,.9);
    for(let i=0;i<70;i++){const a=Math.random()*Math.PI*2,r=R(.15,.85);fxAdd.emit(pos.x+Math.cos(a)*r,R(0,.4),pos.z+Math.sin(a)*r,0,R(1.6,4),0,c.r*2.2,c.g*2.2,c.b*2.2,R(.6,1.3),.34,.05,.95,0,.3)}},
  shield(id,color){const a=actors[id];if(!a)return;const c=col(color||0x6cc4e8);
    const m=new THREE.Mesh(new THREE.SphereGeometry(a.h*.62,24,16),new THREE.MeshBasicMaterial({transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false}));
    m.material.color.setRGB(c.r*1.2,c.g*1.2,c.b*1.2);m.position.copy(posOf(id,a.h*.55));scene.add(m);
    tween(.9,t=>{m.scale.setScalar(.6+.5*ease.out(Math.min(1,t*2.5)));m.material.opacity=.42*(1-t)},ease.lin,true).then(()=>{scene.remove(m);m.geometry.dispose();m.material.dispose()})},
  aura(id,color){const p=posOf(id,0);fx.ring(p,color,.3,1.5,.6);fx.burst(posOf(id),color,16,2.6,.4,.7)},
  light:fxLight
};
function slowmo(scale,ms){timeScale=scale;return new Promise(r=>setTimeout(()=>{timeScale=1;r()},ms))}
function hitStop(ms){const p=timeScale;timeScale=.04;setTimeout(()=>{timeScale=p===.04?1:p},ms)}

/* ---------- rendu ---------- */
const FinalShader={uniforms:{tDiffuse:{value:null},vig:{value:.85},sat:{value:1.08},red:{value:0}},
  vertexShader:"varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}",
  fragmentShader:"uniform sampler2D tDiffuse;uniform float vig;uniform float sat;uniform float red;varying vec2 vUv;vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);}void main(){vec3 c=texture2D(tDiffuse,vUv).rgb*1.05;c=aces(c);float l=dot(c,vec3(.299,.587,.114));c=mix(vec3(l),c,sat);vec2 q=vUv-.5;float d=length(q)*1.2;c*=mix(1.,smoothstep(.95,.2,d),vig);c=mix(c,c*vec3(1.25,.55,.5),red*smoothstep(.2,.8,d));c=pow(c,vec3(1./2.2));gl_FragColor=vec4(c,1.);}"};
function setQuality(q,manual){
  quality=q;if(manual)autoQ=false;if(!renderer)return;
  const dpr=Math.min(window.devicePixelRatio||1,q===2?2:q===1?1.5:1);renderer.setPixelRatio(dpr);
  renderer.shadowMap.enabled=q>0;if(Stage_moon)Stage_moon.castShadow=q>0;
  scene.traverse(o=>{if(o.material&&o.material.isMeshStandardMaterial)o.material.needsUpdate=true});
  if(composer){composer.setPixelRatio(dpr)}
  layout()}
function layout(){
  if(!renderer)return;const r=host.getBoundingClientRect();W=Math.max(2,Math.round(r.width));H=Math.max(2,Math.round(r.height-inset));
  canvas.style.width=W+"px";canvas.style.height=H+"px";renderer.setSize(W,H,false);if(composer)composer.setSize(W,H);
  camera.aspect=W/H;camera.updateProjectionMatrix()}
function init(cv,hostEl,opt){
  canvas=cv;host=hostEl;opt=opt||{};
  renderer=new THREE.WebGLRenderer({canvas:cv,antialias:true,powerPreference:"high-performance"});
  renderer.outputEncoding=THREE.sRGBEncoding;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.05;
  renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  scene=new THREE.Scene();camera=new THREE.PerspectiveCamera(50,1,.1,400);
  buildWorld();
  try{
    const rt=new THREE.WebGLRenderTarget(4,4,{type:THREE.HalfFloatType,samples:4});
    composer=new THREE.EffectComposer(renderer,rt);composer.addPass(new THREE.RenderPass(scene,camera));
    bloomPass=new THREE.UnrealBloomPass(new THREE.Vector2(256,256),.5,.65,1.0);composer.addPass(bloomPass);
    finalPass=new THREE.ShaderPass(FinalShader);composer.addPass(finalPass);
  }catch(e){composer=null}
  if(opt.quality!==undefined&&opt.quality!==null){autoQ=false;quality=opt.quality}
  setQuality(quality);window.addEventListener("resize",layout);
  cam.snap(new V3(0,15,30),new V3(0,2,-4));cam.setOrbit(new V3(0,2.5,-3),30,13,.05);
  requestAnimationFrame(tick)}
function tick(){
  requestAnimationFrame(tick);
  const real=Math.min(clock.getDelta(),.1),dt=real*timeScale;elapsed+=dt;
  for(let i=tweens.length-1;i>=0;i--){const tw=tweens[i];tw.t+=(tw.scaled?dt:real)/tw.dur;const t=rush?1:Math.min(1,tw.t);tw.fn(tw.e(t));if(t>=1){tweens.splice(i,1);tw.res()}}
  updateActors(dt);updateEmitters(dt);fxAdd.update(dt);fxSmoke.update(dt);updateCam(real);
  const sc=(renderer.getDrawingBufferSize(new THREE.Vector2()).y*.5)/Math.tan(camera.fov*Math.PI/360);fxAdd.mat.uniforms.scale.value=sc;fxSmoke.mat.uniforms.scale.value=sc;
  if(onFrame)onFrame();
  if(composer&&quality>0){bloomPass.enabled=true;composer.render()}else renderer.render(scene,camera);
  // qualité automatique
  if(autoQ&&ready){perf.t+=real;perf.n++;if(perf.n>=80){const ms=perf.t/perf.n*1000;perf.t=perf.n=0;if(ms>38&&quality>0)setQuality(quality-1)}}
}
return{init,load,layout,spawn,remove,removeWhere,playOnce,loopAnim,idle,moveTo,place,faceTo,posOf,hit,die,revive,setGray,project,cam,fx,slowmo,hitStop,wait,tween,ease,clipDur,
  setInset(px){inset=px;layout()},setQuality,quality:()=>quality,isReady:()=>ready,setRush(v){rush=v},isRush:()=>rush,
  setOnFrame(f){onFrame=f},setRed(v){if(finalPass)finalPass.uniforms.red.value=v},setSat(v){if(finalPass)finalPass.uniforms.sat.value=v},
  actor:id=>actors[id],size:()=>({W,H}),V3};
})();
