unit NeoLib;

{$mode objfpc}{$H+}
interface

uses
  uconst, ufunction;

type
  TRGB                       = record
    Color                    : array[0..2] of uint8;
  end;

  TNeo_LED                   = record
    L, R                     : Uint8;
    RGB                      : TRGB;
  end;

  bit                        = 0..1;

const
  {$if defined (ATTiny85) or defined (ATTiny25)}
  LED                        = 2;
  {$endif}
  {$if defined (ATTiny25) or defined (ATTiny85)}
  _RST                       = 205;
  {$elseif defined (ATMega16p) or defined (ATMega328p)}

  _RST                       : uint8 = 230;
  Max_Line                   = 12;

  {$if defined (ATMega328p)}
  LED_Count                  = 7;                                               // immer *-1*, da bei "0" Begonnen wird
  BPD                        = (CPL*LED_Count-1*10);
  {$elseif defined (ATMega16p)}
  Led_Count                  = 8;
  {$endif}


// PORT B
  RS_485_IO                  = 0;
  ShiftOut_NEOPIXEL          = 1;
  _OE_Int_01                 = 2;                                               // OutPut Enabled Line 7 - 12
  _OE_Int_02                 = 3;                                               // OutPut Enabled Line 1 - 06

// PORT C
  LED_01                     = 5;                                               // Line 06|12
  LED_02                     = 4;                                               // Line 05|11
  LED_03                     = 3;                                               // Line 04|10
  LED_04                     = 2;                                               // Line 03|09
  LED_05                     = 1;                                               // Line 02|08
  LED_06                     = 0;                                               // Line 01|07

//LED_01                     = 0;                                               // Line 06|12
//LED_02                     = 1;                                               // Line 05|11
//LED_03                     = 2;                                               // Line 04|10
//LED_04                     = 3;                                               // Line 03|09
//LED_05                     = 4;                                               // Line 02|08
//LED_06                     = 5;                                               // Line 01|07

// Port D
  {$if defined (L1x12)}
  LED_07                     = 7;                                               // Line 06|12
  LED_08                     = 6;                                               // Line 05|11
  LED_09                     = 5;                                               // Line 04|10
  LED_10                     = 4;                                               // Line 03|09
  LED_11                     = 3;                                               // Line 02|08
  LED_12                     = 2;                                               // Line 01|07

//  LED_07                     = 2;                                               // Line 06|12
//  LED_08                     = 3;                                               // Line 05|11
//  LED_09                     = 4;                                               // Line 04|10
//  LED_10                     = 5;                                               // Line 03|09
//  LED_11                     = 6;                                               // Line 02|08
//  LED_12                     = 7;                                               // Line 01|07
  {$endif}
  {$endif}

var
  Rgb_Line                   : array [1..Max_Line, 0..LED_Count] of TRGB;
  Neo                        : TNeo_Led;
//  _RGB_Line                  : array [1..Max_Line, 0..BPD] of bit;

// ge = rst = 1
// rt = sck = 7
// gn = MISO = 6
// bk = MOSI = 5
// ws = GND = 4

procedure Set_IO;

procedure RgbFill(g, r, b: uint8);                                  overload;
procedure RgbFill(g, r, b, Line, Value: uint8);                     overload;
{$if defined (L2x6)}
procedure Set_OE_Int(Value: Boolean);
{$endif}

procedure RgbShiftOut_L01(Value: boolean);
procedure RgbShiftOut_L02(Value: boolean);
procedure RgbShiftOut_L03(Value: boolean);
procedure RgbShiftOut_L04(Value: boolean);
procedure RgbShiftOut_L05(Value: boolean);
procedure RgbShiftOut_L06(Value: boolean);

{$if defined (L1x12)}
procedure RgbShiftOut_L07;
procedure RgbShiftOut_L08;
procedure RgbShiftOut_L09;
procedure RgbShiftOut_L10;
procedure RgbShiftOut_L11;
procedure RgbShiftOut_L12;
{$endif}

implementation

procedure Set_IO;
begin
  {$if defined (ATTiny25) or defined (ATTiny85)}
  DDRB                       := DDRB  or (1 shl LED);                           // sbi	23, 2
  PORTB                      := PORTB or (1 shl LED);                           // sbi  24, 2
  {$elseif defined (ATMega328p)}
  // Define & Settings Port B
  DDRB                       := DDRB  or (1 shl RS_485_IO);
  PORTB                      := PORTB or (1 shl ShiftOut_NEOPIXEL)
                                      or (1 shl RS_485_IO);

  // Define & Settings Port D
