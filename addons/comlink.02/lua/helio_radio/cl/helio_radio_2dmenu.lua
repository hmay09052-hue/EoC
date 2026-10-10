hradio = hradio or {}

local function buildChannelData()
    local ply = LocalPlayer()
    local channels = {}

    if not IsValid(ply) then return channels end

    ply.hradio = ply.hradio or {}
    ply.hradio.MutedChannels = ply.hradio.MutedChannels or {}

    for index, channel in pairs(hradio.Channels or {}) do
        if not channel.Name or not channel.Talkers or not channel.Listeners or
           not channel.GetTalkers or not channel.GetListeners or
           channel.Mutable == nil or not channel.Color then
            continue
        end

        if not channel.GetListeners(ply) and not channel.Listeners[ply:Team()] then
            continue
        end

        local canTalk = channel.GetTalkers(ply) or channel.Talkers[ply:Team()] or false
        local color = channel.Color or Color(255, 190, 50)
        local slot = hradio.GetChannelHotkey and hradio.GetChannelHotkey(index)
        local slotDef = slot and hradio.GetHotkeySlots()[slot]

        channels[#channels + 1] = {
            id = tonumber(index) or 0,
            name = tostring(channel.Name),
            mutable = channel.Mutable == true,
            muted = ply.hradio.MutedChannels[index] == true,
            active = ply.hradio.ActiveChannel == index,
            canTalk = canTalk and true or false,
            hotkey = slotDef and tostring(slotDef.Label) or "",
            joined = hradio.IsChannelJoined and hradio.IsChannelJoined(index) or false,
            color = string.format("rgb(%d,%d,%d)", color.r or 255, color.g or 190, color.b or 50)
        }
    end

    table.sort(channels, function(a, b)
        return a.id < b.id
    end)

    return channels
end

local function buildSlotData()
    local slots = {}

    if hradio.Config.HotkeysEnabled == false or not hradio.GetHotkeySlots then return slots end

    for slot, def in ipairs(hradio.GetHotkeySlots()) do
        slots[#slots + 1] = {
            slot = slot,
            label = tostring(def.Label),
            channel = hradio.GetHotkeyChannel(slot) or 0
        }
    end

    return slots
end

