extends Node3D

@onready var player = $"../Player"
@onready var navRegion = $NavigationRegion3D
@onready var Boss = $Boss

func _physics_process(delta):
	var playerPosition = player.global_transform.origin
	if playerPosition.x >= navRegion.position.x + 9.99 and playerPosition.z >= navRegion.position.z + 8.375 and Boss.visible:
		get_tree().call_group("Enemies_Major", "update_target_location", Vector3(playerPosition.x + 0.25, playerPosition.y, playerPosition.z + 0.25))
	else:
		get_tree().call_group("Enemies_Major", "update_target_location", Vector3(13.0, 30, 11.581))
