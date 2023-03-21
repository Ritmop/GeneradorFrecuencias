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
TMR0_n	    EQU	150	;TMR0 value for display select update

disp0en	    EQU	0	;Display 0 enable RD pin
disp1en	    EQU	1	;Display 1 enable RD pin
disp2en	    EQU	2	;Display 2 enable RD pin
disp3en	    EQU	3	;Display 3 enable RD pin
  
PSECT udata_bank0 ;common memory
    ;Wave variables
    wave_ctrl:	DS  1	;Waveform controler
    wave_count:	DS  1	;Wave counter
    wave_sel:	DS  1	;Waveform Selector
    step_size:	DS  1	;Wave increase/decrease step
    ;Frequency variables
    freq_i:	DS  1	;Frequency table's index
    TMR1_n:	DS  2	;TMR1 variable N value (frequency control)
    freq_nybl:	DS  2	;Left(+1), Right(0) frequency decimal pairs
    freq_dig:	DS  4	;Thousands (+3), Hundreads(+2), Tens(+1) & Ones(0) digits in binary
    disp_out:	DS  4	;Thousands (+3), Hundreads(+2), Tens(+1) & Ones(0) display output
    disp_sel:	DS  1	;Display selector (LSB only)
    ;Macros variables
    ;count_val:	DS  1	;Store counters value
    ;mod10:	DS  1	;Module 10 for binary to decimal convertion
    ;rotations:	DS  1	;Rotations counter for binary to decimal convertion
    cont_big:	DS  1	;
    cont_small:	DS  1	;
    
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
	banksel	PORTA
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
	call	delay_100ms
	;Verify which button triggered the interupt
	btfsc	PORTB,	btnFrecUp
	goto	$+3	    ;Check next button
	incf	freq_i, F   ;Increment tables index
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnFrecDwn
	goto	$+3	    ;Check next button
	decf	freq_i, F   ;Increment tables index
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnWave
	goto	$+6	    ;Check next button
	incf	wave_sel, F
	clrf	PORTA	    ;Reset output to avoid waveform flaws
	clrf	wave_count  ;
	bsf	wave_ctrl, 5;Start increase
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnHz
	goto	$+8	    ;Check next button
	movlw	1
	movwf	step_size
	bsf	wave_ctrl, 6
	bsf	PORTE,	0
	bcf	PORTE,	1
	bcf	PORTE,	2
	goto	reset_RBIF  ;Skip following buttons
	
	btfsc	PORTB,	btnkHz
	goto	$+7	    ;Check next button
	movlw	20
	movwf	step_size
	bcf	wave_ctrl, 6
	bcf	PORTE,	0
	bsf	PORTE,	1
	bsf	PORTE,	2
	;goto	reset_RBIF
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
	movf	TMR1_n, W   ;Load frequency mapped values
	movwf	TMR1L	    ;
	movf	TMR1_n+1, W ;
	movwf	TMR1H	    ;	
	bcf	TMR1IF	    ;Reset TMR1 overflow flag
	;Request wave's next step
	bsf	wave_ctrl, 4
    return
;------------------------------------ Tablas -----------------------------------
PSECT code, delta=2, abs
ORG 0100h    ;posición para el código

display7_table:	;7 segment display decoder
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

