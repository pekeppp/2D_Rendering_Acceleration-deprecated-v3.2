/* sim/start.S —— QEMU virt (riscv32) 裸机启动：设 gp/sp 后跳 sim_main 的 main */
    .section .text.start, "ax"
    .globl _start
_start:
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop
    la      sp, _stack_top
    call    main
1:  j       1b
