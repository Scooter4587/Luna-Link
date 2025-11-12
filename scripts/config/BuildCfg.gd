extends Node
## Centrálne nastavenia pre build systém (foundation).
## Všetko ostatné skripty iba čítajú z BuildCfg – žiadne duplicitné konštanty.

## Rozmer jednej dlaždice v pixeloch (globálne pre build)
const CELL_PX := 128

## Minimálny rozmer základu (foundation)
const FOUNDATION_MIN_SIZE := Vector2i(2, 2)

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