TMR1H_freqCtrl:	;TMR1 High Byte for frequency control
    addwf   PCL, f   ;Offset
    retlw   0xE1     ;1 Hz
    retlw   0xF0     ;2 Hz
    retlw   0xF5     ;3 Hz
    retlw   0xF8     ;4 Hz
    retlw   0xF9     ;5 Hz
    retlw   0xFA     ;6 Hz
    retlw   0xFB     ;7 Hz
    retlw   0xFC     ;8 Hz
    retlw   0xFC     ;9 Hz
    retlw   0xFC     ;10 Hz
    retlw   0xFD     ;15 Hz
    retlw   0xFE     ;20 Hz
    retlw   0xFE     ;25 Hz
    retlw   0xFE     ;30 Hz
    retlw   0xFF     ;35 Hz
    retlw   0xFF     ;40 Hz
    retlw   0xFF     ;45 Hz
    retlw   0xFF     ;50 Hz
    retlw   0xFF     ;55 Hz
    retlw   0xFF     ;60 Hz
    retlw   0xFF     ;65 Hz
    retlw   0xFF     ;70 Hz
    retlw   0xFF     ;75 Hz
    retlw   0xFF     ;80 Hz
    retlw   0xFF     ;85 Hz
    retlw   0xFF     ;90 Hz
    retlw   0xFF     ;95 Hz
    retlw   0xFF     ;100 Hz
    retlw   0xFF     ;110 Hz
    retlw   0xFF     ;120 Hz
    retlw   0xFF     ;130 Hz
    retlw   0xFF     ;140 Hz
    retlw   0xFF     ;150 Hz
    retlw   0xFF     ;160 Hz
    retlw   0xFF     ;170 Hz
    retlw   0xFF     ;180 Hz
    retlw   0xFF     ;190 Hz
    retlw   0xFF     ;200 Hz
    retlw   0xFF     ;210 Hz
    retlw   0xFF     ;220 Hz
    retlw   0xFF     ;230 Hz
    retlw   0xFF     ;240 Hz
    retlw   0xFF     ;250 Hz
    retlw   0xFF     ;275 Hz
    retlw   0xFF     ;300 Hz
    retlw   0xFF     ;325 Hz
    retlw   0xFF     ;350 Hz
    retlw   0xFF     ;375 Hz
    retlw   0xFF     ;400 Hz
    retlw   0xFF     ;425 Hz
    retlw   0xFF     ;450 Hz
    retlw   0xFF     ;475 Hz
    retlw   0xFF     ;500 Hz
    retlw   0xFE     ;0.55 kHz
    retlw   0xFE     ;0.60 kHz
    retlw   0xFF     ;0.65 kHz
    retlw   0xFF     ;0.70 kHz
    retlw   0xFF     ;0.75 kHz
    retlw   0xFF     ;0.80 kHz
    retlw   0xFF     ;0.85 kHz
    retlw   0xFF     ;0.90 kHz
    retlw   0xFF     ;0.95 kHz
    retlw   0xFF     ;1.00 kHz
    retlw   0xFF     ;1.20 kHz
    retlw   0xFF     ;1.40 kHz
    retlw   0xFF     ;1.60 kHz
    retlw   0xFF     ;1.80 kHz
    retlw   0xFF     ;2.00 kHz
    retlw   0xFF     ;2.25 kHz
    retlw   0xFF     ;2.50 kHz
    retlw   0xFF     ;2.75 kHz
    retlw   0xFF     ;3.00 kHz
    retlw   0xFF     ;3.50 kHz
    retlw   0xFF     ;4.00 kHz
    retlw   0xFF     ;4.50 kHz
    retlw   0xFF     ;5.00 kHz
    retlw   0xFF     ;5.50 kHz
    retlw   0xFF     ;6.00 kHz
    retlw   0xFF     ;6.50 kHz
    retlw   0xFF     ;7.00 kHz
    retlw   0xFF     ;7.50 kHz
    retlw   0xFF     ;8.00 kHz
    retlw   0xFF     ;9.00 kHz
    retlw   0xFF     ;10.00 kHz
    retlw   0xFF     ;15.00 kHz
    retlw   0xFF     ;20.00 kHz
    
TMR1L_freqCtrl:	;TMR1 Low Byte for frequency control
    addwf   PCL, f   ;Offset
    retlw   0x5C     ;1 Hz
    retlw   0xAE     ;2 Hz
    retlw   0xC9     ;3 Hz
    retlw   0x57     ;4 Hz
    retlw   0xDF     ;5 Hz
    retlw   0xE4     ;6 Hz
    retlw   0x9F     ;7 Hz
    retlw   0x2B     ;8 Hz
    retlw   0x98     ;9 Hz
    retlw   0xEF     ;10 Hz
    retlw   0xF5     ;15 Hz
    retlw   0x77     ;20 Hz
    retlw   0xC6     ;25 Hz
    retlw   0xFA     ;30 Hz
    retlw   0x1F     ;35 Hz
    retlw   0x3B     ;40 Hz
    retlw   0x51     ;45 Hz
    retlw   0x63     ;50 Hz
    retlw   0x71     ;55 Hz
    retlw   0x7D     ;60 Hz
    retlw   0x87     ;65 Hz
    retlw   0x8F     ;70 Hz
    retlw   0x97     ;75 Hz
    retlw   0x9D     ;80 Hz
    retlw   0xA3     ;85 Hz
    retlw   0xA8     ;90 Hz
    retlw   0xAD     ;95 Hz
    retlw   0xB1     ;100 Hz
    retlw   0xB8     ;110 Hz
    retlw   0xBE     ;120 Hz
    retlw   0xC3     ;130 Hz
    retlw   0xC7     ;140 Hz
    retlw   0xCB     ;150 Hz
    retlw   0xCE     ;160 Hz
    retlw   0xD1     ;170 Hz
    retlw   0xD4     ;180 Hz
    retlw   0xD6     ;190 Hz
    retlw   0xD8     ;200 Hz
    retlw   0xDA     ;210 Hz
    retlw   0xDC     ;220 Hz
    retlw   0xDD     ;230 Hz
    retlw   0xDF     ;240 Hz
    retlw   0xE0     ;250 Hz
    retlw   0xE3     ;275 Hz
    retlw   0xE5     ;300 Hz
    retlw   0xE7     ;325 Hz
    retlw   0xE9     ;350 Hz
    retlw   0xEB     ;375 Hz
    retlw   0xEC     ;400 Hz
    retlw   0xED     ;425 Hz
    retlw   0xEE     ;450 Hz
    retlw   0xEF     ;475 Hz
    retlw   0xF0     ;500 Hz
    retlw   0xE2     ;0.55 kHz
    retlw   0xFA     ;0.60 kHz
    retlw   0x0E     ;0.65 kHz
    retlw   0x1F     ;0.70 kHz
    retlw   0x2E     ;0.75 kHz
    retlw   0x3B     ;0.80 kHz
    retlw   0x47     ;0.85 kHz
    retlw   0x51     ;0.90 kHz
    retlw   0x5A     ;0.95 kHz
    retlw   0x63     ;1.00 kHz
    retlw   0x7D     ;1.20 kHz
    retlw   0x8F     ;1.40 kHz
    retlw   0x9D     ;1.60 kHz
    retlw   0xA8     ;1.80 kHz
    retlw   0xB1     ;2.00 kHz
    retlw   0xBA     ;2.25 kHz
    retlw   0xC1     ;2.50 kHz
    retlw   0xC6     ;2.75 kHz
    retlw   0xCB     ;3.00 kHz
    retlw   0xD3     ;3.50 kHz
    retlw   0xD8     ;4.00 kHz
    retlw   0xDD     ;4.50 kHz
    retlw   0xE0     ;5.00 kHz
    retlw   0xE3     ;5.50 kHz
    retlw   0xE5     ;6.00 kHz
    retlw   0xE7     ;6.50 kHz
    retlw   0xE9     ;7.00 kHz
    retlw   0xEB     ;7.50 kHz
    retlw   0xEC     ;8.00 kHz
    retlw   0xEE     ;9.00 kHz
    retlw   0xF0     ;10.00 kHz
    retlw   0xF5     ;15.00 kHz
    retlw   0xF8     ;20.00 kHz
    
