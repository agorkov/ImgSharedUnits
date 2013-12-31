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

  TCenter = record
    cx, cy: word;
  end;

  TACenters = array of TCenter;

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
function MarkBinaryImage(BI: TBinaryImage): TGreyscaleImage;
function SaveMarkedImgToBitMap(GSI: TGreyscaleImage): TBitMap;
function FindCenters(MI: TGreyscaleImage): TACenters;
///
/// ÷¬≈“Õ€≈ »«Œ¡–¿∆≈Õ»ﬂ
///
function LoadRGBIFromBitMap(BM: TBitMap): TRGBImage;
function SaveRGBImgToBitMap(RGBI: TRGBImage): TBitMap;
function ConvertRGBIToGSI(const RGBI: TRGBImage): TGreyscaleImage;

implementation

uses
  UPixelConvert, UMorphology;

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

function MarkBinaryImage(BI: TBinaryImage): TGreyscaleImage;
  procedure RecursiveMark(var GSI: TGreyscaleImage; row, col: word; mark: word);
  begin
    GSI.I[row, col] := mark;
    if (row - 1 > 0) and (GSI.I[row - 1, col] = 1) then
      RecursiveMark(GSI, row - 1, col, mark);
    if (row + 1 <= GSI.N) and (GSI.I[row + 1, col] = 1) then
      RecursiveMark(GSI, row + 1, col, mark);
    if (col - 1 > 0) and (GSI.I[row, col - 1] = 1) then
      RecursiveMark(GSI, row, col - 1, mark);
    if (col + 1 <= GSI.M) and (GSI.I[row, col + 1] = 1) then
      RecursiveMark(GSI, row, col + 1, mark);
  end;

  const
  size=6;
var
  GSI: TGreyscaleImage;
  row, col: word;
  mark: word;
  MASK: UMorphology.TBinaryStructElem;
begin
   InitBinaryImg(MASK.MASK, size, size);
    for row := 1 to size do
    for col := 1 to size do
    MASK.MASK.I[row, col] := true;
    MASK.cx := (size div 2)+1;
    MASK.cy := (size div 2)+1;
    BI := UMorphology.opening(BI, MASK);

  InitGSImg(GSI, BI.N, BI.M);
  for row := 1 to BI.N do
    for col := 1 to BI.M do
      if BI.I[row, col] = true then
        GSI.I[row, col] := 1
      else
        GSI.I[row, col] := 0;

  mark := 2;
  for row := 1 to GSI.N do
    for col := 1 to GSI.M do
      if GSI.I[row, col] = 1 then
      begin
        RecursiveMark(GSI, row, col, mark);
        mark := mark + 1;
      end;

  for row := 1 to GSI.N do
    for col := 1 to GSI.M do
      if GSI.I[row, col] > 1 then
        GSI.I[row, col] := GSI.I[row, col] - 1;
  MarkBinaryImage := GSI;
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

function SaveMarkedImgToBitMap(GSI: TGreyscaleImage): TBitMap;
var
  I, j: word;
  BM: TBitMap;
begin
  BM := TBitMap.Create;
  BM.Height := GSI.N;
  BM.Width := GSI.M;
  for I := 1 to GSI.N do
    for j := 1 to GSI.M do
      if GSI.I[I, j] = 0 then
        BM.Canvas.Pixels[j - 1, I - 1] := clWhite
      else
        case GSI.I[I, j] mod 14 of
        0: BM.Canvas.Pixels[j - 1, I - 1] := clMaroon;
        1: BM.Canvas.Pixels[j - 1, I - 1] := clGreen;
        2: BM.Canvas.Pixels[j - 1, I - 1] := clOlive;
        3: BM.Canvas.Pixels[j - 1, I - 1] := clNavy;
        4: BM.Canvas.Pixels[j - 1, I - 1] := clPurple;
        5: BM.Canvas.Pixels[j - 1, I - 1] := clTeal;
        6: BM.Canvas.Pixels[j - 1, I - 1] := clGray;
        7: BM.Canvas.Pixels[j - 1, I - 1] := clSilver;
        8: BM.Canvas.Pixels[j - 1, I - 1] := clRed;
        9: BM.Canvas.Pixels[j - 1, I - 1] := clLime;
        10: BM.Canvas.Pixels[j - 1, I - 1] := clBlue;
        11: BM.Canvas.Pixels[j - 1, I - 1] := clFuchsia;
        12: BM.Canvas.Pixels[j - 1, I - 1] := clAqua;
        13: BM.Canvas.Pixels[j - 1, I - 1] := clYellow;
        end;
  SaveMarkedImgToBitMap := BM;
end;

procedure FindCenter(MI: TGreyscaleImage; var C: TCenter; mark: word);
var
  row, col: word;
  x, y, s: longword;
begin
  x := 0;
  y := 0;
  s := 0;
  for row := 1 to MI.N do
    for col := 1 to MI.M do
      if MI.I[row, col] = mark then
      begin
        s := s + 1;
        x := x + col;
        y := y + row;
      end;
  C.cx := round(x / s);
  C.cy := round(y / s);
end;

function FindCenters(MI: TGreyscaleImage): TACenters;
var
  row, col, I: word;
  maxMark: word;
  Centers: TACenters;
begin
  maxMark := 0;
  for row := 1 to MI.N do
    for col := 1 to MI.M do
      if MI.I[row, col] > maxMark then
        maxMark := MI.I[row, col];
  SetLength(Centers, maxMark + 1);
  Centers[0].cx := maxMark;
  Centers[0].cy := maxMark;
  for I := 1 to maxMark do
    FindCenter(MI, Centers[I], I);
  FindCenters := Centers;
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

function LoadRGBIFromBitMap(BM: TBitMap): TRGBImage;
  procedure TColorToRGB(Color: TColor; var R, G, B: byte);
  begin
    R := Color;
    G := Color shr 8;
    B := Color shr 16;
  end;

var
  RGBI: TRGBImage;
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
  LoadRGBIFromBitMap := RGBI;
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
