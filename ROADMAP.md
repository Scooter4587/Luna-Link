# Roadmap 0.0.4 → 0.0.5 – Building System

## Cieľ 0.0.5

Na verzii **0.0.5** vieme na testovacej scéne otestovať všetky základné typy stavieb cez jednotný, dátovo riadený systém:

- **domain:** `exterior` / `interior`
- **footprint_type:** `fixed` / `rect_drag` / `path`
- **anchor_type:** `free` / `on_resource_node` / `on_foundation` / `inside_room`

ALFA typy stavieb:

- `foundation_basic` – exterior, rect_drag, free
- `bm_extractor` – exterior, fixed, on_resource_node
- `solar_panel` – exterior, fixed, free (resp. neskôr on_foundation)
- `power_cable` – exterior, path, free
- `room_basic` – interior, rect_drag, on_foundation (prototyp interiéru)

---

## 0.0.4 – Východzí stav

- Existujúci extraktor a build mód sú funkčné, ale:
  - logika je šitá na mieru konkrétnej stavbe,
  - neexistuje jednotný `BuildingsCfg`,
  - neexistujú zdieľané služby `PlacementService`, `GhostService`, `ConstructionService`.
- GameClock už existuje a riadi čas (pauza, rýchlosť), ale nie je ešte napojený na jednotný systém stavby.

---

## 0.0.41 – Dizajn & BuildingsCfg skeleton

**Cieľ:** mať jasno v dizajne a kostru `BuildingsCfg`, bez zásahu do funkčnej hry.

Úlohy:

- Spísať do dokumentácie (napr. `docs/dev-notes.md` alebo úvod ROADMAP):
  - osi: `domain`, `footprint_type`, `anchor_type`,
  - ALFA typy stavieb (foundation_basic, bm_extractor, solar_panel, power_cable, room_basic).
- Vytvoriť skript / resource `BuildingsCfg` (zatím skeleton):
  - zadefinovať základnú štruktúru dát (id, domain, footprint_type, anchor_type, size_cells, pivot_cell, placement_rules, behaviors, cost, build_time…),
  - zatiaľ môže ísť o pseudo-dáta / placeholder hodnoty.

Výsledok: existuje jeden jasný zdroj pravdy pre budovy (aj keď ešte nie je plne využitý).

---

## 0.0.42 – BuildingsCfg napojený na existujúci build (bez nových služieb)

**Cieľ:** hra stále funguje ako doteraz, ale základné parametre budov už idú z `BuildingsCfg`.

Úlohy:

- Doplniť do `BuildingsCfg` reálne definície pre:
  - `foundation_basic`
  - `bm_extractor`
  - `solar_panel`
  - `power_cable` (zatiaľ môže byť bez reálnej logiky, len ako definícia).
- V existujúcom kóde build módu:
  - začať čítať vybrané hodnoty z `BuildingsCfg` (cost, build_time, základný footprint) namiesto natvrdo zakódovaných čísel,
  - zachovať starý flow, aby sa nič nerozbilo.

Výsledok: `BuildingsCfg` je jediný zdroj pravdy pre základné parametre budov, systém je stále legacy, ale už má dátový základ.

---

## 0.0.43 – PlacementService (fixed + rect_drag)

**Cieľ:** jednotné umiestňovanie pre foundation + fixed budovy cez `PlacementService`.

Úlohy:

- Vytvoriť `PlacementService`:
  - vie pracovať s `footprint_type = fixed` a `rect_drag`,
  - z `BuildingsCfg` číta:
    - `footprint_type`
    - `size_cells`, `pivot_cell`
    - `anchor_type`
    - `placement_rules` (minimálne: `FreeArea`, `OnResourceNode`).
- Presunúť existujúci placement kód:
  - z extraktora a foundation do `PlacementService`,
  - UI/build mód volá už len `PlacementService` (napr. `get_preview_footprint`, `validate_placement`).
- `power_cable` zatiaľ nemusí byť plne funkčný – path logika bude riešená neskôr (0.0.5), ale typ je už pripravený v configu.

Výsledok: foundation, extractor a solar používajú spoločnú logiku overovania pozície, aj keď ghost a construction sú ešte staré.

---

## 0.0.44 – GhostService + jednotný build input

**Cieľ:** jeden ghost systém a jednotné ovládanie pre všetky exterior fixed/rect_drag stavby.

Úlohy:

- Vytvoriť `GhostService`:
  - dostane od `PlacementService` footprint + valid/invalid status,
  - vykreslí duchov (tiles / sprite) a zafarbí ich podľa validácie,
  - používa `footprint_type`, `size_cells`, `pivot_cell`,_
