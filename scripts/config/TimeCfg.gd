# res://scripts/config/TimeCfg.gd
extends RefCounted
class_name TimeCfg

# --- Začiatok hry ---
const START_YEAR: int = 2073
const START_MONTH_INDEX: int = 0   # 0 = January
const START_DAY: int = 1
const START_HOUR: int = 0

# --- Kalendár a škála času ---
const HOURS_PER_DAY: int = 24
const DAYS_PER_MONTH: int = 30     # flat 30 pre jednoduchosť (UI/počty stabilné)

# Koľko reálnych sekúnd trvá 1 herná HODINA pri rýchlosti x1.
const REAL_SECONDS_PER_GAME_HOUR: float = 2.0

# Kľúče rýchlosti → násobky
const SPEEDS := {
	"pause": 0.0,
	"x1": 1.0,
	"x2": 2.0,
	"x4": 4.0,
}

# Mená mesiacov (anglické). Ak chceš SK: ["Január","Február",...]
const MONTH_NAMES: Array[String] = [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
]
