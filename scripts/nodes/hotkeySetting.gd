extends HBoxContainer
class_name HotkeySetting

@export var label:String
@export var action:StringName
var input:InputEvent

var default:Array[InputEvent]
var buttons:Array[HotkeySettingButton]

func _ready() -> void:
	%label.text = label
	default = InputMap.action_get_events(action)
	for event in InputMap.action_get_events(action):
		var button:HotkeySettingButton = HotkeySettingButton.new(self)
		button.event = event
		%buttons.add_child(button)
		buttons.append(button)

func _hover() -> void: %label.add_theme_color_override("font_color", Color("#ffffff"))
func _unhover() -> void: %label.add_theme_color_override("font_color", Color("#bfbfbf"))

func _add():
	var button:HotkeySettingButton = HotkeySettingButton.new(self)
	button._startSet()
	%buttons.add_child(button)
	%buttons.move_child(button, 1)
	buttons.append(button)

func updateReset() -> void:
	%reset.disabled = equalToDefault()

func equalToDefault() -> bool:
	var events:Array[InputEvent] = InputMap.action_get_events(action)
	if len(default) != len(events): return false
	for i in len(default):
		if !default[i].is_match(events[i]): return false
	return true

func _reset(to:Array[InputEvent]=default):
	for button in buttons.duplicate(): button.remove()
	buttons.clear()
	InputMap.action_erase_events(action)
	for event in to:
		InputMap.action_add_event(action, event)
		var button:HotkeySettingButton = HotkeySettingButton.new(self)
		button.event = event
		%buttons.add_child(button)
		buttons.append(button)
	updateReset()

class HotkeySettingButton extends Button:
	var hotkey:HotkeySetting
	var event:InputEvent

	var changed:bool = false
	var setting:bool = false # current changing this one
	var conflictingButtons:Array[HotkeySettingButton] = []

	func _init(_hotkey:HotkeySetting) -> void:
		hotkey = _hotkey
		theme_type_variation = &"RadioButtonText"
		custom_minimum_size.x = 150
		toggle_mode = true
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _ready() -> void:
		mouse_entered.connect(func(): if !setting: text = "(RMB to remove)")
		mouse_exited.connect(_cancelSet)
		setText()
	
	func setText() -> void:
		if setting: text = "(Unhover to cancel)"
		else:
			assert(event is InputEventKey)
			text = event.as_text_physical_keycode()
	
	func _startSet() -> void:
		button_pressed = true
		setting = true
		if event: InputMap.action_erase_event(hotkey.action, event)
		setText()
	
	func _cancelSet() -> void:
		button_pressed = false
		setting = false
		if !event: remove()
		else:
			InputMap.action_add_event(hotkey.action, event)
			setText()
		if changed:
			changed = false
			check()

	func _gui_input(_event:InputEvent) -> void:
		if _event is InputEventMouseButton and _event.pressed:
			get_viewport().set_input_as_handled()
			if !setting:
				match _event.button_index:
					MOUSE_BUTTON_LEFT: _startSet()
					MOUSE_BUTTON_RIGHT:
						if event:
							InputMap.action_erase_event(hotkey.action, event)
							check()
						remove()
			else:
				_cancelSet()
 
	func _input(_event:InputEvent) -> void:
		if !setting or _event is InputEventMouse or !_event.pressed: return
		if _event is InputEventKey and _event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]: return
		_event.keycode = 0
		_event.unicode = 0
		_event.pressed = false
		for checkEvent in InputMap.action_get_events(hotkey.action):
			if checkEvent.is_match(_event): return
		event = _event
		changed = true
		get_viewport().set_input_as_handled()
		_cancelSet()

	func remove() -> void:
		mouse_exited.disconnect(_cancelSet) # sneaky
		clearConflicts()
		hotkey.buttons.erase(self)
		queue_free()

	func check() -> void:
		hotkey.updateReset()
		clearConflicts()
		for checkHotkey in hotkey.get_parent().get_children():
			if checkHotkey is not HotkeySetting: continue
			for button in checkHotkey.buttons:
				if button == self: continue
				if button.event.is_match(event):
					conflictingButtons.append(button)
					button.conflictingButtons.append(self)
					theme_type_variation = &"ConflictedHotkeySettingButton"
					button.theme_type_variation = &"ConflictedHotkeySettingButton"

	func clearConflicts() -> void:
		for button in conflictingButtons:
			button.conflictingButtons.erase(self)
			if len(button.conflictingButtons) == 0: button.theme_type_variation = &"RadioButtonText"
		theme_type_variation = &"RadioButtonText"
		conflictingButtons.clear()
