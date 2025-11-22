extends Node

## -------------------------------------------------------
## ResourceManager
##
## Úloha:
## - Centrálne miesto pre všetky globálne resourcy hry
##   (energia, voda, jedlo, atď.).
## - Poskytuje jednoduché API na:
##     - získanie hodnoty resource,
##     - nastavenie,
##     - pridanie/odobranie,
##     - bezpečnú spotrebu (consume s kontrolou).
## - Neskôr sa naň napoja:
##     - budovy (produkcia/spotreba),
##     - UI (HUD),
##     - scenáre/misné ciele.
## -------------------------------------------------------


## Signál: emitne sa vždy, keď sa zmení hodnota resource.
signal resource_changed(resource_id: StringName, new_amount: float)

## Signál: emitne sa pri neúspešnom consume() – nemáme dosť resource.
signal resource_not_enough(resource_id: StringName, required: float, current: float)


## Konštanty resource ID, aby sme nepísali holé stringy ("magic strings").
## Používame StringName (&"text") kvôli výkonu a menším alokáciám.
const RESOURCE_ENERGY: StringName       = &"energy"
const RESOURCE_WATER: StringName        = &"water"
const RESOURCE_OXYGEN: StringName       = &"oxygen_units"
const RESOURCE_FOOD: StringName         = &"food"
const RESOURCE_ICE: StringName          = &"ice"
const RESOURCE_SPARE_PARTS: StringName  = &"spare_parts"


## Interné úložisko hodnôt resource.
## Kľúč:  resource_id (StringName)
## Hodnota: množstvo (float)
var _resources: Dictionary[StringName, float] = {
	RESOURCE_ENERGY: 0.0,
	RESOURCE_WATER: 0.0,
	RESOURCE_OXYGEN: 0.0,
	RESOURCE_FOOD: 0.0,
	RESOURCE_ICE: 0.0,
	RESOURCE_SPARE_PARTS: 0.0,
}


func _ready() -> void:
	# Tento node žije ako AutoLoad singleton.
	# Tu neskôr môžeme načítať začiatočné hodnoty zo scenára
	# (napr. prvé zásoby po pristátí).
	pass


## -------------------------------------------------------
## ZÁKLADNÉ API
## -------------------------------------------------------

## Vráti aktuálne množstvo daného resource.
## Ak resource v _resources neexistuje, vráti 0.0 (žiadny crash).
func get_amount(resource_id: StringName) -> float:
	if _resources.has(resource_id):
		return _resources[resource_id]
	return 0.0


## Nastaví konkrétne množstvo resource (prepíše hodnotu).
## Emitne resource_changed, ak sa hodnota reálne zmenila.
func set_amount(resource_id: StringName, amount: float) -> void:
	var previous: float = get_amount(resource_id)
	_resources[resource_id] = amount

	if not is_equal_approx(previous, amount):
		emit_signal("resource_changed", resource_id, amount)


## Pridá delta k danému resource (môže byť aj záporné číslo).
## Vráti nové množstvo po zmene.
func add_amount(resource_id: StringName, delta: float) -> float:
	var new_amount: float = get_amount(resource_id) + delta
	set_amount(resource_id, new_amount)
	return new_amount


## Vráti true, ak máme aspoň "amount" daného resource.
func can_consume(resource_id: StringName, amount: float) -> bool:
	if amount <= 0.0:
		# Spotrebovať 0 alebo menej je vždy OK.
		return true

	return get_amount(resource_id) >= amount


## Pokúsi sa minúť "amount" z daného resource.
## - Ak máme dosť → zníži stav a vráti true.
## - Ak nemáme → nechá stav bez zmeny, emitne resource_not_enough a vráti false.
func consume(resource_id: StringName, amount: float) -> bool:
	if amount <= 0.0:
		# Nič reálne nemíňame.
		return true

	var current: float = get_amount(resource_id)

	if current < amount:
		emit_signal("resource_not_enough", resource_id, amount, current)
		return false

	set_amount(resource_id, current - amount)
	return true


## Vráti kópiu všetkých resource hodnôt.
## - Ideálne len na debug alebo UI, aby si neprepisoval _resources priamo.
func get_all() -> Dictionary[StringName, float]:
	return _resources.duplicate(true)
