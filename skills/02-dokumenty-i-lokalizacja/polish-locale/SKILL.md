---
name: polish-locale
description: >
  Użyj tego skilla ZAWSZE, gdy użytkownik prosi o: wygenerowanie raportu Word (.docx),
  dokumentu PDF, prezentacji PowerPoint (.pptx), napisanie programu Python (.py),
  aplikacji desktopowej (.exe, PyInstaller, cx_Freeze, tkinter, PyQt, wxPython),
  lub jakiegokolwiek skryptu/narzędzia, które generuje raporty, pliki tekstowe
  lub wyświetla tekst użytkownikowi. Skill zapewnia poprawne użycie polskich znaków
  (ą ć ę ł ń ó ś ź ż Ą Ć Ę Ł Ń Ó Ś Ź Ż), kodowania UTF-8, polskich ustawień
  regionalnych i języka polskiego we wszystkich tworzonych plikach i programach.
  Stosuj ten skill nawet jeśli użytkownik nie wspomniał wprost o polskich znakach —
  zawsze gdy kontekst rozmowy jest po polsku i tworzone są dokumenty lub programy.
---

# Polish Locale Skill — Polskie znaki i kodowanie

## Zasada nadrzędna

**Wszystkie tworzone dokumenty, prezentacje, skrypty i programy MUSZĄ:**
- używać kodowania **UTF-8**
- stosować poprawne polskie znaki diakrytyczne: `ą ć ę ł ń ó ś ź ż` (i wielkie)
- używać języka polskiego w treści skierowanej do użytkownika końcowego
- nigdy nie zastępować polskich liter zamiennikami ASCII (np. `a` zamiast `ą`, `c` zamiast `ć`)

---

## 1. Dokumenty Word (.docx)

Przy tworzeniu dokumentu Word przez `docx-js` lub `python-docx`:

```python
# python-docx — zawsze UTF-8 (domyślne, ale upewnij się)
from docx import Document
doc = Document()
doc.add_paragraph("Zażółć gęślą jaźń — próba polskich znaków")
doc.save("raport.docx")
```

**Czcionka z polskimi znakami** — preferowane czcionki obsługujące polskie znaki:
- `Calibri`, `Arial`, `Times New Roman`, `Segoe UI` — wszystkie obsługują polskie znaki
- **NIE używaj** czcionek bez glyfów dla liter ą ć ę ł ń ó ś ź ż

**W XML docx** — upewnij się, że deklaracja XML zawiera `encoding="UTF-8"`:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
```

---

## 2. Dokumenty PDF

### Przez WeasyPrint / reportlab / fpdf2

```python
# fpdf2 — ustaw UTF-8 i załaduj czcionkę z polskimi znakami
from fpdf import FPDF

