return {
  -- 插件菜单栏内容
  menu_title = "帧动画记录",
  menu_child_record = "开启记录",
  -- 帧记录面板内容
  panel_title = "帧记录面板",
  panel_generate_text = "创建",
  panel_record_tooltip = "启用记录时，在当前精灵面板上每一次绘制均会记录，\\n然后可以点击创建生成记录的帧动画，\n再次点击可停止记录。",
  panel_record_number = "帧数量",
  panel_clean_last_frame = "清除上一帧",
  panel_clean_tooltip01 =
  "清除当前精灵图帧记录，但已保存的精灵文件不会做处理。",
  panel_clean_tooltip02 = "注意：这个清理只是将临时保存的帧进行了清除， 如您未将该帧记录重新创建为新的文件，",
  panel_clean_tooltip03 = "那么当该插件在下次读取时，会重新从生成的精灵图中获取到上次保存的帧记录。",

  panel_clean_hint = "已无记录帧可清除",

  -- 插件运行时
  start_tip = "请先将当前文件保存（Ctrl + S），然后才能创建帧记录！",

  generate_msg1 = "您当前未记录任何帧动画。",
  generate_msg2 = "请先点击右侧按钮记录绘制，然后点击创建生成！",

  record_text = "启动",
  stop_text = "停止",

}
