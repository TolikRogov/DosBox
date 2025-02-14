;------------------------------------------------------------------------------
;			 Card for Saint Valentine's Day (aka frame)
;			@Rogov Anatoliy 08.02.2025 "Sivchuk Bad Day"
;------------------------------------------------------------------------------

video_segment 		= 0b800h								;video segment
window_len 			= 80									;window row length
window_height 		= 25									;window column height

.model tiny													;set 64 Kb model
.code														;define code block
org 100h													;prog's beginning ram block

Start:	mov bx, video_segment								;bx = video segment position
		mov es, bx											;es = bx

		call CalcParam										;x_start, y_start, y_string

		mov si, offset HeartFrameString						;si = &FrameStyleString
		mov bp, offset height
		mov dh, [bp]										;dh = frame height
		mov bp, offset len
		mov dl, [bp]										;dl = frame length
		xor di, di											;di = 0
		call DrawFrame

		mov si, offset InsideString							;si = &inside frame string
		xor cx, cx											;cx = 0
		call StrLen											;cx = len(si)

		mov si, offset InsideString							;si = &inside frame string
		call EvalShift

		mov bp, offset string_color							;bp = &string_color
		mov ah, [bp]										;ah = string color
		call PrintInsideString

		mov ax, 4c00h										;ax = cmd(4c)
		int 21h												;call scm

;------------------------------------------------------------------------------
; Calculate values of variables: x_start, y_start, y_string
; Entry:		None
; Exit:			None
; Destroyed:	AX, BX, DX, DP
;------------------------------------------------------------------------------

CalcParam	proc

			mov bp, offset len								;bx = &len
			mov al, [bp]									;ax = len
			mov bp, offset height							;bx = &height
			mov dl, [bp]									;dx = height
			mov bp, offset x_start							;bx = &x_start
			mov bl, window_len / 2							;bp = 80 / 2
			mov [bp], bl									;x_start = 40
			shr ax, 1										;ax /= 2
			sub [bp], al									;x_start -= len / 2

			mov bp, offset y_start							;bx = &y_start
			mov bl, window_height / 2						;bp = 25 / 2
			mov [bp], bl									;y_start = 25 / 2
			shr dx, 1										;dx /= 2
			sub [bp], dl									;y_start -= height / 2

			mov bl, [bp]									;bp = y_start
			mov bp, offset y_string							;bx = &y_string
			mov [bp], bl									;y_string = height / 2
			add [bp], dl									;y_string += height / 2

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Eval shift of frame inside string
; Entry:		CX = string length
; Exit:			None
; Destroyed:	DI, BP, AX
;------------------------------------------------------------------------------

EvalShift	proc

			;di = y_string * window_len * 2 + (x_start + len / 2) * 2
			mov bp, offset y_string							;bp = &y_start
			mov al, [bp]									;al = y_start
			shl al, 1										;al *= 2
			xor ah, ah										;ah = 0
			mov bp, window_len								;bp = 80
			push dx											;save size of frame in stack
			mul bp											;ax = 2 * y_start * 80
			pop dx											;return size of frame from stack to dx÷
			mov di, ax										;di = ax

			mov bp, offset x_start							;bp = &x_start
			xor ah, ah										;ah = 0
			mov al, [bp]									;ax = x_start
			mov bp, cx										;bp = cx
			shr bp, 1										;bp /= 2
			add ax, bp										;ax += bp
			shl al, 1										;al /= 2
			add di, ax										;di += 2 * x_start

			mov bp, cx										;bp = cx
			shr bp, 1										;bp /= 2
			sub di, bp										;di -= bp

			shr di, 1										;di /= 2
			shl di, 1										;di *= 2
			sub di, 2										;di -= 2run.bat

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

			mov bp, offset y_start							;bp = &y_start
			mov al, [bp]									;al = y_start
			shl al, 1										;al *= 2
			mov bp, window_len								;bp = 80
			push dx											;save size of frame in stack
			mul bp											;ax = 2 * y_start * 80
			pop dx											;return size of frame from stack to dx
			mov di, ax										;di = ax
			mov bp, offset x_start							;bp = &x_start
			mov al, [bp]									;ax = x_start
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

			mov bx, offset frame_color						;bp = &frame_color
			mov ah, [bx]									;set symbols color

			lodsb											;mov al, ds:[si]
			stosw											;mov es:[di], ax / add di, 2

			push cx											;save prev loop cnt
			mov cl, dl										;counter = dl
			sub cl, 2										;without top and bottom line
			cycle:											;<------------------------------|
				mov al, [si]								;al = [si]						|
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

len 				db 30									;frame row length
height 				db 9									;frame column height
x_start 			db 0									;x frame start position
y_start 			db 0									;y frame start position
y_string 			db 0									;y string start position
frame_color 		db 01001101b							;frame element color
string_color 		db 11001101b							;color of frame inside string

ProgNameString		db 'border.com$'
DoubleFrameString 	db 'ÉÍ»º ºÈÍ¼'
SingleFrameString	db 'ÚÄ¿³ ³ÀÄÙ'
HeartFrameString	db ' '
DebugFrameString	db '123456789'
MathFrameString		db 'ûûûû ûûûû'
PatriotFrameString	db 'RTRT TRTR'
PointedFrameString	db '²±²° °²±²'
OutsideFrameString	db 'ÀÁÙ´ Ã¿ÂÚ'
InsideString 		db "Saint Valentin's Day!$"

end 	Start												;prog's ending
