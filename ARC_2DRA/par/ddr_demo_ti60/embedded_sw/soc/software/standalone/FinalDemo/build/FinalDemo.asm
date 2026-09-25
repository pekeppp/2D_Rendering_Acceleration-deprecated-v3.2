
build/FinalDemo.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00007197          	auipc	gp,0x7
    1004:	0f818193          	addi	gp,gp,248 # 80f8 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00042117          	auipc	sp,0x42
    100c:	39810113          	addi	sp,sp,920 # 433a0 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00005517          	auipc	a0,0x5
    1014:	df050513          	addi	a0,a0,-528 # 5e00 <_data>
	la a1, _data
    1018:	00005597          	auipc	a1,0x5
    101c:	de858593          	addi	a1,a1,-536 # 5e00 <_data>
	la a2, _edata
    1020:	00007617          	auipc	a2,0x7
    1024:	91460613          	addi	a2,a2,-1772 # 7934 <g_cmd_t0>
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
    1040:	00007517          	auipc	a0,0x7
    1044:	8f450513          	addi	a0,a0,-1804 # 7934 <g_cmd_t0>
	la a1, _end
    1048:	00041597          	auipc	a1,0x41
    104c:	35858593          	addi	a1,a1,856 # 423a0 <_end>
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
    107c:	00005797          	auipc	a5,0x5
    1080:	d8478793          	addi	a5,a5,-636 # 5e00 <_data>
    1084:	00005417          	auipc	s0,0x5
    1088:	d7c40413          	addi	s0,s0,-644 # 5e00 <_data>
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
    10b8:	00005797          	auipc	a5,0x5
    10bc:	d4878793          	addi	a5,a5,-696 # 5e00 <_data>
    10c0:	00005417          	auipc	s0,0x5
    10c4:	d4040413          	addi	s0,s0,-704 # 5e00 <_data>
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
    1104:	f3010113          	addi	sp,sp,-208
    1108:	0c112623          	sw	ra,204(sp)
    110c:	0c812423          	sw	s0,200(sp)
    1110:	0c912223          	sw	s1,196(sp)
    1114:	0d212023          	sw	s2,192(sp)
    1118:	0b312e23          	sw	s3,188(sp)
    111c:	0b412c23          	sw	s4,184(sp)
    1120:	0b512a23          	sw	s5,180(sp)
    1124:	0b612823          	sw	s6,176(sp)
    1128:	0b712623          	sw	s7,172(sp)
    112c:	0b812423          	sw	s8,168(sp)
    1130:	0b912223          	sw	s9,164(sp)
    1134:	0ba12023          	sw	s10,160(sp)
    1138:	09b12e23          	sw	s11,156(sp)
    int      path  = PATH_HW;          /* ★ 默认：纯硬件整屏 */
    int      scene = SC_FILL;
    int      n     = N_MIN;            /* ★ 默认 N=25 */
    int      n_cmd = N_MIN;            /* '=' 行缓冲结算出的 N（nline_feed 的出口） */
    113c:	01900793          	li	a5,25
    1140:	08f12623          	sw	a5,140(sp)
    /* ★ 三个计数器共用同一个 1Hz 窗口、同一次清零（见 osd_service 调用点）：
     *   hw_frames/cpu_frames 数的是两侧各自的**渲染趟数**，scr_frames 数的是
     *   **整帧 COPY 真正完成的次数** = 上屏帧数 —— 屏幕的流畅度只看最后一个。 */
    uint32_t hw_frames = 0, cpu_frames = 0, scr_frames = 0;
    uint32_t t_scene, t_now = 0;
    int hw_i = 0, hw_frame_pushed = 0;
    1144:	08012423          	sw	zero,136(sp)
    int size_repaint = 0;
#endif
    /* 双缓冲：两侧各完成一遍 = 一个演示帧，此刻把后台缓冲整体搬上屏一次 */
    int hw_done = 0, cpu_done = 0, back_busy = 0;
    /* 快照失效标志：场景位置变过 ⇒ 等本侧下一趟起点再重拍（保证一趟内 tx,ty 恒定） */
    int snap_hw = 0, snap_cpu = 0;
    1148:	08012223          	sw	zero,132(sp)
    114c:	08012023          	sw	zero,128(sp)
    uint32_t back_t0 = 0;

    rect_t vrg;
    vrg.x0 = 0; vrg.y0 = 0; vrg.w = FB_WIDTH; vrg.h = HALF_H;
    1150:	06012823          	sw	zero,112(sp)
    1154:	06012a23          	sw	zero,116(sp)
    1158:	3c000793          	li	a5,960
    115c:	06f12c23          	sw	a5,120(sp)
    1160:	10400793          	li	a5,260
    1164:	06f12e23          	sw	a5,124(sp)

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */
    1168:	519010ef          	jal	2e80 <bsp_init>

    bsp_printf("\r\n===== FinalDemo: HW accel vs pure CPU, same screen =====\r\n");
    116c:	00007537          	lui	a0,0x7
    1170:	8a050513          	addi	a0,a0,-1888 # 68a0 <_data+0xaa0>
    1174:	57d030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("FB=%x BACK=%x ATLAS=%x SPR=%dx%d\r\n",
    1178:	8201a703          	lw	a4,-2016(gp) # 7918 <g_blk>
    117c:	00070793          	mv	a5,a4
    1180:	002016b7          	lui	a3,0x201
    1184:	00501637          	lui	a2,0x501
    1188:	003015b7          	lui	a1,0x301
    118c:	00007537          	lui	a0,0x7
    1190:	8e050513          	addi	a0,a0,-1824 # 68e0 <_data+0xae0>
    1194:	55d030ef          	jal	4ef0 <bsp_printf>
               (unsigned)FB_BASE, (unsigned)FB_BACK, (unsigned)ATLAS_BASE, SPR_W, SPR_H);
    bsp_printf("blk: %dx%d sprite, runtime-switchable %d/%d/%d (key k cycles 16->32->64->16,\r\n",
    1198:	8201a583          	lw	a1,-2016(gp) # 7918 <g_blk>
    119c:	04000793          	li	a5,64
    11a0:	02000713          	li	a4,32
    11a4:	01000693          	li	a3,16
    11a8:	00058613          	mv	a2,a1
    11ac:	00007537          	lui	a0,0x7
    11b0:	90450513          	addi	a0,a0,-1788 # 6904 <_data+0xb04>
    11b4:	53d030ef          	jal	4ef0 <bsp_printf>
               SPR_W, SPR_H, BLK_LO, BLK_MID, BLK_HI);
    bsp_printf("     atlas rebuilt + scene re-init at every step)\r\n");
    11b8:	00007537          	lui	a0,0x7
    11bc:	95450513          	addi	a0,a0,-1708 # 6954 <_data+0xb54>
    11c0:	531030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("layout: info 0-16 | HW 16-276 | sep | CPU 280-540\r\n");
    11c4:	00007537          	lui	a0,0x7
    11c8:	98850513          	addi	a0,a0,-1656 # 6988 <_data+0xb88>
    11cc:	525030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("default: path=HW only, clear_per_pass=1, advance=time, N=%d\r\n", n);
    11d0:	01900593          	li	a1,25
    11d4:	00007537          	lui	a0,0x7
    11d8:	9bc50513          	addi	a0,a0,-1604 # 69bc <_data+0xbbc>
    11dc:	515030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("cmd: 1/2/3 scene FILL/ALPHA/KEY, s/c/h path SPLIT/CPU/HW\r\n");
    11e0:	00007537          	lui	a0,0x7
    11e4:	9fc50513          	addi	a0,a0,-1540 # 69fc <_data+0xbfc>
    11e8:	509030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("     n or + N+%d, - N-%d, a/A alpha-/+, e clear-per-pass,\r\n", N_STEP, N_STEP);
    11ec:	01900613          	li	a2,25
    11f0:	01900593          	li	a1,25
    11f4:	00007537          	lui	a0,0x7
    11f8:	a3850513          	addi	a0,a0,-1480 # 6a38 <_data+0xc38>
    11fc:	4f5030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("     =N exact N (%d..%d clamped, e.g. =1375 + Enter),\r\n", N_MIN, N_MAX);
    1200:	00001637          	lui	a2,0x1
    1204:	77060613          	addi	a2,a2,1904 # 1770 <main+0x66c>
    1208:	01900593          	li	a1,25
    120c:	00007537          	lui	a0,0x7
    1210:	a7450513          	addi	a0,a0,-1420 # 6a74 <_data+0xc74>
    1214:	4dd030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("     t time/frame advance, k blk 16/32/64 (cycles), r reset, ? help\r\n");
    1218:	00007537          	lui	a0,0x7
    121c:	aac50513          	addi	a0,a0,-1364 # 6aac <_data+0xcac>
    1220:	4d1030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("     l list mode (DDR descriptor table) on/off -- DEFAULT OFF\r\n");
    1224:	00007537          	lui	a0,0x7
    1228:	af450513          	addi	a0,a0,-1292 # 6af4 <_data+0xcf4>
    122c:	4c5030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("       (l takes effect at the next frame boundary, reply: EV dl on/off pending)\r\n");
    1230:	00007537          	lui	a0,0x7
    1234:	b3450513          	addi	a0,a0,-1228 # 6b34 <_data+0xd34>
    1238:	4b9030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("       DL WATCHDOG: 1 retry/event; a 2nd event within 1s disables list mode\r\n");
    123c:	00007537          	lui	a0,0x7
    1240:	b8850513          	addi	a0,a0,-1144 # 6b88 <_data+0xd88>
    1244:	4ad030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("       cost: EV dl list done / EV cmd path done (n=.. cycles=.. cyc/sprite=..)\r\n");
    1248:	00007537          	lui	a0,0x7
    124c:	bd850513          	addi	a0,a0,-1064 # 6bd8 <_data+0xdd8>
    1250:	4a1030ef          	jal	4ef0 <bsp_printf>

    blt_init();
    1254:	104020ef          	jal	3358 <blt_init>
#if FB_FLIP_PUBLISH
    /* ★ 先与实际在屏的缓冲对齐：FB_STAT[0] = 扫描输出**已经生效**的选择。
     *   不假设复位值 —— 这样"不复位 FPGA 直接重跑程序"也不会把后台缓冲画错
     *   （重跑时上一轮的翻转可能还生效着）。 */
    g_disp_sel = fb_stat_sel();
    1258:	539010ef          	jal	2f90 <fb_stat_sel>
    125c:	00050793          	mv	a5,a0
    1260:	8ca1aa23          	sw	a0,-1836(gp) # 79cc <g_disp_sel>
#if FB_TRIPLE_BUFFER
    /* ★v2.7 三缓冲轮转初值：本趟画 disp+1，另一块（disp+2）交给清屏引擎预清。
     *   必须在这里（osd_blit/铺底之前）就把 g_fb_back 定下来，否则信息条会画错缓冲。 */
    g_draw3      = (int)((g_disp_sel + 1u) % 3u);
    1264:	00150513          	addi	a0,a0,1
    1268:	00300493          	li	s1,3
    126c:	02957533          	remu	a0,a0,s1
    1270:	82a1a423          	sw	a0,-2008(gp) # 7920 <g_draw3>
    g_clr3       = (int)((g_disp_sel + 2u) % 3u);
    1274:	00278793          	addi	a5,a5,2
    1278:	0297f7b3          	remu	a5,a5,s1
    127c:	82f1a223          	sw	a5,-2012(gp) # 791c <g_clr3>
    g_clr_need   = 1;                  /* 本趟开始时给清屏引擎下第一条命令 */
    1280:	00100a93          	li	s5,1
    1284:	8d51a223          	sw	s5,-1852(gp) # 79bc <g_clr_need>
    g_pass_armed = 0;
    1288:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
    g_fb_back    = fb_of_sel((uint32_t)g_draw3);
    128c:	4dd010ef          	jal	2f68 <fb_of_sel>
    1290:	82a1a623          	sw	a0,-2004(gp) # 7924 <g_fb_back>
#else
    g_fb_back  = fb_of_sel(g_disp_sel ^ 1u);
#endif
#endif
    build_atlas();                    /* 精灵图集：开机按 BLK_LO=16 建（引擎与 CPU 都从这里取数；'k' 会重跑） */
    1294:	3cc020ef          	jal	3660 <build_atlas>
    spr_mask_report();                /* ★S3：图集一重建就报掩码（含"一块都标不上"这种读数） */
    1298:	589030ef          	jal	5020 <spr_mask_report>
    cpu_fill32(g_fb_back, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);      /* 整屏近黑铺底 */
    129c:	00800793          	li	a5,8
    12a0:	21c00713          	li	a4,540
    12a4:	3c000693          	li	a3,960
    12a8:	00000613          	li	a2,0
    12ac:	00000593          	li	a1,0
    12b0:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    12b4:	444020ef          	jal	36f8 <cpu_fill32>
    cache_evict();
    12b8:	725010ef          	jal	31dc <cache_evict>

    /* ★ 未对齐写入自检：CPU 侧曾因奇数 x 做 32bit 存储而整机静默停死。
     *   这两行能在开机第一秒就暴露该类问题（打印不出来或值不对 = 有问题）。 */
    cpu_fill32(g_fb_back, 33, 500, 8, 2, 0xF800u);
    12bc:	000107b7          	lui	a5,0x10
    12c0:	80078793          	addi	a5,a5,-2048 # f800 <__global_pointer$+0x7708>
    12c4:	00200713          	li	a4,2
    12c8:	00800693          	li	a3,8
    12cc:	1f400613          	li	a2,500
    12d0:	02100593          	li	a1,33
    12d4:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    12d8:	420020ef          	jal	36f8 <cpu_fill32>
    cpu_fill32(g_fb_back, 32, 502, 9, 2, 0x07E0u);
    12dc:	7e000793          	li	a5,2016
    12e0:	00200713          	li	a4,2
    12e4:	00900693          	li	a3,9
    12e8:	1f600613          	li	a2,502
    12ec:	02000593          	li	a1,32
    12f0:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    12f4:	404020ef          	jal	36f8 <cpu_fill32>
    bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 500u * FB_STRIDE + 33u * 2u)),
    12f8:	82c1a783          	lw	a5,-2004(gp) # 7924 <g_fb_back>
    12fc:	000ea737          	lui	a4,0xea
    1300:	64270713          	addi	a4,a4,1602 # ea642 <__freertos_irq_stack_top+0xa72a2>
    1304:	00e78733          	add	a4,a5,a4
    1308:	00075583          	lhu	a1,0(a4)
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 500u * FB_STRIDE + 40u * 2u)),
    130c:	000ea737          	lui	a4,0xea
    1310:	65070713          	addi	a4,a4,1616 # ea650 <__freertos_irq_stack_top+0xa72b0>
    1314:	00e78733          	add	a4,a5,a4
    1318:	00075603          	lhu	a2,0(a4)
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 502u * FB_STRIDE + 32u * 2u)),
    131c:	000eb737          	lui	a4,0xeb
    1320:	54070713          	addi	a4,a4,1344 # eb540 <__freertos_irq_stack_top+0xa81a0>
    1324:	00e78733          	add	a4,a5,a4
    1328:	00075683          	lhu	a3,0(a4)
               (unsigned)(*(volatile uint16_t *)(g_fb_back + 502u * FB_STRIDE + 40u * 2u)));
    132c:	000eb737          	lui	a4,0xeb
    1330:	55070713          	addi	a4,a4,1360 # eb550 <__freertos_irq_stack_top+0xa81b0>
    1334:	00e787b3          	add	a5,a5,a4
    1338:	0007d703          	lhu	a4,0(a5)
    bsp_printf("aligncheck %x %x %x %x (expect f800 f800 07e0 07e0)\r\n",
    133c:	00007537          	lui	a0,0x7
    1340:	c2c50513          	addi	a0,a0,-980 # 6c2c <_data+0xe2c>
    1344:	3ad030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x FB=%x DL=%x\r\n",
               (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG),
    1348:	7b5010ef          	jal	32fc <blt_stat>
    134c:	00050b13          	mv	s6,a0
    1350:	791010ef          	jal	32e0 <blt_cnt>
    1354:	00050b93          	mv	s7,a0
    1358:	02000513          	li	a0,32
    135c:	3fd010ef          	jal	2f58 <blt_rd>
    1360:	00050c13          	mv	s8,a0
               (unsigned)blt_rd(BLT_FB_STAT), (unsigned)blt_rd(BLT_DL_VERSION));
    1364:	02800513          	li	a0,40
    1368:	3f1010ef          	jal	2f58 <blt_rd>
    136c:	00050c93          	mv	s9,a0
    1370:	08000513          	li	a0,128
    1374:	3e5010ef          	jal	2f58 <blt_rd>
    1378:	00050793          	mv	a5,a0
    bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x FB=%x DL=%x\r\n",
    137c:	000c8713          	mv	a4,s9
    1380:	000c0693          	mv	a3,s8
    1384:	000b8613          	mv	a2,s7
    1388:	000b0593          	mv	a1,s6
    138c:	00007537          	lui	a0,0x7
    1390:	c6450513          	addi	a0,a0,-924 # 6c64 <_data+0xe64>
    1394:	35d030ef          	jal	4ef0 <bsp_printf>

    scene_init(n, g_seed, 0);
    1398:	00000613          	li	a2,0
    139c:	81c1a583          	lw	a1,-2020(gp) # 7914 <g_seed>
    13a0:	01900513          	li	a0,25
    13a4:	691020ef          	jal	4234 <scene_init>
    cache_evict();
    13a8:	635010ef          	jal	31dc <cache_evict>

    /* ★ 信息条开机就画好：先组串 → 落屏 → 再整屏上屏，这样**第一帧**顶上就有读数，
     *   而不是黑条空等一秒。t_now 同时作为 1Hz 统计窗口与场景时间基的起点。 */
    t_now    = tick32();
    13ac:	381010ef          	jal	2f2c <tick32>
    13b0:	00050c13          	mv	s8,a0
    13b4:	04a12423          	sw	a0,72(sp)
    t_scene  = t_now;
    g_osd_t0 = t_now;
    13b8:	8aa1a623          	sw	a0,-1876(gp) # 79a4 <g_osd_t0>
    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
    13bc:	8941a803          	lw	a6,-1900(gp) # 798c <g_dl_mode>
    13c0:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    13c4:	00000713          	li	a4,0
    13c8:	00100693          	li	a3,1
    13cc:	08000613          	li	a2,128
    13d0:	00000593          	li	a1,0
    13d4:	01900513          	li	a0,25
    13d8:	2e9020ef          	jal	3ec0 <osd_build>
    osd_blit(g_osd_line, path_label(path));
    13dc:	00200513          	li	a0,2
    13e0:	111020ef          	jal	3cf0 <path_label>
    13e4:	00050593          	mv	a1,a0
    13e8:	8e418513          	addi	a0,gp,-1820 # 79dc <g_osd_line>
    13ec:	449020ef          	jal	4034 <osd_blit>
    g_osd_dirty = 0;
    13f0:	8001ac23          	sw	zero,-2024(gp) # 7910 <g_osd_dirty>
#if FB_TRIPLE_BUFFER
    /* ★v2.7 三缓冲：显示 A / 画 B / 预清 C。
     *   另外两块（还没画过的那两块）在这里各铺一次底（只此一次），免得显示到 DDR 上电随机值。
     *   ★ 当前绘制的这块（g_fb_back = g_draw3）**不能**再铺一次 —— 上面 osd_blit 已经把
     *     信息条画进去了，再铺会把信息条擦掉。 */
    cpu_fill32(fb_of_sel((uint32_t)((g_draw3 + 1) % 3)), 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    13f4:	8281a503          	lw	a0,-2008(gp) # 7920 <g_draw3>
    13f8:	00150513          	addi	a0,a0,1
    13fc:	02956533          	rem	a0,a0,s1
    1400:	369010ef          	jal	2f68 <fb_of_sel>
    1404:	00800793          	li	a5,8
    1408:	21c00713          	li	a4,540
    140c:	3c000693          	li	a3,960
    1410:	00000613          	li	a2,0
    1414:	00000593          	li	a1,0
    1418:	2e0020ef          	jal	36f8 <cpu_fill32>
    cpu_fill32(fb_of_sel((uint32_t)((g_draw3 + 2) % 3)), 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    141c:	8281a503          	lw	a0,-2008(gp) # 7920 <g_draw3>
    1420:	00250513          	addi	a0,a0,2
    1424:	02956533          	rem	a0,a0,s1
    1428:	341010ef          	jal	2f68 <fb_of_sel>
    142c:	00800793          	li	a5,8
    1430:	21c00713          	li	a4,540
    1434:	3c000693          	li	a3,960
    1438:	00000613          	li	a2,0
    143c:	00000593          	li	a1,0
    1440:	2b8020ef          	jal	36f8 <cpu_fill32>
    g_bar_ok[0] = 0; g_bar_ok[1] = 0; g_bar_ok[2] = 0;
    1444:	8c018423          	sb	zero,-1848(gp) # 79c0 <g_bar_ok>
    1448:	8c818793          	addi	a5,gp,-1848 # 79c0 <g_bar_ok>
    144c:	000780a3          	sb	zero,1(a5)
    1450:	00078123          	sb	zero,2(a5)
    g_bar_ok[(uint32_t)g_draw3] = 1;      /* 信息条已经在"本趟要画的那块"里了 */
    1454:	8281a703          	lw	a4,-2008(gp) # 7920 <g_draw3>
    1458:	00f707b3          	add	a5,a4,a5
    145c:	01578023          	sb	s5,0(a5)
    g_flip_req = g_disp_sel;              /* 没有在途请求 */
    1460:	8d41a703          	lw	a4,-1836(gp) # 79cc <g_disp_sel>
    1464:	8ce1a823          	sw	a4,-1840(gp) # 79c8 <g_flip_req>
    cache_evict();
    1468:	575010ef          	jal	31dc <cache_evict>
    bsp_printf("publish: FLIPx3 (disp=%d draw=%d clr=%d, clear-engine on)\r\n",
    146c:	8241a683          	lw	a3,-2012(gp) # 791c <g_clr3>
    1470:	8281a603          	lw	a2,-2008(gp) # 7920 <g_draw3>
    1474:	8d41a583          	lw	a1,-1836(gp) # 79cc <g_disp_sel>
    1478:	00007537          	lui	a0,0x7
    147c:	c9850513          	addi	a0,a0,-872 # 6c98 <_data+0xe98>
    1480:	271030ef          	jal	4ef0 <bsp_printf>
    bsp_printf("publish: FLIP (no full-screen COPY; disp_sel=%d FB_SEL=0x%X FB_STAT=0x%X)\r\n",
               (int)g_disp_sel, (unsigned)BLT_FB_SEL, (unsigned)BLT_FB_STAT);
#endif
#if FB_IRQ_PACING
    /* ★v2.7 IRQ 帧节拍：开 FRAME 中断使能（0x14 bit1）。默认关 = 与改动前一致。 */
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);
    1484:	01400513          	li	a0,20
    1488:	2d1010ef          	jal	2f58 <blt_rd>
    148c:	00256593          	ori	a1,a0,2
    1490:	01400513          	li	a0,20
    1494:	2b5010ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);        /* 先清掉可能已有的挂起 */
    1498:	00200593          	li	a1,2
    149c:	01000513          	li	a0,16
    14a0:	2a9010ef          	jal	2f48 <blt_wr>
    bsp_printf("pacing: IRQ (frame-boundary IRQ_STATUS[1], IRQ_EN[1] on)\r\n");
    14a4:	00007537          	lui	a0,0x7
    14a8:	cd450513          	addi	a0,a0,-812 # 6cd4 <_data+0xed4>
    14ac:	245030ef          	jal	4ef0 <bsp_printf>
    uint32_t back_t0 = 0;
    14b0:	02012423          	sw	zero,40(sp)
    int hw_done = 0, cpu_done = 0, back_busy = 0;
    14b4:	00000413          	li	s0,0
    14b8:	02012023          	sw	zero,32(sp)
    14bc:	02012223          	sw	zero,36(sp)
    int size_repaint = 0;
    14c0:	04012823          	sw	zero,80(sp)
    int repaint_hw = 1, repaint_cpu = 1;
    14c4:	00100793          	li	a5,1
    14c8:	02f12623          	sw	a5,44(sp)
    14cc:	04f12223          	sw	a5,68(sp)
    int cpu_i = 0;
    14d0:	00000493          	li	s1,0
    int pend_adv = 0;                  /* 帧率模式下攒下的待推步数（慢时间片里结算） */
    14d4:	02012e23          	sw	zero,60(sp)
    int frame_adv = 0;                 /* ★ 't'：0=按墙钟时间推进  1=每发布一帧推进一步 */
    14d8:	00000d93          	li	s11,0
    int clear_pp = 1;                  /* ★ 'e' 默认 ON：每趟整片重铺背景（硬件侧） */
    14dc:	00100c93          	li	s9,1
    int hw_fifo_full = 0;              /* 上一圈 FIFO_COUNT 读满（纯硬件模式下据此低频轮询） */
    14e0:	04012623          	sw	zero,76(sp)
    int hw_i = 0, hw_frame_pushed = 0;
    14e4:	04012023          	sw	zero,64(sp)
    uint32_t hw_frames = 0, cpu_frames = 0, scr_frames = 0;
    14e8:	02012a23          	sw	zero,52(sp)
    14ec:	00012e23          	sw	zero,28(sp)
    14f0:	02012c23          	sw	zero,56(sp)
    uint32_t it = 0;
    14f4:	00000993          	li	s3,0
    unsigned alpha = 128u;
    14f8:	08000793          	li	a5,128
    14fc:	02f12823          	sw	a5,48(sp)
    int      n     = N_MIN;            /* ★ 默认 N=25 */
    1500:	01900a13          	li	s4,25
    int      scene = SC_FILL;
    1504:	00000d13          	li	s10,0
    int      path  = PATH_HW;          /* ★ 默认：纯硬件整屏 */
    1508:	00200913          	li	s2,2
    150c:	00912c23          	sw	s1,24(sp)
    1510:	4d80106f          	j	29e8 <main+0x18e4>
        /* ============ 慢时间片（每 32 圈）：UART + 时间 + 场景 + 1Hz 统计 ============
         * ★ 旧版这些工作全在"每圈"里做：1 次 UART 状态读 + 3 次 tick()（每次 3 个
         *   CLINT 寄存器读）= 10 次外设总线事务/圈，占空转期总线事务的绝大部分。
         *   收敛到 1/32 频率后：稳态平均每圈只多 0.03 次总线读。 */
        if ((it & SLOW_MASK) == 0u) {
            int c = uart_poll_char();
    1514:	3d5020ef          	jal	40e8 <uart_poll_char>
    1518:	00050b93          	mv	s7,a0
            t_now = tick32();
    151c:	211010ef          	jal	2f2c <tick32>
    1520:	00050c13          	mv	s8,a0

            /* ---------------- 串口命令（交互全部走这里） ---------------- */
            if (c) {
    1524:	080b9a63          	bnez	s7,15b8 <main+0x4b4>
            }

            /* ---------------- 场景推进：两种模式互斥 ----------------
             * 时间模式（默认）  ：按墙钟推进，40ms 一步 = 25 步/秒（与帧率无关）。
             * 帧率模式（'t'）   ：目标在"一帧被发布上屏之后"才前进一步 ⇒ 运动锁在帧率上。 */
            vrg.h = vrg_h(path);          /* 虚拟区域跟着路径变（单模式 = 整屏高） */
    1528:	00090513          	mv	a0,s2
    152c:	1b1030ef          	jal	4edc <vrg_h>
    1530:	06a12e23          	sw	a0,124(sp)
            if (!frame_adv) {
    1534:	4a0d9063          	bnez	s11,19d4 <main+0x8d0>
                pend_adv = 0;
                if ((uint32_t)(t_now - t_scene) >= (uint32_t)SCENE_TICKS) {
    1538:	04812783          	lw	a5,72(sp)
    153c:	40fc0733          	sub	a4,s8,a5
    1540:	003d17b7          	lui	a5,0x3d1
    1544:	8ff78793          	addi	a5,a5,-1793 # 3d08ff <__freertos_irq_stack_top+0x38d55f>
    1548:	44e7e463          	bltu	a5,a4,1990 <main+0x88c>
                pend_adv = 0;
    154c:	03b12e23          	sw	s11,60(sp)

            /* ---------------- 1Hz 帧率统计（值没变就不重画信息条） ----------------
             * 调用点先用**更便宜的内联判断**挡一道：没到点一个函数调用都不发。
             * ★ hw/cpu/scr 三个计数在这里**一起清零** ⇒ 三个数字共享同一个窗口，
             *   屏幕上 HW=/CPU=/SCR= 可以直接横向对比。 */
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    1550:	8ac1a703          	lw	a4,-1876(gp) # 79a4 <g_osd_t0>
    1554:	40ec0733          	sub	a4,s8,a4
    1558:	05f5e7b7          	lui	a5,0x5f5e
    155c:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f1ad5f>
    1560:	00e7e463          	bltu	a5,a4,1568 <main+0x464>
    1564:	4940106f          	j	29f8 <main+0x18f4>
                osd_service(t_now, hw_frames, cpu_frames, scr_frames,
    1568:	8941a783          	lw	a5,-1900(gp) # 798c <g_dl_mode>
    156c:	00f12423          	sw	a5,8(sp)
    1570:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    1574:	00f12223          	sw	a5,4(sp)
    1578:	01b12023          	sw	s11,0(sp)
    157c:	000c8893          	mv	a7,s9
    1580:	03012803          	lw	a6,48(sp)
    1584:	000d0793          	mv	a5,s10
    1588:	000a0713          	mv	a4,s4
    158c:	03412683          	lw	a3,52(sp)
    1590:	01c12603          	lw	a2,28(sp)
    1594:	03812583          	lw	a1,56(sp)
    1598:	000c0513          	mv	a0,s8
    159c:	191020ef          	jal	3f2c <osd_service>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    15a0:	00051463          	bnez	a0,15a8 <main+0x4a4>
    15a4:	4540106f          	j	29f8 <main+0x18f4>
                            n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode)) {
                hw_frames = 0; cpu_frames = 0; scr_frames = 0;
    15a8:	03512a23          	sw	s5,52(sp)
    15ac:	01512e23          	sw	s5,28(sp)
    15b0:	03512c23          	sw	s5,56(sp)
    15b4:	4440106f          	j	29f8 <main+0x18f4>
                int nl = nline_feed(c, &n_cmd);
    15b8:	08c10593          	addi	a1,sp,140
    15bc:	000b8513          	mv	a0,s7
    15c0:	35d020ef          	jal	411c <nline_feed>
    15c4:	00050b13          	mv	s6,a0
                if (nl == NL_OK) {
    15c8:	00200793          	li	a5,2
    15cc:	02f50a63          	beq	a0,a5,1600 <main+0x4fc>
                } else if (nl == NL_ERR) {
    15d0:	fff00793          	li	a5,-1
    15d4:	04f50663          	beq	a0,a5,1620 <main+0x51c>
                } else if (nl == NL_NONE) {
    15d8:	34051263          	bnez	a0,191c <main+0x818>
                    if (c == '1' || c == '2' || c == '3') {
    15dc:	fd5b8793          	addi	a5,s7,-43
    15e0:	04900713          	li	a4,73
    15e4:	36f76663          	bltu	a4,a5,1950 <main+0x84c>
    15e8:	00279793          	slli	a5,a5,0x2
    15ec:	00007737          	lui	a4,0x7
    15f0:	59070713          	addi	a4,a4,1424 # 7590 <_data+0x1790>
    15f4:	00e787b3          	add	a5,a5,a4
    15f8:	0007a783          	lw	a5,0(a5)
    15fc:	00078067          	jr	a5
                    n = n_cmd;               /* 已在 nline_feed 里钳到 [N_MIN, N_MAX] */
    1600:	08c12a03          	lw	s4,140(sp)
                    bsp_printf("\r\nEV N=%d\r\n", n);     /* 回显**实际生效**的值 */
    1604:	000a0593          	mv	a1,s4
    1608:	00007537          	lui	a0,0x7
    160c:	d1050513          	addi	a0,a0,-752 # 6d10 <_data+0xf10>
    1610:	0e1030ef          	jal	4ef0 <bsp_printf>
                    scene_change = 1; disp_change = 1;
    1614:	00100b93          	li	s7,1
    1618:	00100b13          	li	s6,1
    161c:	3080006f          	j	1924 <main+0x820>
                    bsp_printf("\r\nEV N=ERR\r\n");       /* 非数字 / 太长 / 空数字 */
    1620:	00007537          	lui	a0,0x7
    1624:	d1c50513          	addi	a0,a0,-740 # 6d1c <_data+0xf1c>
    1628:	0c9030ef          	jal	4ef0 <bsp_printf>
                int disp_change  = 0;    /* 显示内容变了才重画信息条（事件驱动） */
    162c:	00000b93          	li	s7,0
                int scene_change = 0;
    1630:	00000b13          	li	s6,0
    1634:	2f00006f          	j	1924 <main+0x820>
                        scene = (c == '1') ? SC_FILL : ((c == '2') ? SC_ALPHA : SC_KEY);
    1638:	03100793          	li	a5,49
    163c:	00fb8863          	beq	s7,a5,164c <main+0x548>
    1640:	03200793          	li	a5,50
    1644:	02fb8463          	beq	s7,a5,166c <main+0x568>
    1648:	00200b13          	li	s6,2
                        bsp_printf("\r\nEV scene=%d (0=FILL 1=ALPHA 2=KEY)\r\n", scene);
    164c:	000b0593          	mv	a1,s6
    1650:	00007537          	lui	a0,0x7
    1654:	d2c50513          	addi	a0,a0,-724 # 6d2c <_data+0xf2c>
    1658:	099030ef          	jal	4ef0 <bsp_printf>
                        scene = (c == '1') ? SC_FILL : ((c == '2') ? SC_ALPHA : SC_KEY);
    165c:	000b0d13          	mv	s10,s6
                        scene_change = 1; disp_change = 1;
    1660:	00100b93          	li	s7,1
    1664:	00100b13          	li	s6,1
    1668:	2bc0006f          	j	1924 <main+0x820>
                        scene = (c == '1') ? SC_FILL : ((c == '2') ? SC_ALPHA : SC_KEY);
    166c:	00100b13          	li	s6,1
    1670:	fddff06f          	j	164c <main+0x548>
                        disp_change = 1; bsp_printf("\r\nEV path=0 SPLIT\r\n"); }
    1674:	00007537          	lui	a0,0x7
    1678:	d5450513          	addi	a0,a0,-684 # 6d54 <_data+0xf54>
    167c:	075030ef          	jal	4ef0 <bsp_printf>
                    } else if (c == 's' || c == 'S') { path = PATH_SPLIT; repaint_hw = repaint_cpu = 1;
    1680:	000b0913          	mv	s2,s6
                        disp_change = 1; bsp_printf("\r\nEV path=0 SPLIT\r\n"); }
    1684:	00100b93          	li	s7,1
                    } else if (c == 's' || c == 'S') { path = PATH_SPLIT; repaint_hw = repaint_cpu = 1;
    1688:	00100793          	li	a5,1
    168c:	02f12623          	sw	a5,44(sp)
    1690:	04f12223          	sw	a5,68(sp)
                        disp_change = 1; bsp_printf("\r\nEV path=0 SPLIT\r\n"); }
    1694:	2900006f          	j	1924 <main+0x820>
                        disp_change = 1; bsp_printf("\r\nEV path=1 CPU only\r\n"); }
    1698:	00007537          	lui	a0,0x7
    169c:	d6850513          	addi	a0,a0,-664 # 6d68 <_data+0xf68>
    16a0:	051030ef          	jal	4ef0 <bsp_printf>
    16a4:	00100b93          	li	s7,1
                    else if (c == 'c' || c == 'C')   { path = PATH_CPU;   repaint_hw = repaint_cpu = 1;
    16a8:	00100793          	li	a5,1
    16ac:	02f12623          	sw	a5,44(sp)
    16b0:	04f12223          	sw	a5,68(sp)
    16b4:	00100913          	li	s2,1
                        disp_change = 1; bsp_printf("\r\nEV path=1 CPU only\r\n"); }
    16b8:	26c0006f          	j	1924 <main+0x820>
                        disp_change = 1; bsp_printf("\r\nEV path=2 HW only\r\n"); }
    16bc:	00007537          	lui	a0,0x7
    16c0:	d8050513          	addi	a0,a0,-640 # 6d80 <_data+0xf80>
    16c4:	02d030ef          	jal	4ef0 <bsp_printf>
    16c8:	00100b93          	li	s7,1
                    else if (c == 'h' || c == 'H')   { path = PATH_HW;    repaint_hw = repaint_cpu = 1;
    16cc:	00100793          	li	a5,1
    16d0:	02f12623          	sw	a5,44(sp)
    16d4:	04f12223          	sw	a5,68(sp)
    16d8:	00200913          	li	s2,2
                        disp_change = 1; bsp_printf("\r\nEV path=2 HW only\r\n"); }
    16dc:	2480006f          	j	1924 <main+0x820>
                        n += N_STEP; if (n > N_MAX) n = N_MIN; scene_change = 1; disp_change = 1;
    16e0:	019a0a13          	addi	s4,s4,25
    16e4:	000017b7          	lui	a5,0x1
    16e8:	77078793          	addi	a5,a5,1904 # 1770 <main+0x66c>
    16ec:	0147d463          	bge	a5,s4,16f4 <main+0x5f0>
    16f0:	01900a13          	li	s4,25
                        bsp_printf("\r\nEV N=%d\r\n", n); }
    16f4:	000a0593          	mv	a1,s4
    16f8:	00007537          	lui	a0,0x7
    16fc:	d1050513          	addi	a0,a0,-752 # 6d10 <_data+0xf10>
    1700:	7f0030ef          	jal	4ef0 <bsp_printf>
                        n += N_STEP; if (n > N_MAX) n = N_MIN; scene_change = 1; disp_change = 1;
    1704:	00100b93          	li	s7,1
    1708:	00100b13          	li	s6,1
                        bsp_printf("\r\nEV N=%d\r\n", n); }
    170c:	2180006f          	j	1924 <main+0x820>
                        n -= N_STEP; if (n < N_MIN) n = N_MAX; scene_change = 1; disp_change = 1;
    1710:	fe7a0a13          	addi	s4,s4,-25
    1714:	01800793          	li	a5,24
    1718:	0147c663          	blt	a5,s4,1724 <main+0x620>
    171c:	00001a37          	lui	s4,0x1
    1720:	770a0a13          	addi	s4,s4,1904 # 1770 <main+0x66c>
                        bsp_printf("\r\nEV N=%d\r\n", n); }
    1724:	000a0593          	mv	a1,s4
    1728:	00007537          	lui	a0,0x7
    172c:	d1050513          	addi	a0,a0,-752 # 6d10 <_data+0xf10>
    1730:	7c0030ef          	jal	4ef0 <bsp_printf>
                        n -= N_STEP; if (n < N_MIN) n = N_MAX; scene_change = 1; disp_change = 1;
    1734:	00100b93          	li	s7,1
    1738:	00100b13          	li	s6,1
    173c:	1e80006f          	j	1924 <main+0x820>
                    else if (c == 'e' || c == 'E') { clear_pp = !clear_pp;
    1740:	001ccb93          	xori	s7,s9,1
                        if (!clear_pp) repaint_hw = 1;   /* 立即重铺一次，切模式后状态一致 */
    1744:	000c8663          	beqz	s9,1750 <main+0x64c>
    1748:	00100793          	li	a5,1
    174c:	04f12223          	sw	a5,68(sp)
                        bsp_printf("\r\nEV clear_per_pass=%d (1=every pass refills the HW region)\r\n", clear_pp); }
    1750:	000b8593          	mv	a1,s7
    1754:	00007537          	lui	a0,0x7
    1758:	d9850513          	addi	a0,a0,-616 # 6d98 <_data+0xf98>
    175c:	794030ef          	jal	4ef0 <bsp_printf>
                    else if (c == 'e' || c == 'E') { clear_pp = !clear_pp;
    1760:	000b8c93          	mv	s9,s7
                        disp_change = 1;
    1764:	00100b93          	li	s7,1
                        bsp_printf("\r\nEV clear_per_pass=%d (1=every pass refills the HW region)\r\n", clear_pp); }
    1768:	1bc0006f          	j	1924 <main+0x820>
                    else if (c == 't' || c == 'T') { frame_adv = !frame_adv;
    176c:	001dcd93          	xori	s11,s11,1
                        bsp_printf("\r\nEV advance=%d (0=time 25 step/s, 1=one step per published frame)\r\n",
    1770:	000d8593          	mv	a1,s11
    1774:	00007537          	lui	a0,0x7
    1778:	dd850513          	addi	a0,a0,-552 # 6dd8 <_data+0xfd8>
    177c:	774030ef          	jal	4ef0 <bsp_printf>
                        t_scene = t_now;                 /* 切回时间模式时别攒出一大跳 */
    1780:	05812423          	sw	s8,72(sp)
                        disp_change = 1;
    1784:	00100b93          	li	s7,1
                        bsp_printf("\r\nEV advance=%d (0=time 25 step/s, 1=one step per published frame)\r\n",
    1788:	19c0006f          	j	1924 <main+0x820>
                        g_blk = blk_next(g_blk);
    178c:	8201a503          	lw	a0,-2016(gp) # 7918 <g_blk>
    1790:	764010ef          	jal	2ef4 <blk_next>
    1794:	82a1a023          	sw	a0,-2016(gp) # 7918 <g_blk>
                        build_atlas();
    1798:	6c9010ef          	jal	3660 <build_atlas>
                        spr_mask_report();        /* ★S3：掩码跟着图集一起换（同一个函数里算的） */
    179c:	085030ef          	jal	5020 <spr_mask_report>
                        bsp_printf("\r\nEV size=%d\r\n", g_blk); }
    17a0:	8201a583          	lw	a1,-2016(gp) # 7918 <g_blk>
    17a4:	00007537          	lui	a0,0x7
    17a8:	e2050513          	addi	a0,a0,-480 # 6e20 <_data+0x1020>
    17ac:	744030ef          	jal	4ef0 <bsp_printf>
                        scene_change = 1; disp_change = 1;
    17b0:	00100b93          	li	s7,1
    17b4:	00100b13          	li	s6,1
                        size_repaint = SIZE_REPAINT_ROUNDS;   /* 另外两块缓冲补铺（见声明处） */
    17b8:	00200793          	li	a5,2
    17bc:	04f12823          	sw	a5,80(sp)
                        bsp_printf("\r\nEV size=%d\r\n", g_blk); }
    17c0:	1640006f          	j	1924 <main+0x820>
                    else if (c == 'a') { if (alpha >= 32u)  alpha -= 32u;
    17c4:	01f00793          	li	a5,31
    17c8:	03012703          	lw	a4,48(sp)
    17cc:	00e7f663          	bgeu	a5,a4,17d8 <main+0x6d4>
    17d0:	fe070793          	addi	a5,a4,-32
    17d4:	02f12823          	sw	a5,48(sp)
                        disp_change = 1; bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
    17d8:	03012583          	lw	a1,48(sp)
    17dc:	00007537          	lui	a0,0x7
    17e0:	e3050513          	addi	a0,a0,-464 # 6e30 <_data+0x1030>
    17e4:	70c030ef          	jal	4ef0 <bsp_printf>
    17e8:	00100b93          	li	s7,1
    17ec:	1380006f          	j	1924 <main+0x820>
                    else if (c == 'A') { if (alpha <= 223u) alpha += 32u;
    17f0:	0df00793          	li	a5,223
    17f4:	03012703          	lw	a4,48(sp)
    17f8:	00e7e663          	bltu	a5,a4,1804 <main+0x700>
    17fc:	02070793          	addi	a5,a4,32
    1800:	02f12823          	sw	a5,48(sp)
                        disp_change = 1; bsp_printf("\r\nEV alpha=%d\r\n", (int)alpha); }
    1804:	03012583          	lw	a1,48(sp)
    1808:	00007537          	lui	a0,0x7
    180c:	e3050513          	addi	a0,a0,-464 # 6e30 <_data+0x1030>
    1810:	6e0030ef          	jal	4ef0 <bsp_printf>
    1814:	00100b93          	li	s7,1
    1818:	10c0006f          	j	1924 <main+0x820>
                    else if (c == 'r' || c == 'R') { scene_change = 1; g_seed += 0x9E3779B9u;
    181c:	81c1a783          	lw	a5,-2020(gp) # 7914 <g_seed>
    1820:	9e378737          	lui	a4,0x9e378
    1824:	9b970713          	addi	a4,a4,-1607 # 9e3779b9 <__freertos_irq_stack_top+0x9e334619>
    1828:	00e787b3          	add	a5,a5,a4
    182c:	80f1ae23          	sw	a5,-2020(gp) # 7914 <g_seed>
                        bsp_printf("\r\nEV reset\r\n"); }
    1830:	00007537          	lui	a0,0x7
    1834:	e4050513          	addi	a0,a0,-448 # 6e40 <_data+0x1040>
    1838:	6b8030ef          	jal	4ef0 <bsp_printf>
                int disp_change  = 0;    /* 显示内容变了才重画信息条（事件驱动） */
    183c:	000b0b93          	mv	s7,s6
                    else if (c == 'r' || c == 'R') { scene_change = 1; g_seed += 0x9E3779B9u;
    1840:	00100b13          	li	s6,1
                        bsp_printf("\r\nEV reset\r\n"); }
    1844:	0e00006f          	j	1924 <main+0x820>
                        int want = (g_dl_want >= 0) ? g_dl_want : g_dl_mode;
    1848:	8101a783          	lw	a5,-2032(gp) # 7908 <g_dl_want>
    184c:	00078493          	mv	s1,a5
    1850:	0407c263          	bltz	a5,1894 <main+0x790>
                        int next = !want;
    1854:	0014b713          	seqz	a4,s1
    1858:	04e12a23          	sw	a4,84(sp)
                        if (next && !dl_supported()) {
    185c:	04048263          	beqz	s1,18a0 <main+0x79c>
                        } else if (next == g_dl_mode) {
    1860:	8941a783          	lw	a5,-1900(gp) # 798c <g_dl_mode>
    1864:	05412703          	lw	a4,84(sp)
    1868:	04e78663          	beq	a5,a4,18b4 <main+0x7b0>
                            g_dl_want = next;
    186c:	05412703          	lw	a4,84(sp)
    1870:	80e1a823          	sw	a4,-2032(gp) # 7908 <g_dl_want>
                            bsp_printf("\r\nEV dl %s pending (takes effect at the next frame boundary)\r\n",
    1874:	06049a63          	bnez	s1,18e8 <main+0x7e4>
    1878:	000065b7          	lui	a1,0x6
    187c:	0d058593          	addi	a1,a1,208 # 60d0 <_data+0x2d0>
    1880:	00007537          	lui	a0,0x7
    1884:	e7050513          	addi	a0,a0,-400 # 6e70 <_data+0x1070>
    1888:	668030ef          	jal	4ef0 <bsp_printf>
                int disp_change  = 0;    /* 显示内容变了才重画信息条（事件驱动） */
    188c:	000b0b93          	mv	s7,s6
    1890:	0940006f          	j	1924 <main+0x820>
                        int want = (g_dl_want >= 0) ? g_dl_want : g_dl_mode;
    1894:	8941a783          	lw	a5,-1900(gp) # 798c <g_dl_mode>
    1898:	00078493          	mv	s1,a5
    189c:	fb9ff06f          	j	1854 <main+0x750>
                        if (next && !dl_supported()) {
    18a0:	7d0030ef          	jal	5070 <dl_supported>
    18a4:	00050b93          	mv	s7,a0
    18a8:	fa051ce3          	bnez	a0,1860 <main+0x75c>
                int scene_change = 0;
    18ac:	00050b13          	mv	s6,a0
    18b0:	0740006f          	j	1924 <main+0x820>
                            g_dl_want = -1;                  /* 又按回来了 ⇒ 撤销待生效请求 */
    18b4:	fff00693          	li	a3,-1
    18b8:	80d1a823          	sw	a3,-2032(gp) # 7908 <g_dl_want>
                            bsp_printf("\r\nEV dl %s pending cancelled\r\n",
    18bc:	02078063          	beqz	a5,18dc <main+0x7d8>
    18c0:	000065b7          	lui	a1,0x6
    18c4:	0d058593          	addi	a1,a1,208 # 60d0 <_data+0x2d0>
    18c8:	00007537          	lui	a0,0x7
    18cc:	e5050513          	addi	a0,a0,-432 # 6e50 <_data+0x1050>
    18d0:	620030ef          	jal	4ef0 <bsp_printf>
                int disp_change  = 0;    /* 显示内容变了才重画信息条（事件驱动） */
    18d4:	000b0b93          	mv	s7,s6
    18d8:	04c0006f          	j	1924 <main+0x820>
                            bsp_printf("\r\nEV dl %s pending cancelled\r\n",
    18dc:	000065b7          	lui	a1,0x6
    18e0:	0d458593          	addi	a1,a1,212 # 60d4 <_data+0x2d4>
    18e4:	fe5ff06f          	j	18c8 <main+0x7c4>
                            bsp_printf("\r\nEV dl %s pending (takes effect at the next frame boundary)\r\n",
    18e8:	000065b7          	lui	a1,0x6
    18ec:	0d458593          	addi	a1,a1,212 # 60d4 <_data+0x2d4>
    18f0:	f91ff06f          	j	1880 <main+0x77c>
                        bsp_printf("\r\ncmd: 1/2/3=scene FILL/ALPHA/KEY   s/c/h=path SPLIT/CPU/HW\r\n"
    18f4:	00001737          	lui	a4,0x1
    18f8:	77070713          	addi	a4,a4,1904 # 1770 <main+0x66c>
    18fc:	01900693          	li	a3,25
    1900:	01900613          	li	a2,25
    1904:	01900593          	li	a1,25
    1908:	00007537          	lui	a0,0x7
    190c:	eb050513          	addi	a0,a0,-336 # 6eb0 <_data+0x10b0>
    1910:	5e0030ef          	jal	4ef0 <bsp_printf>
                int disp_change  = 0;    /* 显示内容变了才重画信息条（事件驱动） */
    1914:	000b0b93          	mv	s7,s6
    1918:	00c0006f          	j	1924 <main+0x820>
    191c:	00000b93          	li	s7,0
                int scene_change = 0;
    1920:	00000b13          	li	s6,0
                if (scene_change) {
    1924:	020b1a63          	bnez	s6,1958 <main+0x854>
                if (disp_change)
    1928:	c00b80e3          	beqz	s7,1528 <main+0x424>
                    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
    192c:	8941a803          	lw	a6,-1900(gp) # 798c <g_dl_mode>
    1930:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    1934:	000d8713          	mv	a4,s11
    1938:	000c8693          	mv	a3,s9
    193c:	03012603          	lw	a2,48(sp)
    1940:	000d0593          	mv	a1,s10
    1944:	000a0513          	mv	a0,s4
    1948:	578020ef          	jal	3ec0 <osd_build>
    194c:	bddff06f          	j	1528 <main+0x424>
                } else if (nl == NL_NONE) {
    1950:	000b0b93          	mv	s7,s6
    1954:	fd1ff06f          	j	1924 <main+0x820>
                    scene_init(n, g_seed, (scene == SC_FILL) ? 0 : 1);
    1958:	01a03633          	snez	a2,s10
    195c:	81c1a583          	lw	a1,-2020(gp) # 7914 <g_seed>
    1960:	000a0513          	mv	a0,s4
    1964:	0d1020ef          	jal	4234 <scene_init>
                    hw_i = 0; hw_frame_pushed = 0; cpu_i = 0; pend_adv = 0;
    1968:	08012423          	sw	zero,136(sp)
                    snap_hw = snap_cpu = 0;   /* scene_init 已把 tx,ty 对齐到 x,y */
    196c:	08012023          	sw	zero,128(sp)
    1970:	08012223          	sw	zero,132(sp)
                    repaint_hw = repaint_cpu = 1;
    1974:	03612623          	sw	s6,44(sp)
    1978:	05612223          	sw	s6,68(sp)
                    hw_i = 0; hw_frame_pushed = 0; cpu_i = 0; pend_adv = 0;
    197c:	00012c23          	sw	zero,24(sp)
    1980:	02012e23          	sw	zero,60(sp)
                    hw_fifo_full = 0;
    1984:	04012623          	sw	zero,76(sp)
                    hw_i = 0; hw_frame_pushed = 0; cpu_i = 0; pend_adv = 0;
    1988:	04012023          	sw	zero,64(sp)
    198c:	f9dff06f          	j	1928 <main+0x824>
                    int steps = 0;
    1990:	000d8b13          	mv	s6,s11
                    do { scene_step_both(n, &vrg, &snap_hw, &snap_cpu); steps++; }
    1994:	08010693          	addi	a3,sp,128
    1998:	08410613          	addi	a2,sp,132
    199c:	07010593          	addi	a1,sp,112
    19a0:	000a0513          	mv	a0,s4
    19a4:	451020ef          	jal	45f4 <scene_step_both>
    19a8:	001b0b13          	addi	s6,s6,1
                    while ((uint32_t)(tick32() - t_scene) >= (uint32_t)SCENE_TICKS &&
    19ac:	580010ef          	jal	2f2c <tick32>
    19b0:	41850533          	sub	a0,a0,s8
    19b4:	003d17b7          	lui	a5,0x3d1
    19b8:	8ff78793          	addi	a5,a5,-1793 # 3d08ff <__freertos_irq_stack_top+0x38d55f>
    19bc:	04a7f063          	bgeu	a5,a0,19fc <main+0x8f8>
    19c0:	00700793          	li	a5,7
    19c4:	fd67d8e3          	bge	a5,s6,1994 <main+0x890>
                pend_adv = 0;
    19c8:	03b12e23          	sw	s11,60(sp)
                    t_scene = t_now;
    19cc:	05812423          	sw	s8,72(sp)
    19d0:	b81ff06f          	j	1550 <main+0x44c>
            } else if (pend_adv > 0) {
    19d4:	03c12483          	lw	s1,60(sp)
    19d8:	b6905ce3          	blez	s1,1550 <main+0x44c>
                scene_step_both(n, &vrg, &snap_hw, &snap_cpu);
    19dc:	08010693          	addi	a3,sp,128
    19e0:	08410613          	addi	a2,sp,132
    19e4:	07010593          	addi	a1,sp,112
    19e8:	000a0513          	mv	a0,s4
    19ec:	409020ef          	jal	45f4 <scene_step_both>
                pend_adv--;
    19f0:	fff48793          	addi	a5,s1,-1
    19f4:	02f12e23          	sw	a5,60(sp)
    19f8:	b59ff06f          	j	1550 <main+0x44c>
                pend_adv = 0;
    19fc:	03b12e23          	sw	s11,60(sp)
                    t_scene = t_now;
    1a00:	05812423          	sw	s8,72(sp)
    1a04:	b4dff06f          	j	1550 <main+0x44c>
             * 2) 到点的 1Hz 统计/组串也在这个窗口里做（osd_service 自带门控，
             *    慢时间片里那次调用会直接返回，不会重复算；调用点还先用内联判断
             *    挡一道，没到点连函数调用都不发）。
             * 3) 有界退避 + 低频轮询：每 4 圈才读一次 BLT_STATUS，其余圈纯 ALU 空转，
             *    **一个外设寄存器都不碰**（旧版这里每圈 1 次状态 + 3 次 CLINT 读）。 */
            if (snap_hw)  { scene_snap(g_sc[SIDE_HW],  n); snap_hw  = 0; }
    1a08:	000a0593          	mv	a1,s4
    1a0c:	00008537          	lui	a0,0x8
    1a10:	a2050513          	addi	a0,a0,-1504 # 7a20 <g_sc>
    1a14:	2dd020ef          	jal	44f0 <scene_snap>
    1a18:	08012223          	sw	zero,132(sp)
    1a1c:	7f10006f          	j	2a0c <main+0x1908>
            if (snap_cpu) { scene_snap(g_sc[SIDE_CPU], n); snap_cpu = 0; }
    1a20:	000a0593          	mv	a1,s4
    1a24:	00025537          	lui	a0,0x25
    1a28:	ee050513          	addi	a0,a0,-288 # 24ee0 <__global_pointer$+0x1cde8>
    1a2c:	2c5020ef          	jal	44f0 <scene_snap>
    1a30:	08012023          	sw	zero,128(sp)
    1a34:	7e50006f          	j	2a18 <main+0x1914>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
                osd_service(t_now, hw_frames, cpu_frames, scr_frames,
    1a38:	8941a783          	lw	a5,-1900(gp) # 798c <g_dl_mode>
    1a3c:	00f12423          	sw	a5,8(sp)
    1a40:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    1a44:	00f12223          	sw	a5,4(sp)
    1a48:	01b12023          	sw	s11,0(sp)
    1a4c:	000c8893          	mv	a7,s9
    1a50:	03012803          	lw	a6,48(sp)
    1a54:	000d0793          	mv	a5,s10
    1a58:	000a0713          	mv	a4,s4
    1a5c:	03412683          	lw	a3,52(sp)
    1a60:	01c12603          	lw	a2,28(sp)
    1a64:	03812583          	lw	a1,56(sp)
    1a68:	000c0513          	mv	a0,s8
    1a6c:	4c0020ef          	jal	3f2c <osd_service>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    1a70:	00051463          	bnez	a0,1a78 <main+0x974>
    1a74:	7bd0006f          	j	2a30 <main+0x192c>
                            n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode)) {
                hw_frames = 0; cpu_frames = 0; scr_frames = 0;
    1a78:	02012a23          	sw	zero,52(sp)
    1a7c:	00012e23          	sw	zero,28(sp)
    1a80:	02012c23          	sw	zero,56(sp)
    1a84:	7ad0006f          	j	2a30 <main+0x192c>
                    back_busy  = 0;
#if FB_TRIPLE_BUFFER
                    /* ★v2.7 三缓冲轮转：刚画完的这块上屏了，接下来
                     *   画 = 之前预清好的那块，清 = 刚腾出来的旧显示缓冲。 */
                    {
                        int old_disp = (int)g_disp_sel;
    1a88:	8d41a683          	lw	a3,-1836(gp) # 79cc <g_disp_sel>
                        g_disp_sel   = g_flip_req;
    1a8c:	8cf1aa23          	sw	a5,-1836(gp) # 79cc <g_disp_sel>
                        g_draw3      = g_clr3;
    1a90:	8241a503          	lw	a0,-2012(gp) # 791c <g_clr3>
    1a94:	82a1a423          	sw	a0,-2008(gp) # 7920 <g_draw3>
                        g_clr3       = old_disp;
    1a98:	82d1a223          	sw	a3,-2012(gp) # 791c <g_clr3>
                        g_clr_need   = 1;          /* 下一趟开始时给清屏引擎下新命令 */
    1a9c:	00100713          	li	a4,1
    1aa0:	8ce1a223          	sw	a4,-1852(gp) # 79bc <g_clr_need>
                        g_pass_armed = 0;
    1aa4:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
                        g_fb_back    = fb_of_sel((uint32_t)g_draw3);
    1aa8:	4c0010ef          	jal	2f68 <fb_of_sel>
    1aac:	82a1a623          	sw	a0,-2004(gp) # 7924 <g_fb_back>
                    }
#else
                    g_disp_sel = g_flip_req;
                    g_fb_back  = fb_of_sel(g_disp_sel ^ 1u);   /* 新的后台缓冲 */
#endif
                    scr_frames++;                              /* 这一帧真的上屏了 */
    1ab0:	03412783          	lw	a5,52(sp)
    1ab4:	00178793          	addi	a5,a5,1
    1ab8:	02f12a23          	sw	a5,52(sp)
                    if (frame_adv && pend_adv < MAX_STEPS) pend_adv++;
    1abc:	000d8c63          	beqz	s11,1ad4 <main+0x9d0>
    1ac0:	00700793          	li	a5,7
    1ac4:	03c12703          	lw	a4,60(sp)
    1ac8:	00e7c663          	blt	a5,a4,1ad4 <main+0x9d0>
    1acc:	00170793          	addi	a5,a4,1
    1ad0:	02f12e23          	sw	a5,60(sp)
                    /* 新后台缓冲里是**两帧前**的内容：clear_pp 关掉时要整片重铺一次，
                     * 否则这一轮没动的物块会留着上一轮的残影（clear_pp=1 每趟本来就重铺）。
                     * ★ 刚切过方块尺寸（size_repaint>0）时同样补铺：轮转到的这块里还是
                     *   **旧尺寸**的方块，不盖掉就会和新尺寸的混在同一帧里（见 'k' 命令
                     *   与 SIZE_REPAINT_ROUNDS）。补铺只加"重铺请求"，发布协议未改。 */
                    if (!clear_pp || size_repaint > 0) {
    1ad4:	040c8a63          	beqz	s9,1b28 <main+0xa24>
    1ad8:	05012783          	lw	a5,80(sp)
    1adc:	00f05c63          	blez	a5,1af4 <main+0x9f0>
                        repaint_hw = 1; repaint_cpu = 1;
                        if (size_repaint > 0) size_repaint--;
    1ae0:	05012783          	lw	a5,80(sp)
    1ae4:	fff78793          	addi	a5,a5,-1
    1ae8:	04f12823          	sw	a5,80(sp)
                        repaint_hw = 1; repaint_cpu = 1;
    1aec:	02812623          	sw	s0,44(sp)
    1af0:	04812223          	sw	s0,68(sp)
                    /* ★v2.13：'l' 的待生效切换就在**这一刻**落地 —— 这里正是"帧发布边界"：
                     *   本帧已经上屏（FB_STAT 确认翻转生效）、本帧那张表已被 DFU 消费完、
                     *   引擎的像素也已写提交，而下一趟从 hw_i==0 重新开始
                     *   ⇒ 不会切在一张表中间，也不会在同一帧里混用两条路径
                     *   （内部还有"确实没有表在飞"的保险，见 dl_apply_pending()）。 */
                    if (dl_apply_pending())
    1af4:	5c0030ef          	jal	50b4 <dl_apply_pending>
    1af8:	00050413          	mv	s0,a0
    1afc:	06050863          	beqz	a0,1b6c <main+0xa68>
                        osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
    1b00:	8941a803          	lw	a6,-1900(gp) # 798c <g_dl_mode>
    1b04:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    1b08:	000d8713          	mv	a4,s11
    1b0c:	000c8693          	mv	a3,s9
    1b10:	03012603          	lw	a2,48(sp)
    1b14:	000d0593          	mv	a1,s10
    1b18:	000a0513          	mv	a0,s4
    1b1c:	3a4020ef          	jal	3ec0 <osd_build>
                    back_busy  = 0;
    1b20:	00000413          	li	s0,0
    1b24:	0480006f          	j	1b6c <main+0xa68>
                        if (size_repaint > 0) size_repaint--;
    1b28:	05012783          	lw	a5,80(sp)
    1b2c:	faf04ae3          	bgtz	a5,1ae0 <main+0x9dc>
                        repaint_hw = 1; repaint_cpu = 1;
    1b30:	02812623          	sw	s0,44(sp)
    1b34:	04812223          	sw	s0,68(sp)
    1b38:	fbdff06f          	j	1af4 <main+0x9f0>
                } else if ((uint32_t)(tick32() - back_t0) > (uint32_t)FLIP_TIMEOUT_TICKS) {
                    g_flip_to++;
                    if (g_flip_to == 1u)
                        bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
                                   (unsigned)blt_rd(BLT_FB_STAT));
    1b3c:	02800513          	li	a0,40
    1b40:	418010ef          	jal	2f58 <blt_rd>
    1b44:	00050593          	mv	a1,a0
                        bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
    1b48:	00007537          	lui	a0,0x7
    1b4c:	1b850513          	addi	a0,a0,440 # 71b8 <_data+0x13b8>
    1b50:	3a0030ef          	jal	4ef0 <bsp_printf>
    1b54:	7490006f          	j	2a9c <main+0x1998>
                    blt_wr(BLT_FB_SEL, g_flip_req);       /* 重发请求，继续有界等待 */
                    back_t0 = tick32();
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
    1b58:	03000513          	li	a0,48
    1b5c:	3dc010ef          	jal	2f38 <cpu_backoff>
    1b60:	00c0006f          	j	1b6c <main+0xa68>
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
                }
#endif
            } else {
                cpu_backoff(BLT_WAIT_NOP);
    1b64:	03000513          	li	a0,48
    1b68:	3d0010ef          	jal	2f38 <cpu_backoff>
        /* ---------------- 硬件侧：每趟"整片重铺 + 画全部块"，位置用本趟快照 ----------------
         * 全部画在后台缓冲里；屏幕看到的是上面那条整帧 COPY。
         * ★ clear_pp=1（默认）：本趟先 FILL 整片渲染区为背景色，再画 N 块，
         *   **不发任何逐块擦除指令** —— 上板验证：黑拖尾与 KEY 四角闪烁都消失。
         * ★ clear_pp=0：退回 comptest2 的"逐块擦旧矩形再画"（留给板上 A/B 对比）。 */
        if (!back_busy && path != PATH_CPU) {
    1b6c:	4c0418e3          	bnez	s0,283c <main+0x1738>
    1b70:	00100793          	li	a5,1
    1b74:	4cf904e3          	beq	s2,a5,283c <main+0x1738>
             * ★ 完成判据只用 DL_STATUS（本模式不再轮询逐条状态/FIFO_COUNT）。 */
            /* ★ 出错后的交接必须排在 g_dl_mode 判断**之前**：出错时列表路径可能已经被
             *   停用（dl_disable），也可能还开着等**看门狗自动重试**（v2.14）—— 两种情况下
             *   DFU 都可能还在把已展开的命令跑完，必须等它落 BUSY 才能安全地重新 arm 或
             *   交回逐条路径（硬件在 S_PUSH 期间会压住 CPU 对 0x08 的写口）。 */
            if (g_dl_fbwait) {
    1b78:	87c1aa83          	lw	s5,-1924(gp) # 7974 <g_dl_fbwait>
    1b7c:	1a0a8263          	beqz	s5,1d20 <main+0xc1c>
                int poll = ((path != PATH_HW) || ((it & BLT_WAIT_MASK) == 0u)) ? 1 : 0;
    1b80:	00200793          	li	a5,2
    1b84:	00f91663          	bne	s2,a5,1b90 <main+0xa8c>
    1b88:	0039f793          	andi	a5,s3,3
    1b8c:	0e079863          	bnez	a5,1c7c <main+0xb78>
                if (poll) {
                    uint32_t fst  = blt_rd(BLT_DL_STATUS);
    1b90:	05c00513          	li	a0,92
    1b94:	3c4010ef          	jal	2f58 <blt_rd>
    1b98:	00050a93          	mv	s5,a0
                    int      idle = ((fst & DL_ST_BUSY) == 0u);
    1b9c:	00157b13          	andi	s6,a0,1
                    if (idle || ((uint32_t)(tick32() - g_dl_ft0) > (uint32_t)DL_FBWAIT_TICKS)) {
    1ba0:	0e0b1463          	bnez	s6,1c88 <main+0xb84>
                        /* ★v2.14 post-mortem：只有**真的等到 BUSY=0** 才有意义 —— 此时
                         *   S_ERR/S_END 已经走完、perf_r 刚被写入（dl_fetch.v:643-663），
                         *   所以这一行的 perf= 才是**这张出错表**的真实周期数（GO→出错→引擎收尾），
                         *   拿它和 tmo= 一比就知道"离超时差多远"。20ms 上界到点但 DFU 还 BUSY 时
                         *   不打印（那会儿 PERF 还是上一张表的，打出来只会误导）。 */
                        if (idle && g_dl_postmortem) {
    1ba4:	8681a783          	lw	a5,-1944(gp) # 7960 <g_dl_postmortem>
    1ba8:	10079063          	bnez	a5,1ca8 <main+0xba4>
                            bsp_printf("EV dl post-mortem: perf=%d tmo=%d (this list, GO->ERR->BUSY=0)\r\n",
                                       (int)blt_rd(BLT_DL_PERF), (int)(DL_TIMEOUT_TICKS & 0xFFFFu));
                        }
                        /* 没等到 BUSY=0（20ms 上界到点）也把这一行作废：那会儿 PERF 还是旧的，
                         * 留到下一次交接打出来只会误导。 */
                        g_dl_postmortem = 0;
    1bac:	8601a423          	sw	zero,-1944(gp) # 7960 <g_dl_postmortem>
                        /* 停了（或有界超时）：本趟作废、从零重画 */
                        g_dl_fbwait = 0; g_dl_inflight = 0; g_dl_pend = -1; g_dl_pend_last = 0;
    1bb0:	8601ae23          	sw	zero,-1924(gp) # 7974 <g_dl_fbwait>
    1bb4:	8801a623          	sw	zero,-1908(gp) # 7984 <g_dl_inflight>
    1bb8:	fff00713          	li	a4,-1
    1bbc:	80e1aa23          	sw	a4,-2028(gp) # 790c <g_dl_pend>
    1bc0:	8801a023          	sw	zero,-1920(gp) # 7978 <g_dl_pend_last>
                        hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
    1bc4:	08012423          	sw	zero,136(sp)
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                        g_pass_armed = 0;
    1bc8:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
#endif
                        if (g_dl_retry_pend) {
    1bcc:	8601a783          	lw	a5,-1952(gp) # 7958 <g_dl_retry_pend>
    1bd0:	04f12023          	sw	a5,64(sp)
    1bd4:	460780e3          	beqz	a5,2834 <main+0x1730>
                             *     不会切在一张表中间；
                             *   · g_dl_report=1 由 arm 分支自动置上 ⇒ 重试那张表照样做"第一张表
                             *     读数 + 像素落地探针"（原有的两条保证一个都不少）；
                             *   · ★ 一帧只有 ~19ms，而 dl_wd_decide() 保证两次"重新起趟"至少隔
                             *     1s ⇒ 同一个帧里**绝不可能**重开第二趟。 */
                            g_dl_retry_pend = 0;
    1bd8:	8601a023          	sw	zero,-1952(gp) # 7958 <g_dl_retry_pend>
                            if (!idle) {
    1bdc:	100b0263          	beqz	s6,1ce0 <main+0xbdc>
                                g_dl_retry_bad++;
    1be0:	8581a783          	lw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
    1be4:	00178793          	addi	a5,a5,1
    1be8:	84f1ac23          	sw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
                                bsp_printf("EV dl retry %d/%d failed (DFU still BUSY after %d ticks)\r\n",
    1bec:	001e86b7          	lui	a3,0x1e8
    1bf0:	48068693          	addi	a3,a3,1152 # 1e8480 <__freertos_irq_stack_top+0x1a50e0>
    1bf4:	00100613          	li	a2,1
    1bf8:	8641a583          	lw	a1,-1948(gp) # 795c <g_dl_retry_n>
    1bfc:	00007537          	lui	a0,0x7
    1c00:	22850513          	addi	a0,a0,552 # 7228 <_data+0x1428>
    1c04:	2ec030ef          	jal	4ef0 <bsp_printf>
                                           g_dl_retry_n, DL_RETRY_MAX, (int)DL_FBWAIT_TICKS);
                                dl_wd_summary("retry aborted: DFU never went idle");
    1c08:	00007537          	lui	a0,0x7
    1c0c:	26450513          	addi	a0,a0,612 # 7264 <_data+0x1464>
    1c10:	341030ef          	jal	5750 <dl_wd_summary>
                                dl_disable("WATCHDOG: DFU never went idle");
    1c14:	00007537          	lui	a0,0x7
    1c18:	28850513          	addi	a0,a0,648 # 7288 <_data+0x1488>
    1c1c:	381030ef          	jal	579c <dl_disable>
                        hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
    1c20:	04812023          	sw	s0,64(sp)
    1c24:	00100793          	li	a5,1
    1c28:	04f12223          	sw	a5,68(sp)
    1c2c:	4110006f          	j	283c <main+0x1738>
        } else if ((path == PATH_CPU || hw_done) && (path == PATH_HW || cpu_done)) {
    1c30:	00100793          	li	a5,1
    1c34:	00f90a63          	beq	s2,a5,1c48 <main+0xb44>
    1c38:	02412783          	lw	a5,36(sp)
    1c3c:	f20788e3          	beqz	a5,1b6c <main+0xa68>
    1c40:	00200793          	li	a5,2
    1c44:	00f90663          	beq	s2,a5,1c50 <main+0xb4c>
    1c48:	02012783          	lw	a5,32(sp)
    1c4c:	f20780e3          	beqz	a5,1b6c <main+0xa68>
            cache_evict();                 /* 与 COPY 路径同一位置：保证 CPU 像素对内存有序 */
    1c50:	58c010ef          	jal	31dc <cache_evict>
            g_flip_req = (uint32_t)g_draw3;
    1c54:	8281a583          	lw	a1,-2008(gp) # 7920 <g_draw3>
    1c58:	8cb1a823          	sw	a1,-1840(gp) # 79c8 <g_flip_req>
            blt_wr(BLT_FB_SEL, g_flip_req);
    1c5c:	02400513          	li	a0,36
    1c60:	2e8010ef          	jal	2f48 <blt_wr>
            back_t0   = tick32();
    1c64:	2c8010ef          	jal	2f2c <tick32>
    1c68:	02a12423          	sw	a0,40(sp)
            hw_done = 0; cpu_done = 0;
    1c6c:	02812023          	sw	s0,32(sp)
    1c70:	02812223          	sw	s0,36(sp)
            back_busy = 1;
    1c74:	00100413          	li	s0,1
    1c78:	ef5ff06f          	j	1b6c <main+0xa68>
                        }
                    } else {
                        cpu_backoff(BLT_WAIT_NOP);
                    }
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
    1c7c:	03000513          	li	a0,48
    1c80:	2b8010ef          	jal	2f38 <cpu_backoff>
    1c84:	3b90006f          	j	283c <main+0x1738>
                    if (idle || ((uint32_t)(tick32() - g_dl_ft0) > (uint32_t)DL_FBWAIT_TICKS)) {
    1c88:	2a4010ef          	jal	2f2c <tick32>
    1c8c:	8781a783          	lw	a5,-1928(gp) # 7970 <g_dl_ft0>
    1c90:	40f50533          	sub	a0,a0,a5
    1c94:	001e87b7          	lui	a5,0x1e8
    1c98:	48078793          	addi	a5,a5,1152 # 1e8480 <__freertos_irq_stack_top+0x1a50e0>
    1c9c:	06a7fc63          	bgeu	a5,a0,1d14 <main+0xc10>
                        if (idle && g_dl_postmortem) {
    1ca0:	f00b16e3          	bnez	s6,1bac <main+0xaa8>
    1ca4:	f01ff06f          	j	1ba4 <main+0xaa0>
                            g_dl_postmortem = 0;
    1ca8:	8601a423          	sw	zero,-1944(gp) # 7960 <g_dl_postmortem>
                            dl_status_dump("post-mortem", fst);
    1cac:	000a8593          	mv	a1,s5
    1cb0:	00007537          	lui	a0,0x7
    1cb4:	1d850513          	addi	a0,a0,472 # 71d8 <_data+0x13d8>
    1cb8:	4d8030ef          	jal	5190 <dl_status_dump>
                                       (int)blt_rd(BLT_DL_PERF), (int)(DL_TIMEOUT_TICKS & 0xFFFFu));
    1cbc:	07c00513          	li	a0,124
    1cc0:	298010ef          	jal	2f58 <blt_rd>
    1cc4:	00050593          	mv	a1,a0
                            bsp_printf("EV dl post-mortem: perf=%d tmo=%d (this list, GO->ERR->BUSY=0)\r\n",
    1cc8:	00010637          	lui	a2,0x10
    1ccc:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f07>
    1cd0:	00007537          	lui	a0,0x7
    1cd4:	1e450513          	addi	a0,a0,484 # 71e4 <_data+0x13e4>
    1cd8:	218030ef          	jal	4ef0 <bsp_printf>
    1cdc:	ed1ff06f          	j	1bac <main+0xaa8>
                                g_dl_armed  = 0;
    1ce0:	8801a823          	sw	zero,-1904(gp) # 7988 <g_dl_armed>
                                g_dl_report = 1;
    1ce4:	00100713          	li	a4,1
    1ce8:	86e1aa23          	sw	a4,-1932(gp) # 796c <g_dl_report>
                                g_dl_stall_seen = 0;
    1cec:	8601a623          	sw	zero,-1940(gp) # 7964 <g_dl_stall_seen>
                                bsp_printf("EV dl retry %d/%d start (fresh arm, this pass from hw_i=0)\r\n",
    1cf0:	00100613          	li	a2,1
    1cf4:	8641a583          	lw	a1,-1948(gp) # 795c <g_dl_retry_n>
    1cf8:	00007537          	lui	a0,0x7
    1cfc:	2a850513          	addi	a0,a0,680 # 72a8 <_data+0x14a8>
    1d00:	1f0030ef          	jal	4ef0 <bsp_printf>
                        hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
    1d04:	04812023          	sw	s0,64(sp)
    1d08:	00100793          	li	a5,1
    1d0c:	04f12223          	sw	a5,68(sp)
    1d10:	32d0006f          	j	283c <main+0x1738>
                        cpu_backoff(BLT_WAIT_NOP);
    1d14:	03000513          	li	a0,48
    1d18:	220010ef          	jal	2f38 <cpu_backoff>
    1d1c:	3210006f          	j	283c <main+0x1738>
                }
            } else if (g_dl_mode) {
    1d20:	8941ab03          	lw	s6,-1900(gp) # 798c <g_dl_mode>
    1d24:	740b0e63          	beqz	s6,2480 <main+0x137c>
                int y0   = hw_y0(path);
    1d28:	00090513          	mv	a0,s2
    1d2c:	16c030ef          	jal	4e98 <hw_y0>
    1d30:	04a12a23          	sw	a0,84(sp)
                int poll = ((path != PATH_HW) || ((it & BLT_WAIT_MASK) == 0u)) ? 1 : 0;
    1d34:	00200793          	li	a5,2
    1d38:	08f90463          	beq	s2,a5,1dc0 <main+0xcbc>
    1d3c:	00100b13          	li	s6,1
                int armed_ok = 1;

                /* ★v2.13 关→开时的一次性配置**带回读校验**：不过就当场退回逐条路径。
                 * 校验内容与理由见 dl_arm()/dl_arm_verify() —— 覆盖的正是"只有场景 2/3
                 * 会踩"的几何表那条链路（配置寄存器读回、几何表读回、W/H/行距非 0）。 */
                if (!g_dl_armed) {
    1d40:	8901a783          	lw	a5,-1904(gp) # 7988 <g_dl_armed>
    1d44:	08078a63          	beqz	a5,1dd8 <main+0xcd4>
                    hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                    g_pass_armed = 0;
#endif
                    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
                } else if (g_dl_inflight) {
    1d48:	88c1ab83          	lw	s7,-1908(gp) # 7984 <g_dl_inflight>
    1d4c:	4e0b8663          	beqz	s7,2238 <main+0x1134>
                    /* ① 乒乓：把下一段写进另一张缓冲。
                     *    描述符只是 DDR 存储（一次 MMIO 都没有），不打扰 DFU 取指。 */
                    if (g_dl_pend < 0 && hw_i < n) {
    1d50:	8141a783          	lw	a5,-2028(gp) # 790c <g_dl_pend>
    1d54:	1207c063          	bltz	a5,1e74 <main+0xd70>
                        cache_evict();             /* 硬件紧接着要读这批描述符 */
                        g_dl_pend = 1 - g_dl_buf; g_dl_pend_n = c; g_dl_pend_last = last;
                        g_dl_pend_sp = hw_i - i0;
                    }
                    /* ② 低频轮询本表：DONE 电平（含引擎写提交）或 ERR 锁存 */
                    if (poll) {
    1d58:	4c0b0a63          	beqz	s6,222c <main+0x1128>
                        uint32_t st = blt_rd(BLT_DL_STATUS);
    1d5c:	05c00513          	li	a0,92
    1d60:	1f8010ef          	jal	2f58 <blt_rd>
    1d64:	00050b93          	mv	s7,a0
                        /* ★v2.14 STALL 必须在这里**粘住**：它是组合位，出错后进 S_ERR 就恒 0
                         *   （理由见 dl_status_dump()），只有在"表还在飞"的每次轮询里记下来，
                         *   出错时才能回答"这张表是不是被饿住过"。 */
                        if (st & DL_ST_STALL) g_dl_stall_seen = 1;
    1d68:	01057793          	andi	a5,a0,16
    1d6c:	00078663          	beqz	a5,1d78 <main+0xc74>
    1d70:	00100713          	li	a4,1
    1d74:	86e1a623          	sw	a4,-1940(gp) # 7964 <g_dl_stall_seen>
                        if (st & DL_ST_ERR) {
    1d78:	004bf793          	andi	a5,s7,4
    1d7c:	1a079c63          	bnez	a5,1f34 <main+0xe30>
                            hw_frame_pushed = 0; repaint_hw = 1;
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                            g_pass_armed = 0;
#endif
                            osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
                        } else if (!(st & DL_ST_BUSY)) {
    1d80:	001bf793          	andi	a5,s7,1
    1d84:	2a079ce3          	bnez	a5,283c <main+0x1738>
                            /* 本表消费完（DONE；ABORTED 也走这里）⇒ 它那张缓冲重新可写 */
                            if (g_dl_report) {
    1d88:	8741a783          	lw	a5,-1932(gp) # 796c <g_dl_report>
    1d8c:	36079663          	bnez	a5,20f8 <main+0xff4>
                                }
                            }
                            /* ★v2.15 成本行：这张表**跑完了**（BUSY=0 之后 DL_PERF 才是这张表的
                             *   周期数）⇒ 记一行"n / cycles / cyc/sprite"，1Hz 门控不刷屏。
                             *   放在"重试 ok"之前打：先给数、再给结论，日志顺序更好读。 */
                            dl_cost_report(g_dl_inflight_sp);
    1d90:	8441a503          	lw	a0,-1980(gp) # 793c <g_dl_inflight_sp>
    1d94:	2dd030ef          	jal	5870 <dl_cost_report>
                            /* ★v2.15 重试成功的判据：那张重试表**跑完了且没报错**、而且
                             *   上面的像素探针也没把它否掉（探针不过时 dl_disable() 已经把
                             *   g_dl_mode 清 0 ⇒ 这里绝不会把"没画像素"报成 ok）。
                             *   成功后**没有"恢复额度"这回事**了：策略是"一次事件一次机会"，
                             *   下一次看门狗事件会重新走一遍 dl_wd_decide()（距上次 >1s 才重试）。 */
                            if (g_dl_retry_n && g_dl_mode) {
    1d98:	8641a583          	lw	a1,-1948(gp) # 795c <g_dl_retry_n>
    1d9c:	00058663          	beqz	a1,1da8 <main+0xca4>
    1da0:	8941a783          	lw	a5,-1900(gp) # 798c <g_dl_mode>
    1da4:	40079c63          	bnez	a5,21bc <main+0x10b8>
                                bsp_printf("EV dl retry %d/%d ok (cumulative ok=%d bad=%d)\r\n",
                                           g_dl_retry_n, DL_RETRY_MAX,
                                           (int)g_dl_retry_ok, (int)g_dl_retry_bad);
                                g_dl_retry_n = 0;
                            }
                            if (g_dl_mode && g_dl_pend >= 0) {
    1da8:	8941a783          	lw	a5,-1900(gp) # 798c <g_dl_mode>
    1dac:	00078663          	beqz	a5,1db8 <main+0xcb4>
    1db0:	8141a503          	lw	a0,-2028(gp) # 790c <g_dl_pend>
    1db4:	42055863          	bgez	a0,21e4 <main+0x10e0>
                                      g_fb_back + (uint32_t)y0 * FB_STRIDE);
                                g_dl_buf = g_dl_pend; g_dl_pend = -1;
                                g_dl_inflight_sp = g_dl_pend_sp;   /* 成本行的 n= 跟着这张表走 */
                                if (g_dl_pend_last) { g_dl_pend_last = 0; hw_frame_pushed = 1; }
                            } else {
                                g_dl_inflight = 0;     /* 下一圈在下面那个分支里收尾/继续发 */
    1db8:	8801a623          	sw	zero,-1908(gp) # 7984 <g_dl_inflight>
    1dbc:	2810006f          	j	283c <main+0x1738>
                int poll = ((path != PATH_HW) || ((it & BLT_WAIT_MASK) == 0u)) ? 1 : 0;
    1dc0:	0039f793          	andi	a5,s3,3
    1dc4:	00079663          	bnez	a5,1dd0 <main+0xccc>
    1dc8:	00100b13          	li	s6,1
    1dcc:	f75ff06f          	j	1d40 <main+0xc3c>
    1dd0:	000a8b13          	mv	s6,s5
    1dd4:	f6dff06f          	j	1d40 <main+0xc3c>
                    armed_ok = dl_arm();
    1dd8:	604030ef          	jal	53dc <dl_arm>
    1ddc:	00050b93          	mv	s7,a0
                    g_dl_armed = armed_ok;
    1de0:	88a1a823          	sw	a0,-1904(gp) # 7988 <g_dl_armed>
                    g_dl_report = armed_ok;
    1de4:	86a1aa23          	sw	a0,-1932(gp) # 796c <g_dl_report>
                    g_dl_probe_px = 0;
    1de8:	8601a823          	sw	zero,-1936(gp) # 7968 <g_dl_probe_px>
                if (!armed_ok) {
    1dec:	f4051ee3          	bnez	a0,1d48 <main+0xc44>
                    if (g_dl_retry_n) {
    1df0:	8641a583          	lw	a1,-1948(gp) # 795c <g_dl_retry_n>
    1df4:	04059a63          	bnez	a1,1e48 <main+0xd44>
                    g_dl_retry_n = 0; g_dl_retry_pend = 0;
    1df8:	8601a223          	sw	zero,-1948(gp) # 795c <g_dl_retry_n>
    1dfc:	8601a023          	sw	zero,-1952(gp) # 7958 <g_dl_retry_pend>
                    g_dl_postmortem = 0;
    1e00:	8601a423          	sw	zero,-1944(gp) # 7960 <g_dl_postmortem>
                    g_dl_mode = 0; g_dl_want = -1;
    1e04:	8801aa23          	sw	zero,-1900(gp) # 798c <g_dl_mode>
    1e08:	fff00713          	li	a4,-1
    1e0c:	80e1a823          	sw	a4,-2032(gp) # 7908 <g_dl_want>
                    hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
    1e10:	08012423          	sw	zero,136(sp)
                    g_pass_armed = 0;
    1e14:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
                    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
    1e18:	00000813          	li	a6,0
    1e1c:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    1e20:	000d8713          	mv	a4,s11
    1e24:	000c8693          	mv	a3,s9
    1e28:	03012603          	lw	a2,48(sp)
    1e2c:	000d0593          	mv	a1,s10
    1e30:	000a0513          	mv	a0,s4
    1e34:	08c020ef          	jal	3ec0 <osd_build>
                    hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
    1e38:	05712023          	sw	s7,64(sp)
    1e3c:	00100793          	li	a5,1
    1e40:	04f12223          	sw	a5,68(sp)
    1e44:	1f90006f          	j	283c <main+0x1738>
                        g_dl_retry_bad++;
    1e48:	8581a783          	lw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
    1e4c:	00178793          	addi	a5,a5,1
    1e50:	84f1ac23          	sw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
                        bsp_printf("EV dl retry %d/%d failed (re-arm verification failed)\r\n",
    1e54:	00100613          	li	a2,1
    1e58:	00007537          	lui	a0,0x7
    1e5c:	2e850513          	addi	a0,a0,744 # 72e8 <_data+0x14e8>
    1e60:	090030ef          	jal	4ef0 <bsp_printf>
                        dl_wd_summary("retry re-arm verification failed");
    1e64:	00007537          	lui	a0,0x7
    1e68:	32050513          	addi	a0,a0,800 # 7320 <_data+0x1520>
    1e6c:	0e5030ef          	jal	5750 <dl_wd_summary>
    1e70:	f89ff06f          	j	1df8 <main+0xcf4>
                    if (g_dl_pend < 0 && hw_i < n) {
    1e74:	08812b83          	lw	s7,136(sp)
    1e78:	ef4bd0e3          	bge	s7,s4,1d58 <main+0xc54>
                        int c = 0, last = 0;
    1e7c:	06012423          	sw	zero,104(sp)
    1e80:	06012623          	sw	zero,108(sp)
                        int rep = (hw_i == 0 && repaint_hw) ? dl_rep_id(path) : -1;
    1e84:	000b9e63          	bnez	s7,1ea0 <main+0xd9c>
    1e88:	04412783          	lw	a5,68(sp)
    1e8c:	08078e63          	beqz	a5,1f28 <main+0xe24>
    1e90:	00090513          	mv	a0,s2
    1e94:	0e1020ef          	jal	4774 <dl_rep_id>
    1e98:	00050713          	mv	a4,a0
    1e9c:	00c0006f          	j	1ea8 <main+0xda4>
    1ea0:	fff00793          	li	a5,-1
    1ea4:	00078713          	mv	a4,a5
                        dl_build((uint32_t *)DL_LIST_ADDR(1 - g_dl_buf), &hw_i, n, scene,
    1ea8:	8881a783          	lw	a5,-1912(gp) # 7980 <g_dl_buf>
    1eac:	00100513          	li	a0,1
    1eb0:	40f50533          	sub	a0,a0,a5
    1eb4:	01151513          	slli	a0,a0,0x11
    1eb8:	06c10793          	addi	a5,sp,108
    1ebc:	00f12023          	sw	a5,0(sp)
    1ec0:	06810893          	addi	a7,sp,104
    1ec4:	00070493          	mv	s1,a4
    1ec8:	00070813          	mv	a6,a4
    1ecc:	000c8793          	mv	a5,s9
    1ed0:	03012703          	lw	a4,48(sp)
    1ed4:	000d0693          	mv	a3,s10
    1ed8:	000a0613          	mv	a2,s4
    1edc:	08810593          	addi	a1,sp,136
    1ee0:	00821337          	lui	t1,0x821
    1ee4:	00650533          	add	a0,a0,t1
    1ee8:	0a1020ef          	jal	4788 <dl_build>
                        if (rep >= 0) repaint_hw = 0;
    1eec:	0004c463          	bltz	s1,1ef4 <main+0xdf0>
    1ef0:	05512223          	sw	s5,68(sp)
                        cache_evict();             /* 硬件紧接着要读这批描述符 */
    1ef4:	2e8010ef          	jal	31dc <cache_evict>
                        g_dl_pend = 1 - g_dl_buf; g_dl_pend_n = c; g_dl_pend_last = last;
    1ef8:	8881a703          	lw	a4,-1912(gp) # 7980 <g_dl_buf>
    1efc:	00100793          	li	a5,1
    1f00:	40e787b3          	sub	a5,a5,a4
    1f04:	80f1aa23          	sw	a5,-2028(gp) # 790c <g_dl_pend>
    1f08:	06812703          	lw	a4,104(sp)
    1f0c:	88e1a223          	sw	a4,-1916(gp) # 797c <g_dl_pend_n>
    1f10:	06c12703          	lw	a4,108(sp)
    1f14:	88e1a023          	sw	a4,-1920(gp) # 7978 <g_dl_pend_last>
                        g_dl_pend_sp = hw_i - i0;
    1f18:	08812783          	lw	a5,136(sp)
    1f1c:	417787b3          	sub	a5,a5,s7
    1f20:	84f1a023          	sw	a5,-1984(gp) # 7938 <g_dl_pend_sp>
    1f24:	e35ff06f          	j	1d58 <main+0xc54>
                        int rep = (hw_i == 0 && repaint_hw) ? dl_rep_id(path) : -1;
    1f28:	fff00793          	li	a5,-1
    1f2c:	00078713          	mv	a4,a5
    1f30:	f79ff06f          	j	1ea8 <main+0xda4>
                            uint32_t ew    = dl_err_report();
    1f34:	60c030ef          	jal	5540 <dl_err_report>
    1f38:	04a12a23          	sw	a0,84(sp)
                            int      wd    = ((ew & 0xFFu) == 0x10u);
    1f3c:	0ff57b93          	zext.b	s7,a0
                            int      spent = (g_dl_retry_n != 0);   /* 错的正是上一次重试 */
    1f40:	8641a783          	lw	a5,-1948(gp) # 795c <g_dl_retry_n>
    1f44:	04f12023          	sw	a5,64(sp)
    1f48:	00f037b3          	snez	a5,a5
    1f4c:	04f12c23          	sw	a5,88(sp)
                            uint32_t now   = tick32();
    1f50:	7dd000ef          	jal	2f2c <tick32>
                            int      again = 0;
    1f54:	06012623          	sw	zero,108(sp)
                            if (wd) {
    1f58:	01000793          	li	a5,16
    1f5c:	04fb8463          	beq	s7,a5,1fa4 <main+0xea0>
                            uint32_t gap   = 0xFFFFFFFFu;           /* 默认 = "很久以前"（没出过事件）*/
    1f60:	fff00793          	li	a5,-1
    1f64:	04f12223          	sw	a5,68(sp)
                            if (spent) {
    1f68:	04012783          	lw	a5,64(sp)
    1f6c:	06079463          	bnez	a5,1fd4 <main+0xed0>
                            if (wd)
    1f70:	01000793          	li	a5,16
    1f74:	0afb8063          	beq	s7,a5,2014 <main+0xf10>
                                if (wd) {
    1f78:	01000793          	li	a5,16
    1f7c:	0cfb8863          	beq	s7,a5,204c <main+0xf48>
                                } else if (spent) {
    1f80:	04012783          	lw	a5,64(sp)
    1f84:	16078263          	beqz	a5,20e8 <main+0xfe4>
                                    dl_wd_summary("retry failed with a deterministic error");
    1f88:	00007537          	lui	a0,0x7
    1f8c:	40c50513          	addi	a0,a0,1036 # 740c <_data+0x160c>
    1f90:	7c0030ef          	jal	5750 <dl_wd_summary>
                                    dl_disable("DL_ERR");
    1f94:	00007537          	lui	a0,0x7
    1f98:	43450513          	addi	a0,a0,1076 # 7434 <_data+0x1634>
    1f9c:	001030ef          	jal	579c <dl_disable>
    1fa0:	0d40006f          	j	2074 <main+0xf70>
                                g_dl_wd_events++;
    1fa4:	8541a783          	lw	a5,-1964(gp) # 794c <g_dl_wd_events>
    1fa8:	00178793          	addi	a5,a5,1
    1fac:	84f1aa23          	sw	a5,-1964(gp) # 794c <g_dl_wd_events>
                                if (g_dl_wd_last != 0)
    1fb0:	8501a783          	lw	a5,-1968(gp) # 7948 <g_dl_wd_last>
    1fb4:	00078a63          	beqz	a5,1fc8 <main+0xec4>
                                    gap = (uint32_t)(now - g_dl_wd_last);
    1fb8:	40f507b3          	sub	a5,a0,a5
    1fbc:	04f12223          	sw	a5,68(sp)
                                g_dl_wd_last = now;
    1fc0:	84a1a823          	sw	a0,-1968(gp) # 7948 <g_dl_wd_last>
    1fc4:	fa5ff06f          	j	1f68 <main+0xe64>
                            uint32_t gap   = 0xFFFFFFFFu;           /* 默认 = "很久以前"（没出过事件）*/
    1fc8:	fff00793          	li	a5,-1
    1fcc:	04f12223          	sw	a5,68(sp)
    1fd0:	ff1ff06f          	j	1fc0 <main+0xebc>
                                g_dl_retry_bad++;
    1fd4:	8581a783          	lw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
    1fd8:	00178793          	addi	a5,a5,1
    1fdc:	84f1ac23          	sw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
                                bsp_printf("EV dl retry %d/%d failed (code=%x %s)\r\n",
    1fe0:	8641a783          	lw	a5,-1948(gp) # 795c <g_dl_retry_n>
    1fe4:	04f12e23          	sw	a5,92(sp)
    1fe8:	05412503          	lw	a0,84(sp)
    1fec:	5ed020ef          	jal	4dd8 <dl_err_name>
    1ff0:	00050713          	mv	a4,a0
    1ff4:	000b8693          	mv	a3,s7
    1ff8:	00100613          	li	a2,1
    1ffc:	05c12583          	lw	a1,92(sp)
    2000:	00007537          	lui	a0,0x7
    2004:	34450513          	addi	a0,a0,836 # 7344 <_data+0x1544>
    2008:	6e9020ef          	jal	4ef0 <bsp_printf>
                                g_dl_retry_n = 0;
    200c:	8601a223          	sw	zero,-1948(gp) # 795c <g_dl_retry_n>
    2010:	f61ff06f          	j	1f70 <main+0xe6c>
                                verdict = dl_wd_decide(spent, gap, &again);
    2014:	06c10613          	addi	a2,sp,108
    2018:	04412583          	lw	a1,68(sp)
    201c:	05812503          	lw	a0,88(sp)
    2020:	2c1020ef          	jal	4ae0 <dl_wd_decide>
                            if (verdict == DL_WD_RETRY) {
    2024:	00100793          	li	a5,1
    2028:	f4f518e3          	bne	a0,a5,1f78 <main+0xe74>
                                g_dl_retry_n    = 1;        /* 本事件唯一的一次重试 */
    202c:	86f1a223          	sw	a5,-1948(gp) # 795c <g_dl_retry_n>
                                g_dl_retry_pend = 1;
    2030:	86f1a023          	sw	a5,-1952(gp) # 7958 <g_dl_retry_pend>
                                bsp_printf("EV dl retry %d/%d pending (WATCHDOG: wait BUSY=0, re-arm, resend this pass)\r\n",
    2034:	00100613          	li	a2,1
    2038:	00100593          	li	a1,1
    203c:	00007537          	lui	a0,0x7
    2040:	36c50513          	addi	a0,a0,876 # 736c <_data+0x156c>
    2044:	6ad020ef          	jal	4ef0 <bsp_printf>
    2048:	02c0006f          	j	2074 <main+0xf70>
                                    if (spent)
    204c:	04012783          	lw	a5,64(sp)
    2050:	06079c63          	bnez	a5,20c8 <main+0xfc4>
                                    else if (again)
    2054:	06c12783          	lw	a5,108(sp)
    2058:	08078063          	beqz	a5,20d8 <main+0xfd4>
                                        dl_wd_summary("2nd watchdog within 1s window");
    205c:	00007537          	lui	a0,0x7
    2060:	3d050513          	addi	a0,a0,976 # 73d0 <_data+0x15d0>
    2064:	6ec030ef          	jal	5750 <dl_wd_summary>
                                    dl_disable("WATCHDOG");
    2068:	00007537          	lui	a0,0x7
    206c:	40050513          	addi	a0,a0,1024 # 7400 <_data+0x1600>
    2070:	72c030ef          	jal	579c <dl_disable>
                            g_dl_postmortem = 1;        /* BUSY 落定后补一行本表真实 PERF */
    2074:	00100793          	li	a5,1
    2078:	86f1a423          	sw	a5,-1944(gp) # 7960 <g_dl_postmortem>
                            g_dl_fbwait = 1; g_dl_ft0 = tick32();
    207c:	86f1ae23          	sw	a5,-1924(gp) # 7974 <g_dl_fbwait>
    2080:	6ad000ef          	jal	2f2c <tick32>
    2084:	86a1ac23          	sw	a0,-1928(gp) # 7970 <g_dl_ft0>
                            g_dl_inflight = 0; g_dl_pend = -1; g_dl_pend_last = 0;
    2088:	8801a623          	sw	zero,-1908(gp) # 7984 <g_dl_inflight>
    208c:	fff00713          	li	a4,-1
    2090:	80e1aa23          	sw	a4,-2028(gp) # 790c <g_dl_pend>
    2094:	8801a023          	sw	zero,-1920(gp) # 7978 <g_dl_pend_last>
                            g_pass_armed = 0;
    2098:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
                            osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
    209c:	8941a803          	lw	a6,-1900(gp) # 798c <g_dl_mode>
    20a0:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    20a4:	000d8713          	mv	a4,s11
    20a8:	000c8693          	mv	a3,s9
    20ac:	03012603          	lw	a2,48(sp)
    20b0:	000d0593          	mv	a1,s10
    20b4:	000a0513          	mv	a0,s4
    20b8:	609010ef          	jal	3ec0 <osd_build>
                            hw_frame_pushed = 0; repaint_hw = 1;
    20bc:	05612223          	sw	s6,68(sp)
    20c0:	05512023          	sw	s5,64(sp)
    20c4:	7780006f          	j	283c <main+0x1738>
                                        dl_wd_summary("retry also failed");
    20c8:	00007537          	lui	a0,0x7
    20cc:	3bc50513          	addi	a0,a0,956 # 73bc <_data+0x15bc>
    20d0:	680030ef          	jal	5750 <dl_wd_summary>
    20d4:	f95ff06f          	j	2068 <main+0xf64>
                                        dl_wd_summary("watchdog event");   /* 防御：dl_wd_decide 不会给这个组合 */
    20d8:	00007537          	lui	a0,0x7
    20dc:	3f050513          	addi	a0,a0,1008 # 73f0 <_data+0x15f0>
    20e0:	670030ef          	jal	5750 <dl_wd_summary>
    20e4:	f85ff06f          	j	2068 <main+0xf64>
                                    dl_disable("DL_ERR");   /* 确定性错误：直接退回逐条 */
    20e8:	00007537          	lui	a0,0x7
    20ec:	43450513          	addi	a0,a0,1076 # 7434 <_data+0x1634>
    20f0:	6ac030ef          	jal	579c <dl_disable>
    20f4:	f81ff06f          	j	2074 <main+0xf70>
                                g_dl_report = 0;
    20f8:	8601aa23          	sw	zero,-1932(gp) # 796c <g_dl_report>
                                           (unsigned)st, (int)(st >> DL_ST_CONSUMED_SH),
    20fc:	010bda93          	srli	s5,s7,0x10
                                           (int)blt_rd(BLT_DL_PERF));
    2100:	07c00513          	li	a0,124
    2104:	655000ef          	jal	2f58 <blt_rd>
    2108:	00050693          	mv	a3,a0
                                bsp_printf("EV dl 1st list: STATUS=%x consumed=%d perf=%d\r\n",
    210c:	000a8613          	mv	a2,s5
    2110:	000b8593          	mv	a1,s7
    2114:	00007537          	lui	a0,0x7
    2118:	43c50513          	addi	a0,a0,1084 # 743c <_data+0x163c>
    211c:	5d5020ef          	jal	4ef0 <bsp_printf>
                                if (!dl_pixel_probe()) {
    2120:	5d0030ef          	jal	56f0 <dl_pixel_probe>
    2124:	00050a93          	mv	s5,a0
    2128:	c60514e3          	bnez	a0,1d90 <main+0xc8c>
                                    if (g_dl_retry_n) {
    212c:	8641a583          	lw	a1,-1948(gp) # 795c <g_dl_retry_n>
    2130:	06059063          	bnez	a1,2190 <main+0x108c>
                                    dl_disable("1st list drew no pixels");
    2134:	00007537          	lui	a0,0x7
    2138:	4c050513          	addi	a0,a0,1216 # 74c0 <_data+0x16c0>
    213c:	660030ef          	jal	579c <dl_disable>
                                    g_dl_fbwait = 1; g_dl_ft0 = tick32();
    2140:	00100713          	li	a4,1
    2144:	86e1ae23          	sw	a4,-1924(gp) # 7974 <g_dl_fbwait>
    2148:	5e5000ef          	jal	2f2c <tick32>
    214c:	86a1ac23          	sw	a0,-1928(gp) # 7970 <g_dl_ft0>
                                    g_dl_inflight = 0; g_dl_pend = -1; g_dl_pend_last = 0;
    2150:	8801a623          	sw	zero,-1908(gp) # 7984 <g_dl_inflight>
    2154:	fff00713          	li	a4,-1
    2158:	80e1aa23          	sw	a4,-2028(gp) # 790c <g_dl_pend>
    215c:	8801a023          	sw	zero,-1920(gp) # 7978 <g_dl_pend_last>
                                    g_pass_armed = 0;
    2160:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
                                    osd_build(n, scene, alpha, clear_pp, frame_adv, g_blk, g_dl_mode);
    2164:	8941a803          	lw	a6,-1900(gp) # 798c <g_dl_mode>
    2168:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    216c:	000d8713          	mv	a4,s11
    2170:	000c8693          	mv	a3,s9
    2174:	03012603          	lw	a2,48(sp)
    2178:	000d0593          	mv	a1,s10
    217c:	000a0513          	mv	a0,s4
    2180:	541010ef          	jal	3ec0 <osd_build>
                                    hw_frame_pushed = 0; repaint_hw = 1;
    2184:	05612223          	sw	s6,68(sp)
    2188:	05512023          	sw	s5,64(sp)
    218c:	c05ff06f          	j	1d90 <main+0xc8c>
                                        g_dl_retry_bad++;
    2190:	8581a783          	lw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
    2194:	00178793          	addi	a5,a5,1
    2198:	84f1ac23          	sw	a5,-1960(gp) # 7950 <g_dl_retry_bad>
                                        bsp_printf("EV dl retry %d/%d failed (list ran but drew no pixels)\r\n",
    219c:	00100613          	li	a2,1
    21a0:	00007537          	lui	a0,0x7
    21a4:	46c50513          	addi	a0,a0,1132 # 746c <_data+0x166c>
    21a8:	549020ef          	jal	4ef0 <bsp_printf>
                                        dl_wd_summary("retry drew no pixels");
    21ac:	00007537          	lui	a0,0x7
    21b0:	4a850513          	addi	a0,a0,1192 # 74a8 <_data+0x16a8>
    21b4:	59c030ef          	jal	5750 <dl_wd_summary>
    21b8:	f7dff06f          	j	2134 <main+0x1030>
                                g_dl_retry_ok++;
    21bc:	85c1a683          	lw	a3,-1956(gp) # 7954 <g_dl_retry_ok>
    21c0:	00168693          	addi	a3,a3,1
    21c4:	84d1ae23          	sw	a3,-1956(gp) # 7954 <g_dl_retry_ok>
                                bsp_printf("EV dl retry %d/%d ok (cumulative ok=%d bad=%d)\r\n",
    21c8:	8581a703          	lw	a4,-1960(gp) # 7950 <g_dl_retry_bad>
    21cc:	00100613          	li	a2,1
    21d0:	00007537          	lui	a0,0x7
    21d4:	4d850513          	addi	a0,a0,1240 # 74d8 <_data+0x16d8>
    21d8:	519020ef          	jal	4ef0 <bsp_printf>
                                g_dl_retry_n = 0;
    21dc:	8601a223          	sw	zero,-1948(gp) # 795c <g_dl_retry_n>
    21e0:	bc9ff06f          	j	1da8 <main+0xca4>
                                      g_fb_back + (uint32_t)y0 * FB_STRIDE);
    21e4:	78000793          	li	a5,1920
    21e8:	05412703          	lw	a4,84(sp)
    21ec:	02f707b3          	mul	a5,a4,a5
                                dl_go(g_dl_pend, g_dl_pend_n,
    21f0:	82c1a603          	lw	a2,-2004(gp) # 7924 <g_fb_back>
    21f4:	00c78633          	add	a2,a5,a2
    21f8:	8841a583          	lw	a1,-1916(gp) # 797c <g_dl_pend_n>
    21fc:	381020ef          	jal	4d7c <dl_go>
                                g_dl_buf = g_dl_pend; g_dl_pend = -1;
    2200:	8141a683          	lw	a3,-2028(gp) # 790c <g_dl_pend>
    2204:	88d1a423          	sw	a3,-1912(gp) # 7980 <g_dl_buf>
    2208:	fff00713          	li	a4,-1
    220c:	80e1aa23          	sw	a4,-2028(gp) # 790c <g_dl_pend>
                                g_dl_inflight_sp = g_dl_pend_sp;   /* 成本行的 n= 跟着这张表走 */
    2210:	8401a703          	lw	a4,-1984(gp) # 7938 <g_dl_pend_sp>
    2214:	84e1a223          	sw	a4,-1980(gp) # 793c <g_dl_inflight_sp>
                                if (g_dl_pend_last) { g_dl_pend_last = 0; hw_frame_pushed = 1; }
    2218:	8801a783          	lw	a5,-1920(gp) # 7978 <g_dl_pend_last>
    221c:	62078063          	beqz	a5,283c <main+0x1738>
    2220:	8801a023          	sw	zero,-1920(gp) # 7978 <g_dl_pend_last>
    2224:	05612023          	sw	s6,64(sp)
    2228:	6140006f          	j	283c <main+0x1738>
                            }
                        }
                    } else {
                        cpu_backoff(BLT_WAIT_NOP);
    222c:	03000513          	li	a0,48
    2230:	509000ef          	jal	2f38 <cpu_backoff>
    2234:	6080006f          	j	283c <main+0x1738>
                    }
                } else {
                    /* 无在飞、无待发：要么发下一段，要么给本趟收尾 */
                    int fin = 0;
                    if (hw_frame_pushed) {
    2238:	04012783          	lw	a5,64(sp)
    223c:	06078663          	beqz	a5,22a8 <main+0x11a4>
                        /* 半途打开 'l' 的情形：本趟的命令是逐条路径发的 ⇒ 用两条路径
                         * 共同的"引擎真的空闲"判据收尾（DFU 不忙 + 引擎 DONE/FIFO 空） */
                        if (poll && !(blt_rd(BLT_DL_STATUS) & DL_ST_BUSY) &&
    2240:	000b0a63          	beqz	s6,2254 <main+0x1150>
    2244:	05c00513          	li	a0,92
    2248:	511000ef          	jal	2f58 <blt_rd>
    224c:	00157793          	andi	a5,a0,1
    2250:	04078463          	beqz	a5,2298 <main+0x1194>
                            blt_idle_st(blt_stat())) fin = 1;
                        else cpu_backoff(BLT_WAIT_NOP);
    2254:	03000513          	li	a0,48
    2258:	4e1000ef          	jal	2f38 <cpu_backoff>
                    int fin = 0;
    225c:	000b8b13          	mv	s6,s7
                        dl_go(b, c, g_fb_back + (uint32_t)y0 * FB_STRIDE);
                        g_dl_buf = b; g_dl_inflight = 1;
                        g_dl_inflight_sp = hw_i - i0;   /* ★v2.15：成本行按这张表算 */
                        if (last) hw_frame_pushed = 1;
                    }
                    if (fin) {
    2260:	5c0b0e63          	beqz	s6,283c <main+0x1738>
                        /* ★ 与逐条路径**完全同一段收尾**（口径不许有第二套） */
                        hw_frames++; hw_frame_pushed = 0; hw_i = 0;
    2264:	03812783          	lw	a5,56(sp)
    2268:	00178793          	addi	a5,a5,1
    226c:	02f12c23          	sw	a5,56(sp)
    2270:	08012423          	sw	zero,136(sp)
                        hw_fifo_full = 0;
                        hw_done = 1;
                        if (clear_pp) repaint_hw = 1;
    2274:	000c8463          	beqz	s9,227c <main+0x1178>
    2278:	05612223          	sw	s6,68(sp)
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                        g_pass_armed = 0;
    227c:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
#endif
                        /* ★v2.15：半途打开 'l' 时本趟的命令是逐条路径发的 ⇒ 它的秒表在这一刻
                         *   结算（成本行口径见 cmd_cost_report）。列表路径发的表 g_cmd_t0=0 ⇒ 空转。*/
                        cmd_cost_report(n);
    2280:	000a0513          	mv	a0,s4
    2284:	658030ef          	jal	58dc <cmd_cost_report>
                        hw_done = 1;
    2288:	03612223          	sw	s6,36(sp)
                        hw_fifo_full = 0;
    228c:	05712623          	sw	s7,76(sp)
                        hw_frames++; hw_frame_pushed = 0; hw_i = 0;
    2290:	05712023          	sw	s7,64(sp)
    2294:	5a80006f          	j	283c <main+0x1738>
                            blt_idle_st(blt_stat())) fin = 1;
    2298:	064010ef          	jal	32fc <blt_stat>
    229c:	07c010ef          	jal	3318 <blt_idle_st>
                        if (poll && !(blt_rd(BLT_DL_STATUS) & DL_ST_BUSY) &&
    22a0:	fc0510e3          	bnez	a0,2260 <main+0x115c>
    22a4:	fb1ff06f          	j	2254 <main+0x1150>
                    } else if (hw_i >= n) {
    22a8:	08812a83          	lw	s5,136(sp)
    22ac:	1d4ad663          	bge	s5,s4,2478 <main+0x1374>
                        int c = 0, last = 0, b = 1 - g_dl_buf;
    22b0:	06012423          	sw	zero,104(sp)
    22b4:	06012623          	sw	zero,108(sp)
    22b8:	8881a783          	lw	a5,-1912(gp) # 7980 <g_dl_buf>
    22bc:	00100713          	li	a4,1
    22c0:	40f70b33          	sub	s6,a4,a5
                        int rep = (hw_i == 0 && repaint_hw) ? dl_rep_id(path) : -1;
    22c4:	000a9e63          	bnez	s5,22e0 <main+0x11dc>
    22c8:	04412783          	lw	a5,68(sp)
    22cc:	14078463          	beqz	a5,2414 <main+0x1310>
    22d0:	00090513          	mv	a0,s2
    22d4:	4a0020ef          	jal	4774 <dl_rep_id>
    22d8:	00050493          	mv	s1,a0
    22dc:	0080006f          	j	22e4 <main+0x11e0>
    22e0:	fff00493          	li	s1,-1
                        if (hw_i == 0 && snap_hw) { scene_snap(g_sc[SIDE_HW], n); snap_hw = 0; }
    22e4:	000a9663          	bnez	s5,22f0 <main+0x11ec>
    22e8:	08412783          	lw	a5,132(sp)
    22ec:	12079863          	bnez	a5,241c <main+0x1318>
                        if (hw_i == 0 && !g_pass_armed) {
    22f0:	08812783          	lw	a5,136(sp)
    22f4:	00079663          	bnez	a5,2300 <main+0x11fc>
    22f8:	8c01a783          	lw	a5,-1856(gp) # 79b8 <g_pass_armed>
    22fc:	12078c63          	beqz	a5,2434 <main+0x1330>
                            int first_seg = (hw_i == 0);
    2300:	08812783          	lw	a5,136(sp)
    2304:	04f12c23          	sw	a5,88(sp)
                            dl_build((uint32_t *)DL_LIST_ADDR(b), &hw_i, n, scene, alpha, clear_pp,
    2308:	011b1513          	slli	a0,s6,0x11
    230c:	06c10793          	addi	a5,sp,108
    2310:	00f12023          	sw	a5,0(sp)
    2314:	06810893          	addi	a7,sp,104
    2318:	00048813          	mv	a6,s1
    231c:	000c8793          	mv	a5,s9
    2320:	03012703          	lw	a4,48(sp)
    2324:	000d0693          	mv	a3,s10
    2328:	000a0613          	mv	a2,s4
    232c:	08810593          	addi	a1,sp,136
    2330:	00821337          	lui	t1,0x821
    2334:	00650533          	add	a0,a0,t1
    2338:	450020ef          	jal	4788 <dl_build>
                            if (rep >= 0) repaint_hw = 0;
    233c:	0004c663          	bltz	s1,2348 <main+0x1244>
    2340:	04012783          	lw	a5,64(sp)
    2344:	04f12223          	sw	a5,68(sp)
                            if (g_dl_report && first_seg) {
    2348:	8741a783          	lw	a5,-1932(gp) # 796c <g_dl_report>
    234c:	06078863          	beqz	a5,23bc <main+0x12b8>
    2350:	05812783          	lw	a5,88(sp)
    2354:	06079463          	bnez	a5,23bc <main+0x12b8>
                                g_dl_probe_px = 0;
    2358:	8601a823          	sw	zero,-1936(gp) # 7968 <g_dl_probe_px>
                                if (!(scene == SC_FILL && b0->color == (uint16_t)COL_BG))
    235c:	000d1c63          	bnez	s10,2374 <main+0x1270>
    2360:	000087b7          	lui	a5,0x8
    2364:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    2368:	0107d703          	lhu	a4,16(a5)
    236c:	00800793          	li	a5,8
    2370:	04f70663          	beq	a4,a5,23bc <main+0x12b8>
                                        + (uint32_t)(b0->ty + y0 + SPR_H / 2) * FB_STRIDE
    2374:	000086b7          	lui	a3,0x8
    2378:	a2068693          	addi	a3,a3,-1504 # 7a20 <g_sc>
    237c:	00e69783          	lh	a5,14(a3)
    2380:	05412703          	lw	a4,84(sp)
    2384:	00e787b3          	add	a5,a5,a4
    2388:	8201a703          	lw	a4,-2016(gp) # 7918 <g_blk>
    238c:	00200613          	li	a2,2
    2390:	02c74733          	div	a4,a4,a2
    2394:	00e787b3          	add	a5,a5,a4
                                        + (uint32_t)(b0->tx + SPR_W / 2) * 2u;
    2398:	00c69683          	lh	a3,12(a3)
    239c:	00d70733          	add	a4,a4,a3
    23a0:	3c000693          	li	a3,960
    23a4:	02d787b3          	mul	a5,a5,a3
    23a8:	00e787b3          	add	a5,a5,a4
    23ac:	00179793          	slli	a5,a5,0x1
    23b0:	82c1a703          	lw	a4,-2004(gp) # 7924 <g_fb_back>
    23b4:	00e787b3          	add	a5,a5,a4
                                    g_dl_probe_px = g_fb_back
    23b8:	86f1a823          	sw	a5,-1936(gp) # 7968 <g_dl_probe_px>
                        cache_evict();         /* 写穿屏障：描述符必须对 DDR/引擎可见 */
    23bc:	621000ef          	jal	31dc <cache_evict>
                        dl_go(b, c, g_fb_back + (uint32_t)y0 * FB_STRIDE);
    23c0:	05412703          	lw	a4,84(sp)
    23c4:	00471793          	slli	a5,a4,0x4
    23c8:	40e787b3          	sub	a5,a5,a4
    23cc:	00779793          	slli	a5,a5,0x7
    23d0:	82c1a603          	lw	a2,-2004(gp) # 7924 <g_fb_back>
    23d4:	00c78633          	add	a2,a5,a2
    23d8:	06812583          	lw	a1,104(sp)
    23dc:	000b0513          	mv	a0,s6
    23e0:	19d020ef          	jal	4d7c <dl_go>
                        g_dl_buf = b; g_dl_inflight = 1;
    23e4:	8961a423          	sw	s6,-1912(gp) # 7980 <g_dl_buf>
    23e8:	00100713          	li	a4,1
    23ec:	88e1a623          	sw	a4,-1908(gp) # 7984 <g_dl_inflight>
                        g_dl_inflight_sp = hw_i - i0;   /* ★v2.15：成本行按这张表算 */
    23f0:	08812783          	lw	a5,136(sp)
    23f4:	415787b3          	sub	a5,a5,s5
    23f8:	84f1a223          	sw	a5,-1980(gp) # 793c <g_dl_inflight_sp>
                        if (last) hw_frame_pushed = 1;
    23fc:	06c12783          	lw	a5,108(sp)
    2400:	06079863          	bnez	a5,2470 <main+0x136c>
    2404:	04012783          	lw	a5,64(sp)
                    int fin = 0;
    2408:	04012b03          	lw	s6,64(sp)
    240c:	04f12023          	sw	a5,64(sp)
    2410:	e51ff06f          	j	2260 <main+0x115c>
                        int rep = (hw_i == 0 && repaint_hw) ? dl_rep_id(path) : -1;
    2414:	fff00493          	li	s1,-1
    2418:	ecdff06f          	j	22e4 <main+0x11e0>
                        if (hw_i == 0 && snap_hw) { scene_snap(g_sc[SIDE_HW], n); snap_hw = 0; }
    241c:	000a0593          	mv	a1,s4
    2420:	00008537          	lui	a0,0x8
    2424:	a2050513          	addi	a0,a0,-1504 # 7a20 <g_sc>
    2428:	0c8020ef          	jal	44f0 <scene_snap>
    242c:	08012223          	sw	zero,132(sp)
    2430:	ec1ff06f          	j	22f0 <main+0x11ec>
                            g_pass_armed = 1;
    2434:	00100713          	li	a4,1
    2438:	8ce1a023          	sw	a4,-1856(gp) # 79b8 <g_pass_armed>
                            repaint_hw = hw_pass_arm(y0, hw_h(path));
    243c:	00090513          	mv	a0,s2
    2440:	261020ef          	jal	4ea0 <hw_h>
    2444:	00050593          	mv	a1,a0
    2448:	05412503          	lw	a0,84(sp)
    244c:	4d5000ef          	jal	3120 <hw_pass_arm>
    2450:	04a12223          	sw	a0,68(sp)
                            rep = repaint_hw ? dl_rep_id(path) : -1;
    2454:	00050a63          	beqz	a0,2468 <main+0x1364>
    2458:	00090513          	mv	a0,s2
    245c:	318020ef          	jal	4774 <dl_rep_id>
    2460:	00050493          	mv	s1,a0
    2464:	e9dff06f          	j	2300 <main+0x11fc>
    2468:	fff00493          	li	s1,-1
    246c:	e95ff06f          	j	2300 <main+0x11fc>
                        if (last) hw_frame_pushed = 1;
    2470:	00100793          	li	a5,1
    2474:	f95ff06f          	j	2408 <main+0x1304>
                        fin = 1;                   /* 防御：没有可发的段了 */
    2478:	00100b13          	li	s6,1
    247c:	de5ff06f          	j	2260 <main+0x115c>
                    }
                }
            }
            /* ============ 逐条下发路径（**默认**，渲染部分一行未改）============ */
            else if (hw_frame_pushed) {
    2480:	04012783          	lw	a5,64(sp)
    2484:	06078863          	beqz	a5,24f4 <main+0x13f0>
                /* 等引擎把本趟画完：**一圈最多读一次 STATUS**，同一个状态字复用。
                 * 轮询节奏：SPLIT/CPU 模式下下面 CPU 段每圈都要画一块，退避会拖慢它
                 * ⇒ 那两种模式每圈照读；纯硬件模式 CPU 侧本来就无活可干 ⇒
                 * 每 4 圈读一次 + 其余圈纯 ALU 退避（与 COPY 窗口同一套参数）。 */
                int poll = ((path != PATH_HW) || ((it & BLT_WAIT_MASK) == 0u)) ? 1 : 0;
    2488:	00200793          	li	a5,2
    248c:	00f91663          	bne	s2,a5,2498 <main+0x1394>
    2490:	0039f793          	andi	a5,s3,3
    2494:	04079663          	bnez	a5,24e0 <main+0x13dc>
                if (poll && blt_idle_st(blt_stat())) {
    2498:	665000ef          	jal	32fc <blt_stat>
    249c:	67d000ef          	jal	3318 <blt_idle_st>
    24a0:	04050063          	beqz	a0,24e0 <main+0x13dc>
                    hw_frames++; hw_frame_pushed = 0; hw_i = 0;
    24a4:	03812783          	lw	a5,56(sp)
    24a8:	00178793          	addi	a5,a5,1
    24ac:	02f12c23          	sw	a5,56(sp)
    24b0:	08012423          	sw	zero,136(sp)
                    hw_fifo_full = 0;          /* 新一趟从"未知"开始，第一圈就正常读 */
                    hw_done = 1;
                    if (clear_pp) repaint_hw = 1;
    24b4:	000c8663          	beqz	s9,24c0 <main+0x13bc>
    24b8:	04012783          	lw	a5,64(sp)
    24bc:	04f12223          	sw	a5,68(sp)
#if FB_TRIPLE_BUFFER
                    g_pass_armed = 0;          /* ★v2.7：下一趟开头重新做"查 clean + 选目标 + 下清屏命令" */
    24c0:	8c01a023          	sw	zero,-1856(gp) # 79b8 <g_pass_armed>
#endif
                    /* ★v2.15 成本行（同口径对照）：本趟是逐条路径推的 + 引擎已空闲 ⇒
                     *   用本趟起点到此刻的墙钟拍数算一次"逐条路径 pi/精灵"，与列表路径那行
                     *   直接比大小。1Hz 门控、稳态每秒最多一行（见 cmd_cost_report）。 */
                    cmd_cost_report(n);
    24c4:	000a0513          	mv	a0,s4
    24c8:	414030ef          	jal	58dc <cmd_cost_report>
                    hw_done = 1;
    24cc:	04012783          	lw	a5,64(sp)
    24d0:	02f12223          	sw	a5,36(sp)
                    hw_fifo_full = 0;          /* 新一趟从"未知"开始，第一圈就正常读 */
    24d4:	05612023          	sw	s6,64(sp)
                    hw_frames++; hw_frame_pushed = 0; hw_i = 0;
    24d8:	05612623          	sw	s6,76(sp)
                    cmd_cost_report(n);
    24dc:	3600006f          	j	283c <main+0x1738>
                } else if (path == PATH_HW) {
    24e0:	00200793          	li	a5,2
    24e4:	34f91c63          	bne	s2,a5,283c <main+0x1738>
                    cpu_backoff(BLT_WAIT_NOP);
    24e8:	03000513          	li	a0,48
    24ec:	24d000ef          	jal	2f38 <cpu_backoff>
    24f0:	34c0006f          	j	283c <main+0x1738>
                }
            } else {
                int y0 = hw_y0(path);
    24f4:	00090513          	mv	a0,s2
    24f8:	1a1020ef          	jal	4e98 <hw_y0>
    24fc:	00050b93          	mv	s7,a0
                 *   先按 BLT_WAIT_MASK 退避几圈再读 —— 引擎取一条指令要几十 us、
                 *   而 FIFO 还有 200 条的缓冲，退避 4*~2us 绝不会把引擎饿着，却能把
                 *   "满时每圈一次 COUNT 读"降到 1/4（N=6000 那种长指令流时才走到这里）。
                 *   SPLIT/CPU 模式不这么干：下面 CPU 段每圈都要画一块，退避会拖慢
                 *   CPU 侧的诚实工作量。 */
                if (hw_fifo_full && path == PATH_HW && ((it & BLT_WAIT_MASK) != 0u)) {
    2500:	04c12783          	lw	a5,76(sp)
    2504:	02078063          	beqz	a5,2524 <main+0x1420>
    2508:	00200793          	li	a5,2
    250c:	00f91c63          	bne	s2,a5,2524 <main+0x1420>
    2510:	0039f793          	andi	a5,s3,3
    2514:	00078863          	beqz	a5,2524 <main+0x1420>
                    cpu_backoff(BLT_WAIT_NOP);
    2518:	03000513          	li	a0,48
    251c:	21d000ef          	jal	2f38 <cpu_backoff>
    2520:	31c0006f          	j	283c <main+0x1738>
                } else {
                    uint32_t room = blt_push_room();
    2524:	605000ef          	jal	3328 <blt_push_room>
    2528:	00050a93          	mv	s5,a0
                    /* ★ 一趟的起点：把场景位置冻进 (tx,ty)（hw_i==0 且上一趟已完成）。
                     *   放在 FIFO 余量判断之前 —— 即使这圈 FIFO 满、一条都推不出去，
                     *   快照也已就位，本趟剩下所有块必然用同一个位置。
                     *   ★v2.15：这**也**是一趟的计时起点（成本行的逐条路径口径）：
                     *   只在本趟还没开始计时时置一次，跑完由 cmd_cost_report() 清零。 */
                    if (hw_i == 0 && snap_hw) { scene_snap(g_sc[SIDE_HW], n); snap_hw = 0; }
    252c:	08812783          	lw	a5,136(sp)
    2530:	00079663          	bnez	a5,253c <main+0x1438>
    2534:	08412783          	lw	a5,132(sp)
    2538:	02079e63          	bnez	a5,2574 <main+0x1470>
                    if (hw_i == 0 && g_cmd_t0 == 0) g_cmd_t0 = tick32();
    253c:	08812783          	lw	a5,136(sp)
    2540:	00079663          	bnez	a5,254c <main+0x1448>
    2544:	83c1a783          	lw	a5,-1988(gp) # 7934 <g_cmd_t0>
    2548:	04078263          	beqz	a5,258c <main+0x1488>
#if FB_FLIP_PUBLISH && FB_TRIPLE_BUFFER
                    /* ---------------- ★v2.7 三缓冲：本趟开画前的一次性动作 ----------------
                     * ①~⑤ 的顺序与理由见 hw_pass_arm() 的注释（列表路径共用同一段）。
                     *   ④ 不干净 → **退回改动前那条命令式区域清屏**（发一条 FILL 整片）：
                     *      语义与老版本逐位相同，宁可多花 568k 周期也绝不在一张脏底上作画。 */
                    if (hw_i == 0 && !g_pass_armed) {
    254c:	08812783          	lw	a5,136(sp)
    2550:	00079663          	bnez	a5,255c <main+0x1458>
    2554:	8c01a783          	lw	a5,-1856(gp) # 79b8 <g_pass_armed>
    2558:	04078063          	beqz	a5,2598 <main+0x1494>
                        g_pass_armed = 1;
                        repaint_hw = hw_pass_arm(y0, hw_h(path));
                    }
#endif
                    if (repaint_hw && room > 0u) {
    255c:	04412783          	lw	a5,68(sp)
    2560:	00078463          	beqz	a5,2568 <main+0x1464>
    2564:	040a9c63          	bnez	s5,25bc <main+0x14b8>
                        blt_fill(g_fb_back + (uint32_t)y0 * FB_STRIDE, FB_STRIDE,
                                 FB_WIDTH, (uint32_t)hw_h(path), COL_BG);
                        repaint_hw = 0;
    2568:	04000793          	li	a5,64
    256c:	05212623          	sw	s2,76(sp)
    2570:	18c0006f          	j	26fc <main+0x15f8>
                    if (hw_i == 0 && snap_hw) { scene_snap(g_sc[SIDE_HW], n); snap_hw = 0; }
    2574:	000a0593          	mv	a1,s4
    2578:	00008537          	lui	a0,0x8
    257c:	a2050513          	addi	a0,a0,-1504 # 7a20 <g_sc>
    2580:	771010ef          	jal	44f0 <scene_snap>
    2584:	08012223          	sw	zero,132(sp)
    2588:	fb5ff06f          	j	253c <main+0x1438>
                    if (hw_i == 0 && g_cmd_t0 == 0) g_cmd_t0 = tick32();
    258c:	1a1000ef          	jal	2f2c <tick32>
    2590:	82a1ae23          	sw	a0,-1988(gp) # 7934 <g_cmd_t0>
    2594:	fb9ff06f          	j	254c <main+0x1448>
                        g_pass_armed = 1;
    2598:	00100713          	li	a4,1
    259c:	8ce1a023          	sw	a4,-1856(gp) # 79b8 <g_pass_armed>
                        repaint_hw = hw_pass_arm(y0, hw_h(path));
    25a0:	00090513          	mv	a0,s2
    25a4:	0fd020ef          	jal	4ea0 <hw_h>
    25a8:	00050593          	mv	a1,a0
    25ac:	000b8513          	mv	a0,s7
    25b0:	371000ef          	jal	3120 <hw_pass_arm>
    25b4:	04a12223          	sw	a0,68(sp)
    25b8:	fa5ff06f          	j	255c <main+0x1458>
                        blt_fill(g_fb_back + (uint32_t)y0 * FB_STRIDE, FB_STRIDE,
    25bc:	78000b13          	li	s6,1920
    25c0:	036b8b33          	mul	s6,s7,s6
    25c4:	82c1a783          	lw	a5,-2004(gp) # 7924 <g_fb_back>
    25c8:	00fb0b33          	add	s6,s6,a5
                                 FB_WIDTH, (uint32_t)hw_h(path), COL_BG);
    25cc:	00090513          	mv	a0,s2
    25d0:	0d1020ef          	jal	4ea0 <hw_h>
    25d4:	00050693          	mv	a3,a0
                        blt_fill(g_fb_back + (uint32_t)y0 * FB_STRIDE, FB_STRIDE,
    25d8:	00800713          	li	a4,8
    25dc:	3c000613          	li	a2,960
    25e0:	78000593          	li	a1,1920
    25e4:	000b0513          	mv	a0,s6
    25e8:	5b5000ef          	jal	339c <blt_fill>
                        room--;
    25ec:	fffa8a93          	addi	s5,s5,-1
                        repaint_hw = 0;
    25f0:	04012783          	lw	a5,64(sp)
    25f4:	04f12223          	sw	a5,68(sp)
    25f8:	f71ff06f          	j	2568 <main+0x1464>
                         *   其余可以"没动就不擦"。FILL/KEY 是幂等的（重画同一块结果不变），
                         *   而 ALPHA 是 dest = blend(src, dest) —— 不擦就再混一次 ⇒ 一次比
                         *   一次暗。板级现象正是：方块不动时逐帧变暗、每次场景步进（移动后
                         *   才擦）亮度恢复 ⇒ 以 25Hz 周期性忽明忽暗。
                         *   擦 + 画是两条引擎指令 ⇒ need=2，两条一起凑够余量才发，绝不半发。 */
                        if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
    25fc:	000087b7          	lui	a5,0x8
    2600:	00249713          	slli	a4,s1,0x2
    2604:	00970733          	add	a4,a4,s1
    2608:	00271713          	slli	a4,a4,0x2
    260c:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    2610:	00e787b3          	add	a5,a5,a4
    2614:	00a79703          	lh	a4,10(a5)
    2618:	00e79783          	lh	a5,14(a5)
    261c:	00f70663          	beq	a4,a5,2628 <main+0x1524>
                            need = 2u;
    2620:	00200913          	li	s2,2
    2624:	0100006f          	j	2634 <main+0x1530>
                        uint32_t need = 1u;
    2628:	00100913          	li	s2,1
    262c:	0080006f          	j	2634 <main+0x1530>
    2630:	00100913          	li	s2,1
                        if (room < need) break;
    2634:	1f2ae063          	bltu	s5,s2,2814 <main+0x1710>
                        if (need == 2u)
    2638:	00200793          	li	a5,2
    263c:	10f90a63          	beq	s2,a5,2750 <main+0x164c>
                            blt_fill(g_fb_back + (uint32_t)(b->dy + y0) * FB_STRIDE
                                              + (uint32_t)b->dx * 2u,
                                     FB_STRIDE, b->sz, b->sz, COL_BG);
                        {                                              /* 立刻画到本趟快照位置 */
                            uint32_t dst = g_fb_back + (uint32_t)(b->ty + y0) * FB_STRIDE
    2640:	000087b7          	lui	a5,0x8
    2644:	00249713          	slli	a4,s1,0x2
    2648:	00970733          	add	a4,a4,s1
    264c:	00271713          	slli	a4,a4,0x2
    2650:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    2654:	00e787b3          	add	a5,a5,a4
    2658:	00e79703          	lh	a4,14(a5)
    265c:	01770733          	add	a4,a4,s7
                                                 + (uint32_t)b->tx * 2u;
    2660:	00c79683          	lh	a3,12(a5)
    2664:	00471793          	slli	a5,a4,0x4
    2668:	40e787b3          	sub	a5,a5,a4
    266c:	00679793          	slli	a5,a5,0x6
    2670:	00d787b3          	add	a5,a5,a3
    2674:	00179793          	slli	a5,a5,0x1
    2678:	82c1a703          	lw	a4,-2004(gp) # 7924 <g_fb_back>
                            uint32_t dst = g_fb_back + (uint32_t)(b->ty + y0) * FB_STRIDE
    267c:	00e78533          	add	a0,a5,a4
                            if (scene == SC_FILL)
    2680:	120d0463          	beqz	s10,27a8 <main+0x16a4>
                                blt_fill(dst, FB_STRIDE, b->sz, b->sz, b->color);
                            else if (scene == SC_ALPHA)
    2684:	00100793          	li	a5,1
    2688:	14fd0863          	beq	s10,a5,27d8 <main+0x16d4>
                                blt_alpha(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE,
                                          SPR_W, SPR_H, alpha);
                            else
                                blt_key(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE,
    268c:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    2690:	00010837          	lui	a6,0x10
    2694:	81f80813          	addi	a6,a6,-2017 # f81f <__global_pointer$+0x7727>
    2698:	00078713          	mv	a4,a5
    269c:	78000693          	li	a3,1920
    26a0:	00179613          	slli	a2,a5,0x1
    26a4:	00050593          	mv	a1,a0
    26a8:	00201537          	lui	a0,0x201
    26ac:	569000ef          	jal	3414 <blt_key>
                                        SPR_W, SPR_H, KEY_COLOR);
                        }
                        b->dx = b->tx; b->dy = b->ty;                  /* 记账：画的就是快照位置 */
    26b0:	00008737          	lui	a4,0x8
    26b4:	a2070713          	addi	a4,a4,-1504 # 7a20 <g_sc>
    26b8:	00249693          	slli	a3,s1,0x2
    26bc:	009687b3          	add	a5,a3,s1
    26c0:	00279793          	slli	a5,a5,0x2
    26c4:	00f707b3          	add	a5,a4,a5
    26c8:	00c79603          	lh	a2,12(a5)
    26cc:	00c79423          	sh	a2,8(a5)
    26d0:	00e79783          	lh	a5,14(a5)
    26d4:	009686b3          	add	a3,a3,s1
    26d8:	00269693          	slli	a3,a3,0x2
    26dc:	00d70733          	add	a4,a4,a3
    26e0:	00f71523          	sh	a5,10(a4)
                        room -= need;
    26e4:	412a8ab3          	sub	s5,s5,s2
                        if (++hw_i >= n) { hw_frame_pushed = 1; break; }
    26e8:	08812783          	lw	a5,136(sp)
    26ec:	00178793          	addi	a5,a5,1
    26f0:	08f12423          	sw	a5,136(sp)
    26f4:	1147d863          	bge	a5,s4,2804 <main+0x1700>
                    while (hw_i < n && room > 0u && budget-- > 0u) {
    26f8:	000b0793          	mv	a5,s6
    26fc:	08812483          	lw	s1,136(sp)
    2700:	1144de63          	bge	s1,s4,281c <main+0x1718>
    2704:	120a8463          	beqz	s5,282c <main+0x1728>
    2708:	fff78b13          	addi	s6,a5,-1
    270c:	0e078863          	beqz	a5,27fc <main+0x16f8>
                        if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
    2710:	f20c90e3          	bnez	s9,2630 <main+0x152c>
    2714:	00100793          	li	a5,1
    2718:	02fd0863          	beq	s10,a5,2748 <main+0x1644>
    271c:	000087b7          	lui	a5,0x8
    2720:	00249713          	slli	a4,s1,0x2
    2724:	00970733          	add	a4,a4,s1
    2728:	00271713          	slli	a4,a4,0x2
    272c:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    2730:	00e787b3          	add	a5,a5,a4
    2734:	00879703          	lh	a4,8(a5)
    2738:	00c79783          	lh	a5,12(a5)
    273c:	ecf700e3          	beq	a4,a5,25fc <main+0x14f8>
                            need = 2u;
    2740:	00200913          	li	s2,2
    2744:	ef1ff06f          	j	2634 <main+0x1530>
    2748:	00200913          	li	s2,2
    274c:	ee9ff06f          	j	2634 <main+0x1530>
                            blt_fill(g_fb_back + (uint32_t)(b->dy + y0) * FB_STRIDE
    2750:	00008737          	lui	a4,0x8
    2754:	00249793          	slli	a5,s1,0x2
    2758:	009787b3          	add	a5,a5,s1
    275c:	00279793          	slli	a5,a5,0x2
    2760:	a2070713          	addi	a4,a4,-1504 # 7a20 <g_sc>
    2764:	00f70733          	add	a4,a4,a5
    2768:	00a71683          	lh	a3,10(a4)
    276c:	017686b3          	add	a3,a3,s7
                                              + (uint32_t)b->dx * 2u,
    2770:	00871603          	lh	a2,8(a4)
    2774:	00469793          	slli	a5,a3,0x4
    2778:	40d787b3          	sub	a5,a5,a3
    277c:	00679793          	slli	a5,a5,0x6
    2780:	00c787b3          	add	a5,a5,a2
    2784:	00179793          	slli	a5,a5,0x1
    2788:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
                                     FB_STRIDE, b->sz, b->sz, COL_BG);
    278c:	01274603          	lbu	a2,18(a4)
                            blt_fill(g_fb_back + (uint32_t)(b->dy + y0) * FB_STRIDE
    2790:	00800713          	li	a4,8
    2794:	00060693          	mv	a3,a2
    2798:	78000593          	li	a1,1920
    279c:	00a78533          	add	a0,a5,a0
    27a0:	3fd000ef          	jal	339c <blt_fill>
    27a4:	e9dff06f          	j	2640 <main+0x153c>
                                blt_fill(dst, FB_STRIDE, b->sz, b->sz, b->color);
    27a8:	000087b7          	lui	a5,0x8
    27ac:	00249713          	slli	a4,s1,0x2
    27b0:	00970733          	add	a4,a4,s1
    27b4:	00271713          	slli	a4,a4,0x2
    27b8:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    27bc:	00e787b3          	add	a5,a5,a4
    27c0:	0127c603          	lbu	a2,18(a5)
    27c4:	0107d703          	lhu	a4,16(a5)
    27c8:	00060693          	mv	a3,a2
    27cc:	78000593          	li	a1,1920
    27d0:	3cd000ef          	jal	339c <blt_fill>
    27d4:	eddff06f          	j	26b0 <main+0x15ac>
                                blt_alpha(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE,
    27d8:	8201a783          	lw	a5,-2016(gp) # 7918 <g_blk>
    27dc:	03012803          	lw	a6,48(sp)
    27e0:	00078713          	mv	a4,a5
    27e4:	78000693          	li	a3,1920
    27e8:	00179613          	slli	a2,a5,0x1
    27ec:	00050593          	mv	a1,a0
    27f0:	00201537          	lui	a0,0x201
    27f4:	3e5000ef          	jal	33d8 <blt_alpha>
    27f8:	eb9ff06f          	j	26b0 <main+0x15ac>
    27fc:	04c12903          	lw	s2,76(sp)
    2800:	0200006f          	j	2820 <main+0x171c>
                        if (++hw_i >= n) { hw_frame_pushed = 1; break; }
    2804:	04c12903          	lw	s2,76(sp)
    2808:	00100793          	li	a5,1
    280c:	04f12023          	sw	a5,64(sp)
    2810:	0100006f          	j	2820 <main+0x171c>
    2814:	04c12903          	lw	s2,76(sp)
    2818:	0080006f          	j	2820 <main+0x171c>
    281c:	04c12903          	lw	s2,76(sp)
                    }
                    hw_fifo_full = (room == 0u) ? 1 : 0;   /* 满了 ⇒ 下一圈先退避 */
    2820:	001ab793          	seqz	a5,s5
    2824:	04f12623          	sw	a5,76(sp)
    2828:	0140006f          	j	283c <main+0x1738>
    282c:	04c12903          	lw	s2,76(sp)
    2830:	ff1ff06f          	j	2820 <main+0x171c>
                        hw_i = 0; hw_frame_pushed = 0; repaint_hw = 1;
    2834:	00100793          	li	a5,1
    2838:	04f12223          	sw	a5,68(sp)
        }

        /* ---------------- CPU 侧：每圈一块，相邻式擦+画，同样用本趟快照 ----------------
         * ★ 语义与 comptest2 完全一致（先擦后画、逐块擦旧矩形），**不跟随 clear_pp**：
         *   这是"纯 CPU"该有的工作量，动了它 CPU-vs-HW 的帧率对比就不诚实了。 */
        if (!back_busy && path != PATH_HW) {
    283c:	14041263          	bnez	s0,2980 <main+0x187c>
    2840:	00200793          	li	a5,2
    2844:	12f90e63          	beq	s2,a5,2980 <main+0x187c>
            int y0 = cpu_y0(path);
    2848:	00090513          	mv	a0,s2
    284c:	668020ef          	jal	4eb4 <cpu_y0>
    2850:	00050a93          	mv	s5,a0
            blk_t *b;
            /* 一趟的起点（cpu_i==0）：CPU 侧的快照点，与硬件侧同理 */
            if (cpu_i == 0 && snap_cpu) { scene_snap(g_sc[SIDE_CPU], n); snap_cpu = 0; }
    2854:	01812783          	lw	a5,24(sp)
    2858:	00079663          	bnez	a5,2864 <main+0x1760>
    285c:	08012783          	lw	a5,128(sp)
    2860:	24079a63          	bnez	a5,2ab4 <main+0x19b0>
            if (repaint_cpu) {                 /* 场景/路径刚变过 → 先把这片区域铺背景 */
    2864:	02c12783          	lw	a5,44(sp)
    2868:	26079263          	bnez	a5,2acc <main+0x19c8>
                cpu_fill32(g_fb_back, 0, cpu_y0(path), FB_WIDTH, cpu_h(path), COL_BG);
                repaint_cpu = 0;
            }
            b = &g_sc[SIDE_CPU][cpu_i];
            /* 同硬件侧：ALPHA 必须每次重铺背景（否则混合逐次叠加、越来越暗） */
            if ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty))
    286c:	00100793          	li	a5,1
    2870:	02fd0a63          	beq	s10,a5,28a4 <main+0x17a0>
    2874:	000087b7          	lui	a5,0x8
    2878:	01812683          	lw	a3,24(sp)
    287c:	00269713          	slli	a4,a3,0x2
    2880:	00d70733          	add	a4,a4,a3
    2884:	00271713          	slli	a4,a4,0x2
    2888:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    288c:	00e787b3          	add	a5,a5,a4
    2890:	0001d737          	lui	a4,0x1d
    2894:	00f707b3          	add	a5,a4,a5
    2898:	4c879703          	lh	a4,1224(a5)
    289c:	4cc79783          	lh	a5,1228(a5)
    28a0:	24f70e63          	beq	a4,a5,2afc <main+0x19f8>
                cpu_fill32(g_fb_back, b->dx, b->dy + y0, b->sz, b->sz, COL_BG);
    28a4:	000087b7          	lui	a5,0x8
    28a8:	01812683          	lw	a3,24(sp)
    28ac:	00269713          	slli	a4,a3,0x2
    28b0:	00d70733          	add	a4,a4,a3
    28b4:	00271713          	slli	a4,a4,0x2
    28b8:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    28bc:	00e787b3          	add	a5,a5,a4
    28c0:	0001d837          	lui	a6,0x1d
    28c4:	00f80833          	add	a6,a6,a5
    28c8:	4ca81603          	lh	a2,1226(a6) # 1d4ca <__global_pointer$+0x153d2>
    28cc:	4d284683          	lbu	a3,1234(a6)
    28d0:	00800793          	li	a5,8
    28d4:	00068713          	mv	a4,a3
    28d8:	01560633          	add	a2,a2,s5
    28dc:	4c881583          	lh	a1,1224(a6)
    28e0:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    28e4:	615000ef          	jal	36f8 <cpu_fill32>
            if (scene == SC_FILL)
    28e8:	240d0263          	beqz	s10,2b2c <main+0x1a28>
                cpu_fill32(g_fb_back, b->tx, b->ty + y0, b->sz, b->sz, b->color);
            else if (scene == SC_ALPHA)
    28ec:	00100793          	li	a5,1
    28f0:	28fd0263          	beq	s10,a5,2b74 <main+0x1a70>
                cpu_alpha_sprite(b->tx, b->ty + y0, alpha);
            else
                cpu_key_sprite(b->tx, b->ty + y0);
    28f4:	000087b7          	lui	a5,0x8
    28f8:	01812683          	lw	a3,24(sp)
    28fc:	00269713          	slli	a4,a3,0x2
    2900:	00d70733          	add	a4,a4,a3
    2904:	00271713          	slli	a4,a4,0x2
    2908:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    290c:	00e787b3          	add	a5,a5,a4
    2910:	0001d737          	lui	a4,0x1d
    2914:	00f707b3          	add	a5,a4,a5
    2918:	4ce79583          	lh	a1,1230(a5)
    291c:	015585b3          	add	a1,a1,s5
    2920:	4cc79503          	lh	a0,1228(a5)
    2924:	044010ef          	jal	3968 <cpu_key_sprite>
            b->dx = b->tx; b->dy = b->ty;
    2928:	00008737          	lui	a4,0x8
    292c:	01812683          	lw	a3,24(sp)
    2930:	00269793          	slli	a5,a3,0x2
    2934:	00d787b3          	add	a5,a5,a3
    2938:	00279793          	slli	a5,a5,0x2
    293c:	a2070713          	addi	a4,a4,-1504 # 7a20 <g_sc>
    2940:	00f70733          	add	a4,a4,a5
    2944:	0001d7b7          	lui	a5,0x1d
    2948:	00e787b3          	add	a5,a5,a4
    294c:	4cc79703          	lh	a4,1228(a5) # 1d4cc <__global_pointer$+0x153d4>
    2950:	4ce79423          	sh	a4,1224(a5)
    2954:	4ce79703          	lh	a4,1230(a5)
    2958:	4ce79523          	sh	a4,1226(a5)
            if (++cpu_i >= n) {
    295c:	00168793          	addi	a5,a3,1
    2960:	00f12c23          	sw	a5,24(sp)
    2964:	0147ce63          	blt	a5,s4,2980 <main+0x187c>
                cpu_i = 0; cpu_frames++;
    2968:	01c12783          	lw	a5,28(sp)
    296c:	00178793          	addi	a5,a5,1
    2970:	00f12e23          	sw	a5,28(sp)
    2974:	00812c23          	sw	s0,24(sp)
                cpu_done = 1;
    2978:	00100793          	li	a5,1
    297c:	02f12023          	sw	a5,32(sp)
         *   就轮到它上屏。所以判据多一个 `!g_bar_ok[]`：内容变了（两个缓冲都作废）
         *   或本缓冲还没画过就重画。稳态下每个缓冲每种内容只画一次。 */
#if FB_FLIP_PUBLISH
#if FB_TRIPLE_BUFFER
        /* ★v2.7 三缓冲：信息条要落在**当前正在画的那块**（g_draw3）里 —— 下一趟就轮到它上屏 */
        if (!back_busy && (g_osd_dirty || !g_bar_ok[g_draw3])) {
    2980:	06041463          	bnez	s0,29e8 <main+0x18e4>
    2984:	8181a783          	lw	a5,-2024(gp) # 7910 <g_osd_dirty>
    2988:	00079c63          	bnez	a5,29a0 <main+0x189c>
    298c:	8281a783          	lw	a5,-2008(gp) # 7920 <g_draw3>
    2990:	8c818713          	addi	a4,gp,-1848 # 79c0 <g_bar_ok>
    2994:	00e787b3          	add	a5,a5,a4
    2998:	0007c783          	lbu	a5,0(a5)
    299c:	04079663          	bnez	a5,29e8 <main+0x18e4>
            osd_blit(g_osd_line, path_label(path));
    29a0:	00090513          	mv	a0,s2
    29a4:	34c010ef          	jal	3cf0 <path_label>
    29a8:	00050593          	mv	a1,a0
    29ac:	8e418513          	addi	a0,gp,-1820 # 79dc <g_osd_line>
    29b0:	684010ef          	jal	4034 <osd_blit>
            /* 分隔条只在分屏模式画：单模式是整屏渲染，中间不该有一条线 */
            if (path == PATH_SPLIT)
    29b4:	1e090e63          	beqz	s2,2bb0 <main+0x1aac>
                cpu_fill32(g_fb_back, 0, TOP_Y0 + HALF_H, FB_WIDTH, SEP_H, COL_SEP);
            if (g_osd_dirty) { g_bar_ok[0] = 0; g_bar_ok[1] = 0; g_bar_ok[2] = 0; }
    29b8:	8181a783          	lw	a5,-2024(gp) # 7910 <g_osd_dirty>
    29bc:	00078a63          	beqz	a5,29d0 <main+0x18cc>
    29c0:	8c018423          	sb	zero,-1848(gp) # 79c0 <g_bar_ok>
    29c4:	8c818793          	addi	a5,gp,-1848 # 79c0 <g_bar_ok>
    29c8:	000780a3          	sb	zero,1(a5)
    29cc:	00078123          	sb	zero,2(a5)
            g_bar_ok[g_draw3] = 1;
    29d0:	8281a783          	lw	a5,-2008(gp) # 7920 <g_draw3>
    29d4:	8c818713          	addi	a4,gp,-1848 # 79c0 <g_bar_ok>
    29d8:	00e787b3          	add	a5,a5,a4
    29dc:	00100713          	li	a4,1
    29e0:	00e78023          	sb	a4,0(a5)
            g_osd_dirty = 0;
    29e4:	8001ac23          	sw	zero,-2024(gp) # 7910 <g_osd_dirty>
        it++;
    29e8:	00198993          	addi	s3,s3,1
        if ((it & SLOW_MASK) == 0u) {
    29ec:	01f9fa93          	andi	s5,s3,31
    29f0:	000a9463          	bnez	s5,29f8 <main+0x18f4>
    29f4:	b21fe06f          	j	1514 <main+0x410>
        if (back_busy) {
    29f8:	00041463          	bnez	s0,2a00 <main+0x18fc>
    29fc:	a34ff06f          	j	1c30 <main+0xb2c>
            if (snap_hw)  { scene_snap(g_sc[SIDE_HW],  n); snap_hw  = 0; }
    2a00:	08412783          	lw	a5,132(sp)
    2a04:	00078463          	beqz	a5,2a0c <main+0x1908>
    2a08:	800ff06f          	j	1a08 <main+0x904>
            if (snap_cpu) { scene_snap(g_sc[SIDE_CPU], n); snap_cpu = 0; }
    2a0c:	08012783          	lw	a5,128(sp)
    2a10:	00078463          	beqz	a5,2a18 <main+0x1914>
    2a14:	80cff06f          	j	1a20 <main+0x91c>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    2a18:	8ac1a703          	lw	a4,-1876(gp) # 79a4 <g_osd_t0>
    2a1c:	40ec0733          	sub	a4,s8,a4
    2a20:	05f5e7b7          	lui	a5,0x5f5e
    2a24:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f1ad5f>
    2a28:	00e7f463          	bgeu	a5,a4,2a30 <main+0x192c>
    2a2c:	80cff06f          	j	1a38 <main+0x934>
            if ((it & BLT_WAIT_MASK) == 0u) {
    2a30:	0039f793          	andi	a5,s3,3
    2a34:	00078463          	beqz	a5,2a3c <main+0x1938>
    2a38:	92cff06f          	j	1b64 <main+0xa60>
                    uint32_t irq = blt_rd(BLT_IRQ_STATUS);
    2a3c:	01000513          	li	a0,16
    2a40:	518000ef          	jal	2f58 <blt_rd>
                    if (irq & BLT_IRQ_FRAME) {
    2a44:	00257513          	andi	a0,a0,2
    2a48:	02050063          	beqz	a0,2a68 <main+0x1964>
                        blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);   /* W1C：清本场中断 */
    2a4c:	00200593          	li	a1,2
    2a50:	01000513          	li	a0,16
    2a54:	4f4000ef          	jal	2f48 <blt_wr>
                if (flip_ev && (fb_stat_sel() == g_flip_req)) {
    2a58:	538000ef          	jal	2f90 <fb_stat_sel>
    2a5c:	8d01a783          	lw	a5,-1840(gp) # 79c8 <g_flip_req>
    2a60:	00f51463          	bne	a0,a5,2a68 <main+0x1964>
    2a64:	824ff06f          	j	1a88 <main+0x984>
                } else if ((uint32_t)(tick32() - back_t0) > (uint32_t)FLIP_TIMEOUT_TICKS) {
    2a68:	4c4000ef          	jal	2f2c <tick32>
    2a6c:	02812783          	lw	a5,40(sp)
    2a70:	40f50533          	sub	a0,a0,a5
    2a74:	009897b7          	lui	a5,0x989
    2a78:	68078793          	addi	a5,a5,1664 # 989680 <__freertos_irq_stack_top+0x9462e0>
    2a7c:	00a7e463          	bltu	a5,a0,2a84 <main+0x1980>
    2a80:	8d8ff06f          	j	1b58 <main+0xa54>
                    g_flip_to++;
    2a84:	8cc1a783          	lw	a5,-1844(gp) # 79c4 <g_flip_to>
    2a88:	00178793          	addi	a5,a5,1
    2a8c:	8cf1a623          	sw	a5,-1844(gp) # 79c4 <g_flip_to>
                    if (g_flip_to == 1u)
    2a90:	00100713          	li	a4,1
    2a94:	00e79463          	bne	a5,a4,2a9c <main+0x1998>
    2a98:	8a4ff06f          	j	1b3c <main+0xa38>
                    blt_wr(BLT_FB_SEL, g_flip_req);       /* 重发请求，继续有界等待 */
    2a9c:	8d01a583          	lw	a1,-1840(gp) # 79c8 <g_flip_req>
    2aa0:	02400513          	li	a0,36
    2aa4:	4a4000ef          	jal	2f48 <blt_wr>
                    back_t0 = tick32();
    2aa8:	484000ef          	jal	2f2c <tick32>
    2aac:	02a12423          	sw	a0,40(sp)
    2ab0:	8bcff06f          	j	1b6c <main+0xa68>
            if (cpu_i == 0 && snap_cpu) { scene_snap(g_sc[SIDE_CPU], n); snap_cpu = 0; }
    2ab4:	000a0593          	mv	a1,s4
    2ab8:	00025537          	lui	a0,0x25
    2abc:	ee050513          	addi	a0,a0,-288 # 24ee0 <__global_pointer$+0x1cde8>
    2ac0:	231010ef          	jal	44f0 <scene_snap>
    2ac4:	08012023          	sw	zero,128(sp)
    2ac8:	d9dff06f          	j	2864 <main+0x1760>
                cpu_fill32(g_fb_back, 0, cpu_y0(path), FB_WIDTH, cpu_h(path), COL_BG);
    2acc:	82c1ab03          	lw	s6,-2004(gp) # 7924 <g_fb_back>
    2ad0:	00090513          	mv	a0,s2
    2ad4:	3f4020ef          	jal	4ec8 <cpu_h>
    2ad8:	00050713          	mv	a4,a0
    2adc:	00800793          	li	a5,8
    2ae0:	3c000693          	li	a3,960
    2ae4:	000a8613          	mv	a2,s5
    2ae8:	00000593          	li	a1,0
    2aec:	000b0513          	mv	a0,s6
    2af0:	409000ef          	jal	36f8 <cpu_fill32>
                repaint_cpu = 0;
    2af4:	02812623          	sw	s0,44(sp)
    2af8:	d75ff06f          	j	286c <main+0x1768>
            if ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty))
    2afc:	000087b7          	lui	a5,0x8
    2b00:	00269713          	slli	a4,a3,0x2
    2b04:	00d70733          	add	a4,a4,a3
    2b08:	00271713          	slli	a4,a4,0x2
    2b0c:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    2b10:	00e787b3          	add	a5,a5,a4
    2b14:	0001d737          	lui	a4,0x1d
    2b18:	00f707b3          	add	a5,a4,a5
    2b1c:	4ca79703          	lh	a4,1226(a5)
    2b20:	4ce79783          	lh	a5,1230(a5)
    2b24:	d8f710e3          	bne	a4,a5,28a4 <main+0x17a0>
    2b28:	dc1ff06f          	j	28e8 <main+0x17e4>
                cpu_fill32(g_fb_back, b->tx, b->ty + y0, b->sz, b->sz, b->color);
    2b2c:	000087b7          	lui	a5,0x8
    2b30:	01812683          	lw	a3,24(sp)
    2b34:	00269713          	slli	a4,a3,0x2
    2b38:	00d70733          	add	a4,a4,a3
    2b3c:	00271713          	slli	a4,a4,0x2
    2b40:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    2b44:	00e787b3          	add	a5,a5,a4
    2b48:	0001d5b7          	lui	a1,0x1d
    2b4c:	00f585b3          	add	a1,a1,a5
    2b50:	4ce59603          	lh	a2,1230(a1) # 1d4ce <__global_pointer$+0x153d6>
    2b54:	4d25c683          	lbu	a3,1234(a1)
    2b58:	4d05d783          	lhu	a5,1232(a1)
    2b5c:	00068713          	mv	a4,a3
    2b60:	01560633          	add	a2,a2,s5
    2b64:	4cc59583          	lh	a1,1228(a1)
    2b68:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    2b6c:	38d000ef          	jal	36f8 <cpu_fill32>
    2b70:	db9ff06f          	j	2928 <main+0x1824>
                cpu_alpha_sprite(b->tx, b->ty + y0, alpha);
    2b74:	000087b7          	lui	a5,0x8
    2b78:	01812683          	lw	a3,24(sp)
    2b7c:	00269713          	slli	a4,a3,0x2
    2b80:	00d70733          	add	a4,a4,a3
    2b84:	00271713          	slli	a4,a4,0x2
    2b88:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    2b8c:	00e787b3          	add	a5,a5,a4
    2b90:	0001d737          	lui	a4,0x1d
    2b94:	00f707b3          	add	a5,a4,a5
    2b98:	4ce79583          	lh	a1,1230(a5)
    2b9c:	03012603          	lw	a2,48(sp)
    2ba0:	015585b3          	add	a1,a1,s5
    2ba4:	4cc79503          	lh	a0,1228(a5)
    2ba8:	4ed000ef          	jal	3894 <cpu_alpha_sprite>
    2bac:	d7dff06f          	j	2928 <main+0x1824>
                cpu_fill32(g_fb_back, 0, TOP_Y0 + HALF_H, FB_WIDTH, SEP_H, COL_SEP);
    2bb0:	000047b7          	lui	a5,0x4
    2bb4:	20878793          	addi	a5,a5,520 # 4208 <nline_feed+0xec>
    2bb8:	00400713          	li	a4,4
    2bbc:	3c000693          	li	a3,960
    2bc0:	11400613          	li	a2,276
    2bc4:	00000593          	li	a1,0
    2bc8:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    2bcc:	32d000ef          	jal	36f8 <cpu_fill32>
    2bd0:	de9ff06f          	j	29b8 <main+0x18b4>

00002bd4 <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    2bd4:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    2bd8:	01055513          	srli	a0,a0,0x10
    }
    2bdc:	0ff57513          	zext.b	a0,a0
    2be0:	00008067          	ret

00002be4 <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    2be4:	ff010113          	addi	sp,sp,-16
    2be8:	00112623          	sw	ra,12(sp)
    2bec:	00812423          	sw	s0,8(sp)
    2bf0:	00912223          	sw	s1,4(sp)
    2bf4:	00050413          	mv	s0,a0
    2bf8:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    2bfc:	00040513          	mv	a0,s0
    2c00:	fd5ff0ef          	jal	2bd4 <uart_writeAvailability>
    2c04:	fe050ce3          	beqz	a0,2bfc <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    2c08:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    2c0c:	00c12083          	lw	ra,12(sp)
    2c10:	00812403          	lw	s0,8(sp)
    2c14:	00412483          	lw	s1,4(sp)
    2c18:	01010113          	addi	sp,sp,16
    2c1c:	00008067          	ret

00002c20 <uart_applyConfig>:
*          value using data length, parity, and stop bit settings from the configuration
*          structure, and writes this value to the UART frame configuration register.
*
******************************************************************************/
    static void uart_applyConfig(u32 reg, Uart_Config *config){
        write_u32(config->clockDivider, reg + UART_CLOCK_DIVIDER);
    2c20:	00c5a783          	lw	a5,12(a1)
    2c24:	00f52423          	sw	a5,8(a0)
        write_u32(((config->dataLength-1) << 0) | (config->parity << 8) | (config->stop << 16), reg + UART_FRAME_CONFIG);
    2c28:	0005a783          	lw	a5,0(a1)
    2c2c:	fff78793          	addi	a5,a5,-1
    2c30:	0045a703          	lw	a4,4(a1)
    2c34:	00871713          	slli	a4,a4,0x8
    2c38:	00e7e7b3          	or	a5,a5,a4
    2c3c:	0085a703          	lw	a4,8(a1)
    2c40:	01071713          	slli	a4,a4,0x10
    2c44:	00e7e7b3          	or	a5,a5,a4
    2c48:	00f52623          	sw	a5,12(a0)
    }
    2c4c:	00008067          	ret

00002c50 <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    2c50:	ff010113          	addi	sp,sp,-16
    2c54:	00112623          	sw	ra,12(sp)
    2c58:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    2c5c:	f8010537          	lui	a0,0xf8010
    2c60:	f85ff0ef          	jal	2be4 <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    2c64:	00c12083          	lw	ra,12(sp)
    2c68:	01010113          	addi	sp,sp,16
    2c6c:	00008067          	ret

00002c70 <_putchar_s>:

    static void _putchar_s(char *p)
    {
    2c70:	ff010113          	addi	sp,sp,-16
    2c74:	00112623          	sw	ra,12(sp)
    2c78:	00812423          	sw	s0,8(sp)
    2c7c:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    2c80:	00c0006f          	j	2c8c <_putchar_s+0x1c>
            _putchar(*(p++));
    2c84:	00140413          	addi	s0,s0,1
    2c88:	fc9ff0ef          	jal	2c50 <_putchar>
        while (*p)
    2c8c:	00044503          	lbu	a0,0(s0)
    2c90:	fe051ae3          	bnez	a0,2c84 <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    2c94:	00c12083          	lw	ra,12(sp)
    2c98:	00812403          	lw	s0,8(sp)
    2c9c:	01010113          	addi	sp,sp,16
    2ca0:	00008067          	ret

00002ca4 <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    2ca4:	ff010113          	addi	sp,sp,-16
    2ca8:	00112623          	sw	ra,12(sp)
    2cac:	00812423          	sw	s0,8(sp)
    2cb0:	00912223          	sw	s1,4(sp)
    2cb4:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2cb8:	01c00413          	li	s0,28
    2cbc:	0240006f          	j	2ce0 <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    2cc0:	0084d733          	srl	a4,s1,s0
    2cc4:	00f77713          	andi	a4,a4,15
    2cc8:	000067b7          	lui	a5,0x6
    2ccc:	e0078793          	addi	a5,a5,-512 # 5e00 <_data>
    2cd0:	00e787b3          	add	a5,a5,a4
    2cd4:	0007c503          	lbu	a0,0(a5)
    2cd8:	f79ff0ef          	jal	2c50 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2cdc:	ffc40413          	addi	s0,s0,-4
    2ce0:	fe0450e3          	bgez	s0,2cc0 <bsp_printHex+0x1c>
        }
    }
    2ce4:	00c12083          	lw	ra,12(sp)
    2ce8:	00812403          	lw	s0,8(sp)
    2cec:	00412483          	lw	s1,4(sp)
    2cf0:	01010113          	addi	sp,sp,16
    2cf4:	00008067          	ret

00002cf8 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    2cf8:	ff010113          	addi	sp,sp,-16
    2cfc:	00112623          	sw	ra,12(sp)
    2d00:	00812423          	sw	s0,8(sp)
    2d04:	00912223          	sw	s1,4(sp)
    2d08:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2d0c:	01c00413          	li	s0,28
    2d10:	0240006f          	j	2d34 <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    2d14:	0084d733          	srl	a4,s1,s0
    2d18:	00f77713          	andi	a4,a4,15
    2d1c:	000067b7          	lui	a5,0x6
    2d20:	e1478793          	addi	a5,a5,-492 # 5e14 <_data+0x14>
    2d24:	00e787b3          	add	a5,a5,a4
    2d28:	0007c503          	lbu	a0,0(a5)
    2d2c:	f25ff0ef          	jal	2c50 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2d30:	ffc40413          	addi	s0,s0,-4
    2d34:	fe0450e3          	bgez	s0,2d14 <bsp_printHex_lower+0x1c>

        }
    }
    2d38:	00c12083          	lw	ra,12(sp)
    2d3c:	00812403          	lw	s0,8(sp)
    2d40:	00412483          	lw	s1,4(sp)
    2d44:	01010113          	addi	sp,sp,16
    2d48:	00008067          	ret

00002d4c <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    2d4c:	ff010113          	addi	sp,sp,-16
    2d50:	00112623          	sw	ra,12(sp)
        _putchar(c);
    2d54:	0ff57513          	zext.b	a0,a0
    2d58:	ef9ff0ef          	jal	2c50 <_putchar>
    }
    2d5c:	00c12083          	lw	ra,12(sp)
    2d60:	01010113          	addi	sp,sp,16
    2d64:	00008067          	ret

00002d68 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    2d68:	ff010113          	addi	sp,sp,-16
    2d6c:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    2d70:	f01ff0ef          	jal	2c70 <_putchar_s>
    }
    2d74:	00c12083          	lw	ra,12(sp)
    2d78:	01010113          	addi	sp,sp,16
    2d7c:	00008067          	ret

00002d80 <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    2d80:	fd010113          	addi	sp,sp,-48
    2d84:	02112623          	sw	ra,44(sp)
    2d88:	02812423          	sw	s0,40(sp)
    2d8c:	02912223          	sw	s1,36(sp)
    2d90:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    2d94:	00054663          	bltz	a0,2da0 <bsp_printf_d+0x20>
    {
    2d98:	00010413          	mv	s0,sp
    2d9c:	02c0006f          	j	2dc8 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    2da0:	02d00513          	li	a0,45
    2da4:	fa9ff0ef          	jal	2d4c <bsp_printf_c>
            val = -val;
    2da8:	409004b3          	neg	s1,s1
    2dac:	fedff06f          	j	2d98 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    2db0:	00a00713          	li	a4,10
    2db4:	02e4e7b3          	rem	a5,s1,a4
    2db8:	03078793          	addi	a5,a5,48
    2dbc:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    2dc0:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    2dc4:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    2dc8:	fe0494e3          	bnez	s1,2db0 <bsp_printf_d+0x30>
    2dcc:	00010793          	mv	a5,sp
    2dd0:	fef400e3          	beq	s0,a5,2db0 <bsp_printf_d+0x30>
        }
        while (p != buffer)
    2dd4:	00010793          	mv	a5,sp
    2dd8:	00f40a63          	beq	s0,a5,2dec <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    2ddc:	fff40413          	addi	s0,s0,-1
    2de0:	00044503          	lbu	a0,0(s0)
    2de4:	f69ff0ef          	jal	2d4c <bsp_printf_c>
    2de8:	fedff06f          	j	2dd4 <bsp_printf_d+0x54>
    }
    2dec:	02c12083          	lw	ra,44(sp)
    2df0:	02812403          	lw	s0,40(sp)
    2df4:	02412483          	lw	s1,36(sp)
    2df8:	03010113          	addi	sp,sp,48
    2dfc:	00008067          	ret

00002e00 <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    2e00:	ff010113          	addi	sp,sp,-16
    2e04:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    2e08:	00000713          	li	a4,0
    2e0c:	00700793          	li	a5,7
    2e10:	02e7c063          	blt	a5,a4,2e30 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    2e14:	00271693          	slli	a3,a4,0x2
    2e18:	ff000793          	li	a5,-16
    2e1c:	00d797b3          	sll	a5,a5,a3
    2e20:	00f577b3          	and	a5,a0,a5
    2e24:	00078663          	beqz	a5,2e30 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    2e28:	00170713          	addi	a4,a4,1 # 1d001 <__global_pointer$+0x14f09>
    2e2c:	fe1ff06f          	j	2e0c <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    2e30:	ec9ff0ef          	jal	2cf8 <bsp_printHex_lower>
    }
    2e34:	00c12083          	lw	ra,12(sp)
    2e38:	01010113          	addi	sp,sp,16
    2e3c:	00008067          	ret

00002e40 <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    2e40:	ff010113          	addi	sp,sp,-16
    2e44:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    2e48:	00000713          	li	a4,0
    2e4c:	00700793          	li	a5,7
    2e50:	02e7c063          	blt	a5,a4,2e70 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    2e54:	00271693          	slli	a3,a4,0x2
    2e58:	ff000793          	li	a5,-16
    2e5c:	00d797b3          	sll	a5,a5,a3
    2e60:	00f577b3          	and	a5,a0,a5
    2e64:	00078663          	beqz	a5,2e70 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    2e68:	00170713          	addi	a4,a4,1
    2e6c:	fe1ff06f          	j	2e4c <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    2e70:	e35ff0ef          	jal	2ca4 <bsp_printHex>
        }
    2e74:	00c12083          	lw	ra,12(sp)
    2e78:	01010113          	addi	sp,sp,16
    2e7c:	00008067          	ret

00002e80 <bsp_init>:
    *   1. UART baudrate
    *   2. 
    */
////////////////////////////////////////////////////////////////////////////////
    static void bsp_init()
    {
    2e80:	fe010113          	addi	sp,sp,-32
    2e84:	00112e23          	sw	ra,28(sp)
        Uart_Config uartConfig;
        uartConfig.dataLength   = BITS_8;
    2e88:	00800793          	li	a5,8
    2e8c:	00f12023          	sw	a5,0(sp)
        uartConfig.parity       = NONE;
    2e90:	00012223          	sw	zero,4(sp)
        uartConfig.stop         = ONE;
    2e94:	00012423          	sw	zero,8(sp)
        uartConfig.clockDivider = BSP_CLINT_HZ/(BSP_UART_BAUDRATE*BSP_UART_DATA_LEN)-1;
    2e98:	06b00793          	li	a5,107
    2e9c:	00f12623          	sw	a5,12(sp)
        uart_applyConfig(BSP_UART_TERMINAL, &uartConfig);    
    2ea0:	00010593          	mv	a1,sp
    2ea4:	f8010537          	lui	a0,0xf8010
    2ea8:	d79ff0ef          	jal	2c20 <uart_applyConfig>
    }
    2eac:	01c12083          	lw	ra,28(sp)
    2eb0:	02010113          	addi	sp,sp,32
    2eb4:	00008067          	ret

00002eb8 <blk_idx>:
static int blk_idx(int sz) { int i; for (i = 0; i < BLK_N; i++) if (g_blk_tab[i] == sz) return i; return 0; }
    2eb8:	00050693          	mv	a3,a0
    2ebc:	00000513          	li	a0,0
    2ec0:	0080006f          	j	2ec8 <blk_idx+0x10>
    2ec4:	00150513          	addi	a0,a0,1 # f8010001 <__freertos_irq_stack_top+0xf7fccc61>
    2ec8:	00200793          	li	a5,2
    2ecc:	02a7c063          	blt	a5,a0,2eec <blk_idx+0x34>
    2ed0:	000077b7          	lui	a5,0x7
    2ed4:	00251713          	slli	a4,a0,0x2
    2ed8:	7fc78793          	addi	a5,a5,2044 # 77fc <g_blk_tab>
    2edc:	00e787b3          	add	a5,a5,a4
    2ee0:	0007a783          	lw	a5,0(a5)
    2ee4:	fed790e3          	bne	a5,a3,2ec4 <blk_idx+0xc>
    2ee8:	00008067          	ret
    2eec:	00000513          	li	a0,0
    2ef0:	00008067          	ret

00002ef4 <blk_next>:
static int blk_next(int sz) { return g_blk_tab[(blk_idx(sz) + 1) % BLK_N]; }
    2ef4:	ff010113          	addi	sp,sp,-16
    2ef8:	00112623          	sw	ra,12(sp)
    2efc:	fbdff0ef          	jal	2eb8 <blk_idx>
    2f00:	00150513          	addi	a0,a0,1
    2f04:	00300793          	li	a5,3
    2f08:	02f56533          	rem	a0,a0,a5
    2f0c:	000077b7          	lui	a5,0x7
    2f10:	00251513          	slli	a0,a0,0x2
    2f14:	7fc78793          	addi	a5,a5,2044 # 77fc <g_blk_tab>
    2f18:	00a787b3          	add	a5,a5,a0
    2f1c:	0007a503          	lw	a0,0(a5)
    2f20:	00c12083          	lw	ra,12(sp)
    2f24:	01010113          	addi	sp,sp,16
    2f28:	00008067          	ret

00002f2c <tick32>:
        return *((volatile u32*) address);
    2f2c:	f8b0c7b7          	lui	a5,0xf8b0c
    2f30:	ff87a503          	lw	a0,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8ac8c58>
static uint32_t tick32(void) { return clint_getTimeLow(BSP_CLINT); }
    2f34:	00008067          	ret

00002f38 <cpu_backoff>:
    if (n == 0u) return;
    2f38:	00050663          	beqz	a0,2f44 <cpu_backoff+0xc>
    __asm__ __volatile__ (
    2f3c:	fff50513          	addi	a0,a0,-1
    2f40:	fe051ee3          	bnez	a0,2f3c <cpu_backoff+0x4>
}
    2f44:	00008067          	ret

00002f48 <blt_wr>:
static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
    2f48:	f81007b7          	lui	a5,0xf8100
    2f4c:	00f50533          	add	a0,a0,a5
    2f50:	00b52023          	sw	a1,0(a0)
    2f54:	00008067          	ret

00002f58 <blt_rd>:
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }
    2f58:	f81007b7          	lui	a5,0xf8100
    2f5c:	00f50533          	add	a0,a0,a5
    2f60:	00052503          	lw	a0,0(a0)
    2f64:	00008067          	ret

00002f68 <fb_of_sel>:
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
    2f68:	00200793          	li	a5,2
    2f6c:	00f50e63          	beq	a0,a5,2f88 <fb_of_sel+0x20>
    2f70:	00100793          	li	a5,1
    2f74:	00f50663          	beq	a0,a5,2f80 <fb_of_sel+0x18>
    2f78:	00301537          	lui	a0,0x301
}
    2f7c:	00008067          	ret
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
    2f80:	00501537          	lui	a0,0x501
    2f84:	00008067          	ret
    2f88:	00701537          	lui	a0,0x701
    2f8c:	00008067          	ret

00002f90 <fb_stat_sel>:
static uint32_t fb_stat_sel(void) { return FB_SEL_STAT_SEL(blt_rd(BLT_FB_STAT)); }
    2f90:	ff010113          	addi	sp,sp,-16
    2f94:	00112623          	sw	ra,12(sp)
    2f98:	02800513          	li	a0,40
    2f9c:	fbdff0ef          	jal	2f58 <blt_rd>
    2fa0:	00357513          	andi	a0,a0,3
    2fa4:	00c12083          	lw	ra,12(sp)
    2fa8:	01010113          	addi	sp,sp,16
    2fac:	00008067          	ret

00002fb0 <clr_stat>:
static uint32_t clr_stat(void)  { return blt_rd(BLT_CLR_STAT); }
    2fb0:	ff010113          	addi	sp,sp,-16
    2fb4:	00112623          	sw	ra,12(sp)
    2fb8:	04000513          	li	a0,64
    2fbc:	f9dff0ef          	jal	2f58 <blt_rd>
    2fc0:	00c12083          	lw	ra,12(sp)
    2fc4:	01010113          	addi	sp,sp,16
    2fc8:	00008067          	ret

00002fcc <clr_busy>:
static int      clr_busy(void)  { return (clr_stat() & BLT_CLR_STAT_BUSY) ? 1 : 0; }
    2fcc:	ff010113          	addi	sp,sp,-16
    2fd0:	00112623          	sw	ra,12(sp)
    2fd4:	fddff0ef          	jal	2fb0 <clr_stat>
    2fd8:	00157513          	andi	a0,a0,1
    2fdc:	00c12083          	lw	ra,12(sp)
    2fe0:	01010113          	addi	sp,sp,16
    2fe4:	00008067          	ret

00002fe8 <clr_is_clean>:
static int      clr_is_clean(uint32_t k) { return (int)((clr_stat() >> (2u + k)) & 1u); }
    2fe8:	ff010113          	addi	sp,sp,-16
    2fec:	00112623          	sw	ra,12(sp)
    2ff0:	00812423          	sw	s0,8(sp)
    2ff4:	00050413          	mv	s0,a0
    2ff8:	fb9ff0ef          	jal	2fb0 <clr_stat>
    2ffc:	00240413          	addi	s0,s0,2
    3000:	00855533          	srl	a0,a0,s0
    3004:	00157513          	andi	a0,a0,1
    3008:	00c12083          	lw	ra,12(sp)
    300c:	00812403          	lw	s0,8(sp)
    3010:	01010113          	addi	sp,sp,16
    3014:	00008067          	ret

00003018 <clr_wait_idle>:
{
    3018:	ff010113          	addi	sp,sp,-16
    301c:	00112623          	sw	ra,12(sp)
    3020:	00812423          	sw	s0,8(sp)
    3024:	00912223          	sw	s1,4(sp)
    uint32_t t0 = tick32();
    3028:	f05ff0ef          	jal	2f2c <tick32>
    302c:	00050493          	mv	s1,a0
{
    3030:	00000413          	li	s0,0
    while (clr_busy()) {
    3034:	f99ff0ef          	jal	2fcc <clr_busy>
    3038:	04050263          	beqz	a0,307c <clr_wait_idle+0x64>
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
    303c:	ef1ff0ef          	jal	2f2c <tick32>
    3040:	40950533          	sub	a0,a0,s1
    3044:	000f47b7          	lui	a5,0xf4
    3048:	24078793          	addi	a5,a5,576 # f4240 <__freertos_irq_stack_top+0xb0ea0>
    304c:	00a7ee63          	bltu	a5,a0,3068 <clr_wait_idle+0x50>
        if (++guard > 64) { guard = 0; cpu_backoff(48u); }
    3050:	00140413          	addi	s0,s0,1
    3054:	04000793          	li	a5,64
    3058:	fc87dee3          	bge	a5,s0,3034 <clr_wait_idle+0x1c>
    305c:	03000513          	li	a0,48
    3060:	ed9ff0ef          	jal	2f38 <cpu_backoff>
    3064:	fcdff06f          	j	3030 <clr_wait_idle+0x18>
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
    3068:	8b81a783          	lw	a5,-1864(gp) # 79b0 <g_clr_to>
    306c:	00178793          	addi	a5,a5,1
    3070:	8af1ac23          	sw	a5,-1864(gp) # 79b0 <g_clr_to>
    3074:	00000513          	li	a0,0
    3078:	0080006f          	j	3080 <clr_wait_idle+0x68>
    return 1;
    307c:	00100513          	li	a0,1
}
    3080:	00c12083          	lw	ra,12(sp)
    3084:	00812403          	lw	s0,8(sp)
    3088:	00412483          	lw	s1,4(sp)
    308c:	01010113          	addi	sp,sp,16
    3090:	00008067          	ret

00003094 <clr_start>:
{
    3094:	ff010113          	addi	sp,sp,-16
    3098:	00112623          	sw	ra,12(sp)
    309c:	00812423          	sw	s0,8(sp)
    30a0:	00912223          	sw	s1,4(sp)
    30a4:	01212023          	sw	s2,0(sp)
    30a8:	00050413          	mv	s0,a0
    30ac:	00058913          	mv	s2,a1
    30b0:	00060493          	mv	s1,a2
    blt_wr(BLT_CLR_ADDR,   fb_of_sel(k) + (uint32_t)y0 * FB_STRIDE);
    30b4:	eb5ff0ef          	jal	2f68 <fb_of_sel>
    30b8:	00491793          	slli	a5,s2,0x4
    30bc:	412787b3          	sub	a5,a5,s2
    30c0:	00779793          	slli	a5,a5,0x7
    30c4:	00f505b3          	add	a1,a0,a5
    30c8:	02c00513          	li	a0,44
    30cc:	e7dff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CLR_STRIDE, FB_STRIDE);
    30d0:	78000593          	li	a1,1920
    30d4:	03000513          	li	a0,48
    30d8:	e71ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CLR_WH,     ((uint32_t)h << 16) | (uint32_t)FB_WIDTH);
    30dc:	01049593          	slli	a1,s1,0x10
    30e0:	3c05e593          	ori	a1,a1,960
    30e4:	03400513          	li	a0,52
    30e8:	e61ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CLR_COLOR,  COL_BG);
    30ec:	00800593          	li	a1,8
    30f0:	03800513          	li	a0,56
    30f4:	e55ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CLR_CTRL,   ((uint32_t)k << 2) | BLT_CLR_GO);
    30f8:	00241593          	slli	a1,s0,0x2
    30fc:	0015e593          	ori	a1,a1,1
    3100:	03c00513          	li	a0,60
    3104:	e45ff0ef          	jal	2f48 <blt_wr>
}
    3108:	00c12083          	lw	ra,12(sp)
    310c:	00812403          	lw	s0,8(sp)
    3110:	00412483          	lw	s1,4(sp)
    3114:	00012903          	lw	s2,0(sp)
    3118:	01010113          	addi	sp,sp,16
    311c:	00008067          	ret

00003120 <hw_pass_arm>:
{
    3120:	fe010113          	addi	sp,sp,-32
    3124:	00112e23          	sw	ra,28(sp)
    3128:	00812c23          	sw	s0,24(sp)
    312c:	00912a23          	sw	s1,20(sp)
    3130:	01212823          	sw	s2,16(sp)
    3134:	01312623          	sw	s3,12(sp)
    3138:	00050993          	mv	s3,a0
    313c:	00058913          	mv	s2,a1
    if (!clr_wait_idle()) {                        /* ① */
    3140:	ed9ff0ef          	jal	3018 <clr_wait_idle>
    clean_k = clr_is_clean((uint32_t)g_draw3);     /* ② */
    3144:	8281a503          	lw	a0,-2008(gp) # 7920 <g_draw3>
    3148:	ea1ff0ef          	jal	2fe8 <clr_is_clean>
    314c:	00050413          	mv	s0,a0
    blt_wr(BLT_DRAW_SEL, (uint32_t)g_draw3);       /* ③ */
    3150:	8281a583          	lw	a1,-2008(gp) # 7920 <g_draw3>
    3154:	04400513          	li	a0,68
    3158:	df1ff0ef          	jal	2f48 <blt_wr>
    if (clr_stat() & BLT_CLR_STAT_ERR) {           /*    清掉互斥留下的 sticky 错误 */
    315c:	e55ff0ef          	jal	2fb0 <clr_stat>
    3160:	04057793          	andi	a5,a0,64
    3164:	02079e63          	bnez	a5,31a0 <hw_pass_arm+0x80>
    if (!clean_k) g_clr_fb++;                      /* ④ 脏 ⇒ 必须退回命令式清屏 */
    3168:	00041863          	bnez	s0,3178 <hw_pass_arm+0x58>
    316c:	8bc1a783          	lw	a5,-1860(gp) # 79b4 <g_clr_fb>
    3170:	00178793          	addi	a5,a5,1
    3174:	8af1ae23          	sw	a5,-1860(gp) # 79b4 <g_clr_fb>
    if (g_clr_need) {                              /* ⑤ */
    3178:	8c41a783          	lw	a5,-1852(gp) # 79bc <g_clr_need>
    317c:	04079463          	bnez	a5,31c4 <hw_pass_arm+0xa4>
}
    3180:	00143513          	seqz	a0,s0
    3184:	01c12083          	lw	ra,28(sp)
    3188:	01812403          	lw	s0,24(sp)
    318c:	01412483          	lw	s1,20(sp)
    3190:	01012903          	lw	s2,16(sp)
    3194:	00c12983          	lw	s3,12(sp)
    3198:	02010113          	addi	sp,sp,32
    319c:	00008067          	ret
        g_clr_err++;
    31a0:	8b41a783          	lw	a5,-1868(gp) # 79ac <g_clr_err>
    31a4:	00178793          	addi	a5,a5,1
    31a8:	8af1aa23          	sw	a5,-1868(gp) # 79ac <g_clr_err>
        blt_wr(BLT_CLR_CTRL, ((uint32_t)g_draw3 << 2) | BLT_CLR_ERRCLR);
    31ac:	8281a583          	lw	a1,-2008(gp) # 7920 <g_draw3>
    31b0:	00259593          	slli	a1,a1,0x2
    31b4:	0105e593          	ori	a1,a1,16
    31b8:	03c00513          	li	a0,60
    31bc:	d8dff0ef          	jal	2f48 <blt_wr>
    31c0:	fa9ff06f          	j	3168 <hw_pass_arm+0x48>
        clr_start((uint32_t)g_clr3, y0, h);
    31c4:	00090613          	mv	a2,s2
    31c8:	00098593          	mv	a1,s3
    31cc:	8241a503          	lw	a0,-2012(gp) # 791c <g_clr3>
    31d0:	ec5ff0ef          	jal	3094 <clr_start>
        g_clr_need = 0;
    31d4:	8c01a223          	sw	zero,-1852(gp) # 79bc <g_clr_need>
    31d8:	fa9ff06f          	j	3180 <hw_pass_arm+0x60>

000031dc <cache_evict>:
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
    31dc:	00000793          	li	a5,0
    31e0:	0200006f          	j	3200 <cache_evict+0x24>
    31e4:	00279693          	slli	a3,a5,0x2
    31e8:	00601737          	lui	a4,0x601
    31ec:	00d70733          	add	a4,a4,a3
    31f0:	a5a506b7          	lui	a3,0xa5a50
    31f4:	00d786b3          	add	a3,a5,a3
    31f8:	00d72023          	sw	a3,0(a4) # 601000 <__freertos_irq_stack_top+0x5bdc60>
    31fc:	00178793          	addi	a5,a5,1
    3200:	7ff00713          	li	a4,2047
    3204:	fef770e3          	bgeu	a4,a5,31e4 <cache_evict+0x8>
}
    3208:	00008067          	ret

0000320c <blt_emit>:
{
    320c:	fe010113          	addi	sp,sp,-32
    3210:	00112e23          	sw	ra,28(sp)
    3214:	00812c23          	sw	s0,24(sp)
    3218:	00912a23          	sw	s1,20(sp)
    321c:	01212823          	sw	s2,16(sp)
    3220:	01312623          	sw	s3,12(sp)
    3224:	01412423          	sw	s4,8(sp)
    3228:	01512223          	sw	s5,4(sp)
    322c:	01612023          	sw	s6,0(sp)
    3230:	00058b13          	mv	s6,a1
    3234:	00060a93          	mv	s5,a2
    3238:	00068a13          	mv	s4,a3
    323c:	00070993          	mv	s3,a4
    3240:	00078413          	mv	s0,a5
    3244:	00080493          	mv	s1,a6
    3248:	00088913          	mv	s2,a7
    blt_wr(BLT_CMD_FIFO_DATA, op);
    324c:	00050593          	mv	a1,a0
    3250:	00800513          	li	a0,8
    3254:	cf5ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, src);
    3258:	000b0593          	mv	a1,s6
    325c:	00800513          	li	a0,8
    3260:	ce9ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    3264:	000a8593          	mv	a1,s5
    3268:	00800513          	li	a0,8
    326c:	cddff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    3270:	000a0593          	mv	a1,s4
    3274:	00800513          	li	a0,8
    3278:	cd1ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    327c:	00098593          	mv	a1,s3
    3280:	00800513          	li	a0,8
    3284:	cc5ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    3288:	01049493          	slli	s1,s1,0x10
    328c:	01041413          	slli	s0,s0,0x10
    3290:	01045413          	srli	s0,s0,0x10
    3294:	0084e5b3          	or	a1,s1,s0
    3298:	00800513          	li	a0,8
    329c:	cadff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    32a0:	00090593          	mv	a1,s2
    32a4:	00800513          	li	a0,8
    32a8:	ca1ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, color);
    32ac:	02012583          	lw	a1,32(sp)
    32b0:	00800513          	li	a0,8
    32b4:	c95ff0ef          	jal	2f48 <blt_wr>
}
    32b8:	01c12083          	lw	ra,28(sp)
    32bc:	01812403          	lw	s0,24(sp)
    32c0:	01412483          	lw	s1,20(sp)
    32c4:	01012903          	lw	s2,16(sp)
    32c8:	00c12983          	lw	s3,12(sp)
    32cc:	00812a03          	lw	s4,8(sp)
    32d0:	00412a83          	lw	s5,4(sp)
    32d4:	00012b03          	lw	s6,0(sp)
    32d8:	02010113          	addi	sp,sp,32
    32dc:	00008067          	ret

000032e0 <blt_cnt>:
static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
    32e0:	ff010113          	addi	sp,sp,-16
    32e4:	00112623          	sw	ra,12(sp)
    32e8:	00c00513          	li	a0,12
    32ec:	c6dff0ef          	jal	2f58 <blt_rd>
    32f0:	00c12083          	lw	ra,12(sp)
    32f4:	01010113          	addi	sp,sp,16
    32f8:	00008067          	ret

000032fc <blt_stat>:
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }
    32fc:	ff010113          	addi	sp,sp,-16
    3300:	00112623          	sw	ra,12(sp)
    3304:	00400513          	li	a0,4
    3308:	c51ff0ef          	jal	2f58 <blt_rd>
    330c:	00c12083          	lw	ra,12(sp)
    3310:	01010113          	addi	sp,sp,16
    3314:	00008067          	ret

00003318 <blt_idle_st>:
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
    3318:	00e57513          	andi	a0,a0,14
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
    331c:	ff650513          	addi	a0,a0,-10 # 700ff6 <__freertos_irq_stack_top+0x6bdc56>
}
    3320:	00153513          	seqz	a0,a0
    3324:	00008067          	ret

00003328 <blt_push_room>:
{
    3328:	ff010113          	addi	sp,sp,-16
    332c:	00112623          	sw	ra,12(sp)
    uint32_t cnt = blt_cnt();
    3330:	fb1ff0ef          	jal	32e0 <blt_cnt>
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    3334:	0c700793          	li	a5,199
    3338:	00a7ec63          	bltu	a5,a0,3350 <blt_push_room+0x28>
    return (uint32_t)BLT_PUSH_LIMIT - cnt;
    333c:	0c800793          	li	a5,200
    3340:	40a78533          	sub	a0,a5,a0
}
    3344:	00c12083          	lw	ra,12(sp)
    3348:	01010113          	addi	sp,sp,16
    334c:	00008067          	ret
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    3350:	00000513          	li	a0,0
    3354:	ff1ff06f          	j	3344 <blt_push_room+0x1c>

00003358 <blt_init>:
{
    3358:	ff010113          	addi	sp,sp,-16
    335c:	00112623          	sw	ra,12(sp)
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    3360:	00400593          	li	a1,4
    3364:	00000513          	li	a0,0
    3368:	be1ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_IRQ_STATUS, 1u);                        /* W1C */
    336c:	00100593          	li	a1,1
    3370:	01000513          	li	a0,16
    3374:	bd5ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_IRQ_EN, 0u);
    3378:	00000593          	li	a1,0
    337c:	01400513          	li	a0,20
    3380:	bc9ff0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
    3384:	00100593          	li	a1,1
    3388:	00000513          	li	a0,0
    338c:	bbdff0ef          	jal	2f48 <blt_wr>
}
    3390:	00c12083          	lw	ra,12(sp)
    3394:	01010113          	addi	sp,sp,16
    3398:	00008067          	ret

0000339c <blt_fill>:
{
    339c:	fe010113          	addi	sp,sp,-32
    33a0:	00112e23          	sw	ra,28(sp)
    33a4:	00060793          	mv	a5,a2
    blt_emit(BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color);
    33a8:	00e12023          	sw	a4,0(sp)
    33ac:	0ff00893          	li	a7,255
    33b0:	00068813          	mv	a6,a3
    33b4:	00058713          	mv	a4,a1
    33b8:	00000693          	li	a3,0
    33bc:	00050613          	mv	a2,a0
    33c0:	00000593          	li	a1,0
    33c4:	00100513          	li	a0,1
    33c8:	e45ff0ef          	jal	320c <blt_emit>
}
    33cc:	01c12083          	lw	ra,28(sp)
    33d0:	02010113          	addi	sp,sp,32
    33d4:	00008067          	ret

000033d8 <blt_alpha>:
{
    33d8:	fe010113          	addi	sp,sp,-32
    33dc:	00112e23          	sw	ra,28(sp)
    blt_emit(BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha, 0u);
    33e0:	00012023          	sw	zero,0(sp)
    33e4:	00080893          	mv	a7,a6
    33e8:	00078813          	mv	a6,a5
    33ec:	00070793          	mv	a5,a4
    33f0:	00068713          	mv	a4,a3
    33f4:	00060693          	mv	a3,a2
    33f8:	00058613          	mv	a2,a1
    33fc:	00050593          	mv	a1,a0
    3400:	00200513          	li	a0,2
    3404:	e09ff0ef          	jal	320c <blt_emit>
}
    3408:	01c12083          	lw	ra,28(sp)
    340c:	02010113          	addi	sp,sp,32
    3410:	00008067          	ret

00003414 <blt_key>:
{
    3414:	fe010113          	addi	sp,sp,-32
    3418:	00112e23          	sw	ra,28(sp)
    blt_emit(BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key);
    341c:	01012023          	sw	a6,0(sp)
    3420:	0ff00893          	li	a7,255
    3424:	00078813          	mv	a6,a5
    3428:	00070793          	mv	a5,a4
    342c:	00068713          	mv	a4,a3
    3430:	00060693          	mv	a3,a2
    3434:	00058613          	mv	a2,a1
    3438:	00050593          	mv	a1,a0
    343c:	00300513          	li	a0,3
    3440:	dcdff0ef          	jal	320c <blt_emit>
}
    3444:	01c12083          	lw	ra,28(sp)
    3448:	02010113          	addi	sp,sp,32
    344c:	00008067          	ret

00003450 <spr_color>:
    int dx = i - SPR_W / 2, dy = j - SPR_H / 2;
    3450:	8201a603          	lw	a2,-2016(gp) # 7918 <g_blk>
    3454:	01f65713          	srli	a4,a2,0x1f
    3458:	00c70733          	add	a4,a4,a2
    345c:	40175713          	srai	a4,a4,0x1
    3460:	40e00733          	neg	a4,a4
    3464:	00a706b3          	add	a3,a4,a0
    3468:	00b707b3          	add	a5,a4,a1
    int d2 = dx * dx + dy * dy;
    346c:	02d686b3          	mul	a3,a3,a3
    3470:	02f787b3          	mul	a5,a5,a5
    3474:	00f686b3          	add	a3,a3,a5
    int r2 = (SPR_W / 2) * (SPR_W / 2);
    3478:	02e70833          	mul	a6,a4,a4
    int ri = SPR_W / 2 - SPR_RING;       /* 白环内边界半径（外边界 = SPR_W/2） */
    347c:	41f65793          	srai	a5,a2,0x1f
    3480:	0077f793          	andi	a5,a5,7
    3484:	00c787b3          	add	a5,a5,a2
    3488:	4037d793          	srai	a5,a5,0x3
    348c:	40f007b3          	neg	a5,a5
    3490:	40e787b3          	sub	a5,a5,a4
    if (d2 > r2)              return KEY_COLOR;      /* 圆外（含四角）⇒ 色键 */
    3494:	06d84863          	blt	a6,a3,3504 <spr_color+0xb4>
    if (d2 > ri * ri)         return COL_WHITE;      /* 白环 */
    3498:	02f787b3          	mul	a5,a5,a5
    349c:	06d7ca63          	blt	a5,a3,3510 <spr_color+0xc0>
    rr = (unsigned)((i * 31) / (SPR_W - 1));
    34a0:	00551793          	slli	a5,a0,0x5
    34a4:	40a78533          	sub	a0,a5,a0
    34a8:	fff60613          	addi	a2,a2,-1
    34ac:	02c54533          	div	a0,a0,a2
    gg = (unsigned)((j * 63) / (SPR_H - 1));
    34b0:	00659793          	slli	a5,a1,0x6
    34b4:	40b787b3          	sub	a5,a5,a1
    34b8:	02c7c7b3          	div	a5,a5,a2
    bb = (unsigned)(31 - ((d2 * 31) / (r2 ? r2 : 1)));
    34bc:	00569713          	slli	a4,a3,0x5
    34c0:	40d70733          	sub	a4,a4,a3
    34c4:	00081463          	bnez	a6,34cc <spr_color+0x7c>
    34c8:	00100813          	li	a6,1
    34cc:	03074733          	div	a4,a4,a6
    34d0:	01f00693          	li	a3,31
    34d4:	40e68733          	sub	a4,a3,a4
    return (uint16_t)((rr << 11) | (gg << 5) | bb);
    34d8:	00b51513          	slli	a0,a0,0xb
    34dc:	01051513          	slli	a0,a0,0x10
    34e0:	01055513          	srli	a0,a0,0x10
    34e4:	00579793          	slli	a5,a5,0x5
    34e8:	01079793          	slli	a5,a5,0x10
    34ec:	0107d793          	srli	a5,a5,0x10
    34f0:	00f56533          	or	a0,a0,a5
    34f4:	00e56533          	or	a0,a0,a4
    34f8:	01051513          	slli	a0,a0,0x10
    34fc:	01055513          	srli	a0,a0,0x10
    3500:	00008067          	ret
    if (d2 > r2)              return KEY_COLOR;      /* 圆外（含四角）⇒ 色键 */
    3504:	00010537          	lui	a0,0x10
    3508:	81f50513          	addi	a0,a0,-2017 # f81f <__global_pointer$+0x7727>
    350c:	00008067          	ret
    if (d2 > ri * ri)         return COL_WHITE;      /* 白环 */
    3510:	00010537          	lui	a0,0x10
    3514:	fff50513          	addi	a0,a0,-1 # ffff <__global_pointer$+0x7f07>
}
    3518:	00008067          	ret

0000351c <spr_mask_of>:
{
    351c:	00050893          	mv	a7,a0
    3520:	00060393          	mv	t2,a2
    3524:	00068813          	mv	a6,a3
    for (rt = 0; rt < 4; rt++) {
    3528:	00000293          	li	t0,0
    uint16_t m = 0u;
    352c:	00000513          	li	a0,0
    for (rt = 0; rt < 4; rt++) {
    3530:	00300793          	li	a5,3
    3534:	1057c463          	blt	a5,t0,363c <spr_mask_of+0x120>
{
    3538:	ff010113          	addi	sp,sp,-16
    353c:	00812623          	sw	s0,12(sp)
    3540:	00912423          	sw	s1,8(sp)
    3544:	0b40006f          	j	35f8 <spr_mask_of+0xdc>
                    if (px[j * w + i] != key) { allkey = 0; break; }
    3548:	00000e13          	li	t3,0
            for (j = y0; j < y1 && allkey; j++)
    354c:	00168693          	addi	a3,a3,1 # a5a50001 <__freertos_irq_stack_top+0xa5a0cc61>
    3550:	03d6dc63          	bge	a3,t4,3588 <spr_mask_of+0x6c>
    3554:	020e0a63          	beqz	t3,3588 <spr_mask_of+0x6c>
                for (i = x0; i < x1; i++)
    3558:	00030713          	mv	a4,t1
    355c:	fec758e3          	bge	a4,a2,354c <spr_mask_of+0x30>
                    if (px[j * w + i] != key) { allkey = 0; break; }
    3560:	02b687b3          	mul	a5,a3,a1
    3564:	00e787b3          	add	a5,a5,a4
    3568:	00179793          	slli	a5,a5,0x1
    356c:	00f887b3          	add	a5,a7,a5
    3570:	0007d783          	lhu	a5,0(a5)
    3574:	01079793          	slli	a5,a5,0x10
    3578:	0107d793          	srli	a5,a5,0x10
    357c:	fd0796e3          	bne	a5,a6,3548 <spr_mask_of+0x2c>
                for (i = x0; i < x1; i++)
    3580:	00170713          	addi	a4,a4,1
    3584:	fd9ff06f          	j	355c <spr_mask_of+0x40>
            if (allkey) m = (uint16_t)(m | (uint16_t)(1u << (rt * 4 + ct)));
    3588:	020e0063          	beqz	t3,35a8 <spr_mask_of+0x8c>
    358c:	00229713          	slli	a4,t0,0x2
    3590:	01e70733          	add	a4,a4,t5
    3594:	00100793          	li	a5,1
    3598:	00e797b3          	sll	a5,a5,a4
    359c:	01079793          	slli	a5,a5,0x10
    35a0:	0107d793          	srli	a5,a5,0x10
    35a4:	00a7e533          	or	a0,a5,a0
            int allkey = 1, i, j;
    35a8:	00048f13          	mv	t5,s1
        for (ct = 0; ct < 4; ct++) {
    35ac:	00300793          	li	a5,3
    35b0:	03e7ce63          	blt	a5,t5,35ec <spr_mask_of+0xd0>
            int x0 = (w * ct) / 4, x1 = (w * (ct + 1)) / 4;  /* 与 RTL 的 col_t* 同一公式 */
    35b4:	02bf07b3          	mul	a5,t5,a1
    35b8:	41f7d313          	srai	t1,a5,0x1f
    35bc:	00337313          	andi	t1,t1,3
    35c0:	00f30333          	add	t1,t1,a5
    35c4:	40235313          	srai	t1,t1,0x2
    35c8:	001f0493          	addi	s1,t5,1
    35cc:	02b487b3          	mul	a5,s1,a1
    35d0:	41f7d613          	srai	a2,a5,0x1f
    35d4:	00367613          	andi	a2,a2,3
    35d8:	00f60633          	add	a2,a2,a5
    35dc:	40265613          	srai	a2,a2,0x2
            for (j = y0; j < y1 && allkey; j++)
    35e0:	000f8693          	mv	a3,t6
            int allkey = 1, i, j;
    35e4:	00100e13          	li	t3,1
            for (j = y0; j < y1 && allkey; j++)
    35e8:	f69ff06f          	j	3550 <spr_mask_of+0x34>
    for (rt = 0; rt < 4; rt++) {
    35ec:	00040293          	mv	t0,s0
    35f0:	00300793          	li	a5,3
    35f4:	0287cc63          	blt	a5,s0,362c <spr_mask_of+0x110>
        int y0 = (h * rt) / 4, y1 = (h * (rt + 1)) / 4;      /* 与 RTL 的 row_t* 同一公式 */
    35f8:	027287b3          	mul	a5,t0,t2
    35fc:	41f7df93          	srai	t6,a5,0x1f
    3600:	003fff93          	andi	t6,t6,3
    3604:	00ff8fb3          	add	t6,t6,a5
    3608:	402fdf93          	srai	t6,t6,0x2
    360c:	00128413          	addi	s0,t0,1
    3610:	027407b3          	mul	a5,s0,t2
    3614:	41f7de93          	srai	t4,a5,0x1f
    3618:	003efe93          	andi	t4,t4,3
    361c:	00fe8eb3          	add	t4,t4,a5
    3620:	402ede93          	srai	t4,t4,0x2
        for (ct = 0; ct < 4; ct++) {
    3624:	00000f13          	li	t5,0
    3628:	f85ff06f          	j	35ac <spr_mask_of+0x90>
}
    362c:	00c12403          	lw	s0,12(sp)
    3630:	00812483          	lw	s1,8(sp)
    3634:	01010113          	addi	sp,sp,16
    3638:	00008067          	ret
    363c:	00008067          	ret

00003640 <spr_mask_tiles>:
{
    3640:	00050793          	mv	a5,a0
    int n = 0;
    3644:	00000513          	li	a0,0
    while (m) { n += (int)(m & 1u); m = (uint16_t)(m >> 1); }
    3648:	0100006f          	j	3658 <spr_mask_tiles+0x18>
    364c:	0017f713          	andi	a4,a5,1
    3650:	00e50533          	add	a0,a0,a4
    3654:	0017d793          	srli	a5,a5,0x1
    3658:	fe079ae3          	bnez	a5,364c <spr_mask_tiles+0xc>
}
    365c:	00008067          	ret

00003660 <build_atlas>:
{
    3660:	fe010113          	addi	sp,sp,-32
    3664:	00112e23          	sw	ra,28(sp)
    3668:	00812c23          	sw	s0,24(sp)
    366c:	00912a23          	sw	s1,20(sp)
    3670:	01212823          	sw	s2,16(sp)
    3674:	01312623          	sw	s3,12(sp)
    for (j = 0; j < SPR_H; j++)
    3678:	00000993          	li	s3,0
    367c:	0340006f          	j	36b0 <build_atlas+0x50>
            p[j * SPR_W + i] = spr_color(i, j);
    3680:	033907b3          	mul	a5,s2,s3
    3684:	008787b3          	add	a5,a5,s0
    3688:	00179793          	slli	a5,a5,0x1
    368c:	002014b7          	lui	s1,0x201
    3690:	00f484b3          	add	s1,s1,a5
    3694:	00098593          	mv	a1,s3
    3698:	00040513          	mv	a0,s0
    369c:	db5ff0ef          	jal	3450 <spr_color>
    36a0:	00a49023          	sh	a0,0(s1) # 201000 <__freertos_irq_stack_top+0x1bdc60>
        for (i = 0; i < SPR_W; i++)
    36a4:	00140413          	addi	s0,s0,1
    36a8:	fd244ce3          	blt	s0,s2,3680 <build_atlas+0x20>
    for (j = 0; j < SPR_H; j++)
    36ac:	00198993          	addi	s3,s3,1
    36b0:	8201a903          	lw	s2,-2016(gp) # 7918 <g_blk>
    36b4:	0129d663          	bge	s3,s2,36c0 <build_atlas+0x60>
        for (i = 0; i < SPR_W; i++)
    36b8:	00000413          	li	s0,0
    36bc:	fedff06f          	j	36a8 <build_atlas+0x48>
    g_spr_mask = spr_mask_of((const volatile uint16_t *)ATLAS_BASE, SPR_W, SPR_H,
    36c0:	000106b7          	lui	a3,0x10
    36c4:	81f68693          	addi	a3,a3,-2017 # f81f <__global_pointer$+0x7727>
    36c8:	00090613          	mv	a2,s2
    36cc:	00090593          	mv	a1,s2
    36d0:	00201537          	lui	a0,0x201
    36d4:	e49ff0ef          	jal	351c <spr_mask_of>
    36d8:	8aa19823          	sh	a0,-1872(gp) # 79a8 <g_spr_mask>
}
    36dc:	01c12083          	lw	ra,28(sp)
    36e0:	01812403          	lw	s0,24(sp)
    36e4:	01412483          	lw	s1,20(sp)
    36e8:	01012903          	lw	s2,16(sp)
    36ec:	00c12983          	lw	s3,12(sp)
    36f0:	02010113          	addi	sp,sp,32
    36f4:	00008067          	ret

000036f8 <cpu_fill32>:
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    36f8:	01079e93          	slli	t4,a5,0x10
    36fc:	00fe8eb3          	add	t4,t4,a5
    int odd = (x & 1);
    3700:	0015ff93          	andi	t6,a1,1
    for (j = 0; j < h; j++) {
    3704:	00000f13          	li	t5,0
    3708:	0480006f          	j	3750 <cpu_fill32+0x58>
        int rem = w;
    370c:	00068e13          	mv	t3,a3
    3710:	0700006f          	j	3780 <cpu_fill32+0x88>
            for (i = 0; i < (rem >> 1); i++) q[i] = two;
    3714:	00281893          	slli	a7,a6,0x2
    3718:	011308b3          	add	a7,t1,a7
    371c:	01d8a023          	sw	t4,0(a7)
    3720:	00180813          	addi	a6,a6,1
    3724:	401e5893          	srai	a7,t3,0x1
    3728:	ff1846e3          	blt	a6,a7,3714 <cpu_fill32+0x1c>
        if (rem & 1) p[rem - 1] = color;
    372c:	001e7813          	andi	a6,t3,1
    3730:	00080e63          	beqz	a6,374c <cpu_fill32+0x54>
    3734:	80000837          	lui	a6,0x80000
    3738:	fff80813          	addi	a6,a6,-1 # 7fffffff <__freertos_irq_stack_top+0x7ffbcc5f>
    373c:	010e0e33          	add	t3,t3,a6
    3740:	001e1e13          	slli	t3,t3,0x1
    3744:	01c30333          	add	t1,t1,t3
    3748:	00f31023          	sh	a5,0(t1) # 821000 <__freertos_irq_stack_top+0x7ddc60>
    for (j = 0; j < h; j++) {
    374c:	001f0f13          	addi	t5,t5,1
    3750:	02ef5c63          	bge	t5,a4,3788 <cpu_fill32+0x90>
        volatile uint16_t *p = (volatile uint16_t *)(base + (uint32_t)(y + j) * FB_STRIDE
    3754:	00cf0833          	add	a6,t5,a2
                                                          + (uint32_t)x * 2u);
    3758:	00481313          	slli	t1,a6,0x4
    375c:	41030333          	sub	t1,t1,a6
    3760:	00631313          	slli	t1,t1,0x6
    3764:	00b30333          	add	t1,t1,a1
    3768:	00131313          	slli	t1,t1,0x1
    376c:	00a30333          	add	t1,t1,a0
        if (odd) { *p++ = color; rem--; }
    3770:	f80f8ee3          	beqz	t6,370c <cpu_fill32+0x14>
    3774:	00f31023          	sh	a5,0(t1)
    3778:	fff68e13          	addi	t3,a3,-1
    377c:	00230313          	addi	t1,t1,2
            for (i = 0; i < (rem >> 1); i++) q[i] = two;
    3780:	00000813          	li	a6,0
    3784:	fa1ff06f          	j	3724 <cpu_fill32+0x2c>
}
    3788:	00008067          	ret

0000378c <blend565>:
{
    378c:	00060693          	mv	a3,a2
    unsigned fr = (fg >> 11) & 0x1Fu, fgc = (fg >> 5) & 0x3Fu, fb = fg & 0x1Fu;
    3790:	00b55713          	srli	a4,a0,0xb
    3794:	00555613          	srli	a2,a0,0x5
    3798:	03f67613          	andi	a2,a2,63
    379c:	01f57513          	andi	a0,a0,31
    unsigned br = (bg >> 11) & 0x1Fu, bgc = (bg >> 5) & 0x3Fu, bb = bg & 0x1Fu;
    37a0:	00b5d893          	srli	a7,a1,0xb
    37a4:	0055d813          	srli	a6,a1,0x5
    37a8:	03f87813          	andi	a6,a6,63
    37ac:	01f5f593          	andi	a1,a1,31
    unsigned f8r = (fr << 3) | (fr >> 2), f8g = (fgc << 2) | (fgc >> 4), f8b = (fb << 3) | (fb >> 2);
    37b0:	00371793          	slli	a5,a4,0x3
    37b4:	00275713          	srli	a4,a4,0x2
    37b8:	00e7e7b3          	or	a5,a5,a4
    37bc:	00261713          	slli	a4,a2,0x2
    37c0:	00465613          	srli	a2,a2,0x4
    37c4:	00c76733          	or	a4,a4,a2
    37c8:	00351613          	slli	a2,a0,0x3
    37cc:	00255513          	srli	a0,a0,0x2
    37d0:	00a66633          	or	a2,a2,a0
    unsigned b8r = (br << 3) | (br >> 2), b8g = (bgc << 2) | (bgc >> 4), b8b = (bb << 3) | (bb >> 2);
    37d4:	00389513          	slli	a0,a7,0x3
    37d8:	0028d893          	srli	a7,a7,0x2
    37dc:	011568b3          	or	a7,a0,a7
    37e0:	00281513          	slli	a0,a6,0x2
    37e4:	00485813          	srli	a6,a6,0x4
    37e8:	01056833          	or	a6,a0,a6
    37ec:	00359513          	slli	a0,a1,0x3
    37f0:	0025d593          	srli	a1,a1,0x2
    37f4:	00b565b3          	or	a1,a0,a1
    unsigned ai  = 255u - a;
    37f8:	0ff00e13          	li	t3,255
    37fc:	40de0333          	sub	t1,t3,a3
    unsigned r = (f8r * a + b8r * ai + 127u) >> 8;
    3800:	02d787b3          	mul	a5,a5,a3
    3804:	02688533          	mul	a0,a7,t1
    3808:	00a787b3          	add	a5,a5,a0
    380c:	07f78793          	addi	a5,a5,127
    3810:	0087d793          	srli	a5,a5,0x8
    unsigned g = (f8g * a + b8g * ai + 127u) >> 8;
    3814:	02d70733          	mul	a4,a4,a3
    3818:	02680533          	mul	a0,a6,t1
    381c:	00a70733          	add	a4,a4,a0
    3820:	07f70713          	addi	a4,a4,127
    3824:	00875713          	srli	a4,a4,0x8
    unsigned b = (f8b * a + b8b * ai + 127u) >> 8;
    3828:	02d60633          	mul	a2,a2,a3
    382c:	026586b3          	mul	a3,a1,t1
    3830:	00d60633          	add	a2,a2,a3
    3834:	07f60613          	addi	a2,a2,127
    3838:	00865613          	srli	a2,a2,0x8
    if (r > 255u) r = 255u;
    383c:	00fe7463          	bgeu	t3,a5,3844 <blend565+0xb8>
    3840:	0ff00793          	li	a5,255
    if (g > 255u) g = 255u;
    3844:	0ff00693          	li	a3,255
    3848:	00e6f463          	bgeu	a3,a4,3850 <blend565+0xc4>
    384c:	0ff00713          	li	a4,255
    if (b > 255u) b = 255u;
    3850:	0ff00693          	li	a3,255
    3854:	00c6f463          	bgeu	a3,a2,385c <blend565+0xd0>
    3858:	0ff00613          	li	a2,255
    return (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
    385c:	0037d513          	srli	a0,a5,0x3
    3860:	00b51513          	slli	a0,a0,0xb
    3864:	01051513          	slli	a0,a0,0x10
    3868:	01055513          	srli	a0,a0,0x10
    386c:	00275713          	srli	a4,a4,0x2
    3870:	00571713          	slli	a4,a4,0x5
    3874:	01071713          	slli	a4,a4,0x10
    3878:	01075713          	srli	a4,a4,0x10
    387c:	00e56533          	or	a0,a0,a4
    3880:	00365613          	srli	a2,a2,0x3
    3884:	00c56533          	or	a0,a0,a2
}
    3888:	01051513          	slli	a0,a0,0x10
    388c:	01055513          	srli	a0,a0,0x10
    3890:	00008067          	ret

00003894 <cpu_alpha_sprite>:
{
    3894:	fd010113          	addi	sp,sp,-48
    3898:	02112623          	sw	ra,44(sp)
    389c:	02812423          	sw	s0,40(sp)
    38a0:	02912223          	sw	s1,36(sp)
    38a4:	03212023          	sw	s2,32(sp)
    38a8:	01312e23          	sw	s3,28(sp)
    38ac:	01412c23          	sw	s4,24(sp)
    38b0:	01512a23          	sw	s5,20(sp)
    38b4:	01612823          	sw	s6,16(sp)
    38b8:	01712623          	sw	s7,12(sp)
    38bc:	00050b93          	mv	s7,a0
    38c0:	00058b13          	mv	s6,a1
    38c4:	00060a93          	mv	s5,a2
    for (j = 0; j < SPR_H; j++) {
    38c8:	00000a13          	li	s4,0
    38cc:	0400006f          	j	390c <cpu_alpha_sprite+0x78>
            d[i] = blend565(s[j * SPR_W + i], d[i], alpha);
    38d0:	034907b3          	mul	a5,s2,s4
    38d4:	008787b3          	add	a5,a5,s0
    38d8:	00179793          	slli	a5,a5,0x1
    38dc:	00201737          	lui	a4,0x201
    38e0:	00f707b3          	add	a5,a4,a5
    38e4:	0007d503          	lhu	a0,0(a5)
    38e8:	00141493          	slli	s1,s0,0x1
    38ec:	009984b3          	add	s1,s3,s1
    38f0:	0004d583          	lhu	a1,0(s1)
    38f4:	000a8613          	mv	a2,s5
    38f8:	e95ff0ef          	jal	378c <blend565>
    38fc:	00a49023          	sh	a0,0(s1)
        for (i = 0; i < SPR_W; i++)
    3900:	00140413          	addi	s0,s0,1
    3904:	fd2446e3          	blt	s0,s2,38d0 <cpu_alpha_sprite+0x3c>
    for (j = 0; j < SPR_H; j++) {
    3908:	001a0a13          	addi	s4,s4,1
    390c:	8201a903          	lw	s2,-2016(gp) # 7918 <g_blk>
    3910:	032a5663          	bge	s4,s2,393c <cpu_alpha_sprite+0xa8>
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
    3914:	016a07b3          	add	a5,s4,s6
    3918:	00479993          	slli	s3,a5,0x4
    391c:	40f989b3          	sub	s3,s3,a5
    3920:	00699993          	slli	s3,s3,0x6
    3924:	017989b3          	add	s3,s3,s7
    3928:	00199993          	slli	s3,s3,0x1
    392c:	82c1a783          	lw	a5,-2004(gp) # 7924 <g_fb_back>
    3930:	00f989b3          	add	s3,s3,a5
        for (i = 0; i < SPR_W; i++)
    3934:	00000413          	li	s0,0
    3938:	fcdff06f          	j	3904 <cpu_alpha_sprite+0x70>
}
    393c:	02c12083          	lw	ra,44(sp)
    3940:	02812403          	lw	s0,40(sp)
    3944:	02412483          	lw	s1,36(sp)
    3948:	02012903          	lw	s2,32(sp)
    394c:	01c12983          	lw	s3,28(sp)
    3950:	01812a03          	lw	s4,24(sp)
    3954:	01412a83          	lw	s5,20(sp)
    3958:	01012b03          	lw	s6,16(sp)
    395c:	00c12b83          	lw	s7,12(sp)
    3960:	03010113          	addi	sp,sp,48
    3964:	00008067          	ret

00003968 <cpu_key_sprite>:
    for (j = 0; j < SPR_H; j++) {
    3968:	00000893          	li	a7,0
    396c:	04c0006f          	j	39b8 <cpu_key_sprite+0x50>
            if (c != (uint16_t)KEY_COLOR) d[i] = c;
    3970:	00171693          	slli	a3,a4,0x1
    3974:	00d806b3          	add	a3,a6,a3
    3978:	00f69023          	sh	a5,0(a3)
        for (i = 0; i < SPR_W; i++) {
    397c:	00170713          	addi	a4,a4,1 # 201001 <__freertos_irq_stack_top+0x1bdc61>
    3980:	02c75a63          	bge	a4,a2,39b4 <cpu_key_sprite+0x4c>
            uint16_t c = s[j * SPR_W + i];
    3984:	031607b3          	mul	a5,a2,a7
    3988:	00e787b3          	add	a5,a5,a4
    398c:	00179793          	slli	a5,a5,0x1
    3990:	002016b7          	lui	a3,0x201
    3994:	00f687b3          	add	a5,a3,a5
    3998:	0007d783          	lhu	a5,0(a5)
    399c:	01079793          	slli	a5,a5,0x10
    39a0:	0107d793          	srli	a5,a5,0x10
            if (c != (uint16_t)KEY_COLOR) d[i] = c;
    39a4:	000106b7          	lui	a3,0x10
    39a8:	81f68693          	addi	a3,a3,-2017 # f81f <__global_pointer$+0x7727>
    39ac:	fcd792e3          	bne	a5,a3,3970 <cpu_key_sprite+0x8>
    39b0:	fcdff06f          	j	397c <cpu_key_sprite+0x14>
    for (j = 0; j < SPR_H; j++) {
    39b4:	00188893          	addi	a7,a7,1
    39b8:	8201a603          	lw	a2,-2016(gp) # 7918 <g_blk>
    39bc:	02c8d663          	bge	a7,a2,39e8 <cpu_key_sprite+0x80>
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
    39c0:	00b887b3          	add	a5,a7,a1
    39c4:	00479813          	slli	a6,a5,0x4
    39c8:	40f80833          	sub	a6,a6,a5
    39cc:	00681813          	slli	a6,a6,0x6
    39d0:	00a80833          	add	a6,a6,a0
    39d4:	00181813          	slli	a6,a6,0x1
    39d8:	82c1a783          	lw	a5,-2004(gp) # 7924 <g_fb_back>
    39dc:	00f80833          	add	a6,a6,a5
        for (i = 0; i < SPR_W; i++) {
    39e0:	00000713          	li	a4,0
    39e4:	f9dff06f          	j	3980 <cpu_key_sprite+0x18>
}
    39e8:	00008067          	ret

000039ec <glyph_of>:
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    39ec:	f9f50793          	addi	a5,a0,-97 # 200f9f <__freertos_irq_stack_top+0x1bdbff>
    39f0:	0ff7f793          	zext.b	a5,a5
    39f4:	01900713          	li	a4,25
    39f8:	00f76663          	bltu	a4,a5,3a04 <glyph_of+0x18>
    39fc:	fe050513          	addi	a0,a0,-32
    3a00:	0ff57513          	zext.b	a0,a0
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return g_font[i].r;
    3a04:	00000713          	li	a4,0
    3a08:	02300793          	li	a5,35
    3a0c:	02e7ce63          	blt	a5,a4,3a48 <glyph_of+0x5c>
    3a10:	000077b7          	lui	a5,0x7
    3a14:	00371693          	slli	a3,a4,0x3
    3a18:	00e686b3          	add	a3,a3,a4
    3a1c:	6b878793          	addi	a5,a5,1720 # 76b8 <g_font>
    3a20:	00d787b3          	add	a5,a5,a3
    3a24:	0007c783          	lbu	a5,0(a5)
    3a28:	00a78663          	beq	a5,a0,3a34 <glyph_of+0x48>
    3a2c:	00170713          	addi	a4,a4,1
    3a30:	fd9ff06f          	j	3a08 <glyph_of+0x1c>
    3a34:	000077b7          	lui	a5,0x7
    3a38:	6b878793          	addi	a5,a5,1720 # 76b8 <g_font>
    3a3c:	00f68533          	add	a0,a3,a5
    3a40:	00150513          	addi	a0,a0,1
    3a44:	00008067          	ret
    return g_font[0].r;
    3a48:	00007537          	lui	a0,0x7
    3a4c:	6b950513          	addi	a0,a0,1721 # 76b9 <g_font+0x1>
}
    3a50:	00008067          	ret

00003a54 <osd_text>:
{
    3a54:	fe010113          	addi	sp,sp,-32
    3a58:	00112e23          	sw	ra,28(sp)
    3a5c:	00812c23          	sw	s0,24(sp)
    3a60:	00912a23          	sw	s1,20(sp)
    3a64:	01212823          	sw	s2,16(sp)
    3a68:	01312623          	sw	s3,12(sp)
    3a6c:	00050493          	mv	s1,a0
    3a70:	00058913          	mv	s2,a1
    3a74:	00060993          	mv	s3,a2
    3a78:	00068413          	mv	s0,a3
    while (*s) {
    3a7c:	1000006f          	j	3b7c <osd_text+0x128>
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3a80:	00000613          	li	a2,0
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    3a84:	01871593          	slli	a1,a4,0x18
    3a88:	4185d593          	srai	a1,a1,0x18
    3a8c:	0205c063          	bltz	a1,3aac <osd_text+0x58>
    3a90:	00000593          	li	a1,0
    3a94:	00b66633          	or	a2,a2,a1
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3a98:	00c7a023          	sw	a2,0(a5)
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3a9c:	01077613          	andi	a2,a4,16
    3aa0:	00060a63          	beqz	a2,3ab4 <osd_text+0x60>
    3aa4:	01041613          	slli	a2,s0,0x10
    3aa8:	0100006f          	j	3ab8 <osd_text+0x64>
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    3aac:	00040593          	mv	a1,s0
    3ab0:	fe5ff06f          	j	3a94 <osd_text+0x40>
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3ab4:	00000613          	li	a2,0
                 | ((bits & 0x20u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    3ab8:	02077593          	andi	a1,a4,32
    3abc:	00058663          	beqz	a1,3ac8 <osd_text+0x74>
    3ac0:	00040593          	mv	a1,s0
    3ac4:	0080006f          	j	3acc <osd_text+0x78>
    3ac8:	00000593          	li	a1,0
    3acc:	00b66633          	or	a2,a2,a1
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3ad0:	00c7a223          	sw	a2,4(a5)
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3ad4:	00477613          	andi	a2,a4,4
    3ad8:	00060663          	beqz	a2,3ae4 <osd_text+0x90>
    3adc:	01041613          	slli	a2,s0,0x10
    3ae0:	0080006f          	j	3ae8 <osd_text+0x94>
    3ae4:	00000613          	li	a2,0
                 | ((bits & 0x08u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    3ae8:	00877593          	andi	a1,a4,8
    3aec:	00058663          	beqz	a1,3af8 <osd_text+0xa4>
    3af0:	00040593          	mv	a1,s0
    3af4:	0080006f          	j	3afc <osd_text+0xa8>
    3af8:	00000593          	li	a1,0
    3afc:	00b66633          	or	a2,a2,a1
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3b00:	00c7a423          	sw	a2,8(a5)
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3b04:	00177613          	andi	a2,a4,1
    3b08:	00060663          	beqz	a2,3b14 <osd_text+0xc0>
    3b0c:	01041613          	slli	a2,s0,0x10
    3b10:	0080006f          	j	3b18 <osd_text+0xc4>
    3b14:	00000613          	li	a2,0
                 | ((bits & 0x02u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    3b18:	00277713          	andi	a4,a4,2
    3b1c:	00070663          	beqz	a4,3b28 <osd_text+0xd4>
    3b20:	00040713          	mv	a4,s0
    3b24:	0080006f          	j	3b2c <osd_text+0xd8>
    3b28:	00000713          	li	a4,0
    3b2c:	00e66733          	or	a4,a2,a4
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3b30:	00e7a623          	sw	a4,12(a5)
        for (row = 0; row < 8; row++) {
    3b34:	00168693          	addi	a3,a3,1
    3b38:	00700793          	li	a5,7
    3b3c:	02d7ce63          	blt	a5,a3,3b78 <osd_text+0x124>
            uint8_t bits = rp[row];
    3b40:	00d507b3          	add	a5,a0,a3
    3b44:	0007c703          	lbu	a4,0(a5)
                                    + (uint32_t)(y + row) * FB_STRIDE + (uint32_t)x * 2u);
    3b48:	01268633          	add	a2,a3,s2
    3b4c:	00461793          	slli	a5,a2,0x4
    3b50:	40c787b3          	sub	a5,a5,a2
    3b54:	00679793          	slli	a5,a5,0x6
    3b58:	009787b3          	add	a5,a5,s1
    3b5c:	00179793          	slli	a5,a5,0x1
    3b60:	82c1a603          	lw	a2,-2004(gp) # 7924 <g_fb_back>
    3b64:	00c787b3          	add	a5,a5,a2
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    3b68:	04077613          	andi	a2,a4,64
    3b6c:	f0060ae3          	beqz	a2,3a80 <osd_text+0x2c>
    3b70:	01041613          	slli	a2,s0,0x10
    3b74:	f11ff06f          	j	3a84 <osd_text+0x30>
        x += OSD_GLYPH_W;
    3b78:	00848493          	addi	s1,s1,8
    while (*s) {
    3b7c:	0009c503          	lbu	a0,0(s3)
    3b80:	00050a63          	beqz	a0,3b94 <osd_text+0x140>
        const uint8_t *rp = glyph_of(*s++);
    3b84:	00198993          	addi	s3,s3,1
    3b88:	e65ff0ef          	jal	39ec <glyph_of>
        for (row = 0; row < 8; row++) {
    3b8c:	00000693          	li	a3,0
    3b90:	fa9ff06f          	j	3b38 <osd_text+0xe4>
}
    3b94:	01c12083          	lw	ra,28(sp)
    3b98:	01812403          	lw	s0,24(sp)
    3b9c:	01412483          	lw	s1,20(sp)
    3ba0:	01012903          	lw	s2,16(sp)
    3ba4:	00c12983          	lw	s3,12(sp)
    3ba8:	02010113          	addi	sp,sp,32
    3bac:	00008067          	ret

00003bb0 <app>:
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
    3bb0:	0100006f          	j	3bc0 <app+0x10>
    3bb4:	00158593          	addi	a1,a1,1
    3bb8:	00f50023          	sb	a5,0(a0)
    3bbc:	00150513          	addi	a0,a0,1
    3bc0:	0005c783          	lbu	a5,0(a1)
    3bc4:	fe0798e3          	bnez	a5,3bb4 <app+0x4>
    3bc8:	00008067          	ret

00003bcc <appn>:
{
    3bcc:	ff010113          	addi	sp,sp,-16
    char d[12]; int n = 0, i;
    3bd0:	00000793          	li	a5,0
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    3bd4:	00a00813          	li	a6,10
    3bd8:	0305f6b3          	remu	a3,a1,a6
    3bdc:	03068693          	addi	a3,a3,48
    3be0:	01078713          	addi	a4,a5,16
    3be4:	00270733          	add	a4,a4,sp
    3be8:	00178793          	addi	a5,a5,1
    3bec:	fed70a23          	sb	a3,-12(a4)
    3bf0:	00058693          	mv	a3,a1
    3bf4:	0305d5b3          	divu	a1,a1,a6
    3bf8:	00900713          	li	a4,9
    3bfc:	02d77863          	bgeu	a4,a3,3c2c <appn+0x60>
    3c00:	00a00713          	li	a4,10
    3c04:	fcf758e3          	bge	a4,a5,3bd4 <appn+0x8>
    3c08:	00000713          	li	a4,0
    3c0c:	0140006f          	j	3c20 <appn+0x54>
    for (i = 0; i < w - n; i++) *p++ = ' ';
    3c10:	02000693          	li	a3,32
    3c14:	00d50023          	sb	a3,0(a0)
    3c18:	00170713          	addi	a4,a4,1
    3c1c:	00150513          	addi	a0,a0,1
    3c20:	40f606b3          	sub	a3,a2,a5
    3c24:	fed746e3          	blt	a4,a3,3c10 <appn+0x44>
    3c28:	0240006f          	j	3c4c <appn+0x80>
    3c2c:	00000713          	li	a4,0
    3c30:	ff1ff06f          	j	3c20 <appn+0x54>
    while (n) *p++ = d[--n];
    3c34:	fff78793          	addi	a5,a5,-1
    3c38:	01078713          	addi	a4,a5,16
    3c3c:	00270733          	add	a4,a4,sp
    3c40:	ff474703          	lbu	a4,-12(a4)
    3c44:	00e50023          	sb	a4,0(a0)
    3c48:	00150513          	addi	a0,a0,1
    3c4c:	fe0794e3          	bnez	a5,3c34 <appn+0x68>
}
    3c50:	01010113          	addi	sp,sp,16
    3c54:	00008067          	ret

00003c58 <slen>:
static int slen(const char *s) { int n = 0; while (s[n]) n++; return n; }
    3c58:	00050713          	mv	a4,a0
    3c5c:	00000513          	li	a0,0
    3c60:	0080006f          	j	3c68 <slen+0x10>
    3c64:	00150513          	addi	a0,a0,1
    3c68:	00a707b3          	add	a5,a4,a0
    3c6c:	0007c783          	lbu	a5,0(a5)
    3c70:	fe079ae3          	bnez	a5,3c64 <slen+0xc>
    3c74:	00008067          	ret

00003c78 <sseq>:
    while (*a && *a == *b) { a++; b++; }
    3c78:	00c0006f          	j	3c84 <sseq+0xc>
    3c7c:	00150513          	addi	a0,a0,1
    3c80:	00158593          	addi	a1,a1,1
    3c84:	00054783          	lbu	a5,0(a0)
    3c88:	00078663          	beqz	a5,3c94 <sseq+0x1c>
    3c8c:	0005c703          	lbu	a4,0(a1)
    3c90:	fee786e3          	beq	a5,a4,3c7c <sseq+0x4>
    return (*a == *b) ? 1 : 0;
    3c94:	0005c703          	lbu	a4,0(a1)
    3c98:	40e78533          	sub	a0,a5,a4
}
    3c9c:	00153513          	seqz	a0,a0
    3ca0:	00008067          	ret

00003ca4 <scpy>:
static void scpy(char *d, const char *s) { while ((*d++ = *s++) != 0) { } }
    3ca4:	0005c703          	lbu	a4,0(a1)
    3ca8:	00158593          	addi	a1,a1,1
    3cac:	00e50023          	sb	a4,0(a0)
    3cb0:	00150513          	addi	a0,a0,1
    3cb4:	fe0718e3          	bnez	a4,3ca4 <scpy>
    3cb8:	00008067          	ret

00003cbc <scene_name>:
    return (scene == SC_ALPHA) ? "ALPHA" : ((scene == SC_KEY) ? "KEY" : "FILL");
    3cbc:	00100793          	li	a5,1
    3cc0:	02f50263          	beq	a0,a5,3ce4 <scene_name+0x28>
    3cc4:	00200793          	li	a5,2
    3cc8:	00f50863          	beq	a0,a5,3cd8 <scene_name+0x1c>
    3ccc:	00006537          	lui	a0,0x6
    3cd0:	e2850513          	addi	a0,a0,-472 # 5e28 <_data+0x28>
}
    3cd4:	00008067          	ret
    return (scene == SC_ALPHA) ? "ALPHA" : ((scene == SC_KEY) ? "KEY" : "FILL");
    3cd8:	00006537          	lui	a0,0x6
    3cdc:	e3850513          	addi	a0,a0,-456 # 5e38 <_data+0x38>
    3ce0:	00008067          	ret
    3ce4:	00006537          	lui	a0,0x6
    3ce8:	e3050513          	addi	a0,a0,-464 # 5e30 <_data+0x30>
    3cec:	00008067          	ret

00003cf0 <path_label>:
    return (path == PATH_SPLIT) ? "SPLIT" : ((path == PATH_CPU) ? "CPU ONLY" : "HW ONLY");
    3cf0:	02050263          	beqz	a0,3d14 <path_label+0x24>
    3cf4:	00100793          	li	a5,1
    3cf8:	00f50863          	beq	a0,a5,3d08 <path_label+0x18>
    3cfc:	00006537          	lui	a0,0x6
    3d00:	e3c50513          	addi	a0,a0,-452 # 5e3c <_data+0x3c>
}
    3d04:	00008067          	ret
    return (path == PATH_SPLIT) ? "SPLIT" : ((path == PATH_CPU) ? "CPU ONLY" : "HW ONLY");
    3d08:	00006537          	lui	a0,0x6
    3d0c:	e4c50513          	addi	a0,a0,-436 # 5e4c <_data+0x4c>
    3d10:	00008067          	ret
    3d14:	00006537          	lui	a0,0x6
    3d18:	e4450513          	addi	a0,a0,-444 # 5e44 <_data+0x44>
    3d1c:	00008067          	ret

00003d20 <fmt_stat>:
{
    3d20:	fe010113          	addi	sp,sp,-32
    3d24:	00112e23          	sw	ra,28(sp)
    3d28:	00812c23          	sw	s0,24(sp)
    3d2c:	00912a23          	sw	s1,20(sp)
    3d30:	01212823          	sw	s2,16(sp)
    3d34:	01312623          	sw	s3,12(sp)
    3d38:	01412423          	sw	s4,8(sp)
    3d3c:	01512223          	sw	s5,4(sp)
    3d40:	01612023          	sw	s6,0(sp)
    3d44:	00058913          	mv	s2,a1
    3d48:	00060493          	mv	s1,a2
    3d4c:	00068413          	mv	s0,a3
    3d50:	00070b13          	mv	s6,a4
    3d54:	00078993          	mv	s3,a5
    3d58:	00080a93          	mv	s5,a6
    3d5c:	00088a13          	mv	s4,a7
    if (hw_fps  > 999u) hw_fps  = 999u;        /* 钳位只为把最长串钉死在上界内 */
    3d60:	3e700793          	li	a5,999
    3d64:	00b7f463          	bgeu	a5,a1,3d6c <fmt_stat+0x4c>
    3d68:	3e700913          	li	s2,999
    if (cpu_fps > 999u) cpu_fps = 999u;
    3d6c:	3e700793          	li	a5,999
    3d70:	0097f463          	bgeu	a5,s1,3d78 <fmt_stat+0x58>
    3d74:	3e700493          	li	s1,999
    if (scr_fps >  99u) scr_fps =  99u;
    3d78:	06300793          	li	a5,99
    3d7c:	0087f463          	bgeu	a5,s0,3d84 <fmt_stat+0x64>
    3d80:	06300413          	li	s0,99
    p = app(p, "HW=");   p = appn(p, hw_fps,  3);
    3d84:	000065b7          	lui	a1,0x6
    3d88:	e5858593          	addi	a1,a1,-424 # 5e58 <_data+0x58>
    3d8c:	e25ff0ef          	jal	3bb0 <app>
    3d90:	00300613          	li	a2,3
    3d94:	00090593          	mv	a1,s2
    3d98:	e35ff0ef          	jal	3bcc <appn>
    p = app(p, " CPU="); p = appn(p, cpu_fps, 3);
    3d9c:	000065b7          	lui	a1,0x6
    3da0:	e5c58593          	addi	a1,a1,-420 # 5e5c <_data+0x5c>
    3da4:	e0dff0ef          	jal	3bb0 <app>
    3da8:	00300613          	li	a2,3
    3dac:	00048593          	mv	a1,s1
    3db0:	e1dff0ef          	jal	3bcc <appn>
    p = app(p, " SCR="); p = appn(p, scr_fps, 2);
    3db4:	000065b7          	lui	a1,0x6
    3db8:	e6458593          	addi	a1,a1,-412 # 5e64 <_data+0x64>
    3dbc:	df5ff0ef          	jal	3bb0 <app>
    3dc0:	00200613          	li	a2,2
    3dc4:	00040593          	mv	a1,s0
    3dc8:	e05ff0ef          	jal	3bcc <appn>
    p = app(p, " SZ=");  p = appn(p, (unsigned)blk, 2);
    3dcc:	000065b7          	lui	a1,0x6
    3dd0:	e6c58593          	addi	a1,a1,-404 # 5e6c <_data+0x6c>
    3dd4:	dddff0ef          	jal	3bb0 <app>
    3dd8:	00200613          	li	a2,2
    3ddc:	02412583          	lw	a1,36(sp)
    3de0:	dedff0ef          	jal	3bcc <appn>
    p = app(p, " N=");   p = appn(p, (unsigned)n, 4);
    3de4:	000065b7          	lui	a1,0x6
    3de8:	e7458593          	addi	a1,a1,-396 # 5e74 <_data+0x74>
    3dec:	dc5ff0ef          	jal	3bb0 <app>
    3df0:	00400613          	li	a2,4
    3df4:	000b0593          	mv	a1,s6
    3df8:	dd5ff0ef          	jal	3bcc <appn>
    p = app(p, " SC");   p = appn(p, (unsigned)(scene + 1), 1);
    3dfc:	000065b7          	lui	a1,0x6
    3e00:	e7858593          	addi	a1,a1,-392 # 5e78 <_data+0x78>
    3e04:	dadff0ef          	jal	3bb0 <app>
    3e08:	00100613          	li	a2,1
    3e0c:	00198593          	addi	a1,s3,1
    3e10:	dbdff0ef          	jal	3bcc <appn>
    p = app(p, ":");
    3e14:	000065b7          	lui	a1,0x6
    3e18:	e7c58593          	addi	a1,a1,-388 # 5e7c <_data+0x7c>
    3e1c:	d95ff0ef          	jal	3bb0 <app>
    3e20:	00050413          	mv	s0,a0
    p = app(p, scene_name(scene));
    3e24:	00098513          	mv	a0,s3
    3e28:	e95ff0ef          	jal	3cbc <scene_name>
    3e2c:	00050593          	mv	a1,a0
    3e30:	00040513          	mv	a0,s0
    3e34:	d7dff0ef          	jal	3bb0 <app>
    p = app(p, " A=");   p = appn(p, alpha, 3);
    3e38:	000065b7          	lui	a1,0x6
    3e3c:	e8058593          	addi	a1,a1,-384 # 5e80 <_data+0x80>
    3e40:	d71ff0ef          	jal	3bb0 <app>
    3e44:	00300613          	li	a2,3
    3e48:	000a8593          	mv	a1,s5
    3e4c:	d81ff0ef          	jal	3bcc <appn>
    if (clear_pp)  p = app(p, " E");
    3e50:	040a1063          	bnez	s4,3e90 <fmt_stat+0x170>
    if (frame_adv) p = app(p, " FR");
    3e54:	02012783          	lw	a5,32(sp)
    3e58:	04079463          	bnez	a5,3ea0 <fmt_stat+0x180>
    if (dl)        p = app(p, " L");          /* ★v2.11 列表路径标记（'l' 切换） */
    3e5c:	02812783          	lw	a5,40(sp)
    3e60:	04079863          	bnez	a5,3eb0 <fmt_stat+0x190>
    *p = 0;
    3e64:	00050023          	sb	zero,0(a0)
}
    3e68:	01c12083          	lw	ra,28(sp)
    3e6c:	01812403          	lw	s0,24(sp)
    3e70:	01412483          	lw	s1,20(sp)
    3e74:	01012903          	lw	s2,16(sp)
    3e78:	00c12983          	lw	s3,12(sp)
    3e7c:	00812a03          	lw	s4,8(sp)
    3e80:	00412a83          	lw	s5,4(sp)
    3e84:	00012b03          	lw	s6,0(sp)
    3e88:	02010113          	addi	sp,sp,32
    3e8c:	00008067          	ret
    if (clear_pp)  p = app(p, " E");
    3e90:	000065b7          	lui	a1,0x6
    3e94:	e8458593          	addi	a1,a1,-380 # 5e84 <_data+0x84>
    3e98:	d19ff0ef          	jal	3bb0 <app>
    3e9c:	fb9ff06f          	j	3e54 <fmt_stat+0x134>
    if (frame_adv) p = app(p, " FR");
    3ea0:	000065b7          	lui	a1,0x6
    3ea4:	e8858593          	addi	a1,a1,-376 # 5e88 <_data+0x88>
    3ea8:	d09ff0ef          	jal	3bb0 <app>
    3eac:	fb1ff06f          	j	3e5c <fmt_stat+0x13c>
    if (dl)        p = app(p, " L");          /* ★v2.11 列表路径标记（'l' 切换） */
    3eb0:	000065b7          	lui	a1,0x6
    3eb4:	e8c58593          	addi	a1,a1,-372 # 5e8c <_data+0x8c>
    3eb8:	cf9ff0ef          	jal	3bb0 <app>
    3ebc:	fa9ff06f          	j	3e64 <fmt_stat+0x144>

00003ec0 <osd_build>:
{
    3ec0:	f9010113          	addi	sp,sp,-112
    3ec4:	06112623          	sw	ra,108(sp)
    fmt_stat(tmp, g_hw_fps, g_cpu_fps, g_scr_fps, n, scene, alpha, clear_pp, frame_adv, blk, dl);
    3ec8:	01012423          	sw	a6,8(sp)
    3ecc:	00f12223          	sw	a5,4(sp)
    3ed0:	00e12023          	sw	a4,0(sp)
    3ed4:	00068893          	mv	a7,a3
    3ed8:	00060813          	mv	a6,a2
    3edc:	00058793          	mv	a5,a1
    3ee0:	00050713          	mv	a4,a0
    3ee4:	8a01a683          	lw	a3,-1888(gp) # 7998 <g_scr_fps>
    3ee8:	8a41a603          	lw	a2,-1884(gp) # 799c <g_cpu_fps>
    3eec:	8a81a583          	lw	a1,-1880(gp) # 79a0 <g_hw_fps>
    3ef0:	01c10513          	addi	a0,sp,28
    3ef4:	e2dff0ef          	jal	3d20 <fmt_stat>
    if (!sseq(tmp, g_osd_line)) { scpy(g_osd_line, tmp); g_osd_dirty = 1; }
    3ef8:	8e418593          	addi	a1,gp,-1820 # 79dc <g_osd_line>
    3efc:	01c10513          	addi	a0,sp,28
    3f00:	d79ff0ef          	jal	3c78 <sseq>
    3f04:	00050863          	beqz	a0,3f14 <osd_build+0x54>
}
    3f08:	06c12083          	lw	ra,108(sp)
    3f0c:	07010113          	addi	sp,sp,112
    3f10:	00008067          	ret
    if (!sseq(tmp, g_osd_line)) { scpy(g_osd_line, tmp); g_osd_dirty = 1; }
    3f14:	01c10593          	addi	a1,sp,28
    3f18:	8e418513          	addi	a0,gp,-1820 # 79dc <g_osd_line>
    3f1c:	d89ff0ef          	jal	3ca4 <scpy>
    3f20:	00100713          	li	a4,1
    3f24:	80e1ac23          	sw	a4,-2024(gp) # 7910 <g_osd_dirty>
}
    3f28:	fe1ff06f          	j	3f08 <osd_build+0x48>

00003f2c <osd_service>:
{
    3f2c:	fd010113          	addi	sp,sp,-48
    3f30:	02112623          	sw	ra,44(sp)
    3f34:	02812423          	sw	s0,40(sp)
    3f38:	01512a23          	sw	s5,20(sp)
    3f3c:	00050313          	mv	t1,a0
    3f40:	00078a93          	mv	s5,a5
    uint32_t el = (uint32_t)(t_now - g_osd_t0);
    3f44:	8ac1a403          	lw	s0,-1876(gp) # 79a4 <g_osd_t0>
    3f48:	40850433          	sub	s0,a0,s0
    if (el < (uint32_t)BSP_CLINT_HZ) return 0;         /* 每秒最多算一次 */
    3f4c:	05f5ee37          	lui	t3,0x5f5e
    3f50:	0ffe0e13          	addi	t3,t3,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f1ad5f>
    3f54:	008e6e63          	bltu	t3,s0,3f70 <osd_service+0x44>
    3f58:	00000513          	li	a0,0
}
    3f5c:	02c12083          	lw	ra,44(sp)
    3f60:	02812403          	lw	s0,40(sp)
    3f64:	01412a83          	lw	s5,20(sp)
    3f68:	03010113          	addi	sp,sp,48
    3f6c:	00008067          	ret
    3f70:	02912223          	sw	s1,36(sp)
    3f74:	03212023          	sw	s2,32(sp)
    3f78:	01312e23          	sw	s3,28(sp)
    3f7c:	01412c23          	sw	s4,24(sp)
    3f80:	01612823          	sw	s6,16(sp)
    3f84:	01712623          	sw	s7,12(sp)
    3f88:	00058513          	mv	a0,a1
    3f8c:	00060993          	mv	s3,a2
    3f90:	00068913          	mv	s2,a3
    3f94:	00070a13          	mv	s4,a4
    3f98:	00080b13          	mv	s6,a6
    3f9c:	00088b93          	mv	s7,a7
    g_osd_t0  = t_now;
    3fa0:	8a61a623          	sw	t1,-1876(gp) # 79a4 <g_osd_t0>
    g_hw_fps  = (uint32_t)(((uint64_t)hw_frames  * (uint64_t)BSP_CLINT_HZ) / el);
    3fa4:	05f5e4b7          	lui	s1,0x5f5e
    3fa8:	10048493          	addi	s1,s1,256 # 5f5e100 <__freertos_irq_stack_top+0x5f1ad60>
    3fac:	0295b5b3          	mulhu	a1,a1,s1
    3fb0:	00040613          	mv	a2,s0
    3fb4:	00000693          	li	a3,0
    3fb8:	02950533          	mul	a0,a0,s1
    3fbc:	195010ef          	jal	5950 <__udivdi3>
    3fc0:	8aa1a423          	sw	a0,-1880(gp) # 79a0 <g_hw_fps>
    g_cpu_fps = (uint32_t)(((uint64_t)cpu_frames * (uint64_t)BSP_CLINT_HZ) / el);
    3fc4:	0299b5b3          	mulhu	a1,s3,s1
    3fc8:	00040613          	mv	a2,s0
    3fcc:	00000693          	li	a3,0
    3fd0:	02998533          	mul	a0,s3,s1
    3fd4:	17d010ef          	jal	5950 <__udivdi3>
    3fd8:	8aa1a223          	sw	a0,-1884(gp) # 799c <g_cpu_fps>
    g_scr_fps = (uint32_t)(((uint64_t)scr_frames * (uint64_t)BSP_CLINT_HZ) / el);
    3fdc:	029935b3          	mulhu	a1,s2,s1
    3fe0:	00040613          	mv	a2,s0
    3fe4:	00000693          	li	a3,0
    3fe8:	02990533          	mul	a0,s2,s1
    3fec:	165010ef          	jal	5950 <__udivdi3>
    3ff0:	8aa1a023          	sw	a0,-1888(gp) # 7998 <g_scr_fps>
    osd_build(n, scene, alpha, clear_pp, frame_adv, blk, dl);
    3ff4:	03812803          	lw	a6,56(sp)
    3ff8:	03412783          	lw	a5,52(sp)
    3ffc:	03012703          	lw	a4,48(sp)
    4000:	000b8693          	mv	a3,s7
    4004:	000b0613          	mv	a2,s6
    4008:	000a8593          	mv	a1,s5
    400c:	000a0513          	mv	a0,s4
    4010:	eb1ff0ef          	jal	3ec0 <osd_build>
    return 1;
    4014:	00100513          	li	a0,1
    4018:	02412483          	lw	s1,36(sp)
    401c:	02012903          	lw	s2,32(sp)
    4020:	01c12983          	lw	s3,28(sp)
    4024:	01812a03          	lw	s4,24(sp)
    4028:	01012b03          	lw	s6,16(sp)
    402c:	00c12b83          	lw	s7,12(sp)
    4030:	f2dff06f          	j	3f5c <osd_service+0x30>

00004034 <osd_blit>:
{
    4034:	ff010113          	addi	sp,sp,-16
    4038:	00112623          	sw	ra,12(sp)
    403c:	00812423          	sw	s0,8(sp)
    4040:	00912223          	sw	s1,4(sp)
    4044:	01212023          	sw	s2,0(sp)
    4048:	00050493          	mv	s1,a0
    404c:	00058413          	mv	s0,a1
    cpu_fill32(g_fb_back, OSD_TEXT_X0, 0, OSD_LEFT_PX, OSD_H, COL_OSD_BG);
    4050:	00000793          	li	a5,0
    4054:	01000713          	li	a4,16
    4058:	20000693          	li	a3,512
    405c:	00000613          	li	a2,0
    4060:	00800593          	li	a1,8
    4064:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    4068:	e90ff0ef          	jal	36f8 <cpu_fill32>
    cpu_fill32(g_fb_back, FB_WIDTH - OSD_RIGHT_PX, 0, OSD_RIGHT_PX, OSD_H, COL_OSD_BG);
    406c:	00000793          	li	a5,0
    4070:	01000713          	li	a4,16
    4074:	04000693          	li	a3,64
    4078:	00000613          	li	a2,0
    407c:	38000593          	li	a1,896
    4080:	82c1a503          	lw	a0,-2004(gp) # 7924 <g_fb_back>
    4084:	e74ff0ef          	jal	36f8 <cpu_fill32>
    osd_text(OSD_TEXT_X0, OSD_TEXT_Y, line, COL_WHITE);
    4088:	00010937          	lui	s2,0x10
    408c:	fff90693          	addi	a3,s2,-1 # ffff <__global_pointer$+0x7f07>
    4090:	00048613          	mv	a2,s1
    4094:	00400593          	li	a1,4
    4098:	00800513          	li	a0,8
    409c:	9b9ff0ef          	jal	3a54 <osd_text>
    osd_text(FB_WIDTH - OSD_GLYPH_W * slen(lbl), OSD_TEXT_Y, lbl, COL_WHITE);
    40a0:	00040513          	mv	a0,s0
    40a4:	bb5ff0ef          	jal	3c58 <slen>
    40a8:	07800793          	li	a5,120
    40ac:	40a78533          	sub	a0,a5,a0
    40b0:	fff90693          	addi	a3,s2,-1
    40b4:	00040613          	mv	a2,s0
    40b8:	00400593          	li	a1,4
    40bc:	00351513          	slli	a0,a0,0x3
    40c0:	995ff0ef          	jal	3a54 <osd_text>
}
    40c4:	00c12083          	lw	ra,12(sp)
    40c8:	00812403          	lw	s0,8(sp)
    40cc:	00412483          	lw	s1,4(sp)
    40d0:	00012903          	lw	s2,0(sp)
    40d4:	01010113          	addi	sp,sp,16
    40d8:	00008067          	ret

000040dc <uart_status_raw>:
    return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS);
    40dc:	f80107b7          	lui	a5,0xf8010
    40e0:	0047a503          	lw	a0,4(a5) # f8010004 <__freertos_irq_stack_top+0xf7fccc64>
}
    40e4:	00008067          	ret

000040e8 <uart_poll_char>:
{
    40e8:	ff010113          	addi	sp,sp,-16
    40ec:	00112623          	sw	ra,12(sp)
    if ((uart_status_raw() >> 24) == 0u) return 0;
    40f0:	fedff0ef          	jal	40dc <uart_status_raw>
    40f4:	01855513          	srli	a0,a0,0x18
    40f8:	00050e63          	beqz	a0,4114 <uart_poll_char+0x2c>
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
    40fc:	f80107b7          	lui	a5,0xf8010
    4100:	0007a503          	lw	a0,0(a5) # f8010000 <__freertos_irq_stack_top+0xf7fccc60>
    4104:	0ff57513          	zext.b	a0,a0
}
    4108:	00c12083          	lw	ra,12(sp)
    410c:	01010113          	addi	sp,sp,16
    4110:	00008067          	ret
    if ((uart_status_raw() >> 24) == 0u) return 0;
    4114:	00000513          	li	a0,0
    4118:	ff1ff06f          	j	4108 <uart_poll_char+0x20>

0000411c <nline_feed>:
{
    411c:	00050793          	mv	a5,a0
    if (!g_nl_on) {
    4120:	8981a503          	lw	a0,-1896(gp) # 7990 <g_nl_on>
    4124:	02051263          	bnez	a0,4148 <nline_feed+0x2c>
        if (c != '=') return NL_NONE;    /* 与 '=' 行无关：原样交回单字符命令分支 */
    4128:	03d00713          	li	a4,61
    412c:	00e78463          	beq	a5,a4,4134 <nline_feed+0x18>
}
    4130:	00008067          	ret
        g_nl_on = 1; g_nl_n = 0;         /* 看到 '='：启用行缓冲 */
    4134:	00100713          	li	a4,1
    4138:	88e1ac23          	sw	a4,-1896(gp) # 7990 <g_nl_on>
    413c:	8801ae23          	sw	zero,-1892(gp) # 7994 <g_nl_n>
        return NL_MORE;
    4140:	00100513          	li	a0,1
    4144:	00008067          	ret
    if (c == '\n' || c == '\r') {        /* 行终止：结算 */
    4148:	00a00713          	li	a4,10
    414c:	04e78063          	beq	a5,a4,418c <nline_feed+0x70>
    4150:	00d00713          	li	a4,13
    4154:	02e78c63          	beq	a5,a4,418c <nline_feed+0x70>
    if (c < '0' || c > '9' || g_nl_n >= (unsigned)NLINE_MAX) {
    4158:	fd078713          	addi	a4,a5,-48
    415c:	00900693          	li	a3,9
    4160:	08e6ec63          	bltu	a3,a4,41f8 <nline_feed+0xdc>
    4164:	89c1a683          	lw	a3,-1892(gp) # 7994 <g_nl_n>
    4168:	00b00713          	li	a4,11
    416c:	08d76663          	bltu	a4,a3,41f8 <nline_feed+0xdc>
    g_nl[g_nl_n++] = (char)c;
    4170:	00168613          	addi	a2,a3,1
    4174:	88c1ae23          	sw	a2,-1892(gp) # 7994 <g_nl_n>
    4178:	8d818713          	addi	a4,gp,-1832 # 79d0 <g_nl>
    417c:	00d70733          	add	a4,a4,a3
    4180:	00f70023          	sb	a5,0(a4)
    return NL_MORE;
    4184:	00100513          	li	a0,1
    4188:	00008067          	ret
        g_nl_on = 0;
    418c:	8801ac23          	sw	zero,-1896(gp) # 7990 <g_nl_on>
        if (g_nl_n == 0u) return NL_ERR; /* "=" 后面一个数字都没有 */
    4190:	89c1a603          	lw	a2,-1892(gp) # 7994 <g_nl_n>
    4194:	06060863          	beqz	a2,4204 <nline_feed+0xe8>
        for (i = 0; i < g_nl_n; i++) {
    4198:	00000693          	li	a3,0
        v = 0u;
    419c:	00000793          	li	a5,0
    41a0:	0080006f          	j	41a8 <nline_feed+0x8c>
        for (i = 0; i < g_nl_n; i++) {
    41a4:	00168693          	addi	a3,a3,1
    41a8:	02c6fc63          	bgeu	a3,a2,41e0 <nline_feed+0xc4>
            v = v * 10u + (unsigned)(g_nl[i] - '0');
    41ac:	00279713          	slli	a4,a5,0x2
    41b0:	00f70733          	add	a4,a4,a5
    41b4:	00171713          	slli	a4,a4,0x1
    41b8:	8d818793          	addi	a5,gp,-1832 # 79d0 <g_nl>
    41bc:	00d787b3          	add	a5,a5,a3
    41c0:	0007c783          	lbu	a5,0(a5)
    41c4:	00e787b3          	add	a5,a5,a4
    41c8:	fd078793          	addi	a5,a5,-48
            if (v > (unsigned)N_MAX) v = (unsigned)N_MAX;
    41cc:	00001737          	lui	a4,0x1
    41d0:	77070713          	addi	a4,a4,1904 # 1770 <main+0x66c>
    41d4:	fcf778e3          	bgeu	a4,a5,41a4 <nline_feed+0x88>
    41d8:	00070793          	mv	a5,a4
    41dc:	fc9ff06f          	j	41a4 <nline_feed+0x88>
        if (v < (unsigned)N_MIN) v = (unsigned)N_MIN;   /* 下界同样只钳不拒 */
    41e0:	01800713          	li	a4,24
    41e4:	00f76463          	bltu	a4,a5,41ec <nline_feed+0xd0>
    41e8:	01900793          	li	a5,25
        *out = (int)v;
    41ec:	00f5a023          	sw	a5,0(a1)
        return NL_OK;
    41f0:	00200513          	li	a0,2
    41f4:	00008067          	ret
        g_nl_on = 0;                     /* 非数字 / 太长：作废并立即复位 */
    41f8:	8801ac23          	sw	zero,-1896(gp) # 7990 <g_nl_on>
        return NL_ERR;
    41fc:	fff00513          	li	a0,-1
    4200:	00008067          	ret
        if (g_nl_n == 0u) return NL_ERR; /* "=" 后面一个数字都没有 */
    4204:	fff00513          	li	a0,-1
    4208:	00008067          	ret

0000420c <lcg>:
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }
    420c:	00052783          	lw	a5,0(a0)
    4210:	00196737          	lui	a4,0x196
    4214:	60d70713          	addi	a4,a4,1549 # 19660d <__freertos_irq_stack_top+0x15326d>
    4218:	02e787b3          	mul	a5,a5,a4
    421c:	3c6ef737          	lui	a4,0x3c6ef
    4220:	35f70713          	addi	a4,a4,863 # 3c6ef35f <__freertos_irq_stack_top+0x3c6abfbf>
    4224:	00e787b3          	add	a5,a5,a4
    4228:	00f52023          	sw	a5,0(a0)
    422c:	0107d513          	srli	a0,a5,0x10
    4230:	00008067          	ret

00004234 <scene_init>:
{
    4234:	fd010113          	addi	sp,sp,-48
    4238:	02112623          	sw	ra,44(sp)
    423c:	02812423          	sw	s0,40(sp)
    4240:	02912223          	sw	s1,36(sp)
    4244:	03212023          	sw	s2,32(sp)
    4248:	01312e23          	sw	s3,28(sp)
    424c:	01412c23          	sw	s4,24(sp)
    4250:	01512a23          	sw	s5,20(sp)
    4254:	01612823          	sw	s6,16(sp)
    4258:	00050a93          	mv	s5,a0
    425c:	00058b13          	mv	s6,a1
    int xr = FB_WIDTH - SCENE_MX(g_blk);
    4260:	8201a703          	lw	a4,-2016(gp) # 7918 <g_blk>
    4264:	0f000a13          	li	s4,240
    4268:	40ea0a33          	sub	s4,s4,a4
    426c:	002a1a13          	slli	s4,s4,0x2
    int yr = HALF_H   - SCENE_MY(g_blk);
    4270:	00271793          	slli	a5,a4,0x2
    4274:	00e787b3          	add	a5,a5,a4
    4278:	01f7d993          	srli	s3,a5,0x1f
    427c:	00f989b3          	add	s3,s3,a5
    4280:	4019d993          	srai	s3,s3,0x1
    4284:	413009b3          	neg	s3,s3
    4288:	10498993          	addi	s3,s3,260
    for (side = 0; side < NSIDE; side++) {
    428c:	00000913          	li	s2,0
    4290:	2240006f          	j	44b4 <scene_init+0x280>
            b->dx = b->x; b->dy = b->y;                      /* 本侧"已画位置"初始对齐 */
    4294:	000087b7          	lui	a5,0x8
    4298:	00241713          	slli	a4,s0,0x2
    429c:	00870733          	add	a4,a4,s0
    42a0:	00271713          	slli	a4,a4,0x2
    42a4:	0001d6b7          	lui	a3,0x1d
    42a8:	4c068693          	addi	a3,a3,1216 # 1d4c0 <__global_pointer$+0x153c8>
    42ac:	02d906b3          	mul	a3,s2,a3
    42b0:	00d70733          	add	a4,a4,a3
    42b4:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    42b8:	00e787b3          	add	a5,a5,a4
    42bc:	00079683          	lh	a3,0(a5)
    42c0:	00d79423          	sh	a3,8(a5)
    42c4:	00279703          	lh	a4,2(a5)
    42c8:	00e79523          	sh	a4,10(a5)
            b->tx = b->x; b->ty = b->y;                      /* 本趟快照初始对齐 */
    42cc:	00d79623          	sh	a3,12(a5)
    42d0:	00e79723          	sh	a4,14(a5)
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
    42d4:	0084d713          	srli	a4,s1,0x8
    42d8:	00b71713          	slli	a4,a4,0xb
    42dc:	01071713          	slli	a4,a4,0x10
    42e0:	01075713          	srli	a4,a4,0x10
    42e4:	00855693          	srli	a3,a0,0x8
    42e8:	00569693          	slli	a3,a3,0x5
    42ec:	7e06f693          	andi	a3,a3,2016
    42f0:	00d76733          	or	a4,a4,a3
                                  | ((r1 + r2) & 0x1Fu));
    42f4:	00a484b3          	add	s1,s1,a0
    42f8:	01f4f493          	andi	s1,s1,31
            b->color = (uint16_t)((((r1 >> 8) & 0x1Fu) << 11) | (((r2 >> 8) & 0x3Fu) << 5)
    42fc:	00976733          	or	a4,a4,s1
    4300:	00e79823          	sh	a4,16(a5)
        for (i = 0; i < n; i++) {
    4304:	00140413          	addi	s0,s0,1
    4308:	1b545463          	bge	s0,s5,44b0 <scene_init+0x27c>
            uint32_t r1 = lcg(&s), r2 = lcg(&s);
    430c:	00c10513          	addi	a0,sp,12
    4310:	efdff0ef          	jal	420c <lcg>
    4314:	00050493          	mv	s1,a0
    4318:	00c10513          	addi	a0,sp,12
    431c:	ef1ff0ef          	jal	420c <lcg>
            b->sz = (uint8_t)(sz_fixed ? SPR_W : BLK_W);
    4320:	8201a583          	lw	a1,-2016(gp) # 7918 <g_blk>
    4324:	0ff5f693          	zext.b	a3,a1
    4328:	000087b7          	lui	a5,0x8
    432c:	00241713          	slli	a4,s0,0x2
    4330:	00870733          	add	a4,a4,s0
    4334:	00271713          	slli	a4,a4,0x2
    4338:	0001d637          	lui	a2,0x1d
    433c:	4c060613          	addi	a2,a2,1216 # 1d4c0 <__global_pointer$+0x153c8>
    4340:	02c90633          	mul	a2,s2,a2
    4344:	00c70733          	add	a4,a4,a2
    4348:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    434c:	00e787b3          	add	a5,a5,a4
    4350:	00d78923          	sb	a3,18(a5)
            b->vx = (int16_t)((int)(r1 % 7u) - 3);
    4354:	00700613          	li	a2,7
    4358:	02c4f633          	remu	a2,s1,a2
    435c:	ffd60613          	addi	a2,a2,-3
    4360:	00c79223          	sh	a2,4(a5)
            b->vy = (int16_t)((int)(r2 % 5u) - 2);
    4364:	00500713          	li	a4,5
    4368:	02e57733          	remu	a4,a0,a4
    436c:	ffe70713          	addi	a4,a4,-2
    4370:	00e79323          	sh	a4,6(a5)
            if (!b->vx) b->vx = 1;
    4374:	02061a63          	bnez	a2,43a8 <scene_init+0x174>
    4378:	00008637          	lui	a2,0x8
    437c:	00241793          	slli	a5,s0,0x2
    4380:	008787b3          	add	a5,a5,s0
    4384:	00279793          	slli	a5,a5,0x2
    4388:	0001d837          	lui	a6,0x1d
    438c:	4c080813          	addi	a6,a6,1216 # 1d4c0 <__global_pointer$+0x153c8>
    4390:	03090833          	mul	a6,s2,a6
    4394:	010787b3          	add	a5,a5,a6
    4398:	a2060613          	addi	a2,a2,-1504 # 7a20 <g_sc>
    439c:	00f607b3          	add	a5,a2,a5
    43a0:	00100613          	li	a2,1
    43a4:	00c79223          	sh	a2,4(a5)
            if (!b->vy) b->vy = 1;
    43a8:	02071a63          	bnez	a4,43dc <scene_init+0x1a8>
    43ac:	00008737          	lui	a4,0x8
    43b0:	00241793          	slli	a5,s0,0x2
    43b4:	008787b3          	add	a5,a5,s0
    43b8:	00279793          	slli	a5,a5,0x2
    43bc:	0001d637          	lui	a2,0x1d
    43c0:	4c060613          	addi	a2,a2,1216 # 1d4c0 <__global_pointer$+0x153c8>
    43c4:	02c90633          	mul	a2,s2,a2
    43c8:	00c787b3          	add	a5,a5,a2
    43cc:	a2070713          	addi	a4,a4,-1504 # 7a20 <g_sc>
    43d0:	00f707b3          	add	a5,a4,a5
    43d4:	00100713          	li	a4,1
    43d8:	00e79323          	sh	a4,6(a5)
            b->x  = (int16_t)((int)(r1 % (uint32_t)xr) & ~1);
    43dc:	0344f7b3          	remu	a5,s1,s4
    43e0:	ffe7f793          	andi	a5,a5,-2
    43e4:	01079793          	slli	a5,a5,0x10
    43e8:	4107d793          	srai	a5,a5,0x10
    43ec:	00008637          	lui	a2,0x8
    43f0:	00241713          	slli	a4,s0,0x2
    43f4:	00870733          	add	a4,a4,s0
    43f8:	00271713          	slli	a4,a4,0x2
    43fc:	0001d837          	lui	a6,0x1d
    4400:	4c080813          	addi	a6,a6,1216 # 1d4c0 <__global_pointer$+0x153c8>
    4404:	03090833          	mul	a6,s2,a6
    4408:	01070733          	add	a4,a4,a6
    440c:	a2060613          	addi	a2,a2,-1504 # 7a20 <g_sc>
    4410:	00e60633          	add	a2,a2,a4
    4414:	00f61023          	sh	a5,0(a2)
            b->y  = (int16_t)(int)(r2 % (uint32_t)yr);
    4418:	03357733          	remu	a4,a0,s3
    441c:	01071713          	slli	a4,a4,0x10
    4420:	41075713          	srai	a4,a4,0x10
    4424:	00e61123          	sh	a4,2(a2)
            if (b->x + b->sz > FB_WIDTH) b->x = (int16_t)(FB_WIDTH - b->sz);
    4428:	0ff5f593          	zext.b	a1,a1
    442c:	00b787b3          	add	a5,a5,a1
    4430:	3c000613          	li	a2,960
    4434:	02f65c63          	bge	a2,a5,446c <scene_init+0x238>
    4438:	3c000893          	li	a7,960
    443c:	40d888b3          	sub	a7,a7,a3
    4440:	00008637          	lui	a2,0x8
    4444:	00241793          	slli	a5,s0,0x2
    4448:	008787b3          	add	a5,a5,s0
    444c:	00279793          	slli	a5,a5,0x2
    4450:	0001d837          	lui	a6,0x1d
    4454:	4c080813          	addi	a6,a6,1216 # 1d4c0 <__global_pointer$+0x153c8>
    4458:	03090833          	mul	a6,s2,a6
    445c:	010787b3          	add	a5,a5,a6
    4460:	a2060613          	addi	a2,a2,-1504 # 7a20 <g_sc>
    4464:	00f607b3          	add	a5,a2,a5
    4468:	01179023          	sh	a7,0(a5)
            if (b->y + b->sz > HALF_H)   b->y = (int16_t)(HALF_H   - b->sz);
    446c:	00b70733          	add	a4,a4,a1
    4470:	10400793          	li	a5,260
    4474:	e2e7d0e3          	bge	a5,a4,4294 <scene_init+0x60>
    4478:	10400613          	li	a2,260
    447c:	40d60633          	sub	a2,a2,a3
    4480:	00008737          	lui	a4,0x8
    4484:	00241793          	slli	a5,s0,0x2
    4488:	008787b3          	add	a5,a5,s0
    448c:	00279793          	slli	a5,a5,0x2
    4490:	0001d6b7          	lui	a3,0x1d
    4494:	4c068693          	addi	a3,a3,1216 # 1d4c0 <__global_pointer$+0x153c8>
    4498:	02d906b3          	mul	a3,s2,a3
    449c:	00d787b3          	add	a5,a5,a3
    44a0:	a2070713          	addi	a4,a4,-1504 # 7a20 <g_sc>
    44a4:	00f707b3          	add	a5,a4,a5
    44a8:	00c79123          	sh	a2,2(a5)
    44ac:	de9ff06f          	j	4294 <scene_init+0x60>
    for (side = 0; side < NSIDE; side++) {
    44b0:	00190913          	addi	s2,s2,1
    44b4:	00100793          	li	a5,1
    44b8:	0127c863          	blt	a5,s2,44c8 <scene_init+0x294>
        uint32_t s = seed;
    44bc:	01612623          	sw	s6,12(sp)
        for (i = 0; i < n; i++) {
    44c0:	00000413          	li	s0,0
    44c4:	e45ff06f          	j	4308 <scene_init+0xd4>
}
    44c8:	02c12083          	lw	ra,44(sp)
    44cc:	02812403          	lw	s0,40(sp)
    44d0:	02412483          	lw	s1,36(sp)
    44d4:	02012903          	lw	s2,32(sp)
    44d8:	01c12983          	lw	s3,28(sp)
    44dc:	01812a03          	lw	s4,24(sp)
    44e0:	01412a83          	lw	s5,20(sp)
    44e4:	01012b03          	lw	s6,16(sp)
    44e8:	03010113          	addi	sp,sp,48
    44ec:	00008067          	ret

000044f0 <scene_snap>:
    for (i = 0; i < n; i++) { sc[i].tx = sc[i].x; sc[i].ty = sc[i].y; }
    44f0:	00000713          	li	a4,0
    44f4:	0280006f          	j	451c <scene_snap+0x2c>
    44f8:	00271793          	slli	a5,a4,0x2
    44fc:	00e787b3          	add	a5,a5,a4
    4500:	00279793          	slli	a5,a5,0x2
    4504:	00f507b3          	add	a5,a0,a5
    4508:	00079683          	lh	a3,0(a5)
    450c:	00d79623          	sh	a3,12(a5)
    4510:	00279683          	lh	a3,2(a5)
    4514:	00d79723          	sh	a3,14(a5)
    4518:	00170713          	addi	a4,a4,1
    451c:	fcb74ee3          	blt	a4,a1,44f8 <scene_snap+0x8>
}
    4520:	00008067          	ret

00004524 <scene_step>:
    int xmin = rg->x0, xmax = rg->x0 + rg->w;
    4524:	00062e83          	lw	t4,0(a2)
    4528:	00862f83          	lw	t6,8(a2)
    452c:	01df8fb3          	add	t6,t6,t4
    int ymin = rg->y0, ymax = rg->y0 + rg->h;
    4530:	00462e03          	lw	t3,4(a2)
    4534:	00c62f03          	lw	t5,12(a2)
    4538:	01cf0f33          	add	t5,t5,t3
    for (i = 0; i < n; i++) {
    453c:	00000893          	li	a7,0
    4540:	0440006f          	j	4584 <scene_step+0x60>
        else if (x + w > xmax) { x = xmax - w; b->vx = (int16_t)(-b->vx); }
    4544:	006682b3          	add	t0,a3,t1
    4548:	005fdc63          	bge	t6,t0,4560 <scene_step+0x3c>
    454c:	406f86b3          	sub	a3,t6,t1
    4550:	01081813          	slli	a6,a6,0x10
    4554:	01085813          	srli	a6,a6,0x10
    4558:	41000833          	neg	a6,a6
    455c:	01079223          	sh	a6,4(a5)
        if (y < ymin)          { y = ymin;     b->vy = (int16_t)(-b->vy); }
    4560:	07c75863          	bge	a4,t3,45d0 <scene_step+0xac>
    4564:	01061613          	slli	a2,a2,0x10
    4568:	01065613          	srli	a2,a2,0x10
    456c:	40c00633          	neg	a2,a2
    4570:	00c79323          	sh	a2,6(a5)
    4574:	000e0713          	mv	a4,t3
        b->x = (int16_t)x;
    4578:	00d79023          	sh	a3,0(a5)
        b->y = (int16_t)y;
    457c:	00e79123          	sh	a4,2(a5)
    for (i = 0; i < n; i++) {
    4580:	00188893          	addi	a7,a7,1
    4584:	06b8d663          	bge	a7,a1,45f0 <scene_step+0xcc>
        blk_t *b = &sc[i];
    4588:	00289793          	slli	a5,a7,0x2
    458c:	011787b3          	add	a5,a5,a7
    4590:	00279793          	slli	a5,a5,0x2
    4594:	00f507b3          	add	a5,a0,a5
        int x = b->x + b->vx, y = b->y + b->vy, w = b->sz;
    4598:	00079683          	lh	a3,0(a5)
    459c:	00479803          	lh	a6,4(a5)
    45a0:	010686b3          	add	a3,a3,a6
    45a4:	00279703          	lh	a4,2(a5)
    45a8:	00679603          	lh	a2,6(a5)
    45ac:	00c70733          	add	a4,a4,a2
    45b0:	0127c303          	lbu	t1,18(a5)
        if (x < xmin)          { x = xmin;     b->vx = (int16_t)(-b->vx); }
    45b4:	f9d6d8e3          	bge	a3,t4,4544 <scene_step+0x20>
    45b8:	01081813          	slli	a6,a6,0x10
    45bc:	01085813          	srli	a6,a6,0x10
    45c0:	41000833          	neg	a6,a6
    45c4:	01079223          	sh	a6,4(a5)
    45c8:	000e8693          	mv	a3,t4
    45cc:	f95ff06f          	j	4560 <scene_step+0x3c>
        else if (y + w > ymax) { y = ymax - w; b->vy = (int16_t)(-b->vy); }
    45d0:	00670833          	add	a6,a4,t1
    45d4:	fb0f52e3          	bge	t5,a6,4578 <scene_step+0x54>
    45d8:	406f0733          	sub	a4,t5,t1
    45dc:	01061613          	slli	a2,a2,0x10
    45e0:	01065613          	srli	a2,a2,0x10
    45e4:	40c00633          	neg	a2,a2
    45e8:	00c79323          	sh	a2,6(a5)
    45ec:	f8dff06f          	j	4578 <scene_step+0x54>
}
    45f0:	00008067          	ret

000045f4 <scene_step_both>:
{
    45f4:	fe010113          	addi	sp,sp,-32
    45f8:	00112e23          	sw	ra,28(sp)
    45fc:	00812c23          	sw	s0,24(sp)
    4600:	00912a23          	sw	s1,20(sp)
    4604:	01212823          	sw	s2,16(sp)
    4608:	01312623          	sw	s3,12(sp)
    460c:	00050413          	mv	s0,a0
    4610:	00058493          	mv	s1,a1
    4614:	00060993          	mv	s3,a2
    4618:	00068913          	mv	s2,a3
    scene_step(g_sc[SIDE_HW],  n, rg);
    461c:	00058613          	mv	a2,a1
    4620:	00050593          	mv	a1,a0
    4624:	00008537          	lui	a0,0x8
    4628:	a2050513          	addi	a0,a0,-1504 # 7a20 <g_sc>
    462c:	ef9ff0ef          	jal	4524 <scene_step>
    scene_step(g_sc[SIDE_CPU], n, rg);
    4630:	00048613          	mv	a2,s1
    4634:	00040593          	mv	a1,s0
    4638:	00025537          	lui	a0,0x25
    463c:	ee050513          	addi	a0,a0,-288 # 24ee0 <__global_pointer$+0x1cde8>
    4640:	ee5ff0ef          	jal	4524 <scene_step>
    *snap_hw  = 1;
    4644:	00100793          	li	a5,1
    4648:	00f9a023          	sw	a5,0(s3)
    *snap_cpu = 1;
    464c:	00f92023          	sw	a5,0(s2)
}
    4650:	01c12083          	lw	ra,28(sp)
    4654:	01812403          	lw	s0,24(sp)
    4658:	01412483          	lw	s1,20(sp)
    465c:	01012903          	lw	s2,16(sp)
    4660:	00c12983          	lw	s3,12(sp)
    4664:	02010113          	addi	sp,sp,32
    4668:	00008067          	ret

0000466c <dl_put>:
    volatile uint32_t *p = (volatile uint32_t *)list + (i * 4);
    466c:	00459593          	slli	a1,a1,0x4
    4670:	00b50533          	add	a0,a0,a1
    p[0] = ((uint32_t)(uint16_t)x) | ((uint32_t)(uint16_t)y << 16);
    4674:	000105b7          	lui	a1,0x10
    4678:	fff58593          	addi	a1,a1,-1 # ffff <__global_pointer$+0x7f07>
    467c:	00b67633          	and	a2,a2,a1
    4680:	01069693          	slli	a3,a3,0x10
    4684:	00c6e6b3          	or	a3,a3,a2
    4688:	00d52023          	sw	a3,0(a0)
    p[1] = (spr_id & 0xFFFFu) | ((flags & 0xFFFFu) << 16);
    468c:	00b77733          	and	a4,a4,a1
    4690:	01079793          	slli	a5,a5,0x10
    4694:	00f76733          	or	a4,a4,a5
    4698:	00e52223          	sw	a4,4(a0)
    p[2] = (key & 0xFFFFu) | ((alpha & 0xFFu) << 16);            /* [31:24] PRIO=0 */
    469c:	00b87833          	and	a6,a6,a1
    46a0:	01089893          	slli	a7,a7,0x10
    46a4:	00ff06b7          	lui	a3,0xff0
    46a8:	00d8f8b3          	and	a7,a7,a3
    46ac:	01186833          	or	a6,a6,a7
    46b0:	01052423          	sw	a6,8(a0)
    p[3] = (mask & 0xFFFFu)                                      /* [15:0] MASK_ID（S3） */
    46b4:	00812783          	lw	a5,8(sp)
    46b8:	00b7f7b3          	and	a5,a5,a1
         | ((w_ovr & 0xFFu) << 16) | ((h_ovr & 0xFFu) << 24);
    46bc:	00012703          	lw	a4,0(sp)
    46c0:	01071713          	slli	a4,a4,0x10
    46c4:	00d77733          	and	a4,a4,a3
    46c8:	00e7e7b3          	or	a5,a5,a4
    46cc:	00412703          	lw	a4,4(sp)
    46d0:	01871713          	slli	a4,a4,0x18
    46d4:	00e7e7b3          	or	a5,a5,a4
    p[3] = (mask & 0xFFFFu)                                      /* [15:0] MASK_ID（S3） */
    46d8:	00f52623          	sw	a5,12(a0)
}
    46dc:	00008067          	ret

000046e0 <dl_geom_put>:
    volatile uint32_t *p = (volatile uint32_t *)g + (id * 4);
    46e0:	00459593          	slli	a1,a1,0x4
    46e4:	00b50533          	add	a0,a0,a1
    p[0] = atlas;
    46e8:	00c52023          	sw	a2,0(a0)
    p[1] = (stride & 0xFFFFu) | ((keydef & 0xFFFFu) << 16);
    46ec:	00010637          	lui	a2,0x10
    46f0:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f07>
    46f4:	00c6f6b3          	and	a3,a3,a2
    46f8:	01071713          	slli	a4,a4,0x10
    46fc:	00e6e6b3          	or	a3,a3,a4
    4700:	00d52223          	sw	a3,4(a0)
    p[2] = (w & 0xFFFFu) | ((h & 0xFFFFu) << 16);
    4704:	00c7f7b3          	and	a5,a5,a2
    4708:	01081813          	slli	a6,a6,0x10
    470c:	0107e7b3          	or	a5,a5,a6
    4710:	00f52423          	sw	a5,8(a0)
    p[3] = (sx & 0xFFFFu) | ((sy & 0xFFFFu) << 16);
    4714:	00c8f8b3          	and	a7,a7,a2
    4718:	00012783          	lw	a5,0(sp)
    471c:	01079793          	slli	a5,a5,0x10
    4720:	00f8e8b3          	or	a7,a7,a5
    4724:	01152623          	sw	a7,12(a0)
}
    4728:	00008067          	ret

0000472c <dl_spr_id>:
{
    472c:	ff010113          	addi	sp,sp,-16
    4730:	00112623          	sw	ra,12(sp)
    4734:	00812423          	sw	s0,8(sp)
    4738:	00050413          	mv	s0,a0
    int i = blk_idx(g_blk);
    473c:	8201a503          	lw	a0,-2016(gp) # 7918 <g_blk>
    4740:	f78fe0ef          	jal	2eb8 <blk_idx>
    if (scene == SC_ALPHA) return (unsigned)(DL_G_ALPHA_16 + i);
    4744:	00100793          	li	a5,1
    4748:	00f40e63          	beq	s0,a5,4764 <dl_spr_id+0x38>
    if (scene == SC_KEY)   return (unsigned)(DL_G_KEY_16   + i);
    474c:	00200793          	li	a5,2
    4750:	00f40e63          	beq	s0,a5,476c <dl_spr_id+0x40>
}
    4754:	00c12083          	lw	ra,12(sp)
    4758:	00812403          	lw	s0,8(sp)
    475c:	01010113          	addi	sp,sp,16
    4760:	00008067          	ret
    if (scene == SC_ALPHA) return (unsigned)(DL_G_ALPHA_16 + i);
    4764:	00350513          	addi	a0,a0,3
    4768:	fedff06f          	j	4754 <dl_spr_id+0x28>
    if (scene == SC_KEY)   return (unsigned)(DL_G_KEY_16   + i);
    476c:	00650513          	addi	a0,a0,6
    4770:	fe5ff06f          	j	4754 <dl_spr_id+0x28>

00004774 <dl_rep_id>:
    return (path == PATH_SPLIT) ? DL_G_REP_SPLIT : DL_G_REP_FULL;
    4774:	00051663          	bnez	a0,4780 <dl_rep_id+0xc>
    4778:	00900513          	li	a0,9
    477c:	00008067          	ret
    4780:	00a00513          	li	a0,10
}
    4784:	00008067          	ret

00004788 <dl_build>:
{
    4788:	fa010113          	addi	sp,sp,-96
    478c:	04112e23          	sw	ra,92(sp)
    4790:	04812c23          	sw	s0,88(sp)
    4794:	04912a23          	sw	s1,84(sp)
    4798:	05212823          	sw	s2,80(sp)
    479c:	05312623          	sw	s3,76(sp)
    47a0:	05412423          	sw	s4,72(sp)
    47a4:	05512223          	sw	s5,68(sp)
    47a8:	05612023          	sw	s6,64(sp)
    47ac:	03712e23          	sw	s7,60(sp)
    47b0:	03812c23          	sw	s8,56(sp)
    47b4:	03912a23          	sw	s9,52(sp)
    47b8:	03a12823          	sw	s10,48(sp)
    47bc:	03b12623          	sw	s11,44(sp)
    47c0:	00050913          	mv	s2,a0
    47c4:	00058d93          	mv	s11,a1
    47c8:	00060993          	mv	s3,a2
    47cc:	00068493          	mv	s1,a3
    47d0:	00070c13          	mv	s8,a4
    47d4:	00078a13          	mv	s4,a5
    47d8:	00080b93          	mv	s7,a6
    47dc:	01112e23          	sw	a7,28(sp)
    int i = *hw_i, c = 0;
    47e0:	0005a403          	lw	s0,0(a1)
                 : ((scene == SC_ALPHA) ? BLT_OP_ALPHA : BLT_OP_KEY);
    47e4:	00068e63          	beqz	a3,4800 <dl_build+0x78>
    47e8:	00100793          	li	a5,1
    47ec:	00f68663          	beq	a3,a5,47f8 <dl_build+0x70>
    47f0:	00300b13          	li	s6,3
    47f4:	0100006f          	j	4804 <dl_build+0x7c>
    47f8:	00200b13          	li	s6,2
    47fc:	0080006f          	j	4804 <dl_build+0x7c>
    4800:	00100b13          	li	s6,1
    unsigned spr = dl_spr_id(scene);
    4804:	00048513          	mv	a0,s1
    4808:	f25ff0ef          	jal	472c <dl_spr_id>
    480c:	00050a93          	mv	s5,a0
    unsigned key = (scene == SC_KEY) ? (unsigned)KEY_COLOR : 0u;  /* ALPHA 的 w7 逐位对齐 CPU 路径 = 0 */
    4810:	00200793          	li	a5,2
    4814:	02f48c63          	beq	s1,a5,484c <dl_build+0xc4>
    unsigned al  = (scene == SC_ALPHA) ? alpha : 0xFFu;
    4818:	00100793          	li	a5,1
    481c:	04f48c63          	beq	s1,a5,4874 <dl_build+0xec>
    4820:	00000c93          	li	s9,0
    unsigned msk   = ((scene == SC_KEY) && (g_spr_mask != 0u)) ? (unsigned)g_spr_mask : 0u;
    4824:	00200793          	li	a5,2
    4828:	02f48863          	beq	s1,a5,4858 <dl_build+0xd0>
    482c:	00000d13          	li	s10,0
    4830:	0ff00c13          	li	s8,255
    unsigned fl    = (op | DL_F_CLIP) | (msk ? (DL_F_MASKEN | DL_F_MASKMODE01) : 0u);
    4834:	00000793          	li	a5,0
    4838:	00fb6b33          	or	s6,s6,a5
    483c:	010b6b13          	ori	s6,s6,16
    if (rep_id >= 0)
    4840:	040bde63          	bgez	s7,489c <dl_build+0x114>
    int i = *hw_i, c = 0;
    4844:	00000593          	li	a1,0
    4848:	1580006f          	j	49a0 <dl_build+0x218>
    unsigned key = (scene == SC_KEY) ? (unsigned)KEY_COLOR : 0u;  /* ALPHA 的 w7 逐位对齐 CPU 路径 = 0 */
    484c:	00010cb7          	lui	s9,0x10
    4850:	81fc8c93          	addi	s9,s9,-2017 # f81f <__global_pointer$+0x7727>
    4854:	fd1ff06f          	j	4824 <dl_build+0x9c>
    unsigned msk   = ((scene == SC_KEY) && (g_spr_mask != 0u)) ? (unsigned)g_spr_mask : 0u;
    4858:	8b01d783          	lhu	a5,-1872(gp) # 79a8 <g_spr_mask>
    485c:	02078463          	beqz	a5,4884 <dl_build+0xfc>
    4860:	00078d13          	mv	s10,a5
    unsigned fl    = (op | DL_F_CLIP) | (msk ? (DL_F_MASKEN | DL_F_MASKMODE01) : 0u);
    4864:	02078863          	beqz	a5,4894 <dl_build+0x10c>
    4868:	0ff00c13          	li	s8,255
    486c:	18000793          	li	a5,384
    4870:	fc9ff06f          	j	4838 <dl_build+0xb0>
    4874:	00000d13          	li	s10,0
    4878:	00000c93          	li	s9,0
    487c:	00000793          	li	a5,0
    4880:	fb9ff06f          	j	4838 <dl_build+0xb0>
    unsigned msk   = ((scene == SC_KEY) && (g_spr_mask != 0u)) ? (unsigned)g_spr_mask : 0u;
    4884:	00000d13          	li	s10,0
    4888:	0ff00c13          	li	s8,255
    unsigned fl    = (op | DL_F_CLIP) | (msk ? (DL_F_MASKEN | DL_F_MASKMODE01) : 0u);
    488c:	00000793          	li	a5,0
    4890:	fa9ff06f          	j	4838 <dl_build+0xb0>
    4894:	0ff00c13          	li	s8,255
    4898:	fa1ff06f          	j	4838 <dl_build+0xb0>
        dl_put(list, c++, 0, 0, (unsigned)rep_id, BLT_OP_FILL | DL_F_CLIP,
    489c:	00012423          	sw	zero,8(sp)
    48a0:	00012223          	sw	zero,4(sp)
    48a4:	00012023          	sw	zero,0(sp)
    48a8:	0ff00893          	li	a7,255
    48ac:	00800813          	li	a6,8
    48b0:	01100793          	li	a5,17
    48b4:	000b8713          	mv	a4,s7
    48b8:	00000693          	li	a3,0
    48bc:	00000613          	li	a2,0
    48c0:	00000593          	li	a1,0
    48c4:	00090513          	mv	a0,s2
    48c8:	da5ff0ef          	jal	466c <dl_put>
    48cc:	00100593          	li	a1,1
    48d0:	0d00006f          	j	49a0 <dl_build+0x218>
        if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
    48d4:	000087b7          	lui	a5,0x8
    48d8:	00241713          	slli	a4,s0,0x2
    48dc:	00870733          	add	a4,a4,s0
    48e0:	00271713          	slli	a4,a4,0x2
    48e4:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    48e8:	00e787b3          	add	a5,a5,a4
    48ec:	00a79703          	lh	a4,10(a5)
    48f0:	00e79783          	lh	a5,14(a5)
    48f4:	00f70663          	beq	a4,a5,4900 <dl_build+0x178>
            need = 2;                                    /* 与逐条路径同一条擦除条件 */
    48f8:	00200713          	li	a4,2
    48fc:	0100006f          	j	490c <dl_build+0x184>
        int need = 1;
    4900:	00100713          	li	a4,1
    4904:	0080006f          	j	490c <dl_build+0x184>
    4908:	00100713          	li	a4,1
        if (c + need > DL_DESC_MAX) break;               /* 放不下 ⇒ 留到下一段（顺序不变） */
    490c:	00e587b3          	add	a5,a1,a4
    4910:	000016b7          	lui	a3,0x1
    4914:	16d7da63          	bge	a5,a3,4a88 <dl_build+0x300>
        if (need == 2)
    4918:	00200793          	li	a5,2
    491c:	0cf70463          	beq	a4,a5,49e4 <dl_build+0x25c>
        if (scene == SC_FILL)
    4920:	10049c63          	bnez	s1,4a38 <dl_build+0x2b0>
            dl_put(list, c++, b->tx, b->ty, spr, BLT_OP_FILL | DL_F_CLIP | DL_F_SZOVR,
    4924:	00158b93          	addi	s7,a1,1
    4928:	00008637          	lui	a2,0x8
    492c:	00241793          	slli	a5,s0,0x2
    4930:	008787b3          	add	a5,a5,s0
    4934:	00279793          	slli	a5,a5,0x2
    4938:	a2060613          	addi	a2,a2,-1504 # 7a20 <g_sc>
    493c:	00f60633          	add	a2,a2,a5
                   (unsigned)b->color, 0xFFu, (unsigned)b->sz, (unsigned)b->sz, 0u);
    4940:	01264783          	lbu	a5,18(a2)
            dl_put(list, c++, b->tx, b->ty, spr, BLT_OP_FILL | DL_F_CLIP | DL_F_SZOVR,
    4944:	00012423          	sw	zero,8(sp)
    4948:	00f12223          	sw	a5,4(sp)
    494c:	00f12023          	sw	a5,0(sp)
    4950:	0ff00893          	li	a7,255
    4954:	01065803          	lhu	a6,16(a2)
    4958:	03100793          	li	a5,49
    495c:	000a8713          	mv	a4,s5
    4960:	00e61683          	lh	a3,14(a2)
    4964:	00c61603          	lh	a2,12(a2)
    4968:	00090513          	mv	a0,s2
    496c:	d01ff0ef          	jal	466c <dl_put>
    4970:	000b8593          	mv	a1,s7
        b->dx = b->tx; b->dy = b->ty;                    /* 记账：画的就是快照位置 */
    4974:	000087b7          	lui	a5,0x8
    4978:	00241713          	slli	a4,s0,0x2
    497c:	00870733          	add	a4,a4,s0
    4980:	00271713          	slli	a4,a4,0x2
    4984:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    4988:	00e787b3          	add	a5,a5,a4
    498c:	00c79703          	lh	a4,12(a5)
    4990:	00e79423          	sh	a4,8(a5)
    4994:	00e79703          	lh	a4,14(a5)
    4998:	00e79523          	sh	a4,10(a5)
        i++;
    499c:	00140413          	addi	s0,s0,1
    while (i < n) {
    49a0:	0f345463          	bge	s0,s3,4a88 <dl_build+0x300>
        if (!clear_pp && ((scene == SC_ALPHA) || (b->dx != b->tx || b->dy != b->ty)))
    49a4:	f60a12e3          	bnez	s4,4908 <dl_build+0x180>
    49a8:	00100793          	li	a5,1
    49ac:	02f48863          	beq	s1,a5,49dc <dl_build+0x254>
    49b0:	000087b7          	lui	a5,0x8
    49b4:	00241713          	slli	a4,s0,0x2
    49b8:	00870733          	add	a4,a4,s0
    49bc:	00271713          	slli	a4,a4,0x2
    49c0:	a2078793          	addi	a5,a5,-1504 # 7a20 <g_sc>
    49c4:	00e787b3          	add	a5,a5,a4
    49c8:	00879703          	lh	a4,8(a5)
    49cc:	00c79783          	lh	a5,12(a5)
    49d0:	f0f702e3          	beq	a4,a5,48d4 <dl_build+0x14c>
            need = 2;                                    /* 与逐条路径同一条擦除条件 */
    49d4:	00200713          	li	a4,2
    49d8:	f35ff06f          	j	490c <dl_build+0x184>
    49dc:	00200713          	li	a4,2
    49e0:	f2dff06f          	j	490c <dl_build+0x184>
            dl_put(list, c++, b->dx, b->dy, DL_G_FILL_16,
    49e4:	00158b93          	addi	s7,a1,1
    49e8:	00008637          	lui	a2,0x8
    49ec:	00241793          	slli	a5,s0,0x2
    49f0:	008787b3          	add	a5,a5,s0
    49f4:	00279793          	slli	a5,a5,0x2
    49f8:	a2060613          	addi	a2,a2,-1504 # 7a20 <g_sc>
    49fc:	00f60633          	add	a2,a2,a5
                   (unsigned)COL_BG, 0xFFu, (unsigned)b->sz, (unsigned)b->sz, 0u);
    4a00:	01264783          	lbu	a5,18(a2)
            dl_put(list, c++, b->dx, b->dy, DL_G_FILL_16,
    4a04:	00012423          	sw	zero,8(sp)
    4a08:	00f12223          	sw	a5,4(sp)
    4a0c:	00f12023          	sw	a5,0(sp)
    4a10:	0ff00893          	li	a7,255
    4a14:	00800813          	li	a6,8
    4a18:	03100793          	li	a5,49
    4a1c:	00000713          	li	a4,0
    4a20:	00a61683          	lh	a3,10(a2)
    4a24:	00861603          	lh	a2,8(a2)
    4a28:	00090513          	mv	a0,s2
    4a2c:	c41ff0ef          	jal	466c <dl_put>
    4a30:	000b8593          	mv	a1,s7
    4a34:	eedff06f          	j	4920 <dl_build+0x198>
            dl_put(list, c++, b->tx, b->ty, spr, fl, key, al, 0u, 0u, msk);
    4a38:	00158b93          	addi	s7,a1,1
    4a3c:	00008637          	lui	a2,0x8
    4a40:	00241793          	slli	a5,s0,0x2
    4a44:	008787b3          	add	a5,a5,s0
    4a48:	00279793          	slli	a5,a5,0x2
    4a4c:	a2060613          	addi	a2,a2,-1504 # 7a20 <g_sc>
    4a50:	00f60633          	add	a2,a2,a5
    4a54:	01a12423          	sw	s10,8(sp)
    4a58:	00012223          	sw	zero,4(sp)
    4a5c:	00012023          	sw	zero,0(sp)
    4a60:	000c0893          	mv	a7,s8
    4a64:	000c8813          	mv	a6,s9
    4a68:	000b0793          	mv	a5,s6
    4a6c:	000a8713          	mv	a4,s5
    4a70:	00e61683          	lh	a3,14(a2)
    4a74:	00c61603          	lh	a2,12(a2)
    4a78:	00090513          	mv	a0,s2
    4a7c:	bf1ff0ef          	jal	466c <dl_put>
    4a80:	000b8593          	mv	a1,s7
    4a84:	ef1ff06f          	j	4974 <dl_build+0x1ec>
    *hw_i = i;
    4a88:	008da023          	sw	s0,0(s11)
    *cnt  = c;
    4a8c:	01c12783          	lw	a5,28(sp)
    4a90:	00b7a023          	sw	a1,0(a5)
    *last = (i >= n) ? 1 : 0;
    4a94:	01342433          	slt	s0,s0,s3
    4a98:	00143413          	seqz	s0,s0
    4a9c:	06012783          	lw	a5,96(sp)
    4aa0:	0087a023          	sw	s0,0(a5)
}
    4aa4:	05c12083          	lw	ra,92(sp)
    4aa8:	05812403          	lw	s0,88(sp)
    4aac:	05412483          	lw	s1,84(sp)
    4ab0:	05012903          	lw	s2,80(sp)
    4ab4:	04c12983          	lw	s3,76(sp)
    4ab8:	04812a03          	lw	s4,72(sp)
    4abc:	04412a83          	lw	s5,68(sp)
    4ac0:	04012b03          	lw	s6,64(sp)
    4ac4:	03c12b83          	lw	s7,60(sp)
    4ac8:	03812c03          	lw	s8,56(sp)
    4acc:	03412c83          	lw	s9,52(sp)
    4ad0:	03012d03          	lw	s10,48(sp)
    4ad4:	02c12d83          	lw	s11,44(sp)
    4ad8:	06010113          	addi	sp,sp,96
    4adc:	00008067          	ret

00004ae0 <dl_wd_decide>:
    int a = (gap <= DL_WD_WINDOW_TICKS);
    4ae0:	05f5e7b7          	lui	a5,0x5f5e
    4ae4:	10178793          	addi	a5,a5,257 # 5f5e101 <__freertos_irq_stack_top+0x5f1ad61>
    4ae8:	00f5b7b3          	sltu	a5,a1,a5
    *again = a;
    4aec:	00f62023          	sw	a5,0(a2)
    if (spent) return DL_WD_OFF;
    4af0:	00051c63          	bnez	a0,4b08 <dl_wd_decide+0x28>
    if (a)     return DL_WD_OFF;
    4af4:	05f5e7b7          	lui	a5,0x5f5e
    4af8:	10078793          	addi	a5,a5,256 # 5f5e100 <__freertos_irq_stack_top+0x5f1ad60>
    4afc:	00b7f863          	bgeu	a5,a1,4b0c <dl_wd_decide+0x2c>
    return DL_WD_RETRY;
    4b00:	00100513          	li	a0,1
    4b04:	00008067          	ret
    if (spent) return DL_WD_OFF;
    4b08:	00000513          	li	a0,0
}
    4b0c:	00008067          	ret

00004b10 <dl_geom_fill>:
{
    4b10:	fe010113          	addi	sp,sp,-32
    4b14:	00112e23          	sw	ra,28(sp)
    4b18:	00812c23          	sw	s0,24(sp)
    4b1c:	00050413          	mv	s0,a0
    dl_geom_put(g, DL_G_FILL_16,  ATLAS_BASE, 32u,         (unsigned)KEY_COLOR, 16u, 16u, 0u, 0u);
    4b20:	00012023          	sw	zero,0(sp)
    4b24:	00000893          	li	a7,0
    4b28:	01000813          	li	a6,16
    4b2c:	01000793          	li	a5,16
    4b30:	00010737          	lui	a4,0x10
    4b34:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4b38:	02000693          	li	a3,32
    4b3c:	00201637          	lui	a2,0x201
    4b40:	00000593          	li	a1,0
    4b44:	b9dff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_FILL_32,  ATLAS_BASE, 64u,         (unsigned)KEY_COLOR, 32u, 32u, 0u, 0u);
    4b48:	00012023          	sw	zero,0(sp)
    4b4c:	00000893          	li	a7,0
    4b50:	02000813          	li	a6,32
    4b54:	02000793          	li	a5,32
    4b58:	00010737          	lui	a4,0x10
    4b5c:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4b60:	04000693          	li	a3,64
    4b64:	00201637          	lui	a2,0x201
    4b68:	00100593          	li	a1,1
    4b6c:	00040513          	mv	a0,s0
    4b70:	b71ff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_FILL_64,  ATLAS_BASE, 128u,        (unsigned)KEY_COLOR, 64u, 64u, 0u, 0u);
    4b74:	00012023          	sw	zero,0(sp)
    4b78:	00000893          	li	a7,0
    4b7c:	04000813          	li	a6,64
    4b80:	04000793          	li	a5,64
    4b84:	00010737          	lui	a4,0x10
    4b88:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4b8c:	08000693          	li	a3,128
    4b90:	00201637          	lui	a2,0x201
    4b94:	00200593          	li	a1,2
    4b98:	00040513          	mv	a0,s0
    4b9c:	b45ff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_ALPHA_16, ATLAS_BASE, 32u,         (unsigned)KEY_COLOR, 16u, 16u, 0u, 0u);
    4ba0:	00012023          	sw	zero,0(sp)
    4ba4:	00000893          	li	a7,0
    4ba8:	01000813          	li	a6,16
    4bac:	01000793          	li	a5,16
    4bb0:	00010737          	lui	a4,0x10
    4bb4:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4bb8:	02000693          	li	a3,32
    4bbc:	00201637          	lui	a2,0x201
    4bc0:	00300593          	li	a1,3
    4bc4:	00040513          	mv	a0,s0
    4bc8:	b19ff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_ALPHA_32, ATLAS_BASE, 64u,         (unsigned)KEY_COLOR, 32u, 32u, 0u, 0u);
    4bcc:	00012023          	sw	zero,0(sp)
    4bd0:	00000893          	li	a7,0
    4bd4:	02000813          	li	a6,32
    4bd8:	02000793          	li	a5,32
    4bdc:	00010737          	lui	a4,0x10
    4be0:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4be4:	04000693          	li	a3,64
    4be8:	00201637          	lui	a2,0x201
    4bec:	00400593          	li	a1,4
    4bf0:	00040513          	mv	a0,s0
    4bf4:	aedff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_ALPHA_64, ATLAS_BASE, 128u,        (unsigned)KEY_COLOR, 64u, 64u, 0u, 0u);
    4bf8:	00012023          	sw	zero,0(sp)
    4bfc:	00000893          	li	a7,0
    4c00:	04000813          	li	a6,64
    4c04:	04000793          	li	a5,64
    4c08:	00010737          	lui	a4,0x10
    4c0c:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4c10:	08000693          	li	a3,128
    4c14:	00201637          	lui	a2,0x201
    4c18:	00500593          	li	a1,5
    4c1c:	00040513          	mv	a0,s0
    4c20:	ac1ff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_KEY_16,   ATLAS_BASE, 32u,         (unsigned)KEY_COLOR, 16u, 16u, 0u, 0u);
    4c24:	00012023          	sw	zero,0(sp)
    4c28:	00000893          	li	a7,0
    4c2c:	01000813          	li	a6,16
    4c30:	01000793          	li	a5,16
    4c34:	00010737          	lui	a4,0x10
    4c38:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4c3c:	02000693          	li	a3,32
    4c40:	00201637          	lui	a2,0x201
    4c44:	00600593          	li	a1,6
    4c48:	00040513          	mv	a0,s0
    4c4c:	a95ff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_KEY_32,   ATLAS_BASE, 64u,         (unsigned)KEY_COLOR, 32u, 32u, 0u, 0u);
    4c50:	00012023          	sw	zero,0(sp)
    4c54:	00000893          	li	a7,0
    4c58:	02000813          	li	a6,32
    4c5c:	02000793          	li	a5,32
    4c60:	00010737          	lui	a4,0x10
    4c64:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4c68:	04000693          	li	a3,64
    4c6c:	00201637          	lui	a2,0x201
    4c70:	00700593          	li	a1,7
    4c74:	00040513          	mv	a0,s0
    4c78:	a69ff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_KEY_64,   ATLAS_BASE, 128u,        (unsigned)KEY_COLOR, 64u, 64u, 0u, 0u);
    4c7c:	00012023          	sw	zero,0(sp)
    4c80:	00000893          	li	a7,0
    4c84:	04000813          	li	a6,64
    4c88:	04000793          	li	a5,64
    4c8c:	00010737          	lui	a4,0x10
    4c90:	81f70713          	addi	a4,a4,-2017 # f81f <__global_pointer$+0x7727>
    4c94:	08000693          	li	a3,128
    4c98:	00201637          	lui	a2,0x201
    4c9c:	00800593          	li	a1,8
    4ca0:	00040513          	mv	a0,s0
    4ca4:	a3dff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_REP_SPLIT, 0UL, 0u, 0u, (unsigned)FB_WIDTH, (unsigned)HALF_H, 0u, 0u);
    4ca8:	00012023          	sw	zero,0(sp)
    4cac:	00000893          	li	a7,0
    4cb0:	10400813          	li	a6,260
    4cb4:	3c000793          	li	a5,960
    4cb8:	00000713          	li	a4,0
    4cbc:	00000693          	li	a3,0
    4cc0:	00000613          	li	a2,0
    4cc4:	00900593          	li	a1,9
    4cc8:	00040513          	mv	a0,s0
    4ccc:	a15ff0ef          	jal	46e0 <dl_geom_put>
    dl_geom_put(g, DL_G_REP_FULL,  0UL, 0u, 0u, (unsigned)FB_WIDTH,
    4cd0:	00012023          	sw	zero,0(sp)
    4cd4:	00000893          	li	a7,0
    4cd8:	20c00813          	li	a6,524
    4cdc:	3c000793          	li	a5,960
    4ce0:	00000713          	li	a4,0
    4ce4:	00000693          	li	a3,0
    4ce8:	00000613          	li	a2,0
    4cec:	00a00593          	li	a1,10
    4cf0:	00040513          	mv	a0,s0
    4cf4:	9edff0ef          	jal	46e0 <dl_geom_put>
}
    4cf8:	01c12083          	lw	ra,28(sp)
    4cfc:	01812403          	lw	s0,24(sp)
    4d00:	02010113          	addi	sp,sp,32
    4d04:	00008067          	ret

00004d08 <dl_geom_build>:
{
    4d08:	ff010113          	addi	sp,sp,-16
    4d0c:	00112623          	sw	ra,12(sp)
    dl_geom_fill((uint32_t *)DL_GEOM_ADDR);
    4d10:	00801537          	lui	a0,0x801
    4d14:	dfdff0ef          	jal	4b10 <dl_geom_fill>
    cache_evict();      /* CPU 写完 DDR、硬件紧接着要读 ⇒ 写穿屏障 */
    4d18:	cc4fe0ef          	jal	31dc <cache_evict>
}
    4d1c:	00c12083          	lw	ra,12(sp)
    4d20:	01010113          	addi	sp,sp,16
    4d24:	00008067          	ret

00004d28 <dl_arm_wait_idle>:
{
    4d28:	ff010113          	addi	sp,sp,-16
    4d2c:	00112623          	sw	ra,12(sp)
    4d30:	00812423          	sw	s0,8(sp)
    uint32_t t0 = tick32();
    4d34:	9f8fe0ef          	jal	2f2c <tick32>
    4d38:	00050413          	mv	s0,a0
    while (blt_rd(BLT_DL_STATUS) & DL_ST_BUSY)
    4d3c:	05c00513          	li	a0,92
    4d40:	a18fe0ef          	jal	2f58 <blt_rd>
    4d44:	00157513          	andi	a0,a0,1
    4d48:	02050063          	beqz	a0,4d68 <dl_arm_wait_idle+0x40>
        if ((uint32_t)(tick32() - t0) > (uint32_t)DL_ARM_IDLE_TICKS) return 0;
    4d4c:	9e0fe0ef          	jal	2f2c <tick32>
    4d50:	40850533          	sub	a0,a0,s0
    4d54:	000f47b7          	lui	a5,0xf4
    4d58:	24078793          	addi	a5,a5,576 # f4240 <__freertos_irq_stack_top+0xb0ea0>
    4d5c:	fea7f0e3          	bgeu	a5,a0,4d3c <dl_arm_wait_idle+0x14>
    4d60:	00000513          	li	a0,0
    4d64:	0080006f          	j	4d6c <dl_arm_wait_idle+0x44>
    return 1;
    4d68:	00100513          	li	a0,1
}
    4d6c:	00c12083          	lw	ra,12(sp)
    4d70:	00812403          	lw	s0,8(sp)
    4d74:	01010113          	addi	sp,sp,16
    4d78:	00008067          	ret

00004d7c <dl_go>:
{
    4d7c:	ff010113          	addi	sp,sp,-16
    4d80:	00112623          	sw	ra,12(sp)
    4d84:	00812423          	sw	s0,8(sp)
    4d88:	00912223          	sw	s1,4(sp)
    4d8c:	00050413          	mv	s0,a0
    4d90:	00058493          	mv	s1,a1
    blt_wr(BLT_DL_DST_BASE, dst_base);
    4d94:	00060593          	mv	a1,a2
    4d98:	07000513          	li	a0,112
    4d9c:	9acfe0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_COUNT,    (uint32_t)cnt);
    4da0:	00048593          	mv	a1,s1
    4da4:	05400513          	li	a0,84
    4da8:	9a0fe0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_CTRL,     (uint32_t)(DL_CTRL_GO | DL_CTRL_AUTO_GO | DL_CTRL_STRICT |
    4dac:	02040263          	beqz	s0,4dd0 <dl_go+0x54>
    4db0:	03500593          	li	a1,53
    4db4:	05800513          	li	a0,88
    4db8:	990fe0ef          	jal	2f48 <blt_wr>
}
    4dbc:	00c12083          	lw	ra,12(sp)
    4dc0:	00812403          	lw	s0,8(sp)
    4dc4:	00412483          	lw	s1,4(sp)
    4dc8:	01010113          	addi	sp,sp,16
    4dcc:	00008067          	ret
    blt_wr(BLT_DL_CTRL,     (uint32_t)(DL_CTRL_GO | DL_CTRL_AUTO_GO | DL_CTRL_STRICT |
    4dd0:	03100593          	li	a1,49
    4dd4:	fe1ff06f          	j	4db4 <dl_go+0x38>

00004dd8 <dl_err_name>:
    if (e & 0x01u)       return "DESC_RANGE (base/count/tail)";
    4dd8:	00157793          	andi	a5,a0,1
    4ddc:	04079863          	bnez	a5,4e2c <dl_err_name+0x54>
    if (e & 0x02u)       return "GEOM_INDEX (SPR_ID>=GEOM_MAX, or GEOM_MAX=0)";
    4de0:	00257793          	andi	a5,a0,2
    4de4:	04079a63          	bnez	a5,4e38 <dl_err_name+0x60>
    if (e & 0x04u)       return "GEOM_RANGE (geom addr off/unaligned)";
    4de8:	00457793          	andi	a5,a0,4
    4dec:	04079c63          	bnez	a5,4e44 <dl_err_name+0x6c>
    if (e & 0x08u)       return "SPRITE_BOUNDS (off-screen w/o CLIP_EN)";
    4df0:	00857793          	andi	a5,a0,8
    4df4:	04079e63          	bnez	a5,4e50 <dl_err_name+0x78>
    if (e & 0x10u)       return "WATCHDOG (one descriptor stuck > DL_TIMEOUT)";
    4df8:	01057793          	andi	a5,a0,16
    4dfc:	06079063          	bnez	a5,4e5c <dl_err_name+0x84>
    if (e & 0x20u)       return "AXI_RRESP (R channel not OKAY)";
    4e00:	02057793          	andi	a5,a0,32
    4e04:	06079263          	bnez	a5,4e68 <dl_err_name+0x90>
    if (e & 0x40u)       return "DESC_COUNT (>4095)";
    4e08:	04057793          	andi	a5,a0,64
    4e0c:	06079463          	bnez	a5,4e74 <dl_err_name+0x9c>
    if (e & 0x80u)       return "ZERO_SIZE (W or H == 0; geometry/override)";
    4e10:	08057793          	andi	a5,a0,128
    4e14:	06079663          	bnez	a5,4e80 <dl_err_name+0xa8>
    if (e & 0x01000000u) return "UNSUPPORTED (MIRROR/SRC_OFF/CHAIN/MASK_MODE)";
    4e18:	00751793          	slli	a5,a0,0x7
    4e1c:	0607c863          	bltz	a5,4e8c <dl_err_name+0xb4>
    return "?";
    4e20:	00006537          	lui	a0,0x6
    4e24:	ff050513          	addi	a0,a0,-16 # 5ff0 <_data+0x1f0>
    4e28:	00008067          	ret
    if (e & 0x01u)       return "DESC_RANGE (base/count/tail)";
    4e2c:	00006537          	lui	a0,0x6
    4e30:	e9050513          	addi	a0,a0,-368 # 5e90 <_data+0x90>
    4e34:	00008067          	ret
    if (e & 0x02u)       return "GEOM_INDEX (SPR_ID>=GEOM_MAX, or GEOM_MAX=0)";
    4e38:	00006537          	lui	a0,0x6
    4e3c:	eb050513          	addi	a0,a0,-336 # 5eb0 <_data+0xb0>
    4e40:	00008067          	ret
    if (e & 0x04u)       return "GEOM_RANGE (geom addr off/unaligned)";
    4e44:	00006537          	lui	a0,0x6
    4e48:	ee050513          	addi	a0,a0,-288 # 5ee0 <_data+0xe0>
    4e4c:	00008067          	ret
    if (e & 0x08u)       return "SPRITE_BOUNDS (off-screen w/o CLIP_EN)";
    4e50:	00006537          	lui	a0,0x6
    4e54:	f0850513          	addi	a0,a0,-248 # 5f08 <_data+0x108>
    4e58:	00008067          	ret
    if (e & 0x10u)       return "WATCHDOG (one descriptor stuck > DL_TIMEOUT)";
    4e5c:	00006537          	lui	a0,0x6
    4e60:	f3050513          	addi	a0,a0,-208 # 5f30 <_data+0x130>
    4e64:	00008067          	ret
    if (e & 0x20u)       return "AXI_RRESP (R channel not OKAY)";
    4e68:	00006537          	lui	a0,0x6
    4e6c:	f6050513          	addi	a0,a0,-160 # 5f60 <_data+0x160>
    4e70:	00008067          	ret
    if (e & 0x40u)       return "DESC_COUNT (>4095)";
    4e74:	00006537          	lui	a0,0x6
    4e78:	f8050513          	addi	a0,a0,-128 # 5f80 <_data+0x180>
    4e7c:	00008067          	ret
    if (e & 0x80u)       return "ZERO_SIZE (W or H == 0; geometry/override)";
    4e80:	00006537          	lui	a0,0x6
    4e84:	f9450513          	addi	a0,a0,-108 # 5f94 <_data+0x194>
    4e88:	00008067          	ret
    if (e & 0x01000000u) return "UNSUPPORTED (MIRROR/SRC_OFF/CHAIN/MASK_MODE)";
    4e8c:	00006537          	lui	a0,0x6
    4e90:	fc050513          	addi	a0,a0,-64 # 5fc0 <_data+0x1c0>
}
    4e94:	00008067          	ret

00004e98 <hw_y0>:
static int hw_y0(int path)  { (void)path; return TOP_Y0; }
    4e98:	01000513          	li	a0,16
    4e9c:	00008067          	ret

00004ea0 <hw_h>:
static int hw_h(int path)   { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
    4ea0:	00051663          	bnez	a0,4eac <hw_h+0xc>
    4ea4:	10400513          	li	a0,260
    4ea8:	00008067          	ret
    4eac:	20c00513          	li	a0,524
    4eb0:	00008067          	ret

00004eb4 <cpu_y0>:
static int cpu_y0(int path) { return (path == PATH_SPLIT) ? BOT_Y0 : TOP_Y0; }
    4eb4:	00051663          	bnez	a0,4ec0 <cpu_y0+0xc>
    4eb8:	11800513          	li	a0,280
    4ebc:	00008067          	ret
    4ec0:	01000513          	li	a0,16
    4ec4:	00008067          	ret

00004ec8 <cpu_h>:
static int cpu_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
    4ec8:	00051663          	bnez	a0,4ed4 <cpu_h+0xc>
    4ecc:	10400513          	li	a0,260
    4ed0:	00008067          	ret
    4ed4:	20c00513          	li	a0,524
    4ed8:	00008067          	ret

00004edc <vrg_h>:
static int vrg_h(int path)  { return (path == PATH_SPLIT) ? HALF_H : (FB_HEIGHT - TOP_Y0); }
    4edc:	00051663          	bnez	a0,4ee8 <vrg_h+0xc>
    4ee0:	10400513          	li	a0,260
    4ee4:	00008067          	ret
    4ee8:	20c00513          	li	a0,524
    4eec:	00008067          	ret

00004ef0 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    4ef0:	fc010113          	addi	sp,sp,-64
    4ef4:	00112e23          	sw	ra,28(sp)
    4ef8:	00812c23          	sw	s0,24(sp)
    4efc:	00912a23          	sw	s1,20(sp)
    4f00:	00050493          	mv	s1,a0
    4f04:	02b12223          	sw	a1,36(sp)
    4f08:	02c12423          	sw	a2,40(sp)
    4f0c:	02d12623          	sw	a3,44(sp)
    4f10:	02e12823          	sw	a4,48(sp)
    4f14:	02f12a23          	sw	a5,52(sp)
    4f18:	03012c23          	sw	a6,56(sp)
    4f1c:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    4f20:	02410793          	addi	a5,sp,36
    4f24:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    4f28:	00000413          	li	s0,0
    4f2c:	01c0006f          	j	4f48 <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    4f30:	00c12783          	lw	a5,12(sp)
    4f34:	00478713          	addi	a4,a5,4
    4f38:	00e12623          	sw	a4,12(sp)
    4f3c:	0007a503          	lw	a0,0(a5)
    4f40:	e0dfd0ef          	jal	2d4c <bsp_printf_c>
        for (i = 0; format[i]; i++)
    4f44:	00140413          	addi	s0,s0,1
    4f48:	008487b3          	add	a5,s1,s0
    4f4c:	0007c503          	lbu	a0,0(a5)
    4f50:	0a050e63          	beqz	a0,500c <bsp_printf+0x11c>
            if (format[i] == '%') {
    4f54:	02500793          	li	a5,37
    4f58:	06f50e63          	beq	a0,a5,4fd4 <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    4f5c:	df1fd0ef          	jal	2d4c <bsp_printf_c>
    4f60:	fe5ff06f          	j	4f44 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    4f64:	00c12783          	lw	a5,12(sp)
    4f68:	00478713          	addi	a4,a5,4
    4f6c:	00e12623          	sw	a4,12(sp)
    4f70:	0007a503          	lw	a0,0(a5)
    4f74:	df5fd0ef          	jal	2d68 <bsp_printf_s>
                        break;
    4f78:	fcdff06f          	j	4f44 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    4f7c:	00c12783          	lw	a5,12(sp)
    4f80:	00478713          	addi	a4,a5,4
    4f84:	00e12623          	sw	a4,12(sp)
    4f88:	0007a503          	lw	a0,0(a5)
    4f8c:	df5fd0ef          	jal	2d80 <bsp_printf_d>
                        break;
    4f90:	fb5ff06f          	j	4f44 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    4f94:	00c12783          	lw	a5,12(sp)
    4f98:	00478713          	addi	a4,a5,4
    4f9c:	00e12623          	sw	a4,12(sp)
    4fa0:	0007a503          	lw	a0,0(a5)
    4fa4:	e9dfd0ef          	jal	2e40 <bsp_printf_X>
                        break;
    4fa8:	f9dff06f          	j	4f44 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    4fac:	00c12783          	lw	a5,12(sp)
    4fb0:	00478713          	addi	a4,a5,4
    4fb4:	00e12623          	sw	a4,12(sp)
    4fb8:	0007a503          	lw	a0,0(a5)
    4fbc:	e45fd0ef          	jal	2e00 <bsp_printf_x>
                        break;
    4fc0:	f85ff06f          	j	4f44 <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    4fc4:	00006537          	lui	a0,0x6
    4fc8:	ff450513          	addi	a0,a0,-12 # 5ff4 <_data+0x1f4>
    4fcc:	d9dfd0ef          	jal	2d68 <bsp_printf_s>
                        break;
    4fd0:	f75ff06f          	j	4f44 <bsp_printf+0x54>
                while (format[++i]) {
    4fd4:	00140413          	addi	s0,s0,1
    4fd8:	008487b3          	add	a5,s1,s0
    4fdc:	0007c783          	lbu	a5,0(a5)
    4fe0:	f60782e3          	beqz	a5,4f44 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    4fe4:	fa878793          	addi	a5,a5,-88
    4fe8:	0ff7f693          	zext.b	a3,a5
    4fec:	02000713          	li	a4,32
    4ff0:	fed762e3          	bltu	a4,a3,4fd4 <bsp_printf+0xe4>
    4ff4:	00269793          	slli	a5,a3,0x2
    4ff8:	00007737          	lui	a4,0x7
    4ffc:	50c70713          	addi	a4,a4,1292 # 750c <_data+0x170c>
    5000:	00e787b3          	add	a5,a5,a4
    5004:	0007a783          	lw	a5,0(a5)
    5008:	00078067          	jr	a5

        va_end(ap);
    }
    500c:	01c12083          	lw	ra,28(sp)
    5010:	01812403          	lw	s0,24(sp)
    5014:	01412483          	lw	s1,20(sp)
    5018:	04010113          	addi	sp,sp,64
    501c:	00008067          	ret

00005020 <spr_mask_report>:
{
    5020:	ff010113          	addi	sp,sp,-16
    5024:	00112623          	sw	ra,12(sp)
    5028:	00812423          	sw	s0,8(sp)
    502c:	00912223          	sw	s1,4(sp)
    bsp_printf("EV atlas %dx%d keymask=%x marked=%d/16 (KEY dw3[15:0]+FLAGS[7]=1; ALPHA/FILL ignore)\r\n",
    5030:	8201a403          	lw	s0,-2016(gp) # 7918 <g_blk>
    5034:	8b01d483          	lhu	s1,-1872(gp) # 79a8 <g_spr_mask>
    5038:	00048513          	mv	a0,s1
    503c:	e04fe0ef          	jal	3640 <spr_mask_tiles>
    5040:	00050713          	mv	a4,a0
    5044:	00048693          	mv	a3,s1
    5048:	00040613          	mv	a2,s0
    504c:	00040593          	mv	a1,s0
    5050:	00006537          	lui	a0,0x6
    5054:	04050513          	addi	a0,a0,64 # 6040 <_data+0x240>
    5058:	e99ff0ef          	jal	4ef0 <bsp_printf>
}
    505c:	00c12083          	lw	ra,12(sp)
    5060:	00812403          	lw	s0,8(sp)
    5064:	00412483          	lw	s1,4(sp)
    5068:	01010113          	addi	sp,sp,16
    506c:	00008067          	ret

00005070 <dl_supported>:
{
    5070:	ff010113          	addi	sp,sp,-16
    5074:	00112623          	sw	ra,12(sp)
    uint32_t v = blt_rd(BLT_DL_VERSION);
    5078:	08000513          	li	a0,128
    507c:	eddfd0ef          	jal	2f58 <blt_rd>
    if ((v & 0xFFFFu) >= 2u) return 1;
    5080:	01051793          	slli	a5,a0,0x10
    5084:	0117d793          	srli	a5,a5,0x11
    5088:	00078a63          	beqz	a5,509c <dl_supported+0x2c>
    508c:	00100513          	li	a0,1
}
    5090:	00c12083          	lw	ra,12(sp)
    5094:	01010113          	addi	sp,sp,16
    5098:	00008067          	ret
    bsp_printf("\r\nEV dl not supported (DL_VERSION=%x, need [15:0]>=2)\r\n", (unsigned)v);
    509c:	00050593          	mv	a1,a0
    50a0:	00006537          	lui	a0,0x6
    50a4:	09850513          	addi	a0,a0,152 # 6098 <_data+0x298>
    50a8:	e49ff0ef          	jal	4ef0 <bsp_printf>
    return 0;
    50ac:	00000513          	li	a0,0
    50b0:	fe1ff06f          	j	5090 <dl_supported+0x20>

000050b4 <dl_apply_pending>:
    if (g_dl_want < 0) return 0;                                   /* 没有待生效请求 */
    50b4:	8101a783          	lw	a5,-2032(gp) # 7908 <g_dl_want>
    50b8:	0c07c263          	bltz	a5,517c <dl_apply_pending+0xc8>
    if (g_dl_inflight || g_dl_pend >= 0 || g_dl_fbwait) return 0;   /* 还有表在飞 ⇒ 再等一帧 */
    50bc:	88c1a503          	lw	a0,-1908(gp) # 7984 <g_dl_inflight>
    50c0:	0c051263          	bnez	a0,5184 <dl_apply_pending+0xd0>
    50c4:	8141a703          	lw	a4,-2028(gp) # 790c <g_dl_pend>
    50c8:	0c075263          	bgez	a4,518c <dl_apply_pending+0xd8>
    50cc:	87c1a703          	lw	a4,-1924(gp) # 7974 <g_dl_fbwait>
    50d0:	0a071e63          	bnez	a4,518c <dl_apply_pending+0xd8>
{
    50d4:	ff010113          	addi	sp,sp,-16
    50d8:	00112623          	sw	ra,12(sp)
    g_dl_mode  = g_dl_want;
    50dc:	88f1aa23          	sw	a5,-1900(gp) # 798c <g_dl_mode>
    g_dl_want  = -1;
    50e0:	fff00693          	li	a3,-1
    50e4:	80d1a823          	sw	a3,-2032(gp) # 7908 <g_dl_want>
    g_dl_armed = 0;                       /* 关→开时下次重新走一遍 dl_arm() */
    50e8:	8801a823          	sw	zero,-1904(gp) # 7988 <g_dl_armed>
    g_dl_retry_n = 0; g_dl_retry_pend = 0;
    50ec:	8601a223          	sw	zero,-1948(gp) # 795c <g_dl_retry_n>
    50f0:	8601a023          	sw	zero,-1952(gp) # 7958 <g_dl_retry_pend>
    g_dl_wd_events = 0; g_dl_wd_last = 0;
    50f4:	8401aa23          	sw	zero,-1964(gp) # 794c <g_dl_wd_events>
    50f8:	8401a823          	sw	zero,-1968(gp) # 7948 <g_dl_wd_last>
    g_cmd_t0 = 0;
    50fc:	8201ae23          	sw	zero,-1988(gp) # 7934 <g_cmd_t0>
    bsp_printf("\r\nEV dl %s\r\n", g_dl_mode ? "on" : "off");
    5100:	04078463          	beqz	a5,5148 <dl_apply_pending+0x94>
    5104:	000065b7          	lui	a1,0x6
    5108:	0d058593          	addi	a1,a1,208 # 60d0 <_data+0x2d0>
    510c:	00006537          	lui	a0,0x6
    5110:	0d850513          	addi	a0,a0,216 # 60d8 <_data+0x2d8>
    5114:	dddff0ef          	jal	4ef0 <bsp_printf>
    if (g_dl_mode)
    5118:	8941a783          	lw	a5,-1900(gp) # 798c <g_dl_mode>
    511c:	02079c63          	bnez	a5,5154 <dl_apply_pending+0xa0>
    bsp_printf("     clr fb=%d to=%d err=%d (cumulative; fb=region repaint in-path)\r\n",
    5120:	8b41a683          	lw	a3,-1868(gp) # 79ac <g_clr_err>
    5124:	8b81a603          	lw	a2,-1864(gp) # 79b0 <g_clr_to>
    5128:	8bc1a583          	lw	a1,-1860(gp) # 79b4 <g_clr_fb>
    512c:	00006537          	lui	a0,0x6
    5130:	11450513          	addi	a0,a0,276 # 6114 <_data+0x314>
    5134:	dbdff0ef          	jal	4ef0 <bsp_printf>
    return 1;                              /* 本帧真的换了模式 ⇒ 调用方重画信息条 */
    5138:	00100513          	li	a0,1
}
    513c:	00c12083          	lw	ra,12(sp)
    5140:	01010113          	addi	sp,sp,16
    5144:	00008067          	ret
    bsp_printf("\r\nEV dl %s\r\n", g_dl_mode ? "on" : "off");
    5148:	000065b7          	lui	a1,0x6
    514c:	0d458593          	addi	a1,a1,212 # 60d4 <_data+0x2d4>
    5150:	fbdff06f          	j	510c <dl_apply_pending+0x58>
                   (unsigned)blt_rd(BLT_DL_VERSION), (unsigned)DL_GEOM_ADDR,
    5154:	08000513          	li	a0,128
    5158:	e01fd0ef          	jal	2f58 <blt_rd>
    515c:	00050593          	mv	a1,a0
        bsp_printf("     DL_VERSION=%x geom=%x lists=%x/%x\r\n",
    5160:	00841737          	lui	a4,0x841
    5164:	008216b7          	lui	a3,0x821
    5168:	00801637          	lui	a2,0x801
    516c:	00006537          	lui	a0,0x6
    5170:	0e850513          	addi	a0,a0,232 # 60e8 <_data+0x2e8>
    5174:	d7dff0ef          	jal	4ef0 <bsp_printf>
    5178:	fa9ff06f          	j	5120 <dl_apply_pending+0x6c>
    if (g_dl_want < 0) return 0;                                   /* 没有待生效请求 */
    517c:	00000513          	li	a0,0
    5180:	00008067          	ret
    if (g_dl_inflight || g_dl_pend >= 0 || g_dl_fbwait) return 0;   /* 还有表在飞 ⇒ 再等一帧 */
    5184:	00000513          	li	a0,0
    5188:	00008067          	ret
}
    518c:	00008067          	ret

00005190 <dl_status_dump>:
{
    5190:	fe010113          	addi	sp,sp,-32
    5194:	00112e23          	sw	ra,28(sp)
    5198:	00058613          	mv	a2,a1
               (int)(st & 1u), (int)((st >> 1) & 1u), (int)((st >> 2) & 1u),
    519c:	0015d713          	srli	a4,a1,0x1
    51a0:	0025d793          	srli	a5,a1,0x2
               (int)((st >> 3) & 1u), (int)((st >> 4) & 1u),
    51a4:	0035d813          	srli	a6,a1,0x3
    51a8:	0045d893          	srli	a7,a1,0x4
               (int)((st >> 8) & 3u), (int)(st >> DL_ST_CONSUMED_SH),
    51ac:	0085d693          	srli	a3,a1,0x8
    51b0:	0105d593          	srli	a1,a1,0x10
    bsp_printf("EV dl %s: DL_STATUS=%x BUSY=%d DONE=%d ERR=%d ABORTED=%d STALL=%d ACTIVE_BUF=%d CONSUMED=%d stall_seen=%d\r\n",
    51b4:	86c1a303          	lw	t1,-1940(gp) # 7964 <g_dl_stall_seen>
    51b8:	00612423          	sw	t1,8(sp)
    51bc:	00b12223          	sw	a1,4(sp)
    51c0:	0036f693          	andi	a3,a3,3
    51c4:	00d12023          	sw	a3,0(sp)
    51c8:	0018f893          	andi	a7,a7,1
    51cc:	00187813          	andi	a6,a6,1
    51d0:	0017f793          	andi	a5,a5,1
    51d4:	00177713          	andi	a4,a4,1
    51d8:	00167693          	andi	a3,a2,1
    51dc:	00050593          	mv	a1,a0
    51e0:	00006537          	lui	a0,0x6
    51e4:	15c50513          	addi	a0,a0,348 # 615c <_data+0x35c>
    51e8:	d09ff0ef          	jal	4ef0 <bsp_printf>
}
    51ec:	01c12083          	lw	ra,28(sp)
    51f0:	02010113          	addi	sp,sp,32
    51f4:	00008067          	ret

000051f8 <dl_reg_chk>:
{
    51f8:	ff010113          	addi	sp,sp,-16
    51fc:	00112623          	sw	ra,12(sp)
    5200:	00812423          	sw	s0,8(sp)
    5204:	00912223          	sw	s1,4(sp)
    5208:	00058413          	mv	s0,a1
    520c:	00060493          	mv	s1,a2
    uint32_t got = blt_rd(off);
    5210:	d49fd0ef          	jal	2f58 <blt_rd>
    if (got != want) {
    5214:	00851e63          	bne	a0,s0,5230 <dl_reg_chk+0x38>
    return 1;
    5218:	00100513          	li	a0,1
}
    521c:	00c12083          	lw	ra,12(sp)
    5220:	00812403          	lw	s0,8(sp)
    5224:	00412483          	lw	s1,4(sp)
    5228:	01010113          	addi	sp,sp,16
    522c:	00008067          	ret
        bsp_printf("EV dl arm FAIL %s: wrote %x read %x\r\n", name,
    5230:	00050693          	mv	a3,a0
    5234:	00040613          	mv	a2,s0
    5238:	00048593          	mv	a1,s1
    523c:	00006537          	lui	a0,0x6
    5240:	1c850513          	addi	a0,a0,456 # 61c8 <_data+0x3c8>
    5244:	cadff0ef          	jal	4ef0 <bsp_printf>
        return 0;
    5248:	00000513          	li	a0,0
    524c:	fd1ff06f          	j	521c <dl_reg_chk+0x24>

00005250 <dl_arm_verify>:
{
    5250:	f4010113          	addi	sp,sp,-192
    5254:	0a112e23          	sw	ra,188(sp)
    dl_geom_fill(exp);                       /* 期望值 = 同一个生成函数 */
    5258:	00010513          	mv	a0,sp
    525c:	8b5ff0ef          	jal	4b10 <dl_geom_fill>
    for (i = 0; i < DL_GEOM_N * 4; i++) {
    5260:	00000513          	li	a0,0
    5264:	02b00793          	li	a5,43
    5268:	06a7c663          	blt	a5,a0,52d4 <dl_arm_verify+0x84>
        if (ge[i] != exp[i]) {
    526c:	00251793          	slli	a5,a0,0x2
    5270:	00801737          	lui	a4,0x801
    5274:	00f70733          	add	a4,a4,a5
    5278:	00072603          	lw	a2,0(a4) # 801000 <__freertos_irq_stack_top+0x7bdc60>
    527c:	0b078793          	addi	a5,a5,176
    5280:	002787b3          	add	a5,a5,sp
    5284:	f507a683          	lw	a3,-176(a5)
    5288:	00d61663          	bne	a2,a3,5294 <dl_arm_verify+0x44>
    for (i = 0; i < DL_GEOM_N * 4; i++) {
    528c:	00150513          	addi	a0,a0,1
    5290:	fd5ff06f          	j	5264 <dl_arm_verify+0x14>
            bsp_printf("EV dl arm FAIL geom[%d].dw%d: wrote %x read %x\r\n",
    5294:	00072703          	lw	a4,0(a4)
    5298:	41f55793          	srai	a5,a0,0x1f
    529c:	01e7d813          	srli	a6,a5,0x1e
    52a0:	01050633          	add	a2,a0,a6
    52a4:	00367613          	andi	a2,a2,3
    52a8:	0037f793          	andi	a5,a5,3
    52ac:	00a785b3          	add	a1,a5,a0
    52b0:	41060633          	sub	a2,a2,a6
    52b4:	4025d593          	srai	a1,a1,0x2
    52b8:	00006537          	lui	a0,0x6
    52bc:	1f050513          	addi	a0,a0,496 # 61f0 <_data+0x3f0>
    52c0:	c31ff0ef          	jal	4ef0 <bsp_printf>
            return 0;
    52c4:	00000513          	li	a0,0
}
    52c8:	0bc12083          	lw	ra,188(sp)
    52cc:	0c010113          	addi	sp,sp,192
    52d0:	00008067          	ret
    for (i = DL_G_ALPHA_16; i <= DL_G_KEY_64; i++) {
    52d4:	00300593          	li	a1,3
    52d8:	00800793          	li	a5,8
    52dc:	06b7c263          	blt	a5,a1,5340 <dl_arm_verify+0xf0>
        unsigned w = (unsigned)(ge[i * 4 + 2] & 0xFFFFu);
    52e0:	00459513          	slli	a0,a1,0x4
    52e4:	00850693          	addi	a3,a0,8
    52e8:	00801737          	lui	a4,0x801
    52ec:	00d706b3          	add	a3,a4,a3
    52f0:	0006a603          	lw	a2,0(a3) # 821000 <__freertos_irq_stack_top+0x7ddc60>
    52f4:	000107b7          	lui	a5,0x10
    52f8:	fff78793          	addi	a5,a5,-1 # ffff <__global_pointer$+0x7f07>
    52fc:	00f67633          	and	a2,a2,a5
        unsigned h = (unsigned)(ge[i * 4 + 2] >> 16);
    5300:	0006a683          	lw	a3,0(a3)
    5304:	0106d693          	srli	a3,a3,0x10
        unsigned st= (unsigned)(ge[i * 4 + 1] & 0xFFFFu);
    5308:	00450513          	addi	a0,a0,4
    530c:	00a70733          	add	a4,a4,a0
    5310:	00072703          	lw	a4,0(a4) # 801000 <__freertos_irq_stack_top+0x7bdc60>
    5314:	00f77733          	and	a4,a4,a5
        if (!w || !h || !st) {
    5318:	00060a63          	beqz	a2,532c <dl_arm_verify+0xdc>
    531c:	00068863          	beqz	a3,532c <dl_arm_verify+0xdc>
    5320:	00070663          	beqz	a4,532c <dl_arm_verify+0xdc>
    for (i = DL_G_ALPHA_16; i <= DL_G_KEY_64; i++) {
    5324:	00158593          	addi	a1,a1,1
    5328:	fb1ff06f          	j	52d8 <dl_arm_verify+0x88>
            bsp_printf("EV dl arm FAIL geom[%d]: W=%d H=%d stride=%d (must be non-zero)\r\n",
    532c:	00006537          	lui	a0,0x6
    5330:	22450513          	addi	a0,a0,548 # 6224 <_data+0x424>
    5334:	bbdff0ef          	jal	4ef0 <bsp_printf>
            return 0;
    5338:	00000513          	li	a0,0
    533c:	f8dff06f          	j	52c8 <dl_arm_verify+0x78>
    if (!dl_reg_chk(BLT_DL_GEOM_BASE,  DL_GEOM_ADDR,   "GEOM_BASE"))  return 0;
    5340:	00006637          	lui	a2,0x6
    5344:	26860613          	addi	a2,a2,616 # 6268 <_data+0x468>
    5348:	008015b7          	lui	a1,0x801
    534c:	06800513          	li	a0,104
    5350:	ea9ff0ef          	jal	51f8 <dl_reg_chk>
    5354:	f6050ae3          	beqz	a0,52c8 <dl_arm_verify+0x78>
    if (!dl_reg_chk(BLT_DL_GEOM_MAX,   (uint32_t)DL_GEOM_N, "GEOM_MAX")) return 0;
    5358:	00006637          	lui	a2,0x6
    535c:	27460613          	addi	a2,a2,628 # 6274 <_data+0x474>
    5360:	00b00593          	li	a1,11
    5364:	06c00513          	li	a0,108
    5368:	e91ff0ef          	jal	51f8 <dl_reg_chk>
    536c:	f4050ee3          	beqz	a0,52c8 <dl_arm_verify+0x78>
    if (!dl_reg_chk(BLT_DL_DST_STRIDE, (uint32_t)FB_STRIDE, "DST_STRIDE")) return 0;
    5370:	00006637          	lui	a2,0x6
    5374:	28060613          	addi	a2,a2,640 # 6280 <_data+0x480>
    5378:	78000593          	li	a1,1920
    537c:	08400513          	li	a0,132
    5380:	e79ff0ef          	jal	51f8 <dl_reg_chk>
    5384:	f40502e3          	beqz	a0,52c8 <dl_arm_verify+0x78>
    if (!dl_reg_chk(BLT_DL_FB_WH,
    5388:	00006637          	lui	a2,0x6
    538c:	28c60613          	addi	a2,a2,652 # 628c <_data+0x48c>
    5390:	021c05b7          	lui	a1,0x21c0
    5394:	3c058593          	addi	a1,a1,960 # 21c03c0 <__freertos_irq_stack_top+0x217d020>
    5398:	08800513          	li	a0,136
    539c:	e5dff0ef          	jal	51f8 <dl_reg_chk>
    53a0:	f20504e3          	beqz	a0,52c8 <dl_arm_verify+0x78>
    if (!dl_reg_chk(BLT_DL_BASE0,      DL_LIST_ADDR(0), "BASE0"))     return 0;
    53a4:	00006637          	lui	a2,0x6
    53a8:	29460613          	addi	a2,a2,660 # 6294 <_data+0x494>
    53ac:	008215b7          	lui	a1,0x821
    53b0:	04c00513          	li	a0,76
    53b4:	e45ff0ef          	jal	51f8 <dl_reg_chk>
    53b8:	f00508e3          	beqz	a0,52c8 <dl_arm_verify+0x78>
    if (!dl_reg_chk(BLT_DL_BASE1,      DL_LIST_ADDR(1), "BASE1"))     return 0;
    53bc:	00006637          	lui	a2,0x6
    53c0:	29c60613          	addi	a2,a2,668 # 629c <_data+0x49c>
    53c4:	008415b7          	lui	a1,0x841
    53c8:	05000513          	li	a0,80
    53cc:	e2dff0ef          	jal	51f8 <dl_reg_chk>
    53d0:	ee050ce3          	beqz	a0,52c8 <dl_arm_verify+0x78>
    return 1;
    53d4:	00100513          	li	a0,1
    53d8:	ef1ff06f          	j	52c8 <dl_arm_verify+0x78>

000053dc <dl_arm>:
{
    53dc:	ff010113          	addi	sp,sp,-16
    53e0:	00112623          	sw	ra,12(sp)
    53e4:	00812423          	sw	s0,8(sp)
    if (!dl_arm_wait_idle()) {
    53e8:	941ff0ef          	jal	4d28 <dl_arm_wait_idle>
    53ec:	10050463          	beqz	a0,54f4 <dl_arm+0x118>
    dl_geom_build();
    53f0:	919ff0ef          	jal	4d08 <dl_geom_build>
    blt_wr(BLT_DL_GEOM_BASE,  DL_GEOM_ADDR);                     /* [31:4]，16B 对齐 */
    53f4:	008015b7          	lui	a1,0x801
    53f8:	06800513          	li	a0,104
    53fc:	b4dfd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_GEOM_MAX,   (uint32_t)DL_GEOM_N);
    5400:	00b00593          	li	a1,11
    5404:	06c00513          	li	a0,108
    5408:	b41fd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_DST_STRIDE, (uint32_t)FB_STRIDE);
    540c:	78000593          	li	a1,1920
    5410:	08400513          	li	a0,132
    5414:	b35fd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_FB_WH,      ((uint32_t)FB_HEIGHT << 16) | (uint32_t)FB_WIDTH);
    5418:	021c05b7          	lui	a1,0x21c0
    541c:	3c058593          	addi	a1,a1,960 # 21c03c0 <__freertos_irq_stack_top+0x217d020>
    5420:	08800513          	li	a0,136
    5424:	b25fd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_BASE0,      DL_LIST_ADDR(0));                  /* 写 BASE 会清 DONE */
    5428:	008215b7          	lui	a1,0x821
    542c:	04c00513          	li	a0,76
    5430:	b19fd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_BASE1,      DL_LIST_ADDR(1));
    5434:	008415b7          	lui	a1,0x841
    5438:	05000513          	li	a0,80
    543c:	b0dfd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_ERR,        DL_ERR_CLR_ALL);                   /* W1C：清掉上次的锁存 */
    5440:	010005b7          	lui	a1,0x1000
    5444:	0ff58593          	addi	a1,a1,255 # 10000ff <__freertos_irq_stack_top+0xfbcd5f>
    5448:	06000513          	li	a0,96
    544c:	afdfd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_CTRL,       DL_CTRL_AUTO_GO | DL_CTRL_STRICT);
    5450:	03000593          	li	a1,48
    5454:	05800513          	li	a0,88
    5458:	af1fd0ef          	jal	2f48 <blt_wr>
    blt_wr(BLT_DL_TIMEOUT,    DL_TIMEOUT_TICKS);
    545c:	000105b7          	lui	a1,0x10
    5460:	fff58593          	addi	a1,a1,-1 # ffff <__global_pointer$+0x7f07>
    5464:	07800513          	li	a0,120
    5468:	ae1fd0ef          	jal	2f48 <blt_wr>
    cache_evict();
    546c:	d71fd0ef          	jal	31dc <cache_evict>
    if (!dl_arm_verify()) {
    5470:	de1ff0ef          	jal	5250 <dl_arm_verify>
    5474:	00050413          	mv	s0,a0
    5478:	08050e63          	beqz	a0,5514 <dl_arm+0x138>
    547c:	00912223          	sw	s1,4(sp)
        uint32_t tmo = blt_rd(BLT_DL_TIMEOUT) & 0xFFFFu;
    5480:	07800513          	li	a0,120
    5484:	ad5fd0ef          	jal	2f58 <blt_rd>
    5488:	000107b7          	lui	a5,0x10
    548c:	fff78793          	addi	a5,a5,-1 # ffff <__global_pointer$+0x7f07>
    5490:	00f57433          	and	s0,a0,a5
        if (tmo != (DL_TIMEOUT_TICKS & 0xFFFFu))
    5494:	08f41863          	bne	s0,a5,5524 <dl_arm+0x148>
                   (unsigned)blt_rd(BLT_DL_GEOM_BASE), (int)(blt_rd(BLT_DL_GEOM_MAX) & 0xFFFFu));
    5498:	06800513          	li	a0,104
    549c:	abdfd0ef          	jal	2f58 <blt_rd>
    54a0:	00050493          	mv	s1,a0
    54a4:	06c00513          	li	a0,108
    54a8:	ab1fd0ef          	jal	2f58 <blt_rd>
        bsp_printf("EV dl arm ok: timeout=%d/%d ticks (x%d reset %d, ~753us@87MHz) GEOM_BASE=%x GEOM_MAX=%d\r\n",
    54ac:	00010637          	lui	a2,0x10
    54b0:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f07>
    54b4:	00c57833          	and	a6,a0,a2
    54b8:	00048793          	mv	a5,s1
    54bc:	00001737          	lui	a4,0x1
    54c0:	01000693          	li	a3,16
    54c4:	00040593          	mv	a1,s0
    54c8:	00006537          	lui	a0,0x6
    54cc:	38c50513          	addi	a0,a0,908 # 638c <_data+0x58c>
    54d0:	a21ff0ef          	jal	4ef0 <bsp_printf>
    g_dl_stall_seen = 0;          /* 从这一刻起重新观察"取指有没有被饿住"（见状态声明处） */
    54d4:	8601a623          	sw	zero,-1940(gp) # 7964 <g_dl_stall_seen>
    return 1;
    54d8:	00100413          	li	s0,1
    54dc:	00412483          	lw	s1,4(sp)
}
    54e0:	00040513          	mv	a0,s0
    54e4:	00c12083          	lw	ra,12(sp)
    54e8:	00812403          	lw	s0,8(sp)
    54ec:	01010113          	addi	sp,sp,16
    54f0:	00008067          	ret
    54f4:	00050413          	mv	s0,a0
                   (unsigned)blt_rd(BLT_DL_STATUS));
    54f8:	05c00513          	li	a0,92
    54fc:	a5dfd0ef          	jal	2f58 <blt_rd>
    5500:	00050593          	mv	a1,a0
        bsp_printf("EV dl arm FAIL: DFU still BUSY (DL_STATUS=%x); 0x4C~0x88 writes would be ignored\r\n",
    5504:	00006537          	lui	a0,0x6
    5508:	2a450513          	addi	a0,a0,676 # 62a4 <_data+0x4a4>
    550c:	9e5ff0ef          	jal	4ef0 <bsp_printf>
        return 0;
    5510:	fd1ff06f          	j	54e0 <dl_arm+0x104>
        bsp_printf("EV dl arm FAIL -> list path stays OFF (per-command continues)\r\n");
    5514:	00006537          	lui	a0,0x6
    5518:	2f850513          	addi	a0,a0,760 # 62f8 <_data+0x4f8>
    551c:	9d5ff0ef          	jal	4ef0 <bsp_printf>
        return 0;
    5520:	fc1ff06f          	j	54e0 <dl_arm+0x104>
            bsp_printf("EV dl arm WARN TIMEOUT: wrote %x read %x (0x78 missing? watchdog stays %d ticks)\r\n",
    5524:	000016b7          	lui	a3,0x1
    5528:	00040613          	mv	a2,s0
    552c:	00078593          	mv	a1,a5
    5530:	00006537          	lui	a0,0x6
    5534:	33850513          	addi	a0,a0,824 # 6338 <_data+0x538>
    5538:	9b9ff0ef          	jal	4ef0 <bsp_printf>
    553c:	f5dff06f          	j	5498 <dl_arm+0xbc>

00005540 <dl_err_report>:
{
    5540:	fe010113          	addi	sp,sp,-32
    5544:	00112e23          	sw	ra,28(sp)
    5548:	00812c23          	sw	s0,24(sp)
    554c:	00912a23          	sw	s1,20(sp)
    5550:	01212823          	sw	s2,16(sp)
    5554:	01312623          	sw	s3,12(sp)
    5558:	01412423          	sw	s4,8(sp)
    uint32_t e  = blt_rd(BLT_DL_ERR);
    555c:	06000513          	li	a0,96
    5560:	9f9fd0ef          	jal	2f58 <blt_rd>
    5564:	00050413          	mv	s0,a0
    uint32_t fa = blt_rd(BLT_DL_FAULT_ADDR);
    5568:	06400513          	li	a0,100
    556c:	9edfd0ef          	jal	2f58 <blt_rd>
    5570:	00050993          	mv	s3,a0
    uint32_t st = blt_rd(BLT_DL_STATUS);
    5574:	05c00513          	li	a0,92
    5578:	9e1fd0ef          	jal	2f58 <blt_rd>
    557c:	00050493          	mv	s1,a0
    bsp_printf("\r\nEV DL_ERR code=%x (%s) idx=%d unsup=%d fault=%x\r\n",
    5580:	00040513          	mv	a0,s0
    5584:	855ff0ef          	jal	4dd8 <dl_err_name>
    5588:	00050613          	mv	a2,a0
               (unsigned)(e & 0xFFu), dl_err_name(e), (int)((e >> 16) & 0xFFu),
    558c:	01045913          	srli	s2,s0,0x10
    5590:	0ff97913          	zext.b	s2,s2
               (int)((e >> 24) & 1u), (unsigned)fa);
    5594:	01845713          	srli	a4,s0,0x18
    bsp_printf("\r\nEV DL_ERR code=%x (%s) idx=%d unsup=%d fault=%x\r\n",
    5598:	00098793          	mv	a5,s3
    559c:	00177713          	andi	a4,a4,1
    55a0:	00090693          	mv	a3,s2
    55a4:	0ff47593          	zext.b	a1,s0
    55a8:	00006537          	lui	a0,0x6
    55ac:	3f050513          	addi	a0,a0,1008 # 63f0 <_data+0x5f0>
    55b0:	941ff0ef          	jal	4ef0 <bsp_printf>
    dl_status_dump("status", st);                 /* ★v2.14：解码后的 DL_STATUS + CONSUMED */
    55b4:	00048593          	mv	a1,s1
    55b8:	00006537          	lui	a0,0x6
    55bc:	42450513          	addi	a0,a0,1060 # 6424 <_data+0x624>
    55c0:	bd1ff0ef          	jal	5190 <dl_status_dump>
               (int)blt_rd(BLT_DL_PERF), (int)(DL_TIMEOUT_TICKS & 0xFFFFu));
    55c4:	07c00513          	li	a0,124
    55c8:	991fd0ef          	jal	2f58 <blt_rd>
    55cc:	00050593          	mv	a1,a0
    bsp_printf("EV dl perf_prev=%d tmo=%d (this list's PERF comes after BUSY=0)\r\n",
    55d0:	00010637          	lui	a2,0x10
    55d4:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f07>
    55d8:	00006537          	lui	a0,0x6
    55dc:	42c50513          	addi	a0,a0,1068 # 642c <_data+0x62c>
    55e0:	911ff0ef          	jal	4ef0 <bsp_printf>
               (unsigned)blt_rd(BLT_CLR_STAT), (int)blt_rd(BLT_CLR_CYC),
    55e4:	04000513          	li	a0,64
    55e8:	971fd0ef          	jal	2f58 <blt_rd>
    55ec:	00050993          	mv	s3,a0
    55f0:	04800513          	li	a0,72
    55f4:	965fd0ef          	jal	2f58 <blt_rd>
    55f8:	00050a13          	mv	s4,a0
               (int)(blt_rd(BLT_CLR_STAT) & BLT_CLR_STAT_BUSY),
    55fc:	04000513          	li	a0,64
    5600:	959fd0ef          	jal	2f58 <blt_rd>
    bsp_printf("EV dl clr: CLR_STAT=%x CLR_CYC=%d busy=%d fb=%d to=%d err=%d\r\n",
    5604:	8b41a803          	lw	a6,-1868(gp) # 79ac <g_clr_err>
    5608:	8b81a783          	lw	a5,-1864(gp) # 79b0 <g_clr_to>
    560c:	8bc1a703          	lw	a4,-1860(gp) # 79b4 <g_clr_fb>
    5610:	00157693          	andi	a3,a0,1
    5614:	000a0613          	mv	a2,s4
    5618:	00098593          	mv	a1,s3
    561c:	00006537          	lui	a0,0x6
    5620:	47050513          	addi	a0,a0,1136 # 6470 <_data+0x670>
    5624:	8cdff0ef          	jal	4ef0 <bsp_printf>
        if ((e & 0x10u) && idx)
    5628:	01047793          	andi	a5,s0,16
    562c:	06078e63          	beqz	a5,56a8 <dl_err_report+0x168>
    5630:	0104d613          	srli	a2,s1,0x10
    5634:	06090263          	beqz	s2,5698 <dl_err_report+0x158>
            bsp_printf("EV dl hint: descriptor fetch starved at idx=%d (CONSUMED=%d %s idx, stall_seen=%d) -> DDR bandwidth, not the geometry table\r\n",
    5638:	05267a63          	bgeu	a2,s2,568c <dl_err_report+0x14c>
    563c:	000066b7          	lui	a3,0x6
    5640:	3e868693          	addi	a3,a3,1000 # 63e8 <_data+0x5e8>
    5644:	86c1a703          	lw	a4,-1940(gp) # 7964 <g_dl_stall_seen>
    5648:	00090593          	mv	a1,s2
    564c:	00006537          	lui	a0,0x6
    5650:	4b050513          	addi	a0,a0,1200 # 64b0 <_data+0x6b0>
    5654:	89dff0ef          	jal	4ef0 <bsp_printf>
    blt_wr(BLT_DL_ERR, DL_ERR_CLR_ALL);          /* W1C，否则 ERR 一直挂着（重试前必须清） */
    5658:	010005b7          	lui	a1,0x1000
    565c:	0ff58593          	addi	a1,a1,255 # 10000ff <__freertos_irq_stack_top+0xfbcd5f>
    5660:	06000513          	li	a0,96
    5664:	8e5fd0ef          	jal	2f48 <blt_wr>
}
    5668:	00040513          	mv	a0,s0
    566c:	01c12083          	lw	ra,28(sp)
    5670:	01812403          	lw	s0,24(sp)
    5674:	01412483          	lw	s1,20(sp)
    5678:	01012903          	lw	s2,16(sp)
    567c:	00c12983          	lw	s3,12(sp)
    5680:	00812a03          	lw	s4,8(sp)
    5684:	02010113          	addi	sp,sp,32
    5688:	00008067          	ret
            bsp_printf("EV dl hint: descriptor fetch starved at idx=%d (CONSUMED=%d %s idx, stall_seen=%d) -> DDR bandwidth, not the geometry table\r\n",
    568c:	000066b7          	lui	a3,0x6
    5690:	3ec68693          	addi	a3,a3,1004 # 63ec <_data+0x5ec>
    5694:	fb1ff06f          	j	5644 <dl_err_report+0x104>
            bsp_printf("EV dl hint: WATCHDOG with idx=0 (no descriptor index) -> check DL_COUNT/BASE\r\n");
    5698:	00006537          	lui	a0,0x6
    569c:	53050513          	addi	a0,a0,1328 # 6530 <_data+0x730>
    56a0:	851ff0ef          	jal	4ef0 <bsp_printf>
    56a4:	fb5ff06f          	j	5658 <dl_err_report+0x118>
        else if (e & 0x00000002u)
    56a8:	00247793          	andi	a5,s0,2
    56ac:	02079263          	bnez	a5,56d0 <dl_err_report+0x190>
        else if (e & 0x00000080u)
    56b0:	08047793          	andi	a5,s0,128
    56b4:	02079663          	bnez	a5,56e0 <dl_err_report+0x1a0>
        else if (e & 0x00000020u)
    56b8:	02047793          	andi	a5,s0,32
    56bc:	f8078ee3          	beqz	a5,5658 <dl_err_report+0x118>
            bsp_printf("EV dl hint: read channel not OKAY (descriptor or geometry fetch, both possible)\r\n");
    56c0:	00006537          	lui	a0,0x6
    56c4:	62850513          	addi	a0,a0,1576 # 6628 <_data+0x828>
    56c8:	829ff0ef          	jal	4ef0 <bsp_printf>
    56cc:	f8dff06f          	j	5658 <dl_err_report+0x118>
            bsp_printf("EV dl hint: ALPHA/KEY descriptors need the geometry table; FILL+SIZE_OVR does not\r\n");
    56d0:	00006537          	lui	a0,0x6
    56d4:	58050513          	addi	a0,a0,1408 # 6580 <_data+0x780>
    56d8:	819ff0ef          	jal	4ef0 <bsp_printf>
    56dc:	f7dff06f          	j	5658 <dl_err_report+0x118>
            bsp_printf("EV dl hint: geometry/override W/H read as 0 (ZERO_SIZE) -> geometry table suspect\r\n");
    56e0:	00006537          	lui	a0,0x6
    56e4:	5d450513          	addi	a0,a0,1492 # 65d4 <_data+0x7d4>
    56e8:	809ff0ef          	jal	4ef0 <bsp_printf>
    56ec:	f6dff06f          	j	5658 <dl_err_report+0x118>

000056f0 <dl_pixel_probe>:
    if (!g_dl_probe_px) return 1;
    56f0:	8701a783          	lw	a5,-1936(gp) # 7968 <g_dl_probe_px>
    56f4:	04078a63          	beqz	a5,5748 <dl_pixel_probe+0x58>
    px = *(volatile uint16_t *)g_dl_probe_px;
    56f8:	0007d583          	lhu	a1,0(a5)
    56fc:	01059593          	slli	a1,a1,0x10
    5700:	0105d593          	srli	a1,a1,0x10
    g_dl_probe_px = 0;
    5704:	8601a823          	sw	zero,-1936(gp) # 7968 <g_dl_probe_px>
    if (px == (uint16_t)COL_BG) {
    5708:	00800793          	li	a5,8
    570c:	00f58663          	beq	a1,a5,5718 <dl_pixel_probe+0x28>
    return 1;
    5710:	00100513          	li	a0,1
}
    5714:	00008067          	ret
{
    5718:	ff010113          	addi	sp,sp,-16
    571c:	00112623          	sw	ra,12(sp)
        bsp_printf("EV dl 1st list drew NOTHING at blk0 sprite centre (px=%x = bg)\r\n",
    5720:	00006537          	lui	a0,0x6
    5724:	67c50513          	addi	a0,a0,1660 # 667c <_data+0x87c>
    5728:	fc8ff0ef          	jal	4ef0 <bsp_printf>
        bsp_printf("EV dl hint: table ran but produced no pixels -> geometry/DFU path suspect\r\n");
    572c:	00006537          	lui	a0,0x6
    5730:	6c050513          	addi	a0,a0,1728 # 66c0 <_data+0x8c0>
    5734:	fbcff0ef          	jal	4ef0 <bsp_printf>
        return 0;
    5738:	00000513          	li	a0,0
}
    573c:	00c12083          	lw	ra,12(sp)
    5740:	01010113          	addi	sp,sp,16
    5744:	00008067          	ret
    if (!g_dl_probe_px) return 1;
    5748:	00100513          	li	a0,1
    574c:	00008067          	ret

00005750 <dl_wd_summary>:
{
    5750:	ff010113          	addi	sp,sp,-16
    5754:	00112623          	sw	ra,12(sp)
    5758:	00050713          	mv	a4,a0
    bsp_printf("EV dl disabled after %d watchdog events (ok=%d bad=%d): %s; descriptor fetch %s; press l to re-arm\r\n",
    575c:	8541a583          	lw	a1,-1964(gp) # 794c <g_dl_wd_events>
    5760:	85c1a603          	lw	a2,-1956(gp) # 7954 <g_dl_retry_ok>
    5764:	8581a683          	lw	a3,-1960(gp) # 7950 <g_dl_retry_bad>
               g_dl_stall_seen ? "starved (stall_seen=1)"
    5768:	86c1a783          	lw	a5,-1940(gp) # 7964 <g_dl_stall_seen>
    bsp_printf("EV dl disabled after %d watchdog events (ok=%d bad=%d): %s; descriptor fetch %s; press l to re-arm\r\n",
    576c:	02078263          	beqz	a5,5790 <dl_wd_summary+0x40>
    5770:	000067b7          	lui	a5,0x6
    5774:	70c78793          	addi	a5,a5,1804 # 670c <_data+0x90c>
    5778:	00006537          	lui	a0,0x6
    577c:	74450513          	addi	a0,a0,1860 # 6744 <_data+0x944>
    5780:	f70ff0ef          	jal	4ef0 <bsp_printf>
}
    5784:	00c12083          	lw	ra,12(sp)
    5788:	01010113          	addi	sp,sp,16
    578c:	00008067          	ret
    bsp_printf("EV dl disabled after %d watchdog events (ok=%d bad=%d): %s; descriptor fetch %s; press l to re-arm\r\n",
    5790:	000067b7          	lui	a5,0x6
    5794:	72478793          	addi	a5,a5,1828 # 6724 <_data+0x924>
    5798:	fe1ff06f          	j	5778 <dl_wd_summary+0x28>

0000579c <dl_disable>:
{
    579c:	fe010113          	addi	sp,sp,-32
    57a0:	00112e23          	sw	ra,28(sp)
    57a4:	00812c23          	sw	s0,24(sp)
    57a8:	00912a23          	sw	s1,20(sp)
    57ac:	01212823          	sw	s2,16(sp)
    57b0:	01312623          	sw	s3,12(sp)
    57b4:	00050593          	mv	a1,a0
    bsp_printf("EV list path OFF (%s), fallback to per-command (key l re-arms)\r\n", why);
    57b8:	00006537          	lui	a0,0x6
    57bc:	7ac50513          	addi	a0,a0,1964 # 67ac <_data+0x9ac>
    57c0:	f30ff0ef          	jal	4ef0 <bsp_printf>
               (unsigned)blt_rd(BLT_DL_GEOM_BASE), (int)(blt_rd(BLT_DL_GEOM_MAX) & 0xFFFFu),
    57c4:	06800513          	li	a0,104
    57c8:	f90fd0ef          	jal	2f58 <blt_rd>
    57cc:	00050413          	mv	s0,a0
    57d0:	06c00513          	li	a0,108
    57d4:	f84fd0ef          	jal	2f58 <blt_rd>
    57d8:	00050493          	mv	s1,a0
               (int)(blt_rd(BLT_DL_DST_STRIDE) & 0xFFFFu),
    57dc:	08400513          	li	a0,132
    57e0:	f78fd0ef          	jal	2f58 <blt_rd>
    57e4:	00050913          	mv	s2,a0
               (int)(blt_rd(BLT_DL_FB_WH) & 0xFFFFu), (int)(blt_rd(BLT_DL_FB_WH) >> 16));
    57e8:	08800513          	li	a0,136
    57ec:	f6cfd0ef          	jal	2f58 <blt_rd>
    57f0:	00050993          	mv	s3,a0
    57f4:	08800513          	li	a0,136
    57f8:	f60fd0ef          	jal	2f58 <blt_rd>
    bsp_printf("EV dl cfg readback: GEOM_BASE=%x GEOM_MAX=%d DST_STRIDE=%d FB_WH=%dx%d\r\n",
    57fc:	00010637          	lui	a2,0x10
    5800:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f07>
    5804:	01055793          	srli	a5,a0,0x10
    5808:	00c9f733          	and	a4,s3,a2
    580c:	00c976b3          	and	a3,s2,a2
    5810:	00c4f633          	and	a2,s1,a2
    5814:	00040593          	mv	a1,s0
    5818:	00006537          	lui	a0,0x6
    581c:	7f050513          	addi	a0,a0,2032 # 67f0 <_data+0x9f0>
    5820:	ed0ff0ef          	jal	4ef0 <bsp_printf>
    blt_wr(BLT_DL_ERR, DL_ERR_CLR_ALL);          /* W1C，否则 ERR 一直挂着 */
    5824:	010005b7          	lui	a1,0x1000
    5828:	0ff58593          	addi	a1,a1,255 # 10000ff <__freertos_irq_stack_top+0xfbcd5f>
    582c:	06000513          	li	a0,96
    5830:	f18fd0ef          	jal	2f48 <blt_wr>
    g_dl_mode  = 0;
    5834:	8801aa23          	sw	zero,-1900(gp) # 798c <g_dl_mode>
    g_dl_armed = 0;                              /* 下次 'l' 重新走一遍 dl_arm() */
    5838:	8801a823          	sw	zero,-1904(gp) # 7988 <g_dl_armed>
    g_dl_want  = -1;                             /* 出错即撤销待生效请求：要再试请重新按 'l' */
    583c:	fff00713          	li	a4,-1
    5840:	80e1a823          	sw	a4,-2032(gp) # 7908 <g_dl_want>
    g_dl_probe_px = 0;
    5844:	8601a823          	sw	zero,-1936(gp) # 7968 <g_dl_probe_px>
    g_dl_retry_n = 0; g_dl_retry_pend = 0;
    5848:	8601a223          	sw	zero,-1948(gp) # 795c <g_dl_retry_n>
    584c:	8601a023          	sw	zero,-1952(gp) # 7958 <g_dl_retry_pend>
    g_dl_postmortem = 0;
    5850:	8601a423          	sw	zero,-1944(gp) # 7960 <g_dl_postmortem>
}
    5854:	01c12083          	lw	ra,28(sp)
    5858:	01812403          	lw	s0,24(sp)
    585c:	01412483          	lw	s1,20(sp)
    5860:	01012903          	lw	s2,16(sp)
    5864:	00c12983          	lw	s3,12(sp)
    5868:	02010113          	addi	sp,sp,32
    586c:	00008067          	ret

00005870 <dl_cost_report>:
{
    5870:	ff010113          	addi	sp,sp,-16
    5874:	00112623          	sw	ra,12(sp)
    5878:	00812423          	sw	s0,8(sp)
    587c:	00050413          	mv	s0,a0
    uint32_t now = tick32();
    5880:	eacfd0ef          	jal	2f2c <tick32>
    if ((uint32_t)(now - g_dl_cost_t0) < DL_COST_TICKS) return;   /* 1s 内最多一行 */
    5884:	84c1a703          	lw	a4,-1972(gp) # 7944 <g_dl_cost_t0>
    5888:	40e50733          	sub	a4,a0,a4
    588c:	05f5e7b7          	lui	a5,0x5f5e
    5890:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f1ad5f>
    5894:	00e7ea63          	bltu	a5,a4,58a8 <dl_cost_report+0x38>
}
    5898:	00c12083          	lw	ra,12(sp)
    589c:	00812403          	lw	s0,8(sp)
    58a0:	01010113          	addi	sp,sp,16
    58a4:	00008067          	ret
    g_dl_cost_t0 = now;
    58a8:	84a1a623          	sw	a0,-1972(gp) # 7944 <g_dl_cost_t0>
    perf = (int)blt_rd(BLT_DL_PERF);
    58ac:	07c00513          	li	a0,124
    58b0:	ea8fd0ef          	jal	2f58 <blt_rd>
    58b4:	00050613          	mv	a2,a0
    bsp_printf("EV dl list done: n=%d cycles=%d cyc/sprite=%d\r\n",
    58b8:	00805e63          	blez	s0,58d4 <dl_cost_report+0x64>
    58bc:	028546b3          	div	a3,a0,s0
    58c0:	00040593          	mv	a1,s0
    58c4:	00007537          	lui	a0,0x7
    58c8:	83c50513          	addi	a0,a0,-1988 # 683c <_data+0xa3c>
    58cc:	e24ff0ef          	jal	4ef0 <bsp_printf>
    58d0:	fc9ff06f          	j	5898 <dl_cost_report+0x28>
    58d4:	00000693          	li	a3,0
    58d8:	fe9ff06f          	j	58c0 <dl_cost_report+0x50>

000058dc <cmd_cost_report>:
    if (!g_cmd_t0) return;                       /* 本趟没计时（例如这一趟是列表路径发的） */
    58dc:	83c1a783          	lw	a5,-1988(gp) # 7934 <g_cmd_t0>
    58e0:	00079463          	bnez	a5,58e8 <cmd_cost_report+0xc>
    58e4:	00008067          	ret
{
    58e8:	ff010113          	addi	sp,sp,-16
    58ec:	00112623          	sw	ra,12(sp)
    58f0:	00812423          	sw	s0,8(sp)
    58f4:	00050413          	mv	s0,a0
    now = tick32();
    58f8:	e34fd0ef          	jal	2f2c <tick32>
    dt  = (uint32_t)(now - g_cmd_t0);
    58fc:	83c1a603          	lw	a2,-1988(gp) # 7934 <g_cmd_t0>
    5900:	40c50633          	sub	a2,a0,a2
    g_cmd_t0 = 0;
    5904:	8201ae23          	sw	zero,-1988(gp) # 7934 <g_cmd_t0>
    if ((uint32_t)(now - g_cmd_cost_t0) < DL_COST_TICKS) return;   /* 1s 内最多一行 */
    5908:	8481a683          	lw	a3,-1976(gp) # 7940 <g_cmd_cost_t0>
    590c:	40d506b3          	sub	a3,a0,a3
    5910:	05f5e737          	lui	a4,0x5f5e
    5914:	0ff70713          	addi	a4,a4,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f1ad5f>
    5918:	02d77063          	bgeu	a4,a3,5938 <cmd_cost_report+0x5c>
    g_cmd_cost_t0 = now;
    591c:	84a1a423          	sw	a0,-1976(gp) # 7940 <g_cmd_cost_t0>
    bsp_printf("EV cmd path done: n=%d cycles=%d cyc/sprite=%d\r\n",
    5920:	02805463          	blez	s0,5948 <cmd_cost_report+0x6c>
    5924:	028646b3          	div	a3,a2,s0
    5928:	00040593          	mv	a1,s0
    592c:	00007537          	lui	a0,0x7
    5930:	86c50513          	addi	a0,a0,-1940 # 686c <_data+0xa6c>
    5934:	dbcff0ef          	jal	4ef0 <bsp_printf>
}
    5938:	00c12083          	lw	ra,12(sp)
    593c:	00812403          	lw	s0,8(sp)
    5940:	01010113          	addi	sp,sp,16
    5944:	00008067          	ret
    bsp_printf("EV cmd path done: n=%d cycles=%d cyc/sprite=%d\r\n",
    5948:	00000693          	li	a3,0
    594c:	fddff06f          	j	5928 <cmd_cost_report+0x4c>

00005950 <__udivdi3>:
    5950:	00060813          	mv	a6,a2
    5954:	00050893          	mv	a7,a0
    5958:	00058713          	mv	a4,a1
    595c:	0e069063          	bnez	a3,5a3c <__udivdi3+0xec>
    5960:	12c5fe63          	bgeu	a1,a2,5a9c <__udivdi3+0x14c>
    5964:	000107b7          	lui	a5,0x10
    5968:	1ef66e63          	bltu	a2,a5,5b64 <__udivdi3+0x214>
    596c:	010007b7          	lui	a5,0x1000
    5970:	01800693          	li	a3,24
    5974:	00f67463          	bgeu	a2,a5,597c <__udivdi3+0x2c>
    5978:	01000693          	li	a3,16
    597c:	00d65333          	srl	t1,a2,a3
    5980:	00002797          	auipc	a5,0x2
    5984:	e8878793          	addi	a5,a5,-376 # 7808 <__clz_tab>
    5988:	006787b3          	add	a5,a5,t1
    598c:	0007c783          	lbu	a5,0(a5)
    5990:	02000313          	li	t1,32
    5994:	00d787b3          	add	a5,a5,a3
    5998:	40f306b3          	sub	a3,t1,a5
    599c:	00f30c63          	beq	t1,a5,59b4 <__udivdi3+0x64>
    59a0:	00d59733          	sll	a4,a1,a3
    59a4:	00f557b3          	srl	a5,a0,a5
    59a8:	00d61833          	sll	a6,a2,a3
    59ac:	00e7e733          	or	a4,a5,a4
    59b0:	00d518b3          	sll	a7,a0,a3
    59b4:	01085613          	srli	a2,a6,0x10
    59b8:	02c75533          	divu	a0,a4,a2
    59bc:	01081693          	slli	a3,a6,0x10
    59c0:	0106d693          	srli	a3,a3,0x10
    59c4:	0108d793          	srli	a5,a7,0x10
    59c8:	02c77733          	remu	a4,a4,a2
    59cc:	02a685b3          	mul	a1,a3,a0
    59d0:	01071713          	slli	a4,a4,0x10
    59d4:	00e7e7b3          	or	a5,a5,a4
    59d8:	00b7fc63          	bgeu	a5,a1,59f0 <__udivdi3+0xa0>
    59dc:	00f807b3          	add	a5,a6,a5
    59e0:	fff50713          	addi	a4,a0,-1
    59e4:	0107e463          	bltu	a5,a6,59ec <__udivdi3+0x9c>
    59e8:	40b7e063          	bltu	a5,a1,5de8 <__udivdi3+0x498>
    59ec:	00070513          	mv	a0,a4
    59f0:	40b787b3          	sub	a5,a5,a1
    59f4:	02c7d733          	divu	a4,a5,a2
    59f8:	01089893          	slli	a7,a7,0x10
    59fc:	0108d893          	srli	a7,a7,0x10
    5a00:	02c7f7b3          	remu	a5,a5,a2
    5a04:	02e686b3          	mul	a3,a3,a4
    5a08:	01079793          	slli	a5,a5,0x10
    5a0c:	00f8e8b3          	or	a7,a7,a5
    5a10:	00d8fe63          	bgeu	a7,a3,5a2c <__udivdi3+0xdc>
    5a14:	011808b3          	add	a7,a6,a7
    5a18:	fff70793          	addi	a5,a4,-1
    5a1c:	0108e663          	bltu	a7,a6,5a28 <__udivdi3+0xd8>
    5a20:	ffe70713          	addi	a4,a4,-2
    5a24:	00d8e463          	bltu	a7,a3,5a2c <__udivdi3+0xdc>
    5a28:	00078713          	mv	a4,a5
    5a2c:	01051513          	slli	a0,a0,0x10
    5a30:	00e56533          	or	a0,a0,a4
    5a34:	00000593          	li	a1,0
    5a38:	00008067          	ret
    5a3c:	00d5f863          	bgeu	a1,a3,5a4c <__udivdi3+0xfc>
    5a40:	00000593          	li	a1,0
    5a44:	00000513          	li	a0,0
    5a48:	00008067          	ret
    5a4c:	000107b7          	lui	a5,0x10
    5a50:	1ef6e863          	bltu	a3,a5,5c40 <__udivdi3+0x2f0>
    5a54:	01000737          	lui	a4,0x1000
    5a58:	01800793          	li	a5,24
    5a5c:	00e6f463          	bgeu	a3,a4,5a64 <__udivdi3+0x114>
    5a60:	01000793          	li	a5,16
    5a64:	00f6d833          	srl	a6,a3,a5
    5a68:	00002717          	auipc	a4,0x2
    5a6c:	da070713          	addi	a4,a4,-608 # 7808 <__clz_tab>
    5a70:	01070733          	add	a4,a4,a6
    5a74:	00074703          	lbu	a4,0(a4)
    5a78:	02000893          	li	a7,32
    5a7c:	00f70733          	add	a4,a4,a5
    5a80:	40e88833          	sub	a6,a7,a4
    5a84:	1ee89663          	bne	a7,a4,5c70 <__udivdi3+0x320>
    5a88:	32b6e463          	bltu	a3,a1,5db0 <__udivdi3+0x460>
    5a8c:	00c53533          	sltu	a0,a0,a2
    5a90:	00153513          	seqz	a0,a0
    5a94:	00000593          	li	a1,0
    5a98:	00008067          	ret
    5a9c:	0c060c63          	beqz	a2,5b74 <__udivdi3+0x224>
    5aa0:	000107b7          	lui	a5,0x10
    5aa4:	2ef67c63          	bgeu	a2,a5,5d9c <__udivdi3+0x44c>
    5aa8:	10063713          	sltiu	a4,a2,256
    5aac:	00173713          	seqz	a4,a4
    5ab0:	00371713          	slli	a4,a4,0x3
    5ab4:	00e656b3          	srl	a3,a2,a4
    5ab8:	00002797          	auipc	a5,0x2
    5abc:	d5078793          	addi	a5,a5,-688 # 7808 <__clz_tab>
    5ac0:	00d787b3          	add	a5,a5,a3
    5ac4:	0007c783          	lbu	a5,0(a5)
    5ac8:	02000693          	li	a3,32
    5acc:	00e787b3          	add	a5,a5,a4
    5ad0:	40f68eb3          	sub	t4,a3,a5
    5ad4:	0cf69463          	bne	a3,a5,5b9c <__udivdi3+0x24c>
    5ad8:	40c587b3          	sub	a5,a1,a2
    5adc:	01065693          	srli	a3,a2,0x10
    5ae0:	01061613          	slli	a2,a2,0x10
    5ae4:	01065613          	srli	a2,a2,0x10
    5ae8:	00100593          	li	a1,1
    5aec:	02d7d533          	divu	a0,a5,a3
    5af0:	0108d713          	srli	a4,a7,0x10
    5af4:	02d7f7b3          	remu	a5,a5,a3
    5af8:	02c50333          	mul	t1,a0,a2
    5afc:	01079793          	slli	a5,a5,0x10
    5b00:	00f767b3          	or	a5,a4,a5
    5b04:	0067fc63          	bgeu	a5,t1,5b1c <__udivdi3+0x1cc>
    5b08:	00f807b3          	add	a5,a6,a5
    5b0c:	fff50713          	addi	a4,a0,-1
    5b10:	0107e463          	bltu	a5,a6,5b18 <__udivdi3+0x1c8>
    5b14:	2c67e463          	bltu	a5,t1,5ddc <__udivdi3+0x48c>
    5b18:	00070513          	mv	a0,a4
    5b1c:	406787b3          	sub	a5,a5,t1
    5b20:	02d7d733          	divu	a4,a5,a3
    5b24:	01089893          	slli	a7,a7,0x10
    5b28:	0108d893          	srli	a7,a7,0x10
    5b2c:	02d7f7b3          	remu	a5,a5,a3
    5b30:	02c70633          	mul	a2,a4,a2
    5b34:	01079793          	slli	a5,a5,0x10
    5b38:	00f8e8b3          	or	a7,a7,a5
    5b3c:	00c8fe63          	bgeu	a7,a2,5b58 <__udivdi3+0x208>
    5b40:	011808b3          	add	a7,a6,a7
    5b44:	fff70793          	addi	a5,a4,-1
    5b48:	0108e663          	bltu	a7,a6,5b54 <__udivdi3+0x204>
    5b4c:	ffe70713          	addi	a4,a4,-2
    5b50:	00c8e463          	bltu	a7,a2,5b58 <__udivdi3+0x208>
    5b54:	00078713          	mv	a4,a5
    5b58:	01051513          	slli	a0,a0,0x10
    5b5c:	00e56533          	or	a0,a0,a4
    5b60:	00008067          	ret
    5b64:	10063693          	sltiu	a3,a2,256
    5b68:	0016b693          	seqz	a3,a3
    5b6c:	00369693          	slli	a3,a3,0x3
    5b70:	e0dff06f          	j	597c <__udivdi3+0x2c>
    5b74:	00000693          	li	a3,0
    5b78:	00002797          	auipc	a5,0x2
    5b7c:	c9078793          	addi	a5,a5,-880 # 7808 <__clz_tab>
    5b80:	00d787b3          	add	a5,a5,a3
    5b84:	0007c783          	lbu	a5,0(a5)
    5b88:	00000713          	li	a4,0
    5b8c:	02000693          	li	a3,32
    5b90:	00e787b3          	add	a5,a5,a4
    5b94:	40f68eb3          	sub	t4,a3,a5
    5b98:	f4f680e3          	beq	a3,a5,5ad8 <__udivdi3+0x188>
    5b9c:	01d61833          	sll	a6,a2,t4
    5ba0:	00f5d333          	srl	t1,a1,a5
    5ba4:	01085693          	srli	a3,a6,0x10
    5ba8:	02d35e33          	divu	t3,t1,a3
    5bac:	01081613          	slli	a2,a6,0x10
    5bb0:	01d595b3          	sll	a1,a1,t4
    5bb4:	01065613          	srli	a2,a2,0x10
    5bb8:	00f557b3          	srl	a5,a0,a5
    5bbc:	00b7e7b3          	or	a5,a5,a1
    5bc0:	0107d713          	srli	a4,a5,0x10
    5bc4:	01d518b3          	sll	a7,a0,t4
    5bc8:	02d37333          	remu	t1,t1,a3
    5bcc:	03c605b3          	mul	a1,a2,t3
    5bd0:	01031313          	slli	t1,t1,0x10
    5bd4:	00676733          	or	a4,a4,t1
    5bd8:	00b77e63          	bgeu	a4,a1,5bf4 <__udivdi3+0x2a4>
    5bdc:	00e80733          	add	a4,a6,a4
    5be0:	fffe0513          	addi	a0,t3,-1
    5be4:	1f076463          	bltu	a4,a6,5dcc <__udivdi3+0x47c>
    5be8:	1eb77263          	bgeu	a4,a1,5dcc <__udivdi3+0x47c>
    5bec:	ffee0e13          	addi	t3,t3,-2
    5bf0:	01070733          	add	a4,a4,a6
    5bf4:	40b70733          	sub	a4,a4,a1
    5bf8:	02d75533          	divu	a0,a4,a3
    5bfc:	01079793          	slli	a5,a5,0x10
    5c00:	0107d793          	srli	a5,a5,0x10
    5c04:	02d77733          	remu	a4,a4,a3
    5c08:	02a60333          	mul	t1,a2,a0
    5c0c:	01071713          	slli	a4,a4,0x10
    5c10:	00e7e7b3          	or	a5,a5,a4
    5c14:	0067fe63          	bgeu	a5,t1,5c30 <__udivdi3+0x2e0>
    5c18:	00f807b3          	add	a5,a6,a5
    5c1c:	fff50713          	addi	a4,a0,-1
    5c20:	1907ee63          	bltu	a5,a6,5dbc <__udivdi3+0x46c>
    5c24:	1867fc63          	bgeu	a5,t1,5dbc <__udivdi3+0x46c>
    5c28:	ffe50513          	addi	a0,a0,-2
    5c2c:	010787b3          	add	a5,a5,a6
    5c30:	010e1593          	slli	a1,t3,0x10
    5c34:	406787b3          	sub	a5,a5,t1
    5c38:	00a5e5b3          	or	a1,a1,a0
    5c3c:	eb1ff06f          	j	5aec <__udivdi3+0x19c>
    5c40:	1006b793          	sltiu	a5,a3,256
    5c44:	0017b793          	seqz	a5,a5
    5c48:	00379793          	slli	a5,a5,0x3
    5c4c:	00f6d833          	srl	a6,a3,a5
    5c50:	00002717          	auipc	a4,0x2
    5c54:	bb870713          	addi	a4,a4,-1096 # 7808 <__clz_tab>
    5c58:	01070733          	add	a4,a4,a6
    5c5c:	00074703          	lbu	a4,0(a4)
    5c60:	02000893          	li	a7,32
    5c64:	00f70733          	add	a4,a4,a5
    5c68:	40e88833          	sub	a6,a7,a4
    5c6c:	e0e88ee3          	beq	a7,a4,5a88 <__udivdi3+0x138>
    5c70:	00e65e33          	srl	t3,a2,a4
    5c74:	010696b3          	sll	a3,a3,a6
    5c78:	00de6e33          	or	t3,t3,a3
    5c7c:	00e5d8b3          	srl	a7,a1,a4
    5c80:	010e5e93          	srli	t4,t3,0x10
    5c84:	03d8d7b3          	divu	a5,a7,t4
    5c88:	010e1313          	slli	t1,t3,0x10
    5c8c:	010595b3          	sll	a1,a1,a6
    5c90:	01035313          	srli	t1,t1,0x10
    5c94:	00e55733          	srl	a4,a0,a4
    5c98:	00b76733          	or	a4,a4,a1
    5c9c:	01075693          	srli	a3,a4,0x10
    5ca0:	01061633          	sll	a2,a2,a6
    5ca4:	03d8f8b3          	remu	a7,a7,t4
    5ca8:	02f305b3          	mul	a1,t1,a5
    5cac:	01089893          	slli	a7,a7,0x10
    5cb0:	0116e6b3          	or	a3,a3,a7
    5cb4:	00b6fe63          	bgeu	a3,a1,5cd0 <__udivdi3+0x380>
    5cb8:	00de06b3          	add	a3,t3,a3
    5cbc:	fff78893          	addi	a7,a5,-1
    5cc0:	11c6ea63          	bltu	a3,t3,5dd4 <__udivdi3+0x484>
    5cc4:	10b6f863          	bgeu	a3,a1,5dd4 <__udivdi3+0x484>
    5cc8:	ffe78793          	addi	a5,a5,-2
    5ccc:	01c686b3          	add	a3,a3,t3
    5cd0:	40b686b3          	sub	a3,a3,a1
    5cd4:	03d6d5b3          	divu	a1,a3,t4
    5cd8:	01071713          	slli	a4,a4,0x10
    5cdc:	01075713          	srli	a4,a4,0x10
    5ce0:	03d6f6b3          	remu	a3,a3,t4
    5ce4:	02b308b3          	mul	a7,t1,a1
    5ce8:	01069693          	slli	a3,a3,0x10
    5cec:	00d76733          	or	a4,a4,a3
    5cf0:	01177e63          	bgeu	a4,a7,5d0c <__udivdi3+0x3bc>
    5cf4:	00ee0733          	add	a4,t3,a4
    5cf8:	fff58693          	addi	a3,a1,-1
    5cfc:	0dc76463          	bltu	a4,t3,5dc4 <__udivdi3+0x474>
    5d00:	0d177263          	bgeu	a4,a7,5dc4 <__udivdi3+0x474>
    5d04:	ffe58593          	addi	a1,a1,-2
    5d08:	01c70733          	add	a4,a4,t3
    5d0c:	01079793          	slli	a5,a5,0x10
    5d10:	00010eb7          	lui	t4,0x10
    5d14:	00b7e7b3          	or	a5,a5,a1
    5d18:	fffe8693          	addi	a3,t4,-1 # ffff <__global_pointer$+0x7f07>
    5d1c:	00d7f5b3          	and	a1,a5,a3
    5d20:	0107d313          	srli	t1,a5,0x10
    5d24:	00d676b3          	and	a3,a2,a3
    5d28:	01065613          	srli	a2,a2,0x10
    5d2c:	02d58e33          	mul	t3,a1,a3
    5d30:	41170733          	sub	a4,a4,a7
    5d34:	02d306b3          	mul	a3,t1,a3
    5d38:	010e5893          	srli	a7,t3,0x10
    5d3c:	02c585b3          	mul	a1,a1,a2
    5d40:	00d585b3          	add	a1,a1,a3
    5d44:	00b885b3          	add	a1,a7,a1
    5d48:	02c30333          	mul	t1,t1,a2
    5d4c:	00d5f463          	bgeu	a1,a3,5d54 <__udivdi3+0x404>
    5d50:	01d30333          	add	t1,t1,t4
    5d54:	0105d693          	srli	a3,a1,0x10
    5d58:	006686b3          	add	a3,a3,t1
    5d5c:	02d76a63          	bltu	a4,a3,5d90 <__udivdi3+0x440>
    5d60:	00d70863          	beq	a4,a3,5d70 <__udivdi3+0x420>
    5d64:	00078513          	mv	a0,a5
    5d68:	00000593          	li	a1,0
    5d6c:	00008067          	ret
    5d70:	000106b7          	lui	a3,0x10
    5d74:	fff68693          	addi	a3,a3,-1 # ffff <__global_pointer$+0x7f07>
    5d78:	00d5f733          	and	a4,a1,a3
    5d7c:	01071713          	slli	a4,a4,0x10
    5d80:	00de7e33          	and	t3,t3,a3
    5d84:	01051533          	sll	a0,a0,a6
    5d88:	01c70733          	add	a4,a4,t3
    5d8c:	fce57ce3          	bgeu	a0,a4,5d64 <__udivdi3+0x414>
    5d90:	fff78513          	addi	a0,a5,-1
    5d94:	00000593          	li	a1,0
    5d98:	00008067          	ret
    5d9c:	010007b7          	lui	a5,0x1000
    5da0:	04f67a63          	bgeu	a2,a5,5df4 <__udivdi3+0x4a4>
    5da4:	01065693          	srli	a3,a2,0x10
    5da8:	01000713          	li	a4,16
    5dac:	d0dff06f          	j	5ab8 <__udivdi3+0x168>
    5db0:	00000593          	li	a1,0
    5db4:	00100513          	li	a0,1
    5db8:	00008067          	ret
    5dbc:	00070513          	mv	a0,a4
    5dc0:	e71ff06f          	j	5c30 <__udivdi3+0x2e0>
    5dc4:	00068593          	mv	a1,a3
    5dc8:	f45ff06f          	j	5d0c <__udivdi3+0x3bc>
    5dcc:	00050e13          	mv	t3,a0
    5dd0:	e25ff06f          	j	5bf4 <__udivdi3+0x2a4>
    5dd4:	00088793          	mv	a5,a7
    5dd8:	ef9ff06f          	j	5cd0 <__udivdi3+0x380>
    5ddc:	ffe50513          	addi	a0,a0,-2
    5de0:	010787b3          	add	a5,a5,a6
    5de4:	d39ff06f          	j	5b1c <__udivdi3+0x1cc>
    5de8:	ffe50513          	addi	a0,a0,-2
    5dec:	010787b3          	add	a5,a5,a6
    5df0:	c01ff06f          	j	59f0 <__udivdi3+0xa0>
    5df4:	01865693          	srli	a3,a2,0x18
    5df8:	01800713          	li	a4,24
    5dfc:	cbdff06f          	j	5ab8 <__udivdi3+0x168>
