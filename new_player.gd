class_name NewPlayer
extends CharacterBody2D
signal Var_Changed(var_name : String, var_value)

@export var is_stunned : bool = false :
	set(value):
		if value != is_stunned:
			Var_Changed.emit("is_stunned",value)
		is_stunned = value

@export var direction : Vector2 = Vector2(1,0) :
	set(value):
		if value != direction:
			Var_Changed.emit("direction",value)
		direction = value

const SPEED = 300.0
const STUN_TIME := 1.0

@rpc("any_peer", "call_local")
func set_authority(id : int) -> void:
	set_multiplayer_authority(id)

func _physics_process(_delta : float):
	if is_multiplayer_authority():
		# Get the input direction and handle the movement/deceleration.
		if is_stunned:
			velocity = Vector2.ZERO
		else:
			direction = Input.get_vector(
				"move_left", "move_right", 
				"move_up", "move_down")
			if direction:
				velocity = direction * SPEED
			else:
				velocity = velocity.move_toward(Vector2.ZERO, SPEED)
			move_and_slide()
		
		#Handle bombs
		if Input.is_action_just_pressed("set_bomb"):
			drop_bomb.rpc_id(1, [position, multiplayer.get_unique_id()])

@rpc("any_peer", "call_local")
func drop_bomb(data : Array) -> void:
	var spawner = get_node("../../BombSpawner")
	spawner.spawn(data)

func set_player_name(value : String):
	$Label.text = value

@rpc("any_peer", "call_local")
func teleport(new_position : Vector2) -> void:
	self.position = new_position
	
@rpc("any_peer", "call_local")
func exploded(_by_who) -> void:
	if is_stunned:
		return
	
	is_stunned = true
	start_stun_timer.rpc()

@rpc("any_peer", "call_local")
func start_stun_timer() -> void:
	# purely visual timing
	get_tree().create_timer(STUN_TIME).timeout.connect(
		func():
			is_stunned = false
	)
