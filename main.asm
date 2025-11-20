; ------------------------------------------------------------
; IC3101 - Arquitectura de Computadores
; Proyecto 2 - Producto interno de 2 vectores con AVX empacado
; MASM x64, devuelve resultado en XMM0 (float32).
; ------------------------------------------------------------

option casemap:none

extrn printf : proc

includelib msvcrt.lib

.data
; --- Datos de prueba ---
align 16
A_8 REAL4  1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  0.0,  0.0
B_8 REAL4  0.5, -1.0,  2.0, -2.5,  1.5,  0.25, 0.0,  0.0

; Versiones exactas de longitud 6
align 16
A_6 REAL4  1.0, 2.0, 3.0, 4.0, 5.0, 6.0
B_6 REAL4  0.5,-1.0, 2.0,-2.5,1.5, 0.25

; Buffers de salida (opcional para depurar)
res_met1 REAL4 0.0
res_met2 REAL4 0.0
res_met3 REAL4 0.0
res_met4 REAL4 0.0

fmtStr  db "Metodo %d -> dot(A,B) = %f", 10, 0

.code

reduccion_horizontal PROC
    ; cargar primeros 4 elementos de los vectores para usarlos en la operacion producto punto
    vmovups xmm0, xmmword ptr [A_6]
    vmovups xmm1, xmmword ptr [B_6]
    
    ;multiplicar en paralelo primeros 4 elementos de los vectores
    vmulps  xmm0, xmm0, xmm1
    
    ;cargar los 2 elementos restantes de los vectores para usarlos en la operacion producto punto
    vmovsd  xmm2, qword ptr [A_6  + 16]
    vmovsd  xmm3, qword ptr [B_6  + 16]
    
    ;multiplicar los 2 elementos restantes de los vectores
    vmulps  xmm2, xmm2, xmm3 
    
    ;sumar los productos de las multiplicaciones de ambas partes del vector
    vaddps  xmm0, xmm0, xmm2
    
    ; reducción #1
    vhaddps xmm0, xmm0, xmm0
    
    ; reducción #2
    vhaddps xmm0, xmm0, xmm0 
    ret ; xmm0 tiene el resultado
reduccion_horizontal ENDP

Dot_AVX_Perm   PROC    ; Integrante 2: vmulps + reduccion con vperm2f128 / vpermilps / vshufps
    ; TODO Integrante 2:
    ; 1) Cargas en YMM (usar A_8/B_8 facilita).
    ; 2) vmulps.
    ; 3) Reducir con permutaciones (vperm2f128 / vpermilps) y vaddps.
    ; 4) Colocar resultado final (float) en XMM0.
    ; 5) (opcional) guardar en res_met2.
    vxorps xmm0, xmm0, xmm0
    ret
Dot_AVX_Perm   ENDP

Dot_AVX_DPPS   PROC

    ;cargar la primera parte de los vectores (primeros 4 elementos) que se van a utilizar en la operacion produto punto
    vmovups xmm1, xmmword ptr [A_6]
    vmovups xmm2, xmmword ptr [B_6]

    ;realizar la operacion producto punto con los primeros 4 elementos de los vectores
    vdpps   xmm0, xmm1, xmm2, 0F1h ;0F1h pone el resultado solo en el primer elemento del registro

    ;cargar los elementos faltantes (ultimos 2) de los vectores
    vmovsd  xmm3, qword ptr [A_6 + 16]
    vmovsd  xmm4, qword ptr [B_6 + 16]

    ;producto punto de los dos elementos restantes de los vectores
    vdpps   xmm5, xmm3, xmm4, 031h

    ;sumar los resultados del producto punto realizado por partes (los primeros 4 elementos + los 2 elementos restantes
    vaddss  xmm0, xmm0, xmm5

    ;guardar el resultado final del producto punto en res_met3
    vmovss  dword ptr [res_met3], xmm0

    ret ;retorna el resultado del producto punto que quedo en xmm0

Dot_AVX_DPPS   ENDP

Dot_AVX_Tail   PROC
    ; Cargar primeros 4 elementos
    lea     rax, A_6
    lea     rbx, B_6
    vmovups xmm1, xmmword ptr [rax]      ; A[0..3]
    vmovups xmm2, xmmword ptr [rbx]      ; B[0..3]
    vmulps  xmm1, xmm1, xmm2             ; A[0..3] * B[0..3]

    ; Reducir a escalar
    vhaddps xmm1, xmm1, xmm1             ; horizontal add
    vhaddps xmm1, xmm1, xmm1             ; horizontal add
    vmovss  xmm0, xmm1                   ; resultado parcial en xmm0

    ; Cargar últimos 2 elementos
    vmovsd  xmm3, qword ptr [rax + 16]   ; A[4..5]
    vmovsd  xmm4, qword ptr [rbx + 16]   ; B[4..5]
    vmulps  xmm3, xmm3, xmm4             ; A[4..5] * B[4..5]

    ; Sumar los dos productos
    vhaddps xmm3, xmm3, xmm3             ; sumar A[4]*B[4] + A[5]*B[5]
    vaddss  xmm0, xmm0, xmm3             ; resultado final

    ret
Dot_AVX_Tail   ENDP

; ------------------------------------------------------------
; main: llama a los 4 metodos (para prueba). Cada quien edita SOLO su PROC.
; ------------------------------------------------------------
main PROC
    sub     rsp, 40

    ;Llamar metodo 1
    call    reduccion_horizontal
    vmovss  dword ptr [res_met1], xmm0

    ; printf("Metodo %d -> dot(A,B) = %f\n", 1, res_met1)
    vcvtss2sd xmm2, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 1
    call    printf

    ; Llamar metodo 2
    call    Dot_AVX_Perm
    vmovss  dword ptr [res_met2], xmm0

    vcvtss2sd xmm2, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 2
    call    printf

    ; Llamar metodo 3
    call    Dot_AVX_DPPS
    vmovss  dword ptr [res_met3], xmm0

    vcvtss2sd xmm2, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 3
    call    printf

    ; Llamar metodo 4
    call    Dot_AVX_Tail
    vmovss  dword ptr [res_met4], xmm0

    vcvtss2sd xmm2, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 4
    call    printf

    add     rsp, 40
    xor     eax, eax
    ret
main ENDP

END
