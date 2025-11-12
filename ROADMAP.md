# Luna Link – Roadmap to Version 0.1.0
Version 0.0.23 → 0.1.0

Základný cieľ: vytvoriť prvý funkčný herný cyklus
postavím → spotrebujem zdroje → ťažím → sledujem HUD → môžem stavať ďalej

---

## Milník M1 – 0.0.24 Foundations polish
Cieľ: stabilné základy stavby a čistý projekt
- Upratať scripts do priečinkov exterior, interior, config
- BuildCfg ako jediné miesto pre hodnoty (CELL_PX, FOUNDATION_WALL_THICKNESS, farby)
- Foundation sa presne zhoduje s ghostom po natiahnutí

---

## Milník M2 – 0.0.25 Zdroje: dátový model a stav hry
Cieľ: mať jednoduché účtovníctvo zdrojov
- Vytvoriť autoload scripts/config/ResourceCfg.gd s definíciou zdrojov (energia, betón)
- Vytvoriť autoload scripts/GameState.gd s runtime počítadlami a signálom resource_changed
- Výstup: funkcie add_resource, spend_resource, can_spend

---

## Milník M3 – 0.0.26 HUD pre zdroje
Cieľ: mať zobrazenie stavu energie a betónu
- Jednoduchý HUD panel v UI
- Aktualizácia pri zmene zdrojov pomocou signálu resource_changed
- Výstup: vždy viditeľný počet zdrojov

---

## Milník M4 – 0.0.27 Stavba s nákladom (cost)
Cieľ: foundation sa postaví len ak má hráč dostatok materiálu
- BuildMode kontroluje cost podľa ResourceCfg
- Ak zdroje nestačia, zobraziť hlášku a nestavať
- Po potvrdení stavby odpočítať betón zo zásob
- Výstup: stavby spotrebúvajú materiál

---

## Milník M5 – 0.0.28 Resource nodes a ťažba
Cieľ: zaviesť jednoduchú ťažbu betónu
- Vytvoriť resource node tiles (napr. regolit)
- MiningRig budova ťaží betón z node pod sebou každé X sekúnd
- Výstup: pri mining rigu rastie počet betónu, ak stojí na node

---

## Milník M6 – 0.0.29 Energia
Cieľ: pridať základný energetický systém
- SolarPanel vyrába energiu
- Budovy majú power_draw a spotrebúvajú energiu
- Ak je nedostatok energie, spotrebné budovy sa pozastavia
- Výstup: bez soláru ťažba stojí, so solárom beží

---

## Milník M7 – 0.0.30 UX a save systém
Cieľ: zlepšiť použiteľnosť a základné uloženie
- Pridať krátke textové hlášky (toast) pri nedostatku zdrojov
- Možnosť resetu hry
- Stub na save a load pomocou JSON
- Výstup: uloženie a načítanie zásob a budov

---

## Milník M8 – 0.1.0 First playable loop
Cieľ: mini herná slučka na mesiaci
- Začiatok s malým množstvom betónu
- Postaviť solárny panel
- Postaviť ťažobnú budovu na node
- Nazbierať betón a rozšíriť foundation
- HUD ukazuje zdroje, energia rozhoduje o činnosti, stavby spotrebúvajú zdroje
- Výstup: jednoduchý, ale kompletný základ hry

---

## Technický rámec
- Autoloady: BuildCfg, ResourceCfg, GameState
- Existujúce skripty sa rozšíria podľa potreby, bez pridávania nových priečinkov
- Minimalistický počet scén: Foundation, SolarPanel, MiningRig
- Rozšíriteľný základ pre budúce systémy (vzduch, životná podpora, kolonisti)

---

## Návrh API (pre ResourceCfg a GameState)
GameState.gd
- get(resource) → int
- add(resource, amount)
- can_spend(resource, amount) → bool
- spend(resource, amount) → bool

ResourceCfg.gd
- RES = { energy, concrete }
- COST = { Foundation, SolarPanel, MiningRig }
- POWER = { SolarPanel production, MiningRig draw }

---

## Pripravené commit správy
- feat(resources): GameState autoload a ResourceCfg definície
- feat(ui): HUD panel pre energiu a betón
- feat(build): kontrola cost pred potvrdením stavby
- feat(mining): MiningRig ťaží betón z node
- feat(power): SolarPanel produkcia a power draw logika
- chore(save): jednoduchý JSON save load stub
- 0.1.0: first playable loop
