unit _eeprom;

interface
                     {
uses
  Classes, SysUtils;}

procedure EEProm_Write;                    Overload;
procedure EEProm_Write(ADDR, Data: Byte);  Overload;
function  EEProm_Read(ADDR: Byte): Byte;


implementation

procedure EEProm_Write;
begin
  {$if defined (ATMega328p)}
  while (EECR and (1 shl EEPE)) <> 0 do begin
  end;
  // Dummy SChreiben ( ADDR = 0; Data = $0FF);
  EEARL         := 0;
  EEDR          := $FF;
  EECR          := EECR or (1 shl EEMPE);
  EECR          := EECR or (1 shl EEPE);
  {$elseif defined (ATMega16p)}
  while (EECR and (1 shl EEWE)) <> 0 do begin
  end;
  // Dummy Schreiben ( ADR = 0; Data = $0FF);
  EEAR          := 0;
  EEDR          := $FF;
  EECR          := EECR or (1 shl EEMWE); // Es müssen 2 Zeilen sein !
  EECR          := EECR or (1 shl EEWE);
  {$endif}
end;

procedure EEProm_Write(ADDR, Data: Byte);
begin
  {$if defined (ATMega328p)}
  while (EECR and (1 shl EEPE)) <> 0 do begin
  end;
  EEARL         := 0;
  EEDR          := Data;
  EECR          := EECR or (1 shl EEMPE);
  EECR          := EECR or (1 shl EEPE);
  {$elseif defined (ATMega16p)}
  while (EECR and (1 shl EEWE)) <> 0 do begin
  end;
  EEAR          := 0;
  EEDR          := Data;
  EECR          := EECR or (1 shl EEMWE);
  EECR          := EECR or (1 shl EEWE);
  {$endif}
end;

function  EEProm_Read(ADDR: Byte): Byte;
begin
  {$if defined (ATMega328p)}
  while (EECR and (1 shl EEPE)) <> 0 do begin end;
  {$elseif defined (ATMega16p)}
  while (EECR and (1 shl EEWE)) <> 0 do begin end;
  {$endif}
  EEAR          := ADDR;
  EECR          := EECR or (1 shl EERE);
  Result        := EEDR;
end;

end.
