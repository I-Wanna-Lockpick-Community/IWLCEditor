extends MarginContainer
class_name GameSettings

const MAX_VOLUME:float = db_to_linear(-7)

var editor:Editor
var playGame:PlayGame

@export var toneButtonGroup:ButtonGroup
var selectedTone:Array[Color] = Game.highTone
var selectedColor:Color

var keyDrawMain:RID
var doorDrawScaled:RID
var doorDrawAuraBreaker:RID
var doorDrawMain:RID

func _ready() -> void:
	keyDrawMain = RenderingServer.canvas_item_create()
	doorDrawScaled = RenderingServer.canvas_item_create()
	doorDrawAuraBreaker = RenderingServer.canvas_item_create()
	doorDrawMain = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(keyDrawMain, %keyPreview.get_canvas_item())
	RenderingServer.canvas_item_set_parent(doorDrawScaled, %doorPreview.get_canvas_item())
	RenderingServer.canvas_item_set_parent(doorDrawAuraBreaker, %doorPreview.get_canvas_item())
	RenderingServer.canvas_item_set_parent(doorDrawMain, %doorPreview.get_canvas_item())
	toneButtonGroup.pressed.connect(_toneSelected)
	%presets.get_popup().id_pressed.connect(_setPreset)
	%colorSelector.onlyFlatColors()
	_colorSelected(Game.COLOR.WHITE)

func opened(configFile:ConfigFile) -> void:
	%volume.value = configFile.get_value("game", "volume", 0.5)
	%fullscreen.button_pressed = configFile.get_value("game", "fullscreen", false)
	%smoothingMode.button_pressed = configFile.get_value("game", "smoothingMode", false)
	%simpleLocks.button_pressed = configFile.get_value("game", "simpleLocks", false)
	for color in Game.COLORS:
		if color in Game.NONFLAT_COLORS: continue
		Game.highTone[color] = configFile.get_value("game", "highTone"+str(color), Game.DEFAULT_HIGH[color])
		Game.mainTone[color] = configFile.get_value("game", "mainTone"+str(color), Game.DEFAULT_MAIN[color])
		Game.darkTone[color] = configFile.get_value("game", "darkTone"+str(color), Game.DEFAULT_DARK[color])
	updateLabels()
	%hideTimer.button_pressed = configFile.get_value("game", "hideTimer", false)
	%autoRun.button_pressed = configFile.get_value("game", "autoRun", true)
	%fullJumps.button_pressed = configFile.get_value("game", "fullJumps", false)
	%fastAnimations.button_pressed = configFile.get_value("game", "fastAnimations", false)

func closed(configFile:ConfigFile) -> void:
	configFile.set_value("game", "volume", %volume.value)
	configFile.set_value("game", "fullscreen", %fullscreen.button_pressed)
	configFile.set_value("game", "smoothingMode", %smoothingMode.button_pressed)
	configFile.set_value("game", "simpleLocks", %simpleLocks.button_pressed)
	for color in Game.COLORS:
		if color in Game.NONFLAT_COLORS: continue
		configFile.set_value("game", "highTone"+str(color), Game.highTone[color])
		configFile.set_value("game", "mainTone"+str(color), Game.mainTone[color])
		configFile.set_value("game", "darkTone"+str(color), Game.darkTone[color])
	configFile.set_value("game", "hideTimer", %hideTimer.button_pressed)
	configFile.set_value("game", "fullJumps", %fullJumps.button_pressed)
	configFile.set_value("game", "fastAnimations", %fastAnimations.button_pressed)

func _volumeSet(value:float) -> void:
	AudioServer.set_bus_volume_linear(AudioManager.masterBus, lerpf(0,MAX_VOLUME,value))

func _fullscreenSet(toggled_on:bool) -> void:
	if playGame: get_window().mode = Window.MODE_FULLSCREEN if toggled_on else Window.MODE_WINDOWED

func _smoothingModeSet(toggled_on:bool) -> void:
	if editor: editor.gameViewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR if toggled_on else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	if playGame: playGame.gameViewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR if toggled_on else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

func _simpleLocksSet(toggled_on:bool):
	Game.simpleLocks = toggled_on

func _toneSelected(button:Button) -> void:
	match button.text:
		"High": selectedTone = Game.highTone
		"Main": selectedTone = Game.mainTone
		"Dark": selectedTone = Game.darkTone
	updateLabels()

func _colorSelected(color:Game.COLOR) -> void:
	%colorEditLabel.text = "Editing '" + Game.COLOR.keys()[color].to_pascal_case() + "'"
	updateLabels()

func updateLabels() -> void:
	selectedColor = selectedTone[%colorSelector.selected]
	%redLabel.text = str(selectedColor.r8)
	%greenLabel.text = str(selectedColor.g8)
	%blueLabel.text = str(selectedColor.b8)
	%redSlider.value = selectedColor.r8
	%greenSlider.value = selectedColor.g8
	%blueSlider.value = selectedColor.b8
	%colorSelector.redrawButtons()
	queue_redraw()
	for object in Game.objects.values(): if object.get_script() in [KeyBulk, Door, RemoteLock]: object.queue_redraw()
	for component in Game.components.values(): if component.get_script() in [Lock, KeyCounterElement]: component.queue_redraw()
	
func _redSet(value:float) -> void:
	selectedTone[%colorSelector.selected].r8 = round(value)
	updateLabels()

func _greenSet(value:float) -> void:
	selectedTone[%colorSelector.selected].g8 = round(value)
	updateLabels()

func _blueSet(value:float) -> void:
	selectedTone[%colorSelector.selected].b8 = round(value)
	updateLabels()

func _setTonesToMain() -> void:
	Game.highTone[%colorSelector.selected] = Game.mainTone[%colorSelector.selected]
	Game.darkTone[%colorSelector.selected] = Game.mainTone[%colorSelector.selected]
	updateLabels()

func _setPreset(id:int) -> void:
	match id:
		0: # default
			Game.highTone.assign(Game.DEFAULT_HIGH)
			Game.mainTone.assign(Game.DEFAULT_MAIN)
			Game.darkTone.assign(Game.DEFAULT_DARK)
		1: # bright
			Game.highTone.assign(Game.BRIGHT_HIGH)
			Game.mainTone.assign(Game.BRIGHT_MAIN)
			Game.darkTone.assign(Game.BRIGHT_DARK)
	updateLabels()

func _draw() -> void:
	RenderingServer.canvas_item_clear(keyDrawMain)
	RenderingServer.canvas_item_clear(doorDrawScaled)
	RenderingServer.canvas_item_clear(doorDrawAuraBreaker)
	RenderingServer.canvas_item_clear(doorDrawMain)
	KeyBulk.drawKey(keyDrawMain,keyDrawMain,Vector2.ZERO,%colorSelector.selected)
	Door.drawDoor(doorDrawScaled,doorDrawAuraBreaker,doorDrawMain,doorDrawMain,Vector2(32,32),%colorSelector.selected,Game.COLOR.GLITCH,Door.TYPE.COMBO,1)

func _hideTimerSet(toggled_on:bool) -> void:
	Game.hideTimer = toggled_on

func _autoRunSet(toggled_on:bool) -> void:
	Game.autoRun = toggled_on

func _fullJumpsSet(toggled_on:bool) -> void:
	Game.fullJumps = toggled_on

func _fastAnimationsSet(toggled_on:bool) -> void:
	Game.fastAnimations = toggled_on
