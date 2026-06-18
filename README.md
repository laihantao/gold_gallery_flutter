# Gold Gallery

A personal gold jewellery inventory and price tracking app built with Flutter. Track your jewellery collection, monitor live gold prices from multiple Malaysian vendors, and export professional PDF reports — all stored offline on your device.

---

## Features

### Jewellery Inventory
- Add, edit, and delete jewellery items with full detail capture: purchase date, brand, gold purity (916/999), weight, price per gram, labour fees, and total price
- Auto-calculate total price from weight × price/gram + labour fees, or enter manually
- Attach multiple photos per item — stored locally as base64
- Assign each item an **owner** and **payer** from your user list
- Record purchase location, measurement unit, currency, and free-text remarks
- Full-text search across name, brand, type, and owner
- Filter by brand, purity, jewellery type, and owner; sort by date or name

### Dashboard & Analytics
- At-a-glance portfolio summary: total item count and total value in MYR
- Breakdown cards by **jewellery type** (rings, necklaces, bangles, etc.) with item count and value
- Breakdown list by **owner** with individual portfolio values
- Recently added items carousel for quick access
- One-tap drill-down from dashboard cards to filtered listing

### Live Gold Price Tracking
- Real-time price fetch from three Malaysian vendors: **Poh Kong**, **Chiang Heng**, and **Tomei**
- Displays 916 and 999 gold prices per gram with day-over-day delta badges (↑ / ↓)
- Per-shop refresh button with loading and error states
- Stale price indicator when the last fetch failed but cached data exists

### Gold Price History & Chart
- Interactive line chart (custom `CustomPainter`) with fill gradient — tap or drag to inspect any point
- Toggle between 916 and 999 karat views; filter chart range to 7D / 30D / All
- Paginated history table (7 / 14 / 30 rows per page) with date and price columns
- **Automatic backfill on startup**: gaps caused by days the app wasn't opened are silently filled from a Google Apps Script web endpoint
- **Manual sync** in Settings triggers a full backfill from the Apps Script API, covering all vendors including Tomei
- Historical seed data bundled as CSV assets so the chart is populated on first launch

### Multi-User Support
- Create and manage multiple users (owners / payers)
- Each jewellery item independently tracks who owns it and who paid for it
- Dependency guard: users with linked jewellery cannot be deleted until items are reassigned
- Export and filter PDF reports per user

### PDF Export
- Two report formats: **Table** (compact, data-dense) and **Product Card** (image-inclusive)
- Per-column selection: choose exactly which fields appear in the report
- Filter by user, date range, and optionally group by owner (separate table per person)
- In-app PDF preview before saving to device
- Export filename includes a date stamp

### Data Backup & Restore
- Export full app data as a JSON backup file — share via system share sheet or save to device
- Import backup from file to restore all jewellery, users, brands, and types
- Import is additive and non-destructive (does not wipe existing data)

### Brands & Types Management
- 8 pre-seeded Malaysian gold brands: Poh Kong, Chiang Heng, Tomei, Emas Juvita, Tian Si, SK Jewellery, Wah Chan, Habib
- Add custom brands and jewellery types; deactivate without deleting
- Default/seeded entries are protected from deletion
- Jewellery types support trilingual names (English / 中文 / Bahasa Melayu) with icon selection

### Localisation
- Full UI in **English**, **简体中文**, and **Bahasa Melayu**
- Switch language at runtime from Settings — no restart required

### Themes
- Three hand-crafted colour themes: **Parchment** (warm gold), **Sky** (cool blue), **Blush** (rose)
- Theme selection persists across sessions

---

## Technical Highlights

| Area | Detail |
|---|---|
| **Storage** | Hive (NoSQL, offline-first) — all data lives on-device; no server required |
| **State management** | Provider / ChangeNotifier for prices, listing filters, and locale |
| **Navigation** | GoRouter with deep-link support and animated tab transitions (fade + slide) |
| **Chart** | Fully custom `CustomPainter` with gesture detection, tooltip smart-positioning, and fill gradient |
| **Price scraping** | HTML parser + CORS proxy fallback chain for web platform; native HTTP for mobile |
| **Backfill** | Google Apps Script web app acts as a lightweight price history API; Flutter fetches gap ranges on demand |
| **PDF** | `pdf` package with two layout engines (table and card), column selection, and per-user grouping |
| **Images** | `image_picker` → XFile → base64 for cross-platform storage inside Hive |
| **Localisation** | Flutter gen-l10n with runtime locale switching via `LocaleNotifier` |
| **Input validation** | Required-field checks, numeric formatters, dependency guards on delete |

---

## Screens

| Tab | Description |
|---|---|
| **Home** | Live gold price cards for all tracked vendors |
| **Dashboard** | Portfolio value summary, type breakdown, owner breakdown, recent items |
| **Listing** | Searchable, filterable, sortable jewellery inventory |
| **Settings** | Theme, language, sync, backup / restore, manage brands and types |

Tap any price card on Home to open its **Price History** page with interactive chart and paginated data table.

---

## Command

```
dart run flutter_launcher_icons
```

```
flutter build apk --release
```

```
flutter run -d chrome
```
