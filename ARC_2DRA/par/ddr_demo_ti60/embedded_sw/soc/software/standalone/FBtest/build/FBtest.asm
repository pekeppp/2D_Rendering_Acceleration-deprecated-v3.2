
build/FBtest.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00001197          	auipc	gp,0x1
    1004:	35818193          	addi	gp,gp,856 # 2358 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00002117          	auipc	sp,0x2
    100c:	b7810113          	addi	sp,sp,-1160 # 2b80 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00001517          	auipc	a0,0x1
    1014:	8e050513          	addi	a0,a0,-1824 # 18f0 <_data>
	la a1, _data
    1018:	00001597          	auipc	a1,0x1
    101c:	8d858593          	addi	a1,a1,-1832 # 18f0 <_data>
	la a2, _edata
    1020:	00001617          	auipc	a2,0x1
    1024:	b5460613          	addi	a2,a2,-1196 # 1b74 <__bss_start>
	bgeu a1, a2, 2f
    1028:	00c5fc63          	bgeu	a1,a2,1040 <init+0x38>
1:
	lw t0, (a0)
    102c:	00052283          	lw	t0,0(a0)
	sw t0, (a1)
    1030:	0055a023          	sw	t0,0(a1)
	addi a0, a0, 4
    1034:	00450513          	addi	a0,a0,4
	addi a1, a1, 4
    1038:	00458593          	addi	a1,a1,4
	bltu a1, a2, 1b
    103c:	fec5e8e3          	bltu	a1,a2,102c <init+0x24>
2:

	/* Clear bss section */
	la a0, __bss_start
    1040:	00001517          	auipc	a0,0x1
    1044:	b3450513          	addi	a0,a0,-1228 # 1b74 <__bss_start>
	la a1, _end
    1048:	00001597          	auipc	a1,0x1
    104c:	b3058593          	addi	a1,a1,-1232 # 1b78 <_end>
	bgeu a0, a1, 2f
    1050:	00b57863          	bgeu	a0,a1,1060 <init+0x58>
1:
	sw zero, (a0)
    1054:	00052023          	sw	zero,0(a0)
	addi a0, a0, 4
    1058:	00450513          	addi	a0,a0,4
	bltu a0, a1, 1b
    105c:	feb56ce3          	bltu	a0,a1,1054 <init+0x4c>
2:

#ifndef NO_LIBC_INIT_ARRAY
	call __libc_init_array
    1060:	010000ef          	jal	1070 <__libc_init_array>
#endif

	call main
    1064:	0a0000ef          	jal	1104 <main>

00001068 <mainDone>:
mainDone:
    j mainDone
    1068:	0000006f          	j	1068 <mainDone>

0000106c <_init>:


	.globl _init
_init:
    ret
    106c:	00008067          	ret

Disassembly of section .text:

00001070 <__libc_init_array>:
    1070:	ff010113          	addi	sp,sp,-16
    1074:	00812423          	sw	s0,8(sp)
    1078:	01212023          	sw	s2,0(sp)
    107c:	00001797          	auipc	a5,0x1
    1080:	87478793          	addi	a5,a5,-1932 # 18f0 <_data>
    1084:	00001417          	auipc	s0,0x1
    1088:	86c40413          	addi	s0,s0,-1940 # 18f0 <_data>
    108c:	00112623          	sw	ra,12(sp)
    1090:	00912223          	sw	s1,4(sp)
    1094:	40878933          	sub	s2,a5,s0
    1098:	02878063          	beq	a5,s0,10b8 <__libc_init_array+0x48>
    109c:	40295913          	srai	s2,s2,0x2
    10a0:	00000493          	li	s1,0
    10a4:	00042783          	lw	a5,0(s0)
    10a8:	00148493          	addi	s1,s1,1
    10ac:	00440413          	addi	s0,s0,4
    10b0:	000780e7          	jalr	a5
    10b4:	ff24e8e3          	bltu	s1,s2,10a4 <__libc_init_array+0x34>
    10b8:	00001797          	auipc	a5,0x1
    10bc:	83878793          	addi	a5,a5,-1992 # 18f0 <_data>
    10c0:	00001417          	auipc	s0,0x1
    10c4:	83040413          	addi	s0,s0,-2000 # 18f0 <_data>
    10c8:	40878933          	sub	s2,a5,s0
    10cc:	40295913          	srai	s2,s2,0x2
    10d0:	00878e63          	beq	a5,s0,10ec <__libc_init_array+0x7c>
    10d4:	00000493          	li	s1,0
    10d8:	00042783          	lw	a5,0(s0)
    10dc:	00148493          	addi	s1,s1,1
    10e0:	00440413          	addi	s0,s0,4
    10e4:	000780e7          	jalr	a5
    10e8:	ff24e8e3          	bltu	s1,s2,10d8 <__libc_init_array+0x68>
    10ec:	00c12083          	lw	ra,12(sp)
    10f0:	00812403          	lw	s0,8(sp)
    10f4:	00412483          	lw	s1,4(sp)
    10f8:	00012903          	lw	s2,0(sp)
    10fc:	01010113          	addi	sp,sp,16
    1100:	00008067          	ret

00001104 <main>:
    for (i = 0; i < FRAME_DELAY_LOOPS; i++) { }
}

