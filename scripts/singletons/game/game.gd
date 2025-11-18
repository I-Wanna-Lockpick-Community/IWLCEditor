extends Node

static var COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement, KeyBulk, Door, Goal, KeyCounter, PlayerSpawn, RemoteLock]
static var NON_OBJECT_COMPONENTS:Array[GDScript] = [Lock, KeyCounterElement]

const COLORS:int = 22
enum COLOR {MASTER, WHITE, ORANGE, PURPLE, RED, GREEN, BLUE, PINK, CYAN, BLACK, BROWN, PURE, GLITCH, STONE, DYNAMITE, QUICKSILVER, MAROON, FOREST, NAVY, ICE, MUD, GRAFFITI}
const COLOR_NAMES = ["Master", "White", "Orange", "Purple", "Red", "Green", "Blue", "Pink", "Cyan", "Black", "Brown", "Pure", "Glitch", "Stone", "Dynamite", "Quicksilver", "Maroon", "Forest", "Navy", "Ice", "Mud", "Graffiti"]
const NONFLAT_COLORS:Array[COLOR] = [COLOR.MASTER, COLOR.PURE, COLOR.GLITCH, COLOR.STONE, COLOR.DYNAMITE, COLOR.QUICKSILVER]
const ANIMATED_COLORS:Array[COLOR] = [COLOR.MASTER, COLOR.PURE, COLOR.DYNAMITE, COLOR.QUICKSILVER]
const TEXTURED_COLORS:Array[COLOR] = [COLOR.MASTER, COLOR.PURE, COLOR.STONE, COLOR.DYNAMITE, COLOR.QUICKSILVER]
const TILED_TEXTURED_COLORS:Array[COLOR] = [COLOR.DYNAMITE]

static var COLOR_TEXTURES:ColorsTextureLoader = ColorsTextureLoader.new("res://assets/game/colorTexture/$c.png",TEXTURED_COLORS)

const EMPTY:Texture2D = preload("res://assets/empty.png")
const FILLED:Texture2D = preload("res://assets/filled.png")

var highTone:Array[Color] = DEFAULT_HIGH.duplicate()
const DEFAULT_HIGH:Array[Color] = [
	Color("#e7bf98"),
	Color("#edeae7"), Color("#e7bf98"), Color("#bfa4db"),
	Color("#c83737"), Color("#70cf88"), Color("#8795b8"),
	Color("#e4afca"), Color("#8acaca"), Color("#554b40"),
	Color("#aa6015"),
	Color("#edeae7"),
	Color("#78be00"),
	Color("#96a0a5"),
	Color("#d18866"), Color("#ffffff"),
	Color("#6d4040"), Color("#3f5c3f"), Color("#49496b"),
	Color("#d1ffff"), Color("#b57ea7"), Color("#f2e380")
]
const BRIGHT_HIGH:Array[Color] = [
	Color("#e7bf98"),
	Color("#edeae7"), Color("#e7bf98"), Color("#bfa4db"),
	Color("#eb3737"), Color("#70cf88"), Color("#8795b8"),
	Color("#e4afca"), Color("#8acaf8"), Color("#554b40"),
	Color("#aa6015"),
	Color("#edeae7"),
	Color("#78be00"),
	Color("#96a0a5"),
	Color("#d18866"), Color("#ffffff"),
	Color("#6d4040"), Color("#3f5c3f"), Color("#49496b"),
	Color("#d1ffff"), Color("#b57ea7"), Color("#f2e380")
]

