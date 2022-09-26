INCLUDE "data/mon_menu.asm"

MonSubmenu:
	xor a
	ldh [hBGMapMode], a
	call GetMonSubmenuItems
	farcall FreezeMonIcons
	ld hl, .MenuHeader
	call LoadMenuHeader
	call .GetTopCoord
	call PopulateMonMenu

	ld a, 1
	ldh [hBGMapMode], a
	call MonMenuLoop
	ld [wMenuSelection], a

	call ExitMenu
	ret

.MenuHeader:
	db MENU_BACKUP_TILES ; flags
	menu_coords 6, 0, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1
	dw 0
	db 1 ; default option

.GetTopCoord:
; [wMenuBorderTopCoord] = 1 + [wMenuBorderBottomCoord] - 2 * ([wMonSubmenuCount] + 1)
	ld a, [wMonSubmenuCount]
	inc a
	add a
	ld b, a
	ld a, [wMenuBorderBottomCoord]
	sub b
	inc a
	ld [wMenuBorderTopCoord], a
	call MenuBox
	ret

MonMenuLoop:
.loop
	ld a, MENU_UNUSED_3 | MENU_BACKUP_TILES_2 ; flags
	ld [wMenuDataFlags], a
	ld a, [wMonSubmenuCount]
	ld [wMenuDataItems], a
	call InitVerticalMenuCursor
	ld hl, w2DMenuFlags1
	set 6, [hl]
	call StaticMenuJoypad
	ld de, SFX_READ_TEXT_2
	call PlaySFX
	ldh a, [hJoyPressed]
	bit A_BUTTON_F, a
	jr nz, .select
	bit B_BUTTON_F, a
	jr nz, .cancel
	jr .loop

.cancel
	ld a, MONMENUITEM_CANCEL
	ret

.select
	ld a, [wMenuCursorY]
	dec a
	ld c, a
	ld b, 0
	ld hl, wMonSubmenuItems
	add hl, bc
	ld a, [hl]
	ret

PopulateMonMenu:
	call MenuBoxCoord2Tile
	ld bc, 2 * SCREEN_WIDTH + 2
	add hl, bc
	ld de, wMonSubmenuItems
.loop
	ld a, [de]
	inc de
	cp -1
	ret z
	push de
	push hl
	call GetMonMenuString
	pop hl
	call PlaceString
	ld bc, 2 * SCREEN_WIDTH
	add hl, bc
	pop de
	jr .loop

GetMonMenuString:
	ld hl, MonMenuOptions + 1
	ld de, 3
	call IsInArray
	dec hl
	ld a, [hli]
	cp MONMENU_MENUOPTION
	jr z, .NotMove
	inc hl
	ld a, [hl]
	ld [wNamedObjectIndex], a
	call GetMoveName
	ret

.NotMove:
	inc hl
	ld a, [hl]
	dec a
	ld hl, MonMenuOptionStrings
	call GetNthString
	ld d, h
	ld e, l
	ret

GetMonSubmenuItems:
	call ResetMonSubmenu
	ld a, [wCurPartySpecies]
	cp EGG
	jr z, .egg
	ld a, [wLinkMode]
	and a
	jr nz, .skip_moves

	call CanUseFlash
	call CanUseFly
	call CanUseDig
	call Can_Use_Sweet_Scent
	call CanUseTeleport
	call CanUseSoftboiled
	call CanUseMilkdrink

.skip_moves
	ld a, MONMENUITEM_STATS
	call AddMonMenuItem
	ld a, MONMENUITEM_SWITCH
	call AddMonMenuItem
	ld a, MONMENUITEM_MOVE
	call AddMonMenuItem
	ld a, [wLinkMode]
	and a
	jr nz, .skip2
	push hl
	ld a, MON_ITEM
	call GetPartyParamLocation
	ld d, [hl]
	farcall ItemIsMail
	pop hl
	ld a, MONMENUITEM_MAIL
	jr c, .ok
	ld a, MONMENUITEM_ITEM

.ok
	call AddMonMenuItem

.skip2
	ld a, [wMonSubmenuCount]
	cp NUM_MONMENU_ITEMS
	jr z, .ok2
	ld a, MONMENUITEM_CANCEL
	call AddMonMenuItem

.ok2
	call TerminateMonSubmenu
	ret

