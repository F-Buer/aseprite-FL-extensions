return {
  tip_title = "prompt",
  tip_title_error = "error",
  tip_title_warning = "warning",
  -- 版本校验弹窗
  version_check_title = "Version Check",
  version_check_msg =
  "Sorry, your aseprite version (% s) is not compatible with the plugin (FL-Extensions/Frame-Record) (API version not lower than v1.3-rc3). If you need to use the functionality of this plugin, please upgrade your version!",
  version_check_tip = "You can click the button on the right to view the API update record on the official website.",
  confirm_button_text = "OK",
  cancel_button_text = "Cancel",

  -- 插件菜单栏内容
  menu_title = "Frame Animate Record",
  menu_child_record = "Recording Panel",

  -- 帧记录面板内容
  panel_title = "Time Lapse",
  panel_generate_text = "Generate",
  panel_record_tooltip =
  "When recording is enabled, every drawing on the current sprite panel will be recorded. \n\n Then, you can click to create a frame animation that generates the record, \n\n and click again to stop recording.",
  panel_record_number = "Frames",
  panel_clean_last_frame = "Undo Last Frame",
  panel_clean_tooltip01 = "Clear the current sprite frame record, but the saved sprite file will not be processed.",
  panel_clean_tooltip02 =
  "Note: This cleaning only clears temporarily saved frames. If you have not recreated the frame record as a new file,",
  panel_clean_tooltip03 =
  "So when the plugin reads it again, it will retrieve the last saved frame record from the generated sprite image.",
  panel_clean_hint = "There are no record frames left to clear",

  start_tip = "Sprite must be saved to disk before a time lapse can be created!",

  generate_msg1 =
  "You are currently not recording any frame animations.",
  generate_msg2 = "Please click the button on the right to record and draw, and then click Create to generate!",

  record_text = "start",
  stop_text = "stop",
}
