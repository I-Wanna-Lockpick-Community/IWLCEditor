extends RichTextLabel
class_name QuickSet

@onready var editor:Editor = get_node("/root/editor")

var component:GameComponent
var quickType:StringName
var input:String = ""

func startQuick(type:StringName, _component:GameComponent) -> void:
	quickType = type
	component = _component
	visible = true
	%explainText.visible = false
	input = ""
	updateText()

func receiveInput(event:InputEvent) -> void:
	if event.is_action_released(quickType): applyOrCancel()
	elif event is InputEventKey and event.is_pressed() and !event.echo:
		if event.keycode >= 32 and event.keycode < 128:
			input += char(event.unicode).to_upper()
			updateText()

func updateText() -> void:
	text = "Quickset "
	match quickType:
		&"quicksetColor": text += "Color: "
		&"quicksetLockSize": text += "Lock Size: "
	text += input

func applyOrCancel() -> void:
	match quickType:
		&"quicksetColor":
			var found:int = findInputIn(ColorQuicksetSetting.matches)
			if found in Mods.colors():
				match component.get_script():
					KeyBulk: editor.focusDialog.keyDialog._keyColorSelected(found)
					Door, Lock: editor.focusDialog.doorDialog._doorColorSelected(found)
					KeyCounterElement: editor.focusDialog.keyCounterDialog._keyCounterColorSelected(found)
		&"quicksetLockSize":
			var found:int = findInputIn(LockSizeQuicksetSetting.matches)
			if found != -1: editor.focusDialog.doorDialog._lockConfigurationSelected(found)
	visible = false
	%explainText.visible = true
	quickType = &""
	component = null

func findInputIn(matches:Array[String]) -> int:
	var sorted = input.split()
	sorted.sort()
	return matches.find("".join(sorted))
