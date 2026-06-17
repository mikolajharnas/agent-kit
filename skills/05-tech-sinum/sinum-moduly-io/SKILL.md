---
name: sinum-moduly-io
description: >
  Karty i moduły sprzętowe TECH Sinum (WEJŚCIA, WYJŚCIA, OPOMIAROWANIE) do projektowania sterowania:
  katalog modułów I/O (KW-03m/10m/11m/12m/12-2m/15m, KW-04), konwerterów (KM-OT/KM-DALI), licznika energii
  (LE-3x230mb), modułów przekaźnikowych i strefowych (PS-*, PSZ-*, MB-04), przekaźników pomocniczych
  (PK-230/PK-24); typy sygnałów (binarne/NTC/0-10V/PWM/4-20mA/1-Wire/M-Bus/Modbus/OpenTherm), bilans I/O,
  obciążalność przekaźników, SBUS przewodowo vs WTP 868 MHz, rezerwa. Użyj przy doborze modułów Sinum i
  projektowaniu funkcjonalności sterowania (pompa ciepła, kocioł, strefy, pomiar energii) — ZANIM napiszesz
  kod Lua / widget.
version: 0.2
last_updated: 2026-06-17
source_basis: Karty katalogowe TECH Sinum (karty rozszerzeń, liczniki energii, moduły DIN) + raport moduly_sinum_raport.
---

# Skill: Moduły I/O i opomiarowanie TECH Sinum (projektowanie sterowania)

> Dobór SPRZĘTU (wejścia/wyjścia/pomiar). Po doborze: logika sterowania w [[sinum-lua-language]],
> GUI w [[sinum-widgets]], wdrożenie kodu w [[sinum-remote-deploy]], analiza dokumentacji projektowej
> w [[analiza-dokumentacji-hvac]]. W kodzie moduły adresujesz przez `wtp[id]`/`sbus[id]` lub `device_selector`.

## Cel skilla

Używaj tego skilla, gdy trzeba zaprojektować lub dobrać moduły Sinum do sterowania instalacją HVAC, zwłaszcza:

- pompą ciepła,
- kotłem gazowym,
- kotłem pelletowym / stałopalnym,
- pompami obiegowymi,
- siłownikami zaworów strefowych,
- zaworami mieszającymi,
- buforem, zasobnikiem CWU, cyrkulacją,
- licznikami energii,
- roletami, bramami i innymi urządzeniami wykonawczymi.

Skill ma prowadzić do doboru modułów według rzeczywistej liczby wejść, wyjść, typów sygnałów i sposobu komunikacji.

## Najważniejsza zasada

Nie dobieraj modułu „na oko”. Najpierw zrób bilans I/O:

1. Policz sygnały wejściowe.
2. Policz sygnały wyjściowe.
3. Rozdziel typy sygnałów.
4. Sprawdź zasilanie urządzeń wykonawczych.
5. Sprawdź obciążalność przekaźników.
6. Zostaw rezerwę minimum 15–30% wejść i wyjść.
7. Dopiero wtedy wybierz moduły.

Jeżeli brakuje danych, wypisz założenia i listę pytań. Nie zakładaj zgodności protokołów bez potwierdzenia w DTR danego urządzenia.

## Typy sygnałów, które trzeba rozróżniać

### Wejścia

- wejście binarne / dwustanowe,
- wejście napięciowe,
- wejście analogowe 0–10 V,
- wejście czujnika NTC,
- wejście 1-Wire,
- wejście z licznika energii / Modbus / M-Bus,
- sygnał alarmowy,
- sygnał pracy źródła,
- sygnał krańcówki,
- sygnał presostatu,
- sygnał przepływu,
- sygnał termostatu pokojowego.

### Wyjścia

- przekaźnik bezpotencjałowy / beznapięciowy,
- wyjście napięciowe 230 V,
- wyjście 24 V,
- wyjście 0–10 V,
- wyjście PWM,
- wyjście 4–20 mA,
- wyjście do pompy,
- styk NO-COM-NC do źródła ciepła,
- wyjście do siłownika termoelektrycznego,
- wyjście do bramy lub rolety.

## Katalog modułów Sinum

Poniższy katalog jest bazą doborową. Przed projektem wykonawczym sprawdź aktualność kart katalogowych producenta.

