{
  :: Implements various graphics-related classes and functions.
  ::
  :: Part of the X2Software Component Library
  ::    http://www.x2software.net/
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLGraphics;

interface
uses
  Classes,
  Graphics,
  Windows;

type
  TX2Color32  = type TColor;
  TDrawTextClipStyle  = (csNone, csEllipsis, csPathEllipsis);

  {$IFNDEF VER180}
  TVerticalAlignment = (taTop, taBottom, taVerticalCenter);
  {$ENDIF}

  PRGBAArray  = ^TRGBAArray;
  TRGBAArray  = array[Word] of TRGBQuad;

  
  function Color32(AColor: TColor; AAlpha: Byte = 255): TX2Color32;
  function DelphiColor(AColor: TX2Color32): TColor;

  function RedValue(AColor: TX2Color32): Byte;
  function GreenValue(AColor: TX2Color32): Byte;
  function BlueValue(AColor: TX2Color32): Byte;
  function AlphaValue(AColor: TX2Color32): Byte;

  function Blend(ABackground: TColor; AForeground: TX2Color32): TColor;


  {
    :$ Provides a wrapper for the DrawText API.
  }
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


  {
    :$ Draws a rectangle with a vertical gradient.
  }
  procedure GradientFillRect(ACanvas: TCanvas; ARect: TRect; AStartColor, AEndColor: TColor);

  
  {
    :$ Darkens a color with the specified value
  }
  function DarkenColor(const AColor: TColor; const AValue: Byte): TColor;


  {
    :$ Lightens a color with the specified value
  }
  function LightenColor(const AColor: TColor; const AValue: Byte): TColor;

  
implementation

  
function Color32(AColor: TColor; AAlpha: Byte): TX2Color32;
begin
  Result  := (ColorToRGB(AColor) and $00FFFFFF) or (AAlpha shl 24);
end;

function DelphiColor(AColor: TX2Color32): TColor;
begin
  Result  := (AColor and $00FFFFFF);
end;


function RedValue(AColor: TX2Color32): Byte;
begin
  Result  := (AColor and $000000FF);
end;

function GreenValue(AColor: TX2Color32): Byte;
begin
  Result  := (AColor and $0000FF00) shr 8;
end;

function BlueValue(AColor: TX2Color32): Byte;
begin
  Result  := (AColor and $00FF0000) shr 16;
end;

function AlphaValue(AColor: TX2Color32): Byte;
begin
  Result  := (AColor and $FF000000) shr 24;
end;


function Blend(ABackground: TColor; AForeground: TX2Color32): TColor;
var
  backColor:        TX2Color32;
  backAlpha:        Integer;
  foreAlpha:        Integer;

begin
  foreAlpha := AlphaValue(AForeground);

  if foreAlpha = 0 then
    Result  := ABackground
  else if foreAlpha = 255 then
    Result  := DelphiColor(AForeground)
  else
  begin
    backColor := Color32(ABackground);
    backAlpha := 256 - foreAlpha;

    Result    := RGB(((RedValue(backColor) * backAlpha) +
                      (RedValue(AForeground) * foreAlpha)) shr 8,
                     ((GreenValue(backColor) * backAlpha) +
                      (GreenValue(AForeground) * foreAlpha)) shr 8,
                     ((BlueValue(backColor) * backAlpha) +
                      (BlueValue(AForeground) * foreAlpha)) shr 8);
  end;
end;


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


procedure GradientFillRect(ACanvas: TCanvas; ARect: TRect; AStartColor, AEndColor: TColor);

  function FixValue(AValue: Single): Single; 
  begin
    Result := AValue;

    if Result < 0 then
      Result := 0;

    if Result > 255 then
      Result := 255;
  end;


var
  startColor: Cardinal;
  endColor:   Cardinal;
  stepCount:  Integer;
  redValue:   Single;
  greenValue: Single;
  blueValue:  Single;
  redStep:    Single;
  greenStep:  Single;
  blueStep:   Single;
  line:       Integer;

begin
  startColor  := ColorToRGB(AStartColor);
  endColor    := ColorToRGB(AEndColor);

  if startColor = endColor then
  begin
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := startColor;
    ACanvas.FillRect(ARect);
  end else
  begin
    redValue    := GetRValue(startColor);
    greenValue  := GetGValue(startColor);
    blueValue   := GetBValue(startColor);

    stepCount   := ARect.Bottom - ARect.Top;
    redStep     := (GetRValue(endColor) - redValue) / stepCount;
    greenStep   := (GetGValue(endColor) - greenValue) / stepCount;
    blueStep    := (GetBValue(endColor) - blueValue) / stepCount;

    ACanvas.Pen.Style := psSolid;

    for line := ARect.Top to ARect.Bottom do
    begin
      ACanvas.Pen.Color := RGB(Trunc(redValue), Trunc(greenValue), Trunc(blueValue));
      ACanvas.MoveTo(ARect.Left, line);
      ACanvas.LineTo(ARect.Right, line);

      redValue    := FixValue(redValue + redStep);
      greenValue  := FixValue(greenValue + greenStep);
      blueValue   := FixValue(blueValue + blueStep);
    end;
  end;
end;


function DarkenColor(const AColor: TColor; const AValue: Byte): TColor;
var
  cColor:     Cardinal;
  iRed:       Integer;
  iGreen:     Integer;
  iBlue:      Integer;

begin
  cColor  := ColorToRGB(AColor);
  iRed    := (cColor and $FF0000) shr 16;;
  iGreen  := (cColor and $00FF00) shr 8;
  iBlue   := cColor and $0000FF;

  Dec(iRed, AValue);
  Dec(iGreen, AValue);
  Dec(iBlue, AValue);

  if iRed   < 0 then iRed   := 0;
  if iGreen < 0 then iGreen := 0;
  if iBlue  < 0 then iBlue  := 0;

  Result  := (iRed shl 16) + (iGreen shl 8) + iBlue;
end;


function LightenColor(const AColor: TColor; const AValue: Byte): TColor;
var
  cColor:     Cardinal;
  iRed:       Integer;
  iGreen:     Integer;
  iBlue:      Integer;

begin
  cColor  := ColorToRGB(AColor);
  iRed    := (cColor and $FF0000) shr 16;;
  iGreen  := (cColor and $00FF00) shr 8;
  iBlue   := cColor and $0000FF;

  Inc(iRed, AValue);
  Inc(iGreen, AValue);
  Inc(iBlue, AValue);

  if iRed   > 255 then iRed   := 255;
  if iGreen > 255 then iGreen := 255;
  if iBlue  > 255 then iBlue  := 255;

  Result  := (iRed shl 16) + (iGreen shl 8) + iBlue;
end;

end.


