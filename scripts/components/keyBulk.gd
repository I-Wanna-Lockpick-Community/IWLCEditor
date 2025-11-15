extends GameObject
class_name KeyBulk
const SCENE:PackedScene = preload("res://scenes/objects/keyBulk.tscn")

const TYPES:int = 9
enum TYPE {NORMAL, EXACT, STAR, UNSTAR, SIGNFLIP, POSROTOR, NEGROTOR, CURSE, UNCURSE}

const KEYTYPE_TEXTURE_OFFSETS:Array[int] = [0,1,2,3,0,0,0,4,5]

const MASTER:KeyColorTextures = preload("res://resources/textures/key/master.tres")
const PURE:KeyColorTextures = preload("res://resources/textures/key/pure.tres")
const STONE:KeyColorTextures = preload("res://resources/textures/key/stone.tres")
const QUICKSILVER:KeyColorTextures = preload("res://resources/textures/key/quicksilver.tres")
const DYNAMITE:KeyColorTextures = preload("res://resources/textures/key/dynamite.tres")
const ICE:KeyColorTextures = preload("res://resources/textures/key/ice.tres")
const MUD:KeyColorTextures = preload("res://resources/textures/key/mud.tres")
const GRAFFITI:KeyColorTextures = preload("res://resources/textures/key/graffiti.tres")

const FILL:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fill.png"),
	preload("res://assets/game/key/exact/fill.png"),
	preload("res://assets/game/key/star/fill.png"),
	preload("res://assets/game/key/unstar/fill.png"),
	preload("res://assets/game/key/curse/fill.png"),
	preload("res://assets/game/key/uncurse/fill.png")
]

const FRAME:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frame.png"),
	preload("res://assets/game/key/exact/frame.png"),
	preload("res://assets/game/key/star/frame.png"),
	preload("res://assets/game/key/unstar/frame.png"),
	preload("res://assets/game/key/curse/frame.png"),
	preload("res://assets/game/key/uncurse/frame.png")
]

const FILL_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/fillGlitch.png"),
	preload("res://assets/game/key/exact/fillGlitch.png"),
	preload("res://assets/game/key/star/fillGlitch.png"),
	preload("res://assets/game/key/unstar/fillGlitch.png"),
	preload("res://assets/game/key/curse/fillGlitch.png"),
	preload("res://assets/game/key/uncurse/fillGlitch.png")
]

const FRAME_GLITCH:Array[Texture2D] = [
	preload("res://assets/game/key/normal/frameGlitch.png"),
	preload("res://assets/game/key/exact/frameGlitch.png"),
	preload("res://assets/game/key/star/frameGlitch.png"),
	preload("res://assets/game/key/unstar/frameGlitch.png"),
	preload("res://assets/game/key/curse/frameGlitch.png"),
	preload("res://assets/game/key/uncurse/frameGlitch.png")
]

const CURSE_FILL_DARK:Texture2D = preload("res://assets/game/key/curse/fillDark.png")

const SIGNFLIP_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/signflip.png")
const POSROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/posrotor.png")
const NEGROTOR_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/negrotor.png")
const INFINITE_SYMBOL:Texture2D = preload("res://assets/game/key/symbols/infinite.png")

const FKEYBULK:Font = preload("res://resources/fonts/fKeyBulk.fnt")

const CREATE_PARAMETERS:Array[StringName] = [
	&"position"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"color", &"type", &"count", &"infinite"
]
static var ARRAYS:Dictionary[StringName,GDScript] = {}

var color:Game.COLOR = Game.COLOR.WHITE
var type:TYPE = TYPE.NORMAL
var count:C = C.ONE
var infinite:bool = false

var drawGlitch:RID
var drawMain:RID
var drawSymbol:RID
func _init() -> void: size = Vector2(32,32)

func _ready() -> void:
	drawGlitch = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawSymbol = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_material(drawGlitch,Game.GLITCH_MATERIAL.get_rid())
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawSymbol,get_canvas_item())
	Game.connect(&"goldIndexChanged",func():if color in Game.ANIMATED_COLORS: queue_redraw())

func outlineTex() -> Texture2D: return getOutlineTexture(color, type)

