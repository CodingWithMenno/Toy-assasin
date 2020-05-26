extends KinematicBody

var player

func _ready():
	player = get_node("./VillagerFox")

func _physics_process(delta):
	if player.isInDrone:
		$Camera.current = true
		pass
