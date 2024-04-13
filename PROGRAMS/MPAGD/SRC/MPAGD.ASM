;	// MPAGD player
;	// Copyright (c) 2019-2024 Source Solutions, Inc.
;	// Copyright (c) 1984 Timex Group B.V.
;	// Copyright (c) 1982 Sky In-Home Service Ltd.

;	// system headers
	include "../../../SYSTEM/HEADERS/SYSTEM.INC"

	org $6000

;	// print intro text
	xor a;								// LD A, 0 (system screen)
	call SEScreenMode;					// API: set screen mode (also does CLS)

	ld ix, text;						// point to text
	call SEScreenPrintString;			// API: print ASCIIZ string

	ld ix, text_lo;						// point to text
	call SEScreenLowerPrintString;		// API: print ASCIIZ string (lower screen)

pr_key:
	call SEKeyboardWaitKey;				// wait for a keypress
	cp ' ';								// space?
	jr nz, pr_key;						// loop if not

	ld sp, 31999;						// set stack

;	// load ROM file
	ld ix, romname;						// filepath: /RSC/TC2048.ROM
	ld hl, 32000;						// address
	call SEFileLoad;					// load it

;	// copy TC2048 ROM to RAM
	di;									// interrupts off
	ld a, %00111111;					// set lower 48K to shadow RAM (middle 32K was already shadow RAM)
	out ($f4), a;						// set it
	ld hl, 32000;						// source
	ld de, 0;							// destination
	ldir;								// copy bytes
	ei;									// restore interrupts

;	// patch ROM to prevent it overwriting itself
	ld a, $17;							// po_scr_4a
	ld hl, $0d2c;						// used to overwrite
	ld (hl), a;							// the font
	xor a;								// skip_ret
	ld hl, $33fb;						// used to overwrite
	ld (hl), a;							// restart 0

;	// page out shadow RAM
	ld bc, $7ffd;						// page out VRAM
	ld a, %00011101;					// ROM 1, VRAM 1, HOME 5
	out (c), a;							// do paging
	ld hl, $4000;						// source
	ld de, $c000;						// destinatino
	ld bc, 16384;						// byte count
	ldir;								// copy contents of shadow RAM at $4000 to HOME bank 5
	xor a;								// LD A, 0
	out ($f4), a;						// page out all shadow RAM

;	// select VRAM 0 / HOME 0
	ld bc, $7ffd;						// page out VRAM
	ld a, %00010000;					// ROM 1, VRAM 0, HOME 0
	out (c), a;							// do paging

;	// load game file
	ld ix, gamename;					// filepath: /RSC/deleteme.bin
	ld hl, 32000;						// address
	call SEFileLoad;					// load it

;	// set pan
	ld a, %10011111;					// ACB stereo
	out ($f7), a;						// set it

;	// set ROM
	ld a, %00000011;					// lower 16K to be shadow RAM
	di;									// interrupts off
	out ($f4), a;						// set it
	ei;

;	// start the game
	jp 32000;							// skip over divMMC trap

romname:
	defb "tc2048.rom", 0;				// ROM file in resource folder

gamename:
	defb "deleteme.bin", 0;				// game file in resource folder

text:
	defb "MPAGD Player - version 1.0", 13;
 	defb "Copyright (C) 2024 Source Solutions, Inc.", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb " ", 13;
	defb 0;

text_lo:
	defb "NOW PRESS SPACE TO START THE GAME", 0;
