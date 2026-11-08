# TeamSpeak Heerlen 3D Cafe v0.8 — CI model downloader.
# Downloads ORIGINAL Polygonal Mind / 100Avatars R1 models only (001-100).
# Official source: https://github.com/PolygonalMind/100Avatars
# Same creator/series as https://poly.pizza/bundle/100-Avatars-R1-amJ23JjkKG
# CC0: https://creativecommons.org/publicdomain/zero/1.0/
# TeamSpeak voice / microphone / PTT is not accessed by this script.
[CmdletBinding()]
param([switch]$ForceDownload)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$modelsDir = Join-Path $root 'assets\avatars\100-r1'
$catalogPath = Join-Path $root 'scripts\r1_avatar_catalog.gd'
$baseApi = 'https://api.github.com/repos/PolygonalMind/100Avatars/git/trees/master?recursive=1'
$rawBase = 'https://raw.githubusercontent.com/PolygonalMind/100Avatars/master/'

function Find-ModelFiles {
    if (-not (Test-Path -LiteralPath $modelsDir)) { return @() }
    return @(Get-ChildItem -LiteralPath $modelsDir -Recurse -File | Where-Object {
        $_.Extension.ToLowerInvariant() -in @('.glb', '.gltf', '.fbx')
    } | Sort-Object FullName)
}

$alreadyHere = @(Find-ModelFiles)
if ($ForceDownload -or $alreadyHere.Count -eq 0) {
    Write-Host 'TEAMSpeak HEERLEN: modellen downloaden bij officiele bron Polygonal Mind (CC0)...'
    $headers = @{ 'User-Agent' = 'TS-Heerlen-3D-Cafe-R1-Build'; 'Accept' = 'application/vnd.github+json' }
    if ($env:GH_TOKEN) { $headers['Authorization'] = 'Bearer ' + $env:GH_TOKEN }
    $tree = Invoke-RestMethod -Uri $baseApi -Headers $headers -TimeoutSec 180
    if ($tree.truncated) { throw 'Bronlijst onvolledig (GitHub tree truncated). Build gestopt.' }

    $files = @($tree.tree | Where-Object {
        $_.type -eq 'blob' -and $_.path -match '^100Avatars_(\d{3})/100Avatars_\d{3}_[^/]+\.(fbx|png)$' -and
        [int]([regex]::Match($_.path, '^100Avatars_(\d{3})/').Groups[1].Value) -ge 1 -and
        [int]([regex]::Match($_.path, '^100Avatars_(\d{3})/').Groups[1].Value) -le 100
    } | Sort-Object path)
    $fbxs = @($files | Where-Object { $_.path -like '*.fbx' })
    $pngs = @($files | Where-Object { $_.path -like '*.png' })
    $indices = @($fbxs | ForEach-Object { [regex]::Match($_.path,'^100Avatars_(\d{3})/').Groups[1].Value } | Select-Object -Unique)
    if ($indices.Count -ne 100 -or $pngs.Count -lt 100) {
        throw "Bron bevat $($indices.Count) unieke R1 FBX-avatars en $($pngs.Count) texturen (100 verwacht)."
    }
    New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null
    $number = 0
    foreach ($entry in $files) {
        $number++
        $destination = Join-Path $modelsDir ($entry.path.Replace('/','\'))
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        if (-not (Test-Path -LiteralPath $destination) -or (Get-Item $destination).Length -eq 0) {
            $url = $rawBase + $entry.path
            $success = $false
            for ($retry=1; $retry -le 4; $retry++) {
                try {
                    Invoke-WebRequest -Uri $url -OutFile $destination -TimeoutSec 180
                    if ((Get-Item -LiteralPath $destination).Length -lt 500) {
                        throw "Leeg model/texture: $url"
                    }
                    $success = $true
                    break
                }
                catch {
                    if ($retry -eq 4) { throw "Bronbestand ophalen mislukt na 4 pogingen: $url — $_" }
                    Start-Sleep -Seconds (3 * $retry)
                }
            }
        }
        if (($number % 25) -eq 0 -or $number -eq $files.Count) {
            Write-Host "R1 bronbestanden: $number van $($files.Count)"
        }
    }
}

# One selectable character for each of the 100 R1 numbers. Some numbers have
# multiple FBX components (notably 091), so copy both but select the first.
$all = @(Find-ModelFiles)
if ($all.Count -lt 70) {
    throw "Slechts $($all.Count) modelbestanden. Verwacht volledige Poly Pizza-bundel (73) of Polygonal Mind R1 (100)."
}
$preferred = @($all | Sort-Object @{ Expression={ if ($_.Extension -eq '.glb') {0} elseif ($_.Extension -eq '.gltf'){1} else {2} } },FullName)
$groups = @{}
foreach ($model in $preferred) {
    $relative = $model.FullName.Substring($modelsDir.Length).TrimStart('\','/').Replace('\','/')
    $name = ($relative -split '/')[0]
    if ($name -match '^100Avatars_(\d{3})$') { $key = $Matches[1] }
    else { $key = $model.BaseName.ToLowerInvariant() }
    if (-not $groups.ContainsKey($key)) { $groups[$key] = $model.FullName }
}
$selected = @($groups.GetEnumerator() | Sort-Object Name | ForEach-Object { $_.Value })
if ($selected.Count -lt 70) { throw "Te weinig unieke R1-avatars: $($selected.Count)" }
$lines = [System.Collections.Generic.List[string]]::new()
[void]$lines.Add('extends RefCounted')
[void]$lines.Add('## Automatisch gegenereerd: alleen Polygonal Mind 100Avatars R1 / Poly Pizza R1 (CC0).')
[void]$lines.Add('const AVATARS: Array[String] = [')
foreach ($path in $selected) {
    $rel = $path.Substring($root.Length).TrimStart('\','/').Replace('\','/')
    if ($rel.Contains('"')) { throw "Ongeldige naam in catalogus: $rel" }
    [void]$lines.Add('    "res://' + $rel + '",')
}
[void]$lines.Add(']')
[IO.File]::WriteAllLines($catalogPath, $lines, [Text.UTF8Encoding]::new($false))
Write-Host "POLYGONAL MIND R1 GEREED: $($selected.Count) selecteerbare avatars."
Write-Host "Catalogus: $catalogPath"
