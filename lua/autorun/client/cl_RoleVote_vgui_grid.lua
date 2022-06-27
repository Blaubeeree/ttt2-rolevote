local PANEL = {}
PANEL.buttons = {}
local avatar_size = 20
local button_size = 110

function PANEL:Paint(w, h)
	draw.RoundedBox(5, 0, 0, w, h, Color(35, 39, 42))
	draw.RoundedBox(5, 1, 1, w - 2, h - 2, Color(44, 47, 51))
	draw.RoundedBoxEx(5, 1, 1, w - 2, 23, Color(64, 67, 71), true, true)
end

function PANEL:Init()
	local width = ScrW() * 0.58
	local height = ScrH() * 0.6
	self:SetSize(width, height)
	self:Center()
	self:SetTitle("RoleVote")
	self:SetDeleteOnClose(false)

	if (RoleVote.end_time > CurTime()) then
		local timeLabel = vgui.Create("DLabel", self)
		timeLabel:SetFont("Trebuchet24")
		timeLabel:Dock(TOP)

		function timeLabel:Think()
			local time = math.Round(RoleVote.end_time - CurTime())
			self:SetText(time .. " seconds left")
		end
	end

	local infoLabel = vgui.Create("DLabel", self)

	if RoleVote.voteban then
		infoLabel:SetText(
			"Vote for a role that will be deactivated until the next vote:"
		)
	else
		infoLabel:SetText(
			"Vote for a role that will be activated until the next vote:"
		)
	end

	infoLabel:SetFont("Trebuchet24")
	infoLabel:DockMargin(0, 5, 0, 10)
	infoLabel:Dock(TOP)

	local scroll = vgui.Create("DScrollPanel", self)
	scroll:Dock(FILL)

	local container = vgui.Create("DGrid", scroll)
	container:Dock(FILL)
	container:SetColWide(button_size)
	container:SetRowHeight(button_size)
	container:SetCols(math.floor(width / button_size))

	self:InitButtons(container)
	self:MakePopup()
	self:SetKeyboardInputEnabled(false)
end

function PANEL:InitButtons(container)
	for _, roleData in ipairs(RoleVote.voteable) do
		roleData = GetRoleByIndex(roleData)
		local role_button = vgui.Create("SimpleRoleIcon", container)
		role_button:SetIcon("vgui/ttt/dynamic/icon_base")
		role_button:SetIconSize(button_size)
		role_button:SetIconColor(roleData.color)
		role_button.Icon:SetImage2("vgui/ttt/dynamic/icon_base_base")
		role_button.Icon:SetImageOverlay(
			"vgui/ttt/dynamic/icon_base_base_overlay"
		)
		role_button.roleData = roleData
		role_button.Icon:SetRoleIconImage(roleData.icon)
		role_button:SetTooltip(LANG.TryTranslation(roleData.name))
		role_button:SetName(roleData.name)

		function role_button:OnMousePressed(keyCode)
			if keyCode == MOUSE_LEFT then
				net.Start("RoleVote_vote")
				net.WriteString(self:GetName())
				net.SendToServer()
			end
		end

		role_button.grid = vgui.Create("DGrid", role_button)
		role_button.grid:SetPos(5, 5)
		role_button.grid:SetSize(button_size - 10, button_size - 10)
		role_button.grid:SetColWide(avatar_size)
		role_button.grid:SetRowHeight(avatar_size)
		role_button.grid:SetCols(math.floor(button_size / avatar_size))
		container:AddItem(role_button)
		self.buttons[roleData.name] = role_button
	end

	local none_button = vgui.Create("SimpleRoleIcon", container)
	none_button:SetIcon("vgui/ttt/dynamic/icon_base")
	none_button:SetIconSize(button_size)
	none_button:SetIconColor(Color(0, 0, 0))
	none_button.Icon:SetImage2("vgui/ttt/dynamic/icon_base_base")
	none_button.Icon:SetImageOverlay("vgui/ttt/dynamic/icon_base_base_overlay")
	none_button.Icon:SetRoleIconImage("vgui/ttt/dynamic/roles/icon_disabled")
	none_button:SetTooltip(LANG.TryTranslation("none"))
	none_button:SetName("none")

	function none_button:OnMousePressed(keyCode)
		if keyCode == MOUSE_LEFT then
			net.Start("RoleVote_vote")
			net.WriteString(self:GetName())
			net.SendToServer()
		end
	end

	none_button.grid = vgui.Create("DGrid", none_button)
	none_button.grid:SetPos(5, 5)
	none_button.grid:SetSize(button_size - 10, button_size - 10)
	none_button.grid:SetColWide(avatar_size)
	none_button.grid:SetRowHeight(avatar_size)
	none_button.grid:SetCols(math.floor(button_size / avatar_size))
	container:AddItem(none_button)
	self.buttons["none"] = none_button
end

function PANEL:UpdateVotes(votes)
	for roleName, players in pairs(votes) do
		local button = self.buttons[roleName]
		-- clear grid
		local items = button.grid:GetItems()

		for i = #items, 1, -1 do
			button.grid:RemoveItem(items[i])
		end

		-- add avatars to grid
		for i = 0, #players - 1 do
			local max = button.grid:GetCols() * 2 - 1

			if #button.grid:GetItems() >= max then
				local label = vgui.Create("DLabel")
				label:SetText("+" .. #players - i - 1)
				button.grid:AddItem(label)
				break
			end

			local ply = player.GetBySteamID64(players[i + 1])
			local avatar = vgui.Create("AvatarImage")
			avatar:SetSize(avatar_size - 2, avatar_size - 2)
			avatar:SetPlayer(ply)
			button.grid:AddItem(avatar)
		end
	end
end

derma.DefineControl("RoleVote_vgui_grid", "", PANEL, "DFrame")