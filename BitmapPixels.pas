// -----------------------------------------------------------------------------
//                              *** BitmapPixels ***
//                      version 1.1, last update 13.12.2021
// -----------------------------------------------------------------------------
//                 Module for direct access to pixels at TBitmap
//            Tested on Windows(WinApi), Linux(Gtk2, Qt5), OSX(Cocoa)
// -----------------------------------------------------------------------------
//
// Latest verion of this unit aviable here:
//    https://github.com/crazzzypeter/BitmapPixels/
//
//   GitHub: https://github.com/crazzzypeter/
//   Twitch: https://www.twitch.tv/crazzzypeter/
//  YouTube: https://www.youtube.com/c/crazzzypeter/
// YouTube?: https://www.youtube.com/channel/UCPQmDZGb5mZJ27ev9-t3bGQ/
// Telegram: @crazzzypeter
//
// -----------------------------------------------------------------------------
// MIT LICENSE
//
// Copyright (c) 2021-2021 CrazzzyPeter
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// -----------------------------------------------------------------------------

{$REGION 'Examples'}
{
  Examples of use:

  --- 1 ---
  procedure InvertColors(const Bitmap: TBitmap);
  var
    Data: TBitmapData;
    X, Y: Integer;
    Pixel: TPixelRec;
  begin
    Data.Map(Bitmap, TAccessMode.ReadWrite, False);// RGB access
    try
      for Y := 0 to Data.Height - 1 do
      begin
        for X := 0 to Data.Width - 1 do
        begin
          Pixel := Data.GetPixel(X, Y);
          Pixel.R := 255 - Pixel.R;
          Pixel.G := 255 - Pixel.G;
          Pixel.B := 255 - Pixel.B;
          Data.SetPixel(X, Y, Pixel);
        end;
      end;
    finally
      Data.Unmap();
    end;
  end;

  --- 2 ---
  procedure HalfAlpha(const Bitmap: TBitmap);
  var
    Data: TBitmapData;
    X, Y: Integer;
    Pixel: TPixelRec;
  begin
    Data.Map(Bitmap, TAccessMode.ReadWrite, True);// ARGB access
    try
      for Y := 0 to Data.Height - 1 do
      begin
        for X := 0 to Data.Width - 1 do
        begin
          Pixel := Data.GetPixel(X, Y);
          Pixel.A := Pixel.A div 2;
          Data.SetPixel(X, Y, Pixel);
        end;
      end;
    finally
      Data.Unmap();
    end;
  end;

  --- 3 ---
  function MakePlasm(): TBitmap;
  var
    Data: TBitmapData;
    X, Y: Integer;
    Pixel: TPixelRec;
  begin
    Result := TBitmap.Create();
    Result.SetSize(300, 300);

    Data.Map(Result, TAccessMode.Write, False);
    try
      for Y := 0 to Data.Height - 1 do
      begin
        for X := 0 to Data.Width - 1 do
        begin
          Pixel.R := Byte(Trunc(
            100 + 100 * (Sin(X * Cos(Y * 0.049) * 0.01) + Cos(X * 0.0123 - Y * 0.09))));
          Pixel.G := 0;
          Pixel.B := Byte(Trunc(
            Pixel.R + 100 * (Sin(X * Cos(X * 0.039) * 0.022) + Sin(X * 0.01 - Y * 0.029))));
          Data.SetPixel(X, Y, Pixel);
        end;
      end;
    finally
      Data.Unmap();
    end;
  end;

  --- 4 ---
  function Mix(const A, B: TBitmap): TBitmap;
    function Min(A, B: Integer): Integer;
    begin
      if A < B then Exit(A) else Exit(B);
    end;
  var
    DataA, DataB, DataResult: TBitmapData;
    X, Y: Integer;
    PixelA, PixelB, PixelResult: TPixelRec;
  begin
    Result := TBitmap.Create();
    Result.SetSize(Min(A.Width, B.Width), Min(A.Height, B.Height));
    // this needed for correct Unmap() on exception
    DataA.Init();
    DataB.Init();
    DataResult.Init();
    try
      DataA.Map(A, TAccessMode.Read, False);
      DataB.Map(B, TAccessMode.Read, False);
      DataResult.Map(Result, TAccessMode.Write, False);
      for Y := 0 to DataResult.Height - 1 do
      begin
        for X := 0 to DataResult.Width - 1 do
        begin
          PixelA := DataA.Pixels[X, Y];
          PixelB := DataB.Pixels[X, Y];
          PixelResult.R := (PixelA.R + PixelB.R) div 2;
          PixelResult.G := (PixelA.G + PixelB.G) div 2;
          PixelResult.B := (PixelA.B + PixelB.B) div 2;
          DataResult[X, Y] := PixelResult;
        end;
      end;
    finally
      DataA.Unmap();
      DataB.Unmap();
      DataResult.Unmap();
    end;
  end;
}
{$ENDREGION}

unit BitmapPixels;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}
{$SCOPEDENUMS ON}
{$POINTERMATH ON}
interface

uses
  {$IFNDEF FPC}Windows,{$ENDIF} Classes, SysUtils, Graphics{$IFDEF FPC}, FPImage{$ENDIF};

