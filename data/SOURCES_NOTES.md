# ملاحظات المصادر / Source notes — seed set (Task 10)

**Owner review 2026-11-04** (`reviewed_by = Project owner`): rows the owner marked correct are
`published`; rows the owner corrected carry the correction and are `reviewed`, waiting for one
"Publish reviewed" click in the admin panel (and `published` in the CSV). Every correction cites
its source in `source_page`; see "Owner review outcome" at the end. The sections below describe
the original transcription.
No value was typed from memory: each value was transcribed from the sources
listed below (retrieved 2026-11-04). Where a source has no value for a crop, or
gives only a range or several alternatives that the schema cannot hold as one
number, the field or row is left **empty**.

> **ملخص بالعربية:** راجع المالك كل الصفوف في 2026-11-04: ما أكّده منشور، وما صحّحه بحالة «مراجَع» بانتظار النشر. فيما يلي وصف النقل الأصلي. القيم منقولة من FAO-56 (الجدولان 11 و12) وFAO-29 (الجدولان 4 و5) وقاعدة EcoCrop
> (نسخة كاملة منشورة من OpenCLIM لأن موقع FAO الحالي يتطلب تسجيل دخول)، وأسماء المحافظات الـ11 والولايات الـ63 بالعربية
> والإنجليزية من الكتاب الإحصائي السنوي 2026 (الإصدار 54) للمركز الوطني للإحصاء والمعلومات، ص 37–38، كما طُبعت.
> بقيت فارغة: متطلبات الموز والقمح العُماني والورد الدمشقي واللبان والبوغنفيليا (النوع غير محدد أو غير موجود في EcoCrop)،
> وساعات البرودة والارتفاع الأدنى (لا توجد في EcoCrop)، و`ece_slope`. القرارات المطلوبة من المالك في آخر الملف.

## Sources (`sources.csv`)

