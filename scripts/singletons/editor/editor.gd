extends Control
class_name Editor

@onready var world:World = %world
@onready var modes:Modes = %modes
@onready var gameCont:MarginContainer = %gameCont
@onready var focusDialog:FocusDialog = %focusDialog
@onready var quickSet:QuickSet = %quickSet
@onready var multiselect:Multiselect = %multiselect
@onready var paste:Button = %paste
@onready var otherObjects:OtherObjects = %otherObjects
@onready var topBar:TopBar = %topBar
@onready var settingsMenu:SettingsMenu = %settingsMenu
var modsWindow:ModsWindow
var findProblems:FindProblems

@onready var saveAsDialog:FileDialog = %saveAsDialog
@onready var openDialog:FileDialog = %openDialog
@onready var unsavedChangesPopup:ConfirmationDialog = %unsavedChangesPopup
@onready var loadErrorPopup:AcceptDialog = %loadErrorPopup

@onready var editorCamera:Camera2D = %editorCamera
@onready var playtestCamera:Camera2D = %playtestCamera

@onready var gameViewport:SubViewport = %gameViewport
@onready var explainText:RichTextLabel = %explainText

enum MODE {SELECT, TILE, KEY, DOOR, OTHER, PASTE}
var mode:MODE = MODE.SELECT

var mouseWorldPosition:Vector2
var mouseTilePosition:Vector2i

var targetCameraZoom:float = 1
var zoomPoint:Vector2 # the point where the latest zoom was targetted

var objectHovered:GameObject
var componentHovered:GameComponent # you can hover both a door and a lock at the same time so

enum DRAG_MODE {POSITION, SIZE_FDIAG, SIZE_BDIAG, SIZE_VERT, SIZE_HORIZ}
enum SIZE_DRAG_PIVOT {TOP_LEFT, TOP, TOP_RIGHT, LEFT, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT, NONE}
var componentDragged:GameComponent
var dragMode:DRAG_MODE
var dragOffset:Vector2 # the offset for position dragging
var dragPivotRect:Rect2 # the pivot for size dragging
var previousDragPosition:Vector2i # to check whether or not a drag would do anything

var lockBufferConvert:bool = false
var connectionSource:GameObject # for pulling connections between remote locks and doors

var tileSize:Vector2i = Vector2i(32,32)

var cameraZoom:float = 1

var settingsOpen:bool = false

var drawDescription:RID
var drawMain:RID
var drawAutoRunGradient:RID
var autoRunTimer:float = 2

func _ready() -> void:
	drawDescription = RenderingServer.canvas_item_create()
	drawMain = RenderingServer.canvas_item_create()
	drawAutoRunGradient = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_z_index(drawDescription, 1)
	RenderingServer.canvas_item_set_material(drawAutoRunGradient, Game.TEXT_GRADIENT_MATERIAL)
	RenderingServer.canvas_item_set_parent(drawDescription, %description.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawMain, %gameCont.get_canvas_item())
	RenderingServer.canvas_item_set_parent(drawAutoRunGradient, %gameCont.get_canvas_item())
	Game.setWorld(%world)
	%settingsText.text = "IWLCEditor v" + ProjectSettings.get_setting("application/config/version")
	settingsMenu.gameSettings.editor = self
	settingsMenu.opened()
	if Game.awaitingEditor: Game.editReadied()
	Saving.editorReady()
	if OS.has_feature('web'):
		%fileMenu.menu.remove_item(6)
		%fileMenu.menu.remove_item(4)

