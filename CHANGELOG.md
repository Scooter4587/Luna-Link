# Changelog — LunaLink
Všetky významné zmeny v tomto projekte budú zapisované sem. Formát: **[verzia] — YYYY-MM-DD**.  
Sekcie: **Added / Changed / Fixed / Removed / Docs / DevOps**. Používame **Conventional Commits** a krátke PR.

[0.0.6] – 2025-11-25
Added
DebugFlags.gd – centrálna debug konfigurácia s MASTER_DEBUG a samostatnými prepínačmi:
DEBUG_STARTING_RESOURCES, DEBUG_AUTOTEST_AIRLOCK, DEBUG_BM_EXTRACTOR_LOGS,
DEBUG_ENERGY_SYSTEM, DEBUG_PRODUCTION_SYSTEM, DEBUG_CONSTRUCTION,
DEBUG_PLACEMENT, DEBUG_LIFE_SUPPORT, DEBUG_PRESSURIZED_ZONES.
Základné debug logy v EnergySystem a ProductionSystem – pri štarte sa vypíše napojenie na Clock.hour_changed a pri ticku sa loguje hodinový prepočet energie (net + aktuálny stav).

Changed
EnergySystem a ProductionSystem mierne upratané (typovanie premenných, odstránené konfliktné class_name), aby išli korektne ako autoload singletony s voliteľným debug logovaním cez DebugFlags.
BMExtractor loguje svoj cfg a úspešné nalinkovanie na ResourceNode (id/názov/path), s možnosťou vypnúť logy cez DEBUG_BM_EXTRACTOR_LOGS.

Fixed
Opravené GDScript chyby okolo DebugFlags (chýbajúce DEBUG_* konstanty, tieňovanie globálnych/autoload názvov).
BuildMode + GhostService + PlacementService vrátené do stabilnej verzie po experimentoch s debugom –
foundation drag, extractor ghost a build pipeline znovu fungujú rovnako ako v 0.0.58 (bez rozbitia ghostu).

Notes
Debug infraštruktúra je pripravená do budúcna – nie všetky DEBUG_* flagy sú aktuálne využité, ale slúžia ako „zapínateľné okruhy“ pre ďalšie survival/energy/airlock systémy.
Next Crew and crew needs

[0.0.58] – 2025-11-24
Added
Backend pre survival pipeline cez GameState a hourly behaviors.
Nové resources ice a oxygen_units v ResourceCfg vrátane zaradenia oxygen_units do sekcie crew needs v top bare.
LifeSupportModule behavior, ktorý pri každej hernej hodine míňa water a produkuje oxygen_units alebo plní oxygen buffer priradenej PressurizedZone.
PressurizedZone behavior s lokálnym oxygen bufferom pre hub zónu a statusom ok / low / critical / empty.
StorageBehavior ako generický lokálny sklad s kapacitami pre konkrétne resource.

Changed
ProductionSystem teraz pri každom game hour ticku spracuje okrem skupiny production_hourly aj všetky nody v skupine behavior_hourly cez metódu _on_behavior_hour_tick, takže nový survival backend beží na rovnakom GameClock ticku ako existujúca produkcia.

Notes
Nové survival behaviors zatiaľ nie sú pripojené na konkrétne budovy. Slúžia ako príprava pre hub_core, oxygen_generator_small, hydroponics_basic, ice_mine_basic a warehouse_small, ktoré na ne napojíme v ďalších verziách.


[0.0.57] – 2025-11-24
Added
AirlockBehavior – univerzálny behavior pre airlocky (crew aj vehicle). Obsahuje stavový automat so stavmi CLOSED_BOTH / OPEN_INSIDE / OPEN_OUTSIDE / CYCLING, API request_open_from_inside/request_open_from_outside, helper metódy is_passable_from_inside/is_passable_from_outside a signal airlock_state_changed pre budúci pathfinding a eventy.

Notes
Behavior zatiaľ nie je napojený na konkrétnu airlock budovu ani na crew. Slúži ako základná kostra, na ktorú v ďalších verziách naviažeme reálne dvere, spotrebu energie/O2 a logiku zón (interiér vs. exteriér).


[0.0.56] – 2025-11-24
Added
BuildingsCfg v2 so survival setom budov
landing_pad_basic, solar_panel_basic, battery_small, oxygen_generator_small, ice_mine_basic, hub_core, airlock_basic, crew_quarters_small, mess_hall_small, warehouse_small, hydroponics_basic.
Každá budova má definované domain, category, footprint_type, anchor_type, placeholder cost, build time a behaviours (PowerProducer, PowerConsumer, PowerStorage, ProductionHourly, CrewCapacity, Storage atď.).

