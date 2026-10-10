FCR = FCR or {}
FCR.UI = FCR.UI or {}
FCR.Runtime = FCR.Runtime or {}

local UI = FCR.UI
local Runtime = FCR.Runtime

UI.Pending = UI.Pending or {}
UI.Ready = UI.Ready or false

local PANEL_HTML_TEMPLATE = [====[<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
        /* =========================================
           ECHOES OF CLONES THEME (passend zu grn_hud_v1)
           ========================================= */
        @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800&display=swap');

        :root {
            --yellow: rgb(252, 178, 73);
            --yellow-soft: rgba(252, 178, 73, .68);
            --yellow-dim: rgba(252, 178, 73, .22);
            --yellow-faint: rgba(252, 178, 73, .08);

            --white: #f4f1e9;
            --text: #d8dbe1;
            --soft: #9da3ad;
            --muted: #656b75;

            --dark: #05070a;
            --panel: rgba(8, 11, 15, .86);
            --panel-soft: rgba(14, 18, 23, .70);
            --panel-strong: rgba(7, 9, 12, .95);

            --line: rgba(207, 216, 228, .15);
            --line-strong: rgba(207, 216, 228, .30);

            --red: #e15858;
            --green: #4acb82;
            --cyan: #50c8dc;

            --font-main: "Montserrat", Arial, Helvetica, sans-serif;
            --font-title: "Bebas Neue", "Arial Narrow", Arial, sans-serif;

            --cut: polygon(10px 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%, 0 10px);
            --cut-sm: polygon(5px 0, 100% 0, 100% calc(100% - 5px), calc(100% - 5px) 100%, 0 100%, 0 5px);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            user-select: none;
        }

        body {
            background: rgba(0, 0, 0, 0.45);
            font-family: var(--font-main);
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            overflow: hidden;
            color: var(--white);
            letter-spacing: 0.02em;
            text-shadow: 0 1px 2px rgba(0, 0, 0, .9);
        }

        ::-webkit-scrollbar { width: 4px; }
        ::-webkit-scrollbar-track { background: var(--line); }
        ::-webkit-scrollbar-thumb { background: var(--yellow); }

        /* =========================================
           HAUPTPANEL
           ========================================= */
        .clipboard-panel {
            position: relative;
            width: min(94vw, 1120px);
            max-width: 1120px;
            height: min(92vh, 860px);
            max-height: min(92vh, 860px);
            padding: 16px 20px 16px;
            background: linear-gradient(180deg, var(--panel-strong), rgba(5, 7, 10, .93));
            border: 1px solid var(--line);
            clip-path: var(--cut);
            color: var(--white);
            display: flex;
            flex-direction: column;
            gap: 9px;
            overflow: hidden;
            isolation: isolate;

            transform: translateY(10px);
            opacity: 0;
            animation: panelIn .22s ease forwards;
        }

        @keyframes panelIn { to { transform: translateY(0); opacity:1; } }
        .clipboard-panel.shake { animation: panelIn .16s ease forwards, shake .34s ease; }
        @keyframes shake { 0%,100%{transform:translateX(0)} 20%{transform:translateX(-7px)} 40%{transform:translateX(6px)} 60%{transform:translateX(-5px)} 80%{transform:translateX(3px)} }

        /* Dezentes Raster */
        .clipboard-panel::before {
            content: '';
            position: absolute;
            inset: 0;
            pointer-events: none;
            z-index: -1;
            background:
                linear-gradient(90deg, rgba(207, 216, 228, 0.025) 1px, transparent 1px),
                linear-gradient(0deg, rgba(207, 216, 228, 0.025) 1px, transparent 1px);
            background-size: 40px 40px, 40px 40px;
        }

        /* Gelbe Akzentlinie oben */
        .clipboard-panel::after {
            content: '';
            position: absolute;
            left: 0;
            right: 0;
            top: 0;
            height: 2px;
            pointer-events: none;
            background: linear-gradient(90deg, var(--yellow) 0, var(--yellow) 140px, var(--line) 140px, transparent);
        }

        /* =========================================
           KOPFBEREICH
           ========================================= */
        .title-section {
            text-align: left;
            padding-left: 12px;
            border-left: 2px solid var(--yellow);
            margin-bottom: 2px;
        }

        .title-section h1 {
            font-family: var(--font-title);
            font-weight: 400;
            font-size: clamp(28px, 4.4vh, 40px);
            line-height: 1;
            color: var(--white);
            margin: 0;
            text-transform: uppercase;
            letter-spacing: .06em;
        }

        .kicker {
            font-size: 10px;
            font-weight: 700;
            color: var(--yellow);
            text-transform: uppercase;
            letter-spacing: 0.22em;
            display: flex;
            align-items: center;
            gap: 7px;
            margin-bottom: 4px;
        }
        .kicker svg { width: 13px; height: 13px; }
        .vehicleName {
            font-size: 11px;
            font-weight: 600;
            color: var(--soft);
            text-transform: uppercase;
            letter-spacing: 0.18em;
            margin-top: 4px;
        }

        /* =========================================
           INFO-KACHELN
           ========================================= */
        .form-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 10px;
        }

        @media (max-width: 768px) {
            .form-grid { grid-template-columns: 1fr 1fr; }
        }

        .full-width { grid-column: 1 / -1; }

        .input-group {
            display: flex;
            flex-direction: column;
            background: var(--panel);
            border: 1px solid var(--line);
            padding: 12px 15px;
            gap: 4px;
            position: relative;
            overflow: hidden;
        }

        .form-grid .input-group {
            align-items: flex-start;
            justify-content: center;
            text-align: left;
            min-height: 74px;
            padding: 10px 14px 9px 16px;
            gap: 5px;
        }

        .input-group::before {
            content: '';
            position: absolute;
            left: 0;
            top: 8px;
            bottom: 8px;
            width: 2px;
            background: var(--yellow);
        }

        .input-group label {
            font-size: 11px;
            color: var(--soft);
            text-transform: uppercase;
            letter-spacing: .16em;
            font-weight: 700;
            display: flex;
            align-items: center;
        }

        .form-grid .input-group label {
            justify-content: flex-start;
            font-size: 11px;
            line-height: 1;
        }

        .input-group label svg {
            width: 13px;
            height: 13px;
            margin-right: 6px;
            color: var(--yellow);
        }

        .form-grid .input-group label svg {
            width: 14px;
            height: 14px;
            margin-right: 7px;
        }

        .chipValue {
            font-family: var(--font-title);
            font-size: 28px;
            color: var(--white);
            letter-spacing: .05em;
        }

        .form-grid .chipValue {
            width: 100%;
            text-align: left;
            font-size: 34px;
            line-height: 1;
        }

        .phaseName {
            font-family: var(--font-title);
            font-size: 30px;
            color: var(--white);
            text-transform: uppercase;
            letter-spacing: .05em;
            line-height: 1;
        }

        .statusInline {
            font-family: var(--font-main);
            font-size: 11px;
            font-weight: 700;
            color: var(--green);
            background: rgba(74, 203, 130, 0.08);
            padding: 6px 11px;
            border: 1px solid rgba(74, 203, 130, 0.38);
            letter-spacing: .16em;
            text-transform: uppercase;
            line-height: 1;
            white-space: nowrap;
        }

        .phaseTitleRow {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 2px;
            gap: 14px;
        }

        .input-group.full-width {
            padding: 9px 15px 10px 16px;
            overflow: visible;
        }

        #phaseOverline {
            display: block;
            line-height: 1;
            margin-bottom: 5px;
            color: var(--yellow);
        }

        #instruction {
            color: var(--soft);
            font-size: 11px;
            font-weight: 500;
            margin-top: 4px;
            letter-spacing: .1em;
            text-transform: uppercase;
        }

        /* =========================================
           SPIELFELD
           ========================================= */
        .signature-container {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .signature-pad {
            background: rgba(5, 7, 10, 0.78);
            border: 1px solid var(--line);
            cursor: crosshair;
            box-shadow: inset 0 0 24px rgba(0, 0, 0, 0.75);
            width: 100%;
            height: 348px;
            min-height: 348px;
            display: block;
        }

        .playBadge {
            display: flex;
            align-items: center;
            gap: 6px;
            color: var(--yellow);
            font-size: 11px;
            font-weight: 700;
            letter-spacing: .16em;
            text-transform: uppercase;
        }
        .playBadge svg { width: 14px; height: 14px; }

        #playAssist {
            color: var(--soft);
            font-size: 11px;
            font-weight: 600;
            letter-spacing: .14em;
            text-transform: uppercase;
        }

        #footerNote {
            color: var(--text);
            font-size: 11px;
            font-weight: 600;
            letter-spacing: .14em;
            text-transform: uppercase;
        }

        /* =========================================
           BUTTON
           ========================================= */
        .action-button {
            background: rgba(252, 178, 73, .84);
            color: #07090c;
            border: 1px solid var(--yellow);
            padding: 9px 16px 7px;
            font-family: var(--font-title);
            font-size: clamp(20px, 2.6vh, 24px);
            letter-spacing: .08em;
            cursor: pointer;
            transition: background .15s ease;
            width: 100%;
            text-transform: uppercase;
            text-align: center;
            text-shadow: none;
            clip-path: var(--cut-sm);
            flex-shrink: 0;
        }

        .action-button:hover { background: var(--yellow); }
        .action-button:active { background: rgba(252, 178, 73, .70); }

        /* =========================================
           BENACHRICHTIGUNGEN
           ========================================= */
        .notice {
            position: absolute; left: 50%; top: 18px; transform: translateX(-50%) translateY(-8px); z-index: 10;
            min-width: 320px; max-width: 70%; display: flex; align-items: center; gap: 12px;
            padding: 11px 14px 11px 13px; background: var(--panel-strong);
            border: 1px solid var(--line); border-left: 3px solid var(--yellow);
            box-shadow: 0 18px 46px rgba(0,0,0,0.5); opacity: 0; pointer-events: none;
            transition: opacity .18s ease, transform .22s ease;
        }
        .notice.show { opacity: 1; transform: translateX(-50%) translateY(0); }
        .notice svg { width: 22px; height: 22px; flex: 0 0 auto; color: var(--yellow); }
        .noticeTitle { font-family: var(--font-title); font-size: 22px; line-height: 1; color: var(--white); letter-spacing: .06em; }
        .noticeBody { margin-top: 3px; font-size: 11px; font-weight: 600; color: var(--soft); text-transform: uppercase; letter-spacing: .14em; line-height: 1.35; }
        .notice.warn { border-left-color: var(--yellow); } .notice.warn svg { color: var(--yellow); }
        .notice.error { border-left-color: var(--red); } .notice.error svg { color: var(--red); }
        .notice.success { border-left-color: var(--green); } .notice.success svg { color: var(--green); }
        .notice.info { border-left-color: var(--cyan); } .notice.info svg { color: var(--cyan); }

        .pulse { display: inline-block; width: 7px; height: 7px; background: var(--yellow); margin-right: 9px; box-shadow: 0 0 0 0 rgba(252,178,73,0.35); animation: pulse 1.55s infinite; }
        @keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(252,178,73,0.45); } 70% { box-shadow: 0 0 0 7px rgba(252,178,73,0); } 100% { box-shadow: 0 0 0 0 rgba(252,178,73,0); } }
