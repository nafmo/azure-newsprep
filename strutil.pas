{************************************************************************}
{* Modul:       StrUtil.Pas                                             *}
{************************************************************************}
{* Inneh†ll:    Str„ngutils                                             *}
{************************************************************************}
{* Funktion:    Inneh†ller str„nghanteringsrutiner f”r Announcer        *}
{************************************************************************}
{* Rutiner:     Convert                                                 *}
{*              LogTime                                                 *}
{*              LongWord                                                *}
{*              ParseINI                                                *}
{*              ReadRandomLine                                          *}
{*              RemoveJunk                                              *}
{*              RmUnderline                                             *}
{*              StdoutOn                                                *}
{*              ASCIZ                                                   *}
{*              InSameDir                                               *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.10 - 1996-07-20 - F”rsta versionen                               *}
{*  v1.2  - 1997-04-05 - StdoutOn, ParseINI, YesNo tillagda             *}
{*        - 1997-07-18 - Buggfix i ParseINI                             *}
{*        - 1997-07-21 - ASCIZ                                          *}
{*        - 1997-08-09 - Buggfix i ParseINI (enteckensdata)             *}
{*        - 1997-08-10 - InSameDir                                      *}
{************************************************************************}

Unit StrUtil;

Interface

Type
  CharsetType = (Pc8, Sv7, Iso, Ascii, FromIso, FromSjuBit, FromASCII,
                 IsSjuBit, IsIso);
  CharPointer = ^Char;

Function   ASCIZ          (ch_p: CharPointer): String;
Function   Convert        (str: String; charset: CharsetType): String;
Function   InSameDir      (FullPath, FileName: String): String;
Function   LogTime        : String;
{$IFDEF FPC}
Function   LongWord       (dwrd: Cardinal): String;
{$ELSE}
Function   LongWord       (dwrd: LongInt): String;
{$ENDIF}
Function   ParseINI       (Indata: String; Var Keyword: String; Var Data: String): Boolean;
Function   ReadRandomLine (filename: String): String;
Procedure  RemoveJunk     (Var s: String);
Function   RmUnderline    (instring: String): String;
Procedure  StdoutOn       (TurnOn: Boolean);
Function   YesNo          (s: String): Boolean;
Function   UpStr          (Indata: String): String;

Implementation

Uses Dos{, NLS};

