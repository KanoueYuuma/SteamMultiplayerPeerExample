extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

var peer : MultiplayerPeer = null

# Name for local player.
var player_name : String

# Names for remote players in id:name format.
var players := {}

var players_ready := []

var lobby_id := -1

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what : String)
signal game_log(what : String)
#
#func _ready():
	#Steam.steamInitEx(true, 480)
	##peer = SteamMultiplayerPeer.new()
	#
	## Keep connections defined locally, if they aren't likely to be used
	## anywhere else, such as with a lambda function for readability.
	#
	#multiplayer.peer_connected.connect(
		#func(_id : int): 
			## When ever a peer connects server tells everyone to update peer dictionary
			#if multiplayer.is_server():
				#for peer_id in players:
					#player_registered.rpc(peer_id,players[peer_id])
	#)
	#multiplayer.peer_disconnected.connect(
		#func(id : int):
			#if is_game_in_progress():
				#if multiplayer.is_server():
					#game_error.emit("Player " + players[id] + " disconnected")
					#end_game()
			#else:
				## Unregister this player. This doesn't need to be called when the
				## server quits, because the whole player list is cleared anyway!
				#unregister_player(id)
	#)
	#multiplayer.connected_to_server.connect(
		#func():
			#connection_succeeded.emit()
			#request_register_player.rpc(player_name)
			#
	#)
	#multiplayer.connection_failed.connect(
		#func():
			#multiplayer.multiplayer_peer = null
			#connection_failed.emit()
	#)
	#multiplayer.server_disconnected.connect(
		#func():
			#game_error.emit("Server disconnected")
			#end_game()
	#)
	#
	#Steam.lobby_joined.connect(
		#func (new_lobby_id: int, _permissions: int, _locked: bool, response: int):
		#if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
			#lobby_id = new_lobby_id
			#var lobby_owner_id = Steam.getLobbyOwner(new_lobby_id)
			#if lobby_owner_id != Steam.getSteamID():
				#connect_steam_socket(lobby_owner_id)
				##request_register_player.rpc(player_name)
		#else:
			## Get the failure reason
			#var FAIL_REASON: String
			#match response:
				#Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST:
					#FAIL_REASON = "This lobby no longer exists."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED:
					#FAIL_REASON = "You don't have permission to join this lobby."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_FULL:
					#FAIL_REASON = "The lobby is now full."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR:
					#FAIL_REASON = "Uh... something unexpected happened!"
				#Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED:
					#FAIL_REASON = "You are banned from this lobby."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED:
					#FAIL_REASON = "You cannot join due to having a limited account."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED:
					#FAIL_REASON = "This lobby is locked or disabled."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN:
					#FAIL_REASON = "This lobby is community locked."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU:
					#FAIL_REASON = "A user in the lobby has blocked you from joining."
				#Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER:
					#FAIL_REASON = "A user you have blocked is in the lobby."
			#game_log.emit(FAIL_REASON)
	#)
	#Steam.lobby_created.connect(
		#func(status: int, new_lobby_id: int):
			#if status == 1:
				##lobby_id = new_lobby_id
				#Steam.setLobbyData(new_lobby_id, "name", 
					#str(Steam.getPersonaName(), "'s Spectabulous Test Server"))
				#create_steam_socket()
			#else:
				#game_error.emit("Error on create lobby!")
	#)
#
#func _process(_delta : float):
	#Steam.run_callbacks()
#
## Lobby management functions.
#
#@rpc("any_peer","call_remote")
#func request_register_player(new_player_name : String):
	#if !multiplayer.is_server():
		#return
	#var id = multiplayer.get_remote_sender_id()
#
	#players[id] = make_unique_username(new_player_name)
	#player_list_changed.emit()
	#player_registered.rpc(id,players[id])
#
#@rpc("authority","call_remote")
#func player_registered(peer_id : int, peer_name : String):
	#players[peer_id] = peer_name
	#player_list_changed.emit()
	#return
#
#
#func unregister_player(id):
	#players.erase(id)
	#player_list_changed.emit()
	#

