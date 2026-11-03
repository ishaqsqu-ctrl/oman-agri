# مزارع عُمان (Oman Farmer)

## العربية

### ما هو هذا المشروع؟
«مزارع عُمان» تطبيق مجاني بالعربية والإنجليزية يساعد المزارع في عُمان: يعرض له المحاصيل المناسبة لأرضه وموسمها، وتقويماً زراعياً، وتنبيهات الطقس، ومحلات المستلزمات الزراعية القريبة. كل معلومة زراعية في التطبيق لها **مصدر** موثّق، ولا تظهر للمستخدم إلا بعد أن **تُراجَع وتُعتمد**.

### خريطة المجلدات
```
oman-agri/
├── app/         تطبيق Flutter (أندرويد / آيفون / ويب / كمبيوتر)
├── supabase/    قاعدة البيانات: migrations/ (موجود الآن)؛ functions/ وseed/ في مراحل لاحقة
├── data/        سكربتات التحقق والاستيراد والتصدير؛ جداول المعرفة (CSV) تصل في المهمة ١٠، و data/demo/ عيّنة تجريبية مؤقتة
├── pipeline/    (مرحلة لاحقة) خط معالجة Python لطبقات البيئة ونموذج الملاءمة
├── tools/       سكربتات مساعدة (مثل إعداد البيئة)
└── docs/        التوثيق والتصميم
```

### التشغيل
1. **إعداد البيئة** (مرة واحدة، ويمكن إعادته بأمان):
   ```
   bash tools/setup_env.sh
   ```
   يثبّت Flutter 3.47.9 وقاعدة PostgreSQL 16 مع PostGIS وأدوات Python. ثم أضف هذا السطر إلى ملف إعدادات الطرفية:
   ```
   export PATH="/usr/lib/postgresql/16/bin:$HOME/flutter/bin:$PATH"
   ```
2. **الاختبارات:** اختبارات Python: `pytest`  — اختبارات التطبيق: `cd app && flutter test`
3. **تشغيل التطبيق:** `cd app && flutter run -d chrome` (للويب). لعرض البيانات غير المعتمدة أثناء التطوير: `flutter run --dart-define=SHOW_DRAFTS=true` — سيظهر شريط دائم «مسودة — قيد المراجعة».

### مراجعة البيانات الزراعية ونشرها (دورك كصاحب المشروع)
**ملفات CSV هي المرجع الوحيد للبيانات ولحالتها.** ما تكتبه فيها هو ما يصل إلى قاعدة البيانات وإلى التطبيق.

ستة ملفات: `sources.csv` و`governorates.csv` و`wilayats.csv` و`crops.csv` و`crop_requirements.csv` و`crop_stages.csv`. تصل الملفات الحقيقية إلى `data/` في **المهمة ١٠**؛ وحتى ذلك الحين توجد عيّنة تجريبية في `data/demo/` (استبدل `data/` بـ `data/demo/` في الأوامر أدناه لتجربتها).

**الخطوات:**
1. افتح ملف CSV في Excel، وصحّح القيم، وتأكد من المصدر (`source_id`) ورقم الصفحة (`source_page`) لكل صف. لا تُكتب أي قيمة بدون مصدر.
2. للصف الذي راجعته: اكتب اسمك في `reviewed_by` والتاريخ في `reviewed_at` (بصيغة `2026-11-03`)، واجعل `status`:
   - `reviewed` = راجعته ولم يُنشر بعد؛
   - `published` = **انشره** ليراه المزارعون؛
   - `draft` = مسودة، أو لإخفاء صف كان منشوراً.
3. احفظ الملف بصيغة **CSV UTF-8 (Comma delimited)** — وليس «CSV» العادي ولا بفاصلة منقوطة.
4. نفّذ الأوامر الثلاثة بالترتيب من مجلد المشروع:
   ```
   python3 -m data.validate data/
   python3 -m data.import_db data/ --dsn "$DATABASE_URL"
   python3 -m data.export_snapshot data/
   ```
   - **التحقق**: يطبع «OK» أو قائمة أخطاء بالعربية والإنجليزية (اسم الملف ورقم الصف والعمود). صحّح الأخطاء وأعد التحقق حتى يظهر «OK».
   - **الاستيراد**: يرفع البيانات إلى قاعدة بيانات Supabase (`DATABASE_URL` هو رابط قاعدة البيانات، انظر قسم Supabase أدناه).
   - **التصدير**: يكتب نسخة البيانات المضمّنة في التطبيق `app/assets/seed/knowledge.json` (تُستعمل عند أول تشغيل دون إنترنت).

