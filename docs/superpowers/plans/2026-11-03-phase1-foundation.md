# Phase 1 — Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A bilingual (Arabic-first, RTL) Flutter app that browses a source-cited crop knowledge base (32 crops, draft status), backed by a Supabase-compatible Postgres schema with row-level security, a CSV data workflow the project owner can review in Excel, and a minimal admin publish screen.

**Architecture:** Agronomic knowledge lives in CSV files under `data/` (the reviewable source of truth), is validated by a Python script, imported into Postgres (Supabase schema in `supabase/migrations/`), and exported to a bundled JSON snapshot so the app works with no backend and offline. The Flutter app reads through one `KnowledgeRepository` that prefers Supabase, falls back to a cached snapshot, then to the bundled asset, and shows only `published` rows unless built with `SHOW_DRAFTS=true`.

**Tech Stack:** Flutter 3.47.9 stable (Dart), flutter_riverpod, go_router, supabase_flutter, shared_preferences, flutter_localizations (ARB); PostgreSQL 16 + PostGIS 3.4; Python 3.13 + pytest + psycopg 3.

**Spec:** `docs/superpowers/specs/2026-11-03-oman-agri-app-design.md` (this plan covers build-order row 1 "الأساس" of §16).

## Global Constraints

- Every knowledge row carries `status` (`draft`|`reviewed`|`published`), `source_id` (NOT NULL, FK to `sources`), `source_page`, `reviewed_by`, `reviewed_at` (spec §5.4).
- `published` requires non-null `reviewed_by` and `reviewed_at`; the app never shows non-published rows except in a `SHOW_DRAFTS=true` build, which shows a persistent "مسودة — قيد المراجعة / Draft — under review" banner (spec §5.5).
- Every displayed agronomic fact has a "المصدر / Source" affordance (spec §5.5).
- Arabic is the default locale and layout is RTL; English is fully supported (spec §1 criterion 6).
- Crop categories (spec §5.2): `vegetable, fruit, legume, cereal, forage, ornamental, medicinal_aromatic, tree`. A crop may have several (pipe-separated in CSV).
- Roles (spec §3): `farmer, shop, admin`. Anonymous visitors may read published knowledge.
- Validator bounds (spec §14): `kc` in `[0, 1.5]`; months in `1..12`; temperatures ordered `t_min ≤ t_opt_low ≤ t_opt_high ≤ t_max`.
- No fabricated data: every seed value is transcribed from a listed source with a page/table reference; all seed rows ship as `draft`.
- Timezone for any date logic: `Asia/Muscat` (UTC+4).
- Offline cache in this phase is a JSON snapshot (file on native, shared_preferences on web); Drift arrives in phase 4 with farm data. This is a deliberate, scoped deviation from spec §4's table — note it in the README.

## Review Focus

1. **Arabic search with diacritics / letter variants** — searching "طماطم" must find "الطَّماطِم"; "ليمون" must find "ليمون عُماني"; "اناناس" matches "أناناس"; "بامية" matches "باميه". Test in Task 8.
2. **Draft leakage** — a default build with all-draft data shows an empty-state message, not draft crops. Test in Task 7.
3. **CSV edited in Excel** — UTF-8 BOM, CRLF line endings, trailing spaces, blank trailing rows must validate and import identically to clean files. Test in Task 4.
4. **First launch with no network** — the app shows bundled data; with a stale cache and failing network, it shows the cache. Test in Task 7.
5. **Language switch persistence and mixed-direction text** — the chosen locale survives restart; Latin scientific names inside Arabic screens render LTR in isolation. Test in Task 6 (persistence) and Task 8 (scientific name wrapped in `Directionality(ltr)`).

---

### Task 1: Environment and repository scaffold

**Files:**
- Create: `tools/setup_env.sh`, `README.md` (Arabic first, English second), `.gitignore`, `requirements-dev.txt`

**Interfaces:**
- Produces: `tools/setup_env.sh` — idempotent; installs Flutter 3.47.9 to `$HOME/flutter` (archive `stable/linux/flutter_linux_3.47.9-stable.tar.xz` from `storage.googleapis.com/flutter_infra_release/releases/`), apt-installs `postgresql-16-postgis-3`, pip-installs `requirements-dev.txt` (`pytest`, `psycopg[binary]>=3.2`). Prints `flutter --version` and `pg_config --version`.

