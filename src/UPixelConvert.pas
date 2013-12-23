unit UPixelConvert;

interface

uses
  VCL.Graphics;

procedure TColorToRGB(Color: TColor; var r, g, b: double);
function RGBToColor(r, g, b: double): TColor;

procedure RGBToCMYK(r, g, b: double; var C, M, Y, K: double);
procedure CMYKToRGB(var r, g, b: double; C, M, Y, K: double);

procedure RGBToHSI(r, g, b: double; var H, S, I: double);
procedure HSIToRGB(var r, g, b: double; H, S, I: double);

procedure RGBToYIQ(r, g, b: double; var Y, I, Q: double);
procedure YIQToRGB(var r, g, b: double; Y, I, Q: double);

function RGBToGS(r, g, b: double): double;
function NormalizationByte(value: double; bits: byte): byte;

implementation

uses
  Winapi.Windows, Math;

function max2(a1, a2: double): double;
var
  r: double;
begin
  if a1 > a2 then
    r := a1
  else
    r := a2;
  max2 := r;
end;

function max3(a1, a2, a3: double): double;
var
  r: double;
begin
  r := max2(a1, a2);
  if a3 > r then
    r := a3;
  max3 := r;
end;

function min2(a1, a2: double): double;
var
  r: double;
begin
  if a1 < a2 then
    r := a1
  else
    r := a2;
  min2 := r;
end;

function min3(a1, a2, a3: double): double;
var
  r: double;
begin
  r := min2(a1, a2);
  if a3 < r then
    r := a3;
  min3 := r;
end;

function NormalizationByte(value: double; bits: byte): byte;
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

  NormalizationByte := r;
end;

procedure TColorToRGB(Color: TColor; var r, g, b: double);
var
  rb, gb, bb: byte;
begin
  rb := Color;
  r := rb / 255;
  gb := Color shr 8;
  g := gb / 255;
  bb := Color shr 16;
  b := bb / 255;
end;

function RGBToColor(r, g, b: double): TColor;
begin
  if r > 1 then
    r := 1;
  if g > 1 then
    g := 1;
  if b > 1 then
    b := 1;
  if r < 0 then
    r := 0;
  if g < 0 then
    g := 0;
  if b < 0 then
    b := 0;
  RGBToColor := RGB(round(r * 255), round(g * 255), round(b * 255));
end;

procedure RGBToCMYK(r, g, b: double; var C, M, Y, K: double);
begin
  K := 1 - max3(r, g, b);
  if K <> 1 then
  begin
    C := (1 - r - K) / (1 - K);
    M := (1 - g - K) / (1 - K);
    Y := (1 - b - K) / (1 - K);
  end
  else
  begin
    C := 1;
    M := 1;
    Y := 1;
  end;
end;

procedure CMYKToRGB(var r, g, b: double; C, M, Y, K: double);
begin
  r := (1 - C) * (1 - K);
  g := (1 - M) * (1 - K);
  b := (1 - Y) * (1 - K);
end;

procedure RGBToHSI(r, g, b: double; var H, S, I: double);
begin
  I := (r + g + b) / 3;
  if I > 0 then
    S := 1 - min3(r, g, b) / I
  else
    S := 0;
  if S <> 0 then
  begin
    r := round(r * 255);
    g := round(g * 255);
    b := round(b * 255);
    if g >= b then
      H := RadToDeg(arccos((r - g / 2 - b / 2) / sqrt(sqr(r) + sqr(g) + sqr(b) - r * g - r * b - g * b)))
    else
      H := 360 - RadToDeg(arccos((r - g / 2 - b / 2) / sqrt(sqr(r) + sqr(g) + sqr(b) - r * g - r * b - g * b)))
  end
  else
    H := 500;
end;

procedure HSIToRGB(var r, g, b: double; H, S, I: double);
begin
  if H = 0 then
  begin
    r := I + 2 * I * S;
    g := I - I * S;
    b := I - I * S;
  end
  else
    if (0 < H) and (H < 120) then
    begin
      r := I + I * S * cos(DegToRad(H)) / cos(DegToRad(60 - H));
      g := I + I * S * (1 - cos(DegToRad(H)) / cos(DegToRad(60 - H)));
      b := I - I * S;
    end
    else
      if (H = 120) then
      begin
        r := I - I * S;
        g := I + 2 * I * S;
        b := I - I * S;
      end
      else
        if (120 < H) and (H < 240) then
        begin
          r := I - I * S;
          g := I + I * S * cos(DegToRad(H - 120)) / cos(DegToRad(180 - H));
          b := I + I * S * (1 - cos(DegToRad(H - 120)) / cos(DegToRad(180 - H)));
        end
        else
          if H = 240 then
          begin
            r := I - I * S;
            g := I - I * S;
            b := I + 2 * I * S;
          end
          else
            if (240 < H) and (H < 360) then
            begin
              r := I + I * S * (1 - cos(DegToRad(H - 240)) / cos(DegToRad(300 - H)));
              g := I - I * S;
              b := I + I * S * cos(DegToRad(H - 240)) / cos(DegToRad(300 - H));
            end
            else
              if H > 360 then
              begin
                r := I;
                g := I;
                b := I;
              end;
end;

procedure RGBToYIQ(r, g, b: double; var Y, I, Q: double);
begin
  Y := 0.299 * r + 0.587 * g + 0.114 * b;
  I := 0.596 * r - 0.274 * g - 0.321 * b;
  Q := 0.211 * r - 0.523 * g + 0.311 * b;
end;

procedure YIQToRGB(var r, g, b: double; Y, I, Q: double);
begin
  r := Y + 0.956 * I + 0.621 * Q;
  g := Y - 0.272 * I - 0.647 * Q;
  b := Y - 1.107 * I + 1.706 * Q;
end;

function RGBToGS(r, g, b: double): double;
var
  Y, I, Q: double;
begin
  RGBToYIQ(r, g, b, Y, I, Q);
  RGBToGS := Y;
end;

end.
