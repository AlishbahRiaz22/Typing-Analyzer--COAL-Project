; ============================================================
;  common_logic.inc
;  Shared procedures: PickSentence, CompareStrings.
;  Accuracy and WPM formulas are also documented here
;  (implemented inline in main on both platforms).
;
;  MASM syntax — included by windows/TypingAnalyzer_win.asm
;
;  The Mac ARM64 version re-implements these as ARM64 routines
;  in mac/TypingAnalyzer_mac.asm because MASM syntax is not
;  valid on Apple's assembler (as/clang).
; ============================================================

; ------------------------------------------------------------
;  PickSentence
;  Uses GetMseconds % g_poolCnt as a cheap random index.
;  Sets g_sentPtr and g_sentLen.
; ------------------------------------------------------------
PickSentence PROC
    push eax
    push ebx
    push ecx
    push edx

    call GetMseconds
    xor  edx, edx
    mov  ecx, g_poolCnt
    div  ecx                ; EDX = random index 0..poolCnt-1

    mov  eax, edx
    shl  eax, 2             ; *4 = DWORD byte offset

    mov  ebx, g_diff
    cmp  ebx, 1
    je   PS_Easy
    cmp  ebx, 2
    je   PS_Med

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
;  ReadLineInput
;  Zeroes buffer, reads a line via Irvine32 ReadString.
;  EAX returns number of characters read (set in g_inputLen).
; ------------------------------------------------------------
ReadLineInput PROC
    push eax
    push ecx
    push edx
    push edi

    mov  edi, OFFSET g_inputBuf
    mov  ecx, INPUT_MAX+2
    xor  eax, eax
    rep  stosb

    mov  edx, OFFSET g_inputBuf
    mov  ecx, INPUT_MAX
    call ReadString
    mov  g_inputLen, eax

    pop  edi
    pop  edx
    pop  ecx
    pop  eax
    ret
ReadLineInput ENDP

; ------------------------------------------------------------
;  CompareStrings
;  Walks g_sentLen characters, comparing g_sentPtr vs
;  g_inputBuf byte-by-byte.  Updates g_correct / g_wrong.
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
;  ACCURACY & WPM FORMULAS  (for reference — implemented
;  inline in main on both platforms)
;
;  Accuracy % = (g_correct * 100) / g_sentLen
;
;  Elapsed seconds = (g_endMs - g_startMs) / 1000   (min 1)
;  WPM            = (g_inputLen / 5) * 60 / elapsedS
; ============================================================
