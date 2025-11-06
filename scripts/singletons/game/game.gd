extends Node2D
class_name Game

const COLORS:int = 22
enum COLOR {MASTER, WHITE, ORANGE, PURPLE, RED, GREEN, BLUE, PINK, CYAN, BLACK, BROWN, PURE, GLITCH, STONE, DYNAMITE, QUICKSILVER, MAROON, FOREST, NAVY, ICE, MUD, GRAFFITI}

static func isAnimated(color:COLOR) -> bool: return color in [COLOR.MASTER, COLOR.PURE, COLOR.DYNAMITE, COLOR.QUICKSILVER]

const MASTER_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/master0.png"),
	preload("res://assets/game/colorTexture/master1.png"),
	preload("res://assets/game/colorTexture/master2.png"),
	preload("res://assets/game/colorTexture/master3.png")
]
func masterTex() -> Texture2D: return MASTER_TEXTURE[goldIndex%4]
const MASTER_KEY_TEXTURE:Array[Texture2D] = [ # move this to keybulk probably
	preload("res://assets/game/key/master/normal0.png"),
	preload("res://assets/game/key/master/normal1.png"),
	preload("res://assets/game/key/master/normal2.png"),
	preload("res://assets/game/key/master/normal3.png"),
	preload("res://assets/game/key/master/exact0.png"),
	preload("res://assets/game/key/master/exact1.png"),
	preload("res://assets/game/key/master/exact2.png"),
	preload("res://assets/game/key/master/exact3.png"),
	preload("res://assets/game/key/master/star0.png"),
	preload("res://assets/game/key/master/star1.png"),
	preload("res://assets/game/key/master/star2.png"),
	preload("res://assets/game/key/master/star3.png"),
	preload("res://assets/game/key/master/unstar0.png"),
	preload("res://assets/game/key/master/unstar1.png"),
	preload("res://assets/game/key/master/unstar2.png"),
	preload("res://assets/game/key/master/unstar3.png"),
]
func masterKeyTex(type:KeyBulk.TYPE) -> Texture2D: return MASTER_KEY_TEXTURE[goldIndex%4 + KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]*4]


const PURE_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/pure0.png"),
	preload("res://assets/game/colorTexture/pure1.png"),
	preload("res://assets/game/colorTexture/pure2.png"),
	preload("res://assets/game/colorTexture/pure3.png"),
]
func pureTex() -> Texture2D: return PURE_TEXTURE[goldIndex%4]
const PURE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/pure/normal0.png"),
	preload("res://assets/game/key/pure/normal1.png"),
	preload("res://assets/game/key/pure/normal2.png"),
	preload("res://assets/game/key/pure/normal3.png"),
	preload("res://assets/game/key/pure/exact0.png"),
	preload("res://assets/game/key/pure/exact1.png"),
	preload("res://assets/game/key/pure/exact2.png"),
	preload("res://assets/game/key/pure/exact3.png"),
	preload("res://assets/game/key/pure/star0.png"),
	preload("res://assets/game/key/pure/star1.png"),
	preload("res://assets/game/key/pure/star2.png"),
	preload("res://assets/game/key/pure/star3.png"),
	preload("res://assets/game/key/pure/unstar0.png"),
	preload("res://assets/game/key/pure/unstar1.png"),
	preload("res://assets/game/key/pure/unstar2.png"),
	preload("res://assets/game/key/pure/unstar3.png"),
]
func pureKeyTex(type:KeyBulk.TYPE) -> Texture2D: return PURE_KEY_TEXTURE[goldIndex%4 + KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]*4]


func stoneTex() -> Texture2D: return preload("res://assets/game/colorTexture/stone.png")
const STONE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/stone/normal.png"),
	preload("res://assets/game/key/stone/exact.png"),
	preload("res://assets/game/key/stone/star.png"),
	preload("res://assets/game/key/stone/unstar.png"),
]
func stoneKeyTex(type:KeyBulk.TYPE) -> Texture2D: return STONE_KEY_TEXTURE[KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]]


