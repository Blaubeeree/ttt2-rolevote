--TODO: Bug Report Button
local frame = nil
local buttons = {}

net.Receive("RoleVote_open", function(len, ply)
    if ispanel(frame) then return end
    -- Frame
    frame = vgui.Create("DFrame")
    frame:SetDeleteOnClose(false)
    frame:SetSize(510, 300)
    frame:Center()
    frame:SetTitle("RoleVote [Beta]")
    frame:SetVisible(true)
    frame:MakePopup()
    -- Label
    local label = vgui.Create("DLabel", frame)
    label:Dock(TOP)
    label:SetFont("DermaDefaultBold")
    label:SetText("Vote for a role that will be deactivated till the next map change:")
    -- Grid
    local grid = vgui.Create("DGrid", frame)
    grid:Dock(TOP)
    grid:SetColWide(100)
    grid:SetCols((frame:GetWide() - 10) / grid:GetColWide())
    -- Bugreport Button
    local rBut = vgui.Create("DButton", frame)
    rBut:SetText("Report Bug")
    rBut:SetSize(60, 17)
    rBut:SetPos(352, 4)

    rBut.DoClick = function()
        gui.OpenURL("https://github.com/Blaubeeree/ttt2-rolevote/issues/new")
    end

    -- Buttons
    for _, role in pairs(net.ReadTable()) do
        local but = vgui.Create("DButton")
        but:SetName(role.name)
        but:SetText("0 " .. role.name)
        but:SetSize(grid:GetColWide() - 5, 30)

        -- sets textcolor to black if backgroundcolor is bright
        if (0.2126 * role.color.r + 0.7152 * role.color.g + 0.0722 * role.color.b) < 190 then
            but:SetTextColor(Color(255, 255, 255))
        else
            but:SetTextColor(Color(0, 0, 0))
        end

        function but:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(82, 82, 82))
            draw.RoundedBox(4, 1, 1, w - 2, h - 2, role.color)
        end

        function but:DoClick()
            -- reset fonts
            for _, b in pairs(buttons) do
                b:SetFont("DermaDefault")
            end

            -- set pressed button font
            self:SetFont("DermaDefaultBold")
            -- tell server the new vote
            net.Start("RoleVote_vote")
            net.WriteString(self:GetName())
            net.SendToServer()
        end

        grid:AddItem(but)
        buttons[but:GetName()] = but
    end
end)

net.Receive("RoleVote_refresh_buttons", function()
    local votes = net.ReadTable()

    for role, plys in pairs(votes) do
        if ispanel(buttons[role]) then
            buttons[role]:SetText(#plys .. " " .. buttons[role]:GetName())
        end
    end
end)

net.Receive("RoleVote_msg", function()
    MsgC(unpack(net.ReadTable()))
end)

hook.Add("InitPostEntity", "RoleVote_InitPostEntity", function()
    if not TTT2 then return end
    AddTTT2AddonDev("76561198329270449")

    bind.Register("RoleVote_open", function()
        if ispanel(frame) then
            frame:SetVisible(true)
        end
    end, function() end, "Other Bindings", "RoleVote", 13)

    net.Start("RoleVote_client_ready")
    net.SendToServer()
end)

hook.Add("TTTBeginRound", "RoleVote_TTTBeginRound", function()
    if ispanel(frame) then
        frame:SetVisible(false)
        frame:Remove()
        frame = nil
    end
end)