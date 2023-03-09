;---------------------------------- Encabezado ---------------------------------
;Archivo: Laboratorio5.s
;Dispositivo: PIC16F887
;Autor: Judah Pérez 21536
;Compilador: pic-as (v2.40), MPLAB X IDE v6.05
;
;Programa: Generador de funciones
;Hardware: ...
;	   
;	   
;	   
;	   
;
;Creado: 20/02/23
;Última modificación: 26/02/23
;
;-------------------------------------------------------------------------------
    PROCESSOR 16F887
    #include <xc.inc>    
    #include "macros.s"

;configuration word 1
    CONFIG FOSC  = INTRC_NOCLKOUT //OSCILADOR INTERNO SIN SALIDA
    CONFIG WDTE	 = OFF //WDT DISSABLED (REINICIO REPETITIVO DEL PIC)
    CONFIG PWRTE = OFF //PWRT ENABLED (ESPERA 72ms AL INICIAR)
    CONFIG MCLRE = OFF //EL PIN DE MCLR SE UTILIZA COMO I/O
    CONFIG CP	 = OFF //SIN PROTECCIÓN DE CÓDIGO
    CONFIG CPD	 = OFF //SIN PROTECCIÓN DE DATOS
    
    CONFIG BOREN = OFF //SIN REINICIO CUANDO EL VOLTAJE DE ALIMENTACIÓN BAJA DE 4V
    CONFIG IESO  = OFF //REINICIO SIN CAMBIO DE RELOJ INTERNO A EXTERNO
    CONFIG FCMEN = OFF //CAMBIO DE RELOJ EXTERNO A INTERNO EN CASO DE FALLO
    CONFIG LVP	 = OFF //PROGRAMACIÓN EN BAJO VOLTAJE PERMITIDA
    
;configuration word 2
    CONFIG WRT   = OFF //PROTECCIÓN DE AUTOESCRITURA POR EL PROGRAMA DESACTIVADA
    CONFIG BOR4V = BOR40V //REINICIO ABAJO DE 4V, (BOR21V>2.1V)
;
;---------------------------------- Variables ----------------------------------
btnFrecUp   EQU	0	;Button increase frequency
btnFrecDwn  EQU	2	;Button decrease frequency
btnHz	    EQU	4	;Button set frequency to Hz
btnkHz	    EQU	6	;Button set frequency to kHz
btnWave	    EQU	7	;Button Change Waveform

disp0en	    EQU	0	;Display 0 enable RD pin
disp1en	    EQU	1	;Display 1 enable RD pin
disp2en	    EQU	2	;Display 2 enable RD pin
disp3en	    EQU	3	;Display 3 enable RD pin
  
PSECT udata_bank0 ;common memory
    ;Wave variables
    wave_ctrl:	DS  1	;Waveform controler
    wave_count:	DS  1	;Wave counter
    wave_sel:	DS  1	;Waveform Selector
    ;Frequency variables
    TMR0_n:	DS  1	;TMR0 variable N value (frequency control)
    freq_dig:	DS  4	;Thousands (+3), Hundreads(+2), Tens(+1) & Ones(0) digits in binary
    disp_out:	DS  4	;Thousands (+3), Hundreads(+2), Tens(+1) & Ones(0) display output
    disp_sel:	DS  1	;Display selector (LSB only)
    ;Macros variables
    count_val:	DS  1	;Store counters value
    mod10:	DS  1	;Module 10 for binary to decimal convertion
    rotations:	DS  1	;Rotations counter for binary to decimal convertion
    
PSECT udata_shr	;common memory
    W_temp:	    DS  1	;Temporary W
    STATUS_temp:    DS	1	;Temporary STATUS
    
;--------------------------------- Vector Reset --------------------------------
PSECT resVect, class=CODE, abs, delta=2
ORG 0000h	    ;posicion 0000h para el reset
    resetVec:
	PAGESEL main
	goto main
	
;------------------------------- Interrupt Vector ------------------------------
PSECT intVect, class=CODE, abs, delta=2
ORG 0004h    ;posición para las interrupciones
	
    push:	;Tamporarily save State before interrupt
	movwf	W_temp		;Copy W to temp register
	swapf	STATUS,	W	;Swap status to be saved into W
	movwf	STATUS_temp	;Save status to STATUS_temp
    isr:	;Interrupt Instructions (Interrupt Service Routine)
	btfsc	RBIF
	call	ioc_PortB
	btfsc	T0IF
	call	T0IF_inter
    pop:	;Restore State before interrupt
	swapf	STATUS_temp,W	;Reverse Swap for status and save into W
	movwf	STATUS		;Move W into STATUS register (Restore State)
	swapf	W_temp,	f	;Swap W_temp nibbles
	swapf	W_temp,	W	;Reverse Swap for W_temp and place it into W
    retfie
