extends Node
class_name GameClock
# Hodinový clock pre gameplay. Pauza a rýchlosti ovládajú iba "game hours".
# Systémy, ktoré chcú byť pauzovateľné, NESMÚ používať _process(dt) ako zdroj času;
# nech odoberajú čas z GameClock-u cez signály (hour_changed alebo tick_hours).

signal tick_hours(delta_hours: float)                 # plynulý delta v hodinách (pre progress bary a animácie)
signal hour_changed(year: int, month_index: int, day: int, hour: int)  # diskretizovaný krok hodiny (pre gameplay)
signal minute_changed(year: int, month_index: int, day: int, hour: int, minute: int) # len pre UI

@export var real_seconds_per_game_hour: float = TimeCfg.REAL_SECONDS_PER_GAME_HOUR

var year: int = TimeCfg.START_YEAR
var month_index: int = TimeCfg.START_MONTH_INDEX
var day: int = TimeCfg.START_DAY
var hour: int = TimeCfg.START_HOUR
var minute_display: int = 0  # len pre UI (0..59) vypočítané z frakcie hodiny

var _time_speed_key: String = "x1"  # "pause" | "x1" | "x2" | "x4"
var time_scale: float = 1.0         # 0=pauza, 1=x1, 2=x2, 4=x4 ...

var _accum_hours: float = 0.0       # frakcia rozbehnutej hodiny (0..<1.0)
var _prev_minute_display: int = -1

func _ready() -> void:
	# uisti sa, že key aj scale sú zosúladené
	set_time_speed(_time_speed_key)
	_prev_minute_display = -1
	_emit_minute_if_changed()
	print("[GameClock] ready @ ", _time_text())

func _process(dt: float) -> void:
	if time_scale <= 0.0:
		return

	var delta_hours: float = 0.0
	if real_seconds_per_game_hour > 0.0:
		delta_hours = (dt * time_scale) / real_seconds_per_game_hour

	if delta_hours <= 0.0:
		return

	emit_signal("tick_hours", delta_hours)

	_accum_hours += delta_hours
	# Emuluj minúty pre UI (len text/animácie)
	_emit_minute_if_changed()

	while _accum_hours >= 1.0:
		_accum_hours -= 1.0
		_inc_hour()

func _inc_hour() -> void:
	hour += 1
	if hour >= TimeCfg.HOURS_PER_DAY:
		hour = 0
		_inc_day()

	emit_signal("hour_changed", year, month_index, day, hour)
	# po skoku hodiny tiež zaktualizuj minuto-displej
	_emit_minute_if_changed()

func _inc_day() -> void:
	day += 1
	if day > TimeCfg.DAYS_PER_MONTH:
		day = 1
		_inc_month()

func _inc_month() -> void:
	month_index += 1
	if month_index >= TimeCfg.MONTH_NAMES.size():
		month_index = 0
		year += 1

func _emit_minute_if_changed() -> void:
	# Pre UI: spočítaj "zobrazené minúty" z frakcie rozbehnutej hodiny.
	minute_display = int(floor(_accum_hours * 60.0)) % 60
	if minute_display != _prev_minute_display:
		_prev_minute_display = minute_display
		emit_signal("minute_changed", year, month_index, day, hour, minute_display)

# --- API ovládania rýchlosti / pauzy ----------------------------------------

func set_time_speed(key: String) -> void:
	# Použi centrálne TimeCfg.SPEEDS, nech sa nič nezdvojí
	var speeds := TimeCfg.SPEEDS
	if not speeds.has(key):
		push_warning("[GameClock] Unknown time speed key: " + str(key) + " (fallback x1)")
		key = "x1"
	_time_speed_key = key
	time_scale = float(speeds[key])
	print("[GameClock] time speed set -> ", key, " (scale=", time_scale, ")")

# alias pre staré volania
func set_speed(mode: String) -> void:
	set_time_speed(mode)

func pause() -> void:
	set_time_speed("pause")

func speed_x1() -> void:
	set_time_speed("x1")

func speed_x2() -> void:
	set_time_speed("x2")

func speed_x4() -> void:
	set_time_speed("x4")

func get_time_speed_key() -> String:
	return _time_speed_key

func get_time_scale() -> float:
	return time_scale

# --- Pomocné / formátovanie --------------------------------------------------

func month_name() -> String:
	return TimeCfg.MONTH_NAMES[clampi(month_index, 0, TimeCfg.MONTH_NAMES.size()-1)]

func _time_text() -> String:
	# "HH:MM  Day DD, Month YYYY"
	var hh := str(hour).pad_zeros(2)
	var mm := str(minute_display).pad_zeros(2)
	return hh + ":" + mm + "  Day " + str(day).pad_zeros(2) + ", " + month_name() + " " + str(year)

func get_formatted_time() -> String:
	var hh := str(hour).pad_zeros(2)
	var mm := str(minute_display).pad_zeros(2)
	return hh + ":" + mm

func get_formatted_date() -> String:
	return "Day " + str(day).pad_zeros(2) + ", " + month_name() + " " + str(year)
