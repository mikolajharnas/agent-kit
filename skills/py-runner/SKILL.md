---
name: py-runner
description: Uruchamianie skryptow i kodu Python na Windowsie. Uzyj zawsze gdy trzeba odpalic plik .py lub fragment kodu Python na tym systemie, bo komenda `python` nie dziala (stub Windows) — uzywa sie launchera `py -3`.
---

# py-runner

Na Windows komenda `python` / `python3` czesto jest stubem ze sklepu Microsoft i nie dziala
(otwiera Microsoft Store zamiast uruchomic kod). Uruchamiaj Pythona przez launcher `py`:

    py -3 skrypt.py

## Zasady

- Plik:           `py -3 sciezka\do\pliku.py`
- Jednolinijkowiec: `py -3 -c "print('hej')"`
- Wersja:         `py -3 --version`
- Lista wersji:   `py --list`
- NIE uzywaj `python` ani `python3`.

## Weryfikacja

Po uruchomieniu sprawdz kod wyjscia i output. Jesli `py` nie istnieje, sprawdz instalacje
Pythona (`py --list`). Jesli brak jakiejkolwiek wersji — Python nie jest zainstalowany.
