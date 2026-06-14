---
name: streamlit-theme-patterns
description: >
  Użyj tego skilla ZAWSZE gdy budujesz lub modyfikujesz aplikację Streamlit
  która ma motyw kolorystyczny (dark/light mode, brand colors, theme switcher).
  Skill zawiera wzorce odkryte przez wielogodzinną iterację z prawdziwą aplikacją
  produkcyjną — chroni przed konkretnymi pułapkami CSS/BaseWeb których nie widać
  w dokumentacji. Stosuj też gdy: user skarży się że checkbox/radio/tooltip mają
  zły kolor, popover ma ciemne tło w jasnym motywie, ptaszek checkboxa jest
  niewidoczny, .bat launcher miga i znika, lub zmiana motywu nie działa od razu.
---

# Streamlit Theme Patterns — wzorce z produkcji

## ZASADA NADRZĘDNA: Nigdy nie hackuj CSS natywnych komponentów

BaseWeb (silnik UI Streamlit) używa:
- `fill="white"` jako **atrybut HTML** na SVG — CSS `fill: color !important` tego NIE nadpisuje
- Inline styles w niektórych komponentach — CSS class rules przegrywają nawet z `!important`
- Portale React dla popoverów/tooltipów — nie dziedziczą CSS z głównego drzewa DOM

**Rozwiązanie:** użyj natywnego systemu motywów Streamlit zamiast walczyć z CSS.

---

## Wzorzec 1: Natywny motyw przez `_config.set_option()`

```python
def apply_native_streamlit_theme(theme_name: str):
    """Ustawia natywny motyw Streamlit.
    Musi być wywołane NA POCZĄTKU main(), przed pierwszym widgetem.
    Komponenty (checkbox, radio, tooltip, popover, sidebar) same
    renderują się w prawidłowych kolorach."""
    t = THEMES.get(theme_name, THEMES["🌙 Ciemny"])
    try:
        from streamlit import _config
        _config.set_option("theme.primaryColor",             t['primary'])
        _config.set_option("theme.backgroundColor",          t['bg'])
        _config.set_option("theme.secondaryBackgroundColor", t['secondary_bg'])
        _config.set_option("theme.textColor",                t['text'])
    except Exception:
        pass  # Graceful fallback — CSS inject jako backup
```

**Wywołanie w main():**
```python
def main():
    st.set_page_config(page_title="...", layout="wide")

    if "theme" not in st.session_state:
        st.session_state["theme"] = "🌙 Ciemny"

    # PRZED pierwszym widgetem — krytyczna kolejność!
    apply_native_streamlit_theme(st.session_state["theme"])

    # ... reszta kodu ...
```

---

## Wzorzec 2: Struktura THEMES dict

```python
THEMES = {
    "🌙 Ciemny": {                   # PEŁNA transformacja: ciemne tło, jasny tekst
        "primary":      "#fb923c",   # akcent (pomarańczowy)
        "bg":           "#0f172a",   # główne tło (granat)
        "secondary_bg": "#1e293b",   # sidebar tło
        "text":         "#f1f5f9",   # tekst (jasny)
        "muted":        "#94a3b8",   # drugoplanowy tekst
        "accent":       "#fb923c",   # hover color
        "border":       "#334155",   # ramki
    },
    "🔴 Brand (czerwony)": {          # TYLKO akcenty — białe tło, brand primary
        "primary":      "#d6222d",   # brand red (wyciągnięty z logo PNG)
        "bg":           "#ffffff",
        "secondary_bg": "#fafafa",   # NIE #fef2f2 — zbyt "kolorowe", męczy oczy
        "text":         "#1a1a1a",
        "muted":        "#666666",
        "accent":       "#b51e27",
        "border":       "#e5e5e5",
    },
    # Analogicznie dla innych jasnych motywów...
}
```

**Filozofia:**
- **Motyw Ciemny** = pełna transformacja (ciemne tło, jasne litery)
- **Motywy jasne** = tylko akcent zmienia się (primary color). Tło ZAWSZE białe.
- Jasne tła z intensywnymi kolorami (fef2f2, eff6ff) męczą przy długiej pracy
- Usuń "Wysoki kontrast" — problematyczny, trudny do utrzymania

---

## Wzorzec 3: Natychmiastowa zmiana motywu (bez opóźnienia)

Problem: `_config.set_option()` + auto-rerun po zmianie radio NIE wystarczają.
Frontend potrzebuje **drugiego rerunu** żeby przeładować natywne kolory.

