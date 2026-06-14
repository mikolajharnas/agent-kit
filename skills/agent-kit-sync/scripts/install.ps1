# install.ps1 - bootstrap agent-kit na tym komputerze (Windows, BEZ admina).
#
# Dla kazdego skilla w agent-kit\skills\ tworzy junction (zlacze katalogu) w folderach
# skilli Claude Code i Codex, a nastepnie wgrywa kontrakt wspolpracy jako globalne
# instrukcje obu narzedzi.
#
# Junctiony NIE wymagaja uprawnien administratora (inaczej niz symlinki).
# Skrypt jest idempotentny - mozna go uruchamiac wielokrotnie.
#
# Uzycie:
#   & "C:\sciezka\do\agent-kit\skills\agent-kit-sync\scripts\install.ps1"

$ErrorActionPreference = 'Stop'

# --- Ustal sciezki -----------------------------------------------------------
# Skrypt lezy w: agent-kit\skills\agent-kit-sync\scripts\install.ps1
# Korzen repo  = trzy poziomy wyzej.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir '..\..\..')).Path

$SkillsSrc = Join-Path $RepoRoot 'skills'
$Contract  = Join-Path $RepoRoot 'instructions\collaboration.md'

$ClaudeSkills = Join-Path $HOME '.claude\skills'
$CodexSkills  = Join-Path $HOME '.codex\skills'

Write-Host "agent-kit bootstrap"
Write-Host "  repo: $RepoRoot"
Write-Host ""

# Upewnij sie, ze docelowe foldery skilli istnieja
New-Item -ItemType Directory -Force -Path $ClaudeSkills | Out-Null
New-Item -ItemType Directory -Force -Path $CodexSkills  | Out-Null

# --- Funkcja: zlinkuj jeden skill -------------------------------------------
function Link-Skill {
    param([string]$Name, [string]$Src, [string]$TargetRoot)

    $target = Join-Path $TargetRoot $Name

    if (Test-Path $target) {
        $item = Get-Item $target -Force
        $isReparse = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
        if ($isReparse) {
            # istniejacy junction - usun TYLKO link (rmdir nie tyka zawartosci celu)
            cmd /c rmdir "$target" | Out-Null
        } else {
            Write-Warning ("  POMIJAM '" + $target + "' - to prawdziwy folder, nie junction. Usun go recznie, jesli chcesz zlinkowac.")
            return
        }
    }

    New-Item -ItemType Junction -Path $target -Target $Src | Out-Null
    Write-Host "  + $target"
}

# --- Linkuj wszystkie skille ------------------------------------------------
Write-Host "Linkuje skille (Claude + Codex):"
Get-ChildItem -Path $SkillsSrc -Directory | ForEach-Object {
    Write-Host ("[" + $_.Name + "]")
    Link-Skill -Name $_.Name -Src $_.FullName -TargetRoot $ClaudeSkills
    Link-Skill -Name $_.Name -Src $_.FullName -TargetRoot $CodexSkills
}
Write-Host ""

# --- Wgraj kontrakt globalny ------------------------------------------------
if (Test-Path $Contract) {
    Write-Host "Wgrywam kontrakt globalny:"
    Copy-Item $Contract (Join-Path $HOME '.claude\CLAUDE.md') -Force
    Copy-Item $Contract (Join-Path $HOME '.codex\AGENTS.md')  -Force
    Write-Host "  + ~\.claude\CLAUDE.md"
    Write-Host "  + ~\.codex\AGENTS.md"
} else {
    Write-Warning ("Brak pliku kontraktu: " + $Contract)
}

Write-Host ""
Write-Host "Gotowe."
