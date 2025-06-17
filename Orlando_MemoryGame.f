HEX

\---- Definizione costanti 

\ Indirizzi periferiche di base 
FE000000 CONSTANT BASE_ADDRESS
BASE_ADDRESS 200000 + CONSTANT PERI_BASE 
BASE_ADDRESS 3000 + CONSTANT TIMER_BASE

\ Gestione GPIO 
PERI_BASE 4 + CONSTANT GPFSEL1
PERI_BASE 8 + CONSTANT GPFSEL2  
PERI_BASE 1C + CONSTANT GPSET0 
PERI_BASE 28 + CONSTANT GPCLR0 
PERI_BASE 34 + CONSTANT GPLEV0
PERI_BASE 40 + CONSTANT GPEDS0
PERI_BASE 58 + CONSTANT GPFEN0

1000000 CONSTANT GPIO8-EN \ bit 24 
200 CONSTANT GPIO23-EN \ bit 9 
40000 CONSTANT GPIO16-EN \ bit 18 
200000 CONSTANT GPIO17-EN \ bit21

\ LED e Buzzer
40000 CONSTANT RED_LED 
800000 CONSTANT YELLOW_LED 
10000 CONSTANT BLUE_LED 
20000 CONSTANT BUZZER-MASK 

\ Pulsanti 
40 CONSTANT RED_BUTTON 
20 CONSTANT YELLOW_BUTTON 
400000 CONSTANT BLUE_BUTTON 


\ Timer 
TIMER_BASE 4 + CONSTANT CLO 
TIMER_BASE 0C + CONSTANT C0 
TIMER_BASE CONSTANT CS 
7A120 CONSTANT HALF-SEC 

\ Variabili 
VARIABLE ROUND 
VARIABLE N
VARIABLE M
VARIABLE ERROR 
VARIABLE COUNTER


\---- Settaggio GPIO 

\ Word di utilità per gestire l'abilitazione delle GPIO.
\ ENABLE PIN opera sullo stack come ( fsel gpio -- ), dove
\ fsel è l'apposito registro di selezione modalità e GPIO il
\ numero binario corrispondente ai bit associati alle periferiche
\ da abilitare
: ENABLE_PIN    OVER @ + SWAP ! ;
: ENABLE_PINS
    GPFSEL1 GPIO8-EN ENABLE_PIN
    GPFSEL2 GPIO23-EN ENABLE_PIN
    GPFSEL1 GPIO16-EN ENABLE_PIN
    GPFSEL1 GPIO17-EN ENABLE_PIN
;

\ Abilito la rilevazione deL fronte di discesa
\ nella lettura dei bottoni
: ENABLE-BTN-EVENT 400060 GPFEN0 ! ;

\ Impostazione stato dei pin in modalità output 
: ON   GPSET0 ! ;
: OFF   GPCLR0 ! ;


\----Gestione interazione componenti 

\ Generazione numero casuale
: RANDOM   CLO @ 3 MOD ;   

\ Gestione System Timer BCM2711
: READ_TIME CLO @ ;         
: DELAY READ_TIME + BEGIN DUP  READ_TIME - 0< UNTIL DROP ;
: HALF-SEC_DELAY     HALF-SEC DELAY ;

\ LED 
: ALL_LED_OFF RED_LED OFF YELLOW_LED OFF BLUE_LED OFF ;
: RED_LED_ON  RED_LED ON HALF-SEC_DELAY RED_LED OFF  ;
: YELLOW_LED_ON  YELLOW_LED ON HALF-SEC_DELAY YELLOW_LED OFF  ;
: BLUE_LED_ON  BLUE_LED ON HALF-SEC_DELAY BLUE_LED OFF ;

\ Tasti 
: BUTTON_CHECK  GPEDS0 @ RED_BUTTON YELLOW_BUTTON BLUE_BUTTON + + AND ;
: READ_EVENT_STATUS   GPEDS0 @ 0 <> ;
: RESETBUTTON  GPEDS0 ! ;

\ Buzzer 
: BUZZER BUZZER-MASK ON HALF-SEC_DELAY BUZZER-MASK OFF ;


\ Utilità 
: DECREASE_COUNTER  COUNTER @ 1 - COUNTER ! ;
: DECREASE_N    N @ 1 - N ! ;


\---- Output terminale 

\ Dizionario parole
: 'A'   41 EMIT ;
: 'B'   42 EMIT ;
: 'C'   43 EMIT ;
: 'D'   44 EMIT ;
: 'E'   45 EMIT ;
: 'F'   46 EMIT ;
: 'G'   47 EMIT ;
: 'H'   48 EMIT ;
: 'I'   49 EMIT ;
: 'L'   4C EMIT ;
: 'M'   4D EMIT ;
: 'N'   4E EMIT ;
: 'O'   4F EMIT ;
: 'P'   50 EMIT ;
: 'Q'   51 EMIT ;
: 'R'   52 EMIT ;
: 'S'   53 EMIT ;
: 'T'   54 EMIT ;
: 'U'   55 EMIT ;
: 'V'   56 EMIT ;
: 'Z'   5A EMIT ;
: '='   3D EMIT ;

