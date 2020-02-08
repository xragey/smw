; ----------------------------------------------------------------------------------------------------------------------------------
;
; "Item Memory"
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
; 
; Replaces the item memory system in Super Mario World with a different system that assigns a bit to every individual tile in a
; stage, rather than having columns within a screen share the same bit. Also implements item memory settings 3. Implements a flag
; that can be used to toggle the use of item memory. Compatible with the ExLevel system implemented by recent versions of Lunar
; Magic.
;
; Installing this patch reclaims offset $7E19F8 (384 bytes).
;
; Division and multiply routines by GreenHammerBro <https://smwc.me/u/18802>
; Additional coding by lx5 <https://github.com/TheLX5>
;
; ----------------------------------------------------------------------------------------------------------------------------------

@asar 1.71

!sa1  = 0
!fast = 0
!bank = $00
!addr = $0000
!long = $000000

; ----------------------------------------------------------------------------------------------------------------------------------

; 2 bytes
; Screen size as defined by ExLevel specification.
!ExLevelScreenSize = $13D7|!addr

; 1 byte
; Toggles the use of item memory.
; ------r- : Disable reading (everything will always respawn).
; -------w : Disable writing.
!ItemMemoryMask = $7F9C7B

; 7168 bytes
; Item memory, divided in four blocks of 1792 bytes per block.
!ItemMemory = $7F9C7C

; ----------------------------------------------------------------------------------------------------------------------------------

; Loading level code
org $0096F4|!long
	autoclean jsl ClearItemMemory
	
freecode
ClearItemMemory:
	lda $141A|!addr
	bne +
	
if !sa1
{
	; rather crude, could be optimized
	rep #$30
	ldx #$1C00
	lda #$0000
-	dex
	dex
	sta !ItemMemory,x
	bpl -
	sep #$30
}
else
{
	rep #$30
	lda.w #!ItemMemory
	sta.w $2181
	sep #$20
	lda.b #!ItemMemory>>16
	sta.w $2183
	ldx #$8008
	stx $4300
	ldx #GetMemory_indices ; address of a zero byte
	stx $4302
	lda #GetMemory_indices>>16 ; address of a zero byte
	sta $4304
	ldx #$1C00
	stx $4305
	lda #$01
	sta $420B
	sep #$10
}
endif

+	jml $05D796|!long ; restored code

; Coin object creation routine
org $0DA8D3|!long
	sta $01
	jsr $A6B1
SingleTile:
	cpx #$04
	bne GenerateTile
	phx
	phy
	lda $1BA1|!addr
	sta $9B ; ---xxxxx : horizontal screen number
	tya
	and #$0F
	asl #4
	sta $9A ; xxxx---- : x-position, low
	pei ($00)
	pei ($02)
	rep #$20
	lda $57
	and #$00F0
	clc 
	adc $6B
	sec 
	sbc #$C800
	sta $00
	lda !ExLevelScreenSize
	sta $02
	jsl Divide
	lda $02
	sta $98
	pla
	sta $02
	pla 
	sta $00
	sep #$20
	autoclean jsl ReadItemMemory
	ply
	plx
	jmp $A924
	warnpc $0DA924|!long

org $00C00D|!long
	jsl WriteItemMemory
	rts

org $00C020|!long
	dl WriteItemMemory
	dl ReadItemMemory

org $0DA92E|!long
GenerateTile:

org $0DA947|!long
	bpl SingleTile

org $0DA957|!long
	jmp SingleTile

freecode
Divide:
	asl $00
	ldy #$0F
	lda #$0000
-	rol a
	cmp $02
	bcc +
	sbc $02
+	rol $00
	dey
	bpl -
	sta $02
	rtl

; Specialized routine, do not reuse elsewhere
Multiply:
	rep #$20
	ldy $45
	sty $4202
	ldy $47 
	sty $4203
	stz $4B
	ldy $48
	lda $4216
	sty $4203
	sta $49
	lda $4A
	rep #$11
	adc $4216
	ldy $46
	sty $4202
	sep #$10
	clc
	ldy $48
	adc $4216
	sty $4203
	sta $4A
	lda $4B
	clc
	adc $4216
	sta $4B
	sep #$20
	rtl

WriteItemMemory:
	lda !ItemMemoryMask
	bit #$01
	bne +
	phx
	phy
	rep #$20
	jsr GetMemory
	sep #$20
	ora.l !ItemMemory,x
	sta.l !ItemMemory,x
	sep #$10
	ply
	plx
+	rtl

ReadItemMemory:
	lda !ItemMemoryMask
	bit #$02
	bne +
	phx
	phy
	rep #$20
	jsr GetMemory
	sep #$20
	lda.l !ItemMemory,x
	and $49
	sta $0F
	sep #$10
	ply
	plx
+	rtl

; Returns target address in X (16 bit) and bit to set in $49
GetMemory:
	lda $5D
	and #$003F
	asl #4
	sta $45 ; stage width in increments of 16 pixels (e.g. blocks)

	lda $98
	and #$3FF0
	lsr #4
	sta $47 ; y position

	rep #$10
	tsx
	cpx #$2000
	sep #$30
	bcs .sa1

.snes
	jsl Multiply ; result $49 = y position * stage width
	bra +

.sa1
	lda.b #Multiply
	sta $0183
	lda.b #Multiply>>8
	sta $0184
	lda.b #Multiply>>16
	sta $0185
	lda #$D0
	sta $2209
-	lda $018A
	beq -
	stz $018A
+	rep #$30
	lda $13BE|!addr
	and #$0003
	tax ; item memory offset
	lda $9A : and #$3FF0 : lsr #4
	clc
	adc $49
	sta $49 ; id assigned to current location
	lsr #3
	clc
	adc.l .indices,x
	pha ; target address (16 bit)
	sep #$30
	lda $49
	and #$07
	tax
	lda.l .bits,x
	sta $49 ; bit to set in target address
	rep #$10
	plx ; target address (16 bit)
	rts

.indices
    dw $0000, $0700, $0E00, $1500

.bits
    db $01, $02, $04, $08, $10, $20, $40, $80
