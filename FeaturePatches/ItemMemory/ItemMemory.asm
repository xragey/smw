;-------------------------------------------------------------------------------
;
; Item Memory
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Replaces the item memory system in Super Mario World with a different system
; that assigns a bit to every individual tile, rather than having tiles share a
; bit for each column per screen. Also implements item memory setting 3. This is
; compatible with recent versions of Lunar Magic that implement ExLevel.
;
; Installing this patch frees 384 bytes of ram at $7E19F8.
; For more information, review the README.
;
;-------------------------------------------------------------------------------

@asar 1.81

assert read1($00FFD5) != $23, "This patch does not support SA-1 images."

if read1($00FFD5)&$10 == $10
	!sa1 = 0
	!fast = 1
else
	!sa1 = 0
	!fast = 0
endif

!bank = select(!fast, $80, $00)
!long = select(!fast, $800000, $000000)
!addr = select(!sa1, $6000, $0000)

;-------------------------------------------------------------------------------

; 1 byte
; Toggles the use of item memory. It's up to you to set and clear it.
; The default address ($0DDB) is cleared on reset only.
; ------r-: Disable reading (everything will always respawn).
; -------w: Disable writing.
!ItemMemoryMask = $0DDB|!addr

; 7168 bytes
; Item memory, divided in four blocks of 1792 bytes per setting.
!ItemMemory = $7F9C7B

;-------------------------------------------------------------------------------

; Loading level code.
org $0096F4|!long
StageLoad:
	jsl ClearItemMemory

; Item memory offsets, for settings 0,1,2,3 respectively.
org $00BFFF
ItemMemoryBlockOffsets:
    dw $0000, $0700, $0E00, $1500

; Write item memory routine. Retains the vanilla location to allow for backward
; compatibility with vanilla and existing custom resources.
org $00C00D
WriteItemMemoryBank0:
	autoclean jsl WriteItemMemory
	rts

; Clear all item memory. This is called from the level loading code (see above).
ClearItemMemory:
	; Check if we're entering from the overworld.
	lda $141A|!addr
	bne +

	; Clear !ItemMemory.
	rep #$30
	lda.w #!ItemMemory
	sta.w $2181
	sep #$20
	lda.b #!ItemMemory>>16
	sta.w $2183
	ldx #$8008
	stx $4300
	ldx #ItemMemoryBlockOffsets
	stx $4302
	lda #ItemMemoryBlockOffsets>>16
	sta $4304
	ldx #$1C00
	stx $4305
	lda #$01
	sta $420B
	sep #$10

+	; Restore overwritten jump position.
	jml $05D796|!long
warnpc $00C063

; WriteItemMemory. Marks a certain coordinate as collected.
; This can be used as a shared routine.
; On entry, $98 should be set to the X position and $9A as the Y position.
freecode
WriteItemMemory:
	lda !ItemMemoryMask
	bit #$01
	bne .Return

	; X = Item memory index
	lda $13BE
	asl
	tax

	; $45 = $13D7 * X position
	rep #$30
	ldy $13D7|!addr
	lda $9A
	lsr #4
	pha
	lsr #4
	cmp $13D7|!addr
	bcs +
	tay
	lda $13D7|!addr
+	sep #$30
	sta $211B
	xba
	sta $211B
	sty $211C
	rep #$20
	lda $2134
	sta $45

	; $47 = Y positon * 16
	lda $98
	and #$3FF0
	sta $47

	; A = Absolute offset
	pla
	and #$000F
	clc
	adc $45
	clc
	adc $47
	clc
	adc.l ItemMemoryBlockOffsets,x

	; X = Address offset
	; A = Bit to set in address
	rep #$10
	sta $45
	lsr #3
	tax
	phx
	lda $45
	and #$0007
	tax
	sep #$20
	lda.l $00C0AA|!bank,x
	plx
	ora.l !ItemMemory,x
	sta.l !ItemMemory,x
	sep #$10

.Return
	rtl

; ReadItemMemory. Checks if the current block coordinate is marked as collected.
; This can be used as a shared (object generation) routine.
; On entry, $6B+Y should be set to the current block linear index. For pretty
; much all object generation routines, this is already set correctly. Returns
; A=$00 if the flag is not set or any other value if it's set.
ReadItemMemory:
	lda !ItemMemoryMask
	bit #$02
	beq +
	lda #$00
	rtl

+	; A = $45 = Absolute offset
	lda $13BE
	asl
	tax
	rep #$30
	lda $6B
	sec
	sbc #$C800
	clc
	adc.l ItemMemoryBlockOffsets,x
	sta $45
	tya
	clc
	adc $45
	sta $45

	; X = Address offset
	; A = Bit to read in address
	lsr #3
	tax
	phx
	lda $45
	and #$0007
	sep #$20
	tax
	lda.l $00C0AA|!bank,x
	plx
	and.l !ItemMemory,x
	sep #$10

.Return
	rtl

; Object creation routine for standard objects $01-$0E and tileset object $31.
; Of these, object $05 (regular coin) uses item memory by default.
; (POINT OF ADVICE: There is leftover space here for you to add checks to have
; some of the others use item memory as well!)
org $0DA8D8
Object01:
	cpx #$04
	beq +
	jmp $A92E
+	phx
	jsl ReadItemMemory
	beq +
	plx
	jmp $A928
+	plx
	jmp $A92E
warnpc $0DA92B

; Object creation routine for extended objects $10-$40. Some of these use item
; memory by default.
org $0DA5F0
ExObject10:
	phx
	jsl ReadItemMemory
	beq +
	plx
	jmp $A63D
+	plx
	jmp $A648
warnpc $0DA63C

; Object creation routine for extended object $41 (Yoshi coin).
org $0DB2E0
ExObject41:
	ldy $57
	jsl ReadItemMemory
	bne +
	jmp $B322
+	rts
warnpc $0DB321
