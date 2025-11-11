-- 初始化多语言配置
Layer_status_I18n = I18n.new()
Layer_status_I18n:init("scripts.Layer-Status.locale")

local status = {
  Layer_status_I18n:get("status_def"),
  Layer_status_I18n:get("status_cmp"),
  Layer_status_I18n:get("status_ips"),
  Layer_status_I18n:get("status_nst")
}
local colors = { Color {
  r = 0,
  g = 0,
  b = 0,
  a = 0
}, Color {
  r = 155,
  g = 200,
  b = 0,
  a = 155
}, Color {
  r = 10,
  g = 110,
  b = 225,
  a = 155
}, Color {
  r = 155,
  g = 0,
  b = 0,
  a = 155
} }

-- Index Of
function IndexOf(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

-- Change Layer Color Function
local function ChangeLayerColor(data)
  -- Check Active Layer
  if not app.activeLayer then
    app.alert(Layer_status_I18n:get("plugin_hint"))
    return
  end

  -- Get Index Of Status Selection
  status_index = IndexOf(status, data.dlg_status)

  -- Apply Color To Layer
  app.activeLayer.color = colors[status_index]
  return true
end

local function ShowDialogue()
  dlg = Dialog(Layer_status_I18n:get("plugin_name"))
  dlg:combobox {
    id = "dlg_status",
    label = Layer_status_I18n:get("plugin_label"),
    options = status
  }
      :newrow()
      :button {
        id = "dlg_ok",
        text = "&" .. Layer_status_I18n:get("confirm_apply"),
        onclick = function()
          if ChangeLayerColor(dlg.data) then
            dlg:close()
          end
        end
      }
      :button {
        text = "&" .. Layer_status_I18n:get("confirm_close")
      }:show {
    wait = false
  }
end

function init(plugin)
  plugin:newCommand {
    id = "excalith-layer-status",
    title = Layer_status_I18n:get("plugin_title"),
    group = "layer_merge",
    onclick = ShowDialogue
  }
end

function exit(plugin)
end
