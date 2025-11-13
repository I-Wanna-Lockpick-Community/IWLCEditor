extends Node

@onready var editor:Editor = get_node("/root/editor")

enum ACTION {NEW, OPEN, SAVE_FOR_PLAY, OPEN_FOR_PLAY, NONE}

var savePath:String = ""
var confirmAction:ACTION

var jsCallback:JavaScriptObject

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
	if OS.has_feature('web'):
		JavaScriptBridge.eval("window.callbacks = {loadJs: null};")

func editorReady() -> void:
	if !OS.has_feature('web'): DirAccess.make_dir_absolute("user://puzzles")
	editor.saveAsDialog.add_filter("*.cedit", "IWLCEditor Puzzle File")
	editor.openDialog.add_filter("*.cedit", "IWLCEditor Puzzle File")
	editor.unsavedChangesPopup.get_ok_button().theme_type_variation = &"RadioButtonText"
	editor.unsavedChangesPopup.get_cancel_button().theme_type_variation = &"RadioButtonText"
	editor.unsavedChangesPopup.get_ok_button().pressed.connect(confirmed)
	editor.loadErrorPopup.get_ok_button().theme_type_variation = &"RadioButtonText"
	editor.saveAsDialog.file_selected.connect(save)
	editor.openDialog.file_selected.connect(loadFile)

func open() -> void:
	confirmAction = ACTION.OPEN
	if Game.anyChanges:
		editor.unsavedChangesPopup.position = get_window().position+(get_window().size-editor.unsavedChangesPopup.size)/2
		editor.unsavedChangesPopup.visible = true
		editor.unsavedChangesPopup.grab_focus()
	else: confirmed()

func openForPlay() -> void:
	confirmAction = ACTION.OPEN_FOR_PLAY
	if Game.anyChanges:
		editor.unsavedChangesPopup.position = get_window().position+(get_window().size-editor.unsavedChangesPopup.size)/2
		editor.unsavedChangesPopup.visible = true
		editor.unsavedChangesPopup.grab_focus()
	else: confirmed()

func saveAs() -> void:
	editor.saveAsDialog.current_dir = "puzzles"
	editor.saveAsDialog.current_file = "puzzles/"+Game.level.name+".cedit"
	editor.saveAsDialog.visible = true
	editor.saveAsDialog.grab_focus()

func new() -> void:
	confirmAction = ACTION.NEW
	if Game.anyChanges:
		editor.unsavedChangesPopup.position = get_window().position+(get_window().size-editor.unsavedChangesPopup.size)/2
		editor.unsavedChangesPopup.visible = true
		editor.unsavedChangesPopup.grab_focus()
	else: confirmed()

