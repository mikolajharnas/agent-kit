---
name: sinum-remote-deploy
description: >
  Zdalne kodowanie centrali TECH SINUM przez lokalne REST API: pobieranie i wdrażanie kodu Lua oraz
  konfiguracji custom device, reguły body PATCH (merge/422/304), endpointy, autoryzacja tokenem,
  włączanie urządzenia (enabled), dyscyplina wdrożeń (luacheck → backup → PATCH → config-finished →
  weryfikacja → rollback), builder/skrypty PowerShell (UTF-8 BOM, timeouty, czytanie błędów), oraz
  bezpieczeństwo na produkcji. Użyj przy wdrażaniu na centralę, gdy pojawia się 422/304, mojibake,
  brak reakcji urządzenia, albo pytania o endpointy/autoryzację SINUM.
---

# SINUM — zdalne kodowanie centrali (REST API)

Wdrażanie kodu i konfiguracji na żywą centralę. Towarzyszące: [[sinum-lua-language]], [[sinum-widgets]].

## 0. Bezpieczeństwo (produkcja = realne ogrzewanie)
- Każda zmiana świadoma i odwracalna. **Master „Sterowanie aktywne" (OFF=podgląd)** w każdym sterowniku dającym komendy — testuj na żywo bez ryzyka, cutover świadomie.
- **Token TYLKO ze zmiennej środowiskowej** (`$env:SINUM_TOKEN`), nigdy w kodzie/repo. Jeśli pojawi się w pełnym JSON urządzenia (np. klucz API w `components.headers`) — redaguj przed zapisem na dysk.
- Kilka urządzeń może dotykać tych samych styków (`wtp[1]` itd.) → unikać równoległego sterowania.

## 1. Autoryzacja i endpointy
Base: `http://<central>/api/v1`. Nagłówek **`Authorization: <token>` (BEZ `Bearer`)**.
- Token z aplikacji: **System → Integracje → Tokeny integracji zewnętrznych → Dodaj token** (typ pozwalający na operacje API). `Unauthorized` = zły/wygasły token, spacje w wartości, lub za małe uprawnienia.
- ⚠️ Na testowanej centrali działa **bez `Bearer`**; część instancji/skryptów używa `Authorization: Bearer <token>`. Jeśli `Unauthorized` mimo dobrego tokenu — spróbuj wariantu z `Bearer` (zależne od centrali/firmware).
- `GET  /devices/virtual/{id}` — pełny JSON w `data` (elements, widget, dialog, lua, enabled, banned, status, error_counter, max_errors…).
- `GET  /devices/virtual/{id}/lua` — koperta `{ "data": "<kod>" }` (string, escaped unicode/`\r\n`).
- `PATCH /devices/virtual/{id}` — aktualizacja pól (body niżej).
- `POST /devices/virtual/{id}/config-finished` — po każdym PATCH.
- `GET /devices/wtp` · `/devices/sbus` · `/devices/tech` — listy sprzętu (id/name/type). (Brak `/devices/{id}/elements`.)

## 2. Reguły body PATCH (drogo okupione)
- ✅ **Częściowe pola top-level mergują się:** `{ "lua":"…" }`, `{ "elements":[…] }`, `{ "widget":{…} }`, `{ "dialog":{…} }`, `{ "enabled":true }`, `{ "name":"…", "logo":"…" }`.
- ❌ **Cały obiekt `data`** (z `banned/status/id/uuid/class…`) → **422** (pola read-only). Nie patchuj pełnego GET-a.
- ❌ `{ "data": {…} }` (opakowanie) → **304** (ignorowane).
- **Body jako UTF-8 BAJTY** + `Content-Type: application/json; charset=utf-8` (inaczej emoji/PL = mojibake).
- **`name` bez znaków specjalnych** `! @ # $ % ^ & * ( ) + = { } [ ] \ " ' / ? < > | \`` (myślnik/spacja/PL OK). Najłatwiej: pomiń `name` (zostaje obecna).
- **`enabled=true` wymagane**, by Lua działała (`status=unknown` + domyślne pola gdy false). Włącz: `PATCH { "enabled": true }`.
- **Serwer zwraca SZCZEGÓŁOWE błędy** z ścieżką pola: `{"errors":{"widget.content[3].rows[0].cells":{"text":"Parameter exceeds maximum range"}}}`. **Iteruj po nich** — nie zgadują. Łap `$_.Exception.Response`, czytaj body strumieniem.
- Częste komunikaty: `variant: Parameter is read only` → usuń `variant` z body (pole read-only); `…cells: Parameter exceeds maximum range` → za szeroki/zagnieżdżony rząd (limit 3 komórek); `hash.data`/`hash.meta` → z importu/eksportu JSON biblioteki z niepasującą kopertą meta — wol PATCH żywego urządzenia zamiast ręcznego importu częściowego JSON.
- Przy PATCH widget/elements zachowuj istniejące `name/uuid/type/callback`, zmieniaj tylko potrzebne pola.

