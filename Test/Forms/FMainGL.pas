unit FMainGL;

interface
uses
  Classes,
  ComCtrls,
  Controls,
  ExtCtrls,
  Forms,
  ImgList,
  Menus,
  PNGImage,
  ToolWin,
  IconXP,
  X2CLGraphicList;

type
  TfrmMain = class(TForm)
    gcMain:                       TX2GraphicContainer;
    glMain:                       TX2GraphicList;
    glTree:                       TX2GraphicList;
    mnuMain:                      TMainMenu;
    mnuTest:                      TMenuItem;
    mnuTestImage:                 TMenuItem;
    tbMain:                       TToolBar;
    tbTest:                       TToolButton;
    tvTest:                       TTreeView;
    glMainDisabled: TX2GraphicList;
  end;

implementation

{$R *.dfm}

end.
