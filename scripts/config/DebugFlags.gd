# res://scripts/debug/DebugFlags.gd
class_name DebugFlags

## Globálny master switch – keď je false, všetky debug helpery sa vypnú.
const MASTER_DEBUG: bool = false

## Zapne/vypne štartovacie resourcy cez DebugUI.gd
const DEBUG_STARTING_RESOURCES: bool = false

## Zapne/vypne automatický test airlocku (DebugAirlock.gd)
const DEBUG_AUTOTEST_AIRLOCK: bool = false

## Zapne/vypne logovanie z BMExtractorov
const DEBUG_BM_EXTRACTOR_LOGS: bool = false


const DEBUG_ENERGY_SYSTEM: bool = false
const DEBUG_PRODUCTION_SYSTEM: bool = false
const DEBUG_CONSTRUCTION: bool = false
const DEBUG_PLACEMENT: bool = false
const DEBUG_LIFE_SUPPORT: bool = false
const DEBUG_PRESSURIZED_ZONES: bool = false