</style>
</head>
<body>
<div id="root" class="phase-1" style="width: 100%; height: 100%; display: flex; justify-content: center; align-items: center;">
  <div class="notice" id="notice"></div>
  <div class="clipboard-panel" id="shell">
    
    <div class="title-section">
      <div class="kicker" id="kicker"></div>
      <h1 id="sysName">__SYSTEM_NAME__</h1>
      <div class="vehicleName" id="vehicleName">__NO_TARGET__</div>
    </div>

    <div class="form-grid">
      <div class="input-group">
        <label><span id="iconIntegrity"></span> __LABEL_INTEGRITY__</label>
        <div class="chipValue" id="chipIntegrity">0%</div>
      </div>
      <div class="input-group">
        <label><span id="iconState"></span> __LABEL_STATUS__</label>
        <div class="chipValue" id="chipState">ACTIVO</div>
      </div>
      <div class="input-group">
        <label><span id="iconPhase"></span> __LABEL_PHASE__</label>
        <div class="chipValue" id="chipPhase">1</div>
      </div>
      <div class="input-group">
        <label><span id="iconAttempts"></span> __LABEL_ATTEMPTS__</label>
        <div class="chipValue" id="chipAttempts">3</div>
      </div>
    </div>

    <div class="input-group full-width">
      <label id="phaseOverline">__REPAIR_PROTOCOL__</label>
      <div class="phaseTitleRow">
        <div class="phaseName" id="phaseName">__PHASE1_TITLE__</div>
        <div class="statusInline" id="statusInline">__PHASE_IN_PROGRESS__</div>
      </div>
      <div id="instruction">__PHASE1_INSTRUCTION__</div>
    </div>

    <div class="signature-container full-width">
      <div style="width:100%; display:flex; justify-content:space-between; align-items: center;">
        <div class="playBadge" id="playBadge"></div>
        <div id="playAssist">__SYNCING_SUBSYSTEM__</div>
      </div>
      <canvas id="playfield" class="signature-pad"></canvas>
    </div>

    <div style="text-align:center; display:flex; align-items:center; justify-content:center; margin-top:-4px; margin-bottom:-1px;" class="full-width">
        <span class="pulse"></span><span id="footerNote">__PROTOCOL_READY__</span>
    </div>
    
    <button class="action-button full-width" id="cancelBtn">__CANCEL_PROTOCOL__</button>
  </div>
