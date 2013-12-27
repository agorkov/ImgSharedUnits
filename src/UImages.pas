unit UImages;

interface

uses
  VCL.Graphics;

type
  TBinaryImage = record
    I: array of array of boolean;
    N, M: word;
  end;

  TGreyscaleImage = record
    I: array of array of byte;
    N, M: word;
  end;

  TRGBImage = record
    R, G, B: TGreyscaleImage;
  end;

  ///
  /// ¡»Õ¿–Õ€≈ »«Œ¡–¿∆≈Õ»ﬂ
  ///
procedure InitBinaryImg(var BI: TBinaryImage; newN, newM: word);
function SaveBinaryImgToBitMap(BI: TBinaryImage): TBitMap;
function ImgAND(BI1, BI2: TBinaryImage): TBinaryImage;
function ImgOR(BI1, BI2: TBinaryImage): TBinaryImage;
function ImgNOT(BI: TBinaryImage): TBinaryImage;
function ImgXOR(BI1, BI2: TBinaryImage): TBinaryImage;
function ImgEquals(Img1, Img2: TBinaryImage): boolean;
///
/// œŒÀ”“ŒÕŒ¬€≈ »«Œ¡–¿∆≈Õ»ﬂ
///
procedure InitGSImg(var GSI: TGreyscaleImage; newN, newM: word);
function SaveGreyscaleImgToBitMap(GSI: TGreyscaleImage): TBitMap;

// procedure LoadChannelFromBitMap(var GSI: TGreyscaleImage; BM: TBitMap; channel: byte);

procedure LoadRGBIFromBitMap(var RGBI: TRGBImage; BM: TBitMap);
function SaveRGBImgToBitMap(RGBI: TRGBImage): TBitMap;
function ConvertRGBIToGSI(const RGBI: TRGBImage): TGreyscaleImage;

implementation

uses
  UPixelConvert;

///
/// ¡»Õ¿–Õ€≈ »«Œ¡–¿∆≈Õ»ﬂ
///

procedure InitBinaryImg(var BI: TBinaryImage; newN, newM: word);
var
  I, j: word;
begin
  BI.N := newN;
  BI.M := newM;
  SetLength(BI.I, BI.N + 1);
  for I := 1 to BI.N do
    SetLength(BI.I[I], BI.M + 1);
  for I := 1 to BI.N do
    for j := 1 to BI.M do
      BI.I[I, j] := false;
end;

function SaveBinaryImgToBitMap(BI: TBinaryImage): TBitMap;
var
  I, j: word;
  BM: TBitMap;
begin
  BM := TBitMap.Create;
  BM.Height := BI.N - 1;
  BM.Width := BI.M - 1;
  for I := 1 to BI.N do
    for j := 1 to BI.M do
      if BI.I[I, j] then
        BM.Canvas.Pixels[j - 1, I - 1] := clBlack
      else
        BM.Canvas.Pixels[j - 1, I - 1] := clWhite;
  SaveBinaryImgToBitMap := BM;
end;

function ImgAND(BI1, BI2: TBinaryImage): TBinaryImage;
var
  BIR: TBinaryImage;
  I, j: word;
begin
  InitBinaryImg(BIR, BI1.N, BI1.M);
  for I := 1 to BI1.N do
    for j := 1 to BI1.M do
      BIR.I[I, j] := BI1.I[I, j] and BI2.I[I, j];
  ImgAND := BIR;
end;

function ImgOR(BI1, BI2: TBinaryImage): TBinaryImage;
var
  BIR: TBinaryImage;
  I, j: word;
begin
  InitBinaryImg(BIR, BI1.N, BI1.M);
  for I := 1 to BI1.N do
    for j := 1 to BI1.M do
      BIR.I[I, j] := BI1.I[I, j] or BI2.I[I, j];
  ImgOR := BIR;
end;

function ImgNOT(BI: TBinaryImage): TBinaryImage;
var
  BIR: TBinaryImage;
  I, j: word;
begin
  InitBinaryImg(BIR, BI.N, BI.M);
  for I := 1 to BI.N do
    for j := 1 to BI.M do
      BIR.I[I, j] := not BI.I[I, j];
  ImgNOT := BIR;
end;

