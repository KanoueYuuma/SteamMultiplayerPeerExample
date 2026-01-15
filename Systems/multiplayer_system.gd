extends Node
class_name MultiplayerSystem

signal game_error(what : String)
signal game_log(what : String)

func _ready() -> void:
	Steam.steamInitEx(true, 480)
	
	# Keep connections defined locally, if they aren't likely to be used
	# anywhere else, such as with a lambda function for readability.
	multiplayer.connected_to_server.connect(
		func():
			gamestate.connection_succeeded.emit()
			request_register_player.rpc(StateManager.data.player_name)
			
	)
	multiplayer.connection_failed.connect(
		func():
			multiplayer.multiplayer_peer = null
			gamestate.connection_failed.emit()
	)
	multiplayer.server_disconnected.connect(
		func():
			game_error.emit("Server disconnected")
			end_game()
	)
	
	multiplayer.peer_connected.connect(
		func(_id : int): 
			# When ever a peer connects server tells everyone to update peer dictionary
			if multiplayer.is_server():
				for peer_id in StateManager.data.peer_name_comps.uids:
					var rel_index = StateManager.data.peer_player_rels.parent_uids.find(peer_id)
					var entity_uid = StateManager.data.peer_player_rels.parent_uids[rel_index]
					var peer_name = ECS.get_string_data_using_uid(peer_id,StateManager.data.peer_name_comps.uids,StateManager.data.peer_name_comps.names)
					player_registered.rpc(peer_id,entity_uid,peer_name)
	)
	multiplayer.peer_disconnected.connect(
		func(id : int):
			if is_game_in_progress():
				if multiplayer.is_server():
					game_error.emit("Player " + ECS.get_string_data_using_uid(id,StateManager.data.peer_name_comps.uids,StateManager.data.peer_name_comps.names)+ " disconnected")
					end_game()
			else:
				# Unregister this player. This doesn't need to be called when the
				# server quits, because the whole player list is cleared anyway!
				unregister_player(id)
	)
	
	Steam.lobby_created.connect(
		func(status: int, new_lobby_id: int):
			if status == 1:
				#lobby_id = new_lobby_id
				Steam.setLobbyData(new_lobby_id, "name", 
					str(Steam.getPersonaName(), "'s Spectabulous Test Server"))
				create_steam_socket()
			else:
				game_error.emit("Error on create lobby!")
	)
	
	Steam.lobby_joined.connect(
		func (new_lobby_id: int, _permissions: int, _locked: bool, response: int):
		if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
			StateManager.data.lobby_id = new_lobby_id
			var lobby_owner_id = Steam.getLobbyOwner(new_lobby_id)
			if lobby_owner_id != Steam.getSteamID():
				connect_steam_socket(lobby_owner_id)
				#request_register_player.rpc(player_name)
		else:
			# Get the failure reason
			var FAIL_REASON: String
			match response:
				Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST:
					FAIL_REASON = "This lobby no longer exists."
				Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED:
					FAIL_REASON = "You don't have permission to join this lobby."
				Steam.CHAT_ROOM_ENTER_RESPONSE_FULL:
					FAIL_REASON = "The lobby is now full."
				Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR:
					FAIL_REASON = "Uh... something unexpected happened!"
				Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED:
					FAIL_REASON = "You are banned from this lobby."
				Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED:
					FAIL_REASON = "You cannot join due to having a limited account."
				Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED:
					FAIL_REASON = "This lobby is locked or disabled."
				Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN:
					FAIL_REASON = "This lobby is community locked."
				Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU:
					FAIL_REASON = "A user in the lobby has blocked you from joining."
				Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER:
					FAIL_REASON = "A user you have blocked is in the lobby."
			game_log.emit(FAIL_REASON)
	)


func _process(_delta : float):
	Steam.run_callbacks()

# Lobby management functions.

@rpc("any_peer","call_remote")
func request_register_player(new_player_name : String):
	if !multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()

	#players[id] = make_unique_username(new_player_name)
	var player_uid = ECS.create_entity()
	player_registered.rpc(peer_id, player_uid, new_player_name)

@rpc("authority","call_local")
func player_registered(peer_id : int, player_uid : int, peer_name : String):
	#players[peer_id] = peer_name
	gamestate.player_list_changed.emit()
	create_peer_name_component(peer_id,peer_name)
	create_player_name_component(player_uid,peer_name)
	create_peer_player_relationship(peer_id,player_uid)



