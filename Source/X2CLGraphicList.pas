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
{$ENDIF}


type
  // Forward declarations
  TX2GraphicList      = class;
  TX2GraphicContainer = class;

  {
    :$ Holds a single graphic.
  }
  TX2GraphicCollectionItem  = class(TCollectionItem, IChangeNotifier)
  private
    FName:              String;
    FPicture:           TPicture;

    procedure SetPicture(const Value: TPicture);
    procedure SetName(const Value: String);
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef(): Integer; stdcall;
    function _Release(): Integer; stdcall;

    function GetDisplayName(): String; override;

    procedure NotifierChanged();
    procedure IChangeNotifier.Changed = NotifierChanged;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy(); override;

    procedure AssignTo(Dest: TPersistent); override;
  published
    property Name:          String    read FName    write SetName;
    property Picture:       TPicture  read FPicture write SetPicture;
  end;

  {
    :$ Holds a collection of graphics.
  }
  TX2GraphicCollection      = class(TCollection)
  private
    FContainer:       TX2GraphicContainer;

    function GetItem(Index: Integer): TX2GraphicCollectionItem;
    procedure SetItem(Index: Integer; Value: TX2GraphicCollectionItem);
  protected
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); override;
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(const AContainer: TX2GraphicContainer);

    function Add(): TX2GraphicCollectionItem;

    property Items[Index: Integer]:   TX2GraphicCollectionItem  read GetItem
                                                                write SetItem; default;
  end;

  {
    :$ Container object for graphics.

    :: TX2GraphicContainer holds all the original graphic data. Link a container
    :: to a TX2GraphicList to provide the graphics for various components.
  }
  TX2GraphicContainer   = class(TComponent)
  private
    FGraphics:        TX2GraphicCollection;
    FLists:           TList;

    procedure SetGraphics(const Value: TX2GraphicCollection);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Notify(Item: TCollectionItem; Action: TCollectionNotification); virtual;
    procedure Update(Item: TCollectionItem); virtual;

    procedure RegisterList(const AList: TX2GraphicList);
    procedure UnregisterList(const AList: TX2GraphicList);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    procedure AssignTo(Dest: TPersistent); override;
  published
    property Graphics:      TX2GraphicCollection  read FGraphics  write SetGraphics;
  end;

  {
    :$ Defines the various modes for drawing a larger image.
  }
  TX2GLStretchMode  = (smCrop, smStretch);

  {
    :$ ImageList replacement for graphics.
  }
  TX2GraphicList        = class(TImageList)
  private
    FBackground:      TColor;
    FContainer:       TX2GraphicContainer;
    FEnabled:         Boolean;
    FStretchMode:     TX2GLStretchMode;
    FUpdateCount:     Integer;

    procedure SetBackground(const Value: TColor);
    procedure SetContainer(const Value: TX2GraphicContainer);
    procedure SetStretchMode(const Value: TX2GLStretchMode);
    procedure SetEnabled(const Value: Boolean);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    function DrawGraphic(const AIndex: Integer;
                         const ACanvas: TCanvas;
                         const AX, AY: Integer;
                         const AEnabled: Boolean = True): Boolean;

    procedure DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer;
                     Style: Cardinal; Enabled: Boolean = True); override;

    procedure CreateImage(const AIndex: Integer; var AImage, AMask: TBitmap); virtual;
    procedure AddImage(const AIndex: Integer); virtual;
    procedure UpdateImage(const AIndex: Integer); virtual;
    procedure DeleteImage(const AIndex: Integer); virtual;

    procedure RebuildImages(); virtual;

    procedure BeginUpdate();
    procedure EndUpdate();
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    procedure AssignTo(Dest: TPersistent); override;

    procedure Loaded(); override;
    procedure Change(); override;
  published
    property Background:    TColor                read FBackground  write SetBackground   default clBtnFace;
    property Container:     TX2GraphicContainer   read FContainer   write SetContainer;
    property Enabled:       Boolean               read FEnabled     write SetEnabled      default True;
    property StretchMode:   TX2GLStretchMode      read FStretchMode write SetStretchMode  default smCrop;
  end;

implementation
uses
  ImgList,
  SysUtils;

type
  PClass          = ^TClass;

  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[Word] of TRGBTriple;



{=============== TX2GraphicCollectionItem
  Initialization
========================================}
constructor TX2GraphicCollectionItem.Create;
begin
  FPicture                := TPicture.Create();
  FPicture.PictureAdapter := Self;

  inherited;
end;

destructor TX2GraphicCollectionItem.Destroy;
begin
  FreeAndNil(FPicture);

  inherited;
end;


