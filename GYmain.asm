    #include "config.h"
    
    ;Preprocessor directives for MPU-6050
    #define dirGY521 0xD0
    ; Name Pull-down AD0 
    #define dirpower ; Register for manage the power of sensor '=0 to turn on'

    ;Preprocessor directive for I2C
    #define I2CEN SSPCON1,SSPEN ; Enable module SSP
    #define START SSPCON2,SEN ; Start
    #define STOP SSPCON2,PEN ; Stop
    #define RESTART SSPCON2,RSEN ; Restart 
    #define RECIVE SSPCON2,RCEN ; Recive 
    #define BUFFERFULL SSPSTAT,BF ; Buffer Full
    #define trisSDA TRISB,RB0 ; Tristate SDA pin 
    #define trisSCL TRISB,RB1 ; Tristate SCL pin
    #define SlewRate SSPSTAT,SMP
    #define FOSC 4000 ;(KHz)
    #define BAUD 100 ;(KHz)
    #define RXACK SSPCON2,ACKSTAT ; Bit for detecting ACK
    
    ;Preprocessor diretives for MCU
    #define trisLED1 TRISA,RA0
    #define trisLED2 TRISA,RA1
    #define pinLED1 LATA,RA0
    #define pinLED2 LATA,RA1
    
    CBLOCK 0x60
    accelerationX:2 ;Measure of acceleration in X  DIR 3B, 3C 
    accelerationY:2 ;Measure of acceleration in Y  DIR 3D, 3E
    accelerationZ:2 ;Measure of acceleration in Z  DIR 3F, 3G
    gyroX:2 ;Measure of gyro in X  DIR 43, 44
    gyroY:2 ;Measure of gyro in Y  DIR 45, 46 
    gyroZ:2 ;Measure of gyro in Z  DIR 47, 48	
    delayvar:3 ;Counter for generating delays
    vardir
    ENDC
    
    org 0x00
    goto main
    org 0x08
    goto ISR
    
main:
    call initialconfig
    call initialstates 
    call configI2C ;---Initial configuration of the I2C
    movwf vardir
    
init:    bsf START ; Sending Start
    call waitMSSP ; Waiting for complete the I2C process
    movlw dirGY521 ; Sending the direction of the slave
    call i2c_send_byte 
    call waitMSSP ; Waiting for complete the I2C process
    btfsc SSPCON2,ACKSTAT ; ACK? oh NACK?
    goto failMSSP  ; was not recived and Acknowledge
    goto LOL
    goto main

;************************************************INITIAL CONFIGURATION SUBRUTINE    
initialconfig:  ;--------Subrutine for initial configuration of PIC    
    movlw 0x0F
    movwf ADCON1 ;Ports as digital instead of analogic
    bcf trisLED1 ; data direction pin LATCH
    bcf trisLED2 ; data direction pin DATA
    return
    
initialstates: ;---------Subrutine for setting the initial states of PIC
    bcf pinLED2  
    bcf pinLED1 
    return
    
;*******************************SUBRUTINE FOR THE INITIAL CONFIGURATION OF I2C     
configI2C:
    bsf I2CEN ; Turn ON module SSP
    bcf SSPCON1,SSPM0 ; Mode=8 'Master mode'
    bcf SSPCON1,SSPM1
    bcf SSPCON1,SSPM2
    bsf SSPCON1,SSPM3
    bsf trisSDA ; SDA as an input pin 
    bsf trisSCL ; SDL as an input pin
    bsf SlewRate ; Disenable faster mode (Not neccesary at this frecuency )
    ;movlw (FOSC/(4*BAUD))-1
    movlw 0x09
    movwf SSPADD  ; Setting the baud rate    
    retlw 0
    
;***********************************SUBRUTINE TO SEND DATA THROUGHT A I2C BUS
i2c_send_byte:
    movwf SSPBUF
    retlw 0
    
;***********************************SUBRUTINE TO WAIT A COMPLETE ACTION OF I2C
waitMSSP:
    btfss PIR1,SSPIF
    goto waitMSSP
    bcf PIR1,SSPIF
    retlw 0
    
;******************************SUBRUTINE (IT has not recived an acknowledge)    
failMSSP:
    btg pinLED2
    movlw 30
    call delayW0ms
    bsf STOP
    call waitMSSP
    goto init
    
;*******************************SUBRUTINE (SUCCESS OF IDENTIFICATION FROM SLAVE)    
LOL:
    bsf pinLED1
    bsf STOP
    call waitMSSP
    goto $

;*****************************;---------------------------- Generating a delay
delay10ms:  ;4MHz frecuency oscillator
    movlw d'84'  ;A Value
    movwf delayvar+1
d0:   movlw d'38' ;B Value
    movwf delayvar  
    nop
d1:  decfsz delayvar,F
    bra d1
    decfsz delayvar+1,F
    bra d0      
    return ;2+1+1+A[1+1+1+B+1+2B-2]+A+1+2A-2+2 => 5+A[5+3B]
delay: ;300 ms delay
    movlw .10
    call delayW0ms
    return
    
delayW0ms: ;It is neccesary load a properly value in the acumulator before use this subrutine
    movwf delayvar+2
d2:    call delay10ms
    decfsz delayvar+2,F
    bra d2
    return     
;*********************************************ISR RUTINE
ISR:
    return   
    
    END