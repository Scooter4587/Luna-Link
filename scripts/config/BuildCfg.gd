extends Node
## Centrálne nastavenia pre build systém (foundation).
## Všetko ostatné skripty iba čítajú z BuildCfg – žiadne duplicitné konštanty.

## Rozmer jednej dlaždice v pixeloch (globálne pre build)
const CELL_PX := 128

# „malý“ grid pre interiér / rooms
const ROOM_CELL_PX: int = 16

# koľko room-buniek sa vojde do jedného foundation tile
@warning_ignore("integer_division")
const ROOM_CELLS_PER_FOUNDATION: int = CELL_PX / ROOM_CELL_PX

## Minimálny rozmer základu (foundation)
const FOUNDATION_MIN_SIZE := Vector2i(2, 2)
const EXTRACTOR_SIZE_CELLS: Vector2i = Vector2i(3, 3) # footprint 3×3 (ľahko zmeň podľa sprite)

const GHOST_HINT        := Color(0.2, 0.6, 1.0, 0.25) # modrá výplň pre “hint”
const GHOST_HINT_STROKE := Color(0.3, 0.8, 1.0, 1.0)  # modrá linka pre “hint”

## Hrúbka obvodového múru v dlaždiciach (ovplyvní ghost prstenec a prípadné okrajové kladenie)
var FOUNDATION_WALL_THICKNESS := 1

## Atlas súradnice pre podlahu a múr (Inside_Build)
var FOUNDATION_FLOOR_ATLAS := Vector2i(0, 0)
var FOUNDATION_WALL_ATLAS  := Vector2i(0, 0)

## Farby ghostu (len vizuál)
var GHOST_FILL  := Color(0.2, 0.8, 1.0, 0.28)
var GHOST_STROKE:= Color(1, 1, 1, 0.95)
var GHOST_TILE  := Color(1, 1, 1, 0.12)
var GHOST_TILE_STROKE := Color(1, 1, 1, 0.8)

# --- Extractor vizuál pre ghost ---
const EXTRACTOR_GHOST_PX: Vector2 = Vector2(200.0, 200.0) # zhodné s tvojím Sprite2D (200×200)

# Voliteľne farby hintov (modrá na snap)
const GHOST_HINT_FILL: Color = Color(0.25, 0.55, 1.0, 0.14)