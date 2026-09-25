
build/comptest2.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00004197          	auipc	gp,0x4
    1004:	8c818193          	addi	gp,gp,-1848 # 48c8 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	0000b117          	auipc	sp,0xb
    100c:	e4810113          	addi	sp,sp,-440 # be50 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00002517          	auipc	a0,0x2
    1014:	6fc50513          	addi	a0,a0,1788 # 370c <_data>
	la a1, _data
    1018:	00002597          	auipc	a1,0x2
    101c:	6f458593          	addi	a1,a1,1780 # 370c <_data>
	la a2, _edata
    1020:	00003617          	auipc	a2,0x3
    1024:	0c460613          	addi	a2,a2,196 # 40e4 <g_sc>
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
    1040:	00003517          	auipc	a0,0x3
    1044:	0a450513          	addi	a0,a0,164 # 40e4 <g_sc>
	la a1, _end
    1048:	0000a597          	auipc	a1,0xa
    104c:	e0058593          	addi	a1,a1,-512 # ae48 <_end>
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
    1080:	69078793          	addi	a5,a5,1680 # 370c <_data>
    1084:	00002417          	auipc	s0,0x2
    1088:	68840413          	addi	s0,s0,1672 # 370c <_data>
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
    10bc:	65478793          	addi	a5,a5,1620 # 370c <_data>
    10c0:	00002417          	auipc	s0,0x2
    10c4:	64c40413          	addi	s0,s0,1612 # 370c <_data>
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
 *   原来固定成 HALF_H，所以即便单模式给了整屏高度，物块也只在上面 260 行里弹
 *   —— 就是"切到纯 CPU/纯硬件时仍只渲染一半"的原因。 */
static int vrg_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }

