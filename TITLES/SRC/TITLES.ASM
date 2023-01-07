;	// TITLES - An example framework for building titles and a start menu

;	// Copyright (c) 2023 Source Solutions, Inc.

;	// OS hook codes
	include "UNODOS3.INC"

	frame equ 23672;					// returns to zero every second
	back_buffer equ $a800;				// upper limit of non-paged RAM
	print_a equ $10;					// print a character
	chan_open equ $1601;				// channel open

	org $6000

;	// print intro text

pr_text:
	ld a, 12;							// FF
	rst print_a;						// clear screen
	ld a, 2;							// select main screen
	call chan_open;						// select channel
	ld hl, text;						// point to text

pr_loop:
	ld a, (hl);							// get character
	and a;								// terminating byte?
	jr z, pr_lower;						// jump if so;
	rst print_a;						// print character
	inc hl;								// point to next character
	jr pr_loop;							// loop until done

pr_lower
	inc hl;								// next position
	push hl;							// stack pointer
	ld a, 1;							// select lower screen
	call chan_open;						// select channel
	pop hl;								// unstack pointer

pr_l_loop:
	ld a, (hl);							// get character
	and a;								// terminating byte?
	jr z, pr_key;						// jump if so;
	rst print_a;						// print character
	inc hl;								// point to next character
	jr pr_l_loop;						// loop until done

pr_key:
	ld a, $7f;							// high byte of I/O address
	in a, ($fe);						// read byte
	rra;								// set carry if space pressed
	jp c, pr_key;						// loop until space pressed

;	// original start

setup:
	xor a;								// LD A, 0;
	out ($fe), a;						// set default border
	ld a, %00011111;					// ROM 1, VID 1, RAM 7
	ld (reg), a
	ld bc, $7ffd;						// 128 paging
	out (c), a;							// set it
	ld a, %00000010;					// 8x1 attribute mode
	out ($ff), a;						// set it (SCLD)
	ld hl, fade_0 + 63;					// last entry @ 0% intensity
	call set_palette;					// make the screen black

startshow:
	ld hl, slide_no;					// address slide number (ASCII)
	ld a, '0';							// reset slide number
	ld (hl), a;							// to '00'
	inc hl;
	ld (hl), a;

	call show_slide;					// display slide 01
	call show_slide;					// display slide 02
	call show_slide;					// display slide 03

	call roll_text;						// do scroll

	call show_slide;					// display slide 04
	call show_slide;					// display slide 05
	call show_slide;					// display slide 06
	call show_slide;					// display slide 07
	call show_slide;					// display slide 08
	call show_slide;					// display slide 09

	ld hl, slide_no;					// address slide number (ASCII)
	ld a, '1';							// inccrement first ASCII digit
	ld (hl), a;							// to '00'
	inc hl;								// address second ASCII digit
	ld a, '0' - 1;						// will loop to '0'
	ld (hl), a;							// set it

	call show_slide;					// display slide 10
	call show_slide;					// display slide 11
	call show_slide;					// display slide 12

space:
	ld a, $7f;							// high byte of I/O address
	in a, ($fe);						// read byte
	rra;								// set carry if space pressed
	jp c, space;						// loop until space pressed
	jp startshow;						// back to the start

show_slide:
	ld hl, slide_no + 1;				// address second ASCII digit
	ld a, (hl);							// get it
	inc a;								// increment it
	ld (hl), a;							// write it back
	ld ix, slide;						// ASCIIZ filename
	call open;							// open file

	ld ix, $c000;						// offset 0 in frame buffer
	ld bc, 6144;						// byte count
	call load;							// load the 1st half of file

	ld ix, $e000;						// offset 1 in frame buffer
	ld bc, 6208;						// byte count
	call load;							// load the 2nd half of the file + palette
	call close;							// close file

	call fade;							// pre-fade the palette to black in 7 steps

	ld hl, fade_1 + 63;					// last entry @ 14% intensity
	call set_palette;					// set palette

	ld hl, fade_2 + 63;					// last entry @ 29% intensity
	call set_palette;					// set palette

	ld hl, fade_3 + 63;					// last entry @ 43% intensity
	call set_palette;					// set palette

	ld hl, fade_4 + 63;					// last entry @ 57% intensity
	call set_palette;					// set palette

	ld hl, fade_5 + 63;					// last entry @ 71% intensity
	call set_palette;					// set palette

	ld hl, fade_6 + 63;					// last entry @ 86% intensity
	call set_palette;					// set palette

	ld hl, fade_7 + 63;					// last entry @ 100% intensity
	call set_palette;					// set palette

	call pause;							// wait for key press

	ld hl, fade_6 + 63;					// last entry @ 86% intensity
	call set_palette;					// set palette

	ld hl, fade_5 + 63;					// last entry @ 71% intensity
	call set_palette;					// set palette

	ld hl, fade_4 + 63;					// last entry @ 57% intensity
	call set_palette;					// set palette

	ld hl, fade_3 + 63;					// last entry @ 43% intensity
	call set_palette;					// set palette

	ld hl, fade_2 + 63;					// last entry @ 29% intensity
	call set_palette;					// set palette

	ld hl, fade_1 + 63;					// last entry @ 14% intensity
	call set_palette;					// set palette

	ld hl, fade_0 + 63;					// last entry @ 0% intensity
	call set_palette;					// set palette

	ret;								// done

