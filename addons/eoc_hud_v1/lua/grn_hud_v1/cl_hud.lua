if not CLIENT then return end

GRN_HUDV1 = GRN_HUDV1 or {}
GRN_HUDV1.State = GRN_HUDV1.State or {}

local C = GRN_HUDV1.Config or (GRN_HUD_V1 and GRN_HUD_V1.Config) or {}
local State = GRN_HUDV1.State
local LOAD_TAG = "[GRN HUD]"
local READY_NET = "GRN_HUD_EOC_ClientReady"


local function loadError(message)
    ErrorNoHalt(LOAD_TAG .. " " .. tostring(message) .. "\n")
end

State.enabled = State.enabled ~= false
State.overlay = State.overlay ~= false

local function configBool(value, fallback)
    if value == nil then return fallback end
    return value == true
end

C.Enabled = configBool(C.Enabled, true)
C.HideDefaultHUD = configBool(C.HideDefaultHUD, true)
C.DefaultHudOn = configBool(C.DefaultHudOn, true)
C.DefaultOverlayOn = configBool(C.DefaultOverlayOn, true)
C.UpdateInterval = math.max(0.05, tonumber(C.UpdateInterval) or 0.10)
C.CompassInterval = math.max(0.03, tonumber(C.CompassInterval) or 0.04)
C.NetworkInterval = math.max(0.25, tonumber(C.NetworkInterval) or 0.50)
C.LSCSUpdateInterval = math.max(0.05, tonumber(C.LSCSUpdateInterval) or 0.08)
C.JetpackUpdateInterval = math.max(0.05, tonumber(C.JetpackUpdateInterval) or 0.08)
C.DHTMLReadyFallbackDelay = math.max(0.35, tonumber(C.DHTMLReadyFallbackDelay) or 1.25)

