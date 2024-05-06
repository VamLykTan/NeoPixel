program RS_TEST;

uses
  uart, _eeprom, NeoLib, ufunction, uconst, utc
  {$ifdef slave}
  , pin_isr
  {$endif};

{$if defined (ATMega328p)}
{CKDIV8 sollte immer "0" geschalten werden...

AVR Fuses = -U lfuse:w:0xe2:m -U hfuse:w:0xd9:m -U efuse:w:0xff:m}
{$elseif defined (ATMega16p)}
{CKOPT sollte immer "0" geschalten werden, um diesen µCU mit max 16 MHz
 betreiben zu können.

AVR Fuses = -U lfuse:w:0xF8:m -U hfuse:w:0x8F:m -U efuse:w:0xff:m}
{$endif}

{*******************************************************************************
**                                                                            **
** Aufbau EEPROM                                                              **
**   - 1te BIT = Dummy WÜrd gesetzt wenn geschrieben                          **
**   - 2te BIT = Status                                                       **
**   - 3te BIT = ADR                                                          **
**   - 4te Bit = Funktion/Eigenschaft bis zu 100 zeichen                      **
**                                                                            **
**   - Befehlssequenz immer doppelt ausführen um Steuerbefehle zu erkennen    **
**                                                                            **
**         1 2   3 4 5 6 7 8 9 0 1 2 3 4 5 6 7                                **
**     - $|<|adr|L|l|C|c|D|g|D|r|D|b|#|w|> Einzelne LED                       **
**       - Antwort und Empfangsbestädigung nach Jeder NeoLED                  **
**     - $|<|adr|#|I>        Modul/Funktion                                   **
**                                                                            **
*******************************************************************************}

const
  _name                      = 'AVR Testmodul mit RS232/485 und NEOLED';
  _adr                       = $35;
  _Funktion                  = 'Grundlegender test zur Datenübertragung zw PC, AVR mit anzeige auf NEOLED>';
//  RX_Max_Buffer              = 25;


var
  adr, a, b, c, d, e
//  ,RX_Count, Status_Flag
                             : uint8;
  Name, Funktion             : Shortstring;

//  RX                         : array [0..RX_Max_Buffer-1] of uint8;

{$ifdef Slave}
{$if defined (ATMega328P)}
procedure PORTB_INT; public Name 'PCINT0_ISR'; interrupt;
{$elseif defined (ATMega16p)}
procedure Port_INT; public Name 'INT0_ISR'; interrupt;
{$endif}
begin

end;
{$endif}

{$if defined (ATMega328p)}
procedure Timer0_Interrupt; public Name 'TIMER0_OVF_ISR'; interrupt;
{$elseif defined (ATMega16p)}
procedure Timer1_Interrupt; public Name 'TIMER1_OVF_ISR'; interrupt;
{$endif}
begin
  {$ifdef Ran_Dom}
  Timer_Interrupt_RND
  {$endif}
end;


procedure USART__RX; public Name
{$if defined (ATMega328p)}'USART__RX_ISR';
{$elseif defined (ATMega16p)} 'USART_RXC_ISR';
{$endif} interrupt;
begin
  Read_TX(23);
end;

{#todo -erweitern der Rückgabe, damit sich jeder Master an den dahinter liegenden
        Slave orientieren kann.
        2µS bei 2,5 bis 3GHz sollten passen.
        Alternativ Repeat until schleife verwenden.}
begin
  asm cli end;
  // Timer Initialisieren

  Int_Timer;
  Set_IO;
