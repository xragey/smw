;-------------------------------------------------------------------------------
;
; Roam.asm
; by Ragey <i@ragey.net>
; https://github.com/xragey/smw
;
; Replaces the vanilla game's oam seeking routine. For information and usage
; instructions, review the readme provided in the git repository.
;
;-------------------------------------------------------------------------------

@asar 1.71

!sa1  = 0
!fast = 0
!bank = $00
!addr = $0000
!long = $000000

!Sprite009E = $009E
!Sprite00C2 = $00C2
!Sprite14C8 = $14C8
!Sprite1549 = $1549
!Sprite15EA = $15EA

; ------------------------------------------------------------------------------

; To enable support for custom sprites, change this value to 1. Recommended to
; activate as soon as you've applied a sprite tool, such as Pixi or Giepy.
!cSupportCustomSprites = 0

; To enable support for dynamic cluster sprite oam tile assignment, change this
; value to 1. You should enable this if you can; only disable it if you heavily
; edited the cluster sprite system and rely on static oam assignment for them.
!cClusterSpritesUseAllocator = 1

; 1 byte
; Holds the slot that will be assigned to the next request for one or more oam
; tile(s).
!OamIndex = $0AF5|!addr

; 20 bytes
; Holds the oam slot that was assigned to individual cluster sprites, similar to
; $15EA for regular sprites. Unused if !cClusterSpritesUseAllocator is disabled.
!ClusterOamIndex = $0F5E|!addr

; ------------------------------------------------------------------------------

; Refresh the allocator at the beginning of each frame.
org $00A1DA
	autoclean jml Refresh
	nop

freecode
Refresh:
	lda $1426|!addr
	beq +
	jml $00A1DF|!long
+	ldy #$44
	lda $13F9|!addr
	beq +
	ldy #$24
+	sty !OamIndex
	jml $00A1E4|!long

; Oam assignment algorithm. Uses a lookup table.
org $0180D1
Allocator:
.Return
	rts
.SpriteOam
	lda !Sprite14C8,x
	beq .Return
	lda !OamIndex
	sta !Sprite15EA,x
	autoclean jsl Allocate
	nop #9
.Continue
	warnpc $0180EA

freecode
Allocate:
.SpecialSprites
	lda !Sprite009E,x
	cmp #$35
	beq .Yoshi
	cmp #$87
	bne .DetermineSpriteType
.LakituCloud
	ldy #$00
	lda !Sprite00C2,x
	bne +
	ldy #$34
	lda $13F9|!addr
	beq +
	ldy #$14
	bra +
.Yoshi
	ldy #$3C
	lda $13F9|!addr
	beq +
	ldy #$1C
+	tya
	sta !Sprite15EA,x
	rtl

.DetermineSpriteType
	phx
if !cSupportCustomSprites
{
	lda !Sprite7FAB10,x
	bit #$08
	beq .StandardSprite
.CustomSprite
	lda !Sprite7FAB9E,x
	tax
	lda !OamIndex
	tay
	clc
	adc.l .CustomSpriteTileCount,x
	sta !OamIndex
	plx
	rtl
}
endif
.StandardSprite
	lda !Sprite009E,x
	tax
	lda !OamIndex
	tay
	clc
	adc.l .StandardSpriteTileCount,x
	sta !OamIndex
	plx
	rtl

; Table contains the amount of oam tiles, times 4, used by each standard sprite.
; Unless you've changed how these sprites behave, this table should not need to
; be changed.
.StandardSpriteTileCount
	db $04,$04,$04,$04,$0C,$0C,$0C,$0C ; 00-07
	db $0C,$0C,$0C,$0C,$0C,$0C,$08,$04 ; 08-0F
	db $0C,$04,$00,$04,$10,$04,$04,$00 ; 10-17
	db $04,$00,$08,$04,$04,$04,$08,$00 ; 18-1F
	db $04,$08,$08,$08,$08,$08,$14,$10 ; 20-27
	db $50,$00,$08,$08,$04,$04,$04,$10 ; 28-2F
	db $0C,$04,$0C,$10,$08,$00,$00,$04 ; 30-37
	db $04,$04,$14,$14,$14,$04,$04,$08 ; 38-3F
	db $08,$0C,$0C,$08,$08,$08,$14,$04 ; 40-47
	db $04,$08,$04,$08,$04,$04,$04,$0C ; 48-4F
	db $0C,$04,$10,$24,$00,$14,$14,$14 ; 50-57
	db $00,$14,$14,$0C,$14,$14,$24,$28 ; 58-5F
	db $08,$04,$0C,$14,$24,$0C,$0C,$10 ; 60-67
	db $04,$00,$04,$14,$14,$00,$10,$14 ; 68-6F
	db $14,$0C,$0C,$0C,$04,$04,$04,$04 ; 70-77
	db $04,$04,$D8,$0C,$00,$04,$0C,$0C ; 78-7F
	db $04,$04,$00,$0C,$0C,$00,$18,$00 ; 80-87
	db $00,$00,$04,$08,$04,$28,$00,$10 ; 88-8F
	db $40,$14,$14,$14,$14,$14,$14,$14 ; 90-97
	db $14,$0C,$10,$10,$10,$14,$18,$40 ; 98-9F
	db $00,$40,$14,$18,$10,$04,$14,$00 ; A0-A7
	db $14,$18,$0C,$08,$14,$14,$28,$04 ; A8-AF
	db $04,$04,$04,$08,$10,$00,$04,$0C ; B0-B7
	db $0C,$04,$0C,$10,$0C,$04,$04,$10 ; B8-BF
	db $14,$14,$04,$10,$10,$50,$04,$00 ; C0-C7
	db $04,$00,$00,$00,$00,$00,$00,$00 ; C8-CF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; D0-D7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; D8-DF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; E0-E7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; E8-EF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; F0-F7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; F8-FF

