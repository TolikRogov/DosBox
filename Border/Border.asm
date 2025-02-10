;------------------------------------------------------------------------------
;		First work with video memory. Output a colored symbol to console.
;			@Rogov Anatoliy 08.02.2025 "Sivchuk Bad Day"
;------------------------------------------------------------------------------

left_top_corner  	= 00c9h
top_line     		= 00cdh
right_top_corner 	= 00bbh
left_line 	 		= 00bah
main_char 	 		= 0020h
right_line 	 		= 00bah
left_bottom_corner 	= 00c8h
bottom_line 		= 00cdh
right_bottom_corner = 00bch

x_start 			= 10
y_start 			= 5
len 				= 60
height 				= 10
window_len 			= 80
frame_color 		= 10001101b

.model tiny										;set 64 Kb model
.code											;define code block
org 100h										;prog's begging ram block

Start:	mov bx, 0b800h
		mov es, bx
		mov bx, offset String
		call SetString
		mov bx, offset String

		mov dh, frame_color
		mov dl, len
		mov di, 0
		add di, y_start * window_len * 2 + x_start * 2
		call PrintString

		mov cx, height - 2
		cycle1:
			add di, window_len * 2
			call PrintString
			sub bx, 3
		loop cycle1
		add bx, 3

		add di, window_len * 2
		call PrintString

		mov ax, 4c00h							;ax = cmd(4c)
		int 21h									;call scm

;------------------------------------------------------------------------------
; Set String
; Entry: 		None
; Exit:			None
; Destroyed:	None
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

			ret										;return function value
			endp									;proc's ending

;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Draws string to console
; Entry: 		BX = string address
;				DL = string size
;				DH = color
; Exit:			None
; Destroyed:	AX, BX, CX
;------------------------------------------------------------------------------

PrintString	proc

			mov ah, dh								;set symbols color

													;Print first string symbol
			mov al, [bx]							;al = *bx
			stosw									;mov es: [di], ax / di += 2
			inc bx									;bx++

													;Print second string symbols
			mov si, cx
			mov cl, dl								;counter = dl
			sub cl, 2
			cycle:									;while
				mov al, [bx]						;al = *bx
				stosw								;mov es: [bx], ax / di += 2
			loop cycle								;goto cycle
			inc bx									;bx++
			mov cx, si

													;Print third string symbol
			mov al, [bx]							;al = [bx]
			stosw									;mov es: [bx], ax / di += 2
			inc bx									;bx++

			sub di, len * 2

			ret										;return function value
			endp									;proc's ending

;------------------------------------------------------------------------------

String db '<_>| |<_>'

end 	Start									;pog's ending
