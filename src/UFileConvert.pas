unit UFileConvert;

interface

uses
  SysUtils, VCL.Graphics;

const
  SUPPORTED_FORMATS = '*.bmp;*.jpg;*.jpeg;*.png';

function LoadFromFile(const FileName: TFileName): TBitmap;
procedure SaveToFile(
  const BM: TBitmap;
  const FileName: string);

implementation

uses
  JPEG, PNGImage;

function LoadFromFile(const FileName: TFileName): TBitmap;
var
  isConvertedToBitMap: boolean;
  Ext: string;
  BM: TBitmap;
  jpg: TJPEGImage;
  PNG: TPNGImage;
begin
  isConvertedToBitMap := false;
  BM := TBitmap.Create;

  Ext := ExtractFileExt(FileName);
  Ext := UpperCase(Ext);

  if (Ext = '.JPG') or (Ext = '.JPEG') then
    try
      jpg := TJPEGImage.Create();
      jpg.LoadFromFile(FileName);
      BM.Assign(jpg);
      jpg.Free;
      isConvertedToBitMap := true;
    except
      isConvertedToBitMap := false;
    end;

  if (Ext = '.PNG') then
    try
      PNG := TPNGImage.Create();
      PNG.LoadFromFile(FileName);
      BM.Assign(PNG);
      PNG.Free;
      isConvertedToBitMap := true;
    except
      isConvertedToBitMap := false;
    end;

  if Ext = '.BMP' then
    try
      BM.LoadFromFile(FileName);
      isConvertedToBitMap := true;
    except
      isConvertedToBitMap := false;
    end;

  if isConvertedToBitMap then
  begin
    BM.PixelFormat := pf24bit;
    LoadFromFile := BM;
  end
  else
    LoadFromFile := nil;
end;

procedure SaveToFile(
  const BM: TBitmap;
  const FileName: string);
var
  Ext: string;
  jpg: TJPEGImage;
  PNG: TPNGImage;
  isSaved: boolean;
begin
  Ext := ExtractFileExt(FileName);
  Ext := UpperCase(Ext);

  if (Ext = '.JPG') or (Ext = '.JPEG') then
    try
      jpg := TJPEGImage.Create();
      jpg.Assign(BM);
      jpg.SaveToFile(FileName);
      jpg.Free;
      isSaved := true;
    except
      isSaved := false;
    end;

  if (Ext = '.PNG') then
    try
      PNG := TPNGImage.Create();
      PNG.Assign(BM);
      PNG.SaveToFile(FileName);
      PNG.Free;
      isSaved := true;
    except
      isSaved := false;
    end;

  if Ext = '.BMP' then
    try
      BM.SaveToFile(FileName);
      isSaved := true;
    except
      isSaved := false;
    end;

  if not isSaved then
  begin
    BM.SaveToFile(FileName + '.BMP');
  end;
end;

end.
