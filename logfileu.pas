{************************************************************************}
{* Modul:       LogFileU.Pas                                            *}
{************************************************************************}
{* Inneh†ll:    Objekt f”r hantering av loggfil                         *}
{************************************************************************}
{* Funktion:    Sk”ter loggfilen                                        *}
{************************************************************************}
{* Klasser:     LogFile                                                 *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.0  - 1997-06-24 - F”rsta versionen                               *}
{************************************************************************}
{$X+}

Unit LogFileU;

Interface

Type
  LogFilePointer = ^LogFile;

{************************************************************************}
{* Klass:       LogFile                                                 *}
{* Beskrivning: Anv„nds vid loggning av programdata till fil            *}
{* Konstrukt”r: Init    - initierar information om programnamn m.m      *}
{* Destrukt”r:  Done    - avslutar loggningen                           *}
{* Metoder:     OpenLog - ”ppnar en loggfil                             *}
{*              LogLine - p†b”rjar loggning av en rad                   *}
{*              LogStr  - loggar en str„ng                              *}
{*              LogInt  - loggar ett heltalsv„rde                       *}
{*              LogLn   - avslutar loggning av en rad                   *}
{************************************************************************}

  LogFile = object
    Title:              String[32];     { Programtitel }
    LogTitle:           String[6];      { Loggradstitel }
    LogBegin, LogEnd:   String[32];     { Str„ngar i b”rjan och slut av logg }
    isOpen:             Boolean;        { Loggfil ”ppen? }
    isLogline:          Boolean;        { Loggrad ”ppen? }
    Log:                Text;           { Loggfilen }

    Constructor Init            (ProgramName, LogName, BegStr, EndStr: String);
    Destructor  Done            ;
    Function    OpenLog         (FileName: String): Boolean;
    Function    LogLine         (LogLevel: Char): LogFilePointer;
    Function    LogStr          (TextString: String): LogFilePointer;
    Function    LogInt          (IntegerData: LongInt): LogFilePointer;
    Procedure   LogLn           ;
  end;

Implementation

Uses Dos, StrUtil;

{************************************************************************}
{* Klass:       LogFile                                                 *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    L„gger in programmets namn i dataf„ltet, och initierar  *}
{*              ”vrig data                                              *}
{* Definition:  Constructor LogFile.Init(ProgramName, LogName, BegStr,  *}
{*              EndStr: String);                                        *}
{************************************************************************}
Constructor LogFile.Init(ProgramName, LogName, BegStr, EndStr: String);
Begin
  Title := ProgramName;
  LogTitle := ' ' + LogName + ' ';
  LogBegin := BegStr;
  LogEnd := EndStr;
  isOpen := False;
  isLogline := False;
end;

{************************************************************************}
{* Metod:       Done (destrukt”r)                                       *}
{************************************************************************}
{* Inneh†ll:    St„nger den eventuellt ”ppna loggfilen                  *}
{* Definition:  Destructor LogFile.Done;                                *}
{************************************************************************}
Destructor LogFile.Done;
Begin
  If isOpen then begin
    LogLine('+');
    LogStr(LogEnd + Title);
    LogLn;
    Close(Log);
  end;
end;

{************************************************************************}
{* Metod:       OpenLog                                                 *}
{************************************************************************}
{* Inneh†ll:    ™ppnar en loggfil f”r skrivning                         *}
{* Definition:  Function LogFile.Openlog(FileName: String): Boolean;    *}
{************************************************************************}
Function LogFile.Openlog(FileName: String): Boolean;
Begin
  If isOpen then begin                          { redan ”ppen? }
    Openlog := False;
  end else begin
{$I-}
    Assign(Log, FileName);
    Append(Log);
    If IoResult <> 0 then begin                 { fanns den inte? }
      Rewrite(Log);
      If IoResult <> 0 then begin
        Openlog := False;
        Exit;
      end;
    end;
{$I+}
    isOpen := True;
    Writeln(Log);
    LogLine('+');
    LogStr(LogBegin + Title);
    LogLn;
    Openlog := True;
  end;
end;

{************************************************************************}
{* Metod:       LogLine                                                 *}
{************************************************************************}
{* Inneh†ll:    P†b”rjar loggning av ny rad, med datum och loglevel     *}
{* Definition:  Function LogFile.LogLine(LogLevel: Char): LogFilePointer;}
{************************************************************************}
Function LogFile.LogLine(LogLevel: Char): LogFilePointer;
Begin
  If isOpen and not isLogLine then begin
    Write(Log, LogLevel, ' ', LogTime, LogTitle);
    isLogLine := True;
  end;
  LogLine := @Self;
end;

{************************************************************************}
{* Metod:       LogStr                                                  *}
{************************************************************************}
{* Inneh†ll:    Loggar en str„ng                                        *}
{* Definition:  Function LogFile.LogStr(TextString: String):            *}
{*              LogFilePointer;                                         *}
{************************************************************************}
Function LogFile.LogStr(TextString: String): LogFilePointer;
Begin
  If isOpen and isLogLine then begin
    Write(Log, TextString);
  end;
  LogStr := @Self;
end;

{************************************************************************}
{* Metod:       LogInt                                                  *}
{************************************************************************}
{* Inneh†ll:    Loggar ett heltalsv„rde                                 *}
{* Definition:  Function LogFile.LogInt(IntegerData: LongInt):          *}
{*              LogFilePointer;                                         *}
{************************************************************************}
Function LogFile.LogInt(IntegerData: LongInt): LogFilePointer;
Begin
  If isOpen and isLogLine then begin
    Write(Log, IntegerData);
  end;
  LogInt := @Self;
end;

{************************************************************************}
{* Metod:       LogLn                                                   *}
{************************************************************************}
{* Inneh†ll:    Avslutar loggning av en rad                             *}
{* Definition:  Procedure LogFile.LogLn;                                *}
{************************************************************************}
Procedure LogFile.LogLn;
Begin
  if isOpen and isLogLine then begin
    Writeln(Log);
    isLogLine := False;
  end;
end;

end.
