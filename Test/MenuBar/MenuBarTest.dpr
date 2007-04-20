program MenuBarTest;

uses
  Forms,
  MainForm in 'MainForm.pas' {frmMain},
  X2CLMenuBarAnimators in '..\..\Source\X2CLMenuBarAnimators.pas',
  X2CLGraphics in '..\..\Source\X2CLGraphics.pas',
  X2CLunaMenuBarPainter in '..\..\Source\X2CLunaMenuBarPainter.pas',
  X2CLMenuBar in '..\..\Source\X2CLMenuBar.pas',
  X2CLmusikCubeMenuBarPainter in '..\..\Source\X2CLmusikCubeMenuBarPainter.pas',
  X2CLMenuBarActions in '..\..\Source\X2CLMenuBarActions.pas';

{$R *.res}

var
  frmMain:    TfrmMain;

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
