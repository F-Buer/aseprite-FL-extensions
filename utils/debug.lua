--[[
  用于插件开发debug调试
  debug内部函数调用均会查询插件中config配置目录，如果config中开启了debug = true，则启用功能。
  debug打印分两种方式，一种是直接aseprite软件中弹出，另一种则是存入扩展开发中log目录中。
]]
function init_debug()
  local debug = {
    -- 核心配置
    enabled = false,                         -- 全局调试开关：true=开启，false=关闭所有功能
    mode = "print",                          -- 输出模式："alert"=弹窗，"print"=控制台，"file"=文件（仅日志），"all"=打印+文件
    log_dir = app.fs.joinPath("./", "logs"), -- 日志保存目录（默认：Aseprite配置目录下）
    enable_file_log = true,                  -- 是否开启文件日志：true=生成日志文件，false=不生成
    is_global_lock = false,                  -- 是否开启全局debug锁，当该项设置为true，则默认任何插件的debug开启事件都无法生效
  }

  -- 文件目录相关函数 start
  -- 确保日志目录存在（不存在则创建）
  local function ensureLogDir()
    if not debug.enable_file_log then return end
    if not app.fs.isDirectory(debug.log_dir) then
      app.fs.makeDirectory(debug.log_dir) -- 创建目录（支持多级）
    end
  end

  -- 获取当日日志文件名（格式：年-月-日.log）
  local function getTodayLogFileName()
    local date_str = os.date("%Y-%m-%d") -- 按日期分文件
    return app.fs.joinPath(debug.log_dir, string.format("%s.log", date_str))
  end

  -- 写入日志到文件（追加模式）
  local function writeToFile(formatted_msg)
    if not debug.enabled or not debug.enable_file_log then return end
    ensureLogDir() -- 确保目录存在

    local log_file = getTodayLogFileName()
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


  -- 数据处理相关函数 start
  -- 格式化日志消息（带时间戳、支持多类型数据）
  local function tableToString(tbl, indent)
    indent = indent or "  "
    local str = "{\n"
    local is_first = true

    for k, v in pairs(tbl) do
      if not is_first then
        str = str .. ",\n"
      end
      is_first = false

      -- 处理键名
      local key_str
      if type(k) == "string" and k:match("^[%a_][%a%d_]*$") then
        key_str = k -- 合法标识符，直接写键名
      else
        key_str = string.format("[%s]", type(k) == "string" and string.format("%q", k) or tostring(k))
      end

      -- 处理值
      local value_str
      if type(v) == "table" then
        value_str = tableToString(v, indent .. "  ") -- lua序列化需要单独的库，这里就不引入直接采用递归序列化子表格
      elseif type(v) == "string" then
        value_str = string.format("%q", v)
      elseif type(v) == "boolean" or type(v) == "number" or type(v) == "nil" then
        value_str = tostring(v)
      else
        value_str = string.format("[%s]", type(v)) -- 不支持的类型直接显示类型名
      end

      str = str .. indent .. key_str .. " = " .. value_str
    end

    str = str .. "\n" .. string.sub(indent, 1, -3) .. "}" -- 闭合表格（去掉最后一级缩进）
    return str
  end
  local function formatMsg(msg)
    local time_str = os.date("%H:%M:%S")
    local prefix = string.format("[%s %s]", os.date("%Y-%m-%d"), time_str)

    if type(msg) == "table" then
      return string.format("%s 【元表】\n%s", prefix, tableToString(msg))
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
  function debug:log(msg, is_print)
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
      writeToFile(formatted_msg)
    elseif self.mode == "all" then
      -- 全量模式（控制台+文件）
      _ = is_print and print(formatted_msg)
      writeToFile(formatted_msg)
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
  function debug:setLogDir(dir_path, is_print)
    if not is_print then is_print = false end
    if type(dir_path) == "string" then
      self.log_dir = dir_path
      self:log(string.format("日志目录已设置为：%s", dir_path), is_print)
      ensureLogDir() -- 确保目录存在
    else
      self:log("设置日志目录失败：路径必须是字符串")
    end
  end

  -- 切换输出模式
  -- @param new_mode: 支持 "alert"、"print"、"file"、"all"
  function debug:setMode(new_mode, is_print)
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
  function debug:setFileLogEnabled(is_enable, is_print)
    if not is_print then is_print = false end
    self.enable_file_log = is_enabled
    self:log(string.format("文件日志已%s", is_enabled and "开启" or "关闭"), is_print)
    if is_enabled then
      ensureLogDir() -- 开启时确保目录存在
    end
  end

  -- 全局开关（一键开启/关闭所有调试功能）
  function debug:setEnabled(is_enabled, is_print)
    if is_enabled == true and self.is_global_lock == true then
      return
    end
    if not is_print then is_print = false end
    self.enabled = is_enabled
    self:log(string.format("调试工具已%s", is_enabled and "开启" or "关闭"), is_print)
  end

  -- 配置动态调整相关函数 start

  -- 初始化日志目录和状态
  ensureLogDir()
  if debug.enabled then
    debug:log(
      string.format(
        "调试工具初始化完成！\n- 全局开关：%s\n- 输出模式：%s\n- 文件日志：%s\n- 日志目录：%s",
        tostring(debug.enabled),
        debug.mode,
        tostring(debug.enable_file_log),
        debug.log_dir)
    )
  end
  return debug
end

-- -- ================== 示例 ==================
-- -- 1. 初始化调试工具（全局唯一）
-- local debug = F_debug()

-- -- 2. 自定义配置
-- debug:setMode("all")  -- 开发推荐：控制台+文件日志
-- -- debug:setLogDir("./")  -- 自定义日志目录（可选），默认是在aseprite的安装目录下

-- -- 使用
-- debug:log(传入内容)
-- -- 功能完成后请关闭调试
-- -- debug:setEnabled(false) 或 注释掉启用的函数
