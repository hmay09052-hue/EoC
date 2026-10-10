local KMS = KrakensMedical

-- Star Wars pharmacy, built from the 501st "Medizinisches Handbuch" (medication list).
-- The handbook's "Person" column is intentionally not enforced: every new treatment is tier 0.

-- How a medication is given decides where it can be applied, how long it takes and its action label.
local ROUTES = {
    inject   = { limbsOnly = true, trainedKey = "trainedTimeInjector", time = 5, group = "inject" },
    muscle   = { limbsOnly = true, trainedKey = "trainedTimeInjector", time = 5, group = "inject" },
    infusion = { limbsOnly = true, trainedKey = "trainedTimeIV", time = 12, group = "infusion" },
    oral     = { headOnly = true, time = 4, group = "oral" },
    inhale   = { headOnly = true, time = 6, group = "oral" },
    spray    = { time = 3, group = "topical" },
    apply    = { time = 5, group = "topical" },
    grenade  = { time = 3, group = "topical" },
}

local ROUTE_VERBS = {
    inject   = { de = "%s injizieren", en = "Inject %s" },
    muscle   = { de = "%s intramuskulär injizieren", en = "Inject %s (intramuscular)" },
    infusion = { de = "%s-Infusion anlegen", en = "Start %s infusion" },
    oral     = { de = "%s verabreichen (oral)", en = "Give %s (oral)" },
    inhale   = { de = "%s über die Atemwege geben", en = "Administer %s (inhaled)" },
    spray    = { de = "%s sprühen", en = "Spray %s" },
    apply    = { de = "%s auftragen", en = "Apply %s" },
    grenade  = { de = "%s auslösen", en = "Deploy %s" },
}

local FLAT_HR = { { 0, 0 }, { 0, 0 }, { 0, 0 } }

local function Med(def)
    def.rampTime = def.rampTime or 15
    def.painReduce = def.painReduce or 0
    def.viscosity = def.viscosity or 0
    def.maxDose = def.maxDose or 4
    def.duration = def.duration or 600
    def.hr = def.hr or FLAT_HR
    return def
end

-- Bandage stats derived from the Bacta (field) dressing: eff overrides per wound type, multipliers for the rest.
local function Bandage(spec)
    local stats = {}
    for woundType, base in pairs(KMS.BandageStats.bandage_field) do
        local effMul = spec.effMul or 1
        local reopenMul = spec.reopenMul or 1
        local delayMul = spec.delayMul or 1
        local eff = spec.eff and spec.eff[woundType]
        stats[woundType] = {
            eff = eff and { eff[1], eff[2], eff[3] } or { base.eff[1] * effMul, base.eff[2] * effMul, base.eff[3] * effMul },
            reopen = { math.min(1, base.reopen[1] * reopenMul), math.min(1, base.reopen[2] * reopenMul), math.min(1, base.reopen[3] * reopenMul) },
            delay = { base.delay[1] * delayMul, base.delay[2] * delayMul },
        }
    end
    return stats
end

