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
  X2CLunaMenuBarPainter, ActnList;

type
  TfrmMain = class(TForm)
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
    lbEvents: TListBox;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    chkHotHand: TCheckBox;
    mbTest: TX2MenuBar;
    alMenu: TActionList;
    actTest: TAction;
    procedure mbTestSelectedChanging(Sender: TObject; Item,
      NewItem: TX2CustomMenuBarItem; var Allowed: Boolean);
    procedure mbTestSelectedChanged(Sender: TObject;
      Item: TX2CustomMenuBarItem);
    procedure chkHotHandClick(Sender: TObject);
    procedure mbTestExpanding(Sender: TObject; Group: TX2MenuBarGroup; var Allowed: Boolean);
    procedure mbTestExpanded(Sender: TObject; Group: TX2MenuBarGroup);
    procedure mbTestCollapsing(Sender: TObject; Group: TX2MenuBarGroup; var Allowed: Boolean);
    procedure mbTestCollapsed(Sender: TObject; Group: TX2MenuBarGroup);
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
    procedure actTestExecute(Sender: TObject);
  private
    procedure Event(const AMsg: String);
  end;

implementation
uses
  Dialogs,
  
  X2UtHandCursor;

{$R *.dfm}

procedure TfrmMain.actTestExecute(Sender: TObject);
begin
  ShowMessage('Action saying: hi!');
end;

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

procedure TfrmMain.chkHotHandClick(Sender: TObject);
begin
  if chkHotHand.Checked then
  begin
    mbTest.CursorGroup  := crHandPoint;
    mbTest.CursorItem   := crHandPoint;
  end else
  begin
    mbTest.CursorGroup  := crDefault;
    mbTest.CursorItem   := crDefault;
  end;
end;

procedure TfrmMain.chkScrollbarClick(Sender: TObject);
begin
  mbTest.Scrollbar := chkScrollbar.Checked;
end;

procedure TfrmMain.Event(const AMsg: String);
begin
  lbEvents.ItemIndex := lbEvents.Items.Add(AMsg);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  chkAutoCollapse.Checked := mbTest.AutoCollapse;
  chkAutoSelectItem.Checked := mbTest.AutoSelectItem;
  chkAllowCollapseAll.Checked := mbTest.AllowCollapseAll;
  chkScrollbar.Checked := mbTest.Scrollbar;
  chkHideScrollbar.Checked := mbTest.HideScrollbar;
end;

procedure TfrmMain.mbTestCollapsed(Sender: TObject; Group: TX2MenuBarGroup);
begin
  Event('OnCollapsed(' + Group.Caption + ')');
end;

procedure TfrmMain.mbTestCollapsing(Sender: TObject; Group: TX2MenuBarGroup; var Allowed: Boolean);
begin
  Event('OnCollapsing(' + Group.Caption + ')');
end;

procedure TfrmMain.mbTestExpanded(Sender: TObject; Group: TX2MenuBarGroup);
begin
  Event('OnExpanded(' + Group.Caption + ')');
end;

procedure TfrmMain.mbTestExpanding(Sender: TObject; Group: TX2MenuBarGroup; var Allowed: Boolean);
begin
  Event('OnExpanding(' + Group.Caption + ')');
end;

procedure TfrmMain.mbTestSelectedChanged(Sender: TObject; Item: TX2CustomMenuBarItem);
begin
  Event('OnSelectedChanged(' + Item.Caption + ')');
end;

procedure TfrmMain.mbTestSelectedChanging(Sender: TObject; Item, NewItem: TX2CustomMenuBarItem; var Allowed: Boolean);
var
  itemCaption: String;
  newItemCaption: String;

begin
  itemCaption     := '';
  newItemCaption  := '';

  if Assigned(Item) then
    itemCaption     := Item.Caption;

  if Assigned(NewItem) then
    newItemCaption  := NewItem.Caption;

  Event('OnSelectedChanging(' + itemCaption + ', ' + newItemCaption + ')');
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
