unit UPixelConvert;

interface

uses
  VCL.Graphics;

type

  TEColorSpace = (csFullColor, csRGB, csCMYK, csHSI, csYIQ);

  TRColorChannels = record
    case TEColorSpace of
      csFullColor:
        (FullColor: TColor);
      csRGB:
        (ccRed, ccGreen, ccBlue: double);
      csCMYK:
        (ccCyan, ccMagenta, ccYellow, ccKeyColor: double);
      csHSI:
        (ccHue, ccSaturation, ccIntensity: double);
      csYIQ:
        (ccY, ccI, ccQ: double);
  end;

  TColorPixel = class
  private
    ColorSpace: TEColorSpace;
    ColorChannels: TRColorChannels;
    procedure RGBToFullColor;
    procedure FullColorToRGB;

    procedure RGBToCMYK;
    procedure CMYKToRGB;

    procedure RGBToHSI;
    procedure HSIToRGB;

    procedure RGBToYIQ;
    procedure YIQToRGB;

    procedure ConvertTo(Target: TEColorSpace);
  public
    procedure SetFullColor(Color: TColor);
    function GetFullColor: TColor;

    procedure SetRed(red: double);
    function GetRed: double;
    procedure SetGreen(green: double);
    function GetGreen: double;
    procedure SetBlue(blue: double);
    function GetBlue: double;

    procedure SetCyan(cyan: double);
    function GetCyan: double;
    procedure SetMagenta(magenta: double);
    function GetMagenta: double;
    procedure SetYellow(yellow: double);
    function GetYellow: double;
    procedure SetKeyColor(keyColor: double);
    function GetKeyColor: double;

    procedure SetHue(hue: double);
    function GetHue: double;
    procedure SetSaturation(saturation: double);
    function GetSaturation: double;
    procedure SetIntensity(intensity: double);
    function GetIntensity: double;

    procedure SetY(Y: double);
    function GetY: double;
    procedure SetI(I: double);
    function GetI: double;
    procedure SetQ(Q: double);
    function GetQ: double;

  end;

function TruncateBits(value: double; bits: byte): byte;

implementation

uses
  Winapi.Windows, Math;

procedure TColorPixel.RGBToFullColor;
begin
  self.ColorSpace := csFullColor;
  if self.ColorChannels.ccRed > 1 then
    self.ColorChannels.ccRed := 1;
  if self.ColorChannels.ccGreen > 1 then
    self.ColorChannels.ccGreen := 1;
  if self.ColorChannels.ccBlue > 1 then
    self.ColorChannels.ccBlue := 1;
  if self.ColorChannels.ccRed < 0 then
    self.ColorChannels.ccRed := 0;
  if self.ColorChannels.ccGreen < 0 then
    self.ColorChannels.ccGreen := 0;
  if self.ColorChannels.ccBlue < 0 then
    self.ColorChannels.ccBlue := 0;
  self.ColorChannels.FullColor :=
    Winapi.Windows.RGB(round(self.ColorChannels.ccRed * 255),
    round(self.ColorChannels.ccGreen * 255),
    round(self.ColorChannels.ccBlue * 255));
end;

procedure TColorPixel.FullColorToRGB;
var
  Color: TColor;
  tmp: byte;
begin
  self.ColorSpace := csRGB;
  Color := self.ColorChannels.FullColor;
  tmp := Color;
  self.ColorChannels.ccRed := tmp / 255;
  tmp := Color shr 8;
  self.ColorChannels.ccGreen := tmp / 255;
  tmp := Color shr 16;
  self.ColorChannels.ccBlue := tmp / 255;
end;

procedure TColorPixel.RGBToCMYK;
var
  r, g, b: double;
begin
  self.ColorSpace := csCMYK;
  r := self.ColorChannels.ccRed;
  g := self.ColorChannels.ccGreen;
  b := self.ColorChannels.ccBlue;
  self.ColorChannels.ccKeyColor := 1 - max(max(r, g), b);
  if self.ColorChannels.ccKeyColor <> 1 then
  begin
    self.ColorChannels.ccCyan := (1 - r - self.ColorChannels.ccKeyColor) /
      (1 - self.ColorChannels.ccKeyColor);
    self.ColorChannels.ccMagenta := (1 - g - self.ColorChannels.ccKeyColor) /
      (1 - self.ColorChannels.ccKeyColor);
    self.ColorChannels.ccYellow := (1 - b - self.ColorChannels.ccKeyColor) /
      (1 - self.ColorChannels.ccKeyColor);
  end
  else
  begin
    self.ColorChannels.ccCyan := 1;
    self.ColorChannels.ccMagenta := 1;
    self.ColorChannels.ccYellow := 1;
  end;
end;

procedure TColorPixel.CMYKToRGB;
var
  C, M, Y, K: double;