-- Handbook order. "item" is the inventory item; entries without "kind" re-skin an existing base item.
local HANDBOOK = {
    { key = "anticeptin_d", item = "anticeptin_d", kind = "rp", route = "spray",
        name = { de = "Anticeptin-D", en = "Anticeptin-D" },
        effect = { de = "Generelle Desinfektion", en = "General disinfection" },
        use = { de = "Sprühen", en = "Spray" },
        dose = { de = "Eine Sprühladung", en = "One spray charge" } },
    { key = "anticeptin_a", item = "anticeptin_a", kind = "rp", route = "spray",
        name = { de = "Anticeptin-A", en = "Anticeptin-A" },
        effect = { de = "Schwache Desinfektion von Gegenständen", en = "Mild disinfection of objects" },
        use = { de = "Sprühen", en = "Spray" },
        dose = { de = "Eine Sprühladung", en = "One spray charge" } },
    { key = "anticeptin_s", item = "anticeptin_s", kind = "rp", route = "spray",
        name = { de = "Anticeptin-S", en = "Anticeptin-S" },
        effect = { de = "Desinfektion von Wunden und Schleimhäuten", en = "Disinfection of wounds and mucous membranes" },
        use = { de = "Sprühen", en = "Spray" },
        dose = { de = "Eine Sprühladung", en = "One spray charge" } },
    { key = "anticeptin_g", item = "anticeptin_g", kind = "rp", route = "grenade",
        name = { de = "Anticeptin-G", en = "Anticeptin-G" },
        effect = { de = "Desinfektion von Räumen", en = "Disinfection of rooms" },
        use = { de = "Sprühen (in Form von Granaten)", en = "Spray (as a grenade)" },
        dose = { de = "Eine Granate", en = "One grenade" } },
    { key = "anti_radiation", item = "anti_radiation", kind = "med", route = "oral",
        name = { de = "Anti-Strahlungs-Pille", en = "Anti-Radiation Pill" },
        effect = { de = "Vorsorgliche Tablette gegen Strahlungsschäden", en = "Preventive pill against radiation damage" },
        use = { de = "Orale Einnahme", en = "Oral" },
        dose = { de = "2cc (Tablette) / 1cc (Injektion)", en = "2cc (pill) / 1cc (injection)" },
        med = Med({ duration = 1200, maxDose = 3, radShield = true }) },
    { key = "adrenalin", item = "epinephrine", route = "inject",
        name = { de = "Adrenalin", en = "Adrenaline" },
        effect = { de = "Erhöht Puls und Blutdruck", en = "Raises pulse and blood pressure" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,4cc - 1cc", en = "0.4cc - 1cc" } },
    { key = "antishock", item = "antishock", kind = "med", route = "inject",
        name = { de = "Antishock", en = "Antishock" },
        effect = { de = "Verhindert Schockzustände", en = "Prevents states of shock" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,3cc - 0,6cc", en = "0.3cc - 0.6cc" },
        med = Med({ rampTime = 8, painReduce = 0.1, viscosity = 6, maxDose = 3, duration = 600, shock = true,
            hr = { { 5, 10 }, { 5, 10 }, { 0, 5 } } }) },
    { key = "bacta", item = "bandage_field", route = "dressing",
        name = { de = "Bacta-Verband", en = "Bacta Bandage" },
        effect = { de = "Regenerativer Wirkstoff", en = "Regenerative agent" },
        use = { de = "Verband", en = "Bandage" },
        dose = { de = "Ein Verband", en = "One bandage" } },
    { key = "bonemer", item = "bonemer", kind = "med", route = "inject", healsFracture = true, time = 6,
        name = { de = "Bonemer", en = "Bonemer" },
        effect = { de = "Erregt die Regeneration von Knochen", en = "Stimulates bone regeneration" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,5cc - 1,5cc", en = "0.5cc - 1.5cc" },
        med = Med({ rampTime = 10, painReduce = 0.05, maxDose = 3, duration = 300 }) },
    { key = "cardinex", item = "cardinex", kind = "med", route = "inject",
        name = { de = "Cardinex", en = "Cardinex" },
        effect = { de = "Gegengift gegen viele Pflanzen", en = "Antidote against many plants" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,3cc - 0,6cc", en = "0.3cc - 0.6cc" },
        med = Med({ maxDose = 3, duration = 900, toxShield = true }) },
    { key = "cicatrix", item = "cicatrix", kind = "bandage", route = "apply",
        name = { de = "Cicatrix-Gel", en = "Cicatrix Gel" },
        effect = { de = "Gel gegen blaue Flecken und Prellungen", en = "Gel against bruises and contusions" },
        use = { de = "Auftragen", en = "Apply" },
        dose = { de = "7,5cc (eine Ladung)", en = "7.5cc (one charge)" },
        stats = { effMul = 0.4, reopenMul = 0.5, eff = {
            contusion = { 3, 3, 3 }, abrasion = { 3.5, 3, 2.5 }, crush = { 1.75, 1.25, 0.75 } } } },
    { key = "coagulin", item = "bandage_quickclot", route = "dressing",
        name = { de = "Coagulin", en = "Coagulin" },
        effect = { de = "Blutverdicker (lässt Blut schneller gerinnen)", en = "Coagulant (makes blood clot faster)" },
        use = { de = "Auftragen", en = "Apply" },
        dose = { de = "0,02cc - 0,1cc", en = "0.02cc - 0.1cc" } },
    { key = "cryogen", item = "cryogen", kind = "med", route = "infusion",
        name = { de = "Cryogen", en = "Cryogen" },
        effect = { de = "Versetzt in Stasis", en = "Puts the patient into stasis" },
        use = { de = "Infusion", en = "Infusion" },
        dose = { de = "10:1 verdünnen (10cc NaCl, 1cc Cryogen) / 5:1 verdünnen (5cc NaCl, 1cc Cryogen)",
            en = "Dilute 10:1 (10cc NaCl, 1cc Cryogen) / dilute 5:1 (5cc NaCl, 1cc Cryogen)" },
        med = Med({ rampTime = 2, painReduce = 1, maxDose = 2, duration = 300, stasis = true }) },
    { key = "clexane", item = "clexane", kind = "med", route = "inject",
        name = { de = "Clexane", en = "Clexane" },
        effect = { de = "Blutverdünner (lässt Blut langsamer gerinnen)", en = "Blood thinner (makes blood clot slower)" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,4cc - 0,8cc", en = "0.4cc - 0.8cc" },
        med = Med({ viscosity = -10, maxDose = 3, duration = 900 }) },
    { key = "cordrazine", item = "cordrazine", kind = "med", route = "inject",
        name = { de = "Cordrazine", en = "Cordrazine" },
        effect = { de = "Schützt vor Strahlungsschäden", en = "Protects against radiation damage" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,5cc - 1cc", en = "0.5cc - 1cc" },
        med = Med({ maxDose = 3, duration = 1800, radShield = true }) },
    { key = "dermasel", item = "dermasel", kind = "bandage", route = "spray",
        name = { de = "Dermasel", en = "Dermasel" },
        effect = { de = "Desinfektion und Versorgung von Brandwunden", en = "Disinfects and treats burn wounds" },
        use = { de = "Sprühen", en = "Spray" },
        dose = { de = "Eine Sprühladung", en = "One spray charge" },
        stats = { effMul = 0.5, eff = { burn = { 4, 3.5, 3 }, abrasion = { 3.5, 3, 2.5 } } } },
    { key = "ellsinandrox", item = "ellsinandrox", kind = "med", route = "oral",
        name = { de = "Ellsinandrox", en = "Ellsinandrox" },
        effect = { de = "Strahlungsblocker", en = "Radiation blocker" },
        use = { de = "Orale Einnahme", en = "Oral" },
        dose = { de = "2cc (Tablette) / 1cc (Injektion)", en = "2cc (pill) / 1cc (injection)" },
        med = Med({ maxDose = 3, duration = 1800, radShield = true }) },
    { key = "enkephalin", item = "enkephalin", kind = "med", route = "spray",
        name = { de = "Enkephalin", en = "Enkephalin" },
        effect = { de = "Gegen Brand- und Ätzwunden", en = "Against burn and acid wounds" },
        use = { de = "Sprühen", en = "Spray" },
        dose = { de = "Eine Sprühladung", en = "One spray charge" },
        med = Med({ rampTime = 5, painReduce = 0.3, maxDose = 4, duration = 240 }) },
    { key = "gasbinder", item = "gasbinder", kind = "med", route = "inject",
        name = { de = "Gasbinder", en = "Gasbinder" },
        effect = { de = "Reinigung von giftigen Stoffen im Blut", en = "Cleans toxic substances from the blood" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "2cc - 4cc", en = "2cc - 4cc" },
        med = Med({ maxDose = 3, duration = 600, toxShield = true, purge = { "verax_serum" } }) },
    { key = "imobilin", item = "imobilin", kind = "med", route = "inject",
        name = { de = "Imobilin", en = "Imobilin" },
        effect = { de = "Starkes Beruhigungsmittel", en = "Strong sedative" },
        use = { de = "Injektion / Infusion", en = "Injection / infusion" },
        dose = { de = "0,5cc - 1cc", en = "0.5cc - 1cc" },
        med = Med({ rampTime = 8, painReduce = 0.2, maxDose = 3, duration = 300, sedate = 60,
            hr = { { -5, -10 }, { -10, -20 }, { -15, -25 } } }) },
    { key = "kolto", item = "bandage_packing", route = "dressing",
        name = { de = "Kolto-Verband", en = "Kolto Bandage" },
        effect = { de = "Regenerativer Wirkstoff, lindert Schmerzen", en = "Regenerative agent, relieves pain" },
        use = { de = "Verband", en = "Bandage" },
        dose = { de = "Ein Verband", en = "One bandage" } },
    { key = "kouhunin", item = "morphine", route = "inject",
        name = { de = "Kouhunin", en = "Kouhunin" },
        effect = { de = "Starkes Schmerzmittel", en = "Strong painkiller" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,3cc - 0,6cc", en = "0.3cc - 0.6cc" } },
    { key = "kryotin", item = "kryotin", kind = "med", route = "inhale",
        name = { de = "Kryotin", en = "Kryotin" },
        effect = { de = "Narkosemittel", en = "Anaesthetic" },
        use = { de = "Durch die Atemwege", en = "Through the airways" },
        dose = { de = "2 l/min", en = "2 l/min" },
        med = Med({ rampTime = 5, painReduce = 1, maxDose = 3, duration = 300, sedate = 240,
            hr = { { 0, -5 }, { -5, -10 }, { -10, -15 } } }) },
    { key = "myocain", item = "myocain", kind = "med", route = "inject",
        name = { de = "Myocain", en = "Myocain" },
        effect = { de = "Leichtes Beruhigungsmittel", en = "Mild sedative" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,5cc - 1cc", en = "0.5cc - 1cc" },
        med = Med({ painReduce = 0.1, maxDose = 4, duration = 300, hr = { { -5, -5 }, { -5, -10 }, { -10, -15 } } }) },
    { key = "nacl", item = "iv_saline", route = "infusion",
        variants = { iv_saline_500 = "500 cc", iv_saline = "1000 cc", iv_saline_1500 = "1500 cc" },
        name = { de = "NaCl-Lösung", en = "Saline (NaCl)" },
        title = { de = "Natriumchloridlösung (NaCl)", en = "Sodium chloride solution (NaCl)" },
        effect = { de = "Mineralstofflösung bei Flüssigkeitsverlust", en = "Mineral solution for fluid loss" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "500cc / 1000cc / 1500cc", en = "500cc / 1000cc / 1500cc" } },
    { key = "norvalin", item = "adenosine", route = "inject",
        name = { de = "Norvalin", en = "Norvalin" },
        effect = { de = "Gegen Adrenalinstöße", en = "Counters adrenaline surges" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,4cc - 0,8cc", en = "0.4cc - 0.8cc" } },
    { key = "nullicain", item = "painkillers", route = "inject",
        name = { de = "Nullicain", en = "Nullicain" },
        effect = { de = "Leichtes Schmerzmittel", en = "Mild painkiller" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "2cc - 5cc", en = "2cc - 5cc" } },
    { key = "numb_spray", item = "numb_spray", kind = "med", route = "spray",
        name = { de = "Numb Spray", en = "Numb Spray" },
        effect = { de = "Örtliches Betäubungsmittel", en = "Local anaesthetic" },
        use = { de = "Sprühen", en = "Spray" },
        dose = { de = "Eine Sprühladung", en = "One spray charge" },
        med = Med({ rampTime = 3, painReduce = 0.25, maxDose = 4, duration = 180 }) },
    { key = "orga_root", item = "orga_root", kind = "med", route = "inject",
        name = { de = "Orga-Wurzel", en = "Orga Root" },
        effect = { de = "Brechmittel", en = "Emetic" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,5cc - 1cc", en = "0.5cc - 1cc" },
        med = Med({ maxDose = 2, duration = 120, purge = { "anti_radiation", "ellsinandrox", "taracetamol" } }) },
    { key = "polybiotic", item = "polybiotic", kind = "med", route = "inject",
        name = { de = "Polybiotic", en = "Polybiotic" },
        effect = { de = "Stärkt das Immunsystem", en = "Strengthens the immune system" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,5cc - 1cc", en = "0.5cc - 1cc" },
        med = Med({ maxDose = 3, duration = 1800 }) },
    { key = "quick_wake", item = "quick_wake", kind = "med", route = "inject",
        name = { de = "Quick Wake", en = "Quick Wake" },
        effect = { de = "Gegen Narkosemittel", en = "Counters anaesthetics" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "1cc - 2cc", en = "1cc - 2cc" },
        med = Med({ rampTime = 3, maxDose = 3, duration = 120, wake = true, hr = { { 10, 20 }, { 5, 15 }, { 0, 10 } } }) },
    { key = "rakghoul_serum", item = "rakghoul_serum", kind = "med", route = "inject",
        name = { de = "Rakghoul-Serum", en = "Rakghoul Serum" },
        effect = { de = "Medikament gegen die Rakghoul-Krankheit", en = "Medication against the Rakghoul plague" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "1cc - 2cc", en = "1cc - 2cc" },
        med = Med({ maxDose = 2, duration = 1800 }) },
    { key = "stimpack", item = "stimpack", kind = "med", route = "inject", time = 3,
        name = { de = "Stimpack", en = "Stimpack" },
        effect = { de = "Für Schnellbehandlungen", en = "For quick treatment" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "Wird per Autoinjektor injiziert", en = "Injected by auto-injector" },
        med = Med({ rampTime = 3, painReduce = 0.2, maxDose = 3, duration = 180, heal = 0.25, stamina = 0.5,
            hr = { { 5, 15 }, { 5, 10 }, { 0, 5 } } }) },
    { key = "spectacilin", item = "spectacilin", kind = "med", route = "inject",
        name = { de = "Spectacilin", en = "Spectacilin" },
        effect = { de = "Wirkt antibakteriell", en = "Antibacterial" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "2,5cc - 5cc", en = "2.5cc - 5cc" },
        med = Med({ maxDose = 3, duration = 1800 }) },
    { key = "soptricaniol", item = "soptricaniol", kind = "med", route = "inject",
        name = { de = "Soptricaniol", en = "Soptricaniol" },
        effect = { de = "Gegen posttraumatische Belastungsstörungen", en = "Against post-traumatic stress disorder" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,2cc - 0,8cc", en = "0.2cc - 0.8cc" },
        med = Med({ maxDose = 3, duration = 1800 }) },
    { key = "taracetamol", item = "taracetamol", kind = "med", route = "oral",
        name = { de = "Taracetamol", en = "Taracetamol" },
        effect = { de = "Fiebersenkend", en = "Reduces fever" },
        use = { de = "Orale Einnahme / Tropfen", en = "Oral / drops" },
        dose = { de = "2cc (Tablette) / 1cc (Injektion)", en = "2cc (pill) / 1cc (injection)" },
        med = Med({ rampTime = 30, painReduce = 0.1, maxDose = 4, duration = 900 }) },
    { key = "synthex_skin", item = "bandage_elastic", route = "dressing",
        name = { de = "Synthex-Haut", en = "Synthex Skin" },
        effect = { de = "Simuliert Haut", en = "Simulates skin" },
        use = { de = "Auftragen", en = "Apply" },
        dose = { de = "Eine Ladung", en = "One charge" } },
    { key = "synthex_flesh", item = "synthex_flesh", kind = "bandage", route = "apply",
        name = { de = "Synthex-Fleisch", en = "Synthex Flesh" },
        effect = { de = "Simuliert Fleisch", en = "Simulates flesh" },
        use = { de = "Auftragen", en = "Apply" },
        dose = { de = "Eine Ladung", en = "One charge" },
        stats = { effMul = 0.8, reopenMul = 0.4, delayMul = 2, eff = {
            avulsion = { 2.75, 2.25, 1.75 }, velocity = { 3, 2.25, 1.75 },
            crush = { 2.5, 2, 1.75 }, puncture = { 2.75, 2, 1.5 } } } },
    { key = "wundkleber", item = "wundkleber", kind = "bandage", route = "apply",
        name = { de = "Wundkleber", en = "Wound Glue" },
        effect = { de = "Verschließt offene Wunden", en = "Seals open wounds" },
        use = { de = "Auftragen", en = "Apply" },
        dose = { de = "Eine Ladung", en = "One charge" },
        stats = { effMul = 0.6, reopenMul = 0, eff = {
            cut = { 4.5, 3.5, 1.5 }, laceration = { 2, 1.5, 0.75 },
            abrasion = { 3.25, 2.75, 2 }, puncture = { 1.5, 1, 0.5 } } } },
    { key = "tavor", item = "tavor", kind = "med", route = "inject",
        name = { de = "Tavor", en = "Tavor" },
        effect = { de = "Sehr starkes Beruhigungsmittel (stark genug, um einen Jedi still zu halten)",
            en = "Very strong sedative (strong enough to keep a Jedi still)" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "0,05cc - 0,1cc", en = "0.05cc - 0.1cc" },
        med = Med({ rampTime = 5, painReduce = 0.3, maxDose = 2, duration = 600, sedate = 180,
            hr = { { -10, -15 }, { -15, -25 }, { -20, -30 } } }) },
    { key = "verax_serum", item = "verax_serum", kind = "med", route = "muscle",
        name = { de = "Verax-Serum", en = "Verax Serum" },
        effect = { de = "Krampfendes Mittel, führt zu starken Schmerzen beim Patienten und schlussendlich zum Tod",
            en = "Convulsant, causes severe pain in the patient and ultimately death" },
        use = { de = "Injektion ins Muskelgewebe", en = "Intramuscular injection" },
        dose = { de = "2,5cc - 5cc", en = "2.5cc - 5cc" },
        med = Med({ rampTime = 2, maxDose = 9, duration = 60, verax = 40, hr = { { 30, 40 }, { 30, 40 }, { 20, 30 } } }) },
    { key = "latheniol_serum", item = "latheniol_serum", kind = "med", route = "inject",
        name = { de = "Latheniol-Serum", en = "Latheniol Serum" },
        effect = { de = "Führt zu schmerzfreiem Herzstillstand", en = "Causes a painless cardiac arrest" },
        use = { de = "Injektion", en = "Injection" },
        dose = { de = "5cc - 10cc", en = "5cc - 10cc" },
        med = Med({ rampTime = 1, painReduce = 1, maxDose = 9, duration = 600, arrest = true }) },
}

-- Hidden pain relief that comes with every Kolto bandage.
KMS.Meds.kolto = Med({ rampTime = 10, painReduce = 0.15, maxDose = 10, duration = 300 })

local ICONS = {
    inject = "morphine", muscle = "morphine", infusion = "plasma", oral = "painkiller", inhale = "saline",
    spray = "quick_clot", apply = "compress", grenade = "quick_clot",
}
local ICON_OVERRIDES = {
    stimpack = "ephinefrina", antishock = "ephinefrina", quick_wake = "ephinefrina", bonemer = "adenosine",
    dermasel = "quick_clot", cicatrix = "elastic", synthex_flesh = "compress", wundkleber = "elastic",
}

KMS.Handbook = {}
KMS.HandbookByItem = {}

local OVERLAYS = {}

local function Text(key, names)
    OVERLAYS[key] = names
end

local function Verb(route, name)
    local verb = ROUTE_VERBS[route]
    return { de = string.format(verb.de, name.de), en = string.format(verb.en, name.en) }
end

local function AddTreatment(entry)
    local id, route = entry.item, ROUTES[entry.route]
    local def = { id = id, cat = entry.kind == "bandage" and "bandage" or "meds", item = id, tier = 0, sw = true, route = entry.route, routeGroup = route.group }
    if entry.kind == "bandage" then
        def.needsWound = true
        KMS.BandageStats[id] = Bandage(entry.stats)
        KMS.Bandages[#KMS.Bandages + 1] = id
    else
        def.time = entry.time or route.time
        def.limbsOnly = route.limbsOnly
        def.headOnly = route.headOnly
        def.trainedKey = route.trainedKey
        def.healsFracture = entry.healsFracture
        if entry.kind == "med" then
            def.med = true
            KMS.Meds[id] = entry.med
        else
            def.rp = true
        end
    end
    KMS.Items[#KMS.Items + 1] = { id = id, sw = true }
    KMS.Treatments[#KMS.Treatments + 1] = def
end

for _, entry in ipairs(HANDBOOK) do
    KMS.Handbook[#KMS.Handbook + 1] = entry
    Text("hb_eff_" .. entry.key, entry.effect)
    Text("hb_use_" .. entry.key, entry.use)
    Text("hb_dose_" .. entry.key, entry.dose)
    Text("hb_name_" .. entry.key, entry.title or entry.name)
    if entry.kind then AddTreatment(entry) end
    if entry.variants then
        for itemId, size in pairs(entry.variants) do
            KMS.HandbookByItem[itemId] = entry
            local label = { de = entry.name.de .. " (" .. size .. ")", en = entry.name.en .. " (" .. size .. ")" }
            Text("item_" .. itemId, label)
            Text("treat_" .. itemId, label)
        end
    else
        KMS.HandbookByItem[entry.item] = entry
        Text("item_" .. entry.item, entry.name)
        local bandage = entry.kind == "bandage" or entry.route == "dressing"
        Text("treat_" .. entry.item, bandage and entry.name or Verb(entry.route, entry.name))
    end
end

KMS.ItemById = {}
for _, item in ipairs(KMS.Items) do
    KMS.ItemById[item.id] = item
end

KMS.TreatmentById = {}
for _, def in ipairs(KMS.Treatments) do
    KMS.TreatmentById[def.id] = def
    if not def.routeGroup and def.cat == "meds" then
        def.routeGroup = (def.ivScale or def.ivMl) and "infusion" or def.trainedKey == "trainedTimeInjector" and "inject" or nil
    end
end

KMS.TreatmentById.bandage_packing.sideMed = "kolto"

-- Starting kits. Saved loadouts pick these up for items they do not list yet.
local LOADOUTS = {
    loadoutDefault = { antishock = 1 },
    loadoutMedic = {
        stimpack = 2, antishock = 2, bonemer = 1, dermasel = 2, cicatrix = 1, synthex_flesh = 1, wundkleber = 2,
        numb_spray = 1, enkephalin = 1, myocain = 1, quick_wake = 1, anticeptin_s = 2, taracetamol = 1,
    },
    loadoutDoctor = {
        stimpack = 3, antishock = 3, bonemer = 2, dermasel = 3, cicatrix = 2, synthex_flesh = 2, wundkleber = 3,
        numb_spray = 2, enkephalin = 2, myocain = 2, imobilin = 1, kryotin = 1, quick_wake = 2, cryogen = 1,
        anticeptin_d = 1, anticeptin_s = 3, taracetamol = 2, spectacilin = 1, polybiotic = 1, gasbinder = 1,
        cordrazine = 1, iv_saline_1500 = 1,
    },
    medVehicleInvDefault = { stimpack = 2, antishock = 2, dermasel = 2, wundkleber = 2 },
}

for key, extra in pairs(LOADOUTS) do
    local defaults = KMS.DefaultSettings[key]
    for _, item in ipairs(KMS.Items) do
        defaults[item.id] = extra[item.id] or defaults[item.id] or 0
    end
    local current = KMS.Settings[key]
    if istable(current) then
        for _, item in ipairs(KMS.Items) do
            if current[item.id] == nil then current[item.id] = defaults[item.id] end
        end
    end
end

local SW_TEXT = {
    item_kolto = { de = "Kolto", en = "Kolto" },
    ivfam_saline = { de = "NaCl-Lösung", en = "Saline (NaCl)" },

    route_grp_inject = { de = "INJEKTIONEN", en = "INJECTIONS" },
    route_grp_infusion = { de = "INFUSIONEN", en = "INFUSIONS" },
    route_grp_oral = { de = "ORAL / ATEMWEGE", en = "ORAL / INHALED" },
    route_grp_topical = { de = "SPRAYS & SALBEN", en = "SPRAYS & TOPICALS" },

    hb_line_effect = { de = "Wirkung: %1", en = "Effect: %1" },
    hb_line_use = { de = "Anwendung: %1", en = "Application: %1" },
    hb_line_dose = { de = "Dosis: %1", en = "Dose: %1" },

    wiki_sw_sedate = { de = "Stellt den Patienten für ~%1 ruhig (bewusstlos).", en = "Puts the patient under for ~%1 (unconscious)." },
    wiki_sw_stasis = { de = "Stasis für %1: keine Blutung, der Herzstillstand-Timer ruht, der Patient ist bewusstlos.", en = "Stasis for %1: no bleeding, the cardiac arrest timer is paused, the patient is unconscious." },
    wiki_sw_wake = { de = "Hebt Beruhigungs-, Narkose- und Stasismittel auf und weckt einen stabilen Patienten sofort.", en = "Cancels sedatives, anaesthetics and stasis and wakes a stable patient at once." },
    wiki_sw_arrest = { de = "Löst sofort einen Herzstillstand aus.", en = "Triggers a cardiac arrest at once." },
    wiki_sw_verax = { de = "Maximale Schmerzen, nach ~%1 Herzstillstand. Gasbinder neutralisiert es.", en = "Maximum pain, cardiac arrest after ~%1. Gasbinder neutralises it." },
    wiki_sw_shock = { de = "Verhindert Bewusstlosigkeit durch Schmerz oder starken Blutverlust (Schock), solange es wirkt.", en = "Prevents passing out from pain or heavy blood loss (shock) while active." },
    wiki_sw_fracture = { de = "Heilt den Knochenbruch der behandelten Gliedmaße vollständig.", en = "Fully heals the fracture of the treated limb." },
    wiki_sw_purge = { de = "Neutralisiert: %1.", en = "Neutralises: %1." },
    wiki_sw_rad = { de = "Schützt vor Strahlungsschäden, solange es wirkt.", en = "Protects against radiation damage while active." },
    wiki_sw_tox = { de = "Schützt vor Gift- und Gasschäden, solange es wirkt.", en = "Protects against poison and gas damage while active." },
    wiki_sw_side = { de = "Lindert zusätzlich Schmerzen um %1%.", en = "Also relieves pain by %1%." },
    wiki_sw_thick = { de = "Lässt Blut schneller gerinnen: weniger Blutung, höherer Druck.", en = "Makes blood clot faster: less bleeding, higher pressure." },
    wiki_sw_thin = { de = "Verdünnt das Blut: stärkere Blutung, niedrigerer Druck.", en = "Thins the blood: heavier bleeding, lower pressure." },
    wiki_sw_rp = { de = "Wird im Patientenprotokoll vermerkt.", en = "Recorded in the patient log." },

    hb_grp = { de = "MEDIZINISCHES HANDBUCH", en = "MEDICAL HANDBOOK" },
    hb_ch_important = { de = "Wichtiges", en = "Important" },
    hb_ch_medlist = { de = "Medikamentenliste", en = "Medication List" },
    hb_important_1 = {
        de = "Es gilt eine Pflicht, Medic-RP auszuführen. Zuwiderhandeln führt laut §x zu einem sofortigen Ausschluss aus dem 501st Medical Platoon!",
        en = "Performing medic RP is mandatory. Violations lead to immediate expulsion from the 501st Medical Platoon under §x!",
    },
    hb_medlist_intro = {
        de = "Alle Medikamente des 501st Medical Platoon. Wirkung, Anwendung und Dosis stammen aus dem Handbuch, darunter steht, was das Mittel im Spiel bewirkt.",
        en = "Every medication of the 501st Medical Platoon. Effect, application and dose come from the handbook; below that is what the medication does in game.",
    },

    err_morphine_cd = { de = "Der Patient hat schon Kouhunin im Körper. Warte etwas vor der nächsten Dosis.", en = "That patient already has Kouhunin in their system. Give it some time before another dose." },
    set_morphineCooldown = { de = "Sicheres Kouhunin-Intervall (Sekunden)", en = "Kouhunin safe interval (seconds)" },
    set_morphineTime = { de = "Kouhunin-Dauer (Sekunden)", en = "Kouhunin duration (seconds)" },
    set_epiTime = { de = "Adrenalin-Dauer (Sekunden)", en = "Adrenaline duration (seconds)" },
    set_adenosineTime = { de = "Norvalin-Dauer (Sekunden)", en = "Norvalin duration (seconds)" },
    set_painkillersTime = { de = "Nullicain-Dauer (Sekunden)", en = "Nullicain duration (seconds)" },
    set_wakeEpiBoost = { de = "Wie stark Adrenalin das Aufwachen beschleunigt (Multiplikator)", en = "How much adrenaline speeds up waking up (multiplier)" },

    guide_it_bandage_field = {
        de = "Bacta-Verband mit regenerativem Wirkstoff: schnell angelegt und für jede Wunde geeignet. Dafür öffnet er sich am wahrscheinlichsten wieder. Nützlich als Erstversorgung.",
        en = "Bacta bandage with a regenerative agent: quick to apply and valid for any wound. In exchange, it is the most likely to reopen. Useful as a first response.",
    },
    guide_it_bandage_elastic = {
        de = "Synthex-Haut simuliert Haut und deckt die Wunde ab. Dauert etwas länger, ist aber am zuverlässigsten: Was sie schließt, öffnet sich fast nie wieder. Empfohlen, wenn du Zeit hast.",
        en = "Synthex Skin simulates skin and covers the wound. Takes a bit longer, but it is the most reliable: wounds it closes almost never reopen. Recommended when you have time.",
    },
    guide_it_bandage_packing = {
        de = "Kolto-Verband für tiefe Wunden wie Schüsse und Stiche, lindert zusätzlich Schmerzen. Anfangs sehr wirksam, öffnet sich aber mit der Zeit: zum Stabilisieren nutzen, danach nähen.",
        en = "Kolto bandage for deep wounds such as shots and punctures, also relieves pain. Very effective at first, but reopens over time: use it to stabilize, then stitch.",
    },
    guide_it_bandage_quickclot = {
        de = "Coagulin lässt Blut schneller gerinnen. Schließt etwas schwächer als andere Verbände, hält aber deutlich länger, bevor es sich öffnet. Guter Kompromiss aus Tempo und Dauer.",
        en = "Coagulin makes blood clot faster. Closes slightly worse than other bandages, but holds much longer before reopening. A good balance between speed and duration.",
    },
    guide_it_painkillers = {
        de = "Nullicain ist ein leichtes Schmerzmittel zur Injektion. Lindert leichte und mittlere Schmerzen ohne nennenswerte Nebenwirkungen. Gegen den Schmerz schwerer Wunden unzureichend.",
        en = "Nullicain is a mild injectable painkiller. Reduces minor and moderate pain without significant side effects. Insufficient against the pain of serious wounds.",
    },
    guide_it_morphine = {
        de = "Kouhunin ist ein starkes Schmerzmittel für schwere Schmerzen. Senkt zusätzlich Puls und Druck: Dosen nicht stapeln und nicht bei Patienten mit niedrigen Werten einsetzen. Halte den Abstand zwischen den Dosen ein.",
        en = "Kouhunin is a strong painkiller for severe pain. It also lowers heart rate and pressure: do not stack doses and avoid using it on patients with low vitals. Respect the interval between doses.",
    },
    guide_it_epinephrine = {
        de = "Adrenalin erhöht Puls und Blutdruck. Dient dazu, das Erwachen stabilisierter Patienten zu beschleunigen und zu niedrige Werte zu stützen.",
        en = "Adrenaline raises pulse and blood pressure. Used to speed up the waking of stabilized patients and to support vitals that are too low.",
    },
    guide_it_adenosine = {
        de = "Norvalin wirkt gegen Adrenalinstöße: Es senkt einen zu hohen Puls, verursacht durch Adrenalin, Stimulanzien oder Schmerz. Einsetzen, wenn der Puls rast.",
        en = "Norvalin counters adrenaline surges: it lowers a heart rate that is too high, caused by adrenaline, stimulants or pain. Use it when the pulse is racing.",
    },
    guide_ivs_1 = {
        de = "Infusionen füllen verlorenes Blutvolumen auf: NaCl-Lösung ist die Basisoption (500, 1000 oder 1500 cc), Plasma wirksamer und Blut am besten. Der Patient muss während der Transfusion stillhalten; mit dem Volumen normalisieren sich Druck und Puls.",
        en = "IVs restore lost blood volume: saline (NaCl) is the basic option (500, 1000 or 1500 cc), plasma is more effective and blood is the best. The patient must stay still during the transfusion; as volume recovers, pressure and pulse return to normal.",
    },
    guide_downed_2 = {
        de = "Wiederbelebungsprotokoll, in dieser Reihenfolge: Zuerst alle Wunden verbinden, um die Blutung zu stoppen; dann verlorenes Blut per Infusion auffüllen; zuletzt warten: Sobald die Werte stabil sind, erwacht der Patient von selbst. Adrenalin beschleunigt das Erwachen eines stabilen Patienten, Quick Wake hebt Beruhigungs- und Narkosemittel auf.",
        en = "Revival protocol, in this order: first bandage all wounds to stop the bleeding; then restore lost blood with an IV; finally wait: once vitals stabilize, the patient wakes up on their own. Adrenaline speeds up the waking of a stable patient, Quick Wake cancels sedatives and anaesthetics.",
    },
    preset_starwars_desc = {
        de = "Für Star-Wars-Server. Blasterfeuer kauterisiert hier: kaum Blutung, das eigentliche Problem ist der Schmerz, also wird viel Kouhunin verbraucht. Lichtschwerter verursachen sehr ernste Wunden und die Macht ist eingebunden (Blitze verbrennen, Machtheilung stellt wirklich Blut wieder her). Der Rest folgt den realistischen Regeln.",
        en = "For Star Wars servers. Blaster fire cauterizes here: barely any bleeding, the real problem is the pain, so Kouhunin gets used a lot. Lightsabers cause very serious wounds and the Force is integrated (lightning burns, Force heal actually restores blood). Everything else follows the realistic rules.",
    },
}

for key, names in pairs(SW_TEXT) do
    Text(key, names)
end

-- Admin renames from the item editor take precedence; ours come back once a rename is removed.
local function ApplyOverlays()
    for key, names in pairs(OVERLAYS) do
        if KMS.LangOverlay[key] == nil then
            KMS.ExtendLang(key, names)
        end
    end
end

ApplyOverlays()
hook.Add("KMS_ItemsApplied", "KMS_StarWarsLang", ApplyOverlays)

if CLIENT then
    for _, entry in ipairs(HANDBOOK) do
        if entry.kind then
            KMS.ItemIconFiles[entry.item] = ICON_OVERRIDES[entry.item] or ICONS[entry.route]
            KMS.ItemIcons[entry.item] = KMS.ResolveItemIcon(entry.item)
        end
    end
end
