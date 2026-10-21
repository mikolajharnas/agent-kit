---
name: cena-pradu-taryfy-ure
description: >
  Cena 1 kWh prądu dla gospodarstwa domowego z taryf zatwierdzonych przez
  Prezesa URE (G11, G12, G12w, G13) — z czego się składa, ile wynosi
  u operatorów (Tauron, PGE, Enea, Energa), godziny stref, jak ją
  przeliczyć do kosztu pracy pompy ciepła i jak co roku zaktualizować.
  Użyj ZAWSZE, gdy liczysz koszt ogrzewania pompą ciepła, porównujesz
  z gazem/pelletem, piszesz ofertę lub pismo z kosztami eksploatacji,
  ustawiasz domyślne ceny w kalkulatorze, albo ktoś pyta „ile kosztuje
  kWh w G12”, „czy G12 się opłaca”, „jaka cena prądu w 2026/2027”.
---

# Cena prądu z taryf URE (gospodarstwa domowe, grupy G)

## Z czego składa się cena dodatkowej kWh

Pompa zmienia rachunek o koszt KAŻDEJ DODATKOWEJ kWh — liczą się tylko składniki zmienne:

```
cena brutto [zł/kWh] = (energia + dystrybucja zmienna + jakościowa + OZE
                        + kogeneracyjna + akcyza) × 1,23
```

- **energia** — cena sprzedawcy z urzędu na terenie operatora (PGE Obrót, Tauron Sprzedaż, Enea, Energa-Obrót);
- **dystrybucja zmienna** — składnik zmienny stawki sieciowej operatora (OSD), osobny dla każdej strefy;
- **opłaty 2026 (netto):** jakościowa 0,0331 · OZE 0,0073 · kogeneracyjna 0,0030 zł/kWh;
- **akcyza 0,005 zł/kWh** — ceny energii w taryfach są BEZ akcyzy i VAT (np. pkt 1.6 taryfy Enea).
  Pułapka: portale podają „brutto” energii = (netto + 0,005) × 1,23, co nie zgadza się
  z netto × 1,23 — to akcyza, nie błąd;
- **pomijamy opłaty stałe** — abonament, składnik stały sieciowej, opłata mocowa (u odbiorców G
  ryczałt miesięczny wg przedziału zużycia), od 2026 opłata przejściowa zniesiona.
  Nie zależą od pracy pompy.

## Stawki 2026 — wynik [zł/kWh brutto]

| Taryfa | Tauron | PGE | Enea | Energa |
|---|---|---|---|---|
| G11 | 0,97 | 1,10 | 0,97 | 1,10 |
| G12 dzień / noc | 1,08 / 0,64 | 1,25 / 0,61 | 1,11 / 0,59 | 1,24 / 0,62 |
| G12w szczyt / poza | 1,23 / 0,63 | 1,30 / 0,68 | 1,19 / 0,59 | 1,30 / 0,65 |
| G13 przedpoł. / popoł. / reszta | 0,90 / 1,50 / 0,63 | — | — | — |

- **G13 dla domu ma w ofercie tylko Tauron** — u innych operatorów przyjmij ceny Tauronu i napisz to.
- Różnica G11 między operatorami ~13 % (0,97 vs 1,10) — przy koszcie rocznym trzeba
  wiedzieć, kto jest operatorem (część „dystrybucja” na rachunku). Regiony orientacyjnie:
  Tauron — południe (Małopolska, Śląsk, Opolszczyzna, Dolny Śląsk), PGE — wschód i centrum,
  Enea — zachód i północny zachód, Energa — północ.
- Składniki netto (energia + dystrybucja per strefa) i źródła — [stawki-2026.md](stawki-2026.md).

**Kontrola sumy (zawsze zrób przed użyciem nowych stawek):** PGE G11 = 1,10 i strefa nocna
G12 = 0,61 zł/kWh — te same liczby podaje dla 2026 WysokieNapiecie.pl. Jeśli Twoja suma się
nie zgadza z niezależną publikacją, szukaj brakującego składnika (najczęściej akcyza).

## Godziny stref (domyślne = taryfa TAURON Dystrybucja 2026, sprawdzona)

- **G12:** tania 22:00–6:00 i 13:00–15:00 codziennie. PGE: latem (IV–IX) dolina popołudniowa
  **15:00–17:00** zamiast 13–15 — jedyny operator ze zmianą sezonową.
- **G12w:** jak G12 w dni robocze; soboty, niedziele, święta całe tanie. Enea w G12w bywa
  bez doliny popołudniowej (tania 21–6) — sprawdź u operatora.
- **G13 (Tauron):** szczyt przedpołudniowy 7–13; popołudniowy 16–21 (X–III) / 19–22 (IV–IX);
  reszta godzin i całe dni wolne — strefa 3.

Dla pompy ciepła sezonowe różnice godzin latem mają znikome znaczenie (latem grzeje tylko c.w.u.).

## Jak liczyć koszt pracy pompy w taryfie strefowej

NIE średnią z suwaka „udział taniej strefy”. Pompa bierze najwięcej prądu w mroźne noce
(tania strefa), mało w letnie popołudnia. Poprawnie: dla każdej godziny roku typowego
(TMY) cena wg strefy (kalendarz roku: dni robocze, weekendy, święta) → dla każdego binu
temperatury średnia cena godzin, które w nim są → koszt bin po binie. Do porównań
z paliwami jedna liczba: cena ważona zapotrzebowaniem na ciepło (waga ∝ T_gr − T).

## Aktualizacja co roku

1. Prezes URE zatwierdza taryfy G zwykle **w połowie grudnia** (2026: decyzje z 17.12.2025),
   obowiązują 1.01–31.12.
2. Źródła: komunikat URE + taryfy na stronach sprzedawców i operatorów (PDF), stawki opłat
   OZE (decyzja Prezesa URE) i kogeneracyjnej (rozporządzenie ministra), jakościowa (PSE/OSD).
3. Strony PGE i części operatorów blokują pobieranie przez narzędzia (odrzucenie, certyfikat).
   Zestawienia przepisujące taryfy (np. elektryka.edu.pl) bywają dobre — ale sprawdź choć
   jeden komplet w oryginale (wyciąg z taryfy OSD, taryfa sprzedawcy) i sumę kontrolną.
4. Pobrany PDF czytaj PyMuPDF (`fitz`) — liczby są w liniach tekstu.
5. W kodzie: tabele per operator + rok stawek w jednym miejscu, test z liczbami z dokumentów
   i sumą kontrolną z prasy (implementacja referencyjna: kalkulator AirAdapt, `taryfy.py`,
   `test_taryfy_strefowe.py`).
