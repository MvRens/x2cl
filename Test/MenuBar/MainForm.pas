unit MainForm;

interface
uses
  Classes,
  Controls,
  Forms,
  ImgList,

  PNGImage,
  X2CLGraphicList,
  X2CLMenuBar,
  X2CLmusikCubePainter, StdCtrls, ExtCtrls, Mask, JvExMask, JvSpin;

type
  TfrmMain = class(TForm)
    mbTest:               TX2MenuBar;
    mbPainter: TX2MenuBarmusikCubePainter;
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
    procedure AnimationClick(Sender: TObject);
    procedure seAnimationTimeChange(Sender: TObject);
  end;

implementation

{$R *.dfm}

procedure TfrmMain.AnimationClick(Sender: TObject);
begin
  if rbSliding.Checked then
    mbPainter.AnimationStyle  := asSlide
  else
    mbPainter.AnimationStyle  := asNone;
end;

procedure TfrmMain.seAnimationTimeChange(Sender: TObject);
begin
  mbPainter.AnimationTime := seAnimationTime.AsInteger;
end;

end.