local HTML_TEMPLATE = [=[
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">

<meta
    name="viewport"
    content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"
>

<title>Echoes of Clones HUD</title>

<style>


:root{

    --yellow:rgb(255,190,50);

    --yellow-soft:rgba(255,190,50,.68);
    --yellow-dim:rgba(255,190,50,.22);
    --yellow-faint:rgba(255,190,50,.08);

    --white:#f4f1e9;
    --text:#d8dbe1;

    --soft:#9da3ad;
    --muted:#656b75;

    --dark:#05070a;

    --panel:rgba(8,11,15,.76);
    --panel-soft:rgba(14,18,23,.60);
    --panel-strong:rgba(7,9,12,.92);

    --line:rgba(207,216,228,.15);
    --line-strong:rgba(207,216,228,.30);

    --red:#e15858;
    --green:#4acb82;

    --font-main:"Montserrat",Arial,Helvetica,sans-serif;
    --font-title:"Bebas Neue","Arial Narrow",Arial,sans-serif;

}


*{

    box-sizing:border-box;

    margin:0;
    padding:0;

    -webkit-user-select:none;
    user-select:none;

}

html,
body{

    width:100%;
    height:100%;

    overflow:hidden;

    background:transparent !important;

    color:var(--white);

    font-family:var(--font-main);

}

body{

    position:fixed;

    inset:0;

    pointer-events:none;

    text-shadow:
        0 1px 2px rgba(0,0,0,.95),
        0 0 8px rgba(0,0,0,.44);

}

#hud{

    position:fixed;

    inset:0;

    width:100vw;
    height:100vh;

    overflow:hidden;

}


.fa-heart-pulse:before{
    content:"+";
}

.fa-shield-halved:before{
    content:"◇";
}

.fa-volume-high:before{

    content:")))";

    font-size:.75em;

}

.fa-microphone:before{
    content:"●";
}

.fa-microphone-slash:before{

    content:"/●";

    font-size:.8em;

}

.fa-tower-broadcast:before{
    content:"⌁";
}

.fa-crosshairs:before{
    content:"⊕";
}

.fa-jedi-order:before{
    content:"✦";
}


.screenFx{

    position:absolute;

    inset:0;

    z-index:1;

    background:

        linear-gradient(
            180deg,
            rgba(0,0,0,.10),
            transparent 13%,
            transparent 83%,
            rgba(0,0,0,.15)
        );

    pointer-events:none;

}


body.no-overlay .screenFx,
body.no-overlay .screenEdge,
body.no-overlay .screenCorner{

    display:none !important;

}


.screenEdge{

    position:absolute;

    z-index:2;

    opacity:.35;

}


.screenEdge.left{

    left:0;

    top:18vh;
    bottom:18vh;

    width:2px;

    background:

        linear-gradient(
            180deg,
            transparent,
            var(--yellow-soft) 16%,
            rgba(255,190,50,.12) 50%,
            var(--yellow-soft) 84%,
            transparent
        );

}


.screenEdge.right{

    right:0;

    top:18vh;
    bottom:18vh;

    width:2px;

    background:

        linear-gradient(
            180deg,
            transparent,
            rgba(255,190,50,.35) 16%,
            rgba(255,190,50,.08) 50%,
            rgba(255,190,50,.35) 84%,
            transparent
        );

}


.screenCorner{

    position:absolute;

    z-index:2;

    width:24px;
    height:24px;

    opacity:.30;

}


.screenCorner:before,
.screenCorner:after{

    content:"";

    position:absolute;

    background:var(--yellow);

}


.screenCorner:before{

    width:100%;
    height:1px;

}


.screenCorner:after{

    width:1px;
    height:100%;

}


.screenCorner.tl{

    left:1.2vw;
    top:2vh;

}


.screenCorner.tr{

    right:1.2vw;
    top:2vh;

    transform:scaleX(-1);

}


.screenCorner.bl{

    left:1.2vw;
    bottom:2vh;

    transform:scaleY(-1);

}


.screenCorner.br{

    right:1.2vw;
    bottom:2vh;

    transform:scale(-1);

}


.compass{

    position:absolute;

    top:1.55vh;
    left:50%;

    transform:translateX(-50%);

    width:clamp(390px,32vw,660px);

    height:54px;

    z-index:8;

    font-family:var(--font-main);

}


.compassLine{

    position:absolute;

    left:4%;
    right:4%;

    top:30px;

    height:1px;

    background:

        linear-gradient(
            90deg,

            transparent 0%,

            rgba(255,190,50,.16) 8%,

            rgba(255,190,50,.44) 35%,

            var(--yellow) 50%,

            rgba(255,190,50,.44) 65%,

            rgba(255,190,50,.16) 92%,

            transparent 100%
        );

}


.compassCenterMask{

    position:absolute;

    top:16px;

    left:50%;

    transform:translateX(-50%);

    width:75px;
    height:31px;

    background:

        linear-gradient(
            90deg,

            transparent,

            rgba(4,6,9,.80) 23%,

            rgba(4,6,9,.92) 50%,

            rgba(4,6,9,.80) 77%,

            transparent
        );

}


.compassMarker{

    position:absolute;

    left:50%;

    top:23px;

    width:2px;
    height:15px;

    transform:translateX(-50%);

    background:var(--yellow);

    box-shadow:
        0 0 6px rgba(255,190,50,.25);

}


.compassMarker:before{

    content:"";

    position:absolute;

    left:50%;

    top:-4px;

    width:5px;
    height:5px;

    transform:
        translateX(-50%)
        rotate(45deg);

    border-left:1px solid var(--yellow);
    border-top:1px solid var(--yellow);

}


.compassItems{

    position:absolute;

    left:3%;
    right:3%;

    top:0;

    height:48px;

    display:grid;

    grid-template-columns:repeat(5,1fr);

    align-items:end;

}


.compassItem{

    position:relative;

    padding-bottom:4px;

    text-align:center;

    font-size:clamp(7px,.47vw,10px);

    font-weight:600;

    letter-spacing:.16em;

    color:rgba(232,235,239,.43);

    white-space:nowrap;

}


.compassItem:nth-child(1),
.compassItem:nth-child(5){

    opacity:.46;

}


.compassItem:nth-child(2),
.compassItem:nth-child(4){

    opacity:.70;

}


.compassItem:after{

    content:"";

    position:absolute;

    left:50%;

    bottom:-5px;

    width:1px;
    height:5px;

    background:rgba(220,225,232,.25);

}


.compassItem.active{

    color:var(--white);

    opacity:1;

    font-weight:800;

    text-shadow:
        0 0 10px rgba(255,190,50,.10);

}


.compassItem.active:after{

    display:none;

}


.compassBearing{

    position:absolute;

    left:50%;

    top:0;

    transform:translateX(-50%);

    font-family:var(--font-title);

    font-size:clamp(13px,.82vw,17px);

    letter-spacing:.10em;

    color:var(--yellow);

    white-space:nowrap;

}


.compassBearing:before{

    content:"NAV // ";

    color:rgba(255,255,255,.22);

    font-family:var(--font-main);

    font-size:.54em;

    font-weight:700;

    letter-spacing:.18em;

}


.brand{

    position:absolute;

    right:2.1vw;
    top:2.0vh;

    z-index:8;

    width:clamp(210px,15vw,340px);

    display:flex;

    flex-direction:column;

    align-items:flex-end;

}


.brandMeta{

    width:100%;

    display:flex;

    justify-content:flex-end;

    align-items:center;

    gap:8px;

    margin-bottom:5px;

    font-size:clamp(6px,.36vw,8px);

    font-weight:700;

    letter-spacing:.18em;

    color:rgba(238,241,245,.25);

}


.brandMetaLine{

    width:31px;
    height:1px;

    background:var(--yellow);

    opacity:.72;

}


.brandLogo{

    position:relative;

    width:100%;

    display:flex;

    justify-content:flex-end;

    align-items:center;

}


.brandLogoImg{

    display:block;

    width:100%;

    max-width:clamp(210px,15vw,340px);

    height:auto;

    object-fit:contain;

    object-position:right center;

    filter:

        drop-shadow(
            0 0 8px rgba(255,190,50,.08)
        )

        drop-shadow(
            0 3px 8px rgba(0,0,0,.60)
        );

}


.leftStatus{

    position:absolute;

    left:2.15vw;

    bottom:3.4vh;

    width:clamp(205px,13vw,275px);

    z-index:8;

    display:flex;

    flex-direction:column;

    gap:10px;

}


.jetFuel{

    display:none;

    width:100%;

}


.jetFuel.visible{

    display:block;

}


.jetHeader{

    display:flex;

    align-items:center;

    justify-content:space-between;

    margin-bottom:4px;

    font-size:clamp(6px,.40vw,8px);

    font-weight:700;

    letter-spacing:.15em;

    color:rgba(255,255,255,.42);

}


.jetHeader strong{

    color:var(--yellow);

    font-weight:700;

}


.jetBar{

    position:relative;

    width:100%;
    height:5px;

    background:rgba(255,190,50,.10);

    border:1px solid rgba(255,190,50,.24);

    overflow:hidden;

}


.jetFuelFill{

    position:absolute;

    left:0;
    top:0;
    bottom:0;

    width:100%;

    background:rgb(255,190,50);

    box-shadow:
        0 0 8px rgba(255,190,50,.30);

    transition:
        width .08s linear,
        opacity .08s linear;

}


.jetFuel.low .jetFuelFill{

    opacity:.55;

}


.lscs{

    display:none;

    position:relative;

    width:100%;

    padding:
        clamp(8px,.55vw,11px)
        clamp(9px,.62vw,13px);

    border-left:2px solid var(--yellow);

    background:

        linear-gradient(
            90deg,

            rgba(10,13,17,.80),

            rgba(10,13,17,.37) 72%,

            transparent
        );

}


.lscs.visible{

    display:block;

}


.lscs:before{

    content:"";

    position:absolute;

    left:0;
    top:0;

    width:42%;
    height:1px;

    background:var(--yellow-soft);

}


.lscsHead{

    display:flex;

    align-items:center;

    gap:8px;

    margin-bottom:9px;

}


.lscsHead i{

    width:19px;

    text-align:center;

    font-size:14px;

    color:var(--yellow);

}


.lscsHeadText{

    flex:1;

    min-width:0;

    display:flex;

    align-items:baseline;

    justify-content:space-between;

    gap:7px;

}


.lscsStance{

    min-width:0;

    overflow:hidden;

    text-overflow:ellipsis;

    white-space:nowrap;

    font-family:var(--font-title);

    font-size:clamp(11px,.72vw,15px);

    letter-spacing:.08em;

    color:#f0ede5;

}


.lscsMode{

    flex:none;

    font-size:clamp(5px,.34vw,7px);

    font-weight:700;

    letter-spacing:.12em;

    color:rgba(255,255,255,.28);

}


.lscsRow{

    height:12px;

    display:grid;

    grid-template-columns:
        44px
        minmax(0,1fr)
        30px;

    align-items:center;

    gap:5px;

    margin-top:4px;

}


.lscsRow.hidden{

    display:none;

}


.lscsLabel,
.lscsValue{

    font-size:clamp(6px,.39vw,8px);

    font-weight:700;

    letter-spacing:.08em;

    color:rgba(255,255,255,.48);

}


.lscsValue{

    text-align:right;

}


.segments{

    height:5px;

    display:grid;

    grid-template-columns:repeat(12,minmax(0,1fr));

    gap:2px;

}


.seg{

    height:5px;

    background:rgba(255,255,255,.08);

    border:1px solid rgba(255,255,255,.07);

    transform:skewX(-12deg);

}


.force .seg.active{

    background:var(--yellow);

    border-color:rgba(255,190,50,.66);

}


.block .seg.active{

    background:#dadde3;

    border-color:rgba(255,255,255,.44);

}


.advantage .seg.active{

    background:#8d929b;

    border-color:rgba(255,255,255,.18);

}


.lscs.critical .block{

    animation:
        critical .48s steps(2,end) infinite;

}


@keyframes critical{

    50%{

        opacity:.25;

    }

}


.vitals{

    position:absolute;

    left:50%;

    bottom:2.65vh;

    transform:translateX(-50%);

    z-index:9;

    width:clamp(390px,28vw,575px);

    display:grid;

    grid-template-columns:
        auto
        minmax(180px,1fr)
        auto;

    align-items:center;

    gap:clamp(9px,.7vw,15px);

}


.vitalText{

    min-width:62px;

    display:flex;

    align-items:center;

    gap:7px;

    font-family:var(--font-title);

    font-size:clamp(21px,1.3vw,28px);

    letter-spacing:.03em;

    color:#f4f1e9;

}


.vitalText.right{

    justify-content:flex-end;

}


.faHud{

    width:19px;

    text-align:center;

    font-size:clamp(12px,.78vw,17px);

    color:var(--yellow);

    filter:

        drop-shadow(
            0 1px 3px rgba(0,0,0,.9)
        );

}


.vitalText.right .faHud{

    color:rgba(235,239,246,.70);

}


.lowHealth{

    color:var(--red);

}


.lowHealth .faHud{

    color:var(--red);

}


.vitalCenter{

    min-width:0;

}


.vitalTop{

    display:flex;

    justify-content:space-between;

    align-items:center;

    margin-bottom:4px;

    font-size:clamp(5px,.34vw,7px);

    font-weight:700;

    letter-spacing:.18em;

    color:rgba(255,255,255,.30);

}


.vitalTop .statusOnline{

    display:flex;

    align-items:center;

    gap:5px;

    color:rgba(255,190,50,.55);

}


.vitalTop .statusOnline:before{

    content:"";

    width:4px;
    height:4px;

    background:var(--yellow);

    transform:rotate(45deg);

}


.vitalBars{

    position:relative;

    width:100%;

}


.vitalBar{

    position:relative;

    width:100%;

    height:5px;

    margin-top:3px;

    overflow:hidden;

    background:rgba(255,255,255,.08);

}


.vitalBar:before{

    content:"";

    position:absolute;

    inset:0;

    background:

        repeating-linear-gradient(
            90deg,

            transparent 0,

            transparent calc(10% - 1px),

            rgba(0,0,0,.42) calc(10% - 1px),

            rgba(0,0,0,.42) 10%
        );

    z-index:2;

    pointer-events:none;

}


.fill{

    position:absolute;

    left:0;
    top:0;
    bottom:0;

    width:100%;

    transform-origin:left center;

    transition:
        width .10s linear;

}


.hpFill{

    background:

        linear-gradient(
            90deg,
            rgba(255,190,50,.55),
            var(--yellow)
        );

}


.armorFill{

    background:

        linear-gradient(
            90deg,
            rgba(185,192,202,.40),
            rgba(237,240,245,.78)
        );

}


.localVoice{

    position:absolute;

    left:50%;

    bottom:7.3vh;

    transform:translateX(-50%);

    z-index:9;

    display:flex;

    align-items:center;

    gap:6px;

    padding:4px 8px;

    border-left:1px solid transparent;

    font-size:clamp(6px,.4vw,8px);

    font-weight:700;

    letter-spacing:.16em;

    color:rgba(255,255,255,.28);

    opacity:0;

    transition:
        opacity .12s,
        color .12s,
        border-color .12s,
        background .12s;

}


.localVoice.visible{

    opacity:1;

}


.localVoice.active{

    color:var(--yellow);

    border-color:var(--yellow);

    background:

        linear-gradient(
            90deg,
            rgba(255,190,50,.08),
            transparent
        );

}


.voiceBars{

    display:flex;

    align-items:flex-end;

    gap:2px;

    height:10px;

}


.voiceBars span{

    width:2px;

    background:currentColor;

}


.voiceBars span:nth-child(1){
    height:3px;
}

.voiceBars span:nth-child(2){
    height:6px;
}

.voiceBars span:nth-child(3){
    height:10px;
}

.voiceBars span:nth-child(4){
    height:5px;
}


.localVoice.active .voiceBars span{

    animation:
        vPulse .44s ease-in-out infinite alternate;

}


.localVoice.active .voiceBars span:nth-child(2){

    animation-delay:.07s;

}


.localVoice.active .voiceBars span:nth-child(3){

    animation-delay:.14s;

}


.localVoice.active .voiceBars span:nth-child(4){

    animation-delay:.21s;

}


@keyframes vPulse{

    from{

        transform:scaleY(.35);

    }

    to{

        transform:scaleY(1);

    }

}


.speakerCard{

    position:absolute;

    right:2.15vw;

    bottom:16.8vh;

    z-index:8;

    width:clamp(190px,13vw,275px);

    opacity:0;

    transform:translateY(4px);

    transition:
        opacity .12s,
        transform .12s;

}


.speakerCard.visible{

    opacity:1;

    transform:none;

}


.speakerTop{

    display:flex;

    align-items:center;

    justify-content:flex-end;

    gap:7px;

    padding-bottom:5px;

}


.speakerLabel{

    font-size:clamp(5px,.33vw,7px);

    font-weight:700;

    letter-spacing:.16em;

    color:rgba(255,255,255,.27);

}


.speakerRow{

    display:flex;

    align-items:center;

    justify-content:flex-end;

    gap:7px;

}


.speakerRow i{

    font-size:10px;

    color:var(--yellow);

}


.speakerName{

    max-width:215px;

    overflow:hidden;

    text-overflow:ellipsis;

    white-space:nowrap;

    font-family:var(--font-title);

    font-size:clamp(12px,.75vw,16px);

    letter-spacing:.06em;

}


.speakerLine{

    position:relative;

    height:1px;

    margin-top:5px;

    background:

        linear-gradient(
            90deg,
            transparent,
            rgba(255,190,50,.18) 40%,
            var(--yellow)
        );

}


.speakerLine:after{

    content:"";

    position:absolute;

    right:0;

    top:-2px;

    width:5px;
    height:5px;

    background:var(--yellow);

}


.comms{

    position:absolute;

    right:2.15vw;

    bottom:3.35vh;

    z-index:9;

    width:clamp(245px,17vw,345px);

    text-align:right;

}


.comms.hidden{

    display:none;

}


.commsHead{

    display:flex;

    align-items:center;

    justify-content:flex-end;

    gap:7px;

    margin-bottom:6px;

}


.commsTitle{

    font-size:clamp(5px,.34vw,7px);

    font-weight:700;

    letter-spacing:.17em;

    color:rgba(255,255,255,.26);

}


.commsHeadLine{

    width:36px;
    height:1px;

    background:var(--yellow);

}


.commsMeta{

    margin-bottom:8px;

    font-size:clamp(7px,.47vw,10px);

    font-weight:500;

    letter-spacing:.04em;

    color:rgba(255,255,255,.54);

    white-space:nowrap;

}


.commsMeta strong{

    color:var(--white);

}


.commsMeta .yellow{

    color:var(--yellow);

}


.commsActions{

    display:flex;

    align-items:center;

    justify-content:flex-end;

    gap:7px;

}


.systemIcon{

    width:29px;
    height:29px;

    display:grid;

    place-items:center;

    border:1px solid rgba(255,255,255,.20);

    background:rgba(11,14,18,.60);

    font-size:10px;

    color:rgba(255,255,255,.45);

    clip-path:

        polygon(
            3px 0,

            100% 0,

            100% calc(100% - 3px),

            calc(100% - 3px) 100%,

            0 100%,

            0 3px
        );

}


.systemIcon.active{

    border-color:rgba(255,190,50,.72);

    color:var(--yellow);

    background:rgba(255,190,50,.06);

}


.systemIcon.inactive{

    opacity:.55;

}


.ammoBlock{

    display:flex;

    align-items:center;

    gap:7px;

    min-width:94px;

    justify-content:flex-end;

}


.ammoType{

    font-size:9px;

    color:var(--yellow);

    opacity:.85;

}


.ammoWrap{

    display:flex;

    align-items:baseline;

    gap:3px;

}


.ammoClip{

    font-family:var(--font-title);

    font-size:clamp(22px,1.35vw,29px);

    line-height:1;

    letter-spacing:.02em;

    color:#f3efe6;

}


.ammoReserve{

    font-size:clamp(7px,.44vw,9px);

    font-weight:600;

    color:rgba(255,255,255,.38);

}


.divider{

    width:1px;

    height:29px;

    margin:0 2px;

    background:

        linear-gradient(
            transparent,
            rgba(255,190,50,.60),
            transparent
        );

}


.radioState{

    font-weight:800;

}


.radioState.on{

    color:var(--yellow);

}


.radioState.off{

    color:rgba(255,255,255,.35);

}


.radioState.lost{

    color:var(--red);

}


.debug{

    position:absolute;

    right:1vw;

    bottom:.5vh;

    z-index:20;

    font:
        9px
        Consolas,
        "Courier New",
        monospace;

    line-height:1.25;

    text-align:left;

    color:rgba(255,255,255,.42);

}


.debug.hidden{

    display:none;

}


#ammoIcon{

    display:none;

}


