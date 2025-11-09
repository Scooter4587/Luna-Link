# Changelog — LunaLink
Všetky významné zmeny v tomto projekte budú zapisované sem. Formát: **[verzia] — YYYY-MM-DD**.  
Sekcie: **Added / Changed / Fixed / Removed / Docs / DevOps**. Používame **Conventional Commits** a krátke PR.

## [0.0.2] — 2025-11-09

### Added
- **Build Mode:** 1× tile ghost, ťahanie obdĺžnika, potvrdenie uvoľnením.
- **ConstructionSite:** cyan overlay s %/ETA, dev čas ~10 s, po dobehu spawne budovu.
- **Building:** prenesie `size_cells`, spustí `Inside_Build`, nastaví pozíciu + z-index.
- **Inside_Build:** vyplní podlahu a perimeter walls (TileMapLayer, assert exportov).
- **BuildUI:** spodná lišta (Build + placeholders), signál `tool_requested`.
- **CameraController:** WASD pan, wheel/Q/E zoom, rýchlosť podľa zoomu.
- **World štruktúra:** `Terrain(Main_Ground 128px)`, `Buildings`, `Construction`, `BuildMode`, `Camera`, `UI`.
- **Autowire:** `BuildMode` si vie nájsť `*Ground*` `TileMapLayer`, ak nie je priradený.

### Notes (short)
- `BuildMode.gd` – výber + spawn `ConstructionSite`.
- `ConstructionSite.gd` – %/ETA → po dobehu `Building`.
- `Building.gd` – spustí interiér.
- `Inside_Build.gd` – Floors + Walls.
- `BuildUI.gd` – emituje `tool_requested`.
- `CameraController.gd` – pohyb a zoom kamery.

### Known / Next
- Dvere: nahradiť otvor v stene za `doors_layer` tile + jednoduchá interakcia.  
- Demolish tool: bezpečne odstrániť budovu a naviazané uzly.  
- UI progress bar v lište (okrem overlayu).  
- Časovanie: prepnúť z dev (~10s) na plocha→čas metriky (napr. 5s / 10 tiles).  
- Kolízie a vstupy: steny s `Collision`, neskôr pathfinding a miestnosti.

[0.0.1] – 2025-11-04
Added
- Discord Testing

Changed


Fixed


Notes