- [ ] **Step 1:** Write `tools/setup_env.sh` and `requirements-dev.txt`; `.gitignore` covers Flutter (`build/`, `.dart_tool/`), Python (`__pycache__/`, `.pytest_cache/`), and `.env*`.
- [ ] **Step 2:** Run `bash tools/setup_env.sh`. Expected: last lines show `Flutter 3.47.9` and `PostgreSQL 16`.
- [ ] **Step 3:** Run it again. Expected: same output, no re-download (idempotent).
- [ ] **Step 4:** README sections: what the project is; folder map (spec §4 structure); how to run setup, tests, and the app; the data review workflow (edit CSV → set `status=reviewed`, fill `reviewed_by`/`reviewed_at` → admin publishes).
- [ ] **Step 5:** Commit `chore: environment setup script and README`.

---

### Task 2: Core database schema + test harness

**Files:**
- Create: `supabase/migrations/20261103000001_core_knowledge.sql`
- Create: `supabase/tests/auth_stub.sql` (test-only Supabase shims)
- Create: `supabase/tests/conftest.py`, `supabase/tests/test_schema.py`

**Interfaces:**
- Produces (SQL):
  - enums `knowledge_status('draft','reviewed','published')`, `crop_category(<8 values from Global Constraints>)`, `lifecycle('annual','perennial','tree')`, `source_type('ministry','university','fao','peer_reviewed','dataset','other')`, `user_role('farmer','shop','admin')`, `growth_stage('initial','development','mid','late')`, `soil_texture('sand','loam','clay')`
  - `sources(id text pk, title text not null, publisher text not null, year int, url text, type source_type not null, reliability smallint check 1..3)`
  - `governorates(id text pk, name_ar, name_en)`; `wilayats(id text pk, governorate_id fk, name_ar, name_en)` — both with knowledge meta columns
  - `crops(id text pk, name_ar, name_en, scientific_name, categories crop_category[] not null check cardinality ≥1, lifecycle, notes_ar, notes_en)` + meta
  - `crop_requirements(crop_id pk fk, t_min, t_opt_low, t_opt_high, t_max numeric, chill_hours_min int, ece_threshold numeric, ece_slope numeric, ph_min, ph_max numeric, textures soil_texture[], alt_min, alt_max int, season_days_min, season_days_max int)` + meta, CHECK on temperature ordering
  - `crop_stages(crop_id fk, seq smallint, stage growth_stage, duration_days int > 0, kc numeric check 0..1.5, primary key(crop_id, seq))` + meta
  - `profiles(id uuid pk references auth.users on delete cascade, role user_role not null default 'farmer', display_name text)`; trigger creating a profile on `auth.users` insert
  - Meta columns on every knowledge table: `status knowledge_status not null default 'draft'`, `source_id text not null references sources`, `source_page text`, `reviewed_by text`, `reviewed_at timestamptz`, CHECK `(status <> 'published' or (reviewed_by is not null and reviewed_at is not null))`
- Produces (pytest fixture in `conftest.py`): `db` — starts a throwaway Postgres 16 cluster (`initdb` in `tmp_path_factory`, random port, `pg_ctl start`), loads `auth_stub.sql` then every file in `supabase/migrations/` in name order, yields a psycopg connection; `as_role(conn, role: str, uid: str | None)` context manager that does `set local role` and sets `request.jwt.claim.sub`.
- `auth_stub.sql` creates roles `anon`, `authenticated`, schema `auth`, table `auth.users(id uuid pk, email text)`, function `auth.uid()` returning `nullif(current_setting('request.jwt.claim.sub', true), '')::uuid` — mirroring Supabase, so migrations run unchanged on real Supabase.

- [ ] **Step 1: Write failing tests** in `test_schema.py`:
  - `test_published_requires_review`: inserting a crop with `status='published'` and null `reviewed_by` raises `psycopg.errors.CheckViolation`.
  - `test_source_required`: crop insert with `source_id=None` raises `NotNullViolation`.
  - `test_temperature_order`: requirements with `t_opt_low=30, t_opt_high=20` raises `CheckViolation`.
  - `test_kc_bounds`: stage with `kc=1.6` raises `CheckViolation`.
  - `test_profile_created_on_signup`: insert into `auth.users` → `profiles` row with role `farmer`.
