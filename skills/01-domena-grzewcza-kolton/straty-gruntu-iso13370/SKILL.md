---
name: straty-gruntu-iso13370
description: >
  Straty ciepła do gruntu wg PN-EN ISO 13370:2017 — U podłogi na gruncie
  i piwnic (B', d_t, d_w), a do ENERGII ROCZNEJ strumień miesięczny (równ. C.4)
  ze współczynnikami okresowymi H_pe / H_pi (zał. H: płyta, piwnica ogrzewana,
  nieogrzewana, izolacja krawędziowa), głębokość wnikania δ (tab. H.1) i ρc
  gruntu. Użyj ZAWSZE, gdy liczysz energię roczną / sezonową budynku z gruntem
  (metoda binowa, miesięczna, godzinowa ISO 52016-1), gdy ktoś bierze f_g1 = 1,45
  z PN-EN 12831 do energii, gdy grunt jest skalowany liniowo z temperaturą
  powietrza, przy piwnicy w gruncie i przy testach takiego rachunku.
  Towarzyszące: [[weryfikacja-energii-rocznej]], [[analiza-dokumentacji-hvac]].
---

# Grunt: moc projektowa ≠ energia roczna

## Najważniejsze

- **Moc projektowa** (PN-EN 12831): jedna liczba `Φ_g = f_g1 · A · U_eq · (θ_int − θ_m,e)`,
  `f_g1 = 1,45`. Współczynnik 1,45 to zapas na roczne wahania — **tylko do mocy**.
- **Energia roczna**: masa gruntu tłumi i opóźnia wahania, więc strata do gruntu
  NIE maleje razem z temperaturą powietrza. Norma daje **strumień miesięczny**
  (równanie C.4). Skalowanie gruntu liniowo „do zera przy granicy grzania” (jak
  w linii obciążenia PN-EN 14825) zaniża grunt w sezonie ok. **2,7×**.
- Skutek w praktyce (dom jednorodzinny, Warszawa, płyta na gruncie): energia CO
  **+7…+9 %** po przejściu z linii na C.4 (grunt to ~5 % Q_proj, ale ~12 % energii).

## Źródło i jego status

- PN-EN ISO 13370:2017 (= ISO 13370:2017, wyd. 3; wobec 2007 zmiany „głównie
  redakcyjne” + wyjścia do ISO 52016-1). Rozdziały: 7.1 płyta, 7.3 piwnica
  ogrzewana, 7.4 nieogrzewana, zał. C — strumień ciepła, zał. H — współczynniki
  okresowe, zał. F — programy dynamiczne (warstwa wirtualna).
- Pełny tekst płatny; darmowa próbka (iTeh, 15 stron) **kończy się przed zał. C i H**.
  Wzory niżej potwierdzone z implementacją referencyjną UK Home Energy Model
  (MHCLG) — `communitiesuk/epb-home-energy-model`,
  `src/core/space_heat_demand/building_element.rs`, z numerami równań normy.
- **Niepotwierdzone w tekście normy:** wariant przesunięcia fazowego. C.1 dopuszcza
  kilka metod (wybór w tab. A.3/B.3); HEM liczy C.4 z temperaturą BIEŻĄCEGO
  miesiąca, bez przesunięcia. Przy piśmie technicznym zaznacz to założenie.

## Wzory

Geometria i grubości zastępcze (Rsi podłoga 0,17, ściana 0,13; Rse 0,04):

    B'  = A / (0,5·P)                      P — obwód EKSPONOWANY
    d_t = w + λ·(Rsi + R_f + Rse)          podłoga (w — pełna grubość ściany)
    d_w = λ·(Rsi + R_w + Rse)              ściana piwnicy w gruncie
    płyta (7.1): d_t < B' → U = 2λ/(π·B' + d_t) · ln(π·B'/d_t + 1)
                 d_t ≥ B' → U = λ/(0,457·B' + d_t)
    H_g = A·U + P·Ψ_wf                     (1) — część stała

Głębokość wnikania i grunt (tab. H.1):

    δ = √(λ · t_p / (π · ρc)),  t_p = 3,15·10⁷ s
    glina/ił λ 1,5  ρc 3,0·10⁶ → δ 2,2 m
    piasek/żwir λ 2,0  ρc 2,0·10⁶ → δ 3,2 m
    skała λ 3,5  ρc 2,0·10⁶ → δ 4,2 m      (λ nieznane → 2,0)

