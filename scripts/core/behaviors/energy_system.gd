# res://scripts/core/energy_system.gd
extends Node
## EnergySystem – globálny manažér elektriny.
##
## Zatiaľ:
## - zbiera všetky PowerProducer / PowerConsumer / PowerStorage cez groups,
## - pri každom ticku (process_game_hours) rieši:
##   - či máme dosť energie na napájanie všetkých,
##   - ako sa mení charge v batériách,
##   - nastavuje is_powered na consumeroch.
##
## Napojenie na GameClock spravíme neskôr (0.0.53+).
## Teraz je to pripravený backend, ktorý môžeme volať z testovacích skriptov.

func _ready() -> void:
	# Žiadne auto-ticky – zatiaľ len príprava systému.
	pass


func _get_producers() -> Array[Node]:
	## Nájde všetky PowerProducer komponenty v scéne.
	return get_tree().get_nodes_in_group("power_producers")


func _get_consumers() -> Array[Node]:
	## Nájde všetky PowerConsumer komponenty v scéne.
	return get_tree().get_nodes_in_group("power_consumers")


func _get_storages() -> Array[Node]:
	## Nájde všetky PowerStorage komponenty v scéne.
	return get_tree().get_nodes_in_group("power_storages")


func process_game_hours(hours: float = 1.0) -> void:
	## Hlavný tick – zavolaj pri posune herného času o X hodín.
	## (napr. 1.0 hod, 0.5 hod, ...)
	if hours <= 0.0:
		return

	var producers: Array[Node] = _get_producers()
	var consumers: Array[Node] = _get_consumers()
	var storages: Array[Node] = _get_storages()

	if consumers.is_empty() and producers.is_empty():
		return  # nič na riešenie

	# 1) Spočítame celkovú produkciu a spotrebu (na hodinu)
	var total_production_per_hour: float = 0.0
	for p in producers:
		if p != null and p.has_method("get_production_per_hour"):
			total_production_per_hour += float(p.get_production_per_hour())

	var total_consumption_per_hour: float = 0.0
	for c in consumers:
		if c != null and c.has_method("get_consumption_per_hour"):
			total_consumption_per_hour += float(c.get_consumption_per_hour())

	var total_production: float = total_production_per_hour * hours
	var total_consumption: float = total_consumption_per_hour * hours

	# 2) Celkový charge vo všetkých batériách
	var total_storage_charge: float = 0.0
	for s in storages:
		if s != null and s.has_variable("current_charge"):
			total_storage_charge += float(s.current_charge)

	# 3) Predpoklad: chceme mať všetko powered, pokiaľ to ide
	var net_energy: float = total_production - total_consumption

	if net_energy >= 0.0:
		# Panely pokryjú všetko, batérie riešia len prebytok
		_set_all_consumers_powered(consumers, true)

		if net_energy > 0.0 and not storages.is_empty():
			_charge_storages(storages, net_energy)
		return

	# 4) Produkcia nestačí – skúšame dočerpať z batérií
	var energy_deficit: float = -net_energy  # koľko chýba, aby sme udržali full power
	if total_storage_charge >= energy_deficit:
		# Batérie vedia dotiahnuť deficit, všetko ostáva powered
		_set_all_consumers_powered(consumers, true)
		_discharge_storages(storages, energy_deficit)
		return

	# 5) Ani panely, ani batérie nestačia → blackout
	_set_all_consumers_powered(consumers, false)
	# Minie sa všetko v batériách
	_discharge_storages(storages, total_storage_charge)


func _set_all_consumers_powered(consumers: Array[Node], powered: bool) -> void:
	for c in consumers:
		if c == null:
			continue

		if c.has_method("set_powered"):
			c.set_powered(powered)
		elif c.has_variable("is_powered"):
			c.is_powered = powered


func _charge_storages(storages: Array[Node], amount: float) -> void:
	## Rozdelí 'amount' energie medzi batérie podľa voľnej kapacity.
	var remaining: float = amount
	for s in storages:
		if remaining <= 0.0:
			break
		if s != null and s.has_method("store"):
			remaining = float(s.store(remaining))
	# remaining > 0 znamená, že batérie sú plné – prebytok zatiaľ ignorujeme


func _discharge_storages(storages: Array[Node], amount: float) -> void:
	## Odoberie 'amount' energie z batérií, pokiaľ je dostupná.
	var remaining: float = amount
	for s in storages:
		if remaining <= 0.0:
			break
		if s != null and s.has_method("draw"):
			var drawn: float = float(s.draw(remaining))
			remaining -= drawn
	# Ak remaining > 0 → batérie sú prázdne, riešime vyššie v process_game_hours()