/* ------------------------------------------------------------------ */
void main(void)
{
    1104:	fd010113          	addi	sp,sp,-48
    1108:	02112623          	sw	ra,44(sp)
    110c:	02812423          	sw	s0,40(sp)
    1110:	02912223          	sw	s1,36(sp)
    1114:	03212023          	sw	s2,32(sp)
    1118:	01312e23          	sw	s3,28(sp)
    111c:	01412c23          	sw	s4,24(sp)
    1120:	01512a23          	sw	s5,20(sp)
    1124:	01612823          	sw	s6,16(sp)
    1128:	01712623          	sw	s7,12(sp)
    112c:	01812423          	sw	s8,8(sp)
    int x  = 0, y = 0, dx = 12, dy = 8;
    int x2 = FB_WIDTH - BOX2_W, y2 = FB_HEIGHT - BOX2_H, dx2 = -9, dy2 = -6;
    uint32_t frame = 0;

    bsp_printf("\r\n*** 2DRA: CPU writes DDR framebuffer -> HDMI scanout ***\r\n");
    1130:	00002537          	lui	a0,0x2
    1134:	96450513          	addi	a0,a0,-1692 # 1964 <_data+0x74>
    1138:	688000ef          	jal	17c0 <bsp_printf>
    bsp_printf("FB0=0x%x  FB1=0x%x  %dx%d RGB565  stride=%d  bytes=%d\r\n",
    113c:	000fd837          	lui	a6,0xfd
    1140:	20080813          	addi	a6,a6,512 # fd200 <__freertos_irq_stack_top+0xfa680>
    1144:	78000793          	li	a5,1920
    1148:	21c00713          	li	a4,540
    114c:	3c000693          	li	a3,960
    1150:	00401637          	lui	a2,0x401
    1154:	003015b7          	lui	a1,0x301
    1158:	00002537          	lui	a0,0x2
    115c:	9a450513          	addi	a0,a0,-1628 # 19a4 <_data+0xb4>
    1160:	660000ef          	jal	17c0 <bsp_printf>
               (unsigned)FB_BASE, (unsigned)FB1_BASE,
               FB_WIDTH, FB_HEIGHT, FB_STRIDE, FB_BYTES);

    /* 1) 缓存一致性自检：确认"CPU 写的数据真的落到 DDR"（HDMI 读的是 DDR） */
    if (coherency_check())
    1164:	5a8000ef          	jal	170c <coherency_check>
    1168:	04050663          	beqz	a0,11b4 <main+0xb0>
        bsp_printf("coherency check: PASS (CPU writes reach DDR)\r\n");
    116c:	00002537          	lui	a0,0x2
    1170:	9dc50513          	addi	a0,a0,-1572 # 19dc <_data+0xec>
    1174:	64c000ef          	jal	17c0 <bsp_printf>
    else
        bsp_printf("coherency check: FAIL -> 需按文档处理 D$ 一致性（write-back 需清理）\r\n");

    /* 2) 静态背景彩条（先确认屏上能显示 DDR 内容） */
    fill_bg_bars();
    1178:	4d8000ef          	jal	1650 <fill_bg_bars>
    cache_evict();
    117c:	560000ef          	jal	16dc <cache_evict>
    bsp_printf("background color bars written, start animation ...\r\n");
    1180:	00002537          	lui	a0,0x2
    1184:	a6450513          	addi	a0,a0,-1436 # 1a64 <_data+0x174>
    1188:	638000ef          	jal	17c0 <bsp_printf>
    uint32_t frame = 0;
    118c:	00000a13          	li	s4,0
    int x2 = FB_WIDTH - BOX2_W, y2 = FB_HEIGHT - BOX2_H, dx2 = -9, dy2 = -6;
    1190:	ffa00c13          	li	s8,-6
    1194:	ff700b93          	li	s7,-9
    1198:	1cc00993          	li	s3,460
    119c:	37000913          	li	s2,880
    int x  = 0, y = 0, dx = 12, dy = 8;
    11a0:	00800b13          	li	s6,8
    11a4:	00c00a93          	li	s5,12
    11a8:	00000493          	li	s1,0
    11ac:	00000413          	li	s0,0
    11b0:	09c0006f          	j	124c <main+0x148>
        bsp_printf("coherency check: FAIL -> 需按文档处理 D$ 一致性（write-back 需清理）\r\n");
    11b4:	00002537          	lui	a0,0x2
    11b8:	a0c50513          	addi	a0,a0,-1524 # 1a0c <_data+0x11c>
    11bc:	604000ef          	jal	17c0 <bsp_printf>
    11c0:	fb9ff06f          	j	1178 <main+0x74>
        /* 背景重画（同时天然把上一帧的方块"擦掉"） */
        fill_bg_bars();

        /* 元素1：大色块弹跳，颜色每帧轮换 */
        x += dx;  y += dy;
        if (x <= 0)                    { x = 0;                   dx = -dx; }
    11c4:	41500ab3          	neg	s5,s5
    11c8:	00000413          	li	s0,0
    11cc:	0900006f          	j	125c <main+0x158>
        if (y <= 0)                    { y = 0;                   dy = -dy; }
    11d0:	41600b33          	neg	s6,s6
    11d4:	00000493          	li	s1,0
    11d8:	0880006f          	j	1260 <main+0x15c>
        if (y >= FB_HEIGHT - BOX_H)    { y = FB_HEIGHT - BOX_H;    dy = -dy; }
        fill_rect(x, y, BOX_W, BOX_H, PAL8[frame & 7]);

        /* 元素2：小白块反向弹跳 */
        x2 += dx2; y2 += dy2;
        if (x2 <= 0)                    { x2 = 0;                    dx2 = -dx2; }
    11dc:	41700bb3          	neg	s7,s7
    11e0:	00000913          	li	s2,0
    11e4:	0d40006f          	j	12b8 <main+0x1b4>
        if (y2 <= 0)                    { y2 = 0;                    dy2 = -dy2; }
    11e8:	41800c33          	neg	s8,s8
    11ec:	00000993          	li	s3,0
    11f0:	0cc0006f          	j	12bc <main+0x1b8>
        if (x2 >= FB_WIDTH  - BOX2_W)   { x2 = FB_WIDTH  - BOX2_W;    dx2 = -dx2; }
        if (y2 >= FB_HEIGHT - BOX2_H)   { y2 = FB_HEIGHT - BOX2_H;    dy2 = -dy2; }
        fill_rect(x2, y2, BOX2_W, BOX2_H, C_WHITE);
    11f4:	00010737          	lui	a4,0x10
    11f8:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xd47f>
    11fc:	05000693          	li	a3,80
    1200:	05000613          	li	a2,80
    1204:	00098593          	mv	a1,s3
    1208:	00090513          	mv	a0,s2
    120c:	350000ef          	jal	155c <fill_rect>

        /* 4) 本帧写完后把数据推入 DDR，再作废 D$（保证扫描输出读到新画面） */
        cache_evict();
    1210:	4cc000ef          	jal	16dc <cache_evict>
    1214:	0000500f          	.word	0x0000500f
        data_cache_invalidate_all();

        frame++;
    1218:	001a0a13          	addi	s4,s4,1
        if ((frame % 30) == 0)
    121c:	01e00793          	li	a5,30
    1220:	02fa77b3          	remu	a5,s4,a5
    1224:	02079263          	bnez	a5,1248 <main+0x144>
            bsp_printf("frame=%u  box=(%d,%d)  small=(%d,%d)\r\n",
    1228:	00098793          	mv	a5,s3
    122c:	00090713          	mv	a4,s2
    1230:	00048693          	mv	a3,s1
    1234:	00040613          	mv	a2,s0
    1238:	000a0593          	mv	a1,s4
    123c:	00002537          	lui	a0,0x2
    1240:	a9c50513          	addi	a0,a0,-1380 # 1a9c <_data+0x1ac>
    1244:	57c000ef          	jal	17c0 <bsp_printf>
                       (unsigned)frame, x, y, x2, y2);

        frame_delay();
    1248:	548000ef          	jal	1790 <frame_delay>
        fill_bg_bars();
    124c:	404000ef          	jal	1650 <fill_bg_bars>
        x += dx;  y += dy;
    1250:	01540433          	add	s0,s0,s5
    1254:	016484b3          	add	s1,s1,s6
        if (x <= 0)                    { x = 0;                   dx = -dx; }
    1258:	f68056e3          	blez	s0,11c4 <main+0xc0>
        if (y <= 0)                    { y = 0;                   dy = -dy; }
    125c:	f6905ae3          	blez	s1,11d0 <main+0xcc>
        if (x >= FB_WIDTH  - BOX_W)    { x = FB_WIDTH  - BOX_W;    dx = -dx; }
    1260:	31f00793          	li	a5,799
    1264:	0087d663          	bge	a5,s0,1270 <main+0x16c>
    1268:	41500ab3          	neg	s5,s5
    126c:	32000413          	li	s0,800
        if (y >= FB_HEIGHT - BOX_H)    { y = FB_HEIGHT - BOX_H;    dy = -dy; }
    1270:	1a300793          	li	a5,419
    1274:	0097d663          	bge	a5,s1,1280 <main+0x17c>
    1278:	41600b33          	neg	s6,s6
    127c:	1a400493          	li	s1,420
        fill_rect(x, y, BOX_W, BOX_H, PAL8[frame & 7]);
    1280:	007a7713          	andi	a4,s4,7
    1284:	000027b7          	lui	a5,0x2
    1288:	00171713          	slli	a4,a4,0x1
    128c:	b4878793          	addi	a5,a5,-1208 # 1b48 <PAL8>
    1290:	00e787b3          	add	a5,a5,a4
    1294:	0007d703          	lhu	a4,0(a5)
    1298:	07800693          	li	a3,120
    129c:	0a000613          	li	a2,160
    12a0:	00048593          	mv	a1,s1
    12a4:	00040513          	mv	a0,s0
    12a8:	2b4000ef          	jal	155c <fill_rect>
        x2 += dx2; y2 += dy2;
    12ac:	01790933          	add	s2,s2,s7
    12b0:	018989b3          	add	s3,s3,s8
        if (x2 <= 0)                    { x2 = 0;                    dx2 = -dx2; }
    12b4:	f32054e3          	blez	s2,11dc <main+0xd8>
        if (y2 <= 0)                    { y2 = 0;                    dy2 = -dy2; }
    12b8:	f33058e3          	blez	s3,11e8 <main+0xe4>
        if (x2 >= FB_WIDTH  - BOX2_W)   { x2 = FB_WIDTH  - BOX2_W;    dx2 = -dx2; }
    12bc:	36f00793          	li	a5,879
    12c0:	0127d663          	bge	a5,s2,12cc <main+0x1c8>
    12c4:	41700bb3          	neg	s7,s7
    12c8:	37000913          	li	s2,880
        if (y2 >= FB_HEIGHT - BOX2_H)   { y2 = FB_HEIGHT - BOX2_H;    dy2 = -dy2; }
    12cc:	1cb00793          	li	a5,459
    12d0:	f337d2e3          	bge	a5,s3,11f4 <main+0xf0>
    12d4:	41800c33          	neg	s8,s8
    12d8:	1cc00993          	li	s3,460
    12dc:	f19ff06f          	j	11f4 <main+0xf0>

000012e0 <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    12e0:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    12e4:	01055513          	srli	a0,a0,0x10
    }
    12e8:	0ff57513          	zext.b	a0,a0
    12ec:	00008067          	ret

