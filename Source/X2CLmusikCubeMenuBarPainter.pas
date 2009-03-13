{
  :: Implements a musikCube-style painter for the X2MenuBar.
  ::
  :: Part of the X2Software Component Library
  ::    http://www.x2software.net/
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLmusikCubeMenuBarPainter;

interface
uses
  Classes,
  Graphics,
  ImgList,
  Windows,

  X2CLGraphics,
  X2CLMenuBar;

type
  TX2MenuBarmCColor   = class(TPersistent)
  private
    FBorder:            TX2Color32;
    FFill:              TX2Color32;
    FDefaultBorder:     TX2Color32;
    FDefaultFill:       TX2Color32;
    FOnChange:          TNotifyEvent;

    procedure SetBorder(const Value: TX2Color32);
    procedure SetFill(const Value: TX2Color32);
    function IsBorderStored(): Boolean;
    function IsFillStored(): Boolean;
  protected
    procedure DoChange();

    procedure SetDefaultColors(ABorder, AFill: TX2Color32);

    property DefaultBorder: TX2Color32    read FDefaultBorder write FDefaultBorder;
    property DefaultFill:   TX2Color32    read FDefaultFill   write FDefaultFill;
    property OnChange:      TNotifyEvent  read FOnChange      write FOnChange;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Border:      TX2Color32  read FBorder  write SetBorder stored IsBorderStored;
    property Fill:        TX2Color32  read FFill    write SetFill   stored IsFillStored;
  end;

  TX2MenuBarmCColors  = class(TPersistent)
  private
    FHot:         TX2MenuBarmCColor;
    FNormal:      TX2MenuBarmCColor;
    FSelected:    TX2MenuBarmCColor;
    FOnChange:    TNotifyEvent;

    procedure SetHot(const Value: TX2MenuBarmCColor);
    procedure SetNormal(const Value: TX2MenuBarmCColor);
    procedure SetSelected(const Value: TX2MenuBarmCColor);
  protected
    procedure DoChange();
    procedure ColorChange(Sender: TObject);

    property OnChange:    TNotifyEvent    read FOnChange  write FOnChange;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure Assign(Source: TPersistent); override;
  published
    property Hot:       TX2MenuBarmCColor read FHot       write SetHot;
    property Normal:    TX2MenuBarmCColor read FNormal    write SetNormal;
    property Selected:  TX2MenuBarmCColor read FSelected  write SetSelected;
  end;

  // #ToDo1 (MvR) 19-3-2006: Custom base class?
  TX2MenuBarmusikCubePainter = class(TX2CustomMenuBarPainter)
  private
    FColor:             TColor;
    FGroupColors:       TX2MenuBarmCColors;
    FGroupHeight:       Integer;
    FIndicatorColors:   TX2MenuBarmCColors;
    FItemColors:        TX2MenuBarmCColors;
    FItemHeight:        Integer;

    procedure SetColor(const Value: TColor);
    procedure SetGroupColors(const Value: TX2MenuBarmCColors);
    procedure SetGroupHeight(const Value: Integer);
    procedure SetIndicatorColors(const Value: TX2MenuBarmCColors);
    procedure SetItemColors(const Value: TX2MenuBarmCColors);
    procedure SetItemHeight(const Value: Integer);
  protected
    procedure ColorChange(Sender: TObject);

    function GetColor(AColors: TX2MenuBarmCColors; AState: TX2MenuBarDrawStates): TX2MenuBarmCColor;
    procedure DrawBlended(ACanvas: TCanvas; AImageList: TCustomImageList; AX, AY, AImageIndex: Integer; AAlpha: Byte);

    function GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer; override;
    function GetItemHeight(AItem: TX2MenuBarItem): Integer; override;

    procedure DrawBackground(ACanvas: TCanvas; const ABounds: TRect); override;
    procedure DrawGroupHeader(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect; AState: TX2MenuBarDrawStates); override;
    procedure DrawItem(ACanvas: TCanvas; AItem: TX2MenuBarItem; const ABounds: TRect; AState: TX2MenuBarDrawStates); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    procedure ResetColors();
  published
    property Color:           TColor              read FColor           write SetColor stored False;
    property GroupColors:     TX2MenuBarmCColors  read FGroupColors     write SetGroupColors stored False;
    property GroupHeight:     Integer             read FGroupHeight     write SetGroupHeight stored False;
    property IndicatorColors: TX2MenuBarmCColors  read FIndicatorColors write SetIndicatorColors stored False;
    property ItemColors:      TX2MenuBarmCColors  read FItemColors      write SetItemColors stored False;
    property ItemHeight:      Integer             read FItemHeight      write SetItemHeight stored False;
  end;

implementation
uses
  SysUtils;


{ TX2MenuBarmusikCubePainter }
constructor TX2MenuBarmusikCubePainter.Create(AOwner: TComponent);
begin
  inherited;

  FColor            := clBtnFace;
  FGroupColors      := TX2MenuBarmCColors.Create();
  FGroupHeight      := 22;
  FIndicatorColors  := TX2MenuBarmCColors.Create();
  FItemColors       := TX2MenuBarmCColors.Create();
  FItemHeight       := 22;

  FGroupColors.OnChange     := ColorChange;
  FIndicatorColors.OnChange := ColorChange;
  FItemColors.OnChange      := ColorChange;

  ResetColors();
end;

destructor TX2MenuBarmusikCubePainter.Destroy();
begin
  FreeAndNil(FItemColors);
  FreeAndNil(FIndicatorColors);
  FreeAndNil(FGroupColors);

  inherited;
end;


procedure TX2MenuBarmusikCubePainter.ResetColors();
begin
  { Group buttons }
  GroupColors.Hot.SetDefaultColors(     Color32(clBtnShadow),
                                        Color32(clBtnShadow, 128));

  GroupColors.Normal.SetDefaultColors(  Color32(clBtnShadow, 64),
                                        Color32(clBtnShadow, 64));

  GroupColors.Selected.SetDefaultColors(Color32(clBtnShadow),
                                        Color32(clBtnHighlight));

  { Indicator }
  IndicatorColors.Selected.SetDefaultColors(Color32(clActiveCaption, 252),
                                            Color32(clActiveCaption, 252));

  { Item buttons }
  ItemColors.Hot.SetDefaultColors(      Color32(clBtnShadow),
                                        Color32(clBtnHighlight, 114));

  ItemColors.Normal.SetDefaultColors(   Color32(clBtnHighlight, 50),
                                        Color32(clBtnHighlight, 50));

  ItemColors.Selected.SetDefaultColors( Color32(clBtnShadow),
                                        Color32(clBtnHighlight));
end;


function TX2MenuBarmusikCubePainter.GetColor(AColors: TX2MenuBarmCColors;
                                             AState: TX2MenuBarDrawStates): TX2MenuBarmCColor;
begin
  if mdsSelected in AState then
    Result  := AColors.Selected
  else if mdsHot in AState then
    Result  := AColors.Hot
  else
    Result  := AColors.Normal;
end;

procedure TX2MenuBarmusikCubePainter.DrawBlended(ACanvas: TCanvas;
                                                 AImageList: TCustomImageList;
                                                 AX, AY, AImageIndex: Integer;
                                                 AAlpha: Byte);
var
  backBuffer:       Graphics.TBitmap;
  iconBuffer:       Graphics.TBitmap;
  sourceRect:       TRect;
  destRect:         TRect;

begin
  backBuffer  := Graphics.TBitmap.Create();
  try
    backBuffer.PixelFormat  := pf32bit;
    backBuffer.Width        := AImageList.Width;
    backBuffer.Height       := AImageList.Height;

    destRect            := Rect(0, 0, backBuffer.Width, backBuffer.Height);
    sourceRect          := destRect;
    OffsetRect(sourceRect, AX, AY);
    backBuffer.Canvas.CopyRect(destRect, ACanvas, sourceRect);

    iconBuffer  := Graphics.TBitmap.Create();
    try
      iconBuffer.Assign(backBuffer);
      AImageList.Draw(iconBuffer.Canvas, 0, 0, AImageIndex);

      X2CLGraphics.DrawBlended(backBuffer, iconBuffer, AAlpha);
    finally
      FreeAndNil(iconBuffer);
    end;

    ACanvas.Draw(AX, AY, backBuffer);
  finally
    FreeAndNil(backBuffer);
  end;
end;


function TX2MenuBarmusikCubePainter.GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer;
begin
  Result := FGroupHeight;
end;

function TX2MenuBarmusikCubePainter.GetItemHeight(AItem: TX2MenuBarItem): Integer;
begin
  Result := FItemHeight;
end;


procedure TX2MenuBarmusikCubePainter.DrawBackground(ACanvas: TCanvas;
                                                    const ABounds: TRect);
begin
  with ACanvas do
  begin
    Brush.Color := FColor;
    FillRect(ABounds);
  end;
end;

procedure TX2MenuBarmusikCubePainter.DrawGroupHeader(ACanvas: TCanvas;
                                                     AGroup: TX2MenuBarGroup;
                                                     const ABounds: TRect;
                                                     AState: TX2MenuBarDrawStates);
var
  groupColor:       TX2MenuBarmCColor;
  textBounds:       TRect;

begin
  with ACanvas do
  begin
    groupColor  := GetColor(GroupColors, AState);

    Brush.Color := Blend(Color, groupColor.Fill);
    Brush.Style := bsSolid;
    Pen.Color   := Blend(Color, groupColor.Border);
    Pen.Style   := psSolid;
    Rectangle(ABounds);

    textBounds  := ABounds;
    Inc(textBounds.Left, 12); // #ToDo3 (MvR) 19-3-2006: GroupIndent property?
    Dec(textBounds.Right, 2);

    ACanvas.Font.Style  := [fsBold];
    if AGroup.Enabled then
      ACanvas.Font.Color  := clWindowText
    else
      ACanvas.Font.Color  := clGrayText;

    DrawText(ACanvas, AGroup.Caption, textBounds, taLeftJustify,
             taVerticalCenter, False, csEllipsis);
  end;
end;


procedure TX2MenuBarmusikCubePainter.DrawItem(ACanvas: TCanvas;
                                              AItem: TX2MenuBarItem;
                                              const ABounds: TRect;
                                              AState: TX2MenuBarDrawStates);
var
  itemColor:          TX2MenuBarmCColor;
  itemBounds:         TRect;
  indicatorBounds:    TRect;
  indicatorColor:     TX2MenuBarmCColor;
  textBounds:         TRect;
  imageList:          TCustomImageList;
  imgY:               Integer;

begin
  with ACanvas do
  begin
    itemColor             := GetColor(ItemColors, AState);
    indicatorColor        := GetColor(IndicatorColors, AState);

    itemBounds            := ABounds;
    indicatorBounds       := itemBounds;
    indicatorBounds.Right := indicatorBounds.Left + 6;
    Brush.Color           := Blend(Color, indicatorColor.Fill);
    Brush.Style           := bsSolid;
    Pen.Color             := Blend(Color, indicatorColor.Border);
    Pen.Style             := psSolid;
    Rectangle(itemBounds);

    itemBounds.Left       := indicatorBounds.Right;
    Brush.Color           := Blend(Color, itemColor.Fill);
    Brush.Style           := bsSolid;
    Pen.Color             := Blend(Color, itemColor.Border);
    Pen.Style             := psSolid;
    Rectangle(itemBounds);

    textBounds            := itemBounds;
    Inc(textBounds.Left, 4);

    imageList := MenuBar.Images;
    if Assigned(imageList) then
    begin
      if AItem.ImageIndex > -1 then
      begin
        imgY  := textBounds.Top + ((textBounds.Bottom - textBounds.Top -
                                    imageList.Height) div 2);

        if (mdsHot in AState) or (mdsSelected in AState) then
          imageList.Draw(ACanvas, textBounds.Left, imgY, AItem.ImageIndex)
        else
          DrawBlended(ACanvas, imageList, textBounds.Left, imgY,
                      AItem.ImageIndex, 128);
      end;

      Inc(textBounds.Left, imageList.Width + 4);
    end;

    if not AItem.Visible then
      { Design-time }
      ACanvas.Font.Style  := [fsItalic]
    else if mdsSelected in AState then
      ACanvas.Font.Style  := [fsBold]
    else
      ACanvas.Font.Style  := [];

    DrawText(ACanvas, AItem.Caption, textBounds, taLeftJustify, taVerticalCenter,
             False, csEllipsis);
  end;
end;

procedure TX2MenuBarmusikCubePainter.ColorChange(Sender: TObject);
begin
  NotifyObservers();
end;


procedure TX2MenuBarmusikCubePainter.SetIndicatorColors(const Value: TX2MenuBarmCColors);
begin
  if Value <> FIndicatorColors then
  begin
    FIndicatorColors.Assign(Value);
    NotifyObservers();
  end;
end;

procedure TX2MenuBarmusikCubePainter.SetItemColors(const Value: TX2MenuBarmCColors);
begin
  if Value <> FItemColors then
  begin
    FItemColors.Assign(Value);
    NotifyObservers();
  end;
end;

procedure TX2MenuBarmusikCubePainter.SetItemHeight(const Value: Integer);
begin
  if Value <> FItemHeight then
  begin
    FItemHeight := Value;
    NotifyObservers();
  end;
end;

procedure TX2MenuBarmusikCubePainter.SetColor(const Value: TColor);
begin
  if Value <> FColor then
  begin
    FColor := Value;
    NotifyObservers();
  end;
end;

procedure TX2MenuBarmusikCubePainter.SetGroupColors(const Value: TX2MenuBarmCColors);
begin
  if Value <> FGroupColors then
  begin
    FGroupColors.Assign(Value);
    NotifyObservers();
  end;
end;

procedure TX2MenuBarmusikCubePainter.SetGroupHeight(const Value: Integer);
begin
  if Value <> FGroupHeight then
  begin
    FGroupHeight := Value;
    NotifyObservers();
  end;
end;


{ TX2MenuBarmCColor }
procedure TX2MenuBarmCColor.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarmCColor then
    with TX2MenuBarmCColor(Source) do
    begin
      Self.DefaultBorder  := DefaultBorder;
      Self.DefaultFill    := DefaultFill;
      Self.Border         := Border;
      Self.Fill           := Fill;
    end
  else
    inherited;
end;


procedure TX2MenuBarmCColor.DoChange();
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TX2MenuBarmCColor.SetDefaultColors(ABorder, AFill: TX2Color32);
begin
  FDefaultBorder  := ABorder;
  FDefaultFill    := AFill;
  FBorder         := ABorder;
  FFill           := AFill;
end;


function TX2MenuBarmCColor.IsBorderStored(): Boolean;
begin
  Result  := (FBorder <> FDefaultBorder);
end;

function TX2MenuBarmCColor.IsFillStored(): Boolean;
begin
  Result  := (FFill <> FDefaultFill);
end;

procedure TX2MenuBarmCColor.SetBorder(const Value: TX2Color32);
begin
  if Value <> FBorder then
  begin
    FBorder := Value;
    DoChange();
  end;
end;

procedure TX2MenuBarmCColor.SetFill(const Value: TX2Color32);
begin
  if Value <> FFill then
  begin
    FFill := Value;
    DoChange();
  end;
end;


{ TX2MenuBarmCColors }
constructor TX2MenuBarmCColors.Create();
begin
  inherited;

  FHot      := TX2MenuBarmCColor.Create();
  FNormal   := TX2MenuBarmCColor.Create();
  FSelected := TX2MenuBarmCColor.Create();

  FHot.OnChange       := ColorChange;
  FNormal.OnChange    := ColorChange;
  FSelected.OnChange  := ColorChange;
end;

destructor TX2MenuBarmCColors.Destroy();
begin
  FreeAndNil(FSelected);
  FreeAndNil(FNormal);
  FreeAndNil(FHot);

  inherited;
end;

procedure TX2MenuBarmCColors.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarmCColors then
    with TX2MenuBarmCColors(Source) do
    begin
      Self.Hot.Assign(Hot);
      Self.Normal.Assign(Normal);
      Self.Selected.Assign(Selected);
    end
  else
    inherited;
end;


procedure TX2MenuBarmCColors.DoChange();
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TX2MenuBarmCColors.ColorChange(Sender: TObject);
begin
  DoChange();
end;


procedure TX2MenuBarmCColors.SetHot(const Value: TX2MenuBarmCColor);
begin
  if FHot <> Value then
  begin
    FHot.Assign(Value);
    DoChange();
  end;
end;

procedure TX2MenuBarmCColors.SetNormal(const Value: TX2MenuBarmCColor);
begin
  if FNormal <> Value then
  begin
    FNormal.Assign(Value);
    DoChange();
  end;
end;

procedure TX2MenuBarmCColors.SetSelected(const Value: TX2MenuBarmCColor);
begin
  if FNormal <> Value then
  begin
    FSelected.Assign(Value);
    DoChange();
  end;
end;

end.
