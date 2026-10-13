[Setup]
AppName=BillFlow
AppVersion=1.0.0
DefaultDirName={autopf}\BillFlow
DefaultGroupName=BillFlow
OutputDir=Output
OutputBaseFilename=BillFlowSetup
Compression=lzma
SolidCompression=yes
SetupIconFile=windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequiredOverridesAllowed=dialog

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\BillFlow"; Filename: "{app}\billflow.exe"
Name: "{autodesktop}\BillFlow"; Filename: "{app}\billflow.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\billflow.exe"; Description: "{cm:LaunchProgram,BillFlow}"; Flags: nowait postinstall skipifsilent

[Code]
// Declare SHChangeNotify from shell32.dll to refresh Windows Explorer icon cache
procedure SHChangeNotify(wEventId: Integer; uFlags: Cardinal; dwItem1: Integer; dwItem2: Integer);
  external 'SHChangeNotify@shell32.dll stdcall';

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssDone then
  begin
    // SHCNE_ASSOCCHANGED = $08000000, SHCNF_IDLIST = $1000
    SHChangeNotify($08000000, $1000, 0, 0);
  end;
end;
