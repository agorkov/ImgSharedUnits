unit UFileConvert;

interface

uses
  SysUtils, VCL.Graphics;

function LoadFile(const FileName: TFileName): TBitmap;
procedure JPEGtoBMP(const FileName: TFileName);

implementation

uses
  JPEG;

procedure JPEGtoBMP(const FileName: TFileName);
var
  JPEG: TJPEGImage;
  bmp: TBitmap;
begin
  JPEG := TJPEGImage.Create;
  try
    JPEG.CompressionQuality := 100;
    JPEG.LoadFromFile(FileName);
    bmp := TBitmap.Create;
    try
      bmp.Assign(JPEG);
      bmp.SaveToFile(ChangeFileExt(FileName, '.bmp'));
    finally
      bmp.Free
    end;
  finally
    JPEG.Free
  end;
end;

function LoadFile(const FileName: TFileName): TBitmap;
var
  str: string;
  fl: boolean;
  BM: TBitmap;
begin
  BM := TBitmap.Create;
  fl := false;
  str := ANSIUpperCase(FileName);
  if (ExtractFileExt(str) = '.JPG') or (ExtractFileExt(str) = '.JPEG') then
  begin
    JPEGtoBMP(str);
    str := ChangeFileExt(str, '.bmp');
    fl := true;
  end;
  BM.LoadFromFile(str);
  if fl then
    DeleteFile(str);
  LoadFile := BM;
end;

end.
