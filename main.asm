; ------------------------------------------------------------
; IC3101 - PROYECTO 2 (Segundo Semestre 2025)
; Producto interno de 2 vectores (longitud 6, float32) con AVX empacado
; Base de código dividida en 4 métodos (uno por integrante)
; Ensamblador: MASM x64 (ml64.exe). Convención Windows x64.
; Devuelve resultado en XMM0 (float32).
; ------------------------------------------------------------

option casemap:none

extrn printf : proc

includelib msvcrt.lib

.data
; --- Datos de prueba (cada quien puede cambiar sus casos en su función) ---
; NOTA: Para facilitar cargas YMM (8 floats), se proveen versiones de 8 elementos
; con los dos últimos en 0.0 (padding). Úsenlas si van a cargar YMM completos.
align 32
A_8 REAL4  1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  0.0,  0.0
B_8 REAL4  0.5, -1.0,  2.0, -2.5,  1.5,  0.25, 0.0,  0.0

; Versiones exactas de longitud 6 (por si prefieren mezclar XMM + YMM o manejar cola)
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

; ------------------------------------------------------------
; Prototipos (cada integrante implementa su PROC)
; Cada PROC debe:
;   - Calcular sum_{i=1..6} A[i]*B[i] con instrucciones AVX empacadas
;   - Devolver el resultado en XMM0 (float32)
;   - (Opcional) guardar en res_metX para validar
; ------------------------------------------------------------
Dot_AVX_HAdd   PROC    ; Integrante 1: vmulps + reduccion con vhaddps / vextractf128
    ; TODO Integrante 1:
    ; 1) Cargar A y B (A_8/B_8 o A_6/B_6) en registros XMM/YMM.
    ; 2) vmulps en paralelo.
    ; 3) Reducir a un escalar (suma horizontal). Opciones:
    ;    - vhaddps en pasos + vextractf128
    ;    - permutaciones + vaddps
    ; 4) mover el escalar final a XMM0.
    ; 5) (opcional) guardarlo en res_met1.
    vxorps xmm0, xmm0, xmm0
    ret
Dot_AVX_HAdd   ENDP

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
    sub     rsp, 32                     ; shadow space

    ; Llamar metodo 1
    call    Dot_AVX_HAdd
    vmovss  dword ptr [res_met1], xmm0
    ; printf("Metodo %d -> dot(A,B) = %f\n", 1, res_met1)
    ; printf usa ABI varargs en MSVCRT; pasar float como double: ampliar a XMM1
    vcvtss2sd xmm1, xmm0, xmm0
    mov     ecx, OFFSET fmtStr          ; 1er arg: const char*
    mov     edx, 1                      ; 2do arg: int (metodo #)
    sub     rsp, 32                     ; espacio para alinear stack de varargs
    call    printf
    add     rsp, 32

    ; Llamar metodo 2
    call    Dot_AVX_Perm
    vmovss  dword ptr [res_met2], xmm0
    vcvtss2sd xmm1, xmm0, xmm0
    mov     ecx, OFFSET fmtStr
    mov     edx, 2
    sub     rsp, 32
    call    printf
    add     rsp, 32

    ; Llamar metodo 3
    call    Dot_AVX_DPPS
    vmovss  dword ptr [res_met3], xmm0
    vcvtss2sd xmm1, xmm0, xmm0
    mov     ecx, OFFSET fmtStr
    mov     edx, 3
    sub     rsp, 32
    call    printf
    add     rsp, 32

    ; Llamar metodo 4
    call    Dot_AVX_Tail
    vmovss  dword ptr [res_met4], xmm0
    vcvtss2sd xmm1, xmm0, xmm0
    mov     ecx, OFFSET fmtStr
    mov     edx, 4
    sub     rsp, 32
    call    printf
    add     rsp, 32

    add     rsp, 32
    ret
main ENDP

END
