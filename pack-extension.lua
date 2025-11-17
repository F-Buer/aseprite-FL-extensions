--[[
  一个简单的打包脚本，用于减少在aseprite扩展的手动打包操作。
]]

-- 引入扩展配置
local json = require "./utils/json/json"
local data, err = io.open("./package.json", "r")
if not data then return print("文件读取失败！", err) end
local json_data = data:read("*a")
local jd = json.decode(json_data)
data:close()

-- 配置参数
local config = {
  source_path = ".\\*",                                                 -- 要打包的源目录（包含package.json的文件夹）
  output_path = '.\\' .. jd.displayName .. '-' .. jd.version .. '.zip', -- 输出目录（nil则默认当前目录）
  replace_name = "aseprite-extension",                                  -- 指定类型后缀
  exclude_files = {                                                     -- 要排除掉的文件及文件夹
    'pack-extension.lua', '.history', '.gitignore', '.git'
  },
}

-- 删除已经存在的包
os.remove(string.gsub(config.output_path, '.zip$', '') .. '.' .. config.replace_name)

-- 扩展压缩包
local function zip_dir(params)
  local cmd
  if package.config:sub(1, 1) == '\\' then
    -- 执行powershell命令，对指定目录（排除指定目录与文件）进行压缩。
    -- 注意：当存在要生成的同名压缩包文件会造成错误中断，如提示【XX路径地址存在，或者不是有效的文件系统路径。】，默认会删除该同名压缩包，二次执行即可。
    cmd = string.format(
      'powershell -Command "Get-ChildItem -Path \'%s\' | Where-Object { $name = $_.Name; @(\'%s\') -notcontains $name } | Compress-Archive -DestinationPath \'%s\' -Force"',
      params.source_path,
      table.concat(params.exclude_files, "', '"),
      params.output_path
    )
  else -- Linux/MacOs：用 zip 命令（需系统预装 zip）
    -- 暂不对Linux/MacOs做兼容
    -- cmd = string.format('zip -r "%s" "%s"', config.output_path, config.source_path)
    return false
  end
  return os.execute(cmd) == true
end

-- 更改文件名称
local function rename_file(params)
  local before_path = string.gsub(params.output_path, '.zip$', '')
  local newFileName = before_path .. '.' .. params.replace_name
  -- os.remove(newFileName)
  local res, _ = os.rename(params.output_path, newFileName)
  return res and true or false
end

-- 执行压缩
if not zip_dir(config) then
  print("failed")
  return
end

-- 重命名压缩包
if not rename_file(config) then
  print("rename error: ")
  return
end
print("successful: " .. config.output_path)
