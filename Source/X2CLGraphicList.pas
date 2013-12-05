{
  :: X2CLGraphicList contains a container component for TGraphic
  :: descendants and a replacement for TImageList.
  ::
  :: Many thanks to Erik Stok. Before I could even work out the idea, he not
  :: only had a similar idea, but created TPngImageList and worked out many of
  :: the problems I thought we would face. His original (Dutch) article can
  :: be found at:
  ::   http://www.erikstok.net/delphi/artikelen/xpicons.html
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLGraphicList;

interface
uses
  Windows,

  Classes,
  Controls,
  Graphics;

{$IFDEF VER150}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_TYPE OFF}
{$ENDIF}

{$IFDEF VER180}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_TYPE OFF}
{$ENDIF}


type
  // Forward declarations
  TX2GraphicList      = class;
  TX2GraphicContainer = class;


  TX2GLCustomDrawImageProc = function(ACanvas: TCanvas;
                                      AGraphicList: TX2GraphicList;
                                      AIndex: Integer;
                                      AX, AY: Integer;
                                      AEnabled: Boolean): Boolean;

  {
    :$ Holds a single graphic.
  }
  TX2GraphicContainerItem = class(TComponent, IChangeNotifier)
  private
    FContainer:         TX2GraphicContainer;
    FPicture:           TPicture;
    FPictureName:       String;

    function GetIndex: Integer;
    procedure SetContainer(const Value: TX2GraphicContainer);
    procedure SetIndex(const Value: Integer);
    procedure SetPicture(const Value: TPicture);
    procedure SetPictureName(const Value: String);
  protected
    procedure Changed; virtual;
    procedure InternalSetContainer(const AContainer: TX2GraphicContainer); virtual;

    function GenerateName: String;

    procedure NotifierChanged;
    procedure IChangeNotifier.Changed = NotifierChanged;

    procedure ReadState(Reader: TReader); override;
    procedure SetParentComponent(AParent: TComponent); override;

    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetParentComponent: TComponent; override;
    function HasParent: Boolean; override;

    procedure AssignTo(Dest: TPersistent); override;
  public
    property Container:     TX2GraphicContainer read FContainer   write SetContainer stored False;
    property Index:         Integer             read GetIndex     write SetIndex stored False;
  published
    property Picture:       TPicture            read FPicture     write SetPicture;
    property PictureName:   String              read FPictureName write SetPictureName;
  end;

  {
    :$ Container object for graphics.

    :: TX2GraphicContainer holds all the original graphic data. Link a container
    :: to a TX2GraphicList to provide the graphics for various components.
  }
  TX2GraphicContainer   = class(TComponent)
  private
    FConversionRequired:  Boolean;
    FGraphics:          TList;
    FLists:               TList;

    function GetGraphicCount: Integer;
    function GetGraphics(Index: Integer): TX2GraphicContainerItem;
    procedure SetGraphics(Index: Integer; const Value: TX2GraphicContainerItem);
  protected
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure SetChildOrder(Component: TComponent; Order: Integer); override;
    procedure SetName(const NewName: TComponentName); override;

    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    procedure ConvertGraphics(Reader: TReader);
    procedure DefineProperties(Filer: TFiler); override;

    procedure AddGraphic(const AGraphic: TX2GraphicContainerItem); virtual;
    procedure RemoveGraphic(const AGraphic: TX2GraphicContainerItem); virtual;
    procedure UpdateGraphic(const AGraphic: TX2GraphicContainerItem); virtual;
    procedure MoveGraphic(const AGraphic: TX2GraphicContainerItem; ANewIndex: Integer); virtual;

    procedure RegisterList(const AList: TX2GraphicList);
    procedure UnregisterList(const AList: TX2GraphicList);

    property ConversionRequired: Boolean read FConversionRequired write FConversionRequired;

    property GraphicsList: TList read FGraphics;
    property Lists: TList read FLists;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    function IndexByName(const AName: String): Integer;
    function GraphicByName(const AName: String): TX2GraphicContainerItem;
    function PictureByName(const AName: String): TPicture;

    procedure AssignTo(Dest: TPersistent); override;

    property Graphics[Index: Integer]:  TX2GraphicContainerItem read GetGraphics  write SetGraphics;
    property GraphicCount:              Integer                 read GetGraphicCount;
  end;

  {
    :$ Defines the various modes for drawing a larger image.
  }
  TX2GLStretchMode  = (smCrop, smStretch);

  {
    :$ ImageList replacement for graphics.

    :: If you are only using components which use ImageList.Draw directly
    :: instead of the ImageList_Draw API (for ex. TMainMenu), set the Convert
    :: property to False to save some processing.
  }
  TX2GraphicList        = class(TImageList)
  private
    FBackground:      TColor;
    FContainer:       TX2GraphicContainer;
    FConvert:         Boolean;
    FEnabled:         Boolean;
    FStretchMode:     TX2GLStretchMode;
    FUpdateCount:     Integer;

    procedure SetBackground(const Value: TColor);
    procedure SetContainer(const Value: TX2GraphicContainer);
    procedure SetConvert(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
    procedure SetStretchMode(const Value: TX2GLStretchMode);
  protected
    procedure ReadData(Stream: TStream); override;
    procedure WriteData(Stream: TStream); override;

    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    function DrawGraphic(const AIndex: Integer;
                         const ACanvas: TCanvas;
                         const AX, AY: Integer;
                         const AEnabled: Boolean = True): Boolean;

    procedure DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer;
                     Style: Cardinal; Enabled: Boolean = True); override;

    procedure BuildImage(const AIndex: Integer; const AImage, AMask: TBitmap); virtual;
    procedure AddImage(const AIndex: Integer); virtual;
    procedure UpdateImage(const AIndex: Integer); virtual;
    procedure DeleteImage(const AIndex: Integer); virtual;
    procedure MoveImage(const AOldIndex, ANewIndex: Integer); virtual;

    function CanConvert: Boolean;

    procedure UpdateImageCount; virtual;
    procedure RebuildImages; virtual;

    procedure BeginUpdate;
    procedure EndUpdate;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure AssignTo(Dest: TPersistent); override;

    procedure Loaded; override;
    procedure Change; override;
  published
    property Background:    TColor                read FBackground  write SetBackground   default clBtnFace;
    property Container:     TX2GraphicContainer   read FContainer   write SetContainer;
    property Convert:       Boolean               read FConvert     write SetConvert      default True;
    property Enabled:       Boolean               read FEnabled     write SetEnabled      default True;
    property StretchMode:   TX2GLStretchMode      read FStretchMode write SetStretchMode  default smCrop;
  end;


  procedure X2GLRegisterCustomDrawImageProc(ACustomDrawImageProc: TX2GLCustomDrawImageProc);
  procedure X2GLUnregisterCustomDrawImageProc(ACustomDrawImageProc: TX2GLCustomDrawImageProc);


