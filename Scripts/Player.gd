extends CharacterBody3D

@onready var head = $Neck/Head
@onready var neck = $Neck
@onready var collisionShape = $CollisionShape3D
@onready var rayCast = $RayCast3D
@onready var camera = $Neck/Head/Camera3D

var speedCurrent = 5.0
const walkingSpeed = 5.0
const sprintSpeed = 8.0
const crouchingSpeed = 3.0

var slideTimer = 0.0
var slideTimerMax = 1
var slideDirection = Vector3.ZERO

const jumpVelocity = 4.5
var lerpSpeed = 10.0
var direction = Vector3.FORWARD
const mouseSensivity = 0.4
var crouchingDepth = -0.5
var freeLookTiltAmount = 8

#States
#var walking = false
#var sprinting = false
#var crouching = false
#var freeLooking = false
#var sliding = false
enum MoveSet{Walking,Sprinting,Crouching,FreeLooking,Sliding,Standing,Jumping}

var moveSet = MoveSet.Standing
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		if moveSet==MoveSet.FreeLooking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouseSensivity))
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x) * mouseSensivity)
		head.rotate_x(deg_to_rad(-event.relative.y) * mouseSensivity)
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))
	
func _physics_process(delta):
	
	var input_dir = Input.get_vector("Left","Right","Forward","Backward")
	
	# Crouching
	
	if Input.is_action_pressed("Crouch"):
		speedCurrent = crouchingSpeed
		head.position.y = lerp(head.position.y, crouchingDepth,delta * lerpSpeed)
		collisionShape.shape.height = 1
		
		if moveSet == MoveSet.Sprinting && input_dir != Vector2.ZERO:
			moveSet = MoveSet.Sliding
			slideTimer = slideTimerMax
			slideDirection = input_dir
		
		moveSet = MoveSet.Crouching
	
	#Standing
	
	elif !rayCast.is_colliding():
		collisionShape.shape.height = 2
		
		head.position.y = lerp(head.position.y,0.0,delta * lerpSpeed)
		
		#Sprinting
		
		if Input.is_action_pressed("Sprint"):
			speedCurrent = sprintSpeed
			
			moveSet = MoveSet.Sprinting
			
		#Walking
		
		else:
			speedCurrent = walkingSpeed
			
			moveSet = MoveSet.Walking
			
	#Handle free looking
	if Input.is_action_pressed("FreeLook"):
		moveSet = MoveSet.FreeLooking
		camera.rotation.z = -deg_to_rad(neck.rotation.y * freeLookTiltAmount)
	else:
		moveSet = MoveSet.Standing
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerpSpeed)
		camera.rotation.z = lerp(camera.rotation.z, 0.0, delta*lerpSpeed)
	
	#HAndle sliding
	if moveSet == MoveSet.Sliding:
		slideTimer -= delta
		if slideTimer <= 0:
			moveSet = MoveSet.Standing
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jumpVelocity
		moveSet = MoveSet.Jumping

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta * lerpSpeed)
	
	if moveSet == MoveSet.Sliding:
		direction = transform.basis * Vector3(slideDirection.x, 0 , slideDirection.y)
		
	if direction:
		velocity.x = direction.x * speedCurrent
		velocity.z = direction.z * speedCurrent
		
		if moveSet == MoveSet.Sliding:
			velocity.x = direction.x * slideTimer
			velocity.z = direction.z * slideTimer
			
	else:
		velocity.x = move_toward(velocity.x, 0, speedCurrent)
		velocity.z = move_toward(velocity.z, 0, speedCurrent)
	print(moveSet)

	move_and_slide()
