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
