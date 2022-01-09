TITLE ASCII Conversion    (Proj6_jenseluc.asm)

; Author: Lucas Jensen
; Last Modified: 12/5/21
; OSU email address: jenseluc@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:  6 - portfolio     Due Date: 12/5/21
; Description: This program collects 10 numbers (as strings) from the user and verifies that they
;	are both numeric and small enough for a 32 bit register, prints the valid input back to the user
;	and then displays some basic statistics.

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Prompts the user for input, and stores that value as a string, up to a maximum size
;
; Preconditions: some empty string exists and is used as a parameter, along with a
;					prompt message
;
; Receives:
; prompt = a string that prompts the user for input, by reference
; storage = an empty string in memory for storing their input. by reference
;
; returns: storage contains the user's input
; ---------------------------------------------------------------------------------
mGetString	MACRO	prompt, storage
	PUSH	EDX				; preserve EDX
	PUSH	ECX				; preserve ECX
	MOV		EDX, prompt
	call	WriteString

	MOV		EDX, storage
	MOV		ECX, MAXSIZE
	call	ReadString
	MOV		EBX, EAX

	; EBX contains string length

	POP		ECX				; restore ECX
	POP		EDX				; restore EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Prints a string which has been provided as a parameter
;
; Preconditions: a reference to a string is being used as a parameter
;
; Receives:
; string = the input string, by reference
;
; returns: the input string is printed
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	string
	
	PUSH	EDX				; preserve EDX
	MOV		EDX, string
	call	WriteString

	POP		EDX				; restore EDX
ENDM

	NUMINTS = 10
	MAXSIZE = 13

.data
	intro1		BYTE	"Assignment 6: ASCII Conversion Nightmare",13,10,"Programmed by: Lucas Jensen",13,10,13,10,0
	intro2		BYTE	"Please provide 10 signed decimal integers.",13,10,"Each number needs to be small "
				BYTE	"enough to fit inside a 32 bit register. After you have finished inputting the raw "
				BYTE	"numbers I will display a list of the integers, their sum, and their average value.",13,10,13,10,0

	prompt1		BYTE	"Please enter a signed number: ",0

	error1		BYTE	"ERROR: You did not enter a signed number or your number was too big. Try again",13,10,0

	inString	BYTE	MAXSIZE DUP(?)

	; outString is used for storage
	outString	BYTE	15 DUP(?)
	; outString2 is used for (un)reversing a string
	outString2	BYTE	15 DUP(?)

	intArray	SDWORD	NUMINTS DUP(?)

	tempVal		SDWORD	?

	message		BYTE	"You entered the following numbers (printed backwards for convenience):",0

	finalNums	BYTE	"You entered the following numbers: ",13,10,0

	sumMsg		BYTE	"The sum of these numbers is: ",0
	avgMsg		BYTE	"The truncated average is: ",0

	commSp		BYTE	", ",0

	byeMsg		BYTE	"Thanks for playing!",13,10,0




.code
main PROC
; ---------------------------------------------------------------------------------
; introduction printing
; ---------------------------------------------------------------------------------
	PUSH			OFFSET intro1
	PUSH			OFFSET intro2
	call			introduction

	MOV				ECX, NUMINTS
	MOV				EDI, OFFSET intArray
	CLD				; clear direction flag, for safety

; ---------------------------------------------------------------------------------
; first main loop: gets input from the user and validates it, and stores validated
;	data into intArray
; ---------------------------------------------------------------------------------
_loop:
	PUSH			ECX

	PUSH			OFFSET tempVal
	PUSH			OFFSET error1
	PUSH			OFFSET prompt1
	PUSH			OFFSET inString
	call			ReadVal

	; add value in EAX to array
	MOV				[EDI], EAX
	ADD				EDI, 4

	POP				ECX
	LOOP			_loop
	
	call			CrLf
	mDisplayString	OFFSET finalNums

	MOV				ECX, NUMINTS
	MOV				EDX, OFFSET intArray