type
  // $AARRGGBB
  TPixel = Cardinal;
  PPixel = ^TPixel;

  TPixelArray = array [0..High(Integer) div SizeOf(TPixel) - 1] of TPixel;
  PPixelArray = ^TPixelArray;

  TAccessMode = (Read, Write, ReadWrite);

  { TBitmapData }

  TBitmapData = record
  private
    FData: PPixelArray;
    FBitmap: TBitmap;
    FWidth: Integer;
    FHeight: Integer;
    FAccessMode: TAccessMode;
    FHasAlpha: Boolean;
    FDataArray: array of TPixel;// do not use this
  public
    procedure Init();
    procedure Map(const Bitmap: TBitmap; const Mode: TAccessMode; const UseAlpha: Boolean;
      const Background: TColor = clNone);
    procedure Unmap();
    function GetPixel(X, Y: Integer): TPixel; inline;
    procedure SetPixel(X, Y: Integer; AValue: TPixel); inline;
    function GetPixelUnsafe(X, Y: Integer): TPixel; inline;
    procedure SetPixelUnsafe(X, Y: Integer; AValue: TPixel); inline;
    property Data: PPixelArray read FData;
    property HasAlpha: Boolean read FHasAlpha;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Pixels[X, Y: Integer]: TPixel read GetPixel write SetPixel; default;
  end;

  { TPixelRec }

  TPixelRec = packed record
    constructor Create(const R, G, B: Byte; const A: Byte = 255);
    class operator Implicit(Pixel: TPixel): TPixelRec; inline;
    class operator Implicit(Pixel: TPixelRec): TPixel; inline;
  case Byte of
    0: (B, G, R, A: Byte);
    1: (Color: TPixel);
  end;

  TPixelColors = record
  {$REGION 'HTML Colors'}
  const
    AliceBlue = $FFF0F8FF;
    AntiqueWhite = $FFFAEBD7;
    Aqua = $FF00FFFF;
    Aquamarine = $FF7FFFD4;
    Azure = $FFF0FFFF;
    Beige = $FFF5F5DC;
    Bisque = $FFFFE4C4;
    Black = $FF000000;
    BlanchedAlmond = $FFFFEBCD;
    Blue = $FF0000FF;
    BlueViolet = $FF8A2BE2;
    Brown = $FFA52A2A;
    BurlyWood = $FFDEB887;
    CadetBlue = $FF5F9EA0;
    Chartreuse = $FF7FFF00;
    Chocolate = $FFD2691E;
    Coral = $FFFF7F50;
    CornflowerBlue = $FF6495ED;
    Cornsilk = $FFFFF8DC;
    Crimson = $FFDC143C;
    Cyan = $FF00FFFF;
    DarkBlue = $FF00008B;
    DarkCyan = $FF008B8B;
    DarkGoldenrod = $FFB8860B;
    DarkGray = $FFA9A9A9;
    DarkGreen = $FF006400;
    DarkKhaki = $FFBDB76B;
    DarkMagenta = $FF8B008B;
    DarkOliveGreen = $FF556B2F;
    DarkOrange = $FFFF8C00;
    DarkOrchid = $FF9932CC;
    DarkRed = $FF8B0000;
    DarkSalmon = $FFE9967A;
    DarkSeaGreen = $FF8FBC8F;
    DarkSlateBlue = $FF483D8B;
    DarkSlateGray = $FF2F4F4F;
    DarkTurquoise = $FF00CED1;
    DarkViolet = $FF9400D3;
    DeepPink = $FFFF1493;
    DeepSkyBlue = $FF00BFFF;
    DimGray = $FF696969;
    DodgerBlue = $FF1E90FF;
    FireBrick = $FFB22222;
    FloralWhite = $FFFFFAF0;
    ForestGreen = $FF228B22;
    Fuchsia = $FFFF00FF;
    Gainsboro = $FFDCDCDC;
    GhostWhite = $FFF8F8FF;
    Gold = $FFFFD700;
    Goldenrod = $FFDAA520;
    Gray = $FF808080;
    Green = $FF008000;
    GreenYellow = $FFADFF2F;
    Honeydew = $FFF0FFF0;
    HotPink = $FFFF69B4;
    IndianRed = $FFCD5C5C;
    Indigo = $FF4B0082;
    Ivory = $FFFFFFF0;
    Khaki = $FFF0E68C;
    Lavender = $FFE6E6FA;
    LavenderBlush = $FFFFF0F5;
    LawnGreen = $FF7CFC00;
    LemonChiffon = $FFFFFACD;
    LightBlue = $FFADD8E6;
    LightCoral = $FFF08080;
    LightCyan = $FFE0FFFF;
    LightGoldenrodYellow = $FFFAFAD2;
    LightGreen = $FF90EE90;
    LightGrey = $FFD3D3D3;
    LightPink = $FFFFB6C1;
    LightSalmon = $FFFFA07A;
    LightSeaGreen = $FF20B2AA;
    LightSkyBlue = $FF87CEFA;
    LightSlateGray = $FF778899;
    LightSteelBlue = $FFB0C4DE;
    LightYellow = $FFFFFFE0;
    Lime = $FF00FF00;
    LimeGreen = $FF32CD32;
    Linen = $FFFAF0E6;
    Magenta = $FFFF00FF;
    Maroon = $FF800000;
    MediumAquamarine = $FF66CDAA;
    MediumBlue = $FF0000CD;
    MediumOrchid = $FFBA55D3;
    MediumPurple = $FF9370DB;
    MediumSeaGreen = $FF3CB371;
    MediumSlateBlue = $FF7B68EE;
    MediumSpringGreen = $FF00FA9A;
    MediumTurquoise = $FF48D1CC;
    MediumVioletRed = $FFC71585;
    MidnightBlue = $FF191970;
    MintCream = $FFF5FFFA;
    MistyRose = $FFFFE4E1;
    Moccasin = $FFFFE4B5;
    NavajoWhite = $FFFFDEAD;
    Navy = $FF000080;
    OldLace = $FFFDF5E6;
    Olive = $FF808000;
    OliveDrab = $FF6B8E23;
    Orange = $FFFFA500;
    OrangeRed = $FFFF4500;
    Orchid = $FFDA70D6;
    PaleGoldenrod = $FFEEE8AA;
    PaleGreen = $FF98FB98;
    PaleTurquoise = $FFAFEEEE;
    PaleVioletRed = $FFDB7093;
    PapayaWhip = $FFFFEFD5;
    PeachPuff = $FFFFDAB9;
    Peru = $FFCD853F;
    Pink = $FFFFC0CB;
    Plum = $FFDDA0DD;
    PowderBlue = $FFB0E0E6;
    Purple = $FF800080;
    Red = $FFFF0000;
    RosyBrown = $FFBC8F8F;
    RoyalBlue = $FF4169E1;
    SaddleBrown = $FF8B4513;
    Salmon = $FFFA8072;
    SandyBrown = $FFF4A460;
    SeaGreen = $FF2E8B57;
    Seashell = $FFFFF5EE;
    Sienna = $FFA0522D;
    Silver = $FFC0C0C0;
    SkyBlue = $FF87CEEB;
    SlateBlue = $FF6A5ACD;
    SlateGray = $FF708090;
    Snow = $FFFFFAFA;
    SpringGreen = $FF00FF7F;
    SteelBlue = $FF4682B4;
    Tan = $FFD2B48C;
    Teal = $FF008080;
    Thistle = $FFD8BFD8;
    Tomato = $FFFF6347;
    Turquoise = $FF40E0D0;
    Violet = $FFEE82EE;
    Wheat = $FFF5DEB3;
    White = $FFFFFFFF;
    WhiteSmoke = $FFF5F5F5;
    Yellow = $FFFFFF00;
    YellowGreen = $FF9ACD32;
    {$ENDREGION}
  end;

  function MakePixel(const R, G, B: Byte; const A: Byte = 255): TPixel; inline;
  function PixelGetA(const Pixel: TPixel): Byte; inline;
  function PixelGetR(const Pixel: TPixel): Byte; inline;
  function PixelGetG(const Pixel: TPixel): Byte; inline;
  function PixelGetB(const Pixel: TPixel): Byte; inline;
  {$IFDEF FPC}
  function FPColorToPixel(const FPColor: TFPColor): TPixel; inline;
  function PixelToFPColor(const Pixel: TPixel): TFPColor; inline;
  {$ENDIF}
  function ColorToPixel(const Color: TColor): TPixel; inline;
  function PixelToColor(const Pixel: TPixel): TColor; inline;

