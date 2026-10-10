GRN_Bombs = GRN_Bombs or {}

local MG

local MINI_I18N = {
    en = {
        wire_title = 'CRITICAL ENERGY UNIT',
        wire_status = 'Network Status',
        wire_sync = 'Synchronization',
        wire_time = 'Time Left',
        wire_scanning = 'SCANNING...',
        wire_stable = 'STABLE',
        wire_bypass = 'BYPASS OK',
        wire_locked = 'SYSTEM LOCKED',
        wire_access = '> ACCESS GRANTED',
        wire_error_short = '> ERROR: SHORT CIRCUIT DETECTED',
        wire_error_time = '> ERROR: TIME WINDOW EXPIRED',
        wire_hint_on = 'Cut the wires in ascending numeric order. The next correct wire will glow.',
        wire_hint_off = 'Cut the wires in ascending numeric order. No automated hints available.',
        wire_reset = 'Reconfigure Fuses',
        wire_abort = 'Abort',
        code_system = 'GRN SYSTEM',
        code_waiting = 'AWAITING INPUT...',
        code_inputting = 'INPUTTING...',
        code_denied = 'ACCESS DENIED - INVALID CODE',
        code_deactivated = 'DEACTIVATED',
        code_defused = 'BOMB DEFUSED',
        code_defused_msg = 'Security protocols successfully bypassed.',
        code_failed = 'MISSION FAILED',
        code_time = 'TIME EXPIRED - DETONATION',
        code_hint_default = 'ENTER ACCESS CODE',
        code_clear = 'CLR',
        code_enter = 'ENT',
        seq_title = 'GALAXY REPUBLIC NETWORK // SECURITY BYPASS',
        seq_wait = 'WAITING TO START...',
        seq_watch = 'WATCH THE SEQUENCE',
        seq_repeat = 'REPEAT THE SEQUENCE',
        seq_correct = 'CORRECT!',
        seq_fail = 'SYSTEM FAILURE',
        seq_round = 'Current Round',
        seq_start = 'START SEQUENCE',
        seq_retry = 'RETRY',
        seq_footer_status = 'STATUS: STANDBY',
        seq_footer_uid = 'UID: 0x884-BOMB',
        seq_close = '×',
        hack_server = 'TACTICAL ENCRYPTION SYSTEM',
        hack_bomb_state = 'BOMB',
        hack_active = 'ACTIVE',
        hack_locked = 'SYSTEM LOCKED',
        hack_subtitle = 'Manual 2-stage bypass required',
        hack_start = 'START HACK',
        hack_stage1 = 'STAGE 1: ACCESS SEQUENCE',
        hack_stage2 = 'STAGE 2: VOLTAGE SYNC',
        hack_security = 'Security',
        hack_attempts = 'Attempts',
        hack_logs = 'System logs',
        hack_waiting = 'Waiting for input...',
        hack_firewall = 'Firewall detected...',
        hack_stage1_log = 'Stage 1: Decoding keypad...',
        hack_stage2_log = 'Stage 2: Synchronizing cores...',
        hack_access = 'Keypad: ACCESS GRANTED',
        hack_error_code = 'ERROR: Invalid code',
        hack_syncing = 'SYNCING: %s%%',
        hack_out_of_range = 'OUT OF RANGE',
        hack_success = 'BOMB DEFUSED',
        hack_success_log = 'SYSTEM FULLY UNLOCKED',
        hack_fail = 'IMMINENT DETONATION',
        hack_fail_log = 'CRITICAL ERROR: SECURITY FAILURE',
        hack_restart = 'RESTART',
        hack_retry = 'RETRY',
        hack_hold_zone = 'KEEP THE MARKER INSIDE THE GREEN ZONE',
        timer_title = 'GRN // SECURITY SYSTEM',
        timer_status = 'STABILIZING CORE...',
        timer_stage = 'STAGE',
        timer_press = 'DISARM [SPACE]',
        timer_secure = 'SYSTEM SECURED',
        timer_secure_desc = 'Disarm protocol completed.',
        timer_boom = 'BOOM!',
        timer_timeout = 'TIME EXPIRED',
        timer_sync_error = 'SYNC ERROR',
        timer_retry = 'RETRY',
        lock_title = 'GRN SYSTEM',
        lock_subtitle = 'Security Disarm',
        lock_time = 'Time Left',
        lock_points = 'Pressure Points',
        lock_hint = 'PRESS SPACE WHEN THE INDICATOR PASSES THE GOLDEN ZONE',
        lock_compromised = 'SYSTEM COMPROMISED',
        lock_fail = 'FAIL',
        btn_title = 'GRN SECURITY',
        btn_module = 'MODULE',
        btn_hint = 'PRESS THE BUTTONS IN ASCENDING ORDER',
        btn_attempts = 'ATTEMPTS',
        btn_access = 'SYSTEM UNLOCKED',
        btn_fail = 'CRITICAL FAILURE / DETONATION',
        btn_restart = 'RESTART',
    },
    es = {
        wire_title = 'UNIDAD DE ENERGÍA CRÍTICA',
        wire_status = 'Estado de Red',
        wire_sync = 'Sincronización',
        wire_time = 'Tiempo Restante',
        wire_scanning = 'ESCANEO...',
        wire_stable = 'ESTABLE',
        wire_bypass = 'BYPASS OK',
        wire_locked = 'SISTEMA BLOQUEADO',
        wire_access = '> ACCESO CONCEDIDO',
        wire_error_short = '> ERROR: CORTOCIRCUITO DETECTADO',
        wire_error_time = '> ERROR: TIEMPO AGOTADO',
        wire_hint_on = 'Corta los cables en orden numérico ascendente. El siguiente cable correcto brillará.',
        wire_hint_off = 'Corta los cables en orden numérico ascendente. No hay pistas automáticas.',
        wire_reset = 'Reconfigurar Fusibles',
        wire_abort = 'Abortar',
        code_system = 'SISTEMA GRN',
        code_waiting = 'ESPERANDO ENTRADA...',
        code_inputting = 'INGRESANDO...',
        code_denied = 'ACCESO DENEGADO - CÓDIGO INVÁLIDO',
        code_deactivated = 'DESACTIVADA',
        code_defused = 'BOMBA DESACTIVADA',
        code_defused_msg = 'Protocolos de seguridad eludidos correctamente.',
        code_failed = 'MISIÓN FALLIDA',
        code_time = 'TIEMPO AGOTADO - DETONACIÓN',
        code_hint_default = 'INGRESA EL CÓDIGO',
        code_clear = 'CLR',
        code_enter = 'ENT',
        seq_title = 'GALAXY REPUBLIC NETWORK // EVASIÓN DE SEGURIDAD',
        seq_wait = 'ESPERANDO INICIO...',
        seq_watch = 'OBSERVA LA SECUENCIA',
        seq_repeat = 'REPITE LA SECUENCIA',
        seq_correct = '¡CORRECTO!',
        seq_fail = 'FALLO EN EL SISTEMA',
        seq_round = 'Ronda actual',
        seq_start = 'INICIAR SECUENCIA',
        seq_retry = 'REINTENTAR',
        seq_footer_status = 'ESTADO: STANDBY',
        seq_footer_uid = 'UID: 0x884-BOMB',
        seq_close = '×',
        hack_server = 'SISTEMA DE ENCRIPTACIÓN TÁCTICA',
        hack_bomb_state = 'BOMBA',
        hack_active = 'ACTIVA',
        hack_locked = 'SISTEMA BLOQUEADO',
        hack_subtitle = 'Se requiere bypass manual de 2 etapas',
        hack_start = 'INICIAR HACKEO',
        hack_stage1 = 'ETAPA 1: SECUENCIA DE ACCESO',
        hack_stage2 = 'ETAPA 2: SINCRONIZACIÓN DE VOLTAJE',
        hack_security = 'Seguridad',
        hack_attempts = 'Intentos',
        hack_logs = 'Registros del sistema',
        hack_waiting = 'Esperando entrada...',
        hack_firewall = 'Firewall detectado...',
        hack_stage1_log = 'Etapa 1: Descifrando keypad...',
        hack_stage2_log = 'Etapa 2: Sincronizando núcleos...',
        hack_access = 'Keypad: ACCESO CONCEDIDO',
        hack_error_code = 'ERROR: Código incorrecto',
        hack_syncing = 'SINCRONIZANDO: %s%%',
        hack_out_of_range = 'FUERA DE RANGO',
        hack_success = 'BOMBA DESACTIVADA',
        hack_success_log = 'SISTEMA TOTALMENTE DESBLOQUEADO',
        hack_fail = 'DETONACIÓN INMINENTE',
        hack_fail_log = 'ERROR CRÍTICO: FALLO DE SEGURIDAD',
        hack_restart = 'REINICIAR',
        hack_retry = 'REINTENTAR',
        hack_hold_zone = 'MANTÉN EL MARCADOR EN LA ZONA VERDE',
        timer_title = 'GRN // SISTEMA DE SEGURIDAD',
        timer_status = 'ESTABILIZANDO NÚCLEO...',
        timer_stage = 'ETAPA',
        timer_press = 'DESACTIVAR [ESPACIO]',
        timer_secure = 'SISTEMA SEGURO',
        timer_secure_desc = 'Protocolo de desactivación completado.',
        timer_boom = '¡BOOM!',
        timer_timeout = 'TIEMPO AGOTADO',
        timer_sync_error = 'ERROR DE SINCRONIZACIÓN',
        timer_retry = 'REINTENTAR',
        lock_title = 'GRN SYSTEM',
        lock_subtitle = 'Desactivación de Seguridad',
        lock_time = 'Tiempo Restante',
        lock_points = 'Puntos de Presión',
        lock_hint = 'PRESIONA ESPACIO CUANDO EL INDICADOR PASE POR LA ZONA DORADA',
        lock_compromised = 'SISTEMA COMPROMETIDO',
        lock_fail = 'FALLO',
        btn_title = 'GRN SECURITY',
        btn_module = 'MÓDULO',
        btn_hint = 'PRESIONA LOS BOTONES EN ORDEN ASCENDENTE',
        btn_attempts = 'INTENTOS',
        btn_access = 'SISTEMA DESBLOQUEADO',
        btn_fail = 'FALLO CRÍTICO / DETONACIÓN',
        btn_restart = 'REINICIAR',
    },
    fr = {
        wire_title = 'UNITÉ D\'ÉNERGIE CRITIQUE',
        wire_status = 'État du Réseau',
        wire_sync = 'Synchronisation',
        wire_time = 'Temps Restant',
        wire_scanning = 'SCAN...',
        wire_stable = 'STABLE',
        wire_bypass = 'BYPASS OK',
        wire_locked = 'SYSTÈME BLOQUÉ',
        wire_access = '> ACCÈS AUTORISÉ',
        wire_error_short = '> ERREUR: COURT-CIRCUIT DÉTECTÉ',
        wire_error_time = '> ERREUR: TEMPS ÉCOULÉ',
        wire_hint_on = 'Coupez les câbles dans l\'ordre numérique croissant. Le prochain câble correct brillera.',
        wire_hint_off = 'Coupez les câbles dans l\'ordre numérique croissant. Aucune aide automatique disponible.',
        wire_reset = 'Reconfigurer Fusibles',
        wire_abort = 'Annuler',
        code_system = 'SYSTÈME GRN',
        code_waiting = 'EN ATTENTE DE SAISIE...',
        code_inputting = 'SAISIE...',
        code_denied = 'ACCÈS REFUSÉ - CODE INVALIDE',
        code_deactivated = 'DÉSACTIVÉE',
        code_defused = 'BOMBE DÉSAMORCÉE',
        code_defused_msg = 'Protocoles de sécurité contournés avec succès.',
        code_failed = 'MISSION ÉCHOUÉE',
        code_time = 'TEMPS ÉCOULÉ - DÉTONATION',
        code_hint_default = 'ENTREZ LE CODE',
        code_clear = 'CLR',
        code_enter = 'ENT',
        seq_title = 'GALAXY REPUBLIC NETWORK // CONTOURNEMENT DE SÉCURITÉ',
        seq_wait = 'EN ATTENTE DU DÉMARRAGE...',
        seq_watch = 'OBSERVEZ LA SÉQUENCE',
        seq_repeat = 'RÉPÉTEZ LA SÉQUENCE',
        seq_correct = 'CORRECT !',
        seq_fail = 'ÉCHEC DU SYSTÈME',
        seq_round = 'Manche actuelle',
        seq_start = 'DÉMARRER LA SÉQUENCE',
        seq_retry = 'RÉESSAYER',
        seq_footer_status = 'STATUT : VEILLE',
        seq_footer_uid = 'UID : 0x884-BOMB',
        seq_close = '×',
        hack_server = 'SYSTÈME DE CHIFFREMENT TACTIQUE',
        hack_bomb_state = 'BOMBE',
        hack_active = 'ACTIVE',
        hack_locked = 'SYSTÈME BLOQUÉ',
        hack_subtitle = 'Contournement manuel en 2 étapes requis',
        hack_start = 'DÉMARRER LE HACK',
        hack_stage1 = 'ÉTAPE 1 : SÉQUENCE D\'ACCÈS',
        hack_stage2 = 'ÉTAPE 2 : SYNCHRONISATION DE TENSION',
        hack_security = 'Sécurité',
        hack_attempts = 'Tentatives',
        hack_logs = 'Journaux système',
        hack_waiting = 'En attente de saisie...',
        hack_firewall = 'Pare-feu détecté...',
        hack_stage1_log = 'Étape 1 : Décodage du keypad...',
        hack_stage2_log = 'Étape 2 : Synchronisation des noyaux...',
        hack_access = 'Keypad : ACCÈS AUTORISÉ',
        hack_error_code = 'ERREUR : Code invalide',
        hack_syncing = 'SYNCHRONISATION : %s%%',
        hack_out_of_range = 'HORS PLAGE',
        hack_success = 'BOMBE DÉSAMORCÉE',
        hack_success_log = 'SYSTÈME ENTIÈREMENT DÉVERROUILLÉ',
        hack_fail = 'DÉTONATION IMMINENTE',
        hack_fail_log = 'ERREUR CRITIQUE : ÉCHEC DE SÉCURITÉ',
        hack_restart = 'REDÉMARRER',
        hack_retry = 'RÉESSAYER',
        hack_hold_zone = 'MAINTENEZ LE MARQUEUR DANS LA ZONE VERTE',
        timer_title = 'GRN // SYSTÈME DE SÉCURITÉ',
        timer_status = 'STABILISATION DU NOYAU...',
        timer_stage = 'ÉTAPE',
        timer_press = 'DÉSAMORCER [ESPACE]',
        timer_secure = 'SYSTÈME SÉCURISÉ',
        timer_secure_desc = 'Protocole de désamorçage terminé.',
        timer_boom = 'BOUM !',
        timer_timeout = 'TEMPS ÉCOULÉ',
        timer_sync_error = 'ERREUR DE SYNCHRO',
        timer_retry = 'RÉESSAYER',
        lock_title = 'SYSTÈME GRN',
        lock_subtitle = 'Désactivation de Sécurité',
        lock_time = 'Temps Restant',
        lock_points = 'Points de Pression',
        lock_hint = 'APPUYEZ SUR ESPACE QUAND L’INDICATEUR PASSE DANS LA ZONE DORÉE',
        lock_compromised = 'SYSTÈME COMPROMIS',
        lock_fail = 'ÉCHEC',
        btn_title = 'SÉCURITÉ GRN',
        btn_module = 'MODULE',
        btn_hint = 'APPUYEZ SUR LES BOUTONS DANS L’ORDRE CROISSANT',
        btn_attempts = 'TENTATIVES',
        btn_access = 'SYSTÈME DÉVERROUILLÉ',
        btn_fail = 'ÉCHEC CRITIQUE / DÉTONATION',
        btn_restart = 'RECOMMENCER',
    }
}

