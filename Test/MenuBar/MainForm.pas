unit MainForm;

interface
uses
  Classes,
  Controls,
  ExtCtrls,
  Forms,
  ImgList,
  Mask,
  StdCtrls,
  XPMan,

  JvExMask,
  JvSpin,
  PNGImage,
  X2CLGraphicList,
  X2CLMenuBar,
  X2CLmusikCubeMenuBarPainter,
  X2CLunaMenuBarPainter;

type
  TfrmMain = class(TForm)
    mbTest:               TX2MenuBar;
    mcPainter: TX2MenuBarmusikCubePainter;
    gcMenu: TX2GraphicContainer;
    glMenu: TX2GraphicList;
    bvlMenu: TBevel;
    rbmusikCube: TRadioButton;
    rbSliding: TRadioButton;
    lblAnimationTime: TLabel;
    seAnimationTime: TJvSpinEdit;
    Panel1: TPanel;
    Panel2: TPanel;
    rbNoAnimation: TRadioButton;
    rbFade: TRadioButton;
    rbUnameIT: TRadioButton;
    unaPainter: TX2MenuBarunaPainter;
    rbDissolve: TRadioButton;
    chkAutoCollapse: TCheckBox;
    chkAllowCollapseAll: TCheckBox;
    chkAutoSelectItem: TCheckBox;
    chkBlurShadow: TCheckBox;
    chkScrollbar: TCheckBox;
    chkHideScrollbar: TCheckBox;
    rbSlideFade: TRadioButton;
    procedure chkHideScrollbarClick(Sender: TObject);
    procedure chkScrollbarClick(Sender: TObject);
    procedure chkBlurShadowClick(Sender: TObject);
    procedure chkAutoSelectItemClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure chkAllowCollapseAllClick(Sender: TObject);
    procedure chkAutoCollapseClick(Sender: TObject);
    procedure PainterClick(Sender: TObject);
    procedure AnimationClick(Sender: TObject);
    procedure seAnimationTimeChange(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TfrmMain.AnimationClick(Sender: TObject);
var
  style: TX2MenuBarAnimationStyle;

begin
  if rbSliding.Checked then
    style := asSlide
  else if rbDissolve.Checked then
    style := asDissolve
  else if rbSlideFade.Checked then
    style := asSlideFade
  else if rbFade.Checked then
    style := asFade
  else
    style := asNone;

  mbTest.AnimationStyle := style;
end;

procedure TfrmMain.chkAllowCollapseAllClick(Sender: TObject);
begin
  mbTest.AllowCollapseAll := chkAllowCollapseAll.Checked;
end;

procedure TfrmMain.chkAutoCollapseClick(Sender: TObject);
begin
  mbTest.AutoCollapse := chkAutoCollapse.Checked;
end;

procedure TfrmMain.chkAutoSelectItemClick(Sender: TObject);
begin
  mbTest.AutoSelectItem := chkAutoSelectItem.Checked;
end;

procedure TfrmMain.chkBlurShadowClick(Sender: TObject);
begin
  unaPainter.BlurShadow := chkBlurShadow.Checked;
end;

procedure TfrmMain.chkHideScrollbarClick(Sender: TObject);
begin
  mbTest.HideScrollbar := chkHideScrollbar.Checked;
end;

procedure TfrmMain.chkScrollbarClick(Sender: TObject);
begin
  mbTest.Scrollbar := chkScrollbar.Checked;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  chkAutoCollapse.Checked := mbTest.AutoCollapse;
  chkAutoSelectItem.Checked := mbTest.AutoSelectItem;
  chkAllowCollapseAll.Checked := mbTest.AllowCollapseAll;
  chkScrollbar.Checked := mbTest.Scrollbar;
  chkHideScrollbar.Checked := mbTest.HideScrollbar;
end;

procedure TfrmMain.PainterClick(Sender: TObject);
begin
  if rbmusikCube.Checked then
  begin
    mbTest.Painter := mcPainter;
    chkAutoCollapse.Checked := False;
    chkAutoSelectItem.Checked := False;
    chkAllowCollapseAll.Checked := True;
  end else
  begin
    mbTest.Painter := unaPainter;
    chkAutoCollapse.Checked := True;
    chkAutoSelectItem.Checked := True;
    chkAllowCollapseAll.Checked := False;
  end;
end;

procedure TfrmMain.seAnimationTimeChange(Sender: TObject);
begin
  mbTest.AnimationTime := seAnimationTime.AsInteger;
end;

end.
