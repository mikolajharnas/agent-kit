---
name: cwu-zapotrzebowanie
description: >
  Zapotrzebowanie na ciepłą wodę użytkową (c.w.u.) wg rodzaju obiektu:
  jednostkowe zużycie, profil godzinowy, energia roczna, moc średnia
  i szczytowa, dobór zasobnika i mocy ładowania — wg projektu metodologii
  charakterystyki energetycznej (tabele 28–36) oraz PN-92/B-01706 (Nh).
  Użyj ZAWSZE, gdy liczysz lub sprawdzasz c.w.u. budynku innego niż dom
  jednorodzinny (wielorodzinny, hotel, akademik, DPS, biuro, szkoła,
  przedszkole, przychodnia, szpital, gastronomia, handel, basen, hala),
  gdy ktoś pyta „czy moc średnia / szczytowa c.w.u. jest za niska”, gdy
  dokumentacja podaje Nh albo litry na osobę, oraz przy doborze pompy ciepła
  z zasobnikiem dla obiektu zbiorowego. Towarzyszące: [[analiza-dokumentacji-hvac]].
---

# Zapotrzebowanie na c.w.u. wg rodzaju obiektu

## Najważniejsze: ta sama liczba osób daje zupełnie różne wyniki

Dla 45 jednostek (woda 55 °C, 10 °C z sieci, k_R = 0,9):

| Obiekt | l/dobę | kWh/rok | średnia doby | średnia w godz. poboru | najwyższa godzina | zasobnik* |
|---|---|---|---|---|---|---|
| hotel / akademik / DPS (miejsca) | 2025 | ~35 000 | 4,4 kW | 5,6 kW | 7,7 kW | ~460 l |
| biuro (zatrudnieni) | 315 | ~3 800 | 0,7 kW | 1,5 kW | 2,0 kW | ~180 l |
| szkoła (uczniowie) | 450 | ~4 400 | 1,0 kW | 2,0 kW | 2,7 kW | ~230 l |
| przychodnia (zatrudnieni) | 675 | ~8 000 | 1,5 kW | 3,0 kW | 4,0 kW | ~340 l |
| szpital (łóżka) | 9000 | ~145 000 | 19,6 kW | 19,6 kW | 28,7 kW | ~1800 l |

\* pojemność UŻYTECZNA przy 55 °C, gdy źródło ładuje stałą mocą = średnia doby.

Liczenie każdego obiektu „jak dom” (osoby × 50 l × 365 dni) daje dla wszystkich ~4,2 kW:
w hotelu poprawnie, w biurze/szkole zawyżone 4–7×, w szpitalu zaniżone ~5×.

## Źródło i jego status

Projekt metodologii obliczania charakterystyki energetycznej (załącznik 1 do projektu
rozporządzenia MRiT, pkt 6.3.2) — tabele 28–36. To PROJEKT (data w nagłówku pusta):
przy cytowaniu w piśmie podawaj „wg projektu metodologii”, a przy obowiązującym
rozporządzeniu z 2015 r. sprawdź, czy wartości się nie różnią.
PDF bywa nieczytelny dla narzędzi pobierających strony — pobrany plik czytaj
PyMuPDF (`fitz`), tabele są w liniach tekstu.

PN-92/B-01706 (wzór Nh) **wycofana w 2009 r. bez następczyni** — wolno jej używać
jako metody inżynierskiej, ale nie jako „obowiązującej normy”.

## Wzory (metodologia)

- Godzinowe zużycie: `V_CW,k = n_k · (V_W / 24) · J_O · k_ARM · k_R`  (wzór 37)
- Roczne (metoda miesięczna, mieszkalne): `V_CW,r = V_W · J_O · k_ARM · t_R · k_R`  (38)
- Ciepło: `Q_W = V_CW · c_W · ρ_W · (θ_CW − θ_0) / 3600` → w praktyce
  `kWh = litry × 0,001164 × (θ_CW − θ_0)`
- `n_k` — współczynnik godziny względem średniej z 24 h; suma doby = 24 (wyjątki niżej)
- `V_W` — jednostkowe zużycie z tabeli 33 (przy θ_CW), `J_O` — liczba jednostek odniesienia
- `k_R = 0,9` (przerwy w użytkowaniu), `k_ARM` — armatura oszczędzająca (tab. 35)
- `θ_CW = 55 °C` dla budynków od 2003 r. (45 °C starsze), `θ_0 = 10 °C` (25 °C przy odzysku ciepła)