.weaponSwitch{

    position:absolute;

    top:calc(1.55vh + 68px);
    left:50%;

    z-index:10;

    display:flex;

    flex-direction:column;

    align-items:stretch;

    opacity:0;

    transform:translate(-50%,-6px);

    transition:
        opacity .12s ease,
        transform .12s ease;

    font-family:var(--font-title);

    text-shadow:
        0 1px 2px rgba(0,0,0,.85),
        0 0 6px rgba(0,0,0,.55);

}


.weaponSwitch.visible{

    opacity:1;

    transform:translate(-50%,0);

}


/* slot number bar: 1 2 3 4 5 ... */
.wsRow{

    display:flex;

    align-items:flex-end;

    justify-content:center;

    gap:clamp(14px,1.25vw,26px);

    padding:0 clamp(6px,.5vw,10px) 3px;

}


.wsSlot{

    position:relative;

    display:flex;

    justify-content:center;

    min-width:clamp(16px,1.1vw,22px);

}


.wsSlotNum{

    font-family:var(--font-title);

    font-size:clamp(26px,1.75vw,36px);

    line-height:.9;

    letter-spacing:.02em;

    color:transparent;

    -webkit-text-stroke:1px rgba(244,241,233,.55);

    text-shadow:none;

    transition:color .1s ease, -webkit-text-stroke-color .1s ease;

}


.wsSlot.empty .wsSlotNum{

    -webkit-text-stroke-color:rgba(244,241,233,.22);

}


.wsSlot.open .wsSlotNum{

    color:var(--white);

    -webkit-text-stroke:1px var(--white);

    text-shadow:
        0 0 8px rgba(255,190,50,.45),
        0 1px 2px rgba(0,0,0,.85);

}


/* small accent mark under the opened slot */
.wsSlot.open:after{

    content:"";

    position:absolute;

    left:15%;
    right:15%;
    bottom:-5px;

    height:2px;

    background:var(--yellow);

    box-shadow:0 0 6px rgba(255,190,50,.6);

}


/* thin divider line under the numbers */
.wsLine{

    height:1px;

    background:
        linear-gradient(
            90deg,
            rgba(244,241,233,0),
            rgba(244,241,233,.85) 8%,
            rgba(244,241,233,.85) 92%,
            rgba(244,241,233,0)
        );

    box-shadow:0 1px 2px rgba(0,0,0,.6);

}


/* weapon list of the opened slot */
.wsList{

    position:relative;

    height:0;

}


.wsItems{

    position:absolute;

    top:6px;

    display:flex;

    flex-direction:column;

    align-items:center;

    gap:1px;

    transform:translateX(-50%);

    white-space:nowrap;

}


.wsItem{

    position:relative;

    display:flex;

    align-items:baseline;

    gap:8px;

    padding:0 4px;

}


.wsName{

    font-family:var(--font-title);

    font-size:clamp(20px,1.4vw,28px);

    line-height:1.08;

    letter-spacing:.03em;

    color:rgba(244,241,233,.82);

}


.wsAmmo{

    font-family:var(--font-main);

    font-size:clamp(8px,.5vw,10px);

    font-weight:700;

    letter-spacing:.1em;

    color:rgba(244,241,233,.40);

}


.wsAmmo:empty{

    display:none;

}


.wsItem.selected .wsName{

    color:var(--yellow);

    text-shadow:
        0 0 10px rgba(255,190,50,.45),
        0 1px 2px rgba(0,0,0,.9);

}


.wsItem.selected .wsAmmo{

    color:var(--yellow-soft);

}


.wsItem.equipped .wsName:after{

    content:"\2022";

    margin-left:6px;

    font-size:.6em;

    vertical-align:middle;

    color:var(--yellow-soft);

}


.wsItem.noammo .wsName,
.wsItem.noammo .wsAmmo{

    color:var(--red);

}


.wsHint{

    position:absolute;

    bottom:calc(100% + 4px);
    right:clamp(6px,.5vw,10px);

    font-family:var(--font-main);

    font-size:clamp(6px,.38vw,8px);

    font-weight:700;

    letter-spacing:.17em;

    color:rgba(244,241,233,.32);

}


.wsHint .yellow{

    color:var(--yellow);

}


@media(max-width:1600px){

    .brand{

        right:1.8vw;

    }


    .leftStatus{

        left:1.8vw;

    }


    .comms{

        right:1.8vw;

    }


    .speakerCard{

        right:1.8vw;

    }

}


@media(max-width:1280px){

    .compass{

        width:39vw;

        min-width:375px;

    }


    .brand{

        transform:scale(.90);

        transform-origin:right top;

    }


    .leftStatus{

        width:205px;

    }


    .comms{

        transform:scale(.90);

        transform-origin:right bottom;

    }


    .speakerCard{

        transform-origin:right bottom;

    }


    .vitals{

        width:430px;

    }

}


@media(max-height:760px){

    .brand{

        top:1.5vh;

        transform:scale(.84);

        transform-origin:right top;

    }


    .compass{

        top:.7vh;

        transform:
            translateX(-50%)
            scale(.90);

        transform-origin:center top;

    }


    .leftStatus{

        bottom:2.6vh;

        transform:scale(.88);

        transform-origin:left bottom;

    }


    .comms{

        bottom:2.6vh;

        transform:scale(.82);

        transform-origin:right bottom;

    }


    .speakerCard{

        bottom:15vh;

        transform-origin:right bottom;

    }


    .speakerCard.visible{

        transform:scale(.88);

    }


    .vitals{

        bottom:2.3vh;

        transform:
            translateX(-50%)
            scale(.90);

        transform-origin:center bottom;

    }


    .localVoice{

        bottom:7.8vh;

    }

}


@media(max-width:1000px){

    .compass{

        width:43vw;

        min-width:350px;

    }


    .brand{

        transform:scale(.78);

        transform-origin:right top;

    }


    .leftStatus{

        left:1.5vw;

        transform:scale(.80);

        transform-origin:left bottom;

    }


    .comms{

        right:1.5vw;

        transform:scale(.76);

        transform-origin:right bottom;

    }


    .speakerCard{

        display:none;

    }


    .vitals{

        width:390px;

    }

}


@media(max-width:720px){

    .brandMeta{

        display:none;

    }


    .brand{

        transform:scale(.66);

    }


    .compass{

        min-width:310px;

    }


    .leftStatus{

        transform:scale(.67);

    }


    .comms{

        transform:scale(.64);

    }


    .vitals{

        width:340px;

        grid-template-columns:
            auto
            1fr
            auto;

        gap:7px;

    }


    .vitalText{

        min-width:46px;

    }

}

</style>
</head>


<body>

