unit UFilter;

interface

uses
  UImages;
procedure AVGFilter(var GSI: TGreyscaleImage; h, w: word);
procedure WeightedAVGFilter(var GSI: TGreyscaleImage; h, w: word);
procedure GeometricMeanFilter(var GSI: TGreyscaleImage; h, w: word);
procedure MedianFilter(var GSI: TGreyscaleImage; h, w: word);
procedure MaxFilter(var GSI: TGreyscaleImage; h, w: word);
procedure MinFilter(var GSI: TGreyscaleImage; h, w: word);
procedure MiddlePointFilter(var GSI: TGreyscaleImage; h, w: word);
procedure TruncatedAVGFilter(var GSI: TGreyscaleImage; h, w, d: word);
procedure LaplaceFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure SobelFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure PrevittFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure SharrFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
procedure LinearTransform(var GSI: TGreyscaleImage; k, b: double);
procedure LogTransform(var GSI: TGreyscaleImage; var c: double);
procedure GammaTransform(var GSI: TGreyscaleImage; var c, gamma: double);
procedure HistogramEqualization(var GSI: TGreyscaleImage);

procedure RGBAVGFilter(var RGBI: TRGBImage; h, w: word);
procedure RGBWeightedAVGFilter(var RGBI: TRGBImage; h, w: word);
procedure RGBGeometricMeanFilter(var RGBI: TRGBImage; h, w: word);
procedure RGBMedianFilter(var RGBI: TRGBImage; h, w: word);
procedure RGBMaxFilter(var RGBI: TRGBImage; h, w: word);
procedure RGBMinFilter(var RGBI: TRGBImage; h, w: word);
procedure RGBMiddlePointFilter(var RGBI: TRGBImage; h, w: word);
procedure RGBTruncatedAVGFilter(var RGBI: TRGBImage; h, w, d: word);
procedure RGBLaplaceFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
procedure RGBSobelFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
procedure RGBPrevittFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
procedure RGBSharrFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
procedure RGBLinearTransform(var RGBI: TRGBImage; k, b: double);
procedure RGBLogTransform(var RGBI: TRGBImage; var c: double);
procedure RGBGammaTransform(var RGBI: TRGBImage; var c, gamma: double);
procedure RGBHistogramEqualization(var RGBI: TRGBImage);

implementation

uses
  Math;

const
  LaplaceMask: array [1 .. 3, 1 .. 3] of shortint = ((1, 1, 1), (1, -8, 1), (1, 1, 1));

  SobelMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1));
  SobelMaskY: array [1 .. 3, 1 .. 3] of shortint = ((1, 2, 1), (0, 0, 0), (-1, -2, -1));

  PrevittMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-1, 0, 1), (-1, 0, 1), (-1, 0, 1));
  PrevittMaskY: array [1 .. 3, 1 .. 3] of shortint = ((1, 1, 1), (0, 0, 0), (-1, -1, -1));

  SharrMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-3, 0, 3), (-10, 0, 10), (-3, 0, 3));
  SharrMaskY: array [1 .. 3, 1 .. 3] of shortint = ((3, 10, 3), (0, 0, 0), (-3, -10, -3));

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

procedure AVGFilter(var GSI: TGreyscaleImage; h, w: word);
var
  i, j: word;
  fi, fj: integer;
  sum: LongWord;
  GSIR: TGreyscaleImage;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      sum := 0;
      for fi := -h to h do
        for fj := -w to w do
          sum := sum + GetPixelValue(GSI, i + fi, j + fj);
      sum := round(sum / ((2 * h + 1) * (2 * w + 1)));
      GSIR.i[i, j] := sum;
    end;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBAVGFilter(var RGBI: TRGBImage; h, w: word);
begin
  AVGFilter(RGBI.R, h, w);
  AVGFilter(RGBI.G, h, w);
  AVGFilter(RGBI.b, h, w);
end;

procedure WeightedAVGFilter(var GSI: TGreyscaleImage; h, w: word);
var
  i, j: integer;
  fi, fj: integer;
  sum: double;
  GSIR: TGreyscaleImage;
  Mask: array of array of double;
  maxDist, maskWeigth: double;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  SetLength(Mask, 2 * h + 2);
  for i := 1 to 2 * h + 2 do
    SetLength(Mask[i], 2 * w + 2);
  for i := -h to h do
    for j := -w to w do
      Mask[i + h + 1, j + w + 1] := sqrt(sqr(i) + sqr(j));
  maxDist := Mask[1, 1];
  maskWeigth := 0;
  for i := 1 to 2 * h + 1 do
    for j := 1 to 2 * w + 1 do
    begin
      Mask[i, j] := (maxDist - Mask[i, j]) / maxDist;
      maskWeigth := maskWeigth + Mask[i, j];
    end;

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      sum := 0;
      for fi := -h to h do
        for fj := -w to w do
          sum := sum + Mask[fi + h + 1, fj + w + 1] * GetPixelValue(GSI, i + fi, j + fj);
      GSIR.i[i, j] := round(sum / maskWeigth);
    end;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBWeightedAVGFilter(var RGBI: TRGBImage; h, w: word);
