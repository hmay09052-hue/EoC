GRNArcCW = GRNArcCW or {}

-- Aufsatz-Werkbank für ArcCW-Waffen. Gleiche Optik wie Inventar und
-- Waffenkammer (Bebas Neue / Montserrat, dunkles Glas, gelbe Akzente,
-- HUD-Ecken, Fußleiste). Die Mitte bleibt durchsichtig: dort steht die
-- Waffe als Viewmodel in der ArcCW-Anpassungspose.
GRNArcCW.HTML = [==[
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
<title>Aufsätze</title>
<style>
:root{
 --yellow:rgb(255,190,50);--white:#f4f1e9;--text:#d8dbe1;--muted:#9da3ad;--good:#77c4aa;--bad:#e07a6a;
 --fontMain:"Montserrat",Arial,sans-serif;--fontTitle:"Bebas Neue",Arial,sans-serif;
 --header:clamp(60px,8.2vh,90px);--footer:clamp(38px,5vh,52px);--sidePad:clamp(20px,3vw,62px);
 --side:__SIDE__vw;--gap:clamp(6px,.5vw,10px)
}
*{box-sizing:border-box;margin:0;padding:0}html,body{width:100%;height:100%;overflow:hidden;background:transparent}
body{font-family:var(--fontMain);color:var(--white);user-select:none;-webkit-user-select:none}button{font:inherit;color:inherit;border:0;outline:0;cursor:pointer;background:none}
.shell{position:relative;width:100vw;height:100vh;overflow:hidden;background:linear-gradient(90deg,rgba(3,7,12,.88),rgba(4,8,14,.62) calc(var(--side) + 2vw),rgba(4,8,14,0) calc(var(--side) + 9vw),rgba(4,8,14,0) calc(100% - var(--side) - 9vw),rgba(4,8,14,.62) calc(100% - var(--side) - 2vw),rgba(3,7,12,.88))}
.shell:before{content:"";position:absolute;inset:0;pointer-events:none;opacity:.12;background-image:radial-gradient(circle,rgba(255,255,255,.46) 0 1px,transparent 1.2px);background-size:220px 220px}
.app{position:relative;z-index:2;width:100%;height:100%}
.hudCorner{position:absolute;z-index:5;width:24px;height:24px;opacity:.34;pointer-events:none}.hudCorner:before,.hudCorner:after{content:"";position:absolute;background:var(--yellow)}.hudCorner:before{width:100%;height:1px}.hudCorner:after{width:1px;height:100%}.hudCorner.tl{left:1.2vw;top:2vh}.hudCorner.tr{right:1.2vw;top:2vh;transform:scaleX(-1)}.hudCorner.bl{left:1.2vw;bottom:2vh;transform:scaleY(-1)}.hudCorner.br{right:1.2vw;bottom:2vh;transform:scale(-1,-1)}
.topbar{position:absolute;left:0;right:0;top:0;height:var(--header);display:flex;align-items:center;padding:0 var(--sidePad);background:linear-gradient(180deg,rgba(4,8,15,.42),transparent)}
.titleBlock{display:flex;align-items:center;gap:clamp(10px,.9vw,16px);min-width:0}.kicker{color:var(--yellow);font-size:clamp(6px,.45vw,9px);font-weight:900;letter-spacing:.16em;text-transform:uppercase}.mainTitle{font-family:var(--fontTitle);font-size:clamp(26px,2.35vw,46px);line-height:1;letter-spacing:.055em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.titleLine{width:clamp(34px,4vw,78px);height:1px;background:linear-gradient(90deg,var(--yellow),transparent);box-shadow:0 0 8px rgba(255,190,50,.30)}
.serial{margin-top:3px;color:#d3dbe6;font-size:clamp(7px,.52vw,10px);font-weight:800;letter-spacing:.08em}.serial:empty{display:none}
.topInfo{margin-left:auto;display:flex;align-items:center;gap:clamp(12px,1.4vw,24px)}.userBlock{text-align:right}.userName{margin-top:2px;color:#d3dbe6;font-size:clamp(7px,.52vw,10px);font-weight:800}
.closeBtn{width:clamp(34px,2.5vw,46px);height:clamp(34px,2.5vw,46px);display:grid;place-items:center;background:rgba(7,12,21,.58);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;transition:.16s ease}.closeBtn:hover{background:rgba(255,190,50,.08);border-color:rgba(255,190,50,.34);transform:translateY(-1px)}
.side{position:absolute;top:var(--header);bottom:var(--footer);width:var(--side);padding:clamp(12px,2vh,24px) 0;display:flex;flex-direction:column;gap:clamp(10px,1.4vh,16px)}.side.left{left:var(--sidePad)}.side.right{right:var(--sidePad)}
.sectionTitle{margin-top:2px;font-family:var(--fontTitle);font-size:clamp(24px,2.2vw,44px);line-height:.94;letter-spacing:.035em}
.frame{position:relative;padding:clamp(10px,.9vw,14px);background:linear-gradient(135deg,rgba(8,11,15,.80),rgba(14,18,23,.52));border:1px solid rgba(255,255,255,.055)}.frame:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--yellow);opacity:.72;box-shadow:0 0 16px rgba(255,190,50,.30)}
.listFrame{flex:1 1 auto;min-height:0;display:flex;flex-direction:column}
.toolbar{flex:0 0 auto;height:clamp(30px,3.8vh,42px);display:flex;align-items:center;gap:10px;border-bottom:1px solid rgba(255,255,255,.06);margin-bottom:clamp(8px,1.2vh,14px)}.toolLabel{display:flex;align-items:center;gap:8px;color:#d7deea;font-size:clamp(7px,.53vw,10px);font-weight:900;text-transform:uppercase;letter-spacing:.06em;min-width:0;overflow:hidden;white-space:nowrap;text-overflow:ellipsis}.toolCount{margin-left:auto;color:#7f8ca0;font-size:clamp(6px,.46vw,9px);font-weight:800;white-space:nowrap}.toolCount strong{color:#dce3eb}
.scroll{flex:1 1 auto;min-height:0;overflow-y:auto;padding-right:4px;display:flex;flex-direction:column;gap:var(--gap)}.scroll::-webkit-scrollbar{width:2px}.scroll::-webkit-scrollbar-thumb{background:rgba(255,190,50,.55)}
.row{position:relative;flex:0 0 auto;min-height:clamp(46px,5.6vh,64px);display:flex;align-items:center;gap:clamp(8px,.7vw,12px);padding:6px 10px;text-align:left;border:1px solid rgba(213,224,241,.13);background:linear-gradient(145deg,rgba(4,8,14,.56),rgba(11,18,29,.34));transition:border-color .12s ease,background .12s ease,transform .12s ease}
.row:hover{border-color:rgba(255,190,50,.34);transform:translateX(2px)}.row.active{border-color:rgba(255,190,50,.85);background:linear-gradient(145deg,rgba(40,30,8,.42),rgba(11,18,29,.34));box-shadow:0 0 14px rgba(255,190,50,.10)}
.row.installed:after{content:"";position:absolute;left:0;top:0;bottom:0;width:2px;background:var(--good)}.row.blocked{opacity:.42}.row.blocked:hover{transform:none}
.ico{flex:0 0 auto;width:clamp(30px,2.5vw,46px);height:clamp(30px,2.5vw,46px);display:grid;place-items:center;border:1px solid rgba(255,255,255,.08);background:rgba(0,0,0,.25)}.ico img{max-width:86%;max-height:86%;object-fit:contain}.ico i{color:#edf0f6;font-size:clamp(12px,1vw,18px)}
.rowText{min-width:0;flex:1 1 auto}.rowName{color:#dce4ee;font-size:clamp(7px,.56vw,11px);font-weight:900;text-transform:uppercase;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rowSub{margin-top:3px;color:#8a95a6;font-size:clamp(6px,.45vw,9px);font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rowSub.on{color:#ffd36e}
.badge{flex:0 0 auto;font-size:clamp(5px,.4vw,8px);font-weight:900;letter-spacing:.08em;color:var(--good)}.badge.lock{color:#7c8696}
.empty{padding:22px 12px;border:1px dashed rgba(255,255,255,.08);text-align:center;color:#697483;font-size:clamp(7px,.5vw,10px);font-weight:800;line-height:1.7}
.detail{flex:0 0 auto;max-height:38vh;overflow:hidden;display:flex;flex-direction:column;gap:8px}.detailName{font-family:var(--fontTitle);font-size:clamp(20px,1.7vw,34px);letter-spacing:.045em;line-height:.95}.detailDesc{color:#8995a6;font-size:clamp(6px,.48vw,9px);line-height:1.55;max-height:7.5em;overflow:hidden}
.pc{display:flex;flex-direction:column;gap:3px;overflow-y:auto;min-height:0}.pc div{font-size:clamp(6px,.48vw,9px);font-weight:800;line-height:1.35}.pc .pro{color:var(--good)}.pc .con{color:var(--bad)}.pc .info{color:#aeb8c6}.pc div:before{content:"▪ ";opacity:.6}
.statBox{position:absolute;left:50%;bottom:calc(var(--footer) + clamp(10px,2vh,22px));transform:translateX(-50%);width:min(calc(100vw - 2*var(--side) - 2*var(--sidePad) - 4vw),760px);display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:4px 22px;padding:clamp(10px,1vw,14px) clamp(14px,1.2vw,20px)}
.stat{display:grid;grid-template-columns:minmax(0,1fr) auto;align-items:center;gap:10px;border-bottom:1px solid rgba(255,255,255,.05);padding:3px 0}.statName{color:#8a95a6;font-size:clamp(6px,.45vw,9px);font-weight:900;text-transform:uppercase;letter-spacing:.06em}.statVal{font-family:var(--fontTitle);font-size:clamp(14px,1.05vw,21px);letter-spacing:.05em;color:#dce4ee}.statVal.up{color:var(--good)}.statVal.down{color:var(--bad)}
.statBar{grid-column:1/-1;height:2px;background:rgba(255,255,255,.06)}.statBar span{display:block;height:100%;background:var(--yellow);opacity:.8}
.actions{flex:0 0 auto;display:flex;gap:var(--gap)}.action{flex:1 1 0;min-height:clamp(38px,4.6vh,52px);padding:0 clamp(10px,.8vw,14px);display:flex;align-items:center;gap:10px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(115deg,rgba(9,16,28,.86),rgba(8,14,24,.54));color:#c3ccd8;font-size:clamp(7px,.52vw,10px);font-weight:900;text-transform:uppercase;letter-spacing:.06em;transition:.14s ease}.action:hover{border-color:rgba(255,190,50,.42);color:#fff}.action.primary{border-color:rgba(255,190,50,.55);background:linear-gradient(115deg,rgba(60,44,10,.70),rgba(20,16,8,.55));color:#ffe3a2}.action[disabled]{opacity:.35;pointer-events:none}.action .label{flex:1 1 auto;text-align:left}
.key{min-width:clamp(24px,1.8vw,34px);height:clamp(22px,1.8vw,31px);padding:0 6px;display:grid;place-items:center;border:1px solid rgba(230,235,243,.45);color:#eef2f7;font-size:clamp(5px,.4vw,8px)}
.footer{position:absolute;left:0;right:0;bottom:0;height:var(--footer);display:flex;align-items:center;gap:14px;padding:0 var(--sidePad);background:linear-gradient(90deg,rgba(255,190,50,.08),rgba(255,190,50,.15),rgba(14,18,23,.58));border-top:1px solid rgba(255,190,50,.10)}.footerText{color:#aeb8c6;font-size:clamp(5px,.42vw,8px);font-weight:800;text-transform:uppercase}.footerLegend{margin-left:auto;display:flex;align-items:center;gap:8px}
.wear{display:flex;gap:16px;align-items:center}.wearItem{display:flex;align-items:center;gap:6px;color:#aeb8c6;font-size:clamp(5px,.42vw,8px);font-weight:900}.wearBar{width:clamp(40px,4vw,80px);height:3px;background:rgba(255,255,255,.08)}.wearBar span{display:block;height:100%;background:var(--good)}
.toast{position:absolute;left:50%;top:calc(var(--header) + 8px);transform:translate(-50%,-8px);padding:8px 12px;z-index:90;background:rgba(7,12,20,.94);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;font-size:10px;opacity:0;pointer-events:none;transition:opacity .16s ease,transform .16s ease}.toast.show{opacity:1;transform:translate(-50%,0)}
@media(max-height:760px){:root{--header:56px;--footer:38px}.detailDesc{display:none}}
</style>
</head>
<body>
<div class="shell"><div class="hudCorner tl"></div><div class="hudCorner tr"></div><div class="hudCorner bl"></div><div class="hudCorner br"></div><main class="app">
<header class="topbar">
 <div class="titleBlock"><div style="min-width:0"><div class="kicker" id="wepKicker">AUFSATZ-WERKBANK</div><div class="mainTitle" id="wepName">WAFFE</div><div class="serial" id="wepSerial"></div></div><div class="titleLine"></div></div>
 <div class="topInfo"><div class="userBlock"><div class="kicker" id="date">-- / -- / ----</div><div class="userName">ECHOES OF CLONES</div></div><button class="closeBtn" onclick="act('close')"><i class="fa-solid fa-xmark"></i></button></div>
</header>
<section class="side left">
 <div><div class="kicker">MONTAGEPUNKTE</div><div class="sectionTitle">SLOTS</div></div>
 <div class="frame listFrame"><div class="toolbar"><div class="toolLabel"><i class="fa-solid fa-screwdriver-wrench"></i><span>BESTÜCKUNG</span></div><div class="toolCount"><strong id="countUsed">0</strong> / <span id="countSlots">0</span> BELEGT</div></div><div class="scroll" id="slotList"></div></div>
</section>
<section class="side right">
 <div><div class="kicker" id="optKicker">FREIGEGEBENE AUFSÄTZE</div><div class="sectionTitle" id="optTitle">AUSWAHL</div></div>
 <div class="frame listFrame"><div class="toolbar"><div class="toolLabel"><i class="fa-solid fa-boxes-stacked"></i><span id="optLabel">KEIN SLOT GEWÄHLT</span></div><div class="toolCount"><strong id="countOpts">0</strong> VERFÜGBAR</div></div><div class="scroll" id="optList"></div></div>
 <div class="frame detail" id="detail"><div class="kicker" id="detKicker">DETAILS</div><div class="detailName" id="detName">—</div><div class="detailDesc" id="detDesc"></div><div class="pc" id="detPC"></div></div>
 <div class="actions"><button class="action primary" id="btnAttach" onclick="act('attach')"><i class="fa-solid fa-plug"></i><span class="label">ANBRINGEN</span><span class="key">LMB</span></button><button class="action" id="btnDetach" onclick="act('detach')"><i class="fa-solid fa-plug-circle-xmark"></i><span class="label">ABNEHMEN</span><span class="key">RMB</span></button></div>
</section>
<div class="frame statBox" id="stats"></div>
<footer class="footer"><div class="footerText">ECHOES OF CLONES · AUFSATZ-WERKBANK</div><div class="wear" id="wear"></div><div class="footerLegend"><span class="key">LMB</span><span class="footerText">ANBRINGEN</span><span class="key">RMB</span><span class="footerText">ABNEHMEN</span><span class="key">C</span><span class="footerText">SCHLIESSEN</span></div></footer>
<div class="toast" id="toast"></div>
</main></div>
<script>
(function(){
  var state={weapon:{},slots:[],stats:[]};var selSlot=null;var selAtt=null;var hoverAtt=null;
  function esc(v){return String(v==null?"":v).replace(/[&<>"']/g,function(c){return({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[c]})}
  function txt(id,v){var el=document.getElementById(id);if(el)el.textContent=v==null?"":String(v)}
  function sfx(k){try{if(window.grnAtt&&grnAtt.uiSound)grnAtt.uiSound(String(k))}catch(e){}}
  function safeIcon(v){v=String(v||"fa-puzzle-piece");return /^fa-[a-z0-9-]+$/i.test(v)?v:"fa-puzzle-piece"}
  function icon(o,fa){if(o&&o.icon)return '<img src="'+esc(o.icon)+'">';return '<i class="fa-solid '+safeIcon(fa)+'"></i>'}
  function slotByIndex(i){for(var k=0;k<state.slots.length;k++)if(state.slots[k].index===i)return state.slots[k];return null}
  function optByName(s,n){if(!s)return null;for(var k=0;k<s.options.length;k++)if(s.options[k].att===n)return s.options[k];return null}
  function renderSlots(){
    var box=document.getElementById("slotList");var h="";var used=0;
    if(!state.slots.length)h='<div class="empty"><i class="fa-solid fa-lock"></i><br>DIESE WAFFE HAT KEINE<br>FREIGEGEBENEN MONTAGEPUNKTE</div>';
    for(var i=0;i<state.slots.length;i++){var s=state.slots[i];if(s.installed)used++;
      h+='<button class="row'+(s.index===selSlot?' active':'')+(s.installed?' installed':'')+'" data-slot="'+s.index+'"><div class="ico">'+icon(s.installed?s.installedIcon:null,s.fa)+'</div><div class="rowText"><div class="rowName">'+esc(s.name)+'</div><div class="rowSub'+(s.installed?' on':'')+'">'+esc(s.installedName||"LEER")+'</div></div><div class="badge lock">'+s.options.length+'</div></button>'}
    box.innerHTML=h;txt("countUsed",used);txt("countSlots",state.slots.length);
    var rows=box.querySelectorAll(".row");for(var j=0;j<rows.length;j++){rows[j].addEventListener("click",function(){sfx("click");selectSlot(parseInt(this.getAttribute("data-slot"),10))});rows[j].addEventListener("mouseenter",function(){sfx("hover")})}
  }
  function renderOptions(){
    var s=slotByIndex(selSlot);var box=document.getElementById("optList");var h="";
    txt("optLabel",s?s.name:"KEIN SLOT GEWÄHLT");txt("countOpts",s?s.options.length:0);
    if(!s)h='<div class="empty">WÄHLE LINKS EINEN MONTAGEPUNKT</div>';
    else if(!s.options.length)h='<div class="empty"><i class="fa-solid fa-ban"></i><br>FÜR DIESEN SLOT IST KEIN<br>AUFSATZ FREIGEGEBEN</div>';
    else for(var i=0;i<s.options.length;i++){var o=s.options[i];var on=s.installed===o.att;
      h+='<button class="row'+(o.att===selAtt?' active':'')+(on?' installed':'')+(o.blocked?' blocked':'')+'" data-att="'+esc(o.att)+'"><div class="ico">'+icon(o,s.fa)+'</div><div class="rowText"><div class="rowName">'+esc(o.name)+'</div><div class="rowSub">'+esc(o.short||"")+'</div></div>'+(on?'<div class="badge"><i class="fa-solid fa-check"></i> VERBAUT</div>':(o.blocked?'<div class="badge lock"><i class="fa-solid fa-lock"></i></div>':''))+'</button>'}
    box.innerHTML=h;
    var rows=box.querySelectorAll(".row");for(var j=0;j<rows.length;j++){
      rows[j].addEventListener("click",function(){var n=this.getAttribute("data-att");selAtt=n;renderOptions();act("attach")});
      rows[j].addEventListener("contextmenu",function(ev){ev.preventDefault();act("detach")});
      rows[j].addEventListener("mouseenter",function(){sfx("hover");hoverAtt=this.getAttribute("data-att");renderDetail()});
      rows[j].addEventListener("mouseleave",function(){hoverAtt=null;renderDetail()})}
    var ba=document.getElementById("btnAttach"),bd=document.getElementById("btnDetach");var o2=optByName(s,selAtt);
    if(ba)ba.disabled=!(s&&o2&&!o2.blocked&&s.installed!==o2.att);if(bd)bd.disabled=!(s&&s.installed&&s.canDetach);
  }
  function renderDetail(){
    var s=slotByIndex(selSlot);var n=hoverAtt||selAtt||(s&&s.installed)||null;var o=optByName(s,n);
    if(!o&&s&&s.installed&&n===s.installed)o={name:s.installedName,desc:s.installedDesc,pros:s.installedPros||[],cons:s.installedCons||[],infos:s.installedInfos||[]};
    txt("detKicker",s?("SLOT · "+s.name):"DETAILS");txt("detName",o?o.name:"—");txt("detDesc",o?(o.desc||""):"Wähle einen Aufsatz aus der Liste.");
    var h="";if(o){var i;for(i=0;i<(o.pros||[]).length;i++)h+='<div class="pro">'+esc(o.pros[i])+'</div>';for(i=0;i<(o.cons||[]).length;i++)h+='<div class="con">'+esc(o.cons[i])+'</div>';for(i=0;i<(o.infos||[]).length;i++)h+='<div class="info">'+esc(o.infos[i])+'</div>';if(o.blocked)h+='<div class="con">Passt nicht zur aktuellen Bestückung</div>'}
    document.getElementById("detPC").innerHTML=h;
  }
  function renderStats(){
    var box=document.getElementById("stats");var h="";var st=state.stats||[];
    for(var i=0;i<st.length;i++){var r=st[i];var cls=r.trend>0?" up":(r.trend<0?" down":"");h+='<div class="stat"><div class="statName">'+esc(r.label)+'</div><div class="statVal'+cls+'">'+esc(r.value)+'</div>'+(r.bar!=null?'<div class="statBar"><span style="width:'+Math.max(0,Math.min(100,r.bar))+'%"></span></div>':'')+'</div>'}
    box.style.display=st.length?"grid":"none";box.innerHTML=h;
    var w=state.weapon||{};var wh="";(w.wear||[]).forEach(function(x){wh+='<div class="wearItem">'+esc(x.label)+'<div class="wearBar"><span style="width:'+Math.max(0,Math.min(100,x.value))+'%;background:'+esc(x.color||"var(--good)")+'"></span></div>'+esc(Math.round(x.value))+'%</div>'});document.getElementById("wear").innerHTML=wh;
  }
  function selectSlot(i){selSlot=i;var s=slotByIndex(i);selAtt=s?s.installed:null;hoverAtt=null;renderSlots();renderOptions();renderDetail()}
  window.act=function(a){
    if(a==="close"){sfx("close");try{grnAtt.close()}catch(e){}return}
    var s=slotByIndex(selSlot);if(!s){toast("Wähle zuerst einen Slot.");sfx("error");return}
    if(a==="attach"){var o=optByName(s,selAtt);if(!o)return;if(o.blocked){toast("Dieser Aufsatz passt gerade nicht.");sfx("error");return}if(s.installed===o.att)return;sfx("equip");try{grnAtt.attach(s.index,o.slot,o.att)}catch(e){}}
    if(a==="detach"){if(!s.installed||!s.canDetach)return;sfx("click");try{grnAtt.detach(s.index)}catch(e){}}
  };
  function toast(m){var el=document.getElementById("toast");el.textContent=String(m||"");el.classList.add("show");clearTimeout(toast._t);toast._t=setTimeout(function(){el.classList.remove("show")},1500)}
  window.GRNAttUI={setData:function(d){if(!d||typeof d!=="object")return;state=d;state.slots=Array.isArray(d.slots)?d.slots:[];var w=d.weapon||{};
      txt("wepName",w.name||"WAFFE");txt("wepKicker",w.kicker||"AUFSATZ-WERKBANK");txt("wepSerial",w.serial||"");txt("date",d.date||"");
      if(selSlot===null||!slotByIndex(selSlot))selSlot=state.slots.length?state.slots[0].index:null;var s=slotByIndex(selSlot);if(s&&!optByName(s,selAtt))selAtt=s.installed||null;
      renderSlots();renderOptions();renderDetail();renderStats()},toast:toast};
  document.addEventListener("keydown",function(ev){if(ev.key==="Escape"||ev.key==="c"||ev.key==="C"){ev.preventDefault();act("close")}});
  document.addEventListener("contextmenu",function(ev){ev.preventDefault()});
  try{if(window.grnAtt&&grnAtt.ready)grnAtt.ready()}catch(e){}
})();
</script>
</body>
</html>
]==]
