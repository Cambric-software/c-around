; C Around - Windows installer.
;
; Installs into a versioned layout so the app can update itself later without
; ever overwriting files that Windows has open:
;
;   %LOCALAPPDATA%\Programs\CAround\
;     current.txt                  -> "1.0.0"
;     versions\1.0.0\c_around.exe, flutter_windows.dll, data\
;
; The shortcut deliberately points at the version this installer shipped, not
; at "whatever is newest". When an update lands, that older copy starts first,
; notices current.txt names a newer version, hands over and exits. That is the
; mechanism that keeps a stale shortcut from trapping the user on an old build.
;
; Per-user install (PrivilegesRequired=lowest) so updating never needs admin.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef AppExeName
  #define AppExeName "c_around.exe"
#endif

#define AppPublisher "Cambric Software"
#define AppName "C Around"
; A plain AppId is enough for upgrade detection and avoids escaped-brace GUID
; syntax, which is easy to get subtly wrong.
#define AppId "CambricCAround"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
; Must be strictly numeric. The release workflow normalises the tag
; (v1.0.1-beta1 -> 1.0.1) before passing /DAppVersion, because Inno
; rejects a pre-release suffix here and dpkg rejects one in a version too.
VersionInfoVersion={#AppVersion}.0
DefaultDirName={localappdata}\Programs\CAround
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableDirPage=no
OutputDir=..\release-out
OutputBaseFilename=CAround-Setup-{#AppVersion}
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\versions\{#AppVersion}\{#AppExeName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Per-user: no elevation prompt, and the app can write its own install
; directory when staging an update.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
UninstallDisplayName={#AppName} {#AppVersion}
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
; The Start Menu entry is created unconditionally; the desktop shortcut is
; optional, because plenty of users do not want one.
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
; The payload is staged by CI as ..\staging, already shaped as the version dir.
Source: "..\staging\*"; DestDir: "{app}\versions\{#AppVersion}"; Flags: ignoreversion recursesubdirs createallsubdirs
; The pointer that decides which version runs.
Source: "..\staging-current.txt"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
; versions\ is created by the file copy, but ensure it exists first so the
; layout is right even for an empty payload.
Name: "{app}\versions"

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\versions\{#AppVersion}\{#AppExeName}"; WorkingDir: "{app}\versions\{#AppVersion}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\versions\{#AppVersion}\{#AppExeName}"; WorkingDir: "{app}\versions\{#AppVersion}"; Tasks: desktopicon

[Run]
Filename: "{app}\versions\{#AppVersion}\{#AppExeName}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[Code]
// Remove version folders left behind by updates.
//
// The folder this installer created is already tracked and removed by Inno's
// own file handling. Anything else under versions/ is a leftover from an
// update. Uninstalling means the user is removing the whole application, so
// there is no reason to preserve the active version - keeping it would leave a
// broken copy behind that nothing can launch.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  VersionsDir: String;
  Found: TFindRec;
  EntryName: String;
begin
  if CurUninstallStep = usUninstall then
  begin
    VersionsDir := ExpandConstant('{app}\versions');
    if DirExists(VersionsDir) then
    begin
      if FindFirst(VersionsDir + '\*', Found) then
      try
        repeat
          EntryName := Found.Name;
          if (Found.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
          begin
            if (CompareText(EntryName, '..') <> 0) and (EntryName <> '.') and
               (CompareText(EntryName, '{#AppVersion}') <> 0) then
              DelTree(VersionsDir + '\' + EntryName, True, True, True);
          end;
        until not FindNext(Found);
      finally
        FindClose(Found);
      end;
    end;
  end;
end;
