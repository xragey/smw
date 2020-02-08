; ----------------------------------------------------------------------------------------------------------------------------------
;
; "Reclaim $7E1F49"
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Installing this patch reclaims offset $7E1F49 (141 bytes).
;
; Note that this patch is integrated into the MoreSram.asm patch. If you apply that one, you should not apply this one.
;
; ----------------------------------------------------------------------------------------------------------------------------------

@asar 1.71

!sa1  = 0
!fast = 0
!bank = $00
!addr = $0000
!long = $000000

; ----------------------------------------------------------------------------------------------------------------------------------

; 141 bytes
; Holds the state of the overworld.
!OverworldState = $1EA2|!addr

; ----------------------------------------------------------------------------------------------------------------------------------

assert read1($009F19) == $22, "Missing required Lunar Magic hijack"
assert read1($01E762) == $22, "Missing required Lunar Magic hijack"

; ----------------------------------------------------------------------------------------------------------------------------------

; Bypass $1F49 buffer
org $009BDF|!long : dw !OverworldState
org $009D19|!long : dw !OverworldState
org $009F09|!long : dw !OverworldState-1
org $009F17|!long : dw !OverworldState
org $009F23|!long : dw !OverworldState+111 ; $1F11-$1F26
org $00A195|!long : rts
org $048F94|!long : nop #11
org $048FA9|!long : nop #24
org $048FC8|!long : nop #6
org $048FD6|!long : nop #6
org $049041|!long : nop #11

; Lunar Magic $1F49
org read3($009F1A)|!long : skip 11 : dw !OverworldState
org read3($01E763)|!long : skip 7 : nop #3
