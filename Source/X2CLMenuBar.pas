{
  :: X2CLMenuBar is a generic group/items menu. Through the various painters,
  :: it can resemble styles such as the musikCube or BBox/Uname-IT menu bars.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLMenuBar;

interface
uses
  Classes,
  Contnrs,
  Controls,
  Forms,
  Graphics,
  ImgList,
  Messages,
  Windows;

type
  // #ToDo1 (MvR) 19-3-2006: implement collection Update mechanisms
  // #ToDo1 (MvR) 19-3-2006: group ImageIndex
  // #ToDo1 (MvR) 19-3-2006: OnCollapsing/OnCollapse/expand events
  // #ToDo1 (MvR) 19-3-2006: AutoCollapse property
  // #ToDo1 (MvR) 19-3-2006: AutoSelectItem property or something
  // #ToDo1 (MvR) 19-3-2006: find a way to remember the selected item per
  //                         group, required for when AutoCollapse = True and
  //                         AutoSelectItem = True
  TX2MenuBarPainterClass = class of TX2MenuBarPainter;
  TX2MenuBarPainter = class;
  TX2MenuBarItem = class;
  TX2MenuBarGroup = class;
  TX2CustomMenuBar = class;

  IX2MenuBarPainterObserver = interface
    ['{22DE60C9-49A1-4E7D-B547-901BEDCC0FB7}']
    procedure PainterUpdate(Sender: TX2MenuBarPainter);
  end;

  TX2MenuBarHitTest = record
    HitTestCode:    Integer;
    Item:           TObject;
  end;

  TX2MenuBarDrawState       = (mdsHot, mdsSelected);
  TX2MenuBarDrawStates      = set of TX2MenuBarDrawState;

  TX2MenuBarAnimationStyle  = (asNone, asSlide);

  {
    :$ Abstract animation class

    :: Descendants implement the animation-specific drawing code.
  }
  TX2MenuBarAnimator = class(TObject)
  private
    FAnimationTime:     Cardinal;
    FExpanding:         Boolean;
    FGroup:             TX2MenuBarGroup;
    FMenuBar:           TX2CustomMenuBar;
    FStartTime:         Cardinal;
    FItemsBuffer:       Graphics.TBitmap;
    FTerminated:        Boolean;

    function GetTimeElapsed(): Cardinal;
  protected
    procedure Terminate(); virtual;

    property ItemsBuffer:     Graphics.TBitmap  read FItemsBuffer;
    property MenuBar:         TX2CustomMenuBar  read FMenuBar         write FMenuBar;
    property TimeElapsed:     Cardinal          read GetTimeElapsed;
  public
    constructor Create(AItemsBuffer: Graphics.TBitmap); virtual;
    destructor Destroy(); override;

    function PrepareHitPoint(APoint: TPoint): TPoint; virtual;
    function Draw(ACanvas: TCanvas; const ABounds: TRect): Integer; virtual; abstract;

    property AnimationTime:   Cardinal                  read FAnimationTime   write FAnimationTime;
    property Expanding:       Boolean                   read FExpanding       write FExpanding;
    property Group:           TX2MenuBarGroup           read FGroup           write FGroup;
    property Terminated:      Boolean                   read FTerminated;
  end;

  {
    :$ Implements a sliding animation
  }
  TX2MenuBarSlideAnimator = class(TX2MenuBarAnimator)
  private
    FSlidePos:        Integer;
    FSlideHeight:     Integer;
  public
    function PrepareHitPoint(APoint: TPoint): TPoint; override;
    function Draw(ACanvas: TCanvas; const ABounds: TRect): Integer; override;
  end;

  {
    :$ Abstract painter class.

    :: Descendants must implement the actual drawing code.
  }
  TX2MenuBarPainter = class(TComponent)
  private
    FAnimationStyle:  TX2MenuBarAnimationStyle;
    FAnimationTime:   Cardinal;
    FMenuBar:         TX2CustomMenuBar;
    FObservers:       TInterfaceList;

    function GetMenuBar(): TX2CustomMenuBar;
  protected
    procedure BeginPaint(const AMenuBar: TX2CustomMenuBar);
    procedure EndPaint();

    function GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer; virtual; abstract;
    function GetGroupHeight(AGroup: TX2MenuBarGroup): Integer; virtual;
    function GetItemHeight(AItem: TX2MenuBarItem): Integer; virtual; abstract;

    procedure DrawBackground(ACanvas: TCanvas; const ABounds: TRect); virtual; abstract;
    procedure DrawGroupHeader(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect; AState: TX2MenuBarDrawStates); virtual; abstract;
    procedure DrawItem(ACanvas: TCanvas; AItem: TX2MenuBarItem; const ABounds: TRect; AState: TX2MenuBarDrawStates); virtual; abstract;

    function CreateAnimator(AItemsBuffer: Graphics.TBitmap): TX2MenuBarAnimator; virtual;

    procedure NotifyObservers();

    property MenuBar:           TX2CustomMenuBar          read GetMenuBar;
  protected
    property AnimationStyle:    TX2MenuBarAnimationStyle  read FAnimationStyle  write FAnimationStyle;
    property AnimationTime:     Cardinal                  read FAnimationTime   write FAnimationTime;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    function HitTest(APoint: TPoint): TX2MenuBarHitTest; overload; virtual;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    procedure AttachObserver(AObserver: IX2MenuBarPainterObserver);
    procedure DetachObserver(AObserver: IX2MenuBarPainterObserver);
  end;

  {
    :$ Contains a single menu item.
  }
  TX2MenuBarItem = class(TCollectionItem)
  private
    FCaption:       String;
    FData:          TObject;
    FOwnsData:      Boolean;
    FImageIndex:    TImageIndex;

    function GetGroup(): TX2MenuBarGroup;
    function GetMenuBar(): TX2CustomMenuBar;
    procedure SetCaption(const Value: String);
    procedure SetData(const Value: TObject);
    procedure SetImageIndex(const Value: TImageIndex);
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy(); override;

    procedure Assign(Source: TPersistent); override;

    property Data:          TObject           read FData        write SetData;
    property Group:         TX2MenuBarGroup   read GetGroup;
    property MenuBar:       TX2CustomMenuBar  read GetMenuBar;
    property OwnsData:      Boolean           read FOwnsData    write FOwnsData;
  published
    property Caption:       String            read FCaption     write SetCaption;
    property ImageIndex:    TImageIndex       read FImageIndex  write SetImageIndex;
  end;

  {
    :$ Manages a collection of menu items.
  }
  TX2MenuBarItems = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TX2MenuBarItem;
    procedure SetItem(Index: Integer; const Value: TX2MenuBarItem);
  public
    constructor Create(AOwner: TPersistent);

    function Add(const ACaption: TCaption = ''): TX2MenuBarItem;

    property Items[Index: Integer]: TX2MenuBarItem read GetItem write SetItem; default;
  end;

  {
    :$ Contains a single menu group.
  }
  TX2MenuBarGroup = class(TCollectionItem)
  private
    FCaption:     String;
    FExpanded:    Boolean;
    FItems:       TX2MenuBarItems;
    FData:        TObject;
    FOwnsData:    Boolean;

    function GetMenuBar(): TX2CustomMenuBar;
    procedure SetCaption(const Value: String);
    procedure SetExpanded(const Value: Boolean);
    procedure SetItems(const Value: TX2MenuBarItems);
    procedure SetData(const Value: TObject);
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy(); override;

    procedure Assign(Source: TPersistent); override;

    property Data:      TObject           read FData      write SetData;
    property MenuBar:   TX2CustomMenuBar  read GetMenuBar;
    property OwnsData:  Boolean           read FOwnsData  write FOwnsData;
  published
    property Caption:   String            read FCaption   write SetCaption;
    property Expanded:  Boolean           read FExpanded  write SetExpanded;
    property Items:     TX2MenuBarItems   read FItems     write SetItems;
  end;

  {
    :$ Manages a collection of menu groups.
  }
  TX2MenuBarGroups = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TX2MenuBarGroup;
    procedure SetItem(Index: Integer; const Value: TX2MenuBarGroup);
  public
    constructor Create(AOwner: TPersistent);

    function Add(const ACaption: TCaption = ''): TX2MenuBarGroup;

    property Items[Index: Integer]: TX2MenuBarGroup read GetItem write SetItem; default;
  end;

  {
    :$ Implements the menu bar.

    :: The menu bar is the visual container for the menu. It manages the groups
    :: and items, and implements the switching between menu items. It does not
    :: paint itself, instead it delegates this to it's linked Painter.
  }
  TX2CustomMenuBar = class(TCustomControl, IX2MenuBarPainterObserver)
  private
    FBorderStyle:     TBorderStyle;
    FGroups:          TX2MenuBarGroups;
    FPainter:         TX2MenuBarPainter;
    FHotItem:         TObject;
    FSelectedItem:    TObject;
    FImageList:       TCustomImageList;
    FAnimator:        TX2MenuBarAnimator;
    FLastMousePos:    TPoint;

    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetGroups(const Value: TX2MenuBarGroups);
    procedure SetImageList(const Value: TCustomImageList);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PainterUpdate(Sender: TX2MenuBarPainter);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
//    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;

    procedure TestMousePos(); virtual;
  protected
    procedure SetPainter(const Value: TX2MenuBarPainter); virtual;

    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure Paint(); override;

    function GetDrawState(AItem: TObject): TX2MenuBarDrawStates;
    function DrawMenu(ACanvas: TCanvas; const ABounds: TRect): Integer; virtual;
    function DrawMenuItems(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect): Integer; virtual;
    procedure DrawNoPainter(ACanvas: TCanvas; const ABounds: TRect); virtual;

    function AllowInteraction(): Boolean; virtual;
    procedure AnimateExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean);

    property Animator:    TX2MenuBarAnimator  read FAnimator    write FAnimator;
    property BorderStyle: TBorderStyle        read FBorderStyle write SetBorderStyle default bsNone;
  protected
    function ExpandedChanging(AGroup: TX2MenuBarGroup; AExpanding: Boolean): Boolean; virtual;
    procedure ExpandedChanged(AGroup: TX2MenuBarGroup); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    function HitTest(APoint: TPoint): TX2MenuBarHitTest; overload;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    property Groups:      TX2MenuBarGroups  read FGroups      write SetGroups;
    property ImageList:   TCustomImageList  read FImageList   write SetImageList;
    property Painter:     TX2MenuBarPainter read FPainter     write SetPainter;
  end;

  {
    :$ Exposes the menu bar's published properties.
  }
  TX2MenuBar = class(TX2CustomMenuBar)
  published
    property Align;
    property BevelEdges;
    property BevelInner;
    property BevelKind;
    property BevelOuter;
    property BorderStyle;
    property BorderWidth;
    property Groups;
    property ImageList;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property Painter;
  end;

  {
    :$ Provides a wrapper for the DrawText API.
  }
  TDrawTextClipStyle  = (csNone, csEllipsis, csPathEllipsis);

  procedure DrawText(ACanvas: TCanvas; const AText: String;
                     const ABounds: TRect;
                     AHorzAlignment: TAlignment = taLeftJustify;
                     AVertAlignment: TVerticalAlignment = taVerticalCenter;
                     AMultiLine: Boolean = False;
                     AClipStyle: TDrawTextClipStyle = csNone);