Współczynniki okresowe (zał. H), `e = exp(−z/δ)`:

    płyta H.4.1   H_pi = A·(λ/d_t)·√(2 / ((1 + δ/d_t)² + 1))
    płyta H.4.2   H_pe = 0,37·P·λ·ln(δ/d_t + 1)
    piw. ogrz. H.7.1  H_pi = A·(λ/d_t)·√(2/((1+δ/d_t)²+1)) + z·P·(λ/d_w)·√(2/((1+δ/d_w)²+1))
    piw. ogrz. H.7.2  H_pe = 0,37·P·λ·[e·ln(δ/d_t + 1) + 2·(1 − e)·ln(δ/d_w + 1)]
    piw. nieogrz. H.8.2 (h — ściany nad terenem, U_w, V = A·(h + z), n = 0,3 1/h §7.4):
      H_pe = A·U_f · [0,37·P·λ·(2 − e)·ln(δ/d_t + 1) + h·P·U_w + 0,33·n·V]
             / [(A + z·P)·λ/δ + h·P·U_w + 0,33·n·V + A·U_f]
    izolacja krawędziowa (H.5, zał. D), d' — dodatkowa grubość zastępcza izolacji:
      pozioma szer. D:  0,37·P·λ·[(1 − e^(−D/δ))·ln(δ/(d_t + d') + 1) + e^(−D/δ)·ln(δ/d_t + 1)]
      pionowa głęb. D:  to samo z e^(−2D/δ)
      (postać wg HEM; tam d' = R_n·λ − D — przed użyciem sprawdź d' z zał. D,
       norma liczy je z grubości izolacji, nie z jej szerokości)

Strumień miesięczny — równanie C.4 (m = 1…12):

    Φ_m = H_g·(θ_i,an − θ_e,an) + P·Ψ_wf·(θ_i,m − θ_e,m)
          − H_pi·(θ_i,an − θ_i,m) + H_pe·(θ_e,an − θ_e,m)

Przy stałej temperaturze wewnętrznej człon H_pi znika. Amplituda temperatury =
połowa różnicy między najwyższą a najniższą średnią miesięczną. Do symulacji
godzinowej (ISO 52016-1) zał. F: temperatura wirtualna gruntu (F.2) i opór
warstwy wirtualnej R_vi (F.1).

## Jak wpiąć w metodę binową (linia obciążenia PN-EN 14825)

1. Rozbij `Q_proj = Q_bez_gruntu + Φ_g,proj` (Φ_g,proj — grunt z mocy projektowej).
2. Część bez gruntu — dalej linią `Q_bez·(T_gr − T)/(T_gr − θ_e)`.
3. Grunt — `Φ_m` miesiąca danej godziny, w każdej godzinie grzania (dzień
   grzewczy i T < T_gr — te same godziny co w binach).
4. W binie: średnia `Φ_m` z godzin, które do niego trafiają → suma po binach =
   suma godzinowa. Ten sam rozkład w profilach godzinowych (PV, taryfa).
5. Dobór mocy (punkt biwalentny, pokrycie) zostaje na pełnym `Q_proj`.

## Pułapki (każda zdarzyła się w praktyce)

- **f_g1 = 1,45 w energii** — zawyża; to współczynnik mocy szczytowej.
- **Grunt liniowo z T powietrza** — zaniża grunt ~2,7× w sezonie.
- **θ_e,an niezgodna ze średnimi miesięcznymi** — licz ją z tego samego szeregu
  (średnia ważona godzinami = średnia godzinowa), inaczej średnia roczna Φ_m ≠ H_g·ΔT.
- **Obwód eksponowany** — bez ścian do ogrzewanego sąsiada; ten sam P co w mocy.
- **Ściany piwnicy przy sąsiedzie** — w H.7.2 człon ścian tylko z eksponowanego obwodu.
- **Piwnica nieogrzewana** — część stała H_g z TEGO SAMEGO modelu co moc
  (np. `U_strop·A·b_u`), inaczej energia i moc liczą dwie różne piwnice.
- **Zyski ciepła** — linia obciążenia zakłada zyski niejawnie; po wyjęciu gruntu
  z linii zyski „kryją” już tylko resztę strat → energia rośnie. Opisz to wprost.
- **TMY 8760 h** — miesiące wg 31/28/31/… dni; rok przestępny wymaga obsługi.

## Wartości kontrolne (do testów)

- δ(1,5 / 2,0 / 3,5) = 2,24 / 3,17 / 4,19 m.
- Piwnica ogrzewana z z = 0 → H_pe = H_pe płyty (H.7.2 → H.4.2).
- Średnia roczna Φ_m (ważona godzinami miesięcy) = H_g·(θ_i − θ_e,an); styczeń > lipiec.
- Płyta 100 m², P = 40 m, w = 0,39 m, R_f = 4,61 m²K/W, λ = 2,0: d_t = 10,03 m,
  U = 0,162, H_g = 16,2 W/K, H_pe = 8,1 W/K; Warszawa (TMY PVGIS, θ_e,an 9,7 °C):
  Φ_m od 243 W (I) do 76 W (VII); w sezonie 1139 kWh wobec 422 kWh liniowo.
