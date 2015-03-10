unit UColorImages;

interface

uses
  VCL.Graphics, UPixelConvert, UGrayscaleImages;

type
  /// Цветное изображение
  TCColorImage = class
  private
    ImgHeight: word; // Высота изображения
    ImgWidth: word; // Ширина изображения
    ImgPixels: array of array of TColorPixel; // Пиксели изображения

    procedure SetHeight(newHeight: word); // Задать новую высоту изображения
    function GetHeight: word; // Получить высоту изображения

    procedure SetWidth(newWidth: word); // Задать новую ширину изображения
    function GetWidth: word; // Получить высоту изображения

    procedure SetPixelValue(i, j: integer; value: TColorPixel); // Устанавливает значение заданного пиксела. Если запрашиваемые координаты за пределами изображения, устанавливается значение ближайшего пиксела
    function GetPixelValue(i, j: integer): TColorPixel; // Возвращает заданный пиксел изображения. Если запрашиваемые координаты за пределами изображения, возвращается значение ближайшего пиксела

    procedure InitPixels; // Инициализация пикслей изображения нулевыми значениями
    procedure FreePixels; // Освобождение пикселей изображения
  public
    constructor Create; // Простой конструктор
    constructor CreateAndLoadFromBitmap(BM: TBitmap); // Конструктор с автоматической загрузкой изображения из битовой карты
    destructor FreeColorImage; // Стандартный деструктор

    property Height: word read GetHeight write SetHeight; // Свойство для чтения и записи высоты изображения
    property Width: word read GetWidth write SetWidth; // Свойство для чтения и записи ширины изображения
    property Pixels[row, col: integer]: TColorPixel read GetPixelValue write SetPixelValue; // Свойство для чтения и записи отдельных пикселей

    function GetChanel(Channel: TEColorChannel): TCGrayscaleImage; // Считать заданный цветовой канал как монохромное изображение
    procedure SetChannel(Channel: TEColorChannel; GS: TCGrayscaleImage); // Задать моохромное изображение как цветовой канал

    procedure AVGFilter(Channel: TEColorChannel; h, w: word); // Фильтр на основе среднегоарифметического
    procedure WeightedAVGFilter(Channel: TEColorChannel; h, w: word); // Фильтр на основе взвешенной суммы
    procedure GeometricMeanFilter(Channel: TEColorChannel; h, w: word); // Фильтр на основе среднего геометрического
    procedure MedianFilter(Channel: TEColorChannel; h, w: word); // Медианный фильтр
    procedure MaxFilter(Channel: TEColorChannel; h, w: word); // Фильтр максимума
    procedure MinFilter(Channel: TEColorChannel; h, w: word); // Фильтр минимума
    procedure MiddlePointFilter(Channel: TEColorChannel; h, w: word); // Фильтр на основе срединной точки
    procedure TruncatedAVGFilter(Channel: TEColorChannel; h, w, d: word); // Фильтр усечённого среднего
    procedure PrevittFilter(Channel: TEColorChannel; AddToOriginal: boolean); // Фильтр Превитт
    procedure SobelFilter(Channel: TEColorChannel; AddToOriginal: boolean); // Фильтр Собеля
    procedure SharrFilter(Channel: TEColorChannel; AddToOriginal: boolean); // Фильтр Щарра
    procedure LaplaceFilter(Channel: TEColorChannel; AddToOriginal: boolean); // Фильтр Лапласа

    procedure LinearTransform(Channel: TEColorChannel; k, b: double); // Линейное преобразование
    procedure LogTransform(Channel: TEColorChannel; c: double); // Логарифмическое преобразование
    procedure GammaTransform(Channel: TEColorChannel; c, gamma: double); // Гамма-коррекция
    procedure EditContrast(Channel: TEColorChannel; k: double);

    procedure HistogramEqualization(Channel: TEColorChannel); // Эквализация гистограммы
    function Histogram(Channel: TEColorChannel): TBitmap; // Получение гистограммы

    procedure LoadFromBitMap(BM: TBitmap); // Загрузка изображения из битовой карты
    function SaveToBitMap: TBitmap; // Сохранение изображения в виде битовой карты

    function ConvertToGrayscale: TCGrayscaleImage; // Преобразование в монохромное изображение
  end;

