extends Control
class_name FocusDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var colorLink:Button = %colorLink

@onready var keyDialog:KeyDialog = %keyDialog
@onready var doorDialog:DoorDialog = %doorDialog
@onready var playerDialog:PlayerDialog = %playerDialog
@onready var keyCounterDialog:KeyCounterDialog = %keyCounterDialog
@onready var goalDialog:GoalDialog = %goalDialog

var focused:GameObject # the object that is currently focused
var componentFocused:GameComponent # you can focus both a door and a lock at the same time so
var interacted:PanelContainer # the number edit that is currently interacted

var above:bool = false # display above the object instead

func _ready() -> void:
	get_tree().call_group("modUI", "changedMods")

func focus(object:GameObject, dontRedirect:bool=false) -> void:
	var new:bool = object != focused
	focused = object
	editor.game.objectsParent.move_child(focused, -1)
	showCorrectDialog()
	if new: deinteract()
	if focused is KeyBulk: keyDialog.focus(focused, new)
	elif focused is Door or focused is RemoteLock: doorDialog.focus(focused, new, dontRedirect)
	elif focused is PlayerSpawn: playerDialog.focus(focused, new)
	elif focused is KeyCounter: keyCounterDialog.focus(focused, new, dontRedirect)
	elif focused is Goal: goalDialog.focus(focused, new)

func showCorrectDialog() -> void:
	%keyDialog.visible = focused is KeyBulk
	%doorDialog.visible = focused is Door or focused is RemoteLock
	%playerDialog.visible = focused is PlayerSpawn
	%keyCounterDialog.visible = focused is KeyCounter
	%goalDialog.visible = focused is Goal
	above = focused is KeyCounter # maybe add more later
	%speechBubbler.rotation_degrees = 0 if above else 180

func defocus() -> void:
	if !focused: return
	var object:GameObject = focused
	editor.quickSet.applyOrCancel()
	if object is Door and !Mods.active(&"ZeroCopies") and object.copies.eq(0): Changes.addChange(Changes.PropertyChange.new(editor.game,object,&"copies",C.new(1)))
	focused = null
	if object is RemoteLock: object.queue_redraw()
	deinteract()
	defocusComponent()

func focusComponent(component:GameComponent) -> void:
	var new:bool = component != componentFocused
	componentFocused = component
	if focused != component.parent: focus(component.parent)
	if component is Lock: doorDialog.focusComponent(component, new)
	elif component is KeyCounterElement: keyCounterDialog.focusComponent(component, new)

func defocusComponent() -> void:
	if !componentFocused: return
	if componentFocused is Lock and !Mods.active(&"ZeroCostLock") and !(Mods.active(&"C3") and componentFocused.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]) and componentFocused.count.eq(0): Changes.addChange(Changes.PropertyChange.new(editor.game,componentFocused,&"count",C.new(1)))
	componentFocused = null
	deinteract()

func interact(edit:PanelContainer) -> void:
	deinteract()
	edit.theme_type_variation = &"NumberEditPanelContainerNewlyInteracted"
	interacted = edit
	edit.newlyInteracted = true

func deinteract() -> void:
	if !interacted: return
	interacted.theme_type_variation = &"NumberEditPanelContainer"
	if interacted is NumberEdit: interacted.bufferedNegative = false
	elif interacted is AxialNumberEdit: interacted.bufferedSign = C.ONE
	interacted.setValue(interacted.value,true)
	interacted = null

func interactDoorFirstEdit() -> void:
	defocusComponent()
	focus(focused)

func interactDoorLastEdit() -> void:
	defocusComponent()
	focus(focused)
	interact(%doorCopiesEdit.imaginaryEdit)

func interactLockFirstEdit(index:int) -> void:
	focusComponent(focused.locks[index])

func interactLockLastEdit(index:int) -> void:
	focusComponent(focused.locks[index])
	if componentFocused.type in [Lock.TYPE.NORMAL, Lock.TYPE.EXACT]: interact(%doorAxialNumberEdit)
	elif componentFocused.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]:
		if componentFocused.isPartial: interact(%partialBlastDenominatorEdit.imaginaryEdit)
		else: interact(%partialBlastNumeratorEdit.imaginaryEdit)
	else: deinteract()