const
  { HitTest Codes }
  htUnknown     = 0;
  htBackground  = 1;
  htGroup       = 2;
  htItem        = 3;

implementation
uses
  SysUtils;

const
  DefaultAnimationStyle = asSlide;
  DefaultAnimationTime  = 250;
  SDefaultItemCaption   = 'Menu Item';
  SDefaultGroupCaption  = 'Group';
  SNoPainter            = 'Painter property not set';
  

{ DrawText wrapper }
procedure DrawText(ACanvas: TCanvas; const AText: String;
                   const ABounds: TRect; AHorzAlignment: TAlignment;
                   AVertAlignment: TVerticalAlignment;
                   AMultiLine: Boolean; AClipStyle: TDrawTextClipStyle);
const
  HorzAlignmentFlags:   array[TAlignment] of Cardinal =
                          (DT_LEFT, DT_RIGHT, DT_CENTER);
  VertAlignmentFlags:   array[TVerticalAlignment] of Cardinal =
                          (DT_TOP, DT_BOTTOM, DT_VCENTER);
  MultiLineFlags:       array[Boolean] of Cardinal =
                          (DT_SINGLELINE, 0);
  ClipStyleFlags:       array[TDrawTextClipStyle] of Cardinal =
                          (0, DT_END_ELLIPSIS, DT_PATH_ELLIPSIS);

