local enabled = GetConVar("ttt_rolevote_enabled"):GetBool()
local voteban = GetConVar("ttt_rolevote_voteban"):GetBool()
local minPlayers = GetConVar("ttt_rolevote_min_players"):GetInt()
local count = GetConVar("ttt_rolevote_count"):GetInt()
local role_cooldown = GetConVar("ttt_rolevote_role_cooldown"):GetInt()
local always_active = string.Split(GetConVar("ttt_rolevote_always_aktiv"):GetString(), ",")

for key, role in pairs(always_active) do
    always_active[key] = string.Trim(role)
end

util.AddNetworkString("RoleVote_open")
util.AddNetworkString("RoleVote_client_ready")
util.AddNetworkString("RoleVote_vote")
util.AddNetworkString("RoleVote_refresh_buttons")
util.AddNetworkString("RoleVote_msg")
util.AddNetworkString("RoleVote_console")
local votes = {}
local winners = {}
local cd = {}
local voteEnded = false

if not sql.TableExists("rolevote") then
    sql.Query("CREATE TABLE rolevote(roles TEXT NOT NULL PRIMARY KEY)")
end

if sql.Query("SELECT * FROM rolevote") ~= nil then
    for _, v in pairs(sql.Query("SELECT * FROM rolevote")) do
        table.Add(cd, util.JSONToTable(v.roles))
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

    return ready >= minPlayers
end

local function EndVote()
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

    voteEnded = true

    for i = 1, count do
        local r = GetWinningKey(votes)
        if votes[r] == nil or #votes[r] <= 0 then continue end
        table.insert(winners, string.lower(r))
        votes[r] = nil
    end

    sql.Query("INSERT INTO rolevote(roles) VALUES('" .. util.TableToJSON(winners) .. "')")

    while (tonumber(sql.Query("SELECT COUNT(*) FROM rolevote")[1]["COUNT(*)"]) > role_cooldown) do
        sql.Query("DELETE FROM rolevote WHERE rowid IN (SELECT rowid FROM rolevote LIMIT 1);")
    end

    hook.Add("TTT2RoleNotSelectable", "TTTRolevoteDisableRoles", function(r)
        if voteban then
            return table.HasValue(winners, r.name) or nil
        else
            return not table.HasValue(winners, r.name) or nil
        end
    end)
end

local function PrepTimerFinished()
    if EnoughPlayers() then
        hook.Remove("TTTPrepareRound", "TTTRolevotePrepareRound")
        if not enabled or minPlayers > #player.GetAll() then return end
        EndVote()
    else
        timer.Adjust("RoleVote_PrepTimer", GetConVar("ttt_preptime_seconds"):GetInt(), 1, PrepTimerFinished)
        timer.Stop("RoleVote_PrepTimer")
    end
end

-- use timer instead of TTTBeginRound hook so that function is called just before the round starts when the roles aren't yet selected
hook.Add("Initialize", "TTTRolevoteInitialize", function()
    if not TTT2 then return end
    timer.Create("RoleVote_PrepTimer", GetConVar("ttt_firstpreptime"):GetInt(), 1, PrepTimerFinished)
    timer.Stop("RoleVote_PrepTimer")

    hook.Add("TTTPrepareRound", "TTTRolevotePrepareRound", function()
        timer.Start("RoleVote_PrepTimer")
    end)
end)

hook.Add("TTTBeginRound", "TTTRolevoteBeginRound", function()
    voteEnded = true
    local msg = {}
    if #winners <= 0 then return end

    for i = 1, #winners do
        table.insert(msg, GetRoleByName(winners[i]).color)
        table.insert(msg, string.SetChar(winners[i], 1, string.upper(winners[i][1])))

        if i ~= #winners then
            table.insert(msg, ", ")
        end
    end

    table.insert(msg, Color(255, 255, 255))
    table.insert(msg, " won the vote.")
    net.Start("RoleVote_msg")
    net.WriteTable(msg)
    net.Broadcast()
    hook.Remove("TTTBeginRound", "TTTRolevoteBeginRound")
end)

net.Receive("RoleVote_client_ready", function(len, ply)
    if not enabled or minPlayers > #player.GetAll() or voteEnded then return end
    local roles = {}

    for _, role in pairs(GetRoles()) do
        if not role:IsSelectable(false) or role == INNOCENT or role == TRAITOR or role == DETECTIVE then continue end
        if table.HasValue(cd, role.name) or table.HasValue(always_active, role.name) or table.HasValue(always_active, role.abbr) then continue end

        local roleData = {
            name = string.SetChar(role.name, 1, string.upper(role.name[1])),
            color = role.color
        }

        table.insert(roles, roleData)
    end

    net.Start("RoleVote_open")
    net.WriteBool(voteban)
    net.WriteTable(roles)
    net.Broadcast()
    net.Start("RoleVote_refresh_buttons")
    net.WriteTable(votes)
    net.Broadcast()
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

concommand.Add("printRoles", function(ply)
    local function addRoles(aktive, tbl)
        tbl = tbl or {}
        local i = 0

        for _, role in pairs(GetRoles()) do
            if aktive and role:IsSelectable(false) or not aktive and not role:IsSelectable(false) and not role.notSelectable then
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
            table.insert(msg, GetRoleByName(winners[i]).color)
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
    table.insert(msg, "Aktive Roles: \n")
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