extends GameComponent
class_name Lock

const TYPES:int = 5
enum TYPE {NORMAL, BLANK, BLAST, ALL, EXACT}
enum SIZE_TYPE {AnyS, AnyH, AnyV, AnyM, AnyL, AnyXL, ANY}
const SIZES:Array[Vector2] = [Vector2(18,18), Vector2(50,18), Vector2(18,50), Vector2(38,38), Vector2(50,50), Vector2(82,82)]
enum CONFIGURATION {spr1A, spr2H, spr2V, spr3H, spr3V, spr4A, spr4B, spr5A, spr5B, spr6A, spr6B, spr8A, spr12A, spr24A, spr7A, spr9A, spr9B, spr10A, spr11A, spr13A, spr24B, NONE}

func getAvailableConfigurations() -> Array[Array]: return availableConfigurations(effectiveCount(), type)

static func availableConfigurations(lockCount:C, lockType:TYPE) -> Array[Array]:
	# returns Array[Array[SIZE_TYPE, CONFIGURATION]]
	# SpecificA/H first, then SpecificB/V
	var available:Array[Array] = []
	if lockType != TYPE.NORMAL and lockType != TYPE.EXACT: return available
	if lockCount.isNonzeroReal():
		if lockCount.r.abs().eq(1): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif lockCount.r.abs().eq(2): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif lockCount.r.abs().eq(3): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
		elif lockCount.r.abs().eq(4): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr4A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr4B])
		elif lockCount.r.abs().eq(5): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr5A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr5B])
		elif lockCount.r.abs().eq(6): available.append([SIZE_TYPE.AnyM, CONFIGURATION.spr6A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr6B])
		elif lockCount.r.abs().eq(8): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr8A])
		elif lockCount.r.abs().eq(12): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr12A])
		elif lockCount.r.abs().eq(24):
			available.append([SIZE_TYPE.AnyXL, CONFIGURATION.spr24A])
			if mods.active("MoreLockConfigs"): available.append([SIZE_TYPE.AnyXL, CONFIGURATION.spr24B])
		elif mods.active("MoreLockConfigs"):
			if lockCount.r.abs().eq(7): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr7A])
			elif lockCount.r.abs().eq(9): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr9A]); available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr9B])
			elif lockCount.r.abs().eq(10): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr10A])
			elif lockCount.r.abs().eq(11): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr11A])
			elif lockCount.r.abs().eq(13): available.append([SIZE_TYPE.AnyL, CONFIGURATION.spr13A])
	elif lockCount.isNonzeroImag():
		if lockCount.i.abs().eq(1): available.append([SIZE_TYPE.AnyS, CONFIGURATION.spr1A])
		elif lockCount.i.abs().eq(2): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr2H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr2V])
		elif lockCount.i.abs().eq(3): available.append([SIZE_TYPE.AnyH, CONFIGURATION.spr3H]); available.append([SIZE_TYPE.AnyV, CONFIGURATION.spr3V])
	return available

const ANY_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(50,50)) # rect of ANY
const CORNER_SIZE:Vector2 = Vector2(2,2) # size of ANY's corners
const GLITCH_ANY_RECT:Rect2 = Rect2(Vector2.ZERO,Vector2(82,82))
const GLITCH_CORNER_SIZE:Vector2 = Vector2(9,9)
const TILE:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_TILE # just to save characters
const STRETCH:RenderingServer.NinePatchAxisMode = RenderingServer.NinePatchAxisMode.NINE_PATCH_STRETCH # just to save characters

