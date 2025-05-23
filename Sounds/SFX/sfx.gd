extends Node
@onready var streamPlayer: AudioStreamPlayer = $AudioStreamPlayer
@onready var movementPlayer: AudioStreamPlayer = $MovementSFXPlayer
enum SFX {
	MOUSE_CLICK,
	WALKING_GRASS,
	HURT_MALE
}

var TRACKS = {
	SFX.MOUSE_CLICK: [preload("res://Sounds/SFX/UI/MouseClick.mp3"), preload("res://Sounds/SFX/UI/mech-keyboard-02-102918.mp3")],
	SFX.WALKING_GRASS: [preload("res://Sounds/SFX/footstep01.wav"), preload("res://Sounds/SFX/footstep02.mp3")],
	SFX.HURT_MALE: [preload("res://Sounds/SFX/Hurt sounds (Male)/aargh0.ogg"), preload("res://Sounds/SFX/Hurt sounds (Male)/aargh2.ogg"), preload("res://Sounds/SFX/Hurt sounds (Male)/aargh4.ogg"), preload("res://Sounds/SFX/Hurt sounds (Male)/aargh6.ogg")] 
	#THEMES.BATTLE: [preload("res://Sounds/Music/The Depths of Hell.mp3")]
}

var current_sfx: int = SFX.WALKING_GRASS
var is_repeating: bool = false

func play_sfx(sfx: int, repeat_sfx: bool = true):
	if current_sfx != sfx or !streamPlayer.playing or !movementPlayer.playing:
		is_repeating = false # Prevent accidentally starting an old track playing
								# again when next command is stop()
		streamPlayer.stop()
		movementPlayer.stop()
		
		is_repeating = repeat_sfx
		current_sfx = sfx
		
		var sfx_tracks: Array = TRACKS[current_sfx]
		if sfx_tracks != []:
			if current_sfx == SFX.WALKING_GRASS:
				movementPlayer.stream = sfx_tracks[randi() % sfx_tracks.size()]
				movementPlayer.play()
			else:
				streamPlayer.stream = sfx_tracks[randi() % sfx_tracks.size()]
				streamPlayer.play()

func replay_current_sfx():
	var sfx_tracks: Array = TRACKS[current_sfx]
	if current_sfx == SFX.WALKING_GRASS:
		movementPlayer.stream = sfx_tracks[randi() % sfx_tracks.size()]
		movementPlayer.play()
	else:
		streamPlayer.stream = sfx_tracks[randi() % sfx_tracks.size()]
		streamPlayer.play()

func _on_audio_stream_player_finished():
	gameplay_sfx_stop()

func gameplay_sfx_stop():
	streamPlayer.stop()

func movement_sfx_stop():
	movementPlayer.stop()