func _process(delta:float) -> void:
	queue_redraw()
	var scaleFactor:float = (targetCameraZoom/editorCamera.zoom.x)**0.2
	if abs(scaleFactor - 1) < 0.0001:
		editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
		if targetCameraZoom == 1: editorCamera.position = round(editorCamera.position)
	else:
		editorCamera.zoom *= scaleFactor
		editorCamera.position += (1-1/scaleFactor) * (worldspaceToScreenspace(zoomPoint)-gameCont.position) / editorCamera.zoom
	
	if Input.is_key_pressed(KEY_ALT):
		if Input.is_key_pressed(KEY_CTRL): tileSize = Vector2i(1,1)
		else: tileSize = Vector2i(4,4)
	elif Input.is_key_pressed(KEY_CTRL): tileSize = Vector2i(16,16)
	else: tileSize = Vector2i(32,32)
	
	if Game.playState != Game.PLAY_STATE.PLAY and !focusDialog.focused and get_window().has_focus() and has_focus():
		editorCamera.position += Vector2(Input.get_axis(&"camera_left", &"camera_right"),Input.get_axis(&"camera_up", &"camera_down"))*delta/editorCamera.zoom*700


	mouseWorldPosition = screenspaceToWorldspace(get_global_mouse_position())
	mouseTilePosition = Vector2i(mouseWorldPosition) / tileSize * tileSize
	if Game.playState == Game.PLAY_STATE.PLAY or settingsOpen: %gameViewportCont.material.set_shader_parameter("mousePosition",Vector2(-1e7,-1e7)) # probably far away enough
	else: %gameViewportCont.material.set_shader_parameter("mousePosition",mouseWorldPosition)
	%gameViewportCont.material.set_shader_parameter("screenPosition",screenspaceToWorldspace(Vector2.ZERO))
	if Game.playState == Game.PLAY_STATE.PLAY: cameraZoom = playtestCamera.zoom.x
	else: cameraZoom = editorCamera.zoom.x
	RenderingServer.global_shader_parameter_set(&"RCAMERA_ZOOM", 1/cameraZoom)
	%gameViewportCont.material.set_shader_parameter("tileSize",tileSize)
	componentHovered = null
	if !componentDragged:
		objectHovered = null
		for object in Game.objectsParent.get_children():
			if mode == MODE.SELECT or (mode == MODE.KEY and object is KeyBulk) or (mode == MODE.DOOR and object is Door) or (mode == MODE.OTHER and object.get_script() == otherObjects.selected):
				if Rect2(object.getDrawPosition(), object.size).has_point(mouseWorldPosition):
					objectHovered = object
		if focusDialog.focused is Door:
			for lock in focusDialog.focused.locks:
				if Rect2(lock.getDrawPosition(), lock.size).has_point(mouseWorldPosition):
					componentHovered = lock
		elif focusDialog.focused is KeyCounter:
			for element in focusDialog.focused.elements:
				if Rect2(element.getDrawPosition(), element.getHoverSize()).has_point(mouseWorldPosition):
					componentHovered = element
	%mouseover.describe(objectHovered if Game.playState == Game.PLAY_STATE.PLAY else null, %gameViewportCont.get_local_mouse_position(), %gameViewportCont.size)
	Game.tiles.z_index = 3 if mode == MODE.TILE and Game.playState != Game.PLAY_STATE.PLAY else 0

	if autoRunTimer < 2:
		autoRunTimer += delta
		queue_redraw()
		if autoRunTimer >= 2: autoRunTimer = 2

