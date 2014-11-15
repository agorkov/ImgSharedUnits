unit UGrayscaleImages;

interface

uses
  VCL.Graphics;

type
  /// Монохромное изображение
  TCGrayscaleImage = class
  private
    Height, Width: word; // Геометрические размеры изображения

    procedure FreePixels; // Освобождение пикселей изображения
    procedure InitPixels; // Инициализация пикслей изображения нулевыми значениями
    function GetPixelValue(i, j: integer): double; // Возвращает заданный пиксел изображения. Если запрашиваемые координаты за пределами изображения, возвращается значение ближайшего пиксела
    constructor CreateCopy(From: TCGrayscaleImage); // Конструктор с копированием другого монохромного изображения
    procedure Copy(From: TCGrayscaleImage); // Копирование монохромного изображения
  public
    Pixels: array of array of double; // Пиксели изображения
    constructor Create; // Простой конструктор
    constructor CreateAndLoadFromBitmap(BM: TBitmap); // Конструктор с автоматической загрузкой изображения из битовой карты
    destructor FreeGrayscaleImage; // Стандартный деструктор

    procedure SetHeight(newHeight: word); // Задать новую высоту изображения
    function GetHeight: word; // Получить высоту изображения
    procedure SetWidth(newWidth: word); // Задать новую ширину изображения
    function GetWidth: word; // Получить высоту изображения

    procedure AVGFilter(h, w: word); // Фильтр на основе среднегоарифметического
    procedure WeightedAVGFilter(h, w: word); // Фильтр на основе взвешенной суммы
    procedure GeometricMeanFilter(h, w: word); // Фильтр на основе среднего геометрического
    procedure MedianFilter(h, w: word); // Медианный фильтр
    procedure MaxFilter(h, w: word); // Фильтр максимума
    procedure MinFilter(h, w: word); // Фильтр минимума
    procedure MiddlePointFilter(h, w: word); // Фильтр на основе срединной точки
    procedure TruncatedAVGFilter(h, w, d: word); // Фильтр усечённого среднего
    procedure PrevittFilter(AddToOriginal: boolean); // Фильтр Превитт
    procedure SobelFilter(AddToOriginal: boolean); // Фильтр Собеля
    procedure SharrFilter(AddToOriginal: boolean); // Фильтр Щарра
    procedure LaplaceFilter(AddToOriginal: boolean); // Фильтр Лапласа

    procedure HistogramEqualization; // Эквализация гистограммы
    function Histogram: TBitmap; // Получение гистограммы

    procedure LinearTransform(k, b: double); // Линейное преобразование
    procedure LogTransform(c: double); // Логарифмическое преобразование
    procedure GammaTransform(c, gamma: double); // Гамма-коррекция

    procedure LoadFromBitMap(BM: TBitmap); // Загрузка изображения из битовой карты
    function SaveToBitMap: TBitmap; // Сохранение изображения в виде битовой карты
  end;

implementation

uses
  Math, SysUtils, UPixelConvert;

const
  LaplaceMask: array [1 .. 3, 1 .. 3] of shortint = ((1, 1, 1), (1, -8, 1), (1, 1, 1));

  SobelMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-1, 0, 1), (-2, 0, 2), (-1, 0, 1));
  SobelMaskY: array [1 .. 3, 1 .. 3] of shortint = ((1, 2, 1), (0, 0, 0), (-1, -2, -1));

  PrevittMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-1, 0, 1), (-1, 0, 1), (-1, 0, 1));
  PrevittMaskY: array [1 .. 3, 1 .. 3] of shortint = ((1, 1, 1), (0, 0, 0), (-1, -1, -1));

  SharrMaskX: array [1 .. 3, 1 .. 3] of shortint = ((-3, 0, 3), (-10, 0, 10), (-3, 0, 3));
  SharrMaskY: array [1 .. 3, 1 .. 3] of shortint = ((3, 10, 3), (0, 0, 0), (-3, -10, -3));

constructor TCGrayscaleImage.Create;
begin
  inherited;
  self.Height := 0;
  self.Width := 0;
end;

constructor TCGrayscaleImage.CreateAndLoadFromBitmap(BM: TBitmap);
begin
  inherited;
  self.Height := 0;
  self.Width := 0;
  self.LoadFromBitMap(BM);
end;

constructor TCGrayscaleImage.CreateCopy(From: TCGrayscaleImage);
var
  i, j: word;
begin
  inherited;
  self.SetHeight(From.GetHeight);
  self.SetWidth(From.GetWidth);
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      self.Pixels[i, j] := From.Pixels[i, j];
end;

