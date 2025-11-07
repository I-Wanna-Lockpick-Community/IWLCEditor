extends Handler
class_name DoorsHandler
# for remote lock

var remoteLock:RemoteLock

func setup(_remoteLock:RemoteLock) -> void:
	selected = -1
	remoteLock = _remoteLock
	deleteButtons()
	for index in len(remoteLock.doors):
		var button:DoorsHandlerButton = DoorsHandlerButton.new(index, self)
		buttons.append(button)
		add_child(button)
	move_child(add, -1)
	move_child(remove, -1)
	remove.visible = len(buttons) > 0

static func buttonType() -> GDScript: return DoorsHandlerButton

func addComponent() -> void:
	editor.connectionSource = remoteLock
	editor.focusDialog.defocus()

func removeComponent() -> void: remoteLock._disconnectTo(buttons[selected].door)

func _select(button:Button) -> void:
	if selected == button.index: editor.focusDialog.focus(button.door)
	else: super(button)
	remoteLock.queue_redraw()

class DoorsHandlerButton extends HandlerButton:
	const ICON:Texture2D = preload("res://assets/ui/focusDialog/doorsHandler/door.png")

	var door:Door

	var drawMain:RID

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		RenderingServer.canvas_item_set_z_index(drawMain,-1)
		editor.game.connect(&"goldIndexChanged",queue_redraw)
		icon = ICON
		queue_redraw()

	func _init(_index:int,_handler:DoorsHandler) -> void:
		super(_index, _handler)
		door = handler.remoteLock.doors[index]

	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		if deleted: return
		var rect:Rect2 = Rect2(Vector2.ONE, size-Vector2(2,2))
		var texture:Texture2D
		if door.colorSpend == Game.COLOR.GLITCH: RenderingServer.canvas_item_set_material(drawMain, Game.UNSCALED_GLITCH_MATERIAL)
		else: RenderingServer.canvas_item_set_material(drawMain, Game.NO_MATERIAL)
		match door.colorSpend:
			Game.COLOR.MASTER: texture = editor.game.masterTex()
			Game.COLOR.PURE: texture = editor.game.pureTex()
			Game.COLOR.STONE: texture = editor.game.stoneTex()
			Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
			Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
		if texture:
			RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
		else:
			RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[door.colorSpend])
