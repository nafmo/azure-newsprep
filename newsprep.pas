{ Prepare FidoNews for posting via Announcer
  v1.0 - 1996-09-03 -
  v1.01- 1997-01-14 - More FixedWidth
  v1.07- 1997-04-15 - Changed subject line format
  v1.08- 1997-07-22 - Removes indentation / Announcer IDSERVER                }

Program NewsPrep;

Uses Dos;

Const
  Indentation = 6;
  Version = '1.08i';
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
  LinesFromTop: Byte;
Begin
  FindFirst(NewsPath + 'FIDO*.NWS', AnyFile - VolumeId, S);
  If DosError <> 0 then begin
    Writeln('File not found, ', NewsPath, 'FIDO*.NWS');
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
  For i := 1 to 128 do
    Titles[i][0] := #0;
  While not eof(FidoNews) do begin
    Readln(FidoNews, TextLine);
    If Not GotTopLine then begin
      GotTopLine := True;
      i := Pos('Volume ', TextLine);
      j := Pos(', Number ', TextLine);
      TopLine := 'FidoNews ' + Copy(TextLine, i + 7, j - i - 7) { †rg†ng }
                 + ':' + Copy(TextLine, j + 9, 2);
      if TopLine[Length(TopLine)] = ' ' then
        Dec(Topline[0]);
      Titles[1] := 'The Front Page';
    end;
    If NextLineIsTitle then begin
      NextLineIsTitle := False;
      i := 1;
      While (TextLine[i] = ' ') do
        Inc(i);
      Titles[Parts] := Copy(TextLine, i, 80);

      StartOfWord := True;
      For i := 1 to length(Titles[Parts]) do begin
        If (Titles[Parts][i] < 'A') or (Titles[Parts][i] > 'Z') then
          StartOfWord := True
        else If StartOfWord then
          StartOfWord := False
        else
          Titles[Parts][i] := Char(Byte(Titles[Parts][i]) or 32); { gemener }
      end;
      Writeln(Parts, ': ', Titles[Parts]);
    end;
    If (Parts > 1) and (LinesFromTop = 2) and
       (Pos('==============================================================',
            TextLine) <> 0) then
      NextLineIsTitle := True;
    Inc(LinesFromTop);
    If TextLine[1] = #12 then begin
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
  end;
  { OutFile „r st„ngd h„r, ”ppna den igen }
  Append(OutFile);
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
  Writeln(OutFile, 'LogFile ', LogFile);
  Writeln(OutFile, 'EchoTossLog ', EchoTossLog);
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
      If (Titles[i] = 'Comix In Ascii') or
         (Titles[i] = 'Fidonet Software Listing') or
         (Titles[i] = 'Coordinators Corner') then
        Writeln(OutFile, 'FixedWidth Yes');
    end;
    Writeln(OutFile, 'Path ', MsgBase);
    Writeln(OutFile, 'File ', TempPath, i, '.TMP');
    Writeln(OutFile, 'Distribution EchoMail');
    Writeln(OutFile, 'Echo R20_FNEWS');
    Writeln(OutFile, 'Orig ' + Orig);
    Writeln(OutFile, 'Origin FidoNews');
    Writeln(OutFile, 'Charset ASCII');
    Writeln(OutFile, '.END');
  end;
  Close(OutFile);
End.


