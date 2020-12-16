        TITLE   SMW$MAIN V05.00
        NAME    SMW$MAIN
        PAGE    64,132
;----------------------------------------------------------------------;
;       Copyright (C) 1986 by Dallas Semiconductor Corporation         ;
;                         All Rights Reserved                          ;
;----------------------------------------------------------------------;
;                                                                      :
;       This software is furnished under a license and may be used     ;
;       and copied only in accordance with the terms of such license   ;
;       and with the inclusion of the above copyright notice. This     ;
;       software or any other copies thereof may not be provided or    ;
;       otherwise made available to any other person.  No title to     ;
;       and ownership of the software is hereby transferred.           ;
;                                                                      ;
;       The information in this software is subject to change without  ;
;       notice and should not be construed as a commitment by Dallas   ;
;       Semiconductor Corporation.                                     ;
;                                                                      ;
;       Dallas Semiconductor assumes no responsibility for the use     ;
;       or reliability of its software on equipment which is not       ;
;       supplied by Dallas Semiconductor.                              ;
;                                                                      :
;----------------------------------------------------------------------;
;       Module:         SMW$MAIN                                       ;
;----------------------------------------------------------------------;
;       Programmer:     Kevin Klughart                                 ;
;----------------------------------------------------------------------;
;       Date:           28-Oct-1986 @ 11:00 CDST                       ;
;----------------------------------------------------------------------;
;       System:         IBM Personal Computer/AT running PC-DOS V3.10  ;
;----------------------------------------------------------------------;
;       Language:       IBM PC 80286 (Intel iAPX 286) assembly         ;
;----------------------------------------------------------------------;
;       Assembler:      Microsoft MACRO Assembler V4.00                ;
;----------------------------------------------------------------------;
;       Site:           Dallas Semiconductor                           ;
;                       4350 Beltwood Parkway South                    ;
;                       Dallas, Texas 75244                            ;
;                       (214)  450-0400                                ;
;----------------------------------------------------------------------;
;       Purpose:        This is the main code module for the DS1216    ;
;                       RAM and DS1216E ROM SmartWatch devices.        ;
;----------------------------------------------------------------------;
;       Note:           This program is designed as a DOS COM image.   ;
;----------------------------------------------------------------------;
;       Revision list:  V01.00 - 01-Jan-1986, Kevin Klughart           ;
;                                Initial release.                      ;
;                                                                      ;
;                       V02.00 - 17-Jan-1986, Kevin Klughart           ;
;                                Revamp screen and add toggle functions;
;                                                                      ;
;                       V03.00 - 14-Feb-1986, Kevin Klughart           ;
;                                Add pause function.                   ;
;                                                                      ;
;                       V04.00 - 27-Feb-1986, Kevin Klughart           ;
;                                Add support for non-286 cpus.         ;
;                                                                      ;
;                       V05.00 - 28-Oct-1986, Kevin Klughart           ;
;                                Fix bug in the interpretation of the  ;
;                                24-hour mode bit.  24-hour operation  ;
;                                is selected when the mode bit is zero.;
;----------------------------------------------------------------------;
;       Assemble using standard instructions and suppress expansions   ;
;----------------------------------------------------------------------;
        .SALL
        SUBTTL  Define local macros
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Define local procedure macros                                  ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;                                                                      ;
;       INTerrupt service request                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
INTCALL MACRO   FUNCTION,AR,BR,CR,DR    


        IFNB    <AR>                    ; AX
        MOV     AX,AR
        ENDIF

        IFNB    <BR>                    ; BX
        MOV     BX,BR
        ENDIF

        IFNB    <CR>                    ; CX
        MOV     CX,CR
        ENDIF

        IFNB    <DR>                    ; DX
        MOV     DX,DR
        ENDIF

        INT     FUNCTION                ; Interrupt service request


        ENDM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       CASE branch implementation                                     ;
;                                                                      ;
;----------------------------------------------------------------------;
CASE    MACRO   REGISTER,DISP
        LOCAL   LBL

        DEC     REGISTER                ; Decrement case register
        JZ      LBL                     ; Continue if case valid
        JMP     DISP                    ; Else check next condition
LBL:

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Key action routine branch implementation                       ;
;                                                                      ;
;----------------------------------------------------------------------;
KEYACT  MACRO   KEYVAL,DISP
        LOCAL   LBL

        CMP     AX,KEYVAL               ; Check key value
        JE      LBL                     ; Continue if key action valid
        JMP     DISP                    ; Else check next condition
LBL:

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Limit range of SmartWatch parameter                            ;
;                                                                      ;
;----------------------------------------------------------------------;
LIMIT   MACRO   REG,LO,HI
        LOCAL   LBL1
        LOCAL   LBL2

        XOR     &REG&H,&REG&H           ; Clear upper byte
        CMP     &REG&X,LO               ; Check low value
        JGE     LBL1                    ; Continue if within range
        MOV     &REG&L,LO               ; Otherwise reset value
LBL1:   CMP     &REG&X,HI               ; Check high value
        JLE     LBL2                    ; Continue if within range
        MOV     &REG&L,LO               ; Otherwise reset value
LBL2:

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       SHIFT arithmetic left multiple                                 ;
;                                                                      ;
;----------------------------------------------------------------------;
SHLM    MACRO   REG,CNT

        REPT    CNT                     ; For each shift
        SHL     REG,1                   ; Shift one left
        ENDM

        ENDM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       PUSHALL registers                                              ;
;                                                                      ;
;----------------------------------------------------------------------;
PUSHALL MACRO

        PUSHA                           ; Push all common registers
        PUSH    DS                      ; Save segment registers
        PUSH    ES                      ; 
        PUSHF                           ; ... and PSW flags
        CLD                             ; Assume forward string search

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       PUSHA simulation                                               ;
;                                                                      ;
;----------------------------------------------------------------------;
PUSHA   MACRO

        PUSH    AX                      ; Push all common registers
        PUSH    BX                      ;
        PUSH    CX                      ;
        PUSH    DX                      ;
        PUSH    BP                      ;
        PUSH    SI                      ;
        PUSH    DI                      ;

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       POPALL registers                                               ;
;                                                                      ;
;----------------------------------------------------------------------;
POPALL  MACRO
        
        POPF                            ; Restore PSW flags
        POP     ES                      ; Restore segment registers
        POP     DS                      ; 
        POPA                            ; ... and all common registers

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       POPA simulation                                                ;
;                                                                      ;
;----------------------------------------------------------------------;
POPA    MACRO
        
        POP     DI                      ; Restore registers
        POP     SI                      ;
        POP     BP                      ;
        POP     DX                      ;
        POP     CX                      ;
        POP     BX                      ;
        POP     AX                      ;

        ENDM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       CONVERT and print byte value at specified row and column       ;
;                                                                      ;
;----------------------------------------------------------------------;
CONVERT MACRO   TYP,ROW,COL,VAL,REG

        
        IFNB    <TYP>
        LEA     SI,TYP                  ; Load conversion table address
        ENDIF

        IFNB    <ROW>
        MOV     BH,ROW                  ; Load display row
        ENDIF

        IFNB    <COL>
        MOV     BL,COL                  ; Load display column
        ENDIF

        IFNB    <VAL>
        MOV     AL,VAL                  ; Load display value
        ENDIF

        CALL    CVT                     ; Convert and display result
        

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       PRINT text string at specified row and column                  ;
;                                                                      ;
;----------------------------------------------------------------------;
PRINT   MACRO   LEN,ROW,COL,VAL

        
        IFNB    <LEN>
        MOV     CX,LEN                  ; Get string length
        ENDIF

        IFNB    <ROW>
        MOV     BH,ROW                  ; Load display row
        ENDIF

        IFNB    <COL>
        MOV     BL,COL                  ; Load display column
        ENDIF

        IFNB    <VAL>
        LEA     SI,VAL                  ; Load source string address
        ENDIF

        CALL    PRT                     ; Print text on display
        

        ENDM
        SUBTTL  Define data structures
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Define data structures                                         ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;                                                                      ;
;       Define code/data segment                                       ;
;                                                                      ;
;----------------------------------------------------------------------;
$SMW    SEGMENT PARA PUBLIC '$SMW'
        ASSUME  CS:$SMW
        ASSUME  DS:$SMW
        ASSUME  ES:$SMW
        ASSUME  SS:$SMW
;----------------------------------------------------------------------;
;                                                                      ;
;       Transfer control to first instruction of SMW utility           ;
;                                                                      ;
;----------------------------------------------------------------------;
        ORG     0100h
START:  JMP     NEAR PTR SMW
        PAGE
        EVEN
