---
name: analiza-dokumentacji-hvac
description: >
  Użyj tego skilla ZAWSZE gdy użytkownik wgrywa dokumentację projektową
  (PAB, PW, OPZ, audyt energetyczny, obliczenia cieplne, opis nieformalny,
  zapytanie ofertowe) i prosi o analizę pod kątem doboru urządzeń grzewczych:
  pomp ciepła (C.O. + C.W.U.), kotłów pelletowych, zasobników C.W.U.,
  buforów ciepła, grzałek szczytowych lub źródeł mieszanych. Skill prowadzi
  przez ekstrakcję parametrów, weryfikację zgodności z polskim prawem,
  wykrycie nieścisłości w dokumentacji i generowanie pisma technicznego
  gotowego do wysłania. Stosuj też gdy użytkownik pyta "czy dobór jest ok",
  "sprawdź dokumentację", "co brakuje w projekcie" dla instalacji grzewczych.
---

# Analizator dokumentacji HVAC — dobór urządzeń grzewczych

## Workflow — zawsze wykonuj w tej kolejności

```
1. WCZYTAJ dokumenty → wyodrębnij parametry (Sekcja A)
2. ZWERYFIKUJ parametry względem wymagań prawnych (Sekcja B)
3. WYKRYJ nieścisłości i braki (Sekcja C)
4. DOBIERZ urządzenia wg logiki doboru (Sekcja D)
5. WYGENERUJ pismo techniczne jako .docx (Sekcja E)
```

Przed czytaniem dokumentów zawsze odczytaj skill `file-reading` jeśli
format pliku jest nieznany. Dla PDF użyj skill `pdf-reading`.

---

## A. EKSTRAKCJA PARAMETRÓW — co wyciągnąć z dokumentacji

### A1. Parametry budynku / obiektu

Szukaj aktywnie następujących danych (różne dokumenty podają je różnie):

| Parametr | Gdzie szukać | Jednostka |
|---|---|---|
| Projektowe obciążenie cieplne (Φ) | obliczenia OZC, strona tytułowa | kW |
| Zapotrzebowanie na energię użytkową QH | audyt, świadectwo, obliczenia | kWh/rok |
| Wskaźnik EP (energia pierwotna) | audyt, WT 2021 | kWh/(m²·rok) |
| Powierzchnia ogrzewana Af | opis techniczny, rzuty | m² |
| Kubatura ogrzewana V | j.w. | m³ |
| Temperatura obliczeniowa zewnętrzna te | obliczenia, opis | °C |
| Temperatura wewnętrzna obliczeniowa ti | obliczenia | °C |
| Typ instalacji grzewczej | opis | CO, podłogówka, grzejniki, mieszana |
| Temperatura zasilania/powrotu | schemat hydrauliczny | °C/°C |
| Zapotrzebowanie na C.W.U. | opis, norma PN-92/B-01706 | l/dobę lub kW |
| Liczba mieszkańców / użytkowników | opis programu użytkowego | os. |
| Strefa klimatyczna | lokalizacja na mapie stref | I–V |

### A2. Parametry wymagane dla doboru pompy ciepła

Wyodrębnij lub oblicz:
- **Moc grzewcza CO** — z obliczeń cieplnych lub bilansu energetycznego
- **Moc C.W.U.** — z normy lub podana wprost (jeśli brak: szacuj 0,25–0,35 kW/osobę)
- **Punkt biwalentny** — temperatura zewnętrzna przy której grzałka szczytowa przejmuje część mocy
- **Temperatura źródła dolnego** — powietrze zewnętrzne (ASHP) lub grunt/woda
- **Parametry obiegu grzewczego** — 35/30°C (podłogówka) vs 55/45°C (grzejniki) vs 70/55°C (stare grzejniki)
- **Wymagany COP / SCOP** — z wymagań ErP lub OPZ
- **Dostępna moc elektryczna przyłączenia** — z opisu lub projektu elektrycznego

### A3. Parametry wymagane dla doboru kotła pelletowego

- Moc nominalna CO + ewentualnie C.W.U.
- Wymagana sprawność (przetarg: zazwyczaj ≥ 92% → EN 303-5 klasa 5)
- Wymagany podajnik + pojemność zasobnika paliwa
- Wymagania emisyjne (Ecodesign 2021, normy lokalne)
- Dostępność miejsca na zasobnik

