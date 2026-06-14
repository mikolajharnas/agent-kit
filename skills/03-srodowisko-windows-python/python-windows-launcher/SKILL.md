---
name: python-windows-launcher
description: >
  Użyj tego skilla ZAWSZE gdy tworzysz aplikację Python przeznaczoną do uruchomienia
  na Windows — skrypt .py, aplikację tkinter, Streamlit, PyQt, lub cokolwiek co
  użytkownik ma uruchomić przez plik .bat lub bezpośrednio. Skill zapewnia że plik
  uruchomieniowy (.bat) używa "py -3" zamiast "python", co rozwiązuje problem
  migającego i znikającego okna CMD na komputerach gdzie stary Python 2.x
  (zainstalowany przez oprogramowanie branżowe: CAD, CNC, BMS, sterowniki)
  przechwytuje komendę "python". Stosuj nawet jeśli użytkownik nie wspomniał
  o problemie — zawsze generuj .bat z py -3 jako domyślny szablon.
---

# Python Windows Launcher — py -3 zamiast python

## Problem (znany z praktyki)

Na komputerach z oprogramowaniem branżowym (CAD, CNC, systemy BMS, sterowniki
urządzeń przemysłowych) często jest zainstalowany **stary Python 2.x**, który
przechwytuje komendę `python` w PATH. Efekt: po uruchomieniu `.bat` okno CMD
**miga przez ułamek sekundy i znika** — aplikacja w ogóle nie startuje.

Python 2 nie ma żadnych nowoczesnych pakietów (streamlit, pandas, tkinter 3.x,
reportlab itd.) i natychmiast się wysypuje.

**Rozwiązanie:** `py -3` — Python Launcher instalowany razem z Python 3,
który zawsze omija Python 2.x i wybiera najnowszy zainstalowany Python 3.

---

## Zasada: ZAWSZE generuj .bat z py -3

Nigdy nie używaj samego `python` ani `python3` w plikach `.bat` na Windows.

| Komenda | Zachowanie na Windows |
|---|---|
| `python` | ❌ Może trafić w Python 2.x z CAD/CNC |
| `python3` | ⚠️ Nie zawsze działa na Windows |
| `py -3` | ✅ Zawsze wybiera Python 3.x, ignoruje Python 2 |

---

## Szablony uruchom.bat

### Aplikacja Streamlit

```bat
@echo off
chcp 65001 >nul
echo Uruchamianie aplikacji...
echo.
py -3 -m pip install streamlit --quiet 2>nul
py -3 -m streamlit run app.py
pause
```

### Aplikacja z requirements.txt (tkinter, pandas, itp.)

```bat
@echo off
chcp 65001 >nul
echo Sprawdzanie zaleznosci...
py -3 -m pip install -r requirements.txt --quiet
echo Uruchamianie...
py -3 main.py
pause
```

### Skrypt bez zewnętrznych pakietów

```bat
@echo off
chcp 65001 >nul
py -3 main.py
pause
```

---

## Zabezpieczenie w main.py

Dodaj zawsze na początku głównego skryptu:

```python
import sys
if sys.version_info[0] < 3:
    print("BŁĄD: Ta aplikacja wymaga Python 3!")
    print(f"Wykryty Python: {sys.version}")
    print("Uruchom przez: py -3 main.py  lub użyj pliku uruchom.bat")
    input("Naciśnij Enter aby zamknąć...")
    sys.exit(1)
```

---

## Komentarz w pliku .bat

Zawsze dodawaj komentarz wyjaśniający dlaczego `py -3`:

```bat
:: UWAGA: używamy "py -3" zamiast "python".
:: Na niektórych komputerach stary Python 2.x z oprogramowania branżowego
:: (CAD, CNC, sterowniki) przechwytuje komendę "python" i powoduje
:: że okno CMD miga i znika. "py -3" używa Python Launchera i omija Python 2.
```
