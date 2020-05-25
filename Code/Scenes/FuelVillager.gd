extends TextureProgress

var player

func _ready():
	player = get_parent().get_parent()
	max_value = player.MAX_FUEL

func _process(delta):
	value = player.fuel
