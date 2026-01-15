extends Node
class_name ECS

static func create_entity():
	var entity_id : int = StateManager.data.next_available_uid
	StateManager.data.next_available_uid += 1
	return entity_id

#these functions return the result of the data_array using the uid of the uid array

static func get_int_data_using_uid(uid : int, uid_array : PackedInt32Array, data_array : PackedInt32Array):
	return data_array.get(uid_array.find(uid))

#this is a vector2 float, not a vector2 int
static func get_vector2_data_using_uid(uid : int, uid_array : PackedInt32Array, data_array : PackedVector2Array):
	return data_array.get(uid_array.find(uid))

static func get_string_data_using_uid(uid : int, uid_array : PackedInt32Array, data_array : PackedStringArray):
	return data_array.get(uid_array.find(uid))

static func set_int_data_using_uid(uid : int, uid_array : PackedInt32Array, data_array : PackedInt32Array, value : int):
	data_array[uid_array.find(uid)] = value

#this is a vector2 float, not a vector2 int
static func set_vector2_data_using_uid(uid : int, uid_array : PackedInt32Array, data_array : PackedVector2Array, value : Vector2):
	data_array[uid_array.find(uid)] = value

static func set_string_data_using_uid(uid : int, uid_array : PackedInt32Array, data_array : PackedStringArray, value : String):
	data_array[uid_array.find(uid)] = value

static func get_child_uids_from_parent_uid(relationship_components : RelationshipComponents, parent_uid : int):
	var child_uids : PackedInt32Array = []
	for i in relationship_components.parent_uids.size():
		if relationship_components.parent_uids[i] == parent_uid:
			child_uids.append(relationship_components.child_uids[i])
	return child_uids