implementation
uses
  CommCtrl,
  Forms,
  ImgList,
  SysUtils,

  X2UtDelphiCompatibility;


var
  CustomDrawImageProcs: TList;


type
  PClass          = ^TClass;

  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[Word] of TRGBTriple;



  { Used for conversion purposes from the old collection-based Graphics property
    to the new TComponent structure. }
  TDeprecatedGraphicItem = class(TCollectionItem)
  private
    FName:              String;
    FPicture:           TPicture;

    procedure SetPicture(const Value: TPicture);
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
  published
    property Name:          String    read FName    write FName;
    property Picture:       TPicture  read FPicture write SetPicture;
  end;



procedure X2GLRegisterCustomDrawImageProc(ACustomDrawImageProc: TX2GLCustomDrawImageProc);
var
  procPointer: Pointer absolute ACustomDrawImageProc;

begin
  if CustomDrawImageProcs.IndexOf(procPointer) = -1 then
    CustomDrawImageProcs.Add(procPointer);
end;


procedure X2GLUnregisterCustomDrawImageProc(ACustomDrawImageProc: TX2GLCustomDrawImageProc);
var
  procPointer: Pointer absolute ACustomDrawImageProc;

begin
  CustomDrawImageProcs.Remove(procPointer);
end;


function CustomDrawImage(ACanvas: TCanvas; AGraphicList: TX2GraphicList;
                         AIndex: Integer; AX, AY: Integer; AEnabled: Boolean): Boolean;
var
  customProcIndex:  Integer;
  customProc:       TX2GLCustomDrawImageProc;

begin
  Result := False;

  for customProcIndex := Pred(CustomDrawImageProcs.Count) downto 0 do
  begin
    customProc  := TX2GLCustomDrawImageProc(CustomDrawImageProcs[customProcIndex]);

    if customProc(ACanvas, AGraphicList, AIndex, AX, AY, AEnabled) then
    begin
      Result := True;
      Break;
    end;
  end;
end;


{================ TX2GraphicContainerItem
  Initialization
========================================}
constructor TX2GraphicContainerItem.Create(AOwner: TComponent);
begin
  inherited;

  FPicture                := TPicture.Create;
  FPicture.PictureAdapter := Self;
end;


destructor TX2GraphicContainerItem.Destroy;
begin
  if Assigned(Container) then
    Container.RemoveGraphic(Self);

  FreeAndNil(FPicture);

  inherited;
