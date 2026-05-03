// ============================================================
//  TypingAnalyzer_mac.s
//  macOS ARM64 (Apple Silicon M1/M2/M3/M4)
//
//  Assemble & link:
//    as -o TypingAnalyzer_mac.o TypingAnalyzer_mac.s
//    ld -o TypingAnalyzer_mac TypingAnalyzer_mac.o \
//       -lSystem -syslibroot $(xcrun -sdk macosx --show-sdk-path) \
//       -e _start -arch arm64
//
//  Run:
//    ./TypingAnalyzer_mac
//
//  Shared data:  ../common_data.inc  (sentence pools & strings)
//  Logic mirror: PickSentence, CompareStrings re-implemented
//                here in ARM64 — same algorithm as common_logic.inc
// ============================================================

// ---- macOS ARM64 syscall numbers --------------------------
// macOS BSD syscalls require the 0x2000000 class prefix
.equ STDIN,      0
.equ STDOUT,     1
// macOS BSD syscall numbers (0x2000000 class) used as movz literals inline

// ---- ANSI colour codes ------------------------------------
// Used instead of Irvine32 SetTextColor
.equ COL_RESET,  0
.equ COL_RED,    31
.equ COL_GREEN,  32
.equ COL_YELLOW, 33
.equ COL_CYAN,   36
.equ COL_WHITE,  37

// ---- constants --------------------------------------------
.equ INPUT_MAX,  100
.equ EASY_CNT,   4
.equ MED_CNT,    4
.equ HARD_CNT,   4

// ===========================================================
//  READ-ONLY DATA
// ===========================================================
.section __TEXT,__cstring,cstring_literals

// --- ANSI escape strings ---
ansi_reset:   .asciz "\033[0m"
ansi_red:     .asciz "\033[31m"
ansi_green:   .asciz "\033[32m"
ansi_yellow:  .asciz "\033[33m"
ansi_cyan:    .asciz "\033[36m"
ansi_white:   .asciz "\033[37m"
ansi_clear:   .asciz "\033[2J\033[H"   // clear screen + cursor home

// --- splash art ---
art_L1:   .asciz "  =============================================\r\n"
art_L2:   .asciz "  ||                                         ||\r\n"
art_L3:   .asciz "  ||   _______ __   __ ____  ___ _  _  ___  ||\r\n"
art_L4:   .asciz "  ||     | \\ \\/ /| |) ||___)|_ | |\\ | |___| ||\r\n"
art_L5:   .asciz "  ||     |  |  | |_/ /|    |__ | | \\| |   | ||\r\n"
art_L6:   .asciz "  ||                                         ||\r\n"
art_L7:   .asciz "  ||    A N A L Y Z E R   v 2 . 0           ||\r\n"
art_L8:   .asciz "  ||      Speed  &  Accuracy  Checker        ||\r\n"
art_L9:   .asciz "  ||                                         ||\r\n"
art_L10:  .asciz "  =============================================\r\n"
art_L11:  .asciz "\r\n         Press any key to begin...\r\n"

// --- menus & prompts ---
msg_menuTop:
    .asciz "\r\n  +------------------------------------------+\r\n  |       SELECT DIFFICULTY LEVEL           |\r\n  +------------------------------------------+\r\n  |                                          |\r\n  |   [1]  EASY    - Short simple phrases   |\r\n  |   [2]  MEDIUM  - Standard sentences     |\r\n  |   [3]  HARD    - Long complex sentences  |\r\n  |   [0]  EXIT                              |\r\n  |                                          |\r\n  +------------------------------------------+\r\n  Choice: "
msg_badKey:   .asciz "\r\n  Invalid key. Press 1, 2, 3 or 0.\r\n"
msg_selEasy:  .asciz "\r\n  >> EASY selected. Good luck!\r\n"
msg_selMed:   .asciz "\r\n  >> MEDIUM selected. Stay focused!\r\n"
msg_selHard:  .asciz "\r\n  >> HARD selected. You asked for it!\r\n"

msg_instrTop: .asciz "\r\n  Type the sentence below EXACTLY:\r\n  ------------------------------------------\r\n  "
msg_instrBot: .asciz "\r\n  ------------------------------------------\r\n"
msg_getready: .asciz "\r\n  Get ready...\r\n"
msg_cnt3:     .asciz "    3...\r\n"
msg_cnt2:     .asciz "    2...\r\n"
msg_cnt1:     .asciz "    1...\r\n"
msg_go:       .asciz "    GO!\r\n\r\n"
msg_prompt:   .asciz "  > "