procedure TX2GraphicCollectionItem.AssignTo;
begin
  if Dest is TX2GraphicCollectionItem then
    with TX2GraphicCollectionItem(Dest) do
      Picture := Self.Picture
  else
    inherited;
end;


function TX2GraphicCollectionItem.QueryInterface;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TX2GraphicCollectionItem._AddRef;
begin
  Result  := -1;
end;

function TX2GraphicCollectionItem._Release;
begin
  Result  := -1;
end;


function TX2GraphicCollectionItem.GetDisplayName;
begin
  if Length(FName) > 0 then
    Result  := FName
  else
    Result  := inherited GetDisplayName();
end;


procedure TX2GraphicCollectionItem.NotifierChanged;
begin
  Changed(False);
end;

procedure TX2GraphicCollectionItem.SetName;
begin
  FName := Value;
  Changed(False);
end;

procedure TX2GraphicCollectionItem.SetPicture;
begin
  FPicture.Assign(Value);
end;


{=================== TX2GraphicCollection
  Item Management
========================================}
constructor TX2GraphicCollection.Create;
begin
  inherited Create(TX2GraphicCollectionItem);

  FContainer  := AContainer;
end;


function TX2GraphicCollection.Add;
begin
  Result  := TX2GraphicCollectionItem(inherited Add());
end;


procedure TX2GraphicCollection.Notify;
begin
  inherited;
  
  if Assigned(FContainer) then
    FContainer.Notify(Item, Action);
end;

procedure TX2GraphicCollection.Update;
begin
  inherited;

  if Assigned(FContainer) then
    FContainer.Update(Item);
end;


function TX2GraphicCollection.GetItem;
begin
  Result  := TX2GraphicCollectionItem(inherited GetItem(Index));
end;

procedure TX2GraphicCollection.SetItem;
begin
  inherited SetItem(Index, Value);
end;


{==================== TX2GraphicContainer
  Initialization
========================================}
constructor TX2GraphicContainer.Create;
begin
  inherited;

  FGraphics := TX2GraphicCollection.Create(Self);
  FLists    := TList.Create();
end;

destructor TX2GraphicContainer.Destroy;
begin
  FreeAndNil(FGraphics);
  FreeAndNil(FLists);

  inherited;
end;


procedure TX2GraphicContainer.AssignTo;
begin
  if Dest is TX2GraphicContainer then
    with TX2GraphicContainer(Dest) do
      Graphics  := Self.Graphics
  else
    inherited;
end;



procedure TX2GraphicContainer.Notification;
begin
  if not Assigned(FLists) then
    exit;

  if Operation = opRemove then
    FLists.Remove(AComponent)
  else
    // In design-time, if a TX2GraphicList is added and it doesn't yet have
    // a container, assign ourselves to it for lazy programmers (such as me :))
    if (Operation = opInsert) and (csDesigning in ComponentState) and
       (AComponent is TX2GraphicList) and
       (not Assigned(TX2GraphicList(AComponent).Container)) then
      TX2GraphicList(AComponent).Container  := Self;

  inherited;
end;

procedure TX2GraphicContainer.Notify;
var
  iList:      Integer;

begin
  case Action of
    cnAdded:
      for iList := FLists.Count - 1 downto 0 do
        TX2GraphicList(FLists[iList]).AddImage(Item.Index);
    cnDeleting:
      for iList := FLists.Count - 1 downto 0 do
        TX2GraphicList(FLists[iList]).DeleteImage(Item.Index);
  end;
end;

procedure TX2GraphicContainer.Update;
var
  iList:      Integer;

begin
  if Assigned(Item) then
    for iList := FLists.Count - 1 downto 0 do
      TX2GraphicList(FLists[iList]).UpdateImage(Item.Index)
  else
    for iList := FLists.Count - 1 downto 0 do
      TX2GraphicList(FLists[iList]).RebuildImages();
end;


procedure TX2GraphicContainer.RegisterList;
begin
  if FLists.IndexOf(AList) = -1 then
    FLists.Add(AList);
end;

procedure TX2GraphicContainer.UnregisterList;
begin
  FLists.Remove(AList);
end;


procedure TX2GraphicContainer.SetGraphics;
begin
  FGraphics.Assign(Value);
end;



{========================= TX2GraphicList
  Initialization
========================================}
constructor TX2GraphicList.Create;
begin
  inherited;

  FBackground   := clBtnFace;
  BkColor       := clNone;
  FEnabled      := True;
  FStretchMode  := smCrop;
end;

procedure TX2GraphicList.Loaded;
begin
  inherited;

  RebuildImages();
end;

procedure TX2GraphicList.Change;
begin
  inherited;

  if FUpdateCount = 0 then
    RebuildImages();
