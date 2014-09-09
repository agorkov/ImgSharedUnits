unit UColorImages;

interface

uses
  VCL.Graphics, UPixelConvert, UGrayscaleImages;

type
  TCColorImage = class
  private
    Height, Width: word;

    procedure FreePixels;
    procedure InitPixels;
  public
    Pixels: array of array of TColorPixel;
    constructor Create;
    procedure SetHeight(newHeight: word);
    function GetHeight: word;
    procedure SetWidth(newWidth: word);
    function GetWidth: word;

    function GetChanel(Channel: TEColorChannel): TCGrayscaleImage;
    procedure SetChannel(Channel: TEColorChannel; GS: TCGrayscaleImage);

    procedure AVGFilter(Channel: TEColorChannel; h, w: word);
    procedure WeightedAVGFilter(Channel: TEColorChannel; h, w: word);
    procedure GeometricMeanFilter(Channel: TEColorChannel; h, w: word);
    procedure MedianFilter(Channel: TEColorChannel; h, w: word);
    procedure MaxFilter(Channel: TEColorChannel; h, w: word);
    procedure MinFilter(Channel: TEColorChannel; h, w: word);
    procedure MiddlePointFilter(Channel: TEColorChannel; h, w: word);
    procedure TruncatedAVGFilter(Channel: TEColorChannel; h, w, d: word);
    procedure PrevittFilter(Channel: TEColorChannel; AddToOriginal: boolean);
    procedure SobelFilter(Channel: TEColorChannel; AddToOriginal: boolean);
    procedure SharrFilter(Channel: TEColorChannel; AddToOriginal: boolean);
    procedure LaplaceFilter(Channel: TEColorChannel; AddToOriginal: boolean);
    procedure HistogramEqualization(Channel: TEColorChannel);
    function Histogram(Channel: TEColorChannel): TBitMap;

    procedure LinearTransform(Channel: TEColorChannel; k, b: double);
    procedure LogTransform(Channel: TEColorChannel; c: double);
    procedure GammaTransform(Channel: TEColorChannel; c, gamma: double);

    procedure LoadFromBitMap(BM: TBitMap);
    function SaveToBitMap: TBitMap;
  end;

implementation

constructor TCColorImage.Create;
begin
  inherited;
  self.Height := 0;
  self.Width := 0;
end;

procedure TCColorImage.FreePixels;
var
  i: word;
begin
  if (self.Height > 0) and (self.Width > 0) then
  begin
    for i := 0 to self.Height - 1 do
      self.Pixels[i] := nil;
    self.Pixels := nil;
  end;
end;

procedure TCColorImage.InitPixels;
var
  i, j: word;
begin
  if (self.Height > 0) and (self.Width > 0) then
  begin
    SetLength(self.Pixels, self.Height);
    for i := 0 to self.Height - 1 do
    begin
      SetLength(self.Pixels[i], self.Width);
      for j := 0 to self.Width - 1 do
      begin
        self.Pixels[i, j] := TColorPixel.Create;
        self.Pixels[i, j].SetFullColor(0);
      end;
    end;
  end;
end;

procedure TCColorImage.SetHeight(newHeight: word);
begin
  FreePixels;
  self.Height := newHeight;
  self.InitPixels;
end;

function TCColorImage.GetHeight: word;
begin
  GetHeight := self.Height;
end;

procedure TCColorImage.SetWidth(newWidth: word);
begin
  FreePixels;
  self.Width := newWidth;
  self.InitPixels;
end;

function TCColorImage.GetWidth: word;
begin
  GetWidth := self.Width;
end;

function TCColorImage.GetChanel(Channel: TEColorChannel): TCGrayscaleImage;
var
  i, j: word;
  GS: TCGrayscaleImage;
begin
  GS := TCGrayscaleImage.Create;
  GS.SetHeight(self.Height);
  GS.SetWidth(self.Width);
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      GS.Pixels[i, j] := self.Pixels[i, j].GetColorChannel(Channel);
  GetChanel := GS;
end;

procedure TCColorImage.SetChannel(Channel: TEColorChannel; GS: TCGrayscaleImage);
var
  i, j: word;
begin
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      self.Pixels[i, j].SetColorChannel(Channel, GS.Pixels[i, j]);
end;

procedure TCColorImage.AVGFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.AVGFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.WeightedAVGFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.WeightedAVGFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.GeometricMeanFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.GeometricMeanFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.MedianFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MedianFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.MaxFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MaxFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.MinFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MinFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.MiddlePointFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MiddlePointFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.TruncatedAVGFilter(Channel: TEColorChannel; h, w, d: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.TruncatedAVGFilter(h, w, d);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.PrevittFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.PrevittFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.SobelFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.SobelFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.SharrFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.SharrFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.LaplaceFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.LaplaceFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.HistogramEqualization(Channel: TEColorChannel);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.HistogramEqualization;
  self.SetChannel(Channel, GS);
  GS.Free;
end;

function TCColorImage.Histogram(Channel: TEColorChannel): TBitMap;
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  Histogram := GS.Histogram;
  GS.Free;
end;

/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////
/// /////////////////////////////////////////////////////////////////////////////

procedure TCColorImage.LinearTransform(Channel: TEColorChannel; k, b: double);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.LinearTransform(k, b);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.LogTransform(Channel: TEColorChannel; c: double);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.LogTransform(c);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.GammaTransform(Channel: TEColorChannel; c, gamma: double);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.GammaTransform(c, gamma);
  self.SetChannel(Channel, GS);
  GS.Free;
end;

procedure TCColorImage.LoadFromBitMap(BM: TBitMap);
var
  i, j: word;
begin
  self.Height := BM.Height;
  self.Width := BM.Width;
  self.InitPixels;
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      self.Pixels[i, j].SetFullColor(BM.Canvas.Pixels[j, i]);
    end;
end;

function TCColorImage.SaveToBitMap: TBitMap;
var
  i, j: word;
  BM: TBitMap;
begin
  BM := TBitMap.Create;
  BM.Height := self.Height;
  BM.Width := self.Width;
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      BM.Canvas.Pixels[j, i] := self.Pixels[i, j].GetFullColor;
  SaveToBitMap := BM;
end;

end.
