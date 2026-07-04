extends Resource
class_name WizardMatchAiProfile

const DIFFICULTY_BEGINNER := "beginner"
const DIFFICULTY_INTERMEDIATE := "intermediate"
const DIFFICULTY_ADVANCED := "advanced"
const DIFFICULTY_MASTER := "master"

const PERSONALITY_AGGRESSIVE := "aggressive"
const PERSONALITY_DEFENSIVE := "defensive"
const PERSONALITY_TACTICAL := "tactical"
const PERSONALITY_POSITIONAL := "positional"
const PERSONALITY_REACTIVE := "reactive"

@export var profile_id: String = ""
@export var display_name: String = ""
@export var difficulty: String = DIFFICULTY_BEGINNER
@export var personality: String = PERSONALITY_POSITIONAL
@export var chess_search_depth: int = 1
@export var max_root_moves_considered: int = 8
@export var max_search_branching: int = 8
@export var max_preparation_cards_per_turn: int = 1
@export var card_play_threshold: float = 0.8
@export var aggression_weight: float = 1.0
@export var defense_weight: float = 1.0
@export var position_weight: float = 1.0
@export var reaction_weight: float = 1.0
@export var trap_weight: float = 1.0
