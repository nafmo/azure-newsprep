{************************************************************************}
{* Modul:       MsgIdU.Pas                                              *}
{************************************************************************}
{* Inneh†ll:    Objekt f”r hantering av MSGID-framtagning               *}
{************************************************************************}
{* Funktion:    Sk”ter MSGID-generering p† ett bra s„tt                 *}
{************************************************************************}
{* Klasser:     MsgIdAbs (abstrakt ”verklass)                           *}
{*              |- NsgIdStd                                             *}
{*              +- MsgIdServ                                            *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.0  - 1997-07-15 - F”rsta versionen                               *}
{************************************************************************}

Unit MsgIdU;

Interface

Type
  IdServerDat = Record
    Signature: LongInt;                { fill with $1a534449 }
    Revision: LongInt;                 { fill with $00000000 }
    InitSerial: LongInt;
    NextSerial: LongInt;
    Reserved: Array[1..59] of longint; { fill with $00000000 }
    Crc32: LongInt;
  End;

  MsgIdAbsPointer = ^MsgIdAbs;
  MsgIdStdPointer = ^MsgIdStd;
  MsgIdServPointer= ^MsgIdServ;

{************************************************************************}
{* Klass:       MsgIdAbs                                                *}
{* Beskrivning: Abstrakt ”verklass f”r MSGID-hanteringsklasserna        *}
{* Metoder:     GetSerial (dummy)                                       *}
{************************************************************************}
  MsgIdAbs = object
    Function  GetSerial(Number: Byte): LongInt; virtual;
  end;

{************************************************************************}
{* Klass:       MsgIdStd                                                *}
{* Beskrivning: MSGID-hantering utan IDSERVER                           *}
{* Konstrukt”r: Init      - initierar MSGID-v„rde                       *}
{* Metoder:     GetSerial - returnerar MSGID-nummer                     *}
{************************************************************************}
  MsgIdStd = object(MsgIdAbs)
    MsgIdNum:   LongInt;
    Constructor Init;
    Function    GetSerial (Number: Byte): LongInt; virtual;
  end;

{************************************************************************}
{* Klass:       MsgIdServ                                               *}
{* Beskrivning: MSGID-hantering med IDSERVER                            *}
{* Konstrukt”r: Init      - initierar IDSERVER-hantering                *}
{* Metoder:     GetSerial - returnerar MSGID-nummer                     *}
{************************************************************************}
  MsgIdServ = object(MsgIdAbs)
    ServerFile: File of IdServerDat;
    ServerFileName: String;

    Constructor Init      (ServerName: String);
    Function    GetSerial (Number: Byte): LongInt; virtual;
  end;

Implementation

Uses
  Crc32, Dos, MkMisc, StrUtil;
{$IFDEF OS2}
Uses BSEDos, Os2Dt;
{$ENDIF}

Type
{$IFDEF MSDOS}
  CompatDateTime = DateTime;
{$ENDIF}

Const
  fmReadOnly  = $00;
  fmWriteOnly = $01;
  fmReadWrite = $02;

  fmDenyAll   = $10;
  fmDenyWrite = $20;
  fmDenyRead  = $30;
  fmDenyNone  = $40;

  ServerVersion   = 0;
  ServerSignature = $1a534449;

{************************************************************************}
{* Klass:       MsgIdAbs                                                *}
{************************************************************************}

{************************************************************************}
{* Metod:       GetSerial                                               *}
{************************************************************************}
{* Inneh†ll:    Dummymetod som returnerar noll                          *}
{* Definition:  Function MsgIdAbs.GetSerial(Number: Byte): LongInt;     *}
{************************************************************************}
Function MsgIdAbs.GetSerial(Number: Byte): LongInt;
Begin
  GetSerial := 0;
end;

{************************************************************************}
{* Klass:       MsgIdStd                                                *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    Initierar MSGID-v„rdet                                  *}
{* Definition:  Constructor MsgIdStd.Init;                              *}
{************************************************************************}
Constructor MsgIdStd.Init;
Var
  Datum:        CompatDateTime;
  Temp:         Word;
Begin
  With Datum do begin
    GetDate(Year, Month, Day, Temp);
    GetTime(Hour, Min, Sec, Temp);
  end;
  {$IFDEF OS2}
  MsgIdNum := ((DTToUnixDate(DosDateTime2OS2DateTime(Datum)) and $7fffffff) shl 4) + (byte(Temp) shr 3);
  {$ELSE}
  MsgIdNum := ((DTToUnixDate(Datum) and $7fffffff) shl 4) + (byte(Temp) shr 3);
  {$ENDIF}
end;

{************************************************************************}
{* Metod:       GetSerial                                               *}
{************************************************************************}
{* Inneh†ll:    Returnerar MSGID-nummer                                 *}
{* Definition:  Function MsgIdAbs.GetSerial(Number: Byte): LongInt;     *}
{************************************************************************}
Function MsgIdStd.GetSerial(Number: Byte): LongInt;
Begin
  GetSerial := MsgIdNum;
  Inc(MsgIdNum, Number);
end;

