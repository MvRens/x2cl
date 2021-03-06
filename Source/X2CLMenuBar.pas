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


{$IFDEF VER180}
  {$DEFINE D2006}
{$ENDIF}


interface
uses
  // Not sure when TImageIndex was deprecated, we upgraded from XE2 to 10.2 Tokyo.
  // Lower the CompilerVersion if required.
  {$IF CompilerVersion >= 32}
  System.UITypes,
  {$IFEND}

  ActnList,
  Classes,
  Contnrs,
  Controls,
  Forms,
  Graphics,
  ImgList,
  Messages,
  SysUtils,
  Types,
  Windows;


type
  EInvalidItem                = class(Exception);
  EMenuBarInternalError       = class(Exception);

  TX2MenuBarAnimationStyle    = (asNone, asSlide, asDissolve, asFade,
                                 asSlideFade, asCustom);

  TX2MenuBarDirection         = (mbdUp, mbdDown);

  {$IF CompilerVersion >= 32}
  TImageIndex = System.UITypes.TImageIndex;
  {$IFEND}


const
  DefaultAnimationStyle = asSlide;
  DefaultAnimationTime  = 250;


type
  // #ToDo1 (MvR) 1-4-2006: scroll wheel support
  TX2CustomMenuBarAnimatorClass = class of TX2CustomMenuBarAnimator;
  TX2CustomMenuBarAnimator = class;
  TX2CustomMenuBarPainterClass = class of TX2CustomMenuBarPainter;
  TX2CustomMenuBarPainter = class;
  TX2CustomMenuBarItem = class;
  TX2MenuBarItem = class;
  TX2MenuBarGroup = class;
  TX2CustomMenuBar = class;


  TX2MenuBarItemsEnumerator = class;
  TX2MenuBarGroupsEnumerator = class;


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

  TX2ComponentNotificationEvent   = procedure(Sender: TObject; AComponent: TComponent; Operation: TOperation) of object;
  TX2MenuBarExpandingEvent        = procedure(Sender: TObject; Group: TX2MenuBarGroup; var Allowed: Boolean) of object;
  TX2MenuBarExpandedEvent         = procedure(Sender: TObject; Group: TX2MenuBarGroup) of object;
  TX2MenuBarSelectedChangingEvent = procedure(Sender: TObject; Item, NewItem: TX2CustomMenUBarItem; var Allowed: Boolean) of object;
  TX2MenuBarSelectedChangedEvent  = procedure(Sender: TObject; Item: TX2CustomMenUBarItem) of object;
  TX2MenuBarGetAnimatorClassEvent = procedure(Sender: TObject; var AnimatorClass: TX2CustomMenuBarAnimatorClass) of object;

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
    :$ Abstract animation buffer provider

    :: Provides on-demand retrieval of the buffer required for animation.
  }
  TX2CustomMenuBarAnimatorBuffer = class(TObject)
  private
    FBitmap:  Graphics.TBitmap;
  protected
    procedure PrepareBitmap(ABitmap: Graphics.TBitmap); virtual; abstract;

    function GetBitmap: Graphics.TBitmap; virtual;
    function GetHeight: Integer; virtual;
    function GetWidth: Integer; virtual;
  public
    destructor Destroy; override;

    property Bitmap:  Graphics.TBitmap  read GetBitmap;
    property Height:  Integer           read GetHeight;
    property Width:   Integer           read GetWidth;
  end;

  {
    :$ Abstract animation class

    :: Descendants implement the animation-specific drawing code.
  }
  TX2CustomMenuBarAnimator = class(TObject)
  private
    FAnimationTime:     Cardinal;
    FExpanding:         Boolean;
    FStartTime:         Cardinal;
    FItemsBuffer:       TX2CustomMenuBarAnimatorBuffer;
    FTerminated:        Boolean;
  protected
    function GetTimeElapsed: Cardinal; virtual;
    function GetHeight: Integer; virtual;
    procedure SetExpanding(const Value: Boolean); virtual;

    procedure Terminate; virtual;

    property ItemsBuffer:     TX2CustomMenuBarAnimatorBuffer  read FItemsBuffer;
    property TimeElapsed:     Cardinal                        read GetTimeElapsed;
  public
    constructor Create(AItemsBuffer: TX2CustomMenuBarAnimatorBuffer); virtual;
    destructor Destroy; override;

    procedure ResetStartTime;

    procedure Update; virtual;
    procedure Draw(ACanvas: TCanvas; const ABounds: TRect); virtual; abstract;

    property AnimationTime:   Cardinal                  read FAnimationTime   write FAnimationTime;
    property Expanding:       Boolean                   read FExpanding       write SetExpanding;
    property Height:          Integer                   read GetHeight;
    property StartTime:       Cardinal                  read FStartTime       write FStartTime;
    property Terminated:      Boolean                   read FTerminated;
  end;


  {
    :$ Abstract painter class.

    :: Descendants must implement the actual drawing code.
  }
  TX2CustomMenuBarPainter = class(TComponent)
  private
    FMenuBar:         TX2CustomMenuBar;
    FPaintCount:      Integer;
    FObservers:       TInterfaceList;

    function GetMenuBar: TX2CustomMenuBar;
  protected
    procedure BeginPaint(const AMenuBar: TX2CustomMenuBar);
    procedure EndPaint;

    function ApplyMargins(const ABounds: TRect): TRect; virtual;
    function UndoMargins(const ABounds: TRect): TRect; virtual;

    function GetSpacing(AElement: TX2MenuBarSpacingElement): Integer; virtual;
    function GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer; virtual; abstract;
    function GetGroupHeight(AGroup: TX2MenuBarGroup): Integer; virtual;
    function GetItemHeight(AItem: TX2MenuBarItem): Integer; virtual; abstract;

    procedure DrawBackground(ACanvas: TCanvas; const ABounds: TRect; const AOffset: TPoint); virtual; abstract;
    procedure DrawGroupHeader(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect; AState: TX2MenuBarDrawStates); virtual; abstract;
    procedure DrawItem(ACanvas: TCanvas; AItem: TX2MenuBarItem; const ABounds: TRect; AState: TX2MenuBarDrawStates); virtual; abstract;
    procedure FindHit(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds: TRect; const ItemBounds: TRect; Data: Pointer; var Abort: Boolean);

    procedure NotifyObservers;

    property MenuBar:           TX2CustomMenuBar          read GetMenuBar;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; overload; virtual;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    procedure AttachObserver(AObserver: IX2MenuBarPainterObserver);
    procedure DetachObserver(AObserver: IX2MenuBarPainterObserver);
  end;


  {
    :$ Abstract action class.

    :: Provides a base for menu bar actions which need to be performed
    :: asynchronous and/or in sequence.
  }
  TX2CustomMenuBarAction = class(TObject)
  private
    FMenuBar:       TX2CustomMenuBar;
    FStarted:       Boolean;
    FTerminated:    Boolean;
  protected
    function GetTerminated: Boolean; virtual;
    procedure Terminate; virtual;

    property MenuBar:   TX2CustomMenuBar  read FMenuBar;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar);

    function AllowUpdateScrollbar: Boolean; virtual;
    function AllowInteraction: Boolean; virtual;

    procedure Start; virtual;
    procedure Stop; virtual;

    procedure BeforePaint; virtual;
    procedure GetItemHeight(AItem: TX2CustomMenuBarItem; var AHeight: Integer; var AHandled: Boolean); virtual;
    procedure DrawMenuItem(ACanvas: TCanvas; APainter: TX2CustomMenuBarPainter;
                           AItem: TX2CustomMenuBarItem; const AMenuBounds,
                           AItemBounds: TRect; AState: TX2MenuBarDrawStates;
                           var AHandled: Boolean); virtual;
    procedure AfterPaint; virtual;

    property Started:     Boolean read FStarted;
    property Terminated:  Boolean read GetTerminated;
  end;


  {
    :$ Animation buffer menu bar link.
  }
  TX2MenuBarAnimatorBuffer  = class(TX2CustomMenuBarAnimatorBuffer)
  private
    FGroup:   TX2MenuBarGroup;
    FMenuBar: TX2CustomMenuBar;
  protected
    procedure PrepareBitmap(ABitmap: Graphics.TBitmap); override;
  public
    constructor Create(AMenuBar: TX2CustomMenuBar; AGroup: TX2MenuBarGroup);

    property Group:   TX2MenuBarGroup   read FGroup   write FGroup;
    property MenuBar: TX2CustomMenuBar  read FMenuBar write FMenuBar;
  end;


  {
    :$ Action link for menu items and groups.
  }
  TX2MenuBarActionLink = class(TActionLink)
  private
    FClient:      TX2CustomMenuBarItem;
  protected
    procedure AssignClient(AClient: TObject); override;

    function IsCaptionLinked: Boolean; override;
    function IsEnabledLinked: Boolean; override;
    function IsImageIndexLinked: Boolean; override;
    function IsVisibleLinked: Boolean; override;
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
    procedure ActionNotification(Sender: TObject; AComponent: TComponent; Operation: TOperation); virtual;

    function IsCaptionStored: Boolean; virtual;
    function GetMenuBar: TX2CustomMenuBar; virtual;
    procedure SetAction(const Value: TBasicAction);
    procedure SetCaption(const Value: String); virtual;
    procedure SetData(const Value: TObject); virtual;
    procedure SetEnabled(const Value: Boolean); virtual;
    procedure SetImageIndex(const Value: TImageIndex); virtual;
    procedure SetVisible(const Value: Boolean); virtual;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

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
    function GetGroup: TX2MenuBarGroup;
  protected
    function IsCaptionStored: Boolean; override;
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

    function GetEnumerator: TX2MenuBarItemsEnumerator;

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

    function GetSelectedItem: Integer;
    procedure SetExpanded(const Value: Boolean);
    procedure SetItems(const Value: TX2MenuBarItems);
  protected
    function IsCaptionStored: Boolean; override;
    procedure SetEnabled(const Value: Boolean); override;

    procedure InternalSetExpanded(const Value: Boolean);
    procedure ItemsNotify(Sender: TObject; Item: TCollectionItem; Action: TCollectionNotification);
    procedure ItemsUpdate(Sender: TObject; Item: TCollectionItem);
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;

    function GetEnumerator: TX2MenuBarItemsEnumerator;

    procedure Assign(Source: TPersistent); override;

    property SelectedItem:    Integer read GetSelectedItem  write FSelectedItem;
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

    function GetEnumerator: TX2MenuBarGroupsEnumerator;

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
    FAutoCollapse:          Boolean;
    FAutoSelectItem:        Boolean;
    FBorderStyle:           TBorderStyle;
    FCursorGroup:           TCursor;
    FCursorItem:            TCursor;
    FHideScrollbar:         Boolean;
    FGroups:                TX2MenuBarGroups;
    FImages:                TCustomImageList;
    FImagesChangeLink:      TChangeLink;
    FOnCollapsed:           TX2MenuBarExpandedEvent;
    FOnCollapsing:          TX2MenuBarExpandingEvent;
    FOnExpanded:            TX2MenuBarExpandedEvent;
    FOnExpanding:           TX2MenuBarExpandingEvent;
    FOnGetAnimatorClass:    TX2MenuBarGetAnimatorClassEvent;
    FOnSelectedChanged:     TX2MenuBarSelectedChangedEvent;
    FOnSelectedChanging:    TX2MenuBarSelectedChangingEvent;
    FPainter:               TX2CustomMenuBarPainter;
    FScrollbar:             Boolean;

    FHotItem:               TX2CustomMenuBarItem;
    FSelectedItem:          TX2CustomMenuBarItem;

    FActionQueue:           TObjectList;
    FBuffer:                Graphics.TBitmap;
    FDesigner:              IX2MenuBarDesigner;
    FLastMousePos:          TPoint;
    FScrollOffset:          Integer;

    procedure SetAllowCollapseAll(const Value: Boolean);
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
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure PainterUpdate(Sender: TX2CustomMenuBarPainter);
    procedure GroupsNotify(Sender: TObject; Item: TCollectionItem; Action: TCollectionNotification);
    procedure GroupsUpdate(Sender: TObject; Item: TCollectionItem);
    procedure UpdateScrollbar;
    procedure ImagesChange(Sender: TObject);

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;

    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
