;Final project: Towers of Hanoi
;Author: Aaron Prichard
;Date: 05 Dec 2021
;Description: Demonstrates use of Recursive algorithms through a game of moving rings of varying size from a 
;			  starting rod to a target rod with some rod in between.
;Issues: Intermittent issue where ring will refuse to move to the middle base. On new game, moves whole ring stack sometimes.
.model small 
.stack 100h	 
.data 
	gameState dw 1,2,3,0,0,0,0,0,0,0
	intro db 10,13,'Towers of Hanoi',10,13,10,13,'$'
	menu db 10,13,'Enter 2 to target 2nd platform or 3 to target 3rd platform',10,13,'(win by stacking rings on target platform)','$'
	ringSmall db 240,240,240,240,240,240,10,13, '$'
	ringMed db 240,240,240,240,240,240,240,240,240,240,240,240,10,13, '$'
	ringLarge db 240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,240,10,13, '$'
	base db 177,177,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,219,177,177, '$'
	promptFrom db 'Move ring from? (1, 2, 3):','$'
	promptTo db 'Move ring to? (1, 2, 3):','$'
	winMessage db 'You Won!', '$'
	playAgain? db 'Enter 1 to play again...', '$'
	targetLabel db 'TARGET BASE: ', '$'
	baseTo dw ?
	baseFrom dw ?
	comma db ', $'
	newline db 10,13,'$'
	color  db 20h
	winColor db 1eh
	target dw 3
	smallX db ?
	smallY db ?
	medX db ?
	medY db ?
	largeX db ?
	largeY db ?
	topRing db ?
	topFrom dw ?
	index dw ?
	
.code ;start of assembly code segment
	extrn indec: proc
	extrn outdec: proc
	include myMacros.asm
.386
main proc

	mov ax,@data
	mov ds,ax
	
	;set up screen and construct
	replay:
	mov smallX, 12
	mov smallY, 10
	mov medX, 9
	mov medY, 11
	mov largeX, 7
	mov largeY, 12
	clearScrn
	changColor color
	prtStr intro
	prtStr menu
	call indec
	mov target, ax
	clearScrn
	changColor color
	call printBoard
	;loop through procedures to print board, get input, and move rings
	GameLoop:
	clearScrn
	changColor color
	moveCursor 20, 5
	prtStr targetLabel
	mov ax, target
	call outdec
	call printBoard
	sound 4560 , 1
	prtStr newline
	call moveRing
	call updateDistance
	call updateHeight
	call printBoard
	checkWin target
	cmp ax, 1
	je Win
	jmp GameLoop
	;check if checkWin macro returned a 1 and output win screen
	Win:
	changColor winColor
	call initMode
	moveCursor 15, 10
	prtStr winMessage
	sound 3416 , 2
	sound 3224, 3
	prtStr newline
	prtStr playAgain?
	call indec
	cmp ax, 1
	je replay
	mov ah,4ch
	int 21h
	
main endp
;magnify win screen text
initMode proc

	mov ah,00h	; set video mode
	mov al,04h	; 40x25x16 colors cga mode
	int 10h
	ret
	
initMode endp
;print rings at what ever their x and y are set to and print bases underneath
printBoard proc
	moveCursor smallX, smallY
	prtStr ringSmall
	moveCursor medX, medY
	prtStr ringMed
	moveCursor largeX, largeY
	prtStr ringLarge
	moveCursor 5, 13
	prtStr base
	moveCursor 25, 13
	prtStr base
	moveCursor 45, 13
	prtStr base
	ret
printBoard endp
;set the x value to the distance from the left for the correct base by comparing to every third index
updateDistance proc
	xor ax, ax
	xor bx, bx
	xor cx, cx
	
	searching:
	inc cx
	cmp cx, 9
	jg continue
	mov ax, gameState+bx
	cmp ax, 0
	je skip
	cmp ax, 1
	je updateSmall
	cmp ax, 2
	je updateMed
	cmp ax, 3
	je updateLarge
	
	updateSmall:
	add bx, 2
	cmp cx, 3
	jg second
	mov smallX, 12
	jmp searching
	second:
	cmp cx, 6
	jg third
	mov smallX, 32
	jmp searching
	third:
	mov smallX, 52
	jmp searching
	
	updateMed:
	add bx, 2
	cmp cx, 3
	jg second1
	mov medX, 9
	jmp searching
	second1:
	cmp cx, 6
	jg third1
	mov medX, 29
	jmp searching
	third1:
	mov medX, 49
	jmp searching
	
	updateLarge:
	add bx, 2
	cmp cx, 3
	jg second2
	mov largeX, 7
	jmp searching
	second2:
	cmp cx, 6
	jg third2
	mov largeX, 27
	jmp searching
	third2:
	mov largeX, 47
	jmp searching
	
	skip:
	add bx, 2
	jmp searching
	
	continue:
	ret	
updateDistance endp
;change y value for each ring based on it's index in 3-index-wide sub arrays in the findIndex macro
updateHeight proc
	
	findIndex 1
	cmp ax, 1
	jl highest
	je middle
	jg lowest
	
	highest:
	mov smallY, 10
	jmp ringTwo
	middle:
	mov smallY, 11
	jmp ringTwo
	lowest:
	mov smallY, 12
	
	ringTwo:
	findIndex 2
	cmp ax, 1
	jl highest1
	je middle1
	jg lowest1
	
	highest1:
	mov medY, 10
	jmp ringThree
	middle1:
	mov medY, 11
	jmp ringThree
	lowest1:
	mov medY, 12	
	
	ringThree:
	findIndex 3
	cmp ax, 1
	jl highest2
	je middle2
	jg lowest2
	
	highest2:
	mov largeY, 10
	jmp heightSet
	middle2:
	mov largeY, 11
	jmp heightSet
	lowest2:
	mov largeY, 12
	
	heightSet:
	ret
endp
;remove and add 'rings' by finding the highest value in its respective subarray and replacing it with a zero and adding
;that value to the first nonzero index in the target subarray
moveRing proc
	prtStr promptFrom
	call indec
	mov baseFrom, ax
	prtStr promptTo
	call indec
	mov baseTo, ax
	cmp baseFrom, 2
	jl firstBase
	je secondBase
	jg thirdBase
	
	firstBase:
	mov baseFrom, 0
	jmp movingTo
	secondBase:
	mov baseFrom, 6
	jmp movingTo
	thirdBase:
	mov baseFrom, 12
	
	movingTo:
	cmp baseTo, 2
	jl firstBase2
	je secondBase2
	jg thirdBase2
	
	firstBase2:
	mov baseTo, 0
	jmp Valid
	secondBase2:
	mov baseTo, 6
	jmp Valid
	thirdBase2:
	mov baseTo, 12
	jmp Valid
;check if valid move. if the target base is empty, jump to moving the ring there. Then check if top of stack being moved
;is less than the top of the stack being moved to
valid:
findTop baseFrom
mov topFrom, ax
findTop baseTo
cmp ax, 0
je ringMoved
cmp topFrom, ax
jge invalid
	
ringMoved:
removeRing baseFrom
addRing baseTo, topRing
invalid:
ret
moveRing endp

end main