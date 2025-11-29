# roadmap.md

# Luna-Link Roadmap – 0.0.51 → 0.1.0

## Milestone 0.1.0 – "Survive the First Hub"

Cieľ:  
Jeden hlavný hub na Mesiaci, v ktorom 2–4 členovia crew dokážu dlhodobo prežiť vďaka:
- energii (solar → battery → buildings),
- kyslíku (oxygen generator + pressurized hub),
- vode (ice → water),
- jedlu (import + hydroponics),
- základným potrebám crew (oxygen, hunger, sleep),
- jednoduchým fail stavom (smrť crew, stres/happiness eventy).

Po 0.1.0 chceme skôr pridávať **content** (viac budov, systémov), nie prepisovať core logiku.

---

## 0.0.51 – 0.0.59: Systems Skeleton (Energy, Water, Food)

### 0.0.51 – Resource model

- Zaviesť základné resourcy (dátovo, bez peknej UI):
  - `energy`
  - `water`
  - `oxygen_units` (abstraktné jednotky O₂)
  - `food`
  - `ice`
  - `spare_parts` (príprava na maintenance, nemusí sa ešte používať)
- Jedno miesto v kóde, ktoré spravuje globálne množstvá (ResourceManager / systém).

---

### 0.0.52 – Energy simulation (bez crew)

- `PowerProducer` behavior (napr. `solar_panel_basic`).
- `PowerStorage` behavior (`battery_small`):
  - kapacita
  - current charge
- `PowerConsumer` behavior (hook pre buildings).
- Tick logika:
  - `production - consumption → battery_charge`
  - basic stav: powered / unpowered.

---

### 0.0.53 – Water & oxygen pipeline (bez crew)

- Ice → Water:
  - ak je `ice_mine_basic` aktívna → generuje `ice`.
  - jednoduché spracovanie `ice → water` (môže byť centrálne alebo v konkrétnej budove).
- Water → Oxygen:
  - `oxygen_generator_small` spotrebuje `water` + `energy`.
  - produkuje `oxygen_units` pre pressurized zónu hubu.

---

### 0.0.54 – Food pipeline (hydroponics) – basic

- `hydroponics_basic`:
  - `ProductionHourly` (water → food).
  - `PowerConsumer`.
- Zatiaľ len čísla, bez detailov crew.

---

### 0.0.55 – Minimal resources UI

- Jednoduchý HUD prvok (text/ikonky) pre:
  - energy (battery charge)
  - water
  - oxygen_units (alebo stav „OK / low“)
  - food
- Skôr debug/tech UI než finálny dizajn.

---

### 0.0.56 – 0.0.59: Buildings & Behaviors for Survival Set

### 0.0.56 – BuildingsCfg: survival set definovaný

- Zapísať do `BuildingsCfg` budovy potrebné pre 0.1:
  - **Exteriér:**  
    - `landing_pad_basic`  
    - `solar_panel_basic`  
    - `battery_small`  
    - `oxygen_generator_small`  
    - `ice_mine_basic`
  - **Interiér:**  
    - `hub_core` (vrátane hlavnej miestnosti / bridge)  
    - `airlock_basic`  
    - `crew_quarters_small`  
    - `mess_hall_small`  
    - `warehouse_small`  
    - `hydroponics_basic`
- Pri každej: domain, footprint_type, anchor_type, zoznam behaviors.

---

### 0.0.57 – Behaviors wired

- Implementovať a pripojiť behaviors:
  - `PressurizedZone` (hub_core)
  - `LifeSupportModule` (oxygen generator napojený na hub)
  - `Storage` (warehouse_small)
  - `ProductionHourly` (ice→water, water→oxygen, water→food)
  - `PowerProducer` / `PowerConsumer` / `PowerStorage`
- Zabezpečiť, že všetko beží na GameClock tickoch.

---

### 0.0.58 – Airlock logic v1

- `airlock_basic`:
  - 2 dvere (inside / outside).
  - naraz môže byť otvorené len jedny.
- Jednoduchý stav:
  - CLOSED_INSIDE / OPEN_INSIDE / OPEN_OUTSIDE.
- Pripraviť hook pre crew pathfinding:
  - crew musí cez airlock, nie cez stenu.

---

### 0.0.59 – Debug & refactor pass

- Prejsť všetky survival budovy:
  - či správne míňajú/produkujú resourcy,
  - či sa energia správa očakávane.
- Upratať naming, komentáre, základné TODO poznámky.

---

## 0.0.6x – Crew & Needs v1

### 0.0.61 – Crew data & spawn

