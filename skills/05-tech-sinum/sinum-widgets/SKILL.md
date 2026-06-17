---
name: sinum-widgets
description: >
  Tworzenie i edycja widgetów (GUI) custom device TECH SINUM przez API: model elements/widget/dialog,
  tworzenie NOWYCH elementów (bez device_id), typy i warianty (text/switcher/slider/combo_box/button/
  device_selector), układ (sekcje/rzędy/komórki, limit 3 komórek na rząd), selektory urządzeń
  (wtp/sbus relay/sensor zamiast stałych ID), widoczność (hidden_adjust), limity walidacji, builder
  PowerShell oraz wzorce UI (karty, tabele, krzywe suwakowe). Użyj przy budowie/zmianie widgetu SINUM,
  gdy „nie da się dodać elementu", 422 z layoutu, mojibake emoji, lub kontrolki znikają/wyskakują.
---

# SINUM — widgety (tworzenie i edycja GUI)

Budowa i modyfikacja interfejsu custom device. Towarzyszące: [[sinum-lua-language]], [[sinum-remote-deploy]].

## 1. Model GUI (niezależny od kodu)
- `elements[]` — definicje kontrolek. `widget.content[]` — widok główny. `dialog.content[]` — widok rozwijany. `config.content[]` — trzeci kontener. Każdy kontener: `{ content:[…], version:2 }`.
- **Spoiwo z kodem:** pole `on_change` (combo/slider/switcher/device_selector) lub **`on_press` (button)** = nazwa metody Lua; w kodzie `self:getElement('name')`.
- Edycja istniejących (value/label_text/visibility/on_change) przez PATCH `{elements:[…]}` działa od ręki.

## 2. Tworzenie NOWEGO elementu (kluczowe)
PATCH `{ name?, logo?, elements:[…WSZYSTKIE istniejące + nowy…], widget, dialog }`.
- **Nowy element BEZ pola `device_id`** — serwer je nadaje. Element z `device_id` o nieistniejącym `uuid` → 422.
- Wysyłaj **pełną tablicę `elements`** (nie deltę). `uuid` generuj po stronie klienta (GUID).
- UTF-8 bajty; szczegóły API: [[sinum-remote-deploy]].

## 3. Typy elementów i schemat
| type | kluczowe pola | callback | variant w layoucie |
|---|---|---|---|
| text | `value, font_size, font_weight, icon, text_id` | — | `text-default` (wartość) / `text-input` (etykieta-box) |
| switcher | `value(bool)` | `on_change` | `switch-default` |
| combo_box | `value(str), options:[{label,text_id,value}]` | `on_change` | `combo-box-default` |
| slider | `value, minimum, maximum, step, unit, label_text` | `on_change` | `slider-with-label` |
| button | `text` | **`on_press`** | `button-default` |
| device_selector | `accepted_classes, accepted_types, allow_multiple, associations.selected` | `on_change` | `device-selector-default` |

Wspólne: `enabled, name, uuid, visibility` (`visible`/`hidden_adjust`).

## 4. Układ (layout)
`content[]` = węzły: **`row`** (`cells:[…]`) lub **`section`** (`text` tytuł, `collapsible`, `collapsed_default`, `has_background`, `rows:[…]`).
- **`cell`**: `orientation` (`row`/`column`), `horizontal_alignment`/`vertical_alignment` (`start`/`center`/`end`), `elements:[{uuid, variant}]`.
- **LIMIT: max 3 komórki (cells) w jednym rzędzie** → inaczej „Parameter exceeds maximum range". Dziel na rzędy.
- Wzorzec „etykieta+wartość": komórka `column` z `[ {uuid,'text-input'} , {uuid,'text-default'} ]`.
- Sekcje z `has_background:true` = efekt „karty"; `collapsible:true, collapsed_default:true` = zwijane (na ustawienia).
- **`config.content`** to osobny kontener (rzadziej używany).

