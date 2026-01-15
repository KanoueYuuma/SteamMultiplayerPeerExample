extends Resource
class_name SavedServerData

var next_available_uid : int = 1

var peer : MultiplayerPeer = null
var lobby_id : int

# TODO move player_name to SavedClientData
var player_name : String

# Entity Components
# TODO move peer_name_comps to UnsavedServerData
var peer_name_comps : NameComponents = NameComponents.new()
var player_name_comps : NameComponents = NameComponents.new()

var position_comps : PositionComponents = PositionComponents.new()
var direction_comps : DirectionComponents = DirectionComponents.new()
var action_comps : ActionComponents = ActionComponents.new()

# Relationship Components
var peer_player_rels : RelationshipComponents = RelationshipComponents.new()
var character_item_rels : RelationshipComponents = RelationshipComponents.new()