ORG 01FFh	   
sinewave_table:	;Map counters value to sine wave voltage 0300
    addwf   PCL, f  ;Offset
    retlw   0     ;4.712 rad
    retlw   1     ;4.737 rad
    retlw   1     ;4.761 rad
    retlw   1     ;4.786 rad
    retlw   1     ;4.810 rad
    retlw   1     ;4.835 rad
    retlw   2     ;4.860 rad
    retlw   2     ;4.884 rad
    retlw   3     ;4.909 rad
    retlw   4     ;4.934 rad
    retlw   4     ;4.958 rad
    retlw   5     ;4.983 rad
    retlw   6     ;5.008 rad
    retlw   7     ;5.032 rad
    retlw   8     ;5.057 rad
    retlw   9     ;5.081 rad
    retlw   10    ;5.106 rad
    retlw   12    ;5.131 rad
    retlw   13    ;5.155 rad
    retlw   14    ;5.180 rad
    retlw   16    ;5.205 rad
    retlw   17    ;5.229 rad
    retlw   19    ;5.254 rad
    retlw   20    ;5.279 rad
    retlw   22    ;5.303 rad
    retlw   24    ;5.328 rad
    retlw   26    ;5.353 rad
    retlw   28    ;5.377 rad
    retlw   30    ;5.402 rad
    retlw   32    ;5.426 rad
    retlw   34    ;5.451 rad
    retlw   36    ;5.476 rad
    retlw   38    ;5.500 rad
    retlw   40    ;5.525 rad
    retlw   43    ;5.550 rad
    retlw   45    ;5.574 rad
    retlw   47    ;5.599 rad
    retlw   50    ;5.624 rad
    retlw   52    ;5.648 rad
    retlw   55    ;5.673 rad
    retlw   58    ;5.697 rad
    retlw   60    ;5.722 rad
    retlw   63    ;5.747 rad
    retlw   66    ;5.771 rad
    retlw   68    ;5.796 rad
    retlw   71    ;5.821 rad
    retlw   74    ;5.845 rad
    retlw   77    ;5.870 rad
    retlw   80    ;5.895 rad
    retlw   83    ;5.919 rad
    retlw   86    ;5.944 rad
    retlw   89    ;5.969 rad
    retlw   92    ;5.993 rad
    retlw   95    ;6.018 rad
    retlw   98    ;6.042 rad
    retlw   101   ;6.067 rad
    retlw   104   ;6.092 rad
    retlw   107   ;6.116 rad
    retlw   110   ;6.141 rad
    retlw   113   ;6.166 rad
    retlw   116   ;6.190 rad
    retlw   119   ;6.215 rad
    retlw   123   ;6.240 rad
    retlw   126   ;6.264 rad
    retlw   129   ;6.289 rad
    retlw   132   ;6.313 rad
    retlw   135   ;6.338 rad
    retlw   138   ;6.363 rad
    retlw   141   ;6.387 rad
    retlw   144   ;6.412 rad
    retlw   148   ;6.437 rad
    retlw   151   ;6.461 rad
    retlw   154   ;6.486 rad
    retlw   157   ;6.511 rad
    retlw   160   ;6.535 rad
    retlw   163   ;6.560 rad
    retlw   166   ;6.585 rad
    retlw   169   ;6.609 rad
    retlw   172   ;6.634 rad
    retlw   175   ;6.658 rad
    retlw   178   ;6.683 rad
    retlw   181   ;6.708 rad
    retlw   183   ;6.732 rad
    retlw   186   ;6.757 rad
    retlw   189   ;6.782 rad
    retlw   192   ;6.806 rad
    retlw   194   ;6.831 rad
    retlw   197   ;6.856 rad
    retlw   200   ;6.880 rad
    retlw   202   ;6.905 rad
    retlw   205   ;6.929 rad
    retlw   207   ;6.954 rad
    retlw   210   ;6.979 rad
    retlw   212   ;7.003 rad
    retlw   214   ;7.028 rad
    retlw   217   ;7.053 rad
    retlw   219   ;7.077 rad
    retlw   221   ;7.102 rad
    retlw   223   ;7.127 rad
    retlw   225   ;7.151 rad
    retlw   227   ;7.176 rad
    retlw   229   ;7.201 rad
    retlw   231   ;7.225 rad
    retlw   233   ;7.250 rad
    retlw   235   ;7.274 rad
    retlw   236   ;7.299 rad
    retlw   238   ;7.324 rad
    retlw   240   ;7.348 rad
    retlw   241   ;7.373 rad
    retlw   242   ;7.398 rad
    retlw   244   ;7.422 rad
    retlw   245   ;7.447 rad
    retlw   246   ;7.472 rad
    retlw   247   ;7.496 rad
    retlw   249   ;7.521 rad
    retlw   250   ;7.545 rad
    retlw   250   ;7.570 rad
    retlw   251   ;7.595 rad
    retlw   252   ;7.619 rad
    retlw   253   ;7.644 rad
    retlw   253   ;7.669 rad
    retlw   254   ;7.693 rad
    retlw   254   ;7.718 rad
    retlw   255   ;7.743 rad
    retlw   255   ;7.767 rad
    retlw   255   ;7.792 rad
    retlw   255   ;7.817 rad
    retlw   255   ;7.841 rad
    retlw   255   ;7.866 rad
    retlw   255   ;7.890 rad
    retlw   255   ;7.915 rad
    retlw   255   ;7.940 rad
    retlw   255   ;7.964 rad
    retlw   254   ;7.989 rad
    retlw   254   ;8.014 rad
    retlw   253   ;8.038 rad
    retlw   253   ;8.063 rad
    retlw   252   ;8.088 rad
    retlw   251   ;8.112 rad
    retlw   250   ;8.137 rad
    retlw   250   ;8.161 rad
    retlw   249   ;8.186 rad
    retlw   247   ;8.211 rad
    retlw   246   ;8.235 rad
    retlw   245   ;8.260 rad
    retlw   244   ;8.285 rad
    retlw   242   ;8.309 rad
    retlw   241   ;8.334 rad
    retlw   240   ;8.359 rad
    retlw   238   ;8.383 rad
    retlw   236   ;8.408 rad
    retlw   235   ;8.433 rad
    retlw   233   ;8.457 rad
    retlw   231   ;8.482 rad
    retlw   229   ;8.506 rad
    retlw   227   ;8.531 rad
    retlw   225   ;8.556 rad
    retlw   223   ;8.580 rad
    retlw   221   ;8.605 rad
    retlw   219   ;8.630 rad
    retlw   217   ;8.654 rad
    retlw   214   ;8.679 rad
    retlw   212   ;8.704 rad
    retlw   210   ;8.728 rad
    retlw   207   ;8.753 rad
    retlw   205   ;8.777 rad
    retlw   202   ;8.802 rad
    retlw   200   ;8.827 rad
    retlw   197   ;8.851 rad
    retlw   194   ;8.876 rad
    retlw   192   ;8.901 rad
    retlw   189   ;8.925 rad
    retlw   186   ;8.950 rad
    retlw   183   ;8.975 rad
    retlw   181   ;8.999 rad
    retlw   178   ;9.024 rad
    retlw   175   ;9.049 rad
    retlw   172   ;9.073 rad
    retlw   169   ;9.098 rad
    retlw   166   ;9.122 rad
    retlw   163   ;9.147 rad
    retlw   160   ;9.172 rad
    retlw   157   ;9.196 rad
    retlw   154   ;9.221 rad
    retlw   151   ;9.246 rad
    retlw   148   ;9.270 rad
    retlw   144   ;9.295 rad
    retlw   141   ;9.320 rad
    retlw   138   ;9.344 rad
    retlw   135   ;9.369 rad
    retlw   132   ;9.393 rad
    retlw   129   ;9.418 rad
    retlw   126   ;9.443 rad
    retlw   123   ;9.467 rad
    retlw   119   ;9.492 rad
    retlw   116   ;9.517 rad
    retlw   113   ;9.541 rad
    retlw   110   ;9.566 rad
    retlw   107   ;9.591 rad
    retlw   104   ;9.615 rad
    retlw   101   ;9.640 rad
    retlw   98    ;9.665 rad
    retlw   95    ;9.689 rad
    retlw   92    ;9.714 rad
    retlw   89    ;9.738 rad
    retlw   86    ;9.763 rad
    retlw   83    ;9.788 rad
    retlw   80    ;9.812 rad
    retlw   77    ;9.837 rad
    retlw   74    ;9.862 rad
    retlw   71    ;9.886 rad
    retlw   68    ;9.911 rad
    retlw   66    ;9.936 rad
    retlw   63    ;9.960 rad
    retlw   60    ;9.985 rad
    retlw   58    ;10.00 rad
    retlw   55    ;10.03 rad
    retlw   52    ;10.05 rad
    retlw   50    ;10.08 rad
    retlw   47    ;10.10 rad
    retlw   45    ;10.13 rad
    retlw   43    ;10.15 rad
    retlw   40    ;10.18 rad
    retlw   38    ;10.20 rad
    retlw   36    ;10.23 rad
    retlw   34    ;10.25 rad
    retlw   32    ;10.28 rad
    retlw   30    ;10.30 rad
    retlw   28    ;10.33 rad
    retlw   26    ;10.35 rad
    retlw   24    ;10.37 rad
    retlw   22    ;10.40 rad
    retlw   20    ;10.42 rad
    retlw   19    ;10.45 rad
    retlw   17    ;10.47 rad
    retlw   16    ;10.50 rad
    retlw   14    ;10.52 rad
    retlw   13    ;10.55 rad
    retlw   12    ;10.57 rad
    retlw   10    ;10.60 rad
    retlw   9     ;10.62 rad
    retlw   8     ;10.65 rad
    retlw   7     ;10.67 rad
    retlw   6     ;10.69 rad
    retlw   5     ;10.72 rad
    retlw   4     ;10.74 rad
    retlw   4     ;10.77 rad
    retlw   3     ;10.79 rad
    retlw   2     ;10.82 rad
    retlw   2     ;10.84 rad
    retlw   1     ;10.87 rad
    retlw   1     ;10.89 rad
    retlw   1     ;10.92 rad
    retlw   1     ;10.94 rad
    retlw   1     ;10.97 rad
    retlw   0     ;10.99 rad

