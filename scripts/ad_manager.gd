# Ad Manager — Handles AdMob interstitial & rewarded ads
# Autoload as: AdManager
#
# Uses the Poing AdMob plugin for Godot 4:
#   https://github.com/poing-studios/godot-admob-android
#
# On non-Android platforms (desktop/web), ads are silently skipped.
# All ad unit IDs are loaded from ad_config.gd.
#
# Pattern follows the official Poing sample:
#   Callbacks created ONCE as class members
#   Load callbacks use named methods (not lambdas)
#   FullScreenContentCallback set AFTER ad loads
extends Node

# --- STATE ---
var _is_android: bool = false
var _initialized: bool = false
var _interstitial_ad: InterstitialAd = null
var _rewarded_ad: RewardedAd = null
var _rewarded_callback: Callable = Callable()

# Callback objects — strong references for the life of the game
var _interstitial_load_cb: InterstitialAdLoadCallback
var _interstitial_content_cb: FullScreenContentCallback
var _rewarded_load_cb: RewardedAdLoadCallback
var _rewarded_content_cb: FullScreenContentCallback

# Loaders — strong references to prevent GC during async load
var _interstitial_loader: InterstitialAdLoader
var _rewarded_loader: RewardedAdLoader

# Frequency cap: show interstitial every N levels
const INTERSTITIAL_FREQUENCY: int = 3
var _levels_since_last_ad: int = 0

signal interstitial_closed
signal rewarded_earned
signal rewarded_failed

func _ready() -> void:
	print("ADMOB: AdManager._ready() — instance: %d" % get_instance_id())
	_is_android = OS.get_name() == "Android"
	if not _is_android:
		return
		
	_setup_callbacks()
	
	# Give the engine one frame to ensure all objects are registered
	# before triggering the AdMob initialization sequence.
	get_tree().process_frame.connect(_initialize_admob, CONNECT_ONE_SHOT)

func _setup_callbacks() -> void:
	# Initialize all callbacks exactly ONCE to keep Callables permanently bound to 'self'
	_interstitial_load_cb = InterstitialAdLoadCallback.new()
	_interstitial_load_cb.on_ad_loaded = _on_interstitial_loaded
	_interstitial_load_cb.on_ad_failed_to_load = _on_interstitial_failed_to_load

	_interstitial_content_cb = FullScreenContentCallback.new()
	_interstitial_content_cb.on_ad_dismissed_full_screen_content = _on_interstitial_dismissed
	_interstitial_content_cb.on_ad_failed_to_show_full_screen_content = _on_interstitial_failed_to_show

	_rewarded_load_cb = RewardedAdLoadCallback.new()
	_rewarded_load_cb.on_ad_loaded = _on_rewarded_loaded
	_rewarded_load_cb.on_ad_failed_to_load = _on_rewarded_failed_to_load

	_rewarded_content_cb = FullScreenContentCallback.new()
	_rewarded_content_cb.on_ad_dismissed_full_screen_content = _on_rewarded_dismissed
	_rewarded_content_cb.on_ad_failed_to_show_full_screen_content = _on_rewarded_failed_to_show

# ===================================================================
# INITIALIZATION
# ===================================================================

func _initialize_admob() -> void:
	if _initialized:
		return
	# ── COPPA / GDPR: Child-directed treatment ──────────────────────
	# Required because the app targets children (ages 5+).
	# tag_for_child_directed_treatment = true  → disables interest-based ads (COPPA)
	# tag_for_under_age_of_consent    = true  → disables personalized ads  (GDPR)
	var config := RequestConfiguration.new()
	config.tag_for_child_directed_treatment = RequestConfiguration.TagForChildDirectedTreatment.TRUE
	config.tag_for_under_age_of_consent = RequestConfiguration.TagForUnderAgeOfConsent.TRUE
	config.max_ad_content_rating = RequestConfiguration.MaxAdContentRating.G
	MobileAds.set_request_configuration(config)
	print("ADMOB: Set child-directed treatment + under-age-of-consent + max rating G")

	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_admob_initialized
	MobileAds.initialize(listener)
	print("ADMOB: Initializing...")

func _on_admob_initialized(_status: InitializationStatus) -> void:
	_initialized = true
	print("ADMOB: Initialized successfully")
	load_interstitial()
	load_rewarded()

# ===================================================================
# INTERSTITIAL ADS — Between levels
# ===================================================================

func load_interstitial() -> void:
	if not _is_android or not _initialized:
		return
	var unit_id: String = _get_interstitial_id()
	print("ADMOB: Loading interstitial with ID: '%s'" % unit_id)
	if unit_id.is_empty():
		return

	_interstitial_loader = InterstitialAdLoader.new()
	_interstitial_loader.load(unit_id, AdRequest.new(), _interstitial_load_cb)
	print("ADMOB: Interstitial load request sent")