msg_resHdr:
    .asciz "\r\n  +------------------------------------------+\r\n  |              YOUR RESULTS                |\r\n  +------------------------------------------+\r\n"
msg_correct:  .asciz "  |  Correct characters : "
msg_wrong:    .asciz "  |  Wrong   characters : "
msg_total:    .asciz "  |  Total   characters : "
msg_accuracy: .asciz "  |  Accuracy           : "
msg_wpm_lbl:  .asciz "  |  Estimated WPM      : "
msg_resFtr:   .asciz "  +------------------------------------------+\r\n"
msg_pct:      .asciz " %\r\n"
msg_wpmU:     .asciz " wpm\r\n"
msg_nl:       .asciz "\r\n"

msg_great:    .asciz "\r\n  *** EXCELLENT! Outstanding performance! ***\r\n"
msg_good:     .asciz "\r\n  *** Good job! Keep practicing! ***\r\n"
msg_poor:     .asciz "\r\n  *** Keep going! You will improve! ***\r\n"
msg_again:    .asciz "\r\n  Play again? (Y/N): "
msg_bye:      .asciz "\r\n  Thanks for playing. Goodbye, Commander!\r\n\r\n  Press any key to exit...\r\n"

// --- sentence pools ---
str_ez0: .asciz "the cat sat on the mat"
str_ez1: .asciz "i like to eat good food"
str_ez2: .asciz "the dog ran in the park"
str_ez3: .asciz "she had a big red ball"

str_md0: .asciz "practice makes a man perfectly skilled"
str_md1: .asciz "the quick brown fox jumps over the dog"
str_md2: .asciz "assembly language is fast and powerful"
str_md3: .asciz "every good programmer thinks before coding"

str_hd0: .asciz "the complexity of modern software demands rigorous testing"
str_hd1: .asciz "a dedicated programmer writes efficient and maintainable code"
str_hd2: .asciz "understanding memory management is crucial in systems programming"
str_hd3: .asciz "the quick analysis of algorithms improves computational efficiency"

// ===========================================================
//  READ-WRITE DATA  (variables, tables, buffers)
// ===========================================================
.section __DATA,__data

// --- sentence pointer tables (8 bytes each on ARM64) ---
tbl_ezPtr: .quad str_ez0, str_ez1, str_ez2, str_ez3
tbl_ezLen: .quad 22, 23, 23, 22

tbl_mdPtr: .quad str_md0, str_md1, str_md2, str_md3
tbl_mdLen: .quad 38, 38, 38, 42

tbl_hdPtr: .quad str_hd0, str_hd1, str_hd2, str_hd3
tbl_hdLen: .quad 57, 60, 63, 65

// --- runtime variables (64-bit for simplicity) ---
g_correct:  .quad 0
g_wrong:    .quad 0
g_startMs:  .quad 0
g_endMs:    .quad 0
g_elapsedS: .quad 0
g_wpm:      .quad 0
g_accuracy: .quad 0
g_inputLen: .quad 0
g_sentLen:  .quad 0
g_sentPtr:  .quad 0
g_diff:     .quad 0    // 1=easy 2=med 3=hard
g_poolCnt:  .quad 0

// --- input buffer ---
.section __DATA,__bss
g_inputBuf: .space 102           // INPUT_MAX + 2

// timeval struct for gettimeofday
tv_sec:     .space 8
tv_usec:    .space 8

// single-char read buffer
char_buf:   .space 2

// number-to-string conversion buffer (max 20 digits)
num_buf:    .space 24

// ===========================================================
//  CODE
// ===========================================================
.section __TEXT,__text
.global _start
.align 2