var
  flags:    Cardinal;
  bounds:   TRect;

begin
  flags := HorzAlignmentFlags[AHorzAlignment] or
           VertAlignmentFlags[AVertAlignment] or
           MultiLineFlags[AMultiLine] or
           ClipStyleFlags[AClipStyle];

  if AMultiLine and (AClipStyle <> csNone) then
    flags := flags or DT_EDITCONTROL;

  bounds  := ABounds;
  Windows.DrawText(ACanvas.Handle, PChar(AText), Length(AText), bounds, flags);
end;


{ TX2MenuBarPainter }
constructor TX2MenuBarPainter.Create(AOwner: TComponent);
begin
  inherited;

  FAnimationStyle := DefaultAnimationStyle;
  FAnimationTime  := DefaultAnimationTime;

  if AOwner is TX2CustomMenuBar then
    FMenuBar  := TX2CustomMenuBar(AOwner);
end;

destructor TX2MenuBarPainter.Destroy();
begin
  FreeAndNil(FObservers);
  inherited;
end;


procedure TX2MenuBarPainter.AttachObserver(AObserver: IX2MenuBarPainterObserver);
begin
  if not Assigned(FObservers) then
    FObservers := TInterfaceList.Create();

  if FObservers.IndexOf(AObserver) = -1 then
    FObservers.Add(AObserver);
end;

procedure TX2MenuBarPainter.DetachObserver(AObserver: IX2MenuBarPainterObserver);
begin
  if Assigned(FObservers) then
    FObservers.Remove(AObserver);
