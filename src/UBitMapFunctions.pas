unit UBitMapFunctions;

interface

uses
  SysUtils, VCL.Graphics;

const
  SUPPORTED_FORMATS = '*.bmp;*.jpg;*.jpeg;*.png';

function LoadFromFile(const FileName: TFileName): TBitmap;
procedure SaveToFile(
  const BM: TBitmap;
  const FileName: string);
function GetHashHex(BMOrigin: TBitmap): string;
function GetHashInt64(BMOrigin: TBitmap): int64;
function CompareHashes(Hash1, Hash2: int64): double;
function CompareImages(BM1, BM2: TBitmap): double;

implementation

uses
  JPEG, PNGImage, UGrayscaleImages, UBinaryImages, Classes;

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
  isSaved := false;

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

function GetHashHex(BMOrigin: TBitmap): string;
const
  ImgHashSize = 8;
var
  BMMin: TBitmap;
  GSI: TCGrayscaleImage;
  BI: TCBinaryImage;
  i, j: word;
  avg: double;
  tmp, hex: string;
begin
  /// Создаём уменьшенное монохромное изображение (ImgHashSize*ImgHashSize пикселей)
  BMMin := TBitmap.Create;
  BMMin.Height := ImgHashSize;
  BMMin.Width := ImgHashSize;
  BMMin.Canvas.StretchDraw(
    Rect(0, 0, ImgHashSize - 1, ImgHashSize - 1),
    BMOrigin);
  GSI := TCGrayscaleImage.CreateAndLoadFromBitmap(BMMin);

  /// Вычисляем порог бинаризации
  avg := 0;
  for i := 0 to GSI.Height - 1 do
    for j := 0 to GSI.Width - 1 do
      avg := avg + GSI.Pixels[i, j];
  avg := avg / (ImgHashSize * ImgHashSize);

  /// Создаём бинарное изображение
  BI := GSI.ThresoldBinarization(avg);

  /// Вычисляем хеш
  tmp := '';
  hex := '';
  for i := 0 to BI.GetHeight - 1 do
    for j := 0 to BI.GetWidth - 1 do
    begin
      if BI.Pixels[i, j] then
        tmp := tmp + '1'
      else
        tmp := tmp + '0';
      if Length(tmp) = 4 then
      begin
        if tmp = '0000' then
          hex := hex + '0';
        if tmp = '0001' then
          hex := hex + '1';
        if tmp = '0010' then
          hex := hex + '2';
        if tmp = '0011' then
          hex := hex + '3';
        if tmp = '0100' then
          hex := hex + '4';
        if tmp = '0101' then
          hex := hex + '5';
        if tmp = '0110' then
          hex := hex + '6';
        if tmp = '0111' then
          hex := hex + '7';
        if tmp = '1000' then
          hex := hex + '8';
        if tmp = '1001' then
          hex := hex + '9';
        if tmp = '1010' then
          hex := hex + 'A';
        if tmp = '1011' then
          hex := hex + 'B';
        if tmp = '1100' then
          hex := hex + 'C';
        if tmp = '1101' then
          hex := hex + 'D';
        if tmp = '1110' then
          hex := hex + 'E';
        if tmp = '1111' then
          hex := hex + 'F';
        tmp := '';
      end;
    end;

  /// Освобождаем занятые ресурсы
  BMMin.Free;
  GSI.FreeGrayscaleImage;
  BI.FreeBinaryImage;
  GetHashHex := hex;
end;

function GetHashInt64(BMOrigin: TBitmap): int64;
begin
  GetHashInt64 := StrToInt64('0x' + GetHashHex(BMOrigin));
end;

function CompareHashes(Hash1, Hash2: int64): double;
var
  r: int64;
  count: byte;
begin
  r := not(Hash1 xor Hash2);
  count := 0;
  while r <> 0 do
  begin
    if odd(r) then
      count := count + 1;
    r := r shr 1;
  end;
  CompareHashes := count / 64;
end;

function CompareImages(BM1, BM2: TBitmap): double;
var
  h1, h2: int64;
begin
  h1 := UBitMapFunctions.GetHashInt64(BM1);
  h2 := UBitMapFunctions.GetHashInt64(BM2);
  CompareImages := CompareHashes(
    h1,
    h2);
end;

end.
