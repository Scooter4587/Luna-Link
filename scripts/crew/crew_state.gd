# scripts/crew/crew_state.gd
class_name CrewState
extends RefCounted
# Čisto logická trieda, žiadny Node.

## Stav posádky (či je živý a schopný fungovať)
enum Status {
	ALIVE,
	DEAD,
	INCAPACITATED,
}

## Ciele / režimy správania (práca, jedlo, spánok...)
enum Goal {
	IDLE,
	WORK,
	EAT,
	SLEEP,
}

## Meno postavy (label, debug, neskôr aj pre UI)
var name: StringName = &"Crew Member"

## Id budovy, kde postava býva (napr. 'room_quarters_basic')
var home_room_id: StringName = &""

## Id budovy, kde pracuje (napr. 'bm_extractor_basic')
var work_station_id: StringName = &""

## Needs v rozsahu 0.0 – 1.0 (0 = ok, 1 = kritický stav)
## Zatiaľ jednoduchý Dictionary, nech sa s tým dá flexibilne pracovať.
var needs := {
	"oxygen": 1.0,  # 1.0 = plné zásoby, budú klesať mimo bezpečnej zóny
	"hunger": 0.0,  # 0.0 = nasýtený, 1.0 = extrémny hlad
	"sleep": 0.0,   # 0.0 = oddýchnutý, 1.0 = extrémna únava
}

## Denný harmonogram – pole blokov:
## { "from_min": int, "to_min": int, "goal": Goal }
## kde from/to sú minúty od 00:00 (napr. 6*60 = 6:00)
var daily_schedule: Array[Dictionary] = []

## Aktuálny stav tela/mozgu (alive/dead/incapacitated)
var status: Status = Status.ALIVE

## Aktuálny cieľ – čo by mal práve robiť (WORK/EAT/SLEEP/IDLE)
var current_goal: Goal = Goal.IDLE


func _init(_name: StringName = &"Crew Member") -> void:
	# Jednoduchý konštruktor – default meno sa dá zmeniť pri spawn-e.
	name = _name
	daily_schedule = make_default_schedule()


## Vytvorí jednoduchý default schedule na testovanie.
static func make_default_schedule() -> Array[Dictionary]:
	# Toto je len placeholder:
	# 06:00–14:00 WORK, 14:00–22:00 FREE/EAT, 22:00–06:00 SLEEP
	return [
		{
			"from_min": 6 * 60,
			"to_min": 14 * 60,
			"goal": Goal.WORK,
		},
		{
			"from_min": 14 * 60,
			"to_min": 22 * 60,
			"goal": Goal.EAT,
		},
		{
			"from_min": 22 * 60,
			"to_min": (24 + 6) * 60, # 30:00 = 06:00 ďalší deň
			"goal": Goal.SLEEP,
		},
	]