000012f0 <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    12f0:	ff010113          	addi	sp,sp,-16
    12f4:	00112623          	sw	ra,12(sp)
    12f8:	00812423          	sw	s0,8(sp)
    12fc:	00912223          	sw	s1,4(sp)
    1300:	00050413          	mv	s0,a0
    1304:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    1308:	00040513          	mv	a0,s0
    130c:	fd5ff0ef          	jal	12e0 <uart_writeAvailability>
    1310:	fe050ce3          	beqz	a0,1308 <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    1314:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    1318:	00c12083          	lw	ra,12(sp)
    131c:	00812403          	lw	s0,8(sp)
    1320:	00412483          	lw	s1,4(sp)
    1324:	01010113          	addi	sp,sp,16
    1328:	00008067          	ret

0000132c <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    132c:	ff010113          	addi	sp,sp,-16
    1330:	00112623          	sw	ra,12(sp)
    1334:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    1338:	f8010537          	lui	a0,0xf8010
    133c:	fb5ff0ef          	jal	12f0 <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    1340:	00c12083          	lw	ra,12(sp)
    1344:	01010113          	addi	sp,sp,16
    1348:	00008067          	ret

0000134c <_putchar_s>:

    static void _putchar_s(char *p)
    {
    134c:	ff010113          	addi	sp,sp,-16
    1350:	00112623          	sw	ra,12(sp)
    1354:	00812423          	sw	s0,8(sp)
    1358:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    135c:	00c0006f          	j	1368 <_putchar_s+0x1c>
            _putchar(*(p++));
    1360:	00140413          	addi	s0,s0,1
    1364:	fc9ff0ef          	jal	132c <_putchar>
        while (*p)
    1368:	00044503          	lbu	a0,0(s0)
    136c:	fe051ae3          	bnez	a0,1360 <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    1370:	00c12083          	lw	ra,12(sp)
    1374:	00812403          	lw	s0,8(sp)
    1378:	01010113          	addi	sp,sp,16
    137c:	00008067          	ret

00001380 <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    1380:	ff010113          	addi	sp,sp,-16
    1384:	00112623          	sw	ra,12(sp)
    1388:	00812423          	sw	s0,8(sp)
    138c:	00912223          	sw	s1,4(sp)
    1390:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1394:	01c00413          	li	s0,28
    1398:	0240006f          	j	13bc <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    139c:	0084d733          	srl	a4,s1,s0
    13a0:	00f77713          	andi	a4,a4,15
    13a4:	000027b7          	lui	a5,0x2
    13a8:	8f078793          	addi	a5,a5,-1808 # 18f0 <_data>
    13ac:	00e787b3          	add	a5,a5,a4
    13b0:	0007c503          	lbu	a0,0(a5)
    13b4:	f79ff0ef          	jal	132c <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    13b8:	ffc40413          	addi	s0,s0,-4
    13bc:	fe0450e3          	bgez	s0,139c <bsp_printHex+0x1c>
        }
    }
    13c0:	00c12083          	lw	ra,12(sp)
    13c4:	00812403          	lw	s0,8(sp)
    13c8:	00412483          	lw	s1,4(sp)
    13cc:	01010113          	addi	sp,sp,16
    13d0:	00008067          	ret

