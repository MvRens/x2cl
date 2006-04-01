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
  Types,
  Windows;

type
  // #ToDo1 (MvR) 19-3-2006: implement collection Update mechanisms
  // #ToDo1 (MvR) 19-3-2006: OnCollapsing/OnCollapse/expand events
  // #ToDo1 (MvR) 19-3-2006: AutoCollapse property
  // #ToDo1 (MvR) 19-3-2006: AutoSelectItem property or something
  // #ToDo1 (MvR) 19-3-2006: find a way to remember the selected item per
  //                         group, required for when AutoCollapse = True and
  //                         AutoSelectItem = True
  // #ToDo1 (MvR) 25-3-2006: various Select methods for key support
  // #ToDo1 (MvR) 1-4-2006: scrollbar support
  // #ToDo1 (MvR) 1-4-2006: Enabled/Visible properties
  TX2CustomMenuBarAnimatorClass = class of TX2CustomMenuBarAnimator;
  TX2CustomMenuBarAnimator = class;
  TX2CustomMenuBarScrollerClass = class of TX2CustomMenuBarScroller;
  TX2CustomMenuBarScroller = class;
  TX2CustomMenuBarPainterClass = class of TX2CustomMenuBarPainter;
  TX2CustomMenuBarPainter = class;
  TX2CustomMenuBarItem = class;
  TX2MenuBarItem = class;
  TX2MenuBarGroup = class;
  TX2CustomMenuBar = class;

  IX2MenuBarPainterObserver = interface
    ['{22DE60C9-49A1-4E7D-B547-901BEDCC0FB7}']
    procedure PainterUpdate(Sender: TX2CustomMenuBarPainter);
  end;

  TX2MenuBarHitTest = record
    HitTestCode:    Integer;
    Item:           TX2CustomMenuBarItem;
  end;

  TX2MenuBarDrawState       = (mdsHot, mdsSelected, mdsGroupHot, mdsGroupSelected);
  TX2MenuBarDrawStates      = set of TX2MenuBarDrawState;

  TX2MenuBarAnimationStyle  = (asNone, asSlide, asDissolve);
  TX2MenuBarSpacingElement  = (seBeforeGroupHeader, seAfterGroupHeader,
                               seBeforeFirstItem, seAfterLastItem,
                               seBeforeItem, seAfterItem);

  TX2MenuBarItemBoundsProc  = procedure(Sender: TObject;
                                        Item: TX2CustomMenuBarItem;
                                        const MenuBounds: TRect;
                                        const ItemBounds: TRect;
                                        Data: Pointer;
                                        var Abort: Boolean) of object;

  {
    :$ Abstract animation class

    :: Descendants implement the animation-specific drawing code.
  }
  TX2CustomMenuBarAnimator = class(TObject)
  private
    FAnimationTime:     Cardinal;
    FExpanding:         Boolean;
    FGroup:             TX2MenuBarGroup;
    FStartTime:         Cardinal;
    FItemsBuffer:       Graphics.TBitmap;
    FTerminated:        Boolean;
  protected
    function GetTimeElapsed(): Cardinal; virtual;
    function GetHeight(): Integer; virtual;
    procedure SetExpanding(const Value: Boolean); virtual;

    procedure Terminate(); virtual;

    property ItemsBuffer:     Graphics.TBitmap  read FItemsBuffer;
    property TimeElapsed:     Cardinal          read GetTimeElapsed;
  public
    constructor Create(AItemsBuffer: Graphics.TBitmap); virtual;
    destructor Destroy(); override;

    procedure Update(); virtual;
    procedure Draw(ACanvas: TCanvas; const ABounds: TRect); virtual; abstract;

    property AnimationTime:   Cardinal                  read FAnimationTime   write FAnimationTime;
    property Expanding:       Boolean                   read FExpanding       write SetExpanding;
    property Group:           TX2MenuBarGroup           read FGroup           write FGroup;
    property Terminated:      Boolean                   read FTerminated;
    property Height:          Integer                   read GetHeight;
  end;

  {
    :$ Implements a sliding animation
  }
  TX2MenuBarSlideAnimator = class(TX2CustomMenuBarAnimator)
  private
    FSlideHeight:     Integer;
  protected
    function GetHeight(): Integer; override;
  public
    procedure Update(); override;
    procedure Draw(ACanvas: TCanvas; const ABounds: TRect); override;
  end;

  {
    :$ Implements a dissolve animation
  }
  TX2MenuBarDissolveAnimator = class(TX2CustomMenuBarAnimator)
  private
    FItemsState:      Graphics.TBitmap;
    FMask:            Graphics.TBitmap;
    FPixels:          TList;
  protected
    procedure SetExpanding(const Value: Boolean); override;

    property ItemsState:    Graphics.TBitmap  read FItemsState;
    property Mask:          Graphics.TBitmap  read FMask;
  public
    constructor Create(AItemsBuffer: Graphics.TBitmap); override;
    destructor Destroy(); override;

    procedure Update(); override;
    procedure Draw(ACanvas: TCanvas; const ABounds: TRect); override;
  end;

  {
    :$ Abstract scroller class.
  }
  TX2CustomMenuBarScroller = class(TPersistent)
  private
    FMenuBar:         TX2CustomMenuBar;
    FClientHeight:    Integer;
    FMenuHeight:      Integer;
    FOffset:          Integer;
  protected
    function ApplyMargins(const ABounds: TRect): TRect; virtual;

    property MenuBar:     TX2CustomMenuBar  read FMenuBar;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar); virtual;

    procedure Draw(ACanvas: TCanvas; const ABounds: TRect); virtual; abstract;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; overload; virtual;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    property ClientHeight:      Integer read FClientHeight  write FClientHeight;
    property MenuHeight:        Integer read FMenuHeight    write FMenuHeight;
    property Offset:            Integer read FOffset        write FOffset;
  end;

  {
    :$ Scrollbar class.
  }
  TScrollbarArrowDirection  = (adUp, adDown);

  TX2MenuBarScrollbarScroller = class(TX2CustomMenuBarScroller)
  private
    FScrollbarWidth:      Integer;
    FArrowHeight:         Integer;
  protected
    function ApplyMargins(const ABounds: TRect): TRect; override;

    procedure DrawArrowButton(ACanvas: TCanvas; const ABounds: TRect; ADirection: TScrollbarArrowDirection); virtual;
    procedure DrawBackground(ACanvas: TCanvas; const ABounds: TRect); virtual;
    procedure DrawThumb(ACanvas: TCanvas; const ABounds: TRect); virtual;

    property ScrollbarWidth:  Integer read FScrollbarWidth  write FScrollbarWidth;
    property ArrowHeight:     Integer read FArrowHeight     write FArrowHeight;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar); override;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; override;

    procedure Draw(ACanvas: TCanvas; const ABounds: TRect); override;
  end;

  {
    :$ Abstract painter class.

    :: Descendants must implement the actual drawing code.
  }
  TX2CustomMenuBarPainter = class(TComponent)
  private
    FAnimationStyle:  TX2MenuBarAnimationStyle;
    FAnimationTime:   Cardinal;
    FMenuBar:         TX2CustomMenuBar;
    FObservers:       TInterfaceList;

    function GetMenuBar(): TX2CustomMenuBar;
  protected
    procedure BeginPaint(const AMenuBar: TX2CustomMenuBar);
    procedure EndPaint();

    function ApplyMargins(const ABounds: TRect): TRect; virtual;
    function GetSpacing(AElement: TX2MenuBarSpacingElement): Integer; virtual;
    function GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer; virtual; abstract;
    function GetGroupHeight(AGroup: TX2MenuBarGroup): Integer; virtual;
    function GetItemHeight(AItem: TX2MenuBarItem): Integer; virtual; abstract;

    procedure DrawBackground(ACanvas: TCanvas; const ABounds: TRect); virtual; abstract;
    procedure DrawGroupHeader(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect; AState: TX2MenuBarDrawStates); virtual; abstract;
    procedure DrawItem(ACanvas: TCanvas; AItem: TX2MenuBarItem; const ABounds: TRect; AState: TX2MenuBarDrawStates); virtual; abstract;

    function GetAnimatorClass(): TX2CustomMenuBarAnimatorClass; virtual;
    function GetScrollerClass(): TX2CustomMenuBarScrollerClass; virtual;
    procedure FindHit(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds: TRect; const ItemBounds: TRect; Data: Pointer; var Abort: Boolean);

    procedure NotifyObservers();

    property MenuBar:           TX2CustomMenuBar          read GetMenuBar;
  protected
    property AnimationStyle:    TX2MenuBarAnimationStyle  read FAnimationStyle  write FAnimationStyle;
    property AnimationTime:     Cardinal                  read FAnimationTime   write FAnimationTime;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; overload; virtual;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    procedure AttachObserver(AObserver: IX2MenuBarPainterObserver);
    procedure DetachObserver(AObserver: IX2MenuBarPainterObserver);
  end;

  {
    :$ Base class for menu items and groups.
  }
  TX2CustomMenuBarItem = class(TCollectionItem)
  private
    FCaption:       String;
    FData:          TObject;
    FImageIndex:    TImageIndex;
    FOwnsData:      Boolean;
  protected
    function GetMenuBar(): TX2CustomMenuBar; virtual;
    procedure SetCaption(const Value: String); virtual;
    procedure SetData(const Value: TObject); virtual;
    procedure SetImageIndex(const Value: TImageIndex); virtual;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy(); override;

    procedure Assign(Source: TPersistent); override;

    property Data:          TObject           read FData        write SetData;
    property OwnsData:      Boolean           read FOwnsData    write FOwnsData;
    property MenuBar:       TX2CustomMenuBar  read GetMenuBar;
  published
    property Caption:       String            read FCaption     write SetCaption;
    property ImageIndex:    TImageIndex       read FImageIndex  write SetImageIndex;
  end;

  {
    :$ Contains a single menu item.
  }
  TX2MenuBarItem = class(TX2CustomMenuBarItem)
  private
    function GetGroup(): TX2MenuBarGroup;
  public
    property Group:         TX2MenuBarGroup   read GetGroup;
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
  TX2MenuBarGroup = class(TX2CustomMenuBarItem)
  private
    FExpanded:        Boolean;
    FItems:           TX2MenuBarItems;
    FSelectedItem:    Integer;

    function GetSelectedItem(): Integer;
    procedure SetExpanded(const Value: Boolean);
    procedure SetItems(const Value: TX2MenuBarItems);
  protected
    procedure InternalSetExpanded(const Value: Boolean);

    property SelectedItem:    Integer read GetSelectedItem  write FSelectedItem;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy(); override;

    procedure Assign(Source: TPersistent); override;
  published
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

  TX2MenuBarOption  = (mboAutoCollapse,       { Allow only a single group to be expanded }
                       mboAutoSelectItem,     { Always select an item when expanding a group }
                       mboAllowCollapseAll);  { Allow all groups to be collapsed }
  TX2MenuBarOptions = set of TX2MenuBarOption;

  {
    :$ Implements the menu bar.

    :: The menu bar is the visual container for the menu. It manages the groups
    :: and items, and implements the switching between menu items. It does not
    :: paint itself, instead it delegates this to it's linked Painter.
  }
  TX2CustomMenuBar = class(TCustomControl, IX2MenuBarPainterObserver)
  private
    FAnimator:          TX2CustomMenuBarAnimator;
    FBorderStyle:       TBorderStyle;
    FExpandingGroups:   TStringList;
    FGroups:            TX2MenuBarGroups;
    FHotItem:           TX2CustomMenuBarItem;
    FImageList:         TCustomImageList;
    FLastMousePos:      TPoint;
    FOptions:           TX2MenuBarOptions;
    FPainter:           TX2CustomMenuBarPainter;
    FSelectedItem:      TX2CustomMenuBarItem;
    FScroller:          TX2CustomMenuBarScroller;

    procedure SetAnimator(const Value: TX2CustomMenuBarAnimator);
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetGroups(const Value: TX2MenuBarGroups);
    procedure SetImageList(const Value: TCustomImageList);
    procedure SetOptions(const Value: TX2MenuBarOptions);
    procedure SetScroller(const Value: TX2CustomMenuBarScroller);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PainterUpdate(Sender: TX2CustomMenuBarPainter);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