int main(int argc, char **argv)
{
    1104:	ef010113          	addi	sp,sp,-272
    1108:	10112623          	sw	ra,268(sp)
    110c:	10812423          	sw	s0,264(sp)
    1110:	10912223          	sw	s1,260(sp)
    1114:	11212023          	sw	s2,256(sp)
    1118:	0f312e23          	sw	s3,252(sp)
    111c:	0f412c23          	sw	s4,248(sp)
    1120:	0f512a23          	sw	s5,244(sp)
    1124:	0f612823          	sw	s6,240(sp)
    1128:	0f712623          	sw	s7,236(sp)
    112c:	0f812423          	sw	s8,232(sp)
    1130:	0f912223          	sw	s9,228(sp)
    1134:	0fa12023          	sw	s10,224(sp)
    1138:	0db12e23          	sw	s11,220(sp)
    int hw_done = 0, cpu_done = 0, back_busy = 0;
    uint32_t disp_frames = 0, disp_fps = 0;
    uint32_t back_t0 = 0;

    rect_t vrg;
    vrg.x0 = 0; vrg.y0 = 0; vrg.w = FB_WIDTH; vrg.h = HALF_H;
    113c:	0c012023          	sw	zero,192(sp)
    1140:	0c012223          	sw	zero,196(sp)
    1144:	3c000793          	li	a5,960
    1148:	0cf12423          	sw	a5,200(sp)
    114c:	10400793          	li	a5,260
    1150:	0cf12623          	sw	a5,204(sp)

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */
    1154:	224010ef          	jal	2378 <bsp_init>

    bsp_printf("\r\n===== comptest2: HW accel vs pure CPU, same screen =====\r\n");
    1158:	00003537          	lui	a0,0x3
    115c:	7b850513          	addi	a0,a0,1976 # 37b8 <_data+0xac>
    1160:	7cd010ef          	jal	312c <bsp_printf>
    bsp_printf("FB=%x BACK=%x ATLAS=%x SPR=%dx%d\r\n",
    1164:	02000793          	li	a5,32
    1168:	02000713          	li	a4,32
    116c:	002016b7          	lui	a3,0x201
    1170:	00501637          	lui	a2,0x501
    1174:	003015b7          	lui	a1,0x301
    1178:	00003537          	lui	a0,0x3
    117c:	7f850513          	addi	a0,a0,2040 # 37f8 <_data+0xec>
    1180:	7ad010ef          	jal	312c <bsp_printf>
               (unsigned)FB_BASE, (unsigned)FB_BACK, (unsigned)ATLAS_BASE, SPR_W, SPR_H);
    bsp_printf("layout: OSD 0-16 | HW 16-276 | sep | CPU 280-540\r\n");
    1184:	00004537          	lui	a0,0x4
    1188:	81c50513          	addi	a0,a0,-2020 # 381c <_data+0x110>
    118c:	7a1010ef          	jal	312c <bsp_printf>
    bsp_printf("cmd: 1/2/3 scene FILL/ALPHA/KEY, s/c/h path SPLIT/CPU/HW\r\n");
    1190:	00004537          	lui	a0,0x4
    1194:	85050513          	addi	a0,a0,-1968 # 3850 <_data+0x144>
    1198:	795010ef          	jal	312c <bsp_printf>
    bsp_printf("     n or + N+25, - N-25, a/A alpha-/+, r reset, ? help\r\n");
    119c:	00004537          	lui	a0,0x4
    11a0:	88c50513          	addi	a0,a0,-1908 # 388c <_data+0x180>
    11a4:	789010ef          	jal	312c <bsp_printf>

    blt_init();
    11a8:	3c0010ef          	jal	2568 <blt_init>
    build_atlas();                    /* 32x32 精灵图集（引擎与 CPU 都从它取数） */
    11ac:	584010ef          	jal	2730 <build_atlas>
    cpu_fill32(FB_BACK, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);        /* 整屏近黑铺底 */
    11b0:	00800793          	li	a5,8
    11b4:	21c00713          	li	a4,540
    11b8:	3c000693          	li	a3,960
    11bc:	00000613          	li	a2,0
    11c0:	00000593          	li	a1,0
    11c4:	00501537          	lui	a0,0x501
    11c8:	5e0010ef          	jal	27a8 <cpu_fill32>
    cache_evict();
    11cc:	220010ef          	jal	23ec <cache_evict>

    /* ★ 未对齐写入自检：CPU 侧曾因奇数 x 做 32bit 存储而整机静默停死。
     *   这两行能在开机第一秒就暴露该类问题（打印不出来或值不对 = 有问题）。 */
    cpu_fill32(FB_BACK, 33, 500, 8, 2, 0xF800u);
    11d0:	000107b7          	lui	a5,0x10
    11d4:	80078793          	addi	a5,a5,-2048 # f800 <__freertos_irq_stack_top+0x39b0>
    11d8:	00200713          	li	a4,2
    11dc:	00800693          	li	a3,8
    11e0:	1f400613          	li	a2,500
    11e4:	02100593          	li	a1,33
    11e8:	00501537          	lui	a0,0x501
    11ec:	5bc010ef          	jal	27a8 <cpu_fill32>
    cpu_fill32(FB_BACK, 32, 502, 9, 2, 0x07E0u);
    11f0:	7e000793          	li	a5,2016
    11f4:	00200713          	li	a4,2
    11f8:	00900693          	li	a3,9
    11fc:	1f600613          	li	a2,502
    1200:	02000593          	li	a1,32
    1204:	00501537          	lui	a0,0x501
    1208:	5a0010ef          	jal	27a8 <cpu_fill32>
    bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 500u * FB_STRIDE + 33u * 2u)),
    120c:	005eb7b7          	lui	a5,0x5eb
    1210:	6427d583          	lhu	a1,1602(a5) # 5eb642 <__freertos_irq_stack_top+0x5df7f2>
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 500u * FB_STRIDE + 40u * 2u)),
    1214:	005eb7b7          	lui	a5,0x5eb
    1218:	6507d603          	lhu	a2,1616(a5) # 5eb650 <__freertos_irq_stack_top+0x5df800>
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 502u * FB_STRIDE + 32u * 2u)),
    121c:	005ec7b7          	lui	a5,0x5ec
    1220:	5407d683          	lhu	a3,1344(a5) # 5ec540 <__freertos_irq_stack_top+0x5e06f0>
               (unsigned)(*(volatile uint16_t *)(FB_BACK + 502u * FB_STRIDE + 40u * 2u)));
    1224:	005ec7b7          	lui	a5,0x5ec
    1228:	5507d703          	lhu	a4,1360(a5) # 5ec550 <__freertos_irq_stack_top+0x5e0700>
    bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
    122c:	00004537          	lui	a0,0x4
    1230:	8c850513          	addi	a0,a0,-1848 # 38c8 <_data+0x1bc>
    1234:	6f9010ef          	jal	312c <bsp_printf>
    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x\r\n",
               (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG));
    1238:	2d4010ef          	jal	250c <blt_stat>
    123c:	00050413          	mv	s0,a0
    1240:	2b0010ef          	jal	24f0 <blt_cnt>
    1244:	00050493          	mv	s1,a0
    1248:	02000513          	li	a0,32
    124c:	190010ef          	jal	23dc <blt_rd>
    1250:	00050693          	mv	a3,a0
    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x\r\n",
    1254:	00048613          	mv	a2,s1
    1258:	00040593          	mv	a1,s0
    125c:	00004537          	lui	a0,0x4
    1260:	90050513          	addi	a0,a0,-1792 # 3900 <_data+0x1f4>
    1264:	6c9010ef          	jal	312c <bsp_printf>

    scene_init(n, g_seed, 0);
    1268:	00000613          	li	a2,0
    126c:	123455b7          	lui	a1,0x12345
    1270:	67858593          	addi	a1,a1,1656 # 12345678 <__freertos_irq_stack_top+0x12339828>
    1274:	01900513          	li	a0,25
    1278:	30d010ef          	jal	2d84 <scene_init>
    cache_evict();
    127c:	170010ef          	jal	23ec <cache_evict>
    blt_copy_full(FB_BACK, FB_BASE);   /* 开机先整屏上屏一次，避免显示未初始化 DDR */
    1280:	003015b7          	lui	a1,0x301
    1284:	00501537          	lui	a0,0x501
    1288:	324010ef          	jal	25ac <blt_copy_full>
    back_busy = 1; back_t0 = (uint32_t)tick();
    128c:	124010ef          	jal	23b0 <tick>
    1290:	06a12623          	sw	a0,108(sp)
    t_osd = t_scene = (uint32_t)tick();
    1294:	11c010ef          	jal	23b0 <tick>
    1298:	02a12623          	sw	a0,44(sp)
    129c:	04a12e23          	sw	a0,92(sp)
    uint32_t disp_frames = 0, disp_fps = 0;
    12a0:	02012e23          	sw	zero,60(sp)
    back_busy = 1; back_t0 = (uint32_t)tick();
    12a4:	00100a93          	li	s5,1
    int hw_done = 0, cpu_done = 0, back_busy = 0;
    12a8:	04012a23          	sw	zero,84(sp)
    12ac:	04012823          	sw	zero,80(sp)
    int repaint_hw = 1, repaint_cpu = 1;
    12b0:	00100793          	li	a5,1
    12b4:	04f12223          	sw	a5,68(sp)
    12b8:	04f12623          	sw	a5,76(sp)
    int cpu_i = 0;
    12bc:	00000b13          	li	s6,0
    int clear_pp = 0;                  /* 'e'：每趟整片重铺背景，不再擦旧矩形（治'擦到邻居'的拖影） */
    12c0:	06012423          	sw	zero,104(sp)
    int frozen = 0;                    /* 'm'：冻结运动（判决闪烁是否来自帧间内容差异/撕裂） */
    12c4:	02012a23          	sw	zero,52(sp)
    uint32_t guard_t0 = 0;
    12c8:	06012223          	sw	zero,100(sp)
    int guard_us = 0;                 /* 'g'：推拷贝前干等多少微秒（等写落地） */
    12cc:	04012c23          	sw	zero,88(sp)
    int fence_on = 0, hw_fence = 0;   /* 'f'：硬件侧每块之间插围栏（诊断写顺序竞态） */
    12d0:	00000d13          	li	s10,0
    12d4:	06012023          	sw	zero,96(sp)
    int hw_i = 0, hw_frame_pushed = 0;
    12d8:	04012423          	sw	zero,72(sp)
    12dc:	00000413          	li	s0,0
    uint32_t hw_frames = 0, cpu_frames = 0;
    12e0:	02012823          	sw	zero,48(sp)
    12e4:	02012c23          	sw	zero,56(sp)
    uint32_t it = 0, it_prev = 0;
    12e8:	04012023          	sw	zero,64(sp)
    12ec:	00000d93          	li	s11,0
    unsigned alpha = 128u;
    12f0:	08000793          	li	a5,128
    12f4:	02f12423          	sw	a5,40(sp)
    int      n     = 25;
    12f8:	01900493          	li	s1,25
    int      scene = SC_FILL;
    12fc:	00000993          	li	s3,0
    int      path  = PATH_SPLIT;
    1300:	00000913          	li	s2,0
    1304:	5290006f          	j	202c <main+0xf28>

    for (;;) {
        int c;
        it++;
        if (hw_fence && blt_idle()) hw_fence = 0;   /* 围栏：引擎做完了才继续发 */
    1308:	220010ef          	jal	2528 <blt_idle>
    130c:	520504e3          	beqz	a0,2034 <main+0xf30>
    1310:	00000d13          	li	s10,0
    1314:	5210006f          	j	2034 <main+0xf30>
        /* ---------------- 串口命令（交互全部走这里） ---------------- */
        c = uart_poll_char();
        if (c) {
            int scene_change = 0;
            if (c == '1' || c == '2' || c == '3') {
                scene = (c == '1') ? SC_FILL : ((c == '2') ? SC_ALPHA : SC_KEY);
    1318:	03100793          	li	a5,49
    131c:	02f50863          	beq	a0,a5,134c <main+0x248>
    1320:	03200793          	li	a5,50
    1324:	02f50063          	beq	a0,a5,1344 <main+0x240>
    1328:	00200993          	li	s3,2
                scene_change = 1;
                bsp_printf("\r\nEV scene=%d (0=FILL 1=ALPHA 2=KEY)\r\n", scene);
    132c:	00098593          	mv	a1,s3
    1330:	00004537          	lui	a0,0x4
    1334:	92850513          	addi	a0,a0,-1752 # 3928 <_data+0x21c>
    1338:	5f5010ef          	jal	312c <bsp_printf>
                scene_change = 1;
    133c:	00100a13          	li	s4,1
    1340:	4700006f          	j	17b0 <main+0x6ac>
                scene = (c == '1') ? SC_FILL : ((c == '2') ? SC_ALPHA : SC_KEY);
    1344:	00100993          	li	s3,1
    1348:	fe5ff06f          	j	132c <main+0x228>
    134c:	00000993          	li	s3,0
    1350:	fddff06f          	j	132c <main+0x228>
            } else if (c == 's' || c == 'S') { path = PATH_SPLIT; repaint_hw = repaint_cpu = 1;
                bsp_printf("\r\nEV path=0 SPLIT\r\n"); }
    1354:	00004537          	lui	a0,0x4
    1358:	95050513          	addi	a0,a0,-1712 # 3950 <_data+0x244>
    135c:	5d1010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    1360:	00000a13          	li	s4,0
            } else if (c == 's' || c == 'S') { path = PATH_SPLIT; repaint_hw = repaint_cpu = 1;
    1364:	00100793          	li	a5,1
    1368:	04f12223          	sw	a5,68(sp)
    136c:	04f12623          	sw	a5,76(sp)
    1370:	00000913          	li	s2,0
                bsp_printf("\r\nEV path=0 SPLIT\r\n"); }
    1374:	43c0006f          	j	17b0 <main+0x6ac>
            else if (c == 'c' || c == 'C')   { path = PATH_CPU;   repaint_hw = repaint_cpu = 1;
                bsp_printf("\r\nEV path=1 CPU only\r\n"); }
    1378:	00004537          	lui	a0,0x4
    137c:	96450513          	addi	a0,a0,-1692 # 3964 <_data+0x258>
    1380:	5ad010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    1384:	00000a13          	li	s4,0
            else if (c == 'c' || c == 'C')   { path = PATH_CPU;   repaint_hw = repaint_cpu = 1;
    1388:	00100793          	li	a5,1
    138c:	04f12223          	sw	a5,68(sp)
    1390:	04f12623          	sw	a5,76(sp)
    1394:	00100913          	li	s2,1
                bsp_printf("\r\nEV path=1 CPU only\r\n"); }
    1398:	4180006f          	j	17b0 <main+0x6ac>
            else if (c == 'h' || c == 'H')   { path = PATH_HW;    repaint_hw = repaint_cpu = 1;
                bsp_printf("\r\nEV path=2 HW only\r\n"); }
    139c:	00004537          	lui	a0,0x4
    13a0:	97c50513          	addi	a0,a0,-1668 # 397c <_data+0x270>
    13a4:	589010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    13a8:	00000a13          	li	s4,0
            else if (c == 'h' || c == 'H')   { path = PATH_HW;    repaint_hw = repaint_cpu = 1;
    13ac:	00100793          	li	a5,1
    13b0:	04f12223          	sw	a5,68(sp)
    13b4:	04f12623          	sw	a5,76(sp)
    13b8:	00200913          	li	s2,2
                bsp_printf("\r\nEV path=2 HW only\r\n"); }
    13bc:	3f40006f          	j	17b0 <main+0x6ac>
            else if (c == 'n' || c == 'N' || c == '+') {
                n += N_STEP; if (n > N_MAX) n = N_MIN; scene_change = 1;
    13c0:	03248493          	addi	s1,s1,50
    13c4:	2bc00793          	li	a5,700
    13c8:	0097d463          	bge	a5,s1,13d0 <main+0x2cc>
    13cc:	01900493          	li	s1,25
                bsp_printf("\r\nEV N=%d\r\n", n); }
    13d0:	00048593          	mv	a1,s1
    13d4:	00004537          	lui	a0,0x4
    13d8:	99450513          	addi	a0,a0,-1644 # 3994 <_data+0x288>
    13dc:	551010ef          	jal	312c <bsp_printf>
                n += N_STEP; if (n > N_MAX) n = N_MIN; scene_change = 1;
    13e0:	00100a13          	li	s4,1
                bsp_printf("\r\nEV N=%d\r\n", n); }
    13e4:	3cc0006f          	j	17b0 <main+0x6ac>
            else if (c == '-') {
                n -= N_STEP; if (n < N_MIN) n = N_MAX; scene_change = 1;
    13e8:	fce48493          	addi	s1,s1,-50
    13ec:	01800793          	li	a5,24
    13f0:	0097c463          	blt	a5,s1,13f8 <main+0x2f4>
    13f4:	2bc00493          	li	s1,700
                bsp_printf("\r\nEV N=%d\r\n", n); }
    13f8:	00048593          	mv	a1,s1
    13fc:	00004537          	lui	a0,0x4
    1400:	99450513          	addi	a0,a0,-1644 # 3994 <_data+0x288>
    1404:	529010ef          	jal	312c <bsp_printf>
                n -= N_STEP; if (n < N_MIN) n = N_MAX; scene_change = 1;
    1408:	00100a13          	li	s4,1
    140c:	3a40006f          	j	17b0 <main+0x6ac>
            else if (c == 'd' || c == 'D') {   /* 诊断：重叠处像素在 FB_BACK / FB_BASE 各是什么，以及拷贝是否忠实 */
                int hy0 = hw_y0(path), oi, oj, ofound = 0;
    1410:	00090513          	mv	a0,s2
    1414:	4c1010ef          	jal	30d4 <hw_y0>
    1418:	00050c13          	mv	s8,a0
                bsp_printf("\r\nEV dump scene=%d path=%d n=%d y0=%d alpha=%d\r\n",
    141c:	02812783          	lw	a5,40(sp)
    1420:	00050713          	mv	a4,a0
    1424:	00048693          	mv	a3,s1
    1428:	00090613          	mv	a2,s2
    142c:	00098593          	mv	a1,s3
    1430:	00004537          	lui	a0,0x4
    1434:	9a050513          	addi	a0,a0,-1632 # 39a0 <_data+0x294>
    1438:	4f5010ef          	jal	312c <bsp_printf>
                int hy0 = hw_y0(path), oi, oj, ofound = 0;
    143c:	00000693          	li	a3,0
                           scene, path, n, hy0, (int)alpha);
                for (oi = 0; oi < n && !ofound; oi++) {
    1440:	00000c93          	li	s9,0
    1444:	1700006f          	j	15b4 <main+0x4b0>
                    for (oj = oi + 1; oj < n && !ofound; oj++) {
    1448:	001a0a13          	addi	s4,s4,1
    144c:	169a5263          	bge	s4,s1,15b0 <main+0x4ac>
    1450:	14069c63          	bnez	a3,15a8 <main+0x4a4>
                        int ax = g_sc[SIDE_HW][oi].tx, ay = g_sc[SIDE_HW][oi].ty + hy0;
    1454:	00004737          	lui	a4,0x4
    1458:	0e470713          	addi	a4,a4,228 # 40e4 <g_sc>
    145c:	002c9793          	slli	a5,s9,0x2
    1460:	019787b3          	add	a5,a5,s9
    1464:	00279793          	slli	a5,a5,0x2
    1468:	00f707b3          	add	a5,a4,a5
    146c:	00c79803          	lh	a6,12(a5)
    1470:	00e79783          	lh	a5,14(a5)
    1474:	018787b3          	add	a5,a5,s8
                        int bx = g_sc[SIDE_HW][oj].tx, by = g_sc[SIDE_HW][oj].ty + hy0;
    1478:	002a1613          	slli	a2,s4,0x2
    147c:	01460633          	add	a2,a2,s4
    1480:	00261613          	slli	a2,a2,0x2
    1484:	00c70733          	add	a4,a4,a2
    1488:	00c71583          	lh	a1,12(a4)
    148c:	00e71e03          	lh	t3,14(a4)
    1490:	018e0e33          	add	t3,t3,s8
                        int lx0 = (ax > bx) ? ax : bx, ly0 = (ay > by) ? ay : by;
    1494:	00080893          	mv	a7,a6
    1498:	00b85463          	bge	a6,a1,14a0 <main+0x39c>
    149c:	00058893          	mv	a7,a1
    14a0:	00078313          	mv	t1,a5
    14a4:	01c7d463          	bge	a5,t3,14ac <main+0x3a8>
    14a8:	000e0313          	mv	t1,t3
                        int ax1 = ax + g_sc[SIDE_HW][oi].sz, ay1 = ay + g_sc[SIDE_HW][oi].sz;
    14ac:	00004637          	lui	a2,0x4
    14b0:	0e460613          	addi	a2,a2,228 # 40e4 <g_sc>
    14b4:	002c9713          	slli	a4,s9,0x2
    14b8:	01970733          	add	a4,a4,s9
    14bc:	00271713          	slli	a4,a4,0x2
    14c0:	00e60733          	add	a4,a2,a4
    14c4:	01274703          	lbu	a4,18(a4)
    14c8:	00f707b3          	add	a5,a4,a5
                        int bx1 = bx + g_sc[SIDE_HW][oj].sz, by1 = by + g_sc[SIDE_HW][oj].sz;
    14cc:	002a1513          	slli	a0,s4,0x2
    14d0:	01450533          	add	a0,a0,s4
    14d4:	00251513          	slli	a0,a0,0x2
    14d8:	00a60633          	add	a2,a2,a0
    14dc:	01264603          	lbu	a2,18(a2)
    14e0:	00b605b3          	add	a1,a2,a1
    14e4:	01c60633          	add	a2,a2,t3
                        int lx1 = (ax1 < bx1) ? ax1 : bx1, ly1 = (ay1 < by1) ? ay1 : by1;
    14e8:	01070733          	add	a4,a4,a6
    14ec:	00e5d463          	bge	a1,a4,14f4 <main+0x3f0>
    14f0:	00058713          	mv	a4,a1
    14f4:	00f65463          	bge	a2,a5,14fc <main+0x3f8>
    14f8:	00060793          	mv	a5,a2
                        if (lx0 < lx1 && ly0 < ly1) {
    14fc:	f4e8d6e3          	bge	a7,a4,1448 <main+0x344>
    1500:	f4f354e3          	bge	t1,a5,1448 <main+0x344>
                            int px = lx0 + (lx1 - lx0) / 2, py = ly0 + (ly1 - ly0) / 2;
    1504:	41170733          	sub	a4,a4,a7
    1508:	01f75693          	srli	a3,a4,0x1f
    150c:	00e686b3          	add	a3,a3,a4
    1510:	4016d693          	srai	a3,a3,0x1
    1514:	011686b3          	add	a3,a3,a7
    1518:	406787b3          	sub	a5,a5,t1
    151c:	01f7d713          	srli	a4,a5,0x1f
    1520:	00f70733          	add	a4,a4,a5
    1524:	40175713          	srai	a4,a4,0x1
    1528:	00670733          	add	a4,a4,t1
                            uint32_t off = (uint32_t)py * FB_STRIDE + (uint32_t)px * 2u;
    152c:	00471793          	slli	a5,a4,0x4
    1530:	40e787b3          	sub	a5,a5,a4
    1534:	00679793          	slli	a5,a5,0x6
    1538:	00d787b3          	add	a5,a5,a3
    153c:	00179793          	slli	a5,a5,0x1
                            bsp_printf("  pair i=%d j=%d px=%d,%d ci=%X cj=%X back=%X base=%X\r\n",
                                       oi, oj, px, py, (unsigned)g_sc[SIDE_HW][oi].color,
    1540:	000045b7          	lui	a1,0x4
    1544:	0e458593          	addi	a1,a1,228 # 40e4 <g_sc>
    1548:	002c9613          	slli	a2,s9,0x2
    154c:	01960633          	add	a2,a2,s9
    1550:	00261613          	slli	a2,a2,0x2
    1554:	00c58633          	add	a2,a1,a2
                                       (unsigned)g_sc[SIDE_HW][oj].color,
    1558:	002a1513          	slli	a0,s4,0x2
    155c:	01450533          	add	a0,a0,s4
    1560:	00251513          	slli	a0,a0,0x2
    1564:	00a585b3          	add	a1,a1,a0
                                       (unsigned)*(volatile uint16_t *)(FB_BACK + off),
    1568:	00501537          	lui	a0,0x501
    156c:	00a78533          	add	a0,a5,a0
    1570:	00055883          	lhu	a7,0(a0) # 501000 <__freertos_irq_stack_top+0x4f51b0>
                                       (unsigned)*(volatile uint16_t *)(FB_BASE + off));
    1574:	00301537          	lui	a0,0x301
    1578:	00a787b3          	add	a5,a5,a0
    157c:	0007d783          	lhu	a5,0(a5)
                            bsp_printf("  pair i=%d j=%d px=%d,%d ci=%X cj=%X back=%X base=%X\r\n",
    1580:	00f12023          	sw	a5,0(sp)
    1584:	0105d803          	lhu	a6,16(a1)
    1588:	01065783          	lhu	a5,16(a2)
    158c:	000a0613          	mv	a2,s4
    1590:	000c8593          	mv	a1,s9
    1594:	00004537          	lui	a0,0x4
    1598:	9d450513          	addi	a0,a0,-1580 # 39d4 <_data+0x2c8>
    159c:	391010ef          	jal	312c <bsp_printf>
                            ofound = 1;
    15a0:	00100693          	li	a3,1
    15a4:	ea5ff06f          	j	1448 <main+0x344>
    15a8:	000b8c93          	mv	s9,s7
    15ac:	0080006f          	j	15b4 <main+0x4b0>
    15b0:	000b8c93          	mv	s9,s7
                for (oi = 0; oi < n && !ofound; oi++) {
    15b4:	009cda63          	bge	s9,s1,15c8 <main+0x4c4>
    15b8:	00069863          	bnez	a3,15c8 <main+0x4c4>
                    for (oj = oi + 1; oj < n && !ofound; oj++) {
    15bc:	001c8b93          	addi	s7,s9,1
    15c0:	000b8a13          	mv	s4,s7
    15c4:	e89ff06f          	j	144c <main+0x348>
                        }
                    }
                }
                if (!ofound) bsp_printf("  no overlap pair in HW region\r\n");
    15c8:	00068a63          	beqz	a3,15dc <main+0x4d8>
                {   /* 拷贝忠实度：硬件区域内 FB_BASE 与 FB_BACK 不同的像素数 */
                    int oyy, oxx; uint32_t odiff = 0, ofirst = 0;
                    for (oyy = 0; oyy < hw_h(path); oyy++) {
                        uint32_t orow = (uint32_t)(oyy + hy0) * FB_STRIDE;
                        for (oxx = 0; oxx < FB_WIDTH; oxx++) {
    15cc:	00000b93          	li	s7,0
    15d0:	00000a13          	li	s4,0
    15d4:	00000c93          	li	s9,0
    15d8:	06c0006f          	j	1644 <main+0x540>
                if (!ofound) bsp_printf("  no overlap pair in HW region\r\n");
    15dc:	00004537          	lui	a0,0x4
    15e0:	a0c50513          	addi	a0,a0,-1524 # 3a0c <_data+0x300>
    15e4:	349010ef          	jal	312c <bsp_printf>
    15e8:	fe5ff06f          	j	15cc <main+0x4c8>
                            uint16_t pa = *(volatile uint16_t *)(FB_BACK + orow + (uint32_t)oxx * 2u);
                            uint16_t pb = *(volatile uint16_t *)(FB_BASE + orow + (uint32_t)oxx * 2u);
                            if (pa != pb) { if (odiff == 0) ofirst = orow + (uint32_t)oxx * 2u; odiff++; }
    15ec:	001a0a13          	addi	s4,s4,1
    15f0:	00078b93          	mv	s7,a5
                        for (oxx = 0; oxx < FB_WIDTH; oxx++) {
    15f4:	00170713          	addi	a4,a4,1
    15f8:	3bf00793          	li	a5,959
    15fc:	04e7c263          	blt	a5,a4,1640 <main+0x53c>
                            uint16_t pa = *(volatile uint16_t *)(FB_BACK + orow + (uint32_t)oxx * 2u);
    1600:	00171793          	slli	a5,a4,0x1
    1604:	00b787b3          	add	a5,a5,a1
    1608:	005016b7          	lui	a3,0x501
    160c:	00d786b3          	add	a3,a5,a3
    1610:	0006d603          	lhu	a2,0(a3) # 501000 <__freertos_irq_stack_top+0x4f51b0>
    1614:	01061613          	slli	a2,a2,0x10
    1618:	01065613          	srli	a2,a2,0x10
                            uint16_t pb = *(volatile uint16_t *)(FB_BASE + orow + (uint32_t)oxx * 2u);
    161c:	003016b7          	lui	a3,0x301
    1620:	00d786b3          	add	a3,a5,a3
    1624:	0006d683          	lhu	a3,0(a3) # 301000 <__freertos_irq_stack_top+0x2f51b0>
    1628:	01069693          	slli	a3,a3,0x10
    162c:	0106d693          	srli	a3,a3,0x10
                            if (pa != pb) { if (odiff == 0) ofirst = orow + (uint32_t)oxx * 2u; odiff++; }
    1630:	fcd602e3          	beq	a2,a3,15f4 <main+0x4f0>
    1634:	fa0a0ce3          	beqz	s4,15ec <main+0x4e8>
    1638:	000b8793          	mv	a5,s7
    163c:	fb1ff06f          	j	15ec <main+0x4e8>
                    for (oyy = 0; oyy < hw_h(path); oyy++) {
    1640:	001c8c93          	addi	s9,s9,1
    1644:	00090513          	mv	a0,s2
    1648:	295010ef          	jal	30dc <hw_h>
    164c:	00acde63          	bge	s9,a0,1668 <main+0x564>
                        uint32_t orow = (uint32_t)(oyy + hy0) * FB_STRIDE;
    1650:	018c87b3          	add	a5,s9,s8
    1654:	00479593          	slli	a1,a5,0x4
    1658:	40f585b3          	sub	a1,a1,a5
    165c:	00759593          	slli	a1,a1,0x7
                        for (oxx = 0; oxx < FB_WIDTH; oxx++) {
    1660:	00000713          	li	a4,0
    1664:	f95ff06f          	j	15f8 <main+0x4f4>
                        }
                    }
                    bsp_printf("  copy diff=%d first_off=%X (0=拷贝忠实)\r\n", (int)odiff, (unsigned)ofirst);
    1668:	000b8613          	mv	a2,s7
    166c:	000a0593          	mv	a1,s4
    1670:	00004537          	lui	a0,0x4
    1674:	a3050513          	addi	a0,a0,-1488 # 3a30 <_data+0x324>
    1678:	2b5010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    167c:	00000a13          	li	s4,0
            else if (c == 'd' || c == 'D') {   /* 诊断：重叠处像素在 FB_BACK / FB_BASE 各是什么，以及拷贝是否忠实 */
    1680:	1300006f          	j	17b0 <main+0x6ac>
                }
            }
            else if (c == 'e' || c == 'E') { clear_pp = !clear_pp;
    1684:	06812783          	lw	a5,104(sp)
    1688:	0017c793          	xori	a5,a5,1
    168c:	06f12423          	sw	a5,104(sp)
                repaint_hw = repaint_cpu = 1;   /* 立即重铺一次，状态一致 */
                bsp_printf("\r\nEV clear_per_pass=%d (1=每趟整片重铺, 且不再发擦除)\r\n", clear_pp); }
    1690:	00078593          	mv	a1,a5
    1694:	00004537          	lui	a0,0x4
    1698:	a6050513          	addi	a0,a0,-1440 # 3a60 <_data+0x354>
    169c:	291010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    16a0:	00000a13          	li	s4,0
                repaint_hw = repaint_cpu = 1;   /* 立即重铺一次，状态一致 */
    16a4:	00100793          	li	a5,1
    16a8:	04f12223          	sw	a5,68(sp)
    16ac:	04f12623          	sw	a5,76(sp)
                bsp_printf("\r\nEV clear_per_pass=%d (1=每趟整片重铺, 且不再发擦除)\r\n", clear_pp); }
    16b0:	1000006f          	j	17b0 <main+0x6ac>
            else if (c == 'm' || c == 'M') { frozen = !frozen;
    16b4:	03412783          	lw	a5,52(sp)
    16b8:	0017c793          	xori	a5,a5,1
    16bc:	02f12a23          	sw	a5,52(sp)
                bsp_printf("\r\nEV freeze=%d (1=运动暂停)\r\n", frozen); }
    16c0:	00078593          	mv	a1,a5
    16c4:	00004537          	lui	a0,0x4
    16c8:	aa450513          	addi	a0,a0,-1372 # 3aa4 <_data+0x398>
    16cc:	261010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    16d0:	00000a13          	li	s4,0
                bsp_printf("\r\nEV freeze=%d (1=运动暂停)\r\n", frozen); }
    16d4:	0dc0006f          	j	17b0 <main+0x6ac>
            else if (c == 'g' || c == 'G') { guard_us = guard_us ? 0 : 300;
    16d8:	05812783          	lw	a5,88(sp)
    16dc:	02078063          	beqz	a5,16fc <main+0x5f8>
    16e0:	04012c23          	sw	zero,88(sp)
                bsp_printf("\r\nEV guard=%dus (0=off,300=wait writes before copy)\r\n", guard_us); }
    16e4:	05812583          	lw	a1,88(sp)
    16e8:	00004537          	lui	a0,0x4
    16ec:	ac850513          	addi	a0,a0,-1336 # 3ac8 <_data+0x3bc>
    16f0:	23d010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    16f4:	00000a13          	li	s4,0
                bsp_printf("\r\nEV guard=%dus (0=off,300=wait writes before copy)\r\n", guard_us); }
    16f8:	0b80006f          	j	17b0 <main+0x6ac>
            else if (c == 'g' || c == 'G') { guard_us = guard_us ? 0 : 300;
    16fc:	12c00793          	li	a5,300
    1700:	04f12c23          	sw	a5,88(sp)
    1704:	fe1ff06f          	j	16e4 <main+0x5e0>
            else if (c == 'f' || c == 'F') { fence_on = !fence_on;
    1708:	06012783          	lw	a5,96(sp)
    170c:	0017c793          	xori	a5,a5,1
    1710:	06f12023          	sw	a5,96(sp)
                bsp_printf("\r\nEV fence=%d (1=hw waits engine idle per block)\r\n", fence_on); }
    1714:	00078593          	mv	a1,a5
    1718:	00004537          	lui	a0,0x4
    171c:	b0050513          	addi	a0,a0,-1280 # 3b00 <_data+0x3f4>
    1720:	20d010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    1724:	00000a13          	li	s4,0
                bsp_printf("\r\nEV fence=%d (1=hw waits engine idle per block)\r\n", fence_on); }
    1728:	0880006f          	j	17b0 <main+0x6ac>
            else if (c == 'a') { if (alpha >= 32u)  alpha -= 32u;
    172c:	01f00793          	li	a5,31
    1730:	02812703          	lw	a4,40(sp)
    1734:	00e7f663          	bgeu	a5,a4,1740 <main+0x63c>
    1738:	fe070793          	addi	a5,a4,-32
    173c:	02f12423          	sw	a5,40(sp)
                bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
    1740:	02812583          	lw	a1,40(sp)
    1744:	00004537          	lui	a0,0x4
    1748:	b3450513          	addi	a0,a0,-1228 # 3b34 <_data+0x428>
    174c:	1e1010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    1750:	00000a13          	li	s4,0
    1754:	05c0006f          	j	17b0 <main+0x6ac>
            else if (c == 'A') { if (alpha <= 223u) alpha += 32u;
    1758:	0df00793          	li	a5,223
    175c:	02812703          	lw	a4,40(sp)
    1760:	00e7e663          	bltu	a5,a4,176c <main+0x668>
    1764:	02070793          	addi	a5,a4,32
    1768:	02f12423          	sw	a5,40(sp)
                bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
    176c:	02812583          	lw	a1,40(sp)
    1770:	00004537          	lui	a0,0x4
    1774:	b3450513          	addi	a0,a0,-1228 # 3b34 <_data+0x428>
    1778:	1b5010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    177c:	00000a13          	li	s4,0
    1780:	0300006f          	j	17b0 <main+0x6ac>
            else if (c == 'r' || c == 'R') { scene_change = 1;
                bsp_printf("\r\nEV reset\r\n"); }
    1784:	00004537          	lui	a0,0x4
    1788:	b4450513          	addi	a0,a0,-1212 # 3b44 <_data+0x438>
    178c:	1a1010ef          	jal	312c <bsp_printf>
            else if (c == 'r' || c == 'R') { scene_change = 1;
    1790:	00100a13          	li	s4,1
                bsp_printf("\r\nEV reset\r\n"); }
    1794:	01c0006f          	j	17b0 <main+0x6ac>
            else if (c == '?') {
                bsp_printf("\r\ncmd: 1/2/3=FILL/ALPHA/KEY  s/c/h=SPLIT/CPU/HW"
    1798:	00004537          	lui	a0,0x4
    179c:	b5450513          	addi	a0,a0,-1196 # 3b54 <_data+0x448>
    17a0:	18d010ef          	jal	312c <bsp_printf>
            int scene_change = 0;
    17a4:	00000a13          	li	s4,0
    17a8:	0080006f          	j	17b0 <main+0x6ac>
        c = uart_poll_char();
    17ac:	00000a13          	li	s4,0
                           "  n/+/ -=N  a/A=alpha  f=fence g=guard m=freeze e=clear d=dump r=reset\r\n"); }
            if (scene_change) {
    17b0:	040a1e63          	bnez	s4,180c <main+0x708>
                repaint_hw = repaint_cpu = 1;
            }
        }

        /* ---------------- 场景按时间推进（两侧同时、目标逐位相同） ---------------- */
        vrg.h = vrg_h(path);          /* 虚拟区域跟着路径变（单模式 = 整屏高） */
    17b4:	00090513          	mv	a0,s2
    17b8:	161010ef          	jal	3118 <vrg_h>
    17bc:	0ca12623          	sw	a0,204(sp)
        if (!frozen && (uint32_t)(tick() - t_scene) >= (uint32_t)SCENE_TICKS) {
    17c0:	03412783          	lw	a5,52(sp)
    17c4:	06078a63          	beqz	a5,1838 <main+0x734>
        /* ---------------- 双缓冲：两侧都画完一遍 → 整体搬上屏一次 ----------------
         * ★ 只有这一处写显示缓冲（FB_BASE），所以"擦除/重画/重叠"的中间过程永远不会
         *   被屏幕看到。之前的尾迹与重叠闪烁，根子都是屏幕拍到了帧中间状态
         *   （两阶段把"已擦未画"的窗口拉长到 10ms 量级，而屏幕每 16.7ms 采一次样）。
         *   这也正是最初"CPU 画屏外缓冲、引擎 COPY 上屏"的做法。 */
        if (back_busy) {
    17c8:	0a0a9e63          	bnez	s5,1884 <main+0x780>
                    dbg_quick(n, hw_y0(path), hw_h(path));
                    osd_fill(n, hw_y0(path), hw_h(path), path, scene, (int)alpha,
                             fence_on, guard_us ? 1 : 0, frozen);
                }
            }
        } else if ((path == PATH_CPU || hw_done) && (path == PATH_HW || cpu_done)) {
    17cc:	00100793          	li	a5,1
    17d0:	00f90a63          	beq	s2,a5,17e4 <main+0x6e0>
    17d4:	05012783          	lw	a5,80(sp)
    17d8:	0a078a63          	beqz	a5,188c <main+0x788>
    17dc:	00200793          	li	a5,2
    17e0:	00f90663          	beq	s2,a5,17ec <main+0x6e8>
    17e4:	05412783          	lw	a5,84(sp)
    17e8:	0a078263          	beqz	a5,188c <main+0x788>
            /* 'g'：推拷贝前先干等 guard_us 微秒，等渲染的写真正落到 DDR。
             * 拷贝是'读 FB_BACK'的另一个 master，与尚未落地的渲染写之间没有顺序保证
             * （read-after-write 冒险），会读到'部分更新'的后台缓冲 —— 重叠处每帧
             * 上下关系乱跳就是这么来的。CPU 侧不出现：它每块要毫秒级，写早落地了。 */
            if (guard_us && guard_t0 == 0) {
    17ec:	05812783          	lw	a5,88(sp)
    17f0:	30078e63          	beqz	a5,1b0c <main+0xa08>
    17f4:	06412783          	lw	a5,100(sp)
    17f8:	2e079c63          	bnez	a5,1af0 <main+0x9ec>
                guard_t0 = (uint32_t)tick() | 1u;
    17fc:	3b5000ef          	jal	23b0 <tick>
    1800:	00156793          	ori	a5,a0,1
    1804:	06f12223          	sw	a5,100(sp)
    1808:	0840006f          	j	188c <main+0x788>
                scene_init(n, g_seed, (scene == SC_FILL) ? 0 : 1);
    180c:	01303633          	snez	a2,s3
    1810:	123455b7          	lui	a1,0x12345
    1814:	67858593          	addi	a1,a1,1656 # 12345678 <__freertos_irq_stack_top+0x12339828>
    1818:	00048513          	mv	a0,s1
    181c:	568010ef          	jal	2d84 <scene_init>
                repaint_hw = repaint_cpu = 1;
    1820:	05412223          	sw	s4,68(sp)
    1824:	05412623          	sw	s4,76(sp)
                hw_i = 0; hw_frame_pushed = 0; cpu_i = 0;
    1828:	00000b13          	li	s6,0
    182c:	04012423          	sw	zero,72(sp)
    1830:	00000413          	li	s0,0
    1834:	f81ff06f          	j	17b4 <main+0x6b0>
        if (!frozen && (uint32_t)(tick() - t_scene) >= (uint32_t)SCENE_TICKS) {
    1838:	379000ef          	jal	23b0 <tick>
    183c:	05c12783          	lw	a5,92(sp)
    1840:	40f50733          	sub	a4,a0,a5
    1844:	003d17b7          	lui	a5,0x3d1
    1848:	8ff78793          	addi	a5,a5,-1793 # 3d08ff <__freertos_irq_stack_top+0x3c4aaf>
    184c:	f6e7fee3          	bgeu	a5,a4,17c8 <main+0x6c4>
            t_scene = (uint32_t)tick();
    1850:	361000ef          	jal	23b0 <tick>
    1854:	04a12e23          	sw	a0,92(sp)
            scene_step(g_sc[SIDE_HW],  n, &vrg);
    1858:	0c010613          	addi	a2,sp,192
    185c:	00048593          	mv	a1,s1
    1860:	00004537          	lui	a0,0x4
    1864:	0e450513          	addi	a0,a0,228 # 40e4 <g_sc>
    1868:	79c010ef          	jal	3004 <scene_step>
            scene_step(g_sc[SIDE_CPU], n, &vrg);
    186c:	0c010613          	addi	a2,sp,192
    1870:	00048593          	mv	a1,s1
    1874:	00007537          	lui	a0,0x7
    1878:	79450513          	addi	a0,a0,1940 # 7794 <__global_pointer$+0x2ecc>
    187c:	788010ef          	jal	3004 <scene_step>
    1880:	f49ff06f          	j	17c8 <main+0x6c4>
            if (blt_idle() && ((uint32_t)(tick() - back_t0) > (uint32_t)(BSP_CLINT_HZ / 5000u))) {
    1884:	4a5000ef          	jal	2528 <blt_idle>
    1888:	22051e63          	bnez	a0,1ac4 <main+0x9c0>
        /* ---------------- 硬件侧：**相邻式**擦+画，位置用本趟快照 ----------------
         * 全部画在后台缓冲里；屏幕看到的是上面那条整帧 COPY。
         * ★ 相邻式（擦一块立刻画这一块）是 v1 的原始做法 —— 当时只有重叠闪烁、没有尾迹。
         *   我后来为修闪烁改成"先擦完 N 块再统一画 N 块"，结果引入了尾迹且闪烁也没修好，
         *   所以退回来；重叠闪烁交给双缓冲解决（瞬态只在后台缓冲里，屏幕看不到）。 */
        if (!back_busy && path != PATH_CPU) {
    188c:	060a9263          	bnez	s5,18f0 <main+0x7ec>
    1890:	00100793          	li	a5,1
    1894:	04f90e63          	beq	s2,a5,18f0 <main+0x7ec>
            if (hw_frame_pushed) {
    1898:	04812783          	lw	a5,72(sp)
    189c:	28079e63          	bnez	a5,1b38 <main+0xa34>
                                        /* 'e' 打开：下一趟先整片铺背景再画全部块 ⇒ 不再擦掉压在旧位置上的邻居，
                     *   场景1 那种 2~3px 背景色拖影即消失；中间态被双缓冲挡住。 */
                    if (clear_pp) repaint_hw = 1;
                    scene_snap(g_sc[SIDE_HW], n);     /* 上一趟结束 → 为下一趟拍快照 */
                }
            } else if (repaint_hw && blt_can_push()) {
    18a0:	04c12783          	lw	a5,76(sp)
    18a4:	2c078e63          	beqz	a5,1b80 <main+0xa7c>
    18a8:	4a5000ef          	jal	254c <blt_can_push>
    18ac:	2c050a63          	beqz	a0,1b80 <main+0xa7c>
                blt_fill(FB_BACK + (uint32_t)hw_y0(path) * FB_STRIDE, FB_STRIDE,
    18b0:	00090513          	mv	a0,s2
    18b4:	021010ef          	jal	30d4 <hw_y0>
    18b8:	00451a13          	slli	s4,a0,0x4
    18bc:	40aa0a33          	sub	s4,s4,a0
    18c0:	007a1a13          	slli	s4,s4,0x7
                         FB_WIDTH, (uint32_t)hw_h(path), COL_BG);
    18c4:	00090513          	mv	a0,s2
    18c8:	015010ef          	jal	30dc <hw_h>
    18cc:	00050693          	mv	a3,a0
                blt_fill(FB_BACK + (uint32_t)hw_y0(path) * FB_STRIDE, FB_STRIDE,
    18d0:	00800713          	li	a4,8
    18d4:	3c000613          	li	a2,960
    18d8:	78000593          	li	a1,1920
    18dc:	00501537          	lui	a0,0x501
    18e0:	00aa0533          	add	a0,s4,a0
    18e4:	505000ef          	jal	25e8 <blt_fill>
                repaint_hw = 0;
    18e8:	04812783          	lw	a5,72(sp)
    18ec:	04f12623          	sw	a5,76(sp)
                }
            }
        }

        /* ---------------- CPU 侧：每圈一块，相邻式擦+画，同样用本趟快照 ---------------- */
        if (!back_busy && path != PATH_HW) {
    18f0:	100a9463          	bnez	s5,19f8 <main+0x8f4>
    18f4:	00200793          	li	a5,2
    18f8:	10f90063          	beq	s2,a5,19f8 <main+0x8f4>
            int y0 = cpu_y0(path);
    18fc:	00090513          	mv	a0,s2
    1900:	7f0010ef          	jal	30f0 <cpu_y0>
    1904:	00050a13          	mv	s4,a0
            blk_t *b;
            if (repaint_cpu) {                 /* 场景/路径刚变过 → 先把这片区域铺背景 */
    1908:	04412783          	lw	a5,68(sp)
    190c:	46079c63          	bnez	a5,1d84 <main+0xc80>
                cpu_fill32(FB_BACK, 0, cpu_y0(path), FB_WIDTH, cpu_h(path), COL_BG);
                repaint_cpu = 0;
            }
            b = &g_sc[SIDE_CPU][cpu_i];
            /* 同硬件侧：ALPHA 必须每次重铺背景（否则混合逐次叠加、越来越暗） */
            if ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty))
    1910:	00100793          	li	a5,1
    1914:	02f98863          	beq	s3,a5,1944 <main+0x840>
    1918:	000047b7          	lui	a5,0x4
    191c:	002b1713          	slli	a4,s6,0x2
    1920:	01670733          	add	a4,a4,s6
    1924:	00271713          	slli	a4,a4,0x2
    1928:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    192c:	00e787b3          	add	a5,a5,a4
    1930:	00003737          	lui	a4,0x3
    1934:	00f707b3          	add	a5,a4,a5
    1938:	6b879703          	lh	a4,1720(a5)
    193c:	6bc79783          	lh	a5,1724(a5)
    1940:	46f70863          	beq	a4,a5,1db0 <main+0xcac>
                cpu_fill32(FB_BACK, b->dx, b->dy + y0, b->sz, b->sz, COL_BG);
    1944:	000047b7          	lui	a5,0x4
    1948:	002b1713          	slli	a4,s6,0x2
    194c:	01670733          	add	a4,a4,s6
    1950:	00271713          	slli	a4,a4,0x2
    1954:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1958:	00e787b3          	add	a5,a5,a4
    195c:	000035b7          	lui	a1,0x3
    1960:	00f585b3          	add	a1,a1,a5
    1964:	6ba59603          	lh	a2,1722(a1) # 36ba <__udivdi3+0x45e>
    1968:	6c25c683          	lbu	a3,1730(a1)
    196c:	00800793          	li	a5,8
    1970:	00068713          	mv	a4,a3
    1974:	01460633          	add	a2,a2,s4
    1978:	6b859583          	lh	a1,1720(a1)
    197c:	00501537          	lui	a0,0x501
    1980:	629000ef          	jal	27a8 <cpu_fill32>
            if (scene == SC_FILL)
    1984:	44098e63          	beqz	s3,1de0 <main+0xcdc>
                cpu_fill32(FB_BACK, b->tx, b->ty + y0, b->sz, b->sz, b->color);
            else if (scene == SC_ALPHA)
    1988:	00100793          	li	a5,1
    198c:	48f98c63          	beq	s3,a5,1e24 <main+0xd20>
                cpu_alpha_sprite(b->tx, b->ty + y0, alpha);
            else
                cpu_key_sprite(b->tx, b->ty + y0);
    1990:	000047b7          	lui	a5,0x4
    1994:	002b1713          	slli	a4,s6,0x2
    1998:	01670733          	add	a4,a4,s6
    199c:	00271713          	slli	a4,a4,0x2
    19a0:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    19a4:	00e787b3          	add	a5,a5,a4
    19a8:	00003737          	lui	a4,0x3
    19ac:	00f707b3          	add	a5,a4,a5
    19b0:	6be79583          	lh	a1,1726(a5)
    19b4:	014585b3          	add	a1,a1,s4
    19b8:	6bc79503          	lh	a0,1724(a5)
    19bc:	05c010ef          	jal	2a18 <cpu_key_sprite>
            b->dx = b->tx; b->dy = b->ty;
    19c0:	00004737          	lui	a4,0x4
    19c4:	002b1793          	slli	a5,s6,0x2
    19c8:	016787b3          	add	a5,a5,s6
    19cc:	00279793          	slli	a5,a5,0x2
    19d0:	0e470713          	addi	a4,a4,228 # 40e4 <g_sc>
    19d4:	00f70733          	add	a4,a4,a5
    19d8:	000037b7          	lui	a5,0x3
    19dc:	00e787b3          	add	a5,a5,a4
    19e0:	6bc79703          	lh	a4,1724(a5) # 36bc <__udivdi3+0x460>
    19e4:	6ae79c23          	sh	a4,1720(a5)
    19e8:	6be79703          	lh	a4,1726(a5)
    19ec:	6ae79d23          	sh	a4,1722(a5)
            if (++cpu_i >= n) {
    19f0:	001b0b13          	addi	s6,s6,1
    19f4:	469b5463          	bge	s6,s1,1e5c <main+0xd58>
                scene_snap(g_sc[SIDE_CPU], n);   /* 上一趟结束 → 为下一趟拍快照 */
            }
        }

        /* ---------------- OSD + 统计（每 300ms） ---------------- */
        if ((uint32_t)(tick() - t_osd) >= (uint32_t)(BSP_CLINT_HZ * 3u / 10u)) {
    19f8:	1b9000ef          	jal	23b0 <tick>
    19fc:	02c12a03          	lw	s4,44(sp)
    1a00:	41450533          	sub	a0,a0,s4
    1a04:	01c9c7b7          	lui	a5,0x1c9c
    1a08:	37f78793          	addi	a5,a5,895 # 1c9c37f <__freertos_irq_stack_top+0x1c9052f>
    1a0c:	62a7f063          	bgeu	a5,a0,202c <main+0xf28>
            uint32_t el = (uint32_t)(tick() - t_osd);
    1a10:	1a1000ef          	jal	23b0 <tick>
    1a14:	41450bb3          	sub	s7,a0,s4
            uint32_t d_it = it - it_prev;
    1a18:	04012783          	lw	a5,64(sp)
    1a1c:	40fd8c33          	sub	s8,s11,a5
            char line[72];
            char *p = line;
            uint32_t sc = blt_rd(BLT_SCAN_DBG);
    1a20:	02000513          	li	a0,32
    1a24:	1b9000ef          	jal	23dc <blt_rd>
    1a28:	04a12023          	sw	a0,64(sp)

            t_osd = (uint32_t)tick();
    1a2c:	185000ef          	jal	23b0 <tick>
    1a30:	02a12623          	sw	a0,44(sp)
            it_prev = it;

            hw_fps  = (uint32_t)(((uint64_t)hw_frames  * (uint64_t)BSP_CLINT_HZ) / el);
    1a34:	05f5ea37          	lui	s4,0x5f5e
    1a38:	100a0a13          	addi	s4,s4,256 # 5f5e100 <__freertos_irq_stack_top+0x5f522b0>
    1a3c:	03812783          	lw	a5,56(sp)
    1a40:	0347b5b3          	mulhu	a1,a5,s4
    1a44:	000b8613          	mv	a2,s7
    1a48:	00000693          	li	a3,0
    1a4c:	03478533          	mul	a0,a5,s4
    1a50:	00d010ef          	jal	325c <__udivdi3>
    1a54:	00050c93          	mv	s9,a0
            disp_fps = (uint32_t)(((uint64_t)disp_frames * (uint64_t)BSP_CLINT_HZ) / el);
    1a58:	03c12783          	lw	a5,60(sp)
    1a5c:	0347b5b3          	mulhu	a1,a5,s4
    1a60:	000b8613          	mv	a2,s7
    1a64:	00000693          	li	a3,0
    1a68:	03478533          	mul	a0,a5,s4
    1a6c:	7f0010ef          	jal	325c <__udivdi3>
    1a70:	02a12c23          	sw	a0,56(sp)
            cpu_fps = (uint32_t)(((uint64_t)cpu_frames * (uint64_t)BSP_CLINT_HZ) / el);
    1a74:	03012783          	lw	a5,48(sp)
    1a78:	0347b5b3          	mulhu	a1,a5,s4
    1a7c:	000b8613          	mv	a2,s7
    1a80:	00000693          	li	a3,0
    1a84:	03478533          	mul	a0,a5,s4
    1a88:	7d4010ef          	jal	325c <__udivdi3>
    1a8c:	00050a13          	mv	s4,a0

            cpu_fill32(FB_BACK, 0, 0, FB_WIDTH, OSD_H, COL_OSD_BG);
    1a90:	00000793          	li	a5,0
    1a94:	01000713          	li	a4,16
    1a98:	3c000693          	li	a3,960
    1a9c:	00000613          	li	a2,0
    1aa0:	00000593          	li	a1,0
    1aa4:	00501537          	lui	a0,0x501
    1aa8:	501000ef          	jal	27a8 <cpu_fill32>
            p = app(p, (path == PATH_SPLIT) ? "SPLIT " :
    1aac:	3e090463          	beqz	s2,1e94 <main+0xd90>
    1ab0:	00100793          	li	a5,1
    1ab4:	3cf90a63          	beq	s2,a5,1e88 <main+0xd84>
    1ab8:	000035b7          	lui	a1,0x3
    1abc:	78058593          	addi	a1,a1,1920 # 3780 <_data+0x74>
    1ac0:	3dc0006f          	j	1e9c <main+0xd98>
            if (blt_idle() && ((uint32_t)(tick() - back_t0) > (uint32_t)(BSP_CLINT_HZ / 5000u))) {
    1ac4:	0ed000ef          	jal	23b0 <tick>
    1ac8:	06c12783          	lw	a5,108(sp)
    1acc:	40f50733          	sub	a4,a0,a5
    1ad0:	000057b7          	lui	a5,0x5
    1ad4:	e2078793          	addi	a5,a5,-480 # 4e20 <__global_pointer$+0x558>
    1ad8:	dae7fae3          	bgeu	a5,a4,188c <main+0x788>
                disp_frames++;
    1adc:	03c12783          	lw	a5,60(sp)
    1ae0:	00178793          	addi	a5,a5,1
    1ae4:	02f12e23          	sw	a5,60(sp)
                back_busy = 0;                 /* 200us 保护：避开刚下发时的假空闲 */
    1ae8:	00000a93          	li	s5,0
    1aec:	da1ff06f          	j	188c <main+0x788>
                       ((uint32_t)(tick() - guard_t0) < (uint32_t)guard_us * (BSP_CLINT_HZ / 1000000u))) {
    1af0:	0c1000ef          	jal	23b0 <tick>
    1af4:	06412783          	lw	a5,100(sp)
    1af8:	40f50733          	sub	a4,a0,a5
    1afc:	06400793          	li	a5,100
    1b00:	05812683          	lw	a3,88(sp)
    1b04:	02f687b3          	mul	a5,a3,a5
            } else if (guard_us &&
    1b08:	d8f762e3          	bltu	a4,a5,188c <main+0x788>
                cache_evict();                 /* 保证 CPU 的像素对引擎可见 */
    1b0c:	0e1000ef          	jal	23ec <cache_evict>
                blt_copy_full(FB_BACK, FB_BASE);
    1b10:	003015b7          	lui	a1,0x301
    1b14:	00501537          	lui	a0,0x501
    1b18:	295000ef          	jal	25ac <blt_copy_full>
                back_t0   = (uint32_t)tick();
    1b1c:	095000ef          	jal	23b0 <tick>
    1b20:	06a12623          	sw	a0,108(sp)
                hw_done = 0; cpu_done = 0;
    1b24:	05512a23          	sw	s5,84(sp)
    1b28:	05512823          	sw	s5,80(sp)
                back_busy = 1;
    1b2c:	00100a93          	li	s5,1
                guard_t0 = 0;
    1b30:	06012223          	sw	zero,100(sp)
    1b34:	d59ff06f          	j	188c <main+0x788>
                if (blt_idle()) {
    1b38:	1f1000ef          	jal	2528 <blt_idle>
    1b3c:	da050ae3          	beqz	a0,18f0 <main+0x7ec>
                    hw_frames++; hw_frame_pushed = 0; hw_i = 0;
    1b40:	03812783          	lw	a5,56(sp)
    1b44:	00178793          	addi	a5,a5,1
    1b48:	02f12c23          	sw	a5,56(sp)
                    if (clear_pp) repaint_hw = 1;
    1b4c:	06812783          	lw	a5,104(sp)
    1b50:	00078663          	beqz	a5,1b5c <main+0xa58>
    1b54:	04812783          	lw	a5,72(sp)
    1b58:	04f12623          	sw	a5,76(sp)
                    scene_snap(g_sc[SIDE_HW], n);     /* 上一趟结束 → 为下一趟拍快照 */
    1b5c:	00048593          	mv	a1,s1
    1b60:	00004537          	lui	a0,0x4
    1b64:	0e450513          	addi	a0,a0,228 # 40e4 <g_sc>
    1b68:	468010ef          	jal	2fd0 <scene_snap>
                    hw_done = 1;
    1b6c:	04812783          	lw	a5,72(sp)
    1b70:	04f12823          	sw	a5,80(sp)
                    hw_frames++; hw_frame_pushed = 0; hw_i = 0;
    1b74:	05512423          	sw	s5,72(sp)
    1b78:	000a8413          	mv	s0,s5
    1b7c:	d75ff06f          	j	18f0 <main+0x7ec>
                int budget = fence_on ? 1 : 32;
    1b80:	06012783          	lw	a5,96(sp)
    1b84:	02078063          	beqz	a5,1ba4 <main+0xaa0>
    1b88:	00100a13          	li	s4,1
                int y0 = hw_y0(path);
    1b8c:	00090513          	mv	a0,s2
    1b90:	544010ef          	jal	30d4 <hw_y0>
    1b94:	00050b93          	mv	s7,a0
                while (budget-- > 0 && blt_can_push() && !hw_fence) {
    1b98:	06012c03          	lw	s8,96(sp)
    1b9c:	06812c83          	lw	s9,104(sp)
    1ba0:	10c0006f          	j	1cac <main+0xba8>
                int budget = fence_on ? 1 : 32;
    1ba4:	02000a13          	li	s4,32
    1ba8:	fe5ff06f          	j	1b8c <main+0xa88>
                        blt_fill(FB_BACK + (uint32_t)(b->dy + y0) * FB_STRIDE
    1bac:	000047b7          	lui	a5,0x4
    1bb0:	00241713          	slli	a4,s0,0x2
    1bb4:	00870733          	add	a4,a4,s0
    1bb8:	00271713          	slli	a4,a4,0x2
    1bbc:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1bc0:	00e787b3          	add	a5,a5,a4
    1bc4:	00a79703          	lh	a4,10(a5)
    1bc8:	01770733          	add	a4,a4,s7
                                          + (uint32_t)b->dx * 2u,
    1bcc:	00879683          	lh	a3,8(a5)
    1bd0:	00471513          	slli	a0,a4,0x4
    1bd4:	40e50533          	sub	a0,a0,a4
    1bd8:	00651513          	slli	a0,a0,0x6
    1bdc:	00d50533          	add	a0,a0,a3
    1be0:	00281737          	lui	a4,0x281
    1be4:	80070713          	addi	a4,a4,-2048 # 280800 <__freertos_irq_stack_top+0x2749b0>
    1be8:	00e50533          	add	a0,a0,a4
                                 FB_STRIDE, b->sz, b->sz, COL_BG);
    1bec:	0127c603          	lbu	a2,18(a5)
                        blt_fill(FB_BACK + (uint32_t)(b->dy + y0) * FB_STRIDE
    1bf0:	00800713          	li	a4,8
    1bf4:	00060693          	mv	a3,a2
    1bf8:	78000593          	li	a1,1920
    1bfc:	00151513          	slli	a0,a0,0x1
    1c00:	1e9000ef          	jal	25e8 <blt_fill>
                        uint32_t dst = FB_BACK + (uint32_t)(b->ty + y0) * FB_STRIDE
    1c04:	000047b7          	lui	a5,0x4
    1c08:	00241713          	slli	a4,s0,0x2
    1c0c:	00870733          	add	a4,a4,s0
    1c10:	00271713          	slli	a4,a4,0x2
    1c14:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1c18:	00e787b3          	add	a5,a5,a4
    1c1c:	00e79703          	lh	a4,14(a5)
    1c20:	01770733          	add	a4,a4,s7
                                             + (uint32_t)b->tx * 2u;
    1c24:	00c79783          	lh	a5,12(a5)
    1c28:	00471513          	slli	a0,a4,0x4
    1c2c:	40e50533          	sub	a0,a0,a4
    1c30:	00651513          	slli	a0,a0,0x6
    1c34:	00f50533          	add	a0,a0,a5
    1c38:	002817b7          	lui	a5,0x281
    1c3c:	80078793          	addi	a5,a5,-2048 # 280800 <__freertos_irq_stack_top+0x2749b0>
    1c40:	00f50533          	add	a0,a0,a5
                        uint32_t dst = FB_BACK + (uint32_t)(b->ty + y0) * FB_STRIDE
    1c44:	00151513          	slli	a0,a0,0x1
                        if (scene == SC_FILL)
    1c48:	0c098a63          	beqz	s3,1d1c <main+0xc18>
                        else if (scene == SC_ALPHA)
    1c4c:	00100793          	li	a5,1
    1c50:	0ef98e63          	beq	s3,a5,1d4c <main+0xc48>
                            blt_key(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE,
    1c54:	00010837          	lui	a6,0x10
    1c58:	81f80813          	addi	a6,a6,-2017 # f81f <__freertos_irq_stack_top+0x39cf>
    1c5c:	02000793          	li	a5,32
    1c60:	02000713          	li	a4,32
    1c64:	78000693          	li	a3,1920
    1c68:	04000613          	li	a2,64
    1c6c:	00050593          	mv	a1,a0
    1c70:	00201537          	lui	a0,0x201
    1c74:	1ed000ef          	jal	2660 <blt_key>
                    b->dx = b->tx; b->dy = b->ty;                  /* 记账：画的就是快照位置 */
    1c78:	000047b7          	lui	a5,0x4
    1c7c:	00241713          	slli	a4,s0,0x2
    1c80:	00870733          	add	a4,a4,s0
    1c84:	00271713          	slli	a4,a4,0x2
    1c88:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1c8c:	00e787b3          	add	a5,a5,a4
    1c90:	00c79703          	lh	a4,12(a5)
    1c94:	00e79423          	sh	a4,8(a5)
    1c98:	00e79703          	lh	a4,14(a5)
    1c9c:	00e79523          	sh	a4,10(a5)
                    if (++hw_i >= n) { hw_frame_pushed = 1; break; }
    1ca0:	00140413          	addi	s0,s0,1
    1ca4:	0c945663          	bge	s0,s1,1d70 <main+0xc6c>
                    if (fence_on) { hw_fence = 1; break; }   /* 围栏：等这块彻底落地再发下一块 */
    1ca8:	0c0c1a63          	bnez	s8,1d7c <main+0xc78>
                while (budget-- > 0 && blt_can_push() && !hw_fence) {
    1cac:	000a0793          	mv	a5,s4
    1cb0:	fffa0a13          	addi	s4,s4,-1
    1cb4:	c2f05ee3          	blez	a5,18f0 <main+0x7ec>
    1cb8:	095000ef          	jal	254c <blt_can_push>
    1cbc:	c2050ae3          	beqz	a0,18f0 <main+0x7ec>
    1cc0:	c20d18e3          	bnez	s10,18f0 <main+0x7ec>
                    if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
    1cc4:	f40c90e3          	bnez	s9,1c04 <main+0xb00>
    1cc8:	00100793          	li	a5,1
    1ccc:	eef980e3          	beq	s3,a5,1bac <main+0xaa8>
    1cd0:	000047b7          	lui	a5,0x4
    1cd4:	00241713          	slli	a4,s0,0x2
    1cd8:	00870733          	add	a4,a4,s0
    1cdc:	00271713          	slli	a4,a4,0x2
    1ce0:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1ce4:	00e787b3          	add	a5,a5,a4
    1ce8:	00879703          	lh	a4,8(a5)
    1cec:	00c79783          	lh	a5,12(a5)
    1cf0:	eaf71ee3          	bne	a4,a5,1bac <main+0xaa8>
    1cf4:	000047b7          	lui	a5,0x4
    1cf8:	00241713          	slli	a4,s0,0x2
    1cfc:	00870733          	add	a4,a4,s0
    1d00:	00271713          	slli	a4,a4,0x2
    1d04:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1d08:	00e787b3          	add	a5,a5,a4
    1d0c:	00a79703          	lh	a4,10(a5)
    1d10:	00e79783          	lh	a5,14(a5)
    1d14:	e8f71ce3          	bne	a4,a5,1bac <main+0xaa8>
    1d18:	eedff06f          	j	1c04 <main+0xb00>
                            blt_fill(dst, FB_STRIDE, b->sz, b->sz, b->color);
    1d1c:	000047b7          	lui	a5,0x4
    1d20:	00241713          	slli	a4,s0,0x2
    1d24:	00870733          	add	a4,a4,s0
    1d28:	00271713          	slli	a4,a4,0x2
    1d2c:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1d30:	00e787b3          	add	a5,a5,a4
    1d34:	0127c603          	lbu	a2,18(a5)
    1d38:	0107d703          	lhu	a4,16(a5)
    1d3c:	00060693          	mv	a3,a2
    1d40:	78000593          	li	a1,1920
    1d44:	0a5000ef          	jal	25e8 <blt_fill>
    1d48:	f31ff06f          	j	1c78 <main+0xb74>
                            blt_alpha(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE,
    1d4c:	02812803          	lw	a6,40(sp)
    1d50:	02000793          	li	a5,32
    1d54:	02000713          	li	a4,32
    1d58:	78000693          	li	a3,1920
    1d5c:	04000613          	li	a2,64
    1d60:	00050593          	mv	a1,a0
    1d64:	00201537          	lui	a0,0x201
    1d68:	0bd000ef          	jal	2624 <blt_alpha>
    1d6c:	f0dff06f          	j	1c78 <main+0xb74>
                    if (++hw_i >= n) { hw_frame_pushed = 1; break; }
    1d70:	00100793          	li	a5,1
    1d74:	04f12423          	sw	a5,72(sp)
    1d78:	b79ff06f          	j	18f0 <main+0x7ec>
                    if (fence_on) { hw_fence = 1; break; }   /* 围栏：等这块彻底落地再发下一块 */
    1d7c:	00100d13          	li	s10,1
    1d80:	b71ff06f          	j	18f0 <main+0x7ec>
                cpu_fill32(FB_BACK, 0, cpu_y0(path), FB_WIDTH, cpu_h(path), COL_BG);
    1d84:	00090513          	mv	a0,s2
    1d88:	37c010ef          	jal	3104 <cpu_h>
    1d8c:	00050713          	mv	a4,a0
    1d90:	00800793          	li	a5,8
    1d94:	3c000693          	li	a3,960
    1d98:	000a0613          	mv	a2,s4
    1d9c:	00000593          	li	a1,0
    1da0:	00501537          	lui	a0,0x501
    1da4:	205000ef          	jal	27a8 <cpu_fill32>
                repaint_cpu = 0;
    1da8:	05512223          	sw	s5,68(sp)
    1dac:	b65ff06f          	j	1910 <main+0x80c>
            if ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty))
    1db0:	000047b7          	lui	a5,0x4
    1db4:	002b1713          	slli	a4,s6,0x2
    1db8:	01670733          	add	a4,a4,s6
    1dbc:	00271713          	slli	a4,a4,0x2
    1dc0:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1dc4:	00e787b3          	add	a5,a5,a4
    1dc8:	00003737          	lui	a4,0x3
    1dcc:	00f707b3          	add	a5,a4,a5
    1dd0:	6ba79703          	lh	a4,1722(a5)
    1dd4:	6be79783          	lh	a5,1726(a5)
    1dd8:	b6f716e3          	bne	a4,a5,1944 <main+0x840>
    1ddc:	ba9ff06f          	j	1984 <main+0x880>
                cpu_fill32(FB_BACK, b->tx, b->ty + y0, b->sz, b->sz, b->color);
    1de0:	000047b7          	lui	a5,0x4
    1de4:	002b1713          	slli	a4,s6,0x2
    1de8:	01670733          	add	a4,a4,s6
    1dec:	00271713          	slli	a4,a4,0x2
    1df0:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1df4:	00e787b3          	add	a5,a5,a4
    1df8:	000035b7          	lui	a1,0x3
    1dfc:	00f585b3          	add	a1,a1,a5
    1e00:	6be59603          	lh	a2,1726(a1) # 36be <__udivdi3+0x462>
    1e04:	6c25c683          	lbu	a3,1730(a1)
    1e08:	6c05d783          	lhu	a5,1728(a1)
    1e0c:	00068713          	mv	a4,a3
    1e10:	01460633          	add	a2,a2,s4
    1e14:	6bc59583          	lh	a1,1724(a1)
    1e18:	00501537          	lui	a0,0x501
    1e1c:	18d000ef          	jal	27a8 <cpu_fill32>
    1e20:	ba1ff06f          	j	19c0 <main+0x8bc>
                cpu_alpha_sprite(b->tx, b->ty + y0, alpha);
    1e24:	000047b7          	lui	a5,0x4
    1e28:	002b1713          	slli	a4,s6,0x2
    1e2c:	01670733          	add	a4,a4,s6
    1e30:	00271713          	slli	a4,a4,0x2
    1e34:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    1e38:	00e787b3          	add	a5,a5,a4
    1e3c:	00003737          	lui	a4,0x3
    1e40:	00f707b3          	add	a5,a4,a5
    1e44:	6be79583          	lh	a1,1726(a5)
    1e48:	02812603          	lw	a2,40(sp)
    1e4c:	014585b3          	add	a1,a1,s4
    1e50:	6bc79503          	lh	a0,1724(a5)
    1e54:	2f1000ef          	jal	2944 <cpu_alpha_sprite>
    1e58:	b69ff06f          	j	19c0 <main+0x8bc>
                cpu_i = 0; cpu_frames++;
    1e5c:	03012783          	lw	a5,48(sp)
    1e60:	00178793          	addi	a5,a5,1
    1e64:	02f12823          	sw	a5,48(sp)
                scene_snap(g_sc[SIDE_CPU], n);   /* 上一趟结束 → 为下一趟拍快照 */
    1e68:	00048593          	mv	a1,s1
    1e6c:	00007537          	lui	a0,0x7
    1e70:	79450513          	addi	a0,a0,1940 # 7794 <__global_pointer$+0x2ecc>
    1e74:	15c010ef          	jal	2fd0 <scene_snap>
                cpu_i = 0; cpu_frames++;
    1e78:	000a8b13          	mv	s6,s5
                cpu_done = 1;
    1e7c:	00100793          	li	a5,1
    1e80:	04f12a23          	sw	a5,84(sp)
    1e84:	b75ff06f          	j	19f8 <main+0x8f4>
            p = app(p, (path == PATH_SPLIT) ? "SPLIT " :
    1e88:	000035b7          	lui	a1,0x3
    1e8c:	79458593          	addi	a1,a1,1940 # 3794 <_data+0x88>
    1e90:	00c0006f          	j	1e9c <main+0xd98>
    1e94:	000035b7          	lui	a1,0x3
    1e98:	78858593          	addi	a1,a1,1928 # 3788 <_data+0x7c>
    1e9c:	07810513          	addi	a0,sp,120
    1ea0:	5d5000ef          	jal	2c74 <app>
                       ((path == PATH_CPU) ? "CPUMODE " : "HWMODE "));
            p = app(p, (scene == SC_FILL) ? "FILL " :
    1ea4:	02098263          	beqz	s3,1ec8 <main+0xdc4>
    1ea8:	00100793          	li	a5,1
    1eac:	00f98863          	beq	s3,a5,1ebc <main+0xdb8>
    1eb0:	000035b7          	lui	a1,0x3
    1eb4:	7a058593          	addi	a1,a1,1952 # 37a0 <_data+0x94>
    1eb8:	0180006f          	j	1ed0 <main+0xdcc>
    1ebc:	000035b7          	lui	a1,0x3
    1ec0:	7b058593          	addi	a1,a1,1968 # 37b0 <_data+0xa4>
    1ec4:	00c0006f          	j	1ed0 <main+0xdcc>
    1ec8:	000035b7          	lui	a1,0x3
    1ecc:	7a858593          	addi	a1,a1,1960 # 37a8 <_data+0x9c>
    1ed0:	5a5000ef          	jal	2c74 <app>
                       ((scene == SC_ALPHA) ? "ALPHA " : "KEY "));
            p = app(p, "N");    p = appn(p, (unsigned)n, 4);
    1ed4:	000045b7          	lui	a1,0x4
    1ed8:	bcc58593          	addi	a1,a1,-1076 # 3bcc <_data+0x4c0>
    1edc:	599000ef          	jal	2c74 <app>
    1ee0:	00400613          	li	a2,4
    1ee4:	00048593          	mv	a1,s1
    1ee8:	5a9000ef          	jal	2c90 <appn>
            p = app(p, " A");   p = appn(p, alpha, 4);
    1eec:	000045b7          	lui	a1,0x4
    1ef0:	bd058593          	addi	a1,a1,-1072 # 3bd0 <_data+0x4c4>
    1ef4:	581000ef          	jal	2c74 <app>
    1ef8:	00400613          	li	a2,4
    1efc:	02812583          	lw	a1,40(sp)
    1f00:	591000ef          	jal	2c90 <appn>
            p = app(p, " HW");  p = appn(p, hw_fps, 5);
    1f04:	000045b7          	lui	a1,0x4
    1f08:	bd458593          	addi	a1,a1,-1068 # 3bd4 <_data+0x4c8>
    1f0c:	569000ef          	jal	2c74 <app>
    1f10:	00500613          	li	a2,5
    1f14:	000c8593          	mv	a1,s9
    1f18:	579000ef          	jal	2c90 <appn>
            p = app(p, " CPU"); p = appn(p, cpu_fps, 5);
    1f1c:	000045b7          	lui	a1,0x4
    1f20:	bd858593          	addi	a1,a1,-1064 # 3bd8 <_data+0x4cc>
    1f24:	551000ef          	jal	2c74 <app>
    1f28:	00500613          	li	a2,5
    1f2c:	000a0593          	mv	a1,s4
    1f30:	561000ef          	jal	2c90 <appn>
            p = app(p, " SCR");p = appn(p, disp_fps, 5);
    1f34:	000045b7          	lui	a1,0x4
    1f38:	be058593          	addi	a1,a1,-1056 # 3be0 <_data+0x4d4>
    1f3c:	539000ef          	jal	2c74 <app>
    1f40:	00500613          	li	a2,5
    1f44:	03812583          	lw	a1,56(sp)
    1f48:	549000ef          	jal	2c90 <appn>
            *p = 0;
    1f4c:	00050023          	sb	zero,0(a0)
            osd_text(8, 4, line, COL_WHITE);
    1f50:	000106b7          	lui	a3,0x10
    1f54:	fff68693          	addi	a3,a3,-1 # ffff <__freertos_irq_stack_top+0x41af>
    1f58:	07810613          	addi	a2,sp,120
    1f5c:	00400593          	li	a1,4
    1f60:	00800513          	li	a0,8
    1f64:	3b1000ef          	jal	2b14 <osd_text>

            /* ★ 分隔条与两侧标签**只在分屏模式画**：单模式是整屏渲染，中间不该有一条线，
             *   也不该残留上一次模式画的 "CPU"/"HW" 字样。
             *   （单模式下切换路径会触发整区重铺，把旧标签一起清掉。） */
            if (path == PATH_SPLIT) {
    1f68:	0e091863          	bnez	s2,2058 <main+0xf54>
                osd_text(8, TOP_Y0 + 4, "HW", COL_HW_FG);
    1f6c:	000106b7          	lui	a3,0x10
    1f70:	fe068693          	addi	a3,a3,-32 # ffe0 <__freertos_irq_stack_top+0x4190>
    1f74:	00004637          	lui	a2,0x4
    1f78:	be860613          	addi	a2,a2,-1048 # 3be8 <_data+0x4dc>
    1f7c:	01400593          	li	a1,20
    1f80:	00800513          	li	a0,8
    1f84:	391000ef          	jal	2b14 <osd_text>
                cpu_fill32(FB_BACK, 0, TOP_Y0 + HALF_H, FB_WIDTH, SEP_H, COL_SEP);
    1f88:	000047b7          	lui	a5,0x4
    1f8c:	20878793          	addi	a5,a5,520 # 4208 <g_sc+0x124>
    1f90:	00400713          	li	a4,4
    1f94:	3c000693          	li	a3,960
    1f98:	11400613          	li	a2,276
    1f9c:	00000593          	li	a1,0
    1fa0:	00501537          	lui	a0,0x501
    1fa4:	005000ef          	jal	27a8 <cpu_fill32>
                osd_text(8, BOT_Y0 + 4, "CPU", COL_CPU_FG);
    1fa8:	7ff00693          	li	a3,2047
    1fac:	00004637          	lui	a2,0x4
    1fb0:	bec60613          	addi	a2,a2,-1044 # 3bec <_data+0x4e0>
    1fb4:	11c00593          	li	a1,284
    1fb8:	00800513          	li	a0,8
    1fbc:	359000ef          	jal	2b14 <osd_text>
            } else if (path == PATH_CPU) {
                osd_text(8, TOP_Y0 + 4, "CPU ONLY", COL_CPU_FG);
            } else {
                osd_text(8, TOP_Y0 + 4, "HW ONLY", COL_HW_FG);
            }
            cache_evict();
    1fc0:	42c000ef          	jal	23ec <cache_evict>

            bsp_printf("S it=%d d=%d p=%d sc=%d N=%d A=%d HW=%d CPU=%d C=%d ST=%x ab=%d un=%d\r\n",
                       (int)it, (int)d_it, path, scene, n, (int)alpha,
                       (int)hw_fps, (int)cpu_fps,
                       (int)blt_cnt(), (unsigned)blt_stat(),
    1fc4:	52c000ef          	jal	24f0 <blt_cnt>
    1fc8:	00050b93          	mv	s7,a0
    1fcc:	540000ef          	jal	250c <blt_stat>
                       (int)(sc >> 16), (int)(sc & 0xFFFFu));
    1fd0:	04012783          	lw	a5,64(sp)
    1fd4:	0107d713          	srli	a4,a5,0x10
            bsp_printf("S it=%d d=%d p=%d sc=%d N=%d A=%d HW=%d CPU=%d C=%d ST=%x ab=%d un=%d\r\n",
    1fd8:	01079793          	slli	a5,a5,0x10
    1fdc:	0107d793          	srli	a5,a5,0x10
    1fe0:	00f12823          	sw	a5,16(sp)
    1fe4:	00e12623          	sw	a4,12(sp)
    1fe8:	00a12423          	sw	a0,8(sp)
    1fec:	01712223          	sw	s7,4(sp)
    1ff0:	01412023          	sw	s4,0(sp)
    1ff4:	000c8893          	mv	a7,s9
    1ff8:	02812803          	lw	a6,40(sp)
    1ffc:	00048793          	mv	a5,s1
    2000:	00098713          	mv	a4,s3
    2004:	00090693          	mv	a3,s2
    2008:	000c0613          	mv	a2,s8
    200c:	000d8593          	mv	a1,s11
    2010:	00004537          	lui	a0,0x4
    2014:	c0450513          	addi	a0,a0,-1020 # 3c04 <_data+0x4f8>
    2018:	114010ef          	jal	312c <bsp_printf>
            it_prev = it;
    201c:	05b12023          	sw	s11,64(sp)

            hw_frames = 0; cpu_frames = 0; disp_frames = 0;
    2020:	02012e23          	sw	zero,60(sp)
    2024:	02012823          	sw	zero,48(sp)
    2028:	02012c23          	sw	zero,56(sp)
        it++;
    202c:	001d8d93          	addi	s11,s11,1
        if (hw_fence && blt_idle()) hw_fence = 0;   /* 围栏：引擎做完了才继续发 */
    2030:	ac0d1c63          	bnez	s10,1308 <main+0x204>
        c = uart_poll_char();
    2034:	4f5000ef          	jal	2d28 <uart_poll_char>
        if (c) {
    2038:	07300793          	li	a5,115
    203c:	f6a7e863          	bltu	a5,a0,17ac <main+0x6a8>
    2040:	00251793          	slli	a5,a0,0x2
    2044:	00004737          	lui	a4,0x4
    2048:	cd070713          	addi	a4,a4,-816 # 3cd0 <_data+0x5c4>
    204c:	00e787b3          	add	a5,a5,a4
    2050:	0007a783          	lw	a5,0(a5)
    2054:	00078067          	jr	a5
            } else if (path == PATH_CPU) {
    2058:	00100793          	li	a5,1
    205c:	02f90263          	beq	s2,a5,2080 <main+0xf7c>
                osd_text(8, TOP_Y0 + 4, "HW ONLY", COL_HW_FG);
    2060:	000106b7          	lui	a3,0x10
    2064:	fe068693          	addi	a3,a3,-32 # ffe0 <__freertos_irq_stack_top+0x4190>
    2068:	00004637          	lui	a2,0x4
    206c:	bfc60613          	addi	a2,a2,-1028 # 3bfc <_data+0x4f0>
    2070:	01400593          	li	a1,20
    2074:	00800513          	li	a0,8
    2078:	29d000ef          	jal	2b14 <osd_text>
    207c:	f45ff06f          	j	1fc0 <main+0xebc>
                osd_text(8, TOP_Y0 + 4, "CPU ONLY", COL_CPU_FG);
    2080:	7ff00693          	li	a3,2047
    2084:	00004637          	lui	a2,0x4
    2088:	bf060613          	addi	a2,a2,-1040 # 3bf0 <_data+0x4e4>
    208c:	01400593          	li	a1,20
    2090:	00800513          	li	a0,8
    2094:	281000ef          	jal	2b14 <osd_text>
    2098:	f29ff06f          	j	1fc0 <main+0xebc>

0000209c <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    209c:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    20a0:	01055513          	srli	a0,a0,0x10
    }
    20a4:	0ff57513          	zext.b	a0,a0
    20a8:	00008067          	ret

000020ac <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    20ac:	ff010113          	addi	sp,sp,-16
    20b0:	00112623          	sw	ra,12(sp)
    20b4:	00812423          	sw	s0,8(sp)
    20b8:	00912223          	sw	s1,4(sp)
    20bc:	00050413          	mv	s0,a0
    20c0:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    20c4:	00040513          	mv	a0,s0
    20c8:	fd5ff0ef          	jal	209c <uart_writeAvailability>
    20cc:	fe050ce3          	beqz	a0,20c4 <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    20d0:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    20d4:	00c12083          	lw	ra,12(sp)
    20d8:	00812403          	lw	s0,8(sp)
    20dc:	00412483          	lw	s1,4(sp)
    20e0:	01010113          	addi	sp,sp,16
    20e4:	00008067          	ret

000020e8 <uart_applyConfig>:
*          value using data length, parity, and stop bit settings from the configuration
*          structure, and writes this value to the UART frame configuration register.
*
******************************************************************************/
    static void uart_applyConfig(u32 reg, Uart_Config *config){
        write_u32(config->clockDivider, reg + UART_CLOCK_DIVIDER);
    20e8:	00c5a783          	lw	a5,12(a1)
    20ec:	00f52423          	sw	a5,8(a0)
        write_u32(((config->dataLength-1) << 0) | (config->parity << 8) | (config->stop << 16), reg + UART_FRAME_CONFIG);
    20f0:	0005a783          	lw	a5,0(a1)
    20f4:	fff78793          	addi	a5,a5,-1
    20f8:	0045a703          	lw	a4,4(a1)
    20fc:	00871713          	slli	a4,a4,0x8
    2100:	00e7e7b3          	or	a5,a5,a4
    2104:	0085a703          	lw	a4,8(a1)
    2108:	01071713          	slli	a4,a4,0x10
    210c:	00e7e7b3          	or	a5,a5,a4
    2110:	00f52623          	sw	a5,12(a0)
    }
    2114:	00008067          	ret

00002118 <clint_getTime>:
*          to guard against rollover. It checks if the high part remains unchanged
*          during the read operation to ensure consistency. The high and low parts
*          are then combined to form the 64-bit current time value.
*
******************************************************************************/
    static u64 clint_getTime(u32 p){
    2118:	00050693          	mv	a3,a0
    readReg_u32 (clint_getTimeHigh, CLINT_TIME_ADDR+4)
    211c:	0000c7b7          	lui	a5,0xc
    2120:	ffc78793          	addi	a5,a5,-4 # bffc <__freertos_irq_stack_top+0x1ac>
    2124:	00f687b3          	add	a5,a3,a5
        return *((volatile u32*) address);
    2128:	0007a583          	lw	a1,0(a5)
    readReg_u32 (clint_getTimeLow , CLINT_TIME_ADDR)
    212c:	0000c737          	lui	a4,0xc
    2130:	ff870713          	addi	a4,a4,-8 # bff8 <__freertos_irq_stack_top+0x1a8>
    2134:	00e68733          	add	a4,a3,a4
    2138:	00072503          	lw	a0,0(a4)
    213c:	0007a783          	lw	a5,0(a5)
    
        /* Likewise, must guard against rollover when reading */
        do {
            hi = clint_getTimeHigh(p);
            lo = clint_getTimeLow(p);
        } while (clint_getTimeHigh(p) != hi);
    2140:	fcb79ee3          	bne	a5,a1,211c <clint_getTime+0x4>
    
        return (((u64)hi) << 32) | lo;
    }
    2144:	00008067          	ret

00002148 <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    2148:	ff010113          	addi	sp,sp,-16
    214c:	00112623          	sw	ra,12(sp)
    2150:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    2154:	f8010537          	lui	a0,0xf8010
    2158:	f55ff0ef          	jal	20ac <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    215c:	00c12083          	lw	ra,12(sp)
    2160:	01010113          	addi	sp,sp,16
    2164:	00008067          	ret

00002168 <_putchar_s>:

    static void _putchar_s(char *p)
    {
    2168:	ff010113          	addi	sp,sp,-16
    216c:	00112623          	sw	ra,12(sp)
    2170:	00812423          	sw	s0,8(sp)
    2174:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    2178:	00c0006f          	j	2184 <_putchar_s+0x1c>
            _putchar(*(p++));
    217c:	00140413          	addi	s0,s0,1
    2180:	fc9ff0ef          	jal	2148 <_putchar>
        while (*p)
    2184:	00044503          	lbu	a0,0(s0)
    2188:	fe051ae3          	bnez	a0,217c <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    218c:	00c12083          	lw	ra,12(sp)
    2190:	00812403          	lw	s0,8(sp)
    2194:	01010113          	addi	sp,sp,16
    2198:	00008067          	ret

0000219c <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    219c:	ff010113          	addi	sp,sp,-16
    21a0:	00112623          	sw	ra,12(sp)
    21a4:	00812423          	sw	s0,8(sp)
    21a8:	00912223          	sw	s1,4(sp)
    21ac:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    21b0:	01c00413          	li	s0,28
    21b4:	0240006f          	j	21d8 <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    21b8:	0084d733          	srl	a4,s1,s0
    21bc:	00f77713          	andi	a4,a4,15
    21c0:	000037b7          	lui	a5,0x3
    21c4:	70c78793          	addi	a5,a5,1804 # 370c <_data>
    21c8:	00e787b3          	add	a5,a5,a4
    21cc:	0007c503          	lbu	a0,0(a5)
    21d0:	f79ff0ef          	jal	2148 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    21d4:	ffc40413          	addi	s0,s0,-4
    21d8:	fe0450e3          	bgez	s0,21b8 <bsp_printHex+0x1c>
        }
    }
    21dc:	00c12083          	lw	ra,12(sp)
    21e0:	00812403          	lw	s0,8(sp)
    21e4:	00412483          	lw	s1,4(sp)
    21e8:	01010113          	addi	sp,sp,16
    21ec:	00008067          	ret

000021f0 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    21f0:	ff010113          	addi	sp,sp,-16
    21f4:	00112623          	sw	ra,12(sp)
    21f8:	00812423          	sw	s0,8(sp)
    21fc:	00912223          	sw	s1,4(sp)
    2200:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2204:	01c00413          	li	s0,28
    2208:	0240006f          	j	222c <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    220c:	0084d733          	srl	a4,s1,s0
    2210:	00f77713          	andi	a4,a4,15
    2214:	000037b7          	lui	a5,0x3
    2218:	72078793          	addi	a5,a5,1824 # 3720 <_data+0x14>
    221c:	00e787b3          	add	a5,a5,a4
    2220:	0007c503          	lbu	a0,0(a5)
    2224:	f25ff0ef          	jal	2148 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2228:	ffc40413          	addi	s0,s0,-4
    222c:	fe0450e3          	bgez	s0,220c <bsp_printHex_lower+0x1c>

        }
    }
    2230:	00c12083          	lw	ra,12(sp)
    2234:	00812403          	lw	s0,8(sp)
    2238:	00412483          	lw	s1,4(sp)
    223c:	01010113          	addi	sp,sp,16
    2240:	00008067          	ret

00002244 <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    2244:	ff010113          	addi	sp,sp,-16
    2248:	00112623          	sw	ra,12(sp)
        _putchar(c);
    224c:	0ff57513          	zext.b	a0,a0
    2250:	ef9ff0ef          	jal	2148 <_putchar>
    }
    2254:	00c12083          	lw	ra,12(sp)
    2258:	01010113          	addi	sp,sp,16
    225c:	00008067          	ret

00002260 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    2260:	ff010113          	addi	sp,sp,-16
    2264:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    2268:	f01ff0ef          	jal	2168 <_putchar_s>
    }
    226c:	00c12083          	lw	ra,12(sp)
    2270:	01010113          	addi	sp,sp,16
    2274:	00008067          	ret

00002278 <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    2278:	fd010113          	addi	sp,sp,-48
    227c:	02112623          	sw	ra,44(sp)
    2280:	02812423          	sw	s0,40(sp)
    2284:	02912223          	sw	s1,36(sp)
    2288:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    228c:	00054663          	bltz	a0,2298 <bsp_printf_d+0x20>
    {
    2290:	00010413          	mv	s0,sp
    2294:	02c0006f          	j	22c0 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    2298:	02d00513          	li	a0,45
    229c:	fa9ff0ef          	jal	2244 <bsp_printf_c>
            val = -val;
    22a0:	409004b3          	neg	s1,s1
    22a4:	fedff06f          	j	2290 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    22a8:	00a00713          	li	a4,10
    22ac:	02e4e7b3          	rem	a5,s1,a4
    22b0:	03078793          	addi	a5,a5,48
    22b4:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    22b8:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    22bc:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    22c0:	fe0494e3          	bnez	s1,22a8 <bsp_printf_d+0x30>
    22c4:	00010793          	mv	a5,sp
    22c8:	fef400e3          	beq	s0,a5,22a8 <bsp_printf_d+0x30>
        }
        while (p != buffer)
    22cc:	00010793          	mv	a5,sp
    22d0:	00f40a63          	beq	s0,a5,22e4 <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    22d4:	fff40413          	addi	s0,s0,-1
    22d8:	00044503          	lbu	a0,0(s0)
    22dc:	f69ff0ef          	jal	2244 <bsp_printf_c>
    22e0:	fedff06f          	j	22cc <bsp_printf_d+0x54>
    }
    22e4:	02c12083          	lw	ra,44(sp)
    22e8:	02812403          	lw	s0,40(sp)
    22ec:	02412483          	lw	s1,36(sp)
    22f0:	03010113          	addi	sp,sp,48
    22f4:	00008067          	ret

000022f8 <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    22f8:	ff010113          	addi	sp,sp,-16
    22fc:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    2300:	00000713          	li	a4,0
    2304:	00700793          	li	a5,7
    2308:	02e7c063          	blt	a5,a4,2328 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    230c:	00271693          	slli	a3,a4,0x2
    2310:	ff000793          	li	a5,-16
    2314:	00d797b3          	sll	a5,a5,a3
    2318:	00f577b3          	and	a5,a0,a5
    231c:	00078663          	beqz	a5,2328 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    2320:	00170713          	addi	a4,a4,1
    2324:	fe1ff06f          	j	2304 <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    2328:	ec9ff0ef          	jal	21f0 <bsp_printHex_lower>
    }
    232c:	00c12083          	lw	ra,12(sp)
    2330:	01010113          	addi	sp,sp,16
    2334:	00008067          	ret

00002338 <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    2338:	ff010113          	addi	sp,sp,-16
    233c:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    2340:	00000713          	li	a4,0
    2344:	00700793          	li	a5,7
    2348:	02e7c063          	blt	a5,a4,2368 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    234c:	00271693          	slli	a3,a4,0x2
    2350:	ff000793          	li	a5,-16
    2354:	00d797b3          	sll	a5,a5,a3
    2358:	00f577b3          	and	a5,a0,a5
    235c:	00078663          	beqz	a5,2368 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    2360:	00170713          	addi	a4,a4,1
    2364:	fe1ff06f          	j	2344 <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    2368:	e35ff0ef          	jal	219c <bsp_printHex>
        }
    236c:	00c12083          	lw	ra,12(sp)
    2370:	01010113          	addi	sp,sp,16
    2374:	00008067          	ret

00002378 <bsp_init>:
    *   1. UART baudrate
    *   2. 
    */
////////////////////////////////////////////////////////////////////////////////
    static void bsp_init()
    {
    2378:	fe010113          	addi	sp,sp,-32
    237c:	00112e23          	sw	ra,28(sp)
        Uart_Config uartConfig;
        uartConfig.dataLength   = BITS_8;
    2380:	00800793          	li	a5,8
    2384:	00f12023          	sw	a5,0(sp)
        uartConfig.parity       = NONE;
    2388:	00012223          	sw	zero,4(sp)
        uartConfig.stop         = ONE;
    238c:	00012423          	sw	zero,8(sp)
        uartConfig.clockDivider = BSP_CLINT_HZ/(BSP_UART_BAUDRATE*BSP_UART_DATA_LEN)-1;
    2390:	06b00793          	li	a5,107
    2394:	00f12623          	sw	a5,12(sp)
        uart_applyConfig(BSP_UART_TERMINAL, &uartConfig);    
    2398:	00010593          	mv	a1,sp
    239c:	f8010537          	lui	a0,0xf8010
    23a0:	d49ff0ef          	jal	20e8 <uart_applyConfig>
    }
    23a4:	01c12083          	lw	ra,28(sp)
    23a8:	02010113          	addi	sp,sp,32
    23ac:	00008067          	ret

000023b0 <tick>:
static uint64_t tick(void) { return clint_getTime(BSP_CLINT); }
    23b0:	ff010113          	addi	sp,sp,-16
    23b4:	00112623          	sw	ra,12(sp)
    23b8:	f8b00537          	lui	a0,0xf8b00
    23bc:	d5dff0ef          	jal	2118 <clint_getTime>
    23c0:	00c12083          	lw	ra,12(sp)
    23c4:	01010113          	addi	sp,sp,16
    23c8:	00008067          	ret

000023cc <blt_wr>:
static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
    23cc:	f81007b7          	lui	a5,0xf8100
    23d0:	00f50533          	add	a0,a0,a5
    23d4:	00b52023          	sw	a1,0(a0) # f8b00000 <__freertos_irq_stack_top+0xf8af41b0>
    23d8:	00008067          	ret

000023dc <blt_rd>:
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }
    23dc:	f81007b7          	lui	a5,0xf8100
    23e0:	00f50533          	add	a0,a0,a5
    23e4:	00052503          	lw	a0,0(a0)
    23e8:	00008067          	ret

000023ec <cache_evict>:
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
    23ec:	00000793          	li	a5,0
    23f0:	0200006f          	j	2410 <cache_evict+0x24>
    23f4:	00279693          	slli	a3,a5,0x2
    23f8:	00601737          	lui	a4,0x601
    23fc:	00d70733          	add	a4,a4,a3
    2400:	a5a506b7          	lui	a3,0xa5a50
    2404:	00d786b3          	add	a3,a5,a3
    2408:	00d72023          	sw	a3,0(a4) # 601000 <__freertos_irq_stack_top+0x5f51b0>
    240c:	00178793          	addi	a5,a5,1 # f8100001 <__freertos_irq_stack_top+0xf80f41b1>
    2410:	7ff00713          	li	a4,2047
    2414:	fef770e3          	bgeu	a4,a5,23f4 <cache_evict+0x8>
}
    2418:	00008067          	ret

0000241c <blt_emit>:
{
    241c:	fe010113          	addi	sp,sp,-32
    2420:	00112e23          	sw	ra,28(sp)
    2424:	00812c23          	sw	s0,24(sp)
    2428:	00912a23          	sw	s1,20(sp)
    242c:	01212823          	sw	s2,16(sp)
    2430:	01312623          	sw	s3,12(sp)
    2434:	01412423          	sw	s4,8(sp)
    2438:	01512223          	sw	s5,4(sp)
    243c:	01612023          	sw	s6,0(sp)
    2440:	00058b13          	mv	s6,a1
    2444:	00060a93          	mv	s5,a2
    2448:	00068a13          	mv	s4,a3
    244c:	00070993          	mv	s3,a4
    2450:	00078413          	mv	s0,a5
    2454:	00080493          	mv	s1,a6
    2458:	00088913          	mv	s2,a7
    blt_wr(BLT_CMD_FIFO_DATA, op);
    245c:	00050593          	mv	a1,a0
    2460:	00800513          	li	a0,8
    2464:	f69ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, src);
    2468:	000b0593          	mv	a1,s6
    246c:	00800513          	li	a0,8
    2470:	f5dff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    2474:	000a8593          	mv	a1,s5
    2478:	00800513          	li	a0,8
    247c:	f51ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    2480:	000a0593          	mv	a1,s4
    2484:	00800513          	li	a0,8
    2488:	f45ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    248c:	00098593          	mv	a1,s3
    2490:	00800513          	li	a0,8
    2494:	f39ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    2498:	01049493          	slli	s1,s1,0x10
    249c:	01041413          	slli	s0,s0,0x10
    24a0:	01045413          	srli	s0,s0,0x10
    24a4:	0084e5b3          	or	a1,s1,s0
    24a8:	00800513          	li	a0,8
    24ac:	f21ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    24b0:	00090593          	mv	a1,s2
    24b4:	00800513          	li	a0,8
    24b8:	f15ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, color);
    24bc:	02012583          	lw	a1,32(sp)
    24c0:	00800513          	li	a0,8
    24c4:	f09ff0ef          	jal	23cc <blt_wr>
}
    24c8:	01c12083          	lw	ra,28(sp)
    24cc:	01812403          	lw	s0,24(sp)
    24d0:	01412483          	lw	s1,20(sp)
    24d4:	01012903          	lw	s2,16(sp)
    24d8:	00c12983          	lw	s3,12(sp)
    24dc:	00812a03          	lw	s4,8(sp)
    24e0:	00412a83          	lw	s5,4(sp)
    24e4:	00012b03          	lw	s6,0(sp)
    24e8:	02010113          	addi	sp,sp,32
    24ec:	00008067          	ret

000024f0 <blt_cnt>:
static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
    24f0:	ff010113          	addi	sp,sp,-16
    24f4:	00112623          	sw	ra,12(sp)
    24f8:	00c00513          	li	a0,12
    24fc:	ee1ff0ef          	jal	23dc <blt_rd>
    2500:	00c12083          	lw	ra,12(sp)
    2504:	01010113          	addi	sp,sp,16
    2508:	00008067          	ret

0000250c <blt_stat>:
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }
    250c:	ff010113          	addi	sp,sp,-16
    2510:	00112623          	sw	ra,12(sp)
    2514:	00400513          	li	a0,4
    2518:	ec5ff0ef          	jal	23dc <blt_rd>
    251c:	00c12083          	lw	ra,12(sp)
    2520:	01010113          	addi	sp,sp,16
    2524:	00008067          	ret

