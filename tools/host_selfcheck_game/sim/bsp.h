/* =============================================================================
 * sim/bsp.h —— 主机仿真用的「假 BSP」
 * -----------------------------------------------------------------------------
 * 主机自检把 **GameDemo.c 原样 #include 进来**编译（见 sim_main.c），
 * 所以这里只要提供 GameDemo.c 真正用到的那几个符号即可：
 *   · BSP_CLINT / BSP_CLINT_HZ      —— clint_getTimeLow() 的参数与频率口径
 *   · SYSTEM_UART_0_IO_CTRL         —— UART_TERM 的默认值（仿真里被 -D 覆盖成 RAM 里的假寄存器）
 *   · bsp_init / bsp_printf / clint_getTimeLow —— 由 sim_main.c 实现（**不是**板级 BSP）
 *
 * ★ 这里**故意**不引入真实 BSP 头：真实 print.h 是 mini 版、semihosting.h 有一堆
 *   静态函数，带进来只会把自检日志淹掉；仿真要的是「同一份 GameDemo.c 源码」，
 *   不是「同一套 BSP」。
 * ============================================================================= */
#ifndef GAMEDEMO_SIM_BSP_H
#define GAMEDEMO_SIM_BSP_H

#include <stdint.h>

#define BSP_CLINT                 0
#define BSP_CLINT_HZ              100000000u     /* SYSTEM_CLINT_HZ，与板级一致 */

/* 仿真里 UART_TERM / BLT_BASE / DDR_BASE 都由命令行 -D 覆盖成 RAM 里的假寄存器区，
 * 这里的值只是「万一没覆盖」的兜底。 */
#define SYSTEM_UART_0_IO_CTRL     0x82100000UL

void     bsp_init(void);
void     bsp_printf(const char *fmt, ...);
uint32_t clint_getTimeLow(int p);

#endif /* GAMEDEMO_SIM_BSP_H */
