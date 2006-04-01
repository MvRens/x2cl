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
  else
    style := asNone;

  mcPainter.AnimationStyle := style;
  unaPainter.AnimationStyle := style;
end;

procedure TfrmMain.chkAllowCollapseAllClick(Sender: TObject);
begin
  if chkAllowCollapseAll.Checked then
    mbTest.Options  := mbTest.Options + [mboAllowCollapseAll]
  else
    mbTest.Options  := mbTest.Options - [mboAllowCollapseAll];
end;

procedure TfrmMain.chkAutoCollapseClick(Sender: TObject);
begin
  if chkAutoCollapse.Checked then
    mbTest.Options := mbTest.Options + [mboAutoCollapse]
  else
    mbTest.Options := mbTest.Options - [mboAutoCollapse];
end;

procedure TfrmMain.chkAutoSelectItemClick(Sender: TObject);
begin
  if chkAutoSelectItem.Checked then
    mbTest.Options := mbTest.Options + [mboAutoSelectItem]
  else
    mbTest.Options := mbTest.Options - [mboAutoSelectItem];
end;

procedure TfrmMain.chkBlurShadowClick(Sender: TObject);
begin
  unaPainter.BlurShadow := chkBlurShadow.Checked;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  chkAutoCollapse.Checked := mboAutoCollapse in mbTest.Options;
  chkAutoSelectItem.Checked := mboAutoSelectItem in mbTest.Options;
  chkAllowCollapseAll.Checked := mboAllowCollapseAll in mbTest.Options;
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
  mcPainter.AnimationTime := seAnimationTime.AsInteger;
  unaPainter.AnimationTime := seAnimationTime.AsInteger;
end;

end.
