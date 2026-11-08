@echo off
setlocal
chcp 65001 >nul
title TeamSpeak Heerlen - Poly Pizza 100 Avatars R1
set "SCRIPTPATH=%~dp0IMPORTEER-R1-AVATARS.ps1"
if "%~1"=="" (
  echo Sleep het gedownloade GLTF ZIP-bestand op dit .cmd-bestand.
  echo Of voer uit: START-IMPORT-R1.cmd "C:\Downloads\100-Avatars-R1.zip"
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTPATH%" -PackPath "%~1"
if errorlevel 1 (
  echo Import mislukt. Controleer of je de GLTF-download hebt gekozen.
  pause
  exit /b 1
)
echo Import afgerond. Kopieer nu de volledige gewijzigde projectmap naar GitHub.
pause