//  Set_pin_ISR;
  UARTInit(false);
  Status_Flag                := 0;
  if EEProm_Read(0) <> $FF then begin
    adr                      := _adr;
    Name                     := _name;
    Funktion                 := _Funktion;
    end;
  for a := 0 to 35 do RX[a]  := $00;
  asm sei end;
  repeat
    {$if defined (PC_Mod)}
    case Status_flag of
    255: begin
           for a := 0 to 19 do
             RX[a]           := $00;
           Status_Flag       := $FE;
           end;
    254: begin
           UARTSendString(CRLF);
           Status_Flag       := 0;
         end;
      2: begin
           Status_Flag     := 1;
           UARTSendString(CRLF);
           UARTSendString(MSG_Start);
           UARTSendString(CRLF);
           UARTSendByte(adr+48);
           UARTSendString(CRLF);
           UARTSendByte(RX[1]);
           UARTSendString(CRLF);
           if RX[0] <> Trans_end then begin
             UARTSendString(OK_MSG);
             UARTSendByte(Trans_Sektor);
             a               := 0;
             repeat
               UARTSendString(CRLF);
               if a < 10 then begin
                 UARTSendByte(48);
                 UARTSendByte(a+48);
               end;
               if (a >= 10) and (a < 100) then begin
                 UARTSendByte(49);
                 UARTSendByte((a-10)+48);
               end;
               UARTSendString(':   ');
               UARTSendByte(RX[a]);
               inc(a);
               Until RX[a] = $00;
             end else begin
                      UARTSendString(Error_MSG);                                     // Overload im Datenbuffer
                      Status_Flag:= 0;
                      end;
             UARTSendString(CRLF);
             UARTSendByte(Trans_End);
           end;
      1: begin
         {$ifdef Term}
           UARTSendString(CRLF);
           UARTSendString(CRLF);
           UARTSendString('Befehlstätze:');
           UARTSendString(CRLF);
           UARTSendString('WakeUp:             ');
           UARTSendbyte(WakeUp);
           UARTSendString(CRLF);
           UARTSendString('Trans_Start:        ');
           UARTSendbyte(Trans_Start);
           UARTSendString(CRLF);
           UARTSendString('Adresse des µCU:    ');
           UARTSendString(CRLF);
           UARTSendString('    Alle:           ');
           UARTSendByte(byte('A'));
           UARTSendString(CRLF);
           UARTSendString('    Einzeln:        ');
           UARTSendbyte(53);
           UARTSendString(CRLF);
          {$endif}

         if (((RX[0] = Trans_Start) and (RX[1] = byte('A'))) or
             ((RX[0] = Trans_Start) and (RX[1] = byte('a')))) then begin          // $<A>
           RgbFill(Rnd_Color[0], Rnd_Color[1], Rnd_Color[2]);
//           RgbFill(77, 7, 3);
{           RgbShiftOut_L01(false);
           RgbShiftOut_L02(false);
           RgbShiftOut_L03(false);
           RgbShiftOut_L04(false);
           RgbShiftOut_L05(false);
           RgbShiftOut_L06(false);
           RgbShiftOut_L07;
           RgbShiftOut_L08;
           RgbShiftOut_L09;
           RgbShiftOut_L10;
           RgbShiftOut_L11;
           RgbShiftOut_L12;
}           end;
         if ((RX[0] = Trans_Start) and (RX[1] = _adr)) then begin                                   // Befehl zum Datentransfar auf alles µCUs
           UARTSendString(CRLF);
           UARTSendString('µCU auf Adresse: ');
           UARTSendbyte(RX[1]);
           UARTSendString(' gefunden.');
           UARTSendString(CRLF);
{           if ((RX[3] = byte('l')) or (RX[3] = byte('L'))) then                                     // <5#L1C1DDUD1#>
             Neo.L           := CharToUInt(RX[4], RX[5], RX[6]);                                    // Line / Col des Boards definieren
           if ((RX[7] = byte('c')) or (RX[7] = byte('C'))) then                                     // Row des Boards definieren
             Neo.R           := CharToUint(RX[8],  RX[9],  RX[10]);
           Neo.RGB.Color[0]  := CharToUint(RX[11], RX[12], RX[13]);                                 // Grün erzeugen
           Neo.RGB.Color[1]  := CharToUint(RX[14], RX[15], RX[16]);                                 // Rot  erzeugen
           Neo.RGB.Color[2]  := CharToUint(RX[17], RX[18], RX[19]);                                 // Blau erzeugen

           RgbFill(Neo.RGB.Color[0], Neo.RGB.Color[1], Neo.RGB.Color[2], Neo.L, Neo.R);
           UARTSendString(char(Neo.L));
           UARTSendString(CRLF);
           UARTSendString(char(Neo.R));
           UARTSendString(CRLF);
           UARTSendString(char(Neo.RGB.Color[0]));
           UARTSendString(CRLF);
           UARTSendString(char(Neo.RGB.Color[1]));
           UARTSendString(CRLF);
           UARTSendString(char(Neo.RGB.Color[2]));
           UARTSendString(CRLF);
}
           if ((RX[3] = byte('l')) or (RX[3] = byte('L'))) then                                     // <5#L1C1DDUD1#>
             Neo.L           := RX[4];                                                              // Line / Col des Boards definieren
           if ((RX[5] = byte('c')) or (RX[5] = byte('C'))) then                                     // Row des Boards definieren
             Neo.R           := RX[6];
           Neo.RGB.Color[0]  := RX[ 8];                                                             // Grün erzeugen
           Neo.RGB.Color[1]  := RX[10];                                                             // Rot  erzeugen
           Neo.RGB.Color[2]  := RX[12];                                                             // Blau erzeugen

           RgbFill(Neo.RGB.Color[0], Neo.RGB.Color[1], Neo.RGB.Color[2], Neo.L, Neo.R);
           end;