```yaml
modules:
  - id: KW-03m
    group: karta_rozszerzen
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: natynkowy
    inputs:
      binary: 1
      ntc: 1
    outputs:
      voltage_24v: 1
    use_when:
      - potrzeba jednego wejścia binarnego
      - potrzeba jednego czujnika NTC
      - potrzeba prostego wyjścia 24 V
    avoid_when:
      - potrzeba wielu przekaźników
      - potrzeba sygnałów 0-10 V, PWM albo 4-20 mA

  - id: KW-10m
    group: karta_rozszerzen
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    inputs:
      binary: 2
      ntc: 1
    outputs:
      relay: 2
      analog_0_10v: 2
      pwm: 2
      current_4_20ma: 1
    relay_load: 0.5 A
    use_when:
      - sterowanie sygnałem 0-10 V
      - sterowanie PWM
      - sterowanie 4-20 mA
      - potrzeba kilku wyjść analogowych do HVAC
    examples:
      - zadawanie prędkości pompy obiegowej 0-10 V
      - zadawanie sygnału mocy, jeśli urządzenie zewnętrzne przyjmuje 0-10 V
      - odczyt 1 temperatury NTC i 2 sygnałów dwustanowych

  - id: KW-11m
    group: karta_rozszerzen_wejsc
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    inputs:
      binary: 4
      ntc: 4
      one_wire: 1
      analog_0_10v: 2
    outputs: {}
    use_when:
      - potrzeba wielu wejść pomiarowych
      - trzeba zebrać temperatury NTC
      - trzeba zebrać sygnały 0-10 V
      - trzeba zebrać wejścia binarne bez sterowania wyjściami
    avoid_when:
      - trzeba sterować pompą, kotłem albo zaworem

  - id: KW-12m
    group: karta_rozszerzen_wejsc
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    inputs:
      binary: 4
      ntc: 8
    outputs: {}
    use_when:
      - dużo czujników temperatury NTC
      - monitoring bufora, CWU, zasilania, powrotu, sprzęgła i obiegów
    avoid_when:
      - potrzebne wyjścia sterujące

  - id: KW-12-2m
    group: karta_rozszerzen_wejsc
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    inputs:
      binary: 12
    outputs: {}
    use_when:
      - wiele styków bezpotencjałowych
      - krańcówki, presostaty, alarmy, stany pracy, styki pomp i kotłów
    avoid_when:
      - potrzebne wejścia temperatury lub wyjścia sterujące

  - id: KW-15m
    group: karta_wejsc_wyjsc
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    inputs:
      binary: 1
      ntc: 2
    outputs:
      relay: 9
      analog_0_10v: 1
      mbus: 1
      voltage_24v: 1
    aux_supply:
      voltage: 24 V
      power: 30 W
    use_when:
      - potrzeba wielu przekaźników
      - trzeba zasilić centralę lub siłowniki 24 V
      - potrzebny M-Bus do licznika
      - potrzebne jedno wyjście 0-10 V
    examples:
      - większa kotłownia z kilkoma pompami i zaworami
      - sterowanie wieloma odbiornikami przekaźnikowymi z rezerwą

  - id: KW-04
    group: karta_wejsc_wyjsc_bezprzewodowa
    communication: WTP 868 MHz bezprzewodowo
    supply: 230 V AC
    mounting: DIN
    inputs:
      voltage: 2
    outputs:
      relay: 2
    relay_load:
      ac1: 5 A
      led: 200 W
      dc1: 2 A / 30 V
    use_when:
      - potrzebne 2 wejścia napięciowe i 2 wyjścia przekaźnikowe
      - brak możliwości prowadzenia przewodu SBUS
    avoid_when:
      - wymagana komunikacja przewodowa
      - środowisko utrudnia niezawodną komunikację radiową

  - id: KM-DALI
    group: konwerter
    communication: Modbus-DALI
    function: konwerter DALI na Modbus
    requirements:
      - dedykowany zasilacz DALI
    use_when:
      - integracja oświetlenia DALI z Sinum

  - id: KM-OT
    group: konwerter
    communication: Modbus-OpenTherm
    function: konwerter OpenTherm na Modbus
    use_when:
      - urządzenie grzewcze obsługuje OpenTherm
      - centrala Sinum ma sterować lub komunikować się z urządzeniem OpenTherm
    warning:
      - sprawdź zgodność konkretnego kotła lub pompy ciepła z OpenTherm

  - id: LE-3x230mb
    group: licznik_energii
    type: trójfazowy_dwukierunkowy_licznik_energii
    certification: MID
    communication: RS485 izolowany (ochrona przepieciowa), Modbus-RTU do 9600 bps
    accuracy: moc czynna klasa 0.5S, napiecie/prad klasa 0.2
    supply: 3x230/380 V AC
    temp_range: -25..70 C
    dimensions: 72 x 90 x 63.5 mm
    current_range: 0.25-5(63) A
    measures:
      - napięcie każdej fazy
      - prąd każdej fazy
      - moc czynna
      - moc bierna
      - moc pozorna
      - współczynnik mocy
      - częstotliwość
      - energia czynna dwukierunkowa
      - energia bierna dwukierunkowa
      - energia bierna czterokwadrantowa
    use_when:
      - monitoring zużycia pompy ciepła
      - monitoring produkcji lub poboru energii
      - logika zarządzania energią

  - id: PSZ-02
    group: przekaznik_bezprzewodowy_roletowy
    communication: WTP 868 MHz
    supply: 230 V AC
    mounting: DIN
    inputs:
      wall_switch: optional
    outputs:
      relay: 2
    relay_load: 0.5 A
    function: sterowanie roletą góra/dół

  - id: PS-02
    group: przekaznik_bezprzewodowy_beznapieciowy
    communication: WTP 868 MHz
    supply: 230 V AC
    mounting: DIN
    inputs:
      bell_switch: optional
    outputs:
      relay: 2
    relay_load:
      ac1: 5 A
      led: 200 W
      dc1: 2 A / 30 V
    use_when:
      - dwa obwody oświetlenia lub zasilania
      - proste zdalne sterowanie dwoma odbiornikami

  - id: PS-08
    group: przekaznik_bezprzewodowy_beznapieciowy
    communication: WTP 868 MHz
    supply: 230 V AC
    mounting: DIN
    outputs:
      relay: 8
    relay_load:
      ac1: 5 A
      led: 200 W
      dc1: 2 A / 30 V
    use_when:
      - osiem obwodów bezpotencjałowych
      - sterowanie oświetleniem lub zasilaniem przez przekaźniki

  - id: PS-08-230
    group: modul_bezprzewodowy_napieciowy
    communication: WTP 868 MHz
    supply: 230 V AC
    mounting: DIN
    outputs:
      voltage_230v: 8
    output_load: 0.3 A
    use_when:
      - sterowanie do 8 siłowników termoelektrycznych 230 V
      - ogrzewanie strefowe bez przewodowego SBUS
    avoid_when:
      - odbiorniki mają większy prąd niż 0.3 A na wyjście

  - id: PS-10-230
    group: sterownik_strefowy_bezprzewodowy
    communication: WTP 868 MHz
    supply: 230 V AC
    mounting: DIN
    inputs:
      binary: 2
    outputs:
      actuator_230v: 8
      pump_230v: 1
      heat_source_dry_contact_no_com_nc: 1
    output_load: 0.3 A
    use_when:
      - ogrzewanie strefowe
      - siłowniki termoelektryczne 230 V
      - jedna pompa obiegowa stref
      - trzeba dać sygnał zapotrzebowania do kotła lub pompy ciepła
    notes:
      - producent wskazuje obsługę do około 50 siłowników termostatycznych

  - id: MB-04
    group: modul_bezprzewodowy_bramowy
    communication: WTP 868 MHz
    supply: 24 V AC
    mounting: DIN
    inputs:
      binary: 2
    outputs:
      relay: 2
    relay_load: 2 A AC1 / 2 A DC1
    use_when:
      - sterowanie bramą
      - odczyt krańcówek
      - dwa sygnały wejściowe i dwa wyjścia przekaźnikowe

  - id: PSZ-02m
    group: przekaznik_przewodowy_roletowy
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    inputs:
      wall_switch: optional
    outputs:
      relay: 2
    relay_load: 0.5 A
    use_when:
      - przewodowe sterowanie roletą góra/dół

  - id: PS-02m
    group: przekaznik_przewodowy_beznapieciowy
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    inputs:
      bell_switch: optional
    outputs:
      relay: 2
    relay_load:
      ac1: 5 A
      led: 200 W
      dc1: 2 A / 30 V
    use_when:
      - dwa obwody oświetlenia lub zasilania w instalacji przewodowej

  - id: PS-06m
    group: przekaznik_przewodowy_beznapieciowy
    communication: Sinum SBUS przewodowo
    supply: 24 V DC
    mounting: DIN
    outputs:
      relay: 6
    relay_load:
      ac1: 5 A
      led: 200 W
      dc1: 2 A / 30 V
    use_when:
      - sześć obwodów bezpotencjałowych po SBUS

  - id: PS-08m-230
    group: modul_przewodowy_napieciowy
    communication: Sinum SBUS przewodowo
    supply: 230 V AC
    mounting: DIN
    outputs:
      voltage_230v: 8
    output_load: 0.3 A
    use_when:
      - przewodowe sterowanie 8 siłownikami lub odbiornikami 230 V

  - id: PS-10m-230
    group: sterownik_strefowy_przewodowy
    communication: Sinum SBUS przewodowo
    supply: 230 V AC
    mounting: DIN
    inputs:
      binary: 2
    outputs:
      actuator_230v: 8
      pump_230v: 1
      heat_source_dry_contact_no_com_nc: 1
    output_load: 0.3 A
    use_when:
      - przewodowe ogrzewanie strefowe
      - siłowniki 230 V
      - pompa obiegowa stref
      - sygnał zapotrzebowania do źródła ciepła

  - id: PK-230
    group: przekaźnik_pomocniczy
    communication: none
    supply: 230 V AC
    outputs:
      relay: 1
    relay_load: 16 A
    use_when:
      - trzeba załączać większy odbiornik 230 V
      - wyjście modułu Sinum ma zbyt małą obciążalność
      - potrzebny przekaźnik pomocniczy / separacja

  - id: PK-24
    group: przekaźnik_pomocniczy
    communication: none
    supply: 24 V DC
    outputs:
      relay: 1
    relay_load: 16 A
    use_when:
      - trzeba załączać większy odbiornik przez sygnał 24 V
      - potrzebny przekaźnik pomocniczy / separacja
```

