att.PrintName = "DLT-19 Short-range Ironsight"
att.Icon = nil
att.SortOrder = 1
att.Description = "DLT-19 short range ironsight"
att.Desc_Pros = {}
att.Desc_Cons = {}

att.AutoStats = true

att.Slot = "dlt19_iron"
att.ActivateElements = {"dlt19_short"}

att.Override_IronSightStruct = {
    Pos = Vector(-2.86, -8, 0.3),
    Ang = Angle(1.394, 0.428, 0),
    Magnification = 2.5,
    SwitchToSound = "empire-essentials/interaction/zoom_start.mp3",
    SwitchFromSound = "empire-essentials/interaction/zoom_end.mp3",
    ViewModelFOV = 55,
}