### A4. Parametry zasobnika C.W.U.

- Liczba osób → normatywne zużycie wg PN-92/B-01706 lub EN 15316
- Wymagana temperatura magazynowania (min. 55°C — wymóg sanitarny, dezynfekcja Legionella)
- Źródło ciepła do podgrzewu (pompa ciepła / kocioł / grzałka elektryczna)
- Wymagany czas podgrzewu dobowego (zazwyczaj 1–2 h)
- Pojemność: szacunkowa reguła → 40–60 l/osobę dla PJ; 50–80 l/osobę dla PC

### A5. Parametry bufora ciepła

- Wymagana pojemność (reguła: min. 15–20 l/kW mocy pompy ciepła)
- Temperatura maksymalna pracy (zależna od źródła)
- Ilość wężownic / wymienników (solar, pompa, kocioł)
- Podział na strefy temperaturowe (jeśli C.W.U. + CO z jednego zbiornika)

---

## B. WERYFIKACJA PRAWNA — wymagania obowiązujące w Polsce

### B1. Warunki Techniczne WT 2021 (Dz.U. 2022 poz. 1225)

Wymagania EP dla budynków nowych i po głębokiej modernizacji:

| Typ budynku | EP max [kWh/(m²·rok)] |
|---|---|
| Dom jednorodzinny | 70 |
| Dom wielorodzinny | 65 |
| Budynek użyteczności publicznej (biuro) | 90 |
| Szkoła, żłobek | 60 |
| Szpital | 290 |
| Hotel | 110 |

Sprawdź czy wskaźnik EP z dokumentacji mieści się w limicie.
Jeśli brak wskaźnika EP → zaznacz jako **BRAK WYMAGANEJ INFORMACJI**.

Współczynniki nakładu nieodnawialnej energii pierwotnej wi:
- Energia elektryczna (sieć): wi = 2,5 (do 2026) → 1,8 (od 2026 wg rozp.)
- Gaz ziemny: wi = 1,1
- Pellet / biomasa: wi = 0,2
- Ciepło sieciowe (zależy od źródła): wi = 0,8–1,3

### B2. Wymagania dla pomp ciepła (ErP / rozp. 813/2013)

- Minimalny ηs (sprawność sezonowa) dla grzewczych pomp ciepła: ≥ 115% dla niskiej temp., ≥ 125% dla średniej temp.
- SCOP ≥ 2,5 dla strefy klimatycznej umiarkowanej (Polska: strefa średnia)
- Obowiązek etykiety energetycznej (klasa min. A+)

### B3. Wymagania sanitarne — C.W.U.

- Temperatura zasobnika C.W.U.: min. 55°C w całym zasobniku (ochrona przed Legionellą) — Dz.U. 2002 nr 75 poz. 690
- Dezynfekcja termiczna: możliwość podgrzewu do 70°C min. raz w tygodniu
- Pompa cyrkulacyjna C.W.U.: wymagana gdy długość przewodów > 3 m (praktycznie zawsze w budynku wielorodzinnym)
- Zawór antyoparzeniowy (termostatyczny): wymagany na punktach czerpalnych jeśli zasobnik > 55°C

### B4. Wymagania dla kotłów pelletowych (przetargi publiczne)

- EN 303-5:2012 klasa 5 — wymagana w przetargach finansowanych ze środków publicznych
- Ecodesign 2021 (rozp. 2015/1189) — min. sprawność sezonowa ηs ≥ 75% (kotły ≤ 500 kW)
- Emisja CO: < 500 mg/m³ (klasa 5), emisja pyłu: < 40 mg/m³

### B5. Przepisy F-Gas II (Rozp. UE 2024/573) dla pomp ciepła

- Od 2027: zakaz nowych urządzeń z czynnikiem GWP ≥ 150 w wielu zastosowaniach
- R410A (GWP 2088) — nie rekomendować dla nowych instalacji
- R32 (GWP 675), R454B (GWP 466) — ryzyko regulacyjne
- R290 (GWP 3), R744 (GWP 1) — bezpieczne, zalecane

