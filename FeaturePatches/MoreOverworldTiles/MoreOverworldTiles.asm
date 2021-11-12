;-------------------------------------------------------------------------------
;
; More Overworld Tiles
;
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Proposal implementation for Lunar Magic's "more levels and overworld events"
; feature by moving and/or expanding the affected level tables. This increases
; the amount of translevels to 256 (up from 96) and the amount of overworld
; events to 255 (up from 128).
;
; This patch has numerous prerequisites before it can be applied. Refer to the
; README for additional (and technical) information.
;
;-------------------------------------------------------------------------------

@asar 1.71

if read1($00FFD5) == $23
	if read1($00FD7) > $0C
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

; Shift of array $1F02-$1F10. Do not change.
!cOffset1F02 = 160

; Shift of array $1F11-$1F2E. Do not change.
!cOffset1F11 = 177

; Amount of bytes, offset from !OverworldState, to zero out upon loading the
; overworld.
!cOverworldStateLength = 318

; 318 bytes
; Holds the state of the overworld. Do not change.
!OverworldState = $1EA2|!addr

; 32 bytes
; Bitwise tracker for in which stages all dragon coins were collected.
!DragonCoinFlags = select(!sa1, $6113, $010D)

; 32 bytes
; Bitwise tracker for in which stages the 1UP check points were triggered.
!CheckpointFlags = select(!sa1, $6133, $012D)

; 32 bytes
; Bitwise tracker for in which stages a moon was collected.
!MoonFlags = select(!sa1, $6153, $014D)

; SRAM array.
!Sram = select(!sa1, $41C000, $700000)

;-------------------------------------------------------------------------------

assert read2($009BF1) >= 318, "Insufficient SRAM available to install"
assert read1($009F19) == $22, "Lunar Magic overworld ASM is not installed"
assert read1($049199) == $22, "Lunar Magic overworld ASM is not installed"
assert read1($04DCA5) == $22, "Lunar Magic overworld ASM is not installed"
assert read1($048509) == $22, "Lunar Magic overworld teleport is not installed"
assert read1($048566) == $22, "Lunar Magic overworld teleport is not installed"
assert read1($049A35) == $22, "Lunar Magic overworld path ASM is not installed"
assert read1($03BBD8) == $BF, "Lunar Magic overworld expansion is not installed"

;-------------------------------------------------------------------------------

; Overworld tile initialization.
org read3($009F1A)
	skip  4 : dw $00FE
	skip  5 : dw !OverworldState

; Opening message in intro stage.
if read1($01E762) == $22
	org read3($01E763) : skip 5 : dw ($1F11+!cOffset1F11)|!addr
elseif read1($01E763) == $22
	org read3($01E764) : skip 10 : dw ($1F11+!cOffset1F11)|!addr
endif

; Entering overworld pipe.
org read3($04850A)
	skip  4 : dw ($1F11+!cOffset1F11)|!addr
	skip 28 : dw ($1F1F+!cOffset1F11)|!addr
	skip  7 : dw ($1F21+!cOffset1F11)|!addr

; Map loading.
org read3($048567)
	skip 20 : dw ($1F17+!cOffset1F11)|!addr
	skip  5 : dw ($1F1F+!cOffset1F11)|!addr
	skip  5 : dw ($1F19+!cOffset1F11)|!addr
	skip  5 : dw ($1F21+!cOffset1F11)|!addr

; After clearing a stage.
org read3($048F8B)
	skip 14 : dw !OverworldState

; Entering a stage.
org read3($04919A)
	skip 23 : dw !OverworldState
	skip  6 : dw !OverworldState
	skip 32 : dw ($1F1F+!cOffset1F11)|!addr
	skip  3 : dw ($1F21+!cOffset1F11)|!addr
	skip 55 : dw ($1F11+!cOffset1F11)|!addr

; Teleport path tile.
org read3($049A36)
	skip 14 : dw ($1F19+!cOffset1F11)|!addr
	skip  7 : dw ($1F17+!cOffset1F11)|!addr
	skip 23 : dw ($1F19+!cOffset1F11)|!addr
	skip  5 : dw ($1F17+!cOffset1F11)|!addr
	skip 22 : dw ($1F21+!cOffset1F11)|!addr
	skip  8 : dw ($1F1F+!cOffset1F11)|!addr