implementation

uses
  SysUtils, UBinaryImages, Classes;

constructor TCColorImage.Create;
begin
  inherited;
  self.ImgHeight := 0;
  self.ImgWidth := 0;
end;

constructor TCColorImage.CreateAndLoadFromBitmap(BM: TBitmap);
begin
  inherited;
  self.ImgHeight := 0;
  self.ImgWidth := 0;
  self.LoadFromBitMap(BM);
end;

destructor TCColorImage.FreeColorImage;
begin
  self.FreePixels;
  inherited;
end;

procedure TCColorImage.FreePixels;
var
  i, j: word;
begin
  if (self.ImgHeight > 0) and (self.ImgWidth > 0) then
  begin
    for i := 0 to self.ImgHeight - 1 do
    begin
      for j := 0 to self.ImgWidth - 1 do
        self.ImgPixels[i, j].Free;
      SetLength(self.ImgPixels[i], 0);
      Finalize(self.ImgPixels[i]);
      self.ImgPixels[i] := nil;
    end;
    SetLength(self.ImgPixels, 0);
    Finalize(self.ImgPixels);
    self.ImgPixels := nil;
  end;
end;

procedure TCColorImage.InitPixels;
var
  i, j: word;
begin
  if (self.ImgHeight > 0) and (self.ImgWidth > 0) then
  begin
    SetLength(self.ImgPixels, self.ImgHeight);
    for i := 0 to self.ImgHeight - 1 do
    begin
      SetLength(self.ImgPixels[i], self.ImgWidth);
      for j := 0 to self.ImgWidth - 1 do
      begin
        self.ImgPixels[i, j] := TColorPixel.Create;
        self.ImgPixels[i, j].SetFullColor(0);
      end;
    end;
  end;
end;

procedure TCColorImage.SetHeight(newHeight: word);
begin
  FreePixels;
  self.ImgHeight := newHeight;
  self.InitPixels;
end;

function TCColorImage.GetHeight: word;
begin
  GetHeight := self.ImgHeight;
end;

procedure TCColorImage.SetWidth(newWidth: word);
begin
  FreePixels;
  self.ImgWidth := newWidth;
  self.InitPixels;
end;

function TCColorImage.GetWidth: word;
begin
  GetWidth := self.ImgWidth;
end;

function TCColorImage.GetPixelValue(i, j: integer): TColorPixel;
begin
  if i < 0 then
    i := 0;
  if i >= self.ImgHeight then
    i := self.ImgHeight - 1;
  if j < 0 then
    j := 0;
  if j >= self.ImgWidth then
    j := self.ImgWidth - 1;
  GetPixelValue := self.ImgPixels[i, j];
end;

procedure TCColorImage.SetPixelValue(i, j: integer; value: TColorPixel);
begin
  if i < 0 then
    i := 0;
  if i >= self.ImgHeight then
    i := self.ImgHeight - 1;
  if j < 0 then
    j := 0;
  if j >= self.ImgWidth then
    j := self.ImgWidth - 1;
  ImgPixels[i, j] := value;
end;

function TCColorImage.GetChanel(Channel: TEColorChannel): TCGrayscaleImage;
var
  i, j: word;
  GS: TCGrayscaleImage;
begin
  GS := TCGrayscaleImage.Create;
  GS.Height := self.ImgHeight;
  GS.Width := self.ImgWidth;
  for i := 0 to self.ImgHeight - 1 do
    for j := 0 to self.ImgWidth - 1 do
      GS.Pixels[i, j] := self.ImgPixels[i, j].GetColorChannel(Channel);
  GetChanel := GS;
end;

procedure TCColorImage.SetChannel(Channel: TEColorChannel; GS: TCGrayscaleImage);
var
  i, j: word;