//    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;

    procedure TestMousePos(); virtual;
    function GetMenuHeight(): Integer; virtual;
  protected
    procedure SetPainter(const Value: TX2CustomMenuBarPainter); virtual;

    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure Paint(); override;

    function GetDrawState(AItem: TX2CustomMenuBarItem): TX2MenuBarDrawStates;
    procedure DrawMenu(ACanvas: TCanvas); virtual;
    procedure DrawMenuItem(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds, ItemBounds: TRect; Data: Pointer; var Abort: Boolean); virtual;
    procedure DrawMenuItems(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect); virtual;
    procedure DrawNoPainter(ACanvas: TCanvas; const ABounds: TRect); virtual;

    function IterateItemBounds(ACallback: TX2MenuBarItemBoundsProc; AData: Pointer = nil): TX2CustomMenuBarItem;
    function AllowInteraction(): Boolean; virtual;

    procedure AutoCollapse(AGroup: TX2MenuBarGroup);
    procedure AutoSelectItem(AGroup: TX2MenuBarGroup);

    property Animator:    TX2CustomMenuBarAnimator  read FAnimator    write SetAnimator;
    property BorderStyle: TBorderStyle              read FBorderStyle write SetBorderStyle default bsNone;
    property Options:     TX2MenuBarOptions         read FOptions     write SetOptions;
    property Scroller:    TX2CustomMenuBarScroller  read FScroller    write SetScroller;
  protected
    procedure DoExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean);
    procedure DoExpandedChanging(AGroup: TX2MenuBarGroup; AExpanding: Boolean); virtual;
    procedure DoExpandedChanged(AGroup: TX2MenuBarGroup); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; overload;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    property Groups:      TX2MenuBarGroups        read FGroups      write SetGroups;
    property ImageList:   TCustomImageList        read FImageList   write SetImageList;
    property Painter:     TX2CustomMenuBarPainter read FPainter     write SetPainter;
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
    property Options;
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
  htScroller    = 4;