destructor TCGrayscaleImage.FreeGrayscaleImage;
begin
  self.FreePixels;
  inherited;
end;

procedure TCGrayscaleImage.FreePixels;
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

procedure TCGrayscaleImage.InitPixels;
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
        self.Pixels[i, j] := 0;
    end;
  end;
end;

procedure TCGrayscaleImage.SetHeight(newHeight: word);
begin
  FreePixels;
  self.Height := newHeight;
  self.InitPixels;
end;

function TCGrayscaleImage.GetHeight: word;
begin
  GetHeight := self.Height;
end;

procedure TCGrayscaleImage.SetWidth(newWidth: word);
begin
  FreePixels;
  self.Width := newWidth;
  self.InitPixels;
end;

function TCGrayscaleImage.GetWidth: word;
begin
  GetWidth := self.Width;
end;

function TCGrayscaleImage.GetPixelValue(i, j: integer): double;
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

procedure TCGrayscaleImage.Copy(From: TCGrayscaleImage);
var
  i, j: word;
begin
  if (self.Height <> From.Height) or (self.Width <> From.Width) then
  begin
    self.SetHeight(From.Height);
    self.SetWidth(From.Width);
  end;
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      self.Pixels[i, j] := From.Pixels[i, j];
end;

procedure TCGrayscaleImage.AVGFilter(h, w: word);
var
  i, j: word;
  fi, fj: integer;
  sum: double;
  GSIR: TCGrayscaleImage;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      sum := 0;
      for fi := -h to h do
        for fj := -w to w do
          sum := sum + self.GetPixelValue(i + fi, j + fj);
      sum := sum / ((2 * h + 1) * (2 * w + 1));
      GSIR.Pixels[i, j] := sum;
    end;
  self.Copy(GSIR);
  GSIR.Free;
end;

procedure TCGrayscaleImage.WeightedAVGFilter(h, w: word);
var
  i, j: integer;
  fi, fj: integer;
  sum: double;
  GSIR: TCGrayscaleImage;
  Mask: array of array of double;
  maxDist, maskWeigth: double;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);
  SetLength(
    Mask,
    2 * h + 2);
  for i := 1 to 2 * h + 1 do
    SetLength(
      Mask[i],
      2 * w + 2);
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

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      sum := 0;
      for fi := -h to h do
        for fj := -w to w do
          sum := sum + Mask[fi + h + 1, fj + w + 1] * self.GetPixelValue(i + fi, j + fj);
      GSIR.Pixels[i, j] := sum / maskWeigth;
    end;

  self.Copy(GSIR);
  GSIR.Free;
  SetLength(
    Mask,
    0);
  Finalize(Mask);
  Mask := nil;
end;

procedure TCGrayscaleImage.GeometricMeanFilter(h, w: word);
var
  i, j: word;
  fi, fj: integer;
  p: extended;
  GSIR: TCGrayscaleImage;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      p := 1;
      for fi := -h to h do
        for fj := -w to w do
          p := p * self.GetPixelValue(i + fi, j + fj);
      p := power(
        p,
        1 / ((2 * h + 1) * (2 * w + 1)));
      GSIR.Pixels[i, j] := p;
    end;

  self.Copy(GSIR);
  GSIR.Free;
end;

procedure TCGrayscaleImage.MedianFilter(h, w: word);
  function FindMedian(
    N: word;
    var Arr: array of double): double;
  var
    L, R, k, i, j: word;
    w, x: double;
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
  GSIR: TCGrayscaleImage;
  k: word;
  tmp: array of double;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);
  SetLength(
    tmp,
    (2 * h + 1) * (2 * w + 1) + 1);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := self.GetPixelValue(
            i + fi,
            j + fj);
        end;
      GSIR.Pixels[i, j] := FindMedian(
        (2 * h + 1) * (2 * w + 1),
        tmp);
    end;
  tmp := nil;

  self.Copy(GSIR);
  GSIR.Free;
  SetLength(
    tmp,
    0);
  Finalize(tmp);
  tmp := nil;
end;

procedure TCGrayscaleImage.MaxFilter(h, w: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TCGrayscaleImage;
  k: word;
  Max: double;
  tmp: array of double;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);
  SetLength(
    tmp,
    (2 * h + 1) * (2 * w + 1) + 1);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := self.GetPixelValue(
            i + fi,
            j + fj);
        end;
      Max := tmp[1];
      for k := 1 to (2 * h + 1) * (2 * w + 1) do
        if tmp[k] > Max then
          Max := tmp[k];
      GSIR.Pixels[i, j] := Max;
    end;
  tmp := nil;

  self.Copy(GSIR);
  GSIR.Free;
  SetLength(
    tmp,
    0);
  Finalize(tmp);
  tmp := nil;