//  DDRD                       := DDRD  or (1 shl _OE_Int_01) or (1 shl _OE_Int_01);
//  PORTD                      := PORTD or (1 shl _OE_Int_01) or (0 shl _OE_Int_02);

  // Define & Settings Port C; Latch-Port; 6-Bit
  DDRC                       := DDRC  or (1 shl LED_01) or (1 shl LED_02)
                                      or (1 shl LED_03) or (1 shl LED_04)
                                      or (1 shl LED_05) or (1 shl LED_06);
  PORTC                      := PORTC or (1 shl LED_01) or (1 shl LED_02)
                                      or (1 shl LED_03) or (1 shl LED_04)
                                      or (1 shl LED_05) or (1 shl LED_06);

  {$if defined (L1x12)}
  DDRD                       := DDRD  or (1 shl LED_07) or (1 shl LED_08)
                                      or (1 shl LED_09) or (1 shl LED_10)
                                      or (1 shl LED_11) or (1 shl LED_12);
  PORTD                      := PORTD or (1 shl LED_07) or (1 shl LED_08)
                                      or (1 shl LED_09) or (1 shl LED_10)
                                      or (1 shl LED_11) or (1 shl LED_12);
  {$endif}
  {$endif}
  {$if defined (ATMega16p)}
  DDRA                       := DDRA  or (1 shl LED_01) or (1 shl LED_02)
                                      or (1 shl LED_03) or (1 shl LED_04)
                                      or (1 shl LED_05) or (1 shl LED_06);
  PORTA                      := PORTA or (1 shl LED_01) or (1 shl LED_02)
                                      or (1 shl LED_03) or (1 shl LED_04)
                                      or (1 shl LED_05) or (1 shl LED_06);
  {$endif}
end;

procedure RgbFill(g, r, b: uint8);
var
  i                          : uint16;
  j                          : uint8;
begin
  for j := 1 to Max_Line do begin
      for i := 0 to LED_Count-1 do
        RGB_line[j][i].Color[0]     := g;
        RGB_line[j][i].Color[1]     := r;
        RGB_line[j][i].Color[2]     := b;
      end;
end;

procedure RgbFill(g, r, b, Line, Value: uint8);
var a: uint8;
begin
  RGB_line[Line][Value].Color[0]     := g;
  RGB_line[Line][Value].Color[1]     := r;
  RGB_line[Line][Value].Color[2]     := b;

end;

{procedure PixelOut_P_C;
label
  PixelLoop, ColorLoop;

var
  p                          : ^TRGB;
  Row                        : array [1..6] of TRGB;

  Pixel, RGBLine             : uint8;
  Data                       : TRGB;

begin

{ Beispiel für ein Array welches auf 6 x 6 Pixel definiert sein kann.
  Alle Daten gem: des Types "TRGB"!!! wobei die Werte der reihen nach für Grün, Blau, Rot
  stehen...
  1: [  4, 0, 0]; [0,   4, 0]; [0, 0,   4]; [  4,   4, 0]; [  4, 0,   4]; [  4,   4,   4];
  2: [  8, 0, 0]; [0,   8, 0]; [0, 0,   8]; [  8,   8, 0]; [  8, 0,   8]; [  8,   8,   8];
  3: [ 16, 0, 0]; [0,  16, 0]; [0, 0,  16]; [ 16,  16, 0]; [ 16, 0,  16]; [ 16,  16,  16];
  4: [ 32, 0, 0]; [0,  32, 0]; [0, 0,  32]; [ 32,  32, 0]; [ 32, 0,  32]; [ 32,  32,  32];
  5: [ 64, 0, 0]; [0,  64, 0]; [0, 0,  64]; [ 64,  64, 0]; [ 64, 0,  64]; [ 64,  64,  64];
  6: [128, 0, 0]; [0, 128, 0]; [0, 0, 128]; [128, 128, 0]; [128, 0, 128]; [128, 128, 128];
}
  for Pixel := 0 to LED_Count do begin     // Pixel innerhalb der Line
    for RGBLine := 1 to 6 do begin         // NeoPixel_Line
      Row[RGBLine]           := RGB_Line[RGBLine, Pixel];
      end;
    p                        := @Row;
    Data                     := p^;
    asm
     // X-Register mit der Array Adresse laden
      ldi r26, lo(Data.Color[0])
      ldi r27, hi(Data.Color[0])
      ldi r28, lo(Data.Color[1])
      ldi r29, hi(Data.Color[1])
      ldi r30, lo(Data.Color[2])
      ldi r31, hi(Data.Color[2])


      ldi r20,   0           // Register mit Nullbyte initialisieren
      ldi r21,  63           // Register mit EINSEN initialisieren

//      ldi r22,   8           // Schleife für 8 Bit initialisieren
      ldi r23,   3           // Schleife für 8 Bit initialisieren

    ColorLoop:
      ldi r22,   8           // Schleife für 8 Bit initialisieren
    PixelLoop:
      OUT PORTC, r21         // 1 Takt  --> A 0
      LD  r25,   X+          // 2 Takte -->   2
      OUT PORTC, r25         // 1 Takt  --> B 3
      NOP                    // 1 Takt  -->   4
      NOP                    // 1 Takt  -->   5
      OUT PORTC, r20         // 1 Takt  --> C 6
    dec r22                  // 1 Takt  -->   7
    brne PixelLoop;
    dec r23
    brne CollorLoop;

    end['r20','r21','r22', 'r23','r25','r26','r27','r28','r29','r30','r31'];
  end;
end;     }