func confirmed() -> void:
	match confirmAction:
		ACTION.NEW: clear()
		ACTION.OPEN, ACTION.OPEN_FOR_PLAY:
			if OS.has_feature('web'):
				jsCallback = JavaScriptBridge.create_callback(loadJs)
				JavaScriptBridge.get_interface("callbacks").loadJs = jsCallback
				JavaScriptBridge.eval("
					const input = document.createElement('input');
					input.setAttribute('type', 'file');
					input.setAttribute('accept', '.cedit');
					input.addEventListener('change', event=>{
						const reader = new FileReader();
						reader.onload = ()=>{
							let array = new Uint8Array(reader.result);
							callbacks.loadJs(array.toBase64());
						}
						reader.readAsArrayBuffer(event.target.files[0]);
						input.remove();
					});
					input.click();
				")
			else:
				editor.openDialog.current_dir = "puzzles"
				editor.openDialog.visible = true
				editor.openDialog.grab_focus()

func clear() -> void:
	savePath = ""
	Game.levelBounds = Rect2i(0,0,800,608)
	if editor:
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
	if Game.playState != Game.PLAY_STATE.EDIT: await Game.stopTest()
	Game.latestSpawn = null
	Game.levelStart = null
	Game.fastAnimSpeed = 0
	Game.fastAnimTimer = 0
	Game.complexViewHue = 0
	Game.goldIndexFloat = 0
	Game.objectIdIter = 0
	Game.componentIdIter = 0
	for object in Game.objects.values(): object.queue_free()
	Game.objects.clear()
	for component in Game.components.values(): component.queue_free()
	Game.components.clear()
	Game.level = Level.new()
	Game.anyChanges = false
	Game.tiles.clear()
	Changes.undoStack.clear()
	Changes.undoStack.append(Changes.UndoSeparator.new())
	Changes.stackPosition = 0
	Mods.activeModpack = Mods.modpacks[&"Refactored"]
	Mods.activeVersion = Mods.activeModpack.versions[0]
	for mod in Mods.mods.values(): mod.active = false
	if editor: editor.home()

func save(path:String="") -> void:
	if OS.has_feature('web'):
		savePath = "user://temp.cedit"
		path = savePath
	elif !path:
		if savePath:
			path = savePath
			if !Game.anyChanges:
				if confirmAction == ACTION.SAVE_FOR_PLAY: Game.playSaved()
				return
		else: return saveAs()
	else: savePath = path
	Game.anyChanges = false

	var file:FileAccess = FileAccess.open(path,FileAccess.ModeFlags.WRITE)

	# HEADER
	file.store_pascal_string("IWLCEditorPuzzle")
	file.store_32(FILE_FORMAT_VERSION)
	# LEVEL METADATA
	file.store_var(Game.level,true)
	file.store_var(Game.levelBounds.size)
	file.store_var(Mods.getActiveMods())
	var modpackId = Mods.modpacks.find_key(Mods.activeModpack)
	file.store_var(modpackId if modpackId else &"")
	if Mods.activeModpack: file.store_32(Mods.activeModpack.versions.find(Mods.activeVersion))
	file.store_64(Game.levelStart.id if Game.levelStart else -1)
	# LEVEL DATA
	# tiles
	file.store_var(Game.tiles.tile_map_data)
	# components
	file.store_64(Game.componentIdIter)
	file.store_64(len(Game.components))
	for component in Game.components.values():
		file.store_16(Game.COMPONENTS.find(component.get_script()))
		for property in component.PROPERTIES:
			file.store_var(component.get(property), true)
		for array in component.ARRAYS.keys():
			if component.ARRAYS[array] in Game.COMPONENTS: file.store_var(componentArrayToIDs(component.get(array)))
			else: file.store_var(component.get(array))
	# objects
	file.store_64(Game.objectIdIter)
	file.store_64(len(Game.objects))
	for object in Game.objects.values():
		file.store_16(Game.COMPONENTS.find(object.get_script()))
		for property in object.PROPERTIES:
			file.store_var(object.get(property), true)
		for array in object.ARRAYS.keys():
			if object.ARRAYS[array] in Game.COMPONENTS: file.store_var(componentArrayToIDs(object.get(array)))
			else: file.store_var(object.get(array))
		if object is Door: file.store_var(componentArrayToIDs(object.locks))
		elif object is KeyCounter: file.store_var(componentArrayToIDs(object.elements))
	file.close()
	if OS.has_feature('web'):
		JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),Game.level.name+".cedit")
	
	if confirmAction == ACTION.SAVE_FOR_PLAY: Game.playSaved()

func componentArrayToIDs(array:Array) -> Array: return array.map(func(component):return component.id)
func IDArraytoComponents(type:GDScript,array:Array) -> Array:
	if type in Game.NON_OBJECT_COMPONENTS: return array.map(func(id):return Game.components[id])
	else: return array.map(func(id):return Game.objects[id])

func loadFile(path:String) -> void:
	clear()
	savePath = path
	if confirmAction == ACTION.OPEN_FOR_PLAY:
		confirmAction = ACTION.OPEN
		return Game.playSaved()

	var file:FileAccess = FileAccess.open(path,FileAccess.ModeFlags.READ)

	if file.get_pascal_string() != "IWLCEditorPuzzle": return loadError("Unrecognised file format")
	match file.get_32():
		0: LoadV0.load(file)
		_: return loadError("Unrecognised version")

func loadJs(result) -> void:
	var buffer:PackedByteArray = Marshalls.base64_to_raw(result[0])
	var file = FileAccess.open("user://temp.cedit",FileAccess.ModeFlags.WRITE)
	file.store_buffer(buffer)
	file.close()
	loadFile("user://temp.cedit")

func loadError(message:String,title:="Load Error") -> void:
	editor.loadErrorPopup.title = title
	editor.loadErrorPopup.dialog_text = message
	editor.loadErrorPopup.position = get_window().position+(get_window().size-editor.loadErrorPopup.size)/2
	editor.loadErrorPopup.visible = true
	editor.loadErrorPopup.grab_focus()
