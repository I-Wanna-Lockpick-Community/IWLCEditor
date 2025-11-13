extends MenuButton
class_name FileMenu

@onready var menu:PopupMenu = get_popup()

func _ready() -> void:
	menu.theme_type_variation = &"PopupMenuFiles"
	menu.id_pressed.connect(optionPressed)
	@warning_ignore("int_as_enum_without_cast") @warning_ignore("int_as_enum_without_match")
	menu.set_item_accelerator(3, KEY_MASK_CMD_OR_CTRL | KEY_S)
	@warning_ignore("int_as_enum_without_cast") @warning_ignore("int_as_enum_without_match")
	menu.set_item_accelerator(4, KEY_MASK_CMD_OR_CTRL | KEY_MASK_SHIFT | KEY_S)
	@warning_ignore("int_as_enum_without_cast") @warning_ignore("int_as_enum_without_match")
	menu.set_item_accelerator(5, KEY_MASK_CMD_OR_CTRL | KEY_E)

func optionPressed(id:int) -> void:
	match id:
		# FILE
		0: Saving.confirmAction = Saving.ACTION.NONE; Saving.new()
		1: Saving.open()
		2: Saving.openForPlay()
		3: Saving.confirmAction = Saving.ACTION.NONE; Saving.save()
		4: Saving.confirmAction = Saving.ACTION.NONE; Saving.saveAs()
		5: pass # export
		6: OS.shell_open(ProjectSettings.globalize_path("user://puzzles"))
		# CONFIG
		8: Mods.openModsWindow()
		9: Game.play()
