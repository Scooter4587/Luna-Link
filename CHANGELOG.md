# Changelog — LunaLink
Všetky významné zmeny v tomto projekte budú zapisované sem. Formát: **[verzia] — YYYY-MM-DD**.  
Sekcie: **Added / Changed / Fixed / Removed / Docs / DevOps**. Používame **Conventional Commits** a krátke PR.

[0.0.2] – 2025-11-09
Added
- **Build Mode** (rect výber na gride): ghost 1× tile, ťahanie obdĺžnika, potvrdenie uvoľnením myši.
- **ConstructionSite**: výrazný cyan overlay s % a ETA, testovací čas stavby ~10s, po dokončení spawne budovu.
- **Building**: po spawne vytvorí interiér (napojí `Inside_Build`, posunie `size_cells`, z-index a presnú pozíciu).
- **Inside_Build**: generuje podlahu a obvodové múry cez `TileMapLayer` (exporty `Floors` / `Walls`), assert na chýbajúce vrstvy.
- **BuildUI** (spodná lišta): tlačidlá (Build + placeholders), `tool_requested(tool_id)` signál, integrácia s Build Mode.
- **CameraController**: WASD pan, zoom wheel, rýchlosť závislá od zoomu.
- **Scéna World – čistá štruktúra**:  
  `World/{Terrain(Main_Ground: TileMapLayer 128px), Buildings, Construction, BuildMode, Camera, UI}`.
- **Autowire** `terrain_grid` (ak nie je priradený, BuildMode si skúsi nájsť `*Ground*` TileMapLayer).

### Notes (čo je čo)
- **`BuildMode.gd`** — logika stavebného režimu (UI nástroje, snímanie myši, výber obdĺžnika, ghost kreslenie, vytvorenie `ConstructionSite`).  
  - Dôležité: exporty musia byť nastavené **pred** `add_child()` (platí pre Site aj Building).  
  - Potrebuje `terrain_grid: TileMapLayer` (map<->world prepočet: `local_to_map`, `map_to_local`).  
  - Test override: pri spawne Site zapíname `dev_mode=true`, `dev_total_time=10.0`.

- **`ConstructionSite.gd`** — dočasný „plán“ stavby.  
  - Kreslí overlay (cyan) + % a ETA; beží odpočítavanie; po dobehu vytvorí `Building`.  
  - Exporty: `terrain_grid`, `top_left_cell`, `size_cells`, `cell_px`, `building_scene`, `inside_build_scene`, `buildings_root_path`.  
  - Časovanie: produkčne `sec_per_tile/min/max`, v dev režime fix ~10s.  
  - Pozor: vlastnosti nastaviť **pred** vložením do stromu (inak `_ready()` štartuje s defaultmi).

- **`Building.gd`** — runtime budova.  
  - Prijme `size_cells` a `interior_scene (Inside_Build.tscn)`, potom inštancuje interiér.  
  - Ak `Inside_Build` má `setup(size_cells)`, zavolá ju; inak fallback vyplnenie (podlaha + perimeter walls).  
  - Z-index 200; pozícia = ľavý-horný roh výberu (počítané z TileMapLayer).

- **`Inside_Build.gd`** — generátor interiéru.  
  - Exporty: `floors_layer`, `walls_layer`, voliteľne `doors_layer`, `floor_atlas`, `wall_atlas`.  
  - `setup(size_cells)` vyplní podlahu a obvodové múry; `assert` upozorní, ak vrstvy nie sú priradené.  
  - TileSet: stačí 1 tile (atlas (0,0)), pre steny odporúčaná zapnutá `Collision`.

- **`BuildUI.gd`** — spodná lišta nástrojov.  
  - Tlačidlá: `BtnBuild` (+ `Rooms/Utilities/Demolish` placeholdery).  
  - `ButtonGroup` + toggle režimy; emituje `tool_requested(int)`.

- **`CameraController.gd`** — kamera.  
  - WASD pan (`cam_left/right/up/down` v Input Map), zoom na koliesko, rýchlosť škáluje podľa `zoom.x`.

- **Scény a prepojenia**  
  - `World.tscn`: musí existovať **`Buildings`** (Node2D) a **`Construction`** (Node2D).  
  - `Terrain/Main_Ground` = `TileMapLayer` s **Cell Size 128×128** (zodpovedá `cell_px=128`).  
  - `BuildMode` exporty:  
    - `terrain_grid` → `Terrain/Main_Ground` (použi *Editable Children* na inštancii Terrain),  
    - `construction_site_scene` → `scenes/ConstructionSite.tscn`,  
    - `building_scene` → `scenes/Building.tscn`,  
    - `inside_build_scene` → `scenes/Inside_Build.tscn`,  
    - `construction_root` → `../Construction`, `buildings_root` → `../Buildings`.  
  - `Inside_Build.tscn`: má `Floors`/`Walls` vrstvy priradené v Inspectore.

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


