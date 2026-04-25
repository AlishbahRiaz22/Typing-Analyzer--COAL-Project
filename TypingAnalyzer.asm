; ============================================================
;  Typing Speed & Accuracy Analyzer  v2.0
;  COAL Project | MASM615 + Irvine32
;
;  Build:
;    ml /c /coff TypingAnalyzer.asm
;    link /subsystem:console TypingAnalyzer.obj irvine32.lib kernel32.lib user32.lib
; ============================================================

INCLUDE Irvine32.inc

; ---- constants ---------------------------------------------
INPUT_MAX   EQU 100
EASY_CNT    EQU 4
MED_CNT     EQU 4
HARD_CNT    EQU 4

.data

; ============================================================
;  SENTENCE POOLS  (name + length stored together)
; ============================================================

; EASY
str_ez0  BYTE "the cat sat on the mat",0
str_ez1  BYTE "i like to eat good food",0
str_ez2  BYTE "the dog ran in the park",0
str_ez3  BYTE "she had a big red ball",0

tbl_ezPtr  DWORD OFFSET str_ez0, OFFSET str_ez1, OFFSET str_ez2, OFFSET str_ez3
tbl_ezLen  DWORD 22, 23, 23, 22

; MEDIUM
str_md0  BYTE "practice makes a man perfectly skilled",0
str_md1  BYTE "the quick brown fox jumps over the dog",0
str_md2  BYTE "assembly language is fast and powerful",0
str_md3  BYTE "every good programmer thinks before coding",0

tbl_mdPtr  DWORD OFFSET str_md0, OFFSET str_md1, OFFSET str_md2, OFFSET str_md3
tbl_mdLen  DWORD 38, 38, 38, 42

; HARD
str_hd0  BYTE "the complexity of modern software demands rigorous testing",0
str_hd1  BYTE "a dedicated programmer writes efficient and maintainable code",0
str_hd2  BYTE "understanding memory management is crucial in systems programming",0
str_hd3  BYTE "the quick analysis of algorithms improves computational efficiency",0

tbl_hdPtr  DWORD OFFSET str_hd0, OFFSET str_hd1, OFFSET str_hd2, OFFSET str_hd3
tbl_hdLen  DWORD 57, 60, 63, 65

; ============================================================
;  ASCII ART SPLASH  (simple, no backslash confusion)
; ============================================================
art_L1  BYTE "  =============================================",13,10,0
art_L2  BYTE "  ||                                         ||",13,10,0
art_L3  BYTE "  ||   _______ __   __ ____  ___ _  _  ___  ||",13,10,0
art_L4  BYTE "  ||     | \ \/ /| |) ||___)|_ | |\ | |___| ||",13,10,0
art_L5  BYTE "  ||     |  |  | |_/ /|    |__ | | \| |   | ||",13,10,0
art_L6  BYTE "  ||                                         ||",13,10,0
art_L7  BYTE "  ||    A N A L Y Z E R   v 2 . 0           ||",13,10,0
art_L8  BYTE "  ||      Speed  &  Accuracy  Checker        ||",13,10,0
art_L9  BYTE "  ||                                         ||",13,10,0
art_L10 BYTE "  =============================================",13,10,0
art_L11 BYTE 13,10,"         Press any key to begin...",13,10,0

; ============================================================
;  MENUS & PROMPTS
; ============================================================
msg_menuTop   BYTE 13,10
              BYTE "  +------------------------------------------+",13,10
              BYTE "  |       SELECT DIFFICULTY LEVEL           |",13,10
              BYTE "  +------------------------------------------+",13,10
              BYTE "  |                                          |",13,10
              BYTE "  |   [1]  EASY    - Short simple phrases   |",13,10
              BYTE "  |   [2]  MEDIUM  - Standard sentences     |",13,10
              BYTE "  |   [3]  HARD    - Long complex sentences  |",13,10
              BYTE "  |   [0]  EXIT                              |",13,10
              BYTE "  |                                          |",13,10
              BYTE "  +------------------------------------------+",13,10
              BYTE "  Choice: ",0