const DYNAMITE_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/dynamite0.png"),
	preload("res://assets/game/colorTexture/dynamite1.png"),
	preload("res://assets/game/colorTexture/dynamite2.png"),
	preload("res://assets/game/colorTexture/dynamite3.png"),
	preload("res://assets/game/colorTexture/dynamite4.png"),
	preload("res://assets/game/colorTexture/dynamite5.png"),
	preload("res://assets/game/colorTexture/dynamite6.png"),
	preload("res://assets/game/colorTexture/dynamite7.png"),
	preload("res://assets/game/colorTexture/dynamite8.png"),
	preload("res://assets/game/colorTexture/dynamite9.png"),
	preload("res://assets/game/colorTexture/dynamite10.png"),
	preload("res://assets/game/colorTexture/dynamite11.png")
]
func dynamiteTex() -> Texture2D: return DYNAMITE_TEXTURE[goldIndex]
const DYNAMITE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/dynamite/normal0.png"), preload("res://assets/game/key/dynamite/normal1.png"), preload("res://assets/game/key/dynamite/normal2.png"), preload("res://assets/game/key/dynamite/normal3.png"), preload("res://assets/game/key/dynamite/normal4.png"), preload("res://assets/game/key/dynamite/normal5.png"), preload("res://assets/game/key/dynamite/normal6.png"), preload("res://assets/game/key/dynamite/normal7.png"), preload("res://assets/game/key/dynamite/normal8.png"), preload("res://assets/game/key/dynamite/normal9.png"), preload("res://assets/game/key/dynamite/normal10.png"), preload("res://assets/game/key/dynamite/normal11.png"),
	preload("res://assets/game/key/dynamite/exact0.png"), preload("res://assets/game/key/dynamite/exact1.png"), preload("res://assets/game/key/dynamite/exact2.png"), preload("res://assets/game/key/dynamite/exact3.png"), preload("res://assets/game/key/dynamite/exact4.png"), preload("res://assets/game/key/dynamite/exact5.png"), preload("res://assets/game/key/dynamite/exact6.png"), preload("res://assets/game/key/dynamite/exact7.png"), preload("res://assets/game/key/dynamite/exact8.png"), preload("res://assets/game/key/dynamite/exact9.png"), preload("res://assets/game/key/dynamite/exact10.png"), preload("res://assets/game/key/dynamite/exact11.png"),
	preload("res://assets/game/key/dynamite/star0.png"), preload("res://assets/game/key/dynamite/star1.png"), preload("res://assets/game/key/dynamite/star2.png"), preload("res://assets/game/key/dynamite/star3.png"), preload("res://assets/game/key/dynamite/star4.png"), preload("res://assets/game/key/dynamite/star5.png"), preload("res://assets/game/key/dynamite/star6.png"), preload("res://assets/game/key/dynamite/star7.png"), preload("res://assets/game/key/dynamite/star8.png"), preload("res://assets/game/key/dynamite/star9.png"), preload("res://assets/game/key/dynamite/star10.png"), preload("res://assets/game/key/dynamite/star11.png"),
	preload("res://assets/game/key/dynamite/unstar0.png"), preload("res://assets/game/key/dynamite/unstar1.png"), preload("res://assets/game/key/dynamite/unstar2.png"), preload("res://assets/game/key/dynamite/unstar3.png"), preload("res://assets/game/key/dynamite/unstar4.png"), preload("res://assets/game/key/dynamite/unstar5.png"), preload("res://assets/game/key/dynamite/unstar6.png"), preload("res://assets/game/key/dynamite/unstar7.png"), preload("res://assets/game/key/dynamite/unstar8.png"), preload("res://assets/game/key/dynamite/unstar9.png"), preload("res://assets/game/key/dynamite/unstar10.png"), preload("res://assets/game/key/dynamite/unstar11.png")
]
func dynamiteKeyTex(type:KeyBulk.TYPE) -> Texture2D: return DYNAMITE_KEY_TEXTURE[goldIndex + KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]*12]


const QUICKSILVER_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/colorTexture/quicksilver0.png"),
	preload("res://assets/game/colorTexture/quicksilver1.png"),
	preload("res://assets/game/colorTexture/quicksilver2.png"),
	preload("res://assets/game/colorTexture/quicksilver3.png"),
]
func quicksilverTex() -> Texture2D: return QUICKSILVER_TEXTURE[goldIndex%4]
const QUICKSILVER_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/quicksilver/normal0.png"),
	preload("res://assets/game/key/quicksilver/normal1.png"),
	preload("res://assets/game/key/quicksilver/normal2.png"),
	preload("res://assets/game/key/quicksilver/normal3.png"),
	preload("res://assets/game/key/quicksilver/exact0.png"),
	preload("res://assets/game/key/quicksilver/exact1.png"),
	preload("res://assets/game/key/quicksilver/exact2.png"),
	preload("res://assets/game/key/quicksilver/exact3.png"),
	preload("res://assets/game/key/quicksilver/star0.png"),
	preload("res://assets/game/key/quicksilver/star1.png"),
	preload("res://assets/game/key/quicksilver/star2.png"),
	preload("res://assets/game/key/quicksilver/star3.png"),
	preload("res://assets/game/key/quicksilver/unstar0.png"),
	preload("res://assets/game/key/quicksilver/unstar1.png"),
	preload("res://assets/game/key/quicksilver/unstar2.png"),
	preload("res://assets/game/key/quicksilver/unstar3.png"),
]
func quicksilverKeyTex(type:KeyBulk.TYPE) -> Texture2D: return QUICKSILVER_KEY_TEXTURE[goldIndex%4+KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]*4]


