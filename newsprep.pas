{************************************************************************}
{* Program:     Azure/NewsPrep                                          *}
{************************************************************************}
{* Author:      Peter Karlsson, Copyright 1996-1999                     *}
{* Version:     3.0                                                     *}
{************************************************************************}
{* Modules:     NewsPrep.Pas                                            *}
{*              PktHead.Pas [from "Announcer", GPL]                     *}
{*              StrUtil.Pas [from "Announcer", GPL]                     *}
{*              LogFileU.Pas [from "Announcer", GPL]                    *}
{*              NLS.Pas from "ADir" by Thomas Mainka (see README)       *}
{*              MsgIdU.Pas [from "Announcer", GPL]                      *}
{*               +- MkMisc.Pas by Mythical Kingdom Software (see README)*}
{*               +- CRC32.Pas also by Mythical Kingdom Software ( -"- ) *}
{************************************************************************}
{************************************************************************}
{* Module:      Announce.Pas                                            *}
{************************************************************************}
{* Contents:    NewsPrep's main program                                 *}
{************************************************************************}
{* Function:    Creates a PKT file containing a FidoNews issue          *}
{************************************************************************}
{* This program is free software; you can redistribute it and/or modify *}
{* it under the terms of the GNU General Public License version 2 as    *}
{* published by the Free Software Foundation.                           *}
{*                                                                      *}
{* This program is distributed in the hope that it will be useful,      *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of       *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        *}
{* GNU General Public License for more details.                         *}
{*                                                                      *}
{* You should have received a copy of the GNU General Public License    *}
{* along with this program; if not, write to the Free Software          *}
{* Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.            *}
{*                                                                      *}
{*                                                                      *}
{* As I am somewhat uncertain whether the GNU GPL is compatible with    *}
{* the licenses of the other sources I have used here, I here           *}
{* explicitly allows the linking of this program with the routines      *}
{* NLS.Pas, MkMisc.Pas and CRC32.Pas as mentioned above.                *}
{************************************************************************}
{* Routines:    PaseFido                                                *}
{*              ToStr                                                   *}
{*              Exists                                                  *}
{*              main                                                    *}
{************************************************************************}
{* Revisions:                                                           *}
{* Newsprep history:                                                    *}
{* v1.0 - 1996-09-03 -                                                  *}
{* v1.01- 1997-01-14 - More FixedWidth                                  *}
{* v1.07- 1997-04-15 - Changed subject line format                      *}
{* v1.08- 1997-07-13 - Removes indentation / Announcer IDSERVER         *}
{*                                                                      *}
{* Sweprep history:                                                     *}
{* v1.02- 1997-01-18 - Closes OutFile                                   *}
{* v1.03- 1997-01-20 - More FixedWidth                                  *}
{* v1.04- 1997-02-03 - Handles PGP signature                            *}
{* v1.05- 1997-02-07 - More FixedWidth                                  *}
{* v1.06- 1997-03-08 - Skips ASCII 01                                   *}
{* v1.07- 1997-04-15 - Changed subject line format                      *}
{* v1.08- 1997-07-12 - Removes indentation / Announcer IDSERVER         *}
{* v1.08.1    -07-16 - More FixedWidth                                  *}
{*                                                                      *}
{* Second rewrite, joined NewsPrep and SwePrep:                         *}
{* v2.0 - 1997-07-17 - One file per section, not per page               *}
{*                   - merged NewsPrep and SwePrep to one source file   *}
{* v2.01- 1997-07-22 - [s version only] Fixed problems with PGP         *}
{*                     signature                                        *}
{*                   - fixes problem with '-' in section headline       *}
{* v2.02- 1997-07-27 - Fixes problem with size count of empty lines     *}
{* v2.03- 1997-09-23 - Fixes problem with ten parts (was shown as xx/ 9)*}
{* v2.04- 1998-01-10 - Strips Origin lines                              *}
{*                   - Issues with numbers less than 10 now gets a 0    *}
{*                     inserted                                         *}
{* v2.05- 1998-03-18 - Handles PGP keys in Int'l FidoNews too           *}
{* v2.06- 1998-10-22 - New header in Int'l FidoNews                     *}
{*                                                                      *}
{* Third rewrite, the independent, configurable, shareable version:     *}
{* v3.00- 1999-02-04 - Outputs PKT files, and reads a config file       *}
{************************************************************************}

Program NewsPrep;

{ $Id: NEWSPREP.PAS 2.2 1999/02/09 07:19:36 peter Exp $ }

Uses Dos, PktHead, StrUtil, LogFileU, NLS, MsgIdU;

Const
  Version = '3.0';
  VerMaj = 3;
  VerMin = 0;
  Copyright = '1996-1999 Peter Karlsson';
  Digits: Array[0..9] of Char = '0123456789';
  Months: Array[0..11] of String =
    ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  mTo: Array[0..3] of Char = 'All'#0;
  From: Array[0..14] of Char = 'FidoNews Robot'#0;
  Fixed: Array[0..10] of Char = #1'FLAGS NPD'#13;
  Chrs: Array[0..14] of Char = #1'CHRS: IBMPC 2'#13;
  Null: Char = #0;

Var
  Indentation:    Byte;
  Indentation2:   Byte;
  Source:         String;
  SourcePath:     String;
  TempPath:       String;
  LogFile:        String;
  IdServer:       String;
  Dest:           String;
  PktPwd:         String;
  Inbound:        String;
  FrontTitle:     String;
  Echo:           String;
  Name:           String;
  Orig:           String;
  Origin:         String;
  OZ, ON, OS, OP: Word;
  DZ, DN, DS, DP: Word;
  UseTear:        Boolean;

{************************************************************************}
{* Routine:     WithSlash                                               *}
{************************************************************************}
{* Contents:    Adds a backslash to the path if it doesn't already end  *}
{*              with one.                                               *}
{* Definition:  Function WithSlash(S: String): String;                  *}
{************************************************************************}
Function WithSlash(S: String): String;
Begin
  If S[Length(s)] = '\' then
    WithSlash := S
  else
    WithSlash := S + '\';
End;

{************************************************************************}
{* Routine:     ParseFido                                               *}
{************************************************************************}
{* Contents:    Parses a 4D FidoNet address into its components         *}
{* Definition:  Procedure ParseFido(A: String; Var Z, N, S, P: Word);   *}
{************************************************************************}
Procedure ParseFido(A: String; Var Z, N, S, P: Word);
Var P1, P2, P3: Byte;
  Tmp: Integer;
Begin
  P1 := Pos(':', A);
  P2 := Pos('/', A);
  P3 := Pos('.', A);
  If (P1 = 0) or (P2 = 0) or (P3 = 0) then begin
    Writeln('Malformed address: ', A);
    Halt(1);
  end;
  Val(Copy(A, 1, P1 - 1), Z, Tmp);
  Val(Copy(A, P1 + 1, P2 - P1 - 1), N, Tmp);
  Val(Copy(A, P2 + 1, P3 - P2 - 1), S, Tmp);
  Val(Copy(A, P3 + 1, Length(A) - P3 - 1), P, Tmp);
End;

{************************************************************************}
{* Routine:     ToStr                                                   *}
{************************************************************************}
{* Contents:    Converts an integer to a string                         *}
{* Definition:  Function ToStr(i: Integer): String;                     *}
{************************************************************************}
Function ToStr(i: Integer): String;
Var S: String;
Begin
  Str(i, S);
  ToStr := S;
End;

{************************************************************************}
{* Routine:     Exists                                                  *}
{************************************************************************}
{* Contents:    Check if a file exists                                  *}
{* Definition:  Function Exists(Var S: String): Boolean;                *}
{************************************************************************}
Function Exists(Var S: String): Boolean;
Var F: File;
Begin
  {$I-}
  Assign(F, S);
  Reset(F);
  Close(F);
  If IOResult = 0 then
    Exists := True
  else
    Exists := False;
  {$I+}
End;

{************************************************************************}
{* Routine:     main                                                    *}
{************************************************************************}
{* Contents:    Does too much                                           *}
{* Definition:  -                                                       *}
{************************************************************************}
Var
  S:                                            SearchRec;
  IniFile, FidoNews, OutFile, TmpFile:          Text;
  PktFile:                                      File;
  Parts:                                        Word;
  TextLine, TmpStr, TopLine, PartsString:       String;
  IniString, Keyword, Data:                     String;
  DateStr, PktFileName:                         String;
  GotTopLine, GotIssueNumber, StartOfWord:      Boolean;
  i, j:                                         Word;
  Titles:                                       Array[1..128] of string;
  Size:                                         Word;
  Log:                                          LogFilePointer;
  PktHead_p:                                    ^PKTheader;
  PktMsg_p:                                     ^PkdMSG;
  MsgId:                                        MsgIdServPointer;
  C:                                            Char;
  MsgIdNum, PktNum, FirstMsgId:                 LongInt;
Begin
  { Open and parse configuration file }
  {$I-}
  Assign(IniFile, InSameDir(ParamStr(0), 'NEWSPREP.INI'));
  Reset(IniFile);
  If IOResult <> 0 then begin
    Writeln('File not found, ', InSameDir(ParamStr(0), 'NEWSPREP.INI'));
    Halt(1);
  end;
  {$I+}
  UseTear := True;
  While not eof(IniFile) do begin
    Readln(IniFile, IniString);
    if (Length(IniString) > 0) and (IniString[0] <> ';') then begin
      If ParseIni(IniString, Keyword, Data) then begin
        If Keyword = 'INDENTATION' then begin
          Val(Data, Indentation2, i);
        end else If Keyword = 'FRONTPAGEINDENTATION' then begin
          Val(Data, Indentation, i);
        end else If Keyword = 'SOURCE' then begin
          Source := Data;
        end else If Keyword = 'SOURCEPATH' then begin
          SourcePath := WithSlash(Data);
        end else If Keyword = 'TEMPPATH' then begin
          TempPath := WithSlash(Data);
        end else If Keyword = 'LOGFILE' then begin
          LogFile := Data;
        end else If Keyword = 'IDSERVER' then begin
          IdServer := WithSlash(Data);
        end else If Keyword = 'ORIG' then begin
          ParseFido(Data, OZ, ON, OS, OP);
          Orig := Data;
        end else If Keyword = 'DEST' then begin
          ParseFido(Data, DZ, DN, DS, DP);
        end else If Keyword = 'PASSWORD' then begin
          If UpStr(Data) = 'NONE' then
            PktPwd := ''
          else
            PktPwd := Data;
        end else If Keyword = 'INBOUND' then begin
          Inbound := WithSlash(Data);
        end else If Keyword = 'FRONTPAGE' then begin
          FrontTitle := Data;
        end else if Keyword = 'ECHO' then begin
          Echo := Data;
        end else if Keyword = 'NAME' then begin
          Name := Data;
        end else if Keyword = 'ORIGIN' then begin
          If UpStr(Data) = 'NONE' then
            Origin := ''
          else
            Origin := Data + ' ';
        end else if Keyword = 'USETEAR' then begin
          If UpCase(Data[1]) = 'Y' then
            UseTear := True
          else
            UseTear := False;
        end;
      end;
    end;
  end;
  Close(IniFile);

  { Open logfile }
  New(Log, Init('Azure/NewsPrep ' + Version, 'NPRP', 'Begin, ', 'End, '));
  Log^.OpenLog(LogFile);

  { Open and partition FidoNews file }
  FindFirst(SourcePath + Source, AnyFile - VolumeId, S);
  If DosError <> 0 then begin
    Writeln('File not found, ' + SourcePath + Source);
    Log^.LogLine('!')^.LogStr('Unable to find ' + SourcePath + Source)^.LogLn;
    Dispose(Log, Done);
    Halt(1);
  end;
  Assign(FidoNews, SourcePath + S.Name);
  Reset(FidoNews);
  Log^.LogLine('+')^.LogStr('Opened ' + SourcePath + S.Name)^.LogLn;

  Parts := 1;
  Str(Parts, TmpStr);
  Assign(OutFile, TempPath + TmpStr + '.TMP');
  Rewrite(OutFile);
  GotTopLine := False;
  GotIssueNumber := False;
  Size := 0;
  For i := 1 to 128 do
    Titles[i][0] := #0;
  Titles[1] := FrontTitle;
  While not eof(FidoNews) do begin
    Readln(FidoNews, TextLine);
    If Pos('-----BEGIN PGP SIGNED MESSAGE-----', TextLine) > 0 then begin
      Readln(FidoNews, TextLine); { Skip empty line }
      Readln(FidoNews, TextLine);
    end;
    If Pos('-----BEGIN PGP SIGNATURE-----', TextLine) > 0 then begin
      While not eof(FidoNews) and
            (Pos('-----END PGP SIGNATURE-----', TextLine) = 0) do
        Readln(FidoNews, TextLine);
      If Pos('-----END PGP SIGNATURE-----', TextLine) > 0 then
        TextLine := '';
    end;
    If Not GotTopLine then begin
      GotTopLine := True;
      i := Pos('Volume ', TextLine);
      j := Pos(', Number ', TextLine);
      If (i = 0) or (j = 0) Then
        GotIssueNumber := False
      else begin
        GotIssueNumber := True;
        If TextLine[j + 9] = ' ' then TextLine[j + 9] := '0';
        TopLine := Name + ' '+
                   Copy(TextLine, i + 7, j - i - 7) { ÜrgÜng } + ':' +
                   Copy(TextLine, j + 9, 2);
        If TopLine[Length(TopLine)] = ' ' then
          Dec(Topline[0]);
        Log^.LogLine(' ')^.LogStr('This is ' + TopLine)^.LogLn;
      end;
    end;
    If (TextLine[1] = #12) or (TextLine[1] = #1) then begin
      If (TextLine[1] = #12) then begin
        If (Not GotIssueNumber) then begin
          i := Pos('FIDONEWS ', TextLine);
          j := Pos('-', TextLine);
          TopLine := 'FidoNews ' +
                     Copy(TextLine, i + 9, j - i - 9) { ÜrgÜng } + ':' +
                     Copy(TextLine, j + 1, 2);
          If TopLine[Length(TopLine)] = ' ' then
            Dec(Topline[0]);
          GotIssueNumber := True;
        end;
      end;
      Indentation := Indentation2;
      For i := 1 to 3 do begin
        Readln(FidoNews, TextLine);
        If TextLine = '     -----BEGIN PGP SIGNATURE-----' then begin
          While not eof(FidoNews) and (TextLine <> '     -----END PGP SIGNATURE-----') do
            Readln(FidoNews, TextLine);
          If TextLine = '     -----END PGP SIGNATURE-----' then
            TextLine := '';
        end;
        If TextLine = '     =================================================================' then
          i := 3;
      end;
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
            Case Titles[Parts][i] of { Change to lowercase }
              'A'..'Z': Titles[Parts][i] := Char(Byte(Titles[Parts][i]) or 32); { gemener }
              'è': Titles[Parts][i] := 'Ü'; { Swedish }
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
   {If Copy(TextLine, 1, 4) = '--- '        then TextLine[2] := '+';}
    If Copy(TextLine, 1, 11)= ' * Origin: ' then TextLine[2] := '+';
    Writeln(OutFile, TextLine);
    Inc(Size, Length(TextLine) + 1);
  end;

  { Commercial blurb }
  Writeln(OutFile);
  Writeln(OutFile, '** Prepared for ', Echo, ' by Azure/NewsPrep ', Version);
  Writeln(OutFile, '   (c) Copyright ', Copyright);
  Close(OutFile);

  { We're done with the input, close and delete }
  Close(FidoNews);
  {$I-}
  Erase(FidoNews);
  If IOResult = 0 then
    Log^.LogLine('+')^.LogStr('Removed ' + SourcePath + S.Name)^.LogLn
  else
    Log^.LogLine('-')^.LogStr('Unable to remove ' + SourcePath +
                              S.Name)^.LogLn;
  {$I+}
  Log^.LogLine(' ')^.LogInt(Parts)^.LogStr(' sections')^.LogLn;

  Writeln(TopLine);

  Str(Parts - 1:2, PartsString);
  If Parts <= 10 then
    PartsString[1] := '0';

  { Open MSGID server }
  New(MsgId, Init(IdServer));
  MsgIdNum := MsgId^.GetSerial(Parts); { Allocate MSGIDs }
  FirstMsgId := MsgIdNum;
  Dispose(MsgId);

  { Write output }
  PktNum := MsgIdNum - 1;
  Repeat
    Inc(PktNum);
    PktFileName := Inbound + LongWord(MsgIdNum) + '.PKT';
  Until Not Exists(PktFileName); { Ensure uniqueness of PKT file name }

  Assign(PktFile, PktFileName);
  Rewrite(PktFile, 1);
  Log^.LogLine('+')^.LogStr('Creating ' + PktFileName)^.LogLn;
  New(PktHead_p);
  New(PktMsg_p);

  { Create PKT header }
  FillChar(PktHead_p^, SizeOf(PKTHeader), #0);
  With PktHead_p^ do begin
    QOrgZone := OZ;
    OrgZone := OZ;
    OrgNet := ON;
    OrgNode := OS;
    OrgPoint := OP;
    QDstZone := DZ;
    DstZone := DZ;
    DstNet := DN;
    DstNode := DS;
    DstPoint := DP;
    GetDate(Year, Month, Day, i);
    Dec(Month); { Adjust month number to 0-11 }
    GetTime(Hour, Min, Sec, i);
    PktVer := 2;
    PrdCodL := $fe; { No product ID allocated }
    CapValid := $100;
    CapWord := $1;
    PVMinor := VerMin; { Version }
    PVMajor := VerMaj;
    If Length(PktPwd) > 0 then
      For i := 0 to Length(PktPwd) - 1 do
        Password[i] := PktPwd[i + 1];
    { Create date string }
    { Format: Dd Mmm Yy  HH:MM:SS }
    DateStr := Digits[Day  div 10] + Digits[Day  mod 10] + ' ' +
               Months[Month] + ' ' +
               Digits[(Year div 10) mod 10] + Digits[Year mod 10] + '  ' +
               Digits[Hour div 10] + Digits[Hour mod 10] + ':' +
               Digits[Min  div 10] + Digits[Min  mod 10] + ':' +
               Digits[Sec  div 10] + Digits[Sec  mod 10];
  end; { With PktHead_p^ }
  BlockWrite(PktFile, PktHead_p^, SizeOf(PktHeader));

  For i := 1 to Parts do begin
    FillChar(PktMsg_p^, SizeOf(PkdMSG), #0);
    With PktMsg_p^ do begin
      PktVer := $2;
      OrgNode := OS;
      DstNode := DS;
      OrgNet := ON;
      DstNet := DN;
      For j := 0 to 19 do
        DateTime[j] := DateStr[j + 1];
    end; { With PktMsg_p^ }
    BlockWrite(PktFile, PktMsg_p^, SizeOf(PkdMsg));
    { To }
    BlockWrite(PktFile, mTo, SizeOf(mTo));
    { From }
    BlockWrite(PktFile, From, SizeOf(From));
    { Subject }
    Str(i - 1:2, TmpStr);
    If i < 11 then
      TmpStr[1] := '0';
    TmpStr := TopLine + ' [' + TmpStr + '/' + PartsString + ']: ' +
              Titles[i] + #0;
    For j := 1 to Length(TmpStr) do
      BlockWrite(PktFile, TmpStr[j], 1);
    Log^.LogLine(' ')^.LogStr('Message: ' + TmpStr)^.LogLn;
    { Area }
    TmpStr := 'AREA:' + Echo + #13;
    For j := 1 to Length(TmpStr) do
      BlockWrite(PktFile, TmpStr[j], 1);

    { Kludges }
    { FLAGS }
    If (i = 1) or
       (Titles[i] = 'Comix In Ascii') or
       (Titles[i] = 'Fidonet Software Listing') or
       (Titles[i] = 'Coordinators Corner') or
       (Titles[i] = 'Fidonet-statistik') or
       (Titles[i] = 'Ascii-konst') or
       (Titles[i] = 'Fidonet-bosslistan') then
      BlockWrite(PktFile, Fixed, SizeOf(Fixed));

    { MSGID }
    TmpStr := #1'MSGID: ' + Orig + ' ' + LongWord(MsgIdNum) + #13;
    For j := 1 to Length(TmpStr) do
      BlockWrite(PktFile, TmpStr[j], 1);
    Inc(MsgIdNum);

    { REPLY, used in the chapters to point back to the contents }
    If i > 1 then begin
      TmpStr := #1'REPLY: ' + Orig + ' ' + LongWord(FirstMsgId) + #13;
      For j := 1 to Length(TmpStr) do
        BlockWrite(PktFile, TmpStr[j], 1);
    end;

    { CHRS }
    BlockWrite(PktFile, Chrs, SizeOf(Chrs));

    { PID, if tearline is not in use }
    If not UseTear then begin
      TmpStr := #1'PID: Azure/NewsPrep ' + Version + #13;
      For j := 1 to Length(TmpStr) do
        BlockWrite(PktFile, TmpStr[j], 1);
    end;


    { Body }
    Str(i, TmpStr);
    Assign(TmpFile, TempPath + TmpStr + '.TMP');
    Reset(TmpFile);

    While not eof(TmpFile) do begin
      Read(TmpFile, C);
      if (C <> #10) then BlockWrite(PktFile, C, 1);
    end;

    Close(TmpFile);
    Erase(TmpFile);

    { Tear and Origin line }
    If UseTear then
      TmpStr := #13'--- Azure/NewsPrep ' + Version
    else
      TmpStr := '';
    TmpStr := TmpStr + #13' * Origin: ' + Origin + '(' + Orig + ')'#13 +
                       #1'PATH: ' + ToStr(ON) + '/' + ToStr(OS) + #13;
    For j := 1 to Length(TmpStr) do
      BlockWrite(PktFile, TmpStr[j], 1);

    BlockWrite(PktFile, Null, 1);
  end;

  BlockWrite(PktFile, Null, 1);
  BlockWrite(PktFile, Null, 1);

  Dispose(PktHead_p);
  Dispose(PktMsg_p);
  Close(PktFile);

  Log^.LogLine('+')^.LogStr('Created ' + PktFileName)^.LogLn;

  Dispose(Log, Done);
End.