000013d4 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    13d4:	ff010113          	addi	sp,sp,-16
    13d8:	00112623          	sw	ra,12(sp)
    13dc:	00812423          	sw	s0,8(sp)
    13e0:	00912223          	sw	s1,4(sp)
    13e4:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    13e8:	01c00413          	li	s0,28
    13ec:	0240006f          	j	1410 <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    13f0:	0084d733          	srl	a4,s1,s0
    13f4:	00f77713          	andi	a4,a4,15
    13f8:	000027b7          	lui	a5,0x2
    13fc:	90478793          	addi	a5,a5,-1788 # 1904 <_data+0x14>
    1400:	00e787b3          	add	a5,a5,a4
    1404:	0007c503          	lbu	a0,0(a5)
    1408:	f25ff0ef          	jal	132c <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    140c:	ffc40413          	addi	s0,s0,-4
    1410:	fe0450e3          	bgez	s0,13f0 <bsp_printHex_lower+0x1c>

        }
    }
    1414:	00c12083          	lw	ra,12(sp)
    1418:	00812403          	lw	s0,8(sp)
    141c:	00412483          	lw	s1,4(sp)
    1420:	01010113          	addi	sp,sp,16
    1424:	00008067          	ret

00001428 <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    1428:	ff010113          	addi	sp,sp,-16
    142c:	00112623          	sw	ra,12(sp)
        _putchar(c);
    1430:	0ff57513          	zext.b	a0,a0
    1434:	ef9ff0ef          	jal	132c <_putchar>
    }
    1438:	00c12083          	lw	ra,12(sp)
    143c:	01010113          	addi	sp,sp,16
    1440:	00008067          	ret

