-- require 'scripts.Frame-Record.src.FocusManager'
-- 初始化
local JSON_DIR = app.fs.joinPath(
  app.fs.userConfigPath, "extensions", Global_Config.EXTENSIONS_NAME, "package.json")
local exclude_plugin = { main = 1, ["Extensions-Manager"] = 1 }

local dlg = Dialog({
  title = Extensions_Manager_I18n:get("plugin_title"),
  onclose = function()

  end
})

local datas = nil
---扩插件称配置，如json中存在指定多语言key值，则返回存在的翻译数据，否则返回插件id
---@param id string
---@param key_name string|nil
---@return string
local function plugin_keys_vilad(id, key_name)
  local KEY_NAME = string.gsub(id, "-", "_") .. "_I18n"
  local i18n_obj = _G[KEY_NAME]
  local is_vaild_i18n = i18n_obj and type(i18n_obj.get) == "function"
  if not is_vaild_i18n then key_name = nil end
  return key_name and i18n_obj:get(key_name) or id
end
-- 插件数据初始化
local function pluginCreate()
  plugins_list = datas.contributes.scripts

  for _, value in ipairs(datas.contributes.scripts) do
    if not exclude_plugin[value.id] then
      if value.status == nil then
        value.status = true -- 默认为启用状态
      end
      -- 扩展状态名称
      local status_name = value.status and Extensions_Manager_I18n:get("plugin_enableds") or
          Extensions_Manager_I18n:get("plugin_disableds")
      -- 扩展名称/内容
      Utils.labelCreate(dlg, value.id, "",
        plugin_keys_vilad(value.id, value.key_name) ..
        "(" .. Extensions_Manager_I18n:get("current_status_text") .. "" .. status_name .. ")"
      )

      dlg:combobox {
        id = value.id,
        label = "",
        option = value.status and Extensions_Manager_I18n:get("plugin_enabled") or Extensions_Manager_I18n:get("plugin_disabled"),
        options = {
          Extensions_Manager_I18n:get("plugin_enabled"),
          Extensions_Manager_I18n:get("plugin_disabled")
        },
        onchange = function()
          value.status = not value.status
          -- plugins_status[value.id] = not plugins_status[value.id]
        end
      }
      -- aseprite官方没有提供radio的分组限制，所以无法使用radio，这边使用了combobox来处理，后续如官方更新了该组件，则可以进一步调整下。
      -- dlg:radio {
      --   id = value.id .. "_disabled",
      --   text = "禁用",
      --   selected = value.status == false,
      --   onclick = function()
      --     plugins_status[value.id] = false
      --   end
      -- }:radio {
      --   id = value.id .. "_disabled",
      --   text = "启用",
      --   selected = value.status,
      --   onclick = function(e)
      --     plugins_status[value.id] = true
      --   end
      -- }
    end
  end
end

local function panelDataInit()
  -- 查看当前配置json数据
  datas = Utils.load_json(JSON_DIR)
  if datas ~= nil then
    if datas.contributes and datas.contributes.scripts then
      pluginCreate()
    end
  end
end
-- 面板数据初始化
panelDataInit()

dlg:button {
  id = "about us",
  text = Extensions_Manager_I18n:get("dlg_btn_text1"),
  onclick = function()
    if not datas then return end
    local names = {}
    if datas.contributors then
      for _, value in ipairs(datas.contributors) do
        table.insert(names, value.name)
      end
    end
    app.alert({
      title = Extensions_Manager_I18n:get("dlg_btn_text1"),
      text = {
        Extensions_Manager_I18n:get("about_text1") .. datas.name,
        Extensions_Manager_I18n:get("about_text2") .. datas.displayName,
        Extensions_Manager_I18n:get("about_text3") .. datas.version,
        Extensions_Manager_I18n:get("about_text4") .. datas.author.name .. " " .. datas.author.url,
        Extensions_Manager_I18n:get("about_text5") .. table.concat(names, " "),
        Extensions_Manager_I18n:get("about_text6") .. datas.license,
        Extensions_Manager_I18n:get("about_text7") .. datas.copyright,
      },
      buttons = {
        Extensions_Manager_I18n:get("confirm_button_text"),
      }
    })
  end
}:button {
  id = "dlg-close-button",
  text = Extensions_Manager_I18n:get("confirm_close"),
  onclick = function()
    dlg:close()
  end
}:button {
  id = "dlg-exit-button",
  text = Extensions_Manager_I18n:get("confirm_apply"),
  onclick = function()
    for index, value in ipairs(datas.contributes.scripts) do
      if not exclude_plugin[value.id] then
        local item = {
          id = value.id,
          status = value.status,
          [value.status and "path" or "_path"] = value.status
              and (value._path or value.path)
              or value.path
        }
        if value.key_name then item.key_name = value.key_name end
        datas.contributes.scripts[index] = item
      end
    end
    local result = Utils.save_json(JSON_DIR, json.encode(datas), 'w')
    if result == false then
      return error(Extensions_Manager_I18n:get("err_text"))
    end
    local res = app.alert({
      title = Extensions_Manager_I18n:get("tip_title"),
      text = {
        Extensions_Manager_I18n:get("data_alert1"),
        Extensions_Manager_I18n:get("data_alert2")
      },
      buttons = {
        Extensions_Manager_I18n:get("confirm_button_text"),
      }
    })
    if res == 1 then app.exit() end
  end
}:show { wait = false, autoscrollbars = true }