end;


procedure TX2MenuBarPainter.BeginPaint(const AMenuBar: TX2CustomMenuBar);
begin
  Assert(not Assigned(FMenuBar), 'BeginPaint already called');
  FMenuBar  := AMenuBar;
end;

procedure TX2MenuBarPainter.EndPaint();
begin
  Assert(Assigned(FMenuBar), 'EndPaint without BeginPaint');
  FMenuBar  := nil;
end;

procedure TX2MenuBarPainter.NotifyObservers();
var
  observerIndex:    Integer;

begin
  if Assigned(FObservers) then
    for observerIndex := 0 to Pred(FObservers.Count) do
      (FObservers[observerIndex] as IX2MenuBarPainterObserver).PainterUpdate(Self);
end;


function TX2MenuBarPainter.GetGroupHeight(AGroup: TX2MenuBarGroup): Integer;
var
  itemIndex:    Integer;

begin
  Result := 0;
  for itemIndex := 0 to Pred(AGroup.Items.Count) do
    Inc(Result, GetItemHeight(AGroup.Items[itemIndex]));
end;


function TX2MenuBarPainter.CreateAnimator(AItemsBuffer: Graphics.TBitmap): TX2MenuBarAnimator;
begin
  Result  := nil;
  
  case AnimationStyle of
    asSlide:    Result  := TX2MenuBarSlideAnimator.Create(AItemsBuffer);
  end;

  if Assigned(Result) then
    Result.AnimationTime  := AnimationTime;
end;


function TX2MenuBarPainter.HitTest(APoint: TPoint): TX2MenuBarHitTest;
var
  hitRect:        TRect;
  groupIndex:     Integer;
  group:          TX2MenuBarGroup;
  itemIndex:      Integer;
  item:           TX2MenuBarItem;

begin
  Result.HitTestCode  := htUnknown;
  Result.Item         := nil;
  hitRect             := Rect(0, 0, MenuBar.ClientWidth, 0);

  for groupIndex := 0 to Pred(MenuBar.Groups.Count) do
  begin
    group           := MenuBar.Groups[groupIndex];
    hitRect.Bottom  := hitRect.Top + GetGroupHeaderHeight(group);

    if PtInRect(hitRect, APoint) then
    begin
      Result.HitTestCode  := htGroup;
      Result.Item         := group;
      break;
    end;

    hitRect.Top     := hitRect.Bottom;
    if group.Expanded then
    begin
      for itemIndex := 0 to Pred(group.Items.Count) do
      begin
        item            := group.Items[itemIndex];
        hitRect.Bottom  := hitRect.Top + GetItemHeight(item);

        if PtInRect(hitRect, APoint) then
        begin
          Result.HitTestCode  := htItem;
          Result.Item         := item;
          break;
        end;

        hitRect.Top     := hitRect.Bottom;
      end;

      if Result.HitTestCode <> htUnknown then
        break;
    end;
  end;
end;

function TX2MenuBarPainter.HitTest(AX, AY: Integer): TX2MenuBarHitTest;
begin
  Result  := HitTest(Point(AX, AY));
end;


function TX2MenuBarPainter.GetMenuBar(): TX2CustomMenuBar;
begin
  Assert(Assigned(FMenuBar), 'BeginPaint not called');
  Result  := FMenuBar;
end;


{ TX2MenuBarAnimator }
constructor TX2MenuBarAnimator.Create(AItemsBuffer: Graphics.TBitmap);
begin
  inherited Create();

  FStartTime    := GetTickCount();
  FItemsBuffer  := Graphics.TBitmap.Create();
  FItemsBuffer.Assign(AItemsBuffer);
end;

destructor TX2MenuBarAnimator.Destroy();
begin
  FreeAndNil(FItemsBuffer);

  inherited;
end;


function TX2MenuBarAnimator.GetTimeElapsed(): Cardinal;
var
  currentTime:      Cardinal;

begin
  currentTime := GetTickCount();
  Result      := currentTime - FStartTime;

  if currentTime < FStartTime then
    Inc(Result, High(Cardinal));
end;

procedure TX2MenuBarAnimator.Terminate();
begin
  FTerminated := True;
end;


function TX2MenuBarAnimator.PrepareHitPoint(APoint: TPoint): TPoint;
begin
  Result := APoint;
end;

{ TX2MenuBarSlideAnimator }
function TX2MenuBarSlideAnimator.PrepareHitPoint(APoint: TPoint): TPoint;
begin
  Result  := inherited PrepareHitPoint(APoint);

  { While expanding / collapsing, Group.Expanded has already changed. HitTest
    uses this data to determine if items should be taken into account. We must
    compensate for that while sliding. }
  if Expanding then
  begin
    if Result.Y > (FSlidePos + FSlideHeight) then
      Inc(Result.Y, ItemsBuffer.Height - FSlideHeight);
  end
  else
    if Result.Y >= FSlidePos then
      if Result.Y <= FSlidePos + FSlideHeight then
        Result.Y  := -1
      else
        Dec(Result.Y, FSlideHeight);
