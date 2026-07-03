# Pocket Gold — Theme Reference

Source of truth: [lib/theme/app_colors.dart](../lib/theme/app_colors.dart),
[lib/theme/app_theme.dart](../lib/theme/app_theme.dart),
[lib/theme/app_text_styles.dart](../lib/theme/app_text_styles.dart),
[lib/theme/theme_notifier.dart](../lib/theme/theme_notifier.dart).

The app ships 4 selectable themes ("coloured notebooks"), enum `AurumTheme`:

| id | label (en) | label (zh-CN) | label (ms) | dark? |
|---|---|---|---|---|
| `parchment` | **Aureate** (default) | 暖金 | Keemasan | No |
| `sky` | **Sky** | 天蓝 | Langit | No |
| `blush` | **Blush** | 玫瑰 | Merona | No |
| `noir` | **Noir** | 暗金 | Gelap | Yes |

Every raw `Color(0xFF...)` for these 4 themes lives in `app_colors.dart` — one
class per theme (`ParchmentColors`, `SkyColors`, `BlushColors`, `NoirColors`).
`app_theme.dart` wraps each into a private `_Palette` and exposes it via the
`AurumTheme` enum getters used across the app.

---

## 1. Color palettes

Role names below are the exact getter names on `AurumTheme` (e.g.
`appTheme.primary`). "Legacy alias" getters that just forward to the same
value are noted in parentheses.

### Aureate (`parchment`) — default, warm cream/champagne-gold

| Role | Getter | Hex |
|---|---|---|
| Background (page) | `primaryBg` (alias `backgroundPrimary`) | `#F5F0E0` |
| Surface (cards) | `surface` (alias `backgroundSurface`) | `#FEFCF8` |
| Header/AppBar bg | `headerBg` | `#D4A843` |
| Watermark pattern | `patternColor` | `#C8A860` |
| Primary accent | `primary` (alias `accentPrimary`) | `#BF9E52` |
| Primary dark | `primaryDark` (alias `accentSecondary`, `priceHighlight`) | `#8C6A28` |
| Primary light (chip bg) | `primaryLight` (alias `backgroundSubtle`) | `#EAE2C8` |
| Secondary/accent (FAB) | `accent` | `#3D2B1F` |
| Text — heading | `inkDark` (alias `textHeading`) | `#28200E` |
| Text — body | `inkMid` (alias `textBody`) | `#5C4A38` |
| Text — caption/metadata | `inkLight` | `#9A8468` |
| Border | `border` (alias `borderColor`) | `#D8CEBC` |
| Divider | `divider` | `#E8E2D0` |
| Shadow | `shadow` | `#A88A40` |
| Success | `success` | `#7BAE6E` |
| Warning | `warning` | `#BF9E52` |
| Error | `error` | `#FF6B6B` |
| Error (light bg) | `errorLight` | `#FFEEEE` |

### Sky — soft blue

| Role | Getter | Hex |
|---|---|---|
| Background | `primaryBg` | `#F0F6FF` |
| Surface | `surface` | `#FFFFFF` |
| Header/AppBar bg | `headerBg` | `#7EC8E3` |
| Watermark pattern | `patternColor` | `#B8DCF0` |
| Primary accent | `primary` | `#7EC8E3` |
| Primary dark | `primaryDark` | `#4DA8C8` |
| Primary light (chip bg) | `primaryLight` | `#CCEAF5` |
| Secondary/accent (FAB, mint) | `accent` | `#A0D4B8` |
| Text — heading | `inkDark` | `#1A2E3A` |
| Text — body | `inkMid` | `#4A6880` |
| Text — caption | `inkLight` | `#8AAABB` |
| Border | `border` | `#BDD8E8` |
| Divider | `divider` | `#D8EDF5` |
| Shadow | `shadow` | `#8ABCD4` |
| Success | `success` | `#7BAE6E` |
| Warning | `warning` | `#F5C842` |
| Error | `error` | `#FF6B6B` |
| Error (light bg) | `errorLight` | `#FFEEEE` |

### Blush — rose pink

