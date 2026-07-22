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
- **Dwa typy auth:** (1) **statyczny token API** — nie wygasa, ważny póki istnieje (UŻYWAMY tego); (2) login użytkownika → **JWT** (trzeba odświeżać przez endpoint refresh — niewygodne do automatyki). **Dwa sposoby podania tokenu** (oba potwierdzone): nagłówek `Authorization: <token>` **albo** parametr URL **`?access_token=<token>`** (przydatne dla klientów, które nie ustawiają nagłówków; ⚠️ URL-e trafiają do logów — wol nagłówek). Brak/zły token → **401**.
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
Wzorzec gotowy: **builder urządzenia na pierwszym planie** (`patch_NN_widget.ps1`) z wbudowaną dyscypliną (luacheck → backup → PATCH **pełnego obiektu** `{name,lua,elements,widget,dialog}` → config-finished → weryfikacja → rollback). ⚠️ NIE `deploy_sinum.ps1` z samym `{lua}` — w tle wisi (zob. §6).

## 4. PowerShell (builder/deploy) — praktyka
- ⚠️ **Uruchamiaj PATCH na PIERWSZYM PLANIE** (krótki builder, nie długi `deploy_sinum.ps1` z `Start-Sleep`/logami, który harness wrzuca w tło → PATCH wisi; zob. §6). Higiena pomocnicza: `$ProgressPreference='SilentlyContinue'`, `[Net.ServicePointManager]::Expect100Continue=$false` (NIE leczą wiszenia w tle, ale nie szkodzą).
- Pobranie kodu: `GET …/lua` → `($r.data)` to string; zapis `[IO.File]::WriteAllText(path, $code, [Text.UTF8Encoding]::new($false))`.
- Wysyłka: `$bytes=[Text.Encoding]::UTF8.GetBytes(($obj|ConvertTo-Json -Depth 100 -Compress)); Invoke-WebRequest -Method Patch -Uri $u -Headers @{Authorization=$tok} -ContentType 'application/json; charset=utf-8' -Body $bytes -TimeoutSec 45`.
- **Plik `.ps1` zapisz jako UTF-8 z BOM**, jeśli zawiera emoji/PL (PS 5.1 inaczej czyta jako mojibake):
  `$c=[IO.File]::ReadAllText($p,[Text.UTF8Encoding]::new($false)); [IO.File]::WriteAllText($p,$c,[Text.UTF8Encoding]::new($true))`.
