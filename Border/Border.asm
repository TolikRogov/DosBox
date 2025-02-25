;------------------------------------------------------------------------------
;			 Card for Saint Valentine's Day (aka frame)
;			@Rogov Anatoliy 08.02.2025 "Sivchuk Bad Day"
;------------------------------------------------------------------------------

cmd_line_add		= 0081h									;cmd line address
video_segment 		= 0b800h								;video segment
window_len 			= 80									;window row length
window_height 		= 25									;window column height

.model tiny													;set 64 Kb model
.code														;define code block
org 100h													;prog's beginning ram block

Start:	mov bx, video_segment								;bx = video segment position
		mov es, bx											;es = bx

		call EnterData										;len, height
		call CalcParam										;x_start, y_start, y_string
		call SetStyle										;calculate si

		mov dh, height										;dh = height
		mov dl, len											;dl = len
		xor di, di											;di = 0
		call DrawFrame										;Drawing frame
		call DrawString										;Drawing string inside frame

		mov ax, 4c00h										;ax = cmd(4c)
		int 21h												;call scm

;------------------------------------------------------------------------------
; Set frame style
; Entry:		None
; Exit:			SI
; Destroyed:	SI, BP, BX, DX
;------------------------------------------------------------------------------

SetStyle	proc

			xor bx, bx										;bx = 0
			mov bl, frame_style								;bl = frame_style

			push si											;save si
			call SkipSpaces									;skip spaces
			call SkipQuot									;skip while ne quot
			call SkipSpaces									;skip spaces
			mov bp, offset str_data_pos						;bp = &str_data_pos
			mov [bp], si									;str_data_pos = si
			pop si											;return si

			cmp bl, 0										;if (bl == 0) jz = 1
			je own_style									;if (jz == 1) goto own_style

			mov bp, offset frame_style						;bp = &frame_style
			sub bl, 1										;bl -= 1
			push bx											;save bx
			shl bl, 3										;bl *= 8
			pop dx											;return bx to dx
			add bl, dl										;bl += dl
			inc bl											;bl += 1
			add bp, bx										;bp += bx
			mov si, bp										;si = bp

			ret												;return function value
			endp											;proc's ending

			own_style:
			call SkipSpaces									;skip spaces on si

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Skip quotation mark on si address
; Entry:		SI - symbol on or before quotation mark
; Exit:			SI - first symbol equal to quotation mark
; Destroyed:	CX, AL
;------------------------------------------------------------------------------

SkipQuot	proc

			mov cx, 1										;cx = 1

			cmd_skip_quot:									;<----------------------------------|
				lodsb										;mov al, ds:[si]					|
				cmp al, '"'									;if (al == ' ') zf = 1				|
				je end_cmd_skip_quot						;if (zf == 1) goto end_cmd_skip_quot|
				add cx, 2									;cx += 2							|
			loop cmd_skip_quot								;-----------------------------------|
			end_cmd_skip_quot:

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

			mov bp, offset str_data_pos						;bp = &str_data_pos
			mov si, [bp]									;si = str_data_pos
			xor cx, cx										;cx = 0
			call StrLen										;cx = len(si)

			mov bp, offset str_data_pos
			mov si, [bp]									;si = &inside frame string
			call EvalShift									;di = 2 * window_len * y_start + (x_start + (cx - len) / 2) * 2

			mov ah, frame_color								;ah = string color
			call PrintInsideString

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Enter the data for frame
; Entry:		None
; Exit:			None
; Destroyed:	SI, BP
;------------------------------------------------------------------------------

EnterData	proc

			mov si, cmd_line_add							;si = cmd_line
			call SkipSpaces									;skip spaces in cmd line
			call Atoi										;bl = integer
			mov bp, offset len								;bp = &len
			mov [bp], bl									;len = bl

			call SkipSpaces									;skip spaces in cmd line
			call Atoi										;bl = integer
			mov bp, offset height							;bp = &height
			mov [bp], bl									;height = bl

			call SkipSpaces									;skip spaces in cmd line
			call Atoh										;bl = hex
			mov bp, offset frame_color						;bp = &height
			mov [bp], bl									;frame_color = bl

			call SkipSpaces									;skip spaces in cmd line
			call Atoi										;bl = integer
			mov bp, offset frame_style						;bp = &style
			mov [bp], bl									;frame_style = bl

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
; Skip spaces on cmd line address
; Entry:		SI - string beginning with ' '(20) space
; Exit:			SI - first non space symbol
; Destroyed:	CX, AL
;------------------------------------------------------------------------------

SkipSpaces	proc

			mov cx, 1										;cx = 1

			cmd_skip_spc:									;<----------------------------------|
				lodsb										;mov al, ds:[si]					|
				cmp al, ' '									;if (al == ' ') zf = 1				|
				jne end_cmd_skip_spc						;if (zf == 1) goto end_cmd_skip_spc	|
				add cx, 2									;cx += 2							|
			loop cmd_skip_spc								;-----------------------------------|
			end_cmd_skip_spc:

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
			mov y_string, bl								;y_string = height / 2
			add y_string, dl								;y_string += height / 2

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
			pop dx											;return size of frame from stack to dx�
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

			push bx cx di

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

			pop di cx bx

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

len 				db 0									;frame row length
height 				db 0									;frame column height
frame_color 		db 0									;frame element color

x_start 			db 0									;x frame start position
y_start 			db 0									;y frame start position
y_string 			db 0									;y string start position
str_data_pos 		db 0									;cmd line position of string

frame_style 		db 1									;frame style
DoubleFrameString 	db '�ͻ� ��ͼ'
SingleFrameString	db '�Ŀ� ����'
HeartFrameString	db ' '
DebugFrameString	db '123456789'
MathFrameString		db '���� ����'
PatriotFrameString	db 'RTRT TRTR'
PointedFrameString	db '���� ����'
OutsideFrameString	db '��ٴ ÿ��'
InsideString 		db "Saint Valentine's Day!$"

end 	Start												;prog's ending
