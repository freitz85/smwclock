        TITLE   SMW$CLOCK V01.02
        NAME    SMW$CLOCK
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
;       Module:         SMW$CLOCK                                      ;
;----------------------------------------------------------------------;
;       Programmer:     Kevin Klughart                                 ;
;----------------------------------------------------------------------;
;       Date:           28-Oct-1986 @ 11:00 CDST                       ;
;----------------------------------------------------------------------;
;       System:         IBM Personal Computer/AT running PC-DOS V3.10  ;
;----------------------------------------------------------------------;
;       Language:       IBM PC 80286 (Intel iAPX 286) assembly         ;
;----------------------------------------------------------------------;
;       Assembler:      Microsoft MACRO Assembler V4.00 [ONLY]         ;
;----------------------------------------------------------------------;
;       Site:           Dallas Semiconductor                           ;
;                       4350 Beltwood Parkway South                    ;
;                       Dallas, Texas 75244                            ;
;                       (214)  450-0400                                ;
;----------------------------------------------------------------------;
;       Purpose:        This program allows the DS1216E ROM SmartWatch ;
;                       to be used with IBM PC/XT/AT 8088/8086 CPUs    ;
;                       running under the MS-DOS operating system.     ;
;                                                                      ;
;                       This utility performs two functions:           ;
;                                                                      ;
;                       (1)  Allows the DS1216E SmartWatch time to     ;
;                            be loaded from the current DOS internal   ;
;                            clock.  This is the CALIBRATE option.     ;
;                                                                      ;
;                       (2)  Allows the current DOS internal clock     ;
;                            to be loaded from any available DS1216E   ;
;                            which can be located in the system        ;
;                            address map.  This is the SET_DOS_TIME    ;
;                            option.                                   ;
;                                                                      ;
;                       (3)  Allows the DS1216 to be located in the    ;
;                            system and the clock time to be displayed.;
;                            This is the FIND option.  (DEFAULT)       ;
;                                                                      ;
;                                                                      ;
;                       Invocation of this utility is as follows:      ;
;                                                                      ;
;                            A> SMWCLOCK [option]                      ;
;                                                                      ;
;                       Examples:                                      ;
;                                                                      ;
;                            A> SMWCLOCK calibrate    (Calibrate time) ;
;                            A> SMWCLOCK set_DOS_time (Set DOS time)   ;
;                            A> SMWCLOCK find         (Find SmartWatch);
;                            A> SMWCLOCK              (Find SmartWatch);
;----------------------------------------------------------------------;
;       Note:           This program is designed as a DOS COM image.   ;
;----------------------------------------------------------------------;
;       Revision list:  V01.00 - 24-Sep-1986, Kevin Klughart           ;
;                                Initial release.                      ;
;                                                                      ;
;                       V01.01 - 26-Sep-1986, Kevin Klughart           ;
;                                Speed up search logic by reducing     ;
;                                range of segments and cutting number  ;
;                                of test patterns for verification.    ;
;                                Display search paragraph for FIND.    ;
;                                                                      ;
;                       V01.02 - 28-Oct-1986, Kevin Klughart           ;
;                                Fix bug in setting of 24-hour mode.   ;
;                                24-hour mode is selected by clearing  ;
;                                rather than setting the mode bit.     ;
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
;       SHIFT arithmetic left multiple                                 ;
;                                                                      ;
;----------------------------------------------------------------------;
SHLM    MACRO   REG,CNT

        REPT    CNT                     ; For each shift
        SHL     REG,1                   ; Shift one left
        ENDM

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       SHIFT logical right multiple                                   ;
;                                                                      ;
;----------------------------------------------------------------------;
SHRM    MACRO   REG,CNT

        REPT    CNT                     ; For each shift
        SHR     REG,1                   ; Shift one right
        ENDM

        ENDM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Convert BCD to binary                                          ;