if !cSupportCustomSprites
{
; Table contains the amount of oam tiles, times 4, used by each custom sprite.
; You should update this table as you add custom sprites to your game.
.CustomSpriteTileCount
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 00-07
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 08-0F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 10-17
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 18-1F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 20-27
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 28-2F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 30-37
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 38-3F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 40-47
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 48-4F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 50-57
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 58-5F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 60-67
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 68-6F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 70-77
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 78-7F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 80-87
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 88-8F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 90-97
	db $00,$00,$00,$00,$00,$00,$00,$00 ; 98-9F
	db $00,$00,$00,$00,$00,$00,$00,$00 ; A0-A7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; A8-AF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; B0-B7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; B8-BF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; C0-C7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; C8-CF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; D0-D7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; D8-DF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; E0-E7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; E8-EF
	db $00,$00,$00,$00,$00,$00,$00,$00 ; F0-F7
	db $00,$00,$00,$00,$00,$00,$00,$00 ; F8-FF
}
endif

; Implements a dynamic oam tile assignment scheme for cluster sprites.
if !cClusterSpritesUseAllocator
{
org $02FF50
AllocateClusterSprite:
	ldy !OamIndex
	tya
	sta !ClusterOamIndex,x
	clc
	adc #$04
	sta !OamIndex
	rts

AllocateSumoFire:
	ldy !OamIndex
	tya
	sta !ClusterOamIndex,x
	clc
	adc #$08
	sta !OamIndex
	rts
	warnpc $02FF6C

; Remap sumo brothers' fire pillar cluster sprite.
org $02F940
SumoFire:
	jsr AllocateSumoFire
	sty !Sprite15EA
	nop #3
	warnpc $02F949

; Remap other cluster sprites. Note that the candle flames are intentionally not
; remapped to ensure that they will always use the bottom five slots, just as in
; the vanilla game.
org $02FCCD : lda !ClusterOamIndex,x
org $02FCD9 : ldy !ClusterOamIndex,x
org $02FD4A : jsr AllocateClusterSprite
org $02FD98 : ldy !ClusterOamIndex,x
org $02FE48 : jsr AllocateClusterSprite
}
endif

; Shift Mario's oam slot by 1. This fixes Super Mario's head disappearing while
; carrying certain items, such as MechaKoopas.
org $00E2B2 : db $14,$D4,$14,$E8

; Shift Yoshi's oam slot by 1 while turning around. This fixes Yoshi's head
; disappearing while riding Lakitu's cloud.
org $01EF62 : db $08

; Prevent Lakitu's cloud from using hardcoded slots. This allows us to free 8
; oam slots while Mario is behind the scenery (e.g. climbing nets).
org $01E8DE
	lda !Sprite15EA,x
	sta $18B6|!addr
	sta $0E
	clc
	adc #$04
	sta $0F
	warnpc $01E8EB

; Prevent Lakitu's fishing rod from using hardcoded slots, which messes up the
; allocator.
org $02E6EC
	nop #2
	autoclean jsl AllocateFishingLine
	warnpc $02E6F2

freecode
AllocateFishingLine:
	lda !OamIndex
	clc
	adc #$08
	sta !Sprite15EA,x
	tay
	clc
	adc #$20
	sta !OamIndex
	rtl

; Prevent the swiveling net door from using hardcoded slots, which messes up the
; allocator.
org $01BB33
	lda !Sprite15EA,x
	sta $0F
	warnpc $01BB38
