all: newsprep.exe swe_prep.exe
        rem

newsprep.exe: newsprep.pas
        tpc /v /DINTL newsprep.pas

swe_prep.exe: newsprep.pas
        tpc /v /EG:\TEMP /dSWE newsprep.pas
        4dos /c *move g:\temp\newsprep.exe swe_prep.exe