local function phrase(lang, key)
    local tbl = MINI_I18N[lang] or MINI_I18N.en
    return tbl[key] or MINI_I18N.en[key] or key
end

local function jsEscape(str)
    str = tostring(str or '')
    str = str:gsub('\\', '\\\\')
    str = str:gsub("'", "\\'")
    str = str:gsub('\n', '\\n')
    str = str:gsub('\r', '')
    return str
end

local function closeMG()
    if IsValid(MG) then MG:Remove() end
end

local function sendResult(ent, success)
    if not IsValid(ent) then
        closeMG()
        return
    end

    net.Start('grn_bombs_minigame_result')
        net.WriteEntity(ent)
        net.WriteBool(success)
    net.SendToServer()

    closeMG()
end

local function difficultyWireCount(diff)
    return ({easy = 4, medium = 5, hard = 6, expert = 7})[tostring(diff or 'medium')] or 5
end

local function wireHintEnabled(diff)
    return tostring(diff or 'medium') ~= 'expert'
end

local WIRECUTTING_HTML = [[
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap');
:root{--bg-dark:#06080b;--bg-panel:#0b0e12;--bg-card:#12161c;--accent-cyan:#fcb249;--accent-gold:#fcb249;--accent-green:#2ecc71;--accent-red:#e74c3c;--text-primary:#ece9e0;--text-secondary:#a8aeb4;--text-dim:#70777f;--border-color:#262a30;--border-accent:#3a3426}
*{box-sizing:border-box;margin:0;padding:0}html,body{width:100%;height:100%;overflow:hidden;background:transparent;font-family:SymBody,'Roboto Condensed',sans-serif;color:var(--text-primary)}body{display:flex;align-items:center;justify-content:center}
.gmod-window{width:min(95vw,650px);background:var(--bg-panel);border:1px solid var(--border-accent);box-shadow:0 0 50px rgba(0,0,0,.8);display:flex;flex-direction:column;position:relative}.title-bar{height:40px;background:linear-gradient(90deg,#0b0e12,#12161c);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;padding:0 15px;justify-content:space-between}.title-bar span{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:13px;text-transform:uppercase;color:var(--accent-cyan);letter-spacing:2px}.game-container{padding:26px;display:flex;flex-direction:column;align-items:center;gap:20px}.status-panel{width:100%;background:var(--bg-dark);padding:15px;border:1px solid var(--border-color);display:flex;justify-content:space-around;border-radius:0}.stat-label{font-family:SymHead,BigNoodleTitling,'Bebas Neue';font-size:10px;color:var(--text-dim);text-transform:uppercase}.stat-value{font-family:SymHead,BigNoodleTitling,'Bebas Neue';font-size:20px;font-weight:700;color:var(--accent-gold)}.wires-area{width:100%;height:280px;background:var(--bg-card);background-image:radial-gradient(circle at 50% 50%,#1c2235 0%,#12161c 100%);border:2px solid var(--border-color);position:relative;display:flex;justify-content:space-around;align-items:center;padding:0 40px;border-radius:0}.wire-container{height:100%;width:16px;position:relative;cursor:pointer;transition:transform .2s}.wire-container:hover{transform:scaleX(1.12)}.wire{width:100%;height:100%;background:var(--wire-color);box-shadow:inset -4px 0 6px rgba(0,0,0,.6),0 0 15px var(--wire-color);border-radius:0;position:relative;z-index:2}.wire-container.next-hint .wire{animation:hint-glow 1.5s infinite ease-in-out}@keyframes hint-glow{0%,100%{filter:brightness(1);box-shadow:0 0 15px var(--wire-color)}50%{filter:brightness(1.8);box-shadow:0 0 30px var(--wire-color)}}.wire-part{width:100%;background:var(--wire-color);box-shadow:inset -4px 0 6px rgba(0,0,0,.6);position:absolute;left:0;z-index:3;transition:transform .5s cubic-bezier(.175,.885,.32,1.275),opacity .3s}.wire-top{top:0;height:50%;border-radius:0}.wire-bottom{bottom:0;height:50%;border-radius:0}.cut .wire{display:none}.cut .wire-top{transform:translateY(-15px) rotate(-5deg);opacity:.6}.cut .wire-bottom{transform:translateY(15px) rotate(5deg);opacity:.6}.spark{position:absolute;top:50%;left:50%;width:4px;height:4px;background:#fff;border-radius:50%;pointer-events:none;box-shadow:0 0 10px #fff;opacity:0}.cut .spark{animation:spark-burst .4s forwards}@keyframes spark-burst{0%{transform:scale(1);opacity:1}100%{transform:scale(10);opacity:0}}.wire-num{position:absolute;bottom:-25px;left:50%;transform:translateX(-50%);font-family:SymHead,BigNoodleTitling,'Bebas Neue';font-weight:700;font-size:14px;color:var(--text-secondary)}.msg{font-family:SymHead,BigNoodleTitling,'Bebas Neue';font-weight:700;text-transform:uppercase;min-height:20px;letter-spacing:1px;text-align:center}.error{color:var(--accent-red);animation:shake .4s}.success{color:var(--accent-green);text-shadow:0 0 10px var(--accent-green)}.hint{color:var(--text-dim);font-size:11px;text-align:center;line-height:1.4}.actions{display:flex;gap:10px}.btn{padding:10px 22px;font-family:SymHead,BigNoodleTitling,'Bebas Neue';font-weight:700;cursor:pointer;text-transform:uppercase;transition:.2s}.btn-reset{background:rgba(252,178,73,.05);border:1px solid var(--accent-cyan);color:var(--accent-cyan)}.btn-reset:hover{background:var(--accent-cyan);color:#000}.btn-abort{background:rgba(231,76,60,.08);border:1px solid var(--accent-red);color:var(--accent-red)}.btn-abort:hover{background:var(--accent-red);color:#fff}@keyframes shake{0%,100%{transform:translateX(0)}20%,60%{transform:translateX(-10px)}40%,80%{transform:translateX(10px)}}
</style></head><body>
<div class="gmod-window" id="window"><div class="title-bar"><span id="titleName">CRITICAL ENERGY UNIT</span><span id="titleId" style="color:var(--text-dim);font-size:10px">ID: #GRN-00</span></div><div class="game-container"><div class="status-panel"><div style="text-align:center"><div class="stat-label" id="lblStatus">Network Status</div><div id="game-status" class="stat-value">STABLE</div></div><div style="text-align:center"><div class="stat-label" id="lblSync">Synchronization</div><div id="game-step" class="stat-value">0%</div></div><div style="text-align:center"><div class="stat-label" id="lblTime">Time Left</div><div id="game-timer" class="stat-value">00:00</div></div></div><div class="hint" id="hintText"></div><div class="wires-area" id="wires-box"></div><div id="feedback" class="msg"></div><div class="actions"><button class="btn btn-reset" id="resetBtn" onclick="initGame()">Reconfigure Fuses</button><button class="btn btn-abort" id="abortBtn" onclick="abortGame()">Abort</button></div></div></div>
<script>
const colors=['#e74c3c','#3498db','#f1c40f','#2ecc71','#9b59b6','#e67e22','#fcb249'];let currentStep=0,totalWires=5,isGameOver=false,sequence=[],secondsLeft=60,timerHandle=null,hintEnabled=true,sessionId=77;let TXT={};
function setConfig(cfg){TXT=cfg.texts||{};totalWires=Math.max(4,Math.min(8,Number(cfg.totalWires||5)));secondsLeft=Math.max(5,Number(cfg.timer||60));hintEnabled=!!cfg.hintEnabled;sessionId=Number(cfg.sessionId||77);document.getElementById('titleName').innerText=String(cfg.title||TXT.wire_title||'CRITICAL ENERGY UNIT').toUpperCase();document.getElementById('titleId').innerText='ID: #GRN-'+String(sessionId).padStart(2,'0');document.getElementById('lblStatus').innerText=TXT.wire_status||'Network Status';document.getElementById('lblSync').innerText=TXT.wire_sync||'Synchronization';document.getElementById('lblTime').innerText=TXT.wire_time||'Time Left';document.getElementById('resetBtn').innerText=TXT.wire_reset||'Reconfigure Fuses';document.getElementById('abortBtn').innerText=TXT.wire_abort||'Abort';document.getElementById('hintText').innerText=hintEnabled?(TXT.wire_hint_on||''):(TXT.wire_hint_off||'');initGame()}
function initTimer(){if(timerHandle)clearInterval(timerHandle);updateTimer();timerHandle=setInterval(()=>{if(isGameOver){clearInterval(timerHandle);timerHandle=null;return}secondsLeft--;updateTimer();if(secondsLeft<=0){fail(TXT.wire_error_time||'> ERROR')}} ,1000)}
function updateTimer(){const mins=Math.floor(Math.max(0,secondsLeft)/60);const secs=Math.max(0,secondsLeft)%60;document.getElementById('game-timer').innerText=String(mins).padStart(2,'0')+':'+String(secs).padStart(2,'0')}
function initGame(){const box=document.getElementById('wires-box');const feedback=document.getElementById('feedback');const statusVal=document.getElementById('game-status');const stepVal=document.getElementById('game-step');box.innerHTML='';feedback.innerHTML='';feedback.className='msg';statusVal.innerText=TXT.wire_scanning||'SCANNING...';statusVal.style.color='var(--accent-gold)';currentStep=0;isGameOver=false;let nums=[];while(nums.length<totalWires){let r=Math.floor(Math.random()*25)+1;if(nums.indexOf(r)===-1)nums.push(r)}sequence=[...nums].sort((a,b)=>a-b);stepVal.innerText='0%';nums.forEach((num,i)=>{const c=document.createElement('div');c.className='wire-container';c.id='wire-id-'+num;c.style.setProperty('--wire-color',colors[i%colors.length]);c.innerHTML='<div class="wire"></div><div class="wire-part wire-top"></div><div class="wire-part wire-bottom"></div><div class="spark"></div><div class="wire-num">'+num+'</div>';c.onclick=()=>processClick(num,c);box.appendChild(c)});updateHint();initTimer()}
function processClick(num,element){if(isGameOver||element.classList.contains('cut'))return;if(num===sequence[currentStep]){element.classList.add('cut');element.classList.remove('next-hint');currentStep++;document.getElementById('game-step').innerText=Math.round((currentStep/totalWires)*100)+'%';if(currentStep===totalWires){victory()}else updateHint()}else fail(TXT.wire_error_short||'> ERROR')}
function updateHint(){document.querySelectorAll('.wire-container').forEach(el=>el.classList.remove('next-hint'));if(!hintEnabled||isGameOver)return;const nextVal=sequence[currentStep];const nextWire=document.getElementById('wire-id-'+nextVal);if(nextWire)nextWire.classList.add('next-hint')}
function victory(){isGameOver=true;if(timerHandle)clearInterval(timerHandle);document.getElementById('game-status').innerText=TXT.wire_bypass||'BYPASS OK';document.getElementById('game-status').style.color='var(--accent-green)';document.getElementById('feedback').innerText=TXT.wire_access||'> ACCESS';document.getElementById('feedback').className='msg success';setTimeout(()=>{if(window.gmod&&gmod.Success)gmod.Success()},500)}
function fail(msg){isGameOver=true;if(timerHandle)clearInterval(timerHandle);document.getElementById('game-status').innerText=TXT.wire_locked||'SYSTEM LOCKED';document.getElementById('game-status').style.color='var(--accent-red)';document.getElementById('feedback').innerText=msg||'> ERROR';document.getElementById('feedback').className='msg error';document.getElementById('window').style.animation='shake 0.4s';setTimeout(()=>{document.getElementById('window').style.animation=''},400);setTimeout(()=>{if(window.gmod&&gmod.Fail)gmod.Fail()},650)}
function abortGame(){if(window.gmod&&gmod.Abort)gmod.Abort()}
</script></body></html>
]]


local SEQUENCE_HTML = [[
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap');
:root{--bg-dark:#06080b;--bg-panel:#0b0e12;--bg-card:#12161c;--bg-hover:#1b2028;--accent-blue:#fcb249;--accent-blue-light:#fdc06e;--accent-cyan:#fcb249;--accent-gold:#fcb249;--accent-green:#2ecc71;--accent-red:#e74c3c;--text-primary:#ece9e0;--text-secondary:#a8aeb4;--text-dim:#70777f;--border-color:#262a30;--border-accent:#3a3426;--transition:.18s ease}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}html,body{height:100%;font-family:SymBody,'Roboto Condensed',sans-serif;color:var(--text-primary);background:transparent;overflow:hidden}body{display:flex;align-items:center;justify-content:center;min-height:100vh}
.gmod-window{width:min(95vw,600px);background:var(--bg-panel);border:1px solid var(--border-color);box-shadow:0 8px 60px rgba(0,0,0,.85);display:flex;flex-direction:column;position:relative}.title-bar{height:38px;background:linear-gradient(90deg,#0b0e12,#12161c 60%,#0b0e12);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;padding:0 15px;justify-content:space-between}.server-name{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-cyan)}.win-btn{width:26px;height:26px;border:1px solid rgba(231,76,60,.35);display:grid;place-items:center;color:var(--accent-red);cursor:pointer;font-size:18px;line-height:1;background:rgba(231,76,60,.06)}.win-btn:hover{background:var(--accent-red);color:#fff}.game-container{padding:30px;text-align:center}.status-display{margin-bottom:20px;padding:15px;background:rgba(0,0,0,.3);border-radius:0;border:1px solid var(--border-color)}#status-text{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:18px;text-transform:uppercase;letter-spacing:2px;color:var(--accent-gold)}.score-info{font-size:12px;color:var(--text-dim);margin-top:5px;text-transform:uppercase}.sequence-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:15px;margin:20px auto;max-width:320px}.pad-btn{aspect-ratio:1/1;border-radius:0;border:2px solid var(--border-color);cursor:pointer;transition:all .1s ease;position:relative;opacity:.6;background:var(--bg-card)}.pad-btn:active{transform:scale(.95)}.pad-btn.active{opacity:1;border-color:#fff;box-shadow:0 0 20px currentColor}.btn-cyan{color:var(--accent-cyan);background:rgba(252,178,73,.1)}.btn-red{color:var(--accent-red);background:rgba(231,76,60,.1)}.btn-green{color:var(--accent-green);background:rgba(46,204,113,.1)}.btn-gold{color:var(--accent-gold);background:rgba(252,178,73,.1)}.btn-cyan.active{background:var(--accent-cyan)}.btn-red.active{background:var(--accent-red)}.btn-green.active{background:var(--accent-green)}.btn-gold.active{background:var(--accent-gold)}.btn-action{margin-top:20px;padding:12px 40px;background:var(--accent-blue);border:none;border-radius:0;color:#fff;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;text-transform:uppercase;cursor:pointer;letter-spacing:1px;transition:var(--transition)}.btn-action:hover{background:var(--accent-blue-light)}.btn-action:disabled{background:var(--border-color);cursor:not-allowed;opacity:.5}.footer{padding:10px 15px;font-size:10px;color:var(--text-dim);border-top:1px solid var(--border-color);display:flex;justify-content:space-between}
</style></head><body>
<div class="gmod-window"><div class="title-bar"><span class="server-name" id="titleText">GALAXY REPUBLIC NETWORK // SECURITY BYPASS</span><div class="win-btn close" id="closeBtn" onclick="closeMenu()">×</div></div><div class="game-container"><div class="status-display"><div id="status-text">WAITING TO START...</div><div class="score-info"><span id="roundLabel">Current Round</span>: <span id="round-count" style="color:var(--text-primary)">0</span></div></div><div class="sequence-grid"><div class="pad-btn btn-cyan" id="pad-0" onclick="handleInput(0)"></div><div class="pad-btn btn-red" id="pad-1" onclick="handleInput(1)"></div><div class="pad-btn btn-green" id="pad-2" onclick="handleInput(2)"></div><div class="pad-btn btn-gold" id="pad-3" onclick="handleInput(3)"></div></div><button class="btn-action" id="start-btn" onclick="startGame()">START SEQUENCE</button></div><div class="footer"><span id="footerStatus">STATUS: STANDBY</span><span id="footerUid">UID: 0x884-BOMB</span></div></div>
<script>
let sequence=[],playerSequence=[],round=0,isWaitingForInput=false,isGameOver=false,playbackSpeed=800,flashDuration=400,targetRounds=5,TXT={};
const statusText=document.getElementById('status-text'),roundCount=document.getElementById('round-count'),startBtn=document.getElementById('start-btn');
function setConfig(cfg){TXT=cfg.texts||{};playbackSpeed=Math.max(350,Number(cfg.playbackSpeed||800));flashDuration=Math.max(140,Math.min(playbackSpeed-120,Number(cfg.flashDuration||400)));targetRounds=Math.max(3,Math.min(12,Number(cfg.targetRounds||5)));document.getElementById('titleText').innerText=TXT.seq_title||'GALAXY REPUBLIC NETWORK // SECURITY BYPASS';document.getElementById('status-text').innerText=TXT.seq_wait||'WAITING TO START...';document.getElementById('roundLabel').innerText=TXT.seq_round||'Current Round';document.getElementById('start-btn').innerText=TXT.seq_start||'START SEQUENCE';document.getElementById('footerStatus').innerText=TXT.seq_footer_status||'STATUS: STANDBY';document.getElementById('footerUid').innerText=TXT.seq_footer_uid||'UID: 0x884-BOMB';document.getElementById('closeBtn').innerText=TXT.seq_close||'×';}
function startGame(){sequence=[];playerSequence=[];round=0;isGameOver=false;startBtn.disabled=true;startBtn.innerText=TXT.seq_start||'START SEQUENCE';nextRound()}
function nextRound(){if(isGameOver)return;playerSequence=[];round++;roundCount.innerText=round;statusText.innerText=TXT.seq_watch||'WATCH THE SEQUENCE';statusText.style.color='var(--accent-cyan)';sequence.push(Math.floor(Math.random()*4));playSequence()}
function playSequence(){isWaitingForInput=false;let i=0;const interval=setInterval(()=>{flashPad(sequence[i]);i++;if(i>=sequence.length){clearInterval(interval);setTimeout(()=>{if(isGameOver)return;isWaitingForInput=true;statusText.innerText=TXT.seq_repeat||'REPEAT THE SEQUENCE';statusText.style.color='var(--accent-gold)'},Math.max(300,flashDuration+140))}},playbackSpeed)}
function flashPad(index){const pad=document.getElementById('pad-'+index);pad.classList.add('active');setTimeout(()=>pad.classList.remove('active'),flashDuration)}
function handleInput(index){if(!isWaitingForInput||isGameOver)return;flashPad(index);playerSequence.push(index);const currentStep=playerSequence.length-1;if(playerSequence[currentStep]!==sequence[currentStep]){gameOver();return}if(playerSequence.length===sequence.length){isWaitingForInput=false;if(round>=targetRounds){winGame();return}statusText.innerText=TXT.seq_correct||'CORRECT!';statusText.style.color='var(--accent-green)';setTimeout(nextRound,900)}}
function winGame(){isGameOver=true;isWaitingForInput=false;statusText.innerText=TXT.seq_correct||'CORRECT!';statusText.style.color='var(--accent-green)';setTimeout(()=>{if(window.gmod&&gmod.Success)gmod.Success()},500)}
function gameOver(){isGameOver=true;isWaitingForInput=false;statusText.innerText=TXT.seq_fail||'SYSTEM FAILURE';statusText.style.color='var(--accent-red)';startBtn.disabled=false;startBtn.innerText=TXT.seq_retry||'RETRY';setTimeout(()=>{if(window.gmod&&gmod.Fail)gmod.Fail()},600)}
function closeMenu(){if(window.gmod&&gmod.Abort)gmod.Abort()}
</script></body></html>
]]

local CODE_HTML = [[
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap');
:root{--bg-dark:#06080b;--bg-panel:#0b0e12;--bg-card:#12161c;--bg-hover:#1b2028;--accent-blue:#fcb249;--accent-blue-light:#fdc06e;--accent-cyan:#fcb249;--accent-green:#2ecc71;--accent-red:#e74c3c;--text-primary:#ece9e0;--text-secondary:#a8aeb4;--text-dim:#70777f;--border-color:#262a30;--border-accent:#3a3426;--transition:.18s ease}*{box-sizing:border-box;margin:0;padding:0}html,body{height:100%;font-family:SymBody,'Roboto Condensed',sans-serif;color:var(--text-primary);background:transparent;overflow:hidden}body{display:flex;align-items:center;justify-content:center}.gmod-window{width:min(95vw,500px);background:var(--bg-panel);border:1px solid var(--border-color);box-shadow:0 8px 60px rgba(0,0,0,.85), inset 0 1px 0 rgba(255,255,255,.04);display:flex;flex-direction:column;position:relative;border-radius:0}.title-bar{height:38px;background:linear-gradient(90deg,#0b0e12,#12161c 60%,#0b0e12);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;padding:0 10px;gap:8px;flex-shrink:0}.title-bar .server-name{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-cyan)}.bomb-container{padding:25px;display:flex;flex-direction:column;gap:20px;align-items:center}.display-unit{width:100%;background:#080a12;border:2px solid var(--border-accent);border-radius:0;padding:15px;position:relative;box-shadow:inset 0 0 15px rgba(252,178,73,.1);text-align:center}.timer{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:32px;font-weight:700;color:var(--accent-red);letter-spacing:2px;text-shadow:0 0 10px rgba(231,76,60,.5);margin-bottom:10px}.code-input-display{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:42px;font-weight:700;color:var(--text-primary);letter-spacing:8px;min-height:50px;display:flex;justify-content:center;align-items:center}.code-dot{color:var(--text-dim)}.code-filled{color:var(--accent-cyan)}.keypad-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;width:100%;max-width:300px}.key-btn{aspect-ratio:1/1;background:var(--bg-card);border:1px solid var(--border-color);border-radius:0;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:24px;font-weight:700;color:var(--text-secondary);cursor:pointer;transition:all var(--transition);display:flex;align-items:center;justify-content:center}.key-btn:hover{background:var(--bg-hover);border-color:var(--accent-blue-light);color:#fff}.key-btn:active{transform:scale(.95);background:var(--accent-blue)}.key-btn.action-clear{color:var(--accent-red);border-color:rgba(231,76,60,.3);font-size:16px}.key-btn.action-enter{color:var(--accent-green);border-color:rgba(46,204,113,.3);font-size:16px}.status-bar{width:100%;padding:10px;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:11px;text-transform:uppercase;letter-spacing:.1em;text-align:center;border-radius:0;background:rgba(255,255,255,.02);color:var(--text-dim)}.status-error{color:var(--accent-red);animation:blink .5s step-end infinite}.status-success{color:var(--accent-green)}@keyframes blink{50%{opacity:0}}.overlay{position:absolute;inset:0;background:transparent;display:none;flex-direction:column;align-items:center;justify-content:center;z-index:10;padding:20px;text-align:center}.overlay h2{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:32px;margin-bottom:10px;text-transform:uppercase}.overlay.win h2{color:var(--accent-green)}.overlay.fail h2{color:var(--accent-red)}.subhint{font-size:11px;color:var(--text-dim);text-transform:uppercase;letter-spacing:.08em}
</style></head><body>
<div class="gmod-window"><div class="title-bar"><div class="server-name" id="sysTitle">GRN SYSTEM</div></div><div class="bomb-container"><div class="display-unit"><div id="timer" class="timer">00:45:00</div><div id="display" class="code-input-display">____</div></div><div id="status-msg" class="status-bar">AWAITING INPUT...</div><div id="hint-msg" class="subhint">ENTER ACCESS CODE</div><div class="keypad-grid"><button class="key-btn" onclick="addNum('1')">1</button><button class="key-btn" onclick="addNum('2')">2</button><button class="key-btn" onclick="addNum('3')">3</button><button class="key-btn" onclick="addNum('4')">4</button><button class="key-btn" onclick="addNum('5')">5</button><button class="key-btn" onclick="addNum('6')">6</button><button class="key-btn" onclick="addNum('7')">7</button><button class="key-btn" onclick="addNum('8')">8</button><button class="key-btn" onclick="addNum('9')">9</button><button class="key-btn action-clear" id="btnClear" onclick="clearInput()">CLR</button><button class="key-btn" onclick="addNum('0')">0</button><button class="key-btn action-enter" id="btnEnter" onclick="checkCode()">ENT</button></div></div><div id="overlay" class="overlay"><h2 id="overlay-title">SYSTEM HALTED</h2><p id="overlay-msg" style="font-size:13px;color:var(--text-secondary)"></p></div></div>
<script>
let CORRECT_CODE='7342', currentInput='', timeLeft=45, isGameOver=false, codeLength=4, TXT={};
const displayEl=document.getElementById('display'), timerEl=document.getElementById('timer'), statusEl=document.getElementById('status-msg'), overlayEl=document.getElementById('overlay');
function setConfig(cfg){TXT=cfg.texts||{};CORRECT_CODE=String(cfg.code||'7342');codeLength=Math.max(1,Math.min(12,CORRECT_CODE.length));timeLeft=Math.max(5,Number(cfg.timer||45));document.getElementById('sysTitle').innerText=TXT.code_system||'GRN SYSTEM';document.getElementById('status-msg').innerText=TXT.code_waiting||'AWAITING INPUT...';document.getElementById('hint-msg').innerText=cfg.hint && String(cfg.hint).trim()!=='' ? String(cfg.hint) : (TXT.code_hint_default||'ENTER ACCESS CODE');document.getElementById('btnClear').innerText=TXT.code_clear||'CLR';document.getElementById('btnEnter').innerText=TXT.code_enter||'ENT';updateDisplay()}
function updateDisplay(){let dots='';for(let i=0;i<codeLength;i++){if(currentInput[i])dots+='<span class="code-filled">'+currentInput[i]+'</span>';else dots+='<span class="code-dot">_</span>';}displayEl.innerHTML=dots}
function addNum(num){if(isGameOver||currentInput.length>=codeLength)return;currentInput+=num;updateDisplay();statusEl.innerText=TXT.code_inputting||'INPUTTING...';statusEl.className='status-bar'}
function clearInput(){if(isGameOver)return;currentInput='';updateDisplay();statusEl.innerText=TXT.code_waiting||'AWAITING INPUT...';statusEl.className='status-bar'}
function checkCode(){if(isGameOver||currentInput.length<codeLength)return;if(currentInput===CORRECT_CODE){winGame()}else{statusEl.innerText=TXT.code_denied||'ACCESS DENIED';statusEl.className='status-bar status-error';currentInput='';setTimeout(updateDisplay,350);timeLeft=Math.max(0,timeLeft-5)}}
const timerInterval=setInterval(()=>{if(isGameOver)return;timeLeft-=0.01;if(timeLeft<=0){timeLeft=0;failGame(TXT.code_time||'TIME EXPIRED')}const secs=Math.floor(timeLeft);const ms=Math.floor((timeLeft%1)*100);timerEl.innerText='00:'+secs.toString().padStart(2,'0')+':'+ms.toString().padStart(2,'0');if(timeLeft<10)timerEl.style.color='#ff0000'},10)
function winGame(){isGameOver=true;statusEl.innerText=TXT.code_deactivated||'DEACTIVATED';statusEl.className='status-bar status-success';overlayEl.style.display='flex';overlayEl.className='overlay win';document.getElementById('overlay-title').innerText=TXT.code_defused||'BOMB DEFUSED';document.getElementById('overlay-msg').innerText=TXT.code_defused_msg||'';setTimeout(()=>{if(window.gmod&&gmod.Success)gmod.Success()},500)}
function failGame(reason){isGameOver=true;overlayEl.style.display='flex';overlayEl.className='overlay fail';document.getElementById('overlay-title').innerText=TXT.code_failed||'MISSION FAILED';document.getElementById('overlay-msg').innerText=reason||'';setTimeout(()=>{if(window.gmod&&gmod.Fail)gmod.Fail()},700)}
updateDisplay();
</script></body></html>
]]

local function openDHTMLMinigame(htmlStr, ent, configJs)
    closeMG()

    MG = vgui.Create('DFrame')
    MG:SetTitle('')
    MG:SetSize(math.min(ScrW() - 80, 760), math.min(ScrH() - 80, 620))
    MG:Center()
    MG:MakePopup()
    MG:ShowCloseButton(false)
    MG:SetDraggable(false)
    MG.Paint = function(_, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    local html = vgui.Create('DHTML', MG)
    html:Dock(FILL)
    html:SetAllowLua(true)
    if SYMUI then htmlStr = SYMUI.ThemeHTML(htmlStr, { css = GRN_Bombs.SymCSS }) end
    html:SetHTML(htmlStr)

    html:AddFunction('gmod', 'Success', function() sendResult(ent, true) end)
    html:AddFunction('gmod', 'Fail', function() sendResult(ent, false) end)
    html:AddFunction('gmod', 'Abort', function() sendResult(ent, false) end)

    html.OnDocumentReady = function(self)
        self:QueueJavascript(configJs)
    end

    -- Reenviar SPACE al JS porque DHTML no recibe eventos de teclado del juego
    MG.OnKeyCodePressed = function(_, keyCode)
        if keyCode == KEY_SPACE then
            html:QueueJavascript("if(window.gmod&&typeof gmod.KeyPress==='function'){gmod.KeyPress(57)}else{var e=new KeyboardEvent('keydown',{code:'Space',key:' ',bubbles:true});window.dispatchEvent(e)}")
        end
    end
end

local function openWireCutting(ent, data, lang)
    local sessionId = IsValid(ent) and ent:EntIndex() or math.random(10, 99)
    local texts = util.TableToJSON(MINI_I18N[lang] or MINI_I18N.en)
    local configJs = string.format(
        "setConfig({title:'%s', timer:%d, totalWires:%d, hintEnabled:%s, sessionId:%d, texts:%s});",
        jsEscape(tostring(data.name or phrase(lang, 'wire_title'))),
        math.max(5, tonumber(data.timer) or 60),
        difficultyWireCount(data.difficulty),
        wireHintEnabled(data.difficulty) and 'true' or 'false',
        sessionId,
        texts
    )
    openDHTMLMinigame(WIRECUTTING_HTML, ent, configJs)
end

local function sequenceTargetRounds(diff)
    return ({easy = 4, medium = 5, hard = 6, expert = 7})[tostring(diff or 'medium')] or 5
end

local function sequencePlaybackSpeed(diff)
    return ({easy = 900, medium = 800, hard = 650, expert = 520})[tostring(diff or 'medium')] or 800
end

local function openCodeInput(ent, data, lang)
    local texts = util.TableToJSON(MINI_I18N[lang] or MINI_I18N.en)
    local code = tostring(data.codeValue or '7342'):gsub('[^%d]', '')
    if code == '' then code = '7342' end
    local hint = tostring(data.codeHint or '')
    local configJs = string.format(
        "setConfig({timer:%d, code:'%s', hint:'%s', texts:%s});",
        math.max(5, tonumber(data.timer) or 45),
        jsEscape(code),
        jsEscape(hint),
        texts
    )
    openDHTMLMinigame(CODE_HTML, ent, configJs)
end

local function openSequenceMinigame(ent, data, lang)
    local texts = util.TableToJSON(MINI_I18N[lang] or MINI_I18N.en)
    local configJs = string.format(
        "setConfig({targetRounds:%d, playbackSpeed:%d, flashDuration:%d, texts:%s});",
        sequenceTargetRounds(data.difficulty),
        sequencePlaybackSpeed(data.difficulty),
        math.max(140, sequencePlaybackSpeed(data.difficulty) - 300),
        texts
    )
    openDHTMLMinigame(SEQUENCE_HTML, ent, configJs)
end


local HACKPAD_HTML = [[
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap');
:root{--bg-dark:#06080b;--bg-panel:#0b0e12;--bg-card:#12161c;--bg-hover:#1b2028;--accent-blue:#fcb249;--accent-cyan:#fcb249;--accent-green:#2ecc71;--accent-red:#e74c3c;--accent-orange:#e67e22;--text-primary:#ece9e0;--text-secondary:#a8aeb4;--text-dim:#70777f;--border-color:#262a30;--border-accent:#3a3426;--transition:0.18s ease}
*,*:before,*:after{box-sizing:border-box;margin:0;padding:0}html,body{height:100%;font-family:SymBody,'Roboto Condensed',sans-serif;color:var(--text-primary);background:transparent;overflow:hidden}body{display:flex;align-items:center;justify-content:center;min-height:100vh}
.gmod-window{width:min(95vw,1000px);height:min(90vh,700px);background:var(--bg-panel);border:1px solid var(--border-color);box-shadow:0 8px 60px rgba(0,0,0,.85),inset 0 1px 0 rgba(255,255,255,.04);display:flex;flex-direction:column;position:relative}
.title-bar{height:38px;background:linear-gradient(90deg,#0b0e12,#12161c 60%,#0b0e12);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;padding:0 12px;gap:8px;flex-shrink:0}.server-name{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-cyan)}.breadcrumb{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:12px;color:var(--text-secondary);text-transform:uppercase}.breadcrumb span{color:var(--accent-red)}.timer-display{margin-left:auto;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;color:var(--accent-red);letter-spacing:2px;font-size:18px}
.game-container{display:flex;flex:1;overflow:hidden}.sidebar{width:280px;background:var(--bg-dark);border-right:1px solid var(--border-color);display:flex;flex-direction:column;padding:15px}.status-box{background:var(--bg-card);border:1px solid var(--border-accent);padding:15px;border-radius:0;margin-bottom:15px}.status-label{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:10px;color:var(--text-dim);text-transform:uppercase;letter-spacing:1px}.status-value{font-size:18px;font-weight:700;color:var(--text-primary);margin-bottom:10px}.puzzle-main{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:20px;position:relative}
.keypad-grid{display:grid;grid-template-columns:repeat(3,70px);gap:10px}.key-btn{height:70px;background:var(--bg-card);border:1px solid var(--border-accent);border-radius:0;display:grid;place-items:center;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:20px;font-weight:700;cursor:pointer;transition:all .1s}.key-btn:hover{background:var(--bg-hover);border-color:var(--accent-cyan)}.key-btn:active{transform:scale(.95);background:var(--accent-blue)}.code-display{width:230px;height:50px;background:rgba(0,0,0,.3);border:1px solid var(--border-color);margin-bottom:20px;display:flex;align-items:center;justify-content:center;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:24px;letter-spacing:8px;color:var(--accent-cyan)}
.slider-wrap{width:80%;max-width:400px;text-align:center}.voltage-bar{width:100%;height:30px;background:var(--bg-dark);border:1px solid var(--border-accent);position:relative;margin:20px 0;overflow:hidden}.voltage-target{position:absolute;height:100%;background:rgba(46,204,113,.3);border-left:2px solid var(--accent-green);border-right:2px solid var(--accent-green)}.voltage-indicator{position:absolute;height:100%;width:4px;background:#fff;box-shadow:0 0 10px #fff;transition:left .1s linear}
.screen{display:none;width:100%;height:100%;flex-direction:column;align-items:center;justify-content:center}.screen.active{display:flex}.terminal-msg{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;text-transform:uppercase;text-align:center}.btn-action{margin-top:20px;padding:12px 30px;background:var(--accent-cyan);border:none;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;cursor:pointer;border-radius:0}.log-area{margin-top:auto;font-size:11px;font-family:monospace;color:var(--accent-green);padding:10px;background:rgba(0,0,0,.2);width:100%;height:100px;overflow-y:auto}
</style></head><body>
<div class="gmod-window"><div class="title-bar"><div class="server-name" id="server-name"></div><div class="sep">|</div><div class="breadcrumb"><span id="bomb-state-label"></span> <span id="bomb-state-value"></span></div><div class="timer-display" id="global-timer">00:30</div></div><div class="game-container"><div class="sidebar"><div class="status-box"><div class="status-label" id="security-label"></div><div class="status-value" style="color:var(--accent-orange)" id="security-value">LEVEL 4</div><div class="status-label" id="attempts-label"></div><div id="lives-count" class="status-value">3 / 3</div></div><div class="status-label" id="logs-label"></div><div class="log-area" id="terminal-logs"></div></div><div class="puzzle-main"><div id="screen-start" class="screen active"><h1 class="terminal-msg" id="locked-title" style="font-size:32px;margin-bottom:10px"></h1><p id="locked-subtitle" style="color:var(--text-secondary);margin-bottom:20px"></p><button class="btn-action" id="start-btn" onclick="startGame()"></button></div><div id="screen-p1" class="screen"><div class="status-label" id="stage1-label" style="margin-bottom:10px"></div><div class="code-display" id="keypad-input">----</div><div class="keypad-grid"><div class="key-btn" onclick="pressKey(1)">1</div><div class="key-btn" onclick="pressKey(2)">2</div><div class="key-btn" onclick="pressKey(3)">3</div><div class="key-btn" onclick="pressKey(4)">4</div><div class="key-btn" onclick="pressKey(5)">5</div><div class="key-btn" onclick="pressKey(6)">6</div><div class="key-btn" onclick="pressKey(7)">7</div><div class="key-btn" onclick="pressKey(8)">8</div><div class="key-btn" onclick="pressKey(9)">9</div><div class="key-btn" style="color:var(--accent-red)" onclick="clearKey()">C</div><div class="key-btn" onclick="pressKey(0)">0</div><div class="key-btn" style="color:var(--accent-green)" onclick="checkKeypad()">OK</div></div></div><div id="screen-p2" class="screen"><div class="status-label" id="stage2-label"></div><p id="voltage-status" style="font-size:12px;margin-top:5px"></p><div class="slider-wrap"><div class="voltage-bar"><div class="voltage-target" style="left:60%;width:20%"></div><div class="voltage-indicator" id="v-ptr" style="left:0%"></div></div><input type="range" min="0" max="100" value="0" style="width:100%" id="voltage-control"></div></div><div id="screen-win" class="screen"><div style="font-size:60px;color:var(--accent-green)">✔</div><h1 class="terminal-msg" id="win-title"></h1><button class="btn-action" id="win-btn" style="background:var(--bg-card);border:1px solid var(--accent-green);color:var(--accent-green)" onclick="restartGame()"></button></div><div id="screen-lose" class="screen"><div style="font-size:60px;color:var(--accent-red)">✖</div><h1 class="terminal-msg" id="lose-title"></h1><button class="btn-action" id="lose-btn" style="background:var(--accent-red);color:white" onclick="restartGame()"></button></div></div></div></div>
<script>
let currentStage=0,timer=30,lives=3,gameActive=false,timerInterval=null,voltageInterval=null,inputBuffer="";
let CFG={timer:30,code:'1944',hint:'',texts:{}};
function t(k){return (CFG.texts&&CFG.texts[k])||k}
function setConfig(cfg){CFG=Object.assign(CFG,cfg||{});applyTexts();timer=Math.max(5,parseInt(CFG.timer||30));document.getElementById('global-timer').innerText='00:'+(timer<10?'0'+timer:timer);clearKey();const log=document.getElementById('terminal-logs');log.innerHTML=t('hack_waiting')+'<br>'+t('hack_firewall')+'<br>';}
function applyTexts(){document.getElementById('server-name').innerText=t('hack_server');document.getElementById('bomb-state-label').innerText=t('hack_bomb_state');document.getElementById('bomb-state-value').innerText=t('hack_active');document.getElementById('security-label').innerText=t('hack_security');document.getElementById('attempts-label').innerText=t('hack_attempts');document.getElementById('logs-label').innerText=t('hack_logs');document.getElementById('locked-title').innerText=t('hack_locked');document.getElementById('locked-subtitle').innerText=t('hack_subtitle');document.getElementById('start-btn').innerText=t('hack_start');document.getElementById('stage1-label').innerText=t('hack_stage1');document.getElementById('stage2-label').innerText=t('hack_stage2');document.getElementById('voltage-status').innerText=t('hack_hold_zone');document.getElementById('win-title').innerText=t('hack_success');document.getElementById('win-btn').innerText=t('hack_restart');document.getElementById('lose-title').innerText=t('hack_fail');document.getElementById('lose-btn').innerText=t('hack_retry');}
function addLog(msg){const logs=document.getElementById('terminal-logs');logs.innerHTML+='> '+msg+'<br>';logs.scrollTop=logs.scrollHeight}
function updateLives(){document.getElementById('lives-count').innerText=lives+' / 3';if(lives<=0)endGame(false)}
function showScreen(id){document.querySelectorAll('.screen').forEach(s=>s.classList.remove('active'));document.getElementById(id).classList.add('active')}
function startGame(){gameActive=true;lives=3;updateLives();showScreen('screen-p1');addLog(t('hack_stage1_log'));timerInterval=setInterval(()=>{timer--;document.getElementById('global-timer').innerText='00:'+(timer<10?'0'+timer:timer);if(timer<=0)endGame(false)},1000)}
function pressKey(num){if(!gameActive)return;if(inputBuffer.length<Math.max(1,String(CFG.code||'1944').length)){inputBuffer+=num;document.getElementById('keypad-input').innerText=inputBuffer}}
function clearKey(){inputBuffer='';document.getElementById('keypad-input').innerText='----'}
function checkKeypad(){if(!gameActive)return;const correct=String(CFG.code||'1944').replace(/\D/g,'')||'1944';if(inputBuffer===correct){addLog(t('hack_access'));initVoltageStage()}else{lives--;updateLives();addLog(t('hack_error_code'));clearKey()}}
function initVoltageStage(){showScreen('screen-p2');addLog(t('hack_stage2_log'));const ctrl=document.getElementById('voltage-control');const ptr=document.getElementById('v-ptr');let progress=0;clearInterval(voltageInterval);voltageInterval=setInterval(()=>{if(!gameActive){clearInterval(voltageInterval);return}let val=Number(ctrl.value||0);ptr.style.left=val+'%';if(val>=60&&val<=80){progress+=2;document.getElementById('voltage-status').innerText=t('hack_syncing').replace('%s',Math.floor(progress));document.getElementById('voltage-status').style.color='var(--accent-green)'}else{if(progress>0)progress-=0.5;document.getElementById('voltage-status').innerText=t('hack_out_of_range');document.getElementById('voltage-status').style.color='var(--accent-red)'}if(progress>=100){clearInterval(voltageInterval);endGame(true)}},100)}
function endGame(win){gameActive=false;clearInterval(timerInterval);clearInterval(voltageInterval);if(win){showScreen('screen-win');addLog(t('hack_success_log'));if(window.gmod&&gmod.Success)gmod.Success()}else{showScreen('screen-lose');addLog(t('hack_fail_log'));if(window.gmod&&gmod.Fail)gmod.Fail()}}
function restartGame(){if(window.gmod&&gmod.Abort)gmod.Abort()}
</script></body></html>]]

local function timerStages(diff)
    return ({easy = 4, medium = 5, hard = 6, expert = 7})[tostring(diff or 'medium')] or 5
end

local function timerBaseSpeed(diff)
    return ({easy = 2.3, medium = 2.8, hard = 3.4, expert = 4.1})[tostring(diff or 'medium')] or 2.8
end

local TIMER_HTML = [[
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap');
:root{--bg-dark:#06080b;--bg-panel:#0b0e12;--bg-card:#12161c;--accent-cyan:#fcb249;--accent-red:#e74c3c;--accent-green:#2ecc71;--accent-gold:#fcb249;--text-primary:#ece9e0;--text-secondary:#a8aeb4;--border-color:#262a30;--border-accent:#3a3426}*,*:before,*:after{box-sizing:border-box;margin:0;padding:0}body{height:100vh;font-family:SymBody,'Roboto Condensed',sans-serif;background:transparent;display:flex;align-items:center;justify-content:center;overflow:hidden;color:var(--text-primary)}.gmod-window{width:450px;background:var(--bg-panel);border:1px solid var(--border-color);box-shadow:0 8px 60px rgba(0,0,0,.85);display:flex;flex-direction:column;position:relative}.title-bar{height:38px;background:linear-gradient(90deg,#0b0e12,#12161c 60%,#0b0e12);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;padding:0 15px}.server-name{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-cyan)}.game-container{padding:30px;display:flex;flex-direction:column;align-items:center;gap:20px}.timer-display{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:42px;font-weight:700;color:var(--accent-red);text-shadow:0 0 10px rgba(231,76,60,.4)}.dial-wrapper{position:relative;width:220px;height:220px;border-radius:50%;border:4px solid var(--bg-dark);background:var(--bg-card);box-shadow:inset 0 0 20px rgba(0,0,0,.5);display:flex;align-items:center;justify-content:center}.progress-ring{position:absolute;width:100%;height:100%;border-radius:50%;border:8px solid rgba(255,255,255,.05)}#success-zone{position:absolute;width:100%;height:100%;border-radius:50%;border:8px solid transparent;border-top-color:var(--accent-cyan);transform:rotate(0deg);filter:drop-shadow(0 0 5px var(--accent-cyan))}#needle{position:absolute;width:4px;height:50%;background:var(--text-primary);bottom:50%;transform-origin:bottom center;border-radius:0;box-shadow:0 0 10px #fff;z-index:10}.center-node{width:20px;height:20px;background:var(--bg-panel);border:2px solid var(--border-accent);border-radius:50%;z-index:11}.game-info{text-align:center}.status-text{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:2px;font-size:14px;color:var(--text-secondary);margin-bottom:5px}.stage-counter{color:var(--accent-gold);font-size:12px}.btn-action{width:100%;padding:12px;background:var(--accent-blue,#fcb249);border:none;border-radius:0;color:#fff;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;text-transform:uppercase;letter-spacing:1px;cursor:pointer;transition:.2s}.btn-action:active{transform:scale(.98);background:var(--accent-cyan)}.overlay{position:absolute;inset:0;background:rgba(10,12,16,.95);display:none;flex-direction:column;align-items:center;justify-content:center;z-index:100;text-align:center}.overlay.active{display:flex}.overlay h2{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:32px;margin-bottom:10px}.text-success{color:var(--accent-green)}.text-error{color:var(--accent-red)}
</style></head><body><div class="gmod-window"><div class="title-bar"><div class="server-name" id="title"></div></div><div class="game-container"><div class="timer-display" id="timer">10.00</div><div class="dial-wrapper"><div class="progress-ring"></div><div id="success-zone"></div><div id="needle"></div><div class="center-node"></div></div><div class="game-info"><p class="status-text" id="status"></p><p class="stage-counter"><span id="stage-label"></span>: <span id="stage">1</span> / <span id="max-stage">5</span></p></div><button class="btn-action" id="interact-btn"></button></div><div id="overlay-result" class="overlay"><h2 id="result-title"></h2><p id="result-desc" style="color:var(--text-secondary);margin-bottom:20px;"></p><button class="btn-action" style="width:auto;padding:10px 30px;" id="retry-btn" onclick="resetGame()"></button></div></div>
<script>
let currentStage=1,maxStages=5,angle=0,speed=2.8,zoneAngle=0,zoneSize=45,isRunning=true,timeLeft=10.0,lastUpdate=Date.now();
let CFG={targetStages:5,baseSpeed:2.8,timer:10,texts:{}};
const needle=document.getElementById('needle'),successZone=document.getElementById('success-zone'),timerEl=document.getElementById('timer'),statusEl=document.getElementById('status'),overlay=document.getElementById('overlay-result');
function t(k){return (CFG.texts&&CFG.texts[k])||k}
function setConfig(cfg){CFG=Object.assign(CFG,cfg||{});maxStages=parseInt(CFG.targetStages||5);speed=Number(CFG.baseSpeed||2.8);timeLeft=Number(CFG.timer||10);document.getElementById('max-stage').innerText=maxStages;document.getElementById('title').innerText=t('timer_title');document.getElementById('status').innerText=t('timer_status');document.getElementById('stage-label').innerText=t('timer_stage');document.getElementById('interact-btn').innerText=t('timer_press');document.getElementById('retry-btn').innerText=t('timer_retry');initStage();update();}
function initStage(){zoneAngle=Math.floor(Math.random()*260)+40;zoneSize=Math.max(25,55-(currentStage*6));successZone.style.transform='rotate('+zoneAngle+'deg)';document.getElementById('stage').innerText=currentStage}
function update(){if(!isRunning)return;let now=Date.now();let dt=(now-lastUpdate)/16.66;lastUpdate=now;angle=(angle+(speed*dt))%360;needle.style.transform='rotate('+angle+'deg)';timeLeft-=0.016*dt;if(timeLeft<=0){endGame(false,t('timer_timeout'))}else{timerEl.innerText=timeLeft.toFixed(2)}requestAnimationFrame(update)}
function checkClick(){if(!isRunning)return;const hitBuffer=2,min=zoneAngle-hitBuffer,max=zoneAngle+zoneSize+hitBuffer;if(angle>=min&&angle<=max){flashEffect('var(--accent-cyan)');if(currentStage<maxStages){currentStage++;statusEl.innerText=t('timer_stage')+' '+currentStage;initStage()}else{endGame(true,t('timer_secure'))}}else{flashEffect('var(--accent-red)');endGame(false,t('timer_sync_error'))}}
function flashEffect(color){const dial=document.querySelector('.dial-wrapper');dial.style.boxShadow='0 0 30px '+color;setTimeout(()=>{dial.style.boxShadow='inset 0 0 20px rgba(0,0,0,0.5)'},150)}
function endGame(success,reason){isRunning=false;overlay.classList.add('active');const title=document.getElementById('result-title');const desc=document.getElementById('result-desc');if(success){title.innerText=t('timer_secure');title.className='text-success';desc.innerText=t('timer_secure_desc');if(window.gmod&&gmod.Success)gmod.Success()}else{title.innerText=t('timer_boom');title.className='text-error';desc.innerText=reason;if(window.gmod&&gmod.Fail)gmod.Fail()}}
function resetGame(){if(window.gmod&&gmod.Abort)gmod.Abort()}
document.getElementById('interact-btn').addEventListener('click',e=>{e.preventDefault();checkClick()});window.addEventListener('keydown',e=>{if(e.code==='Space'){e.preventDefault();checkClick()}})
</script></body></html>]]

local function openHackpadMinigame(ent, data, lang)
    local texts = util.TableToJSON(MINI_I18N[lang] or MINI_I18N.en)
    local code = tostring(data.codeValue or '1944'):gsub('[^%d]', '')
    if code == '' then code = '1944' end
    local configJs = string.format(
        "setConfig({timer:%d, code:'%s', hint:'%s', texts:%s});",
        math.max(5, tonumber(data.timer) or 30),
        jsEscape(code),
        jsEscape(tostring(data.codeHint or '')),
        texts
    )
    openDHTMLMinigame(HACKPAD_HTML, ent, configJs)
end

local function openTimerMinigame(ent, data, lang)
    local texts = util.TableToJSON(MINI_I18N[lang] or MINI_I18N.en)
    local configJs = string.format(
        "setConfig({targetStages:%d, baseSpeed:%s, timer:%d, texts:%s});",
        timerStages(data.difficulty),
        tostring(timerBaseSpeed(data.difficulty)),
        math.max(5, tonumber(data.timer) or 10),
        texts
    )
    openDHTMLMinigame(TIMER_HTML, ent, configJs)
end

local function lockpickStages(diff)
    return ({easy = 3, medium = 4, hard = 5, expert = 6})[tostring(diff or 'medium')] or 4
end

local function lockpickSpeed(diff)
    return ({easy = 2.4, medium = 3.0, hard = 3.6, expert = 4.3})[tostring(diff or 'medium')] or 3.0
end

local LOCKPICK_HTML = [[
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap');
:root{--bg-dark:#06080b;--bg-panel:#0b0e12;--bg-card:#12161c;--bg-hover:#1b2028;--accent-blue:#fcb249;--accent-cyan:#fcb249;--accent-gold:#fcb249;--accent-green:#2ecc71;--accent-red:#e74c3c;--text-primary:#ece9e0;--text-secondary:#a8aeb4;--text-dim:#70777f;--border-color:#262a30;--border-accent:#3a3426}
*{box-sizing:border-box;margin:0;padding:0;user-select:none}body{height:100vh;font-family:SymBody,'Roboto Condensed',sans-serif;color:var(--text-primary);background:transparent;display:flex;align-items:center;justify-content:center;overflow:hidden}.gmod-window{width:450px;background:var(--bg-panel);border:1px solid var(--border-color);box-shadow:0 8px 60px rgba(0,0,0,.85);display:flex;flex-direction:column;position:relative;animation:fadeIn .3s ease-out}@keyframes fadeIn{from{opacity:0;transform:scale(.95)}to{opacity:1;transform:scale(1)}}.title-bar{height:38px;background:linear-gradient(90deg,#0b0e12,#12161c 60%,#0b0e12);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;padding:0 12px;gap:8px}.server-name{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:12px;letter-spacing:.14em;color:var(--accent-cyan)}.game-container{padding:30px;display:flex;flex-direction:column;align-items:center;gap:25px}.lock-outer{width:200px;height:200px;border-radius:50%;border:8px solid var(--bg-dark);background:var(--bg-card);position:relative;box-shadow:inset 0 0 20px rgba(0,0,0,.5),0 0 15px rgba(252,178,73,.1);display:flex;align-items:center;justify-content:center}.lock-target{position:absolute;width:100%;height:100%;border-radius:50%;border:8px solid transparent;border-top-color:var(--accent-gold);transform:rotate(0deg);transition:transform .1s linear}.lock-core{width:60px;height:60px;background:var(--bg-dark);border:2px solid var(--border-accent);border-radius:50%;display:flex;align-items:center;justify-content:center;z-index:2}.lock-pick{position:absolute;width:4px;height:90px;background:linear-gradient(to bottom,var(--accent-cyan),transparent);bottom:50%;transform-origin:bottom center}.game-info{width:100%;display:grid;grid-template-columns:1fr 1fr;gap:10px}.stat-box{background:var(--bg-dark);border:1px solid var(--border-color);padding:10px;border-radius:0;text-align:center}.stat-label{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:10px;color:var(--text-dim);text-transform:uppercase}.stat-value{font-size:18px;font-weight:700;font-family:SymHead,BigNoodleTitling,'Bebas Neue'}.timer-active{color:var(--accent-red);text-shadow:0 0 5px rgba(231,76,60,.5)}.progress-container{width:100%;height:6px;background:var(--bg-dark);border-radius:0;overflow:hidden}.progress-bar{height:100%;width:0%;background:var(--accent-cyan);transition:width .2s}.hint-text{font-size:11px;color:var(--text-dim);text-align:center;margin-top:10px}.hint-text span{color:var(--accent-gold);font-weight:700}
</style></head><body><div class="gmod-window"><div class="title-bar"><span class="server-name" id="title"></span><span style="color:var(--text-dim)">|</span><span id="subtitle" style="font-size:11px;text-transform:uppercase;letter-spacing:1px;"></span></div><div class="game-container"><div class="game-info"><div class="stat-box"><div class="stat-label" id="time-label"></div><div id="timer" class="stat-value timer-active">00:30</div></div><div class="stat-box"><div class="stat-label" id="points-label"></div><div id="stage-info" class="stat-value" style="color:var(--accent-cyan)">1 / 3</div></div></div><div class="lock-outer"><div id="lock-target" class="lock-target"></div><div id="lock-core" class="lock-core"><div id="lock-pick" class="lock-pick"></div><div style="font-size:10px;color:var(--accent-cyan);font-weight:800;">GRN</div></div></div><div class="progress-container"><div id="progress" class="progress-bar"></div></div><div class="hint-text" id="hint"></div></div></div>
<script>
const state={active:true,angle:0,targetAngle:0,speed:3,stage:1,maxStages:3,timeLeft:30,targetWidth:40,texts:{}};const targetEl=document.getElementById('lock-target'),pickEl=document.getElementById('lock-pick'),timerEl=document.getElementById('timer'),stageEl=document.getElementById('stage-info'),progressEl=document.getElementById('progress');function t(k){return (state.texts&&state.texts[k])||k}
function setConfig(cfg){state.active=true;state.angle=0;state.stage=1;state.maxStages=parseInt(cfg.maxStages||3);state.timeLeft=Math.max(5,parseInt(cfg.timer||30));state.speed=Number(cfg.baseSpeed||3);state.targetWidth=Math.max(15,parseInt(cfg.targetWidth||40));state.texts=cfg.texts||{};document.getElementById('title').innerText=t('lock_title');document.getElementById('subtitle').innerText=t('lock_subtitle');document.getElementById('time-label').innerText=t('lock_time');document.getElementById('points-label').innerText=t('lock_points');document.getElementById('hint').innerHTML=t('lock_hint').replace('ESPACIO','<span>ESPACIO</span>').replace('SPACE','<span>SPACE</span>').replace('ESPACE','<span>ESPACE</span>');progressEl.style.width='0%';stageEl.style.color='var(--accent-cyan)';stageEl.innerText='1 / '+state.maxStages;initLevel();startTimer();update()}
function initLevel(){state.targetAngle=Math.random()*320;targetEl.style.transform='rotate('+state.targetAngle+'deg)';state.targetWidth=Math.max(12,state.targetWidth-((state.stage-1)*2));}
function update(){if(!state.active)return;state.angle+=state.speed;if(state.angle>=360)state.angle=0;pickEl.style.transform='rotate('+state.angle+'deg)';requestAnimationFrame(update)}
function checkHit(){if(!state.active)return;const center=(state.targetAngle+20)%360;let diff=Math.abs(state.angle-center);if(diff>180)diff=360-diff;if(diff<=state.targetWidth/2){state.stage++;progressEl.style.width=((state.stage-1)/state.maxStages*100)+'%';if(state.stage>state.maxStages){win()}else{stageEl.innerText=state.stage+' / '+state.maxStages;state.speed+=0.45;initLevel()}}else{state.timeLeft=Math.max(0,state.timeLeft-5);document.body.style.backgroundColor='rgba(231,76,60,.2)';setTimeout(()=>document.body.style.backgroundColor='transparent',100);if(state.timeLeft<=0)gameOver()}}
function win(){state.active=false;stageEl.innerText=t('lock_compromised');stageEl.style.color='var(--accent-green)';if(window.gmod&&gmod.Success)gmod.Success()}
function gameOver(){state.active=false;timerEl.innerText=t('lock_fail');if(window.gmod&&gmod.Fail)gmod.Fail()}
function startTimer(){if(window.__lpTimer)clearInterval(window.__lpTimer);window.__lpTimer=setInterval(()=>{if(!state.active)return;state.timeLeft--;if(state.timeLeft<=0){gameOver()}else{const secs=state.timeLeft<10?'0'+state.timeLeft:state.timeLeft;timerEl.innerText='00:'+secs}},1000)}
window.addEventListener('keydown',e=>{if((e.code==='Space'||e.key===' ')&&state.active){e.preventDefault();checkHit()}});
if(window.gmod){gmod.KeyPress=function(key){if(key===57&&state.active){checkHit()}}}
</script></body></html>]]

local function buttonPanelTime(diff)
    return ({easy = 14, medium = 11, hard = 9, expert = 7})[tostring(diff or 'medium')] or 11
end

local BUTTON_PANEL_HTML = [[
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><style>
@import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Roboto+Condensed:wght@400;500;600;700;800&display=swap');
:root{--bg-dark:#06080b;--bg-panel:#0b0e12;--bg-card:#12161c;--bg-hover:#1b2028;--accent-cyan:#fcb249;--accent-green:#2ecc71;--accent-red:#e74c3c;--text-primary:#ece9e0;--text-secondary:#a8aeb4;--text-dim:#70777f;--border-color:#262a30;--border-accent:#3a3426}
*{box-sizing:border-box;margin:0;padding:0;user-select:none}body{height:100vh;font-family:SymBody,'Roboto Condensed',sans-serif;background:transparent;display:flex;align-items:center;justify-content:center;overflow:hidden}.gmod-window{width:450px;background:var(--bg-panel);border:1px solid var(--border-color);box-shadow:0 8px 60px rgba(0,0,0,.85);display:flex;flex-direction:column;position:relative}.title-bar{height:38px;background:linear-gradient(90deg,#0b0e12,#12161c 60%,#0b0e12);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;padding:0 12px;gap:8px;flex-shrink:0}.server-name{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-cyan)}.breadcrumb{font-size:11px;color:var(--text-secondary);flex:1;text-align:right}.game-container{padding:20px;display:flex;flex-direction:column;gap:20px}.status-display{background:var(--bg-dark);border:1px solid var(--border-color);padding:15px;border-radius:0;text-align:center}.timer{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:32px;font-weight:700;color:var(--accent-red);text-shadow:0 0 10px rgba(231,76,60,.3)}.instruction{font-size:12px;color:var(--text-secondary);margin-top:5px;text-transform:uppercase;letter-spacing:1px}.button-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.game-btn{aspect-ratio:1;background:var(--bg-card);border:1px solid var(--border-accent);border-radius:0;cursor:pointer;display:flex;align-items:center;justify-content:center;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:24px;font-weight:700;color:var(--text-dim);transition:all .1s}.game-btn:hover{background:var(--bg-hover);border-color:var(--accent-cyan)}.game-btn:active{transform:scale(.95)}.game-btn.correct{background:rgba(46,204,113,.1);border-color:var(--accent-green);color:var(--accent-green)}.game-btn.wrong{background:rgba(231,76,60,.1);border-color:var(--accent-red);color:var(--accent-red)}.footer{padding:12px;border-top:1px solid var(--border-color);display:flex;justify-content:space-between;align-items:center}.progress-bar{height:4px;flex:1;background:var(--bg-dark);border-radius:0;margin:0 15px;overflow:hidden}.progress-fill{height:100%;width:0%;background:var(--accent-cyan);transition:width .3s ease}.attempt-count{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:11px;color:var(--text-dim)}.result-overlay{position:absolute;inset:0;background:rgba(10,12,16,.9);display:none;flex-direction:column;align-items:center;justify-content:center;z-index:10}.result-icon{font-size:48px;margin-bottom:10px}.result-title{font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-size:24px;font-weight:700;margin-bottom:20px}.btn-retry{padding:8px 24px;background:var(--accent-cyan);color:#000;border:none;border-radius:0;font-family:SymHead,BigNoodleTitling,'Bebas Neue',sans-serif;font-weight:700;cursor:pointer;text-transform:uppercase}
</style></head><body><div class="gmod-window"><div class="title-bar"><div class="server-name" id="title"></div><div class="breadcrumb"><span id="module-label"></span> <span>#AX-09</span></div></div><div class="game-container"><div class="status-display"><div id="timer" class="timer">00:10</div><div id="hint" class="instruction"></div></div><div class="button-grid" id="buttonGrid"></div></div><div class="footer"><div class="attempt-count"><span id="attempt-label"></span>: <span id="attempts">0</span></div><div class="progress-bar"><div id="progress" class="progress-fill"></div></div></div><div id="resultScreen" class="result-overlay"><div id="resultIcon" class="result-icon">✔️</div><div id="resultTitle" class="result-title"></div><button class="btn-retry" id="retryBtn" onclick="restartGame()"></button></div></div>
<script>
let sequence=[],playerIndex=0,timeLeft=10,timerInterval=null,isGameOver=false,attempts=0,TXT={};const grid=document.getElementById('buttonGrid'),timerEl=document.getElementById('timer'),progressEl=document.getElementById('progress'),attemptsEl=document.getElementById('attempts'),resultScreen=document.getElementById('resultScreen');
function t(k){return (TXT&&TXT[k])||k}
function setConfig(cfg){TXT=cfg.texts||{};timeLeft=Math.max(5,parseInt(cfg.timer||10));document.getElementById('title').innerText=t('btn_title');document.getElementById('module-label').innerText=t('btn_module');document.getElementById('hint').innerText=t('btn_hint');document.getElementById('attempt-label').innerText=t('btn_attempts');document.getElementById('retryBtn').innerText=t('btn_restart');startGame()}
function startGame(){isGameOver=false;playerIndex=0;attempts=0;attemptsEl.innerText='0';sequence=Array.from({length:9},(_,i)=>i+1).sort(()=>Math.random()-.5);resultScreen.style.display='none';grid.innerHTML='';progressEl.style.width='0%';sequence.forEach(num=>{const btn=document.createElement('div');btn.className='game-btn';btn.innerText=num;btn.onclick=()=>handlePress(btn,num);grid.appendChild(btn)});startTimer()}
function startTimer(){clearInterval(timerInterval);timerEl.innerText='00:'+(timeLeft<10?'0':'')+timeLeft;timerInterval=setInterval(()=>{timeLeft--;timerEl.innerText='00:'+(timeLeft<10?'0':'')+Math.max(0,timeLeft);if(timeLeft<=0)endGame(false)},1000)}
function handlePress(btn,num){if(isGameOver)return;if(num===playerIndex+1){playerIndex++;btn.classList.add('correct');btn.style.pointerEvents='none';progressEl.style.width=((playerIndex/9)*100)+'%';if(playerIndex===9)endGame(true)}else{btn.classList.add('wrong');attempts++;attemptsEl.innerText=attempts;setTimeout(()=>btn.classList.remove('wrong'),300);timeLeft=Math.max(0,timeLeft-1);timerEl.innerText='00:'+(timeLeft<10?'0':'')+timeLeft;if(timeLeft<=0)endGame(false)}}
function endGame(success){isGameOver=true;clearInterval(timerInterval);resultScreen.style.display='flex';const title=document.getElementById('resultTitle'),icon=document.getElementById('resultIcon');if(success){title.innerText=t('btn_access');title.style.color='var(--accent-green)';icon.innerText='✔️';if(window.gmod&&gmod.Success)gmod.Success()}else{title.innerText=t('btn_fail');title.style.color='var(--accent-red)';icon.innerText='⚠️';if(window.gmod&&gmod.Fail)gmod.Fail()}}
function restartGame(){if(window.gmod&&gmod.Abort)gmod.Abort()}
</script></body></html>]]

local function openLockpickMinigame(ent, data, lang)
    local texts = util.TableToJSON(MINI_I18N[lang] or MINI_I18N.en)
    local configJs = string.format(
        "setConfig({maxStages:%d, baseSpeed:%s, timer:%d, targetWidth:%d, texts:%s});",
        lockpickStages(data.difficulty),
        tostring(lockpickSpeed(data.difficulty)),
        math.max(5, tonumber(data.timer) or 30),
        ({easy = 44, medium = 36, hard = 30, expert = 24})[tostring(data.difficulty or 'medium')] or 36,
        texts
    )
    openDHTMLMinigame(LOCKPICK_HTML, ent, configJs)
end

local function openButtonsMinigame(ent, data, lang)
    local texts = util.TableToJSON(MINI_I18N[lang] or MINI_I18N.en)
    local configJs = string.format(
        "setConfig({timer:%d, texts:%s});",
        math.max(5, tonumber(data.timer) or buttonPanelTime(data.difficulty)),
        texts
    )
    openDHTMLMinigame(BUTTON_PANEL_HTML, ent, configJs)
end

local function openFallbackMinigame(ent, data)
    closeMG()
    MG = vgui.Create('DFrame')
    MG:SetTitle('Bomb Defusal - ' .. tostring(data.name or 'Bomb'))
    MG:SetSize(500, 220)
    MG:Center()
    MG:MakePopup()
    MG:ShowCloseButton(false)

    local body = vgui.Create('DPanel', MG)
    body:Dock(FILL)
    body:DockMargin(12, 12, 12, 12)
    body.Paint = function(_, w, h)
        surface.SetDrawColor(20, 20, 20, 240)
        surface.DrawRect(0, 0, w, h)
    end

    local lbl = vgui.Create('DLabel', body)
    lbl:Dock(TOP)
    lbl:DockMargin(10, 10, 10, 8)
    lbl:SetWrap(true)
    lbl:SetTall(80)
    lbl:SetText('Fallback minigame for: ' .. tostring(data.minigame) .. '\nDifficulty: ' .. tostring(data.difficulty) .. '\nTimer: ' .. tostring(data.timer) .. 's')

    local ok = vgui.Create('DButton', body)
    ok:Dock(TOP)
    ok:DockMargin(10, 8, 10, 8)
    ok:SetTall(34)
    ok:SetText('Success')
    ok.DoClick = function() sendResult(ent, true) end

    local fail = vgui.Create('DButton', body)
    fail:Dock(TOP)
    fail:DockMargin(10, 0, 10, 8)
    fail:SetTall(34)
    fail:SetText('Fail')
    fail.DoClick = function() sendResult(ent, false) end
end

net.Receive('grn_bombs_open_minigame', function()
    local ent = net.ReadEntity()
    local data = net.ReadTable() or {}
    local lang = tostring(GRN_Bombs.ClientLang or GRN_Bombs.Config.DefaultLanguage or 'en')
    local mg = tostring(data.minigame or 'wirecutting')

    if mg == 'wirecutting' then
        openWireCutting(ent, data, lang)
    elseif mg == 'code' then
        openCodeInput(ent, data, lang)
    elseif mg == 'sequence' then
        openSequenceMinigame(ent, data, lang)
    elseif mg == 'hackpad' then
        openHackpadMinigame(ent, data, lang)
    elseif mg == 'timer' then
        openTimerMinigame(ent, data, lang)
    elseif mg == 'lockpick' then
        openLockpickMinigame(ent, data, lang)
    elseif mg == 'buttons' then
        openButtonsMinigame(ent, data, lang)
    else
        openFallbackMinigame(ent, data)
    end
end)