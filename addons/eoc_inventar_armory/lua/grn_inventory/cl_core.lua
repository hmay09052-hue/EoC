local INV = GRNInventory
local C = INV.Config

INV.UI = INV.UI or nil
INV.LastSyncJSON = INV.LastSyncJSON or nil

local HTML = [==[
<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>Inventar</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">
<style>
:root{
 --yellow:rgb(255,190,50);--yellowSoft:rgba(255,190,50,.68);--yellowDim:rgba(255,190,50,.22);--yellowFaint:rgba(255,190,50,.08);
 --white:#f4f1e9;--text:#d8dbe1;--muted:#9da3ad;--muted2:#656b75;
 --panel:rgba(8,11,15,.76);--panelSoft:rgba(14,18,23,.60);--panelStrong:rgba(7,9,12,.92);
 --line:rgba(207,216,228,.15);--lineStrong:rgba(207,216,228,.30);
 --fontMain:"Montserrat",Arial,sans-serif;--fontTitle:"Bebas Neue",Arial,sans-serif;
 --header:clamp(60px,8.2vh,90px);--footer:clamp(38px,5vh,52px);--sidePad:clamp(20px,4.3vw,82px);
 --slot:clamp(52px,4.65vw,88px);--gap:clamp(5px,.42vw,8px);--armorSlot:clamp(52px,4.4vw,84px)
}
*{box-sizing:border-box;margin:0;padding:0}html,body{width:100%;height:100%;overflow:hidden;background:transparent}
body{font-family:var(--fontMain);color:var(--white);user-select:none;-webkit-user-select:none}button{font:inherit;color:inherit;border:0;outline:0;cursor:pointer}
.shell{position:relative;width:100vw;height:100vh;overflow:hidden;background:radial-gradient(ellipse at 50% 105%,rgba(255,190,50,.055),transparent 56%),linear-gradient(90deg,rgba(3,7,12,.52),rgba(4,8,14,.17) 42%,rgba(4,8,14,.12) 62%,rgba(3,7,12,.46))}
.shell:before{content:"";position:absolute;inset:0;pointer-events:none;opacity:.18;background-image:radial-gradient(circle,rgba(255,255,255,.46) 0 1px,transparent 1.2px);background-size:220px 220px}
.shell:after{content:"";position:absolute;inset:0;pointer-events:none;background:linear-gradient(180deg,rgba(0,0,0,.2),transparent 20%,transparent 75%,rgba(0,0,0,.3)),radial-gradient(circle at 50% 50%,transparent 48%,rgba(0,0,0,.18) 100%)}
.app{position:relative;z-index:2;width:100%;height:100%}.topbar{position:absolute;left:0;right:0;top:0;height:var(--header);display:flex;align-items:center;padding:0 var(--sidePad);background:linear-gradient(180deg,rgba(4,8,15,.36),transparent);border-bottom:1px solid rgba(255,255,255,.025)}
.titleBlock{display:flex;align-items:center;gap:clamp(10px,.9vw,16px)}.mainTitle{font-family:var(--fontTitle);font-size:clamp(26px,2.35vw,46px);line-height:1;letter-spacing:.055em}.titleLine{width:clamp(34px,4vw,78px);height:1px;background:linear-gradient(90deg,var(--yellow),transparent);box-shadow:0 0 8px rgba(255,190,50,.30)}
.topInfo{margin-left:auto;display:flex;align-items:center;gap:clamp(12px,1.4vw,24px)}.userBlock{text-align:right}.userKicker{color:var(--yellow);font-size:clamp(5px,.4vw,8px);font-weight:900;letter-spacing:.16em;text-transform:uppercase}.userName{margin-top:2px;color:#d3dbe6;font-size:clamp(7px,.52vw,10px);font-weight:800}.closeBtn{width:clamp(34px,2.5vw,46px);height:clamp(34px,2.5vw,46px);display:grid;place-items:center;background:rgba(7,12,21,.58);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;transition:.16s ease}.closeBtn:hover{background:rgba(255,190,50,.08);border-color:rgba(255,190,50,.34);transform:translateY(-1px)}
.content{position:absolute;left:0;right:0;top:var(--header);bottom:var(--footer);padding:clamp(15px,2.2vh,28px) var(--sidePad);display:grid;grid-template-columns:minmax(0,.86fr) minmax(0,1.14fr);gap:clamp(24px,3.4vw,68px);overflow:hidden}
.inventoryColumn,.loadoutColumn{position:relative;min-width:0;height:100%}.sectionHead{height:clamp(64px,8.6vh,96px);display:flex;align-items:flex-start;justify-content:space-between;gap:18px}.sectionKicker{color:var(--yellow);font-size:clamp(6px,.45vw,9px);font-weight:900;letter-spacing:.16em;text-transform:uppercase}.sectionTitle{margin-top:2px;font-family:var(--fontTitle);font-size:clamp(27px,2.65vw,52px);line-height:.94;letter-spacing:.035em}.sectionDesc{max-width:320px;color:#758195;font-size:clamp(6px,.47vw,9px);line-height:1.55;text-align:right}
.inventoryFrame{position:absolute;left:0;right:0;top:clamp(74px,10.5vh,118px);bottom:clamp(96px,13vh,140px);padding:clamp(11px,1vw,16px);overflow:hidden;background:linear-gradient(135deg,rgba(8,11,15,.78),rgba(14,18,23,.48));border:1px solid rgba(255,255,255,.055)}.inventoryFrame:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--yellow);opacity:.72;box-shadow:0 0 16px rgba(255,190,50,.30)}
.invToolbar{position:relative;z-index:2;height:clamp(34px,4.3vh,46px);display:flex;align-items:center;border-bottom:1px solid rgba(255,255,255,.06)}.invLabel{display:flex;align-items:center;gap:8px;color:#d7deea;font-size:clamp(7px,.53vw,10px);font-weight:900;text-transform:uppercase;letter-spacing:.06em}.capacity{margin-left:auto;display:flex;align-items:center;gap:7px;color:#7f8ca0;font-size:clamp(6px,.46vw,9px);font-weight:800}.capacity strong{color:#dce3eb}.capacityBar{position:absolute;left:0;right:0;bottom:-1px;height:1px;background:rgba(255,255,255,.035)}.capacityBar span{display:block;width:0;height:100%;background:var(--yellow);box-shadow:0 0 8px rgba(255,190,50,.35)}
.gridWrap{position:absolute;left:clamp(11px,1vw,16px);right:clamp(11px,1vw,16px);top:calc(clamp(34px,4.3vh,46px) + clamp(20px,2vh,26px));bottom:clamp(12px,1.2vh,16px);display:flex;align-items:flex-start;gap:clamp(10px,1vw,16px);overflow:hidden}.slotGrid{display:grid;grid-template-columns:repeat(5,var(--slot));grid-auto-rows:var(--slot);gap:var(--gap);align-content:start;flex:0 0 auto;position:relative}.slot{position:relative;width:var(--slot);height:var(--slot);overflow:hidden;z-index:1;border:1px solid rgba(213,224,241,.15);background:linear-gradient(145deg,rgba(4,8,14,.52),rgba(11,18,29,.32));transition:border-color .12s ease,background .12s ease}.slot:hover{border-color:rgba(255,190,50,.30);background:linear-gradient(145deg,rgba(14,25,42,.6),rgba(8,14,24,.4))}.slot.selected{border-color:rgba(255,190,50,.78);box-shadow:inset 0 0 0 1px rgba(255,190,50,.12),0 0 12px rgba(255,190,50,.10)}.slot.dragover{border-color:#dce8f6;background:rgba(255,190,50,.13);box-shadow:inset 0 0 0 1px rgba(255,190,50,.20)}.slotNo{position:absolute;left:5px;top:4px;color:#58667a;font-size:clamp(5px,.36vw,7px);font-weight:900}.itemTile{position:relative;z-index:5;min-width:0;min-height:0;overflow:hidden;display:grid;place-items:center;cursor:grab;border:1px solid rgba(213,224,241,.25);background:linear-gradient(145deg,rgba(9,12,16,.94),rgba(6,8,11,.90));box-shadow:0 5px 16px rgba(0,0,0,.22),inset 0 0 24px rgba(255,190,50,.025);transition:border-color .12s ease,transform .12s ease,filter .12s ease}.itemTile:hover{border-color:rgba(255,190,50,.56);transform:translateY(-1px)}.itemTile.selected{border-color:rgba(255,190,50,.92);box-shadow:0 0 18px rgba(255,190,50,.12),inset 0 0 0 1px rgba(255,190,50,.12)}.itemTile.dragging{opacity:.28;filter:saturate(.55)}.itemTile:active{cursor:grabbing}.dragGhost{position:fixed!important;z-index:20000!important;pointer-events:none!important;opacity:.92!important;transform:none!important;box-shadow:0 18px 46px rgba(0,0,0,.48),0 0 22px rgba(255,190,50,.15)!important}.inventoryDragging,.inventoryDragging *{cursor:grabbing!important}.itemTile i{font-size:calc(var(--slot)*.42);color:#f6f7f2;filter:drop-shadow(0 3px 8px rgba(0,0,0,.42))}.itemTile img,.equipIcon img,.selectedIcon img{max-width:72%;max-height:72%;object-fit:contain;filter:drop-shadow(0 3px 8px rgba(0,0,0,.42));pointer-events:none}.qty{position:absolute;right:6px;bottom:5px;color:white;font-size:clamp(6px,.43vw,8px);font-weight:900}.sizeBadge{position:absolute;right:6px;top:5px;color:#71839b;font-size:clamp(5px,.34vw,7px);font-weight:900;letter-spacing:.04em}.rarity{position:absolute;left:0;right:0;bottom:0;height:2px}.r-common{background:#7f8c9d}.r-uncommon{background:#66aa78}.r-rare{background:#d1a842}.r-epic{background:#8e6fd6}.r-legendary{background:#d5ae5a}
.sideSlots{flex:1 1 auto;min-width:64px;display:flex;flex-direction:column;gap:var(--gap)}.utilitySlot{position:relative;height:var(--slot);min-width:60px;display:flex;align-items:center;justify-content:center;border:1px solid rgba(213,224,241,.1);background:rgba(5,10,18,.34);color:#dce4ee;transition:.16s ease}.utilitySlot:hover{border-color:rgba(255,190,50,.24);background:rgba(255,190,50,.045)}.utilitySlot .num{position:absolute;left:6px;top:5px;color:#677489;font-size:7px;font-weight:900}.utilitySlot i{font-size:clamp(18px,1.6vw,28px)}
.selectedInfo{position:absolute;left:0;right:0;bottom:0;min-height:clamp(82px,10.6vh,116px);padding:clamp(12px,1.1vw,18px);display:flex;align-items:center;gap:clamp(12px,1.1vw,18px);background:linear-gradient(110deg,rgba(7,9,12,.90),rgba(14,18,23,.60));border:1px solid rgba(255,255,255,.05)}.selectedIcon{width:clamp(52px,4vw,72px);height:clamp(52px,4vw,72px);flex:0 0 auto;display:grid;place-items:center;border:1px solid rgba(255,255,255,.12);background:rgba(4,8,14,.42)}.selectedIcon i{font-size:clamp(21px,1.8vw,34px)}.selectedText{min-width:0}.selectedName{font-family:var(--fontTitle);font-size:clamp(19px,1.65vw,32px);letter-spacing:.04em;line-height:.95}.selectedDesc{margin-top:5px;color:#8996a8;font-size:clamp(6px,.48vw,9px);line-height:1.55}.selectedMeta{margin-left:auto;min-width:80px;text-align:right;color:#6f7e93;font-size:clamp(5px,.4vw,8px);font-weight:900;text-transform:uppercase}.selectedMeta strong{display:block;margin-top:3px;color:#dce4ee;font-family:var(--fontTitle);font-size:clamp(16px,1.35vw,25px)}
.characterCard{position:relative;height:clamp(90px,11.3vh,126px);padding:clamp(14px,1.2vw,20px);display:grid;grid-template-columns:1fr auto;gap:20px;background:linear-gradient(120deg,rgba(8,11,15,.76),rgba(14,18,23,.48));border:1px solid rgba(255,255,255,.05)}.characterName{margin-top:5px;font-family:var(--fontTitle);font-size:clamp(22px,1.85vw,35px);letter-spacing:.045em}.characterSub{margin-top:2px;color:#7d899c;font-size:clamp(6px,.47vw,9px)}.characterStats{display:flex;gap:clamp(22px,2vw,38px);align-items:flex-end}.statBlock{text-align:right}.statLabel{color:#65758b;font-size:clamp(5px,.38vw,7px);font-weight:900;text-transform:uppercase;letter-spacing:.08em}.statValue{margin-top:3px;color:#dce4ee;font-family:var(--fontTitle);font-size:clamp(17px,1.3vw,25px)}.statValue.money{color:#84b55f}
.loadoutColumn{display:flex;flex-direction:column;gap:clamp(10px,1.4vh,16px)}.characterCard{flex:0 0 auto}
.dollFrame{position:relative;flex:1 1 auto;min-height:0;display:grid;grid-template-columns:auto minmax(0,1fr) auto;grid-template-rows:auto minmax(0,1fr);column-gap:clamp(12px,1.4vw,26px);row-gap:clamp(6px,.9vh,12px);padding:clamp(12px,1.1vw,18px) clamp(14px,1.3vw,22px);background:linear-gradient(135deg,rgba(8,11,15,.78),rgba(14,18,23,.48));border:1px solid rgba(255,255,255,.055);overflow:hidden}.dollFrame:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--yellow);opacity:.72;box-shadow:0 0 16px rgba(255,190,50,.30)}
.dollHead{grid-column:1/-1;display:flex;align-items:flex-end;justify-content:space-between;gap:16px;border-bottom:1px solid rgba(255,255,255,.06);padding-bottom:clamp(6px,.8vh,10px)}.dollTitle{margin-top:2px;font-family:var(--fontTitle);font-size:clamp(24px,2.1vw,40px);line-height:.95;letter-spacing:.04em}.dollSummary{color:#7f8ca0;font-size:clamp(6px,.46vw,9px);font-weight:800;text-transform:uppercase;letter-spacing:.06em;text-align:right}.dollSummary strong{color:var(--yellow)}
.armorCol{display:flex;flex-direction:column;gap:clamp(8px,1.2vh,16px);justify-content:center;min-height:0}.armorSlot{display:flex;flex-direction:column;align-items:center;gap:4px}.armorLabel{font-family:var(--fontTitle);font-size:clamp(14px,1.05vw,21px);letter-spacing:.06em;color:#dce4ee;line-height:1}
.armorBox{--rc:127,140,157;position:relative;width:var(--armorSlot);height:var(--armorSlot);display:grid;place-items:center;overflow:hidden;border:1px solid rgba(213,224,241,.15);background:linear-gradient(145deg,rgba(4,8,14,.52),rgba(11,18,29,.32));transition:border-color .12s ease,background .12s ease,transform .12s ease}.armorBox:hover{border-color:rgba(255,190,50,.34);transform:translateY(-1px)}.armorBox .ghostIcon{font-size:calc(var(--armorSlot)*.34);color:rgba(220,228,238,.13)}.armorBox.filled{border-color:rgba(var(--rc),.95);background:linear-gradient(150deg,rgba(var(--rc),.62),rgba(var(--rc),.20) 70%,rgba(6,9,13,.6));box-shadow:inset 0 0 18px rgba(0,0,0,.35),0 0 12px rgba(var(--rc),.18)}.armorBox img{max-width:86%;max-height:86%;object-fit:contain;filter:drop-shadow(0 4px 8px rgba(0,0,0,.5));pointer-events:none}.armorBox i.itemFa{font-size:calc(var(--armorSlot)*.42);color:#f6f7f2;filter:drop-shadow(0 3px 8px rgba(0,0,0,.42))}.armorSlot.dragover .armorBox{border-color:#dce8f6;background:rgba(255,190,50,.16)}
.armorBox[data-rarity=common]{--rc:127,140,157}.armorBox[data-rarity=uncommon]{--rc:102,170,120}.armorBox[data-rarity=rare]{--rc:209,168,66}.armorBox[data-rarity=epic]{--rc:142,111,214}.armorBox[data-rarity=legendary]{--rc:213,174,90}
.dollCenter{position:relative;min-width:0;min-height:0}.dollRing{position:absolute;left:calc(50% - clamp(27px,2.1vw,41px));bottom:clamp(14px,2vh,24px);width:min(62%,320px);aspect-ratio:3/1;transform:translateX(-50%);border-radius:50%;border:1px solid rgba(255,190,50,.20);background:radial-gradient(ellipse at center,rgba(255,190,50,.10),transparent 68%);pointer-events:none}.dollGrid{position:absolute;inset:2% 14% 4% 2%;opacity:.18;background:linear-gradient(rgba(255,190,50,.10) 1px,transparent 1px),linear-gradient(90deg,rgba(255,190,50,.10) 1px,transparent 1px);background-size:34px 34px;-webkit-mask-image:radial-gradient(circle,#000 22%,transparent 70%);pointer-events:none}#dollViewport{position:absolute;left:0;top:0;bottom:clamp(16px,2.2vh,26px);right:clamp(54px,4.2vw,82px)}.dollNote{position:absolute;left:0;right:clamp(54px,4.2vw,82px);bottom:0;text-align:center;color:#5f6c80;font-size:clamp(5px,.38vw,7px);font-weight:900;letter-spacing:.12em;text-transform:uppercase}
.statBars{position:absolute;right:0;top:2%;bottom:0;display:flex;gap:clamp(6px,.6vw,12px)}.vbar{width:clamp(16px,1.25vw,24px);display:flex;flex-direction:column;align-items:center;gap:6px}.vbarTrack{position:relative;flex:1 1 auto;width:100%;background:rgba(255,255,255,.045);border:1px solid rgba(255,255,255,.07);overflow:hidden}.vbarFill{position:absolute;left:0;right:0;bottom:0;height:0;transition:height .25s ease}.vbar.hp .vbarFill{background:linear-gradient(0deg,#9e3b3b,#d9645d);box-shadow:0 0 10px rgba(217,100,93,.35)}.vbar.ar .vbarFill{background:linear-gradient(0deg,#b9861f,var(--yellow));box-shadow:0 0 10px rgba(255,190,50,.35)}.vbarBonus{position:absolute;left:0;right:0;border-top:1px dashed rgba(255,255,255,.55);display:none}.vbar i{font-size:clamp(9px,.75vw,14px)}.vbar.hp i{color:#d9645d}.vbar.ar i{color:var(--yellow)}.vbarVal{color:#c4ccd7;font-size:clamp(5px,.38vw,7px);font-weight:900}
.weaponRow{flex:0 0 auto;display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:clamp(8px,.8vw,14px)}.equipSlot{position:relative;min-width:0;display:flex;flex-direction:column;gap:clamp(5px,.7vh,8px);padding:clamp(9px,.85vw,14px);background:linear-gradient(115deg,rgba(9,16,28,.86),rgba(8,14,24,.54));border:1px solid rgba(255,255,255,.05);transition:transform .16s ease,border-color .16s ease,background .16s ease;overflow:hidden}.equipSlot:before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--yellow);opacity:.7;box-shadow:0 0 14px rgba(255,190,50,.28)}.equipSlot:hover{transform:translateY(-2px);border-color:rgba(255,190,50,.22)}.equipSlot.dragover{border-color:rgba(255,190,50,.58);background:linear-gradient(115deg,rgba(34,29,18,.86),rgba(14,16,18,.72))}.equipKicker{color:var(--yellow);font-size:clamp(5px,.4vw,8px);font-weight:900;text-transform:uppercase;letter-spacing:.14em}.equipName{font-family:var(--fontTitle);font-size:clamp(16px,1.35vw,26px);line-height:.95;letter-spacing:.04em}.equipItem{min-width:0;display:flex;flex-direction:column;gap:5px}.equipIcon{width:100%;height:clamp(48px,6.4vh,82px);display:grid;place-items:center;border:1px solid rgba(255,255,255,.11);background:rgba(4,8,14,.4)}.equipIcon i{font-size:clamp(20px,1.9vw,36px);color:#f4f6f3;filter:drop-shadow(0 3px 8px rgba(0,0,0,.4))}.equipIcon i.fa-plus{color:#4f5c6e}.equippedName{color:#dce4ee;font-size:clamp(6px,.5vw,10px);font-weight:900;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.equippedEmpty{color:#6c798c;font-size:clamp(6px,.46vw,9px);font-weight:700;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.itemTile.equipped:before{content:"";position:absolute;left:0;top:0;width:0;height:0;border-top:12px solid var(--yellow);border-right:12px solid transparent;z-index:3}
.footer{position:absolute;left:0;right:0;bottom:0;height:var(--footer);display:flex;align-items:center;padding:0 var(--sidePad);background:linear-gradient(90deg,rgba(255,190,50,.08),rgba(255,190,50,.15),rgba(14,18,23,.58));border-top:1px solid rgba(255,190,50,.10)}.footerText{color:#aeb8c6;font-size:clamp(5px,.42vw,8px);font-weight:800;text-transform:uppercase}.footerLegend{margin-left:auto;display:flex;align-items:center;gap:10px}.key{min-width:clamp(27px,2vw,38px);height:clamp(25px,2vw,35px);padding:0 7px;display:grid;place-items:center;border:1px solid rgba(230,235,243,.45);color:#eef2f7;font-size:clamp(5px,.4vw,8px)}
.toast{position:absolute;left:50%;top:calc(var(--header) + 8px);transform:translate(-50%,-8px);padding:8px 12px;z-index:90;background:rgba(7,12,20,.94);border:1px solid rgba(255,255,255,.08);color:#d9e1ec;font-size:10px;opacity:0;pointer-events:none;transition:opacity .16s ease,transform .16s ease}.toast.show{opacity:1;transform:translate(-50%,0)}
.contextMenu{position:fixed;z-index:9999;width:clamp(176px,10.5vw,214px);padding:5px;display:none;background:linear-gradient(145deg,rgba(8,14,24,.97),rgba(5,9,16,.98));border:1px solid rgba(213,224,241,.13);box-shadow:0 16px 44px rgba(0,0,0,.48),inset 0 1px 0 rgba(255,255,255,.025)}.contextMenu.show{display:block;animation:contextIn .12s ease both}.contextMenu:before{content:"";position:absolute;left:0;top:0;bottom:0;width:2px;background:var(--yellow);box-shadow:0 0 10px rgba(255,190,50,.32)}.contextHeader{padding:7px 9px 8px 10px;border-bottom:1px solid rgba(255,255,255,.06);margin-bottom:4px}.contextItemName{overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:#dce4ee;font-family:var(--fontTitle);font-size:clamp(14px,1vw,19px);letter-spacing:.04em;line-height:1}.contextItemMeta{margin-top:3px;color:#647287;font-size:clamp(5px,.37vw,7px);font-weight:800;text-transform:uppercase;letter-spacing:.08em}.contextAction{width:100%;height:clamp(30px,3.35vh,38px);padding:0 9px;display:grid;grid-template-columns:20px 1fr auto;align-items:center;gap:8px;background:transparent;border:1px solid transparent;color:#aeb9c8;text-align:left;font-size:clamp(6px,.45vw,9px);font-weight:800;text-transform:uppercase;letter-spacing:.045em;transition:.12s ease}.contextAction i{width:16px;text-align:center;color:#75859a}.contextAction .contextKey{color:#526075;font-size:clamp(5px,.34vw,7px);font-weight:900}.contextAction:hover{color:#eef3fa;background:rgba(255,190,50,.09);border-color:rgba(255,190,50,.12)}.contextAction:hover i{color:#ffbe32}.contextAction.danger:hover{color:#ffb4b7;background:rgba(176,59,66,.11);border-color:rgba(221,91,98,.12)}.contextAction.disabled{opacity:.3;pointer-events:none}.contextDivider{height:1px;margin:4px 7px;background:linear-gradient(90deg,rgba(255,255,255,.08),rgba(255,255,255,.018))}
.quantityPanel{position:fixed;z-index:10000;width:clamp(220px,13vw,270px);display:none;padding:11px;background:linear-gradient(145deg,rgba(8,14,24,.99),rgba(5,9,16,.99));border:1px solid rgba(213,224,241,.14);box-shadow:0 18px 50px rgba(0,0,0,.55)}.quantityPanel.show{display:block;animation:contextIn .12s ease both}.quantityTitle{font-family:var(--fontTitle);font-size:clamp(17px,1.2vw,23px);letter-spacing:.045em}.quantitySub{margin-top:3px;color:#66758a;font-size:clamp(5px,.38vw,8px);line-height:1.45}.quantityControls{margin-top:12px;height:38px;display:grid;grid-template-columns:38px 1fr 38px;gap:5px}.quantityBtn,.quantityInput{border:1px solid rgba(255,255,255,.08);background:rgba(5,10,18,.48);color:#dce4ee}.quantityBtn{cursor:pointer}.quantityInput{width:100%;text-align:center;outline:0;font-size:clamp(8px,.58vw,11px);font-weight:900}.quantityActions{margin-top:7px;display:grid;grid-template-columns:1fr 1fr;gap:5px}.quantityConfirm,.quantityCancel{height:32px;font-size:clamp(6px,.42vw,8px);font-weight:900;text-transform:uppercase;background:rgba(6,11,19,.52);border:1px solid rgba(255,255,255,.07)}.quantityConfirm:hover{background:rgba(255,190,50,.10);border-color:rgba(255,190,50,.22)}.quantityCancel{color:#7f8da0}.quantityCancel:hover{color:#d5dde7;background:rgba(255,255,255,.035)}

.hudCorner{position:absolute;z-index:5;width:24px;height:24px;opacity:.34;pointer-events:none}.hudCorner:before,.hudCorner:after{content:"";position:absolute;background:var(--yellow)}.hudCorner:before{width:100%;height:1px}.hudCorner:after{width:1px;height:100%}.hudCorner.tl{left:1.2vw;top:2vh}.hudCorner.tr{right:1.2vw;top:2vh;transform:scaleX(-1)}.hudCorner.bl{left:1.2vw;bottom:2vh;transform:scaleY(-1)}.hudCorner.br{right:1.2vw;bottom:2vh;transform:scale(-1)}
@keyframes contextIn{from{opacity:0;transform:translateY(-4px) scale(.985)}to{opacity:1;transform:translateY(0) scale(1)}}
@media(max-width:1600px){:root{--sidePad:clamp(18px,3vw,46px);--slot:clamp(46px,4.25vw,68px);--armorSlot:clamp(48px,4.2vw,74px)}.content{gap:clamp(20px,2.5vw,42px)}}
@media(max-width:1366px){:root{--sidePad:clamp(16px,2.4vw,34px);--slot:clamp(43px,4.35vw,59px);--gap:4px;--armorSlot:clamp(44px,4.4vw,64px)}.content{grid-template-columns:minmax(0,.9fr) minmax(0,1.1fr);gap:24px}.sectionDesc{max-width:250px}}
@media(max-width:1180px){.content{gap:18px}.sectionDesc{display:none}.characterStats{gap:16px}.dollSummary{display:none}}
@media(max-width:1024px){:root{--sidePad:14px;--slot:clamp(39px,4.7vw,48px);--armorSlot:44px}.content{grid-template-columns:minmax(0,.92fr) minmax(0,1.08fr);gap:14px}.sideSlots{min-width:48px}.utilitySlot{min-width:46px}.equipName{font-size:15px}}
@media(max-height:850px){:root{--header:60px;--footer:40px;--armorSlot:56px}.content{padding-top:10px;padding-bottom:8px}.sectionHead{height:62px}.inventoryFrame{top:66px;bottom:92px}.selectedInfo{min-height:78px;padding:10px 12px}.characterCard{height:78px;padding:10px 12px}.equipIcon{height:46px}.armorCol{gap:6px}}
@media(max-height:700px){:root{--armorSlot:44px}.sectionHead{height:50px}.sectionTitle{font-size:28px}.inventoryFrame{top:54px;bottom:78px}.selectedInfo{min-height:66px}.selectedDesc{display:none}.characterCard{height:64px}.characterSub{display:none}.equipIcon{height:38px}.equipKicker,.dollNote{display:none}.dollTitle{font-size:22px}}
</style>
</head>
<body>
<div class="shell"><div class="hudCorner tl"></div><div class="hudCorner tr"></div><div class="hudCorner bl"></div><div class="hudCorner br"></div><main class="app">
<header class="topbar"><div class="topInfo"><div class="userBlock"><div class="userKicker">AKTUELLER CHARAKTER</div><div class="userName" id="topPlayerName">LÄDT...</div></div><button class="closeBtn" id="closeBtn"><i class="fa-solid fa-xmark"></i></button></div></header>
<section class="content">
<div class="inventoryColumn">
 <div class="sectionHead"><div><div class="sectionKicker">AUSRÜSTUNGSVERWALTUNG</div><div class="sectionTitle">INVENTAR</div></div><div class="sectionDesc">Verwalte Gegenstände, Munition und Ausrüstung. Ziehe eine Waffe auf einen Ausrüstungsslot, um sie anzulegen.</div></div>
 <div class="inventoryFrame"><div class="invToolbar"><div class="invLabel"><i class="fa-solid fa-briefcase"></i><span>INHALT</span></div><div class="capacity"><i class="fa-solid fa-weight-hanging"></i><strong id="weightNow">000</strong>/<span id="weightMax">100</span> KG</div><div class="capacityBar"><span id="capacityFill"></span></div></div><div class="gridWrap"><div class="slotGrid" id="slotGrid"></div><div class="sideSlots"><div class="utilitySlot"><span class="num">1</span><i class="fa-solid fa-arrow-up"></i></div><div class="utilitySlot"><span class="num">2</span><i class="fa-solid fa-plus"></i></div><div class="utilitySlot"><span class="num">3</span><i class="fa-solid fa-plus"></i></div><div class="utilitySlot"><span class="num">4</span><i class="fa-solid fa-plus"></i></div></div></div></div>
 <div class="selectedInfo"><div class="selectedIcon" id="selectedIconWrap"><i id="selectedIcon" class="fa-solid fa-box"></i></div><div class="selectedText"><div class="selectedName" id="selectedName">KEINE AUSWAHL</div><div class="selectedDesc" id="selectedDesc">Wähle einen Gegenstand aus, um Details zu sehen.</div></div><div class="selectedMeta">GEWICHT<strong id="selectedWeight">0.0 KG</strong></div></div>
</div>
<div class="loadoutColumn">
 <div class="characterCard"><div><div class="sectionKicker">CHARAKTER</div><div class="characterName" id="characterName">LÄDT...</div><div class="characterSub">Zugewiesene Ausrüstung und verfügbare Mittel</div></div><div class="characterStats"><div class="statBlock"><div class="statLabel">GUTHABEN</div><div class="statValue money" id="balance">0 CR</div></div><div class="statBlock"><div class="statLabel">LAST</div><div class="statValue" id="loadValue">0 KG</div></div></div></div>
 <div class="dollFrame" id="dollFrame">
  <div class="dollHead"><div><div class="sectionKicker">RÜSTUNG · CHARAKTER</div><div class="dollTitle">AUSRÜSTUNG</div></div><div class="dollSummary" id="dollSummary">KEINE RÜSTUNG ANGELEGT</div></div>
  <div class="armorCol" id="armorLeft"></div>
  <div class="dollCenter"><div class="dollGrid"></div><div class="dollRing"></div><div id="dollViewport"></div><div class="dollNote" id="dollNote">RÜSTUNG AUF EINEN SLOT ZIEHEN</div>
   <div class="statBars"><div class="vbar hp" title="Health"><div class="vbarTrack"><div class="vbarFill" id="hpFill"></div></div><i class="fa-solid fa-heart-pulse"></i><span class="vbarVal" id="hpVal">0</span></div><div class="vbar ar" title="Armor"><div class="vbarTrack"><div class="vbarFill" id="arFill"></div><div class="vbarBonus" id="arBonus"></div></div><i class="fa-solid fa-shield-halved"></i><span class="vbarVal" id="arVal">0</span></div></div>
  </div>
  <div class="armorCol" id="armorRight"></div>
 </div>
 <div class="weaponRow">
  <div class="equipSlot" data-equip="primary"><div><div class="equipKicker">SLOT 01</div><div class="equipName">PRIMÄR</div></div><div class="equipItem" id="equip-primary"></div></div>
  <div class="equipSlot" data-equip="secondary"><div><div class="equipKicker">SLOT 02</div><div class="equipName">SEKUNDÄR</div></div><div class="equipItem" id="equip-secondary"></div></div>
  <div class="equipSlot" data-equip="specialized"><div><div class="equipKicker">SLOT 03 · NUR EINE</div><div class="equipName">SPEZIAL</div></div><div class="equipItem" id="equip-specialized"></div></div>
  <div class="equipSlot" data-equip="utility"><div><div class="equipKicker">SLOT 04</div><div class="equipName">HILFSMITTEL</div></div><div class="equipItem" id="equip-utility"></div></div>
 </div>
</div>
</section>
<footer class="footer"><div class="footerText">ECHOES OF CLONES · INVENTARSYSTEM</div><div class="footerLegend"><span class="footerText">DOPPELKLICK · BENUTZEN</span><span class="key">I</span><span class="footerText">ÖFFNEN / SCHLIESSEN</span><span class="key">ESC</span><span class="footerText">SCHLIESSEN</span></div></footer>
<div class="contextMenu" id="contextMenu"><div class="contextHeader"><div class="contextItemName" id="contextItemName">GEGENSTAND</div><div class="contextItemMeta" id="contextItemMeta">SLOT 00 · 0.0 KG</div></div><button class="contextAction" id="contextEquip"><i class="fa-solid fa-shield-halved"></i><span id="contextEquipText">AUSRÜSTEN</span><span class="contextKey">E</span></button><button class="contextAction" id="contextUse"><i class="fa-solid fa-box-archive"></i><span id="contextUseText">BENUTZEN</span><span class="contextKey">U</span></button><div class="contextDivider"></div><button class="contextAction danger" id="contextDrop"><i class="fa-solid fa-arrow-down"></i><span>FALLEN LASSEN</span><span class="contextKey">D</span></button><button class="contextAction danger" id="contextDropQuantity"><i class="fa-solid fa-layer-group"></i><span>MENGE FALLEN LASSEN</span><span class="contextKey">Q</span></button></div>
<div class="quantityPanel" id="quantityPanel"><div class="quantityTitle">MENGE FALLEN LASSEN</div><div class="quantitySub" id="quantitySub">Wähle, wie viele du fallen lassen willst.</div><div class="quantityControls"><button class="quantityBtn" id="quantityMinus"><i class="fa-solid fa-minus"></i></button><input class="quantityInput" id="quantityInput" type="number" min="1" value="1"><button class="quantityBtn" id="quantityPlus"><i class="fa-solid fa-plus"></i></button></div><div class="quantityActions"><button class="quantityCancel" id="quantityCancel">ABBRECHEN</button><button class="quantityConfirm" id="quantityConfirm">FALLEN LASSEN</button></div></div>
<div class="toast" id="toast">Aktualisiert</div>
</main></div>
<script>
(function(){"use strict";
const qs=(s,p=document)=>p.querySelector(s),qsa=(s,p=document)=>Array.from(p.querySelectorAll(s));
const state={maxWeight:100,currentWeight:0,selectedSlot:null,draggedSlot:null,gridColumns:5,gridRows:5,slotCount:25,items:[],equipment:{primary:null,secondary:null,specialized:null,utility:null},armor:{},armorSlots:[],armorEnabled:true,stats:{},icons:{}};
const toast=qs("#toast"),contextMenu=qs("#contextMenu"),quantityPanel=qs("#quantityPanel"),quantityInput=qs("#quantityInput");let toastTimer=null,contextSlot=null,quantitySlot=null,dragSession=null,suppressClickUntil=0,armorLayoutSig="";
function itemBySlot(slot){return state.items.find(x=>Number(x.slot)===Number(slot))}function itemByUID(uid){return state.items.find(x=>x.uid===uid)}
function slotToGrid(slot){const z=Number(slot)-1;return {col:(z%state.gridColumns)+1,row:Math.floor(z/state.gridColumns)+1}}
function footprint(item,anchor){if(!item)return[];const start=slotToGrid(anchor===undefined?item.slot:anchor),w=Math.max(1,Number(item.sizeW)||1),h=Math.max(1,Number(item.sizeH)||1),out=[];if(start.col+w-1>state.gridColumns||start.row+h-1>state.gridRows)return out;for(let y=0;y<h;y++)for(let x=0;x<w;x++)out.push((start.row+y-1)*state.gridColumns+(start.col+x));return out}
function itemCoveringSlot(slot){const n=Number(slot);return state.items.find(item=>footprint(item).includes(n))}
function escapeHTML(s){return String(s).replace(/[&<>'"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"}[c]))}
function faClass(v){v=String(v||"fa-box").replace(/^fa-solid\s+/,"");return /^fa-[a-z0-9-]+$/i.test(v)?v:"fa-box"}
function iconHTML(item,extraClass){if(item&&item.iconURL){return '<img src="'+String(item.iconURL).replace(/"/g,'&quot;')+'" alt="">'}const rendered=item&&state.icons[item.id];if(rendered){return '<img src="'+rendered+'" alt="">'}return '<i class="fa-solid '+faClass(item&&item.icon)+(extraClass?' '+extraClass:'')+'"></i>'}
function equipmentLabel(type){return ({primary:"PRIMÄR",secondary:"SEKUNDÄR",specialized:"SPEZIAL",utility:"HILFSMITTEL"})[type]||String(type||"").toUpperCase()}
function armorSlotInfo(id){return state.armorSlots.find(s=>s.id===id)||{id:id,label:String(id||"").toUpperCase(),icon:"fa-shield-halved"}}
function armorSlotOf(uid){return Object.keys(state.armor).find(k=>state.armor[k]===uid)||null}
function equipSlotOf(uid){return Object.keys(state.equipment).find(k=>state.equipment[k]===uid)||null}
function isItemEquipped(uid){return !!equipSlotOf(uid)||!!armorSlotOf(uid)}
function hideContextMenu(){contextMenu.classList.remove("show");contextSlot=null}function hideQuantityPanel(){quantityPanel.classList.remove("show");quantitySlot=null}
function clampFloatingPanel(panel,x,y){const rect=panel.getBoundingClientRect(),m=8;let px=x,py=y;if(px+rect.width+m>innerWidth)px=innerWidth-rect.width-m;if(py+rect.height+m>innerHeight)py=innerHeight-rect.height-m;panel.style.left=Math.max(m,px)+"px";panel.style.top=Math.max(m,py)+"px"}
function showToast(text){if(/PASST NICHT|KANN NICHT|KANNST|NICHT GENUG|UNGÜLTIG|VOLL|LIMIT|NICHT VERFÜGBAR|NICHT GEFUNDEN|KONNTE NICHT|DARF NICHT|DEAKTIVIERT|UNBEKANNT|ERST ABLEGEN|LEER/i.test(String(text||"")))sfx("error");toast.textContent=String(text||"Updated");toast.classList.add("show");clearTimeout(toastTimer);toastTimer=setTimeout(()=>toast.classList.remove("show"),1500)}
function sfx(kind){try{if(window.gmod&&gmod.uiSound)gmod.uiSound(String(kind))}catch(_){}}
function dispatch(name,payload={}){try{if(window.gmod&&typeof window.gmod.inventoryAction==="function")window.gmod.inventoryAction(JSON.stringify({name,payload}))}catch(_){}}
function toggleEquip(item){if(!item)return false;if(item.armorSlot||item.equipSlot)sfx("equip");if(item.armorSlot){const worn=armorSlotOf(item.uid);if(worn)dispatch("unequipArmor",{armorSlot:worn});else dispatch("equipArmor",{slot:item.slot,armorSlot:item.armorSlot});return true}if(item.equipSlot){const type=equipSlotOf(item.uid);if(type)dispatch("unequip",{equipSlot:type});else dispatch("equip",{slot:item.slot,equipSlot:item.equipSlot});return true}return false}
function openContextMenu(slotNo,x,y){const item=itemBySlot(slotNo);if(!item)return;contextSlot=slotNo;hideQuantityPanel();qs("#contextItemName").textContent=item.name.toUpperCase();qs("#contextItemMeta").textContent="SLOT "+String(slotNo).padStart(2,"0")+" · "+((Number(item.weight)||0)*(Number(item.qty)||0)).toFixed(1)+" KG · X"+(Number(item.qty)||0);const equipButton=qs("#contextEquip"),equipText=qs("#contextEquipText"),useText=qs("#contextUseText");if(item.armorSlot){equipButton.classList.remove("disabled");equipText.textContent=armorSlotOf(item.uid)?"ABLEGEN":"ANLEGEN · "+armorSlotInfo(item.armorSlot).label}else if(item.equipSlot){equipButton.classList.remove("disabled");equipText.textContent=isItemEquipped(item.uid)?"ABLEGEN":"AUSRÜSTEN · "+equipmentLabel(item.equipSlot)}else{equipButton.classList.add("disabled");equipText.textContent=item.jobEquipment?"JOB-AUSRÜSTUNG":"NICHT AUSRÜSTBAR"}if(useText)useText.textContent=item.jobEquipment?"ZURÜCK IN DIE WAFFENKAMMER":"BENUTZEN";qs("#contextUse").classList.toggle("disabled",item.jobEquipment?false:!item.usable);const qty=Number(item.qty)||0;qs("#contextDrop").classList.toggle("disabled",item.jobEquipment||qty<=0);qs("#contextDropQuantity").classList.toggle("disabled",item.jobEquipment||qty<=1);contextMenu.classList.add("show");requestAnimationFrame(()=>clampFloatingPanel(contextMenu,x,y))}
function openQuantityPanel(slotNo,x,y){const item=itemBySlot(slotNo);if(!item)return;quantitySlot=slotNo;hideContextMenu();const max=Math.max(1,Number(item.qty)||1);quantityInput.min="1";quantityInput.max=String(max);quantityInput.value="1";qs("#quantitySub").textContent=item.name.toUpperCase()+" · VERFÜGBAR: "+max;quantityPanel.classList.add("show");requestAnimationFrame(()=>{clampFloatingPanel(quantityPanel,x,y);quantityInput.focus();quantityInput.select()})}
function sanitizeQuantity(){if(quantitySlot===null)return 1;const item=itemBySlot(quantitySlot);if(!item)return 1;const max=Math.max(1,Number(item.qty)||1);let value=Math.floor(Number(quantityInput.value)||1);value=Math.max(1,Math.min(max,value));quantityInput.value=String(value);return value}
function clearDragPreview(){qsa(".slot.dragover,.equipSlot.dragover,.armorSlot.dragover").forEach(x=>x.classList.remove("dragover"))}
function gridMetrics(){const grid=qs("#slotGrid"),first=qs(".slot",grid);if(!grid||!first)return null;const gr=grid.getBoundingClientRect(),sr=first.getBoundingClientRect(),style=getComputedStyle(grid),gx=parseFloat(style.columnGap)||0,gy=parseFloat(style.rowGap)||gx;return {grid,gr,cellW:sr.width,cellH:sr.height,gapX:gx,gapY:gy,stepX:sr.width+gx,stepY:sr.height+gy}}
function slotFromPoint(x,y){const m=gridMetrics();if(!m)return null;const col=Math.floor((x-m.gr.left)/m.stepX)+1,row=Math.floor((y-m.gr.top)/m.stepY)+1;if(col<1||col>state.gridColumns||row<1||row>state.gridRows)return null;return (row-1)*state.gridColumns+col}
function anchorFromPoint(x,y,grabCol,grabRow){const hover=slotFromPoint(x,y);if(!hover)return null;const pos=slotToGrid(hover),col=pos.col-(Number(grabCol)||0),row=pos.row-(Number(grabRow)||0);if(col<1||row<1||col>state.gridColumns||row>state.gridRows)return null;return (row-1)*state.gridColumns+col}
function previewDestination(target){clearDragPreview();if(state.draggedSlot===null||!target)return;const item=itemBySlot(state.draggedSlot)||itemCoveringSlot(state.draggedSlot);if(!item)return;footprint(item,target).forEach(slotNo=>{const el=qs('.slot[data-slot="'+slotNo+'"]');if(el)el.classList.add("dragover")})}
function beginInventoryDrag(e,item,el){if(e.button!==0)return;const rect=el.getBoundingClientRect(),m=gridMetrics(),w=Math.max(1,Number(item.sizeW)||1),h=Math.max(1,Number(item.sizeH)||1);if(!m)return;const localX=Math.max(0,e.clientX-rect.left),localY=Math.max(0,e.clientY-rect.top),grabCol=Math.max(0,Math.min(w-1,Math.floor(localX/m.stepX))),grabRow=Math.max(0,Math.min(h-1,Math.floor(localY/m.stepY)));dragSession={sourceSlot:Number(item.slot),uid:item.uid,item,element:el,startX:e.clientX,startY:e.clientY,offsetX:e.clientX-rect.left,offsetY:e.clientY-rect.top,grabCol,grabRow,moving:false,target:null,targetEquip:null,targetArmor:null,ghost:null,width:rect.width,height:rect.height};state.draggedSlot=Number(item.slot);hideContextMenu();hideQuantityPanel();e.preventDefault();e.stopPropagation()}
function startDragGhost(){if(!dragSession||dragSession.moving)return;sfx("drag");dragSession.moving=true;dragSession.element.classList.add("dragging");document.body.classList.add("inventoryDragging");const ghost=dragSession.element.cloneNode(true);ghost.classList.remove("selected","dragging");ghost.classList.add("dragGhost");ghost.style.width=dragSession.width+"px";ghost.style.height=dragSession.height+"px";ghost.style.gridColumn="auto";ghost.style.gridRow="auto";document.body.appendChild(ghost);dragSession.ghost=ghost}
function updateDragGhost(x,y){if(!dragSession||!dragSession.ghost)return;dragSession.ghost.style.left=(x-dragSession.offsetX)+"px";dragSession.ghost.style.top=(y-dragSession.offsetY)+"px"}
function closestAt(x,y,sel){const node=document.elementFromPoint(x,y);return node&&node.closest?node.closest(sel):null}
function onInventoryMouseMove(e){if(!dragSession)return;const dx=e.clientX-dragSession.startX,dy=e.clientY-dragSession.startY;if(!dragSession.moving&&Math.sqrt(dx*dx+dy*dy)<4)return;if(!dragSession.moving)startDragGhost();updateDragGhost(e.clientX,e.clientY);clearDragPreview();const armor=closestAt(e.clientX,e.clientY,".armorSlot"),equip=armor?null:closestAt(e.clientX,e.clientY,".equipSlot");dragSession.targetArmor=null;dragSession.targetEquip=null;dragSession.target=null;if(armor){armor.classList.add("dragover");dragSession.targetArmor=armor.dataset.armor||null}else if(equip){equip.classList.add("dragover");dragSession.targetEquip=equip.dataset.equip||null}else{const target=anchorFromPoint(e.clientX,e.clientY,dragSession.grabCol,dragSession.grabRow);dragSession.target=target;previewDestination(target)}e.preventDefault()}
function cleanupInventoryDrag(){if(!dragSession){state.draggedSlot=null;clearDragPreview();return}if(dragSession.element)dragSession.element.classList.remove("dragging");if(dragSession.ghost&&dragSession.ghost.parentNode)dragSession.ghost.parentNode.removeChild(dragSession.ghost);document.body.classList.remove("inventoryDragging");clearDragPreview();state.draggedSlot=null;dragSession=null}
function finishInventoryMouseDrag(e){if(!dragSession)return;const session=dragSession;if(session.moving){suppressClickUntil=Date.now()+220;const equipType=session.targetEquip,armorType=session.targetArmor,target=session.target;cleanupInventoryDrag();if(armorType){if(session.item.armorSlot!==armorType){showToast("DIESER GEGENSTAND PASST NICHT IN "+armorSlotInfo(armorType).label)}else{sfx("equip");dispatch("equipArmor",{slot:session.sourceSlot,armorSlot:armorType})}}else if(equipType){if(session.item.equipSlot!==equipType){showToast("DIESER GEGENSTAND PASST NICHT IN "+equipmentLabel(equipType))}else{sfx("equip");dispatch("equip",{slot:session.sourceSlot,equipSlot:equipType})}}else if(target!==null&&Number(target)!==Number(session.sourceSlot)){sfx("click");dispatch("move",{from:session.sourceSlot,to:target})}e.preventDefault();e.stopPropagation()}else{cleanupInventoryDrag()}}
document.addEventListener("mousemove",onInventoryMouseMove,true);document.addEventListener("mouseup",finishInventoryMouseDrag,true);
function renderSlots(){const grid=qs("#slotGrid");grid.innerHTML="";grid.style.gridTemplateColumns="repeat("+state.gridColumns+",var(--slot))";for(let slotNo=1;slotNo<=state.slotCount;slotNo++){const pos=slotToGrid(slotNo),slot=document.createElement("div");slot.className="slot";slot.dataset.slot=slotNo;slot.style.gridColumn=String(pos.col);slot.style.gridRow=String(pos.row);slot.innerHTML='<span class="slotNo">'+slotNo+'</span>';slot.addEventListener("click",()=>{if(Date.now()<suppressClickUntil)return;sfx("click");selectSlot(slotNo)});grid.appendChild(slot)}
state.items.forEach(item=>{const pos=slotToGrid(item.slot),w=Math.max(1,Number(item.sizeW)||1),h=Math.max(1,Number(item.sizeH)||1),el=document.createElement("div");el.className="itemTile"+(Number(state.selectedSlot)===Number(item.slot)?" selected":"")+(isItemEquipped(item.uid)?" equipped":"");el.draggable=false;el.dataset.slot=item.slot;el.dataset.uid=item.uid;el.style.gridColumn=pos.col+" / span "+w;el.style.gridRow=pos.row+" / span "+h;const q=Number(item.qty)||0;el.innerHTML=iconHTML(item)+(q!==1?'<span class="qty">x'+q+'</span>':'')+((w>1||h>1)?'<span class="sizeBadge">'+w+'×'+h+'</span>':'')+'<span class="rarity r-'+(item.rarity||'common')+'"></span>';el.addEventListener("mousedown",e=>beginInventoryDrag(e,item,el));el.addEventListener("mouseenter",()=>{if(!dragSession)sfx("hover")});el.addEventListener("click",e=>{e.stopPropagation();if(Date.now()<suppressClickUntil)return;sfx("click");selectSlot(item.slot)});el.addEventListener("contextmenu",e=>{e.preventDefault();e.stopPropagation();if(Date.now()<suppressClickUntil)return;sfx("click");selectSlot(item.slot,false);openContextMenu(item.slot,e.clientX,e.clientY)});el.addEventListener("dblclick",e=>{e.preventDefault();e.stopPropagation();if(Date.now()<suppressClickUntil)return;if(!toggleEquip(item)&&item.usable)dispatch("use",{slot:item.slot})});grid.appendChild(el)});if(state.selectedSlot)selectSlot(state.selectedSlot,false)}
function itemDescription(item){let d=item.desc||"";if(item.armorStats){const a=item.armorStats,parts=[];if(a.armor)parts.push("+"+a.armor+" RÜSTUNG");if(a.health)parts.push("+"+a.health+" HP");if(a.dr)parts.push(a.dr+"% SCHADENSREDUKTION");if(a.carry)parts.push("+"+a.carry+" KG TRAGKRAFT");parts.unshift(armorSlotInfo(item.armorSlot).label+" RÜSTUNG");d+=(d?" · ":"")+parts.join(" · ")}return d}
function selectSlot(slotNo,emit=true){state.selectedSlot=Number(slotNo);qsa(".slot").forEach(slot=>slot.classList.toggle("selected",Number(slot.dataset.slot)===Number(slotNo)));qsa(".itemTile").forEach(tile=>tile.classList.toggle("selected",Number(tile.dataset.slot)===Number(slotNo)));const item=itemBySlot(slotNo)||itemCoveringSlot(slotNo),wrap=qs("#selectedIconWrap");if(!item){wrap.innerHTML='<i id="selectedIcon" class="fa-solid fa-box"></i>';qs("#selectedName").textContent="LEERER SLOT";qs("#selectedDesc").textContent="Diesem Slot ist kein Gegenstand zugewiesen.";qs("#selectedWeight").textContent="0.0 KG";return}state.selectedSlot=Number(item.slot);qsa(".slot").forEach(slot=>slot.classList.toggle("selected",footprint(item).includes(Number(slot.dataset.slot))));qsa(".itemTile").forEach(tile=>tile.classList.toggle("selected",Number(tile.dataset.slot)===Number(item.slot)));wrap.innerHTML=iconHTML(item);qs("#selectedName").textContent=item.name.toUpperCase();qs("#selectedDesc").textContent=itemDescription(item)+" · GRÖSSE "+(item.sizeW||1)+"×"+(item.sizeH||1);qs("#selectedWeight").textContent=((Number(item.weight)||0)*(Number(item.qty)||0)).toFixed(1)+" KG"}
function renderEquipment(){["primary","secondary","specialized","utility"].forEach(type=>{const holder=qs("#equip-"+type),item=state.equipment[type]?itemByUID(state.equipment[type]):null;if(!holder)return;if(item){holder.innerHTML='<div class="equipIcon">'+iconHTML(item)+'</div><div class="equippedName">'+escapeHTML(item.name.toUpperCase())+'</div>'}else{holder.innerHTML='<div class="equipIcon"><i class="fa-solid fa-plus"></i></div><div class="equippedEmpty">GEGENSTAND HIERHER ZIEHEN</div>'}})}
function buildArmorLayout(){const sig=JSON.stringify(state.armorSlots);if(sig===armorLayoutSig)return;armorLayoutSig=sig;const left=qs("#armorLeft"),right=qs("#armorRight");left.innerHTML="";right.innerHTML="";state.armorSlots.forEach(slot=>{const el=document.createElement("div");el.className="armorSlot";el.dataset.armor=slot.id;el.addEventListener("mouseenter",()=>{if(!dragSession)sfx("hover")});el.title=slot.hint||"";el.innerHTML='<div class="armorLabel">'+escapeHTML(String(slot.label||slot.id).toUpperCase())+'</div><div class="armorBox" id="armor-'+escapeHTML(slot.id)+'"></div>';el.addEventListener("dblclick",()=>{if(state.armor[slot.id])sfx("equip"),dispatch("unequipArmor",{armorSlot:slot.id})});el.addEventListener("contextmenu",e=>{e.preventDefault();if(state.armor[slot.id])dispatch("unequipArmor",{armorSlot:slot.id})});el.addEventListener("click",()=>{const uid=state.armor[slot.id],item=uid&&itemByUID(uid);if(item)selectSlot(item.slot)});(slot.side==="right"?right:left).appendChild(el)})}
function renderArmor(){const frame=qs("#dollFrame");buildArmorLayout();state.armorSlots.forEach(slot=>{const box=qs("#armor-"+slot.id);if(!box)return;const uid=state.armor[slot.id],item=uid?itemByUID(uid):null;if(item){box.className="armorBox filled";box.dataset.rarity=item.rarity||"common";box.innerHTML=iconHTML(item,"itemFa");box.parentNode.title=item.name}else{box.className="armorBox";box.removeAttribute("data-rarity");box.innerHTML='<i class="fa-solid '+faClass(slot.icon)+' ghostIcon"></i>';box.parentNode.title=slot.hint||""}});const st=state.stats||{},parts=[];if(st.bonusArmor)parts.push("<strong>+"+st.bonusArmor+"</strong> RÜSTUNG");if(st.bonusHealth)parts.push("<strong>+"+st.bonusHealth+"</strong> HP");if(st.damageReduction)parts.push("<strong>"+st.damageReduction+"%</strong> SCHADENSRED.");if(st.carry)parts.push("<strong>+"+st.carry+"</strong> KG");qs("#dollSummary").innerHTML=parts.length?parts.join(" · "):"KEINE RÜSTUNG ANGELEGT";const anyWorn=Object.keys(state.armor).some(k=>state.armor[k]);qs("#dollNote").textContent=!state.armorEnabled?"RÜSTUNGSSYSTEM DEAKTIVIERT":(anyWorn&&st.visualAllowed===false?"WERTE AKTIV · RÜSTUNG AN DIESEM MODEL NICHT SICHTBAR":"RÜSTUNG AUF EINEN SLOT ZIEHEN · DOPPELKLICK ZUM ABLEGEN");if(frame){const noArmor=!state.armorEnabled||!state.armorSlots.length;qs("#armorLeft").style.display=noArmor?"none":"";qs("#armorRight").style.display=noArmor?"none":"";qs("#dollSummary").style.display=noArmor?"none":"";qs("#dollNote").style.display=noArmor?"none":"";qs(".dollHead .sectionKicker").textContent=noArmor?"CHARAKTER":"RÜSTUNG · CHARAKTER";frame.style.gridTemplateColumns=noArmor?"minmax(0,1fr)":""}}
function renderStats(){const st=state.stats||{},hp=Number(st.health)||0,mhp=Math.max(1,Number(st.maxHealth)||100),ar=Number(st.armor)||0,mar=Math.max(1,Number(st.maxArmor)||100);qs("#hpFill").style.height=Math.max(0,Math.min(100,hp/mhp*100))+"%";qs("#arFill").style.height=Math.max(0,Math.min(100,ar/mar*100))+"%";qs("#hpVal").textContent=String(Math.round(hp));qs("#arVal").textContent=String(Math.round(ar));const bonus=qs("#arBonus"),b=Number(st.bonusArmor)||0;if(b>0&&b<mar){bonus.style.display="block";bonus.style.bottom=Math.max(0,Math.min(100,(mar-b)/mar*100))+"%"}else bonus.style.display="none"}
function syncDoll(){const hook=qs("#dollViewport");if(!hook)return;const r=hook.getBoundingClientRect();try{if(window.gmod&&gmod.dollViewport)gmod.dollViewport(JSON.stringify({x:r.left,y:r.top,w:r.width,h:r.height,viewportW:window.innerWidth,viewportH:window.innerHeight}))}catch(_){}}
qsa(".equipSlot").forEach(slot=>{const type=slot.dataset.equip;slot.addEventListener("mouseenter",()=>{if(!dragSession)sfx("hover")});slot.addEventListener("dblclick",()=>{if(state.equipment[type])dispatch("unequip",{equipSlot:type})});slot.addEventListener("contextmenu",e=>{e.preventDefault();if(state.equipment[type])dispatch("unequip",{equipSlot:type})})});
qs("#contextEquip").addEventListener("click",()=>{if(contextSlot===null)return;toggleEquip(itemBySlot(contextSlot));hideContextMenu()});
qs("#contextUse").addEventListener("click",()=>{sfx("click");if(contextSlot===null)return;const item=itemBySlot(contextSlot);if(!item)return;if(item.jobEquipment){dispatch("store",{slot:contextSlot});hideContextMenu();return}if(!item.usable)return;dispatch("use",{slot:contextSlot});hideContextMenu()});
qs("#contextDrop").addEventListener("click",()=>{sfx("click");if(contextSlot===null)return;const item=itemBySlot(contextSlot);if(!item||(Number(item.qty)||0)<=0)return;dispatch("drop",{slot:contextSlot,quantity:1});hideContextMenu()});
qs("#contextDropQuantity").addEventListener("click",()=>{if(contextSlot===null)return;const item=itemBySlot(contextSlot);if(!item||(Number(item.qty)||0)<=1)return;const rect=contextMenu.getBoundingClientRect();openQuantityPanel(contextSlot,rect.right+6,rect.top)});
qs("#quantityMinus").addEventListener("click",()=>{quantityInput.value=String(sanitizeQuantity()-1);sanitizeQuantity()});qs("#quantityPlus").addEventListener("click",()=>{quantityInput.value=String(sanitizeQuantity()+1);sanitizeQuantity()});quantityInput.addEventListener("input",sanitizeQuantity);quantityInput.addEventListener("keydown",e=>{if(e.key==="Enter")qs("#quantityConfirm").click();if(e.key==="Escape")hideQuantityPanel()});qs("#quantityCancel").addEventListener("click",hideQuantityPanel);qs("#quantityConfirm").addEventListener("click",()=>{sfx("click");if(quantitySlot===null)return;dispatch("drop",{slot:quantitySlot,quantity:sanitizeQuantity()});hideQuantityPanel()});
document.addEventListener("mousedown",e=>{if(contextMenu.classList.contains("show")&&!contextMenu.contains(e.target))hideContextMenu();if(quantityPanel.classList.contains("show")&&!quantityPanel.contains(e.target))hideQuantityPanel()});window.addEventListener("blur",()=>{hideContextMenu();hideQuantityPanel();cleanupInventoryDrag()});qs("#closeBtn").addEventListener("click",()=>{try{if(window.gmod&&gmod.closeInventory)gmod.closeInventory()}catch(_){}});window.addEventListener("keydown",e=>{if(e.key==="Escape"){if(quantityPanel.classList.contains("show")){hideQuantityPanel();return}if(contextMenu.classList.contains("show")){hideContextMenu();return}try{if(window.gmod&&gmod.closeInventory)gmod.closeInventory()}catch(_){}}});
function setWeight(current,max){state.currentWeight=Number(current)||0;state.maxWeight=Math.max(1,Number(max)||100);qs("#weightNow").textContent=String(Math.round(state.currentWeight)).padStart(3,"0");qs("#weightMax").textContent=String(Math.round(state.maxWeight));qs("#loadValue").textContent=Math.round(state.currentWeight)+" KG";qs("#capacityFill").style.width=Math.max(0,Math.min(100,state.currentWeight/state.maxWeight*100))+"%"}
function asMap(v){return v&&typeof v==="object"&&!Array.isArray(v)?v:{}}
function renderAll(){if(dragSession){clearTimeout(renderAll._t);renderAll._t=setTimeout(renderAll,250);return}renderSlots();renderEquipment();renderArmor();renderStats()}
window.InventoryUI={applySync(data){if(!data||typeof data!=="object")return;state.gridColumns=Math.max(1,Number(data.gridColumns)||5);state.gridRows=Math.max(1,Number(data.gridRows)||5);state.slotCount=Math.max(1,Number(data.slotCount)||(state.gridColumns*state.gridRows));state.items=Array.isArray(data.items)?data.items.map(x=>({slot:Number(x.slot),uid:String(x.uid||""),id:String(x.id||""),name:String(x.name||"Item"),icon:String(x.icon||"fa-box"),iconURL:String(x.iconURL||""),qty:Number(x.qty)||0,weight:Number(x.weight)||0,rarity:String(x.rarity||"common"),type:String(x.type||"generic"),desc:String(x.desc||""),equipSlot:x.equipSlot?String(x.equipSlot):null,armorSlot:x.armorSlot?String(x.armorSlot):null,armorStats:x.armorStats||null,jobEquipment:!!x.jobEquipment,usable:!!x.usable,virtualMoney:!!x.virtualMoney,sizeW:Math.max(1,Number(x.sizeW)||1),sizeH:Math.max(1,Number(x.sizeH)||1)})):[];const eq=asMap(data.equipment);state.equipment={primary:eq.primary||null,secondary:eq.secondary||null,specialized:eq.specialized||null,utility:eq.utility||null};state.armor=asMap(data.armor);state.armorSlots=Array.isArray(data.armorSlots)?data.armorSlots:[];state.armorEnabled=data.armorEnabled!==false;state.stats=asMap(data.stats);if(data.character){qs("#characterName").textContent=String(data.character.name||"");qs("#topPlayerName").textContent=String(data.character.name||"");qs("#balance").textContent=String(data.character.balance||"0 CR")}setWeight(data.currentWeight,data.maxWeight);renderAll();requestAnimationFrame(syncDoll)},setIcons(map){map=asMap(map);let changed=false;Object.keys(map).forEach(k=>{if(state.icons[k]!==map[k]){state.icons[k]=map[k];changed=true}});if(changed){renderAll()}},toast:showToast,syncDoll:syncDoll};
renderAll();setWeight(0,100);window.addEventListener("resize",()=>requestAnimationFrame(syncDoll));setInterval(syncDoll,500);
})();
</script>
</body>
</html>
]==]

local function jsString(value)
    local wrapped = util.TableToJSON({ tostring(value or "") }, false) or "[\"\"]"
    return wrapped .. "[0]"
end

local function backpackAnimationEnabled()
    local cfg = istable(C.BackpackAnimation) and C.BackpackAnimation or {}
    if cfg.Enabled == false then return false end

    local ply = LocalPlayer()
    if cfg.AliveOnly ~= false and (not IsValid(ply) or not ply:Alive()) then
        return false
    end

    return true
end

local function sendBackpackState(opening)
    net.Start("GRNINV_BackpackState")
    net.WriteBool(opening == true)
    net.SendToServer()
end

function INV.CloseUI()
    local hadPanel = IsValid(INV.UI)
    local wasOpening = INV._Opening == true

    INV._OpenToken = (INV._OpenToken or 0) + 1
    INV._Opening = false

    if (hadPanel or wasOpening) and isfunction(INV.PlayUISound) then INV.PlayUISound("Close") end
    if isfunction(INV.RemoveArmorDoll) then INV.RemoveArmorDoll() end
    if hadPanel then
        INV.UI:Remove()
    end
    INV.UI = nil

    if hadPanel or wasOpening then
        sendBackpackState(false)
        net.Start("GRNINV_ClientClosed")
        net.SendToServer()
    end
end

local function sendAction(raw)
    local decoded = util.JSONToTable(tostring(raw or ""))
    if not istable(decoded) then return end
    local action = tostring(decoded.name or "")
    local data = istable(decoded.payload) and decoded.payload or {}
    if action == "dropQuantity" then action = "drop" end
    if not ({ move=true, equip=true, unequip=true, use=true, store=true, drop=true, equipArmor=true, unequipArmor=true })[action] then return end

    net.Start("GRNINV_Action")
    net.WriteString(action)
    net.WriteString(util.TableToJSON(data, false) or "{}")
    net.SendToServer()
end

local function createInventoryPanel(openToken)
    if openToken ~= INV._OpenToken or not INV._Opening then return end
    INV._Opening = false

    local pnl = vgui.Create("DHTML")
    INV.UI = pnl
    pnl:SetPos(0, 0)
    pnl:SetSize(ScrW(), ScrH())
    pnl:SetMouseInputEnabled(true)
    pnl:SetKeyboardInputEnabled(true)
    pnl:SetAllowLua(true)

    pnl:AddFunction("gmod", "inventoryAction", function(raw)
        sendAction(raw)
    end)

    pnl:AddFunction("gmod", "closeInventory", function()
        INV.CloseUI()
    end)

    pnl:AddFunction("gmod", "uiSound", function(kind)
        if isfunction(INV.PlayUISound) then INV.PlayUISound(kind) end
    end)

    pnl:AddFunction("gmod", "dollViewport", function(raw)
        if isfunction(INV.SyncArmorDoll) then INV.SyncArmorDoll(raw) end
    end)

    pnl:SetHTML(SYMUI and SYMUI.ThemeHTML(HTML) or HTML)
    pnl:MakePopup()

    if INV.LastSyncJSON then
        local wrapped = util.TableToJSON({ INV.LastSyncJSON }, false) or "[\"{}\"]"
        pnl:QueueJavascript("if(window.InventoryUI){InventoryUI.applySync(JSON.parse((" .. wrapped .. ")[0]));}")
        INV.PushItemIcons(INV.LastSyncJSON)
    end

    net.Start("GRNINV_RequestSync")
    net.SendToServer()
end

function INV.OpenUI()
    if IsValid(INV.UI) or INV._Opening then
        INV.CloseUI()
        return
    end

    INV._OpenToken = (INV._OpenToken or 0) + 1
    local openToken = INV._OpenToken
    INV._Opening = true
    if isfunction(INV.PlayUISound) then INV.PlayUISound("Open") end

    local animate = backpackAnimationEnabled()
    local cfg = istable(C.BackpackAnimation) and C.BackpackAnimation or {}
    local delay = animate and math.max(0, tonumber(cfg.OpenUIDelay) or 0.48) or 0

    if animate then
        -- Start the first-person backpack deploy immediately. The DHTML panel is
        -- intentionally delayed so the player sees the bag enter the screen
        -- before the inventory becomes interactive.
        sendBackpackState(true)
    end

    if delay <= 0 then
        createInventoryPanel(openToken)
    else
        timer.Simple(delay, function()
            createInventoryPanel(openToken)
        end)
    end
end

concommand.Add("grn_inventory_open", function()
    INV.OpenUI()
end)

INV._OpenKeyWasDown = INV._OpenKeyWasDown or false

hook.Add("Think", "GRNInventory_Keybind", function()
    local cfg = istable(C.BackpackAnimation) and C.BackpackAnimation or {}
    local ply = LocalPlayer()
    if (IsValid(INV.UI) or INV._Opening) and cfg.AliveOnly ~= false and IsValid(ply) and not ply:Alive() then
        INV.CloseUI()
        INV._OpenKeyWasDown = false
        return
    end

    local key = C.OpenKey or KEY_I
    local down = input.IsKeyDown(key)

    if down and not INV._OpenKeyWasDown then
        if IsValid(INV.UI) or INV._Opening then
            INV.CloseUI()
        else
            if not gui.IsGameUIVisible() and not gui.IsConsoleVisible() then
                local focus = vgui.GetKeyboardFocus()
                if not IsValid(focus) then
                    INV.OpenUI()
                end
            end
        end
    end

    INV._OpenKeyWasDown = down
end)

-- Rendered model icons (armor + weapons without IconURL) are pushed to the
-- page as data: URIs keyed by item ID.
local function pushIcon(itemID, uri)
    if not IsValid(INV.UI) or not uri then return end
    local map = util.TableToJSON({ [itemID] = uri }, false)
    if not map then return end
    INV.UI:QueueJavascript("if(window.InventoryUI&&InventoryUI.setIcons){InventoryUI.setIcons(" .. map .. ");}")
end

function INV.PushItemIcons(json)
    if not isfunction(INV.RequestItemIcon) then return end
    local data = util.JSONToTable(tostring(json or ""))
    if not istable(data) or not istable(data.items) then return end
    local seen = {}
    for _, item in ipairs(data.items) do
        local id = tostring(item.id or "")
        if id ~= "" and not seen[id] and (item.iconURL or "") == "" then
            seen[id] = true
            INV.RequestItemIcon(id, function(uri) pushIcon(id, uri) end)
        end
    end
end

net.Receive("GRNINV_Sync", function()
    local json = net.ReadString()
    local changed = INV.LastSyncJSON ~= json
    INV.LastSyncJSON = json
    if not IsValid(INV.UI) then return end
    if not changed and INV.UI.GRNSynced then return end
    INV.UI.GRNSynced = true

    local wrapped = util.TableToJSON({ json }, false) or "[\"{}\"]"
    INV.UI:QueueJavascript("if(window.InventoryUI){InventoryUI.applySync(JSON.parse((" .. wrapped .. ")[0]));}")
    INV.PushItemIcons(json)
end)

net.Receive("GRNINV_Notice", function()
    local text = net.ReadString()
    if IsValid(INV.UI) then
        INV.UI:QueueJavascript("if(window.InventoryUI){InventoryUI.toast(" .. jsString(text) .. ");}")
    else
        chat.AddText(Color(255, 190, 50), "[Inventar] ", Color(216, 219, 225), text)
    end
end)

hook.Add("OnScreenSizeChanged", "GRNInventory_Resize", function()
    if IsValid(INV.UI) then
        INV.UI:SetPos(0, 0)
        INV.UI:SetSize(ScrW(), ScrH())
    end
end)
