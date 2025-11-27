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

enum DRAG_MODE {POSITION, SIZE_DIAG, SIZE_VERT, SIZE_HORIZ}
enum SIZE_DRAG_PIVOT {TOP_LEFT, TOP, TOP_RIGHT, LEFT, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT, NONE}
const SIZE_DRAG_DIRECTIONS:Array[Vector2] = [Vector2(-1,-1), Vector2(0,-1), Vector2(1,-1), Vector2(-1,0), Vector2(1,0), Vector2(-1,1), Vector2(0,1), Vector2(1,1), Vector2(0,0)]
var componentDragged:GameComponent
var dragMode:DRAG_MODE
var dragPivotRect:Rect2 # the pivot for size dragging
var dragHandlePosition:Vector2
var previousDragPosition:Vector2i
var dragHandle:Vector2 # direction of the handle (initially), so that size_vert and size_horiz behave as they do

var lockBufferConvert:bool = false
var connectionSource:GameObject # for pulling connections between remote locks and doors

var tileSize:Vector2i = Vector2i(32,32)

var cameraZoom:float = 1

var settingsOpen:bool = false

var drawDescription:RID
var drawMain:RID
var drawAutoRunGradient:RID
var autoRunTimer:float = 2

var screenshot:Image

func _ready() -> void:
	Changes.editor = self
	Mods.editor = self
	Saving.editor = self
	Explainer.editor = self
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
	Saving.editorReady()
	if OS.has_feature('web'):
		%fileMenu.menu.remove_item(5)
		%fileMenu.menu.remove_item(3)
	%screenshotViewport.world_2d = %gameViewport.world_2d

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
	mouseTilePosition = Vector2i(floor(mouseWorldPosition / Vector2(tileSize))) * tileSize
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
				if Rect2(object.getDrawPosition(), object.size).has_point(mouseWorldPosition) and (Game.playState != Game.PLAY_STATE.PLAY or object.active):
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
					DRAG_MODE.SIZE_DIAG:
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
			if componentDragged: dragComponent(); return
			# other
			var inBounds:bool = Mods.active(&"OutOfBounds") or Game.levelBounds.has_point(mouseTilePosition)
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
					if inBounds:
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
						if objectHovered is not KeyBulk and inBounds:
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
							if objectHovered is not Door and inBounds:
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
						if (!objectHovered or objectHovered.get_script() != otherObjects.selected) and inBounds:
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
	dragMode = DRAG_MODE.POSITION
	previousDragPosition = mouseTilePosition

func startSizeDrag(component:GameComponent, handle:Vector2=Vector2(1,1)) -> void:
	focusDialog.defocus()
	componentDragged = component
	var minSize:Vector2
	if component is Door: minSize = Vector2(32,32)
	elif component is Lock or component is RemoteLock: minSize = Vector2(18,18)
	elif component is KeyCounter: minSize = Vector2(107,63)
	if handle.x and handle.y: dragMode = DRAG_MODE.SIZE_DIAG
	elif handle.x: dragMode = DRAG_MODE.SIZE_HORIZ; minSize.y = componentDragged.size.y
	elif handle.y: dragMode = DRAG_MODE.SIZE_VERT; minSize.x = componentDragged.size.x
	
	var parentPosition:Vector2i = component.parent.position if component.get_script() in Game.NON_OBJECT_COMPONENTS else Vector2i.ZERO
	dragPivotRect = Rect2(component.position + (component.size - minSize) * Vector2.ZERO.max(-handle), minSize)
	dragHandlePosition = mouseTilePosition - parentPosition
	previousDragPosition = mouseTilePosition
	dragHandle = handle

