;------------------------------------------------------------------------------
;				It is impossible to debug! SO...SI...DI...SS
;			@Rogov Anatoliy 25.02.2025 "When will I delete DOSBox?"
;------------------------------------------------------------------------------

video_segment 		= 0b800h								;video segment
window_len 			= 80									;window row length
window_height 		= 25									;window column height

.model tiny													;set 64 Kb model
.code														;define code block
org 100h													;prog's beginning ram block

Start:	xor ax, ax											;ax = 0
		mov es, ax											;es = 0
		mov bx, 09h * 4										;bx = &int 09h

		mov ax, es:[bx]										;ax = old09h offset
		mov old09ofs, ax									;old09fs = ax
		mov ax, es:[bx + 2]									;ax = old09h segment
		mov old09seg, ax									;old09seg = ax

		cli													;clear interrupt flag

		mov es:[bx], offset New09h							;change 09h interrupt function by mine
		mov ax, cs											;ax = cs
		mov es:[bx + 2], ax									;current segment

		sti													;set interrupt flag

		mov ax, 3100h										;make program resident
		mov dx, offset EOP									;dx = &EOP
		shr dx, 4											;dx /= 4
		inc dx												;dx += 1
		int 21h												;31 function of 21 interrupt

;------------------------------------------------------------------------------
; New procedural handler of 09h interrupt
; Entry: 		None
; Exit: 		None
; Destroyed:	None
;------------------------------------------------------------------------------

New09h 	proc
		push ax bx cx dx si di ds es						;save all registers
		push cs												;cs in stack
		pop ds												;ds = cs

		in al, 60h											;al = scan code from 60h port
		cmp al, 58h											;if (al == F12) zf = 1
		jne skip											;if (zf != 1) goto skip --------|
			call MainBorder									;Main Border function			|
		skip:												;<------------------------------|

		;say that ready to input new button by blink the bit
		in al, 61h											;al = value from 61h keyboard port
		mov ah, al											;ah = al
		or al, 80h											;set the highest bit
		out 61h, al											;out al to 61h keyboard port
		mov al, ah											;al = ah
		out 61h, al											;out al to 61h keyboard port

		mov al, 20h											;non-specific end of interrupt
		out 20h, al											;interrupt controller port

		pop es ds di si dx cx bx ax							;return all registers after interrupt
		 	db 0eah											;jump to old procedural handler of 09h interrupt
old09ofs 	dw 0											;previous offset
old09seg 	dw 0											;in that segment
		endp

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Main program to view frame
; Entry:		None
; Exit:			None
; Destroyed:	AX, CX, BX, ES, DX, DI
;------------------------------------------------------------------------------

MainBorder	proc

			xor ax, ax										;ax = 0
			xor cx, cx										;cx = 0

			mov bx, video_segment							;bx = video segment position
			mov es, bx										;es = bx

			call CalcParam									;x_start, y_start, y_string

			mov dh, height									;dh = height
			mov dl, len										;dl = len
			xor di, di										;di = 0;
			call DrawFrame									;Drawing frame
			call DrawString									;Drawing string inside frame

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

		half:												;
			sub bx, cx
			add bx, 2

			mov al, ss:[bx]
			shr al, 4
			call htoa
			stosw

			mov al, ss:[bx]
			and al, 0fh
			call htoa
			stosw
		loop half

		pop bx
		pop cx

		ret												;return function value
		endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Print information about one register
; Entry:		SI - address of string to current register name
;				DI - place on the screen where will be register value
; Exit:			None
; Destroyed:	DI, SI, AL
;------------------------------------------------------------------------------

OneRegister	proc

			push di
			push cx

			mov cx, 0003h

			register_name:
				lodsb
				stosw
			loop register_name
			inc si

			call RegVal

			pop cx
			pop di
			add di, 0002h * window_len

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draw registers inside the frame
; Entry:		SI - first register name string address
; Exit:			None
; Destroyed:	CX, AX, BX
;------------------------------------------------------------------------------

DrawString	proc

			mov cx, 0007h
			call EvalShift
			mov cx, reg_in_frame
			mov ah, 4eh

			push ax
			mov bx, sp
			xor ax, ax
			mov ax, reg_in_frame
			shl ax, 1
			add bx, ax										;????????? ?? ax ? ?????
			pop ax

			all_registers:
				call OneRegister
				sub bx, 0002h
			loop all_registers

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Calculate values of variables: x_start, y_start, y_string
; Entry:		None
; Exit:			None
; Destroyed:	AX, BX, DX, BP
;------------------------------------------------------------------------------