; Selecting amount of players.
org read3($04DCA6)
	skip 12 : dw ($1F02+!cOffset1F02)|!addr

; Swapping players on the overworld.
org read3($049DFE)
    skip 1 : dw ($1F11+!cOffset1F11)|!addr
    skip 1 : dw ($1F12+!cOffset1F11)|!addr

; Fix event splice table to respect most significant bit.
org $04E46C : autoclean jsl EventTableIndex
org $04E6D9 : jsl EventTableIndex
org $04E6EE : sep #$30
org $04ECB5 : jsl EventTableIndex
org $04ECBD : jsl RestoreState
org $04ECCD : jsl RestoreState2 : nop

freecode
EventTableIndex:
	rep #$30
	and #$00FF
	asl
	tax
	rtl

RestoreState:
	sep #$20
	asl #4
	rtl

RestoreState2:
	sep #$30
	lda #$1C
	sta $1B84|!addr
	rtl

; Exit counter on file select.
org $009D66
	lda.l !Sram+140+!cOffset1F11,x

; If Lunar Magic's implementation of LC_LZ3 has been installed
if read1($049DFE) == $22
	org read3($04DBBA) : skip 45 : dw ($1F11+!cOffset1F11)|!addr
endif

;-------------------------------------------------------------------------------

; Disable writes to array $1FD6
org $07F782 : nop #3

; Remap dragon coin flags
org $00977A : dw !DragonCoinFlags
org $00F352 : dw !DragonCoinFlags
org $00F355 : dw !DragonCoinFlags
org $0DB2D8 : dw !DragonCoinFlags

; Remap 1UP check point flags
org $00F2B9 : dw !CheckpointFlags
org $00F2BC : dw !CheckpointFlags
org $0DA5A8 : dw !CheckpointFlags

; Remap 3UP moon flags
org $00F323 : dw !MoonFlags
org $00F326 : dw !MoonFlags
org $0DA59D : dw !MoonFlags
org $009780 : dw !MoonFlags

; Remap array $7E1F02-$7E1F10
org $048F97 : dw ($1F02+!cOffset1F02)|!addr
org $04DA5D : dw ($1F02+!cOffset1F02)|!addr
org $04E461 : dw ($1F02+!cOffset1F02)|!addr
org $04E612 : dw ($1F02+!cOffset1F02)|!addr
org $04EA15 : dw ($1F02+!cOffset1F02)|!addr
org $04EA1C : dw ($1F02+!cOffset1F02)|!addr
org $05B36D : dw ($1F02+!cOffset1F02)|!addr

org $04FD86 : dw ($1F07+!cOffset1F02)|!addr

; Remap array $7E1F11-$7E1F2E
org $0096D3 : dw ($1F11+!cOffset1F11)|!addr
org $009F23 : dw ($1F11+!cOffset1F11)|!addr
org $00A12E : dw ($1F11+!cOffset1F11)|!addr
org $00A54C : dw ($1F11+!cOffset1F11)|!addr
org $00C9DC : dw ($1F11+!cOffset1F11)|!addr
org $01E2F7 : dw ($1F11+!cOffset1F11)|!addr
org $01EC2D : dw ($1F11+!cOffset1F11)|!addr
org $02DA7D : dw ($1F11+!cOffset1F11)|!addr
org $0392FC : dw ($1F11+!cOffset1F11)|!addr
org $048379 : dw ($1F11+!cOffset1F11)|!addr
org $0486FE : dw ($1F11+!cOffset1F11)|!addr
org $048E3E : dw ($1F11+!cOffset1F11)|!addr
org $048EF7 : dw ($1F11+!cOffset1F11)|!addr
org $04933C : dw ($1F11+!cOffset1F11)|!addr
org $049853 : dw ($1F11+!cOffset1F11)|!addr
org $0498B6 : dw ($1F11+!cOffset1F11)|!addr
org $049A2D : dw ($1F11+!cOffset1F11)|!addr
org $049A9D : dw ($1F11+!cOffset1F11)|!addr
org $049AA6 : dw ($1F11+!cOffset1F11)|!addr
org $049E0C : dw ($1F11+!cOffset1F11)|!addr
org $04D703 : dw ($1F11+!cOffset1F11)|!addr
org $04D761 : dw ($1F11+!cOffset1F11)|!addr
org $04DBA4 : dw ($1F11+!cOffset1F11)|!addr
org $04DBEC : dw ($1F11+!cOffset1F11)|!addr
org $04DBEF : dw ($1F11+!cOffset1F11)|!addr
org $04DBF4 : dw ($1F11+!cOffset1F11)|!addr
org $04DC12 : dw ($1F11+!cOffset1F11)|!addr
org $04DCDD : dw ($1F11+!cOffset1F11)|!addr
org $04EB3E : dw ($1F11+!cOffset1F11)|!addr
org $04F899 : dw ($1F11+!cOffset1F11)|!addr
org $04FC4D : dw ($1F11+!cOffset1F11)|!addr
org $04FD7D : dw ($1F11+!cOffset1F11)|!addr
org $05D7CC : dw ($1F11+!cOffset1F11)|!addr
org $05D88C : dw ($1F11+!cOffset1F11)|!addr
org $05D8AF : dw ($1F11+!cOffset1F11)|!addr

