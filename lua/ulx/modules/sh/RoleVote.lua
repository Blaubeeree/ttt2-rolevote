local CATEGORY_NAME = "RoleVote"

------------------------------ rv_start ---------------------------
function ulx.rv_start(calling_ply, duration)
    if not RoleVote.started then
        RoleVote:Start(duration)
        ulx.fancyLogAdmin(calling_ply, "#A started RoleVote!")
    end
end

local rv_start = ulx.command(CATEGORY_NAME, "ulx rv_start", ulx.rv_start, "!rv_start")

rv_start:addParam{
    type = ULib.cmds.NumArg,
    default = 30,
    hint = "duration",
    ULib.cmds.round, ULib.cmds.optional
}

rv_start:defaultAccess(ULib.ACCESS_ADMIN)
rv_start:help("Starts a vote")

------------------------------ rv_end -----------------------------
function ulx.rv_end(calling_ply)
    if RoleVote.started then
        RoleVote:End()
        ulx.fancyLogAdmin(calling_ply, "#A ended RoleVote!")
    end
end

local rv_end = ulx.command(CATEGORY_NAME, "ulx rv_end", ulx.rv_end, "!rv_end")
rv_end:defaultAccess(ULib.ACCESS_ADMIN)
rv_end:help("Ends the current vote")

------------------------------ rv_cancel --------------------------
function ulx.rv_cancel(calling_ply)
    if RoleVote.started then
        RoleVote:Cancel()
        ulx.fancyLogAdmin(calling_ply, "#A canceled RoleVote!")
    end
end

local rv_cancel = ulx.command(CATEGORY_NAME, "ulx rv_cancel", ulx.rv_cancel, "!rv_cancel")
rv_cancel:defaultAccess(ULib.ACCESS_ADMIN)
rv_cancel:help("Cancels the current vote (without banning/activating a role)")