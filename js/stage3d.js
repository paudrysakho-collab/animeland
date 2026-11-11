"use strict";
/* Magicaland : scène 3D (Three.js r147). Village de nuit, acteurs animés, caméra, effets. */
const Stage=(()=>{
const V3=THREE.Vector3;
/* Personnages anime (modèles VRoid en CC0) et bibliothèque d'animations (Quaternius, CC0). */
const NAMES=["Sendagaya_Shibu","Sakurada_Fumiriya","Victoria_Rubin","Vita","Vivi","Darkness_Shibu","HairSample_Male","Anims"];
const REF="Sendagaya_Shibu",TALL=1.72,EMI=.3;
// anciens noms d'animation (utilisés par le jeu) vers les clips de la bibliothèque
const ALIAS={Idle:"Idle_Loop","2H_Melee_Idle":"Sword_Idle",Running_A:"Sprint_Loop",Walking_A:"Walk_Loop",
 "1H_Melee_Attack_Chop":"Sword_Attack","1H_Melee_Attack_Slice_Diagonal":"Sword_Attack","1H_Melee_Attack_Stab":"Punch_Cross",
 "2H_Melee_Attack_Chop":"Sword_Attack","2H_Melee_Attack_Slice":"Sword_Attack","2H_Melee_Attack_Spin":"Sword_Attack","2H_Ranged_Shoot":"Pistol_Shoot",
 Spellcast_Shoot:"Spell_Simple_Shoot",Spellcast_Raise:"Spell_Simple_Enter",Spellcast_Long:"Spell_Simple_Shoot",Use_Item:"Interact",
 Hit_A:"Hit_Chest",Hit_B:"Hit_Head",Death_A:"Death01",Dodge_Backward:"Roll",Dodge_Left:"Roll",Block:"Punch_Enter",Block_Hit:"Punch_Enter",Cheer:"Punch_Enter",Victory:"Dance_Loop"};
const RN=n=>ALIAS[n]||n;
// os de la bibliothèque -> os VRoid, et os enfant servant à aligner la direction du membre
const BMAP=[["DEF-hips","J_Bip_C_Hips"],["DEF-spine001","J_Bip_C_Spine"],["DEF-spine002","J_Bip_C_Chest"],["DEF-spine003","J_Bip_C_UpperChest"],["DEF-neck","J_Bip_C_Neck"],["DEF-head","J_Bip_C_Head"],
 ["DEF-shoulderL","J_Bip_L_Shoulder"],["DEF-upper_armL","J_Bip_L_UpperArm","DEF-forearmL","J_Bip_L_LowerArm"],["DEF-forearmL","J_Bip_L_LowerArm","DEF-handL","J_Bip_L_Hand"],["DEF-handL","J_Bip_L_Hand"],
 ["DEF-shoulderR","J_Bip_R_Shoulder"],["DEF-upper_armR","J_Bip_R_UpperArm","DEF-forearmR","J_Bip_R_LowerArm"],["DEF-forearmR","J_Bip_R_LowerArm","DEF-handR","J_Bip_R_Hand"],["DEF-handR","J_Bip_R_Hand"],
 ["DEF-thighL","J_Bip_L_UpperLeg","DEF-shinL","J_Bip_L_LowerLeg"],["DEF-shinL","J_Bip_L_LowerLeg","DEF-footL","J_Bip_L_Foot"],["DEF-footL","J_Bip_L_Foot"],
 ["DEF-thighR","J_Bip_R_UpperLeg","DEF-shinR","J_Bip_R_LowerLeg"],["DEF-shinR","J_Bip_R_LowerLeg","DEF-footR","J_Bip_R_Foot"],["DEF-footR","J_Bip_R_Foot"]];
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

/* ---------- monde : village de nuit, direction « clair-obscur peint » ---------- */
const sway=[],fogs=[],rays=[],lanterns=[];
function mkTex(w,h,draw,rx,ry,lin){const c=document.createElement("canvas");c.width=w;c.height=h;draw(c.getContext("2d"),w,h);
  const t=new THREE.CanvasTexture(c);t.wrapS=t.wrapT=THREE.RepeatWrapping;t.repeat.set(rx||1,ry||1);if(!lin)t.encoding=THREE.sRGBEncoding;t.anisotropy=8;return t}
function blot(g,w,h,n,cols,r0,r1,a){for(let i=0;i<n;i++){g.globalAlpha=a*Math.random();g.fillStyle=cols[(Math.random()*cols.length)|0];g.beginPath();g.arc(Math.random()*w,Math.random()*h,R(r0,r1),0,7);g.fill()}g.globalAlpha=1}
function buildWorld(){
  scene.background=new THREE.Color(0x04040a);
  scene.fog=new THREE.FogExp2(0x101626,0.017);
  /* ciel peint : dégradé, nuages éclairés par la lune, lueur d'incendie à l'horizon */
  const sky=new THREE.Mesh(new THREE.SphereGeometry(190,32,16),new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,fog:false,uniforms:{t:{value:0}},
    vertexShader:"varying vec3 vP;void main(){vP=position;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}",
    fragmentShader:"varying vec3 vP;uniform float t;float h2(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}float n2(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h2(i),h2(i+vec2(1,0)),f.x),mix(h2(i+vec2(0,1)),h2(i+vec2(1,1)),f.x),f.y);}float fbm(vec2 p){float a=.5,s=0.;for(int i=0;i<5;i++){s+=a*n2(p);p*=2.03;a*=.5;}return s;}"+
      "void main(){vec3 d=normalize(vP);float h=d.y;vec3 top=vec3(.006,.010,.035);vec3 mid=vec3(.020,.050,.085);vec3 hor=vec3(.26,.085,.03);vec3 c=mix(hor,mid,smoothstep(-.03,.14,h));c=mix(c,top,smoothstep(.10,.6,h));"+
      "vec2 uv=d.xz/(abs(h)+.25)*1.6+vec2(t*.004,0.);float cl=smoothstep(.48,.85,fbm(uv))*smoothstep(-.02,.25,h);vec3 md=normalize(vec3(-58.,74.,-130.));float ml=pow(max(dot(d,md),0.),6.);"+
      "c=mix(c,vec3(.05,.07,.12)+vec3(.30,.36,.52)*ml+vec3(.20,.07,.02)*smoothstep(.3,0.,h),cl*.75);c+=vec3(.10,.13,.22)*pow(max(dot(d,md),0.),40.);gl_FragColor=vec4(c,1.);}"}));
  scene.add(sky);world.sky=sky;
  const sp=new Float32Array(1400*3);for(let i=0;i<1400;i++){const a=Math.random()*Math.PI*2,e=R(.1,1.5),r=178;sp[i*3]=Math.cos(a)*Math.cos(e)*r;sp[i*3+1]=Math.sin(e)*r;sp[i*3+2]=Math.sin(a)*Math.cos(e)*r}
  const sg=new THREE.BufferGeometry();sg.setAttribute("position",new THREE.BufferAttribute(sp,3));
  scene.add(new THREE.Points(sg,new THREE.PointsMaterial({color:0xcfd8ff,size:1.5,sizeAttenuation:false,fog:false,transparent:true,opacity:.8})));
  const glow=glowTex();
  const moon=new THREE.Mesh(new THREE.SphereGeometry(11,32,20),new THREE.MeshBasicMaterial({fog:false}));moon.material.color.setRGB(2.4,2.6,3.3);moon.position.set(-58,74,-130);scene.add(moon);
  const halo=new THREE.Mesh(new THREE.PlaneGeometry(120,120),new THREE.MeshBasicMaterial({map:glow,transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,opacity:.35,color:0x8fb0ff}));halo.position.copy(moon.position);halo.lookAt(0,5,0);scene.add(halo);
  /* montagnes en silhouette */
  const mt=mkTex(2048,256,(g,w,h)=>{for(const[col,base,amp]of[["#121a36",150,110],["#080d1c",190,70]]){g.fillStyle=col;g.beginPath();g.moveTo(0,h);let y=base;for(let x=0;x<=w;x+=16){y+=R(-amp*.13,amp*.13);y=Math.max(h-base-amp*.5,Math.min(h-20,y));const yy=x>w-200?y+(h-base*.6-y)*((x-(w-200))/200):y;g.lineTo(x,x===0?h-base*.6:yy)}g.lineTo(w,h);g.fill()}},2,1);
  const mts=new THREE.Mesh(new THREE.CylinderGeometry(172,172,74,48,1,true),new THREE.MeshBasicMaterial({map:mt,transparent:true,alphaTest:.05,side:THREE.BackSide,fog:false}));mts.position.y=30;scene.add(mts);
  /* la Flèche d'or : repère lointain, propre à ce monde */
  const tw=new THREE.Mesh(new THREE.CylinderGeometry(2.6,7,104,5),new THREE.MeshBasicMaterial({color:0x0a0e20,fog:false}));tw.position.set(44,52,-140);scene.add(tw);
  const slit=new THREE.Mesh(new THREE.PlaneGeometry(1.1,46),new THREE.MeshBasicMaterial({fog:false}));slit.material.color.setRGB(3.2,2.2,.7);slit.position.set(42.6,62,-135.6);slit.lookAt(0,40,0);scene.add(slit);
  const ringT=new THREE.Mesh(new THREE.TorusGeometry(11,.18,8,64),new THREE.MeshBasicMaterial({fog:false}));ringT.material.color.setRGB(2.6,1.8,.6);ringT.position.set(44,100,-140);ringT.rotation.set(1.25,.2,0);scene.add(ringT);world.ring=ringT;
  const tg=new THREE.Mesh(new THREE.PlaneGeometry(70,70),new THREE.MeshBasicMaterial({map:glow,transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,opacity:.3,color:0xffc060}));tg.position.set(43,84,-137);tg.lookAt(0,30,0);scene.add(tg);

  /* lumière : ombres profondes, contre-jour bleu de lune, flaques chaudes des feux */
  scene.add(new THREE.HemisphereLight(0x33427e,0x1a0e08,.17));
  const ml=new THREE.DirectionalLight(0x8fb0ff,.72);ml.position.set(-14,26,-22);ml.castShadow=true;
  ml.shadow.mapSize.set(2048,2048);const sc=ml.shadow.camera;sc.left=-24;sc.right=24;sc.top=24;sc.bottom=-24;sc.near=1;sc.far=90;ml.shadow.bias=-.0004;ml.shadow.normalBias=.03;scene.add(ml);scene.add(ml.target);
  Stage_moon=ml;
  const fill=new THREE.DirectionalLight(0xffb27a,.1);fill.position.set(7,7,12);scene.add(fill);

  /* textures peintes par le code */
  const stones=[];for(let j=0;j<10;j++)for(let i=0;i<10;i++)stones.push([(i+.5+R(-.22,.22))*51.2+(j%2?25:0),(j+.5+R(-.2,.2))*51.2,R(19,27),R(17,24),R(0,3.1),(Math.random()*4)|0]);
  const drawStones=(g,w,h,bump)=>{g.fillStyle=bump?"#202020":"#1c1917";g.fillRect(0,0,w,h);for(const[x,y,rx,ry,a,ci]of stones)for(const ox of[0,-w,w]){g.save();g.translate(x+ox,y);g.rotate(a*.2);
      if(bump){const gr=g.createRadialGradient(0,0,2,0,0,rx);gr.addColorStop(0,"#f0f0f0");gr.addColorStop(.75,"#b0b0b0");gr.addColorStop(1,"#303030");g.fillStyle=gr}else g.fillStyle=["#6a6055","#585049","#756a5b","#4c453f"][ci];
      g.beginPath();g.ellipse(0,0,rx,ry,0,0,7);g.fill();g.restore()}
    if(!bump){blot(g,w,h,260,["#2a2520","#8a7d6a","#3a4238"],4,26,.22)}};
  const tCob=mkTex(512,512,(g,w,h)=>drawStones(g,w,h,false),1,1),tCobB=mkTex(512,512,(g,w,h)=>drawStones(g,w,h,true),1,1,true);
  const cob=(rx,ry,color)=>{const a=tCob.clone(),b=tCobB.clone();a.needsUpdate=b.needsUpdate=true;a.repeat.set(rx,ry);b.repeat.set(rx,ry);return new THREE.MeshStandardMaterial({map:a,bumpMap:b,bumpScale:.025,roughness:.86,color:color||0xffffff})};
  const tPl=mkTex(512,512,(g,w,h)=>{g.fillStyle="#b3a288";g.fillRect(0,0,w,h);blot(g,w,h,520,["#9c8d74","#c6b89e","#857660","#a89a84"],6,44,.26);
    for(let i=0;i<70;i++){g.globalAlpha=R(.03,.1);g.fillStyle="#3a3026";const x=Math.random()*w;g.fillRect(x,R(0,h*.5),R(1,5),R(60,h))}
    g.globalAlpha=1;const gr=g.createLinearGradient(0,h*.6,0,h);gr.addColorStop(0,"rgba(40,32,24,0)");gr.addColorStop(1,"rgba(40,32,24,.55)");g.fillStyle=gr;g.fillRect(0,0,w,h);
    g.strokeStyle="rgba(50,40,30,.5)";g.lineWidth=1;for(let i=0;i<14;i++){g.beginPath();let x=Math.random()*w,y=Math.random()*h;g.moveTo(x,y);for(let k=0;k<6;k++){x+=R(-18,18);y+=R(6,26);g.lineTo(x,y)}g.stroke()}},1,1);
  const tRoof=mkTex(512,512,(g,w,h)=>{g.fillStyle="#241a1c";g.fillRect(0,0,w,h);const rows=14,cols=12,tw2=w/cols,th=h/rows;
    for(let j=0;j<rows;j++)for(let i=-1;i<cols;i++){const x=i*tw2+(j%2?tw2/2:0),y=j*th;g.fillStyle=["#5e3b34","#4c302c","#6e473a","#3f2b30","#553a3e"][(Math.random()*5)|0];g.beginPath();g.moveTo(x+2,y);g.lineTo(x+tw2-2,y);g.lineTo(x+tw2-2,y+th*.7);g.quadraticCurveTo(x+tw2/2,y+th*1.25,x+2,y+th*.7);g.fill();
      g.fillStyle="rgba(0,0,0,.28)";g.fillRect(x+2,y,tw2-4,th*.16)}blot(g,w,h,200,["#1c2a24","#2a1a18"],5,26,.25)},3,2);
  const tWood=mkTex(256,256,(g,w,h)=>{g.fillStyle="#34241a";g.fillRect(0,0,w,h);for(let i=0;i<160;i++){g.globalAlpha=R(.1,.4);g.strokeStyle=Math.random()<.5?"#1e140e":"#5a4230";g.lineWidth=R(.6,2.2);const x=Math.random()*w;g.beginPath();g.moveTo(x,0);g.bezierCurveTo(x+R(-8,8),h*.3,x+R(-8,8),h*.7,x+R(-5,5),h);g.stroke()}g.globalAlpha=1},1,2);
  const tDirt=mkTex(512,512,(g,w,h)=>{g.fillStyle="#211c17";g.fillRect(0,0,w,h);blot(g,w,h,900,["#2c251e","#17130f","#243024","#1b2a22","#33291f"],6,40,.3)},36,36);
  const mGround=new THREE.MeshStandardMaterial({map:tDirt,roughness:1});
  const mStone=cob(2,1,0xb0a69a),mBeam=new THREE.MeshStandardMaterial({map:tWood,roughness:.9,color:0x9a8a7a}),mWood=new THREE.MeshStandardMaterial({map:tWood,roughness:.85,color:0xd0b090});
  const mWall=[0xf2e6d2,0xd9c8ae,0xe6d2bc,0xc9bca8].map(c=>new THREE.MeshStandardMaterial({map:tPl,roughness:.95,color:c}));
  const mRoof=[0xffffff,0xb8c0e0,0xe0c0a0].map(c=>new THREE.MeshStandardMaterial({map:tRoof,roughness:.85,color:c})),mRoofBurnt=new THREE.MeshStandardMaterial({map:tRoof,roughness:1,color:0x5a4a48});
  const mWin=new THREE.MeshBasicMaterial({fog:false});mWin.color.setRGB(2.9,1.55,.5);
  const mWinFire=new THREE.MeshBasicMaterial({fog:false});mWinFire.color.setRGB(3.6,1.2,.3);
  const mWinOff=new THREE.MeshStandardMaterial({color:0x0a0e18,roughness:.25,metalness:.6});
  const mIron=new THREE.MeshStandardMaterial({color:0x1c1a1a,roughness:.55,metalness:.7});

  const ground=new THREE.Mesh(new THREE.PlaneGeometry(300,300),mGround);ground.rotation.x=-Math.PI/2;ground.receiveShadow=true;scene.add(ground);
  const plaza=new THREE.Mesh(new THREE.CircleGeometry(11.8,72),cob(15,15,0xa39a90));plaza.rotation.x=-Math.PI/2;plaza.position.y=.015;plaza.receiveShadow=true;scene.add(plaza);
  const curb=new THREE.Mesh(new THREE.TorusGeometry(11.9,.16,6,72),cob(40,1,0x8a8078));curb.rotation.x=-Math.PI/2;curb.position.y=.05;curb.receiveShadow=true;scene.add(curb);
  const road=new THREE.Mesh(new THREE.PlaneGeometry(6.4,60),cob(4,36,0xa39a90));road.rotation.x=-Math.PI/2;road.position.set(0,.012,41);road.receiveShadow=true;scene.add(road);

  const box=(g,w,h,d,m,x,y,z,rx,ry,rz)=>{const o=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),m);o.position.set(x,y,z);o.rotation.set(rx||0,ry||0,rz||0);o.castShadow=o.receiveShadow=true;g.add(o);return o};
  function win(g,x,y,z,s,mat){const r=s<0?Math.PI:0;
    box(g,.78,.98,.07,mBeam,x,y,z);const p=new THREE.Mesh(new THREE.PlaneGeometry(.6,.8),mat);p.position.set(x,y,z+s*.045);p.rotation.y=r;g.add(p);
    box(g,.04,.8,.03,mBeam,x,y,z+s*.05);box(g,.6,.04,.03,mBeam,x,y+.05,z+s*.05);box(g,.9,.07,.16,mStone,x,y-.52,z+s*.06);
    for(const k of[-1,1])box(g,.3,.92,.04,mWood,x+k*.55,y,z+s*.1,0,k*s*.5,0)}
  function house(x,z,ry,w,d,h,burn){
    const g=new THREE.Group(),wm=mWall[(Math.random()*mWall.length)|0],two=h>3.95,W=two?w+.4:w,D=two?d+.4:d,rm=burn?mRoofBurnt:mRoof[(Math.random()*mRoof.length)|0];
    box(g,w+.2,.55,d+.2,mStone,0,.275,0);box(g,w,h-.5,d,wm,0,.5+(h-.5)/2,0);
    if(two)box(g,W,h*.44,D,wm,0,h-h*.22,0);
    for(const s of[1,-1]){const zf=s*(D/2+.035),zg=s*(d/2+.035);
      for(const fx of[-.5,-.17,.17,.5])box(g,.14,two?h*.44:h-.5,.09,mBeam,fx*(W-.14),two?h-h*.22:.5+(h-.5)/2,zf);
      for(const fy of(two?[h*.56,h-.07]:[.62,h-.07]))box(g,W+.06,.14,.1,mBeam,0,fy,zf);
      box(g,.1,h*.36,.08,mBeam,-.335*W,h*.79,zf,0,0,.6);box(g,.1,h*.36,.08,mBeam,.335*W,h*.79,zf,0,0,-.6);
      if(two)for(const fx of[-.5,.5])box(g,.14,h*.56-.5,.09,mBeam,fx*(w-.14),.5+(h*.56-.5)/2,zg)}
    for(const s of[1,-1]){const xf=s*(W/2+.035);for(const fz of[-.5,0,.5])box(g,.09,two?h*.44:h-.5,.14,mBeam,xf,two?h-h*.22:.5+(h-.5)/2,fz*(D-.14));box(g,.1,.14,D+.06,mBeam,xf,h-.07,0)}
    // toit à deux pans, pignons, cheminée
    const run=D/2+.5,rh=run*R(.95,1.2),a=Math.atan2(rh,run),sw=Math.hypot(run,rh)+.1;
    for(const s of[1,-1]){const sl=box(g,W+.9,.16,sw,rm,0,h+rh/2,s*run/2,s*a,0,0);sl.material=rm}
    box(g,W+1,.2,.2,mBeam,0,h+rh+.02,0);
    for(const s of[1,-1]){const sh=new THREE.Shape();sh.moveTo(-D/2,0);sh.lineTo(D/2,0);sh.lineTo(0,rh-.12);const t=new THREE.Mesh(new THREE.ShapeGeometry(sh),wm);t.material=wm.clone();t.material.side=THREE.DoubleSide;t.rotation.y=Math.PI/2;t.position.set(s*(W/2-.02),h,0);t.castShadow=true;g.add(t);
      box(g,.1,rh-.1,.12,mBeam,s*(W/2+.03),h+(rh-.1)/2,0);box(g,.1,.12,D*.55,mBeam,s*(W/2+.03),h+rh*.42,0)}
    const cx=W*.27,cz=-D*.16;box(g,.62,rh*.9+1,.62,mStone,cx,h+rh*.55,cz);box(g,.78,.14,.78,mStone,cx,h+rh+.5,cz);
    // porte, fenêtres
    const zd=d/2+.04;box(g,1.02,1.95,.09,mWood,0,.55+.975,zd);box(g,1.3,.16,.14,mBeam,0,2.6,zd);box(g,.12,2.05,.14,mBeam,-.6,1.55,zd);box(g,.12,2.05,.14,mBeam,.6,1.55,zd);box(g,1.5,.16,.6,mStone,0,.36,zd+.3);
    const kn=new THREE.Mesh(new THREE.SphereGeometry(.05,8,6),mIron);kn.position.set(.34,1.5,zd+.07);g.add(kn);
    const lit=()=>burn?mWinFire:(Math.random()<.72?mWin:mWinOff);
    if(two){for(const fx of[-.3,.3])win(g,fx*w,1.75,d/2+.04,1,lit());for(const fx of[-.31,0,.31])win(g,fx*W,h*.79,D/2+.04,1,lit());for(const fx of[-.3,.3])win(g,fx*W,h*.79,-D/2-.04,-1,lit())}
    else{for(const fx of[-.31,.31])win(g,fx*w,h*.5+.35,d/2+.04,1,lit());win(g,0,h*.5+.35,-d/2-.04,-1,lit())}
    g.position.set(x,0,z);g.rotation.y=ry;scene.add(g);
    const top=new V3(cx,h+rh+.7,cz).applyAxisAngle(new V3(0,1,0),ry).add(g.position);
    if(burn){const p=new V3(R(-W*.2,W*.2),h+rh*.6,0).applyAxisAngle(new V3(0,1,0),ry).add(g.position);emitters.push({p,r:W*.3,rate:burn*50,size:burn*1.3,up:3.4,smoke:.55})}
    else if(Math.random()<.7)emitters.push({kind:"smoke",p:top,rate:3});
    return g}
  // fond derrière les ennemis
  house(-13,-15,.25,6,5,4.3,1.5);house(-4.6,-17.4,-.08,5.5,5,3.7,0);house(4.6,-16.8,.12,6,5.5,4.7,1.25);house(13.5,-14,-.3,5.5,5,3.8,0);
  house(-21,-26,.2,7,6,5,0);house(-7,-28,0,6,6,5.4,1.1);house(9,-29,-.1,7,6,5,0);house(23,-25,-.25,6,6,4.5,.9);
  // côtés de la place
  house(-17.4,-5,Math.PI/2+.1,5.5,5,4.1,0);house(-17.8,5.2,Math.PI/2-.08,6,5,3.7,.9);house(17.4,-4,-Math.PI/2+.1,5.5,5,4.3,1);house(17.8,6.2,-Math.PI/2-.1,6,5,3.6,0);
  // rue derrière les héros
  for(let i=0;i<5;i++){const z=16.5+i*8.6;house(-8.2-R(0,1.2),z,Math.PI/2+R(-.08,.08),5.5,5,i%2?4.4:3.7,i===2?1:0);house(8.2+R(0,1.2),z+R(-1.2,1.2),-Math.PI/2+R(-.08,.08),5.5,5,i%2?3.7:4.5,i===4?.9:0)}

  /* fontaine et statue : accent sarcelle face à l'orange des feux */
  const f=new THREE.Group();const basin=new THREE.Mesh(new THREE.CylinderGeometry(2.3,2.5,.62,28),cob(6,1,0xb8b0a6));basin.position.y=.31;basin.castShadow=basin.receiveShadow=true;f.add(basin);
  const water=new THREE.Mesh(new THREE.CircleGeometry(2.05,28),new THREE.MeshBasicMaterial());water.material.color.setRGB(.10,.55,.62);water.rotation.x=-Math.PI/2;water.position.y=.63;f.add(water);
  const pil=new THREE.Mesh(new THREE.CylinderGeometry(.34,.5,1.7,10),mStone);pil.position.y=1.45;pil.castShadow=true;f.add(pil);
  const robe=new THREE.Mesh(new THREE.ConeGeometry(.6,1.9,10),mStone);robe.position.y=3.2;robe.castShadow=true;f.add(robe);
  const hd=new THREE.Mesh(new THREE.SphereGeometry(.24,12,10),mStone);hd.position.y=4.32;hd.castShadow=true;f.add(hd);
  const arm=box(f,.14,.95,.14,mStone,.42,4.25,0,0,0,-.55);
  const orb=new THREE.Mesh(new THREE.SphereGeometry(.17,16,12),new THREE.MeshBasicMaterial({fog:false}));orb.material.color.setRGB(.5,2.6,2.9);orb.position.set(.72,4.78,0);f.add(orb);
  const og=new THREE.Mesh(new THREE.PlaneGeometry(3.4,3.4),new THREE.MeshBasicMaterial({map:glow,transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,opacity:.45,color:0x40d0e0}));og.position.copy(orb.position);f.add(og);world.orbGlow=og;
  f.position.set(0,0,-9.4);scene.add(f);world.fountain=new V3(.72,4.78,-9.4);

  /* guirlandes de lanternes */
  function garland(a,b,n,sag){const pts=[];for(let i=0;i<=16;i++){const t=i/16;pts.push(new V3(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t-Math.sin(t*Math.PI)*sag,a[2]+(b[2]-a[2])*t))}
    const tube=new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts),24,.018,4),mIron);scene.add(tube);
    for(let i=1;i<=n;i++){const t=i/(n+1),p=new V3(a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t-Math.sin(t*Math.PI)*sag-.2,a[2]+(b[2]-a[2])*t);
      const teal=Math.random()<.22,l=new THREE.Mesh(new THREE.SphereGeometry(.12,10,8),new THREE.MeshBasicMaterial({fog:false}));teal?l.material.color.setRGB(.5,2.3,2.5):l.material.color.setRGB(2.8,1.6,.55);l.position.copy(p);scene.add(l);
      const cap=new THREE.Mesh(new THREE.ConeGeometry(.1,.1,6),mIron);cap.position.set(p.x,p.y+.14,p.z);scene.add(cap);lanterns.push({l,y:p.y,ph:Math.random()*6})}}
  garland([-10.6,4.5,-12.8],[-4.4,4.2,-14.8],5,.5);garland([-4.4,4.2,-14.8],[4.6,4.7,-14.2],7,.7);garland([4.6,4.7,-14.2],[12.2,4.3,-11.8],5,.5);
  garland([-15,4.2,-3],[-6.2,2.2,-6.4],4,.4);garland([15,4.3,-2.5],[6.4,2.2,-6.0],4,.4);
  for(const z of[18,26.5,35,43.5])garland([-5.6,4.1,z],[5.6,4.1,z+R(-1,1)],6,.6);

  /* arbres : feuillage à facettes, quelques cimes pourpres */
  const mTrunk=new THREE.MeshStandardMaterial({map:tWood,roughness:1,color:0x6a5a4c});
  const mLeaf=[0x1d3a38,0x24443a,0x17302e,0x2a4a44,0x6e2430,0x7a3a22].map(c=>new THREE.MeshStandardMaterial({color:c,roughness:.9,flatShading:true}));
  function tree(x,z,s){const g=new THREE.Group(),tr=new THREE.Mesh(new THREE.CylinderGeometry(.14*s,.3*s,2.6*s,7),mTrunk);tr.position.y=1.3*s;tr.rotation.z=R(-.09,.09);tr.castShadow=true;g.add(tr);
    const red=Math.random()<.18,n=4+((Math.random()*3)|0),sd=Math.random()*9;
    for(let i=0;i<n;i++){const r=R(.85,1.5)*s,geo=new THREE.IcosahedronGeometry(r,1),p=geo.attributes.position;
      for(let k=0;k<p.count;k++){const X=p.getX(k),Y=p.getY(k),Z=p.getZ(k),q=1+.2*Math.sin(X*3.1+Y*2.3+Z*4.7+sd+i);p.setXYZ(k,X*q,Y*q*.85,Z*q)}geo.computeVertexNormals();
      const lf=new THREE.Mesh(geo,mLeaf[red?4+((Math.random()*2)|0):(Math.random()*4)|0]);lf.position.set(R(-.95,.95)*s,(2.5+R(.1,1.7))*s,R(-.95,.95)*s);lf.castShadow=true;g.add(lf)}
    g.position.set(x,0,z);scene.add(g);sway.push({g,ph:Math.random()*6})}
  [[-23,-12],[-25,2],[-24,12],[23,-13],[25,1],[24,13],[-15,-22],[15,-22],[-2,-23],[-30,-20],[30,-19],[-13,13],[13,13.5],[-14,24],[14.5,30],[-15,40],[15,46],[-22,-34],[2,-36],[20,-35],[-34,-6],[34,-8],[-12.6,-9.6],[12.8,-9.2]].forEach(([x,z])=>tree(x,z,R(1.1,1.7)));
  const mPine=new THREE.MeshStandardMaterial({color:0x0e1e1c,roughness:1,flatShading:true});
  for(let i=0;i<90;i++){const a=Math.random()*Math.PI*2,r=R(40,78),x=Math.cos(a)*r,z=Math.sin(a)*r;if(Math.abs(x)<9&&z>0)continue;const h=R(6,12);
    for(let k=0;k<3;k++){const c=new THREE.Mesh(new THREE.ConeGeometry((2.4-k*.6)*h/9,h*.5,7),mPine);c.position.set(x,h*.3+k*h*.26+1,z);scene.add(c)}
    const tr=new THREE.Mesh(new THREE.CylinderGeometry(.2,.3,1.6,6),mTrunk);tr.position.set(x,.8,z);scene.add(tr)}

  /* herbe, fleurs lumineuses */
  const tBlade=mkTex(64,64,(g,w,h)=>{g.clearRect(0,0,w,h);for(let i=0;i<9;i++){const x=R(6,58),t=R(.5,1);g.fillStyle="rgba(255,255,255,"+R(.75,1)+")";g.beginPath();g.moveTo(x-3,h);g.quadraticCurveTo(x+R(-6,6),h*(1-t*.6),x+R(-9,9),h*(1-t));g.quadraticCurveTo(x+R(-3,3),h*(1-t*.5),x+3,h);g.fill()}},1,1);
  const gg=new THREE.PlaneGeometry(.8,.6);gg.translate(0,.3,0);
  const NG=5200,grass=new THREE.InstancedMesh(gg,new THREE.MeshLambertMaterial({map:tBlade,alphaTest:.45,side:THREE.DoubleSide,emissive:0x0c1a16}),NG),M=new THREE.Matrix4(),Qt=new THREE.Quaternion(),Sv=new V3(),Pv=new V3(),C=new THREE.Color();
  const spots=[];
  for(let i=0;i<NG;i++){let x,z;if(i%5===0){x=(Math.random()<.5?-1:1)*R(3.4,6.4);z=R(11,60)}else{const a=Math.random()*Math.PI*2,r=R(12.2,34);x=Math.cos(a)*r;z=Math.sin(a)*r;if(Math.abs(x)<3.3&&z>0){x+=x<0?-3.5:3.5}}
    Qt.setFromAxisAngle(new V3(0,1,0),Math.random()*Math.PI);const s=R(.7,1.6);Sv.set(s,s*R(.8,1.4),s);Pv.set(x,0,z);M.compose(Pv,Qt,Sv);grass.setMatrixAt(i,M);
    C.setHSL(R(.36,.47),R(.3,.5),R(.1,.2));grass.setColorAt(i,C);if(i%9===0)spots.push([x,z])}
  grass.receiveShadow=true;scene.add(grass);world.spots=spots;
  const NF=520,fl=new THREE.InstancedMesh(new THREE.SphereGeometry(.045,6,5),new THREE.MeshBasicMaterial({fog:false}),NF);fl.material.color.setRGB(2.1,2.1,2.1);
  for(let i=0;i<NF;i++){const s=spots[(Math.random()*spots.length)|0];Pv.set(s[0]+R(-.6,.6),R(.22,.5),s[1]+R(-.6,.6));Qt.identity();Sv.setScalar(R(.6,1.3));M.compose(Pv,Qt,Sv);fl.setMatrixAt(i,M);
    const k=Math.random();C.setRGB(k<.5?1:k<.8?.35:.95,k<.5?.72:k<.8?.95:.95,k<.5?.25:k<.8?1:.9);fl.setColorAt(i,C)}
  scene.add(fl);

  /* tonneaux, caisses, barrières, charrette */
  [[-9,-8],[-9.8,-7.2],[10,-7.5],[12.6,2],[-12.6,1.5],[-12.1,2.6],[9.6,9],[-10,10],[10.6,-6.6]].forEach(([x,z],i)=>{
    const m=i%2?new THREE.Mesh(new THREE.CylinderGeometry(.42,.38,1,12),mWood):new THREE.Mesh(new THREE.BoxGeometry(.9,.9,.9),mWood);
    m.position.set(x,i%2?.5:.45,z);m.rotation.y=R(0,1.5);m.castShadow=m.receiveShadow=true;scene.add(m);
    if(i%2)for(const y of[.25,.75]){const h2=new THREE.Mesh(new THREE.TorusGeometry(.42,.025,5,14),mIron);h2.rotation.x=Math.PI/2;h2.position.set(x,y,z);scene.add(h2)}});
  const fen=new THREE.Group();for(let i=0;i<11;i++)box(fen,.13,R(.9,1.15),.13,mBeam,-13+i*.86,.5,10.5,0,R(0,.5),R(-.06,.06));box(fen,8.8,.09,.08,mBeam,-8.7,.78,10.5);box(fen,8.8,.09,.08,mBeam,-8.7,.42,10.5);scene.add(fen);
  const cart=new THREE.Group();box(cart,2.2,.14,1.2,mWood,0,.75,0);box(cart,2.2,.5,.08,mWood,0,1.05,.6);box(cart,2.2,.5,.08,mWood,0,1.05,-.6);box(cart,.08,.5,1.2,mWood,-1.1,1.05,0);box(cart,1.6,.08,.08,mBeam,1.8,.72,.3,0,0,-.12);box(cart,1.6,.08,.08,mBeam,1.8,.72,-.3,0,0,-.12);
  for(const s of[1,-1]){const wh=new THREE.Mesh(new THREE.TorusGeometry(.48,.07,6,18),mBeam);wh.position.set(-.3,.5,s*.72);wh.castShadow=true;cart.add(wh);for(let k=0;k<4;k++)box(cart,.9,.05,.05,mBeam,-.3,.5,s*.72,0,0,k*Math.PI/4)}
  cart.position.set(11.4,0,5.2);cart.rotation.y=.7;scene.add(cart);

  /* braseros : éclairent les combattants */
  [[-6.2,-6.4],[6.4,-6.0],[-7.5,6.5],[7.6,7]].forEach(([x,z],i)=>{
    const st=new THREE.Mesh(new THREE.CylinderGeometry(.07,.15,1.5,6),mIron);st.position.set(x,.75,z);st.castShadow=true;scene.add(st);
    for(let k=0;k<3;k++){const lg=new THREE.Mesh(new THREE.CylinderGeometry(.03,.03,.7,5),mIron);lg.position.set(x+Math.cos(k*2.1)*.22,.3,z+Math.sin(k*2.1)*.22);lg.rotation.set(Math.sin(k*2.1)*.5,0,-Math.cos(k*2.1)*.5);scene.add(lg)}
    const bw=new THREE.Mesh(new THREE.CylinderGeometry(.44,.22,.34,12,1,true),mIron);bw.material.side=THREE.DoubleSide;bw.position.set(x,1.62,z);scene.add(bw);
    emitters.push({p:new V3(x,1.8,z),r:.2,rate:28,size:.5,up:1.9,smoke:.12});
    if(i<2){const l=new THREE.PointLight(0xff8a3a,1.5,24,1.5);l.position.set(x,2.5,z);scene.add(l);fireLights.push({l,b:1.5})}});
  const big=new THREE.PointLight(0xff6a2a,1.3,55,1.3);big.position.set(3,9,-18);scene.add(big);fireLights.push({l:big,b:1.3});
  for(let i=0;i<3;i++){const l=new THREE.PointLight(0xffffff,0,14,1.6);l.position.set(0,-50,0);scene.add(l);fxLights.push({l,busy:false})}

  /* brume en couches et rayons de lune */
  const tFog=mkTex(512,128,(g,w,h)=>{g.clearRect(0,0,w,h);for(let i=0;i<70;i++){const x=Math.random()*w,y=R(h*.3,h*.8),r=R(26,70);for(const ox of[0,-w,w]){const gr=g.createRadialGradient(x+ox,y,0,x+ox,y,r);gr.addColorStop(0,"rgba(255,255,255,"+R(.08,.22)+")");gr.addColorStop(1,"rgba(255,255,255,0)");g.fillStyle=gr;g.fillRect(x+ox-r,y-r,r*2,r*2)}}},1,1);
  [[0,2.0,-11.5,0,54,7,0x6f8fd8,.34],[0,3.2,-21,0,80,11,0x5a78c8,.4],[0,5,-33,0,110,16,0x4a68b8,.45],[-21,2.6,0,Math.PI/2,60,9,0x6f8fd8,.3],[21,2.6,0,-Math.PI/2,60,9,0x6f8fd8,.3],[0,2.4,22,Math.PI,60,9,0x6f8fd8,.3],[0,1.1,-4,0,34,3.2,0xff9a5a,.16]].forEach(([x,y,z,ry,w,h,c,o],i)=>{
    const t=tFog.clone();t.needsUpdate=true;t.repeat.set(1.5,1);const m=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({map:t,transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,opacity:o,color:c,side:THREE.DoubleSide}));
    m.position.set(x,y,z);m.rotation.y=ry;m.renderOrder=3;scene.add(m);fogs.push({m,t,sp:.006+i*.002})});
  const tRay=mkTex(64,256,(g,w,h)=>{const gr=g.createLinearGradient(0,0,0,h);gr.addColorStop(0,"rgba(255,255,255,.9)");gr.addColorStop(1,"rgba(255,255,255,0)");g.fillStyle=gr;g.fillRect(0,0,w,h);
    const gx=g.createLinearGradient(0,0,w,0);gx.addColorStop(0,"rgba(0,0,0,1)");gx.addColorStop(.5,"rgba(0,0,0,0)");gx.addColorStop(1,"rgba(0,0,0,1)");g.globalCompositeOperation="destination-out";g.fillStyle=gx;g.fillRect(0,0,w,h)},1,1);
  [[-11,-10,3.2],[-5.5,-13,4.4],[1,-12,3],[6.5,-14.5,5],[-15.5,-6,3.6],[11.5,-11,3.4]].forEach(([x,z,w],i)=>{
    const m=new THREE.Mesh(new THREE.PlaneGeometry(w,34),new THREE.MeshBasicMaterial({map:tRay,transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,fog:false,opacity:.1,color:0x9db8ff,side:THREE.DoubleSide}));
    m.position.set(x-4,13.5,z-5);m.rotation.set(-.32,.25,.42);m.renderOrder=3;scene.add(m);rays.push({m,ph:i*1.7})});

  const tex=glow;
  fxAdd=new PSys(3200,tex,THREE.AdditiveBlending);scene.add(fxAdd.pts);
  fxSmoke=new PSys(520,tex,THREE.NormalBlending);fxSmoke.pts.renderOrder=4;scene.add(fxSmoke.pts);
}
const world={};
function animWorld(dt){
  if(world.sky)world.sky.material.uniforms.t.value=elapsed;
  for(const s of sway){s.g.rotation.z=Math.sin(elapsed*.6+s.ph)*.018;s.g.rotation.x=Math.cos(elapsed*.45+s.ph)*.014}
  for(const f of fogs){f.t.offset.x+=dt*f.sp}
  for(const r of rays)r.m.material.opacity=.07+.05*Math.sin(elapsed*.5+r.ph);
  for(const l of lanterns)l.l.position.y=l.y+Math.sin(elapsed*1.3+l.ph)*.03;
  if(world.ring)world.ring.rotation.z+=dt*.05;
  if(world.orbGlow){world.orbGlow.lookAt(camera.position);world.orbGlow.material.opacity=.38+.12*Math.sin(elapsed*2)}
  if(quality===0)return;
  // pétales lumineux, lucioles, étincelles de la fontaine
  if(Math.random()<dt*14)fxAdd.emit(R(-18,18),R(4,8),R(-16,10),R(-.5,.2),R(-.55,-.25),R(.1,.5),1.5,.62,.74,R(6,10),.1,.07,.75,0,.02);
  if(world.spots&&Math.random()<dt*9){const s=world.spots[(Math.random()*world.spots.length)|0];fxAdd.emit(s[0],R(.4,1.6),s[1],R(-.25,.25),R(-.05,.2),R(-.25,.25),.9,1.9,.6,R(2.5,5),.09,.02,1,0,.1)}
  if(world.fountain&&Math.random()<dt*10){const p=world.fountain;fxAdd.emit(p.x+R(-.1,.1),p.y,p.z+R(-.1,.1),R(-.3,.3),R(.4,1.1),R(-.3,.3),.4,2.0,2.3,R(.8,1.8),.14,.02,1,0,.4)}
}
let Stage_moon=null;
function updateEmitters(dt){
  animWorld(dt);
  const dens=quality===0?.45:quality===1?.75:1;
  for(const e of emitters){
    if(e.kind==="smoke"){e.acc=(e.acc||0)+e.rate*dt;while(e.acc>=1){e.acc--;fxSmoke.emit(e.p.x,e.p.y,e.p.z,R(-.1,.4),R(.5,1),R(-.15,.15),.10,.10,.115,R(3,5.5),.5,2.8,.28,.03,.1)}continue}
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
const info={},modelClips={};
function load(onP){
  const L=new THREE.GLTFLoader();let done=0;
  // les modèles sont stockés en base64 dans des fichiers .json (format accepté partout)
  return Promise.all(NAMES.map(n=>fetch("assets/"+n+".json").then(r=>r.json()).then(j=>new Promise((res,rej)=>{
    const bin=atob(j.b64),u=new Uint8Array(bin.length);for(let i=0;i<bin.length;i++)u[i]=bin.charCodeAt(i);
    L.parse(u.buffer,"",g=>{models[n]=g.scene;g.scene.traverse(o=>{if(o.isMesh&&!o.geometry.attributes.normal)o.geometry.computeVertexNormals()});if(n==="Anims")models._src=g.animations;done++;onP&&onP(done/NAMES.length);res()},rej)})))).then(()=>{
    bake();ready=true})}
/* Report des animations sur le squelette VRoid, une fois pour toutes (voir tools/retarget-test.html). */
function bake(){
  const S=models.Anims,T=models[REF],Q=()=>new THREE.Quaternion(),P=()=>new V3();
  S.updateMatrixWorld(true);T.updateMatrixWorld(true);
  const mix=new THREE.AnimationMixer(S),tp=models._src.find(c=>c.name==="A_TPose");
  if(tp){mix.clipAction(tp).play();mix.setTime(0);S.updateMatrixWorld(true)}
  const pairs=[];
  for(const [a,b,ac,bc] of BMAP){const sb=S.getObjectByName(a),t=T.getObjectByName(b);if(!sb||!t)continue;
    const C=Q();
    if(ac){const sc=S.getObjectByName(ac),tc=T.getObjectByName(bc);
      const vs=sc.getWorldPosition(P()).sub(sb.getWorldPosition(P())).normalize();vs.set(-vs.x,vs.y,-vs.z);
      const vt=tc.getWorldPosition(P()).sub(t.getWorldPosition(P())).normalize();C.setFromUnitVectors(vt,vs)}
    pairs.push({sb,t,name:b,C,rs:sb.getWorldQuaternion(Q()),rt:t.getWorldQuaternion(Q()),rest:t.quaternion.clone(),vals:null})}
  const sh=S.getObjectByName("DEF-hips"),th=T.getObjectByName("J_Bip_C_Hips"),shRest=sh.position.clone(),thRest=th.position.clone();
  const ratio=th.getWorldPosition(P()).y/Math.max(.01,sh.getWorldPosition(P()).y);
  mix.stopAllAction();
  const d=Q(),q=Q(),pw=Q(),out={};
  for(const clip of models._src){
    if(clip.name==="A_TPose")continue;
    const m2=new THREE.AnimationMixer(S);m2.clipAction(clip).play();
    const n=Math.max(2,Math.ceil(clip.duration*30)+1),times=new Float32Array(n),hp=new Float32Array(n*3);
    for(const p of pairs)p.vals=new Float32Array(n*4);
    for(let i=0;i<n;i++){
      const t=Math.min(clip.duration-1e-4,i/30);times[i]=i/(n-1)*clip.duration;m2.setTime(t);S.updateMatrixWorld(true);
      for(const p of pairs){
        d.copy(p.sb.getWorldQuaternion(q)).multiply(q.copy(p.rs).invert());d.set(-d.x,d.y,-d.z,d.w);
        const tw=d.multiply(p.C).multiply(p.rt);
        p.t.parent.updateWorldMatrix(true,false);p.t.parent.getWorldQuaternion(pw);
        p.t.quaternion.copy(pw.invert().multiply(tw));p.t.updateMatrixWorld(true);
        p.vals.set([p.t.quaternion.x,p.t.quaternion.y,p.t.quaternion.z,p.t.quaternion.w],i*4)}
      hp[i*3]=-(sh.position.x-shRest.x)*ratio;hp[i*3+1]=(sh.position.y-shRest.y)*ratio;hp[i*3+2]=-(sh.position.z-shRest.z)*ratio}
    m2.stopAllAction();
    out[clip.name]={dur:clip.duration,times,hp,tracks:pairs.map(p=>new THREE.QuaternionKeyframeTrack(p.name+".quaternion",times,p.vals))}}
  for(const p of pairs)p.t.quaternion.copy(p.rest);th.position.copy(thRest);T.updateMatrixWorld(true);
  // un jeu de clips par modèle : seule la hauteur du bassin change
  const refHip=thRest.y;
  for(const n of NAMES){if(n==="Anims")continue;const M=models[n];M.updateMatrixWorld(true);
    const box=new THREE.Box3().setFromObject(M),h=Math.max(.5,box.max.y-box.min.y),hip=M.getObjectByName("J_Bip_C_Hips"),hr=hip?hip.position.clone():new V3(),k=hip?hr.y/refHip:1;
    info[n]={scale:TALL/h};modelClips[n]={};
    for(const c in out){const o=out[c],v=new Float32Array(o.hp.length);
      for(let i=0;i<v.length;i+=3){v[i]=hr.x+o.hp[i]*k;v[i+1]=hr.y+o.hp[i+1]*k;v[i+2]=hr.z+o.hp[i+2]*k}
      modelClips[n][c]=new THREE.AnimationClip(c,o.dur,o.tracks.concat([new THREE.VectorKeyframeTrack("J_Bip_C_Hips.position",o.times,v)]))}}
  for(const c in out)clips[c]={duration:out[c].dur};
}

/* ---------- acteurs ---------- */
function weapon(kind,orbCol){
  const g=new THREE.Group(),steel=new THREE.MeshStandardMaterial({color:0xcfd6e2,roughness:.3,metalness:.85}),wood=new THREE.MeshStandardMaterial({color:0x5a3d28,roughness:.9});
  if(kind==="sword"||kind==="greatsword"){const L=kind==="sword"?.85:1.25,w=kind==="sword"?.05:.085;
    const b=new THREE.Mesh(new THREE.BoxGeometry(.018,w,L),steel);b.position.z=-(L/2+.08);b.castShadow=true;g.add(b);
    const gd=new THREE.Mesh(new THREE.BoxGeometry(.03,.2,.03),wood);gd.position.z=-.08;g.add(gd);
    const h=new THREE.Mesh(new THREE.CylinderGeometry(.018,.018,.16,6),wood);h.rotation.x=Math.PI/2;g.add(h)}
  if(kind==="staff"){const st=new THREE.Mesh(new THREE.CylinderGeometry(.018,.022,1.5,6),wood);st.rotation.x=Math.PI/2;st.position.z=-.25;st.castShadow=true;g.add(st);
    const o=new THREE.Mesh(new THREE.SphereGeometry(.075,12,8),new THREE.MeshBasicMaterial());const c=col(orbCol||0xfff2b0);o.material.color.setRGB(c.r*3,c.g*3,c.b*3);o.position.z=-1.03;g.add(o)}
  return g}
function spawn(id,o){
  remove(id);
  const root=new THREE.Group(),m=THREE.SkeletonUtils.clone(models[o.model]),sc=info[o.model].scale*(o.scale||1);
  m.scale.setScalar(sc);m.rotation.y=Math.PI;root.add(m); // les modèles VRM 0.x regardent vers -Z
  const mats=[];
  m.traverse(n=>{
    if(n.isMesh){n.castShadow=true;n.frustumCulled=false;const s0=n.material;
      // matière éclairée par la scène, avec une part de lumière propre pour rester lisible la nuit
      const mk=x=>{const k=new THREE.MeshLambertMaterial({map:x.map,transparent:x.transparent,alphaTest:x.alphaTest,side:x.side,opacity:x.opacity,depthWrite:x.depthWrite,emissive:0xffffff,emissiveMap:x.map,emissiveIntensity:EMI});
        if(x.color)k.color.copy(x.color);if(o.tint)k.color.multiply(col(o.tint));k.userData.base=k.color.clone();k.emissive.copy(k.color);mats.push(k);return k};
      n.material=Array.isArray(s0)?s0.map(mk):mk(s0)}});
  root.position.set(o.x,0,o.z);root.rotation.y=o.face||0;scene.add(root);
  const a={id,root,m,mixer:new THREE.AnimationMixer(m),acts:{},cur:null,idle:o.idle||"Idle",home:new V3(o.x,0,o.z),face:o.face||0,
    h:TALL*(o.scale||1),dead:false,mats,flash:0,gray:0,opt:o};
  actors[id]=a;setAnim(a,a.idle,0);
  const rh=m.getObjectByName("J_Bip_R_Hand"),lh=m.getObjectByName("J_Bip_L_Hand");
  if(o.weapon&&rh){const w=weapon(o.weapon,o.orbCol);w.position.set(.07,0,0);rh.add(w)}
  if(o.orb&&lh){const g=new THREE.Mesh(new THREE.SphereGeometry(.055,12,8),new THREE.MeshBasicMaterial());const c=col(o.orb);g.material.color.setRGB(c.r*3,c.g*3,c.b*3);g.position.set(-.09,0,0);lh.add(g);a.orb=g}
  if(o.extras)decorate(a,o.extras);
  return a}
function decorate(a,x){
  const head=a.m.getObjectByName("J_Bip_C_Head");if(!head)return;
  const mk=(geo,c)=>{const m=new THREE.Mesh(geo,new THREE.MeshLambertMaterial({color:c,emissive:c,emissiveIntensity:.25}));m.castShadow=true;return m};
  if(x.ears==="beast")for(const s of[-1,1]){const e=mk(new THREE.ConeGeometry(.045,.11,4),x.hair||0x8a8a94);e.position.set(s*.075,.205,.01);e.rotation.z=-s*.25;head.add(e)}
  if(x.ears==="elf")for(const s of[-1,1]){const e=mk(new THREE.ConeGeometry(.02,.12,4),x.skin||0xf1d9bf);e.position.set(s*.115,.075,.01);e.rotation.z=-s*1.15;head.add(e)}
  if(x.horns)for(const s of[-1,1]){const e=mk(new THREE.ConeGeometry(.022,.13,6),0xe8dcc0);e.position.set(s*.06,.215,-.03);e.rotation.z=-s*.35;e.rotation.x=-.3;head.add(e)}
  const hips=a.m.getObjectByName("J_Bip_C_Hips");
  if(x.tail&&hips){const t=mk(new THREE.CylinderGeometry(.012,.028,.42,6),x.tail);t.position.set(0,-.02,.2);t.rotation.x=1.0;hips.add(t)}
  const chest=a.m.getObjectByName("J_Bip_C_UpperChest")||a.m.getObjectByName("J_Bip_C_Chest");
  if(x.wings&&chest)for(const s of[-1,1]){const g=new THREE.BufferGeometry();g.setAttribute("position",new THREE.BufferAttribute(new Float32Array([0,0,0, s*.55,.32,.14, s*.42,-.3,.16]),3));g.computeVertexNormals();
    const w=new THREE.Mesh(g,new THREE.MeshLambertMaterial({color:x.wings,emissive:x.wings,emissiveIntensity:.25,side:THREE.DoubleSide,transparent:true,opacity:.92}));w.position.set(s*.04,.08,.1);chest.add(w)}
}
function remove(id){const a=actors[id];if(!a)return;scene.remove(a.root);a.mixer.stopAllAction();delete actors[id]}
function removeWhere(fn){Object.keys(actors).filter(fn).forEach(remove)}
function action(a,name){name=RN(name);if(!a.acts[name]){const c=(modelClips[a.opt.model]||{})[name];if(!c)return null;a.acts[name]=a.mixer.clipAction(c)}return a.acts[name]}
function setAnim(a,name,fade,opt){
  opt=opt||{};const act=action(a,name);if(!act)return null;
  act.reset();act.setLoop(opt.once?THREE.LoopOnce:THREE.LoopRepeat,opt.once?1:Infinity);act.clampWhenFinished=!!opt.once;act.timeScale=opt.speed||1;act.enabled=true;act.setEffectiveWeight(1);
  if(a.cur&&a.cur!==act&&fade>0)act.crossFadeFrom(a.cur,fade,false);else if(a.cur&&a.cur!==act)a.cur.stop();
  act.play();a.cur=act;return act}
function clipDur(name){name=RN(name);return clips[name]?clips[name].duration:1}
function playOnce(id,name,opt){
  opt=opt||{};const a=actors[id];if(!a||!clips[RN(name)])return Promise.resolve();
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
      for(const m of a.mats)m.emissiveIntensity=EMI+a.flash*1.4;
      for(const m of a.mats){m.color.copy(m.userData.base);if(a.gray){const l=m.color.r*.3+m.color.g*.5+m.color.b*.2;m.color.setRGB(l*.6,l*.65,l*.8)}m.emissive.copy(m.color)}}
    if(a.orb)a.orb.scale.setScalar(1+.18*Math.sin(elapsed*5))}}
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
cam.wide=k=>{cam.zoom(baseFov());portrait()?cam.go(new V3(-2.7,5.4,11.6),new V3(-.05,1.55,-.6),k):cam.go(new V3(-6.2,3.3,9.4),new V3(.5,1.25,-1.2),k)};
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
    const c=col(color);m.material.color.setRGB(c.r*1.3,c.g*1.3,c.b*1.3);m.rotation.x=-Math.PI/2;m.position.set(pos.x,.06,pos.z);scene.add(m);
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
/* ---------- effets d'attaque par élément ---------- */
const ELC={feu:0xff7a2a,glace:0x8fe0ff,foudre:0xfff07a,lumiere:0xfff2c0,ombre:0x9a5cff,phys:0xfff2c0};
function tmp(m,dur,fn,e){scene.add(m);return tween(dur,t=>fn(t,m),e||ease.lin,true).then(()=>{scene.remove(m);m.traverse(o=>{if(o.geometry)o.geometry.dispose();if(o.material)o.material.dispose()})})}
function addMat(color,k,op){const c=col(color),m=new THREE.MeshBasicMaterial({transparent:true,blending:THREE.AdditiveBlending,depthWrite:false,side:THREE.DoubleSide,fog:false,opacity:op===undefined?1:op});m.color.setRGB(c.r*k,c.g*k,c.b*k);return m}
function smokePuff(p,n,r,g,b,size,up){for(let i=0;i<n;i++){const a=Math.random()*Math.PI*2,v=R(.5,2.2);fxSmoke.emit(p.x,p.y,p.z,Math.cos(a)*v,R(.3,up||1.4),Math.sin(a)*v,r,g,b,R(.9,1.9),size*.5,size*2.4,.38,.1,1.2)}}
fx.flare=function(pos,color){
  for(const[w,h]of[[4.2,.09],[.09,4.2],[2.4,.05]]){const m=new THREE.Mesh(new THREE.PlaneGeometry(w,h),addMat(color,3));m.position.copy(pos);m.lookAt(camera.position);if(w===2.4)m.rotateZ(.78);
    tmp(m,.38,(t,o)=>{o.scale.setScalar(.3+t*1.2);o.material.opacity=1-t*t},ease.out)}};
