local P = mvp.meta.package:New()

P:SetIcon(Material("mvp/perfecthands/package_icon.png", "smooth"))
P:SetName("Perfect Hands")
P:SetVersion("3.0.3")
P:SetDescription("Perfect hands, addon which adds perfect hands SWEP, as its name says!")
P:SetAuthor("Kot")

P:AddDependency("radialmenu")

P:AddConfigsFolder()
P:AddFolder("languages")
P:AddFolder("animations")
P:AddFile("sh_themes.lua")
P:AddFile("cl_credits.lua")
P:AddFile("cl_menu.lua")

hook.Add("mvp.package.Registered", "mvp.phands.RegisterThemes", function(pckg)
    if (pckg ~= P) then
        return
    end

    mvp.q.LogInfo("Perfect Hands", "Registering themes")
    hook.Run("mvp.phands.RegisterThemes")
    mvp.q.LogInfo("Perfect Hands", "Themes registered")
end)

mvp.package.Register(P)