begin
  self.ColorSpace := csRGB;
  C := self.ColorChannels.ccCyan;
  M := self.ColorChannels.ccMagenta;
  Y := self.ColorChannels.ccYellow;
  K := self.ColorChannels.ccKeyColor;
  self.ColorChannels.ccRed := (1 - C) * (1 - K);
  self.ColorChannels.ccGreen := (1 - M) * (1 - K);
  self.ColorChannels.ccBlue := (1 - Y) * (1 - K);
end;

procedure TColorPixel.RGBToHSI;
var
  r, g, b: double;
begin
  self.ColorSpace := csHSI;
  r := self.ColorChannels.ccRed;
  g := self.ColorChannels.ccGreen;
  b := self.ColorChannels.ccBlue;
  self.ColorChannels.ccIntensity := (r + g + b) / 3;
  if self.ColorChannels.ccIntensity > 0 then
    self.ColorChannels.ccSaturation := 1 - min(min(r, g), b) /
      self.ColorChannels.ccIntensity
  else
    self.ColorChannels.ccSaturation := 0;
  if self.ColorChannels.ccSaturation <> 0 then
  begin
    r := round(r * 255);
    g := round(g * 255);
    b := round(b * 255);
    if g >= b then
      self.ColorChannels.ccHue :=
        RadToDeg(arccos((r - g / 2 - b / 2) / sqrt(sqr(r) + sqr(g) + sqr(b) - r
        * g - r * b - g * b)))
    else
      self.ColorChannels.ccHue := 360 -
        RadToDeg(arccos((r - g / 2 - b / 2) / sqrt(sqr(r) + sqr(g) + sqr(b) - r
        * g - r * b - g * b)))
  end
  else
    self.ColorChannels.ccHue := 500;
end;

procedure TColorPixel.HSIToRGB;
var
  H, S, I: double;
begin
  self.ColorSpace := csRGB;
  H := self.ColorChannels.ccHue;
  S := self.ColorChannels.ccSaturation;
  I := self.ColorChannels.ccIntensity;
  if H = 0 then
  begin
    self.ColorChannels.ccRed := I + 2 * I * S;
    self.ColorChannels.ccGreen := I - I * S;
    self.ColorChannels.ccBlue := I - I * S;
  end
  else if (0 < H) and (H < 120) then
  begin
    self.ColorChannels.ccRed := I + I * S * cos(DegToRad(H)) /
      cos(DegToRad(60 - H));
    self.ColorChannels.ccGreen := I + I * S *
      (1 - cos(DegToRad(H)) / cos(DegToRad(60 - H)));
    self.ColorChannels.ccBlue := I - I * S;
  end
  else if (H = 120) then
  begin
    self.ColorChannels.ccRed := I - I * S;
    self.ColorChannels.ccGreen := I + 2 * I * S;
    self.ColorChannels.ccBlue := I - I * S;
  end
  else if (120 < H) and (H < 240) then
  begin
    self.ColorChannels.ccRed := I - I * S;
    self.ColorChannels.ccGreen := I + I * S * cos(DegToRad(H - 120)) /
      cos(DegToRad(180 - H));
    self.ColorChannels.ccBlue := I + I * S *
      (1 - cos(DegToRad(H - 120)) / cos(DegToRad(180 - H)));
  end
  else if H = 240 then
  begin
    self.ColorChannels.ccRed := I - I * S;
    self.ColorChannels.ccGreen := I - I * S;
    self.ColorChannels.ccBlue := I + 2 * I * S;
  end
  else if (240 < H) and (H < 360) then
  begin
    self.ColorChannels.ccRed := I + I * S *
      (1 - cos(DegToRad(H - 240)) / cos(DegToRad(300 - H)));
    self.ColorChannels.ccGreen := I - I * S;
    self.ColorChannels.ccBlue := I + I * S * cos(DegToRad(H - 240)) /
      cos(DegToRad(300 - H));
  end
  else if H > 360 then
  begin
    self.ColorChannels.ccRed := I;
    self.ColorChannels.ccGreen := I;
    self.ColorChannels.ccBlue := I;
  end;
end;

procedure TColorPixel.RGBToYIQ;
var
  r, g, b: double;
begin
  self.ColorSpace := csYIQ;
  r := self.ColorChannels.ccRed;
  g := self.ColorChannels.ccGreen;
  b := self.ColorChannels.ccBlue;
  self.ColorChannels.ccY := 0.299 * r + 0.587 * g + 0.114 * b;
  self.ColorChannels.ccI := 0.596 * r - 0.274 * g - 0.321 * b;
  self.ColorChannels.ccQ := 0.211 * r - 0.523 * g + 0.311 * b;
end;

procedure TColorPixel.YIQToRGB;
var
  Y, I, Q: double;
begin
  self.ColorSpace := csRGB;
  Y := self.ColorChannels.ccY;
  I := self.ColorChannels.ccI;
  Q := self.ColorChannels.ccQ;
  self.ColorChannels.ccRed := Y + 0.956 * I + 0.621 * Q;
  self.ColorChannels.ccGreen := Y - 0.272 * I - 0.647 * Q;
  self.ColorChannels.ccBlue := Y - 1.107 * I + 1.706 * Q;
