// End-to-end web smoke test. Usage:
//   node tools/smoke_web.mjs [baseUrl] [screensDir]
// Serves nothing itself: run `python3 -m http.server 8099 -d app/build/web` first
// (the app must be built with --dart-define=SHOW_DRAFTS=true).
// Picks the crop to search from the bundled snapshot, so it never hardcodes absent data.
import { createRequire } from 'node:module';
import { readFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const base = process.argv[2] ?? 'http://localhost:8099/';
const outDir = process.argv[3] ?? 'screens';
mkdirSync(outDir, { recursive: true });

const here = path.dirname(fileURLToPath(import.meta.url));
const snap = JSON.parse(readFileSync(path.join(here, '../app/assets/seed/knowledge.json'), 'utf8'));
const crop = snap.crops.find((c) => c.id === 'tomato') ?? snap.crops[0];
if (!crop) throw new Error('bundled snapshot has no crops');
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

  await step(`search "${crop.name_ar}" and open detail`, async () => {
    const field = page.getByRole('textbox').first();
    await field.click();
    await page.keyboard.type(crop.name_ar);
    await text(crop.name_ar).waitFor({ timeout: T });
    await page.waitForTimeout(500);
    await shot('search.png');
    await text(crop.name_ar).click();
    if (crop.scientific_name) await text(crop.scientific_name).waitFor({ timeout: T });
    await page.waitForTimeout(500);
  });
  await shot('detail.png');

  await step('open source sheet', async () => {
    await page.getByRole('button', { name: 'المصدر' }).first().click();
    await text('الناشر').waitFor({ timeout: T });
  });
  await shot('source-sheet.png');

  await step('switch to English', async () => {
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
    await page.evaluate(() => { location.hash = '#/settings'; });
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
}
if (errors.length) console.log('page errors:', errors.slice(0, 3));
await browser.close();
console.log(failed ? 'SMOKE FAILED' : 'SMOKE OK');
process.exit(failed ? 1 : 0);
