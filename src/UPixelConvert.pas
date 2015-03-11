unit UPixelConvert;

interface

uses
  VCL.Graphics;

type
  /// Поддерживаемые цветовые пространства:
  /// csFullColor - стандартный TColor
  /// csRGB - аддитивный цветовой куб RGB
  /// csCMYK - субтрактивное цветовое пространство (субстративный аналог RGB)
  /// csHSI - пространство тон-насыщенность-интенсивность
  /// csYIQ - цветоразностная модель
  TEColorSpace = (csFullColor, csRGB, csCMYK, csHSI, csYIQ);

  /// Константы для каждого цветового канала:
  /// ccRed - красный, ccGreen - зелёный, ccBlue - синий
  /// ccCyan - голубой, ccMagenta - пурпурный, ccYellow - жёлтый, ccKeyColor - ключевой цвет (чёрный)
  /// ccHue - тон, ccSaturation - насыщенность, ccIntensity - интенсивность
  /// ccY - компонента интенсивности, ccI - цветоразностная компонента, ccQ - цветоразностная компонента
  TEColorChannel = (ccRed, ccGreen, ccBlue, ccCyan, ccMagenta, ccYellow, ccKeyColor, ccHue, ccSaturation, ccIntensity, ccY, ccI, ccQ);

  /// Описание цвета. В зависимости от выбранной вариантной части, цвет представляется в одном из поддерживаемых цветовых пространств
  TRColorChannels = record
    case TEColorSpace of
      csFullColor: // Стандартный TColor
        (FullColor: TColor);
      csRGB: // Аддитивный цветовой куб RGB
        (ccRed, ccGreen, ccBlue: double);
      csCMYK: // Субтрактивное цветовое пространство (субстративный аналог RGB)
        (ccCyan, ccMagenta, ccYellow, ccKeyColor: double);
      csHSI: // Пространство тон-насыщенность-интенсивность
        (ccHue, ccSaturation, ccIntensity: double);
      csYIQ: // Цветоразностная модель
        (ccY, ccI, ccQ: double);
  end;

  /// Пиксел цветного изображения
  TColorPixel = class
  private
    ColorSpace: TEColorSpace; // Используемое цветовое пространство
    ColorChannels: TRColorChannels;
    // Цвет, разделённый на каналы в соответствии с выбранным цветовым пространством

    procedure RGBToFullColor; // Преобразование из пространства RGB в TColor
    procedure FullColorToRGB;
    // Преобразование из TColor в цветовое пространство RGB

    procedure RGBToCMYK;
    // Преобразование из пространства RGB в пространство CMYK
    procedure CMYKToRGB;
    // Преобразование из пространства CMYK в пространство RGB

    procedure RGBToHSI; // Преобразование из пространства RGB в пространство HSI
    procedure HSIToRGB; // Преобразование из пространства HSI в пространство RGB

    procedure RGBToYIQ; // Преобразование из пространства RGB в пространство YIQ
    procedure YIQToRGB; // Преобразование из пространства YIQ в пространство RGB

    procedure ConvertTo(Target: TEColorSpace);
    // Преобразование в указаное цветовое пространство

    procedure NormalizeChannels;
    function NormalizeValue(x: double): double;

    procedure SetFullColor(Color: TColor); // Задать TColor
    function GetFullColor: TColor; // Считать TColor

    procedure SetRed(red: double); // Задать красную составляющую
    function GetRed: double; // Получить красную составляющую
    procedure SetGreen(green: double); // Задать зелёную составляющую
    function GetGreen: double; // Получить зелёную составляющую
    procedure SetBlue(blue: double); // Задать синюю составляющую
    function GetBlue: double; // Получить синюю составляющую

    procedure SetCyan(cyan: double); // Задать голубую составляющую
    function GetCyan: double; // Получить голубую составляющую
    procedure SetMagenta(magenta: double); // Задать пурпурную составляющую
    function GetMagenta: double; // Получить пурпурную составляющую
    procedure SetYellow(yellow: double); // Задать жёлтую составляющую
    function GetYellow: double; // Получить жёлтую составляющую
    procedure SetKeyColor(keyColor: double); // Задать ключевую (чёрную) составляющую
    function GetKeyColor: double; // Получить ключевую (чёрную) составляющую

    procedure SetHue(hue: double); // Задать составляющую цветового тона
    function GetHue: double; // Получить составляющую цветового тона
    procedure SetSaturation(saturation: double); // Задать составляющую насыщенности
    function GetSaturation: double; // Получить составляющую насыщенности
    procedure SetIntensity(intensity: double); // Задать составляющую интенсивности
    function GetIntensity: double; // Задать составляющую интенсивности

    procedure SetY(Y: double); // Задать Y составляющую
    function GetY: double; // Получить Y составляющую
    procedure SetI(I: double); // Задать I составляющую
    function GetI: double; // Получить I составляющую
    procedure SetQ(Q: double); // Задать Q составляющую
    function GetQ: double; // Получить Q составляющую
  public

    property FullColor: TColor read GetFullColor write SetFullColor;

    property red: double read GetRed write SetRed;
    property green: double read GetGreen write SetGreen;
    property blue: double read GetBlue write SetBlue;
    procedure SetRGB(R, G, B: double); // Задать все параметры RGB

    property cyan: double read GetCyan write SetCyan;
    property magenta: double read GetMagenta write SetMagenta;
    property yellow: double read GetYellow write SetYellow;
    property keyColor: double read GetKeyColor write SetKeyColor;
    procedure SetCMYK(C, M, Y, K: double); // Задать все параметры CMYK

    property hue: double read GetHue write SetHue;
    property saturation: double read GetSaturation write SetSaturation;
    property intensity: double read GetIntensity write SetIntensity;
    procedure SetHSI(H, S, I: double); // Задать все параметры HSI

    property Y: double read GetY write SetY;
    property I: double read GetI write SetI;
    property Q: double read GetQ write SetQ;
    procedure SetYIQ(Y, I, Q: double); // Задать все параметры YIQ

    procedure SetColorChannel(Channel: TEColorChannel; value: double); // Задать значение указанного цветового канала
    function GetColorChannel(Channel: TEColorChannel): double; // Получить значение указанного цветового канала
  end;