func _gui_input(event:InputEvent) -> void:
	if !objectHovered: objectHovered = null
	if !componentHovered: componentHovered = null
	if event is InputEventMouse:
		if settingsOpen:
			mouse_default_cursor_shape = CURSOR_ARROW
		elif Game.playState == Game.PLAY_STATE.PLAY:
			mouse_default_cursor_shape = CURSOR_ARROW
		else:
			# move camera
			if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
				editorCamera.position -= event.relative / cameraZoom
			if event is InputEventMouseButton and event.is_pressed():
				match event.button_index:
					MOUSE_BUTTON_WHEEL_UP: zoomCamera(1.25)
					MOUSE_BUTTON_WHEEL_DOWN: zoomCamera(0.8)
			# modes
			if isLeftUnclick(event) or isRightUnclick(event):
				if componentDragged:
					if sizeDragging():
						if !Mods.active(&"NstdLockSize") and componentDragged is Lock and componentDragged.parent.type != Door.TYPE.SIMPLE:
							componentDragged._coerceSize()
						if componentDragged is GameObject: focusDialog.focus(componentDragged)
						else: focusDialog.focusComponent(componentDragged)
					elif dragMode == DRAG_MODE.POSITION:
						if lockBufferConvert:
							lockBufferConvert = false
							var remoteLock = Changes.addChange(Changes.CreateComponentChange.new(RemoteLock,{&"position":componentDragged.position+componentDragged.parent.position})).result
							for property in Lock.PROPERTIES:
								if property not in [&"id", &"position", &"parentId", &"index"]:
									Changes.addChange(Changes.PropertyChange.new(remoteLock,property,componentDragged.get(property)))
							focusDialog.focus(remoteLock)
							remoteLock._connectTo(componentDragged.parent)
							Changes.addChange(Changes.DeleteComponentChange.new(componentDragged))
				Changes.bufferSave()
				componentDragged = null
			# set mouse cursor
			if multiselect.state == Multiselect.STATE.DRAGGING: mouse_default_cursor_shape = CURSOR_DRAG
			elif componentDragged:
				match dragMode:
					DRAG_MODE.POSITION: mouse_default_cursor_shape = CURSOR_DRAG
					DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG:
						pass
						var diffSign:Vector2 = rectSign(dragPivotRect, Vector2(mouseTilePosition))
						match diffSign:
							Vector2(-1,-1), Vector2(0,0), Vector2(1,1): mouse_default_cursor_shape = CURSOR_FDIAGSIZE
							Vector2(-1,1), Vector2(1,-1): mouse_default_cursor_shape = CURSOR_BDIAGSIZE
							Vector2(-1,0), Vector2(1,0): mouse_default_cursor_shape = CURSOR_HSIZE
							Vector2(0,-1), Vector2(0,1): mouse_default_cursor_shape = CURSOR_VSIZE
					DRAG_MODE.SIZE_VERT: mouse_default_cursor_shape = CURSOR_VSIZE
					DRAG_MODE.SIZE_HORIZ: mouse_default_cursor_shape = CURSOR_HSIZE
			else: mouse_default_cursor_shape = CURSOR_ARROW
			# connection pulling
			if connectionSource and isLeftClick(event):
				if connectionSource is RemoteLock and objectHovered is Door: connectionSource._connectTo(objectHovered)
				if connectionSource is Door and objectHovered is RemoteLock: objectHovered._connectTo(connectionSource)
				focusDialog.focus(connectionSource)
				connectionSource.queue_redraw()
				connectionSource = null
				return
			# multiselect
			if multiselect.receiveMouseInput(event): return
			elif multiselect.state == Multiselect.STATE.HOLDING and (isLeftClick(event) or isRightClick(event)): multiselect.deselect()
			# size drag handles
			if focusDialog.componentFocused is Lock and focusDialog.focused.type != Door.TYPE.SIMPLE:
				if focusDialog.componentFocused.receiveMouseInput(event): return
			elif objectHovered:
				if objectHovered.receiveMouseInput(event): return
			# dragging
			if componentDragged and dragComponent(): return
			# other
			match mode:
				MODE.SELECT:
					if isLeftClick(event): # if youre hovering something and you leftclick, focus it
						if componentHovered:
							focusDialog.focusComponent(componentHovered)
						else: focusDialog.defocusComponent()
						if componentHovered is Lock and componentHovered.parent.type != Door.TYPE.SIMPLE: startPositionDrag(componentHovered)
						elif componentHovered is KeyCounterElement: startPositionDrag(componentHovered)
						elif objectHovered: startPositionDrag(objectHovered)
						else:
							focusDialog.defocus()
							multiselect.pivot = get_global_mouse_position()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and event is InputEventMouseMotion and multiselect.state == Multiselect.STATE.HOLDING: multiselect.startSelect()
				MODE.TILE:
					if Mods.active(&"OutOfBounds") or Game.levelBounds.has_point(mouseWorldPosition):
						if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
							Changes.addChange(Changes.TileChange.new(mouseTilePosition/32,true))
							focusDialog.defocus()
						elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
							Changes.addChange(Changes.TileChange.new(mouseTilePosition/32,false))
							focusDialog.defocus()
				MODE.KEY:
					if isLeftClick(event): # if youre hovering a key and you leftclick, focus it
						if objectHovered is KeyBulk:
							startPositionDrag(objectHovered)
						else: focusDialog.defocus()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						if objectHovered is not KeyBulk and Game.levelBounds.has_point(mouseWorldPosition):
							var key:KeyBulk = Changes.addChange(Changes.CreateComponentChange.new(KeyBulk,{&"position":mouseTilePosition})).result
							focusDialog.defocus()
							if !Input.is_key_pressed(KEY_SHIFT):
								modes.setMode(MODE.SELECT)
								startPositionDrag(key)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered is KeyBulk:
							Changes.addChange(Changes.DeleteComponentChange.new(objectHovered))
							Changes.bufferSave()
				MODE.DOOR:
					if isLeftClick(event):
						if componentHovered:
							focusDialog.focusComponent(componentHovered)
						else: focusDialog.defocusComponent()
						if componentHovered is Lock: startPositionDrag(componentHovered)
						elif objectHovered is Door: startPositionDrag(objectHovered)
						else:
							if objectHovered is not Door and Game.levelBounds.has_point(mouseWorldPosition):
								var door:Door = Changes.addChange(Changes.CreateComponentChange.new(Door,{&"position":mouseTilePosition})).result
								startSizeDrag(door)
								Changes.addChange(Changes.CreateComponentChange.new(Lock,{&"position":Vector2.ZERO,&"parentId":door.id}))
								if !Input.is_key_pressed(KEY_SHIFT):
									modes.setMode(MODE.SELECT)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered is Door:
							Changes.addChange(Changes.DeleteComponentChange.new(objectHovered))
							Changes.bufferSave()
				MODE.OTHER:
					if isLeftClick(event):
						if componentHovered is KeyCounterElement and otherObjects.selected == KeyCounter: startPositionDrag(componentHovered)
						elif objectHovered and objectHovered.get_script() == otherObjects.selected:
							startPositionDrag(objectHovered)
						else: focusDialog.defocus()
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
						if (!objectHovered or objectHovered.get_script() != otherObjects.selected) and Game.levelBounds.has_point(mouseWorldPosition):
							var object:GameObject = Changes.addChange(Changes.CreateComponentChange.new(otherObjects.selected,{&"position":mouseTilePosition})).result
							focusDialog.defocus()
							if otherObjects.selected == KeyCounter:
								Changes.addChange(Changes.CreateComponentChange.new(KeyCounterElement,{&"position":Vector2(12,12),&"parentId":object.id}))
							if !Input.is_key_pressed(KEY_SHIFT):
								modes.setMode(MODE.SELECT)
								startPositionDrag(object)
					if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
						if objectHovered and objectHovered.get_script() == otherObjects.selected:
							Changes.addChange(Changes.DeleteComponentChange.new(objectHovered))
							Changes.bufferSave()
				MODE.PASTE:
					if isLeftClick(event):
						multiselect.paste()
						if !Input.is_key_pressed(KEY_SHIFT):
							modes.setMode(MODE.SELECT)