## 5. Limity i pułapki walidacji
- Max 3 komórki/rząd (wyżej). · `name` urządzenia bez znaków specjalnych (zob. [[sinum-remote-deploy]]).
- Pola liczbowe suwaka MUSZĄ być liczbą — `-20` w PowerShellu bywa stringiem → 422 (użyj `(-20)`/`[double]`).
- **Pola read-only** (np. `variant`) → 422 „Parameter is read only" — nie wysyłaj ich w PATCH; przy edycji elementów zachowuj `name/uuid/type/callback`.
- **Brak elementu „wykres"** — wykresy tylko przez `statistics:addPoint` (zakładka Statystyki). Natywny kafelek pogody ma wykres jako funkcję aplikacji, nieodtwarzalną w custom device.
- `logo`: `"kolton"`, `"blank"`… `icon`: zestaw **Font Awesome** (np. `"cloudy"`) — brak glifu „SINUM" (użyj badge tekstowego/emoji).

## 6. device_selector — wybór z listy zamiast stałych ID (zalecane)
```
accepted_classes=["wtp","sbus"], accepted_types=["relay"]      # lub ["temperature_sensor"]
associations.selected = [ {class, id} ]   # lub [] = brak wyboru (serwer-nadane uuid później)
```
W Lua: `local dev = self:getElement('sel'):getValue('associations.selected')` → obiekt; `dev:call("turn_on"/"turn_off")`, `dev:getValue("state"/"temperature")`, `dev:changedValue(...)`. Pozwala konfigurować wyjścia/czujniki bez `wtp[1]` w kodzie.

## 7. Widoczność (dynamiczna)
- `setValue('visibility','visible'|'hidden_adjust')` z Lua. `hidden_adjust` ukrywa i zwija miejsce.
- **Domyślne ukrycie ustaw w DEFINICJI elementu** (`visibility="hidden_adjust"`), inaczej po re-renderze kontrolka „wyskakuje" (render przywraca trwałą wartość).
- Po zmianie stanu (np. tryb, liczba pomp, cel pompy) **przeliczaj widoczność w callbacku** oraz w `onEvent` (po re-renderze).
- **Reset switcha do OFF musi też wyłączyć fizyczne wyjście** — nie zostawiać stanu z poprzedniego cyklu (gdy sterowanie aktywne).

## 8. Builder PowerShell (wzorzec)
- Funkcje `New-Text/Switch/Combo/Slider/Button/Selector` → pscustomobject; `New-Cell`/`New-Row`/`New-Section` budują layout (referencje `{uuid,variant}`).
- Powtarzalne elementy (np. 8 pomp) generuj **pętlą**, zbieraj do listy (ArrayList).
- ⚠️ `$EL`≡`$el` (case-insensitive) — lista i param różne nazwy. ⚠️ `.ps1` jako **UTF-8 z BOM** dla emoji/PL.
- ⚠️ **Pełny rebuild resetuje wartości** suwaków/combo — preferuj edycję przyrostową, gdy ustawienia mają zostać.
- Po PATCH → `config-finished`; sprawdź brak wiszących referencji (każdy `uuid` z layoutu istnieje w `elements`).

## 9. Wzorce UI (sprawdzone)
- **Krzywa suwakowa** (COP/pogodowa/grzewcza): N suwaków w punktach + interpolacja liniowa w Lua + clamp poza zakresem.
- **Tabela**: nagłówek + rzędy 3-kolumnowe (np. Godzina │ Wartość │ Wiatr).
- **Karty**: sekcje `has_background`; ustawienia w sekcjach zwijanych.
- **Etykiety dynamiczne** suwaka: `setValue('label_text', "Próg: 45°C")` w callbacku.
- **Emoji + polskie znaki** działają (UTF-8 bajty w PATCH; BOM w `.ps1`). Przy złożonych warunkach pogody dobieraj ikonę po słowach kluczowych.
- **Master „Sterowanie aktywne"** (podgląd) — patrz [[sinum-remote-deploy]].
