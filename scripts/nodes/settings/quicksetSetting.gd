@abstract
extends GridContainer
class_name QuicksetSetting

var buttonType:GDScript = QuicksetSettingButton

var options:Array[Variant] = []
var buttons:Array[QuicksetSettingButton] = []
var reset:Button

func _ready() -> void:
	self.matches.assign(self.DEFAULT_MATCHES)
	for value in options:
		var button = buttonType.new(value, self)
		add_child(button)
		buttons.append(button)
	reset = Button.new()
	reset.icon = preload("res://assets/ui/settings/resetHotkey.png")
	reset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reset.pressed.connect(setMatches)
	get_parent().add_child.call_deferred(reset)

func setMatches(to:Array[String]=self.DEFAULT_MATCHES.duplicate()) -> void:
	self.matches = to
	for button in buttons: button.setText(); button.check()
	updateReset()

func updateReset() -> void:
	reset.disabled = self.matches == self.DEFAULT_MATCHES

class QuicksetSettingButton extends Button:
	@onready var editor:Editor = get_node("/root/editor")

	var value:int
	var quicksetSetting:QuicksetSetting

	var setting:bool = false
	var changed:bool = false
	var setMatch:Array[String] = []
	var conflictingButtons:Array[QuicksetSettingButton] = []

	func _init(_value:Variant, _quicksetSetting:QuicksetSetting):
		value = _value
		quicksetSetting = _quicksetSetting
		toggle_mode = true
		theme_type_variation = &"RadioButtonText"

	func _ready() -> void:
		mouse_exited.connect(_cancelSet)
		setText()
	
	func setText() -> void:
		if setting: text = "".join(setMatch)
		else: text = quicksetSetting.matches[value]
	
	func _startSet() -> void:
		button_pressed = true
		setting = true
		setMatch = []
		setText()
	
	func _cancelSet() -> void:
		button_pressed = false
		setting = false
		if changed:
			changed = false
			quicksetSetting.matches[value] = "".join(setMatch)
			check()
		setText()
	
	func _gui_input(_event:InputEvent) -> void:
		if _event is InputEventMouseButton and _event.pressed:
			if !setting:
				match _event.button_index:
					MOUSE_BUTTON_LEFT: _startSet()
					MOUSE_BUTTON_RIGHT: quicksetSetting.matches[value] = quicksetSetting.DEFAULT_MATCHES[value]; setText(); check()
					_: return
			else: _cancelSet()
			get_viewport().set_input_as_handled()

	func _input(event:InputEvent) -> void:
		if !setting or event is InputEventMouse or !event.pressed: return
		if event is InputEventKey and event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]: return
		var match:String = char(event.unicode).to_upper()
		setMatch.append(match)
		setMatch.sort()
		changed = true
		setText()
		get_viewport().set_input_as_handled()

	func check() -> void:
		quicksetSetting.updateReset()
		clearConflicts()
		if !visible: return
		for button in quicksetSetting.buttons:
			if button == self or !button.visible: continue
			if quicksetSetting.matches[button.value] == quicksetSetting.matches[value]:
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
