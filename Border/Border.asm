;------------------------------------------------------------------------------
;		First work with video memory. Output a colored symbol to console.
;			@Rogov Anatoliy 08.02.2025 "Sivchuk Bad Day"
;------------------------------------------------------------------------------

left_top_corner  	= 00c9h									;frames elements
top_line     		= 00cdh
right_top_corner 	= 00bbh
left_line 	 		= 00bah
main_char 	 		= 0020h
right_line 	 		= 00bah
left_bottom_corner 	= 00c8h
bottom_line 		= 00cdh
right_bottom_corner = 00bch

window_len 			= 80									;window length in columns
window_height 		= 25									;window height in rows
frame_color 		= 00001010b								;color of frame element

len 				= 50									;frame length in columns
height 				= 10									;frame height in rows
str_size 			= 14									;inside frame string position

x_start 			= (window_len - len) / 2				;eval x frame start position
y_start 			= (window_height - height) / 2			;eval y frame start position
x_string 			= x_start + (len - str_size) / 2		;inside frame string x start position
y_string 			= (2 * height + y_start) / 2 - 1		;inside frame string y start position

.model tiny													;set 64 Kb model
.code														;define code block
org 100h													;prog's begging ram block

Start:	mov bx, 0b800h										;es = video segment
		mov es, bx

		mov bx, offset String								;Set frame data string with frame elements
		call SetString

		mov bx, offset String								;Prepare for frame drawing
		mov dh, height
		mov dl, len
		mov di, 0
		call StringDrawing

		mov bx, offset InsideString
		mov di, y_string * window_len * 2 + x_string * 2
		mov ah, frame_color
		mov cx, str_size
		call PrintInsideString

		mov ax, 4c00h										;ax = cmd(4c)
		int 21h												;call scm

;------------------------------------------------------------------------------
; Print string inside the frame
; Entry: 		BX = data string address
;				AH = string color
;				CX = string length
; Exit:			None
; Destroyed:	BX, AL, DI
;------------------------------------------------------------------------------

PrintInsideString	proc

					print_string:
						mov al, [bx]
						stosw
						inc bx
					loop print_string

					ret													;return function value
					endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draw frame with size: len, height
; Entry: 		BX = data string address
;				DH = frame height
;				DL = frame len
; Exit:			None
; Destroyed:	BX
;------------------------------------------------------------------------------

StringDrawing	proc

				add di, y_start * window_len * 2 + x_start * 2		;draw frame top line
				call PrintString

				mov cx, height - 2									;draw frame main lines
				cycle1:
					add di, window_len * 2
					call PrintString
					sub bx, 3
				loop cycle1
				add bx, 3

				add di, window_len * 2								;draw frame bottom line
				call PrintString

				ret													;return function value
				endp												;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Set String
; Entry: 		None
; Exit:			None
; Destroyed:	BX
;------------------------------------------------------------------------------

SetString	proc

			mov byte ptr ds: [bx], left_top_corner
			inc bx

			mov byte ptr ds: [bx], top_line
			inc bx

			mov byte ptr ds: [bx], right_top_corner
			inc bx

			mov byte ptr ds: [bx], left_line
			inc bx

			mov byte ptr ds: [bx], main_char
			inc bx

			mov byte ptr ds: [bx], right_line
			inc bx

			mov byte ptr ds: [bx], left_bottom_corner
			inc bx

			mov byte ptr ds: [bx], bottom_line
			inc bx

			mov byte ptr ds: [bx], right_bottom_corner
			inc bx

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

															;Print first string symbol
			mov al, [bx]									;al = *bx
			stosw											;mov es: [di], ax / di += 2
			inc bx											;bx++

															;Print second string symbols
			mov si, cx										;save prev loop cnt
			mov cl, dl										;counter = dl
			sub cl, 2										;without top and bottom line
			cycle:											;while
				mov al, [bx]								;al = *bx
				stosw										;mov es: [bx], ax / di += 2
			loop cycle										;goto cycle
			inc bx											;bx++
			mov cx, si										;return prev loop cnt

															;Print third string symbol
			mov al, [bx]									;al = [bx]
			stosw											;mov es: [bx], ax / di += 2
			inc bx											;bx++

			sub di, len * 2									;set di to line beginning

			ret												;return function value
			endp											;proc's ending

;------------------------------------------------------------------------------

String 			db '<_>| |<_>'
InsideString 	db 'I wanna sleep!$'

end 	Start												;pog's ending
