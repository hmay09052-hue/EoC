crashmenu.Config = {} -- Don't touch this

-- Do NOT touch this. Assigned directly upon download of the add-on.
crashmenu.Config.ChatRoomID = '812ec738-535e-4743-8c38-3236eae81ae1' -- Chat room which will be used to discuss about the server crash

crashmenu.Config.LogoURL = "https://bell.moe/gmodstore/reconnect.png" -- Must be a direct link to an image
crashmenu.Config.Gradient = true -- Turn on gradient or not?
crashmenu.Config.Color1 = Color(1, 163, 164, 127) -- Customize the color of the border and background here.
crashmenu.Config.BigFont = "Roboto Bk" -- Font for the header.
crashmenu.Config.Font = "Roboto" -- Font for the buttons and help text
crashmenu.Config.FontShadows = true
crashmenu.Config.CrashSound = "common/bugreporter_failed.wav" -- Sound path that will be played when the panel shows up. Comment this line or set it to nil to disable the sound.

crashmenu.Config.Title = "Ups, der Server scheint abgestürzt zu sein."
crashmenu.Config.SubTitle = [[
Falls der Server sich nicht erholt, wirst du in Kürze automatisch neu verbunden.
In der Zwischenzeit kannst du dich gerne mit den anderen Spielern im Chat unten unterhalten.
Vergiss nicht, auch unserem Discord beizutreten.
]]

-- This table is useful for adding other buttons to the screen.
-- Adding a button with an "IP" field will redirect clients to another server upon clicking it.
-- Adding a button with an "URL" field will open a page in the Steam overlay for the client upon clicking it.
-- DON'T make a button with both, "IP" will take priority over "URL".
crashmenu.Config.Servers = { -- Examples below
    {
        Name = "Discord",
        URL = "https://discord.gg/kNNv5Txy53"
    },
}
