class_name TimeHelper
extends Node # Needs to be node in order to have the `_process` function

# This script is loaded into the helper.gd autoload singleton
# It can be accessed through Helper.time_helper
# This is a helper script that manages time, supporting many game mechanics.

# Internal state
var _elapsed_time: float = 0.0  # Total elapsed time for the current game session (in seconds)
var _is_tracking_time: bool = false  # Flag to track if we are actively counting time
var _last_tick_time: int = 0  # The last recorded tick time (in milliseconds)

# --- Constants ---
const DAYTIME_MINUTES: int = 20  # Daytime in real-life minutes
const NIGHTTIME_MINUTES: int = 15  # Nighttime in real-life minutes
const DAY_DURATION_MINUTES: int = DAYTIME_MINUTES + NIGHTTIME_MINUTES  # Total real-life minutes per day
const IN_GAME_DAY_MINUTES: int = 24 * 60  # Total in-game minutes in a day

# Signal to notify when an in-game minute has passed
signal minute_passed(current_time: String)
# Internal state to track the last emitted in-game minute
var _last_emitted_minute: int = -1


func _ready():
	_connect_signals() # Connect signals for game state changes


func _process(_delta: float):
	if _is_tracking_time:
		_update_elapsed_time()
		_emit_minute_if_needed()


# --- Private Methods ---

# Connects signals for game lifecycle events.
func _connect_signals():
	Helper.signal_broker.game_started.connect(_on_game_started)
	Helper.signal_broker.game_loaded.connect(_on_game_loaded)
	Helper.signal_broker.game_ended.connect(_on_game_ended)

# Updates the elapsed time based on ticks for precise time tracking.
func _update_elapsed_time():
	var current_ticks = Time.get_ticks_msec()
	_elapsed_time += (current_ticks - _last_tick_time) / 1000.0  # Convert milliseconds to seconds
	_last_tick_time = current_ticks


# Emits the `minute_passed` signal if a new in-game minute has elapsed.
func _emit_minute_if_needed():
	var current_in_game_minutes = get_current_in_game_minutes()
	if current_in_game_minutes != _last_emitted_minute:
		_last_emitted_minute = current_in_game_minutes
		var current_time = get_current_time()
		minute_passed.emit(current_time)


# --- Signal Handlers ---
# Called when a new game starts. Resets time tracking and begins counting from zero.
func _on_game_started():
	# Start the game with 8 in-game hours already passed
	# Calculate the real-life time equivalent to 8 in-game hours
	var in_game_hours = 8
	var in_game_minutes = in_game_hours * 60  # 8 hours * 60 minutes
	_elapsed_time = (in_game_minutes / float(IN_GAME_DAY_MINUTES)) * DAY_DURATION_MINUTES * 60  # Convert to real-life seconds
	
	_start_tracking_time()


# Called when a game is loaded. Resumes time tracking from the saved time.
func _on_game_loaded():
	#_elapsed_time = saved_time  # Resume from the saved time
	_start_tracking_time()

# Called when the game ends. Stops time tracking.
func _on_game_ended():
	_stop_tracking_time()

# --- Private Helpers ---

# Starts time tracking by recording the current tick time.
func _start_tracking_time():
	_last_tick_time = Time.get_ticks_msec()
	_is_tracking_time = true

# Stops time tracking by clearing the tracking flag.
func _stop_tracking_time():
	_is_tracking_time = false

# --- Public API ---

# Returns the total elapsed time in seconds for the current session.
func get_elapsed_time() -> float:
	return _elapsed_time


# Sets the elapsed time for saving/loading purposes.
# Resets the reference for accurate tracking.
func set_elapsed_time(new_time: float):
	_elapsed_time = new_time
	if _is_tracking_time:
		_last_tick_time = Time.get_ticks_msec()


# Returns the time difference between a given past time and the current time in seconds.
func get_time_difference(past_time: float) -> float:
	return max(0.0, _elapsed_time - past_time)


# Returns the number of in-game days since the start
func get_days_since_start() -> float:
	return float(_elapsed_time / (DAY_DURATION_MINUTES * 60))  # Convert minutes to seconds


# The current time string, representing the time of day
func get_current_time() -> String:
	# Use get_current_in_game_minutes to get the current in-game minutes
	var current_minutes_of_day = get_current_in_game_minutes()

	# Calculate hours and minutes
	var hours: int = current_minutes_of_day / 60.0
	var minutes: int = current_minutes_of_day % 60

	return "%02d:%02d" % [hours, minutes]


# Returns a percentage between 0 and 100, indicating how much of the day has progressed.
func get_day_progress_percentage() -> float:
	# Use get_current_in_game_minutes to get the current in-game minutes
	var current_minutes_of_day = get_current_in_game_minutes()

	# Calculate percentage of the day completed
	return (current_minutes_of_day / float(IN_GAME_DAY_MINUTES)) * 100.0


# Returns the current number of in-game minutes into the day (0-1440).
func get_current_in_game_minutes() -> int:
	var day_seconds = DAY_DURATION_MINUTES * 60.0
	var scaled_minutes = (_elapsed_time / day_seconds) * IN_GAME_DAY_MINUTES
	return int(scaled_minutes) % IN_GAME_DAY_MINUTES


# Returns a number representing the current hour. For example:
# Midnight will return 0.0
# Noon will return 12.0
# 10:14 will return 10.1
func get_time_in_hr() -> float:
	# Get the current in-game minutes
	var current_minutes_of_day = get_current_in_game_minutes()
	
	# Map the current in-game minutes (0 to 1440) to animation frames (0 to 24)
	return float(current_minutes_of_day) / IN_GAME_DAY_MINUTES * 24.0
