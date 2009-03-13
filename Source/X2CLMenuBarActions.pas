unit X2CLMenuBarActions;

interface
uses
  Contnrs,
  Graphics,
  Windows,
  
  X2CLMenuBar;


type
  {
    :$ Animate group expand/collapse.

    :: Handles the animating of a single group.
  }
  TX2MenuBarAnimateAction = class(TX2CustomMenuBarAction)
  private
    FAnimator:    TX2CustomMenuBarAnimator;
    FGroup:       TX2MenuBarGroup;
  protected
    property Animator:  TX2CustomMenuBarAnimator  read FAnimator;
    property Group:     TX2MenuBarGroup           read FGroup;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar; AGroup: TX2MenuBarGroup;
                       AAnimator: TX2CustomMenuBarAnimator);
    destructor Destroy(); override;

    procedure Start(); override;

    procedure BeforePaint(); override;
    procedure GetItemHeight(AItem: TX2CustomMenuBarItem; var AHeight: Integer;
                            var AHandled: Boolean); override;
    procedure DrawMenuItem(ACanvas: TCanvas; APainter: TX2CustomMenuBarPainter;
                           AItem: TX2CustomMenuBarItem; const AMenuBounds: TRect;
                           const AItemBounds: TRect; AState: TX2MenuBarDrawStates;
                           var AHandled: Boolean); override;
    procedure AfterPaint(); override;
  end;


  {
    :$ Animate multiple groups expanding/collapsing.

    :: Manages multiple TX2MenuBarAnimateAction instances in one action.
  }
  TX2MenuBarAnimateMultipleAction = class(TX2CustomMenuBarAction)
  private
    FAnimateActions:    TObjectList;

    function GetCount(): Integer;
  protected
    function GetAnimateAction(AIndex: Integer): TX2MenuBarAnimateAction;
    function GetTerminated(): Boolean; override;

    property AnimateActions:    TObjectList read FAnimateActions;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar);
    destructor Destroy(); override;

    procedure Add(AAction: TX2MenuBarAnimateAction);

    procedure BeforePaint(); override;
    procedure GetItemHeight(AItem: TX2CustomMenuBarItem; var AHeight: Integer;
                            var AHandled: Boolean); override;
    procedure DrawMenuItem(ACanvas: TCanvas; APainter: TX2CustomMenuBarPainter;
                           AItem: TX2CustomMenuBarItem; const AMenuBounds: TRect;
                           const AItemBounds: TRect; AState: TX2MenuBarDrawStates;
                           var AHandled: Boolean); override;
    procedure AfterPaint(); override;

    property Count:   Integer read GetCount;
  end;


  {
    :$ Sets the Expanded property of a group.

    :: Provides a way to set the Expanded property of a group after it has
    :: been animated.
  }
  TX2MenuBarExpandAction = class(TX2CustomMenuBarAction)
  private
    FExpanding:   Boolean;
    FGroup:       TX2MenuBarGroup;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar; AGroup: TX2MenuBarGroup;
                       AExpanding: Boolean);

    procedure Start(); override;
  end;


  {
    :$ Sets the Selected property.

    :: Provides a way to set the Selected property of an item after
    :: animating.
  }
  TX2MenuBarSelectAction = class(TX2CustomMenuBarAction)
  private
    FItem:        TX2CustomMenuBarItem;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar; AItem: TX2CustomMenuBarItem);

    procedure Start(); override;
  end;


implementation
uses
  SysUtils;


type
  TProtectedX2CustomMenuBarPainter = class(TX2CustomMenuBarPainter);
  TProtectedX2CustomMenuBar = class(TX2CustomMenuBar);
  TProtectedX2MenuBarGroup = class(TX2MenuBarGroup);



{ TX2MenuBarAnimateAction }
constructor TX2MenuBarAnimateAction.Create(AMenuBar: TX2CustomMenuBar; AGroup: TX2MenuBarGroup;
                                           AAnimator: TX2CustomMenuBarAnimator);
begin
  inherited Create(AMenuBar);

  FAnimator := AAnimator;
  FGroup    := AGroup;
end;


destructor TX2MenuBarAnimateAction.Destroy();
begin
  FreeAndNil(FAnimator);

  inherited;
end;


procedure TX2MenuBarAnimateAction.Start();
begin
  inherited;

  Animator.ResetStartTime();
end;


procedure TX2MenuBarAnimateAction.BeforePaint();
begin
  inherited;

   Animator.Update();
   if Animator.Terminated then
    Terminate();
end;


procedure TX2MenuBarAnimateAction.GetItemHeight(AItem: TX2CustomMenuBarItem;
                                                var AHeight: Integer;
                                                var AHandled: Boolean);
begin
  inherited;

  if AItem = Group then
  begin
    AHeight   := Animator.Height;
    AHandled  := True;
  end;
end;


procedure TX2MenuBarAnimateAction.DrawMenuItem(ACanvas: TCanvas; APainter: TX2CustomMenuBarPainter;
                                               AItem: TX2CustomMenuBarItem; const AMenuBounds,
                                               AItemBounds: TRect; AState: TX2MenuBarDrawStates;
                                               var AHandled: Boolean);
