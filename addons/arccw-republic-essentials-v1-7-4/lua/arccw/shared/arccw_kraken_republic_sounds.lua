-- Weapons
sound.Add( {
    name = "ArcCW_Kraken.ShotgunLoad",
    channel = CHAN_ITEM + 6,
    volume = 0.5,
    level = 100,
    pitch = {90, 115},
    sound = {
        "arccw/kraken/republic/sb2/load1.wav",
        "arccw/kraken/republic/sb2/load2.wav",
        "arccw/kraken/republic/sb2/load3.wav",
        "arccw/kraken/republic/sb2/load4.wav",
        "arccw/kraken/republic/sb2/load5.wav",
        "arccw/kraken/republic/sb2/load6.wav"
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_GEOBLASTER",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/sonicblaster/sonicblaster.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_GEOBLASTER_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/sonicblaster/sonicblaster.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_B2HAND",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/b2/sw01_weapons_blasters_e5-b2_laser_close_var_01_01.wav",
        "arccw/kraken/republic/b2/sw01_weapons_blasters_e5-b2_laser_close_var_01_02.wav",
        "arccw/kraken/republic/b2/sw01_weapons_blasters_e5-b2_laser_close_var_01_03.wav",
        "arccw/kraken/republic/b2/sw01_weapons_blasters_e5-b2_laser_close_var_01_04.wav",
        "arccw/kraken/republic/b2/sw01_weapons_blasters_e5-b2_laser_close_var_01_05.wav",
        "arccw/kraken/republic/b2/sw01_weapons_blasters_e5-b2_laser_close_var_01_05.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_B2HAND_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_01.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_02.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_03.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_04.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_05.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_06.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_07.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_08.wav",
        "arccw/kraken/empire/e11/sw02_weapons_blasters_e11_laser_distant_var_06_09.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5C",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_close_var_02_01.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_close_var_02_02.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_close_var_02_03.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_close_var_02_04.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_close_var_02_05.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_close_var_02_06.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_close_var_02_07.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5C_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_distant_var_01_05.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_distant_var_01_06.wav",
        "arccw/kraken/republic/e5c/sw02_weapons_blasters_e-5c_laser_distant_var_01_07.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5S",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_close_var_01_01.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_close_var_01_02.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_close_var_01_03.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_close_var_01_04.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_close_var_01_05.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5S_Distant",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/e5s/sw02_weapons_blasters_e5s_laser_distant_var_01_05.wav",
    }  
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_SB2",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/sb2/sb2.wav",
        "arccw/kraken/republic/sb2/sb2.wav",
        "arccw/kraken/republic/sb2/sb2.wav",
        "arccw/kraken/republic/sb2/sb2.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_SB2_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/scattergun/sw02_weapons_blaster_scattergun_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/scattergun/sw02_weapons_blaster_scattergun_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/scattergun/sw02_weapons_blaster_scattergun_laser_distant_var_01_03.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5BX",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_close_var_01_01.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_close_var_01_02.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_close_var_01_03.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_close_var_01_04.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_close_var_01_05.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5BX_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_bx_laser_distant_var_01_04.wav",
    }
} )


