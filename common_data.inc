; ============================================================
;  common_data.inc
;  Shared sentence pools, UI strings, and runtime variables.
;
;  Included by BOTH:
;    windows/TypingAnalyzer_win.asm  (MASM615 + Irvine32)
;    mac/TypingAnalyzer_mac.asm      (ARM64 NASM-style via 'as')
;
;  DO NOT put any platform-specific code here.
; ============================================================

; ---- constants ---------------------------------------------
INPUT_MAX   EQU 100
EASY_CNT    EQU 4
MED_CNT     EQU 4
HARD_CNT    EQU 4

; ============================================================
;  SENTENCE POOLS
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
;  ASCII ART SPLASH
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
g_inputBuf   BYTE INPUT_MAX+2 DUP(0)
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
