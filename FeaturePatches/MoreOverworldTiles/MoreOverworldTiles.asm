; ----------------------------------------------------------------------------------------------------------------------------------
;
; "More Overworld Tiles"
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Fully implements Lunar Magic's "more levels and overworld events" feature. This increases the amount of translevels on the over-
; world to 256 (up from 96) and the amount of overworld events to 255 (up from 128).
;
; Prerequisites:
; * Lunar Magic 3.10 and up (Earlier versions are not supported);
; * Lunar Magic overworld expansion hijack (press shift + ctrl + alt + F8 while on the overworld editor);
; * Lunar Magic overworld teleport hijack (set the transfer index for a pipe or star to 0x1B or higher);
; * Lunar Magic overworld path hijack (set the transfer index for a red path tile to 0x0E or higher);
; * Some form of SRAM expansion that provides at least 318 bytes of total SRAM (per save, excluding optional checksum);
; * Some form of ASM that has reclaimed offset $7E1F49 (141 bytes).
;
; Note that this patch may change the intro stage to 0x1C5.
; You will need to reapply this patch if you later switch to Lunar Magic's LC_LZ3 compression.
;
; ----------------------------------------------------------------------------------------------------------------------------------

@asar 1.71

!sa1  = 0
!fast = 0
!bank = $00
!addr = $0000
!long = $000000

; ----------------------------------------------------------------------------------------------------------------------------------

; Shift of array $1F02-$1F10. Do not change.
!cOffset1F02 = 160

; Shift of array $1F11-$1F2E. Do not change.
!cOffset1F11 = 177

; Amount of bytes, offset from !OverworldState, to zero out upon loading the overworld.
!cOverworldStateLength = 318

; 318 bytes
; Holds the state of the overworld. Do not change.
!OverworldState = $1EA2|!addr

; 32 bytes
; Bitwise tracker for in which stages all dragon coins were collected. Each byte holds 8 stages.
!DragonCoinFlags = $010D|!addr

; 32 bytes
; Bitwise tracker for in which stages the 1UP check points were triggered. Each byte holds 8 stages.
!CheckpointFlags = $012D|!addr

; 32 bytes
; Bitwise tracker for in which stages a moon was collected. Each byte holds 8 stages.
!MoonFlags = $014D|!addr

; SRAM array.
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

assert read2($009BF1) >= 318, "Insufficient SRAM available to install"
assert read1($009F19) == $22, "Lunar Magic standard overworld ASM is not installed"
assert read1($049199) == $22, "Lunar Magic standard overworld ASM is not installed"
assert read1($04DCA5) == $22, "Lunar Magic standard overworld ASM is not installed"
assert read1($048509) == $22, "Lunar Magic overworld teleport hijack is not installed"
assert read1($048566) == $22, "Lunar Magic overworld teleport hijack is not installed"
assert read1($049A35) == $22, "Lunar Magic overworld path hijack is not installed"
assert read1($03BBD8) == $BF, "Lunar Magic translevel and event expansion is not installed"

; ----------------------------------------------------------------------------------------------------------------------------------

; Zero out overworld data
org $009F06|!long : autoclean jml ClearMemory

freecode
ClearMemory:
	rep #$10
	ldx #!cOverworldStateLength
-	stz !OverworldState,x
	dex
	bpl -
	sep #$10
	ldx #$20
-	stz !DragonCoinFlags,x
	stz !CheckpointFlags,x
	stz !MoonFlags,x
	dex
	bpl -
	jml $009F0E|!long

; Overworld tile initialization
org read3($009F1A)|!long
	skip  4 : dw $00FE
	skip  5 : dw !OverworldState

; Opening message in intro stage
org read3($01E763)|!long
	skip  5 : dw ($1F11+!cOffset1F11)|!addr

; Entering overworld pipe
org read3($04850A)|!long
	skip  4 : dw ($1F11+!cOffset1F11)|!addr
	skip 28 : dw ($1F1F+!cOffset1F11)|!addr
	skip  7 : dw ($1F21+!cOffset1F11)|!addr

; Map loading
org read3($048567)|!long
	skip 20 : dw ($1F17+!cOffset1F11)|!addr
	skip  5 : dw ($1F1F+!cOffset1F11)|!addr
	skip  5 : dw ($1F19+!cOffset1F11)|!addr
	skip  5 : dw ($1F21+!cOffset1F11)|!addr

; After clearing a stage
org read3($048F8B)|!long
	skip 14 : dw !OverworldState

; Entering a stage
org read3($04919A)|!long
	skip 23 : dw !OverworldState
	skip  6 : dw !OverworldState
	skip 32 : dw ($1F1F+!cOffset1F11)|!addr
	skip  3 : dw ($1F21+!cOffset1F11)|!addr
	skip 55 : dw ($1F11+!cOffset1F11)|!addr