<div id="hud">


    <div class="screenFx"></div>

    <div class="screenEdge left"></div>
    <div class="screenEdge right"></div>

    <div class="screenCorner tl"></div>
    <div class="screenCorner tr"></div>
    <div class="screenCorner bl"></div>
    <div class="screenCorner br"></div>


    <div class="compass">

        <div class="compassLine"></div>

        <div class="compassCenterMask"></div>

        <div class="compassMarker"></div>


        <div
            class="compassBearing"
            id="bearing"
        >
            000°
        </div>


        <div class="compassItems">


            <div
                class="compassItem"
                id="compassFarLeft"
            >
                WEST
            </div>


            <div
                class="compassItem"
                id="compassLeft"
            >
                NORTHWEST
            </div>


            <div class="compassItem active">

                <span id="direction">
                    N
                </span>

            </div>


            <div
                class="compassItem"
                id="compassRight"
            >
                NORTHEAST
            </div>


            <div
                class="compassItem"
                id="compassFarRight"
            >
                EAST
            </div>


        </div>

    </div>


    <div class="brand">


        <div class="brandMeta">

            <span id="dateText">
                00/00/0000
            </span>

            <span class="brandMetaLine"></span>

            <span>
                CLONE WARS ROLEPLAY
            </span>

        </div>


    </div>


    <div
        class="leftStatus"
        id="leftStatus"
    >


        <div
            class="jetFuel"
            id="jetFuel"
        >


            <div class="jetHeader">

                <span>
                    JETPACK FUEL
                </span>

                <strong id="jetFuelValue">
                    100%
                </strong>

            </div>


            <div class="jetBar">

                <div
                    class="jetFuelFill"
                    id="jetFuelFill"
                ></div>

            </div>


        </div>


        <div
            class="lscs"
            id="lscs"
        >


            <div class="lscsHead">


                <i class="fa-brands fa-jedi-order"></i>


                <div class="lscsHeadText">


                    <span
                        class="lscsStance"
                        id="lscsStance"
                    >
                        NO STANCE
                    </span>


                    <span
                        class="lscsMode"
                        id="lscsMode"
                    >
                        LSCS
                    </span>


                </div>


            </div>


            <div
                class="lscsRow force"
                id="lscsForceRow"
            >

                <span class="lscsLabel">
                    FORCE
                </span>


                <span
                    class="segments"
                    id="forceSegments"
                ></span>


                <span
                    class="lscsValue"
                    id="forceValue"
                >
                    100%
                </span>

            </div>


            <div
                class="lscsRow block"
                id="lscsBlockRow"
            >

                <span class="lscsLabel">
                    BLOCK
                </span>


                <span
                    class="segments"
                    id="blockSegments"
                ></span>


                <span
                    class="lscsValue"
                    id="blockValue"
                >
                    100%
                </span>

            </div>


            <div
                class="lscsRow advantage"
                id="lscsAdvantageRow"
            >

                <span class="lscsLabel">
                    ADV
                </span>


                <span
                    class="segments"
                    id="advantageSegments"
                ></span>


                <span
                    class="lscsValue"
                    id="advantageValue"
                >
                    0%
                </span>

            </div>


        </div>


    </div>


    <div
        class="localVoice"
        id="localVoice"
    >


        <i class="fa-solid fa-microphone"></i>


        <span>
            VOICE TRANSMISSION
        </span>


        <span class="voiceBars">

            <span></span>
            <span></span>
            <span></span>
            <span></span>

        </span>


    </div>


    <div class="vitals">


        <div
            class="vitalText"
            id="healthBox"
        >


            <i class="fa-solid fa-heart-pulse faHud"></i>


            <span id="healthText">
                100
            </span>


        </div>


        <div class="vitalCenter">


            <div class="vitalTop">


                <span id="vitalPlayerName">
                    PLAYER
                </span>


                <span class="statusOnline">
                    ONLINE
                </span>


            </div>


            <div class="vitalBars">


                <div class="vitalBar">

                    <div
                        class="fill hpFill"
                        id="healthFill"
                    ></div>

                </div>


                <div class="vitalBar">

                    <div
                        class="fill armorFill"
                        id="armorFill"
                    ></div>

                </div>


            </div>


        </div>


        <div class="vitalText right">


            <span id="armorText">
                0
            </span>


            <i class="fa-solid fa-shield-halved faHud"></i>


        </div>


    </div>


    <div
        class="speakerCard"
        id="speakerCard"
    >


        <div class="speakerTop">

            <span class="speakerLabel">
                ACTIVE TRANSMISSION
            </span>

        </div>


        <div class="speakerRow">


            <i class="fa-solid fa-volume-high"></i>


            <span
                class="speakerName"
                id="speakerName"
            >
                CT-0000
            </span>


        </div>


        <div class="speakerLine"></div>


    </div>


    <div
        class="comms"
        id="comms"
    >


        <div class="commsHead">


            <span class="commsTitle">
                REPUBLIC COMMS SYSTEM
            </span>


            <span class="commsHeadLine"></span>


        </div>


        <div class="commsMeta">


            FREQ


            <strong
                class="yellow"
                id="frequency"
            >
                100
            </strong>


            &nbsp; // &nbsp;


            RADIO


            <strong
                class="radioState off"
                id="radioState"
            >
                OFF
            </strong>


        </div>


        <div class="commsActions">


            <div
                class="systemIcon"
                id="ammoIcon"
            >

                <i class="fa-solid fa-crosshairs"></i>

            </div>


            <div
                class="ammoBlock"
                id="ammoBlock"
            >


                <span class="ammoType">
                    //
                </span>


                <div
                    class="ammoWrap"
                    id="ammoWrap"
                >


                    <span
                        class="ammoClip"
                        id="ammoClip"
                    >
                        --
                    </span>


                    <span
                        class="ammoReserve"
                        id="ammoReserve"
                    >
                        / --
                    </span>


                </div>


            </div>


            <div class="divider"></div>


            <div
                class="systemIcon inactive"
                id="radioIcon"
            >


                <i class="fa-solid fa-tower-broadcast"></i>


            </div>


            <div
                class="systemIcon inactive"
                id="voiceIcon"
            >


                <i
                    class="fa-solid fa-microphone-slash"
                    id="voiceIconGlyph"
                ></i>


            </div>


        </div>


    </div>


    <div
        class="weaponSwitch"
        id="weaponSwitch"
    >


        <div
            class="wsRow"
            id="wsRow"
        ></div>


        <div class="wsLine"></div>


        <div
            class="wsHint"
            id="wsHint"
        >

            <span class="yellow">LMB</span> SELECT
            &nbsp; // &nbsp;
            <span class="yellow">RMB</span> CANCEL

        </div>


        <div
            class="wsList"
            id="wsList"
        ></div>


    </div>


    <div
        class="debug hidden"
        id="debug"
    >
    </div>


</div>


<script>

