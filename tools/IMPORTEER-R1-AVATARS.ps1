param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PackPath
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# TeamSpeak Heerlen: importeer uitsluitend de originele Poly Pizza 100 Avatars R1 GLTF-bundel.
# Deze offline importer downloadt GEEN andere avatarbronnen en verandert GEEN voice-code.
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$assetRoot = Join-Path $projectRoot 'assets\avatars\100-r1'
$catalog = Join-Path $projectRoot 'scripts\r1_avatar_catalog.gd'
$source = (Resolve-Path -LiteralPath $PackPath -ErrorAction Stop).Path
$temp = Join-Path ([IO.Path]::GetTempPath()) ('TS-Heerlen-100-R1-' + [guid]::NewGuid().ToString('N'))

function Expand-Package([string]$file, [string]$dest) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Expand-Archive -LiteralPath $file -DestinationPath $dest -Force
}

try {
    New-Item -ItemType Directory -Path $temp -Force | Out-Null
    if (Test-Path -LiteralPath $source -PathType Container) {
        Copy-Item -Path (Join-Path $source '*') -Destination $temp -Recurse -Force
    }
    elseif ([IO.Path]::GetExtension($source).ToLowerInvariant() -eq '.zip') {
        Expand-Package $source $temp
    }
    else {
        throw 'Geef de gedownloade GLTF ZIP of de uitgepakte map van Poly Pizza op.'
    }

    # Sommige downloads leveren ZIP-bestanden in een ZIP. Maximaal twee niveaus.
    for ($level = 0; $level -lt 2; $level++) {
        $nested = @(Get-ChildItem -LiteralPath $temp -Recurse -File -Filter '*.zip')
        if ($nested.Count -eq 0) { break }
        foreach ($z in $nested) {
            $folder = $z.FullName + '.unpacked'
            Expand-Package $z.FullName $folder
            Remove-Item -LiteralPath $z.FullName -Force
        }
    }

    $models = @(Get-ChildItem -LiteralPath $temp -Recurse -File | Where-Object {
        $_.Extension.ToLowerInvariant() -in @('.glb', '.gltf')
    })
    if ($models.Count -eq 0) {
        throw 'Geen .glb of .gltf-bestanden gevonden. Download bij Poly Pizza: Download GLTF (niet FBX).'
    }

    # Oude 100-R1 bestanden vervangen zonder andere projectbestanden aan te raken.
    if (Test-Path -LiteralPath $assetRoot) {
        Remove-Item -LiteralPath $assetRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $assetRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $temp '*') -Destination $assetRoot -Recurse -Force

    $allModels = @(Get-ChildItem -LiteralPath $assetRoot -Recurse -File | Where-Object {
        $_.Extension.ToLowerInvariant() -in @('.glb', '.gltf')
    } | Sort-Object FullName)

    # Dubbele exports van precies hetzelfde model in dezelfde folder: geef .glb voorrang.
    $seen = @{}
    $selected = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
    foreach ($model in ($allModels | Sort-Object @{Expression={if($_.Extension -eq '.glb'){0}else{1}}},FullName)) {
        $key = ($model.DirectoryName + '|' + $model.BaseName).ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        [void]$selected.Add($model)
    }
    $selected = @($selected | Sort-Object FullName)

    $lines = New-Object 'System.Collections.Generic.List[string]'
    [void]$lines.Add('extends RefCounted')
    [void]$lines.Add('## AUTOMATISCH GEGENEREERD: uitsluitend Polygonal Mind / Poly Pizza 100 Avatars R1.')
    [void]$lines.Add('## Alle gevonden GLB/GLTF-modellen zijn beschikbaar als selectie.')
    [void]$lines.Add('const AVATARS: Array[String] = [')
    foreach ($model in $selected) {
        $relative = $model.FullName.Substring($projectRoot.Length).TrimStart('\','/').Replace('\','/')
        if ($relative.Contains('"')) {
            throw "Ongeldige bestandsnaam voor Godot catalogus: $relative"
        }
        [void]$lines.Add(('    "res://' + $relative + '",'))
    }
    [void]$lines.Add(']')
    [IO.File]::WriteAllLines($catalog, $lines, [Text.UTF8Encoding]::new($false))

    Write-Host ''
    Write-Host '==============================================' -ForegroundColor Green
    Write-Host '  TEAMSpeak HEERLEN - 100 AVATARS R1 IMPORT' -ForegroundColor Green
    Write-Host '==============================================' -ForegroundColor Green
    Write-Host ('Gevonden modellen : ' + $selected.Count)
    Write-Host ('Modellen in       : ' + $assetRoot)
    Write-Host ('Catalogus         : ' + $catalog)
    if ($selected.Count -lt 73) {
        Write-Warning 'De Poly Pizza-pagina toont 73 modellen. Controleer of je de VOLLEDIGE GLTF-bundel hebt gedownload.'
    }
    Write-Host 'Upload de gewijzigde scripts EN de volledige assets/avatars/100-r1 map naar GitHub.' -ForegroundColor Yellow
    Write-Host ''
}
finally {
    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Recurse -Force
    }
}