type
  PRGBAArray  = ^TRGBAArray;
  TRGBAArray  = array[Word] of TRGBQuad;


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


{ TX2CustomMenuBarPainter }
constructor TX2CustomMenuBarPainter.Create(AOwner: TComponent);
begin
  inherited;

  FAnimationStyle := DefaultAnimationStyle;
  FAnimationTime  := DefaultAnimationTime;

  if AOwner is TX2CustomMenuBar then
    FMenuBar  := TX2CustomMenuBar(AOwner);
end;

destructor TX2CustomMenuBarPainter.Destroy();
begin
  FreeAndNil(FObservers);
  inherited;
end;


procedure TX2CustomMenuBarPainter.AttachObserver(AObserver: IX2MenuBarPainterObserver);
begin
  if not Assigned(FObservers) then
    FObservers := TInterfaceList.Create();

  if FObservers.IndexOf(AObserver) = -1 then
    FObservers.Add(AObserver);
end;

procedure TX2CustomMenuBarPainter.DetachObserver(AObserver: IX2MenuBarPainterObserver);
begin
  if Assigned(FObservers) then
    FObservers.Remove(AObserver);
end;


procedure TX2CustomMenuBarPainter.BeginPaint(const AMenuBar: TX2CustomMenuBar);
begin
  Assert(not Assigned(FMenuBar), 'BeginPaint already called');
  FMenuBar  := AMenuBar;
end;

procedure TX2CustomMenuBarPainter.EndPaint();
begin
  Assert(Assigned(FMenuBar), 'EndPaint without BeginPaint');
  FMenuBar  := nil;
end;

procedure TX2CustomMenuBarPainter.NotifyObservers();
var
  observerIndex:    Integer;

begin
  if Assigned(FObservers) then
    for observerIndex := 0 to Pred(FObservers.Count) do
      (FObservers[observerIndex] as IX2MenuBarPainterObserver).PainterUpdate(Self);
end;


function TX2CustomMenuBarPainter.ApplyMargins(const ABounds: TRect): TRect;
begin
  Result  := ABounds;
end;

function TX2CustomMenuBarPainter.GetGroupHeight(AGroup: TX2MenuBarGroup): Integer;
var
  itemIndex:    Integer;

begin
  Result := 0;
  for itemIndex := 0 to Pred(AGroup.Items.Count) do
    Inc(Result, GetItemHeight(AGroup.Items[itemIndex]));
end;


function TX2CustomMenuBarPainter.GetAnimatorClass(): TX2CustomMenuBarAnimatorClass;
begin
  Result  := nil;

  case AnimationStyle of
    asSlide:    Result  := TX2MenuBarSlideAnimator;
    asDissolve: Result  := TX2MenuBarDissolveAnimator;
  end;
end;

function TX2CustomMenuBarPainter.GetScrollerClass: TX2CustomMenuBarScrollerClass;
begin
  Result  := TX2MenuBarScrollbarScroller;
end;


procedure TX2CustomMenuBarPainter.FindHit(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds, ItemBounds: TRect; Data: Pointer; var Abort: Boolean);
var
  hitPoint:     PPoint;

begin
  hitPoint  := Data;
  Abort     := PtInRect(ItemBounds, hitPoint^);
end;

function TX2CustomMenuBarPainter.HitTest(const APoint: TPoint): TX2MenuBarHitTest;
var
  hitPoint:     TPoint;

begin
  hitPoint            := APoint;
  Result.HitTestCode  := htUnknown;
  Result.Item         := MenuBar.IterateItemBounds(FindHit, @hitPoint);

  if Assigned(Result.Item) then
    if Result.Item is TX2MenuBarGroup then
      Result.HitTestCode  := htGroup
    else if Result.Item is TX2MenuBarItem then
      Result.HitTestCode  := htItem;
end;

function TX2CustomMenuBarPainter.HitTest(AX, AY: Integer): TX2MenuBarHitTest;
begin
  Result  := HitTest(Point(AX, AY));
end;


function TX2CustomMenuBarPainter.GetMenuBar(): TX2CustomMenuBar;
begin
  Assert(Assigned(FMenuBar), 'BeginPaint not called');
  Result  := FMenuBar;
end;

function TX2CustomMenuBarPainter.GetSpacing(AElement: TX2MenuBarSpacingElement): Integer;
begin
  Result  := 0;
end;


{ TX2CustomMenuBarAnimator }
constructor TX2CustomMenuBarAnimator.Create(AItemsBuffer: Graphics.TBitmap);
begin
  inherited Create();

  FStartTime    := GetTickCount();
  FItemsBuffer  := Graphics.TBitmap.Create();
  FItemsBuffer.Assign(AItemsBuffer);
end;

destructor TX2CustomMenuBarAnimator.Destroy();
begin
  FreeAndNil(FItemsBuffer);

  inherited;
end;


function TX2CustomMenuBarAnimator.GetHeight(): Integer;
begin
  Result  := ItemsBuffer.Height;
end;

function TX2CustomMenuBarAnimator.GetTimeElapsed(): Cardinal;
var
  currentTime:      Cardinal;

begin
  currentTime := GetTickCount();
  Result      := currentTime - FStartTime;

  if currentTime < FStartTime then
    Inc(Result, High(Cardinal));
end;

procedure TX2CustomMenuBarAnimator.SetExpanding(const Value: Boolean);
begin
  FExpanding  := Value;
end;


procedure TX2CustomMenuBarAnimator.Terminate();
begin
  FTerminated := True;
end;


procedure TX2CustomMenuBarAnimator.Update();
begin
end;


{ TX2MenuBarSlideAnimator }
function TX2MenuBarSlideAnimator.GetHeight(): Integer;
begin
  Result  := FSlideHeight;
end;

procedure TX2MenuBarSlideAnimator.Update();
var
  elapsed:      Cardinal;

begin
  elapsed         := TimeElapsed;
  FSlideHeight    := Trunc((elapsed / AnimationTime) * ItemsBuffer.Height);
  if not Expanding then
    FSlideHeight  := ItemsBuffer.Height - FSlideHeight;

  if FSlideHeight > ItemsBuffer.Height then
    FSlideHeight  := ItemsBuffer.Height
  else if FSlideHeight < 0 then
    FSlideHeight  := 0;

  if elapsed >= AnimationTime then
    Terminate();
end;

procedure TX2MenuBarSlideAnimator.Draw(ACanvas: TCanvas; const ABounds: TRect);
var
  sourceRect:   TRect;
  destRect:     TRect;

