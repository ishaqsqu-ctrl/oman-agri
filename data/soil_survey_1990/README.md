# General Soil Map of the Sultanate of Oman (1990)

Source id `maf1990_soilmap` in `../sources.csv`. Ministry of Agriculture and Fisheries, Sultanate of
Oman, with FAO; first printing 1990. Received from the project owner on 2026-11-18 as phone photos
of the printed atlas (two sets, about 120 pages).

**Copyright.** © 1990 Ministry of Agriculture and Fisheries. The atlas says no part may be
reproduced without the Ministry's permission. The photos are **not** stored in this repository. The
tables here are transcribed facts with a page reference, for review. Copying the maps or photos into
the app needs the Ministry's written permission.

## What the atlas contains

| Part | Content | Use for the app |
|---|---|---|
| Introduction, environmental setting | 11 physiographic regions (figure 1), climate, rainfall and temperature charts for selected stations (figure 3) | Context |
| Methodology, map units (pp. 7–18) | Descriptions of 61 map units plus R (rock) and W (water), with soil taxonomy, slope, depth, salinity, land class | Explanations in the map's place card |
| Table 1 | Area and share of each map unit | Reference |
| **Land suitability classification (p. 19)** | Table 2: structure; **Table 3: criteria for S1, S2, S3, N** | **Transcribed:** `land_suitability_criteria.csv` |
| Tables 4–5 (p. 20) | Map units by land class; area by class | **Transcribed:** `map_unit_classes.csv`, `suitability_area.csv` |
| Table 6 | Limitations and reclamation measures for each map unit (large-scale irrigated farming) | To transcribe |
| Soil formation and classification | Soil-forming factors and processes; USDA Soil Taxonomy | Reference |
| **Pedons 1–20** | Location, landform, horizon descriptions and **laboratory data** (texture, pH, ECe, CaCO3, gypsum, CEC, exchangeable cations) | Documented points on the map, to transcribe |
| Laboratory methods, references, glossary | | Reference |
| The maps | Index sheet (56 sheets) and the general soil map: dark green = S1, light green = S2, yellow = N | Needs the Ministry's GIS file (see below) |

## Transcription status

| File | Status |
|---|---|
| `land_suitability_criteria.csv` | Transcribed 2026-11-18 from the photo of p. 19. Awaiting owner review. |
| `map_unit_classes.csv` | Transcribed from Table 4. Checked: units 1–61 each appear exactly once, plus R and W. Awaiting owner review. |
| `suitability_area.csv` | Transcribed from Table 5. Checked: S1 + S2 = 2,223,057 ha; suitable + N = 31,426,466 ha. Awaiting owner review. |
| `map_units.csv` | Map unit descriptions 1–61, R and W (pp. 7–18): dominant soils, description, slope range, land class. Awaiting owner review. |
| `pedons.csv` | Pedons 1–20: location, USDA and FAO classification, physiography, slope, parent material, field id, land use. Transcribed 2026-11-18. |
| `pedons_checked.csv` | Output of `check_pedons.py`: each location tested against the 1:250 000 sheet named in its field id and against the land grid. 14 verified; 4, 8 and 14 have no readable sheet code; 10, 15 and 17 disagree with their sheet. Those six need the printed page. |
| Pedon laboratory tables | **Not transcribed.** In the photos each digit is a few pixels high; guessing them would put wrong numbers in the app. Needs close, flat photos of each table. |
| Table 1 (area per map unit) | Not transcribed: low value without the map itself, and the photo's rows are hard to align. |

Suitable land (S1 + S2) is 7.07 % of Oman; 2.52 % is S1 (highly to moderately suitable).

The national salinity criterion (ECe in the top 100 cm: S1 < 8, S2 8–16, > 16 reclaimable or not
suitable) is for land suitability under irrigation. It is not the same as the FAO 29 crop
thresholds the app uses for each crop.

## Why the maps are not digitised from these photos

The 56 sheets are photographed at an angle on a curved page, at about 1600 × 750 pixels. Tracing
boundaries from them would place soil units hundreds of metres to kilometres off. The Ministry
(now the Ministry of Agriculture, Fisheries and Water Resources) is likely to hold the map as a GIS
file. With that file and permission, the app can show S1/S2/N land and the map unit at any point.
