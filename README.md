# BitmapPixels
## [ENG] <img src="https://upload.wikimedia.org/wikipedia/commons/a/ae/Flag_of_the_United_Kingdom.svg" height="11px"/>
### BitmapPixels.pas  - Lazarus and Delphi module for direct access to pixels at TBitmap
#### Worked on Windows(WinApi), Linux(GTK2, Qt5), OSX(Cocoa)

Quite a popular question is how to get quick access to **TBitmap** pixels?  
It is easy to do in **Delphi**, with **Scanline[]** property, due to the limited number of pixel formats, but rather difficult in **Lazarus**.   
For example: https://wiki.freepascal.org/Fast_direct_pixel_access  

I propose a small, single file, module **"BitmapPixels.pas"** that simplify work to just calling **TBitmapData.Map()** and **TBitmapData.Unmap()**.  
You get an array of **$AARRGGBB** pixels in the **Data** property, and abilty set and get color of pixels using **SetPixel()/GetPixel()**.  

```delphi
var
  Data: TBitmapData;
  X, Y: Integer;
  Pixel: TPixelRec;// for easy access to the channels 
begin
  // Reading the colors of the image into map "Data", width mode "ReadWrite", in the "False" alpha channel mode.
  // The alpha channel will be set to 0 on every element of the array. ($00RRGGBB, $00RRGGBB, ...) 
  Data.Map(Bitmap, TAccessMode.ReadWrite, False);
  try
    for Y := 0 to Data.Height - 1 do
    begin
      for X := 0 to Data.Width - 1 do
      begin
        // Read color at (X, Y) to Pixel record
        Pixel := Data.GetPixel(X, Y);
        // some changes of Pixel
        Pixel.R := (Pixel.R + Pixel.G + Pixel.B) div 3;
        Pixel.G := Pixel.R;
        Pixel.B := Pixel.R;
        // ...
        // Write Pixel record to (X, Y) in map
        Data.SetPixel(X, Y, Pixel);
      end;
    end;
  finally
    // Writing the map to the image.
    // Since we have abandoned Alpha, the pixel format will be set to pf24bit.
    Data.Unmap();
  end;
end;
```

**Key Features:**
- cross-platform 
- supports all TBitmap pixel formats for reading 
- fast processing of popular formats in Windows/GTK/Qt/OSX 
- can map any image as having an alpha channel or not (24bit/32bit)


#### Example 1 - Invert colors (read and write)
![example1.png](examples/example1.png)
```delphi
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
```
#### Example 2 - Half bitmap transparency (read and write, alpha)
![example2.png](examples/example2.png)
```delphi
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
```
#### Example 3 - Make a plasm effect on bitmap (write only)
![example3.png](examples/example3.png)
```delphi
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
```
#### Example 4 - Mix two bitmaps to one bitmap (read only, write only)
![example4.png](examples/example4.png)
```delphi
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
```

---
## [RUS] <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/White-blue-white_flag.svg/375px-White-blue-white_flag.svg.png" height="11px"/>
### BitmapPixels.pas  - Модуль для Lazarus и Delphi дающий прямой доступ к пикселам TBitmap.
#### Работает на Windows(WinApi), Linux(GTK2, Qt5), OSX(Cocoa)

Есть довольно популярный, в сообществе Lazarus разработчиков, вопрос: Как получить быстрый доступ к пикселам **TBitmap**?  
Это легко сделать в **Delphi** благодаря свойству **Scanline[]** из-за довольно ограниченного количества возможных форматов пикселей, но довольно сложно в **Lazarus**.  
Примеры сложностей, которые могут возникнуть: https://wiki.freepascal.org/Fast_direct_pixel_access. 

Я предлагаю небольшой, в виде одного файла, модуль **"BitmapPixels.pas"**, который упрощает работу до простого вызова **TBitmapData.Map()** и **TBitmapData.Unmap()**.  
Вы получаете массив пикселей в формате **$AARRGGBB** в свойстве **Data**, а также возможность установить и получить цвет пикселей с помощью **SetPixel()/GetPixel()**. 