;	// subroutines

set_palette:
	ld c, $3b;							// palette port
	ld de, $00bf;						// d = data, e = register
	ld a, 64;							// becomes 63
	halt;								// wait for vblank

palette_loop:
	dec a;								// next register
	ld b, e;							// register port
	out (c), a;							// select register
	ld b, d;							// data port
	outd;								// dec b; out bc, (hl); dec hl
	and a;								// was that the last register?
	jr nz, palette_loop;				// set all 64 entries
;	ret;								// done

wait:
	ld a, (frame);						// get current frame value
	ld c, a;							// store it

wait2:
	ld a, (frame);						// get frame again
	cp c;								// has it changed?
	jr nz, wait2;						// loop until one frame passed
	halt;								// wait one more frame
	ret;								// return

pause:
	ld b, 180;							// frames/2 to wait

pause2:
	call wait;							// wait 2 frames
	djnz pause2;
	ret;								// done

load:
	ld a, (handle);						// file handle
	jp SEFileRead;						// exit via read file vector

fade:
	ld hl, $f800;						// source palette
	ld de, fade_7;						// 100% intensity palette
	ld bc, 64;							// byte count
	ldir;								// copy it

	ld ix, fade_7 + 63;					// last entry of 100% intensity palette

	ld b, 64;							// count
	call wo_blue;						// 1st pass

	ld b, 64;							// count
	call wi_blue;						// 2nd pass

	ld b, 64;							// count
	call wo_blue;						// 3rd pass

	ld b, 64;							// count
	call wi_blue;						// 4th pass

	ld b, 64;							// count
	call wo_blue;						// 5th pass

	ld b, 64;							// count
	call wi_blue;						// 6th pass

;	// the next part is already set to zeros

;	ld b, 64;							// count
;	call wo_blue;						// 7th pass

	ret;								// done

overflow:
	ret nc;		 						// return if no overflow
	xor a;							  	// else clear A
	ret;								// done

wo_blue:
	ld a, (ix);		 					// get entry
	and %11100000;	  					// isolate Green
	sub %00100000;	  					// reduce Green
	call overflow;	 					// test for overflow
	and %11100000;	  					// isolate Green
	ld c, a;							// Green to C

	ld a, (ix);							// get entry
	and %00011100;	  					// isolate Red
	sub %00000100;	  					// reduce Red
	call overflow;	  					// test for overflow
	and %00011100;	  					// isolate Red
	ld d, a;							// Red to D

	ld a, (ix);		 					// get entry
	and %00000011;	  					// isolate Blue

	add a, c;		   					// add Green
	add a, d;		   					// add Red
	ld (ix - 64), a;					// write to next palette set

	dec ix;			 					// next entry
	djnz wo_blue;	   					// do all 64 entrieas
	ret;								// done