end;

function TX2MenuBarSlideAnimator.Draw(ACanvas: TCanvas; const ABounds: TRect): Integer;
var
  elapsed:      Cardinal;
  sourceRect:   TRect;
  destRect:     TRect;

begin
  elapsed         := TimeElapsed;
  FSlidePos       := ABounds.Top;
  FSlideHeight    := Trunc((elapsed / AnimationTime) * ItemsBuffer.Height);
  if not Expanding then
    FSlideHeight  := ItemsBuffer.Height - FSlideHeight;

  Result          := FSlideHeight;

  sourceRect      := Rect(0, 0, ItemsBuffer.Width, FSlideHeight);
  destRect        := ABounds;
  destRect.Bottom := destRect.Top + FSlideHeight;
  ACanvas.CopyRect(destRect, ItemsBuffer.Canvas, sourceRect);

  if elapsed >= AnimationTime then
    Terminate();
end;


{ TX2MenuBarItem }
constructor TX2MenuBarItem.Create(Collection: TCollection);
begin
  inherited;

  FCaption  := SDefaultItemCaption;
end;

destructor TX2MenuBarItem.Destroy();
begin
  if OwnsData then
    FreeAndNil(FData);

  inherited;
end;


function TX2MenuBarItem.GetGroup(): TX2MenuBarGroup;
begin
  Result  := nil;

  if Assigned(Collection) and (Collection.Owner <> nil) and
     (Collection.Owner is TX2MenuBarGroup) then
    Result  := TX2MenuBarGroup(Collection.Owner);  
end;

function TX2MenuBarItem.GetMenuBar(): TX2CustomMenuBar;
var
  group:    TX2MenuBarGroup;

begin
  Result  := nil;
  group   := GetGroup();
  if Assigned(group) then
    Result  := group.MenuBar;
end;

procedure TX2MenuBarItem.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarItem then
    with TX2MenuBarItem(Source) do
    begin
      Self.Caption  := Caption;
      Self.Data     := Data;
      Self.OwnsData := OwnsData;
    end
  else
    inherited;
end;


procedure TX2MenuBarItem.SetCaption(const Value: String);
begin
  if Value <> FCaption then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TX2MenuBarItem.SetData(const Value: TObject);
begin
  if Value <> FData then
  begin
    if FOwnsData then
      FreeAndNil(FData);

    FData := Value;
  end;
end;

procedure TX2MenuBarItem.SetImageIndex(const Value: TImageIndex);
begin
  if Value <> FImageIndex then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;


{ TX2MenuBarItems }
constructor TX2MenuBarItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TX2MenuBarItem);
end;


function TX2MenuBarItems.Add(const ACaption: TCaption): TX2MenuBarItem;
begin
  Result          := TX2MenuBarItem(inherited Add());
  Result.Caption  := ACaption;
end;


function TX2MenuBarItems.GetItem(Index: Integer): TX2MenuBarItem;
begin
  Result  := TX2MenuBarItem(inherited GetItem(Index));
end;

procedure TX2MenuBarItems.SetItem(Index: Integer; const Value: TX2MenuBarItem);
begin
  inherited SetItem(Index, Value);
end;


{ TX2MenuBarGroup }
constructor TX2MenuBarGroup.Create(Collection: TCollection);
begin
  inherited;

  FCaption  := SDefaultGroupCaption;
  FItems    := TX2MenuBarItems.Create(Self);
end;

destructor TX2MenuBarGroup.Destroy();
begin
  FreeAndNil(FItems);

  if OwnsData then
    FreeAndNil(FData);

  inherited;
end;


procedure TX2MenuBarGroup.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarGroup then
    with TX2MenuBarGroup(Source) do
    begin
      Self.Caption  := Caption;
      Self.Items.Assign(Items);
    end
  else
    inherited;
end;


function TX2MenuBarGroup.GetMenuBar(): TX2CustomMenuBar;
begin
  Result  := nil;

  if Assigned(Collection) and (Collection.Owner <> nil) and
     (Collection.Owner is TX2CustomMenuBar) then
    Result  := TX2CustomMenuBar(Collection.Owner);
end;

procedure TX2MenuBarGroup.SetCaption(const Value: String);
begin
  if Value <> FCaption then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TX2MenuBarGroup.SetData(const Value: TObject);
begin
  if Value <> FData then
  begin
    if FOwnsData then
      FreeAndNil(FData);

    FData := Value;
  end;
