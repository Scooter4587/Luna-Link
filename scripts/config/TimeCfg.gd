extends RefCounted
class_name TimeCfg
# TimeCfg: globálne nastavenia herného času a rýchlostí.
# - používa sa v GameClock a UI (napr. text formátu dátumu).

# Základné parametre herného času.
const HOURS_PER_DAY: int = 24
const DAYS_PER_MONTH: int = 30
const MONTHS_PER_YEAR: int = 12

# „Operatívny“ kalendár – mená mesiacov (v lore zemský rok, ale každý má 30 dní).
const MONTH_NAMES: Array[String] = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
]

# Východzí rok pre začiatok kampane (čisto dizajnový parameter).
const DEFAULT_START_YEAR: int = 2073

# Koľko reálnych sekúnd trvá 1 herná hodina pri rýchlosti 1x.
# (napr. 2.0 = každé 2 sekundy poskočí čas o hodinu)
const REAL_SECONDS_PER_GAME_HOUR: float = 2.0

# Odvodené – koľko sekúnd trvá 1 herná minúta pri rýchlosti 1x.
const REAL_SECONDS_PER_GAME_MINUTE: float = REAL_SECONDS_PER_GAME_HOUR / 60.0

# Prednastavené rýchlosti času (multiplikátory).
const TIME_SPEEDS: Dictionary = {
    "pause": 0.0,
    "x1": 1.0,
    "x2": 2.0,
    "x4": 4.0,
}

# Vráti názov mesiaca podľa indexu (0-based) – ak je mimo rozsah, vráti prázdny string.
static func get_month_name(month_index: int) -> String:
    if month_index < 0 or month_index >= MONTH_NAMES.size():
        return ""
    return MONTH_NAMES[month_index]

# Bezpečne znormalizuje index mesiaca do rozsahu 0..MONTHS_PER_YEAR-1.
static func normalize_month_index(month_index: int) -> int:
    var m: int = month_index % MONTHS_PER_YEAR
    if m < 0:
        m += MONTHS_PER_YEAR
    return m

# Pomocná funkcia: počet hodín v jednom hernom dni (len proxy, ak by sa menilo).
static func get_hours_per_day() -> int:
    return HOURS_PER_DAY

# Pomocná funkcia: počet dní v jednom mesiaci.
static func get_days_per_month() -> int:
    return DAYS_PER_MONTH

# Pomocná funkcia: vráti multiplikátor pre kľúč rýchlosti (napr. "x2").
static func get_time_speed(key: String) -> float:
    return float(TIME_SPEEDS.get(key, 1.0))