;                                                                      ;
;----------------------------------------------------------------------;
BCD_BIN MACRO   DST,SRC                 ; Convert value from BCD to binary

        MOV     AH,SRC                  ; Load source data
        MOV     DST,SRC                 ; Load output initially
        AND     DST,0Fh                 ; Strip high order nibble
        SHRM    AH,4                    ; Get high order nibble
        SHL     AH,1                    ; Multiply by 2
        ADD     DST,AH                  ; Add to the result
        SHLM    AH,2                    ; Multiply by 4
        ADD     DST,AH                  ; Generate final result sum

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Convert binary to BCD byte                                     ;
;                                                                      ;
;----------------------------------------------------------------------;
BIN_BCD MACRO   DST,SRC                 ; Convert value from binary to BCD

        PUSH    AX                      ; Save registers
        PUSH    DX                      ;
        MOV     AL,SRC                  ; Load source data
        XOR     DX,DX                   ; Clear upper dividend bits
        MOV     AH,DH                   ; Clear lower dividend bits
        MOV     BX,10                   ; Load divisor
        DIV     BX                      ; Divide AX by DX
        SHLM    AX,4                    ; Move divisor to high nibble
        OR      AL,DL                   ; ... and combine with lower nibble
        MOV     DST,AL                  ; Store resulting BCD value
        POP     DX                      ; Restore registers
        POP     AX                      ;

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Convert from binary to ASCII hexadecimal and print byte        ;
;                                                                      ;
;----------------------------------------------------------------------;
BIN_HEX MACRO   VALUE                   ; Convert value from binary to ASCII

        IFNB    <VALUE>                 ; If value specified
        MOV     DH,VALUE                ; Load display value
        ENDIF

        CALL    HEX                     ; Convert to ASCII hex

        ENDM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       PRINT byte/string to screen                                    ;
;                                                                      ;
;----------------------------------------------------------------------;
PRINT   MACRO   VALUE,STRING            ; Print value or DL contents
        LOCAL   LBL                     ; Text label
        LOCAL   SKIP                    ; Skip label

        IFNB    <VALUE>                 ; If register or value specified
        MOV     DL,VALUE                ; Load byte value
        ENDIF

        IFNB    <STRING>                ; If string print operation

        JMP     SHORT SKIP              ; Skip the text
LBL:    DB      STRING,'$'              ; Define the text

SKIP:   PUSH    AX                      ; Save registers
        PUSH    DX                      ;
        LEA     DX,LBL                  ; Get string offset
        MOV     AH,9                    ; Function:  print string
        INT     21h                     ; Request DOS service
        POP     DX                      ; Restore registers
        POP     AX                      ;

        ELSE                            ; Else if single byte

        MOV     AH,2                    ; Select DOS print function
        INT     21h                     ; Print the byte

        ENDIF                           ; Terminate conditional

        ENDM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       PUSHALL registers                                              ;
;                                                                      ;
;----------------------------------------------------------------------;
PUSHALL MACRO

        IRP     REG,<AX,BX,CX,DX,BP,SI,DI,DS,ES>
        PUSH    REG                     ; Push all registers
        ENDM                            ;
        PUSHF                           ; ... and PSW flags
        CLD                             ; Assume forward string search

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       POPALL registers                                               ;
;                                                                      ;
;----------------------------------------------------------------------;
POPALL  MACRO

        POPF                            ; Restore PSW flags
        IRP     REG,<ES,DS,DI,SI,BP,DX,CX,BX,AX>
        POP     REG                     ; Pop all registers
        ENDM                            ;

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Define repeat loop count and entrypoint                        ;
;                                                                      ;
;----------------------------------------------------------------------;
REPEAT  MACRO   LBL,CNT

        IFNB    <CNT>                   ; If count specified
        MOV     CX,CNT                  ; Load loop counter
        ENDIF                           ; Otherwise assume already loaded

LBL     LABEL   NEAR                    ; ... and define loop start
        PUSH    CX                      ; Save loop index counter

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Define repeat loop termination exitpoint                       ;
;                                                                      ;
;----------------------------------------------------------------------;
ENDR    MACRO   LBL,X

        POP     CX                      ; Restore loop counter
        LOOP&X  LBL                     ; ... and continue looping

        ENDM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Perform multi-way CASE branch                                  ;
;                                                                      ;
;----------------------------------------------------------------------;
CASE    MACRO   SR,BASE,LIMIT,PREFIX,DISPLIST
        LOCAL   SKIP
        LOCAL   VECTBL


        CMP     SR,LIMIT                ; Compare to limit
        JA      SKIP                    ; ... and skip if case invalid
        SUB     SR,BASE                 ; Subtract base
        JB      SKIP                    ; ... and skip if case invalid

        SAL     SR,1                    ; Convert word to byte offset
        JMP     WORD PTR CS:VECTBL[&SR&]; Vector via table

VECTBL:
        IRP     VECTOR,<DISPLIST>       ; Repeat for each entry
        CASEVEC PREFIX,VECTOR           ; Define case vector
        ENDM                            ; Terminate dispacement list
SKIP:                                   ; Skip here if no cases match


        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Perform multi-way CASE branch                                  ;
;                                                                      ;
;----------------------------------------------------------------------;
CASEVEC MACRO   FAC,LBL

        DW      OFFSET &FAC&LBL&        ; Define case vector

        ENDM
