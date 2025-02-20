.data
# Example adjacency matrix (graph)
graph: .word 0, 4, 0, 0, 0, 0, 0, 8, 0      # 0 -> [1|4] -> [7|8]
       .word 4, 0, 8, 0, 0, 0, 0, 11, 0     # 1 -> [0|4] -> [2|8] -> [7|11]
       .word 0, 8, 0, 7, 0, 4, 0, 0, 2      # 2 -> [1|8] -> [3|7] -> [5|4] -> [9|2]
       .word 0, 0, 7, 0, 9, 14, 0, 0, 0     # ...
       .word 0, 0, 0, 9, 0, 10, 0, 0, 0
       .word 0, 0, 4, 14, 10, 0, 2, 0, 0
       .word 0, 0, 0, 0, 0, 2, 0, 1, 6
       .word 8, 11, 0, 0, 0, 0, 1, 0, 7
       .word 0, 0, 2, 0, 0, 0, 6, 7, 0
# Distance vector
distances: .word 0, 9999, 9999, 9999, 9999, 9999, 9999, 9999, 9999
# Visited nodes vector
visited: .word 0, 0, 0, 0, 0, 0, 0, 0, 0
# Precentes
precedent: .word -1, -1, -1, -1, -1, -1, -1, -1, -1
# Number of nodes
num_nodes: .word 9

newline: .asciiz "\n"
space: .asciiz " "
precedent_index: .asciiz "prec: "
vertex: .asciiz "vert: "
distance_str: .asciiz "dist: "
vertex_chose: .asciiz "O vertice que voce quer o caminho: "
seta: .asciiz " <----("
final_seta: .asciiz ")---- "
caminho: .asciiz "Caminho: "

.text
.globl main

main:
    # Initialization
    la $s0, distances       # Carrega o endereco do vetor de distancias
    la $s1, visited         # Carrega o endereco do vetor de nos visitados
    la $s2, graph           # Carrega o endereco da matriz de adjacencia
    lw $s3, num_nodes       # Carrega o numero de nos
    li $s4, 9               # Numero de linhas e colunas (9)
    li $s5, 0               # Contador de nos processados
    la $s6, precedent       # Carrega vetor de precedentes
    li $s7, 0               # Armazena o no inicial
    li $t0, 0               # Inicializa com vertice na linha 0 (i = 0)

main_loop:
    beq $s5, $s3, print_distances  # Se todos os nos foram processados, imprime distancias

    move $a0, $t0
    jal relax_edges         # Relaxa as arestas do no atual

    jal find_min_distance   # Encontra o no com a menor distancia
    move $t0, $v0           # $t0 = no com a menor distancia

    # Marcar o no como visitado
    li $t2, 1
    sll $t1, $t0, 2
    add $t1, $s1, $t1
    sw $t2, 0($t1)

    addi $s5, $s5, 1        # Incrementa o contador de nos processados

    j main_loop

# Funcao para encontrar o no com a menor distancia
find_min_distance:
    li $t0, 0               # Inicializa o indice da coluna (j = 0)
    li $t8, 9999            # Inicializar a menor distancia
    li $t9, -1              # Armazena o indice com a menor distancia

loop_find_min:
    beq $t0, $s3, end_find_min  # Se j == numero de colunas, vai para fim do loop

    # Carrega adistancia do no atual
    sll $t1, $t0, 2
    add $t1, $s0, $t1
    lw $t2, 0($t1)          # $t2 = distance[current]

    # Carrega o status de visita do no atual
    sll $t1, $t0, 2
    add $t1, $s1, $t1
    lw $t3, 0($t1)

    # Se o no nao foi visitado ou tem uma distancia menor
    bnez $t3, next_node
    bge $t2, $t8, next_node

    # Atualiza a menor distancia e o indice(vertice) que a possui
    move $t8, $t2
    move $t9, $t0

next_node:
    addi $t0, $t0, 1
    j loop_find_min

end_find_min:
    move $v0, $t9
    jr $ra

# Funcao para relaxar as arestas do no atual
relax_edges:
    move $t0, $a0           # Armazena o indice da linha em $t0
    li $t1, 0               # Inicializa o indice da coluna (j = 0)

loop_relax:
    beq $t1, $s3, end_relax  # Se j == numero de colunas, vai para fim do loop

    # Calcula o endereco de graph[current][j]
    mul $t2, $t0, $s4       # $t2 = i x num de colunas
    add $t2, $t2, $t1       # $t2 = i x num de colunas + j
    sll $t2, $t2, 2         # $t2 = (i x num de colunas + j) x 4
    add $t2, $s2, $t2       # $t2 = graph + deslocamento
    lw $t3, 0($t2)          # $t3 = graph[current][j]

    beqz $t3, next_relax    # Se nao ha aresta (0), pula

    # Calcula nova distancia
    sll $t4, $t0, 2         # $t4 = i x 4
    add $t4, $s0, $t4       # $t4 = distance + (i x 4)
    lw $t4, 0($t4)          # $t4 = distance[current]
    add $t4, $t4, $t3       # $t4 = distance[current] + graph[current][j]

    # Compara com a distancia que ja existe
    sll $t5, $t1, 2         # $t5 = j x 4
    add $t5, $s0, $t5       # $t5 = distance + (j x 4)
    lw $t6, 0($t5)          # $t6 = distance[j]

    bge $t4, $t6, next_relax  # Se a nova distancia >= distancia existente, pula

    # Atualiza distancia
    sw $t4, 0($t5)

    # Armazena o predecessor
    sll $t7, $t1, 2
    add $t7, $s6, $t7
    sw $t0, 0($t7)

next_relax:
    addi $t1, $t1, 1
    j loop_relax

end_relax:
    jr $ra

print_distances:
    li $t0, 0               # Initialize counter

loop_print:
    beq $t0, $s3, end_main  # If counter == number of nodes, end

    # Imprime o vertice
    li $v0, 4
    la $a0, vertex
    syscall
    li $v0, 1
    move $a0, $t0
    syscall
    li $v0, 4
    la $a0, space
    syscall

    # Carrega e printa predecessor
    li $v0, 4
    la $a0, precedent_index
    syscall
    sll $t1, $t0, 2
    add $t1, $s6, $t1
    lw $a0, 0($t1)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, space
    syscall

    # Load and print distance
    li $v0, 4
    la $a0, distance_str
    syscall
    sll $t1, $t0, 2
    add $t1, $s0, $t1
    lw $a0, 0($t1)
    li $v0, 1
    syscall

    # Print newline
    la $a0, newline
    li $v0, 4
    syscall

    addi $t0, $t0, 1
    j loop_print

end_main:

    li $v0, 4
    la $a0, vertex_chose
    syscall

    li $v0, 5
    syscall
    move $t2, $v0
    li $v0, 4
    la $a0, newline
    syscall

    move $a0, $t2
    jal show_way

    # End program
    li $v0, 10
    syscall

show_way:
    move $t0, $a0
    j loop_way

loop_way:
    beqz $t0, end_way

    # Imprime o vertice
    li $v0, 1
    move $a0, $t0
    syscall

    # Load and print distance
    li $v0, 4
    la $a0, seta
    syscall
    sll $t1, $t0, 2
    add $t1, $s0, $t1
    lw $a0, 0($t1)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, final_seta
    syscall

    # Carrega e printa predecessor
    sll $t1, $t0, 2
    add $t1, $s6, $t1
    lw $t0, 0($t1)
    j loop_way

end_way:
    li $v0, 1
    move $a0, $s7
    syscall
    jr $ra