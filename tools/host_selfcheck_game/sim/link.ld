/* sim/link.ld —— 程序放 0x80000000（QEMU virt RAM 基址），栈顶留 256KB。
 * ★ 假 MMIO / 假 DDR 区（0x81000000 起）**不在这里**：那是 GameDemo.c 里被 -D 覆盖过的
 *   DDR_BASE / BLT_BASE / UART_TERM 直接访问的裸 RAM，QEMU 的 RAM 覆盖到 0x88000000，
 *   只要程序本身 < 1MB 就绝不会与它重叠。 */
OUTPUT_ARCH(riscv)
ENTRY(_start)
MEMORY {
    RAM (rwxa) : ORIGIN = 0x80000000, LENGTH = 16M
}
SECTIONS {
    . = 0x80000000;
    .text : { *(.text.start) *(.text*) } > RAM
    . = ALIGN(16);
    __global_pointer$ = . + 0x800;
    .rodata : { *(.rodata*) *(.srodata*) } > RAM
    .data : { *(.data*) *(.sdata*) } > RAM
    .bss : { *(.bss*) *(.sbss*) *(COMMON) } > RAM
    . = ALIGN(16);
    . += 0x40000;                 /* 256KB 栈 */
    _stack_top = .;
    /DISCARD/ : { *(.comment) *(.note*) *(.riscv.attributes) }
}
