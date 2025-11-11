--[[
  该类用于生成JSON数据并将文件保存磁盘中。
  需要借助25版本以上的官方JSON功能，如要向下兼容则需要手动引入新的JSON库。
]]
SpriteJson = {
  -- 设置精灵图的JSON数据
  ---@param sprite Sprite
  ---@param property_name string
  ---@param property_value any
  setProperty = function(sprite, property_name, property_value)
    if not SpriteJson.__isSaved(sprite) then
      return
    end
    local properties = {}
    if app.fs.isFile(SpriteJson.__jsonName(sprite)) then
      properties = SpriteJson.__loadJson(sprite)
    end
    properties[property_name] = property_value

    local json_file = io.open(SpriteJson.__jsonName(sprite) or "", "w")
    if not json_file then return end
    json_file:write(json.encode(properties))
    json_file:close()
  end,

  -- 获取保存的精灵图JSON中指定的属性
  getProperty = function(sprite, property_name)
    if not SpriteJson.__isSaved(sprite) then
      return nil
    end
    if not app.fs.isFile(SpriteJson.__jsonName(sprite)) then
      return nil
    end
    return SpriteJson.__loadJson(sprite)[property_name]
  end,
  -- 修改指定的属性的值
  ---@param sprite Sprite
  ---@param property_name string
  ---@param mod_func function
  modifyProperty = function(sprite, property_name, mod_func)
    SpriteJson.setProperty(sprite, property_name, mod_func(SpriteJson.getProperty(sprite, property_name)))
  end,

  -- 判断该精灵图是否为正确的文件
  __isSaved = function(sprite)
    return app.fs.isFile(sprite.filename)
  end,
  -- 生成要保存的JSON文件的名称
  ---@return string | nil
  __jsonName = function(sprite)
    if not SpriteJson.__isSaved(sprite) then
      return nil
    end
    return (sprite.filename:match("^(.*)%..*$")) .. "-lapse.json"
  end,
  -- 加载JSON文件内容
  __loadJson = function(sprite)
    local json_file = io.open(SpriteJson.__jsonName(sprite) or "", 'r')
    local json_data = json_file and json_file:read("*all")
    _ = json_file and json_file:close()
    -- 数据解包
    local status, result = pcall(json.decode, json_data)
    return (status and result) or {}
  end
}