;-------------------------- Subrutinas de Interrupcion -------------------------    
    ioc_PortB:
	;Verify which button triggered the interupt
	banksel	PORTA
	btfsc	PORTB,	btnFrecUp
	goto	$+4	;Check next button
	movlw	5
	addwf	TMR0_n, F
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnFrecDwn
	goto	$+4	;Check next button
	movlw	5
	subwf	TMR0_n, F
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnWave
	goto	$+5	;Check next button
	incf	wave_sel,   F
	clrf	PORTA	;Reset to avoid waveform flaws
	bsf	wave_ctrl,  5	;Start increase
	goto	reset_RBIF  ;Skip following buttons
	
	;btfss	PORTB,	btnHz
	;decf	PORTA
	
	;btfss	PORTB,	btnkHz
	;decf	PORTA
	
	reset_RBIF:
	bcf	RBIF	;Reset OIC flag
    return

    T0IF_inter:
	;Reset TMR0
	movf	TMR0_n, W   ;reset TRM0 count
	movwf	TMR0
	bcf	T0IF	    ;Reset TMR0 overflow flag
	bsf	wave_ctrl, 4	;Next step of waveform	
    return
	
;------------------------------------ Tablas -----------------------------------
PSECT code, delta=2, abs
ORG 0100h    ;posición para el código

display7_table:
    clrf    PCLATH	
    bsf	    PCLATH, 0	;0100h
    addwf   PCL,    f	;Offset
    retlw   00111111B   ;0
    retlw   00000110B   ;1
    retlw   01011011B   ;2
    retlw   01001111B   ;3
    retlw   01100110B   ;4
    retlw   01101101B   ;5
    retlw   01111101B   ;6
    retlw   00000111B   ;7
    retlw   01111111B   ;8
    retlw   01101111B   ;9
    retlw   01110111B   ;A
    retlw   01111100B   ;B
    retlw   00111001B   ;C
    retlw   01011110B   ;D
    retlw   01111001B   ;E
    retlw   01110001B   ;F
    retlw   01110110B   ;X "Offset > 15"
	   ;_gfedcba segments
	   
;------------------------------- Configuración uC ------------------------------

    main:
	call	config_io	;Configure Inputs/Outputs
	call	config_TMR0	;Configure TMR0
	call	config_ie	;Configure Interrupt Enable
	call	init_portNvars	;Initialize Ports and Variables

;-------------------------------- Loop Principal -------------------------------
    loop:
	call	waveform_select
	call	create_waveform
	
	call	get_digits	;Get frequency's value in decimal digits
	call	fetch_disp_out	;Prepare displays outputs
	call	show_display	;Show display output
	;Change selected display
	;incf	disp_sel
	goto	loop	    ;loop forever
	