org $04870A : dw ($1F12+!cOffset1F11)|!addr

org $0486AE : dw ($1F13+!cOffset1F11)|!addr
org $048722 : dw ($1F13+!cOffset1F11)|!addr
org $048966 : dw ($1F13+!cOffset1F11)|!addr
org $048CED : dw ($1F13+!cOffset1F11)|!addr
org $048D9F : dw ($1F13+!cOffset1F11)|!addr
org $048DAC : dw ($1F13+!cOffset1F11)|!addr
org $0491A9 : dw ($1F13+!cOffset1F11)|!addr
org $0491B3 : dw ($1F13+!cOffset1F11)|!addr
org $04927E : dw ($1F13+!cOffset1F11)|!addr
org $049285 : dw ($1F13+!cOffset1F11)|!addr
org $0493FB : dw ($1F13+!cOffset1F11)|!addr
org $049403 : dw ($1F13+!cOffset1F11)|!addr
org $04966C : dw ($1F13+!cOffset1F11)|!addr
org $049672 : dw ($1F13+!cOffset1F11)|!addr
org $04967F : dw ($1F13+!cOffset1F11)|!addr
org $049685 : dw ($1F13+!cOffset1F11)|!addr
org $0496DB : dw ($1F13+!cOffset1F11)|!addr
org $04979B : dw ($1F13+!cOffset1F11)|!addr
org $0498C7 : dw ($1F13+!cOffset1F11)|!addr

org $048DB1 : dw ($1F15+!cOffset1F11)|!addr
org $048DBE : dw ($1F15+!cOffset1F11)|!addr

org $04854E : dw ($1F17+!cOffset1F11)|!addr
org $048634 : dw ($1F17+!cOffset1F11)|!addr
org $04865A : dw ($1F17+!cOffset1F11)|!addr
org $048DF6 : dw ($1F17+!cOffset1F11)|!addr
org $048EC1 : dw ($1F17+!cOffset1F11)|!addr
org $048EFE : dw ($1F17+!cOffset1F11)|!addr
org $048F19 : dw ($1F17+!cOffset1F11)|!addr
org $04900B : dw ($1F17+!cOffset1F11)|!addr
org $0491EF : dw ($1F17+!cOffset1F11)|!addr
org $04932D : dw ($1F17+!cOffset1F11)|!addr
org $0493DE : dw ($1F17+!cOffset1F11)|!addr
org $0493EC : dw ($1F17+!cOffset1F11)|!addr
org $04947A : dw ($1F17+!cOffset1F11)|!addr
org $0497AF : dw ($1F17+!cOffset1F11)|!addr
org $049826 : dw ($1F17+!cOffset1F11)|!addr
org $049829 : dw ($1F17+!cOffset1F11)|!addr
org $049845 : dw ($1F17+!cOffset1F11)|!addr
org $049918 : dw ($1F17+!cOffset1F11)|!addr
org $049A48 : dw ($1F17+!cOffset1F11)|!addr
org $049A64 : dw ($1F17+!cOffset1F11)|!addr
org $04F2B4 : dw ($1F17+!cOffset1F11)|!addr
org $04FF01 : dw ($1F17+!cOffset1F11)|!addr