local HTML = [==[
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
/* SymChars-Design: abgeschrägte Platten, Bernstein-Akzent, BigNoodle-Überschriften mit Aurebesh */
@font-face{font-family:'SymHead';src:url('asset://garrysmod/resource/fonts/symchars_bignoodle.ttf')}
@font-face{font-family:'SymBody';src:url('asset://garrysmod/resource/fonts/symchars_robotocondensed.ttf')}
@font-face{font-family:'SymAure';src:url('asset://garrysmod/resource/fonts/symchars_aurebesh.ttf')}
:root{
    --yellow:rgb(252,178,73);
    --yellow-soft:rgba(252,178,73,.66);
    --yellow-dim:rgba(252,178,73,.22);
    --yellow-faint:rgba(252,178,73,.08);
    --bg:rgba(9,11,14,.97);
    --panel:rgba(11,14,18,.91);
    --panel2:rgba(18,22,28,.94);
    --panel3:rgba(27,32,40,.96);
    --text:#ece9e0;
    --soft:#a8aeb4;
    --muted:#70777f;
    --ink:#121519;
    --line:rgba(255,255,255,.086);
    --line2:rgba(255,255,255,.2);
    --red:#cd3e38;
    --red-bg:rgba(90,18,18,.55);
    --head:'SymHead','BigNoodleTitling','Bebas Neue',Impact,sans-serif;
    --body:'SymBody','Roboto Condensed','Arial Narrow',Arial,sans-serif;
    --aure:'SymAure','Aurebesh',monospace;
    --cut:polygon(16px 0,100% 0,100% calc(100% - 16px),calc(100% - 16px) 100%,0 100%,0 16px);
    --cut-sm:polygon(8px 0,100% 0,100% calc(100% - 8px),calc(100% - 8px) 100%,0 100%,0 8px);
}
*{box-sizing:border-box;margin:0;padding:0;-webkit-user-select:none;user-select:none}
html,body{width:100%;height:100%;overflow:hidden;background:transparent!important}
body{font-family:var(--body);color:var(--text)}
.viewport{position:fixed;inset:0;padding:clamp(10px,1.05vw,20px);pointer-events:none}

/* Fenster: Rahmen (Akzent) als äußere Platte, Inhalt 1px eingerückt -> abgeschrägter Rahmen */
.menu{
    width:clamp(380px,23.5vw,460px);
    max-width:calc(100vw - 20px);
    height:min(640px,calc(100vh - 20px));
    min-height:430px;
    position:relative;
    pointer-events:auto;
    padding:1px;
    background:rgba(252,178,73,.45);
    background:var(--yellow-soft);
    clip-path:var(--cut);
    filter:drop-shadow(0 18px 40px rgba(0,0,0,.55));
    animation:open .18s ease-out both;
}
.menuInner{
    width:100%;height:100%;
    display:grid;
    grid-template-rows:auto auto minmax(0,1fr) auto;
    position:relative;overflow:hidden;
    background:var(--bg);
    clip-path:var(--cut);
}
@keyframes open{from{opacity:0;transform:translateX(-8px)}to{opacity:1;transform:none}}
.menuInner:before{
    content:"";position:absolute;z-index:0;inset:0;pointer-events:none;
    background:repeating-linear-gradient(180deg,rgba(0,0,0,.18) 0 1px,transparent 1px 3px);
    opacity:.35;
}

/* Kopf */
.header{
    position:relative;z-index:2;
    display:flex;align-items:center;justify-content:space-between;gap:12px;
    padding:16px 16px 14px 20px;
}
.header:after{content:"";position:absolute;left:20px;right:16px;bottom:0;height:1px;background:var(--line2)}
.header:before{content:"";position:absolute;left:20px;bottom:0;width:80px;height:2px;background:var(--yellow);z-index:1}
.brand{display:flex;align-items:center;gap:12px;min-width:0}
.logoWrap{width:70px;height:40px;flex:0 0 70px;display:flex;align-items:center;overflow:hidden}
.logo{display:block;max-width:68px;max-height:38px;object-fit:contain;filter:drop-shadow(0 2px 7px rgba(0,0,0,.7))}
.titleWrap{min-width:0}
.kicker{font-family:var(--body);font-size:11px;font-weight:700;letter-spacing:1.6px;color:var(--yellow);text-transform:uppercase;white-space:nowrap}
.title{font-family:var(--head);font-size:38px;font-weight:400;letter-spacing:1px;line-height:.95;text-transform:uppercase;color:var(--text);white-space:nowrap}
.aure{font-family:var(--aure);font-size:10px;letter-spacing:1px;line-height:1.1;color:rgba(168,174,180,.55);text-transform:uppercase;white-space:nowrap}
.subtitle{display:none}
.close{
    width:30px;height:30px;flex:0 0 30px;align-self:flex-start;
    display:grid;place-items:center;border:0;background:transparent;
    color:var(--soft);font-size:26px;line-height:1;cursor:pointer;
}
.close:hover{color:var(--red)}

/* Statuszeile wie die Reiterleiste */
.network{
    position:relative;z-index:2;height:36px;
    display:flex;align-items:center;justify-content:space-between;
    margin:10px 16px 0 20px;padding:0 12px;
    background:rgba(0,0,0,.6);
    border-bottom:1px solid var(--yellow-dim);
}
.networkLeft,.networkRight{display:flex;align-items:center;gap:7px}
.dot{width:6px;height:6px;background:var(--yellow);transform:rotate(45deg);box-shadow:0 0 8px var(--yellow-soft)}
.networkLabel{font-family:var(--head);font-size:17px;letter-spacing:1px;color:var(--soft);text-transform:uppercase}
.networkValue{font-family:var(--head);font-size:17px;letter-spacing:1px;color:var(--yellow);text-transform:uppercase}
.counter{font-family:var(--head);font-size:17px;letter-spacing:1px;color:var(--text)}

/* Liste */
.list{position:relative;z-index:2;min-height:0;overflow-y:auto;padding:10px 12px 12px 20px}
.list::-webkit-scrollbar{width:4px}
.list::-webkit-scrollbar-track{background:rgba(255,255,255,.06)}
.list::-webkit-scrollbar-thumb{background:var(--yellow-soft)}
.list::-webkit-scrollbar-thumb:hover{background:var(--yellow)}
.row{
    --channel:#ffffff;
    width:100%;min-height:52px;
    position:relative;
    display:grid;grid-template-columns:32px minmax(0,1fr) auto;align-items:center;gap:10px;
    margin-bottom:6px;padding:6px 12px 6px 12px;
    border:1px solid var(--line);
    background:rgba(11,14,18,.88);
    color:var(--text);text-align:left;cursor:pointer;
    font-family:var(--body);
    transition:border-color .12s ease,background .12s ease,box-shadow .12s ease;
}
.row:last-child{margin-bottom:0}
.row:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--channel)}
.row:hover{border-color:var(--line2);background:rgba(18,22,28,.94)}
.row.selected{border-color:var(--yellow);background:rgba(18,21,26,.96);box-shadow:0 0 0 1px var(--yellow-dim),0 0 14px var(--yellow-dim)}
.row.active{
    border-color:var(--yellow);
    background:linear-gradient(0deg,var(--yellow-dim),var(--yellow-faint));
    box-shadow:0 0 0 1px var(--yellow-dim),0 0 16px var(--yellow-dim);
}
.row.active:after{content:"";position:absolute;left:0;right:0;bottom:0;height:3px;background:var(--yellow)}
.row.muted{border-color:rgba(205,62,56,.6);background:var(--red-bg)}
.channelIndex{
    width:32px;height:32px;display:grid;place-items:center;
    background:var(--panel3);clip-path:var(--cut-sm);
    font-family:var(--head);font-size:19px;color:var(--soft);
}
.row.active .channelIndex,.row.selected .channelIndex{background:var(--yellow);color:var(--ink)}
.channelMain{min-width:0;display:flex;flex-direction:column}
.channelName{
    display:block;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;
    font-family:var(--head);font-size:23px;line-height:1;letter-spacing:.6px;text-transform:uppercase;color:var(--text);
}
.row:not(.active):not(.selected) .channelName{color:#d6d3cb}
.channelSub{display:block;margin-top:2px;font-family:var(--body);font-size:11px;font-weight:700;letter-spacing:.9px;color:var(--muted);text-transform:uppercase}
.status{display:flex;flex-direction:column;align-items:flex-end;gap:2px}
.tag{font-family:var(--head);font-size:15px;letter-spacing:.8px;text-transform:uppercase;color:var(--muted);white-space:nowrap;line-height:1}
.tag.ready{color:var(--yellow)}
.tag.active{color:var(--text)}
.tag.bad{color:#e07a74}
.keyMark{
    display:inline-block;margin-right:6px;padding:1px 5px 0;
    background:var(--yellow);color:var(--ink);
    font-family:var(--head);font-size:12px;letter-spacing:.5px;
    clip-path:polygon(3px 0,100% 0,100% calc(100% - 3px),calc(100% - 3px) 100%,0 100%,0 3px);
}

/* Detail / Aktionen */
.footer{position:relative;z-index:2;padding:12px 16px 16px 20px}
.footer:before{content:"";position:absolute;top:0;left:20px;right:16px;height:1px;background:var(--line2)}
.footer:after{content:"";position:absolute;top:-1px;left:20px;width:80px;height:2px;background:var(--yellow)}
.detailHead{display:flex;align-items:flex-start;justify-content:space-between;gap:10px;margin-top:4px}
.detailTitle{
    min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;
    font-family:var(--head);font-size:34px;line-height:1;letter-spacing:1px;text-transform:uppercase;color:var(--text);
}
.detailCode{
    flex:0 0 auto;margin-top:4px;padding:3px 8px 2px;
    background:var(--panel3);color:var(--yellow);
    font-family:var(--head);font-size:15px;letter-spacing:1px;
    clip-path:var(--cut-sm);
}
.detailAure{font-family:var(--aure);font-size:10px;letter-spacing:1px;color:rgba(168,174,180,.5);text-transform:uppercase;margin:2px 0 6px;white-space:nowrap;overflow:hidden}
.detailCopy{min-height:32px;margin-bottom:12px;color:var(--soft);font-size:14px;line-height:1.4}
.actions{display:grid;grid-template-columns:1fr 1fr;gap:8px}
.btn{
    height:38px;position:relative;border:0;
    background:var(--line2);padding:1px;
    clip-path:var(--cut-sm);
    color:var(--soft);
    font-family:var(--head);font-size:21px;letter-spacing:1px;text-transform:uppercase;cursor:pointer;
}
/* innere Fläche über box-shadow, damit der Rahmen abgeschrägt bleibt */
.btn{box-shadow:inset 0 0 0 1px transparent;background:linear-gradient(var(--panel2),var(--panel2)) padding-box,var(--line2) border-box;border:1px solid transparent}
.btn:hover{color:var(--text);background:linear-gradient(var(--panel3),var(--panel3)) padding-box,var(--yellow) border-box}
.btn.primary{background:var(--yellow);color:var(--ink);border-color:var(--yellow)}
.btn.primary:hover{background:#ffc36a;color:var(--ink);filter:drop-shadow(0 0 8px var(--yellow-soft))}
.btn.alert{background:linear-gradient(rgba(90,18,18,.9),rgba(90,18,18,.9)) padding-box,rgba(205,62,56,.8) border-box;color:var(--text)}
.btn:disabled{opacity:.3;cursor:not-allowed;filter:none}
.binds{display:grid;gap:8px;margin-top:8px}
.binds:empty{display:none}
.bind{
    height:32px;border:1px solid transparent;
    background:linear-gradient(rgba(4,6,8,.9),rgba(4,6,8,.9)) padding-box,var(--line2) border-box;
    color:var(--soft);clip-path:var(--cut-sm);
    font-family:var(--head);font-size:17px;letter-spacing:.8px;text-transform:uppercase;cursor:pointer;
}
.bind:hover{color:var(--text);background:linear-gradient(rgba(18,22,28,.95),rgba(18,22,28,.95)) padding-box,var(--yellow) border-box}
.bind.on{color:var(--yellow);background:linear-gradient(rgba(40,30,14,.95),rgba(40,30,14,.95)) padding-box,var(--yellow) border-box}
.bind.taken{color:var(--muted)}
.bind:disabled{opacity:.3;cursor:not-allowed}
.hint{margin-top:10px;text-align:center;color:var(--muted);font-size:11px;font-weight:600;letter-spacing:.4px;line-height:1.4}
.empty{
    height:58px;display:flex;align-items:center;justify-content:center;
    border:1px dashed var(--yellow-dim);
    color:var(--muted);font-family:var(--head);font-size:18px;letter-spacing:1px;text-transform:uppercase;
}
@media(max-height:650px){
    .menu{height:calc(100vh - 16px);min-height:0}
    .viewport{padding:8px}
    .title{font-size:32px}
    .row{min-height:44px}.channelName{font-size:20px}.detailTitle{font-size:28px}.detailCopy{min-height:0}
}
@media(max-width:720px){
    .viewport{padding:8px}
    .menu{width:min(360px,calc(100vw - 16px));height:calc(100vh - 16px)}
}
</style>
</head>
<body>
<div class="viewport">
    <section class="menu"><div class="menuInner">
        <header class="header">
            <div class="brand">
                <div class="logoWrap">
                    <img class="logo" src="asset://garrysmod/materials/vgui/hradio/eoc_logo.png" onerror="this.onerror=null;this.src='https://r2.fivemanage.com/CAL8kaFVELoEmru99DXu6/scheres_eoc_logo.png';" alt="Echoes of Clones">
                </div>
                <div class="titleWrap">
                    <div class="kicker">Echoes of Clones</div>
                    <div class="title">Funkgerät</div>
                    <div class="aure">Funkgeraet</div>
                    <div class="subtitle">Funknetz der Republik</div>
                </div>
            </div>
            <button class="close" onclick="closeMenu()">×</button>
        </header>

        <div class="network">
            <div class="networkLeft">
                <span class="dot"></span>
                <span class="networkLabel">Funknetz</span>
                <span class="networkValue">Online</span>
            </div>
            <div class="networkRight">
                <span class="networkLabel">Deine Funks</span>
                <span class="counter" id="channelCount">00</span>
            </div>
        </div>

        <div id="list" class="list"></div>

        <footer class="footer">
            <div class="detailHead">
                <div id="detailTitle" class="detailTitle">Funk</div>
                <div id="detailCode" class="detailCode">NR. 00</div>
            </div>
            <div id="detailAure" class="detailAure"></div>
            <div id="detailCopy" class="detailCopy">Klicke oben auf einen Funk, um ihn auszuwählen.</div>
            <div class="actions">
                <button id="activateBtn" class="btn primary" onclick="toggleActive()" disabled>Einschalten</button>
                <button id="muteBtn" class="btn" onclick="toggleMute()" disabled>Stummschalten</button>
            </div>
            <div id="binds" class="binds"></div>
            <div id="hint" class="hint">ESC = Schließen</div>
        </footer>
    </div></section>
</div>

<script>
var channels = [];
var slots = [];
var selectedId = null;

function esc(s){
    return String(s).replace(/[&<>"']/g,function(c){
        return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c];
    });
}

function pad2(v){
    v = Number(v) || 0;
    return v < 10 ? "0" + v : String(v);
}

function getSelected(){
    for(var i=0;i<channels.length;i++){
        if(channels[i].id === selectedId) return channels[i];
    }
    return null;
}

function sortChannels(){
    channels.sort(function(a,b){
        return Number(a.id || 0) - Number(b.id || 0);
    });
}

function selectChannel(id){
    selectedId = id;
    render();
}

function render(){
    sortChannels();

    var root = document.getElementById("list");
    root.innerHTML = "";
    document.getElementById("channelCount").textContent = pad2(channels.length);

    if(!channels.length){
        root.innerHTML = '<div class="empty">Keine Funks verfügbar</div>';
        selectedId = null;
        updateDetail();
        return;
    }

    if(selectedId === null || !getSelected()){
        var preferred = null;
        for(var p=0;p<channels.length;p++){
            if(channels[p].active){ preferred = channels[p]; break; }
        }
        selectedId = (preferred || channels[0]).id;
    }

    for(var i=0;i<channels.length;i++){
        (function(ch){
            var row = document.createElement("button");
            var cls = "row";

            if(ch.active) cls += " active";
            else if(selectedId === ch.id) cls += " selected";
            if(ch.muted) cls += " muted";

            row.className = cls;
            row.style.setProperty("--channel", ch.color || "rgb(255,190,50)");
            row.onclick = function(){ selectChannel(ch.id); };

            var status = "";
            if(ch.muted){
                status = '<span class="tag bad">Stumm</span>';
            }else if(ch.active){
                status = '<span class="tag active">Aktiv</span><span class="tag ready">Sprechen + Hören</span>';
            }else if(!ch.joined){
                status = '<span class="tag">Nicht beigetreten</span>';
            }else if(ch.canTalk){
                status = '<span class="tag active">Beigetreten</span><span class="tag ready">Bereit</span>';
            }else{
                status = '<span class="tag active">Beigetreten</span><span class="tag">Nur hören</span>';
            }

            row.innerHTML =
                '<span class="channelIndex">'+pad2(ch.id)+'</span>'+
                '<span class="channelMain">'+
                    '<span class="channelName">'+esc(ch.name)+'</span>'+
                    '<span class="channelSub">'+(ch.hotkey ? '<span class="keyMark">'+esc(ch.hotkey)+'</span>Schnellwahl' : 'Funk')+'</span>'+
                '</span>'+
                '<span class="status">'+status+'</span>';

            root.appendChild(row);
        })(channels[i]);
    }

    updateDetail();
}

function updateDetail(){
    var ch = getSelected();
    var title = document.getElementById("detailTitle");
    var code = document.getElementById("detailCode");
    var copy = document.getElementById("detailCopy");
    var activateBtn = document.getElementById("activateBtn");
    var muteBtn = document.getElementById("muteBtn");

    if(!ch){
        title.textContent = "Funk";
        code.textContent = "NR. 00";
        copy.textContent = "Für deinen Job gibt es gerade keine Funks.";
        activateBtn.disabled = true;
        muteBtn.disabled = true;
        renderBinds(null);
        return;
    }

    title.textContent = ch.name;
    var aure = document.getElementById("detailAure");
    if(aure) aure.textContent = String(ch.name || "").replace(/[äÄ]/g,"ae").replace(/[öÖ]/g,"oe").replace(/[üÜ]/g,"ue").replace(/ß/g,"ss");
    code.textContent = "NR. " + pad2(ch.id);

    if(ch.muted){
        copy.textContent = "Dieser Funk ist stummgeschaltet. Du hörst hier nichts, bis du den Ton wieder anmachst.";
    }else if(ch.active){
        copy.textContent = "Dieser Funk ist an. Wenn du sprichst, hören dich alle auf diesem Funk.";
    }else if(!ch.joined){
        copy.textContent = "Du hörst diesen Funk noch nicht. Lege ihn unten auf F1, F2 oder F3, um beizutreten.";
    }else if(ch.canTalk){
        copy.textContent = "Du bist beigetreten und hörst diesen Funk. Taste drücken oder „Einschalten“ = sprechen.";
    }else{
        copy.textContent = "Du bist beigetreten und hörst zu. Sprechen ist hier nicht erlaubt.";
    }

    activateBtn.disabled = !ch.canTalk || ch.muted;
    activateBtn.textContent = ch.active ? "Ausschalten" : "Einschalten";

    muteBtn.disabled = !ch.mutable;
    muteBtn.textContent = ch.muted ? "Ton wieder an" : "Stummschalten";
    muteBtn.className = "btn" + (ch.muted ? " alert" : "");

    renderBinds(ch);
}

function renderBinds(ch){
    var root = document.getElementById("binds");
    var hint = document.getElementById("hint");
    root.innerHTML = "";

    if(!slots.length){
        hint.textContent = "ESC = Schließen";
        return;
    }

    root.style.gridTemplateColumns = "repeat(" + slots.length + ",1fr)";

    var labels = [];

    for(var i=0;i<slots.length;i++){
        (function(sl){
            var btn = document.createElement("button");
            var on = !!ch && sl.channel === ch.id;

            labels.push(sl.label);
            btn.className = "bind" + (on ? " on" : (sl.channel ? " taken" : ""));
            btn.textContent = on ? ("Von " + sl.label + " lösen") : ("Auf " + sl.label + " legen");
            btn.disabled = !ch;
            btn.onclick = function(){ bindSlot(sl.slot); };

            root.appendChild(btn);
        })(slots[i]);
    }

    hint.textContent = "Funk anklicken → auf " + labels.join(" / ") + " legen = beitreten (erst dann hörst du ihn) → im Spiel Taste drücken = sprechen an/aus · ESC = Schließen";
}

function bindSlot(slot){
    var ch = getSelected();
    if(!ch) return;

    var sl = null;
    for(var i=0;i<slots.length;i++){
        if(slots[i].slot === slot){ sl = slots[i]; break; }
    }
    if(!sl) return;


    gmod.bindChannel(slot, ch.id);
}

function toggleActive(){
    var ch = getSelected();
    if(!ch || !ch.canTalk || ch.muted) return;

    var next = ch.active ? 0 : ch.id;

    for(var i=0;i<channels.length;i++){
        channels[i].active = (channels[i].id === next);
    }

    gmod.activateChannel(next);
    render();
}

function toggleMute(){
    var ch = getSelected();
    if(!ch || !ch.mutable) return;

    ch.muted = !ch.muted;

    if(ch.muted && ch.active){
        ch.active = false;
        gmod.activateChannel(0);
    }

    gmod.muteChannel(ch.id, ch.muted);
    render();
}

function setActive(id){
    id = Number(id) || 0;

    for(var i=0;i<channels.length;i++){
        channels[i].active = (channels[i].id === id);
    }

    render();
}

function setChannels(data, slotData){
    channels = Array.isArray(data) ? data : [];
    slots = Array.isArray(slotData) ? slotData : [];
    render();
}

function closeMenu(){
    gmod.closeMenu();
}

document.addEventListener("keydown",function(e){
    if(e.key === "Escape" || e.keyCode === 27){ closeMenu(); return; }

    var key = String(e.key || "").toUpperCase();

    for(var i=0;i<slots.length;i++){
        if(String(slots[i].label).toUpperCase() === key){
            e.preventDefault();
            bindSlot(slots[i].slot);
            return;
        }
    }
});

window.onload = function(){
    gmod.ready();
};
</script>
</body>
</html>
]==]

