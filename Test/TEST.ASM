video_segment 	= 	0b800h

.model tiny
.code
org 100h
Start:
		xor ax, ax
		mov es, ax
		mov bx, 09h * 4

		mov ax, es:[bx]
		mov old09ofs, ax
		mov ax, es:[bx + 2]
		mov old09seg, ax

		mov es:[bx], offset NewOS	;change 09h interrupt by mine
		mov ax, cs					;ax = cs
		mov es:[bx + 2], ax			;new segment

		int 09h						;call procedural interrupt handler (поп)

		mov ax, 3100h				;31 functions 21 interrupt
		mov dx, offset EOP
		shr dx, 4
		inc dx
		int 21h

NewOS 	proc
		push ax bx cx dx es si bp

		mov ax, video_segment
		mov es, ax
		mov ah, 4eh

		mov bx, 5 * 80 * 2 + 40 * 2

		in al, 60h
		mov es:[bx], ax

		in al, 61h
		mov ah, al
		or al, 80h
		out 61h, al						;ready for input next button
		mov al, ah
		out 61h, al

		mov al, 20h						;non-specific end of interrupt
		out 20h, al						;interrupt controller port

		pop bp si es dx cx bx ax
		 	db 0eah
old09ofs 	dw 0
old09seg 	dw 0
		endp

EOP:
end 		Start