; Teleport path tile
org read3($049A36)|!long
	skip 14 : dw ($1F19+!cOffset1F11)|!addr
	skip  7 : dw ($1F17+!cOffset1F11)|!addr
	skip 23 : dw ($1F19+!cOffset1F11)|!addr
	skip  5 : dw ($1F17+!cOffset1F11)|!addr
	skip 22 : dw ($1F21+!cOffset1F11)|!addr
	skip  8 : dw ($1F1F+!cOffset1F11)|!addr

; Selecting amount of players
org read3($04DCA6)|!long
	skip 12 : dw ($1F02+!cOffset1F02)|!addr

; Swapping players on the overworld
org read3($049DFE)
    skip 1 : dw ($1F11+!cOffset1F11)|!addr
    skip 1 : dw ($1F12+!cOffset1F11)|!addr

; Fix event splice table to respect most significant bit
org $04E46C|!long : autoclean jsl EventTableIndex
org $04E6D9|!long : jsl EventTableIndex
org $04E6EE|!long : sep #$30
org $04ECB5|!long : jsl EventTableIndex
org $04ECBD|!long : jsl RestoreState
org $04ECCD|!long : jsl RestoreState2 : nop

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

; Exit counter on file select
org $009D66|!long
	lda.l !Sram+140+!cOffset1F11,x

; If Lunar Magic's "Message Sprite Fix" has not been installed
if read1($00A0A0) == $9C
{
org $00A0A1|!long : dw ($1F11+!cOffset1F11)|!addr
}
endif

; If Lunar Magic's implementation of LC_LZ3 has been installed
if read1($049DFE) == $22
{
org read3($04DBBA)|!long
	skip 45 : dw ($1F11+!cOffset1F11)|!addr
}
endif

; ----------------------------------------------------------------------------------------------------------------------------------

; Disable writes to array $1FD6
org $07F782|!long : nop #3

; Remap dragon coin flags
org $00977A|!long : dw !DragonCoinFlags
org $00F352|!long : dw !DragonCoinFlags
org $00F355|!long : dw !DragonCoinFlags
org $0DB2D8|!long : dw !DragonCoinFlags

; Remap 1UP check point flags
org $00F2B9|!long : dw !CheckpointFlags
org $00F2BC|!long : dw !CheckpointFlags
org $0DA5A8|!long : dw !CheckpointFlags

; Remap 3UP moon flags
org $00F323|!long : dw !MoonFlags
org $00F326|!long : dw !MoonFlags
org $0DA59D|!long : dw !MoonFlags
org $009780|!long : dw !MoonFlags

; Remap array $7E1F02-$7E1F10
org $048F97|!long : dw ($1F02+!cOffset1F02)|!addr
org $04DA5D|!long : dw ($1F02+!cOffset1F02)|!addr
org $04E461|!long : dw ($1F02+!cOffset1F02)|!addr
org $04E612|!long : dw ($1F02+!cOffset1F02)|!addr
org $04EA15|!long : dw ($1F02+!cOffset1F02)|!addr
org $04EA1C|!long : dw ($1F02+!cOffset1F02)|!addr
org $05B36D|!long : dw ($1F02+!cOffset1F02)|!addr

org $04FD86|!long : dw ($1F07+!cOffset1F02)|!addr

