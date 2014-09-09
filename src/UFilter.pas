unit UFilter;

interface

uses
  VCL.Graphics, UGrayscaleImages, URGBImages;
procedure LaplaceFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure SobelFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure PrevittFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure SharrFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure HistogramEqualization(var GSI: TGreyscaleImage);
function Histogram(var RGBI: TRGBImage; Channel: byte): TBitMap;

implementation

uses
  Math;

const
  LaplaceMask: array [1 .. 3, 1 .. 3] of shortint = ((1, 1, 1), (1, -8, 1),
    (1, 1, 1));

  SobelMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-1, 0, 1), (-2, 0, 2),
    (-1, 0, 1));
  SobelMaskY: array [1 .. 3, 1 .. 3] of shortint = ((1, 2, 1), (0, 0, 0),
    (-1, -2, -1));

  PrevittMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-1, 0, 1), (-1, 0, 1),
    (-1, 0, 1));
  PrevittMaskY: array [1 .. 3, 1 .. 3] of shortint = ((1, 1, 1), (0, 0, 0),
    (-1, -1, -1));

  SharrMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-3, 0, 3), (-10, 0, 10),
    (-3, 0, 3));
  SharrMaskY: array [1 .. 3, 1 .. 3] of shortint = ((3, 10, 3), (0, 0, 0),
    (-3, -10, -3));

function GetPixelValue(const GSI: TGreyscaleImage; i, j: integer): byte;
begin
  if i < 1 then
    i := 1;
  if i > GSI.N then
    i := GSI.N;
  if j < 1 then
    j := 1;
  if j > GSI.M then
    j := GSI.M;
  GetPixelValue := GSI.i[i, j];
end;



procedure LaplaceFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + LaplaceMask[fi + 1 + 1, fj + 1 + 1] *
            GetPixelValue(GSI, i + fi, j + fj);
      if AddToOriginal then
        response := round(GSI.i[i, j] - response);
      if response > 255 then
        GSIR.i[i, j] := 255;
      if response < 0 then
        GSIR.i[i, j] := 0;
      if response in [0 .. 255] then
        GSIR.i[i, j] := response;
    end;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure SobelFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + SobelMaskX[fi + 1 + 1, fj + 1 + 1] *
            GetPixelValue(GSI, i + fi, j + fj) + SobelMaskY[fi + 1 + 1,
            fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj);
      if AddToOriginal then
        response := GSI.i[i, j] + response;
      if response > 255 then
        GSIR.i[i, j] := 255;
      if response < 0 then
        GSIR.i[i, j] := 0;
      if response in [0 .. 255] then
        GSIR.i[i, j] := response;
    end;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure PrevittFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + PrevittMaskX[fi + 1 + 1, fj + 1 + 1] *
            GetPixelValue(GSI, i + fi, j + fj) + PrevittMaskY
            [fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj);
      if AddToOriginal then
        response := GSI.i[i, j] + response;
      if response > 255 then
        GSIR.i[i, j] := 255;
      if response < 0 then
        GSIR.i[i, j] := 0;
      if response in [0 .. 255] then
        GSIR.i[i, j] := response;
    end;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure SharrFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + SharrMaskX[fi + 1 + 1, fj + 1 + 1] *
            GetPixelValue(GSI, i + fi, j + fj) + SharrMaskY[fi + 1 + 1,
            fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj);
      if AddToOriginal then
        response := GSI.i[i, j] + response;
      if response > 255 then
        GSIR.i[i, j] := 255;
      if response < 0 then
        GSIR.i[i, j] := 0;
      if response in [0 .. 255] then
        GSIR.i[i, j] := response;
    end;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure HistogramEqualization(var GSI: TGreyscaleImage);
var
  h: array [0 .. 255] of double;
  i, j: word;
begin
  for i := 0 to 255 do
    h[i] := 0;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      h[GSI.i[i, j]] := h[GSI.i[i, j]] + 1;
  for i := 0 to 255 do
    h[i] := h[i] / (GSI.N * GSI.M);

  for i := 1 to 255 do
    h[i] := h[i - 1] + h[i];
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := round(255 * h[GSI.i[i, j]]);
end;

function Histogram(var RGBI: TRGBImage; Channel: byte): TBitMap;
var
  BM: TBitMap;
  h: array [0 .. 255] of LongWord;
  Max: LongWord;
  i, j: word;
begin
  Max := 0;
  for i := 0 to 255 do
    h[i] := 0;
  for i := 1 to RGBI.R.N do
    for j := 1 to RGBI.R.M do
      case Channel of
        1:
          h[RGBI.R.i[i, j]] := h[RGBI.R.i[i, j]] + 1;
        2:
          h[RGBI.G.i[i, j]] := h[RGBI.G.i[i, j]] + 1;
        3:
          h[RGBI.b.i[i, j]] := h[RGBI.b.i[i, j]] + 1;
      end;

  for i := 0 to 255 do
    if h[i] > Max then
      Max := h[i];

  BM := TBitMap.Create;
  BM.Height := 100;
  BM.Width := 256;
  case Channel of
    1:
      begin
        BM.Canvas.Pen.Color := clRed;
        BM.Canvas.Brush.Color := clRed;
      end;
    2:
      begin
        BM.Canvas.Pen.Color := clGreen;
        BM.Canvas.Brush.Color := clGreen;
      end;
    3:
      begin
        BM.Canvas.Pen.Color := clBlue;
        BM.Canvas.Brush.Color := clBlue;
      end;
  end;

  BM.Canvas.Brush.Style := bsSolid;
  for i := 0 to 255 do
  begin
    BM.Canvas.MoveTo(i, BM.Height);
    BM.Canvas.LineTo(i, BM.Height - round(h[i] * 100 / Max));
  end;
  Histogram := BM;
end;

end.