**ملاحظات مهمة:**
- **حذف صف من CSV لا يحذفه من قاعدة البيانات.** لإخفاء صف اجعل حالته `draft` ثم أعد الاستيراد.
- زر «نشر المراجَع» في لوحة المدير داخل التطبيق اختصار يغيّر الحالة في قاعدة البيانات فقط؛ **يجب أن تكتب `published` في ملف CSV أيضاً** ليبقى الملف هو المرجع. (الاستيراد لا يُرجع صفاً منشوراً إلى `reviewed`، لكن كتابة `draft` في CSV تلغي نشره.)

### ملاحظة تقنية: التخزين دون إنترنت
في هذه المرحلة يُحفظ نسخة البيانات للعمل دون إنترنت كـ **لقطة JSON** (ملف على الأجهزة، و`shared_preferences` على الويب) بدلاً من Drift/SQLite المذكور في التصميم. هذا انحراف مقصود ومحدود؛ يصل Drift في المرحلة 4 مع بيانات المزرعة.

### عرض النسخة التجريبية (ويب)
```
cd app
flutter build web --dart-define=SHOW_DRAFTS=true --no-web-resources-cdn
cd ..
python3 -m http.server 8099 -d app/build/web
```
ثم افتح `http://localhost:8099` في المتصفح. لإيقاف الخادم اضغط Ctrl+C (أو شغّله في الخلفية بـ `&` وأوقفه بـ `kill %1`). الخيار `--no-web-resources-cdn` يضمّن محرك الرسم مع التطبيق فيعمل دون الاتصال بخوادم Google. لاختبار آلي سريع للواجهة (يلزم توفّر Playwright مع Chromium، والخادم يعمل): `node tools/smoke_web.mjs http://localhost:8099/ /tmp/screens` (المسار الثاني اختياري، وافتراضيه مجلد مؤقت خارج المشروع) — يفتح التطبيق ويبحث عن «طماطم» ويفتح المصدر ويبدّل اللغة ويحفظ لقطات الشاشة.

### إنشاء مشروع Supabase وتطبيق قاعدة البيانات
1. أنشئ مشروعاً جديداً من لوحة Supabase (supabase.com) واحفظ كلمة مرور قاعدة البيانات.
2. ثبّت أداة Supabase CLI (مرة واحدة) حسب الشرح في https://supabase.com/docs/guides/cli — مثلاً على macOS: `brew install supabase/tap/supabase`، أو استعملها دون تثبيت عبر `npx supabase ...` إذا كان Node.js مثبتاً.
3. من مجلد المشروع: `supabase login` ثم `supabase link --project-ref <معرّف المشروع>` ثم `supabase db push` لتطبيق ملفات `supabase/migrations/`.
4. ضع رابط قاعدة البيانات في المتغير `DATABASE_URL`:
   `export DATABASE_URL="postgresql://postgres:<كلمة المرور>@db.<معرّف المشروع>.supabase.co:5432/postgres"`
   ثم استورد المعرفة الزراعية بالأوامر الثلاثة في قسم «مراجعة البيانات» أعلاه.