### B6. Normy pomocnicze

- PN-EN 14511 — metoda pomiaru COP pompy ciepła
- PN-EN 14825 — obliczanie SCOP
- PN-92/B-01706 — zapotrzebowanie na C.W.U. (normatywne zużycie)
- PN-EN 12828 — instalacje grzewcze w budynkach

---

## C. WYKRYWANIE NIEŚCISŁOŚCI I BRAKÓW

Dla każdego dokumentu sprawdź systematycznie poniższą listę.
Każdą nieścisłość klasyfikuj jako: **[BŁĄD]**, **[BRAK]** lub **[OSTRZEŻENIE]**.

### C1. Nieścisłości w mocach i bilansach

- Moc projektowa CO nie wynika z obliczeń cieplnych (podana bez podstawy)
- Suma mocy pomieszczeń ≠ moc łączna budynku
- Moc dobrana urządzenia < projektowego obciążenia cieplnego (niedostateczny dobór)
- Moc dobrana > 2× projektowego obciążenia (przewymiarowanie — obniży COP, ryzyko cyklowania)
- Brak uwzględnienia mocy C.W.U. w bilansie mocy przyłączenia elektrycznego
- Brak uwzględnienia jednoczesności obciążeń CO + C.W.U.

### C2. Nieścisłości w parametrach instalacji

- Temperatura zasilania grzejnikowego > 55°C przy doborze pompy ciepła (niski COP, konieczna modernizacja grzejników lub nowa pompa wysokotemperaturowa)
- Brak informacji o typie instalacji (podłogówka vs grzejniki)
- Brak podania minimalnego przepływu przez pompę ciepła (ryzyko pracy poza charakterystyką)
- Parametry hydrauliczne sprzeczne ze schematem (np. schemat pokazuje bufor ale opis go nie wymienia)

### C3. Nieścisłości w C.W.U.

- Pojemność zasobnika < 40 l/osobę (niedoszacowanie)
- Brak dezynfekcji termicznej (pompa ciepła nie osiągnie 70°C → wymagana grzałka)
- Brak cyrkulacji C.W.U. przy budynku wielorodzinnym
- Temperatura zasobnika podana < 55°C (niezgodność z wymogami sanitarnymi)

### C4. Braki formalne i dokumentacyjne

- Brak obliczeń cieplnych (lub obliczenia z programu bez wydruku weryfikacyjnego)
- Brak wskaźnika EP lub jego niespójność z WT 2021
- Brak strefy klimatycznej (konieczna do SCOP)
- Brak schematu hydraulicznego lub schemat niekompletny
- Brak specyfikacji technicznej urządzeń (tylko nazwy bez parametrów)
- Brak podania trybu pracy (tylko CO / tylko C.W.U. / biwatencja / backup)

### C5. Tryby pracy — wymagane sprawdzenie

Zidentyfikuj i zweryfikuj tryby pracy instalacji:
- **Tryb monowalentny** — pompa ciepła pokrywa 100% zapotrzebowania → sprawdź czy moc wystarcza do te,min
- **Tryb biwalentny równoległy** — pompa + grzałka szczytowa powyżej punktu biwalentnego → sprawdź punkt biwalentny i moc grzałki
- **Tryb biwalentny alternatywny** — pompa lub kocioł (nie jednocześnie) → sprawdź logikę przełączania
- **Tryb backup** — kocioł lub grzałka jako 100% backup przy awarii pompy → sprawdź moc backup
- **Tryb C.W.U.** — priorytet C.W.U. vs CO → sprawdź czy zasobnik ma grzałkę do dezynfekcji

---

## D. LOGIKA DOBORU URZĄDZEŃ

### D1. Pompa ciepła — dobór mocy

```
Φ_PC = Φ_CO × f_biw + Φ_CWU_szczyt

gdzie:
  Φ_CO    = projektowe obciążenie cieplne [kW]
  f_biw   = współczynnik biwalencji:
            - monowalentna: f = 1,0
            - biwalentna (punkt -7°C): f ≈ 0,6–0,7
            - biwalentna (punkt 0°C):  f ≈ 0,4–0,5
  Φ_CWU_szczyt = moc szczytowa C.W.U. [kW]
                 (zazwyczaj 0,5–1,0 kW/osobę lub z obliczeń)
```

