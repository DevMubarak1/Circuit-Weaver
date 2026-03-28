extends Node

var user_name: String = "Guest"
var user_age: int = 0
var is_child: bool = true  # Default to child-safe until age screen confirms otherwise
var current_level: int = 1
var current_level_score: int = 0  # 0-3 stars
var max_level_unlocked: int = 1

# Per-level scores: { level_id: stars }
var level_scores: Dictionary = {}

# --- ACHIEVEMENTS ---

const ACHIEVEMENT_DEFS: Dictionary = {
	"first_spark": {"title": "FIRST SPARK", "desc": "Complete your first level."},
	"perfect_score": {"title": "PERFECTIONIST", "desc": "Get 3 stars on any level."},
	"chapter_1": {"title": "CHAPTER 1 CLEAR", "desc": "Complete all Chapter 1 levels."},
	"chapter_2": {"title": "CHAPTER 2 CLEAR", "desc": "Complete all Chapter 2 levels."},
	"chapter_3": {"title": "CHAPTER 3 CLEAR", "desc": "Complete all Chapter 3 levels."},
	"chapter_4": {"title": "CHAPTER 4 CLEAR", "desc": "Complete all Chapter 4 levels."},
	"star_collector": {"title": "STAR COLLECTOR", "desc": "Earn 10 total stars."},
	"star_hoarder": {"title": "STAR HOARDER", "desc": "Earn 30 total stars."},
	"star_master": {"title": "STAR MASTER", "desc": "Earn all 60 stars."},
	"graduate": {"title": "CIRCUIT ARCHITECT", "desc": "Complete all 20 levels."},
	"half_adder": {"title": "HALF ADDER HERO", "desc": "Complete the Half Adder (Level 11)."},
	"universal_gate": {"title": "UNIVERSAL BUILDER", "desc": "Prove NAND universality (Level 15)."},
	"final_exam": {"title": "CERTIFIED ARCHITECT", "desc": "Pass the Final Exam (Level 20)."},
}

var achievements: Dictionary = {}

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

func unlock_achievement(ach_id: String) -> bool:
	"""Unlock an achievement. Returns true if newly unlocked, false if already had it."""
	if achievements.get(ach_id, false):
		return false
	achievements[ach_id] = true
	save_progress()
	return true

func has_achievement(ach_id: String) -> bool:
	return achievements.get(ach_id, false)

func get_unlocked_count() -> int:
	var count: int = 0
	for v in achievements.values():
		if v:
			count += 1
	return count

func check_and_unlock_achievements() -> Array[String]:
	"""Check all achievement conditions and return list of newly unlocked IDs."""
	var newly: Array[String] = []
	var total_stars: int = get_total_stars()
	var levels_completed: int = 0
	for i in range(1, 21):
		if level_scores.get(i, 0) > 0:
			levels_completed += 1

	# First level
	if levels_completed >= 1 and unlock_achievement("first_spark"):
		newly.append("first_spark")

	# Perfect score on any level
	for i in range(1, 21):
		if level_scores.get(i, 0) >= 3:
			if unlock_achievement("perfect_score"):
				newly.append("perfect_score")
			break

	# Chapter clears
	var ch1_done: bool = true
	for i in range(1, 6):
		if level_scores.get(i, 0) == 0:
			ch1_done = false
			break
	if ch1_done and unlock_achievement("chapter_1"):
		newly.append("chapter_1")

	var ch2_done: bool = true
	for i in range(6, 14):
		if level_scores.get(i, 0) == 0:
			ch2_done = false
			break
	if ch2_done and unlock_achievement("chapter_2"):
		newly.append("chapter_2")

	var ch3_done: bool = true
	for i in range(14, 18):
		if level_scores.get(i, 0) == 0:
			ch3_done = false
			break
	if ch3_done and unlock_achievement("chapter_3"):
		newly.append("chapter_3")

	var ch4_done: bool = true
	for i in range(18, 21):
		if level_scores.get(i, 0) == 0:
			ch4_done = false
			break
	if ch4_done and unlock_achievement("chapter_4"):
		newly.append("chapter_4")

	# Star milestones
	if total_stars >= 10 and unlock_achievement("star_collector"):
		newly.append("star_collector")
	if total_stars >= 30 and unlock_achievement("star_hoarder"):
		newly.append("star_hoarder")
	if total_stars >= 60 and unlock_achievement("star_master"):
		newly.append("star_master")

	# Graduate
	if levels_completed >= 20 and unlock_achievement("graduate"):
		newly.append("graduate")

	# Specific level achievements
	if level_scores.get(11, 0) > 0 and unlock_achievement("half_adder"):
		newly.append("half_adder")
	if level_scores.get(15, 0) > 0 and unlock_achievement("universal_gate"):
		newly.append("universal_gate")
	if level_scores.get(20, 0) > 0 and unlock_achievement("final_exam"):
		newly.append("final_exam")

	return newly

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
	is_child = config.get_value("Architect", "is_child", true)
	max_level_unlocked = config.get_value("Progress", "max_level_unlocked", 1)
	for i in range(1, 21):
		var score: int = config.get_value("Progress", "level_%d_score" % i, 0)
		if score > 0:
			level_scores[i] = score
	# Load achievements
	for ach_id in ACHIEVEMENT_DEFS:
		var unlocked: bool = config.get_value("Achievements", ach_id, false)
		if unlocked:
			achievements[ach_id] = true

func save_progress() -> void:
	var config := ConfigFile.new()
	var load_result = config.load(SAVE_PATH)
	if load_result != OK and load_result != ERR_FILE_NOT_FOUND:
		config = ConfigFile.new()  # Start fresh if load fails
	config.set_value("Architect", "name", user_name)
	config.set_value("Architect", "age", user_age)
	config.set_value("Architect", "is_child", is_child)
	config.set_value("Progress", "max_level_unlocked", max_level_unlocked)
	for level_id in level_scores:
		config.set_value("Progress", "level_%d_score" % level_id, level_scores[level_id])
	# Save achievements
	for ach_id in achievements:
		config.set_value("Achievements", ach_id, achievements[ach_id])
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save progress to %s (error %d)" % [SAVE_PATH, err])

func logout() -> void:
	user_name = "Guest"
	user_age = 0
	is_child = true
	current_level = 1
	current_level_score = 0
	max_level_unlocked = 1
	level_scores.clear()
	achievements.clear()
	# Delete save file
	if FileAccess.file_exists(SAVE_PATH):
		var err = DirAccess.remove_absolute(SAVE_PATH)
		if err != OK:
			push_error("Could not delete save file: %d" % err)