Changed
GameState teraz pri štarte inicializuje všetky zdroje z ResourceCfg.initial a synchronizuje ich do ResourceManageru, takže štartovacie hodnoty sú centrálne definované v ResourceCfg.


[0.0.55] – 2025-11-24
Added
RightPanelUI – pravý UI panel s debug zobrazením globálnych survival zdrojov (energy, water, oxygen_units, food) napojený na ResourceManager.resource_changed.
DEBUG folder - bude slúžiť na debug skripty v budúcnosti
DebugUi.gd - Debug script pre UI

Removed
test_placement.gd - vymazaný už ako nepotrebný

Notes
0.0.54 - Presunuté pod 0.0.56 - poznámka v dev-notes.md
Panel zatiaľ zobrazuje iba globálne hodnoty. V budúcnosti bude doplnený o režim building inspector pre vybranú stavbu (názov budovy, upkeep, stav powered/unpowered).


[0.0.53] – 2025-11-22
Added
Backend pre produkčné pipeline
`ProductionHourly` behavior pre konverziu resource-ov v čase (napr. ice → water, water → oxygen, water → food).
`ProductionSystem` core manažér, ktorý tickuje všetky `ProductionHourly` komponenty cez herné hodiny.

Notes
Zatiaľ žiadne priame napojenie na budovy ani GameClock – systém je pripravený v pozadí a aktivuje sa v neskoršom kroku (0.0.57+).


[0.0.52] – 2025-11-22
Added
Základný backend pre energy systém
`EnergySystem` core manažér.
Behaviour komponenty `PowerProducer`, `PowerConsumer`, `PowerStorage` (pripravené na napojenie na budovy).
Podpora pre vyhľadávanie energy komponentov cez groups (`power_producers`, `power_consumers`, `power_storages`).

Changed
Zatiaľ žiadne viditeľné zmeny v hre – energy systém je pripravený v pozadí a na budovy sa napojí v neskoršom kroku (0.0.57).


[0.0.51] – 2025-11-22
Added
ResourceManager ako AutoLoad singleton pre globálne resourcy (energia, voda, jedlo, atď.).

Changed
GameState pri štarte synchronizuje svoje resource hodnoty do ResourceManageru.

Notes
Updatovaný Roadmap až po 0.1
Dev notes - detaily a vysvetlivky na postup.

[0.0.5] – 2025-11-19

Added
Nový dátový základ: `BuildCfg.gd`, `BuildingsCfg.gd`, `TimeCfg.gd` + autoload `GameClock.gd`, `ResourceCfg.gd`, `GameState.gd`, `ResourceNodeCfg.gd` a `ResourceNode.gd` pre jednotný čas, zdroje a povrchové nody.
Services vrstva: `PlacementService.gd`, `GhostService.gd`, `ConstructionService.gd` pre výpočet footprintu, validáciu (FreeArea, OnResourceNode, MinClearRadius) a spúšťanie ConstructionSite.
`BMExtractor.gd` napojený na `GameClock.hour_changed`, ktorý číta z `ResourceNode` a pridáva hodinovú produkciu do State.
`Building.gd` + `Inside_Build.gd` pre dátovo riadené generovanie interiérov (podlaha + múry) podľa BuildCfg.
CameraController.gd pre WASD pan a zoom kolieskom.

Changed
`BuildMode.gd` používa `BuildingsCfg` + services (PlacementService, GhostService, ConstructionService) pre foundation (rect-drag) aj extractor (snap na ResourceNode), vrátane kontroly obsadených tiles a clear radius.
`ConstructionSite.gd` je jednotný build pipeline pre foundation aj fixné budovy: výpočet času podľa time_mode, napojenie na GameClock (minúty/hodiny), kreslenie progresu a konzistentný spawn budov.
`TopBarUI.gd` počúva `State.resource_changed` a `Clock.minute_changed`, zobrazuje zdroje z `ResourceCfg` a pri building_materials aj hodinový delta indikátor.
`BuildUI.gd` má čistejšiu ButtonGroup a funguje iba ako emitér signálu `tool_requested` pre `BuildMode`.

Fixed
Foundation placement už neprekryje existujúce budovy a construction site-y a zvýrazní neplatné tiles v ghoste.
Extractor placement zlyhá, keď nie je nad resource nodom alebo poruší clear radius, a drží konzistentné zarovnanie na grid okolo snap centra.
Construction site sa po dokončení korektne odpájajú od `GameClock` a pri chýbajúcom root node `Buildings` logujú jednu jasnú chybu namiesto spamu.
`BMExtractor.gd` a `ResourceNode.gd` validujú konfiguráciu už v `_ready` a pri chýbajúcej definícii vypíšu varovanie namiesto tichého správania.

