unit rs485;

{$mode objFPC}{$H+}
{$Marco on}

interface

const

  Baud                       = 9600;
  TIMER_PRESCALER           = 8;


{*******************************************************************************
**                 RS485 via SN75176B                                         **
**                                                                            **
**                   R/D = Datenleitung                                       **
**                 _RE/DE = Steuerleitung                                     **
**                 _Int Bufferinterrupt                                       **
*******************************************************************************}

{$if defined (Attiny25)}
   _RX                       = 2;
   Faktor                    = 8;
{$endif}
{$if defined (Attiny25) or defined (Attiny45) or defined (Attiny85)}
  _RX                        = 3;                                               // PB3 Pin 2; Datenleitung (TX - OUT = 1; Reserve -> RS-Umsetzter)
  _TX                        = 4;                                               // PB4 Pin 3; Datenleitung (RX - IN = 0; Transmit <- RS-Umsetzter)
  _RE_DE                     = 0;                                               // Steuerleitung (_RE = "L" / _DE = "H" ; as out)
//  DataIn                     = 0;
//  Faktor                     = 103;  {** richtigen Wert rausfinden **}
  {$IFNDEF ws2812}
  _Int                       = (1 shl 5);                                       // PB5 Pin1; Interrupterkennung für RS 485, nur für Sendeanforderung
  {$endif}
{$endif}
{$if defined (ATMega16)}
  _TX_RX                     = 1 shl 0;                                         // Datenleitung (TX - OUT = 1 / RX - IN = 0)
  _RE_DE                     = 1 shl 1;                                         // Datenflussteuerung "_RE = L" / "_DE = H"
  _Int                       = 1 shl 2;                                         // Interruptkennung für RS485 auf DDRA
  Faktor                     = 22;
{$endif}

{$IFNDEF F_CPU}
//  {$ERROR F_CPU not defined}
  {$if defined (ATTiny25) or defined (ATtiny45) or defined (ATtiny85) or defined (ATMega8)}
    F_CPU                    = 8000000;
  {$else if defined (ATMega16) or defined (ATMega328p)}
    F_CPU                    = 16000000;
  {$endif}
{$ENDIF}
{$ifndef Softteiler}
  {$if defined (ATTiny45) or defined (ATTiny85)}
    Softteiler               = 10;                       // Bitzeitzähler
//    _XL                      = Softteiler mod 255;
//    _XH                      = Softteiler div 255;
  {$endif}
  {$if defined (ATMega16) or defined (ATTiny25)}
    SoftTeiler               = F_CPU div (Baud * Faktor);                       // Bitzeitzähler
  {$endif}
{$endif}

var
  _RE                        : boolean;                                         // false = Read;
  RByte                      : char;

procedure USI_Init;                                                             // Inizialisieren der Hardware UART

//function ReverseByte (value: uint8): uint8;

//procedure PCINT0_RS485;
procedure RS485_SendByte(value: byte);

implementation

uses
  uconst;

// Init UART & USI for UART at ATtiny25/45/85

procedure USI_Init;
begin
  {$if defined (ATtiny25) or defined (ATtiny45) or defined (ATtiny85)}

  //DDRB                       := DDRB       or (1 shl _TX);// or (1 shl _RE_DE); // Steuerleitung auf Out; Pegel "L"
  asm
    sbi  23, _TX
    sbi  24, _TX
    nop
    nop
    end;
  {$endif}
end;

// Funktionen für die RS485 Übertragung

{procedure RS485_SendByte(value: byte);
var
  tx_buf_head: uint8;
begin
  tx_Buf_head                := (UUart_tx_Head+1) and UART_TX_Buf_Msk;
  While (tx_buf_head = UUart_tx_tail) do begin
    UUart_tx_head            := TX_Buf_head;
    UUart_tx_buf[UUart_tx_head] := chr(ReverseByte(Value));
    if not UUart_Status.ongoing_tx_from_buf then
       While (UUart_Status.ongoing_tx) do
       USI_Init;
  end;
end;

function ReverseByte(value: uint8): uint8;
begin
  value                      := ((value shr 1) and $55) or ((value shl 1) and $aa);
  value                      := ((value shr 2) and $33) or ((value shl 2) and $cc);
  value                      := ((value shr 4) and $0f) or ((value shl 4) and $f0);
  result                     := Value;
end;}

