cmd_line_add		= 0081h									;cmd line address
video_segment 		= 0b800h								;video segment
window_len 			= 80									;window row length
window_height 		= 25									;window column height

.model tiny
.code
org 100h
Start:	xor bx, bx
		mov bx, video_segment
		mov es, bx

		xor dx, dx										;dx = 0
		mov dx, offset AXString							;dx = &AXString
		mov bp, offset str_data_pos						;bp = &str_data_pos
		mov [bp], dx									;str_data_pos = AXString

		mov ax, 1111h
		mov bx, 2222h
		mov cx, 3333h
		mov dx, 4444h

		call DrawString

		mov ax, 4c00h
		int 21h

DrawString	proc

			push ax bx dx cx
			mov cx, reg_in_frame
			reg_str:										;<--------------------------------------------------------------|
				push cx
				mov bp, offset str_data_pos					;bp = &str_data_pos												|
				mov si, [bp]								;si = str_data_pos												|
				xor cx, cx									;cx = 0															|
				call StrLen									;cx = len(si)  													|
				push cx										;save len														|
															;						Shifting								|
				mov bp, offset str_data_pos					;bp = &str_data_pos												|
				mov si, [bp]								;si = &inside frame string										|
				call EvalShift								;di = 2 * window_len * y_start + (x_start + (cx - len) / 2) * 2	|
															;						Print									|
				mov ah, frame_color							;ah = string color												|
				call PrintInsideString						;print string													|
															;						Next Row								|
				pop cx										;return len														|
				mov bp, offset str_data_pos					;bp = &str_data_pos												|
				inc cx										;cx += 1														|
				add [bp], cx								;str_data_pos = len + 1											|
				add y_string, 1								;y_string += 1													|
				pop cx
															;						Out Register							|
				sub di, 2									;remove 0000													|
				push ax										;save ax 														|
				mov bp, offset print_ax						;bp = &print_ax													|
				add bp, reg_in_frame						;bp += reg_in_frame												|
				sub bp, cx									;bp -= loop cnt													|
				mov al, [bp]								;al = right exchange function									|
				mov CurReg, al								;CurReg = al													|
				pop ax										;return ax 														|
				pop bp dx bx ax
				push cx
				mov cx, bp
				CurReg db 0									;exchange function												|
				call OutAx									;Print ax register												|
				pop bp
				push ax bx dx cx
				mov cx, bp
															;																|
			loop reg_str									;---------------------------------------------------------------|
			pop cx dx bx ax

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Show ax register value
; Entry:		AX - printing value
; Exit:			NONE
; Destroyed:	CX, BX, DX, AX
;------------------------------------------------------------------------------

OutAx	proc
		std

		push ax cx dx

		mov dl, 16
		mov cx, 0002h
		print_al:
			push ax
			and ax, 000fh
			cmp al, 10
			jae letter
				add al, '0'
				jmp both
			letter:
				add al, 'A' - 10
			both:
			mov ah, frame_color
			stosw
			pop ax

			push ax
			and ax, 00f0h
			div dl
			cmp al, 10
			jae letter2
				add al, '0'
				jmp both2
			letter2:
				add al, 'A' - 10
			both2:
			mov ah, frame_color
			stosw
			pop ax
			mov al, ah
		loop print_al
		pop dx cx ax

		add di, 4
		cld
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

			;di = y_string * window_len * 2 + (x_start + (cx - len) / 2) * 2
			mov al, y_string								;al = y_string
			shl al, 1										;al *= 2
			xor ah, ah										;ah = 0
			mov bp, window_len								;bp = 80
			push dx											;save size of frame in stack
			mul bp											;ax = 2 * y_start * 80
			pop dx											;return size of frame from stack to dxΓëê
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

len 				db 19									;frame row length
height 				db 7									;frame column height
frame_color 		db 4eh									;frame element color

x_start 			db 0									;x frame start position
y_start 			db 0									;y frame start position
y_string 			db 0									;y string start position
str_data_pos 		db 0									;cmd line position of string
reg_in_frame		equ 4									;amount of registers in frame
loop_cnt			dw 0

DoubleFrameString 	db '╔═╗║ ║╚═╝'

AXString 			db "ax 0000$"
BXString 			db "bx 0000$"
CXString 			db "cx 0000$"
DXString 			db "dx 0000$"

print_ax			db 090h
print_bx			db 093h
print_cx			db 091h
print_dx			db 092h

EOP:
end 		Start
