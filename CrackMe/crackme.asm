;------------------------------------------------------------------------------
;					New day - new life. Happy Spring!
;		@Rogov Anatoliy 01.03.2025 11:07 "I hope it is not so hard"
;------------------------------------------------------------------------------

.model tiny												;64 Kb on each segment
.code													;code segment
org 100h												;offset of commands in code segment

Start:													;Start of program
	;==========================================================================
	mov ax, 0900h										;9h function of 21 interrupt | outs the string by dx address
	mov dx, offset StartString							;dx = &StartString
	int 21h												;call 21 interrupt
	;==========================================================================

	mov si, offset Buffer								;si = &Buffer
	call InputSymbolsToBuffer							;Inputting symbols while it is not CR

	mov si, offset Buffer								;si = &Buffer
	mov cx, buffer_size									;cx = buffer_size
	call DJB2											;hash function

	call Authentication									;check password

	mov ax, 4c00h										;4ch function of 21 interrupt | end program
	int 21h												;call 21 interrupt

;------------------------------------------------------------------------------
; Read key from keyboard, show it on screen, if key is 'Return/Enter' -> return
; Entry:		SI - offset of buffer in data segment
; Exit:			Buffer
; Destroy:		AX, SI
;------------------------------------------------------------------------------
InputSymbolsToBuffer	proc							;start procedure

waitForKey:												;<--------------------------------------------------|
														;01h function of 21 interrupt						|
	mov ah, 01h											;input the symbol, place it in al and show on screen|
	int 21h												;call 21 interrupt									|
														;													|
	mov ds:[si], al										;ds:[si] = al 	| put symbol in buffer 				|
	inc si												;si += 1		| shift buffer pointer 				|
														;													|
	cmp al, 0dh											;if (al == carriage return) zf = 1					|
	jne waitForKey										;if (zf != 1) goto waitForKey ----------------------|

	ret													;return function
	endp												;end function
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Check password of correct
; Entry:		AX - hash value of password
; Exit:			Screen
; Destroy:		AX
;------------------------------------------------------------------------------
Authentication	proc									;start procedure

	cmp ax, Password									;if (ax == Password) zf = 1
	jne unfortunately									;if (zf != 1) goto unfortunately ---|
														;									|
	mov ax, 0900h										;09h function of 21 interrupt		|
	mov dx, offset GG									;dx = &GG | give access				|
	int 21h												;call 21 interrupt					|
	jmp end_access										;goto end_access ---------------|	|
														;								|	|
unfortunately:											;<------------------------------|---|
	mov ax, 0900h										;09h function of 21 interrupt	|
	mov dx, offset Sry									;dx = &Sry | don't give access	|
	int 21h												;call 21 interrupt				|
														;								|
end_access:												;<------------------------------|
	ret													;return function
	endp												;end function
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; DJB2 hash function
; Entry:	SI - buffer address
;			CX - buffer size
; Exit:		AX
; Destroy:  AX, CX, SI, BX
;------------------------------------------------------------------------------
DJB2	proc											;start procedure

	xor ax, ax 											;ax = 0
	xor bh, bh											;bh = 0

	calc_hash:											;<----------------------------------|
		mov bl, ds:[si]									;bl = ds:[si] | symbol of password	|
		add ax, bx										;ax += bx							|
		inc si											;si += 1							|
	loop calc_hash										;-----------------------------------|

	ret													;return function
	endp												;end function
;------------------------------------------------------------------------------

.data													;data segment

video_segment 	equ 0b800h								;segment of video memory
buffer_size 	equ 13d									;size of buffer to inputting symbols

Buffer 			db buffer_size + 1 dup (0)				;initialization of buffer in memory
Password 		dw 0367h								;right password hash to get access

ENDL 			equ 0dh, 0ah, '$'						;next line
StartString 	db "Hello, hope you did't forget about password!", 	ENDL
Sry 			db 'Access is not yours!', 							ENDL
GG				db 'Access is always yours!', 						ENDL

EOP:													;end of program
end 		Start
