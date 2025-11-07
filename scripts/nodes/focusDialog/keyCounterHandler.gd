extends Handler
class_name KeyCounterHandler

var keyCounter:KeyCounter

func setup(_keyCounter:KeyCounter) -> void:
	keyCounter = _keyCounter
	deleteButtons()
	for index in len(keyCounter.elements):
		var button:KeyCounterHandlerButton = KeyCounterHandlerButton.new(index, self)
		buttons.append(button)
		add_child(button)
	move_child(add, -1)
	move_child(remove, -1)

func addComponent() -> void: keyCounter.addElement()
func removeComponent() -> void: keyCounter.removeElement(selected)

static func buttonType() -> GDScript: return KeyCounterHandlerButton

func addButton(index:int=len(buttons),select:bool=true) -> void:
	super(index,select)
	if len(buttons) == 1: remove.visible = false

func removeButton(index:int=selected,select:bool=true) -> void:
	super(index,select)
	if len(buttons) == 1: remove.visible = false

func _select(button:Button) -> void:
	super(button)
	if !manuallySetting: editor.focusDialog.focusComponent(keyCounter.elements[selected])

func deselect() -> void:
	if selected == -1: return
	buttons[selected].button_pressed = false
	selected = -1

class KeyCounterHandlerButton extends HandlerButton:
	
	var element:KeyCounterElement

	var drawMain:RID
	var drawGlitch:RID

	func _init(_index:int,_handler:KeyCounterHandler) -> void:
		super(_index, _handler)
		element = handler.keyCounter.elements[index]

	func _ready() -> void:
		drawMain = RenderingServer.canvas_item_create()
		drawGlitch = RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_material(drawGlitch,Game.UNSCALED_GLITCH_MATERIAL.get_rid())
		RenderingServer.canvas_item_set_parent(drawMain,get_canvas_item())
		RenderingServer.canvas_item_set_parent(drawGlitch,get_canvas_item())
		RenderingServer.canvas_item_set_z_index(drawMain,-1)
		RenderingServer.canvas_item_set_z_index(drawGlitch,-1)
		editor.game.connect(&"goldIndexChanged",queue_redraw)
		queue_redraw()
	
	func _draw() -> void:
		RenderingServer.canvas_item_clear(drawMain)
		RenderingServer.canvas_item_clear(drawGlitch)
		if deleted: return
		var rect:Rect2 = Rect2(Vector2.ONE, size-Vector2(2,2))
		var texture:Texture2D
		match element.color:
			Game.COLOR.MASTER: texture = editor.game.masterTex()
			Game.COLOR.PURE: texture = editor.game.pureTex()
			Game.COLOR.STONE: texture = editor.game.stoneTex()
			Game.COLOR.DYNAMITE: texture = editor.game.dynamiteTex()
			Game.COLOR.QUICKSILVER: texture = editor.game.quicksilverTex()
		if texture:
			RenderingServer.canvas_item_add_texture_rect(drawMain,rect,texture)
		elif element.color == Game.COLOR.GLITCH:
			RenderingServer.canvas_item_add_rect(drawGlitch,rect,editor.game.mainTone[element.color])
		else:
			RenderingServer.canvas_item_add_rect(drawMain,rect,editor.game.mainTone[element.color])