```delphi
var
  Data: TBitmapData;
  X, Y: Integer;
  Pixel: TPixelRec;// for easy access to the channels 
begin
  // Reading the colors of the image into map "Data", width mode "ReadWrite", in the "False" alpha channel mode.
  // The alpha channel will be set to 0 on every element of the array. ($00RRGGBB, $00RRGGBB, ...) 
  Data.Map(Bitmap, TAccessMode.ReadWrite, False);
  try
    for Y := 0 to Data.Height - 1 do
    begin
      for X := 0 to Data.Width - 1 do
      begin
        // Read color at (X, Y) to Pixel record
        Pixel := Data.GetPixel(X, Y);
        // some changes of Pixel
        Pixel.R := (Pixel.R + Pixel.G + Pixel.B) div 3;
        Pixel.G := Pixel.R;
        Pixel.B := Pixel.R;
        // ...
        // Write Pixel record to (X, Y) in map
        Data.SetPixel(X, Y, Pixel);
      end;
    end;
  finally
    // Writing the map to the image.
    // Since we have abandoned Alpha, the pixel format will be set to pf24bit.
    Data.Unmap();
  end;
end;
```

**Основные фичи:**
- кроссплатформенность
- поддерживает все форматы пикселей TBitmap для чтения
- ускоренная обработка популярных форматов в Windows/GTK/Qt /OSX
- можно обработать любое изображение, как имеющее альфа-канал, так и нет (24бит/32бит) 


#### Example 1 - Инвертирование цвета (read and write)
![example1.png](examples/example1.png)
```delphi
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
```
#### Example 2 - Создание полупрозрачного изображения (read and write, alpha)
![example2.png](examples/example2.png)
```delphi
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
```
#### Example 3 - Создание эффекта плазмы (write only)
![example3.png](examples/example3.png)
```delphi
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
```
#### Example 4 - Смешивание двух изображений (read only, write only)
![example4.png](examples/example4.png)
```delphi
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
```
---
## [UA] <img src="https://upload.wikimedia.org/wikipedia/commons/4/49/Flag_of_Ukraine.svg" height="11px"/>
### BitmapPixels.pas  - Модуль для Lazarus і Delphi, що дає прямий доступ до пікселів TBitmap.
#### Працює на Windows(WinApi), Linux(GTK2, Qt5), OSX(Cocoa)

Є досить популярне, у спільноті Lazarus розробників, питання: Як отримати швидкий доступ до пікселів TBitmap?  
Це легко зробити в **Delphi** завдяки властивості **Scanline[]** через досить обмежену кількість можливих форматів пікселів, але досить складно в **Lazarus**.  
Приклади складнощів, які можуть виникнути: https://wiki.freepascal.org/Fast_direct_pixel_access. 

Я пропоную невеликий, у вигляді одного файлу, модуль **"BitmapPixels.pas "**, який спрощує роботу до простого виклику **TBitmapData.Map()** і **TBitmapData.Unmap()**.  
Ви отримуєте масив пікселів у форматі **$AARRGGBB** у властивості **Data**, а також можливість встановити та отримати колір пікселів за допомогою **SetPixel()/GetPixel()**. 

```delphi
var
  Data: TBitmapData;
  X, Y: Integer;
  Pixel: TPixelRec;// for easy access to the channels 
begin
  // Reading the colors of the image into map "Data", width mode "ReadWrite", in the "False" alpha channel mode.
  // The alpha channel will be set to 0 on every element of the array. ($00RRGGBB, $00RRGGBB, ...) 
  Data.Map(Bitmap, TAccessMode.ReadWrite, False);
  try
    for Y := 0 to Data.Height - 1 do
    begin
      for X := 0 to Data.Width - 1 do
      begin
        // Read color at (X, Y) to Pixel record
        Pixel := Data.GetPixel(X, Y);
        // some changes of Pixel
        Pixel.R := (Pixel.R + Pixel.G + Pixel.B) div 3;
        Pixel.G := Pixel.R;
        Pixel.B := Pixel.R;
        // ...
        // Write Pixel record to (X, Y) in map
        Data.SetPixel(X, Y, Pixel);
      end;
    end;
  finally
    // Writing the map to the image.
    // Since we have abandoned Alpha, the pixel format will be set to pf24bit.
    Data.Unmap();
  end;
end;
```

**Основні фічі:**
- кросплатформеність
- підтримує всі формати пікселів TBitmap для читання
- прискорена обробка популярних форматів у Windows/GTK/Qt /OSX
- можна обробити будь-яке зображення, як таке, що має альфа-канал, так і ні (24біт/32біт) 


#### Example 1 - Інвертування кольору (read and write)
![example1.png](examples/example1.png)
```delphi
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
```
#### Example 2 - Створення напівпрозорого зображення (read and write, alpha)
![example2.png](examples/example2.png)
```delphi
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
```
#### Example 3 - Створення ефекту плазми (write only)
![example3.png](examples/example3.png)
```delphi
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
```
#### Example 4 - Змішування двох зображень (read only, write only)
![example4.png](examples/example4.png)
```delphi
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
```
