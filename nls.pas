{************************************************************************}
{************************************************************************}
{* Modul:       nls.pas                                                 *}
{************************************************************************}
{* Inhalt:      National Language Support                               *}
{************************************************************************}
{* Funktion:    Auswertung der Country-Informationen und Bereitstellung *}
{*              von Ausgaberoutinen, die Landes- und Sprachspezifische  *}
{*              Eigenheiten in der Darstellung von Informationen        *}
{*              bercksichtigen.                                        *}
{************************************************************************}
{* Version:     0.22                                                    *}
{* Autor:       Thomas Mainka                                           *}
{* Datum:       04.Apr.1994                                             *}
{* Ver„nderung: Erweiterung um Umwandlung von Windows-ANSI nach OEM     *}
{* Version:     0.22.OS2                                                *}
{* Autor:       Peter Karlsson                                          *}
{* Datum:       1997-08-06                                              *}
{* Ver„nderung: OS/2-st”d                                               *}
{************************************************************************}
{* Revision:    0.10 Erste Version                                      *}
{*              0.12 Rckmeldung des Landes in der Country-Variablen    *}
{*              0.20 Erweiterung um UpStr-Routine auch fr Sonderzeichen*}
{************************************************************************}
{* Routinen:    OEMStr                                                  *}
{*              UpStr                                                   *}
{*              NumStr                                                  *}
{*              DateStr                                                 *}
{*              TimeStr                                                 *}
{*              CurrStr                                                 *}
{*              SetSwChar                                               *}
{*              GetSwChar                                               *}
{*              GetCodeP                                                *}
{*              GetNLS                                                  *}
{************************************************************************}

Unit NLS;

interface

uses     Dos;
{$IFDEF OS2}
uses     BSEDos;
{$ENDIF}
Type     NLSType   = record
                      {$IFDEF MSDOS}
                       DateFor : Word;
                      {$ELSE}{$IFDEF OS2}
                       Country : Longword;
                       Reserved1:Longword;
                       DateFor : Longword;
                      {$ENDIF}{$ENDIF}
                       CurrSym : Array[1..5] of Char;
                       ThouSep : Char;
                       ThouSep2: Char;
                       DecPoin : Char;
                       DecPoin2: Char;
                       DateSep : Char;
                       DateSep2: Char;
                       TimeSep : Char;
                       TimeSep2: Char;
                       CurrFor : Byte;
                       CurrDig : Byte;
                       TimeFor : Byte;
                      {$IFDEF MSDOS}
                       UpCaOfs : Word;
                       UpCaSeg : Word;
                      {$ELSE}{$IFDEF OS2}
                       Reserved2:Array[0..1] of Word;
                      {$ENDIF}{$ENDIF}
                       ListSep : Char;
                       ListSep2: Char;
                      {$IFDEF MSDOS}
                       Reserved:Array[0..9] of Byte;
                      {$ELSE}{$IFDEF OS2}
                       Reserved3:Array[0..4] of Word;
                      {$ENDIF}{$ENDIF}
                     end;

Var      NLSDat    : NLSType;
         Country   : Word;
         SwiChar   : Char;
         CodePage  : Word;
        {$IFDEF OS2}
         NLSDatCI  : CountryInfo absolute NLSDat;
         CountryC  : CountryCode;
        {$ENDIF}

Function OEMStr(S:String):String;
Function UpStr(S:String):String;
Function NumStr(N, D: Integer):String;
Function DateStr(Dat:DateTime):String;
Function TimeStr(Tim:DateTime):String;
Function CurrStr(Amount: Real;i,j: Integer):String;
Procedure SetSwChar(SChar:Char);
Procedure GetSwChar;
Procedure GetNLS(Cntry:Byte);

