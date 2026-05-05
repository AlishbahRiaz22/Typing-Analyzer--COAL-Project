; ============================================================
;  TypingAnalyzer_win.asm
;  Windows x86-32 entry point — MASM615 + Irvine32
;
;  Build:
;    ml /c /coff TypingAnalyzer_win.asm
;    link /subsystem:console TypingAnalyzer_win.obj Irvine32.lib kernel32.lib user32.lib
;
;  Shared files pulled in:
;    ../common_data.inc   — sentence pools, strings, variables
;    ../common_logic.inc  — PickSentence, ReadLineInput, CompareStrings
; ============================================================

INCLUDE Irvine32.inc

.data
INCLUDE ../common_data.inc

.code

; ---- include shared procedures ----------------------------
INCLUDE ../common_logic.inc

; ------------------------------------------------------------
;  ShowSplash  (Windows — uses Irvine32 SetTextColor)
; ------------------------------------------------------------
ShowSplash PROC
    mov  eax, cyan
    call SetTextColor

    mov  edx, OFFSET art_L1  & call WriteString
    mov  edx, OFFSET art_L2  & call WriteString
    mov  edx, OFFSET art_L3  & call WriteString
    mov  edx, OFFSET art_L4  & call WriteString
    mov  edx, OFFSET art_L5  & call WriteString
    mov  edx, OFFSET art_L6  & call WriteString

    mov  eax, yellow
    call SetTextColor

    mov  edx, OFFSET art_L7  & call WriteString
    mov  edx, OFFSET art_L8  & call WriteString
    mov  edx, OFFSET art_L9  & call WriteString

    mov  eax, cyan
    call SetTextColor

    mov  edx, OFFSET art_L10
    call WriteString

    mov  eax, white
    call SetTextColor

    mov  edx, OFFSET art_L11
    call WriteString

    call ReadChar
    ret
ShowSplash ENDP

; ------------------------------------------------------------
;  ShowDiffMenu  — returns EAX=1 (chosen) or 0 (exit)
; ------------------------------------------------------------
ShowDiffMenu PROC
SDM_Top:
    call Clrscr
    mov  eax, white
    call SetTextColor

    mov  edx, OFFSET msg_menuTop
    call WriteString

    call ReadChar
    mov  bl, al
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

; ============================================================
;  main
; ============================================================
main PROC

    mov  dh, 0
    mov  dl, 0
    call Gotoxy
    call Clrscr
    call ShowSplash

ML_DiffSelect:
    call ShowDiffMenu
    cmp  eax, 0
    je   ML_Exit

ML_GameLoop:
    mov  g_correct,  0
    mov  g_wrong,    0
    mov  g_inputLen, 0

    call PickSentence
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
    mov  eax, red
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

    ; --- time + input ---
    call GetMseconds
    mov  g_startMs, eax
    mov  edx, OFFSET msg_prompt
    call WriteString
    call ReadLineInput
    call GetMseconds
    mov  g_endMs, eax

    call CompareStrings
    call Clrscr

    ; --- accuracy = (g_correct * 100) / g_sentLen ---
    mov  eax, g_correct
    mov  ebx, 100
    mul  ebx
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
    div  ebx
    cmp  eax, 1
    jae  ML_SecOk
    mov  eax, 1
ML_SecOk:
    mov  g_elapsedS, eax

    mov  eax, g_inputLen
    xor  edx, edx
    mov  ebx, 5
    div  ebx
    cmp  eax, 1
    jae  ML_WordOk
    mov  eax, 1
ML_WordOk:
    mov  ebx, 60
    mul  ebx
    xor  edx, edx
    div  g_elapsedS
    mov  g_wpm, eax

    ; --- print results ---
    mov  eax, white
    call SetTextColor

    mov  edx, OFFSET msg_resHdr  & call WriteString
    mov  edx, OFFSET msg_correct & call WriteString
    mov  eax, g_correct          & call WriteDec
    mov  edx, OFFSET msg_nl      & call WriteString
    mov  edx, OFFSET msg_wrong   & call WriteString
    mov  eax, g_wrong            & call WriteDec
    mov  edx, OFFSET msg_nl      & call WriteString
    mov  edx, OFFSET msg_total   & call WriteString
    mov  eax, g_sentLen          & call WriteDec
    mov  edx, OFFSET msg_nl      & call WriteString
    mov  edx, OFFSET msg_accuracy & call WriteString
    mov  eax, g_accuracy         & call WriteDec
    mov  edx, OFFSET msg_pct     & call WriteString
    mov  edx, OFFSET msg_wpm     & call WriteString
    mov  eax, g_wpm              & call WriteDec
    mov  edx, OFFSET msg_wpmU    & call WriteString
    mov  edx, OFFSET msg_resFtr  & call WriteString

    ; --- coloured feedback ---
    mov  eax, g_accuracy
    cmp  eax, 85
    jge  ML_Great
    cmp  eax, 60
    jge  ML_Good

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
    call ReadChar
    mov  bl, al
    call WriteChar
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
    call ReadChar
    call Clrscr
    exit

main ENDP
END main