wi_blue:
	ld a, (ix);		 					// get entry
	and %11100000;	  					// isolate Green
	sub %00100000;	  					// reduce Green
	call overflow;	  					// test for overflow
	and %11100000;	  					// isolate Green
	ld c, a;							// Green to C

	ld a, (ix);		 					// get entry
	and %00011100;	  					// isolate Red
	sub %00000100;	  					// reduce Red
	call overflow;	  					// test for overflow
	and %00011100;	  					// isolate Red
	ld d, a;							// Red to D

	ld a, (ix);		 					// get entry
	and %00000011;	  					// isolate Blue
	sub %00000001;	  					// reduce Blue
	call overflow;	  					// test for overflow
	and %00000011;	  					// isolate Blue
	ld e, a;							// Blue to E

	xor a;			  					// LD A, 0
	add a, c;		   					// add Green
	add a, d;		   					// add Red
	add a, e;		   					// add Blue
	ld (ix - 64), a;					// write to next palette set

	dec ix;			 					// next entry
	djnz wi_blue;	   					// do all 64 entrieas
	ret;								// done

roll_text:
	ld hl, back_buffer;					// source
	ld (hl), 0;							// clar it
    ld de, back_buffer + 1;		       	// destination
    ld bc, 6143;				        // byte count
    ldir;               				// clear it

	ld bc, $bf3b;						// palette port
	xor a;								// register 0 (first foreground value)
	out (c), a;							// select register
	ld a, $ff;							// bright white
	ld b, a;							// data port
	out (c), a;							// write palette entry

	call clear_screen;					// clear it

	ld a, %00011101;					// ROM 1, video 1, RAM 5
	ld bc, $7ffd;						// 128 paging
	out (c), a;							// set it

	call clear_screen;					// clear it

	ld ix, filename;					// point to data
	call open;							// open file for reading

skip_header:
	ld ix, $a7c2;						// 62 bytes before back buffer
	ld bc, 62;							// BMP header
	call load;							// read file	

main_loop:
	call scroll;						// scroll the back buffer up one pixel

	ld ix, $bfe0;						// last line of back buffer
	ld bc, 32;							// byte count
	call load;							// read file	

;	//  if end of file reached, BC will be 2
	dec bc;								// reduce BC
	dec bc;
	ld a, c;							// test for zero
	or b;
	jr z, close;						// exit if done

	ld a, (reg);						// get video / RAM page
	xor %00000010;						// change RAM page
	ld bc, $7ffd;						// 128 paging
	out (c), a;							// set it

    ld hl, $a800;       				// back buffer
    ld de, $c000;     					// currently paged out frame buffer
    ld bc, 6144;      					// byte count
    ldir;               				// copy it

	xor %00001000;						// chage video page
	ld (reg), a;						// store it
	ld bc, $7ffd;						// 128 paging

	halt;								// this should wait for a vblank

	out (c), a;							// set it

	halt;								// wait for a second vblank

	jp main_loop;						// do next line

;	// subroutines

close:
	ld a, (handle);						// get folder handle
	jp SEFileClose;						// exit via close file vector

scroll:
    ld ix, row_table;   				// table of addresses
    ld a, 191;          				// number of rows to copy

do_rows:
    ld e, (ix);         				// destination
    ld d, (ix + 1);
    ld l, (ix + 2);     				// source
    ld h, (ix + 3);
    ld bc, 32;          				// byte count
    ldir;               				// copy it
    inc ix;             				// advance 
    inc ix;             				// one row
    dec a;              				// reduce count
    and a;              				// test for zero
    jr nz, do_rows;     				// loop until done
	ret;

clear_screen:
	ld hl, $c000;						// source
	ld (hl), 0;							// clar it
	ld de, $c001;						// destination
	ld bc, 6143;						// byte count
	ldir;								// clear screen
	ld hl, $e000;						// source
	ld (hl), 0;							// clear it
	ld de, $e001;						// destination
	ld bc, 6143;						// byte count
	ldir;								// set attributes
	ret;

;	// file handling
open:
	call SEFileOpenExists;				// open file
	ld (handle), a;						// store file handle
	ret;								// end of subroutine

