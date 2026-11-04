# ملاحظات المصادر / Source notes — seed set (Task 10)

All rows are `status=draft`. Nothing here is shown in a default build until the
owner reviews it and marks it `reviewed`/`published` in the CSV (README §review).
No value was typed from memory: each value was transcribed from the online FAO
editions listed below (retrieved 2026-11-04). Where a source has no value for a
crop, or gives only a range or several alternatives that the schema cannot hold
as one number, the field or row is left **empty**.

> **ملخص بالعربية:** كل الصفوف مسودة. القيم منقولة حرفياً من FAO-56 (الجدولان 11 و12) وFAO-29 (الجدولان 4 و5).
> لم يُتح الوصول إلى قاعدة EcoCrop ولا إلى ملفات المركز الوطني للإحصاء (api.ncsi.gov.om) في جلسة الإعداد،
> لذلك بقيت حقول الحرارة وpH والقوام والارتفاع وطول الموسم فارغة، وملفا المحافظات والولايات بلا صفوف حتى تُنقل من المصدر.

## Sources (`sources.csv`)

| id | used for | status |
|---|---|---|
| `fao56` | `crop_stages.csv` — stage lengths (Table 11) and Kc (Table 12), Chapter 6, https://www.fao.org/4/x0490e/x0490e0b.htm | transcribed |
| `fao29` | `crop_requirements.csv` — `ece_threshold` (Table 4); `crops.csv` — scientific names (Tables 4–5), §2.4.3, https://www.fao.org/4/t0234e/T0234E03.htm | transcribed |
| `ecocrop` | intended for temperature, pH, texture, altitude, season length, life form | **not accessible** — ecocrop.review.fao.org denied by the session network policy; fields left empty |
| `ncsi_admin` | intended for the 11 governorates and 63 wilayats (AR/EN names) | **not accessible** — www.ncsi.gov.om loads, but every NCSI publication file is served from api.ncsi.gov.om, which the policy denies; `governorates.csv` and `wilayats.csv` are header-only |
| `project_spec` | crop list, Arabic names and categories (design spec §5.3) for crops that have no row in FAO-29 | project taxonomy, not an agronomic fact |

## `crops.csv`
- The 32 crops, Arabic names and categories come from spec §5.3; English names are plain translations of those labels.
- `scientific_name` is copied verbatim from FAO-29 Table 4 (preferred) or Table 5, so `source_id=fao29`. Note that FAO-29 uses older names in places (e.g. tomato *Lycopersicon esculentum*, now usually *Solanum lycopersicum*; eggplant *Solanum melongena esculentum*). These are left as the source prints them, for the reviewer to decide.
- Crops not in FAO-29 (garlic, banana, turmeric, damask rose, fenugreek, coconut, walnut, frankincense, henna, bougainvillea) and **Omani wheat** have an empty `scientific_name` and `source_id=project_spec`. Omani wheat is left empty because FAO-29 lists both *T. aestivum* and *T. turgidum*, and picking one would be a guess.
- `lifecycle` is empty for every crop: EcoCrop's "life form" field was meant to supply it.

## `crop_requirements.csv` (one row per crop; the importer test requires it)
- `ece_threshold` = FAO-29 Table 4, soil-salinity ECe (dS/m) at **100 % yield potential** (the "a" value of Eq. 10). Filled for tomato 2.5, cucumber 2.5, onion 1.2, potato 1.7, cowpea 4.9 (field-crop row, not forage), alfalfa 2.0, date palm 4.0, pepper 1.5, carrot 1.0, faba bean (Broadbean) 1.5, sorghum 6.8, grape 1.5.
- Not listed in Table 4, so left empty: every other crop. Watermelon, muskmelon, okra, mango, lime, papaya, pomegranate and Rhodes grass have only a qualitative class in Table 5, and the schema has no column for that.
- `ece_slope` is **empty**. Table 4 does not print b. FAO-29 says b "can be determined from Table 4" (from the 0–100 % columns), but that is a derived value, not a transcribed one. **Owner decision:** allow the derivation b = 100 / (ECe₀ − a) from Table 4, or wait for the original Maas (1984) values.
- All other columns (temperatures, chill hours, pH, texture, altitude, season days) are empty, pending EcoCrop.
- Every row has `source_id=fao29`. Rows with no value have `source_page = "Table 4 — crop not listed"`.