implementation
Type     RestTab   = Array[128..255] of Char;
Const    C437      : RestTab =
                     (#$20,#$20,#$20,#$9F,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$FA,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$AD,#$9B,#$9C,#$20,#$9D,#$20,#$15,  {A0h-A7h}
                      #$20,#$20,#$A6,#$AE,#$AA,#$20,#$20,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$20,#$20,#$E6,#$14,#$F9,  {B0h-B7h}
                      #$20,#$20,#$A7,#$AF,#$AC,#$AB,#$20,#$A8,  {B8h-BFh}
                      #$20,#$20,#$20,#$20,#$8E,#$8F,#$92,#$80,  {C0h-C7h}
                      #$20,#$90,#$20,#$20,#$20,#$20,#$20,#$20,  {C8h-CFh}
                      #$20,#$A5,#$20,#$20,#$20,#$20,#$99,#$20,  {D0h-D7h}
                      #$ED,#$20,#$20,#$20,#$9A,#$20,#$20,#$E1,  {D8h-DFh}
                      #$85,#$A0,#$83,#$20,#$84,#$86,#$91,#$87,  {E0h-E7h}
                      #$8A,#$82,#$88,#$89,#$8D,#$A1,#$8C,#$8B,  {E8h-EFh}
                      #$20,#$A4,#$95,#$A2,#$93,#$20,#$94,#$F6,  {F0h-F7h}
                      #$20,#$97,#$A3,#$96,#$81,#$20,#$20,#$98); {F8h-FFh}
         C850      : RestTab =
                     (#$20,#$20,#$20,#$9F,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$FA,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$AD,#$BD,#$9C,#$CF,#$BE,#$DD,#$F5,  {A0h-A7h}
                      #$20,#$B8,#$A6,#$AE,#$AA,#$20,#$A9,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$FC,#$EF,#$E6,#$F4,#$FA,  {B0h-B7h}
                      #$20,#$FB,#$A7,#$AF,#$AC,#$AB,#$F3,#$A8,  {B8h-BFh}
                      #$B7,#$B5,#$B6,#$20,#$8E,#$8F,#$92,#$80,  {C0h-C7h}
                      #$20,#$90,#$D2,#$D3,#$DE,#$D5,#$D6,#$D8,  {C8h-CFh}
                      #$D1,#$A5,#$E3,#$E0,#$E2,#$E5,#$99,#$9C,  {D0h-D7h}
                      #$9D,#$EB,#$E9,#$EA,#$9A,#$ED,#$20,#$E1,  {D8h-DFh}
                      #$85,#$A0,#$83,#$20,#$84,#$86,#$91,#$87,  {E0h-E7h}
                      #$8A,#$82,#$88,#$89,#$8D,#$A1,#$8C,#$8B,  {E8h-EFh}
                      #$D0,#$A4,#$95,#$A2,#$93,#$E4,#$94,#$F6,  {F0h-F7h}
                      #$9B,#$97,#$A3,#$96,#$81,#$EC,#$20,#$98); {F8h-FFh}
         C852      : RestTab =
                     (#$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$E6,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$E7,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$F5,  {A0h-A7h}
                      #$F9,#$20,#$20,#$AE,#$AA,#$20,#$20,#$20,  {A8h-AFh}
                      #$F8,#$20,#$20,#$20,#$EF,#$20,#$14,#$FA,  {B0h-B7h}
                      #$F7,#$20,#$20,#$AF,#$20,#$20,#$20,#$20,  {B8h-BFh}
                      #$20,#$B5,#$B6,#$20,#$8E,#$20,#$20,#$80,  {C0h-C7h}
                      #$20,#$90,#$20,#$D3,#$20,#$D6,#$D7,#$20,  {C8h-CFh}
                      #$D1,#$20,#$20,#$E0,#$E2,#$8A,#$99,#$9E,  {D0h-D7h}
                      #$20,#$20,#$E9,#$20,#$9A,#$ED,#$20,#$E1,  {D8h-DFh}
                      #$20,#$A0,#$83,#$20,#$84,#$20,#$20,#$87,  {E0h-E7h}
                      #$20,#$82,#$20,#$89,#$20,#$A1,#$8C,#$20,  {E8h-EFh}
                      #$20,#$20,#$20,#$A2,#$93,#$8B,#$94,#$F6,  {F0h-F7h}
                      #$20,#$20,#$A3,#$20,#$81,#$EC,#$20,#$20); {F8h-FFh}
         C857      : RestTab =
                     (#$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$AD,#$BD,#$9C,#$CF,#$BE,#$DD,#$F5,  {A0h-A7h}
                      #$F9,#$B8,#$D1,#$AE,#$AA,#$EE,#$A9,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$FC,#$EF,#$E6,#$F4,#$FA,  {B0h-B7h}
                      #$F7,#$FB,#$D0,#$AF,#$AC,#$AB,#$F3,#$A8,  {B8h-BFh}
                      #$B7,#$B5,#$B6,#$C7,#$8E,#$8F,#$92,#$80,  {C0h-C7h}
                      #$D4,#$90,#$D2,#$D3,#$DE,#$D6,#$D7,#$D8,  {C8h-CFh}
                      #$20,#$A5,#$E3,#$E0,#$E2,#$E5,#$99,#$E8,  {D0h-D7h}
                      #$9D,#$EB,#$E9,#$EA,#$9A,#$20,#$20,#$E1,  {D8h-DFh}
                      #$85,#$A0,#$83,#$C6,#$84,#$86,#$91,#$87,  {E0h-E7h}
                      #$8A,#$82,#$88,#$89,#$EC,#$A1,#$8C,#$8B,  {E8h-EFh}
                      #$20,#$A4,#$95,#$A2,#$93,#$E4,#$94,#$F6,  {F0h-F7h}
                      #$9B,#$97,#$A3,#$96,#$81,#$20,#$20,#$ED); {F8h-FFh}
         C860      : RestTab =
                     (#$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$5E,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$FA,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$AD,#$9B,#$9C,#$20,#$20,#$20,#$15,  {A0h-A7h}
                      #$20,#$20,#$A6,#$AE,#$AA,#$20,#$20,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$20,#$20,#$E6,#$14,#$F9,  {B0h-B7h}
                      #$20,#$20,#$A7,#$AF,#$AC,#$AB,#$20,#$A8,  {B8h-BFh}
                      #$91,#$86,#$8F,#$8E,#$20,#$20,#$20,#$80,  {C0h-C7h}
                      #$92,#$90,#$89,#$20,#$8D,#$20,#$20,#$20,  {C8h-CFh}
                      #$20,#$A5,#$A9,#$9F,#$8C,#$99,#$20,#$20,  {D0h-D7h}
                      #$20,#$9D,#$96,#$20,#$9A,#$20,#$20,#$E1,  {D8h-DFh}
                      #$85,#$A0,#$83,#$84,#$20,#$20,#$20,#$87,  {E0h-E7h}
                      #$8A,#$82,#$88,#$20,#$8B,#$A1,#$20,#$20,  {E8h-EFh}
                      #$20,#$A4,#$95,#$A2,#$93,#$94,#$20,#$F6,  {F0h-F7h}
                      #$20,#$97,#$A3,#$20,#$81,#$20,#$20,#$20); {F8h-FFh}
         C861      : RestTab =
                     (#$20,#$20,#$20,#$9F,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$F9,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$AD,#$20,#$9C,#$20,#$20,#$20,#$15,  {A0h-A7h}
                      #$20,#$20,#$20,#$AE,#$AA,#$20,#$20,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$20,#$27,#$E6,#$14,#$FA,  {B0h-B7h}
                      #$20,#$20,#$20,#$AF,#$AC,#$AB,#$20,#$A8,  {B8h-BFh}
                      #$20,#$A4,#$20,#$20,#$8E,#$8F,#$92,#$80,  {C0h-C7h}
                      #$20,#$90,#$20,#$20,#$20,#$A5,#$20,#$20,  {C8h-CFh}
                      #$8B,#$20,#$20,#$A6,#$20,#$20,#$99,#$20,  {D0h-D7h}
                      #$9D,#$20,#$A7,#$20,#$9A,#$97,#$8D,#$E1,  {D8h-DFh}
                      #$85,#$A0,#$83,#$20,#$84,#$86,#$91,#$87,  {E0h-E7h}
                      #$8A,#$82,#$88,#$89,#$20,#$A1,#$20,#$20,  {E8h-EFh}
                      #$8C,#$20,#$20,#$A2,#$93,#$20,#$94,#$F6,  {F0h-F7h}
                      #$9B,#$20,#$A3,#$96,#$81,#$98,#$95,#$20); {F8h-FFh}
         C862      : RestTab =
                     (#$20,#$20,#$20,#$9F,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$F9,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$AD,#$9B,#$9C,#$20,#$9D,#$20,#$15,  {A0h-A7h}
                      #$20,#$20,#$A6,#$AE,#$AA,#$20,#$20,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$20,#$27,#$E6,#$14,#$FA,  {B0h-B7h}
                      #$20,#$20,#$A7,#$AF,#$AC,#$AB,#$20,#$A8,  {B8h-BFh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {C0h-C7h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {C8h-CFh}
                      #$20,#$A5,#$20,#$20,#$20,#$20,#$20,#$20,  {D0h-D7h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$E1,  {D8h-DFh}
                      #$20,#$A0,#$20,#$20,#$20,#$20,#$20,#$20,  {E0h-E7h}
                      #$20,#$20,#$20,#$20,#$20,#$A1,#$20,#$20,  {E8h-EFh}
                      #$20,#$A4,#$20,#$A2,#$20,#$20,#$20,#$F6,  {F0h-F7h}
                      #$20,#$20,#$A3,#$20,#$20,#$20,#$20,#$20); {F8h-FFh}
         C863      : RestTab =
                     (#$20,#$20,#$20,#$9F,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$FA,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$20,#$9B,#$9C,#$98,#$20,#$A0,#$8F,  {A0h-A7h}
                      #$A4,#$20,#$20,#$AE,#$AA,#$20,#$20,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$A6,#$A1,#$E6,#$86,#$F9,  {B0h-B7h}
                      #$20,#$20,#$20,#$AF,#$AC,#$AB,#$AD,#$20,  {B8h-BFh}
                      #$8E,#$20,#$84,#$20,#$20,#$20,#$20,#$80,  {C0h-C7h}
                      #$91,#$90,#$92,#$94,#$20,#$20,#$A8,#$95,  {C8h-CFh}
                      #$20,#$20,#$20,#$20,#$99,#$20,#$20,#$20,  {D0h-D7h}
                      #$20,#$9D,#$20,#$9E,#$9A,#$20,#$20,#$E1,  {D8h-DFh}
                      #$85,#$20,#$83,#$20,#$20,#$20,#$20,#$87,  {E0h-E7h}
                      #$8A,#$82,#$88,#$89,#$20,#$20,#$8C,#$8B,  {E8h-EFh}
                      #$20,#$20,#$20,#$A2,#$93,#$20,#$20,#$F6,  {F0h-F7h}
                      #$20,#$20,#$97,#$96,#$81,#$20,#$20,#$20); {F8h-FFh}
         C864      : RestTab =
                     (#$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$82,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$20,#$20,#$A3,#$A4,#$20,#$20,#$15,  {A0h-A7h}
                      #$20,#$20,#$20,#$97,#$20,#$20,#$20,#$20,  {A8h-AFh}
                      #$80,#$93,#$20,#$20,#$27,#$20,#$14,#$81,  {B0h-B7h}
                      #$20,#$20,#$20,#$98,#$95,#$94,#$20,#$20,  {B8h-BFh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {C0h-C7h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {C8h-CFh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {D0h-D7h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$90,  {D8h-DFh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {E0h-E7h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {E8h-EFh}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {F0h-F7h}
                      #$92,#$20,#$20,#$20,#$20,#$20,#$20,#$20); {F8h-FFh}
         C865      : RestTab =
                     (#$20,#$20,#$20,#$9F,#$20,#$20,#$20,#$20,  {80h-87h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {88h-8Fh}
                      #$20,#$20,#$20,#$20,#$20,#$FA,#$20,#$20,  {90h-97h}
                      #$20,#$20,#$20,#$20,#$20,#$20,#$20,#$20,  {98h-9Fh}
                      #$20,#$AD,#$20,#$9C,#$20,#$20,#$20,#$15,  {A0h-A7h}
                      #$20,#$20,#$A6,#$AE,#$AA,#$20,#$20,#$20,  {A8h-AFh}
                      #$F8,#$F1,#$FD,#$20,#$20,#$E6,#$14,#$F9,  {B0h-B7h}
                      #$20,#$20,#$A7,#$AF,#$AC,#$AB,#$20,#$A8,  {B8h-BFh}
                      #$20,#$20,#$20,#$20,#$8E,#$8F,#$92,#$80,  {C0h-C7h}
                      #$20,#$90,#$20,#$20,#$20,#$20,#$20,#$20,  {C8h-CFh}
                      #$20,#$A5,#$20,#$20,#$20,#$20,#$99,#$20,  {D0h-D7h}
                      #$9D,#$20,#$20,#$20,#$9A,#$20,#$20,#$E1,  {D8h-DFh}
                      #$85,#$A0,#$83,#$20,#$84,#$86,#$91,#$87,  {E0h-E7h}
                      #$8A,#$82,#$88,#$89,#$8D,#$A1,#$8C,#$8B,  {E8h-EFh}
                      #$20,#$A4,#$95,#$A2,#$93,#$20,#$94,#$F6,  {F0h-F7h}
                      #$9B,#$97,#$A3,#$96,#$81,#$20,#$20,#$98); {F8h-FFh}

Var      Reg       : Registers;
         CodeErw   : RestTab;

{************************************************************************}
{* Routine:     OEMStr                                                  *}
{************************************************************************}
{* Inhalt:      Erzeugung eines OEM-Strings aus einem ANSI-String       *}
{* Definition:  Function OEMStr(S:String):String                        *}
{************************************************************************}

Function OEMStr(S:String):String;
Var      HStr      : String;
         i         : Byte;

begin
   HStr:=S;
   for i:=1 to Length(S) do
     if Ord(HStr[i])>=128 then HStr[i]:=CodeErw[Ord(HStr[i])];
   OEMStr:=HStr;
end;

{************************************************************************}
{* Routine:     UpStr                                                   *}
{************************************************************************}
{* Inhalt:      Erzeugung eines UpCase-Strings mit Sonderzeichen        *}
{* Definition:  Function UpStr(S:String):String                         *}
{************************************************************************}

Function UpStr(S:String):String;
{$IFDEF MSDOS}
Var      HStr      : String;
         i         : Integer;
         P1        : Pointer;
         C1        : Char;

begin
   HStr:=S;
   P1:=Ptr(NLSDat.UpCaSeg,NLSDat.UpCaOfs);
   for i:=1 to Length(S) do
     if Ord(HStr[i])<128 then HStr[i]:=UpCase(HStr[i])
     else begin
       C1:=HStr[i];
       inline(
         $8A/$86/C1/
         $ff/$9e/P1/
         $88/$86/C1);
       {asm
         mov  AL,C1
         call [P1]
         mov  C1,AL
       end;}
       HStr[i]:=C1;
     end;
   UpStr:=HStr;
end;
{$ELSE}{$IFDEF OS2}
Var      HStr      : CString;
begin
  HStr := S;
  DosMapCase(Length(HStr), CountryC, HStr);
  UpStr := HStr;
end;
{$ENDIF}{$ENDIF}

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
{* Routine:     DateStr                                                 *}
{************************************************************************}
{* Inhalt:      Erzeugung eines Datum-Strings mit num. Monatsangabe     *}
{*              und 2stelliger Jahresangabe                             *}
{* Definition:  Function DateStr(Dat:DateTime):String                   *}
{************************************************************************}

Function DateStr(Dat:DateTime):String;
Var      HString   : String;
begin
   case NLSDat.DateFor of
     0: HString:=NumStr(Dat.Month,2)+NLSDat.DateSep+
                 NumStr(Dat.Day,2)+NLSDat.DateSep+NumStr(Dat.Year mod 100,2);
     1: HString:=NumStr(Dat.Day,2)+NLSDat.DateSep+
                 NumStr(Dat.Month,2)+NLSDat.DateSep+NumStr(Dat.Year mod 100,2);
     2: HString:=NumStr(Dat.Year mod 100,2)+NLSDat.DateSep+
                 NumStr(Dat.Month,2)+NLSDat.DateSep+NumStr(Dat.Day,2);
   end;
   DateStr:=HString;
end;

{************************************************************************}
{* Routine:     TimeStr                                                 *}
{************************************************************************}
{* Inhalt:      Erzeugung eines Uhrzeit-Strings mit Stunde und Minute   *}
{* Definition:  Function TimeStr(Tim:DateTime):String                   *}
{************************************************************************}

Function TimeStr(Tim:DateTime):String;
Var HString        : String;
    HHour          : Integer;
    AM_PM          : Char;
begin
   if NLSDat.TimeFor=1 then
     HString:=NumStr(Tim.Hour,2)+NLSDat.TimeSep+NumStr(Tim.Min,2)+' '
   else begin
     if Tim.Hour>12 then begin
       HHour:=Tim.Hour-12;
       AM_PM:='p';
     end
     else begin
       HHour:=Tim.Hour;
       AM_PM:='a';
     end;
     HString:=NumStr(HHour,2)+NLSDat.TimeSep+NumStr(Tim.Min,2)+AM_PM
   end;
   if HString[1]='0' then HString[1]:=' ';
   TimeStr:=HString;
end;

{************************************************************************}
{* Routine:     CurrStr                                                 *}
{************************************************************************}
{* Inhalt:      Erzeugung eines W„hrungs-Strings                        *}
{* Definition:  Function CurrStr(Amount:Real; i,j:Integer):String;      *}
{************************************************************************}

Function CurrStr(Amount: Real;i,j: Integer):String;
Var      HStr      : String;
         PStr      : String[10];
         MCurr,Curr: Integer;
         TCurr     : Integer;
         KorrFak   : Real;
         F,l       : Integer;
begin
  if Amount<>0 then KorrFak:=Amount/Abs(Amount)*0.01
  else KorrFak:=0;
  With NLSDat do begin
    case CurrDig of
      0 : F:=1;
      1 : F:=10;
      2 : F:=100;
      3 : F:=1000;
    end;
    MCurr:=Abs(Trunc(Frac(Amount)*F+KorrFak));
    Curr:=Trunc(Frac(Amount/1000)*1000+KorrFak);
    TCurr:=Trunc(Amount/1000);
    if CurrDig<>0 then begin
      Str(MCurr,PStr);
      while Length(PStr)<CurrDig do PStr:='0'+PStr;
      HStr:=DecPoin+PStr;
    end
    else HStr:='';
    Str(Curr,PStr);
    if TCurr<>0 then begin
      Curr:=Abs(Curr);
      Str(Curr,PStr);
      While Length(PStr)<3 do PStr:='0'+PStr;
      HStr:=ThouSep+PStr+HStr;
      Str(TCurr,PStr);
    end;
    HStr:=PStr+HStr;
    PStr:='';
    l:=1;
    While CurrSym[l]<>#$00 do begin
      PStr:=PStr+CurrSym[l];
      l:=Succ(l);
    end;
    if CurrFor=0 then begin
      HStr:=PStr+HStr;
      While Length(HStr)<j+Length(PStr) do HStr:=' '+HStr;
    end
    else begin
      While Length(HStr)<j do HStr:=' '+HStr;
      case CurrFor of
        1 : HStr:=HStr+PStr;
        2 : HStr:=PStr+HStr;
        3 : HStr:=HStr+' '+PStr;
      end;
    end;
  end;
  While Length(HStr)<i do HStr:=' '+HStr;
  CurrStr:=HStr;
end;

{************************************************************************}
{* Routine:     SetSwChar                                               *}
{************************************************************************}
{* Inhalt:      Setzen des Switch-Characters                            *}
{* Definition:  Procedure SetSwChar(SChar: Char);                       *}
{************************************************************************}

Procedure SetSwChar(SChar: Char);
begin
{$IFDEF MSDOS}
   Reg.AX:=$3701;
   Reg.DL:=Byte(SChar);
   MsDos(Reg);
{$ENDIF}
end;

{************************************************************************}
{* Routine:     GetSwChar                                               *}
{************************************************************************}
{* Inhalt:      Holen des Switch-Charakters                             *}
{* Definition:  Procedure GetSwChar;                                    *}
{************************************************************************}

Procedure GetSwChar;
begin
{$IFDEF MSDOS}
   Reg.AX:=$3700;
   MsDos(Reg);
   if (Reg.AH<>Byte(#$ff)) then SwiChar:=Char(Reg.DL)
   else SwiChar:='/';
{$ELSE}{$IFDEF OS2}
   SwiChar:='/';
{$ENDIF}{$ENDIF}
end;

{************************************************************************}
{* Routine:     GetCodeP                                                *}
{************************************************************************}
{* Inhalt:      Holen der aktuellen CodePage                            *}
{* Definition:  Procedure GetCodeP;                                     *}
{************************************************************************}

Procedure GetCodeP;
{$IFDEF MSDOS}
Var      Ver       : Word;
begin
   Ver:=DosVersion;
   if (Lo(Ver) > 3) or ((Lo(Ver) = 3) and (Hi(Ver) >= 30)) then begin
     Reg.AX:=$6601;
     MsDos(Reg);
     CodePage:=Reg.BX;
     if CodePage = 437 then CodeErw:=C437;
     if CodePage = 850 then CodeErw:=C850;
     if CodePage = 852 then CodeErw:=C852;
     if CodePage = 857 then CodeErw:=C857;
     if CodePage = 860 then CodeErw:=C860;
     if CodePage = 861 then CodeErw:=C861;
     if CodePage = 862 then CodeErw:=C861;
     if CodePage = 863 then CodeErw:=C863;
     if CodePage = 864 then CodeErw:=C861;
     if CodePage = 865 then CodeErw:=C865;
   end
   else begin
     CodePage:=437;
     CodeErw:=C437;
   end;
end;
{$ELSE}{$IFDEF OS2}
Var      GetCodePage, DataLen: LongWord;
begin
   DosQueryCp(4, GetCodePage, DataLen);
   CodePage := GetCodePage;
end;
{$ENDIF}{$ENDIF}

{************************************************************************}
{* Routine:     GetNLS                                                  *}
{************************************************************************}
{* Inhalt:      Holen der NLS-Informationen eines Landes                *}
{* Definition:  Procedure GetNLS(Country: Byte);                        *}
{************************************************************************}

Procedure GetNLS(Cntry: Byte);
{$IFDEF MSDOS}
begin
   Reg.AX:=$3800+Cntry;
   Reg.DS:=Seg(NLSDat);
   Reg.DX:=Ofs(NLSDat);
   MsDos(Reg);
   Country:=Reg.BX;
end;
{$ELSE}{$IFDEF OS2}
var      temp : ulong;
begin
  CountryC.Country := cntry;
  CountryC.Codepage := 0;
  DosQueryCtryInfo(SizeOf(NLSDat), CountryC, NLSDatCI, temp);
  CountryC.Country := NLSDat.Country;
  Country := NLSDat.Country;
end;
{$ENDIF}{$ENDIF}

{************************************************************************}
{* Routine:     Unit-Hauptprogramm (Initialisierung)                    *}
{************************************************************************}
{* Inhalt:      Holt die aktuell gesetzte Country-Information           *}
{************************************************************************}

begin
   GetNLS(0);
   GetCodeP;
end.