## Procedura doboru modułów

### Krok 1: Zbierz dane instalacji

Wypisz urządzenia i sygnały:

```yaml
project_inputs:
  heat_sources:
    - pompa_ciepla
    - kociol_gazowy
    - kociol_pelletowy
  hydraulic_devices:
    - pompy_obiegowe
    - zawory_mieszajace
    - siłowniki_strefowe
    - bufor
    - cwu
  measurements:
    - temperatury_NTC
    - sygnały_alarmowe
    - sygnały_pracy
    - licznik_energii
  user_control:
    - termostaty
    - aplikacja_Sinum
    - harmonogramy
```

### Krok 2: Zrób bilans wejść

Dla każdego sygnału wejściowego podaj:

- nazwa sygnału,
- typ sygnału,
- napięcie lub rodzaj styku,
- czy sygnał jest krytyczny,
- gdzie fizycznie znajduje się urządzenie.

Przykład:

```yaml
input_balance:
  binary:
    - alarm_pompy_ciepla
    - praca_kotla_gazowego
    - presostat_instalacji
  ntc:
    - bufor_gora
    - bufor_dol
    - cwu
    - zasilanie_co
    - powrot_co
  analog_0_10v:
    - sygnal_zapotrzebowania_zewnętrznego
```

### Krok 3: Zrób bilans wyjść

