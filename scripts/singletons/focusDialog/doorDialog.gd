extends Control
class_name DoorDialog

@onready var editor:Editor = get_node("/root/editor")
@onready var main:FocusDialog = get_parent()

@onready var lockHandler:LockHandler = %lockHandler

func focus(focused:Door, new:bool, dontRedirect:bool) -> void:
	%doorTypes.get_child(focused.type).button_pressed = true
	%lockHandler.colorLink.visible = focused.type == Door.TYPE.SIMPLE
	%spend.queue_redraw()
	%lockConfigurationSelector.visible = main.componentFocused and focused.type != Door.TYPE.SIMPLE
	%doorColorSelector.visible = main.componentFocused or focused.type != Door.TYPE.GATE # a mod will probably add something so i wont turn off the menu completely
	%frozen.button_pressed = focused.frozen
	%crumbled.button_pressed = focused.crumbled
	%painted.button_pressed = focused.painted
	if !main.componentFocused:
		%lockSettings.visible = false
		%doorAxialNumberEdit.visible = false
		%doorAuraSettings.visible = focused.type != Door.TYPE.GATE
		%doorComplexNumberEdit.visible = focused.type != Door.TYPE.GATE
		%doorColorSelector.setSelect(focused.colorSpend)
		%doorComplexNumberEdit.setValue(focused.copies, true)
		%spend.button_pressed = true
		%blastLockSettings.visible = false
	if main.interacted and !main.interacted.is_visible_in_tree(): main.deinteract()
	if %doorComplexNumberEdit.visible:
		if !main.interacted: main.interact(%doorComplexNumberEdit.realEdit)
	elif %doorAxialNumberEdit.visible:
		if !main.interacted: main.interact(%doorAxialNumberEdit)
	else: main.deinteract()
	if new:
		%lockHandler.setup(focused)
		if focused.type == Door.TYPE.SIMPLE and !dontRedirect: main.focusComponent(focused.locks[0])

func focusComponent(component:Lock, _new:bool) -> void:
	%doorColorSelector.visible = true
	%doorColorSelector.setSelect(component.color)
	%lockHandler.setSelect(component.index)
	%lockTypeSelector.setSelect(component.type)
	%lockConfigurationSelector.visible = main.focused.type != Door.TYPE.SIMPLE
	%lockConfigurationSelector.setup(component)
	%lockSettings.visible = true
	
	%doorAxialNumberEdit.visible = component.type == Lock.TYPE.NORMAL or component.type == Lock.TYPE.EXACT
	%doorAxialNumberEdit.setValue(component.count, true)

	%doorComplexNumberEdit.visible = false
	%doorAuraSettings.visible = false

	%blastLockSettings.visible = component.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]
	%blastLockSign.button_pressed = component.denominator.sign() < 0
	%blastLockAxis.button_pressed = component.denominator.isNonzeroImag()
	
	%partialBlastSettings.visible = mods.active(&"C3")
	%isPartial.visible = mods.active(&"C3")
	%isPartial.button_pressed = component.isPartial
	%partialDenominator.visible = component.isPartial
	%discreteBlastSettings.visible = !component.isPartial and component.type != Lock.TYPE.ALL
	%partialBlastNumeratorEdit.setValue(component.count, true)
	%partialBlastDenominatorEdit.setValue(component.denominator, true)

	%lockHandler.redrawButton(component.index)
	%lockNegated.button_pressed = component.negated
	if main.interacted and !main.interacted.is_visible_in_tree(): main.deinteract()
	if %doorAxialNumberEdit.visible:
		if !main.interacted: main.interact(%doorAxialNumberEdit)
	elif %partialBlastSettings.visible:
		print("here")
		if !main.interacted: main.interact(%partialBlastNumeratorEdit.realEdit)
	else: main.deinteract()

func receiveKey(event:InputEvent) -> bool:
	match event.keycode:
		KEY_N: _lockTypeSelected(Lock.TYPE.NORMAL)
		KEY_B: _lockTypeSelected(Lock.TYPE.BLANK)
		KEY_X: _lockTypeSelected(Lock.TYPE.BLAST)
		KEY_A: _lockTypeSelected(Lock.TYPE.ALL)
		KEY_E: if mods.active(&"C3"): _lockTypeSelected(Lock.TYPE.EXACT)
		KEY_N: if mods.active(&"C1"): _lockNegatedSet(!%lockNegated.button_pressed)
		KEY_C:
			if main.componentFocused: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, main.componentFocused)
			else: editor.quickSet.startQuick(QuickSet.QUICK.COLOR, main.focused)
		KEY_L: if Input.is_key_pressed(KEY_CTRL): main.focused.addLock()
		KEY_DELETE:
			if main.componentFocused:
				main.focused.removeLock(main.componentFocused.index)
				if len(main.focused.locks) != 0: main.focusComponent(main.focused.locks[-1])
				else: main.focus(main.focused)
			else: changes.addChange(Changes.DeleteComponentChange.new(editor.game,main.focused))
			changes.bufferSave()
		KEY_TAB:
			assert(main.componentFocused) # should be handled by interact otherwise
			if Input.is_key_pressed(KEY_SHIFT):
				if main.componentFocused.index == 0: main.interactDoorLastEdit()
				else: main.interactLockLastEdit(main.componentFocused.index-1)
			else:
				if main.componentFocused.index == len(main.componentFocused.parent.locks)-1: main.interactDoorFirstEdit()
				else: main.interactLockFirstEdit(main.componentFocused.index+1)
		_: return false
	return true