- [ ] **Step 2:** Run `pytest supabase/tests -v`. Expected: FAIL (tables missing).
- [ ] **Step 3:** Write the migration per the Interfaces block.
- [ ] **Step 4:** Run `pytest supabase/tests -v`. Expected: 5 passed.
- [ ] **Step 5:** Commit `feat(db): core knowledge schema with source and review constraints`.

---

### Task 3: Row-level security and publish RPC

**Files:**
- Create: `supabase/migrations/20261103000002_rls.sql`
- Test: `supabase/tests/test_rls.py`

**Interfaces:**
- Consumes: Task 2 tables, `as_role` fixture.
- Produces:
  - `public.is_admin() returns boolean` (security definer, `stable`): true when `profiles.role = 'admin'` for `auth.uid()`.
  - RLS enabled on all tables. Knowledge tables + `sources`: `select` for `anon, authenticated` where `status = 'published'` (sources: always readable); all operations for `is_admin()`.
  - `profiles`: user selects/updates own row but cannot change `role`; admin all.
  - `public.publish_reviewed(p_table text) returns integer` (security definer): raises `insufficient_privilege` unless `is_admin()`; `p_table` must be one of the knowledge tables (else raises `invalid_parameter_value`); sets `status='published'` where `status='reviewed'`; returns affected count.
  - `public.knowledge_status_counts() returns table(table_name text, status knowledge_status, n bigint)` — admin only.

- [ ] **Step 1: Write failing tests:**
  - `test_anon_sees_only_published`: seed one draft + one published crop; as `anon`, `select id from crops` returns only the published id.
  - `test_farmer_cannot_write_knowledge`: as authenticated farmer, `insert into crops` raises `InsufficientPrivilege`.
  - `test_farmer_cannot_promote_self`: farmer `update profiles set role='admin'` → role unchanged / error.
  - `test_publish_reviewed_admin`: two `reviewed` crops (with reviewer fields) + one `draft`; admin calls `publish_reviewed('crops')` → returns 2; draft untouched.
  - `test_publish_reviewed_non_admin`: farmer call raises `InsufficientPrivilege`.
  - `test_publish_reviewed_bad_table`: admin with `'profiles'` raises `InvalidParameterValue`.
- [ ] **Step 2:** Run `pytest supabase/tests/test_rls.py -v`. Expected: FAIL.
- [ ] **Step 3:** Write the migration.
- [ ] **Step 4:** Run `pytest supabase/tests -v`. Expected: all pass.
- [ ] **Step 5:** Commit `feat(db): RLS policies and admin publish RPC`.

---

### Task 4: CSV knowledge format and validator

**Files:**
- Create: `data/schema.py` (column specs per file), `data/validate.py`, `data/csvio.py`
- Test: `data/tests/test_validate.py`, `data/tests/fixtures/` (small valid + broken CSV sets)

**Interfaces:**
- Produces:
  - CSV files (one per table), header = DB column names; array columns pipe-separated (`vegetable|legume`); meta columns last: `status,source_id,source_page,reviewed_by,reviewed_at`. Files: `sources.csv, governorates.csv, wilayats.csv, crops.csv, crop_requirements.csv, crop_stages.csv`.
  - `csvio.read_rows(path: Path) -> list[dict[str, str]]` — reads with `encoding='utf-8-sig'`, `newline=''`, strips every cell, drops rows whose cells are all empty.
  - `validate.validate_dir(path: Path) -> list[Issue]` where `Issue = NamedTuple(file: str, row: int, column: str, message_ar: str, message_en: str)`; row numbers are 1-based spreadsheet rows (header = row 1).
  - CLI: `python -m data.validate data/` prints issues (Arabic then English) and exits 1 if any, else prints `OK: <n> rows` and exits 0.
  - Rules: unique ids; FK existence (`source_id`, `crop_id`, `governorate_id`); enum membership; numeric parse; temperature order; `kc` bounds; `ph` in `0..14` and `ph_min ≤ ph_max`; `alt_min ≤ alt_max`; `season_days_min ≤ season_days_max`; `status=published|reviewed` requires `reviewed_by` and ISO date `reviewed_at`; `name_ar` contains Arabic letters, `name_en` does not; stages for a crop have contiguous `seq` from 1.

