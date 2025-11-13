-- MIT License

-- Copyright (c) 2024 Balamod

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

Balamod_I18n = I18n.new()
Balamod_I18n:init("scripts.Balamod.locale")

function loadFile(data, ...)
    local path = Global_Config.SYS_EXTENSIONS_DIR("Balamod", ...)
    return loadfile(path)(data)
end

function init(plugin)
    if (plugin.preferences == nil) then
        plugin.preferences = {};
    end

    local debug = false;

    local data = {
        prefs = plugin.preferences,

        json = dofile(Global_Config.SYS_EXTENSIONS_DIR("Balamod", "src", "json.lua")),
        logger = {
            Log = function(msg) if (debug == true) then print("LOG: " .. msg) end end,
            Error = function(msg) if (debug == true) then print("ERROR: " .. msg) end end,
            LineBreak = function()
                if (debug == true) then
                    print(
                        "--------------------------------------------------------------------------------------")
                end
            end,
        },
        utils = dofile(Global_Config.SYS_EXTENSIONS_DIR("Balamod", "src", "helpers.lua"))
    };


    plugin:newMenuGroup {
        id = "balamod-list",
        title = Balamod_I18n:get("plugin_group_title"),
        group = "layer_merge",
    }
    local function AddCommand(id, title, group, file, loc)
        plugin:newCommand {
            id = id,
            title = title,
            group = group,
            onclick = function()
                loadfile(Global_Config.SYS_EXTENSIONS_DIR("Balamod", loc, file))(data)
            end
        }
    end

    AddCommand("Balamod_Extension_Templates", Balamod_I18n:get("plugin_name1"), "balamod-list", "TemplateWindow.lua",
        "Dialogs");
    AddCommand("Balamod_Extension_Tools_Blindify", Balamod_I18n:get("plugin_name2"), "balamod-list", "Blindify.lua",
        "src")
    AddCommand("Balamod_Extension_Tools_Scaler", Balamod_I18n:get("plugin_name3"), "balamod-list", "1Xto2X.lua", "src")
end

function exit(plugin)

end