CalcParam	proc

			mov al, len										;al = len
			mov dl, height									;dl = height
			mov bl, window_len / 2							;bp = 80 / 2
			mov x_start, bl									;x_start = 40
			shr ax, 1										;ax /= 2
			sub x_start, al									;x_start -= len / 2

			mov bl, window_height / 2						;bp = 25 / 2
			mov y_start, bl									;y_start = 25 / 2
			shr dx, 1										;dx /= 2
			sub y_start, dl									;y_start -= height / 2

			mov bl, y_start									;bp = y_start
			inc bl											;bl += 1
			mov y_string, bl								;y_string = y_start + 1

			mov si, offset DoubleFrameString				;si = &style string

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Eval shift of frame inside string
; Entry:		CX = string length
; Exit:			None
; Destroyed:	DI, BP, AX, BX
;------------------------------------------------------------------------------

EvalShift	proc

			;di = y_string * window_len * 2 + (x_start + (cx - len) / 2) * 2
			mov al, y_string								;al = y_string
			shl al, 1										;al *= 2
			xor ah, ah										;ah = 0
			mov bp, window_len								;bp = 80
			push dx											;save size of frame in stack
			mul bp											;ax = 2 * y_start * 80
			pop dx											;return size of frame from stack to dxâ‰ˆ
			mov di, ax										;di = ax

			xor ah, ah										;ah = 0
			xor bh, bh										;bh = 0
			mov al, x_start									;al = x_start
			mov bp, offset len								;bp = &len
			mov bl, len										;bl = len
			sub bl, cl										;bl -= cl
			shr bl, 1										;bl = (cx - len) / 2
			add al, bl										;x_start += (cx - len) / 2
			shl al, 1										;al *= 2
			add di, ax										;di += al

			shr di, 1										;di /= 2
			shl di, 1										;di *= 2

			ret												;return function value
			endp											;proc's ending

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

			mov al, y_start									;al = y_start
			shl al, 1										;al *= 2
			mov bp, window_len								;bp = 80
			push dx											;save size of frame in stack
			mul bp											;ax = 2 * y_start * 80
			pop dx											;return size of frame from stack to dx
			mov di, ax										;di = ax
			mov al, x_start									;ax = x_start
			shl al, 1										;ax *= 2
			xor ah, ah										;ah = 0
			add di, ax										;di += 2 * x_start
			call PrintString								;print string

			mov cl, dh										;loop on length of frame string
			xor ch, ch										;ch = 0
			sub cx, 2										;without first and lsat symbols of string
			cycle1:											;<--------------------------|
				add di, window_len * 2						;di += window_len * 2		|
				call PrintString							;print string				|
				sub si, 3									;si -= 3					|
			loop cycle1										;---------------------------|
			add si, 3										;si += 3

			add di, window_len * 2							;di += window_len * 2 (next line)
			call PrintString								;print string

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draws string to console in format: s1s2....s2s3
; Entry: 		SI = string address
;				DL = string len
; Exit:			None
; Destroyed:	AX, BX, CX, SI
;------------------------------------------------------------------------------

PrintString	proc

			mov ah, frame_color								;set symbols color

			lodsb											;mov al, ds:[si]
			stosw											;mov es:[di], ax / add di, 2

			push cx											;save prev loop cnt
			mov cl, dl										;counter = dl
			sub cl, 2										;without top and bottom line
			mov al, [si]									;al = [si]
			cycle:											;<------------------------------|
				stosw										;mov es:[di], ax / add di, 2	|
			loop cycle										;-------------------------------|
			inc si											;bx++
			pop cx											;return prev loop cnt

			lodsb											;mov al, ds:[si]
			stosw											;mov es:[di], ax / add di, 2

			mov bl, dl										;bl = dl
			xor bh, bh										;bh = 0
			shl bx, 1										;bx *= 2
			sub di, bx										;set di to line beginning

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

len 				db 31									;frame row length
height 				db 10									;frame column height
frame_color 		db 4eh									;frame element color

x_start 			db 0									;x frame start position
y_start 			db 0									;y frame start position
y_string 			db 0									;y string start position
str_data_pos 		db 0									;cmd line position of string
reg_in_frame		equ 8									;amount of registers in frame

DoubleFrameString 	db 'ÉÍ»º ºÈÍ¼'

AXString 			db "ax $"
BXString 			db "bx $"
CXString 			db "cx $"
DXString 			db "dx $"
SIString 			db "si $"
DIString 			db "di $"
DSString 			db "ds $"
ESString 			db "es $"

EOP:
end 	Start												;prog's ending
