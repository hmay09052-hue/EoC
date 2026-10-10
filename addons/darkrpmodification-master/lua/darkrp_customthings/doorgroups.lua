--[[---------------------------------------------------------------------------
Door groups
---------------------------------------------------------------------------
The server owner can set certain doors as owned by a group of people, identified by their jobs.


HOW TO MAKE A DOOR GROUP:
AddDoorGroup("NAME OF THE GROUP HERE, you will see this when looking at a door", Team1, Team2, team3, team4, etc.)
---------------------------------------------------------------------------]]
AddDoorGroup("Prison - NTs RGs and SKs only(VIP and event jobs as well)", TEAM_SKPVT, TEAM_SKPFC, TEAM_SKCPL, TEAM_SKSGT, TEAM_SKSSGT, TEAM_SKLT, TEAM_SKCPT, TEAM_SKMJR, TEAM_SKCOL, TEAM_SKBATTCOM, TEAM_SKREGCOM, TEAM_NTPVT, TEAM_NTPFC, TEAM_NTCPL, TEAM_NTSGT, TEAM_NTSSGT, TEAM_NTLT, TEAM_NTCPT, TEAM_NTMJR, TEAM_NTCOL, TEAM_NTBATTCOM, TEAM_NTREGCOM, TEAM_RGPVT, TEAM_RGPFC, TEAM_RGCPL, TEAM_RGSGT, TEAM_RGSSGT, TEAM_RGLT, TEAM_RGCPT, TEAM_RGMJR, TEAM_RGCOL, TEAM_RGBATTCOM, TEAM_RGREGCOM, TEAM_DARTHVADER, TEAM_YODA, TEAM_SHADOW, TEAM_BOBBA, TEAM_JEDI, TEAM_EMPERORPALPATINE, TEAM_REBEL, TEAM_REBELCOM, TEAM_AOD)
AddDoorGroup("Darth Vader and Emperor Palpatine ONLY!", TEAM_DARTHVADER, TEAM_EMPERORPALPATINE )
-- Example: AddDoorGroup("Cops and Mayor only", TEAM_CHIEF, TEAM_POLICE, TEAM_MAYOR)
-- Example: AddDoorGroup("Gundealer only", TEAM_GUN)