| id | used for | status |
|---|---|---|
| `fao56` | `crop_stages.csv` — stage lengths (Table 11) and Kc (Table 12), Chapter 6, https://www.fao.org/4/x0490e/x0490e0b.htm | transcribed |
| `fao29` | `crop_requirements.csv` — `ece_threshold` (Table 4); `crops.csv` — scientific names (Tables 4–5), §2.4.3, https://www.fao.org/4/t0234e/T0234E03.htm | transcribed |
| `ecocrop` | the FAO EcoCrop database itself (https://ecocrop.review.fao.org) | **kept for reference, not cited by any row** — the site now redirects to a Google sign-in (IAP), so it could not be read |
| `ecocrop_openclim` | temperature, pH, texture, altitude, season length (`crop_requirements.csv`); `lifecycle` and six scientific names (`crops.csv`) | transcribed from `EcoCrop_DB.csv`, the full EcoCrop export redistributed by OpenCLIM / UKCEH (https://github.com/OpenCLIM/ecocrop, Zenodo DOI 10.5281/zenodo.10843625; the repo README calls it "the full FAO EcoCrop database"). It is a secondary copy, so reliability is 2; spot-checking against FAO's own site is a review item |
| `ncsi_admin` | the 11 governorates and 63 wilayats, AR/EN names | transcribed from NCSI *Statistical Year Book 2026, Issue 54*, table "المحافظات والولايات / Governorate And Wilayat", printed pp. 37–38 (PDF pages 38–39). The PDF's Arabic text layer is scrambled, so the Arabic names were read off the rendered page images |
| `project_spec` | crop list, Arabic names and categories (design spec §5.3) for crops with no name in a source | project taxonomy, not an agronomic fact |

## `governorates.csv`, `wilayats.csv` (NCSI)
- Names are as printed in the Year Book, in both languages, including its spellings (e.g. `محظة` / Mahdah, `ادم`, `ازكي`, `ابراء` without hamza, English `Al-Buraymi`, `Jabal Al-Akhdhar`). Governorate names drop the words «محافظة» / "Governorate".
- Governorate English names follow the Year Book order of words ("Al Batinah North", not "North Al Batinah" as in `data/demo/`).
- ids are ASCII snake case of the English name (`as_seeb`, `jaalan_bani_bu_ali`); governorate ids are short forms (`batinah_north`, `sharqiyah_south`). A wilayat may share an id with its governorate (`muscat`) — they are separate tables.
- Counts per governorate (Year Book): Muscat 6, Dhofar 10, Musandam 4, Al-Buraymi 3, Ad Dakhiliyah 9, Al Batinah North 6, Al Batinah South 6, Ash Sharqiyah South 5, Ash Sharqiyah North 7, Adh Dhahirah 3, Al Wusta 4 = **63**.

## `crops.csv`
- The 32 crops, Arabic names and categories come from spec §5.3; English names are plain translations of those labels.
- `scientific_name` is copied verbatim from FAO-29 Table 4 (preferred) or Table 5, so `source_id=fao29`. FAO-29 uses older names in places (tomato *Lycopersicon esculentum*, now usually *Solanum lycopersicum*; eggplant *Solanum melongena esculentum*). They are left as printed, for the reviewer to decide.
- Six crops absent from FAO-29 now take their name from the EcoCrop record (`source_id=ecocrop_openclim`): garlic *Allium sativum*, turmeric *Curcuma longa*, fenugreek *Trigonella foenum-graecum*, coconut *Cocos nucifera*, walnut *Juglans regia*, henna *Lawsonia inermis*. Each is the only EcoCrop species for that crop name, except walnut (see review items).
- Still no scientific name, `source_id=project_spec`: Omani wheat (FAO-29 and EcoCrop both list *T. aestivum* and *T. durum/turgidum*), banana (many *Musa* records, no single cultivated one), damask rose (no *Rosa damascena* in EcoCrop), frankincense (EcoCrop has *Boswellia serrata* only, not the Omani *B. sacra*), bougainvillea (only *B. glabra*; the species grown is not specified).
- `lifecycle` from EcoCrop: `tree` when life form (LIFO) includes "tree"; otherwise `annual`/`perennial` when the life span (LISPA) is exactly that. Left **empty** when LISPA is `biennial` (onion, garlic, carrot) or `annual, perennial` (Rhodes grass), since the schema has no such value.

## `crop_requirements.csv` (one row per crop; the importer test requires it)
**EcoCrop fields** (27 crops; EcoPortCode in each row's `source_page`). Matching was by the crop's scientific name — the FAO-29 name where there is one (eggplant via EcoCrop's synonym list, lime *aurantiifolia* = EcoCrop *aurantifolia*). Column mapping:

| schema | EcoCrop | note |
|---|---|---|
| `t_min`, `t_opt_low`, `t_opt_high`, `t_max` | TMIN, TOPMN, TOPMX, TMAX | absolute and optimal temperature, °C |
| `ph_min`, `ph_max` | PHMIN, PHMAX | **absolute** range (EcoCrop also has an optimal range PHOPMN/PHOPMX, not stored) |
| `textures` | TEXTR | **absolute** range; light→sand, medium→loam, heavy→clay (EcoCrop's own glossary). "organic" and "wide" have no schema value and are dropped, so onion (`wide, organic`) and sorghum (`wide`) have empty textures |
| `alt_max` | ALTMX | EcoCrop gives no minimum altitude, so `alt_min` is empty |
| `season_days_min`, `season_days_max` | GMIN, GMAX | `0 0` in EcoCrop means "no value" (watermelon) and is left empty |
| `chill_hours_min` | — | not in EcoCrop; empty |

- `ece_threshold` = FAO-29 Table 4, soil-salinity ECe (dS/m) at **100 % yield potential**. Filled for tomato 2.5, cucumber 2.5, onion 1.2, potato 1.7, cowpea 4.9, alfalfa 2.0, date palm 4.0, pepper 1.5, carrot 1.0, faba bean 1.5, sorghum 6.8, grape 1.5. Not in Table 4 → empty. EcoCrop's own salinity class (SAL) is not stored.
- `ece_slope` is **empty**: Table 4 does not print b (see owner decisions).
- One row has one `source_id`. Rows with EcoCrop values cite `ecocrop_openclim`, and their `source_page` states which fields came from FAO-29 Table 4. The five crops with no EcoCrop match (banana, Omani wheat, damask rose, frankincense, bougainvillea) keep `source_id=fao29` and are otherwise empty.

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

## Owner review outcome (2026-11-04)
Status after the review: crops 19 published / 13 reviewed; crop_requirements 22 / 10; crop_stages 52 / 0;
governorates 11 / 0; wilayats 62 / 1 (Mahdah).

Corrections applied (all `reviewed`):
- **Scientific names** (decision 9): tomato *Solanum lycopersicum*, eggplant *Solanum melongena*, grape *Vitis vinifera* (FAO-29 lists grape in Table 4, not 5). Older FAO-29 names are kept in `source_page`; a synonym field for search is a later schema change.
- **Species** (decisions 1–5): Omani wheat *Triticum aestivum* (`alkhanjari2005`), banana *Musa spp.* (`opara2010`), bougainvillea *Bougainvillea glabra* (EcoCrop 3795), damask rose *Rosa × damascena*, frankincense *Boswellia sacra* (not EcoCrop's *B. serrata*), walnut *Juglans regia* confirmed.
- **Lifecycle** (decision 8): onion, garlic, carrot → `annual`; Rhodes grass → `perennial`; wheat `annual`; banana, damask rose, bougainvillea `perennial`; frankincense `tree`.
- **English name:** alfalfa → "Alfalfa (lucerne)" ("qat" means *Catha edulis* in English).
- **Requirements:** wheat from EcoCrop 2114 + FAO-29 ECe 6.0; banana from EcoCrop 7849 (*Musa acuminata × balbisiana*), ECe empty (FAO-61: sensitive, no number); bougainvillea from EcoCrop 3795, season empty; onion and sorghum textures `sand|loam|clay` (EcoCrop "wide"; "organic" has no schema value); eggplant `alt_max` emptied (EcoCrop's 50 m rejected).
- **Salinity** (decision 7, new source `fao61`, Maas & Grattan 1999): ECe/slope garlic 3.9/14.3, eggplant 1.1/6.9, muskmelon 1.0/8.4; slopes wheat 7.1, tomato 9.9, date palm 3.6. Other slopes stay empty until transcribed from FAO-61 Annex 1.
- **Mahdah:** the Year Book's Governorate and Wilayat table (pp. 37–38) prints «محظة», but the same Year Book prints «محضة» in later tables (PDF pp. 65, 81); the owner adopted «محضة».

Still open (not data edits):
- **Decision 6 — stage rows for tomato, cowpea, wheat, sorghum** do not exist yet: the chosen Kc values (tomato end 0.80; cowpea 0.60 fresh / 0.35 dry; wheat end 0.25; sorghum mid 1.05) still need the stage lengths from FAO-56 Table 11. Cowpea needs a fresh-or-dry choice, or two crop entries.
- **Decision 10:** the app should interpolate Kc linearly day by day across development and late stages (FAO-56 ch. 6); stored values stay the end-of-stage points.
- **Decision 11:** adjust Kc mid/end per wilayat with FAO-56 Eq. 62 once climate data (RHmin, u2) is in the pipeline.
- Damask rose and frankincense requirements stay empty until a ministry or SQU source is found (decision 4).
- EcoCrop spot-check against FAO's own site (the owner checked every value against the OpenCLIM copy).