end;

procedure TCGrayscaleImage.MinFilter(h, w: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TCGrayscaleImage;
  k: word;
  Min: double;
  tmp: array of double;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);
  SetLength(
    tmp,
    (2 * h + 1) * (2 * w + 1) + 1);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := self.GetPixelValue(
            i + fi,
            j + fj);
        end;
      Min := tmp[1];
      for k := 1 to (2 * h + 1) * (2 * w + 1) do
        if tmp[k] < Min then
          Min := tmp[k];
      GSIR.Pixels[i, j] := Min;
    end;
  tmp := nil;

  self.Copy(GSIR);
  GSIR.FreeGrayscaleImage;
  SetLength(
    tmp,
    0);
  Finalize(tmp);
  tmp := nil;
end;

procedure TCGrayscaleImage.MiddlePointFilter(h, w: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TCGrayscaleImage;
  k: word;
  Min, Max: double;
  tmp: array of double;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);
  SetLength(
    tmp,
    (2 * h + 1) * (2 * w + 1) + 1);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := self.GetPixelValue(
            i + fi,
            j + fj);
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
      GSIR.Pixels[i, j] := (Max + Min) / 2;
    end;
  tmp := nil;

  self.Copy(GSIR);
  GSIR.FreeGrayscaleImage;
  SetLength(
    tmp,
    0);
  Finalize(tmp);
  tmp := nil;
end;

procedure TCGrayscaleImage.TruncatedAVGFilter(h, w, d: word);
var
  i, j: word;
  fi, fj: integer;
  GSIR: TCGrayscaleImage;
  k, L: word;
  val: double;
  tmp: array of double;
  sum: double;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);
  SetLength(
    tmp,
    (2 * h + 1) * (2 * w + 1) + 1);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      k := 0;
      for fi := -h to h do
        for fj := -w to w do
        begin
          k := k + 1;
          tmp[k] := self.GetPixelValue(
            i + fi,
            j + fj);
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
      GSIR.Pixels[i, j] := sum / ((2 * h + 1) * (2 * w + 1) - 2 * d);
    end;
  tmp := nil;

  self.Copy(GSIR);
  GSIR.FreeGrayscaleImage;
  SetLength(
    tmp,
    0);
  Finalize(tmp);
  tmp := nil;
end;