```python
# Selektor motywu (w kolumnach [7,1] — kompaktowy)
title_col, theme_col = st.columns([7, 1])
with title_col:
    st.title("Nazwa aplikacji")
with theme_col:
    with st.popover("🎨", use_container_width=True):
        theme_pick = st.radio(
            "Motyw",
            list(THEMES.keys()),
            index=list(THEMES.keys()).index(st.session_state["theme"]),
            label_visibility="collapsed",
            key="theme_radio")
        st.session_state["theme"] = theme_pick

inject_theme(st.session_state["theme"])  # CSS custom elementów

# KLUCZOWE: rerun PO zamknięciu popovera, z guard anty-pętla
if st.session_state["theme"] != st.session_state.get("_applied_theme"):
    st.session_state["_applied_theme"] = st.session_state["theme"]
    st.rerun()  # wymusza przeładowanie natywnych kolorów
```

**Dlaczego guard `_applied_theme`?**
Bez niego: zmiana motywu → rerun → zmiana motywu (ta sama) → rerun → ... (nieskończona pętla)
Z guardem: drugi rerun widzi `theme == _applied_theme` → zatrzymuje się.

---

## Wzorzec 4: Minimalny `inject_theme()` (tylko custom elementy)

```python
def inject_theme(theme_name: str):
    """MINIMALNY CSS — tylko elementy których Streamlit nie kontroluje natywnie.
    Natywne komponenty obsługuje apply_native_streamlit_theme()."""
    t = THEMES.get(theme_name, THEMES["🌙 Ciemny"])
    css = f"""
    <style>
    /* CSS Variables (dla Plotly i custom HTML) */
    :root {{
        --primary: {t['primary']};
        --bg: {t['bg']};
        --text: {t['text']};
        --muted: {t['muted']};
        --border: {t['border']};
    }}

    /* BUTTONS — outline domyślnie (akcje pomocnicze), filled tylko primary */
    body [data-testid="stButton"] > button,
    body .stButton > button {{
        background-color: {t['bg']} !important;
        color: {t['primary']} !important;
        border: 1px solid {t['primary']} !important;
    }}
    body [data-testid="stButton"] > button:hover,
    body .stButton > button:hover {{
        background-color: {t['primary']} !important;
        color: #ffffff !important;
    }}
    body [data-testid="stButton"] > button[kind="primary"],
    body .stButton > button[kind="primary"] {{
        background-color: {t['primary']} !important;
        color: #ffffff !important;
        border: none !important;
    }}

    /* NUMBER INPUT ± — subtelne strzałki */
    body .stNumberInput button {{
        background-color: {t['bg']} !important;
        color: {t['text']} !important;
        border: 1px solid {t['border']} !important;
    }}

    /* FILE UPLOADER — kompaktowy (bez drag area) */
    body [data-testid="stFileUploader"] section {{
        background-color: {t['bg']} !important;
        border: 1px solid {t['primary']} !important;
        border-radius: 6px !important;
        padding: 0 !important;
        min-height: 38px !important;
    }}
    body [data-testid="stFileUploader"] section [data-testid="stFileUploaderDropzoneInstructions"],
    body [data-testid="stFileUploader"] small {{ display: none !important; }}
    body [data-testid="stFileUploader"] button {{
        background-color: transparent !important;
        color: {t['primary']} !important;
        border: none !important; outline: none !important;
        width: 100% !important; min-height: 38px !important;
    }}

    /* POPOVER TRIGGER — subtelny outline */
    [data-testid="stPopover"] button {{
        background-color: transparent !important;
        color: {t['text']} !important;
        border: 1px solid {t['border']} !important;
    }}
    </style>
    """
    st.markdown(css, unsafe_allow_html=True)
```

---

## Anti-patterny — NIGDY nie rób tego

### ❌ Szerokie selektory SVG
```css
/* ŹLE — niszczy ikony pytajnika, checkboxy, expander arrows */
[data-baseweb="checkbox"] svg { display: none !important; }
[data-baseweb="checkbox"] svg path { fill: black !important; }

/* DOBRZE — tylko visual span checkboxa */
[data-baseweb="checkbox"] > span:first-of-type svg { display: none !important; }
```

### ❌ Forsowanie fill na SVG ikon
```css
/* ŹLE — SVG ikony "?" mają 2 warstwy (outline + litera).
   fill na obu = jednolity kwadrat zamiast "?" */
[data-testid="stTooltipIcon"] svg path { fill: black !important; }

/* DOBRZE — tylko color, fill naturalnie dziedziczy przez currentColor */
[data-testid="stTooltipIcon"] { color: var(--muted) !important; }
```