var
  groupBounds:      TRect;
  painter:          TProtectedX2CustomMenuBarPainter;

begin
  inherited;

  if Group = AItem then
  begin
    painter             := TProtectedX2CustomMenuBarPainter(APainter);
    groupBounds         := AMenuBounds;
    groupBounds.Top     := AItemBounds.Bottom +
                           painter.GetSpacing(seAfterGroupHeader) +
                           painter.GetSpacing(seBeforeFirstItem);
    groupBounds.Bottom  := groupBounds.Top + Animator.Height;
    Animator.Draw(ACanvas, groupBounds);
//    AHandled            := True;
  end;
end;


procedure TX2MenuBarAnimateAction.AfterPaint();
begin
  inherited;

  if not Terminated then
  begin
    { Prevent 100% CPU usage }
    Sleep(5);

    TProtectedX2CustomMenuBar(MenuBar).TestMousePos();
    MenuBar.Invalidate();
  end;
end;


{ TX2MenuBarAnimateMultipleAction }
constructor TX2MenuBarAnimateMultipleAction.Create(AMenuBar: TX2CustomMenuBar);
begin
  inherited;

  FAnimateActions := TObjectList.Create(True);
end;


destructor TX2MenuBarAnimateMultipleAction.Destroy();
begin
  FreeAndNil(FAnimateActions);

  inherited;
end;


procedure TX2MenuBarAnimateMultipleAction.Add(AAction: TX2MenuBarAnimateAction);
begin
  AnimateActions.Add(AAction);
end;


procedure TX2MenuBarAnimateMultipleAction.BeforePaint();
var
  actionIndex:      Integer;

begin
  inherited;

  for actionIndex := 0 to Pred(AnimateActions.Count) do
    GetAnimateAction(actionIndex).BeforePaint();
end;


procedure TX2MenuBarAnimateMultipleAction.GetItemHeight(AItem: TX2CustomMenuBarItem;
                                                        var AHeight: Integer;
                                                        var AHandled: Boolean);
var
  actionIndex:      Integer;

begin
  inherited;

  for actionIndex := 0 to Pred(AnimateActions.Count) do
  begin
    GetAnimateAction(actionIndex).GetItemHeight(AItem, AHeight, AHandled);

    if AHandled then
      Break;
  end;
end;


procedure TX2MenuBarAnimateMultipleAction.DrawMenuItem(ACanvas: TCanvas;
                                                       APainter: TX2CustomMenuBarPainter;
                                                       AItem: TX2CustomMenuBarItem;
                                                       const AMenuBounds, AItemBounds: TRect;
                                                       AState: TX2MenuBarDrawStates;
                                                       var AHandled: Boolean);
var
  actionIndex:      Integer;

begin
  inherited;

  for actionIndex := 0 to Pred(AnimateActions.Count) do
  begin
    GetAnimateAction(actionIndex).DrawMenuItem(ACanvas, APainter, AItem,
                                               AMenuBounds, AItemBounds, AState,
                                               AHandled);

    if AHandled then
      Break;
  end;
end;


procedure TX2MenuBarAnimateMultipleAction.AfterPaint();
var
  actionIndex:      Integer;

begin
  inherited;

  for actionIndex := 0 to Pred(AnimateActions.Count) do
    GetAnimateAction(actionIndex).AfterPaint();
end;


function TX2MenuBarAnimateMultipleAction.GetAnimateAction(AIndex: Integer): TX2MenuBarAnimateAction;
begin
  Result := TX2MenuBarAnimateAction(AnimateActions[AIndex]);
end;


function TX2MenuBarAnimateMultipleAction.GetCount(): Integer;
begin
  Result := FAnimateActions.Count;
end;


function TX2MenuBarAnimateMultipleAction.GetTerminated(): Boolean;
var
  actionIndex:      Integer;

begin
  Result := inherited GetTerminated();

  if not Result then
  begin
    for actionIndex := 0 to Pred(AnimateActions.Count) do
      if GetAnimateAction(actionIndex).Terminated then
      begin
        Result := True;
        Break;
      end;
  end;
end;


{ TX2MenuBarExpandAction }
constructor TX2MenuBarExpandAction.Create(AMenuBar: TX2CustomMenuBar;
                                          AGroup: TX2MenuBarGroup;
                                          AExpanding: Boolean);
begin
  inherited Create(AMenuBar);

  FExpanding := AExpanding;
  FGroup := AGroup;
end;


procedure TX2MenuBarExpandAction.Start();
begin
  inherited;

  TProtectedX2CustomMenuBar(MenuBar).InternalSetExpanded(FGroup, FExpanding);
  Terminate();
end;


{ TX2MenuBarSelectAction }
constructor TX2MenuBarSelectAction.Create(AMenuBar: TX2CustomMenuBar;
                                          AItem: TX2CustomMenuBarItem);
begin
  inherited Create(AMenuBar);

  FItem := AItem;
end;


procedure TX2MenuBarSelectAction.Start();
begin
  inherited;

  TProtectedX2CustomMenuBar(MenuBar).InternalSetSelected(FItem);
  Terminate();
end;

end.

