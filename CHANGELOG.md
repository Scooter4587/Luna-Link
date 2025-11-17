# Changelog — LunaLink
Všetky významné zmeny v tomto projekte budú zapisované sem. Formát: **[verzia] — YYYY-MM-DD**.  
Sekcie: **Added / Changed / Fixed / Removed / Docs / DevOps**. Používame **Conventional Commits** a krátke PR.

[0.0.4] – 2025-11-17 Základy prestavby Building systém
Added
BuildingsCfg.gd - Dátový skeleton pre konfigurácie budov - jednotný input na budovy
dev-notes.md - pridaný postup a ciele do verzie 0.0.5
ROADMAP.md - Updatovaný postup od 0.0.4 do 0.0.5


[0.0.31] – 2025-11-16
Added
GameClock (hodinový model času) s pauzou a rýchlosťami (pause/x1/x2/x4); signály hour_changed, minute_changed
ConstructionSite viazaný na clock: režimy GAME_HOURS_FIXED (foundation) a GAME_MINUTES_FIXED (extractor); overlay s percentami a ETA
BuildMode nástroj EXTERIOR_EXTRACTOR; snap na ResourceNode (modré hinty), zelený/červený ghost s reálnym footprintom (200×200 px)
BMExtractor: automatické napojenie na najbližší ResourceNode; produkcia 1× za hernú hodinu (building_materials)
Building: po dokončení foundation sa spawne interiér (Inside_Build) podľa size_cells

Changed
Foundation používa ConstructionSite na herných hodinách; čas sa počíta podľa plochy
Ghost pre foundation: presný 1× tile pod kurzorom + ťahaný obdĺžnik s prstencom hrúbky z BuildCfg
Finalizácia stavieb: pozícia sa určí pred add_child, budova má správnu polohu už v _ready()
ConstructionSite robustne hľadá cieľový ../Buildings (fallback), rešpektuje buildings_root_path
Extractor: cena BM + Equipment; node sa počas rozostavania označí ako obsadený
BMExtractor: debug logy vypnuté v základe

Fixed
Nesprávne centrovanie budov a extractorov (snap na stred ResourceNode)
Nepravidelný foundation ghost počas ťahania (zarovnanie na grid)
Nesprávne správanie pri pauze/rýchlostiach – stavby a produkcia teraz bežia výhradne cez GameClock
Chyby v odpojovaní GameClock signálov a drobné duplicity helperov


[0.0.3] – 2025-11-15
Added
TopBar UI Panel
Config skripty: GameClock.gd, GameState.gd, ResourceCfg.gd, TimeCfg.gd
UI skript: TopBarUI.gd
Prepojenie TopBarUI na GameState a GameClock – live zobrazenie resource hodnôt a aktuálneho času/dátumu
Ovládanie rýchlosti času priamo v TopBarUI (Pause / 1x / 2x / 4x)

Changed
Prestavba UI stromu: jeden UI CanvasLayer obsahuje BuildUI a TopBarUI ako Control nody
Úprava layoutu top baru – medzery medzi resource labelmi a bočné okraje pre lepšiu čitateľnosť

Fixed
Build mód znovu prijíma kliky po tom, čo root BuildUI a TopBarUI dostali Mouse Filter = Ignore
Odstránený duplikovaný vnútorný BuildUI node, ktorý komplikoval štruktúru a signály



[0.0.23] – 2025-11-13

Added
Scripts config BuildCfg gd Autoload centralne nastavenia CELL_PX FOUNDATION_WALL_THICKNESS atlas pre floor a wall farby ghostu
VSCode nastavenia file nesting pre Godot subory a skrytie pripon gd uid v exploreri a vyhladavani
ROADMAP.md - zatiaľ veľmi základný roadmap na verziu 0.1 - ide iba o orientáciu na fundamentálnej úrovni.

Changed
Struktura skriptov presun do scripts exterior interior config
BuildMode gd pouziva skutocny tile size z TileMapLayer pridal sa prstenec podla BuildCfg a jednotny vypocet rohov
Upratane komentare a exporty pre lepsiu citatelnost

Fixed
Foundation sa po dokonceni vytvori presne v rozmere natiahnuteho ghostu namiesto 1x1
Zarovnanie ghost a finalnej budovy je presne na pixel

Removed
Osobna cesta k Godotu z projektoveho priecinka vscode settings presunute do User Settings

Notes
chore build presun skriptov do exterior interior config a pridanie BuildCfg autoload
fix build presne rozmery foundation a ghost pouziva tile size z TileMapLayer
chore vscode nesting pre Godot a skrytie gd uid odstranenie osobnej cesty k Godotu z workspace



[0.0.22] – 2025-11-09

Added
- Build Mode: 1x tile ghost, tahanie obdlznika, potvrdenie uvolnenim.
- ConstructionSite: cyan overlay s percent a ETA, dev cas ~10 s, po dobehu spawne budovu.
- Building: prenesie size_cells, spusti Inside_Build, nastavi poziciu a z-index.
- Inside_Build: vyplni podlahu a perimeter walls (TileMapLayer, assert exportov).
- BuildUI: spodna lista (Build + placeholders), signal tool_requested.
- CameraController: WASD pan, wheel/Q/E zoom, rychlost podla zoomu.
- World struktura: Terrain(Main_Ground 128px), Buildings, Construction, BuildMode, Camera, UI.
- Autowire: BuildMode si vie najst Ground TileMapLayer, ak nie je priradeny.

Notes
- BuildMode.gd - vyber a spawn ConstructionSite.
- ConstructionSite.gd - percent a ETA -> po dobehu Building.
- Building.gd - spusti interier.
- Inside_Build.gd - Floors a Walls.
- BuildUI.gd - emituje tool_requested.
- CameraController.gd - pohyb a zoom kamery.

[0.0.21] – 2025-11-09

### Added
- **Build Mode:** 1× tile ghost, ťahanie obdĺžnika, potvrdenie uvoľnením.
- **ConstructionSite:** cyan overlay s %/ETA, dev čas ~10 s, po dobehu spawne budovu.
- **Building:** prenesie `size_cells`, spustí `Inside_Build`, nastaví pozíciu + z-index.
- **Inside_Build:** vyplní podlahu a perimeter walls (TileMapLayer, assert exportov).
- **BuildUI:** spodná lišta (Build + placeholders), signál `tool_requested`.
- **CameraController:** WASD pan, wheel/Q/E zoom, rýchlosť podľa zoomu.
- **World štruktúra:** `Terrain(Main_Ground 128px)`, `Buildings`, `Construction`, `BuildMode`, `Camera`, `UI`.
- **Autowire:** `BuildMode` si vie nájsť `*Ground*` `TileMapLayer`, ak nie je priradený.

### Notes
- `BuildMode.gd` – výber + spawn `ConstructionSite`.
- `ConstructionSite.gd` – %/ETA → po dobehu `Building`.
- `Building.gd` – spustí interiér.
- `Inside_Build.gd` – Floors + Walls.
- `BuildUI.gd` – emituje `tool_requested`.
- `CameraController.gd` – pohyb a zoom kamery.


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
