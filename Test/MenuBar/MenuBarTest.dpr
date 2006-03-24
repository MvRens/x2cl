program MenuBarTest;

uses
  Forms,
  MainForm in 'MainForm.pas' {frmMain};

{$R *.res}

var
  frmMain:    TfrmMain;

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