[0.0.48] – 2025-11-19
Added
BMExtractor ↔ ResourceNode prepojenie:** Každý BMExtractor sa po dostavaní automaticky nalinkuje na najbližší `ResourceNode` pod sebou a drží si referenciu (`linked_node`).
Hodinová produkcia v GameState:** Pridané funkcie `get_hourly_production()` a `get_hourly_delta_for(id)`, ktoré spočítajú hodinový výstup zo všetkých aktívnych extractorov podľa naviazaných resource nodov.
TopBarUI – zobrazenie +X/h:** Horná lišta pri Building Materials zobrazuje aktuálnu hodnotu a čistú hodinovú produkciu vo formáte napr. `BM: 2000 (+5/h)`.

Changed
BMExtractor:
- `_ready()` najprv skúsi nájsť `ResourceNode` hneď, a ak ešte nie je presne na finálnej pozícii, spraví oneskorený link cez `call_deferred("_late_link_attempt")`.
- Po úspešnom nalinkovaní sa pripojí na `GameClock.hour_changed` a pri každej hernej hodine pridá do `GameState` hodnoty z `linked_node.get_hourly_output()`.
ResourceNode: Zjednotený výstup produkcie cez `get_hourly_output()`, ktorý vracia slovník typu `{ resource_id: output_per_hour }` a slúži ako jediný zdroj pravdy pre produkciu nodu.

Fixed
Opravené viaceré GDScript warningy (tieňovanie premenných, integer division, nepoužité parametre) v `BuildMode.gd`, `GameState.gd`, `ResourceNode.gd` a `TopBarUI.gd`.
Stabilizované spojenie extractor ↔ resource node (overené cez Remote/Debugger – `linked_node` sa nastavuje korektne a produkcia beží len pri platnom linku).

Notes
Začína Veľký Clean-up na verziu 0.0.5


[0.0.47] – 2025-11-18
Added
BMExtractor: pri `_ready()` sa automaticky pokúsi nájsť najbližší `ResourceNode` pod sebou a uloží ho do premennej `linked_node`.
Ak sa node nepodarí nájsť hneď (kvôli spawn order z `ConstructionSite`), extractor použije deferred `_late_link_attempt()` – linkovanie sa zopakuje po jednom frame a až potom sa pripojí na `GameClock`.
Po úspešnom linku sa do konzoly vypisuje debug správa  `[BMExtractor] Linked to ResourceNode id=... name=... path=...`  pre jednoduchú kontrolu a ladenie (alebo cez Remote inspector).

Fixed
Odstránený edge-case, keď extractor po dokončení stavby nemusel mať korektne naviazaný `ResourceNode`, ale aj tak počúval `GameClock` (potenciál pre “mŕtve” alebo nesprávne extractory pri ďalšom refaktore).
Stabilnejšie napojenie na `GameClock` – extractor sa pripája až po úspešnom nájdení `linked_node`, takže produkcia je vždy viazaná na konkrétny resource node.


[0.0.46] – 2025-11-18
Added
Prekopaný EXTRACTOR ghost – číta `size_cells` z `BuildingsCfg` a `EXTRACTOR_GHOST_PX` z `BuildCfg`, kreslí veľký ghost v skutočnej veľkosti sprite-u, centrovaný na ResourceNode.
Foundation ghost teraz používa per-tile informácie z `GhostService` (`per_cell_state`) a každý tile má vlastný fill + tenký obrys gridu.
Obnovený múr/prstenec pre foundation – okrajový rámik sa kreslí hrubšou čiarou, aby bolo jasne vidieť hranicu budúcej základne.
-`BuildMode` pre extractor úplne prešlo na PlacementService + GhostService:
- footprint sa počíta z `BuildingsCfg` (`size_cells`, `pivot_cell`),
- validácia ide cez `FreeArea`, `OnResourceNode`, `MinClearRadius`,
- resource cost sa odpočítava až po úspešnej validácii.

