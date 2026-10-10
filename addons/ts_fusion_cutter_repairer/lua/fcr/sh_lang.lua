FCR = FCR or {}
FCR.Languages = FCR.Languages or {}

local function normalize(code)
    code = string.lower(tostring(code or "en"))
    if code == "ua" then code = "uk" end
    return code
end

function FCR.RegisterLanguage(code, data)
    code = normalize(code)
    FCR.Languages[code] = table.Copy(data or {})
end

function FCR.GetLanguageCode(code)
    local cfg = FCR.Config or {}
    local resolved = normalize(code or cfg.Language or "en")
    if FCR.Languages[resolved] then return resolved end

    local fallback = normalize(cfg.FallbackLanguage or "en")
    if FCR.Languages[fallback] then return fallback end

    if FCR.Languages.en then return "en" end
    return next(FCR.Languages) or "en"
end

function FCR.GetLanguageTable(code)
    return FCR.Languages[FCR.GetLanguageCode(code)] or FCR.Languages.en or {}
end

function FCR.GetLanguageBundle(code)
    return table.Copy(FCR.GetLanguageTable(code))
end

function FCR.L(key, ...)
    local lang = FCR.GetLanguageTable()
    local fallback = FCR.Languages.en or {}
    local value = lang[key] or fallback[key] or key
    if select("#", ...) > 0 then
        local ok, result = pcall(string.format, value, ...)
        if ok then
            return result
        end
    end
    return value
end

function FCR.GetDifficultyLabel(id, fallbackName)
    local key = "difficulty_" .. string.lower(tostring(id or "medium"))
    local value = FCR.L(key)
    if value == key then
        return fallbackName or string.upper(tostring(id or "medium"))
    end
    return value
end

FCR.RegisterLanguage("en", {
    system_name = "REPAIR SYSTEM",
    no_target = "NO TARGET",
    kicker_protocol = "REPUBLIC ENGINEERING PROTOCOL",
    label_integrity = "INTEGRITY",
    label_status = "STATUS",
    label_phase = "PHASE",
    label_attempts = "ATTEMPTS",
    repair_protocol = "REPAIR PROTOCOL",
    phase_in_progress = "PHASE IN PROGRESS",
    syncing_subsystem = "SYNCING SUBSYSTEM",
    protocol_ready = "PROTOCOL ARMED. EXECUTE THE CURRENT TASK.",
    cancel_protocol = "CANCEL PROTOCOL",
    chip_status_active = "ACTIVE",
    chip_status_stable = "STABLE",

    phase1_overline = "THERMAL PROTOCOL · PHASE 1",
    phase1_title = "SEAL CRACKS",
    phase1_instruction = "HOLD CLICK AND GUIDE THE TIP THROUGH THE WELD CHANNEL WITHOUT LEAVING IT.",
    phase1_badge = "WELD CHANNEL",
    phase1_assist = "MANUAL PRECISION TRACKING",
    phase1_footer = "HOLD CLICK AND STAY INSIDE THE CHANNEL.",

    phase2_overline = "ENERGY PROTOCOL · PHASE 2",
    phase2_title = "REROUTE POWER",
    phase2_instruction = "ACTIVATE THE NODES IN ASCENDING ORDER. ONE MISTAKE RESTARTS THE ENTIRE PHASE.",
    phase2_badge = "NODE SEQUENCE",
    phase2_assist = "ASCENDING POWER REROUTE",
    phase2_footer = "CLICK THE NODES IN THE CORRECT ORDER.",

    phase3_overline = "THERMAL PROTOCOL · PHASE 3",
    phase3_title = "SPOT WELDING",
    phase3_instruction = "LOCK EACH THERMAL POINT BEFORE IT COLLAPSES. IF ONE EXPIRES, THE PHASE FAILS.",
    phase3_badge = "MICRO WELDING",
    phase3_assist = "CRITICAL POINT FIXATION",
    phase3_footer = "EACH POINT MUST BE LOCKED BEFORE IT COLLAPSES.",

    success_overline = "REPAIR COMPLETE",
    success_title = "PROTOCOL COMPLETE",
    success_instruction = "THE UNIT HAS BEEN SUCCESSFULLY RESTORED.",
    success_badge = "INTEGRITY RESTORED",
    success_assist = "SYSTEM STABLE",
    success_footer = "RESTORATION COMPLETED SUCCESSFULLY.",

    notice_protocol_failed = "PROTOCOL FAILURE",
    notice_phase_completed = "PHASE COMPLETE",
    notice_loading_next = "LOADING NEXT SUBSYSTEM",
    notice_repair_completed = "REPAIR COMPLETE",
    notice_integrity_restored = "INTEGRITY RESTORED TO MAXIMUM",
    notice_protocol_cancelled = "PROTOCOL CANCELLED",

    status_tactical_reset = "TACTICAL RESET",
    status_phase_transition = "PHASE TRANSITION",
    status_repair_completed = "REPAIR COMPLETE",

    reason_phase_fail = "PHASE FAILURE",
    reason_phase1_hold_lost = "WELDING INTERRUPTED",
    reason_phase1_out_of_channel = "YOU LEFT THE WELD CHANNEL",
    reason_phase2_wrong_node = "INCORRECT NODE",
    reason_phase3_timeout = "A THERMAL POINT EXPIRED",
    reason_phase3_bad_click = "INVALID POINT",
    reason_target_invalid = "INVALID TARGET",
    reason_vehicle_locked = "THE VEHICLE IS ALREADY IN USE",
    reason_session_active = "YOU ALREADY HAVE AN ACTIVE SESSION",
    reason_user_cancel = "CANCELLED BY THE USER",
    reason_cancelled = "CANCELLED",
    reason_repair_apply_failed = "FAILED TO APPLY THE REPAIR",
    reason_lost_distance = "TARGET OUT OF RANGE",
    reason_weapon_lost = "REPAIR TOOL LOST",
    reason_already_repaired = "TARGET ALREADY REPAIRED",
    reason_unknown = "UNKNOWN REASON",

    hud_state_critical = "CRITICAL",
    hud_state_damaged = "DAMAGED",
    hud_state_stable = "STABLE",
    hud_protocol_word = "PROTOCOL",
    hud_protocol_locked = "LOCKED",
    hud_protocol_available = "AVAILABLE",
    hud_integrity_short = "INT %.1f%%",
    hud_attempts = "ATTEMPTS",

    weapon_printname = "Fusion Cutter",
    weapon_instructions = "LMB: start vehicle repair protocol",

    difficulty_easy = "EASY",
    difficulty_medium = "MEDIUM",
    difficulty_hard = "HARD"
})

