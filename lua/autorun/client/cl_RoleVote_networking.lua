local oldGuiCvar =
	CreateClientConVar("ttt_rolevote_old_gui", "0", true, false, "Enable the old GUI", 0, 1)

net.Receive("RoleVote_open", function()
	if ispanel(RoleVote.vgui) then return end
	RoleVote.voteban = net.ReadBool()
	RoleVote.voteable = net.ReadTable()
	RoleVote.end_time = net.ReadInt(32) + CurTime()

	if oldGuiCvar:GetBool() then
		RoleVote.vgui = vgui.Create("RoleVote_vgui_grid")
	else
		RoleVote.vgui = vgui.Create("RoleVote_vgui_list")
	end
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

	bind.Register(
		"RoleVote_open",
		function()
			if ispanel(RoleVote.vgui) then
				RoleVote.vgui:SetVisible(true)
			end
		end,
		function() end,
		"Other Bindings",
		"RoleVote",
		13
	)

	net.Start("RoleVote_client_ready")
	net.SendToServer()
end)