GRNStore = GRNStore or {}

-- Personal Armory terminal. Visual language matches the GRN inventory
-- (Echoes of Clones server design): Bebas Neue / Montserrat, dark glass
-- panels, yellow accent bars, HUD corners and the same footer.
GRNStore.ArmoryHTML = [==[
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
<title>Waffenkammer</title>
<style>
:root{
 --yellow:rgb(255,190,50);--white:#f4f1e9;--text:#d8dbe1;--muted:#9da3ad;
 --fontMain:"Montserrat",Arial,sans-serif;--fontTitle:"Bebas Neue",Arial,sans-serif;
 --header:clamp(60px,8.2vh,90px);--footer:clamp(38px,5vh,52px);--sidePad:clamp(20px,4.3vw,82px);
 --card:clamp(84px,9.4vh,118px);--gap:clamp(6px,.5vw,10px)
}
*{box-sizing:border-box;margin:0;padding:0}html,body{width:100%;height:100%;overflow:hidden;background:transparent}
body{font-family:var(--fontMain);color:var(--white);user-select:none;-webkit-user-select:none}button{font:inherit;color:inherit;border:0;outline:0;cursor:pointer;background:none}
.shell{position:relative;width:100vw;height:100vh;overflow:hidden;background:radial-gradient(ellipse at 50% 105%,rgba(255,190,50,.055),transparent 56%),linear-gradient(90deg,rgba(3,7,12,.86),rgba(4,8,14,.62) 42%,rgba(4,8,14,.58) 62%,rgba(3,7,12,.84))}
.shell:before{content:"";position:absolute;inset:0;pointer-events:none;opacity:.18;background-image:radial-gradient(circle,rgba(255,255,255,.46) 0 1px,transparent 1.2px);background-size:220px 220px}
.shell:after{content:"";position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,rgba(0,0,0,.2),transparent 20%,transparent 75%,rgba(0,0,0,.3)),radial-gradient(circle at 50% 50%,transparent 48%,rgba(0,0,0,.18) 100%)}
.app{position:relative;z-index:2;width:100%;height:100%}
.hudCorner{position:absolute;z-index:5;width:24px;height:24px;opacity:.34;pointer-events:none}.hudCorner:before,.hudCorner:after{content:"";position:absolute;background:var(--yellow)}.hudCorner:before{width:100%;height:1px}.hudCorner:after{width:1px;height:100%}.hudCorner.tl{left:1.2vw;top:2vh}.hudCorner.tr{right:1.2vw;top:2vh;transform:scaleX(-1)}.hudCorner.bl{left:1.2vw;bottom:2vh;transform:scaleY(-1)}.hudCorner.br{right:1.2vw;bottom:2vh;transform:scale(-1)}
.topbar{position:absolute;left:0;right:0;top:0;height:var(--header);display:flex;align-items:center;padding:0 var(--sidePad);background:linear-gradient(180deg,rgba(4,8,15,.36),transparent);border-bottom:1px solid rgba(255,255,255,.025)}
.titleBlock{display:flex;align-items:center;gap:clamp(10px,.9vw,16px)}.kicker{color:var(--yellow);font-size:clamp(6px,.45vw,9px);font-weight:900;letter-spacing:.16em;text-transform:uppercase}.mainTitle{font-family:var(--fontTitle);font-size:clamp(26px,2.35vw,46px);line-height:1;letter-spacing:.055em}.titleLine{width:clamp(34px,4vw,78px);height:1px;background:linear-gradient(90deg,var(--yellow),transparent);box-shadow:0 0 8px rgba(255,190,50,.30)}
.topInfo{margin-left:auto;display:flex;align-items:center;gap:clamp(12px,1.4vw,24px)}.userBlock{text-align:right}.userName{margin-top:2px;color:#d3dbe6;font-size:clamp(7px,.52vw,10px);font-weight:800}.closeBtn{width:clamp(34px,2.5vw,46px);height:clamp(34px,2.5vw,46px);display:grid;place-items:center;background:rgba(7,12,21,.58);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;transition:.16s ease}.closeBtn:hover{background:rgba(255,190,50,.08);border-color:rgba(255,190,50,.34);transform:translateY(-1px)}
.content{position:absolute;left:0;right:0;top:var(--header);bottom:var(--footer);padding:clamp(15px,2.2vh,28px) var(--sidePad);display:grid;grid-template-columns:minmax(0,.86fr) minmax(0,1.14fr);gap:clamp(24px,3.4vw,68px);overflow:hidden}
.col{position:relative;min-width:0;height:100%;display:flex;flex-direction:column;gap:clamp(10px,1.4vh,16px)}
.sectionHead{flex:0 0 auto;display:flex;align-items:flex-start;justify-content:space-between;gap:18px}.sectionTitle{margin-top:2px;font-family:var(--fontTitle);font-size:clamp(27px,2.65vw,52px);line-height:.94;letter-spacing:.035em}.sectionDesc{max-width:320px;color:#758195;font-size:clamp(6px,.47vw,9px);line-height:1.55;text-align:right}
.frame{position:relative;padding:clamp(11px,1vw,16px);background:linear-gradient(135deg,rgba(8,11,15,.78),rgba(14,18,23,.48));border:1px solid rgba(255,255,255,.055)}.frame:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--yellow);opacity:.72;box-shadow:0 0 16px rgba(255,190,50,.30)}
.listFrame{flex:1 1 auto;min-height:0;display:flex;flex-direction:column}
.toolbar{flex:0 0 auto;height:clamp(34px,4.3vh,46px);display:flex;align-items:center;gap:10px;border-bottom:1px solid rgba(255,255,255,.06);margin-bottom:clamp(10px,1.4vh,16px)}.toolLabel{display:flex;align-items:center;gap:8px;color:#d7deea;font-size:clamp(7px,.53vw,10px);font-weight:900;text-transform:uppercase;letter-spacing:.06em;min-width:0;overflow:hidden;white-space:nowrap;text-overflow:ellipsis}.toolLabel i{color:var(--yellow)}.toolCount{margin-left:auto;color:#7f8ca0;font-size:clamp(6px,.46vw,9px);font-weight:800;white-space:nowrap}.toolCount strong{color:#dce3eb}
.listScroll{flex:1 1 auto;min-height:0;overflow-y:auto;padding-right:4px}.listScroll::-webkit-scrollbar{width:2px}.listScroll::-webkit-scrollbar-thumb{background:rgba(255,190,50,.55)}
.weapon-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:var(--gap)}
.weapon-card{position:relative;height:var(--card);padding:8px 10px;overflow:hidden;text-align:left;border:1px solid rgba(213,224,241,.15);background:linear-gradient(145deg,rgba(4,8,14,.52),rgba(11,18,29,.32));transition:border-color .12s ease,background .12s ease,transform .12s ease}.weapon-card:hover{border-color:rgba(255,190,50,.34);transform:translateY(-1px)}.weapon-card.active{border-color:rgba(255,190,50,.85);background:linear-gradient(145deg,rgba(255,190,50,.12),rgba(9,12,16,.9));box-shadow:0 0 18px rgba(255,190,50,.12),inset 0 0 0 1px rgba(255,190,50,.12)}
.weapon-title{position:absolute;z-index:2;left:10px;right:10px;top:8px;color:#dce4ee;font-size:clamp(6px,.5vw,10px);font-weight:900;text-transform:uppercase;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.weapon-icon-wrap{position:absolute;left:8px;right:8px;top:22%;bottom:22%;display:flex;align-items:center;justify-content:center;pointer-events:none}.weapon-icon-wrap img{max-width:100%;max-height:100%;object-fit:contain;filter:drop-shadow(0 6px 10px rgba(0,0,0,.45))}.weapon-icon-wrap i{color:#edf0f6;font-size:clamp(22px,1.9vw,36px);filter:drop-shadow(0 6px 10px rgba(0,0,0,.35))}
.weapon-tag{position:absolute;left:10px;bottom:7px;display:flex;align-items:center;gap:5px;font-size:clamp(5px,.4vw,8px);font-weight:900;letter-spacing:.08em;color:#ffd36e}.weapon-tag.store{color:#77c4aa}.weapon-tag.base{color:#9fb1c7}
.weapon-owned{position:absolute;right:8px;bottom:6px;color:#77c4aa;font-size:clamp(5px,.38vw,7px);font-weight:900;letter-spacing:.06em}.weapon-card.owned .weapon-icon-wrap{opacity:.55}
.weapon-card .rarityLine{position:absolute;left:0;right:0;bottom:0;height:2px;background:rgba(255,190,50,.55)}
.empty{grid-column:1/-1;padding:28px 12px;border:1px dashed rgba(255,255,255,.08);text-align:center;color:#697483;font-size:clamp(7px,.5vw,10px);font-weight:800;line-height:1.7}
.jobCard{flex:0 0 auto;min-height:clamp(70px,9vh,104px);display:flex;align-items:center;gap:clamp(12px,1.1vw,18px);padding:clamp(12px,1.1vw,18px);background:linear-gradient(110deg,rgba(7,9,12,.90),rgba(14,18,23,.60));border:1px solid rgba(255,255,255,.05)}.jobIcon{width:clamp(44px,3.4vw,62px);height:clamp(44px,3.4vw,62px);flex:0 0 auto;display:grid;place-items:center;border:1px solid rgba(255,255,255,.12);background:rgba(4,8,14,.42);color:var(--yellow);font-size:clamp(18px,1.5vw,28px)}.jobName{font-family:var(--fontTitle);font-size:clamp(18px,1.5vw,30px);letter-spacing:.04em;line-height:.95}.jobSub{margin-top:5px;color:#8996a8;font-size:clamp(6px,.48vw,9px);line-height:1.55}
.detailCard{flex:0 0 auto;padding:clamp(14px,1.2vw,20px);display:grid;grid-template-columns:minmax(0,1fr) auto;gap:20px;background:linear-gradient(120deg,rgba(8,11,15,.76),rgba(14,18,23,.48));border:1px solid rgba(255,255,255,.05)}.detailName{margin-top:5px;font-family:var(--fontTitle);font-size:clamp(26px,2.3vw,46px);letter-spacing:.045em;line-height:.92;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.detailDesc{margin-top:6px;color:#7d899c;font-size:clamp(6px,.48vw,9px);line-height:1.55;max-height:4.8em;overflow:hidden}.detailMeta{text-align:right;color:#65758b;font-size:clamp(5px,.38vw,7px);font-weight:900;text-transform:uppercase;letter-spacing:.08em}.detailMeta strong{display:block;margin-top:3px;color:#dce4ee;font-family:var(--fontTitle);font-size:clamp(17px,1.3vw,25px);letter-spacing:.04em}.detailMeta strong.ok{color:#77c4aa}
.previewFrame{flex:1 1 auto;min-height:0;display:grid;grid-template-columns:minmax(0,1fr) clamp(190px,15vw,300px);gap:clamp(12px,1.4vw,26px)}
.preview{position:relative;min-width:0;min-height:0}.previewGrid{position:absolute;inset:4%;opacity:.2;background:linear-gradient(rgba(255,190,50,.10) 1px,transparent 1px),linear-gradient(90deg,rgba(255,190,50,.10) 1px,transparent 1px);background-size:38px 38px;-webkit-mask-image:radial-gradient(circle,#000 22%,transparent 70%);pointer-events:none}.previewRing{position:absolute;left:50%;top:50%;width:min(70%,460px);aspect-ratio:1;transform:translate(-50%,-50%);border-radius:50%;border:1px solid rgba(207,214,226,.08);box-shadow:0 0 0 50px rgba(255,255,255,.012),inset 0 0 80px rgba(255,190,50,.03);pointer-events:none}.model-hook{position:absolute;inset:4% 2% 12% 2%;pointer-events:none}.previewTag{position:absolute;left:50%;bottom:2%;transform:translateX(-50%);min-width:220px;text-align:center;color:#5f6c80;font-size:clamp(5px,.38vw,7px);font-weight:900;letter-spacing:.13em;text-transform:uppercase}.previewTag .bar{height:1px;margin-top:7px;background:linear-gradient(90deg,transparent,var(--yellow),transparent);box-shadow:0 0 10px rgba(255,190,50,.40)}
.stats{min-height:0;overflow:hidden;padding-left:clamp(10px,1vw,16px);border-left:1px solid rgba(255,255,255,.06)}.statsTitle{font-family:var(--fontTitle);font-size:clamp(18px,1.35vw,27px);letter-spacing:.055em;color:#dce4ee;margin-bottom:10px}.stat{display:grid;grid-template-columns:minmax(0,1fr) auto;align-items:center;gap:12px;min-height:clamp(20px,2.6vh,28px);border-bottom:1px solid rgba(255,255,255,.035)}.stat-name{color:#8e97a5;font-size:clamp(6px,.48vw,9px);font-weight:700;text-transform:uppercase;letter-spacing:.04em}.stat-value{color:#dce4ee;font-size:clamp(6px,.5vw,10px);font-weight:900;white-space:nowrap}.stat-value.accent{color:var(--yellow)}
.actionRow{flex:0 0 auto;display:flex;gap:clamp(8px,.8vw,14px)}.action{flex:1 1 0;min-height:clamp(42px,5.2vh,58px);padding:0 clamp(12px,1vw,18px);display:flex;align-items:center;gap:12px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(115deg,rgba(9,16,28,.86),rgba(8,14,24,.54));color:#c3ccd8;font-size:clamp(7px,.52vw,10px);font-weight:900;text-transform:uppercase;letter-spacing:.06em;transition:.14s ease;position:relative;overflow:hidden}.action:hover{border-color:rgba(255,190,50,.30);color:#fff;transform:translateY(-1px)}.action.primary{border-color:rgba(255,190,50,.38);background:linear-gradient(115deg,rgba(255,190,50,.20),rgba(20,18,12,.75));color:#fff}.action.primary:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--yellow);box-shadow:0 0 14px rgba(255,190,50,.4)}.action.disabled{opacity:.35;pointer-events:none}.action .label{flex:1 1 auto;text-align:left}
.key{min-width:clamp(27px,2vw,38px);height:clamp(25px,2vw,35px);padding:0 7px;display:grid;place-items:center;border:1px solid rgba(230,235,243,.45);color:#eef2f7;font-size:clamp(5px,.4vw,8px)}
.footer{position:absolute;left:0;right:0;bottom:0;height:var(--footer);display:flex;align-items:center;gap:14px;padding:0 var(--sidePad);background:linear-gradient(90deg,rgba(255,190,50,.08),rgba(255,190,50,.15),rgba(14,18,23,.58));border-top:1px solid rgba(255,190,50,.10)}.footerText{color:#aeb8c6;font-size:clamp(5px,.42vw,8px);font-weight:800;text-transform:uppercase}.vitals{display:flex;align-items:center;gap:8px;color:#dce4ee;font-size:clamp(6px,.46vw,9px);font-weight:900}.vitals i.hp{color:#d9645d}.vitals i.ar{color:var(--yellow)}.footerLegend{margin-left:auto;display:flex;align-items:center;gap:10px}
.toast{position:absolute;left:50%;top:calc(var(--header) + 8px);transform:translate(-50%,-8px);padding:8px 12px;z-index:90;background:rgba(7,12,20,.94);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;font-size:10px;opacity:0;pointer-events:none;transition:opacity .16s ease,transform .16s ease}.toast.show{opacity:1;transform:translate(-50%,0)}
@media(max-width:1366px){:root{--sidePad:clamp(16px,2.4vw,34px)}.content{gap:24px}.sectionDesc{max-width:240px}.weapon-grid{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media(max-width:1100px){.sectionDesc{display:none}.previewFrame{grid-template-columns:minmax(0,1fr) 170px}}
@media(max-height:760px){:root{--header:60px;--footer:40px;--card:74px}.content{padding-top:10px;padding-bottom:8px}.detailDesc{display:none}.jobCard{min-height:60px}}
</style>
</head>
<body>
<div class="shell"><div class="hudCorner tl"></div><div class="hudCorner tr"></div><div class="hudCorner bl"></div><div class="hudCorner br"></div><main class="app">
<header class="topbar">
 <div class="titleBlock"><div><div class="kicker">TAKTISCHES TERMINAL</div><div class="mainTitle" id="armoryTitle">WAFFENKAMMER</div></div><div class="titleLine"></div></div>
 <div class="topInfo"><div class="userBlock"><div class="kicker" id="date">-- / -- / ----</div><div class="userName" id="server">ECHOES OF CLONES</div></div><button class="closeBtn" onclick="armoryAction('close')"><i class="fa-solid fa-xmark"></i></button></div>
</header>
<section class="content">
 <div class="col">
  <div class="sectionHead"><div><div class="kicker">FREIGEGEBENE AUSRÜSTUNG</div><div class="sectionTitle">WAFFENKAMMER</div></div><div class="sectionDesc">Für deinen aktuellen Job freigegebene Ausrüstung. Entnommene Gegenstände landen in deinem Inventar (I), dort rüstest du sie aus.</div></div>
  <div class="frame listFrame">
   <div class="toolbar"><div class="toolLabel"><i class="fa-solid fa-box-open"></i><span id="loadoutSectionTitle">WAFFENKAMMER-ZUGRIFF</span></div><div class="toolCount"><strong id="countOwned">0</strong> / <span id="countTotal">0</span> IM INVENTAR</div></div>
   <div class="listScroll"><div class="weapon-grid" id="weaponGrid"></div></div>
  </div>
  <div class="jobCard" id="sets"></div>
 </div>
 <div class="col">
  <div class="detailCard"><div style="min-width:0"><div class="kicker" id="weaponType">PERSÖNLICHE WAFFENKAMMER</div><div class="detailName" id="weaponName">KEINE AUSWAHL</div><div class="detailDesc" id="weaponDesc">Wähle einen Gegenstand aus der Waffenkammer.</div></div><div class="detailMeta">STATUS<strong id="weaponStatus">-</strong></div></div>
  <div class="frame previewFrame">
   <div class="preview"><div class="previewGrid"></div><div class="previewRing"></div><div class="model-hook" id="modelViewport"></div><div class="previewTag">TECHNISCHE ANSICHT DER AUSWAHL<div class="bar"></div></div></div>
   <aside class="stats"><div class="statsTitle">DATEN</div><div id="statRows"></div></aside>
  </div>
  <div class="actionRow">
   <button class="action primary" id="takeBtn" onclick="armoryAction('take_weapon')"><i class="fa-solid fa-hand-holding"></i><span class="label">NEHMEN</span><span class="key">ALT</span></button>
   <button class="action" id="returnBtn" onclick="armoryAction('return_all')"><i class="fa-solid fa-rotate-left"></i><span class="label">ALLES ZURÜCKGEBEN</span><span class="key">R</span></button>
  </div>
 </div>
</section>
<footer class="footer"><div class="footerText">ECHOES OF CLONES · WAFFENKAMMER</div><div class="vitals"><i class="fa-solid fa-heart-pulse hp"></i><span id="health">100</span><i class="fa-solid fa-shield-halved ar"></i><span id="armor">0</span></div><div class="footerLegend"><span class="key">ALT</span><span class="footerText">NEHMEN</span><span class="key">ESC</span><span class="footerText">SCHLIESSEN</span></div></footer>
<div class="toast" id="toast">Action sent</div>
</main></div>
<script>
(function(){
  var state={weapons:[],sets:[[],[],[],[]],jobLoadout:{active:false},health:100,armor:0};
  var icons={};var selectedId="";var activeSet=1;var viewportTimer=null;
  function sfx(k){try{if(window.grnArmory&&grnArmory.uiSound)grnArmory.uiSound(String(k))}catch(e){}}
  function esc(v){return String(v==null?"":v).replace(/[&<>"']/g,function(c){return({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[c]})}
  function txt(id,v){var el=document.getElementById(id);if(el)el.textContent=v==null?"":String(v)}
  function weaponById(id){for(var i=0;i<state.weapons.length;i++)if(String(state.weapons[i].id)===String(id))return state.weapons[i];return null}
  function safeIconClass(v){v=String(v||"fa-gun").replace(/^fa-solid\s+/,'');if(!/^fa-[a-z0-9-]+$/i.test(v))v="fa-gun";return v}
  function iconFor(w){if(w.iconURL)return '<img src="'+esc(w.iconURL)+'">';if(icons[w.id])return '<img src="'+icons[w.id]+'">';return '<i class="fa-solid '+safeIconClass(w.icon)+'"></i>'}
  function renderWeapons(){
    var grid=document.getElementById("weaponGrid");if(!grid)return;var html="";var owned=0;
    if(!state.weapons.length){html='<div class="empty"><i class="fa-solid fa-lock"></i><br>FÜR DEINEN AKTUELLEN JOB IST KEINE AUSRÜSTUNG FREIGEGEBEN</div>';selectedId=""}
    for(var i=0;i<state.weapons.length;i++){
      var w=state.weapons[i];if(!selectedId&&i===0)selectedId=String(w.id);if(w.inInventory)owned++;
      var cls="weapon-card"+(String(w.id)===String(selectedId)?" active":"")+(w.inInventory?" owned":"");
      var source=w.source==="base"?"base":(w.source==="job"?"job":"store");var label=w.sourceLabel||(source==="base"?"BASIS":(source==="job"?"JOB":"GEKAUFT"));
      html+='<button class="'+cls+'" data-id="'+esc(w.id)+'"><div class="weapon-title">'+esc(w.name)+'</div><div class="weapon-icon-wrap">'+iconFor(w)+'</div><div class="weapon-tag '+source+'"><i class="fa-solid '+(w.isArmor?'fa-shield-halved':'fa-lock-open')+'"></i>'+esc(label)+'</div>'+(w.inInventory?'<div class="weapon-owned"><i class="fa-solid fa-check"></i> IM INVENTAR</div>':'')+'<div class="rarityLine"></div></button>';
    }
    grid.innerHTML=html;txt("countOwned",owned);txt("countTotal",state.weapons.length);
    var cards=grid.querySelectorAll(".weapon-card");for(var j=0;j<cards.length;j++){cards[j].addEventListener("click",function(){sfx("click");selectWeapon(this.getAttribute("data-id"))});cards[j].addEventListener("mouseenter",function(){sfx("hover")})}
  }
  function renderSets(){var box=document.getElementById("sets");if(!box)return;var job=state.jobLoadout&&state.jobLoadout.active?state.jobLoadout:null;txt("loadoutSectionTitle",job?("JOB-AUSRÜSTUNG · "+(job.name||"")):"WAFFENKAMMER-ZUGRIFF");if(job){box.innerHTML='<div class="jobIcon"><i class="fa-solid fa-id-badge"></i></div><div style="min-width:0"><div class="kicker">FREIGEGEBENE AUSRÜSTUNG</div><div class="jobName">'+esc(job.name||"JOB-AUSRÜSTUNG")+'</div><div class="jobSub">'+Number(job.count||state.weapons.length)+' freigegebene Gegenstände · nimm nur, was du brauchst · Ausrüstung anderer Jobs wird beim Jobwechsel entfernt</div></div>';return}box.innerHTML='<div class="jobIcon"><i class="fa-solid fa-warehouse"></i></div><div><div class="kicker">EINZELAUSGABE</div><div class="jobName">KEINE JOB-AUSRÜSTUNG</div><div class="jobSub">Dein aktueller Job hat keine Waffenkammer-Ausrüstung. Gekaufte Waffen werden trotzdem angezeigt.</div></div>'}
  function renderStats(w){var box=document.getElementById("statRows");if(!box)return;var rows=(w&&Array.isArray(w.statRows))?w.statRows:[];var h="";for(var i=0;i<rows.length;i++){h+='<div class="stat"><div class="stat-name">'+esc(rows[i].label)+'</div><div class="stat-value'+(rows[i].accent?' accent':'')+'">'+esc(rows[i].value)+'</div></div>'}box.innerHTML=h||'<div class="stat"><div class="stat-name">Keine Daten</div><div class="stat-value">-</div></div>'}
  function selectWeapon(id){var w=weaponById(id);if(!w)return;selectedId=String(w.id);renderWeapons();txt("weaponName",w.name||"UNBEKANNT");txt("weaponType",w.typeLabel||"Waffe · Ausrüstung");txt("weaponDesc",w.description||"");var st=document.getElementById("weaponStatus");if(st){st.textContent=w.inInventory?"IM INVENTAR":"VERFÜGBAR";st.className=w.inInventory?"ok":""}var tb=document.getElementById("takeBtn");if(tb)tb.classList.toggle("disabled",!!w.inInventory);renderStats(w);try{if(window.grnArmory&&grnArmory.selectWeapon)grnArmory.selectWeapon(selectedId)}catch(e){}scheduleViewport()}
  function syncViewport(){var hook=document.getElementById("modelViewport");if(!hook||!selectedId)return;var r=hook.getBoundingClientRect();if(r.width<20||r.height<20)return;var data={id:selectedId,x:r.left,y:r.top,w:r.width,h:r.height,viewportW:window.innerWidth,viewportH:window.innerHeight};try{if(window.grnArmory&&grnArmory.syncViewport)grnArmory.syncViewport(JSON.stringify(data))}catch(e){}}
  function scheduleViewport(){if(viewportTimer)clearTimeout(viewportTimer);viewportTimer=setTimeout(syncViewport,30)}
  window.armoryAction=function(action){if(action!=="close")sfx(action==="take_weapon"?"equip":"click");if(action==="close"){try{if(window.grnArmory&&grnArmory.close)grnArmory.close()}catch(e){}return}if(action!=="return_all"&&!selectedId){toast("Wähle einen Gegenstand aus.");return}try{if(window.grnArmory&&grnArmory.action)grnArmory.action(action,selectedId||"",String(activeSet))}catch(e){}}
  function toast(message){if(/NICHT GENUG|NICHT MEHR|KONNTE NICHT|NICHT VERFÜGBAR|LIMIT|KEINE GEGENSTÄNDE|UNGÜLTIG|KEINE SWEP/i.test(String(message||"")))sfx("error");var el=document.getElementById("toast");if(!el)return;el.textContent=String(message||"");el.classList.add("show");clearTimeout(toast._t);toast._t=setTimeout(function(){el.classList.remove("show")},1500)}
  window.GRNArmoryUI={setData:function(data){state=data&&typeof data==="object"?data:state;state.weapons=Array.isArray(state.weapons)?state.weapons:[];state.sets=Array.isArray(state.sets)?state.sets:[[],[],[],[]];state.jobLoadout=state.jobLoadout&&typeof state.jobLoadout==="object"?state.jobLoadout:{active:false};if(selectedId&&!weaponById(selectedId))selectedId="";txt("armoryTitle",String(state.armoryName||"Persönliche Waffenkammer").toUpperCase());txt("server",state.serverName||"ECHOES OF CLONES");txt("date",state.date||"");txt("health",state.health==null?100:state.health);txt("armor",state.armor==null?0:state.armor);renderWeapons();renderSets();if(state.weapons.length)selectWeapon(selectedId||state.weapons[0].id);else{renderStats(null);txt("weaponName","KEINE AUSWAHL");txt("weaponDesc","");scheduleViewport()}try{if(window.grnArmory&&grnArmory.stateApplied)grnArmory.stateApplied(state.weapons.length,!!state.jobLoadout.active)}catch(e){}},
    setIcons:function(map){if(!map||typeof map!=="object")return;var changed=false;for(var k in map){if(icons[k]!==map[k]){icons[k]=map[k];changed=true}}if(changed)renderWeapons()},
    toast:toast,syncViewport:syncViewport};
  try{if(window.grnArmory&&grnArmory.ready)grnArmory.ready()}catch(e){};
  document.addEventListener("keydown",function(ev){if(ev.key==="Escape")armoryAction("close");if(ev.key==="Alt"){ev.preventDefault();armoryAction("take_weapon")}if(ev.key==="r"||ev.key==="R")armoryAction("return_all")});
  window.addEventListener("resize",scheduleViewport);setInterval(syncViewport,500);renderWeapons();renderSets();
})();
</script>
</body>
</html>
]==]