5. لتشغيل التطبيق على Supabase: `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

### تعيين مشرف (admin)
سجّل الدخول مرة واحدة بحسابك أولاً، ثم في محرر SQL داخل Supabase نفّذ:
```
update public.profiles set role = 'admin' where id = '<معرّف المستخدم UUID>';
```
تجد المعرّف في Authentication ← Users.

### حالة البيانات
بيانات المحاصيل الحقيقية (٣٢ محصولاً) تصل في **المهمة ١٠**. حالياً يحتوي التطبيق على **عيّنة تجريبية غير حقيقية** من `data/demo/` (الطماطم والليمون العماني): مصدرها الوحيد «بيانات تجريبية — ليست حقيقية»، وكل صفوفها بحالة `draft`، وأرقامها للعرض فقط ولا يجوز الاعتماد عليها. لذلك لا تظهر إلا في نسخة مبنية بـ `SHOW_DRAFTS=true` مع شريط «مسودة — قيد المراجعة».

---

## English

### What is this?
Oman Farmer is a free bilingual (Arabic/English) app for farmers in Oman: crop suitability for their land and season, a farming calendar, weather alerts, and nearby agri-input shops. Every agronomic fact carries a documented **source** and is shown only after it has been **reviewed and published**. Arabic is the default locale (RTL); English is fully supported.

Stack: Flutter + Supabase (Postgres/PostGIS, RLS) + Python data tools.

### Folder map
```
oman-agri/
├── app/         Flutter app (Android / iOS / web / desktop)
├── supabase/    migrations/ (now); functions/ (Edge Functions) and seed/ in later phases
├── data/        validate/import/export scripts; knowledge CSVs arrive with Task 10, data/demo/ holds a temporary sample set
├── pipeline/    (later phase) Python pipeline for environmental layers and suitability model
├── tools/       helper scripts (environment setup)
└── docs/        documentation and design spec
```

### Running
1. **Set up the environment** (idempotent):
   ```
   bash tools/setup_env.sh
   export PATH="/usr/lib/postgresql/16/bin:$HOME/flutter/bin:$PATH"
   ```
   Installs Flutter 3.47.9 to `~/flutter`, `postgresql-16-postgis-3`, and the Python dev requirements (`pytest`, `psycopg[binary]>=3.2`). The script uses `pip --break-system-packages` (PEP 668) because the container is disposable.
2. **Tests:** Python: `pytest` — app: `cd app && flutter test`
3. **Run the app:** `cd app && flutter run -d chrome`. To see unpublished data in development use `--dart-define=SHOW_DRAFTS=true`; a persistent "Draft — under review" banner is shown.

### Data review and publishing workflow
**The CSV files are the single source of truth for the data and its `status`.**

Six files: `sources.csv`, `governorates.csv`, `wilayats.csv`, `crops.csv`, `crop_requirements.csv`, `crop_stages.csv`. The real files arrive in `data/` with **Task 10**; until then a demo set lives in `data/demo/` (use `data/demo/` instead of `data/` below to try it).

1. Open the CSV in Excel, correct values, and verify `source_id` and `source_page` for every row. No value without a source.
2. For each row you reviewed fill `reviewed_by` and `reviewed_at` (`2026-11-03`) and set `status`: `reviewed` (checked, not yet public), `published` (**publish** it to farmers) or `draft` (draft, or hide a previously published row).
3. Save as **CSV UTF-8 (Comma delimited)** — not plain "CSV" and not semicolon-delimited.
4. Run the three commands, in order, from the repo root:
   ```
   python3 -m data.validate data/
   python3 -m data.import_db data/ --dsn "$DATABASE_URL"
   python3 -m data.export_snapshot data/
   ```
   Validate prints `OK` or bilingual issues (file:row:column) — fix and re-run until `OK`. Import upserts into the Supabase database. Export rewrites the bundled offline snapshot `app/assets/seed/knowledge.json`.

Notes:
- The importer is upsert-only: **deleting a CSV row does not delete it from the database.** Set its `status` to `draft` to hide it.
- The admin panel's "Publish reviewed" button is a DB-side shortcut; **mirror it in the CSV** (`status=published`). Re-importing never downgrades a published row to `reviewed`, but a CSV `draft` does unpublish it.

### Deliberate deviation: offline cache
In phase 1 the offline cache is a **JSON snapshot** (a file on native platforms, `shared_preferences` on web) instead of the Drift/SQLite store named in design spec §4. This is a deliberate, scoped deviation; Drift arrives in phase 4 together with farm data.

### Viewing the demo (web)
```
cd app
flutter build web --dart-define=SHOW_DRAFTS=true --no-web-resources-cdn
cd ..
python3 -m http.server 8099 -d app/build/web
```
Then open `http://localhost:8099`. Stop the server with Ctrl+C (or start it in the background with `&` and stop it with `kill %1`). `--no-web-resources-cdn` bundles the CanvasKit renderer so the build works without reaching Google's CDN. For an automated UI check (needs Playwright with Chromium available, and the server running): `node tools/smoke_web.mjs http://localhost:8099/ /tmp/screens` (the second argument is optional; the default is a temp dir outside the repo) — it opens the app, searches Arabic "tomato", opens a source sheet, switches to English and saves screenshots.

### Creating the Supabase project and applying the schema
1. Create a new project in the Supabase dashboard and keep the database password.
2. Install the Supabase CLI once (see https://supabase.com/docs/guides/cli — e.g. `brew install supabase/tap/supabase` on macOS, or run it without installing via `npx supabase ...` when Node.js is available).
3. From the repo root: `supabase login`, `supabase link --project-ref <project-ref>`, then `supabase db push` to apply `supabase/migrations/`.
4. `export DATABASE_URL="postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"`, then load the knowledge data with the three commands in the data workflow above.
5. Run the app against Supabase: `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

### Making a user an admin
Sign in once with your account first, then run in the Supabase SQL editor:
```
update public.profiles set role = 'admin' where id = '<user uuid>';
```
Find the id under Authentication → Users.

### Data status
The real crop data (32 crops) arrives in **Task 10**. For now the bundled snapshot is built from `data/demo/` — **sample data that is not real** (tomato, Omani lime) under a single source titled "SAMPLE DATA — not real", every row `draft`, values for display only. It is visible only in a `SHOW_DRAFTS=true` build, under the "Draft — under review" banner.
