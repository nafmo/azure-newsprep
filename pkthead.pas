{************************************************************************}
{* Modul:       pkthead.pas                                             *}
{************************************************************************}
{* Inneh†ll:    Definition av en type 2/type 2+ PKT-header              *}
{************************************************************************}
{* Funktion:    Anv„nds av BluePKT                                      *}
{************************************************************************}
{* Rutiner:     inga                                                    *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.00 - 1995-09-30 -                                                *}
{************************************************************************}

Unit PKTHead;

Interface

Type  PKTheader = record
                    OrgNode,              { Originating Node }
                    DstNode,              { Destination Node }
                    Year,                 { Year of creation }
                    Month,                { Month (0 = Jan)  }
                    Day,                  { Day              }
                    Hour,                 { Hour             }
                    Min,                  { Minute           }
                    Sec,                  { Second           }
                    Baud,                 { Baud rate        }
                    PktVer,               { Packet rev. (2)  }
                    OrgNet,               { Originating Net  }
                    DstNet:       word;   { Destination Net  }
                    PrdCodL,              { Production Code  }
                    PVMajor:      byte;   { Prod. Rev, major }
                    Password:     array[0..7] of char; { Password }
                    QOrgZone,             { Originating Zone }
                    QDstZone:     word;   { Destination Zone }
                    Filler:       word;
                    CapValid:     word;   { Byteswapped CapW }
                    PrdCodH,              { Prod. Code, high }
                    PVMinor:      byte;   { Prod. Rev, minor }
                    CapWord,              { Capability Word  }
                    OrgZone,              { Originating Zone }
                    DstZone,              { Destination Zone }
                    OrgPoint,             { Orig. Point      }
                    DstPoint:    word;    { Dest. Point      }
                    ProdData:    array[0..3] of char; { whatever...      }
                  end;

Type  PkdMSG    = record
                    PktVer,               { Packet rev. (2)  }
                    OrgNode,              { Originating Node }
                    DstNode,              { Destination Node }
                    OrgNet,               { Originating Net  }
                    DstNet,               { Destination Net  }
                    Attribute,            { Attributes       }
                    Cost:       word;     { Cost             }
                    DateTime:   array[0..19] of char; { Date amd time }
                  end;

Implementation

end.