</div>

<script>
const Icons = {
  spark: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l1.8 5.2L19 9l-5.2 1.8L12 16l-1.8-5.2L5 9l5.2-1.8L12 2Z"/><path d="M18.5 15.5l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8.8-2.2Z"/></svg>',
  heat: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3c2.2 2 3.5 4.1 3.5 6.7A4.5 4.5 0 0 1 11 14c-2 0-3.7 1.7-3.7 3.8A4.7 4.7 0 0 0 12 22a5 5 0 0 0 5-5c0-3.6-2-5.8-5-8.8Z"/></svg>',
  bolt: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2 5 13h6l-1 9 8-11h-6l1-9Z"/></svg>',
  target: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2.2"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3"/></svg>',
  check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="m5 13 4 4L19 7"/></svg>',
  error: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"><path d="M12 9v4"/><path d="M12 17h.01"/><path d="M10.3 3.8 2.8 17a2 2 0 0 0 1.7 3h15a2 2 0 0 0 1.7-3L13.7 3.8a2 2 0 0 0-3.4 0Z"/></svg>',
  stable: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12h3l2-5 4 10 2-5h5"/></svg>'
};

const LANG = __LANG_JSON__;
const T = (key) => LANG[key] || key;

const root = document.getElementById('root');
const shell = document.getElementById('shell');
const notice = document.getElementById('notice');
const canvas = document.getElementById('playfield');
const ctx = canvas.getContext('2d');

const els = {
  kicker: document.getElementById('kicker'),
  sysName: document.getElementById('sysName'),
  vehicleName: document.getElementById('vehicleName'),
  chipIntegrity: document.getElementById('chipIntegrity'),
  chipState: document.getElementById('chipState'),
  chipPhase: document.getElementById('chipPhase'),
  chipAttempts: document.getElementById('chipAttempts'),
  phaseOverline: document.getElementById('phaseOverline'),
  phaseName: document.getElementById('phaseName'),
  instruction: document.getElementById('instruction'),
  statusInline: document.getElementById('statusInline'),
  playBadge: document.getElementById('playBadge'),
  playAssist: document.getElementById('playAssist'),
  footerNote: document.getElementById('footerNote'),
  cancelBtn: document.getElementById('cancelBtn'),
  iconIntegrity: document.getElementById('iconIntegrity'),
  iconState: document.getElementById('iconState'),
  iconPhase: document.getElementById('iconPhase'),
  iconAttempts: document.getElementById('iconAttempts')
};

els.iconIntegrity.innerHTML = Icons.heat;
els.iconState.innerHTML = Icons.stable;
els.iconPhase.innerHTML = Icons.bolt;
els.iconAttempts.innerHTML = Icons.spark;

const state = {
  sessionId: '',
  systemName: T('system_name'),
  vehicle: { label: T('no_target'), integrity: 0, entIndex: -1 },
  attemptsLeft: 3,
  maxAttempts: 3,
  phase: 1,
  totalPhases: 3,
  phaseName: T('phase1_title'),
  instruction: T('phase1_instruction'),
  phaseData: null,
  status: T('phase_in_progress'),
  footer: T('protocol_ready'),
  assist: T('syncing_subsystem'),
  p1Progress: 1,
  p2Expected: 1,
  p3CurrentIndex: 1,
  p3Lifetime: 1,
  p3ExpireLocal: 0,
  hoverNode: null,
  holdPhase1: false,
  mouse: { x:0, y:0, inside:false },
  lastPhase1Sent: 0,
  blockInput: false,
  transientPulse: 0,
  failFlash: 0,
  successFlash: 0,
  p2DecoySeq: null,
  p2DecoyUntil: 0,
  p2NextDecoyAt: 0
};

const PHASE_META = {
  1: {
    klass:'phase-1',
    overline:T('phase1_overline'),
    title:T('phase1_title'),
    instruction:T('phase1_instruction'),
    badge:T('phase1_badge'),
    assist:T('phase1_assist'),
    footer:T('phase1_footer')
  },
  2: {
    klass:'phase-2',
    overline:T('phase2_overline'),
    title:T('phase2_title'),
    instruction:T('phase2_instruction'),
    badge:T('phase2_badge'),
    assist:T('phase2_assist'),
    footer:T('phase2_footer')
  },
  3: {
    klass:'phase-3',
    overline:T('phase3_overline'),
    title:T('phase3_title'),
    instruction:T('phase3_instruction'),
    badge:T('phase3_badge'),
    assist:T('phase3_assist'),
    footer:T('phase3_footer')
  },
  success: {
    klass:'phase-success',
    overline:T('success_overline'),
    title:T('success_title'),
    instruction:T('success_instruction'),
    badge:T('success_badge'),
    assist:T('success_assist'),
    footer:T('success_footer')
  }
};

function iconMarkup(key) { return Icons[key] || Icons.spark; }

function updateHeader() {
  const integrity = (state.vehicle && state.vehicle.integrity || 0).toFixed(1);
  const phaseNow = state.phase === 'success' ? state.totalPhases : (state.phase || 1);
  const phaseMax = state.totalPhases || 3;
  const attemptsNow = Math.max(0, state.attemptsLeft || 0);
  const attemptsMax = Math.max(attemptsNow, state.maxAttempts || 3);

  els.sysName.textContent = state.systemName || T('system_name');
  els.vehicleName.textContent = (state.vehicle && state.vehicle.label) || T('no_target');
  els.chipIntegrity.textContent = `${integrity}%`;
  els.chipState.textContent = state.vehicle && state.vehicle.integrity >= 100 ? T('chip_status_stable') : T('chip_status_active');
  els.chipPhase.textContent = `${phaseNow}/${phaseMax}`;
  els.chipAttempts.textContent = `${attemptsNow}/${attemptsMax}`;
  const meta = PHASE_META[state.phase] || PHASE_META[1];
  els.phaseName.textContent = meta.title || state.phaseName || T('repair_protocol');
  els.instruction.textContent = meta.instruction || state.instruction || '';
  els.statusInline.textContent = state.status || T('phase_in_progress');
  
  els.phaseOverline.textContent = meta.overline;
  els.playBadge.innerHTML = `${iconMarkup(state.phase === 2 ? 'bolt' : state.phase === 3 ? 'heat' : 'spark')}<span>${meta.badge}</span>`;
  els.playAssist.textContent = meta.assist || state.assist || '';
  els.footerNote.textContent = meta.footer || state.footer || '';
  els.kicker.innerHTML = `${iconMarkup('target')}<span>${T('kicker_protocol')}</span>`;
}

