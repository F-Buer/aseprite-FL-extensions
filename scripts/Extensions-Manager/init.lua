Extension_manager_I18n = I18n.new()
Extension_manager_I18n:init("scripts.Extensions-Manager.locale")

function init(plugin)
  local dlg = Dialog({
    title = Extension_manager_I18n:get("plugin_title"),
    onclose = function()

    end
  })
  -- 查看当前配置json数据
  local file_name = app.fs.joinPath(
    app.fs.userConfigPath, "extensions", "aseprite-extensions", "package.json")

  local datas = Utils.load_json(file_name)

  -- 扩展种类操作函数
  local function categoriesType(val)
    app.alert(val)
  end

  if datas ~= nil then
    _ = datas.categories and categoriesType(datas.categories)
  end
  dlg:label {
    id = "copyright",
    label = "版权所有：",
    text = "非正常人类研究中心"
  }
      :button {
        id = "dlg-close-button",
        text = "关闭对话框",
        onclick = function()
          dlg:close()
        end
      }:button {
    id = "dlg-exit-button",
    text = "退出程序",
    onclick = function()
      app.exit()
    end
  }

  plugin:newMenuSeparator {
    group = "layer_merge"
  }

  plugin:newCommand {
    id = "extensions-manager",
    title = Extension_manager_I18n:get("plugin_title"),
    group = "layer_merge",
    onclick = function()
      dlg:show { wait = false }
    end,
    onenabled = function()
      -- return not not app.sprite
      return true
    end
  }
end

function exit()
end