;----------------------------------------------------------------------;
;                                                                      ;
;       SmartWatch data areas                                          ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Search mode, segment, increment, and counters                  ;
;----------------------------------------------------------------------;
SW$FLAG DW      0                       ; Option flags (1=inhibit read)
SW$MODE DW      0                       ; Watch access mode (1=RAM0,
                                        ; 2=RAM1, 3=ROM, 4=ROM0, 5=ROM1
SW$PARA DW      0                       ; Memory segment for SmartWatch
SW$STEP DW      0                       ; Search increment for segment

SW$CNT0 DB      0                       ; Interval counter 0
SW$CNT1 DB      0                       ; Interval counter 1
SW$CNT2 DB      0                       ; Interval counter 2
SW$CNT3 DB      0                       ; Interval counter 3
;----------------------------------------------------------------------;
;       Define the time data structure                                 ;
;----------------------------------------------------------------------;
;       DS1216 devices have the following data fields:                 ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 0       ;
;       |    10 centisecond     |      centisecond      | centisec     ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (00-99)      ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 1       ;
;       |      10 second        |        second         | second       ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (00-59)      ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 2       ;
;       |      10 minute        |        minute         | minute       ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (00-59)      ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 3       ;
;       |12/24|  0  |AM/PM| hour|         hour          | hour         ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (01-12)      ;
;                                                            (00-23)   ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 4       ;
;       |  0  |  0  | osc |reset|  0  |       day       | day          ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (01-07)      ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 5       ;
;       |  0  |  0  |  10 date  |         date          | date         ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (01-31)      ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 6       ;
;       |  0  |  0  |  0  |month|         month         | month        ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (01-12)      ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ byte 7       ;
;       |        10 year        |         year          | year         ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+ (00-99)      ;
;                                                                      ;
;       OSC and RESET are active low - 0 enables these functions.      ;
;----------------------------------------------------------------------;
TIME    STRUC
CC      DB      0                       ; centisecond
SC      DB      0                       ; second
MM      DB      0                       ; minute
HH      DB      0                       ; hour and mode bits
DY      DB      0                       ; day-of-week and osc/reset
DM      DB      0                       ; day-of-month
MN      DB      0                       ; month
YY      DB      0                       ; year
TIME    ENDS
;----------------------------------------------------------------------;
;       DOS time data buffer                                           ;
;----------------------------------------------------------------------;
DS$TIME TIME    <>                      ; DOS read/write time buffer
;----------------------------------------------------------------------;
;       SmartWatch initialization sequence and time data buffer        ;
;----------------------------------------------------------------------;
SW$INIT DW      3AC5h,5CA3h,3AC5h,5CA3h ; Initialization protocol
SW$TIME TIME    <>                      ; SmartWatch read/write time buffer
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Display screen image                                           ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Define screen data                                             ;
;----------------------------------------------------------------------;
;                0000000000111111111122222222223333333333
;                0123456789012345678901234567890123456789
SCRDAT: DB      '                                        '      ; 0
        DB      '          Dallas Semiconductor          '      ; 1
        DB      '                                        '      ; 2
        DB      '       DS1216 RAM  -  DS1216E ROM       '      ; 3
        DB      '                                        '      ; 4
        DB      '               SmartWatch               '      ; 5
        DB      '                                        '      ; 6
        DB      '                                        '      ; 7
        DB      '       Year YY [F1]  [F2] HH Hour       '      ; 8
        DB      '      Month MM [F3]  [F4] MM Minutes    '      ; 9
        DB      '       Date DD [F5]  [F6] SS Second     '      ; 10
        DB      'Osc-Rst/Day OW [F7]  [F8] CC Centisecond'      ; 11
        DB      '  Calibrate    [F9] [F10]    Oscillator '      ; 12
        DB      '  zero time alt[F9] [F10]alt Reset      '      ; 13    
        DB      '  A14 / A13 shf[F9] [F10]shf 12/24 mode '      ; 14
        DB      'Access mode ctl[F9] [F10]ctl AM/PM mode '      ; 15
        DB      'Inc segment     Up    Dn     Dec segment'      ; 16
        DB      '                                        '      ; 17
        DB      'DOS time:   DDD, DD-MMM-19YY HH:MM:SS.CC'      ; 18
        DB      'SMW time:   DDD, DD-MMM-19YY HH:MM:SS.CC'      ; 19
        DB      'SMW oscillator drift error:  HH:MM:SS.CC'      ; 20
        DB      '                                        '      ; 21
        DB      '                                        '      ; 22
        DB      'Address:xxxx0  Search:xxxx  Count:xxxxxx'      ; 23
        DB      '                                        '      ; 24
;----------------------------------------------------------------------;
;       Define screen attributes                                       ;
;----------------------------------------------------------------------;
SCRATR: DB      40 DUP (4Eh)                                            ; 0
        DB      40 DUP (4Eh)                                            ; 1
        DB      40 DUP (4Eh)                                            ; 2
        DB      40 DUP (4Eh)                                            ; 3
        DB      40 DUP (4Eh)                                            ; 4
        DB      40 DUP (4Eh)                                            ; 5
        DB      40 DUP (4Eh)                                            ; 6
        DB      40 DUP (10h)                                            ; 7
        DB      12 DUP (1Dh), 2 DUP (1Fh), 12 DUP (16h), 2 DUP (1Fh), 12 DUP (1Dh)
        DB      12 DUP (1Dh), 2 DUP (1Fh), 12 DUP (16h), 2 DUP (1Fh), 12 DUP (1Dh)
        DB      12 DUP (1Dh), 2 DUP (1Fh), 12 DUP (16h), 2 DUP (1Fh), 12 DUP (1Dh)
        DB      12 DUP (1Dh), 2 DUP (1Fh), 12 DUP (16h), 2 DUP (1Fh), 12 DUP (1Dh)
        DB      12 DUP (1Dh), 16 DUP (16h), 12 DUP (1Dh)                ; 12
        DB      12 DUP (1Dh), 16 DUP (16h), 12 DUP (1Dh)                ; 13
        DB      12 DUP (1Dh), 16 DUP (16h), 12 DUP (1Dh)                ; 14
        DB      12 DUP (1Dh), 16 DUP (16h), 12 DUP (1Dh)                ; 15
        DB      12 DUP (1Dh), 16 DUP (16h), 12 DUP (1Dh)                ; 16
        DB      40 DUP (10h)                                            ; 17
        DB      40 DUP (1Eh)                                            ; 18
        DB      40 DUP (1Bh)                                            ; 19
        DB      40 DUP (1Ch)                                            ; 20
        DB      40 DUP (10h)                                            ; 21
        DB      40 DUP (1Ah)                                            ; 22
        DB      40 DUP (1Ah)                                            ; 23
        DB      40 DUP (07h)                                            ; 24
;----------------------------------------------------------------------;
;       Define screen summation buffer                                 ;
;----------------------------------------------------------------------;
SCRBUF: DW      2048 DUP (?)
;----------------------------------------------------------------------;
;       Define SmartWatch protocol access modes                        ;
;----------------------------------------------------------------------;
ACCMOD: DB      'DS1216  (RAM)    bank 0                 '
        DB      'DS1216  (RAM)    bank 1                 '
        DB      'DS1216E (ROM)            non-interleaved'
        DB      'DS1216E (ROM)    bank 0      interleaved'
        DB      'DS1216E (ROM)    bank 1      interleaved'
        SUBTTL  Define data conversion tables
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Define data conversion tables                                  ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;                                                                      ;
;       Binary to ASCII decimal conversion table                       ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This conversion table allows a two digit binary integer to be  ;
;       converted to text with minimal effort.  This is essentially    ;
;       a word-aligned lookup table with the table index being the     ;
;       binary value to be converted.                                  ;
;----------------------------------------------------------------------;
DEC     DB      '00010203040506070809'  ; 0 - 99
        DB      '10111213141516171819'
        DB      '20212223242526272829'
        DB      '30313233343536373839'
        DB      '40414243444546474849'
        DB      '50515253545556575859'
        DB      '60616263646566676869'
        DB      '70717273747576777879'
        DB      '80818283848586878889'
        DB      '90919293949596979899'

        DB      '00010203040506070809'  ; 100 - 199
        DB      '10111213141516171819'
        DB      '20212223242526272829'
        DB      '30313233343536373839'
        DB      '40414243444546474849'
        DB      '50515253545556575859'
        DB      '60616263646566676869'
        DB      '70717273747576777879'
        DB      '80818283848586878889'
        DB      '90919293949596979899'

        DB      '00010203040506070809'  ; 200 - 299
        DB      '10111213141516171819'
        DB      '20212223242526272829'
        DB      '30313233343536373839'
        DB      '40414243444546474849'
        DB      '50515253545556575859'
        DB      '60616263646566676869'
        DB      '70717273747576777879'
        DB      '80818283848586878889'
        DB      '90919293949596979899'
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Binary to ASCII hexadecimal conversion table                   ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This hexadecimal conversion table is generated statically to   ;
;       drastically improve the conversion and display speed.          ;
;----------------------------------------------------------------------;
HEX     DB      '000102030405060708090A0B0C0D0E0F'
        DB      '101112131415161718191A1B1C1D1E1F'
        DB      '202122232425262728292A2B2C2D2E2F'
        DB      '303132333435363738393A3B3C3D3E3F'
        DB      '404142434445464748494A4B4C4D4E4F'
        DB      '505152535455565758595A5B5C5D5E5F'
        DB      '606162636465666768696A6B6C6D6E6F'
        DB      '707172737475767778797A7B7C7D7E7F'
        DB      '808182838485868788898A8B8C8D8E8F'
        DB      '909192939495969798999A9B9C9D9E9F'
        DB      'A0A1A2A3A4A5A6A7A8A9AAABACADAEAF'
        DB      'B0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF'
        DB      'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECF'
        DB      'D0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF'
        DB      'E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF'
        DB      'F0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF'
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Binary to BCD conversion table                                 ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This conversion table allows a two digit binary integer to be  ;
;       converted to BCD with minimal effort.  This is essentially     ;
;       a byte-aligned lookup table with the table index being the     ;
;       binary value to be converted.                                  ;
;----------------------------------------------------------------------;
BINBCD  DB      00h,01h,02h,03h,04h,05h,06h,07h,08h,09h ; 0 - 99
        DB      10h,11h,12h,13h,14h,15h,16h,17h,18h,19h
        DB      20h,21h,22h,23h,24h,25h,26h,27h,28h,29h
        DB      30h,31h,32h,33h,34h,35h,36h,37h,38h,39h
        DB      40h,41h,42h,43h,44h,45h,46h,47h,48h,49h
        DB      50h,51h,52h,53h,54h,55h,56h,57h,58h,59h
        DB      60h,61h,62h,63h,64h,65h,66h,67h,68h,69h
        DB      70h,71h,72h,73h,74h,75h,76h,77h,78h,79h
        DB      80h,81h,82h,83h,84h,85h,86h,87h,88h,89h
        DB      90h,91h,92h,93h,94h,95h,96h,97h,98h,99h

        DB      00h,01h,02h,03h,04h,05h,06h,07h,08h,09h ; 100 - 199
        DB      10h,11h,12h,13h,14h,15h,16h,17h,18h,19h
        DB      20h,21h,22h,23h,24h,25h,26h,27h,28h,29h
        DB      30h,31h,32h,33h,34h,35h,36h,37h,38h,39h
        DB      40h,41h,42h,43h,44h,45h,46h,47h,48h,49h
        DB      50h,51h,52h,53h,54h,55h,56h,57h,58h,59h
        DB      60h,61h,62h,63h,64h,65h,66h,67h,68h,69h
        DB      70h,71h,72h,73h,74h,75h,76h,77h,78h,79h
        DB      80h,81h,82h,83h,84h,85h,86h,87h,88h,89h
        DB      90h,91h,92h,93h,94h,95h,96h,97h,98h,99h

        DB      00h,01h,02h,03h,04h,05h,06h,07h,08h,09h ; 200 - 299
        DB      10h,11h,12h,13h,14h,15h,16h,17h,18h,19h
        DB      20h,21h,22h,23h,24h,25h,26h,27h,28h,29h
        DB      30h,31h,32h,33h,34h,35h,36h,37h,38h,39h
        DB      40h,41h,42h,43h,44h,45h,46h,47h,48h,49h
        DB      50h,51h,52h,53h,54h,55h,56h,57h,58h,59h
        DB      60h,61h,62h,63h,64h,65h,66h,67h,68h,69h
        DB      70h,71h,72h,73h,74h,75h,76h,77h,78h,79h
        DB      80h,81h,82h,83h,84h,85h,86h,87h,88h,89h
        DB      90h,91h,92h,93h,94h,95h,96h,97h,98h,99h
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       BCD to binary conversion table                                 ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This conversion table allows a two digit BCD integer to be     ;
;       converted to binary with minimal effort.  This is essentially  ;
;       a byte-aligned lookup table with the table index being the     ;
;       binary value to be converted.                                  ;
;----------------------------------------------------------------------;
BCDBIN  DB      00,01,02,03,04,05,06,07,08,09,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      10,11,12,13,14,15,16,17,18,19,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      20,21,22,23,24,25,26,27,28,29,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      30,31,32,33,34,35,36,37,38,39,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      40,41,42,43,44,45,46,47,48,49,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      50,51,52,53,54,55,56,57,58,59,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      60,61,62,63,64,65,66,67,68,69,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      70,71,72,73,74,75,76,77,78,79,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      80,81,82,83,84,85,86,87,88,89,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      90,91,92,93,94,95,96,97,98,99,0FFh,0FFh,0FFh,0FFh,0FFh,0FFh
        DB      16 DUP (0FFh)
        DB      16 DUP (0FFh)
        DB      16 DUP (0FFh)
        DB      16 DUP (0FFh)
        DB      16 DUP (0FFh)
        DB      16 DUP (0FFh)
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Day of week and month conversion tables                        ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Define days of the week                                        ;
;----------------------------------------------------------------------;
DAY     DB      'Sun Mon Tue Wed Thr Fri Sat ??? '
;----------------------------------------------------------------------;
;       Define months of the year                                      ;
;----------------------------------------------------------------------;
MON     DB      'Jan Feb Mar Apr May Jun Jul Aug '
        DB      'Sep Oct Nov Dec ??? ??? ??? ??? '
        SUBTTL  Define program entrypoint
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Define program entrypoint                                      ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
SMW     PROC    NEAR                    ; Define procedure entrypoint
        PUSHALL                         ; Save all registers
        MOV     BP,SP                   ; Save stack pointer
;----------------------------------------------------------------------;
;                                                                      ;
;       Setup the control-break interrupt vector                       ;
;                                                                      ;
;----------------------------------------------------------------------;
        PUSH    DS                      ; Save current data segment

        XOR     AX,AX                   ; Get all zeros
        MOV     DS,AX                   ; ... and clear the data segment
        MOV     DS:[(4*35)+0],OFFSET BRK; Load break routine offset
        MOV     DS:[(4*35)+2],CS        ; Load break routine segment

        POP     DS                      ; Restore current data segment
;----------------------------------------------------------------------;
;                                                                      ;
;       Initialize the display attributes                              ;
;                                                                      ;
;----------------------------------------------------------------------;
        INTCALL 10h,0001h               ; Set display mode 40-column color
        INTCALL 10h,0500h               ; Set display page 0
        INTCALL 10h,0100h,,2020h        ; Set cursor size (inhibit)
        INTCALL 10h,0200h,0000h,,1901h  ; Home the cursor
;----------------------------------------------------------------------;
;                                                                      ;
;       Combine data and attribute screens and flush to display        ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Load current display data                                      ;
;----------------------------------------------------------------------;
        LEA     SI,SCRDAT               ; Get data screen offset
        LEA     DI,SCRBUF               ; Initialize output offset
        XOR     AX,AX                   ; Clear background characteristics
        MOV     CX,(40*25)              ; Load character count
        
DSPTXT: LODSB                           ; Get a text byte
        STOSW                           ; ... and store in display memory
        LOOP    DSPTXT                  ; Update some more text
;----------------------------------------------------------------------;
;       Load current display attributes                                ;
;----------------------------------------------------------------------;
        LEA     SI,SCRATR               ; Get attribute screen offset
        LEA     DI,SCRBUF               ; Initialize output offset
        MOV     CX,(40*25)              ; Load character count

DSPATR: LODSB                           ; Get an attribute byte
        INC     DI                      ; Point to next attribute area
        STOSB                           ; ... and store in display memory
        LOOP    DSPATR                  ; Update some more text
        SUBTTL  Main processing loop
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Main processing loop                                           ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;                                                                      ;
;       Search for the SmartWatch                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
        CALL    SEARCH                  ; Search for the SmartWatch
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the SmartWatch                                            ;
;                                                                      ;
;----------------------------------------------------------------------;
BEGIN:  TEST    SW$FLAG,1               ; Reads inhibited?
        JNZ     UPD                     ; Yes, skip the read operation

        CALL    READ                    ; Read the SmartWatch
;----------------------------------------------------------------------;
;                                                                      ;
;       Update the display with the new SmartWatch data                ;
;                                                                      ;
;----------------------------------------------------------------------;
UPD:    CALL    UPDATE                  ; Update the data display
;----------------------------------------------------------------------;
;                                                                      ;
;       Determine if a keyboard entry has occurred                     ;
;                                                                      ;
;----------------------------------------------------------------------;
        INTCALL 16h,0100h               ; Scan keyboard
        JZ      BEGIN                   ; ... and wait for key entry
;----------------------------------------------------------------------;
;                                                                      ;
;       Dispatch to key action routine                                 ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Fetch the key entered by the user                              ;
;----------------------------------------------------------------------;
        INTCALL 16h,0000h               ; Read the keyboard
;----------------------------------------------------------------------;
;       Clear AH if AL is nonzero                                      ;
;----------------------------------------------------------------------;
        OR      AL,AL                   ; Single character entered?
        JZ      PAUSE                   ; No, continue

        XOR     AH,AH                   ; Yes, clear extended key code
        SUBTTL  Key action:  pause
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  pause                                             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine pauses the display and waits for another command  ;
;----------------------------------------------------------------------;
PAUSE:  KEYACT  001Bh,INC_YY            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Toggle the SmartWatch read flag                                ;
;----------------------------------------------------------------------;
        XOR     SW$FLAG,0001h           ; Toggle watch read flag
        JMP     BEGIN                   ; ... and restart display loop
        SUBTTL  Key action:  increment year
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment year                                    ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the year                               ;
;----------------------------------------------------------------------;
INC_YY: KEYACT  3B00h,INC_HH            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the year                                             ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.YY           ; Get current year
        ADD     AL,1                    ; Increment the year
        DAA                             ; ... and adjust after addition
        LIMIT   A,00h,99h               ; Limit scope of result
        MOV     SW$TIME.YY,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment hour
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment hour                                    ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the hour                               ;
;----------------------------------------------------------------------;
INC_HH: KEYACT  3C00h,INC_MN            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the hour                                             ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.HH           ; Get current hour
        MOV     BH,AL                   ; Save mode flag
        AND     BH,80h                  ; ... and mask off hours
        AND     AL,7Fh                  ; Strip mode flag from hours
        ADD     AL,1                    ; Increment the hour
        DAA                             ; ... and adjust after addition
        LIMIT   A,00h,23h               ; Limit scope of result
        OR      AL,BH                   ; Restore mode bit
        MOV     SW$TIME.HH,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment month
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment month                                   ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the month                              ;
;----------------------------------------------------------------------;
INC_MN: KEYACT  3D00h,INC_MM            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the month                                            ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.MN           ; Get current month
        ADD     AL,1                    ; Increment the year
        DAA                             ; ... and adjust after addition
        LIMIT   A,01h,12h               ; Limit scope of result
        MOV     SW$TIME.MN,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment minute
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment minute                                  ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the minute                             ;
;----------------------------------------------------------------------;
INC_MM: KEYACT  3E00h,INC_DM            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the minute                                           ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.MM           ; Get current minute
        ADD     AL,1                    ; Increment the year
        DAA                             ; ... and adjust after addition
        LIMIT   A,00h,59h               ; Limit scope of result
        MOV     SW$TIME.MM,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment date
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment date                                    ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the date                               ;
;----------------------------------------------------------------------;
INC_DM: KEYACT  3F00h,INC_SC            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the date                                             ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.DM           ; Get current date
        ADD     AL,1                    ; Increment the year
        DAA                             ; ... and adjust after addition
        LIMIT   A,01h,31h               ; Limit scope of result
        MOV     SW$TIME.DM,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment second
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment second                                  ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the second                             ;
;----------------------------------------------------------------------;
INC_SC: KEYACT  4000h,INC_DY            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the second                                           ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.SC           ; Get current second
        ADD     AL,1                    ; Increment the year
        DAA                             ; ... and adjust after addition
        LIMIT   A,00h,59h               ; Limit scope of result
        MOV     SW$TIME.SC,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment day
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment day                                     ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the day                                ;
;----------------------------------------------------------------------;
INC_DY: KEYACT  4100h,INC_CC            ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the day                                              ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.DY           ; Get current day
        MOV     BH,AL                   ; Save osc/rst bits
        AND     BH,0F0h                 ; ... and clear the rest
        AND     AL,00Fh                 ; Clear osc/rst bits
        ADD     AL,1                    ; Increment the year
        DAA                             ; ... and adjust after addition
        LIMIT   A,01h,07h               ; Limit scope of result
        OR      AL,BH                   ; Restore osc/rst bits
        MOV     SW$TIME.DY,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment centisecond
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment centisecond                             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the centisecond                        ;
;----------------------------------------------------------------------;
INC_CC: KEYACT  4200h,CAL               ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the centisecond                                      ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.CC           ; Get current centisecond
        ADD     AL,1                    ; Increment the year
        DAA                             ; ... and adjust after addition
        LIMIT   A,00h,99h               ; Limit scope of result
        MOV     SW$TIME.CC,AL           ; Restore normalized value
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  calibrate time
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  calibrate time                                    ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine calibrates the time in the SmartWatch.            ;
;----------------------------------------------------------------------;
CAL:    KEYACT  4300h,OSC               ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Calibrate the SmartWatch data to the system clock              ;
;----------------------------------------------------------------------;
;       Load current DOS date                                          ;
;----------------------------------------------------------------------;
        LEA     BX,BINBCD               ; Get conversion table address

        MOV     AL,DS$TIME.DY           ; Get day-of-week
        INC     AL                      ; Correct offset for day-of-week
        XLAT                            ; Convert to BCD
        OR      AL,10h                  ; Set reset bit (disable)
        MOV     SW$TIME.DY,AL           ; ... and store in data buffer

        MOV     AL,DS$TIME.DM           ; Get day-of-month
        XLAT                            ; Convert to BCD
        MOV     SW$TIME.DM,AL           ; ... and store in data buffer

        MOV     AL,DS$TIME.MN           ; Get month
        XLAT                            ; Convert to BCD
        MOV     SW$TIME.MN,AL           ; ... and store in data buffer

        MOV     AL,DS$TIME.YY           ; Get year
        XLAT                            ; Convert to BCD
        MOV     SW$TIME.YY,AL           ; ... and store in data buffer
;----------------------------------------------------------------------;
;       Load current DOS time                                          ;
;----------------------------------------------------------------------;
        MOV     AL,DS$TIME.HH           ; Get hours
        XLAT                            ; Convert to BCD
        MOV     SW$TIME.HH,AL           ; ... and store in data buffer

        MOV     AL,DS$TIME.MM           ; Get minutes
        XLAT                            ; Convert to BCD
        MOV     SW$TIME.MM,AL           ; ... and store in data buffer

        MOV     AL,DS$TIME.SC           ; Get seconds
        XLAT                            ; Convert to BCD
        MOV     SW$TIME.SC,AL           ; ... and store in data buffer

        MOV     AL,DS$TIME.CC           ; Get centiseconds
        XLAT                            ; Convert to BCD
        MOV     SW$TIME.CC,AL           ; ... and store in data buffer
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  toggle oscillator
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  toggle oscillator                                 ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine toggles the oscillator bit in the SmartWatch.     ;
;----------------------------------------------------------------------;
OSC:    KEYACT  4400h,ZERO              ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Toggle the oscillator bit                                      ;
;----------------------------------------------------------------------;
        XOR     SW$TIME.DY,20h          ; Toggle the oscillator bit
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  zero time
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  zero time                                         ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine zeros the time in the SmartWatch.                 ;
;----------------------------------------------------------------------;
ZERO:   KEYACT  7000h,RST               ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Clear the SmartWatch data                                      ;
;----------------------------------------------------------------------;
        XOR     AX,AX                   ; Get a zero

        MOV     SW$TIME.CC,AL           ; Clear centiseconds
        MOV     SW$TIME.SC,AL           ; Clear seconds
        MOV     SW$TIME.MM,AL           ; Clear minutes
        MOV     SW$TIME.HH,AL           ; Clear hour
        MOV     SW$TIME.DY,10h          ; Clear day-of-week
        MOV     SW$TIME.DM,AL           ; Clear day-of-month
        MOV     SW$TIME.MN,AL           ; Clear month
        MOV     SW$TIME.YY,AL           ; Clear year
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  toggle reset
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  toggle reset                                      ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine toggles the reset bit in the SmartWatch.          ;
;----------------------------------------------------------------------;
RST:    KEYACT  7100h,A14               ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Toggle the reset bit                                           ;
;----------------------------------------------------------------------;
        XOR     SW$TIME.DY,10h          ; Toggle the reset bit
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  toggle A14
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  toggle A14                                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine toggles address line A14 in the memory segment.   ;
;----------------------------------------------------------------------;
A14:    KEYACT  5C00h,MODE              ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Toggle address line A14 (A13 for interleaved memory)           ;
;----------------------------------------------------------------------;
        XOR     SW$PARA,0400h           ; Toggle A14
        JMP     BEGIN                   ; Resume reading SmartWatch
        SUBTTL  Key action:  toggle time mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  toggle time mode                                  ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine toggles the time mode bit in the SmartWatch.      ;
;----------------------------------------------------------------------;
MODE:   KEYACT  5D00h,ACC               ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Toggle the mode bit                                            ;
;----------------------------------------------------------------------;
        XOR     SW$TIME.HH,80h          ; Toggle the mode bit
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  toggle access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  toggle access mode                                ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine toggles the access mode to the SmartWatch.        ;
;----------------------------------------------------------------------;
ACC:    KEYACT  6600h,APM               ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Toggle access mode and check for underflow.                    ;
;----------------------------------------------------------------------;
        DEC     SW$MODE                 ; Select new access mode
        JNZ     ACC_E                   ; ... and continue if not zero
        MOV     SW$MODE,5               ; Otherwise reset access mode

ACC_E:  JMP     BEGIN                   ; Resume reading SmartWatch
        SUBTTL  Key action:  toggle AM/PM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  toggle AM/PM                                      ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine toggles the AM/PM bit in the SmartWatch.          ;
;----------------------------------------------------------------------;
APM:    KEYACT  6700h,SINC              ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Toggle the AM/PM bit                                           ;
;----------------------------------------------------------------------;
        XOR     SW$TIME.HH,20h          ; Toggle the AM/PM bit
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        JMP     REWRITE                 ; Rewrite the SmartWatch data
        SUBTTL  Key action:  increment segment
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  increment segment                                 ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine increments the SmartWatch memory segment.         ;
;----------------------------------------------------------------------;
SINC:   KEYACT  4800h,SDEC              ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Increment the search segment and check for overflow.           ;
;----------------------------------------------------------------------;
        ADD     SW$PARA,0080h           ; Increment 2 kb
        JNC     SINC_E                  ; ... and continue if no overflow
        MOV     SW$PARA,0A000h          ; Otherwise reset to initial value

SINC_E: JMP     BEGIN                   ; Resume reading SmartWatch
        SUBTTL  Key action:  decrement segment
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Key action:  decrement segment                                 ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine decrements the SmartWatch memory segment.         ;
;----------------------------------------------------------------------;
SDEC:   KEYACT  5000h,EXIT              ; Continue if wrong key action
;----------------------------------------------------------------------;
;       Decrement the search segment and check for underflow.          ;
;----------------------------------------------------------------------;
        SUB     SW$PARA,0080h           ; Decrement 2 kb
        CMP     SW$PARA,0A000h          ; Check for underflow
        JGE     SDEC_E                  ; ... and continue if no overflow
        MOV     SW$PARA,0FF80h          ; Otherwise reset to high value

SDEC_E: JMP     BEGIN                   ; Resume reading SmartWatch
        SUBTTL  Rewrite SmartWatch time
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Rewrite SmartWatch time                                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine rewrites the SmartWatch time and restarts the     ;
;       display loop.                                                  ;
;----------------------------------------------------------------------;
REWRITE:CALL    WRITE                   ; Rewrite the data
        JMP     BEGIN                   ; ... and restart display loop
        SUBTTL  SmartWatch search routine
        PAGE       
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       SmartWatch search routine                                      ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine searches for a SmartWatch in the address space    ;
;       of the PC by performing the following series of actions:       ;
;                                                                      ;
;               - Initialize segment search at A000 hex, increment 1000;
;               - Read watch using test segment                        ;
;               - If data read is invalid, then reselect               ;
;                 segment using an updated segment value.              ;
;                                                                      ;
;       Invalid watch data is determined via the following criterion:  ;
;                                                                      ;
;               - data of all 0s or all 1s is invalid                  ;
;               - data of 1s in areas which always return 0s is invalid;
;----------------------------------------------------------------------;
;       Arguments:      SW$PARA contains the memory segment in which   ;
;                               the SmartWatch is positioned           ;
;                               (set by this routine)                  ;
;                       SW$TIME returns the current SmartWatch time    ;
;----------------------------------------------------------------------;
SEARCH  PROC    NEAR                    ; Read SmartWatch time
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;                                                                      ;
;       Initialize new increment and segment search                    ;
;                                                                      ;
;----------------------------------------------------------------------;
NEWINC: MOV     DX,01000h               ; Initialize search increment
NEWSEG: MOV     BX,0A000h               ; Initialize search segment
NEWMOD: MOV     SW$MODE,5               ; Initialize access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Abort search if a keyboard entry has occurred                  ;
;                                                                      ;
;----------------------------------------------------------------------;
        INTCALL 16h,0100h               ; Scan keyboard
        JZ      TSTSEG                  ; ... and continue if no activity

        JMP     FOUND                   ; Otherwise terminate processing
;----------------------------------------------------------------------;
;                                                                      ;
;       Read SmartWatch using current guess at the correct segment     ;
;                                                                      ;
;----------------------------------------------------------------------;
TSTSEG: MOV     SI,64                   ; Repeat search pattern 64 times
TSTCHK: MOV     SW$PARA,BX              ; Load the test segment value
        MOV     SW$STEP,DX              ; Load the test segment increment
        CALL    READ                    ; Read SmartWatch data

        CALL    UPDATE                  ; Update the display
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Check to see if the returned data is all zeros                 ;
;                                                                      ;
;----------------------------------------------------------------------;
;       If the returned data is all zeros then the segment is invalid  ;
;----------------------------------------------------------------------;
        MOV     CX,8                    ; Set string length
        LEA     DI,SW$TIME              ; Set string address
        XOR     AX,AX                   ; Set skip pattern

        REPE    SCASB                   ; Skip any repeated data
        JE      TSTNXT                  ; Invalid data - check next segment
;----------------------------------------------------------------------;
;                                                                      ;
;       Check to see if the returned data is all ones                  ;
;                                                                      ;
;----------------------------------------------------------------------;
;       If the returned data is all ones then the segment is invalid   ;
;----------------------------------------------------------------------;
        MOV     CX,8                    ; Set string length
        LEA     DI,SW$TIME              ; Set string address
        NOT     AX                      ; Set skip pattern

        REPE    SCASB                   ; Skip any repeated data
        JE      TSTNXT                  ; Invalid data - check next segment
;----------------------------------------------------------------------;
;                                                                      ;
;       Check to see if the returned data has invalid bits             ;
;                                                                      ;
;----------------------------------------------------------------------;
;       If data contains invalid bits then the segment is incorrect    ;
;----------------------------------------------------------------------;
        TEST    SW$TIME.SC,080h         ; Seconds range 00-59
        JNE     TSTNXT                  ; Invalid if high bit set

        TEST    SW$TIME.MM,080h         ; Minutes range 00-59
        JNE     TSTNXT                  ; Invalid if high bit set

        TEST    SW$TIME.HH,040h         ; Hours range 00-23
        JNE     TSTNXT                  ; Invalid if high bit set

        TEST    SW$TIME.DY,0C8h         ; Days range 01-07
        JNE     TSTNXT                  ; Invalid if high bits set

        TEST    SW$TIME.DM,0C0h         ; Date range 01-31
        JNE     TSTNXT                  ; Invalid if high bits set

        TEST    SW$TIME.MN,0E0h         ; Month range 01-12
        JNE     TSTNXT                  ; Invalid if high bits set

        DEC     SI                      ; Decrement certainty counter
        JNZ     TSTCHK                  ; ... and repeat search check
        JMP     FOUND                   ; All tests ok - watch found
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Search has failed - retry using a new segment guess            ;
;                                                                      ;
;----------------------------------------------------------------------;
TSTNXT: DEC     SW$MODE                 ; Decrement the search mode type
        JNE     TSTSEG                  ; ... and retry using this mode

        ADD     BX,DX                   ; Add increment to test segment
        JNC     NEWMOD                  ; ... and retest for SmartWatch

        SHR     DX,1                    ; Divide the search increment by 2
        AND     DX,0FFF0h               ; Mask to get 256-byte boundaries
        OR      DX,DX                   ; Test to see if increment zero
        JZ      TSTERR                  ; Signal error if we are done
        JMP     NEWSEG                  ; ... and continue if not zero

TSTERR: CALL    ERROR                   ; Signal an error condition
        JMP     NEWINC                  ; Otherwise restart the loop
;----------------------------------------------------------------------;
;       Return from SmartWatch service                                 ;
;----------------------------------------------------------------------;
FOUND:  POPALL                          ; Restore all registers
        RET                             ; Return to caller
SEARCH  ENDP
        SUBTTL  SmartWatch read routine
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       SmartWatch read routine                                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine resets the SmartWatch, transfers the required     ;
;       protocol, and then reads the current time using the transfer   ;
;       protocol of the SmartWatch.  Result is placed in SW$TIME.      ;
;----------------------------------------------------------------------;
;       Arguments:      SW$PARA contains the memory segment in which   ;
;                               the SmartWatch is positioned           ;
;                       SW$INIT contains 8 bytes of initialization     ;
;                       SW$TIME returns the current SmartWatch time    ;
;----------------------------------------------------------------------;
READ    PROC    NEAR                    ; Read SmartWatch time
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;                                                                      ;
;       Reset the SmartWatch                                           ;
;                                                                      ;
;----------------------------------------------------------------------;
        CALL    RESET                   ; Reset the SmartWatch
;----------------------------------------------------------------------;
;                                                                      ;
;       Transfer the SmartWatch protocol                               ;
;                                                                      ;
;----------------------------------------------------------------------;
        LEA     DI,SW$INIT              ; Load initialization protocol address
        CALL    WRT                     ; ... and write it to the Watch
;----------------------------------------------------------------------;
;       Load the address of the return time data buffer                ;
;----------------------------------------------------------------------;
        LEA     DI,SW$TIME              ; Load return time address
;----------------------------------------------------------------------;
;       Determine access mode which will be used with SmartWatch       ;
;----------------------------------------------------------------------;
        MOV     CX,SW$MODE              ; Get SmartWatch access mode
;----------------------------------------------------------------------;
;       Initialize data segment to that of the SmartWatch              ;
;----------------------------------------------------------------------;
        MOV     DS,SW$PARA              ; Load the SmartWatch data segment
        SUBTTL  Read - RAM bank 0 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - RAM bank 0 access mode                         ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_RAM0:CASE    CX,RD_RAM1              ; Skip if not RAM access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
        REPT    4                       ; Repeat for 8 bytes (4 words)

        REPT    16                      ; Repeat for 16 bits in each word
        MOV     AL,DS:[0000b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDM                            ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RD_EXT                  ; Return to caller
        SUBTTL  Read - RAM bank 1 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - RAM bank 1 access mode                         ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_RAM1:CASE    CX,RD_ROM               ; Skip if not RAM access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
        REPT    4                       ; Repeat for 8 bytes (4 words)

        REPT    16                      ; Repeat for 16 bits in each word
        MOV     AL,DS:[0001b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDM                            ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RD_EXT                  ; Return to caller
        SUBTTL  Read - ROM access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - ROM non-interleaved access mode                ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_ROM: CASE    CX,RD_ROM0              ; Skip if not ROM access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
        REPT    4                       ; Repeat for 8 bytes (4 words)

        REPT    16                      ; Repeat for 16 bits in each word
        MOV     AL,DS:[0100b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDM                            ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RD_EXT                  ; Return to caller
        SUBTTL  Read - ROM bank 0 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - ROM interleaved access mode bank 0             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_ROM0:CASE    CX,RD_ROM1              ; Skip if not ROM bank 0 access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
        REPT    4                       ; Repeat for 8 bytes (4 words)

        REPT    16                      ; Repeat for 16 bits in each word
        MOV     AL,DS:[1000b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDM                            ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RD_EXT                  ; Return to caller
        SUBTTL  Read - ROM bank 1 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - ROM interleaved access mode bank               ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_ROM1:CASE    CX,RD_EXT               ; Skip if not ROM bank 1 access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
        REPT    4                       ; Repeat for 8 bytes (4 words)

        REPT    16                      ; Repeat for 16 bits in each word
        MOV     AL,DS:[1001b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDM                            ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Return from SmartWatch service                                 ;
;----------------------------------------------------------------------;
RD_EXT: POPALL                          ; Restore all registers
        RET                             ; Return to caller
READ    ENDP
        SUBTTL  SmartWatch write routine
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       SmartWatch write routine                                       ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine resets the SmartWatch, transfers the required     ;
;       protocol, and then writes the current time using the transfer  ;
;       protocol of the SmartWatch.  Data is taken from SW$TIME.       ;
;----------------------------------------------------------------------;
;       Arguments:      SW$PARA contains the memory segment in which   ;
;                               the SmartWatch is positioned           ;
;                       SW$INIT contains 8 bytes of initialization     ;
;                       SW$TIME contains the time data to be written   ;
;----------------------------------------------------------------------;
WRITE   PROC    NEAR                    ; Write SmartWatch time
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;                                                                      ;
;       Reset the SmartWatch                                           ;
;                                                                      ;
;----------------------------------------------------------------------;
        CALL    RESET                   ; Reset the SmartWatch
;----------------------------------------------------------------------;
;                                                                      ;
;       Transfer the SmartWatch protocol                               ;
;                                                                      ;
;----------------------------------------------------------------------;
        LEA     DI,SW$INIT              ; Load initialization protocol address
        CALL    WRT                     ; ... and write it to the Watch
;----------------------------------------------------------------------;
;                                                                      ;
;       Transfer the SmartWatch data                                   ;
;                                                                      ;
;----------------------------------------------------------------------;
        LEA     DI,SW$TIME              ; Load time data buffer address
        CALL    WRT                     ; ... and write it to the Watch
;----------------------------------------------------------------------;
;       Return from SmartWatch service                                 ;
;----------------------------------------------------------------------;
        POPALL                          ; Restore all registers
        RET                             ; Return to caller
WRITE   ENDP
        SUBTTL  Write data bytes routine
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write data bytes routine                                       ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine transfers 8 bytes of data pointed to by [DI] to   ;
;       the SmartWatch via the write data function.                    ;
;----------------------------------------------------------------------;
;       Arguments:      ES:[DI] points to the data to be written.      ;
;----------------------------------------------------------------------;
WRT     PROC    NEAR                    ; Write data bytes
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Get address of the source time data buffer                     ;
;----------------------------------------------------------------------;
        MOV     SI,DI                   ; Get data buffer address
;----------------------------------------------------------------------;
;       Determine access mode which will be used with SmartWatch       ;
;----------------------------------------------------------------------;
        MOV     CX,SW$MODE              ; Get SmartWatch access mode
;----------------------------------------------------------------------;
;       Initialize data segment to that of the SmartWatch              ;
;----------------------------------------------------------------------;
        MOV     DS,SW$PARA              ; Load the SmartWatch data segment
        SUBTTL  Write - RAM bank 0 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - RAM bank 0 access mode                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_RAM0:CASE    CX,WT_RAM1              ; Skip if not RAM access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Write data buffer to the SmartWatch                            ;
;                                                                      ;
;----------------------------------------------------------------------;
        REPT    4                       ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source
                              
        REPT    16                      ; Repeat for 16 bits in each word
        MOV     DS:[0000b],AL           ; Write data byte (bit) to SmartWatch
        SHR     AX,1                    ; Rotate next bit to LSB
        ENDM                            ; Terminate bit fill repetition

        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     WT_EXT                  ; Return to caller
        SUBTTL  Write - RAM bank 1 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - RAM bank 1 access mode                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_RAM1:CASE    CX,WT_ROM               ; Skip if not RAM access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Write data buffer to the SmartWatch                            ;
;                                                                      ;
;----------------------------------------------------------------------;
        REPT    4                       ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source
                              
        REPT    16                      ; Repeat for 16 bits in each word
        MOV     DS:[0001b],AL           ; Write data byte (bit) to SmartWatch
        SHR     AX,1                    ; Rotate next bit to LSB
        ENDM                            ; Terminate bit fill repetition

        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     WT_EXT                  ; Return to caller
        SUBTTL  Write - ROM access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - ROM non-interleaved access mode               ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_ROM: CASE    CX,WT_ROM0              ; Skip if not ROM access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Write protocol and data buffers to the SmartWatch              ;
;                                                                      ;
;----------------------------------------------------------------------;
        MOV     BX,0010b                ; Get ROM write function


        REPT    4                       ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source

        REPT    16                      ; Repeat for 16 bits in each word
        SHR     BX,1                    ; Trash data bit of BX
        RCR     AX,1                    ; Get next data bit
        RCL     BX,1                    ; Load new data bit
        MOV     DL,[BX]                 ; Write bit to SmartWatch
        ENDM                            ; Terminate bit fill repetition

        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     WT_EXT                  ; Return to caller
        SUBTTL  Write - ROM bank 0 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - ROM interleaved access mode bank 0            ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_ROM0:CASE    CX,WT_ROM1              ; Skip if not ROM bank 0 access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Write protocol and data buffers to the SmartWatch              ;
;                                                                      ;
;----------------------------------------------------------------------;
        MOV     BX,0100b                ; Get ROM write function


        REPT    4                       ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source

        REPT    16                      ; Repeat for 16 bits in each word
        ROR     BX,1                    ; Save bank bit by shifting right
        SHR     BX,1                    ; Trash data bit of BX
        RCR     AX,1                    ; Get next data bit
        RCL     BX,1                    ; Load new data bit
        ROL     BX,1                    ; Restore bank bit by shifting left
        MOV     DL,[BX]                 ; Write bit to SmartWatch
        ENDM                            ; Terminate bit fill repetition

        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     WT_EXT                  ; Return to caller
        SUBTTL  Write - ROM bank 1 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - ROM interleaved access mode bank              ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_ROM1:CASE    CX,WT_EXT               ; Skip if not ROM bank 1 access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Write protocol and data buffers to the SmartWatch              ;
;                                                                      ;
;----------------------------------------------------------------------;
        MOV     BX,0101b                ; Get ROM write function


        REPT    4                       ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source

        REPT    16                      ; Repeat for 16 bits in each word
        ROR     BX,1                    ; Save bank bit by shifting right
        SHR     BX,1                    ; Trash data bit of BX
        RCR     AX,1                    ; Get next data bit
        RCL     BX,1                    ; Load new data bit
        ROL     BX,1                    ; Restore bank bit by shifting left
        MOV     DL,[BX]                 ; Write bit to SmartWatch
        ENDM                            ; Terminate bit fill repetition

        ENDM                            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Return from SmartWatch service                                 ;
;----------------------------------------------------------------------;
WT_EXT: POPALL                          ; Restore all registers
        RET                             ; Return to caller
WRT     ENDP
        SUBTTL  Reset SmartWatch routine
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Reset SmartWatch routine                                       ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine resets the SmartWatch by clocking through 65      ;
;       single-bit reads to flush any pending transfers.               ;
;----------------------------------------------------------------------;
;       Arguments:      SW$MODE indicates transfer mode type           ;
;                       SW$PARA contains the SmartWatch paragraph      ;
;----------------------------------------------------------------------;
RESET   PROC    NEAR                    ; Reset SmartWatch
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Determine access mode which will be used with SmartWatch       ;
;----------------------------------------------------------------------;
        MOV     CX,SW$MODE              ; Get SmartWatch access mode
;----------------------------------------------------------------------;
;       Initialize data segment to that of the SmartWatch              ;
;----------------------------------------------------------------------;
        MOV     DS,SW$PARA              ; Load the SmartWatch data segment
        SUBTTL  Reset - RAM bank 0 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Reset protocol - RAM bank 0 access mode                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RS_RAM0:CASE    CX,RS_RAM1              ; Skip if not RAM access mode
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
        REPT    65                      ; Repeat reset sequence
        MOV     AL,DS:[0000b]           ; Issue reset sequence
        ENDM                            ; Terminate repeat sequence
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RS_EXT                  ; Return to caller
        SUBTTL  Reset - RAM bank 1 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Reset protocol - RAM bank 1 access mode                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RS_RAM1:CASE    CX,RS_ROM               ; Skip if not RAM access mode
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
        REPT    65                      ; Repeat reset sequence
        MOV     AL,DS:[0001b]           ; Issue reset sequence
        ENDM                            ; Terminate repeat sequence
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RS_EXT                  ; Return to caller
        SUBTTL  Reset - ROM access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Reset protocol - ROM non-interleaved access mode               ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RS_ROM: CASE    CX,RS_ROM0              ; Skip if not ROM access mode
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
        REPT    65                      ; Repeat reset sequence
        MOV     AL,DS:[0100b]           ; Issue reset sequence
        ENDM                            ; Terminate repeat sequence
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RS_EXT                  ; Return to caller
        SUBTTL  Reset - ROM bank 0 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Reset protocol - ROM interleaved access mode bank 0            ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RS_ROM0:CASE    CX,RS_ROM1              ; Skip if not ROM bank 0 access mode
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
        REPT    65                      ; Repeat reset sequence
        MOV     AL,DS:[1000b]           ; Issue reset sequence
        ENDM                            ; Terminate repeat sequence
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     RS_EXT                  ; Return to caller
        SUBTTL  Reset - ROM bank 1 access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Reset protocol - ROM interleaved access mode bank              ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RS_ROM1:CASE    CX,RS_EXT               ; Skip if not ROM bank 1 access mode
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
        REPT    65                      ; Repeat reset sequence
        MOV     AL,DS:[1001b]           ; Issue reset sequence
        ENDM                            ; Terminate repeat sequence
;----------------------------------------------------------------------;
;       Return from SmartWatch service                                 ;
;----------------------------------------------------------------------;
RS_EXT: POPALL                          ; Restore all registers
        RET                             ; Return to caller
RESET   ENDP
        SUBTTL  Update the display screen
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Update the display                                             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine updates the display whenever the screen image     ;
;       is modified.                                                   ;
;----------------------------------------------------------------------;
UPDATE  PROC    NEAR                
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;                                                                      ;
;       Get DOS system time and display                                ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Get and save the current DOS date                              ;
;----------------------------------------------------------------------;
        INTCALL 21h,2A00h               ; Get current DOS date

        MOV     DS$TIME.DY,AL           ; Save day-of-week
        SUB     CX,1900                 ; Normalize year
        MOV     DS$TIME.YY,CL           ; Save year
        MOV     DS$TIME.MN,DH           ; Save month
        MOV     DS$TIME.DM,DL           ; Save day-of-month
;----------------------------------------------------------------------;
;       Get and save the current DOS time                              ;
;----------------------------------------------------------------------;
        INTCALL 21h,2C00h               ; Get current DOS time

        MOV     DS$TIME.HH,CH           ; Save hour
        MOV     DS$TIME.MM,CL           ; Save minutes
        MOV     DS$TIME.SC,DH           ; Save seconds
        MOV     DS$TIME.CC,DL           ; Save centiseconds
;----------------------------------------------------------------------;
;       Display current DOS date                                       ;
;----------------------------------------------------------------------;
        CONVERT DEC,18,17,DS$TIME.DM    ; Display day of month
        CONVERT    ,  ,26,DS$TIME.YY    ; Display year

        MOV     AL,DS$TIME.DY           ; Get day-of-week
        AND     AX,7                    ; Limit range of weekday
        SHLM    AX,2                    ; Calculate offset
        LEA     SI,DAY                  ; Get days of week table address
        ADD     SI,AX                   ; Point to day-of-week
        PRINT     3,  ,12               ; Display day-of-week

        MOV     AL,DS$TIME.MN           ; Get month
        DEC     AL                      ; Base index at 0
        AND     AX,0Fh                  ; ... and limit scope
        SHLM    AX,2                    ; Calculate offset
        LEA     SI,MON                  ; Get months of year table address
        ADD     SI,AX                   ; Point to month-of-year
        PRINT     3,  ,20               ; Display month-of-year
;----------------------------------------------------------------------;
;       Display current DOS time                                       ;
;----------------------------------------------------------------------;
        CONVERT DEC,  ,29,DS$TIME.HH    ; Display hour
        CONVERT    ,  ,32,DS$TIME.MM    ; Display minutes
        CONVERT    ,  ,35,DS$TIME.SC    ; Display seconds
        CONVERT    ,  ,38,DS$TIME.CC    ; Display centiseconds
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Get SmartWatch time and display                                ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Update the SmartWatch time displays                            ;
;----------------------------------------------------------------------;
        CONVERT HEX,08,12,SW$TIME.YY    ; Display data byte 7
        CONVERT    ,09,  ,SW$TIME.MN    ; Display data byte 6
        CONVERT    ,10,  ,SW$TIME.DM    ; Display data byte 5
        CONVERT    ,11,  ,SW$TIME.DY    ; Display data byte 4
        CONVERT    ,08,26,SW$TIME.HH    ; Display data byte 3
        CONVERT    ,09,  ,SW$TIME.MM    ; Display data byte 2
        CONVERT    ,10,  ,SW$TIME.SC    ; Display data byte 1
        CONVERT    ,11,  ,SW$TIME.CC    ; Display data byte 0
                                     
        CONVERT    ,19,26,SW$TIME.YY    ; Display year
        CONVERT    ,  ,17,SW$TIME.DM    ; Display day of month
        MOV     AL,SW$TIME.HH           ; Get current hour
        AND     AL,3Fh                  ; ... and mask time mode bit
        CONVERT    ,  ,29,              ; Display hour
        CONVERT    ,  ,32,SW$TIME.MM    ; Display minute
        CONVERT    ,  ,35,SW$TIME.SC    ; Display second
        CONVERT    ,  ,38,SW$TIME.CC    ; Display centisecond
;----------------------------------------------------------------------;
;       Update the SmartWatch day-of-week display                      ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.DY           ; Get day-of-week
        DEC     AL                      ; Base index at 0
        AND     AX,7                    ; Limit range of weekday
        SHLM    AX,2                    ; Calculate offset
        LEA     SI,DAY                  ; Get days of week table address
        ADD     SI,AX                   ; Point to day-of-week
        PRINT     3,19,12               ; Display day-of-week
;----------------------------------------------------------------------;
;       Update the SmartWatch month-of-year display                    ;
;----------------------------------------------------------------------;
        LEA     BX,BCDBIN               ; Get BCD-to-binary conversion table
        MOV     AL,SW$TIME.MN           ; Get month
        XLAT                            ; Convert BCD to binary
        DEC     AL                      ; Base index at 0
        AND     AX,0Fh                  ; Limit scope of result
        SHLM    AX,2                    ; Calculate offset
        LEA     SI,MON                  ; Get months of year table address
        ADD     SI,AX                   ; Point to month-of-year
        PRINT     3,19,20               ; Display month-of-year
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Update SmartWatch drift time displays                          ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Load the current SmartWatch time                               ;
;----------------------------------------------------------------------;
        MOV     CH,SW$TIME.HH           ; Get current hour
        MOV     CL,SW$TIME.MM           ; Get current minute
        MOV     DH,SW$TIME.SC           ; Get current second
        MOV     DL,SW$TIME.CC           ; Get current centisecond
;----------------------------------------------------------------------;
;       Normalize the SmartWatch hour to 24-hour (0-23) format         ;
;----------------------------------------------------------------------;
        TEST    CH,80h                  ; Check for 24-hour mode
        JNZ     DR_12H                  ; ... and skip if 12-hour mode
        AND     CH,7Fh                  ; Otherwise clear the mode bit
        JMP     DR_CVT                  ; ... and convert to binary

DR_12H: TEST    CH,20h                  ; Check for 12-hour P.M. mode
        JZ      DR_CVT                  ; ... and skip if A.M. mode
        AND     CH,1Fh                  ; Clear the AM/PM indicator
        ADD     CH,12h                  ; Convert to 24-hour format
        DAA                             ; ... and adjust for carry

        CMP     CH,23h                  ; Check for overflow...
        JLE     DR_CVT                  ; ... and continue if within bounds
        MOV     CH,00h                  ; Otherwise indicate midnight
;----------------------------------------------------------------------;
;       Convert BCD SmartWatch time to binary format                   ;
;----------------------------------------------------------------------;
DR_CVT: LEA     BX,BCDBIN               ; Get conversion table address

        IRP     REG,<CH,CL,DH,DL>       ; Convert hour, minute, second, centi
        MOV     AL,REG                  ; Get BCD value
        ADD     AL,0                    ; Clear carry flags
        DAA                             ; Convert to a normal BCD number
        XLAT                            ; Convert to binary format
        MOV     REG,AL                  ; ... and save for later use
        ENDM                            ; Terminate conversion
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Subtract DOS and SmartWatch times and display the difference   ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Restore current DOS date for time comparison                   ;
;----------------------------------------------------------------------;
        MOV     AH,DS$TIME.HH           ; Get DOS hour
        MOV     AL,DS$TIME.MM           ; Get DOS minute
        MOV     BH,DS$TIME.SC           ; Get DOS second
        MOV     BL,DS$TIME.CC           ; Get DOS centisecond
;----------------------------------------------------------------------;
;       Determine which time is largest:  DOS or SmartWatch            ;
;----------------------------------------------------------------------;
        IRP     CHK,<<AH,CH>,<AL,CL>,<BH,DH>,<BL,DL>>
        CMP     CHK                     ; DOS time greater than SMW time?
        JG      DR_DOS                  ; Yes, use DOS as major value
        JL      DR_SMW                  ; No,  use SMW as major value
        ENDM                            ; Terminate comparison
;----------------------------------------------------------------------;
;       DOS time is greater than DOS time - swap the two time values   ;
;----------------------------------------------------------------------;
DR_DOS: XCHG    AX,CX                   ; Make DOS time major value
        XCHG    BX,DX                   ; ... by swapping registers
;----------------------------------------------------------------------;
;       SmartWatch time is now guaranteed >= DOS time                  ;
;----------------------------------------------------------------------;
DR_SMW: SUB     DL,BL                   ; Subtract centiseconds
        JNC     DR_SC                   ; ... and continue if no borrow
        ADD     DL,100                  ; Otherwise compensate
        STC                             ; ... and set borrow flag

DR_SC:  SBB     DH,BH                   ; Subtract seconds
        JNC     DR_MM                   ; ... and continue if no borrow
        ADD     DH,60                   ; Otherwise compensate
        STC                             ; ... and set borrow flag

DR_MM:  SBB     CL,AL                   ; Subtract minutes
        JNC     DR_HH                   ; ... and continue if no borrow
        ADD     CL,60                   ; Otherwise compensate
        STC                             ; ... and set borrow flag

DR_HH:  SBB     CH,AH                   ; Subtract hours
        JNC     DR_DSP                  ; ... and continue if no borrow
        ADD     CH,24                   ; Otherwise compensate
        STC                             ; ... and set borrow flag
;----------------------------------------------------------------------;
;       Convert and display the SmartWatch drift time                  ;
;----------------------------------------------------------------------;
DR_DSP: CONVERT DEC,20,29,CH            ; Display drift hours
        CONVERT    ,  ,32,CL            ; Display drift minutes
        CONVERT    ,  ,35,DH            ; Display drift seconds
        CONVERT    ,  ,38,DL            ; Display drift centiseconds
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Update access mode type line                                   ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Display the type of access mode being used                     ;
;----------------------------------------------------------------------;
        LEA     SI,ACCMOD               ; Get access mode table address
        MOV     AX,SW$MODE              ; Get current access mode
        DEC     AX                      ; Base index at 0
        MOV     DX,AX                   ; ... and save it

        SHLM    AX,2                    ; Multiply by 4
        ADD     AX,DX                   ; ... and add once to make it 5
                   
        SHLM    AX,3                    ; Multiply by 8 to make it 40
        ADD     SI,AX                   ; Point to text string
        PRINT   040,22,00,              ; ... and print the message
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Update status display line                                     ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Update segment field                                           ;
;----------------------------------------------------------------------;
        MOV     AX,SW$PARA              ; Get current segment value
        CONVERT HEX,23,10,              ; Display search segment low

        MOV     AL,AH                   ; Get high byte of segment
        CONVERT    ,  ,08,              ; Display search segment high
;----------------------------------------------------------------------;
;       Update search increment field                                  ;
;----------------------------------------------------------------------;
        MOV     AX,SW$STEP              ; Get current search increment
        CONVERT    ,  ,24,              ; Display search increment low

        MOV     AL,AH                   ; Get high byte of increment
        CONVERT    ,  ,22,              ; Display search increment high
;----------------------------------------------------------------------;
;       Increment the interval counter                                 ;
;----------------------------------------------------------------------;
        STC                             ; Initial carry is 1

        IRP     BCD_DIG,<SW$CNT0,SW$CNT1,SW$CNT2,SW$CNT3>
        MOV     AL,BCD_DIG              ; Get the result          
        ADC     AL,0                    ; Add carry from last digit
        DAA                             ; Adjust for BCD addition
        MOV     BCD_DIG,AL              ; ... and save the result
        ENDM                            ; Terminate carry addition
;----------------------------------------------------------------------;
;       Update interval counter field                                  ;
;----------------------------------------------------------------------;
        CONVERT    ,  ,38,SW$CNT0       ; Print interval count 0
        CONVERT    ,  ,36,SW$CNT1       ; Print interval count 1
        CONVERT    ,  ,34,SW$CNT2       ; Print interval count 2
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Combine data and attribute screens and flush to display        ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Flush the screen buffer to the display                         ;
;----------------------------------------------------------------------;
        MOV     CX,(40*25)              ; Load word count
        LEA     SI,SCRBUF               ; Get screen buffer address
                
        MOV     AX,0B800h               ; Load display segment
        MOV     ES,AX                   ; ... and load segment register
        XOR     DI,DI                   ; Clear output offset
        
        REP     MOVSW                   ; Flush screen data to the display
;----------------------------------------------------------------------;
;       Terminate procedure                                            ;
;----------------------------------------------------------------------;
        POPALL                          ; Restore all registers
        RET                             ; Return to caller
UPDATE  ENDP
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Data conversion and output routine                             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine takes a byte and converts it to text, displaying  ;
;       the result at the desired row and column of the display map.   ;
;                                                                      ;
;       Upon entry, AL contains the byte to convert, BH contains the   ;
;       desired row, and BL contains the desired column for display.   ;
;       SI points to the conversion table address.                     ;
;----------------------------------------------------------------------;
CVT     PROC    NEAR                    ; Data conversion procedure
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Calculate the hex text value for the byte in question          ;
;----------------------------------------------------------------------;
        XOR     AH,AH                   ; Zero AH
        SHL     AX,1                    ; Convert word to byte index
        ADD     SI,AX                   ; Calculate index to text value
;----------------------------------------------------------------------;
;       Calculate cell address ((index = row * 40 + col) * 2)          ;
;----------------------------------------------------------------------;   
        MOV     AL,BH                   ; Get row counter
        CBW                             ; Zero AH
        MOV     DX,AX                   ; Save initial row count
        SHLM    AX,2                    ; Multiply by 4
        ADD     AX,DX                   ; Sum initial to multiply by 5
        SHLM    AX,3                    ; Multiply by 8
        XOR     BH,BH                   ; Zero upper column byte
        ADD     AX,BX                   ; ... and sum in the correct column
        SHL     AX,1                    ; Convert word to byte address

        LEA     DI,SCRBUF               ; Get screen buffer address
        ADD     DI,AX                   ; Point to first display byte
;----------------------------------------------------------------------;
;       Fill the output buffer with the result of the conversion       ;
;----------------------------------------------------------------------;
        REPT    2                       ; Repeat for each digit
        MOVSB                           ; Move one digit
        INC     DI                      ; ... and point to next output byte
        ENDM
;----------------------------------------------------------------------;
;       Terminate procedure                                            ;
;----------------------------------------------------------------------;
        POPALL                          ; Restore all registers
        RET                             ; Return to caller
CVT     ENDP
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Text print routine                                             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine takes a string and displays it starting at a      ;
;       specified row and column on the display.                       ;
;                                                                      ;
;       Upon entry, CX contains the byte count, BH contains the        ;
;       desired row, and BL contains the desired column for display.   ;
;       SI points to the first byte of the string to print.            ;
;----------------------------------------------------------------------;
PRT     PROC    NEAR                    ; Data printing procedure
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Calculate cell address ((index = row * 40 + col) * 2)          ;
;----------------------------------------------------------------------;   
        MOV     AL,BH                   ; Get row counter
        CBW                             ; Zero AH
        MOV     DX,AX                   ; Save initial row count
        SHLM    AX,2                    ; Multiply by 4
        ADD     AX,DX                   ; Sum initial to multiply by 5
        SHLM    AX,3                    ; Multiply by 8
        XOR     BH,BH                   ; Zero upper column byte
        ADD     AX,BX                   ; ... and sum in the correct column
        SHL     AX,1                    ; Convert word to byte address

        LEA     DI,SCRBUF               ; Get screen buffer address
        ADD     DI,AX                   ; Point to first display byte
;----------------------------------------------------------------------;
;       Move the text string to the output buffer                      ;
;----------------------------------------------------------------------;
PRT_LP: MOVSB                           ; Move one source byte
        INC     DI                      ; ... and point to next output area
        LOOP    PRT_LP                  ; Continue until done
;----------------------------------------------------------------------;
;       Terminate procedure                                            ;
;----------------------------------------------------------------------;
        POPALL                          ; Restore all registers
        RET                             ; Return to caller
PRT     ENDP
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Error processing routine                                       ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine is activated whenever an error condition is       ;
;       detected and an audible error indication should be output.     ;
;       This routine sounds the system bell and displays the message   ;
;       then returns to the caller. This routine take from the Peter   ;
;       Norton Programmer's Guide to the IBM PC, page 150.             ;
;----------------------------------------------------------------------;
ERROR   PROC    NEAR
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Initialize the programmable interval timer division count      ;
;----------------------------------------------------------------------;
        MOV     AL,0B6h                 ; Prepare timer for count
        OUT     67h,AL                  ;   by configuring PIT control port
        MOV     AL,08Dh                 ; LO byte - 1193280 / 3000
        OUT     66h,AL                  ;   for programmable timer
        MOV     AL,1                    ; HI byte - 1193280 / 3000
        OUT     66h,AL                  ;   for programmable timer
;----------------------------------------------------------------------;
;       Enable the speaker                                             ;
;----------------------------------------------------------------------;
        IN      AL,61h                  ; Get old port value
        OR      AL,03h                  ; Activate the speaker
        OUT     61h,AL                  ; ... and flush result to hardware
;----------------------------------------------------------------------;
;       Wait about 0.25 seconds to allow the indicator signal          ;
;----------------------------------------------------------------------;
        INTCALL 15h,8600h,,4,0          ; Delay 4*65536 microseconds
;----------------------------------------------------------------------;
;       Disable the speaker                                            ;
;----------------------------------------------------------------------;
        IN      AL,61h                  ; Get old port value
        XOR     AL,03h                  ; Kill the speaker
        OUT     61h,AL                  ; ... and flush result to hardware
;----------------------------------------------------------------------;
;       Return to caller                                               ;
;----------------------------------------------------------------------;
        POPALL                          ; Restore all registers
        RET                             ; Terminate interrupt service
ERROR   ENDP
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Break processing routine                                       ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine is whenever a control-break is detected by DOS.   ;
;----------------------------------------------------------------------;
BRK     PROC    FAR
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Restore screen attributes                                      ;
;----------------------------------------------------------------------;
        INTCALL 10h,0003h               ; Set display mode 80-column color
        INTCALL 10h,0500h               ; Set display page 0
        INTCALL 10h,0100h,,0007h        ; Set cursor size
        INTCALL 10h,0200h,0000h,,1901h  ; Home the cursor

        POPALL                          ; Restore all registers
        STC                             ; Set program terminate flag
;----------------------------------------------------------------------;
;       Terminate control-break processing                             ;
;----------------------------------------------------------------------;
        RET                             ; Return from interrupt
BRK     ENDP
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Terminate code segment and return to DOS                       ;
;                                                                      ;
;----------------------------------------------------------------------;
EXIT:   MOV     SP,BP                   ; Restore stack pointer
        POPALL                          ; Restore all registers
        RET                             ; Return to DOS
SMW     ENDP
$SMW    ENDS
;----------------------------------------------------------------------;
;       Terminate assembly                                             ;
;----------------------------------------------------------------------;
        END     START