const ICE_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/ice/normal.png"),
	preload("res://assets/game/key/ice/exact.png"),
	preload("res://assets/game/key/ice/star.png"),
	preload("res://assets/game/key/ice/unstar.png"),
]
func iceKeyTex(type:KeyBulk.TYPE) -> Texture2D: return ICE_KEY_TEXTURE[KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]]


const MUD_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/mud/normal.png"),
	preload("res://assets/game/key/mud/exact.png"),
	preload("res://assets/game/key/mud/star.png"),
	preload("res://assets/game/key/mud/unstar.png"),
]
func mudKeyTex(type:KeyBulk.TYPE) -> Texture2D: return MUD_KEY_TEXTURE[KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]]


const GRAFFITI_KEY_TEXTURE:Array[Texture2D] = [
	preload("res://assets/game/key/graffiti/normal.png"),
	preload("res://assets/game/key/graffiti/exact.png"),
	preload("res://assets/game/key/graffiti/star.png"),
	preload("res://assets/game/key/graffiti/unstar.png"),
]
func graffitiKeyTex(type:KeyBulk.TYPE) -> Texture2D: return GRAFFITI_KEY_TEXTURE[KeyBulk.KEYTYPE_TEXTURE_OFFSETS[type]]

const EMPTY:Texture2D = preload("res://assets/empty.png")
const FILLED:Texture2D = preload("res://assets/filled.png")



const highTone:Array[Color] = [
	Color("#e7bf98"),
	Color("#edeae7"),
	Color("#e7bf98"),
	Color("#bfa4db"),
	Color("#c83737"),
	Color("#70cf88"),
	Color("#8795b8"),
	Color("#e4afca"),
	Color("#8acaca"),
	Color("#554b40"),
	Color("#aa6015"),
	Color("#edeae7"),
	Color("#78be00"),
	Color("#96a0a5"),
	Color("#d18866"),
	Color("#ffffff"),
	Color("#6b2020"),
	Color("#1d5c2c"),
	Color("#20326b"),
	Color("#cce7ed"),
	Color("#945950"),
	Color("#91a35e")
]

const mainTone:Array[Color] = [
	Color("#d68f49"),
	Color("#d6cfc9"),
	Color("#d68f49"),
	Color("#8f5fc0"),
	Color("#8f1b1b"),
	Color("#359f50"),
	Color("#5f71a0"),
	Color("#cf709f"),
	Color("#50afaf"),
	Color("#363029"),
	Color("#704010"),
	Color("#d6cfc9"),
	Color("#b49600"),
	Color("#647378"),
	Color("#d34728"),
	Color("#b8b8b8"),
	Color("#461415"),
	Color("#163b21"),
	Color("#182552"),
	Color("#98d8ea"),
	Color("#744138"),
	Color("#71843e")
]

const darkTone:Array[Color] = [
	Color("#9c6023"),
	Color("#bbaea4"),
	Color("#9c6023"),
	Color("#603689"),
	Color("#480d0d"),
	Color("#1b5028"),
	Color("#3a4665"),
	Color("#af3a75"),
	Color("#357575"),
	Color("#181512"),
	Color("#382007"),
	Color("#bbaea4"),
	Color("#dc6e00"),
	Color("#3c4b50"),
	Color("#7a3117"),
	Color("#818181"),
	Color("#2e0c0c"),
	Color("#0a2b14"),
	Color("#101833"),
	Color("#5ebdcc"),
	Color("#562a25"),
	Color("#4e5c27")
]

@onready var editor:Editor = get_node("/root/editor")
@onready var tiles:TileMapLayer = %tiles
@onready var editorCamera:Camera2D = %editorCamera
@onready var playCamera:Camera2D = %playCamera
@onready var objectsParent:Node = %objectsParent

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
		editor.gameViewportCont.material.set_shader_material("gameSize",levelBounds.size)
		%playCamera.set_limit.left = levelBounds.position.x
		%playCamera.set_limit.top = levelBounds.position.y
		%playCamera.set_limit.right = levelBounds.end.x
		%playCamera.set_limit.bottom = levelBounds.end.y

