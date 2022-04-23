	prtStr macro X
		mov dx,offset X ; load the address where the string promptA starts in memory
		mov ah,09h ; load the high order byte of the ax register with a 09h (DOS API string write operation)
		int 21h	; interrupt vector for DOS API
	endm
	
	clearScrn macro
		mov ax, 0002h ; set ax to BIOS clear screen operation
		int 10h
	endm
	
	changColor macro C
		mov ah, 06h ;set ax high to scroll up
		mov al, 00h ;whole screen
		mov bh, C ;set bx high to chosen color from main code 
		mov cx, 0000h ;set cx to 0000h cursor position 0,0
		mov dx, 184fh ;set dx to 25x80 screen size
		int 10h
	endm
	
	readCh macro Y
		; read a character
		mov ah,01h	; load the ah with 01h (DOS API read ascii character operation)
		int 21h	; interrupt vector for DOS API
		mov Y,al	; load the ascii character read into numA
		and al,00001111b ; strip ascii bits to convert to decimal
		mov Y,al
	endm
	
	writeCh macro Z
		; print the character
		or Z,00110000b ; or operation with 30h to convert decimal digit to ascii digit
		mov dl,Z
		mov ah,02h	; load ah with 02h (DOS API acsii character write operation)
		int 21h
	endm
	
	moveCursor Macro X, Y
		;move the cursor to (x, y) position from top left
		mov dl, x
		mov dh, y
		mov ah, 02h
		mov bh, 0
		int 10h
	endm
	;return value of first index that contains a nonzero value or returns zero if all are zeroes
	findTop Macro A
		LOCAL search
		LOCAL done
		LOCAL replace
		xor ax, ax
		xor bx, bx
		mov bx, A
		xor cx, cx
		search:
		mov ax, gameState+bx
		inc cx	
		cmp ax, 0
		jnz replace
		cmp cx, 3
		jg replace
		add bx, 2
		jmp search
		replace:
		mov ax, gameState+bx
		done:
	endm
	;offset array reader by index of target from user input and read 3 non zero values because order is enforced elsewhere
	checkWin Macro T
	LOCAL exit
	LOCAL search
	
	cmp T, 2
	jl cheated
	je twoWins
	jg threeWins
	
	cheated:
	jmp True
	
	twoWins:
	xor bx, bx
	mov bx, 6
	search:
	cmp bx, 12
	je True
	mov ax, gameState+bx
	cmp ax, 0
	je exit
	add bx, 2
	jne search
	jmp exit
	
	threeWins:
	xor bx, bx
	mov bx, 12
	search1:
	cmp bx, 18
	je True
	mov ax, gameState+bx
	cmp ax, 0
	je exit
	add bx, 2
	jne search1
	mov ax, 1
	jmp exit
	
	True:
	mov ax, 1
	exit:
	endm
	;replace first nonzero value with a zero taking offset in array as a parameter
	removeRing Macro A
	LOCAL search
	LOCAL done
	LOCAL replace
	xor ax, ax
	xor bx, bx
	mov bx, A
	xor cx, cx
	search:
	mov ax, gameState+bx
	inc cx	
	cmp ax, 0
	jnz replace
	cmp cx, 3
	jg replace
	add bx, 2
	jmp search
	replace:
	mov ax, gameState+bx
	mov topRing, al
	mov gameState+bx, 0
	done:
	endm
	;finds the first nonzero value and places the top ring found earlier in the index before that
	addRing Macro A, T
	LOCAL search
	LOCAL done
	LOCAL replace
	cmp T, 0
	jng done
	xor ax, ax
	xor bx, bx
	mov bx, A
	xor cx, cx
	search:
	mov ax, gameState+bx
	inc cx	
	cmp ax, 0
	jne replace
	cmp cx, 3
	jg replace
	add bx, 2
	jmp search
	replace:
	sub bx, 2
	mov al, T
	mov gameState+bx, ax
	done:
	endm
	;searches array in groups of three resetting cx every three because there are only 3 possible y values
	findIndex Macro X
	LOCAL search
	LOCAL subtract
	LOCAL foundIndex
	LOCAL failed
	
	xor bx, bx
	xor cx, cx
	
	search:
	cmp bx, 18
	jge failed
	cmp cx, 3
	je subtract
	mov ax, X
	cmp ax, gameState+bx
	je foundIndex
	inc cx
	add bx, 2
	jmp search
	
	subtract:
	sub cx, 3
	jmp search
	
	foundIndex:
	mov ax, cx
	
	failed:
	endm
	
	pArray Macro X
	LOCAL Print
	xor bx, bx ;Clear bx register for loop control
	Print:
	mov ax, X+bx ;print bytes in array at data+bx address
	call outdec ;print bytes at that address
	prtStr comma ;comma between values
	add bx, 2 ;load next address in array
	cmp bx, 17 ;compare to last location + 2 bytes
	jl Print ;loop if less than last address + 2 bytes
	endm
	
	sound macro pitch,duration
	mov al, 182         ; Prepare the speaker for the
	out 43h, al         ; note.

	mov ax,pitch		; Frequency number (in decimal)for middle C.
	out 42h, al         ; Output low byte.
	mov al, ah          ; Output high byte.
	out 42h, al 

	in  al, 61h         ; Turn on note (get value from port 61h).
	or  al, 00000011b   ; Set bits 1 and 0.
	out 61h, al         ; Send new value.

	mov cx,duration		; Pause for duration of note.
	mov dx,0fh
	mov ah,86h			; CX:DX = how long pause is? I'm not sure exactly how it works but it's working
	int 15h				; Pause for duration of note.

	in  al, 61h         ; Turn off note (get value from
							;  port 61h).
	and al, 11111100b   ; Reset bits 1 and 0.
	out 61h, al         ; Send new value.
	
	mov cx,01h			;Pause to give the notes some separation
	mov dx,08h
	mov ah,86h
	int 15h
	endm