# Music Manager — procedural evolving soundtrack for Circuit Weaver
# Autoload as: MusicManager
#
# Layered generative music: warm pads with chord progressions, melodic arps,
# rhythmic bass, and subtle percussive texture. Each chapter brings a
# different key, chord set, tempo, and mood.
extends Node

# --- SETTINGS ---

var music_volume: float = 0.5:
	set(v):
		music_volume = clampf(v, 0.0, 1.0)
		_apply_volume()

var music_enabled: bool = true:
	set(v):
		music_enabled = v
		if not v:
			_stop_all()
		elif _playing:
			_rebuild_and_play()

# --- INTERNALS ---

var _playing: bool = false
var _current_chapter: int = 1
const SAMPLE_RATE: int = 22050

# Players — one per layer
var _pad_player: AudioStreamPlayer
var _bass_player: AudioStreamPlayer
var _arp_player: AudioStreamPlayer
var _perc_player: AudioStreamPlayer
var _texture_player: AudioStreamPlayer

# Timing
var _beat_timer: float = 0.0
var _beat_index: int = 0        # counts every 8th note
var _arp_index: int = 0
var _chord_index: int = 0       # index into current progression
var _pad_refresh_timer: float = 0.0

# Chapter definitions: root Hz, tempo, chord intervals, arp mode, mood
const CHAPTER_DATA: Array[Dictionary] = [
	{   # Chapter 1 — Clean & curious (C major)
		"root": 261.63,
		"bpm": 90,
		"chords": [[0,4,7], [5,9,12], [7,11,14], [0,4,7,11]],
		"arp_pattern": [0, 4, 7, 12, 7, 4],
		"arp_octave": 2.0,
		"bass_pattern": [1,0,0,1, 0,0,1,0],  # 8th note hits
		"pad_wave": "triangle",
		"arp_wave": "sine",
	},
	{   # Chapter 2 — Warm & flowing (D dorian)
		"root": 293.66,
		"bpm": 100,
		"chords": [[0,3,7], [5,8,12], [7,10,14], [0,3,7,10]],
		"arp_pattern": [0, 3, 7, 10, 12, 10, 7, 3],
		"arp_octave": 2.0,
		"bass_pattern": [1,0,1,0, 0,1,0,0],
		"pad_wave": "soft_saw",
		"arp_wave": "triangle",
	},
	{   # Chapter 3 — Tense & focused (F minor)
		"root": 349.23,
		"bpm": 108,
		"chords": [[0,3,7], [0,3,8], [5,8,12], [7,10,14]],
		"arp_pattern": [0, 7, 3, 12, 0, 10, 7, 3],
		"arp_octave": 1.5,
		"bass_pattern": [1,0,0,1, 0,1,0,1],
		"pad_wave": "soft_saw",
		"arp_wave": "sine",
	},
	{   # Chapter 4 — Epic & triumphant (A major)
		"root": 440.0,
		"bpm": 116,
		"chords": [[0,4,7,11], [5,9,12,16], [7,11,14], [0,4,7]],
		"arp_pattern": [0, 4, 7, 11, 12, 11, 7, 4, 0, -1, 4, 7],
		"arp_octave": 2.0,
		"bass_pattern": [1,0,1,0, 1,0,0,1],
		"pad_wave": "triangle",
		"arp_wave": "triangle",
	},
]

func _ready() -> void:
	_pad_player = _create_player("PadPlayer")
	_bass_player = _create_player("BassPlayer")
	_arp_player = _create_player("ArpPlayer")
	_perc_player = _create_player("PercPlayer")
	_texture_player = _create_player("TexturePlayer")
	load_music_settings()

