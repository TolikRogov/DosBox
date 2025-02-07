.model tiny
.code

org 100h

Start:		mov ax, 0900h
			mov dx, offset String
			int 21h

			mov bx, 0b800h
			mov es, bx
			mov bx, 5 * 80 * 2 + 40 * 2
			mov byte ptr es: [bx], 'A'
			mov byte ptr es: [bx + 1], 10101100b

			mov ax, 4c00h
			int 21h

ENDL 		equ 0ah, 0dh

String db "RTRTRTRTRTRTRTRTRTRTRT", ENDL, "$"

end 	Start
