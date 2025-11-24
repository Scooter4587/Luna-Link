extends Node

func _ready() -> void:
	# Nájdeme prvý airlock v strome (node s AirlockBehavior)
	var airlocks := get_tree().get_nodes_in_group(&"airlocks")
	if airlocks.is_empty():
		print("[DebugUI] Žiadne airlocky v group 'airlocks'")
		return

	var airlock = airlocks[0]

	# Zavoláme testovací prechod z interiéru von
	if airlock.has_method("request_open_from_inside"):
		print("[DebugUI] Spúšťam test airlocku (inside -> outside)")
		airlock.request_open_from_inside()
	else:
		print("[DebugUI] Node v skupine 'airlocks' nemá metódu request_open_from_inside()")
