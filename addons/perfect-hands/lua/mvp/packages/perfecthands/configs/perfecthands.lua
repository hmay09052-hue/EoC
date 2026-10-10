local PERFECTHANDS_SECTION = mvp.config.RegisterSection("perfecthands")

local APPEARANCE_GROUP = mvp.config.RegisterCategory("appearance", PERFECTHANDS_SECTION, 1)

mvp.config.Add("phands.useIcons", true, {
    description = "If enabled, animations will be using icons, otherwise they will use text.",
    category = APPEARANCE_GROUP,

    ui = {}
}, 1)

mvp.config.Add("phands.useModels", true, {
    description = "If enabled, animations will be using player model, FPS heavy.",
    category = APPEARANCE_GROUP,

    ui = {}
}, 2)

mvp.config.Add("phands.iconsTheme", "clones2", {
    description = "Theme for the icons",
    category = APPEARANCE_GROUP,

    ui = {
        type = "dropdown",
        choices = function()
            local P = mvp.package.Get("perfecthands")
            local themes = P.themes.GetAll()

            local choices = {}
            for k, v in pairs(themes) do
                choices[k] = mvp.q.Lang("phands.themes." .. k)
            end

            return choices
        end
    }
}, 3)

mvp.config.Add("phands.hintMargin", 50, {
    description = "Controls the margin for the hint text.",
    category = APPEARANCE_GROUP,

    ui = {}
}, 4)

local ANIMATION_GROUP = mvp.config.RegisterCategory("animations", PERFECTHANDS_SECTION, 3)

mvp.config.Add("phands.useAnimations", true, {
    description = "Enable animation system.",
    category = ANIMATION_GROUP,

    ui = {}
}, 1)

mvp.config.Add("phands.animationAllowFreelook", true, {
    description = "Allow freelook while the animation is playing.",
    category = ANIMATION_GROUP,

    ui = {}
}, 2)

mvp.config.Add("phands.animationSpeed", 5, {
    description = "Controls how fast player's hands will move.",
    category = ANIMATION_GROUP,

    ui = {}
}, 3)

mvp.config.Add("phands.animationVelocityCutoff", 5, {
    description = "Controls the maximum velocity at which the animation will play. If the player's velocity is higher than this value, the animation will not play.",
    category = ANIMATION_GROUP,

    ui = {}
}, 4)

local INTERACTION_GROUP = mvp.config.RegisterCategory("interactions", PERFECTHANDS_SECTION, 4)

mvp.config.Add("phands.useInteractions", true, {
    description = "Enable interaction system.",
    category = INTERACTION_GROUP,

    ui = {}
}, 1)

mvp.config.Add("phands.interactionDistance", 100, {
    description = "Controls the maximum distance at which the player can interact with objects.",
    category = INTERACTION_GROUP,

    ui = {}
}, 2)

mvp.config.Add("phands.interactionWeightMultiplier", 1, {
    description = "Controls the weight multiplier for the interaction system. This will affect how heavy the objects feel when the player is holding them.",
    category = INTERACTION_GROUP,

    ui = {}
}, 3)