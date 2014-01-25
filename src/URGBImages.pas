unit URGBImages;

interface

uses
  VCL.Graphics, UGrayscaleImages;

type
  TRGBImage = record
    R, G, B: TGreyscaleImage;
  end;

procedure InitRGBI(var RGBI: TRGBImage; newN, newM: word);
function LoadRGBIFromBitMap(BM: TBitMap): TRGBImage;
function SaveRGBImgToBitMap(RGBI: TRGBImage): TBitMap;
function ConvertRGBIToGSI(const RGBI: TRGBImage): TGreyscaleImage;

implementation

uses
  UPixelConvert;

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