00002528 <blt_idle>:
{
    2528:	ff010113          	addi	sp,sp,-16
    252c:	00112623          	sw	ra,12(sp)
    uint32_t st = blt_stat();
    2530:	fddff0ef          	jal	250c <blt_stat>
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
    2534:	00e57513          	andi	a0,a0,14
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
    2538:	ff650513          	addi	a0,a0,-10
}
    253c:	00153513          	seqz	a0,a0
    2540:	00c12083          	lw	ra,12(sp)
    2544:	01010113          	addi	sp,sp,16
    2548:	00008067          	ret

0000254c <blt_can_push>:
{
    254c:	ff010113          	addi	sp,sp,-16
    2550:	00112623          	sw	ra,12(sp)
    return (blt_cnt() <= (uint32_t)(BLT_FIFO_DEPTH - HW_FIFO_MARGIN - 1)) ? 1 : 0;
    2554:	f9dff0ef          	jal	24f0 <blt_cnt>
}
    2558:	0c853513          	sltiu	a0,a0,200
    255c:	00c12083          	lw	ra,12(sp)
    2560:	01010113          	addi	sp,sp,16
    2564:	00008067          	ret

00002568 <blt_init>:
{
    2568:	ff010113          	addi	sp,sp,-16
    256c:	00112623          	sw	ra,12(sp)
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    2570:	00400593          	li	a1,4
    2574:	00000513          	li	a0,0
    2578:	e55ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_IRQ_STATUS, 1u);                        /* W1C */
    257c:	00100593          	li	a1,1
    2580:	01000513          	li	a0,16
    2584:	e49ff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_IRQ_EN, 0u);
    2588:	00000593          	li	a1,0
    258c:	01400513          	li	a0,20
    2590:	e3dff0ef          	jal	23cc <blt_wr>
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
    2594:	00100593          	li	a1,1
    2598:	00000513          	li	a0,0
    259c:	e31ff0ef          	jal	23cc <blt_wr>
}
    25a0:	00c12083          	lw	ra,12(sp)
    25a4:	01010113          	addi	sp,sp,16
    25a8:	00008067          	ret