end;

procedure TColorPixel.ConvertTo(Target: TEColorSpace);
var
  From: TEColorSpace;
begin
  From := self.ColorSpace;
  if From <> Target then
  begin
    case From of
      csFullColor:
        FullColorToRGB;
      csRGB:
        ;
      csCMYK:
        CMYKToRGB;
      csHSI:
        HSIToRGB;
      csYIQ:
        YIQToRGB;
    end;
    case Target of
      csFullColor:
        RGBToFullColor;
      csRGB:
        ;
      csCMYK:
        RGBToCMYK;
      csHSI:
        RGBToHSI;
      csYIQ:
        RGBToYIQ;
    end;
  end;
end;

procedure TColorPixel.SetFullColor(Color: TColor);
begin
  self.ColorSpace := csFullColor;
  self.ColorChannels.FullColor := Color;
end;

function TColorPixel.GetFullColor: TColor;
begin
  ConvertTo(csFullColor);
  GetFullColor := self.ColorChannels.FullColor;
end;

procedure TColorPixel.SetRed(red: double);
begin
  ConvertTo(csRGB);
  self.ColorChannels.ccRed := red;
end;

function TColorPixel.GetRed: double;
begin
  ConvertTo(csRGB);
  GetRed := self.ColorChannels.ccRed;
end;

procedure TColorPixel.SetGreen(green: double);
begin
  ConvertTo(csRGB);
  self.ColorChannels.ccGreen := green;
end;

function TColorPixel.GetGreen: double;
begin
  ConvertTo(csRGB);
  GetGreen := self.ColorChannels.ccGreen;
end;

procedure TColorPixel.SetBlue(blue: double);
begin
  ConvertTo(csRGB);
  self.ColorChannels.ccBlue := blue;
end;

function TColorPixel.GetBlue: double;
begin
  ConvertTo(csRGB);
  GetBlue := self.ColorChannels.ccBlue;
end;

procedure TColorPixel.SetCyan(cyan: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccCyan := cyan;
end;

function TColorPixel.GetCyan: double;
begin
  ConvertTo(csCMYK);
  GetCyan := self.ColorChannels.ccCyan;
end;

procedure TColorPixel.SetMagenta(magenta: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccMagenta := magenta;
end;

function TColorPixel.GetMagenta: double;
begin
  ConvertTo(csCMYK);
  GetMagenta := self.ColorChannels.ccMagenta;
end;

procedure TColorPixel.SetYellow(yellow: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccYellow := yellow;
end;

function TColorPixel.GetYellow: double;
begin
  ConvertTo(csCMYK);
  GetYellow := self.ColorChannels.ccYellow;
end;

procedure TColorPixel.SetKeyColor(keyColor: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccKeyColor := keyColor;
end;

function TColorPixel.GetKeyColor: double;
begin
  ConvertTo(csCMYK);
  GetKeyColor := self.ColorChannels.ccKeyColor;
end;

procedure TColorPixel.SetHue(hue: double);
begin
  ConvertTo(csHSI);
  self.ColorChannels.ccHue := hue;
end;

function TColorPixel.GetHue: double;
begin
  ConvertTo(csHSI);
  GetHue := self.ColorChannels.ccHue;
end;

procedure TColorPixel.SetSaturation(saturation: double);
begin
  ConvertTo(csHSI);
  self.ColorChannels.ccSaturation := saturation;
end;

function TColorPixel.GetSaturation: double;
begin
  ConvertTo(csHSI);
  GetSaturation := self.ColorChannels.ccSaturation;
end;

procedure TColorPixel.SetIntensity(intensity: double);
begin
  ConvertTo(csHSI);
  self.ColorChannels.ccIntensity := intensity;
end;

function TColorPixel.GetIntensity: double;
begin
  ConvertTo(csHSI);
  GetIntensity := self.ColorChannels.ccIntensity;
end;

procedure TColorPixel.SetY(Y: double);
begin
  ConvertTo(csYIQ);
  self.ColorChannels.ccY := Y;
end;

function TColorPixel.GetY: double;
begin
  ConvertTo(csYIQ);
  GetY := self.ColorChannels.ccY;
end;

procedure TColorPixel.SetI(I: double);
begin
  ConvertTo(csYIQ);
  self.ColorChannels.ccI := I;
end;

function TColorPixel.GetI: double;
begin
  ConvertTo(csYIQ);
  GetI := self.ColorChannels.ccI;
end;

procedure TColorPixel.SetQ(Q: double);
begin
  ConvertTo(csYIQ);
  self.ColorChannels.ccQ := Q;
end;

function TColorPixel.GetQ: double;
begin
  ConvertTo(csYIQ);
  GetQ := self.ColorChannels.ccQ;
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