Tabela 33, profile 28–31, tabele 35 i 36 — pełne wartości w [tabele-metodologia.md](tabele-metodologia.md).

## Pułapki (każda zdarzyła się w praktyce)

1. **Nh z PN-92 tylko dla budynków mieszkalnych i z τ = 18 h.**
   `Nh = 9,32 · U^(−0,244)`, a średnia godzinowa to `V_d / τ` z **τ = 18 h**, nie /24 h.
   Dzielenie przez 24 zaniża szczyt o 1/4 (45 osób: 15,3 zamiast 20,4 kW).
   Do biur i szkół wzoru Nh NIE stosować — mają własne profile.
2. **Moc „średnia” do doboru źródła = średnia najcięższej doby, nie średnia z roku.**
   Średnią roczną zaniżają weekendy i wakacje (biuro: roczna 0,43 kW, dzień roboczy 0,69 kW).
3. **Energia nie zależy od nastawy zasobnika.** Użytkownik potrzebuje tej samej wody
   na kranie: przy niższej nastawie zużywa WIĘCEJ litrów ciepłej (mniej domieszki zimnej),
   ciepła tyle samo. Liczenie `litry × (nastawa − zimna)` ze stałymi litrami tworzy
   fikcyjną oszczędność. Nastawa zmienia COP pompy, wielkość zasobnika i straty pętli.
   Litry przy nastawie: `V_nast = V_ref · (T_ref − T_zimna) / (T_nast − T_zimna)`.
4. **„50 l na osobę” to reguła dla mieszkańca domu** (przy ~48 °C, reguła Kołton),
   ≈ 40 l przy 55 °C wg tabeli 33. Pracownik biura to 7 l, uczeń 10 l, łóżko szpitalne 200 l.
5. **Błąd druku w projekcie: profil gastronomii** — 13 h × 1,15 = 14,95 zamiast 24
   (handel: 13 h × 1,85 = 24,05). Dosłownie znika 38 % zużycia z tabeli 33 — skaluj do 24
   i napisz o tym. **Szpital w weekend** sumuje się do 19,0 — prawdopodobnie celowo
   (mniej zabiegów), zostaw.
6. **Sport (baseny, hale):** metodologia każe ustalić profil „indywidualnie” —
   przyjmij godziny otwarcia (np. 7–22 równomiernie) i zaznacz to jako założenie.
7. **Oświata: w lipcu i sierpniu n_k = 0** (przypis do tabeli 29). Dni ustawowo wolne
   traktuj jak weekend.
8. **Straty zasobnika i pętli cyrkulacyjnej biegną codziennie**, także w dni bez poboru
   (weekend biura) — doliczaj `straty × 365`, a w profilu godzinowym rozkładaj je równo.

## Dobór zasobnika i mocy ładowania (pompa ciepła)

Źródło ładuje stałą mocą `P`; zasobnik pokrywa nadwyżkę rozbioru nad `P`:

```python
def zasobnik_kwh(q_doba, n24, P):
    """Największy skumulowany deficyt [kWh] — liczony na 2 dobach (przez północ)."""
    kum = najw = 0.0
    for n in list(n24) * 2:
        kum = max(0.0, kum + n * q_doba / 24 - P)
        najw = max(najw, kum)
    return najw
```

- `P` = średnia najcięższej doby → zasobnik wychodzi najmniejszy możliwy przy ładowaniu ciągłym:
  hotel ~23 % rozbioru dobowego, biuro ~57 % (cały pobór w 11 h).
- Litry przy nastawie: `kWh / (0,001164 × (T_nast − T_zimna))`, potem / 0,8 (użyteczne
  80 % — warstwowanie), zaokrąglij w górę do 50 l.
- Większa moc ładowania → mniejszy zasobnik (bisekcja po `P`, jeśli zasobnik jest dany).
- Moc szczytowa (najwyższa godzina profilu albo Nh) służy do wężownicy, przepływu
  i liczby jednostek kaskady na c.w.u. — NIE do doliczania do obciążenia budynku.

## Jak przedstawiać wynik

Zawsze podawaj obok siebie: rodzaj obiektu i jednostkę, zużycie przy 55 °C, energię
roczną, średnią doby, średnią w godzinach poboru, najwyższą godzinę, zasobnik.
Jeśli dokumentacja podaje jedną „moc c.w.u.” — zapytaj/ustal, którą z tych wielkości.