- [ ] **Step 1: Write failing tests** — one per rule, each using a fixture directory with exactly one defect and asserting exactly one `Issue` with the expected `file`, `row`, `column`; plus:
  - `test_excel_artifacts_ok`: fixture saved with BOM, CRLF, trailing spaces and two blank trailing rows → `[]`.
  - `test_cli_exit_codes`: subprocess on valid fixture → exit 0 and stdout starts `OK:`; on broken → exit 1.
- [ ] **Step 2:** Run `pytest data/tests -v`. Expected: FAIL.
- [ ] **Step 3:** Implement `schema.py`, `csvio.py`, `validate.py`.
- [ ] **Step 4:** Run `pytest data/tests -v`. Expected: all pass.
- [ ] **Step 5:** Commit `feat(data): CSV knowledge format and bilingual validator`.

---

### Task 5: Importer and app snapshot exporter

**Files:**
- Create: `data/import_db.py`, `data/export_snapshot.py`
- Test: `data/tests/test_import_export.py` (reuses the `db` fixture via `conftest.py` at repo root that imports `supabase/tests/conftest.py` fixtures)

**Interfaces:**
- Consumes: `validate_dir`, `read_rows`, Task 2 schema.
- Produces:
  - `import_db.import_dir(path: Path, conn) -> dict[str, int]` — refuses (raises `ValueError` listing issues) if `validate_dir` returns issues; upserts in FK order (`sources, governorates, wilayats, crops, crop_requirements, crop_stages`) with `on conflict do update`; one transaction; returns rows per table. CLI `python -m data.import_db data/ --dsn $DATABASE_URL`.
  - `export_snapshot.build_snapshot(path: Path) -> dict` — from CSV (not DB), shape:
    `{"schema_version": 1, "generated_at": ISO, "sources": [...], "governorates": [...], "wilayats": [...], "crops": [{...crop, "requirements": {...}|null, "stages": [...]}]}`; every row keeps its meta fields. CLI writes `app/assets/seed/knowledge.json` (UTF-8, `ensure_ascii=False`, sorted keys).

- [ ] **Step 1: Write failing tests:**
  - `test_import_counts`: valid fixture → counts match row counts; second run idempotent (same counts, no duplicates).
  - `test_import_rejects_invalid`: broken fixture → `ValueError`, DB unchanged.
  - `test_import_updates_changed_value`: change `name_en` in a copy, re-import → DB has new value.
  - `test_snapshot_shape`: `schema_version == 1`; crop `tomato` has nested `requirements` and stages ordered by `seq`; Arabic preserved unescaped in the written file.
- [ ] **Step 2:** Run `pytest data/tests/test_import_export.py -v`. Expected: FAIL.
- [ ] **Step 3:** Implement both modules.
- [ ] **Step 4:** Run `pytest -v` (whole repo). Expected: all pass.
- [ ] **Step 5:** Commit `feat(data): DB importer and app snapshot exporter`.

---

### Task 6: Flutter app shell — bilingual, RTL, navigation, settings

**Files:**
- Create: `app/` via `flutter create --org om.mazari --project-name oman_agri --platforms android,ios,web,windows,macos,linux app`
- Create: `app/l10n.yaml`, `app/lib/l10n/app_ar.arb`, `app/lib/l10n/app_en.arb`
- Create: `app/lib/main.dart`, `app/lib/app.dart`, `app/lib/core/theme.dart`, `app/lib/core/router.dart`, `app/lib/core/locale_controller.dart`, `app/lib/features/settings/settings_screen.dart`, `app/lib/features/shell/coming_soon_screen.dart`
- Test: `app/test/app_shell_test.dart`

