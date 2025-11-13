return {
    ShowDetails = function(name, width, height, file, pluginData)
        validate = function(dlg, pluginData)
            if dlg.data.templateName == nil or dlg.data.templateName == "" then
                pluginData.utils.create_error(Balamod_I18n:get("dw_err_hint1"), dlg, 0);
                return false
            end
            if dlg.data.templateWidth <= 0 or dlg.data.templateHeight <= 0 then
                pluginData.utils.create_error(Balamod_I18n:get("dw_err_hint2"), dlg, 0);
                return false
            end
            return true
        end
        ----------------------------------------------------------------------------------------
        -- Setup the dialog, and prepare a result object for the return.
        ----------------------------------------------------------------------------------------
        local initName = name;
        local data = { template = { name = name, width = width, height = height, file = file } };
        local dlg = Dialog(Balamod_I18n:get("dw_dlg_title"));

        ----------------------------------------------------------------------------------------
        -- Setup the widgets for the templates data, updating the result on changes.
        ----------------------------------------------------------------------------------------
        dlg:entry {
            id = "templateName",
            label = Balamod_I18n:get("dw_dlg_label1"),
            text = (data.template.name or Balamod_I18n:get("dw_dlg_text1")),
            onchange = function() data.template.name = dlg.data.templateName; end
        }:newrow();

        dlg:number {
            id = "templateWidth",
            label = Balamod_I18n:get("dw_dlg_label2"),
            decimals = 0,
            text = tostring(data.template.width or 128),
            onchange = function() data.template.width = dlg.data.templateWidth; end
        }:newrow();

        dlg:number {
            id = "templateHeight",
            label = Balamod_I18n:get("dw_dlg_label3"),
            decimals = 0,
            text = tostring(data.template.height or 128),
            onchange = function() data.template.height = dlg.data.templateHeight; end
        }:newrow();

        dlg:file {
            id = "templateFile",
            open = true,
            load = true,
            entry = false,
            filename = data.template.file,
            filetypes = { "ase", "aseprite", "png" },
            onchange = function()
                data.template.file = dlg.data.templateFile;
                local fileSprite = Sprite { fromFile = dlg.data.templateFile };
                local w = fileSprite.width;
                local h = fileSprite.height;
                fileSprite:close();
                data.template.width = w;
                data.template.height = h;
                dlg:modify { id = "templateWidth", text = w }
                dlg:modify { id = "templateHeight", text = h }
            end
        }:newrow();


        ----------------------------------------------------------------------------------------
        -- Setup the buttons which will set the result action and close the dialog.
        ----------------------------------------------------------------------------------------
        dlg:button {
            id = "saveChangesButton",
            text = Balamod_I18n:get("dw_btn_text1"),
            onclick = function()
                if validate(dlg, pluginData) then
                    data.action = "update";
                    dlg:close();
                end
            end
        }

        dlg:button {
            id = "addNewButton",
            text = Balamod_I18n:get("dw_btn_text2"),
            onclick = function()
                if validate(dlg, pluginData) then
                    if (initName == dlg.data.templateName) then
                        refresh = pluginData.utils.create_confirm(Balamod_I18n:get("dw_confirm_hint1"));
                        if refresh then
                            data.action = "update";
                            dlg:close();
                        end
                    else
                        data.action = "add";
                        dlg:close();
                    end
                end
            end
        }

        dlg:button {
            id = "deleteButton",
            text = Balamod_I18n:get("dlg_btn_text4"),
            onclick = function()
                refresh = pluginData.utils.create_confirm(Balamod_I18n:get("dw_confirm_hint2") ..
                    " '" .. dlg.data.templateName .. "'?");
                if refresh then
                    data.action = "delete";
                    dlg:close();
                end
            end
        }

        dlg:button {
            id = "cancelButton",
            text = Balamod_I18n:get("dw_btn_text3"),
            onclick = function()
                data.action = nil;
                dlg:close();
            end
        }

        dlg:show { wait = true };

        return data;
    end
};