- Definovať štruktúru jednej crew jednotky:
  - `name`
  - `home_room`
  - `work_station`
  - `needs`: oxygen, hunger, sleep
  - `daily_schedule`
  - `status`: alive / dead / incapacitated
- Spawn:
  - z `landing_pad_basic` pri začiatku scenára.

---

## 0.0.62 – 0.0.7: Crew & Interior System Roadmap

Cieľ celého bloku:  
Dostať posádku od jednoduchého „pawn s idle“ k plnohodnotnému crew loopu:
- interiér s roomkami (Prison Architect štýl ghost overlay),
- airlock s dverami a pravidlami,
- home/work/mess assignment,
- needs (O2/Hunger/Sleep) napojené na GameClock,
- shift systém (6–14, 14–22, 22–06, jedna šichta na pawna),
- Crew Manager UI s prehľadom posádky.

---

### 0.0.62 – ROOM ako source of truth + debug skelet

**Cieľ:**  
Hra pochopí, čo je to ROOM ako koncept. Od toho sa budú odvíjať všetky typy rooms (quarters, mess hall, airlock, atď.).

**Úlohy:**

- [ ] **RoomCfg.gd – konfigurácia typov miestností**
  - Čistý config pre typy rooms, podobne ako ResourceCfg / BuildingsCfg.
  - Príklady polí:
    - `id` (napr. `"quarters_basic"`, `"mess_hall_basic"`, `"airlock_basic"`)
    - `display_name`
    - `category` – `"quarters"`, `"mess"`, `"airlock"`, `"corridor"`, …
    - `min_size_cells: Vector2i` – minimálny rozmer (napr. quarters 3×3, airlock 3×2)
    - `recommended_size_cells` (voliteľné)
    - `base_capacity` alebo `base_capacity_per_cell`
    - `default_color` pre ghost overlay
    - voliteľne: `allowed_objects`, `requires_foundation: bool`
  - **Poznámka:** RoomCfg má byť „jediný zdroj pravdy“ o tom, aké typy miestností existujú a aké majú minimálne rozmery / vlastnosti.

- [ ] **RoomArea2D.gd – runtime reprezentácia jednej roomky**
  - `extends Area2D`
  - Polia:
    - `room_instance_id: StringName` – unikátne ID v hre
    - `room_type_id: StringName` – odkaz na RoomCfg (napr. &"quarters_basic")
    - `bounds_cells: Rect2i` – rozsah v grid-e foundationu
    - `max_capacity: int` – spočítané z RoomCfg + veľkosti
    - `assigned_residents: Array[int]` – crew_id, čo tu bývajú
    - `assigned_workers: Array[int]` – crew_id, čo tu pracujú
    - neskôr: `current_occupants: Array[int]`
  - Vizualizácia:
    - jemný ghost overlay (Polygon2D/ColorRect) nad podlahou foundationu,
    - Label s názvom room (napr. „Crew Quarters“, „Mess Hall“, „Airlock“).
  - **Inšpirácia:** Prison Architect – viditeľné hranice miestnosti + jej názov.

- [ ] **RoomRegistry (autoload)**
  - Globálny register rooms, podobne ako Crew_Registry.
  - Drží `Dictionary{ room_instance_id: RoomArea2D }`.
  - Helpery:
    - `get_rooms_by_type(&"quarters")`
    - `get_room(room_instance_id)`
    - neskôr: `get_home_room_for_crew(crew_id)`, `get_work_room_for_crew(crew_id)`
  - Debug:
    - pri štarte vypísať zoznam vytvorených room (ak je zapnutý debug).

- [ ] **DebugFlags – zjednotený debug systém**
  - Rozšíriť existujúci `DebugFlags.gd` o nové flagy:
    - `DEBUG_ROOMS`
    - `DEBUG_AIRLOCK`
    - `DEBUG_NAV`
    - neskôr: `DEBUG_BUILD_INTERIOR`, `DEBUG_SCHEDULE`, …
  - Konvencia:
    - debug výpisy budú vždy v tvare:
      - `if DebugFlags.MASTER_DEBUG and DebugFlags.DEBUG_ROOMS: print("[Rooms] ...")`
  - **Poznámka:** MASTER_DEBUG = hlavný „kill-switch“. Ak je false, všetky debug logiky sú off. Každý skript má vlastný špecifický flag.