(function(){

    "use strict";


    var $ = function(id){

        return document.getElementById(id);

    };


    var compassShort = [

        "N",
        "NE",
        "E",
        "SE",
        "S",
        "SW",
        "W",
        "NW"

    ];


    var compassLong = [

        "NORTH",
        "NORTHEAST",
        "EAST",
        "SOUTHEAST",
        "SOUTH",
        "SOUTHWEST",
        "WEST",
        "NORTHWEST"

    ];


    var segmentCount = 12;


    function clamp(v,a,b){

        return Math.max(
            a,
            Math.min(b,v)
        );

    }


    function pad(v){

        return v < 10
            ? "0" + v
            : String(v);

    }


    function updateClock(){

        var d = new Date();


        $("dateText").textContent =

            pad(d.getDate())

            + "/"

            + pad(d.getMonth()+1)

            + "/"

            + d.getFullYear();

    }


    updateClock();


    setInterval(

        updateClock,

        1000

    );


    function buildSegments(id){

        var box = $(id);


        if(
            !box ||
            box.children.length
        ){

            return;

        }


        for(
            var i = 0;
            i < segmentCount;
            i++
        ){

            var s =
                document.createElement("span");


            s.className =
                "seg";


            box.appendChild(s);

        }

    }


    function setSegments(
        id,
        value,
        maxValue
    ){

        var box =
            $(id);


        if(!box){

            return 0;

        }


        var max =

            Math.max(

                .001,

                Number(maxValue) || 1

            );


        var ratio =

            clamp(

                (Number(value) || 0)
                /
                max,

                0,

                1

            );


        var active =

            Math.round(

                ratio
                *
                segmentCount

            );


        for(
            var i = 0;
            i < box.children.length;
            i++
        ){

            box.children[i].className =

                "seg"

                +

                (
                    i < active

                    ? " active"

                    : ""
                );

        }


        return Math.round(

            ratio
            *
            100

        );

    }


    buildSegments(
        "forceSegments"
    );


    buildSegments(
        "blockSegments"
    );


    buildSegments(
        "advantageSegments"
    );


    window.GRN_HUD = {


        setOverlay:function(on){

            document.body.classList.toggle(
                "no-overlay",
                !on
            );

        },


        show:function(on){

            $("hud").style.display =

                on
                ? "block"
                : "none";

        },


        setBrand:function(value){

            var img =
                $("brandLogoImg");


            if(!img){

                return;

            }


            if(
                typeof value === "string"
                &&
                /^https?:\/\//i.test(value)
            ){

                img.src =
                    value;

                return;

            }


            img.alt =
                String(
                    value ||
                    "Echoes of Clones"
                );

        },


        setPlayerName:function(name){

            var el = $("vitalPlayerName");

            if(el){
                el.textContent = String(name || "PLAYER").toUpperCase();
            }

        },


        setHealthArmor:function(
            hp,
            maxHp,
            armor,
            maxArmor
        ){

            var h =

                Math.max(
                    0,
                    Math.floor(
                        Number(hp) || 0
                    )
                );


            var hm =

                Math.max(
                    1,
                    Math.floor(
                        Number(maxHp) || 100
                    )
                );


            var a =

                Math.max(
                    0,
                    Math.floor(
                        Number(armor) || 0
                    )
                );


            var am =

                Math.max(
                    1,
                    Math.floor(
                        Number(maxArmor) || 100
                    )
                );


            $("healthText").textContent =
                h;


            $("armorText").textContent =
                a;


            $("healthFill").style.width =

                (
                    clamp(
                        h / hm,
                        0,
                        1
                    )
                    *
                    100
                )

                .toFixed(2)

                +

                "%";


            $("armorFill").style.width =

                (
                    clamp(
                        a / am,
                        0,
                        1
                    )
                    *
                    100
                )

                .toFixed(2)

                +

                "%";


            $("healthBox").classList.toggle(

                "lowHealth",

                h / hm <= .25

            );

        },


        setCompass:function(angle){

            var a =

                (
                    (
                        Math.floor(
                            Number(angle) || 0
                        )

                        %
                        360
                    )

                    +
                    360
                )

                %
                360;


            var idx =

                Math.round(
                    a / 45
                )

                %
                8;


            var bearing =

                (
                    a < 10

                    ? "00"

                    :

                    a < 100

                    ? "0"

                    : ""
                )

                +

                a

                +

                "°";


            $("bearing").textContent =
                bearing;


            $("direction").textContent =
                compassShort[idx];


            $("compassFarLeft").textContent =

                compassLong[
                    (idx + 6) % 8
                ];


            $("compassLeft").textContent =

                compassLong[
                    (idx + 7) % 8
                ];


            $("compassRight").textContent =

                compassLong[
                    (idx + 1) % 8
                ];


            $("compassFarRight").textContent =

                compassLong[
                    (idx + 2) % 8
                ];

        },


        setRadarVisible:function(on){

            return;

        },


        setRadar:function(points,range){

            return;

        },


        setRadarColors:function(
            ally,
            enemy,
            neutral
        ){

            return;

        },


        setLocalVoice:function(
            show,
            active
        ){

            var enabled =

                !!show
                &&
                !!active;


            $("localVoice").classList.toggle(
                "visible",
                enabled
            );


            $("localVoice").classList.toggle(
                "active",
                !!active
            );


            $("voiceIcon").classList.toggle(
                "active",
                !!active
            );


            $("voiceIcon").classList.toggle(
                "inactive",
                !active
            );


            $("voiceIconGlyph").className =

                active

                ? "fa-solid fa-microphone"

                : "fa-solid fa-microphone-slash";

        },


        setSpeaker:function(
            name,
            visible
        ){

            $("speakerName").textContent =

                String(
                    name ||
                    ""
                );


            $("speakerCard").classList.toggle(
                "visible",
                !!visible
            );

        },


        setRadioVisible:function(on){

            $("comms").classList.toggle(
                "hidden",
                !on
            );

        },


        setRadio:function(
            frequency,
            on,
            state
        ){

            var mode =

                String(
                    state ||
                    ""
                );


            $("frequency").textContent =

                String(

                    frequency == null

                    ? "--"

                    : frequency

                );


            $("radioState").textContent =

                on

                ? "ON"

                : "OFF";


            $("radioState").className =

                "radioState "

                +

                (
                    mode === "lost"

                    ? "lost"

                    :

                    on

                    ? "on"

                    : "off"
                );


            $("radioIcon").classList.toggle(
                "active",
                !!on
            );


            $("radioIcon").classList.toggle(
                "inactive",
                !on
            );

        },


        setAmmo:function(
            clip,
            reserve,
            show
        ){

            $("ammoBlock").style.display =

                show

                ? "flex"

                : "none";


            $("ammoWrap").style.display =

                show

                ? "flex"

                : "none";


            $("ammoClip").textContent =

                show

                ? String(clip)

                : "--";


            $("ammoReserve").textContent =

                show

                ? "/ " + String(reserve)

                : "/ --";

        },


        setJetFuel:function(data){

            data =
                data ||
                {};


            var visible =
                !!data.visible;


            $("jetFuel").classList.toggle(
                "visible",
                visible
            );


            if(!visible){

                $("jetFuelFill").style.width =
                    "0%";


                $("jetFuelValue").textContent =
                    "0%";


                return;

            }


            var max =

                Math.max(
                    .001,
                    Number(data.max) || 1
                );


            var ratio =

                clamp(

                    (Number(data.value) || 0)
                    /
                    max,

                    0,

                    1

                );


            $("jetFuelFill").style.width =

                (ratio * 100).toFixed(2)

                +

                "%";


            $("jetFuelValue").textContent =

                Math.round(
                    ratio * 100
                )

                +

                "%";


            $("jetFuel").classList.toggle(

                "low",

                ratio <= .2

            );

        },


        setLSCS:function(data){

            data =
                data ||
                {};


            var visible =
                !!data.visible;


            var weapon =
                !!data.weapon;


            $("lscs").classList.toggle(
                "visible",
                visible
            );


            if(!visible){

                return;

            }


            $("lscs").classList.toggle(
                "critical",
                !!data.critical
            );


            $("lscsStance").textContent =

                weapon

                ? String(
                    data.stance ||
                    "NO STANCE"
                )

                : "FORCE RESERVE";


            $("lscsMode").textContent =

                weapon

                ? "LSCS // COMBAT"

                : "LSCS // FORCE";


            $("lscsBlockRow").classList.toggle(

                "hidden",

                !weapon
                ||
                !data.autoBlock

            );


            $("lscsAdvantageRow").classList.toggle(

                "hidden",

                !weapon

            );


            $("forceValue").textContent =

                setSegments(
                    "forceSegments",
                    data.force,
                    data.forceMax
                )

                +

                "%";


            $("blockValue").textContent =

                setSegments(
                    "blockSegments",
                    data.block,
                    data.blockMax
                )

                +

                "%";


            $("advantageValue").textContent =

                setSegments(
                    "advantageSegments",
                    data.advantage,
                    1
                )

                +

                "%";

        },


        setWeaponSwitch:function(data){

            var root = $("weaponSwitch");
            var row = $("wsRow");
            var list = $("wsList");

            if(!root || !row || !list){
                return;
            }

            data = data || {};

            if(!data.visible){
                root.classList.remove("visible");
                return;
            }

            var esc = function(v){
                return String(v == null ? "" : v)
                    .replace(/&/g,"&amp;")
                    .replace(/</g,"&lt;")
                    .replace(/>/g,"&gt;")
                    .replace(/"/g,"&quot;");
            };

            var slots = data.slots || [];
            var rowHtml = "";
            var itemsHtml = "";

            for(var i = 0; i < slots.length; i++){

                var slot = slots[i] || {};
                var open = slot.slot === data.activeSlot;
                var weapons = slot.weapons || [];
                var label = slot.slot === 10 ? 0 : slot.slot;

                rowHtml +=
                    '<div class="wsSlot' +
                    (open ? " open" : "") +
                    (slot.count > 0 ? "" : " empty") +
                    '"' + (open ? ' id="wsOpenSlot"' : '') + '>' +
                    '<span class="wsSlotNum">' + esc(label) + '</span>' +
                    '</div>';

                if(open){

                    for(var j = 0; j < weapons.length; j++){

                        var w = weapons[j] || {};

                        itemsHtml +=
                            '<div class="wsItem' +
                            (w.selected ? " selected" : "") +
                            (w.equipped ? " equipped" : "") +
                            (w.noAmmo ? " noammo" : "") +
                            '"><span class="wsName">' + esc(w.name) + '</span>' +
                            '<span class="wsAmmo">' + esc(w.noAmmo ? "NO AMMO" : (w.ammo || "")) + '</span>' +
                            '</div>';

                    }

                }

            }

            row.innerHTML = rowHtml;
            list.innerHTML = itemsHtml !== "" ? '<div class="wsItems" id="wsItems">' + itemsHtml + '</div>' : "";

            // center the weapon list under the opened slot number
            var openSlot = $("wsOpenSlot");
            var items = $("wsItems");

            if(openSlot && items){
                items.style.left = (openSlot.offsetLeft + openSlot.offsetWidth / 2) + "px";
            }

            if($("wsHint")){
                $("wsHint").style.display = data.fast ? "none" : "";
            }

            root.classList.add("visible");

        },


        setDebugVisible:function(on){

            $("debug").classList.toggle(
                "hidden",
                !on
            );

        },


        setDebug:function(text){

            $("debug").innerHTML =

                String(
                    text ||
                    ""
                )

                .replace(
                    /\n/g,
                    "<br>"
                );

        }

    };


    try{

        if(
            window.gmod
            &&
            typeof window.gmod.grnHudReady ===
            "function"
        ){

            window.gmod.grnHudReady(
                "echoes of clones hud ready"
            );

        }

    }

    catch(e){}


    setTimeout(function(){

        try{


            var pre1 =
                document.createElement("link");


            pre1.rel =
                "preconnect";


            pre1.href =
                "https://fonts.googleapis.com";


            document.head.appendChild(pre1);


            var pre2 =
                document.createElement("link");


            pre2.rel =
                "preconnect";


            pre2.href =
                "https://fonts.gstatic.com";


            pre2.crossOrigin =
                "anonymous";


            document.head.appendChild(pre2);


            var fonts =
                document.createElement("link");


            fonts.rel =
                "stylesheet";


            fonts.href =
                "https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap";


            document.head.appendChild(fonts);


            var fa =
                document.createElement("link");


            fa.rel =
                "stylesheet";


            fa.href =
                "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css";


            document.head.appendChild(fa);


        }

        catch(e){}


    },0);


})();

</script>

</body>
</html>
]=]

local function buildHTML()
    return HTML_TEMPLATE
end

