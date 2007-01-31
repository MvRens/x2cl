{
  :: Implements a Uname-IT-style painter for the X2MenuBar.
  ::
  :: Part of the X2Software Component Library
  ::    http://www.x2software.net/
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLunaMenuBarPainter;

interface
uses
  Classes,
  Graphics,
  Windows,

  X2CLMenuBar;

type
  TX2MenuBarunaProperty = class(TPersistent)
  private
    FOnChange: TNotifyEvent;
  protected
    procedure Changed();
  public
    property OnChange:    TNotifyEvent  read FOnChange  write FOnChange;
  end;

  TX2MenuBarunaColor = class(TX2MenuBarunaProperty)
  private
    FDefaultDisabled:   TColor;
    FDefaultHot:        TColor;
    FDefaultNormal:     TColor;
    FDefaultSelected:   TColor;
    FDisabled:          TColor;
    FHot:               TColor;
    FNormal:            TColor;
    FSelected:          TColor;

    function IsDisabledStored(): Boolean;
    function IsHotStored(): Boolean;
    function IsNormalStored(): Boolean;
    function IsSelectedStored(): Boolean;
    procedure SetDisabled(const Value: TColor);
    procedure SetHot(const Value: TColor);
    procedure SetNormal(const Value: TColor);
    procedure SetSelected(const Value: TColor);
  protected
    procedure SetDefaultColors(AHot, ANormal, ASelected, ADisabled: TColor);

    property DefaultDisabled:   TColor  read FDefaultDisabled write FDefaultDisabled;
    property DefaultHot:        TColor  read FDefaultHot      write FDefaultHot;
    property DefaultNormal:     TColor  read FDefaultNormal   write FDefaultNormal;
    property DefaultSelected:   TColor  read FDefaultSelected write FDefaultSelected;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Disabled:  TColor read FDisabled write SetDisabled stored IsDisabledStored;
    property Hot:       TColor read FHot      write SetHot      stored IsHotStored;
    property Normal:    TColor read FNormal   write SetNormal   stored IsNormalStored;
    property Selected:  TColor read FSelected write SetSelected stored IsSelectedStored;
  end;

  TX2MenuBarunaGroupColors = class(TX2MenuBarunaProperty)
  private
    FFill:    TX2MenuBarunaColor;
    FText:    TX2MenuBarunaColor;
    FBorder:  TX2MenuBarunaColor;
    
    procedure SetBorder(const Value: TX2MenuBarunaColor);
    procedure SetFill(const Value: TX2MenuBarunaColor);
    procedure SetText(const Value: TX2MenuBarunaColor);
  protected
    procedure ColorChange(Sender: TObject);
  public
    constructor Create();
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
  published
    property Border:    TX2MenuBarunaColor  read FBorder  write SetBorder;
    property Fill:      TX2MenuBarunaColor  read FFill    write SetFill;
    property Text:      TX2MenuBarunaColor  read FText    write SetText;
  end;

  TX2MenuBarunaMetrics = class(TX2MenuBarunaProperty)
  private
    FAfterGroupHeader:    Integer;
    FAfterItem:           Integer;
    FAfterLastItem:       Integer;
    FBeforeFirstItem:     Integer;
    FBeforeGroupHeader:   Integer;
    FBeforeItem:          Integer;
    FGroupHeight:         Integer;
    FItemHeight:          Integer;
    FMargin:              Integer;
    
    procedure SetAfterGroupHeader(const Value: Integer);
    procedure SetAfterItem(const Value: Integer);
    procedure SetAfterLastItem(const Value: Integer);
    procedure SetBeforeFirstItem(const Value: Integer);
    procedure SetBeforeGroupHeader(const Value: Integer);
    procedure SetBeforeItem(const Value: Integer);
    procedure SetGroupHeight(const Value: Integer);
    procedure SetItemHeight(const Value: Integer);
    procedure SetMargin(const Value: Integer);
  public
    constructor Create();

    procedure Assign(Source: TPersistent); override;
  published
    property AfterGroupHeader:  Integer read FAfterGroupHeader  write SetAfterGroupHeader   default 8;
    property AfterItem:         Integer read FAfterItem         write SetAfterItem          default 2;
    property AfterLastItem:     Integer read FAfterLastItem     write SetAfterLastItem      default 10;
    property BeforeFirstItem:   Integer read FBeforeFirstItem   write SetBeforeFirstItem    default 0;
    property BeforeGroupHeader: Integer read FBeforeGroupHeader write SetBeforeGroupHeader  default 8;
    property BeforeItem:        Integer read FBeforeItem        write SetBeforeItem         default 2;
    property GroupHeight:       Integer read FGroupHeight       write SetGroupHeight        default 22;
    property ItemHeight:        Integer read FItemHeight        write SetItemHeight         default 21;
    property Margin:            Integer read FMargin            write SetMargin             default 10;
  end;

  TX2MenuBarunaPainter = class(TX2CustomMenuBarPainter)
  private
    FArrowColor:      TColor;
    FBlurShadow:      Boolean;
    FColor:           TColor;
    FGroupColors:     TX2MenuBarunaGroupColors;
    FItemColors:      TX2MenuBarunaColor;
    FMetrics:         TX2MenuBarunaMetrics;
    FShadowColor:     TColor;
    FShadowOffset:    Integer;

    procedure SetBlurShadow(const Value: Boolean);
    procedure SetGroupColors(const Value: TX2MenuBarunaGroupColors);
    procedure SetItemColors(const Value: TX2MenuBarunaColor);
    procedure SetMetrics(const Value: TX2MenuBarunaMetrics);
    procedure SetShadowColor(const Value: TColor);
    procedure SetShadowOffset(const Value: Integer);
  protected
    function ApplyMargins(const ABounds: TRect): TRect; override;
    function GetSpacing(AElement: TX2MenuBarSpacingElement): Integer; override;
    function GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer; override;
    function GetItemHeight(AItem: TX2MenuBarItem): Integer; override;

    procedure DrawBackground(ACanvas: TCanvas; const ABounds: TRect); override;
    procedure DrawGroupHeader(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect; AState: TX2MenuBarDrawStates); override;
    procedure DrawItem(ACanvas: TCanvas; AItem: TX2MenuBarItem; const ABounds: TRect; AState: TX2MenuBarDrawStates); override;

    procedure ColorChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;

    procedure ResetColors();
  published
    property ArrowColor:      TColor                    read FArrowColor    write FArrowColor     default clBlue;
    property BlurShadow:      Boolean                   read FBlurShadow    write SetBlurShadow   default True;
    property Color:           TColor                    read FColor         write FColor          default clWindow;
    property GroupColors:     TX2MenuBarunaGroupColors  read FGroupColors   write SetGroupColors;
    property ItemColors:      TX2MenuBarunaColor        read FItemColors    write SetItemColors;
    property Metrics:         TX2MenuBarunaMetrics      read FMetrics       write SetMetrics;
    property ShadowColor:     TColor                    read FShadowColor   write SetShadowColor  default clBtnShadow;
    property ShadowOffset:    Integer                   read FShadowOffset  write SetShadowOffset default 2;
  end;

implementation
uses
  ImgList,
  SysUtils,

  X2CLGraphics;



procedure Blur(ASource: Graphics.TBitmap);
var
  refBitmap:      Graphics.TBitmap;
  lines:          array[0..2] of PRGBAArray;
  lineDest:       PRGBAArray;
  lineIndex:      Integer;
  line:           PRGBAArray;
  xPos:           Integer;
  yPos:           Integer;
  maxX:           Integer;
  maxY:           Integer;
  sumRed:         Integer;
  sumGreen:       Integer;
  sumBlue:        Integer;
  samples:        Integer;

begin
  ASource.PixelFormat := pf32bit;
  refBitmap           := Graphics.TBitmap.Create();
  try
    refBitmap.Assign(ASource);

    for lineIndex := Low(lines) to High(lines) do
      lines[lineIndex]  := nil;

    maxY  := Pred(ASource.Height);
    for yPos := 0 to maxY do
    begin
      for lineIndex := Low(lines) to High(lines) - 1 do
        lines[lineIndex]  := lines[Succ(lineIndex)];

      if yPos = maxY then
        lines[High(lines)]  := nil
      else
        lines[High(lines)]  := refBitmap.ScanLine[Succ(yPos)];
        
      lineDest            := ASource.ScanLine[yPos];
      maxX                := Pred(ASource.Width);

      for xPos := 0 to maxX do
      begin
        sumBlue   := 0; 
        sumGreen  := 0;
        sumRed    := 0;
        samples   := 0;

        for lineIndex := Low(lines) to High(lines) do
          if Assigned(lines[lineIndex]) then
          begin
            line  := lines[lineIndex];

            with line^[xPos] do
            begin
              Inc(sumBlue, rgbBlue);
              Inc(sumGreen, rgbGreen);
              Inc(sumRed, rgbRed);
              Inc(samples);
            end;

            if xPos > 0 then
              with line^[Pred(xPos)] do
              begin
                Inc(sumBlue, rgbBlue);
                Inc(sumGreen, rgbGreen);
                Inc(sumRed, rgbRed);
                Inc(samples);
              end;

            if xPos < maxX then
              with line^[Succ(xPos)] do
              begin
                Inc(sumBlue, rgbBlue);
                Inc(sumGreen, rgbGreen);
                Inc(sumRed, rgbRed);
                Inc(samples);
              end;
          end;

        if samples > 0 then
          with lineDest^[xPos] do
          begin
            rgbBlue   := sumBlue div samples;
            rgbGreen  := sumGreen div samples;
            rgbRed    := sumRed div samples;
          end;
      end;
    end;
  finally
    FreeAndNil(refBitmap);
  end;
end;


{ TX2MenuBarunaMetrics }
constructor TX2MenuBarunaMetrics.Create();
begin
  inherited;

  FAfterGroupHeader   := 8;
  FAfterItem          := 2;
  FAfterLastItem      := 10;
  FBeforeFirstItem    := 0;
  FBeforeGroupHeader  := 8;
  FBeforeItem         := 2;
  FGroupHeight        := 22;
  FItemHeight         := 21;
  FMargin             := 10;
end;


procedure TX2MenuBarunaMetrics.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarunaMetrics then
    with TX2MenuBarunaMetrics(Source) do
    begin
      Self.AfterGroupHeader   := AfterGroupHeader;
      Self.AfterItem          := AfterItem;
      Self.AfterLastItem      := AfterLastItem;
      Self.BeforeFirstItem    := BeforeFirstItem;
      Self.BeforeGroupHeader  := BeforeGroupHeader;
      Self.BeforeItem         := BeforeItem;
      Self.GroupHeight        := GroupHeight;
      Self.ItemHeight         := ItemHeight;
      Self.Margin             := Margin;
    end
  else
    inherited;
end;


procedure TX2MenuBarunaMetrics.SetAfterGroupHeader(const Value: Integer);
begin
  if Value <> FAfterGroupHeader then
  begin
    FAfterGroupHeader := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetAfterItem(const Value: Integer);
begin
  if Value <> FAfterItem then
  begin
    FAfterItem := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetAfterLastItem(const Value: Integer);
begin
  if Value <> FAfterLastItem then
  begin
    FAfterLastItem := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetBeforeFirstItem(const Value: Integer);
begin
  if Value <> FBeforeFirstItem then
  begin
    FBeforeFirstItem := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetBeforeGroupHeader(const Value: Integer);
begin
  if Value <> FBeforeGroupHeader then
  begin
    FBeforeGroupHeader := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetBeforeItem(const Value: Integer);
begin
  if Value <> FBeforeItem then
  begin
    FBeforeItem := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetGroupHeight(const Value: Integer);
begin
  if Value <> FGroupHeight then
  begin
    FGroupHeight := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetItemHeight(const Value: Integer);
begin
  if Value <> FItemHeight then
  begin
    FItemHeight := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaMetrics.SetMargin(const Value: Integer);
begin
  if Value <> FMargin then
  begin
    FMargin := Value;
    Changed();
  end;
end;


{ TX2MenuBarunaPainter }
constructor TX2MenuBarunaPainter.Create(AOwner: TComponent);
begin
  inherited;

  FBlurShadow   := True;
  FGroupColors  := TX2MenuBarunaGroupColors.Create();
  FItemColors   := TX2MenuBarunaColor.Create();
  FMetrics      := TX2MenuBarunaMetrics.Create();
  FShadowOffset := 2;

  FGroupColors.OnChange := ColorChange;
  FItemColors.OnChange  := ColorChange;
  FMetrics.OnChange     := ColorChange;

  ResetColors();
end;

destructor TX2MenuBarunaPainter.Destroy();
begin
  FreeAndNil(FMetrics);
  FreeAndNil(FItemColors);
  FreeAndNil(FGroupColors);

  inherited;
end;


procedure TX2MenuBarunaPainter.ResetColors();
const
  PurpleBlue = $00BE6363;

var
  groupColor:       TColor;
  textColor:        TColor;
  disabledColor:    TColor;

begin
  ArrowColor    := clBlue;
  Color         := clWindow;
  ShadowColor   := clBtnShadow;

  { Group buttons }
  groupColor    := Blend(Color, Color32(clBtnFace, 128));
  GroupColors.Border.SetDefaultColors(PurpleBlue, clBlack, PurpleBlue, clBlack);
  GroupColors.Fill.SetDefaultColors(groupColor, groupColor, groupColor, groupColor);
  GroupColors.Text.SetDefaultColors(PurpleBlue, clWindowText, PurpleBlue, clGrayText);

  { Items }
  textColor     := Blend(clGrayText, Color32(clWindowText, 128));
  disabledColor := Blend(Color, Color32(clGrayText, 128));
  ItemColors.SetDefaultColors(clWindowText, textColor, clWindowText, disabledColor);
end;


procedure TX2MenuBarunaPainter.SetBlurShadow(const Value: Boolean);
begin
  if Value <> FBlurShadow then
  begin
    FBlurShadow := Value;
    NotifyObservers();
  end;
end;


function TX2MenuBarunaPainter.ApplyMargins(const ABounds: TRect): TRect;
begin
  Result  := inherited ApplyMargins(ABounds);
  InflateRect(Result, -Metrics.Margin, -Metrics.Margin);
end;

function TX2MenuBarunaPainter.GetSpacing(AElement: TX2MenuBarSpacingElement): Integer;
begin
  Result  := inherited GetSpacing(AElement);
  
  case AElement of
    seBeforeGroupHeader:  Result  := Metrics.BeforeGroupHeader;
    seAfterGroupHeader:   Result  := Metrics.AfterGroupHeader;
    seBeforeFirstItem:    Result  := Metrics.BeforeFirstItem;
    seAfterLastItem:      Result  := Metrics.AfterLastItem;
    seBeforeItem:         Result  := Metrics.BeforeItem;
    seAfterItem:          Result  := Metrics.AfterItem;
  end;
end;

function TX2MenuBarunaPainter.GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer;
begin
  Result := Metrics.GroupHeight;
end;

function TX2MenuBarunaPainter.GetItemHeight(AItem: TX2MenuBarItem): Integer;
begin
  Result := Metrics.ItemHeight
end;


procedure TX2MenuBarunaPainter.DrawBackground(ACanvas: TCanvas;
                                              const ABounds: TRect);
begin
  ACanvas.Brush.Color := Self.Color;
  ACanvas.FillRect(ABounds);
end;

procedure TX2MenuBarunaPainter.DrawGroupHeader(ACanvas: TCanvas;
                                               AGroup: TX2MenuBarGroup;
                                               const ABounds: TRect;
                                               AState: TX2MenuBarDrawStates);
const
  ShadowMargin  = 2;
  
  procedure DrawShadowOutline(AShadowCanvas: TCanvas; AShadowBounds: TRect);
  begin
    AShadowCanvas.Brush.Color := ShadowColor;
    AShadowCanvas.Pen.Color   := ShadowColor;
    AShadowCanvas.RoundRect(AShadowBounds.Left + ShadowMargin,
                            AShadowBounds.Top + ShadowMargin,
                            AShadowBounds.Right + ShadowMargin,
                            AShadowBounds.Bottom + ShadowMargin, 5, 5);
  end;

  function GetColor(AColor: TX2MenuBarunaColor): TColor;
  begin
    if AGroup.Enabled then
      if (mdsSelected in AState) or (mdsGroupSelected in AState) then
        Result  := AColor.Selected
      else if mdsHot in AState then
        Result  := AColor.Hot
      else
        Result  := AColor.Normal
    else
      Result    := AColor.Disabled;
  end;

var
  imageList:        TCustomImageList;
  imagePos:         TPoint;
  shadowBitmap:     Graphics.TBitmap;
  shadowBounds:     TRect;
  textRect:         TRect;

begin
  if not ((mdsSelected in AState) or (mdsGroupSelected in AState)) then
  begin
    { Shadow }
    if BlurShadow then
    begin
      shadowBitmap  := Graphics.TBitmap.Create();
      try
        shadowBitmap.PixelFormat  := pf32bit;
        shadowBitmap.Width        := (ABounds.Right - ABounds.Left + (ShadowMargin * 2));
        shadowBitmap.Height       := (ABounds.Bottom - ABounds.Top + (ShadowMargin * 2));

        DrawBackground(shadowBitmap.Canvas, Rect(0, 0, shadowBitmap.Width,
                                                 shadowBitmap.Height));
        DrawShadowOutline(shadowBitmap.Canvas, Rect(0, 0, shadowBitmap.Width - (ShadowMargin * 2),
                          shadowBitmap.Height - (ShadowMargin * 2)));

        Blur(shadowBitmap);
        ACanvas.Draw(ABounds.Left, ABounds.Top, shadowBitmap);
      finally
        FreeAndNil(shadowBitmap);
      end
    end else
    begin
      shadowBounds  := ABounds;
      OffsetRect(shadowBounds, -ShadowMargin, -ShadowMargin);
      DrawShadowOutline(ACanvas, ABounds);
    end;
  end;

  { Rounded rectangle }
  ACanvas.Brush.Color := GetColor(GroupColors.Fill);
  ACanvas.Pen.Color   := GetColor(GroupColors.Border);
  ACanvas.Font.Color  := GetColor(GroupColors.Text);

  ACanvas.RoundRect(ABounds.Left, ABounds.Top, ABounds.Right, ABounds.Bottom, 5, 5);
  
  textRect  := ABounds;
  Inc(textRect.Left, 4);
  Dec(textRect.Right, 4);

  { Image }
  imageList := AGroup.MenuBar.Images;
  if Assigned(imageList) then
  begin
    if AGroup.ImageIndex > -1 then
    begin
      imagePos.X  := textRect.Left;
      imagePos.Y  := ABounds.Top + ((ABounds.Bottom - ABounds.Top - imageList.Height) div 2);
      imageList.Draw(ACanvas, imagePos.X, imagePos.Y, AGroup.ImageIndex);
    end;

    Inc(textRect.Left, imageList.Width + 4);
  end;

  { Text }
  ACanvas.Font.Style  := [fsBold];
  DrawText(ACanvas, AGroup.Caption, textRect, taLeftJustify, taVerticalCenter,
           False, csEllipsis);
end;

procedure TX2MenuBarunaPainter.DrawItem(ACanvas: TCanvas; AItem: TX2MenuBarItem;
                                        const ABounds: TRect;
                                        AState: TX2MenuBarDrawStates);
  function GetColor(AColor: TX2MenuBarunaColor): TColor;
  begin
    if AItem.Enabled then
      if mdsSelected in AState then
        Result  := AColor.Selected
      else if mdsHot in AState then
        Result  := AColor.Hot
      else
        Result  := AColor.Normal
    else
      Result    := AColor.Disabled;
  end;

var
  focusBounds:      TRect;
  textBounds:       TRect;
  arrowPoints:      array[0..2] of TPoint;

begin
  focusBounds := ABounds;
  Dec(focusBounds.Right, Metrics.Margin);

  if (mdsSelected in AState) then
  begin
    { Focus rectangle }
    DrawFocusRect(ACanvas, focusBounds);

    { Arrow }
    ACanvas.Brush.Color := ArrowColor;
    ACanvas.Pen.Color   := ArrowColor;

    arrowPoints[0].X    := ABounds.Right - 8;
    arrowPoints[0].Y    := ABounds.Top + ((ABounds.Bottom - ABounds.Top - 15) div 2) + 7;
    arrowPoints[1].X    := Pred(ABounds.Right);
    arrowPoints[1].Y    := arrowPoints[0].Y - 7;
    arrowPoints[2].X    := Pred(ABounds.Right);
    arrowPoints[2].Y    := arrowPoints[0].Y + 7;
    ACanvas.Polygon(arrowPoints);
  end;

  { Text }
  ACanvas.Font.Color  := GetColor(ItemColors);
  textBounds  := focusBounds;
  Inc(textBounds.Left, 4);
  Dec(textBounds.Right, 4);

  SetBkMode(ACanvas.Handle, TRANSPARENT);

  if not AItem.Visible then
    { Design-time }
    ACanvas.Font.Style  := [fsItalic]
  else
    ACanvas.Font.Style  := [];

  DrawText(ACanvas, AItem.Caption, textBounds, taRightJustify, taVerticalCenter,
           False, csEllipsis);
end;


procedure TX2MenuBarunaPainter.ColorChange(Sender: TObject);
begin
  NotifyObservers();
end;


procedure TX2MenuBarunaPainter.SetGroupColors(const Value: TX2MenuBarunaGroupColors);
begin
  if Value <> FGroupColors then
  begin
    FGroupColors.Assign(Value);
    NotifyObservers();
  end;
end;

procedure TX2MenuBarunaPainter.SetItemColors(const Value: TX2MenuBarunaColor);
begin
  if Value <> FItemColors then
  begin
    FItemColors.Assign(Value);
    NotifyObservers();
  end;
end;

procedure TX2MenuBarunaPainter.SetMetrics(const Value: TX2MenuBarunaMetrics);
begin
  if Value <> FMetrics then
  begin
    FMetrics.Assign(Value);
    NotifyObservers();
  end;
end;

procedure TX2MenuBarunaPainter.SetShadowColor(const Value: TColor);
begin
  if Value <> FShadowColor then
  begin
    FShadowColor := Value;
    NotifyObservers();
  end;
end;

procedure TX2MenuBarunaPainter.SetShadowOffset(const Value: Integer);
begin
  if Value <> FShadowOffset then
  begin
    FShadowOffset := Value;
    NotifyObservers();
  end;
end;


{ TX2MenuBarunaProperty }
procedure TX2MenuBarunaProperty.Changed();
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;


{ TX2MenuBarunaColor }
procedure TX2MenuBarunaColor.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarunaColor then
    with TX2MenuBarunaColor(Source) do
    begin
      Self.DefaultDisabled  := DefaultDisabled;
      Self.DefaultHot       := DefaultHot;
      Self.DefaultNormal    := DefaultNormal;
      self.DefaultSelected  := DefaultSelected;
      Self.Disabled         := Disabled;
      Self.Hot              := Hot;
      Self.Normal           := Normal;
      self.Selected         := Selected;
    end
  else
    inherited;
end;

function TX2MenuBarunaColor.IsDisabledStored(): Boolean;
begin
  Result  := (FDisabled <> FDefaultDisabled);
end;

function TX2MenuBarunaColor.IsHotStored(): Boolean;
begin
  Result  := (FHot <> FDefaultHot);
end;

function TX2MenuBarunaColor.IsNormalStored(): Boolean;
begin
  Result  := (FNormal <> FDefaultNormal);
end;

function TX2MenuBarunaColor.IsSelectedStored(): Boolean;
begin
  Result  := (FSelected <> FDefaultSelected);
end;

procedure TX2MenuBarunaColor.SetDefaultColors(AHot, ANormal, ASelected, ADisabled: TColor);
begin
  FDefaultDisabled  := ADisabled;
  FDefaultHot       := AHot;
  FDefaultNormal    := ANormal;
  FDefaultSelected  := ASelected;
  FDisabled         := ADisabled;
  FHot              := AHot;
  FNormal           := ANormal;
  FSelected         := ASelected;
end;

procedure TX2MenuBarunaColor.SetDisabled(const Value: TColor);
begin
  if Value <> FDisabled then
  begin
    FDisabled := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaColor.SetHot(const Value: TColor);
begin
  if Value <> FHot then
  begin
    FHot := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaColor.SetNormal(const Value: TColor);
begin
  if Value <> FNormal then
  begin
    FNormal := Value;
    Changed();
  end;
end;

procedure TX2MenuBarunaColor.SetSelected(const Value: TColor);
begin
  if Value <> FSelected then
  begin
    FSelected := Value;
    Changed();
  end;
end;


{ TX2MenuBarunaGroupColors }
constructor TX2MenuBarunaGroupColors.Create();
begin
  inherited;

  FBorder := TX2MenuBarunaColor.Create();
  FFill   := TX2MenuBarunaColor.Create();
  FText   := TX2MenuBarunaColor.Create();

  FBorder.OnChange  := ColorChange;
  FFill.OnChange    := ColorChange;
  FText.OnChange    := ColorChange;
end;

destructor TX2MenuBarunaGroupColors.Destroy();
begin
  FreeAndNil(FText);
  FreeAndNil(FFill);
  FreeAndNil(FBorder);

  inherited;
end;


procedure TX2MenuBarunaGroupColors.Assign(Source: TPersistent);
begin
  if Source is TX2MenuBarunaGroupColors then
    with TX2MenuBarunaGroupColors(Source) do
    begin
      Self.Border.Assign(Border);
      Self.Fill.Assign(Fill);
      Self.Text.Assign(Text);
    end
  else
    inherited;
end;


procedure TX2MenuBarunaGroupColors.ColorChange(Sender: TObject);
begin
  Changed();
end;


procedure TX2MenuBarunaGroupColors.SetBorder(const Value: TX2MenuBarunaColor);
begin
  if Value <> FBorder then
  begin
    FBorder.Assign(Value);
    Changed();
  end;
end;

procedure TX2MenuBarunaGroupColors.SetFill(const Value: TX2MenuBarunaColor);
begin
  if Value <> FFill then
  begin
    FFill.Assign(Value);
    Changed();
  end;
end;

procedure TX2MenuBarunaGroupColors.SetText(const Value: TX2MenuBarunaColor);
begin
  if Value <> FText then
  begin
    FText.Assign(Value);
    Changed();
  end;
end;

end.