Changed
ConstructionSite: `size_cells` a `get_occupied_cells()` teraz blokujú reálnu plochu stavby (aj pre extractor site), takže foundation ani iné stavby už neprelezú cez rozostavaný extractor.
Occupied area extractora: finálna budova aj jej ConstructionSite používajú rovnaký footprint, takže extractor naozaj blokuje oblasť zodpovedajúcu jeho sprite-u (nie len 2×2).
Opravené varovania: 
- integer division v `PlacementService._rule_min_clear_radius` (použité pomocné `center_x`, `center_y`),
- odstránené/shadow fixy pre lokálne premené (`has_node`, `ghost_px`, `center_world`, `tl_world`).

Notes
`GhostService.build_ghost_info()` je teraz jediný zdroj pravdy pre:
- `is_valid`,
- per-tile stav (`CellState.VALID / BLOCKED`),
- zoznam chýb pre debug / UI.
`BuildMode._draw()` má spoločnú pomocnú funkciu `_draw_ghost_tile()` pre kreslenie tile ghostov (foundation, budúce budovy).

[0.0.45] – 2025-11-18
Added
PlacementService – spoločná služba pre všetky budovy:
  - výpočet footprintu podľa `BuildingsCfg` (`fixed` a `rect_drag`),
  - generické validačné pravidlá podľa `placement_rules`:
    - `FreeArea` – žiadna dlaždica footprintu nesmie byť už obsadená,
    - `OnResourceNode` – extractor musí zasahovať aspoň jednu resource tile,
    - `MinClearRadius` – minimálny odstup od iných budov/ConstructionSite (konfigurovaný v `BuildingsCfg`).
- GhostService (skeleton) – funkcia `build_ghost_info()` prevádza výsledky validácie (`per_cell`) na stav pre ghost (OK/bloknuté) a loguje ich pre debug.

Changed
ConstructionSite.gd
 - Site sa pridáva do skupiny `"buildings"` a implementuje `get_occupied_cells()`, takže placement logika vidí aj rozostavané stavby.
Building.gd
  - Pridaná metóda `get_occupied_cells()`, vďaka ktorej hotové budovy vstupujú do validačného systému (FreeArea / MinClearRadius).
BuildMode.gd
 - Foundation (tool `EXTERIOR_COMPLEX`) pred vytvorením `ConstructionSite` používa `PlacementService.validate_placement()` – pri nevalidnom placemente sa stavba vôbec nespustí.
 - Extractor (tool `EXTERIOR_EXTRACTOR`) pred spustením stavby overuje:
   - voľné tiles v okolí resource nodu (`FreeArea`),
   - že footprint zasahuje resource node (`OnResourceNode`),
   - že je dodržaný minimálny odstup od iných budov (`MinClearRadius`).

Fixed
Foundation sa už nedá postaviť cez existujúci extractor ani iné budovy/ConstructionSite – blokuje to pravidlo `FreeArea`.
Extractor sa nedá postaviť na resource node, ak by jeho footprint kolidoval s foundation alebo bol príliš blízko iných stavieb (porušil by `min_clear_radius`).
`bm_extractor` má v `BuildingsCfg` nastavený `min_clear_radius = 6`, takže extractory sa nemôžu “nalepiť” na základňu.
Opravené integer division warningy v `_rule_min_clear_radius()` v `PlacementService.gd`.

Notes
Pokračuje Cleanup a generalizuje Build Systém


[0.0.44] – 2025-11-18
Added
GhostService: prepojenie výstupu z PlacementService.validate_placement() na ghost logiku (per-tile VALID/BLOCKED, textové chyby).
Debug: testovací skript na World pre overenie footprintu, validácie a ghost info.

Notes
Napojený testovací skript na World Main Node - Treba odpojiť v budúcnosti.

[0.0.43] – 2025-11-18
Added
Valide placement - get_footprint a validate_placement mechanika nahodená a otestovaná


[0.0.42] – 2025-11-18
Added
services folder - bude slúžiť čisto pre logiku a opakovateľné skripty. 
PlacementService: prvá verzia výpočtu footprintu pre `fixed` a `rect_drag` budovy, napojená na BuildingsCfg.

Notes
Otestovanie mechaniky cez debug - Použitý script test_placement.gd


[0.0.41] – 2025-11-17
Added
BMExtractor: prvé napojenie na BuildingsCfg.gd – extraktor pri spawne načíta svoju konfiguráciu z dátového configu (zatiaľ len na debug/log účely, bez zmeny gameplay).

Notes
Update 0.0.4 Neprešiel na discord:
Added
BuildingsCfg.gd - Dátový skeleton pre konfigurácie budov - jednotný input na budovy
dev-notes.md - pridaný postup a ciele do verzie 0.0.5
ROADMAP.md - Updatovaný postup od 0.0.4 do 0.0.5


[0.0.4] – 2025-11-17
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