FCR.RegisterLanguage("es", {
    system_name = "SISTEMA DE REPARACIÓN",
    no_target = "SIN OBJETIVO",
    kicker_protocol = "PROTOCOLO DE INGENIERÍA DE LA REPÚBLICA",
    label_integrity = "INTEGRIDAD",
    label_status = "ESTADO",
    label_phase = "FASE",
    label_attempts = "INTENTOS",
    repair_protocol = "PROTOCOLO DE REPARACIÓN",
    phase_in_progress = "FASE EN CURSO",
    syncing_subsystem = "SINCRONIZANDO SUBSISTEMA",
    protocol_ready = "PROTOCOLO ARMADO. EJECUTÁ LA TAREA ACTUAL.",
    cancel_protocol = "CANCELAR PROTOCOLO",
    chip_status_active = "ACTIVO",
    chip_status_stable = "ESTABLE",

    phase1_overline = "PROTOCOLO TÉRMICO · FASE 1",
    phase1_title = "SELLAR GRIETAS",
    phase1_instruction = "MANTENÉ CLICK Y GUIÁ LA PUNTA POR EL CANAL DE SOLDADURA SIN SALIRTE.",
    phase1_badge = "CANAL DE SOLDADURA",
    phase1_assist = "SEGUIMIENTO MANUAL DE PRECISIÓN",
    phase1_footer = "MANTENÉ CLICK Y QUEDATE DENTRO DEL CANAL.",

    phase2_overline = "PROTOCOLO DE ENERGÍA · FASE 2",
    phase2_title = "REDIRIGIR ENERGÍA",
    phase2_instruction = "ACTIVÁ LOS NODOS EN ORDEN ASCENDENTE. UN ERROR REINICIA TODA LA FASE.",
    phase2_badge = "SECUENCIA DE NODOS",
    phase2_assist = "REDIRECCIÓN ASCENDENTE DE ENERGÍA",
    phase2_footer = "HACÉ CLICK EN LOS NODOS EN EL ORDEN CORRECTO.",

    phase3_overline = "PROTOCOLO TÉRMICO · FASE 3",
    phase3_title = "SOLDADURA POR PUNTOS",
    phase3_instruction = "FIJÁ CADA PUNTO TÉRMICO ANTES DE QUE COLAPSE. SI UNO EXPIRA, LA FASE FALLA.",
    phase3_badge = "MICRO SOLDADURA",
    phase3_assist = "FIJACIÓN DE PUNTOS CRÍTICOS",
    phase3_footer = "CADA PUNTO DEBE FIJARSE ANTES DE QUE COLAPSE.",

    success_overline = "REPARACIÓN COMPLETADA",
    success_title = "PROTOCOLO FINALIZADO",
    success_instruction = "LA UNIDAD FUE RESTAURADA CORRECTAMENTE.",
    success_badge = "INTEGRIDAD RESTAURADA",
    success_assist = "SISTEMA ESTABLE",
    success_footer = "RESTAURACIÓN COMPLETADA CORRECTAMENTE.",

    notice_protocol_failed = "FALLO DEL PROTOCOLO",
    notice_phase_completed = "FASE COMPLETADA",
    notice_loading_next = "CARGANDO EL SIGUIENTE SUBSISTEMA",
    notice_repair_completed = "REPARACIÓN COMPLETADA",
    notice_integrity_restored = "INTEGRIDAD RESTAURADA AL MÁXIMO",
    notice_protocol_cancelled = "PROTOCOLO CANCELADO",

    status_tactical_reset = "REINICIO TÁCTICO",
    status_phase_transition = "TRANSICIÓN DE FASE",
    status_repair_completed = "REPARACIÓN COMPLETADA",

    reason_phase_fail = "FALLO DE FASE",
    reason_phase1_hold_lost = "SE INTERRUMPIÓ LA SOLDADURA",
    reason_phase1_out_of_channel = "SALISTE DEL CANAL DE SOLDADURA",
    reason_phase2_wrong_node = "NODO INCORRECTO",
    reason_phase3_timeout = "UN PUNTO TÉRMICO EXPIRÓ",
    reason_phase3_bad_click = "PUNTO INVÁLIDO",
    reason_target_invalid = "OBJETIVO INVÁLIDO",
    reason_vehicle_locked = "EL VEHÍCULO YA ESTÁ EN USO",
    reason_session_active = "YA TENÉS UNA SESIÓN ACTIVA",
    reason_user_cancel = "CANCELADO POR EL USUARIO",
    reason_cancelled = "CANCELADO",
    reason_repair_apply_failed = "NO SE PUDO APLICAR LA REPARACIÓN",
    reason_lost_distance = "OBJETIVO FUERA DE ALCANCE",
    reason_weapon_lost = "SE PERDIÓ LA HERRAMIENTA DE REPARACIÓN",
    reason_already_repaired = "EL OBJETIVO YA ESTÁ REPARADO",
    reason_unknown = "MOTIVO DESCONOCIDO",

    hud_state_critical = "CRÍTICO",
    hud_state_damaged = "DAÑADO",
    hud_state_stable = "ESTABLE",
    hud_protocol_word = "PROTOCOLO",
    hud_protocol_locked = "BLOQUEADO",
    hud_protocol_available = "DISPONIBLE",
    hud_integrity_short = "INT %.1f%%",
    hud_attempts = "INTENTOS",

    weapon_printname = "Fusion Cutter",
    weapon_instructions = "LMB: iniciar protocolo de reparación de vehículos",

    difficulty_easy = "FÁCIL",
    difficulty_medium = "INTERMEDIO",
    difficulty_hard = "DIFÍCIL"
})

