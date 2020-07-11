extends KinematicBody

var mouseSensitivity = 0.1
var cameraTarget
var cameraTransform
var orientation
var camera
const CAMERA_SPEED = 0.003

var stateMachine

var isInDrone = false
var drone
var droneMade = false

var particlesRocket
var fuel = MAX_FUEL
const MAX_FUEL = 100
const REGENERATION_FUEL = 25
const JETPACK_FORCE = 500

var velocity = Vector3()
var speed
var stamina = MAX_STAMINA
const MAX_STAMINA = 200
const REGENERATION_STAMINA = 25
const GRAVITY = -9.8
const WALK_SPEED = 3
const RUN_SPEED = 7
const ACCELERATION = 6
const DE_ACCELERATION = 8
const JUMP_FORCE = 750
const ROTATION_SPEED = 0.2


# Gets called once
func _ready():
	particlesRocket = $Particles/RocketFire
	
	camera = $Orientation/CameraTarget/Camera
	orientation = $Orientation
	cameraTarget = $Orientation/CameraTarget
	
	stateMachine = $AnimationTree.get("parameters/playback")
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Gets called when there is a mouse or key inputs
func _input(event):
	if isInDrone:
		return
	
	if event is InputEventMouseMotion:
		orientation.rotate_y(deg2rad(-event.relative.x * mouseSensitivity))
		cameraTarget.rotate_x(deg2rad(event.relative.y * mouseSensitivity))
		cameraTarget.rotation.x = clamp(cameraTarget.rotation.x, deg2rad(-80), deg2rad(80))
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			if camera.translation.z < -9:
				camera.translation.z += 1
		if event.button_index == BUTTON_WHEEL_DOWN:
			if camera.translation.z > -100:
				camera.translation.z -= 1


# Gets called every frame
func _physics_process(delta):
	var orientationTransform = orientation.get_global_transform()
	
	var direction = Vector3()
	var hasMoved = false
	var hasJumped = false
	var isJetpacking = false
	
	if not is_on_floor():
		fall()
	else:
		idle()
	
	if Input.is_action_just_pressed("f"):
		isInDrone = not isInDrone
	
	if isInDrone:
		if not droneMade:
			drone = preload("res://Scenes/Drone.tscn")
			drone = drone.instance()
			get_node("..").add_child(drone)
			droneMade = true
	else:
		if droneMade:
			get_node("..").remove_child(drone)
			droneMade = false
			drone = null
			camera.current = true
			$UI/Stamina.visible = true
			$UI/Fuel.visible = true
		
		if Input.is_action_pressed("e") and fuel > 0:
			if fuel < 1:
				fuel = -MAX_FUEL / 10
			else:
				velocity.y = delta * JETPACK_FORCE
				isJetpacking = true
				fuel -= REGENERATION_FUEL * delta
			particlesRocket.emitting = true
		else:
			if fuel < MAX_FUEL:
				fuel += (REGENERATION_FUEL / 10) * delta
			particlesRocket.emitting = false
		
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
	
	if Input.is_action_pressed("shift") and stamina > 0 and hasMoved and not isJetpacking:
		if stamina < 1:
			stamina = -MAX_STAMINA / 5
		else:
			speed = RUN_SPEED
		stamina -= REGENERATION_STAMINA * delta
	else:
		if stamina < MAX_STAMINA:
			stamina += REGENERATION_STAMINA * delta
		speed = WALK_SPEED
	
	if isJetpacking:
		speed = RUN_SPEED * 2
	
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
		
		if speed == WALK_SPEED and not hasJumped and is_on_floor() and not isJetpacking:
			walk()
		elif speed == RUN_SPEED and not hasJumped and is_on_floor()  and not isJetpacking:
			run()
	
	if isJetpacking:
		jetPack()
	
	if isInDrone and is_on_floor():
		drone()

func drone():
	stateMachine.travel("Death")

func jetPack():
	stateMachine.travel("Flying-loop")

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