; ---------------------------------------------------------------------------------
; 2nd main loop: print each value in array using mDisplayString
; ---------------------------------------------------------------------------------
_loop2:
	PUSH			ECX
	MOV				EAX, [EDX]
	PUSH			EDX

	; numeric value from array is in EAX
	PUSH			EAX
	PUSH			OFFSET outString
	call			WriteVal

	MOV				EDX, 0
	POP				EDX
	ADD				EDX, 4
	POP				ECX
	CMP				ECX, 1
	JE				_skip				; on the final iteration, don't print a comma
	mDisplayString	OFFSET commSp
_skip:
	LOOP			_loop2
	call			CrLf

; ---------------------------------------------------------------------------------
; find and display sum using mDisplayString
; ---------------------------------------------------------------------------------
	MOV				ECX, LENGTHOF intArray
	MOV				ESI, OFFSET intArray
	MOV				EDX, 0
_sumLoop:
	MOV				EAX, [ESI]
	ADD				EDX, EAX
	ADD				ESI, 4
	LOOP			_sumLoop
	; EDX now holds the sum
	mDisplayString	OFFSET sumMsg
	PUSH			EDX					; preserve sum

	PUSH			EDX
	PUSH			OFFSET outString
	call			WriteVal
	call			CrLf

; ---------------------------------------------------------------------------------	
; find and display average
; ---------------------------------------------------------------------------------
	POP				EAX					; restore sum into EAX
	MOV				EBX, 10
	CDQ
	IDIV			EBX
	; truncated average now in EAX
	mDisplayString	OFFSET avgMsg
	PUSH			EAX
	PUSH			OFFSET outString
	call			WriteVal
	call			CrLf
	
; ---------------------------------------------------------------------------------
; say bye!
; ---------------------------------------------------------------------------------
	call			CrLf
	mDisplayString	OFFSET byeMsg

	Invoke ExitProcess,0	; exit to operating system
main ENDP


; ---------------------------------------------------------------------------------
; Name: introduction
; Description: prints an introduction to the user
; Preconditions: two introduction strings have been defined and pushed
; Postconditions: stack is cleared, EDX still points to a string
; Receives: [EBP + 8] = intro2 string reference
;			[EBP + 12] = intro1 string reference
; Returns: Two messages are printed for the user
; ---------------------------------------------------------------------------------
introduction PROC
	PUSH	EBP
	MOV		EBP, ESP

	MOV		EDX, [EBP + 12]
	call	WriteString

	MOV		EDX, [EBP + 8]
	call	WriteString

	POP		EBP
	RET		8
introduction ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
; Description: Gets, verifies, and stores 10 signed integers from the user
; Preconditions: mGetString has been defined, error1 and prompt1 strings have been defined and PUSHed
; Postconditions: EAX, EBX, ECX, EDX, ESI are all modified. 
; Receives: [EBP + 8]  = inString reference
;			[EBP + 12] = prompt1 string reference
;			[EBP + 16] = error1 string reference
; Returns: EAX holds the numeric input from the user
; ---------------------------------------------------------------------------------
ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP

_getInput:

	mGetString	[EBP + 12], [EBP + 8]	; prompt in EBP + 12, inString in EBP + 8

	; validate user input
	MOV		ECX, EBX
	MOV		ESI, [EBP + 8]
_validate:
	CMP		EBX, 12
	JGE		_error

	LODSB				; current byte into AL
	CMP		ECX, EBX
	JNE		_ignoreSign

	CMP		AL, 45
	JE		_success
	CMP		AL, 43
	JE		_success

	_ignoreSign:

	CMP		AL, 48
	JL		_error
	CMP		AL, 58
	JGE		_error

	JMP		_success

	_error:
	MOV		EDX, [EBP + 16]
	call	WriteString
	JMP		_getInput
	
	_success:
	LOOP	_validate

	; ASCII to integer
	MOV		ECX, EBX
	MOV		ESI, [EBP + 8]

	PUSH	EDI
	MOV		EDI, 0		; EDI will be our integer "builder" and starts at zero every time

