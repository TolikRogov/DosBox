;------------------------------------------------------------------------------
;				It is impossible to debug! SO...SI...DI...SS
;			@Rogov Anatoliy 25.02.2025 "When will I delete DOSBox?"
;------------------------------------------------------------------------------

video_segment 		= 0b800h							;video segment
window_len 			= 80								;window row length
window_height 		= 25								;window column height

.model tiny												;set 64 Kb model
.code													;define code block
org 100h												;prog's beginning ram block

Start:
	;==============================================================================================
	mov cx, 0ffffh
	inf_loop:
		mov ax, 1111h
		mov bx, 2222h
		mov cx, 3333h
		mov dx, 4444h
		in al, 60h
	loop inf_loop
	mov ax, 4c00h
	int 21h												;31 function of 21 interrupt

;------------------------------------------------------------------------------
; New procedural handler of 08h interrupt - timer
; Entry: 		None
; Exit: 		None
; Destroyed:	None
;------------------------------------------------------------------------------

New08h 	proc

	push ax bx cx dx si di ds es bp						;save all registers
	push cs												;cs in stack
	pop ds												;ds = cs

	cmp Active, 1										;if (Active == 1) zf = 1
	jne skip_activision									;if (zf != 1) goto skip_activision--|
		call MainBorder									;Main Border function				|
		jmp old_08h										;goto old_08h ----------------------|---|
	skip_activision:									;<----------------------------------|	|
														;										|
	old_08h:											;<--------------------------------------|
	pop bp es ds di si dx cx bx ax						;return all registers after interrupt
	db 0eah												;jump to old procedural handler of 09h interrupt
	old08ofs dw 0000h									;previous offset
	old08seg dw 0000h									;in that segment

	endp

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; New procedural handler of 09h interrupt
; Entry: 		None
; Exit: 		None
; Destroyed:	None
;------------------------------------------------------------------------------

New09h 	proc

	push ax bx cx dx si di ds es bp						;save all registers
	push cs												;cs in stack
	pop ds												;ds = cs

	in al, 60h											;al = scan code from 60h port
	cmp al, 58h											;if (al == F12) zf = 1
	jne skip_open										;if (zf != 1) goto skip_open ---|
		call MainBorder									;Main Border function			|
		jmp old											;got old ---------------------------|
	skip_open:											;<------------------------------|	|
														;									|
	cmp al, 0dh											;if (al == '=') zf = 1				|
	jne skip_close										;if (zf != 1) goto skip_close --|	|
		;call CloseFrame									;Close Frame function			|	|
		jmp old											;goto old ----------------------|	|
	skip_close:											;<------------------------------|	|
														;									|
	old:												;<----------------------------------|

	pop bp es ds di si dx cx bx ax						;return all registers after interrupt
	db 0eah												;jump to old procedural handler of 09h interrupt
	old09ofs dw 0000h									;previous offset
	old09seg dw 0000h									;in that segment

	endp

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Close frame
; Entry:		Active - frame status: 1 - opened, 0 - closed
; Exit:			None
; Destroyed:	AX, Active
;------------------------------------------------------------------------------

CloseFrame	proc

	cmp Active, 1										;if (Active == 1) zf = 1
	jne closing											;if (zf != 1) goto closing

	push ax bx cx dx bp si es
	call CalcParam
	mov dh, height
	mov dl, len

	mov bx, video_segment
	mov es, bx

	mov si, di
	xor cx, cx
	mov cl, dh
	outside_close:
		xor ax, ax
		mov al, dh
		sub al, cl
		push dx
		mul dl
		pop dx

		push cx

		xor cx, cx
		mov cl, dl
		xor bp, bp

		push si
		inside_close:
			;bp = &Buffer + (dh - cl) * dl + (dl - cx)
			push dx
			xor dh, dh
			mov bp, dx
			pop dx
			sub bp, cx
			;shl bp, 2
			add bp, ax
			add bp, offset Buffer
			mov bx, [bp]
			mov es:[si], bx
			add si, 2
		loop inside_close

		pop si
		add si, 2 * window_len

		pop cx
	loop outside_close

	pop es si bp dx cx bx ax
	mov Active, 0										;Active = 0

	closing:
	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Main program to view frame