func startPositionDrag(component:GameComponent) -> void:
	if component is GameObject: focusDialog.focus(component)
	else: focusDialog.focusComponent(component)
	componentDragged = component
	dragOffset = component.position - Vector2(mouseTilePosition)
	dragMode = DRAG_MODE.POSITION
	previousDragPosition = mouseTilePosition

func startSizeDrag(component:GameComponent, pivot:SIZE_DRAG_PIVOT=SIZE_DRAG_PIVOT.BOTTOM_RIGHT) -> void:
	focusDialog.defocus()
	componentDragged = component
	var rectPos:Vector2 = Vector2.ZERO
	var minSize:Vector2
	if component is Door: minSize = Vector2(32,32)
	elif component is Lock or component is RemoteLock: minSize = Vector2(18,18)
	elif component is KeyCounter: minSize = Vector2(107,63)
	if component is not GameObject: rectPos += component.parent.position
	match pivot:
		SIZE_DRAG_PIVOT.BOTTOM_RIGHT: rectPos += componentDragged.position; dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_LEFT: rectPos += componentDragged.position+componentDragged.size-minSize; dragMode = DRAG_MODE.SIZE_FDIAG
		SIZE_DRAG_PIVOT.TOP_RIGHT: rectPos += componentDragged.position+Vector2(0,componentDragged.size.y-minSize.y); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM_LEFT: rectPos += componentDragged.position+Vector2(componentDragged.size.x-minSize.x,0); dragMode = DRAG_MODE.SIZE_BDIAG
		SIZE_DRAG_PIVOT.BOTTOM: rectPos += componentDragged.position; dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.TOP: rectPos += componentDragged.position+Vector2(0,componentDragged.size.y-minSize.y); dragMode = DRAG_MODE.SIZE_VERT
		SIZE_DRAG_PIVOT.RIGHT: rectPos += componentDragged.position; dragMode = DRAG_MODE.SIZE_HORIZ
		SIZE_DRAG_PIVOT.LEFT: rectPos += componentDragged.position+Vector2(componentDragged.size.x-minSize.x,0); dragMode = DRAG_MODE.SIZE_HORIZ
	if dragMode == DRAG_MODE.SIZE_VERT:  minSize.x = componentDragged.size.x
	if dragMode == DRAG_MODE.SIZE_HORIZ:  minSize.y = componentDragged.size.y
	dragPivotRect = Rect2(rectPos, minSize)
	previousDragPosition = mouseTilePosition