var mainTone:Array[Color] = DEFAULT_MAIN.duplicate()
const DEFAULT_MAIN:Array[Color] = [
	Color("#d68f49"),
	Color("#d6cfc9"), Color("#d68f49"), Color("#8f5fc0"),
	Color("#8f1b1b"), Color("#359f50"), Color("#5f71a0"),
	Color("#cf709f"), Color("#50afaf"), Color("#363029"),
	Color("#704010"),
	Color("#d6cfc9"),
	Color("#b49600"),
	Color("#647378"),
	Color("#d34728"), Color("#b8b8b8"),
	Color("#583232"), Color("#2c3b2c"), Color("#333352"),
	Color("#82f0ff"), Color("#966489"), Color("#e2c961")
]
const BRIGHT_MAIN:Array[Color] = [
	Color("#d68f49"),
	Color("#d6cfc9"), Color("#d68f49"), Color("#8f5fc0"),
	Color("#a11b1b"), Color("#359f50"), Color("#5f71a0"),
	Color("#cf709f"), Color("#50afd1"), Color("#363029"),
	Color("#704010"),
	Color("#d6cfc9"),
	Color("#b49600"),
	Color("#647378"),
	Color("#d34728"), Color("#b8b8b8"),
	Color("#583232"), Color("#2c3b2c"), Color("#333352"),
	Color("#82f0ff"), Color("#966489"), Color("#e2c961")
]

var darkTone:Array[Color] = DEFAULT_DARK.duplicate()
const DEFAULT_DARK:Array[Color] = [
	Color("#9c6023"),
	Color("#bbaea4"), Color("#9c6023"), Color("#603689"),
	Color("#480d0d"), Color("#1b5028"), Color("#3a4665"),
	Color("#af3a75"), Color("#357575"), Color("#181512"),
	Color("#382007"),
	Color("#bbaea4"),
	Color("#dc6e00"),
	Color("#3c4b50"),
	Color("#7a3117"), Color("#818181"),
	Color("#3b1f1f"), Color("#1d2b1d"), Color("#262633"),
	Color("#62b6c1"), Color("#7f4972"), Color("#c6af51")
]
const BRIGHT_DARK:Array[Color] = [
	Color("#9c6023"),
	Color("#bbaea4"), Color("#9c6023"), Color("#603689"),
	Color("#6b0d0d"), Color("#1b5028"), Color("#3a4665"),
	Color("#af3a75"), Color("#357592"), Color("#181512"),
	Color("#382007"),
	Color("#bbaea4"),
	Color("#dc6e00"),
	Color("#3c4b50"),
	Color("#7a3117"), Color("#818181"),
	Color("#3b1f1f"), Color("#1d2b1d"), Color("#262633"),
	Color("#62b6c1"), Color("#7f4972"), Color("#c6af51")
]

@onready var editor:Editor = get_node("/root/editor")
var playGame:PlayGame
var world:World
var tiles:TileMapLayer
var objectsParent:Node2D
var particlesParent:Node2D

var level:Level = Level.new()
var anyChanges:bool = false:
	set(value):
		anyChanges = value
		updateWindowName()

var objectIdIter:int = 0 # for creating objects
var componentIdIter:int = 0 # for creating components
var goldIndex:int = 0 # youve seen this before
var goldIndexFloat:float = 0
signal goldIndexChanged

var objects:Dictionary[int,GameObject] = {}
var components:Dictionary[int,GameComponent] = {}

var levelBounds:Rect2i = Rect2i(0,0,800,608):
	set(value):
		levelBounds = value
		RenderingServer.global_shader_parameter_set(&"LEVEL_SIZE", levelBounds.size)
		if editor:
			editor.playtestCamera.limit_left = levelBounds.position.x
			editor.playtestCamera.limit_top = levelBounds.position.y
			editor.playtestCamera.limit_right = levelBounds.end.x
			editor.playtestCamera.limit_bottom = levelBounds.end.y

const NO_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/noMaterial.tres")
const GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/materials/glitchDrawMaterial.tres") # uses texture pixel size
const UNSCALED_GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/materials/unscaledGlitchDrawMaterial.tres") # per pixel
const SCALED_GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/materials/scaledGlitchDrawMaterial.tres") # uses size input
const PIXELATED_MATERIAL:ShaderMaterial = preload("res://resources/materials/pixelatedDrawMaterial.tres")
const ADDITIVE_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/additiveMaterial.tres")
const SUBTRACTIVE_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/subtractiveMaterial.tres")
const NEGATIVE_MATERIAL:ShaderMaterial = preload("res://resources/materials/negativeMaterial.tres")
const TEXT_GRADIENT_MATERIAL:ShaderMaterial = preload("res://resources/materials/textGradientMaterial.tres")

