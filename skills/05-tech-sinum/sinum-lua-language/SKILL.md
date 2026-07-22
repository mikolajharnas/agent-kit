---
name: sinum-lua-language
description: >
  Programowanie Custom Device TECH SINUM w języku Lua: framework platformy (onInit/onEvent/getElement/setValue),
  dostęp do urządzeń (wtp/sbus/tech/virtual[id], :call/:getValue/:setValue/:changedValue), zdarzenia
  (dateTime, weather, sunrise/sunset, event.type), timery (setTimeout/clearTimeout), statystyki
  (statistics:addPoint z unit), pogoda (weather:current/hourly/daily), powiadomienia (notify), pamięć
  trwała (variable), utils, klient HTTP, oraz krytyczne pułapki runtime. Użyj przy pisaniu/debugowaniu
  kodu Lua sterowników SINUM, gdy pojawia się ban, błędny czas, martwe UI, lub pytania o API platformy.
---

# SINUM — język Lua (Custom Device)

Reguły i API języka Lua na platformie TECH SINUM. Towarzyszące: [[sinum-remote-deploy]] (wdrażanie kodu),
[[sinum-widgets]] (GUI). Pełne API: `LUA-API-manual` (PDF firmware 1.22).

## 1. Framework Custom Device
Platforma dostarcza globalną klasę `CustomDevice`. Definiuj na niej metody — **NIE rób `CustomDevice = {…}`**
(nadpisuje klasę → łamie framework, `status=unknown`).
```lua
function CustomDevice:onInit(reason)  -- reason: "add" (pierwsze dodanie), "config", restart…
  -- inicjalizacja; na "add" ustaw domyślne wartości elementów
end
function CustomDevice:onEvent(event)  -- wołane przy KAŻDYM zdarzeniu (poll 60 s + zmiany)
end
function CustomDevice:onMojaAkcja(value, element)  -- callback elementu (on_change/on_press)
end
```
- Urządzenie musi mieć **`enabled=true`**, inaczej kod się nie uruchamia (patrz [[sinum-remote-deploy]]).
- **Dostęp do GUI:** `self:getElement('name')` → element; `el:setValue('value', x)`, `el:setValue('label_text', s)`, `el:setValue('visibility', 'visible'|'hidden_adjust')`, `el:getValue('value')`, `el:getValue('associations.selected')`. **Nie zostawiaj martwego `getElement`** (np. `return uiElements[name]` bez definicji → zawsze nil).
- **Nigdy `self:render()` w callbackach on*Changed** → bounce kontrolek. Aktualizuj tylko docelowe pola.
- `setValue('value', x, true)` (3. arg = silent) ustawia kontrolkę bez wyzwalania jej callbacku.
- Nie nadawaj metodzie i polu tej samej nazwy (`self.foo` przesłoni `CustomDevice:foo()`).
- Limit `max_execution_time` (np. 30 s) — callbacki/poll trzymaj lekkie, inaczej BAN.

## 2. Dostęp do urządzeń (kontenery klasowe)
`wtp[id]` (przewodowe WTP), `sbus[id]` (SBUS), `tech[id]` (TECH RS), `virtual[id]`, `slink[id]`, `modbus[id]`,
oraz `*_parent_device[id]`.
- ⚠️ **`device_selector` → `el:getValue("associations.selected")`** (ścieżka Z KROPKĄ) zwraca **gotowe UCHWYTY urządzeń** — wołaj na nich wprost `dev:call/:setValue/:getValue`; iteruj `pairs()`, długość `#`, pierwszy `[1]`. NIE zwraca `{class,id}` do ręcznego mapowania na `wtp[id]`/`virtual[id]`. Zły wzorzec (`getValue("associations")` + `.selected` + własny mapper) = **pusta lista, ciche „nie steruje wybranym", `error_counter=0`** (pętla po 0 elementach nie rzuca). JSON z REST pokazuje `{class,id}` — to inna reprezentacja niż Lua! (patrz [[sinum-device-selector-types]])
- **Przekaźnik:** `dev:call("turn_on")` / `dev:call("turn_off")` / `dev:call("toggle")`; stan `dev:getValue("state") == true`.
- **Czujnik:** `dev:getValue("temperature")` (w 0.1 °C → /10). Sentinel braku danych (np. −32768) — filtruj.
- **Parametry/komendy:** `dev:setValue("blockade", true)` (zawór `common_valve`/obieg: blokada = obieg wyłączony), `dev:call("set_target_temperature", 244)`, `dev:call("open", 55)`.
- **Termostat wirtualny — tryb on/off:** `dev:call("set_mode","off"|"heating"|"cooling")` **albo** `dev:setValue("mode", …)` — **oba działają** (przykład TECH używa `setValue` z gardą `if dev:getValue("mode_mutable")`). ⚠️ Objaw „nie steruje termostatem" zwykle NIE wynika z metody zapisu, tylko z **pustego odczytu selektora** (patrz punkt o `associations.selected`) — najpierw sprawdź, ile urządzeń realnie zwraca selektor.
- **Termostat — harmonogram:** `dev:call("enable_schedule_mode")` = idź wg SWOJEGO przypisanego harmonogramu; `dev:call("enable_constant_mode", target_0_1C)` = trzymaj stałą zadaną (ignoruj harmonogram). Tak się **włącza/wyłącza** harmonogram bez zmieniania przypisań. (Przypisanie to osobna rzecz: `schedule[id]:setValue("associations.thermostats", {uchwyty})`, `{}` = odepnij wszystkie.)
- **Głowica grzejnikowa** `radiator_actuator`: `dev:call("open", 0..100)` (%), property `opening`/`opening_minimum`/`opening_maximum`/`emergency_opening`. ⚠️ Gdy głowica jest przypisana do termostatu, termostat ją zaraz przymknie — na czas wymuszenia odbierz mu sterowanie: `thermostat:setValue("radiator_control.use_for_heating", false)` i **pamiętaj przywrócić `true`**.
- Obieg i-3 (kontener `container_name==1290`): `dev:setValue("parameters.811.value", 1)` = tryb letni ON / `0` = grzanie.
- **Zmiana wykryta:** `dev:changedValue("state")` (zwraca true gdy zmieniło się od ostatniego odczytu).
- **Opóźnione:** `dev:setValueAfter("state", false, 30)`; `dev:call("enqueue_action", { type="parameter", param_or_command="state", argument=true, … })`.

