
build/comptest.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00003197          	auipc	gp,0x3
    1004:	eb018193          	addi	gp,gp,-336 # 3eb0 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00007117          	auipc	sp,0x7
    100c:	8d810113          	addi	sp,sp,-1832 # 78e0 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00002517          	auipc	a0,0x2
    1014:	05c50513          	addi	a0,a0,92 # 306c <_data>
	la a1, _data
    1018:	00002597          	auipc	a1,0x2
    101c:	05458593          	addi	a1,a1,84 # 306c <_data>
	la a2, _edata
    1020:	00002617          	auipc	a2,0x2
    1024:	6bc60613          	addi	a2,a2,1724 # 36dc <g_key_cnt>
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
    1040:	00002517          	auipc	a0,0x2
    1044:	69c50513          	addi	a0,a0,1692 # 36dc <g_key_cnt>
	la a1, _end
    1048:	00006597          	auipc	a1,0x6
    104c:	89858593          	addi	a1,a1,-1896 # 68e0 <_end>
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
    107c:	00002797          	auipc	a5,0x2
    1080:	ff078793          	addi	a5,a5,-16 # 306c <_data>
    1084:	00002417          	auipc	s0,0x2
    1088:	fe840413          	addi	s0,s0,-24 # 306c <_data>
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
    10b8:	00002797          	auipc	a5,0x2
    10bc:	fb478793          	addi	a5,a5,-76 # 306c <_data>
    10c0:	00002417          	auipc	s0,0x2
    10c4:	fac40413          	addi	s0,s0,-84 # 306c <_data>
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
#define BS_RENDERING 1
#define BS_READY     2
#define BS_COPYING   3