;----------------------------------------------------------------------;
;                                                                      ;
;       Define uppercase conversion macro                              ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Perform uppercase conversion on byte register                  ;
;----------------------------------------------------------------------;
UPCASE  MACRO   REG
        LOCAL   SKIP

        AND     REG,7Fh                 ; Strip parity bit
        CMP     REG,61h                 ; Too small?
        JL      SKIP                    ; Yes, skip conversion
        CMP     REG,7Ah                 ; Too large?
        JG      SKIP                    ; Yes, skip conversion
        AND     REG,5Fh                 ; Perform lower-to-upper conversion
SKIP:                                   ; ... and continue processing

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
        ASSUME  CS:$SMW,DS:$SMW,ES:$SMW,SS:$SMW
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Define program entrypoint                                      ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
        ORG     0100h
;----------------------------------------------------------------------;
;       Define procedure entry address and prepare for later exit      ;
;----------------------------------------------------------------------;
SMW     PROC    NEAR                    ; Define procedure entrypoint
        PUSHALL                         ; Save all registers
        MOV     BP,SP                   ; Save stack pointer
;----------------------------------------------------------------------;
;       Start processing by finding the SmartWatch                     ;
;----------------------------------------------------------------------;
        JMP     SEARCH                  ; ... and begin SmartWatch search
        PAGE
        EVEN
;----------------------------------------------------------------------;
;                                                                      ;
;       SmartWatch data areas                                          ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Search mode, segment, increment, and counters                  ;
;----------------------------------------------------------------------;
SW$MODE DW      0                       ; Watch access mode (1=ROM,2=ROM0,3=ROM1)
SW$PARA DW      0                       ; Memory segment for SmartWatch
;----------------------------------------------------------------------;
;       Define the time data structure                                 ;
;----------------------------------------------------------------------;
;       DS1216 devices have the following data fields:                 ;
;                                                                      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |    10 centisecond     |      centisecond      | (00-99)      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |      10 second        |        second         | (00-59)      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |      10 minute        |        minute         | (00-59)      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |12/24|  0  |AM/PM| hour|         hour          | (01-12/00-23);
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |  0  |  0  | osc |reset|  0  |       day       | (01-07)      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |  0  |  0  |  10 date  |         date          | (01-31)      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |  0  |  0  |  0  |month|         month         | (01-12)      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
;       |        10 year        |         year          | (00-99)      ;
;       +-----+-----+-----+-----+-----+-----+-----+-----+              ;
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
;       SmartWatch initialization sequence and time data buffer        ;
;----------------------------------------------------------------------;
SW$INIT DW      3AC5h,5CA3h,3AC5h,5CA3h ; Initialization protocol
SW$TIME TIME    <>                      ; SmartWatch read/write time buffer
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Day of week and month conversion tables                        ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Define days of the week                                        ;
;----------------------------------------------------------------------;
DAY     DB      '??? Sun Mon Tue Wed Thr Fri Sat '
;----------------------------------------------------------------------;
;       Define months of the year                                      ;
;----------------------------------------------------------------------;
MON     DB      '???-Jan-Feb-Mar-Apr-May-Jun-Jul-'
        DB      'Aug-Sep-???-???-???-???-???-???-'
        DB      'Oct-Nov-Dec-???-???-???-???-???-'
        DB      '???-???-???-???-???-???-???-???-'
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
;               - Initialize segment search at ^xC000, increment 64kb  ;
;               - Read watch using test segment                        ;
;               - If data read is invalid, then reselect               ;
;                 segment using an updated segment value.              ;
;                                                                      ;
;       Invalid watch data is determined via the following criterion:  ;
;                                                                      ;
;               - data of all 1s is invalid                            ;
;               - data of 1s in must-be-zero (MBZ) areas is invalid    ;
;                                                                      ;
;       A second level of testing is also performed in the event that  ;
;       the returned data meets the above criterion.  This involves    ;
;       rewriting the year field with a test pattern and then reading  ;
;       back the result.  If this can be done with a variety of data   ;
;       patterns, then the SmartWatch has in fact been located.        ;
;----------------------------------------------------------------------;
;       Arguments:      SW$PARA contains the memory segment in which   ;
;                               the SmartWatch is positioned           ;
;                               (set by this routine)                  ;
;                       SW$TIME returns the current SmartWatch time    ;
;----------------------------------------------------------------------;
;                                                                      ;
;       Initialize new increment and segment search                    ;
;                                                                      ;
;----------------------------------------------------------------------;
SEARCH: MOV     DX,01000h               ; Initialize search increment (64kb)
ADDRESS:MOV     SW$PARA,0C000h          ; Initialize search segment
MODE:   MOV     SW$MODE,3               ; Initialize access mode
;----------------------------------------------------------------------;
;                                                                      ;
;       Read SmartWatch using current guess at the correct segment     ;
;                                                                      ;
;----------------------------------------------------------------------;
CHECK:  CALL    READ                    ; Read SmartWatch data
;----------------------------------------------------------------------;
;                                                                      ;
;       Check to see if the returned data is all ones                  ;
;                                                                      ;
;----------------------------------------------------------------------;
;       If the returned data is all ones then the segment is invalid   ;
;----------------------------------------------------------------------;
        MOV     CX,4                    ; Set string length
        LEA     DI,SW$TIME              ; Set string address
        MOV     AX,0FFFFh               ; Set skip pattern

        REPE    SCASW                   ; Skip any repeated data
        JE      NEXT                    ; Invalid data - check next segment
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Check to see if the returned data has invalid bits             ;
;                                                                      ;
;----------------------------------------------------------------------;
;       If data contains invalid bits then the segment is incorrect.   ;
;       If data bits which are MBZ are in fact read as 1s, then we     ;
;       obviously have not found the correct SmartWatch segment.       ;
;----------------------------------------------------------------------;
        LEA     SI,SW$TIME              ; Get string address

        IRP     FIELD,<08000h,04080h,0C0C8h,000E0h>
        LODSW                           ; Get SmartWatch data word
        TEST    AX,FIELD                ; ... and check for invalid bits
        JNZ     NEXT                    ; Invalid if MBZ bits are set
        ENDM                            ; Terminate field check expansion