const FKEYX:Font = preload("res://resources/fonts/fKeyX.fnt")
const FKEYNUM:Font = preload("res://resources/fonts/fKeyNum.fnt")
const FTALK:Font = preload("res://resources/fonts/fTalk.fnt")
const FLEVELID:Font = preload("res://resources/fonts/fLevelID.fnt")
const FLEVELNAME:Font = preload("res://resources/fonts/fLevelName.fnt")
const FROOMNUM:Font = preload("res://resources/fonts/fRoomNum.fnt")
const FMINIID:Font = preload("res://resources/fonts/fMiniId.fnt")

var latestSpawn:PlayerSpawn
var levelStart:PlayerSpawn
var player:Player
enum PLAY_STATE {EDIT, PLAY, PAUSED}
var playState:PLAY_STATE = PLAY_STATE.EDIT:
	set(value):
		playState = value
		if editor:
			editor.topBar._updateButtons()
			editor.editorCamera.enabled = playState != PLAY_STATE.PLAY
			editor.playtestCamera.enabled = playState == PLAY_STATE.PLAY
			editor.updateDescription()
		fastAnimSpeed = 0
		fastAnimTimer = 0
		complexViewHue = 0

var fastAnimSpeed:float = 0 # 0: slowest, 1: fastest
var fastAnimTimer:float = 0 # speed resets when this counts down to 0

var complexViewHue:float = 0

var editorWindowSize:Vector2
var editorWindowMode:Window.Mode

var awaitingEditor:bool = false

var simpleLocks:bool = false:
	set(value):
		simpleLocks = value
		for component in components.values():
			if component is Lock: component.queue_redraw()
var hideTimer:bool = false:
	set(value):
		hideTimer = value
		updateWindowName()
var playTime:float
var autoRun:bool = true
var fullJumps:bool = false
var fastAnimations:bool = false

var won:bool = false

func setWorld(_world:World) -> void:
	world = _world
	tiles = world.tiles
	objectsParent = world.objectsParent
	particlesParent = world.particlesParent
	updateWindowName()

func _process(delta:float) -> void:
	goldIndexFloat += delta*6 # 0.1 per frame, 60fps
	if goldIndexFloat > 12: goldIndexFloat -= 12
	if goldIndex != int(goldIndexFloat):
		goldIndex = int(goldIndexFloat)
		goldIndexChanged.emit()
	RenderingServer.global_shader_parameter_set(&"NOISE_OFFSET", Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000)))
	if editor and player: editor.playtestCamera.position = player.position
	# fast anims
	if fastAnimTimer > 0:
		fastAnimTimer -= delta
		# counted down; reset
		if fastAnimTimer <= 0 or !fastAnimations:
			fastAnimTimer = 0
			fastAnimSpeed = 0
	complexViewHue += delta*0.1764705882 # 0.75/255 per frame, 60fps
	if complexViewHue >= 1: complexViewHue -= 1
	if playGame and !hideTimer: updateWindowName()

func updateWindowName() -> void:
	if editor:
		if anyChanges: get_window().title = level.name + "*" + " - IWLCEditor"
		else: get_window().title = level.name + " - IWLCEditor"
	else:
		if hideTimer: get_window().title = "IWLCEditor"
		else: get_window().title = "IWLCEditor - Time: " + formatTime(playTime)

func fasterAnims() -> void:
	if !fastAnimations: return
	fastAnimTimer = 1.6666666667 # 100 frames, 60fps
	fastAnimSpeed = min(fastAnimSpeed+0.05, 1)