- ⚠️ **PowerShell case-insensitive:** `$EL` ≡ `$el`. Lista akumulatora elementów i parametr funkcji NIE mogą mieć tej samej nazwy (np. `$AllEl` + param `$item`).
- ⚠️ Liczby z wiodącym minusem: `New-Slider … -20 …` zrobi **string** „-20" → 422. Używaj `(-20)` lub `[double]`.
- `pwsh` może nie istnieć → `powershell.exe`. Token z User scope: `[Environment]::GetEnvironmentVariable('SINUM_TOKEN','User')` (świeży proces nie dziedziczy zmiennej z innego okna).
- Zegar/poll: po wdrożeniu odczekaj ~70 s na cykl (`onEvent` co 60 s), potem GET i weryfikuj wartości.
- ⚠️ **luacheck szuka `.luacheckrc` od CWD w górę** — builder odpalony spoza folderu ze wspólnym `.luacheckrc` daje fałszywe warningi (`wtp`/`tech`/`dateTime`/`CustomDevice` „undefined") i blokuje PATCH. W builderze podawaj **`--config <ścieżka>\.luacheckrc`** jawnie. Warning `W512 loop is executed at most once` (pętla z `break`) = exit 1 → bramka blokuje; weź pierwszy przez indeks `[1]` zamiast `for…break`.

## 5. Backup, rollback, weryfikacja
- Backup: `GET` pełny JSON → `…/backups/{id}_{stamp}.json` (z kodem do ręcznego przywrócenia).
- Rollback: PATCH `{lua}` (lub `{elements,widget}`) z backupu → config-finished.
- Weryfikacja po deploy: `banned`, `ban_reason`, `error_counter/max_errors`, długość/treść lua, obecność elementów, status.
- Dodatkowy backup: eksport elementów do **CSV** (`name,type,on_change,value,visibility`) — szybki przegląd kontrolek i callbacków.
- **Audyt callbacków** (po zmianie lua): zbierz funkcje regexem `function\s+CustomDevice:(\w+)` i porównaj ze zebranymi `on_change`/`on_press` elementów → zero brakujących definicji.

## 6. Behawioryzmy (z iteracji)
- Diagnozuj 422/304 zmieniając jedno pole naraz (np. `{elements unchanged}`→200 vs `{full data}`→422) — izoluj przyczynę.
- **Wieszający się PATCH = skrypt poszedł W TŁO, NIE blokada centrali. Lekarstwo: PATCH na pierwszym planie.** Objaw: GET wraca od ręki, PATCH wisi w nieskończoność, a `-TimeoutSec`/`Expect100Continue=$false`/`$ProgressPreference='SilentlyContinue'`/nawet HttpClient z twardym timeoutem **NIE pomagają** (sprawdzone — w tle żadne z nich nie przerwało wiszącego PATCH). Przyczyna: nakładka harnessa wrzuca długie/gadatliwe skrypty (np. `deploy_sinum.ps1` z `Start-Sleep` + logami) w tło, gdzie wywołanie HTTP się zawiesza. **Builder GUI (krótki, foreground) zawsze wraca w ~1 s.** ⇒ **Kod wdrażaj tą samą drogą co GUI: PATCH pełnego obiektu z polem `lua` przez foreground builder** (`{ name, lua, elements, widget, dialog }` w JEDNYM PATCH, wraca ~1 s). NIE diagnozuj tego jako „zablokowana ścieżka zapisu centrali", NIE każ resetować centrali — uruchom PATCH na pierwszym planie. Trzymaj skrypty deploy krótkie i ciche, żeby harness ich nie wrzucał w tło.
- Pełna przebudowa UI **resetuje wartości** suwaków/combo (nowe uuid) **i KASUJE wybory `device_selector`** — ostrzegaj lub edytuj przyrostowo. **Poprawka SAMEGO kodu bez utraty konfiguracji użytkownika: PATCH tylko `{ "lua": … }`** (builder z flagą `-LuaOnly`) — merge top-level zostawia elements/widget/dialog i wszystkie wybory nietknięte. Debug bez zmiany GUI: zapisz diagnostykę do ukrytego elementu tekstowego (`hidden_adjust`) i czytaj przez `GET` (wartość elementu = NVM).
- Duże urządzenia wdrażaj **fazami**; potwierdzaj logikę krytyczną (CWU, biwalent, jednostki) przed budową.

## 7. Dostęp zdalny (programowanie widgetów spoza LAN)
**Programowanie widgetów = `PATCH` (token) DO centrali — ruch WCHODZĄCY.** REST jest w LAN; tożsamość auth (token) i builder NIE zmieniają się przy pracy zdalnej — zmienia się tylko **droga sieciowa** do `192.168.1.162`.
- ⚠️ **Integracje „Klient X" (Modbus/MQTT/WebSocket/Zewnętrzny klient HTTP) są WYCHODZĄCE** (centrala → świat; w Lua `http_client[id]`/`mqtt_client[id]`/`websocket_client[id]`). **NIE służą do programowania centrali** ani logowania do niej — to do telemetrii/zdalnego sterowania przez broker/serwer, który kontrolujesz (centrala inicjuje połączenie, więc bez wystawiania portów). Inbound = tylko **Tokeny integracji zewnętrznych** (§1).
- ✅ **Zdalne programowanie „jak w LAN" → VPN do sieci lokalnej.** Po wpięciu centrala jest pod tym samym IP; `$env:SINUM_TOKEN` (User scope) + foreground builder działają **bez zmian** w skryptach.
- ❌ **Port-forward / wystawienie REST na internet — odradzane na produkcji** (przejęcie sterowania ogrzewaniem). Jeśli koniecznie: **tylko HTTPS**, token jak hasło, ogranicz IP/firewall.

### Checklista — zdalne programowanie przez VPN
1. **VPN** do sieci centrali aktywny (klient zestawiony, w tej samej podsieci lub z trasą do `192.168.1.x`).
2. **Test łączności:** `Test-Connection 192.168.1.162` oraz `GET /api/v1/devices/virtual/{id}` z tokenem → oczekuj `200` (a bez tokenu `401`).
3. **Token w User scope:** `[Environment]::GetEnvironmentVariable('SINUM_TOKEN','User')` (świeży proces nie dziedziczy zmiennej).
4. **Wdrażaj jak zwykle:** `patch_NN_widget.ps1 -DryRun` → realny (foreground; luacheck+backup+weryfikacja+rollback).
5. ⚠️ Przez VPN łącze bywa **wolniejsze/zrywalne** — PATCH foreground; jeśli zerwie, sprawdź stan przez `GET` (kod się aplikuje albo nie — backup masz). Nie ponawiaj w pętli w tle.

### ❌ „Agent na centrali" (http_client woła własny REST) — NIE działa (sprawdzone, 1.22.1)
Pomysł: custom device na centrali, który przez wychodzący `http_client` woła **własny** lokalny REST (`http://127.0.0.1/api/v1/...`) i sam aplikuje PATCH — żeby programować zdalnie BEZ sprzętu/VPN. **Przetestowane wyczerpująco — ślepy zaułek na tym firmware:**
- ✅ Łączność loopback działa: zdarzenie **`http_client_request_completed`** wstaje, bez auth wraca czysty **`401`** (status czytelny tylko przez `c:status()` w obsłudze tego zdarzenia — `onMessage` NIE wstaje, `hasResponse()` zwraca false).
- ❌ Kontener **`http_client[1..64]` jest PUSTY** — integracja „Zewnętrzny klient HTTP" nie wystawia się jako `http_client[id]`; dostępny tylko ograniczony obiekt z `getComponent("nazwa")`.
- ❌ Żądanie z **realnym tokenem (~291 zn.)** → **`status=0`** każdą drogą (nagłówek w kodzie, `?access_token=` w URL, nagłówek integracji). Bez tokenu → `401`. Czyli ten klient nie udźwiga uwierzytelnionego wołania (a z PC ten sam token daje 200 — więc REST OK, słaby jest klient HTTP centrali).
- **Wniosek:** self-PATCH agentem niewykonalny. Zdalne programowanie = **LAN lub VPN**. Nie próbuj tego znowu.
- **Chmura SINUM** (zdalny podgląd w aplikacji) to **relay WebSocket/STOMP** (`wss://backend.prd.sinum24.com/proxy/gs-guide-websocket/...?deviceId=<ID>&access_token=<krótki JWT>`), **nie REST** — nie nadaje się do skryptowego PATCH. Pełne zarządzanie ręczne przez aplikację chmurową działa (kanał WS), ale nie programowo.
