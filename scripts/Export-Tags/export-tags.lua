-- 初始化多语言配置
Export_Tags_I18n = I18n.new()
Export_Tags_I18n:init("scripts.Export-Tags.locale")

-- Local Variables
local lastDirectory

-- Hides layer visibilities and returns layer visibility table
function HideLayers(spr)
  local layerData = {} -- Save visibility status of each layer
  local groupData = {} -- Save visibility status of each group

  for i, layer in ipairs(spr.layers) do
    -- Recursive for layer groups
    if layer.isGroup then
      groupData[i] = layer.isVisible
      layer.isVisible = true
      layerData[i] = HideLayers(layer)
    else
      layerData[i] = layer.isVisible
      -- Set layer visible if active layer is current iteration
      layer.isVisible = layer.name == app.activeLayer.name
    end
  end

  return layerData, groupData
end

-- Restores layer visibilities
function ShowLayers(sprite, layerData, groupData)
  for i, layer in ipairs(sprite.layers) do
    if layer.isGroup then
      -- Recursive for layer groups
      layer.isVisible = groupData[i]
      ShowLayers(layer, layerData[i])
    else
      layer.isVisible = layerData[i]
    end
  end
end

-- Returns exportable tags
function GetTagList(sprite, selectedTag)
  local exportTagList
  if selectedTag == Export_Tags_I18n:get("all_tags") then
    exportTagList = activeSprite.tags
  else
    for i, tag in ipairs(activeSprite.tags) do
      if selectedTag == tag.name then
        exportTagList = { tag }
      end
    end
  end

  return exportTagList
end

-- Returns strip direction
function GetStripDirection(stripDir)
  stripOptionsData = { SpriteSheetType.HORIZONTAL, SpriteSheetType.VERTICAL }
  stripDirection = stripDir == Export_Tags_I18n:get("dir_h") and 1 or 2
  return stripOptionsData[stripDirection]
end

-- Export function
function ExportSpriteSheet(data)
  -- Check directory
  if lastDirectory == "" then
    app.alert(Export_Tags_I18n:get("dir_hint"))
    return false
  end

  -- Make parent export folder
  exportFolderName = data.d_export_folder
  app.fs.makeDirectory(lastDirectory .. "/" .. exportFolderName)

  -- Tag filter
  activeSprite = app.activeSprite
  local exportTagList = GetTagList(activeSprite, data.d_tag)

  -- If Export Only Selected Layer selected, hide inactive layers
  local layerData, groupData
  if data.d_export_layer_mode == Export_Tags_I18n:get("layer_choose_mode_text") then
    if app.activeLayer.isGroup then
      app.alert(I18n:get("layer_choose_group"))
      return false
    end

    layerData, groupData = HideLayers(activeSprite)
  end

  -- Export selected tags
  for i, tag in ipairs(exportTagList) do
    fileName = lastDirectory .. '/' .. exportFolderName .. '/' .. tag.name
    app.command.ExportSpriteSheet {
      ui = false,
      type = GetStripDirection(data.d_strip_dir),
      textureFilename = fileName .. '.png',
      tag = tag.name,
      listLayers = false,
      listTags = false,
      listSlices = false
    }
  end

  -- If Export Only Selected Layer selected, restore layer visibilities
  if data.d_export_layer_mode == Export_Tags_I18n:get("layer_choose_mode_text") then
    layerData = ShowLayers(activeSprite, layerData, groupData)
  end

  return true
end

-- Dialog show function
function ShowDialog(plugin)
  -- Check active sprite
  activeSprite = app.activeSprite
  if not activeSprite then
    app.alert(Export_Tags_I18n:get("no_sprite_hint"))
    return
  end

  -- Check active layer
  activeLayer = app.activeLayer
  if not activeLayer then
    app.alert(Export_Tags_I18n:get("no_active_layer_hint"))
    return
  end

  -- Check if project have tags
  if #activeSprite.tags == 0 then
    app.alert(Export_Tags_I18n:get("no_tags_hint"))
    return
  end

  -- Remove spaces from sprite name
  spriteName = string.gsub(activeLayer.name, "%s+", "")

  -- Get all avilable tags
  tagOptions = { Export_Tags_I18n:get("all_tags") };
  for i, tag in ipairs(activeSprite.tags) do
    tagOptions[i + 1] = tag.name;
  end

  dlg = Dialog(Export_Tags_I18n:get("panel_title"))
  dlg:combobox {
    id = "d_tag",
    label = Export_Tags_I18n:get("panel_label"),
    option = plugin.preferences.selectedTag,
    options = tagOptions,
    onchange = function()
      plugin.preferences.selectedTag = dlg.data.d_tag
    end
  }:combobox {
    id = "d_strip_dir",
    label = Export_Tags_I18n:get("panel_label_dic"),
    option = plugin.preferences.stripDirection,
    options = { Export_Tags_I18n:get("dir_h"), Export_Tags_I18n:get("dir_v") },
    onchange = function()
      plugin.preferences.stripDirection = dlg.data.d_strip_dir
    end
  }:combobox {
    id = "d_export_layer_mode",
    label = Export_Tags_I18n:get("panel_label_export"),
    option = plugin.preferences.exportLayerMode,
    options = { Export_Tags_I18n:get("layer_choose_mode_all"), Export_Tags_I18n:get("layer_choose_mode_text") },
    onchange = function()
      plugin.preferences.exportLayerMode = dlg.data.d_export_layer_mode
    end
  }:separator {
    text = ""
  }:entry {
    id = "d_export_folder",
    label = Export_Tags_I18n:get("panel_label_folder"),
    text = spriteName,
    focus = true
  }:file {
    id = "d_directory",
    label = Export_Tags_I18n:get("panel_label_dir"),
    title = Export_Tags_I18n:get("panel_label_dir_title"),
    open = false,
    save = true,
    filename = spriteName,
    entry = true,
    filetypes = {},
    onchange = function()
      -- Get parent folder of save data
      parentFolder = app.fs.filePath(dlg.data.d_directory)

      -- Save last selected directory to preferences
      plugin.preferences.lastdir = parentFolder
      lastDirectory = parentFolder
    end
  }:separator {
    text = ""
  }:button {
    id = "d_btn_export",
    text = "&" .. Export_Tags_I18n:get("export_text"),
    onclick = function()
      didExport = ExportSpriteSheet(dlg.data)
      if didExport then
        dlg:close()
      end
    end
  }:button {
    text = "&" .. Export_Tags_I18n:get("cancel_button_text")
  }:show {
    wait = false
  }
end

-- Plugin initialize
function init(plugin)
  -- Check if we have previous directory prefs
  if plugin.preferences.lastdir == nil then
    plugin.preferences.lastdir = ""
  end

  -- Check previous selected tag prefs
  if plugin.preferences.selectedTag == nil then
    plugin.preferences.selectedTag = "All Tags"
  end

  -- Check previous selected strip direction prefs
  if plugin.preferences.stripDirection == nil then
    plugin.preferences.stripDirection = "Horizontal"
  end

  -- Check previous selected strip direction prefs
  if plugin.preferences.exportLayerMode == nil then
    plugin.preferences.exportLayerMode = "All Visible Layers"
  end

  -- Cache previous directory
  lastDirectory = plugin.preferences.lastdir

  -- Register command
  plugin:newMenuSeparator {
    group = "layer_merge"
  }
  plugin:newCommand {
    id = "excalith-export-tags",
    title = Export_Tags_I18n:get("panel_title"),
    group = "layer_merge",
    onclick = function()
      ShowDialog(plugin)
    end
  }
end

-- Plugin exit
function exit(plugin)
end
