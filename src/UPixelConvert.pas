unit UPixelConvert;

interface

uses
  VCL.Graphics;

type
  /// �������������� �������� ������������:
  /// csFullColor - ����������� TColor
  /// csRGB - ���������� �������� ��� RGB
  /// csCMYK - ������������� �������� ������������ (������������� ������ RGB)
  /// csHSI - ������������ ���-������������-�������������
  /// csYIQ - ��������������� ������
  TEColorSpace = (csFullColor, csRGB, csCMYK, csHSI, csYIQ);

  /// ��������� ��� ������� ��������� ������:
  /// ccRed - �������, ccGreen - ������, ccBlue - �����
  /// ccCyan - �������, ccMagenta - ���������, ccYellow - �����, ccKeyColor - �������� ���� (������)
  /// ccHue - ���, ccSaturation - ������������, ccIntensity - �������������
  /// ccY - ���������� �������������, ccI - ��������������� ����������, ccQ - ��������������� ����������
  TEColorChannel = (ccRed, ccGreen, ccBlue, ccCyan, ccMagenta, ccYellow, ccKeyColor, ccHue, ccSaturation, ccIntensity, ccY, ccI, ccQ);

  /// �������� �����. � ����������� �� ��������� ���������� �����, ���� �������������� � ����� �� �������������� �������� �����������
  TRColorChannels = record
    case TEColorSpace of
    csFullColor: // ����������� TColor
        (FullColor: TColor);
    csRGB: // ���������� �������� ��� RGB
        (ccRed, ccGreen, ccBlue: double);
    csCMYK: // ������������� �������� ������������ (������������� ������ RGB)
        (ccCyan, ccMagenta, ccYellow, ccKeyColor: double);
    csHSI: // ������������ ���-������������-�������������
        (ccHue, ccSaturation, ccIntensity: double);
    csYIQ: // ��������������� ������
        (ccY, ccI, ccQ: double);
  end;

  /// ������ �������� �����������
  TColorPixel = class
  private
    ColorSpace: TEColorSpace; // ������������ �������� ������������
    ColorChannels: TRColorChannels; // ����, ���������� �� ������ � ������������ � ��������� �������� �������������

    procedure RGBToFullColor; // �������������� �� ������������ RGB � TColor
    procedure FullColorToRGB; // �������������� �� TColor � �������� ������������ RGB

    procedure RGBToCMYK; // �������������� �� ������������ RGB � ������������ CMYK
    procedure CMYKToRGB; // �������������� �� ������������ CMYK � ������������ RGB

    procedure RGBToHSI; // �������������� �� ������������ RGB � ������������ HSI
    procedure HSIToRGB; // �������������� �� ������������ HSI � ������������ RGB

    procedure RGBToYIQ; // �������������� �� ������������ RGB � ������������ YIQ
    procedure YIQToRGB; // �������������� �� ������������ YIQ � ������������ RGB

    procedure ConvertTo(Target: TEColorSpace); // �������������� � �������� �������� ������������

  public
    procedure SetFullColor(Color: TColor); // ������ TColor
    function GetFullColor: TColor; // ������� TColor

    procedure SetRed(red: double); // ������ ������� ������������
    function GetRed: double; // �������� ������� ������������
    procedure SetGreen(green: double); // ������ ������ ������������
    function GetGreen: double; // �������� ������ ������������
    procedure SetBlue(blue: double); // ������ ����� ������������
    function GetBlue: double; // �������� ����� ������������
    procedure SetRGB(R, G, B: double); // ������ ��� ��������� RGB

    procedure SetCyan(cyan: double); // ������ ������� ������������
    function GetCyan: double; // �������� ������� ������������
    procedure SetMagenta(magenta: double); // ������ ��������� ������������
    function GetMagenta: double; // �������� ��������� ������������
    procedure SetYellow(yellow: double); // ������ ����� ������������
    function GetYellow: double; // �������� ����� ������������
    procedure SetKeyColor(keyColor: double); // ������ �������� (������) ������������
    function GetKeyColor: double; // �������� �������� (������) ������������
    procedure SetCMYK(C, M, Y, K: double); // ������ ��� ��������� CMYK

    procedure SetHue(hue: double); // ������ ������������ ��������� ����
    function GetHue: double; // �������� ������������ ��������� ����
    procedure SetSaturation(saturation: double); // ������ ������������ ������������
    function GetSaturation: double; // �������� ������������ ������������
    procedure SetIntensity(intensity: double); // ������ ������������ �������������
    function GetIntensity: double; // ������ ������������ �������������
    procedure SetHSI(H, S, I: double); // ������ ��� ��������� HSI

    procedure SetY(Y: double); // ������ Y ������������
    function GetY: double; // �������� Y ������������
    procedure SetI(I: double); // ������ I ������������
    function GetI: double; // �������� I ������������
    procedure SetQ(Q: double); // ������ Q ������������
    function GetQ: double; // �������� Q ������������
    procedure SetYIQ(Y, I, Q: double); // ������ ��� ��������� YIQ

    procedure SetColorChannel(Channel: TEColorChannel; value: double); // ������ �������� ���������� ��������� ������
    function GetColorChannel(Channel: TEColorChannel): double; // �������� �������� ���������� ��������� ������
  end;

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
  self.ColorChannels.FullColor := Winapi.Windows.RGB(round(self.ColorChannels.ccRed * 255), round(self.ColorChannels.ccGreen * 255), round(self.ColorChannels.ccBlue * 255));
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
  R, G, B: double;
begin
  self.ColorSpace := csCMYK;
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
  R, G, B, rHue: double;
begin
  self.ColorSpace := csHSI;
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
end;

procedure TColorPixel.HSIToRGB;
var
  H, S, I: double;