const NO_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/noMaterial.tres")
const GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/materials/glitchDrawMaterial.tres") # uses texture pixel size
const UNSCALED_GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/materials/unscaledGlitchDrawMaterial.tres") # per pixel
const SCALED_GLITCH_MATERIAL:ShaderMaterial = preload("res://resources/materials/scaledGlitchDrawMaterial.tres") # uses size input
const PIXELATED_MATERIAL:ShaderMaterial = preload("res://resources/materials/pixelatedDrawMaterial.tres")
const ADDITIVE_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/additiveMaterial.tres")
const SUBTRACTIVE_MATERIAL:CanvasItemMaterial = preload("res://resources/materials/subtractiveMaterial.tres")
const NEGATIVE_MATERIAL:ShaderMaterial = preload("res://resources/materials/negativeMaterial.tres")

const FKEYX:Font = preload("res://resources/fonts/fKeyX.fnt")
const FKEYNUM:Font = preload("res://resources/fonts/fKeyNum.fnt")
const FTALK:Font = preload("res://resources/fonts/fTalk.fnt")

var latestSpawn:PlayerSpawn
var levelStart:PlayerSpawn
var player:Player
enum PLAY_STATE {EDIT, PLAY, PAUSED}
var playState:PLAY_STATE = PLAY_STATE.EDIT:
	set(value):
		playState = value
		editor.topBar._playStateChanged()
		%editorCamera.enabled = playState != PLAY_STATE.PLAY
		%playCamera.enabled = playState == PLAY_STATE.PLAY
		fastAnimSpeed = 0
		fastAnimTimer = 0
		complexViewHue = 0

var fastAnimSpeed:float = 0 # 0: slowest, 1: fastest
var fastAnimTimer:float = 0 # speed resets when this counts down to 0

var complexViewHue:float = 0

func _ready() -> void:
	gameChanges.game = self

func _process(delta:float) -> void:
	goldIndexFloat += delta*6 # 0.1 per frame, 60fps
	if goldIndexFloat > 12: goldIndexFloat -= 12
	if goldIndex != int(goldIndexFloat):
		goldIndex = int(goldIndexFloat)
		goldIndexChanged.emit()
	RenderingServer.global_shader_parameter_set(&"NOISE_OFFSET", Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000)))
	RenderingServer.global_shader_parameter_set(&"RCAMERA_ZOOM", 1/editor.cameraZoom)
	if player:
		%playCamera.position = player.position
	# fast anims
	if fastAnimTimer > 0:
		fastAnimTimer -= delta
		# counted down; reset
		if fastAnimTimer <= 0:
			fastAnimTimer = 0
			fastAnimSpeed = 0
	complexViewHue += delta*0.1764705882 # 0.75/255 per frame, 60fps
	if complexViewHue >= 1: complexViewHue -= 1

func fasterAnims() -> void:
	fastAnimTimer = 1.6666666667 # 100 frames, 60fps
	fastAnimSpeed = min(fastAnimSpeed+0.05, 1)

func playTest(spawn:PlayerSpawn) -> void:
	var starting:bool = false
	if playState == PLAY_STATE.EDIT:
		starting = true
		player = preload("res://scenes/player.tscn").instantiate()
		player.game = self
		add_child(player)
		player.position = spawn.position + Vector2(17, 23)
	playState = PLAY_STATE.PLAY
	latestSpawn = spawn

	goldIndexFloat = 0

	editor.multiselect.deselect()
	editor.focusDialog.defocusComponent()
	editor.focusDialog.defocus()
	editor.componentDragged = null
	changes.bufferSave()

	if starting: gameChanges.start()
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
	gameChanges.saveBuffered = false
	player.pauseFrame = true
	await get_tree().process_frame
	player.queue_free()
	player = null
	for object in objects.values():
		object.stop()
		object.queue_redraw()
	for component in components.values():
		component.stop()
		component.queue_redraw()

func restart() -> void:
	stopTest()
	await get_tree().process_frame # to be safe
	playTest(latestSpawn)

func setGlitch(color:COLOR) -> void:
	for object in objects.values():
		if object.get_script() in [KeyBulk, Door, RemoteLock]:
			object.setGlitch(color)