//    procedure WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
//    procedure CMMouseWheel(var Message: TCMMouseWheel); message CM_MOUSEWHEEL;

    procedure TestMousePos; virtual;
    function GetMenuHeight: Integer; virtual;
  protected
    procedure SetPainter(const Value: TX2CustomMenuBarPainter); virtual;


    { Painting }
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure Paint; override;

    procedure FindGroupBounds(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds: TRect; const ItemBounds: TRect; Data: Pointer; var Abort: Boolean);
    function GetGroupBounds(AGroup: TX2MenuBarGroup): TRect;

    function GetDrawState(AItem: TX2CustomMenuBarItem): TX2MenuBarDrawStates;
    procedure DrawMenu(ACanvas: TCanvas); virtual;
    procedure DrawMenuItem(Sender: TObject; Item: TX2CustomMenuBarItem; const MenuBounds, ItemBounds: TRect; Data: Pointer; var Abort: Boolean); virtual;
    procedure DrawMenuItems(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect); virtual;
    procedure DrawNoPainter(ACanvas: TCanvas; const ABounds: TRect); virtual;

    function GetAnimatorClass: TX2CustomMenuBarAnimatorClass; virtual;
    function GetAnimateAction(AGroup: TX2MenuBarGroup; AExpanding: Boolean): TX2CustomMenuBarAction; virtual;
    procedure GetAnimateGroup(AGroup: TX2MenuBarGroup; ABitmap: Graphics.TBitmap); virtual;

    function IterateItemBounds(ACallback: TX2MenuBarItemBoundsProc; AData: Pointer = nil): TX2CustomMenuBarItem;
    function AllowInteraction: Boolean; virtual;
    function ItemEnabled(AItem: TX2CustomMenuBarItem): Boolean; virtual;
    function ItemVisible(AItem: TX2CustomMenuBarItem): Boolean; virtual;


    { Action queue }
    function GetCurrentAction: TX2CustomMenuBarAction;
    procedure PushAction(AAction: TX2CustomMenuBarAction);
    procedure PopCurrentAction;


    property ActionQueue:         TObjectList                     read FActionQueue;
    property HotItem:             TX2CustomMenuBarItem            read FHotItem             write FHotItem;

    property AllowCollapseAll:    Boolean                         read FAllowCollapseAll    write SetAllowCollapseAll default True;
    property AnimationStyle:      TX2MenuBarAnimationStyle        read FAnimationStyle      write FAnimationStyle default DefaultAnimationStyle;
    property AnimationTime:       Cardinal                        read FAnimationTime       write FAnimationTime default DefaultAnimationTime;
    property AutoCollapse:        Boolean                         read FAutoCollapse        write SetAutoCollapse default False;
    property AutoSelectItem:      Boolean                         read FAutoSelectItem      write SetAutoSelectItem default False;
    property BorderStyle:         TBorderStyle                    read FBorderStyle         write SetBorderStyle default bsNone;
    property CursorGroup:         TCursor                         read FCursorGroup         write FCursorGroup default crDefault;
    property CursorItem:          TCursor                         read FCursorItem          write FCursorItem default crDefault;
    property HideScrollbar:       Boolean                         read FHideScrollbar       write SetHideScrollbar default True;
    property Scrollbar:           Boolean                         read FScrollbar           write SetScrollbar default True;

    property OnCollapsed:         TX2MenuBarExpandedEvent         read FOnCollapsed         write FOnCollapsed;
    property OnCollapsing:        TX2MenuBarExpandingEvent        read FOnCollapsing        write FOnCollapsing;
    property OnExpanded:          TX2MenuBarExpandedEvent         read FOnExpanded          write FOnExpanded;
    property OnExpanding:         TX2MenuBarExpandingEvent        read FOnExpanding         write FOnExpanding;
    property OnGetAnimatorClass:  TX2MenuBarGetAnimatorClassEvent read FOnGetAnimatorClass  write FOnGetAnimatorClass;
    property OnSelectedChanged:   TX2MenuBarSelectedChangedEvent  read FOnSelectedChanged   write FOnSelectedChanged;
    property OnSelectedChanging:  TX2MenuBarSelectedChangingEvent read FOnSelectedChanging  write FOnSelectedChanging;
  protected
    procedure InternalSetExpanded(AGroup: TX2MenuBarGroup; AExpanded: Boolean); virtual;
    procedure InternalSetSelected(AItem: TX2CustomMenuBarItem); virtual;

    function DoAutoCollapse(AGroup: TX2MenuBarGroup): Boolean; virtual;
    function DoAutoSelectItem(AGroup: TX2MenuBarGroup): Boolean; virtual;
    function DoExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean): Boolean; virtual;
    function DoSelectItem(AItem: TX2CustomMenuBarItem): Boolean; virtual;

    function PerformAutoCollapse(AGroup: TX2MenuBarGroup): Boolean; virtual;
    function PerformAutoSelectItem(AGroup: TX2MenuBarGroup): Boolean; virtual;
    function PerformExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean): Boolean; virtual;
    function PerformSelectItem(AItem: TX2CustomMenuBarItem): Boolean; virtual;

    procedure DoCollapsed(AGroup: TX2MenuBarGroup); virtual;
    procedure DoCollapsing(AGroup: TX2MenuBarGroup; var AAllowed: Boolean); virtual;
    procedure DoExpanded(AGroup: TX2MenuBarGroup); virtual;
    procedure DoExpanding(AGroup: TX2MenuBarGroup; var AAllowed: Boolean); virtual;

    procedure DoExpandedChanging(AGroup: TX2MenuBarGroup; AExpanding: Boolean); virtual;
    procedure DoExpandedChanged(AGroup: TX2MenuBarGroup); virtual;
    procedure DoSelectedChanging(ANewItem: TX2CustomMenuBarItem; var AAllowed: Boolean); virtual;
    procedure DoSelectedChanged; virtual;

    procedure FindEnabledItem(Sender: TObject; Item: TX2CustomMenuBarItem; Data: Pointer; var Abort: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetEnumerator: TX2MenuBarGroupsEnumerator;

    function HitTest(const APoint: TPoint): TX2MenuBarHitTest; overload;
    function HitTest(AX, AY: Integer): TX2MenuBarHitTest; overload;

    function Iterate(ACallback: TX2MenuBarIterateProc;
                     ADirection: TX2MenuBarDirection = mbdDown;
                     AData: Pointer = nil;
                     AStart: TX2CustomMenuBarItem = nil): TX2CustomMenuBarItem;

    function SelectFirst: TX2CustomMenuBarItem;
    function SelectLast: TX2CustomMenuBarItem;
    function SelectNext: TX2CustomMenuBarItem;
    function SelectPrior: TX2CustomMenuBarItem;

    function SelectGroup(AIndex: Integer): TX2MenuBarGroup;
    function SelectItem(AIndex: Integer; AGroup: TX2MenuBarGroup): TX2CustomMenuBarItem; overload;
    function SelectItem(AIndex: Integer; AGroup: Integer): TX2CustomMenuBarItem; overload;
    function SelectItem(AIndex: Integer): TX2CustomMenuBarItem; overload;

    procedure ResetGroupsSelectedItem;

    property Groups:        TX2MenuBarGroups        read FGroups        write SetGroups;
    property Images:        TCustomImageList        read FImages        write SetImages;
    property Painter:       TX2CustomMenuBarPainter read FPainter       write SetPainter;
    property SelectedItem:  TX2CustomMenuBarItem    read FSelectedItem  write SetSelectedItem;

    property Designer:      IX2MenuBarDesigner      read FDesigner      write FDesigner;
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
    property TabOrder;
    property TabStop default True;
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
    {$IFDEF D2006}
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
    :$ For iterators support for D2006+
  }
  TX2MenuBarItemsEnumerator = class(TCollectionEnumerator)
  private
    function GetCurrent: TX2MenuBarItem;
  public
    property Current: TX2MenuBarItem read GetCurrent;
  end;


  TX2MenuBarGroupsEnumerator = class(TCollectionEnumerator)
  private
    function GetCurrent: TX2MenuBarGroup;
  public
    property Current: TX2MenuBarGroup read GetCurrent;
  end;