end;


procedure TX2GraphicContainerItem.AssignTo(Dest: TPersistent);
begin
  if Dest is TX2GraphicContainerItem then
    with TX2GraphicContainerItem(Dest) do
    begin
      Picture := Self.Picture;
      PictureName := Self.PictureName;
    end
  else
    inherited;
end;


procedure TX2GraphicContainerItem.NotifierChanged;
begin
  Changed;
end;


procedure TX2GraphicContainerItem.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FContainer) then
    FContainer := nil;

  inherited;
end;


procedure TX2GraphicContainerItem.InternalSetContainer(const AContainer: TX2GraphicContainer);
begin
  if AContainer <> FContainer then
  begin
    if Assigned(FContainer) then
      FContainer.RemoveFreeNotification(Self);

    FContainer := AContainer;

    if Assigned(FContainer) then
      FContainer.FreeNotification(Self);
  end;
end;



procedure TX2GraphicContainerItem.Changed;
begin
  if Assigned(Container) then
    Container.UpdateGraphic(Self);
end;



function TX2GraphicContainerItem.GetParentComponent: TComponent;
begin
  if Assigned(Container) then
    Result := Container
  else
    Result := inherited GetParentComponent;
end;


function TX2GraphicContainerItem.HasParent: Boolean;
begin
  if Assigned(Container) then
    Result := True
  else
    Result := inherited HasParent;
end;



procedure TX2GraphicContainerItem.ReadState(Reader: TReader);
begin
  inherited;

  if Assigned(Reader.Parent) and (Reader.Parent is TX2GraphicContainer) then
    Container := TX2GraphicContainer(Reader.Parent);
end;


procedure TX2GraphicContainerItem.SetParentComponent(AParent: TComponent);
begin
  if (not (csLoading in ComponentState)) and
     Assigned(AParent) and (AParent is TX2GraphicContainer) then
    Container := TX2GraphicContainer(AParent);
end;


function TX2GraphicContainerItem.GetIndex: Integer;
begin
  Result := -1;
  if Assigned(Container) then
    Result := Container.GraphicsList.IndexOf(Self);
end;


procedure TX2GraphicContainerItem.SetContainer(const Value: TX2GraphicContainer);
begin
  if Value <> Container then
  begin
    if Assigned(Container) then
      Container.RemoveGraphic(Self);
  
    if Assigned(Value) then
      Value.AddGraphic(Self);
  
    if not (csLoading in ComponentState) then
      Name := GenerateName;
  end;
end;


procedure TX2GraphicContainerItem.SetIndex(const Value: Integer);
begin
  if Assigned(Container) then
    Container.MoveGraphic(Self, Value);
end;


procedure TX2GraphicContainerItem.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TX2GraphicContainerItem.SetPictureName(const Value: String);
begin
  if Value <> FPictureName then
  begin
    FPictureName := Value;

    if not (csLoading in ComponentState) then
      Name := GenerateName;
  end;
end;


function TX2GraphicContainerItem.GenerateName: String;
  function ValidComponentName(const AComponent: TComponent; const AName: String): Boolean;
  var
    checkOwner:   TComponent;
    existing:     TComponent;

  begin
    Result := True;
    checkOwner := AComponent;

    while Assigned(checkOwner) do
    begin
      existing := checkOwner.FindComponent(AName);

      if Assigned(existing) and (existing <> Self) then
      begin
        Result := False;
        exit;
      end;

      checkOwner := checkOwner.Owner;
    end;
  end;


const
  Alpha = ['A'..'Z', 'a'..'z', '_'];
  AlphaNumeric = Alpha + ['0'..'9'];

var
  charIndex:    Integer;
  counter:      Integer;
  resultName:   String;


begin
  if Assigned(Container) then
    Result := Container.Name
  else
    Result := 'GraphicContainerItem';

  for charIndex := 1 to Length(PictureName) do
    if CharInSet(PictureName[charIndex], AlphaNumeric) then
      Result := Result + PictureName[charIndex];


  resultName  := Result;
  counter     := 0;

  while not ValidComponentName(Self, Result) do
  begin
    Inc(counter);
    Result := resultName + IntToStr(counter); 
  end;
end;



{==================== TX2GraphicContainer
  Initialization
========================================}
constructor TX2GraphicContainer.Create(AOwner: TComponent);
begin
  inherited;

  FGraphics := TList.Create;
  FLists    := TList.Create;
end;


destructor TX2GraphicContainer.Destroy;
begin
  Clear;
  
  FreeAndNil(FGraphics);
  FreeAndNil(FLists);

  inherited;
end;


function TX2GraphicContainer.IndexByName(const AName: String): Integer;
var
  graphicIndex: Integer;