org $04F2BB : dw ($1F18+!cOffset1F11)|!addr

org $04855B : dw ($1F19+!cOffset1F11)|!addr
org $048643 : dw ($1F19+!cOffset1F11)|!addr
org $048669 : dw ($1F19+!cOffset1F11)|!addr
org $048DFF : dw ($1F19+!cOffset1F11)|!addr
org $048EC7 : dw ($1F19+!cOffset1F11)|!addr
org $048F05 : dw ($1F19+!cOffset1F11)|!addr
org $048F22 : dw ($1F19+!cOffset1F11)|!addr
org $049014 : dw ($1F19+!cOffset1F11)|!addr
org $0491FB : dw ($1F19+!cOffset1F11)|!addr
org $049325 : dw ($1F19+!cOffset1F11)|!addr
org $0497C6 : dw ($1F19+!cOffset1F11)|!addr
org $04984A : dw ($1F19+!cOffset1F11)|!addr
org $0498E0 : dw ($1F19+!cOffset1F11)|!addr
org $0498E3 : dw ($1F19+!cOffset1F11)|!addr
org $0498ED : dw ($1F19+!cOffset1F11)|!addr
org $049924 : dw ($1F19+!cOffset1F11)|!addr
org $049A40 : dw ($1F19+!cOffset1F11)|!addr
org $049A5E : dw ($1F19+!cOffset1F11)|!addr
org $049E86 : dw ($1F19+!cOffset1F11)|!addr
org $049E8C : dw ($1F19+!cOffset1F11)|!addr
org $04F2C2 : dw ($1F19+!cOffset1F11)|!addr
org $04F9DB : dw ($1F19+!cOffset1F11)|!addr
org $04FF21 : dw ($1F19+!cOffset1F11)|!addr

org $0498E7 : dw ($1F1A+!cOffset1F11)|!addr
org $0498EA : dw ($1F1A+!cOffset1F11)|!addr
org $04F2C9 : dw ($1F1A+!cOffset1F11)|!addr
org $04F9E1 : dw ($1F1A+!cOffset1F11)|!addr

org $048525 : dw ($1F1F+!cOffset1F11)|!addr
org $048555 : dw ($1F1F+!cOffset1F11)|!addr
org $048E66 : dw ($1F1F+!cOffset1F11)|!addr
org $0491F8 : dw ($1F1F+!cOffset1F11)|!addr
org $04952E : dw ($1F1F+!cOffset1F11)|!addr
org $049586 : dw ($1F1F+!cOffset1F11)|!addr
org $049608 : dw ($1F1F+!cOffset1F11)|!addr
org $049921 : dw ($1F1F+!cOffset1F11)|!addr
org $049A81 : dw ($1F1F+!cOffset1F11)|!addr
org $05D851 : dw ($1F1F+!cOffset1F11)|!addr
org $05D865 : dw ($1F1F+!cOffset1F11)|!addr

org $04852A : dw ($1F21+!cOffset1F11)|!addr
org $048562 : dw ($1F21+!cOffset1F11)|!addr
org $048E6B : dw ($1F21+!cOffset1F11)|!addr
org $049204 : dw ($1F21+!cOffset1F11)|!addr
org $049533 : dw ($1F21+!cOffset1F11)|!addr
org $04958B : dw ($1F21+!cOffset1F11)|!addr
org $04960D : dw ($1F21+!cOffset1F11)|!addr
org $04992D : dw ($1F21+!cOffset1F11)|!addr
org $049A78 : dw ($1F21+!cOffset1F11)|!addr
org $05D859 : dw ($1F21+!cOffset1F11)|!addr
org $05D873 : dw ($1F21+!cOffset1F11)|!addr

org $0DB590 : dw ($1F27+!cOffset1F11)|!addr
org $0DEC97 : dl ($1F27+!cOffset1F11)|!addr
org $00EEAF : dw ($1F27+!cOffset1F11)|!addr
org $00EEB5 : dw ($1F27+!cOffset1F11)|!addr

org $0DB941 : dw ($1F29+!cOffset1F11)|!addr

org $00A0F7 : dw ($1F2E+!cOffset1F11)|!addr
org $04EA1F : dw ($1F2E+!cOffset1F11)|!addr