end;


destructor TX2GraphicList.Destroy;
begin
  SetContainer(nil);

  inherited;
end;


procedure TX2GraphicList.AssignTo;
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
function TX2GraphicList.DrawGraphic;
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
              bmpTemp := TBitmap.Create();
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
  if (AIndex < 0) or (AIndex >= Count) then
    exit;

  if (not Assigned(FContainer)) or
     (not Assigned(FContainer.Graphics[AIndex].Picture.Graphic)) or
     (FContainer.Graphics[AIndex].Picture.Graphic.Empty) then
    exit;

  if AEnabled then
    // Enabled, simply draw the graphic
    InternalDrawGraphic(ACanvas, AX, AY)
  else
  begin
    // Disabled, need to draw the image using 50% transparency. There's only
    // one problem; not all TGraphic's support that, and neither is there a
    // generic way of determining a pixel's transparency. So instead, we
    // blend the background with a copy of the background with the graphic
    // painted on it...
    bmpBackground := TBitmap.Create();
    bmpBlend      := TBitmap.Create();
    try
      // Get background from canvas
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

      // Blend graphic with background at 50%
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

      // Copy blended graphic back
      ACanvas.Draw(AX, AY, bmpBlend);
    finally
      FreeAndNil(bmpBlend);
      FreeAndNil(bmpBackground);
    end;
  end;

  Result  := True;
end;

procedure TX2GraphicList.DoDraw;
begin
  DrawGraphic(Index, Canvas, X, Y, Enabled);
end;


procedure TX2GraphicList.CreateImage;
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

  bmpCompare  := TBitmap.Create();
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

procedure TX2GraphicList.AddImage;
var
  bmpImage:       TBitmap;
  bmpMask:        TBitmap;

begin
  if csLoading in ComponentState then
    exit;

  BeginUpdate();
  try
    bmpImage  := TBitmap.Create();
    bmpMask   := TBitmap.Create();
    try
      CreateImage(AIndex, bmpImage, bmpMask);
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
    EndUpdate();
  end;
end;

procedure TX2GraphicList.UpdateImage;
var
  bmpImage:       TBitmap;
  bmpMask:        TBitmap;

begin
  if csLoading in ComponentState then
    exit;

  BeginUpdate();
  try
    bmpImage  := TBitmap.Create();
    bmpMask   := TBitmap.Create();
    try
      CreateImage(AIndex, bmpImage, bmpMask);
      Replace(AIndex, bmpImage, bmpMask);
    finally
      FreeAndNil(bmpMask);
      FreeAndNil(bmpImage);
    end;
  finally
    EndUpdate();
  end;
end;

procedure TX2GraphicList.DeleteImage;
begin
  BeginUpdate();
  try
    Delete(AIndex);
  finally
    EndUpdate();
  end;
end;


procedure TX2GraphicList.RebuildImages;
var
  iIndex:       Integer;

begin
  if (csLoading in ComponentState) or
     (Width = 0) or (Height = 0) then
    exit;

  BeginUpdate();
  try
    Clear();

    if not Assigned(FContainer) then
      exit;

    for iIndex  := 0 to FContainer.Graphics.Count - 1 do
      AddImage(iIndex);
  finally
    EndUpdate();
  end;
end;


{========================= TX2GraphicList
  Properties
========================================}
procedure TX2GraphicList.DefineProperties;
var
  pType:        TClass;

begin
  // TCustomImageList defines the Bitmap property, we don't want that
  // (since the ImageList will be generated from a GraphicContainer).
  // Erik's solution was to override Read/WriteData, but in Delphi 6 those
  // aren't virtual yet. Instead we skip TCustomImageList's DefineProperties.
  //
  // The trick here is to modify the ClassType so the VMT of descendants
  // (include ourself!) is ignored and only TComponent.DefineProperties
  // is called...
  pType           := Self.ClassType;
  PClass(Self)^   := TComponent;
  try
    DefineProperties(Filer);
  finally
    PClass(Self)^ := pType;
  end;
end;

procedure TX2GraphicList.Notification;
begin
  if (Operation = opRemove) and (AComponent = FContainer) then
    FContainer  := nil;
    
  inherited;
end;


procedure TX2GraphicList.SetBackground;
begin
  FBackground := Value;
  RebuildImages();
end;

procedure TX2GraphicList.SetContainer;
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

  RebuildImages();
end;

procedure TX2GraphicList.SetEnabled;
begin
  FEnabled := Value;
  RebuildImages();
end;

procedure TX2GraphicList.SetStretchMode;
begin
  FStretchMode := Value;
  RebuildImages();
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

end.
