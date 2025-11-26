extends VBoxContainer
class_name ModTreeSubTree

const EXPANDED:DPITexture = preload("res://resources/modTree/expanded.tres")
const COLLAPSED:DPITexture = preload("res://resources/modTree/collapsed.tres")

var selectMods:SelectMods

@onready var cont:VBoxContainer = %cont

var subTree:SelectMods.SubTree

func _ready() -> void:
	%button.text = subTree.label

func _toggled(toggled_on:bool) -> void:
	%c.visible = toggled_on
	%button.icon = EXPANDED if toggled_on else COLLAPSED

func _hover() -> void:
	selectMods._treeItemHovered(self)

func _unhover() -> void:
	selectMods._treeItemUnhovered(self)
