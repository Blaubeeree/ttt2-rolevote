CreateConVar("ttt_rolevote_enabled", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Enable/Disable RoleVote"):GetBool()
CreateConVar("ttt_rolevote_voteban", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "0: The players vote the roles that get activated 1: The players vote the roles that get banned"):GetBool()
CreateConVar("ttt_rolevote_min_players", 7, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Sets the minimum players that have to be online for RoleVote being active", 1):GetInt()
CreateConVar("ttt_rolevote_count", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Sets how many roles will be banned/activated", 1):GetInt()
CreateConVar("ttt_rolevote_role_cooldown", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Sets how many times a role can't be voted on after it has won a vote.", 0):GetInt()
CreateConVar("ttt_rolevote_always_aktiv", "", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Always activated roles (separated by ,)"):GetString()

hook.Add("TTTUlxInitCustomCVar", "TTTRolevoteInitRWCVar", function(name)
    ULib.replicatedWritableCvar("ttt_rolevote_enabled", "rep_ttt_rolevote_enabled", GetConVar("ttt_rolevote_enabled"):GetBool(), true, false, name)
    ULib.replicatedWritableCvar("ttt_rolevote_voteban", "rep_ttt_rolevote_voteban", GetConVar("ttt_rolevote_voteban"):GetBool(), true, false, name)
    ULib.replicatedWritableCvar("ttt_rolevote_min_players", "rep_ttt_rolevote_min_players", GetConVar("ttt_rolevote_min_players"):GetInt(), true, false, name)
    ULib.replicatedWritableCvar("ttt_rolevote_count", "rep_ttt_rolevote_count", GetConVar("ttt_rolevote_count"):GetInt(), true, false, name)
    ULib.replicatedWritableCvar("ttt_rolevote_role_cooldown", "rep_ttt_rolevote_role_cooldown", GetConVar("ttt_rolevote_role_cooldown"):GetInt(), true, false, name)
    ULib.replicatedWritableCvar("ttt_rolevote_always_aktiv", "rep_ttt_rolevote_always_aktiv", GetConVar("ttt_rolevote_always_aktiv"):GetString(), true, false, name)
end)

if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    hook.Add("TTTUlxModifyAddonSettings", "TTTRolevoteModifySettings", function(name)
        local tttrspnl = xlib.makelistlayout{
            w = 415,
            h = 318,
            parent = xgui.null
        }

        local tttrsclp = vgui.Create("DCollapsibleCategory", tttrspnl)
        tttrsclp:SetSize(390, 155)
        tttrsclp:SetExpanded(1)
        tttrsclp:SetLabel("RoleVote Settings")
        local tttrslst = vgui.Create("DPanelList", tttrsclp)
        tttrslst:SetPos(5, 25)
        tttrslst:SetSize(390, 155)
        tttrslst:SetSpacing(5)

        tttrslst:AddItem(xlib.makecheckbox{
            label = "ttt_rolevote_enabled (Def. 1)",
            repconvar = "rep_ttt_rolevote_enabled",
            parent = tttrslst
        })

        tttrslst:AddItem(xlib.makecheckbox{
            label = "ttt_rolevote_voteban (Def. 1)",
            repconvar = "rep_ttt_rolevote_voteban",
            parent = tttrslst
        })

        tttrslst:AddItem(xlib.makeslider{
            label = "ttt_rolevote_min_players (Def. 7)",
            repconvar = "rep_ttt_rolevote_min_players",
            min = 1,
            max = 30,
            decimal = 0,
            parent = tttrslst
        })

        tttrslst:AddItem(xlib.makeslider{
            label = "ttt_rolevote_count (Def. 1)",
            repconvar = "rep_ttt_rolevote_count",
            min = 1,
            max = 30,
            decimal = 0,
            parent = tttrslst
        })

        tttrslst:AddItem(xlib.makeslider{
            label = "ttt_rolevote_role_cooldown (Def. 1)",
            repconvar = "rep_ttt_rolevote_role_cooldown",
            min = 0,
            max = 30,
            decimal = 0,
            parent = tttrslst
        })

        tttrslst:AddItem(xlib.makelabel{
            label = "Always activated roles (separated by ,):",
            parent = tttrslst
        })

        tttrslst:AddItem(xlib.maketextbox{
            repconvar = "rep_ttt_rolevote_always_aktiv",
            parent = tttrslst
        })

        xgui.hookEvent("onProcessModules", nil, tttrspnl.processModules)
        xgui.addSubModule("RoleVote", tttrspnl, nil, name)
    end)
end