;0300h
freq_leftDigits:
    addwf   PCL, f  ;Offset
    retlw   0x00    ;0001 Hz
    retlw   0x00    ;0002 Hz
    retlw   0x00    ;0003 Hz
    retlw   0x00    ;0004 Hz
    retlw   0x00    ;0005 Hz
    retlw   0x00    ;0006 Hz
    retlw   0x00    ;0007 Hz
    retlw   0x00    ;0008 Hz
    retlw   0x00    ;0009 Hz
    retlw   0x00    ;0010 Hz
    retlw   0x00    ;0015 Hz
    retlw   0x00    ;0020 Hz
    retlw   0x00    ;0025 Hz
    retlw   0x00    ;0030 Hz
    retlw   0x00    ;0035 Hz
    retlw   0x00    ;0040 Hz
    retlw   0x00    ;0045 Hz
    retlw   0x00    ;0050 Hz
    retlw   0x00    ;0055 Hz
    retlw   0x00    ;0060 Hz
    retlw   0x00    ;0065 Hz
    retlw   0x00    ;0070 Hz
    retlw   0x00    ;0075 Hz
    retlw   0x00    ;0080 Hz
    retlw   0x00    ;0085 Hz
    retlw   0x00    ;0090 Hz
    retlw   0x00    ;0095 Hz
    retlw   0x01    ;0100 Hz
    retlw   0x01    ;0110 Hz
    retlw   0x01    ;0120 Hz
    retlw   0x01    ;0130 Hz
    retlw   0x01    ;0140 Hz
    retlw   0x01    ;0150 Hz
    retlw   0x01    ;0160 Hz
    retlw   0x01    ;0170 Hz
    retlw   0x01    ;0180 Hz
    retlw   0x01    ;0190 Hz
    retlw   0x02    ;0200 Hz
    retlw   0x02    ;0210 Hz
    retlw   0x02    ;0220 Hz
    retlw   0x02    ;0230 Hz
    retlw   0x02    ;0240 Hz
    retlw   0x02    ;0250 Hz
    retlw   0x02    ;0275 Hz
    retlw   0x03    ;0300 Hz
    retlw   0x03    ;0325 Hz
    retlw   0x03    ;0350 Hz
    retlw   0x03    ;0375 Hz
    retlw   0x04    ;0400 Hz
    retlw   0x04    ;0425 Hz
    retlw   0x04    ;0450 Hz
    retlw   0x04    ;0475 Hz
    retlw   0x05    ;0500 Hz
    retlw   0x00    ;00.55 kHz
    retlw   0x00    ;00.60 kHz
    retlw   0x00    ;00.65 kHz
    retlw   0x00    ;00.70 kHz
    retlw   0x00    ;00.75 kHz
    retlw   0x00    ;00.80 kHz
    retlw   0x00    ;00.85 kHz
    retlw   0x00    ;00.90 kHz
    retlw   0x00    ;00.95 kHz
    retlw   0x01    ;01.00 kHz
    retlw   0x01    ;01.20 kHz
    retlw   0x01    ;01.40 kHz
    retlw   0x01    ;01.60 kHz
    retlw   0x01    ;01.80 kHz
    retlw   0x02    ;02.00 kHz
    retlw   0x02    ;02.25 kHz
    retlw   0x02    ;02.50 kHz
    retlw   0x02    ;02.75 kHz
    retlw   0x03    ;03.00 kHz
    retlw   0x03    ;03.50 kHz
    retlw   0x04    ;04.00 kHz
    retlw   0x04    ;04.50 kHz
    retlw   0x05    ;05.00 kHz
    retlw   0x05    ;05.50 kHz
    retlw   0x06    ;06.00 kHz
    retlw   0x06    ;06.50 kHz
    retlw   0x07    ;07.00 kHz
    retlw   0x07    ;07.50 kHz
    retlw   0x08    ;08.00 kHz
    retlw   0x09    ;09.00 kHz
    retlw   0x10    ;10.00 kHz
    retlw   0x15    ;15.00 kHz
    retlw   0x20    ;20.00 kHz
    
