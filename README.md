# مزارع عُمان (Oman Farmer)

## العربية

### ما هو هذا المشروع؟
«مزارع عُمان» تطبيق مجاني بالعربية والإنجليزية يساعد المزارع في عُمان: يعرض له المحاصيل المناسبة لأرضه وموسمها، وتقويماً زراعياً، وتنبيهات الطقس، ومحلات المستلزمات الزراعية القريبة. كل معلومة زراعية في التطبيق لها **مصدر** موثّق، ولا تظهر للمستخدم إلا بعد أن **تُراجَع وتُعتمد**.

### خريطة المجلدات
```
oman-agri/
├── app/         تطبيق Flutter (أندرويد / آيفون / ويب / كمبيوتر)
├── supabase/    قاعدة البيانات (migrations) ووظائف الخادم (functions) وبيانات البداية (seed)
├── data/        جداول المعرفة الزراعية (CSV) + سكربت التحقق والاستيراد
├── pipeline/    خط معالجة Python لطبقات البيئة ونموذج الملاءمة
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

(المجلدات `app/` و`data/` وغيرها تُضاف تدريجياً في مهام المرحلة الأولى.)

### مراجعة البيانات الزراعية (دورك كصاحب المشروع)
1. افتح ملف CSV المناسب من مجلد `data/` في Excel.
2. صحّح القيم، وتأكد من المصدر ورقم الصفحة لكل صف.
3. للصف الذي راجعته: غيّر `status` إلى `reviewed`، واكتب اسمك في `reviewed_by` والتاريخ في `reviewed_at`.
4. احفظ الملف (UTF-8) — ثم يقوم المشرف (admin) بـ**النشر** (`published`)، وعندها فقط تظهر المعلومة للمزارعين.

لا تُكتب أي قيمة بدون مصدر؛ كل بيانات البداية تبدأ بحالة `draft`.

### ملاحظة تقنية: التخزين دون إنترنت
في هذه المرحلة يُحفظ نسخة البيانات للعمل دون إنترنت كـ **لقطة JSON** (ملف على الأجهزة، و`shared_preferences` على الويب) بدلاً من Drift/SQLite المذكور في التصميم. هذا انحراف مقصود ومحدود؛ يصل Drift في المرحلة 4 مع بيانات المزرعة.

### عرض النسخة التجريبية (ويب)
```
cd app
flutter build web --dart-define=SHOW_DRAFTS=true --no-web-resources-cdn
cd ..
python3 -m http.server 8099 -d app/build/web
```
ثم افتح `http://localhost:8099` في المتصفح. الخيار `--no-web-resources-cdn` يضمّن محرك الرسم مع التطبيق فيعمل دون الاتصال بخوادم Google. لاختبار آلي سريع للواجهة (بعد التشغيل أعلاه): `node tools/smoke_web.mjs http://localhost:8099/ ./screens` — يفتح التطبيق ويبحث عن «طماطم» ويفتح المصدر ويبدّل اللغة ويحفظ لقطات الشاشة.

### إنشاء مشروع Supabase وتطبيق قاعدة البيانات
1. أنشئ مشروعاً جديداً من لوحة Supabase (supabase.com) واحفظ كلمة مرور قاعدة البيانات.
2. من مجلد المشروع: `supabase link --project-ref <معرّف المشروع>` ثم `supabase db push` لتطبيق ملفات `supabase/migrations/`.
3. استورد المعرفة الزراعية (بعد اجتياز التحقق): `python -m data.import_db data/ --dsn "postgresql://postgres:<كلمة المرور>@db.<معرّف المشروع>.supabase.co:5432/postgres"` (أو ضع الرابط في المتغير `DATABASE_URL`).
4. لتشغيل التطبيق على Supabase: `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

### تعيين مشرف (admin)
سجّل الدخول مرة واحدة بحسابك أولاً، ثم في محرر SQL داخل Supabase نفّذ:
```
update public.profiles set role = 'admin' where id = '<معرّف المستخدم UUID>';
```
تجد المعرّف في Authentication ← Users.

### حالة البيانات
بيانات المحاصيل الحقيقية (٣٢ محصولاً) تصل في **المهمة ١٠**. حالياً يحتوي التطبيق على عيّنة صغيرة (الطماطم والليمون العماني) بحالة `draft` لأغراض العرض فقط؛ لذلك يلزم `SHOW_DRAFTS=true` لرؤيتها.

---

## English

### What is this?
Oman Farmer is a free bilingual (Arabic/English) app for farmers in Oman: crop suitability for their land and season, a farming calendar, weather alerts, and nearby agri-input shops. Every agronomic fact carries a documented **source** and is shown only after it has been **reviewed and published**. Arabic is the default locale (RTL); English is fully supported.

Stack: Flutter + Supabase (Postgres/PostGIS, RLS) + Python data tools.

### Folder map
```
oman-agri/
├── app/         Flutter app (Android / iOS / web / desktop)
├── supabase/    migrations/, functions/ (Edge Functions), seed/
├── data/        agronomic knowledge CSVs + validate/import script
├── pipeline/    Python pipeline for environmental layers and suitability model
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

(`app/`, `data/` etc. are added incrementally by later phase-1 tasks.)

### Data review workflow
1. Open the relevant CSV in `data/` with Excel.
2. Correct values; verify the source and page for each row.
3. For each reviewed row set `status=reviewed`, fill `reviewed_by` and `reviewed_at`.
4. Save as UTF-8. An admin then publishes (`status=published`, which requires `reviewed_by`/`reviewed_at`); only published rows are visible to users.

No value may be entered without a source; all seed rows ship as `draft`.

### Deliberate deviation: offline cache
In phase 1 the offline cache is a **JSON snapshot** (a file on native platforms, `shared_preferences` on web) instead of the Drift/SQLite store named in design spec §4. This is a deliberate, scoped deviation; Drift arrives in phase 4 together with farm data.

### Viewing the demo (web)
```
cd app
flutter build web --dart-define=SHOW_DRAFTS=true --no-web-resources-cdn
cd ..
python3 -m http.server 8099 -d app/build/web
```
Then open `http://localhost:8099`. `--no-web-resources-cdn` bundles the CanvasKit renderer so the build works without reaching Google's CDN. For an automated UI check (with the server above running): `node tools/smoke_web.mjs http://localhost:8099/ ./screens` — it opens the app, searches Arabic "tomato", opens a source sheet, switches to English and saves screenshots.

### Creating the Supabase project and applying the schema
1. Create a new project in the Supabase dashboard and keep the database password.
2. From the repo root: `supabase link --project-ref <project-ref>` then `supabase db push` to apply `supabase/migrations/`.
3. Import the knowledge data (it must pass validation): `python -m data.import_db data/ --dsn "postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres"` (or set `DATABASE_URL`).
4. Run the app against Supabase: `flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

### Making a user an admin
Sign in once with your account first, then run in the Supabase SQL editor:
```
update public.profiles set role = 'admin' where id = '<user uuid>';
```
Find the id under Authentication → Users.

### Data status
The real crop data (32 crops) arrives in **Task 10**. For now the bundled snapshot is a small fixture (tomato, Omani lime), all `draft`, for demo only — hence `SHOW_DRAFTS=true`.
