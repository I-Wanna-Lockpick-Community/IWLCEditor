extends PanelContainer
class_name PlayGame

const SCREEN_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(800,608))
const DESCRIPTION_BOX:Texture2D = preload("res://assets/game/gameUI/description.png")

const TEXT_BREAK_FLAGS:int = TextServer.LineBreakFlag.BREAK_MANDATORY|TextServer.LineBreakFlag.BREAK_WORD_BOUND|TextServer.LineBreakFlag.BREAK_ADAPTIVE

@onready var world:World = %world
@onready var gameViewport:SubViewport = %gameViewport

var configFile:ConfigFile = ConfigFile.new()

var paused:bool = false

var mainDraw:RID

var roomTransitionPhase:int = -1
var roomTransitionTimer:float = 0
var roomTransitionColor:Color = Color("#5a96c8")
var textWiggleAngle:float = 0
var textOffsetAngle:float = 0
var pauseAnimPhase:int = -1
var pauseAnimTimer:float = 0

func _ready() -> void:
	mainDraw = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(mainDraw, %worldViewportCont.get_canvas_item())
	Game.playGame = self
	Game.playReadied()

func _process(delta:float) -> void:
	textWiggleAngle += 5.8643062867*delta # 5.6 degrees per frame, 60fps
	textWiggleAngle = fmod(textWiggleAngle,TAU)
	if roomTransitionPhase != -1:
		roomTransitionTimer += delta
		match roomTransitionPhase:
			0:
				roomTransitionColor.a = 1
				textOffsetAngle = deg_to_rad(min(roomTransitionTimer*60,40)*2.25)
				queue_redraw()
				if roomTransitionTimer >= 2.5:
					roomTransitionTimer = 0
					roomTransitionPhase += 1
			1:
				roomTransitionColor.a = 1 - roomTransitionTimer/0.5833333333
				textOffsetAngle = deg_to_rad(90+roomTransitionTimer*154.2857142857)
				queue_redraw()
				if roomTransitionTimer >= 0.4166666667:
					roomTransitionPhase = -1
	if pauseAnimPhase != -1:
		pauseAnimTimer += delta
		%gameViewportCont.get_material().set_shader_parameter(&"pauseAnimTimer", pauseAnimTimer)
		queue_redraw()
		match pauseAnimPhase:
			0:
				if pauseAnimTimer >= 0.4166666667:
					pauseAnimPhase += 1
					paused = !paused
					%pauseMenu.visible = paused
					%gameViewportCont.get_material().set_shader_parameter(&"darken", !paused)
			1:
				if pauseAnimTimer >= 0.75:
					pauseAnimPhase = -1
					%mouseBlocker.mouse_filter = MOUSE_FILTER_IGNORE
					%gameViewportCont.get_material().set_shader_parameter(&"pauseAnimTimer", 0)
					%gameViewportCont.get_material().set_shader_parameter(&"darken", false)
	if !paused: Game.timer += delta

