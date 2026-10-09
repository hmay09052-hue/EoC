att.PrintName = "DLT-19h Long Range Ironsight"
att.Icon = nil

att.SortOrder = 1

att.Description = "DLT-19h long range ironsight"
att.Desc_Pros = {}
att.Desc_Cons = {}

att.AutoStats = true

att.Slot = "dlt19h_iron"
att.ActivateElements = {"dlt19h_long"}

att.Override_IronSightStruct = {
    Pos = Vector(0, -9, 3.4),
    Ang = Angle(3, 0, 0),
    Magnification = 5,
    SwitchToSound = "empire-essentials/interaction/zoom_start.mp3",
    SwitchFromSound = "empire-essentials/interaction/zoom_end.mp3",
    ViewModelFOV = 55,
}
