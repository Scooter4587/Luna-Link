extends Node
## ProductionSystem – globálny manažér produkcie resource-ov v čase.
##
## Zatiaľ:
## - nájde všetky nody v skupine "production_hourly"
## - zavolá na nich process_game_hours(hours)
##
## Napojenie na GameClock:
## - neskôr (0.0.53/0.0.54) ho pripojíme na signál z GameClocku.
## - teraz je to len backend, ktorý vieme testovať manuálne.

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# tu nič netreba, ProductionSystem len čaká na volanie process_game_hours()

func _get_producers() -> Array[Node]:
	## Vráti všetky ProductionHourly komponenty v hre.
	return get_tree().get_nodes_in_group("production_hourly")


func process_game_hours(hours: float) -> void:
	if hours <= 0.0:
		return

	# 1) Existujúce: ProductionHourly komponenty
	var producers: Array = get_tree().get_nodes_in_group("production_hourly")
	for node in producers:
		if node.has_method("process_game_hours"):
			node.process_game_hours(hours)

	# 2) NOVÉ: hourly behaviory (LifeSupport, PressurizedZone, atď.)
	var behavior_nodes: Array = get_tree().get_nodes_in_group("behavior_hourly")
	for node in behavior_nodes:
		if node.has_method("_on_behavior_hour_tick"):
			node._on_behavior_hour_tick(hours)