end;

procedure TX2MenuBarGroup.SetExpanded(const Value: Boolean);
var
  menu:     TX2CustomMenuBar;

begin
  if Value <> FExpanded then
  begin
    menu  := MenuBar;
    if Assigned(menu) then
      menu.ExpandedChanging(Self, Value);

    FExpanded := Value;
    Changed(False);

    if Assigned(menu) then
      menu.ExpandedChanged(Self);
  end;
end;

procedure TX2MenuBarGroup.SetItems(const Value: TX2MenuBarItems);
begin
  if Value <> FItems then
  begin
    FItems.Assign(Value);
    Changed(False);
  end;
end;


{ TX2MenuBarGroups }
constructor TX2MenuBarGroups.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TX2MenuBarGroup);
end;


function TX2MenuBarGroups.Add(const ACaption: TCaption): TX2MenuBarGroup;
begin
  Result          := TX2MenuBarGroup(inherited Add());
  if Length(ACaption) > 0 then
    Result.Caption  := ACaption;
end;


function TX2MenuBarGroups.GetItem(Index: Integer): TX2MenuBarGroup;
begin
  Result := TX2MenuBarGroup(inherited GetItem(Index));
end;

procedure TX2MenuBarGroups.SetItem(Index: Integer; const Value: TX2MenuBarGroup);
begin
  inherited SetItem(Index, Value);
end;

{ TX2CustomMenuBar }
constructor TX2CustomMenuBar.Create(AOwner: TComponent);
begin
  inherited;

  FBorderStyle  := bsNone;
  FGroups       := TX2MenuBarGroups.Create(Self);
end;

procedure TX2CustomMenuBar.CreateParams(var Params: TCreateParams);
const
  BorderStyles:   array[TBorderStyle] of DWORD = (0, WS_BORDER);

begin
  inherited;

  { Source: TScrollBox.CreateParams }
  with Params do
  begin
    Style := Style or BorderStyles[FBorderStyle];

    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style   := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
end;

destructor TX2CustomMenuBar.Destroy();
begin
  FreeAndNil(FGroups);

  inherited;
end;

procedure TX2CustomMenuBar.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result  := 0;
end;

procedure TX2CustomMenuBar.Paint();
var
  buffer:           Graphics.TBitmap;

begin
  if Assigned(Painter) then
  begin
    buffer  := Graphics.TBitmap.Create();
    try
      buffer.PixelFormat  := pf24bit;
      buffer.Width        := Self.ClientWidth;
      buffer.Height       := Self.ClientHeight;

      Painter.BeginPaint(Self);
      try
        Painter.DrawBackground(buffer.Canvas, Self.ClientRect);
        DrawMenu(buffer.Canvas, Self.ClientRect);
      finally
        Painter.EndPaint();
      end;
    finally
      Self.Canvas.Draw(0, 0, buffer);
      FreeAndNil(buffer);
    end;

    if Assigned(Animator) then
    begin
      if Animator.Terminated then
        FreeAndNil(FAnimator);

      TestMousePos();
      Invalidate();
    end;
  end
  else
    DrawNoPainter(Self.Canvas, Self.ClientRect);
end;


function TX2CustomMenuBar.GetDrawState(AItem: TObject): TX2MenuBarDrawStates;
begin
  Result  := [];

  if AItem = FHotItem then
    Include(Result, mdsHot);

  if AItem = FSelectedItem then
    Include(Result, mdsSelected);
end;

function TX2CustomMenuBar.DrawMenu(ACanvas: TCanvas; const ABounds: TRect): Integer;
var
  groupIndex:       Integer;
  group:            TX2MenuBarGroup;
  groupBounds:      TRect;
  drawState:        TX2MenuBarDrawStates;

begin
  groupBounds := ABounds;

  for groupIndex := 0 to Pred(Groups.Count) do
  begin
    { Group header }
    group               := Groups[groupIndex];
    groupBounds.Bottom  := groupBounds.Top +
                           Painter.GetGroupHeaderHeight(group);

    if groupBounds.Bottom > ABounds.Bottom then
      break;

    drawState           := GetDrawState(group);
    Painter.DrawGroupHeader(ACanvas, group, groupBounds, drawState);
    groupBounds.Top     := groupBounds.Bottom;

    if Assigned(Animator) and (Animator.Group = group) then
    begin
      { Animated group }
      groupBounds.Bottom  := ABounds.Bottom;
      Inc(groupBounds.Top, Animator.Draw(ACanvas, groupBounds));
    end else
    begin
      { Items }
      if group.Expanded and (groupBounds.Top <= ABounds.Bottom) then
      begin
        groupBounds.Bottom  := ABounds.Bottom;
        Inc(groupBounds.Top, DrawMenuItems(ACanvas, group, groupBounds));
      end;
    end;
  end;

  Result  := groupBounds.Top - ABounds.Top;
