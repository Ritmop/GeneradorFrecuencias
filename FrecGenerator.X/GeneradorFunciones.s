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
TMR0_n	    EQU	61	;TMR0 value for display select update
freq_step   EQU	10	;TMR1 inc/dec frequency step

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
    TMR1_n:	DS  2	;TMR1 variable N value (frequency control)
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
	call	portB_inter
	btfsc	T0IF
	call	TMR0_inter
	btfsc	TMR1IF
	call	TMR1_inter
    pop:	;Restore State before interrupt
	swapf	STATUS_temp,W	;Reverse Swap for status and save into W
	movwf	STATUS		;Move W into STATUS register (Restore State)
	swapf	W_temp,	f	;Swap W_temp nibbles
	swapf	W_temp,	W	;Reverse Swap for W_temp and place it into W
    retfie
;-------------------------- Subrutinas de Interrupcion -------------------------    
    portB_inter:
	;Verify which button triggered the interupt
	banksel	PORTA
	btfsc	PORTB,	btnFrecUp
	goto	$+4	;Check next button
	movlw	freq_step
	addwf	TMR1_n+1, F
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnFrecDwn
	goto	$+4	;Check next button
	movlw	freq_step
	subwf	TMR1_n+1, F
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnWave
	goto	$+6	;Check next button
	incf	wave_sel,   F
	clrf	PORTA	    ;Reset output to avoid waveform flaws
	clrf	wave_count  ;
	bsf	wave_ctrl,  5	;Start increase
	goto	reset_RBIF  ;Skip following buttons
	
	;btfss	PORTB,	btnHz
	;decf	PORTA
	
	;btfss	PORTB,	btnkHz
	;decf	PORTA
	
	reset_RBIF:
	bcf	RBIF	;Reset OIC flag
    return

    TMR0_inter:
	;Reset TMR0
	movlw	TMR0_n	;Reset TRM0 count
	movwf	TMR0
	bcf	T0IF	;Reset TMR0 overflow flag
	;Change selected display
	incf	disp_sel, F	
    return
    
    TMR1_inter:
	;Reset TMR1
	;movf	TMR1_n, W  ;Reset TRM1 count
	;movlw	00101100B
	;movwf	TMR1L	    ;
	;movf	TMR1_n+1, W ;
	;movlw	11111100B
	;movwf	TMR1H	    ;
	movlw	11111001B
	movwf	TMR1H
	movlw	11011111B
	movwf	TMR1L
	
	bcf	TMR1IF	;Reset TMR1 overflow flag
	;Request waves next step
	bsf	wave_ctrl, 4
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
	   ;_gfedcba segments

ORG 01FFh
	   
