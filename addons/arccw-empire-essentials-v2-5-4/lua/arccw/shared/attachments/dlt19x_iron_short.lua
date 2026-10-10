att.PrintName = "DLT-19x Short-range Ironsight"
att.Icon = nil
att.SortOrder = 1
att.Description = "DLT-19x short range ironsight"
att.Desc_Pros = {}
att.Desc_Cons = {}

att.AutoStats = true

att.Slot = "dlt19x_iron"
att.ActivateElements = {"dlt19x_short"}

att.Override_IronSightStruct = {
    Pos = Vector(-3.4, -5, 1.45),
    Ang = Angle(2, 0.5, 9),
    Magnification = 2.5,
    SwitchToSound = "empire-essentials/interaction/zoom_start.mp3",
    SwitchFromSound = "empire-essentials/interaction/zoom_end.mp3",
    ViewModelFOV = 55,
}