fx.slash=function(pos,color){
  for(let k=0;k<2;k++){const m=new THREE.Mesh(new THREE.RingGeometry(.78,1,48,1,0,2.9),addMat(k?0xffffff:color,k?3.2:2.4));m.position.copy(pos);m.lookAt(camera.position);const r0=R(0,6.28)+k*1.9;m.rotateZ(r0);
    tmp(m,.3,(t,o)=>{o.scale.setScalar((k?.55:.7)+t*(k?1.5:2.0));o.rotateZ(.2);o.material.opacity=1-t*t},ease.out)}
  for(let i=0;i<7;i++){const m=new THREE.Mesh(new THREE.PlaneGeometry(R(1.2,2.6),.035),addMat(0xffffff,2.2,.8));m.position.copy(pos);m.lookAt(camera.position);m.rotateZ(R(0,6.28));
    tmp(m,.22,(t,o)=>{o.translateX(.22);o.material.opacity=.8*(1-t)},ease.lin)}
  fx.sparks(pos,color,22);fx.ring(new V3(pos.x,0,pos.z),color,.3,2.4,.4);smokePuff(new V3(pos.x,.15,pos.z),7,.22,.2,.18,.5,.8);fxLight(pos,color,5,.25)};
fx.spellTravel=function(el,from,to,arc){
  const c=ELC[el]||0xffffff;
  if(el==="foudre"||el==="lumiere"){fx.ring(new V3(to.x,0,to.z),c,1.6,.3,.24);fxLight(new V3(to.x,3,to.z),c,3,.3);return wait(240)}
  const k=col(c),m=new THREE.Mesh(el==="glace"?new THREE.ConeGeometry(.16,.9,4):new THREE.SphereGeometry(el==="feu"?.3:.24,14,10),new THREE.MeshBasicMaterial({fog:false}));
  m.material.color.setRGB(k.r*3.4,k.g*3.4,k.b*3.4);scene.add(m);
  const f=fxLights.find(x=>!x.busy);if(f){f.busy=true;f.l.color.set(c);f.l.intensity=5}
  return tween(.36,t=>{m.position.lerpVectors(from,to,t);m.position.y+=Math.sin(t*Math.PI)*(arc||0);if(el==="glace"){m.lookAt(to);m.rotateX(Math.PI/2)}if(f)f.l.position.copy(m.position);
    const p=m.position;
    for(let i=0;i<4;i++)fxAdd.emit(p.x+R(-.14,.14),p.y+R(-.14,.14),p.z+R(-.14,.14),R(-.8,.8),R(-.3,1),R(-.8,.8),k.r*2.3,k.g*2.3,k.b*2.3,R(.25,.6),el==="feu"?.9:.55,.05,.9,el==="feu"?1.5:0,1);
    if(el==="feu"&&Math.random()<.6)fxSmoke.emit(p.x,p.y,p.z,R(-.3,.3),R(.4,1),R(-.3,.3),.07,.06,.06,R(.6,1.2),.4,1.5,.35,.1,.6);
    if(el==="ombre")fxSmoke.emit(p.x,p.y,p.z,R(-.4,.4),R(-.2,.4),R(-.4,.4),.03,.0,.06,R(.4,.8),.7,1.4,.7,0,.6);
    if(el==="glace"&&Math.random()<.7)fxAdd.emit(p.x,p.y,p.z,R(-1,1),R(-1,.2),R(-1,1),2.4,2.6,2.8,R(.2,.5),.12,.02,1,-3,.4)},ease.in,true)
    .then(()=>{scene.remove(m);m.geometry.dispose();m.material.dispose();if(f){f.l.intensity=0;f.busy=false}})};
