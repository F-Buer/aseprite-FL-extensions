local I18n = {
  common_translate = {} -- 初始化通用多语言信息
}
function I18n.new()
  local self = setmetatable({}, { __index = I18n })
  self.language_name = {
    en = ".en",
    ["zh-CN"] = ".zh",
    zh = ".zh",
    ["zh-TW"] = ".zh-TW",
    -- ru = ".ru",
    -- ko = ".ko",
    -- ja = ".ja",
    -- de = ".de",
    -- fr = ".fr",
    -- es = ".es"
  }
  self.translations = { -- 语言文件存放的位置
    -- en = {}
  }
  self.current_lang = "en"
  return self
end

function I18n:init(locale_path)
  if not locale_path then return end
  local user_language = app.preferences and app.preferences.general and app.preferences.general.language
  self.current_lang = user_language or "en"
  if not self.language_name[self.current_lang] then
    self.current_lang = "en"
  end

  -- 引入前校验文件
  local ok, _ = pcall(function()
    if not self.translations[self.current_lang] then                                                       -- 指定插件的翻译不存在时
      self.translations[self.current_lang] = require(locale_path .. self.language_name[self.current_lang]) -- 引入语言文件
    end
  end)
  if not ok then -- 语言文件置入错误，直接更替为英文
    self.translations[self.current_lang] = require(locale_path .. ".en")
  end
  -- 合并通用翻译
  if #self.common_translate <= 0 then
    self.common_translate = require("lang.locale" .. self.language_name[self.current_lang])
  end
  for key, value in pairs(self.common_translate) do
    if not self.translations[self.current_lang][key] then
      self.translations[self.current_lang][key] = value
    end
  end
end

function I18n:get(key, ...)
  -- 由于后续调整成插件默认只加载一份翻译文件，所以当当前语言中访问了不存在的key则直接提示
  local text = self.translations[self.current_lang][key]
  if not text then
    -- 这里随便调了个插件翻译实例中的翻译内容，lang_kv_missing合并自全局翻译
    error(Frame_Record_I18n:get("lang_kv_missing", key))
    return key
  end

  -- local text = self.translations[self.current_lang][key]
  --     or (not self.translations.en and self.translations.en[key])
  --     or key
  return select("#", ...) > 0 and string.format(text, ...) or text
end

return I18n