Dla każdego wyjścia podaj:

- co steruje,
- czy ma być styk bezpotencjałowy,
- czy ma być 230 V,
- wymagany prąd odbiornika,
- czy potrzebny przekaźnik pomocniczy,
- czy ma działać w automatyce bezpieczeństwa.

Przykład:

```yaml
output_balance:
  dry_contact:
    - start_stop_pompy_ciepla
    - sygnal_zapotrzebowania_kociol_gazowy
  voltage_230v:
    - pompa_obiegowa_co
    - pompa_cwu
    - cyrkulacja
  analog_0_10v:
    - pompa_obiegowa_pwm_0_10v
```

### Krok 4: Dobierz typ komunikacji

Stosuj przewodowy SBUS, gdy:

- projekt jest nowy lub jest dostęp do prowadzenia kabli,
- kotłownia ma być stabilna i serwisowalna,
- sterujesz krytycznymi urządzeniami HVAC,
- moduły są w jednej rozdzielnicy.

Stosuj WTP 868 MHz, gdy:

- budynek istnieje i trudno prowadzić przewody,
- sterowanie dotyczy mniej krytycznych obwodów,
- moduł jest blisko centrali i warunki radiowe są dobre,
- akceptujesz zależność od łączności radiowej.

### Krok 5: Dobierz moduły

