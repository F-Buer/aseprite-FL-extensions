Extension_Manager_I18n = I18n.new()
Extension_Manager_I18n:init("scripts.Extensions-Manager.locale")

Extensions_Manager_Debug = Debug:new(true, "file",
  "G:\\hurricane\\design\\pixel_art\\Aseprite-extensions\\FL-Extensions\\scripts\\Extensions-Manager\\logs") -- 需要调试时或需要日志打印以及提示时请手动启用
function init(plugin)
  plugin:newMenuSeparator {
    group = "layer_merge"
  }
  plugin:newCommand {
    id = "extensions-manager",
    title = Extension_Manager_I18n:get("plugin_title"),
    group = "layer_merge",
    onclick = function()
      loadfile(Global_Config.SYS_EXTENSIONS_DIR("Extensions-Manager", "panel.lua"))()
    end,
    onenabled = function()
      -- return not not app.sprite
      return true
    end
  }
end

function exit()
end