// Pin change interrupt detects start of UART reseption
// Verwendung für USI_reserve
{$if defined (Attiny25) or defined (Attiny45) or defined (Attiny85)}
{procedure PCINT0_RS485;    {PCINT0_vect}
begin
  if (PORTB and 1 shl PINB) = 0 then begin                                      // Ignore if InPut is high
    GIMSK                    := 0 shl PCIE;                                     // Disable pin change interrupts
    TCCR0A                   := 2 shl WGM0;                                     // CTC mode
    TCCR0B                   := 0 shl WGM02 or 2 shl CS0;                       // Set Prescaler to /8
    OCR0A                    := 103;                                            // Delay (51+1)*8 cycles
    TCNT0                    := 206;                                            // count up from 0
    // USI-OVF-Interrupt aktivieren und Timer0-Vergleichübereinstimmg als USI-Taktqelle auswählen:
    USICR                    := (1 shl USIOIE) or
                                (0 shl USIWM) or
                                (1 shl USICS);
    USISR                    := (1 shl USIOIF) or 8                             // USI OVF Flag löschen und Zähler setzen
    end;
end;

// USI overflow indicates we've received a byte
procedure USI_OVF; public Name 'USI_OVF_ISR'; interrupt;
var rx_buf_head              : uint8;
begin
  if uuart_Status.ongoing_tx_from_buf then
     if UUart_Status.ongoing_tx then begin
       UUart_Status.ongoing_tx:= false;

       USISR                 := $0F or USI_Counter_Seed_TX;
       USIDR                 := (UUart_tx_data shl 3) or $07
       end
     else begin
       if (uuart_tx_head <> uuart_tx_tail) then begin
         UUart_Status.ongoing_tx_from_buf := True;
         USIDR               := (1 + 0 + UUart_Tx_Buf[UUart_tx_head]);
         dec(UUart_tx_head);
       end;
     end;
end;  }

{$endif}

{procedure RS485_SendByte(value: byte); assembler;
label Daten, H_Bit_0, L_Bit_0, Loop_01, Loop_02, Loop_03, Loop_04,
      Loop_05, Loop_06, Next;
asm
  sei
//  sbi   24, _TX                                                                 // _TX - Ausgang Kontroller setzer (RX Empfänger)

  ldi  r16, 1//2                                                                   // Softteiler High alle Loops
  ldi  r17, 17                                                                  // Softteiler Low  Start
  ldi  r20, 19                                                                  // Softteiler Low  Parität
  ldi  r24, 3                                                                   // Zusatzschleife für Letztes Datenbit
  ldi  r21, 9//17                                                                  // Softteiler Low  Stop
  mov  r22, value                                                               // Daten Kopieren
//  ldi  r22, 0
  ldi  r23, 8                                                                   // länge der Datanbits definieren

// Startbit senden
  cbi  24, _TX
{ nop
  Loop_01:                                                                      // begin der ersten Schleife
  dec  r17
  brne loop_01
  dec  r16
  brne loop_01                                                                  // Dauer der Schleife = 104,125 µs
             }
// Datenbyte senden
Daten:
  ldi  r16, 1//2
  ldi  r18, 9//16
//  ldi  r19, 15//16
  ror  r22
  brcs L_Bit_0
  brcc H_Bit_0

// H_Datenbit senden
H_Bit_0:
  sbi  24, _TX
Loop_02:
  dec  r18
  brne Loop_02
  dec  r16
  brne Loop_02
  rjmp Next

// L_Datenbit senden
L_Bit_0:
  nop
  cbi  24, _TX
Loop_03:
  dec  r18
  brne Loop_03
  dec  r16
  brne Loop_03
  rjmp Next

Next:
  dec r19
  brne Daten

// Restschleife für das Letzte Datenbit
  ldi  r16, 2
Loop_04:
  dec r24
  brne Loop_04
  nop

// Parity Bit senden
{  cbi  24, _TX
  ldi  r16, 2
Loop_05:
  dec  r20
  brne Loop_05
  dec  r16
  brne Loop_05
  ldi  r16, 2   }
//  nop

// Stopp Bit senden
  sbi  24, _TX
Loop_06:
  dec  r21
  brne Loop_06
  dec  r16
  brne Loop_06
  cli
end;             }

procedure RS485_SendByte(value: byte);
var
    i, Data: int16;
    j:       Int8;
  begin
    asm Cli end; // Interrupt sperren
    Data := (value shl 1) or $FE00;
    for j := 0 to 9 do begin          // Bit ausgeben, inklusiv Stop-Bits.
      if (Data and 1) = 1 then begin
        PORTB := PORTB or (1 shl _RX);       // HIGH
        for i := 0 to SoftTeiler do;    // Ein Takt Pause
      end
      else begin
        PORTB := PORTB and not (1 shl _RX); // LOW
        for i := 0 to SoftTeiler do asm nop end;    // Ein Takt Pause
        end;
      Data := Data shr 1;
//      for i := 0 to SoftTeiler do asm nop end;    // Ein Takt Pause
    end;
    asm Sei end; // Interrupt erlauben
  end;

end.