;	// back buffer lookup table
row_table:
    defw $a800, $a900, $aa00, $ab00, $ac00, $ad00, $ae00, $af00
    defw $a820, $a920, $aa20, $ab20, $ac20, $ad20, $ae20, $af20
    defw $a840, $a940, $aa40, $ab40, $ac40, $ad40, $ae40, $af40
    defw $a860, $a960, $aa60, $ab60, $ac60, $ad60, $ae60, $af60
    defw $a880, $a980, $aa80, $ab80, $ac80, $ad80, $ae80, $af80
    defw $a8a0, $a9a0, $aaa0, $aba0, $aca0, $ada0, $aea0, $afa0
    defw $a8c0, $a9c0, $aac0, $abc0, $acc0, $adc0, $aec0, $afc0
    defw $a8e0, $a9e0, $aae0, $abe0, $ace0, $ade0, $aee0, $afe0

    defw $b000, $b100, $b200, $b300, $b400, $b500, $b600, $b700
    defw $b020, $b120, $b220, $b320, $b420, $b520, $b620, $b720
    defw $b040, $b140, $b240, $b340, $b440, $b540, $b640, $b740
    defw $b060, $b160, $b260, $b360, $b460, $b560, $b660, $b760
    defw $b080, $b180, $b280, $b380, $b480, $b580, $b680, $b780
    defw $b0a0, $b1a0, $b2a0, $b3a0, $b4a0, $b5a0, $b6a0, $b7a0
    defw $b0c0, $b1c0, $b2c0, $b3c0, $b4c0, $b5c0, $b6c0, $b7c0
    defw $b0e0, $b1e0, $b2e0, $b3e0, $b4e0, $b5e0, $b6e0, $b7e0

    defw $b800, $b900, $ba00, $bb00, $bc00, $bd00, $be00, $bf00
    defw $b820, $b920, $ba20, $bb20, $bc20, $bd20, $be20, $bf20
    defw $b840, $b940, $ba40, $bb40, $bc40, $bd40, $be40, $bf40
    defw $b860, $b960, $ba60, $bb60, $bc60, $bd60, $be60, $bf60
    defw $b880, $b980, $ba80, $bb80, $bc80, $bd80, $be80, $bf80
    defw $b8a0, $b9a0, $baa0, $bba0, $bca0, $bda0, $bea0, $bfa0
    defw $b8c0, $b9c0, $bac0, $bbc0, $bcc0, $bdc0, $bec0, $bfc0
    defw $b8e0, $b9e0, $bae0, $bbe0, $bce0, $bde0, $bee0, $bfe0

slide:
	defb "slide_";						// filename for slide

slide_no:
	defb "01";
	defb ".scr", 0;

filename:
	defb "rolltext.bmp", 0;

reg:
	defb 0

handle:
	defb 0

;	// palette entries

fade_0:
	defs 64, 0;							// 0% intensity

fade_1 equ fade_0 + 64
fade_2 equ fade_1 + 64
fade_3 equ fade_2 + 64
fade_4 equ fade_3 + 64
fade_5 equ fade_4 + 64
fade_6 equ fade_5 + 64
fade_7 equ fade_6 + 64

text:
	defb "TITLES (Version 1.0)", 13;
 	defb "Copyright (C) 2023 Source Solutions, Inc.", 13;
	defb 13;
	defb "You can place a message here.", 13;
	defb 0;
	defb "PRESS SPACE TO CONTINUE", 0;

