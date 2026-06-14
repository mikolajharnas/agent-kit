---
name: skill-packager
description: >
  Użyj tego skilla ZAWSZE gdy pakujesz skill do pliku .skill gotowego do
  instalacji w Claude. Skill zapewnia poprawną strukturę paczki — SKILL.md
  bezpośrednio w korzeniu zipa, bez zagnieżdżonych folderów, bez duplikatów.
  Stosuj po każdym utworzeniu lub aktualizacji SKILL.md, zanim oddasz plik
  użytkownikowi.
---

# Skill Packager — poprawne pakowanie skillsów

## Dlaczego to ważne

Claude.ai wymaga przy instalacji `.skill`:
- `SKILL.md` musi być **bezpośrednio w korzeniu** paczki (nie w podfolderze)
- w paczce musi być **dokładnie jeden** plik `SKILL.md`

Typowe błędy przy naiwnym pakowaniu:

| Błąd | Przyczyna |
|---|---|
| `SKILL.md must be in the top-level folder` | zipowano cały folder zamiast wchodzić do środka |
| `Zip must contain exactly one SKILL.md` | zip już istniał i dopisał drugi plik zamiast nadpisać |

---

## Procedura pakowania — zawsze ta sama sekwencja

```bash
# 1. Usuń stary plik jeśli istnieje (unika duplikatu SKILL.md)
rm -f /mnt/user-data/outputs/NAZWA_SKILLA.skill

# 2. Wejdź DO folderu ze skillem (kluczowe — zip będzie relatywny)
cd /home/claude/NAZWA_SKILLA

# 3. Zipuj tylko SKILL.md (i opcjonalne zasoby) z tego poziomu
zip /mnt/user-data/outputs/NAZWA_SKILLA.skill SKILL.md

# 4. Weryfikacja — sprawdź że jest dokładnie jeden plik i bez ścieżki
unzip -l /mnt/user-data/outputs/NAZWA_SKILLA.skill
```

Wynik `unzip -l` powinien wyglądać tak:
```
Archive:  nazwa.skill
  Length    Date    Time    Name
--------  ------  ------  ----
    2976  ...     ...     SKILL.md   ← bez żadnego prefiksu ścieżki!
--------                  -------
    2976                  1 file
```

---

## Jeśli skill ma dodatkowe pliki (references, scripts, assets)

```bash
cd /home/claude/NAZWA_SKILLA
rm -f /mnt/user-data/outputs/NAZWA_SKILLA.skill
zip -r /mnt/user-data/outputs/NAZWA_SKILLA.skill SKILL.md references/ scripts/ assets/
unzip -l /mnt/user-data/outputs/NAZWA_SKILLA.skill
```

Dodatkowe podfoldery są dozwolone — niedozwolone jest tylko żeby `SKILL.md`
był w podfolderze.

---

## Aktualizacja istniejącego skilla

Jeśli skill już był zainstalowany i użytkownik chce go zaktualizować:
1. Edytuj `SKILL.md` w `/home/claude/NAZWA_SKILLA/`
2. Użyj tej samej procedury — `rm` starego `.skill` i `zip` od nowa
3. Użytkownik wgrywa nowy plik — Claude.ai nadpisze stary skill