Sprawdź czy dobrana pompa ciepła mieści się w zakresie ±15% obliczonej mocy.

### D2. Grzałka / kocioł szczytowy — dobór mocy

```
Φ_backup = Φ_CO - Φ_PC_przy_te,min
```

Przy trybie backup (100%): Φ_backup = Φ_CO + Φ_CWU_szczyt

### D3. Zasobnik C.W.U. — dobór pojemności

```
V_CWU = n_osób × q_jedn × f_jednocz / 1000

gdzie:
  q_jedn   = 50–80 l/(osobę·dobę) dla mieszkań
             40–60 l/(osobę·dobę) dla hoteli, akademików
  f_jednocz = 0,7–0,9 (współczynnik jednoczesności)
```

Minimalnie: zawsze sprawdź V ≥ 2 × (moc pompy ciepła [kW]) × 15 [l/kW]

### D4. Bufor ciepła — dobór pojemności

```
V_buf = Φ_PC [kW] × 15 [l/kW]   (minimum)
V_buf = Φ_PC [kW] × 20 [l/kW]   (zalecane dla pomp inwerterowych)
```

---

## E. GENEROWANIE PISMA TECHNICZNEGO

Po zebraniu wszystkich danych wygeneruj pismo jako `.docx`:

1. Użyj skill `docx` do stworzenia pliku
2. Użyj skill `kolton-dokumenty` dla stylu i danych firmy
3. Użyj skill `polish-locale` dla kodowania

### Struktura pisma technicznego z analizy:

```
[Miejscowość, data]
[Adresat]
Dotyczy: Analiza techniczna dokumentacji projektowej — [nazwa obiektu]

1. PRZEDMIOT ANALIZY
   Krótki opis wgranej dokumentacji (typ, data, autor jeśli podany)

2. WYODRĘBNIONE PARAMETRY TECHNICZNE
   Tabela: parametr | wartość z dokumentacji | wymaganie prawne | ocena

3. DOBÓR URZĄDZEŃ
   Zestawienie: urządzenie | wymagana moc/pojemność | dobrana wartość | zgodność

4. STWIERDZONE NIEŚCISŁOŚCI I BRAKI
   Lista [BŁĄD] / [BRAK] / [OSTRZEŻENIE] z krótkim wyjaśnieniem każdego

5. REKOMENDACJE
   Konkretne działania: co uzupełnić, co poprawić, co wyjaśnić z projektantem

6. UWAGI KOŃCOWE
   Zastrzeżenie: analiza na podstawie dostarczonej dokumentacji; ostateczny
   dobór wymaga potwierdzenia przez uprawnionego projektanta instalacji.

Kołton Spółka Komandytowa
```

### Zasady redakcji pisma:

- Ton formalny, rzeczowy — patrz skill `kolton-dokumenty`
- Nieścisłości podawaj konkretnie: "Dobrana pojemność zasobnika 150 l jest
  niewystarczająca dla 5 osób (wymagane min. 250 l wg PN-92/B-01706)"
- Nigdy nie pisz "błąd projektanta" — pisz "wartość wymaga weryfikacji"
- Przy brakach danych: "Dokumentacja nie zawiera informacji o [X].
  Prosimy o uzupełnienie przed finalnym doborem urządzeń."
- Rekomendacje zawsze kończ wskazaniem normy lub przepisu

---

## F. OBSŁUGA TYPOWYCH TYPÓW PLIKÓW

| Typ pliku | Metoda odczytu |
|---|---|
| PDF (tekst) | `extract-text` lub skill `pdf-reading` |
| PDF (skan) | OCR przez `pdf-reading` → Tesseract |
| DOCX | skill `docx` → `extract-text` |
| Nieformalny opis (wklejony tekst) | Analizuj bezpośrednio z kontekstu |
| Zapytanie ofertowe | Traktuj jak OPZ — wyciągnij parametry z treści |

Jeśli dokument jest niekompletny lub nieczytelny — poinformuj użytkownika
o konkretnych brakach zanim przystąpisz do analizy.
