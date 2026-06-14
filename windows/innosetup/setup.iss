#define MyAppName "Creche"
#define MyAppVersion GetEnv("APP_VERSION")
#define MyAppPublisher "Connacri"
#define MyAppURL "https://github.com/Connacri/CRECHE"
#define MyAppExeName "creche.exe"

[Setup]
AppId={{D3D3D3D3-D3D3-D3D3-D3D3-D3D3D3D3D3D3}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

DefaultDirName={autopf64}\{#MyAppName}

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

DisableProgramGroupPage=yes

OutputDir=build\windows\installer
OutputBaseFilename=creche-windows-installer

Compression=lzma2
SolidCompression=yes
WizardStyle=modern

UninstallDisplayIcon={app}\{#MyAppExeName}

SetupIconFile=windows\runner\resources\app_icon.ico

PrivilegesRequired=admin

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le bureau"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; \
    DestDir: "{app}"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"

Name: "{autodesktop}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; \
    Description: "Lancer {#MyAppName}"; \
    Flags: nowait postinstall skipifsilent