;----------------------------------------------------------------------;
;                                                                      ;
;       Verify SmartWatch location by writing year with data patterns  ;
;                                                                      ;
;----------------------------------------------------------------------;
        MOV     AH,SW$TIME.YY           ; Save the current year
        MOV     AL,80h                  ; Rolling bit test (8 patterns)

VERIFY: MOV     SW$TIME.YY,AL           ; Load test data pattern
        CALL    WRITE                   ; Rewrite the SmartWatch data
        CALL    READ                    ; Reread the SmartWatch data
        CMP     SW$TIME.YY,AL           ; Valid year returned?
        JNE     NEXT                    ; No, check next address segment
        SHR     AL,1                    ; Generate next data pattern
        JNZ     VERIFY                  ; ... and continue verification

        MOV     SW$TIME.YY,AH           ; Restore the original year
        CALL    WRITE                   ; ... and rewrite SmartWatch data
        JMP     COMMAND                 ; Process user command
;----------------------------------------------------------------------;
;                                                                      ;
;       Search has failed - retry using a new segment guess            ;
;                                                                      ;
;----------------------------------------------------------------------;
NEXT:   DEC     SW$MODE                 ; Decrement the search mode type
        JNE     CHECK                   ; ... and retry using this mode

        ADD     SW$PARA,DX              ; Add increment to test segment
        JNC     MODE                    ; ... and retest for SmartWatch

        SHR     DX,1                    ; Divide the search increment by 2
        AND     DX,0FF80h               ; Mask to get 2048-byte boundaries
        JNZ     ADDRESS                 ; ... and continue if not zero
;----------------------------------------------------------------------;
;       Watch not found!  Display error message and exit.              ;
;----------------------------------------------------------------------;
        PRINT   ,<'ERROR:  SmartWatch not found!'>
        JMP     EXIT                    ; Terminate program
        SUBTTL  Process user command
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Process user command                                           ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This code fragment scans the command line for a user command   ;
;       which may be one of Calibrate, Set_DOS_time, Find (default).   ;
;       Note that only the first character of the command is used      ;
;       to determine the command displatch.  Remaining bytes are       ;
;       ignored.                                                       ;
;----------------------------------------------------------------------;
;       Read command line bytes and ignore spaces                      ;
;----------------------------------------------------------------------;
COMMAND:MOV     SI,81h                  ; Point to start of command line
        XOR     BX,BX                   ; Initialize command vector

CMD:    LODSB                           ; Get a command line byte
        UPCASE  AL                      ; ... and convert to upper case
        CMP     AL,' '                  ; Space character?
        JB      VECTOR                  ; Terminate if control sequence
;----------------------------------------------------------------------;
;       Check for valid user commands (C/F/S)                          ;
;----------------------------------------------------------------------;
        MOV     BL,0                    ; Load vector index
        CMP     AL,'F'                  ; Find?
        JE      VECTOR                  ; Yes, dispatch command

        MOV     BL,1                    ; Load vector index
        CMP     AL,'C'                  ; Calibrate?
        JE      VECTOR                  ; Yes, dispatch command

        MOV     BL,2                    ; Load vector index
        CMP     AL,'S'                  ; Set DOS time?
        JNE     CMD                     ; No, check next byte
