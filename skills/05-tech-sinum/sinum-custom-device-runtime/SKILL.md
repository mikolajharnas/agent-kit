---
name: sinum-custom-device-runtime
description: >
  Pułapki runtime, trwałości stanu i wdrożeń custom device TECH SINUM odkryte w boju:
  stan NIE przeżywa między pollami (variable[] albo wartości elementów jako NVM),
  onInit NIE odpala się przy hot-swapie kodu (rejestruj callbacki w onEvent),
  statistics:query BEZ znacznika czasu na punkt (tylko agregaty), serializacja stanu
  (%.7g ucina timestampy — używaj %.0f), builder pełnego rebuildu kasuje selektory
  i suwaki (zachowuj z GET), oraz debug „nie zapisuje/nie liczy" (sprawdź realne
  wartości configu — porzucone pole routuje logikę w martwą gałąź). Towarzyszące:
  [[sinum-lua-language]], [[sinum-widgets]], [[sinum-remote-deploy]].
---

# SINUM Custom Device — pułapki runtime i trwałości

Twardo zdobyta wiedza (urządzenie 40 „Badanie budynku", estymator z trwałym stanem).
Uzupełnia [[sinum-lua-language]] (API) i [[sinum-remote-deploy]] (wdrażanie).

## 1. Stan NIE przeżywa między pollami
Manual str. 49: *„Variables defined in the script are not preserved between calls."*
Zmienne skryptu, lokalne i globalne, oraz pola na `self` **giną** między cyklami `onEvent`.
Każdy stan, który ma akumulować (liczniki, estymator, kotwica czasu), trzymaj w:
- **`variable[N]`** (NVM; typy `bool/int/string/table`), albo
- **wartościach elementów widgetu** (też trwałe — patrz §3).

Wzorzec na każdy poll: **wczytaj stan → 1 krok → zapisz stan**.

## 2. `onInit` NIE odpala się przy hot-swapie kodu (PATCH)
Po wdrożeniu nowego `lua` (PATCH + config-finished) urządzenie **kontynuuje `onEvent`**,
ale `onInit` **się nie wykonuje** (obserwacja: log startowy z onInit nie pojawił się,
a zegar w onEvent tykał). Konsekwencja: rejestracje robione tylko w onInit (np.
`statistics:onQueryResult(...)`) po redeployu nie działają.
**Fix:** rejestruj callbacki TEŻ w `onEvent` (idempotentnie, w `pcall`), nie tylko w onInit.
**Powiązane:** jeśli sterownik zapisuje do urządzeń tylko na **TRANZYCJI** stanu (a nie co poll), to po
deployu samego kodu (`-LuaOnly`, stan bez zmian) NIC się nie przeliczy — onInit nie ruszył, tranzycji nie
było. Wymuś jednorazowo zmianą w configu (callback woła apply) albo poczekaj na realną tranzycję.

## 3. Trwałość w wartościach elementów (NVM bez tworzenia variable[])
Wartości elementów **są trwałe** — widać je w GET urządzenia i przeżywają restart.
Można ich użyć jako magazynu (np. zserializowany stan estymatora), zero konfiguracji.
- **PATCH** utrwala wartość pola `text` do **co najmniej 400 znaków** (sprawdzone).
- **Pisz tylko do elementów renderowanych** (widoczne; sekcja rozwinięta, NIE-zwijalna —
  mirror działającej sekcji). Magazyn trzymaj w sekcji rozwiniętej; do zwiniętych/ukrytych
  pól runtime `setValue` bywa zawodne (nie testowane do końca — bądź konserwatywny).
- **Flaga `silent` (3. arg `setValue('value', x, true)`) NIE utrwala wartości** — pomija
  zapis. Do magazynu używaj zwykłego `setValue('value', x)` (pole bez `on_change` → brak bounce).
- Długi stan tnij na kawałki (~64 zn.) i sklejaj przy odczycie — konserwatywnie, bo limit
  *runtime* `setValue` długiego stringa nie został u nas jednoznacznie ustalony.

## 4. Serializacja stanu: `%.7g` UCINA timestampy
`string.format("%.7g", t)` na uniksowym czasie (~1.78e9, 10 cyfr) zaokrągla do 7 cyfr =
do **najbliższego ~1000 s** → `elapsed = now - t_anchor` losowe → warunki czasowe się psują
(kroki nie zapadają, log martwy). Duże liczby całkowite (timestampy) serializuj **`%.0f`/`%d`**,
floaty mogą zostać `%.7g`. Wersjonuj format stanu tagiem (np. `BTI2`) — zmiana układu = stary stan odrzucony i reinit.

## 5. `statistics:query` — BEZ znacznika czasu na punkt
Wynik to `{id, class, name, unit, value}` — **brak `timestamp`**. Parametry zapytania to tylko
`time_start`/`time_end` (UTC). Nadaje się do **agregatów w oknie** (średnie), NIE do dynamiki
`dT/dt`. Do szeregów czasowych próbkuj sam i trzymaj stan (§1–3). Patrz [[sinum-statistics-query]].

## 6. Builder pełnego rebuildu KASUJE konfigurację użytkownika
Wysyłka pełnej tablicy `elements` resetuje **selektory urządzeń** (associations.selected → [])
i **wartości suwaków/switchy/combo** do defaultów buildera → wymazuje przypisane czujniki i ustawienia.
**Fix:** przed PATCH wczytaj bieżące `elements` z GET i **przepisz**: `associations.selected`
device_selektorów oraz `value` slider/switch/combo/text-input (po `name`). Dla pól-magazynu stanu
(`state_*`) też zachowuj wartość — inaczej każdy redeploy kasuje naukę.
**Najprościej, gdy poprawka jest TYLKO w kodzie:** PATCH samego `{ "lua": … }` (builder `-LuaOnly`) —
nie wysyłaj `elements`, więc wszystkie wybory i wartości zostają. Pełny rebuild (z przepisaniem z GET)
rób tylko gdy zmieniasz strukturę GUI.

## 7. Debug „nie zapisuje / nie liczy" → sprawdź REALNE wartości configu
Najdroższy błąd sesji: porzucone `set_var_id=1` w GUI kierowało zapis stanu do `variable[1]`
(nieistniejącej) → `pcall` łykał błąd → stan nigdzie nie lądował → wieczne „n=1", zero efektu.
Wszystkie hipotezy (limit długości, ukryte/zwinięte sekcje) były **zafałszowane** tym jednym polem.
**Zasada:** gdy trwałość/logika nie działa, **NAJPIERW zrób GET i obejrzyj rzeczywiste wartości
elementów/configu** (nie zakładaj). `pcall` wokół zapisu maskuje błąd routingu — usuń go na czas debugu
albo loguj wynik. Footgun-pola, które już nie są potrzebne — **usuń z GUI**, nie zostawiaj.

## 7b. Diagnostyka BEZ logów i bez dostępu do API (wdrożenie u klienta)
Gdy sterownik działa na obcej centrali (brak VPN, brak REST, „mamy tylko logi"), jedynym kanałem
jest **sam widget**. Zasady, które uratowały debugowanie głowic:
- **`pcall` połyka wszystko** — przy każdej operacji na urządzeniach licz `znalezione / ok / błąd`
  i zapisuj do widocznego elementu tekstowego **razem z treścią pierwszego błędu**. To właśnie
  komunikat `Reason: … already managed by the virtual thermostat` wskazał przyczynę; bez tego
  wszyscy zgadywali.
- ⚠️ **Ustawiony timer/flaga NIE dowodzi, że coś zadziałało.** Kod ustawiał licznik czasu niezależnie
  od tego, czy znalazł choć jedno urządzenie → „u mnie timer wystartował" mylnie sugerowało sukces.
  Zawsze raportuj **liczbę faktycznie znalezionych obiektów** (`n=0` to najważniejsza informacja).
- **Rozróżniaj błędy oczekiwane od realnych** (np. „managed by thermostat" to normalny tryb pracy,
  nie awaria) — inaczej `błąd 18` wywołuje fałszywy alarm.
- Log dwukanałowy: `print("[devNN] …")` → konsola SINUM, plus **ostatnie wpisy w elemencie tekstowym**
  (prepend + przycięcie do ~280 zn.) → widoczne w aplikacji bez dostępu do centrali.
- Weryfikując z PowerShella: ⚠️ `$_` wewnątrz `Where-Object` **przesłania** `$_` z zewnętrznego
  `ForEach-Object` → skrypt kontrolny pokaże puste wartości i zgłosi nieistniejący błąd.

## 8. Inne potwierdzone drobiazgi
- **Typy device_selector / jednostki:** `accepted_types=[]` = wszystkie; `heat_meter` ma `active_power`
  w **mW** (×1e-9 → kW!), `energy_meter`/`heat_pump` → `actual_power`/`electrical_power`. Lista czujników
  z `GET /api/v1/devices` → `data.wtp[]`/`data.sbus[]`… (pola `type`, `temperature` w 0.1 °C; sentinel −32768).
- **`label_text` suwaka > ~30 zn. = 422** „Parameter exceeds maximum range" (mylące — to nie zakres liczbowy).
- **Weryfikacja wdrożenia** dopasuj do STAŁEGO markera kodu (np. nagłówka), nie do tagu, który się zmienia.
- **Zmiana czujnika/configu** widać w widgecie dopiero po następnym pollu (kod aktualizuje pola co cykl).
