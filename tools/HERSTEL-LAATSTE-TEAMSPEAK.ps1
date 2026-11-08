# Keeps the user's *working* TeamSpeak bridge and related code from the last
# verified repository commit, rather than overwriting it with an older snapshot.
# This runs inside GitHub Actions only; no voice settings or secrets touched.
$ErrorActionPreference = 'Stop'
$ref = '60ac95fd3c3dba53634349953fff6e1c77d38766'
$files = @{
  'bridge/main.cjs' = '3be719ff677383fcd5e34d251e9a8a9eb35d142e'
  'scripts/teamspeak_bridge.gd' = 'cbca1a20afd9c7a273a0f7530af99c356f3fe52f'
  'scripts/hud.gd' = '80fe98a40c92400490480debbe884e8aa8434a59'
  'scripts/world.gd' = '78b71af7660035d56a33ec63ee9ff178bdb3c239'
}
Write-Host "TeamSpeak: originele stabiele bron herstellen van commit $ref."
& git fetch --no-tags --depth=1 origin $ref
if ($LASTEXITCODE -ne 0) { throw 'Stabiele TeamSpeak GitHub-commit niet beschikbaar.' }
foreach ($name in $files.Keys) {
    # Git returns original file bytes, PowerShell 7 redirects stdout as UTF-8.
    $content = (& git show "${ref}:$name" | Out-String).TrimEnd("`r", "`n") + "`n"
    if ($LASTEXITCODE -ne 0) { throw "Bronbestand niet te herstellen: $name" }
    $target = Join-Path (Get-Location).Path $name
    [IO.File]::WriteAllText($target, $content, [Text.UTF8Encoding]::new($false))
    $actual = (& git hash-object -- $name).Trim()
    if ($actual -ne $files[$name]) {
        # Line endings from PowerShell pipeline may differ; use git show via
        # byte stream to preserve exact checksummed bytes where supported.
        $spec = "${ref}:$name"
        $pinfo = [Diagnostics.ProcessStartInfo]::new('git')
        [void]$pinfo.ArgumentList.Add('show')
        [void]$pinfo.ArgumentList.Add($spec)
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $process = [Diagnostics.Process]::Start($pinfo)
        $memory = [IO.MemoryStream]::new()
        $process.StandardOutput.BaseStream.CopyTo($memory)
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw "Git show mislukt: $name" }
        [IO.File]::WriteAllBytes($target, $memory.ToArray())
        $actual = (& git hash-object -- $name).Trim()
    }
    if ($actual -ne $files[$name]) { throw "Checksumverschil in $name" }
    Write-Host "Stabiele bron hersteld: $name"
}