;--------------------------------- Sub Rutinas ---------------------------------
    ;*****Set-Up Subroutines*****
    config_io:
	banksel ANSEL
	clrf	ANSEL	    ;PortA & PortE Digital
	clrf	ANSELH	    ;PortB Digital
	
	banksel TRISA
	clrf	TRISA	    ;PortA Output
	clrf	TRISC	    ;PortC Output
	clrf	TRISD	    ;PortD Output
	clrf	TRISE	    ;PortE Output
	
	bsf	TRISB,	btnFrecUp	;Input on buttons
	bsf	TRISB,	btnFrecDwn	;
	bsf	TRISB,	btnHz		;
	bsf	TRISB,	btnkHz		;
	bsf	TRISB,	btnWave		;
	bsf	WPUB,	btnFrecUp	;Pull-up's on buttons
	bsf	WPUB,	btnFrecDwn	;
	bsf	WPUB,	btnHz		;
	bsf	WPUB,	btnkHz		;
	bsf	WPUB,	btnWave		;
	
	bcf	OPTION_REG, 7	;Enable PortB Internal Pull-ups
    return
    
    config_TMR0:
	bsf	OSCCON,	6   ;Internal clock 8 MHz
	bsf	OSCCON,	5   
	bsf	OSCCON,	4   
	bsf	OSCCON,	0	
	
	bcf	OPTION_REG, 5	;TMR0 internal instruction cycle source 
	bcf	OPTION_REG, 4	;Low-to-High transition
	bcf	OPTION_REG, 3	;Prescaler assigned to TMR0 module
	
	bsf	OPTION_REG, 2	;TMR0 prescaler 1:64
	bcf	OPTION_REG, 1	
	bsf	OPTION_REG, 0
    return
    
    config_ie:
	bsf	INTCON,	7	;Enable Global Interrupt
	
	bsf	INTCON,	5	;Enable TMR0 Overflow Interrupt
	
	bsf	INTCON,	3	;Enable PortB Interrupts
	bsf	IOCB,	btnFrecUp	;Enable Interrupt-on-Change
	bsf	IOCB,	btnFrecDwn	;
	bsf	IOCB,	btnHz		;
	bsf	IOCB,	btnkHz		;
	bsf	IOCB,	btnWave		;
    return
    
    init_portNvars:
	banksel PORTA	    ;Clear Output Ports
	clrf	PORTA
	clrf	PORTC
	clrf	PORTD
	clrf	PORTE
	clrw
	bsf	wave_ctrl,  5	;Start increase
    return
    
    ;*****Funtion Generator*****    
    waveform_select:    ;wave_sel 00 - square, 01saw 10trian 11sine
	btfsc	wave_sel,   1
	goto	sel_triangle
	btfsc	wave_sel,   0
	goto	sel_sawtooth
	
	sel_square:
	bcf wave_ctrl,  3   ;sine
	bsf wave_ctrl,  0   ;square
    return    
	sel_sawtooth:
	bcf wave_ctrl,  0   ;square
	bsf wave_ctrl,  1   ;sawtooth
    return    
	sel_triangle:
	    btfsc	wave_sel,   0
	    goto	sel_sine
	bcf wave_ctrl,  1   ;sawtooth
	bsf wave_ctrl,  2   ;triangle
    return    
	sel_sine:
	bcf wave_ctrl,  2   ;triangle
	bsf wave_ctrl,  3   ;sine
    return
      
    create_waveform:
	btfss	wave_ctrl, 4	;Waveform next step requested
	return	;Return if not requested	
	;Check selected waveform
	btfsc	wave_ctrl,  0
	call	square_wave
	btfsc	wave_ctrl,  1
	call	sawtooth_wave
	btfsc	wave_ctrl,  2
	call	triangle_wave
	btfsc	wave_ctrl,  3
	call	sawtooth_wave
	
	bcf	wave_ctrl, 4	;Waveform step compleated
    return
    
    square_wave:
	incf	wave_count, F
	movf	wave_count, W
	sublw	128	    ;Compare counter at half period
	btfss	STATUS,	0   ;Check ~Borrow flag
	goto	$+4	;Skip set
	movlw	255	;Set to HIGH on first half
	movwf	PORTA	;
	return		
	clrf	PORTA	;Reset to LOW on second half
    return
    
    sawtooth_wave:	
	incf	PORTA	
    return
    
    triangle_wave:
	btfss	wave_ctrl,  5	;Check increase
	goto	$+9	;Jump to decrease
	incf	PORTA
	incf	PORTA, W
	btfsc	STATUS,	2 ;Check Zero flag, if zero dont store inc and start decrease, no zero store
	goto	$+3	    ;Skip inc and start decrease
	movwf	PORTA	;Store increment
	return
	bcf	wave_ctrl,  5	;Start decrease
	return	
		
	decf	PORTA
	btfsc	STATUS,	2 ;Check Zero flag
	goto	$+3
	decf	PORTA	;dectement again
	return
	bsf	wave_ctrl,  5	;Start increase
    return
    
    ;*****Frequency Display*****    
     get_digits:
	bin_to_dec  TMR0_n,freq_dig
	bin_to_dec  count_val,freq_dig+1
	bin_to_dec  count_val,freq_dig+2
	bin_to_dec  count_val,freq_dig+3
    return
    
    fetch_disp_out:
	display7_decode	freq_dig,   disp_out   ;Ones display	
	display7_decode	freq_dig+1, disp_out+1 ;Tens display	
	display7_decode	freq_dig+2, disp_out+2 ;Hundreds display
	display7_decode	freq_dig+3, disp_out+3 ;Thousands display
    return
    
    show_display:
	btfsc	disp_sel,   1
	goto	display_2
	btfsc	disp_sel,   0
	goto	display_1
	
	display_0: ;Ones
	bcf	PORTD,	disp3en	;Disable display 2
	movf	disp_out, W	;Load display 0 value
	movwf	PORTC		;to PortC
	bsf	PORTD,	disp0en	;Enable display 0
    return    
	display_1: ;Tens
	bcf	PORTD,	disp0en	;Disable display 0
	movf	disp_out+1, W	;Load display 1 value
	movwf	PORTC		;to PortC
	bsf	PORTD,	disp1en	;Enable display 1
    return    
	display_2: ;Hundreds
	    btfsc   disp_sel,   0
	    goto    display_3
	bcf	PORTD,	disp1en	;Disable display 1
	movf	disp_out+2, W	;Load display 1 value
	movwf	PORTC		;to PortC
	bsf	PORTD,	disp2en	;Enable display 2
    return    
	display_3: ;Thousands
	bcf	PORTD,	disp2en	;Disable display 1
	movf	disp_out+3, W	;Load display 1 value
	movwf	PORTC		;to PortC
	bsf	PORTD,	disp3en	;Enable display 2
    return
    
    END