FCR.RegisterLanguage("ru", {
    system_name = "СИСТЕМА РЕМОНТА",
    no_target = "НЕТ ЦЕЛИ",
    kicker_protocol = "ИНЖЕНЕРНЫЙ ПРОТОКОЛ РЕСПУБЛИКИ",
    label_integrity = "ЦЕЛОСТНОСТЬ",
    label_status = "СТАТУС",
    label_phase = "ЭТАП",
    label_attempts = "ПОПЫТКИ",
    repair_protocol = "ПРОТОКОЛ РЕМОНТА",
    phase_in_progress = "ЭТАП В РАБОТЕ",
    syncing_subsystem = "СИНХРОНИЗАЦИЯ ПОДСИСТЕМЫ",
    protocol_ready = "ПРОТОКОЛ ГОТОВ. ВЫПОЛНИТЕ ТЕКУЩУЮ ЗАДАЧУ.",
    cancel_protocol = "ОТМЕНИТЬ ПРОТОКОЛ",
    chip_status_active = "АКТИВЕН",
    chip_status_stable = "СТАБИЛЬНО",

    phase1_overline = "ТЕРМИЧЕСКИЙ ПРОТОКОЛ · ЭТАП 1",
    phase1_title = "ГЕРМЕТИЗАЦИЯ ТРЕЩИН",
    phase1_instruction = "УДЕРЖИВАЙТЕ КНОПКУ И ВЕДИТЕ НАКОНЕЧНИК ПО СВАРОЧНОМУ КАНАЛУ, НЕ ВЫХОДЯ ИЗ НЕГО.",
    phase1_badge = "СВАРОЧНЫЙ КАНАЛ",
    phase1_assist = "РУЧНОЕ ТОЧНОЕ НАВЕДЕНИЕ",
    phase1_footer = "УДЕРЖИВАЙТЕ КНОПКУ И ОСТАВАЙТЕСЬ ВНУТРИ КАНАЛА.",

    phase2_overline = "ЭНЕРГЕТИЧЕСКИЙ ПРОТОКОЛ · ЭТАП 2",
    phase2_title = "ПЕРЕНАПРАВЛЕНИЕ ЭНЕРГИИ",
    phase2_instruction = "АКТИВИРУЙТЕ УЗЛЫ ПО ВОЗРАСТАНИЮ. ОДНА ОШИБКА ПЕРЕЗАПУСКАЕТ ВСЮ ФАЗУ.",
    phase2_badge = "ПОСЛЕДОВАТЕЛЬНОСТЬ УЗЛОВ",
    phase2_assist = "ВОСХОДЯЩЕЕ ПЕРЕНАПРАВЛЕНИЕ ЭНЕРГИИ",
    phase2_footer = "НАЖИМАЙТЕ УЗЛЫ В ПРАВИЛЬНОМ ПОРЯДКЕ.",

    phase3_overline = "ТЕРМИЧЕСКИЙ ПРОТОКОЛ · ЭТАП 3",
    phase3_title = "ТОЧЕЧНАЯ СВАРКА",
    phase3_instruction = "ЗАФИКСИРУЙТЕ КАЖДУЮ ТЕПЛОВУЮ ТОЧКУ ДО ЕЁ КОЛЛАПСА. ЕСЛИ ОДНА ИСЧЕЗНЕТ, ФАЗА ПРОВАЛЕНА.",
    phase3_badge = "МИКРОСВАРКА",
    phase3_assist = "ФИКСАЦИЯ КРИТИЧЕСКИХ ТОЧЕК",
    phase3_footer = "КАЖДАЯ ТОЧКА ДОЛЖНА БЫТЬ ЗАФИКСИРОВАНА ДО КОЛЛАПСА.",

    success_overline = "РЕМОНТ ЗАВЕРШЁН",
    success_title = "ПРОТОКОЛ ЗАВЕРШЁН",
    success_instruction = "УЗЕЛ УСПЕШНО ВОССТАНОВЛЕН.",
    success_badge = "ЦЕЛОСТНОСТЬ ВОССТАНОВЛЕНА",
    success_assist = "СИСТЕМА СТАБИЛЬНА",
    success_footer = "ВОССТАНОВЛЕНИЕ УСПЕШНО ЗАВЕРШЕНО.",

    notice_protocol_failed = "СБОЙ ПРОТОКОЛА",
    notice_phase_completed = "ЭТАП ЗАВЕРШЁН",
    notice_loading_next = "ЗАГРУЗКА СЛЕДУЮЩЕЙ ПОДСИСТЕМЫ",
    notice_repair_completed = "РЕМОНТ ЗАВЕРШЁН",
    notice_integrity_restored = "ЦЕЛОСТНОСТЬ ВОССТАНОВЛЕНА ДО МАКСИМУМА",
    notice_protocol_cancelled = "ПРОТОКОЛ ОТМЕНЁН",

    status_tactical_reset = "ТАКТИЧЕСКИЙ СБРОС",
    status_phase_transition = "ПЕРЕХОД ЭТАПА",
    status_repair_completed = "РЕМОНТ ЗАВЕРШЁН",

    reason_phase_fail = "СБОЙ ЭТАПА",
    reason_phase1_hold_lost = "СВАРКА ПРЕРВАНА",
    reason_phase1_out_of_channel = "ВЫ ВЫШЛИ ИЗ СВАРОЧНОГО КАНАЛА",
    reason_phase2_wrong_node = "НЕВЕРНЫЙ УЗЕЛ",
    reason_phase3_timeout = "ТЕПЛОВАЯ ТОЧКА ИСЧЕЗЛА",
    reason_phase3_bad_click = "НЕДОПУСТИМАЯ ТОЧКА",
    reason_target_invalid = "НЕДОПУСТИМАЯ ЦЕЛЬ",
    reason_vehicle_locked = "ТЕХНИКА УЖЕ ИСПОЛЬЗУЕТСЯ",
    reason_session_active = "У ВАС УЖЕ ЕСТЬ АКТИВНАЯ СЕССИЯ",
    reason_user_cancel = "ОТМЕНЕНО ПОЛЬЗОВАТЕЛЕМ",
    reason_cancelled = "ОТМЕНЕНО",
    reason_repair_apply_failed = "НЕ УДАЛОСЬ ПРИМЕНИТЬ РЕМОНТ",
    reason_lost_distance = "ЦЕЛЬ ВНЕ ДИАПАЗОНА",
    reason_weapon_lost = "ИНСТРУМЕНТ РЕМОНТА ПОТЕРЯН",
    reason_already_repaired = "ЦЕЛЬ УЖЕ ОТРЕМОНТИРОВАНА",
    reason_unknown = "НЕИЗВЕСТНАЯ ПРИЧИНА",

    hud_state_critical = "КРИТИЧНО",
    hud_state_damaged = "ПОВРЕЖДЁН",
    hud_state_stable = "СТАБИЛЕН",
    hud_protocol_word = "ПРОТОКОЛ",
    hud_protocol_locked = "ЗАБЛОКИРОВАН",
    hud_protocol_available = "ДОСТУПЕН",
    hud_integrity_short = "ЦЕЛ %.1f%%",
    hud_attempts = "ПОПЫТКИ",

    weapon_printname = "Fusion Cutter",
    weapon_instructions = "ЛКМ: начать протокол ремонта техники",

    difficulty_easy = "ЛЁГКИЙ",
    difficulty_medium = "СРЕДНИЙ",
    difficulty_hard = "СЛОЖНЫЙ"
})