| Role | Getter | Hex |
|---|---|---|
| Background | `primaryBg` | `#FFF0F4` |
| Surface | `surface` | `#FFFFFF` |
| Header/AppBar bg | `headerBg` | `#FFAABB` |
| Watermark pattern | `patternColor` | `#FFCCD8` |
| Primary accent | `primary` | `#FFAABB` |
| Primary dark | `primaryDark` | `#E0708A` |
| Primary light (chip bg) | `primaryLight` | `#FFDDE5` |
| Secondary/accent (FAB, peach) | `accent` | `#FFCC88` |
| Text — heading | `inkDark` | `#2C1A20` |
| Text — body | `inkMid` | `#6B4050` |
| Text — caption | `inkLight` | `#A88090` |
| Border | `border` | `#EEC8D0` |
| Divider | `divider` | `#F5DDE2` |
| Shadow | `shadow` | `#E8A0B0` |
| Success | `success` | `#7BAE6E` |
| Warning | `warning` | `#F5C842` |
| Error | `error` | `#FF6B6B` |
| Error (light bg) | `errorLight` | `#FFEEEE` |

### Noir — dark mode, charcoal + warm gold

| Role | Getter | Hex |
|---|---|---|
| Background | `primaryBg` | `#1C1914` |
| Surface | `surface` | `#26221C` |
| Header/AppBar bg | `headerBg` | `#2E2820` |
| Watermark pattern | `patternColor` | `#3A3025` |
| Primary accent (warm gold) | `primary` | `#C9A84C` |
| Primary dark — actually *lighter* gold for contrast on dark bg | `primaryDark` | `#E8C86D` |
| Primary light (dark gold chip bg) | `primaryLight` | `#3D3020` |
| Secondary/accent (FAB, bright gold) | `accent` | `#E8C86D` |
| Text — heading (warm cream) | `inkDark` | `#F2EDE4` |
| Text — body (warm light) | `inkMid` | `#CEC0A4` |
| Text — caption (muted) | `inkLight` | `#8A7B66` |
| Border | `border` | `#3E3628` |
| Divider | `divider` | `#2E2820` |
| Shadow | `shadow` | `#0A0805` |
| Success | `success` | `#7BAE6E` |
| Warning | `warning` | `#C9A84C` |
| Error | `error` | `#FF6B6B` |
| Error (light bg) | `errorLight` | `#4A2020` |