function resizeCanvas() {
  const rect = canvas.getBoundingClientRect();
  const dpr = Math.max(1, window.devicePixelRatio || 1);
  const w = Math.max(1, Math.floor(rect.width * dpr));
  const h = Math.max(1, Math.floor(rect.height * dpr));
  if (canvas.width !== w || canvas.height !== h) {
    canvas.width = w;
    canvas.height = h;
  }
}

function getView() {
  const data = state.phaseData || { areaW: 1040, areaH: 520 };
  const areaW = data.areaW || 1040;
  const areaH = data.areaH || 520;
  const pad = state.phase === 2 ? 4 : 10;
  const zoom = state.phase === 2 ? 1.07 : 1;
  const w = canvas.width;
  const h = canvas.height;
  const baseScale = Math.min((w - pad * 2) / areaW, (h - pad * 2) / areaH);
  const scale = baseScale * zoom;
  const drawW = areaW * scale;
  const drawH = areaH * scale;
  const ox = Math.max(0, (w - drawW) * 0.5);
  const oy = Math.max(0, (h - drawH) * 0.5);
  return { areaW, areaH, scale, ox, oy, drawW, drawH };
}

function phaseToCanvas(x,y) { const v=getView(); return { x:v.ox + x*v.scale, y:v.oy + y*v.scale }; }
function canvasToPhase(ev) {
  const rect = canvas.getBoundingClientRect();
  const rx = (ev.clientX - rect.left) / rect.width;
  const ry = (ev.clientY - rect.top) / rect.height;
  const v = getView();
  const x = (rx * canvas.width - v.ox) / v.scale;
  const y = (ry * canvas.height - v.oy) / v.scale;
  return { x: Math.max(0, Math.min(v.areaW, x)), y: Math.max(0, Math.min(v.areaH, y)) };
}

function push(kind, payload) {
  if (!window.gmod || !window.gmod.event) return;
  payload = Object.assign({ sessionId: state.sessionId }, payload || {});
  window.gmod.event(kind, JSON.stringify(payload));
}

function showNotice(kind, title, body) {
  const icon = kind === 'success' ? 'check' : kind === 'error' ? 'error' : kind === 'info' ? 'bolt' : 'spark';
  notice.className = `notice ${kind}`;
  notice.innerHTML = `${iconMarkup(icon)}<div><div class="noticeTitle">${title}</div><div class="noticeBody">${body}</div></div>`;
  requestAnimationFrame(() => notice.classList.add('show'));
  clearTimeout(showNotice._t);
  showNotice._t = setTimeout(() => notice.classList.remove('show'), kind === 'success' ? 1600 : 1200);
}

function flashShell() {
  shell.classList.remove('shake');
  void shell.offsetWidth;
  shell.classList.add('shake');
  setTimeout(() => shell.classList.remove('shake'), 360);
}

function distance(ax, ay, bx, by) { const dx=ax-bx, dy=ay-by; return Math.sqrt(dx*dx+dy*dy); }

function reasonText(code) {
  const map = {
    phase_fail: T('reason_phase_fail'),
    phase1_hold_lost: T('reason_phase1_hold_lost'),
    phase1_out_of_channel: T('reason_phase1_out_of_channel'),
    phase2_wrong_node: T('reason_phase2_wrong_node'),
    phase3_timeout: T('reason_phase3_timeout'),
    phase3_bad_click: T('reason_phase3_bad_click'),
    target_invalid: T('reason_target_invalid'),
    vehicle_locked: T('reason_vehicle_locked'),
    session_active: T('reason_session_active'),
    user_cancel: T('reason_user_cancel'),
    cancelled: T('reason_cancelled'),
    repair_apply_failed: T('reason_repair_apply_failed'),
    lost_distance: T('reason_lost_distance'),
    weapon_lost: T('reason_weapon_lost'),
    already_repaired: T('reason_already_repaired')
  };
  return map[code] || String(code || T('reason_unknown')).split('_').join(' ');
}

function phase2HasTroll() {
  const data = state.phaseData || {};
  return state.phase === 2 && data && data.trollEnabled === true && data.difficultyId === 'hard';
}

function phase2ResetDecoy(now) {
  const t = now || performance.now();
  state.p2DecoySeq = null;
  state.p2DecoyUntil = 0;
  state.p2NextDecoyAt = t + 420;
}

function phase2UpdateDecoy(now) {
  if (!phase2HasTroll()) {
    state.p2DecoySeq = null;
    state.p2DecoyUntil = 0;
    return;
  }
  const data = state.phaseData || {};
  const nodes = data.nodes || [];
  if (!nodes.length || state.p2Expected > nodes.length) {
    state.p2DecoySeq = null;
    state.p2DecoyUntil = 0;
    return;
  }
  if (state.p2DecoySeq != null && now <= state.p2DecoyUntil) return;
  if (state.p2DecoySeq != null && now > state.p2DecoyUntil) {
    state.p2DecoySeq = null;
    state.p2DecoyUntil = 0;
  }
  if (now < (state.p2NextDecoyAt || 0)) return;

  const chance = Math.max(0, Math.min(1, Number(data.trollChance || 0.55)));
  const minMs = Math.max(220, Number(data.trollMinInterval || 0.95) * 1000);
  const maxMs = Math.max(minMs, Number(data.trollMaxInterval || 1.75) * 1000);
  const durationMs = Math.max(260, Number(data.trollDuration || 0.78) * 1000);
  const jitter = minMs + Math.random() * (maxMs - minMs);

  const candidates = nodes.filter(node => node.seq >= state.p2Expected && node.seq !== state.p2Expected);
  if (!candidates.length) {
    state.p2NextDecoyAt = now + jitter;
    return;
  }
  if (Math.random() > chance) {
    state.p2NextDecoyAt = now + jitter;
    return;
  }

  const pick = candidates[Math.floor(Math.random() * candidates.length)];
  state.p2DecoySeq = pick.seq;
  state.p2DecoyUntil = now + durationMs;
  state.p2NextDecoyAt = now + durationMs + jitter;
}