// <5# Allgemeine Abfrage der µCU Adresse

         if ((RX[0] = Trans_Start) and (RX[1] = _adr)
             and (RX[2] = Trans_Sektor)) then begin                                                 // $<5#I>
             if ((RX[3] = byte('I')) or (RX[3] = byte('i'))) then begin           // Befehl zum EEProm auslesen
               UARTSendString(CRLF);
               UARTSendString(_Name);
               UARTSendString(CRLF);
               UARTSendByte(_adr);
               UARTSendString(CRLF);
               UARTSendString(_Funktion);
               UARTSendString(CRLF);
               end;
             if ((RX[3] = byte('S')) or (RX[3] = byte('s'))) then begin           // $<5#SBefehl zum senden auf die WS2812B register
                                                                                // $<5#S>
                RGBShiftOut_L01(False);
      //        RGBShiftOut_L01(True);
                RGBShiftOut_L02(False);
      //        RGBShiftOut_L02(True);
                RGBShiftOut_L03(False);
      //        RGBShiftOut_L03(True);
                RGBShiftOut_L04(False);
      //        RGBShiftOut_L04(True);
                RGBShiftOut_L05(False);
      //        RGBShiftOut_L05(True);
                RGBShiftOut_L06(False);
      //        RGBShiftOut_L06(True);
                RGBShiftOut_L07;
                RGBShiftOut_L08;
                RGBShiftOut_L09;
                RGBShiftOut_L10;
                RGBShiftOut_L11;
                RGBShiftOut_L12;
                end;
              end;
        Status_Flag         := $FF;
         end;
     end;
    {$elseif defined (Test_Mod)}
// Testmod via Schlreife
    for a := 0 to 20 do //begin
      for b := 0 to 20 do //begin
        for c := 0 to 20 do //begin
          for e := 0 to 4 do begin
            for d := 1 to 3 do begin
              RgbFill(a      , b    , c     , d    , e);
              RgbFill(b * 2  , c * 2, a +  2, d + 3, e);
              RgbFill(c shl 2, a * 2, b + 20, d + 6, e);
              RgbFill(a shr 1, c + 5, b *  2, d + 9, e);
              end;

    {$elseif defined (Ran_Dom)}
// Testmod via Timer0 (Zufallszahl)
          for e := 0 to 4 do
            for d := 1 to 12 do begin
              RgbFill((Rnd_Color[2] shl 1), Rnd_Color[1], (Rnd_Color[0] shr 1), d, e);
    {$endif}

            RgbShiftOut_L01(false);
            RgbShiftOut_L02(false);
            RgbShiftOut_L03(false);
            RgbShiftOut_L04(false);
            RgbShiftOut_L05(false);
            RgbShiftOut_L06(false);

            {$if defined (L2x6)}
            RgbShiftOut_L01(true);
            RgbShiftOut_L02(true);
            RgbShiftOut_L03(true);
            RgbShiftOut_L04(true);
            RgbShiftOut_L05(true);
            RgbShiftOut_L06(true);
            {$elseif defined (l1x12)}
            RgbShiftOut_L07;
            RgbShiftOut_L08;
            RgbShiftOut_L09;
            RgbShiftOut_L10;
            RgbShiftOut_L11;
            RgbShiftOut_L12;
    {$endif}
    {$ifndef PC_Mod}
            end;
    {$endif}
//            delay(_rst div 5);
    until 1 = 0;
end.