- [ ] **UI koncepcia: Interior → Rooms / Objects**
  - Hlavné kategórie v spodnom build bare:
    - napr. `Exterior`, `Interior`, `Infra`, …
  - Po kliknutí na **Interior**:
    - nad spodným barom sa objaví sub-riadok:
      - `Rooms` (Airlock, Mess Hall, Crew Quarters, …)
      - `Objects` (Dvere, Posteľ, Stôl, atď.)
  - Správanie:
    - Rooms → výber typu room → natiahnutie ghost oblasti (rect-drag).
    - Objects → výber objektu → klasické placement (fixed footprint).
  - V tejto verzii stačí základná štruktúra UI + placeholdery, nie plná logika.

---

### 0.0.63 – Interior build: rooms & ghost overlay vo Foundatione

**Cieľ:**  
Z BuildMode vieme klásť rooms (Quarters/Mess/Airlock) do foundationu ako ghosty. Každý takto vytvorený room generuje RoomArea2D a zapisuje sa do RoomRegistry.

**Úlohy:**

- [ ] **Rozšíriť BuildingsCfg o interior rooms & objects**
  - Pridať definície:
    - `room_quarters_basic`
    - `room_mess_hall_basic`
    - `room_airlock_basic`
  - Polia:
    - `domain: "interior"`
    - `category: "room"`
    - `footprint_type: "rect_drag"`
    - `min_size_cells` – z RoomCfg
    - `placement_rules: ["InsideFoundation"]`
    - `ui_group: "interior_rooms"`
  - Pridať základné interior objects:
    - `door_interior_basic`, `bed_basic`, `table_basic`, …
    - `domain: "interior"`
    - `category: "object"`
    - `footprint_type: "fixed"`
    - `placement_rules: ["InsideRoom"]`
    - `ui_group: "interior_objects"`

- [ ] **BuildMode: rect-drag pre rooms**
  - Po výbere room typu (napr. `room_quarters_basic`) z UI:
    - BuildMode zobrazí rect-drag ghost vo Foundation oblasti.
    - Po potvrdení:
      - spočíta bounds v cell-och,
      - vytvorí RoomArea2D instanciu,
      - nastaví:
        - `room_type_id`
        - `bounds_cells`
        - `max_capacity` podľa RoomCfg + veľkosti,
      - zaregistruje v RoomRegistry.

- [ ] **Ghost overlay & názvy**
  - RoomArea2D vizuálne:
    - polopriehľadná farba podľa RoomCfg (`default_color`),
    - Label s `display_name` v strede miestnosti.
  - **Poznámka:** cieľ je viditeľné rozlíšenie Quarters / Mess Hall / Airlock pri pohľade na hub.

- [ ] **Placement rules: InsideFoundation & InsideRoom**
  - `InsideFoundation`:
    - celý room rect musí ležať nad existujúcou foundation.
  - `InsideRoom`:
    - interior objects (posteľ, dvere, atď.) sa môžu klásť len dovnútra definovanej RoomArea2D (bounds).

---

### 0.0.64 – Múry, dvere, airlock skeleton + základ navigácie

**Cieľ:**  
Interiér dostane fyzickú podobu – múry, dvere, airlock logiku a základ pathfindingu pre crew (NavigationAgent2D + NavigationRegion2D).

**Úlohy:**

- [ ] **Interior walls & doors (kolízia)**
  - Interior wall:
    - napr. `wall_interior_basic` ako StaticBody2D + CollisionShape2D.
  - Interior door:
    - `door_interior_basic` s metódami:
      - `open()` → vypnúť collision + zmeniť sprite,
      - `close()` → zapnúť collision + sprite naspäť.
  - **Poznámka:** zatiaľ bez zložitej logiky, len základ „je priechod / nie je priechod“.

- [ ] **AirlockController – kostra**
  - Airlock ako špeciálny room (`room_airlock_basic`) alebo samostatný controller naviazaný na room.
  - Ref:
    - `outer_door: InteriorDoor` (hranica foundation ↔ vonkajšok),
    - `inner_door: InteriorDoor` (airlock ↔ vnútro).
  - Základné pravidlo:
    - nikdy neotvárať `outer_door` a `inner_door` naraz.
  - Neskôr:
    - fronty „čakaj vonku“ / „čakaj vnútri“,
    - tlak, oxygen, atď.

- [ ] **NavigationRegion2D & NavigationAgent2D (basic)**
  - Vo World scéne:
    - `NavigationRegion2D` pokrývajúci interiérovú podlahu.
  - V `CrewPawn`:
    - child `NavigationAgent2D` (napr. `NavAgent`).
    - `command_move_to(world_pos)`:
      - nastaví `nav_agent.target_position = world_pos`.
    - V `_physics_process`:
      - ak agent má path → pawn ide k `get_next_path_position()`,
      - ak `is_navigation_finished()` → clear move command.
  - **Poznámka:**  
    - 0.0.64 = crew už nechodí po „rovnej čiare“, ale po reálnej ceste, obchádza múry a dvere (keď sú otvorené).

