# Ad Manager — Handles AdMob interstitial & rewarded ads
# Autoload as: AdManager
#
# Uses the Poing AdMob plugin for Godot 4:
#   https://github.com/poing-studios/godot-admob-android
#
# On non-Android platforms (desktop/web), ads are silently skipped.
# All ad unit IDs are loaded from ad_config.gd (gitignored).
extends Node

# --- STATE ---
var _is_android: bool = false
var _admob: Object = null  # MobileAds singleton from plugin
var _interstitial_loaded: bool = false
var _rewarded_loaded: bool = false
var _rewarded_callback: Callable = Callable()

# Frequency cap: show interstitial every N levels (not every single one)
const INTERSTITIAL_FREQUENCY: int = 3
var _levels_since_last_ad: int = 0

signal interstitial_closed
signal rewarded_earned
signal rewarded_failed

func _ready() -> void:
	_is_android = OS.get_name() == "Android"
	if not _is_android:
		return

	# Check if AdMob plugin is available
	if Engine.has_singleton("AdMob"):
		_admob = Engine.get_singleton("AdMob")
		_initialize_admob()
	else:
		push_warning("AdManager: AdMob plugin not found. Ads disabled.")

func _initialize_admob() -> void:
	if not _admob:
		return

	# Initialize with test mode based on config
	var _is_test: bool = true
	if ClassDB.class_exists("AdConfig"):
		_is_test = AdConfig.USE_TEST_ADS

	_admob.initialize()

	# Connect signals
	if _admob.has_signal("initialization_completed"):
		_admob.initialization_completed.connect(_on_admob_initialized)

func _on_admob_initialized() -> void:
	load_interstitial()
	load_rewarded()

# ===================================================================
# INTERSTITIAL ADS — Between levels
# ===================================================================

func load_interstitial() -> void:
	if not _admob:
		return
	var unit_id: String = _get_interstitial_id()
	if unit_id.is_empty():
		return

	if _admob.has_method("load_interstitial"):
		_admob.load_interstitial(unit_id)

	if _admob.has_signal("interstitial_loaded"):
		if not _admob.interstitial_loaded.is_connected(_on_interstitial_loaded):
			_admob.interstitial_loaded.connect(_on_interstitial_loaded)
	if _admob.has_signal("interstitial_closed"):
		if not _admob.interstitial_closed.is_connected(_on_interstitial_closed):
			_admob.interstitial_closed.connect(_on_interstitial_closed)
	if _admob.has_signal("interstitial_failed_to_load"):
		if not _admob.interstitial_failed_to_load.is_connected(_on_interstitial_failed):
			_admob.interstitial_failed_to_load.connect(_on_interstitial_failed)

func show_interstitial_if_ready() -> void:
	"""Call this after level completion. Respects frequency cap."""
	_levels_since_last_ad += 1
	if _levels_since_last_ad < INTERSTITIAL_FREQUENCY:
		interstitial_closed.emit()
		return
	if not _is_android or not _admob or not _interstitial_loaded:
		interstitial_closed.emit()
		return
	_levels_since_last_ad = 0
	if _admob.has_method("show_interstitial"):
		_admob.show_interstitial()
	else:
		interstitial_closed.emit()

func _on_interstitial_loaded() -> void:
	_interstitial_loaded = true

func _on_interstitial_closed() -> void:
	_interstitial_loaded = false
	interstitial_closed.emit()
	# Pre-load next one
	load_interstitial()

func _on_interstitial_failed(_error_code: int = 0) -> void:
	_interstitial_loaded = false

# ===================================================================
# REWARDED ADS — Watch ad for hints
# ===================================================================

func load_rewarded() -> void:
	if not _admob:
		return
	var unit_id: String = _get_rewarded_id()
	if unit_id.is_empty():
		return

	if _admob.has_method("load_rewarded"):
		_admob.load_rewarded(unit_id)

	if _admob.has_signal("rewarded_ad_loaded"):
		if not _admob.rewarded_ad_loaded.is_connected(_on_rewarded_loaded):
			_admob.rewarded_ad_loaded.connect(_on_rewarded_loaded)
	if _admob.has_signal("rewarded_ad_closed"):
		if not _admob.rewarded_ad_closed.is_connected(_on_rewarded_closed):
			_admob.rewarded_ad_closed.connect(_on_rewarded_closed)
	if _admob.has_signal("user_earned_reward"):
		if not _admob.user_earned_reward.is_connected(_on_reward_earned):
			_admob.user_earned_reward.connect(_on_reward_earned)
	if _admob.has_signal("rewarded_ad_failed_to_load"):
		if not _admob.rewarded_ad_failed_to_load.is_connected(_on_rewarded_failed):
			_admob.rewarded_ad_failed_to_load.connect(_on_rewarded_failed)

func show_rewarded(on_reward: Callable = Callable()) -> void:
	"""Show a rewarded ad. Calls on_reward if user earns the reward."""
	_rewarded_callback = on_reward
	if not _is_android or not _admob or not _rewarded_loaded:
		# No ad available — grant reward for free (graceful fallback)
		if on_reward.is_valid():
			on_reward.call()
		rewarded_failed.emit()
		return
	if _admob.has_method("show_rewarded"):
		_admob.show_rewarded()
	else:
		if on_reward.is_valid():
			on_reward.call()
		rewarded_failed.emit()

func is_rewarded_ready() -> bool:
	return _is_android and _rewarded_loaded

func _on_rewarded_loaded() -> void:
	_rewarded_loaded = true

func _on_reward_earned(_type: String = "", _amount: int = 0) -> void:
	if _rewarded_callback.is_valid():
		_rewarded_callback.call()
	_rewarded_callback = Callable()
	rewarded_earned.emit()

func _on_rewarded_closed() -> void:
	_rewarded_loaded = false
	_rewarded_callback = Callable()
	# Pre-load next one
	load_rewarded()

func _on_rewarded_failed(_error_code: int = 0) -> void:
	_rewarded_loaded = false

# ===================================================================
# HELPERS
# ===================================================================

func _get_interstitial_id() -> String:
	if not ClassDB.class_exists("AdConfig"):
		return ""
	if AdConfig.USE_TEST_ADS:
		return AdConfig.TEST_INTERSTITIAL_ID
	return AdConfig.INTERSTITIAL_ID

func _get_rewarded_id() -> String:
	if not ClassDB.class_exists("AdConfig"):
		return ""
	if AdConfig.USE_TEST_ADS:
		return AdConfig.TEST_REWARDED_ID
	return AdConfig.REWARDED_ID

func _get_banner_id() -> String:
	if not ClassDB.class_exists("AdConfig"):
		return ""
	if AdConfig.USE_TEST_ADS:
		return AdConfig.TEST_BANNER_ID
	return AdConfig.BANNER_ID
