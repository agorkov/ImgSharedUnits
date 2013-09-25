unit UBinarization;

interface

uses
  VCL.Graphics, UImages;

function ThresoldBinarization(GSI: TGreyscaleImage; Thresold: byte): TBinaryImage;
function BernsenBinarization(GSI: TGreyscaleImage; r,ContrastThresold: byte): TBinaryImage;

implementation

function ThresoldBinarization(GSI: TGreyscaleImage; Thresold: byte): TBinaryImage;
var
BI: TBinaryImage;
i,j: word;
begin
  InitBinaryImg(BI,GSI.N,GSI.M);
  for i:=1 to GSI.N do
    for j:=1 to GSI.M do
      BI.I[i,j]:=GSI.I[i,j]<Thresold;
  ThresoldBinarization:=BI;
end;

function BernsenBinarization(GSI: TGreyscaleImage; r,ContrastThresold: byte): TBinaryImage;
var
BI: TBinaryImage;
i,j,internali,internalj: word;
Imin,Imax,IThresold: byte;
begin
  InitBinaryImg(BI,GSI.N,GSI.M);
  for i:=r+1 to GSI.N-r do
    for j:=r+1 to GSI.M-r do
    begin
      Imin:=255; Imax:=0;
      for internali:=i-r to i+r do
        for internalj:=j-r to j+r do
        begin
          if GSI.I[internali,internalj]>Imax then
            Imax:=GSI.I[internali,internalj];
          if GSI.I[internali,internalj]<Imin then
            Imin:=GSI.I[internali,internalj];
        end;
      IThresold:=round((Imax-Imin)/2);
      if Imax-Imin>ContrastThresold then
        BI.I[i,j]:=true
      else
        BI.I[i,j]:=GSI.I[i,j]<IThresold;
    end;
  BernsenBinarization:=BI;
end;

end.