FCR.RegisterLanguage("de", {
    system_name = "REPARATURSYSTEM",
    no_target = "KEIN ZIEL",
    kicker_protocol = "REPUBLIK-INGENIEURPROTOKOLL",
    label_integrity = "INTEGRITÄT",
    label_status = "STATUS",
    label_phase = "PHASE",
    label_attempts = "VERSUCHE",
    repair_protocol = "REPARATURPROTOKOLL",
    phase_in_progress = "PHASE AKTIV",
    syncing_subsystem = "SUBSYSTEM WIRD SYNCHRONISIERT",
    protocol_ready = "PROTOKOLL BEREIT. FÜHRE DIE AKTUELLE AUFGABE AUS.",
    cancel_protocol = "PROTOKOLL ABBRECHEN",
    chip_status_active = "AKTIV",
    chip_status_stable = "STABIL",

    phase1_overline = "THERMALPROTOKOLL · PHASE 1",
    phase1_title = "RISSE VERSIEGELN",
    phase1_instruction = "HALTE DIE TASTE GEDRÜCKT UND FÜHRE DIE SPITZE DURCH DEN SCHWEISSKANAL, OHNE IHN ZU VERLASSEN.",
    phase1_badge = "SCHWEISSKANAL",
    phase1_assist = "MANUELLE PRÄZISIONSFÜHRUNG",
    phase1_footer = "HALTE GEDRÜCKT UND BLEIBE IM KANAL.",

    phase2_overline = "ENERGIEPROTOKOLL · PHASE 2",
    phase2_title = "ENERGIE UMLENKEN",
    phase2_instruction = "AKTIVIERE DIE KNOTEN IN AUFSTEIGENDER REIHENFOLGE. EIN FEHLER SETZT DIE GESAMTE PHASE ZURÜCK.",
    phase2_badge = "KNOTENFOLGE",
    phase2_assist = "AUFSTEIGENDE ENERGIEUMLENKUNG",
    phase2_footer = "KLICKE DIE KNOTEN IN DER RICHTIGEN REIHENFOLGE.",

    phase3_overline = "THERMALPROTOKOLL · PHASE 3",
    phase3_title = "PUNKTSCHWEISSEN",
    phase3_instruction = "SICHERE JEDEN THERMOPUNKT, BEVOR ER KOLLABIERT. WENN EINER ABLÄUFT, SCHLÄGT DIE PHASE FEHL.",
    phase3_badge = "MIKROSCHWEISSEN",
    phase3_assist = "FIXIERUNG KRITISCHER PUNKTE",
    phase3_footer = "JEDER PUNKT MUSS GESICHERT WERDEN, BEVOR ER KOLLABIERT.",

    success_overline = "REPARATUR ABGESCHLOSSEN",
    success_title = "PROTOKOLL ABGESCHLOSSEN",
    success_instruction = "DIE EINHEIT WURDE ERFOLGREICH WIEDERHERGESTELLT.",
    success_badge = "INTEGRITÄT WIEDERHERGESTELLT",
    success_assist = "SYSTEM STABIL",
    success_footer = "WIEDERHERSTELLUNG ERFOLGREICH ABGESCHLOSSEN.",

    notice_protocol_failed = "PROTOKOLLFEHLER",
    notice_phase_completed = "PHASE ABGESCHLOSSEN",
    notice_loading_next = "NÄCHSTES SUBSYSTEM WIRD GELADEN",
    notice_repair_completed = "REPARATUR ABGESCHLOSSEN",
    notice_integrity_restored = "INTEGRITÄT AUF MAXIMUM WIEDERHERGESTELLT",
    notice_protocol_cancelled = "PROTOKOLL ABGEBROCHEN",

    status_tactical_reset = "TAKTISCHER RESET",
    status_phase_transition = "PHASENWECHSEL",
    status_repair_completed = "REPARATUR ABGESCHLOSSEN",

    reason_phase_fail = "PHASENFEHLER",
    reason_phase1_hold_lost = "SCHWEISSVORGANG UNTERBROCHEN",
    reason_phase1_out_of_channel = "DU HAST DEN SCHWEISSKANAL VERLASSEN",
    reason_phase2_wrong_node = "FALSCHER KNOTEN",
    reason_phase3_timeout = "EIN THERMOPUNKT IST ABGELAUFEN",
    reason_phase3_bad_click = "UNGÜLTIGER PUNKT",
    reason_target_invalid = "UNGÜLTIGES ZIEL",
    reason_vehicle_locked = "DAS FAHRZEUG WIRD BEREITS VERWENDET",
    reason_session_active = "DU HAST BEREITS EINE AKTIVE SITZUNG",
    reason_user_cancel = "VOM BENUTZER ABGEBROCHEN",
    reason_cancelled = "ABGEBROCHEN",
    reason_repair_apply_failed = "REPARATUR KONNTE NICHT ANGEWENDET WERDEN",
    reason_lost_distance = "ZIEL AUSSER REICHWEITE",
    reason_weapon_lost = "REPARATURWERKZEUG VERLOREN",
    reason_already_repaired = "ZIEL BEREITS REPARIERT",
    reason_unknown = "UNBEKANNTER GRUND",

    hud_state_critical = "KRITISCH",
    hud_state_damaged = "BESCHÄDIGT",
    hud_state_stable = "STABIL",
    hud_protocol_word = "PROTOKOLL",
    hud_protocol_locked = "GESPERRT",
    hud_protocol_available = "VERFÜGBAR",
    hud_integrity_short = "INT %.1f%%",
    hud_attempts = "VERSUCHE",

    weapon_printname = "Fusion Cutter",
    weapon_instructions = "LMB: Fahrzeug-Reparaturprotokoll starten",

    difficulty_easy = "LEICHT",
    difficulty_medium = "MITTEL",
    difficulty_hard = "SCHWER"
})

