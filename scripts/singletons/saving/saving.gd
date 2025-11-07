extends Node

@onready var editor:Editor = get_node("/root/editor")
var game:Game

enum ACTION {NEW, OPEN}

var savePath:String = ""
var confirmAction:ACTION

const FILE_FORMAT_VERSION:int = 0

# Okay.
# Here's how we'll do it
# HEADER:
# - file format header
# - file format version number
# LEVEL METADATA:
# - level object
# - level size
# - active mods
# - modpack
# - modpack version
# - levelstart
# LEVEL DATA:
# - tiles
# - components
# - objects

func _ready() -> void:
	await editor.ready
	DirAccess.make_dir_absolute("user://puzzles")
	editor.saveAsDialog.file_selected.connect(save)
	editor.saveAsDialog.add_filter("*.cedit", "IWLCEditor Puzzle File")
	editor.openDialog.file_selected.connect(load)
	editor.openDialog.add_filter("*.cedit", "IWLCEditor Puzzle File")
	editor.unsavedChangesPopup.get_ok_button().theme_type_variation = &"RadioButtonText"
	editor.unsavedChangesPopup.get_cancel_button().theme_type_variation = &"RadioButtonText"
	editor.unsavedChangesPopup.get_ok_button().pressed.connect(confirmed)
	editor.loadErrorPopup.get_ok_button().theme_type_variation = &"RadioButtonText"

func open() -> void:
	confirmAction = ACTION.OPEN
	if game.anyChanges:
		editor.unsavedChangesPopup.position = get_window().position+(get_window().size-editor.unsavedChangesPopup.size)/2
		editor.unsavedChangesPopup.visible = true
		editor.unsavedChangesPopup.grab_focus()
	else: confirmed()

func saveAs() -> void:
	editor.saveAsDialog.current_dir = "puzzles"
	editor.saveAsDialog.current_file = "puzzles/"+game.level.name+".cedit"
	editor.saveAsDialog.visible = true
	editor.saveAsDialog.grab_focus()

func new() -> void:
	confirmAction = ACTION.NEW
	if game.anyChanges:
		editor.unsavedChangesPopup.position = get_window().position+(get_window().size-editor.unsavedChangesPopup.size)/2
		editor.unsavedChangesPopup.visible = true
		editor.unsavedChangesPopup.grab_focus()
	else: confirmed()

func confirmed() -> void:
	match confirmAction:
		ACTION.NEW: clear()
		ACTION.OPEN:
			editor.openDialog.current_dir = "puzzles"
			editor.openDialog.visible = true
			editor.openDialog.grab_focus()

func clear() -> void:
	savePath = ""
	game.levelBounds = Rect2i(0,0,800,608)
	editor.focusDialog.defocus()
	editor.objectHovered = null
	editor.componentHovered = null
	editor.componentDragged = null
	editor.lockBufferConvert = false
	editor.connectionSource = null
	if editor.modsWindow: editor.modsWindow._close()
	editor.quickSet.cancel()
	editor.modes.setMode(Editor.MODE.SELECT)
	editor.otherObjects.objectSelected(PlayerSpawn, true)
	editor.multiselect.stopDrag()
	editor.multiselect.clipboard.clear()
	if game.playState != Game.PLAY_STATE.EDIT: await game.stopTest()
	game.latestSpawn = null
	game.levelStart = null
	game.fastAnimSpeed = 0
	game.fastAnimTimer = 0
	game.complexViewHue = 0
	game.goldIndexFloat = 0
	game.objectIdIter = 0
	game.componentIdIter = 0
	for object in game.objects.values(): object.queue_free()
	game.objects.clear()
	for component in game.components.values(): component.queue_free()
	game.components.clear()
	game.level = Level.new()
	game.level.game = game
	game.anyChanges = false
	game.tiles.clear()
	Changes.undoStack.clear()
	Changes.undoStack.append(Changes.UndoSeparator.new())
	Changes.stackPosition = 0
	Mods.activeModpack = Mods.modpacks[&"Refactored"]
	Mods.activeVersion = Mods.activeModpack.versions[0]
	for mod in Mods.mods.values(): mod.active = false
	editor.home()

func save(path:String="") -> void:
	if !path:
		if savePath and !game.anyChanges: return
		return saveAs()
	else: savePath = path
	game.anyChanges = false

	var file:FileAccess = FileAccess.open(path,FileAccess.ModeFlags.WRITE)

	# HEADER
	file.store_pascal_string("IWLCEditorPuzzle")
	file.store_32(FILE_FORMAT_VERSION)
	# LEVEL METADATA
	file.store_var(game.level,true)
	file.store_var(game.levelBounds.size)
	file.store_var(Mods.getActiveMods())
	var modpackId = Mods.modpacks.find_key(Mods.activeModpack)
	file.store_var(modpackId if modpackId else &"")
	if Mods.activeModpack: file.store_32(Mods.activeModpack.versions.find(Mods.activeVersion))
	file.store_64(game.levelStart.id if game.levelStart else -1)
	# LEVEL DATA
	# tiles
	file.store_var(game.tiles.tile_map_data)
	# components
	file.store_64(game.componentIdIter)
	file.store_64(len(game.components))
	for component in game.components.values():
		file.store_16(Game.COMPONENTS.find(component.get_script()))
		for property in component.PROPERTIES:
			file.store_var(component.get(property), true)
		for array in component.ARRAYS.keys():
			if component.ARRAYS[array] in Game.COMPONENTS: file.store_var(componentArrayToIDs(component.get(array)))
			else: file.store_var(component.get(array))
	# objects
	file.store_64(game.objectIdIter)
	file.store_64(len(game.objects))
	for object in game.objects.values():
		file.store_16(Game.COMPONENTS.find(object.get_script()))
		for property in object.PROPERTIES:
			file.store_var(object.get(property), true)
		for array in object.ARRAYS.keys():
			if object.ARRAYS[array] in Game.COMPONENTS: file.store_var(componentArrayToIDs(object.get(array)))
			else: file.store_var(object.get(array))
		if object is Door: file.store_var(componentArrayToIDs(object.locks))
		elif object is KeyCounter: file.store_var(componentArrayToIDs(object.elements))
	file.close()

func componentArrayToIDs(array:Array) -> Array: return array.map(func(component):return component.id)
func IDArraytoComponents(type:GDScript,array:Array) -> Array:
	if type in Game.NON_OBJECT_COMPONENTS: return array.map(func(id):return game.components[id])
	else: return array.map(func(id):return game.objects[id])

func load(path:String) -> void:
	clear()
	savePath = path

	var file:FileAccess = FileAccess.open(path,FileAccess.ModeFlags.READ)

	if file.get_pascal_string() != "IWLCEditorPuzzle": return loadError("Unrecognised file format")
	match file.get_32():
		0: LoadV0.load(file, game)
		_: return loadError("Unrecognised version")

func loadError(message:String) -> void:
	editor.loadErrorPopup.dialog_text = message
	editor.loadErrorPopup.position = get_window().position+(get_window().size-editor.loadErrorPopup.size)/2
	editor.loadErrorPopup.visible = true
	editor.loadErrorPopup.grab_focus()
