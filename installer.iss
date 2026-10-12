[Setup]
AppName=BillFlow
AppVersion=1.0.0
DefaultDirName={pf}\BillFlow
DefaultGroupName=BillFlow
OutputDir=Output
OutputBaseFilename=BillFlowSetup
Compression=lzma
SolidCompression=yes

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\BillFlow"; Filename: "{app}\billflow.exe"
Name: "{commondesktop}\BillFlow"; Filename: "{app}\billflow.exe"