{************************************************************************}
{* Klass:       MsgIdAbs                                                *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    Initierar IDSERVER-data                                 *}
{* Definition:  Constructor MsgIdServ.Init(ServerName: String);         *}
{************************************************************************}
Constructor MsgIdServ.Init(ServerName: String);
Begin
  If ServerName[Length(ServerName)] <> '\' then
    ServerName := ServerName + '\';
  ServerName := ServerName + 'idserver.dat';
  Assign(ServerFile, ServerName);
  ServerFileName := ServerName;
end;

{************************************************************************}
{* Metod:       GetSerial                                               *}
{************************************************************************}
{* Inneh†ll:    Returnerar MSGID-nummer och uppdaterar IDSERVER-data    *}
{* Definition:  Function MsgIdServ.GetSerial(Number: Byte): LongInt;    *}
{************************************************************************}
Function MsgIdServ.GetSerial(Number: Byte): LongInt;
Var
  ServerDat: IdServerDat;
  i, j: Byte;
  k: Word;
  crc: LongInt;
  ServerDatByteArrayBase: Byte Absolute ServerDat;
  ServerDatByteArray_p: ^Byte;
  {$IFDEF MSDOS}
  R: Registers;
  Dummy: Real;
  {$ENDIF}

 {************************************************************************}
 {* Rutin:       CreateFile                                              *}
 {************************************************************************}
 {* Inneh†ll:    Skapar en ny IDSERVER-fil                               *}
 {* Definition:  Procedure CreateFile;                                   *}
 {************************************************************************}
 Procedure CreateFile;
 Var
   Datum: CompatDateTime;
   Temp: Word;
 Begin
   FillChar(ServerDat, SizeOf(IdServerDat), #0);
   ServerDat.Revision := ServerVersion;
   ServerDat.Signature := ServerSignature;
   With Datum do begin
     GetDate(Year, Month, Day, Temp);
     GetTime(Hour, Min, Sec, Temp);
   end;
   {$IFDEF OS2}
   ServerDat.InitSerial := DTToUnixDate(DosDateTime2OS2DateTime(Datum)) shl 5;
   {$ELSE}
   ServerDat.InitSerial := DTToUnixDate(Datum) shl 5;
   {$ENDIF}
   ServerDat.NextSerial := ServerDat.InitSerial;
   ServerDat.Crc32 := ServerSignature; { On”digt CRC32:a direkt }
   Seek(ServerFile, 0);
   Write(ServerFile, ServerDat);
 end;

 {************************************************************************}

Begin
  FileMode := fmReadWrite or fmDenyAll;
  {$I-}
  Reset(ServerFile);
  If IoResult <> 0 then begin                   { Gick inte att ”ppna? }
    Rewrite(ServerFile);
    If IoResult = 0 then begin                  { Gick att skapa       }
      CreateFile;
    end else begin                              { Gick inte att skapa  }
      i := 0;
      While (i < 5) do begin                    { F”rs”k fem g†nger    }
        {$IFDEF MSDOS}
        R.AX := $1680;
        Intr($2f, R);                           { Sl„pp tid            }
        If R.AL = $80 then begin
          For k := 0 to 65535 do                { v„nta omultitaskande }
            Dummy := k / 3;
        end else begin
          R.AX := $1680;                        { och sl„pp lite till  }
          Intr($2f, R);
        end;
        {$ELSE}{$IFDEF OS2}
        DosSleep(Random(1000));                 { Sov en stund         }
        {$ENDIF}{$ENDIF}
        Inc(i);
        Reset(ServerFile);
        If IoResult = 0 then                    { Lyckades... flagga   }
          i := 10;
      end; { While }
      Writeln;
      If i <> 10 then begin
        GetSerial := (LongInt(Random($ffff)) shl 16) or Random($ffff);
        Exit;
      end;
    end; { If }
  end;
  { Okej, filen „r ”ppen... }
  Seek(ServerFile, 0);
  Read(ServerFile, ServerDat);
  If ServerDat.Signature <> ServerSignature then begin { fel signatur }
    Seek(ServerFile, 0);
    Truncate(ServerFile);
    CreateFile;
  end;
  If ServerDat.Crc32 <> ServerSignature then begin { Kontrollera CRC32 }
    crc := $ffffffff;
    ServerDatByteArray_p := @ServerDatByteArrayBase;
    For i := 1 to SizeOf(ServerDat) - SizeOf(LongInt) do begin
      crc := UpdC32(ServerDatByteArray_p^, crc);
      Inc(ServerDatByteArray_p);
    end;
    If ServerDat.Crc32 <> crc then begin { CRC-fel }
      Truncate(ServerFile);
      CreateFile;
    end;
  end;
  GetSerial := ServerDat.NextSerial;            { H„mta serienummer    }
  Inc(ServerDat.NextSerial, Number);            { Uppdatera            }
  { Ber„kna ny CRC32 }
  crc := $ffffffff;
  ServerDatByteArray_p := @ServerDatByteArrayBase;
  For i := 1 to SizeOf(ServerDat) - SizeOf(LongInt) do begin
    crc := UpdC32(ServerDatByteArray_p^, crc);
    Inc(ServerDatByteArray_p);
  end;
  ServerDat.Crc32 := crc;
  Seek(ServerFile, 0);
  Write(ServerFile, ServerDat);
  Close(ServerFile);
  { Klart! }
  FileMode := fmReadOnly or fmDenyNone;
end;

end.