implementation

uses
  Winapi.Windows, Math;

procedure TColorPixel.NormalizeChannels;
begin
  case self.ColorSpace of
    csFullColor:
      ;
    csRGB:
      begin
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
      end;
    csCMYK:
      begin
        if self.ColorChannels.ccCyan > 1 then
          self.ColorChannels.ccCyan := 1;
        if self.ColorChannels.ccMagenta > 1 then
          self.ColorChannels.ccMagenta := 1;
        if self.ColorChannels.ccYellow > 1 then
          self.ColorChannels.ccYellow := 1;
        if self.ColorChannels.ccKeyColor > 1 then
          self.ColorChannels.ccKeyColor := 1;

        if self.ColorChannels.ccCyan < 0 then
          self.ColorChannels.ccCyan := 0;
        if self.ColorChannels.ccMagenta < 0 then
          self.ColorChannels.ccMagenta := 0;
        if self.ColorChannels.ccYellow < 0 then
          self.ColorChannels.ccYellow := 0;
        if self.ColorChannels.ccKeyColor < 0 then
          self.ColorChannels.ccKeyColor := 0;
      end;
    csHSI:
      begin
        if self.ColorChannels.ccHue > 1 then
          self.ColorChannels.ccHue := 1;
        if self.ColorChannels.ccSaturation > 1 then
          self.ColorChannels.ccSaturation := 1;
        if self.ColorChannels.ccIntensity > 1 then
          self.ColorChannels.ccIntensity := 1;

        if self.ColorChannels.ccHue < 0 then
          self.ColorChannels.ccHue := 0;
        if self.ColorChannels.ccSaturation < 0 then
          self.ColorChannels.ccSaturation := 0;
        if self.ColorChannels.ccIntensity < 0 then
          self.ColorChannels.ccIntensity := 0;
      end;
    csYIQ:
      begin
        if self.ColorChannels.ccY > 1 then
          self.ColorChannels.ccY := 1;
        if self.ColorChannels.ccI > 1 then
          self.ColorChannels.ccI := 1;
        if self.ColorChannels.ccQ > 1 then
          self.ColorChannels.ccQ := 1;

        if self.ColorChannels.ccY < 0 then
          self.ColorChannels.ccY := 0;
        if self.ColorChannels.ccI < 0 then
          self.ColorChannels.ccI := 0;
        if self.ColorChannels.ccQ < 0 then
          self.ColorChannels.ccQ := 0;
      end;
  end;
end;

function TColorPixel.NormalizeValue(x: double): double;
begin
  if x > 1 then
    x := 1;
  if x < 0 then
    x := 0;
  NormalizeValue := x;
