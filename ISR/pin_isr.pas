unit pin_isr;

{$mode ObjFPC}{$H+}

interface

const
  // PORD B - Definition Aufruf ZWINGEND nach Set_IO (NeoLib) erforderlich,
  // da diese sonst überschrieben wird.

  ShiftOut_NEOPIXEL          = 1;


procedure Set_pin_ISR;
procedure SO_NEOPIX;

implementation

procedure Set_pin_ISR;
begin
  DDRB                       := 0;
  PORTB                      := (1 shl ShiftOut_NeoPixel);
  EICRA                      := %10;
  EIMSK                      := %01;
  PCICR                      := %001;
  PCMSK0                     := (1 shl ShiftOut_NeoPixel);
end;

procedure SO_NEOPIX;
begin

end;

end.