00001444 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    1444:	ff010113          	addi	sp,sp,-16
    1448:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    144c:	f01ff0ef          	jal	134c <_putchar_s>
    }
    1450:	00c12083          	lw	ra,12(sp)
    1454:	01010113          	addi	sp,sp,16
    1458:	00008067          	ret

0000145c <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    145c:	fd010113          	addi	sp,sp,-48
    1460:	02112623          	sw	ra,44(sp)
    1464:	02812423          	sw	s0,40(sp)
    1468:	02912223          	sw	s1,36(sp)
    146c:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    1470:	00054663          	bltz	a0,147c <bsp_printf_d+0x20>
    {
    1474:	00010413          	mv	s0,sp
    1478:	02c0006f          	j	14a4 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    147c:	02d00513          	li	a0,45
    1480:	fa9ff0ef          	jal	1428 <bsp_printf_c>
            val = -val;
    1484:	409004b3          	neg	s1,s1
    1488:	fedff06f          	j	1474 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    148c:	00a00713          	li	a4,10
    1490:	02e4e7b3          	rem	a5,s1,a4
    1494:	03078793          	addi	a5,a5,48
    1498:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    149c:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    14a0:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    14a4:	fe0494e3          	bnez	s1,148c <bsp_printf_d+0x30>
    14a8:	00010793          	mv	a5,sp
    14ac:	fef400e3          	beq	s0,a5,148c <bsp_printf_d+0x30>
        }
        while (p != buffer)
    14b0:	00010793          	mv	a5,sp
    14b4:	00f40a63          	beq	s0,a5,14c8 <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    14b8:	fff40413          	addi	s0,s0,-1
    14bc:	00044503          	lbu	a0,0(s0)
    14c0:	f69ff0ef          	jal	1428 <bsp_printf_c>
    14c4:	fedff06f          	j	14b0 <bsp_printf_d+0x54>
    }
    14c8:	02c12083          	lw	ra,44(sp)
    14cc:	02812403          	lw	s0,40(sp)
    14d0:	02412483          	lw	s1,36(sp)
    14d4:	03010113          	addi	sp,sp,48
    14d8:	00008067          	ret

000014dc <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    14dc:	ff010113          	addi	sp,sp,-16
    14e0:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    14e4:	00000713          	li	a4,0
    14e8:	00700793          	li	a5,7
    14ec:	02e7c063          	blt	a5,a4,150c <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    14f0:	00271693          	slli	a3,a4,0x2
    14f4:	ff000793          	li	a5,-16
    14f8:	00d797b3          	sll	a5,a5,a3
    14fc:	00f577b3          	and	a5,a0,a5
    1500:	00078663          	beqz	a5,150c <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    1504:	00170713          	addi	a4,a4,1
    1508:	fe1ff06f          	j	14e8 <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    150c:	ec9ff0ef          	jal	13d4 <bsp_printHex_lower>
    }
    1510:	00c12083          	lw	ra,12(sp)
    1514:	01010113          	addi	sp,sp,16
    1518:	00008067          	ret

0000151c <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    151c:	ff010113          	addi	sp,sp,-16
    1520:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    1524:	00000713          	li	a4,0
    1528:	00700793          	li	a5,7
    152c:	02e7c063          	blt	a5,a4,154c <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1530:	00271693          	slli	a3,a4,0x2
    1534:	ff000793          	li	a5,-16
    1538:	00d797b3          	sll	a5,a5,a3
    153c:	00f577b3          	and	a5,a0,a5
    1540:	00078663          	beqz	a5,154c <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    1544:	00170713          	addi	a4,a4,1
    1548:	fe1ff06f          	j	1528 <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    154c:	e35ff0ef          	jal	1380 <bsp_printHex>
        }
    1550:	00c12083          	lw	ra,12(sp)
    1554:	01010113          	addi	sp,sp,16
    1558:	00008067          	ret