func dragComponent() -> bool: # returns whether or not an object is being dragged, for laziness
	if !componentDragged: return false
	if mouseTilePosition == previousDragPosition and componentDragged is not KeyCounterElement: return true
	lockBufferConvert = false
	previousDragPosition = mouseTilePosition
	var dragPosition:Vector2 = mouseTilePosition
	var parentPosition:Vector2 = Vector2.ZERO
	if componentDragged is not GameObject: parentPosition = componentDragged.parent.position
	# clamp to bounds
	if dragMode == DRAG_MODE.POSITION: dragPosition += Vector2(dragOffset)
	else: dragPosition -= parentPosition
	if componentDragged is Lock:
		var topLeft:Vector2 = componentDragged.getOffset()
		var bottomRight:Vector2 = componentDragged.getOffset()+componentDragged.parent.size-Vector2.ONE
		# this shit sucks
		if dragPosition.x < topLeft.x or dragPosition.y < topLeft.y:
			if Mods.active(&"C1"): lockBufferConvert = true
			elif !Mods.active(&"DisconnectedLock"): dragPosition += ceil(Vector2.ZERO.max(topLeft-dragPosition)/Vector2(tileSize))*Vector2(tileSize)
		if dragMode == DRAG_MODE.POSITION and (dragPosition.x > bottomRight.x or dragPosition.y > bottomRight.y):
			if Mods.active(&"C1"): lockBufferConvert = true
			elif !Mods.active(&"DisconnectedLock"): dragPosition += floor(Vector2.ZERO.min(bottomRight-dragPosition)/Vector2(tileSize))*Vector2(tileSize)
	elif componentDragged is not KeyCounterElement and !Mods.active(&"OutOfBounds"):
		var topLeft:Vector2 = Game.levelBounds.position
		var bottomRight:Vector2 = Game.levelBounds.end-Vector2i.ONE
		# this shit sucks
		if dragPosition.x < topLeft.x or dragPosition.y < topLeft.y: dragPosition += ceil(Vector2.ZERO.max(topLeft-dragPosition)/Vector2(tileSize))*Vector2(tileSize)
		if dragMode == DRAG_MODE.POSITION and (dragPosition.x > bottomRight.x or dragPosition.y > bottomRight.y): dragPosition += floor(Vector2.ZERO.min(bottomRight-dragPosition)/Vector2(tileSize))*Vector2(tileSize)
	if dragMode == DRAG_MODE.POSITION: dragPosition -= Vector2(dragOffset)
	else: dragPosition += parentPosition
	match dragMode:
		DRAG_MODE.POSITION:
			if componentDragged is KeyCounterElement:
				dragPosition = mouseWorldPosition - Vector2(0,20)
				if componentDragged.index > 0 and (componentDragged.position+parentPosition).y - dragPosition.y >= 20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index-1)
				elif componentDragged.index < len(componentDragged.parent.elements) - 1 and (componentDragged.position+parentPosition).y - dragPosition.y <= -20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index+1)
			else:
				Changes.addChange(Changes.PropertyChange.new(componentDragged,&"position",dragPosition + dragOffset))
		DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ:
			# since mousetileposition rounds down, dragging down or right should go one tile farther
			if mouseWorldPosition.x > dragPivotRect.position.x:
				dragPosition.x += tileSize.x
				if componentDragged is Lock or componentDragged is RemoteLock: dragPosition.x += componentDragged.getOffset().x*2
			if mouseWorldPosition.y > dragPivotRect.position.y:
				dragPosition.y += tileSize.y
				if componentDragged is Lock or componentDragged is RemoteLock: dragPosition.y += componentDragged.getOffset().y*2
			# keycounter has only a few possible widths
			if componentDragged is KeyCounter:
				dragPosition -= dragPivotRect.position
				if dragPosition.x <= KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[2]: dragPosition.x = KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[2]
				elif dragPosition.x <= KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[1]: dragPosition.x = KeyCounter.WIDTHS[0] - KeyCounter.WIDTHS[1]
				elif dragPosition.x > KeyCounter.WIDTHS[2]: dragPosition.x = KeyCounter.WIDTHS[2]
				elif dragPosition.x > KeyCounter.WIDTHS[1]: dragPosition.x = KeyCounter.WIDTHS[1]
				else: dragPosition.x = 0
				dragPosition.y = 0
				dragPosition += dragPivotRect.position
			var toRect:Rect2 = dragPivotRect.expand(dragPosition)
			Changes.addChange(Changes.PropertyChange.new(componentDragged,&"position",toRect.position-parentPosition))
			Changes.addChange(Changes.PropertyChange.new(componentDragged,&"size",toRect.size))
	return true