msg_badKey    BYTE 13,10,"  Invalid key. Press 1, 2, 3 or 0.",13,10,0
msg_selEasy   BYTE 13,10,"  >> EASY selected. Good luck!",13,10,0
msg_selMed    BYTE 13,10,"  >> MEDIUM selected. Stay focused!",13,10,0
msg_selHard   BYTE 13,10,"  >> HARD selected. You asked for it!",13,10,0

msg_instrTop  BYTE 13,10
              BYTE "  Type the sentence below EXACTLY:",13,10
              BYTE "  ------------------------------------------",13,10
              BYTE "  ",0
msg_instrBot  BYTE 13,10
              BYTE "  ------------------------------------------",13,10,0

msg_getready  BYTE 13,10,"  Get ready...",13,10,0
msg_cnt3      BYTE "    3...",13,10,0
msg_cnt2      BYTE "    2...",13,10,0
msg_cnt1      BYTE "    1...",13,10,0
msg_go        BYTE "    GO!",13,10,13,10,0
msg_prompt    BYTE "  > ",0

msg_resHdr    BYTE 13,10
              BYTE "  +------------------------------------------+",13,10
              BYTE "  |              YOUR RESULTS                |",13,10
              BYTE "  +------------------------------------------+",13,10,0
msg_correct   BYTE "  |  Correct characters : ",0
msg_wrong     BYTE "  |  Wrong   characters : ",0
msg_total     BYTE "  |  Total   characters : ",0
msg_accuracy  BYTE "  |  Accuracy           : ",0
msg_wpm       BYTE "  |  Estimated WPM      : ",0
msg_resFtr    BYTE "  +------------------------------------------+",13,10,0

msg_pct       BYTE " %",13,10,0
msg_wpmU      BYTE " wpm",13,10,0
msg_nl        BYTE 13,10,0
msg_sp        BYTE " ",0

msg_great     BYTE 13,10,"  *** EXCELLENT! Outstanding performance! ***",13,10,0
msg_good      BYTE 13,10,"  *** Good job! Keep practicing! ***",13,10,0
msg_poor      BYTE 13,10,"  *** Keep going! You will improve! ***",13,10,0

msg_again     BYTE 13,10,"  Play again? (Y/N): ",0
msg_bye       BYTE 13,10,"  Thanks for playing. Goodbye, Commander!",13,10
              BYTE 13,10,"  Press any key to exit...",13,10,0

; ============================================================
;  RUNTIME VARIABLES
; ============================================================
g_inputBuf   BYTE INPUT_MAX+2 DUP(0)   ; +2: null + safety byte
g_correct    DWORD 0
g_wrong      DWORD 0
g_startMs    DWORD 0
g_endMs      DWORD 0
g_elapsedS   DWORD 0
g_wpm        DWORD 0
g_accuracy   DWORD 0
g_inputLen   DWORD 0
g_sentLen    DWORD 0
g_sentPtr    DWORD 0
g_diff       DWORD 0    ; 1=easy 2=med 3=hard
g_poolCnt    DWORD 0

; ============================================================
.code
; ============================================================

; ------------------------------------------------------------
;  ShowSplash
; ------------------------------------------------------------
ShowSplash PROC
    mov  eax, cyan
    call SetTextColor

    mov  edx, OFFSET art_L1
    call WriteString
    mov  edx, OFFSET art_L2
    call WriteString
    mov  edx, OFFSET art_L3
    call WriteString
    mov  edx, OFFSET art_L4
    call WriteString
    mov  edx, OFFSET art_L5
    call WriteString
    mov  edx, OFFSET art_L6
    call WriteString

    mov  eax, yellow
    call SetTextColor

    mov  edx, OFFSET art_L7
    call WriteString
    mov  edx, OFFSET art_L8
    call WriteString
    mov  edx, OFFSET art_L9
    call WriteString

    mov  eax, cyan
    call SetTextColor

    mov  edx, OFFSET art_L10
    call WriteString

    mov  eax, white
    call SetTextColor

    mov  edx, OFFSET art_L11
    call WriteString

    call ReadChar       ; wait for any key — ReadChar is fine here
                        ; (no Delay before it, no stale buffer)
    ret
