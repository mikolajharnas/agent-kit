---
name: pptx-no-image-slides
description: >
  Użyj tego skilla ZAWSZE gdy użytkownik prosi o stworzenie slajdu, prezentacji,
  lub mówi "zrób slajd", "zrób slide", "zrób prezentację", "dodaj slajd".
  Skill zakazuje tworzenia grafik (SVG, PNG, HTML) jako substytutu slajdu
  i wymusza tworzenie prawdziwego edytowalnego pliku .pptx przez pptxgenjs,
  gdzie każdy element (tytuł, tekst, wykres, ikona) jest osobnym edytowalnym
  obiektem na slajdzie — nigdy wklejonym obrazkiem. Stosuj nawet jeśli
  wcześniej w rozmowie powstała grafika SVG/HTML przypominająca slajd.
---

# PPTX — slajdy jako edytowalne obiekty, nie obrazki

## Zakaz bezwzględny

**NIGDY nie rób:**
- grafiki SVG i nie wklejaj jej jako obrazka do slajdu
- zrzutu HTML/widgetu i nie osadzaj go jako PNG w slajdzie
- slajdu który jest jednym wielkim obrazkiem z tekstem

**Każdy element slajdu musi być osobnym edytowalnym obiektem pptxgenjs:**
- tytuł → `slide.addText()`
- treść / bullet points → `slide.addText()` z tablicą obiektów
- wykres → `slide.addChart()`
- tabela → `slide.addTable()`
- kształt/tło → `slide.addShape()`
- logo/zdjęcie → `slide.addImage()` — tylko prawdziwe grafiki, nie screenshot slajdu

---

## Workflow — zawsze pptxgenjs

Przy każdym "zrób slajd" lub "zrób prezentację":

1. Wczytaj skill `/mnt/skills/public/pptx/SKILL.md` i `pptxgenjs.md`
2. Napisz skrypt `.js` używający pptxgenjs
3. Uruchom przez `node skrypt.js`
4. Zweryfikuj przez `python scripts/thumbnail.py` (podgląd)
5. Oddaj plik `.pptx` przez `present_files`

**Nie twórz wizualizacji SVG/HTML jako "podglądu" slajdu** — to prowadzi do
pokusy wklejenia jej jako obrazka. Jeśli trzeba pokazać koncepcję układu,
opisz go słownie i od razu buduj `.pptx`.

---

## Grafiki jako elementy slajdu — kiedy addImage() jest OK

`addImage()` jest prawidłowe TYLKO dla:
- logotypów firmy (`.png`, `.svg`)
- zdjęć produktów, zdjęć technicznych
- ikon (`.png`, `.svg`) jako elementów dekoracyjnych

`addImage()` jest **zabronione** gdy:
- obrazek zawiera tekst który powinien być edytowalny
- obrazek to screenshot innego slajdu lub grafiki SVG
- obrazek zastępuje wykres lub tabelę którą można zbudować natywnie

---

## Przykład poprawnej struktury slajdu

```javascript
const pptx = require("pptxgenjs");
const prs = new pptx();

const slide = prs.addSlide();

// ✅ Tytuł jako edytowalny tekst
slide.addText("Wyniki sprzedaży Q1 2025", {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 28, bold: true, color: "1F3864"
});

// ✅ Bullet points jako edytowalna lista
slide.addText([
  { text: "Przychód: 1,2 mln zł", options: { bullet: true, fontSize: 18 } },
  { text: "Wzrost o 12% r/r",     options: { bullet: true, fontSize: 18 } },
  { text: "Nowi klienci: 34",     options: { bullet: true, fontSize: 18 } },
], { x: 0.5, y: 1.3, w: 6, h: 3 });

// ✅ Wykres słupkowy jako natywny obiekt
slide.addChart(prs.ChartType.bar, [
  { name: "Przychód", labels: ["Q1","Q2","Q3"], values: [120,145,160] }
], { x: 6.5, y: 1.3, w: 3, h: 3 });

// ✅ Logo jako addImage — to jest OK bo to prawdziwy plik graficzny
slide.addImage({ path: "logo.png", x: 8.5, y: 0.1, w: 1.2, h: 0.5 });

prs.writeFile({ fileName: "raport.pptx" });
```

---

## Jeśli użytkownik pyta "czy mogę edytować ten slajd w PowerPoint?"

Odpowiedź musi być **TAK** — każdy tekst, każdy wykres, każda tabela
muszą być edytowalne po otwarciu pliku w PowerPoint lub LibreOffice Impress.
Jeśli jakikolwiek element jest obrazkiem zamiast natywnego obiektu — to błąd,
który trzeba naprawić przed oddaniem pliku.
