;------------------------------------------------------------------------------
;			 Card for Saint Valentine's Day (aka frame)
;			@Rogov Anatoliy 08.02.2025 "Sivchuk Bad Day"
;------------------------------------------------------------------------------

video_segment 		= 0b800h								;video segment
window_len 			= 80									;window row length
window_height 		= 25									;window column height
frame_color 		= 00001010b								;color of frame element
string_color 		= 10001010b								;color of frame inside string

len 				= 30									;frame row length
height 				= 9										;frame column height

x_start 			= (window_len - len) / 2				;x frame start position
y_start 			= (window_height - height) / 2			;y frame start position
y_string 			= (height / 2 + y_start)				;y string start position

.model tiny													;set 64 Kb model
.code														;define code block
org 100h													;prog's begging ram block

Start:	mov bx, video_segment								;bx = video segment position
		mov es, bx											;es = bx

		mov si, offset OutsideFrameString					;si = &FrameStyleString
		mov dh, height										;dh = frame height
		mov dl, len											;dl = frame length
		xor di, di											;di = 0
		call DrawFrame

		mov si, offset InsideString							;si = &inside frame string
		xor cx, cx											;cx = 0
		call StrLen

		mov si, offset InsideString							;si = &inside frame string
		call EvalShift

		mov ah, string_color								;ah = string color
		call PrintInsideString

		mov ax, 4c00h										;ax = cmd(4c)
		int 21h												;call scm

;------------------------------------------------------------------------------
; Eval shift of frame inside string
; Entry:		CX = string length
; Exit:			None
; Destroyed:	DI, BX
;------------------------------------------------------------------------------

EvalShift	proc

			mov di, y_string * window_len * 2 + (x_start + len / 2) * 2
			mov bx, cx										;bx = cx
			shr bx, 1										;bx /= 2
			sub di, bx										;di -= bx
			sub di, bx										;di -= bx

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; Eval string length with '$' terminal symbol
; Entry: 		SI = data string address
; Exit:			None
; Destroyed:	BX, AL, CX
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

			add di, y_start * window_len * 2 + x_start * 2	;frame top line shifting
			call PrintString								;print string

			mov cx, height - 2								;count of center frame line
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
; Entry: 		BX = string address
;				DL = string len
; Exit:			None
; Destroyed:	AX, BX, CX, SI
;------------------------------------------------------------------------------

PrintString	proc

			mov ah, frame_color								;set symbols color

			lodsb											;mov al, ds:[si]
			stosw											;mov es:[di], ax / add di, 2

			mov bx, cx										;save prev loop cnt
			mov cl, dl										;counter = dl
			sub cl, 2										;without top and bottom line
			cycle:											;<------------------------------|
				mov al, [si]								;al = [si]						|
				stosw										;mov es:[di], ax / add di, 2	|
			loop cycle										;-------------------------------|
			inc si											;bx++
			mov cx, bx										;return prev loop cnt

			lodsb											;mov al, ds:[si]
			stosw											;mov es:[di], ax / add di, 2

			sub di, len * 2									;set di to line beginning

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

DoubleFrameString 	db 'ÉÍ»º ºÈÍ¼'
SingleFrameString	db 'ÚÄ¿³ ³ÀÄÙ'
HeartFrameString	db ' '
DebugFrameString	db '123456789'
MathFrameString		db 'ûûûû ûûûû'
PatriotFrameString	db 'RTRT TRTR'
PointedFrameString	db '²±²° °²±²'
OutsideFrameString	db 'ÀÁÙ´ Ã¿ÂÚ'
InsideString 		db 'I wanna sleep!$'

end 	Start												;prog's ending
