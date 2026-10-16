#ifndef AppVersion
  #define AppVersion "1.8.0"
#endif

[Setup]
AppId={{C0CD984F-2F4E-4C4F-A7B7-8069C079542D}
AppName=SMT-CHECK
AppVersion={#AppVersion}
AppPublisher=Marginal-Z
AppPublisherURL=https://github.com/Marginal-Z/SMT-CHECK
DefaultDirName={localappdata}\Programs\SMT-CHECK
DefaultGroupName=SMT-CHECK
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=SMT-CHECK-Setup-x64
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\SMT-CHECK.exe
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
WizardImageFile=wizard-large.bmp
WizardSmallImageFile=wizard-small.bmp
WizardImageBackColor=$FFFFFF
CloseApplications=yes
RestartApplications=no
VersionInfoVersion={#AppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimp"; MessagesFile: "ChineseSimplified.isl"
Name: "thai"; MessagesFile: "Thai.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Files]
Source: "..\dist\SMT-CHECK-windows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SMT-CHECK"; Filename: "{app}\SMT-CHECK.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\SMT-CHECK"; Filename: "{app}\SMT-CHECK.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\SMT-CHECK.exe"; Description: "Launch SMT-CHECK"; Flags: nowait postinstall skipifsilent