begin
  Result  := -1;

  for graphicIndex := Pred(GraphicCount) downto 0 do
    if SameText(Graphics[graphicIndex].PictureName, AName) then
    begin
      Result := graphicIndex;
      break;
    end;
end;


function TX2GraphicContainer.GraphicByName(const AName: String): TX2GraphicContainerItem;
var
  graphicIndex: Integer;

begin
  Result        := nil;
  graphicIndex  := IndexByName(AName);
  if graphicIndex > -1 then
    Result  := Graphics[graphicIndex];
end;


function TX2GraphicContainer.PictureByName(const AName: String): TPicture;
var
  graphic: TX2GraphicContainerItem;

begin
  Result  := nil;
  graphic := GraphicByName(AName);
  if Assigned(graphic) then
    Result  := graphic.Picture;
end;


procedure TX2GraphicContainer.AssignTo(Dest: TPersistent);
var
  destContainer: TX2GraphicContainer;
  graphicIndex: Integer;

begin
  if Dest is TX2GraphicContainer then
  begin
    destContainer := TX2GraphicContainer(Dest);
    destContainer.Clear;
  
    for graphicIndex := 0 to Pred(Self.GraphicCount) do
      with TX2GraphicContainerItem.Create(destContainer) do
      begin
        Assign(Self.Graphics[graphicIndex]);
        Container := destContainer;
      end;
  end
  else
    inherited;
end;



procedure TX2GraphicContainer.Clear;
begin
  while GraphicsList.Count > 0 do
    TX2GraphicContainerItem(GraphicsList.Last).Free;
end;


procedure TX2GraphicContainer.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  graphicIndex:   Integer;
  graphic:        TX2GraphicContainerItem;

begin
  for graphicIndex := 0 to Pred(GraphicCount) do
  begin
    graphic := Graphics[graphicIndex];
    Proc(graphic);
  end;
end;


procedure TX2GraphicContainer.SetChildOrder(Component: TComponent; Order: Integer);
begin
  if GraphicsList.IndexOf(Component) >= 0 then
    (Component as TX2GraphicContainerItem).Index := Order;
end;


procedure TX2GraphicContainer.SetName(const NewName: TComponentName);
var
  oldName: String;
  graphicIndex: Integer;

begin
  oldName := Self.Name;

  inherited;

  if Self.Name <> oldName then
  begin
    { Re-generate names for graphic components }
    for graphicIndex := 0 to Pred(GraphicCount) do
      Graphics[graphicIndex].Name := Graphics[graphicIndex].GenerateName;
  end;
end;


procedure TX2GraphicContainer.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;

  case Operation of
    opInsert:
      { In design-time, if a TX2GraphicList is added and it doesn't yet have
        a container, assign ourselves to it for lazy programmers (such as me :)) }
      if (csDesigning in ComponentState) and
         (AComponent is TX2GraphicList) and
         (not Assigned(TX2GraphicList(AComponent).Container)) then
        TX2GraphicList(AComponent).Container  := Self;
  
    opRemove:
      begin
        if (AComponent is TX2GraphicContainerItem) and
           (TX2GraphicContainerItem(AComponent).Container = Self) then
        begin
          RemoveGraphic(TX2GraphicContainerItem(AComponent));
        end
  
        else if AComponent is TX2GraphicList then
          Lists.Remove(AComponent);
      end;
  end;
end;


procedure TX2GraphicContainer.DefineProperties(Filer: TFiler);
begin
  inherited;

  { Previous versions used a Collection to hold the container items. As this
    wasn't Visual Inheritance-friendly, container items are now TComponents.
    This will convert the deprecated Graphics property. }
  Filer.DefineProperty('Graphics', ConvertGraphics, nil, False);
end;


procedure TX2GraphicContainer.ConvertGraphics(Reader: TReader);
var
  graphics: TCollection;
  graphicIndex: Integer;
  graphicItem: TDeprecatedGraphicItem;

