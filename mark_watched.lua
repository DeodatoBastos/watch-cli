local last_path = nil
local max_percent = 0
local threshold = 95

mp.observe_property("path", "string", function(name, value)
    if value then last_path = value end
end)

mp.observe_property("percent-pos", "number", function(name, value)
    if value and value > max_percent then max_percent = value end
end)

mp.register_event("end-file", function(e)
    if e.reason == "eof" or max_percent >= threshold then
        if last_path then
            local f = io.open(os.getenv("HOME") .. "/.config/watch-cli/watched.txt", "a")
            if f then
                f:write(last_path .. "\n")
                f:close()
            end
        end
    end
end)