---

### 0.0.65 – Home / Work / Mess assignment + sloty

**Cieľ:**  
Každý pawn má svoje **home room** (quarters) a **work room**. Mess hall má max kapacitu a je používaná rotačne.

**Úlohy:**

- [ ] **CrewPawn: home/work/mess prepojenie**
  - Pridať polia:
    - `home_room_id: StringName`
    - `work_room_id: StringName`
    - `current_room_id: StringName`
  - Helpery:
    - `set_home_room(room_id)`
    - `set_work_room(room_id)`

- [ ] **RoomArea2D: sloty a kapacita**
  - `slot_positions: Array[Vector2]` – lokálne pozície, kde pawn stojí/spí/sedí.
  - Metódy:
    - `get_free_slot()` → vráti (world pozícia, index).
    - `occupy_slot(crew_id, index)`
    - `free_slot(index)`
  - Kapacita:
    - `max_capacity` = počet slotov alebo vypočítaná hodnota.

- [ ] **Mess Hall rotácia**
  - Room typu `"mess"`:
    - `max_capacity`
    - `current_eaters: Array[int]`
    - `queue_waiting: Array[int]`
  - Logika:
    - ak je voľno → crew dostane slot,
    - ak plno → crew ide do fronty (zatiaľ stačí jednoduchý model).

- [ ] **API v CrewPawn: go_home / go_to_work / go_eat**
  - `go_home()`:
    - nájde room podľa `home_room_id`,
    - pýta si slot,
    - nastaví path cez NavigationAgent2D.
  - `go_to_work()`:
    - rovnako, ale cez `work_room_id`.
  - `go_eat()`:
    - nájde vhodný mess room (room_type `"mess"`),
    - rieši kapacitu / frontu.

---

### 0.0.66 – Needs + GameClock + vplyv rooms

**Cieľ:**  
Oxygen, hunger a sleep sa menia v čase podľa GameClock a aktuálnej room. Rooms majú reálny vplyv na needs.

**Úlohy:**

- [ ] **Napojenie CrewPawn na GameClock**
  - Pawn sa pripojí na `Clock.tick_hours(delta_hours)`:
    - `hunger` postupne rastie,
    - `sleep` postupne rastie (únava),
    - `oxygen` klesá, ak je pawn v „nesafe“ prostredí (dočasne definované).

- [ ] **Rooms ovplyvňujú needs**
  - Ak `current_room_type == "quarters"`:
    - `sleep` sa znižuje (odpočinok/spánok).
  - Ak `current_room_type == "mess"`:
    - `hunger` sa znižuje (jedáleň).
  - Oxygen:
    - dočasný model:
      - interior rooms = safe (pressurized),
      - exteriér = nebezpečný.
    - neskôr: prepojenie s oxygen systémom a life support.

- [ ] **Dead logika**
  - Ak `oxygen <= 0`:
    - `status = DEAD`
    - zastaviť pohyb a AI pre daného pawn.

---

### 0.0.67 – Shift systém (6–14, 14–22, 22–06) + „jedna šichta na pawna“

**Cieľ:**  
Zaviesť work shifty. Každý pawn má **jednu šichtu**, ostatný čas je určený pre jedlo, spánok a voľno. Na Mesiaci nie je deň/noc, iba „simulovaný režim“.

**Úlohy:**

- [ ] **Shift definícia (config)**
  - Enum / konstanta napr.:

    - `MORNING: 6–14`
    - `AFTERNOON: 14–22`
    - `NIGHT: 22–06`

  - Uložené v nejakom ShiftCfg alebo v CrewManageri.

- [ ] **Crew schedule per pawn**
  - Pawn má:
    - `assigned_shift: ShiftType` (jedna z troch – MORNING / AFTERNOON / NIGHT),
    - `work_room_id` už nastavený z 0.0.65.
  - Idea:
    - počas svojej šichty = WORKING,
    - mimo šichty = čas na Eat / Sleep / Free time.

- [ ] **CrewManager (logika plánovania podľa času)**
  - Node, ktorý počúva `Clock.hour_changed`.
  - Pre každý pawn:
    - ak je v čase dohodnutej šichty:
      - cieľ = work room → `go_to_work()`.
    - pred šichtou:
      - ak je hladný → `go_eat()`.
    - po šichte:
      - `go_eat()` + `go_home()` (sleep).
  - **Poznámka:**  
    - Toto je základ „kolónia beží sama“ – hráč len nastaví job + shift.