const PREDEFINED_SPRITE_NORMAL:Array[Texture2D] = [
	preload("res://assets/game/lock/predefined/1Anormal.png"), preload("res://assets/game/lock/predefined/1Aexact.png"),
	preload("res://assets/game/lock/predefined/2Hnormal.png"), preload("res://assets/game/lock/predefined/2Hexact.png"),
	preload("res://assets/game/lock/predefined/2Vnormal.png"), preload("res://assets/game/lock/predefined/2Vexact.png"),
	preload("res://assets/game/lock/predefined/3Hnormal.png"), preload("res://assets/game/lock/predefined/3Hexact.png"),
	preload("res://assets/game/lock/predefined/3Vnormal.png"), preload("res://assets/game/lock/predefined/3Vexact.png"),
	preload("res://assets/game/lock/predefined/4Anormal.png"), preload("res://assets/game/lock/predefined/4Aexact.png"),
	preload("res://assets/game/lock/predefined/4Bnormal.png"), preload("res://assets/game/lock/predefined/4Bexact.png"),
	preload("res://assets/game/lock/predefined/5Anormal.png"), preload("res://assets/game/lock/predefined/5Aexact.png"),
	preload("res://assets/game/lock/predefined/5Bnormal.png"), preload("res://assets/game/lock/predefined/5Bexact.png"),
	preload("res://assets/game/lock/predefined/6Anormal.png"), preload("res://assets/game/lock/predefined/6Aexact.png"),
	preload("res://assets/game/lock/predefined/6Bnormal.png"), preload("res://assets/game/lock/predefined/6Bexact.png"),
	preload("res://assets/game/lock/predefined/8Anormal.png"), preload("res://assets/game/lock/predefined/8Aexact.png"),
	preload("res://assets/game/lock/predefined/12Anormal.png"), preload("res://assets/game/lock/predefined/12Aexact.png"),
	preload("res://assets/game/lock/predefined/24Anormal.png"), preload("res://assets/game/lock/predefined/24Aexact.png"),
	# MoreLockConfigs
	preload("res://assets/game/lock/predefined/7Anormal.png"), preload("res://assets/game/lock/predefined/7Aexact.png"),
	preload("res://assets/game/lock/predefined/9Anormal.png"), preload("res://assets/game/lock/predefined/9Aexact.png"),
	preload("res://assets/game/lock/predefined/9Bnormal.png"), preload("res://assets/game/lock/predefined/9Bexact.png"),
	preload("res://assets/game/lock/predefined/10Anormal.png"), preload("res://assets/game/lock/predefined/10Aexact.png"),
	preload("res://assets/game/lock/predefined/11Anormal.png"), preload("res://assets/game/lock/predefined/11Aexact.png"),
	preload("res://assets/game/lock/predefined/13Anormal.png"), preload("res://assets/game/lock/predefined/13Aexact.png"),
	preload("res://assets/game/lock/predefined/24Bnormal.png"), preload("res://assets/game/lock/predefined/24Bexact.png"),
]
const PREDEFINED_SPRITE_IMAGINARY:Array[Texture2D] = [
	preload("res://assets/game/lock/predefined/1Aimaginary.png"), preload("res://assets/game/lock/predefined/1Aexacti.png"),
	preload("res://assets/game/lock/predefined/2Himaginary.png"), preload("res://assets/game/lock/predefined/2Hexacti.png"),
	preload("res://assets/game/lock/predefined/2Vimaginary.png"), preload("res://assets/game/lock/predefined/2Vexacti.png"),
	preload("res://assets/game/lock/predefined/3Himaginary.png"), preload("res://assets/game/lock/predefined/3Hexacti.png"),
	preload("res://assets/game/lock/predefined/3Vimaginary.png"), preload("res://assets/game/lock/predefined/3Vexacti.png"),
]
static func getPredefinedLockSprite(lockCount:C, lockType:TYPE, lockConfiguration:CONFIGURATION) -> Texture2D:
	if lockCount.isNonzeroImag(): return PREDEFINED_SPRITE_IMAGINARY[lockConfiguration*2+int(lockType==TYPE.EXACT)]
	else: return PREDEFINED_SPRITE_NORMAL[lockConfiguration*2+int(lockType==TYPE.EXACT)]

const FRAME_HIGH:Texture2D = preload("res://assets/game/lock/frame/high.png")
const FRAME_MAIN:Texture2D = preload("res://assets/game/lock/frame/main.png")
const FRAME_DARK:Texture2D = preload("res://assets/game/lock/frame/dark.png")

static func getFrameHighColor(_isNegative:bool, _negated:bool) -> Color:
	if _isNegative: return Color("#14202c") if _negated else Color("#ebdfd3")
	else: return Color("#7b9fc3") if _negated else Color("#84603c")

static func getFrameMainColor(_isNegative:bool, _negated:bool) -> Color:
	if _isNegative: return Color("#274058") if _negated else Color("#d8bfa7")
	else: return Color("#a7bfd8") if _negated else Color("#584027")

static func getFrameDarkColor(_isNegative:bool, _negated:bool) -> Color:
	if _isNegative: return Color("#3b6084") if _negated else Color("#c49f7b")
	else: return Color("#d3dfeb") if _negated else Color("#42301d")

const SYMBOL_NORMAL = preload("res://assets/game/lock/symbols/normal.png")
const SYMBOL_BLAST = preload("res://assets/game/lock/symbols/blast.png")
const SYMBOL_BLASTI = preload("res://assets/game/lock/symbols/blasti.png")
const SYMBOL_EXACT = preload("res://assets/game/lock/symbols/exact.png")
const SYMBOL_EXACTI = preload("res://assets/game/lock/symbols/exacti.png")
const SYMBOL_ALL = preload("res://assets/game/lock/symbols/all.png")
const SYMBOL_SIZE:Vector2 = Vector2(32,32)