begin
  self.ColorSpace := csRGB;
  H := self.ColorChannels.ccHue * 363 - 1;
  S := self.ColorChannels.ccSaturation;
  I := self.ColorChannels.ccIntensity;
  if H = 0 then
  begin
    self.ColorChannels.ccRed := I + 2 * I * S;
    self.ColorChannels.ccGreen := I - I * S;
    self.ColorChannels.ccBlue := I - I * S;
  end
  else
    if (0 < H) and (H < 120) then
    begin
      self.ColorChannels.ccRed := I + I * S * cos(DegToRad(H)) / cos(DegToRad(60 - H));
      self.ColorChannels.ccGreen := I + I * S * (1 - cos(DegToRad(H)) / cos(DegToRad(60 - H)));
      self.ColorChannels.ccBlue := I - I * S;
    end
    else
      if (H = 120) then
      begin
        self.ColorChannels.ccRed := I - I * S;
        self.ColorChannels.ccGreen := I + 2 * I * S;
        self.ColorChannels.ccBlue := I - I * S;
      end
      else
        if (120 < H) and (H < 240) then
        begin
          self.ColorChannels.ccRed := I - I * S;
          self.ColorChannels.ccGreen := I + I * S * cos(DegToRad(H - 120)) / cos(DegToRad(180 - H));
          self.ColorChannels.ccBlue := I + I * S * (1 - cos(DegToRad(H - 120)) / cos(DegToRad(180 - H)));
        end
        else
          if H = 240 then
          begin
            self.ColorChannels.ccRed := I - I * S;
            self.ColorChannels.ccGreen := I - I * S;
            self.ColorChannels.ccBlue := I + 2 * I * S;
          end
          else
            if (240 < H) and (H < 360) then
            begin
              self.ColorChannels.ccRed := I + I * S * (1 - cos(DegToRad(H - 240)) / cos(DegToRad(300 - H)));
              self.ColorChannels.ccGreen := I - I * S;
              self.ColorChannels.ccBlue := I + I * S * cos(DegToRad(H - 240)) / cos(DegToRad(300 - H));
            end
            else
              if H > 360 then
              begin
                self.ColorChannels.ccRed := I;
                self.ColorChannels.ccGreen := I;
                self.ColorChannels.ccBlue := I;
              end;
end;

procedure TColorPixel.RGBToYIQ;
var
  R, G, B: double;
begin
  self.ColorSpace := csYIQ;
  R := self.ColorChannels.ccRed;
  G := self.ColorChannels.ccGreen;
  B := self.ColorChannels.ccBlue;
  self.ColorChannels.ccY := 0.299 * R + 0.587 * G + 0.114 * B;
  self.ColorChannels.ccI := 0.596 * R - 0.274 * G - 0.321 * B;
  self.ColorChannels.ccI := (self.ColorChannels.ccI + 0.595) / 1.191;
  self.ColorChannels.ccQ := 0.211 * R - 0.523 * G + 0.311 * B;
  self.ColorChannels.ccQ := (self.ColorChannels.ccQ + 0.523) / 1.045;
end;

procedure TColorPixel.YIQToRGB;
var
  Y, I, Q: double;
begin
  self.ColorSpace := csRGB;
  Y := self.ColorChannels.ccY;
  I := self.ColorChannels.ccI;
  I := I * 1.191 - 0.595;
  Q := self.ColorChannels.ccQ;
  Q := Q * 1.045 - 0.523;
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
    csFullColor: FullColorToRGB;
    csRGB:;
    csCMYK: CMYKToRGB;
    csHSI: HSIToRGB;
    csYIQ: YIQToRGB;
    end;
    case Target of
    csFullColor: RGBToFullColor;
    csRGB:;
    csCMYK: RGBToCMYK;
    csHSI: RGBToHSI;
    csYIQ: RGBToYIQ;
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

procedure TColorPixel.SetRGB(R, G, B: double);
begin
  self.SetRed(R);
  self.SetGreen(G);
  self.SetBlue(B);
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

procedure TColorPixel.SetHSI(H, S, I: double);
begin
  self.SetHue(H);
  self.SetSaturation(S);
  self.SetIntensity(I);
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

procedure TColorPixel.SetYIQ(Y, I, Q: double);
begin
  self.SetY(Y);
  self.SetI(I);
  self.SetQ(Q);
end;

procedure TColorPixel.SetColorChannel(Channel: TEColorChannel; value: double);
begin
  case Channel of
  ccRed: self.SetRed(value);
  ccGreen: self.SetGreen(value);
  ccBlue: self.SetBlue(value);
  ccCyan: self.SetCyan(value);
  ccMagenta: self.SetMagenta(value);
  ccYellow: self.SetYellow(value);
  ccKeyColor: self.SetKeyColor(value);
  ccHue: self.SetHue(value);
  ccSaturation: self.SetSaturation(value);
  ccIntensity: self.SetIntensity(value);
  ccY: self.SetY(value);
  ccI: self.SetI(value);
  ccQ: self.SetQ(value);
  end;
end;

function TColorPixel.GetColorChannel(Channel: TEColorChannel): double;
var
  R: double;
begin
  R := 0;
  case Channel of
  ccRed: R := self.GetRed;
  ccGreen: R := self.GetGreen;
  ccBlue: R := self.GetBlue;
  ccCyan: R := self.GetCyan;
  ccMagenta: R := self.GetMagenta;
  ccYellow: R := self.GetYellow;
  ccKeyColor: R := self.GetKeyColor;
  ccHue: R := self.GetHue;
  ccSaturation: R := self.GetSaturation;
  ccIntensity: R := self.GetIntensity;
  ccY: R := self.GetY;
  ccI: R := self.GetI;
  ccQ: R := self.GetQ;
  end;
  GetColorChannel := R;
end;

end.
