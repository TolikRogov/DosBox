;------------------------------------------------------------------------------------------------------------------
;This program is the third version of resident and it draw frame if key == ESC
;------------------------------------------------------------------------------------------------------------------
;                                        program

.model tiny   ;64 kilobytes in RAM, address == 16 bit == 2 bytes (because: sizeof (register) == 2 bytes)

;--------------------------------------------------------------------------------------------------------------
;										main program
;--------------------------------------------------------------------------------------------------------------

.code         ;begin program
org 100h      ;start == 256:   jmp start == jmp 256 != jmp 0 (because address [0;255] in program segment in DOS for PSP)
start:
	xor ax, ax
	mov es, ax       ;es = 0

	mov bx, 0009h*4  ;bx = address on 9th interrupt
	int 09h          ;call old 9th interrupt

	mov ax, es:[bx]
	mov address_of_old_9th_interrupt, ax  ;save address of old 9th interrupt

	mov ax, es:[bx+2]
	mov segment_of_old_9th_interrupt, ax  ;save segment of old 9th interrupt

	cli     ;CPU cannot work with interrupts

	mov es:[bx], offset new_9th_interrupt    ;es:[bx] = address on new 9th interrupt

	push cs
	pop ax     ;ax = cs (segment of our code and code with new 9th interrupt)

	mov es:[bx+2], ax    ;es:[bx+2] in table with interrupts = cs (segment address, where is code with new 9th interrupt)

	sti       ;CPU can work with interrupts

	int 09h   ;call new 9th interrupt

	mov ax, 3100h       ;complete program, return 00h and save code in RAM from segment address in PSP in quantity = dx * 16 bytes

	mov dx, offset end_of_program
	shr dx, 4
	inc dx               ;dx = (address of program's end)/16 + 1

	int 21h              ;call 21th interrupt  (end work of CPU)
;--------------------------------------------------------------------------------------------------------------




















;--------------------------------------------------------------------------------------------------------------
;											 new_9th_interrupt
;Has code for new 9th interrupt, that can print key in video memory and after calls old 9th interrupt
;Entry: None
;
;Exit:  None
;
;Destr: None
;--------------------------------------------------------------------------------------------------------------

new_9th_interrupt proc

	push ax bx cx dx si di ds es
	push cs
	pop ds     ;ds = cs

	in al, 60h   ;al = scan code of last key from 60th port
	cmp al, 02d
	jne check_for_delete_frame       ;if (al != scan_code_of_hot_key): goto check_for_delete_frame
		call sosi
		jmp do_old_9th_interrupt       ;end print frame
	check_for_delete_frame:

	do_old_9th_interrupt:           ;skip new_9th_interrupt

	pop es ds di si dx cx bx ax
	db 0eah
	address_of_old_9th_interrupt dw 0000h
	segment_of_old_9th_interrupt dw 0000h    ;jmp segment_of_old_9th_interrupt:[address_of_old_9th_interrupt]    (call old 9th interrupt)

	endp
;--------------------------------------------------------------------------------------------------------------












;--------------------------------------------------------------------------------------------------------------
;											 count_left_high_point
;Count coordinates of left high point of frame
;
;Entry: x_size = horizontal size of frame
;		y_size = vertical   size of frame
;
;Exit:  di = address in video memory for left high of frame
;
;Destr: ax = calculations
;		bx = logical  left coordinate
;       cx = logical  high coordinate
;       si = physical left address
;       di = physical high address and address of point in video memory
;--------------------------------------------------------------------------------------------------------------

sosi proc

	mov di, 0b800h     ;video segment
	mov es, di         ;register es for segment address of video memory  (es != const    es == reg)

	call count_left_high_point

	push di   ;save di for print registers

	mov ah, color     ;ah = color

	mov si, offset frame_style  ;si = address on style of frame

	mov cx, x_size
	sub cx, 0002d     ;cx = x_size - 2 = len of str with recurring symbol

	call print_frame

    mov si, offset list_of_registers    ;si = address on list of registers

	pop di
	add di, 0080d * 0002d + 0002d * 0002d  ;di == address of beginning

	mov cx, quantity_of_registers   ;cx = how many registers program must print

	mov bx,  sp
	add bx, 0002d        ;bx = sp + quantity_of_registers * 0002d   - by this address in stack on ax. After on bx, cx, dx, ..., es

	print_next_register:
	call print_list_of_reg

	sub bx, 0002d                 ;address in stack for value next register

	loop print_next_register      ;while (cx--) {print_next_register ();s}

	ret
	endp
;--------------------------------------------------------------------------------------------------------------

















;--------------------------------------------------------------------------------------------------------------
;											 count_left_high_point
;Count coordinates of left high point of frame
;
;Entry: x_size = horizontal size of frame
;		y_size = vertical   size of frame
;
;Exit:  di = address in video memory for left high of frame
;
;Destr: ax = calculations
;		bx = logical  left coordinate
;       cx = logical  high coordinate
;       si = physical left address
;       di = physical high address and address of point in video memory
;--------------------------------------------------------------------------------------------------------------

count_left_high_point proc

	;center point:   0080d*(0008d)*0002d + 0002d*(0038d)

	mov ax, x_size
	shr ax, 1
	mov bx, x_center
	sub bx, ax       ;bx = 0038d - x_size / 2

	mov ax, 0002d
	mul bx
	mov	si, ax       ;si = 0002d * bx = 0002d * (0038d - x_size / 2)   - left point

	mov ax, y_size
	shr ax, 1
	mov cx, y_center
	sub cx, ax        ;cx = 0008d - y_size / 2

	mov ax, 0160d
	mul cx
	mov di, ax        ;di = cx * 0160d = 0002d * 0080d * (0008d - y_size / 2)   - high point

	add di, si        ;di = 0002d*0080d*(0008d - y_size / 2) + 0002d*(0038d - x_size / 2) - left high point in Video memory

	ret
	endp
;--------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------
;											 print_frame
;Draws frame x_size * y_size in frame_style and color
;
;Entry: ah = color
;		cx = x_size - 2 = len of str with recurring symbol
;		si = address on line with style / on the first set of symbols (for the first line)
;		di = address of point in video memory (in video segment)
;		es = segment address of video memory
;
;Exit: None
;
;Destr: dx = index of lines
;		si = address on different sets of symbols from line with style
;--------------------------------------------------------------------------------------------------------------

print_frame proc
	mov dx, y_size        ;dx - index of line  (max value = y_size, step = -1, min value = 0)

	call print_line       ;draw the first line of frame with the first set of symbols
	dec dx

	print_new_line:       ;for (bx = y_size - 1; bx > 1; bx--) {printf ("%s\n", middle_line);}

		push si           ;save address on the second set of symbols (for the middle lines)
		call print_line   ;draw the middle line
		dec dx
		pop si

		cmp dx, 1d
		jnz print_new_line

	add si, 3            ;address on the third set of symbols (for the last line)

	call print_line      ;draw the last line of frame
	dec dx

	ret
	endp
;--------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------
;											 print_line
;Draws one line with someone set of symbols

;Entry: cx = x_size - 2 = len of str with recurring symbol
;		ah = color
;		di = address of point in video memory (in video segment)
;		si = address on set of symbols
;
;Exit:  None
;
;Destr: al = symbol
;		di = shifting address of point in video memory (in video segment)
;		si = shifting address on set of symbols
;--------------------------------------------------------------------------------------------------------------

print_line proc

	push cx      ;save len of str with recurring symbol

	lodsb				;mov al, ds:[si]    ;al = the first symbol in set
						;inc si

	stosw				;mov word ptr es:[di], ax   ;put symbol and his color (ax) in video memory by address = es[di]
						;add di, 2

	lodsb				;mov al, ds:[si]    ;al = the second symbol in set
						;inc si

	next_symbol:

	stosw		;mov word ptr es:[di], ax
				;add di, 2

	loop next_symbol   ; while (cx--) {printf ("%c", ax);}    //ax = second symbol with color

	lodsb		;mov al, ds:[si]     ;al = the third symbol in set
				;inc si

	stosw		;mov word ptr es:[di], ax
				;add di, 2

	pop cx

	add di, 80d * 2d
	sub di, x_size
	sub di, x_size      ;count new address of new line in frame <==> '\n'

	ret
	endp
;--------------------------------------------------------------------------------------------------------------




































;--------------------------------------------------------------------------------------------------------------
;											 print_list_of_reg
;Print value of register in frame
;
;Entry: ah = color
;		di = address of point in video memory (in video segment)
;		si = address on list of registers
;       bx = address in stack for value of register
;       ss = segment address of stack
;       es = segment address of video memory
;
;Exit:  di = di + 0080d*0002d ('\n')
;       si = address on new name of register
;
;Destr: al = symbol
;		di = shifting address of point in video memory (in video segment)
;		si = shifting address on set of symbols in names of all registers
;--------------------------------------------------------------------------------------------------------------

print_list_of_reg proc

	push di
	push cx     ;old cx = index_for_registers_in_list, new cx = index_for_symbols_in_name => save cx

	mov cx, quantity_symbols_in_name_of_register

	next_symbol_in_name_of_register:

	lodsb							;mov al, ds:[si]    ;al = the symbol in register's name from list of registers
									;inc si

	stosw							;mov word ptr es:[di], ax   ;put symbol and his color (ax) in video memory by address = es[di]
									;add di, 2

	loop next_symbol_in_name_of_register

	;-----------------------------------------------------------------------------------------------------------
	;print("%c%c = ", name_register[0], name_register[1]);

	call print_value_reg  ;print value of register

	pop cx

	pop di
	add di, 0080d*0002d  ;di = di + 0080d*0002d ('\n')

	ret
	endp
;--------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------
;											 print_value_reg
;Print value of register in frame
;
;Entry: ah = color
;		bx = address in stack for value of register
;		ss = segment address of stack
;		di = address of point in video memory (in video segment)
;       es = segment address of video memory
;
;Exit:  None
;
;Destr: al = symbol
;		di = shifting address of point in video memory (in video segment)
;
;--------------------------------------------------------------------------------------------------------------
print_value_reg proc                                      ;register =  |_ _ _ _ | _ _ _ _ | _ _ _ _ | _ _ _ _|
;																	   |  high     lou    |  high      lou   |
;																	   |                  |                  |
;                                                                      |____high half_____|____lou half______|

	mov al, ss:[bx]    ;al = lou half of register

	shr al, 4          ;high half in al

	call translate_value_in_al_to_ascii     ;al = ascii of print_number

	stosw			;mov word ptr es:[di], ax   ;put symbol and his color (ax) in video memory by address = es[di]
					;add di, 2

	;------------------------------------------------------------------------------------------------------------------------

	mov al, ss:[bx]    ;al = lou half of register

	and al, 0Fh        ;lou half in al

	call translate_value_in_al_to_ascii    ;al = ascii of print_number

	stosw			;mov word ptr es:[di], ax   ;put symbol and his color (ax) in video memory by address = es[di]
					;add di, 2

	;------------------------------------------------------------------------------------------------------------------------

	mov al, ss:[bx+1]    ;al = high half of register

	shr al, 4            ;high half in al

	call translate_value_in_al_to_ascii       ;al = ascii of print_number

	stosw			;mov word ptr es:[di], ax   ;put symbol and his color (ax) in video memory by address = es[di]
					;add di, 2

	;------------------------------------------------------------------------------------------------------------------------

	mov al, ss:[bx+1]    ;al = high half of register

	and al, 0Fh          ;lou half in al

	call translate_value_in_al_to_ascii       ;al = ascii of print_number

	stosw			;mov word ptr es:[di], ax   ;put symbol and his color (ax) in video memory by address = es[di]
					;add di, 2

	ret
	endp

;--------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------
;											 translate_value_in_al_to_ascii
;Take value from al and translate it in symbol in ascii (For example: 1 -> '1', 10 -> 'a')
;
;Entry: al = value of print_number
;
;Exit:  al = ascii of print_number
;
;Destr: al = number -> ascii
;
;--------------------------------------------------------------------------------------------------------------
translate_value_in_al_to_ascii proc

	cmp al, 0010d
	js al_is_number

	;al_is_latter:
	sub al, 0010d
	add al, 'a'
	ret

	al_is_number:
	add al, '0'
	ret

	endp

;--------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------
;                                      variables
.data
color db 01011011b
	    ;bBBBFFFF	b == blink;  B == back ground;  F == for ground
	    ; rgbIRGB	r/R == red;  g/G == green;  b/B == blue;  I == increase

scan_code_of_hot_key_for_print_frame db 02d    ;hot key for print frame  == '1'
scan_code_of_hot_key_for_delete_frame db 03d   ;hot key for delete frame == '2'

x_size dw 0036d   ;horizontal sizes of frame
y_size dw 0014d   ;vertical   sizes of frame


;center point:   0080d*(0008d)*0002d + 0002d*(0038d)
x_center dw 0038d
y_center dw 0010d

frame_style db '         '

quantity_symbols_in_name_of_register dw 0005d
quantity_of_registers dw 0008d

list_of_registers db 'ax = bx = cx = dx = si = di = ds = es = '

;--------------------------------------------------------------------------------------------------------------

;--------------------------------------------------------------------------------------------------------------
end_of_program:
end start              ;end of asm and address of program's beginning

;list of colors:
;01011011 = blue symbols on violet background