begin
  sourceRect        := Rect(0, 0, ItemsBuffer.Width, FSlideHeight);
  destRect          := ABounds;
  destRect.Bottom   := destRect.Top + FSlideHeight;

  ACanvas.CopyRect(destRect, ItemsBuffer.Canvas, sourceRect);
end;


{ TX2MenuBarDissolveAnimator }
constructor TX2MenuBarDissolveAnimator.Create(AItemsBuffer: Graphics.TBitmap);
var
  pixelIndex:   Integer;

begin
  inherited;

  { The bitmaps need to be 32-bits since we'll be accessing the scanlines as
    one big array, not by using Scanline on each row. In 24-bit mode, the
    scanlines are still aligned on a 32-bits boundary, thus causing problems. }
  ItemsBuffer.PixelFormat := pf32bit;

  FMask                   := Graphics.TBitmap.Create();
  FMask.PixelFormat       := pf32bit;
  FMask.Width             := AItemsBuffer.Width;
  FMask.Height            := AItemsBuffer.Height;

  FItemsState             := Graphics.TBitmap.Create();
  FItemsState.PixelFormat := pf32bit;
  FItemsState.Width       := AItemsBuffer.Width;
  FItemsState.Height      := AItemsBuffer.Height;

  { Prepare an array of pixel indices which will be used to pick random
    unique pixels in the Update method. }
  FPixels                 := TList.Create();
  FPixels.Count           := AItemsBuffer.Width * AItemsBuffer.Height;

  for pixelIndex := 0 to Pred(FPixels.Count) do
    FPixels[pixelIndex]   := Pointer(pixelIndex);

  if RandSeed = 0 then  
    Randomize();
end;

destructor TX2MenuBarDissolveAnimator.Destroy();
begin
  FreeAndNil(FItemsState);
  FreeAndNil(FMask); 

  inherited;
end;


procedure TX2MenuBarDissolveAnimator.Update();
  function GetScanlinePointer(ABitmap: Graphics.TBitmap): Pointer;
  var
    firstScanline:    Pointer;
    lastScanline:     Pointer;

  begin
    { Most bitmaps are bottom-up, so Scanline[0] actually returns the
      last physical row in memory. Check for this condition. Order of
      scanlines is not important for this effect. }
    firstScanline := ABitmap.ScanLine[0];
    lastScanline  := ABitmap.ScanLine[Pred(ABitmap.Height)];

    if Cardinal(firstScanline) > Cardinal(lastScanline) then
      Result  := lastScanline
    else
      Result  := firstScanline;
  end;

const
  RGBBlack:   TRGBQuad  = (rgbBlue:     0;
                           rgbGreen:    0;
                           rgbRed:      0;
                           rgbReserved: 0);

  RGBWhite:   TRGBQuad  = (rgbBlue:     255;
                           rgbGreen:    255;
                           rgbRed:      255;
                           rgbReserved: 0);

var
  totalPixelCount:    Integer;
  elapsed:            Cardinal;
  pixelsRemaining:    Integer;
  pixel:              Integer;
  pixelIndex:         Integer;
  pixelCount:         Integer;
  pixelPos:           Integer;
  statePixels:        PRGBAArray;
  maskPixels:         PRGBAArray;
  itemsPixels:        PRGBAArray;

begin
  // #ToDo1 (MvR) 1-4-2006: slow on big menu's, god knows why...
  
  totalPixelCount := ItemsBuffer.Width * ItemsBuffer.Height;
  elapsed         := TimeElapsed;
  pixelsRemaining := totalPixelCount - (Trunc((elapsed / AnimationTime) *
                                        totalPixelCount));

  if pixelsRemaining < 0 then
    pixelsRemaining := 0;

  statePixels     := GetScanlinePointer(ItemsState);
  maskPixels      := GetScanlinePointer(Mask);
  itemsPixels     := nil;

  if Expanding then
    itemsPixels   := GetScanlinePointer(ItemsBuffer);

  for pixel := 0 to Pred(FPixels.Count - pixelsRemaining) do
  begin
    pixelCount  := FPixels.Count;
    pixelIndex  := Random(pixelCount);

    if pixelIndex > Pred(pixelCount) then
      pixelIndex  := Pred(pixelCount);

    pixelPos    := Integer(FPixels[pixelIndex]);
    FPixels.Delete(pixelIndex);

    if Expanding then
    begin
      { Make the pixel visible }
      statePixels^[pixelPos]  := itemsPixels^[pixelPos];
      maskPixels^[pixelPos]   := RGBBlack;
    end else
    begin
      { Make the pixel invisible }
      statePixels^[pixelPos]  := RGBBlack;
      maskPixels^[pixelPos]   := RGBWhite;
    end;
  end;

  if elapsed >= AnimationTime then
    Terminate();
end;

procedure TX2MenuBarDissolveAnimator.Draw(ACanvas: TCanvas; const ABounds: TRect);
var
  boundsRegion: THandle;
  oldCopyMode: TCopyMode;

begin
  boundsRegion  := CreateRectRgn(ABounds.Left, ABounds.Top, ABounds.Right,
                                 ABounds.Bottom);
  oldCopyMode   := ACanvas.CopyMode;
  try
    SelectClipRgn(ACanvas.Handle, boundsRegion);
    ACanvas.CopyMode  := cmSrcAnd;
    ACanvas.Draw(ABounds.Left, ABounds.Top, Mask);

    ACanvas.CopyMode  := cmSrcPaint;
    ACanvas.Draw(ABounds.Left, ABounds.Top, ItemsState);
  finally
    SelectClipRgn(ACanvas.Handle, 0);
    ACanvas.CopyMode  := oldCopyMode;
  end;
end;


procedure TX2MenuBarDissolveAnimator.SetExpanding(const Value: Boolean);
begin
  if Value then
  begin
    { Start with an invisible group }
    FMask.Canvas.Brush.Color  := clWhite;

    with FItemsState.Canvas do
    begin
      Brush.Color := clBlack;
      FillRect(Rect(0, 0, FItemsState.Width, FItemsState.Height));
    end;
  end else
  begin
    { Start with a visible group }
    FMask.Canvas.Brush.Color  := clBlack;
    FItemsState.Canvas.Draw(0, 0, ItemsBuffer);
  end;

  FMask.Canvas.FillRect(Rect(0, 0, FMask.Width, FMask.Height));

  inherited;
end;


{ TX2CustomMenuBarScroller }
constructor TX2CustomMenuBarScroller.Create(AMenuBar: TX2CustomMenuBar);
begin
  inherited Create();

  FMenuBar  := AMenuBar;
end;

function TX2CustomMenuBarScroller.ApplyMargins(const ABounds: TRect): TRect;
begin
  Result  := ABounds;
end;

function TX2CustomMenuBarScroller.HitTest(const APoint: TPoint): TX2MenuBarHitTest;
begin
  Result.HitTestCode  := htUnknown;
  Result.Item         := nil;
