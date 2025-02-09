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
right_bottom_corner = 00bch

.model tiny										;set 64 Kb model
.code											;define code block
org 100h										;prog's begging ram block

Start:	mov bx, 0b800h
		mov es, bx

		mov bx, offset String
		mov dh, 00001111b
		mov dl, 9
		call PrintString

		mov ax, 4c00h							;ax = cmd(4c)
		int 21h									;call scm

;------------------------------------------------------------------------------
; Draws string to console (x = 0, y = 0)
; Entry: 		BX = string address
;				DL = string size
;				DX = color
; Exit:			None
; Destroyed:	AX, BX, CX
;------------------------------------------------------------------------------

PrintString	proc

			mov di, 0
			mov cl, dl

			cycle:
			mov al, [bx]
			mov ah, dh
			stosw
			inc bx
			loop cycle

			ret										;return function value
			endp									;proc's ending

;------------------------------------------------------------------------------

String db '123456789'

end 	Start									;pog's ending
