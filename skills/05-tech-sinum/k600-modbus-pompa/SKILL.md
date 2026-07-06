---
name: k600-modbus-pompa
description: Sterowanie pompą ciepła Kołton AirAdapt (sterownik K600, program 1.4.4+) po Modbus RTU z centrali TECH SINUM. Użyj przy pracy z rejestrami BMS K600 (odczyt mocy/COP/temperatur/energii, zapis krzywej/trybów/CWU/obrotów), konfiguracji klienta modbus_client w SINUM, trybie MANUAL (obroty rej. 526), diagnostyce TIMEOUT, oraz pisaniu pętli sterowania (regulator obrotów). Zawiera zweryfikowane empirycznie adresy, skale (w tym korekty względem oficjalnego ODS), artefakty wyświetlania i pułapki Lua przy kliencie Modbus.
---

# K600 (Kołton AirAdapt) po Modbus RTU z SINUM

Wiedza zweryfikowana NA ŻYWEJ POMPIE (2026-07-03, firmware 1.4.4, sec 1.79.53).
Pełna mapa rejestrów: arkusze `BMS_menu_użytkownika.ods` / `BMS_menu_instalatora.ods`
(w projekcie: `41_doradca-grzewczy/_docs/`, wyciąg w `MODBUS_MAP.md`).

## Warunki działania łącza