end;

function TX2CustomMenuBar.DrawMenuItems(ACanvas: TCanvas;
                                        AGroup: TX2MenuBarGroup;
                                        const ABounds: TRect): Integer;
var
  itemIndex:        Integer;
  item:             TX2MenuBarItem;
  itemBounds:       TRect;
  drawState:        TX2MenuBarDrawStates;

begin
  itemBounds  := ABounds;

  for itemIndex := 0 to Pred(AGroup.Items.Count) do
  begin
    item              := AGroup.Items[itemIndex];
    itemBounds.Bottom := itemBounds.Top + Painter.GetItemHeight(item);

    if itemBounds.Bottom <= ABounds.Bottom then
    begin
      drawState         := GetDrawState(item);
      Painter.DrawItem(ACanvas, item, itemBounds, drawState);
    end;

    itemBounds.Top    := itemBounds.Bottom;
  end;

  Result  := itemBounds.Top - ABounds.Top;
end;

procedure TX2CustomMenuBar.DrawNoPainter(ACanvas: TCanvas; const ABounds: TRect);
const
  XorColor  = $00FFD8CE;  // RGB(206, 216, 255)

begin
  with ACanvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(ABounds);

    Pen.Style   := psDot;
    Pen.Mode    := pmXor;
    Pen.Color   := XorColor;
    Brush.Style := bsClear;
    Rectangle(ABounds);

    DrawText(ACanvas, SNoPainter, ABounds, taCenter);
  end;
end;


function TX2CustomMenuBar.ExpandedChanging(AGroup: TX2MenuBarGroup;
                                           AExpanding: Boolean): Boolean;
begin
  // #ToDo1 (MvR) 20-3-2006: raise event

  AnimateExpand(AGroup, AExpanding);

  Result := True;
end;

procedure TX2CustomMenuBar.ExpandedChanged(AGroup: TX2MenuBarGroup);
begin
  // #ToDo1 (MvR) 20-3-2006: raise event
end;


function TX2CustomMenuBar.AllowInteraction(): Boolean;
begin
  Result  := not Assigned(Animator);
end;


procedure TX2CustomMenuBar.AnimateExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean);
var
  itemsBuffer:    Graphics.TBitmap;
  itemsBounds:    TRect;

begin
  Assert(not Assigned(Animator), 'Already animating');
  if not Assigned(Painter) then
    exit;

  Painter.BeginPaint(Self);
  try
    itemsBuffer := Graphics.TBitmap.Create();
    try
      itemsBuffer.PixelFormat := pf24bit;
      itemsBuffer.Width       := Self.ClientWidth;
      itemsBuffer.Height      := Painter.GetGroupHeight(AGroup);
      itemsBounds             := Rect(0, 0, itemsBuffer.Width, itemsBuffer.Height);

      // #ToDo3 (MvR) 23-3-2006: this will probably cause problems if we ever
      //                         want a bitmapped/customdrawn background.
      //                         Maybe we can trick around a bit with the
      //                         canvas offset? think about it later.
      Painter.DrawBackground(itemsBuffer.Canvas, itemsBounds);
      DrawMenuItems(itemsBuffer.Canvas, AGroup, itemsBounds);

      Animator                := Painter.CreateAnimator(itemsBuffer);
      if Assigned(Animator) then
      begin
        Animator.Group          := AGroup;
        Animator.Expanding      := AExpanding;
      end;
    finally
      FreeAndNil(itemsBuffer);
    end;
  finally
    Painter.EndPaint();
    Invalidate();       
  end;

//      Painter.BeginPaint(Self);
//      try
//        groupBounds             := Painter.GetGroupBounds(AGroup, ClientRect);
//        menuBitmap.Width        := Self.ClientWidth;
//        menuBitmap.Height       := Self.ClientHeight;
//        Painter.DrawBackground(menuBitmap.Canvas, ClientRect);
//        DrawMenu(menuBitmap.Canvas, ClientRect);
//      finally
//        Painter.EndPaint();
//      end;
//
      { Pre-paint the parts which will be animated }
//      Animator.Top.Width      := Self.ClientWidth;
//      Animator.Top.Height     := groupBounds.Top;
//      Animator.Top.Canvas.Draw(0, 0, menuBitmap);
//
//      Animator.Group.Width    := Self.ClientWidth;
//      Animator.Group.Height   := groupBounds.Bottom - groupBounds.Top;
//      Animator.Group.Canvas.Draw(0, -groupBounds.Top, menuBitmap);
//
//      Animator.Bottom.Width   := Self.ClientWidth;
//      Animator.Bottom.Height  := Self.ClientHeight - groupBounds.Bottom;
//      Animator.Bottom.Canvas.Draw(0, -groupBounds.Bottom, menuBitmap);
//    finally
//      FreeAndNil(menuBitmap);
//    end;