**Interfaces:**
- Produces:
  - `localeControllerProvider` (Riverpod `NotifierProvider<LocaleController, Locale>`): initial `Locale('ar')`; `setLocale(Locale)` persists key `locale` in shared_preferences; restores on startup.
  - `appRouter` (go_router) with a bottom-navigation `StatefulShellRoute` of 5 tabs, in order: `/` home (crops list from Task 8), `/map`, `/calendar`, `/farm`, `/store` — tabs 2–5 render `ComingSoonScreen(featureKey)`; plus `/settings`, `/crops/:id`, `/admin`.
  - Theme: Material 3, seed color `#2E7D32`; Arabic font `Noto Kufi Arabic`/`Noto Sans Arabic` bundled as asset (no runtime font download, for offline).
  - ARB keys needed now: `appTitle` ("مزارع عُمان" / "Oman Farmer"), `tabHome, tabMap, tabCalendar, tabFarm, tabStore, settings, language, arabic, english, comingSoon, draftBanner, source, emptyCrops, searchCrops, allCategories`, and one key per crop category.

- [ ] **Step 1: Write failing widget tests:**
  - `default locale is Arabic and RTL`: pump app → `Directionality.of(ctx) == TextDirection.rtl` and `find.text('مزارع عُمان')`.
  - `switching to English persists`: tap settings → English → widget shows `Oman Farmer` and LTR; rebuild app with same `SharedPreferences` mock → still English.
  - `five tabs in order`: labels match `tabHome..tabStore` Arabic strings.
- [ ] **Step 2:** Run `cd app && flutter test test/app_shell_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `cd app && flutter test && flutter analyze`. Expected: all pass, `No issues found!`.
- [ ] **Step 5:** Commit `feat(app): bilingual RTL shell with navigation and settings`.

---

### Task 7: Knowledge models and repository (Supabase → cache → bundled)

**Files:**
- Create: `app/lib/features/crops/data/models.dart`, `app/lib/features/crops/data/knowledge_repository.dart`, `app/lib/features/crops/data/snapshot_cache.dart`, `app/lib/core/config.dart`
- Test: `app/test/knowledge_repository_test.dart`, `app/test/fixtures/knowledge_min.json`

**Interfaces:**
- Consumes: snapshot JSON shape from Task 5.
- Produces:
  - `config.dart`: `const supabaseUrl = String.fromEnvironment('SUPABASE_URL')`, `supabaseAnonKey`, `const showDrafts = bool.fromEnvironment('SHOW_DRAFTS')`; `bool get hasBackend => supabaseUrl.isNotEmpty`.
  - Models (immutable, `fromJson`): `Source`, `Crop{id, nameAr, nameEn, scientificName, categories: List<CropCategory>, lifecycle, requirements: CropRequirements?, stages: List<CropStage>, meta: KnowledgeMeta}`, `KnowledgeMeta{status, sourceId, sourcePage, reviewedBy, reviewedAt}`, `KnowledgeSnapshot{generatedAt, sources: Map<String, Source>, crops: List<Crop>}`. `Crop.localizedName(Locale)`.
  - `abstract class SnapshotSource { Future<KnowledgeSnapshot> load(); }` with `SupabaseSnapshotSource`, `CachedSnapshotSource` (`SnapshotCache.read/write`), `BundledSnapshotSource` (asset `assets/seed/knowledge.json`).
  - `KnowledgeRepository({required List<SnapshotSource> chain, required bool includeDrafts, SnapshotCache? cache})`: `Future<KnowledgeSnapshot> load()` tries each source in order; the first success is written to cache (unless it came from the cache/bundle) and returned; filters out non-`published` rows unless `includeDrafts`. Chain is `[Supabase if hasBackend, Cached, Bundled]`.
  - `knowledgeProvider` = `FutureProvider<KnowledgeSnapshot>`.

- [ ] **Step 1: Write failing tests** (fake sources):
  - `falls back to bundled when network fails and no cache` → returns bundled crops.
  - `uses cache when network fails` → returns cached snapshot, not bundled.
  - `writes network result to cache`.
  - `hides drafts by default`: fixture with 1 published + 2 draft → 1 crop.
  - `shows drafts when includeDrafts` → 3 crops.
  - `parses fixture`: tomato has 4 stages, `requirements.tOptHigh == fixture value`.
- [ ] **Step 2:** Run `flutter test test/knowledge_repository_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement. Supabase source selects from the 5 tables via `supabase_flutter` and assembles the same `KnowledgeSnapshot`.
- [ ] **Step 4:** Run `flutter test`. Expected: all pass.
- [ ] **Step 5:** Commit `feat(app): knowledge repository with offline fallback and draft filtering`.

