-- 加载全局文件
-- 加载语言文件
I18n = require 'utils.initLocale'
Main_I18n = I18n.new()
Main_I18n:init("./lang/locale")
-- 加载全局配置文件
Global_Config = require 'config.baseConfig'
-- 加载全局辅助函数
Utils = require 'utils.helpers'
-- 加载debug
Debug = require 'utils.debug'

function init()
  local dlg = Dialog({
    title = Main_I18n:get("statement")
  })

  -- 获取page.json中是否有无需通知弹窗
  local JSON_DIR = app.fs.joinPath(
    app.fs.userConfigPath, "extensions", Global_Config.EXTENSIONS_NAME, "package.json")
  local datas = Utils.load_json(JSON_DIR)


  local values = {
    [4] = datas.license,
    [9] = os.date("%Y-%m-%d %H:%M:%S"),
    [10] = datas.author.url
  }
  for i = 1, 10 do
    local val = values[i] and values[i] or ""
    local key_value = Main_I18n:get("statement_text" .. i, val)
    if key_value ~= "" then
      Utils.labelCreate(dlg, "st" .. i, "", key_value)
    end
  end

  if datas.no_notice == true then return end
  local is_confirm = false
  dlg:check {
    id = "notice",
    text = Main_I18n:get("notice_text"),
    selected = false,
    onclick = function()
      is_confirm = not is_confirm
    end
  }:button {
    id = "dlg-close-button",
    text = Main_I18n:get("confirm_close"),
    onclick = function()
      if is_confirm == true then
        datas.no_notice = true
      end
      local result = Utils.save_json(JSON_DIR, json.encode(datas), 'w')
      if result == false then
        return error(Main_I18n:get("err_text"))
      end
      dlg:close()
    end
  }
  dlg:show { wait = false, autoscrollbars = true }
end

function exit()
end