end;

function TX2CustomMenuBarScroller.HitTest(AX, AY: Integer): TX2MenuBarHitTest;
begin
  Result  := HitTest(Point(AX, AY));
end;


{ TX2MenuBarScrollbarScroller }
constructor TX2MenuBarScrollbarScroller.Create(AMenuBar: TX2CustomMenuBar);
begin
  inherited;

  FScrollbarWidth := GetSystemMetrics(SM_CXVSCROLL);
  FArrowHeight    := GetSystemMetrics(SM_CYVSCROLL);
end;

function TX2MenuBarScrollbarScroller.ApplyMargins(const ABounds: TRect): TRect;
begin
  Result  := inherited ApplyMargins(ABounds);
  Dec(Result.Right, FScrollbarWidth + 5);
end;


procedure TX2MenuBarScrollbarScroller.DrawArrowButton(ACanvas: TCanvas;
                                                      const ABounds: TRect;
                                                      ADirection: TScrollbarArrowDirection);
var
  flags:    Cardinal;

begin
  flags := 0{DFCS_INACTIVE};
  case ADirection of
    adUp:     flags := flags or DFCS_SCROLLUP;
    adDown:   flags := flags or DFCS_SCROLLDOWN;
  end;

  // #ToDo1 (MvR) 1-4-2006: XP theme support
  DrawFrameControl(ACanvas.Handle, ABounds, DFC_SCROLL, flags);
end;

procedure TX2MenuBarScrollbarScroller.DrawBackground(ACanvas: TCanvas;
                                                     const ABounds: TRect);
  function GetForegroundColor(): Cardinal;
  var
    color1:   Cardinal;
    color2:   Cardinal;

  begin
    color1  := GetSysColor(COLOR_3DHILIGHT);
    color2  := GetSysColor(COLOR_WINDOW);

    if (color1 <> $ffffff) and (color1 = color2) then
  		Result  := GetSysColor(COLOR_BTNFACE)
    else
  		Result  := GetSysColor(COLOR_3DHILIGHT);
  end;

  function GetBackgroundColor(): Cardinal;
  begin
    Result  := GetSysColor(COLOR_SCROLLBAR);
  end;

const
  CheckPattern:   array[0..7] of Word =
                  ($aaaa, $5555, $aaaa, $5555, $aaaa, $5555, $aaaa, $5555);

var
  patternBitmap:  Graphics.TBitmap;

begin
  patternBitmap := Graphics.TBitmap.Create();
  try
    patternBitmap.Handle  := CreateBitmap(8, 8, 1, 1, @CheckPattern);
    ACanvas.Brush.Bitmap  := patternBitmap;

    SetTextColor(ACanvas.Handle, GetForegroundColor());
    SetBkColor(ACanvas.Handle, GetBackgroundColor());
    ACanvas.FillRect(ABounds);
  finally
    ACanvas.Brush.Bitmap  := nil;
    FreeAndNil(patternBitmap);
  end;
end;

procedure TX2MenuBarScrollbarScroller.DrawThumb(ACanvas: TCanvas;
                                                const ABounds: TRect);
var
  bounds:     TRect;

begin
  ACanvas.Brush.Color := clBtnFace;
  ACanvas.FillRect(ABounds);

  bounds  := ABounds;
  DrawEdge(ACanvas.Handle, bounds, EDGE_RAISED, BF_RECT);
end;

function TX2MenuBarScrollbarScroller.HitTest(const APoint: TPoint): TX2MenuBarHitTest;
var
  bounds:     TRect;

begin
  Result.HitTestCode  := htUnknown;
  Result.Item         := nil;
  
  bounds              := MenuBar.ClientRect;
  bounds.Left         := bounds.Right - ScrollbarWidth;

  if PtInRect(APoint) then
  begin
    Result.HitTestCode  := htScroller;
    Result.Item         := Self;
  end;
end;

procedure TX2MenuBarScrollbarScroller.Draw(ACanvas: TCanvas;
                                           const ABounds: TRect);
const
  MinThumbHeight  = 8;

var
  bounds:         TRect;
  trackBounds:    TRect;
  scrollHeight:   Integer;
  visiblePart:    Double;
  thumbHeight:    Integer;
  scrollArea:     Integer;

begin
  bounds        := ABounds;
  bounds.Left   := bounds.Right - ScrollbarWidth;

  if (bounds.Bottom - bounds.Top) <= (2 * ArrowHeight) then
  begin
    { Top thumb }
    bounds.Bottom := bounds.Top + ((bounds.Bottom - bounds.Top) div 2);
    DrawArrowButton(ACanvas, bounds, adUp);

    { Bottom thumb }
    bounds.Top    := bounds.Bottom;
    bounds.Bottom := ABounds.Bottom;
    DrawArrowButton(ACanvas, bounds, adDown);
  end
  else
  begin
    { Top thumb }
    bounds.Bottom := bounds.Top + ArrowHeight;
    DrawArrowButton(ACanvas, bounds, adUp);

    { Bottom thumb }
    bounds.Bottom := ABounds.Bottom;
    bounds.Top    := bounds.Bottom - ArrowHeight;
    DrawArrowButton(ACanvas, bounds, adDown);

    { Track bar }
    bounds.Bottom := bounds.Top;
    bounds.Top    := ABounds.Top + ArrowHeight;
    DrawBackground(ACanvas, bounds);
    trackBounds   := bounds;

    { Thumb }
    scrollHeight  := MenuHeight - ClientHeight;
    if scrollHeight > 0 then
    begin
      visiblePart   := ClientHeight / MenuHeight;
      thumbHeight   := Trunc((bounds.Bottom - bounds.Top) * visiblePart);
      scrollArea    := (trackBounds.Bottom - trackBounds.Top) - thumbHeight;

      Inc(bounds.Top, Trunc((Offset / scrollHeight) * scrollArea));
      bounds.Bottom := bounds.Top + thumbHeight;

      if bounds.Bottom - bounds.Top < MinThumbHeight then
        bounds.Bottom := bounds.Top + MinThumbHeight;

      if bounds.Bottom > trackBounds.Bottom then
        bounds.Bottom := trackBounds.Bottom;      

      DrawThumb(ACanvas, bounds);
    end;
  end;
end;


{ TX2CustomMenuBarItem }
constructor TX2CustomMenuBarItem.Create(Collection: TCollection);
begin
  inherited;

  FCaption    := SDefaultItemCaption;
  FImageIndex := -1;
  FOwnsData   := True;
end;

destructor TX2CustomMenuBarItem.Destroy();
begin
  Data  := nil;

  inherited;
end;


function TX2CustomMenuBarItem.GetMenuBar(): TX2CustomMenuBar;
var
  parentCollection: TCollection;
  parentOwner: TPersistent;
   
