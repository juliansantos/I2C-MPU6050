    #include "config.h"
    
    ;Preprocessor directives for MPU-6050
    #define dirGY521 0xD0 ; to write
    #define rGY521 0xD1 ; to read
    ; Name Pull-down AD0 
    #define dirPower 0x6B ; Register for manage the power of sensor '=0 to turn on'
    #define acelx 0x3D

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
    
    ;Preprocesor directives for 74595
    #define trisLATCH TRISB,3
    #define trisCLOCK TRISB,5
    #define trisDATA TRISB,4
    #define pinLATCH LATB,3
    #define pinCLOCK LATB,5
    #define pinDATA LATB,4
    
    CBLOCK 0x60
    accelerationX:2 ;Measure of acceleration in X  DIR 3B, 3C 
    accelerationY:2 ;Measure of acceleration in Y  DIR 3D, 3E
    accelerationZ:2 ;Measure of acceleration in Z  DIR 3F, 3G
    gyroX:2 ;Measure of gyro in X  DIR 43, 44
    gyroY:2 ;Measure of gyro in Y  DIR 45, 46 
    gyroZ:2 ;Measure of gyro in Z  DIR 47, 48	
    delayvar:3 ;Counter for generating delays
    vardir
    sdata:2 ; State of 16 LED
    count8
    datatmp
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
    movlw dirPower ;Sending the direction of power control register
    call i2c_send_byte
    movlw 0x00 
    call i2c_send_byte ; writing 0 in a power control register
    bsf RESTART
    call waitMSSP
    movlw dirGY521 ; Sending the direction of the slave
    call i2c_send_byte 
    movlw acelx 
    call i2c_send_byte
    
    bsf RESTART
    call waitMSSP
    movlw rGY521
    call i2c_send_byte
    bsf SSPCON2,RCEN 
    call waitMSSP
    bsf SSPCON2,ACKDT ; ACK DATA to send is 1, which is NACK.
    bsf SSPCON2,ACKEN ; Send ACK DATA now.
    call waitMSSP
    movf SSPBUF,W ; Get data from SSPBUF into W register
    movwf sdata+1
   
    ;here repet 
    bsf RESTART
    call waitMSSP
    movlw rGY521
    call i2c_send_byte
    bsf SSPCON2,RCEN 
    call waitMSSP
    
    bsf SSPCON2,ACKDT ; ACK DATA to send is 1, which is NACK.
    bsf SSPCON2,ACKEN ; Send ACK DATA now.
    call waitMSSP
    
    movf SSPBUF,W ; Get data from SSPBUF into W register
    movwf sdata
    call showdata
    
    goto LOL
    goto main

;************************************************INITIAL CONFIGURATION SUBRUTINE    
initialconfig:  ;--------Subrutine for initial configuration of PIC    
    movlw 0x0F
    movwf ADCON1 ;Ports as digital instead of analogic
    bcf trisLED1 ; data direction pin LATCH
    bcf trisLED2 ; data direction pin DATA
    bcf trisLATCH ; data direction pin LATCH
    bcf trisDATA ; data direction pin DATA
    bcf trisCLOCK ; data direction pin CLOCK
    return
    
initialstates: ;---------Subrutine for setting the initial states of PIC
    bcf pinLED2  
    bcf pinLED1 
    clrf accelerationX 
    clrf accelerationX+1 
    clrf accelerationY 
    clrf accelerationY+1
    clrf accelerationZ 
    clrf accelerationZ+1
    clrf gyroX 
    clrf gyroY 
    clrf gyroZ 
    bcf pinLATCH ;no latch information
    bcf pinCLOCK ;no send +edge
    bcf pinDATA ;low state data pin
    clrf sdata ;low byte (little endian)
    clrf sdata+1 ;high byte  (big endian)
    movlw 0xAF
    movwf sdata
    movwf sdata+1
    call showdata ; Turn off all LEDs
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
    btfss PIR1,SSPIF
    goto waitMSSP
    bcf PIR1,SSPIF
    btfsc SSPCON2,ACKSTAT ; ACK? oh NACK?
    goto failMSSP  ; was not recived and Acknowledge
    retlw 0
    
;***********************************SUBRUTINE TO WAIT A COMPLETE ACTION OF I2C
waitMSSP:
    btfss PIR1,SSPIF
    goto waitMSSP
    bcf PIR1,SSPIF
    btfsc SSPCON2,ACKSTAT ; ACK? oh NACK?
    goto failMSSP  ; was not recived and Acknowledge
    retlw 0
    
;******************************SUBRUTINE (IT has not recived an acknowledge)    
failMSSP:
    btg pinLED2
    movlw 1
    call delayW0ms
    bsf STOP
    call waitMSSP
    goto init
    
;*******************************SUBRUTINE (SUCCESS OF IDENTIFICATION FROM SLAVE)    
LOL:
    btg pinLED1
    movlw 1
    call delayW0ms
    bsf STOP
    call waitMSSP
    goto init

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
    
;*************************************************************
;------------------------------Subrutine for move data of sdata register to LEDs
showdata:
    clrf count8 ;set count in 0
    movff sdata,datatmp
    call send8 ;send low byte
    movff sdata+1,datatmp
    call send8 ;send high byte
    call latch
    return ; Data has been sent
    
send8:    rrcf datatmp,F ; LSB -> C
    btfsc STATUS,C
    bsf pinDATA ; Carry =1 then Data=1 
    btfss STATUS,C
    bcf pinDATA ; Carry =0 then Data=0
    incf count8,F ; Increment counter
    call pclock ; sending a positive edge 9clock)
    btfss count8,3 ;test if count=8
    bra send8 ;else, continue rotating
    clrf count8 ; clear counter 8 bit
    return
;-------------------------------------Subrutine for send a positive edge (clock)    
pclock:
    bsf pinCLOCK
   ;call delay according specifications
    bcf pinCLOCK
    return
;-----------------------------------------------Subrutine for latch data (clock)    
latch:
    bsf pinLATCH
    ;call delay according specifications
    bcf pinLATCH    
    return
    
;*********************************************ISR RUTINE
ISR:
    return   
    
    END