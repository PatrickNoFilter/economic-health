# Economic Health — Android app (source)

Real-time economic dashboard (IHSG, USD/IDR, EUR/IDR, gold Rp/gram, gold/silver,
WTI/Brent, BTC/ETH, S&P 500, Nasdaq 100, Nikkei 225, Hang Seng, STI) with
stock-board style animated numbers. Data: Yahoo Finance v8 chart API (no key).

## Layout
- `www/index.html` ......... the app (single file — edit this, then rebuild)
- `android/` ............... WebView wrapper (package `com.patricknofilter.economichealth`)
- `build.sh` ............... APK builder (manual aapt2 pipeline, no Gradle)
- `keystore/eh.keystore` ... signing key — KEEP, reuse for every update
- `out/EconomicHealth-v1.apk`  built APK

## Rebuild on this machine (the VM)
```bash
bash ~/workspace/economic-health/build.sh
# output: out/EconomicHealth-v1.apk
```
Needs: Android SDK at `~/workspace/android-sdk`, JDK at `~/workspace/jdk`.

## Rebuild on the phone (proot Ubuntu, like the katolik app)
Copy this whole folder to the phone, then adapt paths in `build.sh`
(`APP=`, `SDK=`, JDK path) — the pipeline itself (aapt2/javac/d8/zipalign/
apksigner) works the same wherever the SDK lives.

## Versioning
3 digits: `MAJOR.MINOR.PATCH` — the third digit is for bug fixes only.
`./build.sh` reads the version from the `VERSION` file (or `./build.sh 1.2.0`
to set a new one) and derives `versionCode` as `MAJOR*10000 + MINOR*100 + PATCH`
so it always increases.

## Notes
- Same signing key MUST be used for updates or Android will refuse the install.
- WebView has `setAllowUniversalAccessFromFileURLs(true)` so the local
  `file://` page can call https APIs directly (CORS bypass).
- v1: 21,092 bytes, md5 f1ed438256476ebe26e8ccf83c8eed31.
- v1.1 (odometer ghosting fix): digit columns now use em-based translate steps,
  no flexbox inside digit columns. versionCode 2, md5 cb01d32fe60101db751a3426c466e54d.
- v1.1.1: first 3-digit release (same code as v1.1, versioning convention only).
- v1.2.0: IHSG detail page — tap the IHSG card to open top gainers / top losers
  among 24 tracked IDX stocks (blue chips & index heavyweights), with day
  high/low summary; Android back button closes the detail overlay first.
- v1.3.0: IHSG detail redesigned as pro dashboard — hero price block (big price,
  % + points, day-range slider with prev-close marker, OHLC + volume tiles),
  canvas intraday chart (1-minute Yahoo series, gradient area, prev-close
  dashed reference, WIB time axis), market breadth bar (up/flat/down counts),
  top gainers / losers / most-active-by-value tables.
- v1.4.0: market-wide top gainers/losers — detail page now pulls the real
  se-IDX tables from id.investing.com (server-rendered HTML, parsed by row
  shape not hashed class names; verified 33 gainers + 50 losers live); 24-stock
  Yahoo watchlist kept as fallback + for breadth/most-active. WebView UA set
  to explicit Chrome Mobile (the UA the fetch was verified with). No cloak or
  anti-bot tooling needed — plain request returns 200.
- v1.4.1: investing.com fetch diagnostics — detail page now shows the exact
  fetch outcome per table (HTTP status, KB, rows scanned/matched) in the note
  line, plus real browser request headers and sequential (non-burst) fetching,
  to pin down why the phone falls back to the watchlist.
- v1.5.0: running price ticker on the IHSG detail page — scrolling tape of
  current prices + % changes for the 24-stock watchlist, pinned under the
  detail header (reuses the dashboard tape style, 38s loop).
- v1.5.1: removed the temporary fetch-diagnostics line — investing.com confirmed
  working on the phone (HTTP 200, 36 gainers + 50 losers parsed 2026-10-19);
  note now just names the source.
- v1.6.0: Sector Performance — new detail-page section grouping the 24-stock
  watchlist by IDX-IC sector (Financials, Energy, Basic Materials,
  Infrastructures, Industrials, Consumer Non-Cyclicals, Technology) with
  diverging green/red bars, avg % change per sector, and a summary line
  (n sektor · menguat/melemah · terbaik/terlemah).