sound.Add( {
    name = "ArcCW_Kraken.SW_RG4D",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_01.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_02.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_03.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_04.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_05.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_06.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_07.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_08.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_09.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_10.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_11.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_close_var_01_12.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_RG4D_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_distant_var_01_05.wav",
        "arccw/kraken/republic/rg-4d/sw02_weapons_blasters_rg-4d_laser_distant_var_01_06.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_close_var_04_01.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_close_var_04_02.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_close_var_04_03.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_close_var_04_04.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_close_var_04_05.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_close_var_04_06.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E5_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_distant_var_01_05.wav",
        "arccw/kraken/republic/e-5/sw02_weapons_blasters_e5_laser_distant_var_01_06.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15SA",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc15sa/dc15sa.wav",
        "arccw/kraken/republic/dc15sa/dc15sa.wav",
        "arccw/kraken/republic/dc15sa/dc15sa.wav",
        "arccw/kraken/republic/dc15sa/dc15sa.wav",
    }
} )
sound.Add( {
    name = "ArcCW_Kraken.SW_WESTAR",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/m5/m5.wav",
        "arccw/kraken/republic/m5/m5.wav",
        "arccw/kraken/republic/m5/m5.wav",
        "arccw/kraken/republic/m5/m5.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_WESTAR_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/m5/m5.wav",
        "arccw/kraken/republic/m5/m5.wav",
        "arccw/kraken/republic/m5/m5.wav",
        "arccw/kraken/republic/m5/m5.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_E9",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/e-series/e11.wav",
        "arccw/kraken/republic/e-series/e11.wav",
        "arccw/kraken/republic/e-series/e11.wav",
        "arccw/kraken/republic/e-series/e11.wav",
        "arccw/kraken/republic/e-series/e11.wav",
        "arccw/kraken/republic/e-series/e11.wav",
    }
} )
sound.Add( {
    name = "ArcCW_Kraken.SW_Z6",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_close_var_01_02.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_close_var_01_03.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_close_var_01_04.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_close_var_01_05.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_close_var_01_06.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_close_var_01_07.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_close_var_01_08.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_Z6_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_05.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_06.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_07.wav",
        "arccw/kraken/republic/z6rotaryblaster/sw02_blasters_z6rotaryblaster_laser_distant_var_01_08.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC17M_SNIPER",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC17M_SNIPER_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
        "arccw/kraken/republic/dc17m_sniper_fire0.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC17",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_01.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_02.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_03.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_04.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_05.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_06.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_07.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_08.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_close_var_07_09.wav"
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC17_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_05.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_06.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_07.wav",
        "arccw/kraken/republic/dc17/sw02_weapons_blasters_dc17_laser_distant_var_01_08.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC17M",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_close_var_01_01.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_close_var_01_02.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_close_var_01_03.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_close_var_01_04.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_close_var_01_05.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC17M_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_distant_var_01_05.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_distant_var_01_06.wav",
        "arccw/kraken/republic/dc17m/sw02_weapons_blasters_dc17m_laser_distant_var_01_07.wav"
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15LE",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc15le.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15LE_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/dc15le.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15A",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_01.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_02.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_03.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_04.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_05.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_06.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_07.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_08.wav",
        "arccw/kraken/republic/dc15/sw02_weapons_blasters_dc15_laser_close_var_03_09.wav"
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15S",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_01.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_02.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_03.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_04.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_05.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_06.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_07.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_close_var_08_08.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15A_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_distant_var_06_01.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_distant_var_06_02.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_distant_var_06_03.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_distant_var_06_04.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_distant_var_06_05.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_distant_var_06_06.wav",
        "arccw/kraken/republic/e11/sw02_weapons_blasters_e11_laser_distant_var_06_07.wav"
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15SA",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc15sa/fire0.wav",
        "arccw/kraken/republic/dc15sa/fire0.wav",
        "arccw/kraken/republic/dc15sa/fire0.wav",
        "arccw/kraken/republic/dc15sa/fire0.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15SA_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/dc15sa/fire0.wav",
        "arccw/kraken/republic/dc15sa/fire0.wav",
        "arccw/kraken/republic/dc15sa/fire0.wav",
        "arccw/kraken/republic/dc15sa/fire0.wav",
    }
} )


sound.Add( {
    name = "ArcCW_Kraken.SW_DC15XR",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dc15xr/fire1.wav",
        "arccw/kraken/republic/dc15xr/fire2.wav",
        "arccw/kraken/republic/dc15xr/fire3.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15XR_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/dc15xr/fire1.wav",
        "arccw/kraken/republic/dc15xr/fire2.wav",
        "arccw/kraken/republic/dc15xr/fire3.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15X",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_close_var_01_01.wav",
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_close_var_01_02.wav",
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_close_var_01_03.wav",
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_close_var_01_04.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DC15X_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/dlt19x/sw02_weapons_blaster_dlt19x_laser_distant_var_01_04.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DP23",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/dp23.wav",
        "arccw/kraken/republic/dp23.wav",
        "arccw/kraken/republic/dp23.wav",
        "arccw/kraken/republic/dp23.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_DP23_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/scattergun/sw02_weapons_blaster_scattergun_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/scattergun/sw02_weapons_blaster_scattergun_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/scattergun/sw02_weapons_blaster_scattergun_laser_distant_var_01_03.wav",
    }
} )


sound.Add( {
    name = "ArcCW_Kraken.SW_VALKEN",
    channel = CHAN_WEAPON + 6,
    volume = 0.7,
    level = 60,
    pitch = {95, 105},
    sound = {
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_close_var_01_01.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_close_var_01_02.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_close_var_01_03.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_close_var_01_04.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_close_var_01_05.wav",
    }
} )

sound.Add( {
    name = "ArcCW_Kraken.SW_VALKEN_Distant",
    channel = ArcCW.CHAN_DISTANT or 136,
    level = 90,
    pitch = {80,110},
    volume = 1.0,
    sound = {
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_distant_var_01_01.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_distant_var_01_02.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_distant_var_01_03.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_distant_var_01_04.wav",
        "arccw/kraken/republic/valken38/sw02_weapons_blasters_valken-38x_laser_distant_var_01_05.wav",
    }
} )