{$if defined (L2x6)}
// Set_OE_Int: False = Low (1-6); True = High = (7-12)
// Set_OE_Int: Port D (11)
procedure Set_OE_Int(Value: boolean);
begin
  asm
    sbi 11, _OE_Int_01
    sbi 11, _OE_Int_02
    nop
  end;
  if not Value then
    asm
    cbi 11, _OE_Int_02
    end
  else
    asm
    cbi 11, _OE_Int_01
    end;
end;
{$endif}

procedure RgbShiftOut_L01(Value: boolean);
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata, Line    : uint8;
label
  TH, TL, T0L, T1L, Loop;
begin
//  DezToWS2812(1);
  asm CLI end;
  {$if defined (L2x6)}
  Set_OE_Int(Value);
  if not Value then Line     := 1
  else              Line     := 7;
  {$elseif defined (L1x12)}
  Line                       := 1;
  {$endif}
  p                          := @Rgb_Line[Line];
  for byteCount := 0 to sizeof(Rgb_Line[Line]) do begin
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        {$if defined (ATTiny25) or defined (ATTiny85)}
        SBI 24, 2                                                             // 24 = PORTB
        nop
        nop
        {$endif}
//        {$if defined (ATMega16p)}SBI 21, LED                                     // 21 = PORTC
//        ldi r16, 13
//        {$endif}
        {$if defined (ATMega328p)}
        sbi 8, LED_01
        {$endif}
        nop
        nop
        nop
        {$if defined (ATTiny25) or defined (ATTiny85)}
        CBI 24, LED
        {$endif}
        {$if defined (ATMega328p)}
        cbi 8, LED_01
        {$endif}
//        {$if defined (ATMega16p)}CBI 21, LED
//        ldi r16, 7
//        {$endif}
//        nop
        end;
        RGBdata              := RGBdata shl 1;
      end else begin
        asm
        {$if defined (ATTiny25) or defined (ATTiny85)}
        SBI 24, LED
        nop
        {$endif}
        {$if defined (ATMega328p)}
        sbi 8, LED_01
        {$endif}
//        {$if defined (ATMega16p)}SBI 21, LED
//        ldi r16, 7
//        TL:
//          dec r16
//          brne TL{$endif}
        {$if defined (ATTiny25) or defined (ATTiny85)}
        CBI 24, LED
        {$endif}
        {$if defined (ATMega328p)}
        cbi 8, LED_01
        {$endif}
//        {$if defined (ATMega16p)}CBI 21, LED
//        ldi r16, 13
//        T0L:
//          dec R16
//          brne T0L
//        {$endif}
         end;
         RGBdata              := RGBdata shl 1;
       end;
    end;
  asm SEI end;
end;

procedure RgbShiftOut_L02(Value: boolean);
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata, Line    : uint8;
label
  TH, TL, T0L, T1L, Loop;
begin
  asm CLI end;
  {$if defined (L2x6)}
  Set_OE_Int(Value);
  if not Value then Line     := 2
  else              Line     := 8;
  {$elseif defined (L1x12)}
  Line                       := 2;
  {$endif}
  p                          := @Rgb_Line[Line];
  for byteCount := 0 to sizeof(Rgb_Line[Line]) do begin
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
       {$if defined (ATMega328p)}
        sbi 8, LED_02
        {$endif}
        nop
        nop
        nop
        {$if defined (ATMega328p)}
        cbi 8, LED_02
        {$endif}
        end;
      RGBdata                := RGBdata shl 1;
      end else begin
        asm
        {$if defined (ATMega328p)}
        sbi 8, LED_02
        {$endif}
        {$if defined (ATMega328p)}
        cbi 8, LED_02
        {$endif}
        end;
        RGBdata              := RGBdata shl 1;
      end;
//    RGBdata                  := RGBdata shl 1;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L03(Value: Boolean);
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata, Line    : uint8;
label
  TH, TL, T0L, T1L, Loop;
begin
  asm CLI end;
  {$if defined (L2x6)}
  Set_OE_Int(Value);
  if not Value then Line     := 3
  else              Line     := 9;
  {$elseif defined (L1x12)}
  Line                       := 3;
  {$endif}
  p                          := @Rgb_Line[Line];
  for byteCount := 0 to sizeof(Rgb_Line[Line]) do begin
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 08, LED_03
        nop
        nop
        nop
        cbi 08, LED_03
        end;
        RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 08, LED_03
        nop
        cbi 08, LED_03
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L04(Value: Boolean);
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata, Line    : uint8;
label
  TH, TL, T0L, T1L, Loop;