## `crop_stages.csv` (FAO-56)
**How a row was chosen in Table 11:** the first row whose region mentions an arid climate ("Arid Region", "Arid climate", "(Semi) Arid") was taken. A row with an ambiguous slash value such as `50/30` was skipped. Fallbacks, in order: "desert" or "Near East", then "Mediterranean", then the first row listed. **In Table 12:** the first listed sub-entry was taken. Where a crop row has no Kc ini, the group header row's Kc ini was used, as FAO-56 lays the table out.

**Meaning of `kc` per stage:** FAO-56 gives three values (Kc ini, Kc mid, Kc end) and defines the development and late stages as straight lines between them. Each stored `kc` is the value the curve reaches **at the end of that stage**:

| stage | stored kc |
|---|---|
| initial | Kc ini |
| development | Kc mid |
| mid | Kc mid |
| late | Kc end |

No interpolated or averaged number is stored. The later irrigation calculation (spec §الري) must interpolate within the development and late stages, as FAO-56 Fig. 25 does.

Table 12 values are for a sub-humid climate (RHmin ≈ 45 %, u2 ≈ 2 m/s). The FAO-56 climate adjustment (Eq. 62) has **not** been applied.

| crop | Table 11 row (days ini/dev/mid/late) | Table 12 entry (ini, mid, end) |
|---|---|---|
| cucumber | Cucumber, June/Aug, Arid Region (20/30/40/15) | Fresh Market 0.6, 1.00, 0.75 |
| onion | Onion (dry), Oct; Jan., Arid Region (20/35/110/45) | Onions – dry; ini from group a: 0.7, 1.05, 0.75 |
| potato | Arid row is `30/45` (ambiguous) → Calif. Desert, Dec (30/35/50/25) | 0.5 (group d), 1.15, 0.75 |
| watermelon | Near East (desert), Mat/Aug (10/20/20/30) | 0.4, 1.00, 0.75 |
| eggplant | October, Arid Region (30/40/40/20) | 0.6 (group b), 1.05, 0.90 |
| pepper | Sweet peppers (bell), October, Arid Region (30/40/110/30) | 0.6 (group b), 1.05, 0.90 |
| carrot | Arid row is `50/30` (ambiguous) → Calif. Desert, Oct (30/50/90/30) | 0.7 (group a), 1.05, 0.95 |
| muskmelon | Sweet melons, Dec/Jan, Arid Region (30/45/65/20) | Sweet Melons 0.5 (group c), 1.05, 0.75 |
| faba bean | Mediterranean, Mar/Apr (20/30/35/15) | Fresh 0.5, 1.15, 1.10 |
| lime_omani | Citrus, Jan, Mediterranean (60/90/120/95) | Citrus, no ground cover, 70 % canopy 0.70, 0.65, 0.70 |
| banana | Banana 1st yr, Mar, Mediterranean (120/90/120/60) | 1st year 0.50, 1.10, 1.00 |
| grape | Low Latitudes, April (20/40/120/60) | Table or Raisin 0.30, 0.85, 0.45 |
| walnut | Walnuts, April, Utah (20/10/130/30) | Walnut Orchard 0.50, 1.10, 0.65 |

**No stages, with the reason** (the app shows a crop's stages only when all four exist):
- **Range in Table 12** (owner to choose a value): tomato (Kc end 0.70–0.90), cowpea (Kc end 0.60–0.35: fresh vs dry harvest), wheat (Kc end 0.25–0.4), sorghum grain (Kc mid 1.00–1.10).
- **Not a four-stage crop:** alfalfa. FAO-56 describes it as a series of cutting cycles (Table 11 fn 4, Table 12 fn 13–14).
- **In Table 12 but not in Table 11:** garlic, date palm.
- **In neither table:** pomegranate, turmeric, damask rose, okra, fenugreek, Rhodes grass, mango, coconut ("Palm Trees" is not coconut-specific), papaya, frankincense, henna, bougainvillea.

## To finish this set
1. Allow `ecocrop.review.fao.org` and `api.ncsi.gov.om` in the environment's network policy. Then transcribe the EcoCrop fields and the NCSI governorate/wilayat names. When 63 wilayats import, the strict xfail in `data/tests/test_seed_import.py::test_seed_import_admin_divisions` will start failing; remove the marker then.
2. Owner decisions listed above: `ece_slope` derivation; which value to use where Table 12 gives a range; scientific-name updates.
