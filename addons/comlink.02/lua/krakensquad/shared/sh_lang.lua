KrakenSquad.LANG_NAMES = {
    en = "English", es = "Español", pt = "Português", de = "Deutsch",
    ru = "Русский", uk = "Українська", fr = "Français", it = "Italiano",
    pl = "Polski", tr = "Türkçe", ja = "Japanese", ko = "Korean", zh = "Chinese",
}

KrakenSquad.LangData    = KrakenSquad.LangData    or {}
KrakenSquad.LangCurrent = KrakenSquad.LangCurrent or "en"

function KrakenSquad.AddLang(lang, tbl)
    lang = lang:lower()
    local store = KrakenSquad.LangData[lang] or {}
    for k, v in pairs(tbl) do store[k] = v end
    KrakenSquad.LangData[lang] = store
    if KF.Lang then
        KF.Lang.Register("krakensquad", lang, KrakenSquad.LANG_NAMES[lang] or lang, store)
    end
end

function KrakenSquad.L(key, ...)
    local cur = KrakenSquad.LangData[KrakenSquad.LangCurrent]
    local val = (cur and cur[key]) or (KrakenSquad.LangData.en or {})[key]
    if not val then return key end
    if select("#", ...) > 0 then return val:format(...) end
    return val
end

function KrakenSquad.SetLang(lang)
    lang = (lang or "en"):lower()
    if not KrakenSquad.LangData[lang] then lang = "en" end
    KrakenSquad.LangCurrent = lang
    if KF.Lang then KF.Lang.SetLanguage("krakensquad", lang) end
    hook.Run("KrakenSquad.LanguageChanged", lang)
end