@rpc("call_local")
func load_world():
	# Change scene.
	var world = load("res://world.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

	get_tree().set_pause(false) # Unpause and unleash the game!

##region Lobbies
#
#func host_lobby(new_player_name : String):
	#player_name = new_player_name
	#players[1] = new_player_name
	#Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PEERS)
#
#
#func join_lobby(new_lobby_id : int, new_player_name : String):
	#player_name = new_player_name
	#Steam.joinLobby(new_lobby_id)
#
##endregion
#
func begin_game():
	#Ensure that this is only running on the server; if it isn't, we need
	#to check our code.
	assert(multiplayer.is_server())
	
	#call load_world on all clients
	load_world.rpc()
	
	#grab the world node and player scene
	var world : Node2D = get_tree().get_root().get_node("World")
	var player_scene := load("res://new_player.tscn")
	
	#Iterate over our connected peer ids
	var spawn_index = 0
	
	for peer_id in StateManager.data.peer_name_comps.uids:
		print("PEER ID: ", peer_id)
		var player : CharacterBody2D = player_scene.instantiate()
		var index = StateManager.data.peer_name_comps.uids.find(peer_id)
		player.set_player_name(StateManager.data.peer_name_comps.names[index])
		# "true" forces a readable name, which is important, as we can't have sibling nodes
		# with the same name.
		world.get_node("Players").add_child(player, true)
		
		#Set the authorization for the player. This has to be called on all peers to stay in sync.
		player.set_authority.rpc(peer_id)
		
		#Grab our location for the player.
		var target : Vector2 = world.get_node("SpawnPoints").get_child(spawn_index).position
		
		#The peer has authority over the player's position, so to sync it properly,
		#we need to set that position from that peer with an RPC.
		player.teleport.rpc_id(peer_id, target)
		
		spawn_index += 1
	
## create_steam_socket and connect_steam_socket both create the multiplayer peer, instead
## of _ready, for the sake of compatibility with other networking services
## such as WebSocket, WebRTC, or Steam or Epic.
#
##region Steam Peer Management
#func create_steam_socket():
	#peer = SteamMultiplayerPeer.new()
	#peer.create_host(0, [])
	#multiplayer.set_multiplayer_peer(peer)
#
#func connect_steam_socket(steam_id : int):
	#peer = SteamMultiplayerPeer.new()
	#peer.create_client(steam_id, 0, [])
	#multiplayer.set_multiplayer_peer(peer)
#
##endregion
#
##region ENet Peer Management
#func create_enet_host(new_player_name : String):
	#peer = ENetMultiplayerPeer.new()
	#(peer as ENetMultiplayerPeer).create_server(DEFAULT_PORT)
	#multiplayer.set_multiplayer_peer(peer)
	#player_name = new_player_name
	#var id := multiplayer.get_unique_id() # always 1
	#players[id] = new_player_name
	#player_registered.rpc(id,players[id])
#
#func create_enet_client(new_player_name : String, address : String):
	#peer = ENetMultiplayerPeer.new()
	#(peer as ENetMultiplayerPeer).create_client(address, DEFAULT_PORT)
	#multiplayer.set_multiplayer_peer(peer)
#
##endregion
#
##region Utility
	#
#func make_unique_username(requested_name: String,) -> String:
		#
	## If the originally requested name is free, keep it
	#if not gamestate.players.values().has(requested_name):
		#return requested_name
		#
	#var base_name := requested_name
	#var number := 0
#
	## Detect trailing number (e.g. "Alice12")
	#var regex := RegEx.new()
	#regex.compile("(.*?)(\\d+)$")
	#var result := regex.search(requested_name)
#
	#if result:
		#base_name = result.get_string(1)
		#number = int(result.get_string(2))
		#print(str(base_name) + str(number))
	#else:
		#number = 2
		#print(number)
#
	#var candidate : String = base_name + str(number)
	## Otherwise, increment until unique
	#while gamestate.players.values().has(candidate):
		#number += 1
		#candidate = base_name + str(number)
	#return candidate
			#
#@rpc("call_local", "any_peer")
#func get_player_name() -> String:
	#return players[multiplayer.get_remote_sender_id()]
#
func is_game_in_progress() -> bool:
	return has_node("/root/World")

func end_game():
	if is_game_in_progress():
		get_node("/root/World").queue_free()
	
	game_ended.emit()
	players.clear()

##endregion
