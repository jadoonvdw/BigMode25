extends CharacterBody3D

var SPEED
const SPEEDNORMAL = 5.0
const SPRINTSPEED = 8.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.003

#bob variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
var t_bob = 0.0
#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
#air dash variables
const AIR_DASH_FORCE = 10.0
const AIR_DASH_DURATION = 0.2
var can_air_dash = true
var air_dash_timer = 0.0
var air_dash_direction: Vector3 = Vector3.ZERO
#Jump buffer
const JUMP_BUFFER_TIME= 0.2  # Adjust this value to control buffer window
var jump_buffer_timer = 0.0



@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var subviewport = $Head/Camera3D/SubViewportContainer/SubViewport
@onready var viewport_cam = $Head/Camera3D/SubViewportContainer/SubViewport/Viewport_cam





func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
	#handles mouse capture and uncapture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		


func _physics_process(delta):
	
	#synchs viewport with main camera
	viewport_cam.global_transform = camera.global_transform
	subviewport.size = DisplayServer.window_get_size()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#handle buffer timer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	#check for jump input
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	#Execute Jump if conditions met
	if is_on_floor() and (Input.is_action_just_pressed("jump") or jump_buffer_timer > 0):
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0


	#handle sprint
	if Input.is_action_pressed("sprint"):
		SPEED = SPRINTSPEED
	else:
		SPEED = SPEEDNORMAL

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if Input.is_action_just_pressed("air_dash") and not is_on_floor() and can_air_dash:
			air_dash_direction = direction if direction != Vector3.ZERO else -head.global_transform.basis.z
			air_dash_timer = AIR_DASH_DURATION
			can_air_dash = false

	if air_dash_timer > 0:
		air_dash_timer -= delta
		velocity = air_dash_direction * AIR_DASH_FORCE
	
	if is_on_floor():
		can_air_dash = true
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)

#Head Bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINTSPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 6.0)

	move_and_slide()
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ/2) * BOB_AMP
	return pos
