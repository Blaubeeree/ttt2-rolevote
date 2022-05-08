util.AddNetworkString("RoleVote_open")
util.AddNetworkString("RoleVote_close")
util.AddNetworkString("RoleVote_client_ready")
util.AddNetworkString("RoleVote_vote")
util.AddNetworkString("RoleVote_refresh_buttons")
util.AddNetworkString("RoleVote_msg")
util.AddNetworkString("RoleVote_console")
local version = "26/01/2021"
local always_active
local cooldown
local votes = {}
local winners = {}
RoleVote.started = false

local function reloadCooldown()
    cooldown = {}

    if not sql.TableExists("rolevote") then
        sql.Query("CREATE TABLE rolevote(roles TEXT NOT NULL PRIMARY KEY)")
    end

    if sql.Query("SELECT * FROM rolevote") ~= nil then
        for _, v in pairs(sql.Query("SELECT * FROM rolevote")) do
            table.Add(cooldown, util.JSONToTable(v.roles))
        end
    end
end

reloadCooldown()

local function reloadAlwaysAktive()
    always_active = string.Split(GetConVar("ttt_rolevote_always_active"):GetString(), ",")
    table.Add(always_active, {INNOCENT.name, TRAITOR.name, DETECTIVE.name})

    for key, role in pairs(always_active) do
        always_active[key] = string.lower(string.Trim(role))
    end
end

local function EnoughPlayers()
    local ready = 0
    local plys = player.GetAll()

    for i = 1, #plys do
        local ply = plys[i]
        if not IsValid(ply) or not ply:ShouldSpawn() then continue end
        ready = ready + 1
    end

    return ready >= GetConVar("ttt_minimum_players"):GetInt()
end

function RoleVote:Start(time)
    if not RoleVote.started then
        votes = {}
        RoleVote.started = true
        time = time and time or 20

        if time >= 0 then
            timer.Create("RoleVote_VoteTimer", time, 1, function()
                RoleVote:End()
            end)
        end

        hook.Remove("TTT2RoleNotSelectable", "TTTRolevoteDisableRoles")
    end

    local roles = {}

    for _, role in pairs(GetRoles()) do
        if not role:IsSelectable(false) or
            table.HasValue(cooldown, role.name) or
            table.HasValue(always_active, role.name) or
            table.HasValue(always_active, role.abbr)
        then continue end

        table.insert(roles, role.index)
    end

    if #roles < 1 then
        ErrorNoHalt("[RoleVote] No roles avalible, canceling vote... (this could be because of every role being disabled or on cooldown)\n")

        RoleVote:Cancel()

        sql.Query("DELETE FROM rolevote WHERE rowid IN (SELECT rowid FROM rolevote LIMIT 1);")
        reloadCooldown()

        return
    end

    net.Start("RoleVote_open")
    net.WriteBool(GetConVar("ttt_rolevote_voteban"):GetBool())
    net.WriteTable(roles)
    net.Broadcast()
    net.Start("RoleVote_refresh_buttons")
    net.WriteTable(votes)
    net.Broadcast()
end