const
  { HitTest Codes }
  htUnknown     = 0;
  htBackground  = 1;
  htGroup       = 2;
  htItem        = 3;
  htScroller    = 4;


implementation
uses
  X2CLGraphics,
  X2CLMenuBarActions,
  X2CLMenuBarAnimators;


const
  SDefaultItemCaption   = 'Menu Item';
  SDefaultGroupCaption  = 'Group';
  SNoPainter            = 'Painter property not set';
  SInvalidItem          = 'Item does not belong to this MenuBar';
  SBeginPaintConflict   = 'BeginPaint already called for a different MenuBar';
  SEndPaintWithoutBegin = 'EndPaint called without BeginPaint';
  
type
  TProtectedCollection  = class(TCollection);

  PFindGroupBoundsInfo  = ^TFindGroupBoundsInfo;
  TFindGroupBoundsInfo  = record
    Group:    TX2MenuBarGroup;
    Bounds:   TRect;
  end;


  
{ TX2CustomMenuBarPainter }
constructor TX2CustomMenuBarPainter.Create(AOwner: TComponent);
begin
  inherited;

  if AOwner is TX2CustomMenuBar then
    FMenuBar  := TX2CustomMenuBar(AOwner);
end;


destructor TX2CustomMenuBarPainter.Destroy;
begin
  FreeAndNil(FObservers);
  inherited;
end;


procedure TX2CustomMenuBarPainter.AttachObserver(AObserver: IX2MenuBarPainterObserver);
begin
  if not Assigned(FObservers) then
    FObservers := TInterfaceList.Create;

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
  if (FPaintCount > 0) and (AMenuBar <> FMenuBar) then
    raise EMenuBarInternalError.Create(SBeginPaintConflict);

  FMenuBar  := AMenuBar;
  Inc(FPaintCount);
