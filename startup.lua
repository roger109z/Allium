-- Allium version
local allium_version = "0.9.0-pr1"

if not commands then -- Attempt to prevent user from running this on non-command comps
	printError("Allium must be run on a command computer")
	return
end

local default = {
    version = allium_version, -- Allium's version
    import_timeout = 5, -- The maximum amount of time it takes to wait for a plugin dependency to provide its module.
    label = "<&r&dAll&5&h[[Killroy wuz here.]]&i[[https://www.youtube.com/watch?v=XqZsoesa55w&t=15s]]i&r&dum&r> ", -- The label the loader uses
    updates = { -- Various auto-update configurations. Server operators may want to change this from the default
        deps = true, -- Automatically update dependencies
        allium = true -- Automatically update allium
    }
}

--load settings from file
local loadSettings = function(file, default)
    assert(type(file) == "string", "file must be a string")  
    if not fs.exists(file) then
        local setting = fs.open(file,"w")
        setting.write(textutils.serialise(default))
        setting.close()
        return default
    end
    local setting = fs.open(file, "r")
    local config = setting.readAll()
    setting.close()
    config = textutils.unserialise(config)
    if type(config) ~= "table" then
        return default
    end
    local checkForKeys
    checkForKeys = function(default, test)
        for key, value in pairs(default) do
            if type(test[key]) ~= type(value) then
                test[key] = value
            elseif type(test[key]) == "table" then
                checkForKeys(value, test[key])
            end
        end
    end
    checkForKeys(default, config)
    return config
end

config = loadSettings("cfg/allium.lson", default)

-- Checking Allium/Plugin updates
if config.updates.allium then
    if fs.exists("cfg/repolist.csh") then -- Checking for a repolist shell executable
        -- Update all plugins and programs on the repolist
        for line in io.lines("cfg/repolist.csh") do
            shell.run(line)
        end
    end
end

-- Filling Dependencies
if config.updates.dependencies then
    -- Allium DepMan Instance: https://pastebin.com/nRgBd3b6
    print("Checking for dependency updates...")
    local didrun = false
    parallel.waitForAll(function()
        didrun = shell.run("pastebin run nRgBd3b6 upgrade https://pastebin.com/raw/fisfxn76 /cfg/deps.lson /lib "..allium_version)
    end, 
    function()
        multishell.setTitle(multishell.getCurrent(), "depman")
    end)
    if not didrun then
        printError("Could not update dependencies")
        return
    end
end

-- Clearing the screen
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

-- Running Allium
multishell.setTitle(multishell.getCurrent(), "Allium")
os.run(_ENV, "allium.lua", config)

-- Removing all captures
for _, side in pairs(peripheral.getNames()) do -- Finding the chat module
	if peripheral.getMethods(side) then
		for _, method in pairs(peripheral.getMethods(side)) do
			if method == "uncapture" then
                peripheral.call(side, "uncapture")
				break
			end
		end
    end
end

-- Rebooting or exiting
print("Rebooting in 5 seconds")
print("Press any key to cancel")
parallel.waitForAny(function() repeat until os.pullEvent("char") end, function() sleep(5) os.reboot() end)