extends Node
class_name GameClock
# GameClock: centrálne riadi herný čas (rok, mesiac, deň, hodina, minúta)
# a podporuje rôzne rýchlosti času (pause, 1x, 2x, 4x).
# Neskôr naň naviažeme produkciu, spotrebu, eventy, crew shifty.

signal minute_changed(year: int, month_index: int, day: int, hour: int, minute: int)
signal hour_changed(year: int, month_index: int, day: int, hour: int)
signal day_changed(year: int, month_index: int, day: int)
signal month_changed(year: int, month_index: int)
signal year_changed(year: int)

var year: int = TimeCfg.DEFAULT_START_YEAR
var month_index: int = 0    # 0 = January, 1 = February, ...
var day: int = 1            # 1..DAYS_PER_MONTH
var hour: int = 0           # 0..23
var minute: int = 0         # 0..59

# Aktuálny kľúč rýchlosti (pause, x1, x2, x4).
var _time_speed_key: String = "x1"
# Multiplikátor rýchlosti (0.0 = pauza, 1.0 = normál, 2.0 = 2x, ...).
var time_scale: float = 1.0

# Akumulátor reálneho času (v sekundách).
var _real_seconds_accum: float = 0.0


func _ready() -> void:
    # Clock beží stále, aj keď zatiaľ nič nepočúva signály.
    set_process(true)
    _apply_time_speed(_time_speed_key)
    print("[GameClock] ready @ ", get_formatted_datetime())


func _process(delta: float) -> void:
    # Keď je pauza, clock stojí.
    if time_scale <= 0.0:
        return

    var scaled_delta: float = delta * time_scale
    _real_seconds_accum += scaled_delta

    var sec_per_game_minute: float = TimeCfg.REAL_SECONDS_PER_GAME_MINUTE
    # Pre istotu while – keby bol veľký lag, môžeme preskočiť viac minút naraz.
    while _real_seconds_accum >= sec_per_game_minute:
        _real_seconds_accum -= sec_per_game_minute
        _advance_minute()


# -- Verejné API --------------------------------------------------------------

# Nastaví rýchlosť času podľa kľúča (napr. "pause", "x1", "x2", "x4").
func set_time_speed(key: String) -> void:
    _time_speed_key = key
    _apply_time_speed(key)


func get_time_speed_key() -> String:
    return _time_speed_key


func pause() -> void:
    set_time_speed("pause")


func resume_normal() -> void:
    set_time_speed("x1")


func get_formatted_time() -> String:
    # HH:MM formát (napr. "03:07").
    return "%02d:%02d" % [hour, minute]


func get_formatted_date() -> String:
    # "Day 05, March 2073"
    var month_name: String = TimeCfg.get_month_name(month_index)
    return "Day %02d, %s %d" % [day, month_name, year]


func get_formatted_datetime() -> String:
    # "03:07  Day 05, March 2073"
    return "%s  %s" % [get_formatted_time(), get_formatted_date()]


func reset_to_start() -> void:
    year = TimeCfg.DEFAULT_START_YEAR
    month_index = 0
    day = 1
    hour = 0
    minute = 0
    _real_seconds_accum = 0.0
    _apply_time_speed(_time_speed_key)


# -- Vnútorná logika ----------------------------------------------------------

func _apply_time_speed(key: String) -> void:
    # Získa multiplikátor z TimeCfg, napr. "x2" -> 2.0.
    time_scale = TimeCfg.get_time_speed(key)
    print("[GameClock] time speed set -> ", key, " (scale=", time_scale, ")")


func _advance_minute() -> void:
    minute += 1
    if minute >= 60:
        minute = 0
        _advance_hour()
    else:
        emit_signal("minute_changed", year, month_index, day, hour, minute)


func _advance_hour() -> void:
    hour += 1
    if hour >= TimeCfg.get_hours_per_day():
        hour = 0
        _advance_day()
    emit_signal("hour_changed", year, month_index, day, hour)


func _advance_day() -> void:
    day += 1
    if day > TimeCfg.get_days_per_month():
        day = 1
        _advance_month()
    emit_signal("day_changed", year, month_index, day)


func _advance_month() -> void:
    month_index += 1
    if month_index >= TimeCfg.MONTHS_PER_YEAR:
        month_index = 0
        _advance_year()
    emit_signal("month_changed", year, month_index)


func _advance_year() -> void:
    year += 1
    emit_signal("year_changed", year)
