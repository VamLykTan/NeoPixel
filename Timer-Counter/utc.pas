unit utc;

{$mode objfpc}{$H+}
interface

{*******************************************************************************
**                                                                            **
** Sammlung für Timer und Counter Funktionen, welche analog wie die uFunction **
** in alles AVR Projekten verwendet werden kann                               **
**                                                                            **
*******************************************************************************}

const
  Anz_LED_Bit                = 3;

var
  Rnd_Color                  : array [0..Anz_LED_Bit-1] of uint8;

procedure Int_Timer;

{$if defined (Ran_Dom) or defined (PC_Mod)}
procedure Timer_Interrupt_RND;
{$endif}

implementation

procedure Int_Timer;
// ATMega16 T1 = ATMega328 T0
begin
{$if defined (ATMega328p)}
  TCCR0A                     := %00;                                            // Normaler Timer
  TCCR0B                     := %011;                                           // Clock = CPU / 16
  TIMSK0                     := (1 shl TOIE0);                                  // Enable Timer0 Interrupt
{$elseif defined (ATMega16p)}
  TCCR1A                     := %00;
  TCCR1B                     := %011;
  TIMSK                      := (1 shl TOIE1);
  {$endif}
end;


{$if defined (Ran_Dom) or defined (PC_Mod)}
procedure Timer_Interrupt_RND;
const
  RndCount                   = 50;                                              // Anzahl der Farben / LED
var
  i                          : uint16;
  rnd                        : array [0..Anz_LED_Bit-1] of uint8;
begin
  for i:= 0 to Anz_LED_Bit-1 do begin
        inc(rnd[i]);
        if rnd[i] > i then begin
          rnd[i]             := 0;
          inc(RND_Color[i]);
          if (Rnd_Color[i] >= RndCount) then
             Rnd_Color[i]    := 0;
             end;
        end;
end;
{$endif}

end.