---

### 0.0.68 – Crew Manager UI (veľký prehľad posádky)

**Cieľ:**  
Urobiť veľké prehľadové UI pre crew – „Crew Manager“ panel.

**Úlohy:**

- [ ] **Zoznam posádky**
  - UI panel, ktorý zobrazuje:
    - meno / ID,
    - job / role,
    - priradený shift (6–14 / 14–22 / 22–06),
    - `home_room_id` / `work_room_id`,
    - basic needs (O2/Hunger/Sleep) ako ikonky alebo malé bargrafy,
    - mood (napr. OK / stressed).

- [ ] **Interakcia s UI**
  - Klik na riadok:
    - vyberie daného pawna v hre (prepojenie na CrewController).
  - Neskôr:
    - možnosť meniť shift / work room priamo z UI.

- [ ] **Prepojenie s CrewManagerom**
  - UI číta z centrálnej štruktúry (CrewManager / CrewRegistry),
  - zmena nastavení v UI ovplyvní reálnu logiku (shifty, assignments).

---

### 0.0.7 – Crew loop v1 – základný funkčný behavior

**Cieľ:**  
0.0.7 znamená, že:

- posádka má:
  - svoje home quarters,
  - work station,
  - mess hall (s kapacitou a rotáciou),
- interiér je:
  - definovaný cez Rooms (RoomCfg → RoomArea2D → RoomRegistry),
  - priechodný cez dvere a navmesh (NavigationAgent2D),
  - chránený airlockom (základné pravidlá dverí),
- Needs (O2/Hunger/Sleep) bežia podľa GameClock,
- Shifty (6–14, 14–22, 22–06) sú nastavené per pawn,  
  a CrewManager podľa toho posiela crew pracovať, jesť a spať,
- Crew Manager UI poskytuje prehľad o posádke  
  (základ pre budúce micromanagement a „sim“ časť hry).

Toto je **Crew Loop v1**, na ktorom sa bude dať ďalej stavať (stress, happiness, social needs, events, choroby, atď.).

---

## 0.0.7x – Survival logika & Fail stavy

### 0.0.71 – Oxygen failure

- Ak pressurized zóna nemá oxygen:
  - crew v zóne dostáva damage.
- Ak damage presiahne threshold:
  - crew zomiera.
- Game reakcia:
  - event / message, možno „game over“ pre prvý scenár.

---

### 0.0.72 – Hunger & sleep konsekvencie

- Hunger:
  - dlhodobý vysoký hunger → nižší výkon (pomalšie chodenie / nižšia produktivita).
- Sleep:
  - dlhodobý nedostatok spánku → pomalšie reakcie / penalizácia výkonu.
- V 0.0.7x nemusí byť plne realistické, skôr jednoduchý model.

---

### 0.0.73 – Stress / happiness skeleton

- Jednoduchý stat `happiness` / `stress`:
  - + keď všetko beží hladko,
  - – keď vypadne energia, zomrie crew, chýba jedlo/oxygen.
- Efekt:
  - zatiaľ len ako info + drobný malus, neskôr to rozšírime.

---

### 0.0.74 – Alerts & messages

- Systém upozornení:
  - „Low power“
  - „No oxygen in hub“
  - „Food critically low“
  - „Crew member died“
- Zobrazenie v HUD (ikonky + krátke texty).

---

## 0.0.8x – First scenario & balancing

### 0.0.81 – Scenár "First Hub Survival"

- Skript/konfigurácia scenára:
  - 2–4 crew priletí na landing pad.
  - Začiatočné zásoby: voda, jedlo, spare_parts.
- Cieľ:
  - prežiť X dní,
  - alebo dosiahnuť stabilný stav (napr. zásoba vody/food nad určitým prahom).

---

### 0.0.82 – Basic tutorial / hints

- Jednoduché hinty:
  - „Postav solárne panely a batériu“
  - „Postav oxygen generator, quarters, mess hall“
  - „Rozbehni hydroponiku“
- Môže byť len textová forma v rohu.

---

### 0.0.83 – Balancing & polish

- Upraviť čísla:
  - rýchlosť produkcie,
  - spotrebu vody/energie,
  - potreby crew.
- Opraviť kritické bugy, ktoré blokujú prežitie.

---

## 0.1.0 – First Playable Milestone

- Tag release 0.1.0:
  - stabilná verzia scenára „Survive the First Hub“.
- Dokumentácia:
  - krátky popis core loopu,
  - známe limity (čo bude až 0.2+: Helium-3, rovery, vlaky, MPT, science lab, workshop atď.).
