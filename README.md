# SiteSee Redesign — Integration Guide

## Files in this bundle

| File | Replaces |
|------|----------|
| `app_theme.dart` | *(new)* — design tokens + `buildSiteSeeTheme()` |
| `bottom_nav_bar.dart` | `bottom_nav_bar.dart` |
| `gps_status_banner.dart` | `gps_status_banner.dart` |
| `user_location_marker.dart` | `user_location_marker.dart` |
| `photo_picker_sheet.dart` | `photo_picker_sheet.dart` |
| `home_page.dart` | `home_page.dart` |
| `map_page.dart` | `map_page.dart` |
| `photo_page.dart` | `photo_page.dart` |
| `profile_page.dart` | `profile_page.dart` |

---

## 1. Add fonts to pubspec.yaml

```yaml
flutter:
  fonts:
    - family: Syne
      fonts:
        - asset: assets/fonts/Syne-Regular.ttf   weight: 400
        - asset: assets/fonts/Syne-Bold.ttf       weight: 700
    - family: DM Sans
      fonts:
        - asset: assets/fonts/DMSans-Regular.ttf  weight: 400
        - asset: assets/fonts/DMSans-Medium.ttf   weight: 500
    - family: DM Mono
      fonts:
        - asset: assets/fonts/DMMono-Regular.ttf  weight: 400
        - asset: assets/fonts/DMMono-Medium.ttf   weight: 500
```

Alternatively use the `google_fonts` package and replace the `fontFamily`
strings in `SiteFonts` with `GoogleFonts.syne(...)` etc.

---

## 2. Apply the theme in main.dart

```dart
import 'widgets/app_theme.dart';

MaterialApp(
  theme: buildSiteSeeTheme(),
  // ...
)
```

---

## 3. Place app_theme.dart

Put `app_theme.dart` in your `lib/widgets/` folder so the import path
`../widgets/app_theme.dart` works from all pages.

---

## 4. Optional — dark map tiles on MapPage

In `map_page.dart`, swap the `TileLayer` URL to CartoDB Dark Matter for a
fully dark map aesthetic:

```dart
urlTemplate:
  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
subdomains: const ['a', 'b', 'c', 'd'],
```

Add attribution per CartoDB's terms.

---

## 5. What changed visually

### Global
- Dark bg `#0D1117` / surfaces `#161B22` / `#1C2230`
- Amber `#E8A020` as the single accent (GPS dot, active nav, level, buttons)
- Monospace font (DM Mono) for all data — labels, IDs, timestamps, visibility pills
- Display font (Syne) for headings and names

### AppBar
- No elevation, dark bg, Syne title

### BottomNavBar
- Custom dark bar replaces `NavigationBar`
- Animated icon swap on tab press, amber active state

### GpsStatusBanner
- Pulsing amber dot replaces `CircularProgressIndicator`
- Dark pill container, no white box

### UserLocationMarker
- Animated expanding ring (repeating scale+fade)
- Amber dot with dark bg border

### HomePage
- Profile card: amber-bordered avatar circle, initials fallback, green badge
- Level card: large amber level number, 4 px progress bar
- Posts: coloured visibility pills (blue/amber/purple), divider rows

### MapPage
- Rounded-square photo pins coloured by visibility
- Compact map legend bottom-left
- Redesigned photo detail sheet (chips for visibility + GPS)

### PhotoPage
- Empty state: tap-to-add illustration
- Visibility: segmented 3-button control (replaces dropdown)
- Metadata card: monospace two-column rows

### ProfilePage
- Centered header with avatar, stats grid (Level / XP total / Progress %)
- "Sauvegarder" moved to AppBar action
- Fields grouped in dark cards with monospace labels