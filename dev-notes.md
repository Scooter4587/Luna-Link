## Building system – design (0.0.41)

### Axes

- **domain**
  - `exterior` – budovy na povrchu Mesiaca
  - `interior` – budovy / objekty vo vnútri (v miestnostiach)

- **footprint_type**
  - `fixed` – pevný footprint, klikaná stavba (napr. extractor, solar)
  - `rect_drag` – obdĺžnik ťahaný myšou (foundations, rooms)
  - `path` – A → B trasa po gride (power cables, rails, pipes)

- **anchor_type**
  - `free` – stačí voľná plocha
  - `on_resource_node` – musí zasahovať resource node (He-3, ore, ice…)
  - `on_foundation` – musí byť na existujúcej foundation / room ploche
  - `inside_room` – musí byť v ľubovoľnej miestnosti (budúcnosť)
  - `inside_room_type_*` – musí byť v konkrétnom type room (budúcnosť)

### ALFA building types (0.0.5 target)

- `foundation_basic`
  - domain: `exterior`
  - footprint_type: `rect_drag`
  - anchor_type: `free`

- `bm_extractor`
  - domain: `exterior`
  - footprint_type: `fixed`
  - anchor_type: `on_resource_node`

- `solar_panel`
  - domain: `exterior`
  - footprint_type: `fixed`
  - anchor_type: `free` (neskôr možno `on_foundation`)

- `power_cable`
  - domain: `exterior`
  - footprint_type: `path`
  - anchor_type: `free`

- `room_basic`
  - domain: `interior`
  - footprint_type: `rect_drag`
  - anchor_type: `on_foundation`
