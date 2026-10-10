GRN_Bombs = GRN_Bombs or {}
GRN_Bombs.Phrases = {
    en = {
        no_access = 'You do not have access to this menu.',
        saved = 'Bomb saved successfully.',
        deleted = 'Bomb deleted successfully.',
        spawned = 'Bomb spawned successfully.',
        missing = 'Bomb configuration not found.',
        invalid = 'Invalid bomb configuration.',
        need_weapon = 'You need %s to interact with this bomb.',
        defused = 'Bomb defused.',
        failed = 'Defusal failed.',
        reward = 'You received $%s for defusing the bomb.',
        exploded = 'The bomb exploded!',
    },
    es = {
        no_access = 'No tienes acceso a este menú.',
        saved = 'Bomba guardada correctamente.',
        deleted = 'Bomba eliminada correctamente.',
        spawned = 'Bomba spawneada correctamente.',
        missing = 'No se encontró la configuración de la bomba.',
        invalid = 'Configuración de bomba inválida.',
        need_weapon = 'Necesitas %s para interactuar con esta bomba.',
        defused = 'Bomba desactivada.',
        failed = 'Fallaste la desactivación.',
        reward = 'Recibiste $%s por desactivar la bomba.',
        exploded = '¡La bomba explotó!',
    },
    fr = {
        no_access = 'Vous navez pas accès à ce menu.',
        saved = 'Bombe sauvegardée avec succès.',
        deleted = 'Bombe supprimée avec succès.',
        spawned = 'Bombe spawnée avec succès.',
        missing = 'Configuration de bombe introuvable.',
        invalid = 'Configuration de bombe invalide.',
        need_weapon = 'Vous avez besoin de %s pour interagir avec cette bombe.',
        defused = 'Bombe désamorcée.',
        failed = 'Le désamorçage a échoué.',
        reward = 'Vous avez reçu $%s pour avoir désamorcé la bombe.',
        exploded = 'La bombe a explosé !',
    }
}

function GRN_Bombs.GetPhrase(key, lang, ...)
    local tbl = GRN_Bombs.Phrases[lang or 'en'] or GRN_Bombs.Phrases.en
    local phrase = tbl[key] or GRN_Bombs.Phrases.en[key] or key
    if select('#', ...) > 0 then
        return string.format(phrase, ...)
    end
    return phrase
end
