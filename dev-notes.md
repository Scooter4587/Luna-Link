# dev.notes

# Luna-Link – Design Notes (0.1 Focus)

## 1. Vízia & inšpirácie

- Hra: realistickejší **mesačný kolonizačný manažment**.
- Téma:
  - budovanie lunárneho hubu,
  - prežitie posádky,
  - dlhodobý cieľ: He-3, energetická kríza na Zemi.
- Inšpirácie:
  - Deliver Us The Moon (lore, MPT & He-3),
  - Surviving Mars, Planetbase (kolónie, survival),
  - RimWorld (crew, joby, potreby),
  - rôzne base-building / management hry.

### Dlhodobý veľký plán (mimo 0.1)

- Helium-3 chain (raw → refined → reactor → MPT → Zem).
- Externé outposty, vlaky, rovery, power cables, Micro MPT.
- Pokročilá logistika (fyzické crates, hauleri).
- Science, research, workshop, vylepšenia budov (MK2).
- Events, havárie, politický tlak, psychológia posádky.

0.1 sa zameriava čisto na **prežitie prvého hubu**.

---

## 2. Core loop pre verziu 0.1

Pracovný názov: **"Survive the First Hub"**

Hráč:

1. Postaví základný hub:
   - hub_core (bridge / hlavná miestnosť),
   - airlock na prechod,
   - crew_quarters_small,
   - mess_hall_small,
   - warehouse_small.

2. Rozbehne energiu:
   - solar_panel_basic → battery_small.

3. Rozbehne životnú podporu:
   - oxygen_generator_small (spotrebuje vodu + energiu),
   - napojí ho na pressurized zónu hubu.

4. Zabezpečí vodu a jedlo:
   - ice_mine_basic → ice → water,
   - hydroponics_basic: water → food,
   - prípadne doplnkové zásoby zo Zeme cez landing_pad_basic.

5. Manažuje potreby crew:
   - oxygen (bez zóny / bez O₂ → smrť),
   - hunger (jesť v mess hall),
   - sleep (spať v quarters).

6. Reaguje na problémy:
   - nedostatok energie → vypnuté systémy,
   - nedostatok vody/food → hladovanie,
   - smrť crew → stres/happiness drop, event.

Cieľ:
- udržať posádku pri živote určitý čas,
- dosiahnuť stabilný stav základných zdrojov.

---

## 3. Budovy pre 0.1

### 3.1 Exteriér (0.1)

**`landing_pad_basic`**
- Úloha:
  - spawn crew + prvé zásoby,
  - neskôr event „supply drop“ zo Zeme.
- Behaviors:
  - scenárový spúšťač, nemusí mať generické behavior.

**`solar_panel_basic`**
- Úloha:
  - základný zdroj energie.
- Behaviors:
  - `PowerProducer`.
- Poznámka:
  - do budúcna maintenance (spotreba spare_parts, opotrebenie).

**`battery_small`**
- Úloha:
  - uloženie energie.
- Behaviors:
  - `PowerStorage` (kapacita, current_charge).
- UI:
  - bar/percento stavu batérie.

**`oxygen_generator_small`**
- Úloha:
  - vyrába oxygen pre hub.
- Spotreba:
  - `water`,
  - `energy`.
- Behaviors:
  - `LifeSupportModule` (napája `PressurizedZone`),
  - `PowerConsumer`.

**`ice_mine_basic`**
- Úloha:
  - ťažba ľadu (ice).
- Spotreba:
  - `energy`.
- Behaviors:
  - `ProductionHourly` (terrain → ice_resource),
  - `CrewStation` (potrebuje worker-a).

---

### 3.2 Interiér (0.1)

**`hub_core`**
- Úloha:
  - hlavný modul hubu,
  - definuje pressurized zónu,
  - obsahuje „hlavnú miestnosť“ (bridge / command room).
- Behaviors:
  - `PressurizedZone`,
  - môže mať `CrewStation` pre command role.

**`airlock_basic`**
- Úloha:
  - medzi miestnosť medzi exteriérom a interiérom.
- Logika:
  - 2 dvere: inside / outside,
  - naraz môže byť otvorené len jedny.
- Behaviors:
  - vlastný AirlockController,
  - hook pre crew pathfinding.

**`crew_quarters_small`**
- Úloha:
  - spánok pre 2–4 astronautov.
- Behaviors:
  - `CrewHome` (kapacita),
  - regeneruje `sleep` need.

**`mess_hall_small`**
- Úloha:
  - miesto na jedlo.
- Spotreba:
  - `food` resource.
- Behaviors:
  - `CrewCanteen` (regeneruje hunger, míňa food).

**`warehouse_small`**
- Úloha:
  - interiérový sklad.
- Behaviors:
  - `Storage` (kapacita pre: food, water, spare_parts, ice, atď.).
- UI:
  - zatiaľ číslo + pár crate spriteov.

**`hydroponics_basic`**
- Úloha:
  - produkcia jedla.
- Spotreba:
  - `water`,
  - `energy`.
- Behaviors:
  - `ProductionHourly` (water → food),
  - `PowerConsumer`.

---

## 4. Systémy pre 0.1

### 4.1 Energia

