--[[
  用于插件开发debug调试
  debug内部函数调用均会查询插件中config配置目录，如果config中开启了debug = true，则启用功能。
  debug打印分两种方式，一种是直接aseprite软件中弹出，另一种则是存入扩展开发中log目录中。
]]
local F_debug = {}

-- 文件目录相关函数 start
-- 确保日志目录存在（不存在则创建）
local function ensureLogDir(log_dir)
  if not app.fs.isDirectory(log_dir) then
    app.fs.makeDirectory(log_dir) -- 创建目录（支持多级）
  end
end

-- 获取当日日志文件名（格式：年-月-日.log）
local function getTodayLogFileName(log_dir)
  local date_str = os.date("%Y-%m-%d") -- 按日期分文件
  return app.fs.joinPath(log_dir, string.format("%s.log", date_str))
end

-- 写入日志到文件（追加模式）
local function writeToFile(log_dir, formatted_msg)
  ensureLogDir(log_dir)
  local log_file = getTodayLogFileName(log_dir)
  -- 追加模式写入（"a"=追加，不存在则创建文件）
  local file = io.open(log_file, "a")
  if file then
    file:write(formatted_msg .. "\n\n") -- 由于lua无从顶部追加方法，这边懒得读取再写入再追加以实现最新日志数据再顶部的操作了，有需求的可以自己改下。
    file:close()
  else
    -- 文件写入失败时，降级到打印模式提示
    print(string.format("[调试工具] 无法写入日志文件：%s", log_file))
  end
end
-- 文件目录相关函数 end

function F_debug.new(...)
  local self = setmetatable({}, { __index = F_debug })
  local _, enabled, mode, log_dir, enable_file_log, is_global_lock = ...
  -- 核心配置
  self.enabled = enabled or false                         -- 全局调试开关：true=开启，false=关闭所有功能
  self.mode = mode or "print"                             -- 输出模式："alert"=弹窗，"print"=控制台，"file"=文件（仅日志），"all"=打印+文件
  self.log_dir = log_dir or app.fs.joinPath("./", "logs") -- 日志保存目录（默认：Aseprite配置目录下）
  self.enable_file_log = enable_file_log or true          -- 是否开启文件日志：true=生成日志文件，false=不生成
  self.is_global_lock = is_global_lock or false           -- 是否开启全局debug锁，当该项设置为true，则默认任何插件的debug开启事件都无法生效

  -- 初始化日志目录和状态
  ensureLogDir(self.log_dir)
  if self.enabled then
    self:log(
      string.format(
        "调试工具初始化完成！\n- 全局开关：%s\n- 输出模式：%s\n- 文件日志：%s\n- 日志目录：%s",
        tostring(self.enabled),
        self.mode,
        tostring(self.enable_file_log),
        self.log_dir)
    )
  end
  return self
end

local function formatMsg(msg)
  local time_str = os.date("%H:%M:%S")
  local prefix = string.format("[%s %s]", os.date("%Y-%m-%d"), time_str)

  if type(msg) == "table" then
    return string.format("%s 【元表】\n%s", prefix, json.encode(msg))
  elseif type(msg) == "nil" then
    return string.format("%s 【nil】", prefix)
  elseif type(msg) == "boolean" then
    return string.format("%s 【布尔值】%s", prefix, tostring(msg))
  elseif type(msg) == "string" then
    return string.format("%s 【文本】%s", prefix, msg)
  else
    return string.format("%s 【%s】%s", prefix, type(msg), tostring(msg))
  end
end
-- 调试输出（核心方法：按模式输出日志）
-- is_print all模式下强制不print
function F_debug:log(msg, is_print)
  if not self.enabled then return end
  local formatted_msg = formatMsg(msg)

  -- 按模式输出
  if self.mode == "alert" then
    -- 弹窗模式|后续有需求可以调入面板或对话框
    app.alert(formatted_msg)
  elseif self.mode == "print" then
    -- 控制台模式
    print(formatted_msg)
  elseif self.mode == "file" then
    -- 文件模式
    writeToFile(self.log_dir, formatted_msg)
  elseif self.mode == "all" then
    -- 全量模式（控制台+文件）
    if is_print ~= false then
      print(formatted_msg)
    end
    writeToFile(self.log_dir, formatted_msg)
  else
    -- 无效模式：默认降级到控制台
    print(string.format("[调试工具] 无效输出模式：%s，已降级到控制台", self.mode))
    print(formatted_msg)
  end
end

-- 数据处理相关函数 end


-- 配置动态调整相关函数 start
-- 配置日志目录（可选：自定义日志保存路径）
-- 注意：目录地址可以为绝对路径或相对路径（aseprite中会直接存放在安装目录）
function F_debug:setLogDir(dir_path, is_print)
  if not is_print then is_print = false end
  if type(dir_path) == "string" then
    self.log_dir = dir_path
    self:log(string.format("日志目录已设置为：%s", dir_path), is_print)
    ensureLogDir(self.log_dir) -- 确保目录存在
  else
    self:log("设置日志目录失败：路径必须是字符串")
  end
end

-- 切换输出模式
-- @param new_mode: 支持 "alert"、"print"、"file"、"all"
function F_debug:setMode(new_mode, is_print)
  if not is_print then is_print = false end
  local valid_modes = { "alert", "print", "file", "all" }
  for _, mode in ipairs(valid_modes) do
    if new_mode == mode then
      self.mode = new_mode
      self:log(string.format("输出模式已切换为：%s", new_mode), is_print)
      return
    end
  end
  self:log(string.format("切换模式失败：无效模式「%s」，仅支持 %s", new_mode, table.concat(valid_modes, "/")))
end

-- 开启/关闭文件日志
function F_debug:setFileLogEnabled(is_enable, is_print)
  if not is_print then is_print = false end
  self.enable_file_log = is_enabled
  self:log(string.format("文件日志已%s", is_enabled and "开启" or "关闭"), is_print)
  if is_enabled then
    ensureLogDir(self.log_dir) -- 开启时确保目录存在
  end
end

-- 全局开关（一键开启/关闭所有调试功能）
function F_debug:setEnabled(is_enabled, is_print)
  if is_enabled == true and self.is_global_lock == true then
    return
  end
  if not is_print then is_print = false end
  self.enabled = is_enabled
  self:log(string.format("调试工具已%s", is_enabled and "开启" or "关闭"), is_print)
end

function F_debug:getEnabled()
  return self.enabled
end

-- 配置动态调整相关函数 end
return F_debug