- v1.7.0: KOSPI (^KS11) and SSE Composite (^SSEC) added to Global Markets.
- v1.7.1: fixed wrong IHSG prev close — Yahoo's chartPreviousClose for ^JKSE lagged a full trading day (Tue 20 Oct showed Friday's 5.185,10 instead of Monday's 4.996,61, flipping the sign to -0,37%). The index now derives prev from daily bars (last completed trading day, Asia/Jakarta) for both the dashboard card and the detail page/chart; OPEN tile falls back to the first intraday point; index volume 0 now shows '—'.
- v1.7.2: consolidation release (two v1.7.1 builds existed — main-chat build fixed ^SSEC→000001.SS; side-chat build fixed the ^JKSE prev-close bug). This build combines both: SSE Composite via 000001.SS + daily-bar prev close for ^JKSE.
- v1.8.0: Semua Emiten — full IDX stock browser. One fetch of investing.com's Indonesia equities page yields all 964 emiten (name, price, pts, %); searchable list with sort chips (Naik/Turun/A–Z/Harga) and market summary (n emiten · naik · turun · tetap). Tapping any stock opens a per-stock detail page (hero price + %, day-range slider, Open/Prev/High/Low/Volume tiles, intraday chart) fed by Yahoo .JK with the daily-bar prev-close fix. Android back now closes the topmost overlay via window.__closeTop (stock detail -> stock list -> IHSG detail).
- v2.0.0: RENAMED to "Indonesia Economy Health" (launcher label, title, header; package unchanged). New home tab 🏛️ Makro: BPS macroeconomic health dashboard — 10 sub-indicators (GDP, inflasi IHK, TPT, kemiskinan, neraca dagang, cadev, IPM, Gini, NTP, wisman) with latest 2026 BPS releases vs same-period 2025, each scored SEHAT (green) / WASPADA (yellow) / SAKIT (red) with trend-aware rules (inflation accelerating to band ceiling, shrinking surplus, bleeding reserves downgrade to yellow). Master indicator: SVG gauge 0–100 = (2*green + yellow)/(2n), ≥75 SEHAT / 50–75 WASPADA / <50 SAKIT, plus composition bar and counts. Current score 80/100 SEHAT (6g/4y/0r, data per Okt 2026). Existing live market dashboard kept intact under the 📈 Pasar tab; detail overlays + Android back bridge unchanged.
- v2.1.0: +2 manufacturing indexes on the Makro tab: PMI Manufaktur (S&P Global) Sep 2026 = 52,4 vs Sep 2025 = 50,4 (expansion, highest since Feb 2026; new export orders fastest since May 2022); IKI Indeks Kepercayaan Industri (Kemenperin) Sep 2026 = 51,93 vs Sep 2025 = 53,02 (15 of 23 subsectors expansive). Health rule for diffusion indexes: ≥51 green / 49–51 yellow / <49 red — both green. Master now 83/100 SEHAT (8g/4y/0r, 12 indicators). Makro subtitle updated (BPS, S&P Global & Kemenperin).
- v2.2.0: +Utang Pemerintah card on the Makro tab (DJPPR Kemenkeu): Q2 2026 = 41,26% PDB (total Rp 10.294 T: SBN 87,1%, pinjaman 12,9%) vs 2025 = 40,46% (Rp 9.637,90 T). Health rule: <40% green / 40–45% yellow / >45% red (legal cap 60%) — yellow: highest since 2021, interest burden Rp 450 T. Card shows the ratio big + total as a prominent extra line (generic `extra` field support added to card renderer). Master now 81/100 SEHAT (8g/5y/0r, 13 indicators).
- v2.2.1: day-range pin now carries a price label (IHSG detail + per-stock detail) so the marker reads unmistakably as "where the current price sits between today's low and high", not session progress; label flips side when price is near the low end. (The marker math was already correct — e.g. 5.419 at 98,5% of the 5.185–5.422 range.) Plus: the top ticker tape is now tab-aware — on the Makro tab it scrolls the macro indicators (master score first, then all 13 with health colors + deltas); on the Pasar tab it scrolls market prices as before.
- v2.3.0: header mood badge replaced: MIXED/RISK ON/RISK OFF → SEHAT/WASPADA/SAKIT, tab-aware (Makro tab: macro master score, e.g. "✓ SEHAT · 81"; Pasar tab: market health). New "Kesehatan Pasar" card at the top of the Pasar page: 0–100 score = % of 9 tracked markets up (≥60 SEHAT / 40–60 WASPADA / <40 SAKIT — boundaries reproduce the old RISK ON/MIXED/RISK OFF exactly), with up/down counts. Shared macroHealth()/marketHealth() scorers.
- v2.3.1: Kesehatan Pasar goes Indonesia-only (no global markets): scored from IHSG + USD/IDR with direction-aware logic (IHSG up = good; USD/IDR down = rupiah menguat = good; ±0,25% flat band), 0–100 with ≥60 SEHAT / 40–60 WASPADA / <40 SAKIT. Card detail shows both components colored by good/bad + explainer note. MOOD_SET retired.
- v2.4.0: +BI-Rate tile on the Pasar page (Indonesia section): static policy-rate tile — 5,75% (RDG 20–21 Okt 2026; Gubernur BI Destry Damayanti; deposit facility 5,00%, lending facility 6,50%) vs 4,75% Okt 2025 → "+ 1,00 pp YoY". Static tiles skip the Yahoo fetch loop (sym:null) and are seeded + painted once at startup; generic staticRate branch in paintCard.
- v2.5.0: package renamed com.patricknofilter.economichealth → com.patricknofilter.economichealth (all source, manifest, build.sh CN, docs). NOTE: new package = new app identity on Android; install fresh alongside the old build, then uninstall the old one. Same signing key.
- v2.5.1: package rename reverted — back to com.patricknofilter.economichealth so the APK updates the installed app in place. If v2.5.0 (com.patricknofilter.*) was installed, uninstall that duplicate.
- v2.5.2: package is com.patricknofilter.economichealth for good (re-applied v2.5.0 rename). This updates the v2.5.0 install in place. Uninstall the old com.patrisius.economichealth app if still present.
- v2.5.3: IHSG holiday sub-indicator — Kesehatan Pasar card shows LIBUR (neutral, score —) with detail "IHSG libur · USD/IDR ±x%" when no IHSG trading happened today (weekend, or weekday public holiday detected via Yahoo regularMarketTime stale vs Jakarta date after 09:00 WIB); header badge shows LIBUR too. Trading days score exactly as before.
- v2.5.4: stale-data fix — failed symbol fetches retry once after 2s (Yahoo 429s are often intermittent); tiles not refreshed in a cycle are dimmed with a DATA LAMA tag (BI-Rate exempt, Emas Rp/gram stale only when gold/usdidr stale); a toast names the failed symbols (once per failure set, not every 60s cycle).