ShowSplash ENDP

; ------------------------------------------------------------
;  ShowDiffMenu
;  Returns EAX = 1 (chosen) or 0 (exit)
; ------------------------------------------------------------
ShowDiffMenu PROC
SDM_Top:
    call Clrscr
    mov  eax, white
    call SetTextColor

    mov  edx, OFFSET msg_menuTop
    call WriteString

    call ReadChar           ; read one key, no echo yet
    mov  bl, al             ; save key

    ; echo the key then newline
    call WriteChar
    mov  edx, OFFSET msg_nl
    call WriteString

    cmp  bl, '0'
    je   SDM_Exit
    cmp  bl, '1'
    je   SDM_Easy
    cmp  bl, '2'
    je   SDM_Med
    cmp  bl, '3'
    je   SDM_Hard

    ; invalid key
    mov  edx, OFFSET msg_badKey
    call WriteString
    jmp  SDM_Top

SDM_Easy:
    mov  g_diff,    1
    mov  g_poolCnt, EASY_CNT
    mov  eax, green
    call SetTextColor
    mov  edx, OFFSET msg_selEasy
    call WriteString
    mov  eax, white
    call SetTextColor
    mov  eax, 1
    ret

SDM_Med:
    mov  g_diff,    2
    mov  g_poolCnt, MED_CNT
    mov  eax, yellow
    call SetTextColor
    mov  edx, OFFSET msg_selMed
    call WriteString
    mov  eax, white
    call SetTextColor
    mov  eax, 1
    ret

SDM_Hard:
    mov  g_diff,    3
    mov  g_poolCnt, HARD_CNT
    mov  eax, red
    call SetTextColor
    mov  edx, OFFSET msg_selHard
    call WriteString
    mov  eax, white
    call SetTextColor
    mov  eax, 1
    ret

SDM_Exit:
    mov  eax, 0
    ret
ShowDiffMenu ENDP

; ------------------------------------------------------------
;  PickSentence  — sets g_sentPtr and g_sentLen
; ------------------------------------------------------------
PickSentence PROC
    push eax
    push ebx
    push ecx
    push edx

    call GetMseconds
    xor  edx, edx
    mov  ecx, g_poolCnt
    div  ecx                ; EDX = 0..poolCnt-1 (random index)

    mov  eax, edx
    shl  eax, 2             ; *4 = DWORD offset

    mov  ebx, g_diff
    cmp  ebx, 1
    je   PS_Easy
    cmp  ebx, 2
    je   PS_Med
    ; fall through = Hard
PS_Hard:
    mov  ebx, tbl_hdPtr[eax]
    mov  g_sentPtr, ebx
    mov  ebx, tbl_hdLen[eax]
    mov  g_sentLen, ebx
    jmp  PS_Done
PS_Easy:
    mov  ebx, tbl_ezPtr[eax]
    mov  g_sentPtr, ebx
    mov  ebx, tbl_ezLen[eax]
    mov  g_sentLen, ebx
    jmp  PS_Done
PS_Med:
    mov  ebx, tbl_mdPtr[eax]
    mov  g_sentPtr, ebx
    mov  ebx, tbl_mdLen[eax]
    mov  g_sentLen, ebx
PS_Done:
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret
PickSentence ENDP