const GLITCH_FILL:Array[Texture2D] = [
	preload("res://assets/game/lock/fill/AnySglitch.png"),
	preload("res://assets/game/lock/fill/AnyHglitch.png"),
	preload("res://assets/game/lock/fill/AnyVglitch.png"),
	preload("res://assets/game/lock/fill/AnyMglitch.png"),
	preload("res://assets/game/lock/fill/AnyLglitch.png"),
	preload("res://assets/game/lock/fill/AnyXLglitch.png"),
	preload("res://assets/game/lock/fill/ANYglitch.png")
]

const GLITCH_FILL_MASTER:Array[Texture2D] = [
	preload("res://assets/game/lock/fill/AnySglitchMaster.png"),
	preload("res://assets/game/lock/fill/AnyHglitchMaster.png"),
	preload("res://assets/game/lock/fill/AnyVglitchMaster.png"),
	preload("res://assets/game/lock/fill/AnyMglitchMaster.png"),
	preload("res://assets/game/lock/fill/AnyLglitchMaster.png"),
	preload("res://assets/game/lock/fill/AnyXLglitchMaster.png"),
	preload("res://assets/game/lock/fill/ANYglitchMaster.png")
]
const GLITCH_FILL_PURE:Array[Texture2D] = [
	preload("res://assets/game/lock/fill/AnySglitchPure.png"),
	preload("res://assets/game/lock/fill/AnyHglitchPure.png"),
	preload("res://assets/game/lock/fill/AnyVglitchPure.png"),
	preload("res://assets/game/lock/fill/AnyMglitchPure.png"),
	preload("res://assets/game/lock/fill/AnyLglitchPure.png"),
	preload("res://assets/game/lock/fill/AnyXLglitchPure.png"),
	preload("res://assets/game/lock/fill/ANYglitchPure.png")
]
const GLITCH_FILL_STONE:Array[Texture2D] = [
	preload("res://assets/game/lock/fill/AnySglitchStone.png"),
	preload("res://assets/game/lock/fill/AnyHglitchStone.png"),
	preload("res://assets/game/lock/fill/AnyVglitchStone.png"),
	preload("res://assets/game/lock/fill/AnyMglitchStone.png"),
	preload("res://assets/game/lock/fill/AnyLglitchStone.png"),
	preload("res://assets/game/lock/fill/AnyXLglitchStone.png"),
	preload("res://assets/game/lock/fill/ANYglitchStone.png")
]
const GLITCH_FILL_DYNAMITE:Array[Texture2D] = [
	preload("res://assets/game/lock/fill/AnySglitchDynamite.png"),
	preload("res://assets/game/lock/fill/AnyHglitchDynamite.png"),
	preload("res://assets/game/lock/fill/AnyVglitchDynamite.png"),
	preload("res://assets/game/lock/fill/AnyMglitchDynamite.png"),
	preload("res://assets/game/lock/fill/AnyLglitchDynamite.png"),
	preload("res://assets/game/lock/fill/AnyXLglitchDynamite.png"),
	preload("res://assets/game/lock/fill/ANYglitchDynamite.png")
]
const GLITCH_FILL_QUICKSILVER:Array[Texture2D] = [
	preload("res://assets/game/lock/fill/AnySglitchQuicksilver.png"),
	preload("res://assets/game/lock/fill/AnyHglitchQuicksilver.png"),
	preload("res://assets/game/lock/fill/AnyVglitchQuicksilver.png"),
	preload("res://assets/game/lock/fill/AnyMglitchQuicksilver.png"),
	preload("res://assets/game/lock/fill/AnyLglitchQuicksilver.png"),
	preload("res://assets/game/lock/fill/AnyXLglitchQuicksilver.png"),
	preload("res://assets/game/lock/fill/ANYglitchQuicksilver.png")
]

static func offsetFromType(getSizeType:SIZE_TYPE) -> Vector2:
	match getSizeType:
		SIZE_TYPE.AnyM: return Vector2(3, 3)
		_: return Vector2(-7, -7)

func getOffset() -> Vector2: return offsetFromType(sizeType)

const CREATE_PARAMETERS:Array[StringName] = [
	&"position", &"parentId"
]
const PROPERTIES:Array[StringName] = [
	&"id", &"position", &"size",
	&"parentId", &"color", &"type", &"configuration", &"sizeType", &"count", &"isPartial", &"denominator", &"negated",
	&"index" # implcit
]
static var ARRAYS:Dictionary[StringName,GDScript] = {}

var parent:Door
var parentId:int
var color:Game.COLOR = Game.COLOR.WHITE
var type:TYPE = TYPE.NORMAL
var configuration:CONFIGURATION = CONFIGURATION.spr1A
var sizeType:SIZE_TYPE = SIZE_TYPE.AnyS
var count:C = C.ONE
var isPartial:bool = false # for partial blast
var denominator:C = C.ONE # for partial blast
var negated:bool = false
var index:int