procedure TCGrayscaleImage.PrevittFilter(AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: double;
  GSIR: TCGrayscaleImage;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + PrevittMaskX[fi + 1 + 1, fj + 1 + 1] * self.GetPixelValue(i + fi, j + fj) + PrevittMaskY[fi + 1 + 1, fj + 1 + 1] * self.GetPixelValue(i + fi, j + fj);
      if AddToOriginal then
        response := self.Pixels[i, j] + response;
      GSIR.Pixels[i, j] := response;
      if response > 1 then
        GSIR.Pixels[i, j] := 1;
      if response < 0 then
        GSIR.Pixels[i, j] := 0;
    end;

  self.Copy(GSIR);
  GSIR.FreeGrayscaleImage;
end;

procedure TCGrayscaleImage.SobelFilter(AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: double;
  GSIR: TCGrayscaleImage;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + SobelMaskX[fi + 1 + 1, fj + 1 + 1] * self.GetPixelValue(i + fi, j + fj) + SobelMaskY[fi + 1 + 1, fj + 1 + 1] * self.GetPixelValue(i + fi, j + fj);
      if AddToOriginal then
        response := self.Pixels[i, j] + response;
      GSIR.Pixels[i, j] := response;
      if response > 1 then
        GSIR.Pixels[i, j] := 1;
      if response < 0 then
        GSIR.Pixels[i, j] := 0;
    end;

  self.Copy(GSIR);
  GSIR.FreeGrayscaleImage;
end;

procedure TCGrayscaleImage.SharrFilter(AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: double;
  GSIR: TCGrayscaleImage;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + SharrMaskX[fi + 1 + 1, fj + 1 + 1] * self.GetPixelValue(i + fi, j + fj) + SharrMaskY[fi + 1 + 1, fj + 1 + 1] * self.GetPixelValue(i + fi, j + fj);
      if AddToOriginal then
        response := self.Pixels[i, j] + response;
      GSIR.Pixels[i, j] := response;
      if response > 1 then
        GSIR.Pixels[i, j] := 1;
      if response < 0 then
        GSIR.Pixels[i, j] := 0;
    end;

  self.Copy(GSIR);
  GSIR.FreeGrayscaleImage;
end;

procedure TCGrayscaleImage.LaplaceFilter(AddToOriginal: boolean);
var
  i, j: integer;
  fi, fj: integer;
  response: double;
  GSIR: TCGrayscaleImage;
begin
  GSIR := TCGrayscaleImage.CreateCopy(self);

  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      response := 0;
      for fi := -1 to 1 do
        for fj := -1 to 1 do
          response := response + LaplaceMask[fi + 1 + 1, fj + 1 + 1] * self.GetPixelValue(i + fi, j + fj);
      if AddToOriginal then
        response := self.Pixels[i, j] - response;
      GSIR.Pixels[i, j] := response;
      if response > 1 then
        GSIR.Pixels[i, j] := 1;
      if response < 0 then
        GSIR.Pixels[i, j] := 0;
    end;

  self.Copy(GSIR);
  GSIR.FreeGrayscaleImage;
end;

procedure TCGrayscaleImage.LinearTransform(k, b: double);
var
  i, j: word;
  val: double;
begin
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      val := k * self.Pixels[i, j] + b;
      if val > 1 then
        val := 1;
      if val < 0 then
        val := 0;
      self.Pixels[i, j] := val;
    end;
end;

procedure TCGrayscaleImage.LogTransform(c: double);
var
  i, j: word;
  val: double;
begin
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      val := c * log2(self.Pixels[i, j] + 1);
      if val > 1 then
        val := 1;
      if val < 0 then
        val := 0;
      self.Pixels[i, j] := val;
    end;
end;

procedure TCGrayscaleImage.GammaTransform(c, gamma: double);
var
  i, j: word;
  val: double;
begin
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
    begin
      val := c * power(self.Pixels[i, j], gamma);
      if val > 1 then
        val := 1;
      if val < 0 then
        val := 0;
      self.Pixels[i, j] := val;
    end;
end;

procedure TCGrayscaleImage.HistogramEqualization;
const
  k = 255;
var
  h: array [0 .. k] of double;
  i, j: word;
begin
  for i := 0 to k do
    h[i] := 0;
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      h[round(k * self.Pixels[i, j])] := h[round(k * self.Pixels[i, j])] + 1;
  for i := 0 to k do
    h[i] := h[i] / (self.Height * self.Width);

  for i := 1 to k do
    h[i] := h[i - 1] + h[i];
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      self.Pixels[i, j] := h[round(k * self.Pixels[i, j])];
end;

function TCGrayscaleImage.Histogram: TBitmap;
const
  k = 255;
var
  BM: TBitmap;
  h: array [0 .. k] of LongWord;
  Max: LongWord;
  i, j: word;
begin
  Max := 0;
  for i := 0 to k do
    h[i] := 0;
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      h[round(k * self.Pixels[i, j])] := h[round(k * self.Pixels[i, j])] + 1;

  for i := 0 to k do
    if h[i] > Max then
      Max := h[i];

  BM := TBitmap.Create;
  BM.Height := 100;
  BM.Width := 256;
  BM.Canvas.Pen.Color := clGray;
  BM.Canvas.Brush.Color := clGray;
  BM.Canvas.Brush.Style := bsSolid;

  for i := 0 to k do
  begin
    BM.Canvas.MoveTo(
      i,
      BM.Height);
    BM.Canvas.LineTo(
      i,
      BM.Height - round(h[i] * 100 / Max));
  end;
  Histogram := BM;
end;

procedure TCGrayscaleImage.LoadFromBitMap(BM: TBitmap);
var
  i, j: word;
  p: TColorPixel;
  line: pByteArray;
begin
  p := TColorPixel.Create;
  self.SetHeight(BM.Height);
  self.SetWidth(BM.Width);
  for i := 0 to self.Height - 1 do
  begin
    line := BM.ScanLine[i];
    for j := 0 to self.Width - 1 do
    begin
      p.SetRed(line[3 * j + 2] / 255);
      p.SetGreen(line[3 * j + 1] / 255);
      p.SetBlue(line[3 * j + 0] / 255);
      self.Pixels[i, j] := p.GetColorChannel(ccY);
    end;
  end;
  p.Free;
end;

function TCGrayscaleImage.SaveToBitMap: TBitmap;
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
      p.SetRGB(
        self.Pixels[i, j],
        self.Pixels[i, j],
        self.Pixels[i, j]);
      line[3 * j + 2] := round(p.GetRed * 255);
      line[3 * j + 1] := round(p.GetGreen * 255);
      line[3 * j + 0] := round(p.GetBlue * 255);
    end;
  end;
  SaveToBitMap := BM;
  p.Free;
end;

end.
