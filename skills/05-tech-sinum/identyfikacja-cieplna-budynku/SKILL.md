---
name: identyfikacja-cieplna-budynku
description: >
  Identyfikacja parametrów cieplnych budynku (H_b, C_b, tau, szybkość wychładzania, predykcja Ti,
  pewność) na sterowniku, do sterowania predykcyjnego MPC pompą ciepła. Model RC 1R1C, estymacja
  rekurencyjna (RLS) z czynnikami zapominania jako oknami czasowymi, warianty danych 1-4 (co da się
  wyznaczyć przy jakim zestawie), filtry próbek (skok, min ΔT, swobodny dryf, noc), confidence + pasma
  zaufania, pułapka kwantyzacji i doboru kroku, tryb testowy do wymuszeń (lodówka), oraz uczciwe granice
  (V1 = tylko tau; bez Q_CO nie zidentyfikujesz w trakcie grzania). Towarzyszące: [[sinum-custom-device-runtime]].
---

# Identyfikacja cieplna budynku (na sterowniku)

Metoda i pułapki z device 40 „Badanie budynku". Implementacja-specyfika SINUM: [[sinum-custom-device-runtime]].

## Model i postać regresyjna
1R1C:  `C_b·dT_i/dt = Q_CO − H_b·(T_i − T_e) + Q_z`
Regresja (krok h godzin, y = dT_i/dt):  `y = a·Q_CO − b·(T_i − T_e) + c`
gdzie `a=1/C_b`, `b=H_b/C_b=1/τ`, `c=Q_z/C_b` →  `C_b=1/a`, `H_b=b/a`, `τ=1/b`, wychładzanie@20K = `20·b`.

## Estymacja online (NIE batch) — dlaczego
Sterownik nie zmieści batchu po 30 d/sezonie/roku (pamięć + limit czasu callbacku = ban). Użyj **RLS**
(rekurencyjny LS) z czynnikiem zapominania λ; **kilka estymatorów o różnym λ = różne okna** (≈ `e^(-Δt/horyzont)`,
np. 1h/24h/7d/30d). O(1) pamięci, stan trzymaj trwale (patrz [[sinum-custom-device-runtime]] §1,3).

## Próbkowanie i KWANTYZACJA (kluczowa pułapka)
Czujniki mają kwant **0,1 °C**. Przy kroku 1 min temperatura ledwie drgnie → `dT/dt` to szum kwantu
(naprzemiennie 0 i „skok" = ile kresek przeskoczyło). **Krok estymacji musi być na tyle długi, by ΔT_i
objęło kilka kwantów** — dla wolnego budynku ~**15 min**; krótki krok (3 min) tylko przy **silnym, szybkim
wymuszeniu** (lodówka). Liczy: y=(T_i_now − T_i_anchor)/elapsed, cechy uśredniaj po interwale.

## Warianty danych (co da się wyznaczyć)
- **V1 — tylko temperatury:** TYLKO `τ` i szybkość wychładzania. **H_b i C_b NIErozdzielne** — raportuj „—",
  nie udawaj. Pewność z sufitem (~0,5).
- **V2 — + moc pompy:** przybliżone H_b,C_b (nie cała moc idzie do budynku) — niższa pewność.
- **V3 — + ciepłomierz CO:** najlepszy minimalny zestaw; H_b i C_b.
- **V4 — pełny (pompa+ciepłomierz):** + bufor, COP_real.
Auto-detekcja z device_selektorów.

## Filtry próbek (odrzucaj zaklócone)
- **|dT_i/dt| > max_rate** [K/h] → „skok" (otwarte okno/glitch).
- **|T_i − T_e| < min_dt** [K] → „małe ΔT" (straty za małe by mierzyć).
- **Swobodny dryf (V1, gdy Q nieznane):** ucz się tylko gdy `sign(dT/dt) == sign(T_e − T_i)` (ruch KU równowadze).
  Odrzuca aktywne grzanie/chłodzenie/AC. Działa lato (T_i<T_e, ogrzewa się) i zima (T_i>T_e, stygnie).
- **Tryb nocny** (22–6) → mniej zysków słonecznych.

## Confidence + pasma zaufania
0..1 z: liczby próbek, zakresu T_e, dopasowania (pseudo-R²), sensowności fizycznej, sufitu wariantu (V1≈0,5).
Pokazuj słownie: `❌ nie ufaj <0,3 · ⚠️ wstępne <0,5 · 🟡 orientacyjne <0,7 · 🟢 wiarygodne <0,85 · ✅ pewne`.
Dobra pewność na złych danych = bug; **niska pewność na słabych danych = poprawne zachowanie**.

## Predykcja (swobodne wychładzanie, grzanie OFF)
`T_i(t) = T_ust + (T_i0 − T_ust)·e^(−t/τ)`, `T_ust = T_e + c/b`. Horyzonty 1/3/6/9/12/24 h.
Praktyka MPC: „o ile spadnie, gdy wyłączę grzanie na X h" → bezpieczne odstawienia pompy przy drogim prądzie.

## OGRZEWANIE — czy ma sens?
- **V1:** w trakcie grzania T_i rośnie od grzejnika, model nie wie ile → filtr swobodnego dryfu **odrzuca**
  grzanie; uczysz się tylko z faz BEZ grzania (np. nocny setback).
- **Pomiar W TRAKCIE grzania → potrzebny Q_CO** (ciepłomierz=V3 / moc pompy=V2). Wtedy model zna ciepło →
  uczy się podczas grzania i daje **H_b ORAZ C_b**.
- Sezon grzewczy jest **lepszy** do identyfikacji niż lato (więcej pobudzenia) — o ile masz Q_CO albo łapiesz fazy bez grzania.

## Tryb testowy (wymuszenie: lodówka / nagrzany czujnik)
Switch, który: **zdejmuje filtr swobodnego dryfu i nocny**, podnosi max_rate (np. 1000 K/h) i robi krok co ~3 min.
Do kontrolowanych testów na szybkiej dynamice. **Po teście wyłącz.**
- Czujnik wkładany do lodówki/grzejnika MUSI być przypisany jako **Ti (sel_rooms)** — to jego dynamikę liczymy;
  T_e niech będzie stabilnym odniesieniem (pogoda).
- Sprawdź który czujnik REALNIE stygnie/grzeje (`GET /api/v1/devices`) — nie zakładaj ID.
- Sygnatura sukcesu w logu: malejące co do modułu `dT/dt` (np. −34 → −33 → −26) = relaksacja wykładnicza.
- Wynik na czujniku to τ rzędu minut (czas czujnika), nie budynku (50–150 h) — ale dowodzi, że tor liczy poprawnie.

## Realne rzędy wielkości (budynek)
τ ≈ 50–150 h; wychładzanie@20K ≈ 0,1–0,4 K/h (możesz odstawić grzanie na godziny bez utraty komfortu —
sedno MPC). Wartości w stylu 90 K/h = czujnik + niska pewność = ignoruj.
