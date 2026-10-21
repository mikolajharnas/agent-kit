# Tabele z projektu metodologii ChE (pkt 6.3.2) — wartości przepisane

Przepisane 14.10.2026 z PDF projektu załącznika 1 (rozporządzenie MRiT, data pusta).
Sumy kolumn sprawdzone ręcznie: 24,00 poza wyjątkami opisanymi przy tabelach.

## Tabela 33 — jednostkowe zużycie c.w.u. V_W [l/(j.o.·doba)] przy θ_CW

| Rodzaj | Jednostka odniesienia | V_W | Uwagi |
|---|---|---|---|
| mieszkalny wielorodzinny | mieszkaniec | 45 | |
| mieszkalny jednorodzinny | mieszkaniec | 40 | |
| biurowy | zatrudniony | 7 | |
| oświata, szkolnictwo wyższe, nauka | uczeń / student | 10 | |
| opieka zdrowotna — inna niż szpital | zatrudniony | 15 | |
| szpital | łóżko | 200 | |
| gastronomia | miejsce konsumpcyjne | 30 | |
| sport — baseny, pływalnie, parki wodne | korzystający | 60 | |
| sport — hale widowiskowe, sportowe | korzystający | 7 / 60 | widzowie / sportowcy |
| handel, usługi | zatrudniony | 15 | |
| zamieszkania zbiorowego — hotel, akademik | miejsce noclegowe | 45 | |
| magazynowy | zatrudniony | 7 | |
| produkcyjny | zatrudniony | 7 / 40 | bez / z natryskami |

## Tabela 34 — liczba mieszkańców, gdy brak danych (mieszkalne)

Jednorodzinny: A_f ≤ 250 m² → 4 os., > 250 m² → 6 os.
Wielorodzinny (na mieszkanie): A_f ≤ 50 m² → 2, 50–80 m² → 4, > 80 m² → 6.

## Tabela 35 — k_ARM (armatura oszczędzająca, ≥ 80 % punktów czerpalnych)

dwuuchwytowe 1,00 · jednouchwytowe 1,00 · termostatyczne 0,80 · samozamykające 0,75 ·
bezdotykowe 0,70 · reduktory prysznicowe 0,80 · perlatory 0,90 · ograniczniki wypływu 0,85.
Gdy bateria ma już wbudowany ogranicznik — tylko jeden współczynnik.

## Tabela 36 — temperatury

Budynek do 31.12.2002: θ_0 = 10 °C (25 °C przy odzysku ciepła), θ_CW = 45 °C.
Od 01.01.2003: θ_0 = 10 °C (25 °C przy odzysku), θ_CW = 55 °C.

## Profile godzinowe n_k (godzina 0:00 … 23:00)

### Tabela 28
- Jednorodzinny, roboczy: 0,0,0,0,0.89,1.10,1.23,1.54,1.54,1.32,1.17,1.05,0.93,0.86,0.64,0.94,1.65,1.71,1.85,1.74,1.63,1.44,0.77,0
- Jednorodzinny, weekend: 0,0,0,0,0,0.64,0.90,1.41,1.56,1.43,1.22,1.21,1.34,1.25,1.21,1.40,1.85,1.50,1.76,1.87,1.45,1.43,0.57,0
- Wielorodzinny, roboczy: 0.30,0.25,0.18,0.15,0.32,0.60,1.18,1.59,1.69,1.43,1.04,1.06,1.02,0.81,1.17,1.07,1.41,1.28,1.19,1.60,1.69,1.25,1.09,0.63
- Wielorodzinny, weekend: 0.45,0.22,0.20,0.10,0.25,0.45,0.85,0.97,1.08,1.13,1.18,1.27,1.32,1.38,1.42,1.43,1.41,1.43,1.47,1.52,1.32,1.25,1.09,0.81
- Zamieszkania zbiorowego (roboczy = weekend): 0,0,0,0,0,0.90,1.18,1.70,1.75,1.45,1.08,1.03,1.00,1.15,1.17,1.14,1.16,1.28,1.45,1.60,1.69,1.55,1.19,0.63  (Σ 24,10)

### Tabela 29 (weekend = 0 we wszystkich)
- Biurowy, roboczy: 7:00 0.60 · 8:00 2.41 · 9:00 2.55 · 10:00 2.70 · 11:00 2.76 · 12:00 2.90 · 13:00 2.82 · 14:00 2.76 · 15:00 2.11 · 16:00 1.63 · 17:00 0.76 · reszta 0
- Oświata, roboczy: 6:00 0.95 · 7:00 1.62 · 8:00 1.82 · 9:00 2.14 · 10:00 2.56 · 11:00 2.70 · 12:00 2.69 · 13:00 2.73 · 14:00 2.61 · 15:00 1.94 · 16:00 1.15 · 17:00 1.09 · reszta 0; **lipiec i sierpień: 0 we wszystkich godzinach**
- Opieka zdrowotna (nie szpital), roboczy: 7:00 1.62 · 8:00 1.82 · 9:00 2.14 · 10:00 2.56 · 11:00 2.70 · 12:00 2.69 · 13:00 2.73 · 14:00 2.61 · 15:00 1.94 · 16:00 1.15 · 17:00 1.09 · 18:00 0.95 · reszta 0

### Tabela 30
- Gastronomia (roboczy = weekend): 10:00–22:00 po 1.15, reszta 0 — **Σ 14,95 (błąd druku? skaluj do 24)**
- Handel, usługi, roboczy: 8:00–20:00 po 1.85, reszta 0 (Σ 24,05); weekend 0

### Tabela 31
- Szpital, roboczy: 0.22,0.20,0.19,0.15,0.31,0.55,0.89,1.25,1.46,1.44,1.28,1.33,1.29,1.23,1.26,1.46,1.42,1.29,1.20,1.26,1.31,1.26,1.10,0.65
- Szpital, weekend: 0,0,0,0.10,0.25,0.45,0.85,0.97,1.08,1.09,1.14,1.22,1.24,1.28,1.23,1.25,1.26,1.24,1.22,1.19,1.10,0.84,0,0  (Σ 19,0)
- Sport: „indywidualnie w zależności od funkcji i sposobu użytkowania”

### Tabela 32
- Magazynowy, produkcyjny: „indywidualnie”

## Implementacja referencyjna

Kalkulator AirAdapt (Kołton), moduł `cwu_obiekty.py` (v1.63+): dane powyżej, kalendarz
(weekendy, święta ustawowe, wakacje), energia, moce, zasobnik; test `test_cwu_obiekty.py`.