func _create_player(pname: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = pname
	p.bus = "Master"
	add_child(p)
	return p

func _process(delta: float) -> void:
	if not _playing or not music_enabled:
		return

	var data: Dictionary = CHAPTER_DATA[_current_chapter - 1]
	var beat_dur: float = 60.0 / float(data["bpm"]) / 2.0  # 8th note duration

	_beat_timer += delta
	if _beat_timer >= beat_dur:
		_beat_timer -= beat_dur
		_on_eighth_note(data)
		_beat_index += 1

	_pad_refresh_timer += delta
	var chord_dur: float = beat_dur * 8.0
	var chords_size: int = data["chords"].size()
	if _pad_refresh_timer >= chord_dur:
		_pad_refresh_timer -= chord_dur
		_chord_index = (_chord_index + 1) % chords_size
		_play_pad_chord(data)

func _on_eighth_note(data: Dictionary) -> void:
	var bass_pat: Array = data["bass_pattern"]
	var local_beat: int = _beat_index % bass_pat.size()

	# Bass on pattern hits
	if bass_pat[local_beat] == 1:
		_play_bass_note(data)

	# Arp — play every other 8th (i.e. every quarter) for most chapters
	# But chapter 4 plays every 8th for energy
	var arp_every: int = 2 if _current_chapter < 4 else 1
	if _beat_index % arp_every == 0:
		_play_arp_note(data)

	# Subtle percussion (hi-hat noise) on every 8th
	_play_perc_tick()

# --- PUBLIC API ---

func start_music(chapter: int = -1) -> void:
	if chapter < 1 or chapter > 4:
		chapter = _detect_chapter()
	_current_chapter = chapter
	_playing = true
	_beat_index = 0
	_arp_index = 0
	_chord_index = 0
	_beat_timer = 0.0
	_pad_refresh_timer = 0.0
	if music_enabled:
		_rebuild_and_play()

func stop_music() -> void:
	_playing = false
	_stop_all()

func set_chapter(chapter: int) -> void:
	if chapter == _current_chapter:
		return
	_current_chapter = clampi(chapter, 1, 4)
	_chord_index = 0
	_arp_index = 0
	_beat_index = 0
	if _playing and music_enabled:
		_stop_all()
		_rebuild_and_play()

# --- OSCILLATORS ---

func _osc_sine(phase: float) -> float:
	return sin(phase)

func _osc_triangle(phase: float) -> float:
	var p: float = fmod(phase / TAU, 1.0)
	if p < 0.0:
		p += 1.0
	return 4.0 * absf(p - 0.5) - 1.0

func _osc_soft_saw(phase: float) -> float:
	# Band-limited-ish soft sawtooth (first 4 harmonics)
	return (
		sin(phase)
		- 0.5 * sin(phase * 2.0)
		+ 0.33 * sin(phase * 3.0)
		- 0.25 * sin(phase * 4.0)
	) * 0.6

func _oscillate(wave_type: String, phase: float) -> float:
	match wave_type:
		"triangle": return _osc_triangle(phase)
		"soft_saw": return _osc_soft_saw(phase)
		_:          return _osc_sine(phase)

# --- PAD ---

func _rebuild_and_play() -> void:
	var data: Dictionary = CHAPTER_DATA[_current_chapter - 1]
	_play_pad_chord(data)
	_play_ambient_texture(data)

func _play_pad_chord(data: Dictionary) -> void:
	var root: float = data["root"]
	var chord: Array = data["chords"][_chord_index]
	var wave_type: String = data["pad_wave"]
	var duration: float = 4.0
	var num_samples: int = int(SAMPLE_RATE * duration)
	var buf := PackedByteArray()
	buf.resize(num_samples * 2)

	var detune: float = 1.003  # slight chorus detune
	var vol: float = 0.06 * music_volume

	for i in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		# Envelope: 0.4s attack, hold, 0.6s release
		var env: float = 1.0
		if t < 0.4:
			env = t / 0.4
		elif t > duration - 0.6:
			env = (duration - t) / 0.6
		env = maxf(env, 0.0)

		var mix: float = 0.0
		for semitone in chord:
			var freq: float = root * pow(2.0, float(semitone) / 12.0)
			# Two detuned voices per note for warmth
			mix += _oscillate(wave_type, TAU * freq * t) * 0.5
			mix += _oscillate(wave_type, TAU * freq * detune * t) * 0.5

		mix = mix / float(chord.size()) * vol * env
		var si: int = clampi(int(mix * 32767.0), -32768, 32767)
		buf[i * 2] = si & 0xFF
		buf[i * 2 + 1] = (si >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = buf
	# Loop the sustain portion
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = int(SAMPLE_RATE * 0.5)
	stream.loop_end = num_samples - int(SAMPLE_RATE * 0.6)

	_pad_player.stream = stream
	_pad_player.volume_db = linear_to_db(music_volume * 0.75)
	_pad_player.play()

# --- BASS ---

func _play_bass_note(data: Dictionary) -> void:
	var root: float = data["root"]
	var chord: Array = data["chords"][_chord_index]
	# Bass plays the chord root an octave down
	var bass_freq: float = root * pow(2.0, float(chord[0]) / 12.0) * 0.5
	var duration: float = 0.3
	var num_samples: int = int(SAMPLE_RATE * duration)
	var buf := PackedByteArray()
	buf.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 6.0) * (1.0 - exp(-t * 100.0))
		# Triangle wave for warm bass
		var sample_f: float = _osc_triangle(TAU * bass_freq * t) * 0.14 * env * music_volume
		# Add sub-octave sine for depth
		sample_f += sin(TAU * bass_freq * 0.5 * t) * 0.08 * env * music_volume
		var si: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		buf[i * 2] = si & 0xFF
		buf[i * 2 + 1] = (si >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = buf

	_bass_player.stream = stream
	_bass_player.volume_db = linear_to_db(music_volume * 0.55)
	_bass_player.play()

# --- ARPEGGIO ---

func _play_arp_note(data: Dictionary) -> void:
	var root: float = data["root"]
	var pattern: Array = data["arp_pattern"]
	var semitone: int = pattern[_arp_index % pattern.size()]
	_arp_index += 1

	# Offset by current chord root
	var chord: Array = data["chords"][_chord_index]
	semitone += chord[0]

	var freq: float = root * pow(2.0, float(semitone) / 12.0)
	freq *= data["arp_octave"]  # octave shift

	var wave_type: String = data["arp_wave"]
	var duration: float = 0.22
	var num_samples: int = int(SAMPLE_RATE * duration)
	var buf := PackedByteArray()
	buf.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		# Plucky envelope
		var env: float = exp(-t * 10.0) * (1.0 - exp(-t * 120.0))
		var sample_f: float = _oscillate(wave_type, TAU * freq * t) * 0.065 * env * music_volume
		# Add a soft harmonic at 2× for shimmer
		sample_f += _osc_sine(TAU * freq * 2.0 * t) * 0.02 * env * music_volume
		var si: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		buf[i * 2] = si & 0xFF
		buf[i * 2 + 1] = (si >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = buf

	_arp_player.stream = stream
	_arp_player.volume_db = linear_to_db(music_volume * 0.5)
	_arp_player.play()

# --- PERCUSSION ---

func _play_perc_tick() -> void:
	var duration: float = 0.04
	var num_samples: int = int(SAMPLE_RATE * duration)
	var buf := PackedByteArray()
	buf.resize(num_samples * 2)

	for i in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 80.0)
		# Filtered noise — simple random with fast decay
		var noise: float = randf_range(-1.0, 1.0)
		var sample_f: float = noise * 0.03 * env * music_volume
		var si: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		buf[i * 2] = si & 0xFF
		buf[i * 2 + 1] = (si >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = buf

	_perc_player.stream = stream
	_perc_player.volume_db = linear_to_db(music_volume * 0.3)
	_perc_player.play()

# --- AMBIENT TEXTURE ---

func _play_ambient_texture(data: Dictionary) -> void:
	var duration: float = 8.0
	var num_samples: int = int(SAMPLE_RATE * duration)
	var buf := PackedByteArray()
	buf.resize(num_samples * 2)

	# Simple low-pass filter state
	var lp: float = 0.0
	var cutoff: float = 0.005 + 0.003 * float(_current_chapter)  # brighter per chapter

	for i in range(num_samples):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = 1.0
		if t < 2.0:
			env = t / 2.0
		elif t > duration - 2.0:
			env = (duration - t) / 2.0
		env = maxf(env, 0.0)

		var noise: float = randf_range(-1.0, 1.0)
		lp += cutoff * (noise - lp)  # one-pole lowpass
		var sample_f: float = lp * 0.04 * env * music_volume
		var si: int = clampi(int(sample_f * 32767.0), -32768, 32767)
		buf[i * 2] = si & 0xFF
		buf[i * 2 + 1] = (si >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = buf
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = int(SAMPLE_RATE * 2.0)
	stream.loop_end = num_samples - int(SAMPLE_RATE * 2.0)

	_texture_player.stream = stream
	_texture_player.volume_db = linear_to_db(music_volume * 0.35)
	_texture_player.play()

# --- HELPERS ---

func _stop_all() -> void:
	for p: AudioStreamPlayer in [_pad_player, _bass_player, _arp_player, _perc_player, _texture_player]:
		if p:
			p.stop()

func _apply_volume() -> void:
	if _pad_player:
		_pad_player.volume_db = linear_to_db(music_volume * 0.75)
	if _arp_player:
		_arp_player.volume_db = linear_to_db(music_volume * 0.5)
	if _bass_player:
		_bass_player.volume_db = linear_to_db(music_volume * 0.55)
	if _perc_player:
		_perc_player.volume_db = linear_to_db(music_volume * 0.3)
	if _texture_player:
		_texture_player.volume_db = linear_to_db(music_volume * 0.35)

func _detect_chapter() -> int:
	var lvl: int = Global.current_level
	if lvl <= 5:
		return 1
	elif lvl <= 13:
		return 2
	elif lvl <= 17:
		return 3
	else:
		return 4

# --- PERSISTENCE ---

func save_music_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(Global.SAVE_PATH)
	cfg.set_value("Settings", "music_volume", music_volume)
	cfg.set_value("Settings", "music_enabled", music_enabled)
	cfg.save(Global.SAVE_PATH)

func load_music_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Global.SAVE_PATH) == OK:
		music_volume = cfg.get_value("Settings", "music_volume", 0.5)
		music_enabled = cfg.get_value("Settings", "music_enabled", true)
