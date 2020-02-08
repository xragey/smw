; ----------------------------------------------------------------------------------------------------------------------------------
;
; "More Sram"
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Increases the SRAM capacity of Super Mario World from 140 bytes to 339 bytes by extending the RAM area that is transferred to and
; from SRAM when saving or loading a game. This patch differs from other patches in that it retains the original game's logic in
; handling SRAM and does not expand the physical SRAM area. This means that this solution is compatible with any emulator or hard-
; ware solution.
;
; Installing this patch reclaims offset $7E1F49 (141 bytes), which (with default settings) is entirely located within the SRAM area.
;
; Note that this patch does not clean up the other uses of RAM within the new SRAM area. This results in some notable side-effects,
; such as the "collected all Dragon Coins" flag now also saving to SRAM, as these flags are coincidentally stored within the new
; SRAM area. Many other addresses in this area are useless to transfer to SRAM, so to take full advantage of the added SRAM, some
; manual remapping of addresses is needed.
;
; ----------------------------------------------------------------------------------------------------------------------------------

@asar 1.71

!sa1  = 0
!fast = 0
!bank = $00
!addr = $0000
!long = $000000

; ----------------------------------------------------------------------------------------------------------------------------------

; Transfer range, excluding 2 checksum bytes.
!cSramSize = 339

; !cSramSize bytes
; Ram area that is transferred to SRAM. Does not need to be equal to !OverworldState.
!TransferableRam = $1EA2|!addr

; 141 bytes
; Holds the state of the overworld.
!OverworldState = $1EA2|!addr

; 6*(!cSramSize+2) bytes
; SRAM array, divided in six blocks of !cSramSize bytes per block.
if !sa1
{
	!Sram = $41C000
}
else
{
	!Sram = $700000
}
endif

; ----------------------------------------------------------------------------------------------------------------------------------

assert read1($009F19) == $22, "Missing required Lunar Magic hijack"
assert read1($01E762) == $22, "Missing required Lunar Magic hijack"

; ----------------------------------------------------------------------------------------------------------------------------------

; Bypass $1F49 buffer
org $009BDF|!long : dw !TransferableRam
org $009D19|!long : dw !TransferableRam
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

; File offsets (assuming length 339+2)
org $009CCB|!long : db $00, (!cSramSize+2)>>8, ((!cSramSize+2)*2)>>8
org $009CCE|!long : db $00, (!cSramSize+2), (!cSramSize+2)*2

; File length
org $009BF1|!long : dw !cSramSize
org $009D1E|!long : dw !cSramSize

; File erasing routine
org $009B54|!long : dw !cSramSize+2
org $009B5C|!long : sta.l !Sram+((!cSramSize+2)*3),x

; File checksum routine
org $009DC1|!long : dw (!cSramSize+2)*3
org $009DC6|!long : lda.l !Sram+!cSramSize,x ; 70 01 53
org $009DCF|!long : dw !cSramSize
org $009DEE|!long : dw ((!cSramSize+2)*3)-1

; Restore backup copy
org $009C02|!long : dw (!cSramSize+2)*3
org $009C08|!long : dw (!cSramSize+2)*2
org $009CF7|!long : autoclean jml EmplaceBackup

freecode
EmplaceBackup:
	phx
	stz $0109|!addr
	rep #$20
	lda #!cSramSize+2
	sta $00
-	lda.l !Sram,x
	phx
	tyx
	sta.l !Sram,x
	plx
	inx
	iny
	dec $00
	bne -
	sep #$20
	plx
	jml $009D11|!long

; Exit counter on file select
org $009D66
if !TransferableRam < !OverworldState
{
	lda.l !Sram+140+(!OverworldState-!TransferableRam),x
}
else
{
	lda.l !Sram+140-(!TransferableRam-!OverworldState),x
}
endif
