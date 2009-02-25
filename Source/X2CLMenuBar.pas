{
  :: X2CLMenuBar is a generic group/items menu. Through the various painters,
  :: it can resemble styles such as the musikCube or BBox/Uname-IT menu bars.
  ::
  :: Part of the X2Software Component Library
  ::    http://www.x2software.net/
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLMenuBar;

interface
uses
  ActnList,
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
  TX2MenuBarAnimationStyle    = (asNone, asSlide, asDissolve, asFade,
                                 asSlideFade);

  TX2MenuBarDirection         = (mbdUp, mbdDown);

const
  DefaultAnimationStyle = asSlide;
  DefaultAnimationTime  = 250;

type
  {$IFNDEF VER180}
  // #ToDo1 (MvR) 24-5-2006: check how D2006 defines these
  TVerticalAlignment = (taTop, taBottom, taVerticalCenter);
  {$ENDIF}

  // #ToDo1 (MvR) 25-3-2006: various Select methods for key support
  // #ToDo1 (MvR) 1-4-2006: scroll wheel support
  TX2CustomMenuBarAnimatorClass = class of TX2CustomMenuBarAnimator;
  TX2CustomMenuBarAnimator = class;
  TX2CustomMenuBarPainterClass = class of TX2CustomMenuBarPainter;
  TX2CustomMenuBarPainter = class;
  TX2CustomMenuBarItem = class;
  TX2MenuBarItem = class;
  TX2MenuBarGroup = class;
  TX2CustomMenuBar = class;

  IX2MenuBarDesigner = interface
    ['{F648CFD2-771D-4531-84D0-621FD7597E48}']
    procedure ItemAdded(AItem: TX2CustomMenuBarItem);
    procedure ItemModified(AItem: TX2CustomMenuBarItem);
    procedure ItemDeleting(AItem: TX2CustomMenuBarItem);
  end;

  TX2MenuBarHitTest = record
    HitTestCode:    Integer;
    Item:           TX2CustomMenuBarItem;
  end;

  TX2MenuBarDrawState             = (mdsHot, mdsSelected, mdsGroupHot, mdsGroupSelected);
  TX2MenuBarDrawStates            = set of TX2MenuBarDrawState;

  TX2MenuBarSpacingElement        = (seBeforeGroupHeader, seAfterGroupHeader,
                                     seBeforeFirstItem, seAfterLastItem,
                                     seBeforeItem, seAfterItem);

  TX2MenuBarSelectAction          = (saBefore, saAfter, saBoth);

  TX2ComponentNotificationEvent   = procedure(Sender: TObject; AComponent: TComponent; Operation: TOperation) of object;
  TX2MenuBarExpandingEvent        = procedure(Sender: TObject; Group: TX2MenuBarGroup; var Allowed: Boolean) of object;
  TX2MenuBarExpandedEvent         = procedure(Sender: TObject; Group: TX2MenuBarGroup) of object;
  TX2MenuBarSelectedChangingEvent = procedure(Sender: TObject; Item, NewItem: TX2CustomMenUBarItem; var Allowed: Boolean) of object;
  TX2MenuBarSelectedChangedEvent  = procedure(Sender: TObject; Item: TX2CustomMenUBarItem) of object;

  TX2MenuBarItemBoundsProc        = procedure(Sender: TObject;
                                              Item: TX2CustomMenuBarItem;
                                              const MenuBounds: TRect;
                                              const ItemBounds: TRect;
                                              Data: Pointer;
                                              var Abort: Boolean) of object;

  TX2MenuBarIterateProc           = procedure(Sender: TObject;
                                              Item: TX2CustomMenuBarItem;
                                              Data: Pointer;
                                              var Abort: Boolean) of object;

  TCollectionNotifyEvent          = procedure(Sender: TObject; Item: TCollectionItem; Action: TCollectionNotification) of object;
  TCollectionUpdateEvent          = procedure(Sender: TObject; Item: TCollectionItem) of object;

  IX2MenuBarPainterObserver = interface
    ['{22DE60C9-49A1-4E7D-B547-901BEDCC0FB7}']
    procedure PainterUpdate(Sender: TX2CustomMenuBarPainter);
  end;

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
    :$ Abstract painter class.

    :: Descendants must implement the actual drawing code.
  }
  TX2CustomMenuBarPainter = class(TComponent)
  private
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
    procedure FindHit(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds: TRect; const ItemBounds: TRect; Data: Pointer; var Abort: Boolean);

    procedure NotifyObservers();

    property MenuBar:           TX2CustomMenuBar          read GetMenuBar;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; overload; virtual;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    procedure AttachObserver(AObserver: IX2MenuBarPainterObserver);
    procedure DetachObserver(AObserver: IX2MenuBarPainterObserver);
  end;

  {
    :$ Action link for menu items and groups.
  }
  TX2MenuBarActionLink = class(TActionLink)
  private
    FClient:      TX2CustomMenuBarItem;
  protected
    procedure AssignClient(AClient: TObject); override;

    function IsCaptionLinked(): Boolean; override;
    function IsEnabledLinked(): Boolean; override;
    function IsImageIndexLinked(): Boolean; override;
    function IsVisibleLinked(): Boolean; override;
    procedure SetCaption(const Value: string); override;
    procedure SetEnabled(Value: Boolean); override;
    procedure SetImageIndex(Value: Integer); override;
    procedure SetVisible(Value: Boolean); override;

    property Client:  TX2CustomMenuBarItem  read FClient;
  end;

  {
    :$ Provides component notifications for collection items.
  }
  TX2ComponentNotification = class(TComponent)
  private
    FOnNotification:    TX2ComponentNotificationEvent;
  published
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  published
    property OnNotification: TX2ComponentNotificationEvent  read FOnNotification  write FOnNotification;
  end;

  {
    :$ Base class for menu items and groups.
  }
  TX2CustomMenuBarItem = class(TCollectionItem)
  private
    FAction:        TBasicAction;
    FActionLink:    TX2MenuBarActionLink;
    FCaption:       String;
    FData:          TObject;
    FEnabled:       Boolean;
    FImageIndex:    TImageIndex;
    FOwnsData:      Boolean;
    FTag:           Integer;
    FVisible:       Boolean;

    FNotification:  TX2ComponentNotification;
  private
    procedure DoActionChange(Sender: TObject);
  protected
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); virtual;

    function IsCaptionStored(): Boolean; virtual;
    function GetMenuBar(): TX2CustomMenuBar; virtual;
    procedure SetAction(const Value: TBasicAction);
    procedure SetCaption(const Value: String); virtual;
    procedure SetData(const Value: TObject); virtual;
    procedure SetEnabled(const Value: Boolean); virtual;
    procedure SetImageIndex(const Value: TImageIndex); virtual;
    procedure SetVisible(const Value: Boolean); virtual;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy(); override;

    procedure Assign(Source: TPersistent); override;

    property ActionLink:    TX2MenuBarActionLink  read FActionLink;
    property Data:          TObject               read FData        write SetData;
    property OwnsData:      Boolean               read FOwnsData    write FOwnsData;
    property MenuBar:       TX2CustomMenuBar      read GetMenuBar;
  published
    property Action:        TBasicAction          read FAction      write SetAction;
    property Caption:       String                read FCaption     write SetCaption      stored IsCaptionStored;
    property Enabled:       Boolean               read FEnabled     write SetEnabled      default True;
    property ImageIndex:    TImageIndex           read FImageIndex  write SetImageIndex   default -1;
    property Tag:           Integer               read FTag         write FTag            default 0;
    property Visible:       Boolean               read FVisible     write SetVisible      default True;
  end;

  {
    :$ Base class for menu collections.
  }
  TX2CustomMenuBarItems = class(TOwnedCollection)
  private
    FOnNotify:    TCollectionNotifyEvent;
    FOnUpdate:    TCollectionUpdateEvent;
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
    procedure Update(Item: TCollectionItem); override;

    property OnNotify:  TCollectionNotifyEvent  read FOnNotify  write FOnNotify;
    property OnUpdate:  TCollectionUpdateEvent  read FOnUpdate  write FOnUpdate;
  end;

  {
    :$ Contains a single menu item.
  }
  TX2MenuBarItem = class(TX2CustomMenuBarItem)
  private
    function GetGroup(): TX2MenuBarGroup;
  protected
    function IsCaptionStored(): Boolean; override;
  public
    constructor Create(Collection: TCollection); override;

    property Group:         TX2MenuBarGroup   read GetGroup;
  end;

  {
    :$ Manages a collection of menu items.
  }
  TX2MenuBarItems = class(TX2CustomMenuBarItems)
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
    function IsCaptionStored(): Boolean; override;
    procedure SetEnabled(const Value: Boolean); override;

    procedure InternalSetExpanded(const Value: Boolean);
    procedure ItemsNotify(Sender: TObject; Item: TCollectionItem; Action: TCollectionNotification);
    procedure ItemsUpdate(Sender: TObject; Item: TCollectionItem);

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
  TX2MenuBarGroups = class(TX2CustomMenuBarItems)
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
    FAllowCollapseAll:      Boolean;
    FAnimationStyle:        TX2MenuBarAnimationStyle;
    FAnimationTime:         Cardinal;
    FAnimator:              TX2CustomMenuBarAnimator;
    FAutoCollapse:          Boolean;
    FAutoSelectItem:        Boolean;
    FBorderStyle:           TBorderStyle;
    FBuffer:                Graphics.TBitmap;
    FCursorGroup:           TCursor;
    FCursorItem:            TCursor;
    FDesigner:              IX2MenuBarDesigner;
    FExpandingGroups:       TStringList;
    FGroups:                TX2MenuBarGroups;
    FHideScrollbar:         Boolean;
    FHotItem:               TX2CustomMenuBarItem;
    FImages:                TCustomImageList;
    FLastMousePos:          TPoint;
    FOnCollapsed:           TX2MenuBarExpandedEvent;
    FOnCollapsing:          TX2MenuBarExpandingEvent;
    FOnExpanded:            TX2MenuBarExpandedEvent;
    FOnExpanding:           TX2MenuBarExpandingEvent;
    FOnSelectedChanged:     TX2MenuBarSelectedChangedEvent;
    FOnSelectedChanging:    TX2MenuBarSelectedChangingEvent;
    FPainter:               TX2CustomMenuBarPainter;
    FScrollbar:             Boolean;
    FScrollOffset:          Integer;
    FSelectedItem:          TX2CustomMenuBarItem;

    procedure SetAllowCollapseAll(const Value: Boolean);
    procedure SetAnimator(const Value: TX2CustomMenuBarAnimator);
    procedure SetAutoCollapse(const Value: Boolean);
    procedure SetAutoSelectItem(const Value: Boolean);
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetGroups(const Value: TX2MenuBarGroups);
    procedure SetHideScrollbar(const Value: Boolean);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetScrollbar(const Value: Boolean);
    procedure SetSelectedItem(const Value: TX2CustomMenuBarItem);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Loaded(); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PainterUpdate(Sender: TX2CustomMenuBarPainter);
    procedure GroupsNotify(Sender: TObject; Item: TCollectionItem; Action: TCollectionNotification);
    procedure GroupsUpdate(Sender: TObject; Item: TCollectionItem);
    procedure UpdateScrollbar();

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
//    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;

    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;

    procedure TestMousePos(); virtual;
    function GetMenuHeight(): Integer; virtual;

    property Designer:    IX2MenuBarDesigner  read FDesigner  write FDesigner;
  protected
    procedure SetPainter(const Value: TX2CustomMenuBarPainter); virtual;

    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure Paint(); override;

    function GetDrawState(AItem: TX2CustomMenuBarItem): TX2MenuBarDrawStates;
    procedure DrawMenu(ACanvas: TCanvas); virtual;
    procedure DrawMenuItem(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds, ItemBounds: TRect; Data: Pointer; var Abort: Boolean); virtual;
    procedure DrawMenuItems(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect); virtual;
    procedure DrawNoPainter(ACanvas: TCanvas; const ABounds: TRect); virtual;

    function GetAnimatorClass(): TX2CustomMenuBarAnimatorClass; virtual;

    function IterateItemBounds(ACallback: TX2MenuBarItemBoundsProc; AData: Pointer = nil): TX2CustomMenuBarItem;
    function AllowInteraction(): Boolean; virtual;
    function ItemEnabled(AItem: TX2CustomMenuBarItem): Boolean; virtual;
    function ItemVisible(AItem: TX2CustomMenuBarItem): Boolean; virtual;

    property AllowCollapseAll:    Boolean                         read FAllowCollapseAll    write SetAllowCollapseAll default True;
    property AnimationStyle:      TX2MenuBarAnimationStyle        read FAnimationStyle      write FAnimationStyle default DefaultAnimationStyle;
    property AnimationTime:       Cardinal                        read FAnimationTime       write FAnimationTime default DefaultAnimationTime;
    property Animator:            TX2CustomMenuBarAnimator        read FAnimator            write SetAnimator;
    property AutoCollapse:        Boolean                         read FAutoCollapse        write SetAutoCollapse default False;
    property AutoSelectItem:      Boolean                         read FAutoSelectItem      write SetAutoSelectItem default False;
    property BorderStyle:         TBorderStyle                    read FBorderStyle         write SetBorderStyle default bsNone;
    property CursorGroup:         TCursor                         read FCursorGroup         write FCursorGroup default crDefault;
    property CursorItem:          TCursor                         read FCursorItem          write FCursorItem default crDefault;
    property HideScrollbar:       Boolean                         read FHideScrollbar       write SetHideScrollbar default True;
    property OnCollapsed:         TX2MenuBarExpandedEvent         read FOnCollapsed         write FOnCollapsed;
    property OnCollapsing:        TX2MenuBarExpandingEvent        read FOnCollapsing        write FOnCollapsing;
    property OnExpanded:          TX2MenuBarExpandedEvent         read FOnExpanded          write FOnExpanded;
    property OnExpanding:         TX2MenuBarExpandingEvent        read FOnExpanding         write FOnExpanding;
    property OnSelectedChanged:   TX2MenuBarSelectedChangedEvent  read FOnSelectedChanged   write FOnSelectedChanged;
    property OnSelectedChanging:  TX2MenuBarSelectedChangingEvent read FOnSelectedChanging  write FOnSelectedChanging;
    property Scrollbar:           Boolean                         read FScrollbar           write SetScrollbar default True;
  protected
    procedure DoAutoCollapse(AGroup: TX2MenuBarGroup); virtual;
    function DoAutoSelectItem(AGroup: TX2MenuBarGroup; AAction: TX2MenuBarSelectAction): Boolean; virtual;
    procedure DoExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean); virtual;
    procedure DoExpandedChanging(AGroup: TX2MenuBarGroup; AExpanding: Boolean); virtual;
    procedure DoExpandedChanged(AGroup: TX2MenuBarGroup); virtual;
    procedure DoSelectedChanging(ANewItem: TX2CustomMenuBarItem; var AAllowed: Boolean); virtual;
    procedure DoSelectedChanged(); virtual;

    procedure FindEnabledItem(Sender: TObject; Item: TX2CustomMenuBarItem; Data: Pointer; var Abort: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; overload;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    function Iterate(ACallback: TX2MenuBarIterateProc;
                     ADirection: TX2MenuBarDirection = mbdDown;
                     AData: Pointer = nil;
                     AStart: TX2CustomMenuBarItem = nil): TX2CustomMenuBarItem;

    function SelectFirst(): TX2CustomMenuBarItem;
    function SelectLast(): TX2CustomMenuBarItem;
    function SelectNext(): TX2CustomMenuBarItem;
    function SelectPrior(): TX2CustomMenuBarItem;

    function SelectGroup(AIndex: Integer): TX2MenuBarGroup;
    function SelectItem(AIndex: Integer; AGroup: TX2MenuBarGroup): TX2CustomMenuBarItem; overload;
    function SelectItem(AIndex: Integer; AGroup: Integer): TX2CustomMenuBarItem; overload;
    function SelectItem(AIndex: Integer): TX2CustomMenuBarItem; overload;

    procedure ResetGroupsSelectedItem();

    property Groups:        TX2MenuBarGroups        read FGroups        write SetGroups;
    property Images:        TCustomImageList        read FImages        write SetImages;
    property Painter:       TX2CustomMenuBarPainter read FPainter       write SetPainter;
    property SelectedItem:  TX2CustomMenuBarItem    read FSelectedItem  write SetSelectedItem;
  end;

  {
    :$ Exposes the menu bar's published properties.
  }
  TX2MenuBar = class(TX2CustomMenuBar)
  published
    property Align;
    property AllowCollapseAll;
    property AnimationStyle;
    property AnimationTime;
    property AutoCollapse;
    property AutoSelectItem;
    property BevelEdges;
    property BevelInner;
    property BevelKind;
    property BevelOuter;
    property BorderStyle;
    property BorderWidth;
    property CursorGroup;
    property CursorItem;
    property Font;
    property Groups;
    property HideScrollbar;
    property Images;
    property ParentFont;
    property OnClick;
    property OnCollapsed;
    property OnCollapsing;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnExpanded;
    property OnExpanding;
    property OnSelectedChanged;
    property OnSelectedChanging;
    {$IFDEF VER180}
    property OnMouseActivate;
    property OnMouseEnter;
    property OnMouseLeave;
    {$ENDIF}
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property Painter;
    property Scrollbar;
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

  {
    :$ Returns a pointer to the first physical scanline.

    :: In bottom-up bitmaps, the most common kind, the Scanline property
    :: compensates for this by returning the last physical row for Scanline[0];
    :: the first visual row. For most effects, the order in which the rows are
    :: processed is not important; speed is. This function returns the first
    :: physical scanline, which can be used as a single big array for the whole
    :: bitmap.

    :! Note that every scanline is padded until it is a multiple of 4 bytes
    :! (32 bits). For true lineair access, ensure the bitmap has a PixelFormat
    :! of pf32bit. 
  }
  function GetScanlinePointer(ABitmap: Graphics.TBitmap): Pointer;

  {
    :$ Wrapper for DrawFocusRect.

    :: Ensures the canvas is set up correctly for a standard focus rectangle.
  }
  procedure DrawFocusRect(ACanvas: TCanvas; const ABounds: TRect);

  {
    :$ Draws one bitmap over another with the specified Alpha transparency.

    :: Both bitmaps must be the same size.
  }
  procedure DrawBlended(ABackground, AForeground: Graphics.TBitmap; AAlpha: Byte);

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
  SysUtils,

  X2CLMenuBarAnimators;

const
  SDefaultItemCaption   = 'Menu Item';
  SDefaultGroupCaption  = 'Group';
  SNoPainter            = 'Painter property not set';

type
  TProtectedCollection  = class(TCollection);


{ Convenience functions }
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

function GetScanlinePointer(ABitmap: Graphics.TBitmap): Pointer;
var
  firstScanline:    Pointer;
  lastScanline:     Pointer;

begin
  firstScanline := ABitmap.ScanLine[0];
  lastScanline  := ABitmap.ScanLine[Pred(ABitmap.Height)];

  if Cardinal(firstScanline) > Cardinal(lastScanline) then
    Result  := lastScanline
  else
    Result  := firstScanline;
end;

procedure DrawFocusRect(ACanvas: TCanvas; const ABounds: TRect);
begin
  SetTextColor(ACanvas.Handle, ColorToRGB(clBlack));
  Windows.DrawFocusRect(ACanvas.Handle, ABounds);
end;

procedure DrawBlended(ABackground, AForeground: Graphics.TBitmap; AAlpha: Byte);
var
  sourcePixels:     PRGBAArray;
  destPixels:       PRGBAArray;
  sourcePixel:      PRGBQuad;
  pixelCount:       Integer;
  pixelIndex:       Integer;
  backAlpha:        Integer;
  foreAlpha:        Integer;

begin
  backAlpha     := AAlpha;
  foreAlpha     := 256 - AAlpha;
  pixelCount    := AForeground.Width * AForeground.Height;
  sourcePixels  := GetScanlinePointer(AForeground);
  destPixels    := GetScanlinePointer(ABackground);

  for pixelIndex := Pred(pixelCount) downto 0 do
    with destPixels^[pixelIndex] do
    begin
      sourcePixel := @sourcePixels^[pixelIndex];
      rgbRed      := ((rgbRed * backAlpha) +
                      (sourcePixel^.rgbRed * foreAlpha)) shr 8;
      rgbGreen    := ((rgbGreen * backAlpha) +
                      (sourcePixel^.rgbGreen * foreAlpha)) shr 8;
      rgbBlue     := ((rgbBlue * backAlpha) +
                      (sourcePixel^.rgbBlue * foreAlpha)) shr 8;
    end;
end;


{ TX2CustomMenuBarPainter }
constructor TX2CustomMenuBarPainter.Create(AOwner: TComponent);
begin
  inherited;

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
  Result := GetSpacing(seBeforeFirstItem) +
            GetSpacing(seAfterLastItem);

  for itemIndex := 0 to Pred(AGroup.Items.Count) do
    if MenuBar.ItemVisible(AGroup.Items[itemIndex]) then
      Inc(Result, GetSpacing(seBeforeItem) +
                  GetItemHeight(AGroup.Items[itemIndex]) +
                  GetSpacing(seAfterItem));
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


{ TX2MenuBarActionLink }
procedure TX2MenuBarActionLink.AssignClient(AClient: TObject);
begin
  FClient := (AClient as TX2CustomMenuBarItem);
end;

function TX2MenuBarActionLink.IsCaptionLinked(): Boolean;
begin
  Result  := inherited IsCaptionLinked() and
             (Client.Caption = (Action as TCustomAction).Caption);
end;

function TX2MenuBarActionLink.IsEnabledLinked(): Boolean;
begin
  Result  := inherited IsCaptionLinked() and
             (Client.Enabled = (Action as TCustomAction).Enabled);
end;

function TX2MenuBarActionLink.IsImageIndexLinked(): Boolean;
begin
  Result  := inherited IsCaptionLinked() and
             (Client.ImageIndex = (Action as TCustomAction).ImageIndex);
end;

function TX2MenuBarActionLink.IsVisibleLinked(): Boolean;
begin
  Result  := inherited IsCaptionLinked() and
             (Client.Visible = (Action as TCustomAction).Visible);
end;

procedure TX2MenuBarActionLink.SetCaption(const Value: string);
begin
  if IsCaptionLinked() then
    Client.Caption    := Value;
end;

procedure TX2MenuBarActionLink.SetEnabled(Value: Boolean);
begin
  if IsEnabledLinked() then
    Client.Enabled    := Value;
end;

procedure TX2MenuBarActionLink.SetImageIndex(Value: Integer);
begin
  if IsImageIndexLinked() then
    Client.ImageIndex := Value;
end;

procedure TX2MenuBarActionLink.SetVisible(Value: Boolean);
begin
  if IsVisibleLinked() then
    Client.Visible    := Value;
end;


{ TX2ComponentNotification }
procedure TX2ComponentNotification.Notification(AComponent: TComponent;
                                                Operation: TOperation);
begin
  if Assigned(FOnNotification) then
    FOnNotification(Self, AComponent, Operation);

  inherited;
end;


{ TX2CustomMenuBarItem }
constructor TX2CustomMenuBarItem.Create(Collection: TCollection);
begin
  FEnabled    := True;
  FImageIndex := -1;
  FOwnsData   := True;
  FVisible    := True;

  inherited;
end;

destructor TX2CustomMenuBarItem.Destroy();
begin
  Data  := nil;
  FreeAndNil(FActionLink);
  FreeAndNil(FNotification);

  inherited;
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


procedure TX2CustomMenuBarItem.DoActionChange(Sender: TObject);
begin
  if Sender = Action then
    ActionChange(Sender, False);
end;

procedure TX2CustomMenuBarItem.ActionChange(Sender: TObject;
                                            CheckDefaults: Boolean);
begin
  if Sender is TCustomAction then
    with TCustomAction(Sender) do
    begin
      if (not CheckDefaults) or (not Self.IsCaptionStored()) then
        Self.Caption    := Caption;

      if (not CheckDefaults) or Self.Enabled then
        Self.Enabled    := Enabled;

      if (not CheckDefaults) or (Self.ImageIndex = -1) then
        Self.ImageIndex := ImageIndex;

      if (not CheckDefaults) or Self.Visible then
        Self.Visible    := Visible;
    end;
end;


function TX2CustomMenuBarItem.IsCaptionStored(): Boolean;
begin
  Result  := (Length(Caption) > 0);
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

procedure TX2CustomMenuBarItem.SetAction(const Value: TBasicAction);
begin
  if Value <> FAction then
  begin
    if Assigned(FAction) then
      FAction.RemoveFreeNotification(FNotification);

    FAction := Value;

    if Assigned(FAction) then
    begin
      if not Assigned(FActionLink) then
      begin
        FActionLink           := TX2MenuBarActionLink.Create(Self);
        FActionLink.OnChange  := DoActionChange;
      end;

      FActionLink.Action    := Value;

      if not Assigned(FNotification) then
        FNotification := TX2ComponentNotification.Create(nil);

      ActionChange(Value, csLoading in Value.ComponentState);
      FAction.FreeNotification(FNotification);
    end else
    begin
      FreeAndNil(FActionLink);
      FreeAndNil(FNotification); 
    end;
  end;
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

procedure TX2CustomMenuBarItem.SetEnabled(const Value: Boolean);
begin
  if Value <> FEnabled then
  begin
    FEnabled := Value;
    Changed(False);
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

procedure TX2CustomMenuBarItem.SetVisible(const Value: Boolean);
begin
  if Value <> FVisible then
  begin
    FVisible := Value;
    Changed(False);
  end;
end;


{ TX2CustomMenuBarItems }
procedure TX2CustomMenuBarItems.Notify(Item: TCollectionItem; Action: TCollectionNotification);
begin
  if Assigned(FOnNotify) then
    FOnNotify(Self, Item, Action);

  inherited;
end;

procedure TX2CustomMenuBarItems.Update(Item: TCollectionItem);
begin
  inherited;

  if Assigned(FOnUpdate) then
    FOnUpdate(Self, Item);
end;


{ TX2MenuBarItem }
constructor TX2MenuBarItem.Create(Collection: TCollection);
begin
  Caption := SDefaultItemCaption;

  inherited;
end;


function TX2MenuBarItem.IsCaptionStored(): Boolean;
begin
  Result  := (Caption <> SDefaultItemCaption);
end;


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

  if Length(ACaption) > 0 then
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
  Caption         := SDefaultGroupCaption;
  FItems          := TX2MenuBarItems.Create(Self);
  FItems.OnNotify := ItemsNotify;
  FItems.OnUpdate := ItemsUpdate;

  { This results in the Collection's Notification being called, which needs to
    be after we create our Items property. }
  inherited;
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
  if Value <> FExpanded then
  begin
    FExpanded := Value;
    Changed(False);

    menu  := MenuBar;
    if Assigned(menu) then
      menu.DoExpandedChanged(Self);
  end;
end;

procedure TX2MenuBarGroup.ItemsNotify(Sender: TObject; Item: TCollectionItem; Action: TCollectionNotification);
begin
  if Assigned(Self.Collection) then
    TProtectedCollection(Self.Collection).Notify(Item, Action);
end;

procedure TX2MenuBarGroup.ItemsUpdate(Sender: TObject; Item: TCollectionItem);
var
  groupCollection: TProtectedCollection;

begin
  groupCollection := TProtectedCollection(Self.Collection);

  if Assigned(groupCollection) and (groupCollection.UpdateCount = 0) then
    groupCollection.Update(Item);
end;

function TX2MenuBarGroup.IsCaptionStored(): Boolean;
begin
  Result  := (Caption <> SDefaultGroupCaption);
end;

procedure TX2MenuBarGroup.SetEnabled(const Value: Boolean);
begin
  inherited;

  if not Value then
    Expanded  := False;
end;

procedure TX2MenuBarGroup.SetExpanded(const Value: Boolean);
var
  menu:     TX2CustomMenuBar;

begin
  if (Value <> FExpanded) and
     ((not Value) or Enabled) then
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

  FAllowCollapseAll := True;
  FAnimationStyle   := DefaultAnimationStyle;
  FAnimationTime    := DefaultAnimationTime;
  FBorderStyle      := bsNone;
  FCursorGroup      := crDefault;
  FCursorItem       := crDefault;
  FExpandingGroups  := TStringList.Create();
  FGroups           := TX2MenuBarGroups.Create(Self);
  FGroups.OnNotify  := GroupsNotify;
  FGroups.OnUpdate  := GroupsUpdate;
  FHideScrollbar    := True;
  FScrollbar        := True;
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
    Style := Style or WS_VSCROLL or BorderStyles[FBorderStyle];

    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style   := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
end;

procedure TX2CustomMenuBar.Loaded();
begin
  inherited;

  UpdateScrollbar();
end;


destructor TX2CustomMenuBar.Destroy();
begin
  Animator  := nil;
  Painter   := nil;

  FreeAndNil(FExpandingGroups);
  FreeAndNil(FGroups);
  FreeAndNil(FBuffer);

  inherited;
end;

procedure TX2CustomMenuBar.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result  := 0;
end;

procedure TX2CustomMenuBar.Paint();
var
  bufferRect:       TRect;
  expand:           Boolean;
  group:            TX2MenuBarGroup;

begin
  if Assigned(Painter) then
  begin
    if not Assigned(FBuffer) then
    begin
      FBuffer             := Graphics.TBitmap.Create();
      FBuffer.PixelFormat := pf32bit;
    end;

    if (FBuffer.Width <> Self.ClientWidth) or
       (FBuffer.Height <> Self.ClientHeight) then
    begin
      FBuffer.Width       := Self.ClientWidth;
      FBuffer.Height      := Self.ClientHeight;
    end;

    bufferRect  := Rect(0, 0, FBuffer.Width, FBuffer.Height);
    FBuffer.Canvas.Font.Assign(Self.Font);

    if Assigned(Animator) then
      Animator.Update();

    UpdateScrollbar();
    Painter.BeginPaint(Self);
    try
      Painter.DrawBackground(FBuffer.Canvas, bufferRect);
      DrawMenu(FBuffer.Canvas);
    finally
      Painter.EndPaint();
    end;

    Self.Canvas.Draw(0, 0, FBuffer);

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

        DoExpand(group, expand);
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

  if AItem = SelectedItem then
    Include(Result, mdsSelected);

  if Assigned(FHotItem) and (AItem = ItemGroup(FHotItem)) then
    Include(Result, mdsGroupHot);

  if Assigned(SelectedItem) and (AItem = ItemGroup(SelectedItem)) then
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
    item              := AGroup.Items[itemIndex];
    if not ItemVisible(item) then
      continue;

    Inc(itemBounds.Top, Painter.GetSpacing(seBeforeItem));
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


function TX2CustomMenuBar.GetAnimatorClass(): TX2CustomMenuBarAnimatorClass;
begin
  Result  := nil;

  case AnimationStyle of
    asSlide:      Result  := TX2MenuBarSlideAnimator;
    asDissolve:   Result  := TX2MenuBarDissolveAnimator;
    asFade:       Result  := TX2MenuBarFadeAnimator;
    asSlideFade:  Result  := TX2MenuBarSlideFadeAnimator;
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
  itemBounds  := menuBounds;
  OffsetRect(itemBounds, 0, -FScrollOffset);
  abort       := False;

  for groupIndex := 0 to Pred(Groups.Count) do
  begin
    { Group }
    group               := Groups[groupIndex];
    if not ItemVisible(group) then
      continue;

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
    end else if group.Expanded and (group.Items.Count > 0) then
    begin
      Inc(itemBounds.Top, Painter.GetSpacing(seBeforeFirstItem));

      for itemIndex := 0 to Pred(group.Items.Count) do
      begin
        { Item }
        item              := group.Items[itemIndex];
        if not ItemVisible(item) then
          continue;

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

var
  allowed:    Boolean;

begin
  if csLoading in ComponentState then
  begin
    AGroup.InternalSetExpanded(AExpanding);
    exit;
  end;

  if AGroup.Items.Count > 0 then
  begin
    allowed := True;
    if AExpanding then
    begin
      if Assigned(FOnExpanding) then
        FOnExpanding(Self, AGroup, allowed);
    end else
      if Assigned(FOnCollapsing) then
        FOnCollapsing(Self, AGroup, allowed);

    if not allowed then
      exit;

    { Pretend to auto select item - required for proper functioning of
      the OnSelectedChanging event }
    if AutoSelectItem then
      if not DoAutoSelectItem(AGroup, saBefore) then
        exit;

    { Allow collapse all }
    if not (AExpanding or AllowCollapseAll) then
      if ExpandedGroupsCount() = 1 then
      begin
        if AExpanding and (not Assigned(SelectedItem)) then
          SelectedItem := AGroup;

        exit;
      end;
  end;

  { Auto collapse }
  if AutoCollapse then
    if AExpanding then
      DoAutoCollapse(AGroup);

  if AGroup.Items.Count > 0 then
    DoExpand(AGroup, AExpanding)
  else
  begin
    AGroup.InternalSetExpanded(AExpanding);
    SelectedItem := AGroup
  end;
end;

procedure TX2CustomMenuBar.DoExpandedChanged(AGroup: TX2MenuBarGroup);
begin
  if AGroup.Expanded then
  begin
    { Auto select item }
    if AutoSelectItem then
      DoAutoSelectItem(AGroup, saAfter);

    if Assigned(FOnExpanded) then
      FOnExpanded(Self, AGroup);
  end else
    if Assigned(FOnCollapsed) then
      FOnCollapsed(Self, AGroup);
end;

procedure TX2CustomMenuBar.DoSelectedChanging(ANewItem: TX2CustomMenuBarItem;
                                              var AAllowed: Boolean);
begin
  if Assigned(FOnSelectedChanging) then
    FOnSelectedChanging(Self, SelectedItem, ANewItem, AAllowed);
end;

procedure TX2CustomMenuBar.DoSelectedChanged();
begin
  if Assigned(FOnSelectedChanged) then
    FOnSelectedChanged(Self, SelectedItem);
end;


function TX2CustomMenuBar.AllowInteraction(): Boolean;
begin
  Result  := not Assigned(Animator);
end;

function TX2CustomMenuBar.ItemEnabled(AItem: TX2CustomMenuBarItem): Boolean;
begin
  Result  := AItem.Enabled and AItem.Visible;
end;

function TX2CustomMenuBar.ItemVisible(AItem: TX2CustomMenuBarItem): Boolean;
begin
  Result  := AItem.Visible or (csDesigning in ComponentState);
end;


procedure TX2CustomMenuBar.DoExpand(AGroup: TX2MenuBarGroup;
                                    AExpanding: Boolean);
var
  animatorClass:  TX2CustomMenuBarAnimatorClass;
  itemsBuffer:    Graphics.TBitmap;
  itemsBounds:    TRect;

begin
  if not Assigned(Painter) then
    exit;

  if AGroup.Items.Count = 0 then
  begin
    AGroup.InternalSetExpanded(AExpanding);
    Exit;
  end;

  if Assigned(Animator) then
  begin
    FExpandingGroups.AddObject(Chr(Ord(AExpanding)), AGroup);
  end else
  begin
    animatorClass := GetAnimatorClass();
    if Assigned(animatorClass) and not (csDesigning in ComponentState) then
    begin
      Painter.BeginPaint(Self);
      try
        itemsBuffer := Graphics.TBitmap.Create();
        try
          itemsBounds             := Painter.ApplyMargins(Self.ClientRect);
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
          Animator.AnimationTime  := AnimationTime;
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

procedure TX2CustomMenuBar.DoAutoCollapse(AGroup: TX2MenuBarGroup);
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

function TX2CustomMenuBar.DoAutoSelectItem(AGroup: TX2MenuBarGroup;
                                           AAction: TX2MenuBarSelectAction): Boolean;
var
  group:      TX2MenuBarGroup;
  groupIndex: Integer;
  newItem:    TX2CustomMenuBarItem;
  itemIndex:  Integer;

begin
  Result  := True;
  group   := AGroup;
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
    newItem := group.Items[group.SelectedItem];
    if not ItemEnabled(newItem) then
    begin
      newItem := nil;

      for itemIndex := 0 to Pred(group.Items.Count) do
        if ItemEnabled(group.Items[itemIndex]) then
        begin
          newItem := group.Items[itemIndex];
          Break;
        end;
    end;

    if Assigned(newItem) and (newItem <> SelectedItem) then
    begin
      if AAction in [saBefore, saBoth] then
        DoSelectedChanging(newItem, Result);

      if Result and (AAction in [saAfter, saBoth]) then
        SelectedItem := newItem;
    end;
  end;
end;


procedure TX2CustomMenuBar.ResetGroupsSelectedItem;
var
  groupIndex: Integer;

begin
  for groupIndex := 0 to Pred(Groups.Count) do
    Groups[groupIndex].SelectedItem := -1;
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
  end;
end;

function TX2CustomMenuBar.HitTest(AX, AY: Integer): TX2MenuBarHitTest;
begin
  Result  := HitTest(Point(AX, AY));
end;


function TX2CustomMenuBar.Iterate(ACallback: TX2MenuBarIterateProc;
                                  ADirection: TX2MenuBarDirection;
                                  AData: Pointer;
                                  AStart: TX2CustomMenuBarItem): TX2CustomMenuBarItem;
  procedure MoveIndex(var AIndex: Integer);
  begin
    case ADirection of
      mbdUp:    Dec(AIndex);
      mbdDown:  Inc(AIndex);
    end;
  end;

var
  abort:          Boolean;
  groupIndex:     Integer;
  group:          TX2MenuBarGroup;
  itemIndex:      Integer;
  item:           TX2MenuBarItem;

begin
  Result      := nil;
  groupIndex  := 0;
  itemIndex   := -2;
  abort       := False;

  if Assigned(AStart) then
  begin
    if AStart is TX2MenuBarItem then
    begin
      groupIndex  := TX2MenuBarItem(AStart).Group.Index;
      itemIndex   := AStart.Index;
      MoveIndex(itemIndex);
    end else
      groupIndex  := AStart.Index;
  end;

  while (groupIndex >= 0) and (groupIndex < Groups.Count) do
  begin
    group := Groups[groupIndex];

    if group.Items.Count = 0 then
    begin
      if group <> AStart then
      begin
        ACallback(Self, group, AData, abort);
        if abort then
        begin
          Result := group;
          Break;
        end;
      end;
    end else
    begin
      if itemIndex = -2 then
        case ADirection of
          mbdUp:    itemIndex := Pred(group.Items.Count);
          mbdDown:  itemIndex := 0;
        end;

      while (itemIndex >= 0) and (itemIndex < group.Items.Count) do
      begin
        item  := group.Items[itemIndex];

        ACallback(Self, item, AData, abort);
        if abort then
        begin
          Result  := item;
          Break;
        end;

        MoveIndex(itemIndex);
      end;
    end;

    if Assigned(Result) then
      Break;

    itemIndex := -2;
    MoveIndex(groupIndex);
  end;
end;


procedure TX2CustomMenuBar.FindEnabledItem(Sender: TObject;
                                           Item: TX2CustomMenuBarItem;
                                           Data: Pointer;
                                           var Abort: Boolean);
begin
  Abort := ItemEnabled(Item);
end;


function TX2CustomMenuBar.SelectFirst(): TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result  := Iterate(FindEnabledItem);
    if Assigned(Result) then
      SelectedItem  := Result;
  end;
end;

function TX2CustomMenuBar.SelectLast(): TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result  := Iterate(FindEnabledItem, mbdDown);
    if Assigned(Result) then
      SelectedItem  := Result;
  end;
end;

function TX2CustomMenuBar.SelectNext(): TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result  := Iterate(FindEnabledItem, mbdDown, nil, FSelectedItem);
    if Assigned(Result) then
      SelectedItem  := Result;
  end;
end;

function TX2CustomMenuBar.SelectPrior(): TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result  := Iterate(FindEnabledItem, mbdUp, nil, FSelectedItem);
    if Assigned(Result) then
      SelectedItem  := Result;
  end;
end;


function TX2CustomMenuBar.SelectGroup(AIndex: Integer): TX2MenuBarGroup;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    if (AIndex >= 0) and (AIndex < Groups.Count) then
    begin
      Result        := Groups[AIndex];
      SelectedItem  := Result;
    end;
  end;
end;

function TX2CustomMenuBar.SelectItem(AIndex: Integer;
                                     AGroup: TX2MenuBarGroup): TX2CustomMenuBarItem;
var
  group:        TX2MenuBarGroup;
  groupIndex:   Integer;

begin
  Result  := nil;

  if AllowInteraction then
  begin
    group := AGroup;
    if not Assigned(group) then
    begin
      if Assigned(SelectedItem) then
      begin
        if SelectedItem is TX2MenuBarItem then
          group := TX2MenuBarItem(SelectedItem).Group
        else
          group := (SelectedItem as TX2MenuBarGroup);
      end else
        for groupIndex  := 0 to Pred(Groups.Count) do
          if Groups[groupIndex].Expanded then
          begin
            group := Groups[groupIndex];
            break;
          end;
    end;

    if Assigned(group) and (AIndex >= 0) and (AIndex < group.Items.Count) then
    begin
      Result        := group.Items[AIndex];
      SelectedItem  := Result;
    end;
  end;
end;

function TX2CustomMenuBar.SelectItem(AIndex, AGroup: Integer): TX2CustomMenuBarItem;
var
  group:      TX2MenuBarGroup;

begin
  group := nil;
  if (AGroup > 0) and (AGroup < Groups.Count) then
    group := Groups[AGroup];

  Result  := SelectItem(AIndex, group);
end;

function TX2CustomMenuBar.SelectItem(AIndex: Integer): TX2CustomMenuBarItem;
begin
  Result  := SelectItem(AIndex, nil);
end;



procedure TX2CustomMenuBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if Operation = opRemove then
    if AComponent = FPainter then
    begin
      FPainter  := nil;
      Invalidate();
    end else if AComponent = FImages then
    begin
      FImages := nil;
      Invalidate();
    end;

  inherited;
end;

procedure TX2CustomMenuBar.PainterUpdate(Sender: TX2CustomMenuBarPainter);
begin
  Invalidate();
end;

procedure TX2CustomMenuBar.GroupsNotify(Sender: TObject; Item: TCollectionItem; Action: TCollectionNotification);
begin
  if Action = cnDeleting then
    if Item = SelectedItem then
      SelectedItem  := nil
    else if Item = FHotItem then
      FHotItem      := nil;

  if Assigned(Designer) then
    case Action of
      cnAdded:      Designer.ItemAdded(Item as TX2CustomMenuBarItem);
      cnDeleting:   Designer.ItemDeleting(Item as TX2CustomMenuBarItem);
    end;

  if TProtectedCollection(Item.Collection).UpdateCount = 0 then
    Invalidate();
end;

procedure TX2CustomMenuBar.GroupsUpdate(Sender: TObject; Item: TCollectionItem);
begin
  if Assigned(SelectedItem) and (not ItemEnabled(SelectedItem)) then
    SelectedItem  := nil;

  if Assigned(Designer) then
    Designer.ItemModified(Item as TX2CustomMenuBarItem);

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
        if ItemEnabled(group) then
        begin
          group.Expanded  := not group.Expanded;
          hitTest.Item    := SelectedItem;
          Invalidate();
        end;
      end;

      if Assigned(hitTest.Item) then
        SelectedItem  := hitTest.Item;
    end;

  inherited;
end;

procedure TX2CustomMenuBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  cursor: TCursor;

begin
  FLastMousePos := Point(X, Y);
  TestMousePos();

  cursor  := crDefault;
  if Assigned(FHotItem) then
    if FHotItem is TX2MenuBarGroup then
      cursor  := CursorGroup
    else if FHotItem is TX2MenuBarItem then
      cursor  := CursorItem;

  if (cursor <> crDefault) and ItemEnabled(FHotItem) then
  begin
    Windows.SetCursor(Screen.Cursors[cursor]);
    exit;
  end;

  inherited;
end;

//procedure TX2CustomMenuBar.MouseUp(Button: TMouseButton; Shift: TShiftState;
//                                   X, Y: Integer);
//begin
//  inherited;
//end;

procedure TX2CustomMenuBar.CMMouseLeave(var Msg: TMessage);
begin
  FLastMousePos := Point(-1, -1);
  FHotItem      := nil;
  Invalidate();
end;


procedure TX2CustomMenuBar.WMVScroll(var Msg: TWMVScroll);
var
  scrollInfo:     TScrollInfo;
  scrollPos:      Integer;

begin
  Msg.Result  := 0;
  if Msg.ScrollCode = SB_ENDSCROLL then
    exit;

  scrollPos   := -1;

  FillChar(scrollInfo, SizeOf(TScrollInfo), #0);
  scrollInfo.cbSize := SizeOf(TScrollInfo);

  if Msg.ScrollCode = SB_THUMBTRACK then
  begin
    scrollInfo.fMask  := SIF_TRACKPOS;
    if GetScrollInfo(Self.Handle, SB_VERT, scrollInfo) then
        scrollPos := scrollInfo.nTrackPos;
  end else
  begin
    scrollInfo.fMask  := SIF_RANGE or SIF_POS or SIF_PAGE;
    if GetScrollInfo(Self.Handle, SB_VERT, scrollInfo) then
      case Msg.ScrollCode of
        SB_BOTTOM:
          scrollPos := scrollInfo.nMax;

        // #ToDo2 (MvR) 2-4-2006: scroll to the next item
        //                        (needs GetTopItem implementation) 
        SB_LINEDOWN:
          begin
            scrollPos := scrollInfo.nPos + 40;
            if scrollPos > scrollInfo.nMax then
              scrollPos := scrollInfo.nMax;
          end;
        SB_LINEUP:
          begin
            scrollPos := scrollInfo.nPos - 40;
            if scrollPos < scrollInfo.nMin then
              scrollPos := scrollInfo.nMin;
          end;

        SB_PAGEDOWN:
          begin
            scrollPos := scrollInfo.nPos + Integer(scrollInfo.nPage);
            if scrollPos > scrollInfo.nMax then
              scrollPos := scrollInfo.nMax;
          end;
        SB_PAGEUP:
          begin
            scrollPos := scrollInfo.nPos - Integer(scrollInfo.nPage);
            if scrollPos < scrollInfo.nMin then
              scrollPos := scrollInfo.nMin;
          end;
        SB_TOP:
          scrollPos := 0;
      end;
  end;

  if scrollPos <> -1 then
  begin
    FillChar(scrollInfo, SizeOf(TScrollInfo), #0);
    scrollInfo.cbSize := SizeOf(TScrollInfo);
    scrollInfo.fMask  := SIF_POS;
    scrollInfo.nPos   := scrollPos;

    SetScrollInfo(Self.Handle, SB_VERT, scrollInfo, False);
    Invalidate();
  end;
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
  if not Assigned(Painter) then
  begin
    Result  := -1;
    exit;
  end;

  menuBounds  := Painter.ApplyMargins(Self.ClientRect);
  Result      := Self.ClientHeight - (menuBounds.Bottom - menuBounds.Top);

  for groupIndex := 0 to Pred(Groups.Count) do
  begin
    { Group }
    group := Groups[groupIndex];
    if not ItemVisible(group) then
      continue;

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
        if not ItemVisible(item) then
          continue;

        Inc(Result, Painter.GetSpacing(seBeforeItem) +
                    Painter.GetItemHeight(item) +
                    Painter.GetSpacing(seAfterItem));
      end;

      Inc(Result, Painter.GetSpacing(seAfterLastItem));
    end;
  end;
end;

procedure TX2CustomMenuBar.UpdateScrollbar();
var
  scrollInfo:       TScrollInfo;

begin
  { Don't update the scrollbar while animating, prevents issues with the
    items buffer width if the scrollbar happens to show/hide during animation. }
  if Assigned(Animator) then
    exit;

  FillChar(scrollInfo, SizeOf(TScrollInfo), #0);
  scrollInfo.cbSize := SizeOf(TScrollInfo);
  scrollInfo.fMask  := SIF_PAGE or SIF_RANGE;

  if Scrollbar then
  begin
    scrollInfo.nMin   := 0;
    scrollInfo.nMax   := GetMenuHeight();
    scrollInfo.nPage  := Self.ClientHeight;

    if not HideScrollbar then
      scrollInfo.fMask  := scrollInfo.fMask or SIF_DISABLENOSCROLL;
  end else
  begin
    scrollInfo.nMin   := 0;
    scrollInfo.nMax   := 0;
    scrollInfo.nPage  := 0;
  end;

  SetScrollInfo(Self.Handle, SB_VERT, scrollInfo, True);

  FillChar(scrollInfo, SizeOf(TScrollInfo), #0);
  scrollInfo.cbSize := SizeOf(TScrollInfo);
  scrollInfo.fMask  := SIF_POS;
  FScrollOffset     := 0;

  if GetScrollInfo(Self.Handle, SB_VERT, scrollInfo) then
    FScrollOffset := scrollInfo.nPos;
end;


procedure TX2CustomMenuBar.SetAllowCollapseAll(const Value: Boolean);
begin
  if Value <> FAllowCollapseAll then
  begin
    FAllowCollapseAll := Value;
    
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

procedure TX2CustomMenuBar.SetAutoCollapse(const Value: Boolean);
begin
  if Value <> FAutoCollapse then
  begin
    FAutoCollapse := Value;

    if Value then
      DoAutoCollapse(nil);
  end;
end;

procedure TX2CustomMenuBar.SetAutoSelectItem(const Value: Boolean);
begin
  if Value <> FAutoSelectItem then
  begin
    FAutoSelectItem := Value;

    if Value and (not Assigned(SelectedItem)) then
      DoAutoSelectItem(nil, saBoth);
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

procedure TX2CustomMenuBar.SetHideScrollbar(const Value: Boolean);
begin
  if Value <> FHideScrollbar then
  begin
    FHideScrollbar := Value;
    RecreateWnd();
  end;
end;

procedure TX2CustomMenuBar.SetImages(const Value: TCustomImageList);
begin
  if Value <> FImages then
  begin
    if Assigned(FImages) then
      FImages.RemoveFreeNotification(Self);

    FImages := Value;

    if Assigned(FImages) then
      FImages.FreeNotification(Self);

    Invalidate();
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
    FPainter  := Value;

    if Assigned(FPainter) then
    begin
      FPainter.FreeNotification(Self);
      FPainter.AttachObserver(Self);
    end;

    Invalidate();
  end;
end;

procedure TX2CustomMenuBar.SetScrollbar(const Value: Boolean);
begin
  if Value <> FScrollbar then
  begin
    FScrollbar := Value;
    RecreateWnd();
  end;
end;

procedure TX2CustomMenuBar.SetSelectedItem(const Value: TX2CustomMenuBarItem);
var
  allowed:            Boolean;
  group:              TX2MenuBarGroup;

begin
  if Value <> FSelectedItem then
  begin
    if Assigned(Value) then
    begin
      allowed := ItemEnabled(Value);
      if allowed then
      begin
        DoSelectedChanging(Value, allowed);

        if allowed then
        begin
          if Value is TX2MenuBarGroup then
          begin
            group := TX2MenuBarGroup(Value);

            if group.Items.Count > 0 then
            begin
              // Item is a group, expand it (triggers autoselect too if appropriate)
              group.Expanded := True;
              Exit;
            end else
              DoAutoCollapse(group);
          end;

          FSelectedItem := Value;

          if Value is TX2MenuBarItem then
          begin
            group := TX2MenuBarItem(Value).Group;
            if Assigned(group) then
            begin
              group.SelectedItem  := Value.Index;

              if not group.Expanded then
                group.Expanded  := True;
            end;
          end;

          if Assigned(FSelectedItem) and Assigned(FSelectedItem.Action) then
            FSelectedItem.ActionLink.Execute(Self);
        end;
      end;
    end else
      FSelectedItem := Value;

    DoSelectedChanged();
    Invalidate();
  end;
end;

end.