sinewave_table:
    addwf   PCL,    f	;Offset
    retlw   128     ;0 rad
    retlw   131     ;0.024 rad
    retlw   134     ;0.049 rad
    retlw   137     ;0.073 rad
    retlw   141     ;0.098 rad
    retlw   144     ;0.123 rad
    retlw   147     ;0.147 rad
    retlw   150     ;0.172 rad
    retlw   153     ;0.197 rad
    retlw   156     ;0.221 rad
    retlw   159     ;0.246 rad
    retlw   162     ;0.271 rad
    retlw   165     ;0.295 rad
    retlw   168     ;0.320 rad
    retlw   171     ;0.344 rad
    retlw   174     ;0.369 rad
    retlw   177     ;0.394 rad
    retlw   180     ;0.418 rad
    retlw   183     ;0.443 rad
    retlw   186     ;0.468 rad
    retlw   188     ;0.492 rad
    retlw   191     ;0.517 rad
    retlw   194     ;0.542 rad
    retlw   196     ;0.566 rad
    retlw   199     ;0.591 rad
    retlw   202     ;0.615 rad
    retlw   204     ;0.640 rad
    retlw   207     ;0.665 rad
    retlw   209     ;0.689 rad
    retlw   212     ;0.714 rad
    retlw   214     ;0.739 rad
    retlw   216     ;0.763 rad
    retlw   218     ;0.788 rad
    retlw   221     ;0.813 rad
    retlw   223     ;0.837 rad
    retlw   225     ;0.862 rad
    retlw   227     ;0.887 rad
    retlw   229     ;0.911 rad
    retlw   231     ;0.936 rad
    retlw   233     ;0.960 rad
    retlw   234     ;0.985 rad
    retlw   236     ;1.010 rad
    retlw   238     ;1.034 rad
    retlw   239     ;1.059 rad
    retlw   241     ;1.084 rad
    retlw   242     ;1.108 rad
    retlw   243     ;1.133 rad
    retlw   245     ;1.158 rad
    retlw   246     ;1.182 rad
    retlw   247     ;1.207 rad
    retlw   248     ;1.231 rad
    retlw   249     ;1.256 rad
    retlw   250     ;1.281 rad
    retlw   251     ;1.305 rad
    retlw   252     ;1.330 rad
    retlw   253     ;1.355 rad
    retlw   253     ;1.379 rad
    retlw   254     ;1.404 rad
    retlw   254     ;1.429 rad
    retlw   255     ;1.453 rad
    retlw   255     ;1.478 rad
    retlw   255     ;1.503 rad
    retlw   255     ;1.527 rad
    retlw   255     ;1.552 rad
    retlw   255     ;1.576 rad
    retlw   255     ;1.601 rad
    retlw   255     ;1.626 rad
    retlw   255     ;1.650 rad
    retlw   255     ;1.675 rad
    retlw   254     ;1.700 rad
    retlw   254     ;1.724 rad
    retlw   253     ;1.749 rad
    retlw   253     ;1.774 rad
    retlw   252     ;1.798 rad
    retlw   251     ;1.823 rad
    retlw   251     ;1.847 rad
    retlw   250     ;1.872 rad
    retlw   249     ;1.897 rad
    retlw   248     ;1.921 rad
    retlw   247     ;1.946 rad
    retlw   245     ;1.971 rad
    retlw   244     ;1.995 rad
    retlw   243     ;2.020 rad
    retlw   241     ;2.045 rad
    retlw   240     ;2.069 rad
    retlw   238     ;2.094 rad
    retlw   237     ;2.119 rad
    retlw   235     ;2.143 rad
    retlw   233     ;2.168 rad
    retlw   232     ;2.192 rad
    retlw   230     ;2.217 rad
    retlw   228     ;2.242 rad
    retlw   226     ;2.266 rad
    retlw   224     ;2.291 rad
    retlw   222     ;2.316 rad
    retlw   220     ;2.340 rad
    retlw   217     ;2.365 rad
    retlw   215     ;2.390 rad
    retlw   213     ;2.414 rad
    retlw   210     ;2.439 rad
    retlw   208     ;2.463 rad
    retlw   205     ;2.488 rad
    retlw   203     ;2.513 rad
    retlw   200     ;2.537 rad
    retlw   198     ;2.562 rad
    retlw   195     ;2.587 rad
    retlw   192     ;2.611 rad
    retlw   190     ;2.636 rad
    retlw   187     ;2.661 rad
    retlw   184     ;2.685 rad
    retlw   181     ;2.710 rad
    retlw   178     ;2.735 rad
    retlw   176     ;2.759 rad
    retlw   173     ;2.784 rad
    retlw   170     ;2.808 rad
    retlw   167     ;2.833 rad
    retlw   164     ;2.858 rad
    retlw   161     ;2.882 rad
    retlw   158     ;2.907 rad
    retlw   155     ;2.932 rad
    retlw   151     ;2.956 rad
    retlw   148     ;2.981 rad
    retlw   145     ;3.006 rad
    retlw   142     ;3.030 rad
    retlw   139     ;3.055 rad
    retlw   136     ;3.079 rad
    retlw   133     ;3.104 rad
    retlw   130     ;3.129 rad
    retlw   126     ;3.153 rad
    retlw   123     ;3.178 rad
    retlw   120     ;3.203 rad
    retlw   117     ;3.227 rad
    retlw   114     ;3.252 rad
    retlw   111     ;3.277 rad
    retlw   108     ;3.301 rad
    retlw   105     ;3.326 rad
    retlw   101     ;3.351 rad
    retlw   98      ;3.375 rad
    retlw   95      ;3.400 rad
    retlw   92      ;3.424 rad
    retlw   89      ;3.449 rad
    retlw   86      ;3.474 rad
    retlw   83      ;3.498 rad
    retlw   80      ;3.523 rad
    retlw   78      ;3.548 rad
    retlw   75      ;3.572 rad
    retlw   72      ;3.597 rad
    retlw   69      ;3.622 rad
    retlw   66      ;3.646 rad
    retlw   64      ;3.671 rad
    retlw   61      ;3.695 rad
    retlw   58      ;3.720 rad
    retlw   56      ;3.745 rad
    retlw   53      ;3.769 rad
    retlw   51      ;3.794 rad
    retlw   48      ;3.819 rad
    retlw   46      ;3.843 rad
    retlw   43      ;3.868 rad
    retlw   41      ;3.893 rad
    retlw   39      ;3.917 rad
    retlw   36      ;3.942 rad
    retlw   34      ;3.967 rad
    retlw   32      ;3.991 rad
    retlw   30      ;4.016 rad
    retlw   28      ;4.040 rad
    retlw   26      ;4.065 rad
    retlw   24      ;4.090 rad
    retlw   23      ;4.114 rad
    retlw   21      ;4.139 rad
    retlw   19      ;4.164 rad
    retlw   18      ;4.188 rad
    retlw   16      ;4.213 rad
    retlw   15      ;4.238 rad
    retlw   13      ;4.262 rad
    retlw   12      ;4.287 rad
    retlw   11      ;4.311 rad
    retlw   9       ;4.336 rad
    retlw   8       ;4.361 rad
    retlw   7       ;4.385 rad
    retlw   6       ;4.410 rad
    retlw   5       ;4.435 rad
    retlw   5       ;4.459 rad
    retlw   4       ;4.484 rad
    retlw   3       ;4.509 rad
    retlw   3       ;4.533 rad
    retlw   2       ;4.558 rad
    retlw   2       ;4.583 rad
    retlw   1       ;4.607 rad
    retlw   1       ;4.632 rad
    retlw   1       ;4.656 rad
    retlw   1       ;4.681 rad
    retlw   1       ;4.706 rad
    retlw   1       ;4.730 rad
    retlw   1       ;4.755 rad
    retlw   1       ;4.780 rad
    retlw   1       ;4.804 rad
    retlw   1       ;4.829 rad
    retlw   2       ;4.854 rad
    retlw   2       ;4.878 rad
    retlw   3       ;4.903 rad
    retlw   3       ;4.927 rad
    retlw   4       ;4.952 rad
    retlw   5       ;4.977 rad
    retlw   6       ;5.001 rad
    retlw   7       ;5.026 rad
    retlw   8       ;5.051 rad
    retlw   9       ;5.075 rad
    retlw   10      ;5.100 rad
    retlw   11      ;5.125 rad
    retlw   13      ;5.149 rad
    retlw   14      ;5.174 rad
    retlw   15      ;5.199 rad
    retlw   17      ;5.223 rad
    retlw   18      ;5.248 rad
    retlw   20      ;5.272 rad
    retlw   22      ;5.297 rad
    retlw   23      ;5.322 rad
    retlw   25      ;5.346 rad
    retlw   27      ;5.371 rad
    retlw   29      ;5.396 rad
    retlw   31      ;5.420 rad
    retlw   33      ;5.445 rad
    retlw   35      ;5.470 rad
    retlw   38      ;5.494 rad
    retlw   40      ;5.519 rad
    retlw   42      ;5.543 rad
    retlw   44      ;5.568 rad
    retlw   47      ;5.593 rad
    retlw   49      ;5.617 rad
    retlw   52      ;5.642 rad
    retlw   54      ;5.667 rad
    retlw   57      ;5.691 rad
    retlw   60      ;5.716 rad
    retlw   62      ;5.741 rad
    retlw   65      ;5.765 rad
    retlw   68      ;5.790 rad
    retlw   70      ;5.815 rad
    retlw   73      ;5.839 rad
    retlw   76      ;5.864 rad
    retlw   79      ;5.888 rad
    retlw   82      ;5.913 rad
    retlw   85      ;5.938 rad
    retlw   88      ;5.962 rad
    retlw   91      ;5.987 rad
    retlw   94      ;6.012 rad
    retlw   97      ;6.036 rad
    retlw   100     ;6.061 rad
    retlw   103     ;6.086 rad
    retlw   106     ;6.110 rad
    retlw   109     ;6.135 rad
    retlw   112     ;6.159 rad
    retlw   115     ;6.184 rad
    retlw   119     ;6.209 rad
    retlw   122     ;6.233 rad
    retlw   125     ;6.258 rad
    retlw   128     ;6.283 rad