static func getOutlineTexture(keyColor:Game.COLOR, keyType:TYPE=TYPE.NORMAL) -> Texture2D:
	match keyType:
		KeyBulk.TYPE.EXACT:
			if keyColor == Game.COLOR.MASTER: return preload("res://assets/game/key/master/outlineMaskExact.png")
			else:  return preload("res://assets/game/key/exact/outlineMask.png")
		KeyBulk.TYPE.STAR: return preload("res://assets/game/key/star/outlineMask.png")
		KeyBulk.TYPE.UNSTAR: return preload("res://assets/game/key/unstar/outlineMask.png")
		KeyBulk.TYPE.CURSE: return preload("res://assets/game/key/curse/outlineMask.png")
		KeyBulk.TYPE.UNCURSE: return preload("res://assets/game/key/uncurse/outlineMask.png")
		_:
			match keyColor:
				Game.COLOR.MASTER:
					return preload("res://assets/game/key/master/outlineMask.png")
				Game.COLOR.DYNAMITE: return preload("res://assets/game/key/dynamite/outlineMask.png")
				Game.COLOR.QUICKSILVER: return preload("res://assets/game/key/quicksilver/outlineMask.png")
				_: return preload("res://assets/game/key/normal/outlineMask.png")

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawSymbol)
	if !active and Game.playState == Game.PLAY_STATE.PLAY: return
	var rect:Rect2 = Rect2(Vector2.ZERO, size)
	drawKey(drawGlitch,drawMain,Vector2.ZERO,color,type,glitchMimic)
	if animState == ANIM_STATE.FLASH: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,outlineTex(),false,Color(Color.WHITE,animAlpha))
	match type:
		KeyBulk.TYPE.NORMAL, KeyBulk.TYPE.EXACT:
			if !count.eq(1): TextDraw.outlined2(FKEYBULK,drawSymbol,str(count),keycountColor(),keycountOutlineColor(),14,Vector2(1,25))
		KeyBulk.TYPE.SIGNFLIP: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,SIGNFLIP_SYMBOL)
		KeyBulk.TYPE.POSROTOR: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,POSROTOR_SYMBOL)
		KeyBulk.TYPE.NEGROTOR: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,NEGROTOR_SYMBOL)
	if infinite: RenderingServer.canvas_item_add_texture_rect(drawSymbol,rect,INFINITE_SYMBOL)

func keycountColor() -> Color: return Color("#363029") if count.sign() < 0 else Color("#ebe3dd")
func keycountOutlineColor() -> Color: return Color("#d6cfc9") if count.sign() < 0 else Color("#363029")

static func getTextures(keyColor:Game.COLOR) -> KeyColorTextures:
	match keyColor:
		Game.COLOR.MASTER: return MASTER
		Game.COLOR.PURE: return PURE
		Game.COLOR.STONE: return STONE
		Game.COLOR.DYNAMITE: return DYNAMITE
		Game.COLOR.QUICKSILVER: return QUICKSILVER
		Game.COLOR.ICE: return ICE
		Game.COLOR.MUD: return MUD
		Game.COLOR.GRAFFITI: return GRAFFITI
	return null

static func drawKey(keyDrawGlitch:RID,keyDrawMain:RID,keyOffset:Vector2,keyColor:Game.COLOR,keyType:TYPE=TYPE.NORMAL,keyGlitchMimic:Game.COLOR=Game.COLOR.GLITCH) -> void:
	var textures:KeyColorTextures = getTextures(keyColor)
	var rect:Rect2 = Rect2(keyOffset, Vector2(32,32))
	if textures: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,textures.texture(keyType).current())
	elif keyColor == Game.COLOR.GLITCH:
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FRAME_GLITCH[KEYTYPE_TEXTURE_OFFSETS[keyType]])
		RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,FILL[KEYTYPE_TEXTURE_OFFSETS[keyType]],false,Game.mainTone[keyColor])
		if keyType == TYPE.CURSE: RenderingServer.canvas_item_add_texture_rect(keyDrawGlitch,rect,CURSE_FILL_DARK,false,Game.darkTone[keyColor])
		if keyGlitchMimic != Game.COLOR.GLITCH:
			var glitchTextures:KeyColorTextures = getTextures(keyGlitchMimic)
			if glitchTextures: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,glitchTextures.glitch.texture(keyType).current())
			else: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL_GLITCH[KEYTYPE_TEXTURE_OFFSETS[keyType]],false,Game.mainTone[keyGlitchMimic])
	else:
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FRAME[KEYTYPE_TEXTURE_OFFSETS[keyType]])
		RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,FILL[KEYTYPE_TEXTURE_OFFSETS[keyType]],false,Game.mainTone[keyColor])
		if keyType == TYPE.CURSE: RenderingServer.canvas_item_add_texture_rect(keyDrawMain,rect,CURSE_FILL_DARK,false,Game.darkTone[keyColor])

