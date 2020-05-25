extends KinematicBody

var mouseSensitivity = 0.1
var cameraTarget
var cameraTransform
var orientation
const CAMERA_SPEED = 0.003

var stateMachine

var velocity = Vector3()
var speed
var stamina = MAX_STAMINA
const MAX_STAMINA = 200
const GRAVITY = -9.8
const WALK_SPEED = 3
const RUN_SPEED = 7
const ACCELERATION = 6
const DE_ACCELERATION = 8
const JUMP_FORCE = 750
const ROTATION_SPEED = 0.2


# Gets called once
func _ready():
	orientation = $Orientation
	cameraTarget = $Orientation/CameraTarget
	
	stateMachine = $AnimationTree.get("parameters/playback")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Gets called when there is a mouse or key inputs
func _input(event):
	if event is InputEventMouseMotion:
		orientation.rotate_y(deg2rad(-event.relative.x * mouseSensitivity))
		cameraTarget.rotate_x(deg2rad(event.relative.y * mouseSensitivity))
		cameraTarget.rotation.x = clamp(cameraTarget.rotation.x, deg2rad(-80), deg2rad(80))


# Gets called every frame
func _physics_process(delta):
	var orientationTransform = orientation.get_global_transform()
	
	var direction = Vector3()
	var hasMoved = false
	var hasJumped = false
	
	if not is_on_floor():
		fall()
	else:
		idle()
	
	if Input.is_action_pressed("spacebar") and is_on_floor():
		velocity.y += delta * JUMP_FORCE
		hasJumped = true
		jump()
	if Input.is_action_pressed("w"):
		direction += orientationTransform.basis[2]
		hasMoved = true
	if Input.is_action_pressed("s"):
		direction += -orientationTransform.basis[2]
		hasMoved = true
	if Input.is_action_pressed("a"):
		direction += orientationTransform.basis[0]
		hasMoved = true
	if Input.is_action_pressed("d"):
		direction += -orientationTransform.basis[0]
		hasMoved = true
	
	direction.y= 0
	direction = direction.normalized()
	
	velocity.y += delta * GRAVITY
	
	var hv = velocity
	hv.y = 0
	
	if Input.is_action_pressed("shift") and stamina > 0 and hasMoved:
		if stamina < 1:
			stamina = -MAX_STAMINA / 5
		else:
			speed = RUN_SPEED
		stamina -= 25 * delta
	else:
		if stamina < MAX_STAMINA:
			stamina += 25 * delta
		speed = WALK_SPEED
		
	
	var newPosition = direction * speed
	var accel = DE_ACCELERATION
	
	if (direction.dot(hv) > 0): # Character is accelerating
		accel = ACCELERATION
	
	hv = hv.linear_interpolate(newPosition, accel * delta)
	
	velocity.x = hv.x
	velocity.z = hv.z
	
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if hasMoved:
		cameraTarget.rotation.x = lerp(cameraTarget.rotation.x, orientation.rotation.x, CAMERA_SPEED)
		
		var angle = atan2(hv.x, hv.z)
		var characterRotation = $metarig/Skeleton/Cube.get_rotation()
		var slowAngle = characterRotation.y + (angle - characterRotation.y) * ROTATION_SPEED
		if abs(slowAngle) > 1.5:
			characterRotation.y = angle
		else:
			characterRotation.y = slowAngle
		$metarig/Skeleton/Cube.set_rotation(characterRotation)
		$metarig/Skeleton/Cube001.set_rotation(characterRotation)
		
		if speed == WALK_SPEED and not hasJumped and is_on_floor():
			walk()
		elif speed == RUN_SPEED and not hasJumped and is_on_floor():
			run()

func jump():
	stateMachine.start("Jump")

func fall():
	stateMachine.travel("Falling-loop")

func run():
	stateMachine.travel("Running-loop")

func idle():
	stateMachine.travel("Idle-loop")

func walk(): 
	stateMachine.travel("Walking-loop")
