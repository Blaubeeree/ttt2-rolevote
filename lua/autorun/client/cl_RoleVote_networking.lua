net.Receive("RoleVote_open", function()
    if ispanel(RoleVote.vgui) then return end
    RoleVote.voteban = net.ReadBool()
    RoleVote.voteable = net.ReadTable()
    RoleVote.vgui = vgui.Create("RoleVote_vgui")
end)

net.Receive("RoleVote_close", function()
    if not ispanel(RoleVote.vgui) then return end
    RoleVote.vgui:SetVisible(false)
    RoleVote.vgui:Remove()
    RoleVote.vgui = nil
end)

net.Receive("RoleVote_refresh_buttons", function()
    if not ispanel(RoleVote.vgui) then return end
    RoleVote.vgui:UpdateVotes(net.ReadTable())
end)

net.Receive("RoleVote_msg", function()
    chat.AddText("[RoleVote] ", unpack(net.ReadTable()))
end)

net.Receive("RoleVote_console", function()
    MsgC(unpack(net.ReadTable()))
end)

hook.Add("InitPostEntity", "TTTRolevoteInitPostEntity", function()
    if not TTT2 then return end
    AddTTT2AddonDev("76561198329270449")

    bind.Register("RoleVote_open", function()
        if ispanel(RoleVote.vgui) then
            RoleVote.vgui:SetVisible(true)
        end
    end, function() end, "Other Bindings", "RoleVote", 13)

    net.Start("RoleVote_client_ready")
    net.SendToServer()
end)