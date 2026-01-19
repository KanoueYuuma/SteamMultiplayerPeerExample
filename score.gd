extends HBoxContainer

var player_labels = {} # id : int to {name, label}

func _process(_delta):
	var rocks_left = $"../Rocks".get_child_count()
	if rocks_left == 0:
		var winner_name = ""
		var winner_score = 0
		for p in player_labels:
			if player_labels[p].score > winner_score:
				winner_score = player_labels[p].score
				winner_name = player_labels[p].name

		$"../Winner".set_text("THE WINNER IS:\n" + winner_name)
		$"../Winner".show()


func increase_score(for_who : int):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += 1
	pl.label.set_text(pl.name + "\n" + str(pl.score))


func add_player(id, new_player_name):
	#if player_labels.has(id):
		#return
	
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_text(new_player_name + "\n" + "0")
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font := FontFile.new()
	font = preload("res://montserrat.otf")
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", 18)
	add_child(l)

	player_labels[id] = { name = new_player_name, label = l, score = 0 }


func _ready():
	var player_names = StateManager.data.peer_name_comps.names
	player_names.sort()
	for player_name in player_names:
		var index = StateManager.data.peer_name_comps.names.find(player_name)
		add_player(StateManager.data.peer_name_comps.uids[index], player_name)
	
	$"../Winner".hide()
	set_process(true)

#func refresh_labels():
	#
	#var ids := gamestate.players.keys()
	#ids.sort()
	#for id in ids:
		#add_player(id, gamestate.players[id])
	

func _on_exit_game_pressed():
	gamestate.end_game()