function drawGrid(view, colorA, colorB) {
  ctx.save();
  ctx.strokeStyle = colorA;
  ctx.lineWidth = 1;
  for (let x = 0; x <= view.areaW; x += 52) {
    const p = phaseToCanvas(x, 0);
    ctx.beginPath(); ctx.moveTo(p.x, view.oy); ctx.lineTo(p.x, view.oy + view.drawH); ctx.stroke();
  }
  for (let y = 0; y <= view.areaH; y += 52) {
    const p = phaseToCanvas(0, y);
    ctx.beginPath(); ctx.moveTo(view.ox, p.y); ctx.lineTo(view.ox + view.drawW, p.y); ctx.stroke();
  }
  ctx.strokeStyle = colorB;
  ctx.strokeRect(view.ox, view.oy, view.drawW, view.drawH);
  ctx.restore();
}

function drawPhase1(t, view) {
  const data = state.phaseData || { points:[] };
  const points = data.points || [];
  drawGrid(view, 'rgba(252,178,73,0.06)', 'rgba(255,255,255,0.04)');
  if (points.length < 2) return;

  const progress = Math.max(1, state.p1Progress || 1);
  ctx.save();
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';

  ctx.shadowBlur = 22;
  ctx.shadowColor = 'rgba(252,178,73,0.22)';
  ctx.strokeStyle = 'rgba(252,178,73,0.20)';
  ctx.lineWidth = Math.max(22, data.maxDeviation * view.scale * 1.08);
  ctx.beginPath();
  points.forEach((pt, i) => { const p = phaseToCanvas(pt.x, pt.y); if (i === 0) ctx.moveTo(p.x, p.y); else ctx.lineTo(p.x, p.y); });
  ctx.stroke();

  ctx.shadowBlur = 14;
  ctx.shadowColor = 'rgba(244,241,233,0.14)';
  ctx.strokeStyle = 'rgba(244,241,233,0.28)';
  ctx.lineWidth = Math.max(10, data.safeRadius * view.scale * 0.9);
  ctx.beginPath();
  points.forEach((pt, i) => { const p = phaseToCanvas(pt.x, pt.y); if (i === 0) ctx.moveTo(p.x, p.y); else ctx.lineTo(p.x, p.y); });
  ctx.stroke();

  ctx.shadowBlur = 18;
  ctx.shadowColor = 'rgba(252,178,73,0.48)';
  ctx.strokeStyle = 'rgba(252,178,73,0.95)';
  ctx.lineWidth = 4;
  ctx.beginPath();
  points.forEach((pt, i) => { const p = phaseToCanvas(pt.x, pt.y); if (i === 0) ctx.moveTo(p.x, p.y); else ctx.lineTo(p.x, p.y); });
  ctx.stroke();

  points.forEach((pt, i) => {
    const p = phaseToCanvas(pt.x, pt.y);
    const done = i < progress;
    const active = i === progress;
    const r = active ? 11 + Math.sin(t * 0.006) * 1.7 : 8;
    ctx.shadowBlur = active ? 18 : 10;
    ctx.shadowColor = active ? 'rgba(74,203,130,0.55)' : done ? 'rgba(252,178,73,0.45)' : 'rgba(255,255,255,0.12)';
    ctx.fillStyle = done ? 'rgba(74,203,130,0.95)' : active ? 'rgba(244,241,233,0.95)' : 'rgba(252,178,73,0.82)';
    ctx.beginPath(); ctx.arc(p.x, p.y, r, 0, Math.PI * 2); ctx.fill();
    ctx.lineWidth = 2;
    ctx.strokeStyle = done ? 'rgba(255,255,255,0.20)' : 'rgba(255,255,255,0.08)';
    ctx.stroke();
  });

  if (state.mouse.inside) {
    const mp = phaseToCanvas(state.mouse.x, state.mouse.y);
    ctx.shadowBlur = 14;
    ctx.shadowColor = state.holdPhase1 ? 'rgba(252,178,73,0.55)' : 'rgba(80,200,220,0.25)';
    ctx.strokeStyle = state.holdPhase1 ? 'rgba(244,241,233,0.95)' : 'rgba(80,200,220,0.72)';
    ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(mp.x, mp.y, 10 + Math.sin(t * 0.015) * 1.5, 0, Math.PI * 2); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(mp.x - 12, mp.y); ctx.lineTo(mp.x + 12, mp.y); ctx.moveTo(mp.x, mp.y - 12); ctx.lineTo(mp.x, mp.y + 12); ctx.stroke();
  }
  ctx.restore();
}

