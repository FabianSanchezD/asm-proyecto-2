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
    ; cargar primeros 4 elementos de los vectores
    lea     rax, A_6
    lea     rbx, B_6
    vmovups xmm0, xmmword ptr [rax]
    vmovups xmm1, xmmword ptr [rbx]
    
    ; multiplicar en paralelo primeros 4
    vmulps  xmm0, xmm0, xmm1
    
    ; cargar ultimos 2 elementos
    vmovsd  xmm2, qword ptr [rax + 16]
    vmovsd  xmm3, qword ptr [rbx + 16]
    
    ; multiplicar ultimos 2
    vmulps  xmm2, xmm2, xmm3 
    
    ; combinar productos
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

Dot_AVX_DPPS   PROC    ; Integrante 3: usar VDPPS (dot product) por bloques y combinar
    ; Pista: VDPPS (instrucción AVX) acepta XMM/YMM y máscara (imm8).
    ; Para longitud 6, pueden:
    ;   - hacer dot de los primeros 4 elementos (mask 0xF1 ó similar),
    ;   - luego sumar el dot de los 2 restantes (con máscara que seleccione solo esos),
    ;   - combinar resultados (vaddss).
    ; TODO Integrante 3:
    ; 1) Preparar máscaras inmediatas.
    ; 2) vdp_ps para 4 elems y para 2 elems (zero-pad o usar XMM de 128 bits).
    ; 3) Sumar parciales y dejarlo en XMM0.
    ; 4) (opcional) guardar en res_met3.
    vxorps xmm0, xmm0, xmm0
    ret
Dot_AVX_DPPS   ENDP

Dot_AVX_Tail   PROC    ; Integrante 4: estrategia mixta (YMM para 4 + XMM para 2, sin leer fuera)
    ; TODO Integrante 4:
    ; 1) Cargar 4 elems en YMM/XMM y multiplicar (vmulps).
    ; 2) Reducir esos 4 a escalar (hadd/perm/add).
    ; 3) Cargar los 2 elems restantes en XMM, vmulps, sumarlos al escalar.
    ; 4) Resultado final en XMM0.
    ; 5) (opcional) guardar en res_met4.
    vxorps xmm0, xmm0, xmm0
    ret
Dot_AVX_Tail   ENDP

; ------------------------------------------------------------
; main: llama a los 4 metodos (para prueba). Cada quien edita SOLO su PROC.
; ------------------------------------------------------------
main PROC
    sub     rsp, 32

    ; Llamar metodo 1
    call    reduccion_horizontal
    vmovss  dword ptr [res_met1], xmm0
    ; printf("Metodo %d -> dot(A,B) = %f\n", 1, res_met1)
    vcvtss2sd xmm1, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 1
    sub     rsp, 32
    call    printf
    add     rsp, 32

    ; Llamar metodo 2
    call    Dot_AVX_Perm
    vmovss  dword ptr [res_met2], xmm0
    vcvtss2sd xmm1, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 2
    sub     rsp, 32
    call    printf
    add     rsp, 32

    ; Llamar metodo 3
    call    Dot_AVX_DPPS
    vmovss  dword ptr [res_met3], xmm0
    vcvtss2sd xmm1, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 3
    sub     rsp, 32
    call    printf
    add     rsp, 32

    ; Llamar metodo 4
    call    Dot_AVX_Tail
    vmovss  dword ptr [res_met4], xmm0
    vcvtss2sd xmm1, xmm0, xmm0
    mov     rcx, OFFSET fmtStr
    mov     edx, 4
    sub     rsp, 32
    call    printf
    add     rsp, 32

    add     rsp, 32
    ret
main ENDP

END
