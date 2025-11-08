extends PanelContainer
class_name SettingsMenu

@onready var editor:Editor = get_node("/root/editor")
@onready var levelSettings:MarginContainer = %levelSettings
@onready var editorSettings:MarginContainer = %editorSettings

var configFile:ConfigFile = ConfigFile.new()

var textDraw:RID

func _ready() -> void:
	textDraw = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(textDraw,1)
	RenderingServer.canvas_item_set_parent(textDraw,get_canvas_item())
	if !FileAccess.file_exists("user://config.ini"): closed()

func _tabSelected(tab:int) -> void:
	%levelSettings.visible = tab == 0
	%editorSettings.visible = tab == 1
	editor.updateDescription()
	queue_redraw()

func _levelNumberSet(string:String) -> void:
	editor.game.level.number = string
	queue_redraw()

func _levelNameSet(string:String) -> void:
	editor.game.level.name = string if string else "Unnamed Level"
	queue_redraw()

func _levelAuthorSet(string:String) -> void:
	editor.game.level.author = string
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
	%levelNumber.text = editor.game.level.number
	%levelName.text = editor.game.level.name
	%levelAuthor.text = editor.game.level.author
	%fileDialogWorkaround.button_pressed = configFile.get_value("editor", "fileDialogWorkaround")	

func closed() -> void:
	configFile.set_value("editor", "fileDialogWorkaround", %fileDialogWorkaround.button_pressed)
	configFile.save("user://config.ini")

func _fileDialogWorkaroundSet(toggled_on: bool) -> void:
	editor.saveAsDialog.use_native_dialog = !toggled_on
	editor.openDialog.use_native_dialog = !toggled_on