000025ac <blt_copy_full>:
{
    25ac:	fe010113          	addi	sp,sp,-32
    25b0:	00112e23          	sw	ra,28(sp)
    25b4:	00058613          	mv	a2,a1
    blt_emit(0UL /*COPY*/, src, dst, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, 0xFFu, 0u);
    25b8:	00012023          	sw	zero,0(sp)
    25bc:	0ff00893          	li	a7,255
    25c0:	21c00813          	li	a6,540
    25c4:	3c000793          	li	a5,960
    25c8:	78000713          	li	a4,1920
    25cc:	78000693          	li	a3,1920
    25d0:	00050593          	mv	a1,a0
    25d4:	00000513          	li	a0,0
    25d8:	e45ff0ef          	jal	241c <blt_emit>
}
    25dc:	01c12083          	lw	ra,28(sp)
    25e0:	02010113          	addi	sp,sp,32
    25e4:	00008067          	ret

000025e8 <blt_fill>:
{
    25e8:	fe010113          	addi	sp,sp,-32
    25ec:	00112e23          	sw	ra,28(sp)
    25f0:	00060793          	mv	a5,a2
    blt_emit(BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color);
    25f4:	00e12023          	sw	a4,0(sp)
    25f8:	0ff00893          	li	a7,255
    25fc:	00068813          	mv	a6,a3
    2600:	00058713          	mv	a4,a1
    2604:	00000693          	li	a3,0
    2608:	00050613          	mv	a2,a0
    260c:	00000593          	li	a1,0
    2610:	00100513          	li	a0,1
    2614:	e09ff0ef          	jal	241c <blt_emit>
}
    2618:	01c12083          	lw	ra,28(sp)
    261c:	02010113          	addi	sp,sp,32
    2620:	00008067          	ret

