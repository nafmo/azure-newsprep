Unit MKMisc;


Interface

{$IFDEF WINDOWS}
Uses WinDos;
{$ELSE}
Uses Dos;
{$ENDIF}
{$IFDEF OS2}
Uses Os2Dt;
{$ENDIF}

Function  DTToUnixDate(DT: DateTime): LongInt;
Function  GregorianToJulian(DT: DateTime): LongInt;


Implementation


Uses
  Crc32;


Const
   C1970 = 2440588;
   D0 =    1461;
   D1 =  146097;
   D2 = 1721119;

Function DTToUnixDate(DT: DateTime): LongInt;
   Var
     SecsPast, DaysPast: LongInt;

  Begin
  DaysPast := GregorianToJulian(DT) - c1970;
  SecsPast := DaysPast * 86400;
  SecsPast := SecsPast + (LongInt(DT.Hour) * 3600) + (DT.Min * 60) + (DT.Sec);
  DTToUnixDate := SecsPast;
  End;

Function GregorianToJulian(DT: DateTime): LongInt;
Var
  Century: LongInt;
  XYear: LongInt;
  Temp: LongInt;
  Month: LongInt;

  Begin
  Month := DT.Month;
  If Month <= 2 Then
    Begin
    Dec(DT.Year);
    Inc(Month,12);
    End;
  Dec(Month,3);
  Century := DT.Year Div 100;
  XYear := DT.Year Mod 100;
  Century := (Century * D1) shr 2;
  XYear := (XYear * D0) shr 2;
  GregorianToJulian :=  ((((Month * 153) + 2) div 5) + DT.Day) + D2
    + XYear + Century;
  End;

End.