function ImgXOR(BI1, BI2: TBinaryImage): TBinaryImage;
var
  BIR: TBinaryImage;
  I, j: word;
begin
  InitBinaryImg(BIR, BI1.N, BI1.M);
  for I := 1 to BI1.N do
    for j := 1 to BI1.M do
      BIR.I[I, j] := BI1.I[I, j] xor BI2.I[I, j];
  ImgXOR := BIR;
end;

function ImgEquals(Img1, Img2: TBinaryImage): boolean;
var
  fl: boolean;
  I, j: word;
begin
  fl := (Img1.N = Img2.N) and (Img1.M = Img2.M);
  if fl then
    for I := 1 to Img1.N do
      for j := 1 to Img1.M do
        fl := fl and (Img1.I[I, j] = Img2.I[I, j]);
  ImgEquals := fl;
end;

///
/// œŒÀ”“ŒÕŒ¬€≈ »«Œ¡–¿∆≈Õ»ﬂ
///

procedure InitGSImg(var GSI: TGreyscaleImage; newN, newM: word);
var
  I, j: word;
begin
  GSI.N := newN;
  GSI.M := newM;
  SetLength(GSI.I, GSI.N + 1);
  for I := 1 to GSI.N do
    SetLength(GSI.I[I], GSI.M + 1);
  for I := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.I[I, j] := 0;
end;

function SaveGreyscaleImgToBitMap(GSI: TGreyscaleImage): TBitMap;
var
  I, j: word;
  BM: TBitMap;
begin
  BM := TBitMap.Create;
  BM.Height := GSI.N;
  BM.Width := GSI.M;
  for I := 1 to GSI.N do
    for j := 1 to GSI.M do
      BM.Canvas.Pixels[j - 1, I - 1] := UPixelConvert.RGBToColor(GSI.I[I, j] / 255, GSI.I[I, j] / 255, GSI.I[I, j] / 255);
  SaveGreyscaleImgToBitMap := BM;
end;

///
/// ÷¬≈“Õ€≈ »«Œ¡–¿∆≈Õ»ﬂ
///

procedure InitRGBI(var RGBI: TRGBImage; newN, newM: word);
begin
  InitGSImg(RGBI.R, newN, newM);
  InitGSImg(RGBI.G, newN, newM);
  InitGSImg(RGBI.B, newN, newM);
end;

procedure LoadRGBIFromBitMap(var RGBI: TRGBImage; BM: TBitMap);
  procedure TColorToRGB(Color: TColor; var R, G, B: byte);
  begin
    R := Color;
    G := Color shr 8;
    B := Color shr 16;
  end;

var
  I, j: word;
  R, G, B: byte;
begin
  InitRGBI(RGBI, BM.Height, BM.Width);
  for I := 1 to RGBI.R.N do
    for j := 1 to RGBI.R.M do
    begin
      TColorToRGB(BM.Canvas.Pixels[j - 1, I - 1], R, G, B);
      RGBI.R.I[I, j] := R;
      RGBI.G.I[I, j] := G;
      RGBI.B.I[I, j] := B;
    end;
end;

function ConvertRGBIToGSI(const RGBI: TRGBImage): TGreyscaleImage;
var
  GSI: TGreyscaleImage;
  I, j: word;
begin
  InitGSImg(GSI, RGBI.R.N, RGBI.R.M);
  for I := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.I[I, j] := round(255 * UPixelConvert.RGBToGS(RGBI.R.I[I, j] / 255, RGBI.G.I[I, j] / 255, RGBI.B.I[I, j] / 255));
  ConvertRGBIToGSI := GSI;
end;

function SaveRGBImgToBitMap(RGBI: TRGBImage): TBitMap;
var
  I, j: word;
  BM: TBitMap;
begin
  BM := TBitMap.Create;
  BM.Height := RGBI.R.N;
  BM.Width := RGBI.R.M;
  for I := 1 to RGBI.R.N do
    for j := 1 to RGBI.R.M do
      BM.Canvas.Pixels[j - 1, I - 1] := UPixelConvert.RGBToColor(RGBI.R.I[I, j] / 255, RGBI.G.I[I, j] / 255, RGBI.B.I[I, j] / 255);
  SaveRGBImgToBitMap := BM;
end;

end.