end;


procedure TX2CustomMenuBarPainter.EndPaint;
begin
  if FPaintCount = 0 then
    raise EMenuBarInternalError.Create(SEndPaintWithoutBegin);

  Dec(FPaintCount);
  if FPaintCount = 0 then
    FMenuBar  := nil;       
end;


procedure TX2CustomMenuBarPainter.NotifyObservers;
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


function TX2CustomMenuBarPainter.UndoMargins(const ABounds: TRect): TRect;
begin
  Result := ABounds;
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


function TX2CustomMenuBarPainter.GetMenuBar: TX2CustomMenuBar;
begin
  Assert(Assigned(FMenuBar), 'BeginPaint not called');
  Result  := FMenuBar;
end;


function TX2CustomMenuBarPainter.GetSpacing(AElement: TX2MenuBarSpacingElement): Integer;
begin
  Result  := 0;
end;


{ TX2CustomMenuBarAnimatorBuffer }
destructor TX2CustomMenuBarAnimatorBuffer.Destroy;
begin
  FreeAndNil(FBitmap);

  inherited;
end;


function TX2CustomMenuBarAnimatorBuffer.GetBitmap: Graphics.TBitmap;
begin
  if not Assigned(FBitmap) then
  begin
    FBitmap             := Graphics.TBitmap.Create;
    FBitmap.PixelFormat := pf32bit;
    PrepareBitmap(FBitmap);
  end;

  Result := FBitmap;
end;

function TX2CustomMenuBarAnimatorBuffer.GetHeight: Integer;
begin
  Result := Bitmap.Height;
end;


function TX2CustomMenuBarAnimatorBuffer.GetWidth: Integer;
begin
  Result := Bitmap.Width;
end;


{ TX2CustomMenuBarAnimator }
constructor TX2CustomMenuBarAnimator.Create(AItemsBuffer: TX2CustomMenuBarAnimatorBuffer);
begin
  inherited Create;

  ResetStartTime;
  FItemsBuffer  := AItemsBuffer;
end;

destructor TX2CustomMenuBarAnimator.Destroy;
begin
  FreeAndNil(FItemsBuffer);

  inherited;
end;


procedure TX2CustomMenuBarAnimator.ResetStartTime;
begin
  FStartTime    := GetTickCount;
end;


function TX2CustomMenuBarAnimator.GetHeight: Integer;
begin
  Result  := ItemsBuffer.Height;
end;


function TX2CustomMenuBarAnimator.GetTimeElapsed: Cardinal;
var
  currentTime:      Cardinal;

begin
  currentTime := GetTickCount;
  Result      := currentTime - FStartTime;

  if currentTime < FStartTime then
    Inc(Result, High(Cardinal));
end;


procedure TX2CustomMenuBarAnimator.SetExpanding(const Value: Boolean);
begin
  FExpanding  := Value;
end;


procedure TX2CustomMenuBarAnimator.Terminate;
begin
  FTerminated := True;
end;


procedure TX2CustomMenuBarAnimator.Update;
begin
end;



{ TX2CustomMenuBarAction }
constructor TX2CustomMenuBarAction.Create(AMenuBar: TX2CustomMenuBar);
begin
  inherited Create;

  FMenuBar  := AMenuBar;
end;


procedure TX2CustomMenuBarAction.Terminate;
begin
  FTerminated := True;
end;


function TX2CustomMenuBarAction.AllowInteraction: Boolean;
begin
  Result  := False;
end;


function TX2CustomMenuBarAction.AllowUpdateScrollbar: Boolean;
begin
  Result  := False;
end;


procedure TX2CustomMenuBarAction.Start;
begin
  FStarted  := True;
end;


procedure TX2CustomMenuBarAction.Stop;
begin
  FStarted  := False;
end;


procedure TX2CustomMenuBarAction.BeforePaint;
begin
end;


procedure TX2CustomMenuBarAction.GetItemHeight(AItem: TX2CustomMenuBarItem; var AHeight: Integer; var AHandled: Boolean);
begin
end;


procedure TX2CustomMenuBarAction.DrawMenuItem(ACanvas: TCanvas; APainter: TX2CustomMenuBarPainter;
                                              AItem: TX2CustomMenuBarItem; const AMenuBounds,
                                              AItemBounds: TRect; AState: TX2MenuBarDrawStates;
                                              var AHandled: Boolean);
begin
end;


procedure TX2CustomMenuBarAction.AfterPaint;
begin
end;


function TX2CustomMenuBarAction.GetTerminated: Boolean;
begin
  Result := FTerminated;
end;


{ TX2MenuBarAnimatorBuffer }
constructor TX2MenuBarAnimatorBuffer.Create(AMenuBar: TX2CustomMenuBar; AGroup: TX2MenuBarGroup);
begin
  inherited Create;

  FGroup    := AGroup;
  FMenuBar  := AMenuBar;
end;


procedure TX2MenuBarAnimatorBuffer.PrepareBitmap(ABitmap: Graphics.TBitmap);
begin
  MenuBar.GetAnimateGroup(Group, ABitmap);
end;


{ TX2MenuBarActionLink }
procedure TX2MenuBarActionLink.AssignClient(AClient: TObject);
begin
  FClient := (AClient as TX2CustomMenuBarItem);
end;


function TX2MenuBarActionLink.IsCaptionLinked: Boolean;
begin
  Result  := inherited IsCaptionLinked and
             (Client.Caption = (Action as TCustomAction).Caption);
end;


function TX2MenuBarActionLink.IsEnabledLinked: Boolean;
begin
  Result  := inherited IsCaptionLinked and
             (Client.Enabled = (Action as TCustomAction).Enabled);
end;


function TX2MenuBarActionLink.IsImageIndexLinked: Boolean;
begin
  Result  := inherited IsCaptionLinked and
             (Client.ImageIndex = (Action as TCustomAction).ImageIndex);
end;


function TX2MenuBarActionLink.IsVisibleLinked: Boolean;
begin
  Result  := inherited IsCaptionLinked and
             (Client.Visible = (Action as TCustomAction).Visible);
end;


procedure TX2MenuBarActionLink.SetCaption(const Value: string);
begin
  if IsCaptionLinked then
    Client.Caption    := Value;
end;


procedure TX2MenuBarActionLink.SetEnabled(Value: Boolean);
begin
  if IsEnabledLinked then
    Client.Enabled    := Value;
end;


procedure TX2MenuBarActionLink.SetImageIndex(Value: Integer);
begin
  if IsImageIndexLinked then
    Client.ImageIndex := Value;
end;


procedure TX2MenuBarActionLink.SetVisible(Value: Boolean);
begin
  if IsVisibleLinked then
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

destructor TX2CustomMenuBarItem.Destroy;
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
      if (not CheckDefaults) or (not Self.IsCaptionStored) then
        Self.Caption    := Caption;

      if (not CheckDefaults) or Self.Enabled then
        Self.Enabled    := Enabled;

      if (not CheckDefaults) or (Self.ImageIndex = -1) then
        Self.ImageIndex := ImageIndex;

      if (not CheckDefaults) or Self.Visible then
        Self.Visible    := Visible;
    end;
end;