end;

procedure TColorPixel.RGBToFullColor;
begin
  self.ColorChannels.FullColor := Winapi.Windows.RGB(round(self.ColorChannels.ccRed * 255), round(self.ColorChannels.ccGreen * 255), round(self.ColorChannels.ccBlue * 255));
  self.ColorSpace := csFullColor;
end;

procedure TColorPixel.FullColorToRGB;
var
  Color: TColor;
  tmp: byte;
begin
  Color := self.ColorChannels.FullColor;
  tmp := Color;
  self.ColorChannels.ccRed := tmp / 255;
  tmp := Color shr 8;
  self.ColorChannels.ccGreen := tmp / 255;
  tmp := Color shr 16;
  self.ColorChannels.ccBlue := tmp / 255;
  self.ColorSpace := csRGB;
end;

procedure TColorPixel.RGBToCMYK;
var
  R, G, B: double;
begin
  R := self.ColorChannels.ccRed;
  G := self.ColorChannels.ccGreen;
  B := self.ColorChannels.ccBlue;
  self.ColorChannels.ccKeyColor := 1 - max(max(R, G), B);
  if self.ColorChannels.ccKeyColor <> 1 then
  begin
    self.ColorChannels.ccCyan := (1 - R - self.ColorChannels.ccKeyColor) / (1 - self.ColorChannels.ccKeyColor);
    self.ColorChannels.ccMagenta := (1 - G - self.ColorChannels.ccKeyColor) / (1 - self.ColorChannels.ccKeyColor);
    self.ColorChannels.ccYellow := (1 - B - self.ColorChannels.ccKeyColor) / (1 - self.ColorChannels.ccKeyColor);
  end
  else
  begin
    self.ColorChannels.ccCyan := 1;
    self.ColorChannels.ccMagenta := 1;
    self.ColorChannels.ccYellow := 1;
  end;
  self.ColorSpace := csCMYK;
end;

procedure TColorPixel.CMYKToRGB;
var
  C, M, Y, K: double;
begin
  C := self.ColorChannels.ccCyan;
  M := self.ColorChannels.ccMagenta;
  Y := self.ColorChannels.ccYellow;
  K := self.ColorChannels.ccKeyColor;
  self.ColorChannels.ccRed := (1 - C) * (1 - K);
  self.ColorChannels.ccGreen := (1 - M) * (1 - K);
  self.ColorChannels.ccBlue := (1 - Y) * (1 - K);
  self.ColorSpace := csRGB;
end;

procedure TColorPixel.RGBToHSI;
var
  R, G, B, rHue: double;
begin
  R := self.ColorChannels.ccRed;
  G := self.ColorChannels.ccGreen;
  B := self.ColorChannels.ccBlue;
  self.ColorChannels.ccIntensity := (R + G + B) / 3;
  if self.ColorChannels.ccIntensity > 0 then
    self.ColorChannels.ccSaturation := 1 - min(min(R, G), B) / self.ColorChannels.ccIntensity
  else
    self.ColorChannels.ccSaturation := 0;
  if self.ColorChannels.ccSaturation <> 0 then
  begin
    R := round(R * 255);
    G := round(G * 255);
    B := round(B * 255);
    if G >= B then
      rHue := RadToDeg(arccos((R - G / 2 - B / 2) / sqrt(sqr(R) + sqr(G) + sqr(B) - R * G - R * B - G * B)))
    else
      rHue := 360 - RadToDeg(arccos((R - G / 2 - B / 2) / sqrt(sqr(R) + sqr(G) + sqr(B) - R * G - R * B - G * B)))
  end
  else
    rHue := 361;
  rHue := (rHue + 1) / 363;
  self.ColorChannels.ccHue := rHue;
  self.ColorSpace := csHSI;
end;

procedure TColorPixel.HSIToRGB;
var
  H, S, I: double;
