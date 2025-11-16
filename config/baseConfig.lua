return {
  EXTENSIONS_NAME = "aseprite-extensions",
  -- 预设的aseprite系统安装目录，用于系统内运行的扩展文件引入
  SYS_EXTENSIONS_DIR = function(...)
    return app.fs.joinPath(
      app.fs.userConfigPath, "extensions", "aseprite-extensions", "scripts", ...
    )
  end
}
