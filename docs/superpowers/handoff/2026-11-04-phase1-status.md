# Phase 1 handoff — status as of 2026-11-04

Branch: phase1-foundation (do NOT merge to main until Task 10 is done — owner chose option A).

## Status
- **Update 2026-11-04 (later):** Task 10 data transcribed and owner-reviewed; schema migrations applied to Supabase project `zljqdydelxuzrunipwwg` (recorded in supabase_migrations.schema_migrations) and the reviewed seed loaded. Remaining: owner presses "Publish reviewed"; then merge phase1-foundation into main.
- Tasks 1–9 and 11 of docs/superpowers/plans/2026-11-03-phase1-foundation.md: complete, each task-reviewed; final whole-branch review done and its fix wave applied and re-reviewed.
- Task 10 (seed data: sources, 11 governorates, 63 wilayats, 32 crops + requirements + stages, all draft): NOT started — blocked because the session network policy denied fao.org, openknowledge.fao.org, gaez.fao.org, ncsi.gov.om, mafwr.gov.om. Owner has since allowed these domains; a NEW session is required for them to take effect.
- Values must be transcribed from the sources (FAO-56 Tables 11–12, FAO-29 Table 4, FAO EcoCrop, NCSI), never from memory; leave a field empty if the source lacks it.
- After Task 10: run final checks, then merge phase1-foundation into main.

## Tests at handoff
pytest 120 passed; flutter test 57 passed; flutter analyze clean; web smoke OK.

## Controller ledger (rulings, deferred minors)

