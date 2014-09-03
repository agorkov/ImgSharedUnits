unit UPixelConvert;

interface

uses
  VCL.Graphics;

type
  TColorSpace = (csRGB, csCMYK, csHSI, csYIQ);

  TRColor = record
    ColorSpace: TColorSpace;
    case TColorSpace of
    csRGB: (ccRed, ccGreen, ccBlue: double);
    csCMYK: (ccCyan, ccMagenta, ccYellow, ccKeyColor: double);
    csHSI: (ccHue, ccSaturation, ccIntensity: double);
    csYIQ: (ccY, ccI, ccQ: double);
  end;

function ColorToRGB(Color: TColor): TRColor;
function RGBToColor(RGB: TRColor): TColor;
function RGBToCMYK(RGB: TRColor): TRColor;
function CMYKToRGB(CMYK: TRColor): TRColor;
function RGBToHSI(RGB: TRColor): TRColor;
function HSIToRGB(HSI: TRColor): TRColor;
function RGBToYIQ(RGB: TRColor): TRColor;
function YIQToRGB(YIQ: TRColor): TRColor;
function RGBToGS(RGB: TRColor): double;
function TruncateBits(value: double; bits: byte): byte;

implementation

uses
  Winapi.Windows, Math;

function ColorToRGB(Color: TColor): TRColor;
var
  r: TRColor;
  tmp: byte;
begin
  r.ColorSpace := csRGB;
  tmp := Color;
  r.ccRed := tmp / 255;
  tmp := Color shr 8;
  r.ccGreen := tmp / 255;
  tmp := Color shr 16;
  r.ccBlue := tmp / 255;
  ColorToRGB := r;
end;

function RGBToColor(RGB: TRColor): TColor;
begin
  if RGB.ccRed > 1 then
    RGB.ccRed := 1;
  if RGB.ccGreen > 1 then
    RGB.ccGreen := 1;
  if RGB.ccBlue > 1 then
    RGB.ccBlue := 1;
  if RGB.ccRed < 0 then
    RGB.ccRed := 0;
  if RGB.ccGreen < 0 then
    RGB.ccGreen := 0;
  if RGB.ccBlue < 0 then
    RGB.ccBlue := 0;
  RGBToColor := Winapi.Windows.RGB(round(RGB.ccRed * 255), round(RGB.ccGreen * 255), round(RGB.ccBlue * 255));
end;

function RGBToCMYK(RGB: TRColor): TRColor;
var
  r: TRColor;
begin
  r.ColorSpace := csCMYK;
  r.ccKeyColor := 1 - max(max(RGB.ccRed, RGB.ccGreen), RGB.ccBlue);
  if r.ccKeyColor <> 1 then
  begin
    r.ccCyan := (1 - RGB.ccRed - r.ccKeyColor) / (1 - r.ccKeyColor);
    r.ccMagenta := (1 - RGB.ccGreen - r.ccKeyColor) / (1 - r.ccKeyColor);
    r.ccYellow := (1 - RGB.ccBlue - r.ccKeyColor) / (1 - r.ccKeyColor);
  end
  else
  begin
    r.ccCyan := 1;
    r.ccMagenta := 1;
    r.ccYellow := 1;
  end;
  RGBToCMYK := r;
end;

function CMYKToRGB(CMYK: TRColor): TRColor;
var
  r: TRColor;
begin
  r.ColorSpace := csRGB;
  r.ccRed := (1 - CMYK.ccCyan) * (1 - CMYK.ccKeyColor);
  r.ccGreen := (1 - CMYK.ccMagenta) * (1 - CMYK.ccKeyColor);
  r.ccBlue := (1 - CMYK.ccYellow) * (1 - CMYK.ccKeyColor);
  CMYKToRGB := r;
end;

function RGBToHSI(RGB: TRColor): TRColor;
var
  r: TRColor;
begin
  r.ColorSpace := csHSI;
  r.ccIntensity := (RGB.ccRed + RGB.ccGreen + RGB.ccBlue) / 3;
  if r.ccIntensity > 0 then
    r.ccSaturation := 1 - min(min(RGB.ccRed, RGB.ccGreen), RGB.ccBlue) / r.ccIntensity
  else
    r.ccSaturation := 0;
  if r.ccSaturation <> 0 then
  begin
    RGB.ccRed := round(RGB.ccRed * 255);
    RGB.ccGreen := round(RGB.ccGreen * 255);
    RGB.ccBlue := round(RGB.ccBlue * 255);
    if RGB.ccGreen >= RGB.ccBlue then
      r.ccHue := RadToDeg(arccos((RGB.ccRed - RGB.ccGreen / 2 - RGB.ccBlue / 2) / sqrt(sqr(RGB.ccRed) + sqr(RGB.ccGreen) + sqr(RGB.ccBlue) - RGB.ccRed * RGB.ccGreen - RGB.ccRed * RGB.ccBlue - RGB.ccGreen * RGB.ccBlue)))
    else
      r.ccHue := 360 - RadToDeg(arccos((RGB.ccRed - RGB.ccGreen / 2 - RGB.ccBlue / 2) / sqrt(sqr(RGB.ccRed) + sqr(RGB.ccGreen) + sqr(RGB.ccBlue) - RGB.ccRed * RGB.ccGreen - RGB.ccRed * RGB.ccBlue - RGB.ccGreen * RGB.ccBlue)))
  end
  else
    r.ccHue := 500;
  RGBToHSI := r;
