GRNSerials = GRNSerials or {}

-- Waffenpass, Waffenkammer-Terminal, Werkbank, Vitrine und Admin-Panel in
-- einer Seite. Optik wie Inventar und Waffenkammer (Echoes of Clones).
GRNSerials.HTML = [==[
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css">
<title>Waffenakte</title>
<style>
:root{
 --yellow:rgb(255,190,50);--white:#f4f1e9;--text:#d8dbe1;--muted:#8a95a6;--good:#77c4aa;--bad:#e07a6a;--warn:#ffbe32;
 --fontMain:"Montserrat",Arial,sans-serif;--fontTitle:"Bebas Neue",Arial,sans-serif;
 --header:clamp(60px,8.2vh,90px);--footer:clamp(38px,5vh,52px);--sidePad:clamp(20px,4.3vw,82px);--gap:clamp(6px,.5vw,10px)
}
*{box-sizing:border-box;margin:0;padding:0}html,body{width:100%;height:100%;overflow:hidden;background:transparent}
body{font-family:var(--fontMain);color:var(--white);user-select:none;-webkit-user-select:none}button,input,select{font:inherit;color:inherit;border:0;outline:0;background:none}button{cursor:pointer}
.shell{position:relative;width:100vw;height:100vh;overflow:hidden;background:radial-gradient(ellipse at 50% 105%,rgba(255,190,50,.055),transparent 56%),linear-gradient(90deg,rgba(3,7,12,.90),rgba(4,8,14,.74) 42%,rgba(4,8,14,.72) 62%,rgba(3,7,12,.90))}
.shell:before{content:"";position:absolute;inset:0;pointer-events:none;opacity:.18;background-image:radial-gradient(circle,rgba(255,255,255,.46) 0 1px,transparent 1.2px);background-size:220px 220px}
.app{position:relative;z-index:2;width:100%;height:100%}
.hudCorner{position:absolute;z-index:5;width:24px;height:24px;opacity:.34;pointer-events:none}.hudCorner:before,.hudCorner:after{content:"";position:absolute;background:var(--yellow)}.hudCorner:before{width:100%;height:1px}.hudCorner:after{width:1px;height:100%}.hudCorner.tl{left:1.2vw;top:2vh}.hudCorner.tr{right:1.2vw;top:2vh;transform:scaleX(-1)}.hudCorner.bl{left:1.2vw;bottom:2vh;transform:scaleY(-1)}.hudCorner.br{right:1.2vw;bottom:2vh;transform:scale(-1,-1)}
.topbar{position:absolute;left:0;right:0;top:0;height:var(--header);display:flex;align-items:center;padding:0 var(--sidePad);background:linear-gradient(180deg,rgba(4,8,15,.36),transparent);border-bottom:1px solid rgba(255,255,255,.025)}
.titleBlock{display:flex;align-items:center;gap:clamp(10px,.9vw,16px);min-width:0}.kicker{color:var(--yellow);font-size:clamp(6px,.45vw,9px);font-weight:900;letter-spacing:.16em;text-transform:uppercase}.mainTitle{font-family:var(--fontTitle);font-size:clamp(26px,2.35vw,46px);line-height:1;letter-spacing:.055em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.titleLine{width:clamp(34px,4vw,78px);height:1px;background:linear-gradient(90deg,var(--yellow),transparent);box-shadow:0 0 8px rgba(255,190,50,.30)}
.topInfo{margin-left:auto;display:flex;align-items:center;gap:clamp(10px,1.2vw,20px)}.userBlock{text-align:right}.userName{margin-top:2px;color:#d3dbe6;font-size:clamp(7px,.52vw,10px);font-weight:800}
.iconBtn{width:clamp(34px,2.5vw,46px);height:clamp(34px,2.5vw,46px);display:grid;place-items:center;background:rgba(7,12,21,.58);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;transition:.16s ease}.iconBtn:hover{background:rgba(255,190,50,.08);border-color:rgba(255,190,50,.34);transform:translateY(-1px)}.iconBtn.hidden{display:none}
.content{position:absolute;left:0;right:0;top:var(--header);bottom:var(--footer);padding:clamp(15px,2.2vh,28px) var(--sidePad);display:grid;grid-template-columns:minmax(0,.9fr) minmax(0,1.1fr);gap:clamp(20px,2.8vw,56px);overflow:hidden}
.col{position:relative;min-width:0;height:100%;display:flex;flex-direction:column;gap:clamp(10px,1.4vh,16px);min-height:0}
.sectionTitle{margin-top:2px;font-family:var(--fontTitle);font-size:clamp(24px,2.3vw,46px);line-height:.94;letter-spacing:.035em}
.frame{position:relative;padding:clamp(11px,1vw,16px);background:linear-gradient(135deg,rgba(8,11,15,.78),rgba(14,18,23,.48));border:1px solid rgba(255,255,255,.055)}.frame:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--yellow);opacity:.72;box-shadow:0 0 16px rgba(255,190,50,.30)}
.grow{flex:1 1 auto;min-height:0;display:flex;flex-direction:column}
.toolbar{flex:0 0 auto;min-height:clamp(32px,4vh,44px);display:flex;align-items:center;gap:8px;border-bottom:1px solid rgba(255,255,255,.06);margin-bottom:clamp(8px,1.2vh,14px);flex-wrap:wrap}
.tab{padding:6px 10px;color:#8a95a6;font-size:clamp(6px,.5vw,9px);font-weight:900;letter-spacing:.08em;text-transform:uppercase;border-bottom:2px solid transparent}.tab:hover{color:#dce4ee}.tab.on{color:#ffe3a2;border-color:var(--yellow)}.tab .n{color:#5f6a7a;margin-left:4px}
.search{margin-left:auto;display:flex;align-items:center;gap:6px;padding:5px 8px;border:1px solid rgba(255,255,255,.08);background:rgba(0,0,0,.25);color:#aeb8c6;font-size:clamp(6px,.5vw,9px)}.search input{width:clamp(80px,9vw,170px);font-size:clamp(7px,.52vw,10px);font-weight:700;color:#e6ebf2}
.chk{display:flex;align-items:center;gap:5px;color:#8a95a6;font-size:clamp(6px,.45vw,8px);font-weight:900;cursor:pointer}.chk.on{color:var(--warn)}
.scroll{flex:1 1 auto;min-height:0;overflow-y:auto;padding-right:4px;display:flex;flex-direction:column;gap:var(--gap)}.scroll::-webkit-scrollbar{width:2px}.scroll::-webkit-scrollbar-thumb{background:rgba(255,190,50,.55)}
.row{position:relative;flex:0 0 auto;display:grid;grid-template-columns:minmax(0,1fr) auto;gap:10px;align-items:center;padding:8px 12px;text-align:left;border:1px solid rgba(213,224,241,.13);background:linear-gradient(145deg,rgba(4,8,14,.56),rgba(11,18,29,.34));transition:border-color .12s,transform .12s}.row:hover{border-color:rgba(255,190,50,.34);transform:translateX(2px)}.row.on{border-color:rgba(255,190,50,.85);background:linear-gradient(145deg,rgba(40,30,8,.42),rgba(11,18,29,.34))}
.row.trad:after{content:"";position:absolute;left:0;top:0;bottom:0;width:2px;background:var(--yellow)}
.rName{color:#dce4ee;font-size:clamp(7px,.56vw,11px);font-weight:900;text-transform:uppercase;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rSub{margin-top:3px;color:var(--muted);font-size:clamp(6px,.45vw,9px);font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.rSub b{color:#c9d2de}
.rRight{text-align:right;font-size:clamp(6px,.45vw,9px);font-weight:900;color:#aeb8c6}.mini{width:clamp(50px,5vw,90px);height:3px;background:rgba(255,255,255,.08);margin-top:5px;margin-left:auto}.mini span{display:block;height:100%}
.empty{padding:22px 12px;border:1px dashed rgba(255,255,255,.08);text-align:center;color:#697483;font-size:clamp(7px,.5vw,10px);font-weight:800;line-height:1.7}
.head{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:16px;align-items:start}.serialBig{font-family:var(--fontTitle);font-size:clamp(28px,2.6vw,52px);letter-spacing:.06em;line-height:.95}.nameLine{margin-top:4px;color:#ffe3a2;font-size:clamp(8px,.65vw,13px);font-weight:900;letter-spacing:.04em;text-transform:uppercase}.subLine{margin-top:4px;color:var(--muted);font-size:clamp(6px,.48vw,9px);font-weight:700;line-height:1.6}
.pill{display:inline-flex;align-items:center;gap:5px;padding:4px 8px;border:1px solid rgba(255,255,255,.12);font-size:clamp(5px,.42vw,8px);font-weight:900;letter-spacing:.1em;text-transform:uppercase;color:#cfd7e2}.pill.ok{border-color:rgba(119,196,170,.5);color:var(--good)}.pill.bad{border-color:rgba(224,122,106,.5);color:var(--bad)}.pill.gold{border-color:rgba(255,190,50,.6);color:#ffe3a2}
.bars{display:grid;grid-template-columns:1fr 1fr;gap:12px 20px}.bar .lbl{display:flex;justify-content:space-between;color:var(--muted);font-size:clamp(6px,.45vw,9px);font-weight:900;letter-spacing:.06em;text-transform:uppercase}.bar .lbl b{color:#e6ebf2;font-family:var(--fontTitle);font-size:clamp(14px,1vw,20px);letter-spacing:.05em}.bar .track{height:4px;margin-top:4px;background:rgba(255,255,255,.07)}.bar .track span{display:block;height:100%}
.stats{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:8px}.stat{padding:8px;border:1px solid rgba(255,255,255,.06);background:rgba(0,0,0,.18)}.stat .v{font-family:var(--fontTitle);font-size:clamp(16px,1.3vw,26px);letter-spacing:.05em}.stat .k{color:var(--muted);font-size:clamp(5px,.4vw,8px);font-weight:900;letter-spacing:.08em;text-transform:uppercase}
.badges{display:flex;flex-wrap:wrap;gap:6px}.badge{display:flex;align-items:center;gap:7px;padding:6px 9px;border:1px solid rgba(255,255,255,.07);background:rgba(0,0,0,.2);color:#5f6a7a;font-size:clamp(6px,.45vw,9px);font-weight:900;text-transform:uppercase}.badge.on{color:#ffe3a2;border-color:rgba(255,190,50,.45);background:rgba(60,44,10,.35)}.badge small{color:#8a95a6;font-weight:700;text-transform:none}
.form{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.input{flex:1 1 120px;min-width:0;padding:9px 10px;border:1px solid rgba(255,255,255,.1);background:rgba(0,0,0,.3);font-size:clamp(7px,.55vw,11px);font-weight:700;color:#eef2f7}select.input{appearance:none}select.input option{background:#0c1118}
.btn{min-height:clamp(32px,3.8vh,44px);padding:0 clamp(10px,.8vw,14px);display:inline-flex;align-items:center;gap:8px;border:1px solid rgba(255,255,255,.08);background:linear-gradient(115deg,rgba(9,16,28,.86),rgba(8,14,24,.54));color:#c3ccd8;font-size:clamp(6px,.5vw,10px);font-weight:900;text-transform:uppercase;letter-spacing:.06em;transition:.14s}.btn:hover{border-color:rgba(255,190,50,.42);color:#fff}.btn.primary{border-color:rgba(255,190,50,.55);background:linear-gradient(115deg,rgba(60,44,10,.70),rgba(20,16,8,.55));color:#ffe3a2}.btn.danger{border-color:rgba(224,122,106,.45);color:#f0a99d}.btn[disabled]{opacity:.35;pointer-events:none}
.actions{display:flex;gap:var(--gap);flex-wrap:wrap}
.timeline{position:relative;padding-left:16px}.timeline:before{content:"";position:absolute;left:4px;top:4px;bottom:4px;width:1px;background:rgba(255,190,50,.35)}.tlItem{position:relative;padding:6px 0 10px}.tlItem:before{content:"";position:absolute;left:-15px;top:10px;width:7px;height:7px;border:1px solid var(--yellow);background:#0b0f14}.tlItem.cur:before{background:var(--yellow);box-shadow:0 0 8px rgba(255,190,50,.6)}
.tlName{font-size:clamp(7px,.58vw,11px);font-weight:900;text-transform:uppercase}.tlSub{margin-top:2px;color:var(--muted);font-size:clamp(6px,.45vw,9px);font-weight:700}
.logRow{display:grid;grid-template-columns:clamp(64px,5.6vw,104px) minmax(0,1fr);gap:10px;padding:6px 0;border-bottom:1px solid rgba(255,255,255,.04);font-size:clamp(6px,.48vw,9px)}.logRow .t{color:#5f6a7a;font-weight:800}.logRow .x{color:#c9d2de;font-weight:700;line-height:1.45}.logRow .x b{color:#ffe3a2}
.footer{position:absolute;left:0;right:0;bottom:0;height:var(--footer);display:flex;align-items:center;gap:14px;padding:0 var(--sidePad);background:linear-gradient(90deg,rgba(255,190,50,.08),rgba(255,190,50,.15),rgba(14,18,23,.58));border-top:1px solid rgba(255,190,50,.10)}.footerText{color:#aeb8c6;font-size:clamp(5px,.42vw,8px);font-weight:800;text-transform:uppercase}.footerLegend{margin-left:auto;display:flex;align-items:center;gap:8px}.key{min-width:clamp(24px,1.8vw,34px);height:clamp(22px,1.8vw,31px);padding:0 6px;display:grid;place-items:center;border:1px solid rgba(230,235,243,.45);color:#eef2f7;font-size:clamp(5px,.4vw,8px)}
.toast{position:absolute;left:50%;top:calc(var(--header) + 8px);transform:translate(-50%,-8px);padding:9px 14px;z-index:90;background:rgba(7,12,20,.95);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;font-size:10px;font-weight:700;opacity:0;pointer-events:none;transition:opacity .16s,transform .16s}.toast.show{opacity:1;transform:translate(-50%,0)}.toast.ok{border-color:rgba(119,196,170,.5)}.toast.bad{border-color:rgba(224,122,106,.5)}
.vgrid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:var(--gap)}.vcard{position:relative;padding:14px;min-height:clamp(120px,16vh,190px);border:1px solid rgba(255,190,50,.35);background:linear-gradient(160deg,rgba(60,44,10,.30),rgba(8,11,15,.6));text-align:left}.vcard:hover{border-color:rgba(255,190,50,.8)}.vcard .vt{font-family:var(--fontTitle);font-size:clamp(20px,1.7vw,34px);letter-spacing:.05em;color:#ffe3a2;line-height:1}.vcard .vs{margin-top:6px;color:#c9d2de;font-size:clamp(6px,.48vw,9px);font-weight:800}
.hint{color:#697483;font-size:clamp(6px,.45vw,9px);font-weight:700;line-height:1.6}
@media(max-height:760px){:root{--header:56px;--footer:38px}.stats{grid-template-columns:repeat(3,minmax(0,1fr))}}
</style>
</head>
<body>
<div class="shell"><div class="hudCorner tl"></div><div class="hudCorner tr"></div><div class="hudCorner bl"></div><div class="hudCorner br"></div><main class="app">
<header class="topbar">
 <div class="titleBlock"><div style="min-width:0"><div class="kicker" id="kicker">WAFFENAKTE</div><div class="mainTitle" id="title">WAFFENPASS</div></div><div class="titleLine"></div></div>
 <div class="topInfo"><div class="userBlock"><div class="kicker" id="date">-- / -- / ----</div><div class="userName">ECHOES OF CLONES</div></div><button class="iconBtn hidden" id="backBtn" onclick="UI.back()"><i class="fa-solid fa-arrow-left"></i></button><button class="iconBtn" onclick="UI.close()"><i class="fa-solid fa-xmark"></i></button></div>
</header>
<section class="content" id="content"></section>
<footer class="footer"><div class="footerText" id="footerText">ECHOES OF CLONES · WAFFENAKTE</div><div class="footerLegend"><span class="key">ESC</span><span class="footerText">SCHLIESSEN</span></div></footer>
<div class="toast" id="toast"></div>
</main></div>
<script>
(function(){
  var D={};var stack=[];var tab={};var sel=null;var filter={q:"",low:false};
  function esc(v){return String(v==null?"":v).replace(/[&<>"']/g,function(c){return({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[c]})}
  function $(id){return document.getElementById(id)}
  function sfx(k){try{grnWS.uiSound(String(k))}catch(e){}}
  function req(a,d){try{grnWS.request(a,JSON.stringify(d||{}))}catch(e){}}
  function pad(n){return n<10?"0"+n:""+n}
  function fdate(ts){if(!ts)return "—";var d=new Date(ts*1000);return pad(d.getDate())+"."+pad(d.getMonth()+1)+"."+d.getFullYear()}
  function ftime(ts){if(!ts)return "—";var d=new Date(ts*1000);return fdate(ts)+" "+pad(d.getHours())+":"+pad(d.getMinutes())}
  function condColor(c){return c>=80?"var(--good)":(c>=50?"#c9d27a":(c>=25?"var(--warn)":"var(--bad)"))}
  function dirtColor(c){return c<30?"var(--good)":(c<60?"var(--warn)":"var(--bad)")}
  function statusPill(w){var cls=w.status==="STORED"?"ok":(w.status==="BROKEN"||w.status==="CAPTURED"||w.status==="RETIRED"?"bad":"");return '<span class="pill '+cls+'">'+esc(w.statusLabel)+'</span>'}
  function row(w,extra){var on=sel===w.serial;return '<button class="row'+(on?' on':'')+(w.tradition?' trad':'')+'" data-serial="'+esc(w.serial)+'"><div style="min-width:0"><div class="rName">'+(w.tradition?'<i class="fa-solid fa-crown" style="color:var(--yellow)"></i> ':'')+esc(w.name)+'</div><div class="rSub"><b>'+esc(w.serial)+'</b> · '+esc(w.label)+(extra?' · '+extra:'')+'</div></div><div class="rRight">'+Math.round(w.condition)+' %<div class="mini"><span style="width:'+w.condition+'%;background:'+condColor(w.condition)+'"></span></div></div></button>'}
  function bindRows(root,fn){var r=root.querySelectorAll(".row[data-serial]");for(var i=0;i<r.length;i++){r[i].addEventListener("click",function(){sfx("click");fn(this.getAttribute("data-serial"))});r[i].addEventListener("dblclick",function(){openDossier(this.getAttribute("data-serial"))});r[i].addEventListener("mouseenter",function(){sfx("hover")})}}
  function openDossier(serial){req("pass",{serial:serial,back:D.mode})}
  function bar(label,val,color,suffix){return '<div class="bar"><div class="lbl">'+esc(label)+'<b>'+esc(val)+(suffix||"")+'</b></div><div class="track"><span style="width:'+Math.max(0,Math.min(100,val))+'%;background:'+color+'"></span></div></div>'}
  function stat(k,v){return '<div class="stat"><div class="v">'+esc(v)+'</div><div class="k">'+esc(k)+'</div></div>'}
  function setHead(kicker,title,foot){$("kicker").textContent=kicker;$("title").textContent=title;$("footerText").textContent="ECHOES OF CLONES · "+(foot||title)}
  var EV={created:function(d){return "Waffe erstellt"+(d.regiment?" für <b>"+esc(d.regiment)+"</b>":"")},issue:function(d){return "Ausgabe an <b>"+esc(d.name)+"</b>"},"return":function(d){return "In die Waffenkammer zurückgegeben"},auto_return:function(d){return "Automatisch in die Kammer ("+esc(d.reason||"")+")"},owner:function(d){return "Neuer Träger <b>"+esc(d.name)+"</b> – "+esc(d.how||"")},dropped:function(d){return "<b>"+esc(d.name)+"</b> hat die Waffe abgelegt"},broken:function(d){return "Zustand 0 % – blockiert nach "+esc(d.rounds)+" Schuss"},teamkill:function(d){return "VORFALL: Teamkill durch <b>"+esc(d.name)+"</b> an "+esc(d.victim)},nickname:function(d){return "Spitzname "+(d.nickname?"„<b>"+esc(d.nickname)+"</b>“":"entfernt")+" von "+esc(d.name)},tradition:function(d){return "Zur Traditionswaffe ernannt: „<b>"+esc(d.honor)+"</b>“"},tradition_proposed:function(d){return "Als Traditionswaffe vorgeschlagen von <b>"+esc(d.name)+"</b> („"+esc(d.honor)+"“)"},tradition_rejected:function(d){return "Traditions-Vorschlag abgelehnt ("+esc(d.name)+")"},ceremony:function(d){return "Übergabe-Zeremonie: <b>"+esc(d.from)+"</b> → <b>"+esc(d.to)+"</b> (Offizier "+esc(d.officer)+")"},retired:function(d){return "Ausgemustert von "+esc(d.name)},admin:function(d){return "Admin-Änderung durch "+esc(d.name)+(d.rollback?" (Rollback: "+d.rollback+" Kills)":"")},milestone:function(d){return "Meilenstein „<b>"+esc(d.name)+"</b>“"},kill:function(d){return "<b>"+esc(d.name)+"</b> → "+esc(d.victim)+" · "+esc(d.dist)+" m · "+esc(d.map)},death:function(d){return "Träger <b>"+esc(d.name)+"</b> gefallen durch "+esc(d.killer)+" · "+esc(d.map)},recovered:function(d){return "Geborgen: <b>"+esc(d.name)+"</b> wurde wiederbelebt"},repair:function(d){return "Reparatur durch <b>"+esc(d.name)+"</b>: "+esc(d.before)+" % → "+esc(d.after)+" % ("+esc(d.parts)+" Teile)"},clean:function(d){return "Gereinigt von <b>"+esc(d.name)+"</b> (Schmutz "+esc(d.before)+" → 0)"},barrel:function(d){return "Laufwechsel durch <b>"+esc(d.name)+"</b> nach "+esc(d.rounds)+" Schuss"}};
  function logList(list){if(!list||!list.length)return '<div class="empty">KEINE EINTRÄGE</div>';var h="";for(var i=0;i<list.length;i++){var e=list[i];var f=EV[e.type];h+='<div class="logRow"><div class="t">'+ftime(e.ts)+'</div><div class="x">'+(f?f(e.data||{}):esc(e.type))+'</div></div>'}return h}

  // ---------------- Waffenpass / Akte ----------------
  function renderDossier(){
    var w=D;setHead("WAFFENPASS · "+(w.regimentName||""),w.tradition?(w.honor||w.name):w.name,"WAFFENPASS");
    var nick=w.canNick?'<div class="frame"><div class="kicker">SPITZNAME</div><div class="form" style="margin-top:8px"><input class="input" id="nickIn" maxlength="24" placeholder="max. 24 Zeichen" value="'+esc(w.nickname||"")+'"><button class="btn primary" onclick="UI.setNick()" '+(w.now<w.nickReadyAt?'disabled':'')+'><i class="fa-solid fa-pen"></i>SETZEN</button></div>'+(w.now<w.nickReadyAt?'<div class="hint" style="margin-top:6px">Wieder änderbar ab '+ftime(w.nickReadyAt)+'</div>':'')+'</div>':'';
    var admin="";if(w.isAdmin){var opts="";["STORED","ISSUED","DROPPED","CAPTURED","BROKEN","RETIRED"].forEach(function(s){opts+='<option value="'+s+'"'+(s===w.status?' selected':'')+'>'+s+'</option>'});
      admin='<div class="frame"><div class="kicker">ADMIN · WERTE KORRIGIEREN</div><div class="form" style="margin-top:8px"><input class="input" id="adCond" type="number" min="0" max="100" value="'+w.condition+'" title="Zustand"><input class="input" id="adDirt" type="number" min="0" max="100" value="'+w.dirt+'" title="Verschmutzung"><select class="input" id="adStatus">'+opts+'</select></div><div class="form" style="margin-top:8px"><input class="input" id="adNick" placeholder="Spitzname" value="'+esc(w.nickname||"")+'"><button class="btn primary" onclick="UI.adminSave()"><i class="fa-solid fa-floppy-disk"></i>SPEICHERN</button><button class="btn" onclick="UI.adminSave(\'lock\')"><i class="fa-solid fa-lock'+(w.locked?'-open':'')+'"></i>'+(w.locked?'ENTSPERREN':'SPERREN')+'</button><button class="btn danger" onclick="UI.adminSave(\'reset\')"><i class="fa-solid fa-rotate"></i>ZURÜCKSETZEN</button>'+(w.tradition?'<button class="btn danger" onclick="UI.adminSave(\'untrad\')">TRADITION ENTZIEHEN</button>':'')+'</div></div>'}
    var ms="";(w.milestones||[]).forEach(function(m){ms+='<div class="badge'+(m.reached?' on':'')+'" title="'+esc(m.reached?("Erreicht "+fdate(m.ts)+(m.holder?" · "+m.holder:"")):"Noch nicht erreicht")+'"><i class="fa-solid '+esc(m.icon||"fa-award")+'"></i>'+esc(m.name)+(m.reached&&m.engraving?' <small>Gravur „'+esc(m.engraving)+'“</small>':'')+'</div>'});
    var left='<div class="col"><div class="frame"><div class="head"><div style="min-width:0"><div class="kicker">SERIENNUMMER'+(w.valid?' · <span style="color:var(--good)">PRÜFZIFFER OK</span>':' · <span style="color:var(--bad)">PRÜFZIFFER UNGÜLTIG</span>')+'</div><div class="serialBig">'+esc(w.serial)+'</div><div class="nameLine">'+(w.tradition?'<i class="fa-solid fa-crown"></i> '+esc(w.honor):(w.nickname?'„'+esc(w.nickname)+'“':esc(w.label)))+'</div><div class="subLine">'+esc(w.label)+' · erstellt '+fdate(w.created)+(w.batch?' · Charge '+esc(w.batch):'')+'<br>'+esc(w.regimentName)+(w.owner?' · Träger: <b style="color:#dce4ee">'+esc(w.owner)+'</b>':'')+'</div></div><div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end">'+statusPill(w)+'<span class="pill">'+esc(w.tier)+'</span>'+(w.tradition?'<span class="pill gold">TRADITION</span>':'')+(w.locked?'<span class="pill bad">GESPERRT</span>':'')+'</div></div></div>'
      +'<div class="frame"><div class="bars">'+bar("Zustand",Math.round(w.condition),condColor(w.condition)," %")+bar("Verschmutzung",Math.round(w.dirt),dirtColor(w.dirt))+'</div><div class="stats" style="margin-top:12px">'+stat("Schuss",w.rounds)+stat("Kills",w.kills)+stat("Weitester Treffer",Math.round(w.longest||0)+" m")+stat("Träger",w.holderCount||0)+stat("Lauf (Schuss)",w.barrelRounds||0)+'</div></div>'
      +'<div class="frame"><div class="kicker">MEILENSTEINE</div><div class="badges" style="margin-top:8px">'+ms+'</div></div>'+nick+admin+'</div>';
    var tabs=[["holders","BESITZERKETTE",(w.holders||[]).length],["killLog","KILLS",(w.killLog||[]).length],["deaths","TODE",(w.deaths||[]).length],["service","WARTUNG",(w.service||[]).length],["log","PROTOKOLL",(w.log||[]).length]];
    var t=tab.dossier||"holders";var th="";tabs.forEach(function(x){th+='<button class="tab'+(t===x[0]?' on':'')+'" data-tab="'+x[0]+'">'+x[1]+'<span class="n">'+x[2]+'</span></button>'});
    var body="";
    if(t==="holders"){var hs=w.holders||[];if(!hs.length)body='<div class="empty">NOCH KEIN TRÄGER</div>';else{body='<div class="timeline">';for(var i=hs.length-1;i>=0;i--){var h=hs[i];body+='<div class="tlItem'+(!h.to?' cur':'')+'"><div class="tlName">'+esc(h.name)+'</div><div class="tlSub">'+fdate(h.from)+' – '+(h.to?fdate(h.to):'heute')+' · '+h.kills+' Kills'+(h.ended?' · '+esc(h.ended):'')+'</div></div>'}body+='</div>'}}
    else body=logList(w[t]);
    var right='<div class="col"><div class="frame grow"><div class="toolbar">'+th+'</div><div class="scroll" id="tabBody">'+body+'</div></div></div>';
    $("content").innerHTML=left+right;
    var tb=document.querySelectorAll(".tab[data-tab]");for(var j=0;j<tb.length;j++)tb[j].addEventListener("click",function(){sfx("click");tab.dossier=this.getAttribute("data-tab");renderDossier()});
  }

  // ---------------- Waffenkammer-Terminal ----------------
  function listFor(k){var l=D[k]||[];var q=filter.q.toLowerCase();return l.filter(function(w){if(filter.low&&w.condition>=50)return false;if(!q)return true;return (w.serial+" "+w.name+" "+w.label+" "+(w.owner||"")).toLowerCase().indexOf(q)>=0})}
  function findW(serial){var keys=["stored","issued","tradition","archive","proposals","queue","results"];for(var i=0;i<keys.length;i++){var l=D[keys[i]]||[];for(var j=0;j<l.length;j++)if(l[j].serial===serial)return l[j]}if(D.inHand&&D.inHand.serial===serial)return D.inHand;return null}
  function renderTerminal(){
    setHead("WAFFENKAMMER-TERMINAL",D.regimentName||"WAFFENKAMMER","WAFFENKAMMER-TERMINAL");
    var t=tab.terminal||"stored";var tabs=[["stored","BESTAND"],["issued","AUSGEGEBEN"],["tradition","TRADITION"],["proposals","VORSCHLÄGE"],["archive","ARCHIV"]];
    var th="";tabs.forEach(function(x){th+='<button class="tab'+(t===x[0]?' on':'')+'" data-tab="'+x[0]+'">'+x[1]+'<span class="n">'+(D[x[0]]||[]).length+'</span></button>'});
    var reg="";if(D.isAdmin&&D.regiments&&D.regiments.length){reg='<select class="input" id="regSel" style="flex:0 0 auto;width:auto">';D.regiments.forEach(function(r){reg+='<option value="'+esc(r.id)+'"'+(r.id===D.regiment?' selected':'')+'>'+esc(r.name)+'</option>'});reg+='</select>'}
    var list=listFor(t);var h="";
    if(!list.length)h='<div class="empty">'+(t==="issued"?"KEINE AUSGEGEBENEN WAFFEN":"KEINE EINTRÄGE")+'</div>';
    list.forEach(function(w){var extra=t==="issued"?((w.owner||"?")+(w.ownerOnline?(w.ownerAlive?"":" · <span style=\"color:var(--bad)\">gefallen</span>"):" · <span style=\"color:var(--bad)\">offline – vermisst</span>")):(t==="proposals"?"„"+esc(w.proposedHonor)+"“ von "+esc(w.proposedBy):esc(w.statusLabel));h+=row(w,extra)});
    var left='<div class="col"><div><div class="kicker">REGIMENT</div><div class="sectionTitle">'+esc(D.regimentName)+'</div></div><div class="frame grow"><div class="toolbar">'+th+'<div class="search"><i class="fa-solid fa-magnifying-glass"></i><input id="q" placeholder="Seriennummer, Name …" value="'+esc(filter.q)+'"></div><div class="chk'+(filter.low?' on':'')+'" id="low"><i class="fa-solid fa-'+(filter.low?'square-check':'square')+'"></i>UNTER 50 %</div>'+reg+'</div><div class="scroll" id="list">'+h+'</div></div></div>';
    var w=sel&&findW(sel);var right;
    if(!w){var ch="";(D.chronicle||[]).forEach(function(c){ch+='<div class="logRow"><div class="t">'+fdate(c.ts)+'</div><div class="x">'+esc(c.text)+'</div></div>'});right='<div class="col"><div><div class="kicker">REGIMENTSCHRONIK</div><div class="sectionTitle">CHRONIK</div></div><div class="frame grow"><div class="scroll">'+(ch||'<div class="empty">NOCH KEINE EINTRÄGE</div>')+'</div></div><div class="hint">Wähle links eine Waffe. Doppelklick öffnet die Akte. Traditionswaffen: höchstens '+D.maxTradition+' pro Regiment.</div></div>'}
    else{
      var acts='<button class="btn" onclick="UI.dossier()"><i class="fa-solid fa-folder-open"></i>AKTE</button>';
      if(w.status==="STORED"&&!w.tradition&&D.issuable&&D.issuable[w.class])acts+='<button class="btn primary" onclick="UI.take()"><i class="fa-solid fa-hand-holding"></i>DIESE WAFFE NEHMEN</button>';
      var trad="";
      if(D.canPropose&&!w.tradition&&t!=="proposals"&&w.status!=="RETIRED")trad='<div class="frame"><div class="kicker">ALS TRADITIONSWAFFE VORSCHLAGEN</div><div class="hint" style="margin-top:4px">Voraussetzungen: 30 Tage alt, mindestens ein Meilenstein, Zustand über 50 %.</div><div class="form" style="margin-top:8px"><input class="input" id="honor" maxlength="24" placeholder="Ehrenname, z. B. Eiserne Wache"><button class="btn primary" onclick="UI.propose()"><i class="fa-solid fa-crown"></i>VORSCHLAGEN</button></div></div>';
      if(t==="proposals"&&D.canConfirm)trad='<div class="frame"><div class="kicker">REGIMENTSFÜHRUNG</div><div class="subLine">Vorschlag „<b style="color:#ffe3a2">'+esc(w.proposedHonor)+'</b>“ von '+esc(w.proposedBy)+' ('+fdate(w.proposedAt)+')</div><div class="actions" style="margin-top:8px"><button class="btn primary" onclick="UI.confirm(true)"><i class="fa-solid fa-check"></i>BESTÄTIGEN</button><button class="btn danger" onclick="UI.confirm(false)"><i class="fa-solid fa-xmark"></i>ABLEHNEN</button></div></div>';
      if(w.tradition&&D.canPropose){var o="";(D.nearby||[]).forEach(function(p){o+='<option value="'+esc(p.sid)+'">'+esc(p.name)+'</option>'});trad='<div class="frame"><div class="kicker">ÜBERGABE-ZEREMONIE</div><div class="hint" style="margin-top:4px">Alter und neuer Träger stehen im Umkreis von 3 m. Die Übergabe wird angekündigt und in die Chronik eingetragen.</div><div class="form" style="margin-top:8px">'+(o?'<select class="input" id="target">'+o+'</select><button class="btn primary" onclick="UI.ceremony()"><i class="fa-solid fa-people-arrows"></i>ÜBERGEBEN</button>':'<div class="hint">Niemand in der Nähe.</div>')+'</div></div>'}
      right='<div class="col"><div><div class="kicker">AUSWAHL · '+esc(w.statusLabel)+'</div><div class="sectionTitle">'+esc(w.name)+'</div></div><div class="frame"><div class="subLine"><b style="color:#dce4ee">'+esc(w.serial)+'</b> · '+esc(w.label)+' · erstellt '+fdate(w.created)+(w.owner?' · Träger '+esc(w.owner):'')+'</div><div class="bars" style="margin-top:10px">'+bar("Zustand",Math.round(w.condition),condColor(w.condition)," %")+bar("Verschmutzung",Math.round(w.dirt),dirtColor(w.dirt))+'</div><div class="stats" style="grid-template-columns:repeat(3,1fr);margin-top:10px">'+stat("Kills",w.kills)+stat("Schuss",w.rounds)+stat("Zustand",w.tier)+'</div></div><div class="actions">'+acts+'</div>'+trad+'</div>';
    }
    $("content").innerHTML=left+right;
    var tb=document.querySelectorAll(".tab[data-tab]");for(var j=0;j<tb.length;j++)tb[j].addEventListener("click",function(){sfx("click");tab.terminal=this.getAttribute("data-tab");sel=null;renderTerminal()});
    bindRows($("list"),function(s){sel=sel===s?null:s;render()});
    var q=$("q");q.addEventListener("input",function(){filter.q=this.value;var pos=this.selectionStart;renderTerminal();var n=$("q");n.focus();try{n.setSelectionRange(pos,pos)}catch(e){}});
    $("low").addEventListener("click",function(){filter.low=!filter.low;renderTerminal()});
    var rs=$("regSel");if(rs)rs.addEventListener("change",function(){sel=null;req("terminal_regiment",{regiment:this.value})});
  }

  // ---------------- Werkbank ----------------
  function renderBench(){
    setHead("WERKBANK · "+(D.regimentName||""),"WAFFENMEISTER","WERKBANK");
    var h="";if(D.inHand)h+='<div class="kicker" style="margin:2px 0 4px">IN DER HAND</div>'+row(D.inHand,esc(D.inHand.statusLabel));
    h+='<div class="kicker" style="margin:10px 0 4px">REGIMENTSKAMMER · UNTER 100 %</div>';
    if(!(D.queue||[]).length)h+='<div class="empty">ALLE EINGELAGERTEN WAFFEN SIND EINSATZBEREIT</div>';(D.queue||[]).forEach(function(w){h+=row(w,esc(w.statusLabel))});
    var left='<div class="col"><div><div class="kicker">REPARATUR · REINIGUNG · LAUFWECHSEL</div><div class="sectionTitle">WERKBANK</div></div><div class="frame grow"><div class="toolbar"><div class="tab on">WAFFEN</div><div class="search" style="cursor:default"><i class="fa-solid fa-gears"></i><b style="color:#eef2f7">'+D.parts+'</b>&nbsp;ERSATZTEILE</div></div><div class="scroll" id="list">'+h+'</div></div>'+(!D.isArmorer?'<div class="hint"><i class="fa-solid fa-lock"></i> Reparaturen darf nur der Waffenmeister durchführen.</div>':'')+'</div>';
    var w=sel&&findW(sel);var right;
    if(!w)right='<div class="col"><div><div class="kicker">AUSWAHL</div><div class="sectionTitle">KEINE WAFFE</div></div><div class="frame"><div class="hint">Wähle links eine Waffe. Reparatur kostet 1 Ersatzteil je angefangene 25 % Schaden, ein Laufwechsel '+D.barrelParts+' Teile (nur MGs und schwere Waffen). Reinigungssets benutzt jeder selbst aus dem Inventar.</div></div></div>';
    else right='<div class="col"><div><div class="kicker">AUSWAHL · '+esc(w.statusLabel)+'</div><div class="sectionTitle">'+esc(w.name)+'</div></div><div class="frame"><div class="subLine"><b style="color:#dce4ee">'+esc(w.serial)+'</b> · '+esc(w.label)+'</div><div class="bars" style="margin-top:10px">'+bar("Zustand",Math.round(w.condition),condColor(w.condition)," %")+bar("Verschmutzung",Math.round(w.dirt),dirtColor(w.dirt))+'</div></div><div class="actions"><button class="btn primary" onclick="UI.bench(\'repair\')" '+(D.isArmorer&&w.condition<100?'':'disabled')+'><i class="fa-solid fa-screwdriver-wrench"></i>REPARIEREN ('+w.repairCost+' TEILE)</button>'+(w.canBarrel?'<button class="btn" onclick="UI.bench(\'barrel\')" '+(D.isArmorer?'':'disabled')+'><i class="fa-solid fa-arrows-rotate"></i>LAUFWECHSEL</button>':'')+'<button class="btn" onclick="UI.dossier()"><i class="fa-solid fa-folder-open"></i>AKTE</button>'+((D.isArmorer||D.isAdmin)&&w.status!=="ISSUED"?'<button class="btn danger" onclick="UI.bench(\'retire\')"><i class="fa-solid fa-box-archive"></i>AUSMUSTERN</button>':'')+'</div></div>';
    $("content").innerHTML=left+right;bindRows($("list"),function(s){sel=s;render()});
  }

  // ---------------- Vitrine / Chronik ----------------
  function renderVitrine(){
    setHead("VITRINE · "+(D.regimentName||""),"TRADITIONSWAFFEN","VITRINE");
    var g="";(D.tradition||[]).forEach(function(w){g+='<button class="vcard" data-serial="'+esc(w.serial)+'"><div class="kicker">'+esc(w.label)+'</div><div class="vt" style="margin-top:6px">'+esc(w.honor||w.name)+'</div><div class="vs">'+esc(w.serial)+'</div><div class="vs">'+w.kills+' Kills · '+esc(w.statusLabel)+(w.owner?' · '+esc(w.owner):'')+'</div></button>'});
    var ch="";(D.chronicle||[]).forEach(function(c){ch+='<div class="logRow"><div class="t">'+fdate(c.ts)+'</div><div class="x">'+esc(c.text)+'</div></div>'});
    $("content").innerHTML='<div class="col"><div><div class="kicker">'+esc(D.regimentName)+'</div><div class="sectionTitle">EHRENWAFFEN</div></div><div class="frame grow"><div class="scroll"><div class="vgrid">'+(g||'<div class="empty" style="grid-column:1/-1">DAS REGIMENT HAT NOCH KEINE TRADITIONSWAFFE</div>')+'</div></div></div></div><div class="col"><div><div class="kicker">REGIMENTSCHRONIK</div><div class="sectionTitle">CHRONIK</div></div><div class="frame grow"><div class="scroll">'+(ch||'<div class="empty">NOCH KEINE EINTRÄGE</div>')+'</div></div></div>';
    var c=document.querySelectorAll(".vcard");for(var i=0;i<c.length;i++)c[i].addEventListener("click",function(){openDossier(this.getAttribute("data-serial"))});
  }

  // ---------------- Admin ----------------
  function renderAdmin(){
    setHead("ADMIN-PANEL","WAFFENREGISTER","ADMIN");
    var h="";(D.results||[]).forEach(function(w){h+=row(w,esc(w.statusLabel)+(w.owner?" · "+esc(w.owner):""))});
    $("content").innerHTML='<div class="col"><div><div class="kicker">SUCHE NACH SERIENNUMMER, NAME, TRÄGER ODER STEAMID64</div><div class="sectionTitle">REGISTER</div></div><div class="frame grow"><div class="toolbar"><div class="form" style="flex:1"><input class="input" id="aq" placeholder="z. B. BTA-26-000042-7" value="'+esc(D.query||"")+'"><button class="btn primary" onclick="UI.search()"><i class="fa-solid fa-magnifying-glass"></i>SUCHEN</button></div></div><div class="scroll" id="list">'+(h||'<div class="empty">KEINE TREFFER</div>')+'</div></div></div><div class="col"><div><div class="kicker">NACH EINEM EXPLOIT</div><div class="sectionTitle">ROLLBACK</div></div><div class="frame"><div class="hint">Entfernt alle Kills und Meilensteine eines Spielers ab dem gewählten Zeitpunkt und korrigiert die Summen der Waffen.</div><div class="form" style="margin-top:10px"><input class="input" id="rbSid" placeholder="SteamID64 oder STEAM_0:…"><input class="input" id="rbH" type="number" min="1" value="24" style="flex:0 0 90px" title="Stunden zurück"><button class="btn danger" onclick="UI.rollback()"><i class="fa-solid fa-clock-rotate-left"></i>ROLLBACK</button></div></div><div class="hint">Klick auf eine Waffe öffnet die Akte mit allen Korrektur-Funktionen.</div></div>';
    bindRows($("list"),function(s){openDossier(s)});
    $("aq").addEventListener("keydown",function(e){if(e.key==="Enter")UI.search()});
  }

  function render(){
    $("date").textContent=fdate(D.now||Math.floor(Date.now()/1000)).replace(/\./g," / ");
    $("backBtn").classList.toggle("hidden",!stack.length);
    if(D.mode==="dossier")renderDossier();else if(D.mode==="terminal")renderTerminal();else if(D.mode==="bench")renderBench();else if(D.mode==="vitrine"||D.mode==="chronicle"){D.tradition=D.tradition||[];renderVitrine()}else if(D.mode==="admin")renderAdmin();
  }
  function toast(ok,m){var el=$("toast");el.textContent=String(m||"");el.className="toast show "+(ok?"ok":"bad");sfx(ok?"equip":"error");clearTimeout(toast._t);toast._t=setTimeout(function(){el.className="toast"},2200)}
  window.UI={
    setData:function(d){if(!d||typeof d!=="object")return;if(d.mode==="dossier"&&D.mode&&D.mode!=="dossier"&&d.back)stack.push(D);else if(d.mode!=="dossier")stack=[];D=d;render()},
    toast:toast,
    close:function(){sfx("close");try{grnWS.close()}catch(e){}},
    back:function(){if(!stack.length)return;D=stack.pop();sfx("click");req(D.mode==="admin"?"admin_search":"station",D.mode==="admin"?{query:D.query||""}:{});render()},
    dossier:function(){if(sel)openDossier(sel)},
    setNick:function(){req("nick",{serial:D.serial,nick:$("nickIn").value})},
    take:function(){req("take",{serial:sel})},
    propose:function(){req("propose",{serial:sel,honor:$("honor").value})},
    confirm:function(a){req("confirm",{serial:sel,accept:a})},
    ceremony:function(){var t=$("target");if(t)req("ceremony",{serial:sel,target:t.value})},
    bench:function(a){if(a==="retire"){var now=Date.now();if(!UI._armed||now-UI._armed>3000){UI._armed=now;toast(false,"Zum Ausmustern erneut klicken.");return}UI._armed=0}req(a,{serial:sel})},
    search:function(){req("admin_search",{query:$("aq").value})},
    rollback:function(){var s=$("rbSid").value;if(!s)return;req("admin_rollback",{sid64:s,hours:parseFloat($("rbH").value)||1})},
    adminSave:function(kind){var f={};if(kind==="lock")f.locked=!D.locked;else if(kind==="reset")f.reset=true;else if(kind==="untrad")f.tradition=false;else{f.condition=parseFloat($("adCond").value);f.dirt=parseFloat($("adDirt").value);f.status=$("adStatus").value;f.nickname=$("adNick").value}req("admin_edit",{serial:D.serial,fields:f})}
  };
  document.addEventListener("keydown",function(ev){if(ev.key==="Escape"){ev.preventDefault();UI.close()}});
  try{grnWS.ready()}catch(e){}
})();
</script>
</body>
</html>
]==]
