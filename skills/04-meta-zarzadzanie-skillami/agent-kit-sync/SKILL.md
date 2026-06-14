---
name: agent-kit-sync
description: Zarzadzanie repozytorium agent-kit — synchronizacja wszystkich skilli i kontraktu wspolpracy do Claude Code i Codex przez KOPIOWANIE (install.ps1), dodawanie nowych skilli, bootstrap na nowej maszynie. Uzyj gdy trzeba zsynchronizowac, dodac skill albo postawic agent-kit na nowym komputerze.
---

# agent-kit-sync

Repozytorium **agent-kit** to jedyne zrodlo prawdy dla skilli i zasad pracy
(Claude Code + Codex), przenosne miedzy maszynami przez GitHub:
**https://github.com/mikolajharnas/agent-kit**

Zasada: rozne maszyny, ale Claude Code + Codex + skille + zasady pracy zawsze te same.

## Architektura

- Zrodlo: `agent-kit/skills/<kategoria>/<skill>/SKILL.md`
  (kategorie 01..04 to tylko porzadek; do narzedzi skille trafiaja plasko)
- `agent-kit/instructions/collaboration.md` — kontrakt (zasady pracy)
- `agent-kit/install.ps1` — synchronizacja (w korzeniu repo)

`install.ps1` KOPIUJE (nie junctiony) kazdy folder zawierajacy SKILL.md (szuka
rekurencyjnie) do `~/.claude/skills` i `~/.codex/skills`, oraz wgrywa kontrakt do
`~/.claude/CLAUDE.md` i `~/.codex/AGENTS.md`. Kopie to prawdziwe foldery — dzialaja
zawsze, niezaleznie od lokalizacji repo czy nazwy uzytkownika. Nazwy folderow-skilli
musza byc unikalne (kategorie sa splaszczane).

## Operacje

### Synchronizacja / bootstrap (takze nowa maszyna, bez admina)

    & "$HOME\agent-kit\install.ps1"

Kopiuje wszystkie skille + kontrakt. Idempotentne. Usuwa stare junctiony (migracja)
oraz skille skasowane z repo (wg manifestu `.agent-kit-manifest.txt`).

### Dodanie nowego skilla

1. Utworz `agent-kit/skills/<kategoria>/<nazwa>/SKILL.md` (frontmatter name + description).
2. Odpal `install.ps1`.
3. `git add/commit/push` — backup + inne maszyny.

### Nowa maszyna (pelny bootstrap)

    winget install GitHub.cli --source winget   # jesli brak
    gh auth login                                # raz
    git clone https://github.com/mikolajharnas/agent-kit "$HOME\agent-kit"
    & "$HOME\agent-kit\install.ps1"

### Aktualizacja z GitHub

    git -C "$HOME\agent-kit" pull
    & "$HOME\agent-kit\install.ps1"

## Zasady

- Edytuj skille TYLKO w repo, potem odpal `install.ps1` (kopie nie sa live).
- Tu trafiaja tylko wlasne skille — nie systemowe (`.system`) ani z marketplace.
- Zadnych sekretow, tokenow, kluczy w repo.
- Po edycji kontraktu tez odpal `install.ps1` (nadpisuje globalne CLAUDE.md/AGENTS.md).