begin
  H := self.ColorChannels.ccHue * 363 - 1;
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
    self.ColorChannels.ccRed := I + I * S * cos(DegToRad(H)) / cos(DegToRad(60 - H));
    self.ColorChannels.ccGreen := I + I * S * (1 - cos(DegToRad(H)) / cos(DegToRad(60 - H)));
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
    self.ColorChannels.ccGreen := I + I * S * cos(DegToRad(H - 120)) / cos(DegToRad(180 - H));
    self.ColorChannels.ccBlue := I + I * S * (1 - cos(DegToRad(H - 120)) / cos(DegToRad(180 - H)));
  end
  else if H = 240 then
  begin
    self.ColorChannels.ccRed := I - I * S;
    self.ColorChannels.ccGreen := I - I * S;
    self.ColorChannels.ccBlue := I + 2 * I * S;
  end
  else if (240 < H) and (H < 360) then
  begin
    self.ColorChannels.ccRed := I + I * S * (1 - cos(DegToRad(H - 240)) / cos(DegToRad(300 - H)));
    self.ColorChannels.ccGreen := I - I * S;
    self.ColorChannels.ccBlue := I + I * S * cos(DegToRad(H - 240)) / cos(DegToRad(300 - H));
  end
  else if H > 360 then
  begin
    self.ColorChannels.ccRed := I;
    self.ColorChannels.ccGreen := I;
    self.ColorChannels.ccBlue := I;
  end;
  self.ColorSpace := csRGB;
end;

procedure TColorPixel.RGBToYIQ;
var
  R, G, B: double;
begin
  R := self.ColorChannels.ccRed;
  G := self.ColorChannels.ccGreen;
  B := self.ColorChannels.ccBlue;
  self.ColorChannels.ccY := 0.299 * R + 0.587 * G + 0.114 * B;
  self.ColorChannels.ccI := 0.596 * R - 0.274 * G - 0.321 * B;
  self.ColorChannels.ccI := (self.ColorChannels.ccI + 0.595) / 1.191;
  self.ColorChannels.ccQ := 0.211 * R - 0.523 * G + 0.311 * B;
  self.ColorChannels.ccQ := (self.ColorChannels.ccQ + 0.523) / 1.045;
  self.ColorSpace := csYIQ;
end;

procedure TColorPixel.YIQToRGB;
var
  Y, I, Q: double;
begin
  Y := self.ColorChannels.ccY;
  I := self.ColorChannels.ccI;
  I := I * 1.191 - 0.595;
  Q := self.ColorChannels.ccQ;
  Q := Q * 1.045 - 0.523;
  self.ColorChannels.ccRed := Y + 0.956 * I + 0.621 * Q;
  self.ColorChannels.ccGreen := Y - 0.272 * I - 0.647 * Q;
  self.ColorChannels.ccBlue := Y - 1.107 * I + 1.706 * Q;
  self.ColorSpace := csRGB;
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
  self.NormalizeChannels;
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
  self.ColorChannels.ccRed := self.NormalizeValue(red);
end;

function TColorPixel.GetRed: double;
begin
  ConvertTo(csRGB);
  GetRed := self.ColorChannels.ccRed;
end;

procedure TColorPixel.SetGreen(green: double);
begin
  ConvertTo(csRGB);
  self.ColorChannels.ccGreen := self.NormalizeValue(green);
end;

function TColorPixel.GetGreen: double;
begin
  ConvertTo(csRGB);
  GetGreen := self.ColorChannels.ccGreen;
end;

procedure TColorPixel.SetBlue(blue: double);
begin
  ConvertTo(csRGB);
  self.ColorChannels.ccBlue := self.NormalizeValue(blue);
end;

function TColorPixel.GetBlue: double;
begin
  ConvertTo(csRGB);
  GetBlue := self.ColorChannels.ccBlue;
end;

procedure TColorPixel.SetRGB(R, G, B: double);
begin
  self.SetRed(R);
  self.SetGreen(G);
  self.SetBlue(B);
end;

