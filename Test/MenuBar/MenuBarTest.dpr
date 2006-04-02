program MenuBarTest;

uses
  Forms,
  MainForm in 'MainForm.pas' {frmMain},
  X2CLMenuBarAnimators in '..\..\Source\X2CLMenuBarAnimators.pas';

{$R *.res}

var
  frmMain:    TfrmMain;

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