func dragComponent() -> void: # returns whether or not an object is being dragged, for laziness
	var dragOffset:Vector2 = mouseTilePosition - previousDragPosition
	lockBufferConvert = false # whether or not to buffer a conversion to remotelock
	var bounds:Rect2
	var allowOutOfBounds:bool = Mods.active(&"OutOfBounds")
	if componentDragged is Lock:
		allowOutOfBounds = (Mods.active(&"C1") and dragMode == DRAG_MODE.POSITION) or Mods.active(&"DisconnectedLock")
		bounds = Rect2(componentDragged.getOffset(), componentDragged.parent.size)
	else: bounds = Game.levelBounds
	var innerBounds:Rect2 = bounds.grow(-1) # require strictly within
	match dragMode:
		DRAG_MODE.POSITION:
			if componentDragged is KeyCounterElement:
				var dragPosition = mouseWorldPosition - Vector2(0,20)
				if componentDragged.index > 0 and (componentDragged.getDrawPosition()).y - dragPosition.y >= 20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index-1)
				elif componentDragged.index < len(componentDragged.parent.elements) - 1 and (componentDragged.getDrawPosition()).y - dragPosition.y <= -20:
					componentDragged.parent._swapElements(componentDragged.index, componentDragged.index+1)
			else:
				var goingTo:Rect2 = Rect2(componentDragged.position + dragOffset, componentDragged.size)
				if !bounds.intersects(goingTo):
					if !allowOutOfBounds:
						dragOffset += snappedAway(Vector2.ZERO.max(innerBounds.position - goingTo.end) - Vector2.ZERO.max(goingTo.position - innerBounds.end), Vector2(tileSize))
					elif componentDragged is Lock and Mods.active(&"C1"): lockBufferConvert = true
				previousDragPosition += Vector2i(dragOffset)
				Changes.addChange(Changes.PropertyChange.new(componentDragged,&"position", componentDragged.position + dragOffset))
		DRAG_MODE.SIZE_DIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ:
			dragHandlePosition += dragOffset
			var toPosition:Vector2 = dragPivotRect.position
			# dragging up/left
			toPosition += snappedTrunc(dragHandlePosition - dragPivotRect.position, Vector2(tileSize)) * Vector2.ZERO.max(sign(dragPivotRect.position - dragHandlePosition))
			# dragging down/right (we add another tileSize because itd otherwise be at the top left corner)
			toPosition += (dragPivotRect.size + snappedTrunc(dragHandlePosition - dragPivotRect.end, Vector2(tileSize)) + Vector2(tileSize)) * Vector2.ZERO.max(sign(dragHandlePosition - dragPivotRect.position))

			# keep in bounds
			var effectiveDragPivotRect:Rect2 = dragPivotRect
			if !allowOutOfBounds:
				effectiveDragPivotRect = effectiveDragPivotRect.expand(dragPivotRect.position + snappedAway(Vector2.ZERO.max(innerBounds.position - dragPivotRect.position) - Vector2.ZERO.max(dragPivotRect.position - innerBounds.end), Vector2(tileSize)))

			# keycounter has only a few possible widths
			if componentDragged is KeyCounter:
				toPosition -= effectiveDragPivotRect.position
				if toPosition.x <= effectiveDragPivotRect.size.x - KeyCounter.WIDTHS[2]: toPosition.x = effectiveDragPivotRect.size.x - KeyCounter.WIDTHS[2]
				elif toPosition.x <= effectiveDragPivotRect.size.x - KeyCounter.WIDTHS[1]: toPosition.x = effectiveDragPivotRect.size.x - KeyCounter.WIDTHS[1]
				elif toPosition.x >= KeyCounter.WIDTHS[2]: toPosition.x = KeyCounter.WIDTHS[2]
				elif toPosition.x >= KeyCounter.WIDTHS[1]: toPosition.x = KeyCounter.WIDTHS[1]
				else: toPosition.x = 0
				toPosition.y = 0
				toPosition += effectiveDragPivotRect.position
				if effectiveDragPivotRect.grow(-1).has_point(toPosition):
					previousDragPosition += Vector2i(dragOffset)
					return

			var toRect:Rect2 = effectiveDragPivotRect.expand(toPosition)
			if componentDragged is Door:
				for lock in componentDragged.locks:
					var doorInnerBounds:Rect2 = Rect2(lock.getOffset(), componentDragged.size).grow(-1)
					var lockGoingTo:Rect2 = Rect2(lock.position-toRect.position+componentDragged.position, lock.size) # keep relative position even if the door moves
					lockGoingTo.position += snappedAway(Vector2.ZERO.max(doorInnerBounds.position - lockGoingTo.end) - Vector2.ZERO.max(lockGoingTo.position - doorInnerBounds.end), Vector2(tileSize)) # keep in bounds
					Changes.addChange(Changes.PropertyChange.new(lock,&"position",lockGoingTo.position))
			previousDragPosition += Vector2i(dragOffset)
			Changes.addChange(Changes.PropertyChange.new(componentDragged,&"position",toRect.position))
			Changes.addChange(Changes.PropertyChange.new(componentDragged,&"size",toRect.size))

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
			if event.is_action_pressed(&"editStartPlaytest") and !topBar.play.disabled: await get_tree().process_frame; Game.playTest(Game.levelStart)
			elif event.is_action_pressed(&"editStartPlaytestFromState") and !topBar.play.disabled: await get_tree().process_frame; Game.playTest(Game.latestSpawn)
			elif event.is_action_pressed(&"editStopPlaytest") and Game.playstate == Game.PLAY_STATE.PAUSED: Game.stopTest()
			elif event.is_action_pressed(&"editModeSelect"): modes.setMode(MODE.SELECT); focusDialog.defocus(); componentDragged = null; multiselect.deselect()
			elif event.is_action_pressed(&"editModeTile"): modes.setMode(MODE.TILE)
			elif event.is_action_pressed(&"editModeKey"): modes.setMode(MODE.KEY)
			elif event.is_action_pressed(&"editModeDoor"): modes.setMode(MODE.DOOR)
			elif event.is_action_pressed(&"editModeOther"): modes.setMode(MODE.OTHER)
			elif event.is_action_pressed(&"editObjectSearch"): otherObjects.objectSearch.grab_focus()
			elif event.is_action_pressed(&"editOpenSettings"): _toggleSettingsMenu(true)
			elif event.is_action_pressed(&"editNew"): Saving.confirmAction = Saving.ACTION.NONE; Saving.new()
			elif event.is_action_pressed(&"editOpen"): Saving.open()
			elif event.is_action_pressed(&"editSave"): Saving.confirmAction = Saving.ACTION.NONE; Saving.save()
			elif event.is_action_pressed(&"editSaveAs"):
				Saving.confirmAction = Saving.ACTION.NONE
				if OS.has_feature('web'): Saving.save()
				else: Saving.saveAs()
			elif event.is_action_pressed(&"editExport"): pass
			elif event.is_action_pressed(&"editHome"): home()
			elif event.is_action_pressed(&"editCopy"): multiselect.copySelection()
			elif event.is_action_pressed(&"editCut"): multiselect.copySelection(); multiselect.delete()
			elif event.is_action_pressed(&"editPaste") and multiselect.clipboard != []: modes.setMode(MODE.PASTE)
			elif event.is_action_pressed(&"editUndo"): Changes.undo()
			elif event.is_action_pressed(&"editRedo"): Changes.redo()
			elif event.is_action_pressed(&"editDrag"):
				if focusDialog.componentFocused: startPositionDrag(focusDialog.componentFocused)
				elif focusDialog.focused: startPositionDrag(focusDialog.focused)
			elif event.is_action_pressed(&"editDelete"): multiselect.delete()
			match event.keycode:
				KEY_TAB: grab_focus()
				KEY_F2: takeScreenshot()

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

