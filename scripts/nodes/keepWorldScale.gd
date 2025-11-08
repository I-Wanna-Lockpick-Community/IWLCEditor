extends Control
class_name KeepWorldScale

@onready var editor:Editor = get_node("/root/editor")

func _process(_delta):
	if Game.playState == Game.PLAY_STATE.PLAY: scale = editor.playCamera.zoom
	else: scale = editor.editorCamera.zoom
