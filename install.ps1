# install.ps1 - synchronizacja agent-kit na tej maszynie (Windows, BEZ admina).
#
# KOPIUJE wszystkie skille (foldery zawierajace SKILL.md, szukane rekurencyjnie
# pod skills\) do folderow skilli Claude Code i Codex, oraz wgrywa kontrakt
# wspolpracy jako globalne instrukcje obu narzedzi.
#
# Kopiowanie (nie junctiony): prawdziwe foldery, dzialaja zawsze, niezaleznie od
# lokalizacji repo. Skrypt jest idempotentny.
#
# Uzycie:  & "$HOME\agent-kit\install.ps1"

$ErrorActionPreference = 'Stop'

$RepoRoot  = $PSScriptRoot
$SkillsSrc = Join-Path $RepoRoot 'skills'
$Contract  = Join-Path $RepoRoot 'instructions\collaboration.md'

$Targets = @(
    (Join-Path $HOME '.claude\skills'),
    (Join-Path $HOME '.codex\skills')
)
$ManifestName = '.agent-kit-manifest.txt'

Write-Host "agent-kit sync"
Write-Host "  repo: $RepoRoot"
Write-Host ""

# --- Znajdz wszystkie skille (foldery zawierajace SKILL.md, rekurencyjnie) ---
$skillDirs = @(Get-ChildItem -Recurse -Directory $SkillsSrc | Where-Object {
    Test-Path (Join-Path $_.FullName 'SKILL.md')
})

if ($skillDirs.Count -eq 0) { throw "Nie znaleziono zadnych skilli pod $SkillsSrc" }

# wykryj kolizje nazw (nazwa folderu-skilla musi byc unikalna - kategorie sa splaszczane)
$dupes = $skillDirs | Group-Object Name | Where-Object { $_.Count -gt 1 }
if ($dupes) {
    Write-Warning "Kolizja nazw skilli - napraw przed synchronizacja:"
    foreach ($d in $dupes) {
        Write-Warning ("  '" + $d.Name + "' wystepuje " + $d.Count + " razy:")
        $d.Group | ForEach-Object { Write-Warning ("    " + $_.FullName) }
    }
    throw "Przerwano: zduplikowane nazwy skilli."
}

$skillNames = @($skillDirs | ForEach-Object { $_.Name })
Write-Host ("Skille (" + $skillDirs.Count + "):")
$skillNames | ForEach-Object { Write-Host ("  - " + $_) }
Write-Host ""

# --- Dla kazdego celu: posprzataj i skopiuj ---
foreach ($root in $Targets) {
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    Write-Host ("-> " + $root)

    # 1. Migracja: usun wszystkie junctiony (z poprzedniego setupu opartego na junctionach)
    Get-ChildItem $root -Force -Directory -ErrorAction SilentlyContinue | Where-Object {
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    } | ForEach-Object {
        cmd /c rmdir "$($_.FullName)" | Out-Null
        Write-Host ("   (usunieto stary junction) " + $_.Name)
    }

    # 2. Usun zarzadzane kopie z poprzedniej synchronizacji, ktorych juz nie ma w repo
    $manifestPath = Join-Path $root $ManifestName
    if (Test-Path $manifestPath) {
        $old = @(Get-Content $manifestPath | Where-Object { $_ -ne '' })
        foreach ($name in $old) {
            if ($skillNames -notcontains $name) {
                $stale = Join-Path $root $name
                if (Test-Path $stale) {
                    Remove-Item -Recurse -Force $stale
                    Write-Host ("   (usunieto nieaktualny) " + $name)
                }
            }
        }
    }

    # 3. Skopiuj aktualne skille (nadpisz istniejace)
    foreach ($sd in $skillDirs) {
        $dest = Join-Path $root $sd.Name
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        Copy-Item $sd.FullName -Destination $dest -Recurse -Force
        Write-Host ("   + " + $sd.Name)
    }

    # 4. Zapisz manifest zarzadzanych skilli
    Set-Content -Path $manifestPath -Value $skillNames -Encoding ASCII
}
Write-Host ""

# --- Wgraj kontrakt globalny ---
if (Test-Path $Contract) {
    Write-Host "Kontrakt globalny:"
    Copy-Item $Contract (Join-Path $HOME '.claude\CLAUDE.md') -Force
    Copy-Item $Contract (Join-Path $HOME '.codex\AGENTS.md')  -Force
    Write-Host "   + ~\.claude\CLAUDE.md"
    Write-Host "   + ~\.codex\AGENTS.md"
} else {
    Write-Warning ("Brak kontraktu: " + $Contract)
}

Write-Host ""
Write-Host "Gotowe."
