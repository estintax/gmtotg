if not SERVER then return end
local config = {}
if not file.Exists("gmtotg_config.json", "DATA") then
    local f = file.Open("gmtotg_config.json", "w", "DATA")
    f:Write(util.TableToJSON({
        api_url = "https://api.telegram.org",
        bot_token = "none",
        chat_id = "0",
        msg_format = "<b>%s</b>: <i>%s</i>",
        polling = false,
    }, true))
    f:Close()
end
if file.Exists("gmtotg_config.json", "DATA") then
    local f = file.Open("gmtotg_config.json", "r", "DATA")
    local data = f:Read()
    f:Close()
    config = util.JSONToTable(data)
end

local is_ready = false
local update_id = 0

timer.Simple(0, function ()
    print("GMtoTG (C) 2022 SE Maksim Pinigin")
    if config.bot_token == "none" then
        print("GMtoTG: Please, specify your Telegram bot's token from @BotFather in gmtotg_config.json")
        return nil
    end
    if config.chat_id == "0" then
        print("GMtoTG: Please, specify your Telegram chat ID in gmtotg_config.json")
        return nil
    end

    is_ready = true
    if config.polling then
        util.AddNetworkString("TGtoGMColoredMsg")
        print("GMtoTG: Starting long polling")
        timer.Create("TGBotLongPolling", 2, 0, function ()
            http.Fetch(string.format("%s/bot%s/%s?offset=%d", config.api_url, config.bot_token, "getUpdates", update_id), function (body, size, headers, code)
                if code == 200 then
                    data = util.JSONToTable(body)
                    if data.ok == true and #data.result ~= 0 then
                        update_id = data.result[#data.result].update_id+1
                        for i,update in pairs(data.result) do
                            if update.message and update.message.text then
                                local username = update.message.from.first_name
                                if update.message.from.last_name then
                                    username = username .. " " .. update.message.from.last_name
                                end
                                print(string.format("[TG] %s: %s", username, update.message.text))
                                local players = player.GetAll()
                                for i,ply in pairs(players) do
                                    net.Start("TGtoGMColoredMsg")
                                    net.WriteTable(Color(42, 171, 238, 255))
                                    net.WriteString("[TG] ")
                                    net.WriteTable(Color(255, 255, 255, 255))
                                    net.WriteString(username .. ": ")
                                    net.WriteTable(Color(185, 185, 185, 255))
                                    net.WriteString(update.message.text)
                                    net.Send(ply)
                                end
                            end
                        end
                    end
                end
            end)
        end)
        print("GMtoTG: Working")
    end
end)

gameevent.Listen("player_say")
hook.Add("player_say", "GMtoTGChat", function (data)
    if not is_ready then return nil end
    if string.sub(data.text, 1, 1) == "!" then return nil end
    local p = Player(data.userid)
    local nickname = p:Nick()
    local msg = data.text
    msg = string.Replace(msg, "<", "&lt;")
    msg = string.Replace(msg, ">", "&gt;")
    msg = string.Replace(msg, "&", "&amp;")
    http.Post(string.format("%s/bot%s/%s", config.api_url, config.bot_token, "sendMessage"), {
        chat_id = config.chat_id,
        text = string.format(config.msg_format, nickname, msg),
        parse_mode = "HTML"
    }, function (body, size, headers, code)
    end, function (err)
        print("failed to send message to telegram: " .. err)
    end)
end)