Reguły praktyczne:

- Do wielu temperatur NTC wybieraj KW-12m.
- Do wielu wejść dwustanowych wybieraj KW-12-2m.
- Do sygnałów 0-10 V, PWM i 4-20 mA wybieraj KW-10m.
- Do większej liczby przekaźników i 24 V wybieraj KW-15m.
- Do stref grzewczych 230 V wybieraj PS-10 230 albo PS-10m 230.
- Do 8 stref 230 V bez pompy i styku źródła wybieraj PS-08 230 albo PS-08m 230.
- Do bramy i krańcówek wybieraj MB-04.
- Do rolet wybieraj PSZ-02 albo PSZ-02m.
- Do dużych odbiorników dawaj przekaźnik pomocniczy PK-230 lub PK-24.
- Do pomiaru energii wybieraj LE-3x230mb.
- Do OpenTherm wybieraj KM-OT, ale tylko po potwierdzeniu zgodności urządzenia.

## Wzorzec odpowiedzi projektowej

Gdy użytkownik prosi o projekt sterowania, odpowiadaj w tej strukturze:

1. Założenia.
2. Bilans wejść.
3. Bilans wyjść.
4. Dobór modułów Sinum.
5. Rezerwa I/O.
6. Uwagi do obciążalności przekaźników.
7. Uwagi do komunikacji SBUS/WTP.
8. Logika pracy.
9. Lista pytań brakujących.

### Szablon tabeli doboru

| Funkcja | Sygnał | Typ | Moduł | Kanał | Uwagi |
|---|---|---|---|---|---|
| Start PC | wyjście zapotrzebowania | bezpotencjałowe | PS-10m 230 | NO-COM-NC | sprawdzić DTR PC |
| Pompa CO | wyjście pompy | 230 V | PS-10m 230 | POMPA | sprawdzić prąd |
| Bufor góra | temperatura | NTC | KW-12m | NTC 1 | lokalizacja na tulei |

## Typowe konfiguracje HVAC

### 1. Pompa ciepła + jeden obieg + bufor + CWU

Najpierw sprawdź:

- czy pompa ciepła potrzebuje tylko styku start/stop,
- czy ma wejście SG Ready,
- czy ma alarm bezpotencjałowy,
- czy wymaga 0-10 V,
- czy pompy obiegowe są 230 V czy sterowane 0-10 V/PWM.

Możliwy dobór:

```yaml
modules:
  - KW-12m: temperatury bufora, CWU, zasilania i powrotu
  - PS-02m lub KW-15m: przekaźniki do pomp / sygnałów
  - KW-10m: sygnały 0-10 V lub PWM, jeśli wymagane
  - LE-3x230mb: pomiar energii PC
```

### 2. Pompa ciepła + kocioł gazowy jako szczyt

Zwróć uwagę na separację sterowania źródeł i logikę antyrównoczesną.

Możliwy dobór:

```yaml
outputs:
  - zgoda_na_prace_PC
  - zgoda_na_prace_kotla
  - pompa_obiegowa_glowna
  - pompa_ladowania_bufora
inputs:
  - temperatura_bufor_gora
  - temperatura_bufor_dol
  - alarm_PC
  - praca_kotla
recommended_modules:
  - KW-12m
  - KW-15m
  - LE-3x230mb
```

### 3. Ogrzewanie strefowe podłogowe 230 V

Jeżeli jest wiele siłowników termoelektrycznych, podstawowym modułem jest PS-10 230 lub PS-10m 230.

```yaml
wireless_variant:
  - PS-10-230
wired_variant:
  - PS-10m-230
features:
  - 8 wyjść na siłowniki 230 V
  - 1 wyjście na pompę
  - 1 styk NO-COM-NC na źródło ciepła
  - 2 wejścia binarne
```

### 4. Same strefy bez sterowania źródłem

Jeżeli potrzeba tylko 8 wyjść 230 V na siłowniki, bez wyjścia pompy i styku źródła:

```yaml
wireless_variant:
  - PS-08-230
wired_variant:
  - PS-08m-230
```

### 5. Kotłownia z wieloma pompami i sygnałami

Jeżeli jest kilka pomp, zaworów i sygnałów pracy/alarmu, preferuj KW-15m plus moduły wejść.

```yaml
recommended_modules:
  - KW-15m: przekaźniki, 0-10 V, M-Bus, 24 V
  - KW-12m: temperatury
  - KW-12-2m: alarmy i stany pracy
  - PK-230/PK-24: przekaźniki pomocnicze dla większych odbiorników
```

