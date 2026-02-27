# SFX Manager — procedural synthesized audio for Circuit Weaver
# Autoload as: SFXManager
extends Node

# Audio buses
var _master_volume: float = 0.8
var _sfx_volume: float = 1.0

## Prevent set_volume_db receiving -INF or NaN when volume is zero.
func _safe_linear_to_db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))

# Cached AudioStreamPlayers
var _snap_player: AudioStreamPlayer
var _click_player: AudioStreamPlayer
var _hum_player: AudioStreamPlayer
var _fanfare_player: AudioStreamPlayer
var _error_player: AudioStreamPlayer

# Settings
var screen_shake_enabled: bool = true

func _ready() -> void:
	_snap_player = _create_player("SnapPlayer")
	_click_player = _create_player("ClickPlayer")
	_hum_player = _create_player("HumPlayer")
	_fanfare_player = _create_player("FanfarePlayer")
	_error_player = _create_player("ErrorPlayer")
	load_audio_settings()

func _create_player(player_name: String) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = "Master"
	add_child(player)
	return player

# --- PUBLIC API ---

func play_gate_snap() -> void:
	_play_tone(_snap_player, 1200.0, 0.06, 0.4)

func play_wire_click() -> void:
	_play_tone(_click_player, 600.0, 0.08, 0.5)

func play_simulation_hum(pitch_factor: float = 1.0) -> void:
	_play_tone(_hum_player, 120.0 * pitch_factor, 0.5, 0.15, true)

func stop_simulation_hum() -> void:
	if _hum_player.playing:
		# Fade out via tween
		var tw = create_tween()
		tw.tween_property(_hum_player, "volume_db", -40.0, 0.3)
		tw.tween_callback(_hum_player.stop)

func play_victory_fanfare(stars: int = 3) -> void:
	_play_arpeggio(_fanfare_player, stars)

func play_error_buzz() -> void:
	_play_tone(_error_player, 180.0, 0.15, 0.35)

func play_button_press() -> void:
	_play_tone(_snap_player, 900.0, 0.04, 0.25)

# --- VOLUME CONTROL ---

func set_master_volume(vol: float) -> void:
	_master_volume = clamp(vol, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, _safe_linear_to_db(_master_volume))

func get_master_volume() -> float:
	return _master_volume

func set_sfx_volume(vol: float) -> void:
	_sfx_volume = clamp(vol, 0.0, 1.0)

func get_sfx_volume() -> float:
	return _sfx_volume

func set_screen_shake(enabled: bool) -> void:
	screen_shake_enabled = enabled

func get_screen_shake() -> bool:
	return screen_shake_enabled

# --- SCREEN SHAKE ---

var _shake_tween: Tween = null

func apply_screen_shake(intensity: float = 4.0, duration: float = 0.25) -> void:
	if not screen_shake_enabled:
		return
	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return
	# Cancel any ongoing shake
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	var original_offset := Vector2.ZERO
	_shake_tween = create_tween()
	var steps: int = int(duration / 0.03)
	for i in range(steps):
		var strength: float = intensity * (1.0 - float(i) / steps)
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		_shake_tween.tween_property(cam, "offset", offset, 0.03)
	cam.offset = original_offset
	_shake_tween.tween_property(cam, "offset", original_offset, 0.03)

# --- PERSISTENCE ---

func save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.load(Global.SAVE_PATH)
	config.set_value("Settings", "master_volume", _master_volume)
	config.set_value("Settings", "sfx_volume", _sfx_volume)
	config.set_value("Settings", "screen_shake", screen_shake_enabled)
	config.save(Global.SAVE_PATH)

func load_audio_settings() -> void:
	var config := ConfigFile.new()
	if config.load(Global.SAVE_PATH) == OK:
		_master_volume = config.get_value("Settings", "master_volume", 0.8)
		_sfx_volume = config.get_value("Settings", "sfx_volume", 1.0)
		screen_shake_enabled = config.get_value("Settings", "screen_shake", true)
		AudioServer.set_bus_volume_db(0, _safe_linear_to_db(_master_volume))

# --- INTERNAL ---

func _play_tone(player: AudioStreamPlayer, freq: float, duration: float, volume: float, looping: bool = false) -> void:
	if player.playing and not looping:
		return

	var sample_rate: int = 22050
	var num_samples: int = int(sample_rate * duration)
	if looping:
		num_samples = sample_rate  # 1 second, will loop

	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.stereo = false
	if looping:
		audio.loop_mode = AudioStreamWAV.LOOP_FORWARD
		audio.loop_end = num_samples

	var data = PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / sample_rate
		# Envelope: quick attack, sustained, quick release
		var env: float = 1.0
		var attack: float = 0.005
		var release: float = min(0.02, duration * 0.3)
		if t < attack:
			env = t / attack
		elif not looping and t > (duration - release):
			env = (duration - t) / release

		var sample_val: float = sin(t * freq * TAU) * env * volume * _sfx_volume
		# Add subtle harmonics for richness
		sample_val += sin(t * freq * 2.0 * TAU) * env * volume * _sfx_volume * 0.15
		sample_val += sin(t * freq * 3.0 * TAU) * env * volume * _sfx_volume * 0.05

		var int_val: int = clampi(int(sample_val * 32767.0), -32768, 32767)
		data[i * 2] = int_val & 0xFF
		data[i * 2 + 1] = (int_val >> 8) & 0xFF

	audio.data = data
	player.stream = audio
	player.volume_db = _safe_linear_to_db(_master_volume)
	player.play()

func _play_arpeggio(player: AudioStreamPlayer, stars: int) -> void:
	# C5, E5, G5 for 3 stars; C5, E5 for 2; C5 for 1
	var freqs: Array[float] = [523.25]  # C5
	if stars >= 2:
		freqs.append(659.25)  # E5
	if stars >= 3:
		freqs.append(783.99)  # G5
		freqs.append(1046.50) # C6

	var sample_rate: int = 22050
	var note_len: float = 0.12
	var total_samples: int = int(sample_rate * note_len * freqs.size())

	var audio = AudioStreamWAV.new()
	audio.mix_rate = sample_rate
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(total_samples * 2)

	for n in range(freqs.size()):
		var f: float = freqs[n]
		var start_sample: int = int(n * note_len * sample_rate)
		var end_sample: int = int((n + 1) * note_len * sample_rate)
		end_sample = mini(end_sample, total_samples)
		for i in range(start_sample, end_sample):
			var t: float = float(i - start_sample) / sample_rate
			var env: float = 1.0
			if t < 0.005:
				env = t / 0.005
			elif t > (note_len - 0.015):
				env = (note_len - t) / 0.015
			env = maxf(env, 0.0)

			var sample_val: float = sin(t * f * TAU) * env * 0.4 * _sfx_volume
			sample_val += sin(t * f * 2.0 * TAU) * env * 0.1 * _sfx_volume

			var int_val: int = clampi(int(sample_val * 32767.0), -32768, 32767)
			data[i * 2] = int_val & 0xFF
			data[i * 2 + 1] = (int_val >> 8) & 0xFF

	audio.data = data
	player.stream = audio
	player.volume_db = _safe_linear_to_db(_master_volume)
	player.play()