begin
  WeightedAVGFilter(RGBI.R, h, w);
  WeightedAVGFilter(RGBI.G, h, w);
  WeightedAVGFilter(RGBI.b, h, w);
end;

procedure GeometricMeanFilter(var GSI: TGreyscaleImage; h, w: word);
var
  i, j: word;
  fi, fj: integer;
  p: extended;
  GSIR: TGreyscaleImage;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      p := 1;
      for fi := -h to h do
        for fj := -w to w do
          p := p * GetPixelValue(GSI, i + fi, j + fj);
      p := power(p, 1 / ((2 * h + 1) * (2 * w + 1)));
      GSIR.i[i, j] := round(p);
    end;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBGeometricMeanFilter(var RGBI: TRGBImage; h, w: word);
begin
  GeometricMeanFilter(RGBI.R, h, w);
  GeometricMeanFilter(RGBI.G, h, w);
  GeometricMeanFilter(RGBI.b, h, w);
end;

procedure MedianFilter(var GSI: TGreyscaleImage; h, w: word);
  function FindMedian(N: word; var Arr: array of byte): byte;
  var
    L, R, k, i, j: word;
    w, x: byte;
  begin
    L := 1;
    R := N;
    k := (N div 2) + 1;
    while L < R - 1 do
    begin
      x := Arr[k];
      i := L;
      j := R;
      repeat
        while Arr[i] < x do
          i := i + 1;
        while x < Arr[j] do
          j := j - 1;
        if i <= j then
        begin
          w := Arr[i];
          Arr[i] := Arr[j];
          Arr[j] := w;
          i := i + 1;
          j := j - 1;
        end;
      until i > j;
      if j < k then
        L := i;
      if k < i then
        R := j;
    end;
    FindMedian := Arr[k];
  end;

var
  i, j: word;
  fi, fj: integer;
  GSIR: TGreyscaleImage;
  k: word;
  tmp: array of byte;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  SetLength(tmp, (2 * h + 1) * (2 * w + 1) + 1);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := GetPixelValue(GSI, i + fi, j + fj);
        end;
      GSIR.i[i, j] := FindMedian((2 * h + 1) * (2 * w + 1), tmp);
    end;
  tmp := nil;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBMedianFilter(var RGBI: TRGBImage; h, w: word);
begin
  MedianFilter(RGBI.R, h, w);
  MedianFilter(RGBI.G, h, w);
  MedianFilter(RGBI.b, h, w);
end;

