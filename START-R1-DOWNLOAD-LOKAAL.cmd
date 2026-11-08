@echo off
setlocal
chcp 65001 >nul
title TeamSpeak Heerlen - Haal alle 100 originele R1 avatars op
cd /d "%~dp0"
echo.
echo TEAMSpeak HEERLEN - ALLE R1 AVATARS
 echo Bronnen: Polygonal Mind 100Avatars R1 (CC0).
echo De download wordt alleen lokaal uitgevoerd; broncode en TeamSpeak blijven intact.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools\HAAL-R1-AVATARS-AUTOMATISCH.ps1"
if errorlevel 1 (
 echo.
 echo DOWNLOAD MISLUKT. Lees de foutmelding hierboven.
 pause
 exit /b 1
)
echo.
echo KLAAR: de avatar-modellen staan in assets\avatars\100-r1
pause