function drawPhase2(t, view) {
  const data = state.phaseData || { nodes:[], radius:42 };
  const nodes = data.nodes || [];
  const now = performance.now();
  phase2UpdateDecoy(now);
  const decoySeq = state.p2DecoySeq != null && now <= state.p2DecoyUntil ? state.p2DecoySeq : null;
  drawGrid(view, 'rgba(80,200,220,0.055)', 'rgba(255,255,255,0.04)');

  ctx.save();
  ctx.strokeStyle = 'rgba(255,255,255,0.06)';
  ctx.lineWidth = 2;
  nodes.slice().sort((a,b)=>a.seq-b.seq).forEach((node, idx, arr) => {
    if (idx >= arr.length - 1) return;
    const p1 = phaseToCanvas(node.x, node.y);
    const p2 = phaseToCanvas(arr[idx+1].x, arr[idx+1].y);
    ctx.beginPath(); ctx.moveTo(p1.x, p1.y); ctx.lineTo(p2.x, p2.y); ctx.stroke();
  });

  nodes.forEach(node => {
    const p = phaseToCanvas(node.x, node.y);
    const r = (data.radius || 42) * view.scale;
    const done = node.seq < state.p2Expected;
    const active = node.seq === state.p2Expected;
    const decoy = decoySeq === node.seq;
    const hover = state.hoverNode === node.seq;
    const showTrueGuide = active && !decoySeq;
    const pulse = (showTrueGuide || decoy) ? (Math.sin(t * 0.008) * 0.08 + 0.92) : 1;
    const rr = r * pulse;

    let fill = 'rgba(255,255,255,0.08)';
    let stroke = 'rgba(255,255,255,0.12)';
    let glow = 'rgba(255,255,255,0.00)';
    if (done) {
      fill = 'rgba(74,203,130,0.18)';
      stroke = 'rgba(74,203,130,0.92)';
      glow = 'rgba(74,203,130,0.42)';
    } else if (decoy) {
      fill = 'rgba(80,200,220,0.14)';
      stroke = 'rgba(80,200,220,0.96)';
      glow = hover ? 'rgba(252,178,73,0.46)' : 'rgba(80,200,220,0.42)';
    } else if (showTrueGuide) {
      fill = 'rgba(252,178,73,0.16)';
      stroke = 'rgba(252,178,73,0.95)';
      glow = hover ? 'rgba(80,200,220,0.44)' : 'rgba(252,178,73,0.38)';
    } else if (hover) {
      fill = 'rgba(80,200,220,0.10)';
      stroke = 'rgba(80,200,220,0.82)';
      glow = 'rgba(80,200,220,0.25)';
    }

    ctx.shadowBlur = 24;
    ctx.shadowColor = glow;
    ctx.fillStyle = fill;
    ctx.beginPath(); ctx.arc(p.x, p.y, rr, 0, Math.PI * 2); ctx.fill();
    ctx.lineWidth = 2;
    ctx.strokeStyle = stroke;
    ctx.stroke();

    if (decoy) {
      ctx.shadowBlur = 16;
      ctx.strokeStyle = 'rgba(244,241,233,0.22)';
      ctx.lineWidth = 1.5;
      ctx.setLineDash([5, 5]);
      ctx.beginPath(); ctx.arc(p.x, p.y, rr + 8, 0, Math.PI * 2); ctx.stroke();
      ctx.setLineDash([]);
    }

    ctx.shadowBlur = 0;
    ctx.fillStyle = done ? 'rgba(244,241,233,0.96)' : (showTrueGuide || decoy) ? 'rgba(244,241,233,0.96)' : 'rgba(244,241,233,0.84)';
    ctx.font = `${Math.max(18, rr * 0.68)}px 'Bebas Neue', sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(String(node.seq), p.x, p.y + 1);
  });
  ctx.restore();
}

function drawPhase3(t, view) {
  const data = state.phaseData || { points:[], radius:40, pointLifetime:1 };
  const points = data.points || [];
  drawGrid(view, 'rgba(255,210,108,0.05)', 'rgba(255,255,255,0.04)');

  const idx = Math.max(1, state.p3CurrentIndex || 1);
  const life = Math.max(0.05, state.p3Lifetime || data.pointLifetime || 1);
  const remain = Math.max(0, state.p3ExpireLocal - performance.now());
  const frac = Math.max(0, Math.min(1, remain / (life * 1000)));

  ctx.save();
  points.forEach((pt, i) => {
    const n = i + 1;
    const p = phaseToCanvas(pt.x, pt.y);
    if (n < idx) {
      ctx.shadowBlur = 12;
      ctx.shadowColor = 'rgba(252,178,73,0.38)';
      ctx.fillStyle = 'rgba(252,178,73,0.40)';
      ctx.beginPath(); ctx.arc(p.x, p.y, 9, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = 'rgba(244,241,233,0.35)';
      ctx.lineWidth = 2; ctx.stroke();
      return;
    }
    if (n > idx) return;

    const base = (data.radius || 40) * view.scale;
    const shrink = Math.max(base * 0.38, base * frac);
    const urgency = 1 - frac;
    ctx.shadowBlur = 24 + urgency * 18;
    ctx.shadowColor = frac > 0.35 ? 'rgba(252,178,73,0.55)' : 'rgba(225,88,88,0.60)';
    ctx.fillStyle = frac > 0.35 ? 'rgba(252,178,73,0.20)' : 'rgba(225,88,88,0.22)';
    ctx.beginPath(); ctx.arc(p.x, p.y, base, 0, Math.PI * 2); ctx.fill();

    ctx.lineWidth = 3;
    ctx.strokeStyle = frac > 0.35 ? 'rgba(252,178,73,0.95)' : 'rgba(225,88,88,0.95)';
    ctx.beginPath(); ctx.arc(p.x, p.y, shrink, 0, Math.PI * 2); ctx.stroke();

    ctx.shadowBlur = 14;
    ctx.fillStyle = 'rgba(244,241,233,0.94)';
    ctx.beginPath(); ctx.arc(p.x, p.y, Math.max(8, shrink * 0.28 + Math.sin(t * 0.015) * 1.2), 0, Math.PI * 2); ctx.fill();
  });
  ctx.restore();
}

function renderFrame(t) {
  resizeCanvas();
  const v = getView();
  
  /* Clears the canvas instead of filling it to allow the .signature-pad css background to shine through! */
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  if (state.phase === 1) drawPhase1(t, v);
  else if (state.phase === 2) drawPhase2(t, v);
  else if (state.phase === 3) drawPhase3(t, v);

  if (state.failFlash > 0.01) {
    ctx.fillStyle = `rgba(225,88,88,${0.18 * state.failFlash})`;
    ctx.fillRect(0,0,canvas.width,canvas.height);
    state.failFlash *= 0.92;
  }
  if (state.successFlash > 0.01) {
    ctx.fillStyle = `rgba(74,203,130,${0.16 * state.successFlash})`;
    ctx.fillRect(0,0,canvas.width,canvas.height);
    state.successFlash *= 0.93;
  }
  requestAnimationFrame(renderFrame);
}

function updateFromPhase(payload) {
  state.phase = payload.phase || 1;
  state.totalPhases = payload.totalPhases || state.totalPhases || 3;
  state.phaseName = payload.phaseName || state.phaseName;
  state.instruction = payload.instruction || state.instruction;
  state.phaseData = payload.data || null;
  state.attemptsLeft = payload.attemptsLeft != null ? payload.attemptsLeft : state.attemptsLeft;
  state.maxAttempts = payload.maxAttempts || state.maxAttempts || state.attemptsLeft || 3;
  state.vehicle = payload.vehicle || state.vehicle;
  state.status = T('phase_in_progress');
  const meta = PHASE_META[state.phase] || PHASE_META[1];
  state.assist = meta.assist;
  state.footer = meta.footer;
  state.p1Progress = 1;
  state.p2Expected = 1;
  state.p3CurrentIndex = payload.data && payload.data.currentIndex || 1;
  state.p3Lifetime = payload.data && payload.data.pointLifetime || 1;
  state.p3ExpireLocal = performance.now() + state.p3Lifetime * 1000;
  state.blockInput = false;
  state.holdPhase1 = false;
  phase2ResetDecoy();
  if (state.phase === 2) {
    const lockMs = Math.max(0, Number((payload.data && payload.data.inputLock) || 0.28)) * 1000;
    state.p2InputUnlockAt = performance.now() + lockMs;
    state.p2NeedsRelease = true;
    state.p2LastClickAt = 0;
  } else {
    state.p2InputUnlockAt = 0;
    state.p2NeedsRelease = false;
    state.p2LastClickAt = 0;
  }
  updateHeader();
  requestAnimationFrame(resizeCanvas);
}

window.FCRReceive = function(payload) {
  if (!payload) return;
  if (payload.type === 'open') {
    state.sessionId = payload.sessionId || '';
    state.systemName = payload.systemName || state.systemName;
    state.attemptsLeft = payload.attemptsLeft != null ? payload.attemptsLeft : state.attemptsLeft;
    state.maxAttempts = payload.maxAttempts || state.maxAttempts || state.attemptsLeft || 3;
    state.totalPhases = payload.totalPhases || state.totalPhases || 3;
    state.vehicle = payload.vehicle || state.vehicle;
    state.blockInput = false;
    updateHeader();
    return;
  }
  if (payload.type === 'phase') { updateFromPhase(payload); return; }
  if (payload.type === 'phase1_progress') { state.p1Progress = payload.progress || state.p1Progress; return; }
  if (payload.type === 'phase2_progress') { state.p2Expected = payload.expected || state.p2Expected; phase2ResetDecoy(); return; }
  if (payload.type === 'phase3_progress') { state.p3CurrentIndex = payload.currentIndex || state.p3CurrentIndex; state.p3Lifetime = payload.pointLifetime || state.p3Lifetime; state.p3ExpireLocal = performance.now() + state.p3Lifetime * 1000; return; }
  if (payload.type === 'phase_fail') {
    state.attemptsLeft = payload.attemptsLeft != null ? payload.attemptsLeft : state.attemptsLeft;
    state.vehicle = payload.vehicle || state.vehicle;
    state.status = T('status_tactical_reset');
    state.holdPhase1 = false;
    updateHeader();
    state.failFlash = 1;
    flashShell();
    showNotice('error', T('notice_protocol_failed'), reasonText(payload.reason || 'phase_fail'));
    return;
  }
  if (payload.type === 'phase_complete') {
    state.attemptsLeft = payload.attemptsLeft != null ? payload.attemptsLeft : state.attemptsLeft;
    state.status = T('status_phase_transition');
    state.holdPhase1 = false;
    state.blockInput = true;
    state.hoverNode = null;
    updateHeader();
    state.successFlash = 1;
    showNotice('info', T('notice_phase_completed'), T('notice_loading_next'));
    return;
  }
  if (payload.type === 'success') {
    state.phase = 'success';
    state.vehicle = payload.vehicle || state.vehicle;
    state.status = T('status_repair_completed');
    state.footer = PHASE_META.success.footer;
    updateHeader();
    state.successFlash = 1;
    state.blockInput = true;
    state.holdPhase1 = false;
    showNotice('success', T('notice_repair_completed'), T('notice_integrity_restored'));
    return;
  }
  if (payload.type === 'cancelled') {
    state.blockInput = true;
    state.holdPhase1 = false;
    state.attemptsLeft = payload.attemptsLeft != null ? payload.attemptsLeft : state.attemptsLeft;
    state.vehicle = payload.vehicle || state.vehicle;
    updateHeader();
    showNotice('warn', T('notice_protocol_cancelled'), reasonText(payload.reason || 'cancelled'));
  }
};

canvas.addEventListener('mousemove', (ev) => {
  const p = canvasToPhase(ev);
  state.mouse = { x:p.x, y:p.y, inside:true };
  if (state.phase === 2 && state.phaseData && state.phaseData.nodes) {
    state.hoverNode = null;
    const radius = (state.phaseData.radius || 42) * 1.08;
    for (const node of state.phaseData.nodes) {
      if (distance(p.x, p.y, node.x, node.y) <= radius) { state.hoverNode = node.seq; break; }
    }
  }

  if (state.phase === 1 && state.holdPhase1 && !state.blockInput) {
    const now = performance.now();
    if (now - state.lastPhase1Sent >= 46) {
      state.lastPhase1Sent = now;
      push('phase1_sample', { x:p.x, y:p.y, hold:true });
    }
  }
});
canvas.addEventListener('mouseenter', () => { state.mouse.inside = true; });
canvas.addEventListener('mouseleave', () => {
  state.mouse.inside = false;
  state.hoverNode = null;
  if (state.phase === 1 && state.holdPhase1 && !state.blockInput) {
    state.holdPhase1 = false;
    push('phase1_release', {});
  }
});
canvas.addEventListener('mousedown', (ev) => {
  if (state.blockInput) return;
  if (state.phase === 1) {
    state.holdPhase1 = true;
    const p = canvasToPhase(ev);
    state.lastPhase1Sent = 0;
    push('phase1_sample', { x:p.x, y:p.y, hold:true });
  }
});
window.addEventListener('mouseup', () => {
  if (state.phase === 1 && state.holdPhase1 && !state.blockInput) {
    state.holdPhase1 = false;
    push('phase1_release', {});
  }
  if (state.phase === 2) {
    state.p2NeedsRelease = false;
  }
});
canvas.addEventListener('click', (ev) => {
  if (state.blockInput) return;
  const p = canvasToPhase(ev);
  if (state.phase === 2 && state.phaseData && state.phaseData.nodes) {
    const now = performance.now();
    if (now < (state.p2InputUnlockAt || 0)) return;
    if (state.p2NeedsRelease) return;
    if (now - (state.p2LastClickAt || 0) < 95) return;
    const radius = (state.phaseData.radius || 42) * 1.02;
    for (const node of state.phaseData.nodes) {
      if (distance(p.x, p.y, node.x, node.y) <= radius) {
        state.p2LastClickAt = now;
        push('phase2_click', { seq:node.seq });
        return;
      }
    }
  }
  if (state.phase === 3 && state.phaseData && state.phaseData.points) {
    const idx = state.p3CurrentIndex || 1;
    const point = state.phaseData.points[idx - 1];
    if (!point) return;
    if (distance(p.x, p.y, point.x, point.y) <= (state.phaseData.radius || 40) * 1.08) {
      push('phase3_click', { index:idx, x:p.x, y:p.y });
    }
  }
});

els.cancelBtn.addEventListener('click', () => push('cancel', {}));
window.addEventListener('resize', resizeCanvas);
updateHeader();
requestAnimationFrame(renderFrame);
</script>
</body>
</html>]====]

local function gsubValue(html, token, value)
    value = tostring(value or "")
    value = value:gsub("%%", "%%%%")
    return html:gsub(token, value)
end

local function buildPanelHTML()
    local html = PANEL_HTML_TEMPLATE
    local lang = FCR.GetLanguageBundle and FCR.GetLanguageBundle() or {}
    local replacements = {
        __LANG_JSON__ = util.TableToJSON(lang, false, true) or "{}",
        __SYSTEM_NAME__ = FCR.L("system_name"),
        __NO_TARGET__ = FCR.L("no_target"),
        __LABEL_INTEGRITY__ = FCR.L("label_integrity"),
        __LABEL_STATUS__ = FCR.L("label_status"),
        __LABEL_PHASE__ = FCR.L("label_phase"),
        __LABEL_ATTEMPTS__ = FCR.L("label_attempts"),
        __REPAIR_PROTOCOL__ = FCR.L("repair_protocol"),
        __PHASE1_TITLE__ = FCR.L("phase1_title"),
        __PHASE_IN_PROGRESS__ = FCR.L("phase_in_progress"),
        __PHASE1_INSTRUCTION__ = FCR.L("phase1_instruction"),
        __SYNCING_SUBSYSTEM__ = FCR.L("syncing_subsystem"),
        __PROTOCOL_READY__ = FCR.L("protocol_ready"),
        __CANCEL_PROTOCOL__ = FCR.L("cancel_protocol")
    }

    for token, value in pairs(replacements) do
        html = gsubValue(html, token, value)
    end

    return html
end


local function updateRuntimeFromPayload(payload)
    Runtime.ActiveSession = Runtime.ActiveSession or {}
    if payload and payload.vehicle then
        Runtime.ActiveSession.vehicle = payload.vehicle
    end
    if payload and payload.attemptsLeft ~= nil then
        Runtime.ActiveSession.attemptsLeft = payload.attemptsLeft
    end
    if payload and payload.phase ~= nil then
        Runtime.ActiveSession.phase = payload.phase
    end
end

local function clearRuntime()
    Runtime.ActiveSession = nil
end

local function getPhase1TickSound()
    local sounds = FCR.Config and FCR.Config.Sounds
    return sounds and sounds.Phase1Tick or "buttons/blip1.wav"
end

local function playLocalUISound(path)
    if not path or path == "" then return end
    surface.PlaySound(path)
end

local function jsPush(html, payload)
    if not IsValid(html) then return end
    local json = util.TableToJSON(payload or {}, false, true) or "{}"
    html:QueueJavascript("window.FCRReceive(" .. json .. ");")
end

local function flushPending()
    if not UI.Ready or not IsValid(UI.HTML) then return end
    for _, payload in ipairs(UI.Pending or {}) do
        jsPush(UI.HTML, payload)
    end
    UI.Pending = {}
end

local function removePanel()
    if IsValid(UI.Frame) then
        UI.Frame:Remove()
    end
    UI.Frame = nil
    UI.Holder = nil
    UI.HTML = nil
    UI.Ready = false
    UI.Pending = {}
    gui.EnableScreenClicker(false)
end

local function centeredSize()
    local panelCfg = (FCR.Config and FCR.Config.Panel) or {}
    local maxW = math.max(760, ScrW() - 36)
    local maxH = math.max(560, ScrH() - 36)
    local w = math.min(maxW, panelCfg.MaxWidth or 1380, math.floor(ScrW() * (panelCfg.WidthFrac or 0.84)))
    local h = math.min(maxH, panelCfg.MaxHeight or 860, math.floor(ScrH() * (panelCfg.HeightFrac or 0.82)))
    return w, h
end

local function placeHolder(frame, holder)
    if not IsValid(frame) or not IsValid(holder) then return end
    holder:Center()
    local x, y = holder:GetPos()
    local panelCfg = (FCR.Config and FCR.Config.Panel) or {}
    local biasX = math.floor(tonumber(panelCfg.CenterBiasX or 0) or 0)
    local biasY = math.floor(tonumber(panelCfg.CenterBiasY or 0) or 0)
    holder:SetPos(math.max(0, x + biasX), math.max(0, y + biasY))
end

local function createPanel(openPayload)
    removePanel()

    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame._blurStart = SysTime()
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame:SetMouseInputEnabled(true)
    frame.Paint = function(self, w, h)
        Derma_DrawBackgroundBlur(self, self._blurStart or SysTime())
    end
    frame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then
            net.Start("fcr_input")
                net.WriteString("cancel")
                net.WriteString(util.TableToJSON({ sessionId = openPayload and openPayload.sessionId or "" }, false, true) or "{}")
            net.SendToServer()
        end
    end

    local holder = vgui.Create("EditablePanel", frame)
    local w, h = centeredSize()
    holder:SetSize(w, h)
    placeHolder(frame, holder)
    timer.Simple(0, function()
        if IsValid(frame) and IsValid(holder) then
            placeHolder(frame, holder)
        end
    end)
    holder.Paint = nil

    local html = vgui.Create("DHTML", holder)
    html:Dock(FILL)
    local page = buildPanelHTML()
    html:SetHTML(SYMUI and SYMUI.ThemeHTML(page) or page)

    function frame:OnSizeChanged()
        if not IsValid(holder) then return end
        local nw, nh = centeredSize()
        holder:SetSize(nw, nh)
        placeHolder(frame, holder)
    end

    function html:OnDocumentReady()
        UI.Ready = true
        flushPending()
        timer.Simple(0, function()
            if IsValid(html) then
                html:QueueJavascript("requestAnimationFrame(function(){ window.dispatchEvent(new Event(\"resize\")); });")
            end
        end)
    end

    html:AddFunction("gmod", "event", function(kind, payloadJson)
        net.Start("fcr_input")
            net.WriteString(kind or "")
            net.WriteString(payloadJson or "{}")
        net.SendToServer()
    end)

    UI.Frame = frame
    UI.Holder = holder
    UI.HTML = html
    UI.Pending = { table.Merge({ type = "open" }, openPayload or {}) }

    gui.EnableScreenClicker(true)
end

net.Receive("fcr_open", function()
    local payload = util.JSONToTable(net.ReadString() or "{}") or {}
    updateRuntimeFromPayload(payload)
    createPanel(payload)
end)

net.Receive("fcr_event", function()
    local eventName = net.ReadString()
    local payload = util.JSONToTable(net.ReadString() or "{}") or {}
    payload.type = eventName

    if eventName == "phase" or eventName == "phase_fail" or eventName == "phase_complete" or eventName == "cancelled" or eventName == "success" then
        updateRuntimeFromPayload(payload)
    end

    if eventName == "phase1_progress" then
        playLocalUISound(getPhase1TickSound())
    end

    if eventName == "cancelled" or eventName == "success" then
        if IsValid(UI.HTML) and UI.Ready then
            jsPush(UI.HTML, payload)
        else
            UI.Pending[#UI.Pending + 1] = payload
        end
        timer.Simple(1.0, function()
            removePanel()
            clearRuntime()
        end)
        return
    end

    if not IsValid(UI.HTML) or not UI.Ready then
        UI.Pending[#UI.Pending + 1] = payload
        return
    end

    jsPush(UI.HTML, payload)
end)