Const
  MonthStr: array[1..12] of string[3] = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  Sjubit: array[#0..#255] of char =
   ( #0, #1, #2, #3, #4, #5, #6, #7, #8, #9,#10,#11,#12,#13,#14,#15,
    #16,#17,#18,#19,#20,#21,#22,#23,#24,#25,#26,#27,#28,#29,#30,#31,
    ' ','!','"','#','$','%','&',#39,'(',')','*','+',',','-','.','/',
    '0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?',
    'a','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',
    'P','Q','R','S','T','U','V','W','X','Y','Z','<','/','>',' ','_',
    #39,'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o',
    'p','q','r','s','t','u','v','w','x','y','z','(','!',')','-',#127,
    'C','~','`','a','{','a','}','c','e','e','e','i','i','i','[',']',
    '@','{','[','o','|','o','u','u','y','\','^','C','l','Y','P','f',
    'a','i','o','u','n','N','a','o','?','-','-','/','/','!','"','"',
    'X','X','X','!','+','+','+','+','+','+','!','+','+','+','+','+',
    '+','+','+','+','-','+','+','+','+','+','+','+','+','-','+','+',
    '+','+','+','+','+','+','+','+','+','+','+','X','X','X','X','X',
    'a','b','G','P','S','s','m','g','F','T','O','d','-','F','(','U',
    '=','+','>','<','S','S','/','=','o','.','.','V','n','2','X',' ');
  AsciiTab: array[#128..#255] of char =
   ('C','u','e','a','a','a','a','c','e','e','e','i','i','i','A','A',
    'E','a','A','o','o','o','u','u','y','O','U','C','l','Y','P','f',
    'a','i','o','u','n','N','a','o','?','-','-','/','/','!','"','"',
    'X','X','X','!','+','+','+','+','+','+','!','+','+','+','+','+',
    '+','+','+','+','-','+','+','+','+','+','+','+','+','-','+','+',
    '+','+','+','+','+','+','+','+','+','+','+','X','X','X','X','X',
    'a','b','G','P','S','s','m','g','F','T','O','d','-','F','(','U',
    '=','+','>','<','S','S','/','=','o','.','.','V','n','2','X',' ');
  IsoTab: array[#128..#255] of char =
   ('Ç','ü','é','â','ä','à','å','ç','ê','ë','è','ï','î','ì','Ä','Å',
    'É','æ','Æ','ô','ö','ò','û','ù','ÿ','Ö','Ü','¢','£','¥','P','ƒ',
    'á','í','ó','ú','ñ','Ñ','ª','º','¿','_','¬','½','¼','¡','«','»',
    'X','X','X','|','+','+','+','+','+','+','|','+','+','+','+','+',
    '+','+','+','+','-','+','+','+','+','+','+','+','+','-','+','+',
    '+','+','+','+','+','+','+','+','+','+','+','X','X','X','X','X',
    'a','ß','G','¶','S','s','µ','g','F','T','O','d','-','ø','(','U',
    '=','±','>','<','S','S','÷','=','°','•','·','V','n','²','•',' ');
  FromIsoTab: array[#128..#255] of char =
   (#128,#129,#130,#131,#132,#133,#134,#135,#136,#137,#138,#139,#140,#141,#142,#143,
    #144,#145,#146,#147,#148,#149,#150,#151,#152,#153,#154,#155,#156,#157,#158,#159,
    ' ','­','›','œ','$','','|',#21,'"','c','¦','®','ª','-','r','-',
    'ø','ñ','ý','3',#39,'æ',#20,'ù',',','1','ø','¯','¬','«','/','¨',
    'A','A','A','A','Ž','','’','€','E','','E','E','I','I','I','I',
    'D','¥','O','O','O','O','™','x','™','U','U','U','š','Y',' ','á',
    '…',' ','ƒ','a','„','†','‘','‡','Š','‚','ˆ','‰','','¡','Œ','‹',
    ' ','¤','•','¢','“','o','”','ö','”','—','£','–','','y',' ','˜');
  FromSjuBitTab: array[#0..#127] of char =
   ( #0, #1, #2, #3, #4, #5, #6, #7, #8, #9,#10,#11,#12,#13,#14,#15,
    #16,#17,#18,#19,#20,#21,#22,#23,#24,#25,#26,#27,#28,#29,#30,#31,
    ' ','!','"','#','$','%','&',#39,'(',')','*','+',',','-','.','/',
    '0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?',
    '','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',
    'P','Q','R','S','T','U','V','W','X','Y','Z','Ž','™','','š','_',
    '‚','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o',
    'p','q','r','s','t','u','v','w','x','y','z','„','”','†','',#127);

Type
  FindPosType = Record
                  Case Byte of
                    0: (Low, High: Word;);
                    1: (Long: LongInt;);
                  end;

{************************************************************************}
{* Routine:     NumStr                                                  *}
{************************************************************************}
{* Inhalt:      Erzeugung eines Ziffern-Strings mit Vornullen           *}
{* Copyright:   Fa. Borland (Beispielprogramm)                          *}
{* Definition:  Function NumStr(N,D:Integer):String;                    *}
{************************************************************************}

Function NumStr(N, D: Integer): String;
Var      HStr      : String;
begin
  HStr[0] := Chr(D);
  while D > 0 do begin
    HStr[D] := Chr(N mod 10 + Ord('0'));
    N := N div 10;
    Dec(D);
  end;
  NumStr := HStr;
end;
{************************************************************************}
{* Rutin:       LogTime                                                 *}
{************************************************************************}
{* Inneh†ll:    Skapar en Squishstyle loggtidsstr„ng                    *}
{* Definition:  Function LogTime: String;                               *}
{************************************************************************}

Function LogTime: String;
Var
  Year, Month, Day, Hour, Min, Sec, Dummy: Word;
Begin
  GetTime(Hour, Min, Sec, Dummy);
  GetDate(Year, Month, Day, Dummy);
  LogTime := NumStr(Day, 2) + ' ' + MonthStr[Month] + ' ' + NumStr(Hour, 2) +
             ':' + NumStr(Min, 2) + ':' + NumStr(Sec, 2)
End;

{************************************************************************}
{* Rutin:       Longword                                                *}
{************************************************************************}
{* Inneh†ll:    Framst„ller en hexadecimalstr„ng                        *}
{* Copyright:   Eddy Jansson <2:206/408>                                *}
{* Definition:  Function LongWord(dwrd: LongInt): String; Assembler;    *}
{************************************************************************}

{$IFDEF FPC}
Function LongWord(dwrd: Cardinal): String;
{$ELSE}
Function LongWord(dwrd: LongInt): String;
{$ENDIF}
{$IFDEF MSDOS}
Assembler;
asm
 push ds
 push cs
 pop  ds
 lea bx,@tabel
 les di,@result
 cld
 mov al,8
 stosb
 mov ax,word ptr dwrd+2
 mov cx,ax
 mov dx,ax
 and dx,0f0f0h
 and cx,0f0fh
 shr dx,1
 shr dx,1
 shr dx,1
 shr dx,1
 mov al,dh
 xlat
 stosb
 mov al,ch
 xlat
 stosb
 mov al,dl
 xlat
 stosb
 mov al,cl
 xlat
 stosb
 mov ax,word ptr dwrd
 mov cx,ax
 mov dx,ax
 and dx,0f0f0h
 and cx,00f0fh
 shr dx,1
 shr dx,1
 shr dx,1
 shr dx,1
 mov al,dh
 xlat
 stosb
 mov al,ch
 xlat
 stosb
 mov al,dl
 xlat
 stosb
 mov al,cl
 xlat
 stosb
 pop ds
 jmp @yt
@tabel:
 db '0123456789abcdef'
@yt:
end;
{$ELSE}
Const
  HexChars: Array[0..15] of char = '0123456789abcdef';
Var
  S: String[8];
  i: Byte;
Begin
  S[0] := #8;
  For i := 8 downto 1 do begin
    S[i] := HexChars[dwrd mod 16];
    dwrd := dwrd div 16;
  end;
  Longword := S;
End;
{$ENDIF}

{************************************************************************}
{* Rutin:       ReadRandomLine                                          *}
{************************************************************************}
{* Inneh†ll:    L„ser en slumpm„ssig rad ur en textfil                  *}
{* Copyright:   Sl„ppt som Public Domain av Peter Karlsson <2:204/137.5>*}
{* Definition:  Function ReadRandomLine(filename: String): String;      *}
{************************************************************************}

Function ReadRandomLine(filename: String): String;
Var
  FindPos:      FindPosType;
  ReadFile:     File of Char;
  MyPos:        LongInt;
  ch:           Char;
  Line:         String;
begin
  {$I-}
  Assign(ReadFile, filename);
  Reset(ReadFile);
  If IOResult = 0 then begin
    FindPos.Low := Random(65535);
    FindPos.High := Random(32768); { F”r att undvika negativa tal }
    MyPos := FindPos.Long mod FileSize(ReadFile);
    Seek(ReadFile, MyPos);
    Read(ReadFile, ch);
    While ((MyPos > 0) and (ch <> #13) and (ch <> #10)) do begin
      Dec(MyPos);               { S”k till f”reg†ende radslut el. BOF }
      Seek(ReadFile, MyPos);
      Read(ReadFile, ch);
    end;
    If (MyPos = 0) or (eof(ReadFile)) then Seek(ReadFile, 0);
    Line := '';
    Read(ReadFile, ch);
    While (ch = #10) or (ch = #13) do begin   { Om vi „r i ett radslut }
      Read(ReadFile, ch);
      If eof(ReadFile) then Seek(ReadFile, 0);
    end;
    While ((not eof(ReadFile)) and (ch <> #13) and (ch <> #10)) do begin
      Line := Line + ch;
      Read(ReadFile, ch);
    end;
    Close(ReadFile);
    ReadRandomLine := Line;
  end else
    ReadRandomLine := 'Could not open ' + filename;
  {$I+}
end;

{************************************************************************}
{* Rutin:       RemoveJunk                                              *}
{************************************************************************}
{* Inneh†ll:    Tar bort ”verfl”diga mellanslag i en textrad            *}
{* Definition:  Procedure RemoveJunk(Var s: String);                    *}
{************************************************************************}

Procedure RemoveJunk(Var s: String);
Var
  tmp:          String;
  wasspace:     Boolean;
  i:            integer;
  c:            Char;
Begin
  tmp := '';
  wasspace := false;
  If (s[1] <> '%') and (s[1] <> ';') then
  begin
    While s[1] = ' ' do
      s := Copy(s, 2, Length(s)-1);
    For i:=1 to Length(s) do
    begin
      c := s[i];
      If ((c = #9) or  (c = ' ')) then
        Case wasspace of
          False: begin
            tmp := tmp + ' ';
            wasspace := TRUE;
          end;
        end; { Case }
      If not ((c = #9) or (c = ' ')) then
      begin
        wasspace := False;
        tmp := tmp + c;
      end; { If tab/space }
    end; { For }
  end; { If '%' ';' }
  s := tmp;
End;

{************************************************************************}
{* Rutin:       RmUnderline                                             *}
{************************************************************************}
{* Inneh†ll:    ™vers„tter _ i en str„ng till mellanslag                *}
{* Definition:  Function RmUnderline(instring: String): String;         *}
{************************************************************************}

Function RmUnderline(instring: String): String;
Begin
  While Pos('_', instring) > 0 do
    instring[Pos('_', instring)] := ' ';
  RmUnderline := instring;
End;

{************************************************************************}
{* Rutin:       Convert                                                 *}
{************************************************************************}
{* Inneh†ll:    Konverterar en str„ng till en annan teckenupps„ttning   *}
{* Definition:  Function Convert(str: String; charset: CharsetType):    *}
{*                       String;                                        *}
{************************************************************************}

Function Convert(str: String; charset: CharsetType): String;
Var
  i: Byte;
Begin
  If charset in [Sv7, IsSjuBit] then begin
    For i := 1 to Length(str) do
      str[i] := Sjubit[str[i]];
  end else if charset in [Iso, IsIso] then begin
    For i := 1 to Length(str) do
      If str[i] >= #128 then str[i] := IsoTab[str[i]];
  end else if charset = Ascii then begin
    For i := 1 to Length(str) do
      If str[i] >= #128 then str[i] := AsciiTab[str[i]];
  end else if charset = FromIso then begin
    For i := 1 to Length(str) do
      If str[i] >= #128 then str[i] := FromIsoTab[str[i]];
  end else if charset = FromSjuBit then begin
    For i := 1 to Length(str) do
      If (str[i] < #128) or (str[i] > #160) then
        str[i] := FromSjuBitTab[char(byte(str[i]) and 127)] { ASCII med paritet }
      else
        str[i] := ' ';
  end else if charset = FromASCII then begin
    For i := 1 to Length(str) do
      if (str[i] >= #128) and (str[i] < #160) then
        str[i] := ' '
      else
        str[i] := char(byte(str[i]) and 127); { ASCII med paritet }
  end;
  Convert := str;
End;

{************************************************************************}
{* Rutin:       StdoutOn                                                *}
{************************************************************************}
{* Inneh†ll:    Sl†r p† eller av utdata till sk„rmen/stdout             *}
{* Definition:  Procedure StdoutOn(TurnOn: Boolean);                    *}
{************************************************************************}

Procedure StdoutOn(TurnOn: Boolean);
Begin
  If TurnOn then
    Assign(Output, '')
  else
    Assign(Output, 'NUL');
  Rewrite(Output);
End;

Function UpStr(Indata: String): String;
Var
  Utdata: String;
  I:      Byte;
Begin
  Utdata := '';
  For I := 1 to Length(Indata) do
    Utdata := Utdata + UpCase(Indata[I]);
  UpStr := Utdata;
End;

{************************************************************************}
{* Rutin:       ParseINI                                                *}
{************************************************************************}
{* Inneh†ll:    Delar upp en rad i INI-filen                            *}
{* Definition:  Function ParseINI(Indata: String; Var Keyword: String;  *}
{*              Var Data: String): Boolean;                             *}
{************************************************************************}

Function ParseINI(Indata: String; Var Keyword: String; Var Data: String):
         Boolean;
Var
  Position:     Byte;
Begin
  Position := Pos(' ', Indata);
  If Position <> 0 then begin
    Keyword := UpStr(Copy(Indata, 1, Position - 1));
    While (Position <= Length(Indata)) and (Indata[Position] = ' ') do
      Inc(Position);
    If Position <= Length(Indata) then begin
      Data := Copy(Indata, Position, Length(Indata) - Position + 1);
      If (Data[1] = '"') and (Data[Byte(Data[0])] = '"') then
        Data := Copy(Data, 2, Length(Data) - 2);
      {$IFDEF MY} Writeln(Keyword, ':', Data); {$ENDIF}
      ParseINI := True;
    end else
      ParseINI := False;
  end else
    ParseINI := False;
End;

{************************************************************************}
{* Rutin:       YesNo                                                   *}
{************************************************************************}
{* Inneh†ll:    Avg”r om en str„ng „r yes eller no                      *}
{* Definition:  Function YesNo(s: String): Boolean;                     *}
{************************************************************************}

Function YesNo(s: String): Boolean;
Begin
  If Length(s) > 0 then
    YesNo := UpCase(s[1]) = 'Y'
  else
    YesNo := False;
End;

{************************************************************************}
{* Rutin:       ASCIZ                                                   *}
{************************************************************************}
{* Inneh†ll:    Konverterar en nullterminerad str„ng till Pascalstr„ng  *}
{* Definition:  Function ASCIZ(ch_p: CharPointer): String;              *}
{************************************************************************}
Function ASCIZ(ch_p: CharPointer): String;
Var
  s: String;
Begin
  s := '';
  While ch_p^ <> #0 do begin
    s := s + ch_p^;
    Inc(ch_p);
  end;
  ASCIZ := s;
End;

{************************************************************************}
{* Rutin:       InSameDir                                               *}
{************************************************************************}
{* Inneh†ll:    Ger ett filnamn i samma katalog som det f”rsta namnet   *}
{* Definition:  Function InSameDir(FullPath, FileName: String): String; *}
{************************************************************************}
Function InSameDir(FullPath, FileName: String): String;
Var
  i: Byte;
Begin
  i := Length(FullPath);
  While (i > 0) and (FullPath[i] <> '/') do
    Dec(i);
 InSameDir := Copy(FullPath, 1, i) + FileName;
end;

End.