0000155c <fill_rect>:
    uint32_t v = ((uint32_t)color << 16) | (uint32_t)color;
    155c:	01071e93          	slli	t4,a4,0x10
    1560:	00ee8eb3          	add	t4,t4,a4
    if (w <= 0 || h <= 0) return;
    1564:	0ec05463          	blez	a2,164c <fill_rect+0xf0>
    1568:	0ed05263          	blez	a3,164c <fill_rect+0xf0>
    if (x < 0) { w += x; x = 0; }                 /* 裁剪到屏内 */
    156c:	04054063          	bltz	a0,15ac <fill_rect+0x50>
    if (y < 0) { h += y; y = 0; }
    1570:	0405c463          	bltz	a1,15b8 <fill_rect+0x5c>
    if (x + w > FB_WIDTH)  w = FB_WIDTH  - x;
    1574:	00c507b3          	add	a5,a0,a2
    1578:	3c000813          	li	a6,960
    157c:	00f85663          	bge	a6,a5,1588 <fill_rect+0x2c>
    1580:	3c000613          	li	a2,960
    1584:	40a60633          	sub	a2,a2,a0
    if (y + h > FB_HEIGHT) h = FB_HEIGHT - y;
    1588:	00d587b3          	add	a5,a1,a3
    158c:	21c00813          	li	a6,540
    1590:	00f85663          	bge	a6,a5,159c <fill_rect+0x40>
    1594:	21c00693          	li	a3,540
    1598:	40b686b3          	sub	a3,a3,a1
    if (w <= 0 || h <= 0) return;
    159c:	0ac05863          	blez	a2,164c <fill_rect+0xf0>
    15a0:	0ad05663          	blez	a3,164c <fill_rect+0xf0>
    for (j = 0; j < h; j++) {
    15a4:	00000f13          	li	t5,0
    15a8:	06c0006f          	j	1614 <fill_rect+0xb8>
    if (x < 0) { w += x; x = 0; }                 /* 裁剪到屏内 */
    15ac:	00a60633          	add	a2,a2,a0
    15b0:	00000513          	li	a0,0
    15b4:	fbdff06f          	j	1570 <fill_rect+0x14>
    if (y < 0) { h += y; y = 0; }
    15b8:	00b686b3          	add	a3,a3,a1
    15bc:	00000593          	li	a1,0
    15c0:	fb5ff06f          	j	1574 <fill_rect+0x18>
        for (i = 0; i < n; i++) row[i] = v;
    15c4:	00f308b3          	add	a7,t1,a5
    15c8:	00289893          	slli	a7,a7,0x2
    15cc:	00301837          	lui	a6,0x301
    15d0:	01180833          	add	a6,a6,a7
    15d4:	01d82023          	sw	t4,0(a6) # 301000 <__freertos_irq_stack_top+0x2fe480>
    15d8:	00178793          	addi	a5,a5,1
    15dc:	ffc7c4e3          	blt	a5,t3,15c4 <fill_rect+0x68>
        if (w & 1)                                    /* 奇数宽：补最后一个像素 */
    15e0:	00167793          	andi	a5,a2,1
    15e4:	02078663          	beqz	a5,1610 <fill_rect+0xb4>
            FB16[(uint32_t)(y + j) * FB_WIDTH + x + w - 1] = color;
    15e8:	004f9793          	slli	a5,t6,0x4
    15ec:	41f787b3          	sub	a5,a5,t6
    15f0:	00679793          	slli	a5,a5,0x6
    15f4:	00f507b3          	add	a5,a0,a5
    15f8:	00f607b3          	add	a5,a2,a5
    15fc:	00179793          	slli	a5,a5,0x1
    1600:	00301837          	lui	a6,0x301
    1604:	ffe80813          	addi	a6,a6,-2 # 300ffe <__freertos_irq_stack_top+0x2fe47e>
    1608:	010787b3          	add	a5,a5,a6
    160c:	00e79023          	sh	a4,0(a5)
    for (j = 0; j < h; j++) {
    1610:	001f0f13          	addi	t5,t5,1
    1614:	02df5c63          	bge	t5,a3,164c <fill_rect+0xf0>
        volatile uint32_t *row = FB32 + (uint32_t)(y + j) * (FB_WIDTH / 2) + (x / 2);
    1618:	01e58fb3          	add	t6,a1,t5
    161c:	01f55793          	srli	a5,a0,0x1f
    1620:	00a787b3          	add	a5,a5,a0
    1624:	4017d793          	srai	a5,a5,0x1
    1628:	004f9313          	slli	t1,t6,0x4
    162c:	41f30333          	sub	t1,t1,t6
    1630:	00531313          	slli	t1,t1,0x5
    1634:	00f30333          	add	t1,t1,a5
        int n = w / 2;
    1638:	01f65e13          	srli	t3,a2,0x1f
    163c:	00ce0e33          	add	t3,t3,a2
    1640:	401e5e13          	srai	t3,t3,0x1
        for (i = 0; i < n; i++) row[i] = v;
    1644:	00000793          	li	a5,0
    1648:	f95ff06f          	j	15dc <fill_rect+0x80>
}
    164c:	00008067          	ret

00001650 <fill_bg_bars>:
    for (y = 0; y < FB_HEIGHT; y++) {
    1650:	00000813          	li	a6,0
    1654:	0680006f          	j	16bc <fill_bg_bars+0x6c>
                row[b * ((FB_WIDTH / 8) / 2) + k] = v;
    1658:	00461713          	slli	a4,a2,0x4
    165c:	40c70733          	sub	a4,a4,a2
    1660:	00271793          	slli	a5,a4,0x2
    1664:	00d787b3          	add	a5,a5,a3
    1668:	00279793          	slli	a5,a5,0x2
    166c:	00f507b3          	add	a5,a0,a5
    1670:	00301737          	lui	a4,0x301
    1674:	00f707b3          	add	a5,a4,a5
    1678:	00b7a023          	sw	a1,0(a5)
            for (k = 0; k < (FB_WIDTH / 8) / 2; k++)
    167c:	00168693          	addi	a3,a3,1
    1680:	03b00793          	li	a5,59
    1684:	fcd7dae3          	bge	a5,a3,1658 <fill_bg_bars+0x8>
        for (b = 0; b < 8; b++) {
    1688:	00160613          	addi	a2,a2,1 # 401001 <__freertos_irq_stack_top+0x3fe481>
    168c:	00700793          	li	a5,7
    1690:	02c7c463          	blt	a5,a2,16b8 <fill_bg_bars+0x68>
            uint32_t v = ((uint32_t)BARS[b] << 16) | (uint32_t)BARS[b];
    1694:	000027b7          	lui	a5,0x2
    1698:	00161713          	slli	a4,a2,0x1
    169c:	b5878793          	addi	a5,a5,-1192 # 1b58 <BARS>
    16a0:	00e787b3          	add	a5,a5,a4
    16a4:	0007d783          	lhu	a5,0(a5)
    16a8:	01079593          	slli	a1,a5,0x10
    16ac:	00f585b3          	add	a1,a1,a5
            for (k = 0; k < (FB_WIDTH / 8) / 2; k++)
    16b0:	00000693          	li	a3,0
    16b4:	fcdff06f          	j	1680 <fill_bg_bars+0x30>
    for (y = 0; y < FB_HEIGHT; y++) {
    16b8:	00180813          	addi	a6,a6,1
    16bc:	21b00793          	li	a5,539
    16c0:	0107cc63          	blt	a5,a6,16d8 <fill_bg_bars+0x88>
        volatile uint32_t *row = FB32 + (uint32_t)y * (FB_WIDTH / 2);
    16c4:	00481793          	slli	a5,a6,0x4
    16c8:	410787b3          	sub	a5,a5,a6
    16cc:	00779513          	slli	a0,a5,0x7
        for (b = 0; b < 8; b++) {
    16d0:	00000613          	li	a2,0
    16d4:	fb9ff06f          	j	168c <fill_bg_bars+0x3c>
}
    16d8:	00008067          	ret

000016dc <cache_evict>:
    for (i = 0; i < FLUSH_WORDS; i++)
    16dc:	00000793          	li	a5,0
    16e0:	0200006f          	j	1700 <cache_evict+0x24>
        scratch[i] = 0xA5A50000UL + i;
    16e4:	00279693          	slli	a3,a5,0x2
    16e8:	00501737          	lui	a4,0x501
    16ec:	00d70733          	add	a4,a4,a3
    16f0:	a5a506b7          	lui	a3,0xa5a50
    16f4:	00d786b3          	add	a3,a5,a3
    16f8:	00d72023          	sw	a3,0(a4) # 501000 <__freertos_irq_stack_top+0x4fe480>
    for (i = 0; i < FLUSH_WORDS; i++)
    16fc:	00178793          	addi	a5,a5,1
    1700:	7ff00713          	li	a4,2047
    1704:	fef770e3          	bgeu	a4,a5,16e4 <cache_evict+0x8>
}
    1708:	00008067          	ret

0000170c <coherency_check>:
{
    170c:	ff010113          	addi	sp,sp,-16
    1710:	00112623          	sw	ra,12(sp)
    for (i = 0; i < 256; i++) p[i] = 0x5A5A0000UL + i;
    1714:	00000793          	li	a5,0
    1718:	0200006f          	j	1738 <coherency_check+0x2c>
    171c:	00279693          	slli	a3,a5,0x2
    1720:	00401737          	lui	a4,0x401
    1724:	00d70733          	add	a4,a4,a3
    1728:	5a5a06b7          	lui	a3,0x5a5a0
    172c:	00d786b3          	add	a3,a5,a3
    1730:	00d72023          	sw	a3,0(a4) # 401000 <__freertos_irq_stack_top+0x3fe480>
    1734:	00178793          	addi	a5,a5,1
    1738:	0ff00713          	li	a4,255
    173c:	fef770e3          	bgeu	a4,a5,171c <coherency_check+0x10>
    cache_evict();
    1740:	f9dff0ef          	jal	16dc <cache_evict>
    1744:	0000500f          	.word	0x0000500f
    for (i = 0; i < 256; i++)
    1748:	00000793          	li	a5,0
    174c:	0ff00713          	li	a4,255
    1750:	02f76463          	bltu	a4,a5,1778 <coherency_check+0x6c>
        if (p[i] != (0x5A5A0000UL + i)) return 0;
    1754:	00279693          	slli	a3,a5,0x2
    1758:	00401737          	lui	a4,0x401
    175c:	00d70733          	add	a4,a4,a3
    1760:	00072683          	lw	a3,0(a4) # 401000 <__freertos_irq_stack_top+0x3fe480>
    1764:	5a5a0737          	lui	a4,0x5a5a0
    1768:	00e78733          	add	a4,a5,a4
    176c:	00e69a63          	bne	a3,a4,1780 <coherency_check+0x74>
    for (i = 0; i < 256; i++)
    1770:	00178793          	addi	a5,a5,1
    1774:	fd9ff06f          	j	174c <coherency_check+0x40>
    return 1;
    1778:	00100513          	li	a0,1
    177c:	0080006f          	j	1784 <coherency_check+0x78>
        if (p[i] != (0x5A5A0000UL + i)) return 0;
    1780:	00000513          	li	a0,0
}
    1784:	00c12083          	lw	ra,12(sp)
    1788:	01010113          	addi	sp,sp,16
    178c:	00008067          	ret

00001790 <frame_delay>:
{
    1790:	ff010113          	addi	sp,sp,-16
    for (i = 0; i < FRAME_DELAY_LOOPS; i++) { }
    1794:	00012623          	sw	zero,12(sp)
    1798:	0100006f          	j	17a8 <frame_delay+0x18>
    179c:	00c12783          	lw	a5,12(sp)
    17a0:	00178793          	addi	a5,a5,1
    17a4:	00f12623          	sw	a5,12(sp)
    17a8:	00c12703          	lw	a4,12(sp)
    17ac:	0002c7b7          	lui	a5,0x2c
    17b0:	f1f78793          	addi	a5,a5,-225 # 2bf1f <__freertos_irq_stack_top+0x2939f>
    17b4:	fee7f4e3          	bgeu	a5,a4,179c <frame_delay+0xc>
}
    17b8:	01010113          	addi	sp,sp,16
    17bc:	00008067          	ret

000017c0 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    17c0:	fc010113          	addi	sp,sp,-64
    17c4:	00112e23          	sw	ra,28(sp)
    17c8:	00812c23          	sw	s0,24(sp)
    17cc:	00912a23          	sw	s1,20(sp)
    17d0:	00050493          	mv	s1,a0
    17d4:	02b12223          	sw	a1,36(sp)
    17d8:	02c12423          	sw	a2,40(sp)
    17dc:	02d12623          	sw	a3,44(sp)
    17e0:	02e12823          	sw	a4,48(sp)
    17e4:	02f12a23          	sw	a5,52(sp)
    17e8:	03012c23          	sw	a6,56(sp)
    17ec:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    17f0:	02410793          	addi	a5,sp,36
    17f4:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    17f8:	00000413          	li	s0,0
    17fc:	01c0006f          	j	1818 <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    1800:	00c12783          	lw	a5,12(sp)
    1804:	00478713          	addi	a4,a5,4
    1808:	00e12623          	sw	a4,12(sp)
    180c:	0007a503          	lw	a0,0(a5)
    1810:	c19ff0ef          	jal	1428 <bsp_printf_c>
        for (i = 0; format[i]; i++)
    1814:	00140413          	addi	s0,s0,1
    1818:	008487b3          	add	a5,s1,s0
    181c:	0007c503          	lbu	a0,0(a5)
    1820:	0a050e63          	beqz	a0,18dc <bsp_printf+0x11c>
            if (format[i] == '%') {
    1824:	02500793          	li	a5,37
    1828:	06f50e63          	beq	a0,a5,18a4 <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    182c:	bfdff0ef          	jal	1428 <bsp_printf_c>
    1830:	fe5ff06f          	j	1814 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    1834:	00c12783          	lw	a5,12(sp)
    1838:	00478713          	addi	a4,a5,4
    183c:	00e12623          	sw	a4,12(sp)
    1840:	0007a503          	lw	a0,0(a5)
    1844:	c01ff0ef          	jal	1444 <bsp_printf_s>
                        break;
    1848:	fcdff06f          	j	1814 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    184c:	00c12783          	lw	a5,12(sp)
    1850:	00478713          	addi	a4,a5,4
    1854:	00e12623          	sw	a4,12(sp)
    1858:	0007a503          	lw	a0,0(a5)
    185c:	c01ff0ef          	jal	145c <bsp_printf_d>
                        break;
    1860:	fb5ff06f          	j	1814 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    1864:	00c12783          	lw	a5,12(sp)
    1868:	00478713          	addi	a4,a5,4
    186c:	00e12623          	sw	a4,12(sp)
    1870:	0007a503          	lw	a0,0(a5)
    1874:	ca9ff0ef          	jal	151c <bsp_printf_X>
                        break;
    1878:	f9dff06f          	j	1814 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    187c:	00c12783          	lw	a5,12(sp)
    1880:	00478713          	addi	a4,a5,4
    1884:	00e12623          	sw	a4,12(sp)
    1888:	0007a503          	lw	a0,0(a5)
    188c:	c51ff0ef          	jal	14dc <bsp_printf_x>
                        break;
    1890:	f85ff06f          	j	1814 <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    1894:	00002537          	lui	a0,0x2
    1898:	91850513          	addi	a0,a0,-1768 # 1918 <_data+0x28>
    189c:	ba9ff0ef          	jal	1444 <bsp_printf_s>
                        break;
    18a0:	f75ff06f          	j	1814 <bsp_printf+0x54>
                while (format[++i]) {
    18a4:	00140413          	addi	s0,s0,1
    18a8:	008487b3          	add	a5,s1,s0
    18ac:	0007c783          	lbu	a5,0(a5)
    18b0:	f60782e3          	beqz	a5,1814 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    18b4:	fa878793          	addi	a5,a5,-88
    18b8:	0ff7f693          	zext.b	a3,a5
    18bc:	02000713          	li	a4,32
    18c0:	fed762e3          	bltu	a4,a3,18a4 <bsp_printf+0xe4>
    18c4:	00269793          	slli	a5,a3,0x2
    18c8:	00002737          	lui	a4,0x2
    18cc:	ac470713          	addi	a4,a4,-1340 # 1ac4 <_data+0x1d4>
    18d0:	00e787b3          	add	a5,a5,a4
    18d4:	0007a783          	lw	a5,0(a5)
    18d8:	00078067          	jr	a5

        va_end(ap);
    }
    18dc:	01c12083          	lw	ra,28(sp)
    18e0:	01812403          	lw	s0,24(sp)
    18e4:	01412483          	lw	s1,20(sp)
    18e8:	04010113          	addi	sp,sp,64
    18ec:	00008067          	ret