begin
  graphics := TCollection.Create(TDeprecatedGraphicItem);
  try
    if Reader.NextValue = vaCollection then
    begin
      FConversionRequired := True;
      Clear;
  
      Reader.ReadValue;
      Reader.ReadCollection(graphics);
  
      for graphicIndex := 0 to Pred(graphics.Count) do
      begin
        graphicItem := TDeprecatedGraphicItem(graphics.Items[graphicIndex]);
  
        { Note: this create the item just fine, but won't add a line to the
          form's definition; the designer can take care of that. }
        with TX2GraphicContainerItem.Create(Self) do
        begin
          Picture := graphicItem.Picture;
          PictureName := graphicItem.Name;
          Container := Self;
        end;
      end;
    end;
  finally
    FreeAndNil(graphics);
  end;
end;


procedure TX2GraphicContainer.AddGraphic(const AGraphic: TX2GraphicContainerItem);
var
  graphicIndex:   Integer;
  listIndex:      Integer;

begin
  graphicIndex := GraphicsList.Add(AGraphic);
  AGraphic.InternalSetContainer(Self);
  AGraphic.FreeNotification(Self);
  
  for listIndex := Pred(Lists.Count) downto 0 do
    TX2GraphicList(Lists[listIndex]).AddImage(graphicIndex);
end;


procedure TX2GraphicContainer.RemoveGraphic(const AGraphic: TX2GraphicContainerItem);
var
  graphicIndex:   Integer;
  listIndex:      Integer;

begin
  graphicIndex := AGraphic.Index;
  
  if graphicIndex > -1 then
  begin
    if not (csDestroying in ComponentState) then
    begin
      for listIndex := Pred(Lists.Count) downto 0 do
        TX2GraphicList(Lists[listIndex]).DeleteImage(graphicIndex);
    end;
  
    GraphicsList.Delete(graphicIndex);
    AGraphic.InternalSetContainer(nil);
  end;
end;


procedure TX2GraphicContainer.UpdateGraphic(const AGraphic: TX2GraphicContainerItem);
var
  graphicIndex: Integer;
  listIndex:    Integer;

begin
  graphicIndex := AGraphic.Index;
  
  if graphicIndex > -1 then
  begin
    for listIndex := Pred(Lists.Count) downto 0 do
      TX2GraphicList(Lists[listIndex]).UpdateImage(graphicIndex);
  end;
end;


procedure TX2GraphicContainer.MoveGraphic(const AGraphic: TX2GraphicContainerItem; ANewIndex: Integer);
var
  count:      Integer;
  curIndex:   Integer;
  newIndex:   Integer;
  listIndex:  Integer;

begin
  if not Assigned(AGraphic.Container) then
    Exit;
  
  if AGraphic.Container <> Self then
  begin
    AGraphic.Container.MoveGraphic(AGraphic, ANewIndex);
    Exit;
  end;
  
  
  curIndex := AGraphic.Index;
  
  if curIndex > -1 then
  begin
    count     := GraphicsList.Count;
    newIndex  := ANewIndex;
  
    if newIndex < 0 then
      newIndex := 0;
  
    if newIndex >= count then
      newIndex := Pred(count);
  
    if newIndex <> curIndex then
    begin
      GraphicsList.Move(curIndex, newIndex);
  
      for listIndex := Pred(Lists.Count) downto 0 do
        TX2GraphicList(Lists[listIndex]).MoveImage(curIndex, newIndex);
    end;
  end;
end;



procedure TX2GraphicContainer.RegisterList(const AList: TX2GraphicList);
begin
  if Lists.IndexOf(AList) = -1 then
  begin
    Lists.Add(AList);
    AList.FreeNotification(Self);
  end;
end;


procedure TX2GraphicContainer.UnregisterList(const AList: TX2GraphicList);
begin
  if Lists.Remove(AList) > -1 then
    AList.RemoveFreeNotification(Self);
end;



function TX2GraphicContainer.GetGraphicCount: Integer;
begin
  Result := GraphicsList.Count;
end;


function TX2GraphicContainer.GetGraphics(Index: Integer): TX2GraphicContainerItem;
begin
  Result := TX2GraphicContainerItem(GraphicsList[Index]);
end;

procedure TX2GraphicContainer.SetGraphics(Index: Integer; const Value: TX2GraphicContainerItem);
begin
  TX2GraphicContainerItem(GraphicsList[Index]).Assign(Value);
end;



{========================= TX2GraphicList
  Initialization
========================================}
constructor TX2GraphicList.Create(AOwner: TComponent);
begin
  inherited;

  FBackground   := clBtnFace;
  BkColor       := clNone;
  FConvert      := True;
  FEnabled      := True;
  FStretchMode  := smCrop;
end;


procedure TX2GraphicList.Loaded;
begin
  inherited;

  RebuildImages;
end;


procedure TX2GraphicList.Change;
begin
  inherited;

  if FUpdateCount = 0 then
    RebuildImages;
end;


destructor TX2GraphicList.Destroy;
begin
  SetContainer(nil);

  inherited;
end;


procedure TX2GraphicList.AssignTo(Dest: TPersistent);
begin
  if Dest is TX2GraphicList then
    with TX2GraphicList(Dest) do
    begin
      Background  := Self.Background;
      Container   := Self.Container;
      Enabled     := Self.Enabled;
      StretchMode := Self.StretchMode;
    end
  else
    inherited;
end;



{========================= TX2GraphicList
  Graphics
========================================}
function TX2GraphicList.DrawGraphic(const AIndex: Integer;
                                    const ACanvas: TCanvas;
                                    const AX, AY: Integer;
                                    const AEnabled: Boolean = True): Boolean;
  procedure InternalDrawGraphic(const ADest: TCanvas;
                                const ADestX, ADestY: Integer);
  var
    bmpTemp:      TBitmap;
    iHeight:      Integer;
    iWidth:       Integer;
    rDest:        TRect;
    rSource:      TRect;

  begin
    with FContainer.Graphics[AIndex].Picture do
      if (Width <= Self.Width) and (Height <= Self.Height) then
        ADest.Draw(ADestX, ADestY, Graphic)
      else
      begin
        iWidth  := Width;
        iHeight := Height;

        if iWidth > Self.Width then
          iWidth  := Self.Width;

        if iHeight > Self.Height then
          iHeight := Self.Height;

        rDest               := Rect(ADestX, ADestY,
                                    ADestX + iWidth, ADestY + iHeight);
        rSource := Rect(0, 0, iWidth, iHeight);

        case FStretchMode of
          smCrop:
            begin
              bmpTemp := TBitmap.Create;
              try
                with bmpTemp do
                begin
                  Width       := iWidth;
                  Height      := iHeight;
                  PixelFormat := pf24bit;

                  // Copy existing content
                  Canvas.CopyRect(rSource, ADest, rDest);

                  // Overlay graphic
                  Canvas.Draw(0, 0, Graphic);

                  // Copy back
                  ADest.CopyRect(rDest, Canvas, rDest);
                end;
              finally
                FreeAndNil(bmpTemp);
              end;
            end;
          smStretch:
            // Note: some TGraphic's don't support StretchDraw and will
            //       always crop. Nothing we can do about that...
            ADest.StretchDraw(rDest, Graphic);
        end;
      end;
  end;

var
  bmpBackground:        TBitmap;
  bmpBlend:             TBitmap;
  iX:                   Integer;
  iY:                   Integer;
  pBackground:          PRGBTripleArray;
  pBlend:               PRGBTripleArray;

begin
  Result  := False;
  if not Assigned(FContainer) then
    exit;

  if (AIndex < 0) or (AIndex >= FContainer.GraphicCount) then
    exit;

  if (not Assigned(FContainer.Graphics[AIndex].Picture)) or
     (not Assigned(FContainer.Graphics[AIndex].Picture.Graphic)) or
     (FContainer.Graphics[AIndex].Picture.Graphic.Empty) then
    exit;

  { First see if any custom draw handlers want to draw the image }
  if not CustomDrawImage(ACanvas, Self, AIndex, AX, AY, AEnabled) then
  begin
    if AEnabled then
      { Enabled, simply draw the graphic }
      InternalDrawGraphic(ACanvas, AX, AY)
    else
    begin
      { Disabled, need to draw the image using 50% transparency. There's only
        one problem; not all TGraphic's support that, and neither is there a
        generic way of determining a pixel's transparency. So instead, we
        blend the background with a copy of the background with the graphic
        painted on it... }
      bmpBackground := TBitmap.Create;
      bmpBlend      := TBitmap.Create;
      try
        { Get background from canvas }
        with bmpBackground do
        begin
          Width       := Self.Width;
          Height      := Self.Height;
          PixelFormat := pf24bit;
          Canvas.CopyRect(Rect(0, 0, Width, Height), ACanvas,
                          Rect(AX, AY, AX + Width, AY + Height));
        end;
  
        bmpBlend.Assign(bmpBackground);
        InternalDrawGraphic(bmpBlend.Canvas, 0, 0);
  
        { Blend graphic with background at 50% }
        for iY  := 0 to bmpBackground.Height - 1 do
        begin
          pBackground := bmpBackground.ScanLine[iY];
          pBlend      := bmpBlend.ScanLine[iY];
  
          for iX  := 0 to bmpBackground.Width - 1 do
            with pBlend^[iX] do
            begin
              rgbtBlue    := ((pBackground^[iX].rgbtBlue shl 7) +
                              (rgbtBlue shl 7)) shr 8;
              rgbtGreen   := ((pBackground^[iX].rgbtGreen shl 7) +
                              (rgbtGreen shl 7)) shr 8;
              rgbtRed     := ((pBackground^[iX].rgbtRed shl 7) +
                              (rgbtRed shl 7)) shr 8;
            end;
        end;
  
        { Copy blended graphic back }
        ACanvas.Draw(AX, AY, bmpBlend);
      finally
        FreeAndNil(bmpBlend);
        FreeAndNil(bmpBackground);
      end;
    end;
  end;

  Result  := True;
end;


procedure TX2GraphicList.DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer;
                                Style: Cardinal; Enabled: Boolean = True);
