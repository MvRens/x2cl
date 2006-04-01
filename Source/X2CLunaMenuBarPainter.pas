{
  :: Implements a Uname-IT-style painter for the X2MenuBar.
  ::
  :: Last changed:    $Date$
  :: Revision:        $Rev$
  :: Author:          $Author$
}
unit X2CLunaMenuBarPainter;

interface
uses
  Graphics,
  Windows,

  X2CLMenuBar;

type
  // #ToDo1 (MvR) 27-3-2006: arrow gets cut off one pixel when collapsing a group
  TX2MenuBarunaPainter = class(TX2CustomMenuBarPainter)
  private
    FBlurShadow:    Boolean;
    procedure SetBlurShadow(const Value: Boolean);
  protected
    function ApplyMargins(const ABounds: TRect): TRect; override;
    function GetSpacing(AElement: TX2MenuBarSpacingElement): Integer; override;
    function GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer; override;
    function GetGroupHeight(AGroup: TX2MenuBarGroup): Integer; override;
    function GetItemHeight(AItem: TX2MenuBarItem): Integer; override;

    procedure DrawBackground(ACanvas: TCanvas; const ABounds: TRect); override;
    procedure DrawGroupHeader(ACanvas: TCanvas; AGroup: TX2MenuBarGroup; const ABounds: TRect; AState: TX2MenuBarDrawStates); override;
    procedure DrawItem(ACanvas: TCanvas; AItem: TX2MenuBarItem; const ABounds: TRect; AState: TX2MenuBarDrawStates); override;
  published
    property AnimationStyle;
    property AnimationTime;
    property BlurShadow:      Boolean read FBlurShadow  write SetBlurShadow;
  end;

implementation
uses
  Classes,
  ImgList,
  SysUtils;



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


{ TX2MenuBarunaPainter }
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
  InflateRect(Result, -10, -10);
end;

function TX2MenuBarunaPainter.GetSpacing(AElement: TX2MenuBarSpacingElement): Integer;
begin
  Result  := inherited GetSpacing(AElement);
  
  case AElement of
    seBeforeGroupHeader,
    seAfterGroupHeader:   Result  := 5;
    seAfterLastItem:      Result  := 10;
    seBeforeItem,
    seAfterItem:          Result  := 4;
  end;
end;

function TX2MenuBarunaPainter.GetGroupHeaderHeight(AGroup: TX2MenuBarGroup): Integer;
begin
  Result := 22;
end;

function TX2MenuBarunaPainter.GetGroupHeight(AGroup: TX2MenuBarGroup): Integer;
begin
  Result := GetSpacing(seBeforeFirstItem) +
            (AGroup.Items.Count * (GetSpacing(seBeforeItem) + 21 +
                                   GetSpacing(seAfterItem))) +
            GetSpacing(seAfterLastItem);
end;

function TX2MenuBarunaPainter.GetItemHeight(AItem: TX2MenuBarItem): Integer;
begin
  Result := 21;
end;


procedure TX2MenuBarunaPainter.DrawBackground(ACanvas: TCanvas;
                                              const ABounds: TRect);
begin
  ACanvas.Brush.Color := clWindow;
  ACanvas.FillRect(ABounds);
end;

procedure TX2MenuBarunaPainter.DrawGroupHeader(ACanvas: TCanvas;
                                               AGroup: TX2MenuBarGroup;
                                               const ABounds: TRect;
                                               AState: TX2MenuBarDrawStates);
  procedure DrawShadowOutline(AShadowCanvas: TCanvas; AShadowBounds: TRect);
  begin
    // #ToDo1 (MvR) 27-3-2006: make the color a property
    if BlurShadow then
    begin
      AShadowCanvas.Brush.Color := $00c3c3c3;
      AShadowCanvas.Pen.Color   := $00c3c3c3;
    end else
    begin
      AShadowCanvas.Brush.Color := $00404040;
      AShadowCanvas.Pen.Color   := $00404040;
    end;

    AShadowCanvas.RoundRect(AShadowBounds.Left + 2,
                            AShadowBounds.Top + 2,
                            AShadowBounds.Right + 2,
                            AShadowBounds.Bottom + 2, 5, 5);
  end;