func tabbed(numberEdit:PanelContainer) -> void:
	editor.grab_focus()
	if Input.is_key_pressed(KEY_SHIFT):
		match numberEdit.purpose:
			NumberEdit.PURPOSE.IMAGINARY: interact(numberEdit.get_parent().realEdit)
			NumberEdit.PURPOSE.REAL:
				if focused is KeyBulk:
					interact(%keyCountEdit.imaginaryEdit)
				elif focused is Door:
					if numberEdit == %doorCopiesEdit.realEdit:
						if len(focused.locks) > 0: interactLockLastEdit(-1)
						else: interactDoorLastEdit()
					elif numberEdit == %partialBlastDenominatorEdit.realEdit:
						interact(%partialBlastNumeratorEdit.imaginaryEdit)
					elif numberEdit == %partialBlastNumeratorEdit.realEdit:
						if componentFocused.index == 0: interactDoorLastEdit()
						else: interactLockLastEdit(componentFocused.index-1)
			NumberEdit.PURPOSE.AXIAL:
				assert(componentFocused)
				if componentFocused.index == 0: interactDoorLastEdit()
				else: interactLockLastEdit(componentFocused.index-1)
	else:
		match numberEdit.purpose:
			NumberEdit.PURPOSE.REAL:
				interact(numberEdit.get_parent().imaginaryEdit)
			NumberEdit.PURPOSE.IMAGINARY:
				if focused is KeyBulk:
					interact(%keyCountEdit.realEdit)
				elif focused is Door:
					if numberEdit == %doorCopiesEdit.imaginaryEdit:
						if len(focused.locks) > 0: interactLockFirstEdit(0)
						else: interactDoorFirstEdit()
					elif numberEdit == %partialBlastNumeratorEdit.imaginaryEdit and componentFocused.isPartial:
						interact(%partialBlastDenominatorEdit.realEdit)
					elif numberEdit in [%partialBlastNumeratorEdit.imaginaryEdit, %partialBlastDenominatorEdit.imaginaryEdit]:
						if componentFocused.index == len(focused.locks) - 1: interactDoorFirstEdit()
						else: interactLockFirstEdit(componentFocused.index+1)
			NumberEdit.PURPOSE.AXIAL:
				assert(componentFocused)
				if componentFocused.index == len(focused.locks) - 1: interactDoorFirstEdit()
				else: interactLockFirstEdit(componentFocused.index+1)

func receiveKey(event:InputEvent) -> bool:
	if focused is KeyBulk: return keyDialog.receiveKey(event)
	elif focused is Door or focused is RemoteLock: return doorDialog.receiveKey(event)
	elif focused is KeyCounter: return keyCounterDialog.receiveKey(event)
	else:
		match event.keycode:
			KEY_DELETE:
				Changes.addChange(Changes.DeleteComponentChange.new(editor.game,focused))
				Changes.bufferSave()
			_: return false
	return true

func _process(_delta:float) -> void:
	if focused:
		visible = true
		if above: position = editor.worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,0)) + Vector2(0,-8)
		else: position = editor.worldspaceToScreenspace(focused.getDrawPosition() + Vector2(focused.size.x/2,focused.size.y)) + Vector2(0,8)
		var halfWidth:float = getWidth()/2
		%speechBubbler.position.x = 0
		if position.x < halfWidth:
			%speechBubbler.position.x = max(position.x-halfWidth,10-halfWidth)
			position.x = halfWidth
		if position.x + halfWidth > editor.gameViewportCont.size.x:
			%speechBubbler.position.x = min(position.x+halfWidth-editor.gameViewportCont.size.x,halfWidth-10)
			position.x = editor.gameViewportCont.size.x - halfWidth
	else:
		visible = false

func getWidth() -> float:
	match focused.get_script():
		KeyBulk: return keyDialog.get_child(0).size.x
		Door: return doorDialog.get_child(0).size.x
		Player: return playerDialog.get_child(0).size.x
		KeyCounter: return keyCounterDialog.get_child(0).size.x
		Goal: return goalDialog.get_child(0).size.x
		_: return 0

func focusHandlerAdded(type:GDScript, index:int) -> void:
	match type:
		Lock:
			%lockHandler.addButton(index)
			focusComponent(focused.locks[index])
		KeyCounterElement:
			%keyCounterHandler.addButton(index)
			focusComponent(focused.elements[index])
		Door: %doorsHandler.addButton(index,false)

func focusHandlerRemoved(type:GDScript, index:int) -> void:
	match type:
		Lock:
			%lockHandler.removeButton(index)
			if index != 0: focusComponent(focused.locks[index-1])
			elif len(focused.locks) > 0: focusComponent(focused.locks[0])
		KeyCounterElement:
			%keyCounterHandler.removeButton(index)
			if index != 0: focusComponent(focused.elements[index-1])
			elif len(focused.elements) > 0: focusComponent(focused.elements[0])
		Door: %doorsHandler.removeButton(index,false)