function hradio.OpenMenu2D()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    ply.hradio = ply.hradio or {}

    if IsValid(ply.hradio.RadioMenu) then
        ply.hradio.RadioMenu:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:SetSizable(false)
    frame:SetDeleteOnClose(true)
    frame:MakePopup()
    frame:SetMouseInputEnabled(true)
    frame:SetKeyboardInputEnabled(true)
    frame.Paint = nil

    local browser = vgui.Create("DHTML", frame)
    browser:Dock(FILL)
    browser:SetAllowLua(true)
    browser:SetMouseInputEnabled(true)
    browser:SetKeyboardInputEnabled(true)
    browser:SetVisible(true)

    local ready = false

    local function sendChannels()
        if not IsValid(browser) or not ready then return end
        local json = util.TableToJSON(buildChannelData()) or "[]"
        local slotJson = util.TableToJSON(buildSlotData()) or "[]"
        browser:RunJavascript("setChannels(" .. json .. "," .. slotJson .. ");")
    end

    browser:AddFunction("gmod", "ready", function()
        if not IsValid(browser) then return end
        ready = true
        sendChannels()
    end)

    browser:AddFunction("gmod", "activateChannel", function(channelId)
        channelId = math.floor(tonumber(channelId) or 0)
        if channelId < 0 then channelId = 0 end
        hradio.ChangeActiveChannel(channelId)
    end)

    browser:AddFunction("gmod", "muteChannel", function(channelId, state)
        channelId = math.floor(tonumber(channelId) or 0)
        state = state == true or state == 1 or state == "true"

        ply.hradio.MutedChannels = ply.hradio.MutedChannels or {}
        ply.hradio.MutedChannels[channelId] = state
        hradio.ChangeMuteStatus(channelId, state)
    end)

    browser:AddFunction("gmod", "bindChannel", function(slot, channelId)
        slot = math.floor(tonumber(slot) or 0)
        channelId = math.floor(tonumber(channelId) or 0)

        if hradio.ToggleHotkeyBinding then
            hradio.ToggleHotkeyBinding(slot, channelId)
        end

        sendChannels()
    end)

    browser:AddFunction("gmod", "closeMenu", function()
        if IsValid(frame) then frame:Remove() end
    end)

    browser:SetHTML(SYMUI and SYMUI.ThemeHTML(HTML) or HTML)

    local feedbackHook = "hRadio_DHTMLFeedback_" .. tostring(frame)

    hook.Add("hRadio_PlyChangeChannelFeedback", feedbackHook, function(channelId)
        if not IsValid(browser) then
            hook.Remove("hRadio_PlyChangeChannelFeedback", feedbackHook)
            return
        end

        sendChannels() -- Aktiv- und Beitritts-Status neu anzeigen
    end)

    frame.OnRemove = function()
        hook.Remove("hRadio_PlyChangeChannelFeedback", feedbackHook)
        gui.EnableScreenClicker(false)

        if IsValid(browser) then
            browser:Stop()
        end

        if IsValid(ply) and ply.hradio and ply.hradio.RadioMenu == frame then
            ply.hradio.RadioMenu = nil
        end
    end

    frame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE and IsValid(frame) then
            frame:Remove()
        end
    end

    ply.hradio.RadioMenu = frame

    return frame
end
