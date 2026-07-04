extends Resource
class_name DeckDefinition

@export var deck_id: String = ""
@export var display_name: String = ""
@export var cards: Array[CardDefinition] = []


func card_count() -> int:
	return cards.size()
