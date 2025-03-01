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
	mov dx, offset DebugString							;dx = &DebugString
	int 21h												;call 21 interrupt
	;==========================================================================

waitForKey:												;<------------------------------------------------------------------------------|
	mov ah, 01h											;1h function of 16 interrupt | if key is ready ax = keycode, set zf flag		 |
	int 16h												;call 16 interrupt																|
	jnz gotKey											;if zf flag is set -> goto gotKey ---|											 |
	jmp waitForKey										;goto waitForKey -------------------|-------------------------------------------|
														;									|
gotKey:													;<----------------------------------|
	mov dx, ax											;dx = keycode
	mov ax, 0200h										;2h function of 21 interrupt | outs symbol
	int 21h												;call 21 interrupt

	mov ah, 00h											;0h function of 16 interrupt | remove keystroke from the buffer
	int 16h												;call 16 interrupt

	mov ax, 4c00h										;4ch function of 21 interrupt | end program
	int 21h												;call 21 interrupt

.data													;data segment

video_segment equ 0b800h								;segment of video memory
enter_flag 		db 0									 ;flag of enter button

ENDL equ 0dh, 0ah										;next line
DebugString db 'DebugString is on your screen!', ENDL, '$'

EOP:													;end of progra
end 		Start