FCR.RegisterLanguage("fr", {
    system_name = "SYSTÈME DE RÉPARATION",
    no_target = "AUCUNE CIBLE",
    kicker_protocol = "PROTOCOLE D'INGÉNIERIE DE LA RÉPUBLIQUE",
    label_integrity = "INTÉGRITÉ",
    label_status = "STATUT",
    label_phase = "PHASE",
    label_attempts = "ESSAIS",
    repair_protocol = "PROTOCOLE DE RÉPARATION",
    phase_in_progress = "PHASE EN COURS",
    syncing_subsystem = "SYNCHRONISATION DU SOUS-SYSTÈME",
    protocol_ready = "PROTOCOLE ARMÉ. EXÉCUTEZ LA TÂCHE ACTUELLE.",
    cancel_protocol = "ANNULER LE PROTOCOLE",
    chip_status_active = "ACTIF",
    chip_status_stable = "STABLE",

    phase1_overline = "PROTOCOLE THERMIQUE · PHASE 1",
    phase1_title = "SCELLER LES FISSURES",
    phase1_instruction = "MAINTENEZ LE CLIC ET GUIDE LA POINTE À TRAVERS LE CANAL DE SOUDURE SANS EN SORTIR.",
    phase1_badge = "CANAL DE SOUDURE",
    phase1_assist = "SUIVI MANUEL DE PRÉCISION",
    phase1_footer = "MAINTENEZ LE CLIC ET RESTEZ DANS LE CANAL.",

    phase2_overline = "PROTOCOLE ÉNERGÉTIQUE · PHASE 2",
    phase2_title = "REROUTER L'ÉNERGIE",
    phase2_instruction = "ACTIVEZ LES NŒUDS DANS L'ORDRE CROISSANT. UNE ERREUR RÉINITIALISE TOUTE LA PHASE.",
    phase2_badge = "SÉQUENCE DES NŒUDS",
    phase2_assist = "REDIRECTION ÉNERGÉTIQUE ASCENDANTE",
    phase2_footer = "CLIQUEZ SUR LES NŒUDS DANS LE BON ORDRE.",

    phase3_overline = "PROTOCOLE THERMIQUE · PHASE 3",
    phase3_title = "SOUDURE PAR POINTS",
    phase3_instruction = "VERROUILLEZ CHAQUE POINT THERMIQUE AVANT SON EFFONDREMENT. SI L'UN EXPIRE, LA PHASE ÉCHOUE.",
    phase3_badge = "MICRO-SOUDURE",
    phase3_assist = "FIXATION DES POINTS CRITIQUES",
    phase3_footer = "CHAQUE POINT DOIT ÊTRE VERROUILLÉ AVANT SON EFFONDREMENT.",

    success_overline = "RÉPARATION TERMINÉE",
    success_title = "PROTOCOLE TERMINÉ",
    success_instruction = "L'UNITÉ A ÉTÉ RESTAURÉE AVEC SUCCÈS.",
    success_badge = "INTÉGRITÉ RESTAURÉE",
    success_assist = "SYSTÈME STABLE",
    success_footer = "RESTAURATION TERMINÉE AVEC SUCCÈS.",

    notice_protocol_failed = "ÉCHEC DU PROTOCOLE",
    notice_phase_completed = "PHASE TERMINÉE",
    notice_loading_next = "CHARGEMENT DU SOUS-SYSTÈME SUIVANT",
    notice_repair_completed = "RÉPARATION TERMINÉE",
    notice_integrity_restored = "INTÉGRITÉ RESTAURÉE AU MAXIMUM",
    notice_protocol_cancelled = "PROTOCOLE ANNULÉ",

    status_tactical_reset = "RÉINITIALISATION TACTIQUE",
    status_phase_transition = "TRANSITION DE PHASE",
    status_repair_completed = "RÉPARATION TERMINÉE",

    reason_phase_fail = "ÉCHEC DE LA PHASE",
    reason_phase1_hold_lost = "SOUDURE INTERROMPUE",
    reason_phase1_out_of_channel = "VOUS AVEZ QUITTÉ LE CANAL DE SOUDURE",
    reason_phase2_wrong_node = "NŒUD INCORRECT",
    reason_phase3_timeout = "UN POINT THERMIQUE A EXPIRÉ",
    reason_phase3_bad_click = "POINT INVALIDE",
    reason_target_invalid = "CIBLE INVALIDE",
    reason_vehicle_locked = "LE VÉHICULE EST DÉJÀ UTILISÉ",
    reason_session_active = "VOUS AVEZ DÉJÀ UNE SESSION ACTIVE",
    reason_user_cancel = "ANNULÉ PAR L'UTILISATEUR",
    reason_cancelled = "ANNULÉ",
    reason_repair_apply_failed = "IMPOSSIBLE D'APPLIQUER LA RÉPARATION",
    reason_lost_distance = "CIBLE HORS DE PORTÉE",
    reason_weapon_lost = "OUTIL DE RÉPARATION PERDU",
    reason_already_repaired = "CIBLE DÉJÀ RÉPARÉE",
    reason_unknown = "RAISON INCONNUE",

    hud_state_critical = "CRITIQUE",
    hud_state_damaged = "ENDOMMAGÉ",
    hud_state_stable = "STABLE",
    hud_protocol_word = "PROTOCOLE",
    hud_protocol_locked = "VERROUILLÉ",
    hud_protocol_available = "DISPONIBLE",
    hud_integrity_short = "INT %.1f%%",
    hud_attempts = "ESSAIS",

    weapon_printname = "Fusion Cutter",
    weapon_instructions = "LMB : démarrer le protocole de réparation de véhicule",

    difficulty_easy = "FACILE",
    difficulty_medium = "MOYEN",
    difficulty_hard = "DIFFICILE"
})