;----------------------------------------------------------------------;
;       Vector to action routine                                       ;
;----------------------------------------------------------------------;
VECTOR: CASE    BX,0,2,<>,<FIND,CAL,SET>
        JMP     DISPLAY                 ; Display if invalid command
        SUBTTL  Function:  find SmartWatch
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Function:  find SmartWatch                                     ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine displays the address in which the SmartWatch      ;
;       was found, and also indicates the type of SmartWatch access.   ;
;----------------------------------------------------------------------;
;       Display the SmartWatch segment address                         ;
;----------------------------------------------------------------------;
FIND:   PRINT   ,<'SmartWatch V01.02 found at address '>

        MOV     AX,SW$PARA              ; Get address segment
        BIN_HEX AH                      ; Display high nibble
        BIN_HEX AL                      ; Display low  nibble
        PRINT   ,<'0:  '>               ; Indicate paragraph address
;----------------------------------------------------------------------;
;       Display current time and return to caller                      ;
;----------------------------------------------------------------------;
        JMP     DISPLAY                 ; Display current time
        SUBTTL  Function:  calibrate time
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Function:  calibrate time                                      ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine calibrates the time in the SmartWatch by          ;
;       reading the current time from DOS and setting the SmartWatch   ;
;       accordingly, after making any necessary format conversions.    ;
;----------------------------------------------------------------------;
;       Get the current date from DOS                                  ;
;----------------------------------------------------------------------;
CAL:    MOV     AH,2Ah                  ; Function: get date
        INT     21h                     ; Request DOS service
;----------------------------------------------------------------------;
;       Load current DOS date                                          ;
;----------------------------------------------------------------------;
        INC     AL                      ; Correct offset for day-of-week
        BIN_BCD SW$TIME.DY,AL           ; Convert day-of-week
        OR      SW$TIME.DY,10h          ; Set reset bit (disable)

        BIN_BCD SW$TIME.DM,DL           ; Convert day-of-month
        BIN_BCD SW$TIME.MN,DH           ; Convert month

        SUB     CX,1900                 ; Subtract year offset
        BIN_BCD SW$TIME.YY,CL           ; Convert year
;----------------------------------------------------------------------;
;       Get the current time from DOS                                  ;
;----------------------------------------------------------------------;
        MOV     AH,2Ch                  ; Function: get time
        INT     21h                     ; Request DOS service
;----------------------------------------------------------------------;
;       Load current DOS time                                          ;
;----------------------------------------------------------------------;
        BIN_BCD SW$TIME.HH,CH           ; Convert hours
        AND     SW$TIME.HH,7Fh          ; Set 24 hour mode

        BIN_BCD SW$TIME.MM,CL           ; Convert minutes
        BIN_BCD SW$TIME.SC,DH           ; Convert seconds
        BIN_BCD SW$TIME.CC,DL           ; Convert centiseconds
;----------------------------------------------------------------------;
;       Rewrite the corrected SmartWatch data                          ;
;----------------------------------------------------------------------;
        CALL    WRITE                   ; Rewrite the SmartWatch data
;----------------------------------------------------------------------;
;       Display current time and return to caller                      ;
;----------------------------------------------------------------------;
        JMP     DISPLAY                 ; Display current time
        SUBTTL  Function:  set DOS time
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Function:  set DOS time                                        ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine sets the current DOS time base on the SmartWatch  ;
;       time, performing any BCD/BINARY format conversions required.   ;
;----------------------------------------------------------------------;
;       Load current DOS date                                          ;
;----------------------------------------------------------------------;
SET:    AND     SW$TIME.DY,7            ; Strip control bits in day field
        DEC     SW$TIME.DY              ; Correct offset for day-of-week
        BCD_BIN AL,SW$TIME.DY           ; Convert day-of-week

        BCD_BIN DL,SW$TIME.DM           ; Convert day-of-month
        BCD_BIN DH,SW$TIME.MN           ; Convert month

        XOR     CX,CX                   ; Clear resulting year
        BCD_BIN CL,SW$TIME.YY           ; Convert year
        ADD     CX,1900                 ; Add year offset
;----------------------------------------------------------------------;
;       Set the current DOS date                                       ;
;----------------------------------------------------------------------;
        MOV     AH,2Bh                  ; Function: set date
        INT     21h                     ; Request DOS service
;----------------------------------------------------------------------;
;       Load current DOS time                                          ;
;----------------------------------------------------------------------;
        AND     SW$TIME.HH,7Fh          ; Strip mode bit
        BCD_BIN CH,SW$TIME.HH           ; Convert hours

        BCD_BIN CL,SW$TIME.MM           ; Convert minutes
        BCD_BIN DH,SW$TIME.SC           ; Convert seconds
        BCD_BIN DL,SW$TIME.CC           ; Convert centiseconds
