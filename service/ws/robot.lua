local skynet = require "skynet"
local json = require "cjson"
local ws_client = require "ws.client"

local player_t = ...
local player_t = require "player_t"

local NORET = "NORET"
local player
local ws

local CMD = {}
function CMD.start(url, acc)
    ws = ws_client:new()
    ws:connect(string.format(url))
    player = player_t.new(ws, acc)
    player:on_open()
    skynet.fork(function()
        while true do
            while ws do
                local ret = ws:recv_frame()
                if ret then
                    print("recv", ret)
                    player:on_message(ret)
                else
                    break
                end
            end
            if ws then
                player:ping()
            end
            skynet.sleep(100)
        end
    end)
end

function CMD.stop()
    ws:close()
end

skynet.start(function()		
    skynet.dispatch("lua", function(_, _, cmd1, cmd2, ...)
        local ret = NORET
        local f = CMD[cmd1]
        assert(f)
        ret = f(cmd2, ...)
        if ret ~= NORET then
            skynet.ret(skynet.pack(ret))
        end
    end)
end)