00002624 <blt_alpha>:
{
    2624:	fe010113          	addi	sp,sp,-32
    2628:	00112e23          	sw	ra,28(sp)
    blt_emit(BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha, 0u);
    262c:	00012023          	sw	zero,0(sp)
    2630:	00080893          	mv	a7,a6
    2634:	00078813          	mv	a6,a5
    2638:	00070793          	mv	a5,a4
    263c:	00068713          	mv	a4,a3
    2640:	00060693          	mv	a3,a2
    2644:	00058613          	mv	a2,a1
    2648:	00050593          	mv	a1,a0
    264c:	00200513          	li	a0,2
    2650:	dcdff0ef          	jal	241c <blt_emit>
}
    2654:	01c12083          	lw	ra,28(sp)
    2658:	02010113          	addi	sp,sp,32
    265c:	00008067          	ret

00002660 <blt_key>:
{
    2660:	fe010113          	addi	sp,sp,-32
    2664:	00112e23          	sw	ra,28(sp)
    blt_emit(BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key);
    2668:	01012023          	sw	a6,0(sp)
    266c:	0ff00893          	li	a7,255
    2670:	00078813          	mv	a6,a5
    2674:	00070793          	mv	a5,a4
    2678:	00068713          	mv	a4,a3
    267c:	00060693          	mv	a3,a2
    2680:	00058613          	mv	a2,a1
    2684:	00050593          	mv	a1,a0
    2688:	00300513          	li	a0,3
    268c:	d91ff0ef          	jal	241c <blt_emit>
}
    2690:	01c12083          	lw	ra,28(sp)
    2694:	02010113          	addi	sp,sp,32
    2698:	00008067          	ret

0000269c <spr_color>:
    int dx = i - SPR_W / 2, dy = j - SPR_H / 2;
    269c:	ff050793          	addi	a5,a0,-16
    26a0:	ff058713          	addi	a4,a1,-16
    int d2 = dx * dx + dy * dy;
    26a4:	02f787b3          	mul	a5,a5,a5
    26a8:	02e70733          	mul	a4,a4,a4
    26ac:	00e787b3          	add	a5,a5,a4
    if (d2 > r2)                                   return KEY_COLOR;
    26b0:	10000713          	li	a4,256
    26b4:	06f74263          	blt	a4,a5,2718 <spr_color+0x7c>
    if (d2 > (SPR_W / 2 - 4) * (SPR_W / 2 - 4))    return COL_WHITE;
    26b8:	09000713          	li	a4,144
    26bc:	06f74463          	blt	a4,a5,2724 <spr_color+0x88>
    gg = (unsigned)((j * 63) / (SPR_H - 1));
    26c0:	00659713          	slli	a4,a1,0x6
    26c4:	40b70733          	sub	a4,a4,a1
    26c8:	01f00693          	li	a3,31
    26cc:	02d74733          	div	a4,a4,a3
    bb = (unsigned)(31 - ((d2 * 31) / (r2 ? r2 : 1)));
    26d0:	00579613          	slli	a2,a5,0x5
    26d4:	40f60633          	sub	a2,a2,a5
    26d8:	41f65793          	srai	a5,a2,0x1f
    26dc:	0ff7f793          	zext.b	a5,a5
    26e0:	00c787b3          	add	a5,a5,a2
    26e4:	4087d793          	srai	a5,a5,0x8
    26e8:	40f686b3          	sub	a3,a3,a5
    return (uint16_t)((rr << 11) | (gg << 5) | bb);
    26ec:	00b51513          	slli	a0,a0,0xb
    26f0:	01051513          	slli	a0,a0,0x10
    26f4:	01055513          	srli	a0,a0,0x10
    26f8:	00571793          	slli	a5,a4,0x5
    26fc:	01079793          	slli	a5,a5,0x10
    2700:	0107d793          	srli	a5,a5,0x10
    2704:	00f56533          	or	a0,a0,a5
    2708:	00d56533          	or	a0,a0,a3
    270c:	01051513          	slli	a0,a0,0x10
    2710:	01055513          	srli	a0,a0,0x10
    2714:	00008067          	ret
    if (d2 > r2)                                   return KEY_COLOR;
    2718:	00010537          	lui	a0,0x10
    271c:	81f50513          	addi	a0,a0,-2017 # f81f <__freertos_irq_stack_top+0x39cf>
    2720:	00008067          	ret
    if (d2 > (SPR_W / 2 - 4) * (SPR_W / 2 - 4))    return COL_WHITE;
    2724:	00010537          	lui	a0,0x10
    2728:	fff50513          	addi	a0,a0,-1 # ffff <__freertos_irq_stack_top+0x41af>
}
    272c:	00008067          	ret

