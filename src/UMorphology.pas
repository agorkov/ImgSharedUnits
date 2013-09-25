unit UMorphology;

interface

uses
  UImages;

type
  TBinaryStructElem = record
    Mask: TBinaryImage;
    Cx, Cy: word;
  end;

function dilation(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
function erosion(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
function closing(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
function opening(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
function conditional_dilatation(BI, BIOrigin: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
function HitOrMiss(A, X: TBinaryImage): TBinaryImage;
function Borders(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
function MorphologyCarcass(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
function Skeleton(BI: TBinaryImage): TBinaryImage;

implementation

uses
  Math, UFMain;

function dilation(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
var
  i, j, SEi, SEj: integer;
  BIR: TBinaryImage;
begin
  InitBinaryImg(BIR, BI.N, BI.M);
  for i := 1 to BI.N do
    for j := 1 to BI.M do
      if BI.i[i, j] then
        for SEi := 1 to StructElem.Mask.N do
          for SEj := 1 to StructElem.Mask.M do
            if not((i + SEi - StructElem.Cy < 1) or (j + SEj - StructElem.Cx < 1) or (i + SEi - StructElem.Cy > BI.N) or (j + SEj - StructElem.Cx > BI.M)) then
              BIR.i[i + SEi - StructElem.Cy, j + SEj - StructElem.Cx] := BIR.i[i + SEi - StructElem.Cy, j + SEj - StructElem.Cx] or BI.i[i + SEi - StructElem.Cy, j + SEj - StructElem.Cx] or StructElem.Mask.i[SEi, SEj];
  dilation := BIR;
end;

function erosion(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
var
  i, j, SEi, SEj: integer;
  fl: boolean;
  BIR: TBinaryImage;
begin
  InitBinaryImg(BIR, BI.N, BI.M);
  for i := 1 to BI.N do
    for j := 1 to BI.M do
    begin
      fl := true;
      for SEi := 1 to StructElem.Mask.N do
        for SEj := 1 to StructElem.Mask.M do
        begin
          if (i + SEi - 1 < 1) or (j + SEj - 1 < 1) or (i + SEi - 1 > BI.N) or (j + SEj - 1 > BI.M) then
            fl := false
          else
            if StructElem.Mask.i[SEi, SEj] then
              fl := fl and BI.i[i + SEi - 1, j + SEj - 1];
        end;
      if fl then
        BIR.i[i + StructElem.Cy - 1, j + StructElem.Cx - 1] := true;
    end;
  erosion := BIR;
end;

function closing(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
var
  BIR: TBinaryImage;
begin
  BIR := erosion(dilation(BI, StructElem), StructElem);
  closing := BIR;
end;

function opening(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
var
  BIR: TBinaryImage;
begin
  BIR := dilation(erosion(BI, StructElem), StructElem);
  opening := BIR;
end;

function HitOrMiss(A, X: TBinaryImage): TBinaryImage;
var
  AC, Wx: TBinaryImage;
  Mx, MWx: TBinaryStructElem;
  i, j: word;
begin
  AC := ImgNOT(A);
  InitBinaryImg(Wx, X.N + 2, X.M + 2);
  Wx := ImgNOT(Wx);
  for i := 2 to Wx.N - 1 do
    for j := 2 to Wx.M - 1 do
      if X.i[i - 1, j - 1] then
        Wx.i[i, j] := false;
  Mx.Mask := X;
  Mx.Cx := 1;
  Mx.Cy := 1;
  MWx.Mask := Wx;
  MWx.Cx := 2;
  MWx.Cy := 2;
  HitOrMiss := ImgAND(erosion(A, Mx), erosion(AC, MWx));
end;

function conditional_dilatation(BI, BIOrigin: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
var
  BIR, BIOld: TBinaryImage;
begin
  BIR := ImgOR(BI, BI);
  repeat
    BIOld := ImgOR(BIR, BIR);
    BIR := dilation(BIR, StructElem);
    BIR := ImgAND(BIR, BIOrigin);
  until ImgEquals(BIR, BIOld);
  conditional_dilatation := BIOld;
end;

function Borders(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
begin
  Borders := ImgNOT(ImgOR(ImgNOT(BI), erosion(BI, StructElem)))
end;

function MorphologyCarcass(BI: TBinaryImage; StructElem: TBinaryStructElem): TBinaryImage;
  function GetTmpK(BI: TBinaryImage; StructElem: TBinaryStructElem; k: word): TBinaryImage;
  var
    tmp1, tmp2: TBinaryImage;
    i, j: word;
  begin
    tmp1 := ImgOR(BI, BI);
    for i := 1 to k do
      tmp1 := erosion(tmp1, StructElem);
    tmp2 := opening(tmp1, StructElem);
    for i := 1 to tmp1.N do
      for j := 1 to tmp1.M do
        if tmp2.i[i, j] then
          tmp1.i[i, j] := false;
    GetTmpK := tmp1;
  end;

var
  BIR, BIOld: TBinaryImage;
  i: word;
begin
  InitBinaryImg(BIR, BI.N, BI.M);
  i := 0;
  REPEAT
    BIOld := ImgOR(BIR, BIR);
    BIR := ImgOR(BIR, GetTmpK(BI, StructElem, i));
    i := i + 1;
  UNTIL ImgEquals(BIR, BIOld);
  MorphologyCarcass := BIR;
end;

function Skeleton(BI: TBinaryImage): TBinaryImage;
  function p(BI: TBinaryImage; r, c: word; ind: byte): boolean;
  var
    res: boolean;
  begin
    res := false;
    case ind of
    0: res := BI.i[r, c];
    1: res := BI.i[r - 1, c];
    2: res := BI.i[r - 1, c + 1];
    3: res := BI.i[r, c + 1];
    4: res := BI.i[r + 1, c + 1];
    5: res := BI.i[r + 1, c];
    6: res := BI.i[r + 1, c - 1];
    7: res := BI.i[r, c - 1];
    8: res := BI.i[r - 1, c - 1];
    end;
    p := res;
  end;

  function NeighbourCount(BI: TBinaryImage; r, c: word): byte;
  var
    i: byte;
    tmp: byte;
  begin
    tmp := 0;
    for i := 1 to 8 do
      tmp := tmp + word(p(BI, r, c, i));
    NeighbourCount := tmp;
  end;

  function TransitionCount(BI: TBinaryImage; r, c: word): byte;
  var
    tmp, i: byte;
  begin
    tmp := 0;
    for i := 1 to 7 do
      if (not p(BI, r, c, i)) and (p(BI, r, c, i + 1)) then
        tmp := tmp + 1;
    if (not p(BI, r, c, 8)) and (p(BI, r, c, 1)) then
      tmp := tmp + 1;
    TransitionCount := tmp;
  end;

  function Kontur(BI: TBinaryImage): TBinaryImage;
  var
    i, j: word;
    BIR: TBinaryImage;
  begin
    InitBinaryImg(BIR, BI.N, BI.M);
    for i := 1 to BI.N do
      for j := 1 to BI.M do
        if BI.i[i, j] then
          if not(p(BI, i, j, 2) and p(BI, i, j, 3) and p(BI, i, j, 4) and p(BI, i, j, 5) and p(BI, i, j, 6) and p(BI, i, j, 7) and p(BI, i, j, 8)) then
            BIR.i[i, j] := true;
    Kontur := BIR;
  end;

  function Thin(BIR: TBinaryImage): TBinaryImage;
  var
    Border, NewBorder: TBinaryImage;
    fl: boolean;
    i, j: word;
  begin
    Border := Kontur(BIR);
    NewBorder := ImgOR(Border, Border);
    for i := 1 to Border.N do
      for j := 1 to Border.M do
        if Border.i[i, j] then
        begin
          fl := true;
          fl := fl and (NeighbourCount(BIR, i, j) in [2 .. 6]);
          fl := fl and (TransitionCount(BIR, i, j) = 1);
          fl := fl and ((p(BIR, i, j, 1) and p(BIR, i, j, 3) and p(BIR, i, j, 5)) = false);
          fl := fl and ((p(BIR, i, j, 3) and p(BIR, i, j, 5) and p(BIR, i, j, 6)) = false);
          if fl then
            NewBorder.i[i, j] := false;
        end;
    for i := 1 to Border.N do
      for j := 1 to Border.M do
        if Border.i[i, j] then
          BIR.i[i, j] := NewBorder.i[i, j];
    Border := Kontur(BIR);
    NewBorder := ImgOR(Border, Border);
    for i := 1 to Border.N do
      for j := 1 to Border.M do
        if Border.i[i, j] then
        begin
          fl := true;
          fl := fl and (NeighbourCount(BIR, i, j) in [2 .. 6]);
          fl := fl and (TransitionCount(BIR, i, j) = 1);
          fl := fl and ((p(BIR, i, j, 1) and p(BIR, i, j, 3) and p(BIR, i, j, 7)) = false);
          fl := fl and ((p(BIR, i, j, 1) and p(BIR, i, j, 5) and p(BIR, i, j, 7)) = false);
          if fl then
            NewBorder.i[i, j] := false;
        end;
    for i := 1 to Border.N do
      for j := 1 to Border.M do
        if Border.i[i, j] then
          BIR.i[i, j] := NewBorder.i[i, j];
    Thin := BIR;
  end;

var
  ImgOld: TBinaryImage;
begin
  REPEAT
    ImgOld := ImgOR(BI, BI);
    BI := Thin(BI);
  UNTIL ImgEquals(BI, ImgOld);
  Skeleton := BI;
end;

end.
