local cel = app.site.cel
if not cel then
    return app.alert(Balamod_I18n:get("blindify_cel"))
end

local origImg = cel.image:clone()

local r = app.sprite.bounds
-- local file = Global_Config.SYS_EXTENSIONS_DIR("Balamod", "Images", "BlindShineOverlay.aseprite")

if r.width == 34 and r.height == 34 then
    r.width = r.width * 21
    app.command.CanvasSize { ui = false, bounds = r }
    local newImg = Image(r.width, r.height)
    local x = 0
    app.transaction(function()
        while x < 34 * 21 do
            newImg:drawImage(origImg, { x, 0 })
            x = x + 34
        end
        -- newImg:drawImage(Image { fromFile = file }, { 0, 0 }, 124)
    end)
    cel.image = newImg
    app.refresh()
else
    return app.alert(Balamod_I18n:get("blindify_hint"))
end