procedure TColorPixel.SetCyan(cyan: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccCyan := self.NormalizeValue(cyan);
end;

function TColorPixel.GetCyan: double;
begin
  ConvertTo(csCMYK);
  GetCyan := self.ColorChannels.ccCyan;
end;

procedure TColorPixel.SetMagenta(magenta: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccMagenta := self.NormalizeValue(magenta);
end;

function TColorPixel.GetMagenta: double;
begin
  ConvertTo(csCMYK);
  GetMagenta := self.ColorChannels.ccMagenta;
end;

procedure TColorPixel.SetYellow(yellow: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccYellow := self.NormalizeValue(yellow);
end;

function TColorPixel.GetYellow: double;
begin
  ConvertTo(csCMYK);
  GetYellow := self.ColorChannels.ccYellow;
end;

procedure TColorPixel.SetKeyColor(keyColor: double);
begin
  ConvertTo(csCMYK);
  self.ColorChannels.ccKeyColor := self.NormalizeValue(keyColor);
end;

function TColorPixel.GetKeyColor: double;
begin
  ConvertTo(csCMYK);
  GetKeyColor := self.ColorChannels.ccKeyColor;
end;

procedure TColorPixel.SetCMYK(C, M, Y, K: double);
begin
  self.SetCyan(C);
  self.SetMagenta(M);
  self.SetYellow(Y);
  self.SetKeyColor(K);
end;

procedure TColorPixel.SetHue(hue: double);
begin
  ConvertTo(csHSI);
  self.ColorChannels.ccHue := self.NormalizeValue(hue);
end;

function TColorPixel.GetHue: double;
begin
  ConvertTo(csHSI);
  GetHue := self.ColorChannels.ccHue;
end;

procedure TColorPixel.SetSaturation(saturation: double);
begin
  ConvertTo(csHSI);
  self.ColorChannels.ccSaturation := self.NormalizeValue(saturation);
end;

function TColorPixel.GetSaturation: double;
begin
  ConvertTo(csHSI);
  GetSaturation := self.ColorChannels.ccSaturation;
end;

procedure TColorPixel.SetIntensity(intensity: double);
begin
  ConvertTo(csHSI);
  self.ColorChannels.ccIntensity := self.NormalizeValue(intensity);
end;

function TColorPixel.GetIntensity: double;
begin
  ConvertTo(csHSI);
  GetIntensity := self.ColorChannels.ccIntensity;
end;

procedure TColorPixel.SetHSI(H, S, I: double);
begin
  self.SetHue(H);
  self.SetSaturation(S);
  self.SetIntensity(I);
end;

procedure TColorPixel.SetY(Y: double);
begin
  ConvertTo(csYIQ);
  self.ColorChannels.ccY := self.NormalizeValue(Y);
end;

function TColorPixel.GetY: double;
begin
  ConvertTo(csYIQ);
  GetY := self.ColorChannels.ccY;
end;

procedure TColorPixel.SetI(I: double);
begin
  ConvertTo(csYIQ);
  self.ColorChannels.ccI := self.NormalizeValue(I);
end;

function TColorPixel.GetI: double;
begin
  ConvertTo(csYIQ);
  GetI := self.ColorChannels.ccI;
end;

procedure TColorPixel.SetQ(Q: double);
begin
  ConvertTo(csYIQ);
  self.ColorChannels.ccQ := self.NormalizeValue(Q);
end;

function TColorPixel.GetQ: double;
begin
  ConvertTo(csYIQ);
  GetQ := self.ColorChannels.ccQ;
end;

procedure TColorPixel.SetYIQ(Y, I, Q: double);
begin
  self.SetY(Y);
  self.SetI(I);
  self.SetQ(Q);
end;

procedure TColorPixel.SetColorChannel(Channel: TEColorChannel; value: double);
begin
  case Channel of
    ccRed:
      self.SetRed(value);
    ccGreen:
      self.SetGreen(value);
    ccBlue:
      self.SetBlue(value);
    ccCyan:
      self.SetCyan(value);
    ccMagenta:
      self.SetMagenta(value);
    ccYellow:
      self.SetYellow(value);
    ccKeyColor:
      self.SetKeyColor(value);
    ccHue:
      self.SetHue(value);
    ccSaturation:
      self.SetSaturation(value);
    ccIntensity:
      self.SetIntensity(value);
    ccY:
      self.SetY(value);
    ccI:
      self.SetI(value);
    ccQ:
      self.SetQ(value);
  end;
end;

function TColorPixel.GetColorChannel(Channel: TEColorChannel): double;
var
  R: double;
begin
  R := 0;
  case Channel of
    ccRed:
      R := self.GetRed;
    ccGreen:
      R := self.GetGreen;
    ccBlue:
      R := self.GetBlue;
    ccCyan:
      R := self.GetCyan;
    ccMagenta:
      R := self.GetMagenta;
    ccYellow:
      R := self.GetYellow;
    ccKeyColor:
      R := self.GetKeyColor;
    ccHue:
      R := self.GetHue;
    ccSaturation:
      R := self.GetSaturation;
    ccIntensity:
      R := self.GetIntensity;
    ccY:
      R := self.GetY;
    ccI:
      R := self.GetI;
    ccQ:
      R := self.GetQ;
  end;
  GetColorChannel := R;
end;

end.