local function jsQuote(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\"):gsub("\r", ""):gsub("\n", "\\n"):gsub('"', '\\"')
    return '"' .. value .. '"'
end

local function boolJS(value)
    return value and "true" or "false"
end


local rootPanel
local htmlPanel
local lastSizeW, lastSizeH = 0, 0
local documentReady = false
local documentReadyReported = false
local clientReadySent = false
local nextCreateAttempt = 0
local createAttempt = 0

local function safeTransparent(panel)
    if not IsValid(panel) then return end
    if panel.SetPaintBackground then panel:SetPaintBackground(false) end
    if panel.SetBackgroundColor then panel:SetBackgroundColor(Color(0, 0, 0, 0)) end
end

local function runJS(code)
    if not documentReady or not IsValid(htmlPanel) then return end
    htmlPanel:QueueJavascript(code)
end

local function optimizationAllowsHUD()
    if GRN_MENU_OPT and GRN_MENU_OPT.GetSetting then
        local mode = GRN_MENU_OPT.GetSetting("hud")
        if mode ~= nil and mode == "low" then return false end
    end
    return true
end

function GRN_HUDV1_OptimizationAllowsHighHUD()
    return optimizationAllowsHUD()
end

local function shouldRender()
    return C.Enabled and State.enabled and optimizationAllowsHUD()
end

local function reportClientReady(reason)
    if documentReadyReported then return end
    documentReadyReported = true

    if not clientReadySent then
        clientReadySent = true
        net.Start(READY_NET)
        net.SendToServer()
    end
end

local function applyStaticConfig()
    if not documentReady then return end
    runJS("GRN_HUD.setOverlay(" .. boolJS(State.overlay and C.ShowScreenOverlay ~= false) .. ");")
    runJS("GRN_HUD.setBrand(" .. jsQuote(C.BrandLogoURL or "https://r2.fivemanage.com/CAL8kaFVELoEmru99DXu6/scheres_eoc_logo.png") .. ");")
    runJS("GRN_HUD.setRadioVisible(" .. boolJS(C.ShowRadioPanel ~= false) .. ");")
    runJS("GRN_HUD.setDebugVisible(" .. boolJS(C.ShowDebugStats == true) .. ");")
    runJS("GRN_HUD.setLSCS({visible:false});")
    runJS("GRN_HUD.setJetFuel({visible:false});")
    runJS("GRN_HUD.setWeaponSwitch({visible:false});")
end

local function removeHUDPanels()
    documentReady = false
    if IsValid(htmlPanel) then htmlPanel:Remove() end
    if IsValid(rootPanel) then rootPanel:Remove() end
    htmlPanel = nil
    rootPanel = nil
    lastSizeW, lastSizeH = 0, 0
end

local function markDocumentReady(reason)
    if documentReady or not IsValid(htmlPanel) then return end
    documentReady = true
    applyStaticConfig()
    GRN_HUDV1._forceRefresh = true
    reportClientReady(reason)
end

local function ensureHUD()
    if IsValid(rootPanel) and IsValid(htmlPanel) then return true end

    local now = RealTime()
    if now < nextCreateAttempt then return false end
    nextCreateAttempt = now + 1
    createAttempt = createAttempt + 1

    if not vgui or not vgui.Create then
        loadError("VGUI is not available yet. HUD creation will be retried.")
        return false
    end

    documentReady = false
    removeHUDPanels()

    rootPanel = vgui.Create("DPanel")
    if not IsValid(rootPanel) then
        loadError("Failed to create the root DPanel. Retrying in one second.")
        return false
    end

    rootPanel:SetPos(0, 0)
    rootPanel:SetSize(ScrW(), ScrH())
    rootPanel:SetMouseInputEnabled(false)
    rootPanel:SetKeyboardInputEnabled(false)
    rootPanel.Paint = nil
    safeTransparent(rootPanel)
    if rootPanel.ParentToHUD then rootPanel:ParentToHUD() end

    htmlPanel = vgui.Create("DHTML", rootPanel)
    if not IsValid(htmlPanel) then
        loadError("Failed to create the DHTML panel. Retrying in one second.")
        rootPanel:Remove()
        rootPanel = nil
        return false
    end

    htmlPanel:SetPos(0, 0)
    htmlPanel:SetSize(ScrW(), ScrH())
    htmlPanel:SetMouseInputEnabled(false)
    htmlPanel:SetKeyboardInputEnabled(false)
    if htmlPanel.SetScrollbars then htmlPanel:SetScrollbars(false) end
    safeTransparent(htmlPanel)

    if htmlPanel.AddFunction then
        htmlPanel:AddFunction("gmod", "grnHudReady", function(reason)
            markDocumentReady(reason or "JavaScript bridge")
        end)
    end

    local function probeJavaScriptReady(reason)
        if documentReady or not IsValid(htmlPanel) then return end
        htmlPanel:QueueJavascript([[
            try {
                if (window.GRN_HUD && window.gmod && typeof window.gmod.grnHudReady === "function") {
                    window.gmod.grnHudReady("Lua probe");
                }
            } catch (e) {}
        ]])
    end

    htmlPanel.OnDocumentReady = function(_, url)
        timer.Simple(0, function() probeJavaScriptReady("OnDocumentReady") end)
    end


    htmlPanel.OnFinishLoadingDocument = function(_, url)
        timer.Simple(0, function() probeJavaScriptReady("OnFinishLoadingDocument") end)
    end

    local ok, err = pcall(function()
        local page = buildHTML()
        -- SymChars-Farben/Schriften; HUD-Flächen behalten ihre Transparenz
        if SYMUI then page = SYMUI.ThemeHTML(page, { skip = { panel = true, ["panel-soft"] = true, ["panel-strong"] = true, dark = true } }) end
        htmlPanel:SetHTML(page)
    end)

    if not ok then
        loadError("DHTML SetHTML failed: " .. tostring(err))
        removeHUDPanels()
        return false
    end
    local thisPanel = htmlPanel
    timer.Simple(C.DHTMLReadyFallbackDelay, function()
        if IsValid(thisPanel) and thisPanel == htmlPanel and not documentReady then
            probeJavaScriptReady("fallback timer")

            timer.Simple(1.0, function()
                if IsValid(thisPanel) and thisPanel == htmlPanel and not documentReady then
                    loadError("DHTML exists but the HUD JavaScript API did not become ready. The default HUD will remain visible. Run grn_hud_reload on the client.")
                end
            end)
        end
    end)

    return true
end

local function resizeHUD()
    local w, h = ScrW(), ScrH()
    if w <= 0 or h <= 0 then return end
    if IsValid(rootPanel) then
        rootPanel:SetPos(0, 0)
        rootPanel:SetSize(w, h)
    end
    if IsValid(htmlPanel) then
        htmlPanel:SetPos(0, 0)
        htmlPanel:SetSize(w, h)
    end
    lastSizeW, lastSizeH = w, h
end
hook.Add("OnScreenSizeChanged", "GRN_HUD_EOC_Resize", resizeHUD)

local hiddenHUD = {
    CHudHealth = true,
    CHudBattery = true,
    CHudAmmo = true,
    CHudSecondaryAmmo = true,
    DarkRP_HUD = true,
    DarkRP_Hungermod = true,
    DarkRP_LocalPlayerHUD = true,
    CHudVoiceStatus = true,
    CHudVoiceSelfStatus = true,
}
if CLIENT then
    RunConsoleCommand("mp_show_voice_icons", "0")
end

hook.Add("HUDShouldDraw", "GRN_HUD_EOC_HideDefault", function(name)
    if not shouldRender() then return end
    if not documentReady or not IsValid(rootPanel) or not IsValid(htmlPanel) then return end
    if name == "CHudWeaponSelection" then
        if C.WeaponSwitchEnabled ~= false then return false end
        return
    end
    if not C.HideDefaultHUD then return end
    if hiddenHUD[name] then return false end
end)

local hiddenLSCSHud = {[1] = true, [2] = true, [3] = true, [4] = true}
hook.Add("LSCS:HUDShouldDraw", "GRN_HUD_EOC_HideLSCS", function(hudType)
    if C.LSCSIntegrationEnabled ~= true or C.LSCSHideOriginalHUD ~= true then return end
    if not shouldRender() or not documentReady then return end
    if hiddenLSCSHud[tonumber(hudType)] then return false end
end)

local function disableOriginalJetpackHUD()
    if C.JetpackIntegrationEnabled ~= true or C.JetpackHideOriginalHUD ~= true then return end
    hook.Remove("HUDPaint", "jetted")
    hook.Remove("Tick", "Jetted")
end
timer.Simple(0, disableOriginalJetpackHUD)
hook.Add("InitPostEntity", "GRN_HUD_EOC_DisableJetpackHUD", disableOriginalJetpackHUD)
local activeSpeakers = {}
local voiceSerial = 0

hook.Add("PlayerStartVoice", "GRN_HUD_EOC_PlayerStartVoice", function(ply)
    if not IsValid(ply) then return end
    voiceSerial = voiceSerial + 1
    activeSpeakers[ply] = {order = voiceSerial, started = RealTime()}
    GRN_HUDV1._forceVoiceRefresh = true
end)

hook.Add("PlayerEndVoice", "GRN_HUD_EOC_PlayerEndVoice", function(ply)
    if not IsValid(ply) then return end
    activeSpeakers[ply] = nil
    GRN_HUDV1._forceVoiceRefresh = true
end)

local function getCurrentSpeaker(localPlayer)
    local selected
    local selectedOrder = -1

    for ply, data in pairs(activeSpeakers) do
        if not IsValid(ply) or not ply:IsPlayer() or not ply:IsSpeaking() then
            activeSpeakers[ply] = nil
        elseif (ply ~= localPlayer or C.VoiceShowSelf == true) and (data.order or 0) > selectedOrder then
            selected = ply
            selectedOrder = data.order or 0
        end
    end

    return selected
end
local function getRadioState(ply)
    local frequency = math.floor(tonumber(C.RadioDefaultFrequency) or 100)
    local enabled = C.RadioDefaultEnabled == true
    local state = "off"

    if C.RadioUseHelios ~= false and hradio then
        local blocked = GetGlobalBool("GRNComms_HeliosBlocked", false) == true
        if hradio.GRNCommsBlocked == true then blocked = true end
        if isfunction(hradio.IsGRNCommsBlocked) then
            local ok, result = pcall(hradio.IsGRNCommsBlocked)
            if ok and result == true then blocked = true end
        end

        if blocked then return frequency, false, "lost" end

        local channelID = 0
        if istable(ply.hradio) then channelID = math.max(0, math.floor(tonumber(ply.hradio.ActiveChannel) or 0)) end
        if channelID > 0 then
            local channel = istable(hradio.Channels) and hradio.Channels[channelID] or nil
            local channelFrequency = channel and tonumber(channel.Frequency or channel.frequency)
            frequency = math.floor(channelFrequency or channelID)
            return frequency, true, "on"
        end

        return frequency, false, "off"
    end

    if isstring(C.RadioFrequencyNWInt) and C.RadioFrequencyNWInt ~= "" then
        frequency = ply:GetNWInt(C.RadioFrequencyNWInt, frequency)
    end
    if isstring(C.RadioEnabledNWBool) and C.RadioEnabledNWBool ~= "" then
        enabled = ply:GetNWBool(C.RadioEnabledNWBool, enabled)
    end

    if enabled then state = "on" end
    return frequency, enabled, state
end
local function safeCall(obj, methodName, fallback)
    if not IsValid(obj) and not istable(obj) then return fallback end
    local method = obj[methodName]
    if not isfunction(method) then return fallback end
    local ok, result = pcall(method, obj)
    if not ok or result == nil then return fallback end
    return result
end

local function getJetpackHudState(ply)
    local data = {visible = false, value = 0, max = 1}
    if C.JetpackIntegrationEnabled ~= true or not IsValid(ply) then return data end

    local jet = ply:GetNWEntity("Jetted")
    if not IsValid(jet) then
        jet = ply:GetNWEntity("Jetpack")
    end
    if not IsValid(jet) then return data end

    local function numericMethod(obj, methodName)
        local value = safeCall(obj, methodName, nil)
        value = tonumber(value)
        if value ~= nil then return value end
        return nil
    end

    local maximum = numericMethod(jet, "GetMaxFuel")
        or numericMethod(jet, "GetFuelMax")
        or tonumber(jet.MaxFuel)
        or tonumber(jet.FuelMax)
        or tonumber(jet.maxFuel)

    if maximum == nil and isfunction(jet.GetNWFloat) then
        local nwMax = jet:GetNWFloat("MaxFuel", -1)
        if nwMax <= 0 then nwMax = jet:GetNWFloat("FuelMax", -1) end
        if nwMax > 0 then maximum = nwMax end
    end

    if maximum == nil or maximum <= 0 then
        local plyMax = ply:GetNWFloat("JetpackMaxFuel", -1)
        if plyMax <= 0 then plyMax = ply:GetNWFloat("JetFuelMax", -1) end
        if plyMax > 0 then maximum = plyMax end
    end

    maximum = math.max(tonumber(maximum) or 100, 0.001)

    local value = numericMethod(jet, "GetFuel")
        or numericMethod(jet, "GetCurrentFuel")
        or tonumber(jet.Fuel)
        or tonumber(jet.fuel)

    if value == nil and isfunction(jet.GetNWFloat) then
        local nwFuel = jet:GetNWFloat("Fuel", -1)
        if nwFuel < 0 then nwFuel = jet:GetNWFloat("JetFuel", -1) end
        if nwFuel >= 0 then value = nwFuel end
    end

    if value == nil then
        local plyFuel = ply:GetNWFloat("JetpackFuel", -1)
        if plyFuel < 0 then plyFuel = ply:GetNWFloat("JetFuel", -1) end
        if plyFuel >= 0 then value = plyFuel end
    end

    local infinite = safeCall(jet, "GetInfiniteFuel", false) == true
        or jet.InfiniteFuel == true

    value = math.Clamp(tonumber(value) or maximum, 0, maximum)

    data.visible = true
    data.max = maximum
    data.value = infinite and maximum or value

    return data
end

local function getLSCSHudState(ply)
    local data = {visible=false,weapon=false,stance="",force=0,forceMax=1,block=0,blockMax=1,advantage=0,autoBlock=false,critical=false}
    if C.LSCSIntegrationEnabled ~= true or not IsValid(ply) then return data end
    if istable(LSCS) and LSCS.DrawHud == false then return data end
    if not isfunction(ply.lscsGetForce) or not isfunction(ply.lscsGetMaxForce) then return data end
    if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return data end

    local forceMaxRaw = tonumber(safeCall(ply, "lscsGetMaxForce", 0)) or 0
    local forceRaw = tonumber(safeCall(ply, "lscsGetForce", 0)) or 0
    local forceAllowed = safeCall(ply, "lscsGetForceAllowed", forceMaxRaw > 0) == true
    data.forceMax = math.max(forceMaxRaw, 1)
    data.force = math.Clamp(forceRaw, 0, data.forceMax)

    local wep = ply:GetActiveWeapon()
    local hasWeapon = IsValid(wep) and wep.LSCS == true
    data.weapon = hasWeapon

    if hasWeapon then
        local combo = safeCall(wep, "GetCombo", nil)
        if istable(combo) then
            data.stance = tostring(combo.name or combo.PrintName or "NO STANCE")
            data.autoBlock = combo.AutoBlock == true
        else
            data.stance = "NO STANCE"
        end
        data.blockMax = math.max(tonumber(safeCall(wep, "GetMaxBlockPoints", 100)) or 100, 1)
        data.block = math.Clamp(tonumber(safeCall(wep, "GetBlockPoints", 0)) or 0, 0, data.blockMax)
        data.advantage = math.Clamp(tonumber(safeCall(wep, "GetComboHits", 0)) or 0, 0, 1)
        local notifyUntil = tonumber(safeCall(wep, "GetBlockPointNotifyTime", 0)) or 0
        data.critical = data.autoBlock and data.block <= 1 and notifyUntil > CurTime()
    end

    data.visible = hasWeapon or (C.LSCSShowForceWhenDrained ~= false and forceAllowed and forceMaxRaw > 0 and data.force < data.forceMax)
    return data
end
local lastValues = {}
local nextStats = 0
local nextCompass = 0
local nextNetwork = 0
local nextLSCS = 0
local nextJetpack = 0
local lastHeading
local lastLSCSKey
local lastJetpackKey
local smoothedFPS = 60

local function getMaxArmor(ply)
    if isfunction(ply.GetMaxArmor) then
        local ok, value = pcall(ply.GetMaxArmor, ply)
        if ok and tonumber(value) and tonumber(value) > 0 then return math.floor(tonumber(value)) end
    end
    return math.max(100, math.floor(ply:Armor() or 0))
end

local function pushVitalsRadioAmmoVoice(ply, force)
    local playerName = ply:Nick() or "PLAYER"
    if force or playerName ~= lastValues.playerName then
        runJS("GRN_HUD.setPlayerName(" .. jsQuote(playerName) .. ");")
        lastValues.playerName = playerName
    end

    local hp = math.max(0, math.floor(ply:Health() or 0))
    local maxHP = math.max(1, math.floor(ply:GetMaxHealth() or 100))
    local armor = math.max(0, math.floor(ply:Armor() or 0))
    local maxArmor = getMaxArmor(ply)

    if force or hp ~= lastValues.hp or maxHP ~= lastValues.maxHP or armor ~= lastValues.armor or maxArmor ~= lastValues.maxArmor then
        runJS(string.format("GRN_HUD.setHealthArmor(%d,%d,%d,%d);", hp, maxHP, armor, maxArmor))
        lastValues.hp, lastValues.maxHP, lastValues.armor, lastValues.maxArmor = hp, maxHP, armor, maxArmor
    end

    local localSpeaking = ply:IsSpeaking() == true
    if force or localSpeaking ~= lastValues.localSpeaking then
        runJS("GRN_HUD.setLocalVoice(" .. boolJS(C.ShowLocalVoiceIndicator == true) .. "," .. boolJS(localSpeaking) .. ");")
        lastValues.localSpeaking = localSpeaking
    end

    local speaker = getCurrentSpeaker(ply)
    local speakerName = IsValid(speaker) and speaker:Nick() or ""
    local speakerVisible = C.ShowVoiceSpeaker == true and speakerName ~= ""
    if force or GRN_HUDV1._forceVoiceRefresh or speakerName ~= lastValues.speakerName or speakerVisible ~= lastValues.speakerVisible then
        runJS("GRN_HUD.setSpeaker(" .. jsQuote(speakerName) .. "," .. boolJS(speakerVisible) .. ");")
        lastValues.speakerName, lastValues.speakerVisible = speakerName, speakerVisible
        GRN_HUDV1._forceVoiceRefresh = false
    end

    local frequency, radioOn, radioState = getRadioState(ply)
    if force or frequency ~= lastValues.frequency or radioOn ~= lastValues.radioOn or radioState ~= lastValues.radioState then
        runJS("GRN_HUD.setRadio(" .. tostring(math.floor(frequency or 0)) .. "," .. boolJS(radioOn) .. "," .. jsQuote(radioState) .. ");")
        lastValues.frequency, lastValues.radioOn, lastValues.radioState = frequency, radioOn, radioState
    end

    local clip, reserve, showAmmo = 0, 0, false
    if C.ShowAmmoPanel ~= false then
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            clip = tonumber(wep:Clip1()) or -1
            local ammoType = tonumber(wep:GetPrimaryAmmoType()) or -1
            if clip >= 0 and ammoType >= 0 then
                reserve = math.max(0, ply:GetAmmoCount(ammoType) or 0)
                showAmmo = true
            end
        end
    end

    if force or clip ~= lastValues.clip or reserve ~= lastValues.reserve or showAmmo ~= lastValues.showAmmo then
        runJS("GRN_HUD.setAmmo(" .. tostring(math.max(0, clip)) .. "," .. tostring(math.max(0, reserve)) .. "," .. boolJS(showAmmo) .. ");")
        lastValues.clip, lastValues.reserve, lastValues.showAmmo = clip, reserve, showAmmo
    end
end

local function pushCompass(ply, force)
    local heading = math.floor((ply:EyeAngles().y % 360 + 360) % 360 + 0.5) % 360
    if force or lastHeading == nil or math.abs(math.AngleDifference(heading, lastHeading)) >= 1 then
        runJS(string.format("GRN_HUD.setCompass(%d);", heading))
        lastHeading = heading
    end
end

local function jetpackKey(data)
    return table.concat({data.visible and "1" or "0", tostring(math.floor((data.value or 0) * 10 + .5)), tostring(math.floor((data.max or 1) * 10 + .5))}, "|")
end

local function pushJetpack(ply, force)
    local data = getJetpackHudState(ply)
    local key = jetpackKey(data)
    if not force and key == lastJetpackKey then return end
    lastJetpackKey = key
    runJS("GRN_HUD.setJetFuel(" .. (util.TableToJSON(data, false) or '{"visible":false}') .. ");")
end

local function lscsKey(data)
    return table.concat({data.visible and "1" or "0",data.weapon and "1" or "0",data.stance or "",tostring(math.floor((data.force or 0)*10+.5)),tostring(math.floor((data.forceMax or 1)*10+.5)),tostring(math.floor((data.block or 0)*10+.5)),tostring(math.floor((data.blockMax or 1)*10+.5)),tostring(math.floor((data.advantage or 0)*100+.5)),data.autoBlock and "1" or "0",data.critical and "1" or "0"},"|")
end

local function pushLSCS(ply, force)
    local data = getLSCSHudState(ply)
    local key = lscsKey(data)
    if not force and key == lastLSCSKey then return end
    lastLSCSKey = key
    runJS("GRN_HUD.setLSCS(" .. (util.TableToJSON(data, false) or '{"visible":false}') .. ");")
end

local WeaponSwitch = {open = false, fast = false, selected = nil, closeAt = 0, nextUpdate = 0, lastKey = nil}

local function wsEnabled()
    return C.WeaponSwitchEnabled ~= false and shouldRender() and documentReady and IsValid(htmlPanel)
end

local function wsSlotCount()
    return math.Clamp(math.floor(tonumber(C.WeaponSwitchSlots) or 6), 1, 10)
end

local function wsSound(path)
    if C.WeaponSwitchSounds == false then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local volume = math.Clamp(tonumber(C.WeaponSwitchVolume) or 0.5, 0, 1)
    if volume <= 0 then return end
    ply:EmitSound(path, 0, 100, volume, CHAN_AUTO)
end

local function wsWeaponName(wep)
    local raw = tostring(wep.GetPrintName and wep:GetPrintName() or "")
    if raw == "" then return wep:GetClass() end
    local phrase = language.GetPhrase(raw)
    if phrase == raw and raw:sub(1, 1) == "#" then phrase = language.GetPhrase(raw:sub(2)) end
    return (phrase and phrase ~= "") and phrase or raw
end

local function wsCollect(ply)
    local count = wsSlotCount()
    local slots = {}
    for i = 1, count do slots[i] = {} end

    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) then
            local slot = math.Clamp((tonumber(wep:GetSlot()) or 0) + 1, 1, count)
            table.insert(slots[slot], wep)
        end
    end

    for i = 1, count do
        table.sort(slots[i], function(a, b)
            local pa, pb = tonumber(a:GetSlotPos()) or 0, tonumber(b:GetSlotPos()) or 0
            if pa ~= pb then return pa < pb end
            return a:GetClass() < b:GetClass()
        end)
    end

    return slots