func playTest(spawn:PlayerSpawn) -> void:
	var starting:bool = false
	if playState == PLAY_STATE.EDIT:
		starting = true
		player = preload("res://scenes/player.tscn").instantiate()
		world.add_child(player)
		player.position = spawn.position + Vector2(16, 23)
	playState = PLAY_STATE.PLAY
	latestSpawn = spawn

	goldIndexFloat = 0

	editor.multiselect.deselect()
	editor.focusDialog.defocusComponent()
	editor.focusDialog.defocus()
	editor.componentDragged = null
	Changes.bufferSave()

	if starting: GameChanges.start()
	for object in objects.values():
		if starting: object.start()
		object.queue_redraw()
	for component in components.values():
		if starting: component.start()
		component.queue_redraw()

func pauseTest() -> void:
	playState = PLAY_STATE.PAUSED
	for object in objects.values(): object.queue_redraw()
	for component in components.values(): component.queue_redraw()

func stopTest() -> void:
	playState = PLAY_STATE.EDIT
	GameChanges.saveBuffered = false
	player.pauseFrame = true
	won = false
	await get_tree().process_frame
	player.queue_free()
	for object in objects.values():
		object.stop()
		object.queue_redraw()
	for component in components.values():
		component.stop()
		component.queue_redraw()

func restart() -> void:
	if editor:
		stopTest()
		await get_tree().process_frame # to be safe
		if editor: playTest(latestSpawn)
	else: playGame.restart()

func setGlitch(color:COLOR) -> void:
	for object in objects.values():
		if object.get_script() in [KeyBulk, Door, RemoteLock]:
			object.setGlitch(color)

func play() -> void:
	if !levelStart: return Saving.loadError("No level start found,\nCannot play level.", "Play Error")
	Saving.confirmAction = Saving.ACTION.SAVE_FOR_PLAY
	Saving.save()
	playTime = 0

func playSaved() -> void:
	editorWindowMode = get_window().mode
	editorWindowSize = get_window().size
	get_tree().change_scene_to_file("res://scenes/playGame.tscn")
	get_window().mode = Window.MODE_WINDOWED
	if !OS.has_feature("web"): get_window().size = Vector2(800,608)
	objects.clear()
	components.clear()

func playReadied() -> void:
	setWorld(playGame.world)
	Saving.loadFile(Saving.savePath)
	playState = PLAY_STATE.PLAY
	playGame.loadSettings()
	playGame.startLevel()

func edit() -> void:
	won = false
	awaitingEditor = true
	playState = PLAY_STATE.EDIT
	get_tree().change_scene_to_file("res://scenes/editor.tscn")
	get_window().mode = editorWindowMode
	if !OS.has_feature("web"): get_window().size = editorWindowSize
	objects.clear()
	components.clear()

func editReadied() -> void:
	editor = get_node("/root/editor")
	Changes.editor = editor
	Mods.editor = editor
	Saving.editor = editor
	Explainer.editor = editor
	Saving.loadFile(Saving.savePath)
	await get_tree().process_frame
	editor.home()

func formatTime(seconds:float) -> String:
	var hours:int = int(seconds/3600)
	seconds -= hours*3600
	var minutes:int = int(seconds/60)
	seconds -= minutes*60
	var string:String = ""
	if hours: string += str(hours) + "h "
	if minutes: string += str(minutes) + "m "
	if seconds: string += str(int(seconds)) + "s "
	return string.trim_suffix(" ")

func win(goal:Goal) -> void:
	won = true
	goal.win()
	if goal.type == Goal.TYPE.OMEGA:
		AudioManager.play(preload("res://resources/sounds/goal/deltaruneShine.wav"), 1.2, 0.8)
		AudioManager.play(preload("res://resources/sounds/goal/winOmega.wav"))
	else: AudioManager.play(preload("res://resources/sounds/goal/win.wav"), 0.9, 1.4)
	if editor:
		await timer(0.5)
		stopTest()
		editor.cameraZoom = 1
		editor.editorCamera.zoom = Vector2.ONE
		editor.home()
	else:
		playGame.win(goal)

func timer(time:float) -> Signal:
	var t = Timer.new()
	t.one_shot = true
	get_tree().get_root().add_child(t)
	t.timeout.connect(t.queue_free)
	t.start(time)
	return t.timeout
