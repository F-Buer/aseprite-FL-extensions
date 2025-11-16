return {
  load_json = function(file_name)
    if not file_name then
      return nil
    end
    local json_file = io.open(file_name, 'r')
    local json_data = json_file and json_file:read("*all")
    _ = json_file and json_file:close()
    local status, result = pcall(json.decode, json_data)
    return (status and result) or nil
  end,

  -- 插件的版本检测
  ---@param v [string|number] 需要指定的版本号
  ---@param ... string 提示的自定义内容，可提供多项
  ---@returns boolean
  version_check = function(v, ...)
    if app.apiVersion < v then
      local app_version = tostring(app.version)                  -- aseprite当前版本，该插件要求至少不低于v1.3-rc3
      local title = Frame_Record_I18n:get("version_check_title") -- 获取弹窗使用内容
      local msg = Frame_Record_I18n:get("version_check_msg")
      app.alert({
        title = title,
        text = {
          string.format(msg, app_version),
          Frame_Record_I18n:get("version_check_tip")
        },
        buttons = { Frame_Record_I18n:get("confirm_button_text") }
      })
      return false
    else
      return true
    end
  end,

  -- label start
  labelCreate = function(dlg, ...)
    local id, label, text = ...
    dlg:label {
      id = id,
      label = label,
      text = text
    }
  end
  -- label end
}