func _input(event:InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if settingsOpen:
			pass
		elif Game.playState == Game.PLAY_STATE.PLAY:
			# IN PLAY
			match event.keycode:
				KEY_E: autoRun()
				KEY_ESCAPE: _toggleSettingsMenu(true)
				_: Game.player.receiveKey(event)
		else:
			# IN EDIT
			if otherObjects.objectSearch.has_focus():
				match event.keycode:
					KEY_ESCAPE: grab_focus()
					KEY_TAB: otherObjects._searchSubmitted()
				return
			if quickSet.quick: quickSet.receiveKey(event); return
			if focusDialog.interacted and focusDialog.interacted.receiveKey(event): return
			if focusDialog.focused and focusDialog.receiveKey(event): return
			match event.keycode:
				KEY_ESCAPE:
					if Input.is_key_pressed(KEY_SHIFT):
						_toggleSettingsMenu(true)
					else:
						modes.setMode(MODE.SELECT)
						focusDialog.defocus()
						componentDragged = null
						multiselect.deselect()
				KEY_T: modes.setMode(MODE.TILE)
				KEY_B: modes.setMode(MODE.KEY)
				KEY_D: modes.setMode(MODE.DOOR)
				KEY_S:
					if Input.is_key_pressed(KEY_CTRL):
						if OS.has_feature('web'): Saving.save()
						else:
							if Input.is_key_pressed(KEY_SHIFT): Saving.saveAs()
							else: Saving.save()
					else: otherObjects.objectSearch.grab_focus()
				KEY_Z: if Input.is_key_pressed(KEY_CTRL): Changes.undo()
				KEY_Y: if Input.is_key_pressed(KEY_CTRL): Changes.redo()
				KEY_C: if Input.is_key_pressed(KEY_CTRL): multiselect.copySelection()
				KEY_V: if Input.is_key_pressed(KEY_CTRL) and multiselect.clipboard != []: modes.setMode(MODE.PASTE)
				KEY_X:
					if Input.is_key_pressed(KEY_CTRL): multiselect.copySelection(); multiselect.delete()
					else: modes.setMode(MODE.OTHER)
				KEY_O: if Game.playState != Game.PLAY_STATE.EDIT: Game.stopTest()
				KEY_M:
					if focusDialog.componentFocused: startPositionDrag(focusDialog.componentFocused)
					elif focusDialog.focused: startPositionDrag(focusDialog.focused)
				KEY_H: home()
				KEY_SPACE:
					if !topBar.play.disabled:
						var ctrlHeld:bool = Input.is_key_pressed(KEY_CTRL)
						await get_tree().process_frame
						await get_tree().process_frame # bullshit to make sure you dont jump at the start
						if ctrlHeld: Game.playTest(Game.latestSpawn)
						else: Game.playTest(Game.levelStart)
				KEY_DELETE: multiselect.delete()
				KEY_TAB: grab_focus()

func home() -> void:
	targetCameraZoom = 1
	zoomPoint = Game.levelBounds.get_center()
	editorCamera.position = zoomPoint - gameCont.size / (cameraZoom*2)

func zoomCamera(factor:float) -> void:
	targetCameraZoom *= factor
	zoomPoint = mouseWorldPosition
	if abs(targetCameraZoom - 1) < 0.001: targetCameraZoom = 1
	if targetCameraZoom < 0.001: targetCameraZoom = 0.001
	if targetCameraZoom > 1000: targetCameraZoom = 1000

func worldspaceToScreenspace(vector:Vector2) -> Vector2:
	if Game.playState == Game.PLAY_STATE.PLAY: return (vector - playtestCamera.get_screen_center_position())*playtestCamera.zoom + gameCont.position + gameCont.size/2
	else: return (vector - editorCamera.position)*editorCamera.zoom + gameCont.position

func screenspaceToWorldspace(vector:Vector2) -> Vector2:
	if Game.playState == Game.PLAY_STATE.PLAY: return (vector - gameCont.position - gameCont.size/2)/playtestCamera.zoom + playtestCamera.get_screen_center_position()
	return (vector - gameCont.position)/editorCamera.zoom + editorCamera.position

static func isLeftClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightClick(event:InputEvent) -> bool: return event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT
static func isLeftUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
static func isRightUnclick(event:InputEvent) -> bool: return event is InputEventMouseButton and !event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT

func sizeDragging() -> bool: return dragMode in [DRAG_MODE.SIZE_FDIAG, DRAG_MODE.SIZE_BDIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ]

static func rectSign(rect:Rect2, point:Vector2) -> Vector2: # the "sign" of a point minus a rectangle, ie. where it is in relation
	var signX:float = 0
	var signY:float = 0
	if point.x < rect.position.x: signX = -1
	if point.x >= rect.end.x: signX = 1
	if point.y < rect.position.y: signY = -1
	if point.y >= rect.end.y: signY = 1
	return Vector2(signX, signY)

func scrollIntoView(component:GameComponent) -> void:
	var rect:Rect2 = Rect2(component.getDrawPosition()-Vector2(16,16), component.size+Vector2(32,32))
	var screenRect:Rect2 = Rect2(screenspaceToWorldspace(gameCont.position), gameCont.size/editorCamera.zoom)
	if rect.size.x > screenRect.size.x: zoomCamera(0.8**ceil(log(screenRect.size.x/rect.size.x)/-0.2231435513))
	if rect.size.y > screenRect.size.y: zoomCamera(0.8**ceil(log(screenRect.size.y/rect.size.y)/-0.2231435513))
	editorCamera.zoom = Vector2(targetCameraZoom,targetCameraZoom)
	screenRect = Rect2(screenspaceToWorldspace(gameCont.position), gameCont.size/editorCamera.zoom)
	editorCamera.position = editorCamera.position.clamp(rect.end-screenRect.size, rect.position)

func _toggleSettingsMenu(toggled_on:bool) -> void:
	%toggleSettingsMenu.button_pressed = toggled_on
	quickSet.applyOrCancel()
	%settingsMenu.visible = toggled_on
	%settingsText.visible = toggled_on
	%explainText.visible = !toggled_on
	settingsOpen = toggled_on
	get_tree().call_group(&"hotkeyButton", &"queue_redraw")
	topBar._updateButtons()
	if toggled_on:
		%settingsMenu.opened()
		%settingsMenu.grab_focus()
	else:
		%settingsMenu.closed()
		grab_focus()
	updateDescription()

func updateDescription() -> void:
	%description.visible = (settingsOpen and settingsMenu.levelSettings.visible) or (Game.playState == Game.PLAY_STATE.PLAY and %levelDescription.text != "")
	%levelDescription.text = Game.level.description
	%levelShortNumber.text = Game.level.shortNumber
	%levelDescription.editable = settingsOpen
	%levelShortNumber.editable = settingsOpen

func _levelDescriptionSet() -> void:
	Game.level.description = %levelDescription.text
	Game.anyChanges = true

func _draw() -> void:
	RenderingServer.canvas_item_clear(drawDescription)
	RenderingServer.canvas_item_clear(drawMain)
	RenderingServer.canvas_item_clear(drawAutoRunGradient)
	TextDraw.outlinedCentered(Game.FROOMNUM,drawDescription,"PUZZLE",Color("#d6cfc9"),Color("#3e2d1c"),20,Vector2(728,27))
	TextDraw.outlinedCentered(Game.FROOMNUM,drawDescription,%levelShortNumber.text,Color("#8c50c8"),Color("#140064"),20,Vector2(728,57))
	var autoRunAlpha:float = abs(sin(autoRunTimer*PI))
	if autoRunAlpha > 0:
		TextDraw.outlinedGradient(Game.FMINIID,drawMain,drawAutoRunGradient,
			"[E] Auto-Run is " + ("on" if Game.autoRun else "off"),
			Color(Color("#e6ffe6") if Game.autoRun else Color("#dcffe6"),autoRunAlpha),
			Color(Color("#e6c896") if Game.autoRun else Color("#64dc8c"),autoRunAlpha),
			Color(Color.BLACK,autoRunAlpha),12,Vector2(4,20)
		)

func _levelShortNumberSet(string:String) -> void:
	Game.level.shortNumber = string
	queue_redraw()

func autoRun() -> void:
	Game.autoRun = !Game.autoRun
	AudioManager.play(preload("res://resources/sounds/autoRun.wav")).pitch_scale = 1.0 if Game.autoRun else 0.7
	autoRunTimer = 0
	%settingsMenu.gameSettings.closed(%settingsMenu.configFile)
	%settingsMenu.configFile.save("user://config.ini")
