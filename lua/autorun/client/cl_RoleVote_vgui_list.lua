local PANEL = {}
PANEL.buttons = {}
local title = "RoleVote"

surface.CreateFont("TTTRoleVote", {
	font = "DermaDefault",
	size = 16,
	weight = 1000,
})

surface.CreateFont("TTTRoleVoteLarge", {
	font = "DermaDefault",
	size = 18,
	weight = 1000,
})

function PANEL:Init()
	local scale = appearance.GetGlobalScale()
	local width = scale * 600
	local height = scale * 700
	self.button_height = scale * 60
	self.font = scale < 0.75 and "TTTRoleVote" or "TTTRoleVoteLarge"

	self:SetSize(width, height)
	self:Center()
	self:SetTitle(title)
	self:SetDeleteOnClose(false)

	if (RoleVote.end_time > CurTime()) then
		function self:Think()
			local time = math.Round(RoleVote.end_time - CurTime())
			self:SetTitle(title .. ": " .. time .. " seconds left")
		end
	end

	local infoLabel = vgui.Create("DLabelTTT2", self)

	if RoleVote.voteban then
		infoLabel:SetText(
			"Vote for a role that will be deactivated until the next vote:"
		)
	else
		infoLabel:SetText(
			"Vote for a role that will be activated until the next vote:"
		)
	end

	infoLabel:SetFont(self.font)
	infoLabel:DockMargin(0, 0, 0, 5)
	infoLabel:Dock(TOP)

	local scroll = vgui.Create("DScrollPanelTTT2", self)
	scroll:Dock(FILL)

	local buttonContainer = vgui.Create("DListLayout", scroll)
	buttonContainer:Dock(FILL)

	self:AddButton(
		buttonContainer,
		"none",
		Color(0, 0, 0),
		"vgui/ttt/dynamic/roles/icon_disabled"
	)

	for _, roleData in ipairs(RoleVote.voteable) do
		roleData = GetRoleByIndex(roleData)
		self:AddButton(
			buttonContainer,
			roleData.name,
			roleData.color,
			roleData.icon
		)
	end

	self:MakePopup()
	self:SetKeyboardInputEnabled(false)
end

function PANEL:AddButton(container, name, color, iconPath)
	local button = vgui.Create("DPanelTTT2", container)
	button:SetName(name)
	button:SetPaintBackgroundEnabled(true)
	button:SetHeight(self.button_height)
	button:DockMargin(0, 10, 5, 0)

	function button:OnMouseReleased(keyCode)
		if keyCode == MOUSE_LEFT then
			net.Start("RoleVote_vote")
			net.WriteString(self:GetName())
			net.SendToServer()
		end
	end

	local icon = vgui.Create("DRoleImage", button)
	icon:SetSize(self.button_height, self.button_height)
	icon:SetImage("vgui/ttt/dynamic/icon_base")
	icon:SetImage2("vgui/ttt/dynamic/icon_base_base")
	icon:SetImageOverlay("vgui/ttt/dynamic/icon_base_base_overlay")
	icon:SetImageColor(color)
	icon:SetRoleIconImage(iconPath)
	icon:Dock(LEFT)

	local votes = vgui.Create("DPanelTTT2", button)
	votes:Dock(RIGHT)

	function votes:OnMouseReleased(keyCode)
		self:GetParent():OnMouseReleased(keyCode)
	end

	function votes:SetNumber(num)
		self.counter:SetText(num)
	end

	local votesCounter = vgui.Create("DLabelTTT2", votes)
	votesCounter:SetText(0)
	votesCounter:SetFont(self.font)
	votesCounter:SizeToContents()
	votesCounter:Dock(LEFT)
	votes.counter = votesCounter

	local votesText = vgui.Create("DLabelTTT2", votes)
	votesText:SetText(" Votes")
	votesText:SetFont(self.font)
	votesText:SizeToContents()
	votesText:DockMargin(0, 0, 10, 0)
	votesText:Dock(FILL)

	button.votes = votes

	local label = vgui.Create("DLabelTTT2", button)
	label:SetText(LANG.TryTranslation(name))
	label:SetFont(self.font)
	label:SizeToContents()
	label:DockMargin(10, 0, 10, 0)
	label:Dock(FILL)

	container:Add(button)
	self.buttons[name] = button
end

function PANEL:UpdateVotes(votes)
	for roleName, players in pairs(votes) do
		local button = self.buttons[roleName]
		button.votes:SetNumber(#players)

		if table.IsEmpty(players) then
			button.votes:SetTooltipPanelOverride(nil)
		else
			local plyNames = {}
			for _, ply in pairs(players) do
				ply = player.GetBySteamID64(ply)
				table.insert(plyNames, ply:GetName())
			end

			button.votes:SetTooltip(table.concat(plyNames, ", "))
		end

		if table.HasValue(players, LocalPlayer():SteamID64()) then
			button:SetBGColor(Color(52, 114, 52))
		else
			button:SetBGColor(null)
		end
	end
end

derma.DefineControl("RoleVote_vgui_list", "", PANEL, "DFrameTTT2")