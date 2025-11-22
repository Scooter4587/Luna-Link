# res://scripts/core/behaviors/power_storage.gd
extends Node
## PowerStorage – batérie / akumulátory.
## Ukladá a uvoľňuje energiu, ktorú EnergySystem používa.

@export var capacity: float = 100.0
@export var current_charge: float = 0.0


func _ready() -> void:
	# prihlásime sa do skupiny, aby nás EnergySystem vedel nájsť
	add_to_group("power_storages")

	# Na istotu clamp pri štarte
	capacity = maxf(capacity, 0.0)
	current_charge = clampf(current_charge, 0.0, capacity)


func get_free_capacity() -> float:
	## Voľné miesto v batérii.
	return maxf(capacity - current_charge, 0.0)


func store(amount: float) -> float:
	## Pokúsi sa uložiť 'amount' energie.
	## Vráti zvyšok, ktorý sa NEVOŠIEL (teda neuložený prebytok).
	if amount <= 0.0:
		return 0.0

	var free: float = get_free_capacity()
	var stored: float = minf(amount, free)
	current_charge += stored
	return amount - stored


func draw(amount: float) -> float:
	## Pokúsi sa odobrať 'amount' energie.
	## Vráti, KOĽKO NAOZAJ ODOBRAL (nie vždy to musí byť celé amount).
	if amount <= 0.0:
		return 0.0

	var drawn: float = minf(amount, current_charge)
	current_charge -= drawn
	return drawn
