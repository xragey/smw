;-------------------------------------------------------------------------------
;
; Bank3SpriteHandler.asm
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Sprites that run from bank $03 are handled with an awkward if-then-else chain,
; which adds quite a bit of processing time to these sprites, especially those
; at the tail of the chain. This rewrites the routine to use a jump table for
; most of these sprites, saving both cycles and bytes in ROM.
;
; Installing this patch frees $03A19B (190 bytes).
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
else
	!sa1 = 0
	!fast = 0
endif

!bank = select(!fast, $80, $00)
!long = select(!fast, $800000, $000000)
!addr = select(!sa1, $6000, $0000)

!SpriteId = select(!sa1, $3200, $9E)

;-------------------------------------------------------------------------------

org $03A118
Bnk3CallSprMain:
	phb
	phk
	plb
	lda !SpriteId,x
	cmp #$A0
	bcc .HandleLowIds

.ExecutePtr
	sbc #$A0
	pea .Return-1
	asl
	tay
	lda .Pointers+1,y
	pha
	lda .Pointers,y
	pha
	rts

.Pointers
	dw $A259-1			; $A0 - Bowser
	dw $B163-1			; $A1 - Bowling ball
	dw $B2A9-1			; $A2 - Mechakoopa

; Utilize space *inside* the pointer table, which would be unused, since
; sprites $A3-$A7 don't use this routine anyway.
.HandleLowIds
	; Football
	cmp #$1B
	bne .HandleOtherLowIds
	jsr $8012

.Return
	plb
	rtl
	nop

.PointersCntd
	dw $9F38-1			; $A8 - Blargg
	dw $9890-1			; $A9 - Reznor
	dw $96F6-1			; $AA - Fishbone
	dw $9517-1			; $AB - Rex
	dw $9423-1			; $AC - Wooden spike
	dw $9423-1			; $AD - Wooden spike
	dw $9065-1			; $AE - Fishin' Boo
	dw $0000			; $AF
	dw $8F7A-1			; $B0 - Boo stream
	dw $9284-1			; $B1 - Snake block
	dw $9214-1			; $B2 - Falling spike
	dw $8EEC-1			; $B3 - Statue fireball
	dw $0000			; $B4
	dw $0000			; $B5
	dw $8F75-1			; $B6 - Reflecting fireball
	dw $8C2F-1			; $B7 - Carrot top lift
	dw $8C2F-1			; $B8 - Carrot top lift
	dw $8D6F-1			; $B9 - Info box
	dw $8DBB-1			; $BA - Timed lift
	dw $8E79-1			; $BB - Grey castle block
	dw $8A3C-1			; $BC - Bowser statue
	dw $8958-1			; $BD - Sliding koopa
	dw $88A3-1			; $BE - Swooper
	dw $8770-1			; $BF - Mega mole
	dw $86FF-1			; $C0 - Lava platform
	dw $85F6-1			; $C1 - Three flying turn blocks
	dw $84CA-1			; $C2 - Blurp
	dw $852F-1			; $C3 - Porcupuffer
	dw $8454-1			; $C4 - Falling grey platform
	dw $8087-1			; $C5 - Big Boo boss
	dw $C4DC-1			; $C6 - Spotlight
	dw $C30F-1			; $C7 - Invisible mushroom
	dw $C1F5-1			; $C8 - Light switch

.HandleOtherLowIds
	cmp #$51			; $51 - Ninji
	bne +
	jsr $C34C
	plb
	rtl

+	cmp #$7A			; $7A - Fireworks
	bne +
	jsr $C816
	plb
	rtl

+	jsr $AC97			; $7C - Peach
	plb
	rtl

; Change Bowser epilogue to match the new call format.
org $03A263
	rts
	nop
