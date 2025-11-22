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
	# Žiadne auto-ticky – budeme ho volať z GameClocku alebo testovacích skriptov.
	pass


func _get_producers() -> Array[Node]:
	## Vráti všetky ProductionHourly komponenty v hre.
	return get_tree().get_nodes_in_group("production_hourly")


func process_game_hours(hours: float = 1.0) -> void:
	## Hlavný tick pre všetky ProductionHourly nody.
	if hours <= 0.0:
		return

	var producers: Array[Node] = _get_producers()
	for node in producers:
		if node != null and node.has_method("process_game_hours"):
			node.process_game_hours(hours)