; Remap array $7E1F11-$7E1F2E
org $0096D3|!long : dw ($1F11+!cOffset1F11)|!addr
org $009F23|!long : dw ($1F11+!cOffset1F11)|!addr
org $00A12E|!long : dw ($1F11+!cOffset1F11)|!addr
org $00A54C|!long : dw ($1F11+!cOffset1F11)|!addr
org $00C9DC|!long : dw ($1F11+!cOffset1F11)|!addr
org $01E2F7|!long : dw ($1F11+!cOffset1F11)|!addr
org $01EC2D|!long : dw ($1F11+!cOffset1F11)|!addr
org $02DA7D|!long : dw ($1F11+!cOffset1F11)|!addr
org $0392FC|!long : dw ($1F11+!cOffset1F11)|!addr
org $048379|!long : dw ($1F11+!cOffset1F11)|!addr
org $0486FE|!long : dw ($1F11+!cOffset1F11)|!addr
org $048E3E|!long : dw ($1F11+!cOffset1F11)|!addr
org $048EF7|!long : dw ($1F11+!cOffset1F11)|!addr
org $04933C|!long : dw ($1F11+!cOffset1F11)|!addr
org $049853|!long : dw ($1F11+!cOffset1F11)|!addr
org $0498B6|!long : dw ($1F11+!cOffset1F11)|!addr
org $049A2D|!long : dw ($1F11+!cOffset1F11)|!addr
org $049A9D|!long : dw ($1F11+!cOffset1F11)|!addr
org $049AA6|!long : dw ($1F11+!cOffset1F11)|!addr
org $049E0C|!long : dw ($1F11+!cOffset1F11)|!addr
org $04D703|!long : dw ($1F11+!cOffset1F11)|!addr
org $04D761|!long : dw ($1F11+!cOffset1F11)|!addr
org $04DBA4|!long : dw ($1F11+!cOffset1F11)|!addr
org $04DBEC|!long : dw ($1F11+!cOffset1F11)|!addr
org $04DBEF|!long : dw ($1F11+!cOffset1F11)|!addr
org $04DBF4|!long : dw ($1F11+!cOffset1F11)|!addr
org $04DC12|!long : dw ($1F11+!cOffset1F11)|!addr
org $04DCDD|!long : dw ($1F11+!cOffset1F11)|!addr
org $04EB3E|!long : dw ($1F11+!cOffset1F11)|!addr
org $04F899|!long : dw ($1F11+!cOffset1F11)|!addr
org $04FC4D|!long : dw ($1F11+!cOffset1F11)|!addr
org $04FD7D|!long : dw ($1F11+!cOffset1F11)|!addr
org $05D7CC|!long : dw ($1F11+!cOffset1F11)|!addr
org $05D88C|!long : dw ($1F11+!cOffset1F11)|!addr
org $05D8AF|!long : dw ($1F11+!cOffset1F11)|!addr

org $04870A|!long : dw ($1F12+!cOffset1F11)|!addr

org $0486AE|!long : dw ($1F13+!cOffset1F11)|!addr
org $048722|!long : dw ($1F13+!cOffset1F11)|!addr
org $048966|!long : dw ($1F13+!cOffset1F11)|!addr
org $048CED|!long : dw ($1F13+!cOffset1F11)|!addr
org $048D9F|!long : dw ($1F13+!cOffset1F11)|!addr
org $048DAC|!long : dw ($1F13+!cOffset1F11)|!addr
org $0491A9|!long : dw ($1F13+!cOffset1F11)|!addr
org $0491B3|!long : dw ($1F13+!cOffset1F11)|!addr
org $04927E|!long : dw ($1F13+!cOffset1F11)|!addr
org $049285|!long : dw ($1F13+!cOffset1F11)|!addr
org $0493FB|!long : dw ($1F13+!cOffset1F11)|!addr
org $049403|!long : dw ($1F13+!cOffset1F11)|!addr
org $04966C|!long : dw ($1F13+!cOffset1F11)|!addr
org $049672|!long : dw ($1F13+!cOffset1F11)|!addr
org $04967F|!long : dw ($1F13+!cOffset1F11)|!addr
org $049685|!long : dw ($1F13+!cOffset1F11)|!addr
org $0496DB|!long : dw ($1F13+!cOffset1F11)|!addr
org $04979B|!long : dw ($1F13+!cOffset1F11)|!addr
org $0498C7|!long : dw ($1F13+!cOffset1F11)|!addr

org $048DB1|!long : dw ($1F15+!cOffset1F11)|!addr
org $048DBE|!long : dw ($1F15+!cOffset1F11)|!addr

org $04854E|!long : dw ($1F17+!cOffset1F11)|!addr
org $048634|!long : dw ($1F17+!cOffset1F11)|!addr
org $04865A|!long : dw ($1F17+!cOffset1F11)|!addr
org $048DF6|!long : dw ($1F17+!cOffset1F11)|!addr
org $048EC1|!long : dw ($1F17+!cOffset1F11)|!addr
org $048EFE|!long : dw ($1F17+!cOffset1F11)|!addr
org $048F19|!long : dw ($1F17+!cOffset1F11)|!addr
org $04900B|!long : dw ($1F17+!cOffset1F11)|!addr
org $0491EF|!long : dw ($1F17+!cOffset1F11)|!addr
org $04932D|!long : dw ($1F17+!cOffset1F11)|!addr
org $0493DE|!long : dw ($1F17+!cOffset1F11)|!addr
org $0493EC|!long : dw ($1F17+!cOffset1F11)|!addr
org $04947A|!long : dw ($1F17+!cOffset1F11)|!addr
org $0497AF|!long : dw ($1F17+!cOffset1F11)|!addr
org $049826|!long : dw ($1F17+!cOffset1F11)|!addr
org $049829|!long : dw ($1F17+!cOffset1F11)|!addr
org $049845|!long : dw ($1F17+!cOffset1F11)|!addr
org $049918|!long : dw ($1F17+!cOffset1F11)|!addr
org $049A48|!long : dw ($1F17+!cOffset1F11)|!addr
org $049A64|!long : dw ($1F17+!cOffset1F11)|!addr
org $04F2B4|!long : dw ($1F17+!cOffset1F11)|!addr
org $04FF01|!long : dw ($1F17+!cOffset1F11)|!addr