_convert:
	LODSB				; current byte into AL
	CMP		AL, 43
	JE		_skip		; if the first char is +, then our signed integer is already taken care of
	CMP		AL, 45
	JE		_skip		; if the first char is -, we also skip, but will come back to this later

	MOV		EDX, 0
	MOV		DL, AL
	SUB		DL, 48
	IMUL	EAX, EDI, 10
	ADD		EAX, EDX
	MOV		EDI, EAX
	_skip:
	LOOP	_convert

	PUSH	EAX			; preserve EAX

; ---------------------------------------------------------------------------------
; check for and handle negative numbers
; ---------------------------------------------------------------------------------
	MOV		ESI, [EBP + 8]
	LODSB
	CMP		AL, 45
	JNE		_notNeg

	POP		EAX
	NEG		EAX
	JMP		_neg		; restore EAX

	_notNeg:
	POP		EAX			; restore EAX
	_neg:

	; EAX now holds the integer of the user input
	MOV		[EBP + 16], EAX

	POP		EDI
	POP		EBP
	RET		16
ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
; Description: Converts a numeris SDWORD to a string
; Preconditions: a string for output has been defined and PUSHed, along with a numeric value to 
;		convert and print
; Postconditions: EAX, EBX, ECX, EDX, EDI, ESI are all modified. Nobody left behind.
; Receives: [EBP + 8]  = reference to the new string (to be built)
;			[EBP + 12] = numeric value to convert
; Returns: a new string is created and not reversed! That string is printed.
; ---------------------------------------------------------------------------------
WriteVal PROC
	PUSH	EBP
	MOV		EBP, ESP

	MOV		EDI, [EBP + 8]		; EDI points to outString
	MOV		EAX, [EBP + 12]		; numeric value is in EAX
	MOV		ECX, 14
	CMP		EAX, 0
	JGE		_toLoop				; handle negative sign
	NEG		EAX
_toLoop:
_loop:
	; EAX already has value to be divided
	CDQ
	MOV		EBX, 10
	IDIV	EBX
	; EDX holds remainder
	ADD		EDX, 48
	MOV		ESI, EAX

	MOV		EAX, 0
	MOV		AL, DL
	STOSB

	MOV		EAX, ESI
	CMP		EAX, 0
	JE		_exit
	LOOP	_loop
_exit:
	MOV		EAX, [EBP + 12]
	CMP		EAX, 0
	JGE		_positive
	MOV		EAX, 45
	STOSB
_positive:
	MOV		EAX, 0
	STOSB
	; outString now exists but is reversed

; ---------------------------------------------------------------------------------
; Now for the fun task for (un)reversing the string.  This will be accomplished
;	by PUSHing and POPing in order to flip the order.  These comments may be excessive
;	but I found this section to be extradorinarily confusing without them.
; ---------------------------------------------------------------------------------
	MOV		EAX, 0			; clear EAX, for safety
	MOV		ESI, [EBP + 8]	; ESI will track the string
	MOV		ECX, 15			; 15 is arbitrary. The loop will break before then
	mov		EDX, 0			; EDX will count the chars PUSHED
_revLoop1:
	; Push ascii values to the stack, next loop will pop them
	LODSB
	CMP		EAX, 0
	JE		_break
	PUSH	EAX
	INC		EDX
	LOOP	_revLoop1
_break:

	MOV		EDI, [EBP + 8]	; ESI will track the string
	MOV		ECX, EDX		; Loop for the number of times the previous loop did
_revLoop2:
	; pop values back to rebuild the string in the correct order
	POP		EAX
	STOSB
	LOOP	_revLoop2
	MOV		EAX, 0
	STOSB

	mDisplayString	[EBP + 8]

	POP		EBP
	RET		8
WriteVal ENDP

END main