procedure TX2CustomMenuBarItem.ActionNotification(Sender: TObject; AComponent: TComponent; Operation: TOperation);
begin
  if (AComponent = FAction) and (Operation = opRemove) then
  begin
    { Don't free FNotification here, we're in it's event handler }
    FAction := nil;
    FreeAndNil(FActionLink);
  end;
end;


function TX2CustomMenuBarItem.IsCaptionStored: Boolean;
begin
  Result  := (Length(Caption) > 0);
end;


function TX2CustomMenuBarItem.GetMenuBar: TX2CustomMenuBar;
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
      begin
        FNotification := TX2ComponentNotification.Create(nil);
        FNotification.OnNotification := ActionNotification;
      end;

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


function TX2MenuBarItem.IsCaptionStored: Boolean;
begin
  Result  := (Caption <> SDefaultItemCaption);
end;


function TX2MenuBarItem.GetGroup: TX2MenuBarGroup;
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


function TX2MenuBarItems.GetEnumerator: TX2MenuBarItemsEnumerator;
begin
  Result := TX2MenuBarItemsEnumerator.Create(Self);
end;


function TX2MenuBarItems.Add(const ACaption: TCaption): TX2MenuBarItem;
begin
  Result          := TX2MenuBarItem(inherited Add);

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


destructor TX2MenuBarGroup.Destroy;
begin
  FreeAndNil(FItems);

  if OwnsData then
    FreeAndNil(FData);

  inherited;
end;


function TX2MenuBarGroup.GetEnumerator: TX2MenuBarItemsEnumerator;
begin
  Result := TX2MenuBarItemsEnumerator.Create(Items);
end;


procedure TX2MenuBarGroup.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarGroup then
    with TX2MenuBarGroup(Source) do
      Self.Items.Assign(Items);

  inherited;
end;


function TX2MenuBarGroup.GetSelectedItem: Integer;
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
begin
  if Value <> FExpanded then
  begin
    FExpanded := Value;
    Changed(False);
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


function TX2MenuBarGroup.IsCaptionStored: Boolean;
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


function TX2MenuBarGroups.GetEnumerator: TX2MenuBarGroupsEnumerator;
begin
  Result := TX2MenuBarGroupsEnumerator.Create(Self);
end;


function TX2MenuBarGroups.Add(const ACaption: TCaption): TX2MenuBarGroup;
begin
  Result          := TX2MenuBarGroup(inherited Add);

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

  FActionQueue      := TObjectList.Create(True);
  FAllowCollapseAll := True;
  FAnimationStyle   := DefaultAnimationStyle;
  FAnimationTime    := DefaultAnimationTime;
  FBorderStyle      := bsNone;
  FCursorGroup      := crDefault;
  FCursorItem       := crDefault;
  FGroups           := TX2MenuBarGroups.Create(Self);
  FGroups.OnNotify  := GroupsNotify;
  FGroups.OnUpdate  := GroupsUpdate;
  FHideScrollbar    := True;
  FImagesChangeLink := TChangeLink.Create;
  FScrollbar        := True;
  TabStop           := True;

  FImagesChangeLink.OnChange  := ImagesChange;
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


procedure TX2CustomMenuBar.Loaded;
begin
  inherited;

  UpdateScrollbar;
end;


destructor TX2CustomMenuBar.Destroy;
begin
  Images    := nil;
  Painter   := nil;

  FreeAndNil(FGroups);
  FreeAndNil(FBuffer);
  FreeAndNil(FActionQueue);
  FreeAndNil(FImagesChangeLink);

  inherited;
end;


function TX2CustomMenuBar.GetEnumerator: TX2MenuBarGroupsEnumerator;
begin
  Result := TX2MenuBarGroupsEnumerator.Create(Groups);
end;


procedure TX2CustomMenuBar.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result  := 0;
end;


procedure TX2CustomMenuBar.Paint;
var
  bufferRect:       TRect;
  currentAction:    TX2CustomMenuBarAction;

begin
  if Assigned(Painter) then
  begin
    { Prepare buffer }
    if not Assigned(FBuffer) then
    begin
      FBuffer             := Graphics.TBitmap.Create;
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


    { Update action }
    currentAction := GetCurrentAction;
    if Assigned(currentAction) then
    begin
      if not currentAction.Started then
        currentAction.Start;

      currentAction.BeforePaint;
    end;


    UpdateScrollbar;


    { Draw menu }
    Painter.BeginPaint(Self);
    try
      Painter.DrawBackground(FBuffer.Canvas, bufferRect, Point(0, 0));
      DrawMenu(FBuffer.Canvas);
    finally
      Painter.EndPaint;
    end;

    Self.Canvas.Draw(0, 0, FBuffer);


    { Action queue }
    if Assigned(currentAction) then
    begin
      { Make sure Paint is called again while there's an action queue }
      Invalidate;

      currentAction.AfterPaint;

      if currentAction.Terminated then
      begin
        currentAction.Stop;
        PopCurrentAction;

        { Start the next action in the queue, continue until we find an
          action which doesn't terminate immediately. See PushAction. }
        currentAction := GetCurrentAction;
        while Assigned(currentAction) do
        begin
          currentAction.Start;

          if currentAction.Terminated then
          begin
            currentAction.Stop;
            PopCurrentAction;

            currentAction := GetCurrentAction;
          end else
            Break;
        end;
      end;
    end;
  end
  else
    DrawNoPainter(Self.Canvas, Self.ClientRect);
end;


procedure TX2CustomMenuBar.FindGroupBounds(Sender: TObject; Item: TX2CustomMenuBarItem;
                                           const MenuBounds, ItemBounds: TRect;
                                           Data: Pointer; var Abort: Boolean);
var
  findInfo: PFindGroupBoundsInfo;

begin
  findInfo := Data;

  if Item = findInfo^.Group then
  begin
    findInfo^.Bounds  := ItemBounds;
    Abort             := True;
  end;
end;


function TX2CustomMenuBar.GetGroupBounds(AGroup: TX2MenuBarGroup): TRect;
var
  findInfo: TFindGroupBoundsInfo;

begin
  findInfo.Group  := AGroup;
  if Assigned(IterateItemBounds(FindGroupBounds, @findInfo)) then
  begin
    Result        := findInfo.Bounds;

    { We receive the bounds of the group item, start with the first
      menu item. }
    Result.Top    := Result.Bottom;
    Result.Bottom := Result.Top + Painter.GetGroupHeight(AGroup);
  end;
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
  canvas:           TCanvas;
  currentAction:    TX2CustomMenuBarAction;
  drawState:        TX2MenuBarDrawStates;
  handled:          Boolean;

begin
  if ItemBounds.Top > MenuBounds.Bottom then
  begin
    Abort := True;
    exit;
  end;

  canvas        := TCanvas(Data);
  drawState     := GetDrawState(Item);
  currentAction := GetCurrentAction;
  handled       := False;

  if Assigned(currentAction) then
    currentAction.DrawMenuItem(canvas, Painter, Item, MenuBounds, ItemBounds,
                               drawState, handled);

  if not handled then
  begin
    if Item is TX2MenuBarGroup then
      Painter.DrawGroupHeader(canvas, TX2MenuBarGroup(Item), ItemBounds, drawState)
    else if Item is TX2MenuBarItem then
      Painter.DrawItem(canvas, TX2MenuBarItem(Item), ItemBounds, drawState);
  end;
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

    X2CLGraphics.DrawText(ACanvas, SNoPainter, ABounds, taCenter);
  end;
end;


function TX2CustomMenuBar.GetAnimatorClass: TX2CustomMenuBarAnimatorClass;
begin
  Result  := nil;

  case AnimationStyle of
    asSlide:      Result  := TX2MenuBarSlideAnimator;
    asDissolve:   Result  := TX2MenuBarDissolveAnimator;
    asFade:       Result  := TX2MenuBarFadeAnimator;
    asSlideFade:  Result  := TX2MenuBarSlideFadeAnimator;
  end;
end;


function TX2CustomMenuBar.GetAnimateAction(AGroup: TX2MenuBarGroup; AExpanding: Boolean): TX2CustomMenuBarAction;
var
  animatorClass:    TX2CustomMenuBarAnimatorClass;
  animator:         TX2CustomMenuBarAnimator;

begin
  Result := nil;
  if not Assigned(Painter) then
    Exit;

  animatorClass := GetAnimatorClass;
  if Assigned(animatorClass) and not (csDesigning in ComponentState) then
  begin
    animator                := animatorClass.Create(TX2MenuBarAnimatorBuffer.Create(Self, AGroup));
    animator.AnimationTime  := AnimationTime;
    animator.Expanding      := AExpanding;

    Result := TX2MenuBarAnimateAction.Create(Self, AGroup, animator);
    Invalidate;
  end;
end;


procedure TX2CustomMenuBar.GetAnimateGroup(AGroup: TX2MenuBarGroup; ABitmap: Graphics.TBitmap);
var
  itemsBounds:      TRect;
  groupOffset:      TPoint;

begin
  Painter.BeginPaint(Self);
  try
    itemsBounds         := GetGroupBounds(AGroup);
    ABitmap.PixelFormat := pf32bit;
    ABitmap.Width       := itemsBounds.Right - itemsBounds.Left;
    ABitmap.Height      := itemsBounds.Bottom - itemsBounds.Top;

    { Pass the original position of the group to the painter, so it
      can do proper custom backgrounds. }
    Painter.UndoMargins(itemsBounds);
    groupOffset             := itemsBounds.TopLeft;

    // #ToDo1 (MvR) 17-04-2009: even tijdelijk; een van de metrics moet meegenomen worden in de berekening
    Inc(groupOffset.Y, 8);

    itemsBounds             := Rect(0, 0, ABitmap.Width, ABitmap.Height);

    ABitmap.Canvas.Font.Assign(Self.Font);

    Painter.DrawBackground(ABitmap.Canvas, itemsBounds, groupOffset);
    DrawMenuItems(ABitmap.Canvas, AGroup, itemsBounds);
  finally
    Painter.EndPaint;
  end;
end;


function TX2CustomMenuBar.IterateItemBounds(ACallback: TX2MenuBarItemBoundsProc;
                                            AData: Pointer): TX2CustomMenuBarItem;
var
  abort:            Boolean;
  currentAction:    TX2CustomMenuBarAction;
  group:            TX2MenuBarGroup;
  groupIndex:       Integer;
  handled:          Boolean;
  item:             TX2MenuBarItem;
  itemBounds:       TRect;
  itemHeight:       Integer;
  itemIndex:        Integer;
  menuBounds:       TRect;

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
    currentAction       := GetCurrentAction;
    handled             := False;

    if Assigned(currentAction) then
    begin
      itemHeight  := 0;

      currentAction.GetItemHeight(group, itemHeight, handled);
      if handled then
        Inc(itemBounds.Top, itemHeight);
    end;

    if (not handled) and group.Expanded and (group.Items.Count > 0) then
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
  function ExpandedGroupsCount: Integer;
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
    // #ToDo1 (MvR) 20-4-2007: check OnSelectedChanging behaviour
//    if AutoSelectItem then
//      if not DoAutoSelectItem(AGroup, saBefore) then
//        exit;

    { Allow collapse all }
    if not (AExpanding or AllowCollapseAll) then
      if ExpandedGroupsCount = 1 then
      begin
        if AExpanding and (not Assigned(SelectedItem)) then
          SelectedItem := AGroup;

        exit;
      end;
  end;

  if AGroup.Items.Count > 0 then
  begin
    { Auto collapse first }
    if AutoCollapse and AExpanding then
        DoAutoCollapse(AGroup);

    PerformExpand(AGroup, AExpanding);
  end else
  begin
    AGroup.InternalSetExpanded(AExpanding);
    SelectedItem := AGroup;

    { Auto collapse after - if selecting the group takes some time this ensures
      that the animation starts afterwards. }
    if AutoCollapse and AExpanding then
        DoAutoCollapse(AGroup);
  end;
end;


procedure TX2CustomMenuBar.DoExpandedChanged(AGroup: TX2MenuBarGroup);
begin
  if AGroup.Expanded then
  begin
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


procedure TX2CustomMenuBar.DoSelectedChanged;
begin
  if Assigned(FOnSelectedChanged) then
    FOnSelectedChanged(Self, SelectedItem);
end;


procedure TX2CustomMenuBar.DoCollapsed(AGroup: TX2MenuBarGroup);
begin
  if Assigned(FOnCollapsed) then
    FOnCollapsed(Self, AGroup);
end;


procedure TX2CustomMenuBar.DoCollapsing(AGroup: TX2MenuBarGroup; var AAllowed: Boolean);
begin
  if Assigned(FOnCollapsing) then
    FOnCollapsing(Self, AGroup, AAllowed);
end;


procedure TX2CustomMenuBar.DoExpanded(AGroup: TX2MenuBarGroup);
begin
  if Assigned(FOnExpanded) then
    FOnExpanded(Self, AGroup);
end;


procedure TX2CustomMenuBar.DoExpanding(AGroup: TX2MenuBarGroup; var AAllowed: Boolean);
begin
  if Assigned(FOnExpanding) then
    FOnExpanding(Self, AGroup, AAllowed);
end;



function TX2CustomMenuBar.AllowInteraction: Boolean;
var
  currentAction:  TX2CustomMenuBarAction;

begin
  Result        := True;

  currentAction := GetCurrentAction;
  if Assigned(currentAction) then
    Result := currentAction.AllowInteraction;
end;


function TX2CustomMenuBar.ItemEnabled(AItem: TX2CustomMenuBarItem): Boolean;
begin
  Result  := AItem.Enabled and AItem.Visible;
end;


function TX2CustomMenuBar.ItemVisible(AItem: TX2CustomMenuBarItem): Boolean;
begin
  Result  := AItem.Visible or (csDesigning in ComponentState);
end;



function TX2CustomMenuBar.GetCurrentAction: TX2CustomMenuBarAction;
begin
  Result := nil;
  if ActionQueue.Count > 0 then
    Result := TX2CustomMenuBarAction(ActionQueue[0]);
end;


procedure TX2CustomMenuBar.PushAction(AAction: TX2CustomMenuBarAction);
var
  action:   TX2CustomMenuBarAction;

begin
  action  := AAction;

  if ActionQueue.Count = 0 then
  begin
    { Start the action; if it's terminated immediately don't add it to the
      queue. This enables actions like selecting an item without requiring
      animation to fire straight away. }
    action.Start;

    if action.Terminated then
    begin
      action.Stop;
      FreeAndNil(action);
    end;
  end;

  if Assigned(action) then
    ActionQueue.Add(action);

  Invalidate;
end;


procedure TX2CustomMenuBar.PopCurrentAction;
begin
  if ActionQueue.Count > 0 then
    ActionQueue.Delete(0);
end;


procedure TX2CustomMenuBar.InternalSetExpanded(AGroup: TX2MenuBarGroup;
                                               AExpanded: Boolean);
begin
  AGroup.InternalSetExpanded(AExpanded);
  DoExpandedChanged(AGroup);

  Invalidate;
end;


procedure TX2CustomMenuBar.InternalSetSelected(AItem: TX2CustomMenuBarItem);
var
  group:    TX2MenuBarGroup;

begin
  FSelectedItem := AItem;
  DoSelectedChanged;

  if Assigned(AItem) then
  begin
    if (AItem is TX2MenuBarItem) then
    begin
      group := TX2MenuBarItem(AItem).Group;
      if Assigned(group) then
        group.SelectedItem  := AItem.Index;
    end;

    if Assigned(AItem) and Assigned(AItem.Action) then
      AItem.ActionLink.Execute(Self);
  end;
end;


function TX2CustomMenuBar.DoAutoCollapse(AGroup: TX2MenuBarGroup): Boolean;
var
  possibleGroup:      TX2MenuBarGroup;
  expandedGroup:      TX2MenuBarGroup;
  groupIndex:         Integer;
  group:              TX2MenuBarGroup;
  collapseGroups:     TList;
  collapseActions:    TX2MenuBarAnimateMultipleAction;
  collapseAction:     TX2MenuBarAnimateAction;

begin
  Result        := True;
  expandedGroup := AGroup;

  { If no group is specified, use the first appropriate group }
  if not Assigned(expandedGroup) then
  begin
    possibleGroup := nil;

    for groupIndex := 0 to Pred(Groups.Count) do
    begin
      if ItemVisible(Groups[groupIndex]) then
      begin
        if Groups[groupIndex].Expanded then
        begin
          expandedGroup := Groups[groupIndex];
          break;
        end else
          if not Assigned(possibleGroup) then
            possibleGroup := nil;
      end;
    end;

    if not Assigned(expandedGroup) then
    begin
      expandedGroup := possibleGroup;

      if Assigned(expandedGroup) then
      begin
        { Expand the first visible group. This will trigger DoAutoCollapse
          again. }
        Result := PerformExpand(expandedGroup, True);
        Exit;
      end;
    end;
  end;

  collapseGroups  := TList.Create;
  try
    { Determine which groups to collapse }
    for groupIndex := 0 to Pred(Groups.Count) do
    begin
      group := Groups[groupIndex];

      if (group <> expandedGroup) and (group.Expanded) then
        collapseGroups.Add(group);
    end;

    if collapseGroups.Count > 0 then
    begin
      { If more than one, collapse simultaniously }
      if collapseGroups.Count > 1 then
      begin
        { Check if all the groups are allowed to collapse first }
        for groupIndex := 0 to Pred(collapseGroups.Count) do
        begin
          group := TX2MenuBarGroup(collapseGroups[groupIndex]);
          DoCollapsing(group, Result);

          if not Result then
            Break;
        end;


        if Result then
        begin
          { Animate visible groups }
          collapseActions := TX2MenuBarAnimateMultipleAction.Create(Self);

          for groupIndex := 0 to Pred(collapseGroups.Count) do
          begin
            group           := TX2MenuBarGroup(collapseGroups[groupIndex]);

            if ItemVisible(group) then
            begin
              collapseAction  := TX2MenuBarAnimateAction(GetAnimateAction(group, False));

              if Assigned(collapseAction) then
                collapseActions.Add(collapseAction);
            end;
          end;

          if collapseActions.Count > 0 then
            PushAction(collapseActions)
          else
            FreeAndNil(collapseActions);


          { Add the collapse actions after the animation so OnCollapsed events
            raise afterwards. }
          for groupIndex := 0 to Pred(collapseGroups.Count) do
            PushAction(TX2MenuBarExpandAction.Create(Self, TX2MenuBarGroup(collapseGroups[groupIndex]),
                                                     False));
        end;
      end else
        Result := PerformExpand(TX2MenuBarGroup(collapseGroups[0]), False);
    end;
  finally
    FreeAndNil(collapseGroups);
  end;
end;


function TX2CustomMenuBar.DoAutoSelectItem(AGroup: TX2MenuBarGroup): Boolean;
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
      PerformSelectItem(newItem);
  end;
end;


function TX2CustomMenuBar.DoExpand(AGroup: TX2MenuBarGroup; AExpanding: Boolean): Boolean;
var
  allowed: Boolean;
  expandAction: TX2MenuBarAnimateAction;

begin
  Result  := False;
  allowed := True;

  if AExpanding then
    DoExpanding(AGroup, allowed)
  else
    DoCollapsing(AGroup, allowed);

  if not allowed then
    Exit;

  if AExpanding then
    if not PerformAutoCollapse(AGroup) then
      Exit;

      //  if not AExpanding then
//  begin
//    // #ToDo1 (MvR) 22-3-2007: ? anything ?
//  end else
//  begin
//    if not (PerformAutoCollapse(AGroup) and
//            PerformAutoSelectItem(AGroup)) then
//      Result  := False;
//  end;

  Result        := True;
  expandAction  := TX2MenuBarAnimateAction(GetAnimateAction(AGroup, AExpanding));
  if Assigned(expandAction) then
    PushAction(expandAction);

  PushAction(TX2MenuBarExpandAction.Create(Self, AGroup, AExpanding));
end;


function TX2CustomMenuBar.DoSelectItem(AItem: TX2CustomMenuBarItem): Boolean;
begin
  PushAction(TX2MenuBarSelectAction.Create(Self, AItem));
  Result  := True;
end;


function TX2CustomMenuBar.PerformAutoCollapse(AGroup: TX2MenuBarGroup): Boolean;
begin
  Result  := True;

  if AutoCollapse then
    Result  := DoAutoCollapse(AGroup);
end;


function TX2CustomMenuBar.PerformAutoSelectItem(AGroup: TX2MenuBarGroup): Boolean;
begin
  Result  := True;

  if AutoSelectItem then
    Result  := DoAutoSelectItem(AGroup);
end;


function TX2CustomMenuBar.PerformExpand(AGroup: TX2MenuBarGroup;
                                        AExpanding: Boolean): Boolean;
begin
  Result  := True;

  if AExpanding <> AGroup.Expanded then
    Result  := DoExpand(AGroup, AExpanding);
end;


function TX2CustomMenuBar.PerformSelectItem(AItem: TX2CustomMenuBarItem): Boolean;
begin
  Result := DoSelectItem(AItem);
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
      Painter.EndPaint;
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

  case ADirection of
    mbdUp:    groupIndex  := Pred(Groups.Count);
    mbdDown:  groupIndex  := 0;
  end;

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


function TX2CustomMenuBar.SelectFirst: TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result  := Iterate(FindEnabledItem);
    if Assigned(Result) then
      SelectedItem  := Result;
  end;
end;


function TX2CustomMenuBar.SelectLast: TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result    := Iterate(FindEnabledItem, mbdUp);
    if Assigned(Result) then
      SelectedItem  := Result;
  end;
end;


function TX2CustomMenuBar.SelectNext: TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result  := Iterate(FindEnabledItem, mbdDown, nil, SelectedItem);
    if Assigned(Result) then
      SelectedItem  := Result;
  end;
end;


function TX2CustomMenuBar.SelectPrior: TX2CustomMenuBarItem;
begin
  Result  := nil;

  if AllowInteraction then
  begin
    Result  := Iterate(FindEnabledItem, mbdUp, nil, SelectedItem);
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
      Invalidate;
    end else if AComponent = FImages then
    begin
      FImages := nil;
      Invalidate;
    end;

  inherited;
end;


procedure TX2CustomMenuBar.PainterUpdate(Sender: TX2CustomMenuBarPainter);
begin
  Invalidate;
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
    Invalidate;
end;


procedure TX2CustomMenuBar.GroupsUpdate(Sender: TObject; Item: TCollectionItem);
begin
  if Assigned(SelectedItem) and (not ItemEnabled(SelectedItem)) then
    SelectedItem  := nil;

  if Assigned(Designer) then
    Designer.ItemModified(Item as TX2CustomMenuBarItem);

  Invalidate;
end;


procedure TX2CustomMenuBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
                                     X, Y: Integer);
var
  hitTest:      TX2MenuBarHitTest;

begin
  if Button = mbLeft then
  begin
    if AllowInteraction then
    begin
      hitTest := Self.HitTest(X, Y);
      if Assigned(hitTest.Item) then
        SelectedItem  := hitTest.Item;
    end;
  end;

  inherited;
end;


procedure TX2CustomMenuBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  cursor: TCursor;

begin
  FLastMousePos := Point(X, Y);
  TestMousePos;

  cursor  := crDefault;
  if Assigned(HotItem) then
  begin
    if HotItem is TX2MenuBarGroup then
      cursor  := CursorGroup
    else if HotItem is TX2MenuBarItem then
      cursor  := CursorItem;
  end;

  if (cursor <> crDefault) and ItemEnabled(HotItem) then
  begin
    Windows.SetCursor(Screen.Cursors[cursor]);
    exit;
  end;

  inherited;
end;


procedure TX2CustomMenuBar.CMMouseLeave(var Msg: TMessage);
begin
  FLastMousePos := Point(-1, -1);
  FHotItem      := nil;
  Invalidate;
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
    Invalidate;
  end;
end;


procedure TX2CustomMenuBar.TestMousePos;
var
  hitTest:    TX2MenuBarHitTest;

begin
  hitTest := Self.HitTest(FLastMousePos.X, FLastMousePos.Y);
  if hitTest.Item <> FHotItem then
  begin
    HotItem := hitTest.Item;
    Invalidate;
  end;
end;


function TX2CustomMenuBar.GetMenuHeight: Integer;
var
  currentAction:    TX2CustomMenuBarAction;
  group:            TX2MenuBarGroup;
  groupIndex:       Integer;
  handled:          Boolean;
  item:             TX2MenuBarItem;
  itemHeight:       Integer;
  itemIndex:        Integer;
  menuBounds:       TRect;

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

    handled       := False;
    currentAction := GetCurrentAction;
    if Assigned(currentAction) then
    begin
      currentAction.GetItemHeight(group, itemHeight, handled);

      if handled then
        Inc(Result, itemHeight);
    end;

    if (not handled) and group.Expanded then
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


procedure TX2CustomMenuBar.UpdateScrollbar;
var
  currentAction:    TX2CustomMenuBarAction;
  scrollInfo:       TScrollInfo;

begin
  { Don't update the scrollbar while animating, prevents issues with the
    items buffer width if the scrollbar happens to show/hide during animation. }
  currentAction := GetCurrentAction;
  if Assigned(currentAction) and (not currentAction.AllowUpdateScrollbar) then
    exit;

  FillChar(scrollInfo, SizeOf(TScrollInfo), #0);
  scrollInfo.cbSize := SizeOf(TScrollInfo);
  scrollInfo.fMask  := SIF_PAGE or SIF_RANGE;

  if Scrollbar then
  begin
    scrollInfo.nMin   := 0;
    scrollInfo.nMax   := GetMenuHeight;
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


procedure TX2CustomMenuBar.ImagesChange(Sender: TObject);
begin
  Invalidate;
end;


procedure TX2CustomMenuBar.SetAllowCollapseAll(const Value: Boolean);
begin
  if Value <> FAllowCollapseAll then
  begin
    FAllowCollapseAll := Value;
    
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
      DoAutoSelectItem(nil);
  end;
end;


procedure TX2CustomMenuBar.SetBorderStyle(const Value: TBorderStyle);
begin
  if Value <> FBorderStyle then
  begin
    FBorderStyle := Value;
    RecreateWnd;
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
    RecreateWnd;
  end;
end;


procedure TX2CustomMenuBar.SetImages(const Value: TCustomImageList);
begin
  if Value <> FImages then
  begin
    if Assigned(FImages) then
    begin
      FImages.UnRegisterChanges(FImagesChangeLink);
      FImages.RemoveFreeNotification(Self);
    end;

    FImages := Value;

    if Assigned(FImages) then
    begin
      FImages.FreeNotification(Self);
      FImages.RegisterChanges(FImagesChangeLink);
    end;

    Invalidate;
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

    // #ToDo1 (MvR) 13-3-2007: check queue ?
    FPainter  := Value;

    if Assigned(FPainter) then
    begin
      FPainter.FreeNotification(Self);
      FPainter.AttachObserver(Self);
    end;

    Invalidate;
  end;
end;


procedure TX2CustomMenuBar.SetScrollbar(const Value: Boolean);
begin
  if Value <> FScrollbar then
  begin
    FScrollbar := Value;
    RecreateWnd;
  end;
end;


procedure TX2CustomMenuBar.SetSelectedItem(const Value: TX2CustomMenuBarItem);
var
  allowed:            Boolean;
  group:              TX2MenuBarGroup;
  selectItem:         TX2CustomMenuBarItem;

begin
  if Value <> FSelectedItem then
  begin
    if Assigned(Value) and (Value.MenuBar <> Self) then
      raise EInvalidItem.Create(SInvalidItem);


    allowed := (not Assigned(Value)) or ItemEnabled(Value);
    if allowed then
      DoSelectedChanging(Value, allowed);

      
    if allowed then
    begin
      selectItem  := Value;

      if Assigned(selectItem) then
      begin
        if selectItem is TX2MenuBarGroup then
        begin
          group := TX2MenuBarGroup(selectItem);

          { Check if the group should be collapsed }
          if group.Expanded and (not AutoCollapse) then
          begin
            PerformExpand(group, False);
          end else
          begin
            if group.Items.Count > 0 then
            begin
              PerformExpand(group, True);
              PerformAutoSelectItem(group);
            end else
            begin
              if PerformAutoCollapse(group) then
                PerformSelectItem(group);
            end;
          end;
        end else
        begin
          if (selectItem is TX2MenuBarItem) then
          begin
            group := TX2MenuBarItem(selectItem).Group;
            if Assigned(group) and (not group.Expanded) then
              PerformExpand(group, True);
          end;

          PerformSelectItem(selectItem);
        end;
      end else
        PerformSelectItem(selectItem);
    end;
  end;
end;

//procedure TX2CustomMenuBar.WMMouseWheel(var Message: TWMMouseWheel);
//begin
////  MessageBox(0, 'I gots a mousewheel', '', 0);
//end;
//
//procedure TX2CustomMenuBar.CMMouseWheel(var Message: TCMMouseWheel);
//begin
////  MessageBox(0, 'I gots a mousewheel', '', 0);
//end;


{ TX2MenuBarItemsEnumerator }
function TX2MenuBarItemsEnumerator.GetCurrent: TX2MenuBarItem;
begin
  Result := TX2MenuBarItem(inherited GetCurrent);
end;


{ TX2MenuBarGroupsEnumerator }
function TX2MenuBarGroupsEnumerator.GetCurrent: TX2MenuBarGroup;
begin
  Result := TX2MenuBarGroup(inherited GetCurrent);
end;

end.