begin
  DrawGraphic(Index, Canvas, X, Y, Enabled);
end;


procedure TX2GraphicList.BuildImage(const AIndex: Integer;
                                    const AImage, AMask: TBitmap);
  function RGBTriple(const AColor: TColor): TRGBTriple;
  var
    cColor:       Cardinal;

  begin
    cColor  := ColorToRGB(AColor);

    with Result do
    begin
      rgbtBlue    := GetBValue(cColor);
      rgbtGreen   := GetGValue(cColor);
      rgbtRed     := GetRValue(cColor);
    end;
  end;

  function SameColor(const AColor1, AColor2: TRGBTriple): Boolean;
  begin
    Result  := CompareMem(@AColor1, @AColor2, SizeOf(TRGBTriple));
  end;

var
  bmpCompare: TBitmap;
  bOk:        Boolean;
  cImage:     TRGBTriple;
  cMask:      TRGBTriple;
  iBit:       Integer;
  iPosition:  Integer;
  iX:         Integer;
  iY:         Integer;
  pCompare:   PRGBTripleArray;
  pImage:     PRGBTripleArray;
  pMask:      PByteArray;

begin
  // Technique used here: draw the image twice, once on the background color,
  // once on black. Loop through the two images, check if a pixel is the
  // background color on one image and black on the other; if so then it's
  // fully transparent. This doesn't eliminate all problems with alpha images,
  // but it's the best option (at least for pre-XP systems).
  //
  // Note that components using ImageList.Draw will have full alpha support,
  // this routine only ensures compatibility with ImageList_Draw components.
  // TMenu is among the first, TToolbar and similar are amongst the latter.
  with AImage do
  begin
    Width               := Self.Width;
    Height              := Self.Height;
    PixelFormat         := pf24bit;
  
    with Canvas do
    begin
      Brush.Color       := FBackground;
      FillRect(Rect(0, 0, Width, Height));
      bOk               := DrawGraphic(AIndex, Canvas, 0, 0, FEnabled);
    end;
  end;
  
  with AMask do
  begin
    Width               := Self.Width;
    Height              := Self.Height;
    PixelFormat         := pf1bit;
  
    with Canvas do
    begin
      Brush.Color       := clBlack;
      FillRect(Rect(0, 0, Width, Height));
    end;
  end;
  
  // No point in looping through the
  // images if they're blank anyways...
  if not bOk then
    exit;
  
  bmpCompare  := TBitmap.Create;
  try
    with bmpCompare do
    begin
      Width               := Self.Width;
      Height              := Self.Height;
      PixelFormat         := pf24bit;
  
      with Canvas do
      begin
        Brush.Color       := clBlack;
        FillRect(Rect(0, 0, Width, Height));
        DrawGraphic(AIndex, Canvas, 0, 0, FEnabled);
      end;
    end;
  
    cImage  := RGBTriple(FBackground);
    cMask   := RGBTriple(clBlack);
  
    for iY  := 0 to AImage.Height - 1 do
    begin
      pImage    := AImage.ScanLine[iY];
      pCompare  := bmpCompare.ScanLine[iY];
      pMask     := AMask.ScanLine[iY];
      iPosition := 0;
      iBit      := 128;
  
      for iX  := 0 to AImage.Width - 1 do
      begin
        if iBit = 128 then
          pMask^[iPosition] := 0;
  
        if SameColor(pImage^[iX], cImage) and
           SameColor(pCompare^[iX], cMask) then
        begin
          // Transparent pixel
          FillChar(pImage^[iX], SizeOf(TRGBTriple), $00);
          pMask^[iPosition] := pMask^[iPosition] or iBit;
        end;
  
        iBit  := iBit shr 1;
        if iBit < 1 then
        begin
          iBit  := 128;
          Inc(iPosition);
        end;
      end;
    end;
  finally
    FreeAndNil(bmpCompare);
  end;