- Zdroje:
  - `solar_panel_basic` → `PowerProducer`.
- Storage:
  - `battery_small` → `PowerStorage`.
- Spotreba:
  - `PowerConsumer` na:
    - oxygen_generator,
    - ice_mine,
    - hydroponics,
    - interiérové systémy.
- Logika:
  - `production - consumption → battery_charge`.
- Fail:
  - battery_charge ≤ 0 → buildings s `PowerConsumer` sú vypnuté,
  - spúšťa následné problémy (life support, production).

---

### 4.2 Water & oxygen

- `ice_mine_basic` → generuje `ice`.
- Spracovanie:
  - ice → water (centrálne alebo v určitej budove).
- `oxygen_generator_small`:
  - spotrebuje `water` + `energy`,
  - produkuje `oxygen_units`.
- `PressurizedZone`:
  - hub_core definuje interiér,
  - oxygen generator musí byť aktívny, aby bola zóna „safe“.

---

### 4.3 Food

- `hydroponics_basic`:
  - water → food,
  - spotrebuje energiu.
- `landing_pad_basic`:
  - môže pridať food do skladu pri prílete zásob.
- `mess_hall_small`:
  - crew tu míňa food a znižuje hunger.

---

### 4.4 Čas & schedule

- GameClock:
  - 24h cyklus, delený na bloky (Work / Eat / Sleep / Idle).
- Tick:
  - každú hernú hodinu (alebo kratší interval) sa:
    - aktualizujú needs,
    - prebehne produkcia/spotreba resourcov,
    - kontrolujú zmeny stavov (powered/unpowered atď.).

---

## 5. Crew – návrh pre 0.1

### 5.1 Crew entity

- Atribúty:
  - `name`
  - `home_room` (Crew Quarters)
  - `work_station` (CrewStation v konkrétnej budove)
  - `needs`:
    - oxygen,
    - hunger,
    - sleep,
    - (pripravené: happiness / stress)
  - `daily_schedule` (Work/Eat/Sleep bloky)
  - `status`: alive / dead / incapacitated

- Spawn:
  - z `landing_pad_basic` na začiatku scenára.

---

### 5.2 Needs model

- **Oxygen**
  - závisí od:
    - či je crew v pressurized zóne,
    - či zóna má oxygen (funkčný oxygen generator).
  - Fail:
    - bez O₂ → damage / smrť.

- **Hunger**
  - pomaly rastie,
  - reset v `mess_hall_small` (pri jedle),
  - dlhodobý hlad → penalizácia (výkon, rýchlosť).

- **Sleep**
  - rastie počas bdenia,
  - reset v `crew_quarters_small`,
  - dlhodobý nedostatok spánku → penalizácia.

- **Happiness / stress (skeleton)**
  - jednoduchý stat:
    - + pri stabilnom chode,
    - – pri výpadkoch, smrti posádky.
  - Efekt v 0.1 minimálny (info + drobný malus).

---

### 5.3 AI & pathfinding (0.1 scope)

- Pohyb:
  - iba v rámci jedného hubu,
  - medzi:
    - quarters ↔ mess hall ↔ work_station ↔ airlock.
- Cez airlock:
  - používa definovaný prechod (nie cez steny).
- Logika:
  - žiadne RimWorld šialenstvo,
  - len: podľa schedule choď na správne miesto.

---

## 6. Veci po 0.1 (nesiahať teraz 🙂)

Tagujeme ako **[0.2+]**:

- Helium-3 systém:
  - Raw Helium Extractor,
  - Refinery outpost (separate base),
  - Helium reactor,
  - MPT Dish (ground + orbit).

- Power sieť:
  - Micro MPT Dish (lokálna bezdrôtová energia),
  - dlhé power cables,
  - komplexnejšie grid mechaniky.

- Logistika:
  - rovery,
  - vlaky,
  - fyzické crates pri každej budove,
  - haulers / logistickí roboti/crew joby.

- Systémy:
  - science lab & research tree,
  - workshop / equipment,
  - pokročilý maintenance (opotrebenie, opravy).

- Crew rozšírenia:
  - podrobnejší stress / happiness systém,  
  - zdravotný stav, zranenia,
  - eventy (nehody, psychické breakdowny).

Tieto nápady nechávame uložené, ale **0.1 rieši len survival prvého hubu**.


## hydroponics_basic – design (0.0.54)

- Typ: interior building (v hube).
- Úloha: základná produkcia jedla z vody.

Backend plán:
- ProductionHourly:
  - input_resource_id: &"water"
  - input_per_hour: 1.0   # 1 jednotka vody / hod
  - output_resource_id: &"food"
  - output_per_hour: 2.0  # 2 jednotky jedla / hod
  - require_power: true
  - require_full_input: true

- PowerConsumer:
  - consumption_per_hour: 3.0  # 3 energy / hod
  - critical: true (bez jedla dlhodobo = problém pre crew)

Poznámka:
- Zatiaľ žiadne napojenie na crew (spotreba jedla).
- Napojenie ProductionHourly + PowerConsumer na konkrétnu scénu
  (hydroponics_basic.tscn) príde v kroku ~0.0.57 spolu s ice_mine_basic
  a oxygen_generator_small.
