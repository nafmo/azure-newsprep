{ Prepare FidoNews for posting via Announcer

  Newsprep history:
  v1.0 - 1996-09-03 -
  v1.01- 1997-01-14 - More FixedWidth
  v1.07- 1997-04-15 - Changed subject line format
  v1.08- 1997-07-13 - Removes indentation / Announcer IDSERVER

  Sweprep history:
  v1.02- 1997-01-18 - Closes OutFile
  v1.03- 1997-01-20 - More FixedWidth
  v1.04- 1997-02-03 - Handles PGP signature
  v1.05- 1997-02-07 - More FixedWidth
  v1.06- 1997-03-08 - Skips ASCII 01
  v1.07- 1997-04-15 - Changed subject line format
  v1.08- 1997-07-12 - Removes indentation / Announcer IDSERVER
  v1.08.1    -07-16 - More FixedWidth

  Joined history:
  v2.0 - 1997-07-17 - One file per section, not per page
                    - merged NewsPrep and SwePrep to one source file
  v2.01- 1997-07-22 - [s version only] Fixed problems with PGP signature
                    - fixes problem with '-' in section headline
  v2.02- 1997-07-27 - Fixes problem with size count of empty lines
  v2.03- 1997-09-23 - Fixes problem with ten parts (was shown as xx/ 9)       }


Program NewsPrep;

Uses Dos;

Const
  {$IFDEF INTL}
  Indentation = 6;
  Version = '2.03i';
  Source = 'FIDO*.NWS';
  {$ENDIF}{$IFDEF SWE}
  Version = '2.03s';
  Source = 'SFNEWS*.*';
  {$ENDIF}
  Copyright = '1996-1997 Peter Karlsson';
  NewsPath = 'C:\DEV\PAS\SRC\UTIL\NEWSPREP\';
  TempPath = 'G:\TEMP\';
  MsgBase = 'SD:\MAIL\SQUISH\FIDO\R20\FNEWS';
  EchoTossLog = 'D:\MAIL\PRG\SQUISH\ECHOTOSS.LOG';
  LogFile = 'C:\DEV\PAS\SRC\UTIL\NEWSPREP\ANNOUNCE.LOG';
  IdServer = 'C:\DEV\PAS\SRC\UTIL\NEWSPREP\';
  Orig = '2:206/221.2';

Var
  S: SearchRec;
  FidoNews, OutFile: Text;
  Parts: Word;
  TextLine, TmpStr, TopLine, PartsString: String;
  GotTopLine, StartOfWord: Boolean;
  i, j: Word;
  Titles: Array[1..128] of string;
  Size: Word;
  {$IFDEF SWE}
  Indentation: Byte;
  {$ENDIF}