func unregister_player(peer_id):
	#players.erase(peer_id)
	var rel_index = StateManager.data.peer_player_rels.parent_uids.find(peer_id)
	var player_uid = StateManager.data.peer_player_rels.child_uids[rel_index]
	StateManager.data.peer_player_rels.parent_uids.remove_at(rel_index)
	StateManager.data.peer_player_rels.child_uids.remove_at(rel_index)
	remove_peer_component(peer_id)
	remove_player_component(player_uid)
	gamestate.player_list_changed.emit()

func create_peer_name_component(peer_id : int, peer_name : String):
	var index = StateManager.data.peer_name_comps.uids.find(peer_id)
	if index == -1:
		StateManager.data.peer_name_comps.uids.append(peer_id)
		StateManager.data.peer_name_comps.names.append(peer_name)
	else:
		StateManager.data.peer_name_comps.names[index] = peer_name

func create_player_name_component(peer_id : int, player_name : String):
	var index = StateManager.data.player_name_comps.uids.find(peer_id)
	if index == -1:
		StateManager.data.player_name_comps.uids.append(peer_id)
		StateManager.data.player_name_comps.names.append(player_name)
	else:
		StateManager.data.player_name_comps.names[index] = player_name

func create_peer_player_relationship(peer_id : int, player_uid : int):
	StateManager.data.peer_player_rels.parent_uids.append(peer_id)
	StateManager.data.peer_player_rels.child_uids.append(player_uid)

func remove_peer_component(peer_id : int):
	var index = StateManager.data.peer_name_comps.uids.find(peer_id)
	if index != -1:
		StateManager.data.peer_name_comps.uids.remove_at(index)
		StateManager.data.peer_name_comps.names.remove_at(index)

func remove_player_component(player_id : int):
	var index = StateManager.data.player_name_comps.uids.find(player_id)
	if index != -1:
		StateManager.data.player_name_comps.uids.remove_at(index)
		StateManager.data.player_name_comps.names.remove_at(index)

func remove_peer_player_relationship(peer_id : int):
	var index = StateManager.data.peer_player_rels.parent_uids.find(peer_id)
	if index != -1:
		StateManager.data.peer_player_rels.parent_uids.remove_at(index)
		StateManager.data.peer_player_rels.child_uids.remove_at(index)


#region Steam Peer Management
func create_steam_socket():
	StateManager.data.peer = SteamMultiplayerPeer.new()
	StateManager.data.peer.create_host(0, [])
	multiplayer.set_multiplayer_peer(StateManager.data.peer)

func connect_steam_socket(steam_id : int):
	StateManager.data.peer = SteamMultiplayerPeer.new()
	StateManager.data.peer.create_client(steam_id, 0, [])
	multiplayer.set_multiplayer_peer(StateManager.data.peer)

#endregion

#region ENet Peer Management
func create_enet_host(new_player_name : String):
	StateManager.data.peer = ENetMultiplayerPeer.new()
	(StateManager.data.peer as ENetMultiplayerPeer).create_server(Consts.DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(StateManager.data.peer)
	StateManager.data.player_name = new_player_name
	
	var id := multiplayer.get_unique_id() # always 1
	StateManager.data.peer_name_comps.uids.append(id)
	StateManager.data.peer_name_comps.names.append(new_player_name)
	
	var uid = ECS.create_entity()
	StateManager.data.player_name_comps.uids.append(uid)
	StateManager.data.player_name_comps.names.append(new_player_name)
	player_registered.rpc(id,uid,new_player_name)

func create_enet_client(new_player_name : String, address : String):
	StateManager.data.peer = ENetMultiplayerPeer.new()
	(StateManager.data.peer as ENetMultiplayerPeer).create_client(address, Consts.DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(StateManager.data.peer)

#endregion

#region Utility
	
func make_unique_username(requested_name: String,) -> String:
		
	# If the originally requested name is free, keep it
	if not StateManager.data.player_name_comps.names.has(requested_name):
		return requested_name
		
	var base_name := requested_name
	var number := 0

	# Detect trailing number (e.g. "Alice12")
	var regex := RegEx.new()
	regex.compile("(.*?)(\\d+)$")
	var result := regex.search(requested_name)

	if result:
		base_name = result.get_string(1)
		number = int(result.get_string(2))
		print(str(base_name) + str(number))
	else:
		number = 2
		print(number)

	var candidate : String = base_name + str(number)
	# Otherwise, increment until unique
	while StateManager.data.player_name_comps.names.has(candidate):
		number += 1
		candidate = base_name + str(number)
	return candidate


func is_game_in_progress() -> bool:
	return has_node("/root/World")

func end_game():
	if is_game_in_progress():
		get_node("/root/World").queue_free()
	
	gamestate.game_ended.emit()
	#players.clear()
	StateManager.data.peer_name_comps = NameComponents.new()

#endregion
