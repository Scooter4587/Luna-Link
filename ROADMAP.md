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

### 0.0.62 – Pathfinding inside hub

- Nastaviť navigáciu v rámci jedného hubu:
  - prepojenia medzi room nodes a dverami.
- Crew vie prejsť:
  - quarters → work_station → mess_hall → quarters.
- Ignorujeme exteriérové rovery/vlaky – len interiér + airlock.

---

### 0.0.63 – Needs & Schedule

- Implementovať:
  - oxygen (viazaný na pressurized zónu + oxygen gen stav),
  - hunger (rastie, reset v mess hall),
  - sleep (rastie, reset v quarters).
- Daily schedule:
  - Work / Eat / Sleep bloky počas 24h cyklu.
- Crew podľa schedule mení cieľ:
  - Work → work_station,
  - Eat → mess_hall,
  - Sleep → quarters.

---

### 0.0.64 – Basic crew HUD

- Zobraziť:
  - minimálne ikony pre každého člena crew (stav needs),
  - jednoduchý stav nálady (OK / stressed).
- Zatiaľ bez detailných portrétov.

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
