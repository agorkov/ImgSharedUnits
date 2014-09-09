unit UGrayscaleImages;

interface

uses
  VCL.Graphics, UBinaryImages;

type
  TGreyscaleImage = record
    I: array of array of byte;
    N, M: word;
  end;

  TCenter = record
    cx, cy: word;
  end;

  TACenters = array of TCenter;

procedure InitGSImg(var GSI: TGreyscaleImage; newN, newM: word);
function SaveGreyscaleImgToBitMap(GSI: TGreyscaleImage): TBitMap;
function MarkBinaryImage(BI: TBinaryImage): TGreyscaleImage;
function SaveMarkedImgToBitMap(GSI: TGreyscaleImage): TBitMap;
procedure FindCenter(MI: TGreyscaleImage; var C: TCenter; mark: word);
function FindCenters(MI: TGreyscaleImage): TACenters;

implementation

uses
  UPixelConvert, UMorphology;

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
  p: TColorPixel;
begin
  BM := TBitMap.Create;
  BM.Height := GSI.N;
  BM.Width := GSI.M;
  p := TColorPixel.Create;
  for I := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      p.SetRGB(GSI.I[I, j] / 255, GSI.I[I, j] / 255, GSI.I[I, j] / 255);
      BM.Canvas.Pixels[j - 1, I - 1] := p.GetFullColor;
    end;
  SaveGreyscaleImgToBitMap := BM;
  p.Free;
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
  size = 6;
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
  MASK.cx := (size div 2) + 1;
  MASK.cy := (size div 2) + 1;
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
          0:
            BM.Canvas.Pixels[j - 1, I - 1] := clMaroon;
          1:
            BM.Canvas.Pixels[j - 1, I - 1] := clGreen;
          2:
            BM.Canvas.Pixels[j - 1, I - 1] := clOlive;
          3:
            BM.Canvas.Pixels[j - 1, I - 1] := clNavy;
          4:
            BM.Canvas.Pixels[j - 1, I - 1] := clPurple;
          5:
            BM.Canvas.Pixels[j - 1, I - 1] := clTeal;
          6:
            BM.Canvas.Pixels[j - 1, I - 1] := clGray;
          7:
            BM.Canvas.Pixels[j - 1, I - 1] := clSilver;
          8:
            BM.Canvas.Pixels[j - 1, I - 1] := clRed;
          9:
            BM.Canvas.Pixels[j - 1, I - 1] := clLime;
          10:
            BM.Canvas.Pixels[j - 1, I - 1] := clBlue;
          11:
            BM.Canvas.Pixels[j - 1, I - 1] := clFuchsia;
          12:
            BM.Canvas.Pixels[j - 1, I - 1] := clAqua;
          13:
            BM.Canvas.Pixels[j - 1, I - 1] := clYellow;
        end;
  SaveMarkedImgToBitMap := BM;
end;

procedure FindCenter(MI: TGreyscaleImage; var C: TCenter; mark: word);
var
  row, col: word;
  x, y, S: longword;
begin
  x := 0;
  y := 0;
  S := 0;
  for row := 1 to MI.N do
    for col := 1 to MI.M do
      if MI.I[row, col] = mark then
      begin
        S := S + 1;
        x := x + col;
        y := y + row;
      end;
  C.cx := round(x / S);
  C.cy := round(y / S);
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

end.
