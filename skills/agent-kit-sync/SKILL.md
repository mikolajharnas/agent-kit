---
name: agent-kit-sync
description: Zarzadzanie przenosnym repozytorium skilli agent-kit — podlaczanie skilli do Claude Code i Codex przez junctiony, dodawanie nowych skilli, odswiezanie i naprawa linkow, wgrywanie globalnego kontraktu wspolpracy. Uzyj gdy trzeba zsynchronizowac, dodac, naprawic skille albo zbootstrapowac agent-kit na nowym komputerze.
---

# agent-kit-sync

Skill do zarzadzania repozytorium `agent-kit` — przenosnym zestawem skilli i kontraktu
wspolpracy wspoldzielonym przez Claude Code i Codex.

## Architektura

- Prawdziwe pliki (jedyne zrodlo prawdy): `agent-kit\skills\<nazwa>\SKILL.md`
- Junctiony (strzalki do prawdziwych plikow) tworzone w:
  - `~\.claude\skills\<nazwa>`  — Claude Code
  - `~\.codex\skills\<nazwa>`   — Codex
- Kontrakt globalny: `agent-kit\instructions\collaboration.md` kopiowany do:
  - `~\.claude\CLAUDE.md`
  - `~\.codex\AGENTS.md`

Junction = jeden plik, kilka widokow. **Edytuj zawsze w repo, nigdy przez junction.**
Junctiony NIE przenosza sie miedzy komputerami — odtwarza je install.ps1 lokalnie.

## Operacje

### Pelna synchronizacja / bootstrap (takze swiezy komputer, bez admina)

    & "<repo>\skills\agent-kit-sync\scripts\install.ps1"

Tworzy junctiony dla wszystkich skilli + wgrywa kontrakt globalny. Idempotentne —
mozna odpalac wielokrotnie.

### Dodanie nowego skilla

1. Utworz `agent-kit\skills\<nowa-nazwa>\SKILL.md` z frontmatterem `name` + `description`.
2. Odpal install.ps1 (zlinkuje rowniez nowy) albo zrob pojedyncze junctiony:

       New-Item -ItemType Junction -Path "$HOME\.claude\skills\<nazwa>" -Target "<repo>\skills\<nazwa>"
       New-Item -ItemType Junction -Path "$HOME\.codex\skills\<nazwa>"  -Target "<repo>\skills\<nazwa>"

### Naprawa zepsutych junctionow

Martwe strzalki (np. po przeniesieniu repo) — po prostu odpal install.ps1 ponownie.
Usuwa stare linki (`rmdir`, NIE tyka zawartosci repo) i tworzy nowe.

### Weryfikacja

    Get-ChildItem "$HOME\.claude\skills" | Where-Object LinkType -eq 'Junction'
    Get-ChildItem "$HOME\.codex\skills"  | Where-Object LinkType -eq 'Junction'

Sprawdz, ze cele wskazuja na `agent-kit`.

## Format SKILL.md (wspolny dla Claude i Codex)

    ---
    name: <kebab-case>
    description: <kiedy uzyc — konkretne wyzwalacze, slowa kluczowe>
    ---
    # Tytul
    <tresc skilla>

## Twarde zasady

- Edytuj pliki TYLKO w repo, nie przez junction.
- Do agent-kit trafiaja TYLKO wlasne skille — nie systemowe (`.system`) ani z pluginow/marketplace.
- Zadnych sekretow, tokenow, kluczy w repo.
- install.ps1 NADPISUJE globalne `~\.claude\CLAUDE.md` i `~\.codex\AGENTS.md` — przed pierwszym
  uruchomieniem sprawdz, czy nie masz tam wczesniej recznie dodanych instrukcji.