end;


procedure TX2GraphicList.AddImage(const AIndex: Integer);
var
  bmpImage:       TBitmap;
  bmpMask:        TBitmap;

begin
  if csLoading in ComponentState then
    exit;

  if CanConvert then
  begin
    BeginUpdate;
    try
      bmpImage  := TBitmap.Create;
      bmpMask   := TBitmap.Create;
      try
        BuildImage(AIndex, bmpImage, bmpMask);
        Assert(AIndex <= Self.Count, 'AAAH! Images out of sync! *panics*');

        if AIndex = Self.Count then
          Add(bmpImage, bmpMask)
        else
          Insert(AIndex, bmpImage, bmpMask);
      finally
        FreeAndNil(bmpMask);
        FreeAndNil(bmpImage);
      end;
    finally
      EndUpdate;
    end;
  end else
    UpdateImageCount;
end;


procedure TX2GraphicList.UpdateImage(const AIndex: Integer);
var
  bmpImage:       TBitmap;
  bmpMask:        TBitmap;

begin
  if csLoading in ComponentState then
    exit;
  
  if not CanConvert then
    Exit;
  
  if (AIndex < 0) or (AIndex >= Count) then
    exit;
  
  BeginUpdate;
  try
    bmpImage  := TBitmap.Create;
    bmpMask   := TBitmap.Create;
    try
      BuildImage(AIndex, bmpImage, bmpMask);
      Replace(AIndex, bmpImage, bmpMask);
    finally
      FreeAndNil(bmpMask);
      FreeAndNil(bmpImage);
    end;
  finally
    EndUpdate;
  end;
