extends Selector
class_name KeyRotorSelector

const VALUES:int = 3
enum VALUE {SIGNFLIP, POSROTOR, NEGROTOR}

const ICONS:Array[Texture2D] = [
	preload("res://assets/ui/focusDialog/keySplitType/signflip.png"),
	preload("res://assets/ui/focusDialog/keySplitType/posrotor.png"),
	preload("res://assets/ui/focusDialog/keySplitType/negrotor.png"),
]

func _ready() -> void:
	columns = VALUES
	options = range(VALUES)
	defaultValue = VALUE.SIGNFLIP
	buttonType = KeyRotorSelectorButton
	super()

func setValue(count:C) -> void:
	if count.eq(-1): setSelect(VALUE.SIGNFLIP)
	elif count.eq(C.I): setSelect(VALUE.POSROTOR)
	elif count.eq(C.nI): setSelect(VALUE.NEGROTOR)

class KeyRotorSelectorButton extends SelectorButton:
	var drawMain:RID

	func _init(_value:VALUE, _selector:KeyRotorSelector):
		custom_minimum_size = Vector2(16,16)
		z_index = 1
		super(_value, _selector)
		icon = ICONS[value]