begin
  Result            := nil;
  parentCollection  := Collection;

  { Traverse up the tree of CollectionItems and OwnedCollections until
    we find a MenuBar... or not. }
  while Assigned(parentCollection) do
  begin
    parentOwner := parentCollection.Owner;
    if Assigned(parentOwner) then
    begin
      if parentOwner is TX2CustomMenuBar then
      begin
        Result  := TX2CustomMenuBar(parentCollection.Owner);
        break;
      end else if parentOwner is TCollectionItem then
        parentCollection  := TCollectionItem(parentOwner).Collection;
    end else
      break;
  end;
end;

procedure TX2CustomMenuBarItem.Assign(Source: TPersistent);
begin
  if Source is TX2CustomMenuBarItem then
    with TX2CustomMenuBarItem(Source) do
    begin
      Self.Caption  := Caption;
      Self.Data     := Data;
      Self.OwnsData := OwnsData;
    end
  else
    inherited;
end;


procedure TX2CustomMenuBarItem.SetCaption(const Value: String);
begin
  if Value <> FCaption then
  begin
    FCaption := Value;
    Changed(False);
  end;
end;

procedure TX2CustomMenuBarItem.SetData(const Value: TObject);
begin
  if Value <> FData then
  begin
    if FOwnsData then
      FreeAndNil(FData);

    FData := Value;
  end;
end;

procedure TX2CustomMenuBarItem.SetImageIndex(const Value: TImageIndex);
begin
  if Value <> FImageIndex then
  begin
    FImageIndex := Value;
    Changed(False);
  end;
end;


{ TX2MenuBarItem }
function TX2MenuBarItem.GetGroup(): TX2MenuBarGroup;
begin
  Result  := nil;

  if Assigned(Collection) and (Collection.Owner <> nil) and
     (Collection.Owner is TX2MenuBarGroup) then
    Result  := TX2MenuBarGroup(Collection.Owner);
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
      Self.Items.Assign(Items);

  inherited;
end;


function TX2MenuBarGroup.GetSelectedItem(): Integer;
begin
  Result := -1;
  
  if Items.Count > 0 then
  begin
    if (FSelectedItem >= 0) and (FSelectedItem < Items.Count) then
      Result  := FSelectedItem
    else
      Result  := 0;
  end;
end;

procedure TX2MenuBarGroup.InternalSetExpanded(const Value: Boolean);
var
  menu:     TX2CustomMenuBar;

begin
  FExpanded := Value;
  Changed(False);

  menu  := MenuBar;
  if Assigned(menu) then
    menu.DoExpandedChanged(Self);
end;

procedure TX2MenuBarGroup.SetExpanded(const Value: Boolean);
var
  menu:     TX2CustomMenuBar;

begin
  if Value <> FExpanded then
  begin
    menu  := MenuBar;
    if Assigned(menu) then
      menu.DoExpandedChanging(Self, Value)
    else
      InternalSetExpanded(Value);
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

  FBorderStyle      := bsNone;
  FGroups           := TX2MenuBarGroups.Create(Self);
  FOptions          := [mboAllowCollapseAll];
  FExpandingGroups  := TStringList.Create();
end;

procedure TX2CustomMenuBar.CreateParams(var Params: TCreateParams);
const
  BorderStyles:   array[TBorderStyle] of DWORD = (0, WS_BORDER);

begin
  inherited;

  { Source: TScrollBox.CreateParams
      Applies the BorderStyle property. }
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
  Animator  := nil;
  Scroller  := nil;

  FreeAndNil(FExpandingGroups);
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
  bufferRect:       TRect;
  expand:           Boolean;
  group:            TX2MenuBarGroup;
  scrollerClass:    TX2CustomMenuBarScrollerClass;
  menuHeight:       Integer;

