extends Node

@onready var masterBus:int = AudioServer.get_bus_index(&"Master")

func play(stream:AudioStream, gain:float=1, pitchScale:float = 1) -> AudioStreamPlayer:
	var player:AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.finished.connect(player.queue_free)
	player.volume_linear = gain
	player.pitch_scale = pitchScale
	get_tree().get_root().add_child(player)
	player.play()
	return player