FCR.RegisterLanguage("pt", {
    system_name = "SISTEMA DE REPARO",
    no_target = "SEM ALVO",
    kicker_protocol = "PROTOCOLO DE ENGENHARIA DA REPÚBLICA",
    label_integrity = "INTEGRIDADE",
    label_status = "STATUS",
    label_phase = "FASE",
    label_attempts = "TENTATIVAS",
    repair_protocol = "PROTOCOLO DE REPARO",
    phase_in_progress = "FASE EM ANDAMENTO",
    syncing_subsystem = "SINCRONIZANDO SUBSISTEMA",
    protocol_ready = "PROTOCOLO ARMADO. EXECUTE A TAREFA ATUAL.",
    cancel_protocol = "CANCELAR PROTOCOLO",
    chip_status_active = "ATIVO",
    chip_status_stable = "ESTÁVEL",

    phase1_overline = "PROTOCOLO TÉRMICO · FASE 1",
    phase1_title = "SELAR FISSURAS",
    phase1_instruction = "MANTENHA O CLIQUE E GUIE A PONTA PELO CANAL DE SOLDA SEM SAIR DELE.",
    phase1_badge = "CANAL DE SOLDA",
    phase1_assist = "RASTREAMENTO MANUAL DE PRECISÃO",
    phase1_footer = "MANTENHA O CLIQUE E PERMANEÇA DENTRO DO CANAL.",

    phase2_overline = "PROTOCOLO DE ENERGIA · FASE 2",
    phase2_title = "REDIRECIONAR ENERGIA",
    phase2_instruction = "ATIVE OS NÓS EM ORDEM CRESCENTE. UM ERRO REINICIA TODA A FASE.",
    phase2_badge = "SEQUÊNCIA DE NÓS",
    phase2_assist = "REDIRECIONAMENTO ASCENDENTE DE ENERGIA",
    phase2_footer = "CLIQUE NOS NÓS NA ORDEM CORRETA.",

    phase3_overline = "PROTOCOLO TÉRMICO · FASE 3",
    phase3_title = "SOLDA POR PONTOS",
    phase3_instruction = "TRAVE CADA PONTO TÉRMICO ANTES QUE ELE COLAPSE. SE UM EXPIRAR, A FASE FALHA.",
    phase3_badge = "MICRO SOLDA",
    phase3_assist = "FIXAÇÃO DE PONTOS CRÍTICOS",
    phase3_footer = "CADA PONTO DEVE SER TRAVADO ANTES DE COLAPSAR.",

    success_overline = "REPARO CONCLUÍDO",
    success_title = "PROTOCOLO FINALIZADO",
    success_instruction = "A UNIDADE FOI RESTAURADA COM SUCESSO.",
    success_badge = "INTEGRIDADE RESTAURADA",
    success_assist = "SISTEMA ESTÁVEL",
    success_footer = "RESTAURAÇÃO CONCLUÍDA COM SUCESSO.",

    notice_protocol_failed = "FALHA NO PROTOCOLO",
    notice_phase_completed = "FASE CONCLUÍDA",
    notice_loading_next = "CARREGANDO O PRÓXIMO SUBSISTEMA",
    notice_repair_completed = "REPARO CONCLUÍDO",
    notice_integrity_restored = "INTEGRIDADE RESTAURADA AO MÁXIMO",
    notice_protocol_cancelled = "PROTOCOLO CANCELADO",

    status_tactical_reset = "REINÍCIO TÁTICO",
    status_phase_transition = "TRANSIÇÃO DE FASE",
    status_repair_completed = "REPARO CONCLUÍDO",

    reason_phase_fail = "FALHA DE FASE",
    reason_phase1_hold_lost = "SOLDA INTERROMPIDA",
    reason_phase1_out_of_channel = "VOCÊ SAIU DO CANAL DE SOLDA",
    reason_phase2_wrong_node = "NÓ INCORRETO",
    reason_phase3_timeout = "UM PONTO TÉRMICO EXPIROU",
    reason_phase3_bad_click = "PONTO INVÁLIDO",
    reason_target_invalid = "ALVO INVÁLIDO",
    reason_vehicle_locked = "O VEÍCULO JÁ ESTÁ EM USO",
    reason_session_active = "VOCÊ JÁ POSSUI UMA SESSÃO ATIVA",
    reason_user_cancel = "CANCELADO PELO USUÁRIO",
    reason_cancelled = "CANCELADO",
    reason_repair_apply_failed = "NÃO FOI POSSÍVEL APLICAR O REPARO",
    reason_lost_distance = "ALVO FORA DE ALCANCE",
    reason_weapon_lost = "FERRAMENTA DE REPARO PERDIDA",
    reason_already_repaired = "ALVO JÁ REPARADO",
    reason_unknown = "MOTIVO DESCONHECIDO",

    hud_state_critical = "CRÍTICO",
    hud_state_damaged = "DANIFICADO",
    hud_state_stable = "ESTÁVEL",
    hud_protocol_word = "PROTOCOLO",
    hud_protocol_locked = "BLOQUEADO",
    hud_protocol_available = "DISPONÍVEL",
    hud_integrity_short = "INT %.1f%%",
    hud_attempts = "TENTATIVAS",

    weapon_printname = "Fusion Cutter",
    weapon_instructions = "LMB: iniciar protocolo de reparo de veículos",

    difficulty_easy = "FÁCIL",
    difficulty_medium = "MÉDIO",
    difficulty_hard = "DIFÍCIL"
})