;------------------------------- Configuración uC ------------------------------

    main:
	call	config_io	;Configure Inputs/Outputs
	call	config_TMR0	;Configure TMR0
	call	config_ie	;Configure Interrupt Enable
	call	config_fosc	;Config Fosc
	call	init_portNvars	;Initialize Ports and Variables
	call	config_TMR1	;Configure TMR1

;-------------------------------- Loop Principal -------------------------------
    loop:
	call	waveform_select
	call	create_waveform
	
	call	get_digits	;Get frequency's value in decimal digits
	call	fetch_disp_out	;Prepare displays outputs
	call	show_display	;Show display output
	
	goto	loop	    ;loop forever
	
;--------------------------------- Sub Rutinas ---------------------------------
    
    ;*****Setup Subroutines*****
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
    
    config_fosc:
	bsf	OSCCON,	6   ;Internal clock 8 MHz
	bsf	OSCCON,	5   ;
	bsf	OSCCON,	4   ;
	bsf	OSCCON,	0   ;Internal oscillator used for system clock
    return
    
    config_TMR0:
	;TMR0 overflow set to 20ms (TMR0_n = 217)	
	bcf	OPTION_REG, 5	;TMR0 internal instruction cycle source
	bcf	OPTION_REG, 3	;Prescaler assigned to TMR0 module	
	bsf	OPTION_REG, 2	;TMR0 prescaler 1:256
	bsf	OPTION_REG, 1	;
	bsf	OPTION_REG, 0	;	
    return
    
    config_TMR1:
	;TMR1 overflow time is variable
	bcf	T1CON,	5   ;TMR1 prescaler 1:1
	bcf	T1CON,	4   ;
	bsf	T1CON,	0   ;Enable TMR1
	
	movlw	11111001B
	movwf	TMR1H
	movlw	11011111B
	movwf	TMR1L
    return
    
    config_ie:
	bsf	INTCON,	7	;Enable Global Interrupt
	bsf	INTCON,	6	;Enable Peripheral Interrupt
	bsf	INTCON,	5	;Enable TMR0 Overflow Interrupt		
	bsf	INTCON,	3	;Enable PortB Interrupts
	
	bsf	PIE1,	0	    ;Enable TMR1 Interrupt
	bsf	IOCB,	btnFrecUp   ;Enable Interrupt-on-Change on buttons
	bsf	IOCB,	btnFrecDwn  ;
	bsf	IOCB,	btnHz	    ;
	bsf	IOCB,	btnkHz	    ;
	bsf	IOCB,	btnWave	    ;
    return
    
    init_portNvars:
	banksel PORTA	    ;Clear Output Ports
	clrf	PORTA
	clrf	PORTC
	clrf	PORTD
	clrf	PORTE
	clrf	wave_ctrl
	clrf	wave_count
	clrf	wave_sel
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
	call	sine_wave
	
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
    
    sine_wave:    
	clrf    PCLATH	    ;Prepare Table's position
	bsf	PCLATH, 1   ;0200h
	movf	wave_count, W
	call    sinewave_table	;Returns voltage code DAC
	movwf   PORTA	
	incf	wave_count, F	;Next index
    return
    
    ;*****Frequency Display*****    
     get_digits:
	bin_to_dec  TMR1H,freq_dig	 ;Ones digit
	bin_to_dec  count_val,freq_dig+1 ;Tens digit
	bin_to_dec  count_val,freq_dig+2 ;Hundreads digit
	bin_to_dec  count_val,freq_dig+3 ;Thousands digit
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