begin
  if Assigned(Painter) then
  begin
    buffer  := Graphics.TBitmap.Create();
    try
      buffer.PixelFormat  := pf32bit;
      buffer.Width        := Self.ClientWidth;
      buffer.Height       := Self.ClientHeight;
      bufferRect          := Rect(0, 0, buffer.Width, buffer.Height);
      buffer.Canvas.Font.Assign(Self.Font);

      if Assigned(Animator) then
        Animator.Update();

      menuHeight          := GetMenuHeight();

      { Don't change the scroller's visibility while animating }
      if not Assigned(Animator) then
      begin
        if menuHeight > bufferRect.Bottom then
        begin
          if not Assigned(Scroller) then
          begin
            scrollerClass := Painter.GetScrollerClass();
            if Assigned(scrollerClass) then
              Scroller  := scrollerClass.Create(Self);
          end;
        end else
          if Assigned(Scroller) then
            Scroller  := nil;
      end;

      Painter.BeginPaint(Self);
      try
        Painter.DrawBackground(buffer.Canvas, bufferRect);
        DrawMenu(buffer.Canvas);

        if Assigned(Scroller) then
        begin
          Scroller.ClientHeight := Self.ClientHeight;
          Scroller.MenuHeight   := menuHeight;
          Scroller.Draw(buffer.Canvas, bufferRect);
        end;
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
      begin
        Animator.Group.InternalSetExpanded(Animator.Expanding);
        Animator  := nil;
      end
      else
        { Prevent 100% CPU usage }
        Sleep(5);

      TestMousePos();
      Invalidate();
    end
    else
      { Process animation queue }
      if FExpandingGroups.Count > 0 then
      begin
        expand  := (FExpandingGroups[0] = #1);
        group   := TX2MenuBarGroup(FExpandingGroups.Objects[0]);
        FExpandingGroups.Delete(0);

        group.Expanded  := expand;
      end;
  end
  else
    DrawNoPainter(Self.Canvas, Self.ClientRect);
end;


function TX2CustomMenuBar.GetDrawState(AItem: TX2CustomMenuBarItem): TX2MenuBarDrawStates;
  function ItemGroup(AGroupItem: TX2CustomMenuBarItem): TX2MenuBarGroup;
  begin
    Result  := nil;
    if AGroupItem is TX2MenuBarItem then
      Result  := TX2MenuBarItem(AGroupItem).Group;
  end;

begin
  Result  := [];

  if AItem = FHotItem then
    Include(Result, mdsHot);

  if AItem = FSelectedItem then
    Include(Result, mdsSelected);

  if Assigned(FHotItem) and (AItem = ItemGroup(FHotItem)) then
    Include(Result, mdsGroupHot);

  if Assigned(FSelectedItem) and (AItem = ItemGroup(FSelectedItem)) then
      Include(Result, mdsGroupSelected);
end;

procedure TX2CustomMenuBar.DrawMenuItem(Sender: TObject;
                                        Item: TX2CustomMenuBarItem;
                                        const MenuBounds, ItemBounds: TRect;
                                        Data: Pointer; var Abort: Boolean);
var
  canvas:       TCanvas;
  drawState:    TX2MenuBarDrawStates;
  group:        TX2MenuBarGroup;
  groupBounds:  TRect;

begin
  if ItemBounds.Top > MenuBounds.Bottom then
  begin
    Abort := True;
    exit;
  end;

  canvas    := TCanvas(Data);
  drawState := GetDrawState(Item);

  if Item is TX2MenuBarGroup then
  begin
    group := TX2MenuBarGroup(Item);
    Painter.DrawGroupHeader(canvas, group, ItemBounds,
                            drawState);

    if Assigned(Animator) and (Animator.Group = group) then
    begin
      groupBounds         := MenuBounds;
      groupBounds.Top     := ItemBounds.Bottom +
                             Painter.GetSpacing(seAfterGroupHeader) +
                             Painter.GetSpacing(seBeforeFirstItem);
      groupBounds.Bottom  := groupBounds.Top + Animator.Height;
      Animator.Draw(canvas, groupBounds);
    end;
  end else if Item is TX2MenuBarItem then
    Painter.DrawItem(canvas, TX2MenuBarItem(Item), ItemBounds, drawState);
end;

procedure TX2CustomMenuBar.DrawMenuItems(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect);
var
  itemBounds:       TRect;
  itemIndex:        Integer;
  item:             TX2MenuBarItem;
  drawState:        TX2MenuBarDrawStates;

begin
  Assert(Assigned(Painter), 'No Painter assigned');
  itemBounds  := ABounds;
  Inc(itemBounds.Top, Painter.GetSpacing(seBeforeFirstItem));

  for itemIndex := 0 to Pred(AGroup.Items.Count) do
  begin
    Inc(itemBounds.Top, Painter.GetSpacing(seBeforeItem));

    item              := AGroup.Items[itemIndex];
    itemBounds.Bottom := itemBounds.Top + Painter.GetItemHeight(item);

    drawState         := GetDrawState(item);
    Painter.DrawItem(ACanvas, item, itemBounds, drawState);

    itemBounds.Top    := itemBounds.Bottom + Painter.GetSpacing(seAfterItem);
  end;
end;

procedure TX2CustomMenuBar.DrawMenu(ACanvas: TCanvas);
begin
  IterateItemBounds(DrawMenuItem, Pointer(ACanvas));
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


function TX2CustomMenuBar.IterateItemBounds(ACallback: TX2MenuBarItemBoundsProc;
                                            AData: Pointer): TX2CustomMenuBarItem;
var
  groupIndex:       Integer;
  group:            TX2MenuBarGroup;
  menuBounds:       TRect;
  itemBounds:       TRect;
  itemIndex:        Integer;
  item:             TX2MenuBarItem;
  abort:            Boolean;

begin
  Assert(Assigned(Painter), 'No Painter assigned');
  
  Result      := nil;
  menuBounds  := Painter.ApplyMargins(Self.ClientRect);
  if Assigned(Scroller) then
    menuBounds  := Scroller.ApplyMargins(menuBounds);

  itemBounds  := menuBounds;
  abort       := False;

  for groupIndex := 0 to Pred(Groups.Count) do
  begin
    { Group }
    group               := Groups[groupIndex];
    Inc(itemBounds.Top, Painter.GetSpacing(seBeforeGroupHeader));
    itemBounds.Bottom   := itemBounds.Top +
                           Painter.GetGroupHeaderHeight(group);

    ACallback(Self, group, menuBounds, itemBounds, AData, abort);
    if abort then
    begin
      Result  := group;
      break;
    end;

    itemBounds.Top      := itemBounds.Bottom +
                           Painter.GetSpacing(seAfterGroupHeader);

    if Assigned(Animator) and (Animator.Group = group) then
    begin
      { Animated group }
      Inc(itemBounds.Top, Animator.Height);
    end else if group.Expanded then
    begin
      Inc(itemBounds.Top, Painter.GetSpacing(seBeforeFirstItem));

      for itemIndex := 0 to Pred(group.Items.Count) do
      begin
        { Item }
        item              := group.Items[itemIndex];
        Inc(itemBounds.Top, Painter.GetSpacing(seBeforeItem));
        itemBounds.Bottom := itemBounds.Top + Painter.GetItemHeight(item);

        ACallback(Self, item, menuBounds, itemBounds, AData, abort);
        if abort then
        begin
          Result  := item;
          break;
        end;

        itemBounds.Top    := itemBounds.Bottom +
                             Painter.GetSpacing(seAfterItem);
      end;

      Inc(itemBounds.Top, Painter.GetSpacing(seAfterLastItem));
    end;

    if abort then
      break;
  end;
end;


procedure TX2CustomMenuBar.DoExpandedChanging(AGroup: TX2MenuBarGroup;
                                              AExpanding: Boolean);
  function ExpandedGroupsCount(): Integer;
  var
    groupIndex:     Integer;

  begin
    Result  := 0;
    for groupIndex := 0 to Pred(Groups.Count) do
      if Groups[groupIndex].Expanded then
        Inc(Result);
  end;

begin
  if csLoading in ComponentState then
  begin
    AGroup.InternalSetExpanded(AExpanding);
    exit;
  end;

  { Auto select item }
  if mboAutoSelectItem in Options then
    AutoSelectItem(AGroup);

  { Allow collapse all }
  if not (AExpanding or (mboAllowCollapseAll in Options)) then
    if ExpandedGroupsCount() = 1 then
      exit;

  { Auto collapse }
  if mboAutoCollapse in Options then
    if AExpanding then
      AutoCollapse(AGroup);

  DoExpand(AGroup, AExpanding);
end;

procedure TX2CustomMenuBar.DoExpandedChanged(AGroup: TX2MenuBarGroup);
begin
  // #ToDo1 (MvR) 27-3-2006: raise event
end;


function TX2CustomMenuBar.AllowInteraction(): Boolean;
begin
  Result  := not Assigned(Animator);
end;


procedure TX2CustomMenuBar.DoExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean);
var
  animatorClass:  TX2CustomMenuBarAnimatorClass;
  itemsBuffer:    Graphics.TBitmap;
  itemsBounds:    TRect;

begin
  if not Assigned(Painter) then
    exit;

  if Assigned(Animator) then
  begin
    FExpandingGroups.AddObject(Chr(Ord(AExpanding)), AGroup);
  end else
  begin
    animatorClass := Painter.GetAnimatorClass();
    if Assigned(animatorClass) then
    begin
      Painter.BeginPaint(Self);
      try
        itemsBuffer := Graphics.TBitmap.Create();
        try
          itemsBounds             := Painter.ApplyMargins(Self.ClientRect);
          if Assigned(Scroller) then
            itemsBounds           := Scroller.ApplyMargins(itemsBounds);

          itemsBuffer.PixelFormat := pf32bit;
          itemsBuffer.Width       := itemsBounds.Right - itemsBounds.Left;
          itemsBuffer.Height      := Painter.GetGroupHeight(AGroup);
          itemsBounds             := Rect(0, 0, itemsBuffer.Width, itemsBuffer.Height);
          itemsBuffer.Canvas.Font.Assign(Self.Font);

          // #ToDo3 (MvR) 23-3-2006: this will probably cause problems if we ever
          //                         want a bitmapped/customdrawn background.
          //                         Maybe we can trick around a bit with the
          //                         canvas offset? think about it later.
          Painter.DrawBackground(itemsBuffer.Canvas, itemsBounds);
          DrawMenuItems(itemsBuffer.Canvas, AGroup, itemsBounds);

          Animator                := animatorClass.Create(itemsBuffer);
          Animator.AnimationTime  := Painter.AnimationTime;
          Animator.Expanding      := AExpanding;
          Animator.Group          := AGroup;
        finally
          FreeAndNil(itemsBuffer);
        end;
      finally
        Painter.EndPaint();
        Invalidate();
      end;
    end else
      AGroup.InternalSetExpanded(AExpanding);
  end;
