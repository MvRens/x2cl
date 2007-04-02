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

end.