func show_interstitial_if_ready() -> void:
	"""Call this after level completion. Respects frequency cap."""
	_levels_since_last_ad += 1
	if _levels_since_last_ad < INTERSTITIAL_FREQUENCY:
		interstitial_closed.emit()
		return
	if not _is_android or _interstitial_ad == null:
		print("ADMOB: Ad was null, could not call show.")
		interstitial_closed.emit()
		return
	
	if is_instance_valid(_interstitial_ad):
		_levels_since_last_ad = 0
		_interstitial_ad.show()
		print("ADMOB: Showing interstitial")
	else:
		print("ADMOB: Interstitial ad instance invalid.")
		_interstitial_ad = null
		interstitial_closed.emit()

# --- Interstitial callbacks ---

func _on_interstitial_loaded(ad: InterstitialAd) -> void:
	print("ADMOB: Interstitial loaded!")
	ad.full_screen_content_callback = _interstitial_content_cb
	_interstitial_ad = ad

func _on_interstitial_failed_to_load(error: LoadAdError) -> void:
	print("ADMOB: Interstitial failed to load: %s" % error.message)
	_interstitial_ad = null

func _on_interstitial_dismissed() -> void:
	print("ADMOB: Interstitial dismissed")
	if _interstitial_ad:
		_interstitial_ad.destroy()
	_interstitial_ad = null
	interstitial_closed.emit()
	load_interstitial()

func _on_interstitial_failed_to_show(_error: AdError) -> void:
	print("ADMOB: Interstitial failed to show")
	_interstitial_ad = null
	interstitial_closed.emit()
	load_interstitial()

# ===================================================================
# REWARDED ADS — Watch ad for hints
# ===================================================================

func load_rewarded() -> void:
	if not _is_android or not _initialized:
		return
	var unit_id: String = _get_rewarded_id()
	if unit_id.is_empty():
		return
		
	_rewarded_loader = RewardedAdLoader.new()
	_rewarded_loader.load(unit_id, AdRequest.new(), _rewarded_load_cb)
	print("ADMOB: Loading rewarded...")

func show_rewarded(on_reward: Callable = Callable()) -> void:
	"""Show a rewarded ad. Calls on_reward if user earns the reward."""
	_rewarded_callback = on_reward
	if not _is_android or _rewarded_ad == null:
		print("ADMOB: Rewarded ad was null, granting reward gracefully.")
		# No ad available — grant reward for free (graceful fallback)
		if on_reward.is_valid():
			on_reward.call()
		rewarded_failed.emit()
		return

	if is_instance_valid(_rewarded_ad):
		var reward_listener := OnUserEarnedRewardListener.new()
		reward_listener.on_user_earned_reward = _on_user_earned_reward
		_rewarded_ad.show(reward_listener)
		print("ADMOB: Showing rewarded")
	else:
		print("ADMOB: Rewarded ad instance invalid.")
		_rewarded_ad = null
		if _rewarded_callback.is_valid():
			_rewarded_callback.call()
		_rewarded_callback = Callable()
		rewarded_failed.emit()

func is_rewarded_ready() -> bool:
	return _is_android and _rewarded_ad != null

# --- Rewarded callbacks ---

func _on_rewarded_loaded(ad: RewardedAd) -> void:
	print("ADMOB: Rewarded loaded!")
	ad.full_screen_content_callback = _rewarded_content_cb
	_rewarded_ad = ad

func _on_rewarded_failed_to_load(error: LoadAdError) -> void:
	print("ADMOB: Rewarded failed to load: %s" % error.message)
	_rewarded_ad = null

func _on_user_earned_reward(_item: RewardedItem) -> void:
	print("ADMOB: User earned reward")
	if _rewarded_callback.is_valid():
		_rewarded_callback.call()
	_rewarded_callback = Callable()
	rewarded_earned.emit()

func _on_rewarded_dismissed() -> void:
	print("ADMOB: Rewarded dismissed")
	if _rewarded_ad:
		_rewarded_ad.destroy()
	_rewarded_ad = null
	_rewarded_callback = Callable()
	load_rewarded()

func _on_rewarded_failed_to_show(_error: AdError) -> void:
	print("ADMOB: Rewarded failed to show")
	_rewarded_ad = null
	if _rewarded_callback.is_valid():
		_rewarded_callback.call()
	_rewarded_callback = Callable()
	rewarded_failed.emit()
	load_rewarded()

# ===================================================================
# HELPERS
# ===================================================================

func _get_interstitial_id() -> String:
	if AdConfig.USE_TEST_ADS:
		return AdConfig.TEST_INTERSTITIAL_ID
	return AdConfig.INTERSTITIAL_ID

func _get_rewarded_id() -> String:
	if AdConfig.USE_TEST_ADS:
		return AdConfig.TEST_REWARDED_ID
	return AdConfig.REWARDED_ID