int main(int argc, char **argv)
{
    1104:	f7010113          	addi	sp,sp,-144
    1108:	08112623          	sw	ra,140(sp)
    110c:	08812423          	sw	s0,136(sp)
    1110:	08912223          	sw	s1,132(sp)
    1114:	09212023          	sw	s2,128(sp)
    1118:	07312e23          	sw	s3,124(sp)
    111c:	07412c23          	sw	s4,120(sp)
    1120:	07512a23          	sw	s5,116(sp)
    1124:	07612823          	sw	s6,112(sp)
    1128:	07712623          	sw	s7,108(sp)
    112c:	07812423          	sw	s8,104(sp)
    1130:	07912223          	sw	s9,100(sp)
    1134:	07a12023          	sw	s10,96(sp)
    1138:	05b12e23          	sw	s11,92(sp)
    int      hw_frame_pushed = 0;   /* 本帧指令是否已全部下发（硬件模式"一帧一帧推"用） */
    int      osd_dirty       = 0;   /* 状态条已改、待搬到显示缓冲（在帧边界搬） */
    /* ★ 重铺标记：场景一变（N 加减 / 复位 / 切模式）就要把背景重铺一遍。
     *   不重铺的话，旧物块留在缓冲里的像素没有任何人负责擦掉，只有等某个新物块
     *   碰巧经过才被盖住 —— 就是"加减物块后旧物块要等接触才刷新"那个现象。 */
    int      repaint[2]      = { 0, 0 };
    113c:	02012823          	sw	zero,48(sp)
    1140:	02012a23          	sw	zero,52(sp)
    uint32_t osd_evt = 0;

    (void)argc; (void)argv;

    /* ★ 必须最先调用：bsp_init() 里才配置 UART 时钟分频 */
    bsp_init();
    1144:	595000ef          	jal	1ed8 <bsp_init>

    bsp_printf("\r\n===== comptest: CPU software render vs BitBlt HW accel =====\r\n");
    1148:	00003537          	lui	a0,0x3
    114c:	10850513          	addi	a0,a0,264 # 3108 <_data+0x9c>
    1150:	13d010ef          	jal	2a8c <bsp_printf>
    bsp_printf("FB=%x FB1=%x FB2=%x N=%d-%d step %d\r\n",
    1154:	01900813          	li	a6,25
    1158:	19000793          	li	a5,400
    115c:	01900713          	li	a4,25
    1160:	005016b7          	lui	a3,0x501
    1164:	00401637          	lui	a2,0x401
    1168:	003015b7          	lui	a1,0x301
    116c:	00003537          	lui	a0,0x3
    1170:	14c50513          	addi	a0,a0,332 # 314c <_data+0xe0>
    1174:	119010ef          	jal	2a8c <bsp_printf>
               (unsigned)FB_BASE, (unsigned)FB1_BASE, (unsigned)FB2_BASE,
               N_MIN, N_MAX, N_STEP);
    bsp_printf("keys: GPIOR_22=mode  GPIOR_21=N+25  GPIOL_03=reset\r\n");
    1178:	00003537          	lui	a0,0x3
    117c:	17450513          	addi	a0,a0,372 # 3174 <_data+0x108>
    1180:	10d010ef          	jal	2a8c <bsp_printf>
    bsp_printf("uart: m=mode  n or +=N+25  -=N-25  r=reset\r\n");
    1184:	00003537          	lui	a0,0x3
    1188:	1ac50513          	addi	a0,a0,428 # 31ac <_data+0x140>
    118c:	101010ef          	jal	2a8c <bsp_printf>
    bsp_printf("ver: CPU renders to off-screen buf, engine copies to display\r\n");
    1190:	00003537          	lui	a0,0x3
    1194:	1dc50513          	addi	a0,a0,476 # 31dc <_data+0x170>
    1198:	0f5010ef          	jal	2a8c <bsp_printf>

    blt_init();
    119c:	72d000ef          	jal	20c8 <blt_init>

    /* ★ 只给**屏外缓冲**铺底。显示缓冲 FB_BASE 一个字节都不由 CPU 写 ——
     *   它的内容全部来自引擎（开机第一条整屏 COPY 就会铺满它，不需要单独清屏）。 */
    cpu_fill32(FB1_BASE, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    11a0:	00800793          	li	a5,8
    11a4:	21c00713          	li	a4,540
    11a8:	3c000693          	li	a3,960
    11ac:	00000613          	li	a2,0
    11b0:	00000593          	li	a1,0
    11b4:	00401537          	lui	a0,0x401
    11b8:	070010ef          	jal	2228 <cpu_fill32>
    cpu_fill32(FB2_BASE, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    11bc:	00800793          	li	a5,8
    11c0:	21c00713          	li	a4,540
    11c4:	3c000693          	li	a3,960
    11c8:	00000613          	li	a2,0
    11cc:	00000593          	li	a1,0
    11d0:	00501537          	lui	a0,0x501
    11d4:	054010ef          	jal	2228 <cpu_fill32>
    cache_evict();
    11d8:	575000ef          	jal	1f4c <cache_evict>

    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x UST=%x URO=%d KEY=%x\r\n",
               (unsigned)blt_stat(), (unsigned)blt_cnt(),
    11dc:	691000ef          	jal	206c <blt_stat>
    11e0:	00050413          	mv	s0,a0
    11e4:	66d000ef          	jal	2050 <blt_cnt>
    11e8:	00050493          	mv	s1,a0
               (unsigned)blt_rd(0x20),
    11ec:	02000513          	li	a0,32
    11f0:	54d000ef          	jal	1f3c <blt_rd>
    11f4:	00050913          	mv	s2,a0
               (unsigned)uart_status_raw(), (int)uart_rx_occ(), (unsigned)gpio_read_keys());
    11f8:	5b4010ef          	jal	27ac <uart_status_raw>
    11fc:	00050993          	mv	s3,a0
    1200:	5b8010ef          	jal	27b8 <uart_rx_occ>
    1204:	00050a13          	mv	s4,a0
    1208:	4e8010ef          	jal	26f0 <gpio_read_keys>
    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x UST=%x URO=%d KEY=%x\r\n",
    120c:	00050813          	mv	a6,a0
    1210:	000a0793          	mv	a5,s4
    1214:	00098713          	mv	a4,s3
    1218:	00090693          	mv	a3,s2
    121c:	00048613          	mv	a2,s1
    1220:	00040593          	mv	a1,s0
    1224:	00003537          	lui	a0,0x3
    1228:	21c50513          	addi	a0,a0,540 # 321c <_data+0x1b0>
    122c:	061010ef          	jal	2a8c <bsp_printf>

    /* ================= ★ 未对齐写入自检（这次卡死的根因就是它） =================
     * 在**奇数 x** 处画一小块再读回：若 cpu_fill32 对奇数 x 仍做 32bit 未对齐存储，
     * CPU 会在这里就静默停死、下面这行 "aligncheck" 永远打不出来。
     * 打出来且值正确（f800）就说明这条路径安全了。 */
    cpu_fill32(FB1_BASE, 33, 300, 8, 2, 0xF800u);
    1230:	000107b7          	lui	a5,0x10
    1234:	80078793          	addi	a5,a5,-2048 # f800 <__freertos_irq_stack_top+0x7f20>
    1238:	00200713          	li	a4,2
    123c:	00800693          	li	a3,8
    1240:	12c00613          	li	a2,300
    1244:	02100593          	li	a1,33
    1248:	00401537          	lui	a0,0x401
    124c:	7dd000ef          	jal	2228 <cpu_fill32>
    cpu_fill32(FB1_BASE, 32, 302, 9, 2, 0x07E0u);      /* 偶数 x + 奇数宽度 */
    1250:	7e000793          	li	a5,2016
    1254:	00200713          	li	a4,2
    1258:	00900693          	li	a3,9
    125c:	12e00613          	li	a2,302
    1260:	02000593          	li	a1,32
    1264:	00401537          	lui	a0,0x401
    1268:	7c1000ef          	jal	2228 <cpu_fill32>
    {
        unsigned v1 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 300u * FB_STRIDE + 33u * 2u));
    126c:	0048e7b7          	lui	a5,0x48e
    1270:	a427d583          	lhu	a1,-1470(a5) # 48da42 <__freertos_irq_stack_top+0x486162>
        unsigned v2 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 300u * FB_STRIDE + 40u * 2u));
    1274:	0048e7b7          	lui	a5,0x48e
    1278:	a507d603          	lhu	a2,-1456(a5) # 48da50 <__freertos_irq_stack_top+0x486170>
        unsigned v3 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 302u * FB_STRIDE + 32u * 2u));
    127c:	0048f7b7          	lui	a5,0x48f
    1280:	9407d683          	lhu	a3,-1728(a5) # 48e940 <__freertos_irq_stack_top+0x487060>
        unsigned v4 = (unsigned)(*(volatile uint16_t *)(FB1_BASE + 302u * FB_STRIDE + 40u * 2u));
    1284:	0048f7b7          	lui	a5,0x48f
    1288:	9507d703          	lhu	a4,-1712(a5) # 48e950 <__freertos_irq_stack_top+0x487070>
        bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
    128c:	00003537          	lui	a0,0x3
    1290:	25c50513          	addi	a0,a0,604 # 325c <_data+0x1f0>
    1294:	7f8010ef          	jal	2a8c <bsp_printf>
                   v1, v2, v3, v4);
    }

    scene_init(n, g_seed);
    1298:	123455b7          	lui	a1,0x12345
    129c:	67858593          	addi	a1,a1,1656 # 12345678 <__freertos_irq_stack_top+0x1233dd98>
    12a0:	01900513          	li	a0,25
    12a4:	1a4010ef          	jal	2448 <scene_init>
    rg.x0 = 0; rg.y0 = 0; rg.w = FB_WIDTH; rg.h = FB_HEIGHT;
    12a8:	04012023          	sw	zero,64(sp)
    12ac:	04012223          	sw	zero,68(sp)
    12b0:	3c000793          	li	a5,960
    12b4:	04f12423          	sw	a5,72(sp)
    12b8:	21c00793          	li	a5,540
    12bc:	04f12623          	sw	a5,76(sp)
     *   · 预热后能持续跑 → 证实卡死是"冷读拿不到 DDR 读通道"；
     *   · 预热后仍同样卡死 → 与读无关，得往写通路/别处查。
     * 预热要在**开机写清屏之后**做（那时 DDR 已经挨过最大的一波写，通道还正常）。 */
    {
        int wk;
        for (wk = 0; wk < 8; wk++)                       /* g_sc 两份场景数据 + scene_step 代码 */
    12c0:	00000413          	li	s0,0
    12c4:	01c0006f          	j	12e0 <main+0x1dc>
            scene_step((wk & 1) ? g_sc[1] : g_sc[0], n, &rg);
    12c8:	00003537          	lui	a0,0x3
    12cc:	6e050513          	addi	a0,a0,1760 # 36e0 <g_sc>
    12d0:	04010613          	addi	a2,sp,64
    12d4:	01900593          	li	a1,25
    12d8:	340010ef          	jal	2618 <scene_step>
        for (wk = 0; wk < 8; wk++)                       /* g_sc 两份场景数据 + scene_step 代码 */
    12dc:	00140413          	addi	s0,s0,1
    12e0:	00700793          	li	a5,7
    12e4:	0087cc63          	blt	a5,s0,12fc <main+0x1f8>
            scene_step((wk & 1) ? g_sc[1] : g_sc[0], n, &rg);
    12e8:	00147793          	andi	a5,s0,1
    12ec:	fc078ee3          	beqz	a5,12c8 <main+0x1c4>
    12f0:	00005537          	lui	a0,0x5
    12f4:	fe050513          	addi	a0,a0,-32 # 4fe0 <__global_pointer$+0x1130>
    12f8:	fd9ff06f          	j	12d0 <main+0x1cc>
        for (wk = 0; wk < 3; wk++) {                     /* fill / OSD / 字模 / .rodata 字符串 */
    12fc:	00000413          	li	s0,0
    1300:	0400006f          	j	1340 <main+0x23c>
            cpu_fill32(FB1_BASE, 0, 0, FB_WIDTH, OSD_H, COL_OSD_BG);
    1304:	00000793          	li	a5,0
    1308:	01000713          	li	a4,16
    130c:	3c000693          	li	a3,960
    1310:	00000613          	li	a2,0
    1314:	00000593          	li	a1,0
    1318:	00401537          	lui	a0,0x401
    131c:	70d000ef          	jal	2228 <cpu_fill32>
            draw_osd(FB1_BASE, mode, n, 0, 0, 0);
    1320:	00000793          	li	a5,0
    1324:	00000713          	li	a4,0
    1328:	00000693          	li	a3,0
    132c:	01900613          	li	a2,25
    1330:	00000593          	li	a1,0
    1334:	00401537          	lui	a0,0x401
    1338:	634010ef          	jal	296c <draw_osd>
        for (wk = 0; wk < 3; wk++) {                     /* fill / OSD / 字模 / .rodata 字符串 */
    133c:	00140413          	addi	s0,s0,1
    1340:	00200793          	li	a5,2
    1344:	fc87d0e3          	bge	a5,s0,1304 <main+0x200>
        }
        for (wk = 0; wk < 64; wk++) {                    /* 输入轮询路径（GPIO/UART 状态读） */
    1348:	00000413          	li	s0,0
    134c:	0100006f          	j	135c <main+0x258>
            (void)gpio_read_keys();
    1350:	3a0010ef          	jal	26f0 <gpio_read_keys>
            (void)uart_poll_char();
    1354:	480010ef          	jal	27d4 <uart_poll_char>
        for (wk = 0; wk < 64; wk++) {                    /* 输入轮询路径（GPIO/UART 状态读） */
    1358:	00140413          	addi	s0,s0,1
    135c:	03f00793          	li	a5,63
    1360:	fe87d8e3          	bge	a5,s0,1350 <main+0x24c>
        }
        /* 打印路径：把 S/D 两条格式串连同 %d/%x 的转换代码都过一遍 */
        bsp_printf("warmup %d %d %d %d %d %d %x %x\r\n",
    1364:	00012023          	sw	zero,0(sp)
    1368:	00000893          	li	a7,0
    136c:	00000813          	li	a6,0
    1370:	00000793          	li	a5,0
    1374:	00000713          	li	a4,0
    1378:	00000693          	li	a3,0
    137c:	00000613          	li	a2,0
    1380:	00000593          	li	a1,0
    1384:	00003537          	lui	a0,0x3
    1388:	29450513          	addi	a0,a0,660 # 3294 <_data+0x228>
    138c:	700010ef          	jal	2a8c <bsp_printf>
                   0, 0, 0, 0, 0, 0, 0u, 0u);
        /* 引擎收尾路径：等它做完（有界等待），把 blt_idle/blt_can_push 也跑热 */
        {
            uint32_t wt = (uint32_t)tick();
    1390:	381000ef          	jal	1f10 <tick>
    1394:	00050413          	mv	s0,a0
            while (!blt_idle() && ((uint32_t)(tick() - wt) < (uint32_t)(BSP_CLINT_HZ / 4u))) { }
    1398:	4f1000ef          	jal	2088 <blt_idle>
    139c:	00051c63          	bnez	a0,13b4 <main+0x2b0>
    13a0:	371000ef          	jal	1f10 <tick>
    13a4:	40850533          	sub	a0,a0,s0
    13a8:	017d87b7          	lui	a5,0x17d8
    13ac:	83f78793          	addi	a5,a5,-1985 # 17d783f <__freertos_irq_stack_top+0x17cff5f>
    13b0:	fea7f4e3          	bgeu	a5,a0,1398 <main+0x294>
        }
        bsp_printf("warmup done\r\n");
    13b4:	00003537          	lui	a0,0x3
    13b8:	2b850513          	addi	a0,a0,696 # 32b8 <_data+0x24c>
    13bc:	6d0010ef          	jal	2a8c <bsp_printf>
    }

    bs[0] = BS_FREE; bs[1] = BS_FREE;
    13c0:	02012c23          	sw	zero,56(sp)
    13c4:	02012e23          	sw	zero,60(sp)
    g_key_stable = gpio_read_keys();   /* 上电时按键未按（高）当基准 */
    13c8:	328010ef          	jal	26f0 <gpio_read_keys>
    13cc:	80a1aa23          	sw	a0,-2028(gp) # 36c4 <g_key_stable>
    g_key_prev   = g_key_stable;
    13d0:	80a1a823          	sw	a0,-2032(gp) # 36c0 <g_key_prev>

    t0 = (uint32_t)tick();
    13d4:	33d000ef          	jal	1f10 <tick>
    13d8:	00050c13          	mv	s8,a0
    13dc:	02a12623          	sw	a0,44(sp)
    t_osd = t0;

    draw_osd(FB1_BASE, mode, n, 0, 0, 0);
    13e0:	00000793          	li	a5,0
    13e4:	00000713          	li	a4,0
    13e8:	00000693          	li	a3,0
    13ec:	01900613          	li	a2,25
    13f0:	00000593          	li	a1,0
    13f4:	00401537          	lui	a0,0x401
    13f8:	574010ef          	jal	296c <draw_osd>
    draw_osd(FB2_BASE, mode, n, 0, 0, 0);   /* ★ 两块屏外缓冲都要有状态条，
    13fc:	00000793          	li	a5,0
    1400:	00000713          	li	a4,0
    1404:	00000693          	li	a3,0
    1408:	01900613          	li	a2,25
    140c:	00000593          	li	a1,0
    1410:	00501537          	lui	a0,0x501
    1414:	558010ef          	jal	296c <draw_osd>
                                             *   否则双缓冲交替上屏时 OSD 会来回闪 */
    cache_evict();                     /* 保证上面这些 CPU 写对引擎可见（写穿 + 有序屏障） */
    1418:	335000ef          	jal	1f4c <cache_evict>
    /* 让显示缓冲先显示一块已铺底 + 带状态条的图，避免开机黑屏 */
    blt_copy_full(FB1_BASE, FB_BASE);  bs[0] = BS_COPYING; copying = 0;
    141c:	003015b7          	lui	a1,0x301
    1420:	00401537          	lui	a0,0x401
    1424:	4e9000ef          	jal	210c <blt_copy_full>
    1428:	00300793          	li	a5,3
    142c:	02f12c23          	sw	a5,56(sp)
    uint32_t osd_evt = 0;
    1430:	00012a23          	sw	zero,20(sp)
    int      hw_repaint      = 0;
    1434:	02012023          	sw	zero,32(sp)
    int      osd_dirty       = 0;   /* 状态条已改、待搬到显示缓冲（在帧边界搬） */
    1438:	02012423          	sw	zero,40(sp)
    int      hw_frame_pushed = 0;   /* 本帧指令是否已全部下发（硬件模式"一帧一帧推"用） */
    143c:	00012823          	sw	zero,16(sp)
    int      hw_i = 0, hw_half = 0;
    1440:	00000493          	li	s1,0
    1444:	00000413          	li	s0,0
    uint32_t hw_frames     = 0;
    1448:	02012223          	sw	zero,36(sp)
    uint32_t scr_frames    = 0;       /* 引擎搬上屏的帧数 */
    144c:	00012e23          	sw	zero,28(sp)
    uint32_t render_frames = 0;       /* CPU 画完的帧数（纯渲染口径） */
    1450:	00000a13          	li	s4,0
    int      cpu_i     = 0;
    1454:	00000b13          	li	s6,0
    blt_copy_full(FB1_BASE, FB_BASE);  bs[0] = BS_COPYING; copying = 0;
    1458:	00000c93          	li	s9,0
    int      rendering = -1;          /* 正在被 CPU 渲染的缓冲下标，-1 = 无 */
    145c:	fff00a93          	li	s5,-1
    uint32_t it = 0, it_prev = 0;
    1460:	00000d93          	li	s11,0
    1464:	00000993          	li	s3,0
    int      n = 25;
    1468:	01900913          	li	s2,25
    int      mode = MODE_CPU;
    146c:	00000b93          	li	s7,0
    1470:	3a80006f          	j	1818 <main+0x714>
         * 它能回答一个关键问题：**CPU 还活着吗？卡在读还是卡在别处？**
         *   · 红条在跳 → CPU 仍在执行、仍能 store（说明卡的不是写通路）；
         *   · 红条不动而串口也没了 → CPU 真的停了（多半卡在某次访问上）。
         * 这段只用常量与寄存器算地址，代码也是刚预热过的，不会引入新的冷读。 */
        if ((it & 4095u) == 0u) {
            cpu_fill32(g_buf[0], 0, OSD_H + 2, 128, 8, COL_BG);
    1474:	00800793          	li	a5,8
    1478:	00800713          	li	a4,8
    147c:	08000693          	li	a3,128
    1480:	01200613          	li	a2,18
    1484:	00000593          	li	a1,0
    1488:	00401537          	lui	a0,0x401
    148c:	59d000ef          	jal	2228 <cpu_fill32>
            cpu_fill32(g_buf[0], (int)((it >> 12) & 1u) * 64, OSD_H + 2, 64, 8, 0xF800u);
    1490:	00c9d593          	srli	a1,s3,0xc
    1494:	0015f593          	andi	a1,a1,1
    1498:	000107b7          	lui	a5,0x10
    149c:	80078793          	addi	a5,a5,-2048 # f800 <__freertos_irq_stack_top+0x7f20>
    14a0:	00800713          	li	a4,8
    14a4:	04000693          	li	a3,64
    14a8:	01200613          	li	a2,18
    14ac:	00659593          	slli	a1,a1,0x6
    14b0:	00401537          	lui	a0,0x401
    14b4:	575000ef          	jal	2228 <cpu_fill32>
    14b8:	37c0006f          	j	1834 <main+0x730>
        }

        if (ev == EV_MODE) {
            mode = (mode == MODE_CPU) ? MODE_HW : MODE_CPU;
    14bc:	001bcb93          	xori	s7,s7,1
            hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
            repaint[0] = repaint[1] = 1; hw_repaint = 1;   /* 两种模式的画面互相残留，重铺 */
    14c0:	02f12a23          	sw	a5,52(sp)
    14c4:	02f12823          	sw	a5,48(sp)
            bsp_printf("\r\nEV mode -> %d (0=CPU 1=HW)\r\n", mode);
    14c8:	000b8593          	mv	a1,s7
    14cc:	00003537          	lui	a0,0x3
    14d0:	2c850513          	addi	a0,a0,712 # 32c8 <_data+0x25c>
    14d4:	5b8010ef          	jal	2a8c <bsp_printf>
            repaint[0] = repaint[1] = 1; hw_repaint = 1;   /* 两种模式的画面互相残留，重铺 */
    14d8:	03a12023          	sw	s10,32(sp)
            hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
    14dc:	00012823          	sw	zero,16(sp)
    14e0:	00000493          	li	s1,0
    14e4:	00000413          	li	s0,0
    14e8:	3540006f          	j	183c <main+0x738>
        }
        if (ev == EV_N_INC) {
            n += N_STEP; if (n > N_MAX) n = N_MIN;
    14ec:	01990913          	addi	s2,s2,25
    14f0:	19000793          	li	a5,400
    14f4:	0127d463          	bge	a5,s2,14fc <main+0x3f8>
    14f8:	01900913          	li	s2,25
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
    14fc:	123455b7          	lui	a1,0x12345
    1500:	67858593          	addi	a1,a1,1656 # 12345678 <__freertos_irq_stack_top+0x1233dd98>
    1504:	00090513          	mv	a0,s2
    1508:	741000ef          	jal	2448 <scene_init>
            repaint[0] = repaint[1] = 1; hw_repaint = 1;
    150c:	00100793          	li	a5,1
    1510:	02f12a23          	sw	a5,52(sp)
    1514:	02f12823          	sw	a5,48(sp)
    1518:	02f12023          	sw	a5,32(sp)
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
    151c:	00012823          	sw	zero,16(sp)
    1520:	00000493          	li	s1,0
    1524:	00000413          	li	s0,0
    1528:	00000b13          	li	s6,0
    152c:	3180006f          	j	1844 <main+0x740>
        }
        if (ev == EV_N_DEC) {
            n -= N_STEP; if (n < N_MIN) n = N_MAX;
    1530:	fe790913          	addi	s2,s2,-25
    1534:	01800793          	li	a5,24
    1538:	0127c463          	blt	a5,s2,1540 <main+0x43c>
    153c:	19000913          	li	s2,400
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
    1540:	123455b7          	lui	a1,0x12345
    1544:	67858593          	addi	a1,a1,1656 # 12345678 <__freertos_irq_stack_top+0x1233dd98>
    1548:	00090513          	mv	a0,s2
    154c:	6fd000ef          	jal	2448 <scene_init>
            repaint[0] = repaint[1] = 1; hw_repaint = 1;
    1550:	00100793          	li	a5,1
    1554:	02f12a23          	sw	a5,52(sp)
    1558:	02f12823          	sw	a5,48(sp)
    155c:	02f12023          	sw	a5,32(sp)
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
    1560:	00012823          	sw	zero,16(sp)
    1564:	00000493          	li	s1,0
    1568:	00000413          	li	s0,0
    156c:	00000b13          	li	s6,0
    1570:	2dc0006f          	j	184c <main+0x748>
        }
        if (ev == EV_RESET) {
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
    1574:	123455b7          	lui	a1,0x12345
    1578:	67858593          	addi	a1,a1,1656 # 12345678 <__freertos_irq_stack_top+0x1233dd98>
    157c:	00090513          	mv	a0,s2
    1580:	6c9000ef          	jal	2448 <scene_init>
            repaint[0] = repaint[1] = 1; hw_repaint = 1;
    1584:	00100793          	li	a5,1
    1588:	02f12a23          	sw	a5,52(sp)
    158c:	02f12823          	sw	a5,48(sp)
    1590:	02f12023          	sw	a5,32(sp)
            scene_init(n, g_seed); cpu_i = 0; hw_i = 0; hw_half = 0; hw_frame_pushed = 0;
    1594:	00012823          	sw	zero,16(sp)
    1598:	00000493          	li	s1,0
    159c:	00000413          	li	s0,0
    15a0:	00000b13          	li	s6,0
    15a4:	2b00006f          	j	1854 <main+0x750>
        }

        /* ---------- 引擎收尾：COPY 完成的缓冲回到 FREE ---------- */
        if (copying >= 0 && blt_idle()) {
    15a8:	2e1000ef          	jal	2088 <blt_idle>
    15ac:	2a050663          	beqz	a0,1858 <main+0x754>
            bs[copying] = BS_FREE;
    15b0:	002c9c93          	slli	s9,s9,0x2
    15b4:	030c8793          	addi	a5,s9,48
    15b8:	02010713          	addi	a4,sp,32
    15bc:	00e78cb3          	add	s9,a5,a4
    15c0:	fe0ca423          	sw	zero,-24(s9)
            copying = -1;
            scr_frames++;
    15c4:	01c12783          	lw	a5,28(sp)
    15c8:	00178793          	addi	a5,a5,1
    15cc:	00f12e23          	sw	a5,28(sp)
            copying = -1;
    15d0:	fff00c93          	li	s9,-1
    15d4:	2840006f          	j	1858 <main+0x754>
        }
        if (mode == MODE_CPU) {
            /* ---------- CPU 模式：画屏外缓冲 → 引擎整屏 COPY 上屏 ---------- */
            if (rendering < 0) {                     /* 选一块 FREE 的开始新一帧 */
                if      (bs[0] == BS_FREE) { rendering = 0; bs[0] = BS_RENDERING; }
    15d8:	03812783          	lw	a5,56(sp)
    15dc:	02079863          	bnez	a5,160c <main+0x508>
    15e0:	00100793          	li	a5,1
    15e4:	02f12c23          	sw	a5,56(sp)
    15e8:	000b8a93          	mv	s5,s7
                else if (bs[1] == BS_FREE) { rendering = 1; bs[1] = BS_RENDERING; }
                if (rendering >= 0) {
                    cpu_i = 0;
                    if (repaint[rendering]) {
    15ec:	002a9793          	slli	a5,s5,0x2
    15f0:	03078793          	addi	a5,a5,48
    15f4:	02010713          	addi	a4,sp,32
    15f8:	00e787b3          	add	a5,a5,a4
    15fc:	fe07a783          	lw	a5,-32(a5)
    1600:	02079263          	bnez	a5,1624 <main+0x520>
                        scene_sync(g_sc[rendering], n);
                        repaint[rendering] = 0;
                    }
                }
            }
            if (rendering >= 0) {
    1604:	000b8b13          	mv	s6,s7
    1608:	2580006f          	j	1860 <main+0x75c>
                else if (bs[1] == BS_FREE) { rendering = 1; bs[1] = BS_RENDERING; }
    160c:	03c12783          	lw	a5,60(sp)
    1610:	10079263          	bnez	a5,1714 <main+0x610>
    1614:	00100793          	li	a5,1
    1618:	02f12e23          	sw	a5,60(sp)
    161c:	00100a93          	li	s5,1
    1620:	fcdff06f          	j	15ec <main+0x4e8>
                        cpu_fill32(g_buf[rendering], 0, OSD_H,
    1624:	002a9793          	slli	a5,s5,0x2
    1628:	81818513          	addi	a0,gp,-2024 # 36c8 <g_buf>
    162c:	00078b13          	mv	s6,a5
    1630:	00f50533          	add	a0,a0,a5
    1634:	00800793          	li	a5,8
    1638:	20c00713          	li	a4,524
    163c:	3c000693          	li	a3,960
    1640:	01000613          	li	a2,16
    1644:	00000593          	li	a1,0
    1648:	00052503          	lw	a0,0(a0)
    164c:	3dd000ef          	jal	2228 <cpu_fill32>
                        scene_sync(g_sc[rendering], n);
    1650:	415007b3          	neg	a5,s5
    1654:	00002737          	lui	a4,0x2
    1658:	90070713          	addi	a4,a4,-1792 # 1900 <main+0x7fc>
    165c:	00e7f7b3          	and	a5,a5,a4
    1660:	00090593          	mv	a1,s2
    1664:	00003537          	lui	a0,0x3
    1668:	6e050513          	addi	a0,a0,1760 # 36e0 <g_sc>
    166c:	00f50533          	add	a0,a0,a5
    1670:	77d000ef          	jal	25ec <scene_sync>
                        repaint[rendering] = 0;
    1674:	030b0793          	addi	a5,s6,48
    1678:	02010713          	addi	a4,sp,32
    167c:	00e78b33          	add	s6,a5,a4
    1680:	fe0b2023          	sw	zero,-32(s6)
    1684:	f81ff06f          	j	1604 <main+0x500>
                blk_t *b = &g_sc[rendering][cpu_i];
                /* 擦旧位置 + 画新位置（全部写屏外缓冲） */
                if (b->px != b->x || b->py != b->y)
                    cpu_fill32(g_buf[rendering], b->px, b->py, b->sz, b->sz, COL_BG);
    1688:	002a9793          	slli	a5,s5,0x2
    168c:	81818513          	addi	a0,gp,-2024 # 36c8 <g_buf>
    1690:	00f50533          	add	a0,a0,a5
    1694:	00003637          	lui	a2,0x3
    1698:	19000793          	li	a5,400
    169c:	02fa87b3          	mul	a5,s5,a5
    16a0:	016787b3          	add	a5,a5,s6
    16a4:	00479793          	slli	a5,a5,0x4
    16a8:	6e060613          	addi	a2,a2,1760 # 36e0 <g_sc>
    16ac:	00f60633          	add	a2,a2,a5
    16b0:	00e64683          	lbu	a3,14(a2)
    16b4:	00800793          	li	a5,8
    16b8:	00068713          	mv	a4,a3
    16bc:	00661603          	lh	a2,6(a2)
    16c0:	00052503          	lw	a0,0(a0)
    16c4:	365000ef          	jal	2228 <cpu_fill32>
                cpu_fill32(g_buf[rendering], b->x, b->y, b->sz, b->sz, b->color);
    16c8:	002a9793          	slli	a5,s5,0x2
    16cc:	81818513          	addi	a0,gp,-2024 # 36c8 <g_buf>
    16d0:	00f50533          	add	a0,a0,a5
    16d4:	000035b7          	lui	a1,0x3
    16d8:	19000793          	li	a5,400
    16dc:	02fa87b3          	mul	a5,s5,a5
    16e0:	016787b3          	add	a5,a5,s6
    16e4:	00479793          	slli	a5,a5,0x4
    16e8:	6e058593          	addi	a1,a1,1760 # 36e0 <g_sc>
    16ec:	00f585b3          	add	a1,a1,a5
    16f0:	00e5c683          	lbu	a3,14(a1)
    16f4:	00c5d783          	lhu	a5,12(a1)
    16f8:	00068713          	mv	a4,a3
    16fc:	00259603          	lh	a2,2(a1)
    1700:	00059583          	lh	a1,0(a1)
    1704:	00052503          	lw	a0,0(a0)
    1708:	321000ef          	jal	2228 <cpu_fill32>
                if (++cpu_i >= n) {                  /* 一帧画完 */
    170c:	001b0b13          	addi	s6,s6,1
    1710:	1b2b5263          	bge	s6,s2,18b4 <main+0x7b0>
                    rendering = -1;
                    render_frames++;
                }
            }
            /* 有 READY 的缓冲 + 引擎空闲 → 推整屏 COPY（一次只允许一笔在飞） */
            if (copying < 0 && blt_can_push()) {
    1714:	1e0cc663          	bltz	s9,1900 <main+0x7fc>
                }
            }
        }

        /* ---------- 每 300ms 刷 OSD + 打印一行统计（纯 ASCII） ---------- */
        if ((uint32_t)(tick() - t_osd) >= (uint32_t)(BSP_CLINT_HZ * 3u / 10u)) {
    1718:	7f8000ef          	jal	1f10 <tick>
    171c:	41850533          	sub	a0,a0,s8
    1720:	01c9c7b7          	lui	a5,0x1c9c
    1724:	37f78793          	addi	a5,a5,895 # 1c9c37f <__freertos_irq_stack_top+0x1c94a9f>
    1728:	0ea7f863          	bgeu	a5,a0,1818 <main+0x714>
            uint32_t el = (uint32_t)(tick() - t_osd);
    172c:	7e4000ef          	jal	1f10 <tick>
    1730:	418507b3          	sub	a5,a0,s8
    1734:	00f12c23          	sw	a5,24(sp)
            uint32_t d_it = it - it_prev;
    1738:	41b98db3          	sub	s11,s3,s11

            t_osd   = (uint32_t)tick();
    173c:	7d4000ef          	jal	1f10 <tick>
    1740:	00050c13          	mv	s8,a0
            it_prev = it;
            osd_evt++;
    1744:	01412703          	lw	a4,20(sp)
    1748:	00170713          	addi	a4,a4,1
    174c:	00e12a23          	sw	a4,20(sp)

            cpu_fps = (uint32_t)(((uint64_t)render_frames * (uint64_t)BSP_CLINT_HZ) / el);
    1750:	05f5ed37          	lui	s10,0x5f5e
    1754:	100d0d13          	addi	s10,s10,256 # 5f5e100 <__freertos_irq_stack_top+0x5f56820>
    1758:	03aa35b3          	mulhu	a1,s4,s10
    175c:	01812603          	lw	a2,24(sp)
    1760:	00000693          	li	a3,0
    1764:	03aa0533          	mul	a0,s4,s10
    1768:	454010ef          	jal	2bbc <__udivdi3>
    176c:	00050a13          	mv	s4,a0
            scr_fps = (uint32_t)(((uint64_t)(scr_frames + hw_frames) * (uint64_t)BSP_CLINT_HZ) / el);
    1770:	01c12703          	lw	a4,28(sp)
    1774:	02412683          	lw	a3,36(sp)
    1778:	00d70533          	add	a0,a4,a3
    177c:	03a535b3          	mulhu	a1,a0,s10
    1780:	01812603          	lw	a2,24(sp)
    1784:	00000693          	li	a3,0
    1788:	03a50533          	mul	a0,a0,s10
    178c:	430010ef          	jal	2bbc <__udivdi3>
    1790:	00050d13          	mv	s10,a0
             *             方块永远不会进入 OSD 条，所以不会互相覆盖）。若此刻没有在渲染
             *             的缓冲（刚推完 COPY 的瞬间），就等下一轮 300ms 再画。
             *   硬件模式 → 固定画进 FB1，再让引擎搬最上面 960x16 那一条上屏。
             *   ★ 这条 OSD 搬运**不占用双缓冲状态机**（copying 只表示整屏 COPY 在飞），
             *     且只在引擎完全空闲时下发，避免与整屏 COPY 的完成判定互相干扰。 */
            if (mode == MODE_CPU) {
    1794:	3e0b9863          	bnez	s7,1b84 <main+0xa80>
                /* ★ 两块屏外缓冲都要刷 OSD：它们是交替上屏的，只刷一块会让状态条
                 *   在两帧之间来回跳（数字闪烁）。正在被引擎整屏 COPY 的那块不能碰
                 *   （会撕裂），其余状态（FREE/READY/RENDERING）都可以安全写。 */
                if (bs[0] != BS_COPYING) draw_osd(g_buf[0], mode, n, cpu_fps, scr_fps, it / 1000u);
    1798:	03812703          	lw	a4,56(sp)
    179c:	00300793          	li	a5,3
    17a0:	38f71e63          	bne	a4,a5,1b3c <main+0xa38>
                if (bs[1] != BS_COPYING) draw_osd(g_buf[1], mode, n, cpu_fps, scr_fps, it / 1000u);
    17a4:	03c12703          	lw	a4,60(sp)
    17a8:	00300793          	li	a5,3
    17ac:	3af71a63          	bne	a4,a5,1b60 <main+0xa5c>
            }

            bsp_printf("S it=%d d=%d m=%d N=%d CPU=%d SCR=%d C=%d ST=%x KEY=%x\r\n",
                       (int)it, (int)d_it, mode, n,
                       (int)cpu_fps, (int)scr_fps,
                       (int)blt_cnt(), (unsigned)blt_stat(),
    17b0:	0a1000ef          	jal	2050 <blt_cnt>
    17b4:	00a12c23          	sw	a0,24(sp)
    17b8:	0b5000ef          	jal	206c <blt_stat>
    17bc:	00a12e23          	sw	a0,28(sp)
                       (unsigned)gpio_read_keys());
    17c0:	731000ef          	jal	26f0 <gpio_read_keys>
            bsp_printf("S it=%d d=%d m=%d N=%d CPU=%d SCR=%d C=%d ST=%x KEY=%x\r\n",
    17c4:	00a12223          	sw	a0,4(sp)
    17c8:	01c12783          	lw	a5,28(sp)
    17cc:	00f12023          	sw	a5,0(sp)
    17d0:	01812883          	lw	a7,24(sp)
    17d4:	000d0813          	mv	a6,s10
    17d8:	000a0793          	mv	a5,s4
    17dc:	00090713          	mv	a4,s2
    17e0:	000b8693          	mv	a3,s7
    17e4:	000d8613          	mv	a2,s11
    17e8:	00098593          	mv	a1,s3
    17ec:	00003537          	lui	a0,0x3
    17f0:	2e850513          	addi	a0,a0,744 # 32e8 <_data+0x27c>
    17f4:	298010ef          	jal	2a8c <bsp_printf>

            render_frames = 0; scr_frames = 0; hw_frames = 0;

            /* 诊断：每 10 次统计打一条更全的（含扫描输出健康度 0x20） */
            if ((osd_evt % 10u) == 0u) {
    17f8:	00a00a13          	li	s4,10
    17fc:	01412783          	lw	a5,20(sp)
    1800:	0347fa33          	remu	s4,a5,s4
    1804:	3a0a0663          	beqz	s4,1bb0 <main+0xaac>
            it_prev = it;
    1808:	00098d93          	mv	s11,s3
            render_frames = 0; scr_frames = 0; hw_frames = 0;
    180c:	02012223          	sw	zero,36(sp)
    1810:	00012e23          	sw	zero,28(sp)
    1814:	00000a13          	li	s4,0
        it++;
    1818:	00198993          	addi	s3,s3,1
        ev = input_poll();
    181c:	7e9000ef          	jal	2804 <input_poll>
    1820:	00050d13          	mv	s10,a0
        if ((it & 4095u) == 0u) {
    1824:	000017b7          	lui	a5,0x1
    1828:	fff78793          	addi	a5,a5,-1 # fff <CUSTOM2+0xfa4>
    182c:	00f9f7b3          	and	a5,s3,a5
    1830:	c40782e3          	beqz	a5,1474 <main+0x370>
        if (ev == EV_MODE) {
    1834:	00100793          	li	a5,1
    1838:	c8fd02e3          	beq	s10,a5,14bc <main+0x3b8>
        if (ev == EV_N_INC) {
    183c:	00200793          	li	a5,2
    1840:	cafd06e3          	beq	s10,a5,14ec <main+0x3e8>
        if (ev == EV_N_DEC) {
    1844:	00300793          	li	a5,3
    1848:	cefd04e3          	beq	s10,a5,1530 <main+0x42c>
        if (ev == EV_RESET) {
    184c:	00400793          	li	a5,4
    1850:	d2fd02e3          	beq	s10,a5,1574 <main+0x470>
        if (copying >= 0 && blt_idle()) {
    1854:	d40cdae3          	bgez	s9,15a8 <main+0x4a4>
        if (mode == MODE_CPU) {
    1858:	100b9463          	bnez	s7,1960 <main+0x85c>
            if (rendering < 0) {                     /* 选一块 FREE 的开始新一帧 */
    185c:	d60acee3          	bltz	s5,15d8 <main+0x4d4>
                if (b->px != b->x || b->py != b->y)
    1860:	00003737          	lui	a4,0x3
    1864:	19000793          	li	a5,400
    1868:	02fa87b3          	mul	a5,s5,a5
    186c:	016787b3          	add	a5,a5,s6
    1870:	00479793          	slli	a5,a5,0x4
    1874:	6e070713          	addi	a4,a4,1760 # 36e0 <g_sc>
    1878:	00f707b3          	add	a5,a4,a5
    187c:	00479583          	lh	a1,4(a5)
    1880:	00079783          	lh	a5,0(a5)
    1884:	e0f592e3          	bne	a1,a5,1688 <main+0x584>
    1888:	00003737          	lui	a4,0x3
    188c:	19000793          	li	a5,400
    1890:	02fa87b3          	mul	a5,s5,a5
    1894:	016787b3          	add	a5,a5,s6
    1898:	00479793          	slli	a5,a5,0x4
    189c:	6e070713          	addi	a4,a4,1760 # 36e0 <g_sc>
    18a0:	00f707b3          	add	a5,a4,a5
    18a4:	00679703          	lh	a4,6(a5)
    18a8:	00279783          	lh	a5,2(a5)
    18ac:	dcf71ee3          	bne	a4,a5,1688 <main+0x584>
    18b0:	e19ff06f          	j	16c8 <main+0x5c4>
                    scene_step(g_sc[rendering], n, &rg);
    18b4:	00002537          	lui	a0,0x2
    18b8:	90050513          	addi	a0,a0,-1792 # 1900 <main+0x7fc>
    18bc:	02aa8533          	mul	a0,s5,a0
    18c0:	04010613          	addi	a2,sp,64
    18c4:	00090593          	mv	a1,s2
    18c8:	000037b7          	lui	a5,0x3
    18cc:	6e078793          	addi	a5,a5,1760 # 36e0 <g_sc>
    18d0:	00a78533          	add	a0,a5,a0
    18d4:	545000ef          	jal	2618 <scene_step>
                    bs[rendering] = BS_READY;
    18d8:	002a9a93          	slli	s5,s5,0x2
    18dc:	030a8793          	addi	a5,s5,48
    18e0:	02010713          	addi	a4,sp,32
    18e4:	00e78ab3          	add	s5,a5,a4
    18e8:	00200793          	li	a5,2
    18ec:	fefaa423          	sw	a5,-24(s5)
                    render_frames++;
    18f0:	001a0a13          	addi	s4,s4,1
                    cpu_i = 0;
    18f4:	000b8b13          	mv	s6,s7
                    rendering = -1;
    18f8:	fff00a93          	li	s5,-1
    18fc:	e19ff06f          	j	1714 <main+0x610>
            if (copying < 0 && blt_can_push()) {
    1900:	7ac000ef          	jal	20ac <blt_can_push>
    1904:	e0050ae3          	beqz	a0,1718 <main+0x614>
                if      (bs[0] == BS_READY) { cache_evict(); blt_copy_full(g_buf[0], FB_BASE); bs[0] = BS_COPYING; copying = 0; }
    1908:	03812703          	lw	a4,56(sp)
    190c:	00200793          	li	a5,2
    1910:	02f70863          	beq	a4,a5,1940 <main+0x83c>
                else if (bs[1] == BS_READY) { cache_evict(); blt_copy_full(g_buf[1], FB_BASE); bs[1] = BS_COPYING; copying = 1; }
    1914:	03c12703          	lw	a4,60(sp)
    1918:	00200793          	li	a5,2
    191c:	def71ee3          	bne	a4,a5,1718 <main+0x614>
    1920:	62c000ef          	jal	1f4c <cache_evict>
    1924:	003015b7          	lui	a1,0x301
    1928:	00501537          	lui	a0,0x501
    192c:	7e0000ef          	jal	210c <blt_copy_full>
    1930:	00300793          	li	a5,3
    1934:	02f12e23          	sw	a5,60(sp)
    1938:	00100c93          	li	s9,1
    193c:	dddff06f          	j	1718 <main+0x614>
                if      (bs[0] == BS_READY) { cache_evict(); blt_copy_full(g_buf[0], FB_BASE); bs[0] = BS_COPYING; copying = 0; }
    1940:	60c000ef          	jal	1f4c <cache_evict>
    1944:	003015b7          	lui	a1,0x301
    1948:	00401537          	lui	a0,0x401
    194c:	7c0000ef          	jal	210c <blt_copy_full>
    1950:	00300793          	li	a5,3
    1954:	02f12c23          	sw	a5,56(sp)
    1958:	000b8c93          	mv	s9,s7
    195c:	dbdff06f          	j	1718 <main+0x614>
            if (hw_frame_pushed) {
    1960:	01012783          	lw	a5,16(sp)
    1964:	1a078863          	beqz	a5,1b14 <main+0xa10>
                if (blt_idle()) {
    1968:	720000ef          	jal	2088 <blt_idle>
    196c:	da0506e3          	beqz	a0,1718 <main+0x614>
                    hw_frames++;
    1970:	02412783          	lw	a5,36(sp)
    1974:	00178793          	addi	a5,a5,1
    1978:	02f12223          	sw	a5,36(sp)
                    scene_step(g_sc[0], n, &rg);      /* 下一帧用新位置（擦除用 px/py） */
    197c:	04010613          	addi	a2,sp,64
    1980:	00090593          	mv	a1,s2
    1984:	00003537          	lui	a0,0x3
    1988:	6e050513          	addi	a0,a0,1760 # 36e0 <g_sc>
    198c:	48d000ef          	jal	2618 <scene_step>
                    if (hw_repaint && blt_can_push()) {
    1990:	02012783          	lw	a5,32(sp)
    1994:	02079263          	bnez	a5,19b8 <main+0x8b4>
                    if (osd_dirty && blt_can_push()) { /* ★ 状态条此刻搬，必然发得出去 */
    1998:	02812783          	lw	a5,40(sp)
    199c:	18078063          	beqz	a5,1b1c <main+0xa18>
    19a0:	70c000ef          	jal	20ac <blt_can_push>
    19a4:	00050413          	mv	s0,a0
    19a8:	04051863          	bnez	a0,19f8 <main+0x8f4>
                    hw_frame_pushed = 0;
    19ac:	00a12823          	sw	a0,16(sp)
                    hw_i = 0; hw_half = 0;
    19b0:	00050493          	mv	s1,a0
    19b4:	d65ff06f          	j	1718 <main+0x614>
                    if (hw_repaint && blt_can_push()) {
    19b8:	6f4000ef          	jal	20ac <blt_can_push>
    19bc:	fc050ee3          	beqz	a0,1998 <main+0x894>
                        blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, COL_BG);
    19c0:	00800713          	li	a4,8
    19c4:	21c00693          	li	a3,540
    19c8:	3c000613          	li	a2,960
    19cc:	78000593          	li	a1,1920
    19d0:	00301537          	lui	a0,0x301
    19d4:	7b0000ef          	jal	2184 <blt_fill>
                        scene_sync(g_sc[0], n);
    19d8:	00090593          	mv	a1,s2
    19dc:	00003537          	lui	a0,0x3
    19e0:	6e050513          	addi	a0,a0,1760 # 36e0 <g_sc>
    19e4:	409000ef          	jal	25ec <scene_sync>
                        osd_dirty  = 1;
    19e8:	02012783          	lw	a5,32(sp)
    19ec:	02f12423          	sw	a5,40(sp)
                        hw_repaint = 0;
    19f0:	02012023          	sw	zero,32(sp)
    19f4:	fadff06f          	j	19a0 <main+0x89c>
                        blt_copy_osd(FB1_BASE, FB_BASE);
    19f8:	003015b7          	lui	a1,0x301
    19fc:	00401537          	lui	a0,0x401
    1a00:	748000ef          	jal	2148 <blt_copy_osd>
                        osd_dirty = 0;
    1a04:	02012423          	sw	zero,40(sp)
                    hw_frame_pushed = 0;
    1a08:	00012823          	sw	zero,16(sp)
                    hw_i = 0; hw_half = 0;
    1a0c:	00000493          	li	s1,0
    1a10:	00000413          	li	s0,0
    1a14:	d05ff06f          	j	1718 <main+0x614>
                        blt_fill(FB_BASE + (uint32_t)b->py * FB_STRIDE + (uint32_t)b->px * 2u,
    1a18:	000037b7          	lui	a5,0x3
    1a1c:	00441713          	slli	a4,s0,0x4
    1a20:	6e078793          	addi	a5,a5,1760 # 36e0 <g_sc>
    1a24:	00e787b3          	add	a5,a5,a4
    1a28:	00679703          	lh	a4,6(a5)
    1a2c:	00471513          	slli	a0,a4,0x4
    1a30:	40e50533          	sub	a0,a0,a4
    1a34:	00651513          	slli	a0,a0,0x6
    1a38:	00d50533          	add	a0,a0,a3
    1a3c:	00181737          	lui	a4,0x181
    1a40:	80070713          	addi	a4,a4,-2048 # 180800 <__freertos_irq_stack_top+0x178f20>
    1a44:	00e50533          	add	a0,a0,a4
                                 FB_STRIDE, b->sz, b->sz, COL_BG);
    1a48:	00e7c603          	lbu	a2,14(a5)
                        blt_fill(FB_BASE + (uint32_t)b->py * FB_STRIDE + (uint32_t)b->px * 2u,
    1a4c:	00800713          	li	a4,8
    1a50:	00060693          	mv	a3,a2
    1a54:	78000593          	li	a1,1920
    1a58:	00151513          	slli	a0,a0,0x1
    1a5c:	728000ef          	jal	2184 <blt_fill>
                        hw_half = 1;
    1a60:	00100493          	li	s1,1
    1a64:	000d0793          	mv	a5,s10
                while (budget-- > 0 && blt_can_push()) {
    1a68:	fff78d13          	addi	s10,a5,-1
    1a6c:	caf056e3          	blez	a5,1718 <main+0x614>
    1a70:	63c000ef          	jal	20ac <blt_can_push>
    1a74:	ca0502e3          	beqz	a0,1718 <main+0x614>
                    if (hw_half == 0) {
    1a78:	04049063          	bnez	s1,1ab8 <main+0x9b4>
                        if (b->px == b->x && b->py == b->y) { hw_half = 1; continue; }
    1a7c:	000037b7          	lui	a5,0x3
    1a80:	00441713          	slli	a4,s0,0x4
    1a84:	6e078793          	addi	a5,a5,1760 # 36e0 <g_sc>
    1a88:	00e787b3          	add	a5,a5,a4
    1a8c:	00479683          	lh	a3,4(a5)
    1a90:	00079783          	lh	a5,0(a5)
    1a94:	f8f692e3          	bne	a3,a5,1a18 <main+0x914>
    1a98:	000037b7          	lui	a5,0x3
    1a9c:	6e078793          	addi	a5,a5,1760 # 36e0 <g_sc>
    1aa0:	00e787b3          	add	a5,a5,a4
    1aa4:	00679703          	lh	a4,6(a5)
    1aa8:	00279783          	lh	a5,2(a5)
    1aac:	f6f716e3          	bne	a4,a5,1a18 <main+0x914>
    1ab0:	00100493          	li	s1,1
    1ab4:	fb1ff06f          	j	1a64 <main+0x960>
                        blt_fill(FB_BASE + (uint32_t)b->y * FB_STRIDE + (uint32_t)b->x * 2u,
    1ab8:	000037b7          	lui	a5,0x3
    1abc:	00441713          	slli	a4,s0,0x4
    1ac0:	6e078793          	addi	a5,a5,1760 # 36e0 <g_sc>
    1ac4:	00e787b3          	add	a5,a5,a4
    1ac8:	00279703          	lh	a4,2(a5)
    1acc:	00079683          	lh	a3,0(a5)
    1ad0:	00471513          	slli	a0,a4,0x4
    1ad4:	40e50533          	sub	a0,a0,a4
    1ad8:	00651513          	slli	a0,a0,0x6
    1adc:	00d50533          	add	a0,a0,a3
    1ae0:	00181737          	lui	a4,0x181
    1ae4:	80070713          	addi	a4,a4,-2048 # 180800 <__freertos_irq_stack_top+0x178f20>
    1ae8:	00e50533          	add	a0,a0,a4
                                 FB_STRIDE, b->sz, b->sz, b->color);
    1aec:	00e7c603          	lbu	a2,14(a5)
                        blt_fill(FB_BASE + (uint32_t)b->y * FB_STRIDE + (uint32_t)b->x * 2u,
    1af0:	00c7d703          	lhu	a4,12(a5)
    1af4:	00060693          	mv	a3,a2
    1af8:	78000593          	li	a1,1920
    1afc:	00151513          	slli	a0,a0,0x1
    1b00:	684000ef          	jal	2184 <blt_fill>
                        if (++hw_i >= n) {
    1b04:	00140413          	addi	s0,s0,1
    1b08:	03245263          	bge	s0,s2,1b2c <main+0xa28>
                        hw_half = 0;
    1b0c:	01012483          	lw	s1,16(sp)
    1b10:	f55ff06f          	j	1a64 <main+0x960>
                int budget = 32;
    1b14:	02000793          	li	a5,32
    1b18:	f51ff06f          	j	1a68 <main+0x964>
                    hw_frame_pushed = 0;
    1b1c:	02812403          	lw	s0,40(sp)
    1b20:	00812823          	sw	s0,16(sp)
                    hw_i = 0; hw_half = 0;
    1b24:	00040493          	mv	s1,s0
    1b28:	bf1ff06f          	j	1718 <main+0x614>
    1b2c:	00048793          	mv	a5,s1
                        hw_half = 0;
    1b30:	01012483          	lw	s1,16(sp)
                            hw_frame_pushed = 1;      /* 本帧指令推满 → 停手，等引擎做完 */
    1b34:	00f12823          	sw	a5,16(sp)
    1b38:	be1ff06f          	j	1718 <main+0x614>
                if (bs[0] != BS_COPYING) draw_osd(g_buf[0], mode, n, cpu_fps, scr_fps, it / 1000u);
    1b3c:	3e800793          	li	a5,1000
    1b40:	02f9d7b3          	divu	a5,s3,a5
    1b44:	00050713          	mv	a4,a0
    1b48:	000a0693          	mv	a3,s4
    1b4c:	00090613          	mv	a2,s2
    1b50:	000b8593          	mv	a1,s7
    1b54:	00401537          	lui	a0,0x401
    1b58:	615000ef          	jal	296c <draw_osd>
    1b5c:	c49ff06f          	j	17a4 <main+0x6a0>
                if (bs[1] != BS_COPYING) draw_osd(g_buf[1], mode, n, cpu_fps, scr_fps, it / 1000u);
    1b60:	3e800793          	li	a5,1000
    1b64:	02f9d7b3          	divu	a5,s3,a5
    1b68:	000d0713          	mv	a4,s10
    1b6c:	000a0693          	mv	a3,s4
    1b70:	00090613          	mv	a2,s2
    1b74:	000b8593          	mv	a1,s7
    1b78:	00501537          	lui	a0,0x501
    1b7c:	5f1000ef          	jal	296c <draw_osd>
    1b80:	c31ff06f          	j	17b0 <main+0x6ac>
                draw_osd(FB1_BASE, mode, n, cpu_fps, scr_fps, it / 1000u);
    1b84:	3e800793          	li	a5,1000
    1b88:	02f9d7b3          	divu	a5,s3,a5
    1b8c:	00050713          	mv	a4,a0
    1b90:	000a0693          	mv	a3,s4
    1b94:	00090613          	mv	a2,s2
    1b98:	000b8593          	mv	a1,s7
    1b9c:	00401537          	lui	a0,0x401
    1ba0:	5cd000ef          	jal	296c <draw_osd>
                osd_dirty = 1;
    1ba4:	00100793          	li	a5,1
    1ba8:	02f12423          	sw	a5,40(sp)
    1bac:	c05ff06f          	j	17b0 <main+0x6ac>
                uint32_t sc = blt_rd(0x20);
    1bb0:	02000513          	li	a0,32
    1bb4:	388000ef          	jal	1f3c <blt_rd>
    1bb8:	00050d13          	mv	s10,a0
                bsp_printf("D it=%d SC=%x ab=%d un=%d t=%x\r\n",
                           (int)it, (unsigned)sc,
                           (int)(sc >> 16), (int)(sc & 0xFFFFu),
    1bbc:	01055d93          	srli	s11,a0,0x10
                           (unsigned)(uint32_t)(tick() - t0));
    1bc0:	350000ef          	jal	1f10 <tick>
                bsp_printf("D it=%d SC=%x ab=%d un=%d t=%x\r\n",
    1bc4:	02c12783          	lw	a5,44(sp)
    1bc8:	40f507b3          	sub	a5,a0,a5
    1bcc:	010d1713          	slli	a4,s10,0x10
    1bd0:	01075713          	srli	a4,a4,0x10
    1bd4:	000d8693          	mv	a3,s11
    1bd8:	000d0613          	mv	a2,s10
    1bdc:	00098593          	mv	a1,s3
    1be0:	00003537          	lui	a0,0x3
    1be4:	32450513          	addi	a0,a0,804 # 3324 <_data+0x2b8>
    1be8:	6a5000ef          	jal	2a8c <bsp_printf>
            render_frames = 0; scr_frames = 0; hw_frames = 0;
    1bec:	03412223          	sw	s4,36(sp)
    1bf0:	01412e23          	sw	s4,28(sp)
            it_prev = it;
    1bf4:	00098d93          	mv	s11,s3
    1bf8:	c21ff06f          	j	1818 <main+0x714>

00001bfc <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    1bfc:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    1c00:	01055513          	srli	a0,a0,0x10
    }
    1c04:	0ff57513          	zext.b	a0,a0
    1c08:	00008067          	ret

00001c0c <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    1c0c:	ff010113          	addi	sp,sp,-16
    1c10:	00112623          	sw	ra,12(sp)
    1c14:	00812423          	sw	s0,8(sp)
    1c18:	00912223          	sw	s1,4(sp)
    1c1c:	00050413          	mv	s0,a0
    1c20:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    1c24:	00040513          	mv	a0,s0
    1c28:	fd5ff0ef          	jal	1bfc <uart_writeAvailability>
    1c2c:	fe050ce3          	beqz	a0,1c24 <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    1c30:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    1c34:	00c12083          	lw	ra,12(sp)
    1c38:	00812403          	lw	s0,8(sp)
    1c3c:	00412483          	lw	s1,4(sp)
    1c40:	01010113          	addi	sp,sp,16
    1c44:	00008067          	ret

00001c48 <uart_applyConfig>:
*          value using data length, parity, and stop bit settings from the configuration
*          structure, and writes this value to the UART frame configuration register.
*
******************************************************************************/
    static void uart_applyConfig(u32 reg, Uart_Config *config){
        write_u32(config->clockDivider, reg + UART_CLOCK_DIVIDER);
    1c48:	00c5a783          	lw	a5,12(a1) # 30100c <__freertos_irq_stack_top+0x2f972c>
    1c4c:	00f52423          	sw	a5,8(a0)
        write_u32(((config->dataLength-1) << 0) | (config->parity << 8) | (config->stop << 16), reg + UART_FRAME_CONFIG);
    1c50:	0005a783          	lw	a5,0(a1)
    1c54:	fff78793          	addi	a5,a5,-1
    1c58:	0045a703          	lw	a4,4(a1)
    1c5c:	00871713          	slli	a4,a4,0x8
    1c60:	00e7e7b3          	or	a5,a5,a4
    1c64:	0085a703          	lw	a4,8(a1)
    1c68:	01071713          	slli	a4,a4,0x10
    1c6c:	00e7e7b3          	or	a5,a5,a4
    1c70:	00f52623          	sw	a5,12(a0)
    }
    1c74:	00008067          	ret

00001c78 <clint_getTime>:
*          to guard against rollover. It checks if the high part remains unchanged
*          during the read operation to ensure consistency. The high and low parts
*          are then combined to form the 64-bit current time value.
*
******************************************************************************/
    static u64 clint_getTime(u32 p){
    1c78:	00050693          	mv	a3,a0
    readReg_u32 (clint_getTimeHigh, CLINT_TIME_ADDR+4)
    1c7c:	0000c7b7          	lui	a5,0xc
    1c80:	ffc78793          	addi	a5,a5,-4 # bffc <__freertos_irq_stack_top+0x471c>
    1c84:	00f687b3          	add	a5,a3,a5
        return *((volatile u32*) address);
    1c88:	0007a583          	lw	a1,0(a5)
    readReg_u32 (clint_getTimeLow , CLINT_TIME_ADDR)
    1c8c:	0000c737          	lui	a4,0xc
    1c90:	ff870713          	addi	a4,a4,-8 # bff8 <__freertos_irq_stack_top+0x4718>
    1c94:	00e68733          	add	a4,a3,a4
    1c98:	00072503          	lw	a0,0(a4)
    1c9c:	0007a783          	lw	a5,0(a5)
    
        /* Likewise, must guard against rollover when reading */
        do {
            hi = clint_getTimeHigh(p);
            lo = clint_getTimeLow(p);
        } while (clint_getTimeHigh(p) != hi);
    1ca0:	fcb79ee3          	bne	a5,a1,1c7c <clint_getTime+0x4>
    
        return (((u64)hi) << 32) | lo;
    }
    1ca4:	00008067          	ret

00001ca8 <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    1ca8:	ff010113          	addi	sp,sp,-16
    1cac:	00112623          	sw	ra,12(sp)
    1cb0:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    1cb4:	f8010537          	lui	a0,0xf8010
    1cb8:	f55ff0ef          	jal	1c0c <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    1cbc:	00c12083          	lw	ra,12(sp)
    1cc0:	01010113          	addi	sp,sp,16
    1cc4:	00008067          	ret

00001cc8 <_putchar_s>:

    static void _putchar_s(char *p)
    {
    1cc8:	ff010113          	addi	sp,sp,-16
    1ccc:	00112623          	sw	ra,12(sp)
    1cd0:	00812423          	sw	s0,8(sp)
    1cd4:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    1cd8:	00c0006f          	j	1ce4 <_putchar_s+0x1c>
            _putchar(*(p++));
    1cdc:	00140413          	addi	s0,s0,1
    1ce0:	fc9ff0ef          	jal	1ca8 <_putchar>
        while (*p)
    1ce4:	00044503          	lbu	a0,0(s0)
    1ce8:	fe051ae3          	bnez	a0,1cdc <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    1cec:	00c12083          	lw	ra,12(sp)
    1cf0:	00812403          	lw	s0,8(sp)
    1cf4:	01010113          	addi	sp,sp,16
    1cf8:	00008067          	ret

00001cfc <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    1cfc:	ff010113          	addi	sp,sp,-16
    1d00:	00112623          	sw	ra,12(sp)
    1d04:	00812423          	sw	s0,8(sp)
    1d08:	00912223          	sw	s1,4(sp)
    1d0c:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1d10:	01c00413          	li	s0,28
    1d14:	0240006f          	j	1d38 <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    1d18:	0084d733          	srl	a4,s1,s0
    1d1c:	00f77713          	andi	a4,a4,15
    1d20:	000037b7          	lui	a5,0x3
    1d24:	06c78793          	addi	a5,a5,108 # 306c <_data>
    1d28:	00e787b3          	add	a5,a5,a4
    1d2c:	0007c503          	lbu	a0,0(a5)
    1d30:	f79ff0ef          	jal	1ca8 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1d34:	ffc40413          	addi	s0,s0,-4
    1d38:	fe0450e3          	bgez	s0,1d18 <bsp_printHex+0x1c>
        }
    }
    1d3c:	00c12083          	lw	ra,12(sp)
    1d40:	00812403          	lw	s0,8(sp)
    1d44:	00412483          	lw	s1,4(sp)
    1d48:	01010113          	addi	sp,sp,16
    1d4c:	00008067          	ret

00001d50 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    1d50:	ff010113          	addi	sp,sp,-16
    1d54:	00112623          	sw	ra,12(sp)
    1d58:	00812423          	sw	s0,8(sp)
    1d5c:	00912223          	sw	s1,4(sp)
    1d60:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1d64:	01c00413          	li	s0,28
    1d68:	0240006f          	j	1d8c <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    1d6c:	0084d733          	srl	a4,s1,s0
    1d70:	00f77713          	andi	a4,a4,15
    1d74:	000037b7          	lui	a5,0x3
    1d78:	08078793          	addi	a5,a5,128 # 3080 <_data+0x14>
    1d7c:	00e787b3          	add	a5,a5,a4
    1d80:	0007c503          	lbu	a0,0(a5)
    1d84:	f25ff0ef          	jal	1ca8 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1d88:	ffc40413          	addi	s0,s0,-4
    1d8c:	fe0450e3          	bgez	s0,1d6c <bsp_printHex_lower+0x1c>

        }
    }
    1d90:	00c12083          	lw	ra,12(sp)
    1d94:	00812403          	lw	s0,8(sp)
    1d98:	00412483          	lw	s1,4(sp)
    1d9c:	01010113          	addi	sp,sp,16
    1da0:	00008067          	ret

00001da4 <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    1da4:	ff010113          	addi	sp,sp,-16
    1da8:	00112623          	sw	ra,12(sp)
        _putchar(c);
    1dac:	0ff57513          	zext.b	a0,a0
    1db0:	ef9ff0ef          	jal	1ca8 <_putchar>
    }
    1db4:	00c12083          	lw	ra,12(sp)
    1db8:	01010113          	addi	sp,sp,16
    1dbc:	00008067          	ret

00001dc0 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    1dc0:	ff010113          	addi	sp,sp,-16
    1dc4:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    1dc8:	f01ff0ef          	jal	1cc8 <_putchar_s>
    }
    1dcc:	00c12083          	lw	ra,12(sp)
    1dd0:	01010113          	addi	sp,sp,16
    1dd4:	00008067          	ret

00001dd8 <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    1dd8:	fd010113          	addi	sp,sp,-48
    1ddc:	02112623          	sw	ra,44(sp)
    1de0:	02812423          	sw	s0,40(sp)
    1de4:	02912223          	sw	s1,36(sp)
    1de8:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    1dec:	00054663          	bltz	a0,1df8 <bsp_printf_d+0x20>
    {
    1df0:	00010413          	mv	s0,sp
    1df4:	02c0006f          	j	1e20 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    1df8:	02d00513          	li	a0,45
    1dfc:	fa9ff0ef          	jal	1da4 <bsp_printf_c>
            val = -val;
    1e00:	409004b3          	neg	s1,s1
    1e04:	fedff06f          	j	1df0 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    1e08:	00a00713          	li	a4,10
    1e0c:	02e4e7b3          	rem	a5,s1,a4
    1e10:	03078793          	addi	a5,a5,48
    1e14:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    1e18:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    1e1c:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    1e20:	fe0494e3          	bnez	s1,1e08 <bsp_printf_d+0x30>
    1e24:	00010793          	mv	a5,sp
    1e28:	fef400e3          	beq	s0,a5,1e08 <bsp_printf_d+0x30>
        }
        while (p != buffer)
    1e2c:	00010793          	mv	a5,sp
    1e30:	00f40a63          	beq	s0,a5,1e44 <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    1e34:	fff40413          	addi	s0,s0,-1
    1e38:	00044503          	lbu	a0,0(s0)
    1e3c:	f69ff0ef          	jal	1da4 <bsp_printf_c>
    1e40:	fedff06f          	j	1e2c <bsp_printf_d+0x54>
    }
    1e44:	02c12083          	lw	ra,44(sp)
    1e48:	02812403          	lw	s0,40(sp)
    1e4c:	02412483          	lw	s1,36(sp)
    1e50:	03010113          	addi	sp,sp,48
    1e54:	00008067          	ret

00001e58 <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    1e58:	ff010113          	addi	sp,sp,-16
    1e5c:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    1e60:	00000713          	li	a4,0
    1e64:	00700793          	li	a5,7
    1e68:	02e7c063          	blt	a5,a4,1e88 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1e6c:	00271693          	slli	a3,a4,0x2
    1e70:	ff000793          	li	a5,-16
    1e74:	00d797b3          	sll	a5,a5,a3
    1e78:	00f577b3          	and	a5,a0,a5
    1e7c:	00078663          	beqz	a5,1e88 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    1e80:	00170713          	addi	a4,a4,1
    1e84:	fe1ff06f          	j	1e64 <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    1e88:	ec9ff0ef          	jal	1d50 <bsp_printHex_lower>
    }
    1e8c:	00c12083          	lw	ra,12(sp)
    1e90:	01010113          	addi	sp,sp,16
    1e94:	00008067          	ret

00001e98 <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    1e98:	ff010113          	addi	sp,sp,-16
    1e9c:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    1ea0:	00000713          	li	a4,0
    1ea4:	00700793          	li	a5,7
    1ea8:	02e7c063          	blt	a5,a4,1ec8 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1eac:	00271693          	slli	a3,a4,0x2
    1eb0:	ff000793          	li	a5,-16
    1eb4:	00d797b3          	sll	a5,a5,a3
    1eb8:	00f577b3          	and	a5,a0,a5
    1ebc:	00078663          	beqz	a5,1ec8 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    1ec0:	00170713          	addi	a4,a4,1
    1ec4:	fe1ff06f          	j	1ea4 <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    1ec8:	e35ff0ef          	jal	1cfc <bsp_printHex>
        }
    1ecc:	00c12083          	lw	ra,12(sp)
    1ed0:	01010113          	addi	sp,sp,16
    1ed4:	00008067          	ret

00001ed8 <bsp_init>:
    *   1. UART baudrate
    *   2. 
    */
////////////////////////////////////////////////////////////////////////////////
    static void bsp_init()
    {
    1ed8:	fe010113          	addi	sp,sp,-32
    1edc:	00112e23          	sw	ra,28(sp)
        Uart_Config uartConfig;
        uartConfig.dataLength   = BITS_8;
    1ee0:	00800793          	li	a5,8
    1ee4:	00f12023          	sw	a5,0(sp)
        uartConfig.parity       = NONE;
    1ee8:	00012223          	sw	zero,4(sp)
        uartConfig.stop         = ONE;
    1eec:	00012423          	sw	zero,8(sp)
        uartConfig.clockDivider = BSP_CLINT_HZ/(BSP_UART_BAUDRATE*BSP_UART_DATA_LEN)-1;
    1ef0:	06b00793          	li	a5,107
    1ef4:	00f12623          	sw	a5,12(sp)
        uart_applyConfig(BSP_UART_TERMINAL, &uartConfig);    
    1ef8:	00010593          	mv	a1,sp
    1efc:	f8010537          	lui	a0,0xf8010
    1f00:	d49ff0ef          	jal	1c48 <uart_applyConfig>
    }
    1f04:	01c12083          	lw	ra,28(sp)
    1f08:	02010113          	addi	sp,sp,32
    1f0c:	00008067          	ret

00001f10 <tick>:
static uint64_t tick(void) { return clint_getTime(BSP_CLINT); }
    1f10:	ff010113          	addi	sp,sp,-16
    1f14:	00112623          	sw	ra,12(sp)
    1f18:	f8b00537          	lui	a0,0xf8b00
    1f1c:	d5dff0ef          	jal	1c78 <clint_getTime>
    1f20:	00c12083          	lw	ra,12(sp)
    1f24:	01010113          	addi	sp,sp,16
    1f28:	00008067          	ret

00001f2c <blt_wr>:
static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
    1f2c:	f81007b7          	lui	a5,0xf8100
    1f30:	00f50533          	add	a0,a0,a5
    1f34:	00b52023          	sw	a1,0(a0) # f8b00000 <__freertos_irq_stack_top+0xf8af8720>
    1f38:	00008067          	ret

00001f3c <blt_rd>:
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }
    1f3c:	f81007b7          	lui	a5,0xf8100
    1f40:	00f50533          	add	a0,a0,a5
    1f44:	00052503          	lw	a0,0(a0)
    1f48:	00008067          	ret

00001f4c <cache_evict>:
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
    1f4c:	00000793          	li	a5,0
    1f50:	0200006f          	j	1f70 <cache_evict+0x24>
    1f54:	00279693          	slli	a3,a5,0x2
    1f58:	00601737          	lui	a4,0x601
    1f5c:	00d70733          	add	a4,a4,a3
    1f60:	a5a506b7          	lui	a3,0xa5a50
    1f64:	00d786b3          	add	a3,a5,a3
    1f68:	00d72023          	sw	a3,0(a4) # 601000 <__freertos_irq_stack_top+0x5f9720>
    1f6c:	00178793          	addi	a5,a5,1 # f8100001 <__freertos_irq_stack_top+0xf80f8721>
    1f70:	7ff00713          	li	a4,2047
    1f74:	fef770e3          	bgeu	a4,a5,1f54 <cache_evict+0x8>
}
    1f78:	00008067          	ret

00001f7c <blt_emit>:
{
    1f7c:	fe010113          	addi	sp,sp,-32
    1f80:	00112e23          	sw	ra,28(sp)
    1f84:	00812c23          	sw	s0,24(sp)
    1f88:	00912a23          	sw	s1,20(sp)
    1f8c:	01212823          	sw	s2,16(sp)
    1f90:	01312623          	sw	s3,12(sp)
    1f94:	01412423          	sw	s4,8(sp)
    1f98:	01512223          	sw	s5,4(sp)
    1f9c:	01612023          	sw	s6,0(sp)
    1fa0:	00058b13          	mv	s6,a1
    1fa4:	00060a93          	mv	s5,a2
    1fa8:	00068a13          	mv	s4,a3
    1fac:	00070993          	mv	s3,a4
    1fb0:	00078413          	mv	s0,a5
    1fb4:	00080493          	mv	s1,a6
    1fb8:	00088913          	mv	s2,a7
    blt_wr(BLT_CMD_FIFO_DATA, op);
    1fbc:	00050593          	mv	a1,a0
    1fc0:	00800513          	li	a0,8
    1fc4:	f69ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, src);
    1fc8:	000b0593          	mv	a1,s6
    1fcc:	00800513          	li	a0,8
    1fd0:	f5dff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    1fd4:	000a8593          	mv	a1,s5
    1fd8:	00800513          	li	a0,8
    1fdc:	f51ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    1fe0:	000a0593          	mv	a1,s4
    1fe4:	00800513          	li	a0,8
    1fe8:	f45ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    1fec:	00098593          	mv	a1,s3
    1ff0:	00800513          	li	a0,8
    1ff4:	f39ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    1ff8:	01049493          	slli	s1,s1,0x10
    1ffc:	01041413          	slli	s0,s0,0x10
    2000:	01045413          	srli	s0,s0,0x10
    2004:	0084e5b3          	or	a1,s1,s0
    2008:	00800513          	li	a0,8
    200c:	f21ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    2010:	00090593          	mv	a1,s2
    2014:	00800513          	li	a0,8
    2018:	f15ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, color);
    201c:	02012583          	lw	a1,32(sp)
    2020:	00800513          	li	a0,8
    2024:	f09ff0ef          	jal	1f2c <blt_wr>
}
    2028:	01c12083          	lw	ra,28(sp)
    202c:	01812403          	lw	s0,24(sp)
    2030:	01412483          	lw	s1,20(sp)
    2034:	01012903          	lw	s2,16(sp)
    2038:	00c12983          	lw	s3,12(sp)
    203c:	00812a03          	lw	s4,8(sp)
    2040:	00412a83          	lw	s5,4(sp)
    2044:	00012b03          	lw	s6,0(sp)
    2048:	02010113          	addi	sp,sp,32
    204c:	00008067          	ret

00002050 <blt_cnt>:
static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
    2050:	ff010113          	addi	sp,sp,-16
    2054:	00112623          	sw	ra,12(sp)
    2058:	00c00513          	li	a0,12
    205c:	ee1ff0ef          	jal	1f3c <blt_rd>
    2060:	00c12083          	lw	ra,12(sp)
    2064:	01010113          	addi	sp,sp,16
    2068:	00008067          	ret

0000206c <blt_stat>:
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }
    206c:	ff010113          	addi	sp,sp,-16
    2070:	00112623          	sw	ra,12(sp)
    2074:	00400513          	li	a0,4
    2078:	ec5ff0ef          	jal	1f3c <blt_rd>
    207c:	00c12083          	lw	ra,12(sp)
    2080:	01010113          	addi	sp,sp,16
    2084:	00008067          	ret

00002088 <blt_idle>:
{
    2088:	ff010113          	addi	sp,sp,-16
    208c:	00112623          	sw	ra,12(sp)
    uint32_t st = blt_stat();
    2090:	fddff0ef          	jal	206c <blt_stat>
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
    2094:	00e57513          	andi	a0,a0,14
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
    2098:	ff650513          	addi	a0,a0,-10
}
    209c:	00153513          	seqz	a0,a0
    20a0:	00c12083          	lw	ra,12(sp)
    20a4:	01010113          	addi	sp,sp,16
    20a8:	00008067          	ret

000020ac <blt_can_push>:
{
    20ac:	ff010113          	addi	sp,sp,-16
    20b0:	00112623          	sw	ra,12(sp)
    return (blt_cnt() <= (uint32_t)(BLT_FIFO_DEPTH - HW_FIFO_MARGIN - 1)) ? 1 : 0;
    20b4:	f9dff0ef          	jal	2050 <blt_cnt>
}
    20b8:	0c853513          	sltiu	a0,a0,200
    20bc:	00c12083          	lw	ra,12(sp)
    20c0:	01010113          	addi	sp,sp,16
    20c4:	00008067          	ret

000020c8 <blt_init>:
{
    20c8:	ff010113          	addi	sp,sp,-16
    20cc:	00112623          	sw	ra,12(sp)
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    20d0:	00400593          	li	a1,4
    20d4:	00000513          	li	a0,0
    20d8:	e55ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_IRQ_STATUS, 1u);                        /* W1C */
    20dc:	00100593          	li	a1,1
    20e0:	01000513          	li	a0,16
    20e4:	e49ff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_IRQ_EN, 0u);
    20e8:	00000593          	li	a1,0
    20ec:	01400513          	li	a0,20
    20f0:	e3dff0ef          	jal	1f2c <blt_wr>
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
    20f4:	00100593          	li	a1,1
    20f8:	00000513          	li	a0,0
    20fc:	e31ff0ef          	jal	1f2c <blt_wr>
}
    2100:	00c12083          	lw	ra,12(sp)
    2104:	01010113          	addi	sp,sp,16
    2108:	00008067          	ret

0000210c <blt_copy_full>:
{
    210c:	fe010113          	addi	sp,sp,-32
    2110:	00112e23          	sw	ra,28(sp)
    2114:	00058613          	mv	a2,a1
    blt_emit(BLT_OP_COPY, src, dst, FB_STRIDE, FB_STRIDE,
    2118:	00012023          	sw	zero,0(sp)
    211c:	0ff00893          	li	a7,255
    2120:	21c00813          	li	a6,540
    2124:	3c000793          	li	a5,960
    2128:	78000713          	li	a4,1920
    212c:	78000693          	li	a3,1920
    2130:	00050593          	mv	a1,a0
    2134:	00000513          	li	a0,0
    2138:	e45ff0ef          	jal	1f7c <blt_emit>
}
    213c:	01c12083          	lw	ra,28(sp)
    2140:	02010113          	addi	sp,sp,32
    2144:	00008067          	ret

00002148 <blt_copy_osd>:
{
    2148:	fe010113          	addi	sp,sp,-32
    214c:	00112e23          	sw	ra,28(sp)
    2150:	00058613          	mv	a2,a1
    blt_emit(BLT_OP_COPY, src, dst, FB_STRIDE, FB_STRIDE,
    2154:	00012023          	sw	zero,0(sp)
    2158:	0ff00893          	li	a7,255
    215c:	01000813          	li	a6,16
    2160:	3c000793          	li	a5,960
    2164:	78000713          	li	a4,1920
    2168:	78000693          	li	a3,1920
    216c:	00050593          	mv	a1,a0
    2170:	00000513          	li	a0,0
    2174:	e09ff0ef          	jal	1f7c <blt_emit>
}
    2178:	01c12083          	lw	ra,28(sp)
    217c:	02010113          	addi	sp,sp,32
    2180:	00008067          	ret

00002184 <blt_fill>:
{
    2184:	fe010113          	addi	sp,sp,-32
    2188:	00112e23          	sw	ra,28(sp)
    218c:	00060793          	mv	a5,a2
    blt_emit(BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color);
    2190:	00e12023          	sw	a4,0(sp)
    2194:	0ff00893          	li	a7,255
    2198:	00068813          	mv	a6,a3
    219c:	00058713          	mv	a4,a1
    21a0:	00000693          	li	a3,0
    21a4:	00050613          	mv	a2,a0
    21a8:	00000593          	li	a1,0
    21ac:	00100513          	li	a0,1
    21b0:	dcdff0ef          	jal	1f7c <blt_emit>
}
    21b4:	01c12083          	lw	ra,28(sp)
    21b8:	02010113          	addi	sp,sp,32
    21bc:	00008067          	ret

000021c0 <glyph_of>:
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    21c0:	f9f50793          	addi	a5,a0,-97
    21c4:	0ff7f793          	zext.b	a5,a5
    21c8:	01900713          	li	a4,25
    21cc:	00f76663          	bltu	a4,a5,21d8 <glyph_of+0x18>
    21d0:	fe050513          	addi	a0,a0,-32
    21d4:	0ff57513          	zext.b	a0,a0
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return g_font[i].r;
    21d8:	00000713          	li	a4,0
    21dc:	02500793          	li	a5,37
    21e0:	02e7ce63          	blt	a5,a4,221c <glyph_of+0x5c>
    21e4:	000037b7          	lui	a5,0x3
    21e8:	00371693          	slli	a3,a4,0x3
    21ec:	00e686b3          	add	a3,a3,a4
    21f0:	46478793          	addi	a5,a5,1124 # 3464 <g_font>
    21f4:	00d787b3          	add	a5,a5,a3
    21f8:	0007c783          	lbu	a5,0(a5)
    21fc:	00a78663          	beq	a5,a0,2208 <glyph_of+0x48>
    2200:	00170713          	addi	a4,a4,1
    2204:	fd9ff06f          	j	21dc <glyph_of+0x1c>
    2208:	000037b7          	lui	a5,0x3
    220c:	46478793          	addi	a5,a5,1124 # 3464 <g_font>
    2210:	00f68533          	add	a0,a3,a5
    2214:	00150513          	addi	a0,a0,1
    2218:	00008067          	ret
    return g_font[0].r;
    221c:	00003537          	lui	a0,0x3
    2220:	46550513          	addi	a0,a0,1125 # 3465 <g_font+0x1>
}
    2224:	00008067          	ret

00002228 <cpu_fill32>:
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    2228:	01079e93          	slli	t4,a5,0x10
    222c:	00fe8eb3          	add	t4,t4,a5
    int odd = (x & 1);            /* 起始列是否奇数（需要先写 1 个 16bit 像素凑对齐） */
    2230:	0015ff93          	andi	t6,a1,1
    for (j = 0; j < h; j++) {
    2234:	00000f13          	li	t5,0
    2238:	0480006f          	j	2280 <cpu_fill32+0x58>
        int rem = w;
    223c:	00068e13          	mv	t3,a3
    2240:	0700006f          	j	22b0 <cpu_fill32+0x88>
            for (i = 0; i < (rem >> 1); i++) q[i] = two;  /* 主体：4 字节对齐 */
    2244:	00281893          	slli	a7,a6,0x2
    2248:	011308b3          	add	a7,t1,a7
    224c:	01d8a023          	sw	t4,0(a7)
    2250:	00180813          	addi	a6,a6,1
    2254:	401e5893          	srai	a7,t3,0x1
    2258:	ff1846e3          	blt	a6,a7,2244 <cpu_fill32+0x1c>
        if (rem & 1) p[rem - 1] = color;                  /* 尾部：1 像素，16bit */
    225c:	001e7813          	andi	a6,t3,1
    2260:	00080e63          	beqz	a6,227c <cpu_fill32+0x54>
    2264:	80000837          	lui	a6,0x80000
    2268:	fff80813          	addi	a6,a6,-1 # 7fffffff <__freertos_irq_stack_top+0x7fff871f>
    226c:	010e0e33          	add	t3,t3,a6
    2270:	001e1e13          	slli	t3,t3,0x1
    2274:	01c30333          	add	t1,t1,t3
    2278:	00f31023          	sh	a5,0(t1)
    for (j = 0; j < h; j++) {
    227c:	001f0f13          	addi	t5,t5,1
    2280:	02ef5c63          	bge	t5,a4,22b8 <cpu_fill32+0x90>
        volatile uint16_t *p = (volatile uint16_t *)(base + (uint32_t)(y + j) * FB_STRIDE
    2284:	00cf0833          	add	a6,t5,a2
                                                          + (uint32_t)x * 2u);
    2288:	00481313          	slli	t1,a6,0x4
    228c:	41030333          	sub	t1,t1,a6
    2290:	00631313          	slli	t1,t1,0x6
    2294:	00b30333          	add	t1,t1,a1
    2298:	00131313          	slli	t1,t1,0x1
    229c:	00a30333          	add	t1,t1,a0
        if (odd) { *p++ = color; rem--; }                 /* 头部：1 像素，16bit，任意对齐 */
    22a0:	f80f8ee3          	beqz	t6,223c <cpu_fill32+0x14>
    22a4:	00f31023          	sh	a5,0(t1)
    22a8:	fff68e13          	addi	t3,a3,-1 # a5a4ffff <__freertos_irq_stack_top+0xa5a4871f>
    22ac:	00230313          	addi	t1,t1,2
            for (i = 0; i < (rem >> 1); i++) q[i] = two;  /* 主体：4 字节对齐 */
    22b0:	00000813          	li	a6,0
    22b4:	fa1ff06f          	j	2254 <cpu_fill32+0x2c>
}
    22b8:	00008067          	ret

000022bc <cpu_osd_text>:
{
    22bc:	fe010113          	addi	sp,sp,-32
    22c0:	00112e23          	sw	ra,28(sp)
    22c4:	00812c23          	sw	s0,24(sp)
    22c8:	00912a23          	sw	s1,20(sp)
    22cc:	01212823          	sw	s2,16(sp)
    22d0:	01312623          	sw	s3,12(sp)
    22d4:	01412423          	sw	s4,8(sp)
    22d8:	00050993          	mv	s3,a0
    22dc:	00058493          	mv	s1,a1
    22e0:	00060913          	mv	s2,a2
    22e4:	00068a13          	mv	s4,a3
    22e8:	00070413          	mv	s0,a4
    while (*s) {
    22ec:	0fc0006f          	j	23e8 <cpu_osd_text+0x12c>
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    22f0:	00000693          	li	a3,0
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    22f4:	01881613          	slli	a2,a6,0x18
    22f8:	41865613          	srai	a2,a2,0x18
    22fc:	02064063          	bltz	a2,231c <cpu_osd_text+0x60>
    2300:	00000613          	li	a2,0
    2304:	00c6e6b3          	or	a3,a3,a2
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2308:	00d7a023          	sw	a3,0(a5)
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    230c:	01087693          	andi	a3,a6,16
    2310:	00068a63          	beqz	a3,2324 <cpu_osd_text+0x68>
    2314:	01041693          	slli	a3,s0,0x10
    2318:	0100006f          	j	2328 <cpu_osd_text+0x6c>
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    231c:	00040613          	mv	a2,s0
    2320:	fe5ff06f          	j	2304 <cpu_osd_text+0x48>
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2324:	00000693          	li	a3,0
                 | ((bits & 0x20u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2328:	02087613          	andi	a2,a6,32
    232c:	00060663          	beqz	a2,2338 <cpu_osd_text+0x7c>
    2330:	00040613          	mv	a2,s0
    2334:	0080006f          	j	233c <cpu_osd_text+0x80>
    2338:	00000613          	li	a2,0
    233c:	00c6e6b3          	or	a3,a3,a2
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2340:	00d7a223          	sw	a3,4(a5)
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2344:	00487693          	andi	a3,a6,4
    2348:	00068663          	beqz	a3,2354 <cpu_osd_text+0x98>
    234c:	01041693          	slli	a3,s0,0x10
    2350:	0080006f          	j	2358 <cpu_osd_text+0x9c>
    2354:	00000693          	li	a3,0
                 | ((bits & 0x08u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2358:	00887613          	andi	a2,a6,8
    235c:	00060663          	beqz	a2,2368 <cpu_osd_text+0xac>
    2360:	00040613          	mv	a2,s0
    2364:	0080006f          	j	236c <cpu_osd_text+0xb0>
    2368:	00000613          	li	a2,0
    236c:	00c6e6b3          	or	a3,a3,a2
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2370:	00d7a423          	sw	a3,8(a5)
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2374:	00187693          	andi	a3,a6,1
    2378:	00068663          	beqz	a3,2384 <cpu_osd_text+0xc8>
    237c:	01041693          	slli	a3,s0,0x10
    2380:	0080006f          	j	2388 <cpu_osd_text+0xcc>
    2384:	00000693          	li	a3,0
                 | ((bits & 0x02u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2388:	00287813          	andi	a6,a6,2
    238c:	00080663          	beqz	a6,2398 <cpu_osd_text+0xdc>
    2390:	00040613          	mv	a2,s0
    2394:	0080006f          	j	239c <cpu_osd_text+0xe0>
    2398:	00000613          	li	a2,0
    239c:	00c6e6b3          	or	a3,a3,a2
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    23a0:	00d7a623          	sw	a3,12(a5)
        for (row = 0; row < 8; row++) {
    23a4:	00170713          	addi	a4,a4,1
    23a8:	00700793          	li	a5,7
    23ac:	02e7cc63          	blt	a5,a4,23e4 <cpu_osd_text+0x128>
            uint8_t bits = rp[row];
    23b0:	00e507b3          	add	a5,a0,a4
    23b4:	0007c803          	lbu	a6,0(a5)
            volatile uint32_t *p = (volatile uint32_t *)(base + (uint32_t)(y + row) * FB_STRIDE
    23b8:	012706b3          	add	a3,a4,s2
                                                              + (uint32_t)x * 2u);
    23bc:	00469793          	slli	a5,a3,0x4
    23c0:	40d787b3          	sub	a5,a5,a3
    23c4:	00679793          	slli	a5,a5,0x6
    23c8:	009787b3          	add	a5,a5,s1
    23cc:	00179793          	slli	a5,a5,0x1
    23d0:	013787b3          	add	a5,a5,s3
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    23d4:	04087693          	andi	a3,a6,64
    23d8:	f0068ce3          	beqz	a3,22f0 <cpu_osd_text+0x34>
    23dc:	01041693          	slli	a3,s0,0x10
    23e0:	f15ff06f          	j	22f4 <cpu_osd_text+0x38>
        x += 8;
    23e4:	00848493          	addi	s1,s1,8
    while (*s) {
    23e8:	000a4503          	lbu	a0,0(s4)
    23ec:	00050a63          	beqz	a0,2400 <cpu_osd_text+0x144>
        const uint8_t *rp = glyph_of(*s++);
    23f0:	001a0a13          	addi	s4,s4,1
    23f4:	dcdff0ef          	jal	21c0 <glyph_of>
        for (row = 0; row < 8; row++) {
    23f8:	00000713          	li	a4,0
    23fc:	fadff06f          	j	23a8 <cpu_osd_text+0xec>
}
    2400:	01c12083          	lw	ra,28(sp)
    2404:	01812403          	lw	s0,24(sp)
    2408:	01412483          	lw	s1,20(sp)
    240c:	01012903          	lw	s2,16(sp)
    2410:	00c12983          	lw	s3,12(sp)
    2414:	00812a03          	lw	s4,8(sp)
    2418:	02010113          	addi	sp,sp,32
    241c:	00008067          	ret

00002420 <lcg>:
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }
    2420:	00052783          	lw	a5,0(a0)
    2424:	00196737          	lui	a4,0x196
    2428:	60d70713          	addi	a4,a4,1549 # 19660d <__freertos_irq_stack_top+0x18ed2d>
    242c:	02e787b3          	mul	a5,a5,a4
    2430:	3c6ef737          	lui	a4,0x3c6ef
    2434:	35f70713          	addi	a4,a4,863 # 3c6ef35f <__freertos_irq_stack_top+0x3c6e7a7f>
    2438:	00e787b3          	add	a5,a5,a4
    243c:	00f52023          	sw	a5,0(a0)
    2440:	0107d513          	srli	a0,a5,0x10
    2444:	00008067          	ret

00002448 <scene_init>:
{
    2448:	fd010113          	addi	sp,sp,-48
    244c:	02112623          	sw	ra,44(sp)
    2450:	02812423          	sw	s0,40(sp)
    2454:	02912223          	sw	s1,36(sp)
    2458:	03212023          	sw	s2,32(sp)
    245c:	01312e23          	sw	s3,28(sp)
    2460:	01412c23          	sw	s4,24(sp)
    2464:	00050993          	mv	s3,a0
    2468:	00058a13          	mv	s4,a1
    for (side = 0; side < 2; side++) {
    246c:	00000913          	li	s2,0
    2470:	1480006f          	j	25b8 <scene_init+0x170>
            b->sz = (uint8_t)(((i % 3) == 0) ? 16 : (((i % 3) == 1) ? 24 : 32));
    2474:	01800693          	li	a3,24
    2478:	0080006f          	j	2480 <scene_init+0x38>
    247c:	01000693          	li	a3,16
    2480:	000037b7          	lui	a5,0x3
    2484:	19000713          	li	a4,400
    2488:	02e90733          	mul	a4,s2,a4
    248c:	00970733          	add	a4,a4,s1
    2490:	00471713          	slli	a4,a4,0x4
    2494:	6e078793          	addi	a5,a5,1760 # 36e0 <g_sc>
    2498:	00e787b3          	add	a5,a5,a4
    249c:	00d78723          	sb	a3,14(a5)
            b->vx = (int16_t)((int)(r1 % 7u) - 3);
    24a0:	00700693          	li	a3,7
    24a4:	02d476b3          	remu	a3,s0,a3
    24a8:	ffd68693          	addi	a3,a3,-3
    24ac:	00d79423          	sh	a3,8(a5)
            b->vy = (int16_t)((int)(r2 % 5u) - 2);
    24b0:	00500713          	li	a4,5
    24b4:	02e57733          	remu	a4,a0,a4
    24b8:	ffe70713          	addi	a4,a4,-2
    24bc:	00e79523          	sh	a4,10(a5)
            if (!b->vx) b->vx = 1;
    24c0:	02069463          	bnez	a3,24e8 <scene_init+0xa0>
    24c4:	000036b7          	lui	a3,0x3
    24c8:	19000793          	li	a5,400
    24cc:	02f907b3          	mul	a5,s2,a5
    24d0:	009787b3          	add	a5,a5,s1
    24d4:	00479793          	slli	a5,a5,0x4
    24d8:	6e068693          	addi	a3,a3,1760 # 36e0 <g_sc>
    24dc:	00f687b3          	add	a5,a3,a5
    24e0:	00100693          	li	a3,1
    24e4:	00d79423          	sh	a3,8(a5)
            if (!b->vy) b->vy = 1;
    24e8:	02071463          	bnez	a4,2510 <scene_init+0xc8>
    24ec:	00003737          	lui	a4,0x3
    24f0:	19000793          	li	a5,400
    24f4:	02f907b3          	mul	a5,s2,a5
    24f8:	009787b3          	add	a5,a5,s1
    24fc:	00479793          	slli	a5,a5,0x4
    2500:	6e070713          	addi	a4,a4,1760 # 36e0 <g_sc>
    2504:	00f707b3          	add	a5,a4,a5
    2508:	00100713          	li	a4,1
    250c:	00e79523          	sh	a4,10(a5)
            b->x  = (int16_t)((int)(r1 % 860u) & ~1);      /* 偶数对齐（32bit 写要求） */
    2510:	35c00713          	li	a4,860
    2514:	02e47733          	remu	a4,s0,a4
    2518:	3fe77713          	andi	a4,a4,1022
    251c:	000037b7          	lui	a5,0x3
    2520:	19000693          	li	a3,400
    2524:	02d90633          	mul	a2,s2,a3
    2528:	00960633          	add	a2,a2,s1
    252c:	00461613          	slli	a2,a2,0x4
    2530:	6e078793          	addi	a5,a5,1760 # 36e0 <g_sc>
    2534:	00c787b3          	add	a5,a5,a2
    2538:	00e79023          	sh	a4,0(a5)
            b->y  = (int16_t)((int)(r2 % 400u));
    253c:	02d576b3          	remu	a3,a0,a3
    2540:	00d79123          	sh	a3,2(a5)
            b->px = b->x; b->py = b->y;
    2544:	00e79223          	sh	a4,4(a5)
    2548:	00d79323          	sh	a3,6(a5)
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
    254c:	00845713          	srli	a4,s0,0x8
    2550:	00b71713          	slli	a4,a4,0xb
    2554:	01071713          	slli	a4,a4,0x10
    2558:	01075713          	srli	a4,a4,0x10
    255c:	00855693          	srli	a3,a0,0x8
    2560:	00569693          	slli	a3,a3,0x5
    2564:	7e06f693          	andi	a3,a3,2016
    2568:	00d76733          	or	a4,a4,a3
                                  | ((r1 + r2) & 0x1Fu));
    256c:	00a40433          	add	s0,s0,a0
    2570:	01f47413          	andi	s0,s0,31
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
    2574:	00876733          	or	a4,a4,s0
    2578:	00e79623          	sh	a4,12(a5)
        for (i = 0; i < n; i++) {
    257c:	00148493          	addi	s1,s1,1
    2580:	0334da63          	bge	s1,s3,25b4 <scene_init+0x16c>
            uint32_t r1 = lcg(&s), r2 = lcg(&s);
    2584:	00c10513          	addi	a0,sp,12
    2588:	e99ff0ef          	jal	2420 <lcg>
    258c:	00050413          	mv	s0,a0
    2590:	00c10513          	addi	a0,sp,12
    2594:	e8dff0ef          	jal	2420 <lcg>
            b->sz = (uint8_t)(((i % 3) == 0) ? 16 : (((i % 3) == 1) ? 24 : 32));
    2598:	00300793          	li	a5,3
    259c:	02f4e7b3          	rem	a5,s1,a5
    25a0:	ec078ee3          	beqz	a5,247c <scene_init+0x34>
    25a4:	00100713          	li	a4,1
    25a8:	ece786e3          	beq	a5,a4,2474 <scene_init+0x2c>
    25ac:	02000693          	li	a3,32
    25b0:	ed1ff06f          	j	2480 <scene_init+0x38>
    for (side = 0; side < 2; side++) {
    25b4:	00190913          	addi	s2,s2,1
    25b8:	00100793          	li	a5,1
    25bc:	0127c863          	blt	a5,s2,25cc <scene_init+0x184>
        uint32_t s = seed;
    25c0:	01412623          	sw	s4,12(sp)
        for (i = 0; i < n; i++) {
    25c4:	00000493          	li	s1,0
    25c8:	fb9ff06f          	j	2580 <scene_init+0x138>
}
    25cc:	02c12083          	lw	ra,44(sp)
    25d0:	02812403          	lw	s0,40(sp)
    25d4:	02412483          	lw	s1,36(sp)
    25d8:	02012903          	lw	s2,32(sp)
    25dc:	01c12983          	lw	s3,28(sp)
    25e0:	01812a03          	lw	s4,24(sp)
    25e4:	03010113          	addi	sp,sp,48
    25e8:	00008067          	ret

000025ec <scene_sync>:
    for (i = 0; i < n; i++) { sc[i].px = sc[i].x; sc[i].py = sc[i].y; }
    25ec:	00000713          	li	a4,0
    25f0:	0200006f          	j	2610 <scene_sync+0x24>
    25f4:	00471793          	slli	a5,a4,0x4
    25f8:	00f507b3          	add	a5,a0,a5
    25fc:	00079683          	lh	a3,0(a5)
    2600:	00d79223          	sh	a3,4(a5)
    2604:	00279683          	lh	a3,2(a5)
    2608:	00d79323          	sh	a3,6(a5)
    260c:	00170713          	addi	a4,a4,1
    2610:	feb742e3          	blt	a4,a1,25f4 <scene_sync+0x8>
}
    2614:	00008067          	ret

00002618 <scene_step>:
    int xmin = rg->x0, xmax = rg->x0 + rg->w;
    2618:	00062f03          	lw	t5,0(a2)
    261c:	00862383          	lw	t2,8(a2)
    2620:	01e383b3          	add	t2,t2,t5
    int ymin = rg->y0 + OSD_H + 4, ymax = rg->y0 + rg->h;
    2624:	00462283          	lw	t0,4(a2)
    2628:	01428f93          	addi	t6,t0,20
    262c:	00c62783          	lw	a5,12(a2)
    2630:	00f282b3          	add	t0,t0,a5
    for (i = 0; i < n; i++) {
    2634:	00000893          	li	a7,0
    2638:	0480006f          	j	2680 <scene_step+0x68>
        else if (x + w > xmax) { x = xmax - w; b->vx = (int16_t)(-b->vx); }
    263c:	01d70333          	add	t1,a4,t4
    2640:	0063dc63          	bge	t2,t1,2658 <scene_step+0x40>
    2644:	41d38733          	sub	a4,t2,t4
    2648:	01061613          	slli	a2,a2,0x10
    264c:	01065613          	srli	a2,a2,0x10
    2650:	40c00633          	neg	a2,a2
    2654:	00c79423          	sh	a2,8(a5)
        if (y < ymin)          { y = ymin;     b->vy = (int16_t)(-b->vy); }
    2658:	07f85a63          	bge	a6,t6,26cc <scene_step+0xb4>
    265c:	01069693          	slli	a3,a3,0x10
    2660:	0106d693          	srli	a3,a3,0x10
    2664:	40d006b3          	neg	a3,a3
    2668:	00d79523          	sh	a3,10(a5)
    266c:	000f8813          	mv	a6,t6
        b->x = (int16_t)(x & ~1);
    2670:	ffe77713          	andi	a4,a4,-2
    2674:	00e79023          	sh	a4,0(a5)
        b->y = (int16_t)y;
    2678:	01079123          	sh	a6,2(a5)
    for (i = 0; i < n; i++) {
    267c:	00188893          	addi	a7,a7,1
    2680:	06b8d663          	bge	a7,a1,26ec <scene_step+0xd4>
        blk_t *b = &sc[i];
    2684:	00489793          	slli	a5,a7,0x4
    2688:	00f507b3          	add	a5,a0,a5
        int x = b->x + b->vx, y = b->y + b->vy, w = b->sz;
    268c:	00079e03          	lh	t3,0(a5)
    2690:	00879603          	lh	a2,8(a5)
    2694:	00ce0733          	add	a4,t3,a2
    2698:	00279303          	lh	t1,2(a5)
    269c:	00a79683          	lh	a3,10(a5)
    26a0:	00d30833          	add	a6,t1,a3
    26a4:	00e7ce83          	lbu	t4,14(a5)
        b->px = b->x; b->py = b->y;
    26a8:	01c79223          	sh	t3,4(a5)
    26ac:	00679323          	sh	t1,6(a5)
        if (x < xmin)          { x = xmin;     b->vx = (int16_t)(-b->vx); }
    26b0:	f9e756e3          	bge	a4,t5,263c <scene_step+0x24>
    26b4:	01061613          	slli	a2,a2,0x10
    26b8:	01065613          	srli	a2,a2,0x10
    26bc:	40c00633          	neg	a2,a2
    26c0:	00c79423          	sh	a2,8(a5)
    26c4:	000f0713          	mv	a4,t5
    26c8:	f91ff06f          	j	2658 <scene_step+0x40>
        else if (y + w > ymax) { y = ymax - w; b->vy = (int16_t)(-b->vy); }
    26cc:	01d80633          	add	a2,a6,t4
    26d0:	fac2d0e3          	bge	t0,a2,2670 <scene_step+0x58>
    26d4:	41d28833          	sub	a6,t0,t4
    26d8:	01069693          	slli	a3,a3,0x10
    26dc:	0106d693          	srli	a3,a3,0x10
    26e0:	40d006b3          	neg	a3,a3
    26e4:	00d79523          	sh	a3,10(a5)
    26e8:	f89ff06f          	j	2670 <scene_step+0x58>
}
    26ec:	00008067          	ret

000026f0 <gpio_read_keys>:
    return (*(volatile uint32_t *)(SYSTEM_GPIO_A_APB + GPIO_INPUT_OFS)) & KEY_MASK;
    26f0:	f80157b7          	lui	a5,0xf8015
    26f4:	0007a503          	lw	a0,0(a5) # f8015000 <__freertos_irq_stack_top+0xf800d720>
}
    26f8:	00757513          	andi	a0,a0,7
    26fc:	00008067          	ret

00002700 <key_poll>:
{
    2700:	ff010113          	addi	sp,sp,-16
    2704:	00112623          	sw	ra,12(sp)
    uint32_t now = gpio_read_keys();
    2708:	fe9ff0ef          	jal	26f0 <gpio_read_keys>
    if (now != g_key_prev) {          /* 电平有变化 → 重新计稳定性 */
    270c:	8101a783          	lw	a5,-2032(gp) # 36c0 <g_key_prev>
    2710:	00a78e63          	beq	a5,a0,272c <key_poll+0x2c>
        g_key_prev = now;
    2714:	80a1a823          	sw	a0,-2032(gp) # 36c0 <g_key_prev>
        g_key_cnt  = 0;
    2718:	8201a623          	sw	zero,-2004(gp) # 36dc <g_key_cnt>
        return EV_NONE;
    271c:	00000513          	li	a0,0
}
    2720:	00c12083          	lw	ra,12(sp)
    2724:	01010113          	addi	sp,sp,16
    2728:	00008067          	ret
    if (g_key_cnt < KEY_DEBOUNCE) {
    272c:	82c1a783          	lw	a5,-2004(gp) # 36dc <g_key_cnt>
    2730:	00200713          	li	a4,2
    2734:	04f74863          	blt	a4,a5,2784 <key_poll+0x84>
        g_key_cnt++;
    2738:	00178793          	addi	a5,a5,1
    273c:	82f1a623          	sw	a5,-2004(gp) # 36dc <g_key_cnt>
        if (g_key_cnt == KEY_DEBOUNCE && now != g_key_stable) {
    2740:	00300713          	li	a4,3
    2744:	00e78663          	beq	a5,a4,2750 <key_poll+0x50>
    return EV_NONE;
    2748:	00000513          	li	a0,0
    274c:	fd5ff06f          	j	2720 <key_poll+0x20>
        if (g_key_cnt == KEY_DEBOUNCE && now != g_key_stable) {
    2750:	8141a783          	lw	a5,-2028(gp) # 36c4 <g_key_stable>
    2754:	02a78c63          	beq	a5,a0,278c <key_poll+0x8c>
            uint32_t down = g_key_stable & ~now;      /* 新按下的位 */
    2758:	fff54713          	not	a4,a0
    275c:	00e7f7b3          	and	a5,a5,a4
            g_key_stable = now;
    2760:	80a1aa23          	sw	a0,-2028(gp) # 36c4 <g_key_stable>
            if (down & 0x01u) return EV_MODE;         /* GPIOR_22：切模式 */
    2764:	0017f713          	andi	a4,a5,1
    2768:	02071663          	bnez	a4,2794 <key_poll+0x94>
            if (down & 0x02u) return EV_N_INC;        /* GPIOR_21：N +25 */
    276c:	0027f713          	andi	a4,a5,2
    2770:	02071663          	bnez	a4,279c <key_poll+0x9c>
            if (down & 0x04u) return EV_RESET;        /* GPIOL_03：场景复位 */
    2774:	0047f793          	andi	a5,a5,4
    2778:	02079663          	bnez	a5,27a4 <key_poll+0xa4>
    return EV_NONE;
    277c:	00000513          	li	a0,0
    2780:	fa1ff06f          	j	2720 <key_poll+0x20>
    2784:	00000513          	li	a0,0
    2788:	f99ff06f          	j	2720 <key_poll+0x20>
    278c:	00000513          	li	a0,0
    2790:	f91ff06f          	j	2720 <key_poll+0x20>
            if (down & 0x01u) return EV_MODE;         /* GPIOR_22：切模式 */
    2794:	00100513          	li	a0,1
    2798:	f89ff06f          	j	2720 <key_poll+0x20>
            if (down & 0x02u) return EV_N_INC;        /* GPIOR_21：N +25 */
    279c:	00200513          	li	a0,2
    27a0:	f81ff06f          	j	2720 <key_poll+0x20>
            if (down & 0x04u) return EV_RESET;        /* GPIOL_03：场景复位 */
    27a4:	00400513          	li	a0,4
    27a8:	f79ff06f          	j	2720 <key_poll+0x20>

000027ac <uart_status_raw>:
    return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS);
    27ac:	f80107b7          	lui	a5,0xf8010
    27b0:	0047a503          	lw	a0,4(a5) # f8010004 <__freertos_irq_stack_top+0xf8008724>
}
    27b4:	00008067          	ret

000027b8 <uart_rx_occ>:
static uint32_t uart_rx_occ(void) { return uart_status_raw() >> 24; }
    27b8:	ff010113          	addi	sp,sp,-16
    27bc:	00112623          	sw	ra,12(sp)
    27c0:	fedff0ef          	jal	27ac <uart_status_raw>
    27c4:	01855513          	srli	a0,a0,0x18
    27c8:	00c12083          	lw	ra,12(sp)
    27cc:	01010113          	addi	sp,sp,16
    27d0:	00008067          	ret

000027d4 <uart_poll_char>:
{
    27d4:	ff010113          	addi	sp,sp,-16
    27d8:	00112623          	sw	ra,12(sp)
    if (uart_rx_occ() == 0u) return 0;
    27dc:	fddff0ef          	jal	27b8 <uart_rx_occ>
    27e0:	00050e63          	beqz	a0,27fc <uart_poll_char+0x28>
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
    27e4:	f80107b7          	lui	a5,0xf8010
    27e8:	0007a503          	lw	a0,0(a5) # f8010000 <__freertos_irq_stack_top+0xf8008720>
    27ec:	0ff57513          	zext.b	a0,a0
}
    27f0:	00c12083          	lw	ra,12(sp)
    27f4:	01010113          	addi	sp,sp,16
    27f8:	00008067          	ret
    if (uart_rx_occ() == 0u) return 0;
    27fc:	00000513          	li	a0,0
    2800:	ff1ff06f          	j	27f0 <uart_poll_char+0x1c>

00002804 <input_poll>:
{
    2804:	ff010113          	addi	sp,sp,-16
    2808:	00112623          	sw	ra,12(sp)
    int c = uart_poll_char();
    280c:	fc9ff0ef          	jal	27d4 <uart_poll_char>
    if (c == 'm' || c == 'M') return EV_MODE;
    2810:	07200793          	li	a5,114
    2814:	04a7cc63          	blt	a5,a0,286c <input_poll+0x68>
    2818:	04d00793          	li	a5,77
    281c:	02f54463          	blt	a0,a5,2844 <input_poll+0x40>
    2820:	fb350513          	addi	a0,a0,-77
    2824:	02500793          	li	a5,37
    2828:	04a7e263          	bltu	a5,a0,286c <input_poll+0x68>
    282c:	00251513          	slli	a0,a0,0x2
    2830:	000037b7          	lui	a5,0x3
    2834:	34878793          	addi	a5,a5,840 # 3348 <_data+0x2dc>
    2838:	00f50533          	add	a0,a0,a5
    283c:	00052783          	lw	a5,0(a0)
    2840:	00078067          	jr	a5
    2844:	02b00793          	li	a5,43
    2848:	02f50a63          	beq	a0,a5,287c <input_poll+0x78>
    284c:	02d00793          	li	a5,45
    2850:	00f51e63          	bne	a0,a5,286c <input_poll+0x68>
    if (c == '-') return EV_N_DEC;
    2854:	00300513          	li	a0,3
    2858:	0180006f          	j	2870 <input_poll+0x6c>
    int c = uart_poll_char();
    285c:	00100513          	li	a0,1
    2860:	0100006f          	j	2870 <input_poll+0x6c>
    if (c == 'n' || c == 'N' || c == '+') return EV_N_INC;
    2864:	00200513          	li	a0,2
    2868:	0080006f          	j	2870 <input_poll+0x6c>
    return key_poll();
    286c:	e95ff0ef          	jal	2700 <key_poll>
}
    2870:	00c12083          	lw	ra,12(sp)
    2874:	01010113          	addi	sp,sp,16
    2878:	00008067          	ret
    if (c == 'n' || c == 'N' || c == '+') return EV_N_INC;
    287c:	00200513          	li	a0,2
    2880:	ff1ff06f          	j	2870 <input_poll+0x6c>
    if (c == 'r' || c == 'R') return EV_RESET;
    2884:	00400513          	li	a0,4
    2888:	fe9ff06f          	j	2870 <input_poll+0x6c>

0000288c <u2s>:
{
    288c:	ff010113          	addi	sp,sp,-16
    int  n = 0, i;
    2890:	00000793          	li	a5,0
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    2894:	00a00813          	li	a6,10
    2898:	0305f6b3          	remu	a3,a1,a6
    289c:	03068693          	addi	a3,a3,48
    28a0:	01078713          	addi	a4,a5,16
    28a4:	00270733          	add	a4,a4,sp
    28a8:	00178793          	addi	a5,a5,1
    28ac:	fed70a23          	sb	a3,-12(a4)
    28b0:	00058693          	mv	a3,a1
    28b4:	0305d5b3          	divu	a1,a1,a6
    28b8:	00900713          	li	a4,9
    28bc:	02d77863          	bgeu	a4,a3,28ec <u2s+0x60>
    28c0:	00a00713          	li	a4,10
    28c4:	fcf758e3          	bge	a4,a5,2894 <u2s+0x8>
    28c8:	00000713          	li	a4,0
    28cc:	0140006f          	j	28e0 <u2s+0x54>
    for (i = 0; i < width - n; i++) *buf++ = ' ';
    28d0:	02000693          	li	a3,32
    28d4:	00d50023          	sb	a3,0(a0)
    28d8:	00170713          	addi	a4,a4,1
    28dc:	00150513          	addi	a0,a0,1
    28e0:	40f606b3          	sub	a3,a2,a5
    28e4:	fed746e3          	blt	a4,a3,28d0 <u2s+0x44>
    28e8:	0240006f          	j	290c <u2s+0x80>
    28ec:	00000713          	li	a4,0
    28f0:	ff1ff06f          	j	28e0 <u2s+0x54>
    while (n) *buf++ = d[--n];
    28f4:	fff78793          	addi	a5,a5,-1
    28f8:	01078713          	addi	a4,a5,16
    28fc:	00270733          	add	a4,a4,sp
    2900:	ff474703          	lbu	a4,-12(a4)
    2904:	00e50023          	sb	a4,0(a0)
    2908:	00150513          	addi	a0,a0,1
    290c:	fe0794e3          	bnez	a5,28f4 <u2s+0x68>
    *buf = 0;
    2910:	00050023          	sb	zero,0(a0)
}
    2914:	01010113          	addi	sp,sp,16
    2918:	00008067          	ret

0000291c <app>:
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
    291c:	0100006f          	j	292c <app+0x10>
    2920:	00158593          	addi	a1,a1,1
    2924:	00f50023          	sb	a5,0(a0)
    2928:	00150513          	addi	a0,a0,1
    292c:	0005c783          	lbu	a5,0(a1)
    2930:	fe0798e3          	bnez	a5,2920 <app+0x4>
    2934:	00008067          	ret

00002938 <appn>:
static char *appn(char *p, unsigned v, int w) { char t[16]; u2s(t, v, w); return app(p, t); }
    2938:	fe010113          	addi	sp,sp,-32
    293c:	00112e23          	sw	ra,28(sp)
    2940:	00812c23          	sw	s0,24(sp)
    2944:	00050413          	mv	s0,a0
    2948:	00010513          	mv	a0,sp
    294c:	f41ff0ef          	jal	288c <u2s>
    2950:	00010593          	mv	a1,sp
    2954:	00040513          	mv	a0,s0
    2958:	fc5ff0ef          	jal	291c <app>
    295c:	01c12083          	lw	ra,28(sp)
    2960:	01812403          	lw	s0,24(sp)
    2964:	02010113          	addi	sp,sp,32
    2968:	00008067          	ret

0000296c <draw_osd>:
{
    296c:	fa010113          	addi	sp,sp,-96
    2970:	04112e23          	sw	ra,92(sp)
    2974:	04812c23          	sw	s0,88(sp)
    2978:	04912a23          	sw	s1,84(sp)
    297c:	05212823          	sw	s2,80(sp)
    2980:	05312623          	sw	s3,76(sp)
    2984:	05412423          	sw	s4,72(sp)
    2988:	05512223          	sw	s5,68(sp)
    298c:	00050493          	mv	s1,a0
    2990:	00058413          	mv	s0,a1
    2994:	00060a93          	mv	s5,a2
    2998:	00068a13          	mv	s4,a3
    299c:	00070993          	mv	s3,a4
    29a0:	00078913          	mv	s2,a5
    cpu_fill32(base, 0, OSD_Y0, FB_WIDTH, OSD_H, COL_OSD_BG);
    29a4:	00000793          	li	a5,0
    29a8:	01000713          	li	a4,16
    29ac:	3c000693          	li	a3,960
    29b0:	00000613          	li	a2,0
    29b4:	00000593          	li	a1,0
    29b8:	871ff0ef          	jal	2228 <cpu_fill32>
    p = app(p, (mode == 0) ? "CPU " : "HW ");
    29bc:	0a041c63          	bnez	s0,2a74 <draw_osd+0x108>
    29c0:	000035b7          	lui	a1,0x3
    29c4:	09458593          	addi	a1,a1,148 # 3094 <_data+0x28>
    29c8:	00010513          	mv	a0,sp
    29cc:	f51ff0ef          	jal	291c <app>
    p = appn(p, (unsigned)n, 3);
    29d0:	00300613          	li	a2,3
    29d4:	000a8593          	mv	a1,s5
    29d8:	f61ff0ef          	jal	2938 <appn>
    p = app(p, " N  ");
    29dc:	000035b7          	lui	a1,0x3
    29e0:	0a058593          	addi	a1,a1,160 # 30a0 <_data+0x34>
    29e4:	f39ff0ef          	jal	291c <app>
    p = appn(p, cpu_fps, 5);
    29e8:	00500613          	li	a2,5
    29ec:	000a0593          	mv	a1,s4
    29f0:	f49ff0ef          	jal	2938 <appn>
    p = app(p, " R/S  ");
    29f4:	000035b7          	lui	a1,0x3
    29f8:	0a858593          	addi	a1,a1,168 # 30a8 <_data+0x3c>
    29fc:	f21ff0ef          	jal	291c <app>
    p = appn(p, scr_fps, 5);
    2a00:	00500613          	li	a2,5
    2a04:	00098593          	mv	a1,s3
    2a08:	f31ff0ef          	jal	2938 <appn>
    p = app(p, " S/S  ");
    2a0c:	000035b7          	lui	a1,0x3
    2a10:	0b058593          	addi	a1,a1,176 # 30b0 <_data+0x44>
    2a14:	f09ff0ef          	jal	291c <app>
    p = appn(p, it_k, 5);
    2a18:	00500613          	li	a2,5
    2a1c:	00090593          	mv	a1,s2
    2a20:	f19ff0ef          	jal	2938 <appn>
    p = app(p, " K");
    2a24:	000035b7          	lui	a1,0x3
    2a28:	0b858593          	addi	a1,a1,184 # 30b8 <_data+0x4c>
    2a2c:	ef1ff0ef          	jal	291c <app>
    *p = 0;
    2a30:	00050023          	sb	zero,0(a0)
    cpu_osd_text(base, 8, OSD_Y0 + 4, line, (mode == 0) ? COL_CPU_FG : COL_HW_FG);
    2a34:	04041663          	bnez	s0,2a80 <draw_osd+0x114>
    2a38:	7ff00713          	li	a4,2047
    2a3c:	00010693          	mv	a3,sp
    2a40:	00400613          	li	a2,4
    2a44:	00800593          	li	a1,8
    2a48:	00048513          	mv	a0,s1
    2a4c:	871ff0ef          	jal	22bc <cpu_osd_text>
}
    2a50:	05c12083          	lw	ra,92(sp)
    2a54:	05812403          	lw	s0,88(sp)
    2a58:	05412483          	lw	s1,84(sp)
    2a5c:	05012903          	lw	s2,80(sp)
    2a60:	04c12983          	lw	s3,76(sp)
    2a64:	04812a03          	lw	s4,72(sp)
    2a68:	04412a83          	lw	s5,68(sp)
    2a6c:	06010113          	addi	sp,sp,96
    2a70:	00008067          	ret
    p = app(p, (mode == 0) ? "CPU " : "HW ");
    2a74:	000035b7          	lui	a1,0x3
    2a78:	09c58593          	addi	a1,a1,156 # 309c <_data+0x30>
    2a7c:	f4dff06f          	j	29c8 <draw_osd+0x5c>
    cpu_osd_text(base, 8, OSD_Y0 + 4, line, (mode == 0) ? COL_CPU_FG : COL_HW_FG);
    2a80:	00010737          	lui	a4,0x10
    2a84:	fe070713          	addi	a4,a4,-32 # ffe0 <__freertos_irq_stack_top+0x8700>
    2a88:	fb5ff06f          	j	2a3c <draw_osd+0xd0>

00002a8c <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    2a8c:	fc010113          	addi	sp,sp,-64
    2a90:	00112e23          	sw	ra,28(sp)
    2a94:	00812c23          	sw	s0,24(sp)
    2a98:	00912a23          	sw	s1,20(sp)
    2a9c:	00050493          	mv	s1,a0
    2aa0:	02b12223          	sw	a1,36(sp)
    2aa4:	02c12423          	sw	a2,40(sp)
    2aa8:	02d12623          	sw	a3,44(sp)
    2aac:	02e12823          	sw	a4,48(sp)
    2ab0:	02f12a23          	sw	a5,52(sp)
    2ab4:	03012c23          	sw	a6,56(sp)
    2ab8:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    2abc:	02410793          	addi	a5,sp,36
    2ac0:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    2ac4:	00000413          	li	s0,0
    2ac8:	01c0006f          	j	2ae4 <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    2acc:	00c12783          	lw	a5,12(sp)
    2ad0:	00478713          	addi	a4,a5,4
    2ad4:	00e12623          	sw	a4,12(sp)
    2ad8:	0007a503          	lw	a0,0(a5)
    2adc:	ac8ff0ef          	jal	1da4 <bsp_printf_c>
        for (i = 0; format[i]; i++)
    2ae0:	00140413          	addi	s0,s0,1
    2ae4:	008487b3          	add	a5,s1,s0
    2ae8:	0007c503          	lbu	a0,0(a5)
    2aec:	0a050e63          	beqz	a0,2ba8 <bsp_printf+0x11c>
            if (format[i] == '%') {
    2af0:	02500793          	li	a5,37
    2af4:	06f50e63          	beq	a0,a5,2b70 <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    2af8:	aacff0ef          	jal	1da4 <bsp_printf_c>
    2afc:	fe5ff06f          	j	2ae0 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    2b00:	00c12783          	lw	a5,12(sp)
    2b04:	00478713          	addi	a4,a5,4
    2b08:	00e12623          	sw	a4,12(sp)
    2b0c:	0007a503          	lw	a0,0(a5)
    2b10:	ab0ff0ef          	jal	1dc0 <bsp_printf_s>
                        break;
    2b14:	fcdff06f          	j	2ae0 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    2b18:	00c12783          	lw	a5,12(sp)
    2b1c:	00478713          	addi	a4,a5,4
    2b20:	00e12623          	sw	a4,12(sp)
    2b24:	0007a503          	lw	a0,0(a5)
    2b28:	ab0ff0ef          	jal	1dd8 <bsp_printf_d>
                        break;
    2b2c:	fb5ff06f          	j	2ae0 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    2b30:	00c12783          	lw	a5,12(sp)
    2b34:	00478713          	addi	a4,a5,4
    2b38:	00e12623          	sw	a4,12(sp)
    2b3c:	0007a503          	lw	a0,0(a5)
    2b40:	b58ff0ef          	jal	1e98 <bsp_printf_X>
                        break;
    2b44:	f9dff06f          	j	2ae0 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    2b48:	00c12783          	lw	a5,12(sp)
    2b4c:	00478713          	addi	a4,a5,4
    2b50:	00e12623          	sw	a4,12(sp)
    2b54:	0007a503          	lw	a0,0(a5)
    2b58:	b00ff0ef          	jal	1e58 <bsp_printf_x>
                        break;
    2b5c:	f85ff06f          	j	2ae0 <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    2b60:	00003537          	lui	a0,0x3
    2b64:	0bc50513          	addi	a0,a0,188 # 30bc <_data+0x50>
    2b68:	a58ff0ef          	jal	1dc0 <bsp_printf_s>
                        break;
    2b6c:	f75ff06f          	j	2ae0 <bsp_printf+0x54>
                while (format[++i]) {
    2b70:	00140413          	addi	s0,s0,1
    2b74:	008487b3          	add	a5,s1,s0
    2b78:	0007c783          	lbu	a5,0(a5)
    2b7c:	f60782e3          	beqz	a5,2ae0 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    2b80:	fa878793          	addi	a5,a5,-88
    2b84:	0ff7f693          	zext.b	a3,a5
    2b88:	02000713          	li	a4,32
    2b8c:	fed762e3          	bltu	a4,a3,2b70 <bsp_printf+0xe4>
    2b90:	00269793          	slli	a5,a3,0x2
    2b94:	00003737          	lui	a4,0x3
    2b98:	3e070713          	addi	a4,a4,992 # 33e0 <_data+0x374>
    2b9c:	00e787b3          	add	a5,a5,a4
    2ba0:	0007a783          	lw	a5,0(a5)
    2ba4:	00078067          	jr	a5

        va_end(ap);
    }
    2ba8:	01c12083          	lw	ra,28(sp)
    2bac:	01812403          	lw	s0,24(sp)
    2bb0:	01412483          	lw	s1,20(sp)
    2bb4:	04010113          	addi	sp,sp,64
    2bb8:	00008067          	ret

00002bbc <__udivdi3>:
    2bbc:	00060813          	mv	a6,a2
    2bc0:	00050893          	mv	a7,a0
    2bc4:	00058713          	mv	a4,a1
    2bc8:	0e069063          	bnez	a3,2ca8 <__udivdi3+0xec>
    2bcc:	12c5fe63          	bgeu	a1,a2,2d08 <__udivdi3+0x14c>
    2bd0:	000107b7          	lui	a5,0x10
    2bd4:	1ef66e63          	bltu	a2,a5,2dd0 <__udivdi3+0x214>
    2bd8:	010007b7          	lui	a5,0x1000
    2bdc:	01800693          	li	a3,24
    2be0:	00f67463          	bgeu	a2,a5,2be8 <__udivdi3+0x2c>
    2be4:	01000693          	li	a3,16
    2be8:	00d65333          	srl	t1,a2,a3
    2bec:	00001797          	auipc	a5,0x1
    2bf0:	9d078793          	addi	a5,a5,-1584 # 35bc <__clz_tab>
    2bf4:	006787b3          	add	a5,a5,t1
    2bf8:	0007c783          	lbu	a5,0(a5)
    2bfc:	02000313          	li	t1,32
    2c00:	00d787b3          	add	a5,a5,a3
    2c04:	40f306b3          	sub	a3,t1,a5
    2c08:	00f30c63          	beq	t1,a5,2c20 <__udivdi3+0x64>
    2c0c:	00d59733          	sll	a4,a1,a3
    2c10:	00f557b3          	srl	a5,a0,a5
    2c14:	00d61833          	sll	a6,a2,a3
    2c18:	00e7e733          	or	a4,a5,a4
    2c1c:	00d518b3          	sll	a7,a0,a3
    2c20:	01085613          	srli	a2,a6,0x10
    2c24:	02c75533          	divu	a0,a4,a2
    2c28:	01081693          	slli	a3,a6,0x10
    2c2c:	0106d693          	srli	a3,a3,0x10
    2c30:	0108d793          	srli	a5,a7,0x10
    2c34:	02c77733          	remu	a4,a4,a2
    2c38:	02a685b3          	mul	a1,a3,a0
    2c3c:	01071713          	slli	a4,a4,0x10
    2c40:	00e7e7b3          	or	a5,a5,a4
    2c44:	00b7fc63          	bgeu	a5,a1,2c5c <__udivdi3+0xa0>
    2c48:	00f807b3          	add	a5,a6,a5
    2c4c:	fff50713          	addi	a4,a0,-1
    2c50:	0107e463          	bltu	a5,a6,2c58 <__udivdi3+0x9c>
    2c54:	40b7e063          	bltu	a5,a1,3054 <__udivdi3+0x498>
    2c58:	00070513          	mv	a0,a4
    2c5c:	40b787b3          	sub	a5,a5,a1
    2c60:	02c7d733          	divu	a4,a5,a2
    2c64:	01089893          	slli	a7,a7,0x10
    2c68:	0108d893          	srli	a7,a7,0x10
    2c6c:	02c7f7b3          	remu	a5,a5,a2
    2c70:	02e686b3          	mul	a3,a3,a4
    2c74:	01079793          	slli	a5,a5,0x10
    2c78:	00f8e8b3          	or	a7,a7,a5
    2c7c:	00d8fe63          	bgeu	a7,a3,2c98 <__udivdi3+0xdc>
    2c80:	011808b3          	add	a7,a6,a7
    2c84:	fff70793          	addi	a5,a4,-1
    2c88:	0108e663          	bltu	a7,a6,2c94 <__udivdi3+0xd8>
    2c8c:	ffe70713          	addi	a4,a4,-2
    2c90:	00d8e463          	bltu	a7,a3,2c98 <__udivdi3+0xdc>
    2c94:	00078713          	mv	a4,a5
    2c98:	01051513          	slli	a0,a0,0x10
    2c9c:	00e56533          	or	a0,a0,a4
    2ca0:	00000593          	li	a1,0
    2ca4:	00008067          	ret
    2ca8:	00d5f863          	bgeu	a1,a3,2cb8 <__udivdi3+0xfc>
    2cac:	00000593          	li	a1,0
    2cb0:	00000513          	li	a0,0
    2cb4:	00008067          	ret
    2cb8:	000107b7          	lui	a5,0x10
    2cbc:	1ef6e863          	bltu	a3,a5,2eac <__udivdi3+0x2f0>
    2cc0:	01000737          	lui	a4,0x1000
    2cc4:	01800793          	li	a5,24
    2cc8:	00e6f463          	bgeu	a3,a4,2cd0 <__udivdi3+0x114>
    2ccc:	01000793          	li	a5,16
    2cd0:	00f6d833          	srl	a6,a3,a5
    2cd4:	00001717          	auipc	a4,0x1
    2cd8:	8e870713          	addi	a4,a4,-1816 # 35bc <__clz_tab>
    2cdc:	01070733          	add	a4,a4,a6
    2ce0:	00074703          	lbu	a4,0(a4)
    2ce4:	02000893          	li	a7,32
    2ce8:	00f70733          	add	a4,a4,a5
    2cec:	40e88833          	sub	a6,a7,a4
    2cf0:	1ee89663          	bne	a7,a4,2edc <__udivdi3+0x320>
    2cf4:	32b6e463          	bltu	a3,a1,301c <__udivdi3+0x460>
    2cf8:	00c53533          	sltu	a0,a0,a2
    2cfc:	00153513          	seqz	a0,a0
    2d00:	00000593          	li	a1,0
    2d04:	00008067          	ret
    2d08:	0c060c63          	beqz	a2,2de0 <__udivdi3+0x224>
    2d0c:	000107b7          	lui	a5,0x10
    2d10:	2ef67c63          	bgeu	a2,a5,3008 <__udivdi3+0x44c>
    2d14:	10063713          	sltiu	a4,a2,256
    2d18:	00173713          	seqz	a4,a4
    2d1c:	00371713          	slli	a4,a4,0x3
    2d20:	00e656b3          	srl	a3,a2,a4
    2d24:	00001797          	auipc	a5,0x1
    2d28:	89878793          	addi	a5,a5,-1896 # 35bc <__clz_tab>
    2d2c:	00d787b3          	add	a5,a5,a3
    2d30:	0007c783          	lbu	a5,0(a5)
    2d34:	02000693          	li	a3,32
    2d38:	00e787b3          	add	a5,a5,a4
    2d3c:	40f68eb3          	sub	t4,a3,a5
    2d40:	0cf69463          	bne	a3,a5,2e08 <__udivdi3+0x24c>
    2d44:	40c587b3          	sub	a5,a1,a2
    2d48:	01065693          	srli	a3,a2,0x10
    2d4c:	01061613          	slli	a2,a2,0x10
    2d50:	01065613          	srli	a2,a2,0x10
    2d54:	00100593          	li	a1,1
    2d58:	02d7d533          	divu	a0,a5,a3
    2d5c:	0108d713          	srli	a4,a7,0x10
    2d60:	02d7f7b3          	remu	a5,a5,a3
    2d64:	02c50333          	mul	t1,a0,a2
    2d68:	01079793          	slli	a5,a5,0x10
    2d6c:	00f767b3          	or	a5,a4,a5
    2d70:	0067fc63          	bgeu	a5,t1,2d88 <__udivdi3+0x1cc>
    2d74:	00f807b3          	add	a5,a6,a5
    2d78:	fff50713          	addi	a4,a0,-1
    2d7c:	0107e463          	bltu	a5,a6,2d84 <__udivdi3+0x1c8>
    2d80:	2c67e463          	bltu	a5,t1,3048 <__udivdi3+0x48c>
    2d84:	00070513          	mv	a0,a4
    2d88:	406787b3          	sub	a5,a5,t1
    2d8c:	02d7d733          	divu	a4,a5,a3
    2d90:	01089893          	slli	a7,a7,0x10
    2d94:	0108d893          	srli	a7,a7,0x10
    2d98:	02d7f7b3          	remu	a5,a5,a3
    2d9c:	02c70633          	mul	a2,a4,a2
    2da0:	01079793          	slli	a5,a5,0x10
    2da4:	00f8e8b3          	or	a7,a7,a5
    2da8:	00c8fe63          	bgeu	a7,a2,2dc4 <__udivdi3+0x208>
    2dac:	011808b3          	add	a7,a6,a7
    2db0:	fff70793          	addi	a5,a4,-1
    2db4:	0108e663          	bltu	a7,a6,2dc0 <__udivdi3+0x204>
    2db8:	ffe70713          	addi	a4,a4,-2
    2dbc:	00c8e463          	bltu	a7,a2,2dc4 <__udivdi3+0x208>
    2dc0:	00078713          	mv	a4,a5
    2dc4:	01051513          	slli	a0,a0,0x10
    2dc8:	00e56533          	or	a0,a0,a4
    2dcc:	00008067          	ret
    2dd0:	10063693          	sltiu	a3,a2,256
    2dd4:	0016b693          	seqz	a3,a3
    2dd8:	00369693          	slli	a3,a3,0x3
    2ddc:	e0dff06f          	j	2be8 <__udivdi3+0x2c>
    2de0:	00000693          	li	a3,0
    2de4:	00000797          	auipc	a5,0x0
    2de8:	7d878793          	addi	a5,a5,2008 # 35bc <__clz_tab>
    2dec:	00d787b3          	add	a5,a5,a3
    2df0:	0007c783          	lbu	a5,0(a5)
    2df4:	00000713          	li	a4,0
    2df8:	02000693          	li	a3,32
    2dfc:	00e787b3          	add	a5,a5,a4
    2e00:	40f68eb3          	sub	t4,a3,a5
    2e04:	f4f680e3          	beq	a3,a5,2d44 <__udivdi3+0x188>
    2e08:	01d61833          	sll	a6,a2,t4
    2e0c:	00f5d333          	srl	t1,a1,a5
    2e10:	01085693          	srli	a3,a6,0x10
    2e14:	02d35e33          	divu	t3,t1,a3
    2e18:	01081613          	slli	a2,a6,0x10
    2e1c:	01d595b3          	sll	a1,a1,t4
    2e20:	01065613          	srli	a2,a2,0x10
    2e24:	00f557b3          	srl	a5,a0,a5
    2e28:	00b7e7b3          	or	a5,a5,a1
    2e2c:	0107d713          	srli	a4,a5,0x10
    2e30:	01d518b3          	sll	a7,a0,t4
    2e34:	02d37333          	remu	t1,t1,a3
    2e38:	03c605b3          	mul	a1,a2,t3
    2e3c:	01031313          	slli	t1,t1,0x10
    2e40:	00676733          	or	a4,a4,t1
    2e44:	00b77e63          	bgeu	a4,a1,2e60 <__udivdi3+0x2a4>
    2e48:	00e80733          	add	a4,a6,a4
    2e4c:	fffe0513          	addi	a0,t3,-1
    2e50:	1f076463          	bltu	a4,a6,3038 <__udivdi3+0x47c>
    2e54:	1eb77263          	bgeu	a4,a1,3038 <__udivdi3+0x47c>
    2e58:	ffee0e13          	addi	t3,t3,-2
    2e5c:	01070733          	add	a4,a4,a6
    2e60:	40b70733          	sub	a4,a4,a1
    2e64:	02d75533          	divu	a0,a4,a3
    2e68:	01079793          	slli	a5,a5,0x10
    2e6c:	0107d793          	srli	a5,a5,0x10
    2e70:	02d77733          	remu	a4,a4,a3
    2e74:	02a60333          	mul	t1,a2,a0
    2e78:	01071713          	slli	a4,a4,0x10
    2e7c:	00e7e7b3          	or	a5,a5,a4
    2e80:	0067fe63          	bgeu	a5,t1,2e9c <__udivdi3+0x2e0>
    2e84:	00f807b3          	add	a5,a6,a5
    2e88:	fff50713          	addi	a4,a0,-1
    2e8c:	1907ee63          	bltu	a5,a6,3028 <__udivdi3+0x46c>
    2e90:	1867fc63          	bgeu	a5,t1,3028 <__udivdi3+0x46c>
    2e94:	ffe50513          	addi	a0,a0,-2
    2e98:	010787b3          	add	a5,a5,a6
    2e9c:	010e1593          	slli	a1,t3,0x10
    2ea0:	406787b3          	sub	a5,a5,t1
    2ea4:	00a5e5b3          	or	a1,a1,a0
    2ea8:	eb1ff06f          	j	2d58 <__udivdi3+0x19c>
    2eac:	1006b793          	sltiu	a5,a3,256
    2eb0:	0017b793          	seqz	a5,a5
    2eb4:	00379793          	slli	a5,a5,0x3
    2eb8:	00f6d833          	srl	a6,a3,a5
    2ebc:	00000717          	auipc	a4,0x0
    2ec0:	70070713          	addi	a4,a4,1792 # 35bc <__clz_tab>
    2ec4:	01070733          	add	a4,a4,a6
    2ec8:	00074703          	lbu	a4,0(a4)
    2ecc:	02000893          	li	a7,32
    2ed0:	00f70733          	add	a4,a4,a5
    2ed4:	40e88833          	sub	a6,a7,a4
    2ed8:	e0e88ee3          	beq	a7,a4,2cf4 <__udivdi3+0x138>
    2edc:	00e65e33          	srl	t3,a2,a4
    2ee0:	010696b3          	sll	a3,a3,a6
    2ee4:	00de6e33          	or	t3,t3,a3
    2ee8:	00e5d8b3          	srl	a7,a1,a4
    2eec:	010e5e93          	srli	t4,t3,0x10
    2ef0:	03d8d7b3          	divu	a5,a7,t4
    2ef4:	010e1313          	slli	t1,t3,0x10
    2ef8:	010595b3          	sll	a1,a1,a6
    2efc:	01035313          	srli	t1,t1,0x10
    2f00:	00e55733          	srl	a4,a0,a4
    2f04:	00b76733          	or	a4,a4,a1
    2f08:	01075693          	srli	a3,a4,0x10
    2f0c:	01061633          	sll	a2,a2,a6
    2f10:	03d8f8b3          	remu	a7,a7,t4
    2f14:	02f305b3          	mul	a1,t1,a5
    2f18:	01089893          	slli	a7,a7,0x10
    2f1c:	0116e6b3          	or	a3,a3,a7
    2f20:	00b6fe63          	bgeu	a3,a1,2f3c <__udivdi3+0x380>
    2f24:	00de06b3          	add	a3,t3,a3
    2f28:	fff78893          	addi	a7,a5,-1
    2f2c:	11c6ea63          	bltu	a3,t3,3040 <__udivdi3+0x484>
    2f30:	10b6f863          	bgeu	a3,a1,3040 <__udivdi3+0x484>
    2f34:	ffe78793          	addi	a5,a5,-2
    2f38:	01c686b3          	add	a3,a3,t3
    2f3c:	40b686b3          	sub	a3,a3,a1
    2f40:	03d6d5b3          	divu	a1,a3,t4
    2f44:	01071713          	slli	a4,a4,0x10
    2f48:	01075713          	srli	a4,a4,0x10
    2f4c:	03d6f6b3          	remu	a3,a3,t4
    2f50:	02b308b3          	mul	a7,t1,a1
    2f54:	01069693          	slli	a3,a3,0x10
    2f58:	00d76733          	or	a4,a4,a3
    2f5c:	01177e63          	bgeu	a4,a7,2f78 <__udivdi3+0x3bc>
    2f60:	00ee0733          	add	a4,t3,a4
    2f64:	fff58693          	addi	a3,a1,-1
    2f68:	0dc76463          	bltu	a4,t3,3030 <__udivdi3+0x474>
    2f6c:	0d177263          	bgeu	a4,a7,3030 <__udivdi3+0x474>
    2f70:	ffe58593          	addi	a1,a1,-2
    2f74:	01c70733          	add	a4,a4,t3
    2f78:	01079793          	slli	a5,a5,0x10
    2f7c:	00010eb7          	lui	t4,0x10
    2f80:	00b7e7b3          	or	a5,a5,a1
    2f84:	fffe8693          	addi	a3,t4,-1 # ffff <__freertos_irq_stack_top+0x871f>
    2f88:	00d7f5b3          	and	a1,a5,a3
    2f8c:	0107d313          	srli	t1,a5,0x10
    2f90:	00d676b3          	and	a3,a2,a3
    2f94:	01065613          	srli	a2,a2,0x10
    2f98:	02d58e33          	mul	t3,a1,a3
    2f9c:	41170733          	sub	a4,a4,a7
    2fa0:	02d306b3          	mul	a3,t1,a3
    2fa4:	010e5893          	srli	a7,t3,0x10
    2fa8:	02c585b3          	mul	a1,a1,a2
    2fac:	00d585b3          	add	a1,a1,a3
    2fb0:	00b885b3          	add	a1,a7,a1
    2fb4:	02c30333          	mul	t1,t1,a2
    2fb8:	00d5f463          	bgeu	a1,a3,2fc0 <__udivdi3+0x404>
    2fbc:	01d30333          	add	t1,t1,t4
    2fc0:	0105d693          	srli	a3,a1,0x10
    2fc4:	006686b3          	add	a3,a3,t1
    2fc8:	02d76a63          	bltu	a4,a3,2ffc <__udivdi3+0x440>
    2fcc:	00d70863          	beq	a4,a3,2fdc <__udivdi3+0x420>
    2fd0:	00078513          	mv	a0,a5
    2fd4:	00000593          	li	a1,0
    2fd8:	00008067          	ret
    2fdc:	000106b7          	lui	a3,0x10
    2fe0:	fff68693          	addi	a3,a3,-1 # ffff <__freertos_irq_stack_top+0x871f>
    2fe4:	00d5f733          	and	a4,a1,a3
    2fe8:	01071713          	slli	a4,a4,0x10
    2fec:	00de7e33          	and	t3,t3,a3
    2ff0:	01051533          	sll	a0,a0,a6
    2ff4:	01c70733          	add	a4,a4,t3
    2ff8:	fce57ce3          	bgeu	a0,a4,2fd0 <__udivdi3+0x414>
    2ffc:	fff78513          	addi	a0,a5,-1
    3000:	00000593          	li	a1,0
    3004:	00008067          	ret
    3008:	010007b7          	lui	a5,0x1000
    300c:	04f67a63          	bgeu	a2,a5,3060 <__udivdi3+0x4a4>
    3010:	01065693          	srli	a3,a2,0x10
    3014:	01000713          	li	a4,16
    3018:	d0dff06f          	j	2d24 <__udivdi3+0x168>
    301c:	00000593          	li	a1,0
    3020:	00100513          	li	a0,1
    3024:	00008067          	ret
    3028:	00070513          	mv	a0,a4
    302c:	e71ff06f          	j	2e9c <__udivdi3+0x2e0>
    3030:	00068593          	mv	a1,a3
    3034:	f45ff06f          	j	2f78 <__udivdi3+0x3bc>
    3038:	00050e13          	mv	t3,a0
    303c:	e25ff06f          	j	2e60 <__udivdi3+0x2a4>
    3040:	00088793          	mv	a5,a7
    3044:	ef9ff06f          	j	2f3c <__udivdi3+0x380>
    3048:	ffe50513          	addi	a0,a0,-2
    304c:	010787b3          	add	a5,a5,a6
    3050:	d39ff06f          	j	2d88 <__udivdi3+0x1cc>
    3054:	ffe50513          	addi	a0,a0,-2
    3058:	010787b3          	add	a5,a5,a6
    305c:	c01ff06f          	j	2c5c <__udivdi3+0xa0>
    3060:	01865693          	srli	a3,a2,0x18
    3064:	01800713          	li	a4,24
    3068:	cbdff06f          	j	2d24 <__udivdi3+0x168>
