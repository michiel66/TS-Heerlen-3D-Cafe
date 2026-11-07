; TeamSpeak Heerlen 3D Cafe — echte Windows-installer
; Godot 4.7.2 wordt tijdens GitHub Actions export meegebouwd.
; Bezoekers hebben Godot NIET nodig.
#define MyAppName "TeamSpeak Heerlen 3D Cafe"
#define MyAppVersion "0.7.0"
#define MyAppExeName "TS-Heerlen-3D-Cafe.exe"

[Setup]
AppId=TSHeerlen3DCafe
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=TeamSpeak Heerlen Community
AppPublisherURL=https://github.com/michiel66/TS-Heerlen-3D-Cafe
AppSupportURL=https://github.com/michiel66/TS-Heerlen-3D-Cafe/issues
DefaultDirName={localappdata}\Programs\TeamSpeak Heerlen 3D Cafe
DefaultGroupName=TeamSpeak Heerlen 3D Cafe
DisableProgramGroupPage=yes
OutputDir=dist\installer
OutputBaseFilename=TS-Heerlen-3D-Cafe-Setup-v0.7
SetupIconFile=assets\installer.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
MinVersion=10.0
SetupLogging=yes

[Languages]
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Maak een bureaubladsnelkoppeling"; GroupDescription: "Extra opties:"; Flags: unchecked

[Files]
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Export preset bevat binary_format/embed_pck=true. Eventuele losse PCK wordt ook meegenomen.
Source: "dist\*.pck"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; Zelfstandige lokale TS3 bridge met Node runtime en Opus-codec.
; Geen installatie van Node, Godot of TeamSpeak-plugin nodig op de doelcomputer.
Source: "dist\bridge-runtime\*"; DestDir: "{app}\voice-bridge"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\TeamSpeak Heerlen 3D Cafe"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\TeamSpeak Heerlen 3D Cafe"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Start TeamSpeak Heerlen 3D Cafe"; Flags: nowait postinstall skipifsilent
