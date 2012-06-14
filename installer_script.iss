; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{F0C2E064-9008-41B2-897B-CC078F8E773F}
AppName=YCweather
AppVersion=1.0
;AppVerName=YCweather 1.0
AppPublisher=Andrew E Slaughter
AppPublisherURL=http://aeslaughter.github.com/YCweather/
AppSupportURL=http://aeslaughter.github.com/YCweather/
AppUpdatesURL=http://aeslaughter.github.com/YCweather/
DefaultDirName={pf}\YCweather
DefaultGroupName=YCweather
AllowNoIcons=yes
LicenseFile=C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\license.txt
OutputBaseFilename=setup
OutputDir=C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\YCweather.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\help.pdf"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\license.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\mesowest.mwu"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\version.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\winscp.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Users\slaughter\Documents\MSUResearch\MATLABcode\YCweather_v4\release\YCmain.exe"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\YCweather"; Filename: "{app}\YCweather.exe"
Name: "{group}\{cm:UninstallProgram,YCweather}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\YCweather"; Filename: "{app}\YCweather.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\YCweather.exe"; Description: "{cm:LaunchProgram,YCweather}"; Flags: nowait postinstall skipifsilent