// -----------------------------------------------------------
//  HELPER: write_str  x0 = pointer to null-terminated string
// -----------------------------------------------------------
write_str:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    stp x19, x20, [sp, #-16]!

    mov x19, x0             // save string pointer

    // strlen: count bytes until null
    mov x20, #0
.Lwslen:
    ldrb w1, [x19, x20]
    cbz  w1, .Lwswrite
    add  x20, x20, #1
    b    .Lwslen

.Lwswrite:
    cbz  x20, .Lwsdone      // nothing to write if len=0
    mov x0, #STDOUT
    mov x1, x19
    mov x2, x20
    movz x16, #4
    movk x16, #0x200, lsl #16
    svc #0x80

.Lwsdone:
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// -----------------------------------------------------------
//  HELPER: set_color  x0 = ANSI colour string pointer
// -----------------------------------------------------------
set_color:
    b write_str             // tail-call

// -----------------------------------------------------------
//  HELPER: clrscr — send ANSI clear sequence
// -----------------------------------------------------------
clrscr:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    adrp x0, ansi_clear@PAGE
    add  x0, x0, ansi_clear@PAGEOFF
    bl   write_str
    ldp x29, x30, [sp], #16
    ret

// -----------------------------------------------------------
//  HELPER: read_char — read one byte into char_buf, return in w0
//  Uses raw read (terminal must be in raw mode for instant key;
//  on macOS Terminal it works fine without canonical mode change
//  because we use getline-style input elsewhere and just need
//  single-char menus — see note below).
//
//  NOTE: macOS Terminal is line-buffered by default.
//  read_char here reads 1 byte; the user still presses Enter.
//  To remove the Enter requirement you would need to call
//  tcsetattr to switch to raw mode — kept simple here so
//  the program assembles and runs without extra setup.
// -----------------------------------------------------------
read_char:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    mov x0, #STDIN
    adrp x1, char_buf@PAGE
    add  x1, x1, char_buf@PAGEOFF
    mov x2, #1
    movz x16, #3
    movk x16, #0x200, lsl #16
    svc #0x80

    adrp x1, char_buf@PAGE
    add  x1, x1, char_buf@PAGEOFF
    ldrb w0, [x1]

    ldp x29, x30, [sp], #16
    ret

// -----------------------------------------------------------
//  HELPER: read_line — read up to INPUT_MAX chars into g_inputBuf
//  Returns length in x0.
// -----------------------------------------------------------
read_line:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    stp x19, x20, [sp, #-16]!

    // zero out buffer first
    adrp x19, g_inputBuf@PAGE
    add  x19, x19, g_inputBuf@PAGEOFF
    mov  x20, #102
.Lrlzero:
    strb wzr, [x19, x20]
    subs x20, x20, #1
    b.ge .Lrlzero

    // read up to INPUT_MAX bytes
    mov x0, #STDIN
    mov x1, x19
    mov x2, #INPUT_MAX
    movz x16, #3
    movk x16, #0x200, lsl #16
    svc #0x80                // x0 = bytes read (includes newline)

    // strip trailing newline/CR
    cmp  x0, #0
    b.le .Lrldone
    sub  x1, x0, #1
.Lrlstrip:
    ldrb w2, [x19, x1]
    cmp  w2, #10             // LF
    b.eq .Lrlchop
    cmp  w2, #13             // CR
    b.ne .Lrldone
.Lrlchop:
    strb wzr, [x19, x1]
    subs x0, x0, #1
    cmp  x0, #0
    b.le .Lrldone
    sub  x1, x0, #1
    b    .Lrlstrip

.Lrldone:
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// -----------------------------------------------------------
//  HELPER: write_dec  x0 = unsigned 64-bit integer to print
// -----------------------------------------------------------
write_dec:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    mov  x19, x0             // save number
    adrp x20, num_buf@PAGE
    add  x20, x20, num_buf@PAGEOFF
    mov  x21, #23            // write backwards from end
    strb wzr, [x20, x21]     // null terminate
    sub  x21, x21, #1

    cbz  x19, .Lwdzero

.Lwdloop:
    cbz  x19, .Lwdprint
    mov  x22, #10
    udiv x1,  x19, x22      // x1 = x19 / 10
    msub x2,  x1, x22, x19  // x2 = x19 mod 10
    add  w2,  w2, #'0'
    strb w2,  [x20, x21]
    sub  x21, x21, #1
    mov  x19, x1
    b    .Lwdloop

.Lwdzero:
    mov  w2, #'0'
    strb w2,  [x20, x21]
    sub  x21, x21, #1

.Lwdprint:
    add  x21, x21, #1       // x21 now points to first digit
    add  x0, x20, x21
    bl   write_str

    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// -----------------------------------------------------------
//  HELPER: get_ms — returns milliseconds (mod 2^32) in x0
//  Uses gettimeofday syscall (macOS syscall #116)
// -----------------------------------------------------------
get_ms:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, tv_sec@PAGE
    add  x0, x0, tv_sec@PAGEOFF
    mov  x1, #0
    movz x16, #116
    movk x16, #0x200, lsl #16
    svc  #0x80

    adrp x0, tv_sec@PAGE
    add  x0, x0, tv_sec@PAGEOFF
    ldr  x1, [x0]            // seconds
    adrp x2, tv_usec@PAGE
    add  x2, x2, tv_usec@PAGEOFF
    ldr  x2, [x2]            // microseconds

    mov  x3, #1000
    mul  x0, x1, x3          // ms from seconds
    udiv x2, x2, x3          // ms from useconds
    add  x0, x0, x2

    ldp x29, x30, [sp], #16
    ret

// -----------------------------------------------------------
//  HELPER: sleep_1s — sleep 1 second (nanosleep syscall #214)
// -----------------------------------------------------------
.section __DATA,__data
.align 3
ts_sec:  .quad 1
ts_nsec: .quad 0
.section __TEXT,__text
.align 2

sleep_1s:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, ts_sec@PAGE
    add  x0, x0, ts_sec@PAGEOFF
    mov  x1, #0
    movz x16, #240
    movk x16, #0x200, lsl #16  // nanosleep
    svc  #0x80

    ldp x29, x30, [sp], #16
    ret

// ===========================================================
//  pick_sentence — sets g_sentPtr and g_sentLen
//  Same algorithm as common_logic.inc PickSentence
// ===========================================================
pick_sentence:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    bl   get_ms
    mov  x19, x0             // ms value

    adrp x20, g_poolCnt@PAGE
    add  x20, x20, g_poolCnt@PAGEOFF
    ldr  x20, [x20]          // poolCnt
    udiv x21, x19, x20       // quotient
    msub x21, x21, x20, x19  // x21 = ms mod poolCnt  (random index)

    lsl  x21, x21, #3        // *8 (quad pointers on ARM64)

    adrp x22, g_diff@PAGE
    add  x22, x22, g_diff@PAGEOFF
    ldr  x22, [x22]          // difficulty

    cmp  x22, #1
    b.eq .Lps_easy
    cmp  x22, #2
    b.eq .Lps_med

.Lps_hard:
    adrp x0, tbl_hdPtr@PAGE
    add  x0, x0, tbl_hdPtr@PAGEOFF
    ldr  x0, [x0, x21]
    adrp x1, g_sentPtr@PAGE
    add  x1, x1, g_sentPtr@PAGEOFF
    str  x0, [x1]

    adrp x0, tbl_hdLen@PAGE
    add  x0, x0, tbl_hdLen@PAGEOFF
    ldr  x0, [x0, x21]
    adrp x1, g_sentLen@PAGE
    add  x1, x1, g_sentLen@PAGEOFF
    str  x0, [x1]
    b    .Lps_done

.Lps_easy:
    adrp x0, tbl_ezPtr@PAGE
    add  x0, x0, tbl_ezPtr@PAGEOFF
    ldr  x0, [x0, x21]
    adrp x1, g_sentPtr@PAGE
    add  x1, x1, g_sentPtr@PAGEOFF
    str  x0, [x1]

    adrp x0, tbl_ezLen@PAGE
    add  x0, x0, tbl_ezLen@PAGEOFF
    ldr  x0, [x0, x21]
    adrp x1, g_sentLen@PAGE
    add  x1, x1, g_sentLen@PAGEOFF
    str  x0, [x1]
    b    .Lps_done

.Lps_med:
    adrp x0, tbl_mdPtr@PAGE
    add  x0, x0, tbl_mdPtr@PAGEOFF
    ldr  x0, [x0, x21]
    adrp x1, g_sentPtr@PAGE
    add  x1, x1, g_sentPtr@PAGEOFF
    str  x0, [x1]

    adrp x0, tbl_mdLen@PAGE
    add  x0, x0, tbl_mdLen@PAGEOFF
    ldr  x0, [x0, x21]
    adrp x1, g_sentLen@PAGE
    add  x1, x1, g_sentLen@PAGEOFF
    str  x0, [x1]

.Lps_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ===========================================================
//  compare_strings — same algorithm as common_logic.inc
//  Walks g_sentLen chars, updates g_correct / g_wrong
// ===========================================================
compare_strings:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    stp x19, x20, [sp, #-16]!
    stp x21, x22, [sp, #-16]!

    adrp x19, g_sentPtr@PAGE
    add  x19, x19, g_sentPtr@PAGEOFF
    ldr  x19, [x19]          // source (sentence)

    adrp x20, g_inputBuf@PAGE
    add  x20, x20, g_inputBuf@PAGEOFF  // typed input

    adrp x22, g_sentLen@PAGE
    add  x22, x22, g_sentLen@PAGEOFF
    ldr  x22, [x22]          // loop count

    cbz  x22, .Lcs_done
    mov  x21, #0             // index

.Lcs_loop:
    cmp  x21, x22
    b.ge .Lcs_done

    ldrb w0, [x19, x21]     // sentence char
    ldrb w1, [x20, x21]     // typed char

    cbz  w1, .Lcs_wrong     // typed nothing (short input)
    cmp  w0, w1
    b.eq .Lcs_correct

.Lcs_wrong:
    adrp x0, g_wrong@PAGE
    add  x0, x0, g_wrong@PAGEOFF
    ldr  x1, [x0]
    add  x1, x1, #1
    str  x1, [x0]
    b    .Lcs_next

.Lcs_correct:
    adrp x0, g_correct@PAGE
    add  x0, x0, g_correct@PAGEOFF
    ldr  x1, [x0]
    add  x1, x1, #1
    str  x1, [x0]

.Lcs_next:
    add  x21, x21, #1
    b    .Lcs_loop

.Lcs_done:
    ldp x21, x22, [sp], #16
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ===========================================================
//  show_splash
// ===========================================================
show_splash:
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    adrp x0, ansi_cyan@PAGE
    add  x0, x0, ansi_cyan@PAGEOFF
    bl   set_color

    adrp x0, art_L1@PAGE
    add x0, x0, art_L1@PAGEOFF
    bl write_str
    adrp x0, art_L2@PAGE
    add x0, x0, art_L2@PAGEOFF
    bl write_str
    adrp x0, art_L3@PAGE
    add x0, x0, art_L3@PAGEOFF
    bl write_str
    adrp x0, art_L4@PAGE
    add x0, x0, art_L4@PAGEOFF
    bl write_str
    adrp x0, art_L5@PAGE
    add x0, x0, art_L5@PAGEOFF
    bl write_str
    adrp x0, art_L6@PAGE
    add x0, x0, art_L6@PAGEOFF
    bl write_str

    adrp x0, ansi_yellow@PAGE
    add  x0, x0, ansi_yellow@PAGEOFF
    bl   set_color

    adrp x0, art_L7@PAGE
    add x0, x0, art_L7@PAGEOFF
    bl write_str
    adrp x0, art_L8@PAGE
    add x0, x0, art_L8@PAGEOFF
    bl write_str
    adrp x0, art_L9@PAGE
    add x0, x0, art_L9@PAGEOFF
    bl write_str

    adrp x0, ansi_cyan@PAGE
    add  x0, x0, ansi_cyan@PAGEOFF
    bl   set_color

    adrp x0, art_L10@PAGE
    add x0, x0, art_L10@PAGEOFF
    bl write_str

    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color

    adrp x0, art_L11@PAGE
    add x0, x0, art_L11@PAGEOFF
    bl write_str

    bl   read_char           // wait for any key

    ldp x29, x30, [sp], #16
    ret

// ===========================================================
//  show_diff_menu — returns x0 = 1 (chosen) or 0 (exit)
// ===========================================================
show_diff_menu:
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    stp x19, x20, [sp, #-16]!

.Lsdm_top:
    bl   clrscr

    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color

    adrp x0, msg_menuTop@PAGE
    add  x0, x0, msg_menuTop@PAGEOFF
    bl   write_str

    bl   read_char
    mov  w19, w0             // save key

    // echo key + newline
    mov  x0, #STDOUT
    adrp x1, char_buf@PAGE
    add  x1, x1, char_buf@PAGEOFF
    strb w19, [x1]
    mov  x2, #1
    movz x16, #4
    movk x16, #0x200, lsl #16
    svc  #0x80
    adrp x0, msg_nl@PAGE
    add  x0, x0, msg_nl@PAGEOFF
    bl   write_str

    cmp  w19, #'0'
    b.eq .Lsdm_exit
    cmp  w19, #'1'
    b.eq .Lsdm_easy
    cmp  w19, #'2'
    b.eq .Lsdm_med
    cmp  w19, #'3'
    b.eq .Lsdm_hard

    adrp x0, msg_badKey@PAGE
    add  x0, x0, msg_badKey@PAGEOFF
    bl   write_str
    b    .Lsdm_top

.Lsdm_easy:
    adrp x0, g_diff@PAGE
    add  x0, x0, g_diff@PAGEOFF
    mov  x1, #1
    str  x1, [x0]
    adrp x0, g_poolCnt@PAGE
    add  x0, x0, g_poolCnt@PAGEOFF
    mov  x1, #EASY_CNT
    str  x1, [x0]
    adrp x0, ansi_green@PAGE
    add  x0, x0, ansi_green@PAGEOFF
    bl   set_color
    adrp x0, msg_selEasy@PAGE
    add  x0, x0, msg_selEasy@PAGEOFF
    bl   write_str
    b    .Lsdm_chosen

.Lsdm_med:
    adrp x0, g_diff@PAGE
    add  x0, x0, g_diff@PAGEOFF
    mov  x1, #2
    str  x1, [x0]
    adrp x0, g_poolCnt@PAGE
    add  x0, x0, g_poolCnt@PAGEOFF
    mov  x1, #MED_CNT
    str  x1, [x0]
    adrp x0, ansi_yellow@PAGE
    add  x0, x0, ansi_yellow@PAGEOFF
    bl   set_color
    adrp x0, msg_selMed@PAGE
    add  x0, x0, msg_selMed@PAGEOFF
    bl   write_str
    b    .Lsdm_chosen

.Lsdm_hard:
    adrp x0, g_diff@PAGE
    add  x0, x0, g_diff@PAGEOFF
    mov  x1, #3
    str  x1, [x0]
    adrp x0, g_poolCnt@PAGE
    add  x0, x0, g_poolCnt@PAGEOFF
    mov  x1, #HARD_CNT
    str  x1, [x0]
    adrp x0, ansi_red@PAGE
    add  x0, x0, ansi_red@PAGEOFF
    bl   set_color
    adrp x0, msg_selHard@PAGE
    add  x0, x0, msg_selHard@PAGEOFF
    bl   write_str

.Lsdm_chosen:
    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color
    mov  x0, #1
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

.Lsdm_exit:
    mov  x0, #0
    ldp x19, x20, [sp], #16
    ldp x29, x30, [sp], #16
    ret

// ===========================================================
//  _start — main game loop
// ===========================================================
_start:
    // set up frame
    mov x29, sp

    bl   clrscr
    bl   show_splash

.Lml_diff_select:
    bl   show_diff_menu
    cbz  x0, .Lml_exit

.Lml_game_loop:
    // reset per-round stats
    adrp x0, g_correct@PAGE
    add  x0, x0, g_correct@PAGEOFF
    str  xzr, [x0]
    adrp x0, g_wrong@PAGE
    add  x0, x0, g_wrong@PAGEOFF
    str  xzr, [x0]
    adrp x0, g_inputLen@PAGE
    add  x0, x0, g_inputLen@PAGEOFF
    str  xzr, [x0]

    bl   pick_sentence
    bl   clrscr

    // --- show target sentence ---
    adrp x0, msg_instrTop@PAGE
    add  x0, x0, msg_instrTop@PAGEOFF
    bl   write_str

    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color

    adrp x0, g_sentPtr@PAGE
    add  x0, x0, g_sentPtr@PAGEOFF
    ldr  x0, [x0]
    bl   write_str

    adrp x0, msg_instrBot@PAGE
    add  x0, x0, msg_instrBot@PAGEOFF
    bl   write_str

    // --- colour countdown by difficulty ---
    adrp x19, g_diff@PAGE
    add  x19, x19, g_diff@PAGEOFF
    ldr  x19, [x19]

    cmp  x19, #1
    b.eq .Lml_cnt_easy
    cmp  x19, #2
    b.eq .Lml_cnt_med
    adrp x0, ansi_red@PAGE
    add  x0, x0, ansi_red@PAGEOFF
    bl   set_color
    b    .Lml_cnt_start
.Lml_cnt_easy:
    adrp x0, ansi_green@PAGE
    add  x0, x0, ansi_green@PAGEOFF
    bl   set_color
    b    .Lml_cnt_start
.Lml_cnt_med:
    adrp x0, ansi_yellow@PAGE
    add  x0, x0, ansi_yellow@PAGEOFF
    bl   set_color

.Lml_cnt_start:
    adrp x0, msg_getready@PAGE
    add x0, x0, msg_getready@PAGEOFF
    bl write_str
    adrp x0, msg_cnt3@PAGE
    add x0, x0, msg_cnt3@PAGEOFF
    bl write_str
    bl   sleep_1s
    adrp x0, msg_cnt2@PAGE
    add x0, x0, msg_cnt2@PAGEOFF
    bl write_str
    bl   sleep_1s
    adrp x0, msg_cnt1@PAGE
    add x0, x0, msg_cnt1@PAGEOFF
    bl write_str
    bl   sleep_1s

    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color

    adrp x0, msg_go@PAGE
    add  x0, x0, msg_go@PAGEOFF
    bl   write_str

    // --- drain any leftover newline from read_char calls ---
    mov x0, #STDIN
    adrp x1, char_buf@PAGE
    add  x1, x1, char_buf@PAGEOFF
    mov x2, #1
    movz x16, #3
    movk x16, #0x200, lsl #16
    svc  #0x80

    // --- start timer ---
    bl   get_ms
    adrp x1, g_startMs@PAGE
    add  x1, x1, g_startMs@PAGEOFF
    str  x0, [x1]

    adrp x0, msg_prompt@PAGE
    add  x0, x0, msg_prompt@PAGEOFF
    bl   write_str

    bl   read_line
    adrp x1, g_inputLen@PAGE
    add  x1, x1, g_inputLen@PAGEOFF
    str  x0, [x1]

    // --- stop timer ---
    bl   get_ms
    adrp x1, g_endMs@PAGE
    add  x1, x1, g_endMs@PAGEOFF
    str  x0, [x1]

    bl   compare_strings
    bl   clrscr

    // --- accuracy = (g_correct * 100) / g_sentLen ---
    adrp x0, g_correct@PAGE
    add  x0, x0, g_correct@PAGEOFF
    ldr  x0, [x0]
    mov  x1, #100
    mul  x0, x0, x1

    adrp x1, g_sentLen@PAGE
    add  x1, x1, g_sentLen@PAGEOFF
    ldr  x1, [x1]
    cbnz x1, .Lml_acc_div
    mov  x1, #1
.Lml_acc_div:
    udiv x0, x0, x1
    adrp x1, g_accuracy@PAGE
    add  x1, x1, g_accuracy@PAGEOFF
    str  x0, [x1]

    // --- elapsed seconds = (endMs - startMs) / 1000, min 1 ---
    adrp x0, g_endMs@PAGE
    add  x0, x0, g_endMs@PAGEOFF
    ldr  x0, [x0]
    adrp x1, g_startMs@PAGE
    add  x1, x1, g_startMs@PAGEOFF
    ldr  x1, [x1]
    subs x0, x0, x1
    csel x0, x0, xzr, hi    // if endMs <= startMs, clamp to 0

    mov  x1, #1000
    udiv x0, x0, x1         // seconds
    cmp  x0, #1
    b.ge .Lml_sec_ok
    mov  x0, #1
.Lml_sec_ok:
    adrp x1, g_elapsedS@PAGE
    add  x1, x1, g_elapsedS@PAGEOFF
    str  x0, [x1]

    // --- WPM = (inputLen / 5) * 60 / elapsedS ---
    adrp x0, g_inputLen@PAGE
    add  x0, x0, g_inputLen@PAGEOFF
    ldr  x0, [x0]
    mov  x1, #5
    udiv x0, x0, x1         // word count
    cmp  x0, #1
    b.ge .Lml_word_ok
    mov  x0, #1
.Lml_word_ok:
    mov  x1, #60
    mul  x0, x0, x1
    adrp x1, g_elapsedS@PAGE
    add  x1, x1, g_elapsedS@PAGEOFF
    ldr  x1, [x1]
    udiv x0, x0, x1
    adrp x1, g_wpm@PAGE
    add  x1, x1, g_wpm@PAGEOFF
    str  x0, [x1]

    // --- print results ---
    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color

    adrp x0, msg_resHdr@PAGE
    add x0, x0, msg_resHdr@PAGEOFF
    bl write_str

    adrp x0, msg_correct@PAGE
    add  x0, x0, msg_correct@PAGEOFF
    bl   write_str
    adrp x0, g_correct@PAGE
    add  x0, x0, g_correct@PAGEOFF
    ldr  x0, [x0]
    bl   write_dec
    adrp x0, msg_nl@PAGE
    add x0, x0, msg_nl@PAGEOFF
    bl write_str

    adrp x0, msg_wrong@PAGE
    add  x0, x0, msg_wrong@PAGEOFF
    bl   write_str
    adrp x0, g_wrong@PAGE
    add  x0, x0, g_wrong@PAGEOFF
    ldr  x0, [x0]
    bl   write_dec
    adrp x0, msg_nl@PAGE
    add x0, x0, msg_nl@PAGEOFF
    bl write_str

    adrp x0, msg_total@PAGE
    add  x0, x0, msg_total@PAGEOFF
    bl   write_str
    adrp x0, g_sentLen@PAGE
    add  x0, x0, g_sentLen@PAGEOFF
    ldr  x0, [x0]
    bl   write_dec
    adrp x0, msg_nl@PAGE
    add x0, x0, msg_nl@PAGEOFF
    bl write_str

    adrp x0, msg_accuracy@PAGE
    add  x0, x0, msg_accuracy@PAGEOFF
    bl   write_str
    adrp x0, g_accuracy@PAGE
    add  x0, x0, g_accuracy@PAGEOFF
    ldr  x0, [x0]
    bl   write_dec
    adrp x0, msg_pct@PAGE
    add x0, x0, msg_pct@PAGEOFF
    bl write_str

    adrp x0, msg_wpm_lbl@PAGE
    add  x0, x0, msg_wpm_lbl@PAGEOFF
    bl   write_str
    adrp x0, g_wpm@PAGE
    add  x0, x0, g_wpm@PAGEOFF
    ldr  x0, [x0]
    bl   write_dec
    adrp x0, msg_wpmU@PAGE
    add x0, x0, msg_wpmU@PAGEOFF
    bl write_str
    adrp x0, msg_resFtr@PAGE
    add x0, x0, msg_resFtr@PAGEOFF
    bl write_str

    // --- coloured feedback ---
    adrp x19, g_accuracy@PAGE
    add  x19, x19, g_accuracy@PAGEOFF
    ldr  x19, [x19]

    cmp  x19, #85
    b.ge .Lml_great
    cmp  x19, #60
    b.ge .Lml_good

    // poor
    adrp x0, ansi_yellow@PAGE
    add  x0, x0, ansi_yellow@PAGEOFF
    bl   set_color
    adrp x0, msg_poor@PAGE
    add  x0, x0, msg_poor@PAGEOFF
    bl   write_str
    b    .Lml_feed_done

.Lml_great:
    adrp x0, ansi_green@PAGE
    add  x0, x0, ansi_green@PAGEOFF
    bl   set_color
    adrp x0, msg_great@PAGE
    add  x0, x0, msg_great@PAGEOFF
    bl   write_str
    b    .Lml_feed_done

.Lml_good:
    adrp x0, ansi_cyan@PAGE
    add  x0, x0, ansi_cyan@PAGEOFF
    bl   set_color
    adrp x0, msg_good@PAGE
    add  x0, x0, msg_good@PAGEOFF
    bl   write_str

.Lml_feed_done:
    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color

    // --- play again? ---
    adrp x0, msg_again@PAGE
    add  x0, x0, msg_again@PAGEOFF
    bl   write_str

    bl   read_char
    mov  w19, w0

    // echo + newline
    adrp x0, msg_nl@PAGE
    add  x0, x0, msg_nl@PAGEOFF
    bl   write_str

    cmp  w19, #'Y'
    b.eq .Lml_diff_select
    cmp  w19, #'y'
    b.eq .Lml_diff_select

.Lml_exit:
    adrp x0, ansi_white@PAGE
    add  x0, x0, ansi_white@PAGEOFF
    bl   set_color
    bl   clrscr
    adrp x0, msg_bye@PAGE
    add  x0, x0, msg_bye@PAGEOFF
    bl   write_str
    bl   read_char
    bl   clrscr

    // exit(0)
    mov x0, #0
    movz x16, #1
    movk x16, #0x200, lsl #16
    svc #0x80