implementation

{$IFDEF FPC}
uses
  IntfGraphics, GraphType, LCLType, LCLIntf;
{$ENDIF}

function MakePixel(const R, G, B: Byte; const A: Byte): TPixel; inline;
begin
  Result := B or (G shl 8) or (R shl 16) or (A shl 24);
end;

function PixelGetA(const Pixel: TPixel): Byte; inline;
begin
  Result := (Pixel shr 24) and $FF;
end;

function PixelGetR(const Pixel: TPixel): Byte; inline;
begin
  Result := (Pixel shr 16) and $FF;
end;

function PixelGetG(const Pixel: TPixel): Byte; inline;
begin
  Result := (Pixel shr 8) and $FF;
end;

function PixelGetB(const Pixel: TPixel): Byte; inline;
begin
  Result := Pixel and $FF;
end;

{$IFDEF FPC}
function FPColorToPixel(const FPColor: TFPColor): TPixel; inline;
begin
  Result:=
    ((FPColor.Blue shr 8) and $ff) or
    (FPColor.Green and $ff00) or
    ((FPColor.Red shl 8) and $ff0000) or
    ((FPColor.Alpha shl 16) and $ff000000);
end;

function PixelToFPColor(const Pixel: TPixel): TFPColor; inline;
begin
  Result.Red := (Pixel and $ff0000) shr 8;
  Result.Red := Result.Red + (Result.Red shr 8);
  Result.Green := (Pixel and $ff00);
  Result.Green := Result.Green + (Result.Green shr 8);
  Result.Blue := (Pixel and $ff);
  Result.Blue := Result.Blue + (Result.Blue shl 8);
  Result.Alpha := (Pixel and $ff000000) shr 16;
  Result.Alpha := Result.Alpha + (Result.Alpha shr 8);
end;
{$ENDIF}

function ColorToPixel(const Color: TColor): TPixel; inline;
begin
  Result:=
    (Color and $0000FF00) or
    ((Color shr 16) and $000000FF) or
    ((Color shl 16) and $00FF0000) or
    $FF000000;
end;

function PixelToColor(const Pixel: TPixel): TColor; inline;
begin
  Result:=
    (Pixel and $0000FF00) or
    ((Pixel shr 16) and $000000FF) or
    ((Pixel shl 16) and $00FF0000);
end;

function SwapRedBlueChanel(const Pixel: TPixel): TPixel; inline;
begin
  Result:=
    (Pixel and $FF00FF00) or
    ((Pixel shr 16) and $000000FF) or
    ((Pixel shl 16) and $00FF0000);
end;

procedure BlendData(var BitmapData: TBitmapData; const Background: TColor);
var
  I: Integer;
  R, G, B, A: Byte;
  DestR, DestG, DestB: Byte;
  C: TPixel;
