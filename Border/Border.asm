;------------------------------------------------------------------------------
;		First work with video memory. Output a colored symbol to console.
;			@Rogov Anatoliy 08.02.2025 "Sivchuk Bad Day"
;------------------------------------------------------------------------------

.model tiny										;set 64 Kb model
.code											;define code block
org 100h										;prog's begging ram block

Start:	mov ax, 0900h							;ax = cmd(9) - print str'$'
		mov dx, offset String					;dx = &String
		int 21h									;call system's call manager

		mov bx, 0b800h							;bx = &ram
		mov es, bx								;es = bx
		mov bx, 5 * 80 * 2 + 40 * 2				;bx = window's size
		mov byte ptr es: [bx], 'A'				;*(es * 16 + bx) = 6500
		mov byte ptr es: [bx + 1], 10101100b	;*(es * 16 + bx + 1) = color

		mov ax, 4c00h							;ax = cmd(4c)
		int 21h									;call scm

ENDL 	equ 0ah, 0dh							;define ENDL \r, \n

String db "RTRTRTRTRTRTRTRTRTRTRT", ENDL, "$"	;String = "..." \n "$"

end 	Start									;pog's ending
