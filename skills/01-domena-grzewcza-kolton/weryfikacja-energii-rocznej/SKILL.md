---
name: weryfikacja-energii-rocznej
description: >
  Weryfikacja rocznego zapotrzebowania budynku na ciepło liczonego metodą binową
  (linia obciążenia PN-EN 14825: Q_proj przy θ_e → 0 przy granicy grzania T_gr):
  kontrola z H_HE normy, niezależność od urządzenia, błąd binów, spójność danych
  klimatycznych (biny vs szereg godzinowy TMY), spójność θ_e między OZC a
  lokalizacją, porównanie z godzinowym bilansem strat i zysków (zyski niejawne g*,
  równoważna T_gr), grunt. Użyj ZAWSZE, gdy ktoś prosi „sprawdź, czy energia
  roczna / koszt ogrzewania jest dobrze liczony”, przy przeglądzie kalkulatora
  doboru pompy ciepła, przy rozjeździe z audytem lub świadectwem energetycznym
  i przed zmianą metody liczenia energii. Towarzyszące: [[straty-gruntu-iso13370]],
  [[cena-pradu-taryfy-ure]], [[analiza-dokumentacji-hvac]].
---

# Weryfikacja energii rocznej (metoda binowa)

## Model, który sprawdzasz

    Q(T) = Q_proj · (T_gr − T) / (T_gr − θ_e)   dla T < T_gr, w godzinach grzania
    E    = Σ_biny h(T) · Q(T)

To linia obciążenia PN-EN 14825 (PLR, `T_bin limit = 16 °C`). Dla SCOP jest
normowa. Jako „zapotrzebowanie budynku” to uproszczenie: linia przechodzi przez
Q_proj (bez zysków, jak PN-EN 12831) i przez zero przy T_gr, więc **zakłada zyski
niejawnie** — zero przy θ_e, `H·(θ_i − T_gr)` przy T_gr. Zyski niejawne rosną
z H budynku, a prawdziwe nie zależą od izolacji. To nie jest energia użytkowa
ze świadectwa (metoda miesięczna z zyskami słonecznymi) — różnice są normalne.

## Lista kontrolna (po kolei, z liczbami)

1. **Norma.** Dla klimatów referencyjnych `Σ h·(16 − T)/(16 − T_design)` musi dać
   H_HE z tab. B.2 PN-EN 14825: ciepły 1336 h, umiarkowany 2066 h, chłodny 2465 h.
2. **Niezależność od urządzenia.** Energia CO ta sama dla każdej pompy i kaskady.
   Biny pominięte z braku danych pompy NIE mogą znikać z zapotrzebowania —
   ma je przejąć grzałka/szczyt.
3. **Zaokrąglenie binów.** Ta sama metoda godzina po godzinie na temperaturach
   niezaokrąglonych — różnica ≤ 0,05 %.
4. **Te same dane.** Biny i szereg godzinowy (filtr dobowy, profile) z TEGO SAMEGO
   wydania TMY. Porównuj **stopniogodziny i θ_m,e**, nie liczby godzin w binach:
   zaokrąglenie temperatur do 0,1 K przenosi ~700–800 h między sąsiednimi binami
   przy różnicy energii ≤ 0,06 %. Prawdziwy rozjazd wydań TMY dawał +6…+11 %.
   Sprawdź też, czy biny obejmują cały rok (Σh ≈ 8760) — urwane biny zaniżają
   wszystko, co rozkłada się proporcją h/8760 (np. CWU).
5. **θ_e.** Q_proj z OZC jest policzone dla θ_e formularza — linia musi stać
   w tej samej θ_e. Rozjazd ±2 K → energia ±5 %, przesunięty punkt biwalentny.
6. **Fizyka.** Bilans godzinowy `max(0, H·(θ_i − T) + Φ_grunt − g·A)` w tych samych
   godzinach; szukaj g*, przy którym bilans = wynik programu (bisekcja). Typowe
   zyski wewnętrzne + wykorzystane słoneczne w sezonie: **3–5 W/m²**.
7. **Grunt.** Liniowo z T powietrza zaniża ~2,7× → [[straty-gruntu-iso13370]].
8. **Dane klimatyczne.** Sd(20 °C) w dniach grzewczych z TMY PVGIS 2005–2023:
   Warszawa ~3600 K·d. Podejrzane średnie roczne (Zakopane w TMY 3,4 °C) —
   sprawdź komórkę reanalizy / stację.

## Wyniki referencyjne (Warszawa, TMY PVGIS, T_gr 16 °C, dom 200 m²)

| Budynek | Q_proj | Program (linia) | Bilans, g = 3–5 W/m² | g* | T_gr równoważna |
|---|---|---|---|---|---|
| nowy WT2021, rekuperacja | 23 W/m² | 41 kWh/m² | 24–35 | 2,0 | 10–14 °C |
| lata 90., grawitacja | 49 W/m² | 86 kWh/m² | 81–93 | 4,2 | 15–17 °C |
| bez ocieplenia | 111 W/m² | 193 kWh/m² | 219–231 | 9,3 | 18–19 °C |

Wniosek: przy stałej T_gr = 16 °C przeciętny dom wychodzi dobrze, bardzo dobry
zawyżony o 15–70 %, nieocieplony zaniżony o 12–16 %. Dobór MOCY to nie dotyczy
(opiera się na Q_proj przy θ_e) — tylko energii i kosztów.

Wrażliwość na T_gr (lata 90.): 12 → 62, 14 → 74, 15 → 80, 16 → 86, 17 → 91 kWh/m².

## Poprawki, gdy wynik nie przechodzi

- Rozjazd θ_e → linia w θ_e, dla której policzono Q_proj; informacja w UI/walidacji.
- Różne wydania TMY → przelicz biny z tego samego szeregu, który pobiera program.
- Zyski niejawne → domyślna T_gr wg wskaźnika W/m² (temperatura bilansu
  `θ_b = θ_i − G/H`) albo jawny model zysków. Zmienia koszty wielu doborów —
  decyzja merytoryczna, nie poprawka błędu.
- Grunt → strumień miesięczny ISO 13370 (+7…+9 % energii domów z OZC).

## Szkic obliczenia g* (Python)

    def E_bilans(g):                    # T — temperatury godzin grzania
        q = H*(20 - T) + phi_g_m - g*A  # W; phi_g_m — grunt danej godziny
        return np.clip(q, 0, None).sum() / 1000
    lo, hi = 0.0, 30.0                  # g* przez bisekcję
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if E_bilans(mid) > E_prog else (lo, mid)

`H = (Φ_T + Φ_nieogrz + Φ_V) / (θ_i − θ_e)` z rozbicia mocy projektowej.
