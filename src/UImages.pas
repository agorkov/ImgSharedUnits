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

procedure InitBinaryImg(var BI: TBinaryImage; newN, newM: word);
procedure InitGSImg(var GSI: TGreyscaleImage; newN, newM: word);
procedure LoadGSIFromBitMap(var GSI: TGreyscaleImage; BM: TBitMap);
function SaveBinaryImgToBitMap(BI: TBinaryImage): TBitMap;
function ImgAND(BI1, BI2: TBinaryImage): TBinaryImage;
function ImgOR(BI1, BI2: TBinaryImage): TBinaryImage;
function ImgNOT(BI: TBinaryImage): TBinaryImage;
function ImgXOR(BI1, BI2: TBinaryImage): TBinaryImage;
function ImgEquals(Img1, Img2: TBinaryImage): boolean;

implementation

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

procedure LoadGSIFromBitMap(var GSI: TGreyscaleImage; BM: TBitMap);
var
  I, j: word;
begin
  InitGSImg(GSI, BM.Height, BM.Width);
  for I := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.I[I, j] := BM.Canvas.Pixels[j, I];
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

end.
