extends Resource
class_name SavedServerData

# Entity Components
# TODO move peer_names to UnsavedServerData
var peer_name_comps : NameComponents = NameComponents.new()
var character_name_comps : NameComponents = NameComponents.new()

var position_comps : PositionComponents = PositionComponents.new()
var direction_comps : DirectionComponents = DirectionComponents.new()
var action_comps : ActionComponents = ActionComponents.new()

# Relationship Components
var peer_character_rels : RelationshipComponents = RelationshipComponents.new()
var character_item_rels : RelationshipComponents = RelationshipComponents.new()
