extends CharacterBody3D

# Player : KinematicBody
#	CollisionShape
#	Head : Node3D
#		HeadY : Node3D
#			HeadX : Node3D
#				Camera

# Signals : Autoload script
#	signal stamina_updated

const WALK_SPEED := 1
const RUN_SPEED := 3.0
const SPRINT_SPEED := 6.0
const MOUSE_LOOK_FACTOR := 0.25
const JUMP_FORCE := 5
const TOTAL_STAMINA := 10.0
const STAMINA_RECOVERY := 20.0
const JUMP_CURVE_DURATION := 0.5
const JUMP_CURVE_AMPLITUDE := 5
const LAND_CURVE_AMPLITUDE := 10
@export var jump_curve : Curve

@onready var head = $Head
@onready var head_y = $Head/HeadY
@onready var head_x = $Head/HeadY/HeadX
@onready var cam = $Head/HeadY/HeadX/Camera

var mouse_relative : Vector2
var move_speed := RUN_SPEED
var stamina := 1.0
var jump_curve_value := 0.0
var land_curve_value := 0.0
var last_frame_was_on_floor := true
var last_frame_velocity_y := 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	# SPRINT / WALK
	if Input.is_action_pressed("sprint") and stamina:
		move_speed = SPRINT_SPEED
	elif Input.is_action_pressed("walk"):
		move_speed = WALK_SPEED
	else:
		move_speed = RUN_SPEED
	
	
	# GRAVITY / JUMP
	if is_on_floor():
		if jump_curve_value > 0.02: jump_curve_value = 0
		if land_curve_value == 1: land_curve_value = 0
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_FORCE
			jump_curve_value += delta / JUMP_CURVE_DURATION
		elif (not last_frame_was_on_floor and last_frame_velocity_y < -5) or land_curve_value > 0:
			land_curve_value = min(land_curve_value + (delta / JUMP_CURVE_DURATION) , 1)
	else:
		velocity += get_gravity() * delta
		land_curve_value = 0
		if jump_curve_value > 0: jump_curve_value = min(jump_curve_value + (delta / JUMP_CURVE_DURATION), 1)
	
	# MOVEMENT
	var move_input := Input.get_vector("move_left","move_right", "move_forward","move_back")
	var move_direction : Vector3 = head_y.basis * Vector3(move_input.x, 0, move_input.y).normalized()
	velocity.x = move_direction.x * move_speed
	velocity.z = move_direction.z * move_speed
	
	# STAMINA
	if Input.is_action_pressed("sprint") and move_input:
		if move_speed == SPRINT_SPEED:
			if stamina > 0:
				stamina = max(stamina - (delta / TOTAL_STAMINA), 0)
				Signals.stamina_updated.emit(stamina)
	else:
		if stamina < 1:
			stamina = min(stamina + (delta / STAMINA_RECOVERY), 1)
			Signals.stamina_updated.emit(stamina)
	
	last_frame_was_on_floor = is_on_floor()
	last_frame_velocity_y = velocity.y

func _physics_process(delta):
	move_and_slide()
	
	# MOUSE LOOK
	var look_left_right := 0.0
	var look_up_down := 0.0
	
	if (mouse_relative):
		look_left_right = -mouse_relative.x * delta
		look_up_down = -mouse_relative.y * delta
	else: 
		look_up_down = Input.get_axis("look_up", "look_down") * 2
		look_left_right = Input.get_axis("look_left", "look_right") * 2
	
	head_y.rotate_y(look_left_right)
	var rotation_x = clamp(head_x.rotation.x + look_up_down, -PI/2, PI/2)
	head_x.rotation.x = rotation_x
	mouse_relative = Vector2.ZERO
	
	# HEAD BOB : sin((time + offset) * frequency) * amplitude
	if abs(velocity.x) == 0 and abs(velocity.z) == 0:
		head_y.position.y = move_toward(head_y.position.y, sin(Time.get_ticks_msec() * 0.0015) * 0.01, delta)
	elif move_speed == WALK_SPEED:
		head_y.position.y = move_toward(head_y.position.y, sin(Time.get_ticks_msec() * 0.01) * 0.015, delta)
	elif move_speed == RUN_SPEED:
		head_y.position.y = move_toward(head_y.position.y, sin(Time.get_ticks_msec() * 0.0125) * 0.03, delta)
	elif move_speed == SPRINT_SPEED:
		head_y.position.y = move_toward(head_y.position.y, sin(Time.get_ticks_msec() * 0.014) * 0.05, delta)
		cam.rotation_degrees.z = sin(Time.get_ticks_msec() * 0.007) * 0.25
	
	# JUMP CAMERA SHAKE
	if land_curve_value:
		cam.rotation_degrees.x = -jump_curve.sample(land_curve_value) * LAND_CURVE_AMPLITUDE
	elif jump_curve_value:
		cam.rotation_degrees.x = jump_curve.sample(jump_curve_value) * JUMP_CURVE_AMPLITUDE
	else:
		cam.rotation_degrees.x = 0

func _input(event):
	if event is InputEventMouseMotion:
		mouse_relative = event.relative * MOUSE_LOOK_FACTOR
