extends Resource
class_name CardDefinition

const TYPE_UNIT := "unit"
const TYPE_SPELL := "spell"
const TYPE_REACTION := "reaction"
const TYPE_TRAP := "trap"
const TYPE_ENVIRONMENT := "environment"
const TYPE_ARTIFACT := "artifact"

const RARITY_COMMON := "common"
const RARITY_UNCOMMON := "uncommon"
const RARITY_RARE := "rare"
const RARITY_LEGENDARY := "legendary"

@export var card_id: String = ""
@export var display_name: String = ""
@export var card_type: String = TYPE_SPELL
@export var school: String = ""
@export var academy: String = ""
@export var rarity: String = RARITY_COMMON
@export var mana_cost: int = 0
@export_multiline var rules_text: String = ""
@export var target_requirements: PackedStringArray = PackedStringArray()
@export var keywords: PackedStringArray = PackedStringArray()


func is_persistent_type() -> bool:
	return card_type in [
		TYPE_UNIT,
		TYPE_TRAP,
		TYPE_ENVIRONMENT,
		TYPE_ARTIFACT,
	]
