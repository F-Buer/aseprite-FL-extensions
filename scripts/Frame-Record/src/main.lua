-- debug操作 start
local F_debug = require 'utils.debug'
F_debug = init_debug()
-- debug:setMode("all")
-- debug:setEnabled(true) -- 需要调试时或需要日志打印以及提示时请手动启用
-- debug:setLogDir(app.fs.normalizePath(
--   "G:\\hurricane\\design\\pixel_art\\Aseprite-extensions\\FL-Extensions\\scripts\\Frame-Record\\logs")) -- 调试时请直接填绝对路径，
-- debug操作 end

-- 初始化多语言配置
Frame_Record_I18n = I18n.new()
Frame_Record_I18n:init("scripts.Frame-Record.locale")

-- 版本检测
if app.apiVersion < 25 then
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
  return
end

require 'scripts.Frame-Record.src.FocusManager'
require 'scripts.Frame-Record.src.SpriteLapse'

local sitechange_key = nil
local focus_manager = nil

-- 注册菜单栏
local function initMenu(plugin)
  plugin:newMenuGroup {
    id = "frame-record",
    title = Frame_Record_I18n:get("menu_title"),
    group = "edit_undo",
  }
  -- 配置子菜单
  plugin:newCommand {
    id = "frame-record-listener",
    title = Frame_Record_I18n:get("menu_child_record"),
    group = "frame-record",
    onclick = function()
      if not app.fs.isFile(app.sprite.filename) then
        app.alert(Frame_Record_I18n:get("start_tip"))
        return
      end
      if not focus_manager:contains(app.sprite) then
        focus_manager:add(function() return SpriteLapse(app.sprite) end, app.sprite)
      end

      focus_manager:get(app.sprite):openDialog()
    end,
    onenabled = function() -- 控制插件是否不可选，默认返回true即可
      --[[
        TODO：判断当前语言环境是否存在改变，由于暂未找到合适的api删除旧菜单，该功能暂时搁置
      ]]
      -- if Frame_Record_I18n.current_lang ~= app.preferences.general.language then
      --   initMenu(plugin)
      --   Frame_Record_I18n:init()
      -- end
      -- 对精灵图窗口以外的操作禁用操作
      if app.sprite == nil then
        return false
      end
      return not SpriteJson.getProperty(app.sprite, 'has_dialog')
    end,
  }
end

-- 插件初始化
function init(plugin)
  -- 启用精灵图操作监听
  focus_manager = FocusManager()

  focus_manager:init()
  -- 设置插件菜单栏分割线
  plugin:newMenuSeparator {
    group = "edit_undo"
  }
  -- 配置顶级菜单组
  initMenu(plugin)


  sitechange_key = app.events:on('sitechange', function()
    if app.sprite and not focus_manager:contains(app.sprite) and SpriteJson.getProperty(app.sprite, 'has_lapse') then
      focus_manager:add(function() return SpriteLapse(app.sprite) end, app.sprite, true)
    end
  end)

  for _, sprite in ipairs(app.sprites) do
    if not focus_manager:contains(sprite) and SpriteJson.getProperty(sprite, 'has_lapse') then
      focus_manager:add(function() return SpriteLapse(sprite) end, sprite)
    end
  end
end

-- 插件退出
function exit()
  focus_manager:cleanup()
  focus_manager = nil

  app.events:off(sitechange_key)
end
