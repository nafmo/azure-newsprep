{ Prepare Swedish FidoNews for posting via Announcer
  v1.0 - 1996-09-03 -
  v1.0S- 1996-12-12 -
  v1.01S-1996-12-16 - For Swedish FidoNews
  v1.02- 1997-01-18 - Closes OutFile
  v1.03- 1997-01-20 - More FixedWidth
  v1.04- 1997-02-03 - Handles PGP signature
  v1.05- 1997-02-07 - More FixedWidth
  v1.06- 1997-03-08 - Skips ASCII 01
  v1.07- 1997-04-15 - Changed subject line format
  v1.08- 1997-07-12 - Removes indentation / Announcer IDSERVER
  v1.08.1    -07-16 - More FixedWidth                                         }

Program NewsPrep;

Uses Dos;

Const
  Version = '1.08.1s';
  Copyright = '1996-1997 Peter Karlsson';
  NewsPath = 'C:\DEV\PAS\SRC\UTIL\NEWSPREP\';
  TempPath = 'G:\TEMP\';
  MsgBase = 'SD:\MAIL\SQUISH\FIDO\R20\FNEWS';
  EchoTossLog = 'D:\MAIL\PRG\SQUISH\ECHOTOSS.LOG';
  LogFile = 'C:\DEV\PAS\SRC\UTIL\NEWSPREP\ANNOUNCE.LOG';
  IdServer = 'C:\DEV\PAS\SRC\UTIL\NEWSPREP\IDSERVER.DAT';
  Orig = '2:206/221.2';

Var
  S: SearchRec;
  FidoNews, OutFile: Text;
  Parts: Word;
  TextLine, TmpStr, TopLine, PartsString: String;
  NextLineIsTitle, GotTopLine, StartOfWord: Boolean;
  i, j: Word;
  Titles: Array[1..128] of string;
  LinesFromTop, Indentation: Byte;
Begin
  FindFirst(NewsPath + 'SFNEWS*.*', AnyFile - VolumeId, S);
  If DosError <> 0 then begin
    Writeln('File not found, ', NewsPath, 'SFNEWS*.*');
    Halt(1);
  end;
  Assign(FidoNews, NewsPath + S.Name);
  Reset(FidoNews);
  Parts := 1;
  NextLineIsTitle := False;
  Str(Parts, TmpStr);
  Assign(OutFile, TempPath + TmpStr + '.TMP');
  Rewrite(OutFile);
  GotTopLine := False;
  Indentation := 0;
  For i := 1 to 128 do
    Titles[i][0] := #0;
  While not eof(FidoNews) do begin
    Readln(FidoNews, TextLine);
    If TextLine = '-----BEGIN PGP SIGNED MESSAGE-----' then begin
      Readln(FidoNews, TextLine); { Skippa tomrad }
      Readln(FidoNews, TextLine);
    end;
    If TextLine[1] = #1 then
      TextLine[1] := ' ';
    If TextLine = '-----BEGIN PGP SIGNATURE-----' then begin
      While not eof(FidoNews) do { Konsumera hela PGP-signaturen }
        Readln(FidoNews, TextLine);
    end else begin
      If Not GotTopLine then begin
        GotTopLine := True;
        i := Pos('Volume ', TextLine);
        j := Pos(', Number ', TextLine);
        TopLine := 'Sv FidoNews ' + Copy(TextLine, i + 7, j - i - 7) { ÜrgÜng }
                   + ':' + Copy(TextLine, j + 9, 2);
        if TopLine[Length(TopLine)] = ' ' then
          Dec(Topline[0]);
        Titles[1] := 'Framsidan';
      end;
      If NextLineIsTitle then begin
        NextLineIsTitle := False;
        i := 1;
        While (TextLine[i] = ' ') do
          Inc(i);
        Titles[Parts] := Copy(TextLine, i, 80);

        StartOfWord := True;
        For i := 1 to length(Titles[Parts]) do begin
          If ((Titles[Parts][i] < 'A') or (Titles[Parts][i] > 'Z'))
             and (Titles[Parts][i] <> 'è') and (Titles[Parts][i] <> 'é')
             and (Titles[Parts][i] <> 'ô') and (Titles[Parts][i] <> '-') then
            StartOfWord := True
          else If StartOfWord then
            StartOfWord := False
          else begin
            Case Titles[Parts][i] of
              'A'..'Z': Titles[Parts][i] := Char(Byte(Titles[Parts][i]) or 32); { gemener }
              'è': Titles[Parts][i] := 'Ü';
              'é': Titles[Parts][i] := 'Ñ';
              'ô': Titles[Parts][i] := 'î';
            end;
          end;
        end;
        Writeln(Parts, ': ', Titles[Parts]);
      end;
      If (Parts > 1) and (LinesFromTop <= 2) and
         (Pos('==============================================================',
              TextLine) <> 0) then
        NextLineIsTitle := True;
      Inc(LinesFromTop);
      If TextLine[1] = #12 then begin
        Indentation := 6;
        Close(OutFile);
        LinesFromTop := 0;
        TextLine := Copy(TextLine, 2, 80);
        If Length(TextLine) > 1 then begin
          Inc(Parts);
          Str(Parts, TmpStr);
          Assign(OutFile, TempPath + TmpStr + '.TMP');
          Rewrite(OutFile);
          Writeln(OutFile, Copy(TextLine, Indentation, 80));
          Titles[Parts] := Titles[Parts - 1];
        end;
      end else
        Writeln(OutFile, Copy(TextLine, Indentation, 80));
    end; { If signature }
  end;
  Writeln(OutFile);
  Writeln(OutFile, '** Prepared for R20_FNEWS by NewsPrep ', Version);
  Writeln(OutFile, '   (c) Copyright ', Copyright);
  Close(OutFile);

  Close(FidoNews);
  Erase(FidoNews);

  Writeln(TopLine);

  Str(Parts - 1:2, PartsString);
  If Parts < 10 then
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
      If (Titles[i] = 'Fidonet-statistik') or (Titles[i] = 'Ascii-konst') or
         (Titles[i] = 'Fidonet-bosslistan') then
        Writeln(OutFile, 'FixedWidth Yes');
    end;
    Writeln(OutFile, 'Path ' + MsgBase);
    Writeln(OutFile, 'File ' + TempPath, i, '.TMP');
    Writeln(OutFile, 'Distribution EchoMail');
    Writeln(OutFile, 'Echo R20_FNEWS');
    Writeln(OutFile, 'Orig ' + Orig);
    Writeln(OutFile, 'Origin FidoNews');
    Writeln(OutFile, '.END');
  end;
  Close(OutFile);
End.