; ------------------------------------------------------------
;  ReadLineInput — uses Irvine ReadString (handles backspace,
;  echoes chars, waits for Enter, returns count in EAX)
; ------------------------------------------------------------
ReadLineInput PROC
    push eax
    push ecx
    push edx
    push edi

    ; zero out buffer safely
    mov  edi, OFFSET g_inputBuf
    mov  ecx, INPUT_MAX+2
    xor  eax, eax
    rep  stosb

    mov  edx, OFFSET g_inputBuf
    mov  ecx, INPUT_MAX
    call ReadString         ; EAX = number of chars read
    mov  g_inputLen, eax

    pop  edi
    pop  edx
    pop  ecx
    pop  eax
    ret
ReadLineInput ENDP

; ------------------------------------------------------------
;  CompareStrings — tallies correct/wrong chars
; ------------------------------------------------------------
CompareStrings PROC
    push eax
    push ebx
    push ecx
    push esi
    push edi

    mov  esi, g_sentPtr
    mov  edi, OFFSET g_inputBuf
    mov  ecx, g_sentLen

CS_Loop:
    mov  al, BYTE PTR [esi]
    mov  bl, BYTE PTR [edi]

    cmp  bl, 0
    je   CS_Wrong
    cmp  al, bl
    je   CS_Correct

CS_Wrong:
    inc  g_wrong
    jmp  CS_Next

CS_Correct:
    inc  g_correct

CS_Next:
    inc  esi
    inc  edi
    loop CS_Loop

    pop  edi
    pop  esi
    pop  ecx
    pop  ebx
    pop  eax
    ret
CompareStrings ENDP

; ============================================================
;  main
; ============================================================
main PROC

    ; Move cursor to absolute top-left first, THEN clear.
    ; Without GotoXY, Clrscr only clears from wherever the cursor
    ; currently sits (e.g. after compilation output), leaving old
    ; text visible above. GotoXY(0,0) homes the cursor so Clrscr
    ; wipes the entire visible window from the top.
    mov  dh, 0          ; row 0
    mov  dl, 0          ; col 0
    call Gotoxy
    call Clrscr
    call ShowSplash

ML_DiffSelect:
    call ShowDiffMenu
    cmp  eax, 0
    je   ML_Exit

ML_GameLoop:
    ; reset per-round stats
    mov  g_correct,  0
    mov  g_wrong,    0
    mov  g_inputLen, 0

    call PickSentence

    ; clear screen before each round
    call Clrscr

    ; --- show target sentence ---
    mov  edx, OFFSET msg_instrTop
    call WriteString

    mov  eax, white
    call SetTextColor
    mov  edx, g_sentPtr
    call WriteString

    mov  eax, white
    call SetTextColor
    mov  edx, OFFSET msg_instrBot
    call WriteString

    ; --- colour the countdown by difficulty ---
    mov  ebx, g_diff
    cmp  ebx, 1
    je   ML_CntEasy
    cmp  ebx, 2
    je   ML_CntMed
    mov  eax, red           ; hard
    call SetTextColor
    jmp  ML_CntStart
ML_CntEasy:
    mov  eax, green
    call SetTextColor
    jmp  ML_CntStart
ML_CntMed:
    mov  eax, yellow
    call SetTextColor

ML_CntStart:
    mov  edx, OFFSET msg_getready
    call WriteString

    mov  edx, OFFSET msg_cnt3
    call WriteString
    mov  eax, 1000
    call Delay

    mov  edx, OFFSET msg_cnt2
    call WriteString
    mov  eax, 1000
    call Delay

    mov  edx, OFFSET msg_cnt1
    call WriteString
    mov  eax, 1000
    call Delay

    mov  eax, white
    call SetTextColor
    mov  edx, OFFSET msg_go
    call WriteString

    ; --- start timer, get input, stop timer ---
    call GetMseconds
    mov  g_startMs, eax

    mov  edx, OFFSET msg_prompt
    call WriteString
    call ReadLineInput

    call GetMseconds
    mov  g_endMs, eax

    ; --- compare ---
    call CompareStrings

    ; clear screen before showing results
    call Clrscr

    ; --- accuracy = (g_correct * 100) / g_sentLen ---
    mov  eax, g_correct
    mov  ebx, 100
    mul  ebx                ; EDX:EAX = correct * 100
    mov  ebx, g_sentLen
    cmp  ebx, 0
    jne  ML_AccDiv
    mov  ebx, 1
