extends Node

var user_name: String = "Guest"
var user_age: int = 0
var current_level: int = 1
var current_level_score: int = 0  # 0-3 stars
var max_level_unlocked: int = 1

# Per-level scores: { level_id: stars }
var level_scores: Dictionary = {}

# --- CHAPTER GATE REQUIREMENTS ---
# Chapter N+1 unlocks only after the final level of Chapter N is completed.
const CHAPTER_GATES: Dictionary = {
	2: 5,   # Chapter 2 requires Level 5 completed
	3: 13,  # Chapter 3 requires Level 13 completed
	4: 17,  # Chapter 4 requires Level 17 completed
}

func _ready() -> void:
	load_progress()

func save_user_data(n: String, a: int) -> void:
	user_name = n
	user_age = a

func complete_level(level_id: int, stars: int) -> void:
	level_scores[level_id] = maxi(level_scores.get(level_id, 0), stars)
	current_level_score = stars

	# Unlock next level (if within same chapter or chapter gate is met)
	var next_level: int = level_id + 1
	if next_level <= 20:
		var next_chapter: int = _get_chapter_for_level(next_level)
		var gate_level: int = CHAPTER_GATES.get(next_chapter, 0)
		if gate_level == 0 or level_scores.get(gate_level, 0) > 0:
			if next_level > max_level_unlocked:
				max_level_unlocked = next_level
		elif level_id >= gate_level:
			# Just completed the gate level — unlock
			if next_level > max_level_unlocked:
				max_level_unlocked = next_level
	elif level_id >= max_level_unlocked:
		max_level_unlocked = mini(level_id + 1, 20)

func is_level_unlocked(level_id: int) -> bool:
	return level_id <= max_level_unlocked

func is_chapter_unlocked(chapter: int) -> bool:
	var gate_level: int = CHAPTER_GATES.get(chapter, 0)
	if gate_level == 0:
		return true  # Chapter 1 always unlocked
	return level_scores.get(gate_level, 0) > 0

func get_level_score(level_id: int) -> int:
	return level_scores.get(level_id, 0)

func get_total_stars() -> int:
	var total: int = 0
	for s in level_scores.values():
		total += s
	return total

func _get_chapter_for_level(level_id: int) -> int:
	if level_id <= 5: return 1
	if level_id <= 13: return 2
	if level_id <= 17: return 3
	return 4

# --- PERSISTENCE ---

const SAVE_PATH: String = "user://architect_data.cfg"

func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	user_name = config.get_value("Architect", "name", "Guest")
	user_age = config.get_value("Architect", "age", 0)
	max_level_unlocked = config.get_value("Progress", "max_level_unlocked", 1)
	for i in range(1, 21):
		var score: int = config.get_value("Progress", "level_%d_score" % i, 0)
		if score > 0:
			level_scores[i] = score

func save_progress() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)  # preserve existing sections (Settings, etc.)
	config.set_value("Architect", "name", user_name)
	config.set_value("Architect", "age", user_age)
	config.set_value("Progress", "max_level_unlocked", max_level_unlocked)
	for level_id in level_scores:
		config.set_value("Progress", "level_%d_score" % level_id, level_scores[level_id])
	config.save(SAVE_PATH)

func logout() -> void:
	user_name = "Guest"
	user_age = 0
	current_level = 1
	current_level_score = 0
	max_level_unlocked = 1
	level_scores.clear()
	# Delete save file
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)