fx.spellHit=function(el,id,big){
  const a=actors[id];if(!a)return;const c=ELC[el]||0xffffff,P=posOf(id),G=new V3(P.x,0,P.z),k=col(c),S=big?1.35:1;
  fxLight(P,c,big?13:8,.55);
  if(el==="feu"){
    fx.burst(P,0xff7a2a,big?80:48,9*S,.85,.8);fx.burst(P,0xffd070,24,5,.5,.5);fx.sparks(P,0xffc060,26);fx.ring(G,0xff7a2a,.4,5*S,.55);
    for(let i=0;i<60;i++){const an=Math.random()*Math.PI*2,r=R(0,.7)*S;fxAdd.emit(G.x+Math.cos(an)*r,R(0,.5),G.z+Math.sin(an)*r,R(-.4,.4),R(2.5,6.5),R(-.4,.4),2.4,R(.6,1.3),.25,R(.4,.9),R(.7,1.3)*S,.1,.9,1,.5)}
    smokePuff(new V3(P.x,1,P.z),14,.06,.05,.05,.9,2.6);
    const sc=new THREE.Mesh(new THREE.CircleGeometry(1.7*S,24),new THREE.MeshBasicMaterial({color:0x000000,transparent:true,opacity:.55,depthWrite:false}));sc.rotation.x=-Math.PI/2;sc.position.set(G.x,.03,G.z);tmp(sc,3,(t,o)=>{o.material.opacity=.55*(1-t)})}
  else if(el==="glace"){
    fx.ring(G,c,.3,3.6*S,.6);fx.burst(P,0xdff6ff,34,5,.4,.6);
    for(let i=0;i<(big?11:7);i++){const an=i/(big?11:7)*Math.PI*2+R(-.3,.3),r=i===0?0:R(.35,1.1)*S,h=(i===0?R(2.4,3):R(1.1,2.2))*S;
      const g=new THREE.ConeGeometry(.2*S,h,4);g.translate(0,h/2,0);const m=new THREE.Mesh(g,new THREE.MeshBasicMaterial({transparent:true,opacity:.9,fog:false}));m.material.color.setRGB(k.r*.45,k.g*1.0,k.b*1.45);
      m.position.set(G.x+Math.cos(an)*r,0,G.z+Math.sin(an)*r);m.rotation.set(Math.sin(an)*.45*(r>0?1:0),R(0,3),-Math.cos(an)*.45*(r>0?1:0));
      tmp(m,1.15,(t,o)=>{const up=Math.min(1,t/.16);o.scale.set(1,ease.out(up),1);if(t>.7){const q=(t-.7)/.3;o.material.opacity=.9*(1-q);o.scale.y=1-q*.4}})}
    wait(800).then(()=>{fx.sparks(new V3(P.x,1,P.z),0xdff6ff,28)});
    for(let i=0;i<12;i++)fxSmoke.emit(G.x+R(-1,1),R(.1,.5),G.z+R(-1,1),R(-.8,.8),R(.1,.5),R(-.8,.8),.55,.7,.8,R(1,2),.6,2.2,.22,0,.8)}
  else if(el==="foudre"){
    for(let b=0;b<(big?3:2);b++){const pts=[],top=new V3(P.x+R(-3,3),17,P.z+R(-3,3)),end=b===0?G:new V3(G.x+R(-1.4,1.4),0,G.z+R(-1.4,1.4));
      for(let i=0;i<=9;i++){const t=i/9,p=top.clone().lerp(end,t);if(i>0&&i<9){p.x+=R(-.8,.8);p.z+=R(-.8,.8)}pts.push(p)}
      const m=new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts,false,"catmullrom",.1),28,b===0?.09:.045,5),addMat(0xfff7c0,4.5));
      wait(b*70).then(()=>tmp(m,.42,(t,o)=>{o.material.opacity=(t<.18||(t>.3&&t<.48)||(t>.6&&t<.7))?1:.12*(1-t)}))}
    fx.ring(G,c,.3,4.4*S,.45);fx.sparks(P,0xfff7c0,46);fx.burst(P,0xbfd8ff,26,7,.4,.4);
    $flash(.5)}
  else if(el==="lumiere"){
    const m=new THREE.Mesh(new THREE.CylinderGeometry(1,1,16,24,1,true),addMat(c,.85,.36));m.position.set(G.x,8,G.z);
    tmp(m,.9,(t,o)=>{const w=(1.3-t*1.1)*S;o.scale.set(w,1,w);o.material.opacity=.36*(1-t*t)});
    const m2=new THREE.Mesh(new THREE.CylinderGeometry(.28,.28,16,12,1,true),addMat(0xffffff,3,.9));m2.position.set(G.x,8,G.z);tmp(m2,.7,(t,o)=>{o.material.opacity=.9*(1-t)});
    fx.ring(G,c,.3,4*S,.7);fx.ring(G,0xffffff,.2,2.2*S,.45);
    for(let i=0;i<70;i++){const an=Math.random()*Math.PI*2,r=R(.1,1.1)*S;fxAdd.emit(G.x+Math.cos(an)*r,R(0,1),G.z+Math.sin(an)*r,0,R(2,7),0,2.6,2.4,1.7,R(.5,1.2),.3,.04,1,0,.3)}
    fx.flare(new V3(P.x,P.y+.3,P.z),c)}
  else if(el==="ombre"){
    for(let i=0;i<54;i++){const u=Math.random()*Math.PI*2,v=R(-1,1),r=R(1.8,2.8),x=Math.cos(u)*Math.sqrt(1-v*v)*r,y=v*r,z=Math.sin(u)*Math.sqrt(1-v*v)*r;
      fxAdd.emit(P.x+x,P.y+y,P.z+z,-x*3,-y*3,-z*3,k.r*2.4,k.g*1.6,k.b*2.6,.33,.4,.06,1,0,0)}
    wait(250).then(()=>{const m=new THREE.Mesh(new THREE.SphereGeometry(1,24,16),new THREE.MeshBasicMaterial({color:0x05000c,transparent:true,opacity:.92,depthWrite:false,fog:false}));m.position.copy(P);
      tmp(m,.55,(t,o)=>{o.scale.setScalar((.3+t*1.6)*S);o.material.opacity=.92*(1-t*t)},ease.out);
      const sh=new THREE.Mesh(new THREE.SphereGeometry(1.04,24,16),addMat(c,.8,.38));sh.material.side=THREE.BackSide;sh.position.copy(P);tmp(sh,.55,(t,o)=>{o.scale.setScalar((.3+t*1.7)*S);o.material.opacity=.5*(1-t)},ease.out);
      fx.burst(P,c,50,8,.6,.7);fx.ring(G,c,.3,4.2*S,.6);smokePuff(P,10,.03,0,.06,.9,1.6)})}
  else fx.impact(P,c,big);
};
let flashCb=null;function $flash(v){if(flashCb)flashCb(v)}
function slowmo(scale,ms){timeScale=scale;return new Promise(r=>setTimeout(()=>{timeScale=1;r()},ms))}
function hitStop(ms){const p=timeScale;timeScale=.04;setTimeout(()=>{timeScale=p===.04?1:p},ms)}