```
# SDD ledger — plan: docs/superpowers/plans/2026-11-03-phase1-foundation.md
Branch: phase1-foundation (from main 1ddf2a7)

## Pre-flight scan
| Pair / task | Produces vs consumes | Finding |
|---|---|---|
| T2→T3 | tables, as_role fixture → RLS tests | consistent |
| T2→T5 | db fixture (supabase/tests/conftest.py) → data tests via root conftest | consistent; root conftest must import fixtures (pytest_plugins) |
| T4→T5 | validate_dir/read_rows → importer | consistent |
| T5→T7 | snapshot JSON shape → models | consistent (schema_version 1, nested requirements/stages) |
| T5→T10 | exporter CLI → knowledge.json | consistent |
| T6→T8 | router home tab → crops list | T6 home tab needs placeholder until T8; ok |
| T7→T8 | knowledgeProvider, Crop, showDrafts | consistent |
| T3→T9 | knowledge_status_counts, publish_reviewed | consistent |
| T6 self | tests vs code | consistent |
| T7 self | Supabase source selects "5 tables" but snapshot also needs governorates/wilayats → 6 tables | minor; ruling below |
| T10 self | Step 5 creates test_seed_import.py not listed in Files | minor |
| T11 self | Step 5 push requires GitHub; auto-mode blocked gh repo create | external |

Ruling: T7 Supabase source loads all 6 knowledge tables (sources, governorates, wilayats, crops, crop_requirements, crop_stages) — snapshot shape requires them — cost if wrong: trivial.
Ruling: T10 adds data/tests/test_seed_import.py to its Files — plan step names it — cost: none.
Ruling: T11 step 5 (GitHub push) deferred to owner action; repo creation denied by permission classifier — cost: work lives only in container until owner creates repo.
Ruling: .superpowers/ excluded via .git/info/exclude, not .gitignore — keeps T1's .gitignore scope clean — cost: none.

## Progress
Task 1: minor (deferred): setup_env.sh final flutter check lacks clear error msg; version parse relies on flutter.version.json; .env.* would ignore .env.example
Task 1: complete (commits 1ddf2a7..6be5844, review clean)
Ruling: Task 2 adds `committed_db` fixture (fresh DB from migrated template per test) for code that commits; `db` stays rollback-isolated — importer CLI must commit — cost if wrong: slower tests only.
Task 2: minor (deferred): as_role sets legacy request.jwt.claim.sub only (newer Supabase uses request.jwt.claims JSON) — matters only for real-Supabase parity tests
Task 2: fix round 1 dispatched (as_role savepoint; committed_db fixture; tempdir leak; revoke execute)
Task 2: fix round 1/5 (4 addressed, 0 open; commits 6d5255d..67b4274)
Task 2: minor (deferred): no test for exception propagating out of as_role block; migration edited in place (ok pre-release)
Task 2: complete (commits 6be5844..67b4274, review clean)
Task 3: fix round 1 dispatched (CRITICAL self-promotion under Supabase default privileges; admin profiles all; revokes; select-wrapped is_admin)
Ruling: commits from 1328c80 on use repo-local identity Claude <noreply@anthropic.com> (stop hook requires verified committer); earlier pushed commits left as-is (rewriting pushed history not worth it) — cost: mixed authorship in history
Task 3: fix round 1/5 (6 addressed, 0 open; commits 5b3931d..1328c80)
Task 3: minor (deferred): profile role guard allow-lists anon/authenticated (fail-open for future API roles); revoke TRUNCATE from anon/authenticated as hardening
Task 3: complete (commits 67b4274..1328c80, review clean)
Ruling: months 1..12 validator rule deferred — no month columns exist in phase-1 schema (they arrive with suitability/calendar tables) — cost: none now
Ruling: CSV numeric parsing accepts Arabic-Indic/Extended digits and ٫ (normalized to ASCII) but is otherwise strict; shared parse_int/parse_num module reused by Task 5 importer — owner types on Arabic keyboard — cost if wrong: small rework of parser.
Task 4: fix round 1 dispatched (strict numeric parse, int widths, UTF-8 decode issue, invisible chars, dup headers)
Task 4: fix round 1/5 (4 addressed, 0 open; commits b14a096..f4638cc)
Task 4: minor (deferred): empty header cells produce noisy duplicate/unknown-column issues; duplicated unusable.add; INT_RANGES placement
Task 4: complete (commits 1328c80..f4638cc, review clean)
Task 5: minor (deferred): reviewed_at date cast at session TZ (UTC) vs Asia/Muscat; importer is upsert-only (rows removed from CSV persist in DB, esp. stale crop_stages) — document/--prune later; typed.py r.get default hides missing column
Ruling: snapshot JSON numerics may be int or float by value; Dart models must parse numerics with (x as num).toDouble() (carried into Task 7) — cost if wrong: TypeError on integral values
Task 5: complete (commits f4638cc..e971e2d, review clean)
Task 6: minor (deferred): _rootKey global GlobalKey shared across buildRouter calls; language picker not endonyms (english label); Kufi font lacks Latin glyphs (add fallback); locale prefs write failure unhandled; no assertion on stored 'locale' value
Task 6: complete (commits e971e2d..2b4d0b5, review clean)
Ruling: on network failure, repository loads Cached and Bundled and returns the later generatedAt (tie → cache); Supabase snapshots stamped with fetch time — keeps offline users current after app updates — cost if wrong: one extra asset parse per offline launch
Ruling: a crop's stages are shown only if all its stages are published — partial Kc curve would misstate water needs — cost: stages hidden until fully reviewed
Task 7: fix round 1 dispatched (timeout, cache vs bundle freshness, empty-network cache guard, all-or-nothing stages, pure assembly fn)
Task 7: fix round 1/5 (6 addressed, 0 open; commits 3ce1259..5c58c00)
Task 7: minor (deferred): placeholder seed is all-draft; Supabase source untested against live server; network sources always tried before local regardless of chain order
Task 7: complete (commits 2b4d0b5..5c58c00, review clean)
Task 8: minor (deferred): subtitle alignment flips side; unknown crop id lacks "not found" message; launchUrl not awaited/no http(s) allow-list (prefer fixing in final wave); English locale headline shows Arabic name first; unused ARB keys categories/close; Arabic comma used in English texture list; detail error has no retry
Task 8: complete (commits 5c58c00..6d31d63, review clean)
Task 9: minor (deferred): Arabic publishedRows lacks plural grammar; sign-in network vs auth errors not distinguished; counts-load failure shows zeros without retry; resume/signIn-error/counts-failure untested; autofillHints without AutofillGroup; unused tableLabel key
Task 9: complete (commits 6d31d63..c94b243, review clean)
Ruling: Task 10 (seed data) BLOCKED — network policy denies fao.org, gaez.fao.org, openknowledge.fao.org, ncsi.gov.om, mafwr.gov.om; values must be transcribed from sources, not memory — owner must allow domains; Task 11 runs first on fixture snapshot — cost: demo shows sample data, not 32 crops, until Task 10 runs
Task 11: fix round 1 dispatched (non-vacuous search/detail assertions, condition waits, pageerror fail, screens dir, README server notes)
Task 11: fix round 1/5 (3 addressed, 0 open; commits 5991090..30b3a63)
Task 11: minor (deferred): go_router push() doesn't update web URL (no deep link/refresh for detail); README `kill %1` needs job control; name() substring matching
Task 11: complete (commits c94b243..30b3a63, review clean)
Task 10: BLOCKED (network) — not dispatched
Final review: With fixes — 8 Important (F1 status source of truth/importer unpublish; F2 fabricated-looking fixture shipped; Excel trailing columns; README workflow; Android INTERNET; URL scheme; "ال" search; crop-level SourceButton)
Ruling: F1 — CSV is single source of truth for status; importer never downgrades published→reviewed; CSV draft unpublishes; upsert-only documented — cost if wrong: owner must mirror admin-panel publishes in CSV
Ruling: F2 — ship clearly-labelled demo data (data/demo, source "SAMPLE DATA — not real", all draft); test fixtures relabelled — cost: none
Ruling: deferred to later phases — cache-first background refresh; SHOW_DRAFTS vs live backend; stage-order validation; supabase/ package name shadowing; all other "can wait" ledger minors
Final fix wave dispatched (one fixer)
Final fix wave: re-review — all findings addressed (commits 30b3a63..a3140bb)
Final: parked — source_button maybePop after await may pop detail route if sheet dismissed mid-launch — Ruling: rare, minor, fix in next phase — cost: wrong route popped in an edge case
Final: parked — admin invalidate after await without mounted check — Ruling: caught and reported, minor — cost: misleading "operation failed" snackbar edge case
Ruling: keep SDD workspace (not deleted) — Task 10 still pending — cost: none
```
