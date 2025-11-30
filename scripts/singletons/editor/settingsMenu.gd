extends PanelContainer
class_name SettingsMenu

@onready var editor:Editor = get_node("/root/editor")
@onready var levelSettings:MarginContainer = %levelSettings
@onready var editorSettings:MarginContainer = %editorSettings
@onready var gameSettings:GameSettings = %gameSettings

var configFile:ConfigFile = ConfigFile.new()

var textDraw:RID

func _ready() -> void:
	textDraw = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(textDraw,1)
	RenderingServer.canvas_item_set_parent(textDraw,get_canvas_item())
	if !FileAccess.file_exists("user://config.ini"): closed()
	if OS.has_feature("web"): %fileDialogWorkaroundCont.visible = false
	_tabSelected(0)

func _input(event:InputEvent):
	if !editor.settingsOpen: return
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ESCAPE:
				editor._toggleSettingsMenu(false)
				get_viewport().set_input_as_handled()

func _tabSelected(tab:int) -> void:
	%levelSettings.visible = tab == 0
	%editorSettings.visible = tab == 1
	%gameSettings.visible = tab == 2
	editor.updateDescription()
	queue_redraw()

func _levelNumberSet(string:String) -> void:
	Game.level.number = string
	Game.anyChanges = true
	queue_redraw()

func _levelNameSet(string:String) -> void:
	Game.level.name = string if string else "Unnamed Level"
	Game.anyChanges = true
	queue_redraw()

func _levelAuthorSet(string:String) -> void:
	Game.level.author = string
	Game.anyChanges = true
	queue_redraw()

func _draw() -> void:
	RenderingServer.canvas_item_clear(textDraw)
	if %levelSettings.visible:
		TextDraw.outlinedCentered2(Game.FLEVELID,textDraw,%levelNumber.text,Color.WHITE,Color.BLACK,24,size/2 + Vector2(0,-77))
		TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelName.text,Color.WHITE,Color.BLACK,36,size/2 + Vector2(0,-13))
		TextDraw.outlinedCentered2(Game.FLEVELNAME,textDraw,%levelAuthor.text,Color.BLACK,Color.WHITE,36,size/2 + Vector2(0,83))

func _defocus() -> void:
	if !%levelName.text:
		%levelName.text = "Unnamed Level"
		_levelNameSet(%levelName.text)

func opened() -> void:
	configFile.load("user://config.ini")
	%levelNumber.text = Game.level.number
	%levelName.text = Game.level.name
	%levelAuthor.text = Game.level.author
	%fileDialogWorkaround.button_pressed = configFile.get_value("editor", "fileDialogWorkaround", false)
	%fullscreen.button_pressed = configFile.get_value("editor", "fullscreen", false)
	for setting in get_tree().get_nodes_in_group("hotkeySetting"):
		InputMap.action_erase_events(setting.action)
		setting._reset(configFile.get_value("editor", "hotkey_"+setting.action, setting.default))
		for button in setting.buttons: button.check()
	%colorQuicksetSetting.setMatches(configFile.get_value("editor", "quicksetColorMatches", ColorQuicksetSetting.DEFAULT_MATCHES.duplicate()))
	%lockSizeQuicksetSetting.setMatches(configFile.get_value("editor", "quicksetLockSizeMatches", LockSizeQuicksetSetting.DEFAULT_MATCHES.duplicate()))
	%gameSettings.opened(configFile)

func closed() -> void:
	configFile.set_value("editor", "fileDialogWorkaround", %fileDialogWorkaround.button_pressed)
	configFile.set_value("editor", "fullscreen", %fullscreen.button_pressed)
	for setting in get_tree().get_nodes_in_group("hotkeySetting"):
		configFile.set_value("editor", "hotkey_"+setting.action, InputMap.action_get_events(setting.action))
	configFile.set_value("editor", "quicksetColorMatches", ColorQuicksetSetting.matches)
	configFile.set_value("editor", "quicksetLockSizeMatches", LockSizeQuicksetSetting.matches)
	%gameSettings.closed(configFile)
	configFile.save("user://config.ini")

func _fileDialogWorkaroundSet(toggled_on:bool) -> void:
	editor.saveAsDialog.use_native_dialog = !toggled_on
	editor.openDialog.use_native_dialog = !toggled_on

func _fullscreenSet(toggled_on:bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if toggled_on else Window.MODE_WINDOWED