; Entry:		None
; Exit:			None
; Destroyed:	AX, ES, DX, DI
;------------------------------------------------------------------------------

MainBorder	proc

	mov di, video_segment								;bx = video segment position
	mov es, di											;es = bx
	xor di, di											;di = 0

	call CalcParam										;x_start, y_start, y_string
	mov ah, frame_color									;ah = 4eh 	| color
	mov si, offset DoubleFrameString					;si = &style string

	mov dh, height										;dh = height
	mov dl, len											;dl = len

	cmp Active, 1
	je skip_memory
		call RememberToBuffer								;Remember video ram to buffer
	skip_memory:

	call DrawFrame										;Drawing frame
	call DrawString										;Drawing string inside frame

	mov Active, 1										;Active = 1

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Save video fragments under the future frame
; Entry:		DI
;				DL
;				DH
; Exit:
; Destroyed:
;------------------------------------------------------------------------------

RememberToBuffer proc

	push ax bx cx dx bp si es

	mov bx, video_segment
	mov es, bx

	mov si, di
	xor cx, cx
	mov cl, dh
	outside:
		xor ax, ax
		mov al, dh
		sub al, cl
		push dx
		mul dl
		pop dx

		push cx

		xor cx, cx
		mov cl, dl
		xor bp, bp

		push si
		inside:
			;bp = &Buffer + (dh - cl) * dl + (dl - cx) * 2
			push dx
			xor dh, dh
			mov bp, dx
			pop dx
			sub bp, cx
			add bp, ax
			shl bp, 1
			add bp, offset Buffer

			mov bx, es:[si]
			mov [bp], bx
			add si, 2
		loop inside

		pop si
		add si, 2 * window_len

		pop cx
	loop outside

	pop es si bp dx cx bx ax

	ret												;return function value
	endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Convert hex to ascii code
; Entry:		AL - converted symbol
; Exit:			AL - result of converting
; Destroyed:	AL
;------------------------------------------------------------------------------

htoa	proc

	cmp al, 10											;if (al - 10 < 0) zs = 1
	jae letter											;if (zs == 0) goto letter --|
	jb digit											;if (zs == 1) goto digit ---|-|
														;							| |
	letter:												;<--------------------------| |
		add al, 'A' - 10								;al += 'A' - 10				  |
		jmp ending										;-----------------------------|-|
	digit:												;<----------------------------|	|
		add al, '0'										;al += '0'						|
		jmp ending										;-------------------------------|
														;							 	|
	ending:												;<------------------------------|
	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Print register value
; Entry:		BX - right offset on register in stack segment
; Exit:			None
; Destroyed:	AL
;------------------------------------------------------------------------------

RegVal	proc

	push cx												;save cx - amount of symbols in register name
	push bx												;save bx - right offset of register in stack segment
	mov cx, 0002h										;cx = 0002h

	half:												;<------------------------------|
		sub bx, cx										;bx -= cx						|
		add bx, 2										;bx += 2						|
														;|----|----|					|
		mov al, ss:[bx]									; high low | al = low			|
		shr al, 4										;al /= 16						|
		call htoa										;hex al to ascii				|
		stosw											;mov es:[di], ax / add di, 2	|
														;|----|----|					|
		mov al, ss:[bx]									; high low | al = high			|
		and al, 0fh										;al && 00001111h				|
		call htoa										;hex al to ascii				|
		stosw											;mov es:[di], ax / add di, 2	|
	loop half												;-------------------------------|

	pop bx												;return bx
	pop cx												;return cx

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Print information about one register
; Entry:		SI - address of string to current register name
;				DI - place on the screen where will be register value
; Exit:			None
; Destroyed:	DI, SI, AL
;------------------------------------------------------------------------------

