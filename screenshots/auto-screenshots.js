const { chromium } = require('@playwright/test');
const path = require('path');
const fs = require('fs');

const SCREENSHOTS_DIR = path.join(__dirname, 'output');
if (!fs.existsSync(SCREENSHOTS_DIR)) fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });

async function shot(page, filename, description) {
  const filepath = path.join(SCREENSHOTS_DIR, filename);
  await page.screenshot({ path: filepath, fullPage: false });
  console.log(`✅ ${filename} — ${description}`);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1400, height: 900 } });
  const page = await context.newPage();

  // ─── GITHUB ACTIONS — liste des runs ──────────────────────────
  console.log('\n🐙 GitHub Actions — runs...');
  await page.goto('https://github.com/Ibrah-Ibrah/tp07-devsecops/actions');
  await page.waitForTimeout(4000);
  await shot(page, '06_pipeline_liste_run.png', 'GitHub Actions — liste des runs');

  // ─── GITHUB ACTIONS — dernier run détaillé ────────────────────
  console.log('\n🐙 GitHub Actions — dernier run...');
  const firstRun = page.locator('a[href*="/runs/"]').first();
  const hasRun = await firstRun.isVisible({ timeout: 3000 }).catch(() => false);
  if (hasRun) {
    await firstRun.click();
    await page.waitForTimeout(4000);
    await shot(page, '06b_pipeline_run_detail.png', 'GitHub Actions — run détaillé');
  }

  // ─── PROMETHEUS targets ────────────────────────────────────────
  console.log('\n📊 Prometheus targets...');
  await page.goto('http://localhost:9090/targets');
  await page.waitForTimeout(3000);
  await shot(page, '15_prometheus_targets.png', 'Prometheus — targets actives');

  // ─── PROMETHEUS query CIS ──────────────────────────────────────
  console.log('\n📊 Prometheus query CIS...');
  await page.goto('http://localhost:9090/graph?g0.expr=cis_controls_applied_total&g0.tab=1');
  await page.waitForTimeout(3000);
  await shot(page, '15b_prometheus_query_cis.png', 'Prometheus — CIS controls');

  // ─── PUSHGATEWAY ──────────────────────────────────────────────
  console.log('\n📤 Pushgateway...');
  await page.goto('http://localhost:9091');
  await page.waitForTimeout(2000);
  await shot(page, '16_pushgateway_metrics.png', 'Pushgateway métriques pushées');

  // ─── GRAFANA ──────────────────────────────────────────────────
  console.log('\n📈 Grafana login...');
  await page.goto('http://localhost:3000/login');
  await page.waitForTimeout(2500);
  await page.fill('input[name="user"]', 'admin');
  await page.fill('input[name="password"]', 'tp07devsecops');
  await page.click('button[type="submit"]');
  await page.waitForTimeout(3000);

  const skipButton = page.locator('button:has-text("Skip")');
  if (await skipButton.isVisible({ timeout: 2000 }).catch(() => false)) {
    await skipButton.click();
    await page.waitForTimeout(1000);
  }

  await shot(page, '17a_grafana_home.png', 'Grafana home connecté');

  await page.goto('http://localhost:3000/dashboards');
  await page.waitForTimeout(2500);
  await shot(page, '17b_grafana_dashboards_liste.png', 'Grafana dashboards');

  await page.goto('http://localhost:3000/d/tp07-devsecops/tp07-e28094-devsecops-pipeline?kiosk=tv&refresh=5s');
  await page.waitForTimeout(8000);
  await shot(page, '17_grafana_dashboard.png', 'Dashboard TP07 DevSecOps');

  await browser.close();
  console.log('\n🎉 Screenshots terminés !');
})();