## 3. Zdarzenia
`onEvent(event)` wołane dla wszystkich zdarzeń; rozgałęziaj:
```lua
if dateTime:changed() then … end           -- tyka co minutę (poll)
if weather:changed() then … end            -- zmiana danych pogody
if wtp[1]:changedValue("state") then … end -- zmiana stanu konkretnego urządzenia
if event and event.type == "sunrise" then … end  -- sunrise/sunset/weather_state_changed/weather_partial_update…
```
`event.type` m.in.: `wtp sbus slink tech virtual sunrise sunset weather_state_changed weather_partial_update timer schedule variable`.

## 4. Timery (krytyczna pułapka)
`setTimeout(fn, sekundy, arg)` → zwraca ID; `clearTimeout(id)`.
- **`setTimeout` gubi `self` i zmienne lokalne.** Przekazuj kontekst przez `arg` (tabela), a używane obiekty/funkcje/ID trzymaj w **zmiennych globalnych**. ID tickera w globalnej (do `clearTimeout`).
```lua
_tick_id = nil
function _tick(ctx) ctx.remaining = ctx.remaining - 1
  if ctx.remaining > 0 then _tick_id = setTimeout(_tick, 1, ctx) else ctx.akcja() end end
function CustomDevice:start(s, akcja) _tick_id = setTimeout(_tick, 1, {remaining=s, akcja=akcja, dev=self}) end
```

