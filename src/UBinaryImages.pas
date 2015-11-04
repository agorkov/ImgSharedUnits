unit UBinaryImages;

interface

uses
  VCL.Graphics;

type
  TCBinaryImage = class
  private
    ImgHeight: word;
    ImgWidth: word;
    ImgPixels: array of array of boolean;

    procedure SetHeight(newHeight: word);
    function GetHeight: word;

    procedure SetWidth(newWidth: word);
    function GetWidth: word;

    procedure SetPixelValue(i, j: integer; value: boolean);
    function GetPixelValue(i, j: integer): boolean;

    procedure InitPixels;
    procedure FreePixels;

    procedure Copy(From: TCBinaryImage);
  public
    constructor Create;
    constructor CreateCopy(From: TCBinaryImage);
    destructor FreeBinaryImage;

    function SaveToBitMap: TBitmap;

    property Height: word read GetHeight write SetHeight;
    property Width: word read GetWidth write SetWidth;
    property Pixels[row, col: integer]: boolean read GetPixelValue write SetPixelValue;

    procedure Invert;

    procedure SaveToFile(FileName: string);

    procedure dilatation(Mask: TCBinaryImage; MaskRow, MaskCol: word);
    procedure erosion(Mask: TCBinaryImage; MaskRow, MaskCol: word);
    procedure closing(Mask: TCBinaryImage; MaskRow, MaskCol: word);
    procedure opening(Mask: TCBinaryImage; MaskRow, MaskCol: word);
  end;

implementation

uses
  UPixelConvert, SysUtils, UBitmapFunctions;

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
      SetLength(self.ImgPixels[i], 0);
      Finalize(self.ImgPixels[i]);
      self.ImgPixels[i] := nil;
    end;
    SetLength(self.ImgPixels, 0);
    Finalize(self.ImgPixels);
    self.ImgPixels := nil;
  end;
end;

procedure TCBinaryImage.InitPixels;
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
        self.ImgPixels[i, j] := false;
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
  GetPixelValue := self.ImgPixels[i, j];
end;

procedure TCBinaryImage.SetPixelValue(i, j: integer; value: boolean);
begin
  if i < 0 then
    i := 0;
  if i >= self.ImgHeight then
    i := self.ImgHeight - 1;
  if j < 0 then
    j := 0;
  if j >= self.ImgWidth then
    j := self.ImgWidth - 1;
  self.ImgPixels[i, j] := value;
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
      if self.ImgPixels[i, j] then
        p.SetRGB(0, 0, 0)
      else
        p.SetRGB(1, 1, 1);
      line[3 * j + 2] := round(p.Red * 255);
      line[3 * j + 1] := round(p.Green * 255);
      line[3 * j + 0] := round(p.Blue * 255);
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
      self.ImgPixels[i, j] := not self.ImgPixels[i, j];
end;

procedure TCBinaryImage.dilatation(Mask: TCBinaryImage; MaskRow, MaskCol: word);
var
  i, j, AreaI, AreaJ, Mi, Mj: integer;
  r: TCBinaryImage;
begin
  r := TCBinaryImage.Create;
  r.Height := self.ImgHeight;
  r.Width := self.ImgWidth;
  for i := 0 to r.Height - 1 do
    for j := 0 to r.Width - 1 do
      if self.Pixels[i, j] then
      begin
        Mi := 0;
        for AreaI := i - MaskRow to i + (Mask.Height - 1 - MaskRow) do
        begin
          Mj := 0;
          for AreaJ := j - MaskCol to j + (Mask.Width - 1 - MaskCol) do
          begin
            if (AreaI >= 0) and (AreaI <= r.Height - 1) and (AreaJ >= 0) and (AreaJ <= r.Width - 1) then
              r.Pixels[AreaI, AreaJ] := self.Pixels[AreaI, AreaJ] or Mask.Pixels[Mi, Mj] or r.Pixels[AreaI, AreaJ];
            Mj := Mj + 1;
          end;
          Mi := Mi + 1;
        end;
      end;
  self.Copy(r);
  r.FreeBinaryImage;
end;

procedure TCBinaryImage.erosion(Mask: TCBinaryImage; MaskRow, MaskCol: word);
var
  i, j, AreaI, AreaJ, Mi, Mj: integer;
  fl: boolean;
  r: TCBinaryImage;
begin
  r := TCBinaryImage.Create;
  r.Height := self.ImgHeight;
  r.Width := self.ImgWidth;
  for i := 0 to r.Height - 1 do
    for j := 0 to r.Width - 1 do
    begin
      fl := true;
      Mi := 0;
      for AreaI := i - MaskRow to i + (Mask.Height - 1 - MaskRow) do
      begin
        Mj := 0;
        for AreaJ := j - MaskCol to j + (Mask.Width - 1 - MaskCol) do
        begin
          if (AreaI >= 0) and (AreaI <= r.Height - 1) and (AreaJ >= 0) and (AreaJ <= r.Width - 1) then
          begin
            if Mask.Pixels[Mi, Mj] then
              fl := fl and self.Pixels[AreaI, AreaJ];
          end
          else
            fl := false;
          Mj := Mj + 1;
        end;
        Mi := Mi + 1;
      end;
      r.Pixels[i, j] := fl;
    end;
  self.Copy(r);
  r.FreeBinaryImage;
end;

procedure TCBinaryImage.closing(Mask: TCBinaryImage; MaskRow, MaskCol: word);
begin
  self.dilatation(Mask, MaskRow, MaskCol);
  self.erosion(Mask, MaskRow, MaskCol);
end;

procedure TCBinaryImage.opening(Mask: TCBinaryImage; MaskRow, MaskCol: word);
begin
  self.erosion(Mask, MaskRow, MaskCol);
  self.dilatation(Mask, MaskRow, MaskCol);
end;

procedure TCBinaryImage.Copy(From: TCBinaryImage);
var
  i, j: word;
begin
  self.Height := From.Height;
  self.Width := From.Width;
  for i := 0 to self.Height - 1 do
    for j := 0 to self.Width - 1 do
      self.Pixels[i, j] := From.Pixels[i, j];
end;

constructor TCBinaryImage.CreateCopy(From: TCBinaryImage);
begin
  inherited;
  self.Copy(From);
end;

procedure TCBinaryImage.SaveToFile(FileName: string);
var
  BM: TBitmap;
begin
  BM := self.SaveToBitMap;
  UBitmapFunctions.SaveToFile(BM, FileName);
  BM.Free;
end;

end.