OneRegister	proc

	push di												;save di - previous offset on screen
	push cx												;save cx - loop counter for all registers

	mov cx, 0003h										;cx = 3 | amount of symbols in any register name: 'xx '

	register_name:										;<------------------------------|
		lodsb											;mov al, ds:[si]				|
		stosw											;mov es:[di], ax / add di, 2	|
	loop register_name									;-------------------------------|
	inc si												;si += 1

	call RegVal											;print register value

	pop cx												;return cx
	pop di												;return di
	add di, 0002h * window_len							;di += 80 * 2

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draw registers inside the frame
; Entry:		SI - first register name string address
; Exit:			None
; Destroyed:	CX, AX, BX
;------------------------------------------------------------------------------

DrawString	proc

	push bp												;save bp
	mov bp, offset AXString								;bp = &AXString
	mov si, bp											;si = bp
	pop bp												;return bp

	push cx												;save cx
	mov cx, 0007h										;cx = 0007h | register name len (3) + register value (4)
	call EvalShift										;calculate first inside string position
	pop cx												;return cx

	mov cx, reg_in_frame								;cx = 8 	| amount registers in frame

	push ax												;save ax
	mov bx, sp											;bx = sp
	xor ax, ax											;ax = 0
	mov ax, reg_in_frame								;ax = 8
	shl ax, 1											;ax *= 2
	add bx, ax											;bx += ax - pointer on ax register in stack
	pop ax												;return ax

	all_registers:										;<------------------------------|
		call OneRegister								;Print one register information	|
		sub bx, 0002h									;bx -= 0002h - next register	|
	loop all_registers									;-------------------------------|

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Calculate values of variables: x_start, y_start, y_string
; Entry:		None
; Exit:			None
; Destroyed:	AX, BX, DX, BP
;------------------------------------------------------------------------------

CalcParam	proc

	push ax												;save ax
	xor ah, ah											;ah = 0
	mov al, len											;al = len
	mov dl, height										;dl = height
	mov x_start, window_len / 2							;x_start = 40
	shr ax, 1											;ax /= 2
	sub x_start, al										;x_start -= len / 2
	pop ax												;return ax

	mov bl, window_height / 2							;bp = 25 / 2
	mov y_start, bl										;y_start = 25 / 2
	shr dx, 1											;dx /= 2
	sub y_start, dl										;y_start -= height / 2

	mov bl, y_start										;bp = y_start
	inc bl												;bl += 1
	mov y_string, bl									;y_string = y_start + 1

	xor di, di											;di = 0;

	xor ah, ah											;ah = 0
	mov al, y_start										;al = y_start
	shl al, 1											;al *= 2
	mov bp, window_len									;bp = 80
	push dx												;save size of frame in stack
	mul bp												;ax = 2 * y_start * 80
	pop dx												;return size of frame from stack to dx
	mov di, ax											;di = ax
	mov al, x_start										;ax = x_start
	shl al, 1											;ax *= 2
	xor ah, ah											;ah = 0
	add di, ax											;di += 2 * x_start

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Eval shift of frame inside string
; Entry:		CX = string length
; Exit:			None
; Destroyed:	DI, BP, AX, BX
;------------------------------------------------------------------------------

