unit uart;

{$mode objFPC}{$H+}

interface

uses
  uconst;

const

  Baud                       = 19200;

{$IFNDEF F_CPU}
//  {$ERROR F_CPU not defined}
//  {$if defined (ATtiny45) or defined (ATtiny85) or defined (ATMega8)}
    F_CPU                    = 8000000;
//  {$else if defined (ATMega16) or defined (ATMega328p)}
    F_CPU                    = 16000000;
//  {$endif}
{$ENDIF}

var
  Temp                       : char;
  Status_Flag, RX_Count      : uint8;

  RX                         : array [0..100] of uint8;


procedure UARTInit(_U2X: boolean);                                              // Inizialisieren der Hardware UART

function  UARTReadChar: uint8;                                                  // Zeichen Empfangen

procedure UARTSendByte(b: uint8);                                               // Zeichen Senden;
procedure UARTSendString(Value: shortString);                                   // Stringkette senden;

//procedure UARTSoftSendByte485(Value: Byte);

procedure Read_TX(Laeng: uint16);

implementation

{program UART_ATtiny85;

const
  BAUDRATE = 9600; // Baudrate einstellen
  UBRR_VALUE = (F_CPU div (BAUDRATE * 16)) - 1;

procedure UART_Init;
begin
  UBRRL := UBRR_VALUE; // Baudrate Register setzen
  UCSRB := (1 shl RXEN) or (1 shl TXEN); // RX und TX aktivieren
  UCSRC := (1 shl URSEL) or (1 shl UCSZ1) or (1 shl UCSZ0); // Asynchroner Modus, 8 Datenbits, 1 Stoppbit
end;

procedure UART_SendByte(data: byte);
begin
  while (UCSRA and (1 shl UDRE)) = 0 do ; // Warten, bis das Senderegister bereit ist
  UDR := data; // Byte senden
end;

function UART_ReceiveByte: byte;
begin
  while (UCSRA and (1 shl RXC)) = 0 do ; // Warten, bis ein Byte empfangen wurde
  Result := UDR; // Empfangenes Byte zurückgeben
end;

var
  receivedByte: byte;

begin
  UART_Init; // UART initialisieren

  // Beispiel: Sende das Zeichen 'A' und empfange die Antwort
  UART_SendByte(byte('A'));
  receivedByte := UART_ReceiveByte;

  // Hier kannst du den empfangenen Wert weiterverarbeiten
end.}

procedure UARTInit(_U2X: boolean);
begin
  {$if defined (ATMega16p)}
    if _U2X then begin
      UBRRL                  := (F_CPU div ( 8 * Baud)) - 1;
      UBRRH                  := 0;
      UCSRA                  := UCSRA or (1 shl U2X);
    end else begin
        UBRRL                := (F_CPU div (16 * Baud)) - 1;
        UBRRH                := 0;
        UCSRA                := UCSRA or (0 shl U2X);
        end;
    UCSRB                    := (1 shl TXEN) or (1 shl RXEN);
    UCSRC                    := (1 shl URSEL) or (%011 shl UCSZ);
  {$elseif defined (ATMega328p)}
    if _U2X then begin
       UBRR0L                := (F_CPU div ( 8 * Baud)) - 1;
       UBRR0H                := 0;
       UCSR0A                := UCSR0A or (1 shl U2X0);                         // Normale Geschwindigkeit
    end else begin
        UBRR0L               := (F_CPU div (16 * Baud)) - 1;
        UBRR0H               := 0;
        UCSR0A               := UCSR0A or (0 shl U2X0);
        end;
    UCSR0B                   := UCSR0B or (1 shl TXEN0) or (1 shl RXEN0) or
                                          (1 shl RXCIE0);                       // Empfangen und Senden
    UCSR0C                   := UCSR0C or (%011 shl UCSZ0)                      // 8 - Bit übertragung, 1 Stop-Bits
  {$endif}
end;

function UARTReadChar: uint8;
begin
  {$if defined (ATMega16p)}
    while UCSRA  and (1 shl RXC)  = 0 do;                                       // Warten, bis Zeichen ankommt.
    Result                   := UDR;                                            // Zeichen einlesen.
  {$elseif defined (ATMega328p)}
    while UCSR0A and (1 shl RXC0) = 0 do;
    Result                   := UDR0;
    {$endif}
end;

procedure UARTSendByte(b: uint8);
begin
  {$if defined (ATMega16p)}
    while UCSRA and (1 shl UDRE) = 0 do;                                        // warte bis letztes Zeichen gesendet
    UDR                      := byte(c);                                        // Zeichen senden.
  {$elseif defined (ATMega328p)}
    while UCSR0A and (1 shl UDRE0) = 0 do;
    UDR0                     :=  b;
    {$endif}
end;

procedure UARTSendString(value: ShortString);
var i: uint8;
begin
  for i := 1 to length(Value) do
    UARTSendbyte(byte(Value[i]));
end;

procedure Read_TX(Laeng: uint16);
var temp: byte;
begin
  asm cli end;
  if Status_Flag = $00 then begin
// Read Data from Master
    temp                     := UARTReadChar;
    if (Temp = WakeUp) then begin
      RX_Count               := 0;
      end else begin
        if (temp <> Trans_End) then begin
          RX[RX_Count]       := temp;
          inc(RX_Count);
          if (RX_Count = Laeng) then
             RX[0]           := Trans_End;
          end;
        if (temp = Trans_End) then
          {$ifdef Term}
           Status_Flag       := $02;
          {$else}
           Status_Flag       := $01;
          {$endif}
        end;
  asm sei end;
  end;
end;

end.

