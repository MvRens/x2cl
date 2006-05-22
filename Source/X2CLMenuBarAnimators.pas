{
  :: Implements the animators for the MenuBar. Though they are tightly
  :: interlinked (for now), this keeps the main unit clean.
  ::
  :: Part of the X2Software Component Library
  ::    http://www.x2software.net/
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLMenuBarAnimators;

interface
uses
  Classes,
  Graphics,
  Windows,

  X2CLMenuBar;

type
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
    :$ Implements a fade animation
  }
  TX2MenuBarFadeAnimator = class(TX2CustomMenuBarAnimator)
  private
    FAlpha:     Byte;
  public
    constructor Create(AItemsBuffer: Graphics.TBitmap); override;

    procedure Update(); override;
    procedure Draw(ACanvas: TCanvas; const ABounds: TRect); override;
  end;

  {
    :$ Implements a sliding fade animation
  }
  TX2MenuBarSlideFadeAnimator = class(TX2MenuBarFadeAnimator)
  private
    FSlideHeight:       Integer;
  protected
    function GetHeight(): Integer; override;
  public
    procedure Update(); override;
 end;

implementation
uses
  SysUtils;
  

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
  pixelPos:     Integer;
  tempPos:      Pointer;

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

  if RandSeed = 0 then
    Randomize();

  { Prepare an array of pixel indices which will be used to pick random
    unique pixels in the Update method.

    Optimization note: previously the array was ordered and an item would
    be randomly picked and deleted in Update. Now we pre-shuffle the list,
    then Delete only from the end, which does not reallocate or move any
    memory (TList.Count decreases, Capacity stays the same), a LOT faster. }
  FPixels                 := TList.Create();
  FPixels.Count           := AItemsBuffer.Width * AItemsBuffer.Height;

  for pixelIndex := Pred(FPixels.Count) downto 0 do
    FPixels[pixelIndex] := Pointer(pixelIndex);

  for pixelIndex := Pred(FPixels.Count) downto 0 do
  begin
    pixelPos  := Random(Succ(pixelIndex));
    if (pixelPos <> pixelIndex) then
    begin
      tempPos             := FPixels[pixelIndex];
      FPixels[pixelIndex] := FPixels[pixelPos];
      FPixels[pixelPos]   := tempPos;
    end;
  end;
end;

destructor TX2MenuBarDissolveAnimator.Destroy();
begin
  FreeAndNil(FItemsState);
  FreeAndNil(FMask); 

  inherited;
end;


procedure TX2MenuBarDissolveAnimator.Update();
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

  for pixel := Pred(FPixels.Count - pixelsRemaining) downto 0 do
  begin
    pixelCount  := FPixels.Count;
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


{ TX2MenuBarFadeAnimator }
constructor TX2MenuBarFadeAnimator.Create(AItemsBuffer: Graphics.TBitmap);
begin
  inherited;

  ItemsBuffer.PixelFormat := pf32bit;
end;


procedure TX2MenuBarFadeAnimator.Update();
var
  elapsed:        Cardinal;
  newAlpha:       Integer;

begin
  elapsed   := TimeElapsed;
  newAlpha  := Trunc((elapsed / AnimationTime) * 255);
  if Expanding then
    newAlpha  := 255 - newAlpha;

  if newAlpha > 255 then
    newAlpha  := 255
  else if newAlpha < 0 then
    newAlpha  := 0;

  FAlpha  := newAlpha;
  if elapsed >= AnimationTime then
    Terminate();
end;

procedure TX2MenuBarFadeAnimator.Draw(ACanvas: TCanvas; const ABounds: TRect);
var
  backBuffer:   Graphics.TBitmap;
  sourceRect:   TRect;
  destRect:     TRect;

begin
  if ABounds.Bottom - ABounds.Top <= 0 then
    exit;

  backBuffer  := Graphics.TBitmap.Create();
  try
    backBuffer.PixelFormat  := pf32bit;
    backBuffer.Width        := ItemsBuffer.Width;
    backBuffer.Height       := ItemsBuffer.Height;

    destRect                := Rect(0, 0, backBuffer.Width, backBuffer.Height);
    backBuffer.Canvas.CopyRect(destRect, ACanvas, ABounds);

    X2CLMenuBar.DrawBlended(backBuffer, ItemsBuffer, FAlpha);

    sourceRect              := Rect(0, 0, ItemsBuffer.Width, Self.Height);
    destRect                := ABounds;
    destRect.Bottom         := destRect.Top + Self.Height;
    ACanvas.CopyRect(destRect, backBuffer.Canvas, sourceRect);
  finally
    FreeAndNil(backBuffer);
  end;
end;


{ TX2MenuBarSlideFadeAnimator }
function TX2MenuBarSlideFadeAnimator.GetHeight(): Integer;
begin
  Result  := FSlideHeight;
end;

procedure TX2MenuBarSlideFadeAnimator.Update();
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

  inherited;
end;

end.
