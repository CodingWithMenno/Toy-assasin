extends KinematicBody

var player
var mouseSensitivity = 0.3

var velocity = Vector3()
const SPEED = 750
const ROTATION_SPEED = 0.05

func _ready():
	player = get_node("../VillagerFox")
	translation = Vector3(player.translation.x, player.translation.y + 5, player.translation.z)
	$Orientation/Camera.current = true

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouseSensitivity))

func _physics_process(delta):
	var orientationTransform = $Orientation.get_global_transform()
	var direction = Vector3()
	var hasMovedZ = false
	var hasMovedX = false
	
	if Input.is_action_pressed("w"):
		direction += orientationTransform.basis[0]
		$Cube.rotation.z = lerp($Cube.rotation.z, -0.4, ROTATION_SPEED)
		hasMovedZ = true
	if Input.is_action_pressed("s"):
		direction += -orientationTransform.basis[0]
		$Cube.rotation.z = lerp($Cube.rotation.z, 0.1, ROTATION_SPEED)
		hasMovedZ = true
	if Input.is_action_pressed("a"):
		direction += -orientationTransform.basis[2]
		$Cube.rotation.x = lerp($Cube.rotation.x, -0.2, ROTATION_SPEED)
		hasMovedX = true
	if Input.is_action_pressed("d"):
		direction += orientationTransform.basis[2]
		$Cube.rotation.x = lerp($Cube.rotation.x, 0.2, ROTATION_SPEED)
		hasMovedX = true
	
	if not hasMovedX:
		$Cube.rotation.x = lerp($Cube.rotation.x, 0, ROTATION_SPEED)
	if not hasMovedZ:
		$Cube.rotation.z = lerp($Cube.rotation.z, -0.2, ROTATION_SPEED)
	
	direction = direction.normalized()
	
	if Input.is_action_pressed("spacebar"):
		direction.y += 0.5
	if Input.is_action_pressed("shift"):
		direction.y -= 0.5
	
	velocity = move_and_slide(direction * SPEED * delta)