---

### Task 8: Crops browsing UI — list, category filter, Arabic search, detail with sources

**Files:**
- Create: `app/lib/core/arabic_normalize.dart`, `app/lib/features/crops/ui/crops_list_screen.dart`, `app/lib/features/crops/ui/crop_detail_screen.dart`, `app/lib/features/crops/ui/source_button.dart`, `app/lib/features/crops/ui/draft_banner.dart`
- Test: `app/test/arabic_normalize_test.dart`, `app/test/crops_ui_test.dart`

**Interfaces:**
- Consumes: `knowledgeProvider`, `Crop`, `Source`, `showDrafts`.
- Produces:
  - `String normalizeArabic(String s)`: lowercase; remove tashkeel `U+064B–U+0652`, `U+0670`, tatweel `U+0640`; map `أ إ آ ٱ → ا`, `ى → ي`, `ة → ه`, `ؤ → و`, `ئ → ي`; collapse whitespace.
  - `bool cropMatches(Crop c, String query)`: normalized query is a substring of normalized `nameAr`, `nameEn`, or `scientificName`.
  - `SourceButton(sourceId, page)`: icon button labelled `source`; opens a bottom sheet with title, publisher, year, page, and tappable URL.
  - Crop detail sections: names (scientific name in `Directionality(textDirection: TextDirection.ltr)`), categories as chips, requirements table (temperatures °C, chill hours, salinity threshold dS/m, pH, textures, altitude m, season days) each row with `SourceButton`, stages table (stage, days, Kc) with `SourceButton`.

- [ ] **Step 1: Write failing tests:**
  - normalize: `normalizeArabic('الطَّماطِم') == normalizeArabic('الطماطم')`; `'أناناس'` vs `'اناناس'` equal; `'باميه'` vs `'بامية'` equal.
  - `cropMatches(lemon /*nameAr: ليمون عُماني*/, 'ليمون') == true`; `cropMatches(tomato, 'Solanum') == true`.
  - UI: list shows all fixture crops; typing `طماطم` leaves only tomato; selecting category chip `legume` leaves only legumes; empty result shows `emptyCrops` text.
  - UI: tapping tomato opens detail; tapping first `SourceButton` shows the fixture source title.
  - UI: with `includeDrafts=true` override, `DraftBanner` is visible; with false and all-draft fixture, `emptyCrops` shows.