; MYMPLAY - Player for Chloe
; MSX - version by Marq/Lieves!Tuore & Fit 30.1.2000
;
; ZX Port of MSX v0.4
; 7/2/2000 - Zack <dom@jb.man.ac.uk>
;
; Notes:
;	ZX Version uses im2 (can't capture unlike on MSX)
;	AY Ports on ZX are
;		$BFFD - port select
;		$FFFD - data write
;
; Tune length is limited to ~26350 bytes (Not sure if we'd be 
; affected by contention if we locate at 24576 - working on emu!)
; If not affected than can have ~34540 bytes

	FRAG equ 128;						// Fragment size
	REGS equ 14;						// Number of PSG registers
	FBITS equ 7;						// Bits needed to store fragment offset
	table equ 65024;					// Where we put our im2 int table
	intjp equ 65021;					// Ye olde im2 jump

; MODULE psg

	org 32768;							// 

	exx;								// Starting values for procedure readbits
	ld e, 1;							// 
	ld d, 0;							// 
	ld hl, rows + 2;					// 
	exx;								// 

	ld hl, uncomp + FRAG;				// Starting values for the playing variables
	ld (dest1), hl;						// 
	ld (dest2), hl;						// 
	ld (psource), hl;					// 
	ld a, FRAG;							// 
	ld (played), a;						// 
	ld hl, 0;							// 
	ld (prows), hl;						// 

	call extract;						// Unpack the first fragment

	call setint;						// Set up the interrupts

mainloop:
	call extract;						// 

waitvb:
	ld a, (played);						// Wait until VBI has played a fragment
	or a;								//
	jr nz, waitvb;						//
	ld (psource), iy;					//
	ld a, FRAG;							//
	ld (played), a;						//
	call keypress;						//
	jr z, mainloop;						//
	call shutint;						//
	call shutup;						//
	ret; Goodbye!						//

; Unpack a fragment. Returns IY = new playing position for VBI
extract:
	xor a;								//

regloop:
	push af;							//
	ld c, a;							//
	ld b, 0;							//
	ld hl, regbits;						// D = Bits in this PSG register
	add hl, bc;							//
	ld d, (hl);							//
	ld hl, current;						// E = Current value of a PSG register
	add hl, bc;							//
	ld e, (hl);							//
	ld bc, FRAG	* 3;					// v0.4
	ld hl, (dest1);						// IX = Destination 1
	ld ix, (dest1);						//
	add hl, bc;							//
	ld (dest1), hl;						//
	ld hl, (dest2);						// HL = Destination 2
	push hl;							//
	add hl, bc;							//
	ld (dest2), hl;						//
	pop hl;								//
	ex af, af';							//
	ld a, FRAG;							// AF' = fragment end counter
	ex af, af';							//
	ld a, 1;							// Get fragment bit
	call readbits;						//
	or a;								//
	jr nz, compfrag;					// 1 = Compressed fragment,	0 = Unchanged
	ld b, FRAG;							// Unchanged fragment just set all to E

sweep:
	ld (hl), e;							//
	inc hl;								//
	ld (ix + 0), e;						//
	inc ix;								//
	djnz sweep;							//
	jp nextreg;							//

; Compressed fragment
compfrag:
	ld a, 1;							//
	call readbits;						//
	or a;								//
	jr nz, notprev;						// 0 = Previous register value,	1 = raw/compressed
	ld (hl), e;							// Unchanged register
	inc hl;								//
	ld (ix + 0), e;						//
	inc ix;								//
	ex af, af';							//
	dec a;								//
	ex af, af';							//
	jp nextbit;							//

notprev:
	ld a, 1;							//
	call readbits;						//
	or a;								//
	jr z, packed;						// 0 = compressed data	1 = raw data
	ld a, d;							// Raw data,	read regbits[i] bits
	call readbits;						//
	ld e, a;							//
	ld (hl), a;							//
	inc hl;								//
	ld (ix + 0), a;						//
	inc ix;								//
	ex af, af';							//
	dec a;								//
	ex af, af';							//
	jp nextbit;							//

packed:
	ld a, FBITS;						// Reference to previous data
	call readbits;						// Read the offset
	ld c, a;							//
	ld a, FBITS;						// Read the number of bytes
	call readbits;						//
	ld b, a;							//
	push hl;							//
	push bc;							//
	ld bc, - FRAG;						//
	add hl, bc;							//
	pop bc;								//
	ld a, b;							//
	ld b, 0;							//
	add hl, bc;							//
	ld b, a;							//
	push hl;							//
	pop iy;								// IY = source address
	pop hl;								//
	inc b;								//

copy:
	ld a, (iy + 0);						// Copy from previous data 
	inc iy;								//
	ld e, a;							// Set current value
	ld (hl), a;							//
	inc hl;								//
	ld (ix + 0), a;						//
	inc ix;								//
	ex af, af';							//
	dec a;								//
	ex af, af';							//
	djnz copy;							//

nextbit:
	ex af, af';							// If AF' = 0 then fragment is done
	ld c, a;							//
	ex af, af';							//
	ld a, c;							//
	or a;								//
	jp nz, compfrag;					//

nextreg:
	pop af;								//
	ld b, 0;							// Save the current value of PSG reg
	ld c, a;							//
	push hl;							//
	ld hl, current;						//
	add hl, bc;							//
	ld (hl), e;							//
	pop hl;								//
	inc a;								// Check if all registers are done
	cp REGS;							//
	jp nz, regloop;						//
	or a;								// Check if dest2 must be wrapped
	ld bc, rows;						//
	sbc hl, bc;							//
	jr nz, nowrap;						//
	ld ix, uncomp + FRAG;				//
	ld hl, uncomp + FRAG;				//
	ld iy, uncomp + (2	* FRAG);		//
	jr endext;							//

nowrap:
	ld ix, uncomp;						//
	ld hl, uncomp + (2	* FRAG);		//
	ld iy, uncomp + FRAG;				//

endext:
	ld (dest1), ix;						//
	ld (dest2), hl;						//
	ld bc, FRAG;						//
	ld hl, (prows);						//
	add hl, bc;							//
	ld (prows), hl;						//
	ld bc, (rows);						//
	or a;								//
	sbc hl, bc;							//
	jr c, noend;						// If rows>played rows then exit
	exx;								// Otherwise restart
	ld e, 1;							//
	ld d, 0;							//
	ld hl, rows + 2;					//
	exx;								//
	ld hl, 0;							//
	ld (prows), hl;						//

noend:
	ret;								//

; Reads A bits from data,	returns bits in A
readbits:
	exx;								//
	ld b, a;							//
	ld c, 0;							//

onebit:
	sla c;								// Get one bit at a time
	rrc e;								//
	jr nc, nonew;						// Wrap the AND value
	ld d, (hl);							//
	inc hl;								//

nonew:
	ld a, e;							//
	and d;								//
	jr z, zero;							//
	inc c;								//

zero:
	djnz onebit;						//
	ld a, c;							//
	exx;								//
	ret;								//

; The interrupt handler. Partially MSX specific
interrupt:
	push af;							//
	push bc;							//
	push de;							//
	push hl;							//
	ld hl, (psource);					//
	ld de, - 1 + (3	* FRAG);			// Bytes to skip before next reg - 1
	xor a;								//
	ld c, 253;							//

ploop:
	ld b, 255;							//
	out (c), a;							//
	ld b, 191;							//
	outi;								//
	inc a;								//
	add hl, de;							//
	cp REGS - 1;						//
	jp nz, ploop;						//
	ld a, (hl);							//
	inc a;								// if reg 13 = 255 skip
	jr z, notrig;						//
	ld a, 13;							//
	ld bc, 65533;						//
	out (c), a;							//
	ld b, 191;							//
	outi;								//

notrig:
	ld hl, (psource);					//
	inc hl;								//
	ld (psource), hl;					//
	ld a, (played);						//
	or a;								//
	jr z, endint;						//
	dec a;								//
	ld (played), a;						//

endint:
	pop hl;								//
	pop de;								//
	pop bc;								//
	pop af;								//
	ei;									//
	ret;								//

; Sets up the im2 table and switches mode
setint:
	di;									//
	ld hl, table;						//
	ld de, table + 1;					//
	ld bc, 256;							//
	ld (hl), 253;						//
	ldir;								//
	ld a, 195;							//
	ld (intjp), a;						//
	ld hl, interrupt;					//
	ld (intjp + 1), hl;					//
	ld a, 254;							//
	ld i, a;							//
	im 2;								//
	ei;									//
	ret;								//

; Turn off the interrupts,	go back to im 1 (default for ZX)
; Restore hl' so BASIC stays sane
shutint:
	di;									//
	ld a, 63;							//
	ld i, a;							//
	im 1;								//
	ld hl, 10072;						//
	exx;								//
	ei;									//
	ret;								//

; Returns Z = 1 if key pressed. ZX - specific
keypress:
	xor a;								//
	in a, (254);						//
	cpl;								//
	and 31;								//
	ret;								//

; Shuts down the audio. ZX - Specifc
shutup:
	ld e, 14;							//
	xor a;								//
	ld c, 253;							//
	ld d, 0;							//

shloop:
	ld b, 253;							//
	out (c), a;							//
	inc a;								//
	ld b, 191;							//
	out (c), d;							//
	dec e;								//
	jr nz, shloop;						//
	ret;								//

; Program data
played:
	defb 0;								// VBI counter

dest1:
	defw 0;								// Uncompress destination 1

dest2:
	defw 0;								// - " - 	2

psource:
	defw 0;								// Playing offset for the VB - player

prows:
	defw 0;								// Rows played so far

; Bits per PSG register
regbits:
	defb 8, 4, 8, 4, 8, 4, 5, 8, 5, 5, 5, 8, 8, 8;

; Current values of PSG registers
current:
	defb 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0;

; Reserve room for uncompressed data 
uncomp:
	defs (3 * FRAG * REGS);

; Tune is loaded to this address
rows:
	incbin "TITLE.MYM";					// title tune