var drawGlitch:RID
var drawScaled:RID
var drawMain:RID
var drawConfiguration:RID

static func getConfigurationColor(_isNegative:bool) -> Color:
	if _isNegative: return Color("#ebdfd3")
	else: return Color("#2c2014")

func _init(_parent:Door, _index:int) -> void:
	parent = _parent
	index = _index
	size = Vector2(18,18)

func _ready() -> void:
	drawGlitch = RenderingServer.canvas_item_create()
	drawScaled = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawConfiguration = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawScaled,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawConfiguration,get_canvas_item())
	game.connect(&"goldIndexChanged",queue_redraw)

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawGlitch)
	RenderingServer.canvas_item_clear(drawScaled)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawConfiguration)
	if !parent.active and game.playState == Game.PLAY_STATE.PLAY: return
	drawLock(game,drawGlitch,drawScaled,drawMain,drawConfiguration,
		size,colorAfterCurse(),colorAfterGlitch(),type,effectiveConfiguration(),sizeType,effectiveCount(),isPartial,denominator,negated,
		getFrameHighColor(isNegative(), negated),
		getFrameMainColor(isNegative(), negated),
		getFrameDarkColor(isNegative(), negated),
		isNegative(),
		parent.animState != Door.ANIM_STATE.RELOCK or parent.animPart > 2,
		game.playState != Game.PLAY_STATE.EDIT and parent.ipow().across(game.player.complexMode).eq(0)
	)

