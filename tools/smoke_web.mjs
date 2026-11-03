// End-to-end web smoke test. Usage:
//   node tools/smoke_web.mjs [baseUrl] [screensDir]
// Serves nothing itself: run `python3 -m http.server 8099 -d app/build/web` first
// (the app must be built with --dart-define=SHOW_DRAFTS=true).
// Picks the crop to search from the bundled snapshot, so it never hardcodes absent data.
import { createRequire } from 'node:module';
import { readFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import os from 'node:os';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const base = process.argv[2] ?? 'http://localhost:8099/';
const outDir = process.argv[3] ?? path.join(os.tmpdir(), 'oman-agri-smoke-screens');
mkdirSync(outDir, { recursive: true });

const here = path.dirname(fileURLToPath(import.meta.url));
const snap = JSON.parse(readFileSync(path.join(here, '../app/assets/seed/knowledge.json'), 'utf8'));
const crop = snap.crops.find((c) => c.id === 'tomato') ?? snap.crops[0];
const other = snap.crops.find((c) => c.id !== crop?.id);
if (!crop || !other) throw new Error('bundled snapshot needs at least 2 crops');
console.log(`Other crop (must be filtered out by search): ${other.id} (${other.name_ar})`);
console.log(`Using crop ${crop.id} (${crop.name_ar} / ${crop.name_en})`);

const T = 20000;
let failed = false;
function check(ok, msg) {
  console.log(`${ok ? 'PASS' : 'FAIL'}: ${msg}`);
  if (!ok) failed = true;
}
async function step(msg, fn) {
  try { await fn(); check(true, msg); } catch (e) { check(false, `${msg} -- ${String(e.message).split('\n')[0]}`); throw e; }
}

const browser = await chromium.launch();
const ctx = await browser.newContext({
  viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, locale: 'ar',
});
const page = await ctx.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(String(e)));
const shot = (name) => page.screenshot({ path: path.join(outDir, name) });
const text = (t) => page.getByText(t, { exact: false }).first();

try {
  await step('open app', async () => {
    await page.goto(base, { waitUntil: 'load' });
    await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: T });
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
    await page.waitForSelector('flt-semantics', { state: 'attached', timeout: T });
  });
  await step('Arabic title + draft banner', async () => {
    await text('مزارع عُمان').waitFor({ timeout: T });
    await text('مسودة — قيد المراجعة').waitFor({ timeout: T });
    await text(crop.name_ar).waitFor({ timeout: T });
  });
  await shot('home-ar.png');

  await step(`search "${crop.name_ar}" filters the list, then open detail`, async () => {
    const name = (c) => page.getByRole('button', { name: c.name_ar }); // list tiles
    await name(other).first().waitFor({ timeout: T }); // visible before searching
    await name(crop).first().waitFor({ timeout: T });
    await page.getByRole('textbox').first().click();
    await page.keyboard.type(crop.name_ar);
    await name(other).first().waitFor({ state: 'detached', timeout: T }); // filtered out
    await name(crop).first().waitFor({ timeout: T }); // still there
    await shot('search.png');
    await name(crop).first().click();
    // go_router push() does not update the web URL, so prove navigation by content:
    // the list's search field is gone and a detail-only section title is shown.
    await page.getByRole('textbox').first().waitFor({ state: 'detached', timeout: T });
    await text('متطلبات المحصول').waitFor({ timeout: T }); // detail-only section title
    if (crop.scientific_name) await text(crop.scientific_name).waitFor({ timeout: T });
  });
  await shot('detail.png');

  await step('open source sheet', async () => {
    await page.getByRole('button', { name: 'المصدر' }).first().click();
    await text('الناشر').waitFor({ timeout: T });
  });
  await shot('source-sheet.png');

  await step('switch to English', async () => {
    await page.keyboard.press('Escape');
    await text('الناشر').waitFor({ state: 'hidden', timeout: T });
    await page.evaluate(() => { location.hash = '#/settings'; });
    await page.waitForFunction(() => location.hash.endsWith('/settings'), null, { timeout: T });
    await page.getByRole('radio', { name: 'English' }).click();
    await text('Language').waitFor({ timeout: T });
    await page.evaluate(() => { location.hash = '#/'; });
    await text('Draft — under review').waitFor({ timeout: T });
    await text(crop.name_en).waitFor({ timeout: T });
  });
  await shot('home-en.png');
} catch (e) {
  failed = true;
  await shot('failure.png').catch(() => {});
} finally {
  await browser.close();
}
if (errors.length) {
  failed = true;
  console.log('FAIL: uncaught page errors:', errors.slice(0, 3));
}
console.log(failed ? 'SMOKE FAILED' : 'SMOKE OK');
process.exit(failed ? 1 : 0);