var
  textRect:         TRect;
  imageList:        TCustomImageList;
  imagePos:         TPoint;
  shadowBitmap:     Graphics.TBitmap;

begin
  if not ((mdsSelected in AState) or (mdsGroupSelected in AState)) then
  begin
    { Shadow }
    if BlurShadow then
    begin
      shadowBitmap  := Graphics.TBitmap.Create();
      try
        shadowBitmap.PixelFormat  := pf32bit;
        shadowBitmap.Width        := (ABounds.Right - ABounds.Left + 4);
        shadowBitmap.Height       := (ABounds.Bottom - ABounds.Top + 4);

        DrawBackground(shadowBitmap.Canvas, Rect(0, 0, shadowBitmap.Width,
                                                 shadowBitmap.Height));
        DrawShadowOutline(shadowBitmap.Canvas, Rect(0, 0, shadowBitmap.Width - 4,
                          shadowBitmap.Height - 4));

        Blur(shadowBitmap);
        ACanvas.Draw(ABounds.Left, ABounds.Top, shadowBitmap);
      finally
        FreeAndNil(shadowBitmap);
      end
    end else
      DrawShadowOutline(ACanvas, ABounds);
  end;

  ACanvas.Brush.Color := $00E9E9E9;

  { Rounded rectangle }
  if (mdsSelected in AState) or (mdsHot in AState) or
     (mdsGroupSelected in AState) then
    ACanvas.Pen.Color := $00BE6363
  else
    ACanvas.Pen.Color := clBlack;

  ACanvas.Font.Color  := ACanvas.Pen.Color;
  ACanvas.RoundRect(ABounds.Left, ABounds.Top, ABounds.Right, ABounds.Bottom, 5, 5);

  textRect            := ABounds;
  Inc(textRect.Left, 4);
  Dec(textRect.Right, 4);

  { Image }
  imageList := AGroup.MenuBar.ImageList;
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
var
  focusBounds:      TRect;
  textBounds:       TRect;
  arrowPoints:      array[0..2] of TPoint;

begin
  focusBounds := ABounds;
  Dec(focusBounds.Right, 10);

  if (mdsSelected in AState) then
  begin
    { Focus rectangle }
    SetTextColor(ACanvas.Handle, ColorToRGB(clBlack));
    DrawFocusRect(ACanvas.Handle, focusBounds);

    { Arrow }
    ACanvas.Brush.Color := clBlue;
    ACanvas.Pen.Color   := clBlue;

    arrowPoints[0].X    := ABounds.Right - 8;
    arrowPoints[0].Y    := ABounds.Top + ((ABounds.Bottom - ABounds.Top - 15) div 2) + 7;
    arrowPoints[1].X    := Pred(ABounds.Right);
    arrowPoints[1].Y    := arrowPoints[0].Y - 7;
    arrowPoints[2].X    := Pred(ABounds.Right);
    arrowPoints[2].Y    := arrowPoints[0].Y + 7;
    ACanvas.Polygon(arrowPoints);
  end;

  { Text }
  if (mdsSelected in AState) or (mdsHot in AState) then
    ACanvas.Font.Color  := clBlack
  else
    ACanvas.Font.Color  := $00404040;

  textBounds  := focusBounds;
  Inc(textBounds.Left, 4);
  Dec(textBounds.Right, 4);

  SetBkMode(ACanvas.Handle, TRANSPARENT);
  ACanvas.Font.Style  := [];
  
  DrawText(ACanvas, AItem.Caption, textBounds, taRightJustify, taVerticalCenter,
           False, csEllipsis);
end;

end.