;----------------------------------------------------------------------;
;       Set the current DOS time                                       ;
;----------------------------------------------------------------------;
        MOV     AH,2Dh                  ; Function: set time
        INT     21h                     ; Request DOS service
;----------------------------------------------------------------------;
;       Reread the SmartWatch time for display purposes                ;
;----------------------------------------------------------------------;
        CALL    READ                    ; Read current SmartWatch time
;----------------------------------------------------------------------;
;       Display current time and return to caller                      ;
;----------------------------------------------------------------------;
        JMP     DISPLAY                 ; Display current time
        SUBTTL  Display the SmartWatch time
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Display the SmartWatch time                                    ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine converts and displays the SmartWatch data & time. ;
;----------------------------------------------------------------------;
;       Display the day-of-week                                        ;
;----------------------------------------------------------------------;
DISPLAY:MOV     AL,SW$TIME.DY           ; Get day-of-week
        AND     AX,7                    ; Limit range of weekday
        SHLM    AX,2                    ; Calculate offset (*4)
        LEA     SI,DAY                  ; Get days of week table address
        ADD     SI,AX                   ; Point to day-of-week

        REPT    4                       ; Display 4 bytes
        LODSB                           ; Get day-of-week text byte
        PRINT   AL                      ; ... and display it
        ENDM                            ; Terminate day of week display
;----------------------------------------------------------------------;
;       Display the day-of-month                                       ;
;----------------------------------------------------------------------;
        BIN_HEX SW$TIME.DM              ; Display day-of-month
        PRINT   <'-'>                   ;
;----------------------------------------------------------------------;
;       Display the month                                              ;
;----------------------------------------------------------------------;
        MOV     AL,SW$TIME.MN           ; Get month
        AND     AX,1Fh                  ; Limit scope of result
        SHLM    AX,2                    ; Calculate offset
        LEA     SI,MON                  ; Get months of year table address
        ADD     SI,AX                   ; Point to month-of-year

        REPT    4                       ; Display 4 bytes
        LODSB                           ; Get month text byte
        PRINT   AL                      ; ... and display it
        ENDM                            ; Terminate month display
;----------------------------------------------------------------------;
;       Display the year                                               ;
;----------------------------------------------------------------------;
        PRINT   <'1'>                   ;
        PRINT   <'9'>                   ;
        BIN_HEX SW$TIME.YY              ; Display year
        PRINT   <','>                   ;
        PRINT   <' '>                   ;
;----------------------------------------------------------------------;
;       Display the time                                               ;
;----------------------------------------------------------------------;
        AND     SW$TIME.HH,7Fh          ; Strip mode bit
        BIN_HEX SW$TIME.HH              ; Display hour
        PRINT   <':'>                   ;
        BIN_HEX SW$TIME.MM              ; Display minute
        PRINT   <':'>                   ;
        BIN_HEX SW$TIME.SC              ; Display second
        PRINT   <'.'>                   ;
        BIN_HEX SW$TIME.CC              ; Display centisecond
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Terminate update and return to DOS                             ;
;                                                                      ;
;----------------------------------------------------------------------;
EXIT:   MOV     SP,BP                   ; Restore stack pointer
        POPALL                          ; Restore all registers
        RET                             ; Return to DOS
SMW     ENDP
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
        CLI                             ; Inhibit system interrupts
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
        LEA     SI,SW$INIT              ; Load initialization protocol address
        CALL    WRT                     ; ... and write it to the Watch
;----------------------------------------------------------------------;
;       Load the address of the return time data buffer                ;
;----------------------------------------------------------------------;
        LEA     DI,SW$TIME              ; Load return time address
;----------------------------------------------------------------------;
;       Initialize data segment to that of the SmartWatch              ;
;----------------------------------------------------------------------;
        MOV     DS,CS:SW$PARA           ; Load the SmartWatch data segment
;----------------------------------------------------------------------;
;       Determine access mode which will be used with SmartWatch       ;
;----------------------------------------------------------------------;
        MOV     BX,CS:SW$MODE           ; Get SmartWatch access mode