func propertyChangedInit(property:StringName) -> void:
	if property == &"type":
		if type not in [TYPE.NORMAL, TYPE.EXACT] and count.neq(1): Changes.addChange(Changes.PropertyChange.new(self,&"count",C.ONE))

# ==== PLAY ==== #
var glitchMimic:Game.COLOR = Game.COLOR.GLITCH

enum ANIM_STATE {IDLE, FLASH}
var animState:ANIM_STATE = ANIM_STATE.IDLE
var animAlpha:float = 0

func _process(delta:float) -> void:
	match animState:
		ANIM_STATE.IDLE: animAlpha = 0
		ANIM_STATE.FLASH:
			animAlpha -= delta*6
			if animAlpha <= 0: animState = ANIM_STATE.IDLE
			queue_redraw()

func stop() -> void:
	glitchMimic = Game.COLOR.GLITCH
	super()

func collect(player:Player) -> void:
	match type:
		TYPE.NORMAL: GameChanges.addChange(GameChanges.KeyChange.new(effectiveColor(), player.key[effectiveColor()].plus(count)))
		TYPE.EXACT: GameChanges.addChange(GameChanges.KeyChange.new(effectiveColor(), count))
		TYPE.SIGNFLIP: GameChanges.addChange(GameChanges.KeyChange.new(effectiveColor(), player.key[effectiveColor()].times(-1)))
		TYPE.POSROTOR: GameChanges.addChange(GameChanges.KeyChange.new(effectiveColor(), player.key[effectiveColor()].times(C.I)))
		TYPE.NEGROTOR: GameChanges.addChange(GameChanges.KeyChange.new(effectiveColor(), player.key[effectiveColor()].times(C.nI)))
		TYPE.STAR: GameChanges.addChange(GameChanges.StarChange.new(effectiveColor(), true))
		TYPE.UNSTAR: GameChanges.addChange(GameChanges.StarChange.new(effectiveColor(), false))
		TYPE.CURSE: GameChanges.addChange(GameChanges.CurseChange.new(effectiveColor(), true))
		TYPE.UNCURSE: GameChanges.addChange(GameChanges.CurseChange.new(effectiveColor(), false))
		
	if infinite: flashAnimation()
	else: GameChanges.addChange(GameChanges.PropertyChange.new(self, &"active", false))
	GameChanges.bufferSave()

	if color == Game.COLOR.MASTER: # not effectiveColor; doesnt trigger on glitch master
		AudioManager.play(preload("res://resources/sounds/key/master.wav"))
	else:
		match type:
			TYPE.SIGNFLIP, TYPE.POSROTOR, TYPE.NEGROTOR: AudioManager.play(preload("res://resources/sounds/key/signflip.wav"))
			TYPE.STAR: AudioManager.play(preload("res://resources/sounds/key/star.wav"))
			TYPE.UNSTAR: AudioManager.play(preload("res://resources/sounds/key/unstar.wav"))
			_:
				if count.sign() < 0: AudioManager.play(preload("res://resources/sounds/key/negative.wav"))
				else: AudioManager.play(preload("res://resources/sounds/key/normal.wav"))

func setGlitch(setColor:Game.COLOR) -> void:
	GameChanges.addChange(GameChanges.PropertyChange.new(self, &"glitchMimic", setColor))
	queue_redraw()

func flashAnimation() -> void:
	animState = ANIM_STATE.FLASH
	animAlpha = 1

func propertyGameChangedDo(property:StringName) -> void:
	if property == &"active":
		%interact.process_mode = PROCESS_MODE_INHERIT if active else PROCESS_MODE_DISABLED


func effectiveColor() -> Game.COLOR:
	if color == Game.COLOR.GLITCH: return glitchMimic
	return color