begin
  DestR := Background and $FF;
  DestG := (Background shr 8) and $FF;
  DestB := (Background shr 16) and $FF;

  for I := 0 to BitmapData.FWidth * BitmapData.FHeight - 1 do
  begin
    C := BitmapData.FData[I];
    // read
    B := C and $FF;
    G := (C shr 8) and $FF;
    R := (C shr 16) and $FF;
    A := (C shr 24) and $FF;
    // blend
    B := ((B * A) + (DestB * (255 - A))) div 255;
    G := ((G * A) + (DestG * (255 - A))) div 255;
    R := ((R * A) + (DestR * (255 - A))) div 255;
    // write
    BitmapData.FData[I] := B or ((G shl 8) and $0000FF00) or ((R shl 16) and $00FF0000);
  end;
end;

{$IFDEF FPC}
// FPC ACCESS
procedure ReadData(var BitmapData: TBitmapData);
var
  IntfImage: TLazIntfImage;
  X, Y, Position: Integer;
begin
  IntfImage := BitmapData.FBitmap.CreateIntfImage();
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := FPColorToPixel(IntfImage.Colors[X, Y]);
        Inc(Position, 1);
      end;
    end;
  finally
    IntfImage.Free();
  end;
end;

{function MakeNativeGtk2RawImageDescription(const Width, Height: Integer): TRawImageDescription;
begin
  Result.Init;
  Result.Format := ricfRGBA;
  Result.Width := Width;
  Result.Height := Height;
  Result.Depth := 32;
  Result.BitOrder := riboBitsInOrder;
  Result.ByteOrder := riboLSBFirst;
  Result.LineOrder := riloTopToBottom;
  Result.LineEnd := rileDWordBoundary;
  Result.BitsPerPixel := 32;
  Result.RedPrec := 8;
  Result.RedShift := 0;
  Result.GreenPrec := 8;
  Result.GreenShift := 8;
  Result.BluePrec := 8;
  Result.BlueShift := 16;
  Result.AlphaPrec := 8;
  Result.AlphaShift := 24;
  Result.MaskBitsPerPixel := 0;
  Result.MaskShift := 0;
  Result.MaskLineEnd := rileByteBoundary;
  Result.MaskBitOrder := riboBitsInOrder;
  Result.PaletteColorCount := 0;
  Result.PaletteBitsPerIndex := 0;
  Result.PaletteShift := 0;
  Result.PaletteLineEnd := rileTight;
  Result.PaletteBitOrder := riboBitsInOrder;
  Result.PaletteByteOrder := riboLSBFirst;
end;}

{$IF DEFINED(LCLGTK2) OR DEFINED(WINDOWS)}
procedure WriteData(var BitmapData: TBitmapData);
var
  Position: Integer;
  RawImage: TRawImage;
begin
  if BitmapData.FHasAlpha then
  begin
    RawImage.Init();
    RawImage.Description.Init_BPP32_B8G8R8A8_BIO_TTB(BitmapData.FWidth, BitmapData.FHeight);
    RawImage.Data := PByte(@(BitmapData.FData[0]));
    RawImage.DataSize := BitmapData.FWidth * BitmapData.FHeight * SizeOf(TPixel);
    BitmapData.FBitmap.LoadFromRawImage(RawImage, False);
  end else
  begin
    RawImage.Init();
    RawImage.Description.Init_BPP32_B8G8R8_BIO_TTB(BitmapData.FWidth, BitmapData.FHeight);
    RawImage.DataSize := BitmapData.FWidth * BitmapData.FHeight * SizeOf(TPixel);
    RawImage.CreateData(False);
    try
      for Position := 0 to BitmapData.FWidth * BitmapData.FHeight - 1 do
      begin
        PPixel(RawImage.Data)[Position] := BitmapData.Data[Position] and $00FFFFFF;
      end;
      BitmapData.FBitmap.LoadFromRawImage(RawImage, False);
    finally
      RawImage.FreeData();
    end;
  end;
end;
{$ELSE}
procedure WriteData(var BitmapData: TBitmapData);
var
  IntfImage: TLazIntfImage;
  X, Y, Position: Integer;
  //RawImage: TRawImage;
begin
  if BitmapData.FHasAlpha then
    IntfImage := TLazIntfImage.Create(BitmapData.FWidth, BitmapData.FHeight, [riqfRGB, riqfAlpha])
  else
    IntfImage := TLazIntfImage.Create(BitmapData.FWidth, BitmapData.FHeight, [riqfRGB]);
  try
    IntfImage.CreateData();
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        IntfImage.Colors[X, Y] := PixelToFPColor(BitmapData.FData[Position]);
        Inc(Position, 1);
      end;
    end;
    BitmapData.FBitmap.LoadFromIntfImage(IntfImage);
    // IntfImage.GetRawImage(RawImage, True);
    // BitmapData.FBitmap.LoadFromRawImage(RawImage, True);
  finally
    IntfImage.Free();
  end;
end;
{$ENDIF}