.egg
	ld a, MONMENUITEM_STATS
	call AddMonMenuItem
	ld a, MONMENUITEM_SWITCH
	call AddMonMenuItem
	ld a, MONMENUITEM_CANCEL
	call AddMonMenuItem
	call TerminateMonSubmenu
	ret

ResetMonSubmenu:
	xor a
	ld [wMonSubmenuCount], a
	ld hl, wMonSubmenuItems
	ld bc, NUM_MONMENU_ITEMS + 1
	call ByteFill
	ret

TerminateMonSubmenu:
	ld a, [wMonSubmenuCount]
	ld e, a
	ld d, 0
	ld hl, wMonSubmenuItems
	add hl, de
	ld [hl], -1
	ret

AddMonMenuItem:
	push hl
	push de
	push af
	ld a, [wMonSubmenuCount]
	ld e, a
	inc a
	ld [wMonSubmenuCount], a
	ld d, 0
	ld hl, wMonSubmenuItems
	add hl, de
	pop af
	ld [hl], a
	pop de
	pop hl
	ret

BattleMonMenu:
	ld hl, .MenuHeader
	call CopyMenuHeader
	xor a
	ldh [hBGMapMode], a
	call MenuBox
	call UpdateSprites
	call PlaceVerticalMenuItems
	call WaitBGMap
	call CopyMenuData
	ld a, [wMenuDataFlags]
	bit 7, a
	jr z, .set_carry
	call InitVerticalMenuCursor
	ld hl, w2DMenuFlags1
	set 6, [hl]
	call StaticMenuJoypad
	ld de, SFX_READ_TEXT_2
	call PlaySFX
	ldh a, [hJoyPressed]
	bit B_BUTTON_F, a
	jr z, .clear_carry
	ret z

.set_carry
	scf
	ret

.clear_carry
	and a
	ret

.MenuHeader:
	db 0 ; flags
	menu_coords 11, 11, SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1
	dw .MenuData
	db 1 ; default option

.MenuData:
	db STATICMENU_CURSOR | STATICMENU_NO_TOP_SPACING ; flags
	db 3 ; items
	db "SWITCH@"
	db "STATS@"
	db "CANCEL@"

CanUseFlash:
	ld de, ENGINE_ZEPHYRBADGE
	ld b, CHECK_FLAG
	farcall EngineFlagAction
	ld a, c
	and a
	ret z ; .fail, dont have needed badge
; Flash
	farcall SpecialAerodactylChamber
	jr c, .valid_location ; can use flash
	ld a, [wTimeOfDayPalset]
	cp DARKNESS_PALSET
	ret nz ; .fail ; not a darkcave

.valid_location
	ld a, FLASH
	call CheckMonKnowsMove
	and a
	jr z, .yes

	ld a, HM_FLASH
	ld [wCurItem], a
	ld hl, wNumItems
	call CheckItem
	ret nc ; hm isnt in bag

	ld a, FLASH
	call CheckMonCanLearn_TM_HM_MT
	jr c, .yes

	ld a, FLASH
	call CheckLvlUpMoves
	and a
	ret z ; fail

.yes
	ld a, MONMENUITEM_FLASH
	call AddMonMenuItem
	ret

CanUseFly:
	ld de, ENGINE_STORMBADGE
	ld b, CHECK_FLAG
	farcall EngineFlagAction
	ld a, c
	and a
	ret z ; .fail, dont have needed badge

	call GetMapEnvironment
	call CheckOutdoorMap
	ret nz ; not outdoors, cant fly

	ld a, FLY
	call CheckMonKnowsMove
	and a
	jr z, .yes

	ld a, HM_FLY
	ld [wCurItem], a
	ld hl, wNumItems
	call CheckItem
	ret nc ; .fail, hm isnt in bag

	ld a, FLY
	call CheckMonCanLearn_TM_HM_MT
	jr c, .yes

	ld a, FLY
	call CheckLvlUpMoves
	and a
	ret z ; fail
.yes
	ld a, MONMENUITEM_FLY
	call AddMonMenuItem
	ret

Can_Use_Sweet_Scent:
	farcall CanUseSweetScent
	ret nc ; .no_battle
	farcall GetMapEncounterRate
	ld a, b
	and a
	ret z ; .no_battle