ML_AccDiv:
    xor  edx, edx
    div  ebx
    mov  g_accuracy, eax

    ; --- WPM = (inputLen / 5) * 60 / elapsedSec ---
    mov  eax, g_endMs
    sub  eax, g_startMs
    cmp  eax, 1
    jae  ML_MsOk
    mov  eax, 1
ML_MsOk:
    xor  edx, edx
    mov  ebx, 1000
    div  ebx               ; EAX = seconds
    cmp  eax, 1
    jae  ML_SecOk
    mov  eax, 1
ML_SecOk:
    mov  g_elapsedS, eax

    mov  eax, g_inputLen
    xor  edx, edx
    mov  ebx, 5
    div  ebx               ; EAX = word count
    cmp  eax, 1
    jae  ML_WordOk
    mov  eax, 1
ML_WordOk:
    mov  ebx, 60
    mul  ebx               ; EAX = words * 60
    xor  edx, edx
    div  g_elapsedS
    mov  g_wpm, eax

    ; --- print results ---
    mov  eax, white
    call SetTextColor

    mov  edx, OFFSET msg_resHdr
    call WriteString

    mov  edx, OFFSET msg_correct
    call WriteString
    mov  eax, g_correct
    call WriteDec
    mov  edx, OFFSET msg_nl
    call WriteString

    mov  edx, OFFSET msg_wrong
    call WriteString
    mov  eax, g_wrong
    call WriteDec
    mov  edx, OFFSET msg_nl
    call WriteString

    mov  edx, OFFSET msg_total
    call WriteString
    mov  eax, g_sentLen
    call WriteDec
    mov  edx, OFFSET msg_nl
    call WriteString

    mov  edx, OFFSET msg_accuracy
    call WriteString
    mov  eax, g_accuracy
    call WriteDec
    mov  edx, OFFSET msg_pct
    call WriteString

    mov  edx, OFFSET msg_wpm
    call WriteString
    mov  eax, g_wpm
    call WriteDec
    mov  edx, OFFSET msg_wpmU
    call WriteString

    mov  edx, OFFSET msg_resFtr
    call WriteString

    ; --- coloured feedback ---
    mov  eax, g_accuracy
    cmp  eax, 85
    jge  ML_Great
    cmp  eax, 60
    jge  ML_Good

    ; poor
    mov  eax, yellow
    call SetTextColor
    mov  edx, OFFSET msg_poor
    call WriteString
    jmp  ML_FeedDone

ML_Great:
    mov  eax, green
    call SetTextColor
    mov  edx, OFFSET msg_great
    call WriteString
    jmp  ML_FeedDone

ML_Good:
    mov  eax, lightCyan
    call SetTextColor
    mov  edx, OFFSET msg_good
    call WriteString

ML_FeedDone:
    mov  eax, white
    call SetTextColor

    ; --- play again? ---
    mov  edx, OFFSET msg_again
    call WriteString

    call ReadChar           ; single keypress, no Enter needed
    mov  bl, al             ; save answer
    call WriteChar          ; echo it
    mov  edx, OFFSET msg_nl
    call WriteString

    cmp  bl, 'Y'
    je   ML_DiffSelect
    cmp  bl, 'y'
    je   ML_DiffSelect

ML_Exit:
    mov  eax, white
    call SetTextColor
    call Clrscr
    mov  edx, OFFSET msg_bye
    call WriteString
    ; Wait for a key then clear screen so CMD prompt appears clean
    call ReadChar
    call Clrscr
    exit

main ENDP
END main