func _draw() -> void:
	RenderingServer.canvas_item_clear(mainDraw)
	# description box
	if Game.level.description:
		RenderingServer.canvas_item_add_texture_rect(mainDraw,Rect2(Vector2(11,519),Vector2(784,80)),DESCRIPTION_BOX,false,Color(Color.BLACK,0.35))
		RenderingServer.canvas_item_add_texture_rect(mainDraw,Rect2(Vector2(8,516),Vector2(784,80)),DESCRIPTION_BOX)
		Game.FTALK.draw_multiline_string(mainDraw,Vector2(16,540),Game.level.description,HORIZONTAL_ALIGNMENT_LEFT,666,12,4,Color("#200020"),TEXT_BREAK_FLAGS)
		TextDraw.outlinedCentered(Game.FROOMNUM,mainDraw,"PUZZLE",Color("#d6cfc9"),Color("#3e2d1c"),20,Vector2(732,539))
		TextDraw.outlinedCentered(Game.FROOMNUM,mainDraw,Game.level.shortNumber,Color("#8c50c8"),Color("#140064"),20,Vector2(733,569))
	# room transition
	if roomTransitionPhase != -1:
		var textOffset = Vector2(0,500*sin(textOffsetAngle)-500)
		var textWiggle:Vector2 = Vector2(sin(textWiggleAngle),cos(textWiggleAngle))*3
		var textWiggle2:Vector2 = Vector2(sin(textWiggleAngle+0.8726646260),cos(textWiggleAngle+0.8726646260))*6
		RenderingServer.canvas_item_add_rect(mainDraw,SCREEN_RECT,roomTransitionColor)
		TextDraw.outlinedCentered2(Game.FLEVELID,mainDraw,Game.level.number,Color.WHITE,Color.BLACK,24,Vector2(400,216)+textWiggle+textOffset)
		TextDraw.outlinedCentered2(Game.FLEVELNAME,mainDraw,Game.level.name,Color.WHITE,Color.BLACK,36,Vector2(400,280)+textWiggle2+textOffset)
		TextDraw.outlinedCentered2(Game.FLEVELNAME,mainDraw,Game.level.author,Color.BLACK,Color.WHITE,36,Vector2(400,376)+textWiggle+textOffset)

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if !event.is_echo():
			if event.keycode == KEY_F5: queue_redraw()
			if roomTransitionPhase == 0 and roomTransitionTimer >= 0.6666666667:
				if event.keycode == KEY_SPACE:
					roomTransitionPhase += 1
					roomTransitionTimer = 0
			if !inAnimation():
				if event.keycode == KEY_ESCAPE: pause()
		if !paused and !inAnimation(): Game.player.receiveKey(event)

func startLevel() -> void:
	start()
	roomTransitionPhase = 0
	roomTransitionTimer = 0

func start() -> void:
	Game.player = preload("res://scenes/player.tscn").instantiate()
	world.add_child(Game.player)
	assert(Game.levelStart)
	Game.player.position = Game.levelStart.position + Vector2(16, 23)
	Game.goldIndexFloat = 0
	GameChanges.start()
	for object in Game.objects.values():
		object.start()
		object.queue_redraw()
	for component in Game.components.values():
		component.start()
		component.queue_redraw()

func restart() -> void:
	Game.player.pauseFrame = true
	Game.player.queue_free()
	for object in Game.objects.values():
		object.stop()
		object.queue_redraw()
	for component in Game.components.values():
		component.stop()
		component.queue_redraw()
	await get_tree().process_frame
	start()

func inAnimation() -> bool:
	if roomTransitionPhase == 0: return true
	if roomTransitionPhase == 1 and roomTransitionTimer < 0.1: return true
	if pauseAnimPhase != -1: return true
	return false

func pause() -> void:
	if inAnimation(): return
	pauseAnimPhase = 0
	pauseAnimTimer = 0
	%gameViewportCont.get_material().set_shader_parameter(&"darken", !paused)
	%mouseBlocker.mouse_filter = MOUSE_FILTER_STOP
	var pauseSound:AudioStreamPlayer = AudioManager.play(preload("res://resources/sounds/pause.wav"))
	pauseSound.volume_linear = 0.85
	pauseSound.pitch_scale = 0.6
	if paused:
		%gameSettings.closed(configFile)
		configFile.save("user://config.ini")
	else:
		configFile.load("user://config.ini")
		%gameSettings.opened(configFile)

func quit() -> void:
	%gameSettings.closed(configFile)
	configFile.save("user://config.ini")
	get_tree().quit()

func editLevel() -> void:
	%gameSettings.closed(configFile)
	configFile.save("user://config.ini")
	await get_tree().process_frame
	Game.edit()

func updateSettings() -> void:
	configFile.load("user://config.ini")
	%gameSettings.playGame = self
	%gameSettings.opened(configFile)
