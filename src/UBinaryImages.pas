unit UBinaryImages;

interface

uses
  VCL.Graphics;

type
  /// Бинарное изображение
  TCBinaryImage = class
  private
    ImgHeight: word; // Высота изображения
    ImgWidth: word; // Ширина изображения

    procedure SetHeight(newHeight: word); // Задать новую высоту изображения
    function GetHeight: word; // Получить высоту изображения
    procedure SetWidth(newWidth: word); // Задать новую ширину изображения
    function GetWidth: word; // Получить высоту изображения

    procedure FreePixels; // Освобождение пикселей изображения
    procedure InitPixels;
    // Инициализация пикслей изображения нулевыми значениями
    function GetPixelValue(i, j: integer): boolean;
    // Возвращает заданный пиксел изображения. Если запрашиваемые координаты за пределами изображения, возвращается значение ближайшего пиксела
  public
    Pixels: array of array of boolean; // Пиксели изображения
    constructor Create; // Простой конструктор
    destructor FreeBinaryImage; // Стандартный деструктор

    property Height: word read GetHeight write SetHeight; // Свойство для чтения и записи высоты изображения
    property Width: word read GetWidth write SetWidth; // Свойство для чтения и записи ширины изображения

    procedure Invert;

    function SaveToBitMap: TBitmap;
    // Сохранение изображения в виде битовой карты
  end;

implementation

uses
  UPixelConvert, SysUtils;

constructor TCBinaryImage.Create;
begin
  inherited;
  self.ImgHeight := 0;
  self.ImgWidth := 0;
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
  if (self.ImgHeight > 0) and (self.ImgWidth > 0) then
  begin
    for i := 0 to self.ImgHeight - 1 do
    begin
      SetLength(self.Pixels[i], 0);
      Finalize(self.Pixels[i]);
      self.Pixels[i] := nil;
    end;
    SetLength(self.Pixels, 0);
    Finalize(self.Pixels);
    self.Pixels := nil;
  end;
end;

procedure TCBinaryImage.InitPixels;
var
  i, j: word;
begin
  if (self.ImgHeight > 0) and (self.ImgWidth > 0) then
  begin
    SetLength(self.Pixels, self.ImgHeight);
    for i := 0 to self.ImgHeight - 1 do
    begin
      SetLength(self.Pixels[i], self.ImgWidth);
      for j := 0 to self.ImgWidth - 1 do
        self.Pixels[i, j] := false;
    end;
  end;
end;

function TCBinaryImage.GetPixelValue(i, j: integer): boolean;
begin
  if i < 0 then
    i := 0;
  if i >= self.ImgHeight then
    i := self.ImgHeight - 1;
  if j < 0 then
    j := 0;
  if j >= self.ImgWidth then
    j := self.ImgWidth - 1;
  GetPixelValue := self.Pixels[i, j];
end;

procedure TCBinaryImage.SetHeight(newHeight: word);
begin
  FreePixels;
  self.ImgHeight := newHeight;
  self.InitPixels;
end;

function TCBinaryImage.GetHeight: word;
begin
  GetHeight := self.ImgHeight;
end;

procedure TCBinaryImage.SetWidth(newWidth: word);
begin
  FreePixels;
  self.ImgWidth := newWidth;
  self.InitPixels;
end;

function TCBinaryImage.GetWidth: word;
begin
  GetWidth := self.ImgWidth;
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
  BM.Height := self.ImgHeight;
  BM.Width := self.ImgWidth;
  for i := 0 to self.ImgHeight - 1 do
  begin
    line := BM.ScanLine[i];
    for j := 0 to self.ImgWidth - 1 do
    begin
      if self.Pixels[i, j] then
        p.SetRGB(0, 0, 0)
      else
        p.SetRGB(1, 1, 1);
      line[3 * j + 2] := round(p.GetRed * 255);
      line[3 * j + 1] := round(p.GetGreen * 255);
      line[3 * j + 0] := round(p.GetBlue * 255);
    end;
  end;
  SaveToBitMap := BM;
  p.Free;
end;

procedure TCBinaryImage.Invert;
var
  i, j: word;
begin
  for i := 0 to self.ImgHeight - 1 do
    for j := 0 to self.ImgWidth - 1 do
      self.Pixels[i, j] := not self.Pixels[i, j];
end;

end.