/* ---------- rendu ---------- */
let paintPass=null,paintOn=true;
/* Passe « peinture » (filtre de Kuwahara) : aplats et touches de pinceau. */
const PaintShader={uniforms:{tDiffuse:{value:null},res:{value:new THREE.Vector2(800,600)},amt:{value:.6}},
  vertexShader:"varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}",
  fragmentShader:"uniform sampler2D tDiffuse;uniform vec2 res;uniform float amt;varying vec2 vUv;\n#define RR 3\nvoid main(){vec2 px=1./res;vec3 m0=vec3(0.),m1=vec3(0.),m2=vec3(0.),m3=vec3(0.),s0=vec3(0.),s1=vec3(0.),s2=vec3(0.),s3=vec3(0.);"+
   "for(int j=0;j<=RR;j++)for(int i=0;i<=RR;i++){vec2 o=vec2(float(i),float(j))*px;vec3 c;"+
   "c=min(texture2D(tDiffuse,vUv+vec2(-o.x,-o.y)).rgb,vec3(6.));m0+=c;s0+=c*c;c=min(texture2D(tDiffuse,vUv+vec2(o.x,-o.y)).rgb,vec3(6.));m1+=c;s1+=c*c;"+
   "c=min(texture2D(tDiffuse,vUv+vec2(-o.x,o.y)).rgb,vec3(6.));m2+=c;s2+=c*c;c=min(texture2D(tDiffuse,vUv+vec2(o.x,o.y)).rgb,vec3(6.));m3+=c;s3+=c*c;}"+
   "float n=float((RR+1)*(RR+1));m0/=n;m1/=n;m2/=n;m3/=n;s0=abs(s0/n-m0*m0);s1=abs(s1/n-m1*m1);s2=abs(s2/n-m2*m2);s3=abs(s3/n-m3*m3);"+
   "float v0=s0.r+s0.g+s0.b,v1=s1.r+s1.g+s1.b,v2=s2.r+s2.g+s2.b,v3=s3.r+s3.g+s3.b;vec3 col=m0;float mv=v0;if(v1<mv){mv=v1;col=m1;}if(v2<mv){mv=v2;col=m2;}if(v3<mv){mv=v3;col=m3;}"+
   "vec3 o=texture2D(tDiffuse,vUv).rgb;gl_FragColor=vec4(mix(o,col,amt),1.);}"};
