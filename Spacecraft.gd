extends CharacterBody3D

const CRUISING_SPEED := 80.0 * 100 # metres per second
const STEER_SPEED := 3.0
const STEER_RESPONSIVENESS := 2.0

var steer_controller_input:Vector2
var roll_input:float
var target_yaw_speed := 0.0
var target_roll_speed := 0.0

func _process(_delta):
	steer_controller_input = Input.get_vector("steer_right","steer_left","steer_down","steer_up")

func _physics_process(delta):
	velocity = -global_transform.basis.z * delta * CRUISING_SPEED
	
	var steer_input = steer_controller_input

	# YAW
	if steer_input.x:
		target_yaw_speed = lerp(target_yaw_speed, steer_input.x * delta * STEER_SPEED, delta * STEER_RESPONSIVENESS)
		%Model.rotation.z = lerp(%Model.rotation.z, deg_to_rad(steer_input.x * 25), delta * STEER_RESPONSIVENESS)
	else:
		target_yaw_speed = lerp(target_yaw_speed, 0.0, delta * STEER_RESPONSIVENESS)
		%Model.rotation.z = lerp(%Model.rotation.z, 0.0, delta * STEER_RESPONSIVENESS)
	rotate_object_local(Vector3.UP, target_yaw_speed)
	
	
	#PITCH
	if steer_input.y:
		velocity.y += steer_input.y * delta * CRUISING_SPEED
		%Model.rotation.x = lerp(%Model.rotation.x, deg_to_rad(steer_input.y * 25), 5 * delta)
	else:
		%Model.rotation.x = lerp(%Model.rotation.x, 0.0, 5 * delta)
	
	move_and_slide()
