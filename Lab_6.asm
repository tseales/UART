;************************************************************************
; Filename: Lab_6														*
;																		*
; ELEC3450 - Microprocessors											*
; Wentworth Institute of Technology										*
; Professor Bruce Decker												*
;																		*
; Student #1 Name: Takaris Seales										*
; Course Section: 03													*
; Date of Lab: <07-19-2017>												*
; Semester: Summer 2017													*
;																		*
; Function: This program uses the UART to remotely control LEDs			* 
; on another PIC Board by controlling the Tramsceive and Receive  		*
; Registers and also utilizing Timer2									*	
;																		*
; Wiring: 																*
; Four RC0-RC3 switches connected to first four LEDs       				*	
; Four RB0-RB3 switches connected to last four LEDs						*
; RC6 connected to USART Transceiver, RC7 connected to USART Receiver	*
; RD0-RD7 connected to Debounced Switches S10-S17						*
;************************************************************************												*
; A register may hold an instruction, a storage address, or any kind of data
;(such as a bit sequence or individual characters)
;BYTE-ORIENTED INSTRUCTION:	
;'f'-specifies which register is to be used by the instruction	
;'d'-designation designator: where the result of the operation is to be placed
;BIT-ORIENTED INSTRUCTION:
;'b'-bit field designator: selects # of bit affected by operation
;'f'-represents # of file in which the bit is located
;
;'W'-working register: accumulator of device. Used as an operand in conjunction with
;	 the ALU during two operand instructions															*
;************************************************************************

		#include <p16f877a.inc>

TEMP_W					EQU 0X21			
TEMP_STATUS				EQU 0X22	
TEMP_B					EQU 0X23
TEMP_C					EQU 0X24

		__CONFIG		0X373A 				;Control bits for CONFIG Register w/o WDT enabled			

		
		ORG				0X0000				;Start of memory
		GOTO 		MAIN

		ORG 			0X0004				;INTR Vector Address
PUSH										;Stores Status and W register in temp. registers

		MOVWF 		TEMP_W
		SWAPF		STATUS,W
		MOVWF 		TEMP_STATUS
		GOTO		INTR

POP											;Restores W and Status registers
	
		SWAPF		TEMP_STATUS,W
		MOVWF		STATUS
		SWAPF		TEMP_W,F
		SWAPF		TEMP_W,W				
		RETFIE

INTR										;ISR FOR Transmit and Receive
		BTFSC		PIR1, TXIF				;Checks to see if TXREG is empty (Flag Set)
		CALL 		TransmitLoop
		BTFSC		PIR1, RCIF				;Checks to see if transfer is complete (Flag Set)
		CALL		ReceiveLoop 

		GOTO 		POP
				


MAIN
		CLRF 		PORTB					;Clear GPIOs to be used
		CLRF		PORTC
		CLRF		PORTD
		BCF			INTCON, GIE				;Disable all interrupts
		BSF			STATUS, RP0				;Bank1
		MOVLW		0X00					;Set RB0-RB5 as outputs for LEDs
		MOVWF		TRISB	
		MOVLW		0X80					;Set RC0-RC5 as outputs for LEDs, RC6 as output for TX, RC7 as input for RX
		MOVWF		TRISC	
		MOVLW		0XFF					;Set Port D as all inputs for switches
		MOVWF		TRISD			
		MOVLW		0X26					;Asynchronous mode, BRGH = 1 for High Speed, parity bit set to 0
		MOVWF		TXSTA
		MOVLW		0X81					;Set Baud Rate (9600)
		MOVWF		SPBRG
		BSF			PIE1, RCIE				;Enable USART Receive Interrupt Enable Bit
		BSF			PIE1, TXIE				;Enable USART Transmit Interrupt Enable Bit
		BCF			STATUS, RP0				;Bank0
		BSF			PIR1, RCIF				;Enable USART Receive Interrupt Flag Bit
		BSF			PIR1, TXIF				;Enable USART Transmit Interrupt Flag Bit
		MOVLW		0X90					;Asynchronous Mode, parity bit always set at 0
		MOVWF		RCSTA
		BSF 		INTCON, PEIE			;Enable Peripheral Interrupts
		BSF			INTCON, GIE				;Enable all interrupts
		MOVF		PORTD, W				;Start Transmission
		MOVWF		TXREG

LOOP
		NOP
		
		GOTO 		LOOP
		


TransmitLoop
		MOVF		PORTD, W
		MOVWF		TXREG

		RETURN

ReceiveLoop
		BCF			STATUS, C
		BTFSC		RCSTA, OERR				;Checks Overrun Error Bit
		GOTO		Overrun
		BTFSC		RCSTA, FERR				;Checks Framing Error Bit
		GOTO		Framing
		MOVF		RCREG, W
		ANDLW		0X0F					;Take LSBs and store into TEMP_C
		MOVWF		TEMP_C
		MOVF		RCREG, W
		MOVWF		TEMP_B					
		RRF			TEMP_B,(F)				;Get MSBs and store into TEMP_B
		RRF			TEMP_B,(F)				
		RRF			TEMP_B,(F)				
		RRF			TEMP_B,(F)				
		MOVLW		0X0F
		ANDWF		TEMP_B, F
		MOVF		TEMP_C, W
		MOVWF		PORTC
		MOVF		TEMP_B, W
		MOVWF		PORTB
		

		RETURN
		
	
Overrun		
		BCF			RCSTA, CREN				;Clears OERR by clearing then setting CREN bit
		BSF			RCSTA, CREN				;(resets receive logic)
		CLRF 		RCREG					;Dumps Receiver Register and returns to interrupt

		GOTO		POP	

Framing
		CLRF		RCREG					;Dumps Receiver Register
		
		GOTO		POP



		END