end

local function wsFlatten(slots)
    local list = {}
    for i = 1, #slots do
        for _, wep in ipairs(slots[i]) do list[#list + 1] = wep end
    end
    return list
end

local function wsSlotOf(slots, wep)
    if not IsValid(wep) then return nil, nil end
    for i = 1, #slots do
        for j, other in ipairs(slots[i]) do
            if other == wep then return i, j end
        end
    end
end

local function wsAmmoInfo(ply, wep)
    local ammoType = tonumber(wep:GetPrimaryAmmoType()) or -1
    local clip = tonumber(wep:Clip1()) or -1
    if ammoType < 0 then return "", false end

    local reserve = math.max(0, ply:GetAmmoCount(ammoType) or 0)
    local noAmmo = (clip <= 0) and reserve <= 0
    if clip >= 0 then return clip .. " / " .. reserve, noAmmo end
    return tostring(reserve), noAmmo
end

local function wsPush(ply, force)
    if not WeaponSwitch.open then
        if force or WeaponSwitch.lastKey ~= "closed" then
            runJS("GRN_HUD.setWeaponSwitch({visible:false});")
            WeaponSwitch.lastKey = "closed"
        end
        return
    end

    local slots = wsCollect(ply)
    local activeWeapon = ply:GetActiveWeapon()
    local activeSlot = wsSlotOf(slots, WeaponSwitch.selected) or 1
    local data = {visible = true, fast = WeaponSwitch.fast, activeSlot = activeSlot, slots = {}}

    for i = 1, #slots do
        local entry = {slot = i, count = #slots[i], weapons = {}}
        if i == activeSlot then
            for _, wep in ipairs(slots[i]) do
                local ammo, noAmmo = wsAmmoInfo(ply, wep)
                entry.weapons[#entry.weapons + 1] = {
                    name = wsWeaponName(wep),
                    ammo = ammo,
                    noAmmo = noAmmo,
                    selected = wep == WeaponSwitch.selected,
                    equipped = wep == activeWeapon,
                }
            end
        end
        data.slots[i] = entry
    end

    local json = util.TableToJSON(data, false) or '{"visible":false}'
    if not force and json == WeaponSwitch.lastKey then return end
    WeaponSwitch.lastKey = json
    runJS("GRN_HUD.setWeaponSwitch(" .. json .. ");")
end

local function wsClose(ply)
    if not WeaponSwitch.open then return end
    WeaponSwitch.open = false
    WeaponSwitch.fast = false
    WeaponSwitch.selected = nil
    if IsValid(ply) then wsPush(ply) end
end

local function wsTouch(ply, fast)
    WeaponSwitch.open = true
    WeaponSwitch.fast = fast == true
    local timeout = fast and (tonumber(C.WeaponSwitchFastTimeout) or 1.5) or (tonumber(C.WeaponSwitchTimeout) or 3)
    WeaponSwitch.closeAt = RealTime() + math.max(0.5, timeout)
    wsPush(ply)
end

local function wsConfirm(ply)
    local wep = WeaponSwitch.selected
    if IsValid(wep) and wep ~= ply:GetActiveWeapon() then
        input.SelectWeapon(wep)
        wsSound("common/wpn_hudoff.wav")
    end
    wsClose(ply)
end

local function wsFastSwitch()
    local cvar = GetConVar("hud_fastswitch")
    return cvar and cvar:GetBool() or false
end

-- hud_fastswitch: equip instantly, but keep the menu visible briefly so you see what you switched to.
local function wsFastSelect(ply)
    local wep = WeaponSwitch.selected
    if IsValid(wep) and wep ~= ply:GetActiveWeapon() then
        input.SelectWeapon(wep)
    end
    wsTouch(ply, true)
end

local function wsCycle(ply, dir)
    local list = wsFlatten(wsCollect(ply))
    if #list == 0 then return end

    local current = WeaponSwitch.open and WeaponSwitch.selected or ply:GetActiveWeapon()
    local index = 0
    for i, wep in ipairs(list) do
        if wep == current then index = i break end
    end

    if index == 0 then
        index = dir > 0 and 1 or #list
    else
        index = (index - 1 + dir) % #list + 1
    end

    WeaponSwitch.selected = list[index]
    wsSound("common/wpn_moveselect.wav")

    if wsFastSwitch() then
        wsFastSelect(ply)
        return
    end

    wsTouch(ply)
end

local function wsSelectSlot(ply, slotNumber)
    local slots = wsCollect(ply)
    local weapons = slots[slotNumber]
    if not weapons or #weapons == 0 then
        wsSound("common/wpn_denyselect.wav")
        return
    end

    local current = WeaponSwitch.open and WeaponSwitch.selected or ply:GetActiveWeapon()
    local currentSlot, currentIndex = wsSlotOf(slots, current)

    if currentSlot == slotNumber then
        WeaponSwitch.selected = weapons[currentIndex % #weapons + 1]
    else
        WeaponSwitch.selected = weapons[1]
    end

    wsSound("common/wpn_moveselect.wav")

    if wsFastSwitch() then
        wsFastSelect(ply)
        return
    end

    wsTouch(ply)
end

local function wsScrollBlocked(ply, wep)
    if IsValid(wep) then
        local class = wep:GetClass()
        if class == "weapon_physgun" and ply:KeyDown(IN_ATTACK) then return true end
        if class == "gmod_camera" and ply:KeyDown(IN_ATTACK2) then return true end
    end
    return hook.Run("GRN_HUD_WeaponSwitchBlocked", ply, wep) == true
end

local function wsThink(ply, now, force)
    if not WeaponSwitch.open then
        if force then wsPush(ply, true) end
        return
    end

    if not wsEnabled() or not ply:Alive() or now >= WeaponSwitch.closeAt then
        wsClose(ply)
        return
    end

    if not IsValid(WeaponSwitch.selected) or WeaponSwitch.selected:GetOwner() ~= ply then
        local list = wsFlatten(wsCollect(ply))
        WeaponSwitch.selected = list[1]
        if not IsValid(WeaponSwitch.selected) then
            wsClose(ply)
            return
        end
    end

    if force or now >= WeaponSwitch.nextUpdate then
        WeaponSwitch.nextUpdate = now + math.max(0.03, tonumber(C.WeaponSwitchUpdateInterval) or 0.1)
        wsPush(ply, force)
    end
end

hook.Add("PlayerBindPress", "GRN_HUD_EOC_WeaponSwitch", function(ply, bind, pressed)
    if not pressed or not wsEnabled() then return end
    if not IsValid(ply) or ply ~= LocalPlayer() or not ply:Alive() then return end
    if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return end

    bind = string.lower(bind or "")

    if bind == "invnext" or bind == "invprev" then
        if wsScrollBlocked(ply, ply:GetActiveWeapon()) then return end
        wsCycle(ply, bind == "invnext" and 1 or -1)
        return true
    end

    local slotNumber = tonumber(bind:match("^slot(%d+)$"))
    if slotNumber then
        if slotNumber >= 1 and slotNumber <= wsSlotCount() then
            wsSelectSlot(ply, slotNumber)
        end
        return true
    end

    if not WeaponSwitch.open or WeaponSwitch.fast then return end

    if bind == "+attack" then
        wsConfirm(ply)
        return true
    end

    if bind == "+attack2" then
        wsSound("common/wpn_hudoff.wav")
        wsClose(ply)
        return true
    end
end)

local function pushNetworkStats()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local frameTime = math.max(FrameTime(), 0.001)
    smoothedFPS = Lerp(0.18, smoothedFPS, math.Clamp(1 / frameTime, 0, 999))
    local text = string.format("fps: %d  ping: %d ms\nplayers: %d", math.floor(smoothedFPS + .5), ply:Ping(), #player.GetAll())
    runJS("GRN_HUD.setDebug(" .. jsQuote(text) .. ");")
end

local function setHUDEnabled(enabled)
    State.enabled = enabled == true
    if State.enabled then ensureHUD() end
    if IsValid(rootPanel) then rootPanel:SetVisible(shouldRender()) end
end

local function setOverlayEnabled(enabled)
    State.overlay = enabled == true
    runJS("GRN_HUD.setOverlay(" .. boolJS(State.overlay and C.ShowScreenOverlay ~= false) .. ");")
end

hook.Add("Think", "GRN_HUD_EOC_Update", function()
    if not C.Enabled then
        if IsValid(rootPanel) then rootPanel:SetVisible(false) end
        return
    end

    if not State.enabled or not optimizationAllowsHUD() then
        if IsValid(rootPanel) and rootPanel:IsVisible() then rootPanel:SetVisible(false) end
        return
    end

    ensureHUD()
    if not IsValid(rootPanel) or not IsValid(htmlPanel) then return end
    if not rootPanel:IsVisible() then rootPanel:SetVisible(true) end

    if ScrW() ~= lastSizeW or ScrH() ~= lastSizeH then
        resizeHUD()
    end

    if not documentReady then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local now = RealTime()
    local force = GRN_HUDV1._forceRefresh == true

    if force or GRN_HUDV1._forceVoiceRefresh or now >= nextStats then
        nextStats = now + C.UpdateInterval
        pushVitalsRadioAmmoVoice(ply, force)
    end

    if force or now >= nextCompass then
        nextCompass = now + C.CompassInterval
        pushCompass(ply, force)
    end


    if C.ShowDebugStats == true and (force or now >= nextNetwork) then
        nextNetwork = now + C.NetworkInterval
        pushNetworkStats()
    end

    if C.LSCSIntegrationEnabled == true and (force or now >= nextLSCS) then
        nextLSCS = now + C.LSCSUpdateInterval
        pushLSCS(ply, force)
    elseif force then
        runJS("GRN_HUD.setLSCS({visible:false});")
        lastLSCSKey = nil
    end

    if C.JetpackIntegrationEnabled == true and (force or now >= nextJetpack) then
        nextJetpack = now + C.JetpackUpdateInterval
        pushJetpack(ply, force)
    elseif force then
        runJS("GRN_HUD.setJetFuel({visible:false});")
        lastJetpackKey = nil
    end

    wsThink(ply, now, force)

    GRN_HUDV1._forceRefresh = false
end)

concommand.Add("grn_hud_toggle", function()
    setHUDEnabled(not State.enabled)
end)

concommand.Add("grn_hud_overlay", function()
    setOverlayEnabled(not State.overlay)
end)

hook.Add("OnPlayerChat", "GRN_HUD_EOC_ChatCommands", function(ply, text)
    if ply ~= LocalPlayer() then return end
    local command = string.lower(string.Trim(text or ""))
    if command == "/hud" or command == "!hud" then RunConsoleCommand("grn_hud_toggle") return true end
    if command == "/hudoverlay" or command == "!hudoverlay" then RunConsoleCommand("grn_hud_overlay") return true end
end)

hook.Add("GRN_Optimization_SettingChanged", "GRN_HUD_EOC_Optimization", function(key)
    if key ~= "hud" then return end
    if IsValid(rootPanel) then rootPanel:SetVisible(shouldRender()) end
end)

hook.Add("hRadio_PlyChangeChannelFeedback", "GRN_HUD_EOC_RadioChanged", function()
    GRN_HUDV1._forceRefresh = true
end)

hook.Add("ShutDown", "GRN_HUD_EOC_Cleanup", function()
    if IsValid(rootPanel) then rootPanel:Remove() end
end)

local function bootHUD(source)
    State.enabled = C.DefaultHudOn ~= false
    State.overlay = C.DefaultOverlayOn ~= false

    if not C.Enabled then
        return
    end
    ensureHUD()
end

hook.Add("InitPostEntity", "GRN_HUD_EOC_Boot", function()
    timer.Simple(0.25, function()
        bootHUD("InitPostEntity")
    end)
end)
timer.Simple(2, function()
    if not IsValid(rootPanel) or not IsValid(htmlPanel) then
        bootHUD("fallback startup timer")
    end
end)

concommand.Add("grn_hud_reload", function()
    documentReadyReported = false
    clientReadySent = false
    removeHUDPanels()
    timer.Simple(0.1, function()
        ensureHUD()
    end)
end)
