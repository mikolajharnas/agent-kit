# agent-kit

Przenosny zestaw **skilli** i **kontraktu wspolpracy** dla Claude Code i Codex.
Jeden folder = jedno zrodlo prawdy, dzialajace na wielu komputerach i we wszystkich projektach.

## Co to jest

- `skills/` — wlasne skille (format `SKILL.md` wspolny dla Claude Code i Codex).
- `instructions/collaboration.md` — globalny kontrakt: jak Claude i Codex wspolpracuja.
- `skills/agent-kit-sync/scripts/install.ps1` — bootstrap: podlacza skille i kontrakt na danym komputerze.

## Jak to dziala

Claude i Codex szukaja skilli w sztywnych miejscach (`~/.claude/skills`, `~/.codex/skills`).
`install.ps1` tworzy tam **junctiony** (zlacza katalogow) wskazujace na `agent-kit/skills/*`,
wiec edytujesz pliki w jednym miejscu (repo), a oba narzedzia widza je od razu.

Junctiony na Windows NIE wymagaja admina. Sa lokalne dla komputera — przenosisz FOLDER,
a junctiony odtwarzasz przez `install.ps1` na kazdej maszynie.

## Bootstrap na nowym komputerze

```powershell
git clone <adres-repo> "$HOME\agent-kit"
& "$HOME\agent-kit\skills\agent-kit-sync\scripts\install.ps1"
```

To wszystko — skille i globalny kontrakt sa podlaczone do Claude Code i Codex.

> Uwaga: `install.ps1` NADPISUJE globalne `~/.claude/CLAUDE.md` i `~/.codex/AGENTS.md`
> trescia z `instructions/collaboration.md`. Jesli masz tam wlasne instrukcje — najpierw je zgraj.

## Dodanie nowego skilla

1. `skills/<nazwa>/SKILL.md` z frontmatterem `name` + `description`.
2. Odpal `install.ps1` (zlinkuje rowniez nowy skill).

## Zasady

- Edytuj pliki TYLKO w repo, nie przez junction.
- Tu trafiaja TYLKO wlasne skille — nie systemowe (`.system`) ani z pluginow/marketplace.
- Zadnych sekretow, tokenow ani kluczy w repo.
