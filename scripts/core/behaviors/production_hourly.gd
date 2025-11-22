extends Node
## ProductionHourly – generický komponent pre budovy, ktoré v čase
## produkujú alebo konvertujú resourcy.
##
## Príklady použitia:
## - Ice mine:         input = ""      , output = ice
## - Ice processor:    input = ice     , output = water
## - Oxygen generator: input = water   , output = oxygen_units
## - Hydroponics:      input = water   , output = food
##
## Tento script:
## - NErieši energiu (energy) – to rieši PowerConsumer + EnergySystem.
## - NEviaže sa na konkrétnu budovu – len pracuje s ResourceManagerom.
## - Zatiaľ sa tickuje manuálne cez ProductionSystem.process_game_hours().

signal production_tick_done(actual_input: float, actual_output: float)

@export var input_resource_id: StringName = &""   # napr. &"ice" alebo &"water"
@export var input_per_hour: float = 0.0          # koľko input resource minie za hodinu

@export var output_resource_id: StringName = &"" # napr. &"water", &"oxygen_units"
@export var output_per_hour: float = 0.0         # koľko output resource vyrobí za hodinu

@export var enabled: bool = true                 # jednoduchý on/off prepínač
@export var require_full_input: bool = true      # ak nie je dosť input → radšej neurob nič
@export var require_power: bool = false          # ak true, produkcia prebehne len keď je budova napájaná (cez PowerConsumer)


func _ready() -> void:
	# prihlásime sa do skupiny, aby nás ProductionSystem vedel nájsť
	add_to_group("production_hourly")


func process_game_hours(hours: float) -> void:
	## Hlavný tick pre túto produkciu.
	## - hours: koľko herných hodín uplynulo (napr. 1.0, 0.5, 2.0)
	if not enabled:
		return
	if hours <= 0.0:
		return

	# bez output resource nemá zmysel niečo robiť
	if output_resource_id == &"":
		return

	# ak je vyžadovaná energia a budova nie je napájaná → nič nerobíme
	if require_power and not _has_power():
		production_tick_done.emit(0.0, 0.0)
		return

	var time_factor: float = hours
	var desired_output: float = output_per_hour * time_factor
	var actual_output: float = 0.0
	var actual_input: float = 0.0

	# 1) ŽIADNY INPUT RESOURCE – čistá produkcia "z ničoho" (ice z uloženého depozitu, abstrahujeme terén)
	if input_resource_id == &"" or input_per_hour <= 0.0:
		if desired_output > 0.0:
			ResourceManager.add_amount(output_resource_id, desired_output)
			actual_output = desired_output
		production_tick_done.emit(actual_input, actual_output)
		return

	# 2) Máme input aj output → klasická konverzia
	var desired_input: float = input_per_hour * time_factor
	if desired_input <= 0.0:
		production_tick_done.emit(0.0, 0.0)
		return

	if require_full_input:
		# buď máme celý input a spravíme plný output, alebo nič
		if not ResourceManager.can_consume(input_resource_id, desired_input):
			production_tick_done.emit(0.0, 0.0)
			return

		var consumed_ok: bool = ResourceManager.consume(input_resource_id, desired_input)
		if not consumed_ok:
			production_tick_done.emit(0.0, 0.0)
			return

		ResourceManager.add_amount(output_resource_id, desired_output)
		actual_input = desired_input
		actual_output = desired_output
		production_tick_done.emit(actual_input, actual_output)
	else:
		# partial režim: ak nemáme dosť input, spravíme len zodpovedajúcu časť outputu
		var available: float = ResourceManager.get_amount(input_resource_id)
		if available <= 0.0:
			production_tick_done.emit(0.0, 0.0)
			return

		var ratio: float = minf(1.0, available / desired_input)
		actual_input = desired_input * ratio

		if actual_input <= 0.0:
			production_tick_done.emit(0.0, 0.0)
			return

		# vieme, že available >= actual_input
		ResourceManager.consume(input_resource_id, actual_input)

		actual_output = desired_output * ratio
		if actual_output > 0.0:
			ResourceManager.add_amount(output_resource_id, actual_output)

		production_tick_done.emit(actual_input, actual_output)


func _has_power() -> bool:
	## Skontroluje, či je táto budova napájaná.
	## Logika:
	## - ak require_power = false → ignorujeme energiu, vrátime true.
	## - inak hľadáme v parent node dieťa v skupine "power_consumers"
	##   a čítame jeho property "is_powered".
	if not require_power:
		return true

	var parent: Node = get_parent()
	if parent == null:
		return false

	var children: Array[Node] = parent.get_children()
	for child in children:
		if child.is_in_group("power_consumers"):
			var powered_val: bool = bool(child.get("is_powered"))
			return powered_val

	return false