/* Étalonnage : ombres sarcelle, lumières dorées, contraste, grain, vignette. */
const FinalShader={uniforms:{tDiffuse:{value:null},vig:{value:.9},sat:{value:1.12},red:{value:0},time:{value:0}},
  vertexShader:"varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.);}",
  fragmentShader:"uniform sampler2D tDiffuse;uniform float vig;uniform float sat;uniform float red;uniform float time;varying vec2 vUv;vec3 aces(vec3 x){return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14),0.,1.);}"+
   "void main(){vec3 c=texture2D(tDiffuse,vUv).rgb*1.12;c=aces(c);float l=dot(c,vec3(.299,.587,.114));"+
   "c=mix(c,c*vec3(.72,1.0,1.14)+vec3(.0,.012,.022),(1.-smoothstep(0.,.42,l))*.75);c=mix(c,c*vec3(1.10,1.02,.84),smoothstep(.45,1.,l)*.7);"+
   "c=mix(vec3(l),c,sat);c=c*c*(3.-2.*c)*.55+c*.45;"+
   "vec2 q=vUv-.5;float d=length(q)*1.2;c*=mix(1.,smoothstep(1.0,.18,d),vig);c=mix(c,c*vec3(1.25,.55,.5),red*smoothstep(.2,.8,d));"+
   "float g=fract(sin(dot(vUv*vec2(913.,517.)+time,vec2(12.9898,78.233)))*43758.5453)-.5;c+=g*.022;c=pow(max(c,0.),vec3(1./2.2));gl_FragColor=vec4(c,1.);}"};
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
    composer=new THREE.EffectComposer(renderer,rt);composer.addPass(new THREE.RenderPass(scene,camera));paintPass=new THREE.ShaderPass(PaintShader);composer.addPass(paintPass);
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
  if(paintPass){const v=renderer.getDrawingBufferSize(new THREE.Vector2());paintPass.uniforms.res.value.copy(v);paintPass.enabled=paintOn&&quality===2}
  if(finalPass)finalPass.uniforms.time.value=elapsed%10;
  if(onFrame)onFrame();
  if(composer&&quality>0){bloomPass.enabled=true;composer.render()}else renderer.render(scene,camera);
  // qualité automatique
  if(autoQ&&ready){perf.t+=real;perf.n++;if(perf.n>=80){const ms=perf.t/perf.n*1000;perf.t=perf.n=0;if(ms>38&&quality>0)setQuality(quality-1)}}
}
return{init,load,layout,spawn,remove,removeWhere,playOnce,loopAnim,idle,moveTo,place,faceTo,posOf,hit,die,revive,setGray,project,cam,fx,slowmo,hitStop,wait,tween,ease,clipDur,
  setInset(px){inset=px;layout()},setQuality,quality:()=>quality,isReady:()=>ready,setRush(v){rush=v},isRush:()=>rush,onFlash(f){flashCb=f},setPaint(v){paintOn=v},
  setOnFrame(f){onFrame=f},setRed(v){if(finalPass)finalPass.uniforms.red.value=v},setSat(v){if(finalPass)finalPass.uniforms.sat.value=v},
  actor:id=>actors[id],size:()=>({W,H}),V3};
})();