EvalShift	proc

	push ax bx bp										;save ax bx bp

	;di = y_string * window_len * 2 + (x_start + (cx - len) / 2) * 2
	mov al, y_string									;al = y_string
	shl al, 1											;al *= 2
	xor ah, ah											;ah = 0
	mov bp, window_len									;bp = 80
	push dx												;save size of frame in stack
	mul bp												;ax = 2 * y_start * 80
	pop dx												;return size of frame from stack to dx≈
	mov di, ax											;di = ax

	xor ah, ah											;ah = 0
	xor bh, bh											;bh = 0
	mov al, x_start										;al = x_start
	mov bp, offset len									;bp = &len
	mov bl, len											;bl = len
	sub bl, cl											;bl -= cl
	shr bl, 1											;bl = (cx - len) / 2
	add al, bl											;x_start += (cx - len) / 2
	shl al, 1											;al *= 2
	add di, ax											;di += al

	shr di, 1											;di /= 2
	shl di, 1											;di *= 2

	pop bp bx ax										;return bp bx ax

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Eval string length with '$' terminal symbol
; Entry: 		SI = data string address
; Exit:			CX
; Destroyed:	SI, AL, CX
;------------------------------------------------------------------------------

StrLen	proc

	str_len:											;<------------------------------|
		lodsb											;mov al, ds:[si]				|
		cmp al, '$'										;if (al == '$') zf = 1			|
		jz end_str_len									;if (zf == 1) goto end_str_len	|
		add cx, 2										;cx += 2						|
	loop str_len										;-------------------------------|
	end_str_len:										;label of str len ending

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draw frame with size: len, height
; Entry: 		SI = data string address
;				DH = frame height
;				DL = frame len
; Exit:			None
; Destroyed:	BX, CX, DI
;------------------------------------------------------------------------------

DrawFrame	proc

	push ax bx cx dx si di bp							;save ax bx cx dx si di bx

	call PrintString									;print string

	mov cl, dh											;loop on length of frame string
	xor ch, ch											;ch = 0
	sub cx, 2											;without first and lsat symbols of string
	cycle1:												;<--------------------------|
		add di, window_len * 2							;di += window_len * 2		|
		call PrintString								;print string				|
		sub si, 3										;si -= 3					|
	loop cycle1											;---------------------------|
	add si, 3											;si += 3

	add di, window_len * 2								;di += window_len * 2 (next line)
	call PrintString									;print string

	pop bp di si dx cx bx ax							;return bp di si dx cx bx ax

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draws string to console in format: s1s2....s2s3
; Entry: 		SI = string address
;				DL = string len
; Exit:			None
; Destroyed:	AX, BX, CX, SI
;------------------------------------------------------------------------------

PrintString	proc

	mov ah, frame_color									;set symbols color

	lodsb												;mov al, ds:[si]
	stosw												;mov es:[di], ax / add di, 2

	push cx												;save prev loop cnt
	xor cx, cx											;cx = 0
	mov cl, dl											;counter = dl
	sub cl, 2											;without top and bottom line
	mov al, [si]										;al = [si]
	cycle:												;<------------------------------|
		stosw											;mov es:[di], ax / add di, 2	|
	loop cycle											;-------------------------------|
	inc si												;bx++
	pop cx												;return prev loop cnt

	lodsb												;mov al, ds:[si]
	stosw												;mov es:[di], ax / add di, 2

	mov bl, dl											;bl = dl
	xor bh, bh											;bh = 0
	shl bx, 1											;bx *= 2
	sub di, bx											;set di to line beginning

	ret													;return function value
	endp												;proc's ending

;------------------------------------------------------------------------------

len 				db 31								;frame row length
height 				db 10								;frame column height
frame_color 		db 4eh								;frame element color

x_start 			db 0								;x frame start position
y_start 			db 0								;y frame start position
y_string 			db 0								;y string start position
reg_in_frame		equ 8								;amount of registers in frame
Active				db 0								;frame status

DoubleFrameString 	db 0c9h, 0cdh, 0bbh, 0bah, 020h, 0bah, 0c8h, 0cdh, 0bch
Buffer dw 31 * 10 dup (0)

AXString 			db "ax $"							;registers names
BXString 			db "bx $"
CXString 			db "cx $"
DXString 			db "dx $"
SIString 			db "si $"
DIString 			db "di $"
DSString 			db "ds $"
ESString 			db "es $"

EOP:
end 	Start											;prog's ending
