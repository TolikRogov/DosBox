;------------------------------------------------------------------------------
;			 Card for Saint Valentine's Day (aka frame)
;			@Rogov Anatoliy 08.02.2025 "Sivchuk Bad Day"
;------------------------------------------------------------------------------

cmd_line_add		= 0081h									;cmd line address
video_segment 		= 0b800h								;video segment
window_len 			= 80									;window row length
window_height 		= 25									;window column height
reg_in_frame		= 4										;amount of registers in frame

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

		mov es:[bx], offset New09h							;change 09h interrupt function by mine
		mov ax, cs											;ax = cs
		mov es:[bx + 2], ax									;current segment

		mov ax, 3100h										;make program resident
		mov dx, offset EOP									;dx = &EOP
		shr dx, 4											;dx /= 4
		inc dx												;dx += 1
		int 21h												;31 function of 21 interrupt

;------------------------------------------------------------------------------
; New procedural handler of 09h interrupt
; Entry: 		NONE
; Exit: 		NONE
; Destroyed:	NONE
;------------------------------------------------------------------------------

New09h 	proc
		push ax bx cx dx es si bp							;save all registers

		in al, 60h											;al = scan code from 60h port
		cmp al, 58h											;if (al == F12) zf = 1
		jne skip											;if (zf != 1) goto skip --------|
			push ax bx cx dx es si bp ds					;save all registers				|
															;								|
			mov bx, cs										;bx = code segment				|
			mov ds, bx										;data segment = code segment	|
			call MainBorder									;Main Border function			|
															;								|
			pop ds bp si es dx cx bx ax						;return all registers			|
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

		pop bp si es dx cx bx ax							;return all registers after interrupt
		 	db 0eah											;jump to old procedural handler of 09h interrupt
old09ofs 	dw 0											;previous offset
old09seg 	dw 0											;in segment
		endp

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Main Border
; Entry:		None
; Exit:			SI
; Destroyed:	SI, BP, BX, DX
;------------------------------------------------------------------------------

MainBorder	proc

			xor ax, ax										;ax = 0
			xor bx, bx										;bx = 0
			xor cx, cx										;cx = 0
			xor dx, dx										;dx = 0

			mov bx, video_segment							;bx = video segment position
			mov es, bx										;es = bx

			call CalcParam									;x_start, y_start, y_string
			call SetStyle									;calculate si

			mov dh, height									;dh = height
			mov dl, len										;dl = len
			xor di, di										;di = 0;
			call DrawFrame									;Drawing frame
			call DrawString									;Drawing string inside frame

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Set frame style
; Entry:		None
; Exit:			SI
; Destroyed:	SI, BP, BX, DX
;------------------------------------------------------------------------------

SetStyle	proc

			xor dx, dx										;dx = 0
			mov dx, offset AXString							;dx = &AXString
			mov bp, offset str_data_pos						;bp = &str_data_pos
			mov [bp], dx									;str_data_pos = AXString

			mov si, offset DoubleFrameString				;si = &style string

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draw string inside the frame
; Entry:		None
; Exit:			None
; Destroyed:	SI, BP, CX, AH
;------------------------------------------------------------------------------

DrawString	proc

			mov cx, reg_in_frame 							;cx = amount of registers
			reg_str:										;<--------------------------------------------------------------|
				push cx										;save cx														|
				mov bp, offset str_data_pos					;bp = &str_data_pos												|
				mov si, [bp]								;si = str_data_pos												|
				xor cx, cx									;cx = 0															|
				call StrLen									;cx = len(si)													|
				push cx										;save len														|
															;																|
				mov bp, offset str_data_pos					;bp = &str_data_pos												|
				mov si, [bp]								;si = &inside frame string										|
				call EvalShift								;di = 2 * window_len * y_start + (x_start + (cx - len) / 2) * 2	|
															;																|
				mov ah, frame_color							;ah = string color												|
				call PrintInsideString						;print string													|
															;																|
				pop cx										;return len														|
				mov bp, offset str_data_pos					;bp = &str_data_pos												|
				inc cx										;cx += 1														|
				add [bp], cx								;str_data_pos = len + 1											|
				add y_string, 1								;y_string += 1													|
				pop cx										;return loop counter											|

				sub di, 2 * 4
				push ax bx
				mov bx, ax
				shr bx, 16
				mov ax, bx
				stosw
				pop bx ax

				push ax bx
				mov bx, ax
				shr bx, 12
				mov ax, bx
				stosw
				pop bx ax

				push ax bx
				mov bx, ax
				shr bx, 8
				mov ax, bx
				stosw
				pop bx ax

				push ax bx
				mov bx, ax
				shr bx, 4
				mov ax, bx
				stosw
				pop bx ax

			loop reg_str									;---------------------------------------------------------------|

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; ASCII code symbols to hex integer (ABCDEF instead of abcdef)
; Entry:		AL - first symbol
; Exit:			BL - hex
; Destroyed:	CX, BX, DX, AX
;------------------------------------------------------------------------------

