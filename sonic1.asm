;  =========================================================================
; |           Sonic the Hedgehog Disassembly for Sega Mega Drive            |
;  =========================================================================
;
; Disassembly created by Hivebrain
; thanks to drx, Stealth and Esrael L.G. Neto
;
; Further modified by Selbi with help from RobiWanKenobi

; ===========================================================================

; vladikcomper's debugger
;   Omitting this line will save on some space and is recommended for releases.
;   But if you start using some of the advanced debugger features, like assertions and KDebug interface,
;   these features will be compiled and enabled only in DEBUG builds to avoid performance penalties when not debugging.
;__DEBUG__:	equ 1

; Enable all cheats by default (for development convenience)
;   Level Select, Debug Mode, SlowMo Cheat, Hidden Japanese Credits
;CheatsDefault:	equ 1

; ===========================================================================

	include	"_Constants.asm"
	include	"_Variables.asm"
	include	"_Macros.asm"
	include	"_debug/_Debugger.asm"

; ===========================================================================

StartOfRom:
Vectors:
		dc.l v_systemstack&$FFFFFF	; Initial stack pointer value
		dc.l EntryPoint			; Start of program
		dc.l BusError			; Bus error
		dc.l AddressError		; Address error (4)
		dc.l IllegalInstr		; Illegal instruction
		dc.l ZeroDivide			; Division by zero
		dc.l ChkInstr			; CHK exception
		dc.l TrapvInstr			; TRAPV exception (8)
		dc.l PrivilegeViol		; Privilege violation
		dc.l Trace			; TRACE exception
		dc.l Line1010Emu		; Line-A emulator
		dc.l Line1111Emu		; Line-F emulator (12)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (16)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (20)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved)
		dc.l ErrorExcept		; Unused (reserved) (24)
		dc.l ErrorExcept		; Spurious exception
		dc.l ErrorTrap			; IRQ level 1
		dc.l ErrorTrap			; IRQ level 2
		dc.l ErrorTrap			; IRQ level 3 (28)
		dc.l HBlank			; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorTrap			; IRQ level 5
		dc.l VBlank			; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorTrap			; IRQ level 7 (32)
		dc.l ErrorTrap			; TRAP #00 exception
		dc.l ErrorTrap			; TRAP #01 exception
		dc.l ErrorTrap			; TRAP #02 exception
		dc.l ErrorTrap			; TRAP #03 exception (36)
		dc.l ErrorTrap			; TRAP #04 exception
		dc.l ErrorTrap			; TRAP #05 exception
		dc.l ErrorTrap			; TRAP #06 exception
		dc.l ErrorTrap			; TRAP #07 exception (40)
		dc.l ErrorTrap			; TRAP #08 exception
		dc.l ErrorTrap			; TRAP #09 exception
		dc.l ErrorTrap			; TRAP #10 exception
		dc.l ErrorTrap			; TRAP #11 exception (44)
		dc.l ErrorTrap			; TRAP #12 exception
		dc.l ErrorTrap			; TRAP #13 exception
		dc.l ErrorTrap			; TRAP #14 exception
		dc.l ErrorTrap			; TRAP #15 exception (48)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)

		dc.b "SEGA MEGA DRIVE " ; Hardware system ID (Console name)
		dc.b "(C)SEGA 1991.APR" ; Copyright holder and release date (generally year)
		dc.b "SONIC THE               HEDGEHOG                " ; Domestic name
		dc.b "SONIC THE               HEDGEHOG                " ; International name
		dc.b "GM 00004049-01" ; Serial/version number (Rev 01)

Checksum:	dc.w 0			; Selbi: redudant as the checksum check has been removed
		dc.b "J               " ; I/O support
		dc.l StartOfRom		; Start address of ROM
RomEndLoc:	dc.l EndOfRom-1		; End address of ROM
		dc.l $FF0000		; Start address of RAM
		dc.l $FFFFFF		; End address of RAM
SRAMSupport:	dc.l $20202020		; change to $5241F820 to create	SRAM
		dc.l $20202020		; SRAM start ($200001)
		dc.l $20202020		; SRAM end ($20xxxx)
		dc.b "                                                    " ; Notes (unused, anything can be put in this space, but it has to be 52 bytes.)
		dc.b "JUE             " ; Region (Country code)
EndOfHeader:

; ===========================================================================
; Crash/Freeze the 68000. Unlike Sonic 2, Sonic 1 uses the 68000 for playing music, so it stops too

ErrorTrap:
		nop
		nop
		bra.s	ErrorTrap
; ===========================================================================

EntryPoint:
		tst.l	(z80_port_1_control).l ; test port A & B control registers
		bne.s	PortA_Ok
		tst.w	(z80_expansion_control).l ; test port C control register

PortA_Ok:
		bne.s	SkipSetup ; Skip the VDP and Z80 setup code if port A, B or C is ok...?
		lea	SetupValues(pc),a5	; Load setup values array address.
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	-$10FF(a1),d0	; get hardware version (from $A10001)
		andi.b	#$F,d0
		beq.s	SkipSecurity	; If the console has no TMSS, skip the security stuff.
		move.l	#'SEGA',$2F00(a1) ; move "SEGA" to TMSS register ($A14000)

SkipSecurity:
		move.w	(a4),d0	; clear write-pending flag in VDP to prevent issues if the 68k has been reset in the middle of writing a command long word to the VDP.
		moveq	#0,d0	; clear d0
		movea.l	d0,a6	; clear a6
		move.l	a6,usp	; set usp to $0

		moveq	#$17,d1
VDPInitLoop:
		move.b	(a5)+,d5	; add $8000 to value
		move.w	d5,(a4)		; move value to VDP register
		add.w	d7,d5		; next register
		dbf	d1,VDPInitLoop

		move.l	(a5)+,(a4)
		move.w	d0,(a3)		; clear the VRAM
		move.w	d7,(a1)		; stop the Z80
		move.w	d7,(a2)		; reset the Z80

WaitForZ80:
		btst	d0,(a1)		; has the Z80 stopped?
		bne.s	WaitForZ80	; if not, branch

		moveq	#$25,d2
Z80InitLoop:
		move.b	(a5)+,(a0)+
		dbf	d2,Z80InitLoop

		move.w	d0,(a2)
		move.w	d0,(a1)		; start the Z80
		move.w	d7,(a2)		; reset the Z80

ClrRAMLoop:
		move.l	d0,-(a6)	; clear 4 bytes of RAM
		dbf	d6,ClrRAMLoop	; repeat until the entire RAM is clear
		move.l	(a5)+,(a4)	; set VDP display mode and increment mode
		move.l	(a5)+,(a4)	; set VDP to CRAM write

		moveq	#$1F,d3	; set repeat times
ClrCRAMLoop:
		move.l	d0,(a3)	; clear 2 palettes
		dbf	d3,ClrCRAMLoop	; repeat until the entire CRAM is clear
		move.l	(a5)+,(a4)	; set VDP to VSRAM write

		moveq	#$13,d4
ClrVSRAMLoop:
		move.l	d0,(a3)	; clear 4 bytes of VSRAM.
		dbf	d4,ClrVSRAMLoop	; repeat until the entire VSRAM is clear
		moveq	#3,d5

PSGInitLoop:
		move.b	(a5)+,$11(a3)	; reset the PSG
		dbf	d5,PSGInitLoop	; repeat for other channels
		move.w	d0,(a2)
		movem.l	(a6),d0-a6	; clear all registers
		disable_ints

SkipSetup:
		bra.s	GameProgram	; begin game

; ===========================================================================
SetupValues:	dc.w $8000		; VDP register start number
		dc.w $3FFF		; size of RAM/4
		dc.w $100		; VDP register diff

		dc.l z80_ram		; start of Z80 RAM
		dc.l z80_bus_request	; Z80 bus request
		dc.l z80_reset		; Z80 reset
		dc.l vdp_data_port	; VDP data
		dc.l vdp_control_port	; VDP control

		dc.b 4			; VDP $80 - 8-colour mode
		dc.b $14		; VDP $81 - Megadrive mode, DMA enable
		dc.b ($C000>>10)	; VDP $82 - foreground nametable address
		dc.b ($F000>>10)	; VDP $83 - window nametable address
		dc.b ($E000>>13)	; VDP $84 - background nametable address
		dc.b ($D800>>9)		; VDP $85 - sprite table address
		dc.b 0			; VDP $86 - unused
		dc.b 0			; VDP $87 - background colour
		dc.b 0			; VDP $88 - unused
		dc.b 0			; VDP $89 - unused
		dc.b 255		; VDP $8A - HBlank register
		dc.b 0			; VDP $8B - full screen scroll
		dc.b $81		; VDP $8C - 40 cell display
		dc.b ($DC00>>10)	; VDP $8D - hscroll table address
		dc.b 0			; VDP $8E - unused
		dc.b 1			; VDP $8F - VDP increment
		dc.b 1			; VDP $90 - 64 cell hscroll size
		dc.b 0			; VDP $91 - window h position
		dc.b 0			; VDP $92 - window v position
		dc.w $FFFF		; VDP $93/94 - DMA length
		dc.w 0			; VDP $95/96 - DMA source
		dc.b $80		; VDP $97 - DMA fill VRAM
		dc.l $40000080		; VRAM address 0
; RobiWanKenobi: this is Z80 code, hence this being a blob of hex
		dc.b $AF		; xor a
		dc.b $01, $D9, $1F	; ld bc,1fd9h
		dc.b $11, $27, $00	; ld de,0027h
		dc.b $21, $26, $00	; ld hl,0026h
		dc.b $F9		; ld sp,hl
		dc.b $77		; ld (hl),a
		dc.b $ED, $B0		; ldir
		dc.b $DD, $E1		; pop ix
		dc.b $FD, $E1		; pop iy
		dc.b $ED, $47		; ld i,a
		dc.b $ED, $4F		; ld r,a
		dc.b $D1		; pop de
		dc.b $E1		; pop hl
		dc.b $F1		; pop af
		dc.b $08		; ex af,af'
		dc.b $D9		; exx
		dc.b $C1		; pop bc
		dc.b $D1		; pop de
		dc.b $E1		; pop hl
		dc.b $F1		; pop af
		dc.b $F9		; ld sp,hl
		dc.b $F3		; di
		dc.b $ED, $56		; im1
		dc.b $36, $E9		; ld (hl),e9h
		dc.b $E9		; jp (hl)

		dc.w $8104		; VDP display mode
		dc.w $8F02		; VDP increment
		dc.l $C0000000		; CRAM write mode
		dc.l $40000010		; VSRAM address 0

		dc.b $9F, $BF, $DF, $FF	; values for PSG channel volumes
; ===========================================================================

GameProgram:
		tst.w	(vdp_control_port).l
		btst	#6,($A1000D).l
		beq.s	CheckSumCheck
		cmpi.l	#'init',(v_init).w ; has checksum routine already run?
		beq.w	GameInit	; if yes, branch

CheckSumCheck:
; Selbi: checksum check removed

	CheckSumOk:
		lea	(v_systemstack).w,a6
		moveq	#0,d7
		move.w	#$7F,d6
	@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM	; clear RAM ($FE00-$FFFF)

		move.b	(z80_version).l,d0
		andi.b	#$C0,d0
		move.b	d0,(v_megadrive).w ; get region setting
		move.l	#'init',(v_init).w ; set flag so checksum won't run again

GameInit:
		lea	(v_256x256).l,a6
		moveq	#0,d7
		move.w	#$3F7F,d6
	@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM ; clear RAM ($0000-$FDFF)

	if def(CheatsDefault)
		move.b	#1,(f_debugmode).w
		move.b	#1,(f_levselcheat).w
		move.b	#1,(f_slomocheat).w
		move.b	#1,(f_creditscheat).w
	endif

		bsr.w	VDPSetupGame
		bsr.w	JoypadInit
		move.b	#id_Sega,(v_gamemode).w ; set Game Mode to Sega Screen
		jsr     MegaPCM_LoadDriver
	        lea     SampleTable, a0
	        jsr     MegaPCM_LoadSampleTable
		tst.w   d0		; was sample table loaded successfully?
		beq.s   MainGameLoop	; if yes, sample table is okay, branch
	if def(__DEBUG__)
		RaiseError "MegaPCM_LoadSampleTable returned %<.b d0>", MPCM_Debugger_LoadSampleTableException
	else
		illegal
	endif
; ---------------------------------------------------------------------------

MainGameLoop:
		move.b	(v_gamemode).w,d0 ; load Game Mode
		andi.w	#$1C,d0	; limit Game Mode value to $1C max (change to a maximum of 7C to add more game modes)
		jsr	GameModeArray(pc,d0.w) ; jump to apt location in ROM
		bra.s	MainGameLoop	; loop indefinitely
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------

GameModeArray:

ptr_GM_Sega:	bra.w	GM_Sega		; Sega Screen ($00)
ptr_GM_Title:	bra.w	GM_Title	; Title Screen ($04)
ptr_GM_Demo:	bra.w	GM_Level	; Demo Mode ($08)
ptr_GM_Level:	bra.w	GM_Level	; Normal Level ($0C)
ptr_GM_Special:	bra.w	GM_Special	; Special Stage ($10)
ptr_GM_Cont:	bra.w	GM_Continue	; Continue Screen ($14)
ptr_GM_Ending:	bra.w	GM_Ending	; End of game sequence ($18)
ptr_GM_Credits:	bra.w	GM_Credits	; Credits ($1C)

		rts
;Sonic 1's error handler was here, but we have vladik's in now
; ===========================================================================

Art_Text:	incbin	"artunc\menutext.bin" ; text used in level select, the error handler, and debug mode
		even

; ===========================================================================
; ---------------------------------------------------------------------------
; Vertical interrupt
; ---------------------------------------------------------------------------

; loc_B10:
VBlank:
		movem.l	d0-a6,-(sp)
		tst.b	(v_vbla_routine).w
		beq.s	VBla_00
		move.w	(vdp_control_port).l,d0
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_vdp).w,(vdp_data_port).l ; send screen y-axis pos. to VSRAM
		btst	#6,(v_megadrive).w ; is Megadrive PAL?
		beq.s	@notPAL		; if not, branch

		move.w	#$700,d0
	@waitPAL:
		dbf	d0,@waitPAL ; wait here in a loop doing nothing for a while...

	@notPAL:
		move.b	(v_vbla_routine).w,d0
		move.b	#0,(v_vbla_routine).w
		move.w	#1,(f_hbla_pal).w
		andi.w	#$3E,d0
		move.w	VBla_Index(pc,d0.w),d0
		jsr	VBla_Index(pc,d0.w)

VBla_Music:
		jsr	(UpdateMusic).l

VBla_Exit:
		addq.l	#1,(v_vbla_count).w
		movem.l	(sp)+,d0-a6
		rte
; ===========================================================================
VBla_Index:	dc.w VBla_00-VBla_Index, VBla_02-VBla_Index
		dc.w VBla_04-VBla_Index, VBla_06-VBla_Index
		dc.w VBla_08-VBla_Index, VBla_0A-VBla_Index
		dc.w VBla_0C-VBla_Index, VBla_0E-VBla_Index
		dc.w VBla_10-VBla_Index, VBla_12-VBla_Index
		dc.w VBla_14-VBla_Index, VBla_16-VBla_Index
		dc.w VBla_0C-VBla_Index
; ===========================================================================

VBla_00:
		cmpi.b	#$80+id_Level,(v_gamemode).w
		beq.s	@islevel
		cmpi.b	#id_Level,(v_gamemode).w ; is game on a level?
		bne.w	VBla_Music	; if not, branch

	@islevel:
		cmpi.b	#id_LZ,(v_zone).w ; is level LZ ?
		bne.w	VBla_Music	; if not, branch

		move.w	(vdp_control_port).l,d0
		btst	#6,(v_megadrive).w ; is Megadrive PAL?
		beq.s	@notPAL		; if not, branch

		move.w	#$700,d0
	@waitPAL:
		dbf	d0,@waitPAL

	@notPAL:
		move.w	#1,(f_hbla_pal).w ; set HBlank flag


		tst.b	(f_wtr_state).w	; is water above top of screen?
		bne.s	@waterabove 	; if yes, branch

		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		move.w	(v_hbla_hreg).w,(a5)

		bra.w	VBla_Music
; ===========================================================================

VBla_02:
		bsr.w	sub_106E

VBla_14:
		tst.w	(v_demolength).w
		beq.w	@end
		subq.w	#1,(v_demolength).w

	@end:
		rts
; ===========================================================================

VBla_04:
		bsr.w	sub_106E
		bsr.w	LoadTilesAsYouMove_BGOnly
		bsr.w	sub_1642
		tst.w	(v_demolength).w
		beq.w	@end
		subq.w	#1,(v_demolength).w

	@end:
		rts
; ===========================================================================

VBla_06:
		bsr.w	sub_106E
		rts
; ===========================================================================

VBla_10:
		cmpi.b	#id_Special,(v_gamemode).w ; is game on special stage?
		beq.w	VBla_0A		; if yes, branch

VBla_08:


		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w
		bne.s	@waterabove

		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		move.w	(v_hbla_hreg).w,(a5)

		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		tst.b	(f_sonframechg).w ; has Sonic's sprite changed?
		beq.s	@nochg		; if not, branch

		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w

	@nochg:

		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,(v_screenposx_dup).w
		movem.l	(v_fg_scroll_flags).w,d0-d1
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w
		cmpi.b	#96,(v_hbla_line).w
		bhs.s	Demo_Time
		move.b	#1,(f_doupdatesinhblank).w
		addq.l	#4,sp
		bra.w	VBla_Exit

; ---------------------------------------------------------------------------
; Subroutine to run a demo for an amount of time
; ---------------------------------------------------------------------------

Demo_Time:
		bsr.w	LoadTilesAsYouMove
		jsr	(AnimateLevelGfx).l
		jsr	(HUD_Update).l
		bsr.w	ProcessDPLC2
		tst.w	(v_demolength).w ; is there time left on the demo?
		beq.w	@end		; if not, branch
		subq.w	#1,(v_demolength).w ; subtract 1 from time left

	@end:
		rts
; End of function Demo_Time

; ===========================================================================

VBla_0A:


		bsr.w	ReadJoypads
		writeCRAM	v_pal_dry,$80,0
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll

		bsr.w	PalCycle_SS
		tst.b	(f_sonframechg).w ; has Sonic's sprite changed?
		beq.s	@nochg		; if not, branch

		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w

	@nochg:
		tst.w	(v_demolength).w	; is there time left on the demo?
		beq.w	@end	; if not, return
		subq.w	#1,(v_demolength).w	; subtract 1 from time left in demo

	@end:
		rts
; ===========================================================================

VBla_0C:


		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w
		bne.s	@waterabove

		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		move.w	(v_hbla_hreg).w,(a5)
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		tst.b	(f_sonframechg).w
		beq.s	@nochg
		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic
		move.b	#0,(f_sonframechg).w

	@nochg:

		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,(v_screenposx_dup).w
		movem.l	(v_fg_scroll_flags).w,d0-d1
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w
		bsr.w	LoadTilesAsYouMove
		jsr	(AnimateLevelGfx).l
		jsr	(HUD_Update).l
		bsr.w	sub_1642
		rts
; ===========================================================================

VBla_0E:
		bsr.w	sub_106E
		addq.b	#1,(v_vbla_0e_counter).w
		move.b	#$E,(v_vbla_routine).w
		rts
; ===========================================================================

VBla_12:
		bsr.w	sub_106E
		move.w	(v_hbla_hreg).w,(a5)
		bra.w	sub_1642
; ===========================================================================

VBla_16:


		bsr.w	ReadJoypads
		writeCRAM	v_pal_dry,$80,0
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll

		tst.b	(f_sonframechg).w
		beq.s	@nochg
		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic
		move.b	#0,(f_sonframechg).w

	@nochg:
		tst.w	(v_demolength).w
		beq.w	@end
		subq.w	#1,(v_demolength).w

	@end:
		rts

sub_106E:


		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w ; is water above top of screen?
		bne.s	@waterabove	; if yes, branch
		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

	@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll

		rts
; End of function sub_106E

; ---------------------------------------------------------------------------
; Horizontal interrupt
; ---------------------------------------------------------------------------

; PalToCRAM: <-- horrible misnomer btw
HBlank:
		disable_ints
		tst.w	(f_hbla_pal).w	; is palette set to change? (used for LZ water)
		beq.s	@nochg		; if not, branch
		move.w	#0,(f_hbla_pal).w
		movem.l	a0-a1,-(sp)
		lea	(vdp_data_port).l,a1
		lea	(v_pal_water).w,a0 ; get palette from RAM
		move.l	#$C0000000,4(a1) ; set VDP to CRAM write
		move.l	(a0)+,(a1)	; move palette to CRAM
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.w	#$8A00+223,4(a1) ; reset HBlank register
		movem.l	(sp)+,a0-a1
		tst.b	(f_doupdatesinhblank).w
		bne.s	loc_119E

	@nochg:
		rte
; ===========================================================================

loc_119E:
		clr.b	(f_doupdatesinhblank).w
		movem.l	d0-a6,-(sp)
		bsr.w	Demo_Time
		jsr	(UpdateMusic).l
		movem.l	(sp)+,d0-a6
		rte
; End of function HBlank

; ---------------------------------------------------------------------------
; Subroutine to initialise joypads
; ---------------------------------------------------------------------------

JoypadInit:
		moveq	#$40,d0
		move.b	d0,(z80_port_1_control+1).l	; init port 1 (joypad 1)
		move.b	d0,(z80_port_2_control+1).l	; init port 2 (joypad 2)
		move.b	d0,(z80_expansion_control+1).l	; init port 3 (expansion/extra)
		rts
; End of function JoypadInit

; ---------------------------------------------------------------------------
; Subroutine to	read joypad input, and send it to the RAM
; ---------------------------------------------------------------------------

ReadJoypads:
		lea	(v_jpadhold1).w,a0 ; address where joypad states are written
		lea	(z80_port_1_data+1).l,a1	; first	joypad port
		bsr.s	@read		; do the first joypad
		addq.w	#2,a1		; do the second	joypad

	@read:
		move.b	#0,(a1)
		nop
		nop
		move.b	(a1),d0
		lsl.b	#2,d0
		andi.b	#$C0,d0
		move.b	#$40,(a1)
		nop
		nop
		move.b	(a1),d1
		andi.b	#$3F,d1
		or.b	d1,d0
		not.b	d0
		move.b	(a0),d1
		eor.b	d0,d1
		move.b	d0,(a0)+
		and.b	d0,d1
		move.b	d1,(a0)+
		rts
; End of function ReadJoypads

VDPSetupGame:
		lea	(vdp_control_port).l,a0
		lea	(vdp_data_port).l,a1
		lea	(VDPSetupArray).l,a2
		moveq	#$12,d7

	@setreg:
		move.w	(a2)+,(a0)
		dbf	d7,@setreg	; set the VDP registers

		move.w	(VDPSetupArray+2).l,d0
		move.w	d0,(v_vdp_buffer1).w
		move.w	#$8A00+223,(v_hbla_hreg).w	; H-INT every 224th scanline
		moveq	#0,d0
		move.l	#$C0000000,(vdp_control_port).l ; set VDP to CRAM write
		move.w	#$3F,d7

	@clrCRAM:
		move.w	d0,(a1)
		dbf	d7,@clrCRAM	; clear the CRAM

		clr.l	(v_scrposy_vdp).w
		clr.l	(v_scrposx_vdp).w
		move.l	d1,-(sp)
		fillVRAM	0,$FFFF,0

	@waitforDMA:
		move.w	(a5),d1
		btst	#1,d1		; is DMA (fillVRAM) still running?
		bne.s	@waitforDMA	; if yes, branch

		move.w	#$8F02,(a5)	; set VDP increment size
		move.l	(sp)+,d1
		rts
; End of function VDPSetupGame

; ===========================================================================
VDPSetupArray:	dc.w $8004		; 8-colour mode
		dc.w $8134		; enable V.interrupts, enable DMA
		dc.w $8200+(vram_fg>>10) ; set foreground nametable address
		dc.w $8300+($A000>>10)	; set window nametable address
		dc.w $8400+(vram_bg>>13) ; set background nametable address
		dc.w $8500+(vram_sprites>>9) ; set sprite table address
		dc.w $8600		; unused
		dc.w $8700		; set background colour (palette entry 0)
		dc.w $8800		; unused
		dc.w $8900		; unused
		dc.w $8A00		; default H.interrupt register
		dc.w $8B00		; full-screen vertical scrolling
		dc.w $8C81		; 40-cell display mode
		dc.w $8D00+(vram_hscroll>>10) ; set background hscroll address
		dc.w $8E00		; unused
		dc.w $8F02		; set VDP increment size
		dc.w $9001		; 64-cell hscroll size
		dc.w $9100		; window horizontal position
		dc.w $9200		; window vertical position

; ---------------------------------------------------------------------------
; Subroutine to clear the screen
; ---------------------------------------------------------------------------

ClearScreen:
		fillVRAM	0,$FFF,vram_fg ; clear foreground namespace

	@wait1:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	@wait1

		move.w	#$8F02,(a5)
		fillVRAM	0,$FFF,vram_bg ; clear background namespace

	@wait2:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	@wait2

		move.w	#$8F02,(a5)
		clr.l	(v_scrposy_vdp).w
		clr.l	(v_scrposx_vdp).w

		lea	(v_spritetablebuffer).w,a1
		moveq	#0,d0
		move.w	#($280/4)-1,d1

	@clearsprites:
		move.l	d0,(a1)+
		dbf	d1,@clearsprites ; clear sprite table (in RAM)

		lea	(v_hscrolltablebuffer).w,a1
		moveq	#0,d0
		move.w	#($400/4)-1,d1

	@clearhscroll:
		move.l	d0,(a1)+
		dbf	d1,@clearhscroll ; clear hscroll table (in RAM)
		rts
; End of function ClearScreen
; ---------------------------------------------------------------------------
; Subroutine to play a music track

; input:
; d0 = track to play
; ---------------------------------------------------------------------------

PlaySound:
		move.b	d0,(v_snddriver_ram+v_soundqueue0).w
		rts
; End of function PlaySound

; ---------------------------------------------------------------------------
; Subroutine to play a sound effect
; ---------------------------------------------------------------------------

PlaySound_Special:
		move.b	d0,(v_snddriver_ram+v_soundqueue1).w
		rts
; End of function PlaySound_Special

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to pause the game
; ---------------------------------------------------------------------------

PauseGame:
		tst.b	(v_lives).w	; do you have any lives left?
		beq.s	Unpause		; if not, branch
		tst.w	(f_pause).w	; is game already paused?
		bne.s	Pause_StopGame	; if yes, branch
		btst	#bitStart,(v_jpadpress1).w ; is Start button pressed?
		beq.s	Pause_DoNothing	; if not, branch

Pause_StopGame:
		move.w	#1,(f_pause).w	; freeze time
		move.b	#1,(v_snddriver_ram+f_pausemusic).w ; pause music

Pause_Loop:
		move.b	#$10,(v_vbla_routine).w
		bsr.w	WaitForVBla
		tst.b	(f_slomocheat).w ; is slow-motion cheat on?
		beq.s	Pause_ChkStart	; if not, branch
		btst	#bitA,(v_jpadpress1).w ; is button A pressed?
		beq.s	Pause_ChkBC	; if not, branch
		move.b	#id_Title,(v_gamemode).w ; set game mode to 4 (title screen)
		nop
		bra.s	Pause_EndMusic
; ===========================================================================

Pause_ChkBC:
		btst	#bitB,(v_jpadhold1).w ; is button B pressed?
		bne.s	Pause_SlowMo	; if yes, branch
		btst	#bitC,(v_jpadpress1).w ; is button C pressed?
		bne.s	Pause_SlowMo	; if yes, branch

Pause_ChkStart:
		btst	#bitStart,(v_jpadpress1).w ; is Start button pressed?
		beq.s	Pause_Loop	; if not, branch

Pause_EndMusic:
		move.b	#$80,(v_snddriver_ram+f_pausemusic).w	; unpause the music

Unpause:
		move.w	#0,(f_pause).w	; unpause the game

Pause_DoNothing:
		rts
; ===========================================================================

Pause_SlowMo:
		move.w	#1,(f_pause).w
		move.b	#$80,(v_snddriver_ram+f_pausemusic).w	; Unpause the music
		rts
; End of function PauseGame

; ---------------------------------------------------------------------------
; Subroutine to copy a tile map from RAM to VRAM namespace

; input:
; a1 = tile map address
; d0 = VRAM address
; d1 = width (cells)
; d2 = height (cells)
; ---------------------------------------------------------------------------

TilemapToVRAM:
		lea	(vdp_data_port).l,a6
		move.l	#$800000,d4

	Tilemap_Line:
		move.l	d0,4(a6)	; move d0 to VDP_control_port
		move.w	d1,d3

	Tilemap_Cell:
		move.w	(a1)+,(a6)	; write value to namespace
		dbf	d3,Tilemap_Cell	; next tile
		add.l	d4,d0		; goto next line
		dbf	d2,Tilemap_Line	; next line
		rts
; End of function TilemapToVRAM

; ---------------------------------------------------------------------------
; Nemesis decompression subroutine, decompresses art directly to VRAM
; Inputs:
; a0 = art address

; For format explanation see http://info.sonicretro.org/Nemesis_compression
; ---------------------------------------------------------------------------

; Nemesis decompression to VRAM
NemDec:
		movem.l	d0-a1/a3-a5,-(sp)
		lea	(NemPCD_WriteRowToVDP).l,a3	; write all data to the same location
		lea	(vdp_data_port).l,a4	; specifically, to the VDP data port
		bra.s	NemDecMain

; Nemesis decompression subroutine, decompresses art to RAM
; Inputs:
; a0 = art address
; a4 = destination RAM address
NemDecToRAM:
		movem.l	d0-a1/a3-a5,-(sp)
		lea	(NemPCD_WriteRowToRAM).l,a3 ; advance to the next location after each write

NemDecMain:
		lea	(v_ngfx_buffer).w,a1
		move.w	(a0)+,d2	; get number of patterns
		lsl.w	#1,d2
		bhs.s	loc_146A	; branch if the sign bit isn't set
		adda.w	#NemPCD_WriteRowToVDP_XOR-NemPCD_WriteRowToVDP,a3	; otherwise the file uses XOR mode

loc_146A:
		lsl.w	#2,d2	; get number of 8-pixel rows in the uncompressed data
		movea.w	d2,a5	; and store it in a5 because there aren't any spare data registers
		moveq	#8,d3	; 8 pixels in a pattern row
		moveq	#0,d2
		moveq	#0,d4
		bsr.w	NemDec_BuildCodeTable
		move.b	(a0)+,d5	; get first byte of compressed data
		asl.w	#8,d5	; shift up by a byte
		move.b	(a0)+,d5	; get second byte of compressed data
		move.w	#$10,d6	; set initial shift value
		bsr.s	NemDec_ProcessCompressedData
		movem.l	(sp)+,d0-a1/a3-a5
		rts
; End of function NemDec

; ---------------------------------------------------------------------------
; Part of the Nemesis decompressor, processes the actual compressed data
; ---------------------------------------------------------------------------

NemDec_ProcessCompressedData:
		move.w	d6,d7
		subq.w	#8,d7	; get shift value
		move.w	d5,d1
		lsr.w	d7,d1	; shift so that high bit of the code is in bit position 7
		cmpi.b	#%11111100,d1	; are the high 6 bits set?
		bhs.s	NemPCD_InlineData	; if they are, it signifies inline data
		andi.w	#$FF,d1
		add.w	d1,d1
		move.b	(a1,d1.w),d0	; get the length of the code in bits
		ext.w	d0
		sub.w	d0,d6	; subtract from shift value so that the next code is read next time around
		cmpi.w	#9,d6	; does a new byte need to be read?
		bhs.s	loc_14B2	; if not, branch
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5	; read next byte

loc_14B2:
		move.b	1(a1,d1.w),d1
		move.w	d1,d0
		andi.w	#$F,d1	; get palette index for pixel
		andi.w	#$F0,d0

NemPCD_ProcessCompressedData:
		lsr.w	#4,d0	; get repeat count

NemPCD_WritePixel:
		lsl.l	#4,d4	; shift up by a nybble
		or.b	d1,d4	; write pixel
		subq.w	#1,d3	; has an entire 8-pixel row been written?
		bne.s	NemPCD_WritePixel_Loop	; if not, loop
		jmp	(a3)	; otherwise, write the row to its destination, by doing a dynamic jump to NemPCD_WriteRowToVDP, NemDec_WriteAndAdvance, NemPCD_WriteRowToVDP_XOR, or NemDec_WriteAndAdvance_XOR
; End of function NemDec_ProcessCompressedData

NemPCD_NewRow:
		moveq	#0,d4	; reset row
		moveq	#8,d3	; reset nybble counter

NemPCD_WritePixel_Loop:
		dbf	d0,NemPCD_WritePixel
		bra.s	NemDec_ProcessCompressedData
; ===========================================================================

NemPCD_InlineData:
		subq.w	#6,d6	; 6 bits needed to signal inline data
		cmpi.w	#9,d6
		bhs.s	loc_14E4
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5

loc_14E4:
		subq.w	#7,d6	; and 7 bits needed for the inline data itself
		move.w	d5,d1
		lsr.w	d6,d1	; shift so that low bit of the code is in bit position 0
		move.w	d1,d0
		andi.w	#$F,d1	; get palette index for pixel
		andi.w	#$70,d0	; high nybble is repeat count for pixel
		cmpi.w	#9,d6
		bhs.s	NemPCD_ProcessCompressedData
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5
		bra.s	NemPCD_ProcessCompressedData
; End of function NemPCD_NewRow

; ===========================================================================

NemPCD_WriteRowToVDP:
		move.l	d4,(a4)	; write 8-pixel row
		subq.w	#1,a5
		move.w	a5,d4	; have all the 8-pixel rows been written?
		bne.s	NemPCD_NewRow	; if not, branch
		rts		; otherwise the decompression is finished
; ===========================================================================
NemPCD_WriteRowToVDP_XOR:
		eor.l	d4,d2	; XOR the previous row by the current row
		move.l	d2,(a4)	; and write the result
		subq.w	#1,a5
		move.w	a5,d4
		bne.s	NemPCD_NewRow
		rts
; ===========================================================================

NemPCD_WriteRowToRAM:
		move.l	d4,(a4)+
		subq.w	#1,a5
		move.w	a5,d4
		bne.s	NemPCD_NewRow
		rts
; ===========================================================================
NemPCD_WriteRowToRAM_XOR:
		eor.l	d4,d2
		move.l	d2,(a4)+
		subq.w	#1,a5
		move.w	a5,d4
		bne.s	NemPCD_NewRow
		rts

; ---------------------------------------------------------------------------
; Part of the Nemesis decompressor, builds the code table (in RAM)
; ---------------------------------------------------------------------------

NemDec_BuildCodeTable:
		move.b	(a0)+,d0	; read first byte

NemBCT_ChkEnd:
		cmpi.b	#$FF,d0	; has the end of the code table description been reached?
		bne.s	NemBCT_NewPALIndex	; if not, branch
		rts	; otherwise, this subroutine's work is done
; ===========================================================================

NemBCT_NewPALIndex:
		move.w	d0,d7

NemBCT_Loop:
		move.b	(a0)+,d0	; read next byte
		cmpi.b	#$80,d0	; sign bit being set signifies a new palette index
		bhs.s	NemBCT_ChkEnd	; a bmi could have been used instead of a compare and bcc

		move.b	d0,d1
		andi.w	#$F,d7	; get palette index
		andi.w	#$70,d1	; get repeat count for palette index
		or.w	d1,d7	; combine the two
		andi.w	#$F,d0	; get the length of the code in bits
		move.b	d0,d1
		lsl.w	#8,d1
		or.w	d1,d7	; combine with palette index and repeat count to form code table entry
		moveq	#8,d1
		sub.w	d0,d1	; is the code 8 bits long?
		bne.s	NemBCT_ShortCode	; if not, a bit of extra processing is needed
		move.b	(a0)+,d0	; get code
		add.w	d0,d0	; each code gets a word-sized entry in the table
		move.w	d7,(a1,d0.w)	; store the entry for the code
		bra.s	NemBCT_Loop	; repeat
; ===========================================================================

; the Nemesis decompressor uses prefix-free codes (no valid code is a prefix of a longer code)
; e.g. if 10 is a valid 2-bit code, 110 is a valid 3-bit code but 100 isn't
; also, when the actual compressed data is processed the high bit of each code is in bit position 7
; so the code needs to be bit-shifted appropriately over here before being used as a code table index
; additionally, the code needs multiple entries in the table because no masking is done during compressed data processing
; so if 11000 is a valid code then all indices of the form 11000XXX need to have the same entry
NemBCT_ShortCode:
		move.b	(a0)+,d0	; get code
		lsl.w	d1,d0	; get index into code table
		add.w	d0,d0	; shift so that high bit is in bit position 7
		moveq	#1,d5
		lsl.w	d1,d5
		subq.w	#1,d5	; d5 = 2^d1 - 1

NemBCT_ShortCode_Loop:
		move.w	d7,(a1,d0.w)	; store entry
		addq.w	#2,d0	; increment index
		dbf	d5,NemBCT_ShortCode_Loop	; repeat for required number of entries
		bra.s	NemBCT_Loop
; End of function NemDec_BuildCodeTable

; ---------------------------------------------------------------------------
; Subroutine to load pattern load cues (aka to queue pattern load requests)
; ---------------------------------------------------------------------------

; ARGUMENTS
; d0 = index of PLC list
; ---------------------------------------------------------------------------

; LoadPLC:
AddPLC:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1		; jump to relevant PLC
		lea	(v_plc_buffer).w,a2 ; PLC buffer space

	@findspace:
		tst.l	(a2)		; is space available in RAM?
		beq.s	@copytoRAM	; if yes, branch
		addq.w	#6,a2		; if not, try next space
		bra.s	@findspace
; ===========================================================================

@copytoRAM:
		move.w	(a1)+,d0	; get length of PLC
		bmi.s	@skip

	@loop:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+	; copy PLC to RAM
		dbf	d0,@loop	; repeat for length of PLC

	@skip:
		movem.l	(sp)+,a1-a2 ; a1=object
		rts
; End of function AddPLC

; Queue pattern load requests, but clear the PLQ first

; ARGUMENTS
; d0 = index of PLC list (see ArtLoadCues)

; NOTICE: This subroutine does not check for buffer overruns. The programmer
;   (or hacker) is responsible for making sure that no more than
;   16 load requests are copied into the buffer.
;   _________DO NOT PUT MORE THAN 16 LOAD REQUESTS IN A LIST!__________
;         (or if you change the size of Plc_Buffer, the limit becomes (Plc_Buffer_Only_End-Plc_Buffer)/6)

; LoadPLC2:
NewPLC:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1	; jump to relevant PLC
		bsr.s	ClearPLC	; erase any data in PLC buffer space
		lea	(v_plc_buffer).w,a2
		move.w	(a1)+,d0	; get length of PLC
		bmi.s	@skip		; if it's negative, skip the next loop

	@loop:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+	; copy PLC to RAM
		dbf	d0,@loop		; repeat for length of PLC

	@skip:
		movem.l	(sp)+,a1-a2
		rts
; End of function NewPLC

; ---------------------------------------------------------------------------
; Subroutine to clear the pattern load cues
; ---------------------------------------------------------------------------

; Clear the pattern load queue ($FFF680 - $FFF700)

ClearPLC:
		lea	(v_plc_buffer).w,a2 ; PLC buffer space in RAM
		moveq	#$1F,d0	; bytesToLcnt(v_plc_buffer_end-v_plc_buffer)

	@loop:
		clr.l	(a2)+
		dbf	d0,@loop
		rts
; End of function ClearPLC

; ---------------------------------------------------------------------------
; Subroutine to use graphics listed in a pattern load cue
; ---------------------------------------------------------------------------

; RunPLC_RAM:
RunPLC:
		tst.l	(v_plc_buffer).w
		beq.s	Rplc_Exit
		tst.w	(f_plc_execute).w
		bne.s	Rplc_Exit
		movea.l	(v_plc_buffer).w,a0
		lea	(NemPCD_WriteRowToVDP).l,a3
		lea	(v_ngfx_buffer).w,a1
		move.w	(a0)+,d2
		bpl.s	loc_160E
		adda.w	#$A,a3

loc_160E:
		andi.w	#$7FFF,d2
		move.w	d2,(f_plc_execute).w
		bsr.w	NemDec_BuildCodeTable
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6
		moveq	#0,d0
		move.l	a0,(v_plc_buffer).w
		move.l	a3,(v_ptrnemcode).w
		move.l	d0,(v_plc_repeatcount).w
		move.l	d0,(v_plc_paletteindex).w
		move.l	d0,(v_plc_previousrow).w
		move.l	d5,(v_plc_dataword).w
		move.l	d6,(v_plc_shiftvalue).w

Rplc_Exit:
		rts
; End of function RunPLC

sub_1642:
		tst.w	(f_plc_execute).w
		beq.w	locret_16DA
		move.w	#9,(v_plc_framepatternsleft).w
		moveq	#0,d0
		move.w	(v_plc_buffer+4).w,d0
		addi.w	#$120,(v_plc_buffer+4).w
		bra.s	loc_1676
; End of function sub_1642

; sub_165E:
ProcessDPLC2:
		tst.w	(f_plc_execute).w
		beq.s	locret_16DA
		move.w	#3,(v_plc_framepatternsleft).w
		moveq	#0,d0
		move.w	(v_plc_buffer+4).w,d0
		addi.w	#$60,(v_plc_buffer+4).w

loc_1676:
		lea	(vdp_control_port).l,a4
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(a4)
		subq.w	#4,a4
		movea.l	(v_plc_buffer).w,a0
		movea.l	(v_ptrnemcode).w,a3
		move.l	(v_plc_repeatcount).w,d0
		move.l	(v_plc_paletteindex).w,d1
		move.l	(v_plc_previousrow).w,d2
		move.l	(v_plc_dataword).w,d5
		move.l	(v_plc_shiftvalue).w,d6
		lea	(v_ngfx_buffer).w,a1

loc_16AA:
		movea.w	#8,a5
		bsr.w	NemPCD_NewRow
		subq.w	#1,(f_plc_execute).w
		beq.s	loc_16DC
		subq.w	#1,(v_plc_framepatternsleft).w
		bne.s	loc_16AA
		move.l	a0,(v_plc_buffer).w
		move.l	a3,(v_ptrnemcode).w
		move.l	d0,(v_plc_repeatcount).w
		move.l	d1,(v_plc_paletteindex).w
		move.l	d2,(v_plc_previousrow).w
		move.l	d5,(v_plc_dataword).w
		move.l	d6,(v_plc_shiftvalue).w

locret_16DA:
		rts
; ===========================================================================

loc_16DC:
		lea	(v_plc_buffer).w,a0
		moveq	#$15,d0

loc_16E2:
		move.l	6(a0),(a0)+
		dbf	d0,loc_16E2
		
		; FixBugs: correctly pop the 16th PLC entry
		move.w	6(a0),(a0)
		clr.l	(v_plc_buffer+(6*16)-6).w
		rts
; End of function ProcessDPLC2

; ---------------------------------------------------------------------------
; Subroutine to execute	the pattern load cue
; ---------------------------------------------------------------------------

QuickPLC:
		lea	(ArtLoadCues).l,a1 ; load the PLC index
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		move.w	(a1)+,d1	; get length of PLC

	Qplc_Loop:
		movea.l	(a1)+,a0	; get art pointer
		moveq	#0,d0
		move.w	(a1)+,d0	; get VRAM address
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(vdp_control_port).l ; converted VRAM address to VDP format
		bsr.w	NemDec		; decompress
		dbf	d1,Qplc_Loop	; repeat for length of PLC
		rts
; End of function QuickPLC

; ---------------------------------------------------------------------------
; Enigma decompression algorithm

; input:
; d0 = starting art tile (added to each 8x8 before writing to destination)
; a0 = source address
; a1 = destination address

; usage:
; lea	(source).l,a0
; lea	(destination).l,a1
; move.w	#arttile,d0
; bsr.w	EniDec

; See http://www.segaretro.org/Enigma_compression for format description
; ---------------------------------------------------------------------------

EniDec:
		movem.l	d0-d7/a1-a5,-(sp)
		movea.w	d0,a3		; store starting art tile
		move.b	(a0)+,d0
		ext.w	d0
		movea.w	d0,a5		; store number of bits in inline copy value
		move.b	(a0)+,d4
		lsl.b	#3,d4		; store PCCVH flags bitfield
		movea.w	(a0)+,a2
		adda.w	a3,a2		; store incremental copy word
		movea.w	(a0)+,a4
		adda.w	a3,a4		; store literal copy word
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5	; get first word in format list
		moveq	#16,d6		; initial shift value
; loc_173E:
Eni_Loop:
		moveq	#7,d0		; assume a format list entry is 7 bits
		move.w	d6,d7
		sub.w	d0,d7
		move.w	d5,d1
		lsr.w	d7,d1
		andi.w	#$7F,d1		; get format list entry
		move.w	d1,d2		; and copy it
		cmpi.w	#$40,d1		; is the high bit of the entry set?
		bhs.s	@sevenbitentry
		moveq	#6,d0		; if it isn't, the entry is actually 6 bits
		lsr.w	#1,d2
; loc_1758:
@sevenbitentry:
		bsr.w	EniDec_FetchByte
		andi.w	#$F,d2		; get repeat count
		lsr.w	#4,d1
		add.w	d1,d1
		jmp	EniDec_Index(pc,d1.w)
; End of function EniDec

; ===========================================================================
; loc_1768:
EniDec_00:
@loop:		move.w	a2,(a1)+	; copy incremental copy word
		addq.w	#1,a2		; increment it
		dbf	d2,@loop	; repeat
		bra.s	Eni_Loop
; ===========================================================================
; loc_1772:
EniDec_01:
@loop:		move.w	a4,(a1)+	; copy literal copy word
		dbf	d2,@loop	; repeat
		bra.s	Eni_Loop
; ===========================================================================
; loc_177A:
EniDec_100:
		bsr.w	EniDec_FetchInlineValue
; loc_177E:
@loop:		move.w	d1,(a1)+	; copy inline value
		dbf	d2,@loop	; repeat

		bra.s	Eni_Loop
; ===========================================================================
; loc_1786:
EniDec_101:
		bsr.w	EniDec_FetchInlineValue
; loc_178A:
@loop:		move.w	d1,(a1)+	; copy inline value
		addq.w	#1,d1		; increment
		dbf	d2,@loop	; repeat

		bra.s	Eni_Loop
; ===========================================================================
; loc_1794:
EniDec_110:
		bsr.w	EniDec_FetchInlineValue
; loc_1798:
@loop:		move.w	d1,(a1)+	; copy inline value
		subq.w	#1,d1		; decrement
		dbf	d2,@loop	; repeat

		bra.s	Eni_Loop
; ===========================================================================
; loc_17A2:
EniDec_111:
		cmpi.w	#$F,d2
		beq.s	EniDec_Done
; loc_17A8:
@loop:		bsr.w	EniDec_FetchInlineValue	; fetch new inline value
		move.w	d1,(a1)+	; copy it
		dbf	d2,@loop	; and repeat

		bra.s	Eni_Loop
; ===========================================================================
; loc_17B4:
EniDec_Index:
		bra.s	EniDec_00
		bra.s	EniDec_00
		bra.s	EniDec_01
		bra.s	EniDec_01
		bra.s	EniDec_100
		bra.s	EniDec_101
		bra.s	EniDec_110
		bra.s	EniDec_111
; ===========================================================================
; loc_17C4:
EniDec_Done:
		subq.w	#1,a0		; go back by one byte
		cmpi.w	#16,d6		; were we going to start on a completely new byte?
		bne.s	@notnewbyte	; if not, branch
		subq.w	#1,a0		; and another one if needed
; loc_17CE:
@notnewbyte:
		move.w	a0,d0
		lsr.w	#1,d0		; are we on an odd byte?
		bhs.s	@evenbyte	; if not, branch
		addq.w	#1,a0		; ensure we're on an even byte
; loc_17D6:
@evenbyte:
		movem.l	(sp)+,d0-d7/a1-a5
		rts

; ---------------------------------------------------------------------------
; Part of the Enigma decompressor
; Fetches an inline copy value and stores it in d1
; ---------------------------------------------------------------------------

; loc_17DC:
EniDec_FetchInlineValue:
		move.w	a3,d3		; copy starting art tile
		move.b	d4,d1		; copy PCCVH bitfield
		add.b	d1,d1		; is the priority bit set?
		bhs.s	@skippriority	; if not, branch
		subq.w	#1,d6
		btst	d6,d5		; is the priority bit set in the inline render flags?
		beq.s	@skippriority	; if not, branch
		ori.w	#$8000,d3	; otherwise set priority bit in art tile
; loc_17EE:
@skippriority:
		add.b	d1,d1		; is the high palette line bit set?
		bhs.s	@skiphighpal	; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	@skiphighpal
		addi.w	#$4000,d3	; set second palette line bit
; loc_17FC:
@skiphighpal:
		add.b	d1,d1		; is the low palette line bit set?
		bhs.s	@skiplowpal	; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	@skiplowpal
		addi.w	#$2000,d3	; set first palette line bit
; loc_180A:
@skiplowpal:
		add.b	d1,d1		; is the vertical flip flag set?
		bhs.s	@skipyflip	; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	@skipyflip
		ori.w	#$1000,d3	; set Y-flip bit
; loc_1818:
@skipyflip:
		add.b	d1,d1		; is the horizontal flip flag set?
		bhs.s	@skipxflip	; if not, branch
		subq.w	#1,d6
		btst	d6,d5
		beq.s	@skipxflip
		ori.w	#$800,d3	; set X-flip bit
; loc_1826:
@skipxflip:
		move.w	d5,d1
		move.w	d6,d7
		sub.w	a5,d7		; subtract length in bits of inline copy value
		bhs.s	@enoughbits	; branch if a new word doesn't need to be read
		move.w	d7,d6
		addi.w	#16,d6
		neg.w	d7		; calculate bit deficit
		lsl.w	d7,d1		; and make space for that many bits
		move.b	(a0),d5		; get next byte
		rol.b	d7,d5		; and rotate the required bits into the lowest positions
		add.w	d7,d7
		and.w	EniDec_Masks-2(pc,d7.w),d5
		add.w	d5,d1		; combine upper bits with lower bits
; loc_1844:
@maskvalue:
		move.w	a5,d0		; get length in bits of inline copy value
		add.w	d0,d0
		and.w	EniDec_Masks-2(pc,d0.w),d1	; mask value appropriately
		add.w	d3,d1		; add starting art tile
		move.b	(a0)+,d5
		lsl.w	#8,d5
		move.b	(a0)+,d5	; get next word
		rts
; ===========================================================================
; loc_1856:
@enoughbits:
		beq.s	@justenough	; if the word has been exactly exhausted, branch
		lsr.w	d7,d1	; get inline copy value
		move.w	a5,d0
		add.w	d0,d0
		and.w	EniDec_Masks-2(pc,d0.w),d1	; and mask it appropriately
		add.w	d3,d1	; add starting art tile
		move.w	a5,d0
		bra.s	EniDec_FetchByte
; ===========================================================================
; loc_1868:
@justenough:
		moveq	#16,d6	; reset shift value
		bra.s	@maskvalue
; ===========================================================================
; word_186C:
EniDec_Masks:
		dc.w	 1,    3,    7,   $F
		dc.w   $1F,  $3F,  $7F,  $FF
		dc.w  $1FF, $3FF, $7FF, $FFF
		dc.w $1FFF,$3FFF,$7FFF,$FFFF

; sub_188C:
EniDec_FetchByte:
		sub.w	d0,d6	; subtract length of current entry from shift value so that next entry is read next time around
		cmpi.w	#9,d6	; does a new byte need to be read?
		bhs.s	@locret	; if not, branch
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5
@locret:
		rts
; End of function EniDec_FetchByte

; ---------------------------------------------------------------------------
; Kosinski decompression algorithm

; input:
; a0 = source address
; a1 = destination address

; usage:
; lea	(source).l,a0
; lea	(destination).l,a1
; bsr.w	KosDec
; ---------------------------------------------------------------------------

KosDec:

		subq.l	#2,sp	; make space for 2 bytes on the stack
		move.b	(a0)+,1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5	; get first description field
		moveq	#$F,d4	; set to loop for 16 bits

Kos_Loop:
		lsr.w	#1,d5	; shift bit into the c flag
		move	sr,d6
		dbf	d4,@chkbit
		move.b	(a0)+,1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

	@chkbit:
		move	d6,ccr	; was the bit set?
		bhs.s	Kos_RLE	; if not, branch

		move.b	(a0)+,(a1)+ ; copy byte as-is
		bra.s	Kos_Loop
; ===========================================================================

Kos_RLE:
		moveq	#0,d3
		lsr.w	#1,d5	; get next bit
		move	sr,d6
		dbf	d4,@chkbit
		move.b	(a0)+,1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

	@chkbit:
		move	d6,ccr	; was the bit set?
		blo.s	Kos_SeparateRLE ; if yes, branch

		lsr.w	#1,d5	; shift bit into the x flag
		dbf	d4,@loop1
		move.b	(a0)+,1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

	@loop1:
		roxl.w	#1,d3	; get high repeat count bit
		lsr.w	#1,d5
		dbf	d4,@loop2
		move.b	(a0)+,1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

	@loop2:
		roxl.w	#1,d3	; get low repeat count bit
		addq.w	#1,d3	; increment repeat count
		moveq	#-1,d2
		move.b	(a0)+,d2 ; calculate offset
		bra.s	Kos_RLELoop
; ===========================================================================

Kos_SeparateRLE:
		move.b	(a0)+,d0 ; get first byte
		move.b	(a0)+,d1 ; get second byte
		moveq	#-1,d2
		move.b	d1,d2
		lsl.w	#5,d2
		move.b	d0,d2	; calculate offset
		andi.w	#7,d1	; does a third byte need to be read?
		beq.s	Kos_SeparateRLE2 ; if yes, branch
		move.b	d1,d3	; copy repeat count
		addq.w	#1,d3	; increment

Kos_RLELoop:
		move.b	(a1,d2.w),d0 ; copy appropriate byte
		move.b	d0,(a1)+ ; repeat
		dbf	d3,Kos_RLELoop
		bra.s	Kos_Loop
; ===========================================================================

Kos_SeparateRLE2:
		move.b	(a0)+,d1
		beq.s	Kos_Done ; 0 indicates end of compressed data
		cmpi.b	#1,d1
		beq.w	Kos_Loop ; 1 indicates new description to be read
		move.b	d1,d3	; otherwise, copy repeat count
		bra.s	Kos_RLELoop
; ===========================================================================

Kos_Done:
		addq.l	#2,sp	; restore stack pointer
		rts
; End of function KosDec

; ---------------------------------------------------------------------------
; Palette cycling routine loading subroutine
; ---------------------------------------------------------------------------

; PalCycle_Load:
PaletteCycle:
		moveq	#0,d2
		moveq	#0,d0
		move.b	(v_zone).w,d0	; get level number
		add.w	d0,d0
		move.w	PalCycle_Index(pc,d0.w),d0
		jmp	PalCycle_Index(pc,d0.w) ; jump to relevant palette routine
; End of function PaletteCycle

; ===========================================================================
; ---------------------------------------------------------------------------
; Palette cycling routines
; ---------------------------------------------------------------------------
PalCycle_Index:	dc.w PalCycle_GHZ-PalCycle_Index
		dc.w PalCycle_LZ-PalCycle_Index
		dc.w PalCycle_MZ-PalCycle_Index
		dc.w PalCycle_SLZ-PalCycle_Index
		dc.w PalCycle_SYZ-PalCycle_Index
		dc.w PalCycle_SBZ-PalCycle_Index
		dc.w PalCycle_GHZ-PalCycle_Index	; Ending

PalCycle_Title:
		lea	(Pal_TitleCyc).l,a0
		bra.s	PCycGHZ_Go
; ===========================================================================

PalCycle_GHZ:
		lea	(Pal_GHZCyc).l,a0

PCycGHZ_Go:
		subq.w	#1,(v_pcyc_time).w ; decrement timer
		bpl.s	PCycGHZ_Skip	; if time remains, branch

		move.w	#5,(v_pcyc_time).w ; reset timer to 5 frames
		move.w	(v_pcyc_num).w,d0 ; get cycle number
		addq.w	#1,(v_pcyc_num).w ; increment cycle number
		andi.w	#3,d0		; if cycle > 3, reset to 0
		lsl.w	#3,d0
		lea	(v_pal_dry+$50).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)	; copy palette data to RAM

PCycGHZ_Skip:
		rts
; End of function PalCycle_GHZ

PalCycle_LZ:
; Waterfalls
		subq.w	#1,(v_pcyc_time).w ; decrement timer
		bpl.s	PCycLZ_Skip1	; if time remains, branch

		move.w	#2,(v_pcyc_time).w ; reset timer to 2 frames
		move.w	(v_pcyc_num).w,d0
		addq.w	#1,(v_pcyc_num).w ; increment cycle number
		andi.w	#3,d0		; if cycle > 3, reset to 0
		lsl.w	#3,d0
		lea	(Pal_LZCyc1).l,a0
		cmpi.b	#3,(v_act).w	; check if level is SBZ3
		bne.s	PCycLZ_NotSBZ3
		lea	(Pal_SBZ3Cyc).l,a0 ; load SBZ3 palette instead

	PCycLZ_NotSBZ3:
		lea	(v_pal_dry+$56).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)
		lea	(v_pal_water+$56).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)

PCycLZ_Skip1:
; Conveyor belts
		move.w	(v_framecount).w,d0
		andi.w	#7,d0
		move.b	PCycLZ_Seq(pc,d0.w),d0 ; get byte from palette sequence
		beq.s	PCycLZ_Skip2	; if byte is 0, branch
		moveq	#1,d1
		tst.b	(f_conveyrev).w	; have conveyor belts been reversed?
		beq.s	PCycLZ_NoRev	; if not, branch
		neg.w	d1

	PCycLZ_NoRev:
		move.w	(v_pal_buffer).w,d0
		andi.w	#3,d0
		add.w	d1,d0
		cmpi.w	#3,d0
		blo.s	loc_1A0A
		move.w	d0,d1
		moveq	#0,d0
		tst.w	d1
		bpl.s	loc_1A0A
		moveq	#2,d0

loc_1A0A:
		move.w	d0,(v_pal_buffer).w
		add.w	d0,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		lea	(Pal_LZCyc2).l,a0
		lea	(v_pal_dry+$76).w,a1
		move.l	(a0,d0.w),(a1)+
		move.w	4(a0,d0.w),(a1)
		lea	(Pal_LZCyc3).l,a0
		lea	(v_pal_water+$76).w,a1
		move.l	(a0,d0.w),(a1)+
		move.w	4(a0,d0.w),(a1)

PCycLZ_Skip2:
		rts
; End of function PalCycle_LZ

; ===========================================================================
PCycLZ_Seq:	dc.b 1,	0, 0, 1, 0, 0, 1, 0
; ===========================================================================

PalCycle_MZ:
		rts

PalCycle_SLZ:
		subq.w	#1,(v_pcyc_time).w
		bpl.s	locret_1A80
		move.w	#7,(v_pcyc_time).w
		move.w	(v_pcyc_num).w,d0
		addq.w	#1,d0
		cmpi.w	#6,d0
		blo.s	loc_1A60
		moveq	#0,d0

loc_1A60:
		move.w	d0,(v_pcyc_num).w
		move.w	d0,d1
		add.w	d1,d1
		add.w	d1,d0
		add.w	d0,d0
		lea	(Pal_SLZCyc).l,a0
		lea	(v_pal_dry+$56).w,a1
		move.w	(a0,d0.w),(a1)
		move.l	2(a0,d0.w),4(a1)

locret_1A80:
		rts
; End of function PalCycle_SLZ

PalCycle_SYZ:
		subq.w	#1,(v_pcyc_time).w
		bpl.s	locret_1AC6
		move.w	#5,(v_pcyc_time).w
		move.w	(v_pcyc_num).w,d0
		addq.w	#1,(v_pcyc_num).w
		andi.w	#3,d0
		lsl.w	#2,d0
		move.w	d0,d1
		add.w	d0,d0
		lea	(Pal_SYZCyc1).l,a0
		lea	(v_pal_dry+$6E).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)
		lea	(Pal_SYZCyc2).l,a0
		lea	(v_pal_dry+$76).w,a1
		move.w	(a0,d1.w),(a1)
		move.w	2(a0,d1.w),4(a1)

locret_1AC6:
		rts
; End of function PalCycle_SYZ

PalCycle_SBZ:
		lea	(Pal_SBZCycList1).l,a2
		tst.b	(v_act).w
		beq.s	loc_1ADA
		lea	(Pal_SBZCycList2).l,a2

loc_1ADA:
		lea	(v_pal_buffer).w,a1
		move.w	(a2)+,d1

loc_1AE0:
		subq.b	#1,(a1)
		bmi.s	loc_1AEA
		addq.l	#2,a1
		addq.l	#6,a2
		bra.s	loc_1B06
; ===========================================================================

loc_1AEA:
		move.b	(a2)+,(a1)+
		move.b	(a1),d0
		addq.b	#1,d0
		cmp.b	(a2)+,d0
		blo.s	loc_1AF6
		moveq	#0,d0

loc_1AF6:
		move.b	d0,(a1)+
		andi.w	#$F,d0
		add.w	d0,d0
		movea.w	(a2)+,a0
		movea.w	(a2)+,a3
		move.w	(a0,d0.w),(a3)

loc_1B06:
		dbf	d1,loc_1AE0
		subq.w	#1,(v_pcyc_time).w
		bpl.s	locret_1B64
		lea	(Pal_SBZCyc4).l,a0
		move.w	#1,(v_pcyc_time).w
		tst.b	(v_act).w
		beq.s	loc_1B2E
		lea	(Pal_SBZCyc10).l,a0
		move.w	#0,(v_pcyc_time).w

loc_1B2E:
		moveq	#-1,d1
		tst.b	(f_conveyrev).w
		beq.s	loc_1B38
		neg.w	d1

loc_1B38:
		move.w	(v_pcyc_num).w,d0
		andi.w	#3,d0
		add.w	d1,d0
		cmpi.w	#3,d0
		blo.s	loc_1B52
		move.w	d0,d1
		moveq	#0,d0
		tst.w	d1
		bpl.s	loc_1B52
		moveq	#2,d0

loc_1B52:
		move.w	d0,(v_pcyc_num).w
		add.w	d0,d0
		lea	(v_pal_dry+$58).w,a1
		move.l	(a0,d0.w),(a1)+
		move.w	4(a0,d0.w),(a1)

locret_1B64:
		rts
; End of function PalCycle_SBZ

Pal_TitleCyc:	incbin	"palette\Cycle - Title Screen Water.bin"
Pal_GHZCyc:	incbin	"palette\Cycle - GHZ.bin"
Pal_LZCyc1:	incbin	"palette\Cycle - LZ Waterfall.bin"
Pal_LZCyc2:	incbin	"palette\Cycle - LZ Conveyor Belt.bin"
Pal_LZCyc3:	incbin	"palette\Cycle - LZ Conveyor Belt Underwater.bin"
Pal_SBZ3Cyc:	incbin	"palette\Cycle - SBZ3 Waterfall.bin"
Pal_SLZCyc:	incbin	"palette\Cycle - SLZ.bin"
Pal_SYZCyc1:	incbin	"palette\Cycle - SYZ1.bin"
Pal_SYZCyc2:	incbin	"palette\Cycle - SYZ2.bin"

; ---------------------------------------------------------------------------
; Scrap Brain Zone palette cycling script
; ---------------------------------------------------------------------------

mSBZp:	macro duration,colours,paladdress,ramaddress
	dc.b duration, colours
	dc.w paladdress, ramaddress
	endm

; duration in frames, number of colours, palette address, RAM address

Pal_SBZCycList1:
	dc.w ((end_SBZCycList1-Pal_SBZCycList1-2)/6)-1
	mSBZp	7,8,Pal_SBZCyc1,v_pal_dry+$50
	mSBZp	$D,8,Pal_SBZCyc2,v_pal_dry+$52
	mSBZp	$E,8,Pal_SBZCyc3,v_pal_dry+$6E
	mSBZp	$B,8,Pal_SBZCyc5,v_pal_dry+$70
	mSBZp	7,8,Pal_SBZCyc6,v_pal_dry+$72
	mSBZp	$1C,$10,Pal_SBZCyc7,v_pal_dry+$7E
	mSBZp	3,3,Pal_SBZCyc8,v_pal_dry+$78
	mSBZp	3,3,Pal_SBZCyc8+2,v_pal_dry+$7A
	mSBZp	3,3,Pal_SBZCyc8+4,v_pal_dry+$7C
end_SBZCycList1:
	even

Pal_SBZCycList2:
	dc.w ((end_SBZCycList2-Pal_SBZCycList2-2)/6)-1
	mSBZp	7,8,Pal_SBZCyc1,v_pal_dry+$50
	mSBZp	$D,8,Pal_SBZCyc2,v_pal_dry+$52
	mSBZp	9,8,Pal_SBZCyc9,v_pal_dry+$70
	mSBZp	7,8,Pal_SBZCyc6,v_pal_dry+$72
	mSBZp	3,3,Pal_SBZCyc8,v_pal_dry+$78
	mSBZp	3,3,Pal_SBZCyc8+2,v_pal_dry+$7A
	mSBZp	3,3,Pal_SBZCyc8+4,v_pal_dry+$7C
end_SBZCycList2:
	even

Pal_SBZCyc1:	incbin	"palette\Cycle - SBZ 1.bin"
Pal_SBZCyc2:	incbin	"palette\Cycle - SBZ 2.bin"
Pal_SBZCyc3:	incbin	"palette\Cycle - SBZ 3.bin"
Pal_SBZCyc4:	incbin	"palette\Cycle - SBZ 4.bin"
Pal_SBZCyc5:	incbin	"palette\Cycle - SBZ 5.bin"
Pal_SBZCyc6:	incbin	"palette\Cycle - SBZ 6.bin"
Pal_SBZCyc7:	incbin	"palette\Cycle - SBZ 7.bin"
Pal_SBZCyc8:	incbin	"palette\Cycle - SBZ 8.bin"
Pal_SBZCyc9:	incbin	"palette\Cycle - SBZ 9.bin"
Pal_SBZCyc10:	incbin	"palette\Cycle - SBZ 10.bin"

; ---------------------------------------------------------------------------
; Subroutine to fade in from black
; ---------------------------------------------------------------------------

; Pal_FadeTo:
PaletteFadeIn:
		move.w	#$003F,(v_pfade_start).w ; set start position = 0; size = $40

; Pal_FadeTo2:
PalFadeIn_Alt:				; start position and size are already set
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		moveq	#cBlack,d1
		move.b	(v_pfade_size).w,d0

	@fill:
		move.w	d1,(a0)+
		dbf	d0,@fill 	; fill palette with black

		move.w	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	FadeIn_FromBlack
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteFadeIn

; Pal_FadeIn:
FadeIn_FromBlack:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		lea	(v_pal_dry_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@addcolour:
		bsr.s	FadeIn_AddColour ; increase colour
		dbf	d0,@addcolour	; repeat for size of palette

		cmpi.b	#id_LZ,(v_zone).w	; is level Labyrinth?
		bne.s	@exit		; if not, branch

		moveq	#0,d0
		lea	(v_pal_water).w,a0
		lea	(v_pal_water_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@addcolour2:
		bsr.s	FadeIn_AddColour ; increase colour again
		dbf	d0,@addcolour2 ; repeat

@exit:
		rts
; End of function FadeIn_FromBlack

; Pal_AddColor:
FadeIn_AddColour:
@addblue:
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3		; is colour already at threshold level?
		beq.s	@next		; if yes, branch
		move.w	d3,d1
		addi.w	#$200,d1	; increase blue value
		cmp.w	d2,d1		; has blue reached threshold level?
		bhi.s	@addgreen	; if yes, branch
		move.w	d1,(a0)+	; update palette
		rts

@addgreen:
		move.w	d3,d1
		addi.w	#$20,d1		; increase green value
		cmp.w	d2,d1
		bhi.s	@addred
		move.w	d1,(a0)+	; update palette
		rts

@addred:
		addq.w	#2,(a0)+	; increase red value
		rts

@next:
		addq.w	#2,a0		; next colour
		rts
; End of function FadeIn_AddColour

; ---------------------------------------------------------------------------
; Subroutine to fade out to black
; ---------------------------------------------------------------------------

; Pal_FadeFrom:
PaletteFadeOut:
		move.w	#$003F,(v_pfade_start).w ; start position = 0; size = $40
		move.w	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	FadeOut_ToBlack
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteFadeOut

; Pal_FadeOut:
FadeOut_ToBlack:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@decolour:
		bsr.s	FadeOut_DecColour ; decrease colour
		dbf	d0,@decolour	; repeat for size of palette

		moveq	#0,d0
		lea	(v_pal_water).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@decolour2:
		bsr.s	FadeOut_DecColour
		dbf	d0,@decolour2
		rts
; End of function FadeOut_ToBlack

; Pal_DecColor:
FadeOut_DecColour:
@dered:
		move.w	(a0),d2
		beq.s	@next
		move.w	d2,d1
		andi.w	#$E,d1
		beq.s	@degreen
		subq.w	#2,(a0)+	; decrease red value
		rts

@degreen:
		move.w	d2,d1
		andi.w	#$E0,d1
		beq.s	@deblue
		subi.w	#$20,(a0)+	; decrease green value
		rts

@deblue:
		move.w	d2,d1
		andi.w	#$E00,d1
		beq.s	@next
		subi.w	#$200,(a0)+	; decrease blue value
		rts

@next:
		addq.w	#2,a0
		rts
; End of function FadeOut_DecColour

; ---------------------------------------------------------------------------
; Subroutine to fade in from white (Special Stage)
; ---------------------------------------------------------------------------

; Pal_MakeWhite:
PaletteWhiteIn:
		move.w	#$003F,(v_pfade_start).w ; start position = 0; size = $40
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.w	#cWhite,d1
		move.b	(v_pfade_size).w,d0

	@fill:
		move.w	d1,(a0)+
		dbf	d0,@fill 	; fill palette with white

		move.w	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	WhiteIn_FromWhite
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteWhiteIn

; Pal_WhiteToBlack:
WhiteIn_FromWhite:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		lea	(v_pal_dry_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@decolour:
		bsr.s	WhiteIn_DecColour ; decrease colour
		dbf	d0,@decolour	; repeat for size of palette

		cmpi.b	#id_LZ,(v_zone).w	; is level Labyrinth?
		bne.s	@exit		; if not, branch
		moveq	#0,d0
		lea	(v_pal_water).w,a0
		lea	(v_pal_water_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@decolour2:
		bsr.s	WhiteIn_DecColour
		dbf	d0,@decolour2

	@exit:
		rts
; End of function WhiteIn_FromWhite

; Pal_DecColor2:
WhiteIn_DecColour:
@deblue:
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3
		beq.s	@next
		move.w	d3,d1
		subi.w	#$200,d1	; decrease blue value
		blo.s	@degreen
		cmp.w	d2,d1
		blo.s	@degreen
		move.w	d1,(a0)+
		rts

@degreen:
		move.w	d3,d1
		subi.w	#$20,d1		; decrease green value
		blo.s	@dered
		cmp.w	d2,d1
		blo.s	@dered
		move.w	d1,(a0)+
		rts

@dered:
		subq.w	#2,(a0)+	; decrease red value
		rts

@next:
		addq.w	#2,a0
		rts
; End of function WhiteIn_DecColour

; ---------------------------------------------------------------------------
; Subroutine to fade to white (Special Stage)
; ---------------------------------------------------------------------------

; Pal_MakeFlash:
PaletteWhiteOut:
		move.w	#$003F,(v_pfade_start).w ; start position = 0; size = $40
		move.w	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	WhiteOut_ToWhite
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteWhiteOut

; Pal_ToWhite:
WhiteOut_ToWhite:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@addcolour:
		bsr.s	WhiteOut_AddColour
		dbf	d0,@addcolour

		moveq	#0,d0
		lea	(v_pal_water).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@addcolour2:
		bsr.s	WhiteOut_AddColour
		dbf	d0,@addcolour2
		rts
; End of function WhiteOut_ToWhite

; Pal_AddColor2:
WhiteOut_AddColour:
@addred:
		move.w	(a0),d2
		cmpi.w	#cWhite,d2
		beq.s	@next
		move.w	d2,d1
		andi.w	#$E,d1
		cmpi.w	#cRed,d1
		beq.s	@addgreen
		addq.w	#2,(a0)+	; increase red value
		rts

@addgreen:
		move.w	d2,d1
		andi.w	#$E0,d1
		cmpi.w	#cGreen,d1
		beq.s	@addblue
		addi.w	#$20,(a0)+	; increase green value
		rts

@addblue:
		move.w	d2,d1
		andi.w	#$E00,d1
		cmpi.w	#cBlue,d1
		beq.s	@next
		addi.w	#$200,(a0)+	; increase blue value
		rts

@next:
		addq.w	#2,a0
		rts
; End of function WhiteOut_AddColour

; ---------------------------------------------------------------------------
; Palette cycling routine - Sega logo
; ---------------------------------------------------------------------------

PalCycle_Sega:
		tst.b	(v_pcyc_time+1).w
		bne.s	loc_206A
		lea	(v_pal_dry+$20).w,a1
		lea	(Pal_Sega1).l,a0
		moveq	#5,d1
		move.w	(v_pcyc_num).w,d0

loc_2020:
		bpl.s	loc_202A
		addq.w	#2,a0
		subq.w	#1,d1
		addq.w	#2,d0
		bra.s	loc_2020
; ===========================================================================

loc_202A:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2034
		addq.w	#2,d0

loc_2034:
		cmpi.w	#$60,d0
		bhs.s	loc_203E
		move.w	(a0)+,(a1,d0.w)

loc_203E:
		addq.w	#2,d0
		dbf	d1,loc_202A

		move.w	(v_pcyc_num).w,d0
		addq.w	#2,d0
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2054
		addq.w	#2,d0

loc_2054:
		cmpi.w	#$64,d0
		blt.s	loc_2062
		move.w	#$401,(v_pcyc_time).w
		moveq	#-$C,d0

loc_2062:
		move.w	d0,(v_pcyc_num).w
		moveq	#1,d0
		rts
; ===========================================================================

loc_206A:
		subq.b	#1,(v_pcyc_time).w
		bpl.s	loc_20BC
		move.b	#4,(v_pcyc_time).w
		move.w	(v_pcyc_num).w,d0
		addi.w	#$C,d0
		cmpi.w	#$30,d0
		blo.s	loc_2088
		moveq	#0,d0
		rts
; ===========================================================================

loc_2088:
		move.w	d0,(v_pcyc_num).w
		lea	(Pal_Sega2).l,a0
		lea	(a0,d0.w),a0
		lea	(v_pal_dry+$04).w,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.w	(a0)+,(a1)
		lea	(v_pal_dry+$20).w,a1
		moveq	#0,d0
		moveq	#$2C,d1

loc_20A8:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_20B2
		addq.w	#2,d0

loc_20B2:
		move.w	(a0),(a1,d0.w)
		addq.w	#2,d0
		dbf	d1,loc_20A8

loc_20BC:
		moveq	#1,d0
		rts
; End of function PalCycle_Sega

; ===========================================================================

Pal_Sega1:	incbin	"palette\Sega1.bin"
Pal_Sega2:	incbin	"palette\Sega2.bin"

; ---------------------------------------------------------------------------
; Subroutines to load palettes

; input:
; d0 = index number for palette
; ---------------------------------------------------------------------------

PalLoad1:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		adda.w	#v_pal_dry_dup-v_pal_dry,a3		; skip to "main" RAM address
		move.w	(a1)+,d7	; get length of palette data

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad1

PalLoad2:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		move.w	(a1)+,d7	; get length of palette

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad2

; ---------------------------------------------------------------------------
; Underwater palette loading subroutine
; ---------------------------------------------------------------------------

PalLoad3_Water:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		suba.w	#v_pal_dry-v_pal_water,a3		; skip to "main" RAM address
		move.w	(a1)+,d7	; get length of palette data

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad3_Water

PalLoad4_Water:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		suba.w	#v_pal_dry-v_pal_water_dup,a3
		move.w	(a1)+,d7	; get length of palette data

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad4_Water

; ===========================================================================

; ---------------------------------------------------------------------------
; Palette pointers
; ---------------------------------------------------------------------------

palp:	macro paladdress,ramaddress,colours
	dc.l paladdress
	dc.w ramaddress, (colours>>1)-1
	endm

PalPointers:

; palette address, RAM address, colours

ptr_Pal_SegaBG:		palp	Pal_SegaBG,v_pal_dry,$40		; 0 - Sega logo
ptr_Pal_Title:		palp	Pal_Title,v_pal_dry,$40		; 1 - title screen
ptr_Pal_LevelSel:	palp	Pal_LevelSel,v_pal_dry,$40		; 2 - level select
ptr_Pal_Sonic:		palp	Pal_Sonic,v_pal_dry,$10		; 3 - Sonic
Pal_Levels:
ptr_Pal_GHZ:		palp	Pal_GHZ,v_pal_dry+$20, $30		; 4 - GHZ
ptr_Pal_LZ:		palp	Pal_LZ,v_pal_dry+$20,$30		; 5 - LZ
ptr_Pal_MZ:		palp	Pal_MZ,v_pal_dry+$20,$30		; 6 - MZ
ptr_Pal_SLZ:		palp	Pal_SLZ,v_pal_dry+$20,$30		; 7 - SLZ
ptr_Pal_SYZ:		palp	Pal_SYZ,v_pal_dry+$20,$30		; 8 - SYZ
ptr_Pal_SBZ1:		palp	Pal_SBZ1,v_pal_dry+$20,$30		; 9 - SBZ1
ptr_Pal_Special:	palp	Pal_Special,v_pal_dry,$40		; $A (10) - special stage
ptr_Pal_LZWater:	palp	Pal_LZWater,v_pal_dry,$40		; $B (11) - LZ underwater
ptr_Pal_SBZ3:		palp	Pal_SBZ3,v_pal_dry+$20,$30		; $C (12) - SBZ3
ptr_Pal_SBZ3Water:	palp	Pal_SBZ3Water,v_pal_dry,$40		; $D (13) - SBZ3 underwater
ptr_Pal_SBZ2:		palp	Pal_SBZ2,v_pal_dry+$20,$30		; $E (14) - SBZ2
ptr_Pal_LZSonWater:	palp	Pal_LZSonWater,v_pal_dry,$10	; $F (15) - LZ Sonic underwater
ptr_Pal_SBZ3SonWat:	palp	Pal_SBZ3SonWat,v_pal_dry,$10	; $10 (16) - SBZ3 Sonic underwater
ptr_Pal_SSResult:	palp	Pal_SSResult,v_pal_dry,$40		; $11 (17) - special stage results
ptr_Pal_Continue:	palp	Pal_Continue,v_pal_dry,$20		; $12 (18) - special stage results continue
ptr_Pal_Ending:		palp	Pal_Ending,v_pal_dry,$40		; $13 (19) - ending sequence
ptr_Pal_Menu:		palp	Pal_Menu,v_pal_dry,$40		; 2 - level select
			even

palid_SegaBG:		equ (ptr_Pal_SegaBG-PalPointers)/8
palid_Title:		equ (ptr_Pal_Title-PalPointers)/8
palid_LevelSel:		equ (ptr_Pal_LevelSel-PalPointers)/8
palid_Sonic:		equ (ptr_Pal_Sonic-PalPointers)/8
palid_GHZ:		equ (ptr_Pal_GHZ-PalPointers)/8
palid_LZ:		equ (ptr_Pal_LZ-PalPointers)/8
palid_MZ:		equ (ptr_Pal_MZ-PalPointers)/8
palid_SLZ:		equ (ptr_Pal_SLZ-PalPointers)/8
palid_SYZ:		equ (ptr_Pal_SYZ-PalPointers)/8
palid_SBZ1:		equ (ptr_Pal_SBZ1-PalPointers)/8
palid_Special:		equ (ptr_Pal_Special-PalPointers)/8
palid_LZWater:		equ (ptr_Pal_LZWater-PalPointers)/8
palid_SBZ3:		equ (ptr_Pal_SBZ3-PalPointers)/8
palid_SBZ3Water:	equ (ptr_Pal_SBZ3Water-PalPointers)/8
palid_SBZ2:		equ (ptr_Pal_SBZ2-PalPointers)/8
palid_LZSonWater:	equ (ptr_Pal_LZSonWater-PalPointers)/8
palid_SBZ3SonWat:	equ (ptr_Pal_SBZ3SonWat-PalPointers)/8
palid_SSResult:		equ (ptr_Pal_SSResult-PalPointers)/8
palid_Continue:		equ (ptr_Pal_Continue-PalPointers)/8
palid_Ending:		equ (ptr_Pal_Ending-PalPointers)/8

; ---------------------------------------------------------------------------
; Palette data
; ---------------------------------------------------------------------------
Pal_SegaBG:	incbin	"palette\Sega Background.bin"
Pal_Title:	incbin	"palette\Title Screen.bin"
Pal_LevelSel:	incbin	"palette\Level Select.bin"
Pal_Sonic:	incbin	"palette\Sonic.bin"
Pal_GHZ:	incbin	"palette\Green Hill Zone.bin"
Pal_LZ:		incbin	"palette\Labyrinth Zone.bin"
Pal_LZWater:	incbin	"palette\Labyrinth Zone Underwater.bin"
Pal_MZ:		incbin	"palette\Marble Zone.bin"
Pal_SLZ:	incbin	"palette\Star Light Zone.bin"
Pal_SYZ:	incbin	"palette\Spring Yard Zone.bin"
Pal_SBZ1:	incbin	"palette\SBZ Act 1.bin"
Pal_SBZ2:	incbin	"palette\SBZ Act 2.bin"
Pal_Special:	incbin	"palette\Special Stage.bin"
Pal_SBZ3:	incbin	"palette\SBZ Act 3.bin"
Pal_SBZ3Water:	incbin	"palette\SBZ Act 3 Underwater.bin"
Pal_LZSonWater:	incbin	"palette\Sonic - LZ Underwater.bin"
Pal_SBZ3SonWat:	incbin	"palette\Sonic - SBZ3 Underwater.bin"
Pal_SSResult:	incbin	"palette\Special Stage Results.bin"
Pal_Continue:	incbin	"palette\Special Stage Continue Bonus.bin"
Pal_Ending:	incbin	"palette\Ending.bin"

; ---------------------------------------------------------------------------
; Subroutine to wait for VBlank routines to complete
; ---------------------------------------------------------------------------

; DelayProgram:
WaitForVBla:
		enable_ints

	@wait:
		tst.b	(v_vbla_routine).w ; has VBlank routine finished?
		bne.s	@wait		; if not, branch
		rts
; End of function WaitForVBla

; ---------------------------------------------------------------------------
; Subroutine to generate a pseudo-random number	in d0
; ---------------------------------------------------------------------------

RandomNumber:
		move.l	(v_random).w,d1
		bne.s	@scramble	; if d1 is not 0, branch
		move.l	#$2A6D365A,d1	; if d1 is 0, use seed number

	@scramble:
		move.l	d1,d0
		asl.l	#2,d1
		add.l	d0,d1
		asl.l	#3,d1
		add.l	d0,d1
		move.w	d1,d0
		swap	d1
		add.w	d1,d0
		move.w	d0,d1
		swap	d1
		move.l	d1,(v_random).w
		rts

; ---------------------------------------------------------------------------
; Subroutine calculate a sine

; input:
; d0 = angle

; output:
; d0 = sine
; d1 = cosine
; ---------------------------------------------------------------------------

CalcSine:
		andi.w	#$FF,d0
		add.w	d0,d0
		addi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d1
		subi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d0
		rts
; End of function CalcSine

; ===========================================================================

Sine_Data:	incbin	"misc\sinewave.bin"	; values for a 360° sine wave

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine calculate an angle

; input:
; d1 = x-axis distance
; d2 = y-axis distance

; output:
; d0 = angle
; ---------------------------------------------------------------------------

CalcAngle:
		movem.l	d3-d4,-(sp)
		moveq	#0,d3
		moveq	#0,d4
		move.w	d1,d3
		move.w	d2,d4
		or.w	d3,d4
		beq.s	loc_2D04
		move.w	d2,d4
		tst.w	d3
		bpl.w	loc_2CC2
		neg.w	d3

loc_2CC2:
		tst.w	d4
		bpl.w	loc_2CCA
		neg.w	d4

loc_2CCA:
		cmp.w	d3,d4
		bhs.w	loc_2CDC
		lsl.l	#8,d4
		divu.w	d3,d4
		moveq	#0,d0
		move.b	Angle_Data(pc,d4.w),d0
		bra.s	loc_2CE6
; ===========================================================================

loc_2CDC:
		lsl.l	#8,d3
		divu.w	d4,d3
		moveq	#$40,d0
		sub.b	Angle_Data(pc,d3.w),d0

loc_2CE6:
		tst.w	d1
		bpl.w	loc_2CF2
		neg.w	d0
		addi.w	#$80,d0

loc_2CF2:
		tst.w	d2
		bpl.w	loc_2CFE
		neg.w	d0
		addi.w	#$100,d0

loc_2CFE:
		movem.l	(sp)+,d3-d4
		rts
; ===========================================================================

loc_2D04:
		move.w	#$40,d0
		movem.l	(sp)+,d3-d4
		rts
; End of function CalcAngle

; ===========================================================================

Angle_Data:	incbin	"misc\angles.bin"

; ===========================================================================

; ---------------------------------------------------------------------------
; Sega screen
; ---------------------------------------------------------------------------

; SegaScreen:
GM_Sega:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; use 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8700,(a6)	; set background colour (palette entry 0)
		move.w	#$8B00,(a6)	; full-screen vertical scrolling
		clr.b	(f_wtr_state).w
		disable_ints
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		locVRAM	0
		lea	(Nem_SegaLogo).l,a0 ; load Sega logo patterns
		bsr.w	NemDec
		lea	(v_256x256).l,a1
		lea	(Eni_SegaLogo).l,a0 ; load Sega logo mappings
		move.w	#0,d0
		bsr.w	EniDec

		copyTilemap	v_256x256,$E510,$17,7
		copyTilemap	(v_256x256+$180),$C000,$27,$1B

		tst.b   (v_megadrive).w	; is console Japanese?
		bmi.s   @loadpal
		copyTilemap	(v_256x256+$A40),$C53A,2,1 ; hide "TM" with a white rectangle

	@loadpal:
		moveq	#palid_SegaBG,d0
		bsr.w	PalLoad2	; load Sega logo palette
		move.w	#-$A,(v_pcyc_num).w
		move.w	#0,(v_pcyc_time).w
		move.w	#0,(v_pal_buffer+$12).w
		move.w	#0,(v_pal_buffer+$10).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l

Sega_WaitPal:
		move.b	#2,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	PalCycle_Sega
		bne.s	Sega_WaitPal

		move.b	#sfx_Sega,d0
		bsr.w	PlaySound_Special	; play "SEGA" sound
		move.b	#$14,(v_vbla_routine).w
		bsr.w	WaitForVBla
		move.w  #$1E+2*60,(v_demolength).w


Sega_WaitEnd:
		move.b	#2,(v_vbla_routine).w
		bsr.w	WaitForVBla
		tst.w	(v_demolength).w
		beq.s	Sega_GotoTitle
		andi.b	#btnStart,(v_jpadpress1).w ; is Start button pressed?
		beq.s	Sega_WaitEnd	; if not, branch

Sega_GotoTitle:
		move.b	#id_Title,(v_gamemode).w ; go to title screen
		rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Title screen
; ---------------------------------------------------------------------------

; TitleScreen:
GM_Title:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		disable_ints
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)	; 64-cell hscroll size
		move.w	#$9200,(a6)	; window vertical position
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)	; set background colour (palette line 2, entry 0)
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

	Tit_ClrObj1:
		move.l	d0,(a1)+
		dbf	d1,Tit_ClrObj1	; fill object space ($D000-$EFFF) with 0

		locVRAM	0
		lea	(Nem_JapNames).l,a0 ; load Japanese credits
		bsr.w	NemDec
		locVRAM	$14C0
		lea	(Nem_CreditText).l,a0 ; load alphabet
		bsr.w	NemDec
		lea	(v_256x256).l,a1
		lea	(Eni_JapNames).l,a0 ; load mappings for Japanese credits
		move.w	#0,d0
		bsr.w	EniDec

		copyTilemap	v_256x256,$C000,$27,$1B

		lea	(v_pal_dry_dup).w,a1
		moveq	#cBlack,d0
		move.w	#$1F,d1

	Tit_ClrPal:
		move.l	d0,(a1)+
		dbf	d1,Tit_ClrPal	; fill palette with 0 (black)

		moveq	#palid_Sonic,d0	; load Sonic's palette
		bsr.w	PalLoad1
		move.b	#id_CreditsText,(v_sonicteam).w ; load "SONIC TEAM PRESENTS" object
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		bsr.w	PaletteFadeIn
		disable_ints
		locVRAM	$4000
		lea	(Nem_TitleFg).l,a0 ; load title screen patterns
		bsr.w	NemDec
		locVRAM	$6000
		lea	(Nem_TitleSonic).l,a0 ; load Sonic title screen	patterns
		bsr.w	NemDec
		locVRAM	$A200
		lea	(Nem_TitleTM).l,a0 ; load "TM" patterns
		bsr.w	NemDec
		lea	(vdp_data_port).l,a6
		locVRAM	$D000,4(a6)
		lea	(Art_Text).l,a5	; load level select font
		move.w	#$28F,d1

	Tit_LoadText:
		move.w	(a5)+,(a6)
		dbf	d1,Tit_LoadText	; load level select font

		move.b	#0,(v_lastlamp).w ; clear lamppost counter
		move.w	#0,(v_debuguse).w ; disable debug item placement mode
		move.w	#0,(f_demo).w	; disable debug mode
		move.w	#0,($FFFFFFEA).w ; unused variable
		move.w	#(id_GHZ<<8),(v_zone).w	; set level to GHZ (00)
		move.w	#0,(v_pcyc_time).w ; disable palette cycling
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers
		lea	(v_16x16).w,a1
		lea	(Blk16_GHZ).l,a0 ; load GHZ 16x16 mappings
		move.w	#0,d0
		bsr.w	EniDec
		lea	(Blk256_GHZ).l,a0 ; load GHZ 256x256 mappings
		lea	(v_256x256).l,a1
		bsr.w	KosDec
		bsr.w	LevelLayoutLoad
		bsr.w	PaletteFadeOut
		disable_ints
		bsr.w	ClearScreen
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2
		bsr.w	DrawChunks
		lea	(v_256x256).l,a1
		lea	(Eni_Title).l,a0 ; load title screen mappings
		move.w	#0,d0
		bsr.w	EniDec

		copyTilemap	v_256x256,$C206,$21,$15

		locVRAM	0
		lea	(Nem_GHZ_1st).l,a0 ; load GHZ patterns
		bsr.w	NemDec
		moveq	#palid_Title,d0	; load title screen palette
		bsr.w	PalLoad1
		move.b	#bgm_Title,d0
		bsr.w	PlaySound_Special	; play title screen music
	if def(CheatsDefault)=0
		move.b	#0,(f_debugmode).w ; disable debug mode
	endif
		move.w	#$178,(v_demolength).w ; run title screen for $178 frames

		lea	(v_sonicteam).w,a1
		moveq	#0,d0
		move.w	#$F,d1			; was 7, changed to $F to fix the PRESS START BUTTON bug
	Tit_ClrObj2:
		move.l	d0,(a1)+
		dbf	d1,Tit_ClrObj2

		move.b	#id_TitleSonic,(v_titlesonic).w ; load big Sonic object
		move.b	#id_PSBTM,(v_pressstart).w ; load "PRESS START BUTTON" object

		tst.b   (v_megadrive).w	; is console Japanese?
		bpl.s   @isjap		; if yes, branch

		move.b	#id_PSBTM,(v_titletm).w ; load "TM" object
		move.b	#3,(v_titletm+obFrame).w
	@isjap:
		move.b	#id_PSBTM,(v_ttlsonichide).w ; load object which hides part of Sonic
		move.b	#2,(v_ttlsonichide+obFrame).w
		jsr	(ExecuteObjects).l
		bsr.w	DeformLayers
		jsr	(BuildSprites).l
		moveq	#plcid_Main,d0
		bsr.w	NewPLC
		move.w	#0,(v_title_dcount).w
		move.w	#0,(v_title_ccount).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	PaletteFadeIn
; ---------------------------------------------------------------------------

Tit_MainLoop:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr	(ExecuteObjects).l
		bsr.w	DeformLayers
		jsr	(BuildSprites).l
		bsr.w	PalCycle_Title
		bsr.w	RunPLC
		move.w	(v_objspace+obX).w,d0
		addq.w	#2,d0
		move.w	d0,(v_objspace+obX).w ; move Sonic to the right
		cmpi.w	#$1C00,d0	; has Sonic object passed $1C00 on x-axis?
		blo.s	Tit_ChkRegion	; if not, branch

		move.b	#id_Sega,(v_gamemode).w ; go to Sega screen
		rts
; ===========================================================================

Tit_ChkRegion:
		tst.b	(v_megadrive).w	; check if the machine is US or	Japanese
		bpl.s	Tit_RegionJap	; if Japanese, branch

		lea	(LevSelCode_US).l,a0 ; load US code
		bra.s	Tit_EnterCheat

	Tit_RegionJap:
		lea	(LevSelCode_J).l,a0 ; load J code

Tit_EnterCheat:
		move.w	(v_title_dcount).w,d0
		adda.w	d0,a0
		move.b	(v_jpadpress1).w,d0 ; get button press
		andi.b	#btnDir,d0	; read only UDLR buttons
		cmp.b	(a0),d0		; does button press match the cheat code?
		bne.s	Tit_ResetCheat	; if not, branch
		addq.w	#1,(v_title_dcount).w ; next button press
		tst.b	d0
		bne.s	Tit_CountC
		lea	(f_levselcheat).w,a0
		move.w	(v_title_ccount).w,d1
		lsr.w	#1,d1
		andi.w	#3,d1
		beq.s	Tit_PlayRing
		tst.b	(v_megadrive).w
		bpl.s	Tit_PlayRing
		moveq	#1,d1
		move.b	d1,1(a0,d1.w)	; cheat depends on how many times C is pressed

	Tit_PlayRing:
		move.b	#1,(a0,d1.w)	; activate cheat
		move.b	#sfx_Ring,d0
		bsr.w	PlaySound_Special	; play ring sound when code is entered
		bra.s	Tit_CountC
; ===========================================================================

Tit_ResetCheat:
		tst.b	d0
		beq.s	Tit_CountC
		cmpi.w	#9,(v_title_dcount).w
		beq.s	Tit_CountC
		move.w	#0,(v_title_dcount).w ; reset UDLR counter

Tit_CountC:
		move.b	(v_jpadpress1).w,d0
		andi.b	#btnC,d0	; is C button pressed?
		beq.s	loc_3230	; if not, branch
		addq.w	#1,(v_title_ccount).w ; increment C counter

loc_3230:
		tst.w	(v_demolength).w
		beq.w	GotoDemo
		andi.b	#btnStart,(v_jpadpress1).w ; check if Start is pressed
		beq.w	Tit_MainLoop	; if not, branch

Tit_ChkLevSel:
		tst.b	(f_levselcheat).w ; check if level select code is on
		beq.w	PlayLevel	; if not, play level
		btst	#bitA,(v_jpadhold1).w ; check if A is pressed
		beq.w	PlayLevel	; if not, play level
		jmp	Level_Select_Menu	; Go to Sonic 2 Level Select
		moveq	#palid_LevelSel,d0
		bsr.w	PalLoad2	; load level select palette
		lea	(v_hscrolltablebuffer).w,a1
		moveq	#0,d0
		move.w	#$DF,d1

	Tit_ClrScroll1:
		move.l	d0,(a1)+
		dbf	d1,Tit_ClrScroll1 ; clear scroll data (in RAM)

		move.l	d0,(v_scrposy_vdp).w
		disable_ints
		lea	(vdp_data_port).l,a6
		locVRAM	$E000
		move.w	#$3FF,d1

	Tit_ClrScroll2:
		move.l	d0,(a6)
		dbf	d1,Tit_ClrScroll2 ; clear scroll data (in VRAM)

		bsr.w	LevSelTextLoad

; ---------------------------------------------------------------------------
; Level Select
; ---------------------------------------------------------------------------

LevelSelect:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	LevSelControls
		bsr.w	RunPLC
		tst.l	(v_plc_buffer).w
		bne.s	LevelSelect
		andi.b	#btnABC+btnStart,(v_jpadpress1).w ; is A, B, C, or Start pressed?
		beq.s	LevelSelect	; if not, branch
		move.w	(v_levselitem).w,d0
		cmpi.w	#$14,d0		; have you selected item $14 (sound test)?
		bne.s	LevSel_Level_SS	; if not, go to Level/SS subroutine
		move.w	(v_levselsound).w,d0
		addi.w	#$80,d0
		tst.b	(f_creditscheat).w ; is Japanese Credits cheat on?
		beq.s	LevSel_NoCheat	; if not, branch
		cmpi.w	#$9F,d0		; is sound $9F being played?
		beq.s	LevSel_Ending	; if yes, branch
		cmpi.w	#$9E,d0		; is sound $9E being played?
		beq.s	LevSel_Credits	; if yes, branch

LevSel_NoCheat:
		; This is a workaround for a bug; see PlaySoundID for more.
		; Once you've fixed the bugs there, comment these four instructions out.
		cmpi.w	#bgm__Last+1,d0	; is sound $80-$93 being played?
		blo.s	LevSel_PlaySnd	; if yes, branch
		cmpi.w	#sfx__First,d0	; is sound $94-$9F being played?
		blo.s	LevelSelect	; if yes, branch

LevSel_PlaySnd:
		bsr.w	PlaySound_Special
		bra.s	LevelSelect
; ===========================================================================

LevSel_Ending:
		move.b	#id_Ending,(v_gamemode).w ; set screen mode to $18 (Ending)
		move.w	#(id_EndZ<<8),(v_zone).w ; set level to 0600 (Ending)
		rts
; ===========================================================================

LevSel_Credits:
		move.b	#id_Credits,(v_gamemode).w ; set screen mode to $1C (Credits)
		move.b	#bgm_Credits,d0
		bsr.w	PlaySound_Special ; play credits music
		move.w	#0,(v_creditsnum).w
		rts
; ===========================================================================

LevSel_Level_SS:
		add.w	d0,d0
		move.w	LevSel_Ptrs(pc,d0.w),d0 ; load level number
		bmi.w	LevelSelect
		cmpi.w	#id_SS*$100,d0	; check if level is 0700 (Special Stage)
		bne.s	LevSel_Level	; if not, branch
		move.b	#id_Special,(v_gamemode).w ; set screen mode to $10 (Special Stage)
		clr.w	(v_zone).w	; clear level
		move.b	#3,(v_lives).w	; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.l	d0,(v_score).w	; clear score
		move.l	#5000,(v_scorelife).w ; extra life is awarded at 50000 points
		rts
; ===========================================================================

LevSel_Level:
		andi.w	#$3FFF,d0
		move.w	d0,(v_zone).w	; set level number

PlayLevel:
		move.b	#id_Level,(v_gamemode).w ; set screen mode to $0C (level)
		move.b	#3,(v_lives).w	; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.l	d0,(v_score).w	; clear score
		move.b	d0,(v_lastspecial).w ; clear special stage number
		move.b	d0,(v_emeralds).w ; clear emeralds
		move.l	d0,(v_emldlist).w ; clear emeralds
		move.l	d0,(v_emldlist+4).w ; clear emeralds
		move.b	d0,(v_continues).w ; clear continues
		move.l	#5000,(v_scorelife).w ; extra life is awarded at 50000 points
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special ; fade out music
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Level select - level pointers
; ---------------------------------------------------------------------------
LevSel_Ptrs:
		dc.b id_GHZ, 0
		dc.b id_GHZ, 1
		dc.b id_GHZ, 2
		dc.b id_MZ, 0
		dc.b id_MZ, 1
		dc.b id_MZ, 2
		dc.b id_SYZ, 0
		dc.b id_SYZ, 1
		dc.b id_SYZ, 2
		dc.b id_LZ, 0
		dc.b id_LZ, 1
		dc.b id_LZ, 2
		dc.b id_SLZ, 0
		dc.b id_SLZ, 1
		dc.b id_SLZ, 2
		dc.b id_SBZ, 0
		dc.b id_SBZ, 1
		dc.b id_LZ, 3
		dc.b id_SBZ, 2
		dc.b id_SS, 0		; Special Stage
		dc.w $8000		; Sound Test
		even
; ---------------------------------------------------------------------------
; Level select codes
; ---------------------------------------------------------------------------
LevSelCode_J:	dc.b btnUp,btnDn,btnDn,btnDn,btnL,btnR,0,$FF
		even

LevSelCode_US:	dc.b btnUp,btnDn,btnL,btnR,0,$FF
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Demo mode
; ---------------------------------------------------------------------------

; Demo:
GotoDemo:
		move.w	#$1E,(v_demolength).w

loc_33B6:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	DeformLayers
		bsr.w	PaletteCycle
		bsr.w	RunPLC
		move.w	(v_objspace+obX).w,d0
		addq.w	#2,d0
		move.w	d0,(v_objspace+obX).w
		cmpi.w	#$1C00,d0
		blo.s	loc_33E4
		move.b	#id_Sega,(v_gamemode).w
		rts
; ===========================================================================

loc_33E4:
		andi.b	#btnStart,(v_jpadpress1).w ; is Start button pressed?
		bne.w	Tit_ChkLevSel	; if yes, branch
		tst.w	(v_demolength).w
		bne.w	loc_33B6
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special ; fade out music
		move.w	(v_demonum).w,d0 ; load demo number
		andi.w	#7,d0
		add.w	d0,d0
		move.w	Demo_Levels(pc,d0.w),d0	; load level number for demo
		move.w	d0,(v_zone).w
		addq.w	#1,(v_demonum).w ; add 1 to demo number
		cmpi.w	#4,(v_demonum).w ; is demo number less than 4?
		blo.s	loc_3422	; if yes, branch
		move.w	#0,(v_demonum).w ; reset demo number to 0

loc_3422:
		move.w	#1,(f_demo).w	; turn demo mode on
		move.b	#id_Demo,(v_gamemode).w ; set screen mode to 08 (demo)
		cmpi.w	#$600,d0	; is level number 0600 (special stage)?
		bne.s	Demo_Level	; if not, branch
		move.b	#id_Special,(v_gamemode).w ; set screen mode to $10 (Special Stage)
		clr.w	(v_zone).w	; clear level number
		clr.b	(v_lastspecial).w ; clear special stage number

Demo_Level:
		move.b	#3,(v_lives).w	; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.l	d0,(v_score).w	; clear score
		move.l	#5000,(v_scorelife).w ; extra life is awarded at 50000 points
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Levels used in demos
; ---------------------------------------------------------------------------
Demo_Levels:	incbin	"misc\Demo Level Order - Intro.bin"
		even

; ---------------------------------------------------------------------------
; Subroutine to change what you're selecting in the level select
; ---------------------------------------------------------------------------

LevSelControls:
		move.b	(v_jpadpress1).w,d1
		andi.b	#btnUp+btnDn,d1	; is up/down pressed and held?
		bne.s	LevSel_UpDown	; if yes, branch
		subq.w	#1,(v_levseldelay).w ; subtract 1 from time to next move
		bpl.s	LevSel_SndTest	; if time remains, branch

LevSel_UpDown:
		move.w	#$B,(v_levseldelay).w ; reset time delay
		move.b	(v_jpadhold1).w,d1
		andi.b	#btnUp+btnDn,d1	; is up/down pressed?
		beq.s	LevSel_SndTest	; if not, branch
		move.w	(v_levselitem).w,d0
		btst	#bitUp,d1	; is up pressed?
		beq.s	LevSel_Down	; if not, branch
		subq.w	#1,d0		; move up 1 selection
		bhs.s	LevSel_Down
		moveq	#$14,d0		; if selection moves below 0, jump to selection $14

LevSel_Down:
		btst	#bitDn,d1	; is down pressed?
		beq.s	LevSel_Refresh	; if not, branch
		addq.w	#1,d0		; move down 1 selection
		cmpi.w	#$15,d0
		blo.s	LevSel_Refresh
		moveq	#0,d0		; if selection moves above $14, jump to	selection 0

LevSel_Refresh:
		move.w	d0,(v_levselitem).w ; set new selection
		bsr.w	LevSelTextLoad	; refresh text
		rts
; ===========================================================================

LevSel_SndTest:
		cmpi.w	#$14,(v_levselitem).w ; is item $14 selected?
		bne.s	LevSel_NoMove	; if not, branch
		move.b	(v_jpadpress1).w,d1
		andi.b	#btnR+btnL,d1	; is left/right pressed?
		beq.s	LevSel_NoMove	; if not, branch
		move.w	(v_levselsound).w,d0
		btst	#bitL,d1	; is left pressed?
		beq.s	LevSel_Right	; if not, branch
		subq.w	#1,d0		; subtract 1 from sound test
		bhs.s	LevSel_Right
		moveq	#$4F,d0		; if sound test moves below 0, set to $4F

LevSel_Right:
		btst	#bitR,d1	; is right pressed?
		beq.s	LevSel_Refresh2	; if not, branch
		addq.w	#1,d0		; add 1 to sound test
		cmpi.w	#$50,d0
		blo.s	LevSel_Refresh2
		moveq	#0,d0		; if sound test moves above $4F, set to	0

LevSel_Refresh2:
		move.w	d0,(v_levselsound).w ; set sound test number
		bsr.w	LevSelTextLoad	; refresh text

LevSel_NoMove:
		rts
; End of function LevSelControls

; ---------------------------------------------------------------------------
; Subroutine to load level select text
; ---------------------------------------------------------------------------

LevSelTextLoad:

	textpos:	= ($40000000+(($E210&$3FFF)<<16)+(($E210&$C000)>>14))
					; $E210 is a VRAM address

		lea	(LevelMenuText).l,a1
		lea	(vdp_data_port).l,a6
		move.l	#textpos,d4	; text position on screen
		move.w	#$E680,d3	; VRAM setting (4th palette, $680th tile)
		moveq	#$14,d1		; number of lines of text

	LevSel_DrawAll:
		move.l	d4,4(a6)
		bsr.w	LevSel_ChgLine	; draw line of text
		addi.l	#$800000,d4	; jump to next line
		dbf	d1,LevSel_DrawAll

		moveq	#0,d0
		move.w	(v_levselitem).w,d0
		move.w	d0,d1
		move.l	#textpos,d4
		lsl.w	#7,d0
		swap	d0
		add.l	d0,d4
		lea	(LevelMenuText).l,a1
		lsl.w	#3,d1
		move.w	d1,d0
		add.w	d1,d1
		add.w	d0,d1
		adda.w	d1,a1
		move.w	#$C680,d3	; VRAM setting (3rd palette, $680th tile)
		move.l	d4,4(a6)
		bsr.w	LevSel_ChgLine	; recolour selected line
		move.w	#$E680,d3
		cmpi.w	#$14,(v_levselitem).w
		bne.s	LevSel_DrawSnd
		move.w	#$C680,d3

LevSel_DrawSnd:
		locVRAM	$EC30		; sound test position on screen
		move.w	(v_levselsound).w,d0
		addi.w	#$80,d0
		move.b	d0,d2
		lsr.b	#4,d0
		bsr.w	LevSel_ChgSnd	; draw 1st digit
		move.b	d2,d0
		bsr.w	LevSel_ChgSnd	; draw 2nd digit
		rts
; End of function LevSelTextLoad

LevSel_ChgSnd:
		andi.w	#$F,d0
		cmpi.b	#$A,d0		; is digit $A-$F?
		blo.s	LevSel_Numb	; if not, branch
		addi.b	#7,d0		; use alpha characters

	LevSel_Numb:
		add.w	d3,d0
		move.w	d0,(a6)
		rts
; End of function LevSel_ChgSnd

LevSel_ChgLine:
		moveq	#$17,d2		; number of characters per line

	LevSel_LineLoop:
		moveq	#0,d0
		move.b	(a1)+,d0	; get character
		bpl.s	LevSel_CharOk	; branch if valid
		move.w	#0,(a6)		; use blank character
		dbf	d2,LevSel_LineLoop
		rts

	LevSel_CharOk:
		add.w	d3,d0		; combine char with VRAM setting
		move.w	d0,(a6)		; send to VRAM
		dbf	d2,LevSel_LineLoop
		rts
; End of function LevSel_ChgLine

; ===========================================================================
; ---------------------------------------------------------------------------
; Level select menu text
; ---------------------------------------------------------------------------
LevelMenuText:	incbin	"misc\Level Select Text.bin"
		even
; ---------------------------------------------------------------------------
; Music playlist
; ---------------------------------------------------------------------------
MusicList:
		dc.b bgm_GHZ	; GHZ
		dc.b bgm_LZ	; LZ
		dc.b bgm_MZ	; MZ
		dc.b bgm_SLZ	; SLZ
		dc.b bgm_SYZ	; SYZ
		dc.b bgm_SBZ	; SBZ
		dc.b bgm_FZ	; Ending
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

; Level:
GM_Level:
		bset	#7,(v_gamemode).w ; add $80 to screen mode (for pre level sequence)
		tst.w	(f_demo).w
		bmi.s	Level_NoMusicFade
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special ; fade out music

	Level_NoMusicFade:
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		tst.w	(f_demo).w	; is an ending sequence demo running?
		bmi.s	Level_ClrRam	; if yes, branch
		disable_ints
		locVRAM	$B000
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		enable_ints
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea	(LevelHeaders).l,a2
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	loc_37FC
		bsr.w	AddPLC		; load level patterns

loc_37FC:
		moveq	#plcid_Main2,d0
		bsr.w	AddPLC		; load standard patterns

Level_ClrRam:
		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

	Level_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrObjRam ; clear object RAM

		lea	(v_vbla_0e_counter).w,a1
		moveq	#0,d0
		move.w	#$15,d1

	Level_ClrVars1:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars1 ; clear misc variables

		lea	(v_screenposx).w,a1
		moveq	#0,d0
		move.w	#$3F,d1

	Level_ClrVars2:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars2 ; clear misc variables

		lea	(v_oscillate+2).w,a1
		moveq	#0,d0
		move.w	#$47,d1

	Level_ClrVars3:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars3 ; clear object variables

		disable_ints
		bsr.w	ClearScreen
		lea	(vdp_control_port).l,a6
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8500+(vram_sprites>>9),(a6) ; set sprite table address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		move.w	#$8004,(a6)		; 8-colour mode
		move.w	#$8720,(a6)		; set background colour (line 3; colour 0)
		move.w	#$8A00+223,(v_hbla_hreg).w ; set palette change position (for water)
		move.w	(v_hbla_hreg).w,(a6)
		cmpi.b	#id_LZ,(v_zone).w ; is level LZ?
		bne.s	Level_LoadPal	; if not, branch

		move.w	#$8014,(a6)	; enable H-interrupts
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		lea	(WaterHeight).l,a1 ; load water height array
		move.w	(a1,d0.w),d0
		move.w	d0,(v_waterpos1).w ; set water heights
		move.w	d0,(v_waterpos2).w
		move.w	d0,(v_waterpos3).w
		clr.b	(v_wtr_routine).w ; clear water routine counter
		clr.b	(f_wtr_state).w	; clear water state
		move.b	#1,(f_water).w	; enable water

Level_LoadPal:
		move.w	#30,(v_air).w
		enable_ints
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad2	; load Sonic's palette
		cmpi.b	#id_LZ,(v_zone).w ; is level LZ?
		bne.s	Level_GetBgm	; if not, branch

		moveq	#palid_LZSonWater,d0 ; palette number $F (LZ)
		cmpi.b	#3,(v_act).w	; is act number 3?
		bne.s	Level_WaterPal	; if not, branch
		moveq	#palid_SBZ3SonWat,d0 ; palette number $10 (SBZ3)

	Level_WaterPal:
		bsr.w	PalLoad3_Water	; load underwater palette
		tst.b	(v_lastlamp).w
		beq.s	Level_GetBgm
		move.b	(v_lamp_wtrstat).w,(f_wtr_state).w

Level_GetBgm:
		tst.w	(f_demo).w
		bmi.s	Level_SkipTtlCard
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w ; is level SBZ3?
		bne.s	Level_BgmNotLZ4	; if not, branch
		moveq	#5,d0		; use 5th music (SBZ)

	Level_BgmNotLZ4:
		cmpi.w	#(id_SBZ<<8)+2,(v_zone).w ; is level FZ?
		bne.s	Level_PlayBgm	; if not, branch
		moveq	#6,d0		; use 6th music (FZ)

	Level_PlayBgm:
		lea	(MusicList).l,a1 ; load music playlist
		move.b	(a1,d0.w),d0
		bsr.w	PlaySound	; play music
		move.b	#id_TitleCard,(v_titlecard).w ; load title card object

Level_TtlCardLoop:
		move.b	#$C,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		bsr.w	RunPLC
		move.w	(v_ttlcardact+obX).w,d0
		cmp.w	(v_ttlcardact+card_mainX).w,d0 ; has title card sequence finished?
		bne.s	Level_TtlCardLoop ; if not, branch
		tst.l	(v_plc_buffer).w ; are there any items in the pattern load cue?
		bne.s	Level_TtlCardLoop ; if yes, branch
		jsr	(Hud_Base).l	; load basic HUD gfx

	Level_SkipTtlCard:
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad1	; load Sonic's palette
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers
		bset	#2,(v_fg_scroll_flags).w
		bsr.w	LevelDataLoad ; load block mappings and palettes
		bsr.w	LoadTilesFromStart
		jsr	(ConvertCollisionArray).l
		bsr.w	ColIndexLoad
		bsr.w	LZWaterFeatures
		move.b	#id_SonicPlayer,(v_player).w ; load Sonic object
		tst.w	(f_demo).w
		bmi.s	Level_ChkDebug
		move.b	#id_HUD,(v_hud).w ; load HUD object

Level_ChkDebug:
		tst.b	(f_debugcheat).w ; has debug cheat been entered?
		beq.s	Level_ChkWater	; if not, branch
		btst	#bitA,(v_jpadhold1).w ; is A button held?
		beq.s	Level_ChkWater	; if not, branch
		move.b	#1,(f_debugmode).w ; enable debug mode

Level_ChkWater:
		move.w	#0,(v_jpadhold2).w
		move.w	#0,(v_jpadhold1).w
		cmpi.b	#id_LZ,(v_zone).w ; is level LZ?
		bne.s	Level_LoadObj	; if not, branch
		move.b	#id_WaterSurface,(v_watersurface1).w ; load water surface object
		move.w	#$60,(v_watersurface1+obX).w
		move.b	#id_WaterSurface,(v_watersurface2).w
		move.w	#$120,(v_watersurface2+obX).w

Level_LoadObj:
		jsr	(ObjPosLoad).l
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		moveq	#0,d0
		tst.b	(v_lastlamp).w	; are you starting from a lamppost?
		bne.s	Level_SkipClr	; if yes, branch
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.b	d0,(v_lifecount).w ; clear lives counter

	Level_SkipClr:
		move.b	d0,(f_timeover).w
		move.b	d0,(v_shield).w	; clear shield
		move.b	d0,(v_invinc).w	; clear invincibility
		move.b	d0,(v_shoes).w	; clear speed shoes
		move.b	d0,($FFFFFE2F).w
		move.w	d0,(v_debuguse).w
		move.w	d0,(f_restart).w
		move.w	d0,(v_framecount).w
		bsr.w	OscillateNumInit
		move.b	#1,(f_scorecount).w ; update score counter
		move.b	#1,(f_ringcount).w ; update rings counter
		move.b	#1,(f_timecount).w ; update time counter
		move.w	#0,(v_btnpushtime1).w
		lea	(DemoDataPtr).l,a1 ; load demo data
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		tst.w	(f_demo).w	; is demo mode on?
		bpl.s	Level_Demo	; if yes, branch
		lea	(DemoEndDataPtr).l,a1 ; load ending demo data
		move.w	(v_creditsnum).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1

Level_Demo:
		move.b	1(a1),(v_btnpushtime2).w ; load key press duration
		subq.b	#1,(v_btnpushtime2).w ; subtract 1 from duration
		move.w	#1800,(v_demolength).w
		tst.w	(f_demo).w
		bpl.s	Level_ChkWaterPal
		move.w	#540,(v_demolength).w
		cmpi.w	#4,(v_creditsnum).w
		bne.s	Level_ChkWaterPal
		move.w	#510,(v_demolength).w

Level_ChkWaterPal:
		cmpi.b	#id_LZ,(v_zone).w ; is level LZ/SBZ3?
		bne.s	Level_Delay	; if not, branch
		moveq	#palid_LZWater,d0 ; palette $B (LZ underwater)
		cmpi.b	#3,(v_act).w	; is level SBZ3?
		bne.s	Level_WtrNotSbz	; if not, branch
		moveq	#palid_SBZ3Water,d0 ; palette $D (SBZ3 underwater)

	Level_WtrNotSbz:
		bsr.w	PalLoad4_Water

Level_Delay:
		move.w	#3,d1

	Level_DelayLoop:
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		dbf	d1,Level_DelayLoop

		move.w	#$202F,(v_pfade_start).w ; fade in 2nd, 3rd & 4th palette lines
		bsr.w	PalFadeIn_Alt
		tst.w	(f_demo).w	; is an ending sequence demo running?
		bmi.s	Level_ClrCardArt ; if yes, branch
		addq.b	#2,(v_ttlcardname+obRoutine).w ; make title card move
		addq.b	#4,(v_ttlcardzone+obRoutine).w
		addq.b	#4,(v_ttlcardact+obRoutine).w
		addq.b	#4,(v_ttlcardoval+obRoutine).w
		bra.s	Level_StartGame
; ===========================================================================

Level_ClrCardArt:
		moveq	#plcid_Explode,d0
		jsr	(AddPLC).l	; load explosion gfx
		moveq	#0,d0
		move.b	(v_zone).w,d0
		addi.w	#plcid_GHZAnimals,d0
		jsr	(AddPLC).l	; load animal gfx (level no. + $15)

Level_StartGame:
		bclr	#7,(v_gamemode).w ; subtract $80 from mode to end pre-level stuff

; ---------------------------------------------------------------------------
; Main level loop (when all title card and loading sequences are finished)
; ---------------------------------------------------------------------------

Level_MainLoop:
		bsr.w	PauseGame
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		addq.w	#1,(v_framecount).w ; add 1 to level timer
		bsr.w	MoveSonicInDemo
		bsr.w	LZWaterFeatures
		jsr	(ExecuteObjects).l
		tst.w	(f_restart).w
		bne.w	GM_Level
		tst.w	(v_debuguse).w	; is debug mode being used?
		bne.s	Level_DoScroll	; if yes, branch
		cmpi.b	#6,(v_player+obRoutine).w ; has Sonic just died?
		bhs.s	Level_SkipScroll ; if yes, branch

	Level_DoScroll:
		bsr.w	DeformLayers

	Level_SkipScroll:
		jsr	(BuildSprites).l
		jsr	(ObjPosLoad).l
		bsr.w	PaletteCycle
		bsr.w	RunPLC
		bsr.w	OscillateNumDo
		bsr.w	SynchroAnimate
		bsr.w	SignpostArtLoad

		cmpi.b	#id_Demo,(v_gamemode).w
		beq.s	Level_ChkDemo	; if mode is 8 (demo), branch
		cmpi.b	#id_Level,(v_gamemode).w
		beq.w	Level_MainLoop	; if mode is $C (level), branch
		rts
; ===========================================================================

Level_ChkDemo:
		tst.w	(f_restart).w	; is level set to restart?
		bne.s	Level_EndDemo	; if yes, branch
		tst.w	(v_demolength).w ; is there time left on the demo?
		beq.s	Level_EndDemo	; if not, branch
		cmpi.b	#id_Demo,(v_gamemode).w
		beq.w	Level_MainLoop	; if mode is 8 (demo), branch
		move.b	#id_Sega,(v_gamemode).w ; go to Sega screen
		rts
; ===========================================================================

Level_EndDemo:
		cmpi.b	#id_Demo,(v_gamemode).w
		bne.s	Level_FadeDemo	; if mode is 8 (demo), branch
		move.b	#id_Sega,(v_gamemode).w ; go to Sega screen
		tst.w	(f_demo).w	; is demo mode on & not ending sequence?
		bpl.s	Level_FadeDemo	; if yes, branch
		move.b	#id_Credits,(v_gamemode).w ; go to credits

Level_FadeDemo:
		move.w	#$3C,(v_demolength).w
		move.w	#$3F,(v_pfade_start).w
		clr.w	(v_palchgspeed).w

	Level_FDLoop:
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	MoveSonicInDemo
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		jsr	(ObjPosLoad).l
		subq.w	#1,(v_palchgspeed).w
		bpl.s	loc_3BC8
		move.w	#2,(v_palchgspeed).w
		bsr.w	FadeOut_ToBlack

loc_3BC8:
		tst.w	(v_demolength).w
		bne.s	Level_FDLoop
		rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to do special water effects in Labyrinth Zone
; ---------------------------------------------------------------------------

; LZWaterEffects:
LZWaterFeatures:
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		bne.s	@notlabyrinth	; if not, branch
		tst.b	(f_nobgscroll).w
		bne.s	@setheight
		cmpi.b	#6,(v_player+obRoutine).w ; has Sonic just died?
		bhs.s	@setheight	; if yes, skip other effects

		bsr.w	LZWindTunnels
		bsr.w	LZWaterSlides
		bsr.w	LZDynamicWater

@setheight:
		clr.b	(f_wtr_state).w
		moveq	#0,d0
		move.b	(v_oscillate+2).w,d0
		lsr.w	#1,d0
		add.w	(v_waterpos2).w,d0
		move.w	d0,(v_waterpos1).w
		move.w	(v_waterpos1).w,d0
		sub.w	(v_screenposy).w,d0
		bhs.s	@isbelow
		tst.w	d0
		bpl.s	@isbelow	; if water is below top of screen, branch

		move.b	#223,(v_hbla_line).w
		move.b	#1,(f_wtr_state).w ; screen is all underwater

	@isbelow:
		cmpi.w	#223,d0		; is water within 223 pixels of top of screen?
		blo.s	@isvisible	; if yes, branch
		move.w	#223,d0

	@isvisible:
		move.b	d0,(v_hbla_line).w ; set water surface as on-screen

@notlabyrinth:
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Initial water heights
; ---------------------------------------------------------------------------
WaterHeight:	dc.w $B8	; Labyrinth 1
		dc.w $328	; Labyrinth 2
		dc.w $900	; Labyrinth 3
		dc.w $228	; Scrap Brain 3
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Labyrinth dynamic water routines
; ---------------------------------------------------------------------------

LZDynamicWater:
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		move.w	DynWater_Index(pc,d0.w),d0
		jsr	DynWater_Index(pc,d0.w)
		moveq	#0,d1
		move.b	(f_water).w,d1
		move.w	(v_waterpos3).w,d0
		sub.w	(v_waterpos2).w,d0
		beq.s	@exit		; if water level is correct, branch
		bhs.s	@movewater	; if water level is too high, branch
		neg.w	d1		; set water to move up instead

	@movewater:
		add.w	d1,(v_waterpos2).w ; move water up/down

	@exit:
		rts
; ===========================================================================
DynWater_Index:	dc.w DynWater_LZ1-DynWater_Index
		dc.w DynWater_LZ2-DynWater_Index
		dc.w DynWater_LZ3-DynWater_Index
		dc.w DynWater_SBZ3-DynWater_Index
; ===========================================================================

DynWater_LZ1:
		move.w	(v_screenposx).w,d0
		move.b	(v_wtr_routine).w,d2
		bne.s	@routine2
		move.w	#$B8,d1		; water height
		cmpi.w	#$600,d0	; has screen reached next position?
		blo.s	@setwater	; if not, branch
		move.w	#$108,d1
		cmpi.w	#$200,(v_player+obY).w ; is Sonic above $200 y-axis?
		blo.s	@sonicishigh	; if yes, branch
		cmpi.w	#$C00,d0
		blo.s	@setwater
		move.w	#$318,d1
		cmpi.w	#$1080,d0
		blo.s	@setwater
		move.b	#$80,(f_switch+5).w
		move.w	#$5C8,d1
		cmpi.w	#$1380,d0
		blo.s	@setwater
		move.w	#$3A8,d1
		cmp.w	(v_waterpos2).w,d1 ; has water reached last height?
		bne.s	@setwater	; if not, branch
		move.b	#1,(v_wtr_routine).w ; use second routine next

	@setwater:
		move.w	d1,(v_waterpos3).w
		rts
; ===========================================================================

@sonicishigh:
		cmpi.w	#$C80,d0
		blo.s	@setwater
		move.w	#$E8,d1
		cmpi.w	#$1500,d0
		blo.s	@setwater
		move.w	#$108,d1
		bra.s	@setwater
; ===========================================================================

@routine2:
		subq.b	#1,d2
		bne.s	@skip
		cmpi.w	#$2E0,(v_player+obY).w ; is Sonic above $2E0 y-axis?
		bhs.s	@skip		; if not, branch
		move.w	#$3A8,d1
		cmpi.w	#$1300,d0
		blo.s	@setwater2
		move.w	#$108,d1
		move.b	#2,(v_wtr_routine).w

	@setwater2:
		move.w	d1,(v_waterpos3).w

	@skip:
		rts
; ===========================================================================

DynWater_LZ2:
		move.w	(v_screenposx).w,d0
		move.w	#$328,d1
		cmpi.w	#$500,d0
		blo.s	@setwater
		move.w	#$3C8,d1
		cmpi.w	#$B00,d0
		blo.s	@setwater
		move.w	#$428,d1

	@setwater:
		move.w	d1,(v_waterpos3).w
		rts
; ===========================================================================

DynWater_LZ3:
		move.w	(v_screenposx).w,d0
		move.b	(v_wtr_routine).w,d2
		bne.s	@routine2

		move.w	#$900,d1
		cmpi.w	#$600,d0	; has screen reached position?
		blo.s	@setwaterlz3	; if not, branch
		cmpi.w	#$3C0,(v_player+obY).w
		blo.s	@setwaterlz3
		cmpi.w	#$600,(v_player+obY).w ; is Sonic in a y-axis range?
		bhs.s	@setwaterlz3	; if not, branch

		move.w	#$4C8,d1	; set new water height
		move.b	#$4B,(v_lvllayout+$106).w ; update level layout
		move.b	#1,(v_wtr_routine).w ; use second routine next
		move.w	#sfx_Rumbling,d0
		bsr.w	PlaySound_Special ; play sound $B7 (rumbling)

	@setwaterlz3:
		move.w	d1,(v_waterpos3).w
		move.w	d1,(v_waterpos2).w ; change water height instantly
		rts
; ===========================================================================

@routine2:
		subq.b	#1,d2
		bne.s	@routine3
		move.w	#$4C8,d1
		cmpi.w	#$770,d0
		blo.s	@setwater2
		move.w	#$308,d1
		cmpi.w	#$1400,d0
		blo.s	@setwater2
		cmpi.w	#$508,(v_waterpos3).w
		beq.s	@sonicislow
		cmpi.w	#$600,(v_player+obY).w ; is Sonic below $600 y-axis?
		bhs.s	@sonicislow	; if yes, branch
		cmpi.w	#$280,(v_player+obY).w
		bhs.s	@setwater2

@sonicislow:
		move.w	#$508,d1
		move.w	d1,(v_waterpos2).w
		cmpi.w	#$1770,d0
		blo.s	@setwater2
		move.b	#2,(v_wtr_routine).w

	@setwater2:
		move.w	d1,(v_waterpos3).w
		rts
; ===========================================================================

@routine3:
		subq.b	#1,d2
		bne.s	@routine4
		move.w	#$508,d1
		cmpi.w	#$1860,d0
		blo.s	@setwater3
		move.w	#$188,d1
		cmpi.w	#$1AF0,d0
		bhs.s	@loc_3DC6
		cmp.w	(v_waterpos2).w,d1
		bne.s	@setwater3

	@loc_3DC6:
		move.b	#3,(v_wtr_routine).w

	@setwater3:
		move.w	d1,(v_waterpos3).w
		rts
; ===========================================================================

@routine4:
		subq.b	#1,d2
		bne.s	@routine5
		move.w	#$188,d1
		cmpi.w	#$1AF0,d0
		blo.s	@setwater4
		move.w	#$900,d1
		cmpi.w	#$1BC0,d0
		blo.s	@setwater4
		move.b	#4,(v_wtr_routine).w
		move.w	#$608,(v_waterpos3).w
		move.w	#$7C0,(v_waterpos2).w
		move.b	#1,(f_switch+8).w
		rts
; ===========================================================================

@setwater4:
		move.w	d1,(v_waterpos3).w
		move.w	d1,(v_waterpos2).w
		rts
; ===========================================================================

@routine5:
		cmpi.w	#$1E00,d0	; has screen passed final position?
		blo.s	@dontset	; if not, branch
		move.w	#$128,(v_waterpos3).w

	@dontset:
		rts
; ===========================================================================

DynWater_SBZ3:
		move.w	#$228,d1
		cmpi.w	#$F00,(v_screenposx).w
		blo.s	@setwater
		move.w	#$4C8,d1

	@setwater:
		move.w	d1,(v_waterpos3).w
		rts

; ---------------------------------------------------------------------------
; Labyrinth Zone "wind tunnels" subroutine
; ---------------------------------------------------------------------------

LZWindTunnels:
		tst.w	(v_debuguse).w	; is debug mode being used?
		bne.w	@quit	; if yes, branch
		lea	(LZWind_Data+8).l,a2
		moveq	#0,d0
		move.b	(v_act).w,d0	; get act number
		lsl.w	#3,d0		; multiply by 8
		adda.w	d0,a2		; add to address for data
		moveq	#0,d1
		tst.b	(v_act).w	; is act number 1?
		bne.s	@notact1	; if not, branch
		moveq	#1,d1
		subq.w	#8,a2		; use different data for act 1

	@notact1:
		lea	(v_player).w,a1

@chksonic:
		move.w	obX(a1),d0
		cmp.w	(a2),d0
		blo.w	@chknext
		cmp.w	4(a2),d0
		bhs.w	@chknext
		move.w	obY(a1),d2
		cmp.w	2(a2),d2
		blo.s	@chknext
		cmp.w	6(a2),d2
		bhs.s	@chknext	; branch if Sonic is outside a range
		move.b	(v_vbla_byte).w,d0
		andi.b	#$3F,d0		; does VInt counter fall on 0, $40, $80 or $C0?
		bne.s	@skipsound	; if not, branch
		move.w	#sfx_Waterfall,d0
		jsr	(PlaySound_Special).l	; play rushing water sound (only every $40 frames)

	@skipsound:
		tst.b	(f_wtunnelallow).w ; are wind tunnels disabled?
		bne.w	@quit	; if yes, branch
		cmpi.b	#4,obRoutine(a1) ; is Sonic hurt/dying?
		bhs.s	@clrquit	; if yes, branch
		move.b	#1,(f_wtunnelmode).w
		subi.w	#$80,d0
		cmp.w	(a2),d0
		bhs.s	@movesonic
		moveq	#2,d0
		cmpi.b	#1,(v_act).w	; is act number 2?
		bne.s	@notact2	; if not, branch
		neg.w	d0

	@notact2:
		add.w	d0,obY(a1)	; adjust Sonic's y-axis for curve of tunnel

@movesonic:
		addq.w	#4,obX(a1)
		move.w	#$400,obVelX(a1) ; move Sonic horizontally
		move.w	#0,obVelY(a1)
		move.b	#id_Float2,obAnim(a1)	; use floating animation
		bset	#1,obStatus(a1)
		btst	#0,(v_jpadhold2).w ; is up pressed?
		beq.s	@down		; if not, branch
		subq.w	#1,obY(a1)	; move Sonic up on pole

	@down:
		btst	#1,(v_jpadhold2).w ; is down being pressed?
		beq.s	@end		; if not, branch
		addq.w	#1,obY(a1)	; move Sonic down on pole

	@end:
		rts
; ===========================================================================

@chknext:
		addq.w	#8,a2		; use second set of values (act 1 only)
		dbf	d1,@chksonic	; on act 1, repeat for a second tunnel
		tst.b	(f_wtunnelmode).w ; is Sonic still in a tunnel?
		beq.s	@quit		; if yes, branch
		move.b	#id_Walk,obAnim(a1)	; use walking animation

@clrquit:
		clr.b	(f_wtunnelmode).w ; finish tunnel

@quit:
		rts
; End of function LZWindTunnels

; ===========================================================================

		;    left, top,  right, bottom boundaries
LZWind_Data:	dc.w $A80, $300, $C10,  $380 ; act 1 values (set 1)
		dc.w $F80, $100, $1410,	$180 ; act 1 values (set 2)
		dc.w $460, $400, $710,  $480 ; act 2 values
		dc.w $A20, $600, $1610, $6E0 ; act 3 values
		dc.w $C80, $600, $13D0, $680 ; SBZ act 3 values
		even

; ---------------------------------------------------------------------------
; Labyrinth Zone water slide subroutine
; ---------------------------------------------------------------------------

LZWaterSlides:
		lea	(v_player).w,a1
		btst	#1,obStatus(a1)	; is Sonic jumping?
		bne.s	loc_3F6A	; if not, branch
		move.w	obY(a1),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		move.b	obX(a1),d1
		andi.w	#$7F,d1
		add.w	d1,d0
		lea	(v_lvllayout).w,a2
		move.b	(a2,d0.w),d0
		lea	Slide_Chunks_End(pc),a2
		moveq	#Slide_Chunks_End-Slide_Chunks-1,d1

loc_3F62:
		cmp.b	-(a2),d0
		dbeq	d1,loc_3F62
		beq.s	LZSlide_Move

loc_3F6A:
		tst.b	(f_slidemode).w
		beq.s	locret_3F7A
		move.w	#5,$3E(a1)
		clr.b	(f_slidemode).w

locret_3F7A:
		rts
; ===========================================================================

LZSlide_Move:
		cmpi.w	#3,d1
		bhs.s	loc_3F84
		nop

loc_3F84:
		bclr	#0,obStatus(a1)
		move.b	Slide_Speeds(pc,d1.w),d0
		move.b	d0,obInertia(a1)
		bpl.s	loc_3F9A
		bset	#0,obStatus(a1)

loc_3F9A:
		clr.b	obInertia+1(a1)
		move.b	#id_WaterSlide,obAnim(a1) ; use Sonic's "sliding" animation
		move.b	#1,(f_slidemode).w	; set water slide flag
		move.b	(v_vbla_byte).w,d0
		andi.b	#$1F,d0
		bne.s	locret_3FBE
		move.w	#sfx_Waterfall,d0
		jsr	(PlaySound_Special).l	; play water sound

locret_3FBE:
		rts
; End of function LZWaterSlides

; ===========================================================================
; byte_3FC0:
Slide_Speeds:
		dc.b $A, $F5, $A, $F6, $F5, $F4, $B
		even

Slide_Chunks:
		dc.b 2, 7, 3, $4C, $4B, 8, 4
; byte_3FCF
Slide_Chunks_End
		even

; ---------------------------------------------------------------------------
; Subroutine to move Sonic in demo mode
; ---------------------------------------------------------------------------

MoveSonicInDemo:
		tst.w	(f_demo).w	; is demo mode on?
		bne.s	MDemo_On	; if yes, branch
		rts
; ===========================================================================

MDemo_On:
		tst.b	(v_jpadhold1).w	; is start button pressed?
		bpl.s	@dontquit	; if not, branch
		tst.w	(f_demo).w	; is this an ending sequence demo?
		bmi.s	@dontquit	; if yes, branch
		move.b	#id_Title,(v_gamemode).w ; go to title screen

	@dontquit:
		lea	(DemoDataPtr).l,a1
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.b	#id_Special,(v_gamemode).w ; is this a special stage?
		bne.s	@notspecial	; if not, branch
		moveq	#6,d0		; use demo #6

	@notspecial:
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1	; fetch address for demo data
		tst.w	(f_demo).w	; is this an ending sequence demo?
		bpl.s	@notcredits	; if not, branch
		lea	(DemoEndDataPtr).l,a1
		move.w	(v_creditsnum).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1	; fetch address for credits demo

	@notcredits:
		move.w	(v_btnpushtime1).w,d0
		adda.w	d0,a1
		move.b	(a1),d0
		lea	(v_jpadhold1).w,a0
		move.b	d0,d1
		moveq	#0,d2
		eor.b	d2,d0
		move.b	d1,(a0)+
		and.b	d1,d0
		move.b	d0,(a0)+
		subq.b	#1,(v_btnpushtime2).w
		bhs.s	@end
		move.b	3(a1),(v_btnpushtime2).w
		addq.w	#2,(v_btnpushtime1).w

	@end:
		rts
; End of function MoveSonicInDemo

; ===========================================================================
; ---------------------------------------------------------------------------
; Demo sequence pointers
; ---------------------------------------------------------------------------
DemoDataPtr:	dc.l Demo_GHZ		; demos run after the title screen
		dc.l Demo_GHZ
		dc.l Demo_MZ
		dc.l Demo_MZ
		dc.l Demo_SYZ
		dc.l Demo_SYZ
		dc.l Demo_SS
		dc.l Demo_SS

DemoEndDataPtr:	dc.l Demo_EndGHZ1	; demos run during the credits
		dc.l Demo_EndMZ
		dc.l Demo_EndSYZ
		dc.l Demo_EndLZ
		dc.l Demo_EndSLZ
		dc.l Demo_EndSBZ1
		dc.l Demo_EndSBZ2
		dc.l Demo_EndGHZ2
Demo_Unused:	incbin	"demodata\Intro - Unused.bin"
		even

; ---------------------------------------------------------------------------
; Collision index pointer loading subroutine
; ---------------------------------------------------------------------------

ColIndexLoad:
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#2,d0
		move.l	ColPointers(pc,d0.w),(v_collindex).w
		rts
; End of function ColIndexLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision index pointers
; ---------------------------------------------------------------------------
ColPointers:	dc.l Col_GHZ
		dc.l Col_LZ
		dc.l Col_MZ
		dc.l Col_SLZ
		dc.l Col_SYZ
		dc.l Col_SBZ
; 	dc.l Col_GHZ ; Pointer for Ending is missing by default.

; ---------------------------------------------------------------------------
; Oscillating number subroutines
; ---------------------------------------------------------------------------

; Initialise the values

OscillateNumInit:
		lea	(v_oscillate).w,a1
		lea	(@baselines).l,a2
		moveq	#$20,d1

	@loop:
		move.w	(a2)+,(a1)+	; copy baseline values to RAM
		dbf	d1,@loop
		rts

; ===========================================================================
@baselines:	dc.w %0000000001111100	; oscillation direction bitfield
		dc.w $80, 0
		dc.w $80, 0
		dc.w $80, 0
		dc.w $80, 0
		dc.w $80, 0
		dc.w $80, 0
		dc.w $80, 0
		dc.w $80, 0
		dc.w $80, 0
		dc.w $50F0, $11E
		dc.w $2080, $B4
		dc.w $3080, $10E
		dc.w $5080, $1C2
		dc.w $7080, $276
		dc.w $80, 0
		dc.w $80, 0
		even

; Oscillate values

OscillateNumDo:
		cmpi.b	#6,(v_player+obRoutine).w ; has Sonic just died?
		bhs.s	@end		; if yes, branch
		lea	(v_oscillate).w,a1
		lea	(@settings).l,a2
		move.w	(a1)+,d3	; get oscillation direction bitfield
		moveq	#$F,d1

@loop:
		move.w	(a2)+,d2	; get frequency
		move.w	(a2)+,d4	; get amplitude
		btst	d1,d3		; check oscillation direction
		bne.s	@down		; branch if 1

	@up:
		move.w	2(a1),d0	; get current rate
		add.w	d2,d0		; add frequency
		move.w	d0,2(a1)
		add.w	d0,0(a1)	; add rate to value
		cmp.b	0(a1),d4
		bhi.s	@next
		bset	d1,d3
		bra.s	@next

	@down:
		move.w	2(a1),d0
		sub.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bls.s	@next
		bclr	d1,d3

	@next:
		addq.w	#4,a1
		dbf	d1,@loop
		move.w	d3,(v_oscillate).w

@end:
		rts
; End of function OscillateNumDo

; ===========================================================================
@settings:	dc.w 2,	$10	; frequency, amplitude
		dc.w 2,	$18
		dc.w 2,	$20
		dc.w 2,	$30
		dc.w 4,	$20
		dc.w 8,	8
		dc.w 8,	$40
		dc.w 4,	$40
		dc.w 2,	$50
		dc.w 2,	$50
		dc.w 2,	$20
		dc.w 3,	$30
		dc.w 5,	$50
		dc.w 7,	$70
		dc.w 2,	$10
		dc.w 2,	$10
		even

; ---------------------------------------------------------------------------
; Subroutine to change synchronised animation variables (rings, giant rings)
; ---------------------------------------------------------------------------

; ChangeRingFrame:
SynchroAnimate:

; Used for GHZ spiked log
Sync1:
		subq.b	#1,(v_ani0_time).w ; has timer reached 0?
		bpl.s	Sync2		; if not, branch
		move.b	#$B,(v_ani0_time).w ; reset timer
		subq.b	#1,(v_ani0_frame).w ; next frame
		andi.b	#7,(v_ani0_frame).w ; max frame is 7

; Used for rings and giant rings
Sync2:
		subq.b	#1,(v_ani1_time).w
		bpl.s	Sync3
		move.b	#7,(v_ani1_time).w
		addq.b	#1,(v_ani1_frame).w
		andi.b	#3,(v_ani1_frame).w

; Used for nothing
Sync3:
		subq.b	#1,(v_ani2_time).w
		bpl.s	Sync4
		move.b	#7,(v_ani2_time).w
		addq.b	#1,(v_ani2_frame).w
		cmpi.b	#6,(v_ani2_frame).w
		blo.s	Sync4
		move.b	#0,(v_ani2_frame).w

; Used for bouncing rings
Sync4:
		tst.b	(v_ani3_time).w
		beq.s	SyncEnd
		moveq	#0,d0
		move.b	(v_ani3_time).w,d0
		add.w	(v_ani3_buf).w,d0
		move.w	d0,(v_ani3_buf).w
		rol.w	#7,d0
		andi.w	#3,d0
		move.b	d0,(v_ani3_frame).w
		subq.b	#1,(v_ani3_time).w

SyncEnd:
		rts
; End of function SynchroAnimate

; ---------------------------------------------------------------------------
; End-of-act signpost pattern loading subroutine
; ---------------------------------------------------------------------------

SignpostArtLoad:
		tst.w	(v_debuguse).w	; is debug mode being used?
		bne.w	@exit		; if yes, branch
		cmpi.b	#2,(v_act).w	; is act number 02 (act 3)?
		beq.s	@exit		; if yes, branch

		move.w	(v_screenposx).w,d0
		move.w	(v_limitright2).w,d1
		subi.w	#$100,d1
		cmp.w	d1,d0		; has Sonic reached the edge of	the level?
		blt.s	@exit		; if not, branch
		tst.b	(f_timecount).w
		beq.s	@exit
		cmp.w	(v_limitleft2).w,d1
		beq.s	@exit
		move.w	d1,(v_limitleft2).w ; move left boundary to current screen position
		moveq	#plcid_Signpost,d0
		bra.w	NewPLC		; load signpost patterns

	@exit:
		rts
; End of function SignpostArtLoad

; ===========================================================================
Demo_GHZ:	incbin	"demodata\Intro - GHZ.bin"
Demo_MZ:	incbin	"demodata\Intro - MZ.bin"
Demo_SYZ:	incbin	"demodata\Intro - SYZ.bin"
Demo_SS:	incbin	"demodata\Intro - Special Stage.bin"
; ===========================================================================

; ---------------------------------------------------------------------------
; Special Stage
; ---------------------------------------------------------------------------

; SpecialStage:
GM_Special:
		move.w	#sfx_EnterSS,d0
		bsr.w	PlaySound_Special ; play special stage entry sound
		bsr.w	PaletteWhiteOut
		disable_ints
		lea	(vdp_control_port).l,a6
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8004,(a6)	; 8-colour mode
		move.w	#$8A00+175,(v_hbla_hreg).w
		move.w	#$9011,(a6)	; 128-cell hscroll size
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		enable_ints
		fillVRAM	0,$6FFF,$5000

	SS_WaitForDMA:
		move.w	(a5),d1		; read control port ($C00004)
		btst	#1,d1		; is DMA running?
		bne.s	SS_WaitForDMA	; if yes, branch
		move.w	#$8F02,(a5)	; set VDP increment to 2 bytes
		bsr.w	SS_BGLoad
		moveq	#plcid_SpecialStage,d0
		bsr.w	QuickPLC	; load special stage patterns

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1
	SS_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,SS_ClrObjRam	; clear the object RAM

		lea	(v_screenposx).w,a1
		moveq	#0,d0
		move.w	#$3F,d1
	SS_ClrRam1:
		move.l	d0,(a1)+
		dbf	d1,SS_ClrRam1	; clear variables

		lea	(v_oscillate+2).w,a1
		moveq	#0,d0
		move.w	#$27,d1
	SS_ClrRam2:
		move.l	d0,(a1)+
		dbf	d1,SS_ClrRam2	; clear variables

		lea	(v_ngfx_buffer).w,a1
		moveq	#0,d0
		move.w	#$7F,d1
	SS_ClrNemRam:
		move.l	d0,(a1)+
		dbf	d1,SS_ClrNemRam	; clear Nemesis	buffer

		clr.b	(f_wtr_state).w
		clr.w	(f_restart).w
		moveq	#palid_Special,d0
		bsr.w	PalLoad1	; load special stage palette
		jsr	(SS_Load).l		; load SS layout data
		move.l	#0,(v_screenposx).w
		move.l	#0,(v_screenposy).w
		move.b	#id_SonicSpecial,(v_player).w ; load special stage Sonic object
		bsr.w	PalCycle_SS
		clr.w	(v_ssangle).w	; set stage angle to "upright"
		move.w	#$40,(v_ssrotate).w ; set stage rotation speed
		move.w	#bgm_SS,d0
		bsr.w	PlaySound	; play special stage BG music
		move.w	#0,(v_btnpushtime1).w
		lea	(DemoDataPtr).l,a1
		moveq	#6,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		move.b	1(a1),(v_btnpushtime2).w
		subq.b	#1,(v_btnpushtime2).w
		clr.w	(v_rings).w
		clr.b	(v_lifecount).w
		move.w	#0,(v_debuguse).w
		move.w	#1800,(v_demolength).w
		tst.b	(f_debugcheat).w ; has debug cheat been entered?
		beq.s	SS_NoDebug	; if not, branch
		btst	#bitA,(v_jpadhold1).w ; is A button pressed?
		beq.s	SS_NoDebug	; if not, branch
		move.b	#1,(f_debugmode).w ; enable debug mode

	SS_NoDebug:
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	PaletteWhiteIn

; ---------------------------------------------------------------------------
; Main Special Stage loop
; ---------------------------------------------------------------------------

SS_MainLoop:
		bsr.w	PauseGame
		move.b	#$A,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	MoveSonicInDemo
		move.w	(v_jpadhold1).w,(v_jpadhold2).w
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		jsr	(SS_ShowLayout).l
		bsr.w	SS_BGAnimate
		tst.w	(f_demo).w	; is demo mode on?
		beq.s	SS_ChkEnd	; if not, branch
		tst.w	(v_demolength).w ; is there time left on the demo?
		beq.w	SS_ToSegaScreen	; if not, branch

	SS_ChkEnd:
		cmpi.b	#id_Special,(v_gamemode).w ; is game mode $10 (special stage)?
		beq.w	SS_MainLoop	; if yes, branch

		tst.w	(f_demo).w	; is demo mode on?
		bne.w	SS_ToLevel
		move.b	#id_Level,(v_gamemode).w ; set screen mode to $0C (level)
		cmpi.w	#(id_SBZ<<8)+3,(v_zone).w ; is level number higher than FZ?
		blo.s	SS_Finish	; if not, branch
		clr.w	(v_zone).w	; set to GHZ1

SS_Finish:
		move.w	#60,(v_demolength).w ; set delay time to 1 second
		move.w	#$3F,(v_pfade_start).w
		clr.w	(v_palchgspeed).w

	SS_FinLoop:
		move.b	#$16,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	MoveSonicInDemo
		move.w	(v_jpadhold1).w,(v_jpadhold2).w
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		jsr	(SS_ShowLayout).l
		bsr.w	SS_BGAnimate
		subq.w	#1,(v_palchgspeed).w
		bpl.s	loc_47D4
		move.w	#2,(v_palchgspeed).w
		bsr.w	WhiteOut_ToWhite

loc_47D4:
		tst.w	(v_demolength).w
		bne.s	SS_FinLoop

		disable_ints
		lea	(vdp_control_port).l,a6
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		bsr.w	ClearScreen
		locVRAM	$B000
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		jsr	(Hud_Base).l
		enable_ints
		moveq	#palid_SSResult,d0
		bsr.w	PalLoad2	; load results screen palette
		moveq	#plcid_Main,d0
		bsr.w	NewPLC
		moveq	#plcid_SSResult,d0
		bsr.w	AddPLC		; load results screen patterns
		move.b	#1,(f_scorecount).w ; update score counter
		move.b	#1,(f_endactbonus).w ; update ring bonus counter
		move.w	(v_rings).w,d0
		mulu.w	#10,d0		; multiply rings by 10
		move.w	d0,(v_ringbonus).w ; set rings bonus
		move.w	#bgm_GotThrough,d0
		jsr	(PlaySound_Special).l	 ; play end-of-level music

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1
	SS_EndClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,SS_EndClrObjRam ; clear object RAM

		move.b	#id_SSResult,(v_ssrescard).w ; load results screen object

SS_NormalExit:
		bsr.w	PauseGame
		move.b	#$C,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		bsr.w	RunPLC
		tst.w	(f_restart).w
		beq.s	SS_NormalExit
		tst.l	(v_plc_buffer).w
		bne.s	SS_NormalExit
		move.w	#sfx_EnterSS,d0
		bsr.w	PlaySound_Special ; play special stage exit sound
		bsr.w	PaletteWhiteOut
		rts
; ===========================================================================

SS_ToSegaScreen:
		move.b	#id_Sega,(v_gamemode).w ; goto Sega screen
		rts

SS_ToLevel:	cmpi.b	#id_Level,(v_gamemode).w
		beq.s	SS_ToSegaScreen
		rts

; ---------------------------------------------------------------------------
; Special stage background loading subroutine
; ---------------------------------------------------------------------------

SS_BGLoad:
		lea	(v_256x256).l,a1
		lea	(Eni_SSBg1).l,a0 ; load mappings for the birds and fish
		move.w	#$4051,d0
		bsr.w	EniDec
		locVRAM	$5000,d3
		lea	($FF0080).l,a2
		moveq	#6,d7

loc_48BE:
		move.l	d3,d0
		moveq	#3,d6
		moveq	#0,d4
		cmpi.w	#3,d7
		bhs.s	loc_48CC
		moveq	#1,d4

loc_48CC:
		moveq	#7,d5

loc_48CE:
		movea.l	a2,a1
		eori.b	#1,d4
		bne.s	loc_48E2
		cmpi.w	#6,d7
		bne.s	loc_48F2
		lea	(v_256x256).l,a1

loc_48E2:
		movem.l	d0-d4,-(sp)
		moveq	#7,d1
		moveq	#7,d2
		bsr.w	TilemapToVRAM
		movem.l	(sp)+,d0-d4

loc_48F2:
		addi.l	#$100000,d0
		dbf	d5,loc_48CE
		addi.l	#$3800000,d0
		eori.b	#1,d4
		dbf	d6,loc_48CC
		addi.l	#$10000000,d3
		bpl.s	loc_491C
		swap	d3
		addi.l	#$C000,d3
		swap	d3

loc_491C:
		adda.w	#$80,a2
		dbf	d7,loc_48BE
		lea	(v_256x256).l,a1
		lea	(Eni_SSBg2).l,a0 ; load mappings for the clouds
		move.w	#$4000,d0
		bsr.w	EniDec
		copyTilemap	v_256x256,$C000,$3F,$1F
		copyTilemap	v_256x256,$D000,$3F,$3F
		rts
; End of function SS_BGLoad

; ---------------------------------------------------------------------------
; Palette cycling routine - special stage
; ---------------------------------------------------------------------------

PalCycle_SS:
		tst.w	(f_pause).w
		bne.s	locret_49E6
		subq.w	#1,(v_palss_time).w
		bpl.s	locret_49E6
		lea	(vdp_control_port).l,a6
		move.w	(v_palss_num).w,d0
		addq.w	#1,(v_palss_num).w
		andi.w	#$1F,d0
		lsl.w	#2,d0
		lea	(byte_4A3C).l,a0
		adda.w	d0,a0
		move.b	(a0)+,d0
		bpl.s	loc_4992
		move.w	#$1FF,d0

loc_4992:
		move.w	d0,(v_palss_time).w
		moveq	#0,d0
		move.b	(a0)+,d0
		move.w	d0,($FFFFF7A0).w
		lea	(byte_4ABC).l,a1
		lea	(a1,d0.w),a1
		move.w	#$8200,d0
		move.b	(a1)+,d0
		move.w	d0,(a6)
		move.b	(a1),(v_scrposy_vdp).w
		move.w	#$8400,d0
		move.b	(a0)+,d0
		move.w	d0,(a6)
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_vdp).w,(vdp_data_port).l
		moveq	#0,d0
		move.b	(a0)+,d0
		bmi.s	loc_49E8
		lea	(Pal_SSCyc1).l,a1
		adda.w	d0,a1
		lea	(v_pal_dry+$4E).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+

locret_49E6:
		rts
; ===========================================================================

loc_49E8:
		move.w	($FFFFF79E).w,d1
		cmpi.w	#$8A,d0
		blo.s	loc_49F4
		addq.w	#1,d1

loc_49F4:
		mulu.w	#$2A,d1
		lea	(Pal_SSCyc2).l,a1
		adda.w	d1,a1
		andi.w	#$7F,d0
		bclr	#0,d0
		beq.s	loc_4A18
		lea	(v_pal_dry+$6E).w,a2
		move.l	(a1),(a2)+
		move.l	4(a1),(a2)+
		move.l	8(a1),(a2)+

loc_4A18:
		adda.w	#$C,a1
		lea	(v_pal_dry+$5A).w,a2
		cmpi.w	#$A,d0
		blo.s	loc_4A2E
		subi.w	#$A,d0
		lea	(v_pal_dry+$7A).w,a2

loc_4A2E:
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		adda.w	d0,a1
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		rts
; End of function PalCycle_SS

; ===========================================================================
byte_4A3C:	dc.b 3,	0, 7, $92, 3, 0, 7, $90, 3, 0, 7, $8E, 3, 0, 7,	$8C

		dc.b 3,	0, 7, $8B, 3, 0, 7, $80, 3, 0, 7, $82, 3, 0, 7,	$84
		dc.b 3,	0, 7, $86, 3, 0, 7, $88, 7, 8, 7, 0, 7,	$A, 7, $C
		dc.b $FF, $C, 7, $18, $FF, $C, 7, $18, 7, $A, 7, $C, 7,	8, 7, 0
		dc.b 3,	0, 6, $88, 3, 0, 6, $86, 3, 0, 6, $84, 3, 0, 6,	$82
		dc.b 3,	0, 6, $81, 3, 0, 6, $8A, 3, 0, 6, $8C, 3, 0, 6,	$8E
		dc.b 3,	0, 6, $90, 3, 0, 6, $92, 7, 2, 6, $24, 7, 4, 6,	$30
		dc.b $FF, 6, 6,	$3C, $FF, 6, 6,	$3C, 7,	4, 6, $30, 7, 2, 6, $24
		even
byte_4ABC:	dc.b $10, 1, $18, 0, $18, 1, $20, 0, $20, 1, $28, 0, $28, 1
		even

Pal_SSCyc1:	incbin	"palette\Cycle - Special Stage 1.bin"
		even
Pal_SSCyc2:	incbin	"palette\Cycle - Special Stage 2.bin"
		even

; ---------------------------------------------------------------------------
; Subroutine to make the special stage background animated
; ---------------------------------------------------------------------------

SS_BGAnimate:
		move.w	($FFFFF7A0).w,d0
		bne.s	loc_4BF6
		move.w	#0,(v_bgscreenposy).w
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w

loc_4BF6:
		cmpi.w	#8,d0
		bhs.s	loc_4C4E
		cmpi.w	#6,d0
		bne.s	loc_4C10
		addq.w	#1,(v_bg3screenposx).w
		addq.w	#1,(v_bgscreenposy).w
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w

loc_4C10:
		moveq	#0,d0
		move.w	(v_bgscreenposx).w,d0
		neg.w	d0
		swap	d0
		lea	(byte_4CCC).l,a1
		lea	(v_ngfx_buffer).w,a3
		moveq	#9,d3

loc_4C26:
		move.w	2(a3),d0
		bsr.w	CalcSine
		moveq	#0,d2
		move.b	(a1)+,d2
		muls.w	d2,d0
		asr.l	#8,d0
		move.w	d0,(a3)+
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d2,(a3)+
		dbf	d3,loc_4C26
		lea	(v_ngfx_buffer).w,a3
		lea	(byte_4CB8).l,a2
		bra.s	loc_4C7E
; ===========================================================================

loc_4C4E:
		cmpi.w	#$C,d0
		bne.s	loc_4C74
		subq.w	#1,(v_bg3screenposx).w
		lea	($FFFFAB00).w,a3
		move.l	#$18000,d2
		moveq	#6,d1

loc_4C64:
		move.l	(a3),d0
		sub.l	d2,d0
		move.l	d0,(a3)+
		subi.l	#$2000,d2
		dbf	d1,loc_4C64

loc_4C74:
		lea	($FFFFAB00).w,a3
		lea	(byte_4CC4).l,a2

loc_4C7E:
		lea	(v_hscrolltablebuffer).w,a1
		move.w	(v_bg3screenposx).w,d0
		neg.w	d0
		swap	d0
		moveq	#0,d3
		move.b	(a2)+,d3
		move.w	(v_bgscreenposy).w,d2
		neg.w	d2
		andi.w	#$FF,d2
		lsl.w	#2,d2

loc_4C9A:
		move.w	(a3)+,d0
		addq.w	#2,a3
		moveq	#0,d1
		move.b	(a2)+,d1
		subq.w	#1,d1

loc_4CA4:
		move.l	d0,(a1,d2.w)
		addq.w	#4,d2
		andi.w	#$3FC,d2
		dbf	d1,loc_4CA4
		dbf	d3,loc_4C9A
		rts
; End of function SS_BGAnimate

; ===========================================================================
byte_4CB8:	dc.b 9,	$28, $18, $10, $28, $18, $10, $30, $18,	8, $10,	0
		even
byte_4CC4:	dc.b 6,	$30, $30, $30, $28, $18, $18, $18
		even
byte_4CCC:	dc.b 8,	2, 4, $FF, 2, 3, 8, $FF, 4, 2, 2, 3, 8,	$FD, 4,	2, 2, 3, 2, $FF
		even

; ===========================================================================

; ---------------------------------------------------------------------------
; Continue screen
; ---------------------------------------------------------------------------

; ContinueScreen:
GM_Continue:
		bsr.w	PaletteFadeOut
		disable_ints
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; 8 colour mode
		move.w	#$8700,(a6)	; background colour
		bsr.w	ClearScreen

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1
	Cont_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,Cont_ClrObjRam ; clear object RAM

		locVRAM	$B000
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		locVRAM	$A000
		lea	(Nem_ContSonic).l,a0 ; load Sonic patterns
		bsr.w	NemDec
		locVRAM	$AA20
		lea	(Nem_MiniSonic).l,a0 ; load continue screen patterns
		bsr.w	NemDec
		moveq	#10,d1
		jsr	(ContScrCounter).l	; run countdown (start from 10)
		moveq	#palid_Continue,d0
		bsr.w	PalLoad1	; load continue screen palette
		move.b	#bgm_Continue,d0
		bsr.w	PlaySound	; play continue music
		move.w	#659,(v_demolength).w ; set time delay to 11 seconds
		clr.l	(v_screenposx).w
		move.l	#$1000000,(v_screenposy).w
		move.b	#id_ContSonic,(v_player).w ; load Sonic object
		move.b	#id_ContScrItem,(v_continuetext).w ; load continue screen objects
		move.b	#id_ContScrItem,(v_continuelight).w
		move.b	#3,(v_continuelight+obPriority).w
		move.b	#4,(v_continuelight+obFrame).w
		move.b	#id_ContScrItem,(v_continueicon).w
		move.b	#4,(v_continueicon+obRoutine).w
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	PaletteFadeIn

; ---------------------------------------------------------------------------
; Continue screen main loop
; ---------------------------------------------------------------------------

Cont_MainLoop:
		move.b	#$16,(v_vbla_routine).w
		bsr.w	WaitForVBla
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	loc_4DF2
		disable_ints
		move.w	(v_demolength).w,d1
		divu.w	#$3C,d1
		andi.l	#$F,d1
		jsr	(ContScrCounter).l
		enable_ints

loc_4DF2:
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		cmpi.w	#$180,(v_player+obX).w ; has Sonic run off screen?
		bhs.s	Cont_GotoLevel	; if yes, branch
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	Cont_MainLoop
		tst.w	(v_demolength).w
		bne.w	Cont_MainLoop
		move.b	#id_Sega,(v_gamemode).w ; go to Sega screen
		rts
; ===========================================================================

Cont_GotoLevel:
		move.b	#id_Level,(v_gamemode).w ; set screen mode to $0C (level)
		move.b	#3,(v_lives).w	; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.l	d0,(v_score).w	; clear score
		move.b	d0,(v_lastlamp).w ; clear lamppost count
		subq.b	#1,(v_continues).w ; subtract 1 from continues
		rts
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 80 - Continue screen elements
; ---------------------------------------------------------------------------

; Obj80:
ContScrItem:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	CSI_Index(pc,d0.w),d1
		jmp	CSI_Index(pc,d1.w)
; ===========================================================================
CSI_Index:	dc.w CSI_Main-CSI_Index
		dc.w CSI_Display-CSI_Index
		dc.w CSI_MakeMiniSonic-CSI_Index
		dc.w CSI_ChkDel-CSI_Index
; ===========================================================================

CSI_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_ContScr,obMap(a0)
		move.w	#$8500,obGfx(a0)
		move.b	#0,obRender(a0)
		move.b	#$3C,obActWid(a0)
		move.w	#$120,obX(a0)
		move.w	#$C0,obScreenY(a0)
		move.w	#0,(v_rings).w	; clear rings

CSI_Display:	; Routine 2
		jmp	(DisplaySprite).l
; ===========================================================================

	CSI_MiniSonicPos:
		dc.w $116, $12A, $102, $13E, $EE, $152, $DA, $166, $C6
		dc.w $17A, $B2,	$18E, $9E, $1A2, $8A

CSI_MakeMiniSonic:
		; Routine 4
		movea.l	a0,a1
		lea	(CSI_MiniSonicPos).l,a2
		moveq	#0,d1
		move.b	(v_continues).w,d1
		subq.b	#2,d1
		bhs.s	CSI_MoreThan1
		jmp	(DeleteObject).l	; cancel if you have 0-1 continues

	CSI_MoreThan1:
		moveq	#1,d3
		cmpi.b	#14,d1		; do you have fewer than 16 continues
		blo.s	CSI_FewerThan16	; if yes, branch

		moveq	#0,d3
		moveq	#14,d1		; cap at 15 mini-Sonics

	CSI_FewerThan16:
		move.b	d1,d2
		andi.b	#1,d2

CSI_MiniSonicLoop:
		move.b	#id_ContScrItem,0(a1) ; load mini-Sonic object
		move.w	(a2)+,obX(a1)	; use above data for x-axis position
		tst.b	d2		; do you have an even number of continues?
		beq.s	CSI_Even	; if yes, branch
		subi.w	#$A,obX(a1)	; shift mini-Sonics slightly to the right

	CSI_Even:
		move.w	#$D0,obScreenY(a1)
		move.b	#6,obFrame(a1)
		move.b	#6,obRoutine(a1)
		move.l	#Map_ContScr,obMap(a1)
		move.w	#$8551,obGfx(a1)
		move.b	#0,obRender(a1)
		lea	$40(a1),a1
		dbf	d1,CSI_MiniSonicLoop ; repeat for number of continues

		lea	-$40(a1),a1
		move.b	d3,obSubtype(a1)

CSI_ChkDel:	; Routine 6
		tst.b	obSubtype(a0)	; do you have 16 or more continues?
		beq.s	CSI_Animate	; if yes, branch
		cmpi.b	#6,(v_player+obRoutine).w ; is Sonic running?
		blo.s	CSI_Animate	; if not, branch
		move.b	(v_vbla_byte).w,d0
		andi.b	#1,d0
		bne.s	CSI_Animate
		tst.w	(v_player+obVelX).w ; is Sonic running?
		bne.s	CSI_Delete	; if yes, goto delete
		rts

CSI_Animate:
		move.b	(v_vbla_byte).w,d0
		andi.b	#$F,d0
		bne.s	CSI_Display2
		bchg	#0,obFrame(a0)

	CSI_Display2:
		jmp	(DisplaySprite).l
; ===========================================================================

CSI_Delete:
		jmp	(DeleteObject).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 81 - Sonic on the continue screen
; ---------------------------------------------------------------------------

; Obj81:
ContSonic:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	CSon_Index(pc,d0.w),d1
		jsr	CSon_Index(pc,d1.w)
		jmp	(DisplaySprite).l
; ===========================================================================
CSon_Index:	dc.w CSon_Main-CSon_Index
		dc.w CSon_ChkLand-CSon_Index
		dc.w CSon_Animate-CSon_Index
		dc.w CSon_Run-CSon_Index
; ===========================================================================

CSon_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$A0,obX(a0)
		move.w	#$C0,obY(a0)
		move.l	#Map_Sonic,obMap(a0)
		move.w	#$780,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#2,obPriority(a0)
		move.b	#id_Float3,obAnim(a0) ; use "floating" animation
		move.w	#$400,obVelY(a0) ; make Sonic fall from above

CSon_ChkLand:	; Routine 2
		cmpi.w	#$1A0,obY(a0)	; has Sonic landed yet?
		bne.s	CSon_ShowFall	; if not, branch

		addq.b	#2,obRoutine(a0)
		clr.w	obVelY(a0)	; stop Sonic falling
		move.l	#Map_ContScr,obMap(a0)
		move.w	#$8500,obGfx(a0)
		move.b	#id_Walk,obAnim(a0)
		bra.s	CSon_Animate

CSon_ShowFall:
		jsr	(SpeedToPos).l
		jsr	(Sonic_Animate).l
		jmp	(Sonic_LoadGfx).l
; ===========================================================================

CSon_Animate:	; Routine 4
		tst.b	(v_jpadpress1).w ; is Start button pressed?
		bmi.s	CSon_GetUp	; if yes, branch
		lea	(AniScript_CSon).l,a1
		jmp	(AnimateSprite).l

CSon_GetUp:
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Sonic,obMap(a0)
		move.w	#$780,obGfx(a0)
		move.b	#id_Float4,obAnim(a0) ; use "getting up" animation
		clr.w	obInertia(a0)
		subq.w	#8,obY(a0)
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special ; fade out music

CSon_Run:	; Routine 6
		cmpi.w	#$800,obInertia(a0) ; check Sonic's inertia
		bne.s	CSon_AddInertia	; if too low, branch
		move.w	#$1000,obVelX(a0) ; move Sonic to the right
		bra.s	CSon_ShowRun

CSon_AddInertia:
		addi.w	#$20,obInertia(a0) ; increase inertia

CSon_ShowRun:
		jsr	(SpeedToPos).l
		jsr	(Sonic_Animate).l
		jmp	(Sonic_LoadGfx).l

		include	"_anim\Continue Screen Sonic.asm"
Map_ContScr:	include	"_maps\Continue Screen.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Ending sequence in Green Hill Zone
; ---------------------------------------------------------------------------

; EndingSequence:
GM_Ending:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	PaletteFadeOut

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1
	End_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,End_ClrObjRam ; clear object RAM

		lea	(v_vbla_0e_counter).w,a1
		moveq	#0,d0
		move.w	#$15,d1
	End_ClrRam1:
		move.l	d0,(a1)+
		dbf	d1,End_ClrRam1	; clear variables

		lea	(v_screenposx).w,a1
		moveq	#0,d0
		move.w	#$3F,d1
	End_ClrRam2:
		move.l	d0,(a1)+
		dbf	d1,End_ClrRam2	; clear variables

		lea	(v_oscillate+2).w,a1
		moveq	#0,d0
		move.w	#$47,d1
	End_ClrRam3:
		move.l	d0,(a1)+
		dbf	d1,End_ClrRam3	; clear variables

		disable_ints
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		lea	(vdp_control_port).l,a6
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8500+(vram_sprites>>9),(a6) ; set sprite table address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		move.w	#$8004,(a6)		; 8-colour mode
		move.w	#$8720,(a6)		; set background colour (line 3; colour 0)
		move.w	#$8A00+223,(v_hbla_hreg).w ; set palette change position (for water)
		move.w	(v_hbla_hreg).w,(a6)
		move.w	#30,(v_air).w
		move.w	#id_EndZ<<8,(v_zone).w ; set level number to 0600 (extra flowers)
		cmpi.b	#6,(v_emeralds).w ; do you have all 6 emeralds?
		beq.s	End_LoadData	; if yes, branch
		move.w	#(id_EndZ<<8)+1,(v_zone).w ; set level number to 0601 (no flowers)

End_LoadData:
		moveq	#plcid_Ending,d0
		bsr.w	QuickPLC	; load ending sequence patterns
		jsr	(Hud_Base).l
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers
		bset	#2,(v_fg_scroll_flags).w
		bsr.w	LevelDataLoad
		bsr.w	LoadTilesFromStart
		move.l	#Col_GHZ,(v_collindex).w ; load collision index
		enable_ints
		lea	(Kos_EndFlowers).l,a0 ; load extra flower patterns
		lea	($FFFF9400).w,a1 ; RAM address to buffer the patterns
		bsr.w	KosDec
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad1	; load Sonic's palette
		move.w	#bgm_Ending,d0
		bsr.w	PlaySound	; play ending sequence music
		btst	#bitA,(v_jpadhold1).w ; is button A pressed?
		beq.s	End_LoadSonic	; if not, branch
		move.b	#1,(f_debugmode).w ; enable debug mode

End_LoadSonic:
		move.b	#id_SonicPlayer,(v_player).w ; load Sonic object
		bset	#0,(v_player+obStatus).w ; make Sonic face left
		move.b	#1,(f_lockctrl).w ; lock controls
		move.w	#(btnL<<8),(v_jpadhold2).w ; move Sonic to the left
		move.w	#$F800,(v_player+obInertia).w ; set Sonic's speed
		move.b	#id_HUD,(v_hud).w ; load HUD object
		jsr	(ObjPosLoad).l
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		moveq	#0,d0
		move.w	d0,(v_rings).w
		move.l	d0,(v_time).w
		move.b	d0,(v_lifecount).w
		move.b	d0,(v_shield).w
		move.b	d0,(v_invinc).w
		move.b	d0,(v_shoes).w
		move.b	d0,($FFFFFE2F).w
		move.w	d0,(v_debuguse).w
		move.w	d0,(f_restart).w
		move.w	d0,(v_framecount).w
		bsr.w	OscillateNumInit
		move.b	#1,(f_scorecount).w
		move.b	#1,(f_ringcount).w
		move.b	#0,(f_timecount).w
		move.w	#1800,(v_demolength).w
		move.b	#$18,(v_vbla_routine).w
		bsr.w	WaitForVBla
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		move.w	#$3F,(v_pfade_start).w
		bsr.w	PaletteFadeIn

; ---------------------------------------------------------------------------
; Main ending sequence loop
; ---------------------------------------------------------------------------

End_MainLoop:
		bsr.w	PauseGame
		move.b	#$18,(v_vbla_routine).w
		bsr.w	WaitForVBla
		addq.w	#1,(v_framecount).w
		bsr.w	End_MoveSonic
		jsr	(ExecuteObjects).l
		bsr.w	DeformLayers
		jsr	(BuildSprites).l
		jsr	(ObjPosLoad).l
		bsr.w	PaletteCycle
		bsr.w	OscillateNumDo
		bsr.w	SynchroAnimate
		cmpi.b	#id_Ending,(v_gamemode).w ; is game mode $18 (ending)?
		beq.s	End_ChkEmerald	; if yes, branch

		move.b	#id_Credits,(v_gamemode).w ; goto credits
		move.b	#bgm_Credits,d0
		bsr.w	PlaySound_Special ; play credits music
		move.w	#0,(v_creditsnum).w ; set credits index number to 0
		rts
; ===========================================================================

End_ChkEmerald:
		tst.w	(f_restart).w	; has Sonic released the emeralds?
		beq.w	End_MainLoop	; if not, branch

		clr.w	(f_restart).w
		move.w	#$3F,(v_pfade_start).w
		clr.w	(v_palchgspeed).w

	End_AllEmlds:
		bsr.w	PauseGame
		move.b	#$18,(v_vbla_routine).w
		bsr.w	WaitForVBla
		addq.w	#1,(v_framecount).w
		bsr.w	End_MoveSonic
		jsr	(ExecuteObjects).l
		bsr.w	DeformLayers
		jsr	(BuildSprites).l
		jsr	(ObjPosLoad).l
		bsr.w	OscillateNumDo
		bsr.w	SynchroAnimate
		subq.w	#1,(v_palchgspeed).w
		bpl.s	End_SlowFade
		move.w	#2,(v_palchgspeed).w
		bsr.w	WhiteOut_ToWhite

	End_SlowFade:
		tst.w	(f_restart).w
		beq.w	End_AllEmlds
		clr.w	(f_restart).w
		move.w	#$2E2F,(v_lvllayout+$80).w ; modify level layout
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_screenposx).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2
		bsr.w	DrawChunks
		moveq	#palid_Ending,d0
		bsr.w	PalLoad1	; load ending palette
		bsr.w	PaletteWhiteIn
		bra.w	End_MainLoop

; ---------------------------------------------------------------------------
; Subroutine controlling Sonic on the ending sequence
; ---------------------------------------------------------------------------

End_MoveSonic:
		move.b	(v_sonicend).w,d0
		bne.s	End_MoveSon2
		cmpi.w	#$90,(v_player+obX).w ; has Sonic passed $90 on x-axis?
		bhs.s	End_MoveSonExit	; if not, branch

		addq.b	#2,(v_sonicend).w
		move.b	#1,(f_lockctrl).w ; lock player's controls
		move.w	#(btnR<<8),(v_jpadhold2).w ; move Sonic to the right
		rts
; ===========================================================================

End_MoveSon2:
		subq.b	#2,d0
		bne.s	End_MoveSon3
		cmpi.w	#$A0,(v_player+obX).w ; has Sonic passed $A0 on x-axis?
		blo.s	End_MoveSonExit	; if not, branch

		addq.b	#2,(v_sonicend).w
		moveq	#0,d0
		move.b	d0,(f_lockctrl).w
		move.w	d0,(v_jpadhold2).w ; stop Sonic moving
		move.w	d0,(v_player+obInertia).w
		move.b	#$81,(f_playerctrl).w ; lock controls and disable object interaction
		move.b	#fr_Wait2,(v_player+obFrame).w
		move.w	#(id_Wait<<8)+id_Wait,(v_player+obAnim).w ; use "standing" animation
		move.b	#3,(v_player+obTimeFrame).w
		rts
; ===========================================================================

End_MoveSon3:
		subq.b	#2,d0
		bne.s	End_MoveSonExit
		addq.b	#2,(v_sonicend).w
		move.w	#$A0,(v_player+obX).w
		move.b	#id_EndSonic,(v_player).w ; load Sonic ending sequence object
		clr.w	(v_player+obRoutine).w

End_MoveSonExit:
		rts
; End of function End_MoveSonic

; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 87 - Sonic on ending sequence
; ---------------------------------------------------------------------------

; Obj87:
EndSonic:
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	ESon_Index(pc,d0.w),d1
		jsr	ESon_Index(pc,d1.w)
		jmp	(DisplaySprite).l
; ===========================================================================
ESon_Index:	dc.w ESon_Main-ESon_Index, ESon_MakeEmeralds-ESon_Index
		dc.w Obj87_Animate-ESon_Index,	Obj87_LookUp-ESon_Index
		dc.w Obj87_ClrObjRam-ESon_Index, Obj87_Animate-ESon_Index
		dc.w Obj87_MakeLogo-ESon_Index, Obj87_Animate-ESon_Index
		dc.w Obj87_Leap-ESon_Index, Obj87_Animate-ESon_Index

eson_time:	equ $30	; time to wait between events
; ===========================================================================

ESon_Main:	; Routine 0
		cmpi.b	#6,(v_emeralds).w ; do you have all 6 emeralds?
		beq.s	ESon_Main2	; if yes, branch
		addi.b	#$10,ob2ndRout(a0) ; else, skip emerald sequence
		move.w	#216,eson_time(a0)
		rts
; ===========================================================================

ESon_Main2:
		addq.b	#2,ob2ndRout(a0)
		move.l	#Map_ESon,obMap(a0)
		move.w	#$3E1,obGfx(a0)
		move.b	#4,obRender(a0)
		clr.b	obStatus(a0)
		move.b	#2,obPriority(a0)
		move.b	#0,obFrame(a0)
		move.w	#80,eson_time(a0) ; set duration for Sonic to pause

ESon_MakeEmeralds:
		; Routine 2
		subq.w	#1,eson_time(a0) ; subtract 1 from duration
		bne.s	ESon_Wait
		addq.b	#2,ob2ndRout(a0)
		move.w	#1,obAnim(a0)
		move.b	#id_EndChaos,(v_endemeralds).w ; load chaos emeralds objects

	ESon_Wait:
		rts
; ===========================================================================

Obj87_LookUp:	; Routine 6
		cmpi.w	#$2000,((v_objspace&$FFFFFF)+$400+$3C).l
		bne.s	locret_5480
		move.w	#1,(f_restart).w ; set level to restart	(causes	flash)
		move.w	#90,eson_time(a0)
		addq.b	#2,ob2ndRout(a0)

locret_5480:
		rts
; ===========================================================================

Obj87_ClrObjRam:
		; Routine 8
		subq.w	#1,eson_time(a0)
		bne.s	ESon_Wait2
		lea	(v_endemeralds).w,a1
		move.w	#$FF,d1

Obj87_ClrLoop:
		clr.l	(a1)+
		dbf	d1,Obj87_ClrLoop ; clear the object RAM
		move.w	#1,(f_restart).w
		addq.b	#2,ob2ndRout(a0)
		move.b	#1,obAnim(a0)
		move.w	#60,eson_time(a0)

ESon_Wait2:
		rts
; ===========================================================================

Obj87_MakeLogo:	; Routine $C
		subq.w	#1,eson_time(a0)
		bne.s	ESon_Wait3
		addq.b	#2,ob2ndRout(a0)
		move.w	#180,eson_time(a0)
		move.b	#2,obAnim(a0)
		move.b	#id_EndSTH,(v_endlogo).w ; load "SONIC THE HEDGEHOG" object

ESon_Wait3:
		rts
; ===========================================================================

Obj87_Animate:	; Rountine 4, $A, $E, $12
		lea	(AniScript_ESon).l,a1
		jmp	(AnimateSprite).l
; ===========================================================================

Obj87_Leap:	; Routine $10
		subq.w	#1,eson_time(a0)
		bne.s	ESon_Wait4
		addq.b	#2,ob2ndRout(a0)
		move.l	#Map_ESon,obMap(a0)
		move.w	#$3E1,obGfx(a0)
		move.b	#4,obRender(a0)
		clr.b	obStatus(a0)
		move.b	#2,obPriority(a0)
		move.b	#5,obFrame(a0)
		move.b	#2,obAnim(a0)	; use "leaping" animation
		move.b	#id_EndSTH,(v_endlogo).w ; load "SONIC THE HEDGEHOG" object
		bra.s	Obj87_Animate
; ===========================================================================

ESon_Wait4:
		rts

		include "_anim\Ending Sequence Sonic.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 88 - chaos emeralds on the ending sequence
; ---------------------------------------------------------------------------

; Obj88:
EndChaos:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	ECha_Index(pc,d0.w),d1
		jsr	ECha_Index(pc,d1.w)
		jmp	(DisplaySprite).l
; ===========================================================================
ECha_Index:	dc.w ECha_Main-ECha_Index
		dc.w ECha_Move-ECha_Index

echa_origX:	equ $38	; x-axis centre of emerald circle (2 bytes)
echa_origY:	equ $3A	; y-axis centre of emerald circle (2 bytes)
echa_radius:	equ $3C	; radius (2 bytes)
echa_angle:	equ $3E	; angle for rotation (2 bytes)
; ===========================================================================

ECha_Main:	; Routine 0
		cmpi.b	#2,(v_player+obFrame).w ; this isn't `fr_Wait1`: `v_player` is Object 88, which has its own frames
		beq.s	ECha_CreateEms
		addq.l	#4,sp
		rts
; ===========================================================================

ECha_CreateEms:
		move.w	(v_player+obX).w,obX(a0) ; match X position with Sonic
		move.w	(v_player+obY).w,obY(a0) ; match Y position with Sonic
		movea.l	a0,a1
		moveq	#0,d3
		moveq	#1,d2
		moveq	#5,d1

	ECha_LoadLoop:
		move.b	#id_EndChaos,(a1) ; load chaos emerald object
		addq.b	#2,obRoutine(a1)
		move.l	#Map_ECha,obMap(a1)
		move.w	#$3C5,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#1,obPriority(a1)
		move.w	obX(a0),echa_origX(a1)
		move.w	obY(a0),echa_origY(a1)
		move.b	d2,obAnim(a1)
		move.b	d2,obFrame(a1)
		addq.b	#1,d2
		move.b	d3,obAngle(a1)
		addi.b	#$100/6,d3	; angle between each emerald
		lea	$40(a1),a1
		dbf	d1,ECha_LoadLoop ; repeat 5 more times

ECha_Move:	; Routine 2
		move.w	echa_angle(a0),d0
		add.w	d0,obAngle(a0)
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		moveq	#0,d4
		move.b	echa_radius(a0),d4
		muls.w	d4,d1
		asr.l	#8,d1
		muls.w	d4,d0
		asr.l	#8,d0
		add.w	echa_origX(a0),d1
		add.w	echa_origY(a0),d0
		move.w	d1,obX(a0)
		move.w	d0,obY(a0)

	ECha_Expand:
		cmpi.w	#$2000,echa_radius(a0)
		beq.s	ECha_Rotate
		addi.w	#$20,echa_radius(a0) ; expand circle of emeralds

	ECha_Rotate:
		cmpi.w	#$2000,echa_angle(a0)
		beq.s	ECha_Rise
		addi.w	#$20,echa_angle(a0) ; move emeralds around the centre

	ECha_Rise:
		cmpi.w	#$140,echa_origY(a0)
		beq.s	ECha_End
		subq.w	#1,echa_origY(a0) ; make circle rise

ECha_End:
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 89 - "SONIC THE HEDGEHOG" text on the ending sequence
; ---------------------------------------------------------------------------

; Obj89:
EndSTH:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	ESth_Index(pc,d0.w),d1
		jsr	ESth_Index(pc,d1.w)
		jmp	(DisplaySprite).l
; ===========================================================================
ESth_Index:	dc.w ESth_Main-ESth_Index
		dc.w ESth_Move-ESth_Index
		dc.w ESth_GotoCredits-ESth_Index

esth_time:	equ $30		; time until exit
; ===========================================================================

ESth_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#-$20,obX(a0)	; object starts outside	the level boundary
		move.w	#$D8,obScreenY(a0)
		move.l	#Map_ESth,obMap(a0)
		move.w	#$5C5,obGfx(a0)
		move.b	#0,obRender(a0)
		move.b	#0,obPriority(a0)

ESth_Move:	; Routine 2
		cmpi.w	#$C0,obX(a0)	; has object reached $C0?
		beq.s	ESth_Delay	; if yes, branch
		addi.w	#$10,obX(a0)	; move object to the right
		rts

ESth_Delay:
		addq.b	#2,obRoutine(a0)
		move.w	#300,esth_time(a0) ; set duration for delay (5 seconds)

ESth_GotoCredits:
		; Routine 4
		subq.w	#1,esth_time(a0) ; subtract 1 from duration
		bpl.s	ESth_Wait
		move.b	#id_Credits,(v_gamemode).w ; exit to credits

	ESth_Wait:
		rts

Map_ESon:	include	"_maps\Ending Sequence Sonic.asm"
Map_ECha:	include	"_maps\Ending Sequence Emeralds.asm"
Map_ESth:	include	"_maps\Ending Sequence STH.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Credits ending sequence
; ---------------------------------------------------------------------------

; Credits:
GM_Credits:
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)		; 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		move.w	#$9200,(a6)		; window vertical position
		move.w	#$8B03,(a6)		; line scroll mode
		move.w	#$8720,(a6)		; set background colour (line 3; colour 0)
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1
	Cred_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,Cred_ClrObjRam ; clear object RAM

		locVRAM	$B400
		lea	(Nem_CreditText).l,a0 ; load credits alphabet patterns
		bsr.w	NemDec

		lea	(v_pal_dry_dup).w,a1
		moveq	#0,d0
		move.w	#$1F,d1
	Cred_ClrPal:
		move.l	d0,(a1)+
		dbf	d1,Cred_ClrPal ; fill palette with black

		moveq	#palid_Sonic,d0
		bsr.w	PalLoad1	; load Sonic's palette
		move.b	#id_CreditsText,(v_credits).w ; load credits object
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		bsr.w	EndingDemoLoad
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea	(LevelHeaders).l,a2
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	Cred_SkipObjGfx
		bsr.w	AddPLC		; load object graphics

	Cred_SkipObjGfx:
		moveq	#plcid_Main2,d0
		bsr.w	AddPLC		; load standard level graphics
		move.w	#120,(v_demolength).w ; display a credit for 2 seconds
		bsr.w	PaletteFadeIn

Cred_WaitLoop:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	RunPLC
		tst.w	(v_demolength).w ; have 2 seconds elapsed?
		bne.s	Cred_WaitLoop	; if not, branch
		tst.l	(v_plc_buffer).w ; have level gfx finished decompressing?
		bne.s	Cred_WaitLoop	; if not, branch
		cmpi.w	#9,(v_creditsnum).w ; have the credits finished?
		beq.w	TryAgainEnd	; if yes, branch
		rts

; ---------------------------------------------------------------------------
; Ending sequence demo loading subroutine
; ---------------------------------------------------------------------------

EndingDemoLoad:
		move.w	(v_creditsnum).w,d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	EndDemo_Levels(pc,d0.w),d0 ; load level array
		move.w	d0,(v_zone).w	; set level from level array
		addq.w	#1,(v_creditsnum).w
		cmpi.w	#9,(v_creditsnum).w ; have credits finished?
		bhs.s	EndDemo_Exit	; if yes, branch
		move.w	#$8001,(f_demo).w ; set demo+ending mode
		move.b	#id_Demo,(v_gamemode).w ; set game mode to 8 (demo)
		move.b	#3,(v_lives).w	; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.l	d0,(v_score).w	; clear score
		move.b	d0,(v_lastlamp).w ; clear lamppost counter
		cmpi.w	#4,(v_creditsnum).w ; is SLZ demo running?
		bne.s	EndDemo_Exit	; if not, branch
		lea	(EndDemo_LampVar).l,a1 ; load lamppost variables
		lea	(v_lastlamp).w,a2
		move.w	#8,d0

	EndDemo_LampLoad:
		move.l	(a1)+,(a2)+
		dbf	d0,EndDemo_LampLoad

EndDemo_Exit:
		rts
; End of function EndingDemoLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Levels used in the end sequence demos
; ---------------------------------------------------------------------------
EndDemo_Levels:	incbin	"misc\Demo Level Order - Ending.bin"

; ---------------------------------------------------------------------------
; Lamppost variables in the end sequence demo (Star Light Zone)
; ---------------------------------------------------------------------------
EndDemo_LampVar:
		dc.b 1,	1		; number of the last lamppost
		dc.w $A00, $62C		; x/y-axis position
		dc.w 13			; rings
		dc.l 0			; time
		dc.b 0,	0		; dynamic level event routine counter
		dc.w $800		; level bottom boundary
		dc.w $957, $5CC		; x/y axis screen position
		dc.w $4AB, $3A6, 0, $28C, 0, 0 ; scroll info
		dc.w $308		; water height
		dc.b 1,	1		; water routine and state
; ===========================================================================
; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END" screens
; ---------------------------------------------------------------------------

TryAgainEnd:
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; use 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)	; 64-cell hscroll size
		move.w	#$9200,(a6)	; window vertical position
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8720,(a6)	; set background colour (line 3; colour 0)
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1
	TryAg_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,TryAg_ClrObjRam ; clear object RAM

		moveq	#plcid_TryAgain,d0
		bsr.w	QuickPLC	; load "TRY AGAIN" or "END" patterns

		lea	(v_pal_dry_dup).w,a1
		moveq	#0,d0
		move.w	#$1F,d1
	TryAg_ClrPal:
		move.l	d0,(a1)+
		dbf	d1,TryAg_ClrPal ; fill palette with black

		moveq	#palid_Ending,d0
		bsr.w	PalLoad1	; load ending palette
		clr.w	(v_pal_dry_dup+$40).w
		move.b	#id_EndEggman,(v_endeggman).w ; load Eggman object
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		move.w	#1800,(v_demolength).w ; show screen for 30 seconds
		bsr.w	PaletteFadeIn

; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END" screen main loop
; ---------------------------------------------------------------------------
TryAg_MainLoop:
		bsr.w	PauseGame
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr	(ExecuteObjects).l
		jsr	(BuildSprites).l
		andi.b	#btnStart,(v_jpadpress1).w ; is Start button pressed?
		bne.s	TryAg_Exit	; if yes, branch
		tst.w	(v_demolength).w ; has 30 seconds elapsed?
		beq.s	TryAg_Exit	; if yes, branch
		cmpi.b	#id_Credits,(v_gamemode).w
		beq.s	TryAg_MainLoop

TryAg_Exit:
		move.b	#id_Sega,(v_gamemode).w ; goto Sega screen
		rts

; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 8B - Eggman on "TRY AGAIN" and "END" screens
; ---------------------------------------------------------------------------

; Obj8B:
EndEggman:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	EEgg_Index(pc,d0.w),d1
		jsr	EEgg_Index(pc,d1.w)
		jmp	(DisplaySprite).l
; ===========================================================================
EEgg_Index:	dc.w EEgg_Main-EEgg_Index
		dc.w EEgg_Animate-EEgg_Index
		dc.w EEgg_Juggle-EEgg_Index
		dc.w EEgg_Wait-EEgg_Index

eegg_time:	equ $30		; time between juggle motions
; ===========================================================================

EEgg_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$120,obX(a0)
		move.w	#$F4,obScreenY(a0)
		move.l	#Map_EEgg,obMap(a0)
		move.w	#$3E1,obGfx(a0)
		move.b	#0,obRender(a0)
		move.b	#2,obPriority(a0)
		move.b	#2,obAnim(a0)	; use "END" animation
		cmpi.b	#6,(v_emeralds).w ; do you have all 6 emeralds?
		beq.s	EEgg_Animate	; if yes, branch

		move.b	#id_CreditsText,(v_tryagain).w ; load credits object
		move.w	#9,(v_creditsnum).w ; use "TRY AGAIN" text
		move.b	#id_TryChaos,(v_eggmanchaos).w ; load emeralds object on "TRY AGAIN" screen
		move.b	#0,obAnim(a0)	; use "TRY AGAIN" animation

EEgg_Animate:	; Routine 2
		lea	(Ani_EEgg).l,a1
		jmp	(AnimateSprite).l
; ===========================================================================

EEgg_Juggle:	; Routine 4
		addq.b	#2,obRoutine(a0)
		moveq	#2,d0
		btst	#0,obAnim(a0)
		beq.s	@noflip
		neg.w	d0

	@noflip:
		lea	(v_eggmanchaos).w,a1 ; get RAM address for emeralds
		moveq	#5,d1

@emeraldloop:
		move.b	d0,$3E(a1)
		move.w	d0,d2
		asl.w	#3,d2
		add.b	d2,obAngle(a1)
		lea	$40(a1),a1
		dbf	d1,@emeraldloop
		addq.b	#1,obFrame(a0)
		move.w	#112,eegg_time(a0)

EEgg_Wait:	; Routine 6
		subq.w	#1,eegg_time(a0) ; decrement timer
		bpl.s	@nochg		; branch if time remains
		bchg	#0,obAnim(a0)
		move.b	#2,obRoutine(a0) ; goto EEgg_Animate next

	@nochg:
		rts

		include "_anim\Try Again & End Eggman.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 8C - chaos emeralds on the "TRY AGAIN"	screen
; ---------------------------------------------------------------------------

; Obj8C:
TryChaos:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	TCha_Index(pc,d0.w),d1
		jsr	TCha_Index(pc,d1.w)
		jmp	(DisplaySprite).l
; ===========================================================================
TCha_Index:	dc.w TCha_Main-TCha_Index
		dc.w TCha_Move-TCha_Index
; ===========================================================================

TCha_Main:	; Routine 0
		movea.l	a0,a1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#5,d1
		sub.b	(v_emeralds).w,d1

@makeemerald:
		move.b	#id_TryChaos,(a1) ; load emerald object
		addq.b	#2,obRoutine(a1)
		move.l	#Map_ECha,obMap(a1)
		move.w	#$3C5,obGfx(a1)
		move.b	#0,obRender(a1)
		move.b	#1,obPriority(a1)
		move.w	#$104,obX(a1)
		move.w	#$120,$38(a1)
		move.w	#$EC,obScreenY(a1)
		move.w	obScreenY(a1),$3A(a1)
		move.b	#$1C,$3C(a1)
		lea	(v_emldlist).w,a3

	@chkemerald:
		moveq	#0,d0
		move.b	(v_emeralds).w,d0
		subq.w	#1,d0
		blo.s	@loc_5B42

	@chkloop:
		cmp.b	(a3,d0.w),d2
		bne.s	@notgot
		addq.b	#1,d2
		bra.s	@chkemerald
; ===========================================================================

	@notgot:
		dbf	d0,@chkloop

@loc_5B42:
		move.b	d2,obFrame(a1)
		addq.b	#1,obFrame(a1)
		addq.b	#1,d2
		move.b	#$80,obAngle(a1)
		move.b	d3,obTimeFrame(a1)
		move.b	d3,obDelayAni(a1)
		addi.w	#10,d3
		lea	$40(a1),a1
		dbf	d1,@makeemerald	; repeat 5 times

TCha_Move:	; Routine 2
		tst.w	$3E(a0)
		beq.s	locret_5BBA
		tst.b	obTimeFrame(a0)
		beq.s	loc_5B78
		subq.b	#1,obTimeFrame(a0)
		bne.s	loc_5B80

loc_5B78:
		move.w	$3E(a0),d0
		add.w	d0,obAngle(a0)

loc_5B80:
		move.b	obAngle(a0),d0
		beq.s	loc_5B8C
		cmpi.b	#$80,d0
		bne.s	loc_5B96

loc_5B8C:
		clr.w	$3E(a0)
		move.b	obDelayAni(a0),obTimeFrame(a0)

loc_5B96:
		jsr	(CalcSine).l
		moveq	#0,d4
		move.b	$3C(a0),d4
		muls.w	d4,d1
		asr.l	#8,d1
		muls.w	d4,d0
		asr.l	#8,d0
		add.w	$38(a0),d1
		add.w	$3A(a0),d0
		move.w	d1,obX(a0)
		move.w	d0,obScreenY(a0)

locret_5BBA:
		rts

Map_EEgg:	include	"_maps\Try Again & End Eggman.asm"

; ---------------------------------------------------------------------------
; Ending sequence demos
; ---------------------------------------------------------------------------
Demo_EndGHZ1:	incbin	"demodata\Ending - GHZ1.bin"
		even
Demo_EndMZ:	incbin	"demodata\Ending - MZ.bin"
		even
Demo_EndSYZ:	incbin	"demodata\Ending - SYZ.bin"
		even
Demo_EndLZ:	incbin	"demodata\Ending - LZ.bin"
		even
Demo_EndSLZ:	incbin	"demodata\Ending - SLZ.bin"
		even
Demo_EndSBZ1:	incbin	"demodata\Ending - SBZ1.bin"
		even
Demo_EndSBZ2:	incbin	"demodata\Ending - SBZ2.bin"
		even
Demo_EndGHZ2:	incbin	"demodata\Ending - GHZ2.bin"
		even

; ---------------------------------------------------------------------------
; Subroutine to load level boundaries and start	locations
; ---------------------------------------------------------------------------

LevelSizeLoad:
		moveq	#0,d0
		move.b	d0,($FFFFF740).w
		move.b	d0,($FFFFF741).w
		move.b	d0,($FFFFF746).w
		move.b	d0,($FFFFF748).w
		move.b	d0,(v_dle_routine).w
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		lea	LevelSizeArray(pc,d0.w),a0 ; load level boundaries
		move.w	(a0)+,d0
		move.w	d0,($FFFFF730).w
		move.l	(a0)+,d0
		move.l	d0,(v_limitleft2).w
		move.l	d0,(v_limitleft1).w
		move.l	(a0)+,d0
		move.l	d0,(v_limittop2).w
		move.l	d0,(v_limittop1).w
		move.w	(v_limitleft2).w,d0
		addi.w	#$240,d0
		move.w	d0,(v_limitleft3).w
		move.w	#$1010,($FFFFF74A).w
		move.w	(a0)+,d0
		move.w	d0,(v_lookshift).w
		bra.w	LevSz_ChkLamp
; ===========================================================================
; ---------------------------------------------------------------------------
; Level size array
; ---------------------------------------------------------------------------
LevelSizeArray:
		; GHZ
		dc.w $0004, $0000, $24BF, $0000, $0300, $0060
		dc.w $0004, $0000, $1EBF, $0000, $0300, $0060
		dc.w $0004, $0000, $2960, $0000, $0300, $0060
		dc.w $0004, $0000, $2ABF, $0000, $0300, $0060
		; LZ
		dc.w $0004, $0000, $19BF, $0000, $0530, $0060
		dc.w $0004, $0000, $10AF, $0000, $0720, $0060
		dc.w $0004, $0000, $202F, $FF00, $0800, $0060
		dc.w $0004, $0000, $20BF, $0000, $0720, $0060
		; MZ
		dc.w $0004, $0000, $17BF, $0000, $01D0, $0060
		dc.w $0004, $0000, $17BF, $0000, $0520, $0060
		dc.w $0004, $0000, $1800, $0000, $0720, $0060
		dc.w $0004, $0000, $16BF, $0000, $0720, $0060
		; SLZ
		dc.w $0004, $0000, $1FBF, $0000, $0640, $0060
		dc.w $0004, $0000, $1FBF, $0000, $0640, $0060
		dc.w $0004, $0000, $2000, $0000, $06C0, $0060
		dc.w $0004, $0000, $3EC0, $0000, $0720, $0060
		; SYZ
		dc.w $0004, $0000, $22C0, $0000, $0420, $0060
		dc.w $0004, $0000, $28C0, $0000, $0520, $0060
		dc.w $0004, $0000, $2C00, $0000, $0620, $0060
		dc.w $0004, $0000, $2EC0, $0000, $0620, $0060
		; SBZ
		dc.w $0004, $0000, $21C0, $0000, $0720, $0060
		dc.w $0004, $0000, $1E40, $FF00, $0800, $0060
		dc.w $0004, $2080, $2460, $0510, $0510, $0060
		dc.w $0004, $0000, $3EC0, $0000, $0720, $0060
		; Ending
		dc.w $0004, $0000, $0500, $0110, $0110, $0060
		dc.w $0004, $0000, $0DC0, $0110, $0110, $0060
		dc.w $0004, $0000, $2FFF, $0000, $0320, $0060
		dc.w $0004, $0000, $2FFF, $0000, $0320, $0060

; ---------------------------------------------------------------------------
; Ending start location array
; ---------------------------------------------------------------------------
EndingStLocArray:
		incbin	"startpos\credits\ghz1 (Credits demo 1).bin"
		incbin	"startpos\credits\mz2 (Credits demo).bin"
		incbin	"startpos\credits\syz3 (Credits demo).bin"
		incbin	"startpos\credits\lz3 (Credits demo).bin"
		incbin	"startpos\credits\slz3 (Credits demo).bin"
		incbin	"startpos\credits\sbz1 (Credits demo).bin"
		incbin	"startpos\credits\sbz2 (Credits demo).bin"
		incbin	"startpos\credits\ghz1 (Credits demo 2).bin"
		even

; ===========================================================================

LevSz_ChkLamp:
		tst.b	(v_lastlamp).w	; have any lampposts been hit?
		beq.s	LevSz_StartLoc	; if not, branch

		jsr	(Lamp_LoadInfo).l
		move.w	(v_player+obX).w,d1
		move.w	(v_player+obY).w,d0
		bra.s	LevSz_SkipStartPos
; ===========================================================================

LevSz_StartLoc:
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	StartLocArray(pc,d0.w),a1 ; load Sonic's start location
		tst.w	(f_demo).w	; is ending demo mode on?
		bpl.s	LevSz_SonicPos	; if not, branch

		move.w	(v_creditsnum).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		lea	EndingStLocArray(pc,d0.w),a1 ; load Sonic's start location

LevSz_SonicPos:
		moveq	#0,d1
		move.w	(a1)+,d1
		move.w	d1,(v_player+obX).w ; set Sonic's position on x-axis
		moveq	#0,d0
		move.w	(a1),d0
		move.w	d0,(v_player+obY).w ; set Sonic's position on y-axis

SetScreen:
	LevSz_SkipStartPos:
		subi.w	#160,d1		; is Sonic more than 160px from left edge?
		bhs.s	SetScr_WithinLeft ; if yes, branch
		moveq	#0,d1

	SetScr_WithinLeft:
		move.w	(v_limitright2).w,d2
		cmp.w	d2,d1		; is Sonic inside the right edge?
		blo.s	SetScr_WithinRight ; if yes, branch
		move.w	d2,d1

	SetScr_WithinRight:
		move.w	d1,(v_screenposx).w ; set horizontal screen position

		subi.w	#96,d0		; is Sonic within 96px of upper edge?
		bhs.s	SetScr_WithinTop ; if yes, branch
		moveq	#0,d0

	SetScr_WithinTop:
		cmp.w	(v_limitbtm2).w,d0 ; is Sonic above the bottom edge?
		blt.s	SetScr_WithinBottom ; if yes, branch
		move.w	(v_limitbtm2).w,d0

	SetScr_WithinBottom:
		move.w	d0,(v_screenposy).w ; set vertical screen position
		bsr.w	BgScrollSpeed
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.b	#2,d0
		move.l	LoopTileNums(pc,d0.w),(v_256loop1).w
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic start location array
; ---------------------------------------------------------------------------
StartLocArray:
		incbin	"startpos\ghz1.bin"
		incbin	"startpos\ghz2.bin"
		incbin	"startpos\ghz3.bin"
		dc.w	$80,$A8

		incbin	"startpos\lz1.bin"
		incbin	"startpos\lz2.bin"
		incbin	"startpos\lz3.bin"
		incbin	"startpos\sbz3.bin"

		incbin	"startpos\mz1.bin"
		incbin	"startpos\mz2.bin"
		incbin	"startpos\mz3.bin"
		dc.w	$80,$A8

		incbin	"startpos\slz1.bin"
		incbin	"startpos\slz2.bin"
		incbin	"startpos\slz3.bin"
		dc.w	$80,$A8

		incbin	"startpos\syz1.bin"
		incbin	"startpos\syz2.bin"
		incbin	"startpos\syz3.bin"
		dc.w	$80,$A8

		incbin	"startpos\sbz1.bin"
		incbin	"startpos\sbz2.bin"
		incbin	"startpos\fz.bin"
		dc.w	$80,$A8

		incbin	"startpos\end1.bin"
		incbin	"startpos\end2.bin"
		dc.w	$80,$A8
		dc.w	$80,$A8

		even

; ---------------------------------------------------------------------------
; Which 256x256	tiles contain loops or roll-tunnels
; ---------------------------------------------------------------------------

LoopTileNums:

;	  	loop	loop	tunnel	tunnel

		dc.b	$B5,	$7F,	$1F,	$20	; Green Hill
		dc.b	$7F,	$7F,	$7F,	$7F	; Labyrinth
		dc.b	$7F,	$7F,	$7F,	$7F	; Marble
		dc.b	$AA,	$B4,	$7F,	$7F	; Star Light
		dc.b	$7F,	$7F,	$7F,	$7F	; Spring Yard
		dc.b	$7F,	$7F,	$7F,	$7F	; Scrap Brain
		dc.b	$7F,	$7F,	$7F,	$7F	; Ending (Green Hill)

		even

; ---------------------------------------------------------------------------
; Subroutine to set scroll speed of some backgrounds
; ---------------------------------------------------------------------------

BgScrollSpeed:
		tst.b	(v_lastlamp).w
		bne.s	loc_6206
		move.w	d0,(v_bgscreenposy).w
		move.w	d0,(v_bg2screenposy).w
		move.w	d1,(v_bgscreenposx).w
		move.w	d1,(v_bg2screenposx).w
		move.w	d1,(v_bg3screenposx).w

loc_6206:
		moveq	#0,d2
		move.b	(v_zone).w,d2
		add.w	d2,d2
		move.w	BgScroll_Index(pc,d2.w),d2
		jmp	BgScroll_Index(pc,d2.w)
; End of function BgScrollSpeed

; ===========================================================================
BgScroll_Index:	dc.w BgScroll_GHZ-BgScroll_Index, BgScroll_LZ-BgScroll_Index
		dc.w BgScroll_MZ-BgScroll_Index, BgScroll_SLZ-BgScroll_Index
		dc.w BgScroll_SYZ-BgScroll_Index, BgScroll_SBZ-BgScroll_Index
		dc.w BgScroll_End-BgScroll_Index
; ===========================================================================

BgScroll_GHZ:
		clr.l	(v_bgscreenposx).w
		clr.l	(v_bgscreenposy).w
		clr.l	(v_bg2screenposy).w
		clr.l	(v_bg3screenposy).w
		lea	($FFFFA800).w,a2
		clr.l	(a2)+
		clr.l	(a2)+
		clr.l	(a2)+
		rts
; ===========================================================================

BgScroll_LZ:
		asr.l	#1,d0
		move.w	d0,(v_bgscreenposy).w
		rts
; ===========================================================================

BgScroll_MZ:
		rts
; ===========================================================================

BgScroll_SLZ:
		asr.l	#1,d0
		addi.w	#$C0,d0
		move.w	d0,(v_bgscreenposy).w
		clr.l	(v_bgscreenposx).w
		rts
; ===========================================================================

BgScroll_SYZ:
		asl.l	#4,d0
		move.l	d0,d2
		asl.l	#1,d0
		add.l	d2,d0
		asr.l	#8,d0
		addq.w	#1,d0
		move.w	d0,(v_bgscreenposy).w
		clr.l	(v_bgscreenposx).w
		rts
; ===========================================================================

BgScroll_SBZ:
		andi.w	#$7F8,d0
		asr.w	#3,d0
		addq.w	#1,d0
		move.w	d0,(v_bgscreenposy).w
		rts
; ===========================================================================

BgScroll_End:
		move.w	(v_screenposx).w,d0
		asr.w	#1,d0
		move.w	d0,(v_bgscreenposx).w
		move.w	d0,(v_bg2screenposx).w
		asr.w	#2,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		move.w	d0,(v_bg3screenposx).w
		clr.l	(v_bgscreenposy).w
		clr.l	(v_bg2screenposy).w
		clr.l	(v_bg3screenposy).w
		lea	($FFFFA800).w,a2
		clr.l	(a2)+
		clr.l	(a2)+
		clr.l	(a2)+
		rts

; ---------------------------------------------------------------------------
; Background layer deformation subroutines
; ---------------------------------------------------------------------------

; DeformBgLayer:
DeformLayers:
		tst.b	(f_nobgscroll).w
		beq.s	@bgscroll
		rts
; ===========================================================================

	@bgscroll:
		clr.w	(v_fg_scroll_flags).w
		clr.w	(v_bg1_scroll_flags).w
		clr.w	(v_bg2_scroll_flags).w
		clr.w	(v_bg3_scroll_flags).w
		bsr.w	ScrollHoriz
		bsr.w	ScrollVertical
		bsr.w	DynamicLevelEvents
		move.w	(v_screenposy).w,(v_scrposy_vdp).w
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w
		moveq	#0,d0
		move.b	(v_zone).w,d0
		add.w	d0,d0
		move.w	Deform_Index(pc,d0.w),d0
		jmp	Deform_Index(pc,d0.w)
; End of function DeformLayers

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for background layer deformation code
; ---------------------------------------------------------------------------
Deform_Index:	dc.w Deform_GHZ-Deform_Index, Deform_LZ-Deform_Index
		dc.w Deform_MZ-Deform_Index, Deform_SLZ-Deform_Index
		dc.w Deform_SYZ-Deform_Index, Deform_SBZ-Deform_Index
		dc.w Deform_GHZ-Deform_Index
; ---------------------------------------------------------------------------
; Green Hill Zone background layer deformation code
; ---------------------------------------------------------------------------

Deform_GHZ:
	; block 3 - distant mountains
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#5,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#0,d6
		bsr.w	BGScroll_Block3
	; block 2 - hills & waterfalls
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#7,d4
		moveq	#0,d6
		bsr.w	BGScroll_Block2
	; calculate Y position
		lea	(v_hscrolltablebuffer).w,a1
		move.w	(v_screenposy).w,d0
		andi.w	#$7FF,d0
		lsr.w	#5,d0
		neg.w	d0
		addi.w	#$20,d0
		bpl.s	@limitY
		moveq	#0,d0
	@limitY:
		move.w	d0,d4
		move.w	d0,(v_bgscrposy_vdp).w
		move.w	(v_screenposx).w,d0
		cmpi.b	#id_Title,(v_gamemode).w
		bne.s	@notTitle
		moveq	#0,d0	; reset foreground position in title screen
	@notTitle:
		neg.w	d0
		swap	d0
	; auto-scroll clouds
		lea	(v_bgscroll_buffer).w,a2
		addi.l	#$10000,(a2)+
		addi.l	#$C000,(a2)+
		addi.l	#$8000,(a2)+
	; calculate background scroll
		move.w	(v_bgscroll_buffer).w,d0
		add.w	(v_bg3screenposx).w,d0
		neg.w	d0
		move.w	#$1F,d1
		sub.w	d4,d1
		blo.s	@gotoCloud2
	@cloudLoop1:		; upper cloud (32px)
		move.l	d0,(a1)+
		dbf	d1,@cloudLoop1

	@gotoCloud2:
		move.w	(v_bgscroll_buffer+4).w,d0
		add.w	(v_bg3screenposx).w,d0
		neg.w	d0
		move.w	#$F,d1
	@cloudLoop2:		; middle cloud (16px)
		move.l	d0,(a1)+
		dbf	d1,@cloudLoop2

		move.w	(v_bgscroll_buffer+8).w,d0
		add.w	(v_bg3screenposx).w,d0
		neg.w	d0
		move.w	#$F,d1
	@cloudLoop3:		; lower cloud (16px)
		move.l	d0,(a1)+
		dbf	d1,@cloudLoop3

		move.w	#$2F,d1
		move.w	(v_bg3screenposx).w,d0
		neg.w	d0
	@mountainLoop:		; distant mountains (48px)
		move.l	d0,(a1)+
		dbf	d1,@mountainLoop

		move.w	#$27,d1
		move.w	(v_bg2screenposx).w,d0
		neg.w	d0
	@hillLoop:			; hills & waterfalls (40px)
		move.l	d0,(a1)+
		dbf	d1,@hillLoop

		move.w	(v_bg2screenposx).w,d0
		move.w	(v_screenposx).w,d2
		sub.w	d0,d2
		ext.l	d2
		asl.l	#8,d2
		divs.w	#$68,d2
		ext.l	d2
		asl.l	#8,d2
		moveq	#0,d3
		move.w	d0,d3
		move.w	#$47,d1
		add.w	d4,d1
	@waterLoop:			; water deformation
		move.w	d3,d0
		neg.w	d0
		move.l	d0,(a1)+
		swap	d3
		add.l	d2,d3
		swap	d3
		dbf	d1,@waterLoop
		rts
; End of function Deform_GHZ

; ---------------------------------------------------------------------------
; Labyrinth Zone background layer deformation code
; ---------------------------------------------------------------------------

Deform_LZ:
	; plain background scroll
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#7,d4
		move.w	(v_scrshifty).w,d5
		ext.l	d5
		asl.l	#7,d5
		bsr.w	BGScroll_XY

		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w
		lea	(Lz_Scroll_Data).l,a3
		lea	(Drown_WobbleData).l,a2
		move.b	(v_lz_deform).w,d2
		move.b	d2,d3
		addi.w	#$80,(v_lz_deform).w

		add.w	(v_bgscreenposy).w,d2
		andi.w	#$FF,d2
		add.w	(v_screenposy).w,d3
		andi.w	#$FF,d3
		lea	(v_hscrolltablebuffer).w,a1
		move.w	#$DF,d1
		move.w	(v_screenposx).w,d0
		neg.w	d0
		move.w	d0,d6
		swap	d0
		move.w	(v_bgscreenposx).w,d0
		neg.w	d0
		move.w	(v_waterpos1).w,d4
		move.w	(v_screenposy).w,d5
	; write normal scroll before meeting water position
	@normalLoop:
		cmp.w	d4,d5	; is current y >= water y?
		bge.s	@underwaterLoop	; if yes, branch
		move.l	d0,(a1)+
		addq.w	#1,d5
		addq.b	#1,d2
		addq.b	#1,d3
		dbf	d1,@normalLoop
		rts
	; apply water deformation when underwater
	@underwaterLoop:
		move.b	(a3,d3.w),d4
		ext.w	d4
		add.w	d6,d4
		move.w	d4,(a1)+
		move.b	(a2,d2.w),d4
		ext.w	d4
		add.w	d0,d4
		move.w	d4,(a1)+
		addq.b	#1,d2
		addq.b	#1,d3
		dbf	d1,@underwaterLoop
		rts

Lz_Scroll_Data:
		dc.b $01,$01,$02,$02,$03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $FF,$FF,$FE,$FE,$FD,$FD,$FD,$FD,$FE,$FE,$FF,$FF,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $01,$01,$02,$02,$03,$03,$03,$03,$02,$02,$01,$01,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
; End of function Deform_LZ

; ---------------------------------------------------------------------------
; Marble Zone background layer deformation code
; ---------------------------------------------------------------------------

Deform_MZ:
	; block 1 - dungeon interior
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#2,d6
		bsr.w	BGScroll_Block1
	; block 3 - mountains
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#6,d4
		moveq	#6,d6
		bsr.w	BGScroll_Block3
	; block 2 - bushes & antique buildings
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#7,d4
		moveq	#4,d6
		bsr.w	BGScroll_Block2
	; calculate y-position of background
		move.w	#$200,d0	; start with 512px, ignoring 2 chunks
		move.w	(v_screenposy).w,d1
		subi.w	#$1C8,d1	; 0% scrolling when y <= 56px
		blo.s	@noYscroll
		move.w	d1,d2
		add.w	d1,d1
		add.w	d2,d1
		asr.w	#2,d1
		add.w	d1,d0
	@noYscroll:
		move.w	d0,(v_bg2screenposy).w
		move.w	d0,(v_bg3screenposy).w
		bsr.w	BGScroll_YAbsolute
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w
	; do something with redraw flags
		move.b	(v_bg1_scroll_flags).w,d0
		or.b	(v_bg2_scroll_flags).w,d0
		or.b	d0,(v_bg3_scroll_flags).w
		clr.b	(v_bg1_scroll_flags).w
		clr.b	(v_bg2_scroll_flags).w
	; calculate background scroll buffer
		lea	(v_bgscroll_buffer).w,a1
		move.w	(v_screenposx).w,d2
		neg.w	d2
		move.w	d2,d0
		asr.w	#2,d0
		sub.w	d2,d0
		ext.l	d0
		asl.l	#3,d0
		divs.w	#5,d0
		ext.l	d0
		asl.l	#4,d0
		asl.l	#8,d0
		moveq	#0,d3
		move.w	d2,d3
		asr.w	#1,d3
		move.w	#4,d1
	@cloudLoop:
		move.w	d3,(a1)+
		swap	d3
		add.l	d0,d3
		swap	d3
		dbf	d1,@cloudLoop

		move.w	(v_bg3screenposx).w,d0
		neg.w	d0
		move.w	#1,d1
	@mountainLoop:
		move.w	d0,(a1)+
		dbf	d1,@mountainLoop

		move.w	(v_bg2screenposx).w,d0
		neg.w	d0
		move.w	#8,d1
	@bushLoop:
		move.w	d0,(a1)+
		dbf	d1,@bushLoop

		move.w	(v_bgscreenposx).w,d0
		neg.w	d0
		move.w	#$F,d1
	@interiorLoop:
		move.w	d0,(a1)+
		dbf	d1,@interiorLoop

		lea	(v_bgscroll_buffer).w,a2
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0	; subtract 512px (unused 2 chunks)
		move.w	d0,d2
		cmpi.w	#$100,d0
		blo.s	@limitY
		move.w	#$100,d0
	@limitY:
		andi.w	#$1F0,d0
		lsr.w	#3,d0
		lea	(a2,d0.w),a2
		bra.w	Bg_Scroll_X
; End of function Deform_MZ

; ---------------------------------------------------------------------------
; Star Light Zone background layer deformation code
; ---------------------------------------------------------------------------

Deform_SLZ:
	; vertical scrolling
		move.w	(v_scrshifty).w,d5
		ext.l	d5
		asl.l	#7,d5
		bsr.w	Bg_Scroll_Y
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w
	; calculate background scroll buffer
		lea	(v_bgscroll_buffer).w,a1
		move.w	(v_screenposx).w,d2
		neg.w	d2
		move.w	d2,d0
		asr.w	#3,d0
		sub.w	d2,d0
		ext.l	d0
		asl.l	#4,d0
		divs.w	#$1C,d0
		ext.l	d0
		asl.l	#4,d0
		asl.l	#8,d0
		moveq	#0,d3
		move.w	d2,d3
		move.w	#$1B,d1
	@starLoop:
		move.w	d3,(a1)+
		swap	d3
		add.l	d0,d3
		swap	d3
		dbf	d1,@starLoop

		move.w	d2,d0
		asr.w	#3,d0
		move.w	d0,d1
		asr.w	#1,d1
		add.w	d1,d0
		move.w	#4,d1
	@buildingLoop1:		; distant black buildings
		move.w	d0,(a1)+
		dbf	d1,@buildingLoop1

		move.w	d2,d0
		asr.w	#2,d0
		move.w	#4,d1
	@buildingLoop2:		; closer buildings
		move.w	d0,(a1)+
		dbf	d1,@buildingLoop2

		move.w	d2,d0
		asr.w	#1,d0
		move.w	#$1D,d1
	@bottomLoop:		; bottom part of background
		move.w	d0,(a1)+
		dbf	d1,@bottomLoop

		lea	(v_bgscroll_buffer).w,a2
		move.w	(v_bgscreenposy).w,d0
		move.w	d0,d2
		subi.w	#$C0,d0
		andi.w	#$3F0,d0
		lsr.w	#3,d0
		lea	(a2,d0.w),a2
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
Bg_Scroll_X:
		lea	(v_hscrolltablebuffer).w,a1
		move.w	#$E,d1
		move.w	(v_screenposx).w,d0
		neg.w	d0
		swap	d0
		andi.w	#$F,d2
		add.w	d2,d2
		move.w	(a2)+,d0
		jmp	@pixelJump(pc,d2.w)		; skip pixels for first row
	@blockLoop:
		move.w	(a2)+,d0
	@pixelJump:
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		dbf	d1,@blockLoop
		rts

; ---------------------------------------------------------------------------
; Spring Yard Zone background layer deformation code
; ---------------------------------------------------------------------------

Deform_SYZ:
	; vertical scrolling
		move.w	(v_scrshifty).w,d5
		ext.l	d5
		asl.l	#4,d5
		move.l	d5,d1
		asl.l	#1,d5
		add.l	d1,d5
		bsr.w	Bg_Scroll_Y
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w
	; calculate background scroll buffer
		lea	(v_bgscroll_buffer).w,a1
		move.w	(v_screenposx).w,d2
		neg.w	d2
		move.w	d2,d0
		asr.w	#3,d0
		sub.w	d2,d0
		ext.l	d0
		asl.l	#3,d0
		divs.w	#8,d0
		ext.l	d0
		asl.l	#4,d0
		asl.l	#8,d0
		moveq	#0,d3
		move.w	d2,d3
		asr.w	#1,d3
		move.w	#7,d1
	@cloudLoop:
		move.w	d3,(a1)+
		swap	d3
		add.l	d0,d3
		swap	d3
		dbf	d1,@cloudLoop

		move.w	d2,d0
		asr.w	#3,d0
		move.w	#4,d1
	@mountainLoop:
		move.w	d0,(a1)+
		dbf	d1,@mountainLoop

		move.w	d2,d0
		asr.w	#2,d0
		move.w	#5,d1
	@buildingLoop:
		move.w	d0,(a1)+
		dbf	d1,@buildingLoop

		move.w	d2,d0
		move.w	d2,d1
		asr.w	#1,d1
		sub.w	d1,d0
		ext.l	d0
		asl.l	#4,d0
		divs.w	#$E,d0
		ext.l	d0
		asl.l	#4,d0
		asl.l	#8,d0
		moveq	#0,d3
		move.w	d2,d3
		asr.w	#1,d3
		move.w	#$D,d1
	@bushLoop:
		move.w	d3,(a1)+
		swap	d3
		add.l	d0,d3
		swap	d3
		dbf	d1,@bushLoop

		lea	(v_bgscroll_buffer).w,a2
		move.w	(v_bgscreenposy).w,d0
		move.w	d0,d2
		andi.w	#$1F0,d0
		lsr.w	#3,d0
		lea	(a2,d0.w),a2
		bra.w	Bg_Scroll_X
; End of function Deform_SYZ

; ---------------------------------------------------------------------------
; Scrap Brain Zone background layer deformation	code
; ---------------------------------------------------------------------------

Deform_SBZ:
		tst.b	(v_act).w
		bne.w	Deform_SBZ2
	; block 1 - lower black buildings
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#7,d4
		moveq	#2,d6
		bsr.w	BGScroll_Block1
	; block 3 - distant brown buildings
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#6,d4
		moveq	#6,d6
		bsr.w	BGScroll_Block3
	; block 2 - upper black buildings
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#5,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#4,d6
		bsr.w	BGScroll_Block2
	; vertical scrolling
		moveq	#0,d4
		move.w	(v_scrshifty).w,d5
		ext.l	d5
		asl.l	#5,d5
		bsr.w	BGScroll_YRelative

		move.w	(v_bgscreenposy).w,d0
		move.w	d0,(v_bg2screenposy).w
		move.w	d0,(v_bg3screenposy).w
		move.w	d0,(v_bgscrposy_vdp).w
		move.b	(v_bg1_scroll_flags).w,d0
		or.b	(v_bg3_scroll_flags).w,d0
		or.b	d0,(v_bg2_scroll_flags).w
		clr.b	(v_bg1_scroll_flags).w
		clr.b	(v_bg3_scroll_flags).w
	; calculate background scroll buffer
		lea	(v_bgscroll_buffer).w,a1
		move.w	(v_screenposx).w,d2
		neg.w	d2
		asr.w	#2,d2
		move.w	d2,d0
		asr.w	#1,d0
		sub.w	d2,d0
		ext.l	d0
		asl.l	#3,d0
		divs.w	#4,d0
		ext.l	d0
		asl.l	#4,d0
		asl.l	#8,d0
		moveq	#0,d3
		move.w	d2,d3
		move.w	#3,d1
	@cloudLoop:
		move.w	d3,(a1)+
		swap	d3
		add.l	d0,d3
		swap	d3
		dbf	d1,@cloudLoop

		move.w	(v_bg3screenposx).w,d0
		neg.w	d0
		move.w	#9,d1
	@buildingLoop1:		; distant brown buildings
		move.w	d0,(a1)+
		dbf	d1,@buildingLoop1

		move.w	(v_bg2screenposx).w,d0
		neg.w	d0
		move.w	#6,d1
	@buildingLoop2:		; upper black buildings
		move.w	d0,(a1)+
		dbf	d1,@buildingLoop2

		move.w	(v_bgscreenposx).w,d0
		neg.w	d0
		move.w	#$A,d1
	@buildingLoop3:		; lower black buildings
		move.w	d0,(a1)+
		dbf	d1,@buildingLoop3
		lea	(v_bgscroll_buffer).w,a2
		move.w	(v_bgscreenposy).w,d0
		move.w	d0,d2
		andi.w	#$1F0,d0
		lsr.w	#3,d0
		lea	(a2,d0.w),a2
		bra.w	Bg_Scroll_X
;-------------------------------------------------------------------------------
Deform_SBZ2:;loc_68A2:
	; plain background deformation
		move.w	(v_scrshiftx).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.w	(v_scrshifty).w,d5
		ext.l	d5
		asl.l	#5,d5
		bsr.w	BGScroll_XY
		move.w	(v_bgscreenposy).w,(v_bgscrposy_vdp).w
	; copy fg & bg x-position to hscroll table
		lea	(v_hscrolltablebuffer).w,a1
		move.w	#223,d1
		move.w	(v_screenposx).w,d0
		neg.w	d0
		swap	d0
		move.w	(v_bgscreenposx).w,d0
		neg.w	d0
	@loop:
		move.l	d0,(a1)+
		dbf	d1,@loop
		rts
; End of function Deform_SBZ

; ---------------------------------------------------------------------------
; Subroutine to scroll the level horizontally as Sonic moves
; ---------------------------------------------------------------------------

ScrollHoriz:
		move.w	(v_screenposx).w,d4 ; save old screen position
		bsr.s	MoveScreenHoriz
		move.w	(v_screenposx).w,d0
		andi.w	#$10,d0
		move.b	(v_fg_xblock).w,d1
		eor.b	d1,d0
		bne.s	@return
		eori.b	#$10,(v_fg_xblock).w
		move.w	(v_screenposx).w,d0
		sub.w	d4,d0		; compare new with old screen position
		bpl.s	@scrollRight

		bset	#2,(v_fg_scroll_flags).w ; screen moves backward
		rts

	@scrollRight:
		bset	#3,(v_fg_scroll_flags).w ; screen moves forward

	@return:
		rts
; End of function ScrollHoriz

; ScrollHoriz2:
MoveScreenHoriz:
		move.w	(v_player+obX).w,d0
		sub.w	(v_screenposx).w,d0 ; Sonic's distance from left edge of screen
		subi.w	#144,d0		; is distance less than 144px?
		blo.s	SH_BehindMid	; if yes, branch
		subi.w	#16,d0		; is distance more than 160px?
		bhs.s	SH_AheadOfMid	; if yes, branch
		clr.w	(v_scrshiftx).w
		rts
; ===========================================================================

SH_AheadOfMid:
		cmpi.w	#16,d0		; is Sonic within 16px of middle area?
		blo.s	SH_Ahead16	; if yes, branch
		move.w	#16,d0		; set to 16 if greater

	SH_Ahead16:
		add.w	(v_screenposx).w,d0
		cmp.w	(v_limitright2).w,d0
		blt.s	SH_SetScreen
		move.w	(v_limitright2).w,d0

SH_SetScreen:
		move.w	d0,d1
		sub.w	(v_screenposx).w,d1
		asl.w	#8,d1
		move.w	d0,(v_screenposx).w ; set new screen position
		move.w	d1,(v_scrshiftx).w ; set distance for screen movement
		rts
; ===========================================================================

SH_BehindMid:
		add.w	(v_screenposx).w,d0
		cmp.w	(v_limitleft2).w,d0
		bgt.s	SH_SetScreen
		move.w	(v_limitleft2).w,d0
		bra.s	SH_SetScreen
; End of function MoveScreenHoriz

; ===========================================================================
		tst.w	d0
		bpl.s	loc_6610
		move.w	#-2,d0
		bra.s	SH_BehindMid

loc_6610:
		move.w	#2,d0
		bra.s	SH_AheadOfMid

; ---------------------------------------------------------------------------
; Subroutine to scroll the level vertically as Sonic moves
; ---------------------------------------------------------------------------

ScrollVertical:
		moveq	#0,d1
		move.w	(v_player+obY).w,d0
		sub.w	(v_screenposy).w,d0 ; Sonic's distance from top of screen
		btst	#2,(v_player+obStatus).w ; is Sonic rolling?
		beq.s	SV_NotRolling	; if not, branch
		subq.w	#5,d0

	SV_NotRolling:
		btst	#1,(v_player+obStatus).w ; is Sonic jumping?
		beq.s	loc_664A	; if not, branch

		addi.w	#32,d0
		sub.w	(v_lookshift).w,d0
		blo.s	loc_6696
		subi.w	#64,d0
		bhs.s	loc_6696
		tst.b	(f_bgscrollvert).w
		bne.s	loc_66A8
		bra.s	loc_6656
; ===========================================================================

loc_664A:
		sub.w	(v_lookshift).w,d0
		bne.s	loc_665C
		tst.b	(f_bgscrollvert).w
		bne.s	loc_66A8

loc_6656:
		clr.w	(v_scrshifty).w
		rts
; ===========================================================================

loc_665C:
		cmpi.w	#$60,(v_lookshift).w
		bne.s	loc_6684
		move.w	(v_player+obInertia).w,d1
		bpl.s	loc_666C
		neg.w	d1

loc_666C:
		cmpi.w	#$800,d1
		bhs.s	loc_6696
		move.w	#$600,d1
		cmpi.w	#6,d0
		bgt.s	loc_66F6
		cmpi.w	#-6,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_6684:
		move.w	#$200,d1
		cmpi.w	#2,d0
		bgt.s	loc_66F6
		cmpi.w	#-2,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_6696:
		move.w	#$1000,d1
		cmpi.w	#$10,d0
		bgt.s	loc_66F6
		cmpi.w	#-$10,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_66A8:
		moveq	#0,d0
		move.b	d0,(f_bgscrollvert).w

loc_66AE:
		moveq	#0,d1
		move.w	d0,d1
		add.w	(v_screenposy).w,d1
		tst.w	d0
		bpl.w	loc_6700
		bra.w	loc_66CC
; ===========================================================================

loc_66C0:
		neg.w	d1
		ext.l	d1
		asl.l	#8,d1
		add.l	(v_screenposy).w,d1
		swap	d1

loc_66CC:
		cmp.w	(v_limittop2).w,d1
		bgt.s	loc_6724
		cmpi.w	#-$100,d1
		bgt.s	loc_66F0
		andi.w	#$7FF,d1
		andi.w	#$7FF,(v_player+obY).w
		andi.w	#$7FF,(v_screenposy).w
		andi.w	#$3FF,(v_bgscreenposy).w
		bra.s	loc_6724
; ===========================================================================

loc_66F0:
		move.w	(v_limittop2).w,d1
		bra.s	loc_6724
; ===========================================================================

loc_66F6:
		ext.l	d1
		asl.l	#8,d1
		add.l	(v_screenposy).w,d1
		swap	d1

loc_6700:
		cmp.w	(v_limitbtm2).w,d1
		blt.s	loc_6724
		subi.w	#$800,d1
		blo.s	loc_6720
		andi.w	#$7FF,(v_player+obY).w
		subi.w	#$800,(v_screenposy).w
		andi.w	#$3FF,(v_bgscreenposy).w
		bra.s	loc_6724
; ===========================================================================

loc_6720:
		move.w	(v_limitbtm2).w,d1

loc_6724:
		move.w	(v_screenposy).w,d4
		swap	d1
		move.l	d1,d3
		sub.l	(v_screenposy).w,d3
		ror.l	#8,d3
		move.w	d3,(v_scrshifty).w
		move.l	d1,(v_screenposy).w
		move.w	(v_screenposy).w,d0
		andi.w	#$10,d0
		move.b	(v_fg_yblock).w,d1
		eor.b	d1,d0
		bne.s	@return
		eori.b	#$10,(v_fg_yblock).w
		move.w	(v_screenposy).w,d0
		sub.w	d4,d0
		bpl.s	@scrollBottom
		bset	#0,(v_fg_scroll_flags).w
		rts
; ===========================================================================

	@scrollBottom:
		bset	#1,(v_fg_scroll_flags).w

	@return:
		rts
; End of function ScrollVertical

; Scrolls background and sets redraw flags.
; d4 - background x offset * $10000
; d5 - background y offset * $10000

BGScroll_XY:
		move.l	(v_bgscreenposx).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(v_bgscreenposx).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	(v_bg1_xblock).w,d3
		eor.b	d3,d1
		bne.s	BGScroll_YRelative	; no change in Y
		eori.b	#$10,(v_bg1_xblock).w
		sub.l	d2,d0	; new - old
		bpl.s	@scrollRight
		bset	#2,(v_bg1_scroll_flags).w
		bra.s	BGScroll_YRelative
	@scrollRight:
		bset	#3,(v_bg1_scroll_flags).w
BGScroll_YRelative:
		move.l	(v_bgscreenposy).w,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,(v_bgscreenposy).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	(v_bg1_yblock).w,d2
		eor.b	d2,d1
		bne.s	@return
		eori.b	#$10,(v_bg1_yblock).w
		sub.l	d3,d0
		bpl.s	@scrollBottom
		bset	#0,(v_bg1_scroll_flags).w
		rts
	@scrollBottom:
		bset	#1,(v_bg1_scroll_flags).w
	@return:
		rts
; End of function BGScroll_XY

Bg_Scroll_Y:
		move.l	(v_bgscreenposy).w,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,(v_bgscreenposy).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	(v_bg1_yblock).w,d2
		eor.b	d2,d1
		bne.s	@return
		eori.b	#$10,(v_bg1_yblock).w
		sub.l	d3,d0
		bpl.s	@scrollBottom
		bset	#4,(v_bg1_scroll_flags).w
		rts
	@scrollBottom:
		bset	#5,(v_bg1_scroll_flags).w
	@return:
		rts

BGScroll_YAbsolute:
		move.w	(v_bgscreenposy).w,d3
		move.w	d0,(v_bgscreenposy).w
		move.w	d0,d1
		andi.w	#$10,d1
		move.b	(v_bg1_yblock).w,d2
		eor.b	d2,d1
		bne.s	@return
		eori.b	#$10,(v_bg1_yblock).w
		sub.w	d3,d0
		bpl.s	@scrollBottom
		bset	#0,(v_bg1_scroll_flags).w
		rts
	@scrollBottom:
		bset	#1,(v_bg1_scroll_flags).w
	@return:
		rts
; End of function BGScroll_YAbsolute

; d6 - bit to set for redraw

BGScroll_Block1:
		move.l	(v_bgscreenposx).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(v_bgscreenposx).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	(v_bg1_xblock).w,d3
		eor.b	d3,d1
		bne.s	@return
		eori.b	#$10,(v_bg1_xblock).w
		sub.l	d2,d0
		bpl.s	@scrollRight
		bset	d6,(v_bg1_scroll_flags).w
		bra.s	@return
	@scrollRight:
		addq.b	#1,d6
		bset	d6,(v_bg1_scroll_flags).w
	@return:
		rts
; End of function BGScroll_Block1

BGScroll_Block2:
		move.l	(v_bg2screenposx).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(v_bg2screenposx).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	(v_bg2_xblock).w,d3
		eor.b	d3,d1
		bne.s	@return
		eori.b	#$10,(v_bg2_xblock).w
		sub.l	d2,d0
		bpl.s	@scrollRight
		bset	d6,(v_bg2_scroll_flags).w
		bra.s	@return
	@scrollRight:
		addq.b	#1,d6
		bset	d6,(v_bg2_scroll_flags).w
	@return:
		rts
;-------------------------------------------------------------------------------
BGScroll_Block3:
		move.l	(v_bg3screenposx).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(v_bg3screenposx).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	(v_bg3_xblock).w,d3
		eor.b	d3,d1
		bne.s	@return
		eori.b	#$10,(v_bg3_xblock).w
		sub.l	d2,d0
		bpl.s	@scrollRight
		bset	d6,(v_bg3_scroll_flags).w
		bra.s	@return
	@scrollRight:
		addq.b	#1,d6
		bset	d6,(v_bg3_scroll_flags).w
	@return:
		rts

; sub_6886:
LoadTilesAsYouMove_BGOnly:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_bg1_scroll_flags).w,a2
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2
		bsr.w	DrawBGScrollBlock1
		lea	(v_bg2_scroll_flags).w,a2
		lea	(v_bg2screenposx).w,a3
		bra.w	DrawBGScrollBlock2
; End of function sub_6886

; ---------------------------------------------------------------------------
; Subroutine to display	correct	tiles as you move
; ---------------------------------------------------------------------------

LoadTilesAsYouMove:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		; First, update the background
		lea	(v_bg1_scroll_flags_dup).w,a2	; Scroll block 1 scroll flags
		lea	(v_bgscreenposx_dup).w,a3	; Scroll block 1 X coordinate
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2			; VRAM thing for selecting Plane B
		bsr.w	DrawBGScrollBlock1
		lea	(v_bg2_scroll_flags_dup).w,a2	; Scroll block 2 scroll flags
		lea	(v_bg2screenposx_dup).w,a3	; Scroll block 2 X coordinate
		bsr.w	DrawBGScrollBlock2
		lea	(v_bg3_scroll_flags_dup).w,a2	; Scroll block 3 scroll flags
		lea	(v_bg3screenposx_dup).w,a3	; Scroll block 3 X coordinate
		bsr.w	DrawBGScrollBlock3
		; Then, update the foreground
		lea	(v_fg_scroll_flags_dup).w,a2	; Foreground scroll flags
		lea	(v_screenposx_dup).w,a3		; Foreground X coordinate
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2			; VRAM thing for selecting Plane A
		; The FG's update function is inlined here
		tst.b	(a2)
		beq.s	locret_6952	; If there are no flags set, nothing needs updating
		bclr	#0,(a2)
		beq.s	loc_6908
		; Draw new tiles at the top
		moveq	#-16,d4	; Y coordinate. Note that 16 is the size of a block in pixels
		moveq	#-16,d5 ; X coordinate
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4 ; Y coordinate
		moveq	#-16,d5 ; X coordinate
		bsr.w	DrawBlocks_LR

loc_6908:
		bclr	#1,(a2)
		beq.s	loc_6922
		; Draw new tiles at the bottom
		move.w	#224,d4	; Start at bottom of the screen. Since this draws from top to bottom, we don't need 224+16
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_6922:
		bclr	#2,(a2)
		beq.s	loc_6938
		; Draw new tiles on the left
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_TB

loc_6938:
		bclr	#3,(a2)
		beq.s	locret_6952
		; Draw new tiles on the right
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	DrawBlocks_TB

locret_6952:
		rts
; End of function LoadTilesAsYouMove

; sub_6954:
DrawBGScrollBlock1:
		tst.b	(a2)
		beq.w	locret_69F2
		bclr	#0,(a2)
		beq.s	loc_6972
		; Draw new tiles at the top
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_6972:
		bclr	#1,(a2)
		beq.s	loc_698E
		; Draw new tiles at the top
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_698E:
		bclr	#2,(a2)

		beq.s	locj_6D56
		; Draw new tiles on the left
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_TB
locj_6D56:

		bclr	#3,(a2)
		beq.s	locj_6D70
		; Draw new tiles on the right
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	DrawBlocks_TB
locj_6D70:

		bclr	#4,(a2)
		beq.s	locj_6D88
		; Draw entire row at the top
		moveq	#-16,d4
		moveq	#0,d5
		bsr.w	Calc_VRAM_Pos_2
		moveq	#-16,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6D88:

		bclr	#5,(a2)
		beq.s	locret_69F2
		; Draw entire row at the bottom
		move.w	#224,d4
		moveq	#0,d5
		bsr.w	Calc_VRAM_Pos_2
		move.w	#224,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3

locret_69F2:
		rts
; End of function DrawBGScrollBlock1

; Essentially, this draws everything that isn't scroll block 1
; sub_69F4:
DrawBGScrollBlock2:
		tst.b	(a2)
		beq.w	locj_6DF2
		cmpi.b	#id_SBZ,(v_zone).w
		beq.w	Draw_SBz
		bclr	#0,(a2)
		beq.s	locj_6DD2
		; Draw new tiles on the left
		move.w	#224/2,d4	; Draw the bottom half of the screen
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224/2,d4
		moveq	#-16,d5
		moveq	#3-1,d6		; Draw three rows... could this be a repurposed version of the above unused code?
		bsr.w	DrawBlocks_TB_2
locj_6DD2:
		bclr	#1,(a2)
		beq.s	locj_6DF2
		; Draw new tiles on the right
		move.w	#224/2,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224/2,d4
		move.w	#320,d5
		moveq	#3-1,d6
		bsr.w	DrawBlocks_TB_2
locj_6DF2:
		rts
;===============================================================================
locj_6DF4:
		dc.b $00,$00,$00,$00,$00,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$04
		dc.b $04,$04,$04,$04,$04,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$00
;===============================================================================
Draw_SBz:
		moveq	#-16,d4
		bclr	#0,(a2)
		bne.s	locj_6E28
		bclr	#1,(a2)
		beq.s	locj_6E72
		move.w	#224,d4
locj_6E28:
		lea	(locj_6DF4+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		lea	(locj_6FE4).l,a3
		movea.w	(a3,d0.w),a3
		beq.s	locj_6E5E
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_6E72
;===============================================================================
locj_6E5E:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6E72:
		tst.b	(a2)
		bne.s	locj_6E78
		rts
;===============================================================================
locj_6E78:
		moveq	#-16,d4
		moveq	#-16,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	locj_6E8C
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#320,d5
locj_6E8C:
		lea	(locj_6DF4).l,a0
		move.w	(v_bgscreenposy).w,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	locj_6FEC
;===============================================================================

; locj_6EA4:
DrawBGScrollBlock3:
		tst.b	(a2)
		beq.w	locj_6EF0
		cmpi.b	#id_MZ,(v_zone).w
		beq.w	Draw_Mz
		bclr	#0,(a2)
		beq.s	locj_6ED0
		; Draw new tiles on the left
		move.w	#$40,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4
		moveq	#-16,d5
		moveq	#3-1,d6
		bsr.w	DrawBlocks_TB_2
locj_6ED0:
		bclr	#1,(a2)
		beq.s	locj_6EF0
		; Draw new tiles on the right
		move.w	#$40,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4
		move.w	#320,d5
		moveq	#3-1,d6
		bsr.w	DrawBlocks_TB_2
locj_6EF0:
		rts
locj_6EF2:
		dc.b $00,$00,$00,$00,$00,$00,$06,$06,$04,$04,$04,$04,$04,$04,$04,$04
		dc.b $04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$00
;===============================================================================
Draw_Mz:
		moveq	#-16,d4
		bclr	#0,(a2)
		bne.s	locj_6F66
		bclr	#1,(a2)
		beq.s	locj_6FAE
		move.w	#224,d4
locj_6F66:
		lea	(locj_6EF2+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	locj_6FE4(pc,d0.w),a3
		beq.s	locj_6F9A
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_6FAE
;===============================================================================
locj_6F9A:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6FAE:
		tst.b	(a2)
		bne.s	locj_6FB4
		rts
;===============================================================================
locj_6FB4:
		moveq	#-16,d4
		moveq	#-16,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	locj_6FC8
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#320,d5
locj_6FC8:
		lea	(locj_6EF2).l,a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	locj_6FEC
;===============================================================================
locj_6FE4:
		dc.w v_bgscreenposx_dup, v_bgscreenposx_dup, v_bg2screenposx_dup, v_bg3screenposx_dup
locj_6FEC:
		moveq	#((224+16+16)/16)-1,d6
		move.l	#$800000,d7
locj_6FF4:
		moveq	#0,d0
		move.b	(a0)+,d0
		btst	d0,(a2)
		beq.s	locj_701C
		movea.w	locj_6FE4(pc,d0.w),a3
		movem.l	d4/d5/a0,-(sp)
		movem.l	d4/d5,-(sp)
		bsr.w	GetBlockData
		movem.l	(sp)+,d4/d5
		bsr.w	Calc_VRAM_Pos
		bsr.w	DrawBlock
		movem.l	(sp)+,d4/d5/a0
locj_701C:
		addi.w	#16,d4
		dbf	d6,locj_6FF4
		clr.b	(a2)
		rts

; Don't be fooled by the name: this function's for drawing from left to right
; when the camera's moving up or down
; DrawTiles_LR:
DrawBlocks_LR:
		moveq	#((320+16+16)/16)-1,d6	; Draw the entire width of the screen + two extra columns
; DrawTiles_LR_2:
DrawBlocks_LR_2:
		move.l	#$800000,d7	; Delta between rows of tiles
		move.l	d0,d1

	@loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData
		move.l	d1,d0
		bsr.w	DrawBlock
		addq.b	#4,d1		; Two tiles ahead
		andi.b	#$7F,d1		; Wrap around row
		movem.l	(sp)+,d4-d5
		addi.w	#16,d5		; Move X coordinate one block ahead
		dbf	d6,@loop
		rts
; End of function DrawBlocks_LR

; DrawTiles_LR_3:
DrawBlocks_LR_3:
		move.l	#$800000,d7
		move.l	d0,d1

	@loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData_2
		move.l	d1,d0
		bsr.w	DrawBlock
		addq.b	#4,d1
		andi.b	#$7F,d1
		movem.l	(sp)+,d4-d5
		addi.w	#16,d5
		dbf	d6,@loop
		rts
; End of function DrawBlocks_LR_3

; Don't be fooled by the name: this function's for drawing from top to bottom
; when the camera's moving left or right
; DrawTiles_TB:
DrawBlocks_TB:
		moveq	#((224+16+16)/16)-1,d6	; Draw the entire height of the screen + two extra rows
; DrawTiles_TB_2:
DrawBlocks_TB_2:
		move.l	#$800000,d7	; Delta between rows of tiles
		move.l	d0,d1

	@loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData
		move.l	d1,d0
		bsr.w	DrawBlock
		addi.w	#$100,d1	; Two rows ahead
		andi.w	#$FFF,d1	; Wrap around plane
		movem.l	(sp)+,d4-d5
		addi.w	#16,d4		; Move X coordinate one block ahead
		dbf	d6,@loop
		rts
; End of function DrawBlocks_TB_2

; Draws a block's worth of tiles
; Parameters:
; a0 = Pointer to block metadata (block index and X/Y flip)
; a1 = Pointer to block
; a5 = Pointer to VDP command port
; a6 = Pointer to VDP data port
; d0 = VRAM command to access plane
; d2 = VRAM plane A/B specifier
; d7 = Plane row delta
; DrawTiles:
DrawBlock:
		or.w	d2,d0	; OR in that plane A/B specifier to the VRAM command
		swap	d0
		btst	#4,(a0)	; Check Y-flip bit
		bne.s	DrawFlipY
		btst	#3,(a0)	; Check X-flip bit
		bne.s	DrawFlipX
		move.l	d0,(a5)
		move.l	(a1)+,(a6)	; Write top two tiles
		add.l	d7,d0		; Next row
		move.l	d0,(a5)
		move.l	(a1)+,(a6)	; Write bottom two tiles
		rts
; ===========================================================================

DrawFlipX:
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4	; Invert X-flip bits of each tile
		swap	d4		; Swap the tiles around
		move.l	d4,(a6)		; Write top two tiles
		add.l	d7,d0		; Next row
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)		; Write bottom two tiles
		rts
; ===========================================================================

DrawFlipY:
		btst	#3,(a0)
		bne.s	DrawFlipXY
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$10001000,d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$10001000,d5
		move.l	d5,(a6)
		rts
; ===========================================================================

DrawFlipXY:
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$18001800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$18001800,d5
		swap	d5
		move.l	d5,(a6)
		rts
; End of function DrawBlocks

; ===========================================================================
; Gets address of block at a certain coordinate
; Parameters:
; a4 = Pointer to level layout
; d4 = Relative Y coordinate
; d5 = Relative X coordinate
; Returns:
; a0 = Address of block metadata
; a1 = Address of block
; DrawBlocks:
GetBlockData:
		add.w	(a3),d5		; Add camera X coordinate to relative coordinate
GetBlockData_2:
		add.w	4(a3),d4	; Add camera Y coordinate to relative coordinate
		lea	(v_16x16).w,a1
		; Turn Y coordinate into index into level layout
		move.w	d4,d3
		lsr.w	#1,d3
		andi.w	#$380,d3
		; Turn X coordinate into index into level layout
		lsr.w	#3,d5
		move.w	d5,d0
		lsr.w	#5,d0
		andi.w	#$7F,d0
		; Get chunk from level layout
		add.w	d3,d0
		moveq	#-1,d3
		move.b	(a4,d0.w),d3
		beq.s	locret_6C1E	; If chunk 00, just return a pointer to the first block (expected to be empty)
		; Turn chunk ID into index into chunk table
		subq.b	#1,d3
		andi.w	#$7F,d3
		ror.w	#7,d3
		; Turn Y coordinate into index into chunk
		add.w	d4,d4
		andi.w	#$1E0,d4
		; Turn X coordinate into index into chunk
		andi.w	#$1E,d5
		; Get block metadata from chunk
		add.w	d4,d3
		add.w	d5,d3
		movea.l	d3,a0
		move.w	(a0),d3
		; Turn block ID into address
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		adda.w	d3,a1

locret_6C1E:
		rts
; End of function GetBlockData

; Produces a VRAM plane access command from coordinates
; Parameters:
; d4 = Relative Y coordinate
; d5 = Relative X coordinate
; Returns VDP command in d0
Calc_VRAM_Pos:
		add.w	(a3),d5		; Add camera X coordinate
Calc_VRAM_Pos_2:
		add.w	4(a3),d4	; Add camera Y coordinate
		
		; Floor the coordinates to the nearest pair of tiles (the size of a block).
		; Also note that this wraps the value to the size of the plane:
		; The plane is 64*8 wide, so wrap at $100, and it's 32*8 tall, so wrap at $200
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		; Transform the adjusted coordinates into a VDP command
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0	; Highest bits of plane VRAM address
		swap	d0
		move.w	d4,d0
		rts
; End of function Calc_VRAM_Pos

; not used

; This is just like Calc_VRAM_Pos, but seemingly for an earlier
; VRAM layout: the only difference is the high bits of the
; plane's VRAM address, which are 10 instead of 11.
; Both the foreground and background are at $C000 and $E000
; respectively, so this one starting at $8000 makes no sense.
; sub_6C3C:
Calc_VRAM_Pos_Unknown:
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#2,d0
		swap	d0
		move.w	d4,d0
		rts
; End of function Calc_VRAM_Pos_Unknown

; ---------------------------------------------------------------------------
; Subroutine to load tiles as soon as the level	appears
; ---------------------------------------------------------------------------

LoadTilesFromStart:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_screenposx).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2
		bsr.s	DrawChunks
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2
		tst.b	(v_zone).w
		beq.w	Draw_GHz_Bg
		cmpi.b	#id_MZ,(v_zone).w
		beq.w	Draw_Mz_Bg
		cmpi.w	#(id_SBZ<<8)+0,(v_zone).w
		beq.w	Draw_SBz_Bg
		cmpi.b	#id_EndZ,(v_zone).w
		beq.w	Draw_GHz_Bg
; End of function LoadTilesFromStart

DrawChunks:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6

	@loop:
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	Calc_VRAM_Pos
		move.w	d1,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_2
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,@loop
		rts
; End of function DrawChunks

Draw_GHz_Bg:
		moveq	#0,d4
		moveq	#((224+16+16)/16)-1,d6
locj_7224:
		movem.l	d4-d6,-(sp)
		lea	(locj_724a),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_7224
		rts
locj_724a:
		dc.b $00,$00,$00,$00,$06,$06,$06,$04,$04,$04,$00,$00,$00,$00,$00,$00
;-------------------------------------------------------------------------------
Draw_Mz_Bg:;locj_725a:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6
locj_725E:
		movem.l	d4-d6,-(sp)
		lea	(locj_6EF2+1),a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_725E
		rts
;-------------------------------------------------------------------------------
Draw_SBz_Bg:;locj_7288:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6
locj_728C:
		movem.l	d4-d6,-(sp)
		lea	(locj_6DF4+1),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_728C
		rts
;-------------------------------------------------------------------------------
locj_72B2:
		dc.w v_bgscreenposx, v_bgscreenposx, v_bg2screenposx, v_bg3screenposx
locj_72Ba:
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	locj_72B2(pc,d0.w),a3
		beq.s	locj_72da
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_72EE
locj_72da:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_72EE:
		rts

; ---------------------------------------------------------------------------
; Subroutine to load basic level data
; ---------------------------------------------------------------------------

; MainLoadBlockLoad:
LevelDataLoad:
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea	(LevelHeaders).l,a2
		lea	(a2,d0.w),a2
		move.l	a2,-(sp)
		addq.l	#4,a2
		movea.l	(a2)+,a0
		lea	(v_16x16).w,a1	; RAM address for 16x16 mappings
		move.w	#0,d0
		bsr.w	EniDec
		movea.l	(a2)+,a0
		lea	(v_256x256).l,a1 ; RAM address for 256x256 mappings
		bsr.w	KosDec
		bsr.w	LevelLayoutLoad
		move.w	(a2)+,d0
		move.w	(a2),d0
		andi.w	#$FF,d0
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w ; is level SBZ3 (LZ4) ?
		bne.s	@notSBZ3	; if not, branch
		moveq	#palid_SBZ3,d0	; use SB3 palette

	@notSBZ3:
		cmpi.w	#(id_SBZ<<8)+1,(v_zone).w ; is level SBZ2?
		beq.s	@isSBZorFZ	; if yes, branch
		cmpi.w	#(id_SBZ<<8)+2,(v_zone).w ; is level FZ?
		bne.s	@normalpal	; if not, branch

	@isSBZorFZ:
		moveq	#palid_SBZ2,d0	; use SBZ2/FZ palette

	@normalpal:
		bsr.w	PalLoad1	; load palette (based on d0)
		movea.l	(sp)+,a2
		addq.w	#4,a2		; read number for 2nd PLC
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	@skipPLC	; if 2nd PLC is 0 (i.e. the ending sequence), branch
		bsr.w	AddPLC		; load pattern load cues

	@skipPLC:
		rts
; End of function LevelDataLoad

; ---------------------------------------------------------------------------
; Level layout loading subroutine
; ---------------------------------------------------------------------------

LevelLayoutLoad:
		lea	(v_lvllayout).w,a3
		move.w	#$1FF,d1
		moveq	#0,d0

LevLoad_ClrRam:
		move.l	d0,(a3)+
		dbf	d1,LevLoad_ClrRam ; clear the RAM ($A400-A7FF)

		lea	(v_lvllayout).w,a3 ; RAM address for level layout
		moveq	#0,d1
		bsr.w	LevelLayoutLoad2 ; load level layout into RAM
		lea	(v_lvllayout+$40).w,a3 ; RAM address for background layout
		moveq	#2,d1
; End of function LevelLayoutLoad

; "LevelLayoutLoad2" is run twice - for	the level and the background

LevelLayoutLoad2:
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#5,d0
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0
		add.w	d1,d0
		lea	(Level_Index).l,a1
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		moveq	#0,d1
		move.w	d1,d2
		move.b	(a1)+,d1	; load level width (in tiles)
		move.b	(a1)+,d2	; load level height (in tiles)

LevLoad_NumRows:
		move.w	d1,d0
		movea.l	a3,a0

LevLoad_Row:
		move.b	(a1)+,(a0)+
		dbf	d0,LevLoad_Row	; load 1 row
		lea	$80(a3),a3	; do next row
		dbf	d2,LevLoad_NumRows ; repeat for number of rows
		rts
; End of function LevelLayoutLoad2

; ---------------------------------------------------------------------------
; Dynamic level events
; ---------------------------------------------------------------------------

; DynScrResizeLoad:
DynamicLevelEvents:
		moveq	#0,d0
		move.b	(v_zone).w,d0
		add.w	d0,d0
		move.w	DLE_Index(pc,d0.w),d0
		jsr	DLE_Index(pc,d0.w) ; run level-specific events
		moveq	#2,d1
		move.w	(v_limitbtm1).w,d0
		sub.w	(v_limitbtm2).w,d0 ; has lower level boundary changed recently?
		beq.s	DLE_NoChg	; if not, branch
		bhs.s	loc_6DAC

		neg.w	d1
		move.w	(v_screenposy).w,d0
		cmp.w	(v_limitbtm1).w,d0
		bls.s	loc_6DA0
		move.w	d0,(v_limitbtm2).w
		andi.w	#$FFFE,(v_limitbtm2).w

loc_6DA0:
		add.w	d1,(v_limitbtm2).w
		move.b	#1,(f_bgscrollvert).w

DLE_NoChg:
		rts
; ===========================================================================

loc_6DAC:
		move.w	(v_screenposy).w,d0
		addq.w	#8,d0
		cmp.w	(v_limitbtm2).w,d0
		blo.s	loc_6DC4
		btst	#1,(v_player+obStatus).w
		beq.s	loc_6DC4
		add.w	d1,d1
		add.w	d1,d1

loc_6DC4:
		add.w	d1,(v_limitbtm2).w
		move.b	#1,(f_bgscrollvert).w
		rts
; End of function DynamicLevelEvents

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for dynamic level events
; ---------------------------------------------------------------------------
DLE_Index:	dc.w DLE_GHZ-DLE_Index, DLE_LZ-DLE_Index
		dc.w DLE_MZ-DLE_Index, DLE_SLZ-DLE_Index
		dc.w DLE_SYZ-DLE_Index, DLE_SBZ-DLE_Index
		dc.w DLE_Ending-DLE_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Green Hill Zone dynamic level events
; ---------------------------------------------------------------------------

DLE_GHZ:
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		move.w	DLE_GHZx(pc,d0.w),d0
		jmp	DLE_GHZx(pc,d0.w)
; ===========================================================================
DLE_GHZx:	dc.w DLE_GHZ1-DLE_GHZx
		dc.w DLE_GHZ2-DLE_GHZx
		dc.w DLE_GHZ3-DLE_GHZx
; ===========================================================================

DLE_GHZ1:
		move.w	#$300,(v_limitbtm1).w ; set lower y-boundary
		cmpi.w	#$1780,(v_screenposx).w ; has the camera reached $1780 on x-axis?
		blo.s	locret_6E08	; if not, branch
		move.w	#$400,(v_limitbtm1).w ; set lower y-boundary

locret_6E08:
		rts
; ===========================================================================

DLE_GHZ2:
		move.w	#$300,(v_limitbtm1).w
		cmpi.w	#$ED0,(v_screenposx).w
		blo.s	locret_6E3A
		move.w	#$200,(v_limitbtm1).w
		cmpi.w	#$1600,(v_screenposx).w
		blo.s	locret_6E3A
		move.w	#$400,(v_limitbtm1).w
		cmpi.w	#$1D60,(v_screenposx).w
		blo.s	locret_6E3A
		move.w	#$300,(v_limitbtm1).w

locret_6E3A:
		rts
; ===========================================================================

DLE_GHZ3:
		moveq	#0,d0
		move.b	(v_dle_routine).w,d0
		move.w	off_6E4A(pc,d0.w),d0
		jmp	off_6E4A(pc,d0.w)
; ===========================================================================
off_6E4A:	dc.w DLE_GHZ3main-off_6E4A
		dc.w DLE_GHZ3boss-off_6E4A
		dc.w DLE_GHZ3end-off_6E4A
; ===========================================================================

DLE_GHZ3main:
		move.w	#$300,(v_limitbtm1).w
		cmpi.w	#$380,(v_screenposx).w
		blo.s	locret_6E96
		move.w	#$310,(v_limitbtm1).w
		cmpi.w	#$960,(v_screenposx).w
		blo.s	locret_6E96
		cmpi.w	#$280,(v_screenposy).w
		blo.s	loc_6E98
		move.w	#$400,(v_limitbtm1).w
		cmpi.w	#$1380,(v_screenposx).w
		bhs.s	loc_6E8E
		move.w	#$4C0,(v_limitbtm1).w
		move.w	#$4C0,(v_limitbtm2).w

loc_6E8E:
		cmpi.w	#$1700,(v_screenposx).w
		bhs.s	loc_6E98

locret_6E96:
		rts
; ===========================================================================

loc_6E98:
		move.w	#$300,(v_limitbtm1).w
		addq.b	#2,(v_dle_routine).w
		rts
; ===========================================================================

DLE_GHZ3boss:
		cmpi.w	#$960,(v_screenposx).w
		bhs.s	loc_6EB0
		subq.b	#2,(v_dle_routine).w

loc_6EB0:
		cmpi.w	#$2960,(v_screenposx).w
		blo.s	locret_6EE8
		bsr.w	FindFreeObj
		bne.s	loc_6ED0
		move.b	#id_BossGreenHill,0(a1) ; load GHZ boss object
		move.w	#$2A60,obX(a1)
		move.w	#$280,obY(a1)

loc_6ED0:
		move.w	#bgm_Boss,d0
		bsr.w	PlaySound	; play boss music
		move.b	#1,(f_lockscreen).w ; lock screen
		addq.b	#2,(v_dle_routine).w
		moveq	#plcid_Boss,d0
		bra.w	AddPLC		; load boss patterns
; ===========================================================================

locret_6EE8:
		rts
; ===========================================================================

DLE_GHZ3end:
		move.w	(v_screenposx).w,(v_limitleft2).w
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Labyrinth Zone dynamic level events
; ---------------------------------------------------------------------------

DLE_LZ:
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		move.w	DLE_LZx(pc,d0.w),d0
		jmp	DLE_LZx(pc,d0.w)
; ===========================================================================
DLE_LZx:	dc.w DLE_LZ12-DLE_LZx
		dc.w DLE_LZ12-DLE_LZx
		dc.w DLE_LZ3-DLE_LZx
		dc.w DLE_SBZ3-DLE_LZx
; ===========================================================================

DLE_LZ12:
		rts
; ===========================================================================

DLE_LZ3:
		tst.b	(f_switch+$F).w	; has switch $F been pressed?
		beq.s	loc_6F28	; if not, branch
		lea	(v_lvllayout+$106).w,a1
		cmpi.b	#7,(a1)
		beq.s	loc_6F28
		move.b	#7,(a1)		; modify level layout
		move.w	#sfx_Rumbling,d0
		bsr.w	PlaySound_Special ; play rumbling sound

loc_6F28:
		tst.b	(v_dle_routine).w
		bne.s	locret_6F64
		cmpi.w	#$1CA0,(v_screenposx).w
		blo.s	locret_6F62
		cmpi.w	#$600,(v_screenposy).w
		bhs.s	locret_6F62
		bsr.w	FindFreeObj
		bne.s	loc_6F4A
		move.b	#id_BossLabyrinth,0(a1) ; load LZ boss object

loc_6F4A:
		move.w	#bgm_Boss,d0
		bsr.w	PlaySound	; play boss music
		move.b	#1,(f_lockscreen).w ; lock screen
		addq.b	#2,(v_dle_routine).w
		moveq	#plcid_Boss,d0
		bra.w	AddPLC		; load boss patterns
; ===========================================================================

locret_6F62:
		rts
; ===========================================================================

locret_6F64:
		rts
; ===========================================================================

DLE_SBZ3:
		cmpi.w	#$D00,(v_screenposx).w
		blo.s	locret_6F8C
		cmpi.w	#$18,(v_player+obY).w ; has Sonic reached the top of the level?
		bhs.s	locret_6F8C	; if not, branch
		clr.b	(v_lastlamp).w
		move.w	#1,(f_restart).w ; restart level
		move.w	#(id_SBZ<<8)+2,(v_zone).w ; set level number to 0502 (FZ)
		move.b	#1,(f_playerctrl).w ; lock controls

locret_6F8C:
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Marble Zone dynamic level events
; ---------------------------------------------------------------------------

DLE_MZ:
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		move.w	DLE_MZx(pc,d0.w),d0
		jmp	DLE_MZx(pc,d0.w)
; ===========================================================================
DLE_MZx:	dc.w DLE_MZ1-DLE_MZx
		dc.w DLE_MZ2-DLE_MZx
		dc.w DLE_MZ3-DLE_MZx
; ===========================================================================

DLE_MZ1:
		moveq	#0,d0
		move.b	(v_dle_routine).w,d0
		move.w	off_6FB2(pc,d0.w),d0
		jmp	off_6FB2(pc,d0.w)
; ===========================================================================
off_6FB2:	dc.w loc_6FBA-off_6FB2
		dc.w loc_6FEA-off_6FB2
		dc.w loc_702E-off_6FB2
		dc.w loc_7050-off_6FB2
; ===========================================================================

loc_6FBA:
		move.w	#$1D0,(v_limitbtm1).w
		cmpi.w	#$700,(v_screenposx).w
		blo.s	locret_6FE8
		move.w	#$220,(v_limitbtm1).w
		cmpi.w	#$D00,(v_screenposx).w
		blo.s	locret_6FE8
		move.w	#$340,(v_limitbtm1).w
		cmpi.w	#$340,(v_screenposy).w
		blo.s	locret_6FE8
		addq.b	#2,(v_dle_routine).w

locret_6FE8:
		rts
; ===========================================================================

loc_6FEA:
		cmpi.w	#$340,(v_screenposy).w
		bhs.s	loc_6FF8
		subq.b	#2,(v_dle_routine).w
		rts
; ===========================================================================

loc_6FF8:
		move.w	#0,(v_limittop2).w
		cmpi.w	#$E00,(v_screenposx).w
		bhs.s	locret_702C
		move.w	#$340,(v_limittop2).w
		move.w	#$340,(v_limitbtm1).w
		cmpi.w	#$A90,(v_screenposx).w
		bhs.s	locret_702C
		move.w	#$500,(v_limitbtm1).w
		cmpi.w	#$370,(v_screenposy).w
		blo.s	locret_702C
		addq.b	#2,(v_dle_routine).w

locret_702C:
		rts
; ===========================================================================

loc_702E:
		cmpi.w	#$370,(v_screenposy).w
		bhs.s	loc_703C
		subq.b	#2,(v_dle_routine).w
		rts
; ===========================================================================

loc_703C:
		cmpi.w	#$500,(v_screenposy).w
		blo.s	locret_704E
		cmpi.w	#$B80,(v_screenposx).w
		blo.s	locret_704E
		move.w	#$500,(v_limittop2).w
		addq.b	#2,(v_dle_routine).w

locret_704E:
		rts
; ===========================================================================

loc_7050:
		cmpi.w	#$B80,(v_screenposx).w
		bhs.s	locj_76B8
		cmpi.w	#$340,(v_limittop2).w
		beq.s	locret_7072
		subq.w	#2,(v_limittop2).w
		rts
locj_76B8:
		cmpi.w	#$500,(v_limittop2).w
		beq.s	locj_76CE
		cmpi.w	#$500,(v_screenposy).w
		blo.s	locret_7072
		move.w	#$500,(v_limittop2).w
locj_76CE:

		cmpi.w	#$E70,(v_screenposx).w
		blo.s	locret_7072
		move.w	#0,(v_limittop2).w
		move.w	#$500,(v_limitbtm1).w
		cmpi.w	#$1430,(v_screenposx).w
		blo.s	locret_7072
		move.w	#$210,(v_limitbtm1).w

locret_7072:
		rts
; ===========================================================================

DLE_MZ2:
		move.w	#$520,(v_limitbtm1).w
		cmpi.w	#$1700,(v_screenposx).w
		blo.s	locret_7088
		move.w	#$200,(v_limitbtm1).w

locret_7088:
		rts
; ===========================================================================

DLE_MZ3:
		moveq	#0,d0
		move.b	(v_dle_routine).w,d0
		move.w	off_7098(pc,d0.w),d0
		jmp	off_7098(pc,d0.w)
; ===========================================================================
off_7098:	dc.w DLE_MZ3boss-off_7098
		dc.w DLE_MZ3end-off_7098
; ===========================================================================

DLE_MZ3boss:
		move.w	#$720,(v_limitbtm1).w
		cmpi.w	#$1560,(v_screenposx).w
		blo.s	locret_70E8
		move.w	#$210,(v_limitbtm1).w
		cmpi.w	#$17F0,(v_screenposx).w
		blo.s	locret_70E8
		bsr.w	FindFreeObj
		bne.s	loc_70D0
		move.b	#id_BossMarble,0(a1) ; load MZ boss object
		move.w	#$19F0,obX(a1)
		move.w	#$22C,obY(a1)

loc_70D0:
		move.w	#bgm_Boss,d0
		bsr.w	PlaySound	; play boss music
		move.b	#1,(f_lockscreen).w ; lock screen
		addq.b	#2,(v_dle_routine).w
		moveq	#plcid_Boss,d0
		bra.w	AddPLC		; load boss patterns
; ===========================================================================

locret_70E8:
		rts
; ===========================================================================

DLE_MZ3end:
		move.w	(v_screenposx).w,(v_limitleft2).w
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Star Light Zone dynamic level events
; ---------------------------------------------------------------------------

DLE_SLZ:
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		move.w	DLE_SLZx(pc,d0.w),d0
		jmp	DLE_SLZx(pc,d0.w)
; ===========================================================================
DLE_SLZx:	dc.w DLE_SLZ12-DLE_SLZx
		dc.w DLE_SLZ12-DLE_SLZx
		dc.w DLE_SLZ3-DLE_SLZx
; ===========================================================================

DLE_SLZ12:
		rts
; ===========================================================================

DLE_SLZ3:
		moveq	#0,d0
		move.b	(v_dle_routine).w,d0
		move.w	off_7118(pc,d0.w),d0
		jmp	off_7118(pc,d0.w)
; ===========================================================================
off_7118:	dc.w DLE_SLZ3main-off_7118
		dc.w DLE_SLZ3boss-off_7118
		dc.w DLE_SLZ3end-off_7118
; ===========================================================================

DLE_SLZ3main:
		cmpi.w	#$1E70,(v_screenposx).w
		blo.s	locret_7130
		move.w	#$210,(v_limitbtm1).w
		addq.b	#2,(v_dle_routine).w

locret_7130:
		rts
; ===========================================================================

DLE_SLZ3boss:
		cmpi.w	#$2000,(v_screenposx).w
		blo.s	locret_715C
		bsr.w	FindFreeObj
		bne.s	loc_7144
		move.b	#id_BossStarLight,(a1) ; load SLZ boss object

loc_7144:
		move.w	#bgm_Boss,d0
		bsr.w	PlaySound	; play boss music
		move.b	#1,(f_lockscreen).w ; lock screen
		addq.b	#2,(v_dle_routine).w
		moveq	#plcid_Boss,d0
		bra.w	AddPLC		; load boss patterns
; ===========================================================================

locret_715C:
		rts
; ===========================================================================

DLE_SLZ3end:
		move.w	(v_screenposx).w,(v_limitleft2).w
		rts
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Spring Yard Zone dynamic level events
; ---------------------------------------------------------------------------

DLE_SYZ:
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		move.w	DLE_SYZx(pc,d0.w),d0
		jmp	DLE_SYZx(pc,d0.w)
; ===========================================================================
DLE_SYZx:	dc.w DLE_SYZ1-DLE_SYZx
		dc.w DLE_SYZ2-DLE_SYZx
		dc.w DLE_SYZ3-DLE_SYZx
; ===========================================================================

DLE_SYZ1:
		rts
; ===========================================================================

DLE_SYZ2:
		move.w	#$520,(v_limitbtm1).w
		cmpi.w	#$25A0,(v_screenposx).w
		blo.s	locret_71A2
		move.w	#$420,(v_limitbtm1).w
		cmpi.w	#$4D0,(v_player+obY).w
		blo.s	locret_71A2
		move.w	#$520,(v_limitbtm1).w

locret_71A2:
		rts
; ===========================================================================

DLE_SYZ3:
		moveq	#0,d0
		move.b	(v_dle_routine).w,d0
		move.w	off_71B2(pc,d0.w),d0
		jmp	off_71B2(pc,d0.w)
; ===========================================================================
off_71B2:	dc.w DLE_SYZ3main-off_71B2
		dc.w DLE_SYZ3boss-off_71B2
		dc.w DLE_SYZ3end-off_71B2
; ===========================================================================

DLE_SYZ3main:
		cmpi.w	#$2AC0,(v_screenposx).w
		blo.s	locret_71CE
		bsr.w	FindFreeObj
		bne.s	locret_71CE
		move.b	#id_BossBlock,(a1) ; load blocks that boss picks up
		addq.b	#2,(v_dle_routine).w

locret_71CE:
		rts
; ===========================================================================

DLE_SYZ3boss:
		cmpi.w	#$2C00,(v_screenposx).w
		blo.s	locret_7200
		move.w	#$4CC,(v_limitbtm1).w
		bsr.w	FindFreeObj
		bne.s	loc_71EC
		move.b	#id_BossSpringYard,(a1) ; load SYZ boss object
		addq.b	#2,(v_dle_routine).w

loc_71EC:
		move.w	#bgm_Boss,d0
		bsr.w	PlaySound	; play boss music
		move.b	#1,(f_lockscreen).w ; lock screen
		moveq	#plcid_Boss,d0
		bra.w	AddPLC		; load boss patterns
; ===========================================================================

locret_7200:
		rts
; ===========================================================================

DLE_SYZ3end:
		move.w	(v_screenposx).w,(v_limitleft2).w
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Scrap Brain Zone dynamic level events
; ---------------------------------------------------------------------------

DLE_SBZ:
		moveq	#0,d0
		move.b	(v_act).w,d0
		add.w	d0,d0
		move.w	DLE_SBZx(pc,d0.w),d0
		jmp	DLE_SBZx(pc,d0.w)
; ===========================================================================
DLE_SBZx:	dc.w DLE_SBZ1-DLE_SBZx
		dc.w DLE_SBZ2-DLE_SBZx
		dc.w DLE_FZ-DLE_SBZx
; ===========================================================================

DLE_SBZ1:
		move.w	#$720,(v_limitbtm1).w
		cmpi.w	#$1880,(v_screenposx).w
		blo.s	locret_7242
		move.w	#$620,(v_limitbtm1).w
		cmpi.w	#$2000,(v_screenposx).w
		blo.s	locret_7242
		move.w	#$2A0,(v_limitbtm1).w

locret_7242:
		rts
; ===========================================================================

DLE_SBZ2:
		moveq	#0,d0
		move.b	(v_dle_routine).w,d0
		move.w	off_7252(pc,d0.w),d0
		jmp	off_7252(pc,d0.w)
; ===========================================================================
off_7252:	dc.w DLE_SBZ2main-off_7252
		dc.w DLE_SBZ2boss-off_7252
		dc.w DLE_SBZ2boss2-off_7252
		dc.w DLE_SBZ2end-off_7252
; ===========================================================================

DLE_SBZ2main:
		move.w	#$800,(v_limitbtm1).w
		cmpi.w	#$1800,(v_screenposx).w
		blo.s	locret_727A
		move.w	#$510,(v_limitbtm1).w
		cmpi.w	#$1E00,(v_screenposx).w
		blo.s	locret_727A
		addq.b	#2,(v_dle_routine).w

locret_727A:
		rts
; ===========================================================================

DLE_SBZ2boss:
		cmpi.w	#$1EB0,(v_screenposx).w
		blo.s	locret_7298
		bsr.w	FindFreeObj
		bne.s	locret_7298
		move.b	#id_FalseFloor,(a1) ; load collapsing block object
		addq.b	#2,(v_dle_routine).w
		moveq	#plcid_EggmanSBZ2,d0
		bra.w	AddPLC		; load SBZ2 Eggman patterns
; ===========================================================================

locret_7298:
		rts
; ===========================================================================

DLE_SBZ2boss2:
		cmpi.w	#$1F60,(v_screenposx).w
		blo.s	loc_72B6
		bsr.w	FindFreeObj
		bne.s	loc_72B0
		move.b	#id_ScrapEggman,(a1) ; load SBZ2 Eggman object
		addq.b	#2,(v_dle_routine).w

loc_72B0:
		move.b	#1,(f_lockscreen).w ; lock screen

loc_72B6:
		bra.s	loc_72C2
; ===========================================================================

DLE_SBZ2end:
		cmpi.w	#$2050,(v_screenposx).w
		blo.s	loc_72C2
		rts
; ===========================================================================

loc_72C2:
		move.w	(v_screenposx).w,(v_limitleft2).w
		rts
; ===========================================================================

DLE_FZ:
		moveq	#0,d0
		move.b	(v_dle_routine).w,d0
		move.w	off_72D8(pc,d0.w),d0
		jmp	off_72D8(pc,d0.w)
; ===========================================================================
off_72D8:	dc.w DLE_FZmain-off_72D8, DLE_FZboss-off_72D8
		dc.w DLE_FZend-off_72D8, locret_7322-off_72D8
		dc.w DLE_FZend2-off_72D8
; ===========================================================================

DLE_FZmain:
		cmpi.w	#$2148,(v_screenposx).w
		blo.s	loc_72F4
		addq.b	#2,(v_dle_routine).w
		moveq	#plcid_FZBoss,d0
		bsr.w	AddPLC		; load FZ boss patterns

loc_72F4:
		bra.s	loc_72C2
; ===========================================================================

DLE_FZboss:
		cmpi.w	#$2300,(v_screenposx).w
		blo.s	loc_7312
		bsr.w	FindFreeObj
		bne.s	loc_7312
		move.b	#id_BossFinal,(a1) ; load FZ boss object
		addq.b	#2,(v_dle_routine).w
		move.b	#1,(f_lockscreen).w ; lock screen

loc_7312:
		bra.s	loc_72C2
; ===========================================================================

DLE_FZend:
		cmpi.w	#$2450,(v_screenposx).w
		blo.s	loc_7320
		addq.b	#2,(v_dle_routine).w

loc_7320:
		bra.s	loc_72C2
; ===========================================================================

locret_7322:
		rts
; ===========================================================================

DLE_FZend2:
		bra.s	loc_72C2
; ===========================================================================
; ---------------------------------------------------------------------------
; Ending sequence dynamic level events (empty)
; ---------------------------------------------------------------------------

DLE_Ending:
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 11 - GHZ bridge
; ---------------------------------------------------------------------------

; Obj11:
Bridge:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bri_Index(pc,d0.w),d1
		jmp	Bri_Index(pc,d1.w)
; ===========================================================================
Bri_Index:	dc.w Bri_Main-Bri_Index, Bri_Action-Bri_Index
		dc.w Bri_Platform-Bri_Index, Bri_Delete-Bri_Index
		dc.w Bri_Delete-Bri_Index, Bri_Display-Bri_Index
; ===========================================================================

Bri_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bri,obMap(a0)
		move.w	#$438E,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$80,obActWid(a0)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		move.b	0(a0),d4	; copy object number ($11) to d4
		lea	obSubtype(a0),a2
		moveq	#0,d1
		move.b	(a2),d1		; copy bridge length to d1
		move.b	#0,(a2)+	; clear bridge length
		move.w	d1,d0
		lsr.w	#1,d0
		lsl.w	#4,d0
		sub.w	d0,d3		; d3 is position of leftmost log
		subq.b	#2,d1
		blo.s	Bri_Action	; don't make more if bridge has only 1 log

@buildloop:
		bsr.w	FindFreeObj
		bne.s	Bri_Action
		addq.b	#1,obSubtype(a0)
		cmp.w	obX(a0),d3	; is this log the leftmost one?
		bne.s	@notleftmost	; if not, branch

		addi.w	#$10,d3
		move.w	d2,obY(a0)
		move.w	d2,$3C(a0)
		move.w	a0,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		addq.b	#1,obSubtype(a0)

	@notleftmost:
		move.w	a1,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#$A,obRoutine(a1)
		move.b	d4,0(a1)	; load bridge object (d4 = $11)
		move.w	d2,obY(a1)
		move.w	d2,$3C(a1)
		move.w	d3,obX(a1)
		move.l	#Map_Bri,obMap(a1)
		move.w	#$438E,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#3,obPriority(a1)
		move.b	#8,obActWid(a1)
		addi.w	#$10,d3
		dbf	d1,@buildloop ; repeat d1 times (length of bridge)

Bri_Action:	; Routine 2
		bsr.s	Bri_Solid
		tst.b	$3E(a0)
		beq.s	@display
		subq.b	#4,$3E(a0)
		bsr.w	Bri_Bend

	@display:
		bsr.w	DisplaySprite
		bra.w	Bri_ChkDel

Bri_Solid:
		moveq	#0,d1
		move.b	obSubtype(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		add.w	d2,d2
		lea	(v_player).w,a1
		tst.w	obVelY(a1)
		bmi.w	Plat_Exit
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit
		cmp.w	d2,d0
		bhs.w	Plat_Exit
		bra.s	Plat_NoXCheck
; End of function Bri_Solid

; ---------------------------------------------------------------------------
; Platform subroutine
; ---------------------------------------------------------------------------

PlatformObject:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)	; is Sonic moving up/jumping?
		bmi.w	Plat_Exit	; if yes, branch

; 	perform x-axis range check
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.w	Plat_Exit

	Plat_NoXCheck:
		move.w	obY(a0),d0
		subq.w	#8,d0

Platform3:
; 	perform y-axis range check
		move.w	obY(a1),d2
		move.b	obHeight(a1),d1
		ext.w	d1
		add.w	d2,d1
		addq.w	#4,d1
		sub.w	d1,d0
		bhi.w	Plat_Exit
		cmpi.w	#-$10,d0
		blo.w	Plat_Exit

		tst.b	(f_playerctrl).w
		bmi.w	Plat_Exit
		cmpi.b	#6,obRoutine(a1)
		bhs.w	Plat_Exit
		add.w	d0,d2
		addq.w	#3,d2
		move.w	d2,obY(a1)
		addq.b	#2,obRoutine(a0)

loc_74AE:
		btst	#3,obStatus(a1)
		beq.s	loc_74DC
		moveq	#0,d0
		move.b	standonobject(a1),d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a2
		bclr	#3,obStatus(a2)
		clr.b	ob2ndRout(a2)
		cmpi.b	#4,obRoutine(a2)
		bne.s	loc_74DC
		subq.b	#2,obRoutine(a2)

loc_74DC:
		move.w	a0,d0
		subi.w	#v_objspace&$FFFF,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,standonobject(a1)
		move.b	#0,obAngle(a1)
		move.w	#0,obVelY(a1)
		move.w	obVelX(a1),obInertia(a1)
		btst	#1,obStatus(a1)
		beq.s	loc_7512
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	(Sonic_ResetOnFloor).l
		movea.l	(sp)+,a0

loc_7512:
		bset	#3,obStatus(a1)
		bset	#3,obStatus(a0)

Plat_Exit:
		rts
; End of function PlatformObject

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and SLZ seesaws)
; ---------------------------------------------------------------------------

SlopeObject:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)
		bmi.w	Plat_Exit
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.s	Plat_Exit
		btst	#0,obRender(a0)
		beq.s	loc_754A
		not.w	d0
		add.w	d1,d0

loc_754A:
		lsr.w	#1,d0
		moveq	#0,d3
		move.b	(a2,d0.w),d3
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function SlopeObject

Swing_Solid:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)
		bmi.w	Plat_Exit
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.w	Plat_Exit
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function Obj15_Solid

; ===========================================================================

Bri_Platform:	; Routine 4
		bsr.s	Bri_WalkOff
		bsr.w	DisplaySprite
		bra.w	Bri_ChkDel

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk off a bridge
; ---------------------------------------------------------------------------

Bri_WalkOff:
		moveq	#0,d1
		move.b	obSubtype(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		bsr.s	ExitPlatform2
		bhs.s	locret_75BE
		lsr.w	#4,d0
		move.b	d0,$3F(a0)
		move.b	$3E(a0),d0
		cmpi.b	#$40,d0
		beq.s	loc_75B6
		addq.b	#4,$3E(a0)

loc_75B6:
		bsr.w	Bri_Bend
		bsr.w	Bri_MoveSonic

locret_75BE:
		rts
; End of function Bri_WalkOff

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk or jump off a platform
; ---------------------------------------------------------------------------

ExitPlatform:
		move.w	d1,d2

ExitPlatform2:
		add.w	d2,d2
		lea	(v_player).w,a1
		btst	#1,obStatus(a1)
		bne.s	loc_75E0
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	loc_75E0
		cmp.w	d2,d0
		blo.s	locret_75F2

loc_75E0:
		bclr	#3,obStatus(a1)
		move.b	#2,obRoutine(a0)
		bclr	#3,obStatus(a0)

locret_75F2:
		rts
; End of function ExitPlatform

Bri_MoveSonic:
		moveq	#0,d0
		move.b	$3F(a0),d0
		move.b	$29(a0,d0.w),d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a2
		lea	(v_player).w,a1
		move.w	obY(a2),d0
		subq.w	#8,d0
		moveq	#0,d1
		move.b	obHeight(a1),d1
		sub.w	d1,d0
		move.w	d0,obY(a1)	; change Sonic's position on y-axis
		rts
; End of function Bri_MoveSonic

Bri_Bend:
		move.b	$3E(a0),d0
		bsr.w	CalcSine
		move.w	d0,d4
		lea	(Obj11_BendData2).l,a4
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		lsl.w	#4,d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		move.w	d3,d2
		add.w	d0,d3
		moveq	#0,d5
		lea	(Obj11_BendData).l,a5
		move.b	(a5,d3.w),d5
		andi.w	#$F,d3
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		lea	$29(a0),a2

loc_765C:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a1
		moveq	#0,d0
		move.b	(a3)+,d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a1),d0
		move.w	d0,obY(a1)
		dbf	d2,loc_765C
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		addq.b	#1,d3
		sub.b	d0,d3
		neg.b	d3
		bmi.s	locret_76CA
		move.w	d3,d2
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		adda.w	d2,a3
		subq.w	#1,d2
		blo.s	locret_76CA

loc_76A4:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a1
		moveq	#0,d0
		move.b	-(a3),d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a1),d0
		move.w	d0,obY(a1)
		dbf	d2,loc_76A4

locret_76CA:
		rts
; End of function Bri_Bend

; ===========================================================================
; ---------------------------------------------------------------------------
; GHZ bridge-bending data
; (Defines how the bridge bends when Sonic walks across	it)
; ---------------------------------------------------------------------------
Obj11_BendData:	incbin	"misc\ghzbend1.bin"
		even
Obj11_BendData2:incbin	"misc\ghzbend2.bin"
		even

; ===========================================================================

Bri_ChkDel:
		out_of_range.w	@deletebridge
		rts
; ===========================================================================

@deletebridge:
		moveq	#0,d2
		lea	obSubtype(a0),a2 ; load bridge length
		move.b	(a2)+,d2	; move bridge length to d2
		subq.b	#1,d2		; subtract 1
		blo.s	@delparent

	@loop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a1
		cmp.w	a0,d0
		beq.s	@skipdel
		bsr.w	DeleteChild

	@skipdel:
		dbf	d2,@loop ; repeat d2 times (bridge length)

@delparent:
		bsr.w	DeleteObject
		rts
; ===========================================================================

Bri_Delete:	; Routine 6, 8
		bsr.w	DeleteObject
		rts
; ===========================================================================

Bri_Display:	; Routine $A
		bsr.w	DisplaySprite
		rts

Map_Bri:	include	"_maps\Bridge.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 15 - swinging platforms (GHZ, MZ, SLZ)
;     - spiked ball on a chain (SBZ)
; ---------------------------------------------------------------------------

; Obj15:
SwingingPlatform:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Swing_Index(pc,d0.w),d1
		jmp	Swing_Index(pc,d1.w)
; ===========================================================================
Swing_Index:	dc.w Swing_Main-Swing_Index, Swing_SetSolid-Swing_Index
		dc.w Swing_Action2-Swing_Index,	Swing_Delete-Swing_Index
		dc.w Swing_Delete-Swing_Index, Swing_Display-Swing_Index
		dc.w Swing_Action-Swing_Index

swing_origX:	equ $3A		; original x-axis position
swing_origY:	equ $38		; original y-axis position
; ===========================================================================

Swing_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Swing_GHZ,obMap(a0) ; GHZ and MZ specific code
		move.w	#$4380,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$18,obActWid(a0)
		move.b	#8,obHeight(a0)
		move.w	obY(a0),swing_origY(a0)
		move.w	obX(a0),swing_origX(a0)
		cmpi.b	#id_SLZ,(v_zone).w ; check if level is SLZ
		bne.s	@notSLZ

		move.l	#Map_Swing_SLZ,obMap(a0) ; SLZ specific code
		move.w	#$43DC,obGfx(a0)
		move.b	#$20,obActWid(a0)
		move.b	#$10,obHeight(a0)
		move.b	#$99,obColType(a0)

	@notSLZ:
		cmpi.b	#id_SBZ,(v_zone).w ; check if level is SBZ
		bne.s	@length

		move.l	#Map_BBall,obMap(a0) ; SBZ specific code
		move.w	#$391,obGfx(a0)
		move.b	#$18,obActWid(a0)
		move.b	#$18,obHeight(a0)
		move.b	#$86,obColType(a0)
		move.b	#$C,obRoutine(a0) ; goto Swing_Action next

@length:
		move.b	0(a0),d4
		moveq	#0,d1
		lea	obSubtype(a0),a2 ; move chain length to a2
		move.b	(a2),d1		; move a2 to d1
		move.w	d1,-(sp)
		andi.w	#$F,d1
		move.b	#0,(a2)+
		move.w	d1,d3
		lsl.w	#4,d3
		addq.b	#8,d3
		move.b	d3,$3C(a0)
		subq.b	#8,d3
		tst.b	obFrame(a0)
		beq.s	@makechain
		addq.b	#8,d3
		subq.w	#1,d1

@makechain:
		bsr.w	FindFreeObj
		bne.s	@fail
		addq.b	#1,obSubtype(a0)
		move.w	a1,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#$A,obRoutine(a1) ; goto Swing_Display next
		move.b	d4,0(a1)	; load swinging object
		move.l	obMap(a0),obMap(a1)
		move.w	obGfx(a0),obGfx(a1)
		bclr	#6,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#4,obPriority(a1)
		move.b	#8,obActWid(a1)
		move.b	#1,obFrame(a1)
		move.b	d3,$3C(a1)
		subi.b	#$10,d3
		bhs.s	@notanchor
		move.b	#2,obFrame(a1)
		move.b	#3,obPriority(a1)
		bset	#6,obGfx(a1)

	@notanchor:
		dbf	d1,@makechain ; repeat d1 times (chain length)

	@fail:
		move.w	a0,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.w	#$4080,obAngle(a0)
		move.w	#-$200,$3E(a0)
		move.w	(sp)+,d1
		btst	#4,d1		; is object type $1X ?
		beq.s	@not1X	; if not, branch
		move.l	#Map_GBall,obMap(a0) ; use GHZ ball mappings
		move.w	#$43AA,obGfx(a0)
		move.b	#1,obFrame(a0)
		move.b	#2,obPriority(a0)
		move.b	#$81,obColType(a0) ; make object hurt when touched

	@not1X:
		cmpi.b	#id_SBZ,(v_zone).w ; is zone SBZ?
		beq.s	Swing_Action	; if yes, branch

Swing_SetSolid:	; Routine 2
		moveq	#0,d1
		move.b	obActWid(a0),d1
		moveq	#0,d3
		move.b	obHeight(a0),d3
		bsr.w	Swing_Solid

Swing_Action:	; Routine $C
		bsr.w	Swing_Move
		bsr.w	DisplaySprite
		bra.w	Swing_ChkDel
; ===========================================================================

Swing_Action2:	; Routine 4
		moveq	#0,d1
		move.b	obActWid(a0),d1
		bsr.w	ExitPlatform
		move.w	obX(a0),-(sp)
		bsr.w	Swing_Move
		move.w	(sp)+,d2
		moveq	#0,d3
		move.b	obHeight(a0),d3
		addq.b	#1,d3
		bsr.w	MvSonicOnPtfm
		bsr.w	DisplaySprite
		bra.w	Swing_ChkDel

		rts

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's position with a platform
; ---------------------------------------------------------------------------

MvSonicOnPtfm:
		lea	(v_player).w,a1
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.s	MvSonic2
; End of function MvSonicOnPtfm

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's position with a platform
; ---------------------------------------------------------------------------

MvSonicOnPtfm2:
		lea	(v_player).w,a1
		move.w	obY(a0),d0
		subi.w	#9,d0

MvSonic2:
		tst.b	(f_playerctrl).w
		bmi.s	locret_7B62
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	locret_7B62
		tst.w	(v_debuguse).w
		bne.s	locret_7B62
		moveq	#0,d1
		move.b	obHeight(a1),d1
		sub.w	d1,d0
		move.w	d0,obY(a1)
		sub.w	obX(a0),d2
		sub.w	d2,obX(a1)

locret_7B62:
		rts
; End of function MvSonicOnPtfm2

Swing_Move:
		move.b	(v_oscillate+$1A).w,d0
		move.w	#$80,d1
		btst	#0,obStatus(a0)
		beq.s	loc_7B78
		neg.w	d0
		add.w	d1,d0

loc_7B78:
		bra.s	Swing_Move2
; End of function Swing_Move

Obj48_Move:
		tst.b	standonobject(a0)
		bne.s	loc_7B9C
		move.w	$3E(a0),d0
		addq.w	#8,d0
		move.w	d0,$3E(a0)
		add.w	d0,obAngle(a0)
		cmpi.w	#$200,d0
		bne.s	loc_7BB6
		move.b	#1,standonobject(a0)
		bra.s	loc_7BB6
; ===========================================================================

loc_7B9C:
		move.w	$3E(a0),d0
		subq.w	#8,d0
		move.w	d0,$3E(a0)
		add.w	d0,obAngle(a0)
		cmpi.w	#-$200,d0
		bne.s	loc_7BB6
		move.b	#0,standonobject(a0)

loc_7BB6:
		move.b	obAngle(a0),d0
; End of function Obj48_Move

Swing_Move2:
		bsr.w	CalcSine
		move.w	$38(a0),d2
		move.w	$3A(a0),d3
		lea	obSubtype(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_7BCE:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#v_objspace&$FFFFFF,d4
		movea.l	d4,a1
		moveq	#0,d4
		move.b	$3C(a1),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,obY(a1)
		move.w	d5,obX(a1)
		dbf	d6,loc_7BCE
		rts
; End of function Swing_Move2

; ===========================================================================

Swing_ChkDel:
		out_of_range.w	Swing_DelAll,$3A(a0)
		rts
; ===========================================================================

Swing_DelAll:
		moveq	#0,d2
		lea	obSubtype(a0),a2
		move.b	(a2)+,d2

Swing_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a1
		bsr.w	DeleteChild
		dbf	d2,Swing_DelLoop ; repeat for length of chain
		rts
; ===========================================================================

Swing_Delete:	; Routine 6, 8
		bsr.w	DeleteObject
		rts
; ===========================================================================

Swing_Display:	; Routine $A
		bra.w	DisplaySprite

Map_Swing_GHZ:	include	"_maps\Swinging Platforms (GHZ).asm"
Map_Swing_SLZ:	include	"_maps\Swinging Platforms (SLZ).asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 17 - helix of spikes on a pole (GHZ)
; ---------------------------------------------------------------------------

; Obj17:
Helix:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Hel_Index(pc,d0.w),d1
		jmp	Hel_Index(pc,d1.w)
; ===========================================================================
Hel_Index:	dc.w Hel_Main-Hel_Index
		dc.w Hel_Action-Hel_Index
		dc.w Hel_Action-Hel_Index
		dc.w Hel_Delete-Hel_Index
		dc.w Hel_Display-Hel_Index

hel_frame:	equ $3E		; start frame (different for each spike)

; 	$29-38 are used for child object addresses
; ===========================================================================

Hel_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Hel,obMap(a0)
		move.w	#$4398,obGfx(a0)
		move.b	#7,obStatus(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		move.b	0(a0),d4
		lea	obSubtype(a0),a2 ; move helix length to a2
		moveq	#0,d1
		move.b	(a2),d1		; move helix length to d1
		move.b	#0,(a2)+	; clear subtype
		move.w	d1,d0
		lsr.w	#1,d0
		lsl.w	#4,d0
		sub.w	d0,d3		; d3 is x-axis position of leftmost spike
		subq.b	#2,d1
		blo.s	Hel_Action	; skip to action if length is only 1
		moveq	#0,d6

Hel_Build:
		bsr.w	FindFreeObj
		bne.s	Hel_Action
		addq.b	#1,obSubtype(a0)
		move.w	a1,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+	; copy child address to parent RAM
		move.b	#8,obRoutine(a1)
		move.b	d4,0(a1)
		move.w	d2,obY(a1)
		move.w	d3,obX(a1)
		move.l	obMap(a0),obMap(a1)
		move.w	#$4398,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#3,obPriority(a1)
		move.b	#8,obActWid(a1)
		move.b	d6,hel_frame(a1)
		addq.b	#1,d6
		andi.b	#7,d6
		addi.w	#$10,d3
		cmp.w	obX(a0),d3	; is this spike in the centre?
		bne.s	Hel_NotCentre	; if not, branch

		move.b	d6,hel_frame(a0) ; set parent spike frame
		addq.b	#1,d6
		andi.b	#7,d6
		addi.w	#$10,d3		; skip to next spike
		addq.b	#1,obSubtype(a0)

	Hel_NotCentre:
		dbf	d1,Hel_Build ; repeat d1 times (helix length)

Hel_Action:	; Routine 2, 4
		bsr.w	Hel_RotateSpikes
		bsr.w	DisplaySprite
		bra.w	Hel_ChkDel

Hel_RotateSpikes:
		move.b	(v_ani0_frame).w,d0
		move.b	#0,obColType(a0) ; make object harmless
		add.b	hel_frame(a0),d0
		andi.b	#7,d0
		move.b	d0,obFrame(a0)	; change current frame
		bne.s	locret_7DA6
		move.b	#$84,obColType(a0) ; make object harmful

locret_7DA6:
		rts
; End of function Hel_RotateSpikes

; ===========================================================================

Hel_ChkDel:
		out_of_range.w	Hel_DelAll
		rts
; ===========================================================================

Hel_DelAll:
		moveq	#0,d2
		lea	obSubtype(a0),a2 ; move helix length to a2
		move.b	(a2)+,d2	; move helix length to d2
		subq.b	#2,d2
		blo.s	Hel_Delete

	Hel_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a1		; get child address
		bsr.w	DeleteChild	; delete object
		dbf	d2,Hel_DelLoop ; repeat d2 times (helix length)

Hel_Delete:	; Routine 6
		bsr.w	DeleteObject
		rts
; ===========================================================================

Hel_Display:	; Routine 8
		bsr.w	Hel_RotateSpikes
		bra.w	DisplaySprite

Map_Hel:	include	"_maps\Spiked Pole Helix.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 18 - platforms (GHZ, SYZ, SLZ)
; ---------------------------------------------------------------------------

; Obj18:
BasicPlatform:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Plat_Index(pc,d0.w),d1
		jmp	Plat_Index(pc,d1.w)
; ===========================================================================
Plat_Index:	dc.w Plat_Main-Plat_Index
		dc.w Plat_Solid-Plat_Index
		dc.w Plat_Action2-Plat_Index
		dc.w Plat_Delete-Plat_Index
		dc.w Plat_Action-Plat_Index
; ===========================================================================

Plat_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$4000,obGfx(a0)
		move.l	#Map_Plat_GHZ,obMap(a0)
		move.b	#$20,obActWid(a0)
		cmpi.b	#id_SYZ,(v_zone).w ; check if level is SYZ
		bne.s	@notSYZ

		move.l	#Map_Plat_SYZ,obMap(a0) ; SYZ specific code
		move.b	#$20,obActWid(a0)

	@notSYZ:
		cmpi.b	#id_SLZ,(v_zone).w ; check if level is SLZ
		bne.s	@notSLZ
		move.l	#Map_Plat_SLZ,obMap(a0) ; SLZ specific code
		move.b	#$20,obActWid(a0)
		move.w	#$4000,obGfx(a0)
		move.b	#3,obSubtype(a0)

	@notSLZ:
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.w	obY(a0),$2C(a0)
		move.w	obY(a0),$34(a0)
		move.w	obX(a0),$32(a0)
		move.w	#$80,obAngle(a0)
		moveq	#0,d1
		move.b	obSubtype(a0),d0
		cmpi.b	#$A,d0		; is object type $A (large platform)?
		bne.s	@setframe	; if not, branch
		addq.b	#1,d1		; use frame #1
		move.b	#$20,obActWid(a0) ; set width

	@setframe:
		move.b	d1,obFrame(a0)	; set frame to d1

Plat_Solid:	; Routine 2
		tst.b	$38(a0)
		beq.s	loc_7EE0
		subq.b	#4,$38(a0)

	loc_7EE0:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		bsr.w	PlatformObject

Plat_Action:	; Routine 8
		bsr.w	Plat_Move
		bsr.w	Plat_Nudge
		bsr.w	DisplaySprite
		bra.w	Plat_ChkDel
; ===========================================================================

Plat_Action2:	; Routine 4
		cmpi.b	#$40,$38(a0)
		beq.s	loc_7F06
		addq.b	#4,$38(a0)

	loc_7F06:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		bsr.w	ExitPlatform
		move.w	obX(a0),-(sp)
		bsr.w	Plat_Move
		bsr.w	Plat_Nudge
		move.w	(sp)+,d2
		bsr.w	MvSonicOnPtfm2
		bsr.w	DisplaySprite
		bra.w	Plat_ChkDel

		rts

; ---------------------------------------------------------------------------
; Subroutine to move platform slightly when you	stand on it
; ---------------------------------------------------------------------------

Plat_Nudge:
		move.b	$38(a0),d0
		bsr.w	CalcSine
		move.w	#$400,d1
		muls.w	d1,d0
		swap	d0
		add.w	$2C(a0),d0
		move.w	d0,obY(a0)
		rts
; End of function Plat_Nudge

; ---------------------------------------------------------------------------
; Subroutine to move platforms
; ---------------------------------------------------------------------------

Plat_Move:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	@index(pc,d0.w),d1
		jmp	@index(pc,d1.w)
; End of function Plat_Move

; ===========================================================================
@index:		dc.w @type00-@index, @type01-@index
		dc.w @type02-@index, @type03-@index
		dc.w @type04-@index, @type05-@index
		dc.w @type06-@index, @type07-@index
		dc.w @type08-@index, @type00-@index
		dc.w @type0A-@index, @type0B-@index
		dc.w @type0C-@index
; ===========================================================================

@type00:
		rts			; platform 00 doesn't move
; ===========================================================================

@type05:
		move.w	$32(a0),d0
		move.b	obAngle(a0),d1	; load platform-motion variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$40,d1
		bra.s	@type01_move
; ===========================================================================

@type01:
		move.w	$32(a0),d0
		move.b	obAngle(a0),d1	; load platform-motion variable
		subi.b	#$40,d1

	@type01_move:
		ext.w	d1
		add.w	d1,d0
		move.w	d0,obX(a0)	; change position on x-axis
		bra.w	@chgmotion
; ===========================================================================

@type0C:
		move.w	$34(a0),d0
		move.b	(v_oscillate+$E).w,d1 ; load platform-motion variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$30,d1
		bra.s	@type02_move
; ===========================================================================

@type0B:
		move.w	$34(a0),d0
		move.b	(v_oscillate+$E).w,d1 ; load platform-motion variable
		subi.b	#$30,d1
		bra.s	@type02_move
; ===========================================================================

@type06:
		move.w	$34(a0),d0
		move.b	obAngle(a0),d1	; load platform-motion variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$40,d1
		bra.s	@type02_move
; ===========================================================================

@type02:
		move.w	$34(a0),d0
		move.b	obAngle(a0),d1	; load platform-motion variable
		subi.b	#$40,d1

	@type02_move:
		ext.w	d1
		add.w	d1,d0
		move.w	d0,$2C(a0)	; change position on y-axis
		bra.w	@chgmotion
; ===========================================================================

@type03:
		tst.w	$3A(a0)		; is time delay set?
		bne.s	@type03_wait	; if yes, branch
		btst	#3,obStatus(a0)	; is Sonic standing on the platform?
		beq.s	@type03_nomove	; if not, branch
		move.w	#30,$3A(a0)	; set time delay to 0.5 seconds

	@type03_nomove:
		rts

	@type03_wait:
		subq.w	#1,$3A(a0)	; subtract 1 from time
		bne.s	@type03_nomove	; if time is > 0, branch
		move.w	#32,$3A(a0)
		addq.b	#1,obSubtype(a0) ; change to type 04 (falling)
		rts
; ===========================================================================

@type04:
		tst.w	$3A(a0)
		beq.s	@loc_8048
		subq.w	#1,$3A(a0)
		bne.s	@loc_8048
		btst	#3,obStatus(a0)
		beq.s	@loc_8042
		bset	#1,obStatus(a1)
		bclr	#3,obStatus(a1)
		move.b	#2,obRoutine(a1)
		bclr	#3,obStatus(a0)
		clr.b	$25(a0)
		move.w	obVelY(a0),obVelY(a1)

	@loc_8042:
		move.b	#8,obRoutine(a0)

	@loc_8048:
		move.l	$2C(a0),d3
		move.w	obVelY(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d3,$2C(a0)
		addi.w	#$38,obVelY(a0)
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	$2C(a0),d0
		bhs.s	@locret_8074
		move.b	#6,obRoutine(a0)

	@locret_8074:
		rts
; ===========================================================================

@type07:
		tst.w	$3A(a0)		; is time delay set?
		bne.s	@type07_wait	; if yes, branch
		lea	(f_switch).w,a2	; load switch statuses
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; move object type ($x7) to d0
		lsr.w	#4,d0		; divide d0 by 8, round down
		tst.b	(a2,d0.w)	; has switch no. d0 been pressed?
		beq.s	@type07_nomove	; if not, branch
		move.w	#60,$3A(a0)	; set time delay to 1 second

	@type07_nomove:
		rts

	@type07_wait:
		subq.w	#1,$3A(a0)	; subtract 1 from time delay
		bne.s	@type07_nomove	; if time is > 0, branch
		addq.b	#1,obSubtype(a0) ; change to type 08
		rts
; ===========================================================================

@type08:
		subq.w	#2,$2C(a0)	; move platform up
		move.w	$34(a0),d0
		subi.w	#$200,d0
		cmp.w	$2C(a0),d0	; has platform moved $200 pixels?
		bne.s	@type08_nostop	; if not, branch
		clr.b	obSubtype(a0)	; change to type 00 (stop moving)

	@type08_nostop:
		rts
; ===========================================================================

@type0A:
		move.w	$34(a0),d0
		move.b	obAngle(a0),d1	; load platform-motion variable
		subi.b	#$40,d1
		ext.w	d1
		asr.w	#1,d1
		add.w	d1,d0
		move.w	d0,$2C(a0)	; change position on y-axis

@chgmotion:
		move.b	(v_oscillate+$1A).w,$26(a0) ; update platform-movement variable
		rts
; ===========================================================================

Plat_ChkDel:
		out_of_range.s	Plat_Delete,$32(a0)
		rts
; ===========================================================================

Plat_Delete:	; Routine 6
		bra.w	DeleteObject

Map_Plat_GHZ:	include	"_maps\Platforms (GHZ).asm"
Map_Plat_SYZ:	include	"_maps\Platforms (SYZ).asm"
Map_Plat_SLZ:	include	"_maps\Platforms (SLZ).asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 19 - blank
; ---------------------------------------------------------------------------

Obj19:
		rts

Map_GBall:	include	"_maps\GHZ Ball.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1A - GHZ collapsing ledge
; ---------------------------------------------------------------------------

; Obj1A:
CollapseLedge:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Ledge_Index(pc,d0.w),d1
		jmp	Ledge_Index(pc,d1.w)
; ===========================================================================
Ledge_Index:	dc.w Ledge_Main-Ledge_Index, Ledge_Touch-Ledge_Index
		dc.w Ledge_Collapse-Ledge_Index, Ledge_Display-Ledge_Index
		dc.w Ledge_Delete-Ledge_Index, Ledge_WalkOff-Ledge_Index

ledge_timedelay:	equ $38		; time between touching the ledge and it collapsing
ledge_collapse_flag:	equ $3A		; collapse flag
; ===========================================================================

Ledge_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Ledge,obMap(a0)
		move.w	#$4000,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#7,ledge_timedelay(a0) ; set time delay for collapse
		move.b	#$64,obActWid(a0)
		move.b	obSubtype(a0),obFrame(a0)
		move.b	#$38,obHeight(a0)
		bset	#4,obRender(a0)

Ledge_Touch:	; Routine 2
		tst.b	ledge_collapse_flag(a0)	; is ledge collapsing?
		beq.s	@slope		; if not, branch
		tst.b	ledge_timedelay(a0)	; has time reached zero?
		beq.w	Ledge_Fragment	; if yes, branch
		subq.b	#1,ledge_timedelay(a0) ; subtract 1 from time

	@slope:
		move.w	#$30,d1
		lea	(Ledge_SlopeData).l,a2
		bsr.w	SlopeObject
		bra.w	RememberState
; ===========================================================================

Ledge_Collapse:	; Routine 4
		tst.b	ledge_timedelay(a0)
		beq.w	loc_847A
		move.b	#1,ledge_collapse_flag(a0)	; set collapse flag
		subq.b	#1,ledge_timedelay(a0)

Ledge_WalkOff:	; Routine $A
		move.w	#$30,d1
		bsr.w	ExitPlatform
		move.w	#$30,d1
		lea	(Ledge_SlopeData).l,a2
		move.w	obX(a0),d2
		bsr.w	SlopeObject2
		bra.w	RememberState
; End of function Ledge_WalkOff

; ===========================================================================

Ledge_Display:	; Routine 6
		tst.b	ledge_timedelay(a0)	; has time delay reached zero?
		beq.s	Ledge_TimeZero	; if yes, branch
		tst.b	ledge_collapse_flag(a0)	; is ledge collapsing?
		bne.w	loc_82D0	; if yes, branch
		subq.b	#1,ledge_timedelay(a0) ; subtract 1 from time
		bra.w	DisplaySprite
; ===========================================================================

loc_82D0:
		subq.b	#1,ledge_timedelay(a0)
		bsr.w	Ledge_WalkOff
		lea	(v_player).w,a1
		btst	#3,obStatus(a1)
		beq.s	loc_82FC
		tst.b	ledge_timedelay(a0)
		bne.s	locret_8308
		bclr	#3,obStatus(a1)
		bclr	#5,obStatus(a1)
		move.b	#1,obNextAni(a1)

loc_82FC:
		move.b	#0,ledge_collapse_flag(a0)
		move.b	#6,obRoutine(a0) ; run "Ledge_Display" routine

locret_8308:
		rts
; ===========================================================================

Ledge_TimeZero:
		bsr.w	ObjectFall
		bsr.w	DisplaySprite
		tst.b	obRender(a0)
		bpl.s	Ledge_Delete
		rts
; ===========================================================================

Ledge_Delete:	; Routine 8
		bsr.w	DeleteObject
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 53 - collapsing floors (MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------

; Obj53:
CollapseFloor:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	CFlo_Index(pc,d0.w),d1
		jmp	CFlo_Index(pc,d1.w)
; ===========================================================================
CFlo_Index:	dc.w CFlo_Main-CFlo_Index, CFlo_Touch-CFlo_Index
		dc.w CFlo_Collapse-CFlo_Index, CFlo_Display-CFlo_Index
		dc.w CFlo_Delete-CFlo_Index, CFlo_WalkOff-CFlo_Index

cflo_timedelay:		equ $38
cflo_collapse_flag:	equ $3A
; ===========================================================================

CFlo_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_CFlo,obMap(a0)
		move.w	#$42B8,obGfx(a0)
		cmpi.b	#id_SLZ,(v_zone).w ; check if level is SLZ
		bne.s	@notSLZ

		move.w	#$44E0,obGfx(a0) ; SLZ specific code
		addq.b	#2,obFrame(a0)

	@notSLZ:
		cmpi.b	#id_SBZ,(v_zone).w ; check if level is SBZ
		bne.s	@notSBZ
		move.w	#$43F5,obGfx(a0) ; SBZ specific code

	@notSBZ:
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#7,cflo_timedelay(a0)
		move.b	#$44,obActWid(a0)

CFlo_Touch:	; Routine 2
		tst.b	cflo_collapse_flag(a0)	; has Sonic touched the object?
		beq.s	@solid		; if not, branch
		tst.b	cflo_timedelay(a0)	; has time delay reached zero?
		beq.w	CFlo_Fragment	; if yes, branch
		subq.b	#1,cflo_timedelay(a0) ; subtract 1 from time

	@solid:
		move.w	#$20,d1
		bsr.w	PlatformObject
		tst.b	obSubtype(a0)
		bpl.s	@remstate
		btst	#3,obStatus(a1)
		beq.s	@remstate
		bclr	#0,obRender(a0)
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		bhs.s	@remstate
		bset	#0,obRender(a0)

	@remstate:
		bra.w	RememberState
; ===========================================================================

CFlo_Collapse:	; Routine 4
		tst.b	cflo_timedelay(a0)
		beq.w	loc_8458
		move.b	#1,cflo_collapse_flag(a0)	; set object as "touched"
		subq.b	#1,cflo_timedelay(a0)

CFlo_WalkOff:	; Routine $A
		move.w	#$20,d1
		bsr.w	ExitPlatform
		move.w	obX(a0),d2
		bsr.w	MvSonicOnPtfm2
		bra.w	RememberState
; End of function CFlo_WalkOff

; ===========================================================================

CFlo_Display:	; Routine 6
		tst.b	cflo_timedelay(a0)	; has time delay reached zero?
		beq.s	CFlo_TimeZero	; if yes, branch
		tst.b	cflo_collapse_flag(a0)	; has Sonic touched the object?
		bne.w	loc_8402	; if yes, branch
		subq.b	#1,cflo_timedelay(a0); subtract 1 from time
		bra.w	DisplaySprite
; ===========================================================================

loc_8402:
		subq.b	#1,cflo_timedelay(a0)
		bsr.w	CFlo_WalkOff
		lea	(v_player).w,a1
		btst	#3,obStatus(a1)
		beq.s	loc_842E
		tst.b	cflo_timedelay(a0)
		bne.s	locret_843A
		bclr	#3,obStatus(a1)
		bclr	#5,obStatus(a1)
		move.b	#1,obNextAni(a1)

loc_842E:
		move.b	#0,cflo_collapse_flag(a0)
		move.b	#6,obRoutine(a0) ; run "CFlo_Display" routine

locret_843A:
		rts
; ===========================================================================

CFlo_TimeZero:
		bsr.w	ObjectFall
		bsr.w	DisplaySprite
		tst.b	obRender(a0)
		bpl.s	CFlo_Delete
		rts
; ===========================================================================

CFlo_Delete:	; Routine 8
		bsr.w	DeleteObject
		rts
; ===========================================================================

CFlo_Fragment:
		move.b	#0,cflo_collapse_flag(a0)

loc_8458:
		lea	(CFlo_Data2).l,a4
		btst	#0,obSubtype(a0)
		beq.s	loc_846C
		lea	(CFlo_Data3).l,a4

loc_846C:
		moveq	#7,d1
		addq.b	#1,obFrame(a0)
		bra.s	loc_8486

; ===========================================================================

Ledge_Fragment:
		move.b	#0,ledge_collapse_flag(a0)

loc_847A:
		lea	(CFlo_Data1).l,a4
		moveq	#$18,d1
		addq.b	#2,obFrame(a0)

loc_8486:
		moveq	#0,d0
		move.b	obFrame(a0),d0
		add.w	d0,d0
		movea.l	obMap(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,obRender(a0)
		move.b	0(a0),d4
		move.b	obRender(a0),d5
		movea.l	a0,a1
		bra.s	loc_84B2
; ===========================================================================

loc_84AA:
		bsr.w	FindFreeObj
		bne.s	loc_84F2
		addq.w	#5,a3

loc_84B2:
		move.b	#6,obRoutine(a1)
		move.b	d4,0(a1)
		move.l	a3,obMap(a1)
		move.b	d5,obRender(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	obGfx(a0),obGfx(a1)
		move.b	obPriority(a0),obPriority(a1)
		move.b	obActWid(a0),obActWid(a1)
		move.b	(a4)+,ledge_timedelay(a1)
		cmpa.l	a0,a1
		bhs.s	loc_84EE
		bsr.w	DisplaySprite1

loc_84EE:
		dbf	d1,loc_84AA

loc_84F2:
		bsr.w	DisplaySprite
		move.w	#sfx_Collapse,d0
		jmp	(PlaySound_Special).l	; play collapsing sound
; ===========================================================================
; ---------------------------------------------------------------------------
; Disintegration data for collapsing ledges (MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------
CFlo_Data1:	dc.b $1C, $18, $14, $10, $1A, $16, $12,	$E, $A,	6, $18,	$14, $10, $C, 8, 4
		dc.b $16, $12, $E, $A, 6, 2, $14, $10, $C, 0
CFlo_Data2:	dc.b $1E, $16, $E, 6, $1A, $12,	$A, 2
CFlo_Data3:	dc.b $16, $1E, $1A, $12, 6, $E,	$A, 2

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and MZ platforms)
; ---------------------------------------------------------------------------

SlopeObject2:
		lea	(v_player).w,a1
		btst	#3,obStatus(a1)
		beq.s	locret_856E
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		lsr.w	#1,d0
		btst	#0,obRender(a0)
		beq.s	loc_854E
		not.w	d0
		add.w	d1,d0

loc_854E:
		moveq	#0,d1
		move.b	(a2,d0.w),d1
		move.w	obY(a0),d0
		sub.w	d1,d0
		moveq	#0,d1
		move.b	obHeight(a1),d1
		sub.w	d1,d0
		move.w	d0,obY(a1)
		sub.w	obX(a0),d2
		sub.w	d2,obX(a1)

locret_856E:
		rts
; End of function SlopeObject2

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision data for GHZ collapsing ledge
; ---------------------------------------------------------------------------
Ledge_SlopeData:
		incbin	"misc\GHZ Collapsing Ledge Heightmap.bin"
		even

Map_Ledge:	include	"_maps\Collapsing Ledge.asm"
Map_CFlo:	include	"_maps\Collapsing Floors.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1C - scenery (GHZ bridge stump, SLZ lava thrower)
; ---------------------------------------------------------------------------

; Obj1C:
Scenery:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Scen_Index(pc,d0.w),d1
		jmp	Scen_Index(pc,d1.w)
; ===========================================================================
Scen_Index:	dc.w Scen_Main-Scen_Index
		dc.w Scen_ChkDel-Scen_Index
; ===========================================================================

Scen_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; copy object subtype to d0
		mulu.w	#$A,d0		; multiply by $A
		lea	Scen_Values(pc,d0.w),a1
		move.l	(a1)+,obMap(a0)
		move.w	(a1)+,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	(a1)+,obFrame(a0)
		move.b	(a1)+,obActWid(a0)
		move.b	(a1)+,obPriority(a0)
		move.b	(a1)+,obColType(a0)

Scen_ChkDel:	; Routine 2
		out_of_range.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================
; ---------------------------------------------------------------------------
; Variables for object $1C are stored in an array
; ---------------------------------------------------------------------------
Scen_Values:	dc.l Map_Scen		; mappings address
		dc.w $44D8		; VRAM setting
		dc.b 0,	8, 2, 0		; frame, width, priority, collision response
		dc.l Map_Scen
		dc.w $44D8
		dc.b 0,	8, 2, 0
		dc.l Map_Scen
		dc.w $44D8
		dc.b 0,	8, 2, 0
		dc.l Map_Bri
		dc.w $438E
		dc.b 1,	$10, 1,	0
		even

Map_Scen:	include	"_maps\Scenery.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1D - switch that activates when Sonic touches it
; (this is not used anywhere in	the game)
; ---------------------------------------------------------------------------

; Obj1D:
MagicSwitch:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Swi_Index(pc,d0.w),d1
		jmp	Swi_Index(pc,d1.w)
; ===========================================================================
Swi_Index:	dc.w Swi_Main-Swi_Index
		dc.w Swi_Action-Swi_Index
		dc.w Swi_Delete-Swi_Index

swi_origY:	equ $30		; original y-axis position
; ===========================================================================

Swi_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Swi,obMap(a0)
		move.w	#$4000,obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	obY(a0),swi_origY(a0) ; save position on y-axis
		move.b	#$10,obActWid(a0)
		move.b	#5,obPriority(a0)

Swi_Action:	; Routine 2
		move.w	swi_origY(a0),obY(a0) ; restore position on y-axis
		move.w	#$10,d1
		bsr.w	Swi_ChkTouch	; check if Sonic touches the switch
		beq.s	Swi_ChkDel	; if not, branch

		addq.w	#2,obY(a0)	; move object 2 pixels
		moveq	#1,d0
		move.w	d0,(f_switch).w	; set switch 0 as "pressed"

Swi_ChkDel:
		bsr.w	DisplaySprite
		out_of_range.w	Swi_Delete
		rts
; ===========================================================================

Swi_Delete:	; Routine 4
		bsr.w	DeleteObject
		rts

; ---------------------------------------------------------------------------
; Subroutine to check if Sonic touches the object
; ---------------------------------------------------------------------------

Swi_ChkTouch:
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	Swi_NoTouch
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.s	Swi_NoTouch
		move.w	obY(a1),d2
		move.b	obHeight(a1),d1
		ext.w	d1
		add.w	d2,d1
		move.w	obY(a0),d0
		subi.w	#$10,d0
		sub.w	d1,d0
		bhi.s	Swi_NoTouch
		cmpi.w	#-$10,d0
		blo.s	Swi_NoTouch
		moveq	#-1,d0		; Sonic has touched it
		rts
; ===========================================================================

Swi_NoTouch:
		moveq	#0,d0		; Sonic hasn't touched it
		rts
; End of function Swi_ChkTouch

Map_Swi:	include	"_maps\Unused Switch.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2A - small vertical door (SBZ)
; ---------------------------------------------------------------------------

; Obj2A:
AutoDoor:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	ADoor_Index(pc,d0.w),d1
		jmp	ADoor_Index(pc,d1.w)
; ===========================================================================
ADoor_Index:	dc.w ADoor_Main-ADoor_Index
		dc.w ADoor_OpenShut-ADoor_Index
; ===========================================================================

ADoor_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_ADoor,obMap(a0)
		move.w	#$42E8,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#8,obActWid(a0)
		move.b	#4,obPriority(a0)

ADoor_OpenShut:	; Routine 2
		move.w	#$40,d1		; set range for door detection
		clr.b	obAnim(a0)	; use "closing" animation
		move.w	(v_player+obX).w,d0
		add.w	d1,d0
		cmp.w	obX(a0),d0
		blo.s	ADoor_Animate
		sub.w	d1,d0
		sub.w	d1,d0
		cmp.w	obX(a0),d0	; is Sonic > $40 pixels from door?
		bhs.s	ADoor_Animate	; close door
		add.w	d1,d0
		cmp.w	obX(a0),d0	; is Sonic left of the door?
		bhs.s	loc_899A	; if yes, branch
		btst	#0,obStatus(a0)
		bne.s	ADoor_Animate
		bra.s	ADoor_Open
; ===========================================================================

loc_899A:
		btst	#0,obStatus(a0)
		beq.s	ADoor_Animate

ADoor_Open:
		move.b	#1,obAnim(a0)	; use "opening" animation

ADoor_Animate:
		lea	(Ani_ADoor).l,a1
		bsr.w	AnimateSprite
		tst.b	obFrame(a0)	; is the door open?
		bne.s	@remember	; if yes, branch
		move.w	#$11,d1
		move.w	#$20,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject

	@remember:
		bra.w	RememberState

		include	"_anim\SBZ Small Door.asm"
Map_ADoor:	include	"_maps\SBZ Small Door.asm"

Obj44_SolidWall:
		bsr.w	Obj44_SolidWall2
		beq.s	loc_8AA8
		bmi.w	loc_8AC4
		tst.w	d0
		beq.w	loc_8A92
		bmi.s	loc_8A7C
		tst.w	obVelX(a1)
		bmi.s	loc_8A92
		bra.s	loc_8A82
; ===========================================================================

loc_8A7C:
		tst.w	obVelX(a1)
		bpl.s	loc_8A92

loc_8A82:
		sub.w	d0,obX(a1)
		move.w	#0,obInertia(a1)
		move.w	#0,obVelX(a1)

loc_8A92:
		btst	#1,obStatus(a1)
		bne.s	loc_8AB6
		bset	#5,obStatus(a1)
		bset	#5,obStatus(a0)
		rts
; ===========================================================================

loc_8AA8:
		btst	#5,obStatus(a0)
		beq.s	locret_8AC2
		move.w	#id_Run,obAnim(a1)

loc_8AB6:
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)

locret_8AC2:
		rts
; ===========================================================================

loc_8AC4:
		tst.w	obVelY(a1)
		bpl.s	locret_8AD8
		tst.w	d3
		bpl.s	locret_8AD8
		sub.w	d3,obY(a1)
		move.w	#0,obVelY(a1)

locret_8AD8:
		rts
; End of function Obj44_SolidWall

Obj44_SolidWall2:
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	loc_8B48
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.s	loc_8B48
		move.b	obHeight(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	obY(a1),d3
		sub.w	obY(a0),d3
		add.w	d2,d3
		bmi.s	loc_8B48
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bhs.s	loc_8B48
		tst.b	(f_playerctrl).w
		bmi.s	loc_8B48
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	loc_8B48
		tst.w	(v_debuguse).w
		bne.s	loc_8B48
		move.w	d0,d5
		cmp.w	d0,d1
		bhs.s	loc_8B30
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_8B30:
		move.w	d3,d1
		cmp.w	d3,d2
		bhs.s	loc_8B3C
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_8B3C:
		cmp.w	d1,d5
		bhi.s	loc_8B44
		moveq	#1,d4
		rts
; ===========================================================================

loc_8B44:
		moveq	#-1,d4
		rts
; ===========================================================================

loc_8B48:
		moveq	#0,d4
		rts
; End of function Obj44_SolidWall2

; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1E - Ball Hog enemy (SBZ)
; ---------------------------------------------------------------------------

; Obj1E:
BallHog:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Hog_Index(pc,d0.w),d1
		jmp	Hog_Index(pc,d1.w)
; ===========================================================================
Hog_Index:	dc.w Hog_Main-Hog_Index
		dc.w Hog_Action-Hog_Index

hog_launchflag:	equ $32		; 0 to launch a cannonball
; ===========================================================================

Hog_Main:	; Routine 0
		move.b	#$13,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.l	#Map_Hog,obMap(a0)
		move.w	#$2302,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#5,obColType(a0)
		move.b	#$C,obActWid(a0)
		bsr.w	ObjectFall
		jsr	(ObjFloorDist).l	; find floor
		tst.w	d1
		bpl.s	@floornotfound
		add.w	d1,obY(a0)
		move.w	#0,obVelY(a0)
		addq.b	#2,obRoutine(a0)

	@floornotfound:
		rts
; ===========================================================================

Hog_Action:	; Routine 2
		lea	(Ani_Hog).l,a1
		bsr.w	AnimateSprite
		cmpi.b	#1,obFrame(a0)	; is final frame (01) displayed?
		bne.s	@setlaunchflag	; if not, branch
		tst.b	hog_launchflag(a0)	; is it set to launch cannonball?
		beq.s	@makeball	; if yes, branch
		bra.s	@remember
; ===========================================================================

@setlaunchflag:
		clr.b	hog_launchflag(a0)	; set to launch cannonball

@remember:
		bra.w	RememberState
; ===========================================================================

@makeball:
		move.b	#1,hog_launchflag(a0)
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_Cannonball,0(a1) ; load cannonball object ($20)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	#-$100,obVelX(a1) ; cannonball bounces to the left
		move.w	#0,obVelY(a1)
		moveq	#-4,d0
		btst	#0,obStatus(a0)	; is Ball Hog facing right?
		beq.s	@noflip		; if not, branch
		neg.w	d0
		neg.w	obVelX(a1)	; cannonball bounces to the right

	@noflip:
		add.w	d0,obX(a1)
		addi.w	#$C,obY(a1)
		move.b	obSubtype(a0),obSubtype(a1) ; copy object type from Ball Hog

	@fail:
		bra.s	@remember

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 20 - cannonball that Ball Hog throws (SBZ)
; ---------------------------------------------------------------------------

; Obj20:
Cannonball:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Cbal_Index(pc,d0.w),d1
		jmp	Cbal_Index(pc,d1.w)
; ===========================================================================
Cbal_Index:	dc.w Cbal_Main-Cbal_Index
		dc.w Cbal_Bounce-Cbal_Index

cbal_time:	equ $30		; time until the cannonball explodes (2 bytes)
; ===========================================================================

Cbal_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#7,obHeight(a0)
		move.l	#Map_Hog,obMap(a0)
		move.w	#$2302,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$87,obColType(a0)
		move.b	#8,obActWid(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; move subtype to d0
		mulu.w	#60,d0		; multiply by 60 frames (1 second)
		move.w	d0,cbal_time(a0) ; set explosion time
		move.b	#4,obFrame(a0)

Cbal_Bounce:	; Routine 2
		jsr	(ObjectFall).l
		tst.w	obVelY(a0)
		bmi.s	Cbal_ChkExplode
		jsr	(ObjFloorDist).l
		tst.w	d1		; has ball hit the floor?
		bpl.s	Cbal_ChkExplode	; if not, branch

		add.w	d1,obY(a0)
		move.w	#-$300,obVelY(a0) ; bounce
		tst.b	d3
		beq.s	Cbal_ChkExplode
		bmi.s	loc_8CA4
		tst.w	obVelX(a0)
		bpl.s	Cbal_ChkExplode
		neg.w	obVelX(a0)
		bra.s	Cbal_ChkExplode
; ===========================================================================

loc_8CA4:
		tst.w	obVelX(a0)
		bmi.s	Cbal_ChkExplode
		neg.w	obVelX(a0)

Cbal_ChkExplode:
		subq.w	#1,cbal_time(a0) ; subtract 1 from explosion time
		bpl.s	Cbal_Animate	; if time is > 0, branch

	Cbal_Explode:
		move.b	#id_MissileDissolve,0(a0)
		move.b	#id_ExplosionBomb,0(a0)	; change object to an explosion	($3F)
		move.b	#0,obRoutine(a0) ; reset routine counter
		bra.w	ExplosionBomb	; jump to explosion code
; ===========================================================================

Cbal_Animate:
		subq.b	#1,obTimeFrame(a0) ; subtract 1 from frame duration
		bpl.s	Cbal_Display
		move.b	#5,obTimeFrame(a0) ; set frame duration to 5 frames
		bchg	#0,obFrame(a0)	; change frame

Cbal_Display:
		bsr.w	DisplaySprite
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0	; has object fallen off the level?
		blo.w	DeleteObject	; if yes, branch
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 24 - buzz bomber missile vanishing (unused?)
; ---------------------------------------------------------------------------

; Obj24:
MissileDissolve:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	MDis_Index(pc,d0.w),d1
		jmp	MDis_Index(pc,d1.w)
; ===========================================================================
MDis_Index:	dc.w MDis_Main-MDis_Index
		dc.w MDis_Animate-MDis_Index
; ===========================================================================

MDis_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_MisDissolve,obMap(a0)
		move.w	#$41C,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#0,obColType(a0)
		move.b	#$C,obActWid(a0)
		move.b	#9,obTimeFrame(a0)
		move.b	#0,obFrame(a0)
		move.w	#sfx_A5,d0
		jsr	(PlaySound_Special).l		 ; play sound

MDis_Animate:	; Routine 2
		subq.b	#1,obTimeFrame(a0) ; subtract 1 from frame duration
		bpl.s	@display
		move.b	#9,obTimeFrame(a0) ; set frame duration to 9 frames
		addq.b	#1,obFrame(a0)	; next frame
		cmpi.b	#4,obFrame(a0)	; has animation completed?
		beq.w	DeleteObject	; if yes, branch

	@display:
		bra.w	DisplaySprite
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 27 - explosion from a destroyed enemy or monitor
; ---------------------------------------------------------------------------

; Obj27:
ExplosionItem:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	ExItem_Index(pc,d0.w),d1
		jmp	ExItem_Index(pc,d1.w)
; ===========================================================================
ExItem_Index:	dc.w ExItem_Animal-ExItem_Index
		dc.w ExItem_Main-ExItem_Index
		dc.w ExItem_Animate-ExItem_Index
; ===========================================================================

ExItem_Animal:	; Routine 0
		addq.b	#2,obRoutine(a0)
		bsr.w	FindFreeObj
		bne.s	ExItem_Main
		move.b	#id_Animals,0(a1) ; load animal object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	$3E(a0),$3E(a1)

ExItem_Main:	; Routine 2
		addq.b	#2,obRoutine(a0)
		move.l	#Map_ExplodeItem,obMap(a0)
		move.w	#$5A0,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#0,obColType(a0)
		move.b	#$C,obActWid(a0)
		move.b	#7,obTimeFrame(a0) ; set frame duration to 7 frames
		move.b	#0,obFrame(a0)
		move.w	#sfx_BreakItem,d0
		jsr	(PlaySound_Special).l	; play breaking enemy sound

ExItem_Animate:	; Routine 4 (2 for ExplosionBomb)
		subq.b	#1,obTimeFrame(a0) ; subtract 1 from frame duration
		bpl.s	@display
		move.b	#7,obTimeFrame(a0) ; set frame duration to 7 frames
		addq.b	#1,obFrame(a0)	; next frame
		cmpi.b	#5,obFrame(a0)	; is the final frame (05) displayed?
		beq.w	DeleteObject	; if yes, branch

	@display:
		bra.w	DisplaySprite

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3F - explosion from a destroyed boss, bomb or cannonball
; ---------------------------------------------------------------------------

; Obj3F:
ExplosionBomb:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	ExBom_Index(pc,d0.w),d1
		jmp	ExBom_Index(pc,d1.w)
; ===========================================================================
ExBom_Index:	dc.w ExBom_Main-ExBom_Index
		dc.w ExItem_Animate-ExBom_Index
; ===========================================================================

ExBom_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_ExplodeBomb,obMap(a0)
		move.w	#$5A0,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#0,obColType(a0)
		move.b	#$C,obActWid(a0)
		move.b	#7,obTimeFrame(a0)
		move.b	#0,obFrame(a0)
		move.w	#sfx_Bomb,d0
		jmp	(PlaySound_Special).l	; play exploding bomb sound

		include	"_anim\Ball Hog.asm"
Map_Hog:	include	"_maps\Ball Hog.asm"
Map_MisDissolve:include	"_maps\Buzz Bomber Missile Dissolve.asm"
		include	"_maps\Explosions.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 28 - animals
; ---------------------------------------------------------------------------

; Obj28:
Animals:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Anml_Index(pc,d0.w),d1
		jmp	Anml_Index(pc,d1.w)
; ===========================================================================
Anml_Index:	dc.w Anml_Ending-Anml_Index, loc_912A-Anml_Index
		dc.w loc_9184-Anml_Index, loc_91C0-Anml_Index
		dc.w loc_9184-Anml_Index, loc_9184-Anml_Index
		dc.w loc_9184-Anml_Index, loc_91C0-Anml_Index
		dc.w loc_9184-Anml_Index, loc_9240-Anml_Index
		dc.w loc_9260-Anml_Index, loc_9260-Anml_Index
		dc.w loc_9280-Anml_Index, loc_92BA-Anml_Index
		dc.w loc_9314-Anml_Index, loc_9332-Anml_Index
		dc.w loc_9314-Anml_Index, loc_9332-Anml_Index
		dc.w loc_9314-Anml_Index, loc_9370-Anml_Index
		dc.w loc_92D6-Anml_Index

Anml_VarIndex:	dc.b 0,	5, 2, 3, 6, 3, 4, 5, 4,	1, 0, 1

Anml_Variables:	dc.w $FE00, $FC00
		dc.l Map_Animal1
		dc.w $FE00, $FD00	; horizontal speed, vertical speed
		dc.l Map_Animal2	; mappings address
		dc.w $FE80, $FD00
		dc.l Map_Animal1
		dc.w $FEC0, $FE80
		dc.l Map_Animal2
		dc.w $FE40, $FD00
		dc.l Map_Animal3
		dc.w $FD00, $FC00
		dc.l Map_Animal2
		dc.w $FD80, $FC80
		dc.l Map_Animal3

Anml_EndSpeed:	dc.w $FBC0, $FC00, $FBC0, $FC00, $FBC0,	$FC00, $FD00, $FC00
		dc.w $FD00, $FC00, $FE80, $FD00, $FE80,	$FD00, $FEC0, $FE80
		dc.w $FE40, $FD00, $FE00, $FD00, $FD80,	$FC80

Anml_EndMap:	dc.l Map_Animal2, Map_Animal2, Map_Animal2, Map_Animal1, Map_Animal1
		dc.l Map_Animal1, Map_Animal1, Map_Animal2, Map_Animal3, Map_Animal2
		dc.l Map_Animal3

Anml_EndVram:	dc.w $5A5, $5A5, $5A5, $553, $553, $573, $573, $585, $593
		dc.w $565, $5B3
; ===========================================================================

Anml_Ending:	; Routine 0
		tst.b	obSubtype(a0)	; did animal come from a destroyed enemy?
		beq.w	Anml_FromEnemy	; if yes, branch
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; move object type to d0
		add.w	d0,d0		; multiply d0 by 2
		move.b	d0,obRoutine(a0) ; move d0 to routine counter
		subi.w	#$14,d0
		move.w	Anml_EndVram(pc,d0.w),obGfx(a0)
		add.w	d0,d0
		move.l	Anml_EndMap(pc,d0.w),obMap(a0)
		lea	Anml_EndSpeed(pc),a1
		move.w	(a1,d0.w),$32(a0) ; load horizontal speed
		move.w	(a1,d0.w),obVelX(a0)
		move.w	2(a1,d0.w),$34(a0) ; load vertical speed
		move.w	2(a1,d0.w),obVelY(a0)
		move.b	#$C,obHeight(a0)
		move.b	#4,obRender(a0)
		bset	#0,obRender(a0)
		move.b	#6,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.b	#7,obTimeFrame(a0)
		bra.w	DisplaySprite
; ===========================================================================

Anml_FromEnemy:
		addq.b	#2,obRoutine(a0)
		bsr.w	RandomNumber
		andi.w	#1,d0
		moveq	#0,d1
		move.b	(v_zone).w,d1
		add.w	d1,d1
		add.w	d0,d1
		lea	Anml_VarIndex(pc),a1
		move.b	(a1,d1.w),d0
		move.b	d0,$30(a0)
		lsl.w	#3,d0
		lea	Anml_Variables(pc),a1
		adda.w	d0,a1
		move.w	(a1)+,$32(a0)	; load horizontal speed
		move.w	(a1)+,$34(a0)	; load vertical speed
		move.l	(a1)+,obMap(a0)	; load mappings
		move.w	#$580,obGfx(a0)	; VRAM setting for 1st animal
		btst	#0,$30(a0)	; is 1st animal used?
		beq.s	loc_90C0	; if yes, branch
		move.w	#$592,obGfx(a0)	; VRAM setting for 2nd animal

loc_90C0:
		move.b	#$C,obHeight(a0)
		move.b	#4,obRender(a0)
		bset	#0,obRender(a0)
		move.b	#6,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.b	#7,obTimeFrame(a0)
		move.b	#2,obFrame(a0)
		move.w	#-$400,obVelY(a0)
		tst.b	(v_bossstatus).w
		bne.s	loc_911C
		bsr.w	FindFreeObj
		bne.s	Anml_Display
		move.b	#id_Points,0(a1) ; load points object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	$3E(a0),d0
		lsr.w	#1,d0
		move.b	d0,obFrame(a1)

Anml_Display:
		bra.w	DisplaySprite
; ===========================================================================

loc_911C:
		move.b	#$12,obRoutine(a0)
		clr.w	obVelX(a0)
		bra.w	DisplaySprite
; ===========================================================================

loc_912A:
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		bsr.w	ObjectFall
		tst.w	obVelY(a0)
		bmi.s	loc_9180
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	loc_9180
		add.w	d1,obY(a0)
		move.w	$32(a0),obVelX(a0)
		move.w	$34(a0),obVelY(a0)
		move.b	#1,obFrame(a0)
		move.b	$30(a0),d0
		add.b	d0,d0
		addq.b	#4,d0
		move.b	d0,obRoutine(a0)
		tst.b	(v_bossstatus).w
		beq.s	loc_9180
		btst	#4,(v_vbla_byte).w
		beq.s	loc_9180
		neg.w	obVelX(a0)
		bchg	#0,obRender(a0)

loc_9180:
		bra.w	DisplaySprite
; ===========================================================================

loc_9184:
		bsr.w	ObjectFall
		move.b	#1,obFrame(a0)
		tst.w	obVelY(a0)
		bmi.s	loc_91AE
		move.b	#0,obFrame(a0)
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	loc_91AE
		add.w	d1,obY(a0)
		move.w	$34(a0),obVelY(a0)

loc_91AE:
		tst.b	obSubtype(a0)
		bne.s	loc_9224
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================

loc_91C0:
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		tst.w	obVelY(a0)
		bmi.s	loc_91FC
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	loc_91FC
		add.w	d1,obY(a0)
		move.w	$34(a0),obVelY(a0)
		tst.b	obSubtype(a0)
		beq.s	loc_91FC
		cmpi.b	#$A,obSubtype(a0)
		beq.s	loc_91FC
		neg.w	obVelX(a0)
		bchg	#0,obRender(a0)

loc_91FC:
		subq.b	#1,obTimeFrame(a0)
		bpl.s	loc_9212
		move.b	#1,obTimeFrame(a0)
		addq.b	#1,obFrame(a0)
		andi.b	#1,obFrame(a0)

loc_9212:
		tst.b	obSubtype(a0)
		bne.s	loc_9224
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================

loc_9224:
		move.w	obX(a0),d0
		sub.w	(v_player+obX).w,d0
		blo.s	loc_923C
		subi.w	#$180,d0
		bpl.s	loc_923C
		tst.b	obRender(a0)
		bpl.w	DeleteObject

loc_923C:
		bra.w	DisplaySprite
; ===========================================================================

loc_9240:
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		subq.w	#1,$36(a0)
		bne.w	loc_925C
		move.b	#2,obRoutine(a0)
		move.b	#3,obPriority(a0)

loc_925C:
		bra.w	DisplaySprite
; ===========================================================================

loc_9260:
		bsr.w	sub_9404
		bhs.s	loc_927C
		move.w	$32(a0),obVelX(a0)
		move.w	$34(a0),obVelY(a0)
		move.b	#$E,obRoutine(a0)
		bra.w	loc_91C0
; ===========================================================================

loc_927C:
		bra.w	loc_9224
; ===========================================================================

loc_9280:
		bsr.w	sub_9404
		bpl.s	loc_92B6
		clr.w	obVelX(a0)
		clr.w	$32(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		bsr.w	loc_93C4
		bsr.w	loc_93EC
		subq.b	#1,obTimeFrame(a0)
		bpl.s	loc_92B6
		move.b	#1,obTimeFrame(a0)
		addq.b	#1,obFrame(a0)
		andi.b	#1,obFrame(a0)

loc_92B6:
		bra.w	loc_9224
; ===========================================================================

loc_92BA:
		bsr.w	sub_9404
		bpl.s	loc_9310
		move.w	$32(a0),obVelX(a0)
		move.w	$34(a0),obVelY(a0)
		move.b	#4,obRoutine(a0)
		bra.w	loc_9184
; ===========================================================================

loc_92D6:
		bsr.w	ObjectFall
		move.b	#1,obFrame(a0)
		tst.w	obVelY(a0)
		bmi.s	loc_9310
		move.b	#0,obFrame(a0)
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	loc_9310
		not.b	$29(a0)
		bne.s	loc_9306
		neg.w	obVelX(a0)
		bchg	#0,obRender(a0)

loc_9306:
		add.w	d1,obY(a0)
		move.w	$34(a0),obVelY(a0)

loc_9310:
		bra.w	loc_9224
; ===========================================================================

loc_9314:
		bsr.w	sub_9404
		bpl.s	loc_932E
		clr.w	obVelX(a0)
		clr.w	$32(a0)
		bsr.w	ObjectFall
		bsr.w	loc_93C4
		bsr.w	loc_93EC

loc_932E:
		bra.w	loc_9224
; ===========================================================================

loc_9332:
		bsr.w	sub_9404
		bpl.s	loc_936C
		bsr.w	ObjectFall
		move.b	#1,obFrame(a0)
		tst.w	obVelY(a0)
		bmi.s	loc_936C
		move.b	#0,obFrame(a0)
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	loc_936C
		neg.w	obVelX(a0)
		bchg	#0,obRender(a0)
		add.w	d1,obY(a0)
		move.w	$34(a0),obVelY(a0)

loc_936C:
		bra.w	loc_9224
; ===========================================================================

loc_9370:
		bsr.w	sub_9404
		bpl.s	loc_93C0
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		tst.w	obVelY(a0)
		bmi.s	loc_93AA
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	loc_93AA
		not.b	$29(a0)
		bne.s	loc_93A0
		neg.w	obVelX(a0)
		bchg	#0,obRender(a0)

loc_93A0:
		add.w	d1,obY(a0)
		move.w	$34(a0),obVelY(a0)

loc_93AA:
		subq.b	#1,obTimeFrame(a0)
		bpl.s	loc_93C0
		move.b	#1,obTimeFrame(a0)
		addq.b	#1,obFrame(a0)
		andi.b	#1,obFrame(a0)

loc_93C0:
		bra.w	loc_9224
; ===========================================================================

loc_93C4:
		move.b	#1,obFrame(a0)
		tst.w	obVelY(a0)
		bmi.s	locret_93EA
		move.b	#0,obFrame(a0)
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	locret_93EA
		add.w	d1,obY(a0)
		move.w	$34(a0),obVelY(a0)

locret_93EA:
		rts
; ===========================================================================

loc_93EC:
		bset	#0,obRender(a0)
		move.w	obX(a0),d0
		sub.w	(v_player+obX).w,d0
		bhs.s	locret_9402
		bclr	#0,obRender(a0)

locret_9402:
		rts

sub_9404:
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		subi.w	#$B8,d0
		rts
; End of function sub_9404

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 29 - points that appear when you destroy something
; ---------------------------------------------------------------------------

; Obj29:
Points:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Poi_Index(pc,d0.w),d1
		jsr	Poi_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
Poi_Index:	dc.w Poi_Main-Poi_Index
		dc.w Poi_Slower-Poi_Index
; ===========================================================================

Poi_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Poi,obMap(a0)
		move.w	#$2797,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.w	#-$300,obVelY(a0) ; move object upwards

Poi_Slower:	; Routine 2
		tst.w	obVelY(a0)	; is object moving?
		bpl.w	DeleteObject	; if not, delete
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; reduce object speed
		rts

Map_Animal1:	include	"_maps\Animals 1.asm"
Map_Animal2:	include	"_maps\Animals 2.asm"
Map_Animal3:	include	"_maps\Animals 3.asm"
Map_Poi:	include	"_maps\Points.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1F - Crabmeat enemy (GHZ, SYZ)
; ---------------------------------------------------------------------------

; Obj1F:
Crabmeat:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Crab_Index(pc,d0.w),d1
		jmp	Crab_Index(pc,d1.w)
; ===========================================================================
Crab_Index:
ptr_Crab_Main:		dc.w Crab_Main-Crab_Index
ptr_Crab_Action:	dc.w Crab_Action-Crab_Index
ptr_Crab_Delete:	dc.w Crab_Delete-Crab_Index
ptr_Crab_BallMain:	dc.w Crab_BallMain-Crab_Index
ptr_Crab_BallMove:	dc.w Crab_BallMove-Crab_Index

id_Crab_Main:		equ ptr_Crab_Main-Crab_Index	; 0
id_Crab_Action:		equ ptr_Crab_Action-Crab_Index	; 2
id_Crab_Delete:		equ ptr_Crab_Delete-Crab_Index	; 4
id_Crab_BallMain:	equ ptr_Crab_BallMain-Crab_Index	; 6
id_Crab_BallMove:	equ ptr_Crab_BallMove-Crab_Index	; 8

crab_timedelay:	equ $30
crab_mode:	equ $32
; ===========================================================================

Crab_Main:	; Routine 0
		move.b	#$10,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.l	#Map_Crab,obMap(a0)
		move.w	#$400,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#6,obColType(a0)
		move.b	#$15,obActWid(a0)
		bsr.w	ObjectFall
		jsr	(ObjFloorDist).l	; find floor
		tst.w	d1
		bpl.s	@floornotfound
		add.w	d1,obY(a0)
		move.b	d3,obAngle(a0)
		move.w	#0,obVelY(a0)
		addq.b	#2,obRoutine(a0)

	@floornotfound:
		rts
; ===========================================================================

Crab_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		lea	(Ani_Crab).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
@index:		dc.w @waittofire-@index
		dc.w @walkonfloor-@index
; ===========================================================================

@waittofire:
		subq.w	#1,crab_timedelay(a0) ; subtract 1 from time delay
		bpl.s	@dontmove
		tst.b	obRender(a0)
		bpl.s	@movecrab
		bchg	#1,crab_mode(a0)
		bne.s	@fire

	@movecrab:
		addq.b	#2,ob2ndRout(a0)
		move.w	#127,crab_timedelay(a0) ; set time delay to approx 2 seconds
		move.w	#$80,obVelX(a0)	; move Crabmeat to the right
		bsr.w	Crab_SetAni
		addq.b	#3,d0
		move.b	d0,obAnim(a0)
		bchg	#0,obStatus(a0)
		bne.s	@noflip
		neg.w	obVelX(a0)	; change direction

	@dontmove:
	@noflip:
		rts
; ===========================================================================

@fire:
		move.w	#59,crab_timedelay(a0)
		move.b	#6,obAnim(a0)	; use firing animation
		bsr.w	FindFreeObj
		bne.s	@failleft
		move.b	#id_Crabmeat,0(a1) ; load left fireball
		move.b	#id_Crab_BallMain,obRoutine(a1)
		move.w	obX(a0),obX(a1)
		subi.w	#$10,obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	#-$100,obVelX(a1)

	@failleft:
		bsr.w	FindFreeObj
		bne.s	@failright
		move.b	#id_Crabmeat,0(a1) ; load right fireball
		move.b	#id_Crab_BallMain,obRoutine(a1)
		move.w	obX(a0),obX(a1)
		addi.w	#$10,obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	#$100,obVelX(a1)

	@failright:
		rts
; ===========================================================================

@walkonfloor:
		subq.w	#1,crab_timedelay(a0)
		bmi.s	loc_966E
		bsr.w	SpeedToPos
		bchg	#0,crab_mode(a0)
		bne.s	loc_9654
		move.w	obX(a0),d3
		addi.w	#$10,d3
		btst	#0,obStatus(a0)
		beq.s	loc_9640
		subi.w	#$20,d3

loc_9640:
		jsr	(ObjFloorDist2).l
		cmpi.w	#-8,d1
		blt.s	loc_966E
		cmpi.w	#$C,d1
		bge.s	loc_966E
		rts
; ===========================================================================

loc_9654:
		jsr	(ObjFloorDist).l
		add.w	d1,obY(a0)
		move.b	d3,obAngle(a0)
		bsr.w	Crab_SetAni
		addq.b	#3,d0
		move.b	d0,obAnim(a0)
		rts
; ===========================================================================

loc_966E:
		subq.b	#2,ob2ndRout(a0)
		move.w	#59,crab_timedelay(a0)
		move.w	#0,obVelX(a0)
		bsr.w	Crab_SetAni
		move.b	d0,obAnim(a0)
		rts
; ---------------------------------------------------------------------------
; Subroutine to set the	correct	animation for a	Crabmeat
; ---------------------------------------------------------------------------

Crab_SetAni:
		moveq	#0,d0
		move.b	obAngle(a0),d3
		bmi.s	loc_96A4
		cmpi.b	#6,d3
		blo.s	locret_96A2
		moveq	#1,d0
		btst	#0,obStatus(a0)
		bne.s	locret_96A2
		moveq	#2,d0

locret_96A2:
		rts
; ===========================================================================

loc_96A4:
		cmpi.b	#-6,d3
		bhi.s	locret_96B6
		moveq	#2,d0
		btst	#0,obStatus(a0)
		bne.s	locret_96B6
		moveq	#1,d0

locret_96B6:
		rts
; End of function Crab_SetAni

; ===========================================================================

Crab_Delete:	; Routine 4
		bsr.w	DeleteObject
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Sub-object - missile that the Crabmeat throws
; ---------------------------------------------------------------------------

Crab_BallMain:	; Routine 6
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Crab,obMap(a0)
		move.w	#$400,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$87,obColType(a0)
		move.b	#8,obActWid(a0)
		move.w	#-$400,obVelY(a0)
		move.b	#7,obAnim(a0)

Crab_BallMove:	; Routine 8
		lea	(Ani_Crab).l,a1
		bsr.w	AnimateSprite
		bsr.w	ObjectFall
		bsr.w	DisplaySprite
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0	; has object moved below the level boundary?
		blo.s	@delete		; if yes, branch
		rts

	@delete:
		bra.w	DeleteObject

		include	"_anim\Crabmeat.asm"
Map_Crab:	include	"_maps\Crabmeat.asm"
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 22 - Buzz Bomber enemy (GHZ, MZ, SYZ)
; ---------------------------------------------------------------------------

; Obj22:
BuzzBomber:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Buzz_Index(pc,d0.w),d1
		jmp	Buzz_Index(pc,d1.w)
; ===========================================================================
Buzz_Index:	dc.w Buzz_Main-Buzz_Index
		dc.w Buzz_Action-Buzz_Index
		dc.w Buzz_Delete-Buzz_Index

buzz_timedelay:	equ $32
buzz_buzzstatus:	equ $34
buzz_parent:	equ $3C
; ===========================================================================

Buzz_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Buzz,obMap(a0)
		move.w	#$444,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#8,obColType(a0)
		move.b	#$18,obActWid(a0)

Buzz_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		lea	(Ani_Buzz).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
@index:		dc.w @move-@index
		dc.w @chknearsonic-@index
; ===========================================================================

@move:
		subq.w	#1,buzz_timedelay(a0) ; subtract 1 from time delay
		bpl.s	@noflip		; if time remains, branch
		btst	#1,buzz_buzzstatus(a0) ; is Buzz Bomber near Sonic?
		bne.s	@fire		; if yes, branch
		addq.b	#2,ob2ndRout(a0)
		move.w	#127,buzz_timedelay(a0) ; set time delay to just over 2 seconds
		move.w	#$400,obVelX(a0) ; move Buzz Bomber to the right
		move.b	#1,obAnim(a0)	; use "flying" animation
		btst	#0,obStatus(a0)	; is Buzz Bomber facing left?
		bne.s	@noflip		; if not, branch
		neg.w	obVelX(a0)	; move Buzz Bomber to the left

	@noflip:
		rts
; ===========================================================================

	@fire:
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_Missile,0(a1) ; load missile object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		addi.w	#$1C,obY(a1)
		move.w	#$200,obVelY(a1) ; move missile downwards
		move.w	#$200,obVelX(a1) ; move missile to the right
		move.w	#$18,d0
		btst	#0,obStatus(a0)	; is Buzz Bomber facing left?
		bne.s	@noflip2	; if not, branch
		neg.w	d0
		neg.w	obVelX(a1)	; move missile to the left

	@noflip2:
		add.w	d0,obX(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.w	#$E,buzz_timedelay(a1)
		move.l	a0,buzz_parent(a1)
		move.b	#1,buzz_buzzstatus(a0) ; set to "already fired" to prevent refiring
		move.w	#59,buzz_timedelay(a0)
		move.b	#2,obAnim(a0)	; use "firing" animation

	@fail:
		rts
; ===========================================================================

@chknearsonic:
		subq.w	#1,buzz_timedelay(a0) ; subtract 1 from time delay
		bmi.s	@chgdirection
		bsr.w	SpeedToPos
		tst.b	buzz_buzzstatus(a0)
		bne.s	@keepgoing
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bpl.s	@isleft
		neg.w	d0

	@isleft:
		cmpi.w	#$60,d0		; is Buzz Bomber within $60 pixels of Sonic?
		bhs.s	@keepgoing	; if not, branch
		tst.b	obRender(a0)
		bpl.s	@keepgoing
		move.b	#2,buzz_buzzstatus(a0) ; set Buzz Bomber to "near Sonic"
		move.w	#29,buzz_timedelay(a0) ; set time delay to half a second
		bra.s	@stop
; ===========================================================================

	@chgdirection:
		move.b	#0,buzz_buzzstatus(a0) ; set Buzz Bomber to "normal"
		bchg	#0,obStatus(a0)	; change direction
		move.w	#59,buzz_timedelay(a0)

	@stop:
		subq.b	#2,ob2ndRout(a0)
		move.w	#0,obVelX(a0)	; stop Buzz Bomber moving
		move.b	#0,obAnim(a0)	; use "hovering" animation

@keepgoing:
		rts
; ===========================================================================

Buzz_Delete:	; Routine 4
		bsr.w	DeleteObject
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 23 - missile that Buzz Bomber throws
; ---------------------------------------------------------------------------

; Obj23:
Missile:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Msl_Index(pc,d0.w),d1
		jmp	Msl_Index(pc,d1.w)
; ===========================================================================
Msl_Index:	dc.w Msl_Main-Msl_Index
		dc.w Msl_Animate-Msl_Index
		dc.w Msl_FromBuzz-Msl_Index
		dc.w Msl_Delete-Msl_Index
		dc.w Msl_FromNewt-Msl_Index

msl_parent:	equ $3C
; ===========================================================================

Msl_Main:	; Routine 0
		subq.w	#1,$32(a0)
		bpl.s	Msl_ChkCancel
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Missile,obMap(a0)
		move.w	#$2444,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#8,obActWid(a0)
		andi.b	#3,obStatus(a0)
		tst.b	obSubtype(a0)	; was object created by a Newtron?
		beq.s	Msl_Animate	; if not, branch

		move.b	#8,obRoutine(a0) ; run "Msl_FromNewt" routine
		move.b	#$87,obColType(a0)
		move.b	#1,obAnim(a0)
		bra.s	Msl_Animate2
; ===========================================================================

Msl_Animate:	; Routine 2
		bsr.s	Msl_ChkCancel
		lea	(Ani_Missile).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite

; ---------------------------------------------------------------------------
; Subroutine to check if the Buzz Bomber which fired the missile has been
; destroyed, and if it has, then cancel the missile
; ---------------------------------------------------------------------------

Msl_ChkCancel:
		movea.l	msl_parent(a0),a1
		cmpi.b	#id_ExplosionItem,0(a1) ; has Buzz Bomber been destroyed?
		beq.s	Msl_Delete	; if yes, branch
		rts
; End of function Msl_ChkCancel

; ===========================================================================

Msl_FromBuzz:	; Routine 4
		btst	#7,obStatus(a0)
		bne.s	@explode
		move.b	#$87,obColType(a0)
		move.b	#1,obAnim(a0)
		bsr.w	SpeedToPos
		lea	(Ani_Missile).l,a1
		bsr.w	AnimateSprite
		bsr.w	DisplaySprite
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0	; has object moved below the level boundary?
		blo.s	Msl_Delete	; if yes, branch
		rts
; ===========================================================================

	@explode:
		move.b	#id_MissileDissolve,0(a0) ; change object to an explosion (Obj24)
		move.b	#0,obRoutine(a0)
		bra.w	MissileDissolve
; ===========================================================================

Msl_Delete:	; Routine 6
		bsr.w	DeleteObject
		rts
; ===========================================================================

Msl_FromNewt:	; Routine 8
		tst.b	obRender(a0)
		bpl.s	Msl_Delete
		bsr.w	SpeedToPos

Msl_Animate2:
		lea	(Ani_Missile).l,a1
		bsr.w	AnimateSprite
		bsr.w	DisplaySprite
		rts

		include	"_anim\Buzz Bomber.asm"
		include	"_anim\Buzz Bomber Missile.asm"
Map_Buzz:	include	"_maps\Buzz Bomber.asm"
Map_Missile:	include	"_maps\Buzz Bomber Missile.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 25 - rings
; ---------------------------------------------------------------------------

; Obj25:
Rings:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Ring_Index(pc,d0.w),d1
		jmp	Ring_Index(pc,d1.w)
; ===========================================================================
Ring_Index:
ptr_Ring_Main:		dc.w Ring_Main-Ring_Index
ptr_Ring_Animate:	dc.w Ring_Animate-Ring_Index
ptr_Ring_Collect:	dc.w Ring_Collect-Ring_Index
ptr_Ring_Sparkle:	dc.w Ring_Sparkle-Ring_Index
ptr_Ring_Delete:	dc.w Ring_Delete-Ring_Index

id_Ring_Main:		equ ptr_Ring_Main-Ring_Index	; 0
id_Ring_Animate:		equ ptr_Ring_Animate-Ring_Index	; 2
id_Ring_Collect:		equ ptr_Ring_Collect-Ring_Index	; 4
id_Ring_Sparkle:		equ ptr_Ring_Sparkle-Ring_Index	; 6
id_Ring_Delete:		equ ptr_Ring_Delete-Ring_Index	; 8
; ---------------------------------------------------------------------------
; Distances between rings (format: horizontal, vertical)
; ---------------------------------------------------------------------------
Ring_PosData:	dc.b $10, 0		; horizontal tight
		dc.b $18, 0		; horizontal normal
		dc.b $20, 0		; horizontal wide
		dc.b 0,	$10		; vertical tight
		dc.b 0,	$18		; vertical normal
		dc.b 0,	$20		; vertical wide
		dc.b $10, $10		; diagonal
		dc.b $18, $18
		dc.b $20, $20
		dc.b $F0, $10
		dc.b $E8, $18
		dc.b $E0, $20
		dc.b $10, 8
		dc.b $18, $10
		dc.b $F0, 8
		dc.b $E8, $10
; ===========================================================================

Ring_Main:	; Routine 0
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		lea	2(a2,d0.w),a2
		move.b	(a2),d4
		move.b	obSubtype(a0),d1
		move.b	d1,d0
		andi.w	#7,d1
		cmpi.w	#7,d1
		bne.s	loc_9B80
		moveq	#6,d1

	loc_9B80:
		swap	d1
		move.w	#0,d1
		lsr.b	#4,d0
		add.w	d0,d0
		move.b	Ring_PosData(pc,d0.w),d5 ; load ring spacing data
		ext.w	d5
		move.b	Ring_PosData+1(pc,d0.w),d6
		ext.w	d6
		movea.l	a0,a1
		move.w	obX(a0),d2
		move.w	obY(a0),d3
		lsr.b	#1,d4
		blo.s	loc_9C02
		bclr	#7,(a2)
		bra.s	loc_9BBA
; ===========================================================================

Ring_MakeRings:
		swap	d1
		lsr.b	#1,d4
		blo.s	loc_9C02
		bclr	#7,(a2)
		bsr.w	FindFreeObj
		bne.s	loc_9C0E

loc_9BBA:
		move.b	#id_Rings,0(a1)	; load ring object
		addq.b	#2,obRoutine(a1)
		move.w	d2,obX(a1)	; set x-axis position based on d2
		move.w	obX(a0),$32(a1)
		move.w	d3,obY(a1)	; set y-axis position based on d3
		move.l	#Map_Ring,obMap(a1)
		move.w	#$27B2,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#2,obPriority(a1)
		move.b	#$47,obColType(a1)
		move.b	#8,obActWid(a1)
		move.b	obRespawnNo(a0),obRespawnNo(a1)
		move.b	d1,$34(a1)

loc_9C02:
		addq.w	#1,d1
		add.w	d5,d2		; add ring spacing value to d2
		add.w	d6,d3		; add ring spacing value to d3
		swap	d1
		dbf	d1,Ring_MakeRings ; repeat for number of rings

loc_9C0E:
		btst	#0,(a2)
		bne.w	DeleteObject

Ring_Animate:	; Routine 2
		move.b	(v_ani1_frame).w,obFrame(a0) ; set frame
		bsr.w	DisplaySprite
		out_of_range.s	Ring_Delete,$32(a0)
		rts
; ===========================================================================

Ring_Collect:	; Routine 4
		addq.b	#2,obRoutine(a0)
		move.b	#0,obColType(a0)
		move.b	#1,obPriority(a0)
		bsr.w	CollectRing
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		move.b	$34(a0),d1
		bset	d1,2(a2,d0.w)

Ring_Sparkle:	; Routine 6
		lea	(Ani_Ring).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ===========================================================================

Ring_Delete:	; Routine 8
		bra.w	DeleteObject

CollectRing:
		addq.w	#1,(v_rings).w	; add 1 to rings
		ori.b	#1,(f_ringcount).w ; update the rings counter
		move.w	#sfx_Ring,d0	; play ring sound
		cmpi.w	#100,(v_rings).w ; do you have < 100 rings?
		blo.s	@playsnd	; if yes, branch
		bset	#1,(v_lifecount).w ; update lives counter
		beq.s	@got100
		cmpi.w	#200,(v_rings).w ; do you have < 200 rings?
		blo.s	@playsnd	; if yes, branch
		bset	#2,(v_lifecount).w ; update lives counter
		bne.s	@playsnd

	@got100:
		addq.b	#1,(v_lives).w	; add 1 to the number of lives you have
		addq.b	#1,(f_lifecount).w ; update the lives counter
		move.w	#bgm_ExtraLife,d0 ; play extra life music

	@playsnd:
		jmp	(PlaySound_Special).l
; End of function CollectRing

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 37 - rings flying out of Sonic when he's hit
; ---------------------------------------------------------------------------

; Obj37:
RingLoss:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	RLoss_Index(pc,d0.w),d1
		jmp	RLoss_Index(pc,d1.w)
; ===========================================================================
RLoss_Index:	dc.w RLoss_Count-RLoss_Index
		dc.w RLoss_Bounce-RLoss_Index
		dc.w RLoss_Collect-RLoss_Index
		dc.w RLoss_Sparkle-RLoss_Index
		dc.w RLoss_Delete-RLoss_Index
; ===========================================================================

RLoss_Count:	; Routine 0
		movea.l	a0,a1
		moveq	#0,d5
		move.w	(v_rings).w,d5	; check number of rings you have
		moveq	#32,d0
		cmp.w	d0,d5		; do you have 32 or more?
		blo.s	@belowmax	; if not, branch
		move.w	d0,d5		; if yes, set d5 to 32

	@belowmax:
		subq.w	#1,d5
		move.w	#$288,d4
		bra.s	@makerings
; ===========================================================================

	@loop:
		bsr.w	FindFreeObj
		bne.w	@resetcounter

@makerings:
		move.b	#id_RingLoss,0(a1) ; load bouncing ring object
		addq.b	#2,obRoutine(a1)
		move.b	#8,obHeight(a1)
		move.b	#8,obWidth(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	#Map_Ring,obMap(a1)
		move.w	#$27B2,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#3,obPriority(a1)
		move.b	#$47,obColType(a1)
		move.b	#8,obActWid(a1)
		move.b	#-1,(v_ani3_time).w
		tst.w	d4
		bmi.s	@loc_9D62
		move.w	d4,d0
		bsr.w	CalcSine
		move.w	d4,d2
		lsr.w	#8,d2
		asl.w	d2,d0
		asl.w	d2,d1
		move.w	d0,d2
		move.w	d1,d3
		addi.b	#$10,d4
		bhs.s	@loc_9D62
		subi.w	#$80,d4
		bhs.s	@loc_9D62
		move.w	#$288,d4

	@loc_9D62:
		move.w	d2,obVelX(a1)
		move.w	d3,obVelY(a1)
		neg.w	d2
		neg.w	d4
		dbf	d5,@loop	; repeat for number of rings (max 31)

@resetcounter:
		move.w	#0,(v_rings).w	; reset number of rings to zero
		move.b	#$80,(f_ringcount).w ; update ring counter
		move.b	#0,(v_lifecount).w
		move.w	#sfx_RingLoss,d0
		jsr	(PlaySound_Special).l	; play ring loss sound

RLoss_Bounce:	; Routine 2
		move.b	(v_ani3_frame).w,obFrame(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		bmi.s	@chkdel
		move.b	(v_vbla_byte).w,d0
		add.b	d7,d0
		andi.b	#3,d0
		bne.s	@chkdel
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	@chkdel
		add.w	d1,obY(a0)
		move.w	obVelY(a0),d0
		asr.w	#2,d0
		sub.w	d0,obVelY(a0)
		neg.w	obVelY(a0)

	@chkdel:
		tst.b	(v_ani3_time).w
		beq.s	RLoss_Delete
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0	; has object moved below level boundary?
		blo.s	RLoss_Delete	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

RLoss_Collect:	; Routine 4
		addq.b	#2,obRoutine(a0)
		move.b	#0,obColType(a0)
		move.b	#1,obPriority(a0)
		bsr.w	CollectRing

RLoss_Sparkle:	; Routine 6
		lea	(Ani_Ring).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ===========================================================================

RLoss_Delete:	; Routine 8
		bra.w	DeleteObject

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4B - giant ring for entry to special stage
; ---------------------------------------------------------------------------

; Obj4B:
GiantRing:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GRing_Index(pc,d0.w),d1
		jmp	GRing_Index(pc,d1.w)
; ===========================================================================
GRing_Index:	dc.w GRing_Main-GRing_Index
		dc.w GRing_Animate-GRing_Index
		dc.w GRing_Collect-GRing_Index
		dc.w GRing_Delete-GRing_Index
; ===========================================================================

GRing_Main:	; Routine 0
		move.l	#Map_GRing,obMap(a0)
		move.w	#$2400,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$40,obActWid(a0)
		tst.b	obRender(a0)
		bpl.s	GRing_Animate
		cmpi.b	#6,(v_emeralds).w ; do you have 6 emeralds?
		beq.w	GRing_Delete	; if yes, branch
		cmpi.w	#50,(v_rings).w	; do you have at least 50 rings?
		bhs.s	GRing_Okay	; if yes, branch
		rts
; ===========================================================================

GRing_Okay:
		addq.b	#2,obRoutine(a0)
		move.b	#2,obPriority(a0)
		move.b	#$52,obColType(a0)
		move.w	#$C40,(v_gfxbigring).w	; Signal that Art_BigRing should be loaded ($C40 is the size of Art_BigRing)

GRing_Animate:	; Routine 2
		move.b	(v_ani1_frame).w,obFrame(a0)
		out_of_range.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================

GRing_Collect:	; Routine 4
		subq.b	#2,obRoutine(a0)
		move.b	#0,obColType(a0)
		bsr.w	FindFreeObj
		bne.w	GRing_PlaySnd
		move.b	#id_RingFlash,0(a1) ; load giant ring flash object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	a0,$3C(a1)
		move.w	(v_player+obX).w,d0
		cmp.w	obX(a0),d0	; has Sonic come from the left?
		blo.s	GRing_PlaySnd	; if yes, branch
		bset	#0,obRender(a1)	; reverse flash object

GRing_PlaySnd:
		move.w	#sfx_GiantRing,d0
		jsr	(PlaySound_Special).l	; play giant ring sound
		bra.s	GRing_Animate
; ===========================================================================

GRing_Delete:	; Routine 6
		bra.w	DeleteObject

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7C - flash effect when you collect the	giant ring
; ---------------------------------------------------------------------------

; Obj7C:
RingFlash:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Flash_Index(pc,d0.w),d1
		jmp	Flash_Index(pc,d1.w)
; ===========================================================================
Flash_Index:	dc.w Flash_Main-Flash_Index
		dc.w Flash_ChkDel-Flash_Index
		dc.w Flash_Delete-Flash_Index
; ===========================================================================

Flash_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Flash,obMap(a0)
		move.w	#$2462,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#0,obPriority(a0)
		move.b	#$20,obActWid(a0)
		move.b	#$FF,obFrame(a0)

Flash_ChkDel:	; Routine 2
		bsr.s	Flash_Collect
		out_of_range.w	DeleteObject
		bra.w	DisplaySprite

Flash_Collect:
		subq.b	#1,obTimeFrame(a0)
		bpl.s	locret_9F76
		move.b	#1,obTimeFrame(a0)
		addq.b	#1,obFrame(a0)
		cmpi.b	#8,obFrame(a0)	; has animation finished?
		bhs.s	Flash_End	; if yes, branch
		cmpi.b	#3,obFrame(a0)	; is 3rd frame displayed?
		bne.s	locret_9F76	; if not, branch
		movea.l	$3C(a0),a1	; get parent object address
		move.b	#6,obRoutine(a1) ; delete parent object
		move.b	#id_Null,(v_player+obAnim).w ; make Sonic invisible
		move.b	#1,(f_bigring).w ; stop Sonic getting bonuses
		clr.b	(v_invinc).w	; remove invincibility
		clr.b	(v_shield).w	; remove shield

locret_9F76:
		rts
; ===========================================================================

Flash_End:
		addq.b	#2,obRoutine(a0)
		move.w	#0,(v_player).w ; remove Sonic object
		addq.l	#4,sp
		rts
; End of function Flash_Collect

; ===========================================================================

Flash_Delete:	; Routine 4
		bra.w	DeleteObject

		include	"_anim\Rings.asm"
Map_Ring:	include	"_maps\Rings.asm"
Map_GRing:	include	"_maps\Giant Ring.asm"
Map_Flash:	include	"_maps\Ring Flash.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 26 - monitors
; ---------------------------------------------------------------------------

; Obj26:
Monitor:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Mon_Index(pc,d0.w),d1
		jmp	Mon_Index(pc,d1.w)
; ===========================================================================
Mon_Index:	dc.w Mon_Main-Mon_Index
		dc.w Mon_Solid-Mon_Index
		dc.w Mon_BreakOpen-Mon_Index
		dc.w Mon_Animate-Mon_Index
		dc.w Mon_Display-Mon_Index
; ===========================================================================

Mon_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$E,obHeight(a0)
		move.b	#$E,obWidth(a0)
		move.l	#Map_Monitor,obMap(a0)
		move.w	#$680,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$F,obActWid(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)	; has monitor been broken?
		beq.s	@notbroken	; if not, branch
		move.b	#8,obRoutine(a0) ; run "Mon_Display" routine
		move.b	#$B,obFrame(a0)	; use broken monitor frame
		rts
; ===========================================================================

	@notbroken:
		move.b	#$46,obColType(a0)
		move.b	obSubtype(a0),obAnim(a0)

Mon_Solid:	; Routine 2
		move.b	ob2ndRout(a0),d0 ; is monitor set to fall?
		beq.s	@normal		; if not, branch
		subq.b	#2,d0
		bne.s	@fall

		; 2nd Routine 2
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		bsr.w	ExitPlatform
		btst	#3,obStatus(a1) ; is Sonic on top of the monitor?
		bne.w	@ontop		; if yes, branch
		clr.b	ob2ndRout(a0)
		bra.w	Mon_Animate
; ===========================================================================

	@ontop:
		move.w	#$10,d3
		move.w	obX(a0),d2
		bsr.w	MvSonicOnPtfm
		bra.w	Mon_Animate
; ===========================================================================

@fall:		; 2nd Routine 4
		bsr.w	ObjectFall
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.w	Mon_Animate
		add.w	d1,obY(a0)
		clr.w	obVelY(a0)
		clr.b	ob2ndRout(a0)
		bra.w	Mon_Animate
; ===========================================================================

@normal:	; 2nd Routine 0
		move.w	#$1A,d1
		move.w	#$F,d2
		bsr.w	Mon_SolidSides
		beq.w	loc_A25C
		tst.w	obVelY(a1)
		bmi.s	loc_A20A
		cmpi.b	#id_Roll,obAnim(a1) ; is Sonic rolling?
		beq.s	loc_A25C	; if yes, branch

loc_A20A:
		tst.w	d1
		bpl.s	loc_A220
		sub.w	d3,obY(a1)
		bsr.w	loc_74AE
		move.b	#2,ob2ndRout(a0)
		bra.w	Mon_Animate
; ===========================================================================

loc_A220:
		tst.w	d0
		beq.w	loc_A246
		bmi.s	loc_A230
		tst.w	obVelX(a1)
		bmi.s	loc_A246
		bra.s	loc_A236
; ===========================================================================

loc_A230:
		tst.w	obVelX(a1)
		bpl.s	loc_A246

loc_A236:
		sub.w	d0,obX(a1)
		move.w	#0,obInertia(a1)
		move.w	#0,obVelX(a1)

loc_A246:
		btst	#1,obStatus(a1)
		bne.s	loc_A26A
		bset	#5,obStatus(a1)
		bset	#5,obStatus(a0)
		bra.s	Mon_Animate
; ===========================================================================

loc_A25C:
		btst	#5,obStatus(a0)
		beq.s	Mon_Animate
		move.w	#1,obAnim(a1)	; clear obAnim and set obNextAni to 1

loc_A26A:
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)

Mon_Animate:	; Routine 6
		lea	(Ani_Monitor).l,a1
		bsr.w	AnimateSprite

Mon_Display:	; Routine 8
		bsr.w	DisplaySprite
		out_of_range.w	DeleteObject
		rts
; ===========================================================================

Mon_BreakOpen:	; Routine 4
		addq.b	#2,obRoutine(a0)
		move.b	#0,obColType(a0)
		bsr.w	FindFreeObj
		bne.s	Mon_Explode
		move.b	#id_PowerUp,0(a1) ; load monitor contents object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obAnim(a0),obAnim(a1)

Mon_Explode:
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_ExplosionItem,0(a1) ; load explosion object
		addq.b	#2,obRoutine(a1) ; don't create an animal
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

	@fail:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bset	#0,2(a2,d0.w)
		move.b	#9,obAnim(a0)	; set monitor type to broken
		bra.w	DisplaySprite

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2E - contents of monitors
; ---------------------------------------------------------------------------

; Obj2E:
PowerUp:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Pow_Index(pc,d0.w),d1
		jsr	Pow_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
Pow_Index:	dc.w Pow_Main-Pow_Index
		dc.w Pow_Move-Pow_Index
		dc.w Pow_Delete-Pow_Index
; ===========================================================================

Pow_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$680,obGfx(a0)
		move.b	#$24,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.w	#-$300,obVelY(a0)
		moveq	#0,d0
		move.b	obAnim(a0),d0	; get subtype
		addq.b	#2,d0
		move.b	d0,obFrame(a0)	; use correct frame
		movea.l	#Map_Monitor,a1
		add.b	d0,d0
		adda.w	(a1,d0.w),a1
		addq.w	#1,a1
		move.l	a1,obMap(a0)

Pow_Move:	; Routine 2
		tst.w	obVelY(a0)	; is object moving?
		bpl.w	Pow_Checks	; if not, branch
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; reduce object speed
		rts
; ===========================================================================

Pow_Checks:
		addq.b	#2,obRoutine(a0)
		move.w	#29,obTimeFrame(a0) ; display icon for half a second

Pow_ChkEggman:
		move.b	obAnim(a0),d0
		cmpi.b	#1,d0		; does monitor contain Eggman?
		bne.s	Pow_ChkSonic
		rts			; Eggman monitor does nothing
; ===========================================================================

Pow_ChkSonic:
		cmpi.b	#2,d0		; does monitor contain Sonic?
		bne.s	Pow_ChkShoes

	ExtraLife:
		addq.b	#1,(v_lives).w	; add 1 to the number of lives you have
		addq.b	#1,(f_lifecount).w ; update the lives counter
		move.w	#bgm_ExtraLife,d0
		jmp	(PlaySound).l	; play extra life music
; ===========================================================================

Pow_ChkShoes:
		cmpi.b	#3,d0		; does monitor contain speed shoes?
		bne.s	Pow_ChkShield

		move.b	#1,(v_shoes).w	; speed up the BG music
		move.w	#$4B0,(v_player+$34).w	; time limit for the power-up
		move.w	#$C00,(v_sonspeedmax).w ; change Sonic's top speed
		move.w	#$18,(v_sonspeedacc).w	; change Sonic's acceleration
		move.w	#$80,(v_sonspeeddec).w	; change Sonic's deceleration
		move.w	#bgm_Speedup,d0
		jmp	(PlaySound).l		; Speed up the music
; ===========================================================================

Pow_ChkShield:
		cmpi.b	#4,d0		; does monitor contain a shield?
		bne.s	Pow_ChkInvinc

		move.b	#1,(v_shield).w	; give Sonic a shield
		move.b	#id_ShieldItem,(v_shieldobj).w ; load shield object ($38)
		move.w	#sfx_Shield,d0
		jmp	(PlaySound).l	; play shield sound
; ===========================================================================

Pow_ChkInvinc:
		cmpi.b	#5,d0		; does monitor contain invincibility?
		bne.s	Pow_ChkRings

		move.b	#1,(v_invinc).w	; make Sonic invincible
		move.w	#$4B0,(v_player+$32).w ; time limit for the power-up
		move.b	#id_ShieldItem,(v_starsobj1).w ; load stars object ($3801)
		move.b	#1,(v_starsobj1+obAnim).w
		move.b	#id_ShieldItem,(v_starsobj2).w ; load stars object ($3802)
		move.b	#2,(v_starsobj2+obAnim).w
		move.b	#id_ShieldItem,(v_starsobj3).w ; load stars object ($3803)
		move.b	#3,(v_starsobj3+obAnim).w
		move.b	#id_ShieldItem,(v_starsobj4).w ; load stars object ($3804)
		move.b	#4,(v_starsobj4+obAnim).w
		tst.b	(f_lockscreen).w ; is boss mode on?
		bne.s	Pow_NoMusic	; if yes, branch
		cmpi.w	#$C,(v_air).w
		bls.s	Pow_NoMusic
		move.w	#bgm_Invincible,d0
		jmp	(PlaySound).l ; play invincibility music
; ===========================================================================

Pow_NoMusic:
		rts
; ===========================================================================

Pow_ChkRings:
		cmpi.b	#6,d0		; does monitor contain 10 rings?
		bne.s	Pow_ChkS

		addi.w	#10,(v_rings).w	; add 10 rings to the number of rings you have
		ori.b	#1,(f_ringcount).w ; update the ring counter
		cmpi.w	#100,(v_rings).w ; check if you have 100 rings
		blo.s	Pow_RingSound
		bset	#1,(v_lifecount).w
		beq.w	ExtraLife
		cmpi.w	#200,(v_rings).w ; check if you have 200 rings
		blo.s	Pow_RingSound
		bset	#2,(v_lifecount).w
		beq.w	ExtraLife

	Pow_RingSound:
		move.w	#sfx_Ring,d0
		jmp	(PlaySound).l	; play ring sound
; ===========================================================================

Pow_ChkS:
		cmpi.b	#7,d0		; does monitor contain 'S'?
		bne.s	Pow_ChkEnd
		nop

Pow_ChkEnd:
		rts			; 'S' and goggles monitors do nothing
; ===========================================================================

Pow_Delete:	; Routine 4
		subq.w	#1,obTimeFrame(a0)
		bmi.w	DeleteObject	; delete after half a second
		rts

; ---------------------------------------------------------------------------
; Subroutine to make the sides of a monitor solid
; ---------------------------------------------------------------------------

Mon_SolidSides:
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	loc_A4E6
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.s	loc_A4E6
		move.b	obHeight(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	obY(a1),d3
		sub.w	obY(a0),d3
		add.w	d2,d3
		bmi.s	loc_A4E6
		add.w	d2,d2
		cmp.w	d2,d3
		bhs.s	loc_A4E6
		tst.b	(f_playerctrl).w
		bmi.s	loc_A4E6
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	loc_A4E6
		tst.w	(v_debuguse).w
		bne.s	loc_A4E6
		cmp.w	d0,d1
		bhs.s	loc_A4DC
		add.w	d1,d1
		sub.w	d1,d0

loc_A4DC:
		cmpi.w	#$10,d3
		blo.s	loc_A4EA

loc_A4E2:
		moveq	#1,d1
		rts
; ===========================================================================

loc_A4E6:
		moveq	#0,d1
		rts
; ===========================================================================

loc_A4EA:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addq.w	#4,d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	obX(a1),d1
		sub.w	obX(a0),d1
		bmi.s	loc_A4E2
		cmp.w	d2,d1
		bhs.s	loc_A4E2
		moveq	#-1,d1
		rts
; End of function Mon_SolidSides

		include	"_anim\Monitor.asm"
Map_Monitor:	include	"_maps\Monitor.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0E - Sonic on the title screen
; ---------------------------------------------------------------------------

; Obj0E:
TitleSonic:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	TSon_Index(pc,d0.w),d1
		jmp	TSon_Index(pc,d1.w)
; ===========================================================================
TSon_Index:	dc.w TSon_Main-TSon_Index
		dc.w TSon_Delay-TSon_Index
		dc.w TSon_Move-TSon_Index
		dc.w TSon_Animate-TSon_Index
; ===========================================================================

TSon_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$F0,obX(a0)
		move.w	#$DE,obScreenY(a0) ; position is fixed to screen
		move.l	#Map_TSon,obMap(a0)
		move.w	#$2300,obGfx(a0)
		move.b	#1,obPriority(a0)
		move.b	#29,obDelayAni(a0) ; set time delay to 0.5 seconds
		lea	(Ani_TSon).l,a1
		bsr.w	AnimateSprite

TSon_Delay:	;Routine 2
		subq.b	#1,obDelayAni(a0) ; subtract 1 from time delay
		bpl.s	@wait		; if time remains, branch
		addq.b	#2,obRoutine(a0) ; go to next routine
		bra.w	DisplaySprite

	@wait:
		rts
; ===========================================================================

TSon_Move:	; Routine 4
		subq.w	#8,obScreenY(a0) ; move Sonic up
		cmpi.w	#$96,obScreenY(a0) ; has Sonic reached final position?
		bne.s	@display	; if not, branch
		addq.b	#2,obRoutine(a0)

	@display:
		bra.w	DisplaySprite

		rts
; ===========================================================================

TSon_Animate:	; Routine 6
		lea	(Ani_TSon).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite

		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0F - "PRESS START BUTTON" and "TM" from title screen
; ---------------------------------------------------------------------------

; Obj0F:
PSBTM:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	PSB_Index(pc,d0.w),d1
		jsr	PSB_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
PSB_Index:	dc.w PSB_Main-PSB_Index
		dc.w PSB_PrsStart-PSB_Index
		dc.w PSB_Exit-PSB_Index
; ===========================================================================

PSB_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$D0,obX(a0)
		move.w	#$130,obScreenY(a0)
		move.l	#Map_PSB,obMap(a0)
		move.w	#$200,obGfx(a0)
		cmpi.b	#2,obFrame(a0)	; is object "PRESS START"?
		blo.s	PSB_PrsStart	; if yes, branch

		addq.b	#2,obRoutine(a0)
		cmpi.b	#3,obFrame(a0)	; is the object "TM"?
		bne.s	PSB_Exit	; if not, branch

		move.w	#$2510,obGfx(a0) ; "TM" specific code
		move.w	#$170,obX(a0)
		move.w	#$F8,obScreenY(a0)

PSB_Exit:	; Routine 4
		rts
; ===========================================================================

PSB_PrsStart:	; Routine 2
		lea	(Ani_PSBTM).l,a1
		bra.w	AnimateSprite	; "PRESS START" is animated

		include	"_anim\Title Screen Sonic.asm"
		include	"_anim\Press Start and TM.asm"

; ---------------------------------------------------------------------------
; Subroutine to animate	a sprite using an animation script
; ---------------------------------------------------------------------------

AnimateSprite:
		moveq	#0,d0
		move.b	obAnim(a0),d0	; move animation number to d0
		cmp.b	obNextAni(a0),d0 ; is animation set to restart?
		beq.s	Anim_Run	; if not, branch

		move.b	d0,obNextAni(a0) ; set to "no restart"
		move.b	#0,obAniFrame(a0) ; reset animation
		move.b	#0,obTimeFrame(a0) ; reset frame duration

Anim_Run:
		subq.b	#1,obTimeFrame(a0) ; subtract 1 from frame duration
		bpl.s	Anim_Wait	; if time remains, branch
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation script
		move.b	(a1),obTimeFrame(a0) ; load frame duration
		moveq	#0,d1
		move.b	obAniFrame(a0),d1 ; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		bmi.s	Anim_End_FF	; if animation is complete, branch

Anim_Next:
		move.b	d0,d1
		andi.b	#$1F,d0
		move.b	d0,obFrame(a0)	; load sprite number
		move.b	obStatus(a0),d0
		rol.b	#3,d1
		eor.b	d0,d1
		andi.b	#3,d1
		andi.b	#$FC,obRender(a0)
		or.b	d1,obRender(a0)
		addq.b	#1,obAniFrame(a0) ; next frame number

Anim_Wait:
		rts
; ===========================================================================

Anim_End_FF:
		addq.b	#1,d0		; is the end flag = $FF ?
		bne.s	Anim_End_FE	; if not, branch
		move.b	#0,obAniFrame(a0) ; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.s	Anim_Next
; ===========================================================================

Anim_End_FE:
		addq.b	#1,d0		; is the end flag = $FE ?
		bne.s	Anim_End_FD	; if not, branch
		move.b	2(a1,d1.w),d0	; read the next byte in	the script
		sub.b	d0,obAniFrame(a0) ; jump back d0 bytes in the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.s	Anim_Next
; ===========================================================================

Anim_End_FD:
		addq.b	#1,d0		; is the end flag = $FD ?
		bne.s	Anim_End_FC	; if not, branch
		move.b	2(a1,d1.w),obAnim(a0) ; read next byte, run that animation

Anim_End_FC:
		addq.b	#1,d0		; is the end flag = $FC ?
		bne.s	Anim_End_FB	; if not, branch
		addq.b	#2,obRoutine(a0) ; jump to next routine

Anim_End_FB:
		addq.b	#1,d0		; is the end flag = $FB ?
		bne.s	Anim_End_FA	; if not, branch
		move.b	#0,obAniFrame(a0) ; reset animation
		clr.b	ob2ndRout(a0)	; reset 2nd routine counter

Anim_End_FA:
		addq.b	#1,d0		; is the end flag = $FA ?
		bne.s	Anim_End	; if not, branch
		addq.b	#2,ob2ndRout(a0) ; jump to next routine

Anim_End:
		rts
; End of function AnimateSprite

Map_PSB:	include	"_maps\Press Start and TM.asm"
Map_TSon:	include	"_maps\Title Screen Sonic.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2B - Chopper enemy (GHZ)
; ---------------------------------------------------------------------------

; Obj2B:
Chopper:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Chop_Index(pc,d0.w),d1
		jsr	Chop_Index(pc,d1.w)
		bra.w	RememberState
; ===========================================================================
Chop_Index:	dc.w Chop_Main-Chop_Index
		dc.w Chop_ChgSpeed-Chop_Index

chop_origY:	equ $30
; ===========================================================================

Chop_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Chop,obMap(a0)
		move.w	#$47B,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#9,obColType(a0)
		move.b	#$10,obActWid(a0)
		move.w	#-$700,obVelY(a0) ; set vertical speed
		move.w	obY(a0),chop_origY(a0) ; save original position

Chop_ChgSpeed:	; Routine 2
		lea	(Ani_Chop).l,a1
		bsr.w	AnimateSprite
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; reduce speed
		move.w	chop_origY(a0),d0
		cmp.w	obY(a0),d0	; has Chopper returned to its original position?
		bhs.s	@chganimation	; if not, branch
		move.w	d0,obY(a0)
		move.w	#-$700,obVelY(a0) ; set vertical speed

	@chganimation:
		move.b	#1,obAnim(a0)	; use fast animation
		subi.w	#$C0,d0
		cmp.w	obY(a0),d0
		bhs.s	@nochg
		move.b	#0,obAnim(a0)	; use slow animation
		tst.w	obVelY(a0)	; is Chopper at its highest point?
		bmi.s	@nochg		; if not, branch
		move.b	#2,obAnim(a0)	; use stationary animation

	@nochg:
		rts

		include	"_anim\Chopper.asm"
Map_Chop:	include	"_maps\Chopper.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2C - Jaws enemy (LZ)
; ---------------------------------------------------------------------------

; Obj2C:
Jaws:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Jaws_Index(pc,d0.w),d1
		jmp	Jaws_Index(pc,d1.w)
; ===========================================================================
Jaws_Index:	dc.w Jaws_Main-Jaws_Index
		dc.w Jaws_Turn-Jaws_Index

jaws_timecount:	equ $30
jaws_timedelay:	equ $32
; ===========================================================================

Jaws_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Jaws,obMap(a0)
		move.w	#$2486,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$A,obColType(a0)
		move.b	#4,obPriority(a0)
		move.b	#$10,obActWid(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; load object subtype number
		lsl.w	#6,d0		; multiply d0 by 64
		subq.w	#1,d0
		move.w	d0,jaws_timecount(a0) ; set turn delay time
		move.w	d0,jaws_timedelay(a0)
		move.w	#-$40,obVelX(a0) ; move Jaws to the left
		btst	#0,obStatus(a0)	; is Jaws facing left?
		beq.s	Jaws_Turn	; if yes, branch
		neg.w	obVelX(a0)	; move Jaws to the right

Jaws_Turn:	; Routine 2
		subq.w	#1,jaws_timecount(a0) ; subtract 1 from turn delay time
		bpl.s	@animate	; if time remains, branch
		move.w	jaws_timedelay(a0),jaws_timecount(a0) ; reset turn delay time
		neg.w	obVelX(a0)	; change speed direction
		bchg	#0,obStatus(a0)	; change Jaws facing direction
		move.b	#1,obNextAni(a0) ; reset animation

	@animate:
		lea	(Ani_Jaws).l,a1
		bsr.w	AnimateSprite
		bsr.w	SpeedToPos
		bra.w	RememberState

		include	"_anim\Jaws.asm"
Map_Jaws:	include	"_maps\Jaws.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2D - Burrobot enemy (LZ)
; ---------------------------------------------------------------------------

; Obj2D:
Burrobot:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Burro_Index(pc,d0.w),d1
		jmp	Burro_Index(pc,d1.w)
; ===========================================================================
Burro_Index:	dc.w Burro_Main-Burro_Index
		dc.w Burro_Action-Burro_Index

burro_timedelay:	equ $30		; time between direction changes
; ===========================================================================

Burro_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$13,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.l	#Map_Burro,obMap(a0)
		move.w	#$4A6,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#5,obColType(a0)
		move.b	#$C,obActWid(a0)
		addq.b	#6,ob2ndRout(a0) ; run "Burro_ChkSonic" routine
		move.b	#2,obAnim(a0)

Burro_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		lea	(Ani_Burro).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
@index:		dc.w @changedir-@index
		dc.w Burro_Move-@index
		dc.w Burro_Jump-@index
		dc.w Burro_ChkSonic-@index
; ===========================================================================

@changedir:
		subq.w	#1,burro_timedelay(a0)
		bpl.s	@nochg
		addq.b	#2,ob2ndRout(a0)
		move.w	#255,burro_timedelay(a0)
		move.w	#$80,obVelX(a0)
		move.b	#1,obAnim(a0)
		bchg	#0,obStatus(a0)	; change direction the Burrobot is facing
		beq.s	@nochg
		neg.w	obVelX(a0)	; change direction the Burrobot is moving

	@nochg:
		rts
; ===========================================================================

Burro_Move:
		subq.w	#1,burro_timedelay(a0)
		bmi.s	loc_AD84
		bsr.w	SpeedToPos
		bchg	#0,$32(a0)
		bne.s	loc_AD78
		move.w	obX(a0),d3
		addi.w	#$C,d3
		btst	#0,obStatus(a0)
		bne.s	loc_AD6A
		subi.w	#$18,d3

loc_AD6A:
		jsr	(ObjFloorDist2).l
		cmpi.w	#$C,d1
		bge.s	loc_AD84
		rts
; ===========================================================================

loc_AD78:
		jsr	(ObjFloorDist).l
		add.w	d1,obY(a0)
		rts
; ===========================================================================

loc_AD84:
		btst	#2,(v_vbla_byte).w
		beq.s	loc_ADA4
		subq.b	#2,ob2ndRout(a0)
		move.w	#59,burro_timedelay(a0)
		move.w	#0,obVelX(a0)
		move.b	#0,obAnim(a0)
		rts
; ===========================================================================

loc_ADA4:
		addq.b	#2,ob2ndRout(a0)
		move.w	#-$400,obVelY(a0)
		move.b	#2,obAnim(a0)
		rts
; ===========================================================================

Burro_Jump:
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		bmi.s	locret_ADF0
		move.b	#3,obAnim(a0)
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	locret_ADF0
		add.w	d1,obY(a0)
		move.w	#0,obVelY(a0)
		move.b	#1,obAnim(a0)
		move.w	#255,burro_timedelay(a0)
		subq.b	#2,ob2ndRout(a0)
		bsr.w	Burro_ChkSonic2

locret_ADF0:
		rts
; ===========================================================================

Burro_ChkSonic:
		move.w	#$60,d2
		bsr.w	Burro_ChkSonic2
		bhs.s	locret_AE20
		move.w	(v_player+obY).w,d0
		sub.w	obY(a0),d0
		bhs.s	locret_AE20
		cmpi.w	#-$80,d0
		blo.s	locret_AE20
		tst.w	(v_debuguse).w
		bne.s	locret_AE20
		subq.b	#2,ob2ndRout(a0)
		move.w	d1,obVelX(a0)
		move.w	#-$400,obVelY(a0)

locret_AE20:
		rts

Burro_ChkSonic2:
		move.w	#$80,d1
		bset	#0,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	loc_AE40
		neg.w	d0
		neg.w	d1
		bclr	#0,obStatus(a0)

loc_AE40:
		cmp.w	d2,d0
		rts
; End of function Burro_ChkSonic2

		include	"_anim\Burrobot.asm"
Map_Burro:	include	"_maps\Burrobot.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2F - large grass-covered platforms (MZ)
; ---------------------------------------------------------------------------

; Obj2F:
LargeGrass:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	LGrass_Index(pc,d0.w),d1
		jmp	LGrass_Index(pc,d1.w)
; ===========================================================================
LGrass_Index:	dc.w LGrass_Main-LGrass_Index
		dc.w LGrass_Action-LGrass_Index

lgrass_origX:	equ $2A
lgrass_origY:	equ $2C

LGrass_Data:	dc.w LGrass_Data1-LGrass_Data 	; collision angle data
		dc.b 0,	$40			; frame number,	platform width
		dc.w LGrass_Data3-LGrass_Data
		dc.b 1,	$40
		dc.w LGrass_Data2-LGrass_Data
		dc.b 2,	$20
; ===========================================================================

LGrass_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_LGrass,obMap(a0)
		move.w	#$C000,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#5,obPriority(a0)
		move.w	obY(a0),lgrass_origY(a0)
		move.w	obX(a0),lgrass_origX(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		lsr.w	#2,d0
		andi.w	#$1C,d0
		lea	LGrass_Data(pc,d0.w),a1
		move.w	(a1)+,d0
		lea	LGrass_Data(pc,d0.w),a2
		move.l	a2,$30(a0)
		move.b	(a1)+,obFrame(a0)
		move.b	(a1),obActWid(a0)
		andi.b	#$F,obSubtype(a0)
		move.b	#$40,obHeight(a0)
		bset	#4,1(a0)

LGrass_Action:	; Routine 2
		bsr.w	LGrass_Types
		tst.b	ob2ndRout(a0)
		beq.s	LGrass_Solid
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		bsr.w	ExitPlatform
		btst	#3,obStatus(a1)
		bne.w	LGrass_Slope
		clr.b	ob2ndRout(a0)
		bra.s	LGrass_Display
; ===========================================================================

LGrass_Slope:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		movea.l	$30(a0),a2
		move.w	obX(a0),d2
		bsr.w	SlopeObject2
		bra.s	LGrass_Display
; ===========================================================================

LGrass_Solid:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		move.w	#$20,d2
		cmpi.b	#2,obFrame(a0)
		bne.s	loc_AF8E
		move.w	#$30,d2

loc_AF8E:
		movea.l	$30(a0),a2
		bsr.w	SolidObject2F

LGrass_Display:
		bsr.w	DisplaySprite
		bra.w	LGrass_ChkDel

LGrass_Types:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	LGrass_TypeIndex(pc,d0.w),d1
		jmp	LGrass_TypeIndex(pc,d1.w)
; End of function LGrass_Types

; ===========================================================================
LGrass_TypeIndex:dc.w LGrass_Type00-LGrass_TypeIndex
		dc.w LGrass_Type01-LGrass_TypeIndex
		dc.w LGrass_Type02-LGrass_TypeIndex
		dc.w LGrass_Type03-LGrass_TypeIndex
		dc.w LGrass_Type04-LGrass_TypeIndex
		dc.w LGrass_Type05-LGrass_TypeIndex
; ===========================================================================

LGrass_Type00:
		rts			; type 00 platform doesn't move
; ===========================================================================

LGrass_Type01:
		move.b	(v_oscillate+2).w,d0
		move.w	#$20,d1
		bra.s	LGrass_Move
; ===========================================================================

LGrass_Type02:
		move.b	(v_oscillate+6).w,d0
		move.w	#$30,d1
		bra.s	LGrass_Move
; ===========================================================================

LGrass_Type03:
		move.b	(v_oscillate+$A).w,d0
		move.w	#$40,d1
		bra.s	LGrass_Move
; ===========================================================================

LGrass_Type04:
		move.b	(v_oscillate+$E).w,d0
		move.w	#$60,d1

LGrass_Move:
		btst	#3,obSubtype(a0)
		beq.s	loc_AFF2
		neg.w	d0
		add.w	d1,d0

loc_AFF2:
		move.w	lgrass_origY(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)	; update position on y-axis
		rts
; ===========================================================================

LGrass_Type05:
		move.b	$34(a0),d0
		tst.b	ob2ndRout(a0)
		bne.s	loc_B010
		subq.b	#2,d0
		bhs.s	loc_B01C
		moveq	#0,d0
		bra.s	loc_B01C
; ===========================================================================

loc_B010:
		addq.b	#4,d0
		cmpi.b	#$40,d0
		blo.s	loc_B01C
		move.b	#$40,d0

loc_B01C:
		move.b	d0,$34(a0)
		jsr	(CalcSine).l
		lsr.w	#4,d0
		move.w	d0,d1
		add.w	lgrass_origY(a0),d0
		move.w	d0,obY(a0)
		cmpi.b	#$20,$34(a0)
		bne.s	loc_B07A
		tst.b	$35(a0)
		bne.s	loc_B07A
		move.b	#1,$35(a0)
		bsr.w	FindNextFreeObj
		bne.s	loc_B07A
		move.b	#id_GrassFire,0(a1) ; load sitting flame object
		move.w	obX(a0),obX(a1)
		move.w	lgrass_origY(a0),lgrass_origY(a1)
		addq.w	#8,lgrass_origY(a1)
		subq.w	#3,lgrass_origY(a1)
		subi.w	#$40,obX(a1)
		move.l	$30(a0),$30(a1)
		move.l	a0,$38(a1)
		movea.l	a0,a2
		bsr.s	sub_B09C

loc_B07A:
		moveq	#0,d2
		lea	$36(a0),a2
		move.b	(a2)+,d2
		subq.b	#1,d2
		blo.s	locret_B09A

loc_B086:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.w	#v_objspace&$FFFF,d0
		movea.w	d0,a1
		move.w	d1,$3C(a1)
		dbf	d2,loc_B086

locret_B09A:
		rts

sub_B09C:
		lea	$36(a2),a2
		moveq	#0,d0
		move.b	(a2),d0
		addq.b	#1,(a2)
		lea	1(a2,d0.w),a2
		move.w	a1,d0
		subi.w	#v_objspace&$FFFF,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,(a2)
		rts
; End of function sub_B09C

; ===========================================================================

LGrass_ChkDel:
		tst.b	$35(a0)
		beq.s	loc_B0C6
		tst.b	obRender(a0)
		bpl.s	LGrass_DelFlames

loc_B0C6:
		out_of_range.w	DeleteObject,lgrass_origX(a0)
		rts
; ===========================================================================

LGrass_DelFlames:
		moveq	#0,d2

loc_B0E8:
		lea	$36(a0),a2
		move.b	(a2),d2
		clr.b	(a2)+
		subq.b	#1,d2
		blo.s	locret_B116

loc_B0F4:
		moveq	#0,d0
		move.b	(a2),d0
		clr.b	(a2)+
		lsl.w	#6,d0
		addi.w	#v_objspace&$FFFF,d0
		movea.w	d0,a1
		bsr.w	DeleteChild
		dbf	d2,loc_B0F4
		move.b	#0,$35(a0)
		move.b	#0,$34(a0)

locret_B116:
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Collision data for large moving platforms (MZ)
; ---------------------------------------------------------------------------
LGrass_Data1:	incbin	"misc\mz_pfm1.bin"
		even
LGrass_Data2:	incbin	"misc\mz_pfm2.bin"
		even
LGrass_Data3:	incbin	"misc\mz_pfm3.bin"
		even

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 35 - fireball that sits on the floor (MZ)
; (appears when you walk on sinking platforms)
; ---------------------------------------------------------------------------

; Obj35:
GrassFire:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GFire_Index(pc,d0.w),d1
		jmp	GFire_Index(pc,d1.w)
; ===========================================================================
GFire_Index:	dc.w GFire_Main-GFire_Index
		dc.w loc_B238-GFire_Index
		dc.w GFire_Move-GFire_Index

gfire_origX:	equ $2A
; ===========================================================================

GFire_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Fire,obMap(a0)
		move.w	#$345,obGfx(a0)
		move.w	obX(a0),gfire_origX(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#$8B,obColType(a0)
		move.b	#8,obActWid(a0)
		move.w	#sfx_Burning,d0
		jsr	(PlaySound_Special).l	 ; play burning sound
		tst.b	obSubtype(a0)
		beq.s	loc_B238
		addq.b	#2,obRoutine(a0)
		bra.w	GFire_Move
; ===========================================================================

loc_B238:	; Routine 2
		movea.l	$30(a0),a1
		move.w	obX(a0),d1
		sub.w	gfire_origX(a0),d1
		addi.w	#$C,d1
		move.w	d1,d0
		lsr.w	#1,d0
		move.b	(a1,d0.w),d0
		neg.w	d0
		add.w	$2C(a0),d0
		move.w	d0,d2
		add.w	$3C(a0),d0
		move.w	d0,obY(a0)
		cmpi.w	#$84,d1
		bhs.s	loc_B2B0
		addi.l	#$10000,obX(a0)
		cmpi.w	#$80,d1
		bhs.s	loc_B2B0
		move.l	obX(a0),d0
		addi.l	#$80000,d0
		andi.l	#$FFFFF,d0
		bne.s	loc_B2B0
		bsr.w	FindNextFreeObj
		bne.s	loc_B2B0
		move.b	#id_GrassFire,0(a1)
		move.w	obX(a0),obX(a1)
		move.w	d2,$2C(a1)
		move.w	$3C(a0),$3C(a1)
		move.b	#1,obSubtype(a1)
		movea.l	$38(a0),a2
		bsr.w	sub_B09C

loc_B2B0:
		bra.s	GFire_Animate
; ===========================================================================

GFire_Move:	; Routine 4
		move.w	$2C(a0),d0
		add.w	$3C(a0),d0
		move.w	d0,obY(a0)

GFire_Animate:
		lea	(Ani_GFire).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite

		include	"_anim\Burning Grass.asm"
Map_LGrass:	include	"_maps\MZ Large Grassy Platforms.asm"
Map_Fire:	include	"_maps\Fireballs.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 30 - large green glass blocks (MZ)
; ---------------------------------------------------------------------------

; Obj30:
GlassBlock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Glass_Index(pc,d0.w),d1
		jsr	Glass_Index(pc,d1.w)
		out_of_range.w	Glass_Delete
		bra.w	DisplaySprite
; ===========================================================================

Glass_Delete:
		bra.w	DeleteObject
; ===========================================================================
Glass_Index:	dc.w Glass_Main-Glass_Index
		dc.w Glass_Block012-Glass_Index
		dc.w Glass_Reflect012-Glass_Index
		dc.w Glass_Block34-Glass_Index
		dc.w Glass_Reflect34-Glass_Index

glass_dist:	equ $32		; distance block moves when switch is pressed
glass_parent:	equ $3C		; address of parent object

Glass_Vars1:	dc.b 2,	0, 0	; routine num, y-axis dist from origin,	frame num
		dc.b 4,	0, 1
Glass_Vars2:	dc.b 6,	0, 2
		dc.b 8,	0, 1
; ===========================================================================

Glass_Main:	; Routine 0
		lea	(Glass_Vars1).l,a2
		moveq	#1,d1
		move.b	#$48,obHeight(a0)
		cmpi.b	#3,obSubtype(a0) ; is object type 0/1/2 ?
		blo.s	@IsType012	; if yes, branch

		lea	(Glass_Vars2).l,a2
		moveq	#1,d1
		move.b	#$38,obHeight(a0)

	@IsType012:
		movea.l	a0,a1
		bra.s	@Load		; load main object
; ===========================================================================

	@Repeat:
		bsr.w	FindNextFreeObj
		bne.s	@Fail

@Load:
		move.b	(a2)+,obRoutine(a1)
		move.b	#id_GlassBlock,0(a1)
		move.w	obX(a0),obX(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	obY(a0),d0
		move.w	d0,obY(a1)
		move.l	#Map_Glass,obMap(a1)
		move.w	#$C38E,obGfx(a1)
		move.b	#4,obRender(a1)
		move.w	obY(a1),$30(a1)
		move.b	obSubtype(a0),obSubtype(a1)
		move.b	#$20,obActWid(a1)
		move.b	#4,obPriority(a1)
		move.b	(a2)+,obFrame(a1)
		move.l	a0,glass_parent(a1)
		dbf	d1,@Repeat	; repeat once to load "reflection object"

		move.b	#$10,obActWid(a1)
		move.b	#3,obPriority(a1)
		addq.b	#8,obSubtype(a1)
		andi.b	#$F,obSubtype(a1)

	@Fail:
		move.w	#$90,glass_dist(a0)
		bset	#4,obRender(a0)

Glass_Block012:	; Routine 2
		bsr.w	Glass_Types
		move.w	#$2B,d1
		move.w	#$48,d2
		move.w	#$49,d3
		move.w	obX(a0),d4
		bra.w	SolidObject
; ===========================================================================

Glass_Reflect012:
		; Routine 4
		movea.l	$3C(a0),a1
		move.w	glass_dist(a1),glass_dist(a0)
		bra.w	Glass_Types
; ===========================================================================

Glass_Block34:	; Routine 6
		bsr.w	Glass_Types
		move.w	#$2B,d1
		move.w	#$38,d2
		move.w	#$39,d3
		move.w	obX(a0),d4
		bra.w	SolidObject
; ===========================================================================

Glass_Reflect34:
		; Routine 8
		movea.l	$3C(a0),a1
		move.w	glass_dist(a1),glass_dist(a0)
		move.w	obY(a1),$30(a0)
		bra.w	Glass_Types

Glass_Types:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	Glass_TypeIndex(pc,d0.w),d1
		jmp	Glass_TypeIndex(pc,d1.w)
; End of function Glass_Types

; ===========================================================================
Glass_TypeIndex:dc.w Glass_Type00-Glass_TypeIndex
		dc.w Glass_Type01-Glass_TypeIndex
		dc.w Glass_Type02-Glass_TypeIndex
		dc.w Glass_Type03-Glass_TypeIndex
		dc.w Glass_Type04-Glass_TypeIndex
; ===========================================================================

Glass_Type00:
		rts
; ===========================================================================

Glass_Type01:
		move.b	(v_oscillate+$12).w,d0
		move.w	#$40,d1
		bra.s	loc_B514
; ===========================================================================

Glass_Type02:
		move.b	(v_oscillate+$12).w,d0
		move.w	#$40,d1
		neg.w	d0
		add.w	d1,d0

loc_B514:
		btst	#3,obSubtype(a0)
		beq.s	loc_B526
		neg.w	d0
		add.w	d1,d0
		lsr.b	#1,d0
		addi.w	#$20,d0

loc_B526:
		bra.w	loc_B5EE
; ===========================================================================

Glass_Type03:
		btst	#3,obSubtype(a0)
		beq.s	loc_B53E
		move.b	(v_oscillate+$12).w,d0
		subi.w	#$10,d0
		bra.w	loc_B5EE
; ===========================================================================

loc_B53E:
		btst	#3,obStatus(a0)
		bne.s	loc_B54E
		bclr	#0,$34(a0)
		bra.s	loc_B582
; ===========================================================================

loc_B54E:
		tst.b	$34(a0)
		bne.s	loc_B582
		move.b	#1,$34(a0)
		bset	#0,$35(a0)
		beq.s	loc_B582
		bset	#7,$34(a0)
		move.w	#$10,$36(a0)
		move.b	#$A,$38(a0)
		cmpi.w	#$40,glass_dist(a0)
		bne.s	loc_B582
		move.w	#$40,$36(a0)

loc_B582:
		tst.b	$34(a0)
		bpl.s	loc_B5AA
		tst.b	$38(a0)
		beq.s	loc_B594
		subq.b	#1,$38(a0)
		bne.s	loc_B5AA

loc_B594:
		tst.w	glass_dist(a0)
		beq.s	loc_B5A4
		subq.w	#1,glass_dist(a0)
		subq.w	#1,$36(a0)
		bne.s	loc_B5AA

loc_B5A4:
		bclr	#7,$34(a0)

loc_B5AA:
		move.w	glass_dist(a0),d0
		bra.s	loc_B5EE
; ===========================================================================

Glass_Type04:
		btst	#3,obSubtype(a0)
		beq.s	Glass_ChkSwitch
		move.b	(v_oscillate+$12).w,d0
		subi.w	#$10,d0
		bra.s	loc_B5EE
; ===========================================================================

Glass_ChkSwitch:
		tst.b	$34(a0)
		bne.s	loc_B5E0
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; load object type number
		lsr.w	#4,d0		; read only the first nybble
		tst.b	(a2,d0.w)	; has switch number d0 been pressed?
		beq.s	loc_B5EA	; if not, branch
		move.b	#1,$34(a0)

loc_B5E0:
		tst.w	glass_dist(a0)
		beq.s	loc_B5EA
		subq.w	#2,glass_dist(a0)

loc_B5EA:
		move.w	glass_dist(a0),d0

loc_B5EE:
		move.w	$30(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)
		rts

Map_Glass:	include	"_maps\MZ Large Green Glass Blocks.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 31 - stomping metal blocks on chains (MZ)
; ---------------------------------------------------------------------------

; Obj31:
ChainStomp:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	CStom_Index(pc,d0.w),d1
		jmp	CStom_Index(pc,d1.w)
; ===========================================================================
CStom_Index:	dc.w CStom_Main-CStom_Index
		dc.w loc_B798-CStom_Index
		dc.w loc_B7FE-CStom_Index
		dc.w CStom_Display2-CStom_Index
		dc.w loc_B7E2-CStom_Index

CStom_switch:	equ $3A			; switch number for the current stomper

CStom_SwchNums:	dc.b 0,	0		; switch number, obj number
		dc.b 1,	0

CStom_Var:	dc.b 2,	0, 0		; routine number, y-position, frame number
		dc.b 4,	$1C, 1
		dc.b 8,	$CC, 3
		dc.b 6,	$F0, 2

word_B6A4:	dc.w $7000, $A000
		dc.w $5000, $7800
		dc.w $3800, $5800
		dc.w $B800
; ===========================================================================

CStom_Main:	; Routine 0
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		bpl.s	loc_B6CE
		andi.w	#$7F,d0
		add.w	d0,d0
		lea	CStom_SwchNums(pc,d0.w),a2
		move.b	(a2)+,CStom_switch(a0)
		move.b	(a2)+,d0
		move.b	d0,obSubtype(a0)

loc_B6CE:
		andi.b	#$F,d0
		add.w	d0,d0
		move.w	word_B6A4(pc,d0.w),d2
		tst.w	d0
		bne.s	loc_B6E0
		move.w	d2,$32(a0)

loc_B6E0:
		lea	(CStom_Var).l,a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.s	CStom_MakeStomper
; ===========================================================================

CStom_Loop:
		bsr.w	FindNextFreeObj
		bne.w	CStom_SetSize

CStom_MakeStomper:
		move.b	(a2)+,obRoutine(a1)
		move.b	#id_ChainStomp,0(a1)
		move.w	obX(a0),obX(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	obY(a0),d0
		move.w	d0,obY(a1)
		move.l	#Map_CStom,obMap(a1)
		move.w	#$300,obGfx(a1)
		move.b	#4,obRender(a1)
		move.w	obY(a1),$30(a1)
		move.b	obSubtype(a0),obSubtype(a1)
		move.b	#$10,obActWid(a1)
		move.w	d2,$34(a1)
		move.b	#4,obPriority(a1)
		move.b	(a2)+,obFrame(a1)
		cmpi.b	#1,obFrame(a1)
		bne.s	loc_B76A
		subq.w	#1,d1
		move.b	obSubtype(a0),d0
		andi.w	#$F0,d0
		cmpi.w	#$20,d0
		beq.s	CStom_MakeStomper
		move.b	#$38,obActWid(a1)
		move.b	#$90,obColType(a1)
		addq.w	#1,d1

loc_B76A:
		move.l	a0,$3C(a1)
		dbf	d1,CStom_Loop

		move.b	#3,obPriority(a1)

CStom_SetSize:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		lsr.w	#3,d0
		andi.b	#$E,d0
		lea	CStom_Var2(pc,d0.w),a2
		move.b	(a2)+,obActWid(a0)
		move.b	(a2)+,obFrame(a0)
		bra.s	loc_B798
; ===========================================================================
CStom_Var2:	dc.b $38, 0		; width, frame number
		dc.b $30, 9
		dc.b $10, $A
; ===========================================================================

loc_B798:	; Routine 2
		bsr.w	CStom_Types
		move.w	obY(a0),(v_obj31ypos).w
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		move.w	#$C,d2
		move.w	#$D,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		btst	#3,obStatus(a0)
		beq.s	CStom_Display
		cmpi.b	#$10,$32(a0)
		bhs.s	CStom_Display
		movea.l	a0,a2
		lea	(v_player).w,a0
		jsr	(KillSonic).l
		movea.l	a2,a0

CStom_Display:
		bsr.w	DisplaySprite
		bra.w	CStom_ChkDel
; ===========================================================================

loc_B7E2:	; Routine 8
		move.b	#$80,obHeight(a0)
		bset	#4,obRender(a0)
		movea.l	$3C(a0),a1
		move.b	$32(a1),d0
		lsr.b	#5,d0
		addq.b	#3,d0
		move.b	d0,obFrame(a0)

loc_B7FE:	; Routine 4
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$32(a1),d0
		add.w	$30(a0),d0
		move.w	d0,obY(a0)

CStom_Display2:	; Routine 6
		bsr.w	DisplaySprite

CStom_ChkDel:
		out_of_range.w	DeleteObject
		rts
; ===========================================================================

CStom_Types:
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	CStom_TypeIndex(pc,d0.w),d1
		jmp	CStom_TypeIndex(pc,d1.w)
; ===========================================================================
CStom_TypeIndex:dc.w CStom_Type00-CStom_TypeIndex
		dc.w CStom_Type01-CStom_TypeIndex
		dc.w CStom_Type01-CStom_TypeIndex
		dc.w CStom_Type03-CStom_TypeIndex
		dc.w CStom_Type01-CStom_TypeIndex
		dc.w CStom_Type03-CStom_TypeIndex
		dc.w CStom_Type01-CStom_TypeIndex
; ===========================================================================

CStom_Type00:
		lea	(f_switch).w,a2	; load switch statuses
		moveq	#0,d0
		move.b	CStom_switch(a0),d0 ; move number 0 or 1 to d0
		tst.b	(a2,d0.w)	; has switch (d0) been pressed?
		beq.s	loc_B8A8	; if not, branch
		tst.w	(v_obj31ypos).w
		bpl.s	loc_B872
		cmpi.b	#$10,$32(a0)
		beq.s	loc_B8A0

loc_B872:
		tst.w	$32(a0)
		beq.s	loc_B8A0
		move.b	(v_vbla_byte).w,d0
		andi.b	#$F,d0
		bne.s	loc_B892
		tst.b	1(a0)
		bpl.s	loc_B892
		move.w	#sfx_ChainRise,d0
		jsr	(PlaySound_Special).l	; play rising chain sound

loc_B892:
		subi.w	#$80,$32(a0)
		bhs.s	CStom_Restart
		move.w	#0,$32(a0)

loc_B8A0:
		move.w	#0,obVelY(a0)
		bra.s	CStom_Restart
; ===========================================================================

loc_B8A8:
		move.w	$34(a0),d1
		cmp.w	$32(a0),d1
		beq.s	CStom_Restart
		move.w	obVelY(a0),d0
		addi.w	#$70,obVelY(a0)	; make object fall
		add.w	d0,$32(a0)
		cmp.w	$32(a0),d1
		bhi.s	CStom_Restart
		move.w	d1,$32(a0)
		move.w	#0,obVelY(a0)	; stop object falling
		tst.b	obRender(a0)
		bpl.s	CStom_Restart
		move.w	#sfx_ChainStomp,d0
		jsr	(PlaySound_Special).l	; play stomping sound

CStom_Restart:
		moveq	#0,d0
		move.b	$32(a0),d0
		add.w	$30(a0),d0
		move.w	d0,obY(a0)
		rts
; ===========================================================================

CStom_Type01:
		tst.w	$36(a0)
		beq.s	loc_B938
		tst.w	$38(a0)
		beq.s	loc_B902
		subq.w	#1,$38(a0)
		bra.s	loc_B97C
; ===========================================================================

loc_B902:
		move.b	(v_vbla_byte).w,d0
		andi.b	#$F,d0
		bne.s	loc_B91C
		tst.b	obRender(a0)
		bpl.s	loc_B91C
		move.w	#sfx_ChainRise,d0
		jsr	(PlaySound_Special).l	; play rising chain sound

loc_B91C:
		subi.w	#$80,$32(a0)
		bhs.s	loc_B97C
		move.w	#0,$32(a0)
		move.w	#0,obVelY(a0)
		move.w	#0,$36(a0)
		bra.s	loc_B97C
; ===========================================================================

loc_B938:
		move.w	$34(a0),d1
		cmp.w	$32(a0),d1
		beq.s	loc_B97C
		move.w	obVelY(a0),d0
		addi.w	#$70,obVelY(a0)	; make object fall
		add.w	d0,$32(a0)
		cmp.w	$32(a0),d1
		bhi.s	loc_B97C
		move.w	d1,$32(a0)
		move.w	#0,obVelY(a0)	; stop object falling
		move.w	#1,$36(a0)
		move.w	#$3C,$38(a0)
		tst.b	obRender(a0)
		bpl.s	loc_B97C
		move.w	#sfx_ChainStomp,d0
		jsr	(PlaySound_Special).l	; play stomping sound

loc_B97C:
		bra.w	CStom_Restart
; ===========================================================================

CStom_Type03:
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	loc_B98C
		neg.w	d0

loc_B98C:
		cmpi.w	#$90,d0
		bhs.s	loc_B996
		addq.b	#1,obSubtype(a0)

loc_B996:
		bra.w	CStom_Restart

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 45 - spiked metal block from beta version (MZ)
; ---------------------------------------------------------------------------

; Obj45:
SideStomp:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	SStom_Index(pc,d0.w),d1
		jmp	SStom_Index(pc,d1.w)
; ===========================================================================
SStom_Index:	dc.w SStom_Main-SStom_Index
		dc.w SStom_Solid-SStom_Index
		dc.w loc_BA8E-SStom_Index
		dc.w SStom_Display-SStom_Index
		dc.w SStom_Pole-SStom_Index

		; routine		frame
		; 	 xpos
SStom_Var:	dc.b	2,  	 4,	0	; main block
		dc.b	4,	-$1C,	1	; spikes
		dc.b	8,	 $34,	3	; pole
		dc.b	6,	 $28,	2	; wall bracket

;word_B9BE: ; Note that this indicates three subtypes
SStom_Len:	dc.w $3800	; short
		dc.w $A000	; long
		dc.w $5000	; medium
; ===========================================================================

SStom_Main:	; Routine 0
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	SStom_Len(pc,d0.w),d2
		lea	(SStom_Var).l,a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.s	@load

	@loop:
		bsr.w	FindNextFreeObj
		bne.s	@fail

	@load:
		move.b	(a2)+,obRoutine(a1)
		move.b	#id_SideStomp,0(a1)
		move.w	obY(a0),obY(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	obX(a0),d0
		move.w	d0,obX(a1)
		move.l	#Map_SStom,obMap(a1)
		move.w	#$300,obGfx(a1)
		move.b	#4,obRender(a1)
		move.w	obX(a1),$30(a1)
		move.w	obX(a0),$3A(a1)
		move.b	obSubtype(a0),obSubtype(a1)
		move.b	#$20,obActWid(a1)
		move.w	d2,$34(a1)
		move.b	#4,obPriority(a1)
		cmpi.b	#1,(a2)		; is subobject spikes?
		bne.s	@notspikes	; if not, branch
		move.b	#$91,obColType(a1) ; use harmful collision type

	@notspikes:
		move.b	(a2)+,obFrame(a1)
		move.l	a0,$3C(a1)
		dbf	d1,@loop	; repeat 3 times

		move.b	#3,obPriority(a1)

	@fail:
		move.b	#$10,obActWid(a0)

SStom_Solid:	; Routine 2
		move.w	obX(a0),-(sp)
		bsr.w	SStom_Move
		move.w	#$17,d1
		move.w	#$20,d2
		move.w	#$20,d3
		move.w	(sp)+,d4
		bsr.w	SolidObject
		bsr.w	DisplaySprite
		bra.w	SStom_ChkDel
; ===========================================================================

SStom_Pole:	; Routine 8
		movea.l	$3C(a0),a1
		move.b	$32(a1),d0
		addi.b	#$10,d0
		lsr.b	#5,d0
		addq.b	#3,d0
		move.b	d0,obFrame(a0)

loc_BA8E:	; Routine 4
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$32(a1),d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,obX(a0)

SStom_Display:	; Routine 6
		bsr.w	DisplaySprite

SStom_ChkDel:
		out_of_range.w	DeleteObject,$3A(a0)
		rts

SStom_Move:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	off_BAD6(pc,d0.w),d1
		jmp	off_BAD6(pc,d1.w)
; End of function SStom_Move

; ===========================================================================
		; This indicates only two subtypes... that do the same thing
		; Compare to SStom_Len. This breaks subtype 02
off_BAD6:	dc.w loc_BADA-off_BAD6
		dc.w loc_BADA-off_BAD6
; ===========================================================================

loc_BADA:
		tst.w	$36(a0)
		beq.s	loc_BB08
		tst.w	$38(a0)
		beq.s	loc_BAEC
		subq.w	#1,$38(a0)
		bra.s	loc_BB3C
; ===========================================================================

loc_BAEC:
		subi.w	#$80,$32(a0)
		bhs.s	loc_BB3C
		move.w	#0,$32(a0)
		move.w	#0,obVelX(a0)
		move.w	#0,$36(a0)
		bra.s	loc_BB3C
; ===========================================================================

loc_BB08:
		move.w	$34(a0),d1
		cmp.w	$32(a0),d1
		beq.s	loc_BB3C
		move.w	obVelX(a0),d0
		addi.w	#$70,obVelX(a0)
		add.w	d0,$32(a0)
		cmp.w	$32(a0),d1
		bhi.s	loc_BB3C
		move.w	d1,$32(a0)
		move.w	#0,obVelX(a0)
		move.w	#1,$36(a0)
		move.w	#$3C,$38(a0)

loc_BB3C:
		moveq	#0,d0
		move.b	$32(a0),d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,obX(a0)
		rts

Map_CStom:	include	"_maps\Chained Stompers.asm"
Map_SStom:	include	"_maps\Sideways Stomper.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 32 - buttons (MZ, SYZ, LZ, SBZ)
; ---------------------------------------------------------------------------

; Obj32:
Button:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	But_Index(pc,d0.w),d1
		jmp	But_Index(pc,d1.w)
; ===========================================================================
But_Index:	dc.w But_Main-But_Index
		dc.w But_Pressed-But_Index
; ===========================================================================

But_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_But,obMap(a0)
		move.w	#$4513,obGfx(a0) ; MZ specific code
		cmpi.b	#id_MZ,(v_zone).w ; is level Marble Zone?
		beq.s	But_IsMZ	; if yes, branch

		move.w	#$513,obGfx(a0)	; SYZ, LZ and SBZ specific code

	But_IsMZ:
		move.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)
		addq.w	#3,obY(a0)

But_Pressed:	; Routine 2
		tst.b	obRender(a0)
		bpl.s	But_Display
		move.w	#$1B,d1
		move.w	#5,d2
		move.w	#5,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		bclr	#0,obFrame(a0)	; use "unpressed" frame
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		lea	(f_switch).w,a3
		lea	(a3,d0.w),a3
		moveq	#0,d3
		btst	#6,obSubtype(a0)
		beq.s	loc_BDB2
		moveq	#7,d3

loc_BDB2:
		tst.b	obSubtype(a0)
		bpl.s	loc_BDBE
		bsr.w	But_MZBlock
		bne.s	loc_BDC8

loc_BDBE:
		tst.b	ob2ndRout(a0)
		bne.s	loc_BDC8
		bclr	d3,(a3)
		bra.s	loc_BDDE
; ===========================================================================

loc_BDC8:
		tst.b	(a3)
		bne.s	loc_BDD6
		move.w	#sfx_Switch,d0
		jsr	(PlaySound_Special).l	; play switch sound

loc_BDD6:
		bset	d3,(a3)
		bset	#0,obFrame(a0)	; use "pressed" frame

loc_BDDE:
		btst	#5,obSubtype(a0)
		beq.s	But_Display
		subq.b	#1,obTimeFrame(a0)
		bpl.s	But_Display
		move.b	#7,obTimeFrame(a0)
		bchg	#1,obFrame(a0)

But_Display:
		bsr.w	DisplaySprite
		out_of_range.w	But_Delete
		rts
; ===========================================================================

But_Delete:
		bsr.w	DeleteObject
		rts

But_MZBlock:
		move.w	d3,-(sp)
		move.w	obX(a0),d2
		move.w	obY(a0),d3
		subi.w	#$10,d2
		subq.w	#8,d3
		move.w	#$20,d4
		move.w	#$10,d5
		lea	(v_lvlobjspace).w,a1 ; begin checking object RAM
		move.w	#$5F,d6

But_MZLoop:
		tst.b	obRender(a1)
		bpl.s	loc_BE4E
		cmpi.b	#id_PushBlock,(a1) ; is the object a green MZ block?
		beq.s	loc_BE5E	; if yes, branch

loc_BE4E:
		lea	$40(a1),a1	; check next object
		dbf	d6,But_MZLoop	; repeat $5F times

		move.w	(sp)+,d3
		moveq	#0,d0

locret_BE5A:
		rts
; ===========================================================================
But_MZData:	dc.b $10, $10
; ===========================================================================

loc_BE5E:
		moveq	#1,d0
		andi.w	#$3F,d0
		add.w	d0,d0
		lea	But_MZData-2(pc,d0.w),a2
		move.b	(a2)+,d1
		ext.w	d1
		move.w	obX(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bhs.s	loc_BE80
		add.w	d1,d1
		add.w	d1,d0
		blo.s	loc_BE84
		bra.s	loc_BE4E
; ===========================================================================

loc_BE80:
		cmp.w	d4,d0
		bhi.s	loc_BE4E

loc_BE84:
		move.b	(a2)+,d1
		ext.w	d1
		move.w	obY(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bhs.s	loc_BE9A
		add.w	d1,d1
		add.w	d1,d0
		blo.s	loc_BE9E
		bra.s	loc_BE4E
; ===========================================================================

loc_BE9A:
		cmp.w	d5,d0
		bhi.s	loc_BE4E

loc_BE9E:
		move.w	(sp)+,d3
		moveq	#1,d0
		rts
; End of function But_MZBlock

Map_But:	include	"_maps\Button.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 33 - pushable blocks (MZ, LZ)
; ---------------------------------------------------------------------------

; Obj33:
PushBlock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	PushB_Index(pc,d0.w),d1
		jmp	PushB_Index(pc,d1.w)
; ===========================================================================
PushB_Index:	dc.w PushB_Main-PushB_Index
		dc.w loc_BF6E-PushB_Index
		dc.w loc_C02C-PushB_Index

PushB_Var:	dc.b $10, 0	; object width, frame number
		dc.b $40, 1
; ===========================================================================

PushB_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$F,obHeight(a0)
		move.b	#$F,obWidth(a0)
		move.l	#Map_Push,obMap(a0)
		move.w	#$42B8,obGfx(a0) ; MZ specific code
		cmpi.b	#1,(v_zone).w
		bne.s	@notLZ
		move.w	#$43DE,obGfx(a0) ; LZ specific code

	@notLZ:
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.w	obX(a0),$34(a0)
		move.w	obY(a0),$36(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		andi.w	#$E,d0
		lea	PushB_Var(pc,d0.w),a2
		move.b	(a2)+,obActWid(a0)
		move.b	(a2)+,obFrame(a0)
		tst.b	obSubtype(a0)
		beq.s	@chkgone
		move.w	#$C2B8,obGfx(a0)

	@chkgone:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	loc_BF6E
		bclr	#7,2(a2,d0.w)
		bset	#0,2(a2,d0.w)
		bne.w	DeleteObject

loc_BF6E:	; Routine 2
		tst.b	$32(a0)
		bne.w	loc_C046
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	obX(a0),d4
		bsr.w	loc_C186
		cmpi.w	#(id_MZ<<8)+0,(v_zone).w ; is the level MZ act 1?
		bne.s	loc_BFC6	; if not, branch
		bclr	#7,obSubtype(a0)
		move.w	obX(a0),d0
		cmpi.w	#$A20,d0
		blo.s	loc_BFC6
		cmpi.w	#$AA1,d0
		bhs.s	loc_BFC6
		move.w	(v_obj31ypos).w,d0
		subi.w	#$1C,d0
		move.w	d0,obY(a0)
		bset	#7,(v_obj31ypos).w
		bset	#7,obSubtype(a0)

	loc_BFC6:
		out_of_range.s	loc_ppppp
		bra.w	DisplaySprite
; ===========================================================================

loc_ppppp:
		out_of_range.s	loc_C016,$34(a0)
		move.w	$34(a0),obX(a0)
		move.w	$36(a0),obY(a0)
		move.b	#4,obRoutine(a0)
		bra.s	loc_C02C
; ===========================================================================

loc_C016:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	loc_C028
		bclr	#0,2(a2,d0.w)

loc_C028:
		bra.w	DeleteObject
; ===========================================================================

loc_C02C:	; Routine 4
		bsr.w	ChkPartiallyVisible
		beq.s	locret_C044
		move.b	#2,obRoutine(a0)
		clr.b	$32(a0)
		clr.w	obVelX(a0)
		clr.w	obVelY(a0)

locret_C044:
		rts
; ===========================================================================

loc_C046:
		move.w	obX(a0),-(sp)
		cmpi.b	#4,ob2ndRout(a0)
		bhs.s	loc_C056
		bsr.w	SpeedToPos

loc_C056:
		btst	#1,obStatus(a0)
		beq.s	loc_C0A0
		addi.w	#$18,obVelY(a0)
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.w	loc_C09E
		add.w	d1,obY(a0)
		clr.w	obVelY(a0)
		bclr	#1,obStatus(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0
		blo.s	loc_C09E
		move.w	$30(a0),d0
		asr.w	#3,d0
		move.w	d0,obVelX(a0)
		move.b	#1,$32(a0)
		clr.w	$E(a0)

loc_C09E:
		bra.s	loc_C0E6
; ===========================================================================

loc_C0A0:
		tst.w	obVelX(a0)
		beq.w	loc_C0D6
		bmi.s	loc_C0BC
		moveq	#0,d3
		move.b	obActWid(a0),d3
		jsr	(ObjHitWallRight).l
		tst.w	d1		; has block touched a wall?
		bmi.s	PushB_StopPush	; if yes, branch
		bra.s	loc_C0E6
; ===========================================================================

loc_C0BC:
		moveq	#0,d3
		move.b	obActWid(a0),d3
		not.w	d3
		jsr	(ObjHitWallLeft).l
		tst.w	d1		; has block touched a wall?
		bmi.s	PushB_StopPush	; if yes, branch
		bra.s	loc_C0E6
; ===========================================================================

PushB_StopPush:
		clr.w	obVelX(a0)		; stop block moving
		bra.s	loc_C0E6
; ===========================================================================

loc_C0D6:
		addi.l	#$2001,obY(a0)
		cmpi.b	#$A0,obY+3(a0)
		bhs.s	loc_C104

loc_C0E6:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	(sp)+,d4
		bsr.w	loc_C186
		bsr.s	PushB_ChkLava
		bra.w	loc_BFC6
; ===========================================================================

loc_C104:
		move.w	(sp)+,d4
		lea	(v_player).w,a1
		bclr	#3,obStatus(a1)
		bclr	#3,obStatus(a0)
		bra.w	loc_ppppp
; ===========================================================================

PushB_ChkLava:
		cmpi.w	#(id_MZ<<8)+1,(v_zone).w ; is the level MZ act 2?
		bne.s	PushB_ChkLava2	; if not, branch
		move.w	#-$20,d2
		cmpi.w	#$DD0,obX(a0)
		beq.s	PushB_LoadLava
		cmpi.w	#$CC0,obX(a0)
		beq.s	PushB_LoadLava
		cmpi.w	#$BA0,obX(a0)
		beq.s	PushB_LoadLava
		rts
; ===========================================================================

PushB_ChkLava2:
		cmpi.w	#(id_MZ<<8)+2,(v_zone).w ; is the level MZ act 3?
		bne.s	PushB_NoLava	; if not, branch
		move.w	#$20,d2
		cmpi.w	#$560,obX(a0)
		beq.s	PushB_LoadLava
		cmpi.w	#$5C0,obX(a0)
		beq.s	PushB_LoadLava

PushB_NoLava:
		rts
; ===========================================================================

PushB_LoadLava:
		bsr.w	FindFreeObj
		bne.s	locret_C184
		move.b	#id_GeyserMaker,0(a1) ; load lava geyser object
		move.w	obX(a0),obX(a1)
		add.w	d2,obX(a1)
		move.w	obY(a0),obY(a1)
		addi.w	#$10,obY(a1)
		move.l	a0,$3C(a1)

locret_C184:
		rts
; ===========================================================================

loc_C186:
		move.b	ob2ndRout(a0),d0
		beq.w	loc_C218
		subq.b	#2,d0
		bne.s	loc_C1AA
		bsr.w	ExitPlatform
		btst	#3,obStatus(a1)
		bne.s	loc_C1A4
		clr.b	ob2ndRout(a0)
		rts
; ===========================================================================

loc_C1A4:
		move.w	d4,d2
		bra.w	MvSonicOnPtfm
; ===========================================================================

loc_C1AA:
		subq.b	#2,d0
		bne.s	loc_C1F2
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.w	locret_C1F0
		add.w	d1,obY(a0)
		clr.w	obVelY(a0)
		clr.b	ob2ndRout(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0
		blo.s	locret_C1F0
		move.w	$30(a0),d0
		asr.w	#3,d0
		move.w	d0,obVelX(a0)
		move.b	#1,$32(a0)
		clr.w	obY+2(a0)

locret_C1F0:
		rts
; ===========================================================================

loc_C1F2:
		bsr.w	SpeedToPos
		move.w	obX(a0),d0
		andi.w	#$C,d0
		bne.w	locret_C2E4
		andi.w	#-$10,obX(a0)
		move.w	obVelX(a0),$30(a0)
		clr.w	obVelX(a0)
		subq.b	#2,ob2ndRout(a0)
		rts
; ===========================================================================

loc_C218:
		bsr.w	Solid_ChkEnter
		tst.w	d4
		beq.w	locret_C2E4
		bmi.w	locret_C2E4
		tst.b	$32(a0)
		beq.s	loc_C230
		bra.w	locret_C2E4
; ===========================================================================

loc_C230:
		tst.w	d0
		beq.w	locret_C2E4
		bmi.s	loc_C268
		btst	#0,obStatus(a1)
		bne.w	locret_C2E4
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	obActWid(a0),d3
		jsr	(ObjHitWallRight).l
		move.w	(sp)+,d0
		tst.w	d1
		bmi.w	locret_C2E4
		addi.l	#$10000,obX(a0)
		moveq	#1,d0
		move.w	#$40,d1
		bra.s	loc_C294
; ===========================================================================

loc_C268:
		btst	#0,obStatus(a1)
		beq.s	locret_C2E4
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	obActWid(a0),d3
		not.w	d3
		jsr	(ObjHitWallLeft).l
		move.w	(sp)+,d0
		tst.w	d1
		bmi.s	locret_C2E4
		subi.l	#$10000,obX(a0)
		moveq	#-1,d0
		move.w	#-$40,d1

loc_C294:
		lea	(v_player).w,a1
		add.w	d0,obX(a1)
		move.w	d1,obInertia(a1)
		move.w	#0,obVelX(a1)
		move.w	d0,-(sp)
		move.w	#sfx_Push,d0
		jsr	(PlaySound_Special).l	 ; play pushing sound
		move.w	(sp)+,d0
		tst.b	obSubtype(a0)
		bmi.s	locret_C2E4
		move.w	d0,-(sp)
		jsr	(ObjFloorDist).l
		move.w	(sp)+,d0
		cmpi.w	#4,d1
		ble.s	loc_C2E0
		move.w	#$400,obVelX(a0)
		tst.w	d0
		bpl.s	loc_C2D8
		neg.w	obVelX(a0)

loc_C2D8:
		move.b	#6,ob2ndRout(a0)
		bra.s	locret_C2E4
; ===========================================================================

loc_C2E0:
		add.w	d1,obY(a0)

locret_C2E4:
		rts

Map_Push:	include	"_maps\Pushable Blocks.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 34 - zone title cards
; ---------------------------------------------------------------------------

; Obj34:
TitleCard:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Card_Index(pc,d0.w),d1
		jmp	Card_Index(pc,d1.w)
; ===========================================================================
Card_Index:	dc.w Card_CheckSBZ3-Card_Index
		dc.w Card_ChkPos-Card_Index
		dc.w Card_Wait-Card_Index
		dc.w Card_Wait-Card_Index

card_mainX:	equ $30		; position for card to display on
card_finalX:	equ $32		; position for card to finish on
; ===========================================================================

Card_CheckSBZ3:	; Routine 0
		movea.l	a0,a1
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w ; check if level is SBZ 3
		bne.s	Card_CheckFZ
		moveq	#5,d0		; load title card number 5 (SBZ)

	Card_CheckFZ:
		move.w	d0,d2
		cmpi.w	#(id_SBZ<<8)+2,(v_zone).w ; check if level is FZ
		bne.s	Card_LoadConfig
		moveq	#6,d0		; load title card number 6 (FZ)
		moveq	#$B,d2		; use "FINAL" mappings

	Card_LoadConfig:
		lea	(Card_ConData).l,a3
		lsl.w	#4,d0
		adda.w	d0,a3
		lea	(Card_ItemData).l,a2
		moveq	#3,d1

Card_Loop:
		move.b	#id_TitleCard,0(a1)
		move.w	(a3),obX(a1)	; load start x-position
		move.w	(a3)+,card_finalX(a1) ; load finish x-position (same as start)
		move.w	(a3)+,card_mainX(a1) ; load main x-position
		move.w	(a2)+,obScreenY(a1)
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,d0
		bne.s	Card_ActNumber
		move.b	d2,d0

	Card_ActNumber:
		cmpi.b	#7,d0
		bne.s	Card_MakeSprite
		add.b	(v_act).w,d0
		cmpi.b	#3,(v_act).w
		bne.s	Card_MakeSprite
		subq.b	#1,d0

	Card_MakeSprite:
		move.b	d0,obFrame(a1)	; display frame number d0
		move.l	#Map_Card,obMap(a1)
		move.w	#$8580,obGfx(a1)
		move.b	#$78,obActWid(a1)
		move.b	#0,obRender(a1)
		move.b	#0,obPriority(a1)
		move.w	#60,obTimeFrame(a1) ; set time delay to 1 second
		lea	$40(a1),a1	; next object
		dbf	d1,Card_Loop	; repeat sequence another 3 times

Card_ChkPos:	; Routine 2
		moveq	#$10,d1		; set horizontal speed
		move.w	card_mainX(a0),d0
		cmp.w	obX(a0),d0	; has item reached the target position?
		beq.s	Card_NoMove	; if yes, branch
		bge.s	Card_Move
		neg.w	d1

Card_Move:
		add.w	d1,obX(a0)	; change item's position

Card_NoMove:
		move.w	obX(a0),d0
		bmi.s	locret_C3D8
		cmpi.w	#$200,d0	; has item moved beyond $200 on	x-axis?
		bhs.s	locret_C3D8	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C3D8:
		rts
; ===========================================================================

Card_Wait:	; Routine 4/6
		tst.w	obTimeFrame(a0)	; is time remaining zero?
		beq.s	Card_ChkPos2	; if yes, branch
		subq.w	#1,obTimeFrame(a0) ; subtract 1 from time
		bra.w	DisplaySprite
; ===========================================================================

Card_ChkPos2:
		tst.b	obRender(a0)
		bpl.s	Card_ChangeArt
		moveq	#$20,d1
		move.w	card_finalX(a0),d0
		cmp.w	obX(a0),d0	; has item reached the finish position?
		beq.s	Card_ChangeArt	; if yes, branch
		bge.s	Card_Move2
		neg.w	d1

Card_Move2:
		add.w	d1,obX(a0)	; change item's position
		move.w	obX(a0),d0
		bmi.s	locret_C412
		cmpi.w	#$200,d0	; has item moved beyond $200 on	x-axis?
		bhs.s	locret_C412	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C412:
		rts
; ===========================================================================

Card_ChangeArt:
		cmpi.b	#4,obRoutine(a0)
		bne.s	Card_Delete
		moveq	#plcid_Explode,d0
		jsr	(AddPLC).l	; load explosion patterns
		moveq	#0,d0
		move.b	(v_zone).w,d0
		addi.w	#plcid_GHZAnimals,d0
		jsr	(AddPLC).l	; load animal patterns

Card_Delete:
		bra.w	DeleteObject
; ===========================================================================
Card_ItemData:	dc.w $D0	; y-axis position
		dc.b 2,	0	; routine number, frame number (changes)
		dc.w $E4
		dc.b 2,	6
		dc.w $EA
		dc.b 2,	7
		dc.w $E0
		dc.b 2,	$A
; ---------------------------------------------------------------------------
; Title card configuration data
; Format:
; 4 bytes per item (YYYY XXXX)
; 4 items per level (GREEN HILL, ZONE, ACT X, oval)
; ---------------------------------------------------------------------------
Card_ConData:	dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; GHZ
		dc.w 0,	$120, $FEF4, $134, $40C, $14C, $20C, $14C ; LZ
		dc.w 0,	$120, $FEE0, $120, $3F8, $138, $1F8, $138 ; MZ
		dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; SLZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SYZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SBZ
		dc.w 0,	$120, $FEE4, $124, $3EC, $3EC, $1EC, $12C ; FZ
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 39 - "GAME OVER" and "TIME OVER"
; ---------------------------------------------------------------------------

; Obj39:
GameOverCard:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Over_Index(pc,d0.w),d1
		jmp	Over_Index(pc,d1.w)
; ===========================================================================
Over_Index:	dc.w Over_ChkPLC-Over_Index
		dc.w Over_Move-Over_Index
		dc.w Over_Wait-Over_Index
; ===========================================================================

Over_ChkPLC:	; Routine 0
		tst.l	(v_plc_buffer).w ; are the pattern load cues empty?
		beq.s	Over_Main	; if yes, branch
		rts
; ===========================================================================

Over_Main:
		addq.b	#2,obRoutine(a0)
		move.w	#$50,obX(a0)	; set x-position
		btst	#0,obFrame(a0)	; is the object "OVER"?
		beq.s	Over_1stWord	; if not, branch
		move.w	#$1F0,obX(a0)	; set x-position for "OVER"

	Over_1stWord:
		move.w	#$F0,obScreenY(a0)
		move.l	#Map_Over,obMap(a0)
		move.w	#$855E,obGfx(a0)
		move.b	#0,obRender(a0)
		move.b	#0,obPriority(a0)

Over_Move:	; Routine 2
		moveq	#$10,d1		; set horizontal speed
		cmpi.w	#$120,obX(a0)	; has item reached its target position?
		beq.s	Over_SetWait	; if yes, branch
		blo.s	Over_UpdatePos
		neg.w	d1

	Over_UpdatePos:
		add.w	d1,obX(a0)	; change item's position
		bra.w	DisplaySprite
; ===========================================================================

Over_SetWait:
		move.w	#720,obTimeFrame(a0) ; set time delay to 12 seconds
		addq.b	#2,obRoutine(a0)
		rts
; ===========================================================================

Over_Wait:	; Routine 4
		move.b	(v_jpadpress1).w,d0
		andi.b	#btnABC,d0	; is button A, B or C pressed?
		bne.s	Over_ChgMode	; if yes, branch
		btst	#0,obFrame(a0)
		bne.s	Over_Display
		tst.w	obTimeFrame(a0)	; has time delay reached zero?
		beq.s	Over_ChgMode	; if yes, branch
		subq.w	#1,obTimeFrame(a0) ; subtract 1 from time delay
		bra.w	DisplaySprite
; ===========================================================================

Over_ChgMode:
		tst.b	(f_timeover).w	; is time over flag set?
		bne.s	Over_ResetLvl	; if yes, branch
		move.b	#id_Continue,(v_gamemode).w ; set mode to $14 (continue screen)
		tst.b	(v_continues).w	; do you have any continues?
		bne.s	Over_Display	; if yes, branch
		move.b	#id_Sega,(v_gamemode).w ; set mode to 0 (Sega screen)
		bra.s	Over_Display
; ===========================================================================

Over_ResetLvl:
		clr.l	(v_lamp_time).w
		move.w	#1,(f_restart).w ; restart level

Over_Display:
		bra.w	DisplaySprite

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3A - "SONIC GOT THROUGH" title card
; ---------------------------------------------------------------------------

; Obj3A:
GotThroughCard:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Got_Index(pc,d0.w),d1
		jmp	Got_Index(pc,d1.w)
; ===========================================================================
Got_Index:	dc.w Got_ChkPLC-Got_Index
		dc.w Got_Move-Got_Index
		dc.w Got_Wait-Got_Index
		dc.w Got_TimeBonus-Got_Index
		dc.w Got_Wait-Got_Index
		dc.w Got_NextLevel-Got_Index
		dc.w Got_Wait-Got_Index
		dc.w Got_Move2-Got_Index
		dc.w loc_C766-Got_Index

got_mainX:	equ $30		; position for card to display on
got_finalX:	equ $32		; position for card to finish on
; ===========================================================================

Got_ChkPLC:	; Routine 0
		tst.l	(v_plc_buffer).w ; are the pattern load cues empty?
		beq.s	Got_Main	; if yes, branch
		rts
; ===========================================================================

Got_Main:
		movea.l	a0,a1
		lea	(Got_Config).l,a2
		moveq	#6,d1

Got_Loop:
		move.b	#id_GotThroughCard,0(a1)
		move.w	(a2),obX(a1)	; load start x-position
		move.w	(a2)+,got_finalX(a1) ; load finish x-position (same as start)
		move.w	(a2)+,got_mainX(a1) ; load main x-position
		move.w	(a2)+,obScreenY(a1) ; load y-position
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,d0
		cmpi.b	#6,d0
		bne.s	loc_C5CA
		add.b	(v_act).w,d0	; add act number to frame number

	loc_C5CA:
		move.b	d0,obFrame(a1)
		move.l	#Map_Got,obMap(a1)
		move.w	#$8580,obGfx(a1)
		move.b	#0,obRender(a1)
		lea	$40(a1),a1
		dbf	d1,Got_Loop	; repeat 6 times

Got_Move:	; Routine 2
		moveq	#$10,d1		; set horizontal speed
		move.w	got_mainX(a0),d0
		cmp.w	obX(a0),d0	; has item reached its target position?
		beq.s	loc_C61A	; if yes, branch
		bge.s	Got_ChgPos
		neg.w	d1

	Got_ChgPos:
		add.w	d1,obX(a0)	; change item's position

	loc_C5FE:
		move.w	obX(a0),d0
		bmi.s	locret_C60E
		cmpi.w	#$200,d0	; has item moved beyond $200 on	x-axis?
		bhs.s	locret_C60E	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C60E:
		rts
; ===========================================================================

loc_C610:
		move.b	#$E,obRoutine(a0)
		bra.w	Got_Move2
; ===========================================================================

loc_C61A:
		cmpi.b	#$E,(v_endcardring+obRoutine).w
		beq.s	loc_C610
		cmpi.b	#4,obFrame(a0)
		bne.s	loc_C5FE
		addq.b	#2,obRoutine(a0)
		move.w	#180,obTimeFrame(a0) ; set time delay to 3 seconds

Got_Wait:	; Routine 4, 8, $C
		subq.w	#1,obTimeFrame(a0) ; subtract 1 from time delay
		bne.s	Got_Display
		addq.b	#2,obRoutine(a0)

Got_Display:
		bra.w	DisplaySprite
; ===========================================================================

Got_TimeBonus:	; Routine 6
		bsr.w	DisplaySprite
		move.b	#1,(f_endactbonus).w ; set time/ring bonus update flag
		moveq	#0,d0
		tst.w	(v_timebonus).w	; is time bonus = zero?
		beq.s	Got_RingBonus	; if yes, branch
		addi.w	#10,d0		; add 10 to score
		subi.w	#10,(v_timebonus).w ; subtract 10 from time bonus

Got_RingBonus:
		tst.w	(v_ringbonus).w	; is ring bonus = zero?
		beq.s	Got_ChkBonus	; if yes, branch
		addi.w	#10,d0		; add 10 to score
		subi.w	#10,(v_ringbonus).w ; subtract 10 from ring bonus

Got_ChkBonus:
		tst.w	d0		; is there any bonus?
		bne.s	Got_AddBonus	; if yes, branch
		move.w	#sfx_Cash,d0
		jsr	(PlaySound_Special).l	; play "ker-ching" sound
		addq.b	#2,obRoutine(a0)
		cmpi.w	#(id_SBZ<<8)+1,(v_zone).w
		bne.s	Got_SetDelay
		addq.b	#4,obRoutine(a0)

Got_SetDelay:
		move.w	#180,obTimeFrame(a0) ; set time delay to 3 seconds

locret_C692:
		rts
; ===========================================================================

Got_AddBonus:
		jsr	(AddPoints).l
		move.b	(v_vbla_byte).w,d0
		andi.b	#3,d0
		bne.s	locret_C692
		move.w	#sfx_Switch,d0
		jmp	(PlaySound_Special).l	; play "blip" sound
; ===========================================================================

Got_NextLevel:	; Routine $A
		move.b	(v_zone).w,d0
		andi.w	#7,d0
		lsl.w	#3,d0
		move.b	(v_act).w,d1
		andi.w	#3,d1
		add.w	d1,d1
		add.w	d1,d0
		move.w	LevelOrder(pc,d0.w),d0 ; load level from level order array
		move.w	d0,(v_zone).w	; set level number
		tst.w	d0
		bne.s	Got_ChkSS
		move.b	#id_Sega,(v_gamemode).w
		bra.s	Got_Display2
; ===========================================================================

Got_ChkSS:
		clr.b	(v_lastlamp).w	; clear lamppost counter
		tst.b	(f_bigring).w	; has Sonic jumped into a giant	ring?
		beq.s	VBla_08A	; if not, branch
		move.b	#id_Special,(v_gamemode).w ; set game mode to Special Stage (10)
		bra.s	Got_Display2
; ===========================================================================

VBla_08A:
		move.w	#1,(f_restart).w ; restart level

Got_Display2:
		bra.w	DisplaySprite
; ===========================================================================
; ---------------------------------------------------------------------------
; Level order array
; ---------------------------------------------------------------------------
LevelOrder:
		; Green Hill Zone
		dc.b id_GHZ, 1	; Act 1
		dc.b id_GHZ, 2	; Act 2
		dc.b id_MZ, 0	; Act 3
		dc.b 0, 0

		; Labyrinth Zone
		dc.b id_LZ, 1	; Act 1
		dc.b id_LZ, 2	; Act 2
		dc.b id_SLZ, 0	; Act 3
		dc.b id_SBZ, 2	; Scrap Brain Zone Act 3

		; Marble Zone
		dc.b id_MZ, 1	; Act 1
		dc.b id_MZ, 2	; Act 2
		dc.b id_SYZ, 0	; Act 3
		dc.b 0, 0

		; Star Light Zone
		dc.b id_SLZ, 1	; Act 1
		dc.b id_SLZ, 2	; Act 2
		dc.b id_SBZ, 0	; Act 3
		dc.b 0, 0

		; Spring Yard Zone
		dc.b id_SYZ, 1	; Act 1
		dc.b id_SYZ, 2	; Act 2
		dc.b id_LZ, 0	; Act 3
		dc.b 0, 0

		; Scrap Brain Zone
		dc.b id_SBZ, 1	; Act 1
		dc.b id_LZ, 3	; Act 2
		dc.b 0, 0	; Final Zone
		dc.b 0, 0
		even
; ===========================================================================

Got_Move2:	; Routine $E
		moveq	#$20,d1		; set horizontal speed
		move.w	got_finalX(a0),d0
		cmp.w	obX(a0),d0	; has item reached its finish position?
		beq.s	Got_SBZ2	; if yes, branch
		bge.s	Got_ChgPos2
		neg.w	d1

	Got_ChgPos2:
		add.w	d1,obX(a0)	; change item's position
		move.w	obX(a0),d0
		bmi.s	locret_C748
		cmpi.w	#$200,d0	; has item moved beyond $200 on	x-axis?
		bhs.s	locret_C748	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C748:
		rts
; ===========================================================================

Got_SBZ2:
		cmpi.b	#4,obFrame(a0)
		bne.w	DeleteObject
		addq.b	#2,obRoutine(a0)
		clr.b	(f_lockctrl).w	; unlock controls
		move.w	#bgm_FZ,d0
		jmp	(PlaySound).l	; play FZ music
; ===========================================================================

loc_C766:	; Routine $10
		addq.w	#2,(v_limitright2).w
		cmpi.w	#$2100,(v_limitright2).w
		beq.w	DeleteObject
		rts
; ===========================================================================
		;    x-start, x-main,	y-main,
		; 			routine, frame number

Got_Config:	dc.w 4,		$124,	$BC			; "SONIC HAS"
		dc.b 				2,	0

		dc.w -$120,	$120,	$D0			; "PASSED"
		dc.b 				2,	1

		dc.w $40C,	$14C,	$D6			; "ACT" 1/2/3
		dc.b 				2,	6

		dc.w $520,	$120,	$EC			; score
		dc.b 				2,	2

		dc.w $540,	$120,	$FC			; time bonus
		dc.b 				2,	3

		dc.w $560,	$120,	$10C			; ring bonus
		dc.b 				2,	4

		dc.w $20C,	$14C,	$CC			; oval
		dc.b 				2,	5

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7E - special stage results screen
; ---------------------------------------------------------------------------

; Obj7E:
SSResult:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	SSR_Index(pc,d0.w),d1
		jmp	SSR_Index(pc,d1.w)
; ===========================================================================
SSR_Index:	dc.w SSR_ChkPLC-SSR_Index
		dc.w SSR_Move-SSR_Index
		dc.w SSR_Wait-SSR_Index
		dc.w SSR_RingBonus-SSR_Index
		dc.w SSR_Wait-SSR_Index
		dc.w SSR_Exit-SSR_Index
		dc.w SSR_Wait-SSR_Index
		dc.w SSR_Continue-SSR_Index
		dc.w SSR_Wait-SSR_Index
		dc.w SSR_Exit-SSR_Index
		dc.w loc_C91A-SSR_Index

ssr_mainX:	equ $30		; position for card to display on
; ===========================================================================

SSR_ChkPLC:	; Routine 0
		tst.l	(v_plc_buffer).w ; are the pattern load cues empty?
		beq.s	SSR_Main	; if yes, branch
		rts
; ===========================================================================

SSR_Main:
		movea.l	a0,a1
		lea	(SSR_Config).l,a2
		moveq	#3,d1
		cmpi.w	#50,(v_rings).w	; do you have 50 or more rings?
		blo.s	SSR_Loop	; if no, branch
		addq.w	#1,d1		; if yes, add 1 to d1 (number of sprites)

	SSR_Loop:
		move.b	#id_SSResult,0(a1)
		move.w	(a2)+,obX(a1)	; load start x-position
		move.w	(a2)+,ssr_mainX(a1) ; load main x-position
		move.w	(a2)+,obScreenY(a1) ; load y-position
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,obFrame(a1)
		move.l	#Map_SSR,obMap(a1)
		move.w	#$8580,obGfx(a1)
		move.b	#0,obRender(a1)
		lea	$40(a1),a1
		dbf	d1,SSR_Loop	; repeat sequence 3 or 4 times

		moveq	#7,d0
		move.b	(v_emeralds).w,d1
		beq.s	loc_C842
		moveq	#0,d0
		cmpi.b	#6,d1		; do you have all chaos emeralds?
		bne.s	loc_C842	; if not, branch
		moveq	#8,d0		; load "Sonic got them all" text
		move.w	#$18,obX(a0)
		move.w	#$118,ssr_mainX(a0) ; change position of text

loc_C842:
		move.b	d0,obFrame(a0)

SSR_Move:	; Routine 2
		moveq	#$10,d1		; set horizontal speed
		move.w	ssr_mainX(a0),d0
		cmp.w	obX(a0),d0	; has item reached its target position?
		beq.s	loc_C86C	; if yes, branch
		bge.s	SSR_ChgPos
		neg.w	d1

SSR_ChgPos:
		add.w	d1,obX(a0)	; change item's position

loc_C85A:
		move.w	obX(a0),d0
		bmi.s	locret_C86A
		cmpi.w	#$200,d0	; has item moved beyond $200 on	x-axis?
		bhs.s	locret_C86A	; if yes, branch
		bra.w	DisplaySprite
; ===========================================================================

locret_C86A:
		rts
; ===========================================================================

loc_C86C:
		cmpi.b	#2,obFrame(a0)
		bne.s	loc_C85A
		addq.b	#2,obRoutine(a0)
		move.w	#180,obTimeFrame(a0) ; set time delay to 3 seconds
		move.b	#id_SSRChaos,(v_ssresemeralds).w ; load chaos emerald object

SSR_Wait:	; Routine 4, 8, $C, $10
		subq.w	#1,obTimeFrame(a0) ; subtract 1 from time delay
		bne.s	SSR_Display
		addq.b	#2,obRoutine(a0)

SSR_Display:
		bra.w	DisplaySprite
; ===========================================================================

SSR_RingBonus:	; Routine 6
		bsr.w	DisplaySprite
		move.b	#1,(f_endactbonus).w ; set ring bonus update flag
		tst.w	(v_ringbonus).w	; is ring bonus = zero?
		beq.s	loc_C8C4	; if yes, branch
		subi.w	#10,(v_ringbonus).w ; subtract 10 from ring bonus
		moveq	#10,d0		; add 10 to score
		jsr	(AddPoints).l
		move.b	(v_vbla_byte).w,d0
		andi.b	#3,d0
		bne.s	locret_C8EA
		move.w	#sfx_Switch,d0
		jmp	(PlaySound_Special).l	; play "blip" sound
; ===========================================================================

loc_C8C4:
		move.w	#sfx_Cash,d0
		jsr	(PlaySound_Special).l	; play "ker-ching" sound
		addq.b	#2,obRoutine(a0)
		move.w	#180,obTimeFrame(a0) ; set time delay to 3 seconds
		cmpi.w	#50,(v_rings).w	; do you have at least 50 rings?
		blo.s	locret_C8EA	; if not, branch
		move.w	#60,obTimeFrame(a0) ; set time delay to 1 second
		addq.b	#4,obRoutine(a0) ; goto "SSR_Continue" routine

locret_C8EA:
		rts
; ===========================================================================

SSR_Exit:	; Routine $A, $12
		move.w	#1,(f_restart).w ; restart level
		bra.w	DisplaySprite
; ===========================================================================

SSR_Continue:	; Routine $E
		move.b	#4,(v_ssrescontinue+obFrame).w
		move.b	#$14,(v_ssrescontinue+obRoutine).w
		move.w	#sfx_Continue,d0
		jsr	(PlaySound_Special).l	; play continues jingle
		addq.b	#2,obRoutine(a0)
		move.w	#360,obTimeFrame(a0) ; set time delay to 6 seconds
		bra.w	DisplaySprite
; ===========================================================================

loc_C91A:	; Routine $14
		move.b	(v_vbla_byte).w,d0
		andi.b	#$F,d0
		bne.s	SSR_Display2
		bchg	#0,obFrame(a0)

SSR_Display2:
		bra.w	DisplaySprite
; ===========================================================================
SSR_Config:	dc.w $20, $120,	$C4	; start x-pos, main x-pos, y-pos
		dc.b 2,	0		; rountine number, frame number
		dc.w $320, $120, $118
		dc.b 2,	1
		dc.w $360, $120, $128
		dc.b 2,	2
		dc.w $1EC, $11C, $C4
		dc.b 2,	3
		dc.w $3A0, $120, $138
		dc.b 2,	6

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7F - chaos emeralds from the special stage results screen
; ---------------------------------------------------------------------------

; Obj7F:
SSRChaos:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	SSRC_Index(pc,d0.w),d1
		jmp	SSRC_Index(pc,d1.w)
; ===========================================================================
SSRC_Index:	dc.w SSRC_Main-SSRC_Index
		dc.w SSRC_Flash-SSRC_Index

; ---------------------------------------------------------------------------
; X-axis positions for chaos emeralds
; ---------------------------------------------------------------------------
SSRC_PosData:	dc.w $110, $128, $F8, $140, $E0, $158
; ===========================================================================

SSRC_Main:	; Routine 0
		movea.l	a0,a1
		lea	(SSRC_PosData).l,a2
		moveq	#0,d2
		moveq	#0,d1
		move.b	(v_emeralds).w,d1 ; d1 is number of emeralds
		subq.b	#1,d1		; subtract 1 from d1
		blo.w	DeleteObject	; if you have 0 emeralds, branch

	SSRC_Loop:
		move.b	#id_SSRChaos,0(a1)
		move.w	(a2)+,obX(a1)	; set x-position
		move.w	#$F0,obScreenY(a1) ; set y-position
		lea	(v_emldlist).w,a3 ; check which emeralds you have
		move.b	(a3,d2.w),d3
		move.b	d3,obFrame(a1)
		move.b	d3,obAnim(a1)
		addq.b	#1,d2
		addq.b	#2,obRoutine(a1)
		move.l	#Map_SSRC,obMap(a1)
		move.w	#$8541,obGfx(a1)
		move.b	#0,obRender(a1)
		lea	$40(a1),a1	; next object
		dbf	d1,SSRC_Loop	; loop for d1 number of emeralds

SSRC_Flash:	; Routine 2
		move.b	obFrame(a0),d0
		move.b	#6,obFrame(a0)	; load 6th frame (blank)
		cmpi.b	#6,d0
		bne.s	SSRC_Display
		move.b	obAnim(a0),obFrame(a0) ; load visible frame

	SSRC_Display:
		bra.w	DisplaySprite

; ---------------------------------------------------------------------------
; Sprite mappings - title cards
; ---------------------------------------------------------------------------
Map_Card:	include	"_maps\Title Cards - Levels.asm"
Map_Over:	include	"_maps\Title Cards - Game Over.asm"
Map_Got:	include	"_maps\Title Cards - Passed.asm"
Map_SSR:	include	"_maps\Title Cards - Special Results.asm"

Map_SSRC:	include	"_maps\SS Result Chaos Emeralds.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 36 - spikes
; ---------------------------------------------------------------------------

; Obj36:
Spikes:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Spik_Index(pc,d0.w),d1
		jmp	Spik_Index(pc,d1.w)
; ===========================================================================
Spik_Index:	dc.w Spik_Main-Spik_Index
		dc.w Spik_Solid-Spik_Index

spik_origX:	equ $30		; start X position
spik_origY:	equ $32		; start Y position

Spik_Var:	dc.b 0,	$14		; frame number,	object width
		dc.b 1,	$10
		dc.b 2,	4
		dc.b 3,	$1C
		dc.b 4,	$40
		dc.b 5,	$10
; ===========================================================================

Spik_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Spike,obMap(a0)
		move.w	#$51B,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	obSubtype(a0),d0
		andi.b	#$F,obSubtype(a0)
		andi.w	#$F0,d0
		lea	(Spik_Var).l,a1
		lsr.w	#3,d0
		adda.w	d0,a1
		move.b	(a1)+,obFrame(a0)
		move.b	(a1)+,obActWid(a0)
		move.w	obX(a0),spik_origX(a0)
		move.w	obY(a0),spik_origY(a0)

Spik_Solid:	; Routine 2
		bsr.w	Spik_Type0x	; make the object move
		move.w	#4,d2
		cmpi.b	#5,obFrame(a0)	; is object type $5x ?
		beq.s	Spik_SideWays	; if yes, branch
		cmpi.b	#1,obFrame(a0)	; is object type $1x ?
		bne.s	Spik_Upright	; if not, branch
		move.w	#$14,d2

; Spikes types $1x and $5x face sideways

Spik_SideWays:
		move.w	#$1B,d1
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		btst	#3,obStatus(a0)
		bne.s	Spik_Display
		cmpi.w	#1,d4
		beq.s	Spik_Hurt
		bra.s	Spik_Display
; ===========================================================================

; Spikes types $0x, $2x, $3x and $4x face up or down

Spik_Upright:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		btst	#3,obStatus(a0)
		bne.s	Spik_Hurt
		tst.w	d4
		bpl.s	Spik_Display

; Obj36_Hurt:
Spik_Hurt:
		tst.b	(v_invinc).w	; is Sonic invincible?
		bne.s	Spik_Display	; if yes, branch
		move.l	a0,-(sp)
		movea.l	a0,a2
		lea	(v_player).w,a0
		cmpi.b	#4,obRoutine(a0)
		bhs.s	loc_CF20
		move.l	obY(a0),d3
		move.w	obVelY(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,obY(a0)
		jsr	(HurtSonic).l

loc_CF20:
		movea.l	(sp)+,a0

Spik_Display:
		bsr.w	DisplaySprite
		out_of_range.w	DeleteObject,spik_origX(a0)
		rts
; ===========================================================================

Spik_Type0x:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	Spik_TypeIndex(pc,d0.w),d1
		jmp	Spik_TypeIndex(pc,d1.w)
; ===========================================================================
Spik_TypeIndex:	dc.w Spik_Type00-Spik_TypeIndex
		dc.w Spik_Type01-Spik_TypeIndex
		dc.w Spik_Type02-Spik_TypeIndex
; ===========================================================================

Spik_Type00:
		rts			; don't move the object
; ===========================================================================

Spik_Type01:
		bsr.w	Spik_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	spik_origY(a0),d0
		move.w	d0,obY(a0)	; move the object vertically
		rts
; ===========================================================================

Spik_Type02:
		bsr.w	Spik_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	spik_origX(a0),d0
		move.w	d0,obX(a0)	; move the object horizontally
		rts
; ===========================================================================

Spik_Wait:
		tst.w	$38(a0)		; is time delay = zero?
		beq.s	loc_CFA4	; if yes, branch
		subq.w	#1,$38(a0)	; subtract 1 from time delay
		bne.s	locret_CFE6
		tst.b	obRender(a0)
		bpl.s	locret_CFE6
		move.w	#sfx_SpikesMove,d0
		jsr	(PlaySound_Special).l	; play "spikes moving" sound
		bra.s	locret_CFE6
; ===========================================================================

loc_CFA4:
		tst.w	$36(a0)
		beq.s	loc_CFC6
		subi.w	#$800,$34(a0)
		bhs.s	locret_CFE6
		move.w	#0,$34(a0)
		move.w	#0,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second
		bra.s	locret_CFE6
; ===========================================================================

loc_CFC6:
		addi.w	#$800,$34(a0)
		cmpi.w	#$2000,$34(a0)
		blo.s	locret_CFE6
		move.w	#$2000,$34(a0)
		move.w	#1,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second

locret_CFE6:
		rts

Map_Spike:	include	"_maps\Spikes.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3B - purple rock (GHZ)
; ---------------------------------------------------------------------------

; Obj3B:
PurpleRock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Rock_Index(pc,d0.w),d1
		jmp	Rock_Index(pc,d1.w)
; ===========================================================================
Rock_Index:	dc.w Rock_Main-Rock_Index
		dc.w Rock_Solid-Rock_Index
; ===========================================================================

Rock_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_PRock,obMap(a0)
		move.w	#$63D0,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$13,obActWid(a0)
		move.b	#4,obPriority(a0)

Rock_Solid:	; Routine 2
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		bsr.w	DisplaySprite
		out_of_range.w	DeleteObject
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 49 - waterfall sound effect (GHZ)
; ---------------------------------------------------------------------------

; Obj49:
WaterSound:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	WSnd_Index(pc,d0.w),d1
		jmp	WSnd_Index(pc,d1.w)
; ===========================================================================
WSnd_Index:	dc.w WSnd_Main-WSnd_Index
		dc.w WSnd_PlaySnd-WSnd_Index
; ===========================================================================

WSnd_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#4,obRender(a0)

WSnd_PlaySnd:	; Routine 2
		move.b	(v_vbla_byte).w,d0 ; get low byte of VBlank counter
		andi.b	#$3F,d0
		bne.s	WSnd_ChkDel
		move.w	#sfx_Waterfall,d0
		jsr	(PlaySound_Special).l	; play waterfall sound

	WSnd_ChkDel:
		out_of_range.w	DeleteObject
		rts

Map_PRock:	include	"_maps\Purple Rock.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3C - smashable wall (GHZ, SLZ)
; ---------------------------------------------------------------------------

; Obj3C:
SmashWall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Smash_Index(pc,d0.w),d1
		jsr	Smash_Index(pc,d1.w)
		bra.w	RememberState
; ===========================================================================
Smash_Index:	dc.w Smash_Main-Smash_Index
		dc.w Smash_Solid-Smash_Index
		dc.w Smash_FragMove-Smash_Index

smash_speed:	equ $30		; Sonic's horizontal speed
; ===========================================================================

Smash_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Smash,obMap(a0)
		move.w	#$450F,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)
		move.b	obSubtype(a0),obFrame(a0)

Smash_Solid:	; Routine 2
		move.w	(v_player+obVelX).w,smash_speed(a0) ; load Sonic's horizontal speed
		move.w	#$1B,d1
		move.w	#$20,d2
		move.w	#$20,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		btst	#5,obStatus(a0)	; is Sonic pushing against the wall?
		bne.s	@chkroll	; if yes, branch

@donothing:
		rts
; ===========================================================================

@chkroll:
		cmpi.b	#id_Roll,obAnim(a1) ; is Sonic rolling?
		bne.s	@donothing	; if not, branch
		move.w	smash_speed(a0),d0
		bpl.s	@chkspeed
		neg.w	d0

	@chkspeed:
		cmpi.w	#$480,d0	; is Sonic's speed $480 or higher?
		blo.s	@donothing	; if not, branch
		move.w	smash_speed(a0),obVelX(a1)
		addq.w	#4,obX(a1)
		lea	(Smash_FragSpd1).l,a4 ; use fragments that move	right
		move.w	obX(a0),d0
		cmp.w	obX(a1),d0	; is Sonic to the right of the block?
		blo.s	@smash		; if yes, branch
		subq.w	#8,obX(a1)
		lea	(Smash_FragSpd2).l,a4 ; use fragments that move	left

	@smash:
		move.w	obVelX(a1),obInertia(a1)
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)
		moveq	#7,d1		; load 8 fragments
		move.w	#$70,d2
		bsr.s	SmashObject

Smash_FragMove:	; Routine 4
		bsr.w	SpeedToPos
		addi.w	#$70,obVelY(a0)	; make fragment fall faster
		bsr.w	DisplaySprite
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		rts

; ---------------------------------------------------------------------------
; Subroutine to smash a	block (GHZ walls and MZ	blocks)
; ---------------------------------------------------------------------------

SmashObject:
		moveq	#0,d0
		move.b	obFrame(a0),d0
		add.w	d0,d0
		movea.l	obMap(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,obRender(a0)
		move.b	0(a0),d4
		move.b	obRender(a0),d5
		movea.l	a0,a1
		bra.s	@loadfrag
; ===========================================================================

	@loop:
		bsr.w	FindFreeObj
		bne.s	@playsnd
		addq.w	#5,a3

@loadfrag:
		move.b	#4,obRoutine(a1)
		move.b	d4,0(a1)
		move.l	a3,obMap(a1)
		move.b	d5,obRender(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	obGfx(a0),obGfx(a1)
		move.b	obPriority(a0),obPriority(a1)
		move.b	obActWid(a0),obActWid(a1)
		move.w	(a4)+,obVelX(a1)
		move.w	(a4)+,obVelY(a1)
		cmpa.l	a0,a1
		bhs.s	@loc_D268
		move.l	a0,-(sp)
		movea.l	a1,a0
		bsr.w	SpeedToPos
		add.w	d2,obVelY(a0)
		movea.l	(sp)+,a0
		bsr.w	DisplaySprite1

	@loc_D268:
		dbf	d1,@loop

	@playsnd:
		move.w	#sfx_WallSmash,d0
		jmp	(PlaySound_Special).l ; play smashing sound

; End of function SmashObject
; ===========================================================================
; Smashed block fragment speeds
;
Smash_FragSpd1:	dc.w $400, -$500	; x-move speed, y-move speed
		dc.w $600, -$100
		dc.w $600, $100
		dc.w $400, $500
		dc.w $600, -$600
		dc.w $800, -$200
		dc.w $800, $200
		dc.w $600, $600

Smash_FragSpd2:	dc.w -$600, -$600
		dc.w -$800, -$200
		dc.w -$800, $200
		dc.w -$600, $600
		dc.w -$400, -$500
		dc.w -$600, -$100
		dc.w -$600, $100
		dc.w -$400, $500

Map_Smash:	include	"_maps\Smashable Walls.asm"

; ---------------------------------------------------------------------------
; Object code execution subroutine
; ---------------------------------------------------------------------------

; ObjectsLoad:
ExecuteObjects:
		lea	(v_objspace).w,a0 ; set address for object RAM
		moveq	#$7F,d7
		moveq	#0,d0
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	loc_D362

loc_D348:
		move.b	(a0),d0		; load object number from RAM
		beq.s	loc_D358
		add.w	d0,d0
		add.w	d0,d0
		movea.l	Obj_Index-4(pc,d0.w),a1
		jsr	(a1)		; run the object's code
		moveq	#0,d0

loc_D358:
		lea	$40(a0),a0	; next object
		dbf	d7,loc_D348
		rts
; ===========================================================================

loc_D362:
		moveq	#$1F,d7
		bsr.s	loc_D348
		moveq	#$5F,d7

loc_D368:
		moveq	#0,d0
		move.b	(a0),d0
		beq.s	loc_D378
		tst.b	obRender(a0)
		bpl.s	loc_D378
		bsr.w	DisplaySprite

loc_D378:
		lea	$40(a0),a0

loc_D37C:
		dbf	d7,loc_D368
		rts
; End of function ExecuteObjects

; ===========================================================================
; ---------------------------------------------------------------------------
; Object pointers
; ---------------------------------------------------------------------------
Obj_Index:
ptr_SonicPlayer:	dc.l SonicPlayer	; $01
ptr_Obj02:		dc.l NullObject
ptr_Obj03:		dc.l NullObject
ptr_Obj04:		dc.l NullObject
ptr_Obj05:		dc.l NullObject
ptr_Obj06:		dc.l NullObject
ptr_Obj07:		dc.l NullObject
ptr_Splash:		dc.l Splash		; $08
ptr_SonicSpecial:	dc.l SonicSpecial
ptr_DrownCount:		dc.l DrownCount
ptr_Pole:		dc.l Pole
ptr_FlapDoor:		dc.l FlapDoor
ptr_Signpost:		dc.l Signpost
ptr_TitleSonic:		dc.l TitleSonic
ptr_PSBTM:		dc.l PSBTM
ptr_Obj10:		dc.l Obj10		; $10
ptr_Bridge:		dc.l Bridge
ptr_SpinningLight:	dc.l SpinningLight
ptr_LavaMaker:		dc.l LavaMaker
ptr_LavaBall:		dc.l LavaBall
ptr_SwingingPlatform:	dc.l SwingingPlatform
ptr_Harpoon:		dc.l Harpoon
ptr_Helix:		dc.l Helix
ptr_BasicPlatform:	dc.l BasicPlatform	; $18
ptr_Obj19:		dc.l Obj19
ptr_CollapseLedge:	dc.l CollapseLedge
ptr_WaterSurface:	dc.l WaterSurface
ptr_Scenery:		dc.l Scenery
ptr_MagicSwitch:	dc.l MagicSwitch
ptr_BallHog:		dc.l BallHog
ptr_Crabmeat:		dc.l Crabmeat
ptr_Cannonball:		dc.l Cannonball		; $20
ptr_HUD:		dc.l HUD
ptr_BuzzBomber:		dc.l BuzzBomber
ptr_Missile:		dc.l Missile
ptr_MissileDissolve:	dc.l MissileDissolve
ptr_Rings:		dc.l Rings
ptr_Monitor:		dc.l Monitor
ptr_ExplosionItem:	dc.l ExplosionItem
ptr_Animals:		dc.l Animals		; $28
ptr_Points:		dc.l Points
ptr_AutoDoor:		dc.l AutoDoor
ptr_Chopper:		dc.l Chopper
ptr_Jaws:		dc.l Jaws
ptr_Burrobot:		dc.l Burrobot
ptr_PowerUp:		dc.l PowerUp
ptr_LargeGrass:		dc.l LargeGrass
ptr_GlassBlock:		dc.l GlassBlock		; $30
ptr_ChainStomp:		dc.l ChainStomp
ptr_Button:		dc.l Button
ptr_PushBlock:		dc.l PushBlock
ptr_TitleCard:		dc.l TitleCard
ptr_GrassFire:		dc.l GrassFire
ptr_Spikes:		dc.l Spikes
ptr_RingLoss:		dc.l RingLoss
ptr_ShieldItem:		dc.l ShieldItem		; $38
ptr_GameOverCard:	dc.l GameOverCard
ptr_GotThroughCard:	dc.l GotThroughCard
ptr_PurpleRock:		dc.l PurpleRock
ptr_SmashWall:		dc.l SmashWall
ptr_BossGreenHill:	dc.l BossGreenHill
ptr_Prison:		dc.l Prison
ptr_ExplosionBomb:	dc.l ExplosionBomb
ptr_MotoBug:		dc.l MotoBug		; $40
ptr_Springs:		dc.l Springs
ptr_Newtron:		dc.l Newtron
ptr_Roller:		dc.l Roller
ptr_EdgeWalls:		dc.l EdgeWalls
ptr_SideStomp:		dc.l SideStomp
ptr_MarbleBrick:	dc.l MarbleBrick
ptr_Bumper:		dc.l Bumper
ptr_BossBall:		dc.l BossBall		; $48
ptr_WaterSound:		dc.l WaterSound
ptr_VanishSonic:	dc.l VanishSonic
ptr_GiantRing:		dc.l GiantRing
ptr_GeyserMaker:	dc.l GeyserMaker
ptr_LavaGeyser:		dc.l LavaGeyser
ptr_LavaWall:		dc.l LavaWall
ptr_Obj4F:		dc.l Obj4F
ptr_Yadrin:		dc.l Yadrin		; $50
ptr_SmashBlock:		dc.l SmashBlock
ptr_MovingBlock:	dc.l MovingBlock
ptr_CollapseFloor:	dc.l CollapseFloor
ptr_LavaTag:		dc.l LavaTag
ptr_Basaran:		dc.l Basaran
ptr_FloatingBlock:	dc.l FloatingBlock
ptr_SpikeBall:		dc.l SpikeBall
ptr_BigSpikeBall:	dc.l BigSpikeBall	; $58
ptr_Elevator:		dc.l Elevator
ptr_CirclingPlatform:	dc.l CirclingPlatform
ptr_Staircase:		dc.l Staircase
ptr_Pylon:		dc.l Pylon
ptr_Fan:		dc.l Fan
ptr_Seesaw:		dc.l Seesaw
ptr_Bomb:		dc.l Bomb
ptr_Orbinaut:		dc.l Orbinaut		; $60
ptr_LabyrinthBlock:	dc.l LabyrinthBlock
ptr_Gargoyle:		dc.l Gargoyle
ptr_LabyrinthConvey:	dc.l LabyrinthConvey
ptr_Bubble:		dc.l Bubble
ptr_Waterfall:		dc.l Waterfall
ptr_Junction:		dc.l Junction
ptr_RunningDisc:	dc.l RunningDisc
ptr_Conveyor:		dc.l Conveyor		; $68
ptr_SpinPlatform:	dc.l SpinPlatform
ptr_Saws:		dc.l Saws
ptr_ScrapStomp:		dc.l ScrapStomp
ptr_VanishPlatform:	dc.l VanishPlatform
ptr_Flamethrower:	dc.l Flamethrower
ptr_Electro:		dc.l Electro
ptr_SpinConvey:		dc.l SpinConvey
ptr_Girder:		dc.l Girder		; $70
ptr_Invisibarrier:	dc.l Invisibarrier
ptr_Teleport:		dc.l Teleport
ptr_BossMarble:		dc.l BossMarble
ptr_BossFire:		dc.l BossFire
ptr_BossSpringYard:	dc.l BossSpringYard
ptr_BossBlock:		dc.l BossBlock
ptr_BossLabyrinth:	dc.l BossLabyrinth
ptr_Caterkiller:	dc.l Caterkiller	; $78
ptr_Lamppost:		dc.l Lamppost
ptr_BossStarLight:	dc.l BossStarLight
ptr_BossSpikeball:	dc.l BossSpikeball
ptr_RingFlash:		dc.l RingFlash
ptr_HiddenBonus:	dc.l HiddenBonus
ptr_SSResult:		dc.l SSResult
ptr_SSRChaos:		dc.l SSRChaos
ptr_ContScrItem:	dc.l ContScrItem	; $80
ptr_ContSonic:		dc.l ContSonic
ptr_ScrapEggman:	dc.l ScrapEggman
ptr_FalseFloor:		dc.l FalseFloor
ptr_EggmanCylinder:	dc.l EggmanCylinder
ptr_BossFinal:		dc.l BossFinal
ptr_BossPlasma:		dc.l BossPlasma
ptr_EndSonic:		dc.l EndSonic
ptr_EndChaos:		dc.l EndChaos		; $88
ptr_EndSTH:		dc.l EndSTH
ptr_CreditsText:	dc.l CreditsText
ptr_EndEggman:		dc.l EndEggman
ptr_TryChaos:		dc.l TryChaos

NullObject:
		;jmp (DeleteObject).l	; It would be safer to have this instruction here, but instead it just falls through to ObjectFall

id_SonicPlayer:		equ ((ptr_SonicPlayer-Obj_Index)/4)+1		; $01
id_Obj02:		equ ((ptr_Obj02-Obj_Index)/4)+1
id_Obj03:		equ ((ptr_Obj03-Obj_Index)/4)+1
id_Obj04:		equ ((ptr_Obj04-Obj_Index)/4)+1
id_Obj05:		equ ((ptr_Obj05-Obj_Index)/4)+1
id_Obj06:		equ ((ptr_Obj06-Obj_Index)/4)+1
id_Obj07:		equ ((ptr_Obj07-Obj_Index)/4)+1
id_Splash:		equ ((ptr_Splash-Obj_Index)/4)+1		; $08
id_SonicSpecial:	equ ((ptr_SonicSpecial-Obj_Index)/4)+1
id_DrownCount:		equ ((ptr_DrownCount-Obj_Index)/4)+1
id_Pole:		equ ((ptr_Pole-Obj_Index)/4)+1
id_FlapDoor:		equ ((ptr_FlapDoor-Obj_Index)/4)+1
id_Signpost:		equ ((ptr_Signpost-Obj_Index)/4)+1
id_TitleSonic:		equ ((ptr_TitleSonic-Obj_Index)/4)+1
id_PSBTM:		equ ((ptr_PSBTM-Obj_Index)/4)+1
id_Obj10:		equ ((ptr_Obj10-Obj_Index)/4)+1			; $10
id_Bridge:		equ ((ptr_Bridge-Obj_Index)/4)+1
id_SpinningLight:	equ ((ptr_SpinningLight-Obj_Index)/4)+1
id_LavaMaker:		equ ((ptr_LavaMaker-Obj_Index)/4)+1
id_LavaBall:		equ ((ptr_LavaBall-Obj_Index)/4)+1
id_SwingingPlatform:	equ ((ptr_SwingingPlatform-Obj_Index)/4)+1
id_Harpoon:		equ ((ptr_Harpoon-Obj_Index)/4)+1
id_Helix:		equ ((ptr_Helix-Obj_Index)/4)+1
id_BasicPlatform:	equ ((ptr_BasicPlatform-Obj_Index)/4)+1		; $18
id_Obj19:		equ ((ptr_Obj19-Obj_Index)/4)+1
id_CollapseLedge:	equ ((ptr_CollapseLedge-Obj_Index)/4)+1
id_WaterSurface:	equ ((ptr_WaterSurface-Obj_Index)/4)+1
id_Scenery:		equ ((ptr_Scenery-Obj_Index)/4)+1
id_MagicSwitch:		equ ((ptr_MagicSwitch-Obj_Index)/4)+1
id_BallHog:		equ ((ptr_BallHog-Obj_Index)/4)+1
id_Crabmeat:		equ ((ptr_Crabmeat-Obj_Index)/4)+1
id_Cannonball:		equ ((ptr_Cannonball-Obj_Index)/4)+1		; $20
id_HUD:			equ ((ptr_HUD-Obj_Index)/4)+1
id_BuzzBomber:		equ ((ptr_BuzzBomber-Obj_Index)/4)+1
id_Missile:		equ ((ptr_Missile-Obj_Index)/4)+1
id_MissileDissolve:	equ ((ptr_MissileDissolve-Obj_Index)/4)+1
id_Rings:		equ ((ptr_Rings-Obj_Index)/4)+1
id_Monitor:		equ ((ptr_Monitor-Obj_Index)/4)+1
id_ExplosionItem:	equ ((ptr_ExplosionItem-Obj_Index)/4)+1
id_Animals:		equ ((ptr_Animals-Obj_Index)/4)+1		; $28
id_Points:		equ ((ptr_Points-Obj_Index)/4)+1
id_AutoDoor:		equ ((ptr_AutoDoor-Obj_Index)/4)+1
id_Chopper:		equ ((ptr_Chopper-Obj_Index)/4)+1
id_Jaws:		equ ((ptr_Jaws-Obj_Index)/4)+1
id_Burrobot:		equ ((ptr_Burrobot-Obj_Index)/4)+1
id_PowerUp:		equ ((ptr_PowerUp-Obj_Index)/4)+1
id_LargeGrass:		equ ((ptr_LargeGrass-Obj_Index)/4)+1
id_GlassBlock:		equ ((ptr_GlassBlock-Obj_Index)/4)+1		; $30
id_ChainStomp:		equ ((ptr_ChainStomp-Obj_Index)/4)+1
id_Button:		equ ((ptr_Button-Obj_Index)/4)+1
id_PushBlock:		equ ((ptr_PushBlock-Obj_Index)/4)+1
id_TitleCard:		equ ((ptr_TitleCard-Obj_Index)/4)+1
id_GrassFire:		equ ((ptr_GrassFire-Obj_Index)/4)+1
id_Spikes:		equ ((ptr_Spikes-Obj_Index)/4)+1
id_RingLoss:		equ ((ptr_RingLoss-Obj_Index)/4)+1
id_ShieldItem:		equ ((ptr_ShieldItem-Obj_Index)/4)+1		; $38
id_GameOverCard:	equ ((ptr_GameOverCard-Obj_Index)/4)+1
id_GotThroughCard:	equ ((ptr_GotThroughCard-Obj_Index)/4)+1
id_PurpleRock:		equ ((ptr_PurpleRock-Obj_Index)/4)+1
id_SmashWall:		equ ((ptr_SmashWall-Obj_Index)/4)+1
id_BossGreenHill:	equ ((ptr_BossGreenHill-Obj_Index)/4)+1
id_Prison:		equ ((ptr_Prison-Obj_Index)/4)+1
id_ExplosionBomb:	equ ((ptr_ExplosionBomb-Obj_Index)/4)+1
id_MotoBug:		equ ((ptr_MotoBug-Obj_Index)/4)+1		; $40
id_Springs:		equ ((ptr_Springs-Obj_Index)/4)+1
id_Newtron:		equ ((ptr_Newtron-Obj_Index)/4)+1
id_Roller:		equ ((ptr_Roller-Obj_Index)/4)+1
id_EdgeWalls:		equ ((ptr_EdgeWalls-Obj_Index)/4)+1
id_SideStomp:		equ ((ptr_SideStomp-Obj_Index)/4)+1
id_MarbleBrick:		equ ((ptr_MarbleBrick-Obj_Index)/4)+1
id_Bumper:		equ ((ptr_Bumper-Obj_Index)/4)+1
id_BossBall:		equ ((ptr_BossBall-Obj_Index)/4)+1		; $48
id_WaterSound:		equ ((ptr_WaterSound-Obj_Index)/4)+1
id_VanishSonic:		equ ((ptr_VanishSonic-Obj_Index)/4)+1
id_GiantRing:		equ ((ptr_GiantRing-Obj_Index)/4)+1
id_GeyserMaker:		equ ((ptr_GeyserMaker-Obj_Index)/4)+1
id_LavaGeyser:		equ ((ptr_LavaGeyser-Obj_Index)/4)+1
id_LavaWall:		equ ((ptr_LavaWall-Obj_Index)/4)+1
id_Obj4F:		equ ((ptr_Obj4F-Obj_Index)/4)+1
id_Yadrin:		equ ((ptr_Yadrin-Obj_Index)/4)+1		; $50
id_SmashBlock:		equ ((ptr_SmashBlock-Obj_Index)/4)+1
id_MovingBlock:		equ ((ptr_MovingBlock-Obj_Index)/4)+1
id_CollapseFloor:	equ ((ptr_CollapseFloor-Obj_Index)/4)+1
id_LavaTag:		equ ((ptr_LavaTag-Obj_Index)/4)+1
id_Basaran:		equ ((ptr_Basaran-Obj_Index)/4)+1
id_FloatingBlock:	equ ((ptr_FloatingBlock-Obj_Index)/4)+1
id_SpikeBall:		equ ((ptr_SpikeBall-Obj_Index)/4)+1
id_BigSpikeBall:	equ ((ptr_BigSpikeBall-Obj_Index)/4)+1		; $58
id_Elevator:		equ ((ptr_Elevator-Obj_Index)/4)+1
id_CirclingPlatform:	equ ((ptr_CirclingPlatform-Obj_Index)/4)+1
id_Staircase:		equ ((ptr_Staircase-Obj_Index)/4)+1
id_Pylon:		equ ((ptr_Pylon-Obj_Index)/4)+1
id_Fan:			equ ((ptr_Fan-Obj_Index)/4)+1
id_Seesaw:		equ ((ptr_Seesaw-Obj_Index)/4)+1
id_Bomb:		equ ((ptr_Bomb-Obj_Index)/4)+1
id_Orbinaut:		equ ((ptr_Orbinaut-Obj_Index)/4)+1		; $60
id_LabyrinthBlock:	equ ((ptr_LabyrinthBlock-Obj_Index)/4)+1
id_Gargoyle:		equ ((ptr_Gargoyle-Obj_Index)/4)+1
id_LabyrinthConvey:	equ ((ptr_LabyrinthConvey-Obj_Index)/4)+1
id_Bubble:		equ ((ptr_Bubble-Obj_Index)/4)+1
id_Waterfall:		equ ((ptr_Waterfall-Obj_Index)/4)+1
id_Junction:		equ ((ptr_Junction-Obj_Index)/4)+1
id_RunningDisc:		equ ((ptr_RunningDisc-Obj_Index)/4)+1
id_Conveyor:		equ ((ptr_Conveyor-Obj_Index)/4)+1		; $68
id_SpinPlatform:	equ ((ptr_SpinPlatform-Obj_Index)/4)+1
id_Saws:		equ ((ptr_Saws-Obj_Index)/4)+1
id_ScrapStomp:		equ ((ptr_ScrapStomp-Obj_Index)/4)+1
id_VanishPlatform:	equ ((ptr_VanishPlatform-Obj_Index)/4)+1
id_Flamethrower:	equ ((ptr_Flamethrower-Obj_Index)/4)+1
id_Electro:		equ ((ptr_Electro-Obj_Index)/4)+1
id_SpinConvey:		equ ((ptr_SpinConvey-Obj_Index)/4)+1
id_Girder:		equ ((ptr_Girder-Obj_Index)/4)+1		; $70
id_Invisibarrier:	equ ((ptr_Invisibarrier-Obj_Index)/4)+1
id_Teleport:		equ ((ptr_Teleport-Obj_Index)/4)+1
id_BossMarble:		equ ((ptr_BossMarble-Obj_Index)/4)+1
id_BossFire:		equ ((ptr_BossFire-Obj_Index)/4)+1
id_BossSpringYard:	equ ((ptr_BossSpringYard-Obj_Index)/4)+1
id_BossBlock:		equ ((ptr_BossBlock-Obj_Index)/4)+1
id_BossLabyrinth:	equ ((ptr_BossLabyrinth-Obj_Index)/4)+1
id_Caterkiller:		equ ((ptr_Caterkiller-Obj_Index)/4)+1		; $78
id_Lamppost:		equ ((ptr_Lamppost-Obj_Index)/4)+1
id_BossStarLight:	equ ((ptr_BossStarLight-Obj_Index)/4)+1
id_BossSpikeball:	equ ((ptr_BossSpikeball-Obj_Index)/4)+1
id_RingFlash:		equ ((ptr_RingFlash-Obj_Index)/4)+1
id_HiddenBonus:		equ ((ptr_HiddenBonus-Obj_Index)/4)+1
id_SSResult:		equ ((ptr_SSResult-Obj_Index)/4)+1
id_SSRChaos:		equ ((ptr_SSRChaos-Obj_Index)/4)+1
id_ContScrItem:		equ ((ptr_ContScrItem-Obj_Index)/4)+1		; $80
id_ContSonic:		equ ((ptr_ContSonic-Obj_Index)/4)+1
id_ScrapEggman:		equ ((ptr_ScrapEggman-Obj_Index)/4)+1
id_FalseFloor:		equ ((ptr_FalseFloor-Obj_Index)/4)+1
id_EggmanCylinder:	equ ((ptr_EggmanCylinder-Obj_Index)/4)+1
id_BossFinal:		equ ((ptr_BossFinal-Obj_Index)/4)+1
id_BossPlasma:		equ ((ptr_BossPlasma-Obj_Index)/4)+1
id_EndSonic:		equ ((ptr_EndSonic-Obj_Index)/4)+1
id_EndChaos:		equ ((ptr_EndChaos-Obj_Index)/4)+1		; $88
id_EndSTH:		equ ((ptr_EndSTH-Obj_Index)/4)+1
id_CreditsText:		equ ((ptr_CreditsText-Obj_Index)/4)+1
id_EndEggman:		equ ((ptr_EndEggman-Obj_Index)/4)+1
id_TryChaos:		equ ((ptr_TryChaos-Obj_Index)/4)+1

; ---------------------------------------------------------------------------
; Subroutine to make an	object fall downwards, increasingly fast
; ---------------------------------------------------------------------------

ObjectFall:
		move.l	obX(a0),d2
		move.l	obY(a0),d3
		move.w	obVelX(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	obVelY(a0),d0
		addi.w	#$38,obVelY(a0)	; increase vertical speed
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,obX(a0)
		move.l	d3,obY(a0)
		rts

; End of function ObjectFall

; ---------------------------------------------------------------------------
; Subroutine translating object speed to update	object position
; ---------------------------------------------------------------------------

SpeedToPos:
		move.l	obX(a0),d2
		move.l	obY(a0),d3
		move.w	obVelX(a0),d0	; load horizontal speed
		ext.l	d0
		asl.l	#8,d0		; multiply speed by $100
		add.l	d0,d2		; add to x-axis position
		move.w	obVelY(a0),d0	; load vertical speed
		ext.l	d0
		asl.l	#8,d0		; multiply by $100
		add.l	d0,d3		; add to y-axis position
		move.l	d2,obX(a0)	; update x-axis position
		move.l	d3,obY(a0)	; update y-axis position
		rts

; End of function SpeedToPos

; ---------------------------------------------------------------------------
; Subroutine to display	a sprite/object, when a0 is the	object RAM
; ---------------------------------------------------------------------------

DisplaySprite:
		lea	(v_spritequeue).w,a1
		move.w	obPriority(a0),d0 ; get sprite priority
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a1		; jump to position in queue
		cmpi.w	#$7E,(a1)	; is this part of the queue full?
		bhs.s	DSpr_Full	; if yes, branch
		addq.w	#2,(a1)		; increment sprite count
		adda.w	(a1),a1		; jump to empty position
		move.w	a0,(a1)		; insert RAM address for object

	DSpr_Full:
		rts

; End of function DisplaySprite

; ---------------------------------------------------------------------------
; Subroutine to display	a 2nd sprite/object, when a1 is	the object RAM
; ---------------------------------------------------------------------------

DisplaySprite1:
		lea	(v_spritequeue).w,a2
		move.w	obPriority(a1),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a2
		cmpi.w	#$7E,(a2)
		bhs.s	DSpr1_Full
		addq.w	#2,(a2)
		adda.w	(a2),a2
		move.w	a1,(a2)

	DSpr1_Full:
		rts

; End of function DisplaySprite1

; ---------------------------------------------------------------------------
; Subroutine to delete an object
; ---------------------------------------------------------------------------

DeleteObject:
		movea.l	a0,a1		; move object RAM address to (a1)

; DeleteObject2:
DeleteChild:				; child objects are already in (a1)
		moveq	#0,d1
		moveq	#$F,d0

	DelObj_Loop:
		move.l	d1,(a1)+	; clear the object RAM
		dbf	d0,DelObj_Loop	; repeat for length of object RAM
		rts

; End of function DeleteObject

; ===========================================================================
BldSpr_ScrPos:	dc.l 0				; blank
		dc.l v_screenposx&$FFFFFF	; main screen x-position
		dc.l v_bgscreenposx&$FFFFFF	; background x-position 1
		dc.l v_bg3screenposx&$FFFFFF	; background x-position 2
; ---------------------------------------------------------------------------
; Subroutine to convert	mappings (etc) to proper Megadrive sprites
; ---------------------------------------------------------------------------

BuildSprites:
		lea	(v_spritetablebuffer).w,a2 ; set address for sprite table
		moveq	#0,d5
		lea	(v_spritequeue).w,a4
		moveq	#7,d7

	@priorityLoop:
		tst.w	(a4)	; are there objects left to draw?
		beq.w	@nextPriority	; if not, branch
		moveq	#2,d6

	@objectLoop:
		movea.w	(a4,d6.w),a0	; load object ID
		tst.b	(a0)		; if null, branch
		beq.w	@skipObject
		bclr	#7,obRender(a0)		; set as not visible

		move.b	obRender(a0),d0
		move.b	d0,d4
		andi.w	#$C,d0		; get drawing coordinates
		beq.s	@screenCoords	; branch if 0 (screen coordinates)
		movea.l	BldSpr_ScrPos(pc,d0.w),a1
	; check object bounds
		moveq	#0,d0
		move.b	obActWid(a0),d0
		move.w	obX(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	@skipObject	; left edge out of bounds
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#320,d1
		bge.s	@skipObject	; right edge out of bounds
		addi.w	#128,d3		; VDP sprites start at 128px

		btst	#4,d4		; is assume height flag on?
		beq.s	@assumeHeight	; if yes, branch
		moveq	#0,d0
		move.b	obHeight(a0),d0
		move.w	obY(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.s	@skipObject	; top edge out of bounds
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#224,d1
		bge.s	@skipObject
		addi.w	#128,d2		; VDP sprites start at 128px
		bra.s	@drawObject
; ===========================================================================

	@screenCoords:
		move.w	$A(a0),d2	; special variable for screen Y
		move.w	obX(a0),d3
		bra.s	@drawObject
; ===========================================================================

	@assumeHeight:
		move.w	obY(a0),d2
		sub.w	obMap(a1),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		blo.s	@skipObject
		cmpi.w	#$180,d2
		bhs.s	@skipObject

	@drawObject:
		movea.l	obMap(a0),a1
		moveq	#0,d1
		btst	#5,d4		; is static mappings flag on?
		bne.s	@drawFrame	; if yes, branch
		move.b	obFrame(a0),d1
		add.b	d1,d1
		adda.w	(a1,d1.w),a1	; get mappings frame address
		move.b	(a1)+,d1	; number of sprite pieces
		subq.b	#1,d1
		bmi.s	@setVisible

	@drawFrame:
		bsr.w	BuildSpr_Draw	; write data from sprite pieces to buffer

	@setVisible:
		bset	#7,obRender(a0)		; set object as visible

	@skipObject:
		addq.w	#2,d6
		subq.w	#2,(a4)			; number of objects left
		bne.w	@objectLoop

	@nextPriority:
		lea	$80(a4),a4
		dbf	d7,@priorityLoop
		move.b	d5,(v_spritecount).w
		cmpi.b	#$50,d5
		beq.s	@spriteLimit
		move.l	#0,(a2)
		rts
; ===========================================================================

	@spriteLimit:
		move.b	#0,-5(a2)	; set last sprite link
		rts
; End of function BuildSprites

BuildSpr_Draw:
		movea.w	obGfx(a0),a3
		btst	#0,d4
		bne.s	BuildSpr_FlipX
		btst	#1,d4
		bne.w	BuildSpr_FlipY
; End of function BuildSpr_Draw

BuildSpr_Normal:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; get y-offset
		ext.w	d0
		add.w	d2,d0		; add y-position
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,(a2)+	; write sprite size
		addq.b	#1,d5		; increase sprite counter
		move.b	d5,(a2)+	; set as sprite link
		move.b	(a1)+,d0	; get art tile
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0		; add art tile offset
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,d0	; get x-offset
		ext.w	d0
		add.w	d3,d0		; add x-position
		andi.w	#$1FF,d0	; keep within 512px
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,BuildSpr_Normal	; process next sprite piece

	@return:
		rts
; End of function BuildSpr_Normal

; ===========================================================================

BuildSpr_FlipX:
		btst	#1,d4		; is object also y-flipped?
		bne.w	BuildSpr_FlipXY	; if yes, branch

	@loop:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; y position
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4	; size
		move.b	d4,(a2)+
		addq.b	#1,d5		; link
		move.b	d5,(a2)+
		move.b	(a1)+,d0	; art tile
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$800,d0	; toggle flip-x in VDP
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,d0	; get x-offset
		ext.w	d0
		neg.w	d0			; negate it
		add.b	d4,d4		; calculate flipped position by size
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0	; keep within 512px
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,@loop		; process next sprite piece

	@return:
		rts
; ===========================================================================

BuildSpr_FlipY:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; get y-offset
		move.b	(a1),d4		; get size
		ext.w	d0
		neg.w	d0		; negate y-offset
		lsl.b	#3,d4	; calculate flip offset
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0	; add y-position
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,(a2)+	; size
		addq.b	#1,d5
		move.b	d5,(a2)+	; link
		move.b	(a1)+,d0	; art tile
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1000,d0	; toggle flip-y in VDP
		move.w	d0,(a2)+
		move.b	(a1)+,d0	; x-position
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,BuildSpr_FlipY	; process next sprite piece

	@return:
		rts
; ===========================================================================

BuildSpr_FlipXY:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; calculated flipped y
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,d4	; size
		move.b	d4,(a2)+	; link
		addq.b	#1,d5
		move.b	d5,(a2)+	; art tile
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1800,d0	; toggle flip-x/y in VDP
		move.w	d0,(a2)+
		move.b	(a1)+,d0	; calculate flipped x
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,BuildSpr_FlipXY	; process next sprite piece

	@return:
		rts

; ---------------------------------------------------------------------------
; Subroutine to check if an object is off screen

; output:
; d0 = flag set if object is off screen
; ---------------------------------------------------------------------------

; ChkObjOnScreen:
ChkObjectVisible:
		move.w	obX(a0),d0	; get object x-position
		sub.w	(v_screenposx).w,d0 ; subtract screen x-position
		bmi.s	@offscreen
		cmpi.w	#320,d0		; is object on the screen?
		bge.s	@offscreen	; if not, branch

		move.w	obY(a0),d1	; get object y-position
		sub.w	(v_screenposy).w,d1 ; subtract screen y-position
		bmi.s	@offscreen
		cmpi.w	#224,d1		; is object on the screen?
		bge.s	@offscreen	; if not, branch

		moveq	#0,d0		; set flag to 0
		rts

	@offscreen:
		moveq	#1,d0		; set flag to 1
		rts
; End of function ChkObjectVisible

; ---------------------------------------------------------------------------
; Subroutine to check if an object is off screen
; More precise than above subroutine, taking width into account

; output:
; d0 = flag set if object is off screen
; ---------------------------------------------------------------------------

; ChkObjOnScreen2:
ChkPartiallyVisible:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		move.w	obX(a0),d0	; get object x-position
		sub.w	(v_screenposx).w,d0 ; subtract screen x-position
		add.w	d1,d0		; add object width
		bmi.s	@offscreen2
		add.w	d1,d1
		sub.w	d1,d0
		cmpi.w	#320,d0
		bge.s	@offscreen2

		move.w	obY(a0),d1
		sub.w	(v_screenposy).w,d1
		bmi.s	@offscreen2
		cmpi.w	#224,d1
		bge.s	@offscreen2

		moveq	#0,d0
		rts

	@offscreen2:
		moveq	#1,d0
		rts
; End of function ChkPartiallyVisible

; ---------------------------------------------------------------------------
; Subroutine to load a level's objects
; ---------------------------------------------------------------------------

ObjPosLoad:
		moveq	#0,d0
		move.b	(v_opl_routine).w,d0
		move.w	OPL_Index(pc,d0.w),d0
		jmp	OPL_Index(pc,d0.w)
; End of function ObjPosLoad

; ===========================================================================
OPL_Index:	dc.w OPL_Main-OPL_Index
		dc.w OPL_Next-OPL_Index
; ===========================================================================

OPL_Main:
		addq.b	#2,(v_opl_routine).w
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	(ObjPos_Index).l,a0
		movea.l	a0,a1
		adda.w	(a0,d0.w),a0
		move.l	a0,(v_opl_data).w
		move.l	a0,(v_opl_data+4).w
		adda.w	2(a1,d0.w),a1
		move.l	a1,(v_opl_data+8).w
		move.l	a1,(v_opl_data+$C).w
		lea	(v_objstate).w,a2
		move.w	#$101,(a2)+
		move.w	#$5E,d0

OPL_ClrList:
		clr.l	(a2)+
		dbf	d0,OPL_ClrList	; clear pre-destroyed object list

		lea	(v_objstate).w,a2
		moveq	#0,d2
		move.w	(v_screenposx).w,d6
		subi.w	#$80,d6
		bhs.s	loc_D93C
		moveq	#0,d6

loc_D93C:
		andi.w	#$FF80,d6
		movea.l	(v_opl_data).w,a0

loc_D944:
		cmp.w	(a0),d6
		bls.s	loc_D956
		tst.b	4(a0)
		bpl.s	loc_D952
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_D952:
		addq.w	#6,a0
		bra.s	loc_D944
; ===========================================================================

loc_D956:
		move.l	a0,(v_opl_data).w
		movea.l	(v_opl_data+4).w,a0
		subi.w	#$80,d6
		blo.s	loc_D976

loc_D964:
		cmp.w	(a0),d6
		bls.s	loc_D976
		tst.b	4(a0)
		bpl.s	loc_D972
		addq.b	#1,1(a2)

loc_D972:
		addq.w	#6,a0
		bra.s	loc_D964
; ===========================================================================

loc_D976:
		move.l	a0,(v_opl_data+4).w
		move.w	#-1,(v_opl_screen).w

OPL_Next:
		lea	(v_objstate).w,a2
		moveq	#0,d2
		move.w	(v_screenposx).w,d6
		andi.w	#$FF80,d6
		cmp.w	(v_opl_screen).w,d6
		beq.w	locret_DA3A
		bge.s	loc_D9F6
		move.w	d6,(v_opl_screen).w
		movea.l	(v_opl_data+4).w,a0
		subi.w	#$80,d6
		blo.s	loc_D9D2

loc_D9A6:
		cmp.w	-6(a0),d6
		bge.s	loc_D9D2
		subq.w	#6,a0
		tst.b	4(a0)
		bpl.s	loc_D9BC
		subq.b	#1,1(a2)
		move.b	1(a2),d2

loc_D9BC:
		bsr.w	loc_DA3C
		bne.s	loc_D9C6
		subq.w	#6,a0
		bra.s	loc_D9A6
; ===========================================================================

loc_D9C6:
		tst.b	4(a0)
		bpl.s	loc_D9D0
		addq.b	#1,1(a2)

loc_D9D0:
		addq.w	#6,a0

loc_D9D2:
		move.l	a0,(v_opl_data+4).w
		movea.l	(v_opl_data).w,a0
		addi.w	#$300,d6

loc_D9DE:
		cmp.w	-6(a0),d6
		bgt.s	loc_D9F0
		tst.b	-2(a0)
		bpl.s	loc_D9EC
		subq.b	#1,(a2)

loc_D9EC:
		subq.w	#6,a0
		bra.s	loc_D9DE
; ===========================================================================

loc_D9F0:
		move.l	a0,(v_opl_data).w
		rts
; ===========================================================================

loc_D9F6:
		move.w	d6,(v_opl_screen).w
		movea.l	(v_opl_data).w,a0
		addi.w	#$280,d6

loc_DA02:
		cmp.w	(a0),d6
		bls.s	loc_DA16
		tst.b	4(a0)
		bpl.s	loc_DA10
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_DA10:
		bsr.w	loc_DA3C
		beq.s	loc_DA02

loc_DA16:
		move.l	a0,(v_opl_data).w
		movea.l	(v_opl_data+4).w,a0
		subi.w	#$300,d6
		blo.s	loc_DA36

loc_DA24:
		cmp.w	(a0),d6
		bls.s	loc_DA36
		tst.b	4(a0)
		bpl.s	loc_DA32
		addq.b	#1,1(a2)

loc_DA32:
		addq.w	#6,a0
		bra.s	loc_DA24
; ===========================================================================

loc_DA36:
		move.l	a0,(v_opl_data+4).w

locret_DA3A:
		rts
; ===========================================================================

loc_DA3C:
		tst.b	4(a0)
		bpl.s	OPL_MakeItem
		bset	#7,2(a2,d2.w)
		beq.s	OPL_MakeItem
		addq.w	#6,a0
		moveq	#0,d0
		rts
; ===========================================================================

OPL_MakeItem:
		bsr.w	FindFreeObj
		bne.s	locret_DA8A
		move.w	(a0)+,obX(a1)
		move.w	(a0)+,d0
		move.w	d0,d1
		andi.w	#$FFF,d0
		move.w	d0,obY(a1)
		rol.w	#2,d1
		andi.b	#3,d1
		move.b	d1,obRender(a1)
		move.b	d1,obStatus(a1)
		move.b	(a0)+,d0
		bpl.s	loc_DA80
		andi.b	#$7F,d0
		move.b	d2,obRespawnNo(a1)

loc_DA80:
		move.b	d0,0(a1)
		move.b	(a0)+,obSubtype(a1)
		moveq	#0,d0

locret_DA8A:
		rts

; ---------------------------------------------------------------------------
; Subroutine to find a free object space

; output:
; a1 = free position in object RAM
; ---------------------------------------------------------------------------

; SingleObjLoad:
FindFreeObj:
		lea	(v_lvlobjspace).w,a1 ; start address for object RAM
		move.w	#$5F,d0

	FFree_Loop:
		tst.b	(a1)		; is object RAM slot empty?
		beq.s	FFree_Found	; if yes, branch
		lea	$40(a1),a1	; goto next object RAM slot
		dbf	d0,FFree_Loop	; repeat $5F times

	FFree_Found:
		rts

; End of function FindFreeObj

; ---------------------------------------------------------------------------
; Subroutine to find a free object space AFTER the current one

; output:
; a1 = free position in object RAM
; ---------------------------------------------------------------------------

; SingleObjLoad2:
FindNextFreeObj:
		movea.l	a0,a1
		move.w	#v_lvlobjend&$FFFF,d0
		sub.w	a0,d0
		lsr.w	#6,d0
		subq.w	#1,d0
		blo.s	NFree_Found

	NFree_Loop:
		tst.b	(a1)
		beq.s	NFree_Found
		lea	$40(a1),a1
		dbf	d0,NFree_Loop

	NFree_Found:
		rts

; End of function FindNextFreeObj

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 41 - springs
; ---------------------------------------------------------------------------

; Obj41:
Springs:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Spring_Index(pc,d0.w),d1
		jsr	Spring_Index(pc,d1.w)
		bsr.w	DisplaySprite
		out_of_range.w	DeleteObject
		rts
; ===========================================================================
Spring_Index:	dc.w Spring_Main-Spring_Index
		dc.w Spring_Up-Spring_Index
		dc.w Spring_AniUp-Spring_Index
		dc.w Spring_ResetUp-Spring_Index
		dc.w Spring_LR-Spring_Index
		dc.w Spring_AniLR-Spring_Index
		dc.w Spring_ResetLR-Spring_Index
		dc.w Spring_Dwn-Spring_Index
		dc.w Spring_AniDwn-Spring_Index
		dc.w Spring_ResetDwn-Spring_Index

spring_pow:	equ $30			; power of current spring

Spring_Powers:	dc.w -$1000		; power of red spring
		dc.w -$A00		; power of yellow spring
; ===========================================================================

Spring_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Spring,obMap(a0)
		move.w	#$523,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)
		move.b	obSubtype(a0),d0
		btst	#4,d0		; does the spring face left/right?
		beq.s	Spring_NotLR	; if not, branch

		move.b	#8,obRoutine(a0) ; use "Spring_LR" routine
		move.b	#1,obAnim(a0)
		move.b	#3,obFrame(a0)
		move.w	#$533,obGfx(a0)
		move.b	#8,obActWid(a0)

	Spring_NotLR:
		btst	#5,d0		; does the spring face downwards?
		beq.s	Spring_NotDwn	; if not, branch

		move.b	#$E,obRoutine(a0) ; use "Spring_Dwn" routine
		bset	#1,obStatus(a0)

	Spring_NotDwn:
		btst	#1,d0
		beq.s	loc_DB72
		bset	#5,obGfx(a0)

loc_DB72:
		andi.w	#$F,d0
		move.w	Spring_Powers(pc,d0.w),spring_pow(a0)
		rts
; ===========================================================================

Spring_Up:	; Routine 2
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		tst.b	obSolid(a0)	; is Sonic on top of the spring?
		bne.s	Spring_BounceUp	; if yes, branch
		rts
; ===========================================================================

Spring_BounceUp:
		addq.b	#2,obRoutine(a0)
		addq.w	#8,obY(a1)
		move.w	spring_pow(a0),obVelY(a1) ; move Sonic upwards
		bset	#1,obStatus(a1)
		bclr	#3,obStatus(a1)
		move.b	#id_Spring,obAnim(a1) ; use "bouncing" animation
		move.b	#2,obRoutine(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)
		move.w	#sfx_Spring,d0
		jsr	(PlaySound_Special).l	; play spring sound

Spring_AniUp:	; Routine 4
		lea	(Ani_Spring).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Spring_ResetUp:	; Routine 6
		move.b	#1,obNextAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_Up" routine
		rts
; ===========================================================================

Spring_LR:	; Routine 8
		move.w	#$13,d1
		move.w	#$E,d2
		move.w	#$F,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,obRoutine(a0)
		bne.s	loc_DC0C
		move.b	#8,obRoutine(a0)

loc_DC0C:
		btst	#5,obStatus(a0)
		bne.s	Spring_BounceLR
		rts
; ===========================================================================

Spring_BounceLR:
		addq.b	#2,obRoutine(a0)
		move.w	spring_pow(a0),obVelX(a1) ; move Sonic to the left
		addq.w	#8,obX(a1)
		btst	#0,obStatus(a0)	; is object flipped?
		bne.s	Spring_Flipped	; if yes, branch
		subi.w	#$10,obX(a1)
		neg.w	obVelX(a1)	; move Sonic to the right

	Spring_Flipped:
		move.w	#$F,$3E(a1)
		move.w	obVelX(a1),obInertia(a1)
		bchg	#0,obStatus(a1)
		btst	#2,obStatus(a1)
		bne.s	loc_DC56
		move.b	#id_Walk,obAnim(a1)	; use walking animation

loc_DC56:
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)
		move.w	#sfx_Spring,d0
		jsr	(PlaySound_Special).l	; play spring sound

Spring_AniLR:	; Routine $A
		lea	(Ani_Spring).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Spring_ResetLR:	; Routine $C
		move.b	#2,obNextAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_LR" routine
		rts
; ===========================================================================

Spring_Dwn:	; Routine $E
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,obRoutine(a0)
		bne.s	loc_DCA4
		move.b	#$E,obRoutine(a0)

loc_DCA4:
		tst.b	obSolid(a0)
		bne.s	locret_DCAE
		tst.w	d4
		bmi.s	Spring_BounceDwn

locret_DCAE:
		rts
; ===========================================================================

Spring_BounceDwn:
		addq.b	#2,obRoutine(a0)
		subq.w	#8,obY(a1)
		move.w	spring_pow(a0),obVelY(a1)
		neg.w	obVelY(a1)	; move Sonic downwards
		bset	#1,obStatus(a1)
		bclr	#3,obStatus(a1)
		move.b	#2,obRoutine(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)
		move.w	#sfx_Spring,d0
		jsr	(PlaySound_Special).l	; play spring sound

Spring_AniDwn:	; Routine $10
		lea	(Ani_Spring).l,a1
		bra.w	AnimateSprite
; ===========================================================================

Spring_ResetDwn:
		; Routine $12
		move.b	#1,obNextAni(a0) ; reset animation
		subq.b	#4,obRoutine(a0) ; goto "Spring_Dwn" routine
		rts

		include	"_anim\Springs.asm"
Map_Spring:	include	"_maps\Springs.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 42 - Newtron enemy (GHZ)
; ---------------------------------------------------------------------------

; Obj42:
Newtron:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Newt_Index(pc,d0.w),d1
		jmp	Newt_Index(pc,d1.w)
; ===========================================================================
Newt_Index:	dc.w Newt_Main-Newt_Index
		dc.w Newt_Action-Newt_Index
		dc.w Newt_Delete-Newt_Index
; ===========================================================================

Newt_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Newt,obMap(a0)
		move.w	#$49B,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$14,obActWid(a0)
		move.b	#$10,obHeight(a0)
		move.b	#8,obWidth(a0)

Newt_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		lea	(Ani_Newt).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
@index:		dc.w @chkdistance-@index
		dc.w @type00-@index
		dc.w @matchfloor-@index
		dc.w @speed-@index
		dc.w @type01-@index
; ===========================================================================

@chkdistance:
		bset	#0,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	@sonicisright
		neg.w	d0
		bclr	#0,obStatus(a0)

	@sonicisright:
		cmpi.w	#$80,d0		; is Sonic within $80 pixels of the newtron?
		bhs.s	@outofrange	; if not, branch
		addq.b	#2,ob2ndRout(a0) ; goto @type00 next
		move.b	#1,obAnim(a0)
		tst.b	obSubtype(a0)	; check object type
		beq.s	@istype00	; if type is 00, branch

		move.w	#$249B,obGfx(a0)
		move.b	#8,ob2ndRout(a0) ; goto @type01 next
		move.b	#4,obAnim(a0)	; use different animation

	@outofrange:
	@istype00:
		rts
; ===========================================================================

@type00:
		cmpi.b	#4,obFrame(a0)	; has "appearing" animation finished?
		bhs.s	@fall		; is yes, branch
		bset	#0,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	@sonicisright2
		bclr	#0,obStatus(a0)

	@sonicisright2:
		rts
; ===========================================================================

	@fall:
		cmpi.b	#1,obFrame(a0)
		bne.s	@loc_DE42
		move.b	#$C,obColType(a0)

	@loc_DE42:
		bsr.w	ObjectFall
		bsr.w	ObjFloorDist
		tst.w	d1		; has newtron hit the floor?
		bpl.s	@keepfalling	; if not, branch

		add.w	d1,obY(a0)
		move.w	#0,obVelY(a0)	; stop newtron falling
		addq.b	#2,ob2ndRout(a0)
		move.b	#2,obAnim(a0)
		btst	#5,obGfx(a0)
		beq.s	@pppppppp
		addq.b	#1,obAnim(a0)

	@pppppppp:
		move.b	#$D,obColType(a0)
		move.w	#$200,obVelX(a0) ; move newtron horizontally
		btst	#0,obStatus(a0)
		bne.s	@keepfalling
		neg.w	obVelX(a0)

	@keepfalling:
		rts
; ===========================================================================

@matchfloor:
		bsr.w	SpeedToPos
		bsr.w	ObjFloorDist
		cmpi.w	#-8,d1
		blt.s	@nextroutine
		cmpi.w	#$C,d1
		bge.s	@nextroutine
		add.w	d1,obY(a0)	; match newtron's position with floor
		rts
; ===========================================================================

	@nextroutine:
		addq.b	#2,ob2ndRout(a0) ; goto @speed next
		rts
; ===========================================================================

@speed:
		bsr.w	SpeedToPos
		rts
; ===========================================================================

@type01:
		cmpi.b	#1,obFrame(a0)
		bne.s	@firemissile
		move.b	#$C,obColType(a0)

	@firemissile:
		cmpi.b	#2,obFrame(a0)
		bne.s	@fail
		tst.b	$32(a0)
		bne.s	@fail
		move.b	#1,$32(a0)
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_Missile,0(a1) ; load missile object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		subq.w	#8,obY(a1)
		move.w	#$200,obVelX(a1)
		move.w	#$14,d0
		btst	#0,obStatus(a0)
		bne.s	@noflip
		neg.w	d0
		neg.w	obVelX(a1)

	@noflip:
		add.w	d0,obX(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.b	#1,obSubtype(a1)

	@fail:
		rts
; ===========================================================================

Newt_Delete:	; Routine 4
		bra.w	DeleteObject

		include	"_anim\Newtron.asm"
Map_Newt:	include	"_maps\Newtron.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 43 - Roller enemy (SYZ)
; ---------------------------------------------------------------------------

; Obj43:
Roller:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Roll_Index(pc,d0.w),d1
		jmp	Roll_Index(pc,d1.w)
; ===========================================================================
Roll_Index:	dc.w Roll_Main-Roll_Index
		dc.w Roll_Action-Roll_Index
; ===========================================================================

Roll_Main:	; Routine 0
		move.b	#$E,obHeight(a0)
		move.b	#8,obWidth(a0)
		bsr.w	ObjectFall
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	locret_E052
		add.w	d1,obY(a0)	; match roller's position with the floor
		move.w	#0,obVelY(a0)
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Roll,obMap(a0)
		move.w	#$4B8,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$10,obActWid(a0)

	locret_E052:
		rts
; ===========================================================================

Roll_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Roll_Index2(pc,d0.w),d1
		jsr	Roll_Index2(pc,d1.w)
		lea	(Ani_Roll).l,a1
		bsr.w	AnimateSprite
		move.w	obX(a0),d0
		andi.w	#$FF80,d0
		move.w	(v_screenposx).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bgt.w	Roll_ChkGone
		bra.w	DisplaySprite
; ===========================================================================

Roll_ChkGone:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	Roll_Delete
		bclr	#7,2(a2,d0.w)

Roll_Delete:
		bra.w	DeleteObject
; ===========================================================================
Roll_Index2:	dc.w Roll_RollChk-Roll_Index2
		dc.w Roll_RollNoChk-Roll_Index2
		dc.w Roll_ChkJump-Roll_Index2
		dc.w Roll_MatchFloor-Roll_Index2
; ===========================================================================

Roll_RollChk:
		move.w	(v_player+obX).w,d0
		subi.w	#$100,d0
		blo.s	loc_E0D2
		sub.w	obX(a0),d0	; check distance between Roller	and Sonic
		blo.s	loc_E0D2
		addq.b	#4,ob2ndRout(a0)
		move.b	#2,obAnim(a0)
		move.w	#$700,obVelX(a0) ; move Roller horizontally
		move.b	#$8E,obColType(a0) ; make Roller invincible

loc_E0D2:
		addq.l	#4,sp
		rts
; ===========================================================================

Roll_RollNoChk:
		cmpi.b	#2,obAnim(a0)
		beq.s	loc_E0F8
		subq.w	#1,$30(a0)
		bpl.s	locret_E0F6
		move.b	#1,obAnim(a0)
		move.w	#$700,obVelX(a0)
		move.b	#$8E,obColType(a0)

locret_E0F6:
		rts
; ===========================================================================

loc_E0F8:
		addq.b	#2,ob2ndRout(a0)
		rts
; ===========================================================================

Roll_ChkJump:
		bsr.w	Roll_Stop
		bsr.w	SpeedToPos
		bsr.w	ObjFloorDist
		cmpi.w	#-8,d1
		blt.s	Roll_Jump
		cmpi.w	#$C,d1
		bge.s	Roll_Jump
		add.w	d1,obY(a0)
		rts
; ===========================================================================

Roll_Jump:
		addq.b	#2,ob2ndRout(a0)
		bset	#0,$32(a0)
		beq.s	locret_E12E
		move.w	#-$600,obVelY(a0)	; move Roller vertically

locret_E12E:
		rts
; ===========================================================================

Roll_MatchFloor:
		bsr.w	ObjectFall
		tst.w	obVelY(a0)
		bmi.s	locret_E150
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	locret_E150
		add.w	d1,obY(a0)	; match Roller's position with the floor
		subq.b	#2,ob2ndRout(a0)
		move.w	#0,obVelY(a0)

locret_E150:
		rts

Roll_Stop:
		tst.b	$32(a0)
		bmi.s	locret_E188
		move.w	(v_player+obX).w,d0
		subi.w	#$30,d0
		sub.w	obX(a0),d0
		bhs.s	locret_E188
		move.b	#0,obAnim(a0)
		move.b	#$E,obColType(a0)
		clr.w	obVelX(a0)
		move.w	#120,$30(a0)	; set waiting time to 2 seconds
		move.b	#2,ob2ndRout(a0)
		bset	#7,$32(a0)

locret_E188:
		rts
; End of function Roll_Stop

		include	"_anim\Roller.asm"
Map_Roll:	include	"_maps\Roller.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 44 - edge walls (GHZ)
; ---------------------------------------------------------------------------

; Obj44:
EdgeWalls:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Edge_Index(pc,d0.w),d1
		jmp	Edge_Index(pc,d1.w)
; ===========================================================================
Edge_Index:	dc.w Edge_Main-Edge_Index
		dc.w Edge_Solid-Edge_Index
		dc.w Edge_Display-Edge_Index
; ===========================================================================

Edge_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Edge,obMap(a0)
		move.w	#$434C,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#8,obActWid(a0)
		move.b	#6,obPriority(a0)
		move.b	obSubtype(a0),obFrame(a0) ; copy object type number to frame number
		bclr	#4,obFrame(a0)	; clear 4th bit	(deduct	$10)
		beq.s	Edge_Solid	; make object solid if 4th bit = 0
		addq.b	#2,obRoutine(a0)
		bra.s	Edge_Display	; don't make it solid if 4th bit = 1
; ===========================================================================

Edge_Solid:	; Routine 2
		move.w	#$13,d1
		move.w	#$28,d2
		bsr.w	Obj44_SolidWall

Edge_Display:	; Routine 4
		bsr.w	DisplaySprite
		out_of_range.w	DeleteObject
		rts

Map_Edge:	include	"_maps\GHZ Edge Walls.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 13 - lava ball maker (MZ, SLZ)
; ---------------------------------------------------------------------------

; Obj13:
LavaMaker:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	LavaM_Index(pc,d0.w),d1
		jsr	LavaM_Index(pc,d1.w)
		bra.w	LBall_ChkDel
; ===========================================================================
LavaM_Index:	dc.w LavaM_Main-LavaM_Index
		dc.w LavaM_MakeLava-LavaM_Index
; ---------------------------------------------------------------------------
;
; Lava ball production rates
;
LavaM_Rates:	dc.b 30, 60, 90, 120, 150, 180
; ===========================================================================

LavaM_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	obSubtype(a0),d0
		lsr.w	#4,d0
		andi.w	#$F,d0
		move.b	LavaM_Rates(pc,d0.w),obDelayAni(a0)
		move.b	obDelayAni(a0),obTimeFrame(a0) ; set time delay for lava balls
		andi.b	#$F,obSubtype(a0)

LavaM_MakeLava:	; Routine 2
		subq.b	#1,obTimeFrame(a0) ; subtract 1 from time delay
		bne.s	LavaM_Wait	; if time still remains, branch
		move.b	obDelayAni(a0),obTimeFrame(a0) ; reset time delay
		bsr.w	ChkObjectVisible
		bne.s	LavaM_Wait
		bsr.w	FindFreeObj
		bne.s	LavaM_Wait
		move.b	#id_LavaBall,0(a1) ; load lava ball object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obSubtype(a0),obSubtype(a1)

	LavaM_Wait:
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 14 - lava balls (MZ, SLZ)
; ---------------------------------------------------------------------------

; Obj14:
LavaBall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	LBall_Index(pc,d0.w),d1
		jsr	LBall_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
LBall_Index:	dc.w LBall_Main-LBall_Index
		dc.w LBall_Action-LBall_Index
		dc.w LBall_Delete-LBall_Index

LBall_Speeds:	dc.w -$400, -$500, -$600, -$700, -$200
		dc.w $200, -$200, $200,	0
; ===========================================================================

LBall_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#8,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.l	#Map_Fire,obMap(a0)
		move.w	#$345,obGfx(a0)
		cmpi.b	#3,(v_zone).w	; check if level is SLZ
		bne.s	@notSLZ
		move.w	#$480,obGfx(a0)	; SLZ specific code

	@notSLZ:
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$8B,obColType(a0)
		move.w	obY(a0),$30(a0)
		tst.b	$29(a0)
		beq.s	@speed
		addq.b	#2,obPriority(a0)

	@speed:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	LBall_Speeds(pc,d0.w),obVelY(a0) ; load object speed (vertical)
		move.b	#8,obActWid(a0)
		cmpi.b	#6,obSubtype(a0) ; is object type below $6 ?
		blo.s	@sound		; if yes, branch

		move.b	#$10,obActWid(a0)
		move.b	#2,obAnim(a0)	; use horizontal animation
		move.w	obVelY(a0),obVelX(a0) ; set horizontal speed
		move.w	#0,obVelY(a0)	; delete vertical speed

	@sound:
		move.w	#sfx_Fireball,d0
		jsr	(PlaySound_Special).l	; play lava ball sound

LBall_Action:	; Routine 2
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	LBall_TypeIndex(pc,d0.w),d1
		jsr	LBall_TypeIndex(pc,d1.w)
		bsr.w	SpeedToPos
		lea	(Ani_Fire).l,a1
		bsr.w	AnimateSprite

LBall_ChkDel:
		out_of_range.w	DeleteObject
		rts
; ===========================================================================
LBall_TypeIndex:dc.w LBall_Type00-LBall_TypeIndex, LBall_Type00-LBall_TypeIndex
		dc.w LBall_Type00-LBall_TypeIndex, LBall_Type00-LBall_TypeIndex
		dc.w LBall_Type04-LBall_TypeIndex, LBall_Type05-LBall_TypeIndex
		dc.w LBall_Type06-LBall_TypeIndex, LBall_Type07-LBall_TypeIndex
		dc.w LBall_Type08-LBall_TypeIndex
; ===========================================================================
; lavaball types 00-03 fly up and fall back down

LBall_Type00:
		addi.w	#$18,obVelY(a0)	; increase object's downward speed
		move.w	$30(a0),d0
		cmp.w	obY(a0),d0	; has object fallen back to its original position?
		bhs.s	loc_E41E	; if not, branch
		addq.b	#2,obRoutine(a0)	; goto "LBall_Delete" routine

loc_E41E:
		bclr	#1,obStatus(a0)
		tst.w	obVelY(a0)
		bpl.s	locret_E430
		bset	#1,obStatus(a0)

locret_E430:
		rts
; ===========================================================================
; lavaball type 04 flies up until it hits the ceiling

LBall_Type04:
		bset	#1,obStatus(a0)
		bsr.w	ObjHitCeiling
		tst.w	d1
		bpl.s	locret_E452
		move.b	#8,obSubtype(a0)
		move.b	#1,obAnim(a0)
		move.w	#0,obVelY(a0)	; stop the object when it touches the ceiling

locret_E452:
		rts
; ===========================================================================
; lavaball type 05 falls down until it hits the	floor

LBall_Type05:
		bclr	#1,obStatus(a0)
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	locret_E474
		move.b	#8,obSubtype(a0)
		move.b	#1,obAnim(a0)
		move.w	#0,obVelY(a0)	; stop the object when it touches the floor

locret_E474:
		rts
; ===========================================================================
; lavaball types 06-07 move sideways

LBall_Type06:
		bset	#0,obStatus(a0)
		moveq	#-8,d3
		bsr.w	ObjHitWallLeft
		tst.w	d1
		bpl.s	locret_E498
		move.b	#8,obSubtype(a0)
		move.b	#3,obAnim(a0)
		move.w	#0,obVelX(a0)	; stop object when it touches a wall

locret_E498:
		rts
; ===========================================================================

LBall_Type07:
		bclr	#0,obStatus(a0)
		moveq	#8,d3
		bsr.w	ObjHitWallRight
		tst.w	d1
		bpl.s	locret_E4BC
		move.b	#8,obSubtype(a0)
		move.b	#3,obAnim(a0)
		move.w	#0,obVelX(a0)	; stop object when it touches a wall

locret_E4BC:
		rts
; ===========================================================================

LBall_Type08:
		rts
; ===========================================================================

LBall_Delete:
		bra.w	DeleteObject

		include	"_anim\Fireballs.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6D - flame thrower (SBZ)
; ---------------------------------------------------------------------------

; Obj6D:
Flamethrower:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Flame_Index(pc,d0.w),d1
		jmp	Flame_Index(pc,d1.w)
; ===========================================================================
Flame_Index:	dc.w Flame_Main-Flame_Index
		dc.w Flame_Action-Flame_Index
; ===========================================================================

Flame_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Flame,obMap(a0)
		move.w	#$83D9,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.w	obY(a0),$30(a0)	; store obY (gets overwritten later though)
		move.b	#$C,obActWid(a0)
		move.b	obSubtype(a0),d0
		andi.w	#$F0,d0		; read 1st digit of object type
		add.w	d0,d0		; multiply by 2
		move.w	d0,$30(a0)
		move.w	d0,$32(a0)	; set flaming time
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0		; read 2nd digit of object type
		lsl.w	#5,d0		; multiply by $20
		move.w	d0,$34(a0)	; set pause time
		move.b	#$A,$36(a0)
		btst	#1,obStatus(a0)
		beq.s	Flame_Action
		move.b	#2,obAnim(a0)
		move.b	#$15,$36(a0)

Flame_Action:	; Routine 2
		subq.w	#1,$30(a0)	; subtract 1 from time
		bpl.s	loc_E57A	; if time remains, branch
		move.w	$34(a0),$30(a0)	; begin pause time
		bchg	#0,obAnim(a0)
		beq.s	loc_E57A
		move.w	$32(a0),$30(a0)	; begin flaming	time
		move.w	#sfx_Flamethrower,d0
		jsr	(PlaySound_Special).l ; play flame sound

loc_E57A:
		lea	(Ani_Flame).l,a1
		bsr.w	AnimateSprite
		move.b	#0,obColType(a0)
		move.b	$36(a0),d0
		cmp.b	obFrame(a0),d0
		bne.s	Flame_ChkDel
		move.b	#$A3,obColType(a0)

Flame_ChkDel:
		out_of_range.w	DeleteObject
		bra.w	DisplaySprite

		include	"_anim\Flamethrower.asm"
Map_Flame:	include	"_maps\Flamethrower.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 46 - solid blocks and blocks that fall from the ceiling (MZ)
; ---------------------------------------------------------------------------

; Obj46:
MarbleBrick:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Brick_Index(pc,d0.w),d1
		jmp	Brick_Index(pc,d1.w)
; ===========================================================================
Brick_Index:	dc.w Brick_Main-Brick_Index
		dc.w Brick_Action-Brick_Index

brick_origY:	equ $30
; ===========================================================================

Brick_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$F,obHeight(a0)
		move.b	#$F,obWidth(a0)
		move.l	#Map_Brick,obMap(a0)
		move.w	#$4000,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$10,obActWid(a0)
		move.w	obY(a0),brick_origY(a0)
		move.w	#$5C0,$32(a0)

Brick_Action:	; Routine 2
		tst.b	obRender(a0)
		bpl.s	@chkdel
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object type
		andi.w	#7,d0		; read only the 1st digit
		add.w	d0,d0
		move.w	Brick_TypeIndex(pc,d0.w),d1
		jsr	Brick_TypeIndex(pc,d1.w)
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject

	@chkdel:
		out_of_range.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================
Brick_TypeIndex:dc.w Brick_Type00-Brick_TypeIndex
		dc.w Brick_Type01-Brick_TypeIndex
		dc.w Brick_Type02-Brick_TypeIndex
		dc.w Brick_Type03-Brick_TypeIndex
		dc.w Brick_Type04-Brick_TypeIndex
; ===========================================================================

Brick_Type00:
		rts
; ===========================================================================

Brick_Type02:
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	loc_E888
		neg.w	d0

loc_E888:
		cmpi.w	#$90,d0		; is Sonic within $90 pixels of the block?
		bhs.s	Brick_Type01	; if not, resume wobbling
		move.b	#3,obSubtype(a0)	; if yes, make the block fall

Brick_Type01:
		moveq	#0,d0
		move.b	(v_oscillate+$16).w,d0
		btst	#3,obSubtype(a0)
		beq.s	loc_E8A8
		neg.w	d0
		addi.w	#$10,d0

loc_E8A8:
		move.w	brick_origY(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)	; update the block's position to make it wobble
		rts
; ===========================================================================

Brick_Type03:
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; increase falling speed
		bsr.w	ObjFloorDist
		tst.w	d1		; has the block hit the	floor?
		bpl.w	locret_E8EE	; if not, branch
		add.w	d1,obY(a0)
		clr.w	obVelY(a0)	; stop the block falling
		move.w	obY(a0),brick_origY(a0)
		move.b	#4,obSubtype(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0
		bhs.s	locret_E8EE
		move.b	#0,obSubtype(a0)

locret_E8EE:
		rts
; ===========================================================================

Brick_Type04:
		moveq	#0,d0
		move.b	(v_oscillate+$12).w,d0
		lsr.w	#3,d0
		move.w	brick_origY(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)	; make the block wobble
		rts

Map_Brick:	include	"_maps\MZ Bricks.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 12 - lamp (SYZ)
; ---------------------------------------------------------------------------

; Obj12:
SpinningLight:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Light_Index(pc,d0.w),d1
		jmp	Light_Index(pc,d1.w)
; ===========================================================================
Light_Index:	dc.w Light_Main-Light_Index
		dc.w Light_Animate-Light_Index
; ===========================================================================

Light_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Light,obMap(a0)
		move.w	#0,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#6,obPriority(a0)

Light_Animate:	; Routine 2
		subq.b	#1,obTimeFrame(a0)
		bpl.s	@chkdel
		move.b	#7,obTimeFrame(a0)
		addq.b	#1,obFrame(a0)
		cmpi.b	#6,obFrame(a0)
		blo.s	@chkdel
		move.b	#0,obFrame(a0)

	@chkdel:
		out_of_range.w	DeleteObject
		bra.w	DisplaySprite

Map_Light	include	"_maps\Light.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 47 - pinball bumper (SYZ)
; ---------------------------------------------------------------------------

; Obj47:
Bumper:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bump_Index(pc,d0.w),d1
		jmp	Bump_Index(pc,d1.w)
; ===========================================================================
Bump_Index:	dc.w Bump_Main-Bump_Index
		dc.w Bump_Hit-Bump_Index
; ===========================================================================

Bump_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bump,obMap(a0)
		move.w	#$380,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#1,obPriority(a0)
		move.b	#$D7,obColType(a0)

Bump_Hit:	; Routine 2
		tst.b	obColProp(a0)	; has Sonic touched the bumper?
		beq.w	@display	; if not, branch
		clr.b	obColProp(a0)
		lea	(v_player).w,a1
		move.w	obX(a0),d1
		move.w	obY(a0),d2
		sub.w	obX(a1),d1
		sub.w	obY(a1),d2
		jsr	(CalcAngle).l
		jsr	(CalcSine).l
		muls.w	#-$700,d1
		asr.l	#8,d1
		move.w	d1,obVelX(a1)	; bounce Sonic away
		muls.w	#-$700,d0
		asr.l	#8,d0
		move.w	d0,obVelY(a1)	; bounce Sonic away
		bset	#1,obStatus(a1)
		bclr	#4,obStatus(a1)
		bclr	#5,obStatus(a1)
		clr.b	$3C(a1)
		move.b	#1,obAnim(a0)	; use "hit" animation
		move.w	#sfx_Bumper,d0
		jsr	(PlaySound_Special).l	; play bumper sound
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@addscore
		cmpi.b	#$8A,2(a2,d0.w)	; has bumper been hit 10 times?
		bhs.s	@display	; if yes, Sonic gets no	points
		addq.b	#1,2(a2,d0.w)

	@addscore:
		moveq	#1,d0
		jsr	(AddPoints).l	; add 10 to score
		bsr.w	FindFreeObj
		bne.s	@display
		move.b	#id_Points,0(a1) ; load points object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#4,obFrame(a1)

	@display:
		lea	(Ani_Bump).l,a1
		bsr.w	AnimateSprite
		out_of_range.s	@resetcount
		bra.w	DisplaySprite
; ===========================================================================

@resetcount:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@delete
		bclr	#7,2(a2,d0.w)

	@delete:
		bra.w	DeleteObject

		include	"_anim\Bumper.asm"
Map_Bump:	include	"_maps\Bumper.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0D - signpost at the end of a level
; ---------------------------------------------------------------------------

; Obj0D:
Signpost:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Sign_Index(pc,d0.w),d1
		jsr	Sign_Index(pc,d1.w)
		lea	(Ani_Sign).l,a1
		bsr.w	AnimateSprite
		bsr.w	DisplaySprite
		out_of_range.w	DeleteObject
		rts
; ===========================================================================
Sign_Index:	dc.w Sign_Main-Sign_Index
		dc.w Sign_Touch-Sign_Index
		dc.w Sign_Spin-Sign_Index
		dc.w Sign_SonicRun-Sign_Index
		dc.w Sign_Exit-Sign_Index

spintime:	equ $30		; time for signpost to spin
sparkletime:	equ $32		; time between sparkles
sparkle_id:	equ $34		; counter to keep track of sparkles
; ===========================================================================

Sign_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Sign,obMap(a0)
		move.w	#$680,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$18,obActWid(a0)
		move.b	#4,obPriority(a0)

Sign_Touch:	; Routine 2
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		blo.s	@notouch
		cmpi.w	#$20,d0		; is Sonic within $20 pixels of the signpost?
		bhs.s	@notouch	; if not, branch
		move.w	#sfx_Signpost,d0
		jsr	(PlaySound).l	; play signpost sound
		clr.b	(f_timecount).w	; stop time counter
		move.w	(v_limitright2).w,(v_limitleft2).w ; lock screen position
		addq.b	#2,obRoutine(a0)

	@notouch:
		rts
; ===========================================================================

Sign_Spin:	; Routine 4
		subq.w	#1,spintime(a0)	; subtract 1 from spin time
		bpl.s	@chksparkle	; if time remains, branch
		move.w	#60,spintime(a0) ; set spin cycle time to 1 second
		addq.b	#1,obAnim(a0)	; next spin cycle
		cmpi.b	#3,obAnim(a0)	; have 3 spin cycles completed?
		bne.s	@chksparkle	; if not, branch
		addq.b	#2,obRoutine(a0)

	@chksparkle:
		subq.w	#1,sparkletime(a0) ; subtract 1 from time delay
		bpl.s	@fail		; if time remains, branch
		move.w	#$B,sparkletime(a0) ; set time between sparkles to $B frames
		moveq	#0,d0
		move.b	sparkle_id(a0),d0 ; get sparkle id
		addq.b	#2,sparkle_id(a0) ; increment sparkle counter
		andi.b	#$E,sparkle_id(a0)
		lea	Sign_SparkPos(pc,d0.w),a2 ; load sparkle position data
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_Rings,0(a1)	; load rings object
		move.b	#id_Ring_Sparkle,obRoutine(a1) ; jump to ring sparkle subroutine
		move.b	(a2)+,d0
		ext.w	d0
		add.w	obX(a0),d0
		move.w	d0,obX(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	obY(a0),d0
		move.w	d0,obY(a1)
		move.l	#Map_Ring,obMap(a1)
		move.w	#$27B2,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#2,obPriority(a1)
		move.b	#8,obActWid(a1)

	@fail:
		rts
; ===========================================================================
Sign_SparkPos:	dc.b -$18,-$10		; x-position, y-position
		dc.b	8,   8
		dc.b -$10,   0
		dc.b  $18,  -8
		dc.b	0,  -8
		dc.b  $10,   0
		dc.b -$18,   8
		dc.b  $18, $10
; ===========================================================================

Sign_SonicRun:	; Routine 6
		tst.w	(v_debuguse).w	; is debug mode on?
		bne.w	locret_ECEE	; if yes, branch
		btst	#1,(v_player+obStatus).w
		bne.s	loc_EC70
		move.b	#1,(f_lockctrl).w ; lock controls
		move.w	#btnR<<8,(v_jpadhold2).w ; make Sonic run to the right

	loc_EC70:
		tst.b	(v_player).w
		beq.s	loc_EC86
		move.w	(v_player+obX).w,d0
		move.w	(v_limitright2).w,d1
		addi.w	#$128,d1
		cmp.w	d1,d0
		blo.s	locret_ECEE

	loc_EC86:
		addq.b	#2,obRoutine(a0)

; ---------------------------------------------------------------------------
; Subroutine to set up bonuses at the end of an	act
; ---------------------------------------------------------------------------

GotThroughAct:
		tst.b	(v_endcard).w
		bne.s	locret_ECEE
		move.w	(v_limitright2).w,(v_limitleft2).w
		clr.b	(v_invinc).w	; disable invincibility
		clr.b	(f_timecount).w	; stop time counter
		move.b	#id_GotThroughCard,(v_endcard).w
		moveq	#plcid_TitleCard,d0
		jsr	(NewPLC).l	; load title card patterns
		move.b	#1,(f_endactbonus).w
		moveq	#0,d0
		move.b	(v_timemin).w,d0
		mulu.w	#60,d0		; convert minutes to seconds
		moveq	#0,d1
		move.b	(v_timesec).w,d1
		add.w	d1,d0		; add up your time
		divu.w	#15,d0		; divide by 15
		moveq	#$14,d1
		cmp.w	d1,d0		; is time 5 minutes or higher?
		blo.s	@hastimebonus	; if not, branch
		move.w	d1,d0		; use minimum time bonus (0)

	@hastimebonus:
		add.w	d0,d0
		move.w	TimeBonuses(pc,d0.w),(v_timebonus).w ; set time bonus
		move.w	(v_rings).w,d0	; load number of rings
		mulu.w	#10,d0		; multiply by 10
		move.w	d0,(v_ringbonus).w ; set ring bonus
		move.w	#bgm_GotThrough,d0
		jsr	(PlaySound_Special).l	; play "Sonic got through" music

locret_ECEE:
		rts
; End of function GotThroughAct

; ===========================================================================
TimeBonuses:	dc.w 5000, 5000, 1000, 500, 400, 400, 300, 300,	200, 200
		dc.w 200, 200, 100, 100, 100, 100, 50, 50, 50, 50, 0
; ===========================================================================

Sign_Exit:	; Routine 8
		rts

		include	"_anim\Signpost.asm"
Map_Sign:	include	"_maps\Signpost.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4C - lava geyser / lavafall producer (MZ)
; ---------------------------------------------------------------------------

; Obj4C:
GeyserMaker:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GMake_Index(pc,d0.w),d1
		jsr	GMake_Index(pc,d1.w)
		bra.w	Geyser_ChkDel
; ===========================================================================
GMake_Index:	dc.w GMake_Main-GMake_Index
		dc.w GMake_Wait-GMake_Index
		dc.w GMake_ChkType-GMake_Index
		dc.w GMake_MakeLava-GMake_Index
		dc.w GMake_Display-GMake_Index
		dc.w GMake_Delete-GMake_Index

gmake_time:	equ $34		; time delay (2 bytes)
gmake_timer:	equ $32		; current time remaining (2 bytes)
gmake_parent:	equ $3C		; address of parent object
; ===========================================================================

GMake_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Geyser,obMap(a0)
		move.w	#$E3A8,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#$38,obActWid(a0)
		move.w	#120,gmake_time(a0) ; set time delay to 2 seconds

GMake_Wait:	; Routine 2
		subq.w	#1,gmake_timer(a0) ; decrement timer
		bpl.s	@cancel		; if time remains, branch

		move.w	gmake_time(a0),gmake_timer(a0) ; reset timer
		move.w	(v_player+obY).w,d0
		move.w	obY(a0),d1
		cmp.w	d1,d0
		bhs.s	@cancel
		subi.w	#$170,d1
		cmp.w	d1,d0
		blo.s	@cancel
		addq.b	#2,obRoutine(a0) ; if Sonic is within range, goto GMake_ChkType

	@cancel:
		rts
; ===========================================================================

GMake_MakeLava:	; Routine 6
		addq.b	#2,obRoutine(a0)
		bsr.w	FindNextFreeObj
		bne.s	@fail
		move.b	#id_LavaGeyser,0(a1) ; load lavafall object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obSubtype(a0),obSubtype(a1)
		move.l	a0,gmake_parent(a1)

	@fail:
		move.b	#1,obAnim(a0)
		tst.b	obSubtype(a0)	; is object type 0 (geyser) ?
		beq.s	@isgeyser	; if yes, branch
		move.b	#4,obAnim(a0)
		bra.s	GMake_Display
; ===========================================================================

	@isgeyser:
		movea.l	gmake_parent(a0),a1 ; get parent object address
		bset	#1,obStatus(a1)
		move.w	#-$580,obVelY(a1)
		bra.s	GMake_Display
; ===========================================================================

GMake_ChkType:	; Routine 4
		tst.b	obSubtype(a0)	; is object type 00 (geyser) ?
		beq.s	GMake_Display	; if yes, branch
		addq.b	#2,obRoutine(a0)
		rts
; ===========================================================================

GMake_Display:	; Routine 8
		lea	(Ani_Geyser).l,a1
		bsr.w	AnimateSprite
		bsr.w	DisplaySprite
		rts
; ===========================================================================

GMake_Delete:	; Routine $A
		move.b	#0,obAnim(a0)
		move.b	#2,obRoutine(a0)
		tst.b	obSubtype(a0)
		beq.w	DeleteObject
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4D - lava geyser / lavafall (MZ)
; ---------------------------------------------------------------------------

; Obj4D:
LavaGeyser:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Geyser_Index(pc,d0.w),d1
		jsr	Geyser_Index(pc,d1.w)
		bra.w	DisplaySprite
; ===========================================================================
Geyser_Index:	dc.w Geyser_Main-Geyser_Index
		dc.w Geyser_Action-Geyser_Index
		dc.w loc_EFFC-Geyser_Index
		dc.w Geyser_Delete-Geyser_Index

Geyser_Speeds:	dc.w $FB00, 0
; ===========================================================================

Geyser_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	obY(a0),$30(a0)
		tst.b	obSubtype(a0)
		beq.s	@isgeyser
		subi.w	#$250,obY(a0)

	@isgeyser:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	Geyser_Speeds(pc,d0.w),obVelY(a0)
		movea.l	a0,a1
		moveq	#1,d1
		bsr.s	@makelava
		bra.s	@activate
; ===========================================================================

	@loop:
		bsr.w	FindNextFreeObj
		bne.s	@fail

@makelava:
		move.b	#id_LavaGeyser,0(a1)
		move.l	#Map_Geyser,obMap(a1)
		move.w	#$63A8,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obSubtype(a0),obSubtype(a1)
		move.b	#1,obPriority(a1)
		move.b	#5,obAnim(a1)
		tst.b	obSubtype(a0)
		beq.s	@fail
		move.b	#2,obAnim(a1)

	@fail:
		dbf	d1,@loop
		rts
; ===========================================================================

@activate:
		addi.w	#$60,obY(a1)
		move.w	$30(a0),$30(a1)
		addi.w	#$60,$30(a1)
		move.b	#$93,obColType(a1)
		move.b	#$80,obHeight(a1)
		bset	#4,obRender(a1)
		addq.b	#4,obRoutine(a1)
		move.l	a0,$3C(a1)
		tst.b	obSubtype(a0)
		beq.s	@sound
		moveq	#0,d1
		bsr.w	@loop
		addq.b	#2,obRoutine(a1)
		bset	#4,obGfx(a1)
		addi.w	#$100,obY(a1)
		move.b	#0,obPriority(a1)
		move.w	$30(a0),$30(a1)
		move.l	$3C(a0),$3C(a1)
		move.b	#0,obSubtype(a0)

	@sound:
		move.w	#sfx_Burning,d0
		jsr	(PlaySound_Special).l	; play flame sound

Geyser_Action:	; Routine 2
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	Geyser_Types(pc,d0.w),d1
		jsr	Geyser_Types(pc,d1.w)
		bsr.w	SpeedToPos
		lea	(Ani_Geyser).l,a1
		bsr.w	AnimateSprite

Geyser_ChkDel:
		out_of_range.w	DeleteObject
		rts
; ===========================================================================
Geyser_Types:	dc.w Geyser_Type00-Geyser_Types
		dc.w Geyser_Type01-Geyser_Types
; ===========================================================================

Geyser_Type00:
		addi.w	#$18,obVelY(a0)	; increase object's falling speed
		move.w	$30(a0),d0
		cmp.w	obY(a0),d0
		bhs.s	locret_EFDA
		addq.b	#4,obRoutine(a0)
		movea.l	$3C(a0),a1
		move.b	#3,obAnim(a1)

locret_EFDA:
		rts
; ===========================================================================

Geyser_Type01:
		addi.w	#$18,obVelY(a0)	; increase object's falling speed
		move.w	$30(a0),d0
		cmp.w	obY(a0),d0
		bhs.s	locret_EFFA
		addq.b	#4,obRoutine(a0)
		movea.l	$3C(a0),a1
		move.b	#1,obAnim(a1)

locret_EFFA:
		rts
; ===========================================================================

loc_EFFC:	; Routine 4
		movea.l	$3C(a0),a1
		cmpi.b	#6,obRoutine(a1)
		beq.w	Geyser_Delete
		move.w	obY(a1),d0
		addi.w	#$60,d0
		move.w	d0,obY(a0)
		sub.w	$30(a0),d0
		neg.w	d0
		moveq	#8,d1
		cmpi.w	#$40,d0
		bge.s	loc_F026
		moveq	#$B,d1

loc_F026:
		cmpi.w	#$80,d0
		ble.s	loc_F02E
		moveq	#$E,d1

loc_F02E:
		subq.b	#1,obTimeFrame(a0)
		bpl.s	loc_F04C
		move.b	#7,obTimeFrame(a0)
		addq.b	#1,obAniFrame(a0)
		cmpi.b	#2,obAniFrame(a0)
		blo.s	loc_F04C
		move.b	#0,obAniFrame(a0)

loc_F04C:
		move.b	obAniFrame(a0),d0
		add.b	d1,d0
		move.b	d0,obFrame(a0)
		bra.w	Geyser_ChkDel
; ===========================================================================

Geyser_Delete:	; Routine 6
		bra.w	DeleteObject

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4E - advancing wall of	lava (MZ)
; ---------------------------------------------------------------------------

; Obj4E:
LavaWall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	LWall_Index(pc,d0.w),d1
		jmp	LWall_Index(pc,d1.w)
; ===========================================================================
LWall_Index:	dc.w LWall_Main-LWall_Index
		dc.w LWall_Solid-LWall_Index
		dc.w LWall_Action-LWall_Index
		dc.w LWall_Move-LWall_Index
		dc.w LWall_Delete-LWall_Index

lwall_flag:	equ $36		; flag to start wall moving
; ===========================================================================

LWall_Main:	; Routine 0
		addq.b	#4,obRoutine(a0)
		movea.l	a0,a1
		moveq	#1,d1
		bra.s	@make
; ===========================================================================

	@loop:
		bsr.w	FindNextFreeObj
		bne.s	@fail

@make:
		move.b	#id_LavaWall,0(a1)	; load object
		move.l	#Map_LWall,obMap(a1)
		move.w	#$63A8,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$50,obActWid(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#1,obPriority(a1)
		move.b	#0,obAnim(a1)
		move.b	#$94,obColType(a1)
		move.l	a0,$3C(a1)

	@fail:
		dbf	d1,@loop	; repeat sequence once

		addq.b	#6,obRoutine(a1)
		move.b	#4,obFrame(a1)

LWall_Action:	; Routine 4
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	@rangechk
		neg.w	d0

	@rangechk:
		cmpi.w	#$C0,d0		; is Sonic within $C0 pixels (x-axis)?
		bhs.s	@movewall	; if not, branch
		move.w	(v_player+obY).w,d0
		sub.w	obY(a0),d0
		bhs.s	@rangechk2
		neg.w	d0

	@rangechk2:
		cmpi.w	#$60,d0		; is Sonic within $60 pixels (y-axis)?
		bhs.s	@movewall	; if not, branch
		move.b	#1,lwall_flag(a0) ; set object to move
		bra.s	LWall_Solid
; ===========================================================================

@movewall:
		tst.b	lwall_flag(a0)	; is object set to move?
		beq.s	LWall_Solid	; if not, branch
		move.w	#$180,obVelX(a0) ; set object speed
		subq.b	#2,$24(a0)

LWall_Solid:	; Routine 2
		move.w	#$2B,d1
		move.w	#$18,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		move.b	obRoutine(a0),d0
		move.w	d0,-(sp)
		bsr.w	SolidObject
		move.w	(sp)+,d0
		move.b	d0,obRoutine(a0)
		cmpi.w	#$6A0,obX(a0)	; has object reached $6A0 on the x-axis?
		bne.s	@animate	; if not, branch
		clr.w	obVelX(a0)	; stop object moving
		clr.b	lwall_flag(a0)

	@animate:
		lea	(Ani_LWall).l,a1
		bsr.w	AnimateSprite
		cmpi.b	#4,(v_player+obRoutine).w
		bhs.s	@rangechk
		bsr.w	SpeedToPos

	@rangechk:
		bsr.w	DisplaySprite
		tst.b	lwall_flag(a0)	; is wall already moving?
		bne.s	@moving		; if yes, branch
		out_of_range.s	@chkgone

	@moving:
		rts
; ===========================================================================

@chkgone:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bclr	#7,2(a2,d0.w)
		move.b	#8,obRoutine(a0)
		rts
; ===========================================================================

LWall_Move:	; Routine 6
		movea.l	$3C(a0),a1
		cmpi.b	#8,obRoutine(a1)
		beq.s	LWall_Delete
		move.w	obX(a1),obX(a0)	; move rest of lava wall
		subi.w	#$80,obX(a0)
		bra.w	DisplaySprite
; ===========================================================================

LWall_Delete:	; Routine 8
		bra.w	DeleteObject

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 54 - invisible lava tag (MZ)
; ---------------------------------------------------------------------------

; Obj54:
LavaTag:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	LTag_Index(pc,d0.w),d1
		jmp	LTag_Index(pc,d1.w)
; ===========================================================================
LTag_Index:	dc.w LTag_Main-LTag_Index
		dc.w LTag_ChkDel-LTag_Index

LTag_ColTypes:	dc.b $96, $94, $95
		even
; ===========================================================================

LTag_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		move.b	LTag_ColTypes(pc,d0.w),obColType(a0)
		move.l	#Map_LTag,obMap(a0)
		move.b	#$84,obRender(a0)

LTag_ChkDel:	; Routine 2
		move.w	obX(a0),d0
		andi.w	#$FF80,d0
		move.w	(v_screenposx).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		bmi.w	DeleteObject
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		rts

Map_LTag:	include	"_maps\Lava Tag.asm"
		include	"_anim\Lava Geyser.asm"
		include	"_anim\Wall of Lava.asm"
Map_Geyser:	include	"_maps\Lava Geyser.asm"
Map_LWall:	include	"_maps\Wall of Lava.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 40 - Moto Bug enemy (GHZ)
; ---------------------------------------------------------------------------

; Obj40:
MotoBug:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Moto_Index(pc,d0.w),d1
		jmp	Moto_Index(pc,d1.w)
; ===========================================================================
Moto_Index:	dc.w Moto_Main-Moto_Index
		dc.w Moto_Action-Moto_Index
		dc.w Moto_Animate-Moto_Index
		dc.w Moto_Delete-Moto_Index
; ===========================================================================

Moto_Main:	; Routine 0
		move.l	#Map_Moto,obMap(a0)
		move.w	#$4F0,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$14,obActWid(a0)
		tst.b	obAnim(a0)	; is object a smoke trail?
		bne.s	@smoke		; if yes, branch
		move.b	#$E,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.b	#$C,obColType(a0)
		bsr.w	ObjectFall
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	@notonfloor
		add.w	d1,obY(a0)	; match object's position with the floor
		move.w	#0,obVelY(a0)
		addq.b	#2,obRoutine(a0) ; goto Moto_Action next
		bchg	#0,obStatus(a0)

	@notonfloor:
		rts
; ===========================================================================

@smoke:
		addq.b	#4,obRoutine(a0) ; goto Moto_Animate next
		bra.w	Moto_Animate
; ===========================================================================

Moto_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Moto_ActIndex(pc,d0.w),d1
		jsr	Moto_ActIndex(pc,d1.w)
		lea	(Ani_Moto).l,a1
		bsr.w	AnimateSprite

; ---------------------------------------------------------------------------
; Subroutine to remember whether an object is destroyed/collected
; ---------------------------------------------------------------------------

; MarkObjGone:
RememberState:
		out_of_range.w	@offscreen
		bra.w	DisplaySprite

	@offscreen:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@delete
		bclr	#7,2(a2,d0.w)

	@delete:
		bra.w	DeleteObject

; ===========================================================================
Moto_ActIndex:	dc.w @move-Moto_ActIndex
		dc.w @findfloor-Moto_ActIndex

@time:		equ $30
@smokedelay:	equ $33
; ===========================================================================

@move:
		subq.w	#1,@time(a0)	; subtract 1 from pause time
		bpl.s	@wait		; if time remains, branch
		addq.b	#2,ob2ndRout(a0)
		move.w	#-$100,obVelX(a0) ; move object to the left
		move.b	#1,obAnim(a0)
		bchg	#0,obStatus(a0)
		bne.s	@wait
		neg.w	obVelX(a0)	; change direction

	@wait:
		rts
; ===========================================================================

@findfloor:
		bsr.w	SpeedToPos
		jsr	(ObjFloorDist).l
		cmpi.w	#-8,d1
		blt.s	@pause
		cmpi.w	#$C,d1
		bge.s	@pause
		add.w	d1,obY(a0)	; match object's position with the floor
		subq.b	#1,@smokedelay(a0)
		bpl.s	@nosmoke
		move.b	#$F,@smokedelay(a0)
		bsr.w	FindFreeObj
		bne.s	@nosmoke
		move.b	#id_MotoBug,0(a1) ; load exhaust smoke object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.b	#2,obAnim(a1)

	@nosmoke:
		rts

@pause:
		subq.b	#2,ob2ndRout(a0)
		move.w	#59,@time(a0)	; set pause time to 1 second
		move.w	#0,obVelX(a0)	; stop the object moving
		move.b	#0,obAnim(a0)
		rts
; ===========================================================================

Moto_Animate:	; Routine 4
		lea	(Ani_Moto).l,a1
		bsr.w	AnimateSprite
		bra.w	DisplaySprite
; ===========================================================================

Moto_Delete:	; Routine 6
		bra.w	DeleteObject

		include	"_anim\Moto Bug.asm"
Map_Moto:	include	"_maps\Moto Bug.asm"

; ---------------------------------------------------------------------------
; Object 4F - blank
; ---------------------------------------------------------------------------

Obj4F:
		rts
		
; ===========================================================================
; ---------------------------------------------------------------------------

; For some reason, this Yadrin code is placed above the object itself
Yad_ChkWall:
		move.w	(v_framecount).w,d0
		add.w	d7,d0
		andi.w	#3,d0
		bne.s	loc_F836
		moveq	#0,d3
		move.b	obActWid(a0),d3
		tst.w	obVelX(a0)
		bmi.s	loc_F82C
		bsr.w	ObjHitWallRight
		tst.w	d1
		bpl.s	loc_F836

loc_F828:
		moveq	#1,d0
		rts
; ===========================================================================

loc_F82C:
		not.w	d3
		bsr.w	ObjHitWallLeft
		tst.w	d1
		bmi.s	loc_F828

loc_F836:
		moveq	#0,d0
		rts
; End of function Yad_ChkWall

; ---------------------------------------------------------------------------
; Object 50 - Yadrin enemy (SYZ)
; ---------------------------------------------------------------------------

; Obj50:
Yadrin:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Yad_Index(pc,d0.w),d1
		jmp	Yad_Index(pc,d1.w)
; ===========================================================================
Yad_Index:	dc.w Yad_Main-Yad_Index
		dc.w Yad_Action-Yad_Index

yad_timedelay:	equ $30
; ===========================================================================

Yad_Main:	; Routine 0
		move.l	#Map_Yad,obMap(a0)
		move.w	#$247B,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$14,obActWid(a0)
		move.b	#$11,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.b	#$CC,obColType(a0)
		bsr.w	ObjectFall
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	locret_F89E
		add.w	d1,obY(a0)	; match object's position with the floor
		move.w	#0,obVelY(a0)
		addq.b	#2,obRoutine(a0)
		bchg	#0,obStatus(a0)

	locret_F89E:
		rts
; ===========================================================================

Yad_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Yad_Index2(pc,d0.w),d1
		jsr	Yad_Index2(pc,d1.w)
		lea	(Ani_Yad).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
Yad_Index2:	dc.w Yad_Move-Yad_Index2
		dc.w Yad_FixToFloor-Yad_Index2
; ===========================================================================

Yad_Move:
		subq.w	#1,yad_timedelay(a0) ; subtract 1 from pause time
		bpl.s	locret_F8E2	; if time remains, branch
		addq.b	#2,ob2ndRout(a0)
		move.w	#-$100,obVelX(a0) ; move object
		move.b	#1,obAnim(a0)
		bchg	#0,obStatus(a0)
		bne.s	locret_F8E2
		neg.w	obVelX(a0)	; change direction

	locret_F8E2:
		rts
; ===========================================================================

Yad_FixToFloor:
		bsr.w	SpeedToPos
		bsr.w	ObjFloorDist
		cmpi.w	#-8,d1
		blt.s	Yad_Pause
		cmpi.w	#$C,d1
		bge.s	Yad_Pause
		add.w	d1,obY(a0)	; match object's position to the floor
		bsr.w	Yad_ChkWall
		bne.s	Yad_Pause
		rts
; ===========================================================================

Yad_Pause:
		subq.b	#2,ob2ndRout(a0)
		move.w	#59,yad_timedelay(a0) ; set pause time to 1 second
		move.w	#0,obVelX(a0)
		move.b	#0,obAnim(a0)
		rts

		include	"_anim\Yadrin.asm"
Map_Yad:	include	"_maps\Yadrin.asm"

; ---------------------------------------------------------------------------
; Solid object subroutine (includes spikes, blocks, rocks etc)
;
; input:
; d1 = width
; d2 = height / 2 (when jumping)
; d3 = height / 2 (when walking)
; d4 = x-axis position
; ---------------------------------------------------------------------------

SolidObject:
		tst.b	obSolid(a0)	; is Sonic standing on the object?
		beq.w	Solid_ChkEnter	; if not, branch
		move.w	d1,d2
		add.w	d2,d2
		lea	(v_player).w,a1
		btst	#1,obStatus(a1)	; is Sonic in the air?
		bne.s	@leave		; if yes, branch
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	@leave		; if Sonic moves off the left, branch
		cmp.w	d2,d0		; has Sonic moved off the right?
		blo.s	@stand		; if not, branch

	@leave:
		bclr	#3,obStatus(a1)	; clear Sonic's standing flag
		bclr	#3,obStatus(a0)	; clear object's standing flag
		clr.b	obSolid(a0)
		moveq	#0,d4
		rts

	@stand:
		move.w	d4,d2
		bsr.w	MvSonicOnPtfm
		moveq	#0,d4
		rts
; ===========================================================================

SolidObject71:
		tst.b	obSolid(a0)
		beq.w	loc_FAD0
		move.w	d1,d2
		add.w	d2,d2
		lea	(v_player).w,a1
		btst	#1,obStatus(a1)
		bne.s	@leave
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	@leave
		cmp.w	d2,d0
		blo.s	@stand

	@leave:
		bclr	#3,obStatus(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)
		moveq	#0,d4
		rts

	@stand:
		move.w	d4,d2
		bsr.w	MvSonicOnPtfm
		moveq	#0,d4
		rts
; ===========================================================================

SolidObject2F:
		lea	(v_player).w,a1
		tst.b	obRender(a0)
		bpl.w	Solid_Ignore
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Solid_Ignore
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	Solid_Ignore
		move.w	d0,d5
		btst	#0,obRender(a0)	; is object horizontally flipped?
		beq.s	@notflipped	; if not, branch
		not.w	d5
		add.w	d3,d5

	@notflipped:
		lsr.w	#1,d5
		moveq	#0,d3
		move.b	(a2,d5.w),d3
		sub.b	(a2),d3
		move.w	obY(a0),d5
		sub.w	d3,d5
		move.b	obHeight(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	obY(a1),d3
		sub.w	d5,d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	Solid_Ignore
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bhs.w	Solid_Ignore
		bra.w	loc_FB0E
; ===========================================================================

Solid_ChkEnter:
		tst.b	obRender(a0)
		bpl.w	Solid_Ignore

loc_FAD0:
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Solid_Ignore	; if Sonic moves off the left, branch
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0		; has Sonic moved off the right?
		bhi.w	Solid_Ignore	; if yes, branch
		move.b	obHeight(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	obY(a1),d3
		sub.w	obY(a0),d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	Solid_Ignore	; if Sonic moves above, branch
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3		; has Sonic moved below?
		bhs.w	Solid_Ignore	; if yes, branch

loc_FB0E:
		tst.b	(f_playerctrl).w ; are object interactions disabled?
		bmi.w	Solid_Ignore	; if yes, branch
		cmpi.b	#6,(v_player+obRoutine).w ; is Sonic dying?
		bhs.w	Solid_Debug
		tst.w	(v_debuguse).w	; is debug mode being used?
		bne.w	Solid_Debug	; if yes, branch
		move.w	d0,d5
		cmp.w	d0,d1		; is Sonic right of centre of object?
		bhs.s	@isright	; if yes, branch
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

	@isright:
		move.w	d3,d1
		cmp.w	d3,d2		; is Sonic below centre of object?
		bhs.s	@isbelow	; if yes, branch

		subq.w	#4,d3
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

	@isbelow:
		cmp.w	d1,d5
		bhi.w	Solid_TopBottom	; if Sonic hits top or bottom, branch
		cmpi.w	#4,d1
		bls.s	Solid_SideAir
		tst.w	d0		; where is Sonic?
		beq.s	Solid_Centre	; if inside the object, branch
		bmi.s	Solid_Right	; if right of the object, branch
		tst.w	obVelX(a1)	; is Sonic moving left?
		bmi.s	Solid_Centre	; if yes, branch
		bra.s	Solid_Left
; ===========================================================================

Solid_Right:
		tst.w	obVelX(a1)	; is Sonic moving right?
		bpl.s	Solid_Centre	; if yes, branch

Solid_Left:
		move.w	#0,obInertia(a1)
		move.w	#0,obVelX(a1)	; stop Sonic moving

Solid_Centre:
		sub.w	d0,obX(a1)	; correct Sonic's position
		btst	#1,obStatus(a1)	; is Sonic in the air?
		bne.s	Solid_SideAir	; if yes, branch
		bset	#5,obStatus(a1)	; make Sonic push object
		bset	#5,obStatus(a0)	; make object be pushed
		moveq	#1,d4		; return side collision
		rts
; ===========================================================================

Solid_SideAir:
		bsr.s	Solid_NotPushing
		moveq	#1,d4		; return side collision
		rts
; ===========================================================================

Solid_Ignore:
		btst	#5,obStatus(a0)	; is Sonic pushing?
		beq.s	Solid_Debug	; if not, branch
		move.w	#id_Run,obAnim(a1) ; use running animation

Solid_NotPushing:
		bclr	#5,obStatus(a0)	; clear pushing flag
		bclr	#5,obStatus(a1)	; clear Sonic's pushing flag

Solid_Debug:
		moveq	#0,d4		; return no collision
		rts
; ===========================================================================

Solid_TopBottom:
		tst.w	d3		; is Sonic below the object?
		bmi.s	Solid_Below	; if yes, branch
		cmpi.w	#$10,d3		; has Sonic landed on the object?
		blo.s	Solid_Landed	; if yes, branch
		bra.s	Solid_Ignore
; ===========================================================================

Solid_Below:
		tst.w	obVelY(a1)	; is Sonic moving vertically?
		beq.s	Solid_Squash	; if not, branch
		bpl.s	Solid_TopBtmAir	; if moving downwards, branch
		tst.w	d3		; is Sonic above the object?
		bpl.s	Solid_TopBtmAir	; if yes, branch
		sub.w	d3,obY(a1)	; correct Sonic's position
		move.w	#0,obVelY(a1)	; stop Sonic moving

Solid_TopBtmAir:
		moveq	#-1,d4
		rts
; ===========================================================================

Solid_Squash:
		btst	#1,obStatus(a1)	; is Sonic in the air?
		bne.s	Solid_TopBtmAir	; if yes, branch
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	(KillSonic).l	; kill Sonic
		movea.l	(sp)+,a0
		moveq	#-1,d4
		rts
; ===========================================================================

Solid_Landed:
		subq.w	#4,d3
		moveq	#0,d1
		move.b	obActWid(a0),d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	obX(a1),d1
		sub.w	obX(a0),d1
		bmi.s	Solid_Miss	; if Sonic is right of object, branch
		cmp.w	d2,d1		; is Sonic left of object?
		bhs.s	Solid_Miss	; if yes, branch
		tst.w	obVelY(a1)	; is Sonic moving upwards?
		bmi.s	Solid_Miss	; if yes, branch
		sub.w	d3,obY(a1)	; correct Sonic's position
		subq.w	#1,obY(a1)
		bsr.s	Solid_ResetFloor
		move.b	#2,obSolid(a0) ; set standing flags
		bset	#3,obStatus(a0)
		moveq	#-1,d4		; return top/bottom collision
		rts
; ===========================================================================

Solid_Miss:
		moveq	#0,d4
		rts
; End of function SolidObject

Solid_ResetFloor:
		btst	#3,obStatus(a1)	; is Sonic standing on something?
		beq.s	@notonobj	; if not, branch

		moveq	#0,d0
		move.b	standonobject(a1),d0	; get object being stood on
		lsl.w	#6,d0
		addi.l	#(v_objspace&$FFFFFF),d0
		movea.l	d0,a2
		bclr	#3,obStatus(a2)	; clear object's standing flags
		clr.b	obSolid(a2)

	@notonobj:
		move.w	a0,d0
		subi.w	#v_objspace&$FFFF,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,standonobject(a1)	; set object being stood on
		move.b	#0,obAngle(a1)	; clear Sonic's angle
		move.w	#0,obVelY(a1)	; stop Sonic
		move.w	obVelX(a1),obInertia(a1)
		btst	#1,obStatus(a1)	; is Sonic in the air?
		beq.s	@notinair	; if not, branch
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	(Sonic_ResetOnFloor).l ; reset Sonic as if on floor
		movea.l	(sp)+,a0

	@notinair:
		bset	#3,obStatus(a1)	; set object standing flag
		bset	#3,obStatus(a0)	; set Sonic standing on object flag
		rts
; End of function Solid_ResetFloor

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 51 - smashable green block (MZ)
; ---------------------------------------------------------------------------

; Obj51:
SmashBlock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Smab_Index(pc,d0.w),d1
		jsr	Smab_Index(pc,d1.w)
		bra.w	RememberState
; ===========================================================================
Smab_Index:	dc.w Smab_Main-Smab_Index
		dc.w Smab_Solid-Smab_Index
		dc.w Smab_Points-Smab_Index
; ===========================================================================

Smab_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Smab,obMap(a0)
		move.w	#$42B8,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)
		move.b	obSubtype(a0),obFrame(a0)

Smab_Solid:	; Routine 2

sonicAniFrame:	equ $32		; Sonic's current animation number
@count:		equ $34		; number of blocks hit + previous stuff

		move.w	(v_itembonus).w,$34(a0)
		move.b	(v_player+obAnim).w,sonicAniFrame(a0) ; load Sonic's animation number
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		btst	#3,obStatus(a0)	; has Sonic landed on the block?
		bne.s	@smash		; if yes, branch

	@notspinning:
		rts
; ===========================================================================

@smash:
		cmpi.b	#id_Roll,sonicAniFrame(a0) ; is Sonic rolling/jumping?
		bne.s	@notspinning	; if not, branch
		move.w	@count(a0),(v_itembonus).w
		bset	#2,obStatus(a1)
		move.b	#$E,obHeight(a1)
		move.b	#7,obWidth(a1)
		move.b	#id_Roll,obAnim(a1) ; make Sonic roll
		move.w	#-$300,obVelY(a1) ; rebound Sonic
		bset	#1,obStatus(a1)
		bclr	#3,obStatus(a1)
		move.b	#2,obRoutine(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)
		move.b	#1,obFrame(a0)
		lea	(Smab_Speeds).l,a4 ; load broken fragment speed data
		moveq	#3,d1		; set number of fragments to 4
		move.w	#$38,d2
		bsr.w	SmashObject
		bsr.w	FindFreeObj
		bne.s	Smab_Points
		move.b	#id_Points,0(a1) ; load points object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	(v_itembonus).w,d2
		addq.w	#2,(v_itembonus).w ; increment bonus counter
		cmpi.w	#6,d2		; have fewer than 3 blocks broken?
		blo.s	@bonus		; if yes, branch
		moveq	#6,d2		; set cap for points

	@bonus:
		moveq	#0,d0
		move.w	Smab_Scores(pc,d2.w),d0
		cmpi.w	#$20,(v_itembonus).w ; have 16 blocks been smashed?
		blo.s	@givepoints	; if not, branch
		move.w	#1000,d0	; give higher points for 16th block
		moveq	#10,d2

	@givepoints:
		jsr	(AddPoints).l
		lsr.w	#1,d2
		move.b	d2,obFrame(a1)

Smab_Points:	; Routine 4
		bsr.w	SpeedToPos
		addi.w	#$38,obVelY(a0)
		bsr.w	DisplaySprite
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		rts
; ===========================================================================
Smab_Speeds:	dc.w -$200, -$200	; x-speed, y-speed
		dc.w -$100, -$100
		dc.w $200, -$200
		dc.w $100, -$100

Smab_Scores:	dc.w 10, 20, 50, 100

Map_Smab:	include	"_maps\Smashable Green Block.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 52 - moving platform blocks (MZ, LZ, SBZ)
; ---------------------------------------------------------------------------

; Obj52:
MovingBlock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	MBlock_Index(pc,d0.w),d1
		jmp	MBlock_Index(pc,d1.w)
; ===========================================================================
MBlock_Index:	dc.w MBlock_Main-MBlock_Index
		dc.w MBlock_Platform-MBlock_Index
		dc.w MBlock_StandOn-MBlock_Index

mblock_origX:	equ $30
mblock_origY:	equ $32

MBlock_Var:	dc.b $10, 0		; object width, frame number
		dc.b $20, 1
		dc.b $20, 2
		dc.b $40, 3
		dc.b $30, 4
; ===========================================================================

MBlock_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_MBlock,obMap(a0)
		move.w	#$42B8,obGfx(a0)
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		bne.s	loc_FE44
		move.l	#Map_MBlockLZ,obMap(a0) ; LZ specific code
		move.w	#$43BC,obGfx(a0)
		move.b	#7,obHeight(a0)

loc_FE44:
		cmpi.b	#id_SBZ,(v_zone).w ; check if level is SBZ
		bne.s	loc_FE60
		move.w	#$22C0,obGfx(a0) ; SBZ specific code (object 5228)
		cmpi.b	#$28,obSubtype(a0) ; is object 5228 ?
		beq.s	loc_FE60	; if yes, branch
		move.w	#$4460,obGfx(a0) ; SBZ specific code (object 523x)

loc_FE60:
		move.b	#4,obRender(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	MBlock_Var(pc,d0.w),a2
		move.b	(a2)+,obActWid(a0)
		move.b	(a2)+,obFrame(a0)
		move.b	#4,obPriority(a0)
		move.w	obX(a0),mblock_origX(a0)
		move.w	obY(a0),mblock_origY(a0)
		andi.b	#$F,obSubtype(a0)

MBlock_Platform: ; Routine 2
		bsr.w	MBlock_Move
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(PlatformObject).l
		bra.s	MBlock_ChkDel
; ===========================================================================

MBlock_StandOn:	; Routine 4
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(ExitPlatform).l
		move.w	obX(a0),-(sp)
		bsr.w	MBlock_Move
		move.w	(sp)+,d2
		jsr	(MvSonicOnPtfm2).l

MBlock_ChkDel:
		out_of_range.w	DeleteObject,mblock_origX(a0)
		bra.w	DisplaySprite
; ===========================================================================

MBlock_Move:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	MBlock_TypeIndex(pc,d0.w),d1
		jmp	MBlock_TypeIndex(pc,d1.w)
; ===========================================================================
MBlock_TypeIndex:dc.w MBlock_Type00-MBlock_TypeIndex, MBlock_Type01-MBlock_TypeIndex
		dc.w MBlock_Type02-MBlock_TypeIndex, MBlock_Type03-MBlock_TypeIndex
		dc.w MBlock_Type02-MBlock_TypeIndex, MBlock_Type05-MBlock_TypeIndex
		dc.w MBlock_Type06-MBlock_TypeIndex, MBlock_Type07-MBlock_TypeIndex
		dc.w MBlock_Type08-MBlock_TypeIndex, MBlock_Type02-MBlock_TypeIndex
		dc.w MBlock_Type0A-MBlock_TypeIndex
; ===========================================================================

MBlock_Type00:
		rts
; ===========================================================================

MBlock_Type01:
		move.b	(v_oscillate+$E).w,d0
		move.w	#$60,d1
		btst	#0,obStatus(a0)
		beq.s	loc_FF26
		neg.w	d0
		add.w	d1,d0

loc_FF26:
		move.w	mblock_origX(a0),d1
		sub.w	d0,d1
		move.w	d1,obX(a0)
		rts
; ===========================================================================

MBlock_Type02:
		cmpi.b	#4,obRoutine(a0) ; is Sonic standing on the platform?
		bne.s	MBlock_02_Wait
		addq.b	#1,obSubtype(a0) ; if yes, add 1 to type

MBlock_02_Wait:
		rts
; ===========================================================================

MBlock_Type03:
		moveq	#0,d3
		move.b	obActWid(a0),d3
		bsr.w	ObjHitWallRight
		tst.w	d1		; has the platform hit a wall?
		bmi.s	MBlock_03_End	; if yes, branch
		addq.w	#1,obX(a0)	; move platform to the right
		move.w	obX(a0),mblock_origX(a0)
		rts
; ===========================================================================

MBlock_03_End:
		clr.b	obSubtype(a0)	; change to type 00 (non-moving type)
		rts
; ===========================================================================

MBlock_Type05:
		moveq	#0,d3
		move.b	obActWid(a0),d3
		bsr.w	ObjHitWallRight
		tst.w	d1		; has the platform hit a wall?
		bmi.s	MBlock_05_End	; if yes, branch
		addq.w	#1,obX(a0)	; move platform to the right
		move.w	obX(a0),mblock_origX(a0)
		rts
; ===========================================================================

MBlock_05_End:
		addq.b	#1,obSubtype(a0) ; change to type 06 (falling)
		rts
; ===========================================================================

MBlock_Type06:
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; make the platform fall
		bsr.w	ObjFloorDist
		tst.w	d1		; has platform hit the floor?
		bpl.w	locret_FFA0	; if not, branch
		add.w	d1,obY(a0)
		clr.w	obVelY(a0)	; stop platform falling
		clr.b	obSubtype(a0)	; change to type 00 (non-moving)

locret_FFA0:
		rts
; ===========================================================================

MBlock_Type07:
		tst.b	(f_switch+2).w	; has switch number 02 been pressed?
		beq.s	MBlock_07_ChkDel
		subq.b	#3,obSubtype(a0) ; if yes, change object type to 04

MBlock_07_ChkDel:
		addq.l	#4,sp
		out_of_range.w	DeleteObject,mblock_origX(a0)
		rts
; ===========================================================================

MBlock_Type08:
		move.b	(v_oscillate+$1E).w,d0
		move.w	#$80,d1
		btst	#0,obStatus(a0)
		beq.s	loc_FFE2
		neg.w	d0
		add.w	d1,d0

loc_FFE2:
		move.w	mblock_origY(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)
		rts
; ===========================================================================

MBlock_Type0A:
		moveq	#0,d3
		move.b	obActWid(a0),d3
		add.w	d3,d3
		moveq	#8,d1
		btst	#0,obStatus(a0)
		beq.s	loc_10004
		neg.w	d1
		neg.w	d3

loc_10004:
		tst.w	$36(a0)		; is platform set to move back?
		bne.s	MBlock_0A_Back	; if yes, branch
		move.w	obX(a0),d0
		sub.w	mblock_origX(a0),d0
		cmp.w	d3,d0
		beq.s	MBlock_0A_Wait
		add.w	d1,obX(a0)	; move platform
		move.w	#300,$34(a0)	; set time delay to 5 seconds
		rts
; ===========================================================================

MBlock_0A_Wait:
		subq.w	#1,$34(a0)	; subtract 1 from time delay
		bne.s	locret_1002E	; if time remains, branch
		move.w	#1,$36(a0)	; set platform to move back to its original position

locret_1002E:
		rts
; ===========================================================================

MBlock_0A_Back:
		move.w	obX(a0),d0
		sub.w	mblock_origX(a0),d0
		beq.s	MBlock_0A_Reset
		sub.w	d1,obX(a0)	; return platform to its original position
		rts
; ===========================================================================

MBlock_0A_Reset:
		clr.w	$36(a0)
		subq.b	#1,obSubtype(a0)
		rts

Map_MBlock:	include	"_maps\Moving Blocks (MZ and SBZ).asm"
Map_MBlockLZ:	include	"_maps\Moving Blocks (LZ).asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 55 - Basaran enemy (MZ)
; ---------------------------------------------------------------------------

; Obj55:
Basaran:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bas_Index(pc,d0.w),d1
		jmp	Bas_Index(pc,d1.w)
; ===========================================================================
Bas_Index:	dc.w Bas_Main-Bas_Index
		dc.w Bas_Action-Bas_Index
; ===========================================================================

Bas_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bas,obMap(a0)
		move.w	#$84B8,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$C,obHeight(a0)
		move.b	#2,obPriority(a0)
		move.b	#$B,obColType(a0)
		move.b	#$10,obActWid(a0)

Bas_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		lea	(Ani_Bas).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
@index:		dc.w @dropcheck-@index
		dc.w @dropfly-@index
		dc.w @flapsound-@index
		dc.w @flyup-@index
; ===========================================================================

@dropcheck:
		move.w	#$80,d2
		bsr.w	@chkdistance	; is Sonic < $80 pixels from basaran?
		bhs.s	@nodrop		; if not, branch
		move.w	(v_player+obY).w,d0
		move.w	d0,$36(a0)
		sub.w	obY(a0),d0
		blo.s	@nodrop
		cmpi.w	#$80,d0		; is Sonic < $80 pixels from basaran?
		bhs.s	@nodrop		; if not, branch
		tst.w	(v_debuguse).w	; is debug mode on?
		bne.s	@nodrop		; if yes, branch

		move.b	(v_vbla_byte).w,d0
		add.b	d7,d0
		andi.b	#7,d0
		bne.s	@nodrop
		move.b	#1,obAnim(a0)
		addq.b	#2,ob2ndRout(a0)

	@nodrop:
		rts
; ===========================================================================

@dropfly:
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)	; make basaran fall
		move.w	#$80,d2
		bsr.w	@chkdistance
		move.w	$36(a0),d0
		sub.w	obY(a0),d0
		blo.s	@chkdel
		cmpi.w	#$10,d0		; is basaran close to Sonic vertically?
		bhs.s	@dropmore	; if not, branch
		move.w	d1,obVelX(a0)	; make basaran fly horizontally
		move.w	#0,obVelY(a0)	; stop basaran falling
		move.b	#2,obAnim(a0)
		addq.b	#2,ob2ndRout(a0)

	@dropmore:
		rts

	@chkdel:
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		rts
; ===========================================================================

@flapsound:
		move.b	(v_vbla_byte).w,d0
		andi.b	#$F,d0
		bne.s	@nosound
		move.w	#sfx_Basaran,d0
		jsr	(PlaySound_Special).l	; play flapping sound every 16th frame

	@nosound:
		bsr.w	SpeedToPos
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	@isright	; if Sonic is right of basaran, branch
		neg.w	d0

	@isright:
		cmpi.w	#$80,d0		; is Sonic within $80 pixels of basaran?
		blo.s	@dontflyup	; if yes, branch
		move.b	(v_vbla_byte).w,d0
		add.b	d7,d0
		andi.b	#7,d0
		bne.s	@dontflyup
		addq.b	#2,ob2ndRout(a0)

@dontflyup:
		rts
; ===========================================================================

@flyup:
		bsr.w	SpeedToPos
		subi.w	#$18,obVelY(a0)	; make basaran fly upwards
		bsr.w	ObjHitCeiling
		tst.w	d1		; has basaran hit the ceiling?
		bpl.s	@noceiling	; if not, branch
		sub.w	d1,obY(a0)
		andi.w	#$FFF8,obX(a0)
		clr.w	obVelX(a0)	; stop basaran moving
		clr.w	obVelY(a0)
		clr.b	obAnim(a0)
		clr.b	ob2ndRout(a0)

	@noceiling:
		rts
; ===========================================================================

; Subroutine to check Sonic's distance from the basaran

; input:
; d2 = distance to compare

; output:
; d0 = distance between Sonic and basaran
; d1 = speed/direction for basaran to fly

@chkdistance:
		move.w	#$100,d1
		bset	#0,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	@right		; if Sonic is right of basaran, branch
		neg.w	d0
		neg.w	d1
		bclr	#0,obStatus(a0)

	@right:
		cmp.w	d2,d0
		rts
; ===========================================================================

		include	"_anim\Basaran.asm"
Map_Bas:	include	"_maps\Basaran.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 56 - floating blocks (SYZ/SLZ), large doors (LZ)
; ---------------------------------------------------------------------------

; Obj56:
FloatingBlock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	FBlock_Index(pc,d0.w),d1
		jmp	FBlock_Index(pc,d1.w)
; ===========================================================================
FBlock_Index:	dc.w FBlock_Main-FBlock_Index
		dc.w FBlock_Action-FBlock_Index

fb_origX:	equ $34		; original x-axis position
fb_origY:	equ $30		; original y-axis position
fb_height:	equ $3A		; total object height
fb_type:		equ $3C		; subtype (2nd digit only)

FBlock_Var:	; width/2, height/2
		dc.b  $10, $10	; subtype 0x/8x
		dc.b  $20, $20	; subtype 1x/9x
		dc.b  $10, $20	; subtype 2x/Ax
		dc.b  $20, $1A	; subtype 3x/Bx
		dc.b  $10, $27	; subtype 4x/Cx
		dc.b  $10, $10	; subtype 5x/Dx
		dc.b	8, $20	; subtype 6x/Ex
		dc.b  $40, $10	; subtype 7x/Fx
; ===========================================================================

FBlock_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_FBlock,obMap(a0)
		move.w	#$4000,obGfx(a0)
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		bne.s	@notLZ
		move.w	#$43C4,obGfx(a0) ; LZ specific code

	@notLZ:
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get subtype
		lsr.w	#3,d0
		andi.w	#$E,d0		; read only the 1st digit
		lea	FBlock_Var(pc,d0.w),a2 ; get size data
		move.b	(a2)+,obActWid(a0)
		move.b	(a2),obHeight(a0)
		lsr.w	#1,d0
		move.b	d0,obFrame(a0)
		move.w	obX(a0),fb_origX(a0)
		move.w	obY(a0),fb_origY(a0)
		moveq	#0,d0
		move.b	(a2),d0
		add.w	d0,d0
		move.w	d0,fb_height(a0)
		cmpi.b	#$37,obSubtype(a0)
		bne.s	@dontdelete
		cmpi.w	#$1BB8,obX(a0)
		bne.s	@notatpos
		tst.b	($FFFFF7CE).w
		beq.s	@dontdelete
		jmp	(DeleteObject).l

	@notatpos:
		clr.b	obSubtype(a0)
		tst.b	($FFFFF7CE).w
		bne.s	@dontdelete
		jmp	(DeleteObject).l

	@dontdelete:
		moveq	#0,d0
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		beq.s	@stillnotLZ
		move.b	obSubtype(a0),d0 ; SYZ/SLZ specific code
		andi.w	#$F,d0
		subq.w	#8,d0
		blo.s	@stillnotLZ
		lsl.w	#2,d0
		lea	(v_oscillate+$2C).w,a2
		lea	(a2,d0.w),a2
		tst.w	(a2)
		bpl.s	@stillnotLZ
		bchg	#0,obStatus(a0)

	@stillnotLZ:
		move.b	obSubtype(a0),d0
		bpl.s	FBlock_Action
		andi.b	#$F,d0
		move.b	d0,fb_type(a0)
		move.b	#5,obSubtype(a0)
		cmpi.b	#7,obFrame(a0)
		bne.s	@chkstate
		move.b	#$C,obSubtype(a0)
		move.w	#$80,fb_height(a0)

@chkstate:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	FBlock_Action
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)
		beq.s	FBlock_Action
		addq.b	#1,obSubtype(a0)
		clr.w	fb_height(a0)

FBlock_Action:	; Routine 2
		move.w	obX(a0),-(sp)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object subtype
		andi.w	#$F,d0		; read only the 2nd digit
		add.w	d0,d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)	; move block subroutines
		move.w	(sp)+,d4
		tst.b	obRender(a0)
		bpl.s	@chkdel
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	obHeight(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	SolidObject

	@chkdel:
		out_of_range.s	@chkdel2,fb_origX(a0)
	@display:
		bra.w	DisplaySprite
	@chkdel2:
		cmpi.b	#$37,obSubtype(a0)
		bne.s	@delete
		tst.b	$38(a0)
		bne.s	@display
	@delete:
		jmp	(DeleteObject).l
; ===========================================================================
@index:		dc.w @type00-@index, @type01-@index
		dc.w @type02-@index, @type03-@index
		dc.w @type04-@index, @type05-@index
		dc.w @type06-@index, @type07-@index
		dc.w @type08-@index, @type09-@index
		dc.w @type0A-@index, @type0B-@index
		dc.w @type0C-@index, @type0D-@index
; ===========================================================================

@type00:
; doesn't move
		rts
; ===========================================================================

@type01:
; moves side-to-side
		move.w	#$40,d1		; set move distance
		moveq	#0,d0
		move.b	(v_oscillate+$A).w,d0
		bra.s	@moveLR
; ===========================================================================

@type02:
; moves side-to-side
		move.w	#$80,d1		; set move distance
		moveq	#0,d0
		move.b	(v_oscillate+$1E).w,d0

	@moveLR:
		btst	#0,obStatus(a0)
		beq.s	@noflip
		neg.w	d0
		add.w	d1,d0

	@noflip:
		move.w	fb_origX(a0),d1
		sub.w	d0,d1
		move.w	d1,obX(a0)	; move object horizontally
		rts
; ===========================================================================

@type03:
; moves up/down
		move.w	#$40,d1		; set move distance
		moveq	#0,d0
		move.b	(v_oscillate+$A).w,d0
		bra.s	@moveUD
; ===========================================================================

@type04:
; moves up/down
		move.w	#$80,d1		; set move distance
		moveq	#0,d0
		move.b	(v_oscillate+$1E).w,d0

	@moveUD:
		btst	#0,obStatus(a0)
		beq.s	@noflip04
		neg.w	d0
		add.w	d1,d0

	@noflip04:
		move.w	fb_origY(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)	; move object vertically
		rts
; ===========================================================================

@type05:
; moves up when a switch is pressed
		tst.b	$38(a0)
		bne.s	@loc_104A4
		cmpi.w	#(id_LZ<<8)+0,(v_zone).w ; is level LZ1 ?
		bne.s	@aaa		; if not, branch
		cmpi.b	#3,fb_type(a0)
		bne.s	@aaa
		clr.b	(f_wtunnelallow).w
		move.w	(v_player+obX).w,d0
		cmp.w	obX(a0),d0
		bhs.s	@aaa
		move.b	#1,(f_wtunnelallow).w

	@aaa:
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	fb_type(a0),d0
		btst	#0,(a2,d0.w)
		beq.s	@loc_104AE
		cmpi.w	#(id_LZ<<8)+0,(v_zone).w ; is level LZ1 ?
		bne.s	@loc_1049E	; if not, branch
		cmpi.b	#3,d0
		bne.s	@loc_1049E
		clr.b	(f_wtunnelallow).w

@loc_1049E:
		move.b	#1,$38(a0)

@loc_104A4:
		tst.w	fb_height(a0)
		beq.s	@loc_104C8
		subq.w	#2,fb_height(a0)

@loc_104AE:
		move.w	fb_height(a0),d0
		btst	#0,$22(a0)
		beq.s	@loc_104BC
		neg.w	d0

@loc_104BC:
		move.w	fb_origY(a0),d1
		add.w	d0,d1
		move.w	d1,obY(a0)
		rts
; ===========================================================================

@loc_104C8:
		addq.b	#1,$28(a0)
		clr.b	$38(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@loc_104AE
		bset	#0,2(a2,d0.w)
		bra.s	@loc_104AE
; ===========================================================================

@type06:
		tst.b	$38(a0)
		bne.s	@loc_10500
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	fb_type(a0),d0
		tst.b	(a2,d0.w)
		bpl.s	@loc_10512
		move.b	#1,$38(a0)

@loc_10500:
		moveq	#0,d0
		move.b	obHeight(a0),d0
		add.w	d0,d0
		cmp.w	fb_height(a0),d0
		beq.s	@loc_1052C
		addq.w	#2,fb_height(a0)

@loc_10512:
		move.w	fb_height(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@loc_10520
		neg.w	d0

@loc_10520:
		move.w	fb_origY(a0),d1
		add.w	d0,d1
		move.w	d1,obY(a0)
		rts
; ===========================================================================

@loc_1052C:
		subq.b	#1,obSubtype(a0)
		clr.b	$38(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@loc_10512
		bclr	#0,2(a2,d0.w)
		bra.s	@loc_10512
; ===========================================================================

@type07:
		tst.b	$38(a0)
		bne.s	@loc_1055E
		tst.b	(f_switch+$F).w	; has switch number $F been pressed?
		beq.s	@locret_10578
		move.b	#1,$38(a0)
		clr.w	fb_height(a0)

@loc_1055E:
		addq.w	#1,obX(a0)
		move.w	obX(a0),fb_origX(a0)
		addq.w	#1,fb_height(a0)
		cmpi.w	#$380,fb_height(a0)
		bne.s	@locret_10578
		move.b	#1,($FFFFF7CE).w
		clr.b	$38(a0)
		clr.b	obSubtype(a0)

@locret_10578:
		rts
; ===========================================================================

@type0C:
		tst.b	$38(a0)
		bne.s	@loc_10598
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	fb_type(a0),d0
		btst	#0,(a2,d0.w)
		beq.s	@loc_105A2
		move.b	#1,$38(a0)

@loc_10598:
		tst.w	fb_height(a0)
		beq.s	@loc_105C0
		subq.w	#2,fb_height(a0)

@loc_105A2:
		move.w	fb_height(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@loc_105B4
		neg.w	d0
		addi.w	#$80,d0

@loc_105B4:
		move.w	fb_origX(a0),d1
		add.w	d0,d1
		move.w	d1,obX(a0)
		rts
; ===========================================================================

@loc_105C0:
		addq.b	#1,obSubtype(a0)
		clr.b	$38(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@loc_105A2
		bset	#0,2(a2,d0.w)
		bra.s	@loc_105A2
; ===========================================================================

@type0D:
		tst.b	$38(a0)
		bne.s	@loc_105F8
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	fb_type(a0),d0
		tst.b	(a2,d0.w)
		bpl.s	@wtf
		move.b	#1,$38(a0)

@loc_105F8:
		move.w	#$80,d0
		cmp.w	fb_height(a0),d0
		beq.s	@loc_10624
		addq.w	#2,fb_height(a0)

@wtf:
		move.w	fb_height(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@loc_10618
		neg.w	d0
		addi.w	#$80,d0

@loc_10618:
		move.w	fb_origX(a0),d1
		add.w	d0,d1
		move.w	d1,obX(a0)
		rts
; ===========================================================================

@loc_10624:
		subq.b	#1,obSubtype(a0)
		clr.b	$38(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@wtf
		bclr	#0,2(a2,d0.w)
		bra.s	@wtf
; ===========================================================================

@type08:
		move.w	#$10,d1
		moveq	#0,d0
		move.b	(v_oscillate+$2A).w,d0
		lsr.w	#1,d0
		move.w	(v_oscillate+$2C).w,d3
		bra.s	@square
; ===========================================================================

@type09:
		move.w	#$30,d1
		moveq	#0,d0
		move.b	(v_oscillate+$2E).w,d0
		move.w	(v_oscillate+$30).w,d3
		bra.s	@square
; ===========================================================================

@type0A:
		move.w	#$50,d1
		moveq	#0,d0
		move.b	(v_oscillate+$32).w,d0
		move.w	(v_oscillate+$34).w,d3
		bra.s	@square
; ===========================================================================

@type0B:
		move.w	#$70,d1
		moveq	#0,d0
		move.b	(v_oscillate+$36).w,d0
		move.w	(v_oscillate+$38).w,d3

@square:
		tst.w	d3
		bne.s	@loc_1068E
		addq.b	#1,obStatus(a0)
		andi.b	#3,obStatus(a0)

@loc_1068E:
		move.b	obStatus(a0),d2
		andi.b	#3,d2
		bne.s	@loc_106AE
		sub.w	d1,d0
		add.w	fb_origX(a0),d0
		move.w	d0,obX(a0)
		neg.w	d1
		add.w	fb_origY(a0),d1
		move.w	d1,obY(a0)
		rts
; ===========================================================================

@loc_106AE:
		subq.b	#1,d2
		bne.s	@loc_106CC
		subq.w	#1,d1
		sub.w	d1,d0
		neg.w	d0
		add.w	fb_origY(a0),d0
		move.w	d0,obY(a0)
		addq.w	#1,d1
		add.w	fb_origX(a0),d1
		move.w	d1,obX(a0)
		rts
; ===========================================================================

@loc_106CC:
		subq.b	#1,d2
		bne.s	@loc_106EA
		subq.w	#1,d1
		sub.w	d1,d0
		neg.w	d0
		add.w	fb_origX(a0),d0
		move.w	d0,obX(a0)
		addq.w	#1,d1
		add.w	fb_origY(a0),d1
		move.w	d1,obY(a0)
		rts
; ===========================================================================

@loc_106EA:
		sub.w	d1,d0
		add.w	fb_origY(a0),d0
		move.w	d0,obY(a0)
		neg.w	d1
		add.w	fb_origX(a0),d1
		move.w	d1,obX(a0)
		rts

Map_FBlock:	include	"_maps\Floating Blocks and Doors.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 57 - spiked balls (SYZ, LZ)
; ---------------------------------------------------------------------------

; Obj57:
SpikeBall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	SBall_Index(pc,d0.w),d1
		jmp	SBall_Index(pc,d1.w)
; ===========================================================================
SBall_Index:	dc.w SBall_Main-SBall_Index
		dc.w SBall_Move-SBall_Index
		dc.w SBall_Display-SBall_Index

sball_childs:	equ $29		; number of child objects (1 byte)
		; $30-$37 ; object RAM numbers of childs (1 byte each)
sball_origX:	equ $3A		; centre x-axis position (2 bytes)
sball_origY:	equ $38		; centre y-axis position (2 bytes)
sball_radius:	equ $3C		; radius (1 byte)
sball_speed:	equ $3E		; rate of spin (2 bytes)
; ===========================================================================

SBall_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_SBall,obMap(a0)
		move.w	#$3BA,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.w	obX(a0),sball_origX(a0)
		move.w	obY(a0),sball_origY(a0)
		move.b	#$98,obColType(a0) ; SYZ specific code (chain hurts Sonic)
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		bne.s	@notlz

		move.b	#0,obColType(a0) ; LZ specific code (chain doesn't hurt)
		move.w	#$310,obGfx(a0)
		move.l	#Map_SBall2,obMap(a0)

	@notlz:
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F0,d1		; read only the 1st digit
		ext.w	d1
		asl.w	#3,d1		; multiply by 8
		move.w	d1,sball_speed(a0) ; set object twirl speed
		move.b	obStatus(a0),d0
		ror.b	#2,d0
		andi.b	#$C0,d0
		move.b	d0,obAngle(a0)
		lea	sball_childs(a0),a2
		move.b	obSubtype(a0),d1 ; get object type
		andi.w	#7,d1		; read only the 2nd digit
		move.b	#0,(a2)+
		move.w	d1,d3
		lsl.w	#4,d3
		move.b	d3,sball_radius(a0)
		subq.w	#1,d1		; set chain length (type-1)
		blo.s	@fail
		btst	#3,obSubtype(a0)
		beq.s	@makechain
		subq.w	#1,d1
		blo.s	@fail

@makechain:
		bsr.w	FindFreeObj
		bne.s	@fail
		addq.b	#1,sball_childs(a0) ; increment child object counter
		move.w	a1,d5		; get child object RAM address
		subi.w	#v_objspace&$FFFF,d5 ; subtract base address
		lsr.w	#6,d5		; divide by $40
		andi.w	#$7F,d5
		move.b	d5,(a2)+	; copy child RAM number
		move.b	#4,obRoutine(a1)
		move.b	0(a0),0(a1)
		move.l	obMap(a0),obMap(a1)
		move.w	obGfx(a0),obGfx(a1)
		move.b	obRender(a0),obRender(a1)
		move.b	obPriority(a0),obPriority(a1)
		move.b	obActWid(a0),obActWid(a1)
		move.b	obColType(a0),obColType(a1)
		subi.b	#$10,d3
		move.b	d3,sball_radius(a1)
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		bne.s	@notlzagain

		tst.b	d3
		bne.s	@notlzagain
		move.b	#2,obFrame(a1)	; use different frame for LZ chain

	@notlzagain:
		dbf	d1,@makechain ; repeat for length of chain

	@fail:
		move.w	a0,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		bne.s	SBall_Move

		move.b	#$8B,obColType(a0) ; if yes, make last spikeball larger
		move.b	#1,obFrame(a0)	; use different frame

SBall_Move:	; Routine 2
		bsr.w	@movesub
		bra.w	@chkdel
; ===========================================================================

@movesub:
		move.w	sball_speed(a0),d0
		add.w	d0,obAngle(a0)
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		move.w	sball_origY(a0),d2
		move.w	sball_origX(a0),d3
		lea	sball_childs(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

	@loop:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#v_objspace&$FFFFFF,d4
		movea.l	d4,a1
		moveq	#0,d4
		move.b	sball_radius(a1),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,obY(a1)
		move.w	d5,obX(a1)
		dbf	d6,@loop
		rts
; ===========================================================================

@chkdel:
		out_of_range.w	@delete,sball_origX(a0)
		bra.w	DisplaySprite
; ===========================================================================

@delete:
		moveq	#0,d2
		lea	sball_childs(a0),a2
		move.b	(a2)+,d2

	@deleteloop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a1
		bsr.w	DeleteChild
		dbf	d2,@deleteloop ; delete all pieces of chain

		rts
; ===========================================================================

SBall_Display:	; Routine 4
		bra.w	DisplaySprite

Map_SBall:	include	"_maps\Spiked Ball and Chain (SYZ).asm"
Map_SBall2:	include	"_maps\Spiked Ball and Chain (LZ).asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 58 - giant spiked balls (SYZ)
; ---------------------------------------------------------------------------

; Obj58:
BigSpikeBall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	BBall_Index(pc,d0.w),d1
		jmp	BBall_Index(pc,d1.w)
; ===========================================================================
BBall_Index:	dc.w BBall_Main-BBall_Index
		dc.w BBall_Move-BBall_Index

bball_origX:	equ $3A		; original x-axis position
bball_origY:	equ $38		; original y-axis position
bball_radius:	equ $3C		; radius of circle
bball_speed:	equ $3E		; speed
; ===========================================================================

BBall_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_BBall,obMap(a0)
		move.w	#$396,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$18,obActWid(a0)
		move.w	obX(a0),bball_origX(a0)
		move.w	obY(a0),bball_origY(a0)
		move.b	#$86,obColType(a0)
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F0,d1		; read only the 1st digit
		ext.w	d1
		asl.w	#3,d1		; multiply by 8
		move.w	d1,bball_speed(a0) ; set object speed
		move.b	obStatus(a0),d0
		ror.b	#2,d0
		andi.b	#$C0,d0
		move.b	d0,obAngle(a0)
		move.b	#$50,bball_radius(a0) ; set radius of circle motion

BBall_Move:	; Routine 2
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object type
		andi.w	#7,d0		; read only the 2nd digit
		add.w	d0,d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		out_of_range.w	DeleteObject,bball_origX(a0)
		bra.w	DisplaySprite
; ===========================================================================
@index:		dc.w @type00-@index
		dc.w @type01-@index
		dc.w @type02-@index
		dc.w @type03-@index
; ===========================================================================

@type00:
		rts
; ===========================================================================

@type01:
		move.w	#$60,d1
		moveq	#0,d0
		move.b	(v_oscillate+$E).w,d0
		btst	#0,obStatus(a0)
		beq.s	@noflip1
		neg.w	d0
		add.w	d1,d0

	@noflip1:
		move.w	bball_origX(a0),d1
		sub.w	d0,d1
		move.w	d1,obX(a0)	; move object horizontally
		rts
; ===========================================================================

@type02:
		move.w	#$60,d1
		moveq	#0,d0
		move.b	(v_oscillate+$E).w,d0
		btst	#0,obStatus(a0)
		beq.s	@noflip2
		neg.w	d0
		addi.w	#$80,d0

	@noflip2:
		move.w	bball_origY(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)	; move object vertically
		rts
; ===========================================================================

@type03:
		move.w	bball_speed(a0),d0
		add.w	d0,obAngle(a0)
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		move.w	bball_origY(a0),d2
		move.w	bball_origX(a0),d3
		moveq	#0,d4
		move.b	bball_radius(a0),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,obY(a0)	; move object circularly
		move.w	d5,obX(a0)
		rts

Map_BBall:	include	"_maps\Big Spiked Ball.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 59 - platforms that move when you stand on them (SLZ)
; ---------------------------------------------------------------------------

; Obj59:
Elevator:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Elev_Index(pc,d0.w),d1
		jsr	Elev_Index(pc,d1.w)
		out_of_range.w	DeleteObject,elev_origX(a0)
		bra.w	DisplaySprite
; ===========================================================================
Elev_Index:	dc.w Elev_Main-Elev_Index
		dc.w Elev_Platform-Elev_Index
		dc.w Elev_Action-Elev_Index
		dc.w Elev_MakeMulti-Elev_Index

elev_origX:	equ $32		; original x-axis position
elev_origY:	equ $30		; original y-axis position
elev_dist:	equ $3C		; distance to move (2 bytes)

Elev_Var1:	dc.b $28, 0		; width, frame number

Elev_Var2:	dc.b $10, 1		; distance to move, action type
		dc.b $20, 1
		dc.b $34, 1
		dc.b $10, 3
		dc.b $20, 3
		dc.b $34, 3
		dc.b $14, 1
		dc.b $24, 1
		dc.b $2C, 1
		dc.b $14, 3
		dc.b $24, 3
		dc.b $2C, 3
		dc.b $20, 5
		dc.b $20, 7
		dc.b $30, 9
; ===========================================================================

Elev_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		bpl.s	@normal		; branch for types 00-7F
		addq.b	#4,obRoutine(a0) ; goto Elev_MakeMulti next
		andi.w	#$7F,d0
		mulu.w	#6,d0
		move.w	d0,elev_dist(a0)
		move.w	d0,$3E(a0)
		addq.l	#4,sp
		rts
; ===========================================================================

	@normal:
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	Elev_Var1(pc,d0.w),a2
		move.b	(a2)+,obActWid(a0) ; set width
		move.b	(a2)+,obFrame(a0) ; set frame
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		andi.w	#$1E,d0
		lea	Elev_Var2(pc,d0.w),a2
		move.b	(a2)+,d0
		lsl.w	#2,d0
		move.w	d0,elev_dist(a0)	; set distance to move
		move.b	(a2)+,obSubtype(a0)	; set type
		move.l	#Map_Elev,obMap(a0)
		move.w	#$4000,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.w	obX(a0),elev_origX(a0)
		move.w	obY(a0),elev_origY(a0)

Elev_Platform:	; Routine 2
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(PlatformObject).l
		bra.w	Elev_Types
; ===========================================================================

Elev_Action:	; Routine 4
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(ExitPlatform).l
		move.w	obX(a0),-(sp)
		bsr.w	Elev_Types
		move.w	(sp)+,d2
		tst.b	0(a0)
		beq.s	@deleted
		jmp	(MvSonicOnPtfm2).l

	@deleted:
		rts
; ===========================================================================

Elev_Types:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	@index(pc,d0.w),d1
		jmp	@index(pc,d1.w)
; ===========================================================================
@index:		dc.w @type00-@index, @type01-@index
		dc.w @type02-@index, @type01-@index
		dc.w @type04-@index, @type01-@index
		dc.w @type06-@index, @type01-@index
		dc.w @type08-@index, @type09-@index
; ===========================================================================

@type00:
		rts
; ===========================================================================

@type01:
		cmpi.b	#4,obRoutine(a0) ; check if Sonic is standing on the object
		bne.s	@notstanding
		addq.b	#1,obSubtype(a0) ; if yes, add 1 to type

	@notstanding:
		rts
; ===========================================================================

@type02:
		bsr.w	Elev_Move
		move.w	$34(a0),d0
		neg.w	d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		rts
; ===========================================================================

@type04:
		bsr.w	Elev_Move
		move.w	$34(a0),d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		rts
; ===========================================================================

@type06:
		bsr.w	Elev_Move
		move.w	$34(a0),d0
		asr.w	#1,d0
		neg.w	d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		move.w	$34(a0),d0
		add.w	elev_origX(a0),d0
		move.w	d0,obX(a0)
		rts
; ===========================================================================

@type08:
		bsr.w	Elev_Move
		move.w	$34(a0),d0
		asr.w	#1,d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		move.w	$34(a0),d0
		neg.w	d0
		add.w	elev_origX(a0),d0
		move.w	d0,obX(a0)
		rts
; ===========================================================================

@type09:
		bsr.w	Elev_Move
		move.w	$34(a0),d0
		neg.w	d0
		add.w	elev_origY(a0),d0
		move.w	d0,obY(a0)
		tst.b	obSubtype(a0)
		beq.w	@typereset
		rts
; ===========================================================================

	@typereset:
		btst	#3,obStatus(a0)
		beq.s	@delete
		bset	#1,obStatus(a1)
		bclr	#3,obStatus(a1)
		move.b	#2,obRoutine(a1)

	@delete:
		bra.w	DeleteObject

Elev_Move:
		move.w	$38(a0),d0
		tst.b	$3A(a0)
		bne.s	loc_10CC8
		cmpi.w	#$800,d0
		bhs.s	loc_10CD0
		addi.w	#$10,d0
		bra.s	loc_10CD0
; ===========================================================================

loc_10CC8:
		tst.w	d0
		beq.s	loc_10CD0
		subi.w	#$10,d0

loc_10CD0:
		move.w	d0,$38(a0)
		ext.l	d0
		asl.l	#8,d0
		add.l	$34(a0),d0
		move.l	d0,$34(a0)
		swap	d0
		move.w	elev_dist(a0),d2
		cmp.w	d2,d0
		bls.s	loc_10CF0
		move.b	#1,$3A(a0)

loc_10CF0:
		add.w	d2,d2
		cmp.w	d2,d0
		bne.s	locret_10CFA
		clr.b	obSubtype(a0)

locret_10CFA:
		rts
; End of function Elev_Move

; ===========================================================================

Elev_MakeMulti:	; Routine 6
		subq.w	#1,elev_dist(a0)
		bne.s	@chkdel
		move.w	$3E(a0),elev_dist(a0)
		bsr.w	FindFreeObj
		bne.s	@chkdel
		move.b	#id_Elevator,0(a1) ; duplicate the object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#$E,obSubtype(a1)

@chkdel:
		addq.l	#4,sp
		out_of_range.w	DeleteObject
		rts

Map_Elev:	include	"_maps\SLZ Elevators.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5A - platforms moving in circles (SLZ)
; ---------------------------------------------------------------------------

; Obj5A:
CirclingPlatform:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Circ_Index(pc,d0.w),d1
		jsr	Circ_Index(pc,d1.w)
		out_of_range.w	DeleteObject,circ_origX(a0)
		bra.w	DisplaySprite
; ===========================================================================
Circ_Index:	dc.w Circ_Main-Circ_Index
		dc.w Circ_Platform-Circ_Index
		dc.w Circ_Action-Circ_Index

circ_origX:	equ $32		; original x-axis position
circ_origY:	equ $30		; original y-axis position
; ===========================================================================

Circ_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Circ,obMap(a0)
		move.w	#$4000,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$18,obActWid(a0)
		move.w	obX(a0),circ_origX(a0)
		move.w	obY(a0),circ_origY(a0)

Circ_Platform:	; Routine 2
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(PlatformObject).l
		bra.w	Circ_Types
; ===========================================================================

Circ_Action:	; Routine 4
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(ExitPlatform).l
		move.w	obX(a0),-(sp)
		bsr.w	Circ_Types
		move.w	(sp)+,d2
		jmp	(MvSonicOnPtfm2).l
; ===========================================================================

Circ_Types:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$C,d0
		lsr.w	#1,d0
		move.w	@index(pc,d0.w),d1
		jmp	@index(pc,d1.w)
; ===========================================================================
@index:		dc.w @type00-@index
		dc.w @type04-@index
; ===========================================================================

@type00:
		move.b	(v_oscillate+$22).w,d1 ; get rotating value
		subi.b	#$50,d1		; set radius of circle
		ext.w	d1
		move.b	(v_oscillate+$26).w,d2
		subi.b	#$50,d2
		ext.w	d2
		btst	#0,obSubtype(a0)
		beq.s	@noshift00a
		neg.w	d1
		neg.w	d2

	@noshift00a:
		btst	#1,obSubtype(a0)
		beq.s	@noshift00b
		neg.w	d1
		exg	d1,d2

	@noshift00b:
		add.w	circ_origX(a0),d1
		move.w	d1,obX(a0)
		add.w	circ_origY(a0),d2
		move.w	d2,obY(a0)
		rts
; ===========================================================================

@type04:
		move.b	(v_oscillate+$22).w,d1
		subi.b	#$50,d1
		ext.w	d1
		move.b	(v_oscillate+$26).w,d2
		subi.b	#$50,d2
		ext.w	d2
		btst	#0,obSubtype(a0)
		beq.s	@noshift04a
		neg.w	d1
		neg.w	d2

	@noshift04a:
		btst	#1,obSubtype(a0)
		beq.s	@noshift04b
		neg.w	d1
		exg	d1,d2

	@noshift04b:
		neg.w	d1
		add.w	circ_origX(a0),d1
		move.w	d1,obX(a0)
		add.w	circ_origY(a0),d2
		move.w	d2,obY(a0)
		rts

Map_Circ:	include	"_maps\SLZ Circling Platform.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5B - blocks that form a staircase (SLZ)
; ---------------------------------------------------------------------------

; Obj5B:
Staircase:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Stair_Index(pc,d0.w),d1
		jsr	Stair_Index(pc,d1.w)
		out_of_range.w	DeleteObject,stair_origX(a0)
		bra.w	DisplaySprite
; ===========================================================================
Stair_Index:	dc.w Stair_Main-Stair_Index
		dc.w Stair_Move-Stair_Index
		dc.w Stair_Solid-Stair_Index

stair_origX:	equ $30		; original x-axis position
stair_origY:	equ $32		; original y-axis position

stair_parent:	equ $3C		; address of parent object (4 bytes)
; ===========================================================================

Stair_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		moveq	#$38,d3
		moveq	#1,d4
		btst	#0,obStatus(a0)	; is object flipped?
		beq.s	@notflipped	; if not, branch
		moveq	#$3B,d3
		moveq	#-1,d4

	@notflipped:
		move.w	obX(a0),d2
		movea.l	a0,a1
		moveq	#3,d1
		bra.s	@makeblocks
; ===========================================================================

@loop:
		bsr.w	FindNextFreeObj
		bne.w	@fail
		move.b	#4,obRoutine(a1)

@makeblocks:
		move.b	#id_Staircase,0(a1) ; load another block object
		move.l	#Map_Stair,obMap(a1)
		move.w	#$4000,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#3,obPriority(a1)
		move.b	#$10,obActWid(a1)
		move.b	obSubtype(a0),obSubtype(a1)
		move.w	d2,obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	obX(a0),stair_origX(a1)
		move.w	obY(a1),stair_origY(a1)
		addi.w	#$20,d2
		move.b	d3,$37(a1)
		move.l	a0,stair_parent(a1)
		add.b	d4,d3
		dbf	d1,@loop	; repeat sequence 3 times

	@fail:

Stair_Move:	; Routine 2
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	Stair_TypeIndex(pc,d0.w),d1
		jsr	Stair_TypeIndex(pc,d1.w)

Stair_Solid:	; Routine 4
		movea.l	stair_parent(a0),a2
		moveq	#0,d0
		move.b	$37(a0),d0
		move.b	(a2,d0.w),d0
		add.w	stair_origY(a0),d0
		move.w	d0,obY(a0)
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		tst.b	d4
		bpl.s	loc_10F92
		move.b	d4,$36(a2)

loc_10F92:
		btst	#3,obStatus(a0)
		beq.s	locret_10FA0
		move.b	#1,$36(a2)

locret_10FA0:
		rts
; ===========================================================================
Stair_TypeIndex:dc.w Stair_Type00-Stair_TypeIndex
		dc.w Stair_Type01-Stair_TypeIndex
		dc.w Stair_Type02-Stair_TypeIndex
		dc.w Stair_Type01-Stair_TypeIndex
; ===========================================================================

Stair_Type00:
		tst.w	$34(a0)
		bne.s	loc_10FC0
		cmpi.b	#1,$36(a0)
		bne.s	locret_10FBE
		move.w	#$1E,$34(a0)

locret_10FBE:
		rts
; ===========================================================================

loc_10FC0:
		subq.w	#1,$34(a0)
		bne.s	locret_10FBE
		addq.b	#1,obSubtype(a0) ; add 1 to type
		rts
; ===========================================================================

Stair_Type02:
		tst.w	$34(a0)
		bne.s	loc_10FE0
		tst.b	$36(a0)
		bpl.s	locret_10FDE
		move.w	#$3C,$34(a0)

locret_10FDE:
		rts
; ===========================================================================

loc_10FE0:
		subq.w	#1,$34(a0)
		bne.s	loc_10FEC
		addq.b	#1,obSubtype(a0) ; add 1 to type
		rts
; ===========================================================================

loc_10FEC:
		lea	$38(a0),a1
		move.w	$34(a0),d0
		lsr.b	#2,d0
		andi.b	#1,d0
		move.b	d0,(a1)+
		eori.b	#1,d0
		move.b	d0,(a1)+
		eori.b	#1,d0
		move.b	d0,(a1)+
		eori.b	#1,d0
		move.b	d0,(a1)+
		rts
; ===========================================================================

Stair_Type01:
		lea	$38(a0),a1
		cmpi.b	#$80,(a1)
		beq.s	locret_11038
		addq.b	#1,(a1)
		moveq	#0,d1
		move.b	(a1)+,d1
		swap	d1
		lsr.l	#1,d1
		move.l	d1,d2
		lsr.l	#1,d1
		move.l	d1,d3
		add.l	d2,d3
		swap	d1
		swap	d2
		swap	d3
		move.b	d3,(a1)+
		move.b	d2,(a1)+
		move.b	d1,(a1)+

locret_11038:
		rts
		rts

Map_Stair:	include	"_maps\Staircase.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5C - metal pylons in foreground (SLZ)
; ---------------------------------------------------------------------------

; Obj5C:
Pylon:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Pyl_Index(pc,d0.w),d1
		jmp	Pyl_Index(pc,d1.w)
; ===========================================================================
Pyl_Index:	dc.w Pyl_Main-Pyl_Index
		dc.w Pyl_Display-Pyl_Index
; ===========================================================================

Pyl_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Pylon,obMap(a0)
		move.w	#$83CC,obGfx(a0)
		move.b	#$10,obActWid(a0)

Pyl_Display:	; Routine 2
		move.l	(v_screenposx).w,d1
		add.l	d1,d1
		swap	d1
		neg.w	d1
		move.w	d1,obX(a0)
		move.l	(v_screenposy).w,d1
		add.l	d1,d1
		swap	d1
		andi.w	#$3F,d1
		neg.w	d1
		addi.w	#$100,d1
		move.w	d1,obScreenY(a0)
		bra.w	DisplaySprite

Map_Pylon:	include	"_maps\Pylon.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1B - water surface (LZ)
; ---------------------------------------------------------------------------

; Obj1B:
WaterSurface:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Surf_Index(pc,d0.w),d1
		jmp	Surf_Index(pc,d1.w)
; ===========================================================================
Surf_Index:	dc.w Surf_Main-Surf_Index
		dc.w Surf_Action-Surf_Index

surf_origX:	equ $30		; original x-axis position
surf_freeze:	equ $32		; flag to freeze animation
; ===========================================================================

Surf_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Surf,obMap(a0)
		move.w	#$C300,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$80,obActWid(a0)
		move.w	obX(a0),surf_origX(a0)

Surf_Action:	; Routine 2
		move.w	(v_screenposx).w,d1
		andi.w	#$FFE0,d1
		add.w	surf_origX(a0),d1
		btst	#0,(v_framebyte).w
		beq.s	@even		; branch on even frames
		addi.w	#$20,d1

	@even:
		move.w	d1,obX(a0)	; match obj x-position to screen position
		move.w	(v_waterpos1).w,d1
		move.w	d1,obY(a0)	; match obj y-position to water	height
		tst.b	surf_freeze(a0)
		bne.s	@stopped
		btst	#bitStart,(v_jpadpress1).w ; is Start button pressed?
		beq.s	@animate	; if not, branch
		addq.b	#3,obFrame(a0)	; use different frames
		move.b	#1,surf_freeze(a0) ; stop animation
		bra.s	@display
; ===========================================================================

@stopped:
		tst.w	(f_pause).w	; is the game paused?
		bne.s	@display	; if yes, branch
		move.b	#0,surf_freeze(a0) ; resume animation
		subq.b	#3,obFrame(a0)	; use normal frames

@animate:
		subq.b	#1,obTimeFrame(a0)
		bpl.s	@display
		move.b	#7,obTimeFrame(a0)
		addq.b	#1,obFrame(a0)
		cmpi.b	#3,obFrame(a0)
		blo.s	@display
		move.b	#0,obFrame(a0)

@display:
		bra.w	DisplaySprite

Map_Surf:	include	"_maps\Water Surface.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0B - pole that breaks (LZ)
; ---------------------------------------------------------------------------

; Obj0B:
Pole:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Pole_Index(pc,d0.w),d1
		jmp	Pole_Index(pc,d1.w)
; ===========================================================================
Pole_Index:	dc.w Pole_Main-Pole_Index
		dc.w Pole_Action-Pole_Index
		dc.w Pole_Display-Pole_Index

pole_time:	equ $30		; time between grabbing the pole & breaking
pole_grabbed:	equ $32		; flag set when Sonic grabs the pole
; ===========================================================================

Pole_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Pole,obMap(a0)
		move.w	#$43DE,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#8,obActWid(a0)
		move.b	#4,obPriority(a0)
		move.b	#$E1,obColType(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object type
		mulu.w	#60,d0		; multiply by 60 (1 second)
		move.w	d0,pole_time(a0) ; set breakage time

Pole_Action:	; Routine 2
		tst.b	pole_grabbed(a0) ; has pole already been grabbed?
		beq.s	@grab		; if not, branch
		tst.w	pole_time(a0)
		beq.s	@moveup
		subq.w	#1,pole_time(a0) ; decrement time until break
		bne.s	@moveup
		move.b	#1,obFrame(a0)	; break the pole
		bra.s	@release
; ===========================================================================

@moveup:
		lea	(v_player).w,a1
		move.w	obY(a0),d0
		subi.w	#$18,d0
		btst	#bitUp,(v_jpadhold1).w ; is "up" pressed?
		beq.s	@movedown	; if not, branch
		subq.w	#1,obY(a1)	; move Sonic up
		cmp.w	obY(a1),d0
		blo.s	@movedown
		move.w	d0,obY(a1)

@movedown:
		addi.w	#$24,d0
		btst	#bitDn,(v_jpadhold1).w ; is "down" pressed?
		beq.s	@letgo		; if not, branch
		addq.w	#1,obY(a1)	; move Sonic down
		cmp.w	obY(a1),d0
		bhs.s	@letgo
		move.w	d0,obY(a1)

@letgo:
		move.b	(v_jpadpress2).w,d0
		andi.w	#btnABC,d0	; is A/B/C pressed?
		beq.s	Pole_Display	; if not, branch

@release:
		clr.b	obColType(a0)
		addq.b	#2,obRoutine(a0) ; goto Pole_Display next
		clr.b	(f_playerctrl).w
		clr.b	(f_wtunnelallow).w
		clr.b	pole_grabbed(a0)
		bra.s	Pole_Display
; ===========================================================================

@grab:
		tst.b	obColProp(a0)	; has Sonic touched the pole?
		beq.s	Pole_Display	; if not, branch
		lea	(v_player).w,a1
		move.w	obX(a0),d0
		addi.w	#$14,d0
		cmp.w	obX(a1),d0
		bhs.s	Pole_Display
		clr.b	obColProp(a0)
		cmpi.b	#4,obRoutine(a1)
		bhs.s	Pole_Display
		clr.w	obVelX(a1)	; stop Sonic moving
		clr.w	obVelY(a1)	; stop Sonic moving
		move.w	obX(a0),d0
		addi.w	#$14,d0
		move.w	d0,obX(a1)
		bclr	#0,obStatus(a1)
		move.b	#id_Hang,obAnim(a1) ; set Sonic's animation to "hanging" ($11)
		move.b	#1,(f_playerctrl).w ; lock controls
		move.b	#1,(f_wtunnelallow).w ; disable wind tunnel
		move.b	#1,pole_grabbed(a0) ; begin countdown to breakage

Pole_Display:	; Routine 4
		bra.w	RememberState

Map_Pole:	include	"_maps\Pole that Breaks.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0C - flapping door (LZ)
; ---------------------------------------------------------------------------

; Obj0C:
FlapDoor:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Flap_Index(pc,d0.w),d1
		jmp	Flap_Index(pc,d1.w)
; ===========================================================================
Flap_Index:	dc.w Flap_Main-Flap_Index
		dc.w Flap_OpenClose-Flap_Index

flap_time:	equ $32		; time between opening/closing
flap_wait:	equ $30		; time until change
; ===========================================================================

Flap_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Flap,obMap(a0)
		move.w	#$4328,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$28,obActWid(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object type
		mulu.w	#60,d0		; multiply by 60 (1 second)
		move.w	d0,flap_time(a0) ; set flap delay time

Flap_OpenClose:	; Routine 2
		subq.w	#1,flap_wait(a0) ; decrement time delay
		bpl.s	@wait		; if time remains, branch
		move.w	flap_time(a0),flap_wait(a0) ; reset time delay
		bchg	#0,obAnim(a0)	; open/close door
		tst.b	obRender(a0)
		bpl.s	@nosound
		move.w	#sfx_Door,d0
		jsr	(PlaySound_Special).l	; play door sound

	@wait:
	@nosound:
		lea	(Ani_Flap).l,a1
		bsr.w	AnimateSprite
		clr.b	(f_wtunnelallow).w ; enable wind tunnel
		tst.b	obFrame(a0)	; is the door open?
		bne.s	@display	; if yes, branch
		move.w	(v_player+obX).w,d0
		cmp.w	obX(a0),d0	; has Sonic passed through the door?
		bhs.s	@display	; if yes, branch
		move.b	#1,(f_wtunnelallow).w ; disable wind tunnel
		move.w	#$13,d1
		move.w	#$20,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject	; make the door solid

	@display:
		bra.w	RememberState

		include	"_anim\Flapping Door.asm"
Map_Flap:	include	"_maps\Flapping Door.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 71 - invisible solid barriers
; ---------------------------------------------------------------------------

; Obj71:
Invisibarrier:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Invis_Index(pc,d0.w),d1
		jmp	Invis_Index(pc,d1.w)
; ===========================================================================
Invis_Index:	dc.w Invis_Main-Invis_Index
		dc.w Invis_Solid-Invis_Index

invis_height:	equ $16		; height in pixels
; ===========================================================================

Invis_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Invis,obMap(a0)
		move.w	#$8680,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	obSubtype(a0),d0 ; get object type
		move.b	d0,d1
		andi.w	#$F0,d0		; read only the 1st byte
		addi.w	#$10,d0
		lsr.w	#1,d0
		move.b	d0,obActWid(a0)	; set object width
		andi.w	#$F,d1		; read only the 2nd byte
		addq.w	#1,d1
		lsl.w	#3,d1
		move.b	d1,invis_height(a0) ; set object height

Invis_Solid:	; Routine 2
		bsr.w	ChkObjectVisible
		bne.s	@chkdel
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	invis_height(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject71

@chkdel:
		out_of_range.s	@delete
		tst.w	(v_debuguse).w	; are you using debug mode?
		beq.s	@nodisplay	; if not, branch
		jmp	(DisplaySprite).l	; if yes, display the object

	@nodisplay:
		rts

	@delete:
		jmp	(DeleteObject).l

Map_Invis:	include	"_maps\Invisible Barriers.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5D - fans (SLZ)
; ---------------------------------------------------------------------------

; Obj5D:
Fan:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Fan_Index(pc,d0.w),d1
		jmp	Fan_Index(pc,d1.w)
; ===========================================================================
Fan_Index:	dc.w Fan_Main-Fan_Index
		dc.w Fan_Delay-Fan_Index

fan_time:	equ $30		; time between switching on/off
fan_switch:	equ $32		; on/off switch
; ===========================================================================

Fan_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Fan,obMap(a0)
		move.w	#$43A0,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)

Fan_Delay:	; Routine 2
		btst	#1,obSubtype(a0) ; is object type 02/03 (always on)?
		bne.s	@blow		; if yes, branch
		subq.w	#1,fan_time(a0)	; subtract 1 from time delay
		bpl.s	@blow		; if time remains, branch
		move.w	#120,fan_time(a0) ; set delay to 2 seconds
		bchg	#0,fan_switch(a0) ; switch fan on/off
		beq.s	@blow		; if fan is off, branch
		move.w	#180,fan_time(a0) ; set delay to 3 seconds

@blow:
		tst.b	fan_switch(a0)	; is fan switched on?
		bne.w	@chkdel		; if not, branch
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		btst	#0,obStatus(a0)	; is fan facing right?
		bne.s	@chksonic	; if yes, branch
		neg.w	d0

@chksonic:
		addi.w	#$50,d0
		cmpi.w	#$F0,d0		; is Sonic more than $A0 pixels	from the fan?
		bhs.s	@animate	; if yes, branch
		move.w	obY(a1),d1
		addi.w	#$60,d1
		sub.w	obY(a0),d1
		blo.s	@animate	; branch if Sonic is too low
		cmpi.w	#$70,d1
		bhs.s	@animate	; branch if Sonic is too high
		subi.w	#$50,d0		; is Sonic more than $50 pixels from the fan?
		bhs.s	@faraway	; if yes, branch
		not.w	d0
		add.w	d0,d0

	@faraway:
		addi.w	#$60,d0
		btst	#0,obStatus(a0)	; is fan facing right?
		bne.s	@right		; if yes, branch
		neg.w	d0

	@right:
		neg.b	d0
		asr.w	#4,d0
		btst	#0,obSubtype(a0)
		beq.s	@movesonic
		neg.w	d0

	@movesonic:
		add.w	d0,obX(a1)	; push Sonic away from the fan

@animate:
		subq.b	#1,obTimeFrame(a0)
		bpl.s	@chkdel
		move.b	#0,obTimeFrame(a0)
		addq.b	#1,obAniFrame(a0)
		cmpi.b	#3,obAniFrame(a0)
		blo.s	@noreset
		move.b	#0,obAniFrame(a0) ; reset after 4 frames

	@noreset:
		moveq	#0,d0
		btst	#0,obSubtype(a0)
		beq.s	@noflip
		moveq	#2,d0

	@noflip:
		add.b	obAniFrame(a0),d0
		move.b	d0,obFrame(a0)

@chkdel:
		bsr.w	DisplaySprite
		out_of_range.w	DeleteObject
		rts

Map_Fan:	include	"_maps\Fan.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5E - seesaws (SLZ)
; ---------------------------------------------------------------------------

; Obj5E:
Seesaw:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	See_Index(pc,d0.w),d1
		jsr	See_Index(pc,d1.w)
		move.w	see_origX(a0),d0
		andi.w	#$FF80,d0
		move.w	(v_screenposx).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		bmi.w	DeleteObject
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================
See_Index:	dc.w See_Main-See_Index
		dc.w See_Slope-See_Index
		dc.w See_Slope2-See_Index
		dc.w See_Spikeball-See_Index
		dc.w See_MoveSpike-See_Index
		dc.w See_SpikeFall-See_Index

see_origX:	equ $30		; original x-axis position
see_origY:	equ $34		; original y-axis position
see_speed:	equ $38		; speed of collision
see_frame:	equ $3A		;
see_parent:	equ $3C		; RAM address of parent object
; ===========================================================================

See_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Seesaw,obMap(a0)
		move.w	#$374,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$30,obActWid(a0)
		move.w	obX(a0),see_origX(a0)
		tst.b	obSubtype(a0)	; is object type 00 ?
		bne.s	@noball		; if not, branch

		bsr.w	FindNextFreeObj
		bne.s	@noball
		move.b	#id_Seesaw,0(a1) ; load spikeball object
		addq.b	#6,obRoutine(a1) ; use See_Spikeball routine
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.l	a0,see_parent(a1)

	@noball:
		btst	#0,obStatus(a0)	; is seesaw flipped?
		beq.s	@noflip		; if not, branch
		move.b	#2,obFrame(a0)	; use different frame

	@noflip:
		move.b	obFrame(a0),see_frame(a0)

See_Slope:	; Routine 2
		move.b	see_frame(a0),d1
		bsr.w	See_ChgFrame
		lea	(See_DataSlope).l,a2
		btst	#0,obFrame(a0)	; is seesaw flat?
		beq.s	@notflat	; if not, branch
		lea	(See_DataFlat).l,a2

	@notflat:
		lea	(v_player).w,a1
		move.w	obVelY(a1),see_speed(a0)
		move.w	#$30,d1
		jsr	(SlopeObject).l
		rts
; ===========================================================================

See_Slope2:	; Routine 4
		bsr.w	See_ChkSide
		lea	(See_DataSlope).l,a2
		btst	#0,obFrame(a0)	; is seesaw flat?
		beq.s	@notflat	; if not, branch
		lea	(See_DataFlat).l,a2

	@notflat:
		move.w	#$30,d1
		jsr	(ExitPlatform).l
		move.w	#$30,d1
		move.w	obX(a0),d2
		jsr	(SlopeObject2).l
		rts
; ===========================================================================

See_ChkSide:
		moveq	#2,d1
		lea	(v_player).w,a1
		move.w	obX(a0),d0
		sub.w	obX(a1),d0	; is Sonic on the left side of the seesaw?
		bhs.s	@leftside	; if yes, branch
		neg.w	d0
		moveq	#0,d1

	@leftside:
		cmpi.w	#8,d0
		bhs.s	See_ChgFrame
		moveq	#1,d1

See_ChgFrame:
		move.b	obFrame(a0),d0
		cmp.b	d1,d0		; does frame need to change?
		beq.s	@noflip		; if not, branch
		bhs.s	@loc_11772
		addq.b	#2,d0

	@loc_11772:
		subq.b	#1,d0
		move.b	d0,obFrame(a0)
		move.b	d1,see_frame(a0)
		bclr	#0,obRender(a0)
		btst	#1,obFrame(a0)
		beq.s	@noflip
		bset	#0,obRender(a0)

	@noflip:
		rts
; ===========================================================================

See_Spikeball:	; Routine 6
		addq.b	#2,obRoutine(a0)
		move.l	#Map_SSawBall,obMap(a0)
		move.w	#$4F0,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$8B,obColType(a0)
		move.b	#$C,obActWid(a0)
		move.w	obX(a0),see_origX(a0)
		addi.w	#$28,obX(a0)
		move.w	obY(a0),see_origY(a0)
		move.b	#1,obFrame(a0)
		btst	#0,obStatus(a0)	; is seesaw flipped?
		beq.s	See_MoveSpike	; if not, branch
		subi.w	#$50,obX(a0)	; move spikeball to the other side
		move.b	#2,see_frame(a0)

See_MoveSpike:	; Routine 8
		movea.l	see_parent(a0),a1
		moveq	#0,d0
		move.b	see_frame(a0),d0
		sub.b	see_frame(a1),d0
		beq.s	loc_1183E
		bhs.s	loc_117FC
		neg.b	d0

loc_117FC:
		move.w	#-$818,d1
		move.w	#-$114,d2
		cmpi.b	#1,d0
		beq.s	loc_11822
		move.w	#-$AF0,d1
		move.w	#-$CC,d2
		cmpi.w	#$A00,$38(a1)
		blt.s	loc_11822
		move.w	#-$E00,d1
		move.w	#-$A0,d2

loc_11822:
		move.w	d1,obVelY(a0)
		move.w	d2,obVelX(a0)
		move.w	obX(a0),d0
		sub.w	see_origX(a0),d0
		bhs.s	loc_11838
		neg.w	obVelX(a0)

loc_11838:
		addq.b	#2,obRoutine(a0)
		bra.s	See_SpikeFall
; ===========================================================================

loc_1183E:
		lea	(See_Speeds).l,a2
		moveq	#0,d0
		move.b	obFrame(a1),d0
		move.w	#$28,d2
		move.w	obX(a0),d1
		sub.w	see_origX(a0),d1
		bhs.s	loc_1185C
		neg.w	d2
		addq.w	#2,d0

loc_1185C:
		add.w	d0,d0
		move.w	see_origY(a0),d1
		add.w	(a2,d0.w),d1
		move.w	d1,obY(a0)
		add.w	see_origX(a0),d2
		move.w	d2,obX(a0)
		clr.w	obY+2(a0)
		clr.w	obX+2(a0)
		rts
; ===========================================================================

See_SpikeFall:	; Routine $A
		tst.w	obVelY(a0)	; is spikeball falling down?
		bpl.s	loc_1189A	; if yes, branch
		bsr.w	ObjectFall
		move.w	see_origY(a0),d0
		subi.w	#$2F,d0
		cmp.w	obY(a0),d0
		bgt.s	locret_11898
		bsr.w	ObjectFall

locret_11898:
		rts
; ===========================================================================

loc_1189A:
		bsr.w	ObjectFall
		movea.l	see_parent(a0),a1
		lea	(See_Speeds).l,a2
		moveq	#0,d0
		move.b	obFrame(a1),d0
		move.w	obX(a0),d1
		sub.w	see_origX(a0),d1
		bhs.s	loc_118BA
		addq.w	#2,d0

loc_118BA:
		add.w	d0,d0
		move.w	see_origY(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	obY(a0),d1
		bgt.s	locret_11938
		movea.l	see_parent(a0),a1
		moveq	#2,d1
		tst.w	obVelX(a0)
		bmi.s	See_Spring
		moveq	#0,d1

See_Spring:
		move.b	d1,$3A(a1)
		move.b	d1,see_frame(a0)
		cmp.b	obFrame(a1),d1
		beq.s	loc_1192C
		bclr	#3,obStatus(a1)
		beq.s	loc_1192C
		clr.b	ob2ndRout(a1)
		move.b	#2,obRoutine(a1)
		lea	(v_player).w,a2
		move.w	obVelY(a0),obVelY(a2)
		neg.w	obVelY(a2)
		bset	#1,obStatus(a2)
		bclr	#3,obStatus(a2)
		clr.b	$3C(a2)
		move.b	#id_Spring,obAnim(a2) ; change Sonic's animation to "spring" ($10)
		move.b	#2,obRoutine(a2)
		move.w	#sfx_Spring,d0
		jsr	(PlaySound_Special).l	; play spring sound

loc_1192C:
		clr.w	obVelX(a0)
		clr.w	obVelY(a0)
		subq.b	#2,obRoutine(a0)

locret_11938:
		rts
; ===========================================================================
See_Speeds:	dc.w -8, -$1C, -$2F, -$1C, -8

See_DataSlope:	incbin	"misc\slzssaw1.bin"
		even
See_DataFlat:	incbin	"misc\slzssaw2.bin"
		even

Map_Seesaw:	include	"_maps\Seesaw.asm"
Map_SSawBall:	include	"_maps\Seesaw Ball.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5F - walking bomb enemy (SLZ, SBZ)
; ---------------------------------------------------------------------------

; Obj5F:
Bomb:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bom_Index(pc,d0.w),d1
		jmp	Bom_Index(pc,d1.w)
; ===========================================================================
Bom_Index:	dc.w Bom_Main-Bom_Index
		dc.w Bom_Action-Bom_Index
		dc.w Bom_Display-Bom_Index
		dc.w Bom_End-Bom_Index

bom_time:	equ $30		; time of fuse
bom_origY:	equ $34		; original y-axis position
bom_parent:	equ $3C		; address of parent object
; ===========================================================================

Bom_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bomb,obMap(a0)
		move.w	#$400,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$C,obActWid(a0)
		move.b	obSubtype(a0),d0
		beq.s	loc_11A3C
		move.b	d0,obRoutine(a0)
		rts
; ===========================================================================

loc_11A3C:
		move.b	#$9A,obColType(a0)
		bchg	#0,obStatus(a0)

Bom_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		lea	(Ani_Bomb).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================
@index:		dc.w @walk-@index
		dc.w @wait-@index
		dc.w @explode-@index
; ===========================================================================

@walk:
		bsr.w	@chksonic
		subq.w	#1,bom_time(a0)	; subtract 1 from time delay
		bpl.s	@noflip		; if time remains, branch
		addq.b	#2,ob2ndRout(a0) ; goto @wait
		move.w	#1535,bom_time(a0) ; set time delay to 25 seconds
		move.w	#$10,obVelX(a0)
		move.b	#1,obAnim(a0)	; use walking animation
		bchg	#0,obStatus(a0)
		beq.s	@noflip
		neg.w	obVelX(a0)	; change direction

	@noflip:
		rts
; ===========================================================================

@wait:
		bsr.w	@chksonic
		subq.w	#1,bom_time(a0)	; subtract 1 from time delay
		bmi.s	@stopwalking	; if time expires, branch
		bsr.w	SpeedToPos
		rts
; ===========================================================================

	@stopwalking:
		subq.b	#2,ob2ndRout(a0)
		move.w	#179,bom_time(a0) ; set time delay to 3 seconds
		clr.w	obVelX(a0)	; stop walking
		move.b	#0,obAnim(a0)	; use waiting animation
		rts
; ===========================================================================

@explode:
		subq.w	#1,bom_time(a0)	; subtract 1 from time delay
		bpl.s	@noexplode	; if time remains, branch
		move.b	#id_ExplosionBomb,0(a0) ; change bomb into an explosion
		move.b	#0,obRoutine(a0)

	@noexplode:
		rts
; ===========================================================================

@chksonic:
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bhs.s	@isleft
		neg.w	d0

	@isleft:
		cmpi.w	#$60,d0		; is Sonic within $60 pixels?
		bhs.s	@outofrange	; if not, branch
		move.w	(v_player+obY).w,d0
		sub.w	obY(a0),d0
		bhs.s	@isabove
		neg.w	d0

	@isabove:
		cmpi.w	#$60,d0
		bhs.s	@outofrange
		tst.w	(v_debuguse).w
		bne.s	@outofrange

		move.b	#4,ob2ndRout(a0)
		move.w	#143,bom_time(a0) ; set fuse time
		clr.w	obVelX(a0)
		move.b	#2,obAnim(a0)	; use activated animation
		bsr.w	FindNextFreeObj
		bne.s	@outofrange
		move.b	#id_Bomb,0(a1)	; load fuse object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	obY(a0),bom_origY(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.b	#4,obSubtype(a1)
		move.b	#3,obAnim(a1)
		move.w	#$10,obVelY(a1)
		btst	#1,obStatus(a0)	; is bomb upside-down?
		beq.s	@normal		; if not, branch
		neg.w	obVelY(a1)	; reverse direction for fuse

	@normal:
		move.w	#143,bom_time(a1) ; set fuse time
		move.l	a0,bom_parent(a1)

@outofrange:
		rts
; ===========================================================================

Bom_Display:	; Routine 4
		bsr.s	loc_11B70
		lea	(Ani_Bomb).l,a1
		bsr.w	AnimateSprite
		bra.w	RememberState
; ===========================================================================

loc_11B70:
		subq.w	#1,bom_time(a0)
		bmi.s	loc_11B7C
		bsr.w	SpeedToPos
		rts
; ===========================================================================

loc_11B7C:
		clr.w	bom_time(a0)
		clr.b	obRoutine(a0)
		move.w	bom_origY(a0),obY(a0)
		moveq	#3,d1
		movea.l	a0,a1
		lea	(Bom_ShrSpeed).l,a2 ; load shrapnel speed data
		bra.s	@makeshrapnel
; ===========================================================================

	@loop:
		bsr.w	FindNextFreeObj
		bne.s	@fail

@makeshrapnel:
		move.b	#id_Bomb,0(a1)	; load shrapnel object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#6,obSubtype(a1)
		move.b	#4,obAnim(a1)
		move.w	(a2)+,obVelX(a1)
		move.w	(a2)+,obVelY(a1)
		move.b	#$98,obColType(a1)
		bset	#7,obRender(a1)

	@fail:
		dbf	d1,@loop	; repeat 3 more times

		move.b	#6,obRoutine(a0)

Bom_End:	; Routine 6
		bsr.w	SpeedToPos
		addi.w	#$18,obVelY(a0)
		lea	(Ani_Bomb).l,a1
		bsr.w	AnimateSprite
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite
; ===========================================================================
Bom_ShrSpeed:	dc.w -$200, -$300, -$100, -$200, $200, -$300, $100, -$200

		include	"_anim\Bomb Enemy.asm"
Map_Bomb:	include	"_maps\Bomb Enemy.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 60 - Orbinaut enemy (LZ, SLZ, SBZ)
; ---------------------------------------------------------------------------

; Obj60:
Orbinaut:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Orb_Index(pc,d0.w),d1
		jmp	Orb_Index(pc,d1.w)
; ===========================================================================
Orb_Index:	dc.w Orb_Main-Orb_Index
		dc.w Orb_ChkSonic-Orb_Index
		dc.w Orb_Display-Orb_Index
		dc.w Orb_MoveOrb-Orb_Index
		dc.w Orb_ChkDel2-Orb_Index

orb_parent:	equ $3C		; address of parent object
; ===========================================================================

Orb_Main:	; Routine 0
		move.l	#Map_Orb,obMap(a0)
		move.w	#$429,obGfx(a0)	; SBZ specific code
		cmpi.b	#id_SBZ,(v_zone).w ; check if level is SBZ
		beq.s	@isscrap
		move.w	#$2429,obGfx(a0) ; SLZ specific code

	@isscrap:
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ
		bne.s	@notlabyrinth
		move.w	#$467,obGfx(a0)	; LZ specific code

	@notlabyrinth:
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$B,obColType(a0)
		move.b	#$C,obActWid(a0)
		moveq	#0,d2
		lea	$37(a0),a2
		movea.l	a2,a3
		addq.w	#1,a2
		moveq	#3,d1

@makesatellites:
		bsr.w	FindNextFreeObj
		bne.s	@fail
		addq.b	#1,(a3)
		move.w	a1,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	0(a0),0(a1)	; load spiked orb object
		move.b	#6,obRoutine(a1) ; use Orb_MoveOrb routine
		move.l	obMap(a0),obMap(a1)
		move.w	obGfx(a0),obGfx(a1)
		ori.b	#4,obRender(a1)
		move.b	#4,obPriority(a1)
		move.b	#8,obActWid(a1)
		move.b	#3,obFrame(a1)
		move.b	#$98,obColType(a1)
		move.b	d2,obAngle(a1)
		addi.b	#$40,d2
		move.l	a0,orb_parent(a1)
		dbf	d1,@makesatellites ; repeat sequence 3 more times

	@fail:
		moveq	#1,d0
		btst	#0,obStatus(a0)	; is orbinaut facing left?
		beq.s	@noflip		; if not, branch
		neg.w	d0

	@noflip:
		move.b	d0,$36(a0)
		move.b	obSubtype(a0),obRoutine(a0) ; if type is 02, skip Orb_ChkSonic
		addq.b	#2,obRoutine(a0)
		move.w	#-$40,obVelX(a0) ; move orbinaut to the left
		btst	#0,obStatus(a0)	; is orbinaut facing left??
		beq.s	@noflip2	; if not, branch
		neg.w	obVelX(a0)	; move orbinaut to the right

	@noflip2:
		rts
; ===========================================================================

Orb_ChkSonic:	; Routine 2
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0	; is Sonic to the right of the orbinaut?
		bhs.s	@isright	; if yes, branch
		neg.w	d0

	@isright:
		cmpi.w	#$A0,d0		; is Sonic within $A0 pixels of orbinaut?
		bhs.s	@animate	; if not, branch
		move.w	(v_player+obY).w,d0
		sub.w	obY(a0),d0	; is Sonic above the orbinaut?
		bhs.s	@isabove	; if yes, branch
		neg.w	d0

	@isabove:
		cmpi.w	#$50,d0		; is Sonic within $50 pixels of orbinaut?
		bhs.s	@animate	; if not, branch
		tst.w	(v_debuguse).w	; is debug mode on?
		bne.s	@animate	; if yes, branch
		move.b	#1,obAnim(a0)	; use "angry" animation

@animate:
		lea	(Ani_Orb).l,a1
		bsr.w	AnimateSprite
		bra.w	Orb_ChkDel
; ===========================================================================

Orb_Display:	; Routine 4
		bsr.w	SpeedToPos

Orb_ChkDel:
		out_of_range.w	@chkgone
		bra.w	DisplaySprite

@chkgone:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	loc_11E34
		bclr	#7,2(a2,d0.w)

loc_11E34:
		lea	$37(a0),a2
		moveq	#0,d2
		move.b	(a2)+,d2
		subq.w	#1,d2
		blo.s	Orb_Delete

loc_11E40:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a1
		bsr.w	DeleteChild
		dbf	d2,loc_11E40

Orb_Delete:
		bra.w	DeleteObject
; ===========================================================================

Orb_MoveOrb:	; Routine 6
		movea.l	orb_parent(a0),a1
		cmpi.b	#id_Orbinaut,0(a1) ; does parent object still exist?
		bne.w	DeleteObject	; if not, delete
		cmpi.b	#2,obFrame(a1)	; is orbinaut angry?
		bne.s	@circle		; if not, branch
		cmpi.b	#$40,obAngle(a0) ; is spikeorb directly under the orbinaut?
		bne.s	@circle		; if not, branch
		addq.b	#2,obRoutine(a0)
		subq.b	#1,$37(a1)
		bne.s	@fire
		addq.b	#2,obRoutine(a1)

	@fire:
		move.w	#-$200,obVelX(a0) ; move orb to the left (quickly)
		btst	#0,obStatus(a1)
		beq.s	@noflip
		neg.w	obVelX(a0)

	@noflip:
		bra.w	DisplaySprite
; ===========================================================================

@circle:
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		asr.w	#4,d1
		add.w	obX(a1),d1
		move.w	d1,obX(a0)
		asr.w	#4,d0
		add.w	obY(a1),d0
		move.w	d0,obY(a0)
		move.b	$36(a1),d0
		add.b	d0,obAngle(a0)
		bra.w	DisplaySprite
; ===========================================================================

Orb_ChkDel2:	; Routine 8
		bsr.w	SpeedToPos
		tst.b	obRender(a0)
		bpl.w	DeleteObject
		bra.w	DisplaySprite

		include	"_anim\Orbinaut.asm"
Map_Orb:	include	"_maps\Orbinaut.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 16 - harpoon (LZ)
; ---------------------------------------------------------------------------

; Obj16:
Harpoon:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Harp_Index(pc,d0.w),d1
		jmp	Harp_Index(pc,d1.w)
; ===========================================================================
Harp_Index:	dc.w Harp_Main-Harp_Index
		dc.w Harp_Move-Harp_Index
		dc.w Harp_Wait-Harp_Index

harp_time:	equ $30		; time between stabbing/retracting
; ===========================================================================

Harp_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Harp,obMap(a0)
		move.w	#$3CC,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	obSubtype(a0),obAnim(a0) ; get type (vert/horiz)
		move.b	#$14,obActWid(a0)
		move.w	#60,harp_time(a0) ; set time to 1 second

Harp_Move:	; Routine 2
		lea	(Ani_Harp).l,a1
		bsr.w	AnimateSprite
		moveq	#0,d0
		move.b	obFrame(a0),d0	; get frame number
		move.b	@types(pc,d0.w),obColType(a0) ; get collision type
		bra.w	RememberState

	@types:
		dc.b $9B, $9C, $9D, $9E, $9F, $A0
		even

Harp_Wait:	; Routine 4
		subq.w	#1,harp_time(a0) ; decrement timer
		bpl.s	@chkdel		; branch if time remains
		move.w	#60,harp_time(a0) ; reset timer
		subq.b	#2,obRoutine(a0) ; run "Harp_Move" subroutine
		bchg	#0,obAnim(a0)	; reverse animation

	@chkdel:
		bra.w	RememberState

		include	"_anim\Harpoon.asm"
Map_Harp:	include	"_maps\Harpoon.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 61 - blocks (LZ)
; ---------------------------------------------------------------------------

; Obj61:
LabyrinthBlock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	LBlk_Index(pc,d0.w),d1
		jmp	LBlk_Index(pc,d1.w)
; ===========================================================================
LBlk_Index:	dc.w LBlk_Main-LBlk_Index
		dc.w LBlk_Action-LBlk_Index

LBlk_Var:	dc.b $10, $10		; width, height
		dc.b $20, $C
		dc.b $10, $10
		dc.b $10, $10

lblk_height:	equ $16		; block height
lblk_origX:	equ $34		; original x-axis position
lblk_origY:	equ $30		; original y-axis position
lblk_time:	equ $36		; time delay for block movement
lblk_untouched:	equ $38		; flag block as untouched
; ===========================================================================

LBlk_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_LBlock,obMap(a0)
		move.w	#$43E6,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get block type
		lsr.w	#3,d0		; read only the 1st digit
		andi.w	#$E,d0
		lea	LBlk_Var(pc,d0.w),a2
		move.b	(a2)+,obActWid(a0) ; set width
		move.b	(a2),lblk_height(a0) ; set height
		lsr.w	#1,d0
		move.b	d0,obFrame(a0)
		move.w	obX(a0),lblk_origX(a0)
		move.w	obY(a0),lblk_origY(a0)
		move.b	obSubtype(a0),d0 ; get block type
		andi.b	#$F,d0		; read only the 2nd digit
		beq.s	LBlk_Action	; branch if 0
		cmpi.b	#7,d0
		beq.s	LBlk_Action	; branch if 7
		move.b	#1,lblk_untouched(a0)

LBlk_Action:	; Routine 2
		move.w	obX(a0),-(sp)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		move.w	(sp)+,d4
		tst.b	obRender(a0)
		bpl.s	@chkdel
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	lblk_height(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	SolidObject
		move.b	d4,$3F(a0)
		bsr.w	loc_12180

@chkdel:
		out_of_range.w	DeleteObject,lblk_origX(a0)
		bra.w	DisplaySprite
; ===========================================================================
@index:		dc.w @type00-@index, @type01-@index
		dc.w @type02-@index, @type03-@index
		dc.w @type04-@index, @type05-@index
		dc.w @type06-@index, @type07-@index
; ===========================================================================

@type00:
		rts
; ===========================================================================

@type01:
@type03:
		tst.w	lblk_time(a0)	; does time remain?
		bne.s	@wait01		; if yes, branch
		btst	#3,obStatus(a0)	; is Sonic standing on the object?
		beq.s	@donothing01	; if not, branch
		move.w	#30,lblk_time(a0) ; wait for half second

	@donothing01:
		rts
; ===========================================================================

	@wait01:
		subq.w	#1,lblk_time(a0); decrement waiting time
		bne.s	@donothing01	; if time remains, branch
		addq.b	#1,obSubtype(a0) ; goto @type02 or @type04
		clr.b	lblk_untouched(a0) ; flag block as touched
		rts
; ===========================================================================

@type02:
@type06:
		bsr.w	SpeedToPos
		addq.w	#8,obVelY(a0)	; make block fall
		bsr.w	ObjFloorDist
		tst.w	d1		; has block hit the floor?
		bpl.w	@nofloor02	; if not, branch
		addq.w	#1,d1
		add.w	d1,obY(a0)
		clr.w	obVelY(a0)	; stop when it touches the floor
		clr.b	obSubtype(a0)	; set type to 00 (non-moving type)

	@nofloor02:
		rts
; ===========================================================================

@type04:
		bsr.w	SpeedToPos
		subq.w	#8,obVelY(a0)	; make block rise
		bsr.w	ObjHitCeiling
		tst.w	d1		; has block hit the ceiling?
		bpl.w	@noceiling04	; if not, branch
		sub.w	d1,obY(a0)
		clr.w	obVelY(a0)	; stop when it touches the ceiling
		clr.b	obSubtype(a0)	; set type to 00 (non-moving type)

	@noceiling04:
		rts
; ===========================================================================

@type05:
		cmpi.b	#1,$3F(a0)	; is Sonic touching the block?
		bne.s	@notouch05	; if not, branch
		addq.b	#1,obSubtype(a0) ; goto @type06
		clr.b	lblk_untouched(a0)

	@notouch05:
		rts
; ===========================================================================

@type07:
		move.w	(v_waterpos1).w,d0
		sub.w	obY(a0),d0	; is block level with water?
		beq.s	@stop07		; if yes, branch
		bhs.s	@fall07		; branch if block is above water
		cmpi.w	#-2,d0
		bge.s	@loc_1214E
		moveq	#-2,d0

	@loc_1214E:
		add.w	d0,obY(a0)	; make the block rise with water level
		bsr.w	ObjHitCeiling
		tst.w	d1		; has block hit the ceiling?
		bpl.w	@noceiling07	; if not, branch
		sub.w	d1,obY(a0)	; stop block

	@noceiling07:
		rts
; ===========================================================================

@fall07:
		cmpi.w	#2,d0
		ble.s	@loc_1216A
		moveq	#2,d0

	@loc_1216A:
		add.w	d0,obY(a0)	; make the block sink with water level
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.w	@stop07
		addq.w	#1,d1
		add.w	d1,obY(a0)

	@stop07:
		rts
; ===========================================================================

loc_12180:
		tst.b	lblk_untouched(a0) ; has block been stood on or touched?
		beq.s	locret_121C0	; if yes, branch
		btst	#3,obStatus(a0)	; is Sonic standing on it now?
		bne.s	loc_1219A	; if yes, branch
		tst.b	$3E(a0)
		beq.s	locret_121C0
		subq.b	#4,$3E(a0)
		bra.s	loc_121A6
; ===========================================================================

loc_1219A:
		cmpi.b	#$40,$3E(a0)
		beq.s	locret_121C0
		addq.b	#4,$3E(a0)

loc_121A6:
		move.b	$3E(a0),d0
		jsr	(CalcSine).l
		move.w	#$400,d1
		muls.w	d1,d0
		swap	d0
		add.w	lblk_origY(a0),d0
		move.w	d0,obY(a0)

locret_121C0:
		rts

Map_LBlock:	include	"_maps\LZ Blocks.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 62 - gargoyle head (LZ)
; ---------------------------------------------------------------------------

; Obj62:
Gargoyle:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Gar_Index(pc,d0.w),d1
		jsr	Gar_Index(pc,d1.w)
		bra.w	RememberState
; ===========================================================================
Gar_Index:	dc.w Gar_Main-Gar_Index
		dc.w Gar_MakeFire-Gar_Index
		dc.w Gar_FireBall-Gar_Index
		dc.w Gar_AniFire-Gar_Index

Gar_SpitRate:	dc.b 30, 60, 90, 120, 150, 180,	210, 240
; ===========================================================================

Gar_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Gar,obMap(a0)
		move.w	#$42E9,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#3,obPriority(a0)
		move.b	#$10,obActWid(a0)
		move.b	obSubtype(a0),d0 ; get object type
		andi.w	#$F,d0		; read only the 2nd digit
		move.b	Gar_SpitRate(pc,d0.w),obDelayAni(a0) ; set fireball spit rate
		move.b	obDelayAni(a0),obTimeFrame(a0)
		andi.b	#$F,obSubtype(a0)

Gar_MakeFire:	; Routine 2
		subq.b	#1,obTimeFrame(a0) ; decrement timer
		bne.s	@nofire		; if time remains, branch

		move.b	obDelayAni(a0),obTimeFrame(a0) ; reset timer
		bsr.w	ChkObjectVisible
		bne.s	@nofire
		bsr.w	FindFreeObj
		bne.s	@nofire
		move.b	#id_Gargoyle,0(a1) ; load fireball object
		addq.b	#4,obRoutine(a1) ; use Gar_FireBall routine
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obRender(a0),obRender(a1)
		move.b	obStatus(a0),obStatus(a1)

	@nofire:
		rts
; ===========================================================================

Gar_FireBall:	; Routine 4
		addq.b	#2,obRoutine(a0)
		move.b	#8,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.l	#Map_Gar,obMap(a0)
		move.w	#$2E9,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$98,obColType(a0)
		move.b	#8,obActWid(a0)
		move.b	#2,obFrame(a0)
		addq.w	#8,obY(a0)
		move.w	#$200,obVelX(a0)
		btst	#0,obStatus(a0)	; is gargoyle facing left?
		bne.s	@noflip		; if not, branch
		neg.w	obVelX(a0)

	@noflip:
		move.w	#sfx_Fireball,d0
		jsr	(PlaySound_Special).l	; play lava ball sound

Gar_AniFire:	; Routine 6
		move.b	(v_framebyte).w,d0
		andi.b	#7,d0
		bne.s	@nochg
		bchg	#0,obFrame(a0)	; change every 8 frames

	@nochg:
		bsr.w	SpeedToPos
		btst	#0,obStatus(a0) ; is fireball moving left?
		bne.s	@isright	; if not, branch
		moveq	#-8,d3
		bsr.w	ObjHitWallLeft
		tst.w	d1
		bmi.w	DeleteObject	; delete if the fireball hits a	wall
		rts

	@isright:
		moveq	#8,d3
		bsr.w	ObjHitWallRight
		tst.w	d1
		bmi.w	DeleteObject
		rts

Map_Gar:	include	"_maps\Gargoyle.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 63 - platforms on a conveyor belt (LZ)
; ---------------------------------------------------------------------------

; Obj63:
LabyrinthConvey:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	LCon_Index(pc,d0.w),d1
		jsr	LCon_Index(pc,d1.w)
		out_of_range.s	loc_1236A,$30(a0)

LCon_Display:
		bra.w	DisplaySprite
; ===========================================================================

loc_1236A:
		cmpi.b	#2,(v_act).w
		bne.s	loc_12378
		cmpi.w	#-$80,d0
		bhs.s	LCon_Display

loc_12378:
		move.b	$2F(a0),d0
		bpl.w	DeleteObject
		andi.w	#$7F,d0
		lea	(v_obj63).w,a2
		bclr	#0,(a2,d0.w)
		bra.w	DeleteObject
; ===========================================================================
LCon_Index:	dc.w LCon_Main-LCon_Index
		dc.w loc_124B2-LCon_Index
		dc.w loc_124C2-LCon_Index
		dc.w loc_124DE-LCon_Index
; ===========================================================================

LCon_Main:	; Routine 0
		move.b	obSubtype(a0),d0
		bmi.w	loc_12460
		addq.b	#2,obRoutine(a0)
		move.l	#Map_LConv,obMap(a0)
		move.w	#$43F6,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)
		cmpi.b	#$7F,obSubtype(a0)
		bne.s	loc_123E2
		addq.b	#4,obRoutine(a0)
		move.w	#$3F6,obGfx(a0)
		move.b	#1,obPriority(a0)
		bra.w	loc_124DE
; ===========================================================================

loc_123E2:
		move.b	#4,obFrame(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		move.w	d0,d1
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	LCon_Data(pc),a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,$38(a0)
		move.w	(a2)+,$30(a0)
		move.l	a2,$3C(a0)
		andi.w	#$F,d1
		lsl.w	#2,d1
		move.b	d1,$38(a0)
		move.b	#4,$3A(a0)
		tst.b	(f_conveyrev).w
		beq.s	loc_1244C
		move.b	#1,$3B(a0)
		neg.b	$3A(a0)
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		blo.s	loc_12448
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.s	loc_12448
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_12448:
		move.b	d1,$38(a0)

loc_1244C:
		move.w	(a2,d1.w),$34(a0)
		move.w	2(a2,d1.w),$36(a0)
		bsr.w	LCon_ChangeDir
		bra.w	loc_124B2
; ===========================================================================

loc_12460:
		move.b	d0,$2F(a0)
		andi.w	#$7F,d0
		lea	(v_obj63).w,a2
		bset	#0,(a2,d0.w)
		bne.w	DeleteObject
		add.w	d0,d0
		andi.w	#$1E,d0
		addi.w	#ObjPosLZPlatform_Index-ObjPos_Index,d0
		lea	(ObjPos_Index).l,a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d1
		movea.l	a0,a1
		bra.s	LCon_MakePtfms
; ===========================================================================

LCon_Loop:
		bsr.w	FindFreeObj
		bne.s	loc_124AA

LCon_MakePtfms:
		move.b	#id_LabyrinthConvey,0(a1)
		move.w	(a2)+,obX(a1)
		move.w	(a2)+,obY(a1)
		move.w	(a2)+,d0
		move.b	d0,obSubtype(a1)

loc_124AA:
		dbf	d1,LCon_Loop

		addq.l	#4,sp
		rts
; ===========================================================================

loc_124B2:	; Routine 2
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(PlatformObject).l
		bra.w	sub_12502
; ===========================================================================

loc_124C2:	; Routine 4
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(ExitPlatform).l
		move.w	obX(a0),-(sp)
		bsr.w	sub_12502
		move.w	(sp)+,d2
		jmp	(MvSonicOnPtfm2).l
; ===========================================================================

loc_124DE:	; Routine 6
		move.w	(v_framecount).w,d0
		andi.w	#3,d0
		bne.s	loc_124FC
		moveq	#1,d1
		tst.b	(f_conveyrev).w
		beq.s	loc_124F2
		neg.b	d1

loc_124F2:
		add.b	d1,obFrame(a0)
		andi.b	#3,obFrame(a0)

loc_124FC:
		addq.l	#4,sp
		bra.w	RememberState

sub_12502:
		tst.b	(f_switch+$E).w
		beq.s	loc_12520
		tst.b	$3B(a0)
		bne.s	loc_12520
		move.b	#1,$3B(a0)
		move.b	#1,(f_conveyrev).w
		neg.b	$3A(a0)
		bra.s	loc_12534
; ===========================================================================

loc_12520:
		move.w	obX(a0),d0
		cmp.w	$34(a0),d0
		bne.s	loc_1256A
		move.w	obY(a0),d0
		cmp.w	$36(a0),d0
		bne.s	loc_1256A

loc_12534:
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		blo.s	loc_12552
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.s	loc_12552
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_12552:
		move.b	d1,$38(a0)
		movea.l	$3C(a0),a1
		move.w	(a1,d1.w),$34(a0)
		move.w	2(a1,d1.w),$36(a0)
		bsr.w	LCon_ChangeDir

loc_1256A:
		bsr.w	SpeedToPos
		rts
; End of function sub_12502

LCon_ChangeDir:
		moveq	#0,d0
		move.w	#-$100,d2
		move.w	obX(a0),d0
		sub.w	$34(a0),d0
		bhs.s	loc_12584
		neg.w	d0
		neg.w	d2

loc_12584:
		moveq	#0,d1
		move.w	#-$100,d3
		move.w	obY(a0),d1
		sub.w	$36(a0),d1
		bhs.s	loc_12598
		neg.w	d1
		neg.w	d3

loc_12598:
		cmp.w	d0,d1
		blo.s	loc_125C2
		move.w	obX(a0),d0
		sub.w	$34(a0),d0
		beq.s	loc_125AE
		ext.l	d0
		asl.l	#8,d0
		divs.w	d1,d0
		neg.w	d0

loc_125AE:
		move.w	d0,obVelX(a0)
		move.w	d3,obVelY(a0)
		swap	d0
		move.w	d0,obX+2(a0)
		clr.w	obY+2(a0)
		rts
; ===========================================================================

loc_125C2:
		move.w	obY(a0),d1
		sub.w	$36(a0),d1
		beq.s	loc_125D4
		ext.l	d1
		asl.l	#8,d1
		divs.w	d0,d1
		neg.w	d1

loc_125D4:
		move.w	d1,obVelY(a0)
		move.w	d2,obVelX(a0)
		swap	d1
		move.w	d1,obY+2(a0)
		clr.w	obX+2(a0)
		rts
; End of function LCon_ChangeDir

; ===========================================================================
LCon_Data:	dc.w word_125F4-LCon_Data
		dc.w word_12610-LCon_Data
		dc.w word_12628-LCon_Data
		dc.w word_1263C-LCon_Data
		dc.w word_12650-LCon_Data
		dc.w word_12668-LCon_Data
word_125F4:	dc.w $18, $1070, $1078,	$21A, $10BE, $260, $10BE, $393
		dc.w $108C, $3C5, $1022, $390, $1022, $244
word_12610:	dc.w $14, $1280, $127E,	$280, $12CE, $2D0, $12CE, $46E
		dc.w $1232, $420, $1232, $2CC
word_12628:	dc.w $10, $D68,	$D22, $482, $D22, $5DE,	$DAE, $5DE, $DAE, $482
word_1263C:	dc.w $10, $DA0,	$D62, $3A2, $DEE, $3A2,	$DEE, $4DE, $D62, $4DE
word_12650:	dc.w $14, $D00,	$CAC, $242, $DDE, $242,	$DDE, $3DE, $C52, $3DE,	$C52, $29C
word_12668:	dc.w $10, $1300, $1252,	$20A, $13DE, $20A, $13DE, $2BE,	$1252, $2BE

Map_LConv:	include	"_maps\LZ Conveyor.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 64 - bubbles (LZ)
; ---------------------------------------------------------------------------

; Obj64:
Bubble:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bub_Index(pc,d0.w),d1
		jmp	Bub_Index(pc,d1.w)
; ===========================================================================
Bub_Index:	dc.w Bub_Main-Bub_Index
		dc.w Bub_Animate-Bub_Index
		dc.w Bub_ChkWater-Bub_Index
		dc.w Bub_Display-Bub_Index
		dc.w Bub_Delete-Bub_Index
		dc.w Bub_BblMaker-Bub_Index

bub_inhalable:	equ $2E		; flag set when bubble is collectable
bub_origX:	equ $30		; original x-axis position
bub_time:	equ $32		; time until next bubble spawn
bub_freq:	equ $33		; frequency of bubble spawn
; ===========================================================================

Bub_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bub,obMap(a0)
		move.w	#$8348,obGfx(a0)
		move.b	#$84,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#1,obPriority(a0)
		move.b	obSubtype(a0),d0 ; get bubble type
		bpl.s	@bubble		; if type is $0-$7F, branch

		addq.b	#8,obRoutine(a0) ; goto Bub_BblMaker next
		andi.w	#$7F,d0		; read only last 7 bits (deduct	$80)
		move.b	d0,bub_time(a0)
		move.b	d0,bub_freq(a0)	; set bubble frequency
		move.b	#6,obAnim(a0)
		bra.w	Bub_BblMaker
; ===========================================================================

@bubble:
		move.b	d0,obAnim(a0)
		move.w	obX(a0),bub_origX(a0)
		move.w	#-$88,obVelY(a0) ; float bubble upwards
		jsr	(RandomNumber).l
		move.b	d0,obAngle(a0)

Bub_Animate:	; Routine 2
		lea	(Ani_Bub).l,a1
		jsr	(AnimateSprite).l
		cmpi.b	#6,obFrame(a0)	; is bubble full-size?
		bne.s	Bub_ChkWater	; if not, branch

		move.b	#1,bub_inhalable(a0) ; set "inhalable" flag

Bub_ChkWater:	; Routine 4
		move.w	(v_waterpos1).w,d0
		cmp.w	obY(a0),d0	; is bubble underwater?
		blo.s	@wobble		; if yes, branch

@burst:
		move.b	#6,obRoutine(a0) ; goto Bub_Display next
		addq.b	#3,obAnim(a0)	; run "bursting" animation
		bra.w	Bub_Display
; ===========================================================================

@wobble:
		move.b	obAngle(a0),d0
		addq.b	#1,obAngle(a0)
		andi.w	#$7F,d0
		lea	(Drown_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	bub_origX(a0),d0
		move.w	d0,obX(a0)	; change bubble's x-axis position
		tst.b	bub_inhalable(a0)
		beq.s	@display
		bsr.w	Bub_ChkSonic	; has Sonic touched the bubble?
		beq.s	@display	; if not, branch

		bsr.w	ResumeMusic	; cancel countdown music
		move.w	#sfx_Bubble,d0
		jsr	(PlaySound_Special).l	; play collecting bubble sound
		lea	(v_player).w,a1
		clr.w	obVelX(a1)
		clr.w	obVelY(a1)
		clr.w	obInertia(a1)	; stop Sonic
		move.b	#id_GetAir,obAnim(a1) ; use bubble-collecting animation
		move.w	#$23,$3E(a1)
		move.b	#0,$3C(a1)
		bclr	#5,obStatus(a1)
		bclr	#4,obStatus(a1)
		btst	#2,obStatus(a1)
		beq.w	@burst
		bclr	#2,obStatus(a1)
		move.b	#$13,obHeight(a1)
		move.b	#9,obWidth(a1)
		subq.w	#5,obY(a1)
		bra.w	@burst
; ===========================================================================

@display:
		bsr.w	SpeedToPos
		tst.b	obRender(a0)
		bpl.s	@delete
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================

Bub_Display:	; Routine 6
		lea	(Ani_Bub).l,a1
		jsr	(AnimateSprite).l
		tst.b	obRender(a0)
		bpl.s	@delete
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================

Bub_Delete:	; Routine 8
		bra.w	DeleteObject
; ===========================================================================

Bub_BblMaker:	; Routine $A
		tst.w	$36(a0)
		bne.s	@loc_12874
		move.w	(v_waterpos1).w,d0
		cmp.w	obY(a0),d0	; is bubble maker underwater?
		bhs.w	@chkdel		; if not, branch
		tst.b	obRender(a0)
		bpl.w	@chkdel
		subq.w	#1,$38(a0)
		bpl.w	@loc_12914
		move.w	#1,$36(a0)

	@tryagain:
		jsr	(RandomNumber).l
		move.w	d0,d1
		andi.w	#7,d0
		cmpi.w	#6,d0		; random number over 6?
		bhs.s	@tryagain	; if yes, branch

		move.b	d0,$34(a0)
		andi.w	#$C,d1
		lea	(Bub_BblTypes).l,a1
		adda.w	d1,a1
		move.l	a1,$3C(a0)
		subq.b	#1,bub_time(a0)
		bpl.s	@loc_12872
		move.b	bub_freq(a0),bub_time(a0)
		bset	#7,$36(a0)

@loc_12872:
		bra.s	@loc_1287C
; ===========================================================================

@loc_12874:
		subq.w	#1,$38(a0)
		bpl.w	@loc_12914

@loc_1287C:
		jsr	(RandomNumber).l
		andi.w	#$1F,d0
		move.w	d0,$38(a0)
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_Bubble,0(a1) ; load bubble object
		move.w	obX(a0),obX(a1)
		jsr	(RandomNumber).l
		andi.w	#$F,d0
		subq.w	#8,d0
		add.w	d0,obX(a1)
		move.w	obY(a0),obY(a1)
		moveq	#0,d0
		move.b	$34(a0),d0
		movea.l	$3C(a0),a2
		move.b	(a2,d0.w),obSubtype(a1)
		btst	#7,$36(a0)
		beq.s	@fail
		jsr	(RandomNumber).l
		andi.w	#3,d0
		bne.s	@loc_buh
		bset	#6,$36(a0)
		bne.s	@fail
		move.b	#2,obSubtype(a1)

@loc_buh:
		tst.b	$34(a0)
		bne.s	@fail
		bset	#6,$36(a0)
		bne.s	@fail
		move.b	#2,obSubtype(a1)

	@fail:
		subq.b	#1,$34(a0)
		bpl.s	@loc_12914
		jsr	(RandomNumber).l
		andi.w	#$7F,d0
		addi.w	#$80,d0
		add.w	d0,$38(a0)
		clr.w	$36(a0)

@loc_12914:
		lea	(Ani_Bub).l,a1
		jsr	(AnimateSprite).l

@chkdel:
		out_of_range.w	DeleteObject
		move.w	(v_waterpos1).w,d0
		cmp.w	obY(a0),d0
		blo.w	DisplaySprite
		rts
; ===========================================================================
; bubble production sequence

; 0 = small bubble, 1 = large bubble

Bub_BblTypes:	dc.b 0,	1, 0, 0, 0, 0, 1, 0, 0,	0, 0, 1, 0, 1, 0, 0, 1,	0

; ===========================================================================

Bub_ChkSonic:
		tst.b	(f_playerctrl).w
		bmi.s	@loc_12998
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		move.w	obX(a0),d1
		subi.w	#$10,d1
		cmp.w	d0,d1
		bhs.s	@loc_12998
		addi.w	#$20,d1
		cmp.w	d0,d1
		blo.s	@loc_12998
		move.w	obY(a1),d0
		move.w	obY(a0),d1
		cmp.w	d0,d1
		bhs.s	@loc_12998
		addi.w	#$10,d1
		cmp.w	d0,d1
		blo.s	@loc_12998
		moveq	#1,d0
		rts
; ===========================================================================

@loc_12998:
		moveq	#0,d0
		rts

		include	"_anim\Bubbles.asm"
Map_Bub:	include	"_maps\Bubbles.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 65 - waterfalls (LZ)
; ---------------------------------------------------------------------------

; Obj65:
Waterfall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	WFall_Index(pc,d0.w),d1
		jmp	WFall_Index(pc,d1.w)
; ===========================================================================
WFall_Index:	dc.w WFall_Main-WFall_Index
		dc.w WFall_Animate-WFall_Index
		dc.w WFall_ChkDel-WFall_Index
		dc.w WFall_OnWater-WFall_Index
		dc.w loc_12B36-WFall_Index
; ===========================================================================

WFall_Main:	; Routine 0
		addq.b	#4,obRoutine(a0)
		move.l	#Map_WFall,obMap(a0)
		move.w	#$4259,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$18,obActWid(a0)
		move.b	#1,obPriority(a0)
		move.b	obSubtype(a0),d0 ; get object type
		bpl.s	@under80	; branch if $00-$7F
		bset	#7,obGfx(a0)

	@under80:
		andi.b	#$F,d0		; read only the 2nd digit
		move.b	d0,obFrame(a0)	; set frame number
		cmpi.b	#9,d0		; is object type $x9 ?
		bne.s	WFall_ChkDel	; if not, branch

		clr.b	obPriority(a0)	; object is in front of Sonic
		subq.b	#2,obRoutine(a0) ; goto WFall_Animate next
		btst	#6,obSubtype(a0) ; is object type $49 ?
		beq.s	@not49		; if not, branch

		move.b	#6,obRoutine(a0) ; goto WFall_OnWater next

	@not49:
		btst	#5,obSubtype(a0) ; is object type $A9 ?
		beq.s	WFall_Animate	; if not, branch
		move.b	#8,obRoutine(a0) ; goto loc_12B36 next

WFall_Animate:	; Routine 2
		lea	(Ani_WFall).l,a1
		jsr	(AnimateSprite).l

WFall_ChkDel:	; Routine 4
		bra.w	RememberState
; ===========================================================================

WFall_OnWater:	; Routine 6
		move.w	(v_waterpos1).w,d0
		subi.w	#$10,d0
		move.w	d0,obY(a0)	; match object position	to water height
		bra.s	WFall_Animate
; ===========================================================================

loc_12B36:	; Routine 8
		bclr	#7,obGfx(a0)
		cmpi.b	#7,(v_lvllayout+$106).w
		bne.s	@animate
		bset	#7,obGfx(a0)

	@animate:
		bra.s	WFall_Animate

		include	"_anim\Waterfalls.asm"
Map_WFall	include	"_maps\Waterfalls.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 01 - Sonic
; ---------------------------------------------------------------------------

; Obj01:
SonicPlayer:
		tst.w	(v_debuguse).w	; is debug mode being used?
		beq.s	Sonic_Normal	; if not, branch
		jmp	(DebugMode).l
; ===========================================================================

Sonic_Normal:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Sonic_Index(pc,d0.w),d1
		jmp	Sonic_Index(pc,d1.w)
; ===========================================================================
Sonic_Index:	dc.w Sonic_Main-Sonic_Index
		dc.w Sonic_Control-Sonic_Index
		dc.w Sonic_Hurt-Sonic_Index
		dc.w Sonic_Death-Sonic_Index
		dc.w Sonic_ResetLevel-Sonic_Index
; ===========================================================================

Sonic_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$13,obHeight(a0)
		move.b	#9,obWidth(a0)
		move.l	#Map_Sonic,obMap(a0)
		move.w	#$780,obGfx(a0)
		move.b	#2,obPriority(a0)
		move.b	#$18,obActWid(a0)
		move.b	#4,obRender(a0)
		move.w	#$600,(v_sonspeedmax).w ; Sonic's top speed
		move.w	#$C,(v_sonspeedacc).w ; Sonic's acceleration
		move.w	#$80,(v_sonspeeddec).w ; Sonic's deceleration

Sonic_Control:	; Routine 2
		tst.w	(f_debugmode).w	; is debug cheat enabled?
		beq.s	loc_12C58	; if not, branch
		btst	#bitB,(v_jpadpress1).w ; is button B pressed?
		beq.s	loc_12C58	; if not, branch
		move.w	#1,(v_debuguse).w ; change Sonic into a ring/item
		clr.b	(f_lockctrl).w
		rts
; ===========================================================================

loc_12C58:
		tst.b	(f_lockctrl).w	; are controls locked?
		bne.s	loc_12C64	; if yes, branch
		move.w	(v_jpadhold1).w,(v_jpadhold2).w ; enable joypad control

loc_12C64:
		btst	#0,(f_playerctrl).w ; are controls locked?
		bne.s	loc_12C7E	; if yes, branch
		moveq	#0,d0
		move.b	obStatus(a0),d0
		andi.w	#6,d0
		move.w	Sonic_Modes(pc,d0.w),d1
		jsr	Sonic_Modes(pc,d1.w)

loc_12C7E:
		bsr.s	Sonic_Display
		bsr.w	Sonic_RecordPosition
		bsr.w	Sonic_Water
		move.b	(v_anglebuffer).w,$36(a0)
		move.b	(v_anglebuffer2).w,$37(a0)
		tst.b	(f_wtunnelmode).w
		beq.s	loc_12CA6
		tst.b	obAnim(a0)
		bne.s	loc_12CA6
		move.b	obNextAni(a0),obAnim(a0)

loc_12CA6:
		bsr.w	Sonic_Animate
		tst.b	(f_playerctrl).w
		bmi.s	loc_12CB6
		jsr	(ReactToItem).l

loc_12CB6:
		bsr.w	Sonic_Loops
		bsr.w	Sonic_LoadGfx
		rts
; ===========================================================================
Sonic_Modes:	dc.w Sonic_MdNormal-Sonic_Modes
		dc.w Sonic_MdJump-Sonic_Modes
		dc.w Sonic_MdRoll-Sonic_Modes
		dc.w Sonic_MdJump2-Sonic_Modes
; ---------------------------------------------------------------------------
; Music to play	after invincibility wears off
; ---------------------------------------------------------------------------
MusicList2:
		dc.b bgm_GHZ
		dc.b bgm_LZ
		dc.b bgm_MZ
		dc.b bgm_SLZ
		dc.b bgm_SYZ
		dc.b bgm_SBZ
		; The ending doesn't get an entry
		even

; ---------------------------------------------------------------------------
; Subroutine to display Sonic and set music
; ---------------------------------------------------------------------------

Sonic_Display:
		move.w	flashtime(a0),d0
		beq.s	@display
		subq.w	#1,flashtime(a0)
		lsr.w	#3,d0
		bhs.s	@chkinvincible

	@display:
		jsr	(DisplaySprite).l

	@chkinvincible:
		tst.b	(v_invinc).w	; does Sonic have invincibility?
		beq.s	@chkshoes	; if not, branch
		tst.w	invtime(a0)	; check time remaining for invinciblity
		beq.s	@chkshoes	; if no time remains, branch
		subq.w	#1,invtime(a0)	; subtract 1 from time
		bne.s	@chkshoes
		tst.b	(f_lockscreen).w
		bne.s	@removeinvincible
		cmpi.w	#$C,(v_air).w
		blo.s	@removeinvincible
		moveq	#0,d0
		move.b	(v_zone).w,d0
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w ; check if level is SBZ3
		bne.s	@music
		moveq	#5,d0		; play SBZ music

	@music:
		lea	(MusicList2).l,a1
		move.b	(a1,d0.w),d0
		jsr	(PlaySound).l	; play normal music

	@removeinvincible:
		move.b	#0,(v_invinc).w ; cancel invincibility

	@chkshoes:
		tst.b	(v_shoes).w	; does Sonic have speed shoes?
		beq.s	@exit		; if not, branch
		tst.w	shoetime(a0)	; check time remaining
		beq.s	@exit
		subq.w	#1,shoetime(a0)	; subtract 1 from time
		bne.s	@exit
		move.w	#$600,(v_sonspeedmax).w ; restore Sonic's speed
		move.w	#$C,(v_sonspeedacc).w ; restore Sonic's acceleration
		move.w	#$80,(v_sonspeeddec).w ; restore Sonic's deceleration
		move.b	#0,(v_shoes).w	; cancel speed shoes
		move.w	#bgm_Slowdown,d0
		jmp	(PlaySound).l	; run music at normal speed

	@exit:
		rts
; ---------------------------------------------------------------------------
; Subroutine to record Sonic's previous positions for invincibility stars
; ---------------------------------------------------------------------------

Sonic_RecordPosition:
		move.w	(v_trackpos).w,d0
		lea	(v_tracksonic).w,a1
		lea	(a1,d0.w),a1
		move.w	obX(a0),(a1)+
		move.w	obY(a0),(a1)+
		addq.b	#4,(v_trackbyte).w
		rts
; End of function Sonic_RecordPosition

; ---------------------------------------------------------------------------
; Subroutine for Sonic when he's underwater
; ---------------------------------------------------------------------------

Sonic_Water:
		cmpi.b	#1,(v_zone).w	; is level LZ?
		beq.s	@islabyrinth	; if yes, branch

	@exit:
		rts
; ===========================================================================

	@islabyrinth:
		move.w	(v_waterpos1).w,d0
		cmp.w	obY(a0),d0	; is Sonic above the water?
		bge.s	@abovewater	; if yes, branch
		bset	#6,obStatus(a0)
		bne.s	@exit
		bsr.w	ResumeMusic
		move.b	#id_DrownCount,(v_sonicbubbles).w ; load bubbles object from Sonic's mouth
		move.b	#$81,(v_sonicbubbles+obSubtype).w
		move.w	#$300,(v_sonspeedmax).w ; change Sonic's top speed
		move.w	#6,(v_sonspeedacc).w ; change Sonic's acceleration
		move.w	#$40,(v_sonspeeddec).w ; change Sonic's deceleration
		asr	obVelX(a0)
		asr	obVelY(a0)
		asr	obVelY(a0)	; slow Sonic
		beq.s	@exit		; branch if Sonic stops moving
		move.b	#id_Splash,(v_splash).w ; load splash object
		move.w	#sfx_Splash,d0
		jmp	(PlaySound_Special).l	 ; play splash sound
; ===========================================================================

@abovewater:
		bclr	#6,obStatus(a0)
		beq.s	@exit
		bsr.w	ResumeMusic
		move.w	#$600,(v_sonspeedmax).w ; restore Sonic's speed
		move.w	#$C,(v_sonspeedacc).w ; restore Sonic's acceleration
		move.w	#$80,(v_sonspeeddec).w ; restore Sonic's deceleration
		asl	obVelY(a0)
		beq.w	@exit
		move.b	#id_Splash,(v_splash).w ; load splash object
		cmpi.w	#-$1000,obVelY(a0)
		bgt.s	@belowmaxspeed
		move.w	#-$1000,obVelY(a0) ; set maximum speed on leaving water

	@belowmaxspeed:
		move.w	#sfx_Splash,d0
		jmp	(PlaySound_Special).l	 ; play splash sound
; End of function Sonic_Water

; ===========================================================================
; ---------------------------------------------------------------------------
; Modes for controlling	Sonic
; ---------------------------------------------------------------------------

Sonic_MdNormal:	; on ground and not rolling
		bsr.w	Sonic_Jump
		bsr.w	Sonic_SlopeResist
		bsr.w	Sonic_Move
		bsr.w	Sonic_Roll
		bsr.w	Sonic_LevelBound
		jsr	(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts
; ===========================================================================

Sonic_MdJump:	; airborne but not rolling
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_JumpDirection
		bsr.w	Sonic_LevelBound
		jsr	(ObjectFall).l
		btst	#6,obStatus(a0)
		beq.s	loc_12E5C
		subi.w	#$28,obVelY(a0)

loc_12E5C:
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts
; ===========================================================================

Sonic_MdRoll:	; rolling on ground
		bsr.w	Sonic_Jump
		bsr.w	Sonic_RollRepel
		bsr.w	Sonic_RollSpeed
		bsr.w	Sonic_LevelBound
		jsr	(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts
; ===========================================================================

Sonic_MdJump2:	; airborne and rolling (usually from a regular jump)
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_JumpDirection
		bsr.w	Sonic_LevelBound
		jsr	(ObjectFall).l
		btst	#6,obStatus(a0)
		beq.s	loc_12EA6
		subi.w	#$28,obVelY(a0)

loc_12EA6:
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts

; ---------------------------------------------------------------------------
; Subroutine to make Sonic walk/run
; ---------------------------------------------------------------------------

Sonic_Move:
		move.w	(v_sonspeedmax).w,d6
		move.w	(v_sonspeedacc).w,d5
		move.w	(v_sonspeeddec).w,d4
		tst.b	(f_slidemode).w
		bne.w	loc_12FEE
		tst.w	$3E(a0)
		bne.w	Sonic_ResetScr
		btst	#bitL,(v_jpadhold2).w ; is left being pressed?
		beq.s	@notleft	; if not, branch
		bsr.w	Sonic_MoveLeft

	@notleft:
		btst	#bitR,(v_jpadhold2).w ; is right being pressed?
		beq.s	@notright	; if not, branch
		bsr.w	Sonic_MoveRight

	@notright:
		move.b	obAngle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0		; is Sonic on a slope?
		bne.w	Sonic_ResetScr	; if yes, branch
		tst.w	obInertia(a0)	; is Sonic moving?
		bne.w	Sonic_ResetScr	; if yes, branch
		bclr	#5,obStatus(a0)
		move.b	#id_Wait,obAnim(a0) ; use "standing" animation
		btst	#3,obStatus(a0)
		beq.s	Sonic_Balance
		moveq	#0,d0
		move.b	standonobject(a0),d0
		lsl.w	#6,d0
		lea	(v_objspace).w,a1
		lea	(a1,d0.w),a1
		tst.b	obStatus(a1)
		bmi.s	Sonic_LookUp
		moveq	#0,d1
		move.b	obActWid(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#4,d2
		add.w	obX(a0),d1
		sub.w	obX(a1),d1
		cmpi.w	#4,d1
		blt.s	loc_12F6A
		cmp.w	d2,d1
		bge.s	loc_12F5A
		bra.s	Sonic_LookUp
; ===========================================================================

Sonic_Balance:
		jsr	(ObjFloorDist).l
		cmpi.w	#$C,d1
		blt.s	Sonic_LookUp
		cmpi.b	#3,$36(a0)
		bne.s	loc_12F62

loc_12F5A:
		bclr	#0,obStatus(a0)
		bra.s	loc_12F70
; ===========================================================================

loc_12F62:
		cmpi.b	#3,$37(a0)
		bne.s	Sonic_LookUp

loc_12F6A:
		bset	#0,obStatus(a0)

loc_12F70:
		move.b	#id_Balance,obAnim(a0) ; use "balancing" animation
		bra.s	Sonic_ResetScr
; ===========================================================================

Sonic_LookUp:
		btst	#bitUp,(v_jpadhold2).w ; is up being pressed?
		beq.s	Sonic_Duck	; if not, branch
		move.b	#id_LookUp,obAnim(a0) ; use "looking up" animation
		cmpi.w	#$C8,(v_lookshift).w
		beq.s	loc_12FC2
		addq.w	#2,(v_lookshift).w
		bra.s	loc_12FC2
; ===========================================================================

Sonic_Duck:
		btst	#bitDn,(v_jpadhold2).w ; is down being pressed?
		beq.s	Sonic_ResetScr	; if not, branch
		move.b	#id_Duck,obAnim(a0) ; use "ducking" animation
		cmpi.w	#8,(v_lookshift).w
		beq.s	loc_12FC2
		subq.w	#2,(v_lookshift).w
		bra.s	loc_12FC2
; ===========================================================================

Sonic_ResetScr:
		cmpi.w	#$60,(v_lookshift).w ; is screen in its default position?
		beq.s	loc_12FC2	; if yes, branch
		bhs.s	loc_12FBE
		addq.w	#4,(v_lookshift).w ; move screen back to default

loc_12FBE:
		subq.w	#2,(v_lookshift).w ; move screen back to default

loc_12FC2:
		move.b	(v_jpadhold2).w,d0
		andi.b	#btnL+btnR,d0	; is left/right pressed?
		bne.s	loc_12FEE	; if yes, branch
		move.w	obInertia(a0),d0
		beq.s	loc_12FEE
		bmi.s	loc_12FE2
		sub.w	d5,d0
		bhs.s	loc_12FDC
		move.w	#0,d0

loc_12FDC:
		move.w	d0,obInertia(a0)
		bra.s	loc_12FEE
; ===========================================================================

loc_12FE2:
		add.w	d5,d0
		bhs.s	loc_12FEA
		move.w	#0,d0

loc_12FEA:
		move.w	d0,obInertia(a0)

loc_12FEE:
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		muls.w	obInertia(a0),d1
		asr.l	#8,d1
		move.w	d1,obVelX(a0)
		muls.w	obInertia(a0),d0
		asr.l	#8,d0
		move.w	d0,obVelY(a0)

loc_1300C:
		move.b	obAngle(a0),d0
		addi.b	#$40,d0
		bmi.s	locret_1307C
		move.b	#$40,d1
		tst.w	obInertia(a0)
		beq.s	locret_1307C
		bmi.s	loc_13024
		neg.w	d1

loc_13024:
		move.b	obAngle(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	Sonic_WalkSpeed
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_1307C
		asl.w	#8,d1
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	loc_13078
		cmpi.b	#$40,d0
		beq.s	loc_13066
		cmpi.b	#$80,d0
		beq.s	loc_13060
		add.w	d1,obVelX(a0)
		bset	#5,obStatus(a0)
		move.w	#0,obInertia(a0)
		rts
; ===========================================================================

loc_13060:
		sub.w	d1,obVelY(a0)
		rts
; ===========================================================================

loc_13066:
		sub.w	d1,obVelX(a0)
		bset	#5,obStatus(a0)
		move.w	#0,obInertia(a0)
		rts
; ===========================================================================

loc_13078:
		add.w	d1,obVelY(a0)

locret_1307C:
		rts
; End of function Sonic_Move

Sonic_MoveLeft:
		move.w	obInertia(a0),d0
		beq.s	loc_13086
		bpl.s	loc_130B2

loc_13086:
		bset	#0,obStatus(a0)
		bne.s	loc_1309A
		bclr	#5,obStatus(a0)
		move.b	#1,obNextAni(a0)

loc_1309A:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_130A6
		move.w	d1,d0

loc_130A6:
		move.w	d0,obInertia(a0)
		move.b	#id_Walk,obAnim(a0) ; use walking animation
		rts
; ===========================================================================

loc_130B2:
		sub.w	d4,d0
		bhs.s	loc_130BA
		move.w	#-$80,d0

loc_130BA:
		move.w	d0,obInertia(a0)
		move.b	obAngle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.s	locret_130E8
		cmpi.w	#$400,d0
		blt.s	locret_130E8
		move.b	#id_Stop,obAnim(a0) ; use "stopping" animation
		bclr	#0,obStatus(a0)
		move.w	#sfx_Skid,d0
		jsr	(PlaySound_Special).l	; play stopping sound

locret_130E8:
		rts
; End of function Sonic_MoveLeft

Sonic_MoveRight:
		move.w	obInertia(a0),d0
		bmi.s	loc_13118
		bclr	#0,obStatus(a0)
		beq.s	loc_13104
		bclr	#5,obStatus(a0)
		move.b	#1,obNextAni(a0)

loc_13104:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_1310C
		move.w	d6,d0

loc_1310C:
		move.w	d0,obInertia(a0)
		move.b	#id_Walk,obAnim(a0) ; use walking animation
		rts
; ===========================================================================

loc_13118:
		add.w	d4,d0
		bhs.s	loc_13120
		move.w	#$80,d0

loc_13120:
		move.w	d0,obInertia(a0)
		move.b	obAngle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.s	locret_1314E
		cmpi.w	#-$400,d0
		bgt.s	locret_1314E
		move.b	#id_Stop,obAnim(a0) ; use "stopping" animation
		bset	#0,obStatus(a0)
		move.w	#sfx_Skid,d0
		jsr	(PlaySound_Special).l	; play stopping sound

locret_1314E:
		rts
; End of function Sonic_MoveRight

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's speed as he rolls
; ---------------------------------------------------------------------------

Sonic_RollSpeed:
		move.w	(v_sonspeedmax).w,d6
		asl.w	#1,d6
		move.w	(v_sonspeedacc).w,d5
		asr.w	#1,d5
		move.w	(v_sonspeeddec).w,d4
		asr.w	#2,d4
		tst.b	(f_slidemode).w
		bne.w	loc_131CC
		tst.w	$3E(a0)
		bne.s	@notright
		btst	#bitL,(v_jpadhold2).w ; is left being pressed?
		beq.s	@notleft	; if not, branch
		bsr.w	Sonic_RollLeft

	@notleft:
		btst	#bitR,(v_jpadhold2).w ; is right being pressed?
		beq.s	@notright	; if not, branch
		bsr.w	Sonic_RollRight

	@notright:
		move.w	obInertia(a0),d0
		beq.s	loc_131AA
		bmi.s	loc_1319E
		sub.w	d5,d0
		bhs.s	loc_13198
		move.w	#0,d0

loc_13198:
		move.w	d0,obInertia(a0)
		bra.s	loc_131AA
; ===========================================================================

loc_1319E:
		add.w	d5,d0
		bhs.s	loc_131A6
		move.w	#0,d0

loc_131A6:
		move.w	d0,obInertia(a0)

loc_131AA:
		tst.w	obInertia(a0)	; is Sonic moving?
		bne.s	loc_131CC	; if yes, branch
		bclr	#2,obStatus(a0)
		move.b	#$13,obHeight(a0)
		move.b	#9,obWidth(a0)
		move.b	#id_Wait,obAnim(a0) ; use "standing" animation
		subq.w	#5,obY(a0)

loc_131CC:
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		muls.w	obInertia(a0),d0
		asr.l	#8,d0
		move.w	d0,obVelY(a0)
		muls.w	obInertia(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	loc_131F0
		move.w	#$1000,d1

loc_131F0:
		cmpi.w	#-$1000,d1
		bge.s	loc_131FA
		move.w	#-$1000,d1

loc_131FA:
		move.w	d1,obVelX(a0)
		bra.w	loc_1300C
; End of function Sonic_RollSpeed

Sonic_RollLeft:
		move.w	obInertia(a0),d0
		beq.s	loc_1320A
		bpl.s	loc_13218

loc_1320A:
		bset	#0,obStatus(a0)
		move.b	#id_Roll,obAnim(a0) ; use "rolling" animation
		rts
; ===========================================================================

loc_13218:
		sub.w	d4,d0
		bhs.s	loc_13220
		move.w	#-$80,d0

loc_13220:
		move.w	d0,obInertia(a0)
		rts
; End of function Sonic_RollLeft

Sonic_RollRight:
		move.w	obInertia(a0),d0
		bmi.s	loc_1323A
		bclr	#0,obStatus(a0)
		move.b	#id_Roll,obAnim(a0) ; use "rolling" animation
		rts
; ===========================================================================

loc_1323A:
		add.w	d4,d0
		bhs.s	loc_13242
		move.w	#$80,d0

loc_13242:
		move.w	d0,obInertia(a0)
		rts
; End of function Sonic_RollRight

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's direction while jumping
; ---------------------------------------------------------------------------

; Sonic_ChgJumpDir:
Sonic_JumpDirection:
		move.w	(v_sonspeedmax).w,d6
		move.w	(v_sonspeedacc).w,d5
		asl.w	#1,d5
		btst	#4,obStatus(a0)
		bne.s	Obj01_ResetScr2
		move.w	obVelX(a0),d0
		btst	#bitL,(v_jpadhold2).w ; is left being pressed?
		beq.s	loc_13278	; if not, branch
		bset	#0,obStatus(a0)
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_13278
		move.w	d1,d0

loc_13278:
		btst	#bitR,(v_jpadhold2).w ; is right being pressed?
		beq.s	Obj01_JumpMove	; if not, branch
		bclr	#0,obStatus(a0)
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	Obj01_JumpMove
		move.w	d6,d0

Obj01_JumpMove:
		move.w	d0,obVelX(a0)	; change Sonic's horizontal speed

Obj01_ResetScr2:
		cmpi.w	#$60,(v_lookshift).w ; is the screen in its default position?
		beq.s	loc_132A4	; if yes, branch
		bhs.s	loc_132A0
		addq.w	#4,(v_lookshift).w

loc_132A0:
		subq.w	#2,(v_lookshift).w

loc_132A4:
		cmpi.w	#-$400,obVelY(a0) ; is Sonic moving faster than -$400 upwards?
		blo.s	locret_132D2	; if yes, branch
		move.w	obVelX(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_132D2
		bmi.s	loc_132C6
		sub.w	d1,d0
		bhs.s	loc_132C0
		move.w	#0,d0

loc_132C0:
		move.w	d0,obVelX(a0)
		rts
; ===========================================================================

loc_132C6:
		sub.w	d1,d0
		blo.s	loc_132CE
		move.w	#0,d0

loc_132CE:
		move.w	d0,obVelX(a0)

locret_132D2:
		rts
; End of function Sonic_JumpDirection

; ---------------------------------------------------------------------------
; Subroutine to prevent	Sonic leaving the boundaries of	a level
; ---------------------------------------------------------------------------

Sonic_LevelBound:
		move.l	obX(a0),d1
		move.w	obVelX(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	(v_limitleft2).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0		; has Sonic touched the side boundary?
		bhi.s	@sides		; if yes, branch
		move.w	(v_limitright2).w,d0
		addi.w	#$128,d0
		tst.b	(f_lockscreen).w
		bne.s	@screenlocked
		addi.w	#$40,d0

	@screenlocked:
		cmp.w	d1,d0		; has Sonic touched the side boundary?
		bls.s	@sides		; if yes, branch

	@chkbottom:
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0	; has Sonic touched the bottom boundary?
		blt.s	@bottom		; if yes, branch
		rts
; ===========================================================================

@bottom:
		cmpi.w	#(id_SBZ<<8)+1,(v_zone).w ; is level SBZ2 ?
		bne.w	KillSonic	; if not, kill Sonic
		cmpi.w	#$2000,(v_player+obX).w
		blo.w	KillSonic
		clr.b	(v_lastlamp).w	; clear lamppost counter
		move.w	#1,(f_restart).w ; restart the level
		move.w	#(id_LZ<<8)+3,(v_zone).w ; set level to SBZ3 (LZ4)
		rts
; ===========================================================================

@sides:
		move.w	d0,obX(a0)
		move.w	#0,obX+2(a0)
		move.w	#0,obVelX(a0)	; stop Sonic moving
		move.w	#0,obInertia(a0)
		bra.s	@chkbottom
; End of function Sonic_LevelBound

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to roll when he's moving
; ---------------------------------------------------------------------------

Sonic_Roll:
		tst.b	(f_slidemode).w
		bne.s	@noroll
		move.w	obInertia(a0),d0
		bpl.s	@ispositive
		neg.w	d0

	@ispositive:
		cmpi.w	#$80,d0		; is Sonic moving at $80 speed or faster?
		blo.s	@noroll		; if not, branch
		move.b	(v_jpadhold2).w,d0
		andi.b	#btnL+btnR,d0	; is left/right being pressed?
		bne.s	@noroll		; if yes, branch
		btst	#bitDn,(v_jpadhold2).w ; is down being pressed?
		bne.s	Sonic_ChkRoll	; if yes, branch

	@noroll:
		rts
; ===========================================================================

Sonic_ChkRoll:
		btst	#2,obStatus(a0)	; is Sonic already rolling?
		beq.s	@roll		; if not, branch
		rts
; ===========================================================================

@roll:
		bset	#2,obStatus(a0)
		move.b	#$E,obHeight(a0)
		move.b	#7,obWidth(a0)
		move.b	#id_Roll,obAnim(a0) ; use "rolling" animation
		addq.w	#5,obY(a0)
		move.w	#sfx_Roll,d0
		jsr	(PlaySound_Special).l	; play rolling sound
		tst.w	obInertia(a0)
		bne.s	@ismoving
		move.w	#$200,obInertia(a0) ; set inertia if 0

	@ismoving:
		rts
; End of function Sonic_Roll

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to jump
; ---------------------------------------------------------------------------

Sonic_Jump:
		move.b	(v_jpadpress2).w,d0
		andi.b	#btnABC,d0	; is A, B or C pressed?
		beq.w	locret_1348E	; if not, branch
		moveq	#0,d0
		move.b	obAngle(a0),d0
		addi.b	#$80,d0
		bsr.w	sub_14D48
		cmpi.w	#6,d1
		blt.w	locret_1348E
		move.w	#$680,d2
		btst	#6,obStatus(a0)
		beq.s	loc_1341C
		move.w	#$380,d2

loc_1341C:
		moveq	#0,d0
		move.b	obAngle(a0),d0
		subi.b	#$40,d0
		jsr	(CalcSine).l
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,obVelX(a0)	; make Sonic jump
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,obVelY(a0)	; make Sonic jump
		bset	#1,obStatus(a0)
		bclr	#5,obStatus(a0)
		addq.l	#4,sp
		move.b	#1,$3C(a0)
		clr.b	$38(a0)
		move.w	#sfx_Jump,d0
		jsr	(PlaySound_Special).l	; play jumping sound
		move.b	#$13,obHeight(a0)
		move.b	#9,obWidth(a0)
		btst	#2,obStatus(a0)
		bne.s	loc_13490
		move.b	#$E,obHeight(a0)
		move.b	#7,obWidth(a0)
		move.b	#id_Roll,obAnim(a0) ; use "jumping" animation
		bset	#2,obStatus(a0)
		addq.w	#5,obY(a0)

locret_1348E:
		rts
; ===========================================================================

loc_13490:
		bset	#4,obStatus(a0)
		rts
; End of function Sonic_Jump

; ---------------------------------------------------------------------------
; Subroutine controlling Sonic's jump height/duration
; ---------------------------------------------------------------------------

Sonic_JumpHeight:
		tst.b	$3C(a0)
		beq.s	loc_134C4
		move.w	#-$400,d1
		btst	#6,obStatus(a0)
		beq.s	loc_134AE
		move.w	#-$200,d1

loc_134AE:
		cmp.w	obVelY(a0),d1
		ble.s	locret_134C2
		move.b	(v_jpadhold2).w,d0
		andi.b	#btnABC,d0	; is A, B or C pressed?
		bne.s	locret_134C2	; if yes, branch
		move.w	d1,obVelY(a0)

locret_134C2:
		rts
; ===========================================================================

loc_134C4:
		cmpi.w	#-$FC0,obVelY(a0)
		bge.s	locret_134D2
		move.w	#-$FC0,obVelY(a0)

locret_134D2:
		rts
; End of function Sonic_JumpHeight

; ---------------------------------------------------------------------------
; Subroutine to slow Sonic walking up a	slope
; ---------------------------------------------------------------------------

Sonic_SlopeResist:
		move.b	obAngle(a0),d0
		addi.b	#$60,d0
		cmpi.b	#$C0,d0
		bhs.s	locret_13508
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		muls.w	#$20,d0
		asr.l	#8,d0
		tst.w	obInertia(a0)
		beq.s	locret_13508
		bmi.s	loc_13504
		tst.w	d0
		beq.s	locret_13502
		add.w	d0,obInertia(a0) ; change Sonic's inertia

locret_13502:
		rts
; ===========================================================================

loc_13504:
		add.w	d0,obInertia(a0)

locret_13508:
		rts
; End of function Sonic_SlopeResist

; ---------------------------------------------------------------------------
; Subroutine to push Sonic down	a slope	while he's rolling
; ---------------------------------------------------------------------------

Sonic_RollRepel:
		move.b	obAngle(a0),d0
		addi.b	#$60,d0
		cmpi.b	#-$40,d0
		bhs.s	locret_13544
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		muls.w	#$50,d0
		asr.l	#8,d0
		tst.w	obInertia(a0)
		bmi.s	loc_1353A
		tst.w	d0
		bpl.s	loc_13534
		asr.l	#2,d0

loc_13534:
		add.w	d0,obInertia(a0)
		rts
; ===========================================================================

loc_1353A:
		tst.w	d0
		bmi.s	loc_13540
		asr.l	#2,d0

loc_13540:
		add.w	d0,obInertia(a0)

locret_13544:
		rts
; End of function Sonic_RollRepel

; ---------------------------------------------------------------------------
; Subroutine to push Sonic down	a slope
; ---------------------------------------------------------------------------

Sonic_SlopeRepel:
		nop
		tst.b	$38(a0)
		bne.s	locret_13580
		tst.w	$3E(a0)
		bne.s	loc_13582
		move.b	obAngle(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	locret_13580
		move.w	obInertia(a0),d0
		bpl.s	loc_1356A
		neg.w	d0

loc_1356A:
		cmpi.w	#$280,d0
		bhs.s	locret_13580
		clr.w	obInertia(a0)
		bset	#1,obStatus(a0)
		move.w	#$1E,$3E(a0)

locret_13580:
		rts
; ===========================================================================

loc_13582:
		subq.w	#1,$3E(a0)
		rts
; End of function Sonic_SlopeRepel

; ---------------------------------------------------------------------------
; Subroutine to return Sonic's angle to 0 as he jumps
; ---------------------------------------------------------------------------

Sonic_JumpAngle:
		move.b	obAngle(a0),d0	; get Sonic's angle
		beq.s	locret_135A2	; if already 0, branch
		bpl.s	loc_13598	; if higher than 0, branch

		addq.b	#2,d0		; increase angle
		bhs.s	loc_13596
		moveq	#0,d0

loc_13596:
		bra.s	loc_1359E
; ===========================================================================

loc_13598:
		subq.b	#2,d0		; decrease angle
		bhs.s	loc_1359E
		moveq	#0,d0

loc_1359E:
		move.b	d0,obAngle(a0)

locret_135A2:
		rts
; End of function Sonic_JumpAngle

; ---------------------------------------------------------------------------
; Subroutine for Sonic to interact with the floor after	jumping/falling
; ---------------------------------------------------------------------------

Sonic_Floor:
		move.w	obVelX(a0),d1
		move.w	obVelY(a0),d2
		jsr	(CalcAngle).l
		move.b	d0,($FFFFFFEC).w ;RobiWanKenobi: these are just called unused in AS
		subi.b	#$20,d0
		move.b	d0,($FFFFFFED).w ; RobiWanKenobi: these really don't do anything
		andi.b	#$C0,d0
		move.b	d0,($FFFFFFEE).w
		cmpi.b	#$40,d0
		beq.w	loc_13680
		cmpi.b	#$80,d0
		beq.w	loc_136E2
		cmpi.b	#$C0,d0
		beq.w	loc_1373E
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_135F0
		sub.w	d1,obX(a0)
		move.w	#0,obVelX(a0)

loc_135F0:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13602
		add.w	d1,obX(a0)
		move.w	#0,obVelX(a0)

loc_13602:
		bsr.w	Sonic_HitFloor
		move.b	d1,($FFFFFFEF).w
		tst.w	d1
		bpl.s	locret_1367E
		move.b	obVelY(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_1361E
		cmp.b	d2,d0
		blt.s	locret_1367E

loc_1361E:
		add.w	d1,obY(a0)
		move.b	d3,obAngle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#id_Walk,obAnim(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_1365C
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0
		beq.s	loc_1364E
		asr	obVelY(a0)
		bra.s	loc_13670
; ===========================================================================

loc_1364E:
		move.w	#0,obVelY(a0)
		move.w	obVelX(a0),obInertia(a0)
		rts
; ===========================================================================

loc_1365C:
		move.w	#0,obVelX(a0)
		cmpi.w	#$FC0,obVelY(a0)
		ble.s	loc_13670
		move.w	#$FC0,obVelY(a0)

loc_13670:
		move.w	obVelY(a0),obInertia(a0)
		tst.b	d3
		bpl.s	locret_1367E
		neg.w	obInertia(a0)

locret_1367E:
		rts
; ===========================================================================

loc_13680:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_1369A
		sub.w	d1,obX(a0)
		move.w	#0,obVelX(a0)
		move.w	obVelY(a0),obInertia(a0)
		rts
; ===========================================================================

loc_1369A:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_136B4
		sub.w	d1,obY(a0)
		tst.w	obVelY(a0)
		bpl.s	locret_136B2
		move.w	#0,obVelY(a0)

locret_136B2:
		rts
; ===========================================================================

loc_136B4:
		tst.w	obVelY(a0)
		bmi.s	locret_136E0
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.s	locret_136E0
		add.w	d1,obY(a0)
		move.b	d3,obAngle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#id_Walk,obAnim(a0)
		move.w	#0,obVelY(a0)
		move.w	obVelX(a0),obInertia(a0)

locret_136E0:
		rts
; ===========================================================================

loc_136E2:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_136F4
		sub.w	d1,obX(a0)
		move.w	#0,obVelX(a0)

loc_136F4:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13706
		add.w	d1,obX(a0)
		move.w	#0,obVelX(a0)

loc_13706:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	locret_1373C
		sub.w	d1,obY(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_13726
		move.w	#0,obVelY(a0)
		rts
; ===========================================================================

loc_13726:
		move.b	d3,obAngle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.w	obVelY(a0),obInertia(a0)
		tst.b	d3
		bpl.s	locret_1373C
		neg.w	obInertia(a0)

locret_1373C:
		rts
; ===========================================================================

loc_1373E:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13758
		add.w	d1,obX(a0)
		move.w	#0,obVelX(a0)
		move.w	obVelY(a0),obInertia(a0)
		rts
; ===========================================================================

loc_13758:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_13772
		sub.w	d1,obY(a0)
		tst.w	obVelY(a0)
		bpl.s	locret_13770
		move.w	#0,obVelY(a0)

locret_13770:
		rts
; ===========================================================================

loc_13772:
		tst.w	obVelY(a0)
		bmi.s	locret_1379E
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.s	locret_1379E
		add.w	d1,obY(a0)
		move.b	d3,obAngle(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#id_Walk,obAnim(a0)
		move.w	#0,obVelY(a0)
		move.w	obVelX(a0),obInertia(a0)

locret_1379E:
		rts
; End of function Sonic_Floor

; ---------------------------------------------------------------------------
; Subroutine to reset Sonic's mode when he lands on the floor
; ---------------------------------------------------------------------------

Sonic_ResetOnFloor:
		btst	#4,obStatus(a0)
		beq.s	loc_137AE
		nop
		nop
		nop

loc_137AE:
		bclr	#5,obStatus(a0)
		bclr	#1,obStatus(a0)
		bclr	#4,obStatus(a0)
		btst	#2,obStatus(a0)
		beq.s	loc_137E4
		bclr	#2,obStatus(a0)
		move.b	#$13,obHeight(a0)
		move.b	#9,obWidth(a0)
		move.b	#id_Walk,obAnim(a0) ; use running/walking animation
		subq.w	#5,obY(a0)

loc_137E4:
		move.b	#0,$3C(a0)
		move.w	#0,(v_itembonus).w
		rts
; End of function Sonic_ResetOnFloor

; ---------------------------------------------------------------------------
; Sonic when he	gets hurt
; ---------------------------------------------------------------------------

; Obj01_Hurt:
Sonic_Hurt:	; Routine 4
		jsr	(SpeedToPos).l
		addi.w	#$30,obVelY(a0)
		btst	#6,obStatus(a0)
		beq.s	loc_1380C
		subi.w	#$20,obVelY(a0)

loc_1380C:
		bsr.w	Sonic_HurtStop
		bsr.w	Sonic_LevelBound
		bsr.w	Sonic_RecordPosition
		bsr.w	Sonic_Animate
		bsr.w	Sonic_LoadGfx
		jmp	(DisplaySprite).l

; ---------------------------------------------------------------------------
; Subroutine to stop Sonic falling after he's been hurt
; ---------------------------------------------------------------------------

Sonic_HurtStop:
		move.w	(v_limitbtm2).w,d0
		addi.w	#$E0,d0
		cmp.w	obY(a0),d0
		blo.w	KillSonic
		bsr.w	Sonic_Floor
		btst	#1,obStatus(a0)
		bne.s	locret_13860
		moveq	#0,d0
		move.w	d0,obVelY(a0)
		move.w	d0,obVelX(a0)
		move.w	d0,obInertia(a0)
		move.b	#id_Walk,obAnim(a0)
		subq.b	#2,obRoutine(a0)
		move.w	#$78,$30(a0)

locret_13860:
		rts
; End of function Sonic_HurtStop

; ---------------------------------------------------------------------------
; Sonic when he	dies
; ---------------------------------------------------------------------------

; Obj01_Death:
Sonic_Death:	; Routine 6
		bsr.w	GameOver
		jsr	(ObjectFall).l
		bsr.w	Sonic_RecordPosition
		bsr.w	Sonic_Animate
		bsr.w	Sonic_LoadGfx
		jmp	(DisplaySprite).l

GameOver:
		move.w	(v_limitbtm2).w,d0
		addi.w	#$100,d0
		cmp.w	obY(a0),d0
		bhs.w	locret_13900
		move.w	#-$38,obVelY(a0)
		addq.b	#2,obRoutine(a0)
		clr.b	(f_timecount).w	; stop time counter
		addq.b	#1,(f_lifecount).w ; update lives counter
		subq.b	#1,(v_lives).w	; subtract 1 from number of lives
		bne.s	loc_138D4
		move.w	#0,$3A(a0)
		move.b	#id_GameOverCard,(v_gameovertext1).w ; load GAME object
		move.b	#id_GameOverCard,(v_gameovertext2).w ; load OVER object
		move.b	#1,(v_gameovertext2+obFrame).w ; set OVER object to correct frame
		clr.b	(f_timeover).w

loc_138C2:
		move.w	#bgm_GameOver,d0
		jsr	(PlaySound).l	; play game over music
		moveq	#3,d0
		jmp	(AddPLC).l	; load game over patterns
; ===========================================================================

loc_138D4:
		move.w	#60,$3A(a0)	; set time delay to 1 second
		tst.b	(f_timeover).w	; is TIME OVER tag set?
		beq.s	locret_13900	; if not, branch
		move.w	#0,$3A(a0)
		move.b	#id_GameOverCard,(v_gameovertext1).w ; load TIME object
		move.b	#id_GameOverCard,(v_gameovertext2).w ; load OVER object
		move.b	#2,(v_gameovertext1+obFrame).w
		move.b	#3,(v_gameovertext2+obFrame).w
		bra.s	loc_138C2
; ===========================================================================

locret_13900:
		rts
; End of function GameOver

; ---------------------------------------------------------------------------
; Sonic when the level is restarted
; ---------------------------------------------------------------------------

Sonic_ResetLevel:; Routine 8
		tst.w	$3A(a0)
		beq.s	locret_13914
		subq.w	#1,$3A(a0)	; subtract 1 from time delay
		bne.s	locret_13914
		move.w	#1,(f_restart).w ; restart the level

	locret_13914:
		rts
; ---------------------------------------------------------------------------
; Subroutine to make Sonic run around loops (GHZ/SLZ)
; ---------------------------------------------------------------------------

Sonic_Loops:
		cmpi.b	#id_SLZ,(v_zone).w ; is level SLZ ?
		beq.s	@isstarlight	; if yes, branch
		tst.b	(v_zone).w	; is level GHZ ?
		bne.w	@noloops	; if not, branch

	@isstarlight:
		move.w	obY(a0),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		move.b	obX(a0),d1
		andi.w	#$7F,d1
		add.w	d1,d0
		lea	(v_lvllayout).w,a1
		move.b	(a1,d0.w),d1	; d1 is the 256x256 tile Sonic is currently on

		cmp.b	(v_256roll1).w,d1 ; is Sonic on a "roll tunnel" tile?
		beq.w	Sonic_ChkRoll	; if yes, branch
		cmp.b	(v_256roll2).w,d1
		beq.w	Sonic_ChkRoll

		cmp.b	(v_256loop1).w,d1 ; is Sonic on a loop tile?
		beq.s	@chkifleft	; if yes, branch
		cmp.b	(v_256loop2).w,d1
		beq.s	@chkifinair
		bclr	#6,obRender(a0) ; return Sonic to high plane
		rts
; ===========================================================================

@chkifinair:
		btst	#1,obStatus(a0)	; is Sonic in the air?
		beq.s	@chkifleft	; if not, branch

		bclr	#6,obRender(a0)	; return Sonic to high plane
		rts
; ===========================================================================

@chkifleft:
		move.w	obX(a0),d2
		cmpi.b	#$2C,d2
		bhs.s	@chkifright

		bclr	#6,obRender(a0)	; return Sonic to high plane
		rts
; ===========================================================================

@chkifright:
		cmpi.b	#$E0,d2
		blo.s	@chkangle1

		bset	#6,obRender(a0)	; send Sonic to low plane
		rts
; ===========================================================================

@chkangle1:
		btst	#6,obRender(a0) ; is Sonic on low plane?
		bne.s	@chkangle2	; if yes, branch

		move.b	obAngle(a0),d1
		beq.s	@done
		cmpi.b	#$80,d1		; is Sonic upside-down?
		bhi.s	@done		; if yes, branch
		bset	#6,obRender(a0)	; send Sonic to low plane
		rts
; ===========================================================================

@chkangle2:
		move.b	obAngle(a0),d1
		cmpi.b	#$80,d1		; is Sonic upright?
		bls.s	@done		; if yes, branch
		bclr	#6,obRender(a0)	; send Sonic to high plane

@noloops:
@done:
		rts
; End of function Sonic_Loops

; ---------------------------------------------------------------------------
; Subroutine to animate	Sonic's sprites
; ---------------------------------------------------------------------------

Sonic_Animate:
		lea	(Ani_Sonic).l,a1
		moveq	#0,d0
		move.b	obAnim(a0),d0
		cmp.b	obNextAni(a0),d0 ; is animation set to restart?
		beq.s	@do		; if not, branch
		move.b	d0,obNextAni(a0) ; set to "no restart"
		move.b	#0,obAniFrame(a0) ; reset animation
		move.b	#0,obTimeFrame(a0) ; reset frame duration

	@do:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation script
		move.b	(a1),d0
		bmi.s	@walkrunroll	; if animation is walk/run/roll/jump, branch
		move.b	obStatus(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,obRender(a0)
		or.b	d1,obRender(a0)
		subq.b	#1,obTimeFrame(a0) ; subtract 1 from frame duration
		bpl.s	@delay		; if time remains, branch
		move.b	d0,obTimeFrame(a0) ; load frame duration

@loadframe:
		moveq	#0,d1
		move.b	obAniFrame(a0),d1 ; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		bmi.s	@end_FF		; if animation is complete, branch

	@next:
		move.b	d0,obFrame(a0)	; load sprite number
		addq.b	#1,obAniFrame(a0) ; next frame number

	@delay:
		rts
; ===========================================================================

@end_FF:
		addq.b	#1,d0		; is the end flag = $FF ?
		bne.s	@end_FE		; if not, branch
		move.b	#0,obAniFrame(a0) ; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.s	@next
; ===========================================================================

@end_FE:
		addq.b	#1,d0		; is the end flag = $FE ?
		bne.s	@end_FD		; if not, branch
		move.b	2(a1,d1.w),d0	; read the next byte in	the script
		sub.b	d0,obAniFrame(a0) ; jump back d0 bytes in the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.s	@next
; ===========================================================================

@end_FD:
		addq.b	#1,d0		; is the end flag = $FD ?
		bne.s	@end		; if not, branch
		move.b	2(a1,d1.w),obAnim(a0) ; read next byte, run that animation

	@end:
		rts
; ===========================================================================

@walkrunroll:
		subq.b	#1,obTimeFrame(a0) ; subtract 1 from frame duration
		bpl.s	@delay		; if time remains, branch
		addq.b	#1,d0		; is animation walking/running?
		bne.w	@rolljump	; if not, branch
		moveq	#0,d1
		move.b	obAngle(a0),d0	; get Sonic's angle
		move.b	obStatus(a0),d2
		andi.b	#1,d2		; is Sonic mirrored horizontally?
		bne.s	@flip		; if yes, branch
		not.b	d0		; reverse angle

	@flip:
		addi.b	#$10,d0		; add $10 to angle
		bpl.s	@noinvert	; if angle is $0-$7F, branch
		moveq	#3,d1

	@noinvert:
		andi.b	#$FC,obRender(a0)
		eor.b	d1,d2
		or.b	d2,obRender(a0)
		btst	#5,obStatus(a0)	; is Sonic pushing something?
		bne.w	@push		; if yes, branch

		lsr.b	#4,d0		; divide angle by $10
		andi.b	#6,d0		; angle must be	0, 2, 4	or 6
		move.w	obInertia(a0),d2 ; get Sonic's speed
		bpl.s	@nomodspeed
		neg.w	d2		; modulus speed

	@nomodspeed:
		lea	(SonAni_Run).l,a1 ; use running	animation
		cmpi.w	#$600,d2	; is Sonic at running speed?
		bhs.s	@running	; if yes, branch

		lea	(SonAni_Walk).l,a1 ; use walking animation
		move.b	d0,d1
		lsr.b	#1,d1
		add.b	d1,d0

	@running:
		add.b	d0,d0
		move.b	d0,d3
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	@belowmax
		moveq	#0,d2		; max animation speed

	@belowmax:
		lsr.w	#8,d2
		move.b	d2,obTimeFrame(a0) ; modify frame duration
		bsr.w	@loadframe
		add.b	d3,obFrame(a0)	; modify frame number
		rts
; ===========================================================================

@rolljump:
		addq.b	#1,d0		; is animation rolling/jumping?
		bne.s	@push		; if not, branch
		move.w	obInertia(a0),d2 ; get Sonic's speed
		bpl.s	@nomodspeed2
		neg.w	d2

	@nomodspeed2:
		lea	(SonAni_Roll2).l,a1 ; use fast animation
		cmpi.w	#$600,d2	; is Sonic moving fast?
		bhs.s	@rollfast	; if yes, branch
		lea	(SonAni_Roll).l,a1 ; use slower animation

	@rollfast:
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	@belowmax2
		moveq	#0,d2

	@belowmax2:
		lsr.w	#8,d2
		move.b	d2,obTimeFrame(a0) ; modify frame duration
		move.b	obStatus(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,obRender(a0)
		or.b	d1,obRender(a0)
		bra.w	@loadframe
; ===========================================================================

@push:
		move.w	obInertia(a0),d2 ; get Sonic's speed
		bmi.s	@negspeed
		neg.w	d2

	@negspeed:
		addi.w	#$800,d2
		bpl.s	@belowmax3
		moveq	#0,d2

	@belowmax3:
		lsr.w	#6,d2
		move.b	d2,obTimeFrame(a0) ; modify frame duration
		lea	(SonAni_Push).l,a1
		move.b	obStatus(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,obRender(a0)
		or.b	d1,obRender(a0)
		bra.w	@loadframe

; End of function Sonic_Animate

		include	"_anim\Sonic.asm"

; ---------------------------------------------------------------------------
; Sonic graphics loading subroutine
; ---------------------------------------------------------------------------

; LoadSonicDynPLC:
Sonic_LoadGfx:
		moveq	#0,d0
		move.b	obFrame(a0),d0	; load frame number
		cmp.b	(v_sonframenum).w,d0 ; has frame changed?
		beq.s	@nochange	; if not, branch

		move.b	d0,(v_sonframenum).w
		lea	(SonicDynPLC).l,a2 ; load PLC script
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1	; read "number of entries" value
		subq.b	#1,d1
		bmi.s	@nochange	; if zero, branch
		lea	(v_sgfx_buffer).w,a3
		move.b	#1,(f_sonframechg).w ; set flag for Sonic graphics DMA

	@readentry:
		moveq	#0,d2
		move.b	(a2)+,d2
		move.w	d2,d0
		lsr.b	#4,d0
		lsl.w	#8,d2
		move.b	(a2)+,d2
		lsl.w	#5,d2
		lea	(Art_Sonic).l,a1
		adda.l	d2,a1

	@loadtile:
		movem.l	(a1)+,d2-d6/a4-a6
		movem.l	d2-d6/a4-a6,(a3)
		lea	$20(a3),a3	; next tile
		dbf	d0,@loadtile	; repeat for number of tiles

		dbf	d1,@readentry	; repeat for number of entries

	@nochange:
		rts

; End of function Sonic_LoadGfx

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0A - drowning countdown numbers and small bubbles that float out of
; Sonic's mouth (LZ)
; ---------------------------------------------------------------------------

; Obj0A:
DrownCount:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Drown_Index(pc,d0.w),d1
		jmp	Drown_Index(pc,d1.w)
; ===========================================================================
Drown_Index:
ptr_Drown_Main:		dc.w Drown_Main-Drown_Index
ptr_Drown_Animate:	dc.w Drown_Animate-Drown_Index
ptr_Drown_ChkWater:	dc.w Drown_ChkWater-Drown_Index
ptr_Drown_Display:	dc.w Drown_Display-Drown_Index
ptr_Drown_Delete:	dc.w Drown_Delete-Drown_Index
ptr_Drown_Countdown:	dc.w Drown_Countdown-Drown_Index
ptr_Drown_AirLeft:	dc.w Drown_AirLeft-Drown_Index
			dc.w Drown_Display-Drown_Index
			dc.w Drown_Delete-Drown_Index

drown_origX:		equ $30		; original x-axis position
drown_time:		equ $38		; time between each number changes

id_Drown_Main:		equ ptr_Drown_Main-Drown_Index		; 0
id_Drown_Animate:	equ ptr_Drown_Animate-Drown_Index		; 2
id_Drown_ChkWater:	equ ptr_Drown_ChkWater-Drown_Index	; 4
id_Drown_Display:	equ ptr_Drown_Display-Drown_Index		; 6
id_Drown_Delete:		equ ptr_Drown_Delete-Drown_Index		; 8
id_Drown_Countdown:	equ ptr_Drown_Countdown-Drown_Index	; $A
id_Drown_AirLeft:	equ ptr_Drown_AirLeft-Drown_Index		; $C
; ===========================================================================

Drown_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bub,obMap(a0)
		move.w	#$8348,obGfx(a0)
		move.b	#$84,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#1,obPriority(a0)
		move.b	obSubtype(a0),d0 ; get bubble type
		bpl.s	@smallbubble	; branch if $00-$7F

		addq.b	#8,obRoutine(a0) ; goto Drown_Countdown next
		move.l	#Map_Drown,obMap(a0)
		move.w	#$440,obGfx(a0)
		andi.w	#$7F,d0
		move.b	d0,$33(a0)
		bra.w	Drown_Countdown
; ===========================================================================

@smallbubble:
		move.b	d0,obAnim(a0)
		move.w	obX(a0),drown_origX(a0)
		move.w	#-$88,obVelY(a0)

Drown_Animate:	; Routine 2
		lea	(Ani_Drown).l,a1
		jsr	(AnimateSprite).l

Drown_ChkWater:	; Routine 4
		move.w	(v_waterpos1).w,d0
		cmp.w	obY(a0),d0	; has bubble reached the water surface?
		blo.s	@wobble		; if not, branch

		move.b	#id_Drown_Display,obRoutine(a0) ; goto Drown_Display next
		addq.b	#7,obAnim(a0)
		cmpi.b	#$D,obAnim(a0)
		beq.s	Drown_Display
		bra.s	Drown_Display
; ===========================================================================

@wobble:
		tst.b	(f_wtunnelmode).w ; is Sonic in a water tunnel?
		beq.s	@notunnel	; if not, branch
		addq.w	#4,drown_origX(a0)

	@notunnel:
		move.b	obAngle(a0),d0
		addq.b	#1,obAngle(a0)
		andi.w	#$7F,d0
		lea	(Drown_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	drown_origX(a0),d0
		move.w	d0,obX(a0)
		bsr.s	Drown_ShowNumber
		jsr	(SpeedToPos).l
		tst.b	obRender(a0)
		bpl.s	@delete
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================

Drown_Display:	; Routine 6, Routine $E
		bsr.s	Drown_ShowNumber
		lea	(Ani_Drown).l,a1
		jsr	(AnimateSprite).l
		jmp	(DisplaySprite).l
; ===========================================================================

Drown_Delete:	; Routine 8, Routine $10
		jmp	(DeleteObject).l
; ===========================================================================

Drown_AirLeft:	; Routine $C
		cmpi.w	#$C,(v_air).w	; check air remaining
		bhi.s	Drown_AirLeft_Delete		; if higher than $C, branch
		subq.w	#1,drown_time(a0)
		bne.s	@display
		move.b	#id_Drown_Display+8,obRoutine(a0) ; goto Drown_Display next
		addq.b	#7,obAnim(a0)
		bra.s	Drown_Display
; ===========================================================================

	@display:
		lea	(Ani_Drown).l,a1
		jsr	(AnimateSprite).l
		tst.b	obRender(a0)
		bpl.s	Drown_AirLeft_Delete
		jmp	(DisplaySprite).l

Drown_AirLeft_Delete:
		jmp	(DeleteObject).l
; ===========================================================================

Drown_ShowNumber:
		tst.w	drown_time(a0)
		beq.s	@nonumber
		subq.w	#1,drown_time(a0)	; decrement timer
		bne.s	@nonumber	; if time remains, branch
		cmpi.b	#7,obAnim(a0)
		bhs.s	@nonumber

		move.w	#15,drown_time(a0)
		clr.w	obVelY(a0)
		move.b	#$80,obRender(a0)
		move.w	obX(a0),d0
		sub.w	(v_screenposx).w,d0
		addi.w	#$80,d0
		move.w	d0,obX(a0)
		move.w	obY(a0),d0
		sub.w	(v_screenposy).w,d0
		addi.w	#$80,d0
		move.w	d0,obScreenY(a0)
		move.b	#id_Drown_AirLeft,obRoutine(a0) ; goto Drown_AirLeft next

	@nonumber:
		rts
; ===========================================================================
Drown_WobbleData:
		dc.b 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2
		dc.b 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
		dc.b 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2
		dc.b 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
		dc.b 0, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3
		dc.b -3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -3
		dc.b -3, -3, -3, -3, -3, -3, -2, -2, -2, -2, -2, -1, -1, -1, -1, -1
		dc.b 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2
		dc.b 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
		dc.b 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2
		dc.b 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
		dc.b 0, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3
		dc.b -3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -3
		dc.b -3, -3, -3, -3, -3, -3, -2, -2, -2, -2, -2, -1, -1, -1, -1, -1
; ===========================================================================

Drown_Countdown:; Routine $A
		tst.w	$2C(a0)
		bne.w	@loc_13F86
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.w	@nocountdown
		btst	#6,(v_player+obStatus).w ; is Sonic underwater?
		beq.w	@nocountdown	; if not, branch

		subq.w	#1,drown_time(a0)	; decrement timer
		bpl.w	@nochange	; branch if time remains
		move.w	#59,drown_time(a0)
		move.w	#1,$36(a0)
		jsr	(RandomNumber).l
		andi.w	#1,d0
		move.b	d0,$34(a0)
		move.w	(v_air).w,d0	; check air remaining
		cmpi.w	#25,d0
		beq.s	@warnsound	; play sound if air is 25
		cmpi.w	#20,d0
		beq.s	@warnsound
		cmpi.w	#15,d0
		beq.s	@warnsound
		cmpi.w	#12,d0
		bhi.s	@reduceair	; if air is above 12, branch

		bne.s	@skipmusic	; if air is less than 12, branch
		move.w	#bgm_Drowning,d0
		jsr	(PlaySound).l	; play countdown music

	@skipmusic:
		subq.b	#1,$32(a0)
		bpl.s	@reduceair
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)
		bra.s	@reduceair
; ===========================================================================

@warnsound:
		move.w	#sfx_Warning,d0
		jsr	(PlaySound_Special).l	; play "ding-ding" warning sound

@reduceair:
		subq.w	#1,(v_air).w	; subtract 1 from air remaining
		bhs.w	@gotomakenum	; if air is above 0, branch

		; Sonic drowns here
		bsr.w	ResumeMusic
		move.b	#$81,(f_playerctrl).w ; lock controls and disable object interaction
		move.w	#sfx_Drown,d0
		jsr	(PlaySound_Special).l	; play drowning sound
		move.b	#$A,$34(a0)
		move.w	#1,$36(a0)
		move.w	#$78,$2C(a0)
		move.l	a0,-(sp)
		lea	(v_player).w,a0
		bsr.w	Sonic_ResetOnFloor
		move.b	#id_Drown,obAnim(a0)	; use Sonic's drowning animation
		bset	#1,obStatus(a0)
		bset	#7,obGfx(a0)
		move.w	#0,obVelY(a0)
		move.w	#0,obVelX(a0)
		move.w	#0,obInertia(a0)
		move.b	#1,(f_nobgscroll).w
		movea.l	(sp)+,a0
		rts
; ===========================================================================

@loc_13F86:
		subq.w	#1,$2C(a0)
		bne.s	@loc_13F94
		move.b	#6,(v_player+obRoutine).w
		rts
; ===========================================================================

	@loc_13F94:
		move.l	a0,-(sp)
		lea	(v_player).w,a0
		jsr	(SpeedToPos).l
		addi.w	#$10,obVelY(a0)
		movea.l	(sp)+,a0
		bra.s	@nochange
; ===========================================================================

@gotomakenum:
		bra.s	@makenum
; ===========================================================================

@nochange:
		tst.w	$36(a0)
		beq.w	@nocountdown
		subq.w	#1,$3A(a0)
		bpl.w	@nocountdown

@makenum:
		jsr	(RandomNumber).l
		andi.w	#$F,d0
		move.w	d0,$3A(a0)
		jsr	(FindFreeObj).l
		bne.w	@nocountdown
		move.b	#id_DrownCount,0(a1) ; load object
		move.w	(v_player+obX).w,obX(a1) ; match X position to Sonic
		moveq	#6,d0
		btst	#0,(v_player+obStatus).w
		beq.s	@noflip
		neg.w	d0
		move.b	#$40,obAngle(a1)

	@noflip:
		add.w	d0,obX(a1)
		move.w	(v_player+obY).w,obY(a1)
		move.b	#6,obSubtype(a1)
		tst.w	$2C(a0)
		beq.w	@loc_1403E
		andi.w	#7,$3A(a0)
		addi.w	#0,$3A(a0)
		move.w	(v_player+obY).w,d0
		subi.w	#$C,d0
		move.w	d0,obY(a1)
		jsr	(RandomNumber).l
		move.b	d0,obAngle(a1)
		move.w	(v_framecount).w,d0
		andi.b	#3,d0
		bne.s	@loc_14082
		move.b	#$E,obSubtype(a1)
		bra.s	@loc_14082
; ===========================================================================

@loc_1403E:
		btst	#7,$36(a0)
		beq.s	@loc_14082
		move.w	(v_air).w,d2
		lsr.w	#1,d2
		jsr	(RandomNumber).l
		andi.w	#3,d0
		bne.s	@loc_1406A
		bset	#6,$36(a0)
		bne.s	@loc_14082
		move.b	d2,obSubtype(a1)
		move.w	#$1C,drown_time(a1)

	@loc_1406A:
		tst.b	$34(a0)
		bne.s	@loc_14082
		bset	#6,$36(a0)
		bne.s	@loc_14082
		move.b	d2,obSubtype(a1)
		move.w	#$1C,drown_time(a1)

@loc_14082:
		subq.b	#1,$34(a0)
		bpl.s	@nocountdown
		clr.w	$36(a0)

@nocountdown:
		rts

; ---------------------------------------------------------------------------
; Subroutine to play music for LZ/SBZ3 after a countdown
; ---------------------------------------------------------------------------

ResumeMusic:
		cmpi.w	#12,(v_air).w	; more than 12 seconds of air left?
		bhi.s	@over12		; if yes, branch
		move.w	#bgm_LZ,d0	; play LZ music
		cmpi.w	#(id_LZ<<8)+3,(v_zone).w ; check if level is 0103 (SBZ3)
		bne.s	@notsbz
		move.w	#bgm_SBZ,d0	; play SBZ music

	@notsbz:
		tst.b	(v_invinc).w ; is Sonic invincible?
		beq.s	@notinvinc ; if not, branch
		move.w	#bgm_Invincible,d0

	@notinvinc:
		tst.b	(f_lockscreen).w ; is Sonic at a boss?
		beq.s	@playselected ; if not, branch
		move.w	#bgm_Boss,d0

	@playselected:
		jsr	(PlaySound).l

	@over12:
		move.w	#30,(v_air).w	; reset air to 30 seconds
		clr.b	(v_sonicbubbles+$32).w
		rts
; End of function ResumeMusic

; ===========================================================================

		include	"_anim\Drowning Countdown.asm"
Map_Drown:	include	"_maps\Drowning Countdown.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 38 - shield and invincibility stars
; ---------------------------------------------------------------------------

; Obj38:
ShieldItem:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Shi_Index(pc,d0.w),d1
		jmp	Shi_Index(pc,d1.w)
; ===========================================================================
Shi_Index:	dc.w Shi_Main-Shi_Index
		dc.w Shi_Shield-Shi_Index
		dc.w Shi_Stars-Shi_Index
; ===========================================================================

Shi_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Shield,obMap(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#$10,obActWid(a0)
		tst.b	obAnim(a0)	; is object a shield?
		bne.s	@stars		; if not, branch
		move.w	#$541,obGfx(a0)	; shield specific code
		rts
; ===========================================================================

@stars:
		addq.b	#2,obRoutine(a0) ; goto Shi_Stars next
		move.w	#$55C,obGfx(a0)
		rts
; ===========================================================================

Shi_Shield:	; Routine 2
		tst.b	(v_invinc).w	; does Sonic have invincibility?
		bne.s	@remove		; if yes, branch
		tst.b	(v_shield).w	; does Sonic have shield?
		beq.s	@delete		; if not, branch
		move.w	(v_player+obX).w,obX(a0)
		move.w	(v_player+obY).w,obY(a0)
		move.b	(v_player+obStatus).w,obStatus(a0)
		lea	(Ani_Shield).l,a1
		jsr	(AnimateSprite).l
		jmp	(DisplaySprite).l

	@remove:
		rts

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================

Shi_Stars:	; Routine 4
		tst.b	(v_invinc).w	; does Sonic have invincibility?
		beq.s	Shi_Start_Delete		; if not, branch
		move.w	(v_trackpos).w,d0 ; get index value for tracking data
		move.b	obAnim(a0),d1
		subq.b	#1,d1
		bra.s	@trail
; ===========================================================================
		lsl.b	#4,d1
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0
		addq.b	#4,d1
		andi.b	#$F,d1
		move.b	d1,$30(a0)
		bra.s	@b
; ===========================================================================

@trail:
		lsl.b	#3,d1		; multiply animation number by 8
		move.b	d1,d2
		add.b	d1,d1
		add.b	d2,d1		; multiply by 3
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0		; use earlier tracking data to create trail
		addq.b	#4,d1
		cmpi.b	#$18,d1
		blo.s	@a
		moveq	#0,d1

	@a:
		move.b	d1,$30(a0)

	@b:
		lea	(v_tracksonic).w,a1
		lea	(a1,d0.w),a1
		move.w	(a1)+,obX(a0)
		move.w	(a1)+,obY(a0)
		move.b	(v_player+obStatus).w,obStatus(a0)
		lea	(Ani_Shield).l,a1
		jsr	(AnimateSprite).l
		jmp	(DisplaySprite).l
; ===========================================================================

Shi_Start_Delete:
		jmp	(DeleteObject).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4A - special stage entry from beta
; ---------------------------------------------------------------------------

; Obj4A:
VanishSonic:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Van_Index(pc,d0.w),d1
		jmp	Van_Index(pc,d1.w)
; ===========================================================================
Van_Index:	dc.w Van_Main-Van_Index
		dc.w Van_RmvSonic-Van_Index
		dc.w Van_LoadSonic-Van_Index

van_time:	equ $30		; time for Sonic to disappear
; ===========================================================================

Van_Main:	; Routine 0
		tst.l	(v_plc_buffer).w ; are pattern load cues empty?
		beq.s	@isempty	; if yes, branch
		rts

	@isempty:
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Vanish,obMap(a0)
		move.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#$38,obActWid(a0)
		move.w	#$541,obGfx(a0)
		move.w	#120,van_time(a0) ; set time for Sonic's disappearance to 2 seconds

Van_RmvSonic:	; Routine 2
		move.w	(v_player+obX).w,obX(a0)
		move.w	(v_player+obY).w,obY(a0)
		move.b	(v_player+obStatus).w,obStatus(a0)
		lea	(Ani_Vanish).l,a1
		jsr	(AnimateSprite).l
		cmpi.b	#2,obFrame(a0)
		bne.s	@display
		tst.b	(v_player).w
		beq.s	@display
		move.b	#0,(v_player).w	; remove Sonic
		move.w	#sfx_SSGoal,d0
		jsr	(PlaySound_Special).l	; play Special Stage "GOAL" sound

	@display:
		jmp	(DisplaySprite).l
; ===========================================================================

Van_LoadSonic:	; Routine 4
		subq.w	#1,van_time(a0)	; subtract 1 from time
		bne.s	@wait		; if time remains, branch
		move.b	#id_SonicPlayer,(v_player).w ; load Sonic object
		jmp	(DeleteObject).l

	@wait:
		rts

		include	"_anim\Special Stage Entry (Unused).asm"
Map_Vanish:	include	"_maps\Special Stage Entry (Unused).asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 08 - water splash (LZ)
; ---------------------------------------------------------------------------

; Obj08:
Splash:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Spla_Index(pc,d0.w),d1
		jmp	Spla_Index(pc,d1.w)
; ===========================================================================
Spla_Index:	dc.w Spla_Main-Spla_Index
		dc.w Spla_Display-Spla_Index
		dc.w Spla_Delete-Spla_Index
; ===========================================================================

Spla_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Splash,obMap(a0)
		ori.b	#4,obRender(a0)
		move.b	#1,obPriority(a0)
		move.b	#$10,obActWid(a0)
		move.w	#$4259,obGfx(a0)
		move.w	(v_player+obX).w,obX(a0) ; copy x-position from Sonic

Spla_Display:	; Routine 2
		move.w	(v_waterpos1).w,obY(a0) ; copy y-position from water height
		lea	(Ani_Splash).l,a1
		jsr	(AnimateSprite).l
		jmp	(DisplaySprite).l
; ===========================================================================

Spla_Delete:	; Routine 4
		jmp	(DeleteObject).l	; delete when animation is complete

		include	"_anim\Shield and Invincibility.asm"
Map_Shield:	include	"_maps\Shield and Invincibility.asm"

		include	"_anim\Water Splash.asm"
Map_Splash:	include	"_maps\Water Splash.asm"

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's angle & position as he walks along the floor
; ---------------------------------------------------------------------------

Sonic_AnglePos:
		btst	#3,obStatus(a0)
		beq.s	loc_14602
		moveq	#0,d0
		move.b	d0,($FFFFF768).w
		move.b	d0,(v_anglebuffer2).w
		rts
; ===========================================================================

loc_14602:
		moveq	#3,d0
		move.b	d0,($FFFFF768).w
		move.b	d0,(v_anglebuffer2).w
		move.b	obAngle(a0),d0
		addi.b	#$20,d0
		bpl.s	loc_14624
		move.b	obAngle(a0),d0
		bpl.s	loc_1461E
		subq.b	#1,d0

loc_1461E:
		addi.b	#$20,d0
		bra.s	loc_14630
; ===========================================================================

loc_14624:
		move.b	obAngle(a0),d0
		bpl.s	loc_1462C
		addq.b	#1,d0

loc_1462C:
		addi.b	#$1F,d0

loc_14630:
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	Sonic_WalkVertL
		cmpi.b	#$80,d0
		beq.w	Sonic_WalkCeiling
		cmpi.b	#$C0,d0
		beq.w	Sonic_WalkVertR
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_146BE
		bpl.s	loc_146C0
		cmpi.w	#-$E,d1
		blt.s	locret_146E6
		add.w	d1,obY(a0)

locret_146BE:
		rts
; ===========================================================================

loc_146C0:
		cmpi.w	#$E,d1
		bgt.s	loc_146CC

loc_146C6:
		add.w	d1,obY(a0)
		rts
; ===========================================================================

loc_146CC:
		tst.b	$38(a0)
		bne.s	loc_146C6
		bset	#1,obStatus(a0)
		bclr	#5,obStatus(a0)
		move.b	#1,obNextAni(a0)
		rts
; ===========================================================================

locret_146E6:
		rts
; End of function Sonic_AnglePos

; ===========================================================================
		move.l	obX(a0),d2
		move.w	obVelX(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.l	d2,obX(a0)
		move.w	#$38,d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,obY(a0)
		rts
; ===========================================================================

locret_1470A:
		rts
; ===========================================================================
		move.l	obY(a0),d3
		move.w	obVelY(a0),d0
		subi.w	#$38,d0
		move.w	d0,obVelY(a0)
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,obY(a0)
		rts
		rts
; ===========================================================================
		move.l	obX(a0),d2
		move.l	obY(a0),d3
		move.w	obVelX(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.w	obVelY(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d2,obX(a0)
		move.l	d3,obY(a0)
		rts

; ---------------------------------------------------------------------------
; Subroutine to change Sonic's angle as he walks along the floor
; ---------------------------------------------------------------------------

Sonic_Angle:
		move.b	(v_anglebuffer2).w,d2
		cmp.w	d0,d1
		ble.s	loc_1475E
		move.b	($FFFFF768).w,d2
		move.w	d0,d1

loc_1475E:
		btst	#0,d2
		bne.s	loc_1476A
		move.b	d2,obAngle(a0)
		rts
; ===========================================================================

loc_1476A:
		move.b	obAngle(a0),d2
		addi.b	#$20,d2
		andi.b	#$C0,d2
		move.b	d2,obAngle(a0)
		rts
; End of function Sonic_Angle

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to his right
; ---------------------------------------------------------------------------

Sonic_WalkVertR:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_147F0
		bpl.s	loc_147F2
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		add.w	d1,obX(a0)

locret_147F0:
		rts
; ===========================================================================

loc_147F2:
		cmpi.w	#$E,d1
		bgt.s	loc_147FE

loc_147F8:
		add.w	d1,obX(a0)
		rts
; ===========================================================================

loc_147FE:
		tst.b	$38(a0)
		bne.s	loc_147F8
		bset	#1,obStatus(a0)
		bclr	#5,obStatus(a0)
		move.b	#1,obNextAni(a0)
		rts
; End of function Sonic_WalkVertR

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk upside-down
; ---------------------------------------------------------------------------

Sonic_WalkCeiling:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_14892
		bpl.s	loc_14894
		cmpi.w	#-$E,d1
		blt.w	locret_146E6
		sub.w	d1,obY(a0)

locret_14892:
		rts
; ===========================================================================

loc_14894:
		cmpi.w	#$E,d1
		bgt.s	loc_148A0

loc_1489A:
		sub.w	d1,obY(a0)
		rts
; ===========================================================================

loc_148A0:
		tst.b	$38(a0)
		bne.s	loc_1489A
		bset	#1,obStatus(a0)
		bclr	#5,obStatus(a0)
		move.b	#1,obNextAni(a0)
		rts
; End of function Sonic_WalkCeiling

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to his left
; ---------------------------------------------------------------------------

Sonic_WalkVertL:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF768).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_14934
		bpl.s	loc_14936
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		sub.w	d1,obX(a0)

locret_14934:
		rts
; ===========================================================================

loc_14936:
		cmpi.w	#$E,d1
		bgt.s	loc_14942

loc_1493C:
		sub.w	d1,obX(a0)
		rts
; ===========================================================================

loc_14942:
		tst.b	$38(a0)
		bne.s	loc_1493C
		bset	#1,obStatus(a0)
		bclr	#5,obStatus(a0)
		move.b	#1,obNextAni(a0)
		rts
; End of function Sonic_WalkVertL

; ---------------------------------------------------------------------------
; Subroutine to find which tile	the object is standing on

; input:
; d2 = y-position of object's bottom edge
; d3 = x-position of object

; output:
; a1 = address within 256x256 mappings where object is standing
;      (refers to a 16x16 tile number)
; ---------------------------------------------------------------------------

; Floor_ChkTile:
FindNearestTile:
		move.w	d2,d0		; get y-pos. of bottom edge of object
		lsr.w	#1,d0
		andi.w	#$380,d0
		move.w	d3,d1		; get x-pos. of object
		lsr.w	#8,d1
		andi.w	#$7F,d1
		add.w	d1,d0		; combine
		moveq	#-1,d1
		lea	(v_lvllayout).w,a1
		move.b	(a1,d0.w),d1	; get 256x256 tile number
		beq.s	@blanktile	; branch if 0
		bmi.s	@specialtile	; branch if >$7F
		subq.b	#1,d1
		ext.w	d1
		ror.w	#7,d1
		move.w	d2,d0
		add.w	d0,d0
		andi.w	#$1E0,d0
		add.w	d0,d1
		move.w	d3,d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		add.w	d0,d1

@blanktile:
		movea.l	d1,a1
		rts
; ===========================================================================

@specialtile:
		andi.w	#$7F,d1
		btst	#6,obRender(a0) ; is object "behind a loop"?
		beq.s	@treatasnormal	; if not, branch
		addq.w	#1,d1
		cmpi.w	#$29,d1
		bne.s	@treatasnormal
		move.w	#$51,d1

	@treatasnormal:
		subq.b	#1,d1
		ror.w	#7,d1
		move.w	d2,d0
		add.w	d0,d0
		andi.w	#$1E0,d0
		add.w	d0,d1
		move.w	d3,d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		add.w	d0,d1
		movea.l	d1,a1
		rts
; End of function FindNearestTile

; ---------------------------------------------------------------------------
; Subroutine to find the floor

; input:
; d2 = y-position of object's bottom edge
; d3 = x-position of object
; d5 = bit to test for solidness

; output:
; d1 = distance to the floor
; a1 = address within 256x256 mappings where object is standing
;      (refers to a 16x16 tile number)
; (a4) = floor angle
; ---------------------------------------------------------------------------

FindFloor:
		bsr.s	FindNearestTile
		move.w	(a1),d0		; get value for solidness, orientation and 16x16 tile number
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.s	@isblank	; branch if tile is blank
		btst	d5,d4		; is the tile solid?
		bne.s	@issolid	; if yes, branch

@isblank:
		add.w	a3,d2
		bsr.w	FindFloor2	; try tile below the nearest
		sub.w	a3,d2
		addi.w	#$10,d1		; return distance to floor
		rts
; ===========================================================================

@issolid:
		movea.l	(v_collindex).w,a2
		move.b	(a2,d0.w),d0	; get collision block number
		andi.w	#$FF,d0
		beq.s	@isblank	; branch if 0
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)	; get collision angle value
		lsl.w	#4,d0
		move.w	d3,d1		; get x-pos. of object
		btst	#$B,d4		; is block flipped horizontally?
		beq.s	@noflip		; if not, branch
		not.w	d1
		neg.b	(a4)

	@noflip:
		btst	#$C,d4		; is block flipped vertically?
		beq.s	@noflip2	; if not, branch
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

	@noflip2:
		andi.w	#$F,d1
		add.w	d0,d1		; (block num. * $10) + x-pos. = place in array
		lea	(CollArray1).l,a2
		move.b	(a2,d1.w),d0	; get collision height
		ext.w	d0
		eor.w	d6,d4
		btst	#$C,d4		; is block flipped vertically?
		beq.s	@noflip3	; if not, branch
		neg.w	d0

	@noflip3:
		tst.w	d0
		beq.s	@isblank	; branch if height is 0
		bmi.s	@negfloor	; branch if height is negative
		cmpi.b	#$10,d0
		beq.s	@maxfloor	; branch if height is $10 (max)
		move.w	d2,d1		; get y-pos. of object
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1		; return distance to floor
		rts
; ===========================================================================

@negfloor:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	@isblank

@maxfloor:
		sub.w	a3,d2
		bsr.w	FindFloor2	; try tile above the nearest
		add.w	a3,d2
		subi.w	#$10,d1		; return distance to floor
		rts
; End of function FindFloor

FindFloor2:
		bsr.w	FindNearestTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.s	@isblank2
		btst	d5,d4
		bne.s	@issolid

@isblank2:
		move.w	#$F,d1
		move.w	d2,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts
; ===========================================================================

@issolid:
		movea.l	(v_collindex).w,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.s	@isblank2
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d3,d1
		btst	#$B,d4
		beq.s	@noflip
		not.w	d1
		neg.b	(a4)

	@noflip:
		btst	#$C,d4
		beq.s	@noflip2
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

	@noflip2:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray1).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$C,d4
		beq.s	@noflip3
		neg.w	d0

	@noflip3:
		tst.w	d0
		beq.s	@isblank2
		bmi.s	@negfloor
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ===========================================================================

@negfloor:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	@isblank2
		not.w	d1
		rts
; End of function FindFloor2

FindWall:
		bsr.w	FindNearestTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.s	loc_14B1E
		btst	d5,d4
		bne.s	loc_14B2C

loc_14B1E:
		add.w	a3,d3
		bsr.w	FindWall2
		sub.w	a3,d3
		addi.w	#$10,d1
		rts
; ===========================================================================

loc_14B2C:
		movea.l	(v_collindex).w,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.s	loc_14B1E
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$C,d4
		beq.s	loc_14B5A
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14B5A:
		btst	#$B,d4
		beq.s	loc_14B62
		neg.b	(a4)

loc_14B62:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4
		beq.s	loc_14B7E
		neg.w	d0

loc_14B7E:
		tst.w	d0
		beq.s	loc_14B1E
		bmi.s	loc_14B9A
		cmpi.b	#$10,d0
		beq.s	loc_14BA6
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ===========================================================================

loc_14B9A:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14B1E

loc_14BA6:
		sub.w	a3,d3
		bsr.w	FindWall2
		add.w	a3,d3
		subi.w	#$10,d1
		rts
; End of function FindWall

FindWall2:
		bsr.w	FindNearestTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.s	loc_14BC6
		btst	d5,d4
		bne.s	loc_14BD4

loc_14BC6:
		move.w	#$F,d1
		move.w	d3,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts
; ===========================================================================

loc_14BD4:
		movea.l	(v_collindex).w,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.s	loc_14BC6
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$C,d4
		beq.s	loc_14C02
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14C02:
		btst	#$B,d4
		beq.s	loc_14C0A
		neg.b	(a4)

loc_14C0A:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4
		beq.s	loc_14C26
		neg.w	d0

loc_14C26:
		tst.w	d0
		beq.s	loc_14BC6
		bmi.s	loc_14C3C
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts
; ===========================================================================

loc_14C3C:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14BC6
		not.w	d1
		rts
; End of function FindWall2

; ---------------------------------------------------------------------------
; This subroutine takes 'raw' bitmap-like collision block data as input and
; converts it into the proper collision arrays (ColArray and ColArray2).
; Pointers to said raw data are dummied out.
; Curiously, an example of the original 'raw' data that this was intended
; to process can be found in the J2ME version, in a file called 'blkcol.bct'.
; ---------------------------------------------------------------------------

RawColBlocks		equ CollArray1
ConvRowColBlocks	equ CollArray1

ConvertCollisionArray:
		rts
; ---------------------------------------------------------------------------
		; The raw format stores the collision data column by column for the normal collision array.
		; This makes a copy of the data, but stored row by row, for the rotated collision array.
		lea	(RawColBlocks).l,a1	; Source location of raw collision block data
		lea	(ConvRowColBlocks).l,a2	; Destinatation location for row-converted collision block data

		move.w	#$100-1,d3		; Number of blocks in collision data

	@blockLoop:
		moveq	#16,d5			; Start on the 16th bit (the leftmost pixel)

		move.w	#16-1,d2		; Width of a block in pixels

	@columnLoop:
		moveq	#0,d4

		move.w	#16-1,d1		; Height of a block in pixels

	@rowLoop:
		move.w	(a1)+,d0		; Get row of collision bits
		lsr.l	d5,d0			; Push the selected bit of this row into the 'eXtend' flag
		addx.w	d4,d4			; Shift d4 to the left, and insert the selected bit into bit 0
		dbf	d1,@rowLoop		; Loop for each row of pixels in a block

		move.w	d4,(a2)+		; Store column of collision bits
		suba.w	#2*16,a1		; Back to the start of the block
		subq.w	#1,d5			; Get next bit in the row
		dbf	d2,@columnLoop		; Loop for each column of pixels in a block

		adda.w	#2*16,a1		; Next block
		dbf	d3,@blockLoop		; Loop for each block in the raw collision block data

		; This then converts the collision data into the final collision arrays
		lea	(ConvRowColBlocks).l,a1
		lea	(CollArray2).l,a2	; Convert the row-converted collision block data into final rotated collision array
		bsr.s	@convertArray
		lea	(RawColBlocks).l,a1
		lea	(CollArray1).l,a2	; Convert the raw collision block data into final normal collision array

	@convertArray:
		move.w	#$1000-1,d3		; Size of the collision array

	@processLoop:
		moveq	#0,d2
		move.w	#$F,d1
		move.w	(a1)+,d0		; Get current column of collision pixels
		beq.s	@noCollision		; Branch if there's no collision in this column
		bmi.s	@topPixelSolid		; Branch if top pixel of collision is solid

	; Here we count, starting from the bottom, how many pixels tall
	; the collision in this column is.
	@processColumnLoop1:
		lsr.w	#1,d0
		bhs.s	@pixelNotSolid1
		addq.b	#1,d2

	@pixelNotSolid1:
		dbf	d1,@processColumnLoop1

		bra.s	@columnProcessed
; ===========================================================================

	@topPixelSolid:
		cmpi.w	#$FFFF,d0		; Is entire column solid?
		beq.s	@entireColumnSolid	; Branch if so

	; Here we count, starting from the top, how many pixels tall
	; the collision in this column is (the resulting number is negative).
	@processColumnLoop2:
		lsl.w	#1,d0
		bhs.s	@pixelNotSolid2
		subq.b	#1,d2

	@pixelNotSolid2:
		dbf	d1,@processColumnLoop2

		bra.s	@columnProcessed
; ===========================================================================

	@entireColumnSolid:
		move.w	#$10,d0

	@noCollision:
		move.w	d0,d2

	@columnProcessed:
		move.b	d2,(a2)+		; Store column collision height
		dbf	d3,@processLoop

		rts

; End of function ConvertCollisionArray

Sonic_WalkSpeed:
		move.l	obX(a0),d3
		move.l	obY(a0),d2
		move.w	obVelX(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	obVelY(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,(v_anglebuffer).w
		move.b	d0,(v_anglebuffer2).w
		move.b	d0,d1
		addi.b	#$20,d0
		bpl.s	loc_14D1A
		move.b	d1,d0
		bpl.s	loc_14D14
		subq.b	#1,d0

loc_14D14:
		addi.b	#$20,d0
		bra.s	loc_14D24
; ===========================================================================

loc_14D1A:
		move.b	d1,d0
		bpl.s	loc_14D20
		addq.b	#1,d0

loc_14D20:
		addi.b	#$1F,d0

loc_14D24:
		andi.b	#$C0,d0
		beq.w	loc_14DF0
		cmpi.b	#$80,d0
		beq.w	loc_14F7C
		andi.b	#$38,d1
		bne.s	loc_14D3C
		addq.w	#8,d2

loc_14D3C:
		cmpi.b	#$40,d0
		beq.w	loc_1504A
		bra.w	loc_14EBC

; End of function Sonic_WalkSpeed

sub_14D48:
		move.b	d0,(v_anglebuffer).w
		move.b	d0,(v_anglebuffer2).w
		addi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_14FD6
		cmpi.b	#$80,d0
		beq.w	Sonic_DontRunOnWalls
		cmpi.b	#$C0,d0
		beq.w	sub_14E50

; End of function sub_14D48

; ---------------------------------------------------------------------------
; Subroutine to make Sonic land	on the floor after jumping
; ---------------------------------------------------------------------------

Sonic_HitFloor:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#0,d2

loc_14DD0:
		move.b	(v_anglebuffer2).w,d3
		cmp.w	d0,d1
		ble.s	loc_14DDE
		move.b	(v_anglebuffer).w,d3
		exg	d0,d1

loc_14DDE:
		btst	#0,d3
		beq.s	locret_14DE6
		move.b	d2,d3

locret_14DE6:
		rts

; End of function Sonic_HitFloor

; ===========================================================================
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_14DF0:
		addi.w	#$A,d2
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	#0,d2

loc_14E0A:
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14E16
		move.b	d2,d3

locret_14E16:
		rts

; ---------------------------------------------------------------------------
; Subroutine to find the distance of an object to the floor

; input:
; d3 = x-pos. of object (ObjFloorDist2 only)

; output:
; d1 = distance to the floor
; d3 = floor angle
; a1 = address within 256x256 mappings where object is standing
;      (refers to a 16x16 tile number)
; (a4) = floor angle
; ---------------------------------------------------------------------------

; ObjHitFloor:
ObjFloorDist:
		move.w	obX(a0),d3

; ObjHitFloor2:
ObjFloorDist2:
		move.w	obY(a0),d2
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		lea	(v_anglebuffer).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3		; height of a 16x16 tile
		move.w	#0,d6
		moveq	#$D,d5		; bit to test for solidness
		bsr.w	FindFloor
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14E4E
		move.b	#0,d3

	locret_14E4E:
		rts

; End of function ObjFloorDist2

sub_14E50:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_14DD0

; End of function sub_14E50

sub_14EB4:
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_14EBC:
		addi.w	#$A,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	#-$40,d2
		bra.w	loc_14E0A

; End of function sub_14EB4

; ---------------------------------------------------------------------------
; Subroutine to detect when an object hits a wall to its right
; ---------------------------------------------------------------------------

ObjHitWallRight:
		add.w	obX(a0),d3
		move.w	obY(a0),d2
		lea	(v_anglebuffer).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14F06
		move.b	#-$40,d3

locret_14F06:
		rts

; End of function ObjHitWallRight

; ---------------------------------------------------------------------------
; Subroutine preventing Sonic from running on walls and	ceilings when he
; touches them
; ---------------------------------------------------------------------------

Sonic_DontRunOnWalls:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#-$80,d2
		bra.w	loc_14DD0
; End of function Sonic_DontRunOnWalls

; ===========================================================================
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_14F7C:
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	#-$80,d2
		bra.w	loc_14E0A

ObjHitCeiling:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14FD4
		move.b	#-$80,d3

locret_14FD4:
		rts
; End of function ObjHitCeiling

; ===========================================================================

loc_14FD6:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer2).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_14DD0

; ---------------------------------------------------------------------------
; Subroutine to stop Sonic when	he jumps at a wall
; ---------------------------------------------------------------------------

Sonic_HitWall:
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_1504A:
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	#$40,d2
		bra.w	loc_14E0A
; End of function Sonic_HitWall

; ---------------------------------------------------------------------------
; Subroutine to detect when an object hits a wall to its left
; ---------------------------------------------------------------------------

ObjHitWallLeft:
		add.w	obX(a0),d3
		move.w	obY(a0),d2
		eori.w	#$F,d3
		lea	(v_anglebuffer).w,a4
		move.b	#0,(a4)
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_15098
		move.b	#$40,d3

locret_15098:
		rts
; End of function ObjHitWallLeft

; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 66 - rotating disc junction that grabs Sonic (SBZ)
; ---------------------------------------------------------------------------

; Obj66:
Junction:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Jun_Index(pc,d0.w),d1
		jmp	Jun_Index(pc,d1.w)
; ===========================================================================
Jun_Index:	dc.w Jun_Main-Jun_Index
		dc.w Jun_Action-Jun_Index
		dc.w Jun_Display-Jun_Index
		dc.w Jun_Release-Jun_Index

jun_frame:	equ $34		; current frame
jun_reverse:	equ $36		; flag set when switch is pressed
jun_switch:	equ $38		; which switch will reverse the disc
; ===========================================================================

Jun_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#1,d1
		movea.l	a0,a1
		bra.s	@makeitem
; ===========================================================================

	@repeat:
		bsr.w	FindFreeObj
		bne.s	@fail
		move.b	#id_Junction,0(a1)
		addq.b	#4,obRoutine(a1) ; goto Jun_Display next
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#3,obPriority(a1)
		move.b	#$10,obFrame(a1) ; use large circular sprite

@makeitem:
		move.l	#Map_Jun,obMap(a1)
		move.w	#$4348,obGfx(a1)
		ori.b	#4,obRender(a1)
		move.b	#$38,obActWid(a1)

	@fail:
		dbf	d1,@repeat

		move.b	#$30,obActWid(a0)
		move.b	#4,obPriority(a0)
		move.w	#$3C,$30(a0)
		move.b	#1,jun_frame(a0)
		move.b	obSubtype(a0),jun_switch(a0)

Jun_Action:	; Routine 2
		bsr.w	Jun_ChkSwitch
		tst.b	obRender(a0)
		bpl.w	Jun_Display
		move.w	#$30,d1
		move.w	d1,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		btst	#5,obStatus(a0)	; is Sonic pushing the disc?
		beq.w	Jun_Display	; if not, branch

		lea	(v_player).w,a1
		moveq	#$E,d1
		move.w	obX(a1),d0
		cmp.w	obX(a0),d0	; is Sonic to the left of the disc?
		blo.s	@isleft		; if yes, branch
		moveq	#7,d1

	@isleft:
		cmp.b	obFrame(a0),d1	; is the gap next to Sonic?
		bne.s	Jun_Display	; if not, branch

		move.b	d1,$32(a0)
		addq.b	#4,obRoutine(a0) ; goto Jun_Release next
		move.b	#1,(f_playerctrl).w ; lock controls
		move.b	#id_Roll,obAnim(a1) ; make Sonic use "rolling" animation
		move.w	#$800,obInertia(a1)
		move.w	#0,obVelX(a1)
		move.w	#0,obVelY(a1)
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)
		bset	#1,obStatus(a1)
		move.w	obX(a1),d2
		move.w	obY(a1),d3
		bsr.w	Jun_ChgPos
		add.w	d2,obX(a1)
		add.w	d3,obY(a1)
		asr	obX(a1)
		asr	obY(a1)

Jun_Display:	; Routine 4
		bra.w	RememberState
; ===========================================================================

Jun_Release:	; Routine 6
		move.b	obFrame(a0),d0
		cmpi.b	#4,d0		; is gap pointing down?
		beq.s	@release	; if yes, branch
		cmpi.b	#7,d0		; is gap pointing right?
		bne.s	@dontrelease	; if not, branch

	@release:
		cmp.b	$32(a0),d0
		beq.s	@dontrelease
		lea	(v_player).w,a1
		move.w	#0,obVelX(a1)
		move.w	#$800,obVelY(a1)
		cmpi.b	#4,d0
		beq.s	@isdown
		move.w	#$800,obVelX(a1)
		move.w	#$800,obVelY(a1)

	@isdown:
		clr.b	(f_playerctrl).w	; unlock controls
		subq.b	#4,obRoutine(a0)

	@dontrelease:
		bsr.s	Jun_ChkSwitch
		bsr.s	Jun_ChgPos
		bra.w	RememberState

Jun_ChkSwitch:
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	jun_switch(a0),d0
		btst	#0,(a2,d0.w)	; is switch pressed?
		beq.s	@unpressed	; if not, branch

		tst.b	jun_reverse(a0)	; has switch previously been pressed?
		bne.s	@animate	; if yes, branch
		neg.b	jun_frame(a0)
		move.b	#1,jun_reverse(a0) ; set to "previously pressed"
		bra.s	@animate
; ===========================================================================

@unpressed:
		clr.b	jun_reverse(a0)	; set to "not yet pressed"

@animate:
		subq.b	#1,obTimeFrame(a0) ; decrement frame timer
		bpl.s	@nochange	; if time remains, branch
		move.b	#7,obTimeFrame(a0)
		move.b	jun_frame(a0),d1
		move.b	obFrame(a0),d0
		add.b	d1,d0
		andi.b	#$F,d0
		move.b	d0,obFrame(a0)	; update frame

	@nochange:
		rts
; End of function Jun_ChkSwitch

Jun_ChgPos:
		lea	(v_player).w,a1
		moveq	#0,d0
		move.b	obFrame(a0),d0
		add.w	d0,d0
		lea	@data(pc,d0.w),a2
		move.b	(a2)+,d0
		ext.w	d0
		add.w	obX(a0),d0
		move.w	d0,obX(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	obY(a0),d0
		move.w	d0,obY(a1)
		rts

@data:		dc.b -$20,    0, -$1E,   $E ; disc x-pos, Sonic x-pos, disc y-pos, Sonic y-pos
		dc.b -$18,  $18,  -$E,  $1E
		dc.b    0,  $20,   $E,  $1E
		dc.b  $18,  $18,  $1E,   $E
		dc.b  $20,    0,  $1E,  -$E
		dc.b  $18, -$18,   $E, -$1E
		dc.b    0, -$20,  -$E, -$1E
		dc.b -$18, -$18, -$1E,  -$E

Map_Jun:	include	"_maps\Rotating Junction.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 67 - disc that you run	around (SBZ)
; ---------------------------------------------------------------------------

; Obj67:
RunningDisc:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Disc_Index(pc,d0.w),d1
		jmp	Disc_Index(pc,d1.w)
; ===========================================================================
Disc_Index:	dc.w Disc_Main-Disc_Index
		dc.w Disc_Action-Disc_Index

disc_origX:	equ $32		; original x-axis position
disc_origY:	equ $30		; original y-axis position
; ===========================================================================

Disc_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Disc,obMap(a0)
		move.w	#$C344,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.w	obX(a0),disc_origX(a0)
		move.w	obY(a0),disc_origY(a0)
		move.b	#$18,$34(a0)
		move.b	#$48,$38(a0)
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F,d1		; read only the 2nd digit
		beq.s	@typeis0	; branch if 0
		move.b	#$10,$34(a0)
		move.b	#$38,$38(a0)

	@typeis0:
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F0,d1		; read only the 1st digit
		ext.w	d1
		asl.w	#3,d1
		move.w	d1,$36(a0)
		move.b	obStatus(a0),d0
		ror.b	#2,d0
		andi.b	#$C0,d0
		move.b	d0,obAngle(a0)

Disc_Action:	; Routine 2
		bsr.w	Disc_MoveSonic
		bsr.w	Disc_MoveSpot
		bra.w	Disc_ChkDel
; ===========================================================================

Disc_MoveSonic:
		moveq	#0,d2
		move.b	$38(a0),d2
		move.w	d2,d3
		add.w	d3,d3
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	disc_origX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bhs.s	loc_155A8
		move.w	obY(a1),d1
		sub.w	disc_origY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bhs.s	loc_155A8
		btst	#1,obStatus(a1)
		beq.s	loc_155B8
		clr.b	$3A(a0)
		rts
; ===========================================================================

loc_155A8:
		tst.b	$3A(a0)
		beq.s	locret_155B6
		clr.b	$38(a1)
		clr.b	$3A(a0)

locret_155B6:
		rts
; ===========================================================================

loc_155B8:
		tst.b	$3A(a0)
		bne.s	loc_155E2
		move.b	#1,$3A(a0)
		btst	#2,obStatus(a1)
		bne.s	loc_155D0
		clr.b	obAnim(a1)

loc_155D0:
		bclr	#5,obStatus(a1)
		move.b	#1,obNextAni(a1)
		move.b	#1,$38(a1)

loc_155E2:
		move.w	obInertia(a1),d0
		tst.w	$36(a0)
		bpl.s	loc_15608
		cmpi.w	#-$400,d0
		ble.s	loc_155FA
		move.w	#-$400,obInertia(a1)
		rts
; ===========================================================================

loc_155FA:
		cmpi.w	#-$F00,d0
		bge.s	locret_15606
		move.w	#-$F00,obInertia(a1)

locret_15606:
		rts
; ===========================================================================

loc_15608:
		cmpi.w	#$400,d0
		bge.s	loc_15616
		move.w	#$400,obInertia(a1)
		rts
; ===========================================================================

loc_15616:
		cmpi.w	#$F00,d0
		ble.s	locret_15622
		move.w	#$F00,obInertia(a1)

locret_15622:
		rts
; ===========================================================================

Disc_MoveSpot:
		move.w	$36(a0),d0
		add.w	d0,obAngle(a0)
		move.b	obAngle(a0),d0
		jsr	(CalcSine).l
		move.w	disc_origY(a0),d2
		move.w	disc_origX(a0),d3
		moveq	#0,d4
		move.b	$34(a0),d4
		lsl.w	#8,d4
		move.l	d4,d5
		muls.w	d0,d4
		swap	d4
		muls.w	d1,d5
		swap	d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,obY(a0)
		move.w	d5,obX(a0)
		rts
; ===========================================================================

Disc_ChkDel:
		out_of_range.s	@delete,disc_origX(a0)
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l

Map_Disc:	include	"_maps\Running Disc.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 68 - conveyor belts (SBZ)
; ---------------------------------------------------------------------------

; Obj68:
Conveyor:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Conv_Index(pc,d0.w),d1
		jmp	Conv_Index(pc,d1.w)
; ===========================================================================
Conv_Index:	dc.w Conv_Main-Conv_Index
		dc.w Conv_Action-Conv_Index

conv_speed:	equ $36
conv_width:	equ $38
; ===========================================================================

Conv_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#128,conv_width(a0) ; set width to 128 pixels
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F,d1		; read only the 2nd digit
		beq.s	@typeis0	; if zero, branch
		move.b	#56,conv_width(a0) ; set width to 56 pixels

	@typeis0:
		move.b	obSubtype(a0),d1 ; get object type
		andi.b	#$F0,d1		; read only the 1st digit
		ext.w	d1
		asr.w	#4,d1
		move.w	d1,conv_speed(a0) ; set belt speed

Conv_Action:	; Routine 2
		bsr.s	@movesonic
		out_of_range.s	@delete
		rts

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================

@movesonic:
		moveq	#0,d2
		move.b	conv_width(a0),d2
		move.w	d2,d3
		add.w	d3,d3
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bhs.s	@notonconveyor
		move.w	obY(a1),d1
		sub.w	obY(a0),d1
		addi.w	#$30,d1
		cmpi.w	#$30,d1
		bhs.s	@notonconveyor
		btst	#1,obStatus(a1)
		bne.s	@notonconveyor
		move.w	conv_speed(a0),d0
		add.w	d0,obX(a1)

	@notonconveyor:
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 69 - spinning platforms and trapdoors (SBZ)
; ---------------------------------------------------------------------------

; Obj69:
SpinPlatform:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Spin_Index(pc,d0.w),d1
		jmp	Spin_Index(pc,d1.w)
; ===========================================================================
Spin_Index:	dc.w Spin_Main-Spin_Index
		dc.w Spin_Trapdoor-Spin_Index
		dc.w Spin_Spinner-Spin_Index

spin_timer:	equ $30		; time counter until change
spin_timelen:	equ $32		; time between changes (general)
; ===========================================================================

Spin_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Trap,obMap(a0)
		move.w	#$4492,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$80,obActWid(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		mulu.w	#$3C,d0
		move.w	d0,spin_timelen(a0)
		tst.b	obSubtype(a0)	; is subtype $8x?
		bpl.s	Spin_Trapdoor	; if not, branch

		addq.b	#2,obRoutine(a0) ; goto Spin_Spinner next
		move.l	#Map_Spin,obMap(a0)
		move.w	#$4DF,obGfx(a0)
		move.b	#$10,obActWid(a0)
		move.b	#2,obAnim(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object type
		move.w	d0,d1
		andi.w	#$F,d0		; read only the 2nd digit
		mulu.w	#6,d0		; multiply by 6
		move.w	d0,spin_timer(a0)
		move.w	d0,spin_timelen(a0) ; set time delay
		andi.w	#$70,d1
		addi.w	#$10,d1
		lsl.w	#2,d1
		subq.w	#1,d1
		move.w	d1,$36(a0)
		bra.s	Spin_Spinner
; ===========================================================================

Spin_Trapdoor:	; Routine 2
		subq.w	#1,spin_timer(a0) ; decrement timer
		bpl.s	@animate	; if time remains, branch

		move.w	spin_timelen(a0),spin_timer(a0)
		bchg	#0,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	@animate
		move.w	#sfx_Door,d0
		jsr	(PlaySound_Special).l	; play door sound

	@animate:
		lea	(Ani_Spin).l,a1
		jsr	(AnimateSprite).l
		tst.b	obFrame(a0)	; is frame number 0 displayed?
		bne.s	@notsolid	; if not, branch
		move.w	#$4B,d1
		move.w	#$C,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		bra.w	RememberState
; ===========================================================================

@notsolid:
		btst	#3,obStatus(a0) ; is Sonic standing on the trapdoor?
		beq.s	@display	; if not, branch
		lea	(v_player).w,a1
		bclr	#3,obStatus(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)

	@display:
		bra.w	RememberState
; ===========================================================================

Spin_Spinner:	; Routine 4
		move.w	(v_framecount).w,d0
		and.w	$36(a0),d0
		bne.s	@delay
		move.b	#1,$34(a0)

	@delay:
		tst.b	$34(a0)
		beq.s	@animate
		subq.w	#1,spin_timer(a0)
		bpl.s	@animate
		move.w	spin_timelen(a0),spin_timer(a0)
		clr.b	$34(a0)
		bchg	#0,obAnim(a0)

	@animate:
		lea	(Ani_Spin).l,a1
		jsr	(AnimateSprite).l
		tst.b	obFrame(a0)	; check if frame number	0 is displayed
		bne.s	@notsolid2	; if not, branch
		move.w	#$1B,d1
		move.w	#7,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		bra.w	RememberState
; ===========================================================================

@notsolid2:
		btst	#3,obStatus(a0)
		beq.s	@display
		lea	(v_player).w,a1
		bclr	#3,obStatus(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)

	@display:
		bra.w	RememberState

		include	"_anim\SBZ Spinning Platforms.asm"
Map_Trap:	include	"_maps\Trapdoor.asm"
Map_Spin:	include	"_maps\SBZ Spinning Platforms.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6A - ground saws and pizza cutters (SBZ)
; ---------------------------------------------------------------------------

; Obj6A:
Saws:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Saw_Index(pc,d0.w),d1
		jmp	Saw_Index(pc,d1.w)
; ===========================================================================
Saw_Index:	dc.w Saw_Main-Saw_Index
		dc.w Saw_Action-Saw_Index

saw_origX:	equ $3A		; original x-axis position
saw_origY:	equ $38		; original y-axis position
saw_here:	equ $3D		; flag set when the ground saw appears
; ===========================================================================

Saw_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Saw,obMap(a0)
		move.w	#$43B5,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$20,obActWid(a0)
		move.w	obX(a0),saw_origX(a0)
		move.w	obY(a0),saw_origY(a0)
		cmpi.b	#3,obSubtype(a0) ; is object a ground saw?
		bhs.s	Saw_Action	; if yes, branch
		move.b	#$A2,obColType(a0)

Saw_Action:	; Routine 2
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		out_of_range.s	@delete,saw_origX(a0)
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================
@index:		dc.w @type00-@index, @type01-@index, @type02-@index ; pizza cutters
		dc.w @type03-@index, @type04-@index ; ground saws
; ===========================================================================

@type00:
		rts			; doesn't move
; ===========================================================================

@type01:
		move.w	#$60,d1
		moveq	#0,d0
		move.b	(v_oscillate+$E).w,d0
		btst	#0,obStatus(a0)
		beq.s	@noflip01
		neg.w	d0
		add.w	d1,d0

	@noflip01:
		move.w	saw_origX(a0),d1
		sub.w	d0,d1
		move.w	d1,obX(a0)	; move saw sideways

		subq.b	#1,obTimeFrame(a0)
		bpl.s	@sameframe01
		move.b	#2,obTimeFrame(a0) ; time between frame changes
		bchg	#0,obFrame(a0)	; change frame

	@sameframe01:
		tst.b	obRender(a0)
		bpl.s	@nosound01
		move.w	(v_framecount).w,d0
		andi.w	#$F,d0
		bne.s	@nosound01
		move.w	#sfx_Saw,d0
		jsr	(PlaySound_Special).l		; play saw sound

	@nosound01:
		rts
; ===========================================================================

@type02:
		move.w	#$30,d1
		moveq	#0,d0
		move.b	(v_oscillate+6).w,d0
		btst	#0,obStatus(a0)
		beq.s	@noflip02
		neg.w	d0
		addi.w	#$80,d0

	@noflip02:
		move.w	saw_origY(a0),d1
		sub.w	d0,d1
		move.w	d1,obY(a0)	; move saw vertically
		subq.b	#1,obTimeFrame(a0)
		bpl.s	@sameframe02
		move.b	#2,obTimeFrame(a0)
		bchg	#0,obFrame(a0)

	@sameframe02:
		tst.b	obRender(a0)
		bpl.s	@nosound02
		move.b	(v_oscillate+6).w,d0
		cmpi.b	#$18,d0
		bne.s	@nosound02
		move.w	#sfx_Saw,d0
		jsr	(PlaySound_Special).l		; play saw sound

	@nosound02:
		rts
; ===========================================================================

@type03:
		tst.b	saw_here(a0)	; has the saw appeared already?
		bne.s	@here03		; if yes, branch

		move.w	(v_player+obX).w,d0
		subi.w	#$C0,d0
		blo.s	@nosaw03x
		sub.w	obX(a0),d0
		blo.s	@nosaw03x
		move.w	(v_player+obY).w,d0
		subi.w	#$80,d0
		cmp.w	obY(a0),d0
		bhs.s	@nosaw03y
		addi.w	#$100,d0
		cmp.w	obY(a0),d0
		blo.s	@nosaw03y
		move.b	#1,saw_here(a0)
		move.w	#$600,obVelX(a0) ; move object to the right
		move.b	#$A2,obColType(a0)
		move.b	#2,obFrame(a0)
		move.w	#sfx_Saw,d0
		jsr	(PlaySound_Special).l		; play saw sound

	@nosaw03x:
		addq.l	#4,sp

	@nosaw03y:
		rts
; ===========================================================================

@here03:
		jsr	(SpeedToPos).l
		move.w	obX(a0),saw_origX(a0)
		subq.b	#1,obTimeFrame(a0)
		bpl.s	@sameframe03
		move.b	#2,obTimeFrame(a0)
		bchg	#0,obFrame(a0)

	@sameframe03:
		rts
; ===========================================================================

@type04:
		tst.b	saw_here(a0)
		bne.s	@here04
		move.w	(v_player+obX).w,d0
		addi.w	#$E0,d0
		sub.w	obX(a0),d0
		bhs.s	@nosaw04x
		move.w	(v_player+obY).w,d0
		subi.w	#$80,d0
		cmp.w	obY(a0),d0
		bhs.s	@nosaw04y
		addi.w	#$100,d0
		cmp.w	obY(a0),d0
		blo.s	@nosaw04y
		move.b	#1,saw_here(a0)
		move.w	#-$600,obVelX(a0) ; move object to the left
		move.b	#$A2,obColType(a0)
		move.b	#2,obFrame(a0)
		move.w	#sfx_Saw,d0
		jsr	(PlaySound_Special).l		; play saw sound

	@nosaw04x:
		addq.l	#4,sp

	@nosaw04y:
		rts
; ===========================================================================

@here04:
		jsr	(SpeedToPos).l
		move.w	obX(a0),saw_origX(a0)
		subq.b	#1,obTimeFrame(a0)
		bpl.s	@sameframe04
		move.b	#2,obTimeFrame(a0)
		bchg	#0,obFrame(a0)

	@sameframe04:
		rts

Map_Saw:	include	"_maps\Saws and Pizza Cutters.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6B - stomper and sliding door (SBZ)
; ---------------------------------------------------------------------------

; Obj6B:
ScrapStomp:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Sto_Index(pc,d0.w),d1
		jmp	Sto_Index(pc,d1.w)
; ===========================================================================
Sto_Index:	dc.w Sto_Main-Sto_Index
		dc.w Sto_Action-Sto_Index

sto_height:	equ $16
sto_origX:	equ $34		; original x-axis position
sto_origY:	equ $30		; original y-axis position
sto_active:	equ $38		; flag set when a switch is pressed

Sto_Var:	dc.b  $40,  $C,	$80,   1 ; width, height, ????, type number
		dc.b  $1C, $20,	$38,   3
		dc.b  $1C, $20,	$40,   4
		dc.b  $1C, $20,	$60,   4
		dc.b  $80, $40,	  0,   5
; ===========================================================================

Sto_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		lsr.w	#2,d0
		andi.w	#$1C,d0
		lea	Sto_Var(pc,d0.w),a3
		move.b	(a3)+,obActWid(a0)
		move.b	(a3)+,sto_height(a0)
		lsr.w	#2,d0
		move.b	d0,obFrame(a0)
		move.l	#Map_Stomp,obMap(a0)
		move.w	#$22C0,obGfx(a0)
		cmpi.b	#id_LZ,(v_zone).w ; check if level is LZ/SBZ3
		bne.s	@isSBZ12	; if not, branch
		bset	#0,(v_obj6B).w
		beq.s	@isSBZ3

@chkdel:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@delete
		bclr	#7,2(a2,d0.w)

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================

@isSBZ3:
		move.w	#$41F0,obGfx(a0)
		cmpi.w	#$A80,obX(a0)
		bne.s	@isSBZ12
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@isSBZ12
		btst	#0,2(a2,d0.w)
		beq.s	@isSBZ12
		clr.b	(v_obj6B).w
		bra.s	@chkdel
; ===========================================================================

@isSBZ12:
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.w	obX(a0),sto_origX(a0)
		move.w	obY(a0),sto_origY(a0)
		moveq	#0,d0
		move.b	(a3)+,d0
		move.w	d0,$3C(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		bpl.s	Sto_Action
		andi.b	#$F,d0
		move.b	d0,$3E(a0)
		move.b	(a3),obSubtype(a0)
		cmpi.b	#5,(a3)
		bne.s	@chkgone
		bset	#4,obRender(a0)

	@chkgone:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	Sto_Action
		bclr	#7,2(a2,d0.w)

Sto_Action:	; Routine 2
		move.w	obX(a0),-(sp)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	@index(pc,d0.w),d1
		jsr	@index(pc,d1.w)
		move.w	(sp)+,d4
		tst.b	obRender(a0)
		bpl.s	@chkdel
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	sto_height(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	SolidObject

	@chkdel:
		out_of_range.s	@chkgone,sto_origX(a0)
		jmp	(DisplaySprite).l

	@chkgone:
		cmpi.b	#id_LZ,(v_zone).w
		bne.s	@delete
		clr.b	(v_obj6B).w
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@delete
		bclr	#7,2(a2,d0.w)

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================
@index:		dc.w @type00-@index, @type01-@index
		dc.w @type02-@index, @type03-@index
		dc.w @type04-@index, @type05-@index
; ===========================================================================

@type00:
		rts
; ===========================================================================

@type01:
		tst.b	sto_active(a0)
		bne.s	@isactive01
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	$3E(a0),d0
		btst	#0,(a2,d0.w)
		beq.s	@loc_15DC2
		move.b	#1,sto_active(a0)

	@isactive01:
		move.w	$3C(a0),d0
		cmp.w	$3A(a0),d0
		beq.s	@loc_15DE0
		addq.w	#2,$3A(a0)

	@loc_15DC2:
		move.w	$3A(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@noflip01
		neg.w	d0
		addi.w	#$80,d0

	@noflip01:
		move.w	sto_origX(a0),d1
		sub.w	d0,d1
		move.w	d1,obX(a0)
		rts
; ===========================================================================

@loc_15DE0:
		addq.b	#1,obSubtype(a0)
		move.w	#$B4,$36(a0)
		clr.b	sto_active(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@loc_15DC2
		bset	#0,2(a2,d0.w)
		bra.s	@loc_15DC2
; ===========================================================================

@type02:
		tst.b	sto_active(a0)
		bne.s	@isactive02
		subq.w	#1,$36(a0)
		bne.s	@loc_15E1E
		move.b	#1,sto_active(a0)

	@isactive02:
		tst.w	$3A(a0)
		beq.s	@loc_15E3C
		subq.w	#2,$3A(a0)

	@loc_15E1E:
		move.w	$3A(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@noflip02
		neg.w	d0
		addi.w	#$80,d0

	@noflip02:
		move.w	sto_origX(a0),d1
		sub.w	d0,d1
		move.w	d1,obX(a0)
		rts
; ===========================================================================

@loc_15E3C:
		subq.b	#1,obSubtype(a0)
		clr.b	sto_active(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@loc_15E1E
		bclr	#0,2(a2,d0.w)
		bra.s	@loc_15E1E
; ===========================================================================

@type03:
		tst.b	sto_active(a0)
		bne.s	@isactive03
		tst.w	$3A(a0)
		beq.s	@loc_15E6A
		subq.w	#1,$3A(a0)
		bra.s	@loc_15E8E
; ===========================================================================

@loc_15E6A:
		subq.w	#1,$36(a0)
		bpl.s	@loc_15E8E
		move.w	#$3C,$36(a0)
		move.b	#1,sto_active(a0)

@isactive03:
		addq.w	#8,$3A(a0)
		move.w	$3A(a0),d0
		cmp.w	$3C(a0),d0
		bne.s	@loc_15E8E
		clr.b	sto_active(a0)

@loc_15E8E:
		move.w	$3A(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@noflip03
		neg.w	d0
		addi.w	#$38,d0

	@noflip03:
		move.w	sto_origY(a0),d1
		add.w	d0,d1
		move.w	d1,obY(a0)
		rts
; ===========================================================================

@type04:
		tst.b	sto_active(a0)
		bne.s	@isactive04
		tst.w	$3A(a0)
		beq.s	@loc_15EBE
		subq.w	#8,$3A(a0)
		bra.s	@loc_15EF0
; ===========================================================================

@loc_15EBE:
		subq.w	#1,$36(a0)
		bpl.s	@loc_15EF0
		move.w	#$3C,$36(a0)
		move.b	#1,sto_active(a0)

@isactive04:
		move.w	$3A(a0),d0
		cmp.w	$3C(a0),d0
		beq.s	@loc_15EE0
		addq.w	#8,$3A(a0)
		bra.s	@loc_15EF0
; ===========================================================================

@loc_15EE0:
		subq.w	#1,$36(a0)
		bpl.s	@loc_15EF0
		move.w	#$3C,$36(a0)
		clr.b	sto_active(a0)

@loc_15EF0:
		move.w	$3A(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@noflip04
		neg.w	d0
		addi.w	#$38,d0

	@noflip04:
		move.w	sto_origY(a0),d1
		add.w	d0,d1
		move.w	d1,obY(a0)
		rts
; ===========================================================================

@type05:
		tst.b	sto_active(a0)
		bne.s	@loc_15F3E
		lea	(f_switch).w,a2
		moveq	#0,d0
		move.b	$3E(a0),d0
		btst	#0,(a2,d0.w)
		beq.s	@locret_15F5C
		move.b	#1,sto_active(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@loc_15F3E
		bset	#0,2(a2,d0.w)

@loc_15F3E:
		subi.l	#$10000,obX(a0)
		addi.l	#$8000,obY(a0)
		move.w	obX(a0),sto_origX(a0)
		cmpi.w	#$980,obX(a0)
		beq.s	@loc_15F5E

@locret_15F5C:
		rts
; ===========================================================================

@loc_15F5E:
		clr.b	obSubtype(a0)
		clr.b	sto_active(a0)
		rts

Map_Stomp:	include	"_maps\SBZ Stomper and Door.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6C - vanishing platforms (SBZ)
; ---------------------------------------------------------------------------

; Obj6C:
VanishPlatform:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	VanP_Index(pc,d0.w),d1
		jmp	VanP_Index(pc,d1.w)
; ===========================================================================
VanP_Index:	dc.w VanP_Main-VanP_Index
		dc.w VanP_Vanish-VanP_Index
		dc.w VanP_Appear-VanP_Index
		dc.w loc_16068-VanP_Index

vanp_timer:	equ $30		; counter for time until event
vanp_timelen:	equ $32		; time between events (general)
; ===========================================================================

VanP_Main:	; Routine 0
		addq.b	#6,obRoutine(a0)
		move.l	#Map_VanP,obMap(a0)
		move.w	#$44C3,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$10,obActWid(a0)
		move.b	#4,obPriority(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object type
		andi.w	#$F,d0		; read only the 2nd digit
		addq.w	#1,d0		; add 1
		lsl.w	#7,d0		; multiply by $80
		move.w	d0,d1
		subq.w	#1,d0
		move.w	d0,vanp_timer(a0)
		move.w	d0,vanp_timelen(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; get object type
		andi.w	#$F0,d0		; read only the 1st digit
		addi.w	#$80,d1
		mulu.w	d1,d0
		lsr.l	#8,d0
		move.w	d0,$36(a0)
		subq.w	#1,d1
		move.w	d1,$38(a0)

loc_16068:	; Routine 6
		move.w	(v_framecount).w,d0
		sub.w	$36(a0),d0
		and.w	$38(a0),d0
		bne.s	@animate
		subq.b	#4,obRoutine(a0) ; goto VanP_Vanish next
		bra.s	VanP_Vanish
; ===========================================================================

@animate:
		lea	(Ani_Van).l,a1
		jsr	(AnimateSprite).l
		bra.w	RememberState
; ===========================================================================

VanP_Vanish:	; Routine 2
VanP_Appear:	; Routine 4
		subq.w	#1,vanp_timer(a0)
		bpl.s	@wait
		move.w	#127,vanp_timer(a0)
		tst.b	obAnim(a0)	; is platform vanishing?
		beq.s	@isvanishing	; if yes, branch
		move.w	vanp_timelen(a0),vanp_timer(a0)

	@isvanishing:
		bchg	#0,obAnim(a0)

	@wait:
		lea	(Ani_Van).l,a1
		jsr	(AnimateSprite).l
		btst	#1,obFrame(a0)	; has platform vanished?
		bne.s	@notsolid	; if yes, branch
		cmpi.b	#2,obRoutine(a0)
		bne.s	@loc_160D6
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(PlatformObject).l
		bra.w	RememberState
; ===========================================================================

@loc_160D6:
		moveq	#0,d1
		move.b	obActWid(a0),d1
		jsr	(ExitPlatform).l
		move.w	obX(a0),d2
		jsr	(MvSonicOnPtfm2).l
		bra.w	RememberState
; ===========================================================================

@notsolid:
		btst	#3,obStatus(a0)
		beq.s	@display
		lea	(v_player).w,a1
		bclr	#3,obStatus(a1)
		bclr	#3,obStatus(a0)
		move.b	#2,obRoutine(a0)
		clr.b	obSolid(a0)

	@display:
		bra.w	RememberState

		include	"_anim\SBZ Vanishing Platforms.asm"
Map_VanP:	include	"_maps\SBZ Vanishing Platforms.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6E - electrocution orbs (SBZ)
; ---------------------------------------------------------------------------

; Obj6E:
Electro:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Elec_Index(pc,d0.w),d1
		jmp	Elec_Index(pc,d1.w)
; ===========================================================================
Elec_Index:	dc.w Elec_Main-Elec_Index
		dc.w Elec_Shock-Elec_Index

elec_freq:	equ $34		; frequency
; ===========================================================================

Elec_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Elec,obMap(a0)
		move.w	#$47E,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#$28,obActWid(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0 ; read object type
		lsl.w	#4,d0		; multiply by $10
		subq.w	#1,d0
		move.w	d0,elec_freq(a0)

Elec_Shock:	; Routine 2
		move.w	(v_framecount).w,d0
		and.w	elec_freq(a0),d0 ; is it time to zap?
		bne.s	@animate	; if not, branch

		move.b	#1,obAnim(a0)	; run "zap" animation
		tst.b	obRender(a0)
		bpl.s	@animate
		move.w	#sfx_Electric,d0
		jsr	(PlaySound_Special).l	; play electricity sound

	@animate:
		lea	(Ani_Elec).l,a1
		jsr	(AnimateSprite).l
		move.b	#0,obColType(a0)
		cmpi.b	#4,obFrame(a0)	; is 4th frame displayed?
		bne.s	@display	; if not, branch
		move.b	#$A4,obColType(a0) ; if yes, make object hurt Sonic

	@display:
		bra.w	RememberState

		include	"_anim\Electrocuter.asm"
Map_Elec:	include	"_maps\Electrocuter.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6F - spinning platforms that move around a conveyor belt (SBZ)
; ---------------------------------------------------------------------------

; Obj6F:
SpinConvey:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	SpinC_Index(pc,d0.w),d1
		jsr	SpinC_Index(pc,d1.w)
		out_of_range.s	loc_1629A,$30(a0)

SpinC_Display:
		jmp	(DisplaySprite).l
; ===========================================================================

loc_1629A:
		cmpi.b	#2,(v_act).w	; check if act is 3
		bne.s	SpinC_Act1or2	; if not, branch
		cmpi.w	#-$80,d0
		bhs.s	SpinC_Display

SpinC_Act1or2:
		move.b	$2F(a0),d0
		bpl.s	SpinC_Delete
		andi.w	#$7F,d0
		lea	(v_obj63).w,a2
		bclr	#0,(a2,d0.w)

SpinC_Delete:
		jmp	(DeleteObject).l
; ===========================================================================
SpinC_Index:	dc.w SpinC_Main-SpinC_Index
		dc.w loc_163D8-SpinC_Index
; ===========================================================================

SpinC_Main:	; Routine 0
		move.b	obSubtype(a0),d0
		bmi.w	loc_16380
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Spin,obMap(a0)
		move.w	#$4DF,obGfx(a0)
		move.b	#$10,obActWid(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		move.w	d0,d1
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	off_164A6(pc),a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,$38(a0)
		move.w	(a2)+,$30(a0)
		move.l	a2,$3C(a0)
		andi.w	#$F,d1
		lsl.w	#2,d1
		move.b	d1,$38(a0)
		move.b	#4,$3A(a0)
		tst.b	(f_conveyrev).w
		beq.s	loc_16356
		move.b	#1,$3B(a0)
		neg.b	$3A(a0)
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		blo.s	loc_16352
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.s	loc_16352
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_16352:
		move.b	d1,$38(a0)

loc_16356:
		move.w	(a2,d1.w),$34(a0)
		move.w	2(a2,d1.w),$36(a0)
		tst.w	d1
		bne.s	loc_1636C
		move.b	#1,obAnim(a0)

loc_1636C:
		cmpi.w	#8,d1
		bne.s	loc_16378
		move.b	#0,obAnim(a0)

loc_16378:
		bsr.w	LCon_ChangeDir
		bra.w	loc_163D8
; ===========================================================================

loc_16380:
		move.b	d0,$2F(a0)
		andi.w	#$7F,d0
		lea	(v_obj63).w,a2
		bset	#0,(a2,d0.w)
		beq.s	loc_1639A
		jmp	(DeleteObject).l
; ===========================================================================

loc_1639A:
		add.w	d0,d0
		andi.w	#$1E,d0
		addi.w	#ObjPosSBZPlatform_Index-ObjPos_Index,d0
		lea	(ObjPos_Index).l,a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d1
		movea.l	a0,a1
		bra.s	SpinC_LoadPform
; ===========================================================================

SpinC_Loop:
		jsr	(FindFreeObj).l
		bne.s	loc_163D0

SpinC_LoadPform:
		move.b	#id_SpinConvey,0(a1)
		move.w	(a2)+,obX(a1)
		move.w	(a2)+,obY(a1)
		move.w	(a2)+,d0
		move.b	d0,obSubtype(a1)

loc_163D0:
		dbf	d1,SpinC_Loop

		addq.l	#4,sp
		rts
; ===========================================================================

loc_163D8:	; Routine 2
		lea	(Ani_SpinConvey).l,a1
		jsr	(AnimateSprite).l
		tst.b	obFrame(a0)
		bne.s	loc_16404
		move.w	obX(a0),-(sp)
		bsr.w	loc_16424
		move.w	#$1B,d1
		move.w	#7,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	(sp)+,d4
		bra.w	SolidObject
; ===========================================================================

loc_16404:
		btst	#3,obStatus(a0)
		beq.s	loc_16420
		lea	(v_player).w,a1
		bclr	#3,obStatus(a1)
		bclr	#3,obStatus(a0)
		clr.b	obSolid(a0)

loc_16420:
		bra.w	loc_16424

loc_16424:
		move.w	obX(a0),d0
		cmp.w	$34(a0),d0
		bne.s	loc_16484
		move.w	obY(a0),d0
		cmp.w	$36(a0),d0
		bne.s	loc_16484
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		blo.s	loc_16456
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.s	loc_16456
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_16456:
		move.b	d1,$38(a0)
		movea.l	$3C(a0),a1
		move.w	(a1,d1.w),$34(a0)
		move.w	2(a1,d1.w),$36(a0)
		tst.w	d1
		bne.s	loc_16474
		move.b	#1,obAnim(a0)

loc_16474:
		cmpi.w	#8,d1
		bne.s	loc_16480
		move.b	#0,obAnim(a0)

loc_16480:
		bsr.w	LCon_ChangeDir

loc_16484:
		jmp	(SpeedToPos).l

		include	"_anim\SBZ Spin Platform Conveyor.asm"

off_164A6:	dc.w word_164B2-off_164A6, word_164C6-off_164A6, word_164DA-off_164A6
		dc.w word_164EE-off_164A6, word_16502-off_164A6, word_16516-off_164A6
word_164B2:	dc.w $10, $E80,	$E14, $370, $EEF, $302,	$EEF, $340, $E14, $3AE
word_164C6:	dc.w $10, $F80,	$F14, $2E0, $FEF, $272,	$FEF, $2B0, $F14, $31E
word_164DA:	dc.w $10, $1080, $1014,	$270, $10EF, $202, $10EF, $240,	$1014, $2AE
word_164EE:	dc.w $10, $F80,	$F14, $570, $FEF, $502,	$FEF, $540, $F14, $5AE
word_16502:	dc.w $10, $1B80, $1B14,	$670, $1BEF, $602, $1BEF, $640,	$1B14, $6AE
word_16516:	dc.w $10, $1C80, $1C14,	$5E0, $1CEF, $572, $1CEF, $5B0,	$1C14, $61E
; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 70 - large girder block (SBZ)
; ---------------------------------------------------------------------------

; Obj70:
Girder:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Gird_Index(pc,d0.w),d1
		jmp	Gird_Index(pc,d1.w)
; ===========================================================================
Gird_Index:	dc.w Gird_Main-Gird_Index
		dc.w Gird_Action-Gird_Index

gird_height:	equ $16
gird_origX:	equ $32		; original x-axis position
gird_origY:	equ $30		; original y-axis position
gird_time:	equ $34		; duration for movement in a direction
gird_set:	equ $38		; which movement settings to use (0/8/16/24)
gird_delay:	equ $3A		; delay for movement
; ===========================================================================

Gird_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Gird,obMap(a0)
		move.w	#$42F0,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$60,obActWid(a0)
		move.b	#$18,gird_height(a0)
		move.w	obX(a0),gird_origX(a0)
		move.w	obY(a0),gird_origY(a0)
		bsr.w	Gird_ChgMove

Gird_Action:	; Routine 2
		move.w	obX(a0),-(sp)
		tst.w	gird_delay(a0)
		beq.s	@beginmove
		subq.w	#1,gird_delay(a0)
		bne.s	@solid

	@beginmove:
		jsr	(SpeedToPos).l
		subq.w	#1,gird_time(a0) ; decrement movement duration
		bne.s	@solid		; if time remains, branch
		bsr.w	Gird_ChgMove	; if time is zero, branch

	@solid:
		move.w	(sp)+,d4
		tst.b	obRender(a0)
		bpl.s	@chkdel
		moveq	#0,d1
		move.b	obActWid(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	gird_height(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	SolidObject

	@chkdel:
		out_of_range.s	@delete,gird_origX(a0)
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================

Gird_ChgMove:
		move.b	gird_set(a0),d0
		andi.w	#$18,d0
		lea	(@settings).l,a1
		lea	(a1,d0.w),a1
		move.w	(a1)+,obVelX(a0)
		move.w	(a1)+,obVelY(a0)
		move.w	(a1)+,gird_time(a0)
		addq.b	#8,gird_set(a0)	; use next settings
		move.w	#7,gird_delay(a0)
		rts
; ===========================================================================
@settings:	;   x-speed, y-speed, duration
		dc.w   $100,	 0,   $60,     0 ; right
		dc.w	  0,  $100,   $30,     0 ; down
		dc.w  -$100,  -$40,   $60,     0 ; up/left
		dc.w	  0, -$100,   $18,     0 ; up

Map_Gird:	include	"_maps\Girder Block.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 72 - teleporter (SBZ)
; ---------------------------------------------------------------------------

; Obj72:
Teleport:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Tele_Index(pc,d0.w),d1
		jsr	Tele_Index(pc,d1.w)
		out_of_range.s	@delete
		rts

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================
Tele_Index:	dc.w Tele_Main-Tele_Index
		dc.w loc_166C8-Tele_Index
		dc.w loc_1675E-Tele_Index
		dc.w loc_16798-Tele_Index
; ===========================================================================

Tele_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		andi.w	#$1E,d0
		lea	Tele_Data(pc),a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,$3A(a0)
		move.l	a2,$3C(a0)
		move.w	(a2)+,$36(a0)
		move.w	(a2)+,$38(a0)

loc_166C8:	; Routine 2
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		btst	#0,obStatus(a0)
		beq.s	loc_166E0
		addi.w	#$F,d0

loc_166E0:
		cmpi.w	#$10,d0
		bhs.s	locret_1675C
		move.w	obY(a1),d1
		sub.w	obY(a0),d1
		addi.w	#$20,d1
		cmpi.w	#$40,d1
		bhs.s	locret_1675C
		tst.b	(f_playerctrl).w
		bne.s	locret_1675C
		cmpi.b	#7,obSubtype(a0)
		bne.s	loc_1670E
		cmpi.w	#50,(v_rings).w
		blo.s	locret_1675C

loc_1670E:
		addq.b	#2,obRoutine(a0)
		move.b	#$81,(f_playerctrl).w ; lock controls and disable object interaction
		move.b	#id_Roll,obAnim(a1) ; use Sonic's rolling animation
		move.w	#$800,obInertia(a1)
		move.w	#0,obVelX(a1)
		move.w	#0,obVelY(a1)
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)
		bset	#1,obStatus(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		clr.b	$32(a0)
		move.w	#sfx_Roll,d0
		jsr	(PlaySound_Special).l	; play Sonic rolling sound

locret_1675C:
		rts
; ===========================================================================

loc_1675E:	; Routine 4
		lea	(v_player).w,a1
		move.b	$32(a0),d0
		addq.b	#2,$32(a0)
		jsr	(CalcSine).l
		asr.w	#5,d0
		move.w	obY(a0),d2
		sub.w	d0,d2
		move.w	d2,obY(a1)
		cmpi.b	#$80,$32(a0)
		bne.s	locret_16796
		bsr.w	sub_1681C
		addq.b	#2,obRoutine(a0)
		move.w	#sfx_Teleport,d0
		jsr	(PlaySound_Special).l	; play teleport sound

locret_16796:
		rts
; ===========================================================================

loc_16798:	; Routine 6
		addq.l	#4,sp
		lea	(v_player).w,a1
		subq.b	#1,$2E(a0)
		bpl.s	loc_167DA
		move.w	$36(a0),obX(a1)
		move.w	$38(a0),obY(a1)
		moveq	#0,d1
		move.b	$3A(a0),d1
		addq.b	#4,d1
		cmp.b	$3B(a0),d1
		blo.s	loc_167C2
		moveq	#0,d1
		bra.s	loc_16800
; ===========================================================================

loc_167C2:
		move.b	d1,$3A(a0)
		movea.l	$3C(a0),a2
		move.w	(a2,d1.w),$36(a0)
		move.w	2(a2,d1.w),$38(a0)
		bra.w	sub_1681C
; ===========================================================================

loc_167DA:
		move.l	obX(a1),d2
		move.l	obY(a1),d3
		move.w	obVelX(a1),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	obVelY(a1),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,obX(a1)
		move.l	d3,obY(a1)
		rts
; ===========================================================================

loc_16800:
		andi.w	#$7FF,obY(a1)
		clr.b	obRoutine(a0)
		clr.b	(f_playerctrl).w
		move.w	#0,obVelX(a1)
		move.w	#$200,obVelY(a1)
		rts

sub_1681C:
		moveq	#0,d0
		move.w	#$1000,d2
		move.w	$36(a0),d0
		sub.w	obX(a1),d0
		bge.s	loc_16830
		neg.w	d0
		neg.w	d2

loc_16830:
		moveq	#0,d1
		move.w	#$1000,d3
		move.w	$38(a0),d1
		sub.w	obY(a1),d1
		bge.s	loc_16844
		neg.w	d1
		neg.w	d3

loc_16844:
		cmp.w	d0,d1
		blo.s	loc_1687A
		moveq	#0,d1
		move.w	$38(a0),d1
		sub.w	obY(a1),d1
		swap	d1
		divs.w	d3,d1
		moveq	#0,d0
		move.w	$36(a0),d0
		sub.w	obX(a1),d0
		beq.s	loc_16866
		swap	d0
		divs.w	d1,d0

loc_16866:
		move.w	d0,obVelX(a1)
		move.w	d3,obVelY(a1)
		tst.w	d1
		bpl.s	loc_16874
		neg.w	d1

loc_16874:
		move.w	d1,$2E(a0)
		rts
; ===========================================================================

loc_1687A:
		moveq	#0,d0
		move.w	$36(a0),d0
		sub.w	obX(a1),d0
		swap	d0
		divs.w	d2,d0
		moveq	#0,d1
		move.w	$38(a0),d1
		sub.w	obY(a1),d1
		beq.s	loc_16898
		swap	d1
		divs.w	d0,d1

loc_16898:
		move.w	d1,obVelY(a1)
		move.w	d2,obVelX(a1)
		tst.w	d0
		bpl.s	loc_168A6
		neg.w	d0

loc_168A6:
		move.w	d0,$2E(a0)
		rts
; End of function sub_1681C

; ===========================================================================
Tele_Data:	dc.w @type00-Tele_Data, @type01-Tele_Data, @type02-Tele_Data
		dc.w @type03-Tele_Data, @type04-Tele_Data, @type05-Tele_Data
		dc.w @type06-Tele_Data, @type07-Tele_Data
@type00:	dc.w 4,	$794, $98C
@type01:	dc.w 4,	$94, $38C
@type02:	dc.w $1C, $794,	$2E8
		dc.w $7A4, $2C0, $7D0
		dc.w $2AC, $858, $2AC
		dc.w $884, $298, $894
		dc.w $270, $894, $190
@type03:	dc.w 4,	$894, $690
@type04:	dc.w $1C, $1194, $470
		dc.w $1184, $498, $1158
		dc.w $4AC, $FD0, $4AC
		dc.w $FA4, $4C0, $F94
		dc.w $4E8, $F94, $590
@type05:	dc.w 4,	$1294, $490
@type06:	dc.w $1C, $1594, $FFE8
		dc.w $1584, $FFC0, $1560
		dc.w $FFAC, $14D0, $FFAC
		dc.w $14A4, $FF98, $1494
		dc.w $FF70, $1494, $FD90
@type07:	dc.w 4,	$894, $90

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 78 - Caterkiller enemy (MZ, SBZ)
; ---------------------------------------------------------------------------

; Obj78:
Caterkiller:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Cat_Index(pc,d0.w),d1
		jmp	Cat_Index(pc,d1.w)
; ===========================================================================
Cat_Index:	dc.w Cat_Main-Cat_Index
		dc.w Cat_Head-Cat_Index
		dc.w Cat_BodySeg1-Cat_Index
		dc.w Cat_BodySeg2-Cat_Index
		dc.w Cat_BodySeg1-Cat_Index
		dc.w Cat_Delete-Cat_Index
		dc.w loc_16CC0-Cat_Index

cat_parent:	equ $3C		; address of parent object
; ===========================================================================

locret_16950:
		rts
; ===========================================================================

Cat_Main:	; Routine 0
		move.b	#7,obHeight(a0)
		move.b	#8,obWidth(a0)
		jsr	(ObjectFall).l
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	locret_16950
		add.w	d1,obY(a0)
		clr.w	obVelY(a0)
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Cat,obMap(a0)
		move.w	#$22B0,obGfx(a0)
		cmpi.b	#id_SBZ,(v_zone).w ; if level is SBZ, branch
		beq.s	@isscrapbrain
		move.w	#$24FF,obGfx(a0) ; MZ specific code

	@isscrapbrain:
		andi.b	#3,obRender(a0)
		ori.b	#4,obRender(a0)
		move.b	obRender(a0),obStatus(a0)
		move.b	#4,obPriority(a0)
		move.b	#8,obActWid(a0)
		move.b	#$B,obColType(a0)
		move.w	obX(a0),d2
		moveq	#$C,d5
		btst	#0,obStatus(a0)
		beq.s	@noflip
		neg.w	d5

	@noflip:
		move.b	#4,d6
		moveq	#0,d3
		moveq	#4,d4
		movea.l	a0,a2
		moveq	#2,d1

Cat_Loop:
		jsr	(FindNextFreeObj).l
		bne.w	Cat_ChkGone
		move.b	#id_Caterkiller,0(a1) ; load body segment object
		move.b	d6,obRoutine(a1) ; goto Cat_BodySeg1 or Cat_BodySeg2 next
		addq.b	#2,d6		; alternate between the two
		move.l	obMap(a0),obMap(a1)
		move.w	obGfx(a0),obGfx(a1)
		move.b	#5,obPriority(a1)
		move.b	#8,obActWid(a1)
		move.b	#$CB,obColType(a1)
		add.w	d5,d2
		move.w	d2,obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	obStatus(a0),obStatus(a1)
		move.b	obStatus(a0),obRender(a1)
		move.b	#8,obFrame(a1)
		move.l	a2,cat_parent(a1)
		move.b	d4,cat_parent(a1)
		addq.b	#4,d4
		movea.l	a1,a2

	@fail:
		dbf	d1,Cat_Loop	; repeat sequence 2 more times

		move.b	#7,$2A(a0)
		clr.b	cat_parent(a0)

Cat_Head:	; Routine 2
		tst.b	obStatus(a0)
		bmi.w	loc_16C96
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Cat_Index2(pc,d0.w),d1
		jsr	Cat_Index2(pc,d1.w)
		move.b	$2B(a0),d1
		bpl.s	@display
		lea	(Ani_Cat).l,a1
		move.b	obAngle(a0),d0
		andi.w	#$7F,d0
		addq.b	#4,obAngle(a0)
		move.b	(a1,d0.w),d0
		bpl.s	@animate
		bclr	#7,$2B(a0)
		bra.s	@display

	@animate:
		andi.b	#$10,d1
		add.b	d1,d0
		move.b	d0,obFrame(a0)

	@display:
		out_of_range.w	Cat_ChkGone
		jmp	(DisplaySprite).l

	Cat_ChkGone:
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		beq.s	@delete
		bclr	#7,2(a2,d0.w)

	@delete:
		move.b	#$A,obRoutine(a0)	; goto Cat_Delete next
		rts
; ===========================================================================

Cat_Delete:	; Routine $A
		jmp	(DeleteObject).l
; ===========================================================================
Cat_Index2:	dc.w @wait-Cat_Index2
		dc.w loc_16B02-Cat_Index2
; ===========================================================================

@wait:
		subq.b	#1,$2A(a0)
		bmi.s	@move
		rts
; ===========================================================================

@move:
		addq.b	#2,ob2ndRout(a0)
		move.b	#$10,$2A(a0)
		move.w	#-$C0,obVelX(a0)
		move.w	#$40,obInertia(a0)
		bchg	#4,$2B(a0)
		bne.s	loc_16AFC
		clr.w	obVelX(a0)
		neg.w	obInertia(a0)

loc_16AFC:
		bset	#7,$2B(a0)

loc_16B02:
		subq.b	#1,$2A(a0)
		bmi.s	@loc_16B5E
		tst.w	obVelX(a0)
		beq.s	@notmoving
		move.l	obX(a0),d2
		move.l	d2,d3
		move.w	obVelX(a0),d0
		btst	#0,obStatus(a0)
		beq.s	@noflip
		neg.w	d0

	@noflip:
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.l	d2,obX(a0)
		swap	d3
		cmp.w	obX(a0),d3
		beq.s	@notmoving
		jsr	(ObjFloorDist).l
		cmpi.w	#-8,d1
		blt.s	@loc_16B70
		cmpi.w	#$C,d1
		bge.s	@loc_16B70
		add.w	d1,obY(a0)
		moveq	#0,d0
		move.b	cat_parent(a0),d0
		addq.b	#1,cat_parent(a0)
		andi.b	#$F,cat_parent(a0)
		move.b	d1,$2C(a0,d0.w)

	@notmoving:
		rts
; ===========================================================================

@loc_16B5E:
		subq.b	#2,ob2ndRout(a0)
		move.b	#7,$2A(a0)
		clr.w	obVelX(a0)
		clr.w	obInertia(a0)
		rts
; ===========================================================================

@loc_16B70:
		moveq	#0,d0
		move.b	cat_parent(a0),d0
		move.b	#$80,$2C(a0,d0.w)
		neg.w	obX+2(a0)
		beq.s	@loc_1730A
		btst	#0,obStatus(a0)
		beq.s	@loc_1730A
		subq.w	#1,obX(a0)
		addq.b	#1,cat_parent(a0)
		moveq	#0,d0
		move.b	cat_parent(a0),d0
		clr.b	$2C(a0,d0.w)
@loc_1730A:
		bchg	#0,obStatus(a0)
		move.b	obStatus(a0),obRender(a0)
		addq.b	#1,cat_parent(a0)
		andi.b	#$F,cat_parent(a0)
		rts
; ===========================================================================

Cat_BodySeg2:	; Routine 6
		movea.l	cat_parent(a0),a1
		move.b	$2B(a1),$2B(a0)
		bpl.s	Cat_BodySeg1
		lea	(Ani_Cat).l,a1
		move.b	obAngle(a0),d0
		andi.w	#$7F,d0
		addq.b	#4,obAngle(a0)
		tst.b	4(a1,d0.w)
		bpl.s	Cat_AniBody
		addq.b	#4,obAngle(a0)

Cat_AniBody:
		move.b	(a1,d0.w),d0
		addq.b	#8,d0
		move.b	d0,obFrame(a0)

Cat_BodySeg1:	; Routine 4, 8
		movea.l	cat_parent(a0),a1
		tst.b	obStatus(a0)
		bmi.w	loc_16C90
		move.b	$2B(a1),$2B(a0)
		move.b	ob2ndRout(a1),ob2ndRout(a0)
		beq.w	loc_16C64
		move.w	obInertia(a1),obInertia(a0)
		move.w	obVelX(a1),d0
		add.w	obInertia(a0),d0
		move.w	d0,obVelX(a0)
		move.l	obX(a0),d2
		move.l	d2,d3
		move.w	obVelX(a0),d0
		btst	#0,obStatus(a0)
		beq.s	loc_16C0C
		neg.w	d0

loc_16C0C:
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.l	d2,obX(a0)
		swap	d3
		cmp.w	obX(a0),d3
		beq.s	loc_16C64
		moveq	#0,d0
		move.b	cat_parent(a0),d0
		move.b	$2C(a1,d0.w),d1
		cmpi.b	#$80,d1
		bne.s	loc_16C50
		move.b	d1,$2C(a0,d0.w)
		neg.w	obX+2(a0)
		beq.s	locj_173E4
		btst	#0,obStatus(a0)
		beq.s	locj_173E4
		cmpi.w	#-$C0,obVelX(a0)
		bne.s	locj_173E4
		subq.w	#1,obX(a0)
		addq.b	#1,cat_parent(a0)
		moveq	#0,d0
		move.b	cat_parent(a0),d0
		clr.b	$2C(a0,d0.w)
locj_173E4:
		bchg	#0,obStatus(a0)
		move.b	obStatus(a0),1(a0)
		addq.b	#1,cat_parent(a0)
		andi.b	#$F,cat_parent(a0)
		bra.s	loc_16C64
; ===========================================================================

loc_16C50:
		ext.w	d1
		add.w	d1,obY(a0)
		addq.b	#1,cat_parent(a0)
		andi.b	#$F,cat_parent(a0)
		move.b	d1,$2C(a0,d0.w)

loc_16C64:
		cmpi.b	#$C,obRoutine(a1)
		beq.s	loc_16C90
		cmpi.b	#id_ExplosionItem,0(a1)
		beq.s	loc_16C7C
		cmpi.b	#$A,obRoutine(a1)
		bne.s	loc_16C82

loc_16C7C:
		move.b	#$A,obRoutine(a0)

loc_16C82:
		jmp	(DisplaySprite).l

; ===========================================================================
Cat_FragSpeed:	dc.w -$200, -$180, $180, $200
; ===========================================================================

loc_16C90:
		bset	#7,obStatus(a1)

loc_16C96:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Cat_FragSpeed-2(pc,d0.w),d0
		btst	#0,obStatus(a0)
		beq.s	loc_16CAA
		neg.w	d0

loc_16CAA:
		move.w	d0,obVelX(a0)
		move.w	#-$400,obVelY(a0)
		move.b	#$C,obRoutine(a0)
		andi.b	#$F8,obFrame(a0)

loc_16CC0:	; Routine $C
		jsr	(ObjectFall).l
		tst.w	obVelY(a0)
		bmi.s	loc_16CE0
		jsr	(ObjFloorDist).l
		tst.w	d1
		bpl.s	loc_16CE0
		add.w	d1,obY(a0)
		move.w	#-$400,obVelY(a0)

loc_16CE0:
		tst.b	obRender(a0)
		bpl.w	Cat_ChkGone
		jmp	(DisplaySprite).l

		include	"_anim\Caterkiller.asm"
Map_Cat:	include	"_maps\Caterkiller.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 79 - lamppost
; ---------------------------------------------------------------------------

; Obj79:
Lamppost:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Lamp_Index(pc,d0.w),d1
		jsr	Lamp_Index(pc,d1.w)
		jmp	(RememberState).l
; ===========================================================================
Lamp_Index:	dc.w Lamp_Main-Lamp_Index
		dc.w Lamp_Blue-Lamp_Index
		dc.w Lamp_Finish-Lamp_Index
		dc.w Lamp_Twirl-Lamp_Index

lamp_origX:	equ $30		; original x-axis position
lamp_origY:	equ $32		; original y-axis position
lamp_time:	equ $36		; length of time to twirl the lamp
; ===========================================================================

Lamp_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Lamp,obMap(a0)
		move.w	#$7A0,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#8,obActWid(a0)
		move.b	#5,obPriority(a0)
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)
		bne.s	@red
		move.b	(v_lastlamp).w,d1
		andi.b	#$7F,d1
		move.b	obSubtype(a0),d2 ; get lamppost number
		andi.b	#$7F,d2
		cmp.b	d2,d1		; is this a "new" lamppost?
		blo.s	Lamp_Blue	; if yes, branch

@red:
		bset	#0,2(a2,d0.w)
		move.b	#4,obRoutine(a0) ; goto Lamp_Finish next
		move.b	#3,obFrame(a0)	; use red lamppost frame
		rts
; ===========================================================================

Lamp_Blue:	; Routine 2
		tst.w	(v_debuguse).w	; is debug mode being used?
		bne.w	@donothing	; if yes, branch
		tst.b	(f_playerctrl).w
		bmi.w	@donothing
		move.b	(v_lastlamp).w,d1
		andi.b	#$7F,d1
		move.b	obSubtype(a0),d2
		andi.b	#$7F,d2
		cmp.b	d2,d1		; is this a "new" lamppost?
		blo.s	@chkhit		; if yes, branch
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bset	#0,2(a2,d0.w)
		move.b	#4,obRoutine(a0)
		move.b	#3,obFrame(a0)
		bra.w	@donothing
; ===========================================================================

@chkhit:
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		addq.w	#8,d0
		cmpi.w	#$10,d0
		bhs.w	@donothing
		move.w	(v_player+obY).w,d0
		sub.w	obY(a0),d0
		addi.w	#$40,d0
		cmpi.w	#$68,d0
		bhs.s	@donothing

		move.w	#sfx_Lamppost,d0
		jsr	(PlaySound_Special).l	; play lamppost sound
		addq.b	#2,obRoutine(a0)
		jsr	(FindFreeObj).l
		bne.s	@fail
		move.b	#id_Lamppost,0(a1)	; load twirling lamp object
		move.b	#6,obRoutine(a1) ; goto Lamp_Twirl next
		move.w	obX(a0),lamp_origX(a1)
		move.w	obY(a0),lamp_origY(a1)
		subi.w	#$18,lamp_origY(a1)
		move.l	#Map_Lamp,obMap(a1)
		move.w	#$7A0,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#8,obActWid(a1)
		move.b	#4,obPriority(a1)
		move.b	#2,obFrame(a1)	; use "ball only" frame
		move.w	#$20,lamp_time(a1)

	@fail:
		move.b	#1,obFrame(a0)	; use "post only" frame
		bsr.w	Lamp_StoreInfo
		lea	(v_objstate).w,a2
		moveq	#0,d0
		move.b	obRespawnNo(a0),d0
		bset	#0,2(a2,d0.w)

	@donothing:
		rts
; ===========================================================================

Lamp_Finish:	; Routine 4
		rts
; ===========================================================================

Lamp_Twirl:	; Routine 6
		subq.w	#1,lamp_time(a0) ; decrement timer
		bpl.s	@continue	; if time remains, keep twirling
		move.b	#4,obRoutine(a0) ; goto Lamp_Finish next

	@continue:
		move.b	obAngle(a0),d0
		subi.b	#$10,obAngle(a0)
		subi.b	#$40,d0
		jsr	(CalcSine).l
		muls.w	#$C00,d1
		swap	d1
		add.w	lamp_origX(a0),d1
		move.w	d1,obX(a0)
		muls.w	#$C00,d0
		swap	d0
		add.w	lamp_origY(a0),d0
		move.w	d0,obY(a0)
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to store information when you hit a lamppost
; ---------------------------------------------------------------------------

Lamp_StoreInfo:
		move.b	obSubtype(a0),(v_lastlamp).w 	; lamppost number
		move.b	(v_lastlamp).w,($FFFFFE31).w
		move.w	obX(a0),($FFFFFE32).w		; x-position
		move.w	obY(a0),($FFFFFE34).w		; y-position
		move.w	(v_rings).w,($FFFFFE36).w 	; rings
		move.b	(v_lifecount).w,($FFFFFE54).w 	; lives
		move.l	(v_time).w,($FFFFFE38).w 	; time
		move.b	(v_dle_routine).w,($FFFFFE3C).w ; routine counter for dynamic level mod
		move.w	(v_limitbtm2).w,($FFFFFE3E).w 	; lower y-boundary of level
		move.w	(v_screenposx).w,($FFFFFE40).w 	; screen x-position
		move.w	(v_screenposy).w,($FFFFFE42).w 	; screen y-position
		move.w	(v_bgscreenposx).w,($FFFFFE44).w ; bg position
		move.w	(v_bgscreenposy).w,($FFFFFE46).w 	; bg position
		move.w	(v_bg2screenposx).w,($FFFFFE48).w 	; bg position
		move.w	(v_bg2screenposy).w,($FFFFFE4A).w 	; bg position
		move.w	(v_bg3screenposx).w,($FFFFFE4C).w 	; bg position
		move.w	(v_bg3screenposy).w,($FFFFFE4E).w 	; bg position
		move.w	(v_waterpos2).w,($FFFFFE50).w 	; water height
		move.b	(v_wtr_routine).w,($FFFFFE52).w ; rountine counter for water
		move.b	(f_wtr_state).w,($FFFFFE53).w 	; water direction
		rts

; ---------------------------------------------------------------------------
; Subroutine to load stored info when you start	a level	from a lamppost
; ---------------------------------------------------------------------------

Lamp_LoadInfo:
		move.b	($FFFFFE31).w,(v_lastlamp).w
		move.w	($FFFFFE32).w,(v_player+obX).w
		move.w	($FFFFFE34).w,(v_player+obY).w
		move.w	($FFFFFE36).w,(v_rings).w
		move.b	($FFFFFE54).w,(v_lifecount).w
		clr.w	(v_rings).w
		clr.b	(v_lifecount).w
		move.l	($FFFFFE38).w,(v_time).w
		move.b	#59,(v_timecent).w
		subq.b	#1,(v_timesec).w
		move.b	($FFFFFE3C).w,(v_dle_routine).w
		move.b	($FFFFFE52).w,(v_wtr_routine).w
		move.w	($FFFFFE3E).w,(v_limitbtm2).w
		move.w	($FFFFFE3E).w,(v_limitbtm1).w
		move.w	($FFFFFE40).w,(v_screenposx).w
		move.w	($FFFFFE42).w,(v_screenposy).w
		move.w	($FFFFFE44).w,(v_bgscreenposx).w
		move.w	($FFFFFE46).w,(v_bgscreenposy).w
		move.w	($FFFFFE48).w,(v_bg2screenposx).w
		move.w	($FFFFFE4A).w,(v_bg2screenposy).w
		move.w	($FFFFFE4C).w,(v_bg3screenposx).w
		move.w	($FFFFFE4E).w,(v_bg3screenposy).w
		cmpi.b	#1,(v_zone).w	; is this Labyrinth Zone?
		bne.s	@notlabyrinth	; if not, branch

		move.w	($FFFFFE50).w,(v_waterpos2).w
		move.b	($FFFFFE52).w,(v_wtr_routine).w
		move.b	($FFFFFE53).w,(f_wtr_state).w

	@notlabyrinth:
		tst.b	(v_lastlamp).w
		bpl.s	locret_170F6
		move.w	($FFFFFE32).w,d0
		subi.w	#$A0,d0
		move.w	d0,(v_limitleft2).w

locret_170F6:
		rts

Map_Lamp:	include	"_maps\Lamppost.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7D - hidden points at the end of a level
; ---------------------------------------------------------------------------

; Obj7D:
HiddenBonus:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Bonus_Index(pc,d0.w),d1
		jmp	Bonus_Index(pc,d1.w)
; ===========================================================================
Bonus_Index:	dc.w Bonus_Main-Bonus_Index
		dc.w Bonus_Display-Bonus_Index

bonus_timelen:	equ $30		; length of time to display bonus sprites
; ===========================================================================

Bonus_Main:	; Routine 0
		moveq	#$10,d2
		move.w	d2,d3
		add.w	d3,d3
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bhs.s	@chkdel
		move.w	obY(a1),d1
		sub.w	obY(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bhs.s	@chkdel
		tst.w	(v_debuguse).w
		bne.s	@chkdel
		tst.b	(f_bigring).w
		bne.s	@chkdel
		addq.b	#2,obRoutine(a0)
		move.l	#Map_Bonus,obMap(a0)
		move.w	#$84B6,obGfx(a0)
		ori.b	#4,obRender(a0)
		move.b	#0,obPriority(a0)
		move.b	#$10,obActWid(a0)
		move.b	obSubtype(a0),obFrame(a0)
		move.w	#119,bonus_timelen(a0) ; set display time to 2 seconds
		move.w	#sfx_Bonus,d0
		jsr	(PlaySound_Special).l	; play bonus sound
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		move.w	@points(pc,d0.w),d0 ; load bonus points array
		jsr	(AddPoints).l

	@chkdel:
		out_of_range.s	@delete
		rts

	@delete:
		jmp	(DeleteObject).l

; ===========================================================================
@points:	dc.w 0			; Bonus points array
		dc.w 1000
		dc.w 100
		dc.w 1
; ===========================================================================

Bonus_Display:	; Routine 2
		subq.w	#1,bonus_timelen(a0) ; decrement display time
		bmi.s	Bonus_Display_Delete		; if time is zero, branch
		out_of_range.s	Bonus_Display_Delete
		jmp	(DisplaySprite).l

Bonus_Display_Delete:
		jmp	(DeleteObject).l

Map_Bonus:	include	"_maps\Hidden Bonuses.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 8A - "SONIC TEAM PRESENTS" and credits
; ---------------------------------------------------------------------------

; Obj8A:
CreditsText:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Cred_Index(pc,d0.w),d1
		jmp	Cred_Index(pc,d1.w)
; ===========================================================================
Cred_Index:	dc.w Cred_Main-Cred_Index
		dc.w Cred_Display-Cred_Index
; ===========================================================================

Cred_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$120,obX(a0)
		move.w	#$F0,obScreenY(a0)
		move.l	#Map_Cred,obMap(a0)
		move.w	#$5A0,obGfx(a0)
		move.w	(v_creditsnum).w,d0 ; load credits index number
		move.b	d0,obFrame(a0)	; display appropriate sprite
		move.b	#0,obRender(a0)
		move.b	#0,obPriority(a0)

		cmpi.b	#id_Title,(v_gamemode).w ; is the mode #4 (title screen)?
		bne.s	Cred_Display	; if not, branch

		move.w	#$A6,obGfx(a0)
		move.b	#$A,obFrame(a0)	; display "SONIC TEAM PRESENTS"
		tst.b	(f_creditscheat).w ; is hidden credits cheat on?
		beq.s	Cred_Display	; if not, branch
		cmpi.b	#btnABC+btnDn,(v_jpadhold1).w ; is A+B+C+Down being pressed? ($72)
		bne.s	Cred_Display	; if not, branch
		move.w	#cWhite,(v_pal_dry_dup+$40).w ; 3rd palette, 1st entry = white
		move.w	#$880,(v_pal_dry_dup+$42).w ; 3rd palette, 2nd entry = cyan
		jmp	(DeleteObject).l
; ===========================================================================

Cred_Display:	; Routine 2
		jmp	DisplaySprite

Map_Cred:	include	"_maps\Credits.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3D - Eggman (GHZ)
; ---------------------------------------------------------------------------

; Obj3D:
BossGreenHill:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	BGHZ_Index(pc,d0.w),d1
		jmp	BGHZ_Index(pc,d1.w)
; ===========================================================================
BGHZ_Index:	dc.w BGHZ_Main-BGHZ_Index
		dc.w BGHZ_ShipMain-BGHZ_Index
		dc.w BGHZ_FaceMain-BGHZ_Index
		dc.w BGHZ_FlameMain-BGHZ_Index

BGHZ_ObjData:	dc.b 2,	0		; routine counter, animation
		dc.b 4,	1
		dc.b 6,	7
; ===========================================================================

BGHZ_Main:	; Routine 0
		lea	(BGHZ_ObjData).l,a2
		movea.l	a0,a1
		moveq	#2,d1
		bra.s	BGHZ_LoadBoss
; ===========================================================================

BGHZ_Loop:
		jsr	(FindNextFreeObj).l
		bne.s	loc_17772

BGHZ_LoadBoss:
		move.b	(a2)+,obRoutine(a1)
		move.b	#id_BossGreenHill,0(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.l	#Map_Eggman,obMap(a1)
		move.w	#$400,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.b	#3,obPriority(a1)
		move.b	(a2)+,obAnim(a1)
		move.l	a0,$34(a1)
		dbf	d1,BGHZ_Loop	; repeat sequence 2 more times

loc_17772:
		move.w	obX(a0),$30(a0)
		move.w	obY(a0),$38(a0)
		move.b	#$F,obColType(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8

BGHZ_ShipMain:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	BGHZ_ShipIndex(pc,d0.w),d1
		jsr	BGHZ_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		move.b	obStatus(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================
BGHZ_ShipIndex:	dc.w BGHZ_ShipStart-BGHZ_ShipIndex
		dc.w BGHZ_MakeBall-BGHZ_ShipIndex
		dc.w BGHZ_ShipMove-BGHZ_ShipIndex
		dc.w loc_17954-BGHZ_ShipIndex
		dc.w loc_1797A-BGHZ_ShipIndex
		dc.w loc_179AC-BGHZ_ShipIndex
		dc.w loc_179F6-BGHZ_ShipIndex
; ===========================================================================

BGHZ_ShipStart:
		move.w	#$100,obVelY(a0) ; move ship down
		bsr.w	BossMove
		cmpi.w	#$338,$38(a0)
		bne.s	loc_177E6
		move.w	#0,obVelY(a0)	; stop ship
		addq.b	#2,ob2ndRout(a0) ; goto next routine

loc_177E6:
		move.b	$3F(a0),d0
		jsr	(CalcSine).l
		asr.w	#6,d0
		add.w	$38(a0),d0
		move.w	d0,obY(a0)
		move.w	$30(a0),obX(a0)
		addq.b	#2,$3F(a0)
		cmpi.b	#8,ob2ndRout(a0)
		bhs.s	locret_1784A
		tst.b	obStatus(a0)
		bmi.s	loc_1784C
		tst.b	obColType(a0)
		bne.s	locret_1784A
		tst.b	$3E(a0)
		bne.s	BGHZ_ShipFlash
		move.b	#$20,$3E(a0)	; set number of times for ship to flash
		move.w	#sfx_HitBoss,d0
		jsr	(PlaySound_Special).l	; play boss damage sound

BGHZ_ShipFlash:
		lea	(v_pal_dry+$22).w,a1 ; load 2nd pallet, 2nd entry
		moveq	#0,d0		; move 0 (black) to d0
		tst.w	(a1)
		bne.s	loc_1783C
		move.w	#cWhite,d0	; move 0EEE (white) to d0

loc_1783C:
		move.w	d0,(a1)		; load colour stored in d0
		subq.b	#1,$3E(a0)
		bne.s	locret_1784A
		move.b	#$F,obColType(a0)

locret_1784A:
		rts
; ===========================================================================

loc_1784C:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#8,ob2ndRout(a0)
		move.w	#$B3,$3C(a0)
		rts

; ---------------------------------------------------------------------------
; Defeated boss subroutine
; ---------------------------------------------------------------------------

BossDefeated:
		move.b	(v_vbla_byte).w,d0
		andi.b	#7,d0
		bne.s	locret_178A2
		jsr	(FindFreeObj).l
		bne.s	locret_178A2
		move.b	#id_ExplosionBomb,0(a1)	; load explosion object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		jsr	(RandomNumber).l
		move.w	d0,d1
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,obX(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,obY(a1)

locret_178A2:
		rts
; End of function BossDefeated

; ---------------------------------------------------------------------------
; Subroutine to move a boss
; ---------------------------------------------------------------------------

BossMove:
		move.l	$30(a0),d2
		move.l	$38(a0),d3
		move.w	obVelX(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	obVelY(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,$30(a0)
		move.l	d3,$38(a0)
		rts
; End of function BossMove

; ===========================================================================

BGHZ_MakeBall:
		move.w	#-$100,obVelX(a0)
		move.w	#-$40,obVelY(a0)
		bsr.w	BossMove
		cmpi.w	#$2A00,$30(a0)
		bne.s	loc_17916
		move.w	#0,obVelX(a0)
		move.w	#0,obVelY(a0)
		addq.b	#2,ob2ndRout(a0)
		jsr	(FindNextFreeObj).l
		bne.s	loc_17910
		move.b	#id_BossBall,0(a1) ; load swinging ball object
		move.w	$30(a0),obX(a1)
		move.w	$38(a0),obY(a1)
		move.l	a0,$34(a1)

loc_17910:
		move.w	#$77,$3C(a0)

loc_17916:
		bra.w	loc_177E6
; ===========================================================================

BGHZ_ShipMove:
		subq.w	#1,$3C(a0)
		bpl.s	BGHZ_Reverse
		addq.b	#2,ob2ndRout(a0)
		move.w	#$3F,$3C(a0)
		move.w	#$100,obVelX(a0) ; move the ship sideways
		cmpi.w	#$2A00,$30(a0)
		bne.s	BGHZ_Reverse
		move.w	#$7F,$3C(a0)
		move.w	#$40,obVelX(a0)

BGHZ_Reverse:
		btst	#0,obStatus(a0)
		bne.s	loc_17950
		neg.w	obVelX(a0)	; reverse direction of the ship

loc_17950:
		bra.w	loc_177E6
; ===========================================================================

loc_17954:
		subq.w	#1,$3C(a0)
		bmi.s	loc_17960
		bsr.w	BossMove
		bra.s	loc_17976
; ===========================================================================

loc_17960:
		bchg	#0,obStatus(a0)
		move.w	#$3F,$3C(a0)
		subq.b	#2,ob2ndRout(a0)
		move.w	#0,obVelX(a0)

loc_17976:
		bra.w	loc_177E6
; ===========================================================================

loc_1797A:
		subq.w	#1,$3C(a0)
		bmi.s	loc_17984
		bra.w	BossDefeated
; ===========================================================================

loc_17984:
		bset	#0,obStatus(a0)
		bclr	#7,obStatus(a0)
		clr.w	obVelX(a0)
		addq.b	#2,ob2ndRout(a0)
		move.w	#-$26,$3C(a0)
		tst.b	(v_bossstatus).w
		bne.s	locret_179AA
		move.b	#1,(v_bossstatus).w

locret_179AA:
		rts
; ===========================================================================

loc_179AC:
		addq.w	#1,$3C(a0)
		beq.s	loc_179BC
		bpl.s	loc_179C2
		addi.w	#$18,obVelY(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179BC:
		clr.w	obVelY(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179C2:
		cmpi.w	#$30,$3C(a0)
		blo.s	loc_179DA
		beq.s	loc_179E0
		cmpi.w	#$38,$3C(a0)
		blo.s	loc_179EE
		addq.b	#2,ob2ndRout(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179DA:
		subq.w	#8,obVelY(a0)
		bra.s	loc_179EE
; ===========================================================================

loc_179E0:
		clr.w	obVelY(a0)
		move.w	#bgm_GHZ,d0
		jsr	(PlaySound).l		; play GHZ music

loc_179EE:
		bsr.w	BossMove
		bra.w	loc_177E6
; ===========================================================================

loc_179F6:
		move.w	#$400,obVelX(a0)
		move.w	#-$40,obVelY(a0)
		cmpi.w	#$2AC0,(v_limitright2).w
		beq.s	loc_17A10
		addq.w	#2,(v_limitright2).w
		bra.s	loc_17A16
; ===========================================================================

loc_17A10:
		tst.b	obRender(a0)
		bpl.s	BGHZ_ShipDel

loc_17A16:
		bsr.w	BossMove
		bra.w	loc_177E6
; ===========================================================================

BGHZ_ShipDel:
		jmp	(DeleteObject).l
; ===========================================================================

BGHZ_FaceMain:	; Routine 4
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	ob2ndRout(a1),d0
		subq.b	#4,d0
		bne.s	loc_17A3E
		cmpi.w	#$2A00,$30(a1)
		bne.s	loc_17A46
		moveq	#4,d1

loc_17A3E:
		subq.b	#6,d0
		bmi.s	loc_17A46
		moveq	#$A,d1
		bra.s	loc_17A5A
; ===========================================================================

loc_17A46:
		tst.b	obColType(a1)
		bne.s	loc_17A50
		moveq	#5,d1
		bra.s	loc_17A5A
; ===========================================================================

loc_17A50:
		cmpi.b	#4,(v_player+obRoutine).w
		blo.s	loc_17A5A
		moveq	#4,d1

loc_17A5A:
		move.b	d1,obAnim(a0)
		subq.b	#2,d0
		bne.s	BGHZ_FaceDisp
		move.b	#6,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	BGHZ_FaceDel

BGHZ_FaceDisp:
		bra.s	BGHZ_Display
; ===========================================================================

BGHZ_FaceDel:
		jmp	(DeleteObject).l
; ===========================================================================

BGHZ_FlameMain:	; Routine 6
		move.b	#7,obAnim(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$C,ob2ndRout(a1)
		bne.s	loc_17A96
		move.b	#$B,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	BGHZ_FlameDel
		bra.s	BGHZ_FlameDisp
; ===========================================================================

loc_17A96:
		move.w	obVelX(a1),d0
		beq.s	BGHZ_FlameDisp
		move.b	#8,obAnim(a0)

BGHZ_FlameDisp:
		bra.s	BGHZ_Display
; ===========================================================================

BGHZ_FlameDel:
		jmp	(DeleteObject).l
; ===========================================================================

BGHZ_Display:
		movea.l	$34(a0),a1
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		move.b	obStatus(a1),obStatus(a0)
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		move.b	obStatus(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 48 - ball on a chain that Eggman swings (GHZ)
; ---------------------------------------------------------------------------

; Obj48:
BossBall:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	GBall_Index(pc,d0.w),d1
		jmp	GBall_Index(pc,d1.w)
; ===========================================================================
GBall_Index:	dc.w GBall_Main-GBall_Index
		dc.w GBall_Base-GBall_Index
		dc.w GBall_Display2-GBall_Index
		dc.w loc_17C68-GBall_Index
		dc.w GBall_ChkVanish-GBall_Index
; ===========================================================================

GBall_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$4080,obAngle(a0)
		move.w	#-$200,$3E(a0)
		move.l	#Map_BossItems,obMap(a0)
		move.w	#$46C,obGfx(a0)
		lea	obSubtype(a0),a2
		move.b	#0,(a2)+
		moveq	#5,d1
		movea.l	a0,a1
		bra.s	loc_17B60
; ===========================================================================

GBall_MakeLinks:
		jsr	(FindNextFreeObj).l
		bne.s	GBall_MakeBall
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#id_BossBall,0(a1) ; load chain link object
		move.b	#6,obRoutine(a1)
		move.l	#Map_Swing_GHZ,obMap(a1)
		move.w	#$380,obGfx(a1)
		move.b	#1,obFrame(a1)
		addq.b	#1,obSubtype(a0)

loc_17B60:
		move.w	a1,d5
		subi.w	#v_objspace&$FFFF,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#4,obRender(a1)
		move.b	#8,obActWid(a1)
		move.b	#6,obPriority(a1)
		move.l	$34(a0),$34(a1)
		dbf	d1,GBall_MakeLinks ; repeat sequence 5 more times

GBall_MakeBall:
		move.b	#8,obRoutine(a1)
		move.l	#Map_GBall,obMap(a1) ; load different mappings for final link
		move.w	#$43AA,obGfx(a1) ; use different graphics
		move.b	#1,obFrame(a1)
		move.b	#5,obPriority(a1)
		move.b	#$81,obColType(a1) ; make object hurt Sonic
		rts
; ===========================================================================

GBall_PosData:	dc.b 0,	$10, $20, $30, $40, $60	; y-position data for links and giant ball

; ===========================================================================

GBall_Base:	; Routine 2
		lea	(GBall_PosData).l,a3
		lea	obSubtype(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_17BC6:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#v_objspace&$FFFFFF,d4
		movea.l	d4,a1
		move.b	(a3)+,d0
		cmp.b	$3C(a1),d0
		beq.s	loc_17BE0
		addq.b	#1,$3C(a1)

loc_17BE0:
		dbf	d6,loc_17BC6

		cmp.b	$3C(a1),d0
		bne.s	loc_17BFA
		movea.l	$34(a0),a1
		cmpi.b	#6,ob2ndRout(a1)
		bne.s	loc_17BFA
		addq.b	#2,obRoutine(a0)

loc_17BFA:
		cmpi.w	#$20,$32(a0)
		beq.s	GBall_Display
		addq.w	#1,$32(a0)

GBall_Display:
		bsr.w	sub_17C2A
		move.b	obAngle(a0),d0
		jsr	(Swing_Move2).l
		jmp	(DisplaySprite).l
; ===========================================================================

GBall_Display2:	; Routine 4
		bsr.w	sub_17C2A
		jsr	(Obj48_Move).l
		jmp	(DisplaySprite).l

sub_17C2A:
		movea.l	$34(a0),a1
		addi.b	#$20,obAniFrame(a0)
		bhs.s	loc_17C3C
		bchg	#0,obFrame(a0)

loc_17C3C:
		move.w	obX(a1),$3A(a0)
		move.w	obY(a1),d0
		add.w	$32(a0),d0
		move.w	d0,$38(a0)
		move.b	obStatus(a1),obStatus(a0)
		tst.b	obStatus(a1)
		bpl.s	locret_17C66
		move.b	#id_ExplosionBomb,0(a0)
		move.b	#0,obRoutine(a0)

locret_17C66:
		rts
; End of function sub_17C2A

; ===========================================================================

loc_17C68:	; Routine 6
		movea.l	$34(a0),a1
		tst.b	obStatus(a1)
		bpl.s	GBall_Display3
		move.b	#id_ExplosionBomb,0(a0)
		move.b	#0,obRoutine(a0)

GBall_Display3:
		jmp	(DisplaySprite).l
; ===========================================================================

GBall_ChkVanish:; Routine 8
		moveq	#0,d0
		tst.b	obFrame(a0)
		bne.s	GBall_Vanish
		addq.b	#1,d0

GBall_Vanish:
		move.b	d0,obFrame(a0)
		movea.l	$34(a0),a1
		tst.b	obStatus(a1)
		bpl.s	GBall_Display4
		move.b	#0,obColType(a0)
		bsr.w	BossDefeated
		subq.b	#1,$3C(a0)
		bpl.s	GBall_Display4
		move.b	#id_ExplosionBomb,(a0)
		move.b	#0,obRoutine(a0)

GBall_Display4:
		jmp	(DisplaySprite).l

		include	"_anim\Eggman.asm"
Map_Eggman:	include	"_maps\Eggman.asm"
Map_BossItems:	include	"_maps\Boss Items.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 77 - Eggman (LZ)
; ---------------------------------------------------------------------------

; Obj77:
BossLabyrinth:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj77_Index(pc,d0.w),d1
		jmp	Obj77_Index(pc,d1.w)
; ===========================================================================
Obj77_Index:	dc.w Obj77_Main-Obj77_Index
		dc.w Obj77_ShipMain-Obj77_Index
		dc.w Obj77_FaceMain-Obj77_Index
		dc.w Obj77_FlameMain-Obj77_Index

Obj77_ObjData:	dc.b 2,	0		; routine number, animation
		dc.b 4,	1
		dc.b 6,	7
; ===========================================================================

Obj77_Main:	; Routine 0
		move.w	#$1E10,obX(a0)
		move.w	#$5C0,obY(a0)
		move.w	obX(a0),$30(a0)
		move.w	obY(a0),$38(a0)
		move.b	#$F,obColType(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8
		move.b	#4,obPriority(a0)
		lea	Obj77_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#2,d1
		bra.s	Obj77_LoadBoss
; ===========================================================================

Obj77_Loop:
		jsr	(FindNextFreeObj).l
		bne.s	Obj77_ShipMain
		move.b	#id_BossLabyrinth,0(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

Obj77_LoadBoss:
		bclr	#0,obStatus(a0)
		clr.b	ob2ndRout(a1)
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,obAnim(a1)
		move.b	obPriority(a0),obPriority(a1)
		move.l	#Map_Eggman,obMap(a1)
		move.w	#$400,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.l	a0,$34(a1)
		dbf	d1,Obj77_Loop

Obj77_ShipMain:	; Routine 2
		lea	(v_player).w,a1
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Obj77_ShipIndex(pc,d0.w),d1
		jsr	Obj77_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================
Obj77_ShipIndex:dc.w loc_17F1E-Obj77_ShipIndex,	loc_17FA0-Obj77_ShipIndex
		dc.w loc_17FE0-Obj77_ShipIndex,	loc_1801E-Obj77_ShipIndex
		dc.w loc_180BC-Obj77_ShipIndex,	loc_180F6-Obj77_ShipIndex
		dc.w loc_1812A-Obj77_ShipIndex,	loc_18152-Obj77_ShipIndex
; ===========================================================================

loc_17F1E:
		move.w	obX(a1),d0
		cmpi.w	#$1DA0,d0
		blo.s	loc_17F38
		move.w	#-$180,obVelY(a0)
		move.w	#$60,obVelX(a0)
		addq.b	#2,ob2ndRout(a0)

loc_17F38:
		bsr.w	BossMove
		move.w	$38(a0),obY(a0)
		move.w	$30(a0),obX(a0)

loc_17F48:
		tst.b	standonobject(a0)
		bne.s	loc_17F8E
		tst.b	obStatus(a0)
		bmi.s	loc_17F92
		tst.b	obColType(a0)
		bne.s	locret_17F8C
		tst.b	$3E(a0)
		bne.s	loc_17F70
		move.b	#$20,$3E(a0)
		move.w	#sfx_HitBoss,d0
		jsr	(PlaySound_Special).l

loc_17F70:
		lea	(v_pal_dry+$22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.s	loc_17F7E
		move.w	#cWhite,d0

loc_17F7E:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.s	locret_17F8C
		move.b	#$F,obColType(a0)

locret_17F8C:
		rts
; ===========================================================================

loc_17F8E:
		bra.w	BossDefeated
; ===========================================================================

loc_17F92:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#-1,standonobject(a0)
		rts
; ===========================================================================

loc_17FA0:
		moveq	#-2,d0
		cmpi.w	#$1E48,$30(a0)
		blo.s	loc_17FB6
		move.w	#$1E48,$30(a0)
		clr.w	obVelX(a0)
		addq.w	#1,d0

loc_17FB6:
		cmpi.w	#$500,$38(a0)
		bgt.s	loc_17FCA
		move.w	#$500,$38(a0)
		clr.w	obVelY(a0)
		addq.w	#1,d0

loc_17FCA:
		bne.s	loc_17FDC
		move.w	#$140,obVelX(a0)
		move.w	#-$200,obVelY(a0)
		addq.b	#2,ob2ndRout(a0)

loc_17FDC:
		bra.w	loc_17F38
; ===========================================================================

loc_17FE0:
		moveq	#-2,d0
		cmpi.w	#$1E70,$30(a0)
		blo.s	loc_17FF6
		move.w	#$1E70,$30(a0)
		clr.w	obVelX(a0)
		addq.w	#1,d0

loc_17FF6:
		cmpi.w	#$4C0,$38(a0)
		bgt.s	loc_1800A
		move.w	#$4C0,$38(a0)
		clr.w	obVelY(a0)
		addq.w	#1,d0

loc_1800A:
		bne.s	loc_1801A
		move.w	#-$180,obVelY(a0)
		addq.b	#2,ob2ndRout(a0)
		clr.b	$3F(a0)

loc_1801A:
		bra.w	loc_17F38
; ===========================================================================

loc_1801E:
		cmpi.w	#$100,$38(a0)
		bgt.s	loc_1804E
		move.w	#$100,$38(a0)
		move.w	#$140,obVelX(a0)
		move.w	#-$80,obVelY(a0)
		tst.b	standonobject(a0)
		beq.s	loc_18046
		asl	obVelX(a0)
		asl	obVelY(a0)

loc_18046:
		addq.b	#2,ob2ndRout(a0)
		bra.w	loc_17F38
; ===========================================================================

loc_1804E:
		bset	#0,obStatus(a0)
		addq.b	#2,$3F(a0)
		move.b	$3F(a0),d0
		jsr	(CalcSine).l
		tst.w	d1
		bpl.s	loc_1806C
		bclr	#0,obStatus(a0)

loc_1806C:
		asr.w	#4,d0
		swap	d0
		clr.w	d0
		add.l	$30(a0),d0
		swap	d0
		move.w	d0,obX(a0)
		move.w	obVelY(a0),d0
		move.w	(v_player+obY).w,d1
		sub.w	obY(a0),d1
		blo.s	loc_180A2
		subi.w	#$48,d1
		blo.s	loc_180A2
		asr.w	#1,d0
		subi.w	#$28,d1
		blo.s	loc_180A2
		asr.w	#1,d0
		subi.w	#$28,d1
		blo.s	loc_180A2
		moveq	#0,d0

loc_180A2:
		ext.l	d0
		asl.l	#8,d0
		tst.b	standonobject(a0)
		beq.s	loc_180AE
		add.l	d0,d0

loc_180AE:
		add.l	d0,$38(a0)
		move.w	$38(a0),obY(a0)
		bra.w	loc_17F48
; ===========================================================================

loc_180BC:
		moveq	#-2,d0
		cmpi.w	#$1F4C,$30(a0)
		blo.s	loc_180D2
		move.w	#$1F4C,$30(a0)
		clr.w	obVelX(a0)
		addq.w	#1,d0

loc_180D2:
		cmpi.w	#$C0,$38(a0)
		bgt.s	loc_180E6
		move.w	#$C0,$38(a0)
		clr.w	obVelY(a0)
		addq.w	#1,d0

loc_180E6:
		bne.s	loc_180F2
		addq.b	#2,ob2ndRout(a0)
		bclr	#0,obStatus(a0)

loc_180F2:
		bra.w	loc_17F38
; ===========================================================================

loc_180F6:
		tst.b	standonobject(a0)
		bne.s	loc_18112
		cmpi.w	#$1EC8,obX(a1)
		blt.s	loc_18126
		cmpi.w	#$F0,obY(a1)
		bgt.s	loc_18126
		move.b	#$32,$3C(a0)

loc_18112:
		move.w	#bgm_LZ,d0
		jsr	(PlaySound).l		; play LZ music
		clr.b	(f_lockscreen).w
		bset	#0,obStatus(a0)
		addq.b	#2,ob2ndRout(a0)

loc_18126:
		bra.w	loc_17F38
; ===========================================================================

loc_1812A:
		tst.b	standonobject(a0)
		bne.s	loc_18136
		subq.b	#1,$3C(a0)
		bne.s	loc_1814E

loc_18136:
		clr.b	$3C(a0)
		move.w	#$400,obVelX(a0)
		move.w	#-$40,obVelY(a0)
		clr.b	standonobject(a0)
		addq.b	#2,ob2ndRout(a0)

loc_1814E:
		bra.w	loc_17F38
; ===========================================================================

loc_18152:
		cmpi.w	#$2030,(v_limitright2).w
		bhs.s	loc_18160
		addq.w	#2,(v_limitright2).w
		bra.s	loc_18166
; ===========================================================================

loc_18160:
		tst.b	obRender(a0)
		bpl.s	Obj77_ShipDel

loc_18166:
		bra.w	loc_17F38
; ===========================================================================

Obj77_ShipDel:
		jmp	(DeleteObject).l
; ===========================================================================

Obj77_FaceMain:	; Routine 4
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.s	Obj77_FaceDel
		moveq	#0,d0
		move.b	ob2ndRout(a1),d0
		moveq	#1,d1
		tst.b	standonobject(a0)
		beq.s	loc_1818C
		moveq	#$A,d1
		bra.s	loc_181A0
; ===========================================================================

loc_1818C:
		tst.b	obColType(a1)
		bne.s	loc_18196
		moveq	#5,d1
		bra.s	loc_181A0
; ===========================================================================

loc_18196:
		cmpi.b	#4,(v_player+obRoutine).w
		blo.s	loc_181A0
		moveq	#4,d1

loc_181A0:
		move.b	d1,obAnim(a0)
		cmpi.b	#$E,d0
		bne.s	loc_181B6
		move.b	#6,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	Obj77_FaceDel

loc_181B6:
		bra.s	Obj77_Display
; ===========================================================================

Obj77_FaceDel:
		jmp	(DeleteObject).l
; ===========================================================================

Obj77_FlameMain:; Routine 6
		move.b	#7,obAnim(a0)
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.s	Obj77_FlameDel
		cmpi.b	#$E,ob2ndRout(a1)
		bne.s	loc_181F0
		move.b	#$B,obAnim(a0)
		tst.b	1(a0)
		bpl.s	Obj77_FlameDel
		bra.s	loc_181F0
; ===========================================================================
		tst.w	obVelX(a1)
		beq.s	loc_181F0
		move.b	#8,obAnim(a0)

loc_181F0:
		bra.s	Obj77_Display
; ===========================================================================

Obj77_FlameDel:
		jmp	(DeleteObject).l
; ===========================================================================

Obj77_Display:
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		movea.l	$34(a0),a1
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		move.b	obStatus(a1),obStatus(a0)
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 73 - Eggman (MZ)
; ---------------------------------------------------------------------------

; Obj73:
BossMarble:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj73_Index(pc,d0.w),d1
		jmp	Obj73_Index(pc,d1.w)
; ===========================================================================
Obj73_Index:	dc.w Obj73_Main-Obj73_Index
		dc.w Obj73_ShipMain-Obj73_Index
		dc.w Obj73_FaceMain-Obj73_Index
		dc.w Obj73_FlameMain-Obj73_Index
		dc.w Obj73_TubeMain-Obj73_Index

Obj73_ObjData:	dc.b 2,	0, 4		; routine number, animation, priority
		dc.b 4,	1, 4
		dc.b 6,	7, 4
		dc.b 8,	0, 3
; ===========================================================================

Obj73_Main:	; Routine 0
		move.w	obX(a0),$30(a0)
		move.w	obY(a0),$38(a0)
		move.b	#$F,obColType(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8
		lea	Obj73_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.s	Obj73_LoadBoss
; ===========================================================================

Obj73_Loop:
		jsr	(FindNextFreeObj).l
		bne.s	Obj73_ShipMain
		move.b	#id_BossMarble,0(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

Obj73_LoadBoss:
		bclr	#0,obStatus(a0)
		clr.b	ob2ndRout(a1)
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,obAnim(a1)
		move.b	(a2)+,obPriority(a1)
		move.l	#Map_Eggman,obMap(a1)
		move.w	#$400,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.l	a0,$34(a1)
		dbf	d1,Obj73_Loop	; repeat sequence 3 more times

Obj73_ShipMain:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Obj73_ShipIndex(pc,d0.w),d1
		jsr	Obj73_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================
Obj73_ShipIndex:dc.w loc_18302-Obj73_ShipIndex
		dc.w loc_183AA-Obj73_ShipIndex
		dc.w loc_184F6-Obj73_ShipIndex
		dc.w loc_1852C-Obj73_ShipIndex
		dc.w loc_18582-Obj73_ShipIndex
; ===========================================================================

loc_18302:
		move.b	$3F(a0),d0
		addq.b	#2,$3F(a0)
		jsr	(CalcSine).l
		asr.w	#2,d0
		move.w	d0,obVelY(a0)
		move.w	#-$100,obVelX(a0)
		bsr.w	BossMove
		cmpi.w	#$1910,$30(a0)
		bne.s	loc_18334
		addq.b	#2,ob2ndRout(a0)
		clr.b	obSubtype(a0)
		clr.l	obVelX(a0)

loc_18334:
		jsr	(RandomNumber).l
		move.b	d0,$34(a0)

loc_1833E:
		move.w	$38(a0),obY(a0)
		move.w	$30(a0),obX(a0)
		cmpi.b	#4,ob2ndRout(a0)
		bhs.s	locret_18390
		tst.b	obStatus(a0)
		bmi.s	loc_18392
		tst.b	obColType(a0)
		bne.s	locret_18390
		tst.b	$3E(a0)
		bne.s	loc_18374
		move.b	#$28,$3E(a0)
		move.w	#sfx_HitBoss,d0
		jsr	(PlaySound_Special).l	; play boss damage sound

loc_18374:
		lea	(v_pal_dry+$22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.s	loc_18382
		move.w	#cWhite,d0

loc_18382:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.s	locret_18390
		move.b	#$F,obColType(a0)

locret_18390:
		rts
; ===========================================================================

loc_18392:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#4,ob2ndRout(a0)
		move.w	#$B4,$3C(a0)
		clr.w	obVelX(a0)
		rts
; ===========================================================================

loc_183AA:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		move.w	off_183C2(pc,d0.w),d0
		jsr	off_183C2(pc,d0.w)
		andi.b	#6,obSubtype(a0)
		bra.w	loc_1833E
; ===========================================================================
off_183C2:	dc.w loc_183CA-off_183C2
		dc.w Obj73_MakeLava2-off_183C2
		dc.w loc_183CA-off_183C2
		dc.w Obj73_MakeLava2-off_183C2
; ===========================================================================

loc_183CA:
		tst.w	obVelX(a0)
		bne.s	loc_183FE
		moveq	#$40,d0
		cmpi.w	#$22C,$38(a0)
		beq.s	loc_183E6
		blo.s	loc_183DE
		neg.w	d0

loc_183DE:
		move.w	d0,obVelY(a0)
		bra.w	BossMove
; ===========================================================================

loc_183E6:
		move.w	#$200,obVelX(a0)
		move.w	#$100,obVelY(a0)
		btst	#0,obStatus(a0)
		bne.s	loc_183FE
		neg.w	obVelX(a0)

loc_183FE:
		cmpi.b	#$18,$3E(a0)
		bhs.s	Obj73_MakeLava
		bsr.w	BossMove
		subq.w	#4,obVelY(a0)

Obj73_MakeLava:
		subq.b	#1,$34(a0)
		bhs.s	loc_1845C
		jsr	(FindFreeObj).l
		bne.s	loc_1844A
		move.b	#id_LavaBall,0(a1) ; load lava ball object
		move.w	#$2E8,obY(a1)	; set Y position
		jsr	(RandomNumber).l
		andi.l	#$FFFF,d0
		divu.w	#$50,d0
		swap	d0
		addi.w	#$1878,d0
		move.w	d0,obX(a1)
		lsr.b	#7,d1
		move.w	#$FF,obSubtype(a1)

loc_1844A:
		jsr	(RandomNumber).l
		andi.b	#$1F,d0
		addi.b	#$40,d0
		move.b	d0,$34(a0)

loc_1845C:
		btst	#0,obStatus(a0)
		beq.s	loc_18474
		cmpi.w	#$1910,$30(a0)
		blt.s	locret_1849C
		move.w	#$1910,$30(a0)
		bra.s	loc_18482
; ===========================================================================

loc_18474:
		cmpi.w	#$1830,$30(a0)
		bgt.s	locret_1849C
		move.w	#$1830,$30(a0)

loc_18482:
		clr.w	obVelX(a0)
		move.w	#-$180,obVelY(a0)
		cmpi.w	#$22C,$38(a0)
		bhs.s	loc_18498
		neg.w	obVelY(a0)

loc_18498:
		addq.b	#2,obSubtype(a0)

locret_1849C:
		rts
; ===========================================================================

Obj73_MakeLava2:
		bsr.w	BossMove
		move.w	$38(a0),d0
		subi.w	#$22C,d0
		bgt.s	locret_184F4
		move.w	#$22C,d0
		tst.w	obVelY(a0)
		beq.s	loc_184EA
		clr.w	obVelY(a0)
		move.w	#$50,$3C(a0)
		bchg	#0,obStatus(a0)
		jsr	(FindFreeObj).l
		bne.s	loc_184EA
		move.w	$30(a0),obX(a1)
		move.w	$38(a0),obY(a1)
		addi.w	#$18,obY(a1)
		move.b	#id_BossFire,(a1)	; load lava ball object
		move.b	#1,obSubtype(a1)

loc_184EA:
		subq.w	#1,$3C(a0)
		bne.s	locret_184F4
		addq.b	#2,obSubtype(a0)

locret_184F4:
		rts
; ===========================================================================

loc_184F6:
		subq.w	#1,$3C(a0)
		bmi.s	loc_18500
		bra.w	BossDefeated
; ===========================================================================

loc_18500:
		bset	#0,obStatus(a0)
		bclr	#7,obStatus(a0)
		clr.w	obVelX(a0)
		addq.b	#2,ob2ndRout(a0)
		move.w	#-$26,$3C(a0)
		tst.b	(v_bossstatus).w
		bne.s	locret_1852A
		move.b	#1,(v_bossstatus).w
		clr.w	obVelY(a0)

locret_1852A:
		rts
; ===========================================================================

loc_1852C:
		addq.w	#1,$3C(a0)
		beq.s	loc_18544
		bpl.s	loc_1854E
		cmpi.w	#$270,$38(a0)
		bhs.s	loc_18544
		addi.w	#$18,obVelY(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_18544:
		clr.w	obVelY(a0)
		clr.w	$3C(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_1854E:
		cmpi.w	#$30,$3C(a0)
		blo.s	loc_18566
		beq.s	loc_1856C
		cmpi.w	#$38,$3C(a0)
		blo.s	loc_1857A
		addq.b	#2,ob2ndRout(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_18566:
		subq.w	#8,obVelY(a0)
		bra.s	loc_1857A
; ===========================================================================

loc_1856C:
		clr.w	obVelY(a0)
		move.w	#bgm_MZ,d0
		jsr	(PlaySound).l		; play MZ music

loc_1857A:
		bsr.w	BossMove
		bra.w	loc_1833E
; ===========================================================================

loc_18582:
		move.w	#$500,obVelX(a0)
		move.w	#-$40,obVelY(a0)
		cmpi.w	#$1960,(v_limitright2).w
		bhs.s	loc_1859C
		addq.w	#2,(v_limitright2).w
		bra.s	loc_185A2
; ===========================================================================

loc_1859C:
		tst.b	obRender(a0)
		bpl.s	Obj73_ShipDel

loc_185A2:
		bsr.w	BossMove
		bra.w	loc_1833E
; ===========================================================================

Obj73_ShipDel:
		jmp	(DeleteObject).l
; ===========================================================================

Obj73_FaceMain:	; Routine 4
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	ob2ndRout(a1),d0
		subq.w	#2,d0
		bne.s	loc_185D2
		btst	#1,obSubtype(a1)
		beq.s	loc_185DA
		tst.w	obVelY(a1)
		bne.s	loc_185DA
		moveq	#4,d1
		bra.s	loc_185EE
; ===========================================================================

loc_185D2:
		subq.b	#2,d0
		bmi.s	loc_185DA
		moveq	#$A,d1
		bra.s	loc_185EE
; ===========================================================================

loc_185DA:
		tst.b	obColType(a1)
		bne.s	loc_185E4
		moveq	#5,d1
		bra.s	loc_185EE
; ===========================================================================

loc_185E4:
		cmpi.b	#4,(v_player+obRoutine).w
		blo.s	loc_185EE
		moveq	#4,d1

loc_185EE:
		move.b	d1,obAnim(a0)
		subq.b	#4,d0
		bne.s	loc_18602
		move.b	#6,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	Obj73_FaceDel

loc_18602:
		bra.s	Obj73_Display
; ===========================================================================

Obj73_FaceDel:
		jmp	(DeleteObject).l
; ===========================================================================

Obj73_FlameMain:; Routine 6
		move.b	#7,obAnim(a0)
		movea.l	$34(a0),a1
		cmpi.b	#8,ob2ndRout(a1)
		blt.s	loc_1862A
		move.b	#$B,obAnim(a0)
		tst.b	obRender(a0)
		bpl.s	Obj73_FlameDel
		bra.s	loc_18636
; ===========================================================================

loc_1862A:
		tst.w	obVelX(a1)
		beq.s	loc_18636
		move.b	#8,obAnim(a0)

loc_18636:
		bra.s	Obj73_Display
; ===========================================================================

Obj73_FlameDel:
		jmp	(DeleteObject).l
; ===========================================================================

Obj73_Display:
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l

loc_1864A:
		movea.l	$34(a0),a1
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		move.b	obStatus(a1),obStatus(a0)
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================

Obj73_TubeMain:	; Routine 8
		movea.l	$34(a0),a1
		cmpi.b	#8,ob2ndRout(a1)
		bne.s	loc_18688
		tst.b	obRender(a0)
		bpl.s	Obj73_TubeDel

loc_18688:
		move.l	#Map_BossItems,obMap(a0)
		move.w	#$246C,obGfx(a0)
		move.b	#4,obFrame(a0)
		bra.s	loc_1864A
; ===========================================================================

Obj73_TubeDel:
		jmp	(DeleteObject).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 74 - lava that Eggman drops (MZ)
; ---------------------------------------------------------------------------

; Obj74:
BossFire:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj74_Index(pc,d0.w),d0
		jsr	Obj74_Index(pc,d0.w)
		jmp	(DisplaySprite).l
; ===========================================================================
Obj74_Index:	dc.w Obj74_Main-Obj74_Index
		dc.w Obj74_Action-Obj74_Index
		dc.w loc_18886-Obj74_Index
		dc.w Obj74_Delete3-Obj74_Index
; ===========================================================================

Obj74_Main:	; Routine 0
		move.b	#8,obHeight(a0)
		move.b	#8,obWidth(a0)
		move.l	#Map_Fire,obMap(a0)
		move.w	#$345,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#5,obPriority(a0)
		move.w	obY(a0),$38(a0)
		move.b	#8,obActWid(a0)
		addq.b	#2,obRoutine(a0)
		tst.b	obSubtype(a0)
		bne.s	loc_1870A
		move.b	#$8B,obColType(a0)
		addq.b	#2,obRoutine(a0)
		bra.w	loc_18886
; ===========================================================================

loc_1870A:
		move.b	#$1E,$29(a0)
		move.w	#sfx_Fireball,d0
		jsr	(PlaySound_Special).l	; play lava sound

Obj74_Action:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Obj74_Index2(pc,d0.w),d0
		jsr	Obj74_Index2(pc,d0.w)
		jsr	(SpeedToPos).l
		lea	(Ani_Fire).l,a1
		jsr	(AnimateSprite).l
		cmpi.w	#$2E8,obY(a0)
		bhi.s	Obj74_Delete
		rts
; ===========================================================================

Obj74_Delete:
		jmp	(DeleteObject).l
; ===========================================================================
Obj74_Index2:	dc.w Obj74_Drop-Obj74_Index2
		dc.w Obj74_MakeFlame-Obj74_Index2
		dc.w Obj74_Duplicate-Obj74_Index2
		dc.w Obj74_FallEdge-Obj74_Index2
; ===========================================================================

Obj74_Drop:
		bset	#1,obStatus(a0)
		subq.b	#1,$29(a0)
		bpl.s	locret_18780
		move.b	#$8B,obColType(a0)
		clr.b	obSubtype(a0)
		addi.w	#$18,obVelY(a0)
		bclr	#1,obStatus(a0)
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	locret_18780
		addq.b	#2,ob2ndRout(a0)

locret_18780:
		rts
; ===========================================================================

Obj74_MakeFlame:
		subq.w	#2,obY(a0)
		bset	#7,obGfx(a0)
		move.w	#$A0,obVelX(a0)
		clr.w	obVelY(a0)
		move.w	obX(a0),$30(a0)
		move.w	obY(a0),$38(a0)
		move.b	#3,$29(a0)
		jsr	(FindNextFreeObj).l
		bne.s	loc_187CA
		lea	(a1),a3
		lea	(a0),a2
		moveq	#3,d0

Obj74_Loop:
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		dbf	d0,Obj74_Loop

		neg.w	obVelX(a1)
		addq.b	#2,ob2ndRout(a1)

loc_187CA:
		addq.b	#2,ob2ndRout(a0)
		rts

Obj74_Duplicate2:
		jsr	(FindNextFreeObj).l
		bne.s	locret_187EE
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.b	#id_BossFire,(a1)
		move.w	#$67,obSubtype(a1)

locret_187EE:
		rts
; End of function Obj74_Duplicate2

; ===========================================================================

Obj74_Duplicate:
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	loc_18826
		move.w	obX(a0),d0
		cmpi.w	#$1940,d0
		bgt.s	loc_1882C
		move.w	$30(a0),d1
		cmp.w	d0,d1
		beq.s	loc_1881E
		andi.w	#$10,d0
		andi.w	#$10,d1
		cmp.w	d0,d1
		beq.s	loc_1881E
		bsr.s	Obj74_Duplicate2
		move.w	obX(a0),$32(a0)

loc_1881E:
		move.w	obX(a0),$30(a0)
		rts
; ===========================================================================

loc_18826:
		addq.b	#2,ob2ndRout(a0)
		rts
; ===========================================================================

loc_1882C:
		addq.b	#2,obRoutine(a0)
		rts
; ===========================================================================

Obj74_FallEdge:
		bclr	#1,obStatus(a0)
		addi.w	#$24,obVelY(a0)	; make flame fall
		move.w	obX(a0),d0
		sub.w	$32(a0),d0
		bpl.s	loc_1884A
		neg.w	d0

loc_1884A:
		cmpi.w	#$12,d0
		bne.s	loc_18856
		bclr	#7,obGfx(a0)

loc_18856:
		bsr.w	ObjFloorDist
		tst.w	d1
		bpl.s	locret_1887E
		subq.b	#1,$29(a0)
		beq.s	Obj74_Delete2
		clr.w	obVelY(a0)
		move.w	$32(a0),obX(a0)
		move.w	$38(a0),obY(a0)
		bset	#7,obGfx(a0)
		subq.b	#2,ob2ndRout(a0)

locret_1887E:
		rts
; ===========================================================================

Obj74_Delete2:
		jmp	(DeleteObject).l
; ===========================================================================

loc_18886:	; Routine 4
		bset	#7,obGfx(a0)
		subq.b	#1,$29(a0)
		bne.s	Obj74_Animate
		move.b	#1,obAnim(a0)
		subq.w	#4,obY(a0)
		clr.b	obColType(a0)

Obj74_Animate:
		lea	(Ani_Fire).l,a1
		jmp	(AnimateSprite).l
; ===========================================================================

Obj74_Delete3:	; Routine 6
		jmp	(DeleteObject).l

	Obj7A_Delete:
		jmp	(DeleteObject).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7A - Eggman (SLZ)
; ---------------------------------------------------------------------------

; Obj7A:
BossStarLight:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj7A_Index(pc,d0.w),d1
		jmp	Obj7A_Index(pc,d1.w)
; ===========================================================================
Obj7A_Index:	dc.w Obj7A_Main-Obj7A_Index
		dc.w Obj7A_ShipMain-Obj7A_Index
		dc.w Obj7A_FaceMain-Obj7A_Index
		dc.w Obj7A_FlameMain-Obj7A_Index
		dc.w Obj7A_TubeMain-Obj7A_Index

Obj7A_ObjData:	dc.b 2,	0, 4		; routine number, animation, priority
		dc.b 4,	1, 4
		dc.b 6,	7, 4
		dc.b 8,	0, 3
; ===========================================================================

Obj7A_Main:
		move.w	#$2188,obX(a0)
		move.w	#$228,obY(a0)
		move.w	obX(a0),$30(a0)
		move.w	obY(a0),$38(a0)
		move.b	#$F,obColType(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8
		lea	Obj7A_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.s	Obj7A_LoadBoss
; ===========================================================================

Obj7A_Loop:
		jsr	(FindNextFreeObj).l
		bne.s	loc_1895C
		move.b	#id_BossStarLight,0(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

Obj7A_LoadBoss:
		bclr	#0,obStatus(a0)
		clr.b	ob2ndRout(a1)
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,obAnim(a1)
		move.b	(a2)+,obPriority(a1)
		move.l	#Map_Eggman,obMap(a1)
		move.w	#$400,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.l	a0,$34(a1)
		dbf	d1,Obj7A_Loop	; repeat sequence 3 more times

loc_1895C:
		lea	(v_objspace+$40).w,a1
		lea	$2A(a0),a2
		moveq	#$5E,d0
		moveq	#$3E,d1

loc_18968:
		cmp.b	(a1),d0
		bne.s	loc_18974
		tst.b	obSubtype(a1)
		beq.s	loc_18974
		move.w	a1,(a2)+

loc_18974:
		adda.w	#$40,a1
		dbf	d1,loc_18968

Obj7A_ShipMain:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Obj7A_ShipIndex(pc,d0.w),d0
		jsr	Obj7A_ShipIndex(pc,d0.w)
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================
Obj7A_ShipIndex:dc.w loc_189B8-Obj7A_ShipIndex
		dc.w loc_18A5E-Obj7A_ShipIndex
		dc.w Obj7A_MakeBall-Obj7A_ShipIndex
		dc.w loc_18B48-Obj7A_ShipIndex
		dc.w loc_18B80-Obj7A_ShipIndex
		dc.w loc_18BC6-Obj7A_ShipIndex
; ===========================================================================

loc_189B8:
		move.w	#-$100,obVelX(a0)
		cmpi.w	#$2120,$30(a0)
		bhs.s	loc_189CA
		addq.b	#2,ob2ndRout(a0)

loc_189CA:
		bsr.w	BossMove
		move.b	$3F(a0),d0
		addq.b	#2,$3F(a0)
		jsr	(CalcSine).l
		asr.w	#6,d0
		add.w	$38(a0),d0
		move.w	d0,obY(a0)
		move.w	$30(a0),obX(a0)
		bra.s	loc_189FE
; ===========================================================================

loc_189EE:
		bsr.w	BossMove
		move.w	$38(a0),obY(a0)
		move.w	$30(a0),obX(a0)

loc_189FE:
		cmpi.b	#6,ob2ndRout(a0)
		bhs.s	locret_18A44
		tst.b	obStatus(a0)
		bmi.s	loc_18A46
		tst.b	obColType(a0)
		bne.s	locret_18A44
		tst.b	$3E(a0)
		bne.s	loc_18A28
		move.b	#$20,$3E(a0)
		move.w	#sfx_HitBoss,d0
		jsr	(PlaySound_Special).l	; play boss damage sound

loc_18A28:
		lea	(v_pal_dry+$22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.s	loc_18A36
		move.w	#cWhite,d0

loc_18A36:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.s	locret_18A44
		move.b	#$F,obColType(a0)

locret_18A44:
		rts
; ===========================================================================

loc_18A46:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#6,ob2ndRout(a0)
		move.b	#$78,$3C(a0)
		clr.w	obVelX(a0)
		rts
; ===========================================================================

loc_18A5E:
		move.w	$30(a0),d0
		move.w	#$200,obVelX(a0)
		btst	#0,obStatus(a0)
		bne.s	loc_18A7C
		neg.w	obVelX(a0)
		cmpi.w	#$2008,d0
		bgt.s	loc_18A88
		bra.s	loc_18A82
; ===========================================================================

loc_18A7C:
		cmpi.w	#$2138,d0
		blt.s	loc_18A88

loc_18A82:
		bchg	#0,obStatus(a0)

loc_18A88:
		move.w	8(a0),d0
		moveq	#-1,d1
		moveq	#2,d2
		lea	$2A(a0),a2
		moveq	#$28,d4
		tst.w	obVelX(a0)
		bpl.s	loc_18A9E
		neg.w	d4

loc_18A9E:
		move.w	(a2)+,d1
		movea.l	d1,a3
		btst	#3,obStatus(a3)
		bne.s	loc_18AB4
		move.w	8(a3),d3
		add.w	d4,d3
		sub.w	d0,d3
		beq.s	loc_18AC0

loc_18AB4:
		dbf	d2,loc_18A9E

		move.b	d2,obSubtype(a0)
		bra.w	loc_189CA
; ===========================================================================

loc_18AC0:
		move.b	d2,obSubtype(a0)
		addq.b	#2,ob2ndRout(a0)
		move.b	#$28,$3C(a0)
		bra.w	loc_189CA
; ===========================================================================

Obj7A_MakeBall:
		cmpi.b	#$28,$3C(a0)
		bne.s	loc_18B36
		moveq	#-1,d0
		move.b	obSubtype(a0),d0
		ext.w	d0
		bmi.s	loc_18B40
		subq.w	#2,d0
		neg.w	d0
		add.w	d0,d0
		lea	$2A(a0),a1
		move.w	(a1,d0.w),d0
		movea.l	d0,a2
		lea	(v_objspace+$40).w,a1
		moveq	#$3E,d1

loc_18AFA:
		cmp.l	$3C(a1),d0
		beq.s	loc_18B40
		adda.w	#$40,a1
		dbf	d1,loc_18AFA

		move.l	a0,-(sp)
		lea	(a2),a0
		jsr	(FindNextFreeObj).l
		movea.l	(sp)+,a0
		bne.s	loc_18B40
		move.b	#id_BossSpikeball,(a1) ; load spiked ball object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		addi.w	#$20,obY(a1)
		move.b	obStatus(a2),obStatus(a1)
		move.l	a2,$3C(a1)

loc_18B36:
		subq.b	#1,$3C(a0)
		beq.s	loc_18B40
		bra.w	loc_189FE
; ===========================================================================

loc_18B40:
		subq.b	#2,ob2ndRout(a0)
		bra.w	loc_189CA
; ===========================================================================

loc_18B48:
		subq.b	#1,$3C(a0)
		bmi.s	loc_18B52
		bra.w	BossDefeated
; ===========================================================================

loc_18B52:
		addq.b	#2,ob2ndRout(a0)
		clr.w	obVelY(a0)
		bset	#0,obStatus(a0)
		bclr	#7,obStatus(a0)
		clr.w	obVelX(a0)
		move.b	#-$18,$3C(a0)
		tst.b	(v_bossstatus).w
		bne.s	loc_18B7C
		move.b	#1,(v_bossstatus).w

loc_18B7C:
		bra.w	loc_189FE
; ===========================================================================

loc_18B80:
		addq.b	#1,$3C(a0)
		beq.s	loc_18B90
		bpl.s	loc_18B96
		addi.w	#$18,obVelY(a0)
		bra.s	loc_18BC2
; ===========================================================================

loc_18B90:
		clr.w	obVelY(a0)
		bra.s	loc_18BC2
; ===========================================================================

loc_18B96:
		cmpi.b	#$20,$3C(a0)
		blo.s	loc_18BAE
		beq.s	loc_18BB4
		cmpi.b	#$2A,$3C(a0)
		blo.s	loc_18BC2
		addq.b	#2,ob2ndRout(a0)
		bra.s	loc_18BC2
; ===========================================================================

loc_18BAE:
		subq.w	#8,obVelY(a0)
		bra.s	loc_18BC2
; ===========================================================================

loc_18BB4:
		clr.w	obVelY(a0)
		move.w	#bgm_SLZ,d0
		jsr	(PlaySound).l		; play SLZ music

loc_18BC2:
		bra.w	loc_189EE
; ===========================================================================

loc_18BC6:
		move.w	#$400,obVelX(a0)
		move.w	#-$40,obVelY(a0)
		cmpi.w	#$2160,(v_limitright2).w
		bhs.s	loc_18BE0
		addq.w	#2,(v_limitright2).w
		bra.s	loc_18BE8
; ===========================================================================

loc_18BE0:
		tst.b	obRender(a0)
		bpl.w	Obj7A_Delete

loc_18BE8:
		bsr.w	BossMove
		bra.w	loc_189CA
; ===========================================================================

Obj7A_FaceMain:	; Routine 4
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	ob2ndRout(a1),d0
		cmpi.b	#6,d0
		bmi.s	loc_18C06
		moveq	#$A,d1
		bra.s	loc_18C1A
; ===========================================================================

loc_18C06:
		tst.b	obColType(a1)
		bne.s	loc_18C10
		moveq	#5,d1
		bra.s	loc_18C1A
; ===========================================================================

loc_18C10:
		cmpi.b	#4,(v_player+obRoutine).w
		blo.s	loc_18C1A
		moveq	#4,d1

loc_18C1A:
		move.b	d1,obAnim(a0)
		cmpi.b	#$A,d0
		bne.s	loc_18C32
		move.b	#6,obAnim(a0)
		tst.b	obRender(a0)
		bpl.w	Obj7A_Delete

loc_18C32:
		bra.s	loc_18C6C
; ===========================================================================

Obj7A_FlameMain:; Routine 6
		move.b	#8,obAnim(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$A,ob2ndRout(a1)
		bne.s	loc_18C56
		tst.b	obRender(a0)
		bpl.w	Obj7A_Delete
		move.b	#$B,obAnim(a0)
		bra.s	loc_18C6C
; ===========================================================================

loc_18C56:
		cmpi.b	#8,ob2ndRout(a1)
		bgt.s	loc_18C6C
		cmpi.b	#4,ob2ndRout(a1)
		blt.s	loc_18C6C
		move.b	#7,obAnim(a0)

loc_18C6C:
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l

loc_18C78:
		movea.l	$34(a0),a1
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		move.b	obStatus(a1),obStatus(a0)
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================

Obj7A_TubeMain:	; Routine 8
		movea.l	$34(a0),a1
		cmpi.b	#$A,ob2ndRout(a1)
		bne.s	loc_18CB8
		tst.b	obRender(a0)
		bpl.w	Obj7A_Delete

loc_18CB8:
		move.l	#Map_BossItems,obMap(a0)
		move.w	#$246C,obGfx(a0)
		move.b	#3,obFrame(a0)
		bra.s	loc_18C78

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7B - exploding spikeys	that Eggman drops (SLZ)
; ---------------------------------------------------------------------------

; Obj7B:
BossSpikeball:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj7B_Index(pc,d0.w),d0
		jsr	Obj7B_Index(pc,d0.w)
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	(v_screenposx).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		bmi.w	Obj7A_Delete
		cmpi.w	#$280,d0
		bhi.w	Obj7A_Delete
		jmp	(DisplaySprite).l
; ===========================================================================
Obj7B_Index:	dc.w Obj7B_Main-Obj7B_Index
		dc.w Obj7B_Fall-Obj7B_Index
		dc.w loc_18DC6-Obj7B_Index
		dc.w loc_18EAA-Obj7B_Index
		dc.w Obj7B_Explode-Obj7B_Index
		dc.w Obj7B_MoveFrag-Obj7B_Index
; ===========================================================================

Obj7B_Main:	; Routine 0
		move.l	#Map_SSawBall,obMap(a0)
		move.w	#$518,obGfx(a0)
		move.b	#1,obFrame(a0)
		ori.b	#4,obRender(a0)
		move.b	#4,obPriority(a0)
		move.b	#$8B,obColType(a0)
		move.b	#$C,obActWid(a0)
		movea.l	$3C(a0),a1
		move.w	obX(a1),$30(a0)
		move.w	obY(a1),$34(a0)
		bset	#0,obStatus(a0)
		move.w	obX(a0),d0
		cmp.w	obX(a1),d0
		bgt.s	loc_18D68
		bclr	#0,obStatus(a0)
		move.b	#2,$3A(a0)

loc_18D68:
		addq.b	#2,obRoutine(a0)

Obj7B_Fall:	; Routine 2
		jsr	(ObjectFall).l
		movea.l	$3C(a0),a1
		lea	(word_19018).l,a2
		moveq	#0,d0
		move.b	obFrame(a1),d0
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bhs.s	loc_18D8E
		addq.w	#2,d0

loc_18D8E:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	obY(a0),d1
		bgt.s	locret_18DC4
		movea.l	$3C(a0),a1
		moveq	#2,d1
		btst	#0,obStatus(a0)
		beq.s	loc_18DAE
		moveq	#0,d1

loc_18DAE:
		move.w	#$F0,obSubtype(a0)
		move.b	#10,obDelayAni(a0)	; set frame duration to 10 frames
		move.b	obDelayAni(a0),obTimeFrame(a0)
		bra.w	loc_18FA2
; ===========================================================================

locret_18DC4:
		rts
; ===========================================================================

loc_18DC6:	; Routine 4
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$3A(a0),d0
		sub.b	$3A(a1),d0
		beq.s	loc_18E2A
		bhs.s	loc_18DDA
		neg.b	d0

loc_18DDA:
		move.w	#-$818,d1
		move.w	#-$114,d2
		cmpi.b	#1,d0
		beq.s	loc_18E00
		move.w	#-$960,d1
		move.w	#-$F4,d2
		cmpi.w	#$9C0,$38(a1)
		blt.s	loc_18E00
		move.w	#-$A20,d1
		move.w	#-$80,d2

loc_18E00:
		move.w	d1,obVelY(a0)
		move.w	d2,obVelX(a0)
		move.w	obX(a0),d0
		sub.w	$30(a0),d0
		bhs.s	loc_18E16
		neg.w	obVelX(a0)

loc_18E16:
		move.b	#1,obFrame(a0)
		move.w	#$20,obSubtype(a0)
		addq.b	#2,obRoutine(a0)
		bra.w	loc_18EAA
; ===========================================================================

loc_18E2A:
		lea	(word_19018).l,a2
		moveq	#0,d0
		move.b	obFrame(a1),d0
		move.w	#$28,d2
		move.w	obX(a0),d1
		sub.w	$30(a0),d1
		bhs.s	loc_18E48
		neg.w	d2
		addq.w	#2,d0

loc_18E48:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		move.w	d1,obY(a0)
		add.w	$30(a0),d2
		move.w	d2,obX(a0)
		clr.w	obY+2(a0)
		clr.w	obX+2(a0)
		subq.w	#1,obSubtype(a0)
		bne.s	loc_18E7A
		move.w	#$20,obSubtype(a0)
		move.b	#8,obRoutine(a0)
		rts
; ===========================================================================

loc_18E7A:
		cmpi.w	#$78,obSubtype(a0)
		bne.s	loc_18E88
		move.b	#5,obDelayAni(a0)

loc_18E88:
		cmpi.w	#$3C,obSubtype(a0)
		bne.s	loc_18E96
		move.b	#2,obDelayAni(a0)

loc_18E96:
		subq.b	#1,obTimeFrame(a0)
		bgt.s	locret_18EA8
		bchg	#0,obFrame(a0)
		move.b	obDelayAni(a0),obTimeFrame(a0)

locret_18EA8:
		rts
; ===========================================================================

loc_18EAA:	; Routine 6
		lea	(v_objspace+$40).w,a1
		moveq	#id_BossStarLight,d0
		moveq	#$40,d1
		moveq	#$3E,d2

loc_18EB4:
		cmp.b	(a1),d0
		beq.s	loc_18EC0
		adda.w	d1,a1
		dbf	d2,loc_18EB4

		bra.s	loc_18F38
; ===========================================================================

loc_18EC0:
		move.w	obX(a1),d0
		move.w	obY(a1),d1
		move.w	obX(a0),d2
		move.w	obY(a0),d3
		lea	byte_19022(pc),a2
		lea	byte_19026(pc),a3
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d0
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d2
		cmp.w	d0,d2
		blo.s	loc_18F38
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d0
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d2
		cmp.w	d2,d0
		blo.s	loc_18F38
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d1
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d3
		cmp.w	d1,d3
		blo.s	loc_18F38
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d1
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d3
		cmp.w	d3,d1
		blo.s	loc_18F38
		addq.b	#2,obRoutine(a0)
		clr.w	obSubtype(a0)
		clr.b	obColType(a1)
		subq.b	#1,obColProp(a1)
		bne.s	loc_18F38
		bset	#7,obStatus(a1)
		clr.w	obVelX(a0)
		clr.w	obVelY(a0)

loc_18F38:
		tst.w	obVelY(a0)
		bpl.s	loc_18F5C
		jsr	(ObjectFall).l
		move.w	$34(a0),d0
		subi.w	#$2F,d0
		cmp.w	obY(a0),d0
		bgt.s	loc_18F58
		jsr	(ObjectFall).l

loc_18F58:
		bra.w	loc_18E7A
; ===========================================================================

loc_18F5C:
		jsr	(ObjectFall).l
		movea.l	$3C(a0),a1
		lea	(word_19018).l,a2
		moveq	#0,d0
		move.b	obFrame(a1),d0
		move.w	obX(a0),d1
		sub.w	$30(a0),d1
		bhs.s	loc_18F7E
		addq.w	#2,d0

loc_18F7E:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	obY(a0),d1
		bgt.s	loc_18F58
		movea.l	$3C(a0),a1
		moveq	#2,d1
		tst.w	obVelX(a0)
		bmi.s	loc_18F9C
		moveq	#0,d1

loc_18F9C:
		move.w	#0,obSubtype(a0)

loc_18FA2:
		move.b	d1,$3A(a1)
		move.b	d1,$3A(a0)
		cmp.b	obFrame(a1),d1
		beq.s	loc_19008
		bclr	#3,obStatus(a1)
		beq.s	loc_19008
		clr.b	ob2ndRout(a1)
		move.b	#2,obRoutine(a1)
		lea	(v_player).w,a2
		move.w	obVelY(a0),obVelY(a2)
		neg.w	obVelY(a2)
		cmpi.b	#1,obFrame(a1)
		bne.s	loc_18FDC
		asr	obVelY(a2)

loc_18FDC:
		bset	#1,obStatus(a2)
		bclr	#3,obStatus(a2)
		clr.b	$3C(a2)
		move.l	a0,-(sp)
		lea	(a2),a0
		jsr	(Sonic_ChkRoll).l
		movea.l	(sp)+,a0
		move.b	#2,obRoutine(a2)
		move.w	#sfx_Spring,d0
		jsr	(PlaySound_Special).l	; play "spring" sound

loc_19008:
		clr.w	obVelX(a0)
		clr.w	obVelY(a0)
		addq.b	#2,obRoutine(a0)
		bra.w	loc_18E7A
; ===========================================================================
word_19018:	dc.w -8, -$1C, -$2F, -$1C, -8
		even
byte_19022:	dc.b $E8, $30, $E8, $30
		even
byte_19026:	dc.b 8,	$F0, 8,	$F0
		even
; ===========================================================================

Obj7B_Explode:	; Routine 8
		move.b	#id_ExplosionBomb,(a0)
		clr.b	obRoutine(a0)
		cmpi.w	#$20,obSubtype(a0)
		beq.s	Obj7B_MakeFrag
		rts
; ===========================================================================

Obj7B_MakeFrag:
		move.w	$34(a0),obY(a0)
		moveq	#3,d1
		lea	Obj7B_FragSpeed(pc),a2

Obj7B_Loop:
		jsr	(FindFreeObj).l
		bne.s	loc_1909A
		move.b	#id_BossSpikeball,(a1) ; load shrapnel object
		move.b	#$A,obRoutine(a1)
		move.l	#Map_BSBall,obMap(a1)
		move.b	#3,obPriority(a1)
		move.w	#$518,obGfx(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	(a2)+,obVelX(a1)
		move.w	(a2)+,obVelY(a1)
		move.b	#$98,obColType(a1)
		ori.b	#4,obRender(a1)
		bset	#7,obRender(a1)
		move.b	#$C,obActWid(a1)

loc_1909A:
		dbf	d1,Obj7B_Loop	; repeat sequence 3 more times

		rts
; ===========================================================================
Obj7B_FragSpeed:dc.w -$100, -$340	; horizontal, vertical
		dc.w -$A0, -$240
		dc.w $100, -$340
		dc.w $A0, -$240
; ===========================================================================

Obj7B_MoveFrag:	; Routine $A
		jsr	(SpeedToPos).l
		move.w	obX(a0),$30(a0)
		move.w	obY(a0),$34(a0)
		addi.w	#$18,obVelY(a0)
		moveq	#4,d0
		and.w	(v_vbla_word).w,d0
		lsr.w	#2,d0
		move.b	d0,obFrame(a0)
		tst.b	1(a0)
		bpl.w	Obj7A_Delete
		rts

Map_BSBall:	include	"_maps\SLZ Boss Spikeball.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 75 - Eggman (SYZ)
; ---------------------------------------------------------------------------

; Obj75:
BossSpringYard:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj75_Index(pc,d0.w),d1
		jmp	Obj75_Index(pc,d1.w)
; ===========================================================================
Obj75_Index:	dc.w Obj75_Main-Obj75_Index
		dc.w Obj75_ShipMain-Obj75_Index
		dc.w Obj75_FaceMain-Obj75_Index
		dc.w Obj75_FlameMain-Obj75_Index
		dc.w Obj75_SpikeMain-Obj75_Index

Obj75_ObjData:	dc.b 2,	0, 5		; routine number, animation, priority
		dc.b 4,	1, 5
		dc.b 6,	7, 5
		dc.b 8,	0, 5
; ===========================================================================

Obj75_Main:	; Routine 0
		move.w	#$2DB0,obX(a0)
		move.w	#$4DA,obY(a0)
		move.w	obX(a0),$30(a0)
		move.w	obY(a0),$38(a0)
		move.b	#$F,obColType(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8
		lea	Obj75_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.s	Obj75_LoadBoss
; ===========================================================================

Obj75_Loop:
		jsr	(FindNextFreeObj).l
		bne.s	Obj75_ShipMain
		move.b	#id_BossSpringYard,(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

Obj75_LoadBoss:
		bclr	#0,obStatus(a0)
		clr.b	ob2ndRout(a1)
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,obAnim(a1)
		move.b	(a2)+,obPriority(a1)
		move.l	#Map_Eggman,obMap(a1)
		move.w	#$400,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$20,obActWid(a1)
		move.l	a0,$34(a1)
		dbf	d1,Obj75_Loop	; repeat sequence 3 more times

Obj75_ShipMain:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Obj75_ShipIndex(pc,d0.w),d1
		jsr	Obj75_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================
Obj75_ShipIndex:dc.w loc_191CC-Obj75_ShipIndex,	loc_19270-Obj75_ShipIndex
		dc.w loc_192EC-Obj75_ShipIndex,	loc_19474-Obj75_ShipIndex
		dc.w loc_194AC-Obj75_ShipIndex,	loc_194F2-Obj75_ShipIndex
; ===========================================================================

loc_191CC:
		move.w	#-$100,obVelX(a0)
		cmpi.w	#$2D38,$30(a0)
		bhs.s	loc_191DE
		addq.b	#2,ob2ndRout(a0)

loc_191DE:
		move.b	$3F(a0),d0
		addq.b	#2,$3F(a0)
		jsr	(CalcSine).l
		asr.w	#2,d0
		move.w	d0,obVelY(a0)

loc_191F2:
		bsr.w	BossMove
		move.w	$38(a0),obY(a0)
		move.w	$30(a0),obX(a0)

loc_19202:
		move.w	8(a0),d0
		subi.w	#$2C00,d0
		lsr.w	#5,d0
		move.b	d0,$34(a0)
		cmpi.b	#6,ob2ndRout(a0)
		bhs.s	locret_19256
		tst.b	obStatus(a0)
		bmi.s	loc_19258
		tst.b	obColType(a0)
		bne.s	locret_19256
		tst.b	$3E(a0)
		bne.s	loc_1923A
		move.b	#$20,$3E(a0)
		move.w	#sfx_HitBoss,d0
		jsr	(PlaySound_Special).l	; play boss damage sound

loc_1923A:
		lea	(v_pal_dry+$22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.s	loc_19248
		move.w	#cWhite,d0

loc_19248:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.s	locret_19256
		move.b	#$F,obColType(a0)

locret_19256:
		rts
; ===========================================================================

loc_19258:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#6,ob2ndRout(a0)
		move.w	#$B4,$3C(a0)
		clr.w	obVelX(a0)
		rts
; ===========================================================================

loc_19270:
		move.w	$30(a0),d0
		move.w	#$140,obVelX(a0)
		btst	#0,obStatus(a0)
		bne.s	loc_1928E
		neg.w	obVelX(a0)
		cmpi.w	#$2C08,d0
		bgt.s	loc_1929E
		bra.s	loc_19294
; ===========================================================================

loc_1928E:
		cmpi.w	#$2D38,d0
		blt.s	loc_1929E

loc_19294:
		bchg	#0,obStatus(a0)
		clr.b	standonobject(a0)

loc_1929E:
		subi.w	#$2C10,d0
		andi.w	#$1F,d0
		subi.w	#$1F,d0
		bpl.s	loc_192AE
		neg.w	d0

loc_192AE:
		subq.w	#1,d0
		bgt.s	loc_192E8
		tst.b	standonobject(a0)
		bne.s	loc_192E8
		move.w	(v_player+obX).w,d1
		subi.w	#$2C00,d1
		asr.w	#5,d1
		cmp.b	$34(a0),d1
		bne.s	loc_192E8
		moveq	#0,d0
		move.b	$34(a0),d0
		asl.w	#5,d0
		addi.w	#$2C10,d0
		move.w	d0,$30(a0)
		bsr.w	Obj75_FindBlocks
		addq.b	#2,ob2ndRout(a0)
		clr.w	obSubtype(a0)
		clr.w	obVelX(a0)

loc_192E8:
		bra.w	loc_191DE
; ===========================================================================

loc_192EC:
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		move.w	off_192FA(pc,d0.w),d0
		jmp	off_192FA(pc,d0.w)
; ===========================================================================
off_192FA:	dc.w loc_19302-off_192FA
		dc.w loc_19348-off_192FA
		dc.w loc_1938E-off_192FA
		dc.w loc_193D0-off_192FA
; ===========================================================================

loc_19302:
		move.w	#$180,obVelY(a0)
		move.w	$38(a0),d0
		cmpi.w	#$556,d0
		blo.s	loc_19344
		move.w	#$556,$38(a0)
		clr.w	$3C(a0)
		moveq	#-1,d0
		move.w	$36(a0),d0
		beq.s	loc_1933C
		movea.l	d0,a1
		move.b	#-1,$29(a1)
		move.b	#-1,$29(a0)
		move.l	a0,$34(a1)
		move.w	#$32,$3C(a0)

loc_1933C:
		clr.w	obVelY(a0)
		addq.b	#2,obSubtype(a0)

loc_19344:
		bra.w	loc_191F2
; ===========================================================================

loc_19348:
		subq.w	#1,$3C(a0)
		bpl.s	loc_19366
		addq.b	#2,obSubtype(a0)
		move.w	#-$800,obVelY(a0)
		tst.w	$36(a0)
		bne.s	loc_19362
		asr	obVelY(a0)

loc_19362:
		moveq	#0,d0
		bra.s	loc_1937C
; ===========================================================================

loc_19366:
		moveq	#0,d0
		cmpi.w	#$1E,$3C(a0)
		bgt.s	loc_1937C
		moveq	#2,d0
		btst	#1,standonobject(a0)
		beq.s	loc_1937C
		neg.w	d0

loc_1937C:
		add.w	$38(a0),d0
		move.w	d0,obY(a0)
		move.w	$30(a0),obX(a0)
		bra.w	loc_19202
; ===========================================================================

loc_1938E:
		move.w	#$4DA,d0
		tst.w	$36(a0)
		beq.s	loc_1939C
		subi.w	#$18,d0

loc_1939C:
		cmp.w	$38(a0),d0
		blt.s	loc_193BE
		move.w	#8,$3C(a0)
		tst.w	$36(a0)
		beq.s	loc_193B4
		move.w	#$2D,$3C(a0)

loc_193B4:
		addq.b	#2,obSubtype(a0)
		clr.w	obVelY(a0)
		bra.s	loc_193CC
; ===========================================================================

loc_193BE:
		cmpi.w	#-$40,obVelY(a0)
		bge.s	loc_193CC
		addi.w	#$C,obVelY(a0)

loc_193CC:
		bra.w	loc_191F2
; ===========================================================================

loc_193D0:
		subq.w	#1,$3C(a0)
		bgt.s	loc_19406
		bmi.s	loc_193EE
		moveq	#-1,d0
		move.w	$36(a0),d0
		beq.s	loc_193E8
		movea.l	d0,a1
		move.b	#$A,$29(a1)

loc_193E8:
		clr.w	$36(a0)
		bra.s	loc_19406
; ===========================================================================

loc_193EE:
		cmpi.w	#-$1E,$3C(a0)
		bne.s	loc_19406
		clr.b	$29(a0)
		subq.b	#2,ob2ndRout(a0)
		move.b	#-1,standonobject(a0)
		bra.s	loc_19446
; ===========================================================================

loc_19406:
		moveq	#1,d0
		tst.w	$36(a0)
		beq.s	loc_19410
		moveq	#2,d0

loc_19410:
		cmpi.w	#$4DA,$38(a0)
		beq.s	loc_19424
		blt.s	loc_1941C
		neg.w	d0

loc_1941C:
		tst.w	$36(a0)
		add.w	d0,$38(a0)

loc_19424:
		moveq	#0,d0
		tst.w	$36(a0)
		beq.s	loc_19438
		moveq	#2,d0
		btst	#0,standonobject(a0)
		beq.s	loc_19438
		neg.w	d0

loc_19438:
		add.w	$38(a0),d0
		move.w	d0,obY(a0)
		move.w	$30(a0),8(a0)

loc_19446:
		bra.w	loc_19202

Obj75_FindBlocks:
		clr.w	$36(a0)
		lea	(v_objspace+$40).w,a1
		moveq	#$3E,d0
		moveq	#$76,d1
		move.b	$34(a0),d2

Obj75_FindLoop:
		cmp.b	(a1),d1		; is object a SYZ boss block?
		bne.s	loc_1946A	; if not, branch
		cmp.b	obSubtype(a1),d2
		bne.s	loc_1946A
		move.w	a1,$36(a0)
		bra.s	locret_19472
; ===========================================================================

loc_1946A:
		lea	$40(a1),a1	; next object RAM entry
		dbf	d0,Obj75_FindLoop

locret_19472:
		rts
; End of function Obj75_FindBlocks

; ===========================================================================

loc_19474:
		subq.w	#1,$3C(a0)
		bmi.s	loc_1947E
		bra.w	BossDefeated
; ===========================================================================

loc_1947E:
		addq.b	#2,ob2ndRout(a0)
		clr.w	obVelY(a0)
		bset	#0,obStatus(a0)
		bclr	#7,obStatus(a0)
		clr.w	obVelX(a0)
		move.w	#-1,$3C(a0)
		tst.b	(v_bossstatus).w
		bne.s	loc_194A8
		move.b	#1,(v_bossstatus).w

loc_194A8:
		bra.w	loc_19202
; ===========================================================================

loc_194AC:
		addq.w	#1,$3C(a0)
		beq.s	loc_194BC
		bpl.s	loc_194C2
		addi.w	#$18,obVelY(a0)
		bra.s	loc_194EE
; ===========================================================================

loc_194BC:
		clr.w	obVelY(a0)
		bra.s	loc_194EE
; ===========================================================================

loc_194C2:
		cmpi.w	#$20,$3C(a0)
		blo.s	loc_194DA
		beq.s	loc_194E0
		cmpi.w	#$2A,$3C(a0)
		blo.s	loc_194EE
		addq.b	#2,ob2ndRout(a0)
		bra.s	loc_194EE
; ===========================================================================

loc_194DA:
		subq.w	#8,obVelY(a0)
		bra.s	loc_194EE
; ===========================================================================

loc_194E0:
		clr.w	obVelY(a0)
		move.w	#bgm_SYZ,d0
		jsr	(PlaySound).l		; play SYZ music

loc_194EE:
		bra.w	loc_191F2
; ===========================================================================

loc_194F2:
		move.w	#$400,obVelX(a0)
		move.w	#-$40,obVelY(a0)
		cmpi.w	#$2D40,(v_limitright2).w
		bhs.s	loc_1950C
		addq.w	#2,(v_limitright2).w
		bra.s	loc_19512
; ===========================================================================

loc_1950C:
		tst.b	obRender(a0)
		bpl.s	Obj75_ShipDelete

loc_19512:
		bsr.w	BossMove
		bra.w	loc_191DE
; ===========================================================================

Obj75_ShipDelete:
		jmp	(DeleteObject).l
; ===========================================================================

Obj75_FaceMain:	; Routine 4
		moveq	#1,d1
		movea.l	$34(a0),a1
		moveq	#0,d0
		move.b	ob2ndRout(a1),d0
		move.w	off_19546(pc,d0.w),d0
		jsr	off_19546(pc,d0.w)
		move.b	d1,obAnim(a0)
		move.b	(a0),d0
		cmp.b	(a1),d0
		bne.s	Obj75_FaceDelete
		bra.s	loc_195BE
; ===========================================================================

Obj75_FaceDelete:
		jmp	(DeleteObject).l
; ===========================================================================
off_19546:	dc.w loc_19574-off_19546, loc_19574-off_19546
		dc.w loc_1955A-off_19546, loc_19552-off_19546
		dc.w loc_19552-off_19546, loc_19556-off_19546
; ===========================================================================

loc_19552:
		moveq	#$A,d1
		rts
; ===========================================================================

loc_19556:
		moveq	#6,d1
		rts
; ===========================================================================

loc_1955A:
		moveq	#0,d0
		move.b	obSubtype(a1),d0
		move.w	off_19568(pc,d0.w),d0
		jmp	off_19568(pc,d0.w)
; ===========================================================================
off_19568:	dc.w loc_19570-off_19568, loc_19572-off_19568
		dc.w loc_19570-off_19568, loc_19570-off_19568
; ===========================================================================

loc_19570:
		bra.s	loc_19574
; ===========================================================================

loc_19572:
		moveq	#6,d1

loc_19574:
		tst.b	obColType(a1)
		bne.s	loc_1957E
		moveq	#5,d1
		rts
; ===========================================================================

loc_1957E:
		cmpi.b	#4,(v_player+obRoutine).w
		blo.s	locret_19588
		moveq	#4,d1

locret_19588:
		rts
; ===========================================================================

Obj75_FlameMain:; Routine 6
		move.b	#7,obAnim(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$A,ob2ndRout(a1)
		bne.s	loc_195AA
		move.b	#$B,obAnim(a0)
		tst.b	1(a0)
		bpl.s	Obj75_FlameDelete
		bra.s	loc_195B6
; ===========================================================================

loc_195AA:
		tst.w	obVelX(a1)
		beq.s	loc_195B6
		move.b	#8,obAnim(a0)

loc_195B6:
		bra.s	loc_195BE
; ===========================================================================

Obj75_FlameDelete:
		jmp	(DeleteObject).l
; ===========================================================================

loc_195BE:
		lea	(Ani_Eggman).l,a1
		jsr	(AnimateSprite).l
		movea.l	$34(a0),a1
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)

loc_195DA:
		move.b	obStatus(a1),obStatus(a0)
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================

Obj75_SpikeMain:; Routine 8
		move.l	#Map_BossItems,obMap(a0)
		move.w	#$246C,obGfx(a0)
		move.b	#5,obFrame(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$A,ob2ndRout(a1)
		bne.s	loc_1961C
		tst.b	obRender(a0)
		bpl.s	Obj75_SpikeDelete

loc_1961C:
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		move.w	$3C(a0),d0
		cmpi.b	#4,ob2ndRout(a1)
		bne.s	loc_19652
		cmpi.b	#6,obSubtype(a1)
		beq.s	loc_1964C
		tst.b	obSubtype(a1)
		bne.s	loc_19658
		cmpi.w	#$94,d0
		bge.s	loc_19658
		addq.w	#7,d0
		bra.s	loc_19658
; ===========================================================================

loc_1964C:
		tst.w	$3C(a1)
		bpl.s	loc_19658

loc_19652:
		tst.w	d0
		ble.s	loc_19658
		subq.w	#5,d0

loc_19658:
		move.w	d0,$3C(a0)
		asr.w	#2,d0
		add.w	d0,obY(a0)
		move.b	#8,obActWid(a0)
		move.b	#$C,obHeight(a0)
		clr.b	obColType(a0)
		movea.l	$34(a0),a1
		tst.b	obColType(a1)
		beq.s	loc_19688
		tst.b	$29(a1)
		bne.s	loc_19688
		move.b	#$84,obColType(a0)

loc_19688:
		bra.w	loc_195DA
; ===========================================================================

Obj75_SpikeDelete:
		jmp	(DeleteObject).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 76 - blocks that Eggman picks up (SYZ)
; ---------------------------------------------------------------------------

; Obj76:
BossBlock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj76_Index(pc,d0.w),d1
		jmp	Obj76_Index(pc,d1.w)
; ===========================================================================
Obj76_Index:	dc.w Obj76_Main-Obj76_Index
		dc.w Obj76_Action-Obj76_Index
		dc.w loc_19762-Obj76_Index
; ===========================================================================

Obj76_Main:	; Routine 0
		moveq	#0,d4
		move.w	#$2C10,d5
		moveq	#9,d6
		lea	(a0),a1
		bra.s	Obj76_MakeBlock
; ===========================================================================

Obj76_Loop:
		jsr	(FindFreeObj).l
		bne.s	Obj76_ExitLoop

Obj76_MakeBlock:
		move.b	#id_BossBlock,(a1)
		move.l	#Map_BossBlock,obMap(a1)
		move.w	#$4000,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$10,obActWid(a1)
		move.b	#$10,obHeight(a1)
		move.b	#3,obPriority(a1)
		move.w	d5,obX(a1)	; set x-position
		move.w	#$582,obY(a1)
		move.w	d4,obSubtype(a1)
		addi.w	#$101,d4
		addi.w	#$20,d5		; add $20 to next x-position
		addq.b	#2,obRoutine(a1)
		dbf	d6,Obj76_Loop	; repeat sequence 9 more times

Obj76_ExitLoop:
		rts
; ===========================================================================

Obj76_Action:	; Routine 2
		move.b	$29(a0),d0
		cmp.b	obSubtype(a0),d0
		beq.s	Obj76_Solid
		tst.b	d0
		bmi.s	loc_19718

loc_19712:
		bsr.w	Obj76_Break
		bra.s	Obj76_Display
; ===========================================================================

loc_19718:
		movea.l	$34(a0),a1
		tst.b	obColProp(a1)
		beq.s	loc_19712
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		addi.w	#$2C,obY(a0)
		cmpa.w	a0,a1
		blo.s	Obj76_Display
		move.w	obVelY(a1),d0
		ext.l	d0
		asr.l	#8,d0
		add.w	d0,obY(a0)
		bra.s	Obj76_Display
; ===========================================================================

Obj76_Solid:
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	obX(a0),d4
		jsr	(SolidObject).l

Obj76_Display:
		jmp	(DisplaySprite).l
; ===========================================================================

loc_19762:	; Routine 4
		tst.b	obRender(a0)
		bpl.s	Obj76_Delete
		jsr	(ObjectFall).l
		jmp	(DisplaySprite).l
; ===========================================================================

Obj76_Delete:
		jmp	(DeleteObject).l

Obj76_Break:
		lea	Obj76_FragSpeed(pc),a4
		lea	Obj76_FragPos(pc),a5
		moveq	#1,d4
		moveq	#3,d1
		moveq	#$38,d2
		addq.b	#2,obRoutine(a0)
		move.b	#8,obActWid(a0)
		move.b	#8,obHeight(a0)
		lea	(a0),a1
		bra.s	Obj76_MakeFrag
; ===========================================================================

Obj76_LoopFrag:
		jsr	(FindNextFreeObj).l
		bne.s	loc_197D4

Obj76_MakeFrag:
		lea	(a0),a2
		lea	(a1),a3
		moveq	#3,d3

loc_197AA:
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		dbf	d3,loc_197AA

		move.w	(a4)+,obVelX(a1)
		move.w	(a4)+,obVelY(a1)
		move.w	(a5)+,d3
		add.w	d3,obX(a1)
		move.w	(a5)+,d3
		add.w	d3,obY(a1)
		move.b	d4,obFrame(a1)
		addq.w	#1,d4
		dbf	d1,Obj76_LoopFrag ; repeat sequence 3 more times

loc_197D4:
		move.w	#sfx_WallSmash,d0
		jmp	(PlaySound_Special).l	; play smashing sound
; End of function Obj76_Break

; ===========================================================================
Obj76_FragSpeed:dc.w -$180, -$200
		dc.w $180, -$200
		dc.w -$100, -$100
		dc.w $100, -$100
Obj76_FragPos:	dc.w -8, -8
		dc.w $10, 0
		dc.w 0,	$10
		dc.w $10, $10

Map_BossBlock:	include	"_maps\SYZ Boss Blocks.asm"

loc_1982C:
		jmp	(DeleteObject).l

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 82 - Eggman (SBZ2)
; ---------------------------------------------------------------------------

; Obj82:
ScrapEggman:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	SEgg_Index(pc,d0.w),d1
		jmp	SEgg_Index(pc,d1.w)
; ===========================================================================
SEgg_Index:	dc.w SEgg_Main-SEgg_Index
		dc.w SEgg_Eggman-SEgg_Index
		dc.w SEgg_Switch-SEgg_Index

SEgg_ObjData:	dc.b 2,	0, 3		; routine number, animation, priority
		dc.b 4,	0, 3
; ===========================================================================

SEgg_Main:	; Routine 0
		lea	SEgg_ObjData(pc),a2
		move.w	#$2160,obX(a0)
		move.w	#$5A4,obY(a0)
		move.b	#$F,obColType(a0)
		move.b	#$10,obColProp(a0)
		bclr	#0,obStatus(a0)
		clr.b	ob2ndRout(a0)
		move.b	(a2)+,obRoutine(a0)
		move.b	(a2)+,obAnim(a0)
		move.b	(a2)+,obPriority(a0)
		move.l	#Map_SEgg,obMap(a0)
		move.w	#$400,obGfx(a0)
		move.b	#4,obRender(a0)
		bset	#7,obRender(a0)
		move.b	#$20,obActWid(a0)
		jsr	(FindNextFreeObj).l
		bne.s	SEgg_Eggman
		move.l	a0,$34(a1)
		move.b	#id_ScrapEggman,(a1) ; load switch object
		move.w	#$2130,obX(a1)
		move.w	#$5BC,obY(a1)
		clr.b	ob2ndRout(a0)
		move.b	(a2)+,obRoutine(a1)
		move.b	(a2)+,obAnim(a1)
		move.b	(a2)+,obPriority(a1)
		move.l	#Map_But,obMap(a1)
		move.w	#$4A4,obGfx(a1)
		move.b	#4,obRender(a1)
		bset	#7,obRender(a1)
		move.b	#$10,obActWid(a1)
		move.b	#0,obFrame(a1)

SEgg_Eggman:	; Routine 2
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	SEgg_EggIndex(pc,d0.w),d1
		jsr	SEgg_EggIndex(pc,d1.w)
		lea	Ani_SEgg(pc),a1
		jsr	(AnimateSprite).l
		jmp	(DisplaySprite).l
; ===========================================================================
SEgg_EggIndex:	dc.w SEgg_ChkSonic-SEgg_EggIndex
		dc.w SEgg_PreLeap-SEgg_EggIndex
		dc.w SEgg_Leap-SEgg_EggIndex
		dc.w loc_19934-SEgg_EggIndex
; ===========================================================================

SEgg_ChkSonic:
		move.w	obX(a0),d0
		sub.w	(v_player+obX).w,d0
		cmpi.w	#128,d0		; is Sonic within 128 pixels of Eggman?
		bhs.s	loc_19934	; if not, branch
		addq.b	#2,ob2ndRout(a0)
		move.w	#180,$3C(a0)	; set delay to 3 seconds
		move.b	#1,obAnim(a0)

loc_19934:
		jmp	(SpeedToPos).l
; ===========================================================================

SEgg_PreLeap:
		subq.w	#1,$3C(a0)	; subtract 1 from time delay
		bne.s	loc_19954	; if time remains, branch
		addq.b	#2,ob2ndRout(a0)
		move.b	#2,obAnim(a0)
		addq.w	#4,obY(a0)
		move.w	#15,$3C(a0)

loc_19954:
		bra.s	loc_19934
; ===========================================================================

SEgg_Leap:
		subq.w	#1,$3C(a0)
		bgt.s	loc_199D0
		bne.s	loc_1996A
		move.w	#-$FC,obVelX(a0) ; make Eggman leap
		move.w	#-$3C0,obVelY(a0)

loc_1996A:
		cmpi.w	#$2132,obX(a0)
		bgt.s	loc_19976
		clr.w	obVelX(a0)

loc_19976:
		addi.w	#$24,obVelY(a0)
		tst.w	obVelY(a0)
		bmi.s	SEgg_FindBlocks
		cmpi.w	#$595,obY(a0)
		blo.s	SEgg_FindBlocks
		move.w	#$5357,obSubtype(a0)
		cmpi.w	#$59B,obY(a0)
		blo.s	SEgg_FindBlocks
		move.w	#$59B,obY(a0)
		clr.w	obVelY(a0)

SEgg_FindBlocks:
		move.w	obVelX(a0),d0
		or.w	obVelY(a0),d0
		bne.s	loc_199D0
		lea	(v_objspace).w,a1 ; start at the first object RAM
		moveq	#$3E,d0
		moveq	#$40,d1

SEgg_FindLoop:
		adda.w	d1,a1		; jump to next object RAM
		cmpi.b	#id_FalseFloor,(a1) ; is object a block? (object $83)
		dbeq	d0,SEgg_FindLoop ; if not, repeat (max $3E times)

		bne.s	loc_199D0
		move.w	#$474F,obSubtype(a1) ; set block to disintegrate
		addq.b	#2,ob2ndRout(a0)
		move.b	#1,obAnim(a0)

loc_199D0:
		bra.w	loc_19934
; ===========================================================================

SEgg_Switch:	; Routine 4
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	SEgg_SwIndex(pc,d0.w),d0
		jmp	SEgg_SwIndex(pc,d0.w)
; ===========================================================================
SEgg_SwIndex:	dc.w loc_199E6-SEgg_SwIndex
		dc.w SEgg_SwDisplay-SEgg_SwIndex
; ===========================================================================

loc_199E6:
		movea.l	$34(a0),a1
		cmpi.w	#$5357,obSubtype(a1)
		bne.s	SEgg_SwDisplay
		move.b	#1,obFrame(a0)
		addq.b	#2,ob2ndRout(a0)

SEgg_SwDisplay:
		jmp	(DisplaySprite).l

		include	"_anim\Eggman - Scrap Brain 2 & Final.asm"
Map_SEgg:	include	"_maps\Eggman - Scrap Brain 2.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 83 - blocks that disintegrate Eggman presses	a switch (SBZ2)
; ---------------------------------------------------------------------------

; Obj83:
FalseFloor:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	FFloor_Index(pc,d0.w),d1
		jmp	FFloor_Index(pc,d1.w)
; ===========================================================================
FFloor_Index:	dc.w FFloor_Main-FFloor_Index
		dc.w FFloor_ChkBreak-FFloor_Index
		dc.w loc_19C36-FFloor_Index
		dc.w loc_19C62-FFloor_Index
		dc.w loc_19C72-FFloor_Index
		dc.w loc_19C80-FFloor_Index
; ===========================================================================

FFloor_Main:	; Routine 0
		move.w	#$2080,obX(a0)
		move.w	#$5D0,obY(a0)
		move.b	#$80,obActWid(a0)
		move.b	#$10,obHeight(a0)
		move.b	#4,obRender(a0)
		bset	#7,obRender(a0)
		moveq	#0,d4
		move.w	#$2010,d5
		moveq	#7,d6
		lea	$30(a0),a2

FFloor_MakeBlock:
		jsr	(FindFreeObj).l
		bne.s	FFloor_ExitMake
		move.w	a1,(a2)+
		move.b	#id_FalseFloor,(a1) ; load block object
		move.l	#Map_FFloor,obMap(a1)
		move.w	#$4518,obGfx(a1)
		move.b	#4,obRender(a1)
		move.b	#$10,obActWid(a1)
		move.b	#$10,obHeight(a1)
		move.b	#3,obPriority(a1)
		move.w	d5,obX(a1)	; set X position
		move.w	#$5D0,obY(a1)
		addi.w	#$20,d5		; add $20 for next X position
		move.b	#8,obRoutine(a1)
		dbf	d6,FFloor_MakeBlock ; repeat sequence 7 more times

FFloor_ExitMake:
		addq.b	#2,obRoutine(a0)
		rts
; ===========================================================================

FFloor_ChkBreak:; Routine 2
		cmpi.w	#$474F,obSubtype(a0) ; is object set to disintegrate?
		bne.s	FFloor_Solid	; if not, branch
		clr.b	obFrame(a0)
		addq.b	#2,obRoutine(a0) ; next subroutine

FFloor_Solid:
		moveq	#0,d0
		move.b	obFrame(a0),d0
		neg.b	d0
		ext.w	d0
		addq.w	#8,d0
		asl.w	#4,d0
		move.w	#$2100,d4
		sub.w	d0,d4
		move.b	d0,obActWid(a0)
		move.w	d4,obX(a0)
		moveq	#$B,d1
		add.w	d0,d1
		moveq	#$10,d2
		moveq	#$11,d3
		jmp	(SolidObject).l
; ===========================================================================

loc_19C36:	; Routine 4
		subi.b	#$E,obTimeFrame(a0)
		bhs.s	FFloor_Solid2
		moveq	#-1,d0
		move.b	obFrame(a0),d0
		ext.w	d0
		add.w	d0,d0
		move.w	$30(a0,d0.w),d0
		movea.l	d0,a1
		move.w	#$474F,obSubtype(a1)
		addq.b	#1,obFrame(a0)
		cmpi.b	#8,obFrame(a0)
		beq.s	loc_19C62

FFloor_Solid2:
		bra.s	FFloor_Solid
; ===========================================================================

loc_19C62:	; Routine 6
		bclr	#3,obStatus(a0)
		bclr	#3,(v_player+obStatus).w
		bra.w	loc_1982C
; ===========================================================================

loc_19C72:	; Routine 8
		cmpi.w	#$474F,obSubtype(a0) ; is object set to disintegrate?
		beq.s	FFloor_Break	; if yes, branch
		jmp	(DisplaySprite).l
; ===========================================================================

loc_19C80:	; Routine $A
		tst.b	obRender(a0)
		bpl.w	loc_1982C
		jsr	(ObjectFall).l
		jmp	(DisplaySprite).l
; ===========================================================================

FFloor_Break:
		lea	FFloor_FragSpeed(pc),a4
		lea	FFloor_FragPos(pc),a5
		moveq	#1,d4
		moveq	#3,d1
		moveq	#$38,d2
		addq.b	#2,obRoutine(a0)
		move.b	#8,obActWid(a0)
		move.b	#8,obHeight(a0)
		lea	(a0),a1
		bra.s	FFloor_MakeFrag
; ===========================================================================

FFloor_LoopFrag:
		jsr	(FindNextFreeObj).l
		bne.s	FFloor_BreakSnd

FFloor_MakeFrag:
		lea	(a0),a2
		lea	(a1),a3
		moveq	#3,d3

loc_19CC4:
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		dbf	d3,loc_19CC4

		move.w	(a4)+,obVelY(a1)
		move.w	(a5)+,d3
		add.w	d3,obX(a1)
		move.w	(a5)+,d3
		add.w	d3,obY(a1)
		move.b	d4,obFrame(a1)
		addq.w	#1,d4
		dbf	d1,FFloor_LoopFrag ; repeat sequence 3 more times

FFloor_BreakSnd:
		move.w	#sfx_WallSmash,d0
		jsr	(PlaySound_Special).l	; play smashing sound
		jmp	(DisplaySprite).l
; ===========================================================================
FFloor_FragSpeed:dc.w $80, 0
		dc.w $120, $C0
FFloor_FragPos:	dc.w -8, -8
		dc.w $10, 0
		dc.w 0,	$10
		dc.w $10, $10

Map_FFloor:	include	"_maps\SBZ Eggman's Crumbling Floor.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 85 - Eggman (FZ)
; ---------------------------------------------------------------------------

; Obj85:
Obj85_Delete:
		jmp	(DeleteObject).l
; ===========================================================================

BossFinal:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj85_Index(pc,d0.w),d0
		jmp	Obj85_Index(pc,d0.w)
; ===========================================================================
Obj85_Index:	dc.w Obj85_Main-Obj85_Index
		dc.w Obj85_Eggman-Obj85_Index
		dc.w loc_1A38E-Obj85_Index
		dc.w loc_1A346-Obj85_Index
		dc.w loc_1A2C6-Obj85_Index
		dc.w loc_1A3AC-Obj85_Index
		dc.w loc_1A264-Obj85_Index

Obj85_ObjData:	dc.w $100, $100, $470	; X pos, Y pos, VRAM setting
		dc.l Map_SEgg		; mappings pointer
		dc.w $25B0, $590, $300
		dc.l Map_EggCyl
		dc.w $26E0, $596, $3A0
		dc.l Map_FZLegs
		dc.w $26E0, $596, $470
		dc.l Map_SEgg
		dc.w $26E0, $596, $400
		dc.l Map_Eggman
		dc.w $26E0, $596, $400
		dc.l Map_Eggman

Obj85_ObjData2:	dc.b 2,	0, 4, $20, $19	; routine num, animation, sprite priority, width, height
		dc.b 4,	0, 1, $12, 8
		dc.b 6,	0, 3, 0, 0
		dc.b 8,	0, 3, 0, 0
		dc.b $A, 0, 3, $20, $20
		dc.b $C, 0, 3, 0, 0
; ===========================================================================

Obj85_Main:	; Routine 0
		lea	Obj85_ObjData(pc),a2
		lea	Obj85_ObjData2(pc),a3
		movea.l	a0,a1
		moveq	#5,d1
		bra.s	Obj85_LoadBoss
; ===========================================================================

Obj85_Loop:
		jsr	(FindNextFreeObj).l
		bne.s	loc_19E20

Obj85_LoadBoss:
		move.b	#id_BossFinal,(a1)
		move.w	(a2)+,obX(a1)
		move.w	(a2)+,obY(a1)
		move.w	(a2)+,obGfx(a1)
		move.l	(a2)+,obMap(a1)
		move.b	(a3)+,obRoutine(a1)
		move.b	(a3)+,obAnim(a1)
		move.b	(a3)+,obPriority(a1)
		move.b	(a3)+,obActWid(a1)
		move.b	(a3)+,obHeight(a1)
		move.b	#4,obRender(a1)
		bset	#7,obRender(a0)
		move.l	a0,$34(a1)
		dbf	d1,Obj85_Loop

loc_19E20:
		lea	$36(a0),a2
		jsr	(FindFreeObj).l
		bne.s	loc_19E5A
		move.b	#id_BossPlasma,(a1) ; load energy ball object
		move.w	a1,(a2)
		move.l	a0,$34(a1)
		lea	$38(a0),a2
		moveq	#0,d2
		moveq	#3,d1

loc_19E3E:
		jsr	(FindNextFreeObj).l
		bne.s	loc_19E5A
		move.w	a1,(a2)+
		move.b	#id_EggmanCylinder,(a1) ; load crushing cylinder object
		move.l	a0,$34(a1)
		move.b	d2,obSubtype(a1)
		addq.w	#2,d2
		dbf	d1,loc_19E3E

loc_19E5A:
		move.w	#0,$34(a0)
		move.b	#8,obColProp(a0) ; set number of hits to 8
		move.w	#-1,$30(a0)

Obj85_Eggman:	; Routine 2
		moveq	#0,d0
		move.b	$34(a0),d0
		move.w	off_19E80(pc,d0.w),d0
		jsr	off_19E80(pc,d0.w)
		jmp	(DisplaySprite).l
; ===========================================================================
off_19E80:	dc.w loc_19E90-off_19E80, loc_19EA8-off_19E80
		dc.w loc_19FE6-off_19E80, loc_1A02A-off_19E80
		dc.w loc_1A074-off_19E80, loc_1A112-off_19E80
		dc.w loc_1A192-off_19E80, loc_1A1D4-off_19E80
; ===========================================================================

loc_19E90:
		tst.l	(v_plc_buffer).w
		bne.s	loc_19EA2
		cmpi.w	#$2450,(v_screenposx).w
		blo.s	loc_19EA2
		addq.b	#2,$34(a0)

loc_19EA2:
		addq.l	#1,(v_random).w
		rts
; ===========================================================================

loc_19EA8:
		tst.w	$30(a0)
		bpl.s	loc_19F10
		clr.w	$30(a0)
		jsr	(RandomNumber).l
		andi.w	#$C,d0
		move.w	d0,d1
		addq.w	#2,d1
		tst.l	d0
		bpl.s	loc_19EC6
		exg	d1,d0

loc_19EC6:
		lea	word_19FD6(pc),a1
		move.w	(a1,d0.w),d0
		move.w	(a1,d1.w),d1
		move.w	d0,$30(a0)
		moveq	#-1,d2
		move.w	$38(a0,d0.w),d2
		movea.l	d2,a1
		move.b	#-1,$29(a1)
		move.w	#-1,$30(a1)
		move.w	$38(a0,d1.w),d2
		movea.l	d2,a1
		move.b	#1,$29(a1)
		move.w	#0,$30(a1)
		move.w	#1,$32(a0)
		clr.b	$35(a0)
		move.w	#sfx_Rumbling,d0
		jsr	(PlaySound_Special).l	; play rumbling sound

loc_19F10:
		tst.w	$32(a0)
		bmi.w	loc_19FA6
		bclr	#0,obStatus(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		blo.s	loc_19F2E
		bset	#0,obStatus(a0)

loc_19F2E:
		move.w	#$2B,d1
		move.w	#$14,d2
		move.w	#$14,d3
		move.w	obX(a0),d4
		jsr	(SolidObject).l
		tst.w	d4
		bgt.s	loc_19F50

loc_19F48:
		tst.b	$35(a0)
		bne.s	loc_19F88
		bra.s	loc_19F96
; ===========================================================================

loc_19F50:
		addq.w	#7,(v_random).w
		cmpi.b	#id_Roll,(v_player+obAnim).w
		bne.s	loc_19F48
		move.w	#$300,d0
		btst	#0,obStatus(a0)
		bne.s	loc_19F6A
		neg.w	d0

loc_19F6A:
		move.w	d0,(v_player+obVelX).w
		tst.b	$35(a0)
		bne.s	loc_19F88
		subq.b	#1,obColProp(a0)
		move.b	#$64,$35(a0)
		move.w	#sfx_HitBoss,d0
		jsr	(PlaySound_Special).l	; play boss damage sound

loc_19F88:
		subq.b	#1,$35(a0)
		beq.s	loc_19F96
		move.b	#3,obAnim(a0)
		bra.s	loc_19F9C
; ===========================================================================

loc_19F96:
		move.b	#1,obAnim(a0)

loc_19F9C:
		lea	Ani_SEgg(pc),a1
		jmp	(AnimateSprite).l
; ===========================================================================

loc_19FA6:
		tst.b	obColProp(a0)
		beq.s	loc_19FBC
		addq.b	#2,$34(a0)
		move.w	#-1,$30(a0)
		clr.w	$32(a0)
		rts
; ===========================================================================

loc_19FBC:
		moveq	#100,d0
		bsr.w	AddPoints
		move.b	#6,$34(a0)
		move.w	#$25C0,obX(a0)
		move.w	#$53C,obY(a0)
		move.b	#$14,obHeight(a0)
		rts
; ===========================================================================
word_19FD6:	dc.w 0,	2, 2, 4, 4, 6, 6, 0
; ===========================================================================

loc_19FE6:
		moveq	#-1,d0
		move.w	$36(a0),d0
		movea.l	d0,a1
		tst.w	$30(a0)
		bpl.s	loc_1A000
		clr.w	$30(a0)
		move.b	#-1,$29(a1)
		bsr.s	loc_1A020

loc_1A000:
		moveq	#$F,d0
		and.w	(v_vbla_word).w,d0
		bne.s	loc_1A00A
		bsr.s	loc_1A020

loc_1A00A:
		tst.w	$32(a0)
		beq.s	locret_1A01E
		subq.b	#2,$34(a0)
		move.w	#-1,$30(a0)
		clr.w	$32(a0)

locret_1A01E:
		rts
; ===========================================================================

loc_1A020:
		move.w	#sfx_Electric,d0
		jmp	(PlaySound_Special).l	; play electricity sound
; ===========================================================================

loc_1A02A:
		move.b	#$30,obActWid(a0)
		bset	#0,obStatus(a0)
		jsr	(SpeedToPos).l
		move.b	#6,obFrame(a0)
		addi.w	#$10,obVelY(a0)
		cmpi.w	#$59C,obY(a0)
		blo.s	loc_1A070
		move.w	#$59C,obY(a0)
		addq.b	#2,$34(a0)
		move.b	#$20,obActWid(a0)
		move.w	#$100,obVelX(a0)
		move.w	#-$100,obVelY(a0)
		addq.b	#2,(v_dle_routine).w

loc_1A070:
		bra.w	loc_1A166
; ===========================================================================

loc_1A074:
		bset	#0,obStatus(a0)
		move.b	#4,obAnim(a0)
		jsr	(SpeedToPos).l
		addi.w	#$10,obVelY(a0)
		cmpi.w	#$5A3,obY(a0)
		blo.s	loc_1A09A
		move.w	#-$40,obVelY(a0)

loc_1A09A:
		move.w	#$400,obVelX(a0)
		move.w	obX(a0),d0
		sub.w	(v_player+obX).w,d0
		bpl.s	loc_1A0B4
		move.w	#$500,obVelX(a0)
		bra.w	loc_1A0F2
; ===========================================================================

loc_1A0B4:
		subi.w	#$70,d0
		blo.s	loc_1A0F2
		subi.w	#$100,obVelX(a0)
		subq.w	#8,d0
		blo.s	loc_1A0F2
		subi.w	#$100,obVelX(a0)
		subq.w	#8,d0
		blo.s	loc_1A0F2
		subi.w	#$80,obVelX(a0)
		subq.w	#8,d0
		blo.s	loc_1A0F2
		subi.w	#$80,obVelX(a0)
		subq.w	#8,d0
		blo.s	loc_1A0F2
		subi.w	#$80,obVelX(a0)
		subi.w	#$38,d0
		blo.s	loc_1A0F2
		clr.w	obVelX(a0)

loc_1A0F2:
		cmpi.w	#$26A0,obX(a0)
		blo.s	loc_1A110
		move.w	#$26A0,obX(a0)
		move.w	#$240,obVelX(a0)
		move.w	#-$4C0,obVelY(a0)
		addq.b	#2,$34(a0)

loc_1A110:
		bra.s	loc_1A15C
; ===========================================================================

loc_1A112:
		jsr	(SpeedToPos).l
		cmpi.w	#$26E0,obX(a0)
		blo.s	loc_1A124
		clr.w	obVelX(a0)

loc_1A124:
		addi.w	#$34,obVelY(a0)
		tst.w	obVelY(a0)
		bmi.s	loc_1A142
		cmpi.w	#$592,obY(a0)
		blo.s	loc_1A142
		move.w	#$592,obY(a0)
		clr.w	obVelY(a0)

loc_1A142:
		move.w	obVelX(a0),d0
		or.w	obVelY(a0),d0
		bne.s	loc_1A15C
		addq.b	#2,$34(a0)
		move.w	#-$180,obVelY(a0)
		move.b	#1,obColProp(a0)

loc_1A15C:
		lea	Ani_SEgg(pc),a1
		jsr	(AnimateSprite).l

loc_1A166:
		cmpi.w	#$2700,(v_limitright2).w
		bge.s	loc_1A172
		addq.w	#2,(v_limitright2).w

loc_1A172:
		cmpi.b	#$C,$34(a0)
		bge.s	locret_1A190
		move.w	#$1B,d1
		move.w	#$70,d2
		move.w	#$71,d3
		move.w	obX(a0),d4
		jmp	(SolidObject).l
; ===========================================================================

locret_1A190:
		rts
; ===========================================================================

loc_1A192:
		move.l	#Map_Eggman,obMap(a0)
		move.w	#$400,obGfx(a0)
		move.b	#0,obAnim(a0)
		bset	#0,obStatus(a0)
		jsr	(SpeedToPos).l
		cmpi.w	#$544,obY(a0)
		bhs.s	loc_1A1D0
		move.w	#$180,obVelX(a0)
		move.w	#-$18,obVelY(a0)
		move.b	#$F,obColType(a0)
		addq.b	#2,$34(a0)

loc_1A1D0:
		bra.w	loc_1A15C
; ===========================================================================

loc_1A1D4:
		bset	#0,obStatus(a0)
		jsr	(SpeedToPos).l
		tst.w	$30(a0)
		bne.s	loc_1A1FC
		tst.b	obColType(a0)
		bne.s	loc_1A216
		move.w	#$1E,$30(a0)
		move.w	#sfx_HitBoss,d0
		jsr	(PlaySound_Special).l	; play boss damage sound

loc_1A1FC:
		subq.w	#1,$30(a0)
		bne.s	loc_1A216
		tst.b	obStatus(a0)
		bpl.s	loc_1A210
		move.w	#$60,obVelY(a0)
		bra.s	loc_1A216
; ===========================================================================

loc_1A210:
		move.b	#$F,obColType(a0)

loc_1A216:
		cmpi.w	#$2790,(v_player+obX).w
		blt.s	loc_1A23A
		move.b	#1,(f_lockctrl).w
		move.w	#0,(v_jpadhold2).w
		clr.w	(v_player+obInertia).w
		tst.w	obVelY(a0)
		bpl.s	loc_1A248
		move.w	#$100,(v_jpadhold2).w

loc_1A23A:
		cmpi.w	#$27E0,(v_player+obX).w
		blt.s	loc_1A248
		move.w	#$27E0,(v_player+obX).w

loc_1A248:
		cmpi.w	#$2900,obX(a0)
		blo.s	loc_1A260
		tst.b	obRender(a0)
		bmi.s	loc_1A260
		move.b	#id_Ending,(v_gamemode).w
		bra.w	Obj85_Delete
; ===========================================================================

loc_1A260:
		bra.w	loc_1A15C
; ===========================================================================

loc_1A264:	; Routine 4
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.w	Obj85_Delete
		move.b	#7,obAnim(a0)
		cmpi.b	#$C,$34(a1)
		bge.s	loc_1A280
		bra.s	loc_1A2A6
; ===========================================================================

loc_1A280:
		tst.w	obVelX(a1)
		beq.s	loc_1A28C
		move.b	#$B,obAnim(a0)

loc_1A28C:
		lea	Ani_Eggman(pc),a1
		jsr	(AnimateSprite).l

loc_1A296:
		movea.l	$34(a0),a1
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)

loc_1A2A6:
		movea.l	$34(a0),a1
		move.b	obStatus(a1),obStatus(a0)
		moveq	#3,d0
		and.b	obStatus(a0),d0
		andi.b	#$FC,obRender(a0)
		or.b	d0,obRender(a0)
		jmp	(DisplaySprite).l
; ===========================================================================

loc_1A2C6:	; Routine 6
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.w	Obj85_Delete
		cmpi.l	#Map_Eggman,obMap(a1)
		beq.s	loc_1A2E4
		move.b	#$A,obFrame(a0)
		bra.s	loc_1A2A6
; ===========================================================================

loc_1A2E4:
		move.b	#1,obAnim(a0)
		tst.b	obColProp(a1)
		ble.s	loc_1A312
		move.b	#6,obAnim(a0)
		move.l	#Map_Eggman,obMap(a0)
		move.w	#$400,obGfx(a0)
		lea	Ani_Eggman(pc),a1
		jsr	(AnimateSprite).l
		bra.w	loc_1A296
; ===========================================================================

loc_1A312:
		tst.b	1(a0)
		bpl.w	Obj85_Delete
		bsr.w	BossDefeated
		move.b	#2,obPriority(a0)
		move.b	#0,obAnim(a0)
		move.l	#Map_FZDamaged,obMap(a0)
		move.w	#$3A0,obGfx(a0)
		lea	Ani_FZEgg(pc),a1
		jsr	(AnimateSprite).l
		bra.w	loc_1A296
; ===========================================================================

loc_1A346:	; Routine 8
		bset	#0,obStatus(a0)
		movea.l	$34(a0),a1
		cmpi.l	#Map_Eggman,obMap(a1)
		beq.s	loc_1A35E
		bra.w	loc_1A2A6
; ===========================================================================

loc_1A35E:
		move.w	obX(a1),obX(a0)
		move.w	obY(a1),obY(a0)
		tst.b	obTimeFrame(a0)
		bne.s	loc_1A376
		move.b	#$14,obTimeFrame(a0)

loc_1A376:
		subq.b	#1,obTimeFrame(a0)
		bgt.s	loc_1A38A
		addq.b	#1,obFrame(a0)
		cmpi.b	#2,obFrame(a0)
		bgt.w	Obj85_Delete

loc_1A38A:
		bra.w	loc_1A296
; ===========================================================================

loc_1A38E:	; Routine $A
		move.b	#$B,obFrame(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		blo.s	loc_1A3A6
		tst.b	obRender(a0)
		bpl.w	Obj85_Delete

loc_1A3A6:
		jmp	(DisplaySprite).l
; ===========================================================================

loc_1A3AC:	; Routine $C
		move.b	#0,obFrame(a0)
		bset	#0,obStatus(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$C,$34(a1)
		bne.s	loc_1A3D0
		cmpi.l	#Map_Eggman,obMap(a1)
		beq.w	Obj85_Delete

loc_1A3D0:
		bra.w	loc_1A2A6

		include	"_anim\FZ Eggman in Ship.asm"
Map_FZDamaged:	include	"_maps\FZ Damaged Eggmobile.asm"
Map_FZLegs:	include	"_maps\FZ Eggmobile Legs.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 84 - cylinder Eggman hides in (FZ)
; ---------------------------------------------------------------------------

; Obj84:
Obj84_Delete:
		jmp	(DeleteObject).l
; ===========================================================================

EggmanCylinder:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj84_Index(pc,d0.w),d0
		jmp	Obj84_Index(pc,d0.w)
; ===========================================================================
Obj84_Index:	dc.w Obj84_Main-Obj84_Index
		dc.w loc_1A4CE-Obj84_Index
		dc.w loc_1A57E-Obj84_Index

Obj84_PosData:	dc.w $24D0, $620
		dc.w $2550, $620
		dc.w $2490, $4C0
		dc.w $2510, $4C0
; ===========================================================================

Obj84_Main:	; Routine
		lea	Obj84_PosData(pc),a1
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		add.w	d0,d0
		adda.w	d0,a1
		move.b	#4,obRender(a0)
		bset	#7,obRender(a0)
		bset	#4,obRender(a0)
		move.w	#$300,obGfx(a0)
		move.l	#Map_EggCyl,obMap(a0)
		move.w	(a1)+,obX(a0)
		move.w	(a1),obY(a0)
		move.w	(a1)+,$38(a0)
		move.b	#$20,obHeight(a0)
		move.b	#$60,obWidth(a0)
		move.b	#$20,obActWid(a0)
		move.b	#$60,obHeight(a0)
		move.b	#3,obPriority(a0)
		addq.b	#2,obRoutine(a0)

loc_1A4CE:	; Routine 2
		cmpi.b	#2,obSubtype(a0)
		ble.s	loc_1A4DC
		bset	#1,obRender(a0)

loc_1A4DC:
		clr.l	$3C(a0)
		tst.b	$29(a0)
		beq.s	loc_1A4EA
		addq.b	#2,obRoutine(a0)

loc_1A4EA:
		move.l	$3C(a0),d0
		move.l	$38(a0),d1
		add.l	d0,d1
		swap	d1
		move.w	d1,obY(a0)
		cmpi.b	#4,obRoutine(a0)
		bne.s	loc_1A524
		tst.w	$30(a0)
		bpl.s	loc_1A524
		moveq	#-$A,d0
		cmpi.b	#2,obSubtype(a0)
		ble.s	loc_1A514
		moveq	#$E,d0

loc_1A514:
		add.w	d0,d1
		movea.l	$34(a0),a1
		move.w	d1,obY(a1)
		move.w	obX(a0),obX(a1)

loc_1A524:
		move.w	#$2B,d1
		move.w	#$60,d2
		move.w	#$61,d3
		move.w	obX(a0),d4
		jsr	(SolidObject).l
		moveq	#0,d0
		move.w	$3C(a0),d1
		bpl.s	loc_1A550
		neg.w	d1
		subq.w	#8,d1
		blo.s	loc_1A55C
		addq.b	#1,d0
		asr.w	#4,d1
		add.w	d1,d0
		bra.s	loc_1A55C
; ===========================================================================

loc_1A550:
		subi.w	#$27,d1
		blo.s	loc_1A55C
		addq.b	#1,d0
		asr.w	#4,d1
		add.w	d1,d0

loc_1A55C:
		move.b	d0,obFrame(a0)
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bmi.s	loc_1A578
		subi.w	#$140,d0
		bmi.s	loc_1A578
		tst.b	obRender(a0)
		bpl.w	Obj84_Delete

loc_1A578:
		jmp	(DisplaySprite).l
; ===========================================================================

loc_1A57E:	; Routine 4
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		move.w	off_1A590(pc,d0.w),d0
		jsr	off_1A590(pc,d0.w)
		bra.w	loc_1A4EA
; ===========================================================================
off_1A590:	dc.w loc_1A598-off_1A590
		dc.w loc_1A598-off_1A590
		dc.w loc_1A604-off_1A590
		dc.w loc_1A604-off_1A590
; ===========================================================================

loc_1A598:
		tst.b	$29(a0)
		bne.s	loc_1A5D4
		movea.l	$34(a0),a1
		tst.b	obColProp(a1)
		bne.s	loc_1A5B4
		bsr.w	BossDefeated
		subi.l	#$10000,$3C(a0)

loc_1A5B4:
		addi.l	#$20000,$3C(a0)
		bhs.s	locret_1A602
		clr.l	$3C(a0)
		movea.l	$34(a0),a1
		subq.w	#1,$32(a1)
		clr.w	$30(a1)
		subq.b	#2,obRoutine(a0)
		rts
; ===========================================================================

loc_1A5D4:
		cmpi.w	#-$10,$3C(a0)
		bge.s	loc_1A5E4
		subi.l	#$28000,$3C(a0)

loc_1A5E4:
		subi.l	#$8000,$3C(a0)
		cmpi.w	#-$A0,$3C(a0)
		bgt.s	locret_1A602
		clr.w	$3E(a0)
		move.w	#-$A0,$3C(a0)
		clr.b	$29(a0)

locret_1A602:
		rts
; ===========================================================================

loc_1A604:
		bset	#1,obRender(a0)
		tst.b	$29(a0)
		bne.s	loc_1A646
		movea.l	$34(a0),a1
		tst.b	obColProp(a1)
		bne.s	loc_1A626
		bsr.w	BossDefeated
		addi.l	#$10000,$3C(a0)

loc_1A626:
		subi.l	#$20000,$3C(a0)
		bhs.s	locret_1A674
		clr.l	$3C(a0)
		movea.l	$34(a0),a1
		subq.w	#1,$32(a1)
		clr.w	$30(a1)
		subq.b	#2,obRoutine(a0)
		rts
; ===========================================================================

loc_1A646:
		cmpi.w	#$10,$3C(a0)
		blt.s	loc_1A656
		addi.l	#$28000,$3C(a0)

loc_1A656:
		addi.l	#$8000,$3C(a0)
		cmpi.w	#$A0,$3C(a0)
		blt.s	locret_1A674
		clr.w	$3E(a0)
		move.w	#$A0,$3C(a0)
		clr.b	$29(a0)

locret_1A674:
		rts

Map_EggCyl:	include	"_maps\FZ Eggman's Cylinders.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 86 - energy balls (FZ)
; ---------------------------------------------------------------------------

; Obj86:
BossPlasma:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj86_Index(pc,d0.w),d0
		jmp	Obj86_Index(pc,d0.w)
; ===========================================================================
Obj86_Index:	dc.w Obj86_Main-Obj86_Index
		dc.w Obj86_Generator-Obj86_Index
		dc.w Obj86_MakeBalls-Obj86_Index
		dc.w loc_1A962-Obj86_Index
		dc.w loc_1A982-Obj86_Index
; ===========================================================================

Obj86_Main:	; Routine 0
		move.w	#$2588,obX(a0)
		move.w	#$53C,obY(a0)
		move.w	#$300,obGfx(a0)
		move.l	#Map_PLaunch,obMap(a0)
		move.b	#0,obAnim(a0)
		move.b	#3,obPriority(a0)
		move.b	#8,obWidth(a0)
		move.b	#8,obHeight(a0)
		move.b	#4,obRender(a0)
		bset	#7,obRender(a0)
		addq.b	#2,obRoutine(a0)

Obj86_Generator:; Routine 2
		movea.l	$34(a0),a1
		cmpi.b	#6,$34(a1)
		bne.s	loc_1A850
		move.b	#id_ExplosionBomb,(a0)
		move.b	#0,obRoutine(a0)
		jmp	(DisplaySprite).l
; ===========================================================================

loc_1A850:
		move.b	#0,obAnim(a0)
		tst.b	$29(a0)
		beq.s	loc_1A86C
		addq.b	#2,obRoutine(a0)
		move.b	#1,obAnim(a0)
		move.b	#$3E,obSubtype(a0)

loc_1A86C:
		move.w	#$13,d1
		move.w	#8,d2
		move.w	#$11,d3
		move.w	obX(a0),d4
		jsr	(SolidObject).l
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		bmi.s	loc_1A89A
		subi.w	#$140,d0
		bmi.s	loc_1A89A
		tst.b	obRender(a0)
		bpl.w	Obj84_Delete

loc_1A89A:
		lea	Ani_PLaunch(pc),a1
		jsr	(AnimateSprite).l
		jmp	(DisplaySprite).l
; ===========================================================================

Obj86_MakeBalls:; Routine 4
		tst.b	$29(a0)
		beq.w	loc_1A954
		clr.b	$29(a0)
		add.w	$30(a0),d0
		andi.w	#$1E,d0
		adda.w	d0,a2
		addq.w	#4,$30(a0)
		clr.w	$32(a0)
		moveq	#3,d2

Obj86_Loop:
		jsr	(FindNextFreeObj).l
		bne.w	loc_1A954
		move.b	#id_BossPlasma,(a1)
		move.w	obX(a0),obX(a1)
		move.w	#$53C,obY(a1)
		move.b	#8,obRoutine(a1)
		move.w	#$2300,obGfx(a1)
		move.l	#Map_Plasma,obMap(a1)
		move.b	#$C,obHeight(a1)
		move.b	#$C,obWidth(a1)
		move.b	#0,obColType(a1)
		move.b	#3,obPriority(a1)
		move.w	#$3E,obSubtype(a1)
		move.b	#4,obRender(a1)
		bset	#7,obRender(a1)
		move.l	a0,$34(a1)
		jsr	(RandomNumber).l
		move.w	$32(a0),d1
		muls.w	#-$4F,d1
		addi.w	#$2578,d1
		andi.w	#$1F,d0
		subi.w	#$10,d0
		add.w	d1,d0
		move.w	d0,$30(a1)
		addq.w	#1,$32(a0)
		move.w	$32(a0),$38(a0)
		dbf	d2,Obj86_Loop	; repeat sequence 3 more times

loc_1A954:
		tst.w	$32(a0)
		bne.s	loc_1A95E
		addq.b	#2,obRoutine(a0)

loc_1A95E:
		bra.w	loc_1A86C
; ===========================================================================

loc_1A962:	; Routine 6
		move.b	#2,obAnim(a0)
		tst.w	$38(a0)
		bne.s	loc_1A97E
		move.b	#2,obRoutine(a0)
		movea.l	$34(a0),a1
		move.w	#-1,$32(a1)

loc_1A97E:
		bra.w	loc_1A86C
; ===========================================================================

loc_1A982:	; Routine 8
		moveq	#0,d0
		move.b	ob2ndRout(a0),d0
		move.w	Obj86_Index2(pc,d0.w),d0
		jsr	Obj86_Index2(pc,d0.w)
		lea	Ani_Plasma(pc),a1
		jsr	(AnimateSprite).l
		jmp	(DisplaySprite).l
; ===========================================================================
Obj86_Index2:	dc.w loc_1A9A6-Obj86_Index2
		dc.w loc_1A9C0-Obj86_Index2
		dc.w loc_1AA1E-Obj86_Index2
; ===========================================================================

loc_1A9A6:
		move.w	$30(a0),d0
		sub.w	obX(a0),d0
		asl.w	#4,d0
		move.w	d0,obVelX(a0)
		move.w	#$B4,obSubtype(a0)
		addq.b	#2,ob2ndRout(a0)
		rts
; ===========================================================================

loc_1A9C0:
		tst.w	obVelX(a0)
		beq.s	loc_1A9E6
		jsr	(SpeedToPos).l
		move.w	obX(a0),d0
		sub.w	$30(a0),d0
		bhs.s	loc_1A9E6
		clr.w	obVelX(a0)
		add.w	d0,obX(a0)
		movea.l	$34(a0),a1
		subq.w	#1,$32(a1)

loc_1A9E6:
		move.b	#0,obAnim(a0)
		subq.w	#1,obSubtype(a0)
		bne.s	locret_1AA1C
		addq.b	#2,ob2ndRout(a0)
		move.b	#1,obAnim(a0)
		move.b	#$9A,obColType(a0)
		move.w	#$B4,obSubtype(a0)
		moveq	#0,d0
		move.w	(v_player+obX).w,d0
		sub.w	obX(a0),d0
		move.w	d0,obVelX(a0)
		move.w	#$140,obVelY(a0)

locret_1AA1C:
		rts
; ===========================================================================

loc_1AA1E:
		jsr	(SpeedToPos).l
		cmpi.w	#$5E0,obY(a0)
		bhs.s	loc_1AA34
		subq.w	#1,obSubtype(a0)
		beq.s	loc_1AA34
		rts
; ===========================================================================

loc_1AA34:
		movea.l	$34(a0),a1
		subq.w	#1,$38(a1)
		bra.w	Obj84_Delete

		include	"_anim\Plasma Ball Launcher.asm"
Map_PLaunch:	include	"_maps\Plasma Ball Launcher.asm"
		include	"_anim\Plasma Balls.asm"
Map_Plasma:	include	"_maps\Plasma Balls.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3E - prison capsule
; ---------------------------------------------------------------------------

; Obj3E:
Prison:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Pri_Index(pc,d0.w),d1
		jsr	Pri_Index(pc,d1.w)
		out_of_range.s	@delete
		jmp	(DisplaySprite).l

	@delete:
		jmp	(DeleteObject).l
; ===========================================================================
Pri_Index:	dc.w Pri_Main-Pri_Index
		dc.w Pri_BodyMain-Pri_Index
		dc.w Pri_Switched-Pri_Index
		dc.w Pri_Explosion-Pri_Index
		dc.w Pri_Explosion-Pri_Index
		dc.w Pri_Explosion-Pri_Index
		dc.w Pri_Animals-Pri_Index
		dc.w Pri_EndAct-Pri_Index

pri_origY:	equ $30		; original y-axis position

Pri_Var:	dc.b 2,	$20, 4,	0	; routine, width, priority, frame
		dc.b 4,	$C, 5, 1
		dc.b 6,	$10, 4,	3
		dc.b 8,	$10, 3,	5
; ===========================================================================

Pri_Main:	; Routine 0
		move.l	#Map_Pri,obMap(a0)
		move.w	#$49D,obGfx(a0)
		move.b	#4,obRender(a0)
		move.w	obY(a0),pri_origY(a0)
		moveq	#0,d0
		move.b	obSubtype(a0),d0
		lsl.w	#2,d0
		lea	Pri_Var(pc,d0.w),a1
		move.b	(a1)+,obRoutine(a0)
		move.b	(a1)+,obActWid(a0)
		move.b	(a1)+,obPriority(a0)
		move.b	(a1)+,obFrame(a0)
		cmpi.w	#8,d0		; is object type number 02?
		bne.s	@not02		; if not, branch

		move.b	#6,obColType(a0)
		move.b	#8,obColProp(a0)

	@not02:
		rts
; ===========================================================================

Pri_BodyMain:	; Routine 2
		cmpi.b	#2,(v_bossstatus).w
		beq.s	@chkopened
		move.w	#$2B,d1
		move.w	#$18,d2
		move.w	#$18,d3
		move.w	obX(a0),d4
		jmp	(SolidObject).l
; ===========================================================================

@chkopened:
		tst.b	ob2ndRout(a0)	; has the prison been opened?
		beq.s	@open		; if yes, branch
		clr.b	ob2ndRout(a0)
		bclr	#3,(v_player+obStatus).w
		bset	#1,(v_player+obStatus).w

	@open:
		move.b	#2,obFrame(a0)	; use frame number 2 (destroyed prison)
		rts
; ===========================================================================

Pri_Switched:	; Routine 4
		move.w	#$17,d1
		move.w	#8,d2
		move.w	#8,d3
		move.w	obX(a0),d4
		jsr	(SolidObject).l
		lea	(Ani_Pri).l,a1
		jsr	(AnimateSprite).l
		move.w	pri_origY(a0),obY(a0)
		tst.b	ob2ndRout(a0)	; has prison already been opened?
		beq.s	@open2		; if yes, branch

		addq.w	#8,obY(a0)
		move.b	#$A,obRoutine(a0)
		move.w	#60,obTimeFrame(a0) ; set time between animal spawns
		clr.b	(f_timecount).w	; stop time counter
		clr.b	(f_lockscreen).w ; lock screen position
		move.b	#1,(f_lockctrl).w ; lock controls
		move.w	#(btnR<<8),(v_jpadhold2).w ; make Sonic run to the right
		clr.b	ob2ndRout(a0)
		bclr	#3,(v_player+obStatus).w
		bset	#1,(v_player+obStatus).w

	@open2:
		rts
; ===========================================================================

Pri_Explosion:	; Routine 6, 8, $A
		moveq	#7,d0
		and.b	(v_vbla_byte).w,d0
		bne.s	@noexplosion
		jsr	(FindFreeObj).l
		bne.s	@noexplosion
		move.b	#id_ExplosionBomb,0(a1) ; load explosion object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		jsr	(RandomNumber).l
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,obX(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,obY(a1)

	@noexplosion:
		subq.w	#1,obTimeFrame(a0)
		beq.s	@makeanimal
		rts
; ===========================================================================

@makeanimal:
		move.b	#2,(v_bossstatus).w
		move.b	#$C,obRoutine(a0)	; replace explosions with animals
		move.b	#6,obFrame(a0)
		move.w	#150,obTimeFrame(a0)
		addi.w	#$20,obY(a0)
		moveq	#7,d6
		move.w	#$9A,d5
		moveq	#-$1C,d4

	@loop:
		jsr	(FindFreeObj).l
		bne.s	@fail
		move.b	#id_Animals,0(a1) ; load animal object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		add.w	d4,obX(a1)
		addq.w	#7,d4
		move.w	d5,$36(a1)
		subq.w	#8,d5
		dbf	d6,@loop	; repeat 7 more times

	@fail:
		rts
; ===========================================================================

Pri_Animals:	; Routine $C
		moveq	#7,d0
		and.b	(v_vbla_byte).w,d0
		bne.s	@noanimal
		jsr	(FindFreeObj).l
		bne.s	@noanimal
		move.b	#id_Animals,0(a1) ; load animal object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		jsr	(RandomNumber).l
		andi.w	#$1F,d0
		subq.w	#6,d0
		tst.w	d1
		bpl.s	@ispositive
		neg.w	d0

	@ispositive:
		add.w	d0,obX(a1)
		move.w	#$C,$36(a1)

	@noanimal:
		subq.w	#1,obTimeFrame(a0)
		bne.s	@wait
		addq.b	#2,obRoutine(a0)
		move.w	#180,obTimeFrame(a0)

	@wait:
		rts
; ===========================================================================

Pri_EndAct:	; Routine $E
		moveq	#$3E,d0
		moveq	#id_Animals,d1
		moveq	#$40,d2
		lea	(v_objspace+$40).w,a1 ; load object RAM

	@findanimal:
		cmp.b	(a1),d1		; is object $28 (animal) loaded?
		beq.s	@found		; if yes, branch
		adda.w	d2,a1		; next object RAM
		dbf	d0,@findanimal	; repeat $3E times

		jsr	(GotThroughAct).l
		jmp	(DeleteObject).l

	@found:
		rts

		include	"_anim\Prison Capsule.asm"
Map_Pri:	include	"_maps\Prison Capsule.asm"

; ---------------------------------------------------------------------------
; Subroutine to react to obColType(a0)
; ---------------------------------------------------------------------------

; TouchResponse:
ReactToItem:
		nop
		move.w	obX(a0),d2	; load Sonic's x-axis position
		move.w	obY(a0),d3	; load Sonic's y-axis position
		subq.w	#8,d2
		moveq	#0,d5
		move.b	obHeight(a0),d5	; load Sonic's height
		subq.b	#3,d5
		sub.w	d5,d3
		cmpi.b	#fr_Duck,obFrame(a0) ; is Sonic ducking?
		bne.s	@notducking	; if not, branch
		addi.w	#$C,d3
		moveq	#$A,d5

	@notducking:
		move.w	#$10,d4
		add.w	d5,d5
		lea	(v_lvlobjspace).w,a1 ; set object RAM start address
		move.w	#(v_lvlobjend-v_lvlobjspace)/$40-1,d6

@loop:
		tst.b	obRender(a1)
		bpl.s	@next
		move.b	obColType(a1),d0 ; load collision type
		bne.s	@proximity	; if nonzero, branch

	@next:
		lea	$40(a1),a1	; next object RAM
		dbf	d6,@loop	; repeat $5F more times

		moveq	#0,d0
		rts
; ===========================================================================
@sizes:		;   width, height
		dc.b  $14, $14		; $01
		dc.b   $C, $14		; $02
		dc.b  $14,  $C		; $03
		dc.b	4, $10		; $04
		dc.b   $C, $12		; $05
		dc.b  $10, $10		; $06
		dc.b	6,   6		; $07
		dc.b  $18,  $C		; $08
		dc.b   $C, $10		; $09
		dc.b  $10,  $C		; $0A
		dc.b	8,   8		; $0B
		dc.b  $14, $10		; $0C
		dc.b  $14,   8		; $0D
		dc.b   $E,  $E		; $0E
		dc.b  $18, $18		; $0F
		dc.b  $28, $10		; $10
		dc.b  $10, $18		; $11
		dc.b	8, $10		; $12
		dc.b  $20, $70		; $13
		dc.b  $40, $20		; $14
		dc.b  $80, $20		; $15
		dc.b  $20, $20		; $16
		dc.b	8,   8		; $17
		dc.b	4,   4		; $18
		dc.b  $20,   8		; $19
		dc.b   $C,  $C		; $1A
		dc.b	8,   4		; $1B
		dc.b  $18,   4		; $1C
		dc.b  $28,   4		; $1D
		dc.b	4,   8		; $1E
		dc.b	4, $18		; $1F
		dc.b	4, $28		; $20
		dc.b	4, $20		; $21
		dc.b  $18, $18		; $22
		dc.b   $C, $18		; $23
		dc.b  $48,   8		; $24
; ===========================================================================

@proximity:
		andi.w	#$3F,d0
		add.w	d0,d0
		lea	@sizes-2(pc,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	obX(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bhs.s	@outsidex	; branch if not touching
		add.w	d1,d1
		add.w	d1,d0
		blo.s	@withinx	; branch if touching
		bra.w	@next
; ===========================================================================

@outsidex:
		cmp.w	d4,d0
		bhi.w	@next

@withinx:
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	obY(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bhs.s	@outsidey	; branch if not touching
		add.w	d1,d1
		add.w	d0,d1
		blo.s	@withiny	; branch if touching
		bra.w	@next
; ===========================================================================

@outsidey:
		cmp.w	d5,d0
		bhi.w	@next

@withiny:
	@chktype:
		move.b	obColType(a1),d1 ; load collision type
		andi.b	#$C0,d1		; is obColType $40 or higher?
		beq.w	React_Enemy	; if not, branch
		cmpi.b	#$C0,d1		; is obColType $C0 or higher?
		beq.w	React_Special	; if yes, branch
		tst.b	d1		; is obColType $80-$BF?
		bmi.w	React_ChkHurt	; if yes, branch

; obColType is $40-$7F (powerups)

		move.b	obColType(a1),d0
		andi.b	#$3F,d0
		cmpi.b	#6,d0		; is collision type $46 ?
		beq.s	React_Monitor	; if yes, branch
		cmpi.w	#90,$30(a0)	; is Sonic invincible?
		bhs.w	@invincible	; if yes, branch
		addq.b	#2,obRoutine(a1) ; advance the object's routine counter

	@invincible:
		rts
; ===========================================================================

; Touch_Monitor:
React_Monitor:
		tst.w	obVelY(a0)	; is Sonic moving upwards?
		bpl.s	@movingdown	; if not, branch

		move.w	obY(a0),d0
		subi.w	#$10,d0
		cmp.w	obY(a1),d0
		blo.s	@donothing
		neg.w	obVelY(a0)	; reverse Sonic's vertical speed
		move.w	#-$180,obVelY(a1)
		tst.b	ob2ndRout(a1)
		bne.s	@donothing
		addq.b	#4,ob2ndRout(a1) ; advance the monitor's routine counter
		rts
; ===========================================================================

@movingdown:
		cmpi.b	#id_Roll,obAnim(a0) ; is Sonic rolling/jumping?
		bne.s	@donothing
		neg.w	obVelY(a0)	; reverse Sonic's y-motion
		addq.b	#2,obRoutine(a1) ; advance the monitor's routine counter

	@donothing:
		rts
; ===========================================================================

; Touch_Enemy:
React_Enemy:
		tst.b	(v_invinc).w	; is Sonic invincible?
		bne.s	@donthurtsonic	; if yes, branch
		cmpi.b	#id_Roll,obAnim(a0) ; is Sonic rolling/jumping?
		bne.w	React_ChkHurt	; if not, branch

	@donthurtsonic:
		tst.b	obColProp(a1)
		beq.s	@breakenemy

		neg.w	obVelX(a0)	; repel Sonic
		neg.w	obVelY(a0)
		asr	obVelX(a0)
		asr	obVelY(a0)
		move.b	#0,obColType(a1)
		subq.b	#1,obColProp(a1)
		bne.s	@flagnotclear
		bset	#7,obStatus(a1)

	@flagnotclear:
		rts
; ===========================================================================

@breakenemy:
		bset	#7,obStatus(a1)
		moveq	#0,d0
		move.w	(v_itembonus).w,d0
		addq.w	#2,(v_itembonus).w ; add 2 to item bonus counter
		cmpi.w	#6,d0
		blo.s	@bonusokay
		moveq	#6,d0		; max bonus is lvl6

	@bonusokay:
		move.w	d0,$3E(a1)
		move.w	@points(pc,d0.w),d0
		cmpi.w	#$20,(v_itembonus).w ; have 16 enemies been destroyed?
		blo.s	@lessthan16	; if not, branch
		move.w	#1000,d0	; fix bonus to 10000
		move.w	#$A,$3E(a1)

	@lessthan16:
		bsr.w	AddPoints
		move.b	#id_ExplosionItem,0(a1) ; change object to explosion
		move.b	#0,obRoutine(a1)
		tst.w	obVelY(a0)
		bmi.s	@bouncedown
		move.w	obY(a0),d0
		cmp.w	obY(a1),d0
		bhs.s	@bounceup
		neg.w	obVelY(a0)
		rts
; ===========================================================================

	@bouncedown:
		addi.w	#$100,obVelY(a0)
		rts

	@bounceup:
		subi.w	#$100,obVelY(a0)
		rts

@points:	dc.w 10, 20, 50, 100	; points awarded div 10

; ===========================================================================

React_Caterkiller:
		bset	#7,obStatus(a1)

; Touch_ChkHurt:
React_ChkHurt:
		tst.b	(v_invinc).w	; is Sonic invincible?
		beq.s	@notinvincible	; if not, branch

	@isflashing:
		moveq	#-1,d0
		rts
; ===========================================================================

	; Touch_Hurt:
	@notinvincible:
		nop
		tst.w	$30(a0)		; is Sonic flashing?
		bne.s	@isflashing	; if yes, branch
		movea.l	a1,a2

; End of function ReactToItem
; continue straight to HurtSonic

; ---------------------------------------------------------------------------
; Hurting Sonic subroutine
; ---------------------------------------------------------------------------

HurtSonic:
		tst.b	(v_shield).w	; does Sonic have a shield?
		bne.s	@hasshield	; if yes, branch
		tst.w	(v_rings).w	; does Sonic have any rings?
		beq.w	@norings	; if not, branch

		jsr	(FindFreeObj).l
		bne.s	@hasshield
		move.b	#id_RingLoss,0(a1) ; load bouncing multi rings object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)

	@hasshield:
		move.b	#0,(v_shield).w	; remove shield
		move.b	#4,obRoutine(a0)
		bsr.w	Sonic_ResetOnFloor
		bset	#1,obStatus(a0)
		move.w	#-$400,obVelY(a0) ; make Sonic bounce away from the object
		move.w	#-$200,obVelX(a0)
		btst	#6,obStatus(a0)	; is Sonic underwater?
		beq.s	@isdry		; if not, branch

		move.w	#-$200,obVelY(a0) ; slower bounce
		move.w	#-$100,obVelX(a0)

	@isdry:
		move.w	obX(a0),d0
		cmp.w	obX(a2),d0
		blo.s	@isleft		; if Sonic is left of the object, branch
		neg.w	obVelX(a0)	; if Sonic is right of the object, reverse

	@isleft:
		move.w	#0,obInertia(a0)
		move.b	#id_Hurt,obAnim(a0)
		move.w	#120,$30(a0)	; set temp invincible time to 2 seconds
		move.w	#sfx_Death,d0	; load normal damage sound
		cmpi.b	#id_Spikes,(a2)	; was damage caused by spikes?
		bne.s	@sound		; if not, branch
		cmpi.b	#id_Harpoon,(a2) ; was damage caused by LZ harpoon?
		bne.s	@sound		; if not, branch
		move.w	#sfx_HitSpikes,d0 ; load spikes damage sound

	@sound:
		jsr	(PlaySound_Special).l
		moveq	#-1,d0
		rts
; ===========================================================================

@norings:
		tst.w	(f_debugmode).w	; is debug mode cheat on?
		bne.w	@hasshield	; if yes, branch

; ---------------------------------------------------------------------------
; Subroutine to kill Sonic
; ---------------------------------------------------------------------------

KillSonic:
		tst.w	(v_debuguse).w	; is debug mode active?
		bne.s	@dontdie	; if yes, branch
		move.b	#0,(v_invinc).w	; remove invincibility
		move.b	#6,obRoutine(a0)
		bsr.w	Sonic_ResetOnFloor
		bset	#1,obStatus(a0)
		move.w	#-$700,obVelY(a0)
		move.w	#0,obVelX(a0)
		move.w	#0,obInertia(a0)
		move.w	obY(a0),$38(a0)
		move.b	#id_Death,obAnim(a0)
		bset	#7,obGfx(a0)
		move.w	#sfx_Death,d0	; play normal death sound
		cmpi.b	#id_Spikes,(a2)	; check if you were killed by spikes
		bne.s	@sound
		move.w	#sfx_HitSpikes,d0 ; play spikes death sound

	@sound:
		jsr	(PlaySound_Special).l

	@dontdie:
		moveq	#-1,d0
		rts
; End of function KillSonic

React_Special:
		move.b	obColType(a1),d1
		andi.b	#$3F,d1
		cmpi.b	#$B,d1		; is collision type $CB ?
		beq.s	@caterkiller	; if yes, branch
		cmpi.b	#$C,d1		; is collision type $CC ?
		beq.s	@yadrin		; if yes, branch
		cmpi.b	#$17,d1		; is collision type $D7 ?
		beq.s	@D7orE1		; if yes, branch
		cmpi.b	#$21,d1		; is collision type $E1 ?
		beq.s	@D7orE1		; if yes, branch
		rts
; ===========================================================================

@caterkiller:
		bra.w	React_Caterkiller
; ===========================================================================

@yadrin:
		sub.w	d0,d5
		cmpi.w	#8,d5
		bhs.s	@normalenemy
		move.w	obX(a1),d0
		subq.w	#4,d0
		btst	#0,obStatus(a1)
		beq.s	@noflip
		subi.w	#$10,d0

	@noflip:
		sub.w	d2,d0
		bhs.s	@loc_1B13C
		addi.w	#$18,d0
		blo.s	@loc_1B140
		bra.s	@normalenemy
; ===========================================================================

	@loc_1B13C:
		cmp.w	d4,d0
		bhi.s	@normalenemy

	@loc_1B140:
		bra.w	React_ChkHurt
; ===========================================================================

	@normalenemy:
		bra.w	React_Enemy
; ===========================================================================

@D7orE1:
		addq.b	#1,obColProp(a1)
		rts
; End of function React_Special

; ---------------------------------------------------------------------------
; Subroutine to show the special stage layout
; ---------------------------------------------------------------------------

SS_ShowLayout:
		bsr.w	SS_AniWallsRings
		bsr.w	SS_AniItems
		move.w	d5,-(sp)
		lea	($FFFF8000).w,a1
		move.b	(v_ssangle).w,d0
		andi.b	#$FC,d0
		jsr	(CalcSine).l
		move.w	d0,d4
		move.w	d1,d5
		muls.w	#$18,d4
		muls.w	#$18,d5
		moveq	#0,d2
		move.w	(v_screenposx).w,d2
		divu.w	#$18,d2
		swap	d2
		neg.w	d2
		addi.w	#-$B4,d2
		moveq	#0,d3
		move.w	(v_screenposy).w,d3
		divu.w	#$18,d3
		swap	d3
		neg.w	d3
		addi.w	#-$B4,d3
		move.w	#$F,d7

loc_1B19E:
		movem.w	d0-d2,-(sp)
		movem.w	d0-d1,-(sp)
		neg.w	d0
		muls.w	d2,d1
		muls.w	d3,d0
		move.l	d0,d6
		add.l	d1,d6
		movem.w	(sp)+,d0-d1
		muls.w	d2,d0
		muls.w	d3,d1
		add.l	d0,d1
		move.l	d6,d2
		move.w	#$F,d6

loc_1B1C0:
		move.l	d2,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		move.l	d1,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		add.l	d5,d2
		add.l	d4,d1
		dbf	d6,loc_1B1C0

		movem.w	(sp)+,d0-d2
		addi.w	#$18,d3
		dbf	d7,loc_1B19E

		move.w	(sp)+,d5
		lea	(v_256x256).l,a0
		moveq	#0,d0
		move.w	(v_screenposy).w,d0
		divu.w	#$18,d0
		mulu.w	#$80,d0
		adda.l	d0,a0
		moveq	#0,d0
		move.w	(v_screenposx).w,d0
		divu.w	#$18,d0
		adda.w	d0,a0
		lea	($FFFF8000).w,a4
		move.w	#$F,d7

loc_1B20C:
		move.w	#$F,d6

loc_1B210:
		moveq	#0,d0
		move.b	(a0)+,d0
		beq.s	loc_1B268
		cmpi.b	#$4E,d0
		bhi.s	loc_1B268
		move.w	(a4),d3
		addi.w	#$120,d3
		cmpi.w	#$70,d3
		blo.s	loc_1B268
		cmpi.w	#$1D0,d3
		bhs.s	loc_1B268
		move.w	2(a4),d2
		addi.w	#$F0,d2
		cmpi.w	#$70,d2
		blo.s	loc_1B268
		cmpi.w	#$170,d2
		bhs.s	loc_1B268
		lea	($FF4000).l,a5
		lsl.w	#3,d0
		lea	(a5,d0.w),a5
		movea.l	(a5)+,a1
		move.w	(a5)+,d1
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		movea.w	(a5)+,a3
		moveq	#0,d1
		move.b	(a1)+,d1
		subq.b	#1,d1
		bmi.s	loc_1B268
		jsr	(BuildSpr_Normal).l

loc_1B268:
		addq.w	#4,a4
		dbf	d6,loc_1B210

		lea	$70(a0),a0
		dbf	d7,loc_1B20C

		move.b	d5,(v_spritecount).w
		cmpi.b	#$50,d5
		beq.s	loc_1B288
		move.l	#0,(a2)
		rts
; ===========================================================================

loc_1B288:
		move.b	#0,-5(a2)
		rts
; End of function SS_ShowLayout

; ---------------------------------------------------------------------------
; Subroutine to animate	walls and rings	in the special stage
; ---------------------------------------------------------------------------

SS_AniWallsRings:
		lea	($FF400C).l,a1
		moveq	#0,d0
		move.b	(v_ssangle).w,d0
		lsr.b	#2,d0
		andi.w	#$F,d0
		moveq	#$23,d1

loc_1B2A4:
		move.w	d0,(a1)
		addq.w	#8,a1
		dbf	d1,loc_1B2A4

		lea	($FF4005).l,a1
		subq.b	#1,(v_ani1_time).w
		bpl.s	loc_1B2C8
		move.b	#7,(v_ani1_time).w
		addq.b	#1,(v_ani1_frame).w
		andi.b	#3,(v_ani1_frame).w

loc_1B2C8:
		move.b	(v_ani1_frame).w,$1D0(a1)
		subq.b	#1,(v_ani2_time).w
		bpl.s	loc_1B2E4
		move.b	#7,(v_ani2_time).w
		addq.b	#1,(v_ani2_frame).w
		andi.b	#1,(v_ani2_frame).w

loc_1B2E4:
		move.b	(v_ani2_frame).w,d0
		move.b	d0,$138(a1)
		move.b	d0,$160(a1)
		move.b	d0,$148(a1)
		move.b	d0,$150(a1)
		move.b	d0,$1D8(a1)
		move.b	d0,$1E0(a1)
		move.b	d0,$1E8(a1)
		move.b	d0,$1F0(a1)
		move.b	d0,$1F8(a1)
		move.b	d0,$200(a1)
		subq.b	#1,(v_ani3_time).w
		bpl.s	loc_1B326
		move.b	#4,(v_ani3_time).w
		addq.b	#1,(v_ani3_frame).w
		andi.b	#3,(v_ani3_frame).w

loc_1B326:
		move.b	(v_ani3_frame).w,d0
		move.b	d0,$168(a1)
		move.b	d0,$170(a1)
		move.b	d0,$178(a1)
		move.b	d0,$180(a1)
		subq.b	#1,(v_ani0_time).w
		bpl.s	loc_1B350
		move.b	#7,(v_ani0_time).w
		subq.b	#1,(v_ani0_frame).w
		andi.b	#7,(v_ani0_frame).w

loc_1B350:
		lea	($FF4016).l,a1
		lea	(SS_WaRiVramSet).l,a0
		moveq	#0,d0
		move.b	(v_ani0_frame).w,d0
		add.w	d0,d0
		lea	(a0,d0.w),a0
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),$20(a1)
		move.w	$A(a0),$28(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		rts
; End of function SS_AniWallsRings

; ===========================================================================
SS_WaRiVramSet:	dc.w $142, $6142, $142,	$142, $142, $142, $142,	$6142
		dc.w $142, $6142, $142,	$142, $142, $142, $142,	$6142
		dc.w $2142, $142, $2142, $2142,	$2142, $2142, $2142, $142
		dc.w $2142, $142, $2142, $2142,	$2142, $2142, $2142, $142
		dc.w $4142, $2142, $4142, $4142, $4142,	$4142, $4142, $2142
		dc.w $4142, $2142, $4142, $4142, $4142,	$4142, $4142, $2142
		dc.w $6142, $4142, $6142, $6142, $6142,	$6142, $6142, $4142
		dc.w $6142, $4142, $6142, $6142, $6142,	$6142, $6142, $4142
; ---------------------------------------------------------------------------
; Subroutine to remove items when you collect them in the special stage
; ---------------------------------------------------------------------------

SS_RemoveCollectedItem:
		lea	($FF4400).l,a2
		move.w	#$1F,d0

loc_1B4C4:
		tst.b	(a2)
		beq.s	locret_1B4CE
		addq.w	#8,a2
		dbf	d0,loc_1B4C4

locret_1B4CE:
		rts
; End of function SS_RemoveCollectedItem

; ---------------------------------------------------------------------------
; Subroutine to animate	special	stage items when you touch them
; ---------------------------------------------------------------------------

SS_AniItems:
		lea	($FF4400).l,a0
		move.w	#$1F,d7

loc_1B4DA:
		moveq	#0,d0
		move.b	(a0),d0
		beq.s	loc_1B4E8
		lsl.w	#2,d0
		movea.l	SS_AniIndex-4(pc,d0.w),a1
		jsr	(a1)

loc_1B4E8:
		addq.w	#8,a0

loc_1B4EA:
		dbf	d7,loc_1B4DA

		rts
; End of function SS_AniItems

; ===========================================================================
SS_AniIndex:	dc.l SS_AniRingSparks
		dc.l SS_AniBumper
		dc.l SS_Ani1Up
		dc.l SS_AniReverse
		dc.l SS_AniEmeraldSparks
		dc.l SS_AniGlassBlock
; ===========================================================================

SS_AniRingSparks:
		subq.b	#1,2(a0)
		bpl.s	locret_1B530
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniRingData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B530
		clr.l	(a0)
		clr.l	4(a0)

locret_1B530:
		rts
; ===========================================================================
SS_AniRingData:	dc.b $42, $43, $44, $45, 0, 0
; ===========================================================================

SS_AniBumper:
		subq.b	#1,2(a0)
		bpl.s	locret_1B566
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniBumpData(pc,d0.w),d0
		bne.s	loc_1B564
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#$25,(a1)
		rts
; ===========================================================================

loc_1B564:
		move.b	d0,(a1)

locret_1B566:
		rts
; ===========================================================================
SS_AniBumpData:	dc.b $32, $33, $32, $33, 0, 0
; ===========================================================================

SS_Ani1Up:
		subq.b	#1,2(a0)
		bpl.s	locret_1B596
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_Ani1UpData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B596
		clr.l	(a0)
		clr.l	4(a0)

locret_1B596:
		rts
; ===========================================================================
SS_Ani1UpData:	dc.b $46, $47, $48, $49, 0, 0
; ===========================================================================

SS_AniReverse:
		subq.b	#1,2(a0)
		bpl.s	locret_1B5CC
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniRevData(pc,d0.w),d0
		bne.s	loc_1B5CA
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#$2B,(a1)
		rts
; ===========================================================================

loc_1B5CA:
		move.b	d0,(a1)

locret_1B5CC:
		rts
; ===========================================================================
SS_AniRevData:	dc.b $2B, $31, $2B, $31, 0, 0
; ===========================================================================

SS_AniEmeraldSparks:
		subq.b	#1,2(a0)
		bpl.s	locret_1B60C
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniEmerData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B60C
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#4,(v_player+obRoutine).w
		move.w	#sfx_SSGoal,d0
		jsr	(PlaySound_Special).l	; play special stage GOAL sound

locret_1B60C:
		rts
; ===========================================================================
SS_AniEmerData:	dc.b $46, $47, $48, $49, 0, 0
; ===========================================================================

SS_AniGlassBlock:
		subq.b	#1,2(a0)
		bpl.s	locret_1B640
		move.b	#1,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniGlassData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.s	locret_1B640
		move.b	4(a0),(a1)
		clr.l	(a0)
		clr.l	4(a0)

locret_1B640:
		rts
; ===========================================================================
SS_AniGlassData:dc.b $4B, $4C, $4D, $4E, $4B, $4C, $4D,	$4E, 0,	0

; ---------------------------------------------------------------------------
; Special stage layout pointers
; ---------------------------------------------------------------------------
SS_LayoutIndex:
		dc.l SS_1
		dc.l SS_2
		dc.l SS_3
		dc.l SS_4
		dc.l SS_5
		dc.l SS_6
		even

; ---------------------------------------------------------------------------
; Special stage start locations
; ---------------------------------------------------------------------------
SS_StartLoc:
		incbin	"startpos\ss1.bin"
		incbin	"startpos\ss2.bin"
		incbin	"startpos\ss3.bin"
		incbin	"startpos\ss4.bin"
		incbin	"startpos\ss5.bin"
		incbin	"startpos\ss6.bin"
		even

; ---------------------------------------------------------------------------
; Subroutine to load special stage layout
; ---------------------------------------------------------------------------

SS_Load:
		moveq	#0,d0
		move.b	(v_lastspecial).w,d0 ; load number of last special stage entered
		addq.b	#1,(v_lastspecial).w
		cmpi.b	#6,(v_lastspecial).w
		blo.s	SS_ChkEmldNum
		move.b	#0,(v_lastspecial).w ; reset if higher than 6

SS_ChkEmldNum:
		cmpi.b	#6,(v_emeralds).w ; do you have all emeralds?
		beq.s	SS_LoadData	; if yes, branch
		moveq	#0,d1
		move.b	(v_emeralds).w,d1
		subq.b	#1,d1
		blo.s	SS_LoadData
		lea	(v_emldlist).w,a3 ; check which emeralds you have

SS_ChkEmldLoop:
		cmp.b	(a3,d1.w),d0
		bne.s	SS_ChkEmldRepeat
		bra.s	SS_Load
; ===========================================================================

SS_ChkEmldRepeat:
		dbf	d1,SS_ChkEmldLoop

SS_LoadData:
		lsl.w	#2,d0
		lea	SS_StartLoc(pc,d0.w),a1
		move.w	(a1)+,(v_player+obX).w
		move.w	(a1)+,(v_player+obY).w
		movea.l	SS_LayoutIndex(pc,d0.w),a0
		lea	($FF4000).l,a1
		move.w	#0,d0
		jsr	(EniDec).l
		lea	(v_256x256).l,a1
		move.w	#$FFF,d0

SS_ClrRAM3:
		clr.l	(a1)+
		dbf	d0,SS_ClrRAM3

		lea	($FF1020).l,a1
		lea	($FF4000).l,a0
		moveq	#$3F,d1

loc_1B6F6:
		moveq	#$3F,d2

loc_1B6F8:
		move.b	(a0)+,(a1)+
		dbf	d2,loc_1B6F8

		lea	$40(a1),a1
		dbf	d1,loc_1B6F6

		lea	($FF4008).l,a1
		lea	(SS_MapIndex).l,a0
		moveq	#$4D,d1

loc_1B714:
		move.l	(a0)+,(a1)+
		move.w	#0,(a1)+
		move.b	-4(a0),-1(a1)
		move.w	(a0)+,(a1)+
		dbf	d1,loc_1B714

		lea	($FF4400).l,a1
		move.w	#$3F,d1

loc_1B730:

		clr.l	(a1)+
		dbf	d1,loc_1B730

		rts
; End of function SS_Load

; ===========================================================================

; ---------------------------------------------------------------------------
; Special stage mappings and VRAM pointers
; ---------------------------------------------------------------------------
SS_MapIndex:
	dc.l Map_SSWalls	; address of mappings
	dc.w $142		; VRAM setting
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $2142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $4142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_SSWalls
	dc.w $6142
	dc.l Map_Bump
	dc.w $23B
	dc.l Map_SS_R
	dc.w $570
	dc.l Map_SS_R
	dc.w $251
	dc.l Map_SS_R
	dc.w $370
	dc.l Map_SS_Up
	dc.w $263
	dc.l Map_SS_Down
	dc.w $263
	dc.l Map_SS_R
	dc.w $22F0
	dc.l Map_SS_Glass
	dc.w $470
	dc.l Map_SS_Glass
	dc.w $5F0
	dc.l Map_SS_Glass
	dc.w $65F0
	dc.l Map_SS_Glass
	dc.w $25F0
	dc.l Map_SS_Glass
	dc.w $45F0
	dc.l Map_SS_R
	dc.w $2F0
	dc.l Map_Bump+$1000000	; add frame no. * $1000000
	dc.w $23B
	dc.l Map_Bump+$2000000
	dc.w $23B
	dc.l Map_SS_R
	dc.w $797
	dc.l Map_SS_R
	dc.w $7A0
	dc.l Map_SS_R
	dc.w $7A9
	dc.l Map_SS_R
	dc.w $797
	dc.l Map_SS_R
	dc.w $7A0
	dc.l Map_SS_R
	dc.w $7A9
	dc.l Map_Ring
	dc.w $27B2
	dc.l Map_SS_Chaos3
	dc.w $770
	dc.l Map_SS_Chaos3
	dc.w $2770
	dc.l Map_SS_Chaos3
	dc.w $4770
	dc.l Map_SS_Chaos3
	dc.w $6770
	dc.l Map_SS_Chaos1
	dc.w $770
	dc.l Map_SS_Chaos2
	dc.w $770
	dc.l Map_SS_R
	dc.w $4F0
	dc.l Map_Ring+$4000000
	dc.w $27B2
	dc.l Map_Ring+$5000000
	dc.w $27B2
	dc.l Map_Ring+$6000000
	dc.w $27B2
	dc.l Map_Ring+$7000000
	dc.w $27B2
	dc.l Map_SS_Glass
	dc.w $23F0
	dc.l Map_SS_Glass+$1000000
	dc.w $23F0
	dc.l Map_SS_Glass+$2000000
	dc.w $23F0
	dc.l Map_SS_Glass+$3000000
	dc.w $23F0
	dc.l Map_SS_R+$2000000
	dc.w $4F0
	dc.l Map_SS_Glass
	dc.w $5F0
	dc.l Map_SS_Glass
	dc.w $65F0
	dc.l Map_SS_Glass
	dc.w $25F0
	dc.l Map_SS_Glass
	dc.w $45F0

Map_SS_R:	include	"_maps\SS R Block.asm"
Map_SS_Glass:	include	"_maps\SS Glass Block.asm"
Map_SS_Up:	include	"_maps\SS UP Block.asm"
Map_SS_Down:	include	"_maps\SS DOWN Block.asm"
		include	"_maps\SS Chaos Emeralds.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 09 - Sonic (special stage)
; ---------------------------------------------------------------------------

; Obj09:
SonicSpecial:
		tst.w	(v_debuguse).w	; is debug mode being used?
		beq.s	Obj09_Normal	; if not, branch
		bsr.w	SS_FixCamera
		bra.w	DebugMode
; ===========================================================================

Obj09_Normal:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Obj09_Index(pc,d0.w),d1
		jmp	Obj09_Index(pc,d1.w)
; ===========================================================================
Obj09_Index:	dc.w Obj09_Main-Obj09_Index
		dc.w Obj09_ChkDebug-Obj09_Index
		dc.w Obj09_ExitStage-Obj09_Index
		dc.w Obj09_Exit2-Obj09_Index
; ===========================================================================

Obj09_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$E,obHeight(a0)
		move.b	#7,obWidth(a0)
		move.l	#Map_Sonic,obMap(a0)
		move.w	#$780,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#0,obPriority(a0)
		move.b	#id_Roll,obAnim(a0)
		bset	#2,obStatus(a0)
		bset	#1,obStatus(a0)

Obj09_ChkDebug:	; Routine 2
		tst.w	(f_debugmode).w	; is debug mode cheat enabled?
		beq.s	Obj09_NoDebug	; if not, branch
		btst	#bitB,(v_jpadpress1).w ; is button B pressed?
		beq.s	Obj09_NoDebug	; if not, branch
		move.w	#1,(v_debuguse).w ; change Sonic into a ring

Obj09_NoDebug:
		move.b	#0,$30(a0)
		moveq	#0,d0
		move.b	obStatus(a0),d0
		andi.w	#2,d0
		move.w	Obj09_Modes(pc,d0.w),d1
		jsr	Obj09_Modes(pc,d1.w)
		jsr	(Sonic_LoadGfx).l
		jmp	(DisplaySprite).l
; ===========================================================================
Obj09_Modes:	dc.w Obj09_OnWall-Obj09_Modes
		dc.w Obj09_InAir-Obj09_Modes
; ===========================================================================

Obj09_OnWall:
		bsr.w	Obj09_Jump
		bsr.w	Obj09_Move
		bsr.w	Obj09_Fall
		bra.s	Obj09_Display
; ===========================================================================

Obj09_InAir:
		bsr.w	Obj09_Move
		bsr.w	Obj09_Fall

Obj09_Display:
		bsr.w	Obj09_ChkItems
		bsr.w	Obj09_ChkItems2
		jsr	(SpeedToPos).l
		bsr.w	SS_FixCamera
		move.w	(v_ssangle).w,d0
		add.w	(v_ssrotate).w,d0
		move.w	d0,(v_ssangle).w
		jsr	(Sonic_Animate).l
		rts

Obj09_Move:
		btst	#bitL,(v_jpadhold2).w ; is left being pressed?
		beq.s	Obj09_ChkRight	; if not, branch
		bsr.w	Obj09_MoveLeft

Obj09_ChkRight:
		btst	#bitR,(v_jpadhold2).w ; is right being pressed?
		beq.s	loc_1BA78	; if not, branch
		bsr.w	Obj09_MoveRight

loc_1BA78:
		move.b	(v_jpadhold2).w,d0
		andi.b	#btnL+btnR,d0
		bne.s	loc_1BAA8
		move.w	obInertia(a0),d0
		beq.s	loc_1BAA8
		bmi.s	loc_1BA9A
		subi.w	#$C,d0
		bhs.s	loc_1BA94
		move.w	#0,d0

loc_1BA94:
		move.w	d0,obInertia(a0)
		bra.s	loc_1BAA8
; ===========================================================================

loc_1BA9A:
		addi.w	#$C,d0
		bhs.s	loc_1BAA4
		move.w	#0,d0

loc_1BAA4:
		move.w	d0,obInertia(a0)

loc_1BAA8:
		move.b	(v_ssangle).w,d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		neg.b	d0
		jsr	(CalcSine).l
		muls.w	obInertia(a0),d1
		add.l	d1,obX(a0)
		muls.w	obInertia(a0),d0
		add.l	d0,obY(a0)
		movem.l	d0-d1,-(sp)
		move.l	obY(a0),d2
		move.l	obX(a0),d3
		bsr.w	sub_1BCE8
		beq.s	loc_1BAF2
		movem.l	(sp)+,d0-d1
		sub.l	d1,obX(a0)
		sub.l	d0,obY(a0)
		move.w	#0,obInertia(a0)
		rts
; ===========================================================================

loc_1BAF2:
		movem.l	(sp)+,d0-d1
		rts
; End of function Obj09_Move

Obj09_MoveLeft:
		bset	#0,obStatus(a0)
		move.w	obInertia(a0),d0
		beq.s	loc_1BB06
		bpl.s	loc_1BB1A

loc_1BB06:
		subi.w	#$C,d0
		cmpi.w	#-$800,d0
		bgt.s	loc_1BB14
		move.w	#-$800,d0

loc_1BB14:
		move.w	d0,obInertia(a0)
		rts
; ===========================================================================

loc_1BB1A:
		subi.w	#$40,d0
		bhs.s	loc_1BB22
		nop

loc_1BB22:
		move.w	d0,obInertia(a0)
		rts
; End of function Obj09_MoveLeft

Obj09_MoveRight:
		bclr	#0,obStatus(a0)
		move.w	obInertia(a0),d0
		bmi.s	loc_1BB48
		addi.w	#$C,d0
		cmpi.w	#$800,d0
		blt.s	loc_1BB42
		move.w	#$800,d0

loc_1BB42:
		move.w	d0,obInertia(a0)
		bra.s	locret_1BB54
; ===========================================================================

loc_1BB48:
		addi.w	#$40,d0
		bhs.s	loc_1BB50
		nop

loc_1BB50:
		move.w	d0,obInertia(a0)

locret_1BB54:
		rts
; End of function Obj09_MoveRight

Obj09_Jump:
		move.b	(v_jpadpress2).w,d0
		andi.b	#btnABC,d0	; is A, B or C pressed?
		beq.s	Obj09_NoJump	; if not, branch
		move.b	(v_ssangle).w,d0
		andi.b	#$FC,d0
		neg.b	d0
		subi.b	#$40,d0
		jsr	(CalcSine).l
		muls.w	#$680,d1
		asr.l	#8,d1
		move.w	d1,obVelX(a0)
		muls.w	#$680,d0
		asr.l	#8,d0
		move.w	d0,obVelY(a0)
		bset	#1,obStatus(a0)
		move.w	#sfx_Jump,d0
		jsr	(PlaySound_Special).l	; play jumping sound

Obj09_NoJump:
		rts
; End of function Obj09_Jump

; ---------------------------------------------------------------------------
; Subroutine to fix the	camera on Sonic's position (special stage)
; ---------------------------------------------------------------------------

SS_FixCamera:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		move.w	(v_screenposx).w,d0
		subi.w	#$A0,d3
		blo.s	loc_1BBCE
		sub.w	d3,d0
		sub.w	d0,(v_screenposx).w

loc_1BBCE:
		move.w	(v_screenposy).w,d0
		subi.w	#$70,d2
		blo.s	locret_1BBDE
		sub.w	d2,d0
		sub.w	d0,(v_screenposy).w

locret_1BBDE:
		rts
; End of function SS_FixCamera

; ===========================================================================

Obj09_ExitStage:
		addi.w	#$40,(v_ssrotate).w
		cmpi.w	#$1800,(v_ssrotate).w
		bne.s	loc_1BBF4
		move.b	#id_Level,(v_gamemode).w

loc_1BBF4:
		cmpi.w	#$3000,(v_ssrotate).w
		blt.s	loc_1BC12
		move.w	#0,(v_ssrotate).w
		move.w	#$4000,(v_ssangle).w
		addq.b	#2,obRoutine(a0)
		move.w	#$3C,$38(a0)

loc_1BC12:
		move.w	(v_ssangle).w,d0
		add.w	(v_ssrotate).w,d0
		move.w	d0,(v_ssangle).w
		jsr	(Sonic_Animate).l
		jsr	(Sonic_LoadGfx).l
		bsr.w	SS_FixCamera
		jmp	(DisplaySprite).l
; ===========================================================================

Obj09_Exit2:
		subq.w	#1,$38(a0)
		bne.s	loc_1BC40
		move.b	#id_Level,(v_gamemode).w

loc_1BC40:
		jsr	(Sonic_Animate).l
		jsr	(Sonic_LoadGfx).l
		bsr.w	SS_FixCamera
		jmp	(DisplaySprite).l

Obj09_Fall:
		move.l	obY(a0),d2
		move.l	obX(a0),d3
		move.b	(v_ssangle).w,d0
		andi.b	#$FC,d0
		jsr	(CalcSine).l
		move.w	obVelX(a0),d4
		ext.l	d4
		asl.l	#8,d4
		muls.w	#$2A,d0
		add.l	d4,d0
		move.w	obVelY(a0),d4
		ext.l	d4
		asl.l	#8,d4
		muls.w	#$2A,d1
		add.l	d4,d1
		add.l	d0,d3
		bsr.w	sub_1BCE8
		beq.s	loc_1BCB0
		sub.l	d0,d3
		moveq	#0,d0
		move.w	d0,obVelX(a0)
		bclr	#1,obStatus(a0)
		add.l	d1,d2
		bsr.w	sub_1BCE8
		beq.s	loc_1BCC6
		sub.l	d1,d2
		moveq	#0,d1
		move.w	d1,obVelY(a0)
		rts
; ===========================================================================

loc_1BCB0:
		add.l	d1,d2
		bsr.w	sub_1BCE8
		beq.s	loc_1BCD4
		sub.l	d1,d2
		moveq	#0,d1
		move.w	d1,obVelY(a0)
		bclr	#1,obStatus(a0)

loc_1BCC6:
		asr.l	#8,d0
		asr.l	#8,d1
		move.w	d0,obVelX(a0)
		move.w	d1,obVelY(a0)
		rts
; ===========================================================================

loc_1BCD4:
		asr.l	#8,d0
		asr.l	#8,d1
		move.w	d0,obVelX(a0)
		move.w	d1,obVelY(a0)
		bset	#1,obStatus(a0)
		rts
; End of function Obj09_Fall

sub_1BCE8:
		lea	(v_256x256).l,a1
		moveq	#0,d4
		swap	d2
		move.w	d2,d4
		swap	d2
		addi.w	#$44,d4
		divu.w	#$18,d4
		mulu.w	#$80,d4
		adda.l	d4,a1
		moveq	#0,d4
		swap	d3
		move.w	d3,d4
		swap	d3
		addi.w	#$14,d4
		divu.w	#$18,d4
		adda.w	d4,a1
		moveq	#0,d5
		move.b	(a1)+,d4
		bsr.s	sub_1BD30
		move.b	(a1)+,d4
		bsr.s	sub_1BD30
		adda.w	#$7E,a1
		move.b	(a1)+,d4
		bsr.s	sub_1BD30
		move.b	(a1)+,d4
		bsr.s	sub_1BD30
		tst.b	d5
		rts
; End of function sub_1BCE8

sub_1BD30:
		beq.s	locret_1BD44
		cmpi.b	#$28,d4
		beq.s	locret_1BD44
		cmpi.b	#$3A,d4
		blo.s	loc_1BD46
		cmpi.b	#$4B,d4
		bhs.s	loc_1BD46

locret_1BD44:
		rts
; ===========================================================================

loc_1BD46:
		move.b	d4,$30(a0)
		move.l	a1,$32(a0)
		moveq	#-1,d5
		rts
; End of function sub_1BD30

Obj09_ChkItems:
		lea	(v_256x256).l,a1
		moveq	#0,d4
		move.w	obY(a0),d4
		addi.w	#$50,d4
		divu.w	#$18,d4
		mulu.w	#$80,d4
		adda.l	d4,a1
		moveq	#0,d4
		move.w	obX(a0),d4
		addi.w	#$20,d4
		divu.w	#$18,d4
		adda.w	d4,a1
		move.b	(a1),d4
		bne.s	Obj09_ChkCont
		tst.b	$3A(a0)
		bne.w	Obj09_MakeGhostSolid
		moveq	#0,d4
		rts
; ===========================================================================

Obj09_ChkCont:
		cmpi.b	#$3A,d4		; is the item a ring?
		bne.s	Obj09_Chk1Up
		bsr.w	SS_RemoveCollectedItem
		bne.s	Obj09_GetCont
		move.b	#1,(a2)
		move.l	a1,4(a2)

Obj09_GetCont:
		jsr	(CollectRing).l
		cmpi.w	#50,(v_rings).w	; check if you have 50 rings
		blo.s	Obj09_NoCont
		bset	#0,(v_lifecount).w
		bne.s	Obj09_NoCont
		addq.b	#1,(v_continues).w ; add 1 to number of continues
		move.w	#sfx_Continue,d0
		jsr	(PlaySound).l	; play extra continue sound

Obj09_NoCont:
		moveq	#0,d4
		rts
; ===========================================================================

Obj09_Chk1Up:
		cmpi.b	#$28,d4		; is the item an extra life?
		bne.s	Obj09_ChkEmer
		bsr.w	SS_RemoveCollectedItem
		bne.s	Obj09_Get1Up
		move.b	#3,(a2)
		move.l	a1,4(a2)

Obj09_Get1Up:
		addq.b	#1,(v_lives).w	; add 1 to number of lives
		addq.b	#1,(f_lifecount).w ; update the lives counter
		move.w	#bgm_ExtraLife,d0
		jsr	(PlaySound).l	; play extra life music
		moveq	#0,d4
		rts
; ===========================================================================

Obj09_ChkEmer:
		cmpi.b	#$3B,d4		; is the item an emerald?
		blo.s	Obj09_ChkGhost
		cmpi.b	#$40,d4
		bhi.s	Obj09_ChkGhost
		bsr.w	SS_RemoveCollectedItem
		bne.s	Obj09_GetEmer
		move.b	#5,(a2)
		move.l	a1,4(a2)

Obj09_GetEmer:
		cmpi.b	#6,(v_emeralds).w ; do you have all the emeralds?
		beq.s	Obj09_NoEmer	; if yes, branch
		subi.b	#$3B,d4
		moveq	#0,d0
		move.b	(v_emeralds).w,d0
		lea	(v_emldlist).w,a2
		move.b	d4,(a2,d0.w)
		addq.b	#1,(v_emeralds).w ; add 1 to number of emeralds

Obj09_NoEmer:
		move.w	#bgm_Emerald,d0
		jsr	(PlaySound_Special).l ; play emerald music
		moveq	#0,d4
		rts
; ===========================================================================

Obj09_ChkGhost:
		cmpi.b	#$41,d4		; is the item a ghost block?
		bne.s	Obj09_ChkGhostTag
		move.b	#1,$3A(a0)	; mark the ghost block as "passed"

Obj09_ChkGhostTag:
		cmpi.b	#$4A,d4		; is the item a switch for ghost blocks?
		bne.s	Obj09_NoGhost
		cmpi.b	#1,$3A(a0)	; have the ghost blocks been passed?
		bne.s	Obj09_NoGhost	; if not, branch
		move.b	#2,$3A(a0)	; mark the ghost blocks as "solid"

Obj09_NoGhost:
		moveq	#-1,d4
		rts
; ===========================================================================

Obj09_MakeGhostSolid:
		cmpi.b	#2,$3A(a0)	; is the ghost marked as "solid"?
		bne.s	Obj09_GhostNotSolid ; if not, branch
		lea	($FF1020).l,a1
		moveq	#$3F,d1

Obj09_GhostLoop2:
		moveq	#$3F,d2

Obj09_GhostLoop:
		cmpi.b	#$41,(a1)	; is the item a ghost block?
		bne.s	Obj09_NoReplace	; if not, branch
		move.b	#$2C,(a1)	; replace ghost block with a solid block

Obj09_NoReplace:
		addq.w	#1,a1
		dbf	d2,Obj09_GhostLoop
		lea	$40(a1),a1
		dbf	d1,Obj09_GhostLoop2

Obj09_GhostNotSolid:
		clr.b	$3A(a0)
		moveq	#0,d4
		rts
; End of function Obj09_ChkItems

Obj09_ChkItems2:
		move.b	$30(a0),d0
		bne.s	Obj09_ChkBumper
		subq.b	#1,$36(a0)
		bpl.s	loc_1BEA0
		move.b	#0,$36(a0)

loc_1BEA0:
		subq.b	#1,$37(a0)
		bpl.s	locret_1BEAC
		move.b	#0,$37(a0)

locret_1BEAC:
		rts
; ===========================================================================

Obj09_ChkBumper:
		cmpi.b	#$25,d0		; is the item a bumper?
		bne.s	Obj09_GOAL
		move.l	$32(a0),d1
		subi.l	#$FF0001,d1
		move.w	d1,d2
		andi.w	#$7F,d1
		mulu.w	#$18,d1
		subi.w	#$14,d1
		lsr.w	#7,d2
		andi.w	#$7F,d2
		mulu.w	#$18,d2
		subi.w	#$44,d2
		sub.w	obX(a0),d1
		sub.w	obY(a0),d2
		jsr	(CalcAngle).l
		jsr	(CalcSine).l
		muls.w	#-$700,d1
		asr.l	#8,d1
		move.w	d1,obVelX(a0)
		muls.w	#-$700,d0
		asr.l	#8,d0
		move.w	d0,obVelY(a0)
		bset	#1,obStatus(a0)
		bsr.w	SS_RemoveCollectedItem
		bne.s	Obj09_BumpSnd
		move.b	#2,(a2)
		move.l	$32(a0),d0
		subq.l	#1,d0
		move.l	d0,4(a2)

Obj09_BumpSnd:
		move.w	#sfx_Bumper,d0
		jmp	(PlaySound_Special).l	; play bumper sound
; ===========================================================================

Obj09_GOAL:
		cmpi.b	#$27,d0		; is the item a "GOAL"?
		bne.s	Obj09_UPblock
		addq.b	#2,obRoutine(a0) ; run routine "Obj09_ExitStage"
		move.w	#sfx_SSGoal,d0
		jsr	(PlaySound_Special).l	; play "GOAL" sound
		rts
; ===========================================================================

Obj09_UPblock:
		cmpi.b	#$29,d0		; is the item an "UP" block?
		bne.s	Obj09_DOWNblock
		tst.b	$36(a0)
		bne.w	Obj09_NoGlass
		move.b	#$1E,$36(a0)
		btst	#6,($FFFFF783).w
		beq.s	Obj09_UPsnd
		asl	(v_ssrotate).w	; increase stage rotation speed
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.b	#$2A,(a1)	; change item to a "DOWN" block

Obj09_UPsnd:
		move.w	#sfx_SSItem,d0
		jmp	(PlaySound_Special).l	; play up/down sound
; ===========================================================================

Obj09_DOWNblock:
		cmpi.b	#$2A,d0		; is the item a "DOWN" block?
		bne.s	Obj09_Rblock
		tst.b	$36(a0)
		bne.w	Obj09_NoGlass
		move.b	#$1E,$36(a0)
		btst	#6,(v_ssrotate+1).w
		bne.s	Obj09_DOWNsnd
		asr	(v_ssrotate).w	; reduce stage rotation speed
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.b	#$29,(a1)	; change item to an "UP" block

Obj09_DOWNsnd:
		move.w	#sfx_SSItem,d0
		jmp	(PlaySound_Special).l	; play up/down sound
; ===========================================================================

Obj09_Rblock:
		cmpi.b	#$2B,d0		; is the item an "R" block?
		bne.s	Obj09_ChkGlass
		tst.b	$37(a0)
		bne.w	Obj09_NoGlass
		move.b	#$1E,$37(a0)
		bsr.w	SS_RemoveCollectedItem
		bne.s	Obj09_RevStage
		move.b	#4,(a2)
		move.l	$32(a0),d0
		subq.l	#1,d0
		move.l	d0,4(a2)

Obj09_RevStage:
		neg.w	(v_ssrotate).w	; reverse stage rotation
		move.w	#sfx_SSItem,d0
		jmp	(PlaySound_Special).l	; play sound
; ===========================================================================

Obj09_ChkGlass:
		cmpi.b	#$2D,d0		; is the item a glass block?
		beq.s	Obj09_Glass	; if yes, branch
		cmpi.b	#$2E,d0
		beq.s	Obj09_Glass
		cmpi.b	#$2F,d0
		beq.s	Obj09_Glass
		cmpi.b	#$30,d0
		bne.s	Obj09_NoGlass	; if not, branch

Obj09_Glass:
		bsr.w	SS_RemoveCollectedItem
		bne.s	Obj09_GlassSnd
		move.b	#6,(a2)
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.l	a1,4(a2)
		move.b	(a1),d0
		addq.b	#1,d0		; change glass type when touched
		cmpi.b	#$30,d0
		bls.s	Obj09_GlassUpdate ; if glass is still there, branch
		clr.b	d0		; remove the glass block when it's destroyed

Obj09_GlassUpdate:
		move.b	d0,4(a2)	; update the stage layout

Obj09_GlassSnd:
		move.w	#sfx_SSGlass,d0
		jmp	(PlaySound_Special).l	; play glass block sound
; ===========================================================================

Obj09_NoGlass:
		rts
; End of function Obj09_ChkItems2

; ---------------------------------------------------------------------------
; Object 10 - blank
; ---------------------------------------------------------------------------

Obj10:
		rts

; ---------------------------------------------------------------------------
; Subroutine to animate	level graphics
; ---------------------------------------------------------------------------

; AniArt_Load:
AnimateLevelGfx:
		tst.w	(f_pause).w	; is the game paused?
		bne.s	@ispaused	; if yes, branch
		lea	(vdp_data_port).l,a6
		bsr.w	AniArt_GiantRing
		moveq	#0,d0
		move.b	(v_zone).w,d0
		add.w	d0,d0
		move.w	AniArt_Index(pc,d0.w),d0
		jmp	AniArt_Index(pc,d0.w)

	@ispaused:
		rts

; ===========================================================================
AniArt_Index:	dc.w AniArt_GHZ-AniArt_Index, AniArt_none-AniArt_Index
		dc.w AniArt_MZ-AniArt_Index, AniArt_none-AniArt_Index
		dc.w AniArt_none-AniArt_Index, AniArt_SBZ-AniArt_Index
		dc.w AniArt_Ending-AniArt_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Green Hill
; ---------------------------------------------------------------------------

AniArt_GHZ:

AniArt_GHZ_Waterfall:

@size:		equ 8	; number of tiles per frame

		subq.b	#1,(v_lani0_time).w ; decrement timer
		bpl.s	AniArt_GHZ_Bigflower ; branch if not 0

		move.b	#5,(v_lani0_time).w ; time to display each frame
		lea	(Art_GhzWater).l,a1 ; load waterfall patterns
		move.b	(v_lani0_frame).w,d0
		addq.b	#1,(v_lani0_frame).w ; increment frame counter
		andi.w	#1,d0		; there are only 2 frames
		beq.s	@isframe0	; branch if frame 0
		lea	@size*$20(a1),a1 ; use graphics for frame 1

	@isframe0:
		locVRAM	$6F00		; VRAM address
		move.w	#@size-1,d1	; number of 8x8 tiles
		bra.w	LoadTiles
; ===========================================================================

AniArt_GHZ_Bigflower:

@size:		equ 16	; number of tiles per frame

		subq.b	#1,(v_lani1_time).w
		bpl.s	AniArt_GHZ_Smallflower

		move.b	#$F,(v_lani1_time).w
		lea	(Art_GhzFlower1).l,a1 ; load big flower	patterns
		move.b	(v_lani1_frame).w,d0
		addq.b	#1,(v_lani1_frame).w
		andi.w	#1,d0
		beq.s	@isframe0
		lea	@size*$20(a1),a1

	@isframe0:
		locVRAM	$6B80
		move.w	#@size-1,d1
		bra.w	LoadTiles
; ===========================================================================

AniArt_GHZ_Smallflower:

@size:		equ 12	; number of tiles per frame

		subq.b	#1,(v_lani2_time).w
		bpl.s	@end

		move.b	#7,(v_lani2_time).w
		move.b	(v_lani2_frame).w,d0
		addq.b	#1,(v_lani2_frame).w ; increment frame counter
		andi.w	#3,d0		; there are 4 frames
		move.b	@sequence(pc,d0.w),d0
		btst	#0,d0		; is frame 0 or 2? (actual frame, not frame counter)
		bne.s	@isframe1	; if not, branch
		move.b	#$7F,(v_lani2_time).w ; set longer duration for frames 0 and 2

	@isframe1:
		lsl.w	#7,d0		; multiply frame num by $80
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0		; multiply that by 3 (i.e. frame num times 12 * $20)
		locVRAM	$6D80
		lea	(Art_GhzFlower2).l,a1 ; load small flower patterns
		lea	(a1,d0.w),a1	; jump to appropriate tile
		move.w	#@size-1,d1
		bsr.w	LoadTiles

@end:
		rts

@sequence:	dc.b 0,	1, 2, 1
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Marble
; ---------------------------------------------------------------------------

AniArt_MZ:

AniArt_MZ_Lava:

@size:		equ 8	; number of tiles per frame

		subq.b	#1,(v_lani0_time).w ; decrement timer
		bpl.s	AniArt_MZ_Magma	; branch if not 0

		move.b	#$13,(v_lani0_time).w ; time to display each frame
		lea	(Art_MzLava1).l,a1 ; load lava surface patterns
		moveq	#0,d0
		move.b	(v_lani0_frame).w,d0
		addq.b	#1,d0		; increment frame counter
		cmpi.b	#3,d0		; there are 3 frames
		bne.s	@frame01or2	; branch if frame 0, 1 or 2
		moveq	#0,d0

	@frame01or2:
		move.b	d0,(v_lani0_frame).w
		mulu.w	#@size*$20,d0
		adda.w	d0,a1		; jump to appropriate tile
		locVRAM	$5C40
		move.w	#@size-1,d1
		bsr.w	LoadTiles

AniArt_MZ_Magma:
		subq.b	#1,(v_lani1_time).w ; decrement timer
		bpl.s	AniArt_MZ_Torch	; branch if not 0

		move.b	#1,(v_lani1_time).w ; time between each gfx change
		moveq	#0,d0
		move.b	(v_lani0_frame).w,d0 ; get surface lava frame number
		lea	(Art_MzLava2).l,a4 ; load magma gfx
		ror.w	#7,d0		; multiply frame num by $200
		adda.w	d0,a4		; jump to appropriate tile
		locVRAM	$5A40
		moveq	#0,d3
		move.b	(v_lani1_frame).w,d3
		addq.b	#1,(v_lani1_frame).w ; increment frame counter (unused)
		move.b	(v_oscillate+$A).w,d3 ; get oscillating value
		move.w	#3,d2

	@loop:
		move.w	d3,d0
		add.w	d0,d0
		andi.w	#$1E,d0
		lea	(AniArt_MZextra).l,a3
		move.w	(a3,d0.w),d0
		lea	(a3,d0.w),a3
		movea.l	a4,a1
		move.w	#$1F,d1
		jsr	(a3)
		addq.w	#4,d3
		dbf	d2,@loop
		rts
; ===========================================================================

AniArt_MZ_Torch:

@size:		equ 6	; number of tiles per frame

		subq.b	#1,(v_lani2_time).w ; decrement timer
		bpl.w	@end		; branch if not 0

		move.b	#7,(v_lani2_time).w ; time to display each frame
		lea	(Art_MzTorch).l,a1 ; load torch patterns
		moveq	#0,d0
		move.b	(v_lani3_frame).w,d0
		addq.b	#1,(v_lani3_frame).w ; increment frame counter
		andi.b	#3,(v_lani3_frame).w ; there are 3 frames
		mulu.w	#@size*$20,d0
		adda.w	d0,a1		; jump to appropriate tile
		locVRAM	$5E40
		move.w	#@size-1,d1
		bra.w	LoadTiles

@end:
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Scrap Brain
; ---------------------------------------------------------------------------

AniArt_SBZ:

@size:		equ 12	; number of tiles per frame

		tst.b	(v_lani2_frame).w
		beq.s	@smokepuff	; branch if counter hits 0

		subq.b	#1,(v_lani2_frame).w ; decrement counter
		bra.s	@chk_smokepuff2
; ===========================================================================

@smokepuff:
		subq.b	#1,(v_lani0_time).w ; decrement timer
		bpl.s	@chk_smokepuff2 ; branch if not 0

		move.b	#7,(v_lani0_time).w ; time to display each frame
		lea	(Art_SbzSmoke).l,a1 ; load smoke patterns
		locVRAM	$8900
		move.b	(v_lani0_frame).w,d0
		addq.b	#1,(v_lani0_frame).w ; increment frame counter
		andi.w	#7,d0
		beq.s	@untilnextpuff	; branch if frame 0
		subq.w	#1,d0
		mulu.w	#@size*$20,d0
		lea	(a1,d0.w),a1
		move.w	#@size-1,d1
		bra.w	LoadTiles
; ===========================================================================

@untilnextpuff:
		move.b	#180,(v_lani2_frame).w ; time between smoke puffs (3 seconds)

@clearsky:
		move.w	#(@size/2)-1,d1
		bsr.w	LoadTiles
		lea	(Art_SbzSmoke).l,a1
		move.w	#(@size/2)-1,d1
		bra.w	LoadTiles	; load blank tiles for no smoke puff
; ===========================================================================

@chk_smokepuff2:
		tst.b	(v_lani2_time).w
		beq.s	@smokepuff2	; branch if counter hits 0

		subq.b	#1,(v_lani2_time).w ; decrement counter
		bra.s	@end
; ===========================================================================

@smokepuff2:
		subq.b	#1,(v_lani1_time).w ; decrement timer
		bpl.s	@end		; branch if not 0

		move.b	#7,(v_lani1_time).w ; time to display each frame
		lea	(Art_SbzSmoke).l,a1 ; load smoke patterns
		locVRAM	$8A80
		move.b	(v_lani1_frame).w,d0
		addq.b	#1,(v_lani1_frame).w ; increment frame counter
		andi.w	#7,d0
		beq.s	@untilnextpuff2	; branch if frame 0
		subq.w	#1,d0
		mulu.w	#@size*$20,d0
		lea	(a1,d0.w),a1
		move.w	#@size-1,d1
		bra.w	LoadTiles
; ===========================================================================

@untilnextpuff2:
		move.b	#120,(v_lani2_time).w ; time between smoke puffs (2 seconds)
		bra.s	@clearsky
; ===========================================================================

@end:
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - ending sequence
; ---------------------------------------------------------------------------

AniArt_Ending:

AniArt_Ending_BigFlower:

@size:		equ 16	; number of tiles per frame

		subq.b	#1,(v_lani1_time).w ; decrement timer
		bpl.s	AniArt_Ending_SmallFlower ; branch if not 0

		move.b	#7,(v_lani1_time).w
		lea	(Art_GhzFlower1).l,a1 ; load big flower	patterns
		lea	($FFFF9400).w,a2 ; load 2nd big flower from RAM
		move.b	(v_lani1_frame).w,d0
		addq.b	#1,(v_lani1_frame).w ; increment frame counter
		andi.w	#1,d0		; only 2 frames
		beq.s	@isframe0	; branch if frame 0
		lea	@size*$20(a1),a1
		lea	@size*$20(a2),a2

	@isframe0:
		locVRAM	$6B80
		move.w	#@size-1,d1
		bsr.w	LoadTiles
		movea.l	a2,a1
		locVRAM	$7200
		move.w	#@size-1,d1
		bra.w	LoadTiles
; ===========================================================================

AniArt_Ending_SmallFlower:

@size:		equ 12	; number of tiles per frame

		subq.b	#1,(v_lani2_time).w ; decrement timer
		bpl.s	AniArt_Ending_Flower3 ; branch if not 0

		move.b	#7,(v_lani2_time).w
		move.b	(v_lani2_frame).w,d0
		addq.b	#1,(v_lani2_frame).w ; increment frame counter
		andi.w	#7,d0		; max 8 frames
		move.b	@sequence(pc,d0.w),d0 ; get actual frame num from sequence data
		lsl.w	#7,d0		; multiply by $80
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0		; multiply by 3
		locVRAM	$6D80
		lea	(Art_GhzFlower2).l,a1 ; load small flower patterns
		lea	(a1,d0.w),a1	; jump to appropriate tile
		move.w	#@size-1,d1
		bra.w	LoadTiles
; ===========================================================================
@sequence:	dc.b 0,	0, 0, 1, 2, 2, 2, 1
; ===========================================================================

AniArt_Ending_Flower3:

@size:		equ 16	; number of tiles per frame

		subq.b	#1,(v_lani4_time).w ; decrement timer
		bpl.s	AniArt_Ending_Flower4 ; branch if not 0

		move.b	#$E,(v_lani4_time).w
		move.b	(v_lani4_frame).w,d0
		addq.b	#1,(v_lani4_frame).w ; increment frame counter
		andi.w	#3,d0		; max 4 frames
		move.b	AniArt_Ending_Flower3_sequence(pc,d0.w),d0 ; get actual frame num from sequence data
		lsl.w	#8,d0		; multiply by $100
		add.w	d0,d0		; multiply by 2
		locVRAM	$7000
		lea	($FFFF9800).w,a1 ; load special	flower patterns	(from RAM)
		lea	(a1,d0.w),a1	; jump to appropriate tile
		move.w	#@size-1,d1
		bra.w	LoadTiles
; ===========================================================================
AniArt_Ending_Flower3_sequence:	dc.b 0,	1, 2, 1
; ===========================================================================

AniArt_Ending_Flower4:

@size:		equ 16	; number of tiles per frame

		subq.b	#1,(v_lani5_time).w ; decrement timer
		bpl.s	@end		; branch if not 0

		move.b	#$B,(v_lani5_time).w
		move.b	(v_lani5_frame).w,d0
		addq.b	#1,(v_lani5_frame).w ; increment frame counter
		andi.w	#3,d0
		move.b	AniArt_Ending_Flower3_sequence(pc,d0.w),d0 ; get actual frame num from sequence data
		lsl.w	#8,d0		; multiply by $100
		add.w	d0,d0		; multiply by 2
		locVRAM	$6800
		lea	($FFFF9E00).w,a1 ; load special	flower patterns	(from RAM)
		lea	(a1,d0.w),a1	; jump to appropriate tile
		move.w	#@size-1,d1
		bra.w	LoadTiles
; ===========================================================================

@end:
		rts
; ===========================================================================

AniArt_none:
		rts

; ---------------------------------------------------------------------------
; Subroutine to transfer graphics to VRAM

; input:
; a1 = source address
; a6 = vdp_data_port ($C00000)
; d1 = number of tiles to load (minus one)
; ---------------------------------------------------------------------------

LoadTiles:
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		dbf	d1,LoadTiles
		rts
; End of function LoadTiles

; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - more Marble Zone
; ---------------------------------------------------------------------------
AniArt_MZextra:	dc.w loc_1C3EE-AniArt_MZextra, loc_1C3FA-AniArt_MZextra
		dc.w loc_1C410-AniArt_MZextra, loc_1C41E-AniArt_MZextra
		dc.w loc_1C434-AniArt_MZextra, loc_1C442-AniArt_MZextra
		dc.w loc_1C458-AniArt_MZextra, loc_1C466-AniArt_MZextra
		dc.w loc_1C47C-AniArt_MZextra, loc_1C48A-AniArt_MZextra
		dc.w loc_1C4A0-AniArt_MZextra, loc_1C4AE-AniArt_MZextra
		dc.w loc_1C4C4-AniArt_MZextra, loc_1C4D2-AniArt_MZextra
		dc.w loc_1C4E8-AniArt_MZextra, loc_1C4FA-AniArt_MZextra
; ===========================================================================

loc_1C3EE:
		move.l	(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C3EE
		rts
; ===========================================================================

loc_1C3FA:
		move.l	2(a1),d0
		move.b	1(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C3FA
		rts
; ===========================================================================

loc_1C410:
		move.l	2(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C410
		rts
; ===========================================================================

loc_1C41E:
		move.l	4(a1),d0
		move.b	3(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C41E
		rts
; ===========================================================================

loc_1C434:
		move.l	4(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C434
		rts
; ===========================================================================

loc_1C442:
		move.l	6(a1),d0
		move.b	5(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C442
		rts
; ===========================================================================

loc_1C458:
		move.l	6(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C458
		rts
; ===========================================================================

loc_1C466:
		move.l	8(a1),d0
		move.b	7(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C466
		rts
; ===========================================================================

loc_1C47C:
		move.l	8(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C47C
		rts
; ===========================================================================

loc_1C48A:
		move.l	$A(a1),d0
		move.b	9(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C48A
		rts
; ===========================================================================

loc_1C4A0:
		move.l	$A(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C4A0
		rts
; ===========================================================================

loc_1C4AE:
		move.l	$C(a1),d0
		move.b	$B(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C4AE
		rts
; ===========================================================================

loc_1C4C4:
		move.l	$C(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C4C4
		rts
; ===========================================================================

loc_1C4D2:
		move.l	$C(a1),d0
		rol.l	#8,d0
		move.b	0(a1),d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C4D2
		rts
; ===========================================================================

loc_1C4E8:
		move.w	$E(a1),(a6)
		move.w	0(a1),(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C4E8
		rts
; ===========================================================================

loc_1C4FA:
		move.l	0(a1),d0
		move.b	$F(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbf	d1,loc_1C4FA
		rts

; ---------------------------------------------------------------------------
; Animated pattern routine - giant ring
; ---------------------------------------------------------------------------

AniArt_GiantRing:

@size:		equ 14

		tst.w	(v_gfxbigring).w	; Is there any of the art left to load?
		bne.s	@loadTiles		; If so, get to work
		rts
; ===========================================================================
; loc_1C518:
@loadTiles:
		subi.w	#@size*$20,(v_gfxbigring).w	; Count-down the 14 tiles we're going to load now
		lea	(Art_BigRing).l,a1 ; load giant ring patterns
		moveq	#0,d0
		move.w	(v_gfxbigring).w,d0
		lea	(a1,d0.w),a1
		; Turn VRAM address into VDP command
		addi.w	#$8000,d0
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		; Send VDP command (write to VRAM at address contained in v_gfxbigring)
		move.l	d0,4(a6)

		move.w	#@size-1,d1
		bra.w	LoadTiles

; End of function AniArt_GiantRing

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 21 - SCORE, TIME, RINGS
; ---------------------------------------------------------------------------

; Obj21:
HUD:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	HUD_Index(pc,d0.w),d1
		jmp	HUD_Index(pc,d1.w)
; ===========================================================================
HUD_Index:	dc.w HUD_Main-HUD_Index
		dc.w HUD_Flash-HUD_Index
; ===========================================================================

HUD_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.w	#$90,obX(a0)
		move.w	#$108,obScreenY(a0)
		move.l	#Map_HUD,obMap(a0)
		move.w	#$6CA,obGfx(a0)
		move.b	#0,obRender(a0)
		move.b	#0,obPriority(a0)

HUD_Flash:	; Routine 2
		tst.w	(v_rings).w	; do you have any rings?
		beq.s	@norings	; if not, branch
		clr.b	obFrame(a0)	; make all counters yellow
		jmp	(DisplaySprite).l
; ===========================================================================

@norings:
		moveq	#0,d0
		btst	#3,(v_framebyte).w
		bne.s	@display
		addq.w	#1,d0		; make ring counter flash red
		cmpi.b	#9,(v_timemin).w ; have 9 minutes elapsed?
		bne.s	@display	; if not, branch
		addq.w	#2,d0		; make time counter flash red

	@display:
		move.b	d0,obFrame(a0)
		jmp	DisplaySprite

Map_HUD:	include	"_maps\HUD.asm"

; ---------------------------------------------------------------------------
; Add points subroutine
; ---------------------------------------------------------------------------

AddPoints:
		move.b	#1,(f_scorecount).w ; set score counter to update

		lea     (v_score).w,a3
		add.l   d0,(a3)
		move.l  #999999,d1
		cmp.l   (a3),d1 ; is score below 999999?
		bhi.s   @belowmax ; if yes, branch
		move.l  d1,(a3) ; reset score to 999999
	@belowmax:
		move.l  (a3),d0
		cmp.l   (v_scorelife).w,d0 ; has Sonic got 50000+ points?
		blo.s   @noextralife ; if not, branch

		addi.l  #5000,(v_scorelife).w ; increase requirement by 50000
		tst.b   (v_megadrive).w
		bmi.s   @noextralife ; branch if Mega Drive is Japanese
		addq.b  #1,(v_lives).w ; give extra life
		addq.b  #1,(f_lifecount).w
		move.w	#bgm_ExtraLife,d0
		jmp	(PlaySound).l

@noextralife:
		rts
; End of function AddPoints

; ---------------------------------------------------------------------------
; Subroutine to update the HUD
; ---------------------------------------------------------------------------

; HudUpdate:
HUD_Update:
		tst.w	(f_debugmode).w	; is debug mode on?
		bne.w	HudDebug	; if yes, branch
		tst.b	(f_scorecount).w ; does the score need updating?
		beq.s	@chkrings	; if not, branch

		clr.b	(f_scorecount).w
		locVRAM	$DC80,d0	; set VRAM address
		move.l	(v_score).w,d1	; load score
		bsr.w	Hud_Score

	@chkrings:
		tst.b	(f_ringcount).w	; does the ring counter	need updating?
		beq.s	@chktime	; if not, branch
		bpl.s	@notzero
		bsr.w	Hud_LoadZero	; reset rings to 0 if Sonic is hit

	@notzero:
		clr.b	(f_ringcount).w
		locVRAM	$DF40,d0	; set VRAM address
		moveq	#0,d1
		move.w	(v_rings).w,d1	; load number of rings
		bsr.w	Hud_Rings

	@chktime:
		tst.b	(f_timecount).w	; does the time need updating?
		beq.s	@chklives	; if not, branch
		tst.w	(f_pause).w	; is the game paused?
		bne.s	@chklives	; if yes, branch
		lea	(v_time).w,a1
		cmpi.l	#(9*$10000)+(59*$100)+59,(a1)+ ; is the time 9:59:59?
		beq.s	TimeOver	; if yes, branch

		addq.b	#1,-(a1)	; increment 1/60s counter
		cmpi.b	#60,(a1)	; check if passed 60
		blo.s	@chklives
		move.b	#0,(a1)
		addq.b	#1,-(a1)	; increment second counter
		cmpi.b	#60,(a1)	; check if passed 60
		blo.s	@updatetime
		move.b	#0,(a1)
		addq.b	#1,-(a1)	; increment minute counter
		cmpi.b	#9,(a1)		; check if passed 9
		blo.s	@updatetime
		move.b	#9,(a1)		; keep as 9

	@updatetime:
		locVRAM	$DE40,d0
		moveq	#0,d1
		move.b	(v_timemin).w,d1 ; load minutes
		bsr.w	Hud_Mins
		locVRAM	$DEC0,d0
		moveq	#0,d1
		move.b	(v_timesec).w,d1 ; load seconds
		bsr.w	Hud_Secs

	@chklives:
		tst.b	(f_lifecount).w ; does the lives counter need updating?
		beq.s	@chkbonus	; if not, branch
		clr.b	(f_lifecount).w
		bsr.w	Hud_Lives

	@chkbonus:
		tst.b	(f_endactbonus).w ; do time/ring bonus counters need updating?
		beq.s	@finish		; if not, branch
		clr.b	(f_endactbonus).w
		locVRAM	$AE00
		moveq	#0,d1
		move.w	(v_timebonus).w,d1 ; load time bonus
		bsr.w	Hud_TimeRingBonus
		moveq	#0,d1
		move.w	(v_ringbonus).w,d1 ; load ring bonus
		bsr.w	Hud_TimeRingBonus

	@finish:
		rts
; ===========================================================================

TimeOver:
		clr.b	(f_timecount).w
		lea	(v_player).w,a0
		movea.l	a0,a2
		bsr.w	KillSonic
		move.b	#1,(f_timeover).w
		rts
; ===========================================================================

HudDebug:
		bsr.w	HudDb_XY
		tst.b	(f_ringcount).w	; does the ring counter	need updating?
		beq.s	@objcounter	; if not, branch
		bpl.s	@notzero
		bsr.w	Hud_LoadZero	; reset rings to 0 if Sonic is hit

	@notzero:
		clr.b	(f_ringcount).w
		locVRAM	$DF40,d0	; set VRAM address
		moveq	#0,d1
		move.w	(v_rings).w,d1	; load number of rings
		bsr.w	Hud_Rings

	@objcounter:
		locVRAM	$DEC0,d0	; set VRAM address
		moveq	#0,d1
		move.b	(v_spritecount).w,d1 ; load "number of objects" counter
		bsr.w	Hud_Secs
		tst.b	(f_lifecount).w ; does the lives counter need updating?
		beq.s	@chkbonus	; if not, branch
		clr.b	(f_lifecount).w
		bsr.w	Hud_Lives

	@chkbonus:
		tst.b	(f_endactbonus).w ; does the ring/time bonus counter need updating?
		beq.s	@finish		; if not, branch
		clr.b	(f_endactbonus).w
		locVRAM	$AE00		; set VRAM address
		moveq	#0,d1
		move.w	(v_timebonus).w,d1 ; load time bonus
		bsr.w	Hud_TimeRingBonus
		moveq	#0,d1
		move.w	(v_ringbonus).w,d1 ; load ring bonus
		bsr.w	Hud_TimeRingBonus

	@finish:
		rts
; End of function HUD_Update

; ---------------------------------------------------------------------------
; Subroutine to load "0" on the	HUD
; ---------------------------------------------------------------------------

Hud_LoadZero:
		locVRAM	$DF40
		lea	Hud_TilesZero(pc),a2
		move.w	#2,d2
		bra.s	loc_1C83E
; End of function Hud_LoadZero

; ---------------------------------------------------------------------------
; Subroutine to load uncompressed HUD patterns ("E", "0", colon)
; ---------------------------------------------------------------------------

Hud_Base:
		lea	($C00000).l,a6
		bsr.w	Hud_Lives
		locVRAM	$DC40
		lea	Hud_TilesBase(pc),a2
		move.w	#$E,d2

loc_1C83E:
		lea	Art_Hud(pc),a1

loc_1C842:
		move.w	#$F,d1
		move.b	(a2)+,d0
		bmi.s	loc_1C85E
		ext.w	d0
		lsl.w	#5,d0
		lea	(a1,d0.w),a3

loc_1C852:
		move.l	(a3)+,(a6)
		dbf	d1,loc_1C852

loc_1C858:
		dbf	d2,loc_1C842

		rts
; ===========================================================================

loc_1C85E:
		move.l	#0,(a6)
		dbf	d1,loc_1C85E

		bra.s	loc_1C858
; End of function Hud_Base

; ===========================================================================
Hud_TilesBase:	dc.b $16, $FF, $FF, $FF, $FF, $FF, $FF,	0, 0, $14, 0, 0
Hud_TilesZero:	dc.b $FF, $FF, 0, 0
; ---------------------------------------------------------------------------
; Subroutine to load debug mode	numbers	patterns
; ---------------------------------------------------------------------------

HudDb_XY:
		locVRAM	$DC40		; set VRAM address
		move.w	(v_screenposx).w,d1 ; load camera x-position
		swap	d1
		move.w	(v_player+obX).w,d1 ; load Sonic's x-position
		bsr.s	HudDb_XY2
		move.w	(v_screenposy).w,d1 ; load camera y-position
		swap	d1
		move.w	(v_player+obY).w,d1 ; load Sonic's y-position
; End of function HudDb_XY

HudDb_XY2:
		moveq	#7,d6
		lea	(Art_Text).l,a1

HudDb_XYLoop:
		rol.w	#4,d1
		move.w	d1,d2
		andi.w	#$F,d2
		cmpi.w	#$A,d2
		blo.s	loc_1C8B2
		addq.w	#7,d2

loc_1C8B2:
		lsl.w	#5,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		swap	d1
		dbf	d6,HudDb_XYLoop	; repeat 7 more times

		rts
; End of function HudDb_XY2

; ---------------------------------------------------------------------------
; Subroutine to load rings numbers patterns
; ---------------------------------------------------------------------------

Hud_Rings:
		lea	(Hud_100).l,a2
		moveq	#2,d6
		bra.s	Hud_LoadArt
; End of function Hud_Rings

; ---------------------------------------------------------------------------
; Subroutine to load score numbers patterns
; ---------------------------------------------------------------------------

Hud_Score:
		lea	(Hud_100000).l,a2
		moveq	#5,d6

Hud_LoadArt:
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_ScoreLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C8EC:
		sub.l	d3,d1
		blo.s	loc_1C8F4
		addq.w	#1,d2
		bra.s	loc_1C8EC
; ===========================================================================

loc_1C8F4:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1C8FE
		move.w	#1,d4

loc_1C8FE:
		tst.w	d4
		beq.s	loc_1C92C
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1C92C:
		addi.l	#$400000,d0
		dbf	d6,Hud_ScoreLoop

		rts

; End of function Hud_Score

; ---------------------------------------------------------------------------
; Subroutine to load countdown numbers on the continue screen
; ---------------------------------------------------------------------------

ContScrCounter:
		locVRAM	$DF80
		lea	(vdp_data_port).l,a6
		lea	(Hud_10).l,a2
		moveq	#1,d6
		moveq	#0,d4
		lea	Art_Hud(pc),a1 ; load numbers patterns

ContScr_Loop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C95A:
		sub.l	d3,d1
		blo.s	loc_1C962
		addq.w	#1,d2
		bra.s	loc_1C95A
; ===========================================================================

loc_1C962:
		add.l	d3,d1
		lsl.w	#6,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		dbf	d6,ContScr_Loop	; repeat 1 more time

		rts
; End of function ContScrCounter

; ===========================================================================

; ---------------------------------------------------------------------------
; HUD counter sizes
; ---------------------------------------------------------------------------
Hud_100000:	dc.l 100000
Hud_10000:	dc.l 10000
Hud_1000:	dc.l 1000
Hud_100:	dc.l 100
Hud_10:		dc.l 10
Hud_1:		dc.l 1

; ---------------------------------------------------------------------------
; Subroutine to load time numbers patterns
; ---------------------------------------------------------------------------

Hud_Mins:
		lea	(Hud_1).l,a2
		moveq	#0,d6
		bra.s	loc_1C9BA
; End of function Hud_Mins

Hud_Secs:
		lea	(Hud_10).l,a2
		moveq	#1,d6

loc_1C9BA:
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_TimeLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C9C4:
		sub.l	d3,d1
		blo.s	loc_1C9CC
		addq.w	#1,d2
		bra.s	loc_1C9C4
; ===========================================================================

loc_1C9CC:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1C9D6
		move.w	#1,d4

loc_1C9D6:
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		addi.l	#$400000,d0
		dbf	d6,Hud_TimeLoop

		rts
; End of function Hud_Secs

; ---------------------------------------------------------------------------
; Subroutine to load time/ring bonus numbers patterns
; ---------------------------------------------------------------------------

Hud_TimeRingBonus:
		lea	(Hud_1000).l,a2
		moveq	#3,d6
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_BonusLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1CA1E:
		sub.l	d3,d1
		blo.s	loc_1CA26
		addq.w	#1,d2
		bra.s	loc_1CA1E
; ===========================================================================

loc_1CA26:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1CA30
		move.w	#1,d4

loc_1CA30:
		tst.w	d4
		beq.s	Hud_ClrBonus
		lsl.w	#6,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1CA5A:
		dbf	d6,Hud_BonusLoop ; repeat 3 more times

		rts
; ===========================================================================

Hud_ClrBonus:
		moveq	#$F,d5

Hud_ClrBonusLoop:
		move.l	#0,(a6)
		dbf	d5,Hud_ClrBonusLoop

		bra.s	loc_1CA5A
; End of function Hud_TimeRingBonus

; ---------------------------------------------------------------------------
; Subroutine to load uncompressed lives	counter	patterns
; ---------------------------------------------------------------------------

Hud_Lives:
		locVRAM	$FBA0,d0	; set VRAM address
		moveq	#0,d1
		move.b	(v_lives).w,d1	; load number of lives
		lea	(Hud_10).l,a2
		moveq	#1,d6
		moveq	#0,d4
		lea	Art_LivesNums(pc),a1

Hud_LivesLoop:
		move.l	d0,4(a6)
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1CA90:
		sub.l	d3,d1
		blo.s	loc_1CA98
		addq.w	#1,d2
		bra.s	loc_1CA90
; ===========================================================================

loc_1CA98:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1CAA2
		move.w	#1,d4

loc_1CAA2:
		tst.w	d4
		beq.s	Hud_ClrLives

loc_1CAA6:
		lsl.w	#5,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1CABC:
		addi.l	#$400000,d0
		dbf	d6,Hud_LivesLoop ; repeat 1 more time

		rts
; ===========================================================================

Hud_ClrLives:
		tst.w	d6
		beq.s	loc_1CAA6
		moveq	#7,d5

Hud_ClrLivesLoop:
		move.l	#0,(a6)
		dbf	d5,Hud_ClrLivesLoop
		bra.s	loc_1CABC
; End of function Hud_Lives

Art_Hud:	incbin	"artunc\HUD Numbers.bin" ; 8x16 pixel numbers on HUD
		even
Art_LivesNums:	incbin	"artunc\Lives Counter Numbers.bin" ; 8x8 pixel numbers on lives counter
		even

; ---------------------------------------------------------------------------
; When debug mode is currently in use
; ---------------------------------------------------------------------------

DebugMode:
		moveq	#0,d0
		move.b	(v_debuguse).w,d0
		move.w	Debug_Index(pc,d0.w),d1
		jmp	Debug_Index(pc,d1.w)
; ===========================================================================
Debug_Index:	dc.w Debug_Main-Debug_Index
		dc.w Debug_Action-Debug_Index
; ===========================================================================

Debug_Main:	; Routine 0
		addq.b	#2,(v_debuguse).w
		move.w	(v_limittop2).w,(v_limittopdb).w ; buffer level x-boundary
		move.w	(v_limitbtm1).w,(v_limitbtmdb).w ; buffer level y-boundary
		move.w	#0,(v_limittop2).w
		move.w	#$720,(v_limitbtm1).w
		andi.w	#$7FF,(v_player+obY).w
		andi.w	#$7FF,(v_screenposy).w
		andi.w	#$3FF,(v_bgscreenposy).w
		move.b	#0,obFrame(a0)
		move.b	#id_Walk,obAnim(a0)
		cmpi.b	#id_Special,(v_gamemode).w ; is game mode $10 (special stage)?
		bne.s	@islevel	; if not, branch

		move.w	#0,(v_ssrotate).w ; stop special stage rotating
		move.w	#0,(v_ssangle).w ; make special	stage "upright"
		moveq	#6,d0		; use 6th debug item list
		bra.s	@selectlist
; ===========================================================================

@islevel:
		moveq	#0,d0
		move.b	(v_zone).w,d0

@selectlist:
		lea	(DebugList).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		cmp.b	(v_debugitem).w,d6 ; have you gone past the last item?
		bhi.s	@noreset	; if not, branch
		move.b	#0,(v_debugitem).w ; back to start of list

	@noreset:
		bsr.w	Debug_ShowItem
		move.b	#12,(v_debugxspeed).w
		move.b	#1,(v_debugyspeed).w

Debug_Action:	; Routine 2
		moveq	#6,d0
		cmpi.b	#id_Special,(v_gamemode).w
		beq.s	@isntlevel

		moveq	#0,d0
		move.b	(v_zone).w,d0

	@isntlevel:
		lea	(DebugList).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		bsr.w	Debug_Control
		jmp	(DisplaySprite).l

Debug_Control:
		moveq	#0,d4
		move.w	#1,d1
		move.b	(v_jpadpress1).w,d4
		andi.w	#btnDir,d4	; is up/down/left/right pressed?
		bne.s	@dirpressed	; if yes, branch

		move.b	(v_jpadhold1).w,d0
		andi.w	#btnDir,d0	; is up/down/left/right held?
		bne.s	@dirheld	; if yes, branch

		move.b	#12,(v_debugxspeed).w
		move.b	#15,(v_debugyspeed).w
		bra.w	Debug_ChgItem
; ===========================================================================

@dirheld:
		subq.b	#1,(v_debugxspeed).w
		bne.s	loc_1D01C
		move.b	#1,(v_debugxspeed).w
		addq.b	#1,(v_debugyspeed).w
		bne.s	@dirpressed
		move.b	#-1,(v_debugyspeed).w

@dirpressed:
		move.b	(v_jpadhold1).w,d4

loc_1D01C:
		moveq	#0,d1
		move.b	(v_debugyspeed).w,d1
		addq.w	#1,d1
		swap	d1
		asr.l	#4,d1
		move.l	obY(a0),d2
		move.l	obX(a0),d3
		btst	#bitUp,d4	; is up being pressed?
		beq.s	loc_1D03C	; if not, branch
		sub.l	d1,d2
		bhs.s	loc_1D03C
		moveq	#0,d2

loc_1D03C:
		btst	#bitDn,d4	; is down being pressed?
		beq.s	loc_1D052	; if not, branch
		add.l	d1,d2
		cmpi.l	#$7FF0000,d2
		blo.s	loc_1D052
		move.l	#$7FF0000,d2

loc_1D052:
		btst	#bitL,d4
		beq.s	loc_1D05E
		sub.l	d1,d3
		bhs.s	loc_1D05E
		moveq	#0,d3

loc_1D05E:
		btst	#bitR,d4
		beq.s	loc_1D066
		add.l	d1,d3

loc_1D066:
		move.l	d2,obY(a0)
		move.l	d3,obX(a0)

Debug_ChgItem:
		btst	#bitA,(v_jpadhold1).w ; is button A pressed?
		beq.s	@createitem	; if not, branch
		btst	#bitC,(v_jpadpress1).w ; is button C pressed?
		beq.s	@nextitem	; if not, branch
		subq.b	#1,(v_debugitem).w ; go back 1 item
		bhs.s	@display
		add.b	d6,(v_debugitem).w
		bra.s	@display
; ===========================================================================

@nextitem:
		btst	#bitA,(v_jpadpress1).w ; is button A pressed?
		beq.s	@createitem	; if not, branch
		addq.b	#1,(v_debugitem).w ; go forwards 1 item
		cmp.b	(v_debugitem).w,d6
		bhi.s	@display
		move.b	#0,(v_debugitem).w ; loop back to first item

	@display:
		bra.w	Debug_ShowItem
; ===========================================================================

@createitem:
		btst	#bitC,(v_jpadpress1).w ; is button C pressed?
		beq.s	@backtonormal	; if not, branch
		jsr	(FindFreeObj).l
		bne.s	@backtonormal
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		clr.b	(v_objstate+2).w	; Fix: allows for more than one collectible to be placed
		move.b	4(a0),0(a1)	; create object
		move.b	obRender(a0),obRender(a1)
		move.b	obRender(a0),obStatus(a1)
		andi.b	#$7F,obStatus(a1)
		moveq	#0,d0
		move.b	(v_debugitem).w,d0
		lsl.w	#3,d0
		move.b	4(a2,d0.w),obSubtype(a1)
		rts
; ===========================================================================

@backtonormal:
		btst	#bitB,(v_jpadpress1).w ; is button B pressed?
		beq.s	@stayindebug	; if not, branch
		moveq	#0,d0
		move.w	d0,(v_debuguse).w ; deactivate debug mode
		move.l	#Map_Sonic,(v_player+obMap).w
		move.w	#$780,(v_player+obGfx).w
		move.b	d0,(v_player+obAnim).w
		move.w	d0,obX+2(a0)
		move.w	d0,obY+2(a0)
		move.w	(v_limittopdb).w,(v_limittop2).w ; restore level boundaries
		move.w	(v_limitbtmdb).w,(v_limitbtm1).w
		cmpi.b	#id_Special,(v_gamemode).w ; are you in the special stage?
		bne.s	@stayindebug	; if not, branch

		clr.w	(v_ssangle).w
		move.w	#$40,(v_ssrotate).w ; set new level rotation speed
		move.l	#Map_Sonic,(v_player+obMap).w
		move.w	#$780,(v_player+obGfx).w
		move.b	#id_Roll,(v_player+obAnim).w
		bset	#2,(v_player+obStatus).w
		bset	#1,(v_player+obStatus).w

	@stayindebug:
		rts
; End of function Debug_Control

Debug_ShowItem:
		moveq	#0,d0
		move.b	(v_debugitem).w,d0
		lsl.w	#3,d0
		move.l	(a2,d0.w),obMap(a0) ; load mappings for item
		move.w	6(a2,d0.w),obGfx(a0) ; load VRAM setting for item
		move.b	5(a2,d0.w),obFrame(a0) ; load frame number for item
		rts
; End of function Debug_ShowItem

; ---------------------------------------------------------------------------
; Debug mode item lists
; ---------------------------------------------------------------------------
DebugList:
		dc.w @GHZ-DebugList
		dc.w @LZ-DebugList
		dc.w @MZ-DebugList
		dc.w @SLZ-DebugList
		dc.w @SYZ-DebugList
		dc.w @SBZ-DebugList
		dc.w @Ending-DebugList

dbug:	macro map,object,subtype,frame,vram
		dc.l map+(object<<24)
		dc.b subtype,frame
		dc.w vram
		endm

@GHZ:
		dc.w (@GHZend-@GHZ-2)/8

		; 	mappings	object		subtype	frame	VRAM setting
		dbug 	Map_Ring,	id_Rings,	0,	0,	$27B2
		dbug	Map_Monitor,	id_Monitor,	0,	0,	$680
		dbug	Map_Crab,	id_Crabmeat,	0,	0,	$400
		dbug	Map_Buzz,	id_BuzzBomber,	0,	0,	$444
		dbug	Map_Chop,	id_Chopper,	0,	0,	$47B
		dbug	Map_Spike,	id_Spikes,	0,	0,	$51B
		dbug	Map_Plat_GHZ,	id_BasicPlatform, 0,	0,	$4000
		dbug	Map_PRock,	id_PurpleRock,	0,	0,	$63D0
		dbug	Map_Moto,	id_MotoBug,	0,	0,	$4F0
		dbug	Map_Spring,	id_Springs,	0,	0,	$523
		dbug	Map_Newt,	id_Newtron,	0,	0,	$249B
		dbug	Map_Edge,	id_EdgeWalls,	0,	0,	$434C
		dbug	Map_GBall,	id_Obj19,	0,	0,	$43AA
		dbug	Map_Lamp,	id_Lamppost,	1,	0,	$7A0
		dbug	Map_GRing,	id_GiantRing,	0,	0,	$2400
		dbug	Map_Bonus,	id_HiddenBonus,	1,	1,	$84B6
		@GHZend:

@LZ:
		dc.w (@LZend-@LZ-2)/8

		; 	mappings	object		subtype	frame	VRAM setting
		dbug	Map_Ring,	id_Rings,	0,	0,	$27B2
		dbug	Map_Monitor,	id_Monitor,	0,	0,	$680
		dbug	Map_Spring,	id_Springs,	0,	0,	$523
		dbug	Map_Jaws,	id_Jaws,	8,	0,	$2486
		dbug	Map_Burro,	id_Burrobot,	0,	2,	$84A6
		dbug	Map_Harp,	id_Harpoon,	0,	0,	$3CC
		dbug	Map_Harp,	id_Harpoon,	2,	3,	$3CC
		dbug	Map_Push,	id_PushBlock,	0,	0,	$43DE
		dbug	Map_But,	id_Button,	0,	0,	$513
		dbug	Map_Spike,	id_Spikes,	0,	0,	$51B
		dbug	Map_MBlockLZ,	id_MovingBlock,	4,	0,	$43BC
		dbug	Map_LBlock,	id_LabyrinthBlock, 1,	0,	$43E6
		dbug	Map_LBlock,	id_LabyrinthBlock, $13,	1,	$43E6
		dbug	Map_LBlock,	id_LabyrinthBlock, 5,	0,	$43E6
		dbug	Map_Gar,	id_Gargoyle,	0,	0,	$443E
		dbug	Map_LBlock,	id_LabyrinthBlock, $27,	2,	$43E6
		dbug	Map_LBlock,	id_LabyrinthBlock, $30,	3,	$43E6
		dbug	Map_LConv,	id_LabyrinthConvey, $7F, 0,	$3F6
		dbug	Map_Orb,	id_Orbinaut,	0,	0,	$467
		dbug	Map_Bub,	id_Bubble,	$84,	$13,	$8348
		dbug	Map_WFall,	id_Waterfall,	2,	2,	$C259
		dbug	Map_WFall,	id_Waterfall,	9,	9,	$C259
		dbug	Map_Pole,	id_Pole,	0,	0,	$43DE
		dbug	Map_Flap,	id_FlapDoor,	2,	0,	$4328
		dbug	Map_Lamp,	id_Lamppost,	1,	0,	$7A0
		@LZend:

@MZ:
		dc.w (@MZend-@MZ-2)/8

		; 	mappings	object		subtype	frame	VRAM setting
		dbug	Map_Ring,	id_Rings,	0,	0,	$27B2
		dbug	Map_Monitor,	id_Monitor,	0,	0,	$680
		dbug	Map_Buzz,	id_BuzzBomber,	0,	0,	$444
		dbug	Map_Spike,	id_Spikes,	0,	0,	$51B
		dbug	Map_Spring,	id_Springs,	0,	0,	$523
		dbug	Map_Fire,	id_LavaMaker,	0,	0,	$345
		dbug	Map_Brick,	id_MarbleBrick,	0,	0,	$4000
		dbug	Map_Geyser,	id_GeyserMaker,	0,	0,	$63A8
		dbug	Map_LWall,	id_LavaWall,	0,	0,	$63A8
		dbug	Map_Push,	id_PushBlock,	0,	0,	$42B8
		dbug	Map_Yad,	id_Yadrin,	0,	0,	$247B
		dbug	Map_Smab,	id_SmashBlock,	0,	0,	$42B8
		dbug	Map_MBlock,	id_MovingBlock,	0,	0,	$2B8
		dbug	Map_CFlo,	id_CollapseFloor, 0,	0,	$62B8
		dbug	Map_LTag,	id_LavaTag,	0,	0,	$8680
		dbug	Map_Bas,	id_Basaran,	0,	0,	$4B8
		dbug	Map_Cat,	id_Caterkiller,	0,	0,	$24FF
		dbug	Map_Lamp,	id_Lamppost,	1,	0,	$7A0
		@MZend:

@SLZ:
		dc.w (@SLZend-@SLZ-2)/8

		; 	mappings	object		subtype	frame	VRAM setting
		dbug	Map_Ring,	id_Rings,	0,	0,	$27B2
		dbug	Map_Monitor,	id_Monitor,	0,	0,	$680
		dbug	Map_Elev,	id_Elevator,	0,	0,	$4000
		dbug	Map_CFlo,	id_CollapseFloor, 0,	2,	$44E0
		dbug	Map_Plat_SLZ,	id_BasicPlatform, 0,	0,	$4000
		dbug	Map_Circ,	id_CirclingPlatform, 0,	0,	$4000
		dbug	Map_Stair,	id_Staircase,	0,	0,	$4000
		dbug	Map_Fan,	id_Fan,		0,	0,	$43A0
		dbug	Map_Seesaw,	id_Seesaw,	0,	0,	$374
		dbug	Map_Spring,	id_Springs,	0,	0,	$523
		dbug	Map_Fire,	id_LavaMaker,	0,	0,	$480
		dbug	Map_Scen,	id_Scenery,	0,	0,	$44D8
		dbug	Map_Bomb,	id_Bomb,	0,	0,	$400
		dbug	Map_Orb,	id_Orbinaut,	0,	0,	$2429
		dbug	Map_Lamp,	id_Lamppost,	1,	0,	$7A0
		@SLZend:

@SYZ:
		dc.w (@SYZend-@SYZ-2)/8

		; 	mappings	object		subtype	frame	VRAM setting
		dbug	Map_Ring,	id_Rings,	0,	0,	$27B2
		dbug	Map_Monitor,	id_Monitor,	0,	0,	$680
		dbug	Map_Spike,	id_Spikes,	0,	0,	$51B
		dbug	Map_Spring,	id_Springs,	0,	0,	$523
		dbug	Map_Roll,	id_Roller,	0,	0,	$4B8
		dbug	Map_Light,	id_SpinningLight, 0,	0,	0
		dbug	Map_Bump,	id_Bumper,	0,	0,	$380
		dbug	Map_Crab,	id_Crabmeat,	0,	0,	$400
		dbug	Map_Buzz,	id_BuzzBomber,	0,	0,	$444
		dbug	Map_Yad,	id_Yadrin,	0,	0,	$247B
		dbug	Map_Plat_SYZ,	id_BasicPlatform, 0,	0,	$4000
		dbug	Map_FBlock,	id_FloatingBlock, 0,	0,	$4000
		dbug	Map_But,	id_Button,	0,	0,	$513
		dbug	Map_Cat,	id_Caterkiller,	0,	0,	$24FF
		dbug	Map_Lamp,	id_Lamppost,	1,	0,	$7A0
		@SYZend:

@SBZ:
		dc.w (@SBZend-@SBZ-2)/8

		; 	mappings	object		subtype	frame	VRAM setting
		dbug	Map_Ring,	id_Rings,	0,	0,	$27B2
		dbug	Map_Monitor,	id_Monitor,	0,	0,	$680
		dbug	Map_Bomb,	id_Bomb,	0,	0,	$400
		dbug	Map_Orb,	id_Orbinaut,	0,	0,	$429
		dbug	Map_Cat,	id_Caterkiller,	0,	0,	$22B0
		dbug	Map_BBall,	id_SwingingPlatform, 7,	2,	$4391
		dbug	Map_Disc,	id_RunningDisc,	$E0,	0,	$C344
		dbug	Map_MBlock,	id_MovingBlock,	$28,	2,	$22C0
		dbug	Map_But,	id_Button,	0,	0,	$513
		dbug	Map_Trap,	id_SpinPlatform, 3,	0,	$4492
		dbug	Map_Spin,	id_SpinPlatform, $83,	0,	$4DF
		dbug	Map_Saw,	id_Saws,	2,	0,	$43B5
		dbug	Map_CFlo,	id_CollapseFloor, 0,	0,	$43F5
		dbug	Map_MBlock,	id_MovingBlock,	$39,	3,	$4460
		dbug	Map_Stomp,	id_ScrapStomp,	0,	0,	$22C0
		dbug	Map_ADoor,	id_AutoDoor,	0,	0,	$42E8
		dbug	Map_Stomp,	id_ScrapStomp,	$13,	1,	$22C0
		dbug	Map_Saw,	id_Saws,	1,	0,	$43B5
		dbug	Map_Stomp,	id_ScrapStomp,	$24,	1,	$22C0
		dbug	Map_Saw,	id_Saws,	4,	2,	$43B5
		dbug	Map_Stomp,	id_ScrapStomp,	$34,	1,	$22C0
		dbug	Map_VanP,	id_VanishPlatform, 0,	0,	$44C3
		dbug	Map_Flame,	id_Flamethrower, $64,	0,	$83D9
		dbug	Map_Flame,	id_Flamethrower, $64,	$B,	$83D9
		dbug	Map_Elec,	id_Electro,	4,	0,	$47E
		dbug	Map_Gird,	id_Girder,	0,	0,	$42F0
		dbug	Map_Invis,	id_Invisibarrier, $11,	0,	$8680
		dbug	Map_Hog,	id_BallHog,	4,	0,	$2302
		dbug	Map_Lamp,	id_Lamppost,	1,	0,	$7A0
		@SBZend:

@Ending:
		dc.w (@Endingend-@Ending-2)/8

		; 	mappings	object		subtype	frame	VRAM setting
		dbug	Map_Ring,	id_Rings,	0,	0,	$27B2
		dbug	Map_Ring,	id_Rings,	0,	8,	$27B2
		@Endingend:

		even

; ---------------------------------------------------------------------------
; Level Headers
; ---------------------------------------------------------------------------

LevelHeaders:

lhead:	macro plc1,lvlgfx,plc2,sixteen,twofivesix,music,pal
		dc.l (plc1<<24)+lvlgfx
		dc.l (plc2<<24)+sixteen
		dc.l twofivesix
		dc.b 0, music, pal, pal
		endm

; 1st PLC, level gfx (unused), 2nd PLC, 16x16 data, 256x256 data,
; music (unused), palette (unused), palette

; 	1st PLC				2nd PLC				256x256 data			palette
; 			level gfx*			16x16 data			music*

		lhead	plcid_GHZ,	Nem_GHZ_2nd,	plcid_GHZ2,	Blk16_GHZ,	Blk256_GHZ,	bgm_GHZ,	palid_GHZ	; Green Hill
		lhead	plcid_LZ,	Nem_LZ,		plcid_LZ2,	Blk16_LZ,	Blk256_LZ,	bgm_LZ,		palid_LZ	; Labyrinth
		lhead	plcid_MZ,	Nem_MZ,		plcid_MZ2,	Blk16_MZ,	Blk256_MZ,	bgm_MZ,		palid_MZ	; Marble
		lhead	plcid_SLZ,	Nem_SLZ,	plcid_SLZ2,	Blk16_SLZ,	Blk256_SLZ,	bgm_SLZ,	palid_SLZ	; Star Light
		lhead	plcid_SYZ,	Nem_SYZ,	plcid_SYZ2,	Blk16_SYZ,	Blk256_SYZ,	bgm_SYZ,	palid_SYZ	; Spring Yard
		lhead	plcid_SBZ,	Nem_SBZ,	plcid_SBZ2,	Blk16_SBZ,	Blk256_SBZ,	bgm_SBZ,	palid_SBZ1	; Scrap Brain
		lhead	0,		Nem_GHZ_2nd,	0,		Blk16_GHZ,	Blk256_GHZ,	bgm_SBZ,	palid_Ending	; Ending
		even

; * music and level gfx are actually set elsewhere, so these values are useless

; ---------------------------------------------------------------------------
; Pattern load cues
; ---------------------------------------------------------------------------
ArtLoadCues:

ptr_PLC_Main:		dc.w PLC_Main-ArtLoadCues
ptr_PLC_Main2:		dc.w PLC_Main2-ArtLoadCues
ptr_PLC_Explode:	dc.w PLC_Explode-ArtLoadCues
ptr_PLC_GameOver:	dc.w PLC_GameOver-ArtLoadCues
PLC_Levels:
ptr_PLC_GHZ:		dc.w PLC_GHZ-ArtLoadCues
ptr_PLC_GHZ2:		dc.w PLC_GHZ2-ArtLoadCues
ptr_PLC_LZ:		dc.w PLC_LZ-ArtLoadCues
ptr_PLC_LZ2:		dc.w PLC_LZ2-ArtLoadCues
ptr_PLC_MZ:		dc.w PLC_MZ-ArtLoadCues
ptr_PLC_MZ2:		dc.w PLC_MZ2-ArtLoadCues
ptr_PLC_SLZ:		dc.w PLC_SLZ-ArtLoadCues
ptr_PLC_SLZ2:		dc.w PLC_SLZ2-ArtLoadCues
ptr_PLC_SYZ:		dc.w PLC_SYZ-ArtLoadCues
ptr_PLC_SYZ2:		dc.w PLC_SYZ2-ArtLoadCues
ptr_PLC_SBZ:		dc.w PLC_SBZ-ArtLoadCues
ptr_PLC_SBZ2:		dc.w PLC_SBZ2-ArtLoadCues
ptr_PLC_TitleCard:	dc.w PLC_TitleCard-ArtLoadCues
ptr_PLC_Boss:		dc.w PLC_Boss-ArtLoadCues
ptr_PLC_Signpost:	dc.w PLC_Signpost-ArtLoadCues
ptr_PLC_Warp:		dc.w PLC_Warp-ArtLoadCues
ptr_PLC_SpecialStage:	dc.w PLC_SpecialStage-ArtLoadCues
PLC_Animals:
ptr_PLC_GHZAnimals:	dc.w PLC_GHZAnimals-ArtLoadCues
ptr_PLC_LZAnimals:	dc.w PLC_LZAnimals-ArtLoadCues
ptr_PLC_MZAnimals:	dc.w PLC_MZAnimals-ArtLoadCues
ptr_PLC_SLZAnimals:	dc.w PLC_SLZAnimals-ArtLoadCues
ptr_PLC_SYZAnimals:	dc.w PLC_SYZAnimals-ArtLoadCues
ptr_PLC_SBZAnimals:	dc.w PLC_SBZAnimals-ArtLoadCues
ptr_PLC_SSResult:	dc.w PLC_SSResult-ArtLoadCues
ptr_PLC_Ending:		dc.w PLC_Ending-ArtLoadCues
ptr_PLC_TryAgain:	dc.w PLC_TryAgain-ArtLoadCues
ptr_PLC_EggmanSBZ2:	dc.w PLC_EggmanSBZ2-ArtLoadCues
ptr_PLC_FZBoss:		dc.w PLC_FZBoss-ArtLoadCues

plcm:	macro gfx,vram
	dc.l gfx
	dc.w vram
	endm

; ---------------------------------------------------------------------------
; Pattern load cues - standard block 1
; ---------------------------------------------------------------------------
PLC_Main:	dc.w ((PLC_Mainend-PLC_Main-2)/6)-1
		plcm	Nem_Lamp, $F400		; lamppost
		plcm	Nem_Hud, $D940		; HUD
		plcm	Nem_Lives, $FA80	; lives counter
		plcm	Nem_Ring, $F640 	; rings
		plcm	Nem_Points, $F2E0	; points from enemy
	PLC_Mainend:
; ---------------------------------------------------------------------------
; Pattern load cues - standard block 2
; ---------------------------------------------------------------------------
PLC_Main2:	dc.w ((PLC_Main2end-PLC_Main2-2)/6)-1
		plcm	Nem_Monitors, $D000	; monitors
		plcm	Nem_Shield, $A820	; shield
		plcm	Nem_Stars, $AB80	; invincibility stars
	PLC_Main2end:
; ---------------------------------------------------------------------------
; Pattern load cues - explosion
; ---------------------------------------------------------------------------
PLC_Explode:	dc.w ((PLC_Explodeend-PLC_Explode-2)/6)-1
		plcm	Nem_Explode, $B400	; explosion
	PLC_Explodeend:
; ---------------------------------------------------------------------------
; Pattern load cues - game/time over
; ---------------------------------------------------------------------------
PLC_GameOver:	dc.w ((PLC_GameOverend-PLC_GameOver-2)/6)-1
		plcm	Nem_GameOver, $ABC0	; game/time over
	PLC_GameOverend:
; ---------------------------------------------------------------------------
; Pattern load cues - Green Hill
; ---------------------------------------------------------------------------
PLC_GHZ:	dc.w ((PLC_GHZ2-PLC_GHZ-2)/6)-1
		plcm	Nem_GHZ_1st, 0		; GHZ main patterns
		plcm	Nem_GHZ_2nd, $39A0	; GHZ secondary patterns
		plcm	Nem_Stalk, $6B00	; flower stalk
		plcm	Nem_PplRock, $7A00	; purple rock
		plcm	Nem_Crabmeat, $8000	; crabmeat enemy
		plcm	Nem_Buzz, $8880		; buzz bomber enemy
		plcm	Nem_Chopper, $8F60	; chopper enemy
		plcm	Nem_Newtron, $9360	; newtron enemy
		plcm	Nem_Motobug, $9E00	; motobug enemy
		plcm	Nem_Spikes, $A360	; spikes
		plcm	Nem_HSpring, $A460	; horizontal spring
		plcm	Nem_VSpring, $A660	; vertical spring

PLC_GHZ2:	dc.w ((PLC_GHZ2end-PLC_GHZ2-2)/6)-1
		plcm	Nem_Swing, $7000	; swinging platform
		plcm	Nem_Bridge, $71C0	; bridge
		plcm	Nem_SpikePole, $7300	; spiked pole
		plcm	Nem_Ball, $7540		; giant ball
		plcm	Nem_GhzWall1, $A1E0	; breakable wall
		plcm	Nem_GhzWall2, $6980	; normal wall
	PLC_GHZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - Labyrinth
; ---------------------------------------------------------------------------
PLC_LZ:		dc.w ((PLC_LZ2-PLC_LZ-2)/6)-1
		plcm	Nem_LZ,0		; LZ main patterns
		plcm	Nem_LzBlock1, $3C00	; block
		plcm	Nem_LzBlock2, $3E00	; blocks
		plcm	Nem_Splash, $4B20	; waterfalls and splash
		plcm	Nem_Water, $6000	; water surface
		plcm	Nem_LzSpikeBall, $6200	; spiked ball
		plcm	Nem_FlapDoor, $6500	; flapping door
		plcm	Nem_Bubbles, $6900	; bubbles and numbers
		plcm	Nem_LzBlock3, $7780	; block
		plcm	Nem_LzDoor1, $7880	; vertical door
		plcm	Nem_Harpoon, $7980	; harpoon
		plcm	Nem_Burrobot, $94C0	; burrobot enemy

PLC_LZ2:	dc.w ((PLC_LZ2end-PLC_LZ2-2)/6)-1
		plcm	Nem_LzPole, $7BC0	; pole that breaks
		plcm	Nem_LzDoor2, $7CC0	; large horizontal door
		plcm	Nem_LzWheel, $7EC0	; wheel
		plcm	Nem_Gargoyle, $5D20	; gargoyle head
		plcm	Nem_LzPlatfm, $89E0	; rising platform
		plcm	Nem_Orbinaut, $8CE0	; orbinaut enemy
		plcm	Nem_Jaws, $90C0		; jaws enemy
		plcm	Nem_LzSwitch, $A1E0	; switch
		plcm	Nem_Cork, $A000		; cork block
		plcm	Nem_Spikes, $A360	; spikes
		plcm	Nem_HSpring, $A460	; horizontal spring
		plcm	Nem_VSpring, $A660	; vertical spring
	PLC_LZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - Marble
; ---------------------------------------------------------------------------
PLC_MZ:		dc.w ((PLC_MZ2-PLC_MZ-2)/6)-1
		plcm	Nem_MZ,0		; MZ main patterns
		plcm	Nem_MzMetal, $6000	; metal blocks
		plcm	Nem_MzFire, $68A0	; fireballs
		plcm	Nem_Swing, $7000	; swinging platform
		plcm	Nem_MzGlass, $71C0	; green glassy block
		plcm	Nem_Lava, $7500		; lava
		plcm	Nem_Buzz, $8880		; buzz bomber enemy
		plcm	Nem_Yadrin, $8F60	; yadrin enemy
		plcm	Nem_Basaran, $9700	; basaran enemy
		plcm	Nem_Cater, $9FE0	; caterkiller enemy

PLC_MZ2:	dc.w ((PLC_MZ2end-PLC_MZ2-2)/6)-1
		plcm	Nem_MzSwitch, $A260	; switch
		plcm	Nem_Spikes, $A360	; spikes
		plcm	Nem_HSpring, $A460	; horizontal spring
		plcm	Nem_VSpring, $A660	; vertical spring
		plcm	Nem_MzBlock, $5700	; green stone block
	PLC_MZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - Star Light
; ---------------------------------------------------------------------------
PLC_SLZ:	dc.w ((PLC_SLZ2-PLC_SLZ-2)/6)-1
		plcm	Nem_SLZ,0		; SLZ main patterns
		plcm	Nem_Bomb, $8000		; bomb enemy
		plcm	Nem_Orbinaut, $8520	; orbinaut enemy
		plcm	Nem_MzFire, $9000	; fireballs
		plcm	Nem_SlzBlock, $9C00	; block
		plcm	Nem_SlzWall, $A260	; breakable wall
		plcm	Nem_Spikes, $A360	; spikes
		plcm	Nem_HSpring, $A460	; horizontal spring
		plcm	Nem_VSpring, $A660	; vertical spring

PLC_SLZ2:	dc.w ((PLC_SLZ2end-PLC_SLZ2-2)/6)-1
		plcm	Nem_Seesaw, $6E80	; seesaw
		plcm	Nem_Fan, $7400		; fan
		plcm	Nem_Pylon, $7980	; foreground pylon
		plcm	Nem_SlzSwing, $7B80	; swinging platform
		plcm	Nem_SlzCannon, $9B00	; fireball launcher
		plcm	Nem_SlzSpike, $9E00	; spikeball
	PLC_SLZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - Spring Yard
; ---------------------------------------------------------------------------
PLC_SYZ:	dc.w ((PLC_SYZ2-PLC_SYZ-2)/6)-1
		plcm	Nem_SYZ,0		; SYZ main patterns
		plcm	Nem_Crabmeat, $8000	; crabmeat enemy
		plcm	Nem_Buzz, $8880		; buzz bomber enemy
		plcm	Nem_Yadrin, $8F60	; yadrin enemy
		plcm	Nem_Roller, $9700	; roller enemy

PLC_SYZ2:	dc.w ((PLC_SYZ2end-PLC_SYZ2-2)/6)-1
		plcm	Nem_Bumper, $7000	; bumper
		plcm	Nem_SyzSpike1, $72C0	; large spikeball
		plcm	Nem_SyzSpike2, $7740	; small spikeball
		plcm	Nem_Cater, $9FE0	; caterkiller enemy
		plcm	Nem_LzSwitch, $A1E0	; switch
		plcm	Nem_Spikes, $A360	; spikes
		plcm	Nem_HSpring, $A460	; horizontal spring
		plcm	Nem_VSpring, $A660	; vertical spring
	PLC_SYZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - Scrap Brain
; ---------------------------------------------------------------------------
PLC_SBZ:	dc.w ((PLC_SBZ2-PLC_SBZ-2)/6)-1
		plcm	Nem_SBZ,0		; SBZ main patterns
		plcm	Nem_Stomper, $5800	; moving platform and stomper
		plcm	Nem_SbzDoor1, $5D00	; door
		plcm	Nem_Girder, $5E00	; girder
		plcm	Nem_BallHog, $6040	; ball hog enemy
		plcm	Nem_SbzWheel1, $6880	; spot on large wheel
		plcm	Nem_SbzWheel2, $6900	; wheel that grabs Sonic
		plcm	Nem_SyzSpike1, $7220	; large spikeball
		plcm	Nem_Cutter, $76A0	; pizza cutter
		plcm	Nem_FlamePipe, $7B20	; flaming pipe
		plcm	Nem_SbzFloor, $7EA0	; collapsing floor
		plcm	Nem_SbzBlock, $9860	; vanishing block

PLC_SBZ2:	dc.w ((PLC_SBZ2end-PLC_SBZ2-2)/6)-1
		plcm	Nem_Cater, $5600	; caterkiller enemy
		plcm	Nem_Bomb, $8000		; bomb enemy
		plcm	Nem_Orbinaut, $8520	; orbinaut enemy
		plcm	Nem_SlideFloor, $8C00	; floor that slides away
		plcm	Nem_SbzDoor2, $8DE0	; horizontal door
		plcm	Nem_Electric, $8FC0	; electric orb
		plcm	Nem_TrapDoor, $9240	; trapdoor
		plcm	Nem_SbzFloor, $7F20	; collapsing floor
		plcm	Nem_SpinPform, $9BE0	; small spinning platform
		plcm	Nem_LzSwitch, $A1E0	; switch
		plcm	Nem_Spikes, $A360	; spikes
		plcm	Nem_HSpring, $A460	; horizontal spring
		plcm	Nem_VSpring, $A660	; vertical spring
	PLC_SBZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - title card
; ---------------------------------------------------------------------------
PLC_TitleCard:	dc.w ((PLC_TitleCardend-PLC_TitleCard-2)/6)-1
		plcm	Nem_TitleCard, $B000
	PLC_TitleCardend:
; ---------------------------------------------------------------------------
; Pattern load cues - act 3 boss
; ---------------------------------------------------------------------------
PLC_Boss:	dc.w ((PLC_Bossend-PLC_Boss-2)/6)-1
		plcm	Nem_Eggman, $8000	; Eggman main patterns
		plcm	Nem_Weapons, $8D80	; Eggman's weapons
		plcm	Nem_Prison, $93A0	; prison capsule
		plcm	Nem_Bomb, $A300		; bomb enemy ((gets overwritten)
		plcm	Nem_SlzSpike, $A300	; spikeball ((SLZ boss)
		plcm	Nem_Exhaust, $A540	; exhaust flame
	PLC_Bossend:
; ---------------------------------------------------------------------------
; Pattern load cues - act 1/2 signpost
; ---------------------------------------------------------------------------
PLC_Signpost:	dc.w ((PLC_Signpostend-PLC_Signpost-2)/6)-1
		plcm	Nem_SignPost, $D000	; signpost
		plcm	Nem_Bonus, $96C0	; hidden bonus points
		plcm	Nem_BigFlash, $8C40	; giant ring flash effect
	PLC_Signpostend:
; ---------------------------------------------------------------------------
; Pattern load cues - beta special stage warp effect
; ---------------------------------------------------------------------------
PLC_Warp:	; unused
; ---------------------------------------------------------------------------
; Pattern load cues - special stage
; ---------------------------------------------------------------------------
PLC_SpecialStage:	dc.w ((PLC_SpeStageend-PLC_SpecialStage-2)/6)-1
		plcm	Nem_SSBgCloud, 0	; bubble and cloud background
		plcm	Nem_SSBgFish, $A20	; bird and fish background
		plcm	Nem_SSWalls, $2840	; walls
		plcm	Nem_Bumper, $4760	; bumper
		plcm	Nem_SSGOAL, $4A20	; GOAL block
		plcm	Nem_SSUpDown, $4C60	; UP and DOWN blocks
		plcm	Nem_SSRBlock, $5E00	; R block
		plcm	Nem_SS1UpBlock, $6E00	; 1UP block
		plcm	Nem_SSEmStars, $7E00	; emerald collection stars
		plcm	Nem_SSRedWhite, $8E00	; red and white block
		plcm	Nem_SSGhost, $9E00	; ghost block
		plcm	Nem_SSWBlock, $AE00	; W block
		plcm	Nem_SSGlass, $BE00	; glass block
		plcm	Nem_SSEmerald, $EE00	; emeralds
		plcm	Nem_SSZone1, $F2E0	; ZONE 1 block
		plcm	Nem_SSZone2, $F400	; ZONE 2 block
		plcm	Nem_SSZone3, $F520	; ZONE 3 block
	PLC_SpeStageend:
		plcm	Nem_SSZone4, $F2E0	; ZONE 4 block
		plcm	Nem_SSZone5, $F400	; ZONE 5 block
		plcm	Nem_SSZone6, $F520	; ZONE 6 block
; ---------------------------------------------------------------------------
; Pattern load cues - GHZ animals
; ---------------------------------------------------------------------------
PLC_GHZAnimals:	dc.w ((PLC_GHZAnimalsend-PLC_GHZAnimals-2)/6)-1
		plcm	Nem_Rabbit, $B000	; rabbit
		plcm	Nem_Flicky, $B240	; flicky
	PLC_GHZAnimalsend:
; ---------------------------------------------------------------------------
; Pattern load cues - LZ animals
; ---------------------------------------------------------------------------
PLC_LZAnimals:	dc.w ((PLC_LZAnimalsend-PLC_LZAnimals-2)/6)-1
		plcm	Nem_Penguin, $B000	; penguin
		plcm	Nem_Seal, $B240		; seal
	PLC_LZAnimalsend:
; ---------------------------------------------------------------------------
; Pattern load cues - MZ animals
; ---------------------------------------------------------------------------
PLC_MZAnimals:	dc.w ((PLC_MZAnimalsend-PLC_MZAnimals-2)/6)-1
		plcm	Nem_Squirrel, $B000	; squirrel
		plcm	Nem_Seal, $B240		; seal
	PLC_MZAnimalsend:
; ---------------------------------------------------------------------------
; Pattern load cues - SLZ animals
; ---------------------------------------------------------------------------
PLC_SLZAnimals:	dc.w ((PLC_SLZAnimalsend-PLC_SLZAnimals-2)/6)-1
		plcm	Nem_Pig, $B000		; pig
		plcm	Nem_Flicky, $B240	; flicky
	PLC_SLZAnimalsend:
; ---------------------------------------------------------------------------
; Pattern load cues - SYZ animals
; ---------------------------------------------------------------------------
PLC_SYZAnimals:	dc.w ((PLC_SYZAnimalsend-PLC_SYZAnimals-2)/6)-1
		plcm	Nem_Pig, $B000		; pig
		plcm	Nem_Chicken, $B240	; chicken
	PLC_SYZAnimalsend:
; ---------------------------------------------------------------------------
; Pattern load cues - SBZ animals
; ---------------------------------------------------------------------------
PLC_SBZAnimals:	dc.w ((PLC_SBZAnimalsend-PLC_SBZAnimals-2)/6)-1
		plcm	Nem_Rabbit, $B000	; rabbit
		plcm	Nem_Chicken, $B240	; chicken
	PLC_SBZAnimalsend:
; ---------------------------------------------------------------------------
; Pattern load cues - special stage results screen
; ---------------------------------------------------------------------------
PLC_SSResult:dc.w ((PLC_SpeStResultend-PLC_SSResult-2)/6)-1
		plcm	Nem_ResultEm, $A820	; emeralds
		plcm	Nem_MiniSonic, $AA20	; mini Sonic
	PLC_SpeStResultend:
; ---------------------------------------------------------------------------
; Pattern load cues - ending sequence
; ---------------------------------------------------------------------------
PLC_Ending:	dc.w ((PLC_Endingend-PLC_Ending-2)/6)-1
		plcm	Nem_GHZ_1st,0		; GHZ main patterns
		plcm	Nem_GHZ_2nd, $39A0	; GHZ secondary patterns
		plcm	Nem_Stalk, $6B00	; flower stalk
		plcm	Nem_EndFlower, $7400	; flowers
		plcm	Nem_EndEm, $78A0	; emeralds
		plcm	Nem_EndSonic, $7C20	; Sonic
		plcm	Nem_Rabbit, $AA60	; rabbit
		plcm	Nem_Chicken, $ACA0	; chicken
		plcm	Nem_Penguin, $AE60	; penguin
		plcm	Nem_Seal, $B0A0		; seal
		plcm	Nem_Pig, $B260		; pig
		plcm	Nem_Flicky, $B4A0	; flicky
		plcm	Nem_Squirrel, $B660	; squirrel
		plcm	Nem_EndStH, $B8A0	; "SONIC THE HEDGEHOG"
	PLC_Endingend:
; ---------------------------------------------------------------------------
; Pattern load cues - "TRY AGAIN" and "END" screens
; ---------------------------------------------------------------------------
PLC_TryAgain:	dc.w ((PLC_TryAgainend-PLC_TryAgain-2)/6)-1
		plcm	Nem_EndEm, $78A0	; emeralds
		plcm	Nem_TryAgain, $7C20	; Eggman
		plcm	Nem_CreditText, $B400	; credits alphabet
	PLC_TryAgainend:
; ---------------------------------------------------------------------------
; Pattern load cues - Eggman on SBZ 2
; ---------------------------------------------------------------------------
PLC_EggmanSBZ2:	dc.w ((PLC_EggmanSBZ2end-PLC_EggmanSBZ2-2)/6)-1
		plcm	Nem_SbzBlock, $A300	; block
		plcm	Nem_Sbz2Eggman, $8000	; Eggman
		plcm	Nem_LzSwitch, $9400	; switch
	PLC_EggmanSBZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - final boss
; ---------------------------------------------------------------------------
PLC_FZBoss:	dc.w ((PLC_FZBossend-PLC_FZBoss-2)/6)-1
		plcm	Nem_FzEggman, $7400	; Eggman after boss
		plcm	Nem_FzBoss, $6000	; FZ boss
		plcm	Nem_Eggman, $8000	; Eggman main patterns
		plcm	Nem_Sbz2Eggman, $8E00	; Eggman without ship
		plcm	Nem_Exhaust, $A540	; exhaust flame
	PLC_FZBossend:
		even

; ---------------------------------------------------------------------------
; Pattern load cue IDs
; ---------------------------------------------------------------------------
plcid_Main:		equ (ptr_PLC_Main-ArtLoadCues)/2	; 0
plcid_Main2:		equ (ptr_PLC_Main2-ArtLoadCues)/2	; 1
plcid_Explode:		equ (ptr_PLC_Explode-ArtLoadCues)/2	; 2
plcid_GameOver:		equ (ptr_PLC_GameOver-ArtLoadCues)/2	; 3
plcid_GHZ:		equ (ptr_PLC_GHZ-ArtLoadCues)/2		; 4
plcid_GHZ2:		equ (ptr_PLC_GHZ2-ArtLoadCues)/2	; 5
plcid_LZ:		equ (ptr_PLC_LZ-ArtLoadCues)/2		; 6
plcid_LZ2:		equ (ptr_PLC_LZ2-ArtLoadCues)/2		; 7
plcid_MZ:		equ (ptr_PLC_MZ-ArtLoadCues)/2		; 8
plcid_MZ2:		equ (ptr_PLC_MZ2-ArtLoadCues)/2		; 9
plcid_SLZ:		equ (ptr_PLC_SLZ-ArtLoadCues)/2		; $A
plcid_SLZ2:		equ (ptr_PLC_SLZ2-ArtLoadCues)/2	; $B
plcid_SYZ:		equ (ptr_PLC_SYZ-ArtLoadCues)/2		; $C
plcid_SYZ2:		equ (ptr_PLC_SYZ2-ArtLoadCues)/2	; $D
plcid_SBZ:		equ (ptr_PLC_SBZ-ArtLoadCues)/2		; $E
plcid_SBZ2:		equ (ptr_PLC_SBZ2-ArtLoadCues)/2	; $F
plcid_TitleCard:	equ (ptr_PLC_TitleCard-ArtLoadCues)/2	; $10
plcid_Boss:		equ (ptr_PLC_Boss-ArtLoadCues)/2	; $11
plcid_Signpost:		equ (ptr_PLC_Signpost-ArtLoadCues)/2	; $12
plcid_Warp:		equ (ptr_PLC_Warp-ArtLoadCues)/2	; $13
plcid_SpecialStage:	equ (ptr_PLC_SpecialStage-ArtLoadCues)/2 ; $14
plcid_GHZAnimals:	equ (ptr_PLC_GHZAnimals-ArtLoadCues)/2	; $15
plcid_LZAnimals:	equ (ptr_PLC_LZAnimals-ArtLoadCues)/2	; $16
plcid_MZAnimals:	equ (ptr_PLC_MZAnimals-ArtLoadCues)/2	; $17
plcid_SLZAnimals:	equ (ptr_PLC_SLZAnimals-ArtLoadCues)/2	; $18
plcid_SYZAnimals:	equ (ptr_PLC_SYZAnimals-ArtLoadCues)/2	; $19
plcid_SBZAnimals:	equ (ptr_PLC_SBZAnimals-ArtLoadCues)/2	; $1A
plcid_SSResult:		equ (ptr_PLC_SSResult-ArtLoadCues)/2	; $1B
plcid_Ending:		equ (ptr_PLC_Ending-ArtLoadCues)/2	; $1C
plcid_TryAgain:		equ (ptr_PLC_TryAgain-ArtLoadCues)/2	; $1D
plcid_EggmanSBZ2:	equ (ptr_PLC_EggmanSBZ2-ArtLoadCues)/2	; $1E
plcid_FZBoss:		equ (ptr_PLC_FZBoss-ArtLoadCues)/2	; $1F

		align	$200,$FF
		dcb.b	$300,$FF

; ---------------------------------------------------------------------------
; Art and mappings - screens
; ---------------------------------------------------------------------------
Nem_SegaLogo:	incbin	"artnem\Sega Logo.bin" ; large Sega logo
		even
Eni_SegaLogo:	incbin	"misc\Sega Logo Maps (Enigma).bin" ; large Sega logo (mappings)
		even
Eni_Title:	incbin	"misc\Title Screen Maps (Enigma).bin" ; title screen foreground (mappings)
		even
Nem_TitleFg:	incbin	"artnem\Title Screen Foreground.bin"
		even
Nem_TitleSonic:	incbin	"artnem\Title Screen Sonic.bin"
		even
Nem_TitleTM:	incbin	"artnem\Title Screen TM.bin"
		even
Eni_JapNames:	incbin	"misc\Hidden Japanese Credits Maps (Enigma).bin" ; Japanese credits (mappings)
		even
Nem_JapNames:	incbin	"artnem\Hidden Japanese Credits.bin"
		even
; ---------------------------------------------------------------------------
; Uncompressed graphics - Sonic
; ---------------------------------------------------------------------------
Map_Sonic:	include	"_maps\Sonic.asm"
SonicDynPLC:	include	"_maps\Sonic - Dynamic Gfx Script.asm"
Art_Sonic:	incbin	"artunc\Sonic.bin"	; Sonic
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_Shield:	incbin	"artnem\Shield.bin"
		even
Nem_Stars:	incbin	"artnem\Invincibility Stars.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - special stage
; ---------------------------------------------------------------------------
Map_SSWalls:	include	"_maps\SS Walls.asm"
Nem_SSWalls:	incbin	"artnem\Special Walls.bin" ; special stage walls
		even
Eni_SSBg1:	incbin	"misc\SS Background 1 Maps (Enigma).bin" ; special stage background (mappings)
		even
Nem_SSBgFish:	incbin	"artnem\Special Birds & Fish.bin" ; special stage birds and fish background
		even
Eni_SSBg2:	incbin	"misc\SS Background 2 Maps (Enigma).bin" ; special stage background (mappings)
		even
Nem_SSBgCloud:	incbin	"artnem\Special Clouds.bin" ; special stage clouds background
		even
Nem_SSGOAL:	incbin	"artnem\Special GOAL.bin" ; special stage GOAL block
		even
Nem_SSRBlock:	incbin	"artnem\Special R.bin"	; special stage R block
		even
Nem_SS1UpBlock:	incbin	"artnem\Special 1UP.bin" ; special stage 1UP block
		even
Nem_SSEmStars:	incbin	"artnem\Special Emerald Twinkle.bin" ; special stage stars from a collected emerald
		even
Nem_SSRedWhite:	incbin	"artnem\Special Red-White.bin" ; special stage red/white block
		even
Nem_SSZone1:	incbin	"artnem\Special ZONE1.bin" ; special stage ZONE1 block
		even
Nem_SSZone2:	incbin	"artnem\Special ZONE2.bin" ; ZONE2 block
		even
Nem_SSZone3:	incbin	"artnem\Special ZONE3.bin" ; ZONE3 block
		even
Nem_SSZone4:	incbin	"artnem\Special ZONE4.bin" ; ZONE4 block
		even
Nem_SSZone5:	incbin	"artnem\Special ZONE5.bin" ; ZONE5 block
		even
Nem_SSZone6:	incbin	"artnem\Special ZONE6.bin" ; ZONE6 block
		even
Nem_SSUpDown:	incbin	"artnem\Special UP-DOWN.bin" ; special stage UP/DOWN block
		even
Nem_SSEmerald:	incbin	"artnem\Special Emeralds.bin" ; special stage chaos emeralds
		even
Nem_SSGhost:	incbin	"artnem\Special Ghost.bin" ; special stage ghost block
		even
Nem_SSWBlock:	incbin	"artnem\Special W.bin"	; special stage W block
		even
Nem_SSGlass:	incbin	"artnem\Special Glass.bin" ; special stage destroyable glass block
		even
Nem_ResultEm:	incbin	"artnem\Special Result Emeralds.bin" ; chaos emeralds on special stage results screen
		even
; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
Nem_Stalk:	incbin	"artnem\GHZ Flower Stalk.bin"
		even
Nem_Swing:	incbin	"artnem\GHZ Swinging Platform.bin"
		even
Nem_Bridge:	incbin	"artnem\GHZ Bridge.bin"
		even
Nem_Ball:	incbin	"artnem\GHZ Giant Ball.bin"
		even
Nem_Spikes:	incbin	"artnem\Spikes.bin"
		even
Nem_SpikePole:	incbin	"artnem\GHZ Spiked Log.bin"
		even
Nem_PplRock:	incbin	"artnem\GHZ Purple Rock.bin"
		even
Nem_GhzWall1:	incbin	"artnem\GHZ Breakable Wall.bin"
		even
Nem_GhzWall2:	incbin	"artnem\GHZ Edge Wall.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - LZ stuff
; ---------------------------------------------------------------------------
Nem_Water:	incbin	"artnem\LZ Water Surface.bin"
		even
Nem_Splash:	incbin	"artnem\LZ Water & Splashes.bin"
		even
Nem_LzSpikeBall:incbin	"artnem\LZ Spiked Ball & Chain.bin"
		even
Nem_FlapDoor:	incbin	"artnem\LZ Flapping Door.bin"
		even
Nem_Bubbles:	incbin	"artnem\LZ Bubbles & Countdown.bin"
		even
Nem_LzBlock3:	incbin	"artnem\LZ 32x16 Block.bin"
		even
Nem_LzDoor1:	incbin	"artnem\LZ Vertical Door.bin"
		even
Nem_Harpoon:	incbin	"artnem\LZ Harpoon.bin"
		even
Nem_LzPole:	incbin	"artnem\LZ Breakable Pole.bin"
		even
Nem_LzDoor2:	incbin	"artnem\LZ Horizontal Door.bin"
		even
Nem_LzWheel:	incbin	"artnem\LZ Wheel.bin"
		even
Nem_Gargoyle:	incbin	"artnem\LZ Gargoyle & Fireball.bin"
		even
Nem_LzBlock2:	incbin	"artnem\LZ Blocks.bin"
		even
Nem_LzPlatfm:	incbin	"artnem\LZ Rising Platform.bin"
		even
Nem_Cork:	incbin	"artnem\LZ Cork.bin"
		even
Nem_LzBlock1:	incbin	"artnem\LZ 32x32 Block.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - MZ stuff
; ---------------------------------------------------------------------------
Nem_MzMetal:	incbin	"artnem\MZ Metal Blocks.bin"
		even
Nem_MzSwitch:	incbin	"artnem\MZ Switch.bin"
		even
Nem_MzGlass:	incbin	"artnem\MZ Green Glass Block.bin"
		even
Nem_MzFire:	incbin	"artnem\Fireballs.bin"
		even
Nem_Lava:	incbin	"artnem\MZ Lava.bin"
		even
Nem_MzBlock:	incbin	"artnem\MZ Green Pushable Block.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SLZ stuff
; ---------------------------------------------------------------------------
Nem_Seesaw:	incbin	"artnem\SLZ Seesaw.bin"
		even
Nem_SlzSpike:	incbin	"artnem\SLZ Little Spikeball.bin"
		even
Nem_Fan:	incbin	"artnem\SLZ Fan.bin"
		even
Nem_SlzWall:	incbin	"artnem\SLZ Breakable Wall.bin"
		even
Nem_Pylon:	incbin	"artnem\SLZ Pylon.bin"
		even
Nem_SlzSwing:	incbin	"artnem\SLZ Swinging Platform.bin"
		even
Nem_SlzBlock:	incbin	"artnem\SLZ 32x32 Block.bin"
		even
Nem_SlzCannon:	incbin	"artnem\SLZ Cannon.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SYZ stuff
; ---------------------------------------------------------------------------
Nem_Bumper:	incbin	"artnem\SYZ Bumper.bin"
		even
Nem_SyzSpike2:	incbin	"artnem\SYZ Small Spikeball.bin"
		even
Nem_LzSwitch:	incbin	"artnem\Switch.bin"
		even
Nem_SyzSpike1:	incbin	"artnem\SYZ Large Spikeball.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SBZ stuff
; ---------------------------------------------------------------------------
Nem_SbzWheel1:	incbin	"artnem\SBZ Running Disc.bin"
		even
Nem_SbzWheel2:	incbin	"artnem\SBZ Junction Wheel.bin"
		even
Nem_Cutter:	incbin	"artnem\SBZ Pizza Cutter.bin"
		even
Nem_Stomper:	incbin	"artnem\SBZ Stomper.bin"
		even
Nem_SpinPform:	incbin	"artnem\SBZ Spinning Platform.bin"
		even
Nem_TrapDoor:	incbin	"artnem\SBZ Trapdoor.bin"
		even
Nem_SbzFloor:	incbin	"artnem\SBZ Collapsing Floor.bin"
		even
Nem_Electric:	incbin	"artnem\SBZ Electrocuter.bin"
		even
Nem_SbzBlock:	incbin	"artnem\SBZ Vanishing Block.bin"
		even
Nem_FlamePipe:	incbin	"artnem\SBZ Flaming Pipe.bin"
		even
Nem_SbzDoor1:	incbin	"artnem\SBZ Small Vertical Door.bin"
		even
Nem_SlideFloor:	incbin	"artnem\SBZ Sliding Floor Trap.bin"
		even
Nem_SbzDoor2:	incbin	"artnem\SBZ Large Horizontal Door.bin"
		even
Nem_Girder:	incbin	"artnem\SBZ Crushing Girder.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - enemies
; ---------------------------------------------------------------------------
Nem_BallHog:	incbin	"artnem\Enemy Ball Hog.bin"
		even
Nem_Crabmeat:	incbin	"artnem\Enemy Crabmeat.bin"
		even
Nem_Buzz:	incbin	"artnem\Enemy Buzz Bomber.bin"
		even
Nem_Burrobot:	incbin	"artnem\Enemy Burrobot.bin"
		even
Nem_Chopper:	incbin	"artnem\Enemy Chopper.bin"
		even
Nem_Jaws:	incbin	"artnem\Enemy Jaws.bin"
		even
Nem_Roller:	incbin	"artnem\Enemy Roller.bin"
		even
Nem_Motobug:	incbin	"artnem\Enemy Motobug.bin"
		even
Nem_Newtron:	incbin	"artnem\Enemy Newtron.bin"
		even
Nem_Yadrin:	incbin	"artnem\Enemy Yadrin.bin"
		even
Nem_Basaran:	incbin	"artnem\Enemy Basaran.bin"
		even
Nem_Splats:	incbin	"artnem\Enemy Splats.bin"
		even
Nem_Bomb:	incbin	"artnem\Enemy Bomb.bin"
		even
Nem_Orbinaut:	incbin	"artnem\Enemy Orbinaut.bin"
		even
Nem_Cater:	incbin	"artnem\Enemy Caterkiller.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_TitleCard:	incbin	"artnem\Title Cards.bin"
		even
Nem_Hud:	incbin	"artnem\HUD.bin"	; HUD (rings, time, score)
		even
Nem_Lives:	incbin	"artnem\HUD - Life Counter Icon.bin"
		even
Nem_Ring:	incbin	"artnem\Rings.bin"
		even
Nem_Monitors:	incbin	"artnem\Monitors.bin"
		even
Nem_Explode:	incbin	"artnem\Explosion.bin"
		even
Nem_Points:	incbin	"artnem\Points.bin"	; points from destroyed enemy or object
		even
Nem_GameOver:	incbin	"artnem\Game Over.bin"	; game over / time over
		even
Nem_HSpring:	incbin	"artnem\Spring Horizontal.bin"
		even
Nem_VSpring:	incbin	"artnem\Spring Vertical.bin"
		even
Nem_SignPost:	incbin	"artnem\Signpost.bin"	; end of level signpost
		even
Nem_Lamp:	incbin	"artnem\Lamppost.bin"
		even
Nem_BigFlash:	incbin	"artnem\Giant Ring Flash.bin"
		even
Nem_Bonus:	incbin	"artnem\Hidden Bonuses.bin" ; hidden bonuses at end of a level
		even
; ---------------------------------------------------------------------------
; Compressed graphics - continue screen
; ---------------------------------------------------------------------------
Nem_ContSonic:	incbin	"artnem\Continue Screen Sonic.bin"
		even
Nem_MiniSonic:	incbin	"artnem\Continue Screen Stuff.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
Nem_Rabbit:	incbin	"artnem\Animal Rabbit.bin"
		even
Nem_Chicken:	incbin	"artnem\Animal Chicken.bin"
		even
Nem_Penguin:	incbin	"artnem\Animal Penguin.bin"
		even
Nem_Seal:	incbin	"artnem\Animal Seal.bin"
		even
Nem_Pig:	incbin	"artnem\Animal Pig.bin"
		even
Nem_Flicky:	incbin	"artnem\Animal Flicky.bin"
		even
Nem_Squirrel:	incbin	"artnem\Animal Squirrel.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - primary patterns and block mappings
; ---------------------------------------------------------------------------
Blk16_GHZ:	incbin	"map16\GHZ.bin"
		even
Nem_GHZ_1st:	incbin	"artnem\8x8 - GHZ1.bin"	; GHZ primary patterns
		even
Nem_GHZ_2nd:	incbin	"artnem\8x8 - GHZ2.bin"	; GHZ secondary patterns
		even
Blk256_GHZ:	incbin	"map256\GHZ.bin"
		even
Blk16_LZ:	incbin	"map16\LZ.bin"
		even
Nem_LZ:		incbin	"artnem\8x8 - LZ.bin"	; LZ primary patterns
		even
Blk256_LZ:	incbin	"map256\LZ.bin"
		even
Blk16_MZ:	incbin	"map16\MZ.bin"
		even
Nem_MZ:		incbin	"artnem\8x8 - MZ.bin"	; MZ primary patterns
		even
Blk256_MZ:	incbin	"map256\MZ.bin"
		even
Blk16_SLZ:	incbin	"map16\SLZ.bin"
		even
Nem_SLZ:	incbin	"artnem\8x8 - SLZ.bin"	; SLZ primary patterns
		even
Blk256_SLZ:	incbin	"map256\SLZ.bin"
		even
Blk16_SYZ:	incbin	"map16\SYZ.bin"
		even
Nem_SYZ:	incbin	"artnem\8x8 - SYZ.bin"	; SYZ primary patterns
		even
Blk256_SYZ:	incbin	"map256\SYZ.bin"
		even
Blk16_SBZ:	incbin	"map16\SBZ.bin"
		even
Nem_SBZ:	incbin	"artnem\8x8 - SBZ.bin"	; SBZ primary patterns
		even
Blk256_SBZ:	incbin	"map256\SBZ.bin"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - bosses and ending sequence
; ---------------------------------------------------------------------------
Nem_Eggman:	incbin	"artnem\Boss - Main.bin"
		even
Nem_Weapons:	incbin	"artnem\Boss - Weapons.bin"
		even
Nem_Prison:	incbin	"artnem\Prison Capsule.bin"
		even
Nem_Sbz2Eggman:	incbin	"artnem\Boss - Eggman in SBZ2 & FZ.bin"
		even
Nem_FzBoss:	incbin	"artnem\Boss - Final Zone.bin"
		even
Nem_FzEggman:	incbin	"artnem\Boss - Eggman after FZ Fight.bin"
		even
Nem_Exhaust:	incbin	"artnem\Boss - Exhaust Flame.bin"
		even
Nem_EndEm:	incbin	"artnem\Ending - Emeralds.bin"
		even
Nem_EndSonic:	incbin	"artnem\Ending - Sonic.bin"
		even
Nem_TryAgain:	incbin	"artnem\Ending - Try Again.bin"
		even
Kos_EndFlowers:	incbin	"misc\Flowers at Ending (Kosinski).bin"
		even
Nem_EndFlower:	incbin	"artnem\Ending - Flowers.bin"
		even
Nem_CreditText:	incbin	"artnem\Ending - Credits.bin"
		even
Nem_EndStH:	incbin	"artnem\Ending - StH Logo.bin"
		even

		dcb.b $40,$FF			; why?
; ---------------------------------------------------------------------------
; Collision data
; ---------------------------------------------------------------------------
AngleMap:	incbin	"collide\Angle Map.bin"
		even
CollArray1:	incbin	"collide\Collision Array (Normal).bin"
		even
CollArray2:	incbin	"collide\Collision Array (Rotated).bin"
		even
Col_GHZ:	incbin	"collide\GHZ.bin"	; GHZ index
		even
Col_LZ:		incbin	"collide\LZ.bin"	; LZ index
		even
Col_MZ:		incbin	"collide\MZ.bin"	; MZ index
		even
Col_SLZ:	incbin	"collide\SLZ.bin"	; SLZ index
		even
Col_SYZ:	incbin	"collide\SYZ.bin"	; SYZ index
		even
Col_SBZ:	incbin	"collide\SBZ.bin"	; SBZ index
		even
; ---------------------------------------------------------------------------
; Special Stage layouts
; ---------------------------------------------------------------------------
SS_1:		incbin	"sslayout\1.bin"
		even
SS_2:		incbin	"sslayout\2.bin"
		even
SS_3:		incbin	"sslayout\3.bin"
		even
SS_4:		incbin	"sslayout\4.bin"
		even
SS_5:		incbin	"sslayout\5.bin"
		even
SS_6:		incbin	"sslayout\6.bin"
		even
; ---------------------------------------------------------------------------
; Animated uncompressed graphics
; ---------------------------------------------------------------------------
Art_GhzWater:	incbin	"artunc\GHZ Waterfall.bin"
		even
Art_GhzFlower1:	incbin	"artunc\GHZ Flower Large.bin"
		even
Art_GhzFlower2:	incbin	"artunc\GHZ Flower Small.bin"
		even
Art_MzLava1:	incbin	"artunc\MZ Lava Surface.bin"
		even
Art_MzLava2:	incbin	"artunc\MZ Lava.bin"
		even
Art_MzTorch:	incbin	"artunc\MZ Background Torch.bin"
		even
Art_SbzSmoke:	incbin	"artunc\SBZ Background Smoke.bin"
		even

; ---------------------------------------------------------------------------
; Level layout index
; ---------------------------------------------------------------------------
Level_Index:
		; GHZ
		dc.w Level_GHZ1-Level_Index, Level_GHZbg-Level_Index, byte_68D70-Level_Index
		dc.w Level_GHZ2-Level_Index, Level_GHZbg-Level_Index, byte_68E3C-Level_Index
		dc.w Level_GHZ3-Level_Index, Level_GHZbg-Level_Index, byte_68F84-Level_Index
		dc.w byte_68F88-Level_Index, byte_68F88-Level_Index, byte_68F88-Level_Index
		; LZ
		dc.w Level_LZ1-Level_Index, Level_LZbg-Level_Index, byte_69190-Level_Index
		dc.w Level_LZ2-Level_Index, Level_LZbg-Level_Index, byte_6922E-Level_Index
		dc.w Level_LZ3-Level_Index, Level_LZbg-Level_Index, byte_6934C-Level_Index
		dc.w Level_SBZ3-Level_Index, Level_LZbg-Level_Index, byte_6940A-Level_Index
		; MZ
		dc.w Level_MZ1-Level_Index, Level_MZ1bg-Level_Index, Level_MZ1-Level_Index
		dc.w Level_MZ2-Level_Index, Level_MZ2bg-Level_Index, byte_6965C-Level_Index
		dc.w Level_MZ3-Level_Index, Level_MZ3bg-Level_Index, byte_697E6-Level_Index
		dc.w byte_697EA-Level_Index, byte_697EA-Level_Index, byte_697EA-Level_Index
		; SLZ
		dc.w Level_SLZ1-Level_Index, Level_SLZbg-Level_Index, byte_69B84-Level_Index
		dc.w Level_SLZ2-Level_Index, Level_SLZbg-Level_Index, byte_69B84-Level_Index
		dc.w Level_SLZ3-Level_Index, Level_SLZbg-Level_Index, byte_69B84-Level_Index
		dc.w byte_69B84-Level_Index, byte_69B84-Level_Index, byte_69B84-Level_Index
		; SYZ
		dc.w Level_SYZ1-Level_Index, Level_SYZbg-Level_Index, byte_69C7E-Level_Index
		dc.w Level_SYZ2-Level_Index, Level_SYZbg-Level_Index, byte_69D86-Level_Index
		dc.w Level_SYZ3-Level_Index, Level_SYZbg-Level_Index, byte_69EE4-Level_Index
		dc.w byte_69EE8-Level_Index, byte_69EE8-Level_Index, byte_69EE8-Level_Index
		; SBZ
		dc.w Level_SBZ1-Level_Index, Level_SBZ1bg-Level_Index, Level_SBZ1bg-Level_Index
		dc.w Level_SBZ2-Level_Index, Level_SBZ2bg-Level_Index, Level_SBZ2bg-Level_Index
		dc.w Level_SBZ2-Level_Index, Level_SBZ2bg-Level_Index, byte_6A2F8-Level_Index
		dc.w byte_6A2FC-Level_Index, byte_6A2FC-Level_Index, byte_6A2FC-Level_Index
		; Ending
		dc.w Level_End-Level_Index, Level_GHZbg-Level_Index, byte_6A320-Level_Index
		dc.w Level_End-Level_Index, Level_GHZbg-Level_Index, byte_6A320-Level_Index
		dc.w byte_6A320-Level_Index, byte_6A320-Level_Index, byte_6A320-Level_Index
		dc.w byte_6A320-Level_Index, byte_6A320-Level_Index, byte_6A320-Level_Index

Level_GHZ1:	incbin	"levels\ghz1.bin"
		even
byte_68D70:	dc.b 0,	0, 0, 0
Level_GHZ2:	incbin	"levels\ghz2.bin"
		even
byte_68E3C:	dc.b 0,	0, 0, 0
Level_GHZ3:	incbin	"levels\ghz3.bin"
		even
Level_GHZbg:	incbin	"levels\ghzbg.bin"
		even
byte_68F84:	dc.b 0,	0, 0, 0
byte_68F88:	dc.b 0,	0, 0, 0

Level_LZ1:	incbin	"levels\lz1.bin"
		even
Level_LZbg:	incbin	"levels\lzbg.bin"
		even
byte_69190:	dc.b 0,	0, 0, 0
Level_LZ2:	incbin	"levels\lz2.bin"
		even
byte_6922E:	dc.b 0,	0, 0, 0
Level_LZ3:	incbin	"levels\lz3.bin"
		even
byte_6934C:	dc.b 0,	0, 0, 0
Level_SBZ3:	incbin	"levels\sbz3.bin"
		even
byte_6940A:	dc.b 0,	0, 0, 0

Level_MZ1:	incbin	"levels\mz1.bin"
		even
Level_MZ1bg:	incbin	"levels\mz1bg.bin"
		even
Level_MZ2:	incbin	"levels\mz2.bin"
		even
Level_MZ2bg:	incbin	"levels\mz2bg.bin"
		even
byte_6965C:	dc.b 0,	0, 0, 0
Level_MZ3:	incbin	"levels\mz3.bin"
		even
Level_MZ3bg:	incbin	"levels\mz3bg.bin"
		even
byte_697E6:	dc.b 0,	0, 0, 0
byte_697EA:	dc.b 0,	0, 0, 0

Level_SLZ1:	incbin	"levels\slz1.bin"
		even
Level_SLZbg:	incbin	"levels\slzbg.bin"
		even
Level_SLZ2:	incbin	"levels\slz2.bin"
		even
Level_SLZ3:	incbin	"levels\slz3.bin"
		even
byte_69B84:	dc.b 0,	0, 0, 0

Level_SYZ1:	incbin	"levels\syz1.bin"
		even
Level_SYZbg:	incbin	"levels\syzbg.bin"
		even
byte_69C7E:	dc.b 0,	0, 0, 0
Level_SYZ2:	incbin	"levels\syz2.bin"
		even
byte_69D86:	dc.b 0,	0, 0, 0
Level_SYZ3:	incbin	"levels\syz3.bin"
		even
byte_69EE4:	dc.b 0,	0, 0, 0
byte_69EE8:	dc.b 0,	0, 0, 0

Level_SBZ1:	incbin	"levels\sbz1.bin"
		even
Level_SBZ1bg:	incbin	"levels\sbz1bg.bin"
		even
Level_SBZ2:	incbin	"levels\sbz2.bin"
		even
Level_SBZ2bg:	incbin	"levels\sbz2bg.bin"
		even
byte_6A2F8:	dc.b 0,	0, 0, 0
byte_6A2FC:	dc.b 0,	0, 0, 0
Level_End:	incbin	"levels\ending.bin"
		even
byte_6A320:	dc.b 0,	0, 0, 0

Art_BigRing:	incbin	"artunc\Giant Ring.bin"
		even

		align	$100,$FF

; ---------------------------------------------------------------------------
; Sprite locations index
; ---------------------------------------------------------------------------
ObjPos_Index:
		; GHZ
		dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; LZ
		dc.w ObjPos_LZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; MZ
		dc.w ObjPos_MZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; SLZ
		dc.w ObjPos_SLZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; SYZ
		dc.w ObjPos_SYZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; SBZ
		dc.w ObjPos_SBZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_FZ-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; Ending
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		; --- Put extra object data here. ---
ObjPosLZPlatform_Index:
		dc.w ObjPos_LZ1pf1-ObjPos_Index, ObjPos_LZ1pf2-ObjPos_Index
		dc.w ObjPos_LZ2pf1-ObjPos_Index, ObjPos_LZ2pf2-ObjPos_Index
		dc.w ObjPos_LZ3pf1-ObjPos_Index, ObjPos_LZ3pf2-ObjPos_Index
		dc.w ObjPos_LZ1pf1-ObjPos_Index, ObjPos_LZ1pf2-ObjPos_Index
ObjPosSBZPlatform_Index:
		dc.w ObjPos_SBZ1pf1-ObjPos_Index, ObjPos_SBZ1pf2-ObjPos_Index
		dc.w ObjPos_SBZ1pf3-ObjPos_Index, ObjPos_SBZ1pf4-ObjPos_Index
		dc.w ObjPos_SBZ1pf5-ObjPos_Index, ObjPos_SBZ1pf6-ObjPos_Index
		dc.w ObjPos_SBZ1pf1-ObjPos_Index, ObjPos_SBZ1pf2-ObjPos_Index
		dc.b $FF, $FF, 0, 0, 0,	0
ObjPos_GHZ1:	incbin	"objpos\ghz1.bin"
		even
ObjPos_GHZ2:	incbin	"objpos\ghz2.bin"
		even
ObjPos_GHZ3:	incbin	"objpos\ghz3.bin"
		even
ObjPos_LZ1:	incbin	"objpos\lz1.bin"
		even
ObjPos_LZ2:	incbin	"objpos\lz2.bin"
		even
ObjPos_LZ3:	incbin	"objpos\lz3.bin"
		even
ObjPos_SBZ3:	incbin	"objpos\sbz3.bin"
		even
ObjPos_LZ1pf1:	incbin	"objpos\lz1pf1.bin"
		even
ObjPos_LZ1pf2:	incbin	"objpos\lz1pf2.bin"
		even
ObjPos_LZ2pf1:	incbin	"objpos\lz2pf1.bin"
		even
ObjPos_LZ2pf2:	incbin	"objpos\lz2pf2.bin"
		even
ObjPos_LZ3pf1:	incbin	"objpos\lz3pf1.bin"
		even
ObjPos_LZ3pf2:	incbin	"objpos\lz3pf2.bin"
		even
ObjPos_MZ1:	incbin	"objpos\mz1.bin"
		even
ObjPos_MZ2:	incbin	"objpos\mz2.bin"
		even
ObjPos_MZ3:	incbin	"objpos\mz3.bin"
		even
ObjPos_SLZ1:	incbin	"objpos\slz1.bin"
		even
ObjPos_SLZ2:	incbin	"objpos\slz2.bin"
		even
ObjPos_SLZ3:	incbin	"objpos\slz3.bin"
		even
ObjPos_SYZ1:	incbin	"objpos\syz1.bin"
		even
ObjPos_SYZ2:	incbin	"objpos\syz2.bin"
		even
ObjPos_SYZ3:	incbin	"objpos\syz3.bin"
		even
ObjPos_SBZ1:	incbin	"objpos\sbz1.bin"
		even
ObjPos_SBZ2:	incbin	"objpos\sbz2.bin"
		even
ObjPos_FZ:	incbin	"objpos\fz.bin"
		even
ObjPos_SBZ1pf1:	incbin	"objpos\sbz1pf1.bin"
		even
ObjPos_SBZ1pf2:	incbin	"objpos\sbz1pf2.bin"
		even
ObjPos_SBZ1pf3:	incbin	"objpos\sbz1pf3.bin"
		even
ObjPos_SBZ1pf4:	incbin	"objpos\sbz1pf4.bin"
		even
ObjPos_SBZ1pf5:	incbin	"objpos\sbz1pf5.bin"
		even
ObjPos_SBZ1pf6:	incbin	"objpos\sbz1pf6.bin"
		even
ObjPos_End:	incbin	"objpos\ending.bin"
		even
ObjPos_Null:	dc.b $FF, $FF, 0, 0, 0,	0

		dcb.b $63C,$FF
		;dcb.b ($10000-(*%$10000))-(EndOfRom-SoundDriver),$FF

		include "sound\MegaPCM.asm"
		include "sound\SampleTable.asm"

SoundDriver:	include "sound\s1.sounddriver.asm"
		even

; ==============================================================
; --------------------------------------------------------------
; Debugging modules
; --------------------------------------------------------------
		include	"_debug/_ErrorHandler.asm"
; --------------------------------------------------------------
; WARNING!
;	DO NOT put any data from now on! DO NOT use ROM padding!
;	Symbol data should be appended here after ROM is compiled
;	by ConvSym utility, otherwise debugger modules won't be able
;	to resolve symbol names.
; --------------------------------------------------------------

		include	"s2_menu.asm"	; Sonic 2 level select

EndOfRom:	END