freq_rightDigits:
    addwf   PCL, f  ;Offset
    retlw   0x01    ;0001 Hz
    retlw   0x02    ;0002 Hz
    retlw   0x03    ;0003 Hz
    retlw   0x04    ;0004 Hz
    retlw   0x05    ;0005 Hz
    retlw   0x06    ;0006 Hz
    retlw   0x07    ;0007 Hz
    retlw   0x08    ;0008 Hz
    retlw   0x09    ;0009 Hz
    retlw   0x10    ;0010 Hz
    retlw   0x15    ;0015 Hz
    retlw   0x20    ;0020 Hz
    retlw   0x25    ;0025 Hz
    retlw   0x30    ;0030 Hz
    retlw   0x35    ;0035 Hz
    retlw   0x40    ;0040 Hz
    retlw   0x45    ;0045 Hz
    retlw   0x50    ;0050 Hz
    retlw   0x55    ;0055 Hz
    retlw   0x60    ;0060 Hz
    retlw   0x65    ;0065 Hz
    retlw   0x70    ;0070 Hz
    retlw   0x75    ;0075 Hz
    retlw   0x80    ;0080 Hz
    retlw   0x85    ;0085 Hz
    retlw   0x90    ;0090 Hz
    retlw   0x95    ;0095 Hz
    retlw   0x00    ;0100 Hz
    retlw   0x10    ;0110 Hz
    retlw   0x20    ;0120 Hz
    retlw   0x30    ;0130 Hz
    retlw   0x40    ;0140 Hz
    retlw   0x50    ;0150 Hz
    retlw   0x60    ;0160 Hz
    retlw   0x70    ;0170 Hz
    retlw   0x80    ;0180 Hz
    retlw   0x90    ;0190 Hz
    retlw   0x00    ;0200 Hz
    retlw   0x10    ;0210 Hz
    retlw   0x20    ;0220 Hz
    retlw   0x30    ;0230 Hz
    retlw   0x40    ;0240 Hz
    retlw   0x50    ;0250 Hz
    retlw   0x75    ;0275 Hz
    retlw   0x00    ;0300 Hz
    retlw   0x25    ;0325 Hz
    retlw   0x50    ;0350 Hz
    retlw   0x75    ;0375 Hz
    retlw   0x00    ;0400 Hz
    retlw   0x25    ;0425 Hz
    retlw   0x50    ;0450 Hz
    retlw   0x75    ;0475 Hz
    retlw   0x00    ;0500 Hz
    retlw   0x55    ;00.55 kHz
    retlw   0x60    ;00.60 kHz
    retlw   0x65    ;00.65 kHz
    retlw   0x70    ;00.70 kHz
    retlw   0x75    ;00.75 kHz
    retlw   0x80    ;00.80 kHz
    retlw   0x85    ;00.85 kHz
    retlw   0x90    ;00.90 kHz
    retlw   0x95    ;00.95 kHz
    retlw   0x00    ;01.00 kHz
    retlw   0x20    ;01.20 kHz
    retlw   0x40    ;01.40 kHz
    retlw   0x60    ;01.60 kHz
    retlw   0x80    ;01.80 kHz
    retlw   0x00    ;02.00 kHz
    retlw   0x25    ;02.25 kHz
    retlw   0x50    ;02.50 kHz
    retlw   0x75    ;02.75 kHz
    retlw   0x00    ;03.00 kHz
    retlw   0x50    ;03.50 kHz
    retlw   0x00    ;04.00 kHz
    retlw   0x50    ;04.50 kHz
    retlw   0x00    ;05.00 kHz
    retlw   0x50    ;05.50 kHz
    retlw   0x00    ;06.00 kHz
    retlw   0x50    ;06.50 kHz
    retlw   0x00    ;07.00 kHz
    retlw   0x50    ;07.50 kHz
    retlw   0x00    ;08.00 kHz
    retlw   0x00    ;09.00 kHz
    retlw   0x00    ;10.00 kHz
    retlw   0x00    ;15.00 kHz
    retlw   0x00    ;20.00 kHz
    
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
	call	waveform_select	;Check selected waveform
	call	create_waveform	;Next step in wave formation
	
	call	restr_freq	;Restrict frequency at table borders
	call	map_freq	;Map frequency to TMR1 values
	call	decimal_conv	;Get frequency's value in decimal digits
	call	fetch_disp_out	;Prepare displays outputs
	call	update_display	;Update display's output
	
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
	;TMR0 overflow set to 20ms (TMR0_n = 100)	
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
	
	movlw	0xE1	;Initialize wave frequency to 1Hz
	movwf	TMR1H
	movlw	0x5C
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
	
	movlw	0
	movwf	freq_i	    ;Initialize at 1Hz wave frequency
	movlw	1
	movwf	step_size    ;Initialize at 1 step increasing 
	clrw
	bsf	wave_ctrl,  5	;Start at rising edge
	bsf	wave_ctrl,  6	;Start at Hz multiplier
	bcf	PORTE,	1
	bsf	PORTE,	0
    return
 
    ;*****Funtion Generator*****    
    waveform_select:    ;wave_sel 00(Square), 01(Sawtooth), 10(Triangle), 11(Sine)
	btfsc	wave_sel,   1
	goto	sel_triangle
	btfsc	wave_sel,   0
	goto	sel_sawtooth
	
	sel_square:
	bcf wave_ctrl,  3   ;Deselect Sine wave
	bsf wave_ctrl,  0   ;Select Square
    return    
	sel_sawtooth:
	bcf wave_ctrl,  0   ;Deselect Square wave
	bsf wave_ctrl,  1   ;Select Sawtooth
    return    
	sel_triangle:
	    btfsc	wave_sel,   0
	    goto	sel_sine
	bcf wave_ctrl,  1   ;Deselect Sawtooth wave
	bsf wave_ctrl,  2   ;Select Triangle
    return    
	sel_sine:
	bcf wave_ctrl,  2   ;Deselect Triangle wave
	bsf wave_ctrl,  3   ;Select Sine wave
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
	;incf	wave_count, F
	;movf	wave_count, W
	;sublw	128	    ;Compare counter at half period
	;btfsc	STATUS,	0   ;Check ~Borrow flag
	;goto	$+4	;Skip set
	;movlw	255	;Set to HIGH on first half
	;movwf	PORTA	;
    ;return		
	;clrf	PORTA	;Reset to LOW on second half
    ;return
	movf	step_size, W
	addwf	wave_count, F
	movf	wave_count, W
	sublw	127	    ;Compare counter at half of wave period
	btfsc	STATUS,	0   ;Check ~Borrow flag
	goto	$+4	    ;Skip set
	movlw	255	    ;Set to HIGH on first half of wave period
	movwf	PORTA	    ;
    return		
	clrf	PORTA	;Reset to LOW on first half of wave period
    return
	
    sawtooth_wave:	
	;incf	PORTA
	movf	step_size, W
	addwf	PORTA,	F
    return
    
    triangle_wave:
	btfss	wave_ctrl,  5	;Check increase
	goto	neg_slope
	pos_slope:
	;incf	PORTA
	;incf	PORTA, W
	;btfsc	STATUS,	2 ;Check Zero flag, if zero dont store inc and start decrease, no zero store
	;goto	$+3	    ;Skip inc and start decrease
	;movwf	PORTA	;Store increment
	movf	step_size, W
	addwf	PORTA,	W
	btfsc	STATUS, 0   ;Check Carry flag
	goto	set_to_dec
	movwf	PORTA	    ;Store if no carry
	;Repeat
	movf	step_size, W
	addwf	PORTA,	W
	btfsc	STATUS, 0   ;Check Carry flag
	goto	set_to_dec
	movwf	PORTA	    ;Store if no carry
    return
	set_to_dec:
	bcf	wave_ctrl,  5	;Start decrease
    return	
	neg_slope:
	;decf	PORTA
	;btfsc	STATUS,	2 ;Check Zero flag
	;goto	$+3
	;decf	PORTA	;dectement again
	movf	step_size, W
	subwf	PORTA,	W
	btfss	STATUS, 0   ;Check ~Borrow flag
	goto	set_to_inc
	movwf	PORTA	    ;Store if no borrow
	;Repeat
	movf	step_size, W
	subwf	PORTA,	W
	btfss	STATUS, 0   ;Check ~Borrow flag
	goto	set_to_inc
	movwf	PORTA	    ;Store if no borrow
    return
	set_to_inc:
	bsf	wave_ctrl,  5	;Start increase
    return
    
    sine_wave:    
	clrf    PCLATH	    ;Prepare Table's position
	bsf	PCLATH, 1   ;0200h
	movf	wave_count, W
	call    sinewave_table	;Returns mapped voltage for DAC
	movwf   PORTA
	movf	step_size, W
	addwf	wave_count,F	;Next index
	;incf	wave_count, F	;Next index
    return
    
    ;*****Frequency Display*****
 
    restr_freq:	
	btfss	wave_ctrl, 6 ;Check Hz/kHz multiplier
	goto	restr_kHz
	restr_Hz:
	;Underflow
	btfsc	freq_i, 7
	clrf	freq_i
	;Overflow
	movf	freq_i,	W
	sublw	52
	btfsc	STATUS, 0   ;Check ~borrow flag
	goto	$+3
	movlw	52
	movwf	freq_i	
    return    
	restr_kHz:
	;Underflow
	movf	freq_i,	W
	sublw	53
	btfss	STATUS, 0   ;Check ~borrow flag
	goto	$+3
	movlw	53
	movwf	freq_i	
	;Overflow
	movf	freq_i,	W
	sublw	83
	btfsc	STATUS, 0   ;Check ~borrow flag
	goto	$+3
	movlw	83
	movwf	freq_i
    return
    
    map_freq:	
	clrf    PCLATH	    ;Prepare PCL offset to
	bsf	PCLATH, 0   ;0100h
	;Map Low byte
	movf	freq_i, W
	call	TMR1L_freqCtrl
	movwf	TMR1_n
	;Map High byte
	movf	freq_i, W
	call	TMR1H_freqCtrl
	movwf	TMR1_n+1
    return
    
     decimal_conv:
	clrf    PCLATH	    ;Prepare PCL offset to
	bsf	PCLATH, 0   ;0300h
	bsf	PCLATH, 1   ;
	;Look up frequency digits
	movf	freq_i,	W
	call	freq_rightDigits
	movwf	freq_nybl
	movf	freq_i, W
	call	freq_leftDigits
	movwf	freq_nybl+1
	;Separate nibbles into individual registers
	get_nibbles  freq_nybl+1, freq_dig+3, freq_dig+2
	get_nibbles  freq_nybl,	  freq_dig+1, freq_dig
    return
    
    fetch_disp_out:    
	clrf    PCLATH	    ;Prepare PCL offset to
	bsf	PCLATH, 0   ;0100h
	display7_decode	freq_dig,   disp_out   ;Ones display	
	display7_decode	freq_dig+1, disp_out+1 ;Tens display	
	display7_decode	freq_dig+2, disp_out+2 ;Hundreds display
	display7_decode	freq_dig+3, disp_out+3 ;Thousands display
    return
    
    update_display:
	btfsc	disp_sel,   1
	goto	display_2
	btfsc	disp_sel,   0
	goto	display_1	
	display_0: ;Ones
	portC_mutiplex	disp3en, disp_out, disp0en
    return    
	display_1: ;Tens
	portC_mutiplex	disp0en, disp_out+1, disp1en
    return    
	display_2: ;Hundreds
	    btfsc   disp_sel,   0
	    goto    display_3
	portC_mutiplex	disp1en, disp_out+2, disp2en
    return    
	display_3: ;Thousands
	portC_mutiplex	disp2en, disp_out+3, disp3en
    return
    
    delay_100ms:
	movlw   198		;valor inicial del contador
	movwf   cont_big
	call    delay_small	;rutina de delay
	decfsz  cont_big, 1	;decrementar el contador
	goto    $-2		;ejecutar dos líneas atrás
	return

    delay_small:
	movlw   165		;valor inicial del contador
	movwf   cont_small
	decfsz  cont_small, 1   ;decrementar el contador
	goto    $-1		;ejecutar línea anterior
	return
    END