unit UBinaryImages;

interface

uses
  VCL.Graphics;

type
  /// Бинарное изображение
  TCBinaryImage = class
  private
    Height, Width: word; // Геометрические размеры изображения

    procedure FreePixels; // Освобождение пикселей изображения
    procedure InitPixels; // Инициализация пикслей изображения нулевыми значениями
    function GetPixelValue(i, j: integer): boolean; // Возвращает заданный пиксел изображения. Если запрашиваемые координаты за пределами изображения, возвращается значение ближайшего пиксела
  public
    Pixels: array of array of boolean; // Пиксели изображения
    constructor Create; // Простой конструктор
    destructor FreeBinaryImage; // Стандартный деструктор

    procedure SetHeight(newHeight: word); // Задать новую высоту изображения
    function GetHeight: word; // Получить высоту изображения
    procedure SetWidth(newWidth: word); // Задать новую ширину изображения
    function GetWidth: word; // Получить высоту изображения

    function SaveToBitMap: TBitmap; // Сохранение изображения в виде битовой карты
  end;

implementation

uses
  UPixelConvert, SysUtils;

constructor TCBinaryImage.Create;
begin
  inherited;
  self.Height := 0;
  self.Width := 0;
end;

destructor TCBinaryImage.FreeBinaryImage;
begin
  self.FreePixels;
  inherited;
end;

procedure TCBinaryImage.FreePixels;
var
  i: word;
begin
  if (self.Height > 0) and (self.Width > 0) then
  begin
    for i := 0 to self.Height - 1 do
    begin
      SetLength(
        self.Pixels[i],
        0);
      Finalize(self.Pixels[i]);
      self.Pixels[i] := nil;
    end;
    SetLength(
      self.Pixels,
      0);
    Finalize(self.Pixels);
    self.Pixels := nil;
  end;
end;

procedure TCBinaryImage.InitPixels;
var
  i, j: word;
begin
  if (self.Height > 0) and (self.Width > 0) then
  begin
    SetLength(
      self.Pixels,
      self.Height);
    for i := 0 to self.Height - 1 do
    begin
      SetLength(
        self.Pixels[i],
        self.Width);
      for j := 0 to self.Width - 1 do
        self.Pixels[i, j] := false;
    end;
  end;
end;

function TCBinaryImage.GetPixelValue(i, j: integer): boolean;
begin
  if i < 0 then
    i := 0;
  if i >= self.Height then
    i := self.Height - 1;
  if j < 0 then
    j := 0;
  if j >= self.Width then
    j := self.Width - 1;
  GetPixelValue := self.Pixels[i, j];
end;

procedure TCBinaryImage.SetHeight(newHeight: word);
begin
  FreePixels;
  self.Height := newHeight;
  self.InitPixels;
end;

function TCBinaryImage.GetHeight: word;
begin
  GetHeight := self.Height;
end;

procedure TCBinaryImage.SetWidth(newWidth: word);
begin
  FreePixels;
  self.Width := newWidth;
  self.InitPixels;
end;

function TCBinaryImage.GetWidth: word;
begin
  GetWidth := self.Width;
end;

function TCBinaryImage.SaveToBitMap: TBitmap;
var
  i, j: word;
  BM: TBitmap;
  p: TColorPixel;
  line: pByteArray;
begin
  p := TColorPixel.Create;
  BM := TBitmap.Create;
  BM.PixelFormat := pf24bit;
  BM.Height := self.Height;
  BM.Width := self.Width;
  for i := 0 to self.Height - 1 do
  begin
    line := BM.ScanLine[i];
    for j := 0 to self.Width - 1 do
    begin
      if self.Pixels[i, j] then
        p.SetRGB(
          1,
          1,
          1)
      else
        p.SetRGB(
          0,
          0,
          0);
      line[3 * j + 2] := round(p.GetRed * 255);
      line[3 * j + 1] := round(p.GetGreen * 255);
      line[3 * j + 0] := round(p.GetBlue * 255);
    end;
  end;
  SaveToBitMap := BM;
  p.Free;
end;

end.
