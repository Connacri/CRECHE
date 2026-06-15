#define MyAppName "Creche"
#ifndef MyAppVersion
  #define MyAppVersion GetEnv("APP_VERSION")
#endif
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppPublisher "Connacri"
#define MyAppURL "https://github.com/Connacri/CRECHE"
#define MyAppExeName "creche.exe"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-1234567890AB}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

DefaultDirName={autopf64}\{#MyAppName}

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

#ifndef MyOutputDir
  #define MyOutputDir "build\windows\installer"
#endif
OutputDir={#MyOutputDir}
OutputBaseFilename=creche-windows-installer

Compression=lzma2
SolidCompression=yes
WizardStyle=modern

UninstallDisplayIcon={app}\{#MyAppExeName}

#ifndef MyIconFile
  #define MyIconFile "windows\runner\resources\app_icon.ico"
#endif
SetupIconFile={#MyIconFile}

PrivilegesRequired=admin

[Files]
#ifndef MySourceDir
  #define MySourceDir "build\windows\x64\runner\Release"
#endif
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Flags: nowait postinstall skipifsilent
