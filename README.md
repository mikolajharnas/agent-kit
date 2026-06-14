# agent-kit

Jedyne zrodlo prawdy dla **skilli** i **zasad pracy** (kontraktu wspolpracy)
dla Claude Code i Codex. Przenosne przez GitHub miedzy maszynami.

> Zasada: rozne maszyny, ale Claude Code + Codex + skille + zasady pracy zawsze te same.

## Struktura

```
agent-kit/
  install.ps1                 # synchronizacja na maszyne (kopiowanie)
  instructions/
    collaboration.md          # kontrakt = zasady pracy (role, delegowanie, twarde zasady)
  skills/
    01-domena-grzewcza-kolton/
    02-dokumenty-i-lokalizacja/
    03-srodowisko-windows-python/
    04-meta-zarzadzanie-skillami/
      agent-kit-sync/         # skill o zarzadzaniu tym repo
      ...
```

Kategorie `01..04` to tylko porzadek. Skill = dowolny folder z plikiem `SKILL.md`
(szukane rekurencyjnie). Nazwy folderow-skilli musza byc unikalne.

## Jak dziala (kopiowanie, nie junctiony)

`install.ps1` KOPIUJE skille do `~/.claude/skills` i `~/.codex/skills` jako prawdziwe
foldery, oraz wgrywa `instructions/collaboration.md` do `~/.claude/CLAUDE.md` i
`~/.codex/AGENTS.md`. Kopie dzialaja zawsze i nie zaleza od lokalizacji repo
(repo mozesz trzymac gdziekolwiek i przenosic).

Koszt: po edycji skilla/kontraktu odpal `install.ps1`, zeby skopiowac zmiane.
Edytuj zawsze w repo (kopie nie sa "live").

## Nowa maszyna (bootstrap)

```powershell
winget install GitHub.cli --source winget   # jesli brak gh
gh auth login                                # raz, logowanie
git clone https://github.com/mikolajharnas/agent-kit "$HOME\agent-kit"
& "$HOME\agent-kit\install.ps1"
```

Po tym maszyna ma te same skille i te same zasady dla Claude i Codex.

## Aktualizacja

```powershell
git -C "$HOME\agent-kit" pull
& "$HOME\agent-kit\install.ps1"
```

## Dodanie skilla

1. `skills/<kategoria>/<nazwa>/SKILL.md` (frontmatter `name` + `description`).
2. `install.ps1`.
3. `git add/commit/push`.

## Zasady

- Edytuj pliki TYLKO w repo.
- Tu trafiaja TYLKO wlasne skille — nie systemowe (`.system`) ani z marketplace.
- Zadnych sekretow, tokenow ani kluczy w repo.
- `install.ps1` NADPISUJE globalne `~/.claude/CLAUDE.md` i `~/.codex/AGENTS.md`.