Atoh	proc

		mov cx, 1											;cx = 1
		xor bx, bx											;bx = 0
		xor dx, dx											;dx = 0
		xor ah, ah											;ah = 0

		get_hex:											;<--------------------------|
			cmp al, ' '										;if (al == ' ') zf = 1		|
			je end_atoh										;if (zf == 1) goto end_atoi	|
															;							|
			shl bx, 4										;bx *= 16					|
															;							|
			cmp al, 'A'										;if (al - 65 < 0) fs = 1	|
			jns no_sign										;if (fs != 1) goto no_sign	|
			sub ax, '0'										;ax -= 48					|
			jmp both										;goto both					|
			no_sign:										;							|
				sub ax, 55									;ax -= 55					|
			both:											;							|
			add bx, ax										;bx += ax					|
															;							|
			add cx, 2										;cx += 2					|
			lodsb											;mov al, ds:[si]			|
		loop get_hex										;---------------------------|
		end_atoh:

		ret													;return function value
		endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; ASCII code symbols to integer
; Entry:		AL - first symbol
; Exit:			BL - integer
; Destroyed:	CX, BX, DX, AX
;------------------------------------------------------------------------------

Atoi	proc

		mov cx, 1											;cx = 1
		xor bx, bx											;bx = 0
		xor dx, dx											;dx = 0
		xor ah, ah											;ah = 0

		get_symbol:											;<--------------------------|
			cmp al, ' '										;if (al == ' ') zf = 1		|
			je end_atoi										;if (zf == 1) goto end_atoi	|
															;							|
			push bx											;save bx					|
			shl bx, 3										;bx *= 8					|
															;							|
			pop dx											;return bx: dx = bx			|
			shl dx, 1										;dx *= 2					|
			add bx, dx										;bx += dx					|
															;							|
			sub ax, 48										;ax -= 48					|
			add bx, ax										;bx += ax					|
															;							|
			add cx, 2										;cx += 2					|
			lodsb											;mov al, ds:[si]			|
		loop get_symbol										;---------------------------|
		end_atoi:

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

			;x_start = window_len - len
			mov al, len										;al = len
			mov bl, window_len								;bp = 80
			mov x_start, bl									;x_start = 80
			sub x_start, al									;x_start -= len

			mov y_start, 2									;y_start = 1

			mov bl, y_start									;bp = y_start
			inc bl											;bl += 1
			mov y_string, bl								;y_string = y_start + 1

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
; Print string inside the frame
; Entry: 		BX = data string address
;				AH = string color
;				CX = string length
; Exit:			None
; Destroyed:	BX, AL, DI
;------------------------------------------------------------------------------

PrintInsideString	proc

					print_string:							;<----------------------------------|
						lodsb								;mov al, ds:[si]					|
						stosw								;mov es:[di], ax / add di, 2		|
						cmp al, '$'							;if (al == '$') zf = 1				|
						jz end_print_string					;if (zf == 1) goto end_print_string	|
					loop print_string						;-----------------------------------|
					end_print_string:						;label of print string ending

					ret										;return function value
					endp									;proc's ending

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

.data
len 				db 19									;frame row length
height 				db 7									;frame column height
frame_color 		db 4eh									;frame element color

x_start 			db 0									;x frame start position
y_start 			db 0									;y frame start position
y_string 			db 0									;y string start position
str_data_pos 		db 0									;cmd line position of string

DoubleFrameString 	db 'ÉÍ»º ºÈÍ¼'
AXString 			db "ax 0000$"
BXString 			db "bx 0000$"
CXString 			db "cx 0000$"
DXString 			db "dx 0000$"

EOP:
end 	Start												;prog's ending
