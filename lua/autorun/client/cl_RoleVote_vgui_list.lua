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

local function bgColorAnimationThink(anim, panel, fraction)
	if not anim.StartColor then
		anim.StartColor = panel:GetBGColor()
	end

	panel:SetBGColor(
		Color(
			Lerp(fraction, anim.StartColor.r, anim.Color.r),
			Lerp(fraction, anim.StartColor.g, anim.Color.g),
			Lerp(fraction, anim.StartColor.b, anim.Color.b),
			Lerp(fraction, anim.StartColor.a, anim.Color.a)
		)
	)
end

local function flashButton(button, duration, flashColor)
	duration = duration / 2 -- half duration because flash consists of two animations
	local startColor = button:GetBGColor()

	local anim = button:NewAnimation(duration, 0)
	anim.Color = flashColor
	anim.Think = bgColorAnimationThink

	local anim2 = button:NewAnimation(duration, duration)
	anim2.Color = startColor
	anim2.Think = bgColorAnimationThink
end

function PANEL:Init()
	local root = self
	-- calc a few sizes
	local scale = appearance.GetGlobalScale()
	local width = scale * 600
	local height = scale * 700
	self.button_height = scale * 60
	self.font = scale < 0.75 and "TTTRoleVote" or "TTTRoleVoteLarge"

	-- set some values
	self:SetSize(width, height)
	self:Center()
	self:SetTitle(title)
	self:SetDeleteOnClose(false)

	-- add a timer
	if (RoleVote.end_time > CurTime()) then
		function self:Think()
			local time = math.Round(RoleVote.end_time - CurTime())
			self:SetTitle(title .. ": " .. time .. " seconds left")
		end
	end

	-- add a nice little text
	local infoLabel = vgui.Create("DLabelTTT2", self)

	if RoleVote.voteban then
		infoLabel:SetText("Vote for a role that will be deactivated until the next vote:")
	else
		infoLabel:SetText("Vote for a role that will be activated until the next vote:")
	end

	infoLabel:SetFont(self.font)
	infoLabel:DockMargin(0, 0, 0, 5)
	infoLabel:Dock(TOP)

	-- add a search bar
	local searchBar = vgui.Create("DSearchBarTTT2", self)
	searchBar:SetFont(self.font)
	searchBar:SetPlaceholderText("Search for a role...")
	searchBar:SetCurrentPlaceholderText("Search for a role...")
	searchBar:Dock(TOP)
	searchBar:SetHeight(40)
	searchBar:DockMargin(0, 0, 0, 10)

	function searchBar:OnGetFocus()
		root:SetKeyboardInputEnabled(true)
	end

	function searchBar:OnLoseFocus()
		root:SetKeyboardInputEnabled(false)
	end

	-- add a scroll panel
	local scroll = vgui.Create("DScrollPanelTTT2", self)
	scroll:Dock(FILL)

	-- create a container for the buttons
	local buttonContainer = vgui.Create("DListLayout", scroll)
	buttonContainer:Dock(FILL)

	-- searchbar value change listener
	function searchBar:OnValueChange(val)
		-- check if val is empty
		if val ~= "" then
			-- filter buttons for val match
			for _, child in ipairs(buttonContainer:GetChildren()) do
				-- set visible to val find in name
				child:SetVisible(string.find(child:GetName(), val))
			end
		else
			-- val is empty - show all buttons
			for _, child in ipairs(buttonContainer:GetChildren()) do
				child:SetVisible(true)
			end
		end
		-- relayout container
		buttonContainer:InvalidateLayout(true)
	end

	-- add a "No Role" button
	self:AddButton(
		buttonContainer,
		"none",
		nil,
		Color(0, 0, 0),
		"vgui/ttt/dynamic/roles/icon_disabled"
	)

	-- fetch roles and store as number based table
	local roles = {}
	for _, roleData in ipairs(RoleVote.voteable) do
		roleData = GetRoleByIndex(roleData)
		table.insert(roles, {name = roleData.name, conVarData = roleData.conVarData, color = roleData.color, icon = roleData.icon})
	end

	-- sort roles by name (A-Z)
	table.sort(roles, function(a,b) return a.name < b.name end)

	-- add a button for each role
	for _, item in pairs(roles) do
		self:AddButton(
			buttonContainer,
			item.name,
			item.conVarData,
			item.color,
			item.icon
		)
	end

	-- make panel visible
	self:MakePopup()
	-- enable player to move around
	self:SetKeyboardInputEnabled(false)
end

function PANEL:AddButton(container, name, convars, color, iconPath)
	-- create a button
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

	-- add a panel with a tooltip on the left side of the button
	local iconContainer = vgui.Create("DPanelTTT2", button)
	if convars ~= nil then
		local tooltip = vgui.Create("RichText")

		tooltip:AppendText("Percentage of players:\t" .. convars.pct * 100 .. "%\n")
		tooltip:AppendText("Maximal players:\t\t" .. convars.maximum .. "\n")
		tooltip:AppendText("Total players needed:\t" .. convars.minPlayers .. "\n")
		if convars.random then
			tooltip:AppendText("Probability:\t\t\t" .. convars.random .. "%\n")
		end
		tooltip:AppendText("\n")
		tooltip:AppendText(LANG.TryTranslation("ttt2_desc_" .. name))

		tooltip:SetVerticalScrollbarEnabled(false)
		tooltip:SetWide(self:GetWide())

		function tooltip:PerformLayout()
			tooltip:SetToFullHeight()
		end

		iconContainer:SetTooltipPanel(tooltip)
	end
	iconContainer:SetSize(self.button_height, self.button_height)
	iconContainer:Dock(LEFT)

	function iconContainer:OnMouseReleased(keyCode)
		self:GetParent():OnMouseReleased(keyCode)
	end

	-- put the role icon in the panel
	local icon = vgui.Create("DRoleImage", iconContainer)
	icon:SetSize(self.button_height, self.button_height)
	icon:SetImage("vgui/ttt/dynamic/icon_base")
	icon:SetImage2("vgui/ttt/dynamic/icon_base_base")
	icon:SetImageOverlay("vgui/ttt/dynamic/icon_base_base_overlay")
	icon:SetImageColor(color)
	icon:SetRoleIconImage(iconPath)

	-- add a vote counter on the right side of the button
	local votes = vgui.Create("DPanelTTT2", button)
	votes:Dock(RIGHT)

	function votes:OnMouseReleased(keyCode)
		self:GetParent():OnMouseReleased(keyCode)
	end

	function votes:GetNumber()
		return tonumber(self.counter:GetText())
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

	-- add a label with the role name in the middle of the button
	local label = vgui.Create("DLabelTTT2", button)
	label:SetText(LANG.TryTranslation(name))
	label:SetFont(self.font)
	label:SizeToContents()
	label:DockMargin(10, 0, 10, 0)
	label:Dock(FILL)

	-- add button to the container
	container:Add(button)
	self.buttons[name] = button
end

function PANEL:UpdateVotes(votes)
	for roleName, players in pairs(votes) do
		local button = self.buttons[roleName]

		-- set tooltip
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

		-- set background color
		if table.HasValue(players, LocalPlayer():SteamID64()) then
			button:SetBGColor(Color(52, 114, 52))
		else
			button:SetBGColor(null)
		end

		-- flash button if a vote was added
		if #players > button.votes:GetNumber() then
			flashButton(button, 0.5, Color(30, 144, 255))
		end

		-- set number fo votes
		button.votes:SetNumber(#players)
	end
end

derma.DefineControl("RoleVote_vgui_list", "", PANEL, "DFrameTTT2")