- [ ] **Step 2:** Run `flutter test test/arabic_normalize_test.dart test/crops_ui_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `flutter test && flutter analyze`. Expected: all pass, no issues.
- [ ] **Step 5:** Commit `feat(app): crop list, Arabic-aware search, detail with sources`.

---

### Task 9: Admin screen (sign-in, status counts, publish)

**Files:**
- Create: `app/lib/features/admin/admin_repository.dart`, `app/lib/features/admin/admin_screen.dart`
- Test: `app/test/admin_screen_test.dart`

**Interfaces:**
- Consumes: RPCs `knowledge_status_counts()`, `publish_reviewed(p_table)` from Task 3.
- Produces:
  - `abstract class AdminRepository { Future<bool> signIn(String email, String password); Future<bool> isAdmin(); Future<List<StatusCount>> counts(); Future<int> publishReviewed(String table); }` with `SupabaseAdminRepository`.
  - `/admin` route: when `!hasBackend` shows a message that admin needs a backend (ARB `adminNeedsBackend`); otherwise sign-in form → if not admin, `adminNotAuthorized`; if admin, a table of `table × draft/reviewed/published` counts with a "نشر المراجَع / Publish reviewed" button per table, confirm dialog, then snackbar with the count.

- [ ] **Step 1: Write failing widget tests** with a fake repository: no-backend message; non-admin message; counts grid renders; publish button → confirm → `publishReviewed('crops')` called once and snackbar shows `2`.
- [ ] **Step 2:** Run `flutter test test/admin_screen_test.dart`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `flutter test && flutter analyze`. Expected: all pass.
- [ ] **Step 5:** Commit `feat(app): minimal admin publish screen`.

---

### Task 10: Seed knowledge data — sources, governorates/wilayats, 32 crops (draft)

**Files:**
- Create/fill: `data/sources.csv`, `data/governorates.csv`, `data/wilayats.csv`, `data/crops.csv`, `data/crop_requirements.csv`, `data/crop_stages.csv`
- Create: `data/SOURCES_NOTES.md` — per source: what was taken from it and which tables/pages
- Generate: `app/assets/seed/knowledge.json`

**Interfaces:**
- Consumes: validator/exporter CLIs (Tasks 4–5).
- Data rules:
  - Crops: exactly the 32 crops of spec §5.3 (ids: `tomato, cucumber, onion, potato, watermelon, garlic, cowpea, wheat_omani, alfalfa, date_palm, lime_omani, banana, pomegranate, turmeric, damask_rose, okra, eggplant, pepper, carrot, muskmelon, faba_bean, fenugreek, sorghum, rhodes_grass, mango, coconut, papaya, grape, walnut, frankincense, henna, bougainvillea`).
  - Requirements: from FAO EcoCrop (temperature/pH/texture/altitude/season), FAO-29 Ayers & Westcot 1985 Table 4 (salinity `ece_threshold`, `ece_slope`), FAO-56 Allen et al. 1998 Tables 11–12 (stage lengths, Kc). Where a crop is absent from a source, leave the field empty — never estimate.
  - Governorates: the 11 governorates; wilayats: the 63 wilayats, names AR/EN from NCSI (المركز الوطني للإحصاء والمعلومات) publications.
  - Every row `status=draft`, `source_page` filled (e.g. `Table 12, p.110`).

- [ ] **Step 1:** Fill `sources.csv` with at minimum: `fao56` (Allen et al., 1998, FAO Irrigation and Drainage Paper 56), `fao29` (Ayers & Westcot, 1985, FAO I&D Paper 29 Rev.1), `ecocrop` (FAO EcoCrop database), `ncsi_admin` (NCSI administrative divisions). Run `python -m data.validate data/`. Expected: `OK`.
- [ ] **Step 2:** Fill governorates + wilayats. Validate. Expected: `OK`; `wilayats.csv` has 63 rows, `governorates.csv` 11.
- [ ] **Step 3:** Fill `crops.csv` (32 rows). Validate. Expected: `OK`.
- [ ] **Step 4:** Fill requirements and stages from the sources above. Validate. Expected: `OK`.
- [ ] **Step 5:** Import into the test DB: `pytest data/tests/test_seed_import.py` — new test asserting `import_dir(Path('data'))` returns `crops == 32`, `wilayats == 63`, and every crop has a `crop_requirements` row (fields may be null).
- [ ] **Step 6:** Run `python -m data.export_snapshot data/ app/assets/seed/knowledge.json`; run `cd app && flutter test`. Expected: all pass.
- [ ] **Step 7:** Commit `data: draft knowledge for 32 crops, governorates and wilayats with sources`.

---

### Task 11: End-to-end check, web build, and hand-off

**Files:**
- Create: `tools/smoke_web.mjs` (Playwright script)
- Modify: `README.md` (how to view the demo; how to create the Supabase project and apply migrations: `supabase link` + `supabase db push`, then `python -m data.import_db`)

- [ ] **Step 1:** Run `cd app && flutter build web --dart-define=SHOW_DRAFTS=true`. Expected: `✓ Built build/web`.
- [ ] **Step 2:** Serve `app/build/web` on a local port and run `node tools/smoke_web.mjs`, which: opens the app, asserts the Arabic title and draft banner, searches `طماطم` and opens its detail, opens a source sheet, switches to English, and saves screenshots (deviceScaleFactor 2) to the scratchpad. Expected: exit 0.
- [ ] **Step 3:** Run the full suite: `pytest -v && (cd app && flutter test && flutter analyze)`. Expected: all pass, no analyzer issues.
- [ ] **Step 4:** Commit `chore: web smoke test and setup docs`.
- [ ] **Step 5:** With the owner's explicit go-ahead, create the private GitHub repository `oman-agri` under the owner's account and push `main`.