FCR.RegisterLanguage("uk", {
    system_name = "СИСТЕМА РЕМОНТУ",
    no_target = "НЕМАЄ ЦІЛІ",
    kicker_protocol = "ІНЖЕНЕРНИЙ ПРОТОКОЛ РЕСПУБЛІКИ",
    label_integrity = "ЦІЛІСНІСТЬ",
    label_status = "СТАТУС",
    label_phase = "ФАЗА",
    label_attempts = "СПРОБИ",
    repair_protocol = "ПРОТОКОЛ РЕМОНТУ",
    phase_in_progress = "ФАЗА В ПРОЦЕСІ",
    syncing_subsystem = "СИНХРОНІЗАЦІЯ ПІДСИСТЕМИ",
    protocol_ready = "ПРОТОКОЛ ГОТОВИЙ. ВИКОНАЙТЕ ПОТОЧНЕ ЗАВДАННЯ.",
    cancel_protocol = "СКАСУВАТИ ПРОТОКОЛ",
    chip_status_active = "АКТИВНИЙ",
    chip_status_stable = "СТАБІЛЬНО",

    phase1_overline = "ТЕРМАЛЬНИЙ ПРОТОКОЛ · ФАЗА 1",
    phase1_title = "ГЕРМЕТИЗУВАТИ ТРІЩИНИ",
    phase1_instruction = "УТРИМУЙТЕ КЛІК І ВЕДІТЬ НАКОНЕЧНИК ПО КАНАЛУ ЗВАРЮВАННЯ, НЕ ВИХОДЯЧИ З НЬОГО.",
    phase1_badge = "КАНАЛ ЗВАРЮВАННЯ",
    phase1_assist = "РУЧНЕ ТОЧНЕ ВЕДЕННЯ",
    phase1_footer = "УТРИМУЙТЕ КЛІК І ЗАЛИШАЙТЕСЯ ВСЕРЕДИНІ КАНАЛУ.",

    phase2_overline = "ЕНЕРГЕТИЧНИЙ ПРОТОКОЛ · ФАЗА 2",
    phase2_title = "ПЕРЕНАПРАВИТИ ЕНЕРГІЮ",
    phase2_instruction = "АКТИВУЙТЕ ВУЗЛИ У ЗРОСТАЮЧОМУ ПОРЯДКУ. ОДНА ПОМИЛКА ПЕРЕЗАПУСКАЄ ВСЮ ФАЗУ.",
    phase2_badge = "ПОСЛІДОВНІСТЬ ВУЗЛІВ",
    phase2_assist = "ВИСХІДНЕ ПЕРЕНАПРАВЛЕННЯ ЕНЕРГІЇ",
    phase2_footer = "НАТИСКАЙТЕ ВУЗЛИ У ПРАВИЛЬНОМУ ПОРЯДКУ.",

    phase3_overline = "ТЕРМАЛЬНИЙ ПРОТОКОЛ · ФАЗА 3",
    phase3_title = "ТОЧКОВЕ ЗВАРЮВАННЯ",
    phase3_instruction = "ЗАФІКСУЙТЕ КОЖНУ ТЕПЛОВУ ТОЧКУ ДО ЇЇ КОЛАПСУ. ЯКЩО ОДНА ЗНИКНЕ, ФАЗА ПРОВАЛЕНА.",
    phase3_badge = "МІКРОЗВАРЮВАННЯ",
    phase3_assist = "ФІКСАЦІЯ КРИТИЧНИХ ТОЧОК",
    phase3_footer = "КОЖНУ ТОЧКУ ПОТРІБНО ЗАФІКСУВАТИ ДО ЇЇ КОЛАПСУ.",

    success_overline = "РЕМОНТ ЗАВЕРШЕНО",
    success_title = "ПРОТОКОЛ ЗАВЕРШЕНО",
    success_instruction = "МОДУЛЬ УСПІШНО ВІДНОВЛЕНО.",
    success_badge = "ЦІЛІСНІСТЬ ВІДНОВЛЕНО",
    success_assist = "СИСТЕМА СТАБІЛЬНА",
    success_footer = "ВІДНОВЛЕННЯ УСПІШНО ЗАВЕРШЕНО.",

    notice_protocol_failed = "ЗБІЙ ПРОТОКОЛУ",
    notice_phase_completed = "ФАЗУ ЗАВЕРШЕНО",
    notice_loading_next = "ЗАВАНТАЖУЄТЬСЯ НАСТУПНА ПІДСИСТЕМА",
    notice_repair_completed = "РЕМОНТ ЗАВЕРШЕНО",
    notice_integrity_restored = "ЦІЛІСНІСТЬ ВІДНОВЛЕНО ДО МАКСИМУМУ",
    notice_protocol_cancelled = "ПРОТОКОЛ СКАСОВАНО",

    status_tactical_reset = "ТАКТИЧНЕ СКИДАННЯ",
    status_phase_transition = "ПЕРЕХІД ФАЗИ",
    status_repair_completed = "РЕМОНТ ЗАВЕРШЕНО",

    reason_phase_fail = "ЗБІЙ ФАЗИ",
    reason_phase1_hold_lost = "ЗВАРЮВАННЯ ПЕРЕРВАНО",
    reason_phase1_out_of_channel = "ВИ ВИЙШЛИ З КАНАЛУ ЗВАРЮВАННЯ",
    reason_phase2_wrong_node = "НЕПРАВИЛЬНИЙ ВУЗОЛ",
    reason_phase3_timeout = "ТЕПЛОВА ТОЧКА ЗНИКЛА",
    reason_phase3_bad_click = "НЕДІЙСНА ТОЧКА",
    reason_target_invalid = "НЕДІЙСНА ЦІЛЬ",
    reason_vehicle_locked = "ТЕХНІКА ВЖЕ ВИКОРИСТОВУЄТЬСЯ",
    reason_session_active = "У ВАС ВЖЕ Є АКТИВНА СЕСІЯ",
    reason_user_cancel = "СКАСОВАНО КОРИСТУВАЧЕМ",
    reason_cancelled = "СКАСОВАНО",
    reason_repair_apply_failed = "НЕ ВДАЛОСЯ ЗАСТОСУВАТИ РЕМОНТ",
    reason_lost_distance = "ЦІЛЬ ПОЗА МЕЖАМИ ДОСЯЖНОСТІ",
    reason_weapon_lost = "ІНСТРУМЕНТ РЕМОНТУ ВТРАЧЕНО",
    reason_already_repaired = "ЦІЛЬ ВЖЕ ВІДРЕМОНТОВАНА",
    reason_unknown = "НЕВІДОМА ПРИЧИНА",

    hud_state_critical = "КРИТИЧНО",
    hud_state_damaged = "ПОШКОДЖЕНО",
    hud_state_stable = "СТАБІЛЬНО",
    hud_protocol_word = "ПРОТОКОЛ",
    hud_protocol_locked = "ЗАБЛОКОВАНО",
    hud_protocol_available = "ДОСТУПНО",
    hud_integrity_short = "ЦІЛ %.1f%%",
    hud_attempts = "СПРОБИ",

    weapon_printname = "Fusion Cutter",
    weapon_instructions = "ЛКМ: розпочати протокол ремонту техніки",

    difficulty_easy = "ЛЕГКИЙ",
    difficulty_medium = "СЕРЕДНІЙ",
    difficulty_hard = "СКЛАДНИЙ"
})