function RoleVote:End()
    local function GetWinningKey(tbl)
        local highest = -math.huge
        local winner = nil

        for k, v in RandomPairs(tbl) do
            if (#v > highest) then
                winner = k
                highest = #v
            end
        end

        return winner
    end

    RoleVote:Cancel()
    winners = {}

    for i = 1, GetConVar("ttt_rolevote_count"):GetInt() do
        local r = GetWinningKey(votes)
        if votes[r] == nil or #votes[r] <= 0 then continue end
        table.insert(winners, string.lower(r))
        votes[r] = nil
    end

    if #winners <= 0 then return end
    local msg = {}

    for i = 1, #winners do
        table.insert(msg, winners[i] == "none" and Color(0,0,0) or GetRoleByName(winners[i]).color)
        table.insert(msg, string.SetChar(winners[i], 1, string.upper(winners[i][1])))

        if i ~= #winners then
            table.insert(msg, ", ")
        end
    end

    table.insert(msg, Color(255, 255, 255))
    table.insert(msg, " won the vote.")
    MsgC("[RoleVote] ", unpack(msg))
    MsgC("\n")
    net.Start("RoleVote_msg")
    net.WriteTable(msg)
    net.Broadcast()
    sql.Query("INSERT INTO rolevote(roles) VALUES('" .. util.TableToJSON(winners) .. "')")

    while (tonumber(sql.Query("SELECT COUNT(*) FROM rolevote")[1]["COUNT(*)"]) > GetConVar("ttt_rolevote_role_cooldown"):GetInt()) do
        sql.Query("DELETE FROM rolevote WHERE rowid IN (SELECT rowid FROM rolevote LIMIT 1);")
    end

    reloadCooldown()

    hook.Add("TTT2RoleNotSelectable", "TTTRolevoteDisableRoles", function(r)
        if GetConVar("ttt_rolevote_voteban"):GetBool() then
            return table.HasValue(winners, r.name) or nil
        else
            return not table.HasValue(winners, r.name) and
                not table.HasValue(always_active, r.name) and
                not table.HasValue(always_active, r.abbr)
                or nil
        end
    end)
end

function RoleVote:Cancel()
    hook.Remove("TTTPrepareRound", "TTTRolevotePrepareRound")
    hook.Remove("PlayerSpawn", "TTTRolevotePlayerSpawn")

    if timer.Exists("RoleVote_PrepTimer") then
        timer.Remove("RoleVote_PrepTimer")
    end

    if timer.Exists("RoleVote_VoteTimer") then
        timer.Remove("RoleVote_VoteTimer")
    end

    RoleVote.started = false
    net.Start("RoleVote_close")
    net.Broadcast()
end

-- autostart
local function PrepTimerFinished()
    if EnoughPlayers() then
        RoleVote:End()
    end
end

-- use timer instead of TTTBeginRound hook so that function is called just before the round starts when the roles aren't yet selected
hook.Add("Initialize", "TTTRolevoteInitialize", function()
    reloadAlwaysAktive()
    cvars.AddChangeCallback("ttt_rolevote_always_active", reloadAlwaysAktive)

    if not GetConVar("ttt_rolevote_autostart"):GetBool() then return end
    local firstPrep = true

    hook.Add("TTTPrepareRound", "TTTRolevotePrepareRound", function()
        if not firstPrep then
            timer.Create("RoleVote_PrepTimer", GetConVar("ttt_preptime_seconds"):GetInt(), 1, PrepTimerFinished)
        else
            timer.Create("RoleVote_PrepTimer", GetConVar("ttt_firstpreptime"):GetInt(), 1, PrepTimerFinished)
        end

        firstPrep = false
    end)

    hook.Add("PlayerSpawn", "TTTRolevotePlayerSpawn", function()
        if GetConVar("ttt_rolevote_min_players"):GetInt() > #player.GetAll() or RoleVote.started then return end
        RoleVote:Start(-1)
    end)
end)

-- networking
net.Receive("RoleVote_client_ready", function(len, ply)
    if RoleVote.started then
        RoleVote:Start()
    end
end)

net.Receive("RoleVote_vote", function(len, ply)
    local role = net.ReadString()
    votes[role] = votes[role] or {}
    -- if same role clicked again remove vote
    local removeVote = table.HasValue(votes[role], ply:SteamID64())

    for _, plys in pairs(votes) do
        table.RemoveByValue(plys, ply:SteamID64())
    end

    if not removeVote then
        table.insert(votes[role], ply:SteamID64())
    end

    net.Start("RoleVote_refresh_buttons")
    net.WriteTable(votes)
    net.Broadcast()
end)

-- concommands
concommand.Add("rolevote_version", function(ply)
    local msg = {}
    table.insert(msg, Color(255, 255, 255))
    table.insert(msg, "----- RoleVote Addon -----\n")
    table.insert(msg, "By:      Blaubeeree\n")
    table.insert(msg, "Version: " .. version .. "\n")

    net.Start("RoleVote_console")
    net.WriteTable(msg)
    net.Send(ply)
end)

concommand.Add("printRoles", function(ply)
    local function addRoles(active, tbl)
        tbl = tbl or {}
        local i = 0

        for _, role in pairs(GetRoles()) do
            if active and role:IsSelectable(false) or not active and not role:IsSelectable(false) and not role.notSelectable then
                i = i + 1
                table.insert(tbl, role.color)
                table.insert(tbl, string.SetChar(role.name, 1, string.upper(role.name[1])) .. " \t")

                if string.len(role.name) < 7 then
                    table.insert(tbl, "\t")
                end

                if i % 5 == 0 then
                    table.insert(tbl, "\n")
                end
            end
        end

        table.insert(tbl, "\n\n")

        return i
    end

    local msg = {}

    if #winners ~= 0 then
        table.insert(msg, Color(255, 255, 255))
        table.insert(msg, "Last Vote Winner: \n")

        for i = 1, #winners do
            table.insert(msg, winners[i] == "none" and Color(0,0,0) or GetRoleByName(winners[i]).color)
            table.insert(msg, string.SetChar(winners[i], 1, string.upper(winners[i][1])) .. " \t")

            if string.len(winners[i]) < 7 then
                table.insert(msg, "\t")
            end

            if i % 5 == 0 then
                table.insert(msg, "\n")
            end
        end

        table.insert(msg, "\n\n")
    end

    table.insert(msg, Color(255, 255, 255))
    table.insert(msg, "Active Roles: \n")
    addRoles(true, msg)

    if addRoles(false) > 0 then
        table.insert(msg, Color(255, 255, 255))
        table.insert(msg, "Deactivated Roles: \n")
        addRoles(false, msg)
    end

    net.Start("RoleVote_console")
    net.WriteTable(msg)
    net.Send(ply)
end)
