extends AnimationTree

@onready var player : NewPlayer = $".."
var already_stunned : bool = false
func _ready() -> void:
	player.Var_Changed.connect(
		func(var_name : String, value):
			if var_name == "direction":
				#print("Direction Changed to " + str(value))
				var new_direction : Vector2 = value
				# Update animation tree with parameters for cardinal directions and stunned
				self.set("parameters/up/blend_amount", 
					1.0 if new_direction.dot(Vector2.UP) > 0.0 else 0.0)
				self.set("parameters/down/blend_amount",
					1.0 if new_direction.dot(Vector2.DOWN) > 0.0 else 0.0)
				self.set("parameters/left/blend_amount",
					1.0 if new_direction.dot(Vector2.LEFT) > 0.0 else 0.0)
				self.set("parameters/right/blend_amount",
					1.0 if new_direction.dot(Vector2.RIGHT) > 0.0 else 0.0)
			
			elif var_name == "is_stunned":
				if value:
					#print("PLAYER IS STUNNED")
					if !already_stunned:
						already_stunned = true
						#print("Playing Stunned Animation")
						self.set("parameters/stunned/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					return
				else:
					if already_stunned:
						already_stunned = false
	)
