extends CharacterBody3D


const SPEED = 2.5
const JUMP_VELOCITY = 2.25
const SneakMulti = 1.5
const SprintMulti = 1.5
var isSneaking = false
var isSprinting = false
var isDodging = false
var SneakToggle = false
var JumpToggle = false
var doubleJump = 1
var inVoid = false
var hasFood = false
var BartenderInteractions = 0

# Get Food
@onready var Food = $"../Food"

# Get Pivots
@onready var TwistPivot = $Player
@onready var PitchPivot = $Player/TwistPivot/PitchPivot

# Get GUI HP/Energy Bars
@onready var HP = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/General/HP
@onready var Stamina = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/General/Stamina

# Get Detector
@onready var Detection = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/Detection

# Get the GUI Items
@onready var GUIControl = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl
@onready var PauseMenu = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/PauseMenu
@onready var General = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/General
@onready var Config = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/Config
@onready var DeathUI = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/DeathUI
@onready var QuestUI = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/Quest
@onready var QuestOne = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/Quest/Quest1
@onready var Interact = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/General/Interact

# Get Shift Button
@onready var ShiftButton = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/Config/ShiftButton
@onready var JumpButton = $Player/TwistPivot/PitchPivot/SpringArm3D/Camera3D/GUIControl/Config/JumpButton

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= (gravity * delta) / 1.7
	else:
		doubleJump = 1

	# Handle jump.
	if !JumpToggle:
		if Input.is_action_just_pressed("Jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
			else:
				if doubleJump != 0:
					velocity.y = JUMP_VELOCITY
					doubleJump -= 1
	else:
		if Input.is_action_pressed("Jump"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
		if Input.is_action_just_pressed("Jump"):
			if !is_on_floor():
				if doubleJump != 0:
					velocity.y = JUMP_VELOCITY
					doubleJump -= 1

	# Handle Pause Menu
	if Input.is_action_just_pressed("Escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		General.visible = false
		PauseMenu.visible = true
		
	# Handle Detection
	if Detection.is_colliding():
		print("Detection: ", Detection.get_collider().name)
		if Detection.get_collider().name == "Food":
			Interact.visible = true
		else:
			Interact.visible = false
		if Detection.get_collider().name == "Food" && Input.is_action_just_pressed("RightClick"):
			Food.visible = false
			hasFood = true
		if Detection.get_collider().name == "Bartender" && Input.is_action_just_pressed("LeftClick"):
			if BartenderInteractions == 0:
				QuestUI.visible = true
				QuestOne.text = "Bartender: Get me the burger behind the mountain across the bridge. [Incomplete]"
				BartenderInteractions += 1
			elif BartenderInteractions >= 1 and hasFood:
				QuestOne.text = "Bartender: Get me the burger behind the mountain across the bridge. [Complete]"

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Forward", "Backwards", "Right", "Left")
	var direction = (TwistPivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if Input.is_action_pressed("Sprint") && Stamina.value > 0 && !isSneaking:
			if !isSprinting:
				_energy_spending()
			isSneaking = false
			isSprinting = true
			velocity.x = direction.x * SPEED * SprintMulti
			velocity.z = direction.z * SPEED * SprintMulti
		elif Input.is_action_just_released("Sprint"):
			isSprinting = false
		elif Input.is_action_just_pressed("Dodge"):
			velocity.x = direction.x * SPEED * 100
			velocity.z = direction.z * SPEED * 100
			isDodging = true
			_energy_spending()
		else:
			if isSneaking:
				velocity.x = direction.x * SPEED / SneakMulti
				velocity.z = direction.z * SPEED / SneakMulti
			else:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
		if !SneakToggle:
			if Input.is_action_pressed("Sneak"):
				velocity.x = direction.x * SPEED / SneakMulti
				velocity.z = direction.z * SPEED / SneakMulti
				isSneaking = true
				isSprinting = false
			elif Input.is_action_just_released("Sneak"):
				if isSneaking:
					isSneaking = false
		else:
			if Input.is_action_just_pressed("Sneak"):
				if isSneaking:
					velocity.x = direction.x * SPEED
					velocity.z = direction.z * SPEED
					isSneaking = false
				else:
					isSneaking = true
					velocity.x = direction.x * SPEED / SneakMulti
					velocity.z = direction.z * SPEED / SneakMulti
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if position.y <= -20 and !inVoid:
		_void_death()
		inVoid = true
	
	
	
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			TwistPivot.rotate_y( - event.relative.x * 0.01)
			PitchPivot.rotate_x( - event.relative.y * 0.01)
			PitchPivot.rotation.x = clamp(PitchPivot.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _energy_spending():
	await get_tree().create_timer(.0625).timeout
	while isSprinting:
		await get_tree().create_timer(.25).timeout
		Stamina.value -= Stamina.step
	if isDodging:
		Stamina.value -= 20
		isDodging = false


func _on_resume_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	General.visible = true
	PauseMenu.visible = false


func _on_config_pressed():
	PauseMenu.visible = false
	Config.visible = true


func _on_quit_pressed():
	get_tree().quit()

func _on_button_pressed():
	if !SneakToggle:
		SneakToggle = true
		ShiftButton.text = "Toggle"
		if isSneaking:
			isSneaking = false
	else:
		SneakToggle = false
		ShiftButton.text = "Hold"
		if isSneaking:
			isSneaking = false


func _on_back_button_pressed():
	Config.visible = false
	PauseMenu.visible = true

func _void_death():
	while HP.value != 0:
		await get_tree().create_timer(.5).timeout
		HP.value -= 15
		if HP.value <= 0:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			General.visible = false
			DeathUI.visible = true


func _on_respawn_pressed():
	HP.value = HP.max_value
	Stamina.value = Stamina.max_value
	position.y = 22
	position.z = 0
	position.x = 0
	DeathUI.visible = false
	General.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	inVoid = false


func _on_jump_button_pressed():
	if !JumpToggle:
		JumpToggle = true
		JumpButton.text = "Hold"
	else:
		JumpToggle = false
		JumpButton.text = "Toggle"