begin
  if (self.ImgHeight <> GS.Height) or (self.ImgWidth <> GS.Width) then
  begin
    self.SetHeight(GS.Height);
    self.SetWidth(GS.Width);
  end;
  for i := 0 to self.ImgHeight - 1 do
    for j := 0 to self.ImgWidth - 1 do
      self.ImgPixels[i, j].SetColorChannel(Channel, GS.Pixels[i, j]);
end;

procedure TCColorImage.AVGFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.AVGFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.WeightedAVGFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.WeightedAVGFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.GeometricMeanFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.GeometricMeanFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.MedianFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MedianFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.MaxFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MaxFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.MinFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MinFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.MiddlePointFilter(Channel: TEColorChannel; h, w: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.MiddlePointFilter(h, w);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.TruncatedAVGFilter(Channel: TEColorChannel; h, w, d: word);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.TruncatedAVGFilter(h, w, d);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.PrevittFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.PrevittFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.SobelFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.SobelFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.SharrFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.SharrFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.LaplaceFilter(Channel: TEColorChannel; AddToOriginal: boolean);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.LaplaceFilter(AddToOriginal);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.HistogramEqualization(Channel: TEColorChannel);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.HistogramEqualization;
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.EditContrast(Channel: TEColorChannel; k: double);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.EditContrast(k);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

function TCColorImage.Histogram(Channel: TEColorChannel): TBitmap;
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  Histogram := GS.Histogram;
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.LinearTransform(Channel: TEColorChannel; k, b: double);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.LinearTransform(k, b);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.LogTransform(Channel: TEColorChannel; c: double);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.LogTransform(c);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.GammaTransform(Channel: TEColorChannel; c, gamma: double);
var
  GS: TCGrayscaleImage;
begin
  GS := self.GetChanel(Channel);
  GS.GammaTransform(c, gamma);
  self.SetChannel(Channel, GS);
  GS.FreeGrayscaleImage;
end;

procedure TCColorImage.LoadFromBitMap(BM: TBitmap);
var
  i, j: word;
  line: pByteArray;
begin
  BM.PixelFormat := pf24bit;
  self.ImgHeight := BM.Height;
  self.ImgWidth := BM.Width;
  self.InitPixels;
  for i := 0 to self.ImgHeight - 1 do
  begin
    line := BM.ScanLine[i];
    for j := 0 to self.ImgWidth - 1 do
    begin
      self.ImgPixels[i, j].SetRed(line[j * 3 + 2] / 255);
      self.ImgPixels[i, j].SetGreen(line[j * 3 + 1] / 255);
      self.ImgPixels[i, j].SetBlue(line[j * 3 + 0] / 255);
    end;
  end;
end;

function TCColorImage.SaveToBitMap: TBitmap;
var
  i, j: word;
  BM: TBitmap;
  line: pByteArray;
begin
  BM := TBitmap.Create;
  BM.PixelFormat := pf24bit;
  BM.Height := self.ImgHeight;
  BM.Width := self.ImgWidth;
  for i := 0 to self.ImgHeight - 1 do
  begin
    line := BM.ScanLine[i];
    for j := 0 to self.ImgWidth - 1 do
    begin
      line[j * 3 + 2] := round(self.ImgPixels[i, j].GetRed * 255);
      line[j * 3 + 1] := round(self.ImgPixels[i, j].GetGreen * 255);
      line[j * 3 + 0] := round(self.ImgPixels[i, j].GetBlue * 255);
    end;
  end;
  SaveToBitMap := BM;
end;

function TCColorImage.ConvertToGrayscale: TCGrayscaleImage;
var
  GSI: TCGrayscaleImage;
  i, j: word;
begin
  GSI := TCGrayscaleImage.Create;
  GSI.Height := self.ImgHeight;
  GSI.Width := self.ImgWidth;
  for i := 0 to self.ImgHeight - 1 do
    for j := 0 to self.ImgWidth - 1 do
      GSI.Pixels[i, j] := self.ImgPixels[i, j].GetY;
  ConvertToGrayscale := GSI;
end;

end.