org $04F2BB|!long : dw ($1F18+!cOffset1F11)|!addr

org $04855B|!long : dw ($1F19+!cOffset1F11)|!addr
org $048643|!long : dw ($1F19+!cOffset1F11)|!addr
org $048669|!long : dw ($1F19+!cOffset1F11)|!addr
org $048DFF|!long : dw ($1F19+!cOffset1F11)|!addr
org $048EC7|!long : dw ($1F19+!cOffset1F11)|!addr
org $048F05|!long : dw ($1F19+!cOffset1F11)|!addr
org $048F22|!long : dw ($1F19+!cOffset1F11)|!addr
org $049014|!long : dw ($1F19+!cOffset1F11)|!addr
org $0491FB|!long : dw ($1F19+!cOffset1F11)|!addr
org $049325|!long : dw ($1F19+!cOffset1F11)|!addr
org $0497C6|!long : dw ($1F19+!cOffset1F11)|!addr
org $04984A|!long : dw ($1F19+!cOffset1F11)|!addr
org $0498E0|!long : dw ($1F19+!cOffset1F11)|!addr
org $0498E3|!long : dw ($1F19+!cOffset1F11)|!addr
org $0498ED|!long : dw ($1F19+!cOffset1F11)|!addr
org $049924|!long : dw ($1F19+!cOffset1F11)|!addr
org $049A40|!long : dw ($1F19+!cOffset1F11)|!addr
org $049A5E|!long : dw ($1F19+!cOffset1F11)|!addr
org $049E86|!long : dw ($1F19+!cOffset1F11)|!addr
org $049E8C|!long : dw ($1F19+!cOffset1F11)|!addr
org $04F2C2|!long : dw ($1F19+!cOffset1F11)|!addr
org $04F9DB|!long : dw ($1F19+!cOffset1F11)|!addr
org $04FF21|!long : dw ($1F19+!cOffset1F11)|!addr

org $0498E7|!long : dw ($1F1A+!cOffset1F11)|!addr
org $0498EA|!long : dw ($1F1A+!cOffset1F11)|!addr
org $04F2C9|!long : dw ($1F1A+!cOffset1F11)|!addr
org $04F9E1|!long : dw ($1F1A+!cOffset1F11)|!addr

org $048525|!long : dw ($1F1F+!cOffset1F11)|!addr
org $048555|!long : dw ($1F1F+!cOffset1F11)|!addr
org $048E66|!long : dw ($1F1F+!cOffset1F11)|!addr
org $0491F8|!long : dw ($1F1F+!cOffset1F11)|!addr
org $04952E|!long : dw ($1F1F+!cOffset1F11)|!addr
org $049586|!long : dw ($1F1F+!cOffset1F11)|!addr
org $049608|!long : dw ($1F1F+!cOffset1F11)|!addr
org $049921|!long : dw ($1F1F+!cOffset1F11)|!addr
org $049A81|!long : dw ($1F1F+!cOffset1F11)|!addr
org $05D851|!long : dw ($1F1F+!cOffset1F11)|!addr
org $05D865|!long : dw ($1F1F+!cOffset1F11)|!addr

org $04852A|!long : dw ($1F21+!cOffset1F11)|!addr
org $048562|!long : dw ($1F21+!cOffset1F11)|!addr
org $048E6B|!long : dw ($1F21+!cOffset1F11)|!addr
org $049204|!long : dw ($1F21+!cOffset1F11)|!addr
org $049533|!long : dw ($1F21+!cOffset1F11)|!addr
org $04958B|!long : dw ($1F21+!cOffset1F11)|!addr
org $04960D|!long : dw ($1F21+!cOffset1F11)|!addr
org $04992D|!long : dw ($1F21+!cOffset1F11)|!addr
org $049A78|!long : dw ($1F21+!cOffset1F11)|!addr
org $05D859|!long : dw ($1F21+!cOffset1F11)|!addr
org $05D873|!long : dw ($1F21+!cOffset1F11)|!addr

org $0DB590|!long : dw ($1F27+!cOffset1F11)|!addr
org $0DEC97|!long : dw ($1F27+!cOffset1F11)|!addr
org $00EEAF|!long : dw ($1F27+!cOffset1F11)|!addr
org $00EEB5|!long : dw ($1F27+!cOffset1F11)|!addr

org $0DB941|!long : dw ($1F29+!cOffset1F11)|!addr

org $00A0F7|!long : dw ($1F2E+!cOffset1F11)|!addr
org $04EA1F|!long : dw ($1F2E+!cOffset1F11)|!addr
