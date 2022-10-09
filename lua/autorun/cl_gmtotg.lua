if not CLIENT then return end

net.Receive("TGtoGMColoredMsg", function ()
    local colors = {}
    local strings = {}
    colors[1] = net.ReadTable()
    strings[1] = net.ReadString()
    colors[2] = net.ReadTable()
    strings[2] = net.ReadString()
    colors[3] = net.ReadTable()
    strings[3] = net.ReadString()
    chat.AddText(colors[1], strings[1], colors[2], strings[2], colors[3], strings[3])
end)

hook.Add("ECShouldSendMessage", "GMtoTGEasyChatMessage", function (msg)
    if string.sub(msg, 1, 1) ~= "!" then
        net.Start("TGtoGMEasyChatTrigger")
        net.WriteString(msg)
        net.SendToServer()
    end

    return true
end)