### ❌ st.rerun() wewnątrz st.popover()
```python
# ŹLE — powoduje znikanie widgetów (mapy, checkboxy, dane w session_state)
with st.popover("🎨"):
    theme = st.radio(...)
    if theme != st.session_state["theme"]:
        st.session_state["theme"] = theme
        st.rerun()  # ← ŹLE

# DOBRZE — rerun POZA popoverem z guard variable
with st.popover("🎨"):
    theme = st.radio(...)
    st.session_state["theme"] = theme
# PO popoverze:
if st.session_state["theme"] != st.session_state.get("_applied_theme"):
    st.session_state["_applied_theme"] = st.session_state["theme"]
    st.rerun()  # ← DOBRZE
```

### ❌ CSS hacking zamiast natywnego motywu
```css
/* ŹLE — walczy z BaseWeb inline styles, przegrywa */
[data-baseweb="checkbox"] > span:first-of-type {
    background-color: white !important;
    border: 2px solid black !important;
}

/* DOBRZE — użyj st._config.set_option() i pozwól Streamlit zająć się resztą */
```

---

## Windows .bat launcher — bezpieczny wzorzec

```bat
@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo [1/3] Szukam Pythona 3...
set "PYCMD="

py -3 --version >nul 2>&1
if not errorlevel 1 (
    set "PYCMD=py -3"
    goto :python_ok
)

python --version >nul 2>&1
if not errorlevel 1 (
    python -c "import sys; sys.exit(0 if sys.version_info >= (3,8) else 1)" >nul 2>&1
    if not errorlevel 1 (
        set "PYCMD=python"
        goto :python_ok
    )
)

echo BLAD: Python 3.8+ nie znaleziony!
echo Pobierz z: https://www.python.org/downloads/
pause
exit /b 1

:python_ok
echo [2/3] Sprawdzam pakiety...
%PYCMD% -c "import streamlit, plotly, pandas" >nul 2>&1
if errorlevel 1 (
    echo Instaluje pakiety...
    %PYCMD% -m pip install -r requirements.txt
    if errorlevel 1 (
        echo BLAD: pip install nie powiodl sie.
        pause
        exit /b 1
    )
)

echo [3/3] Uruchamiam...
%PYCMD% -m streamlit run app.py
pause
```

**Zasady:**
- `py -3` ZAWSZE pierwszy (omija stary Python 2.x z TRUMPF/CAD/CNC w PATH)
- Wersja sprawdzana przez `python -c "..."` NIE przez `for /f` (for/f + pipe = silent crash)
- Każdy `exit /b 1` MUSI mieć `pause` przed nim
- `setlocal enabledelayedexpansion` zawsze na początku
- **Bez polskich znaków w .bat** (ogonki psują się w CMD)

---

## Plotly — nadawanie kolorów motywu

```python
def apply_theme_to_plotly(fig):
    """Nakłada kolory aktualnego motywu na figurę Plotly."""
    t = get_current_theme()  # zwraca THEMES[session_state["theme"]]
    fig.update_layout(
        paper_bgcolor=t['bg'],
        plot_bgcolor=t['bg'],
        font=dict(color=t['text']),
        title_font_color=t['text'],
        legend_font_color=t['text'],
    )
    fig.update_xaxes(
        gridcolor=t['border'], linecolor=t['border'],
        tickfont=dict(color=t['text']), title_font=dict(color=t['text']),
    )
    fig.update_yaxes(
        gridcolor=t['border'], linecolor=t['border'],
        tickfont=dict(color=t['text']), title_font=dict(color=t['text']),
    )
    return fig

# Użycie:
fig = plot_something(...)
st.plotly_chart(apply_theme_to_plotly(fig), use_container_width=True)
```

---

## Checklist przy wdrażaniu motywów

- [ ] `apply_native_streamlit_theme()` wywoływana **przed** pierwszym widgetem w main()
- [ ] Guard `_applied_theme` zapobiega nieskończonej pętli rerun
- [ ] `inject_theme()` ma tylko custom elementy (NIE checkbox, radio, tooltip, popover)
- [ ] Brak selektorów `svg path { fill: ... }` — zaburza kształt ikon
- [ ] Brak selektorów `[data-baseweb="checkbox"] svg` — za szeroki, łapie pytajniki
- [ ] Jasne motywy mają białe tło (NIE kolorowe tła `#fef2f2`)
- [ ] `st.rerun()` jest POZA kontekstem `with st.popover()`
- [ ] Plotly figury owijane przez `apply_theme_to_plotly()` przed `st.plotly_chart()`
- [ ] uruchom.bat używa `py -3` → `python -c "..."` do wersji, `pause` przy błędach