00002730 <build_atlas>:
{
    2730:	ff010113          	addi	sp,sp,-16
    2734:	00112623          	sw	ra,12(sp)
    2738:	00812423          	sw	s0,8(sp)
    273c:	00912223          	sw	s1,4(sp)
    2740:	01212023          	sw	s2,0(sp)
    for (j = 0; j < SPR_H; j++)
    2744:	00000913          	li	s2,0
    2748:	0380006f          	j	2780 <build_atlas+0x50>
            p[j * SPR_W + i] = spr_color(i, j);
    274c:	00591793          	slli	a5,s2,0x5
    2750:	008787b3          	add	a5,a5,s0
    2754:	00179793          	slli	a5,a5,0x1
    2758:	002014b7          	lui	s1,0x201
    275c:	00f484b3          	add	s1,s1,a5
    2760:	00090593          	mv	a1,s2
    2764:	00040513          	mv	a0,s0
    2768:	f35ff0ef          	jal	269c <spr_color>
    276c:	00a49023          	sh	a0,0(s1) # 201000 <__freertos_irq_stack_top+0x1f51b0>
        for (i = 0; i < SPR_W; i++)
    2770:	00140413          	addi	s0,s0,1
    2774:	01f00793          	li	a5,31
    2778:	fc87dae3          	bge	a5,s0,274c <build_atlas+0x1c>
    for (j = 0; j < SPR_H; j++)
    277c:	00190913          	addi	s2,s2,1
    2780:	01f00793          	li	a5,31
    2784:	0127c663          	blt	a5,s2,2790 <build_atlas+0x60>
        for (i = 0; i < SPR_W; i++)
    2788:	00000413          	li	s0,0
    278c:	fe9ff06f          	j	2774 <build_atlas+0x44>
}
    2790:	00c12083          	lw	ra,12(sp)
    2794:	00812403          	lw	s0,8(sp)
    2798:	00412483          	lw	s1,4(sp)
    279c:	00012903          	lw	s2,0(sp)
    27a0:	01010113          	addi	sp,sp,16
    27a4:	00008067          	ret

