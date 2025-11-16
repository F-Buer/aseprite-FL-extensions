-- 初始化
local dlg = Dialog({
  title = Extension_Manager_I18n:get("plugin_title"),
  onclose = function()

  end
})

local datas = nil
local plugins_list = {}
local plugins_status = {} -- 扩展要调整的状态
-- 插件数据初始化
local function pluginCreate()
  plugins_list = datas.contributes.scripts
  local exclude_plugin = { main = 1, ["Extensions-Manager"] = 1 }
  for _, value in ipairs(plugins_list) do
    if not exclude_plugin[value.id] then
      if value.status == nil then
        value.status = true -- 默认为启用状态
      end
      local pname = value.key_name and Extension_Manager_I18n:get("key_name") or value.id
      local status_name = value.status and "已启用" or "已禁用"
      Utils.labelCreate(dlg, value.id, "", pname .. "(当前状态：" .. status_name .. ")")

      dlg:combobox {
        id = value.id,
        label = "",
        option = value.status and Extension_Manager_I18n:get("plugin_enabled") or Extension_Manager_I18n:get("plugin_disabled"),
        options = {
          Extension_Manager_I18n:get("plugin_enabled"),
          Extension_Manager_I18n:get("plugin_disabled")
        },
        onchange = function()
          if value.status then
            value.status = false
            plugins_status[value.id] = false
          else
            value.status = true
            plugins_status[value.id] = true
          end
        end
      }
      -- aseprite官方没有提供radio的分组限制，所以无法使用radio，这边使用了combobox来处理
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
  datas = Utils.load_json(app.fs.joinPath(
    app.fs.userConfigPath, "extensions", Global_Config.EXTENSIONS_NAME, "package.json"))
  -- 扩展种类操作函数

  if datas ~= nil then
    if datas.contributes and datas.contributes.scripts then
      pluginCreate()
    end
  end
end


panelDataInit()

dlg:button {
  id = "about us",
  text = "关于",
  onclick = function()
    if not datas then return end
    local names = {}
    if datas.contributors then
      for _, value in ipairs(datas.contributors) do
        table.insert(names, value.name)
      end
    end
    app.alert({
      title = Extension_Manager_I18n:get("plugin_about_title"),
      text = {
        "插件安装名称：" .. datas.name,
        "插件名称：" .. datas.displayName,
        "当前版本：" .. datas.version,
        "作者：" .. datas.author.name,
        "贡献者：" .. table.concat(names, " "),
        "授权许可：" .. datas.license,
        "版权所有：" .. datas.copyright,
      },
      buttons = {
        Frame_Record_I18n:get("confirm_button_text"),
      }
    })
  end
}:button {
  id = "dlg-close-button",
  text = "关闭对话框",
  onclick = function()
    dlg:close()
  end
}:button {
  id = "dlg-exit-button",
  text = "应用",
  onclick = function()
    print(plugins_status)
    for key, value in pairs(plugins_status) do
      print("key:", key)
      print("value", value)
    end
    print("last")
    -- local res = app.alert({
    --   title = Extension_Manager_I18n:get("plugin_about_title"),
    --   text = {
    --     "扩展程序状态已调整，需重启以应用，请点击重启"
    --   },
    --   buttons = {
    --     Frame_Record_I18n:get("confirm_button_text"),
    --   }
    -- })
    -- if res == 1 then app.exit() end
  end
}:show { wait = false, autoscrollbars = true }