func sizeDragging() -> bool: return dragMode in [DRAG_MODE.SIZE_DIAG, DRAG_MODE.SIZE_VERT, DRAG_MODE.SIZE_HORIZ]

static func rectSign(rect:Rect2, point:Vector2) -> Vector2: # the "sign" of a point minus a rectangle, ie. where it is in relation
	var signX:float = 0
	var signY:float = 0
	if point.x < rect.position.x: signX = -1
	if point.x >= rect.end.x: signX = 1
	if point.y < rect.position.y: signY = -1
	if point.y >= rect.end.y: signY = 1
	return Vector2(signX, signY)

static func snappedAway(vector:Variant, to:Variant) -> Variant: # snap, round away from 0
	return sign(vector) * ceil(abs(vector)/to)*to

static func snappedTrunc(vector:Variant, to:Variant) -> Variant: # snap, round towards 0
	return sign(vector) * floor(abs(vector)/to)*to

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
	AudioManager.play(preload("res://resources/sounds/autoRun.wav"), 1.0, 1.0 if Game.autoRun else 0.7)
	autoRunTimer = 0
	%settingsMenu.gameSettings.closed(%settingsMenu.configFile)
	%settingsMenu.configFile.save("user://config.ini")

func takeScreenshot() -> void:
	screenshot = %screenshotViewport.get_texture().get_image()
	screenshot.resize(200,152)