end;


procedure TX2GraphicList.DeleteImage(const AIndex: Integer);
begin
  if CanConvert then
  begin
    BeginUpdate;
    try
      Delete(AIndex);
    finally
      EndUpdate;
    end;
  end else
    UpdateImageCount;
end;


procedure TX2GraphicList.MoveImage(const AOldIndex, ANewIndex: Integer);
begin
  if CanConvert then
  begin
    BeginUpdate;
    try
      Move(AOldIndex, ANewIndex);
    finally
      EndUpdate;
    end;
  end;
end;


procedure TX2GraphicList.UpdateImageCount;
begin
  if not Assigned(Container) then
    Clear
  else
    ImageList_SetImageCount(Self.Handle, Container.GraphicCount);
end;


procedure TX2GraphicList.RebuildImages;
var
  iIndex:       Integer;

begin
  if (csLoading in ComponentState) or
     (Width = 0) or (Height = 0) then
    Exit;

  BeginUpdate;
  try
    if not Assigned(FContainer) then
    begin
      Clear;
    end else
    begin
      UpdateImageCount;

      if CanConvert then
      begin
        for iIndex  := 0 to Pred(FContainer.GraphicCount) do
          UpdateImage(iIndex);
      end;
    end;
  finally
    EndUpdate;
    inherited Change;
  end;
end;


function TX2GraphicList.CanConvert: Boolean;
begin
  Result := FConvert or (csDesigning in ComponentState);
end;


{========================= TX2GraphicList
  Properties
========================================}
procedure TX2GraphicList.ReadData(Stream: TStream);
begin
end;


procedure TX2GraphicList.WriteData(Stream: TStream);
begin
end;


procedure TX2GraphicList.Notification(AComponent: TComponent;
                                      Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent = FContainer) then
    SetContainer(nil);

  inherited;
end;


procedure TX2GraphicList.SetBackground(const Value: TColor);
begin
  FBackground := Value;
  RebuildImages;
end;


procedure TX2GraphicList.SetContainer(const Value: TX2GraphicContainer);
begin
  if Assigned(FContainer) then
  begin
    FContainer.UnregisterList(Self);
    FContainer.RemoveFreeNotification(Self);
  end;
  
  FContainer := Value;
  
  if Assigned(FContainer) then
  begin
    FContainer.FreeNotification(Self);
    FContainer.RegisterList(Self);
  end;
  
  RebuildImages;
end;


procedure TX2GraphicList.SetConvert(const Value: Boolean);
begin
  if Value <> FConvert then
  begin
    FConvert  := Value;
    RebuildImages;
  end;
end;


procedure TX2GraphicList.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
  RebuildImages;
end;


procedure TX2GraphicList.SetStretchMode(const Value: TX2GLStretchMode);
begin
  FStretchMode := Value;
  RebuildImages;
end;


procedure TX2GraphicList.BeginUpdate;
begin
  Inc(FUpdateCount);
end;


procedure TX2GraphicList.EndUpdate;
begin
  Assert(FUpdateCount > 0, 'EndUpdate without matching BeginUpdate!');
  Dec(FUpdateCount);
end;



{ TDeprecatedGraphicItem }
constructor TDeprecatedGraphicItem.Create(Collection: TCollection);
begin
  inherited;

  FPicture  := TPicture.Create;
end;


destructor TDeprecatedGraphicItem.Destroy;
begin
  FreeAndNil(FPicture);

  inherited;
end;


procedure TDeprecatedGraphicItem.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
end;


initialization
  RegisterClass(TX2GraphicContainerItem);
  CustomDrawImageProcs  := TList.Create;

finalization
  FreeAndNil(CustomDrawImageProcs);

end.