000027a8 <cpu_fill32>:
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    27a8:	01079e93          	slli	t4,a5,0x10
    27ac:	00fe8eb3          	add	t4,t4,a5
    int odd = (x & 1);
    27b0:	0015ff93          	andi	t6,a1,1
    for (j = 0; j < h; j++) {
    27b4:	00000f13          	li	t5,0
    27b8:	0480006f          	j	2800 <cpu_fill32+0x58>
        int rem = w;
    27bc:	00068e13          	mv	t3,a3
    27c0:	0700006f          	j	2830 <cpu_fill32+0x88>
            for (i = 0; i < (rem >> 1); i++) q[i] = two;
    27c4:	00281893          	slli	a7,a6,0x2
    27c8:	011308b3          	add	a7,t1,a7
    27cc:	01d8a023          	sw	t4,0(a7)
    27d0:	00180813          	addi	a6,a6,1
    27d4:	401e5893          	srai	a7,t3,0x1
    27d8:	ff1846e3          	blt	a6,a7,27c4 <cpu_fill32+0x1c>
        if (rem & 1) p[rem - 1] = color;
    27dc:	001e7813          	andi	a6,t3,1
    27e0:	00080e63          	beqz	a6,27fc <cpu_fill32+0x54>
    27e4:	80000837          	lui	a6,0x80000
    27e8:	fff80813          	addi	a6,a6,-1 # 7fffffff <__freertos_irq_stack_top+0x7fff41af>
    27ec:	010e0e33          	add	t3,t3,a6
    27f0:	001e1e13          	slli	t3,t3,0x1
    27f4:	01c30333          	add	t1,t1,t3
    27f8:	00f31023          	sh	a5,0(t1)
    for (j = 0; j < h; j++) {
    27fc:	001f0f13          	addi	t5,t5,1
    2800:	02ef5c63          	bge	t5,a4,2838 <cpu_fill32+0x90>
        volatile uint16_t *p = (volatile uint16_t *)(base + (uint32_t)(y + j) * FB_STRIDE
    2804:	00cf0833          	add	a6,t5,a2
                                                          + (uint32_t)x * 2u);
    2808:	00481313          	slli	t1,a6,0x4
    280c:	41030333          	sub	t1,t1,a6
    2810:	00631313          	slli	t1,t1,0x6
    2814:	00b30333          	add	t1,t1,a1
    2818:	00131313          	slli	t1,t1,0x1
    281c:	00a30333          	add	t1,t1,a0
        if (odd) { *p++ = color; rem--; }
    2820:	f80f8ee3          	beqz	t6,27bc <cpu_fill32+0x14>
    2824:	00f31023          	sh	a5,0(t1)
    2828:	fff68e13          	addi	t3,a3,-1 # a5a4ffff <__freertos_irq_stack_top+0xa5a441af>
    282c:	00230313          	addi	t1,t1,2
            for (i = 0; i < (rem >> 1); i++) q[i] = two;
    2830:	00000813          	li	a6,0
    2834:	fa1ff06f          	j	27d4 <cpu_fill32+0x2c>
}
    2838:	00008067          	ret

0000283c <blend565>:
{
    283c:	00060693          	mv	a3,a2
    unsigned fr = (fg >> 11) & 0x1Fu, fgc = (fg >> 5) & 0x3Fu, fb = fg & 0x1Fu;
    2840:	00b55713          	srli	a4,a0,0xb
    2844:	00555613          	srli	a2,a0,0x5
    2848:	03f67613          	andi	a2,a2,63
    284c:	01f57513          	andi	a0,a0,31
    unsigned br = (bg >> 11) & 0x1Fu, bgc = (bg >> 5) & 0x3Fu, bb = bg & 0x1Fu;
    2850:	00b5d893          	srli	a7,a1,0xb
    2854:	0055d813          	srli	a6,a1,0x5
    2858:	03f87813          	andi	a6,a6,63
    285c:	01f5f593          	andi	a1,a1,31
    unsigned f8r = (fr << 3) | (fr >> 2), f8g = (fgc << 2) | (fgc >> 4), f8b = (fb << 3) | (fb >> 2);
    2860:	00371793          	slli	a5,a4,0x3
    2864:	00275713          	srli	a4,a4,0x2
    2868:	00e7e7b3          	or	a5,a5,a4
    286c:	00261713          	slli	a4,a2,0x2
    2870:	00465613          	srli	a2,a2,0x4
    2874:	00c76733          	or	a4,a4,a2
    2878:	00351613          	slli	a2,a0,0x3
    287c:	00255513          	srli	a0,a0,0x2
    2880:	00a66633          	or	a2,a2,a0
    unsigned b8r = (br << 3) | (br >> 2), b8g = (bgc << 2) | (bgc >> 4), b8b = (bb << 3) | (bb >> 2);
    2884:	00389513          	slli	a0,a7,0x3
    2888:	0028d893          	srli	a7,a7,0x2
    288c:	011568b3          	or	a7,a0,a7
    2890:	00281513          	slli	a0,a6,0x2
    2894:	00485813          	srli	a6,a6,0x4
    2898:	01056833          	or	a6,a0,a6
    289c:	00359513          	slli	a0,a1,0x3
    28a0:	0025d593          	srli	a1,a1,0x2
    28a4:	00b565b3          	or	a1,a0,a1
    unsigned ai  = 255u - a;
    28a8:	0ff00e13          	li	t3,255
    28ac:	40de0333          	sub	t1,t3,a3
    unsigned r = (f8r * a + b8r * ai + 127u) >> 8;
    28b0:	02d787b3          	mul	a5,a5,a3
    28b4:	02688533          	mul	a0,a7,t1
    28b8:	00a787b3          	add	a5,a5,a0
    28bc:	07f78793          	addi	a5,a5,127
    28c0:	0087d793          	srli	a5,a5,0x8
    unsigned g = (f8g * a + b8g * ai + 127u) >> 8;
    28c4:	02d70733          	mul	a4,a4,a3
    28c8:	02680533          	mul	a0,a6,t1
    28cc:	00a70733          	add	a4,a4,a0
    28d0:	07f70713          	addi	a4,a4,127
    28d4:	00875713          	srli	a4,a4,0x8
    unsigned b = (f8b * a + b8b * ai + 127u) >> 8;
    28d8:	02d60633          	mul	a2,a2,a3
    28dc:	026586b3          	mul	a3,a1,t1
    28e0:	00d60633          	add	a2,a2,a3
    28e4:	07f60613          	addi	a2,a2,127
    28e8:	00865613          	srli	a2,a2,0x8
    if (r > 255u) r = 255u;
    28ec:	00fe7463          	bgeu	t3,a5,28f4 <blend565+0xb8>
    28f0:	0ff00793          	li	a5,255
    if (g > 255u) g = 255u;
    28f4:	0ff00693          	li	a3,255
    28f8:	00e6f463          	bgeu	a3,a4,2900 <blend565+0xc4>
    28fc:	0ff00713          	li	a4,255
    if (b > 255u) b = 255u;
    2900:	0ff00693          	li	a3,255
    2904:	00c6f463          	bgeu	a3,a2,290c <blend565+0xd0>
    2908:	0ff00613          	li	a2,255
    return (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
    290c:	0037d513          	srli	a0,a5,0x3
    2910:	00b51513          	slli	a0,a0,0xb
    2914:	01051513          	slli	a0,a0,0x10
    2918:	01055513          	srli	a0,a0,0x10
    291c:	00275713          	srli	a4,a4,0x2
    2920:	00571713          	slli	a4,a4,0x5
    2924:	01071713          	slli	a4,a4,0x10
    2928:	01075713          	srli	a4,a4,0x10
    292c:	00e56533          	or	a0,a0,a4
    2930:	00365613          	srli	a2,a2,0x3
    2934:	00c56533          	or	a0,a0,a2
}
    2938:	01051513          	slli	a0,a0,0x10
    293c:	01055513          	srli	a0,a0,0x10
    2940:	00008067          	ret

00002944 <cpu_alpha_sprite>:
{
    2944:	fe010113          	addi	sp,sp,-32
    2948:	00112e23          	sw	ra,28(sp)
    294c:	00812c23          	sw	s0,24(sp)
    2950:	00912a23          	sw	s1,20(sp)
    2954:	01212823          	sw	s2,16(sp)
    2958:	01312623          	sw	s3,12(sp)
    295c:	01412423          	sw	s4,8(sp)
    2960:	01512223          	sw	s5,4(sp)
    2964:	01612023          	sw	s6,0(sp)
    2968:	00050b13          	mv	s6,a0
    296c:	00058a93          	mv	s5,a1
    2970:	00060a13          	mv	s4,a2
    for (j = 0; j < SPR_H; j++) {
    2974:	00000993          	li	s3,0
    2978:	0440006f          	j	29bc <cpu_alpha_sprite+0x78>
            d[i] = blend565(s[j * SPR_W + i], d[i], alpha);
    297c:	00599793          	slli	a5,s3,0x5
    2980:	008787b3          	add	a5,a5,s0
    2984:	00179793          	slli	a5,a5,0x1
    2988:	00201737          	lui	a4,0x201
    298c:	00f707b3          	add	a5,a4,a5
    2990:	0007d503          	lhu	a0,0(a5)
    2994:	00141493          	slli	s1,s0,0x1
    2998:	009904b3          	add	s1,s2,s1
    299c:	0004d583          	lhu	a1,0(s1)
    29a0:	000a0613          	mv	a2,s4
    29a4:	e99ff0ef          	jal	283c <blend565>
    29a8:	00a49023          	sh	a0,0(s1)
        for (i = 0; i < SPR_W; i++)
    29ac:	00140413          	addi	s0,s0,1
    29b0:	01f00793          	li	a5,31
    29b4:	fc87d4e3          	bge	a5,s0,297c <cpu_alpha_sprite+0x38>
    for (j = 0; j < SPR_H; j++) {
    29b8:	00198993          	addi	s3,s3,1
    29bc:	01f00793          	li	a5,31
    29c0:	0337c863          	blt	a5,s3,29f0 <cpu_alpha_sprite+0xac>
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
    29c4:	015987b3          	add	a5,s3,s5
    29c8:	00479913          	slli	s2,a5,0x4
    29cc:	40f90933          	sub	s2,s2,a5
    29d0:	00691913          	slli	s2,s2,0x6
    29d4:	01690933          	add	s2,s2,s6
    29d8:	002817b7          	lui	a5,0x281
    29dc:	80078793          	addi	a5,a5,-2048 # 280800 <__freertos_irq_stack_top+0x2749b0>
    29e0:	00f90933          	add	s2,s2,a5
    29e4:	00191913          	slli	s2,s2,0x1
        for (i = 0; i < SPR_W; i++)
    29e8:	00000413          	li	s0,0
    29ec:	fc5ff06f          	j	29b0 <cpu_alpha_sprite+0x6c>
}
    29f0:	01c12083          	lw	ra,28(sp)
    29f4:	01812403          	lw	s0,24(sp)
    29f8:	01412483          	lw	s1,20(sp)
    29fc:	01012903          	lw	s2,16(sp)
    2a00:	00c12983          	lw	s3,12(sp)
    2a04:	00812a03          	lw	s4,8(sp)
    2a08:	00412a83          	lw	s5,4(sp)
    2a0c:	00012b03          	lw	s6,0(sp)
    2a10:	02010113          	addi	sp,sp,32
    2a14:	00008067          	ret

00002a18 <cpu_key_sprite>:
{
    2a18:	00050813          	mv	a6,a0
    2a1c:	00058513          	mv	a0,a1
    for (j = 0; j < SPR_H; j++) {
    2a20:	00000613          	li	a2,0
    2a24:	0500006f          	j	2a74 <cpu_key_sprite+0x5c>
        for (i = 0; i < SPR_W; i++) {
    2a28:	00170713          	addi	a4,a4,1 # 201001 <__freertos_irq_stack_top+0x1f51b1>
    2a2c:	01f00793          	li	a5,31
    2a30:	04e7c063          	blt	a5,a4,2a70 <cpu_key_sprite+0x58>
            uint16_t c = s[j * SPR_W + i];
    2a34:	00561793          	slli	a5,a2,0x5
    2a38:	00e787b3          	add	a5,a5,a4
    2a3c:	00179793          	slli	a5,a5,0x1
    2a40:	002016b7          	lui	a3,0x201
    2a44:	00f687b3          	add	a5,a3,a5
    2a48:	0007d783          	lhu	a5,0(a5)
    2a4c:	01079793          	slli	a5,a5,0x10
    2a50:	0107d793          	srli	a5,a5,0x10
            if (c != (uint16_t)KEY_COLOR) d[i] = c;
    2a54:	000106b7          	lui	a3,0x10
    2a58:	81f68693          	addi	a3,a3,-2017 # f81f <__freertos_irq_stack_top+0x39cf>
    2a5c:	fcd786e3          	beq	a5,a3,2a28 <cpu_key_sprite+0x10>
    2a60:	00171693          	slli	a3,a4,0x1
    2a64:	00d586b3          	add	a3,a1,a3
    2a68:	00f69023          	sh	a5,0(a3)
    2a6c:	fbdff06f          	j	2a28 <cpu_key_sprite+0x10>
    for (j = 0; j < SPR_H; j++) {
    2a70:	00160613          	addi	a2,a2,1
    2a74:	01f00793          	li	a5,31
    2a78:	02c7c863          	blt	a5,a2,2aa8 <cpu_key_sprite+0x90>
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
    2a7c:	00a607b3          	add	a5,a2,a0
    2a80:	00479593          	slli	a1,a5,0x4
    2a84:	40f585b3          	sub	a1,a1,a5
    2a88:	00659593          	slli	a1,a1,0x6
    2a8c:	010585b3          	add	a1,a1,a6
    2a90:	002817b7          	lui	a5,0x281
    2a94:	80078793          	addi	a5,a5,-2048 # 280800 <__freertos_irq_stack_top+0x2749b0>
    2a98:	00f585b3          	add	a1,a1,a5
    2a9c:	00159593          	slli	a1,a1,0x1
        for (i = 0; i < SPR_W; i++) {
    2aa0:	00000713          	li	a4,0
    2aa4:	f89ff06f          	j	2a2c <cpu_key_sprite+0x14>
}
    2aa8:	00008067          	ret

00002aac <glyph_of>:
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    2aac:	f9f50793          	addi	a5,a0,-97
    2ab0:	0ff7f793          	zext.b	a5,a5
    2ab4:	01900713          	li	a4,25
    2ab8:	00f76663          	bltu	a4,a5,2ac4 <glyph_of+0x18>
    2abc:	fe050513          	addi	a0,a0,-32
    2ac0:	0ff57513          	zext.b	a0,a0
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return g_font[i].r;
    2ac4:	00000713          	li	a4,0
    2ac8:	02100793          	li	a5,33
    2acc:	02e7ce63          	blt	a5,a4,2b08 <glyph_of+0x5c>
    2ad0:	000047b7          	lui	a5,0x4
    2ad4:	00371693          	slli	a3,a4,0x3
    2ad8:	00e686b3          	add	a3,a3,a4
    2adc:	ea078793          	addi	a5,a5,-352 # 3ea0 <g_font>
    2ae0:	00d787b3          	add	a5,a5,a3
    2ae4:	0007c783          	lbu	a5,0(a5)
    2ae8:	00a78663          	beq	a5,a0,2af4 <glyph_of+0x48>
    2aec:	00170713          	addi	a4,a4,1
    2af0:	fd9ff06f          	j	2ac8 <glyph_of+0x1c>
    2af4:	000047b7          	lui	a5,0x4
    2af8:	ea078793          	addi	a5,a5,-352 # 3ea0 <g_font>
    2afc:	00f68533          	add	a0,a3,a5
    2b00:	00150513          	addi	a0,a0,1
    2b04:	00008067          	ret
    return g_font[0].r;
    2b08:	00004537          	lui	a0,0x4
    2b0c:	ea150513          	addi	a0,a0,-351 # 3ea1 <g_font+0x1>
}
    2b10:	00008067          	ret

00002b14 <osd_text>:
{
    2b14:	fe010113          	addi	sp,sp,-32
    2b18:	00112e23          	sw	ra,28(sp)
    2b1c:	00812c23          	sw	s0,24(sp)
    2b20:	00912a23          	sw	s1,20(sp)
    2b24:	01212823          	sw	s2,16(sp)
    2b28:	01312623          	sw	s3,12(sp)
    2b2c:	00050493          	mv	s1,a0
    2b30:	00058913          	mv	s2,a1
    2b34:	00060993          	mv	s3,a2
    2b38:	00068413          	mv	s0,a3
    while (*s) {
    2b3c:	1040006f          	j	2c40 <osd_text+0x12c>
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2b40:	00000613          	li	a2,0
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2b44:	01871593          	slli	a1,a4,0x18
    2b48:	4185d593          	srai	a1,a1,0x18
    2b4c:	0205c063          	bltz	a1,2b6c <osd_text+0x58>
    2b50:	00000593          	li	a1,0
    2b54:	00b66633          	or	a2,a2,a1
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2b58:	00c7a023          	sw	a2,0(a5)
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2b5c:	01077613          	andi	a2,a4,16
    2b60:	00060a63          	beqz	a2,2b74 <osd_text+0x60>
    2b64:	01041613          	slli	a2,s0,0x10
    2b68:	0100006f          	j	2b78 <osd_text+0x64>
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2b6c:	00040593          	mv	a1,s0
    2b70:	fe5ff06f          	j	2b54 <osd_text+0x40>
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2b74:	00000613          	li	a2,0
                 | ((bits & 0x20u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2b78:	02077593          	andi	a1,a4,32
    2b7c:	00058663          	beqz	a1,2b88 <osd_text+0x74>
    2b80:	00040593          	mv	a1,s0
    2b84:	0080006f          	j	2b8c <osd_text+0x78>
    2b88:	00000593          	li	a1,0
    2b8c:	00b66633          	or	a2,a2,a1
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2b90:	00c7a223          	sw	a2,4(a5)
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2b94:	00477613          	andi	a2,a4,4
    2b98:	00060663          	beqz	a2,2ba4 <osd_text+0x90>
    2b9c:	01041613          	slli	a2,s0,0x10
    2ba0:	0080006f          	j	2ba8 <osd_text+0x94>
    2ba4:	00000613          	li	a2,0
                 | ((bits & 0x08u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2ba8:	00877593          	andi	a1,a4,8
    2bac:	00058663          	beqz	a1,2bb8 <osd_text+0xa4>
    2bb0:	00040593          	mv	a1,s0
    2bb4:	0080006f          	j	2bbc <osd_text+0xa8>
    2bb8:	00000593          	li	a1,0
    2bbc:	00b66633          	or	a2,a2,a1
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2bc0:	00c7a423          	sw	a2,8(a5)
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2bc4:	00177613          	andi	a2,a4,1
    2bc8:	00060663          	beqz	a2,2bd4 <osd_text+0xc0>
    2bcc:	01041613          	slli	a2,s0,0x10
    2bd0:	0080006f          	j	2bd8 <osd_text+0xc4>
    2bd4:	00000613          	li	a2,0
                 | ((bits & 0x02u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    2bd8:	00277713          	andi	a4,a4,2
    2bdc:	00070663          	beqz	a4,2be8 <osd_text+0xd4>
    2be0:	00040713          	mv	a4,s0
    2be4:	0080006f          	j	2bec <osd_text+0xd8>
    2be8:	00000713          	li	a4,0
    2bec:	00e66733          	or	a4,a2,a4
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2bf0:	00e7a623          	sw	a4,12(a5)
        for (row = 0; row < 8; row++) {
    2bf4:	00168693          	addi	a3,a3,1
    2bf8:	00700793          	li	a5,7
    2bfc:	04d7c063          	blt	a5,a3,2c3c <osd_text+0x128>
            uint8_t bits = rp[row];
    2c00:	00d507b3          	add	a5,a0,a3
    2c04:	0007c703          	lbu	a4,0(a5)
                                    + (uint32_t)(y + row) * FB_STRIDE + (uint32_t)x * 2u);
    2c08:	01268633          	add	a2,a3,s2
    2c0c:	00461793          	slli	a5,a2,0x4
    2c10:	40c787b3          	sub	a5,a5,a2
    2c14:	00679793          	slli	a5,a5,0x6
    2c18:	009787b3          	add	a5,a5,s1
    2c1c:	00281637          	lui	a2,0x281
    2c20:	80060613          	addi	a2,a2,-2048 # 280800 <__freertos_irq_stack_top+0x2749b0>
    2c24:	00c787b3          	add	a5,a5,a2
    2c28:	00179793          	slli	a5,a5,0x1
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    2c2c:	04077613          	andi	a2,a4,64
    2c30:	f00608e3          	beqz	a2,2b40 <osd_text+0x2c>
    2c34:	01041613          	slli	a2,s0,0x10
    2c38:	f0dff06f          	j	2b44 <osd_text+0x30>
        x += 8;
    2c3c:	00848493          	addi	s1,s1,8
    while (*s) {
    2c40:	0009c503          	lbu	a0,0(s3)
    2c44:	00050a63          	beqz	a0,2c58 <osd_text+0x144>
        const uint8_t *rp = glyph_of(*s++);
    2c48:	00198993          	addi	s3,s3,1
    2c4c:	e61ff0ef          	jal	2aac <glyph_of>
        for (row = 0; row < 8; row++) {
    2c50:	00000693          	li	a3,0
    2c54:	fa5ff06f          	j	2bf8 <osd_text+0xe4>
}
    2c58:	01c12083          	lw	ra,28(sp)
    2c5c:	01812403          	lw	s0,24(sp)
    2c60:	01412483          	lw	s1,20(sp)
    2c64:	01012903          	lw	s2,16(sp)
    2c68:	00c12983          	lw	s3,12(sp)
    2c6c:	02010113          	addi	sp,sp,32
    2c70:	00008067          	ret

00002c74 <app>:
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
    2c74:	0100006f          	j	2c84 <app+0x10>
    2c78:	00158593          	addi	a1,a1,1
    2c7c:	00f50023          	sb	a5,0(a0)
    2c80:	00150513          	addi	a0,a0,1
    2c84:	0005c783          	lbu	a5,0(a1)
    2c88:	fe0798e3          	bnez	a5,2c78 <app+0x4>
    2c8c:	00008067          	ret

00002c90 <appn>:
{
    2c90:	ff010113          	addi	sp,sp,-16
    char d[12]; int n = 0, i;
    2c94:	00000793          	li	a5,0
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    2c98:	00a00813          	li	a6,10
    2c9c:	0305f6b3          	remu	a3,a1,a6
    2ca0:	03068693          	addi	a3,a3,48
    2ca4:	01078713          	addi	a4,a5,16
    2ca8:	00270733          	add	a4,a4,sp
    2cac:	00178793          	addi	a5,a5,1
    2cb0:	fed70a23          	sb	a3,-12(a4)
    2cb4:	00058693          	mv	a3,a1
    2cb8:	0305d5b3          	divu	a1,a1,a6
    2cbc:	00900713          	li	a4,9
    2cc0:	02d77863          	bgeu	a4,a3,2cf0 <appn+0x60>
    2cc4:	00a00713          	li	a4,10
    2cc8:	fcf758e3          	bge	a4,a5,2c98 <appn+0x8>
    2ccc:	00000713          	li	a4,0
    2cd0:	0140006f          	j	2ce4 <appn+0x54>
    for (i = 0; i < w - n; i++) *p++ = ' ';
    2cd4:	02000693          	li	a3,32
    2cd8:	00d50023          	sb	a3,0(a0)
    2cdc:	00170713          	addi	a4,a4,1
    2ce0:	00150513          	addi	a0,a0,1
    2ce4:	40f606b3          	sub	a3,a2,a5
    2ce8:	fed746e3          	blt	a4,a3,2cd4 <appn+0x44>
    2cec:	0240006f          	j	2d10 <appn+0x80>
    2cf0:	00000713          	li	a4,0
    2cf4:	ff1ff06f          	j	2ce4 <appn+0x54>
    while (n) *p++ = d[--n];
    2cf8:	fff78793          	addi	a5,a5,-1
    2cfc:	01078713          	addi	a4,a5,16
    2d00:	00270733          	add	a4,a4,sp
    2d04:	ff474703          	lbu	a4,-12(a4)
    2d08:	00e50023          	sb	a4,0(a0)
    2d0c:	00150513          	addi	a0,a0,1
    2d10:	fe0794e3          	bnez	a5,2cf8 <appn+0x68>
}
    2d14:	01010113          	addi	sp,sp,16
    2d18:	00008067          	ret

00002d1c <uart_status_raw>:
    return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS);
    2d1c:	f80107b7          	lui	a5,0xf8010
    2d20:	0047a503          	lw	a0,4(a5) # f8010004 <__freertos_irq_stack_top+0xf80041b4>
}
    2d24:	00008067          	ret

00002d28 <uart_poll_char>:
{
    2d28:	ff010113          	addi	sp,sp,-16
    2d2c:	00112623          	sw	ra,12(sp)
    if ((uart_status_raw() >> 24) == 0u) return 0;
    2d30:	fedff0ef          	jal	2d1c <uart_status_raw>
    2d34:	01855513          	srli	a0,a0,0x18
    2d38:	00050e63          	beqz	a0,2d54 <uart_poll_char+0x2c>
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
    2d3c:	f80107b7          	lui	a5,0xf8010
    2d40:	0007a503          	lw	a0,0(a5) # f8010000 <__freertos_irq_stack_top+0xf80041b0>
    2d44:	0ff57513          	zext.b	a0,a0
}
    2d48:	00c12083          	lw	ra,12(sp)
    2d4c:	01010113          	addi	sp,sp,16
    2d50:	00008067          	ret
    if ((uart_status_raw() >> 24) == 0u) return 0;
    2d54:	00000513          	li	a0,0
    2d58:	ff1ff06f          	j	2d48 <uart_poll_char+0x20>

00002d5c <lcg>:
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }
    2d5c:	00052783          	lw	a5,0(a0)
    2d60:	00196737          	lui	a4,0x196
    2d64:	60d70713          	addi	a4,a4,1549 # 19660d <__freertos_irq_stack_top+0x18a7bd>
    2d68:	02e787b3          	mul	a5,a5,a4
    2d6c:	3c6ef737          	lui	a4,0x3c6ef
    2d70:	35f70713          	addi	a4,a4,863 # 3c6ef35f <__freertos_irq_stack_top+0x3c6e350f>
    2d74:	00e787b3          	add	a5,a5,a4
    2d78:	00f52023          	sw	a5,0(a0)
    2d7c:	0107d513          	srli	a0,a5,0x10
    2d80:	00008067          	ret

00002d84 <scene_init>:
{
    2d84:	fd010113          	addi	sp,sp,-48
    2d88:	02112623          	sw	ra,44(sp)
    2d8c:	02812423          	sw	s0,40(sp)
    2d90:	02912223          	sw	s1,36(sp)
    2d94:	03212023          	sw	s2,32(sp)
    2d98:	01312e23          	sw	s3,28(sp)
    2d9c:	01412c23          	sw	s4,24(sp)
    2da0:	01512a23          	sw	s5,20(sp)
    2da4:	00050993          	mv	s3,a0
    2da8:	00058a93          	mv	s5,a1
    2dac:	00060a13          	mv	s4,a2
    for (side = 0; side < NSIDE; side++) {
    2db0:	00000913          	li	s2,0
    2db4:	1e40006f          	j	2f98 <scene_init+0x214>
            else b->sz = (uint8_t)(((i % 3) == 0) ? 16 : (((i % 3) == 1) ? 24 : 32));
    2db8:	00300793          	li	a5,3
    2dbc:	02f467b3          	rem	a5,s0,a5
    2dc0:	00078e63          	beqz	a5,2ddc <scene_init+0x58>
    2dc4:	00100713          	li	a4,1
    2dc8:	00e78663          	beq	a5,a4,2dd4 <scene_init+0x50>
    2dcc:	02000613          	li	a2,32
    2dd0:	0100006f          	j	2de0 <scene_init+0x5c>
    2dd4:	01800613          	li	a2,24
    2dd8:	0080006f          	j	2de0 <scene_init+0x5c>
    2ddc:	01000613          	li	a2,16
    2de0:	00004737          	lui	a4,0x4
    2de4:	00241793          	slli	a5,s0,0x2
    2de8:	008787b3          	add	a5,a5,s0
    2dec:	00279793          	slli	a5,a5,0x2
    2df0:	000036b7          	lui	a3,0x3
    2df4:	6b068693          	addi	a3,a3,1712 # 36b0 <__udivdi3+0x454>
    2df8:	02d906b3          	mul	a3,s2,a3
    2dfc:	00d787b3          	add	a5,a5,a3
    2e00:	0e470713          	addi	a4,a4,228 # 40e4 <g_sc>
    2e04:	00f707b3          	add	a5,a4,a5
    2e08:	00c78923          	sb	a2,18(a5)
            b->vx = (int16_t)((int)(r1 % 7u) - 3);
    2e0c:	00700713          	li	a4,7
    2e10:	02e4f733          	remu	a4,s1,a4
    2e14:	ffd70713          	addi	a4,a4,-3
    2e18:	000046b7          	lui	a3,0x4
    2e1c:	00241793          	slli	a5,s0,0x2
    2e20:	008787b3          	add	a5,a5,s0
    2e24:	00279793          	slli	a5,a5,0x2
    2e28:	00003637          	lui	a2,0x3
    2e2c:	6b060613          	addi	a2,a2,1712 # 36b0 <__udivdi3+0x454>
    2e30:	02c90633          	mul	a2,s2,a2
    2e34:	00c787b3          	add	a5,a5,a2
    2e38:	0e468693          	addi	a3,a3,228 # 40e4 <g_sc>
    2e3c:	00f686b3          	add	a3,a3,a5
    2e40:	00e69223          	sh	a4,4(a3)
            b->vy = (int16_t)((int)(r2 % 5u) - 2);
    2e44:	00500793          	li	a5,5
    2e48:	02f577b3          	remu	a5,a0,a5
    2e4c:	ffe78793          	addi	a5,a5,-2
    2e50:	00f69323          	sh	a5,6(a3)
            if (!b->vx) b->vx = 1;
    2e54:	02071a63          	bnez	a4,2e88 <scene_init+0x104>
    2e58:	000046b7          	lui	a3,0x4
    2e5c:	00241713          	slli	a4,s0,0x2
    2e60:	00870733          	add	a4,a4,s0
    2e64:	00271713          	slli	a4,a4,0x2
    2e68:	00003637          	lui	a2,0x3
    2e6c:	6b060613          	addi	a2,a2,1712 # 36b0 <__udivdi3+0x454>
    2e70:	02c90633          	mul	a2,s2,a2
    2e74:	00c70733          	add	a4,a4,a2
    2e78:	0e468693          	addi	a3,a3,228 # 40e4 <g_sc>
    2e7c:	00e68733          	add	a4,a3,a4
    2e80:	00100693          	li	a3,1
    2e84:	00d71223          	sh	a3,4(a4)
            if (!b->vy) b->vy = 1;
    2e88:	02079a63          	bnez	a5,2ebc <scene_init+0x138>
    2e8c:	00004737          	lui	a4,0x4
    2e90:	00241793          	slli	a5,s0,0x2
    2e94:	008787b3          	add	a5,a5,s0
    2e98:	00279793          	slli	a5,a5,0x2
    2e9c:	000036b7          	lui	a3,0x3
    2ea0:	6b068693          	addi	a3,a3,1712 # 36b0 <__udivdi3+0x454>
    2ea4:	02d906b3          	mul	a3,s2,a3
    2ea8:	00d787b3          	add	a5,a5,a3
    2eac:	0e470713          	addi	a4,a4,228 # 40e4 <g_sc>
    2eb0:	00f707b3          	add	a5,a4,a5
    2eb4:	00100713          	li	a4,1
    2eb8:	00e79323          	sh	a4,6(a5)
            b->x  = (int16_t)((int)(r1 % (uint32_t)(FB_WIDTH - 64)) & ~1);
    2ebc:	38000713          	li	a4,896
    2ec0:	02e4f733          	remu	a4,s1,a4
    2ec4:	3fe77713          	andi	a4,a4,1022
    2ec8:	000047b7          	lui	a5,0x4
    2ecc:	00241693          	slli	a3,s0,0x2
    2ed0:	008686b3          	add	a3,a3,s0
    2ed4:	00269693          	slli	a3,a3,0x2
    2ed8:	00003637          	lui	a2,0x3
    2edc:	6b060613          	addi	a2,a2,1712 # 36b0 <__udivdi3+0x454>
    2ee0:	02c90633          	mul	a2,s2,a2
    2ee4:	00c686b3          	add	a3,a3,a2
    2ee8:	0e478793          	addi	a5,a5,228 # 40e4 <g_sc>
    2eec:	00d787b3          	add	a5,a5,a3
    2ef0:	00e79023          	sh	a4,0(a5)
            b->y  = (int16_t)(int)(r2 % (uint32_t)(HALF_H - 40));
    2ef4:	0dc00693          	li	a3,220
    2ef8:	02d576b3          	remu	a3,a0,a3
    2efc:	00d79123          	sh	a3,2(a5)
            b->dx = b->x; b->dy = b->y;                      /* 本侧"已画位置"初始对齐 */
    2f00:	00e79423          	sh	a4,8(a5)
    2f04:	00d79523          	sh	a3,10(a5)
            b->tx = b->x; b->ty = b->y;                      /* 本趟快照初始对齐 */
    2f08:	00e79623          	sh	a4,12(a5)
    2f0c:	00d79723          	sh	a3,14(a5)
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
    2f10:	0084d713          	srli	a4,s1,0x8
    2f14:	00b71713          	slli	a4,a4,0xb
    2f18:	01071713          	slli	a4,a4,0x10
    2f1c:	01075713          	srli	a4,a4,0x10
    2f20:	00855693          	srli	a3,a0,0x8
    2f24:	00569693          	slli	a3,a3,0x5
    2f28:	7e06f693          	andi	a3,a3,2016
    2f2c:	00d76733          	or	a4,a4,a3
                                  | ((r1 + r2) & 0x1Fu));
    2f30:	00a484b3          	add	s1,s1,a0
    2f34:	01f4f493          	andi	s1,s1,31
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
    2f38:	00976733          	or	a4,a4,s1
    2f3c:	00e79823          	sh	a4,16(a5)
        for (i = 0; i < n; i++) {
    2f40:	00140413          	addi	s0,s0,1
    2f44:	05345863          	bge	s0,s3,2f94 <scene_init+0x210>
            uint32_t r1 = lcg(&s), r2 = lcg(&s);
    2f48:	00c10513          	addi	a0,sp,12
    2f4c:	e11ff0ef          	jal	2d5c <lcg>
    2f50:	00050493          	mv	s1,a0
    2f54:	00c10513          	addi	a0,sp,12
    2f58:	e05ff0ef          	jal	2d5c <lcg>
            if (sz_fixed) b->sz = (uint8_t)SPR_W;            /* ALPHA/KEY 用图集尺寸 */
    2f5c:	e40a0ee3          	beqz	s4,2db8 <scene_init+0x34>
    2f60:	00004737          	lui	a4,0x4
    2f64:	00241793          	slli	a5,s0,0x2
    2f68:	008787b3          	add	a5,a5,s0
    2f6c:	00279793          	slli	a5,a5,0x2
    2f70:	000036b7          	lui	a3,0x3
    2f74:	6b068693          	addi	a3,a3,1712 # 36b0 <__udivdi3+0x454>
    2f78:	02d906b3          	mul	a3,s2,a3
    2f7c:	00d787b3          	add	a5,a5,a3
    2f80:	0e470713          	addi	a4,a4,228 # 40e4 <g_sc>
    2f84:	00f707b3          	add	a5,a4,a5
    2f88:	02000713          	li	a4,32
    2f8c:	00e78923          	sb	a4,18(a5)
    2f90:	e7dff06f          	j	2e0c <scene_init+0x88>
    for (side = 0; side < NSIDE; side++) {
    2f94:	00190913          	addi	s2,s2,1
    2f98:	00100793          	li	a5,1
    2f9c:	0127c863          	blt	a5,s2,2fac <scene_init+0x228>
        uint32_t s = seed;
    2fa0:	01512623          	sw	s5,12(sp)
        for (i = 0; i < n; i++) {
    2fa4:	00000413          	li	s0,0
    2fa8:	f9dff06f          	j	2f44 <scene_init+0x1c0>
}
    2fac:	02c12083          	lw	ra,44(sp)
    2fb0:	02812403          	lw	s0,40(sp)
    2fb4:	02412483          	lw	s1,36(sp)
    2fb8:	02012903          	lw	s2,32(sp)
    2fbc:	01c12983          	lw	s3,28(sp)
    2fc0:	01812a03          	lw	s4,24(sp)
    2fc4:	01412a83          	lw	s5,20(sp)
    2fc8:	03010113          	addi	sp,sp,48
    2fcc:	00008067          	ret

00002fd0 <scene_snap>:
    for (i = 0; i < n; i++) { sc[i].tx = sc[i].x; sc[i].ty = sc[i].y; }
    2fd0:	00000713          	li	a4,0
    2fd4:	0280006f          	j	2ffc <scene_snap+0x2c>
    2fd8:	00271793          	slli	a5,a4,0x2
    2fdc:	00e787b3          	add	a5,a5,a4
    2fe0:	00279793          	slli	a5,a5,0x2
    2fe4:	00f507b3          	add	a5,a0,a5
    2fe8:	00079683          	lh	a3,0(a5)
    2fec:	00d79623          	sh	a3,12(a5)
    2ff0:	00279683          	lh	a3,2(a5)
    2ff4:	00d79723          	sh	a3,14(a5)
    2ff8:	00170713          	addi	a4,a4,1
    2ffc:	fcb74ee3          	blt	a4,a1,2fd8 <scene_snap+0x8>
}
    3000:	00008067          	ret

00003004 <scene_step>:
    int xmin = rg->x0, xmax = rg->x0 + rg->w;
    3004:	00062e83          	lw	t4,0(a2)
    3008:	00862f83          	lw	t6,8(a2)
    300c:	01df8fb3          	add	t6,t6,t4
    int ymin = rg->y0, ymax = rg->y0 + rg->h;
    3010:	00462e03          	lw	t3,4(a2)
    3014:	00c62f03          	lw	t5,12(a2)
    3018:	01cf0f33          	add	t5,t5,t3
    for (i = 0; i < n; i++) {
    301c:	00000893          	li	a7,0
    3020:	0440006f          	j	3064 <scene_step+0x60>
        else if (x + w > xmax) { x = xmax - w; b->vx = (int16_t)(-b->vx); }
    3024:	006682b3          	add	t0,a3,t1
    3028:	005fdc63          	bge	t6,t0,3040 <scene_step+0x3c>
    302c:	406f86b3          	sub	a3,t6,t1
    3030:	01081813          	slli	a6,a6,0x10
    3034:	01085813          	srli	a6,a6,0x10
    3038:	41000833          	neg	a6,a6
    303c:	01079223          	sh	a6,4(a5)
        if (y < ymin)          { y = ymin;     b->vy = (int16_t)(-b->vy); }
    3040:	07c75863          	bge	a4,t3,30b0 <scene_step+0xac>
    3044:	01061613          	slli	a2,a2,0x10
    3048:	01065613          	srli	a2,a2,0x10
    304c:	40c00633          	neg	a2,a2
    3050:	00c79323          	sh	a2,6(a5)
    3054:	000e0713          	mv	a4,t3
        b->x = (int16_t)x;
    3058:	00d79023          	sh	a3,0(a5)
        b->y = (int16_t)y;
    305c:	00e79123          	sh	a4,2(a5)
    for (i = 0; i < n; i++) {
    3060:	00188893          	addi	a7,a7,1
    3064:	06b8d663          	bge	a7,a1,30d0 <scene_step+0xcc>
        blk_t *b = &sc[i];
    3068:	00289793          	slli	a5,a7,0x2
    306c:	011787b3          	add	a5,a5,a7
    3070:	00279793          	slli	a5,a5,0x2
    3074:	00f507b3          	add	a5,a0,a5
        int x = b->x + b->vx, y = b->y + b->vy, w = b->sz;
    3078:	00079683          	lh	a3,0(a5)
    307c:	00479803          	lh	a6,4(a5)
    3080:	010686b3          	add	a3,a3,a6
    3084:	00279703          	lh	a4,2(a5)
    3088:	00679603          	lh	a2,6(a5)
    308c:	00c70733          	add	a4,a4,a2
    3090:	0127c303          	lbu	t1,18(a5)
        if (x < xmin)          { x = xmin;     b->vx = (int16_t)(-b->vx); }
    3094:	f9d6d8e3          	bge	a3,t4,3024 <scene_step+0x20>
    3098:	01081813          	slli	a6,a6,0x10
    309c:	01085813          	srli	a6,a6,0x10
    30a0:	41000833          	neg	a6,a6
    30a4:	01079223          	sh	a6,4(a5)
    30a8:	000e8693          	mv	a3,t4
    30ac:	f95ff06f          	j	3040 <scene_step+0x3c>
        else if (y + w > ymax) { y = ymax - w; b->vy = (int16_t)(-b->vy); }
    30b0:	00670833          	add	a6,a4,t1
    30b4:	fb0f52e3          	bge	t5,a6,3058 <scene_step+0x54>
    30b8:	406f0733          	sub	a4,t5,t1
    30bc:	01061613          	slli	a2,a2,0x10
    30c0:	01065613          	srli	a2,a2,0x10
    30c4:	40c00633          	neg	a2,a2
    30c8:	00c79323          	sh	a2,6(a5)
    30cc:	f8dff06f          	j	3058 <scene_step+0x54>
}
    30d0:	00008067          	ret

000030d4 <hw_y0>:
static int hw_y0(int path)  { (void)path; return TOP_Y0; }
    30d4:	01000513          	li	a0,16
    30d8:	00008067          	ret

000030dc <hw_h>:
static int hw_h(int path)   { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
    30dc:	00051663          	bnez	a0,30e8 <hw_h+0xc>
    30e0:	10400513          	li	a0,260
    30e4:	00008067          	ret
    30e8:	20c00513          	li	a0,524
    30ec:	00008067          	ret

000030f0 <cpu_y0>:
static int cpu_y0(int path) { return (path == PATH_SPLIT) ? BOT_Y0 : TOP_Y0; }
    30f0:	00051663          	bnez	a0,30fc <cpu_y0+0xc>
    30f4:	11800513          	li	a0,280
    30f8:	00008067          	ret
    30fc:	01000513          	li	a0,16
    3100:	00008067          	ret

00003104 <cpu_h>:
static int cpu_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
    3104:	00051663          	bnez	a0,3110 <cpu_h+0xc>
    3108:	10400513          	li	a0,260
    310c:	00008067          	ret
    3110:	20c00513          	li	a0,524
    3114:	00008067          	ret

00003118 <vrg_h>:
static int vrg_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
    3118:	00051663          	bnez	a0,3124 <vrg_h+0xc>
    311c:	10400513          	li	a0,260
    3120:	00008067          	ret
    3124:	20c00513          	li	a0,524
    3128:	00008067          	ret

0000312c <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    312c:	fc010113          	addi	sp,sp,-64
    3130:	00112e23          	sw	ra,28(sp)
    3134:	00812c23          	sw	s0,24(sp)
    3138:	00912a23          	sw	s1,20(sp)
    313c:	00050493          	mv	s1,a0
    3140:	02b12223          	sw	a1,36(sp)
    3144:	02c12423          	sw	a2,40(sp)
    3148:	02d12623          	sw	a3,44(sp)
    314c:	02e12823          	sw	a4,48(sp)
    3150:	02f12a23          	sw	a5,52(sp)
    3154:	03012c23          	sw	a6,56(sp)
    3158:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    315c:	02410793          	addi	a5,sp,36
    3160:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    3164:	00000413          	li	s0,0
    3168:	01c0006f          	j	3184 <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    316c:	00c12783          	lw	a5,12(sp)
    3170:	00478713          	addi	a4,a5,4
    3174:	00e12623          	sw	a4,12(sp)
    3178:	0007a503          	lw	a0,0(a5)
    317c:	8c8ff0ef          	jal	2244 <bsp_printf_c>
        for (i = 0; format[i]; i++)
    3180:	00140413          	addi	s0,s0,1
    3184:	008487b3          	add	a5,s1,s0
    3188:	0007c503          	lbu	a0,0(a5)
    318c:	0a050e63          	beqz	a0,3248 <bsp_printf+0x11c>
            if (format[i] == '%') {
    3190:	02500793          	li	a5,37
    3194:	06f50e63          	beq	a0,a5,3210 <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    3198:	8acff0ef          	jal	2244 <bsp_printf_c>
    319c:	fe5ff06f          	j	3180 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    31a0:	00c12783          	lw	a5,12(sp)
    31a4:	00478713          	addi	a4,a5,4
    31a8:	00e12623          	sw	a4,12(sp)
    31ac:	0007a503          	lw	a0,0(a5)
    31b0:	8b0ff0ef          	jal	2260 <bsp_printf_s>
                        break;
    31b4:	fcdff06f          	j	3180 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    31b8:	00c12783          	lw	a5,12(sp)
    31bc:	00478713          	addi	a4,a5,4
    31c0:	00e12623          	sw	a4,12(sp)
    31c4:	0007a503          	lw	a0,0(a5)
    31c8:	8b0ff0ef          	jal	2278 <bsp_printf_d>
                        break;
    31cc:	fb5ff06f          	j	3180 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    31d0:	00c12783          	lw	a5,12(sp)
    31d4:	00478713          	addi	a4,a5,4
    31d8:	00e12623          	sw	a4,12(sp)
    31dc:	0007a503          	lw	a0,0(a5)
    31e0:	958ff0ef          	jal	2338 <bsp_printf_X>
                        break;
    31e4:	f9dff06f          	j	3180 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    31e8:	00c12783          	lw	a5,12(sp)
    31ec:	00478713          	addi	a4,a5,4
    31f0:	00e12623          	sw	a4,12(sp)
    31f4:	0007a503          	lw	a0,0(a5)
    31f8:	900ff0ef          	jal	22f8 <bsp_printf_x>
                        break;
    31fc:	f85ff06f          	j	3180 <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    3200:	00003537          	lui	a0,0x3
    3204:	73450513          	addi	a0,a0,1844 # 3734 <_data+0x28>
    3208:	858ff0ef          	jal	2260 <bsp_printf_s>
                        break;
    320c:	f75ff06f          	j	3180 <bsp_printf+0x54>
                while (format[++i]) {
    3210:	00140413          	addi	s0,s0,1
    3214:	008487b3          	add	a5,s1,s0
    3218:	0007c783          	lbu	a5,0(a5)
    321c:	f60782e3          	beqz	a5,3180 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    3220:	fa878793          	addi	a5,a5,-88
    3224:	0ff7f693          	zext.b	a3,a5
    3228:	02000713          	li	a4,32
    322c:	fed762e3          	bltu	a4,a3,3210 <bsp_printf+0xe4>
    3230:	00269793          	slli	a5,a3,0x2
    3234:	00004737          	lui	a4,0x4
    3238:	c4c70713          	addi	a4,a4,-948 # 3c4c <_data+0x540>
    323c:	00e787b3          	add	a5,a5,a4
    3240:	0007a783          	lw	a5,0(a5)
    3244:	00078067          	jr	a5

        va_end(ap);
    }
    3248:	01c12083          	lw	ra,28(sp)
    324c:	01812403          	lw	s0,24(sp)
    3250:	01412483          	lw	s1,20(sp)
    3254:	04010113          	addi	sp,sp,64
    3258:	00008067          	ret

0000325c <__udivdi3>:
    325c:	00060813          	mv	a6,a2
    3260:	00050893          	mv	a7,a0
    3264:	00058713          	mv	a4,a1
    3268:	0e069063          	bnez	a3,3348 <__udivdi3+0xec>
    326c:	12c5fe63          	bgeu	a1,a2,33a8 <__udivdi3+0x14c>
    3270:	000107b7          	lui	a5,0x10
    3274:	1ef66e63          	bltu	a2,a5,3470 <__udivdi3+0x214>
    3278:	010007b7          	lui	a5,0x1000
    327c:	01800693          	li	a3,24
    3280:	00f67463          	bgeu	a2,a5,3288 <__udivdi3+0x2c>
    3284:	01000693          	li	a3,16
    3288:	00d65333          	srl	t1,a2,a3
    328c:	00001797          	auipc	a5,0x1
    3290:	d4878793          	addi	a5,a5,-696 # 3fd4 <__clz_tab>
    3294:	006787b3          	add	a5,a5,t1
    3298:	0007c783          	lbu	a5,0(a5)
    329c:	02000313          	li	t1,32
    32a0:	00d787b3          	add	a5,a5,a3
    32a4:	40f306b3          	sub	a3,t1,a5
    32a8:	00f30c63          	beq	t1,a5,32c0 <__udivdi3+0x64>
    32ac:	00d59733          	sll	a4,a1,a3
    32b0:	00f557b3          	srl	a5,a0,a5
    32b4:	00d61833          	sll	a6,a2,a3
    32b8:	00e7e733          	or	a4,a5,a4
    32bc:	00d518b3          	sll	a7,a0,a3
    32c0:	01085613          	srli	a2,a6,0x10
    32c4:	02c75533          	divu	a0,a4,a2
    32c8:	01081693          	slli	a3,a6,0x10
    32cc:	0106d693          	srli	a3,a3,0x10
    32d0:	0108d793          	srli	a5,a7,0x10
    32d4:	02c77733          	remu	a4,a4,a2
    32d8:	02a685b3          	mul	a1,a3,a0
    32dc:	01071713          	slli	a4,a4,0x10
    32e0:	00e7e7b3          	or	a5,a5,a4
    32e4:	00b7fc63          	bgeu	a5,a1,32fc <__udivdi3+0xa0>
    32e8:	00f807b3          	add	a5,a6,a5
    32ec:	fff50713          	addi	a4,a0,-1
    32f0:	0107e463          	bltu	a5,a6,32f8 <__udivdi3+0x9c>
    32f4:	40b7e063          	bltu	a5,a1,36f4 <__udivdi3+0x498>
    32f8:	00070513          	mv	a0,a4
    32fc:	40b787b3          	sub	a5,a5,a1
    3300:	02c7d733          	divu	a4,a5,a2
    3304:	01089893          	slli	a7,a7,0x10
    3308:	0108d893          	srli	a7,a7,0x10
    330c:	02c7f7b3          	remu	a5,a5,a2
    3310:	02e686b3          	mul	a3,a3,a4
    3314:	01079793          	slli	a5,a5,0x10
    3318:	00f8e8b3          	or	a7,a7,a5
    331c:	00d8fe63          	bgeu	a7,a3,3338 <__udivdi3+0xdc>
    3320:	011808b3          	add	a7,a6,a7
    3324:	fff70793          	addi	a5,a4,-1
    3328:	0108e663          	bltu	a7,a6,3334 <__udivdi3+0xd8>
    332c:	ffe70713          	addi	a4,a4,-2
    3330:	00d8e463          	bltu	a7,a3,3338 <__udivdi3+0xdc>
    3334:	00078713          	mv	a4,a5
    3338:	01051513          	slli	a0,a0,0x10
    333c:	00e56533          	or	a0,a0,a4
    3340:	00000593          	li	a1,0
    3344:	00008067          	ret
    3348:	00d5f863          	bgeu	a1,a3,3358 <__udivdi3+0xfc>
    334c:	00000593          	li	a1,0
    3350:	00000513          	li	a0,0
    3354:	00008067          	ret
    3358:	000107b7          	lui	a5,0x10
    335c:	1ef6e863          	bltu	a3,a5,354c <__udivdi3+0x2f0>
    3360:	01000737          	lui	a4,0x1000
    3364:	01800793          	li	a5,24
    3368:	00e6f463          	bgeu	a3,a4,3370 <__udivdi3+0x114>
    336c:	01000793          	li	a5,16
    3370:	00f6d833          	srl	a6,a3,a5
    3374:	00001717          	auipc	a4,0x1
    3378:	c6070713          	addi	a4,a4,-928 # 3fd4 <__clz_tab>
    337c:	01070733          	add	a4,a4,a6
    3380:	00074703          	lbu	a4,0(a4)
    3384:	02000893          	li	a7,32
    3388:	00f70733          	add	a4,a4,a5
    338c:	40e88833          	sub	a6,a7,a4
    3390:	1ee89663          	bne	a7,a4,357c <__udivdi3+0x320>
    3394:	32b6e463          	bltu	a3,a1,36bc <__udivdi3+0x460>
    3398:	00c53533          	sltu	a0,a0,a2
    339c:	00153513          	seqz	a0,a0
    33a0:	00000593          	li	a1,0
    33a4:	00008067          	ret
    33a8:	0c060c63          	beqz	a2,3480 <__udivdi3+0x224>
    33ac:	000107b7          	lui	a5,0x10
    33b0:	2ef67c63          	bgeu	a2,a5,36a8 <__udivdi3+0x44c>
    33b4:	10063713          	sltiu	a4,a2,256
    33b8:	00173713          	seqz	a4,a4
    33bc:	00371713          	slli	a4,a4,0x3
    33c0:	00e656b3          	srl	a3,a2,a4
    33c4:	00001797          	auipc	a5,0x1
    33c8:	c1078793          	addi	a5,a5,-1008 # 3fd4 <__clz_tab>
    33cc:	00d787b3          	add	a5,a5,a3
    33d0:	0007c783          	lbu	a5,0(a5)
    33d4:	02000693          	li	a3,32
    33d8:	00e787b3          	add	a5,a5,a4
    33dc:	40f68eb3          	sub	t4,a3,a5
    33e0:	0cf69463          	bne	a3,a5,34a8 <__udivdi3+0x24c>
    33e4:	40c587b3          	sub	a5,a1,a2
    33e8:	01065693          	srli	a3,a2,0x10
    33ec:	01061613          	slli	a2,a2,0x10
    33f0:	01065613          	srli	a2,a2,0x10
    33f4:	00100593          	li	a1,1
    33f8:	02d7d533          	divu	a0,a5,a3
    33fc:	0108d713          	srli	a4,a7,0x10
    3400:	02d7f7b3          	remu	a5,a5,a3
    3404:	02c50333          	mul	t1,a0,a2
    3408:	01079793          	slli	a5,a5,0x10
    340c:	00f767b3          	or	a5,a4,a5
    3410:	0067fc63          	bgeu	a5,t1,3428 <__udivdi3+0x1cc>
    3414:	00f807b3          	add	a5,a6,a5
    3418:	fff50713          	addi	a4,a0,-1
    341c:	0107e463          	bltu	a5,a6,3424 <__udivdi3+0x1c8>
    3420:	2c67e463          	bltu	a5,t1,36e8 <__udivdi3+0x48c>
    3424:	00070513          	mv	a0,a4
    3428:	406787b3          	sub	a5,a5,t1
    342c:	02d7d733          	divu	a4,a5,a3
    3430:	01089893          	slli	a7,a7,0x10
    3434:	0108d893          	srli	a7,a7,0x10
    3438:	02d7f7b3          	remu	a5,a5,a3
    343c:	02c70633          	mul	a2,a4,a2
    3440:	01079793          	slli	a5,a5,0x10
    3444:	00f8e8b3          	or	a7,a7,a5
    3448:	00c8fe63          	bgeu	a7,a2,3464 <__udivdi3+0x208>
    344c:	011808b3          	add	a7,a6,a7
    3450:	fff70793          	addi	a5,a4,-1
    3454:	0108e663          	bltu	a7,a6,3460 <__udivdi3+0x204>
    3458:	ffe70713          	addi	a4,a4,-2
    345c:	00c8e463          	bltu	a7,a2,3464 <__udivdi3+0x208>
    3460:	00078713          	mv	a4,a5
    3464:	01051513          	slli	a0,a0,0x10
    3468:	00e56533          	or	a0,a0,a4
    346c:	00008067          	ret
    3470:	10063693          	sltiu	a3,a2,256
    3474:	0016b693          	seqz	a3,a3
    3478:	00369693          	slli	a3,a3,0x3
    347c:	e0dff06f          	j	3288 <__udivdi3+0x2c>
    3480:	00000693          	li	a3,0
    3484:	00001797          	auipc	a5,0x1
    3488:	b5078793          	addi	a5,a5,-1200 # 3fd4 <__clz_tab>
    348c:	00d787b3          	add	a5,a5,a3
    3490:	0007c783          	lbu	a5,0(a5)
    3494:	00000713          	li	a4,0
    3498:	02000693          	li	a3,32
    349c:	00e787b3          	add	a5,a5,a4
    34a0:	40f68eb3          	sub	t4,a3,a5
    34a4:	f4f680e3          	beq	a3,a5,33e4 <__udivdi3+0x188>
    34a8:	01d61833          	sll	a6,a2,t4
    34ac:	00f5d333          	srl	t1,a1,a5
    34b0:	01085693          	srli	a3,a6,0x10
    34b4:	02d35e33          	divu	t3,t1,a3
    34b8:	01081613          	slli	a2,a6,0x10
    34bc:	01d595b3          	sll	a1,a1,t4
    34c0:	01065613          	srli	a2,a2,0x10
    34c4:	00f557b3          	srl	a5,a0,a5
    34c8:	00b7e7b3          	or	a5,a5,a1
    34cc:	0107d713          	srli	a4,a5,0x10
    34d0:	01d518b3          	sll	a7,a0,t4
    34d4:	02d37333          	remu	t1,t1,a3
    34d8:	03c605b3          	mul	a1,a2,t3
    34dc:	01031313          	slli	t1,t1,0x10
    34e0:	00676733          	or	a4,a4,t1
    34e4:	00b77e63          	bgeu	a4,a1,3500 <__udivdi3+0x2a4>
    34e8:	00e80733          	add	a4,a6,a4
    34ec:	fffe0513          	addi	a0,t3,-1
    34f0:	1f076463          	bltu	a4,a6,36d8 <__udivdi3+0x47c>
    34f4:	1eb77263          	bgeu	a4,a1,36d8 <__udivdi3+0x47c>
    34f8:	ffee0e13          	addi	t3,t3,-2
    34fc:	01070733          	add	a4,a4,a6
    3500:	40b70733          	sub	a4,a4,a1
    3504:	02d75533          	divu	a0,a4,a3
    3508:	01079793          	slli	a5,a5,0x10
    350c:	0107d793          	srli	a5,a5,0x10
    3510:	02d77733          	remu	a4,a4,a3
    3514:	02a60333          	mul	t1,a2,a0
    3518:	01071713          	slli	a4,a4,0x10
    351c:	00e7e7b3          	or	a5,a5,a4
    3520:	0067fe63          	bgeu	a5,t1,353c <__udivdi3+0x2e0>
    3524:	00f807b3          	add	a5,a6,a5
    3528:	fff50713          	addi	a4,a0,-1
    352c:	1907ee63          	bltu	a5,a6,36c8 <__udivdi3+0x46c>
    3530:	1867fc63          	bgeu	a5,t1,36c8 <__udivdi3+0x46c>
    3534:	ffe50513          	addi	a0,a0,-2
    3538:	010787b3          	add	a5,a5,a6
    353c:	010e1593          	slli	a1,t3,0x10
    3540:	406787b3          	sub	a5,a5,t1
    3544:	00a5e5b3          	or	a1,a1,a0
    3548:	eb1ff06f          	j	33f8 <__udivdi3+0x19c>
    354c:	1006b793          	sltiu	a5,a3,256
    3550:	0017b793          	seqz	a5,a5
    3554:	00379793          	slli	a5,a5,0x3
    3558:	00f6d833          	srl	a6,a3,a5
    355c:	00001717          	auipc	a4,0x1
    3560:	a7870713          	addi	a4,a4,-1416 # 3fd4 <__clz_tab>
    3564:	01070733          	add	a4,a4,a6
    3568:	00074703          	lbu	a4,0(a4)
    356c:	02000893          	li	a7,32
    3570:	00f70733          	add	a4,a4,a5
    3574:	40e88833          	sub	a6,a7,a4
    3578:	e0e88ee3          	beq	a7,a4,3394 <__udivdi3+0x138>
    357c:	00e65e33          	srl	t3,a2,a4
    3580:	010696b3          	sll	a3,a3,a6
    3584:	00de6e33          	or	t3,t3,a3
    3588:	00e5d8b3          	srl	a7,a1,a4
    358c:	010e5e93          	srli	t4,t3,0x10
    3590:	03d8d7b3          	divu	a5,a7,t4
    3594:	010e1313          	slli	t1,t3,0x10
    3598:	010595b3          	sll	a1,a1,a6
    359c:	01035313          	srli	t1,t1,0x10
    35a0:	00e55733          	srl	a4,a0,a4
    35a4:	00b76733          	or	a4,a4,a1
    35a8:	01075693          	srli	a3,a4,0x10
    35ac:	01061633          	sll	a2,a2,a6
    35b0:	03d8f8b3          	remu	a7,a7,t4
    35b4:	02f305b3          	mul	a1,t1,a5
    35b8:	01089893          	slli	a7,a7,0x10
    35bc:	0116e6b3          	or	a3,a3,a7
    35c0:	00b6fe63          	bgeu	a3,a1,35dc <__udivdi3+0x380>
    35c4:	00de06b3          	add	a3,t3,a3
    35c8:	fff78893          	addi	a7,a5,-1
    35cc:	11c6ea63          	bltu	a3,t3,36e0 <__udivdi3+0x484>
    35d0:	10b6f863          	bgeu	a3,a1,36e0 <__udivdi3+0x484>
    35d4:	ffe78793          	addi	a5,a5,-2
    35d8:	01c686b3          	add	a3,a3,t3
    35dc:	40b686b3          	sub	a3,a3,a1
    35e0:	03d6d5b3          	divu	a1,a3,t4
    35e4:	01071713          	slli	a4,a4,0x10
    35e8:	01075713          	srli	a4,a4,0x10
    35ec:	03d6f6b3          	remu	a3,a3,t4
    35f0:	02b308b3          	mul	a7,t1,a1
    35f4:	01069693          	slli	a3,a3,0x10
    35f8:	00d76733          	or	a4,a4,a3
    35fc:	01177e63          	bgeu	a4,a7,3618 <__udivdi3+0x3bc>
    3600:	00ee0733          	add	a4,t3,a4
    3604:	fff58693          	addi	a3,a1,-1
    3608:	0dc76463          	bltu	a4,t3,36d0 <__udivdi3+0x474>
    360c:	0d177263          	bgeu	a4,a7,36d0 <__udivdi3+0x474>
    3610:	ffe58593          	addi	a1,a1,-2
    3614:	01c70733          	add	a4,a4,t3
    3618:	01079793          	slli	a5,a5,0x10
    361c:	00010eb7          	lui	t4,0x10
    3620:	00b7e7b3          	or	a5,a5,a1
    3624:	fffe8693          	addi	a3,t4,-1 # ffff <__freertos_irq_stack_top+0x41af>
    3628:	00d7f5b3          	and	a1,a5,a3
    362c:	0107d313          	srli	t1,a5,0x10
    3630:	00d676b3          	and	a3,a2,a3
    3634:	01065613          	srli	a2,a2,0x10
    3638:	02d58e33          	mul	t3,a1,a3
    363c:	41170733          	sub	a4,a4,a7
    3640:	02d306b3          	mul	a3,t1,a3
    3644:	010e5893          	srli	a7,t3,0x10
    3648:	02c585b3          	mul	a1,a1,a2
    364c:	00d585b3          	add	a1,a1,a3
    3650:	00b885b3          	add	a1,a7,a1
    3654:	02c30333          	mul	t1,t1,a2
    3658:	00d5f463          	bgeu	a1,a3,3660 <__udivdi3+0x404>
    365c:	01d30333          	add	t1,t1,t4
    3660:	0105d693          	srli	a3,a1,0x10
    3664:	006686b3          	add	a3,a3,t1
    3668:	02d76a63          	bltu	a4,a3,369c <__udivdi3+0x440>
    366c:	00d70863          	beq	a4,a3,367c <__udivdi3+0x420>
    3670:	00078513          	mv	a0,a5
    3674:	00000593          	li	a1,0
    3678:	00008067          	ret
    367c:	000106b7          	lui	a3,0x10
    3680:	fff68693          	addi	a3,a3,-1 # ffff <__freertos_irq_stack_top+0x41af>
    3684:	00d5f733          	and	a4,a1,a3
    3688:	01071713          	slli	a4,a4,0x10
    368c:	00de7e33          	and	t3,t3,a3
    3690:	01051533          	sll	a0,a0,a6
    3694:	01c70733          	add	a4,a4,t3
    3698:	fce57ce3          	bgeu	a0,a4,3670 <__udivdi3+0x414>
    369c:	fff78513          	addi	a0,a5,-1
    36a0:	00000593          	li	a1,0
    36a4:	00008067          	ret
    36a8:	010007b7          	lui	a5,0x1000
    36ac:	04f67a63          	bgeu	a2,a5,3700 <__udivdi3+0x4a4>
    36b0:	01065693          	srli	a3,a2,0x10
    36b4:	01000713          	li	a4,16
    36b8:	d0dff06f          	j	33c4 <__udivdi3+0x168>
    36bc:	00000593          	li	a1,0
    36c0:	00100513          	li	a0,1
    36c4:	00008067          	ret
    36c8:	00070513          	mv	a0,a4
    36cc:	e71ff06f          	j	353c <__udivdi3+0x2e0>
    36d0:	00068593          	mv	a1,a3
    36d4:	f45ff06f          	j	3618 <__udivdi3+0x3bc>
    36d8:	00050e13          	mv	t3,a0
    36dc:	e25ff06f          	j	3500 <__udivdi3+0x2a4>
    36e0:	00088793          	mv	a5,a7
    36e4:	ef9ff06f          	j	35dc <__udivdi3+0x380>
    36e8:	ffe50513          	addi	a0,a0,-2
    36ec:	010787b3          	add	a5,a5,a6
    36f0:	d39ff06f          	j	3428 <__udivdi3+0x1cc>
    36f4:	ffe50513          	addi	a0,a0,-2
    36f8:	010787b3          	add	a5,a5,a6
    36fc:	c01ff06f          	j	32fc <__udivdi3+0xa0>
    3700:	01865693          	srli	a3,a2,0x18
    3704:	01800713          	li	a4,24
    3708:	cbdff06f          	j	33c4 <__udivdi3+0x168>
