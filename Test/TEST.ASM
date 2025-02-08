;-----------------------------------------------------------------------------
;		It is one of the most terrible thing in the world.
;			@Rogov Anatoliy 04.02.2025 19:39:..
;-----------------------------------------------------------------------------
.model tiny				;Set the model with one memory segment 
					;less then 64 Kb
.code					;Start the block of programm code
org 100h				;Move code block to 100h address
Start:					;Begining label of code
		mov ah, 09h		;ah = puts(String)
		mov dx, offset String	;dx = &String
		int 21h			;system call manager

		mov ax, 4c00h		;ax = exit(0)
		int 21h 		;system call manager

ENDL		equ 0dh, 0ah		;Macros to new line

String db 'RTRTRTRTRTRTRTRTRTRTRTRTRTRTRTRT', ENDL, '$'

end 		Start			;End programm or return to Start
