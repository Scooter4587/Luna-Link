extends Node

## DebugAirlock:
## - nájde prvý node v skupine "airlocks"
## - ak má metódu request_open_from_inside(), spustí test prechodu.
## Aktivuje sa iba keď:
##   DebugFlags.MASTER_DEBUG a DebugFlags.DEBUG_AUTOTEST_AIRLOCK == true.

func _is_debug_enabled() -> bool:
	return DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_AUTOTEST_AIRLOCK


func _ready() -> void:
	if not _is_debug_enabled():
		# Autotest airlocku vypnutý → node zbytočný.
		queue_free()
		return

	var airlocks := get_tree().get_nodes_in_group(&"airlocks")
	if airlocks.is_empty():
		print("[DebugAirlock] Žiadne airlocky v group 'airlocks'")
		return

	var airlock := airlocks[0]

	if airlock.has_method("request_open_from_inside"):
		print("[DebugAirlock] Spúšťam test airlocku (inside -> outside)")
		airlock.request_open_from_inside()
	else:
		print("[DebugAirlock] Node v skupine 'airlocks' nemá metódu request_open_from_inside()")
