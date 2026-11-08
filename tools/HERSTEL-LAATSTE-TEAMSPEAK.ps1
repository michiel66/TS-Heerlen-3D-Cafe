
# ============================================================
# TEAM SPEAK HEERLEN 3D CAFE v0.8.1
# HERSTEL LAATSTE WERKENDE TEAMSPEAK AUDIO
# ============================================================
#
# Herstelt UITSLUITEND:
#   bridge/main.cjs
#   scripts/teamspeak_bridge.gd
#
# VERANDERT NIET:
#   scripts/hud.gd
#   scripts/main.gd
#   scripts/avatar.gd
#   scripts/world.gd
#   scripts/online_avatars.gd
#
# Hierdoor blijven de profielinstellingen, avatarkiezer,
# café-inrichting en F7-avatarselectie intact.
#
# ============================================================

$ErrorActionPreference = 'Stop'

# Laatste stabiele TeamSpeak-bronversie
$ref = '60ac95fd3c3dba53634349953fff6e1c77d38766'

# Alleen originele TeamSpeak-audiobestanden herstellen.
# De SHA-waarden controleren of de bestanden exact kloppen.

$files = [ordered]@{
    'bridge/main.cjs' = '3be719ff677383fcd5e34d251e9a8a9eb35d142e'
    'scripts/teamspeak_bridge.gd' = 'cbca1a20afd9c7a273a0f7530af99c356f3fe52f'
}

Write-Host ""
Write-Host "=========================================="
Write-Host " TEAM SPEAK HEERLEN 3D CAFE v0.8.1"
Write-Host " AUDIO HERSTEL ZONDER PROFIELWIJZIGINGEN"
Write-Host "=========================================="
Write-Host ""

# Bepaal de hoofdmap van het project.
$projectRoot = [IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..')
)

Push-Location $projectRoot

try {

    # Controleer of Git beschikbaar is.
    & git --version

    if ($LASTEXITCODE -ne 0) {
        throw 'Git is niet beschikbaar.'
    }

    # Haal de stabiele bron op.
    Write-Host "Stabiele TeamSpeak-bron ophalen..."

    & git fetch --no-tags --depth=1 origin $ref

    if ($LASTEXITCODE -ne 0) {
        throw 'Stabiele TeamSpeak-commit niet beschikbaar.'
    }

    # Herstel alleen de twee audiobestanden.
    foreach ($name in $files.Keys) {

        Write-Host ""
        Write-Host "Herstellen: $name"

        $spec = "${ref}:$name"

        # Gebruik een byte-stream zodat de oorspronkelijke
        # bestanden exact behouden blijven.
        $startInfo = [Diagnostics.ProcessStartInfo]::new('git')

        [void]$startInfo.ArgumentList.Add('show')
        [void]$startInfo.ArgumentList.Add($spec)

        $startInfo.RedirectStandardOutput = $true
        $startInfo.UseShellExecute = $false

        $process = [Diagnostics.Process]::Start($startInfo)

        if ($null -eq $process) {
            throw "Git-proces kan niet starten: $name"
        }

        $memory = [IO.MemoryStream]::new()

        try {
            $process.StandardOutput.BaseStream.CopyTo($memory)
            $process.WaitForExit()

            if ($process.ExitCode -ne 0) {
                throw "Bestand ophalen mislukt: $name"
            }

            $target = Join-Path $projectRoot $name
            $folder = Split-Path -Parent $target

            if (-not (Test-Path $folder)) {
                New-Item -ItemType Directory -Path $folder -Force |
                    Out-Null
            }

            [IO.File]::WriteAllBytes(
                $target,
                $memory.ToArray()
            )
        }
        finally {
            $memory.Dispose()
            $process.Dispose()
        }

        # Controleer de exacte Git SHA.
        $actual = (& git hash-object -- $name).Trim()

        if ($LASTEXITCODE -ne 0) {
            throw "SHA-controle mislukt voor $name"
        }

        if ($actual -ne $files[$name]) {
            throw "Checksumverschil in $name"
        }

        Write-Host "OK: $name"
    }

    Write-Host ""
    Write-Host "=========================================="
    Write-Host " TEAM SPEAK AUDIO HERSTELD"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "Profielmenu blijft behouden."
    Write-Host "Avatarselectie blijft behouden."
    Write-Host "100Avatars R1 blijft behouden."
    Write-Host "3D-café blijft behouden."
    Write-Host "Microfoon en PTT blijven ongewijzigd."
    Write-Host ""
}
finally {
    Pop-Location
}