func changedMods() -> void:
	%lockSettingsSep.visible = mods.active(&"C1")
	%lockNegated.visible = mods.active(&"C1")
	if main.componentFocused and main.componentFocused.type in [Lock.TYPE.BLAST, Lock.TYPE.ALL]:
		main.focusComponent(main.componentFocused)

func _doorColorSelected(color:Game.COLOR) -> void:
	if main.focused is not Door: return
	if main.componentFocused:
		changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"color",color))
	elif %lockHandler.colorLink.button_pressed and main.focused.type == Door.TYPE.SIMPLE:
		changes.addChange(Changes.PropertyChange.new(editor.game,main.focused.locks[0],&"color",color))
	if !main.componentFocused or (%lockHandler.colorLink.button_pressed and main.focused.type == Door.TYPE.SIMPLE):
		changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"colorSpend",color))
	changes.bufferSave()

func _doorComplexNumberSet(value:C) -> void:
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"copies",value))
	changes.bufferSave()

func _doorAxialNumberSet(value:C) -> void:
	if main.componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"count",value))
	changes.bufferSave()

func _lockTypeSelected(type:Lock.TYPE) -> void:
	if main.componentFocused is not Lock: return
	main.componentFocused._setType(type)

func _doorTypeSelected(type:Door.TYPE) -> void:
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"type",type))
	changes.bufferSave()

func _spendSelected() -> void:
	main.defocusComponent()
	main.focus(main.focused)

func _lockConfigurationSelected(option:ConfigurationSelector.OPTION) -> void:
	if main.componentFocused is not Lock: return
	match option:
		ConfigurationSelector.OPTION.SpecificA:
			var configuration:Array = main.componentFocused.getAvailableConfigurations()[0]
			main.componentFocused._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.SpecificB:
			var configuration:Array = main.componentFocused.getAvailableConfigurations()[1]
			main.componentFocused._comboDoorConfigurationChanged(configuration[0], configuration[1])
		ConfigurationSelector.OPTION.AnyS: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyS)
		ConfigurationSelector.OPTION.AnyH: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyH)
		ConfigurationSelector.OPTION.AnyV: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyV)
		ConfigurationSelector.OPTION.AnyM: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyM)
		ConfigurationSelector.OPTION.AnyL: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyL)
		ConfigurationSelector.OPTION.AnyXL: main.componentFocused._comboDoorConfigurationChanged(Lock.SIZE_TYPE.AnyXL)
	changes.bufferSave()

func _frozenSet(value:bool) -> void:
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"frozen",value))
	changes.bufferSave()

func _crumbledSet(value:bool) -> void:
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"crumbled",value))
	changes.bufferSave()

func _paintedSet(value:bool) -> void:
	if main.focused is not Door: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.focused,&"painted",value))
	changes.bufferSave()

func _lockNegatedSet(value:bool) -> void:
	if main.componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"negated",value))
	changes.bufferSave()

func partialBlastNumeratorSet(value:C) -> void:
	if main.componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"count",value))
	changes.bufferSave()

func partialBlastDenominatorSet(value:C) -> void:
	if main.componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"denominator",value))
	changes.bufferSave()

func _isPartialSet(value:bool) -> void:
	if main.componentFocused is not Lock: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"isPartial",value))
	changes.bufferSave()

func _blastLockSignSet(value:bool):
	if main.componentFocused is not Lock: return
	if main.componentFocused.denominator.sign() < 0 == value: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"count",main.componentFocused.count.times(-1)))
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"denominator",main.componentFocused.denominator.times(-1)))
	changes.bufferSave()

func _blastLockAxisSet(value:bool):
	if main.componentFocused is not Lock: return
	if main.componentFocused.denominator.isNonzeroImag() == value: return
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"count",main.componentFocused.count.times(C.I if value else C.nI)))
	changes.addChange(Changes.PropertyChange.new(editor.game,main.componentFocused,&"denominator",main.componentFocused.denominator.times(C.I if value else C.nI)))
	changes.bufferSave()
