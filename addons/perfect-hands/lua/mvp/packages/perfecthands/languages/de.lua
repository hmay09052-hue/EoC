--
-- This translation was done by TheCookieYT
-- https://steamcommunity.com/id/76561198293343119/
--

local l = {}

l["section.perfecthands"] = "Perfekt Hands"
l["section.perfecthands.appearance"] = "Erscheinungsbild"
l["section.perfecthands.animations"] = "Animations-System"
l["section.perfecthands.interactions"] = "Interaktions-System"

l["value.phands.useIcons.description"] = "Wenn aktiviert, werden Animationen Symbole verwenden, ansonsten Text."
l["value.phands.iconsTheme.description"] = "Das Thema der Symbole."

l["value.phands.useAnimations.description"] = "Aktivieren oder deaktivieren Sie das Animationssystem."
l["value.phands.animationAllowFreelook.description"] = "Ermöglichen Sie dem Spieler, während der Animationen freizusehen."
l["value.phands.animationSpeed.description"] = "Die Geschwindigkeit der Animationen."
l["value.phands.animationVelocityCutoff.description"] = "Steuerung der maximalen Geschwindigkeit, bei der die Animation abgespielt wird. Wenn die Geschwindigkeit des Spielers höher ist als dieser Wert, wird die Animation nicht abgespielt."

l["value.phands.useInteractions.description"] = "Aktivieren oder deaktivieren Sie das Interaktionssystem."
l["value.phands.interactionDistance.description"] = "Die Entfernung, in der der Spieler mit Objekten interagieren kann."
l["value.phands.interactionWeightMultiplier.description"] = "Steuerung des Gewichtsmultiplikators für das Interaktionssystem. Dies beeinflusst, wie schwer die Objekte sich anfühlen, wenn der Spieler sie hält."

l["phands.name"] = "Hände" -- this is the name for the hands SWEP

l["phands.mouse_buttons.MOUSE1"] = "LMB"
l["phands.mouse_buttons.MOUSE2"] = "RMB"
l["phands.mouse_buttons.MOUSE3"] = "MMB"

l["phands.hint.drag"] = "Halte {{btn:%s}} gedrückt, um dieses Objekt zu greifen."
l["phands.hint.rmb"] = "Drücke {{btn:%s}}, um das Animationsmenü zu öffnen."
l["phands.hint.rmb.stop"] = "Drücke {{btn:%s}} oder {{btn:%s}}, um die Animation zu stoppen."
l["phands.hint.freelook"] = "Drücke {{btn:%s}}, um den freien Blick zu aktivieren."

l["phands.cant_use_animation"] = "Du kannst die Animation \"%s\" gerade nicht verwenden."

l["phands.animation.surrender"] = "Ergeben"
l["phands.animation.surrender.description"] = "Du hebst die Hände und akzeptierst dein Schicksal."
l["phands.animation.armsinfront"] = "Arme nach vorne"
l["phands.animation.armsinfront.description"] = "Du legst deine Arme vor dich."
l["phands.animation.armsbehind"] = "Arme nach hinten"
l["phands.animation.armsbehind.description"] = "Du legst deine Arme hinter dich."
l["phands.animation.armsbehindhead"] = "Arme hinter dem Kopf"
l["phands.animation.armsbehindhead.description"] = "Du legst deine Arme hinter deinen Kopf."
l["phands.animation.armsonbelt"] = "Arme auf dem Gürtel"
l["phands.animation.armsonbelt.description"] = "Du legst deine Arme auf deinen Gürtel."
l["phands.animation.comlink"] = "Comlink"
l["phands.animation.comlink.description"] = "Du benutzt dein Comlink."
l["phands.animation.hololink"] = "Hololink"
l["phands.animation.hololink.description"] = "Du benutzt dein Hololink."
l["phands.animation.highfive"] = "High Five"
l["phands.animation.highfive.description"] = "Du streckst deine Hand für ein High Five aus."
l["phands.animation.point"] = "Zeigen"
l["phands.animation.point.description"] = "Du zeigst auf etwas."
l["phands.animation.salute"] = "Salutieren"
l["phands.animation.salute.description"] = "Du salutierst."
l["phands.animation.pensive"] = "Nachdenklich"
l["phands.animation.pensive.description"] = "Du siehst nachdenklich aus."
l["phands.animation.typing"] = "Tippen"
l["phands.animation.typing.description"] = "Du tippst auf einer Tastatur."
l["phands.animation.middlefinger"] = "Mittelfinger"
l["phands.animation.middlefinger.description"] = "Zeige jemandem den Mittel Finger."
l["phands.animation.attention"] = "Achtung"
l["phands.animation.attention.description"] = "Sie stehen stramm."
l["phands.animation.kneel"] = "Knien"
l["phands.animation.kneel.description"] = "Sie knien auf einem Knie."




l["phands.menu.title"] = "Posen"
l["phands.menu.section"] = "Verfügbare Posen"
l["phands.menu.preview"] = "Vorschau"
l["phands.menu.choose"] = "Pose wählen"
l["phands.menu.choose.description"] = "Fahre mit der Maus über eine Pose, um sie an deinem Modell zu sehen."
l["phands.menu.hint"] = "Linksklick: Pose einnehmen   ·   Vorschau ziehen: Modell drehen"
l["phands.menu.cancel"] = "Abbrechen"
l["phands.menu.locked"] = "Gesperrt"
l["phands.menu.choose.short"] = "Maus über eine Pose = Vorschau"
l["phands.menu.hint.compact"] = "Klick: Pose  ·  Rechtsklick/ESC: Schließen"

mvp.language.Register("de", l)