;----------------------------------------------------------------------;
;       Vector to action routine based on SmartWatch access mode       ;
;----------------------------------------------------------------------;
        CASE    BX,1,3,<RD_>,<ROM,ROM0,ROM1>
        SUBTTL  Read - ROM access mode
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - ROM non-interleaved access mode                ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_ROM: REPEAT  RD_ROM_WORD,4           ; Repeat for 8 bytes (4 words)

        REPEAT  RD_ROM_BITS,16          ; Repeat for 16 bits in each word
        MOV     AL,DS:[0100b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDR    RD_ROM_BITS             ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDR    RD_ROM_WORD             ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     SHORT RD_EXT            ; Return to caller
        SUBTTL  Read - Interleaved ROM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - ROM interleaved access mode bank 0             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_ROM0:REPEAT  RD_ROM0_WORD,4          ; Repeat for 8 bytes (4 words)

        REPEAT  RD_ROM0_BITS,16         ; Repeat for 16 bits in each word
        MOV     AL,DS:[1000b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDR    RD_ROM0_BITS            ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDR    RD_ROM0_WORD            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     SHORT RD_EXT            ; Return to caller
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Read protocol - ROM interleaved access mode bank 1             ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;                                                                      ;
;       Read the current time from the SmartWatch                      ;
;                                                                      ;
;----------------------------------------------------------------------;
RD_ROM1:REPEAT  RD_ROM1_WORD,4          ; Repeat for 8 bytes (4 words)

        REPEAT  RD_ROM1_BITS,16         ; Repeat for 16 bits in each word
        MOV     AL,DS:[1001b]           ; Read data byte (bit) from SmartWatch
        RCR     AL,1                    ; Rotate LSB to carry bit
        RCR     BX,1                    ; Rotate LSB to MSB of result register
        ENDR    RD_ROM1_BITS            ; Terminate bit fill repetition

        MOV     AX,BX                   ; Get result data word
        STOSW                           ; Store the complete 16 bit result
        ENDR    RD_ROM1_WORD            ; Terminate word fill repetition
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
        CLI                             ; Inhibit system interrupts
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
        LEA     SI,SW$INIT              ; Load initialization protocol address
        CALL    WRT                     ; ... and write it to the Watch
;----------------------------------------------------------------------;
;                                                                      ;
;       Transfer the SmartWatch data                                   ;
;                                                                      ;
;----------------------------------------------------------------------;
        LEA     SI,SW$TIME              ; Load time data buffer address
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
;       This routine transfers 8 bytes of data pointed to by [SI] to   ;
;       the SmartWatch via the write data function.                    ;
;----------------------------------------------------------------------;
;       Arguments:      ES:[DI] points to the data to be written.      ;
;----------------------------------------------------------------------;
WRT     PROC    NEAR                    ; Write data bytes
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Initialize data segment to that of the SmartWatch              ;
;----------------------------------------------------------------------;
        MOV     DS,CS:SW$PARA           ; Load the SmartWatch data segment
;----------------------------------------------------------------------;
;       Determine access mode which will be used with SmartWatch       ;
;----------------------------------------------------------------------;
        MOV     BX,CS:SW$MODE           ; Get SmartWatch access mode
;----------------------------------------------------------------------;
;       Vector to action routine based on SmartWatch access mode       ;
;----------------------------------------------------------------------;
        CASE    BX,1,3,<WT_>,<ROM,ROM0,ROM1>
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - ROM non-interleaved access mode               ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_ROM: MOV     BX,0010b                ; Get ROM write function


        REPEAT  WT_ROM_WORD,4           ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source

        REPEAT  WT_ROM_BITS,16          ; Repeat for 16 bits in each word
        SHR     BX,1                    ; Trash data bit of BX
        RCR     AX,1                    ; Get next data bit
        RCL     BX,1                    ; Load new data bit
        MOV     DL,[BX]                 ; Write bit to SmartWatch
        ENDR    WT_ROM_BITS             ; Terminate bit fill repetition

        ENDR    WT_ROM_WORD             ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     SHORT WT_EXT            ; Return to caller
        SUBTTL  Write - Interleaved ROM
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - ROM interleaved access mode bank 0            ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_ROM0:MOV     BX,0100b                ; Get ROM write function


        REPEAT  WT_ROM0_WORD,4          ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source

        REPEAT  WT_ROM0_BITS,16         ; Repeat for 16 bits in each word
        ROR     BX,1                    ; Save bank bit by shifting right
        SHR     BX,1                    ; Trash data bit of BX
        RCR     AX,1                    ; Get next data bit
        RCL     BX,1                    ; Load new data bit
        ROL     BX,1                    ; Restore bank bit by shifting left
        MOV     DL,[BX]                 ; Write bit to SmartWatch
        ENDR    WT_ROM0_BITS            ; Terminate bit fill repetition

        ENDR    WT_ROM0_WORD            ; Terminate word fill repetition
;----------------------------------------------------------------------;
;       Terminate transfer operation                                   ;
;----------------------------------------------------------------------;
        JMP     SHORT WT_EXT            ; Return to caller
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Write protocol - ROM interleaved access mode bank 1            ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
WT_ROM1:MOV     BX,0101b                ; Get ROM write function


        REPEAT  WT_ROM1_WORD,4          ; Repeat for 8 bytes (4 words)
        LODS    WORD PTR ES:[SI]        ; Load the complete 16 bit source

        REPEAT  WT_ROM1_BITS,16         ; Repeat for 16 bits in each word
        ROR     BX,1                    ; Save bank bit by shifting right
        SHR     BX,1                    ; Trash data bit of BX
        RCR     AX,1                    ; Get next data bit
        RCL     BX,1                    ; Load new data bit
        ROL     BX,1                    ; Restore bank bit by shifting left
        MOV     DL,[BX]                 ; Write bit to SmartWatch
        ENDR    WT_ROM1_BITS            ; Terminate bit fill repetition

        ENDR    WT_ROM1_WORD            ; Terminate word fill repetition
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
;       Load loop counter for reset operation                          ;
;----------------------------------------------------------------------;
        MOV     CX,65                   ; Load reset loop counter
;----------------------------------------------------------------------;
;       Initialize data segment to that of the SmartWatch              ;
;----------------------------------------------------------------------;
        MOV     DS,CS:SW$PARA           ; Load the SmartWatch data segment
;----------------------------------------------------------------------;
;       Determine access mode which will be used with SmartWatch       ;
;----------------------------------------------------------------------;
        MOV     BX,CS:SW$MODE           ; Get SmartWatch access mode
;----------------------------------------------------------------------;
;       Vector to action routine based on SmartWatch access mode       ;
;----------------------------------------------------------------------;
        CASE    BX,1,3,<RS_>,<ROM,ROM0,ROM1>
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;       Reset protocol - ROM non-interleaved access mode               ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
RS_ROM: MOV     AL,DS:[0100b]           ; Issue reset sequence
        LOOP    RS_ROM                  ; Terminate repeat sequence

        JMP     SHORT RS_EXT            ; Return to caller
;----------------------------------------------------------------------;
;                                                                      ;
;       Reset protocol - ROM interleaved access mode bank 0            ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
RS_ROM0:MOV     AL,DS:[1000b]           ; Issue reset sequence
        LOOP    RS_ROM0                 ; Terminate repeat sequence

        JMP     SHORT RS_EXT            ; Return to caller
;----------------------------------------------------------------------;
;                                                                      ;
;       Reset protocol - ROM interleaved access mode bank 1            ;
;                                                                      ;
;----------------------------------------------------------------------;
;       Reset the SmartWatch by performing 65 consecutive reads.       ;
;----------------------------------------------------------------------;
RS_ROM1:MOV     AL,DS:[1001b]           ; Issue reset sequence
        LOOP    RS_ROM1                 ; Terminate repeat sequence
;----------------------------------------------------------------------;
;       Return from SmartWatch service                                 ;
;----------------------------------------------------------------------;
RS_EXT: POPALL                          ; Restore all registers
        RET                             ; Return to caller
RESET   ENDP
        SUBTTL  Binary to hexadecimal conversion
        PAGE
;----------------------------------------------------------------------;
;                                                                      ;
;                                                                      ;
;       Binary to hexadecimal conversion                               ;
;                                                                      ;
;                                                                      ;
;----------------------------------------------------------------------;
;       This routine converts the binary number in DH to ASCII hex     ;
;       and displays the result to the screen using DOS functions.     ;
;----------------------------------------------------------------------;
;       Arguments:      DH is the byte to be converted and printed     ;
;----------------------------------------------------------------------;
HEX     PROC    NEAR                    ; Convert to ASCII hex
        PUSHALL                         ; Save all registers
;----------------------------------------------------------------------;
;       Convert and display four nibbles, starting with high nibble    ;
;----------------------------------------------------------------------;
        REPEAT  HEX_LOOP,2              ; Repeat 2 times
        ROL     DH,1                    ; Position the next nibble
        ROL     DH,1                    ;
        ROL     DH,1                    ;
        ROL     DH,1                    ;
        MOV     DL,DH                   ; Save nibble data
        AND     DL,0Fh                  ; Isolate 4 bit nibble
        ADD     DL,'0'                  ; Convert nibble to ASCII

        CMP     DL,'9'                  ; Greater than 9?
        JLE     HEX_OUT                 ; No, continue
        ADD     DL,7                    ; Yes, convert to A-F

HEX_OUT:PRINT                           ; Display the result byte
        ENDR    HEX_LOOP                ; Convert additional nibbles
;----------------------------------------------------------------------;
;       Terminate procedure                                            ;
;----------------------------------------------------------------------;
        POPALL                          ; Restore all registers
        RET                             ; Return to caller
HEX     ENDP                            ; Return to caller
;----------------------------------------------------------------------;
;       Terminate assembly                                             ;
;----------------------------------------------------------------------;
$SMW    ENDS
        END     SMW
