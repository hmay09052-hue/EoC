local l = {}

l["section.perfecthands"] = "Perfect Hands"
l["section.perfecthands.appearance"] = "Appearance"
l["section.perfecthands.animations"] = "Animations System"
l["section.perfecthands.interactions"] = "Interactions System"

l["value.phands.useIcons.description"] = "If enabled, animations will be using icons, otherwise they will use text."
l["value.phands.useModels.description"] = "If enabled, animations will be using player model, FPS heavy. Themes will be ignored."
l["value.phands.iconsTheme.description"] = "The theme of the icons."

l["value.phands.useAnimations.description"] = "Enable or disable the animation system."
l["value.phands.animationAllowFreelook.description"] = "Allow the player to freelook while playing animations."
l["value.phands.animationSpeed.description"] = "The speed of the animations."
l["value.phands.animationVelocityCutoff.description"] = "Controls the maximum velocity at which the animation will play. If the player's velocity is higher than this value, the animation will not play."

l["value.phands.useInteractions.description"] = "Enable or disable the interaction system."
l["value.phands.interactionDistance.description"] = "The distance at which the player can interact with objects."
l["value.phands.interactionWeightMultiplier.description"] = "Controls the weight multiplier for the interaction system. This will affect how heavy the objects feel when the player is holding them."

l["phands.name"] = "Hands" -- this is the name for the hands SWEP

l["phands.mouse_buttons.MOUSE1"] = "LMB"
l["phands.mouse_buttons.MOUSE2"] = "RMB"
l["phands.mouse_buttons.MOUSE3"] = "MMB"

l["phands.hint.drag"] = "Press and hold {{btn:%s}} to grab this entity."
l["phands.hint.rmb"] = "Press {{btn:%s}} to open animations menu."
l["phands.hint.rmb.stop"] = "Press {{btn:%s}} or {{btn:%s}} button to stop the animation."
l["phands.hint.freelook"] = "Hold {{btn:%s}} button to freelook."

l["phands.cant_use_animation"] = "You can't use \"%s\" animation right now."

l["phands.animation.surrender"] = "Surrender"
l["phands.animation.surrender.description"] = "You raise your hands and accept your fate."
l["phands.animation.armsinfront"] = "Arms in front"
l["phands.animation.armsinfront.description"] = "You put your arms in front of you."
l["phands.animation.armsbehind"] = "Arms behind"
l["phands.animation.armsbehind.description"] = "You put your arms behind you."
l["phands.animation.armsbehindhead"] = "Arms behind head"
l["phands.animation.armsbehindhead.description"] = "You put your arms behind your head."
l["phands.animation.armsonbelt"] = "Arms on belt"
l["phands.animation.armsonbelt.description"] = "You put your arms on your belt."
l["phands.animation.comlink"] = "Comlink"
l["phands.animation.comlink.description"] = "You use your comlink."
l["phands.animation.hololink"] = "Hololink"
l["phands.animation.hololink.description"] = "You use your hololink."
l["phands.animation.highfive"] = "High five"
l["phands.animation.highfive.description"] = "You raise your hand for a high five."
l["phands.animation.point"] = "Point"
l["phands.animation.point.description"] = "You point at something."
l["phands.animation.salute"] = "Salute"
l["phands.animation.salute.description"] = "You salute."
l["phands.animation.pensive"] = "Pensive"
l["phands.animation.pensive.description"] = "You look pensive."
l["phands.animation.typing"] = "Typing"
l["phands.animation.typing.description"] = "You type on a keyboard."
l["phands.animation.middlefinger"] = "Middle Finger"
l["phands.animation.middlefinger.description"] = "Show someone the middle finger."
l["phands.animation.attention"] = "Attention"
l["phands.animation.attention.description"] = "You stand at attention."
l["phands.animation.kneel"] = "Kneel Down"
l["phands.animation.kneel.description"] = "You kneel down on one knee."




l["phands.menu.title"] = "Poses"
l["phands.menu.section"] = "Available poses"
l["phands.menu.preview"] = "Preview"
l["phands.menu.choose"] = "Choose a pose"
l["phands.menu.choose.description"] = "Hover over a pose to see it on your own model."
l["phands.menu.hint"] = "Left click: take pose   ·   Drag preview: rotate model"
l["phands.menu.cancel"] = "Cancel"
l["phands.menu.locked"] = "Locked"
l["phands.menu.choose.short"] = "Hover a pose = preview"
l["phands.menu.hint.compact"] = "Click: pose  ·  Right click/ESC: close"

mvp.language.Register("en", l)
