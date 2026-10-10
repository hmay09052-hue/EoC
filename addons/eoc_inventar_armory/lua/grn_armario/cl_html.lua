GRNWeaponrio = GRNWeaponrio or {}

function GRNWeaponrio.GetHTML()
return [==[
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<title>Echoes of Clones · Formato</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
html,body{margin:0;padding:0;width:100vw;height:100vh;min-width:100vw;min-height:100vh;overflow:hidden;background:transparent}
body{font-family:"Montserrat",Arial,sans-serif;color:#f4f7fb;-webkit-user-select:none;user-select:none}
button,input{font:inherit;color:inherit}
button{border:0;outline:0;background:none;cursor:pointer}
*{box-sizing:border-box}
.shell{position:fixed;left:0;top:0;width:100vw;height:100vh;min-width:100vw;min-height:100vh;overflow:hidden;background:
  radial-gradient(circle at 78% 54%, rgba(77,128,202,.10), transparent 28%),
  radial-gradient(circle at 42% 120%, rgba(55,100,160,.28), transparent 54%),
  linear-gradient(125deg, rgba(10,18,30,.985), rgba(6,11,18,.985) 52%, rgba(5,10,17,.995));}
.shell:before{content:"";position:absolute;left:0;top:0;right:0;bottom:0;pointer-events:none;opacity:.28;background-image:
  linear-gradient(rgba(255,255,255,.014) 1px,transparent 1px),
  linear-gradient(90deg,rgba(255,255,255,.014) 1px,transparent 1px),
  radial-gradient(circle,rgba(255,255,255,.40) 0 1px,transparent 1.1px),
  radial-gradient(circle,rgba(115,165,237,.32) 0 1px,transparent 1.1px);
  background-size:110px 110px,110px 110px,220px 220px,340px 340px;
  background-position:0 0,0 0,24px 28px,120px 86px;
}
.shell:after{content:"";position:absolute;left:0;right:0;bottom:0;height:24%;pointer-events:none;background:linear-gradient(to top,rgba(42,82,138,.28),rgba(27,54,93,.10) 55%,transparent)}
.corner{position:absolute;width:56px;height:56px;opacity:.24;pointer-events:none}
.corner.tl{left:22px;top:22px;border-left:1px solid #fff;border-top:1px solid #fff}
.corner.tr{right:22px;top:22px;border-right:1px solid #fff;border-top:1px solid #fff}
.corner.bl{left:22px;bottom:22px;border-left:1px solid #fff;border-bottom:1px solid #fff}
.corner.br{right:22px;bottom:22px;border-right:1px solid #fff;border-bottom:1px solid #fff}
.app{position:fixed;left:0;top:0;right:0;bottom:0;width:100vw;height:100vh;min-width:100vw;min-height:100vh;z-index:1}
.topbar{position:absolute;left:0;right:0;top:0;height:74px;padding:0 34px;display:flex;align-items:center;z-index:10;background:linear-gradient(180deg,rgba(10,4,15,.38),rgba(10,4,15,.05) 65%,transparent);border-bottom:1px solid rgba(255,255,255,.03)}
.brand{display:flex;align-items:center;gap:12px}
.brandLine{width:60px;height:1px;background:linear-gradient(90deg,#73a5ed,transparent)}
.brandTitle{font-family:"Bebas Neue",Arial,sans-serif;font-size:40px;line-height:1;letter-spacing:.06em}
.closeBtn{margin-left:auto;width:46px;height:46px;display:flex;align-items:center;justify-content:center;font-family:"Bebas Neue",Arial,sans-serif;font-size:32px;background:rgba(8,13,22,.45);border:1px solid rgba(255,255,255,.08);transition:.16s ease}
.closeBtn:hover{background:rgba(49,85,135,.28);border-color:rgba(115,165,237,.38);transform:translateY(-1px)}
.workspace{position:absolute;left:0;right:0;top:74px;bottom:42px;overflow:hidden;width:auto;height:auto}
.sidebar{position:absolute;left:0;top:0;bottom:0;width:32%;min-width:340px;max-width:520px;padding:16px 26px 18px 34px;border-right:1px solid rgba(225,230,239,.26);background:linear-gradient(90deg,rgba(7,13,22,.38),rgba(8,15,25,.16),transparent)}
.mainpanel{position:absolute;left:32%;right:0;top:0;bottom:0;padding:18px 34px 20px 28px;overflow:hidden}
.sectionTitle,.elementsTitle,.changeLabel,.detailTitle,.detailKicker{font-family:"Bebas Neue",Arial,sans-serif;letter-spacing:.04em}
.sectionTitle{font-size:32px;margin-bottom:14px}
.jobList{height:40%;min-height:215px;overflow:auto;padding-right:4px;padding-bottom:6px}
.jobList::-webkit-scrollbar,.bodygroups::-webkit-scrollbar{width:3px}
.jobList::-webkit-scrollbar-thumb,.bodygroups::-webkit-scrollbar-thumb{background:#4d80ca}
.jobWrap{display:flex;flex-wrap:wrap;gap:10px;align-content:flex-start}
.card{position:relative;width:calc(50% - 5px);min-height:84px;padding:12px 12px 12px 12px;display:flex;align-items:center;gap:12px;text-align:left;background:rgba(8,14,24,.28);border:1px solid rgba(255,255,255,.04);overflow:hidden;transition:.16s ease}
.card:before{content:"";position:absolute;left:0;top:0;right:0;bottom:0;background:linear-gradient(110deg,rgba(77,128,202,.12),transparent 55%);opacity:0;transition:.16s ease}
.card:hover{border-color:rgba(115,165,237,.24);background:rgba(12,24,40,.44)}
.card:hover:before,.card.active:before{opacity:1}
.card.active{border-color:rgba(115,165,237,.42);box-shadow:inset 0 0 0 1px rgba(77,128,202,.12)}
.card.active:after{content:"✓";position:absolute;right:10px;bottom:8px;color:#fff;font-weight:900;font-size:13px;text-shadow:0 0 10px #73a5ed}
.iconBox{position:relative;z-index:1;width:48px;height:48px;flex:0 0 48px;display:flex;align-items:center;justify-content:center;border:1px solid rgba(115,165,237,.18);background:rgba(77,128,202,.08);font-family:"Bebas Neue",Arial,sans-serif;font-size:22px;letter-spacing:.04em;overflow:hidden}.iconBox img{width:100%;height:100%;object-fit:contain;display:block;padding:5px}
.cardCopy{position:relative;z-index:1;min-width:0;flex:1 1 auto}
.cardKicker{font-size:12px;font-weight:900;letter-spacing:.05em;text-transform:uppercase;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.cardSub{margin-top:4px;font-size:11px;font-weight:700;color:#7d899b;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.emptyBlock{display:flex;align-items:center;justify-content:center;text-align:center;min-height:190px;padding:30px;color:#7d899b;font-size:11px;font-weight:800;line-height:1.6;text-transform:uppercase;border:1px dashed rgba(115,165,237,.18)}
.divider{height:10px;margin:14px 0;border-top:1px solid rgba(255,255,255,.15);background:repeating-linear-gradient(90deg,rgba(255,255,255,.33) 0 3px,transparent 3px 6px);background-size:auto 4px;background-repeat:repeat-x;background-position:left top 2px;opacity:.58}
.elementsTitle{font-size:31px;margin-bottom:18px}
.bodygroups{position:absolute;left:34px;right:26px;top:calc(40% + 118px);bottom:18px;overflow:auto;padding-right:4px}
.sliderRow{margin:14px 0;display:flex;align-items:center;gap:10px}
.sliderLabel{width:120px;flex:0 0 120px;color:#b9c1ce;font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.05em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding-top:1px}
.sliderInput{flex:1 1 auto}
.sliderValue{width:26px;flex:0 0 26px;text-align:center;font-size:10px;color:#fff}
 input[type=range]{appearance:none;-webkit-appearance:none;width:100%;height:14px;background:transparent;outline:none}
 input[type=range]::-webkit-slider-runnable-track{height:2px;background:linear-gradient(90deg,#73a5ed var(--fill,0%),rgba(214,222,235,.62) var(--fill,0%));border-radius:0}
 input[type=range]::-webkit-slider-thumb{appearance:none;-webkit-appearance:none;width:10px;height:10px;margin-top:-4px;background:#e9edf3;border:1px solid rgba(255,255,255,.8);box-shadow:0 0 10px rgba(115,165,237,.35)}
.headingRow{position:relative;z-index:4;display:flex;align-items:flex-start;gap:16px;min-height:132px}
.headingIcon{width:58px;height:58px;flex:0 0 58px;display:flex;align-items:center;justify-content:center;margin-top:3px;color:#fff;border:1px solid rgba(115,165,237,.18);background:rgba(77,128,202,.08);font-family:"Bebas Neue",Arial,sans-serif;font-size:28px;letter-spacing:.04em;overflow:hidden}.headingIcon img{width:100%;height:100%;object-fit:contain;display:block;padding:6px}
.detailKicker{font-size:20px;color:#6f92bf;opacity:.82;margin-top:8px}
.detailTitle{font-size:58px;line-height:.94}
.detailSubtitle{margin-top:6px;color:#c0c7d2;font-size:12px;font-weight:700}
.detailDesc{margin-top:4px;color:#8793a5;font-size:11px;font-weight:600;max-width:780px;line-height:1.45}
.stage{position:absolute;left:28px;right:34px;top:146px;bottom:88px;overflow:hidden;pointer-events:none}
.stageLine{position:absolute;left:0;right:0;top:0;height:1px;background:linear-gradient(90deg,rgba(255,255,255,.12),transparent 48%)}
.stageRing{position:absolute;right:2%;bottom:-10%;width:40vw;height:40vw;max-width:620px;max-height:620px;opacity:.22;border:1px solid rgba(255,255,255,.08);border-radius:50%;background:repeating-radial-gradient(circle at center,rgba(115,165,237,.14) 0 1px,transparent 1px 46px),linear-gradient(45deg,transparent 49.85%,rgba(255,255,255,.08) 50%,transparent 50.15%),linear-gradient(-45deg,transparent 49.85%,rgba(255,255,255,.08) 50%,transparent 50.15%)}
.stageRing:before,.stageRing:after{content:"";position:absolute;left:12%;right:12%;top:12%;bottom:12%;border:1px solid rgba(115,165,237,.22);transform:rotate(22.5deg)}
.stageRing:after{left:25%;right:25%;top:25%;bottom:25%;transform:rotate(45deg)}
.stageCaption{position:absolute;left:54%;bottom:11%;transform:translateX(-50%);text-align:center;color:#6f7989;font-size:10px;font-weight:800;letter-spacing:.14em;text-transform:uppercase;opacity:.55}
.stageCaption:before{content:"";display:block;width:1px;height:120px;margin:0 auto 15px;background:linear-gradient(transparent,#4d80ca,transparent)}
.modelCount{position:absolute;right:34px;top:138px;color:#6f7d91;font-size:10px;font-weight:800;letter-spacing:.12em;text-transform:uppercase;z-index:5}
.actions{position:absolute;right:34px;bottom:18px;display:flex;align-items:center;gap:18px;z-index:6}
.action{display:flex;align-items:center;gap:10px;color:#9ea7b6;font-size:10px;font-weight:800;text-transform:uppercase;transition:.16s ease}
.actionKey{min-width:36px;height:30px;padding:0 8px;display:flex;align-items:center;justify-content:center;border:1px solid rgba(230,235,243,.56);background:rgba(10,6,14,.24);font-family:"Bebas Neue",Arial,sans-serif;font-size:18px;color:#f2f4f7}
.action:hover{color:#fff;transform:translateY(-1px)}
.action:hover .actionKey{border-color:#73a5ed;box-shadow:0 0 15px rgba(115,165,237,.18)}
.action.disabled{opacity:.28;pointer-events:none}
.footer{position:absolute;left:0;right:0;bottom:0;height:42px;padding:0 34px;display:flex;align-items:center;z-index:10;background:linear-gradient(90deg,rgba(18,45,78,.58),rgba(30,70,116,.67),rgba(13,34,61,.52));border-top:1px solid rgba(94,145,214,.12)}
.footerText{font-size:10px;font-weight:800;text-transform:uppercase;color:#aeb8c6}
.footerLegend{margin-left:auto;display:flex;align-items:center;gap:10px;font-size:10px;font-weight:800}
.key{min-width:30px;height:25px;padding:0 7px;display:flex;align-items:center;justify-content:center;border:1px solid rgba(230,235,243,.56)}
.toast{position:absolute;left:50%;bottom:60px;transform:translate(-50%,18px);padding:10px 16px;background:rgba(8,13,22,.92);border:1px solid rgba(115,165,237,.32);font-size:10px;font-weight:800;letter-spacing:.05em;opacity:0;pointer-events:none;transition:.22s ease;z-index:30}
.toast.show{opacity:1;transform:translate(-50%,0)}
.toast.error{border-color:rgba(216,81,89,.58)}
@media (max-width: 1450px){
  .sidebar{width:34%;min-width:330px;padding-left:28px;padding-right:20px}
  .mainpanel{left:34%;padding-right:28px}
  .bodygroups{left:28px;right:20px}
}
@media (max-width: 1180px){
  .sidebar{width:37%;min-width:315px}
  .mainpanel{left:37%}
  .card{width:100%}
  .detailTitle{font-size:48px}
}
@media (max-height: 760px){
  .topbar{height:64px}.workspace{top:64px;bottom:38px}.footer{height:38px}
  .stage{top:128px;bottom:74px}
  .detailTitle{font-size:50px}
  .jobList{min-height:180px}
}
</style>
</head>
<body>
<div class="shell">
  <i class="corner tl"></i><i class="corner tr"></i><i class="corner bl"></i><i class="corner br"></i>
  <div class="app">
    <header class="topbar">
      <div class="brand"><div class="brandLine"></div><div class="brandTitle" id="brandTitle">UNIFORM</div></div>
      <button class="closeBtn" id="closeBtn" aria-label="Close">×</button>
    </header>

    <div class="workspace">
      <aside class="sidebar">
        <div class="sectionTitle">UNIFORMAUSWAHL</div>
        <div class="jobList"><div class="jobWrap" id="uniformGrid"></div></div>
        <div class="divider"></div>
        <div class="elementsTitle">UNIFORM-ELEMENTE</div>
        <div class="bodygroups" id="sliders"></div>
      </aside>

      <section class="mainpanel">
        <div class="headingRow">
          <div class="headingIcon" id="headingIcon">GRN</div>
          <div class="headingText">
            <div class="detailTitle" id="detailTitle">JOB AUSWÄHLEN</div>
            <div class="detailSubtitle" id="detailSubtitle">Es werden nur gewhitelistete Jobs angezeigt.</div>
            <div class="detailKicker">UNIFORM ANPASSEN</div>
            <div class="detailDesc" id="detailDesc">Wähle einen freigegebenen Job, um Uniform und Bodygroups einzustellen.</div>
          </div>
        </div>
        <div class="modelCount" id="modelCount"></div>
        <div class="stage">
          <div class="stageLine"></div>
          <div class="stageRing"></div>
          <div class="stageCaption">3D-Uniformvorschau</div>
        </div>
        <div class="actions">
          <button class="action" id="prevModel">VORHERIGES MODELL <span class="actionKey">◀</span></button>
          <button class="action" id="nextModel">NÄCHSTES MODELL <span class="actionKey">▶</span></button>
          <button class="action" id="equipBtn">AUSRÜSTEN <span class="actionKey">↵</span></button>
        </div>
      </section>
    </div>

    <footer class="footer">
      <div class="footerText" id="footerText">Echoes of Clones · Uniformsystem</div>
      <div class="footerLegend"><span>Auswählen</span><span class="key">LMB</span><span>Schließen</span><span class="key">ESC</span></div>
    </footer>
  </div>
  <div class="toast" id="toast"></div>
</div>
<script>
(function(){
var state={jobs:[],selected:null,bodygroups:[],modelIndex:1};
var grid=document.getElementById('uniformGrid'), sliders=document.getElementById('sliders'), title=document.getElementById('detailTitle'), subtitle=document.getElementById('detailSubtitle'), desc=document.getElementById('detailDesc'), heading=document.getElementById('headingIcon'), toast=document.getElementById('toast'), modelCount=document.getElementById('modelCount');
var prevBtn=document.getElementById('prevModel'), nextBtn=document.getElementById('nextModel'), equipBtn=document.getElementById('equipBtn');
function esc(s){return String(s==null?'':s).replace(/[&<>"']/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]})}
function initials(name){var p=String(name||'GRN').trim().split(/\s+/);if(p.length===1)return p[0].slice(0,3).toUpperCase();return (p[0][0]+p[p.length-1][0]).toUpperCase()}
function iconHTML(job){var icon=job&&job.icon?String(job.icon):'';if(icon){return '<img src="'+esc(icon)+'" alt="icon">'}return esc(initials(job&&job.name||'GRN'))}
function current(){for(var i=0;i<state.jobs.length;i++)if(Number(state.jobs[i].id)===Number(state.selected))return state.jobs[i];return null}
function setDisabled(btn, disabled){if(!btn)return;btn.classList.toggle('disabled',!!disabled)}
function renderCards(){
  grid.innerHTML='';
  if(!state.jobs.length){grid.innerHTML='<div class="emptyBlock">Keine Jobs verfügbar.<br>Beantrage eine Whitelist und öffne den Schrank erneut.</div>';setDisabled(prevBtn,true);setDisabled(nextBtn,true);setDisabled(equipBtn,true);return}
  setDisabled(equipBtn,false);
  state.jobs.forEach(function(j){
    var b=document.createElement('button');
    b.className='card'+(Number(j.id)===Number(state.selected)?' active':'');
    b.innerHTML='<span class="iconBox">'+iconHTML(j)+'</span><span class="cardCopy"><div class="cardKicker">'+esc(j.name)+'</div><div class="cardSub">'+esc(j.category||'Ohne Kategorie')+'</div></span>';
    b.onclick=function(){state.selected=Number(j.id);renderCards();updateHeader();try{gmod.selectJob(String(j.id))}catch(e){}};
    grid.appendChild(b);
  });
}
function updateHeader(){
  var j=current();
  if(!j){title.textContent='JOB AUSWÄHLEN';subtitle.textContent='Es werden nur gewhitelistete Jobs angezeigt.';desc.textContent='Wähle einen freigegebenen Job, um Uniform und Bodygroups einzustellen.';heading.innerHTML='GRN';modelCount.textContent='';return}
  title.textContent=String(j.name||'UNIFORM');
  subtitle.textContent=String(j.category||'Freigegebener Job');
  desc.textContent=String(j.description||'Freigegebene Uniform für diesen Job.');
  heading.innerHTML=iconHTML(j);
  var total=(j.models&&j.models.length)||1;
  modelCount.textContent='MODEL '+state.modelIndex+' / '+total;
  setDisabled(prevBtn,total<=1);
  setDisabled(nextBtn,total<=1);
}
function renderBodygroups(list){
  state.bodygroups=Array.isArray(list)?list:[];
  sliders.innerHTML='';
  if(!state.bodygroups.length){sliders.innerHTML='<div class="emptyBlock">Dieses Modell hat keine einstellbaren Bodygroups.</div>';return}
  state.bodygroups.forEach(function(bg){
    var row=document.createElement('div');
    row.className='sliderRow';
    var max=Math.max(0,Number(bg.max||0)), val=Math.max(0,Math.min(max,Number(bg.value||0)));
    row.innerHTML='<div class="sliderLabel">'+esc(bg.name||('Bodygroup '+bg.id))+'</div><div class="sliderInput"><input type="range" min="0" max="'+max+'" value="'+val+'"></div><div class="sliderValue">'+val+'</div>';
    var range=row.querySelector('input'), value=row.querySelector('.sliderValue');
    function sync(){var v=Number(range.value||0), pct=max>0?(v/max)*100:0;value.textContent=String(v);range.style.setProperty('--fill',pct+'%');try{gmod.setBodygroup(String(bg.id),String(v))}catch(e){}}
    range.addEventListener('input',sync);
    range.style.setProperty('--fill',(max>0?(val/max)*100:0)+'%');
    sliders.appendChild(row);
  });
}
function showToast(text,ok){toast.textContent=String(text||'');toast.classList.toggle('error',ok===false);toast.classList.add('show');clearTimeout(window.__grnToast);window.__grnToast=setTimeout(function(){toast.classList.remove('show')},1700)}
window.GRNWeaponrio={
  setData:function(data){
    data=data||{};
    state.jobs=Array.isArray(data.jobs)?data.jobs:[];
    document.getElementById('brandTitle').textContent=String(data.title||'UNIFORM');
    document.getElementById('footerText').textContent=String(data.footer||'Echoes of Clones · Uniformsystem');
    var keep=false;
    for(var i=0;i<state.jobs.length;i++){if(Number(state.jobs[i].id)===Number(state.selected)){keep=true;break}}
    if(!keep){
      state.selected=null;
      for(var x=0;x<state.jobs.length;x++){if(state.jobs[x].current){state.selected=Number(state.jobs[x].id);break}}
      if(state.selected===null&&state.jobs.length)state.selected=Number(state.jobs[0].id);
    }
    renderCards();
    updateHeader();
    if(state.selected!==null){try{gmod.selectJob(String(state.selected))}catch(e){}}
  },
  setBodygroups:function(list,index){state.modelIndex=Number(index||1);renderBodygroups(list);updateHeader()},
  notify:showToast
};
document.getElementById('closeBtn').onclick=function(){try{gmod.close()}catch(e){}};
equipBtn.onclick=function(){try{gmod.equip()}catch(e){}};
prevBtn.onclick=function(){if(this.classList.contains('disabled'))return;try{gmod.nextModel('-1')}catch(e){}};
nextBtn.onclick=function(){if(this.classList.contains('disabled'))return;try{gmod.nextModel('1')}catch(e){}};
document.addEventListener('keydown',function(e){if(e.key==='Escape'){try{gmod.close()}catch(x){}}if(e.key==='Enter'){try{gmod.equip()}catch(x){}}});
})();
</script>
</body>
</html>
]==]
end
