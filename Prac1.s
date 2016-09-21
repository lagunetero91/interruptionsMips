		.data 0xFFFF0000
KeyStatus:	.space 4
KeyData:	.space 4
DispStatus:	.space 4
DispData:	.space 4

		.data 0x10000000
frase:		.asciiz "En un lugar de La Mancha de cuyo nombre no me acuerdo ......\n"
mensaje1:	.asciiz " [Pulsación("
mensaje2:	.asciiz ") = "
mensaje3:	.asciiz "] "
		.align 4
Letra:		.asciiz " "
		.align 4
Hora: 		.space 4
minutos:	.space 4
segundos:	.space 4
men_hora:	.asciiz "\nIntroduzca la hora: "
men_min:	.asciiz "Introduzca los minutos: "	
men_seg:	.asciiz "Introduzca los segundos: "	
hora_local:	.asciiz "\nHora local-> "
men_pun:	.asciiz ":"
ultimo:		.asciiz "\n"
		.text
		
		.globl main

main:		jal KbdIntrEnable
		jal TimerIntrEnable
		li $s4,0			# Contador de pulsaciones
		li $t0,0			# Condicion mostrar reloj
principio:	
		li $s6,0			# Contador del delay
		li $t1, 40000			# Tiempo del delay
		jal PrintCharacter
		jal Delay
		j principio


##############################################################
####     Delay                                            ####
##############################################################

Delay:		beq $s6,$t1, fin
		addi $s6,$s6,1
		j Delay
fin:		jr $ra


##############################################################
####     PrintCharacter                                   ####
##############################################################

PrintCharacter:	addi $s5,$s5,0
		lb $a0,frase($s5)
		beq $a0,$0, Repetir		# Comprobamos que no estemos al final de la frase
		la $t3, DispData
		lw $t2, DispStatus($0)
		andi $t2, $t2,1
		beq $t2,$0, PrintCharacter	# Comprobamos si la pantalla esta lista para pedir dato
		sw $a0,0($t3)
		addi $s5,$s5,1
		jr $ra
Repetir:	li $s5,0			# Volver al principio de la frase
		j PrintCharacter


##############################################################
####     KbdIntrEnable                                    ####
####     -Habilitar interrupciones del teclado		  ####
##############################################################

KbdIntrEnable: 	la $s1, KeyStatus		# Habilitar interrupciones en teclado
		lw $s2,0($s1)
		ori $s2,$s2, 0x2
		sw $s2, 0($s1)
		mfc0 $t2, $12			# Habilitar interrupcion de teclado en procesador
		ori $t2, $t2, 0x801
		mtc0 $t2,$12
		jr $ra


##############################################################
####     TimerIntrEnable                                  ####
####     -Habilitar interrupciones del timer		  ####
##############################################################

TimerIntrEnable:mfc0 $t2, $12			# Habilitar interrupcion Timer en procesador
		ori $t2, $t2, 0x8001
		mtc0 $t2,$12
		li $t2, 1000
		mtc0 $t2,$11
		mtc0 $0,$9
		jr $ra


##############################################################
####     CauseIntr()                                      ####
####     -Detecta causa de interrupcion	  		  ####
##############################################################

CauseIntr:	subu $sp, $sp, 4		# Pila
		sw $ra, 0($sp)

		mfc0 $k0,$13			# Comprobamos registro de causa
		li $t7,0x800			# Interrupcion del teclado
		and $t8,$k0,$t7
		beq $t8,$t7,teclado

		li $t7,0x8000			# Interrupcion del timer
		and $t8,$k0,$t7
		beq $t8,$t7,timer
		lw $ra, 0($sp)
		addu $sp, $sp, 4
		jr $ra

teclado:	jal KbdIntr
		lw $ra, 0($sp)
		addu $sp, $sp, 4
		jr $ra

timer:		jal TimerIntr
		lw $ra, 0($sp)
		addu $sp, $sp, 4
		jr $ra


##############################################################
####     KbdIntr()                                        ####
####     -Rutina de servicio del teclado	  	  ####
##############################################################

KbdIntr:	li $t7,0x12			# Codigo de crtl+R	
		la $s1, KeyData
		lw $t4,0($s1)
		andi $t4,$t4,0xff
		beq $t4,$t7,Reloj		# Vamos a inicializar el reloj
		addi $s4,$s4,1
		
		li $v0, 4 			# Mostrar primer mensaje
		la $a0, mensaje1
		syscall

		li $v0, 1 			# Mostrar contador
		add $a0, $s4, $0
		syscall

		li $v0, 4 			# Mostrar segundo mensaje
		la $a0, mensaje2
		syscall

		li $v0, 4 			# Mostrar letra pulsada
		la $a0, Letra
		sw $t4,0($a0)
		syscall

		li $v0, 4 			# Mostrar tercer mensaje
		la $a0, mensaje3
		syscall

		jr $ra


##############################################################
####     TimerIntr()                                      ####
####     -Rutina de servicio del timer	  	          ####
##############################################################

TimerIntr:	beq $t0,$0,no_activo		# Se comprueba si se ha introducido la hora local

		la $t5, segundos		# Colocar formato segundos
		lw $s3,0($t5)
		li $t9, 60
		div $s3,$t9
		mfhi $v0
		sw $v0,0($t5)
		mflo $v1

		la $t5, minutos			# Colocar formato minutos
		lw $s3,0($t5)
		add $s3, $s3, $v1
		div $s3,$t9
		mfhi $v0
		sw $v0,0($t5)
		mflo $v1
		li $t9, 24

		la $t5, Hora			# Colocar formato horas
		lw $s3,0($t5)
		add $s3, $s3, $v1
dividir:	div $s3,$t9
		mfhi $s3
		bge $s3, $t9, dividir
		mfhi $v0
		sw $v0,0($t5)
		

		li $v0, 4 			# Mostrar mensaje hora local
		la $a0, hora_local
		syscall

		la $t5, Hora			# Mostrar hora
		lw $a0,0($t5)
		li $v0, 1
		syscall

		li $v0, 4 			# Mostrar 2 puntos
		la $a0, men_pun
		syscall

		la $t5, minutos			# Mostrar minutos
		lw $a0,0($t5)
		li $v0, 1
		syscall

		li $v0, 4 			# Mostrar 2 puntos
		la $a0, men_pun
		syscall

		la $t5, segundos		# Mostrar segundos
		lw $a0,0($t5)
		li $v0, 1
		syscall

		li $v0, 4 			# Salto de linea
		la $a0, ultimo
		syscall
		

		la $t5, segundos
		lw $s3,0($t5)
		addi $s3,$s3,1
		sw $s3,0($t5)
no_activo:	mtc0 $0,$9
		jr $ra
		

##############################################################
####     Reloj()                                	  ####
####     -Rutina para inicializar reloj	  	          ####
##############################################################

Reloj:		li $v0, 4 			# Mostrar primer mensaje
		la $a0, men_hora
		syscall

		li $v0, 5
		syscall

		la $t5, Hora
		sw $v0, 0($t5)
		li $v0, 4 			# Mostrar primer mensaje
		la $a0, men_min
		syscall

		li $v0, 5
		syscall

		la $t5, minutos
		sw $v0, 0($t5)
		li $v0, 4 			# Mostrar primer mensaje
		la $a0, men_seg
		syscall

		li $v0, 5
		syscall

		la $t5, segundos
		sw $v0, 0($t5)
		li $t0,1			# Habilitar mensaje del reloj
		jr $ra
	