end;

procedure TX2CustomMenuBar.AutoCollapse(AGroup: TX2MenuBarGroup);
var
  expandedGroup:      TX2MenuBarGroup;
  groupIndex:         Integer;
  group:              TX2MenuBarGroup;

begin
  expandedGroup := AGroup;
  if not Assigned(expandedGroup) then
  begin
    for groupIndex := 0 to Pred(Groups.Count) do
      if Groups[groupIndex].Expanded then
      begin
        expandedGroup := Groups[groupIndex];
        break;
      end;

    if not Assigned(expandedGroup) then
      if Groups.Count > 0 then
      begin
        expandedGroup           := Groups[0];
        expandedGroup.Expanded  := True;
      end else
        exit;
  end;

  for groupIndex := 0 to Pred(Groups.Count) do
  begin
    group := Groups[groupIndex];

    if (group <> expandedGroup) and (group.Expanded) then
      DoExpand(group, False);
  end;
end;

procedure TX2CustomMenuBar.AutoSelectItem(AGroup: TX2MenuBarGroup);
var
  group:      TX2MenuBarGroup;
  groupIndex: Integer;

begin
  group := AGroup;
  if not Assigned(group) then
  begin
    for groupIndex := 0 to Pred(Groups.Count) do
      if Groups[groupIndex].Expanded then
      begin
        group := Groups[groupIndex];
        break;
      end;

    if (not Assigned(group)) and (Groups.Count > 0) then
    begin
      group           := Groups[0];
      group.Expanded  := True;
    end;

    if not Assigned(group) then
      exit;
  end;

  if group.Items.Count > 0 then
  begin
    FSelectedItem := group.Items[group.SelectedItem];
    Invalidate();
  end;
end;


function TX2CustomMenuBar.HitTest(const APoint: TPoint): TX2MenuBarHitTest;
var
  hitPoint:     TPoint;

begin
  Result.HitTestCode  := htUnknown;
  Result.Item         := nil;
  hitPoint            := APoint;

  if PtInRect(Self.ClientRect, APoint) then
  begin
    Painter.BeginPaint(Self);
    try
      Result  := Painter.HitTest(hitPoint);
    finally
      Painter.EndPaint();
    end;

    if (Result.HitTestCode = htUnknown) and Assigned(Scroller) then
      Result  := Scroller.HitTest(APoint);
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

procedure TX2CustomMenuBar.PainterUpdate(Sender: TX2CustomMenuBarPainter);
begin
  Invalidate();
end;


procedure TX2CustomMenuBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                     X, Y: Integer);
var
  hitTest:      TX2MenuBarHitTest;
  group:        TX2MenuBarGroup;

begin
  if Button = mbLeft then
    if AllowInteraction then
    begin
      hitTest := Self.HitTest(X, Y);

      if hitTest.HitTestCode = htGroup then
      begin
        group := TX2MenuBarGroup(hitTest.Item);
        if group.Items.Count > 0 then
        begin
          group.Expanded  := not group.Expanded;
          hitTest.Item    := FSelectedItem;
          Invalidate();
        end;
      end;

      if hitTest.HitTestCode = htScroller then
        Scroller.MouseDown(Button, Shift, X, Y)
      else
        Scroller.MouseLeave();

      if Assigned(hitTest.Item) and (hitTest.Item <> FSelectedItem) then
      begin
        if hitTest.HitTestCode = htItem then
          TX2MenuBarItem(hitTest.Item).Group.SelectedItem := hitTest.Item.Index;

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

function TX2CustomMenuBar.GetMenuHeight(): Integer;
var
  groupIndex:       Integer;
  group:            TX2MenuBarGroup;
  menuBounds:       TRect;
  itemIndex:        Integer;
  item:             TX2MenuBarItem;

begin
  Assert(Assigned(Painter), 'No Painter assigned');

  menuBounds  := Painter.ApplyMargins(Self.ClientRect);
  Result      := Self.ClientHeight - (menuBounds.Bottom - menuBounds.Top);

  for groupIndex := 0 to Pred(Groups.Count) do
  begin
    { Group }
    group := Groups[groupIndex];
    Inc(Result, Painter.GetSpacing(seBeforeGroupHeader) +
                Painter.GetGroupHeaderHeight(group) +
                Painter.GetSpacing(seAfterGroupHeader));

    if Assigned(Animator) and (Animator.Group = group) then
    begin
      { Animated group }
      Inc(Result, Animator.Height);
    end else if group.Expanded then
    begin
      Inc(Result, Painter.GetSpacing(seBeforeFirstItem));

      for itemIndex := 0 to Pred(group.Items.Count) do
      begin
        { Item }
        item  := group.Items[itemIndex];
        Inc(Result, Painter.GetSpacing(seBeforeItem) +
                    Painter.GetItemHeight(item) +
                    Painter.GetSpacing(seAfterItem));
      end;

      Inc(Result, Painter.GetSpacing(seAfterLastItem));
    end;
  end;
end;


procedure TX2CustomMenuBar.SetAnimator(const Value: TX2CustomMenuBarAnimator);
begin
  if Value <> FAnimator then
  begin
    FreeAndNil(FAnimator);
    FAnimator := Value;
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

procedure TX2CustomMenuBar.SetOptions(const Value: TX2MenuBarOptions);
begin
  if Value <> FOptions then
  begin
    FOptions := Value;
    Invalidate();

    if mboAutoCollapse in Options then
      AutoCollapse(nil);

    if (mboAutoSelectItem in Options) and (not Assigned(FSelectedItem)) then
      AutoSelectItem(nil);
  end;
end;

procedure TX2CustomMenuBar.SetScroller(const Value: TX2CustomMenuBarScroller);
begin
  if Value <> FScroller then
  begin
    FreeAndNil(FScroller); 
    FScroller := Value;
  end;
end;

procedure TX2CustomMenuBar.SetPainter(const Value: TX2CustomMenuBarPainter);
begin
  if FPainter <> Value then
  begin
    if Assigned(FPainter) then
    begin
      FPainter.DetachObserver(Self);
      FPainter.RemoveFreeNotification(Self);
    end;

    Animator  := nil;
    Scroller  := nil;
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