- **BMS działa od programu K600 1.4.4** („BMS – pełna obsługa"); starsze wersje mają
  menu parametrów, ale nie odpowiadają. Wersję potwierdź odczytem: **rej. 54** koduje
  x.yy.zz (10404 → 1.4.4) — to zarazem test poprawności bazy adresowej.
- Parametry łącza: **slave wg menu pompy (typowo 2), 19200, parity even, 1 stop**.
- Transceiver SINUM w trybie **master**. Czysty TIMEOUT przy dobrych parametrach =
  warstwa fizyczna (A/B, właściwy port na centrali — Modbus, nie TECH!) lub kable.
- Klient w SINUM: globalny (Sieć → Modbus, `modbus_client[ID]`, app numeruje od 0)
  LUB komponent custom device (Integracje, `self:getComponent("nazwa")`) — oba działają.

## Banki i kody dostępu

| Bank | Zakres | Zapis |
|---|---|---|
| Telemetria | 0–162 | — (odczyt) |
| Użytkownika | 500–576 | bez kodu |
| Instalatora | 5000–5177 | po kodzie: zapis **kodu do rej. 5001** (typowo 0000 → wartość 0) |
| Serwisowy | poza mapą | kod menu serwis (osobny); adresy nieznane |

## Kluczowe rejestry ODCZYTU (zweryfikowane)

- Punkt pracy: **84** moc grzewcza (×0.01 kW) · **87** COP (×0.01) · **85** moc zadana ·
  **90/91** dostępna moc max/min (obwiednia modulacji TERAZ) · **77** obroty sprężarki (RPM) ·
  **82** stan (enum: 0 wył, 2 grzanie, 4/5 odszranianie, 7 czuwanie, 10 ręczny, 12 blokada EVU) ·
  **83** sprężarka 0/1 · **92** korekta algorytmu Comfort (W).
- Temperatury POMIAROWE (int16, ×0.1 °C): **59** zasilanie · **60** powrót · **16** zewnętrzna
  (moduł) · **57** zewnętrzna (inwerter) · **12** bufor grzanie · **14** bufor chłodzenie ·
  **10** CWU · **52/53** wyjście krzywej grzewczej/chłodniczej.
- **ZADANE/NASTAWY są ×1 — w tym WYPADKOWE: rej. 13 (zadana ogrzewania) i 15 (zadana
  chłodzenia)! ODS błędnie podaje ×0.1** (dowód: raw rej. 15 == stała chłodzenia z rej. 528;
  raw 34/43 w rej. 13 = sensowna zadana zasilania CO). Reguła: pomiary ×0.1, nastawy ×1.
  Wypadkowe 13/15 = idealna zadana dla własnego regulatora (uwzględniają stałą/krzywą+SG).
- Nastawy chłodzenia (bank użytkownika): **527** stała(0)/krzywa(1) · **528** stała ·
  **529–533** krzywa chłodnicza przy T zewn. +15/+20/+25/+30/+35 °C · **534** dolny limit
  zadanej (odczyt; pochodna temp. krzepnięcia płynu, rej. 5153).
- **22** przepływ (l/h) · **35/36/37** EVU/SG/Blokada · 54/55 wersje.
- **CHŁODZENIE (stan 82 = 1):** moc chłodnicza = **86** (×0.01 kW), EER = **88** (×0.01) —
  rej. 84/87 dotyczą grzania; widget musi przełączać wg stanu. Bufor chłodzenia = **14**,
  zadana chłodzenia (wypadkowa) = **15** (oba ×0.1 °C). Regulator własny: w chłodzeniu
  błąd ODWRÓCONY (więcej obrotów = niższa temperatura).
- Energia (32-bit LOW+HIGH, wartość = HIGH·65536+LOW): **94/95** cieplna (×0.1 kWh) ·
  **96/97 elektryczna ogrzewania — UWAGA: ×1 kWh (ODS błędnie podaje ×0.1!**
  dowód: ciepło/prąd = SCOP z rej. 98) · **98** SCOP (×0.01) · 127/128 energia PC suma (×0.1) ·
  chłodnicza **99/100** (×0.1) · **elektryczna chłodzenia 101/102 — ×0.1 (zgodnie z ODS;
  zweryfikowane SEER-em: 8744,5/2124,9 = 4,115 = rej. 103)** · **103** SEER (×0.01).
  ⚠️ NIESPÓJNOŚĆ FIRMWARE: elektryczna grzania ×1, elektryczna chłodzenia ×0.1 —
  każdą skalę energii weryfikuj trójkątem (ciepło/prąd = SCOP·SEER).
- Diagnostyka/degradacja: **104** indeks właściwości parownika (oszronienie/fouling) ·
  105/106 czas od odszraniania · 109 liczba odszronień · 111 starty · **112** motogodziny ·
  110 napięcie międzyfazowe · 0–9 alarmy (bitfieldy).
- P_el chwilowe: BRAK rejestru → licz `84/87` (Q/COP).

## Kluczowe rejestry ZAPISU (potwierdzone ✅ / wg mapy)

- ✅ **502** zadana CWU (20–65 °C, ×1) — bez kodu.
- ✅ **526** „zadane obroty sprężarki" — patrz TRYB MANUAL niżej.
- **500** praca 0/1 · **501** tryb pracy (bitfield: 1 ogrzewanie, 2 CWU, 4 chłodzenie; kombinacje OK).
- **514** regulacja 0=stała/1=krzywa · **515** stała (20–70) · **516–519** krzywa grzewcza
  (−20/−10/0/+10 °C, 20–70). ⚠️ W trybie MANUAL zapis 514 jest ODRZUCANY.
- Instalatorskie (po kodzie): **5002** algorytm mocy 0 Auto/1 Comfort/2 Boost ·
  **5010–5014** krzywa mocy Boost (×0.1 kW) · **5158** SG-offset zadanej (−15..+30 °C, gotowy
  override) · 5163/5164 limit mocy SG.
- Obiegi (mieszacze): zadana 544/560, pogodówka 547/563, krzywe 548–551/564–567 (×1 °C);
  stan obiegów: 38–47; konfiguracja zaworów włącz/wyłącz: 5035/5068.
- Styki/urządzenia dodatkowe: TYLKO konfiguracja funkcji (5102+/5114+/5126–5134) —
  **nie ma ręcznego wymuszania ON/OFF**; stan: 48/49.

## TRYB MANUAL (menu SERWIS pompy) — nieintuicyjny!

- W manual rej. **526 = zadane OBROTY sprężarki**; regulacja śledzi je niemal 1:1
  (zapis 3232 → realnie 3228–3231 RPM). Zapis działa bez kodu.
- **ARTEFAKT:** „Moc zadana" (rej. 85 i wyświetlacz pompy) pokazuje wtedy surowe obroty
  ×0.01 jako kW (3232 → „3,23 kW"). To NIE jest moc — nie daj się zmylić.
- Poniżej minimum modulacji pompa NIE staje — schodzi na minimalne obroty.
- Manual wyłącza własną regulację pompy: 514 odrzucane, algorytm 5002 bez znaczenia,
  rej. 5002 NIE odzwierciedla trybu manual (bank serwisowy poza mapą).
- **Po wyjściu z manual pompa wraca do własnej modulacji i IGNORUJE 526** (potwierdzone:
  526 trzymał 3232, pompa modulowała po swojemu 1214 RPM).
- Obroty rozruchowe (praktyka Kołton): **3450 RPM**.

## Pułapki SINUM Lua przy kliencie Modbus (krytyczne)

- **Handlery `onRegisterAsyncRead` / `onAsyncRequestFailure` / `onRegisterAsyncWrite`
  rejestruj przy KAŻDYM `onEvent`** (bezwarunkowo, na początku) — odpowiedź async
  przychodzi w OSOBNYM wywołaniu skryptu; rejestracja tylko przy pollu = odpowiedzi
  przepadają bez śladu (0 błędów, 0 danych).
- Odczyty blokowe `readHoldingRegistersAsync(base, n)` — value w callbacku to tablica
  od 1 (`R[base+i-1]`). Wartości >32767 to ujemne int16 (v−65536).
- Odczyty są CACHE'owane (ustawienia Modbus w aplikacji) — weryfikacja zapisu odczytem
  zwrotnym musi tolerować 1–2 cykle opóźnienia.
- Porównania zapis/odczyt NORMALIZUJ typami: w Lua `"5500" ~= 5500`, `true ~= 1` —
  inaczej fałszywe „nie przyjęty".
- `element:setValue("value", v, true)` — trzeci argument przy synchronizacji kontrolek
  (bez propagacji zdarzeń; inaczej pętla callbacków).
- `visibility` przyjmuje TYLKO `visible/hidden_gap/hidden_adjust` („hidden" = błąd walidacji).
- Otwarty edytor urządzenia w aplikacji SINUM WSTRZYMUJE skrypt (device wygląda na martwy).
- Zapisy przez master-switch („Sterowanie aktywne", OFF = podgląd) + pending na rejestr
  + weryfikacja odczytem zwrotnym z logiem ✅/❌/⛔ — wzorzec z device 42.

## Regulator obrotów (wzorzec, device 42 sekcja 🧮)

Przyrostowe PI na rej. 526 (wymaga trybu MANUAL): `dRPM = Kp·(e−e_prev) + Ki·e` na cykl
(1 min), e = zadana(rej.13) − czujnik (59 zasilanie lub 12 bufor, wybieralny). Bez windup
(forma przyrostowa), bumpless (start od realnych obrotów z rej. 77), strefa martwa gasi
całkę przy zadanej, limit zmiany/cykl (RPM) usuwa szarpanie, klamry min/max, rozruch 3450,
pauza przy stanach 3/4/5/12 (alarm/odszranianie/EVU). Starty: Kp≈80 RPM/K, Ki≈15 RPM/(K·min),
strefa 0.3 K, slew 200 RPM/cykl.
