require 'scripts.Frame-Record.src.config'
local F_debug = require 'utils.debug'
F_debug       = init_debug()
F_debug:setEnabled(true)

--- Constructs an SpriteLapse object, responsible for managing (adding and removing frames) the time lapse of the passed source sprite.
--- fails if the source sprite is another time lapse sprite managed by another SpriteLapse instance.
--- Also responsible for managing a dialog object that allows the user to edit this very sprite lapse instance.
---@param source_sprite Sprite
--- the sprite that frames should be taken from, when updating the time lapse
---@return SpriteLapse | nil
--- returns an SpriteLapse instance, if the object was created succesfully, otherwise nil is returned.
function SpriteLapse(source_sprite)
  local spritelapse = {
    --- instance of the sprite frames are being taken from.
    source_sprite = nil,
    lapse_dialog = nil,

    --- constructor helper method, see SpriteLapse function for info
    __init__ = function(self, _source_sprite)
      self.source_sprite = _source_sprite

      app.transaction(function()
        -- each sprite which has a time lapse, will be marked with the has_lapse property.
        -- this signals to the extension that on future loads, the following sprite should automatically be registered in the extension.

        SpriteJson.setProperty(self.source_sprite, 'has_lapse', true)

        -- has_dialog represents whether the current sprite should have its lapse_dialog visible to the user
        if SpriteJson.getProperty(self.source_sprite, 'has_dialog') == nil then
          SpriteJson.setProperty(self.source_sprite, 'has_dialog', false)
        end

        -- is_paused controls whether frames are stored, on sprite modifications
        if SpriteJson.getProperty(self.source_sprite, 'is_paused') == nil then
          SpriteJson.setProperty(self.source_sprite, 'is_paused', true)
        end
      end)

      -- load any previously stored time lapse frames into memory

      if app.fs.isFile(self:__timelapseFile()) then
        self:__loadLapse(self:__timelapseFile())
      end

      -- setup dialog
      -- hint_dlg = Dialog {
      --       title = Frame_Record_I18n:get("tip_title_warning"),
      --       resizeable = false
      --     }
      --     :button {
      --       id = "undo_confirm",
      --       text = Frame_Record_I18n:get("confirm_button_text"),
      --       onclick = function()
      --         -- 清除上一帧
      --         self:__removeFrame()
      --         hint_dlg:close()
      --       end
      --     }:button {
      --       id = "undo_cancel",
      --       text = Frame_Record_I18n:get("cancel_button_text")
      --     }

      self.lapse_dialog = Dialog {
            title = Frame_Record_I18n:get("panel_title"),
            resizeable = false,
            onclose = function()
              if self.__user_closed then
                SpriteJson.setProperty(self.source_sprite, 'has_dialog', false)
              end
            end
          }
          :label
          {
            id = "frameCount",
            text = Frame_Record_I18n:get("panel_record_number") .. ": " .. #self.__frames,
          }
          :button
          {
            id = "generateTimelapse",
            text = Frame_Record_I18n:get("panel_generate_text"),
            onclick = function()
              -- 创建前做下判断，如当前记录帧小于等于0则提示
              if #self.__frames <= 0 then
                app.alert({
                  title = Frame_Record_I18n:get("tip_title"),
                  text = {
                    Frame_Record_I18n:get("generate_msg1"),
                    Frame_Record_I18n:get("generate_msg2")
                  },
                  buttons = { Frame_Record_I18n:get("confirm_button_text") }
                })
                return
              end
              self:__generateTimelapse()
            end
          }
          :button
          {
            id = "playPauseButton",
            onclick = function()
              self:__togglePause()
              self:__syncPlayPauseButton()
            end,
          }
          :button
          {
            id = "cleanFrameButton",
            text = Frame_Record_I18n:get("panel_clean_last_frame"),
            onclick = function()
              if #self.__frames <= 0 then
                return app.alert(Frame_Record_I18n:get("panel_clean_hint"))
              end
              -- 还是要多行来处理！
              local result = app.alert({
                title = Frame_Record_I18n:get("tip_title_warning"),
                text = {
                  Frame_Record_I18n:get("panel_clean_tooltip01"),
                  Frame_Record_I18n:get("panel_clean_tooltip02"),
                  Frame_Record_I18n:get("panel_clean_tooltip03"),
                },
                resizeable = false,
                buttons = {
                  Frame_Record_I18n:get("confirm_button_text"),
                  Frame_Record_I18n:get("cancel_button_text"),
                }
              })
              if result == 1 then
                self:__removeFrame()
              end

              -- hint_dlg:show { wait = true }
            end,
          }

      self:__syncPlayPauseButton()

      -- store a copy of the sprite in memory, every time the sprite is modified, unless the time lapse is paused

      self.__sprite_event_key = self.source_sprite.events:on('change',
        function(ev)
          if SpriteJson.getProperty(self.source_sprite, 'is_paused') then
            return
          end

          self:__storeFrame(app.frame)
        end)

      return self
    end,

    --- Should be invoked whenever the SpriteLapse is no longer needed.
    --- Saves a copy of the current time lapse to disk.
    cleanup = function(self, obj)
      SpriteJson.setProperty(self.source_sprite, 'object_id', nil)
      -- 在扩展卸载或禁用或重新导入时，该复制帧重新生成并保存后再退出时和aseprite底层资源释放存在冲突，该情况只在打开了使用该扩展的精灵图时进行扩展卸载禁用等操作时才触发，这边考虑了下还是决定将其定为debug时不执行该操作，用户日常使用时一般很少会触发该类情况，且即时闪退也会保存最后的记录帧。
      if not F_debug.enabled then
        self:__generateTimelapse():close()
      end
    end,

    --- Called any time the source_sprite is focused or not
    focus = function(self, focused)
      -- the dialog should only be visible to the user, if the source_sprite is focused, and has_dialog is set.

      if focused and SpriteJson.getProperty(self.source_sprite, 'has_dialog') then
        self.lapse_dialog:show { wait = false }
      else
        -- __user_closed is used in the onclose method, to decide whether has_dialog should be cleared or not.
        self.__user_closed = false
        self.lapse_dialog:close()
        self.__user_closed = true
      end
    end,

    --- Shows the lapse_dialog dialog.
    openDialog = function(self)
      SpriteJson.setProperty(self.source_sprite, 'has_dialog', true)

      self.lapse_dialog:show { wait = false }
    end,

    __user_closed = true,
    __sprite_event_key = nil,
    -- list of Image objects, representing a frame in the time lapse.
    __frames = {},

    --- Toggle the pause state of the SpriteLapse instance
    __togglePause = function(self)
      SpriteJson.modifyProperty(self.source_sprite, 'is_paused',
        function(pause_state)
          return not pause_state
        end)
    end,

    --- Update the text of the playPauseButton so it matches with the pause state.
    ---@param self any
    __syncPlayPauseButton = function(self)
      if SpriteJson.getProperty(self.source_sprite, 'is_paused') then
        self.lapse_dialog:modify {
          id = "playPauseButton",
          text = Frame_Record_I18n:get("record_text")
          -- text = "►"
        }
      else
        self.lapse_dialog:modify {
          id = "playPauseButton",
          text = Frame_Record_I18n:get("stop_text")
          -- text = "||"
        }
      end
    end,

    --- Inserts a copy of the passed frame from the source sprite, into a new frame in the lapse_sprite.
    ---@param self any
    ---@param frame any
    --- the frame that should be copied from, if source_sprite is the active sprite, app.frame should be used.
    __storeFrame = function(self, frame)
      local new_image = Image(self.source_sprite.spec)

      new_image:drawSprite(self.source_sprite, frame.frameNumber)

      table.insert(self.__frames, new_image)

      self.lapse_dialog:modify {
        id = "frameCount",
        text = Frame_Record_I18n:get("panel_record_number") .. ": " .. #self.__frames,
      }
    end,

    --- Removes the latest frame from the time lapse memory.
    __removeFrame = function(self)
      table.remove(self.__frames, #self.__frames)
      self.lapse_dialog:modify {
        id = "frameCount",
        text = Frame_Record_I18n:get("panel_record_number") .. ": " .. #self.__frames,
      }
    end,

    --- Creates a new sprite which holds the time lapse frame currently stored in memory
    ---@return Sprite
    --- The generated sprite
    __generateTimelapse = function(self, hided)
      -- find the width and height of the sprite,
      -- it should be large enough to hold both the tallest and widest image currently in memory.

      local max_width, max_height = 0, 0

      local color_mode = nil

      if #self.__frames > 0 then
        color_mode = self.__frames[1].colorMode
      end

      for _, frame in ipairs(self.__frames) do
        max_width = math.max(max_width, frame.width)
        max_height = math.max(max_width, frame.height)
      end

      local sprite = Sprite(max_width, max_height, color_mode)

      -- convert the currently stored images in __frames to frames in the sprite

      for frame_number, frame_image in ipairs(self.__frames) do
        local frame = sprite:newEmptyFrame(frame_number)
        sprite:newCel(sprite.layers[1], frame, frame_image)
      end

      -- whenever a Sprite is constructed, it comes with an empty frame, so this frame is removed here.

      sprite:deleteFrame(#sprite.frames)

      -- finally save the time lapse sprite to disk

      sprite.filename = self:__timelapseFile()

      sprite:saveAs(sprite.filename)

      return sprite
    end,

    --- Returns the name of the source_sprite suffixed with '-lapse'
    ---@return string
    --- Time lapse filename
    __timelapseFile = function(self)
      local name, ext = self.source_sprite.filename:match("^(.*)(%..*)$")

      return name .. "-lapse" .. ext
    end,

    --- Loads all frames of the given sprite, stored at file_name into the __frames list.
    ---@param file_name any
    __loadLapse = function(self, file_name)
      -- open the sprite which has all of the frames

      local timelapse_sprite = Sprite { fromFile = self:__timelapseFile() }

      -- load all of the frames into memory

      for _, cel in ipairs(timelapse_sprite.cels) do
        -- we create a new image instance here, as the cel.image will reference an invalid Image when we close the timelapse_sprite
        table.insert(self.__frames, Image(cel.image))
      end

      -- close the sprite now

      timelapse_sprite:close()
    end,
  }

  return spritelapse:__init__(source_sprite)
end