Begin
  FindFirst(NewsPath + Source, AnyFile - VolumeId, S);
  If DosError <> 0 then begin
    Writeln('File not found, ' + NewsPath + Source);
    Halt(1);
  end;
  Assign(FidoNews, NewsPath + S.Name);
  Reset(FidoNews);
  Parts := 1;
  Str(Parts, TmpStr);
  Assign(OutFile, TempPath + TmpStr + '.TMP');
  Rewrite(OutFile);
  GotTopLine := False;
  Size := 0;
  {$IFDEF SWE}
  Indentation := 0;
  {$ENDIF}
  For i := 1 to 128 do
    Titles[i][0] := #0;
  While not eof(FidoNews) do begin
    Readln(FidoNews, TextLine);
    {$IFDEF SWE}
    If TextLine = '-----BEGIN PGP SIGNED MESSAGE-----' then begin
      Readln(FidoNews, TextLine); { Skippa tomrad }
      Readln(FidoNews, TextLine);
    end;
    If TextLine = '-----BEGIN PGP SIGNATURE-----' then begin
      While not eof(FidoNews) and (TextLine <> '-----END PGP SIGNATURE-----') do
        Readln(FidoNews, TextLine);
      If TextLine = '-----END PGP SIGNATURE-----' then
        TextLine := '';
    end;
    {$ENDIF}
    If Not GotTopLine then begin
      GotTopLine := True;
      i := Pos('Volume ', TextLine);
      j := Pos(', Number ', TextLine);
      TopLine := {$IFDEF SWE} 'Sv ' + {$ENDIF} 'FidoNews ' +
                 Copy(TextLine, i + 7, j - i - 7) { ÜrgÜng } + ':' +
                 Copy(TextLine, j + 9, 2);
      if TopLine[Length(TopLine)] = ' ' then
        Dec(Topline[0]);
      Titles[1] := {$IFDEF INTL} 'The Front Page'; {$ENDIF}
                   {$IFDEF SWE}  'Framsidan';      {$ENDIF}
    end;
    {$IFDEF INTL}
    If TextLine[1] = #12 then begin
    {$ENDIF}
    {$IFDEF SWE}
    If TextLine[1] = #1 then begin
      Indentation := 6;
    {$ENDIF}
      For i := 1 to 3 do
        Readln(FidoNews, TextLine);
      If TextLine = '     ================================================================='
      then begin
        Close(OutFile);
        Inc(Parts);
        Str(Parts, TmpStr);
        Assign(OutFile, TempPath + TmpStr + '.TMP');
        Rewrite(OutFile);
        Size := Length(TextLine) - Indentation + 1;
        Writeln(OutFile, Copy(TextLine, Indentation, 80));
        Readln(FidoNews, TextLine);
        StartOfWord := True;
        i := 1;
        While (TextLine[i] = ' ') do
          Inc(i);
        Titles[Parts] := Copy(TextLine, i, 80);
        For i := 1 to length(Titles[Parts]) do begin
          If ((Titles[Parts][i] < 'A') or (Titles[Parts][i] > 'Z'))
             and (Titles[Parts][i] <> 'è') and (Titles[Parts][i] <> 'é')
             and (Titles[Parts][i] <> 'ô') and (Titles[Parts][i] <> '-') then
            StartOfWord := True
          else If StartOfWord then
            StartOfWord := False
          else
            Case Titles[Parts][i] of { Omvandla till gemener }
              'A'..'Z': Titles[Parts][i] := Char(Byte(Titles[Parts][i]) or 32); { gemener }
              'è': Titles[Parts][i] := 'Ü';
              'é': Titles[Parts][i] := 'Ñ';
              'ô': Titles[Parts][i] := 'î';
            end;
        end;
        Writeln(Parts, ': ', Titles[Parts]);
      end;
    end else If Size > 15000 then begin { Dela }
      Close(OutFile);
      Inc(Parts);
      Str(Parts, TmpStr);
      Assign(OutFile, TempPath + TmpStr + '.TMP');
      Rewrite(OutFile);
      Titles[Parts] := Titles[Parts - 1];
      Size := 0;
    end;
    TextLine := Copy(TextLine, Indentation, 80);
    Writeln(OutFile, TextLine);
    Inc(Size, Length(TextLine) + 1);
  end;
  Writeln(OutFile);
  Writeln(OutFile, '** Prepared for R20_FNEWS by NewsPrep ', Version);
  Writeln(OutFile, '   (c) Copyright ', Copyright);
  Close(OutFile);

  Close(FidoNews);
  Erase(FidoNews);

  Writeln(TopLine);

  Str(Parts - 1:2, PartsString);
  If Parts <= 10 then
    PartsString[1] := '0';

  Assign(OutFile, TempPath + 'ANNOUNCE.INI');
  Rewrite(OutFile);
  Writeln(OutFile, 'LogFile ' + LogFile);
  Writeln(OutFile, 'EchoTossLog ' + EchoTossLog);
  Writeln(OutFile, 'ReplyKludge No');
  Writeln(OutFile, 'IdServer ' + IdServer);
  For i := 1 to Parts do begin
    Writeln(OutFile, 'MSG');
    Writeln(OutFile, 'From FidoNews Robot');
    Writeln(OutFile, 'To All');
    Str(i - 1:2, TmpStr);
    If i < 11 then
      TmpStr[1] := '0';
    Writeln(OutFile, 'Subject ', TopLine, ' [', TmpStr, '/', PartsString,
            ']: ', Titles[i]);
    If i = 1 then begin
      Writeln(OutFile, 'FixedWidth Yes');
    end else begin
      {$IFDEF INTL}
      If (Titles[i] = 'Comix In Ascii') or
         (Titles[i] = 'Fidonet Software Listing') or
         (Titles[i] = 'Coordinators Corner') then
      {$ENDIF}{$IFDEF SWE}
      If (Titles[i] = 'Fidonet-statistik') or
         (Titles[i] = 'Ascii-konst') or
         (Titles[i] = 'Fidonet-bosslistan') then
      {$ENDIF}
        Writeln(OutFile, 'FixedWidth Yes');
    end;
    Writeln(OutFile, 'Path ' + MsgBase);
    Writeln(OutFile, 'File ' + TempPath, i, '.TMP');
    Writeln(OutFile, 'Distribution EchoMail');
    Writeln(OutFile, 'Echo R20_FNEWS');
    Writeln(OutFile, 'Orig ' + Orig);
    Writeln(OutFile, 'Origin FidoNews');
    {$IFDEF INTL}
    Writeln(OutFile, 'Charset ASCII');
    {$ENDIF}
    Writeln(OutFile, '.END');
  end;
  Close(OutFile);
End.