pdf = FPDF()
pdf.add_page()
# Użyj czcionki obsługującej Unicode (DejaVu, FreeSerif, lub wbudowane w fpdf2)
pdf.add_font("DejaVu", "", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")
pdf.set_font("DejaVu", size=12)
pdf.cell(200, 10, txt="Raport — Zażółć gęślą jaźń", ln=True)
pdf.output("raport.pdf")
```

```python
# reportlab — rejestruj czcionkę TTF z polskimi znakami
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
pdfmetrics.registerFont(TTFont('DejaVu', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'))
```

```python
# WeasyPrint — użyj HTML/CSS z deklaracją charset
html = """<!DOCTYPE html>
<html lang="pl">
<head><meta charset="UTF-8"><title>Raport</title></head>
<body><p>Zażółć gęślą jaźń</p></body>
</html>"""
```

### Instalacja czcionek na Ubuntu (jeśli brak):
```bash
apt-get install -y fonts-dejavu-core fonts-liberation
```

---

## 3. Prezentacje PowerPoint (.pptx)

```python
from pptx import Presentation
from pptx.util import Pt
from pptx.dml.color import RGBColor

prs = Presentation()
slide = prs.slides.add_slide(prs.slide_layouts[1])

# Ustaw polski tekst
title = slide.shapes.title
title.text = "Raport kwartalny — podsumowanie wyników"

# Upewnij się, że czcionka obsługuje polskie znaki
from pptx.util import Pt
tf = slide.placeholders[1].text_frame
tf.text = "Zażółć gęślą jaźń — dane za Q1"
```

**Czcionki w PPTX** — domyślne czcionki Office (`Calibri`, `Arial`) obsługują polskie znaki.
Jeśli używasz niestandardowych czcionek, sprawdź czy zawierają glify dla ą ć ę ł ń ó ś ź ż.

---

## 4. Programy Python (.py)

### Nagłówek każdego skryptu Python

```python
# -*- coding: utf-8 -*-
```

> **Uwaga:** W Python 3 UTF-8 jest domyślne, ale dla jasności i kompatybilności zawsze dodawaj ten nagłówek.

### Obsługa wejścia/wyjścia z polskimi znakami

```python
import sys
import io

# Wymuszenie UTF-8 na stdout/stderr (ważne na Windows)
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
```

### Zapis i odczyt plików

```python
# ZAWSZE jawnie podawaj encoding='utf-8'
with open("raport.txt", "w", encoding="utf-8") as f:
    f.write("Podsumowanie: łączna wartość zamówień wynosi 1 200 zł\n")

with open("dane.csv", "r", encoding="utf-8") as f:
    dane = f.read()
```

### Ustawienia lokalne (locale)

```python
import locale

# Dla formatowania liczb, dat po polsku
try:
    locale.setlocale(locale.LC_ALL, 'pl_PL.UTF-8')
except locale.Error:
    # Fallback jeśli pl_PL niedostępne (np. Windows bez pakietu językowego)
    locale.setlocale(locale.LC_ALL, '')
```

---

## 5. Aplikacje desktopowe (.exe) — PyInstaller, tkinter, PyQt

### tkinter

```python
# -*- coding: utf-8 -*-
import tkinter as tk

root = tk.Tk()
root.title("Aplikacja — Zarządzanie zamówieniami")

label = tk.Label(root, text="Witaj! Wpisz nazwę:")
label.pack()

root.mainloop()
```

### PyQt5 / PyQt6

```python
# -*- coding: utf-8 -*-
import sys
from PyQt5.QtWidgets import QApplication, QLabel, QMainWindow
from PyQt5.QtCore import QTextCodec

# Upewnij się, że Qt używa UTF-8
QTextCodec.setCodecForLocale(QTextCodec.codecForName("UTF-8"))

app = QApplication(sys.argv)
window = QMainWindow()
window.setWindowTitle("Raport — Kołton Sp.K.")
label = QLabel("Dane techniczne: sprawność η = 98%")
window.setCentralWidget(label)
window.show()
sys.exit(app.exec_())
```

### PyInstaller — budowanie .exe z polskimi znakami

```bash
# Upewnij się, że skrypt ma nagłówek # -*- coding: utf-8 -*-
# i dodaj opcję --uac-admin jeśli potrzebne

pyinstaller --onefile --windowed ^
  --name "NazwaAplikacji" ^
  moj_program.py
```

**Na Windows** — dodaj manifest UTF-8 lub ustaw zmienną środowiskową:
```bash
set PYTHONUTF8=1
```

Lub w kodzie (Python 3.7+):
```python
import os
os.environ["PYTHONUTF8"] = "1"
```

---

## 6. Raporty generowane programowo (CSV, TXT, HTML, XLSX)

### CSV

```python
import csv

with open("raport.csv", "w", encoding="utf-8-sig", newline="") as f:
    # utf-8-sig dodaje BOM — Excel na Windows poprawnie odczyta polskie znaki
    writer = csv.writer(f, delimiter=";")
    writer.writerow(["Lp.", "Nazwa produktu", "Wartość (zł)", "Uwagi"])
    writer.writerow([1, "Kocioł pelletowy PELLSMART", "12 500,00", "Dostępny"])
```

> Użyj `utf-8-sig` (z BOM) dla plików otwieranych w Excel — bez BOM Excel może źle interpretować polskie znaki.

### Excel (openpyxl)

```python
from openpyxl import Workbook

wb = Workbook()
ws = wb.active
ws.title = "Dane"
ws["A1"] = "Nazwa urządzenia"
ws["B1"] = "Sprawność"
ws["A2"] = "Pompa ciepła Kołton 12 kW"
ws["B2"] = "98%"
wb.save("raport.xlsx")
# openpyxl domyślnie zapisuje UTF-8 — polskie znaki działają od razu
```

### HTML

```html
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <title>Raport techniczny</title>
</head>
<body>
  <h1>Zestawienie urządzeń grzewczych</h1>
  <p>Sprawność: η ≥ 92% przy temperaturze źródła 7°C/35°C</p>
</body>
</html>
```

---

## 7. Szybka lista kontrolna przed oddaniem pliku

| Element | Wymaganie |
|---|---|
| Kodowanie pliku źródłowego | UTF-8 |
| Nagłówek skryptu Python | `# -*- coding: utf-8 -*-` |
| Otwarcie pliku tekstowego | `encoding='utf-8'` lub `'utf-8-sig'` |
| CSV dla Excel | `encoding='utf-8-sig'` |
| Czcionka w PDF/DOCX/PPTX | obsługuje ą ć ę ł ń ó ś ź ż |
| Deklaracja HTML | `<meta charset="UTF-8">` |
| Windows exe | `PYTHONUTF8=1` lub `io.TextIOWrapper` |
| Tekst interfejsu użytkownika | po polsku, bez ASCII-zamienników |

---

## 8. Testowanie polskich znaków

Standardowy ciąg testowy dla polskich znaków:
```
Zażółć gęślą jaźń — ą ć ę ł ń ó ś ź ż Ą Ć Ę Ł Ń Ó Ś Ź Ż
```

Zawiera wszystkie polskie litery diakrytyczne — jeśli ten ciąg wyświetla się poprawnie, kodowanie działa.