static func drawLock(_game:Game, lockDrawGlitch:RID, lockDrawScaled:RID, lockDrawMain:RID, lockDrawConfiguration:RID, lockSize:Vector2,
	lockBaseColor:Game.COLOR, lockGlitchColor:Game.COLOR,
	lockType:TYPE,
	lockConfiguration:CONFIGURATION,
	lockSizeType:SIZE_TYPE,
	lockCount:C,
	lockIsPartial:bool,
	lockDenominator,
	lockNegated:bool,
	frameHigh:Color,frameMain:Color,frameDark:Color,
	negative:bool, drawFill:bool=true, noCopies:bool=false
) -> void:
	var rect:Rect2 = Rect2(-offsetFromType(lockSizeType), lockSize)
	if lockNegated:
		RenderingServer.canvas_item_set_transform(lockDrawScaled,Transform2D(PI,lockSize-offsetFromType(lockSizeType)*2))
		RenderingServer.canvas_item_set_transform(lockDrawConfiguration,Transform2D(PI,lockSize-offsetFromType(lockSizeType)*2))
	else:
		RenderingServer.canvas_item_set_transform(lockDrawScaled,Transform2D.IDENTITY)
		RenderingServer.canvas_item_set_transform(lockDrawConfiguration,Transform2D.IDENTITY)
	# fill
	if drawFill:
		var texture:Texture2D
		var tileTexture:bool = false
		match lockBaseColor:
			Game.COLOR.MASTER: texture = _game.masterTex()
			Game.COLOR.PURE: texture = _game.pureTex()
			Game.COLOR.STONE: texture = _game.stoneTex()
			Game.COLOR.DYNAMITE: texture = _game.dynamiteTex(); tileTexture = true
			Game.COLOR.QUICKSILVER: texture = _game.quicksilverTex()
		if texture:
			if !tileTexture:
				RenderingServer.canvas_item_set_material(lockDrawScaled,Game.PIXELATED_MATERIAL.get_rid())
				RenderingServer.canvas_item_set_instance_shader_parameter(lockDrawScaled, &"size", lockSize)
			RenderingServer.canvas_item_add_texture_rect(lockDrawScaled,rect,texture,tileTexture)
		elif lockBaseColor == Game.COLOR.GLITCH:
			RenderingServer.canvas_item_set_material(lockDrawGlitch,Game.SCALED_GLITCH_MATERIAL.get_rid())
			RenderingServer.canvas_item_set_instance_shader_parameter(lockDrawGlitch, &"size", lockSize-Vector2(2,2))
			RenderingServer.canvas_item_add_rect(lockDrawGlitch,Rect2(rect.position+Vector2.ONE,rect.size-Vector2(2,2)),Game.mainTone[lockBaseColor])
			if lockGlitchColor != Game.COLOR.GLITCH:
				var glitchTexture:Texture2D
				match lockGlitchColor:
					Game.COLOR.MASTER: glitchTexture = GLITCH_FILL_MASTER[lockSizeType]
					Game.COLOR.PURE: glitchTexture = GLITCH_FILL_PURE[lockSizeType]
					Game.COLOR.STONE: glitchTexture = GLITCH_FILL_STONE[lockSizeType]
					Game.COLOR.DYNAMITE: glitchTexture = GLITCH_FILL_DYNAMITE[lockSizeType]
					Game.COLOR.QUICKSILVER: glitchTexture = GLITCH_FILL_QUICKSILVER[lockSizeType]
				if lockSizeType == SIZE_TYPE.ANY:
					if glitchTexture: RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,GLITCH_ANY_RECT,glitchTexture,GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE)
					else: RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,GLITCH_ANY_RECT,GLITCH_FILL[lockSizeType],GLITCH_CORNER_SIZE,GLITCH_CORNER_SIZE,TILE,TILE,true,Game.mainTone[lockGlitchColor])
				elif glitchTexture: RenderingServer.canvas_item_add_texture_rect(lockDrawMain,rect,glitchTexture)
				else: RenderingServer.canvas_item_add_texture_rect(lockDrawMain,rect,GLITCH_FILL[lockSizeType],false,Game.mainTone[lockGlitchColor])
		else:
			RenderingServer.canvas_item_add_rect(lockDrawMain,Rect2(rect.position+Vector2.ONE,rect.size-Vector2(2,2)),Game.mainTone[lockBaseColor])
	if noCopies: return # no copies in this direction; go away
	# frame
	RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,ANY_RECT,FRAME_HIGH,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,frameHigh)
	RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,ANY_RECT,FRAME_MAIN,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,frameMain)
	RenderingServer.canvas_item_add_nine_patch(lockDrawMain,rect,ANY_RECT,FRAME_DARK,CORNER_SIZE,CORNER_SIZE,TILE,TILE,true,frameDark)
	# configuration
	if lockConfiguration == CONFIGURATION.NONE:
		match lockType:
			TYPE.NORMAL,TYPE.EXACT:
				var string:String = str(lockCount.abs())
				if string == "1": string = ""
				if lockCount.isNonzeroImag() && lockType == TYPE.NORMAL: string += "i"
				var lockOffsetX:float = 0
				var showLock:bool = lockType == TYPE.EXACT || (!lockCount.isNonzeroImag() && (lockSize != Vector2(18,18) || string == ""))
				if lockType == TYPE.EXACT and !showLock: string = "=" + string
				var vertical:bool = lockSize.x == 18 && lockSize.y != 18 && string != ""

				var symbolLast:bool = lockType == TYPE.EXACT and lockCount.isNonzeroImag() and !vertical
				if showLock and !vertical:
					if lockType == TYPE.EXACT:
						if symbolLast: lockOffsetX = 6
						else: lockOffsetX = 12
					else: lockOffsetX = 14

				var strWidth:float = Game.FTALK.get_string_size(string,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x + lockOffsetX

				var startX:int = round((lockSize.x - strWidth)/2)
				var startY:int = round((lockSize.y+14)/2)
				if showLock and vertical: startY -= 8
				@warning_ignore("integer_division")
				if showLock:
					var lockRect:Rect2
					if vertical:
						var lockStartX:int = round((lockSize.x - lockOffsetX)/2)
						lockRect = Rect2(Vector2(lockStartX+lockOffsetX/2,lockSize.y/2+11)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
					elif symbolLast: lockRect = Rect2(Vector2(startX+strWidth-lockOffsetX/2,lockSize.y/2)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
					else: lockRect = Rect2(Vector2(startX+lockOffsetX/2,lockSize.y/2)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
					var lockSymbol:Texture2D
					if lockType == TYPE.NORMAL: lockSymbol = SYMBOL_NORMAL
					elif lockCount.isNonzeroImag(): lockSymbol = SYMBOL_EXACTI
					else: lockSymbol = SYMBOL_EXACT
					if lockNegated: lockRect = Rect2(lockSize-lockRect.position-lockRect.size-offsetFromType(lockSizeType)*2,lockRect.size)
					RenderingServer.canvas_item_add_texture_rect(lockDrawConfiguration,lockRect,lockSymbol,false,getConfigurationColor(lockNegated))
				if symbolLast: Game.FTALK.draw_string(lockDrawMain,Vector2(startX,startY)-offsetFromType(lockSizeType),string,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(lockNegated))
				else: Game.FTALK.draw_string(lockDrawMain,Vector2(startX+lockOffsetX,startY)-offsetFromType(lockSizeType),string,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(lockNegated))
			TYPE.BLANK: pass # nothing really
			TYPE.BLAST, TYPE.ALL:
				var numerator:String
				var ipow:int = 0
				if lockDenominator.isComplex() or lockDenominator.eq(0) or lockType == TYPE.ALL: numerator = str(lockCount)
				else:
					numerator = str(lockCount.over(lockDenominator.axis()))
					ipow = lockDenominator.axis().toIpow()
				if numerator == "1": numerator = ""
				
				const symbolOffsetX:float = 10
				var strWidth:float = Game.FTALK.get_string_size(numerator,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x + symbolOffsetX
				var startX:int = round((lockSize.x - strWidth)/2)
				var startY:int = round((lockSize.y+14)/2)
				
				if lockIsPartial:
					var denom:String
					if !lockDenominator.isComplex(): denom = str(lockDenominator.abs())
					else: denom = str(lockDenominator)
					var denomWidth:float = Game.FTALK.get_string_size(denom,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
					var denomStartX = round((lockSize.x - denomWidth)/2)
					var denomStartY = startY + 10
					startY -= 10
					Game.FTALK.draw_string(lockDrawMain,Vector2(denomStartX, denomStartY)-offsetFromType(lockSizeType),denom,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(negative))
					
					var lineWidth:float = max(strWidth,denomWidth)
					RenderingServer.canvas_item_add_rect(lockDrawMain,Rect2(Vector2(round((lockSize.x - lineWidth)/2),startY+2)-offsetFromType(lockSizeType),Vector2(lineWidth,2)),getConfigurationColor(negative))

				Game.FTALK.draw_string(lockDrawMain,Vector2(startX, startY)-offsetFromType(lockSizeType),numerator,HORIZONTAL_ALIGNMENT_LEFT,-1,12,getConfigurationColor(negative))

				var symbolRect:Rect2 = Rect2(Vector2(startX+strWidth-symbolOffsetX/2,startY-7)-SYMBOL_SIZE/2-offsetFromType(lockSizeType),Vector2(32,32))
				var symbol:Texture2D
				match ipow:
					0, 2: symbol = SYMBOL_BLAST
					1, 3: symbol = SYMBOL_BLASTI
				if lockType == TYPE.ALL: symbol = SYMBOL_ALL
				RenderingServer.canvas_item_add_texture_rect(lockDrawMain,symbolRect,symbol,false,getConfigurationColor(negative))
	else: RenderingServer.canvas_item_add_texture_rect(lockDrawConfiguration,rect,getPredefinedLockSprite(lockCount,lockType,lockConfiguration),false,getConfigurationColor(negative))

func getDrawPosition() -> Vector2: return position + parent.position - getOffset()

func _simpleDoorUpdate() -> void:
	# resize and set configuration	
	var newSizeType:SIZE_TYPE
	match parent.size:
		Vector2(32,32): newSizeType = SIZE_TYPE.AnyS
		Vector2(64,32): newSizeType = SIZE_TYPE.AnyH
		Vector2(32,64): newSizeType = SIZE_TYPE.AnyV
		Vector2(64,64): newSizeType = SIZE_TYPE.AnyL
		Vector2(96,96): newSizeType = SIZE_TYPE.AnyXL
		_: newSizeType = SIZE_TYPE.ANY
	changes.addChange(Changes.PropertyChange.new(game,self,&"position",Vector2.ZERO))
	changes.addChange(Changes.PropertyChange.new(game,self,&"sizeType",newSizeType))
	changes.addChange(Changes.PropertyChange.new(game,self,&"size",parent.size - Vector2(14,14)))
	queue_redraw()

func _comboDoorConfigurationChanged(newSizeType:SIZE_TYPE,newConfiguration:CONFIGURATION=CONFIGURATION.NONE) -> void:
	comboDoorConfigurationChanged(game,self,newSizeType,newConfiguration)

static func comboDoorConfigurationChanged(_game:Game,lock:GameComponent,newSizeType:SIZE_TYPE,newConfiguration:CONFIGURATION=CONFIGURATION.NONE) -> void:
	changes.addChange(Changes.PropertyChange.new(_game,lock,&"sizeType",newSizeType))
	changes.addChange(Changes.PropertyChange.new(_game,lock,&"configuration",newConfiguration))
	var newSize:Vector2
	match lock.sizeType:
		SIZE_TYPE.AnyS: newSize = Vector2(18,18)
		SIZE_TYPE.AnyH: newSize = Vector2(50,18)
		SIZE_TYPE.AnyV: newSize = Vector2(18,50)
		SIZE_TYPE.AnyM: newSize = Vector2(38,38)
		SIZE_TYPE.AnyL: newSize = Vector2(50,50)
		SIZE_TYPE.AnyXL: newSize = Vector2(82,82)
	if newSize: changes.addChange(Changes.PropertyChange.new(_game,lock,&"size",newSize))
	lock.queue_redraw()

func _comboDoorSizeChanged() -> void: comboDoorSizeChanged(game,self)

static func comboDoorSizeChanged(_game:Game,lock:GameComponent) -> void:
	var newSizeType:SIZE_TYPE = SIZE_TYPE.ANY
	match lock.size:
		Vector2(18,18): newSizeType = SIZE_TYPE.AnyS
		Vector2(50,18): newSizeType = SIZE_TYPE.AnyH
		Vector2(18,50): newSizeType = SIZE_TYPE.AnyV
		Vector2(38,38): newSizeType = SIZE_TYPE.AnyM
		Vector2(50,50): newSizeType = SIZE_TYPE.AnyL
		Vector2(82,82): newSizeType = SIZE_TYPE.AnyXL
	changes.addChange(Changes.PropertyChange.new(_game,lock,&"sizeType",newSizeType))
	if [lock.sizeType, lock.configuration] not in lock.getAvailableConfigurations():
		changes.addChange(Changes.PropertyChange.new(_game,lock,&"configuration",CONFIGURATION.NONE))

static func getAutoConfiguration(lock:GameComponent) -> CONFIGURATION:
	var newConfiguration:CONFIGURATION = CONFIGURATION.NONE
	for option in lock.getAvailableConfigurations():
		if lock.sizeType == option[0]:
			newConfiguration = option[1]
			break
	return newConfiguration

func _setAutoConfiguration() -> void:
	changes.addChange(Changes.PropertyChange.new(game,self,&"configuration",getAutoConfiguration(self)))

func receiveMouseInput(event:InputEventMouse) -> bool:
	# resizing
	if editor.componentDragged: return false
	if !Rect2(position-getOffset(),size).has_point(editor.mouseWorldPosition - parent.position) : return false
	var dragCornerSize:Vector2 = Vector2(8,8)/editor.cameraZoom
	var diffSign:Vector2 = Editor.rectSign(Rect2(position+dragCornerSize-getOffset(),size-dragCornerSize*2), editor.mouseWorldPosition-parent.position)
	var dragPivot:Editor.SIZE_DRAG_PIVOT = Editor.SIZE_DRAG_PIVOT.NONE
	match diffSign:
		Vector2(-1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_LEFT;	editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
		Vector2(0,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP;			editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Vector2(1,-1): dragPivot = Editor.SIZE_DRAG_PIVOT.TOP_RIGHT;	editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		Vector2(-1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.LEFT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Vector2(1,0): dragPivot = Editor.SIZE_DRAG_PIVOT.RIGHT;			editor.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		Vector2(-1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_LEFT;	editor.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
		Vector2(0,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM;		editor.mouse_default_cursor_shape = Control.CURSOR_VSIZE
		Vector2(1,1): dragPivot = Editor.SIZE_DRAG_PIVOT.BOTTOM_RIGHT;	editor.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
	if dragPivot != Editor.SIZE_DRAG_PIVOT.NONE and Editor.isLeftClick(event):
		editor.startSizeDrag(self, dragPivot)
		return true
	return false

func _coerceSize() -> void: lockCoerceSize(game,self)

static func lockCoerceSize(_game:Game,lock:GameComponent) -> void:
	var newSize = (lock.size+Vector2(14,14)).snapped(Vector2(16,16))
	if newSize == Vector2(48,48):
		newSize = Vector2(38,38)
	else:
		newSize = (lock.size+Vector2(14,14)).snapped(Vector2(32,32)) - Vector2(14,14)
		if newSize in SIZES: return
		newSize = newSize.min(Vector2(82,82))
		# 1x3, 2x3 -> 3x3
		if newSize.x < newSize.y: newSize = Vector2(newSize.y, newSize.y)
		elif newSize.y < newSize.x: newSize = Vector2(newSize.x, newSize.x)
	_game.changes.addChange(Changes.PropertyChange.new(_game,lock,&"size",newSize))

func propertyChangedInit(property:StringName) -> void:
	if parent.type != Door.TYPE.SIMPLE:
		if property == &"size": _comboDoorSizeChanged()
	if property in [&"count", &"sizeType", &"type"]: _setAutoConfiguration()
	
	if property == &"type":
		if (type == TYPE.BLANK or (type == TYPE.ALL and !mods.active(&"C3"))) and count.neq(1):
			changes.addChange(Changes.PropertyChange.new(game,self,&"count",C.ONE))
		if type == TYPE.BLAST:
			if (count.abs().neq(1)) and !mods.active(&"C3"): changes.addChange(Changes.PropertyChange.new(game,self,&"count",C.ONE if count.eq(0) else count.axis()))
		elif type == TYPE.ALL:
			if !isPartial and denominator.neq(1): changes.addChange(Changes.PropertyChange.new(game,self,&"denominator",C.ONE))
		else:
			if denominator.neq(1): changes.addChange(Changes.PropertyChange.new(game,self,&"denominator",C.ONE))
			if isPartial: changes.addChange(Changes.PropertyChange.new(game,self,&"isPartial",false))

	if property in [&"color", &"type"] and editor.focusDialog.focused == parent: editor.focusDialog.doorDialog.lockHandler.redrawButton(index)
	
	if property == &"isPartial" and !isPartial:
		changes.addChange(Changes.PropertyChange.new(game,self,&"denominator", C.ONE if count.isComplex() or count.eq(0) or type == TYPE.ALL else count.axis()))

func propertyChangedDo(property:StringName) -> void:
	if property in [&"count", &"denominator"]: parent.queue_redraw()

# ==== PLAY ==== #
var glitchMimic:Game.COLOR = Game.COLOR.GLITCH
var curseGlitchMimic:Game.COLOR = Game.COLOR.GLITCH

func stop() -> void:
	glitchMimic = Game.COLOR.GLITCH
	curseGlitchMimic = Game.COLOR.GLITCH

func colorAfterCurse() -> Game.COLOR:
	if parent.cursed and parent.curseColor != Game.COLOR.PURE: return parent.curseColor
	return color

func colorAfterGlitch() -> Game.COLOR:
	var base:Game.COLOR = colorAfterCurse()
	if base == Game.COLOR.GLITCH: return curseGlitchMimic if parent.cursed else glitchMimic
	return base

func colorAfterAurabreaker() -> Game.COLOR:
	if int(parent.gameFrozen) + int(parent.gameCrumbled) + int(parent.gamePainted) > 1: return colorAfterGlitch()
	if parent.gameFrozen: return Game.COLOR.ICE
	if parent.gameCrumbled: return Game.COLOR.MUD
	if parent.gamePainted: return Game.COLOR.GRAFFITI
	return colorAfterGlitch()

func effectiveConfiguration() -> CONFIGURATION:
	if parent.ipow().neq(1):
		if parent.type == Door.TYPE.SIMPLE: return getAutoConfiguration(self)
		else: return CONFIGURATION.NONE
	else: return configuration

func canOpen(player:Player) -> bool: return getLockCanOpen(self, player)

static func getLockCanOpen(lock:GameComponent,player:Player) -> bool:
	var can:bool = true
	var keyCount:C = player.key[lock.colorAfterAurabreaker()]
	match lock.type:
		TYPE.NORMAL: can = !keyCount.across(lock.effectiveCount().axis()).reduce().lt(lock.effectiveCount().abs())
		TYPE.BLANK: can = keyCount.eq(0)
		TYPE.BLAST:
			if lock.effectiveDenominator().eq(0): can = false
			elif lock.effectiveDenominator().r.neq(0) and !player.key[lock.colorAfterAurabreaker()].r.times(lock.effectiveDenominator().r).gt(0): can = false
			elif lock.effectiveDenominator().i.neq(0) and !player.key[lock.colorAfterAurabreaker()].i.times(lock.effectiveDenominator().i).gt(0): can = false
			elif lock.isPartial:
				if lock.effectiveDenominator().r.neq(0) and !player.key[lock.colorAfterAurabreaker()].r.divides(lock.effectiveDenominator().r): can = false
				elif lock.effectiveDenominator().i.neq(0) and !player.key[lock.colorAfterAurabreaker()].i.divides(lock.effectiveDenominator().i): can = false
		TYPE.ALL:
			if lock.effectiveDenominator().eq(0): can = false
			elif keyCount.eq(0): can = false
			elif lock.isPartial:
				if keyCount.modulo(lock.effectiveDenominator()).neq(0): can = false
		TYPE.EXACT: can = keyCount.across(lock.effectiveCount().axibs()).eq(lock.effectiveCount())
	return can != lock.negated

func getCost(player:Player, ipow:C=parent.ipow()) -> C: return getLockCost(self, player, ipow)

static func getLockCost(lock:GameComponent, player:Player, ipow:C) -> C:
	var cost:C = C.ZERO
	match lock.type:
		TYPE.NORMAL, TYPE.EXACT: cost = lock.effectiveCount(ipow)
		TYPE.BLAST:
			if lock.effectiveDenominator(ipow).neq(0): cost = player.key[lock.colorAfterAurabreaker()].across(lock.effectiveDenominator(ipow).axibs()).times(lock.effectiveCount(ipow)).over(lock.effectiveDenominator(ipow))
		TYPE.ALL: if lock.effectiveDenominator(ipow).neq(0): cost = player.key[lock.colorAfterAurabreaker()].times(lock.effectiveCount(ipow)).over(lock.effectiveDenominator(ipow))
	if lock.negated: return cost.times(-1)
	return cost

func effectiveCount(ipow:C=parent.ipow()) -> C:
	return count.times(ipow)

func effectiveDenominator(ipow:C=parent.ipow()) -> C:
	return denominator.times(ipow)

func isNegative() -> bool:
	if type == TYPE.ALL: return false
	return (effectiveDenominator() if type == TYPE.BLAST else effectiveCount()).sign() < 0