> ⚠️ Note: in Noir, `primaryDark` (`#E8C86D`) is lighter than `primary`
> (`#C9A84C`) — the opposite relationship to the other 3 themes — and is
> identical to `accent`. Intentional (comment in source: "lighter gold for
> higher contrast on dark"), but worth flagging for a design tool that
> assumes `primaryDark` is always the darker shade.

### Derived / computed colors (not static hex, but part of the palette contract)

| Name | Definition | Notes |
|---|---|---|
| `snackBarBg` | `isDark ? surface : inkDark` | Always dark enough for white text |
| `cardShadow` | `BoxShadow(color: shadow @ 15% alpha, blur 8, offset (2,4))` | Standard card shadow, used app-wide |
| `ColorScheme.onPrimary` | `isDark ? inkDark : Colors.white` | Material `ColorScheme` mapping in `toThemeData()` |
| `ColorScheme.onSecondary` | `isDark ? inkDark : Colors.white` | |
| `ColorScheme.secondary` | `= accent` | |
| `ColorScheme.onSurface` | `= inkDark` | |
| `ColorScheme.onError` | `Colors.white` (all themes) | |

### `goldPrice` legacy constant

`lib/theme/app_theme.dart:8` — `const Color goldPrice = ParchmentColors.primaryDark;` (`#8C6A28`, hardcoded to Aureate regardless of active theme — legacy, kept for old price text call sites).

### Out-of-system color constants (NOT part of `AurumTheme`, theme-independent)

These bypass the palette entirely and stay fixed across all 4 themes:

**Certificate/share-card palette** — [lib/widgets/share_card_widget.dart:14-24](../lib/widgets/share_card_widget.dart) — explicitly documented as "deliberately independent of `AurumTheme`":

| Constant | Hex |
|---|---|
| `kCertBg` | `#FBF6EA` |
| `kCertFrame` | `#D8C79A` |
| `kCertGold` | `#A8863B` |
| `kCertGoldMuted` | `#B7A05C` |
| `kCertInkDark` | `#2B2620` |
| `kCertInkMuted` | `#8C8172` |
| `kCertChipBg` | `#F6F0E0` |
| `kCertFooterMuted` | `#B0A48F` |
| `kCertButtonBg` | `#FDFCF8` |
| `kCertShareGradientTop` | `#C9A85A` |
| `kCertShareGradientBottom` | `#B4913F` |

**Splash screen coin colors** — [lib/screens/splash_screen.dart:61-63](../lib/screens/splash_screen.dart):

| Constant | Hex |
|---|---|
| `_coinFill` | `#D4A847` |
| `_coinStroke` | `#8B6914` |
| `_coinInner` | `#F0C040` |

**Gain/loss semantic colors, hardcoded per-file instead of using `appTheme.success` / `appTheme.error`:**

| File | Gain color | Loss color |
|---|---|---|
| [lib/pages/price_alerts_page.dart:197](../lib/pages/price_alerts_page.dart) | `#3DAA3D` | `#CC4444` |
| [lib/pages/price_alerts_page.dart:138,279,285](../lib/pages/price_alerts_page.dart) (error icon) | — | `#CC3333` |
| [lib/widgets/gold_price_section.dart:395,403,583](../lib/widgets/gold_price_section.dart) | `#3DAA3D` | `#CC4444` |
| [lib/widgets/gold_price_card.dart:481,533](../lib/widgets/gold_price_card.dart) | `#3FB66E` | `#E06666` |
| [lib/widgets/jewellery_card.dart:358](../lib/widgets/jewellery_card.dart) | `#3DAA3D` | `#CC4444` |
| [lib/pages/portfolio_chart_page.dart:201,334-335](../lib/pages/portfolio_chart_page.dart) | `#3DAA3D` | `#CC4444` |
| [lib/pages/dashboard_page.dart:434-470](../lib/pages/dashboard_page.dart) (on gradient card, higher-contrast variant) | `#7BE87B` | `#FF8A8A` |
| [lib/pages/details_page.dart:651](../lib/pages/details_page.dart) | uses `appTheme.success`/`appTheme.error` ✅ | (only correct usage found) |

This is a real inconsistency: 6 different files reimplement gain/green and
loss/red with 3 *different* hex pairs (`#3DAA3D`/`#CC4444` is the most
common, but `gold_price_card.dart` uses `#3FB66E`/`#E06666` and
`dashboard_page.dart` uses `#7BE87B`/`#FF8A8A`), none of which match
`AurumTheme.success` (`#7BAE6E`) or `AurumTheme.error` (`#FF6B6B`). Only
`details_page.dart:651` uses the theme-provided `success`/`error` getters.

**Bottom nav** — [lib/components/bottom_navigation.dart:125](../lib/components/bottom_navigation.dart): `const warmWhite = Color(0xFFFFFDF5);` (local override, not theme-driven).

---

## 2. Gradients

All gradients are `LinearGradient`. None are defined as reusable
constants/theme helpers — each is inlined at its call site.

| Location | Colors (start → end) | Direction | Notes |
|---|---|---|---|
| **Portfolio Overview card** — [dashboard_page.dart:336-346](../lib/pages/dashboard_page.dart) `_PortfolioCard` | `primaryDark` → `primary` → `highlight` (primary lerp 20% white) → `primaryDark @ 90%` | topLeft → bottomRight, stops `[0.0, 0.38, 0.62, 1.0]` | "the gold gradient" |
| **Market Value card** — [details_page.dart:660-670](../lib/pages/details_page.dart) | Identical recipe to Portfolio Overview: `primaryDark` → `primary` → `highlight` → `primaryDark @ 90%` | topLeft → bottomRight, stops `[0.0, 0.38, 0.62, 1.0]` | Comment explicitly says "matches `_PortfolioCard` style" |
| Shimmer overlay on Portfolio card | `white @ 13%` → `transparent` | topLeft → bottomRight | [dashboard_page.dart:369-376](../lib/pages/dashboard_page.dart) |
| Shimmer overlay on Market Value card | `white @ 13%` → `transparent` | topLeft → center | [details_page.dart:694-701](../lib/pages/details_page.dart) |
| Detail hero image scrim | `primaryDark @ 33%` → `transparent` → `primaryDark @ 87%` | topCenter → bottomCenter, stops `[0.0, 0.45, 1.0]` | [details_page.dart:289-297](../lib/pages/details_page.dart) |
| Edit button pill | `primary` → `primaryDark` | (default, topLeft→bottomRight) | [details_page.dart:1466-1468](../lib/pages/details_page.dart) |
| Certificate/share card top bar | `kCertShareGradientTop` (`#C9A85A`) → `kCertShareGradientBottom` (`#B4913F`) | topCenter → bottomCenter | [details_page.dart:1691-1698](../lib/pages/details_page.dart) — theme-independent cert palette |
| Portfolio chart area fill | `lineColor @ 18%` → `lineColor @ 0%` | topCenter → bottomCenter | [portfolio_chart_page.dart:441-448](../lib/pages/portfolio_chart_page.dart) — `lineColor` is dynamic (gain/loss color) |

**Recommendation for the design tool:** the "gold gradient" is really one
recipe reused twice (`_PortfolioCard` and Market Value card): 4-stop
diagonal gradient built from `primaryDark → primary → (primary lerped 20%
toward white) → primaryDark@90%`, always paired with a `white@13%→
transparent` diagonal shimmer overlay on top. It is not currently extracted
into a shared helper — both call sites duplicate the stop list.

---

## 3. Typography

Defined in [lib/theme/app_text_styles.dart](../lib/theme/app_text_styles.dart), class `AppTextStyles` (static methods, all take a `Color` and most take an optional `AppLocale locale`).

**Font families in the design system:**
- **Fredoka** (Google Fonts `fredoka`) — display/title, rounded chunky/cartoon
- **Nunito** (Google Fonts `nunito`) — body/labels, soft rounded sans (also the app-wide Material `TextTheme` base via `GoogleFonts.nunitoTextTheme()`)
- **Caveat** (Google Fonts `caveat`) — handwritten accent notes
- **Space Mono** (Google Fonts `spaceMono`) — prices/numbers, ledger/typewriter feel
- **ZCOOL KuaiLe** (Google Fonts `zcoolKuaiLe`) — replaces Fredoka/Nunito for `AppLocale.zhCN` (Simplified Chinese), sizes scaled down ~1pt

| Semantic name | Method | Locale = en | Locale = zhCN | Weight |
|---|---|---|---|---|
| App title | `appTitle(c)` | Fredoka, 24 | ZCOOL KuaiLe, 22 | 700 |
| Display | `display(c)` | Fredoka, 28 | ZCOOL KuaiLe, 26 | 700 |
| Headline | `headline(c)` | Fredoka, 20 | ZCOOL KuaiLe, 18 | 700 |
| Title | `title(c)` | Nunito, 16 | ZCOOL KuaiLe, 15 | 700 |
| Body | `body(c)` | Nunito, 14 | ZCOOL KuaiLe, 13 | 400 |
| Body bold | `bodyBold(c)` | Nunito, 14 | ZCOOL KuaiLe, 13 | 700 |
| Caption | `caption(c)` | Nunito, 11 | ZCOOL KuaiLe, 10 | 400 (default) |
| Hand note (decorative) | `handNote(c)` | Caveat, 15 | *(same, locale-independent)* | 400 (default) |
| Price | `price(c)` | Space Mono, 20 | *(same)* | 700 (bold) |
| Price small | `priceSmall(c)` | Space Mono, 13 | *(same)* | 700 (bold) |
| Amount | `amount(c)` | Space Mono, 16 | *(same)* | 700 (bold) |

Base Material `TextTheme` (`ThemeData.textTheme` in `app_theme.dart:215`): `GoogleFonts.nunitoTextTheme()` with `bodyColor: inkMid`, `displayColor: inkDark`.

### ⚠️ Extra font families referenced outside `app_text_styles.dart`

These bypass `AppTextStyles` entirely and pull in **two additional serif
families not part of the documented type system**:

| File | Font(s) used | Where |
|---|---|---|
| [lib/widgets/share_card_widget.dart:134](../lib/widgets/share_card_widget.dart) | **Playfair Display** (serif, italic) | "Pocket Gold" wordmark on the share/certificate card |
| [lib/widgets/share_card_widget.dart:173,225](../lib/widgets/share_card_widget.dart) | **Cormorant Garamond** (serif) | Jewellery name + "Total Paid" amount on the certificate card |
| lib/widgets/share_card_widget.dart:144,184,215,241,275,279 | Nunito (matches system) | body rows, ok |
| [lib/pages/details_page.dart:1676,1757](../lib/pages/details_page.dart) | `GoogleFonts.nunito(...)` inline instead of `AppTextStyles.body/bodyBold` | duplicate/ad-hoc, not a new family but still bypasses the shared style layer |
| [lib/screens/splash_screen.dart:482](../lib/screens/splash_screen.dart) | `GoogleFonts.fredoka(...)` inline (matches system font, but not via `AppTextStyles`) | splash title |
| [lib/screens/splash_screen.dart:498](../lib/screens/splash_screen.dart) | `GoogleFonts.caveat(...)` inline (matches system font, not via `AppTextStyles`) | splash caption |
| [lib/main_common.dart:80](../lib/main_common.dart) | `GoogleFonts.zcoolKuaiLe()` inline | (locale picker or similar) |
| [lib/services/pdf_export_service.dart:18-19](../lib/services/pdf_export_service.dart) | `PdfGoogleFonts.notoSansSCRegular/Bold` | PDF export only (different font package, expected — PDF rendering can't reuse `google_fonts` widget fonts) |

**Bottom line — the serif font (Playfair Display + Cormorant Garamond) is
used exclusively inside `share_card_widget.dart`**, for the "certificate of
ownership" share image (Pocket Gold wordmark, item name, total paid amount).
It is a deliberate one-off "premium certificate" look, paired with the
theme-independent `kCert*` color palette — it does not appear anywhere else
in the app. Everywhere else, "the serif" does not exist; the rest of the app
is Fredoka (display) + Nunito (body) + Space Mono (numbers) + Caveat
(handwritten accents), or ZCOOL KuaiLe for zh-CN.

---

## 4. Reusable component styles vs. hardcoded pages

### Defined in `ThemeData` (via `AurumTheme.toThemeData()`, `app_theme.dart`) — apply automatically to any `ElevatedButton`/`OutlinedButton`/etc.

| Component | Style |
|---|---|
| **AppBar** | bg `headerBg`, fg `inkDark`, elevation 0, title style `AppTextStyles.appTitle(inkDark)` |
| **Card** (`CardThemeData`) | bg `surface`, elevation 0, `RoundedRectangleBorder` radius **16**, 1px `border` side |
| **Elevated (primary/pill) button** | bg `headerBg`, fg white, overlay `primaryDark @ 20%`, elevation 2, shadow `shadow @ 25%`, padding `14v/32h`, text `AppTextStyles.bodyBold(white)`, shape `StadiumBorder` with 1.5px `primaryDark` border |
| **Outlined button** | transparent bg, fg `primary`, 1.5px `primary` border, padding `14v/32h`, text `AppTextStyles.bodyBold(primary)`, shape `StadiumBorder` (no border override) |
| **Text button** | fg `inkMid`, text `AppTextStyles.body(inkMid)` |
| **FAB** | bg `primary`, fg white, elevation 4, `CircleBorder` with 1.5px `primaryDark` border |
| **Input fields** | filled, fill `surface`, radius **12**, border `border` (1px) / focused `primary` (1.8px) / error `error` (1.2px) |
| **Chip** | bg `primaryLight`, selected `primary`, 1px `primary` side, `StadiumBorder`, label `AppTextStyles.caption(inkDark)` |
| **SnackBar** | bg `snackBarBg`, text `AppTextStyles.body(white)`, action color `primary`, `StadiumBorder`, floating |
| **Dialog** | bg `surface`, radius **20**, title `AppTextStyles.headline(inkDark)`, content `AppTextStyles.body(inkMid)` |
| **BottomSheet** | bg `surface`, top radius **24** |
| Standard card shadow | `AurumTheme.cardShadow` getter — `shadow @ 15%`, blur 8, offset (2,4) — used by hand-rolled cards that don't rely on `CardTheme` |

### Reusable widget components (`lib/components/`)

| File | Component | Notes |
|---|---|---|
| [lib/components/buttons.dart](../lib/components/buttons.dart) | `PrimaryButton`, `GhostButton` | Thin wrappers around `ElevatedButton`/`OutlinedButton` — fully theme-driven, no hardcoded colors |
| [lib/components/cards.dart](../lib/components/cards.dart) | `ItemCard` | Uses `appTheme.cardShadow`, `appTheme.border` (via `SketchBorder`), radius **16**, `appTheme.surface` |
| [lib/components/badges.dart](../lib/components/badges.dart) | `PurityBadge`, `PriceText` | `PurityBadge`: `primaryLight` bg, radius **20**, 1px `primary` border. `PriceText`: `AppTextStyles.price(primaryDark)` |
| lib/widgets/sketch_border.dart | `SketchBorder` | Custom hand-drawn-style border painter, takes `color` param — used by `ItemCard` |

### Pages/widgets that hardcode their own styles instead of the shared ones

| File | What's hardcoded | Should probably use |
|---|---|---|
| [lib/widgets/share_card_widget.dart](../lib/widgets/share_card_widget.dart) | Entire `kCert*` color palette + Playfair Display/Cormorant Garamond fonts, custom radii (26, 20, 14, 12), custom shadow | Intentional exception (documented in-file as deliberately theme-independent) — not a bug, but worth flagging as the one place design tokens diverge |
| [lib/pages/price_alerts_page.dart](../lib/pages/price_alerts_page.dart) | Gain/loss colors `#3DAA3D`/`#CC4444`/`#CC3333` instead of `appTheme.success`/`error` | `appTheme.success` / `appTheme.error` |
| [lib/widgets/gold_price_section.dart](../lib/widgets/gold_price_section.dart) | Same `#3DAA3D`/`#CC4444` pair (3 occurrences) | `appTheme.success` / `appTheme.error` |
| [lib/widgets/gold_price_card.dart](../lib/widgets/gold_price_card.dart) | Different gain/loss pair `#3FB66E`/`#E06666` | `appTheme.success` / `appTheme.error` |
| [lib/widgets/jewellery_card.dart](../lib/widgets/jewellery_card.dart) | `#3DAA3D`/`#CC4444` | `appTheme.success` / `appTheme.error` |
| [lib/pages/portfolio_chart_page.dart](../lib/pages/portfolio_chart_page.dart) | `#3DAA3D`/`#CC4444` (chart line/label color + gradient fill built from it) | `appTheme.success` / `appTheme.error` |
| [lib/pages/dashboard_page.dart](../lib/pages/dashboard_page.dart) | Third gain/loss pair `#7BE87B`/`#FF8A8A` (used on the gold-gradient card for contrast) + inline gradient recipe duplicated from `details_page.dart` | Could extract a shared "on-gradient" success/error pair + a shared gradient helper |
| [lib/pages/details_page.dart](../lib/pages/details_page.dart) | Inline gradient recipe duplicated from `dashboard_page.dart` (`_PortfolioCard`); many one-off `BorderRadius.circular(...)` values (8, 10, 14, 16, 20, 22, 99) not standardized against the CardTheme's 16 | Extract shared gradient builder; consider a radius scale |
| [lib/components/bottom_navigation.dart](../lib/components/bottom_navigation.dart) | Local `warmWhite = #FFFDF5` override | Nearest theme token is `surface`/`primaryBg`, but not identical — likely an intentional one-off |
| [lib/screens/splash_screen.dart](../lib/screens/splash_screen.dart) | Coin illustration colors (`#D4A847`/`#8B6914`/`#F0C040`) + inline `GoogleFonts.fredoka`/`GoogleFonts.caveat` instead of `AppTextStyles` | Splash renders before theme/locale may be ready, so some independence is expected; font calls could still route through `AppTextStyles` |
| [lib/main_common.dart:80](../lib/main_common.dart) | Inline `GoogleFonts.zcoolKuaiLe()` | Route through `AppTextStyles` if a semantic size/weight applies |

**Summary of the biggest cleanup opportunity:** gain/loss (success/error)
color is reimplemented ad-hoc in **6 files** with **3 different hex pairs**,
none matching the theme's own `success`/`error` tokens. Consolidating these
onto `appTheme.success`/`appTheme.error` (already defined per-theme) would
be the highest-leverage fix for design/dev consistency.