procedure MaxFilter(var GSI: TGreyscaleImage; h, w: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TGreyscaleImage;
  k: word;
  Max: byte;
  tmp: array of byte;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  SetLength(tmp, (2 * h + 1) * (2 * w + 1) + 1);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := GetPixelValue(GSI, i + fi, j + fj);
        end;
      Max := tmp[1];
      for k := 1 to (2 * h + 1) * (2 * w + 1) do
        if tmp[k] > Max then
          Max := tmp[k];
      GSIR.i[i, j] := Max;
    end;
  tmp := nil;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBMaxFilter(var RGBI: TRGBImage; h, w: word);
begin
  MaxFilter(RGBI.R, h, w);
  MaxFilter(RGBI.G, h, w);
  MaxFilter(RGBI.b, h, w);
end;

procedure MinFilter(var GSI: TGreyscaleImage; h, w: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TGreyscaleImage;
  k: word;
  Min: byte;
  tmp: array of byte;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  SetLength(tmp, (2 * h + 1) * (2 * w + 1) + 1);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := GetPixelValue(GSI, i + fi, j + fj);
        end;
      Min := tmp[1];
      for k := 1 to (2 * h + 1) * (2 * w + 1) do
        if tmp[k] < Min then
          Min := tmp[k];
      GSIR.i[i, j] := Min;
    end;
  tmp := nil;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBMinFilter(var RGBI: TRGBImage; h, w: word);
begin
  MinFilter(RGBI.R, h, w);
  MinFilter(RGBI.G, h, w);
  MinFilter(RGBI.b, h, w);
end;

procedure MiddlePointFilter(var GSI: TGreyscaleImage; h, w: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TGreyscaleImage;
  k: word;
  Min, Max: byte;
  tmp: array of byte;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  SetLength(tmp, (2 * h + 1) * (2 * w + 1) + 1);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := GetPixelValue(GSI, i + fi, j + fj);
        end;
      Min := tmp[1];
      Max := tmp[1];
      for k := 1 to (2 * h + 1) * (2 * w + 1) do
      begin
        if tmp[k] < Min then
          Min := tmp[k];
        if tmp[k] > Max then
          Max := tmp[k];
      end;
      GSIR.i[i, j] := round((Max + Min) / 2);
    end;
  tmp := nil;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBMiddlePointFilter(var RGBI: TRGBImage; h, w: word);
begin
  MiddlePointFilter(RGBI.R, h, w);
  MiddlePointFilter(RGBI.G, h, w);
  MiddlePointFilter(RGBI.b, h, w);
end;

procedure TruncatedAVGFilter(var GSI: TGreyscaleImage; h, w, d: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TGreyscaleImage;
  k, L: word;
  val: byte;
  tmp: array of byte;
  sum: word;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  SetLength(tmp, (2 * h + 1) * (2 * w + 1) + 1);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := GetPixelValue(GSI, i + fi, j + fj);
        end;
      for k := 1 to (2 * h + 1) * (2 * w + 1) - 1 do
        for L := k + 1 to (2 * h + 1) * (2 * w + 1) do
          if tmp[k] > tmp[L] then
          begin
            val := tmp[k];
            tmp[k] := tmp[L];
            tmp[L] := val;
          end;
      sum := 0;
      for k := d + 1 to (2 * h + 1) * (2 * w + 1) - d do
        sum := sum + tmp[k];
      GSIR.i[i, j] := round(sum / ((2 * h + 1) * (2 * w + 1) - 2 * d));
    end;
  tmp := nil;
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSI.i[i, j] := GSIR.i[i, j];
end;

procedure RGBTruncatedAVGFilter(var RGBI: TRGBImage; h, w, d: word);
begin
  TruncatedAVGFilter(RGBI.R, h, w, d);
  TruncatedAVGFilter(RGBI.G, h, w, d);
  TruncatedAVGFilter(RGBI.b, h, w, d);
end;

procedure LaplaceFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + LaplaceMask[fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj);
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

procedure RGBLaplaceFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
begin
  LaplaceFilter(RGBI.R, AddToOriginal);
  LaplaceFilter(RGBI.G, AddToOriginal);
  LaplaceFilter(RGBI.b, AddToOriginal);
end;

procedure SobelFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + SobelMaskX[fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj) + SobelMaskY[fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj);
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

procedure RGBSobelFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
begin
  SobelFilter(RGBI.R, AddToOriginal);
  SobelFilter(RGBI.G, AddToOriginal);
  SobelFilter(RGBI.b, AddToOriginal);
end;

procedure PrevittFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + PrevittMaskX[fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj) + PrevittMaskY[fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj);
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

procedure RGBPrevittFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
begin
  PrevittFilter(RGBI.R, AddToOriginal);
  PrevittFilter(RGBI.G, AddToOriginal);
  PrevittFilter(RGBI.b, AddToOriginal);
end;

procedure SharrFilter(var GSI: TGreyscaleImage; AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: integer;
  GSIR: TGreyscaleImage;
begin
  UImages.InitGSImg(GSIR, GSI.N, GSI.M);
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
      GSIR.i[i, j] := GSI.i[i, j];

  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + SharrMaskX[fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj) + SharrMaskY[fi + 1 + 1, fj + 1 + 1] * GetPixelValue(GSI, i + fi, j + fj);
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

procedure RGBSharrFilter(var RGBI: TRGBImage; AddToOriginal: boolean);
begin
  SharrFilter(RGBI.R, AddToOriginal);
  SharrFilter(RGBI.G, AddToOriginal);
  SharrFilter(RGBI.b, AddToOriginal);
end;

procedure LinearTransform(var GSI: TGreyscaleImage; k, b: double);
var
  i, j: word;
  val: double;
begin
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      val := k * GSI.i[i, j] + b;
      if val > 255 then
        val := 255;
      if val < 0 then
        val := 0;
      GSI.i[i, j] := round(val);
    end;
end;

procedure RGBLinearTransform(var RGBI: TRGBImage; k, b: double);
begin
  LinearTransform(RGBI.R, k, b);
  LinearTransform(RGBI.G, k, b);
  LinearTransform(RGBI.b, k, b);
end;

procedure LogTransform(var GSI: TGreyscaleImage; var c: double);
var
  i, j: word;
  val: double;
begin
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      val := c * log2(GSI.i[i, j] + 1);
      if val > 255 then
        val := 255;
      if val < 0 then
        val := 0;
      GSI.i[i, j] := round(val);
    end;
end;

procedure RGBLogTransform(var RGBI: TRGBImage; var c: double);
begin
  LogTransform(RGBI.R, c);
  LogTransform(RGBI.G, c);
  LogTransform(RGBI.b, c);
end;

procedure GammaTransform(var GSI: TGreyscaleImage; var c, gamma: double);
var
  i, j: word;
  val: double;
begin
  for i := 1 to GSI.N do
    for j := 1 to GSI.M do
    begin
      val := c * power(GSI.i[i, j], gamma);
      if val > 255 then
        val := 255;
      if val < 0 then
        val := 0;
      GSI.i[i, j] := round(val);
    end;
end;

procedure RGBGammaTransform(var RGBI: TRGBImage; var c, gamma: double);
begin
  GammaTransform(RGBI.R, c, gamma);
  GammaTransform(RGBI.G, c, gamma);
  GammaTransform(RGBI.b, c, gamma);
end;

procedure HistogramEqualization(var GSI: TGreyscaleImage);
var
  h: array [0 .. 255] of double;
  q, sum: LongWord;
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

procedure RGBHistogramEqualization(var RGBI: TRGBImage);
begin
  HistogramEqualization(RGBI.R);
  HistogramEqualization(RGBI.G);
  HistogramEqualization(RGBI.b);
end;

end.