procedure ReadDataRGB(var BitmapData: TBitmapData);
var
  pSrc: PByte;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := PByte(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := (pSrc[0] shl 16) or (pSrc[1] shl 8) or pSrc[2];
        Inc(Position, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataRGBOpaque(var BitmapData: TBitmapData);
var
  pSrc: PByte;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := PByte(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := (pSrc[0] shl 16) or (pSrc[1] shl 8) or pSrc[2] or $FF000000;
        Inc(Position, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataBGR(var BitmapData: TBitmapData);
var
  pSrc: PByte;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := PByte(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := pSrc[0] or (pSrc[1] shl 8) or (pSrc[2] shl 16);
        Inc(Position, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataBGROpaque(var BitmapData: TBitmapData);
var
  pSrc: PByte;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := PByte(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := pSrc[0] or (pSrc[1] shl 8) or (pSrc[2] shl 16) or $FF000000;
        Inc(Position, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataBGRA(var BitmapData: TBitmapData);// fast
var
  Y: Integer;
  pSrc, pDst: PPixel;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      pDst := @(BitmapData.FData[BitmapData.FWidth * Y]);
      Move(pSrc^, pDst^, BitmapData.FWidth * SizeOf(TPixel));
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataBGRN(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := Scanline[X];
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataBGRNOpaque(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := Scanline[X] or $FF000000;
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataRGBA(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        BitmapData.FData[Position] := SwapRedBlueChanel(Scanline[X]);
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataRGBN(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  Pixel: TPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        Pixel := Scanline[X];
        BitmapData.FData[Position] :=
          ((Pixel shr 16) and $000000FF) or
          (Pixel and $0000FF00) or
          ((Pixel shl 16) and $00FF0000);
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure ReadDataRGBNOpaque(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  Pixel: TPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        Pixel := Scanline[X];
        BitmapData.FData[Position] :=
          ((Pixel shr 16) and $000000FF) or
          (Pixel and $0000FF00) or
          ((Pixel shl 16) and $00FF0000) or
          $FF000000;
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure WriteDataRGB(var BitmapData: TBitmapData);
var
  pSrc: PByte;
  C: TPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := PByte(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        C := BitmapData.FData[Position];
        pSrc[0] := (C shr 16) and $FF;
        pSrc[1] := (C shr 8) and $FF;
        pSrc[2] := C and $FF;
        Inc(Position, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure WriteDataBGR(var BitmapData: TBitmapData);
var
  pSrc: PByte;
  C: TPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := PByte(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        C := BitmapData.FData[Position];
        pSrc[0] := C and $FF;
        pSrc[1] := (C shr 8) and $FF;
        pSrc[2] := (C shr 16) and $FF;
        Inc(Position, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure WriteDataBGRA(var BitmapData: TBitmapData);// fast
var
  Y: Integer;
  pSrc, pDst: PPixel;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pDst := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      pSrc := @(BitmapData.FData[BitmapData.FWidth * Y]);
      Move(pSrc^, pDst^, BitmapData.FWidth * SizeOf(TPixel));
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure WriteDataRGBA(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        Scanline[X] := SwapRedBlueChanel(BitmapData.FData[Position]);
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure WriteDataRGBN(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  Pixel: TPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        Pixel := BitmapData.FData[Position];
        Scanline[X] :=
          ((Pixel shr 16) and $000000FF) or
          (Pixel and $0000FF00) or
          ((Pixel shl 16) and $00FF0000);
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

procedure WriteDataBGRN(var BitmapData: TBitmapData);
var
  Scanline: PPixel;
  X, Y, Position: Integer;
begin
  BitmapData.FBitmap.BeginUpdate(False);
  try
    Position := 0;
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      Scanline := PPixel(BitmapData.FBitmap.RawImage.GetLineStart(Y));
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        Scanline[X] := BitmapData.FData[Position] and $00FFFFFF;
        Inc(Position, 1);
      end;
    end;
  finally
    BitmapData.FBitmap.EndUpdate(False);
  end;
end;

type
  TDescriptionType = (DeskBGR, DeskRGB, DeskBGRA, DeskRGBA, DeskBGRN, DeskRGBN, DeskOther);

function CalcDescriptionType(const Description: TRawImageDescription; const IsReadOnly: Boolean = False): TDescriptionType;
begin
  Result := TDescriptionType.DeskOther;
  if Description.Format <> ricfRGBA then Exit;
  if Description.ByteOrder <> riboLSBFirst then Exit;
  if Description.PaletteColorCount <> 0 then Exit;
  // if Description.BitOrder <> riboBitsInOrder then Exit; // it doesn't matter without a mask

  // ??? I think it makes no difference to us whether there is a mask or not
  {$IFDEF LCLGTK2}
  // LCLGTK2 image width workaround
  // ex: width = 16 - ok, width = 15 bug
  if (not IsReadOnly) and (Description.MaskBitsPerPixel <> 0) then
    if Description.MaskLineEnd = rileByteBoundary then Exit;
  {$ENDIF}

  if Description.BitsPerPixel = 32 then
  begin
    if Description.Depth = 32 then
    begin
      // prec
      if Description.RedPrec <> 8 then Exit;
      if Description.GreenPrec <> 8 then Exit;
      if Description.BluePrec <> 8 then Exit;
      if Description.AlphaPrec <> 8 then Exit;
      // A and G
      if Description.AlphaShift <> 24 then Exit;
      if Description.GreenShift <> 8 then Exit;
      // DeskBGRA or DeskRGBA
      if (Description.RedShift = 16) and (Description.BlueShift = 0) then
        Result := TDescriptionType.DeskBGRA
      else if (Description.RedShift = 0) and (Description.BlueShift = 16) then
        Result := TDescriptionType.DeskRGBA
      else
        Result := TDescriptionType.DeskOther;
    end
    else if Description.Depth = 24 then
    begin
      // prec
      if Description.RedPrec <> 8 then Exit;
      if Description.GreenPrec <> 8 then Exit;
      if Description.BluePrec <> 8 then Exit;
      // G
      if Description.GreenShift <> 8 then Exit;
      // DeskBGRN or DeskRGBN
      if (Description.RedShift = 16) and (Description.BlueShift = 0) then
        Result := TDescriptionType.DeskBGRN
      else if (Description.RedShift = 0) and (Description.BlueShift = 16) then
        Result := TDescriptionType.DeskRGBN
      else
        Result := TDescriptionType.DeskOther;
    end;
  end
  else if Description.BitsPerPixel = 24 then
  begin
    if Description.Depth <> 24 then Exit;
    // prec
    if Description.RedPrec <> 8 then Exit;
    if Description.GreenPrec <> 8 then Exit;
    if Description.BluePrec <> 8 then Exit;
    // G
    if Description.GreenShift <> 8 then Exit;
    // DeskBGR or DeskRGB
    if (Description.RedShift = 16) and (Description.BlueShift = 0) then
      Result := TDescriptionType.DeskBGR
    else if (Description.RedShift = 0) and (Description.BlueShift = 16) then
      Result := TDescriptionType.DeskRGB
    else
      Result := TDescriptionType.DeskOther;
  end else
    Result := TDescriptionType.DeskOther;
end;

procedure BitmapDataMap(out BitmapData: TBitmapData; const Bitmap: TBitmap; const Mode: TAccessMode;
  const UseAlpha: Boolean; const Background: TColor);
begin
  BitmapData.FBitmap := Bitmap;
  BitmapData.FAccessMode := Mode;
  BitmapData.FHasAlpha := UseAlpha;
  BitmapData.FWidth := Bitmap.Width;
  BitmapData.FHeight := Bitmap.Height;

  SetLength(BitmapData.FDataArray, BitmapData.FHeight * BitmapData.FWidth);
  if Length(BitmapData.FDataArray) > 0 then
    BitmapData.FData := @(BitmapData.FDataArray[0])
  else
    BitmapData.FData := nil;

  if (BitmapData.FData <> nil) and (BitmapData.FAccessMode in [TAccessMode.ReadWrite, TAccessMode.Read]) then
  begin
    case CalcDescriptionType(BitmapData.FBitmap.RawImage.Description, True) of
    TDescriptionType.DeskRGB:
      if BitmapData.FHasAlpha then
        ReadDataRGBOpaque(BitmapData)
      else
        ReadDataRGB(BitmapData);

    TDescriptionType.DeskBGR:
      if BitmapData.FHasAlpha then
        ReadDataBGROpaque(BitmapData)
      else
        ReadDataBGR(BitmapData);

    TDescriptionType.DeskRGBA:
      if BitmapData.FHasAlpha then
        ReadDataRGBA(BitmapData)
      else
      begin
        if Background <> clNone then
        begin
          ReadDataRGBA(BitmapData);
          BlendData(BitmapData, Background);
        end else
          ReadDataRGBN(BitmapData);
      end;

    TDescriptionType.DeskBGRA:
      if BitmapData.FHasAlpha then
        ReadDataBGRA(BitmapData)
      else
      begin
        if Background <> clNone then
        begin
          ReadDataBGRA(BitmapData);
          BlendData(BitmapData, Background);
        end else
          ReadDataBGRN(BitmapData);
      end;

    TDescriptionType.DeskRGBN:
      if BitmapData.FHasAlpha then
        ReadDataRGBNOpaque(BitmapData)
      else
        ReadDataRGBN(BitmapData);

    TDescriptionType.DeskBGRN:
      if BitmapData.FHasAlpha then
        ReadDataBGRNOpaque(BitmapData)
      else
        ReadDataBGRN(BitmapData);

    TDescriptionType.DeskOther:
      ReadData(BitmapData);
    end;
  end;
end;

procedure BitmapDataUnmap(var BitmapData: TBitmapData);
begin
  try
    if (BitmapData.FData <> nil) and (BitmapData.FAccessMode in [TAccessMode.ReadWrite, TAccessMode.Write]) then
    begin
      if BitmapData.FHasAlpha then
        BitmapData.FBitmap.PixelFormat := pf32bit
      else
        BitmapData.FBitmap.PixelFormat := pf24bit;

      case CalcDescriptionType(BitmapData.FBitmap.RawImage.Description) of
      TDescriptionType.DeskRGB:
        WriteDataRGB(BitmapData);

      TDescriptionType.DeskBGR:
        WriteDataBGR(BitmapData);

      TDescriptionType.DeskRGBA:
        WriteDataRGBA(BitmapData);

      TDescriptionType.DeskBGRA:
        WriteDataBGRA(BitmapData);

      TDescriptionType.DeskRGBN:
        WriteDataRGBN(BitmapData);

      TDescriptionType.DeskBGRN:
        WriteDataBGRN(BitmapData);

      TDescriptionType.DeskOther:
        WriteData(BitmapData);
      end;
    end;
  finally
    Finalize(BitmapData.FDataArray);
  end;
end;

{$ELSE}
// DELPHI VCL ACCESS

procedure ReadData(var BitmapData: TBitmapData);
var
  TempBitmap: TBitmap;
  X, Y: Integer;
  pDst: PPixel;
  pSrc: PByte;
begin
  TempBitmap := TBitmap.Create();
  try
    TempBitmap.Assign(BitmapData.FBitmap);
    TempBitmap.PixelFormat := pf24bit;

    pDst := @(BitmapData.FData[0]);
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := TempBitmap.ScanLine[Y];
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        pDst^ := pSrc[0] or (pSrc[1] shl 8) or (pSrc[2] shl 16);
        Inc(pDst, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    TempBitmap.Free;
  end;
end;

procedure ReadDataOpaque(var BitmapData: TBitmapData);
var
  TempBitmap: TBitmap;
  X, Y: Integer;
  pDst: PPixel;
  pSrc: PByte;
begin
  TempBitmap := TBitmap.Create();
  try
    TempBitmap.Assign(BitmapData.FBitmap);
    TempBitmap.PixelFormat := pf24bit;

    pDst := @(BitmapData.FData[0]);
    for Y := 0 to BitmapData.FHeight - 1 do
    begin
      pSrc := TempBitmap.ScanLine[Y];
      for X := 0 to BitmapData.FWidth - 1 do
      begin
        pDst^ := pSrc[0] or (pSrc[1] shl 8) or (pSrc[2] shl 16) or $FF000000;
        Inc(pDst, 1);
        Inc(pSrc, 3);
      end;
    end;
  finally
    TempBitmap.Free;
  end;
end;

procedure ReadDataBGR(var BitmapData: TBitmapData);
var
  X, Y: Integer;
  pDst: PPixel;
  pSrc: PByte;
begin
  pDst := @(BitmapData.FData[0]);
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pSrc := BitmapData.FBitmap.ScanLine[Y];
    for X := 0 to BitmapData.FWidth - 1 do
    begin
      pDst^ := pSrc[0] or (pSrc[1] shl 8) or (pSrc[2] shl 16);
      Inc(pDst, 1);
      Inc(pSrc, 3);
    end;
  end;
end;

procedure ReadDataBGROpaque(var BitmapData: TBitmapData);
var
  X, Y: Integer;
  pDst: PPixel;
  pSrc: PByte;
begin
  pDst := @(BitmapData.FData[0]);
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pSrc := BitmapData.FBitmap.ScanLine[Y];
    for X := 0 to BitmapData.FWidth - 1 do
    begin
      pDst^ := pSrc[0] or (pSrc[1] shl 8) or (pSrc[2] shl 16) or $FF000000;
      Inc(pDst, 1);
      Inc(pSrc, 3);
    end;
  end;
end;

procedure ReadDataBGRA(var BitmapData: TBitmapData);// fast
var
  Y: Integer;
  pDst: PPixel;
  pSrc: PPixel;
begin
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pSrc := BitmapData.FBitmap.ScanLine[Y];
    pDst := @(BitmapData.FData[BitmapData.FWidth * Y]);
    Move(pSrc^, pDst^, BitmapData.FWidth * SizeOf(TPixel));
  end;
end;

procedure ReadDataPremultipliedBGRA(var BitmapData: TBitmapData);// slow
var
  X, Y: Integer;
  pDst: PPixel;
  pSrc: PPixel;
  Pixel: TPixelRec;
begin
  pDst := @(BitmapData.FData[0]);
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pSrc := BitmapData.FBitmap.ScanLine[Y];
    for X := 0 to BitmapData.FWidth - 1 do
    begin
      Pixel := pSrc^;
      if Pixel.A = 0 then
      begin
        Pixel.Color := $00000000;
      end else
      begin
        Pixel.R := MulDiv(Pixel.R, 255, Pixel.A);
        Pixel.G := MulDiv(Pixel.G, 255, Pixel.A);
        Pixel.B := MulDiv(Pixel.B, 255, Pixel.A);
      end;
      pDst^ := Pixel;
      Inc(pDst, 1);
      Inc(pSrc, 1);
    end;
  end;
end;

procedure ReadDataBGRN(var BitmapData: TBitmapData);
var
  X, Y: Integer;
  pDst: PPixel;
  pSrc: PPixel;
begin
  pDst := @(BitmapData.FData[0]);
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pSrc := BitmapData.FBitmap.ScanLine[Y];
    for X := 0 to BitmapData.FWidth - 1 do
    begin
      pDst^ := pSrc^ and $00FFFFFF;
      Inc(pDst, 1);
      Inc(pSrc, 1);
    end;
  end;
end;

procedure WriteDataBGRA(var BitmapData: TBitmapData);// fast
var
  Y: Integer;
  pDst: PPixel;
  pSrc: PPixel;
begin
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pSrc := @(BitmapData.FData[BitmapData.FWidth * Y]);
    pDst := BitmapData.FBitmap.ScanLine[Y];
    Move(pSrc^, pDst^, BitmapData.FWidth * SizeOf(TPixel));
  end;
end;

procedure WriteDataPremultipliedBGRA(var BitmapData: TBitmapData);// slow
var
  X, Y: Integer;
  pDst: PPixel;
  pSrc: PPixel;
  Pixel: TPixelRec;
begin
  pSrc := @(BitmapData.FData[0]);
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pDst := BitmapData.FBitmap.ScanLine[Y];
    for X := 0 to BitmapData.FWidth - 1 do
    begin
      Pixel := pSrc^;
      Pixel.R := MulDiv(Pixel.R, Pixel.A, 255);
      Pixel.G := MulDiv(Pixel.G, Pixel.A, 255);
      Pixel.B := MulDiv(Pixel.B, Pixel.A, 255);
      pDst^ := Pixel;
      Inc(pDst, 1);
      Inc(pSrc, 1);
    end;
  end;
end;

procedure WriteDataBGR(var BitmapData: TBitmapData);
var
  X, Y: Integer;
  pDst: PByte;
  pSrc: PPixel;
begin
  pSrc := @(BitmapData.FData[0]);
  for Y := 0 to BitmapData.FHeight - 1 do
  begin
    pDst := BitmapData.FBitmap.ScanLine[Y];
    for X := 0 to BitmapData.FWidth - 1 do
    begin
      pDst[0] := pSrc^ and $FF;
      pDst[1] := (pSrc^ shr 8) and $FF;
      pDst[2] := (pSrc^ shr 16) and $FF;
      Inc(pDst, 3);
      Inc(pSrc, 1);
    end;
  end;
end;

procedure BitmapDataMap(out BitmapData: TBitmapData; const Bitmap: TBitmap; const Mode: TAccessMode;
  const UseAlpha: Boolean; const Background: TColor);
begin
  BitmapData.FBitmap := Bitmap;
  BitmapData.FAccessMode := Mode;
  BitmapData.FHasAlpha := UseAlpha;
  BitmapData.FWidth := Bitmap.Width;
  BitmapData.FHeight := Bitmap.Height;

  SetLength(BitmapData.FDataArray, BitmapData.FHeight * BitmapData.FWidth);
  if Length(BitmapData.FDataArray) > 0 then
    BitmapData.FData := @(BitmapData.FDataArray[0])
  else
    BitmapData.FData := nil;

  if (BitmapData.FData <> nil) and (BitmapData.FAccessMode in [TAccessMode.ReadWrite, TAccessMode.Read]) then
  begin
    case BitmapData.FBitmap.PixelFormat of
    pfDevice,
    pf1bit,
    pf4bit,
    pf8bit,
    pf15bit,
    pf16bit,
    pfCustom:
      if BitmapData.FHasAlpha then
        ReadDataOpaque(BitmapData)
      else
        ReadData(BitmapData);

    pf24bit:
      if BitmapData.FHasAlpha then
        ReadDataBGROpaque(BitmapData)
      else
        ReadDataBGR(BitmapData);

    pf32bit:
      if BitmapData.FHasAlpha then
      begin
        if BitmapData.FBitmap.AlphaFormat = afIgnored then
          ReadDataBGRA(BitmapData)
        else
          ReadDataPremultipliedBGRA(BitmapData);
      end
      else
        if Background <> clNone then
        begin
          if BitmapData.FBitmap.AlphaFormat = afIgnored then
            ReadDataBGRA(BitmapData)
          else
            ReadDataPremultipliedBGRA(BitmapData);
          BlendData(BitmapData, Background);
        end else
          ReadDataBGRN(BitmapData);
    end;
  end;
end;

type
  TOpenBitmap = class(TBitmap);

procedure BitmapDataUnmap(var BitmapData: TBitmapData);
begin
  try
    if (BitmapData.FData <> nil) and (BitmapData.FAccessMode in [TAccessMode.ReadWrite, TAccessMode.Write]) then
    begin
      if BitmapData.FHasAlpha then
      begin
        if (BitmapData.FBitmap.PixelFormat = pf32bit) and (BitmapData.FBitmap.AlphaFormat = afIgnored) then
        begin
          WriteDataBGRA(BitmapData);// fast way
        end else
        begin
          BitmapData.FBitmap.PixelFormat := pf32bit;
          TOpenBitmap(BitmapData.FBitmap).FAlphaFormat := afPremultiplied;
          WriteDataPremultipliedBGRA(BitmapData);
        end;
      end else
      begin
        BitmapData.FBitmap.PixelFormat := pf24bit;
        WriteDataBGR(BitmapData);
      end;

      BitmapData.FBitmap.Modified := True;
    end;
  finally
    Finalize(BitmapData.FDataArray);
  end;
end;
{$ENDIF}

{ TPixelRec }

constructor TPixelRec.Create(const R, G, B: Byte; const A: Byte);
begin
  Self.Color := B or (G shl 8) or (R shl 16) or (A shl 24);
end;

class operator TPixelRec.Implicit(Pixel: TPixel): TPixelRec;
begin
  Result.Color := Pixel;
end;

class operator TPixelRec.Implicit(Pixel: TPixelRec): TPixel;
begin
  Result := Pixel.Color;
end;

{ TBitmapData }

function TBitmapData.GetPixel(X, Y: Integer): TPixel;
begin
  if (X < 0) or (X >= Self.Width) or (Y < 0) or (Y >= Self.Height) then Exit(0);
  Result := Self.Data[Y * Self.Width + X];
end;

procedure TBitmapData.SetPixel(X, Y: Integer; AValue: TPixel);
begin
  if (X < 0) or (X >= Self.Width) or (Y < 0) or (Y >= Self.Height) then Exit;
  Self.Data[Y * Self.Width + X] := AValue;
end;

function TBitmapData.GetPixelUnsafe(X, Y: Integer): TPixel;
begin
  Result := Self.Data[Y * Self.Width + X];
end;

procedure TBitmapData.SetPixelUnsafe(X, Y: Integer; AValue: TPixel);
begin
  Self.Data[Y * Self.Width + X] := AValue;
end;

procedure TBitmapData.Init();
begin
  Self := Default(TBitmapData);
end;

procedure TBitmapData.Map(const Bitmap: TBitmap; const Mode: TAccessMode; const UseAlpha: Boolean;
      const Background: TColor = clNone);
begin
  BitmapDataMap(Self, Bitmap, Mode, UseAlpha, Background);
end;

procedure TBitmapData.Unmap();
begin
  BitmapDataUnmap(Self);
end;

end.

