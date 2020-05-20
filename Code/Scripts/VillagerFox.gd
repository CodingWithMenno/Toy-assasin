extends KinematicBody

var camera
var gravity = -9.8
var velocity = Vector3()
var anim_player
var character

const SPEED = 2
const ACCELERATION = 1
const DE_ACCELERATION = 10


# Called once
func _ready():
	anim_player = get_node("AnimationPlayer")
	character = get_node(".")


# Called every frame
func _physics_process(delta):
	camera = get_node("Target/Camera").get_global_transform()
	var dir = Vector3()
	
	var is_moving = false
	
	# Movement
	
	if (Input.is_action_pressed("w")):
		dir += -camera.basis[2]
		is_moving = true
	if (Input.is_action_pressed("s")):
		dir += camera.basis[2]
		is_moving = true
	if (Input.is_action_pressed("a")):
		dir += -camera.basis[0]
		is_moving = true
	if (Input.is_action_pressed("d")):
		dir += camera.basis[0]
		is_moving = true
	
	dir.y = 0
	dir = dir.normalized()
	
	velocity.y + delta * gravity
	
	var hv = velocity
	hv.y = 0
	
	var new_pos = dir * SPEED
	var accel = DE_ACCELERATION
	
	if (dir.dot(hv) > 0) :
		accel = ACCELERATION
	
	hv = hv.linear_interpolate(new_pos, accel * delta)
	
	velocity.x = hv.x
	velocity.z = hv.z
	
	velocity = move_and_slide(velocity, Vector3(0, 1, 0))
	
	# Rotation
	if (is_moving):
		var angle = atan2(hv.x, hv.z)
		var char_rot = character.get_rotation()
		char_rot.y = angle
		character.set_rotation(char_rot)
	
	# Animations
	var speed = hv.length() / SPEED
	get_node("AnimationTreePlayer").blend2_node_set_amount("Idle_Walk", speed)
