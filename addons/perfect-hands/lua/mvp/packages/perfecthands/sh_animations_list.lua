local P = mvp.package.Get()

P.animations.list = {}
P.animations.listSeq = {}

P.animations.Add("salute", {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(80, -95, -77.5),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(35, -125, -5),
})

P.animations.Add("surrender", {
    ["ValveBiped.Bip01_L_Forearm"] = Angle(25, -65, 25),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-25, -65, -25),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-70, -180, 70),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(70, -180, -70)
}) 

P.animations.Add("armsinfront", {
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-43, -107, 15),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(20, -57, -6),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-28, -59, 1),
    ["ValveBiped.Bip01_R_Thigh"] = Angle(4, -6, -0),
    ["ValveBiped.Bip01_L_Thigh"] = Angle(-7, -0, 0),
    ["ValveBiped.Bip01_L_Forearm"] = Angle(51, -120, -18),
    ["ValveBiped.Bip01_R_Hand"] = Angle(14, -33, -7),
    ["ValveBiped.Bip01_L_Hand"] = Angle(25, 31, -14),
})

P.animations.Add("armsbehind", {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(3, 15, 2),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-63, 1 , -84),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(3, 15, 2.654),
    ["ValveBiped.Bip01_L_Forearm"] = Angle(53, -29, 31),
    ["ValveBiped.Bip01_R_Thigh"] = Angle(4, 0, 0),
    ["ValveBiped.Bip01_L_Thigh"] = Angle(-8, 0, 0),
})

P.animations.Add("armsbehindhead", {
    ["ValveBiped.Bip01_L_Forearm"] = Angle(25,-115,15),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-32,-115,-15),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-50,-210,80),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(50,-210,-80),
})

P.animations.Add("armsonbelt", {
    ["ValveBiped.Bip01_L_Forearm"] = Angle(50,-90,5),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-50,-90,5),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-40,30,-20),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(40,30,20),
})

P.animations.Add("comlink", {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(32.9448, -103.5211, 2.2273),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-90.3271, -31.3616, -41.8804),
    ["ValveBiped.Bip01_R_Hand"] = Angle(0,0,-24),
})

P.animations.Add("highfive", {
    ["ValveBiped.Bip01_L_Forearm"] = Angle(25,-65,25),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-70,-180,70),
})

P.animations.Add("hololink", {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(10,-20),
    ["ValveBiped.Bip01_R_Hand"] = Angle(0,1,50),
    ["ValveBiped.Bip01_Head1"] = Angle(0,-30,-20),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(0,-65,39.8863),
})

P.animations.Add("point", {
    ["ValveBiped.Bip01_R_Finger2"] = Angle(4, -52, 0),
    ["ValveBiped.Bip01_R_Finger21"] = Angle(0, -58, 0),
    ["ValveBiped.Bip01_R_Finger3"] = Angle(4, -52, 0),
    ["ValveBiped.Bip01_R_Finger31"] = Angle(0, -58, 0),
    ["ValveBiped.Bip01_R_Finger4"] = Angle(4, -52, 0),
    ["ValveBiped.Bip01_R_Finger41"] = Angle(0, -58, 0),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(25, -87, -0),
})

P.animations.Add("pensive", {
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-14.4,-106.18412780762,76.318969154358),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(23.656689071655, -58.723915100098, -5.3269416809082),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-28.913911819458, -59.408206939697, 1.0253102779388),
    ["ValveBiped.Bip01_R_Thigh"] = Angle(4.7250719070435, -6.0294013023376, -0.46876749396324),
    ["ValveBiped.Bip01_L_Thigh"] = Angle(-7.6583762168884, -0.21996378898621, 0.4060270190239),
    ["ValveBiped.Bip01_L_Forearm"] = Angle(51.038677215576, -120.44165039063, -18.86986541748),
    ["ValveBiped.Bip01_R_Hand"] = Angle(-6.224224853516, -7.906204223633, 10.8624106407166),
    ["ValveBiped.Bip01_L_Hand"] = Angle(25.959447860718, 31.564517974854, -14.979378700256),
})

P.animations.Add("typing", {
    ["ValveBiped.Bip01_L_Forearm"] = Angle(0,0,0),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(0,0,0),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-28,-65,50),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(20,-65,-50),
})

-- Attention animation by TheCookieYT
P.animations.Add("attention", {
    ["ValveBiped.Bip01_Head1"] = Angle( 0,12,0 ),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(-6, -6, 0),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-9, 0, 0),
    ["ValveBiped.Bip01_L_Forearm"] = Angle(9, 0, 0),
    ["ValveBiped.Bip01_R_Thigh"] = Angle(-3, 0, 0),
    ["ValveBiped.Bip01_L_Thigh"] = Angle(3, 5, 0),
    ["ValveBiped.Bip01_R_Foot"] = Angle(20, 0, 0),
    ["ValveBiped.Bip01_L_Foot"] = Angle(-20, 0, 0),
    ["ValveBiped.Bip01_R_Hand"] = Angle(0, 0, 20),
    ["ValveBiped.Bip01_L_Hand"] = Angle(0, 0, -20),
})

-- Middle finger animation by TheCookieYT
P.animations.Add("middlefinger", {
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(15,-55,-0),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(0,-55,-0),
    ["ValveBiped.Bip01_R_Hand"] = Angle(20,20,90),
    ["ValveBiped.Bip01_R_Finger1"] = Angle(20,-40,-0),
    ["ValveBiped.Bip01_R_Finger3"] = Angle(0,-30,0),
    ["ValveBiped.Bip01_R_Finger4"] = Angle(-10,-40,0),
    ["ValveBiped.Bip01_R_Finger11"] = Angle(-0,-70,-0),
    ["ValveBiped.Bip01_R_Finger31"] = Angle(0,-70,0),
    ["ValveBiped.Bip01_R_Finger41"] = Angle(0,-70,0),
    ["ValveBiped.Bip01_R_Finger12"] = Angle(-0,-70,-0),
    ["ValveBiped.Bip01_R_Finger32"] = Angle(0,-70,0),
    ["ValveBiped.Bip01_R_Finger42"] = Angle(0,-70,-0),
})

P.animations.Add("kneel", {
    ["Animation.ZOffset"] = -17,

    ["ValveBiped.Bip01_L_Forearm"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_R_Forearm"] = Angle(-90, -30, -70),
    ["ValveBiped.Bip01_L_UpperArm"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle(50, -20, 40),
    ["ValveBiped.Bip01_Pelvis"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_Spine"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_Spine4"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_R_Calf"] = Angle(0, 90, 0),
    ["ValveBiped.Bip01_L_Calf"] = Angle(0, 80, 0),
    ["ValveBiped.Bip01_R_Foot"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_L_Foot"] = Angle(0, 48.5, 0),
    ["ValveBiped.Bip01_R_Thigh"] = Angle(0, -90, 0),
    ["ValveBiped.Bip01_L_Thigh"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_R_Hand"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_L_Hand"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_L_Finger2"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_L_Finger11"] = Angle(0, 0, 0),
    ["ValveBiped.Bip01_Head1"] = Angle(0, -15, 0)
})