end;

function HSIToRGB(HSI: TRColor): TRColor;
var
  r: TRColor;
begin
  r.ColorSpace := csRGB;
  if HSI.ccHue = 0 then
  begin
    r.ccRed := HSI.ccIntensity + 2 * HSI.ccIntensity * HSI.ccSaturation;
    r.ccGreen := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
    r.ccBlue := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
  end
  else
    if (0 < HSI.ccHue) and (HSI.ccHue < 120) then
    begin
      r.ccRed := HSI.ccIntensity + HSI.ccIntensity * HSI.ccSaturation * cos(DegToRad(HSI.ccHue)) / cos(DegToRad(60 - HSI.ccHue));
      r.ccGreen := HSI.ccIntensity + HSI.ccIntensity * HSI.ccSaturation * (1 - cos(DegToRad(HSI.ccHue)) / cos(DegToRad(60 - HSI.ccHue)));
      r.ccBlue := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
    end
    else
      if (HSI.ccHue = 120) then
      begin
        r.ccRed := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
        r.ccGreen := HSI.ccIntensity + 2 * HSI.ccIntensity * HSI.ccSaturation;
        r.ccBlue := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
      end
      else
        if (120 < HSI.ccHue) and (HSI.ccHue < 240) then
        begin
          r.ccRed := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
          r.ccGreen := HSI.ccIntensity + HSI.ccIntensity * HSI.ccSaturation * cos(DegToRad(HSI.ccHue - 120)) / cos(DegToRad(180 - HSI.ccHue));
          r.ccBlue := HSI.ccIntensity + HSI.ccIntensity * HSI.ccSaturation * (1 - cos(DegToRad(HSI.ccHue - 120)) / cos(DegToRad(180 - HSI.ccHue)));
        end
        else
          if HSI.ccHue = 240 then
          begin
            r.ccRed := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
            r.ccGreen := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
            r.ccBlue := HSI.ccIntensity + 2 * HSI.ccIntensity * HSI.ccSaturation;
          end
          else
            if (240 < HSI.ccHue) and (HSI.ccHue < 360) then
            begin
              r.ccRed := HSI.ccIntensity + HSI.ccIntensity * HSI.ccSaturation * (1 - cos(DegToRad(HSI.ccHue - 240)) / cos(DegToRad(300 - HSI.ccHue)));
              r.ccGreen := HSI.ccIntensity - HSI.ccIntensity * HSI.ccSaturation;
              r.ccBlue := HSI.ccIntensity + HSI.ccIntensity * HSI.ccSaturation * cos(DegToRad(HSI.ccHue - 240)) / cos(DegToRad(300 - HSI.ccHue));
            end
            else
              if HSI.ccHue > 360 then
              begin
                r.ccRed := HSI.ccIntensity;
                r.ccGreen := HSI.ccIntensity;
                r.ccBlue := HSI.ccIntensity;
              end;
  HSIToRGB := r;
end;

function RGBToYIQ(RGB: TRColor): TRColor;
var
  r: TRColor;
begin
  r.ColorSpace := csYIQ;
  r.ccY := 0.299 * RGB.ccRed + 0.587 * RGB.ccGreen + 0.114 * RGB.ccBlue;
  r.ccI := 0.596 * RGB.ccRed - 0.274 * RGB.ccGreen - 0.321 * RGB.ccBlue;
  r.ccQ := 0.211 * RGB.ccRed - 0.523 * RGB.ccGreen + 0.311 * RGB.ccBlue;
  RGBToYIQ := r;
end;

function YIQToRGB(YIQ: TRColor): TRColor;
var
  r: TRColor;
begin
  r.ColorSpace := csRGB;
  r.ccRed := YIQ.ccY + 0.956 * YIQ.ccI + 0.621 * YIQ.ccQ;
  r.ccGreen := YIQ.ccY - 0.272 * YIQ.ccI - 0.647 * YIQ.ccQ;
  r.ccBlue := YIQ.ccY - 1.107 * YIQ.ccI + 1.706 * YIQ.ccQ;
  YIQToRGB := r;
end;

function RGBToGS(RGB: TRColor): double;
begin
  RGBToGS := RGBToYIQ(RGB).ccY;
end;

function TruncateBits(value: double; bits: byte): byte;
var
  StepReal: real;
  StepByte: byte;
  I: byte;
  r: byte;
begin
  if value > 1 then
    value := 1;
  if value < 0 then
    value := 0;
  StepReal := 1 / (1 shl bits);
  StepByte := 256 div (1 shl bits);
  I := 0;
  while I * StepReal < value do
    I := I + 1;
  if bits < 8 then
    r := (I - 1) * StepByte + (StepByte div 2)
  else
    r := I;
  TruncateBits := r;
end;

end.