.valid_location
	ld a, SWEET_SCENT
	call CheckMonKnowsMove
	and a
	jr z, .yes

	ld a, TM_SWEET_SCENT
	ld [wCurItem], a
	ld hl, wNumItems
	call CheckItem
	ret nc ; .fail, tm not in bag

	ld a, SWEET_SCENT
	call CheckMonCanLearn_TM_HM_MT
	jr c, .yes

	ld a, SWEET_SCENT
	call CheckLvlUpMoves
	and a
	ret z ; fail
.yes
	ld a, MONMENUITEM_SWEETSCENT
	call AddMonMenuItem
	ret

CanUseDig:
	call GetMapEnvironment
	cp CAVE
	jr z, .valid_location
	cp DUNGEON
	ret nz ; fail, not inside cave or dungeon

.valid_location
	ld a, DIG
	call CheckMonKnowsMove
	and a
	jr z, .yes

	ld a, TM_DIG
	ld [wCurItem], a
	ld hl, wNumItems
	call CheckItem
	ret nc ; .fail ; TM not in bag

	ld a, DIG
	call CheckMonCanLearn_TM_HM_MT
	jr c, .yes

	ld a, DIG
	call CheckLvlUpMoves
	and a
	ret z ; fail
.yes
	ld a, MONMENUITEM_DIG
	call AddMonMenuItem
	ret

CanUseTeleport:
	call GetMapEnvironment
	call CheckOutdoorMap
	ret nz ; .fail	
	
	ld a, TELEPORT
	call CheckMonKnowsMove
	and a
	jr z, .yes

	ld a, TELEPORT
	call CheckLvlUpMoves
	and a
	ret z ; fail
.yes
	ld a, MONMENUITEM_TELEPORT
	call AddMonMenuItem	
	ret

CanUseSoftboiled:
	ld a, SOFTBOILED
	call CheckMonKnowsMove
	and a
	ret nz
	ld a, MONMENUITEM_SOFTBOILED
	call AddMonMenuItem
	ret

CanUseMilkdrink:
	ld a, MILK_DRINK
	call CheckMonKnowsMove
	and a
	ret nz

	ld a, MONMENUITEM_MILKDRINK
	call AddMonMenuItem
	ret

CheckMonCanLearn_TM_HM_MT:
; Check if wCurPartySpecies can learn move in 'a'
	ld [wPutativeTMHMMove], a
	ld a, [wCurPartySpecies]
	farcall CanLearnTMHMMove
.check
	ld a, c
	and a
	ret z ; not found
; yes
	scf
	ret

CheckMonKnowsMove:
	ld b, a
	ld a, MON_MOVES
	call GetPartyParamLocation
	ld d, h
	ld e, l
	ld c, NUM_MOVES
.loop
	ld a, [de]
	and a
	jr z, .next
	cp b
	jr z, .found ; knows move
.next
	inc de
	dec c
	jr nz, .loop
	ld a, -1
	ld c, a
	scf ; mon doesnt know move
	ret
.found
	xor a
	ld c, a
	ret z

CheckLvlUpMoves:
; move looking for in 'd'
	ld a, [wCurPartySpecies]
	dec a
	ld b, 0
	ld c, a
	ld hl, EvosAttacksPointers
	add hl, bc
	add hl, bc
	ld a, BANK(EvosAttacksPointers)
	ld b, a
	call GetFarWord
	ld a, b
	call GetFarByte
	inc hl
	and a
	jr z, .find_move ; does not evolve
	dec hl
; Skip Evo Bytes
; Receives a pointer to the evos and attacks for a mon in b:hl, and skips to the attacks.
.skip_evo_bytes	
	ld a, b
	call GetFarByte
	inc hl
	and a
	jr z, .find_move ; found end
	cp EVOLVE_STAT
	jr nz, .no_extra_skip
	inc hl
.no_extra_skip
	inc hl
	inc hl
	jr .skip_evo_bytes
.find_move
	ld a, BANK(EvosAttacksPointers)
	call GetFarByte
	inc hl
	and a
	jr z, .notfound ; end of mon's lvl up learnset
	ld c, a ; the lvl we learn move
	ld a, BANK(EvosAttacksPointers)
	call GetFarByte
	inc hl
	cp d ; 'd' is not clobbered in any of the used funcs or farcalls
	jr z, .found
	jr .find_move
.found
	; lvl learned move in c
	ret ; move is in lvl up learnset
.notfound
	xor a
	ld c, a
	ret
