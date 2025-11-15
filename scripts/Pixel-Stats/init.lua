Pixel_Stats_I18n = I18n.new()
Pixel_Stats_I18n:init("scripts.Pixel-Stats.locale")
function init(plugin)
  plugin:newCommand {
    id = "pixel-status",
    title = Pixel_Stats_I18n:get("msg_title"),
    group = "layer_merge",
    onclick = function()
      loadfile(Global_Config.SYS_EXTENSIONS_DIR("Pixel-Stats", "pixel_stats.lua"))()
    end,
    onenabled = function()
      return not not app.sprite
    end
  }
end

function exit(plugin)
end
