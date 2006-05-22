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
  Graphics;

type
  TX2Color32  = type TColor;

  function Color32(AColor: TColor; AAlpha: Byte = 255): TX2Color32;
  function DelphiColor(AColor: TX2Color32): TColor;

  function RedValue(AColor: TX2Color32): Byte;
  function GreenValue(AColor: TX2Color32): Byte;
  function BlueValue(AColor: TX2Color32): Byte;
  function AlphaValue(AColor: TX2Color32): Byte;

  function Blend(ABackground: TColor; AForeground: TX2Color32): TColor;

implementation
uses
  Windows;

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

end.
