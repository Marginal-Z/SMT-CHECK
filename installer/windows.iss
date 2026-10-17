#ifndef AppVersion
#define AppVersion "1.14.0"
#endif
#ifndef AppArchitecture
  #define AppArchitecture "x64"
#endif
#ifndef PayloadDir
  #define PayloadDir "..\dist\SMT-CHECK-windows"
#endif

[Setup]
AppId={{C0CD984F-2F4E-4C4F-A7B7-8069C079542D}
AppName=SMT Fusion
AppVersion={#AppVersion}
AppPublisher=Marginal-Z
AppPublisherURL=https://github.com/Marginal-Z/SMT-CHECK
DefaultDirName={localappdata}\Programs\SMT-CHECK
DefaultGroupName=SMT Fusion
UsePreviousGroup=no
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=SMT-CHECK-Setup-{#AppArchitecture}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\smt-fusion-20261017.ico
#if AppArchitecture == "arm64"
ArchitecturesAllowed=arm64
ArchitecturesInstallIn64BitMode=arm64
#else
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
#endif
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
Source: "{#PayloadDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SMT Fusion"; Filename: "{app}\SMT-CHECK.exe"; WorkingDir: "{app}"; IconFilename: "{app}\smt-fusion-20261017.ico"; AppUserModelID: "MarginalZ.SMTFusion.Desktop"
Name: "{autodesktop}\SMT Fusion"; Filename: "{app}\SMT-CHECK.exe"; WorkingDir: "{app}"; IconFilename: "{app}\smt-fusion-20261017.ico"; AppUserModelID: "MarginalZ.SMTFusion.Desktop"; Check: ShouldCreateDesktopShortcut

[InstallDelete]
Type: files; Name: "{userprograms}\SMT-CHECK\SMT-CHECK.lnk"
Type: files; Name: "{autodesktop}\SMT-CHECK.lnk"

[Run]
Filename: "{app}\SMT-CHECK.exe"; Parameters: "--repair-icons"; Flags: runhidden waituntilterminated
Filename: "{app}\SMT-CHECK.exe"; Description: "Launch SMT Fusion"; Flags: nowait postinstall skipifsilent
Filename: "{app}\SMT-CHECK.exe"; Flags: nowait skipifnotsilent; Check: IsFusionUpdate

[Code]
function ShouldCreateDesktopShortcut: Boolean;
begin
  Result := WizardIsTaskSelected('desktopicon') or FileExists(ExpandConstant('{autodesktop}\SMT Fusion.lnk'));
end;

function IsFusionUpdate: Boolean;
begin
  Result := ExpandConstant('{param:SMTFUSIONUPDATE|0}') <> '0';
end;
