;-------------------------------------------------------------------------------
;
; More SRAM
;
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Increases the SRAM capacity of Super Mario World to 339 bytes (up from 140) by
; extending the length of the RAM array that is transferred to and from SRAM.
;
; This patch differs from similar patches in that it retains the original game's
; logic in handling saving and loading, which means it should be compatible with
; all emulators and most other patches.
;
; Installing this patch frees $7E1F49 (141 bytes).
;
; See README.md for more (technical) information.
;
;-------------------------------------------------------------------------------

@asar 1.71

if read1($00FFD5) == $23
	if read1($00FFD7) > $0C
		fullsa1rom
	else
		sa1rom
	endif
	!sa1 = 1
	!fast = 0
elseif read1($00FFD5)&$10 == $10
	!sa1 = 0
	!fast = 1
endif

!bank = select(!fast, $80, $00)
!long = select(!fast, $800000, $000000)
!addr = select(!sa1, $6000, $0000)

;-------------------------------------------------------------------------------

; Transfer range, excluding 2 checksum bytes.
!cSramSize = 339

; !cSramSize bytes
; Ram area that is transferred to SRAM. Does not need to be equal to
; !OverworldState.
!TransferableRam = $1EA2|!addr

; 141 bytes
; Holds the state of the overworld.
!OverworldState = $1EA2|!addr

; 6*(!cSramSize+2) bytes
; SRAM array, divided in six blocks of !cSramSize bytes per block.
!Sram = select(!sa1, $41C000, $700000)

;-------------------------------------------------------------------------------

; Initial save data hijack. Save any change on the overworld editor to install.
assert read1($009F19) == $22, "Missing required Lunar Magic hijack"

; Sprite 0x19 fix. This fix differs between Lunar Magic versions. Supports both
; the old and new methods. Save any change on the overworld editor to install.
if read1($01E762) == $22
	!cLMSprite19Fix = $01E763
elseif read1($01E763) == $22
	!cLMSprite19Fix = $01E764
else
	assert 0, "Missing required Lunar Magic hijack"
endif

; ------------------------------------------------------------------------------

; Bypass $1F49 buffer.
org $009BDF : dw !TransferableRam
org $009D19 : dw !TransferableRam
org $009F17 : dw !OverworldState
org $009F23 : dw !OverworldState+111 ; $1F11-$1F26
org $00A195 : rts
org $048F94 : nop #11
org $048FA9 : nop #24
org $048FC8 : nop #6
org $048FD6 : nop #6
org $049041 : nop #11
org read3($009F1A) : skip 11 : dw !OverworldState

; Lunar Magic sprite 19 fix.
if !cLMSprite19Fix == $01E763
	org read3($01E763) : skip 7 : nop #3
elseif !cLMSprite19Fix == $01E764
	org read3($01E764) : skip 12 : nop #3
endif

; File offsets (assuming length 339+2).
org $009CCB : db $00, (!cSramSize+2)>>8, ((!cSramSize+2)*2)>>8
org $009CCE : db $00, (!cSramSize+2), (!cSramSize+2)*2

; File length.
org $009BF1 : dw !cSramSize
org $009D1E : dw !cSramSize

; File erasing routine.
org $009B54 : dw !cSramSize+2
org $009B5C : sta.l !Sram+((!cSramSize+2)*3),x

; File checksum routine.
org $009DC1 : dw (!cSramSize+2)*3
org $009DC6 : lda.l !Sram+!cSramSize,x ; 70 01 53
org $009DCF : dw !cSramSize
org $009DEE : dw ((!cSramSize+2)*3)-1

; Restore backup copy.
org $009C02 : dw (!cSramSize+2)*3
org $009C08 : dw (!cSramSize+2)*2
org $009CF7 : autoclean jml EmplaceBackup

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

; File clearing routine (called when switching files on the menu).
org $009F06 : autoclean jml ClearFile

freecode
ClearFile:
	rep #$10
	ldx #(!cSramSize-2)
-	stz !TransferableRam,x
	dex
	bpl -
	sep #$10
	jml $009F0E|!long

; Exit counter on file select.
org $009D66
if !TransferableRam < !OverworldState
	lda.l !Sram+140+(!OverworldState-!TransferableRam),x
else
	lda.l !Sram+140-(!TransferableRam-!OverworldState),x
endif
