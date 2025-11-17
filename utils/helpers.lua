return {
  -- 指定json读取数据返回，默认是userdata，可以指定全局的json数据传入json解析
  ---@param jsonType number
  load_json = function(file_name, jsonType)
    if not file_name then
      return nil
    end
    local json_file = io.open(file_name, 'r')
    local json_data = json_file and json_file:read("*all")
    json_file:close()

    -- aseprite返回的是userdata数据。
    if jsonType == 1 and jsons ~= nil then
      return jsons.decode(json_data)
    end
    local status, result = pcall(json.decode, json_data)
    return (status and result) or nil
  end,

  ---保存json数据到指定的文件中
  ---@param dir string json文件地址
  ---@param jsondata string json字符串
  ---@param mode string 读取模式
  ---@return boolean
  save_json = function(dir, jsondata, mode)
    if not mode then mode = "w" end
    local json_file = io.open(dir, mode)
    if not json_file then
      error("Err read file.")
      return false
    end
    local json_res = json_file:write(jsondata)
    if not json_res then
      error("Data writing err.")
      json_file:close()
      return false
    end
    json_file:close()
    return true
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