## 5. Pogoda — pełne API
`weather:getValue("available"|"enabled"|"access_type"|"city_name"|"sunrise"|"sunset")`,
`weather:current()`, `weather:hourly()` (tabela godzin), `weather:daily()` (dni), `weather:changed()`.
Obiekt pogody: `timestamp() weather() weatherId() temperature() feelsLikeTemperature() humidity() pressure()
windSpeed() windGust() windDegrees() rain() snow() cloudCoverage() precipitationProbability() uvIndex()
solarIrradiance() solarEnergy()`. Dzienny dodatkowo: `minTemperature() maxTemperature()`.
Jednostki: temp 0.1 °C, wiatr 0.1 km/h, ciśnienie hPa, opady 0.1 mm/h, UV 0.1, irr. 0.1 W/m², energia 0.1 MJ/m².
- **STREFA CZASU:** `timestamp()` to „unix w czasie lokalnym" — formatuj `os.date("!%H:%M", ts)` (flaga UTC), inaczej podwójne przesunięcie. Realny czas: `os.date("%H:%M")`.
- ⚠️ **WSCHÓD/ZACHÓD:** `weather:getValue("sunrise"/"sunset")` na firmware 1.22 **zwraca nil** (widget pokazuje „—"). Do godzin słońca używaj **globalnych obiektów** `sunrise`/`sunset`: `string.format("%02d:%02d", sunrise:hour(), sunrise:minute())` (patrz sekcja 6). Dopisz `sunrise`/`sunset` do `read_globals` w `.luacheckrc`.
- `weather()` bywa złożone („Rain, Partially cloudy") → ikona/opis **po słowach kluczowych** (priorytet opadów), nie exact-match. `weatherId()` daje stabilny enum.

## 6. Statystyki, powiadomienia, pamięć, czas
- **`statistics:addPoint("seria", wartość, unit.X)`** — **zawsze z `unit`** (`unit.celsius_x10`, `unit.bool_unit`, `unit.relative_humidity`, `unit.null`…). Brak `unit` = **BAN**. Wykresy widać w zakładce Statystyki/Energia (custom device nie ma elementu „wykres"). Zapytania: `statistics:query{ device=…, property="humidity", … }`.
- **`notify:info(tytuł, treść)` / `notify:error(...)`** — powiadomienia push do aplikacji SINUM (nie SMS/e-mail).
- **`variable[N]`** — trwała pamięć (NVM): `variable[1]:getValue()`, `:setValue(x)`, `:changedValue()`. Do agregatów tydzień/miesiąc, liczników między restartami.
- **`os.time()` / `os.date(...)`** — czas lokalny centrali (zwykłe formatowanie). `utils.time:toISO(ts, …)`, `utils.table:forEach(...)`. Globale `sunrise/sunset/dawn/dusk`: `sunrise:hour()`, `:minute()`, `:timeOfDay()`.

## 6b. Harmonogramy (`schedule[id]`)
Globalny kontener `schedule[id]` (jak `wtp`). Typ przez `getValue("type")`: `thermal`, `temperature_curve`, `relay_control`. Custom device **odczytuje wynik** dowolnego harmonogramu (nie musi być przypisany) i stosuje go we własnej logice. Reaguj na zdarzenie **`schedule_state_changed`** lub poll 60 s; `schedule[id]:changed()` / `:changedValue("prop")`.
- **`thermal`** — zadana wg pory dnia (bloki `start`/`end` w minutach + `target_temperature`, per dzień tygodnia) + `fallback`. Odczyt: `schedule[id]:getValue("current_target_temperature")` (0.1 °C). ⚠️ **Zakres tylko 5–35 °C** (termostat/pokój) — NIE nadaje się na zadaną CO/CWU wody (~45–55 °C); na nią zrób **własne okno czasowe** w widgecie (suwak nastawy + godziny od/do).
- **`temperature_curve`** — krzywa pogodowa (punkty `outdoor_temperature → target_temperature`, interpolacja). `current_target_temperature` (zakres −50…120 °C — pasuje na wodę), `outdoor_temperature_override` (30 min), `target_temperature_correction`. Może liczyć z czujnika zamiast pogody.
- **`relay_control`** — ON/OFF wg czasu (bloki per dzień + `control_policy`: `continuous` nadpisuje ręczne, `once_at_change` tylko na starcie). Odczyt: `schedule[id]:getValue("current.state")` → bool lub `nil` (dzień wyłączony). Wzorzec „harmonogram wyłączeń": `state==false` ⇒ wyłącz, `true/nil` ⇒ dozwolone.
- Zmiana: `schedule[id]:setValue("points"|"friday"|"associations.thermostats", …)` — w blokach klucz `end` escape’uj `['end']` (słowo kluczowe Lua). Wybór harmonogramu w GUI: element **`schedule_selector`** → [[sinum-widgets]]. Dopisz `schedule` do `read_globals` w `.luacheckrc`.

## 7. Klient HTTP (integracje, np. AI/REST)
Komponent typu `http_client` (dodany w zakładce Integracje, nagłówki/URL w konfiguracji). W kodzie:
```lua
local c = self:getComponent("nazwa_klienta")
if c ~= nil then
  c:onMessage(function(status, body, url, headers) … end)  -- obsługa odpowiedzi w onEvent
  c:POST("https://…"); c:contentType("application/json"); c:body(payload); c:send()
end
```
Brak biblioteki JSON → parsowanie przez `string.match` (np. `body:match('"text"%s*:%s*"(.-[^\\])"')`). Escape ręczny.

## 8. luacheck (bramka jakości)
`.luacheckrc`: `std="lua53"`; `read_globals = { wtp, sbus, tech, virtual, weather, variable, statistics, dateTime, notify, unit, utils, http_server, setTimeout, clearTimeout, … }`; `globals = { "CustomDevice" }`; `allow_defined_top=true`. Globalne funkcje/zmienne (do setTimeout) definiuj na top-level. Audyt: 0 `self:render()` w callbackach, brak duplikatów `function CustomDevice:*`, każdy `on_change/on_press` ma metodę, `addPoint` zawsze z `unit`.

## 9. Najczęstsze pułapki (skrót)
- setTimeout gubi self/lokalne → globalne/arg. · `addPoint` bez `unit` = ban. · `self:render()` w callbacku = bounce.
- Nadpisanie `CustomDevice` / martwy `getElement` = sterownik nie działa (błędy starych urządzeń 18/26).
- Strefa czasu pogody (`os.date("!…")`). · Sentinel czujnika (−32768) → filtruj. · `enabled=true` wymagane.
- Złożony opis pogody → ikony po słowach kluczowych.