## Zasady bezpieczeństwa i serwisowe

- Nie obciążaj wyjścia przekaźnikowego powyżej danych producenta.
- Przy pompach, grzałkach, stycznikach i większych odbiornikach stosuj przekaźnik pośredniczący lub stycznik.
- Nie łącz bezpośrednio sygnałów różnych producentów bez sprawdzenia, czy są bezpotencjałowe lub napięciowe.
- Dla pomp ciepła i kotłów zawsze sprawdzaj DTR: wejścia blokady, SG Ready, alarm, zapotrzebowanie, OpenTherm, Modbus.
- Wejście 0-10 V nie jest tym samym co wyjście 0-10 V.
- Wyjście bezpotencjałowe nie podaje napięcia.
- Wyjście 230 V podaje napięcie i nie wolno go wpinać w wejście bezpotencjałowe urządzenia.
- W kotłowni technicznej preferuj rozwiązania przewodowe, jeżeli jest taka możliwość.
- Zachowaj rezerwę modułów i miejsc w rozdzielnicy.
- Większość kart to DIN ~70×90×65 mm; **sterowniki strefowe PS-10 230 / PS-10m 230 są duże (120×300×55 mm)** — zaplanuj szerokość rozdzielnicy. KW-03m jest natynkowy (95×98×31 mm). Wymiary i pobór mocy patrz raport `moduly_sinum_raport`.
- Komunikacja: SBUS (24 V DC lub 230 V wg modułu); WTP 868 MHz wymaga zasilania sieciowego i ma niższe obciążalności (0,3–5 A). Licznik LE-3x230mb gada po RS-485 Modbus-RTU (do 9600 bps) — to osobna magistrala niż SBUS/WTP.

## Kontrola jakości odpowiedzi

Przed podaniem doboru sprawdź:

- czy suma wejść się zgadza,
- czy suma wyjść się zgadza,
- czy dobrane moduły mają właściwy typ sygnału,
- czy obciążalność przekaźników jest wystarczająca,
- czy nie pomylono 230 V z bezpotencjałowym stykiem,
- czy uwzględniono rezerwę,
- czy podano braki danych,
- czy zasugerowano potwierdzenie z DTR urządzeń grzewczych.

## Minimalne pytania, gdy brakuje danych

Gdy użytkownik nie podał szczegółów, zapytaj maksymalnie o najważniejsze:

1. Ile jest stref grzewczych i ile siłowników w każdej strefie?
2. Czy siłowniki są 230 V czy 24 V?
3. Czy źródło ciepła ma być sterowane stykiem bezpotencjałowym, 0-10 V, OpenTherm czy Modbus?
4. Ile pomp obiegowych ma być sterowanych?
5. Ile temperatur trzeba mierzyć?
6. Czy komunikacja ma być przewodowa SBUS, czy dopuszczasz WTP 868 MHz?
7. Czy ma być pomiar energii?

## Skrócona mapa doboru

| Potrzeba | Preferowany moduł |
|---|---|
| dużo NTC | KW-12m |
| dużo wejść binarnych | KW-12-2m |
| 0-10 V / PWM / 4-20 mA | KW-10m |
| wiele przekaźników + 24 V + M-Bus | KW-15m |
| strefy 230 V + pompa + styk źródła | PS-10 230 / PS-10m 230 |
| 8 wyjść 230 V | PS-08 230 / PS-08m 230 |
| 2 obwody bezpotencjałowe | PS-02 / PS-02m |
| 6 obwodów bezpotencjałowych przewodowo | PS-06m |
| 8 obwodów bezpotencjałowych bezprzewodowo | PS-08 |
| rolety | PSZ-02 / PSZ-02m |
| brama / krańcówki | MB-04 |
| OpenTherm | KM-OT |
| DALI | KM-DALI |
| licznik energii 3-fazowy | LE-3x230mb |
| przekaźnik pomocniczy 230 V | PK-230 |
| przekaźnik pomocniczy 24 V | PK-24 |

## Ograniczenie

Ten skill jest bazą doborową, nie zastępuje DTR producenta, projektu elektrycznego ani sprawdzenia aktualnych kart katalogowych. W projektach wykonawczych potwierdź parametry techniczne, wersję firmware i kompatybilność centralki Sinum z danym modułem.