//    Animator.Expanding  := AExpanding;
//    Animator.Max        := 250;
//    timeStart           := GetTickCount();
//    repeat
//      timeNow           := GetTickCount();
//      Animator.Position := timeNow - timeStart;
//
//      Invalidate();
//      Application.ProcessMessages();
//      // #ToDo1 (MvR) 20-3-2006: wait for paint cycle (event)?
//      Sleep(0);
//    until (timeNow > timeStart + 250) or (timeNow < timeStart);
//  finally
//    EndAnimate();
//  end;
end;


function TX2CustomMenuBar.HitTest(APoint: TPoint): TX2MenuBarHitTest;
var
  hitPoint:     TPoint;

begin
  Result.HitTestCode  := htUnknown;
  Result.Item         := nil;
  hitPoint            := APoint;

  { Sliding animations alter the position of the underlying groups }
  if Assigned(Animator) then
    hitPoint  := Animator.PrepareHitPoint(hitPoint);

  if PtInRect(Self.ClientRect, APoint) then
  begin
    Painter.BeginPaint(Self);
    try
      Result  := Painter.HitTest(hitPoint);
    finally
      Painter.EndPaint();
    end;
  end;
end;

function TX2CustomMenuBar.HitTest(AX, AY: Integer): TX2MenuBarHitTest;
begin
  Result  := HitTest(Point(AX, AY));
end;


procedure TX2CustomMenuBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
    if AComponent = FPainter then
    begin
      FPainter  := nil;
      Invalidate();
    end else if AComponent = FImageList then
    begin
      FImageList  := nil;
      Invalidate();
    end;

  inherited;
end;

procedure TX2CustomMenuBar.PainterUpdate(Sender: TX2MenuBarPainter);
begin
  Invalidate();
end;


procedure TX2CustomMenuBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                     X, Y: Integer);
var
  hitTest:      TX2MenuBarHitTest;
  group:        TX2MenuBarGroup;

begin
  if AllowInteraction then
  begin
    hitTest := Self.HitTest(X, Y);

    if hitTest.HitTestCode = htGroup then
    begin
      group := TX2MenuBarGroup(hitTest.Item);
      if group.Items.Count > 0 then
      begin
        hitTest.Item    := FSelectedItem;
        group.Expanded  := not group.Expanded;
        Invalidate();
      end;
    end;

    if hitTest.Item <> FSelectedItem then
    begin
      FSelectedItem := hitTest.Item;
      Invalidate();
    end;
  end;

  inherited;
end;

procedure TX2CustomMenuBar.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  FLastMousePos := Point(X, Y);
  TestMousePos();

  inherited;
end;

//procedure TX2CustomMenuBar.MouseUp(Button: TMouseButton; Shift: TShiftState;
//                                   X, Y: Integer);
//begin
//  inherited;
//end;

procedure TX2CustomMenuBar.CMMouseLeave(var Message: TMessage);
begin
  FLastMousePos := Point(-1, -1);
  FHotItem      := nil;
  Invalidate();
end;

procedure TX2CustomMenuBar.TestMousePos();
var
  hitTest:    TX2MenuBarHitTest;

begin
  hitTest := Self.HitTest(FLastMousePos.X, FLastMousePos.Y);
  if hitTest.Item <> FHotItem then
  begin
    FHotItem  := hitTest.Item;
    Invalidate();
  end;
end;


procedure TX2CustomMenuBar.SetBorderStyle(const Value: TBorderStyle);
begin
  if Value <> FBorderStyle then
  begin
    FBorderStyle := Value;
    RecreateWnd();
  end;
end;

procedure TX2CustomMenuBar.SetGroups(const Value: TX2MenuBarGroups);
begin
  if Value <> FGroups then
    FGroups.Assign(Value);
end;

procedure TX2CustomMenuBar.SetImageList(const Value: TCustomImageList);
begin
  if Value <> FImageList then
  begin
    if Assigned(FImageList) then
      FImageList.RemoveFreeNotification(Self);

    FImageList := Value;

    if Assigned(FImageList) then
      FImageList.FreeNotification(Self);
      
    Invalidate();
  end;
end;

procedure TX2CustomMenuBar.SetPainter(const Value: TX2MenuBarPainter);
begin
  if FPainter <> Value then
  begin
    if Assigned(FPainter) then
    begin
      FPainter.DetachObserver(Self);
      FPainter.RemoveFreeNotification(Self);
    end;

    FPainter  := Value;

    if Assigned(FPainter) then
    begin
      FPainter.FreeNotification(Self);
      FPainter.AttachObserver(Self);
    end;

    Invalidate;
  end;
end;

end.