: 'HAI_VINTO'   CR 'H' 'A' 'I' SPACE 'V' 'I' 'N' 'T' 'O' CR  ;
: 'HAI_PERSO'   CR 'H' 'A' 'I' SPACE 'P' 'E' 'R' 'S' 'O' CR  ;
: 'LED_ACCESI'    CR 'L' 'E' 'D' '=' SPACE ;


\---- Gestione principale gioco

\ Condizione per continuare a giocare.
\ Controlla se il round corrente non è ancora il 10 (quello finale) e verifica
\ se il contatore degli errori è uguale a 0. Se la condizione è verificata
\ il round viene incrementato. 
: ?WIN ROUND @ 10 <> ERROR @ 0 = AND ;


\ Controllo dell'accensione dei LED casuali.
\ Imposta due contatori N ed M che corrispondono al numero di LED 
\ accesi in ogni turno. Genera quindi un valore casuale e seleziona il LED 
\ da accendere, memorizzando il valore corrispondente nello stack di ritorno. 
\ Quando i dati vengono ripristinati e recuperati dallo stack di ritorno, 
\ si presenteranno in ordine invertito. 
: LOOP_LED
    DUP
    N !
    M !
    BEGIN
        N @ 0 >
    WHILE
    RANDOM
    DUP
    >R
    CASE    
        0 OF RED_LED_ON 'R' 'O' 'S' 'S' 'O' CR  ENDOF 
        1 OF YELLOW_LED_ON  'G' 'I' 'A' 'L' 'L' 'O' CR  ENDOF
        2 OF BLUE_LED_ON 'B' 'L' 'U'  CR ENDOF 
    ENDCASE
    HALF-SEC_DELAY
    DECREASE_N
    REPEAT
    BEGIN 
        M @ 0 >
    WHILE 
        R>
        M @ 1 - M ! 
    REPEAT
;


\ Gestisce la pressione dei pulsanti e controlla lo stato degli eventi associati.
\ Verifica quale pulsante è stato premuto, ne accende il LED corrispondente 
\ e verifica lo stato dell'evento associato. Controlla inoltre se il pulsante
\ premuto è corretto per la sequenza del gioco. Se non  lo è, setta Error ad 1,
\ altrimenti a 0. Infine resetta lo status del pulsante.  
: READ_PRESSED_BUTTON
    ALL_LED_OFF 
    BUTTON_CHECK 
    CASE 
        RED_BUTTON OF 
            RED_LED_ON
            READ_EVENT_STATUS IF  
                DECREASE_COUNTER
                0 = IF 
                    0 ERROR ! 
                    ELSE 
                    BUZZER 
                    1 ERROR ! 
                THEN 
            THEN 
            RED_BUTTON RESETBUTTON 
        ENDOF 

        YELLOW_BUTTON OF 
            YELLOW_LED_ON
            READ_EVENT_STATUS IF 
                DECREASE_COUNTER
                1 = IF 
                    0 ERROR ! 
                    ELSE 
                    BUZZER 
                    1 ERROR ! 
                THEN 
            THEN 
            YELLOW_BUTTON RESETBUTTON 
        ENDOF

        BLUE_BUTTON OF 
            BLUE_LED_ON 
            READ_EVENT_STATUS IF 
                DECREASE_COUNTER 
                2 = IF 
                    0 ERROR ! 
                    ELSE 
                    BUZZER 
                    1 ERROR ! 
                THEN 
            THEN 
            BLUE_BUTTON RESETBUTTON 
        ENDOF
    ENDCASE
    HALF-SEC_DELAY
    
;


\ Setup generale del gioco
: SETUP_GAME 
    ENABLE_PINS
    ENABLE-BTN-EVENT
;


\ Gestisce l'intera logica del gioco, dal setup iniziale alla conclusione.
\ Imposta il numero iniziale di round (=LED) a 3. Durante ogni round visualizza
\ e gestisce i LED accesi, imposta il contatore per i pulsanti e azzera l'errore.
\ Attende poi l'input dall'utente per replicare la sequenza dei LED accesi e se 
\ la sequenza inserita è corretta, prosegue incrementando il numero di ROUND=LED,
\ fin quando la condizione ?WIN è valida. Se la sequenza non è corretta invece,
\ termina immediatamente il gioco.
: START_GAME
    SETUP_GAME 
    3 ROUND !
    BEGIN 
        ?WIN
        WHILE 
            'LED_ACCESI'  ROUND @ . CR 
            ROUND @ LOOP_LED 
            .S
            ROUND @ COUNTER ! 
            0 ERROR ! 
            BEGIN 
                READ_PRESSED_BUTTON 
                COUNTER @ 0 = ERROR @ 1 = OR 
                
            UNTIL 
            ERROR @ 0 = IF ROUND @ 1 + ROUND ! 
            THEN 
            ROUND @ 10 = IF 'HAI_VINTO' THEN 
            ERROR @ 1 = IF 'HAI_PERSO' THEN 
    REPEAT 
;















\CONTATORE CHE SI INCREMENTA E STAMPA COUNTER 
VARIABLE COUNTER 
3 COUNTER !  
: INCREMENT_COUNTER    COUNTER @ 1 + COUNTER ! COUNTER @ . ; 


\ SUBROUTINE CHE ACCEDE ALL'I-ESIMO ELEMENTO DELL'ARRAY

LDR R0,[R1,OFFSET] 