## 3. Dyscyplina wdrożeń (BEZWZGLĘDNA)
Kolejność: **luacheck → backup → PATCH → config-finished → kontrola aplikacji → weryfikacja → rollback**.
1. Najpierw `-DryRun` (backup + luacheck, bez patcha). Nigdy bez backupu.
2. Po wdrożeniu sprawdź: `banned=false`, pusty `ban_reason`, `error_counter=0`, oraz że kod/elementy faktycznie się zaaplikowały.
3. Ban/błąd → rollback z backupu (`backups/*.json`).
4. Nie obchodź `luacheck`. `statistics:addPoint` tylko z `unit`.
Wzorzec gotowy: `deploy_sinum.ps1` (luacheck twarda bramka, backup, PATCH lua bajtami, weryfikacja, auto-rollback).

## 4. PowerShell (builder/deploy) — praktyka
- Pobranie kodu: `GET …/lua` → `($r.data)` to string; zapis `[IO.File]::WriteAllText(path, $code, [Text.UTF8Encoding]::new($false))`.
- Wysyłka: `$bytes=[Text.Encoding]::UTF8.GetBytes(($obj|ConvertTo-Json -Depth 100 -Compress)); Invoke-WebRequest -Method Patch -Uri $u -Headers @{Authorization=$tok} -ContentType 'application/json; charset=utf-8' -Body $bytes -TimeoutSec 45`.
- **Plik `.ps1` zapisz jako UTF-8 z BOM**, jeśli zawiera emoji/PL (PS 5.1 inaczej czyta jako mojibake):
  `$c=[IO.File]::ReadAllText($p,[Text.UTF8Encoding]::new($false)); [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($true))`.
- ⚠️ **PowerShell case-insensitive:** `$EL` ≡ `$el`. Lista akumulatora elementów i parametr funkcji NIE mogą mieć tej samej nazwy (np. `$AllEl` + param `$item`).
- ⚠️ Liczby z wiodącym minusem: `New-Slider … -20 …` zrobi **string** „-20" → 422. Używaj `(-20)` lub `[double]`.
- `pwsh` może nie istnieć → `powershell.exe`. Token z User scope: `[Environment]::GetEnvironmentVariable('SINUM_TOKEN','User')` (świeży proces nie dziedziczy zmiennej z innego okna).
- Zegar/poll: po wdrożeniu odczekaj ~70 s na cykl (`onEvent` co 60 s), potem GET i weryfikuj wartości.

## 5. Backup, rollback, weryfikacja
- Backup: `GET` pełny JSON → `…/backups/{id}_{stamp}.json` (z kodem do ręcznego przywrócenia).
- Rollback: PATCH `{lua}` (lub `{elements,widget}`) z backupu → config-finished.
- Weryfikacja po deploy: `banned`, `ban_reason`, `error_counter/max_errors`, długość/treść lua, obecność elementów, status.
- Dodatkowy backup: eksport elementów do **CSV** (`name,type,on_change,value,visibility`) — szybki przegląd kontrolek i callbacków.
- **Audyt callbacków** (po zmianie lua): zbierz funkcje regexem `function\s+CustomDevice:(\w+)` i porównaj ze zebranymi `on_change`/`on_press` elementów → zero brakujących definicji.

## 6. Behawioryzmy (z iteracji)
- Diagnozuj 422/304 zmieniając jedno pole naraz (np. `{elements unchanged}`→200 vs `{full data}`→422) — izoluj przyczynę.
- Wieszający się PATCH bywa winą nakładki (np. uruchomienie skryptu jako proces w tle) — bezpośredni PATCH potrafi wrócić w ~1 s.
- Pełna przebudowa UI **resetuje wartości** suwaków/combo (nowe uuid) — ostrzegaj lub edytuj przyrostowo.
- Duże urządzenia wdrażaj **fazami**; potwierdzaj logikę krytyczną (CWU, biwalent, jednostki) przed budową.