begin
  asm CLI end;
  {$if defined (L2x6)}
  Set_OE_Int(Value);
  if not Value then Line     := 4
  else              Line     := 10;
  {$elseif defined (L1x12)}
  Line                       := 4;
  {$endif}
  p                          := @Rgb_Line[Line];
  for byteCount := 0 to sizeof(Rgb_Line[Line]) do begin
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 8, LED_04
        nop
        nop
        nop
        cbi 8, LED_04
        end;
        RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 8, LED_04
        nop
        cbi 8, LED_04
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L05(Value: Boolean);
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata, Line    : uint8;
label
  TH, TL, T0L, T1L, Loop;
begin
  asm CLI end;
  {$if defined (L2x6)}
  Set_OE_Int(Value);
  if not Value then Line     := 5
  else              Line     := 11;
  {$elseif defined (L1x12)}
  Line                       := 5;
  {$endif}
  p                          := @Rgb_Line[Line];
  for byteCount := 0 to sizeof(Rgb_Line[Line]) do begin
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 8, LED_05
        nop
        nop
        nop
        cbi 8, LED_05
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 8, LED_05
        nop
        cbi 8, LED_05
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L06(Value: Boolean);
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata, Line    : uint8;
label
  TH, TL, T0L, T1L, Loop;
begin
  asm CLI end;
  {$if defined (L2x6)}
  Set_OE_Int(Value);
  if not Value then Line     := 6
  else              Line     := 12;
  {$elseif defined (L1x12)}
  Line                       := 6;
  {$endif}
  p                          := @Rgb_Line[Line];
  for byteCount := 0 to sizeof(Rgb_Line[Line]) do begin
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 8, LED_06
        nop
        nop
        nop
        cbi 8, LED_06
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 8, LED_06
        nop
        cbi 8, LED_06
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

{$if defined (L1x12)}
// ShiftOut PortD
procedure RgbShiftOut_L07;
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata          : uint8;
begin
  p                          := @Rgb_Line[7];
  asm CLI end;
  for byteCount := 0 to sizeof(Rgb_Line[7]) - 1 do begin
//    asm WDR end;
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 11, LED_07                                                          // 11 = Port D
        nop
        nop
        nop
        cbi 11, LED_07
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 11, LED_07
        nop
        cbi 11, LED_07
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L08;
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata          : uint8;
begin
  p                          := @Rgb_Line[8];
  asm CLI end;
  for byteCount := 0 to sizeof(Rgb_Line) - 1 do begin
//    asm WDR end;
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 11, LED_08
        nop
        nop
        nop
        cbi 11, LED_08
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 11, LED_08
        nop
        cbi 11, LED_08
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L09;
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata          : uint8;
begin
  p                          := @Rgb_Line[9];
  asm CLI end;
  for byteCount := 0 to sizeof(Rgb_Line) - 1 do begin
//    asm WDR end;
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 11, LED_09
        nop
        nop
        nop
        cbi 11, LED_09
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 11, LED_09
        nop
        cbi 11, LED_09
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L10;
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata          : uint8;
begin
  p                          := @Rgb_Line[10];
  asm CLI end;
  for byteCount := 0 to sizeof(Rgb_Line) - 1 do begin
//    asm WDR end;
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 11, LED_10
        nop
        nop
        nop
        cbi 11, LED_10
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 11, LED_10
        nop
        cbi 11, LED_10
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L11;
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata          : uint8;
begin
  p                          := @Rgb_Line[11];
  asm CLI end;
  for byteCount := 0 to sizeof(Rgb_Line) - 1 do begin
//    asm WDR end;
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 11, LED_11
        nop
        nop
        nop
        cbi 11, LED_11
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 11, LED_11
        nop
        cbi 11, LED_11
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

procedure RgbShiftOut_L12;
var
  p                          : ^byte;
  byteCount                  : uint16;
  bitCount, RGBdata          : uint8;
begin
  p                          := @Rgb_Line[12];
  asm CLI end;
  for byteCount := 0 to sizeof(Rgb_Line) - 1 do begin
//    asm WDR end;
    RGBdata                  := p^;
    inc(p);
    for bitCount := 0 to 7 do
      if RGBdata and $80 > 0 then begin
        asm
        sbi 11, LED_12
        nop
        nop
        nop
        cbi 11, LED_12
        end;
      RGBdata              := RGBdata shl 1;
      end else begin
        asm
        sbi 11, LED_12
        nop
        cbi 11, LED_12
        end;
        RGBdata              := RGBdata shl 1;
      end;
    end;
    asm SEI end;
  end;

{$endif}

end.

