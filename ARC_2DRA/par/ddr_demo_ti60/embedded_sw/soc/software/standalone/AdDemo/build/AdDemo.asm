
build/AdDemo.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00007197          	auipc	gp,0x7
    1004:	02818193          	addi	gp,gp,40 # 8028 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	0001c117          	auipc	sp,0x1c
    100c:	22810113          	addi	sp,sp,552 # 1d230 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00005517          	auipc	a0,0x5
    1014:	fa450513          	addi	a0,a0,-92 # 5fb4 <_data>
	la a1, _data
    1018:	00005597          	auipc	a1,0x5
    101c:	f9c58593          	addi	a1,a1,-100 # 5fb4 <_data>
	la a2, _edata
    1020:	00007617          	auipc	a2,0x7
    1024:	87460613          	addi	a2,a2,-1932 # 7894 <g_flip_bad>
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
    1044:	85450513          	addi	a0,a0,-1964 # 7894 <g_flip_bad>
	la a1, _end
    1048:	0001b597          	auipc	a1,0x1b
    104c:	1e858593          	addi	a1,a1,488 # 1c230 <_end>
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
    1080:	f3878793          	addi	a5,a5,-200 # 5fb4 <_data>
    1084:	00005417          	auipc	s0,0x5
    1088:	f3040413          	addi	s0,s0,-208 # 5fb4 <_data>
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
    10bc:	efc78793          	addi	a5,a5,-260 # 5fb4 <_data>
    10c0:	00005417          	auipc	s0,0x5
    10c4:	ef440413          	addi	s0,s0,-268 # 5fb4 <_data>
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
               FB_WIDTH - OSD_RIGHT_PX, FB_WIDTH, (len <= OSD_LEFT_CH) ? 1 : 0);
    bsp_printf("osd worst: \"%s\"\r\n", worst);
}

int main(int argc, char **argv)
{
    1104:	fb010113          	addi	sp,sp,-80
    1108:	04112623          	sw	ra,76(sp)
    110c:	04812423          	sw	s0,72(sp)
    1110:	04912223          	sw	s1,68(sp)
    1114:	05212023          	sw	s2,64(sp)
    1118:	03312e23          	sw	s3,60(sp)
    111c:	03412c23          	sw	s4,56(sp)
    1120:	03512a23          	sw	s5,52(sp)
    1124:	03612823          	sw	s6,48(sp)
    uint32_t t_now, t_scene;
    int      n_cmd = N_MIN;
    1128:	01000793          	li	a5,16
    112c:	02f12623          	sw	a5,44(sp)
    int      pend_adv = 0;
    int      size_repaint = 0;

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */
    1130:	1b0010ef          	jal	22e0 <bsp_init>
    banner();
    1134:	0b0030ef          	jal	41e4 <banner>

    blt_init();
    1138:	215010ef          	jal	2b4c <blt_init>
    /* 先与实际在屏的缓冲对齐（不假设复位值），再定三缓冲轮转初值 */
    g_disp_sel = (int)fb_stat_sel();
    113c:	710010ef          	jal	284c <fb_stat_sel>
    1140:	00050413          	mv	s0,a0
    1144:	96a1ac23          	sw	a0,-1672(gp) # 79a0 <g_disp_sel>
    g_draw3    = (int)(((uint32_t)g_disp_sel + 1u) % 3u);
    1148:	00150513          	addi	a0,a0,1
    114c:	00300713          	li	a4,3
    1150:	02e57533          	remu	a0,a0,a4
    1154:	84a1aa23          	sw	a0,-1964(gp) # 787c <g_draw3>
    g_clr3     = (int)(((uint32_t)g_disp_sel + 2u) % 3u);
    1158:	00240793          	addi	a5,s0,2
    115c:	02e7f7b3          	remu	a5,a5,a4
    1160:	84f1a823          	sw	a5,-1968(gp) # 7878 <g_clr3>
    g_clr_need = 1;
    1164:	00100713          	li	a4,1
    1168:	96e1a623          	sw	a4,-1684(gp) # 7994 <g_clr_need>
    g_pass_armed = 0;
    116c:	9601a423          	sw	zero,-1688(gp) # 7990 <g_pass_armed>
    g_fb_back  = fb_of_sel((uint32_t)g_draw3);
    1170:	6b4010ef          	jal	2824 <fb_of_sel>
    1174:	84a1ac23          	sw	a0,-1960(gp) # 7880 <g_fb_back>
    g_flip_req = (uint32_t)g_disp_sel;
    1178:	9681aa23          	sw	s0,-1676(gp) # 799c <g_flip_req>

    feat_probe();
    117c:	580040ef          	jal	56fc <feat_probe>
    align_selfcheck();
    1180:	314030ef          	jal	4494 <align_selfcheck>
    attr_selfcheck();
    1184:	368030ef          	jal	44ec <attr_selfcheck>
    argb_selfcheck();
    1188:	45c030ef          	jal	45e4 <argb_selfcheck>
    build_atlas();
    118c:	2ec040ef          	jal	5478 <build_atlas>
    build_bg();
    1190:	5d8030ef          	jal	4768 <build_bg>
    cache_evict();
    1194:	11d010ef          	jal	2ab0 <cache_evict>

    /* ★ 开机自检行也把 SCAN_DBG 解出来（与每秒的 EV diag 行同一组宏、同一口径）：
     *   SCAN=00070108 ⇒ ab=7 un=264 —— 上板第一眼就能看到扫描输出是否已经在报错。 */
    {
        uint32_t scan0 = blt_rd(BLT_SCAN_DBG);
    1198:	02000513          	li	a0,32
    119c:	678010ef          	jal	2814 <blt_rd>
    11a0:	00050413          	mv	s0,a0
        bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x ab=%d un=%d FB=%x\r\n",
                   (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)scan0,
    11a4:	161010ef          	jal	2b04 <blt_stat>
    11a8:	00050493          	mv	s1,a0
    11ac:	13d010ef          	jal	2ae8 <blt_cnt>
    11b0:	00050913          	mv	s2,a0
                   (int)BLT_SCAN_ABORT(scan0), (int)BLT_SCAN_UNDERRUN(scan0),
    11b4:	01045993          	srli	s3,s0,0x10
                   (unsigned)blt_rd(BLT_FB_STAT));
    11b8:	02800513          	li	a0,40
    11bc:	658010ef          	jal	2814 <blt_rd>
        bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x ab=%d un=%d FB=%x\r\n",
    11c0:	00050813          	mv	a6,a0
    11c4:	01041793          	slli	a5,s0,0x10
    11c8:	0107d793          	srli	a5,a5,0x10
    11cc:	00098713          	mv	a4,s3
    11d0:	00040693          	mv	a3,s0
    11d4:	00090613          	mv	a2,s2
    11d8:	00048593          	mv	a1,s1
    11dc:	00007537          	lui	a0,0x7
    11e0:	d3450513          	addi	a0,a0,-716 # 6d34 <_data+0xd80>
    11e4:	6d1020ef          	jal	40b4 <bsp_printf>

    /* 三块缓冲各用**引擎**铺一次底（CPU 一个像素都不写）。
     * 本趟要画的那块（g_fb_back）不铺 —— 信息条随即由段 0 画进去。 */
    {
        int k;
        for (k = 0; k < 3; k++) {
    11e8:	00000413          	li	s0,0
    11ec:	0080006f          	j	11f4 <main+0xf0>
    11f0:	00140413          	addi	s0,s0,1
    11f4:	00200793          	li	a5,2
    11f8:	0487ca63          	blt	a5,s0,124c <main+0x148>
            if (k == g_draw3) continue;
    11fc:	8541a783          	lw	a5,-1964(gp) # 787c <g_draw3>
    1200:	fe8788e3          	beq	a5,s0,11f0 <main+0xec>
            blt_fill(fb_of_sel((uint32_t)k) + (uint32_t)TOP_Y0 * FB_STRIDE, FB_STRIDE,
    1204:	00040513          	mv	a0,s0
    1208:	61c010ef          	jal	2824 <fb_of_sel>
    120c:	00050493          	mv	s1,a0
    1210:	00008537          	lui	a0,0x8
    1214:	80050513          	addi	a0,a0,-2048 # 7800 <__clz_tab+0xc8>
    1218:	00800713          	li	a4,8
    121c:	20c00693          	li	a3,524
    1220:	3c000613          	li	a2,960
    1224:	78000593          	li	a1,1920
    1228:	00a48533          	add	a0,s1,a0
    122c:	7e4030ef          	jal	4a10 <blt_fill>
                     FB_WIDTH, (uint32_t)PLAY_H, COL_BG);
            blt_fill(fb_of_sel((uint32_t)k), FB_STRIDE, FB_WIDTH, (uint32_t)OSD_H, COL_OSD_BG);
    1230:	00000713          	li	a4,0
    1234:	01000693          	li	a3,16
    1238:	3c000613          	li	a2,960
    123c:	78000593          	li	a1,1920
    1240:	00048513          	mv	a0,s1
    1244:	7cc030ef          	jal	4a10 <blt_fill>
    1248:	fa9ff06f          	j	11f0 <main+0xec>
        }
    }
    /* 开 IRQ 帧节拍：翻转确认改由扫描输出的帧边界事件驱动 */
    blt_wr(BLT_IRQ_STATUS, 0xFFFFFFFFu);
    124c:	fff00593          	li	a1,-1
    1250:	01000513          	li	a0,16
    1254:	5b0010ef          	jal	2804 <blt_wr>
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);
    1258:	01400513          	li	a0,20
    125c:	5b8010ef          	jal	2814 <blt_rd>
    1260:	00256593          	ori	a1,a0,2
    1264:	01400513          	li	a0,20
    1268:	59c010ef          	jal	2804 <blt_wr>

    scene_init(g_n, g_seed);
    126c:	8241a583          	lw	a1,-2012(gp) # 784c <g_seed>
    1270:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    1274:	4d1010ef          	jal	2f44 <scene_init>
    t_now = tick32();
    1278:	570010ef          	jal	27e8 <tick32>
    127c:	00050493          	mv	s1,a0
    g_osd_t0 = t_now; t_scene = t_now; g_t_fx0 = t_now;
    1280:	90a1aa23          	sw	a0,-1772(gp) # 793c <g_osd_t0>
    1284:	8ca1a823          	sw	a0,-1840(gp) # 78f8 <g_t_fx0>
    g_diag_t0 = t_now;                 /* ★ EV diag 行从开机起也走 1Hz（与 osd 同一个起点） */
    1288:	86a1aa23          	sw	a0,-1932(gp) # 789c <g_diag_t0>
    g_flash_t0 = t_now; g_flash_ms = FLASH_MS; g_flash_next = t_now + FLASH_REARM_MS * MS_TICKS;
    128c:	8ca1a423          	sw	a0,-1848(gp) # 78f0 <g_flash_t0>
    1290:	0dc00713          	li	a4,220
    1294:	8ce1a623          	sw	a4,-1844(gp) # 78f4 <g_flash_ms>
    1298:	11e1a7b7          	lui	a5,0x11e1a
    129c:	30078793          	addi	a5,a5,768 # 11e1a300 <__freertos_irq_stack_top+0x11dfd0d0>
    12a0:	00f507b3          	add	a5,a0,a5
    12a4:	8cf1a223          	sw	a5,-1852(gp) # 78ec <g_flash_next>
    osd_build(g_n, g_scene, g_alpha, g_frame_adv, g_fx, g_scis_on, g_attr_on, g_auto);
    12a8:	8dc1a883          	lw	a7,-1828(gp) # 7904 <g_auto>
    12ac:	9381a803          	lw	a6,-1736(gp) # 7960 <g_attr_on>
    12b0:	84c1a783          	lw	a5,-1972(gp) # 7874 <g_scis_on>
    12b4:	8281a703          	lw	a4,-2008(gp) # 7850 <g_fx>
    12b8:	8e01a683          	lw	a3,-1824(gp) # 7908 <g_frame_adv>
    12bc:	82c1a603          	lw	a2,-2004(gp) # 7854 <g_alpha>
    12c0:	8e41a583          	lw	a1,-1820(gp) # 790c <g_scene>
    12c4:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    12c8:	344020ef          	jal	360c <osd_build>
    osd_selfcheck();
    12cc:	100040ef          	jal	53cc <osd_selfcheck>
    bsp_printf("publish: FLIPx3 disp=%d draw=%d clr=%d (clear engine on)\r\n",
    12d0:	8501a683          	lw	a3,-1968(gp) # 7878 <g_clr3>
    12d4:	8541a603          	lw	a2,-1964(gp) # 787c <g_draw3>
    12d8:	9781a583          	lw	a1,-1672(gp) # 79a0 <g_disp_sel>
    12dc:	00007537          	lui	a0,0x7
    12e0:	d7050513          	addi	a0,a0,-656 # 6d70 <_data+0xdbc>
    12e4:	5d1020ef          	jal	40b4 <bsp_printf>
               g_disp_sel, g_draw3, g_clr3);
    bsp_printf("scenes ready: 1 GLOW 2 FADE 3 CLIP 4 LAYER 5 THRU, N=%d, SZ=%d\r\n", g_n, SPR_W);
    12e8:	85c1a603          	lw	a2,-1956(gp) # 7884 <g_blk>
    12ec:	8301a583          	lw	a1,-2000(gp) # 7858 <g_n>
    12f0:	00007537          	lui	a0,0x7
    12f4:	dac50513          	addi	a0,a0,-596 # 6dac <_data+0xdf8>
    12f8:	5bd020ef          	jal	40b4 <bsp_printf>
    g_osd_t0 = t_now; t_scene = t_now; g_t_fx0 = t_now;
    12fc:	00048993          	mv	s3,s1
    int      size_repaint = 0;
    1300:	00000a13          	li	s4,0
    int      pend_adv = 0;
    1304:	00000913          	li	s2,0
    1308:	14d0006f          	j	1c54 <main+0xb50>
    for (;;) {
        g_it++;

        /* ============ 慢时间片（每 32 圈）：UART + 时间 + 场景 + 1Hz 统计 + 占用采样 ============ */
        if ((g_it & SLOW_MASK) == 0u) {
            int      c  = uart_poll_char();
    130c:	49c020ef          	jal	37a8 <uart_poll_char>
    1310:	00050a93          	mv	s5,a0
            uint32_t st = blt_stat();          /* ★ 本圈唯一一次 STATUS 读：顺便当占用采样 */
    1314:	7f0010ef          	jal	2b04 <blt_stat>
    1318:	00050b13          	mv	s6,a0
            t_now = tick32();
    131c:	4cc010ef          	jal	27e8 <tick32>
    1320:	00050493          	mv	s1,a0
            g_busy_s++;
    1324:	9001a783          	lw	a5,-1792(gp) # 7928 <g_busy_s>
    1328:	00178793          	addi	a5,a5,1
    132c:	90f1a023          	sw	a5,-1792(gp) # 7928 <g_busy_s>
            if (!blt_idle_st(st)) g_busy_n++;
    1330:	000b0513          	mv	a0,s6
    1334:	7ec010ef          	jal	2b20 <blt_idle_st>
    1338:	00051863          	bnez	a0,1348 <main+0x244>
    133c:	9041a783          	lw	a5,-1788(gp) # 792c <g_busy_n>
    1340:	00178793          	addi	a5,a5,1
    1344:	90f1a223          	sw	a5,-1788(gp) # 792c <g_busy_n>

            /* ---------------- 串口命令 ---------------- */
            if (c) {
    1348:	0c0a9c63          	bnez	s5,1420 <main+0x31c>
                if (disp_change && g_feat_lut)
                    lut_state_line(g_scene == SC_FADE ? "fade" : "state");
            }

            /* ---------------- 场景推进：两种模式互斥 ---------------- */
            if (!g_frame_adv) {
    134c:	8e01aa83          	lw	s5,-1824(gp) # 7908 <g_frame_adv>
    1350:	520a9e63          	bnez	s5,188c <main+0x788>
                pend_adv = 0;
                if ((uint32_t)(t_now - t_scene) >= (uint32_t)SCENE_TICKS) {
    1354:	41348733          	sub	a4,s1,s3
    1358:	003d17b7          	lui	a5,0x3d1
    135c:	8ff78793          	addi	a5,a5,-1793 # 3d08ff <__freertos_irq_stack_top+0x3b36cf>
    1360:	4ee7e063          	bltu	a5,a4,1840 <main+0x73c>
                pend_adv = 0;
    1364:	000a8913          	mv	s2,s5
            } else if (pend_adv > 0) {
                scene_step(g_n); g_anim++; snap_need = 1; pend_adv--;
            }

            /* ---------------- 白闪时间线 ---------------- */
            if (g_flash_ms > 0u) {
    1368:	8cc1aa83          	lw	s5,-1844(gp) # 78f4 <g_flash_ms>
    136c:	020a8c63          	beqz	s5,13a4 <main+0x2a0>
                uint32_t el_ms = fx_elapsed_ms(t_now, g_flash_t0);   /* ★ 拍 → 毫秒 */
    1370:	8c81ab03          	lw	s6,-1848(gp) # 78f0 <g_flash_t0>
    1374:	000b0593          	mv	a1,s6
    1378:	00048513          	mv	a0,s1
    137c:	0d8010ef          	jal	2454 <fx_elapsed_ms>
                if (el_ms > 0u) {
    1380:	02050263          	beqz	a0,13a4 <main+0x2a0>
                    g_flash_t0 += el_ms * MS_TICKS;      /* 只吃掉整毫秒，余数留给下一圈 */
    1384:	000187b7          	lui	a5,0x18
    1388:	6a078793          	addi	a5,a5,1696 # 186a0 <__global_pointer$+0x10678>
    138c:	02f507b3          	mul	a5,a0,a5
    1390:	00fb0b33          	add	s6,s6,a5
    1394:	8d61a423          	sw	s6,-1848(gp) # 78f0 <g_flash_t0>
                    g_flash_ms  = (g_flash_ms > el_ms) ? (g_flash_ms - el_ms) : 0u;
    1398:	01557463          	bgeu	a0,s5,13a0 <main+0x29c>
    139c:	40aa8433          	sub	s0,s5,a0
    13a0:	8c81a623          	sw	s0,-1844(gp) # 78f4 <g_flash_ms>
                }
            }
            if (g_fx && g_feat_lut && g_scene == SC_LAYER &&
    13a4:	8281a783          	lw	a5,-2008(gp) # 7850 <g_fx>
    13a8:	00078c63          	beqz	a5,13c0 <main+0x2bc>
    13ac:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    13b0:	00078863          	beqz	a5,13c0 <main+0x2bc>
    13b4:	8e41a703          	lw	a4,-1820(gp) # 790c <g_scene>
    13b8:	00300793          	li	a5,3
    13bc:	50f70263          	beq	a4,a5,18c0 <main+0x7bc>
                ((int32_t)(t_now - g_flash_next) >= 0)) {
                g_flash_ms = FLASH_MS; g_flash_t0 = t_now;
                g_flash_next = t_now + FLASH_REARM_MS * MS_TICKS;
            }
            fx_update(t_now);
    13c0:	00048513          	mv	a0,s1
    13c4:	431020ef          	jal	3ff4 <fx_update>
            /* ★ LUT 发布兜底：帧边界一直没确认（翻转在等/扫描输出没跑）时也不能让 LUT 状态
             *   永远停在"待发布"——那等于 fade 完全不动、或白闪表洗不掉。超时就地发布一次
             *   （写 bank 与显示 bank 仍然互补 ⇒ 不会撕裂），并打一行诊断。 */
            if (g_feat_lut && g_lut_pend >= 0 &&
    13c8:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    13cc:	02078063          	beqz	a5,13ec <main+0x2e8>
    13d0:	8401a783          	lw	a5,-1984(gp) # 7868 <g_lut_pend>
    13d4:	0007cc63          	bltz	a5,13ec <main+0x2e8>
                (uint32_t)(t_now - g_lut_pend_t0) > (uint32_t)LUT_PEND_TICKS) {
    13d8:	9201a703          	lw	a4,-1760(gp) # 7948 <g_lut_pend_t0>
    13dc:	40e48733          	sub	a4,s1,a4
            if (g_feat_lut && g_lut_pend >= 0 &&
    13e0:	013137b7          	lui	a5,0x1313
    13e4:	d0078793          	addi	a5,a5,-768 # 1312d00 <__freertos_irq_stack_top+0x12f5ad0>
    13e8:	50e7e263          	bltu	a5,a4,18ec <main+0x7e8>
                    bsp_printf("\r\nEV lut WARN: publish timeout (flip not confirmed) -> published\r\n");
                lut_state_line("state");
            }

            /* ---------------- 1Hz 统计（值没变就不重画信息条）---------------- */
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    13ec:	9141a703          	lw	a4,-1772(gp) # 793c <g_osd_t0>
    13f0:	40e48733          	sub	a4,s1,a4
    13f4:	05f5e7b7          	lui	a5,0x5f5e
    13f8:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f40ecf>
    13fc:	52e7e663          	bltu	a5,a4,1928 <main+0x824>

            /* ---------------- ★ 1Hz 诊断行：扫描输出/显示通路有没有被饿死 ----------------
             * 独立门控（不看 osd_service 的返回值、也不等"本趟画完"）：引擎卡住或扫描输出
             * 不报帧边界时，这一行照样每秒出来 —— 正好用来区分"扫描饿死"与"渲染器画错"
             * （判读方法见 ev_diag_line 上方的注释）。整段只多 5 次寄存器读 + 1 行 UART。 */
            if ((uint32_t)(t_now - g_diag_t0) >= (uint32_t)BSP_CLINT_HZ) {
    1400:	8741a703          	lw	a4,-1932(gp) # 789c <g_diag_t0>
    1404:	40e48733          	sub	a4,s1,a4
    1408:	05f5e7b7          	lui	a5,0x5f5e
    140c:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f40ecf>
    1410:	04e7fce3          	bgeu	a5,a4,1c68 <main+0xb64>
                g_diag_t0 = t_now;
    1414:	8691aa23          	sw	s1,-1932(gp) # 789c <g_diag_t0>
                ev_diag_line();                /* 与串口 'd' 完全同一条代码路径 */
    1418:	4d4040ef          	jal	58ec <ev_diag_line>
    141c:	04d0006f          	j	1c68 <main+0xb64>
                int nl = nline_feed(c, &n_cmd);
    1420:	02c10593          	addi	a1,sp,44
    1424:	000a8513          	mv	a0,s5
    1428:	3b4020ef          	jal	37dc <nline_feed>
    142c:	00050b13          	mv	s6,a0
                if (nl == NL_OK) {
    1430:	00200793          	li	a5,2
    1434:	02f50a63          	beq	a0,a5,1468 <main+0x364>
                } else if (nl == NL_ERR) {
    1438:	fff00793          	li	a5,-1
    143c:	04f50863          	beq	a0,a5,148c <main+0x388>
                } else if (nl == NL_NONE) {
    1440:	32051663          	bnez	a0,176c <main+0x668>
                    if (c >= '1' && c <= '5') {
    1444:	fd5a8793          	addi	a5,s5,-43
    1448:	04e00713          	li	a4,78
    144c:	3ef76063          	bltu	a4,a5,182c <main+0x728>
    1450:	00279793          	slli	a5,a5,0x2
    1454:	00007737          	lui	a4,0x7
    1458:	42070713          	addi	a4,a4,1056 # 7420 <_data+0x146c>
    145c:	00e787b3          	add	a5,a5,a4
    1460:	0007a783          	lw	a5,0(a5)
    1464:	00078067          	jr	a5
                    g_n = n_cmd;
    1468:	02c12583          	lw	a1,44(sp)
    146c:	82b1a823          	sw	a1,-2000(gp) # 7858 <g_n>
                    g_auto = 0;                            /* 手动给数 ⇒ 关掉自动爬坡 */
    1470:	8c01ae23          	sw	zero,-1828(gp) # 7904 <g_auto>
                    bsp_printf("\r\nEV N=%d\r\n", g_n);
    1474:	00007537          	lui	a0,0x7
    1478:	df050513          	addi	a0,a0,-528 # 6df0 <_data+0xe3c>
    147c:	439020ef          	jal	40b4 <bsp_printf>
                    scene_change = 1; disp_change = 1;
    1480:	00100a93          	li	s5,1
    1484:	00100b13          	li	s6,1
    1488:	2ec0006f          	j	1774 <main+0x670>
                    bsp_printf("\r\nEV N=ERR\r\n");
    148c:	00007537          	lui	a0,0x7
    1490:	dfc50513          	addi	a0,a0,-516 # 6dfc <_data+0xe48>
    1494:	421020ef          	jal	40b4 <bsp_printf>
                int scene_change = 0, disp_change = 0;
    1498:	00000a93          	li	s5,0
    149c:	00000b13          	li	s6,0
    14a0:	2d40006f          	j	1774 <main+0x670>
                        g_scene = c - '1';
    14a4:	fcfa8b13          	addi	s6,s5,-49
    14a8:	8f61a223          	sw	s6,-1820(gp) # 790c <g_scene>
                        g_auto = (g_scene == SC_THRU) ? 1 : 0;
    14ac:	fcba8793          	addi	a5,s5,-53
    14b0:	0017b793          	seqz	a5,a5
    14b4:	8cf1ae23          	sw	a5,-1828(gp) # 7904 <g_auto>
                        g_flash_ms = FLASH_MS;                 /* 切场景给一下白闪 */
    14b8:	0dc00713          	li	a4,220
    14bc:	8ce1a623          	sw	a4,-1844(gp) # 78f4 <g_flash_ms>
                        g_flash_t0 = t_now;
    14c0:	8c91a423          	sw	s1,-1848(gp) # 78f0 <g_flash_t0>
                        g_flash_next = t_now + FLASH_REARM_MS * MS_TICKS;
    14c4:	11e1a7b7          	lui	a5,0x11e1a
    14c8:	30078793          	addi	a5,a5,768 # 11e1a300 <__freertos_irq_stack_top+0x11dfd0d0>
    14cc:	00f487b3          	add	a5,s1,a5
    14d0:	8cf1a223          	sw	a5,-1852(gp) # 78ec <g_flash_next>
                        g_t_fx0 = t_now;
    14d4:	8c91a823          	sw	s1,-1840(gp) # 78f8 <g_t_fx0>
                        bsp_printf("\r\nEV scene=%d (%s)\r\n", g_scene, scene_name(g_scene));
    14d8:	000b0513          	mv	a0,s6
    14dc:	6d1010ef          	jal	33ac <scene_name>
    14e0:	00050613          	mv	a2,a0
    14e4:	000b0593          	mv	a1,s6
    14e8:	00007537          	lui	a0,0x7
    14ec:	e0c50513          	addi	a0,a0,-500 # 6e0c <_data+0xe58>
    14f0:	3c5020ef          	jal	40b4 <bsp_printf>
                        scene_change = 1; disp_change = 1;
    14f4:	00100a93          	li	s5,1
    14f8:	00100b13          	li	s6,1
    14fc:	2780006f          	j	1774 <main+0x670>
                        g_n += N_STEP; if (g_n > N_MAX) g_n = N_MAX;   /* 只钳不绕 */
    1500:	8301a783          	lw	a5,-2000(gp) # 7858 <g_n>
    1504:	02078793          	addi	a5,a5,32
    1508:	82f1a823          	sw	a5,-2000(gp) # 7858 <g_n>
    150c:	00001737          	lui	a4,0x1
    1510:	77070713          	addi	a4,a4,1904 # 1770 <main+0x66c>
    1514:	00f75663          	bge	a4,a5,1520 <main+0x41c>
    1518:	00070793          	mv	a5,a4
    151c:	82f1a823          	sw	a5,-2000(gp) # 7858 <g_n>
                        scene_change = 1; disp_change = 1; g_auto = 0;
    1520:	8c01ae23          	sw	zero,-1828(gp) # 7904 <g_auto>
                        bsp_printf("\r\nEV N=%d\r\n", g_n);
    1524:	8301a583          	lw	a1,-2000(gp) # 7858 <g_n>
    1528:	00007537          	lui	a0,0x7
    152c:	df050513          	addi	a0,a0,-528 # 6df0 <_data+0xe3c>
    1530:	385020ef          	jal	40b4 <bsp_printf>
                        scene_change = 1; disp_change = 1; g_auto = 0;
    1534:	00100a93          	li	s5,1
    1538:	00100b13          	li	s6,1
                        bsp_printf("\r\nEV N=%d\r\n", g_n);
    153c:	2380006f          	j	1774 <main+0x670>
                        g_n -= N_STEP; if (g_n < N_MIN) g_n = N_MIN;
    1540:	8301a783          	lw	a5,-2000(gp) # 7858 <g_n>
    1544:	fe078793          	addi	a5,a5,-32
    1548:	82f1a823          	sw	a5,-2000(gp) # 7858 <g_n>
    154c:	00f00713          	li	a4,15
    1550:	00f74663          	blt	a4,a5,155c <main+0x458>
    1554:	01000713          	li	a4,16
    1558:	82e1a823          	sw	a4,-2000(gp) # 7858 <g_n>
                        scene_change = 1; disp_change = 1; g_auto = 0;
    155c:	8c01ae23          	sw	zero,-1828(gp) # 7904 <g_auto>
                        bsp_printf("\r\nEV N=%d\r\n", g_n);
    1560:	8301a583          	lw	a1,-2000(gp) # 7858 <g_n>
    1564:	00007537          	lui	a0,0x7
    1568:	df050513          	addi	a0,a0,-528 # 6df0 <_data+0xe3c>
    156c:	349020ef          	jal	40b4 <bsp_printf>
                        scene_change = 1; disp_change = 1; g_auto = 0;
    1570:	00100a93          	li	s5,1
    1574:	00100b13          	li	s6,1
    1578:	1fc0006f          	j	1774 <main+0x670>
                        g_blk = blk_next(g_blk);
    157c:	85c1a503          	lw	a0,-1956(gp) # 7884 <g_blk>
    1580:	7b9000ef          	jal	2538 <blk_next>
    1584:	84a1ae23          	sw	a0,-1956(gp) # 7884 <g_blk>
                        build_atlas();                 /* 尺寸一变必须重建图集（跨度也变了） */
    1588:	6f1030ef          	jal	5478 <build_atlas>
                        bsp_printf("\r\nEV size=%d\r\n", g_blk);
    158c:	85c1a583          	lw	a1,-1956(gp) # 7884 <g_blk>
    1590:	00007537          	lui	a0,0x7
    1594:	e2450513          	addi	a0,a0,-476 # 6e24 <_data+0xe70>
    1598:	31d020ef          	jal	40b4 <bsp_printf>
                        scene_change = 1; disp_change = 1;
    159c:	00100a93          	li	s5,1
    15a0:	00100b13          	li	s6,1
                        size_repaint = 2;              /* 另外两块缓冲里还是旧尺寸，各补铺一次 */
    15a4:	00200a13          	li	s4,2
                        bsp_printf("\r\nEV size=%d\r\n", g_blk);
    15a8:	1cc0006f          	j	1774 <main+0x670>
                        g_frame_adv = !g_frame_adv;
    15ac:	8e01a583          	lw	a1,-1824(gp) # 7908 <g_frame_adv>
    15b0:	0015b593          	seqz	a1,a1
    15b4:	8eb1a023          	sw	a1,-1824(gp) # 7908 <g_frame_adv>
                        bsp_printf("\r\nEV advance=%d (0=time 25 step/s, 1=one step per published frame)\r\n",
    15b8:	00007537          	lui	a0,0x7
    15bc:	e3450513          	addi	a0,a0,-460 # 6e34 <_data+0xe80>
    15c0:	2f5020ef          	jal	40b4 <bsp_printf>
                        t_scene = t_now;
    15c4:	00048993          	mv	s3,s1
                        disp_change = 1;
    15c8:	00100a93          	li	s5,1
                        bsp_printf("\r\nEV advance=%d (0=time 25 step/s, 1=one step per published frame)\r\n",
    15cc:	1a80006f          	j	1774 <main+0x670>
                        g_fx = !g_fx;
    15d0:	8281a583          	lw	a1,-2008(gp) # 7850 <g_fx>
    15d4:	0015b593          	seqz	a1,a1
    15d8:	82b1a423          	sw	a1,-2008(gp) # 7850 <g_fx>
                        if (!g_fx) g_flash_ms = 0u;      /* 关掉特效 ⇒ 立刻回到恒等表 + 使能 0 */
    15dc:	00059463          	bnez	a1,15e4 <main+0x4e0>
    15e0:	8c01a623          	sw	zero,-1844(gp) # 78f4 <g_flash_ms>
                        bsp_printf("\r\nEV lut=%d (1=LUT fade+flash on)\r\n", g_fx);
    15e4:	00007537          	lui	a0,0x7
    15e8:	e7c50513          	addi	a0,a0,-388 # 6e7c <_data+0xec8>
    15ec:	2c9020ef          	jal	40b4 <bsp_printf>
                        disp_change = 1;
    15f0:	00100a93          	li	s5,1
                        bsp_printf("\r\nEV lut=%d (1=LUT fade+flash on)\r\n", g_fx);
    15f4:	1800006f          	j	1774 <main+0x670>
                        g_flash_ms = FLASH_MS; g_flash_t0 = t_now;
    15f8:	0dc00713          	li	a4,220
    15fc:	8ce1a623          	sw	a4,-1844(gp) # 78f4 <g_flash_ms>
    1600:	8c91a423          	sw	s1,-1848(gp) # 78f0 <g_flash_t0>
                        bsp_printf("\r\nEV flash\r\n");
    1604:	00007537          	lui	a0,0x7
    1608:	ea050513          	addi	a0,a0,-352 # 6ea0 <_data+0xeec>
    160c:	2a9020ef          	jal	40b4 <bsp_printf>
                int scene_change = 0, disp_change = 0;
    1610:	000b0a93          	mv	s5,s6
                        bsp_printf("\r\nEV flash\r\n");
    1614:	1600006f          	j	1774 <main+0x670>
                        g_scis_on = !g_scis_on;
    1618:	84c1a583          	lw	a1,-1972(gp) # 7874 <g_scis_on>
    161c:	0015b593          	seqz	a1,a1
    1620:	84b1a623          	sw	a1,-1972(gp) # 7874 <g_scis_on>
                        bsp_printf("\r\nEV scissor=%d (scene 3 only; needs CLIP_* in RTL)\r\n", g_scis_on);
    1624:	00007537          	lui	a0,0x7
    1628:	eb050513          	addi	a0,a0,-336 # 6eb0 <_data+0xefc>
    162c:	289020ef          	jal	40b4 <bsp_printf>
                        disp_change = 1;
    1630:	00100a93          	li	s5,1
                        bsp_printf("\r\nEV scissor=%d (scene 3 only; needs CLIP_* in RTL)\r\n", g_scis_on);
    1634:	1400006f          	j	1774 <main+0x670>
                        g_attr_user = !g_attr_user;
    1638:	8481a783          	lw	a5,-1976(gp) # 7870 <g_attr_user>
    163c:	0017b793          	seqz	a5,a5
    1640:	84f1a423          	sw	a5,-1976(gp) # 7870 <g_attr_user>
                        g_attr_on = (g_feat_attr && g_attr_user) ? 1 : 0;
    1644:	94c1a703          	lw	a4,-1716(gp) # 7974 <g_feat_attr>
    1648:	00070863          	beqz	a4,1658 <main+0x554>
    164c:	02079463          	bnez	a5,1674 <main+0x570>
    1650:	00050593          	mv	a1,a0
    1654:	0080006f          	j	165c <main+0x558>
    1658:	00050593          	mv	a1,a0
    165c:	92b1ac23          	sw	a1,-1736(gp) # 7960 <g_attr_on>
                        bsp_printf("\r\nEV attr=%d (1=one ATTR word per command)\r\n", g_attr_on);
    1660:	00007537          	lui	a0,0x7
    1664:	ee850513          	addi	a0,a0,-280 # 6ee8 <_data+0xf34>
    1668:	24d020ef          	jal	40b4 <bsp_printf>
                        disp_change = 1;
    166c:	00100a93          	li	s5,1
                        bsp_printf("\r\nEV attr=%d (1=one ATTR word per command)\r\n", g_attr_on);
    1670:	1040006f          	j	1774 <main+0x670>
                        g_attr_on = (g_feat_attr && g_attr_user) ? 1 : 0;
    1674:	00100593          	li	a1,1
    1678:	fe5ff06f          	j	165c <main+0x558>
                        g_auto = !g_auto;
    167c:	8dc1a583          	lw	a1,-1828(gp) # 7904 <g_auto>
    1680:	0015b593          	seqz	a1,a1
    1684:	8cb1ae23          	sw	a1,-1828(gp) # 7904 <g_auto>
                        bsp_printf("\r\nEV auto=%d (scene 5 count ramp)\r\n", g_auto);
    1688:	00007537          	lui	a0,0x7
    168c:	f1850513          	addi	a0,a0,-232 # 6f18 <_data+0xf64>
    1690:	225020ef          	jal	40b4 <bsp_printf>
                        disp_change = 1;
    1694:	00100a93          	li	s5,1
                        bsp_printf("\r\nEV auto=%d (scene 5 count ramp)\r\n", g_auto);
    1698:	0dc0006f          	j	1774 <main+0x670>
                        if (g_alpha >= 32u) g_alpha -= 32u;
    169c:	82c1a783          	lw	a5,-2004(gp) # 7854 <g_alpha>
    16a0:	01f00713          	li	a4,31
    16a4:	00f77663          	bgeu	a4,a5,16b0 <main+0x5ac>
    16a8:	fe078793          	addi	a5,a5,-32
    16ac:	82f1a623          	sw	a5,-2004(gp) # 7854 <g_alpha>
                        bsp_printf("\r\nEV alpha=%d\r\n", (int)g_alpha);
    16b0:	82c1a583          	lw	a1,-2004(gp) # 7854 <g_alpha>
    16b4:	00007537          	lui	a0,0x7
    16b8:	f3c50513          	addi	a0,a0,-196 # 6f3c <_data+0xf88>
    16bc:	1f9020ef          	jal	40b4 <bsp_printf>
                        disp_change = 1;
    16c0:	00100a93          	li	s5,1
    16c4:	0b00006f          	j	1774 <main+0x670>
                        if (g_alpha <= 223u) g_alpha += 32u;
    16c8:	82c1a783          	lw	a5,-2004(gp) # 7854 <g_alpha>
    16cc:	0df00713          	li	a4,223
    16d0:	00f76663          	bltu	a4,a5,16dc <main+0x5d8>
    16d4:	02078793          	addi	a5,a5,32
    16d8:	82f1a623          	sw	a5,-2004(gp) # 7854 <g_alpha>
                        bsp_printf("\r\nEV alpha=%d\r\n", (int)g_alpha);
    16dc:	82c1a583          	lw	a1,-2004(gp) # 7854 <g_alpha>
    16e0:	00007537          	lui	a0,0x7
    16e4:	f3c50513          	addi	a0,a0,-196 # 6f3c <_data+0xf88>
    16e8:	1cd020ef          	jal	40b4 <bsp_printf>
                        disp_change = 1;
    16ec:	00100a93          	li	s5,1
    16f0:	0840006f          	j	1774 <main+0x670>
                        scene_change = 1; g_seed += 0x9E3779B9u;
    16f4:	8241a783          	lw	a5,-2012(gp) # 784c <g_seed>
    16f8:	9e378737          	lui	a4,0x9e378
    16fc:	9b970713          	addi	a4,a4,-1607 # 9e3779b9 <__freertos_irq_stack_top+0x9e35a789>
    1700:	00e787b3          	add	a5,a5,a4
    1704:	82f1a223          	sw	a5,-2012(gp) # 784c <g_seed>
                        bsp_printf("\r\nEV reset\r\n");
    1708:	00007537          	lui	a0,0x7
    170c:	f4c50513          	addi	a0,a0,-180 # 6f4c <_data+0xf98>
    1710:	1a5020ef          	jal	40b4 <bsp_printf>
                int scene_change = 0, disp_change = 0;
    1714:	000b0a93          	mv	s5,s6
                        scene_change = 1; g_seed += 0x9E3779B9u;
    1718:	00100b13          	li	s6,1
                        bsp_printf("\r\nEV reset\r\n");
    171c:	0580006f          	j	1774 <main+0x670>
                        bsp_printf("\r\n");
    1720:	00007537          	lui	a0,0x7
    1724:	f5c50513          	addi	a0,a0,-164 # 6f5c <_data+0xfa8>
    1728:	18d020ef          	jal	40b4 <bsp_printf>
                        ev_diag_line();
    172c:	1c0040ef          	jal	58ec <ev_diag_line>
                int scene_change = 0, disp_change = 0;
    1730:	000b0a93          	mv	s5,s6
                        ev_diag_line();
    1734:	0400006f          	j	1774 <main+0x670>
                        bsp_printf("\r\ncmd: 1..5 = scene GLOW/FADE/CLIP/LAYER/THRU\r\n"
    1738:	04000893          	li	a7,64
    173c:	02000813          	li	a6,32
    1740:	01000793          	li	a5,16
    1744:	00001737          	lui	a4,0x1
    1748:	77070713          	addi	a4,a4,1904 # 1770 <main+0x66c>
    174c:	01000693          	li	a3,16
    1750:	02000613          	li	a2,32
    1754:	02000593          	li	a1,32
    1758:	00007537          	lui	a0,0x7
    175c:	f6050513          	addi	a0,a0,-160 # 6f60 <_data+0xfac>
    1760:	155020ef          	jal	40b4 <bsp_printf>
                int scene_change = 0, disp_change = 0;
    1764:	000b0a93          	mv	s5,s6
    1768:	00c0006f          	j	1774 <main+0x670>
    176c:	00000a93          	li	s5,0
    1770:	00000b13          	li	s6,0
                if (scene_change) {
    1774:	060b0663          	beqz	s6,17e0 <main+0x6dc>
                    if (g_n > N_MAX) g_n = N_MAX;
    1778:	8301a703          	lw	a4,-2000(gp) # 7858 <g_n>
    177c:	000017b7          	lui	a5,0x1
    1780:	77078793          	addi	a5,a5,1904 # 1770 <main+0x66c>
    1784:	00e7d863          	bge	a5,a4,1794 <main+0x690>
    1788:	000017b7          	lui	a5,0x1
    178c:	77078793          	addi	a5,a5,1904 # 1770 <main+0x66c>
    1790:	82f1a823          	sw	a5,-2000(gp) # 7858 <g_n>
                    if (g_n < N_MIN) g_n = N_MIN;
    1794:	8301a703          	lw	a4,-2000(gp) # 7858 <g_n>
    1798:	00f00793          	li	a5,15
    179c:	00e7c663          	blt	a5,a4,17a8 <main+0x6a4>
    17a0:	01000713          	li	a4,16
    17a4:	82e1a823          	sw	a4,-2000(gp) # 7858 <g_n>
                    scene_init(g_n, g_seed);
    17a8:	8241a583          	lw	a1,-2012(gp) # 784c <g_seed>
    17ac:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    17b0:	794010ef          	jal	2f44 <scene_init>
                    hw_i = 0; hw_frame_pushed = 0; hw_done = 0; pend_adv = 0;
    17b4:	8a01a023          	sw	zero,-1888(gp) # 78c8 <hw_i>
    17b8:	8801ae23          	sw	zero,-1892(gp) # 78c4 <hw_frame_pushed>
    17bc:	8801ac23          	sw	zero,-1896(gp) # 78c0 <hw_done>
                    g_repaint = 1; snap_need = 0; g_pass_armed = 0;
    17c0:	00100713          	li	a4,1
    17c4:	82e1a023          	sw	a4,-2016(gp) # 7848 <g_repaint>
    17c8:	8801a623          	sw	zero,-1908(gp) # 78b4 <snap_need>
    17cc:	9601a423          	sw	zero,-1688(gp) # 7990 <g_pass_armed>
                    g_st = ST_RESTART;                 /* 改 CLIP / 目标缓冲之前先等引擎空闲 */
    17d0:	8a01ac23          	sw	zero,-1864(gp) # 78e0 <g_st>
                    g_decor_st = DEC_REPAINT; g_decor_i = 0;
    17d4:	8a01aa23          	sw	zero,-1868(gp) # 78dc <g_decor_st>
    17d8:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
                    hw_i = 0; hw_frame_pushed = 0; hw_done = 0; pend_adv = 0;
    17dc:	00000913          	li	s2,0
                if (disp_change)
    17e0:	b60a86e3          	beqz	s5,134c <main+0x248>
                    osd_build(g_n, g_scene, g_alpha, g_frame_adv, g_fx, g_scis_on, g_attr_on, g_auto);
    17e4:	8dc1a883          	lw	a7,-1828(gp) # 7904 <g_auto>
    17e8:	9381a803          	lw	a6,-1736(gp) # 7960 <g_attr_on>
    17ec:	84c1a783          	lw	a5,-1972(gp) # 7874 <g_scis_on>
    17f0:	8281a703          	lw	a4,-2008(gp) # 7850 <g_fx>
    17f4:	8e01a683          	lw	a3,-1824(gp) # 7908 <g_frame_adv>
    17f8:	82c1a603          	lw	a2,-2004(gp) # 7854 <g_alpha>
    17fc:	8e41a583          	lw	a1,-1820(gp) # 790c <g_scene>
    1800:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    1804:	609010ef          	jal	360c <osd_build>
                if (disp_change && g_feat_lut)
    1808:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    180c:	b40780e3          	beqz	a5,134c <main+0x248>
                    lut_state_line(g_scene == SC_FADE ? "fade" : "state");
    1810:	8e41a703          	lw	a4,-1820(gp) # 790c <g_scene>
    1814:	00100793          	li	a5,1
    1818:	00f70e63          	beq	a4,a5,1834 <main+0x730>
    181c:	00007537          	lui	a0,0x7
    1820:	c2850513          	addi	a0,a0,-984 # 6c28 <_data+0xc74>
    1824:	629030ef          	jal	564c <lut_state_line>
    1828:	b25ff06f          	j	134c <main+0x248>
                } else if (nl == NL_NONE) {
    182c:	000b0a93          	mv	s5,s6
    1830:	f45ff06f          	j	1774 <main+0x670>
                    lut_state_line(g_scene == SC_FADE ? "fade" : "state");
    1834:	00007537          	lui	a0,0x7
    1838:	d2c50513          	addi	a0,a0,-724 # 6d2c <_data+0xd78>
    183c:	fe9ff06f          	j	1824 <main+0x720>
                    int steps = 0;
    1840:	000a8913          	mv	s2,s5
                    do { scene_step(g_n); steps++; g_anim++; snap_need = 1; }
    1844:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    1848:	0f1010ef          	jal	3138 <scene_step>
    184c:	00190913          	addi	s2,s2,1
    1850:	8d81a783          	lw	a5,-1832(gp) # 7900 <g_anim>
    1854:	00178793          	addi	a5,a5,1
    1858:	8cf1ac23          	sw	a5,-1832(gp) # 7900 <g_anim>
    185c:	00100713          	li	a4,1
    1860:	88e1a623          	sw	a4,-1908(gp) # 78b4 <snap_need>
                    while ((uint32_t)(tick32() - t_scene) >= (uint32_t)SCENE_TICKS && steps < MAX_STEPS);
    1864:	785000ef          	jal	27e8 <tick32>
    1868:	40950533          	sub	a0,a0,s1
    186c:	003d17b7          	lui	a5,0x3d1
    1870:	8ff78793          	addi	a5,a5,-1793 # 3d08ff <__freertos_irq_stack_top+0x3b36cf>
    1874:	04a7f063          	bgeu	a5,a0,18b4 <main+0x7b0>
    1878:	00700793          	li	a5,7
    187c:	fd27d4e3          	bge	a5,s2,1844 <main+0x740>
                pend_adv = 0;
    1880:	000a8913          	mv	s2,s5
                    t_scene = t_now;
    1884:	00048993          	mv	s3,s1
    1888:	ae1ff06f          	j	1368 <main+0x264>
            } else if (pend_adv > 0) {
    188c:	ad205ee3          	blez	s2,1368 <main+0x264>
                scene_step(g_n); g_anim++; snap_need = 1; pend_adv--;
    1890:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    1894:	0a5010ef          	jal	3138 <scene_step>
    1898:	8d81a783          	lw	a5,-1832(gp) # 7900 <g_anim>
    189c:	00178793          	addi	a5,a5,1
    18a0:	8cf1ac23          	sw	a5,-1832(gp) # 7900 <g_anim>
    18a4:	00100713          	li	a4,1
    18a8:	88e1a623          	sw	a4,-1908(gp) # 78b4 <snap_need>
    18ac:	fff90913          	addi	s2,s2,-1
    18b0:	ab9ff06f          	j	1368 <main+0x264>
                pend_adv = 0;
    18b4:	000a8913          	mv	s2,s5
                    t_scene = t_now;
    18b8:	00048993          	mv	s3,s1
    18bc:	aadff06f          	j	1368 <main+0x264>
                ((int32_t)(t_now - g_flash_next) >= 0)) {
    18c0:	8c41a783          	lw	a5,-1852(gp) # 78ec <g_flash_next>
    18c4:	40f487b3          	sub	a5,s1,a5
            if (g_fx && g_feat_lut && g_scene == SC_LAYER &&
    18c8:	ae07cce3          	bltz	a5,13c0 <main+0x2bc>
                g_flash_ms = FLASH_MS; g_flash_t0 = t_now;
    18cc:	0dc00713          	li	a4,220
    18d0:	8ce1a623          	sw	a4,-1844(gp) # 78f4 <g_flash_ms>
    18d4:	8c91a423          	sw	s1,-1848(gp) # 78f0 <g_flash_t0>
                g_flash_next = t_now + FLASH_REARM_MS * MS_TICKS;
    18d8:	11e1a7b7          	lui	a5,0x11e1a
    18dc:	30078793          	addi	a5,a5,768 # 11e1a300 <__freertos_irq_stack_top+0x11dfd0d0>
    18e0:	00f487b3          	add	a5,s1,a5
    18e4:	8cf1a223          	sw	a5,-1852(gp) # 78ec <g_flash_next>
    18e8:	ad9ff06f          	j	13c0 <main+0x2bc>
                g_lut_to++;
    18ec:	91c1a783          	lw	a5,-1764(gp) # 7944 <g_lut_to>
    18f0:	00178793          	addi	a5,a5,1
    18f4:	90f1ae23          	sw	a5,-1764(gp) # 7944 <g_lut_to>
                lut_publish();
    18f8:	4c8010ef          	jal	2dc0 <lut_publish>
                if (g_lut_to <= 4u)
    18fc:	91c1a703          	lw	a4,-1764(gp) # 7944 <g_lut_to>
    1900:	00400793          	li	a5,4
    1904:	00e7fa63          	bgeu	a5,a4,1918 <main+0x814>
                lut_state_line("state");
    1908:	00007537          	lui	a0,0x7
    190c:	c2850513          	addi	a0,a0,-984 # 6c28 <_data+0xc74>
    1910:	53d030ef          	jal	564c <lut_state_line>
    1914:	ad9ff06f          	j	13ec <main+0x2e8>
                    bsp_printf("\r\nEV lut WARN: publish timeout (flip not confirmed) -> published\r\n");
    1918:	00007537          	lui	a0,0x7
    191c:	27850513          	addi	a0,a0,632 # 7278 <_data+0x12c4>
    1920:	794020ef          	jal	40b4 <bsp_printf>
    1924:	fe5ff06f          	j	1908 <main+0x804>
                osd_service(t_now, g_sc_frames, g_n, g_scene, g_alpha,
    1928:	8dc1a783          	lw	a5,-1828(gp) # 7904 <g_auto>
    192c:	00f12223          	sw	a5,4(sp)
    1930:	9381a783          	lw	a5,-1736(gp) # 7960 <g_attr_on>
    1934:	00f12023          	sw	a5,0(sp)
    1938:	84c1a883          	lw	a7,-1972(gp) # 7874 <g_scis_on>
    193c:	8281a803          	lw	a6,-2008(gp) # 7850 <g_fx>
    1940:	8e01a783          	lw	a5,-1824(gp) # 7908 <g_frame_adv>
    1944:	82c1a703          	lw	a4,-2004(gp) # 7854 <g_alpha>
    1948:	8e41a683          	lw	a3,-1820(gp) # 790c <g_scene>
    194c:	8301a603          	lw	a2,-2000(gp) # 7858 <g_n>
    1950:	8d41a583          	lw	a1,-1836(gp) # 78fc <g_sc_frames>
    1954:	00048513          	mv	a0,s1
    1958:	529010ef          	jal	3680 <osd_service>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    195c:	aa0502e3          	beqz	a0,1400 <main+0x2fc>
                g_sc_frames = 0;
    1960:	8c01aa23          	sw	zero,-1836(gp) # 78fc <g_sc_frames>
                if (g_scene == SC_THRU && g_auto) {
    1964:	8e41a703          	lw	a4,-1820(gp) # 790c <g_scene>
    1968:	00400793          	li	a5,4
    196c:	a8f71ae3          	bne	a4,a5,1400 <main+0x2fc>
    1970:	8dc1a783          	lw	a5,-1828(gp) # 7904 <g_auto>
    1974:	a80786e3          	beqz	a5,1400 <main+0x2fc>
                    int nn = g_n;
    1978:	8301a783          	lw	a5,-2000(gp) # 7858 <g_n>
                    if (g_fps <  52u) nn -= N_STEP * 2;
    197c:	9101a703          	lw	a4,-1776(gp) # 7938 <g_fps>
    1980:	03300693          	li	a3,51
    1984:	02e6e463          	bltu	a3,a4,19ac <main+0x8a8>
    1988:	fc078513          	addi	a0,a5,-64
                    if (nn < N_MIN) nn = N_MIN;
    198c:	00f00713          	li	a4,15
    1990:	02a75a63          	bge	a4,a0,19c4 <main+0x8c0>
                    if (nn > N_MAX) nn = N_MAX;
    1994:	00001737          	lui	a4,0x1
    1998:	77070713          	addi	a4,a4,1904 # 1770 <main+0x66c>
    199c:	02a75663          	bge	a4,a0,19c8 <main+0x8c4>
    19a0:	00001537          	lui	a0,0x1
    19a4:	77050513          	addi	a0,a0,1904 # 1770 <main+0x66c>
    19a8:	0200006f          	j	19c8 <main+0x8c4>
                    else if (g_fps >= 58u) nn += N_STEP;
    19ac:	03900693          	li	a3,57
    19b0:	00e6f663          	bgeu	a3,a4,19bc <main+0x8b8>
    19b4:	02078513          	addi	a0,a5,32
    19b8:	fd5ff06f          	j	198c <main+0x888>
                    int nn = g_n;
    19bc:	00078513          	mv	a0,a5
    19c0:	fcdff06f          	j	198c <main+0x888>
                    if (nn < N_MIN) nn = N_MIN;
    19c4:	01000513          	li	a0,16
                    if (nn != g_n) {
    19c8:	a2f50ce3          	beq	a0,a5,1400 <main+0x2fc>
                        g_n = nn;
    19cc:	82a1a823          	sw	a0,-2000(gp) # 7858 <g_n>
                        scene_init(g_n, g_seed);
    19d0:	8241a583          	lw	a1,-2012(gp) # 784c <g_seed>
    19d4:	570010ef          	jal	2f44 <scene_init>
                        hw_i = 0; hw_frame_pushed = 0; hw_done = 0;
    19d8:	8a01a023          	sw	zero,-1888(gp) # 78c8 <hw_i>
    19dc:	8801ae23          	sw	zero,-1892(gp) # 78c4 <hw_frame_pushed>
    19e0:	8801ac23          	sw	zero,-1896(gp) # 78c0 <hw_done>
                        g_repaint = 1; snap_need = 0; g_pass_armed = 0;
    19e4:	00100713          	li	a4,1
    19e8:	82e1a023          	sw	a4,-2016(gp) # 7848 <g_repaint>
    19ec:	8801a623          	sw	zero,-1908(gp) # 78b4 <snap_need>
    19f0:	9601a423          	sw	zero,-1688(gp) # 7990 <g_pass_armed>
                        g_st = ST_RESTART; g_decor_st = DEC_REPAINT; g_decor_i = 0;
    19f4:	8a01ac23          	sw	zero,-1864(gp) # 78e0 <g_st>
    19f8:	8a01aa23          	sw	zero,-1868(gp) # 78dc <g_decor_st>
    19fc:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
                        osd_build(g_n, g_scene, g_alpha, g_frame_adv, g_fx, g_scis_on,
    1a00:	8dc1a883          	lw	a7,-1828(gp) # 7904 <g_auto>
    1a04:	9381a803          	lw	a6,-1736(gp) # 7960 <g_attr_on>
    1a08:	84c1a783          	lw	a5,-1972(gp) # 7874 <g_scis_on>
    1a0c:	8281a703          	lw	a4,-2008(gp) # 7850 <g_fx>
    1a10:	8e01a683          	lw	a3,-1824(gp) # 7908 <g_frame_adv>
    1a14:	82c1a603          	lw	a2,-2004(gp) # 7854 <g_alpha>
    1a18:	8e41a583          	lw	a1,-1820(gp) # 790c <g_scene>
    1a1c:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    1a20:	3ed010ef          	jal	360c <osd_build>
    1a24:	9ddff06f          	j	1400 <main+0x2fc>
            }
        }

        /* ---------------- 翻转在飞的窗口：做下一趟的活 + 有界等待 ---------------- */
        if (back_busy) {
            if (snap_need) { scene_snap(g_n); snap_need = 0; }
    1a28:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    1a2c:	059010ef          	jal	3284 <scene_snap>
    1a30:	8801a623          	sw	zero,-1908(gp) # 78b4 <snap_need>
    1a34:	2440006f          	j	1c78 <main+0xb74>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
                osd_service(t_now, g_sc_frames, g_n, g_scene, g_alpha,
    1a38:	8dc1a783          	lw	a5,-1828(gp) # 7904 <g_auto>
    1a3c:	00f12223          	sw	a5,4(sp)
    1a40:	9381a783          	lw	a5,-1736(gp) # 7960 <g_attr_on>
    1a44:	00f12023          	sw	a5,0(sp)
    1a48:	84c1a883          	lw	a7,-1972(gp) # 7874 <g_scis_on>
    1a4c:	8281a803          	lw	a6,-2008(gp) # 7850 <g_fx>
    1a50:	8e01a783          	lw	a5,-1824(gp) # 7908 <g_frame_adv>
    1a54:	82c1a703          	lw	a4,-2004(gp) # 7854 <g_alpha>
    1a58:	8e41a683          	lw	a3,-1820(gp) # 790c <g_scene>
    1a5c:	8301a603          	lw	a2,-2000(gp) # 7858 <g_n>
    1a60:	8d41a583          	lw	a1,-1836(gp) # 78fc <g_sc_frames>
    1a64:	00048513          	mv	a0,s1
    1a68:	419010ef          	jal	3680 <osd_service>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    1a6c:	22050063          	beqz	a0,1c8c <main+0xb88>
                            g_frame_adv, g_fx, g_scis_on, g_attr_on, g_auto)) {
                g_sc_frames = 0;
    1a70:	8c01aa23          	sw	zero,-1836(gp) # 78fc <g_sc_frames>
    1a74:	2180006f          	j	1c8c <main+0xb88>
            }
            if ((g_it & BLT_WAIT_MASK) != 0u) { cpu_backoff(BLT_WAIT_NOP); continue; }
            {
                int      flip_ev = 0;
                uint32_t irq = blt_rd(BLT_IRQ_STATUS);
    1a78:	01000513          	li	a0,16
    1a7c:	599000ef          	jal	2814 <blt_rd>
                if (irq & BLT_IRQ_FRAME) {
    1a80:	00257513          	andi	a0,a0,2
    1a84:	00050e63          	beqz	a0,1aa0 <main+0x99c>
                    blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);      /* W1C：清本场中断 */
    1a88:	00200593          	li	a1,2
    1a8c:	01000513          	li	a0,16
    1a90:	575000ef          	jal	2804 <blt_wr>
                    flip_ev = 1;
                }
                if (flip_ev && (fb_stat_sel() == g_flip_req)) {
    1a94:	5b9000ef          	jal	284c <fb_stat_sel>
    1a98:	9741a783          	lw	a5,-1676(gp) # 799c <g_flip_req>
    1a9c:	06f50c63          	beq	a0,a5,1b14 <main+0xa10>
                    g_sc_frames++;
                    g_flip_ok++;                    /* ★ EV diag 的 flp：开机以来确认的翻转数 */
                    if (g_frame_adv && pend_adv < MAX_STEPS) pend_adv++;
                    lut_publish();                  /* ★ LUT 两 bank 只在帧边界切换 */
                    if (size_repaint > 0) { g_repaint = 1; size_repaint--; }
                } else if ((uint32_t)(tick32() - back_t0) > (uint32_t)FLIP_TIMEOUT_TICKS) {
    1aa0:	549000ef          	jal	27e8 <tick32>
    1aa4:	8901a783          	lw	a5,-1904(gp) # 78b8 <back_t0>
    1aa8:	40f50533          	sub	a0,a0,a5
    1aac:	009897b7          	lui	a5,0x989
    1ab0:	68078793          	addi	a5,a5,1664 # 989680 <__freertos_irq_stack_top+0x96c450>
    1ab4:	14a7f263          	bgeu	a5,a0,1bf8 <main+0xaf4>
                    g_flip_to++;
    1ab8:	9701a783          	lw	a5,-1680(gp) # 7998 <g_flip_to>
    1abc:	00178793          	addi	a5,a5,1
    1ac0:	96f1a823          	sw	a5,-1680(gp) # 7998 <g_flip_to>
                    g_flip_bad++;                        /* ★ EV diag 的 flpt：开机以来超时数 */
    1ac4:	86c1a783          	lw	a5,-1940(gp) # 7894 <g_flip_bad>
    1ac8:	00178793          	addi	a5,a5,1
    1acc:	86f1a623          	sw	a5,-1940(gp) # 7894 <g_flip_bad>
                    blt_wr(BLT_FB_SEL, g_flip_req);      /* 重发请求，继续有界等待 */
    1ad0:	9741a583          	lw	a1,-1676(gp) # 799c <g_flip_req>
    1ad4:	02400513          	li	a0,36
    1ad8:	52d000ef          	jal	2804 <blt_wr>
                    back_t0 = tick32();
    1adc:	50d000ef          	jal	27e8 <tick32>
    1ae0:	88a1a823          	sw	a0,-1904(gp) # 78b8 <back_t0>
                    if (g_flip_to <= FLIP_GIVEUP_N) {
    1ae4:	9701a783          	lw	a5,-1680(gp) # 7998 <g_flip_to>
    1ae8:	00300713          	li	a4,3
    1aec:	0af76463          	bltu	a4,a5,1b94 <main+0xa90>
                        if (g_flip_to == 1u)
    1af0:	00100713          	li	a4,1
    1af4:	16e79063          	bne	a5,a4,1c54 <main+0xb50>
                            bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
                                       (unsigned)blt_rd(BLT_FB_STAT));
    1af8:	02800513          	li	a0,40
    1afc:	519000ef          	jal	2814 <blt_rd>
    1b00:	00050593          	mv	a1,a0
                            bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
    1b04:	00007537          	lui	a0,0x7
    1b08:	2bc50513          	addi	a0,a0,700 # 72bc <_data+0x1308>
    1b0c:	5a8020ef          	jal	40b4 <bsp_printf>
    1b10:	1440006f          	j	1c54 <main+0xb50>
                    int old_disp = g_disp_sel;
    1b14:	9781a683          	lw	a3,-1672(gp) # 79a0 <g_disp_sel>
                    back_busy  = 0;
    1b18:	8801aa23          	sw	zero,-1900(gp) # 78bc <back_busy>
                    g_flip_to  = 0;
    1b1c:	9601a823          	sw	zero,-1680(gp) # 7998 <g_flip_to>
                    g_disp_sel = (int)g_flip_req;
    1b20:	96f1ac23          	sw	a5,-1672(gp) # 79a0 <g_disp_sel>
                    g_draw3    = g_clr3;
    1b24:	8501a503          	lw	a0,-1968(gp) # 7878 <g_clr3>
    1b28:	84a1aa23          	sw	a0,-1964(gp) # 787c <g_draw3>
                    g_clr3     = old_disp;
    1b2c:	84d1a823          	sw	a3,-1968(gp) # 7878 <g_clr3>
                    g_clr_need = 1;                 /* 下一趟开始时给清屏引擎下新命令 */
    1b30:	00100713          	li	a4,1
    1b34:	96e1a623          	sw	a4,-1684(gp) # 7994 <g_clr_need>
                    g_pass_armed = 0;
    1b38:	9601a423          	sw	zero,-1688(gp) # 7990 <g_pass_armed>
                    g_fb_back  = fb_of_sel((uint32_t)g_draw3);
    1b3c:	4e9000ef          	jal	2824 <fb_of_sel>
    1b40:	84a1ac23          	sw	a0,-1960(gp) # 7880 <g_fb_back>
                    g_st       = ST_RESTART;
    1b44:	8a01ac23          	sw	zero,-1864(gp) # 78e0 <g_st>
                    g_decor_st = DEC_REPAINT; g_decor_i = 0;
    1b48:	8a01aa23          	sw	zero,-1868(gp) # 78dc <g_decor_st>
    1b4c:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
                    g_sc_frames++;
    1b50:	8d41a783          	lw	a5,-1836(gp) # 78fc <g_sc_frames>
    1b54:	00178793          	addi	a5,a5,1
    1b58:	8cf1aa23          	sw	a5,-1836(gp) # 78fc <g_sc_frames>
                    g_flip_ok++;                    /* ★ EV diag 的 flp：开机以来确认的翻转数 */
    1b5c:	8701a783          	lw	a5,-1936(gp) # 7898 <g_flip_ok>
    1b60:	00178793          	addi	a5,a5,1
    1b64:	86f1a823          	sw	a5,-1936(gp) # 7898 <g_flip_ok>
                    if (g_frame_adv && pend_adv < MAX_STEPS) pend_adv++;
    1b68:	8e01a783          	lw	a5,-1824(gp) # 7908 <g_frame_adv>
    1b6c:	00078863          	beqz	a5,1b7c <main+0xa78>
    1b70:	00700793          	li	a5,7
    1b74:	0127c463          	blt	a5,s2,1b7c <main+0xa78>
    1b78:	00190913          	addi	s2,s2,1
                    lut_publish();                  /* ★ LUT 两 bank 只在帧边界切换 */
    1b7c:	244010ef          	jal	2dc0 <lut_publish>
                    if (size_repaint > 0) { g_repaint = 1; size_repaint--; }
    1b80:	0d405a63          	blez	s4,1c54 <main+0xb50>
    1b84:	00100713          	li	a4,1
    1b88:	82e1a023          	sw	a4,-2016(gp) # 7848 <g_repaint>
    1b8c:	fffa0a13          	addi	s4,s4,-1
    1b90:	0c40006f          	j	1c54 <main+0xb50>
                    } else {
                        /* ★ 连续多次确认不到（扫描输出没跑 / FB_STAT 不跟）⇒ 不再无限等：
                         * 认下这次翻转继续走。屏幕上可能是"慢半拍"，但绝不冻结，
                         * 串口随时能切场景（这正是上板"切不回去"的那个死点之一）。 */
                        int old_disp2 = g_disp_sel;
    1b94:	9781a703          	lw	a4,-1672(gp) # 79a0 <g_disp_sel>
                        g_flip_to  = 0;
    1b98:	9601a823          	sw	zero,-1680(gp) # 7998 <g_flip_to>
                        back_busy  = 0;
    1b9c:	8801aa23          	sw	zero,-1900(gp) # 78bc <back_busy>
                        g_disp_sel = (int)g_flip_req;
    1ba0:	9741a683          	lw	a3,-1676(gp) # 799c <g_flip_req>
    1ba4:	96d1ac23          	sw	a3,-1672(gp) # 79a0 <g_disp_sel>
                        g_draw3    = g_clr3;
    1ba8:	8501a503          	lw	a0,-1968(gp) # 7878 <g_clr3>
    1bac:	84a1aa23          	sw	a0,-1964(gp) # 787c <g_draw3>
                        g_clr3     = old_disp2;
    1bb0:	84e1a823          	sw	a4,-1968(gp) # 7878 <g_clr3>
                        g_clr_need = 1;
    1bb4:	00100713          	li	a4,1
    1bb8:	96e1a623          	sw	a4,-1684(gp) # 7994 <g_clr_need>
                        g_pass_armed = 0;
    1bbc:	9601a423          	sw	zero,-1688(gp) # 7990 <g_pass_armed>
                        g_fb_back  = fb_of_sel((uint32_t)g_draw3);
    1bc0:	465000ef          	jal	2824 <fb_of_sel>
    1bc4:	84a1ac23          	sw	a0,-1960(gp) # 7880 <g_fb_back>
                        g_st       = ST_RESTART;
    1bc8:	8a01ac23          	sw	zero,-1864(gp) # 78e0 <g_st>
                        g_decor_st = DEC_REPAINT; g_decor_i = 0;
    1bcc:	8a01aa23          	sw	zero,-1868(gp) # 78dc <g_decor_st>
    1bd0:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
                        bsp_printf("\r\nEV flip giveup after %d timeouts (FB_STAT=%x) -> continue\r\n",
                                   (int)FLIP_GIVEUP_N, (unsigned)blt_rd(BLT_FB_STAT));
    1bd4:	02800513          	li	a0,40
    1bd8:	43d000ef          	jal	2814 <blt_rd>
    1bdc:	00050613          	mv	a2,a0
                        bsp_printf("\r\nEV flip giveup after %d timeouts (FB_STAT=%x) -> continue\r\n",
    1be0:	00300593          	li	a1,3
    1be4:	00007537          	lui	a0,0x7
    1be8:	2dc50513          	addi	a0,a0,732 # 72dc <_data+0x1328>
    1bec:	4c8020ef          	jal	40b4 <bsp_printf>
                        lut_publish();               /* 帧边界没确认也要把 LUT 状态推上去 */
    1bf0:	1d0010ef          	jal	2dc0 <lut_publish>
    1bf4:	0600006f          	j	1c54 <main+0xb50>
                    }
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
    1bf8:	03000513          	li	a0,48
    1bfc:	3f9000ef          	jal	27f4 <cpu_backoff>
    1c00:	0540006f          	j	1c54 <main+0xb50>
                }
            }
        } else if (hw_done) {
    1c04:	8981a403          	lw	s0,-1896(gp) # 78c0 <hw_done>
    1c08:	02041463          	bnez	s0,1c30 <main+0xb2c>
            back_busy = 1;
            back_t0   = tick32();
            hw_done   = 0;
        } else {
            /* ---------------- 段机：把本趟的命令流推出去 ---------------- */
            switch (g_st) {
    1c0c:	8b81aa83          	lw	s5,-1864(gp) # 78e0 <g_st>
    1c10:	00400793          	li	a5,4
    1c14:	3957e463          	bltu	a5,s5,1f9c <main+0xe98>
    1c18:	002a9793          	slli	a5,s5,0x2
    1c1c:	00007737          	lui	a4,0x7
    1c20:	55c70713          	addi	a4,a4,1372 # 755c <_data+0x15a8>
    1c24:	00e787b3          	add	a5,a5,a4
    1c28:	0007a783          	lw	a5,0(a5)
    1c2c:	00078067          	jr	a5
            g_flip_req = (uint32_t)g_draw3;
    1c30:	8541a583          	lw	a1,-1964(gp) # 787c <g_draw3>
    1c34:	96b1aa23          	sw	a1,-1676(gp) # 799c <g_flip_req>
            blt_wr(BLT_FB_SEL, g_flip_req);
    1c38:	02400513          	li	a0,36
    1c3c:	3c9000ef          	jal	2804 <blt_wr>
            back_busy = 1;
    1c40:	00100713          	li	a4,1
    1c44:	88e1aa23          	sw	a4,-1900(gp) # 78bc <back_busy>
            back_t0   = tick32();
    1c48:	3a1000ef          	jal	27e8 <tick32>
    1c4c:	88a1a823          	sw	a0,-1904(gp) # 78b8 <back_t0>
            hw_done   = 0;
    1c50:	8801ac23          	sw	zero,-1896(gp) # 78c0 <hw_done>
        g_it++;
    1c54:	8881a783          	lw	a5,-1912(gp) # 78b0 <g_it>
    1c58:	00178793          	addi	a5,a5,1
    1c5c:	88f1a423          	sw	a5,-1912(gp) # 78b0 <g_it>
        if ((g_it & SLOW_MASK) == 0u) {
    1c60:	01f7f413          	andi	s0,a5,31
    1c64:	ea040463          	beqz	s0,130c <main+0x208>
        if (back_busy) {
    1c68:	8941a783          	lw	a5,-1900(gp) # 78bc <back_busy>
    1c6c:	f8078ce3          	beqz	a5,1c04 <main+0xb00>
            if (snap_need) { scene_snap(g_n); snap_need = 0; }
    1c70:	88c1a783          	lw	a5,-1908(gp) # 78b4 <snap_need>
    1c74:	da079ae3          	bnez	a5,1a28 <main+0x924>
            if (((uint32_t)(t_now - g_osd_t0) >= (uint32_t)BSP_CLINT_HZ) &&
    1c78:	9141a703          	lw	a4,-1772(gp) # 793c <g_osd_t0>
    1c7c:	40e48733          	sub	a4,s1,a4
    1c80:	05f5e7b7          	lui	a5,0x5f5e
    1c84:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f40ecf>
    1c88:	dae7e8e3          	bltu	a5,a4,1a38 <main+0x934>
            if ((g_it & BLT_WAIT_MASK) != 0u) { cpu_backoff(BLT_WAIT_NOP); continue; }
    1c8c:	8881a783          	lw	a5,-1912(gp) # 78b0 <g_it>
    1c90:	0037f793          	andi	a5,a5,3
    1c94:	de0782e3          	beqz	a5,1a78 <main+0x974>
    1c98:	03000513          	li	a0,48
    1c9c:	359000ef          	jal	27f4 <cpu_backoff>
    1ca0:	fb5ff06f          	j	1c54 <main+0xb50>
            case ST_RESTART: {
                /* 改 CLIP / 拍快照 / 改目标缓冲之前，先确认引擎彻底空闲（文件头 (a)）；
                 * ★ 等待有界：超时（引擎停机）⇒ 软复位 + 重开本趟，绝不无限空转 */
                int r = blt_idle_bounded(STW_RESTART);
    1ca4:	00000513          	li	a0,0
    1ca8:	048020ef          	jal	3cf0 <blt_idle_bounded>
                if (r == ST_WAIT_MORE) break;
    1cac:	fa0504e3          	beqz	a0,1c54 <main+0xb50>
                if (r == ST_WAIT_TIMEO) { blt_recover("restart", STW_RESTART); break; }
    1cb0:	00200793          	li	a5,2
    1cb4:	02f50463          	beq	a0,a5,1cdc <main+0xbd8>
                clip_off_verified();           /* ★ 段 0 之前：写 0 + 回读确认（信息条绝不被裁） */
    1cb8:	4ed030ef          	jal	59a4 <clip_off_verified>
                hw_i = 0; hw_frame_pushed = 0;
    1cbc:	8a01a023          	sw	zero,-1888(gp) # 78c8 <hw_i>
    1cc0:	8801ae23          	sw	zero,-1892(gp) # 78c4 <hw_frame_pushed>
                g_pass_armed = 0;
    1cc4:	9601a423          	sw	zero,-1688(gp) # 7990 <g_pass_armed>
                g_decor_st = DEC_REPAINT; g_decor_i = 0;
    1cc8:	8a01aa23          	sw	zero,-1868(gp) # 78dc <g_decor_st>
    1ccc:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
                g_st = ST_DECOR;
    1cd0:	00100713          	li	a4,1
    1cd4:	8ae1ac23          	sw	a4,-1864(gp) # 78e0 <g_st>
                break; }
    1cd8:	f7dff06f          	j	1c54 <main+0xb50>
                if (r == ST_WAIT_TIMEO) { blt_recover("restart", STW_RESTART); break; }
    1cdc:	00000593          	li	a1,0
    1ce0:	00007537          	lui	a0,0x7
    1ce4:	31c50513          	addi	a0,a0,796 # 731c <_data+0x1368>
    1ce8:	539030ef          	jal	5a20 <blt_recover>
    1cec:	f69ff06f          	j	1c54 <main+0xb50>

            case ST_DECOR: {
                uint32_t room = 0u;
    1cf0:	00012e23          	sw	zero,28(sp)
                int      rr   = blt_room_bounded(&room);
    1cf4:	01c10513          	addi	a0,sp,28
    1cf8:	0d8020ef          	jal	3dd0 <blt_room_bounded>
    1cfc:	00050413          	mv	s0,a0
                /* 一趟起点的一次性动作：拍快照 → 查 clean/选目标/下清屏命令（决定要不要重铺） */
                if (!g_pass_armed) {
    1d00:	9681ab03          	lw	s6,-1688(gp) # 7990 <g_pass_armed>
    1d04:	080b1a63          	bnez	s6,1d98 <main+0xc94>
                    if (snap_need) { scene_snap(g_n); snap_need = 0; }
    1d08:	88c1a783          	lw	a5,-1908(gp) # 78b4 <snap_need>
    1d0c:	0a079c63          	bnez	a5,1dc4 <main+0xcc0>
                    sweep_snap();                        /* 扫掠条位置也按趟冻结（规划/绘制必须同值） */
    1d10:	174020ef          	jal	3e84 <sweep_snap>
                    /* 本趟内容段要不要按局部窗口裁剪：整趟一个决定 ⇒ 'x' 的 A/B 在趟边界生效 */
                    g_clip_pass = (g_scene == SC_CLIP && g_scis_on && g_feat_clip) ? 1 : 0;
    1d14:	8e41a603          	lw	a2,-1820(gp) # 790c <g_scene>
    1d18:	00200793          	li	a5,2
    1d1c:	0af60c63          	beq	a2,a5,1dd4 <main+0xcd0>
    1d20:	9561a423          	sw	s6,-1720(gp) # 7970 <g_clip_pass>
                    g_pass_armed = 1;
    1d24:	00100713          	li	a4,1
    1d28:	96e1a423          	sw	a4,-1688(gp) # 7990 <g_pass_armed>
                    g_repaint = hw_pass_arm(TOP_Y0, PLAY_H, (g_scene == SC_LAYER) ? 0 : 1);
    1d2c:	ffd60613          	addi	a2,a2,-3
    1d30:	00c03633          	snez	a2,a2
    1d34:	20c00593          	li	a1,524
    1d38:	01000513          	li	a0,16
    1d3c:	4a1000ef          	jal	29dc <hw_pass_arm>
    1d40:	82a1a023          	sw	a0,-2016(gp) # 7848 <g_repaint>
                    g_bar_need = (g_osd_dirty || !g_bar_ok[(uint32_t)g_draw3]) ? 1 : 0;
    1d44:	8341a783          	lw	a5,-1996(gp) # 785c <g_osd_dirty>
    1d48:	00079e63          	bnez	a5,1d64 <main+0xc60>
    1d4c:	8541a703          	lw	a4,-1964(gp) # 787c <g_draw3>
    1d50:	95818693          	addi	a3,gp,-1704 # 7980 <g_bar_ok>
    1d54:	00d70733          	add	a4,a4,a3
    1d58:	00074703          	lbu	a4,0(a4)
    1d5c:	00070463          	beqz	a4,1d64 <main+0xc60>
    1d60:	00078a93          	mv	s5,a5
    1d64:	8b51a623          	sw	s5,-1876(gp) # 78d4 <g_bar_need>
                    g_bar_len  = slen(g_osd_line);
    1d68:	99818513          	addi	a0,gp,-1640 # 79c0 <g_osd_line>
    1d6c:	081010ef          	jal	35ec <slen>
    1d70:	00050a93          	mv	s5,a0
    1d74:	8aa1a423          	sw	a0,-1880(gp) # 78d0 <g_bar_len>
                    g_lbl_len  = slen(OSD_LABEL);
    1d78:	00007537          	lui	a0,0x7
    1d7c:	9a050513          	addi	a0,a0,-1632 # 69a0 <_data+0x9ec>
    1d80:	06d010ef          	jal	35ec <slen>
    1d84:	8aa1a223          	sw	a0,-1884(gp) # 78cc <g_lbl_len>
                    if (g_bar_len > OSD_LEFT_CH) g_bar_len = OSD_LEFT_CH;
    1d88:	04800793          	li	a5,72
    1d8c:	0157d663          	bge	a5,s5,1d98 <main+0xc94>
    1d90:	04800713          	li	a4,72
    1d94:	8ae1a423          	sw	a4,-1880(gp) # 78d0 <g_bar_len>
                }
                if (rr == ST_WAIT_MORE) break;             /* 余量不够：下一圈再来 */
    1d98:	ea040ee3          	beqz	s0,1c54 <main+0xb50>
                if (rr == ST_WAIT_TIMEO) { blt_recover("fifo room", STW_ROOM); break; }
    1d9c:	00200793          	li	a5,2
    1da0:	04f40663          	beq	s0,a5,1dec <main+0xce8>
                if (decor_step(&room)) {
    1da4:	01c10513          	addi	a0,sp,28
    1da8:	104030ef          	jal	4eac <decor_step>
    1dac:	ea0504e3          	beqz	a0,1c54 <main+0xb50>
                    if (g_cmd_t0 == 0u) g_cmd_t0 = tick32();
    1db0:	8c01a783          	lw	a5,-1856(gp) # 78e8 <g_cmd_t0>
    1db4:	04078663          	beqz	a5,1e00 <main+0xcfc>
                    g_st = ST_FENCE;
    1db8:	00200713          	li	a4,2
    1dbc:	8ae1ac23          	sw	a4,-1864(gp) # 78e0 <g_st>
    1dc0:	e95ff06f          	j	1c54 <main+0xb50>
                    if (snap_need) { scene_snap(g_n); snap_need = 0; }
    1dc4:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    1dc8:	4bc010ef          	jal	3284 <scene_snap>
    1dcc:	8801a623          	sw	zero,-1908(gp) # 78b4 <snap_need>
    1dd0:	f41ff06f          	j	1d10 <main+0xc0c>
                    g_clip_pass = (g_scene == SC_CLIP && g_scis_on && g_feat_clip) ? 1 : 0;
    1dd4:	84c1a783          	lw	a5,-1972(gp) # 7874 <g_scis_on>
    1dd8:	f40784e3          	beqz	a5,1d20 <main+0xc1c>
    1ddc:	9541a783          	lw	a5,-1708(gp) # 797c <g_feat_clip>
    1de0:	f40780e3          	beqz	a5,1d20 <main+0xc1c>
    1de4:	000a8b13          	mv	s6,s5
    1de8:	f39ff06f          	j	1d20 <main+0xc1c>
                if (rr == ST_WAIT_TIMEO) { blt_recover("fifo room", STW_ROOM); break; }
    1dec:	00400593          	li	a1,4
    1df0:	00007537          	lui	a0,0x7
    1df4:	32450513          	addi	a0,a0,804 # 7324 <_data+0x1370>
    1df8:	429030ef          	jal	5a20 <blt_recover>
    1dfc:	e59ff06f          	j	1c54 <main+0xb50>
                    if (g_cmd_t0 == 0u) g_cmd_t0 = tick32();
    1e00:	1e9000ef          	jal	27e8 <tick32>
    1e04:	8ca1a023          	sw	a0,-1856(gp) # 78e8 <g_cmd_t0>
    1e08:	fb1ff06f          	j	1db8 <main+0xcb4>
                }
                break; }

            case ST_FENCE: {
                /* ★ 围栏：段 0（scissor 关着画的那一段）全部画完之后才允许动 CLIP 状态 */
                int r = blt_idle_bounded(STW_FENCE);
    1e0c:	00100513          	li	a0,1
    1e10:	6e1010ef          	jal	3cf0 <blt_idle_bounded>
                if (r == ST_WAIT_MORE) break;
    1e14:	e40500e3          	beqz	a0,1c54 <main+0xb50>
                if (r == ST_WAIT_TIMEO) { blt_recover("fence", STW_FENCE); break; }
    1e18:	00200793          	li	a5,2
    1e1c:	00f50a63          	beq	a0,a5,1e30 <main+0xd2c>
                clip_off_verified();           /* 段 0 正好结束：再回读确认一次（信息条/HUD 安全） */
    1e20:	385030ef          	jal	59a4 <clip_off_verified>
                g_st = ST_CONTENT;
    1e24:	00300713          	li	a4,3
    1e28:	8ae1ac23          	sw	a4,-1864(gp) # 78e0 <g_st>
                break; }
    1e2c:	e29ff06f          	j	1c54 <main+0xb50>
                if (r == ST_WAIT_TIMEO) { blt_recover("fence", STW_FENCE); break; }
    1e30:	00100593          	li	a1,1
    1e34:	00007537          	lui	a0,0x7
    1e38:	33050513          	addi	a0,a0,816 # 7330 <_data+0x137c>
    1e3c:	3e5030ef          	jal	5a20 <blt_recover>
    1e40:	e15ff06f          	j	1c54 <main+0xb50>

            case ST_CONTENT: {
                uint32_t room   = 0u;
    1e44:	00012a23          	sw	zero,20(sp)
                uint32_t budget = HW_PUSH_BUDGET;
                int      rr     = blt_room_bounded(&room);
    1e48:	01410513          	addi	a0,sp,20
    1e4c:	785010ef          	jal	3dd0 <blt_room_bounded>
    1e50:	00050b13          	mv	s6,a0
                if (rr == ST_WAIT_TIMEO) { blt_recover("fifo room(content)", STW_ROOM); break; }
    1e54:	00200793          	li	a5,2
    1e58:	00f50663          	beq	a0,a5,1e64 <main+0xd60>
                uint32_t budget = HW_PUSH_BUDGET;
    1e5c:	04000a93          	li	s5,64
    1e60:	0240006f          	j	1e84 <main+0xd80>
                if (rr == ST_WAIT_TIMEO) { blt_recover("fifo room(content)", STW_ROOM); break; }
    1e64:	00400593          	li	a1,4
    1e68:	00007537          	lui	a0,0x7
    1e6c:	33850513          	addi	a0,a0,824 # 7338 <_data+0x1384>
    1e70:	3b1030ef          	jal	5a20 <blt_recover>
    1e74:	de1ff06f          	j	1c54 <main+0xb50>
                while (room > 0u && budget > 0u && hw_i < content_total()) {
                    iclip_t w; int need;
                    if (content_plan(hw_i, &w, &need)) {   /* 与裁剪窗口不相交 ⇒ 整条省掉 */
                        hw_i++;
    1e78:	8a01a783          	lw	a5,-1888(gp) # 78c8 <hw_i>
    1e7c:	00178793          	addi	a5,a5,1
    1e80:	8af1a023          	sw	a5,-1888(gp) # 78c8 <hw_i>
                while (room > 0u && budget > 0u && hw_i < content_total()) {
    1e84:	01412783          	lw	a5,20(sp)
    1e88:	08078663          	beqz	a5,1f14 <main+0xe10>
    1e8c:	080a8463          	beqz	s5,1f14 <main+0xe10>
    1e90:	7d9010ef          	jal	3e68 <content_total>
    1e94:	8a01a783          	lw	a5,-1888(gp) # 78c8 <hw_i>
    1e98:	06a7de63          	bge	a5,a0,1f14 <main+0xe10>
                    if (content_plan(hw_i, &w, &need)) {   /* 与裁剪窗口不相交 ⇒ 整条省掉 */
    1e9c:	01810613          	addi	a2,sp,24
    1ea0:	01c10593          	addi	a1,sp,28
    1ea4:	00078513          	mv	a0,a5
    1ea8:	0a0020ef          	jal	3f48 <content_plan>
    1eac:	fc0516e3          	bnez	a0,1e78 <main+0xd74>
                        continue;
                    }
                    if (need) {                            /* 窗口是**局部**坐标 ⇒ 常常要换 */
    1eb0:	01812783          	lw	a5,24(sp)
    1eb4:	02079663          	bnez	a5,1ee0 <main+0xddc>
                        g_clip_want    = w;
                        g_clip_want_on = g_clip_pass;
                        g_st = ST_CLIP;
                        break;
                    }
                    content_emit(hw_i);
    1eb8:	8a01a503          	lw	a0,-1888(gp) # 78c8 <hw_i>
    1ebc:	4d0030ef          	jal	538c <content_emit>
                    hw_i++; room--; budget--;
    1ec0:	8a01a783          	lw	a5,-1888(gp) # 78c8 <hw_i>
    1ec4:	00178793          	addi	a5,a5,1
    1ec8:	8af1a023          	sw	a5,-1888(gp) # 78c8 <hw_i>
    1ecc:	01412783          	lw	a5,20(sp)
    1ed0:	fff78793          	addi	a5,a5,-1
    1ed4:	00f12a23          	sw	a5,20(sp)
    1ed8:	fffa8a93          	addi	s5,s5,-1
    1edc:	fa9ff06f          	j	1e84 <main+0xd80>
                        g_clip_want    = w;
    1ee0:	97c18793          	addi	a5,gp,-1668 # 79a4 <g_clip_want>
    1ee4:	01c12703          	lw	a4,28(sp)
    1ee8:	00e7a023          	sw	a4,0(a5)
    1eec:	02012703          	lw	a4,32(sp)
    1ef0:	00e7a223          	sw	a4,4(a5)
    1ef4:	02412703          	lw	a4,36(sp)
    1ef8:	00e7a423          	sw	a4,8(a5)
    1efc:	02812703          	lw	a4,40(sp)
    1f00:	00e7a623          	sw	a4,12(a5)
                        g_clip_want_on = g_clip_pass;
    1f04:	9481a703          	lw	a4,-1720(gp) # 7970 <g_clip_pass>
    1f08:	88e1a223          	sw	a4,-1916(gp) # 78ac <g_clip_want_on>
                        g_st = ST_CLIP;
    1f0c:	00400713          	li	a4,4
    1f10:	8ae1ac23          	sw	a4,-1864(gp) # 78e0 <g_st>
                }
                if (g_st == ST_CLIP) break;                /* 先去把窗口写进寄存器 */
    1f14:	8b81a703          	lw	a4,-1864(gp) # 78e0 <g_st>
    1f18:	00400793          	li	a5,4
    1f1c:	d2f70ce3          	beq	a4,a5,1c54 <main+0xb50>
                if (hw_i >= content_total()) { hw_frame_pushed = 1; g_st = ST_WAIT; }
    1f20:	749010ef          	jal	3e68 <content_total>
    1f24:	8a01a783          	lw	a5,-1888(gp) # 78c8 <hw_i>
    1f28:	00a7cc63          	blt	a5,a0,1f40 <main+0xe3c>
    1f2c:	00100713          	li	a4,1
    1f30:	88e1ae23          	sw	a4,-1892(gp) # 78c4 <hw_frame_pushed>
    1f34:	00500713          	li	a4,5
    1f38:	8ae1ac23          	sw	a4,-1864(gp) # 78e0 <g_st>
    1f3c:	d19ff06f          	j	1c54 <main+0xb50>
                else if (rr == ST_WAIT_MORE) cpu_backoff(BLT_WAIT_NOP);
    1f40:	d00b1ae3          	bnez	s6,1c54 <main+0xb50>
    1f44:	03000513          	li	a0,48
    1f48:	0ad000ef          	jal	27f4 <cpu_backoff>
    1f4c:	d09ff06f          	j	1c54 <main+0xb50>
            case ST_CLIP: {
                /* ★ 改 CLIP_* 前必须确认引擎**彻底空闲**（寄存器在命令起始锁存，见文件头 (a)）。
                 * 一次围栏换一条命令的局部窗口；窗口没变的连续命令（整幅落在窗口里的精灵都是
                 * [0,SZ)x[0,SZ)）不会走到这里 ⇒ 场景 3 的额外代价只有"窗口变化"那几次。
                 * ★ 这个等待正是上板"场景 3 卡死、之后切不回去"的那一点：现在有界 + 能恢复。 */
                int r = blt_idle_bounded(STW_CLIP);
    1f50:	00200513          	li	a0,2
    1f54:	59d010ef          	jal	3cf0 <blt_idle_bounded>
                if (r == ST_WAIT_MORE) break;
    1f58:	ce050ee3          	beqz	a0,1c54 <main+0xb50>
                if (r == ST_WAIT_TIMEO) { blt_recover("clip fence", STW_CLIP); break; }
    1f5c:	00200793          	li	a5,2
    1f60:	02f50063          	beq	a0,a5,1f80 <main+0xe7c>
                if (g_clip_want_on) clip_arm(&g_clip_want);
    1f64:	8841a783          	lw	a5,-1916(gp) # 78ac <g_clip_want_on>
    1f68:	02078663          	beqz	a5,1f94 <main+0xe90>
    1f6c:	97c18513          	addi	a0,gp,-1668 # 79a4 <g_clip_want>
    1f70:	48d010ef          	jal	3bfc <clip_arm>
                else                clip_off();
                g_st = ST_CONTENT;
    1f74:	00300713          	li	a4,3
    1f78:	8ae1ac23          	sw	a4,-1864(gp) # 78e0 <g_st>
                break; }
    1f7c:	cd9ff06f          	j	1c54 <main+0xb50>
                if (r == ST_WAIT_TIMEO) { blt_recover("clip fence", STW_CLIP); break; }
    1f80:	00200593          	li	a1,2
    1f84:	00007537          	lui	a0,0x7
    1f88:	34c50513          	addi	a0,a0,844 # 734c <_data+0x1398>
    1f8c:	295030ef          	jal	5a20 <blt_recover>
    1f90:	cc5ff06f          	j	1c54 <main+0xb50>
                else                clip_off();
    1f94:	425010ef          	jal	3bb8 <clip_off>
    1f98:	fddff06f          	j	1f74 <main+0xe70>

            default: /* ST_WAIT：等本趟内容画完 */
                if (hw_frame_pushed) {
    1f9c:	89c1a783          	lw	a5,-1892(gp) # 78c4 <hw_frame_pushed>
    1fa0:	08078463          	beqz	a5,2028 <main+0xf24>
                    int r = blt_idle_bounded(STW_CONTENT);
    1fa4:	00300513          	li	a0,3
    1fa8:	549010ef          	jal	3cf0 <blt_idle_bounded>
                    if (r == ST_WAIT_TIMEO) { blt_recover("content wait", STW_CONTENT); break; }
    1fac:	00200793          	li	a5,2
    1fb0:	06f50263          	beq	a0,a5,2014 <main+0xf10>
                    if (r != ST_WAIT_IDLE) break;
    1fb4:	00100793          	li	a5,1
    1fb8:	c8f51ee3          	bne	a0,a5,1c54 <main+0xb50>
                    hw_done = 1;
    1fbc:	00100713          	li	a4,1
    1fc0:	88e1ac23          	sw	a4,-1896(gp) # 78c0 <hw_done>
                    /* ★ 1Hz 成本行（与 FinalDemo 同口径同格式）：本趟起点 → 引擎空闲的墙钟拍数 */
                    if (g_cmd_t0 != 0u) {
    1fc4:	8c01a783          	lw	a5,-1856(gp) # 78e8 <g_cmd_t0>
    1fc8:	c80786e3          	beqz	a5,1c54 <main+0xb50>
                        uint32_t now = tick32();
    1fcc:	01d000ef          	jal	27e8 <tick32>
                        if ((uint32_t)(now - g_cost_t0) >= (uint32_t)BSP_CLINT_HZ) {
    1fd0:	8bc1a703          	lw	a4,-1860(gp) # 78e4 <g_cost_t0>
    1fd4:	40e50733          	sub	a4,a0,a4
    1fd8:	05f5e7b7          	lui	a5,0x5f5e
    1fdc:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f40ecf>
    1fe0:	02e7f663          	bgeu	a5,a4,200c <main+0xf08>
                            uint32_t dt = (uint32_t)(now - g_cmd_t0);
    1fe4:	8c01a603          	lw	a2,-1856(gp) # 78e8 <g_cmd_t0>
    1fe8:	40c50633          	sub	a2,a0,a2
                            g_cost_t0 = now;
    1fec:	8aa1ae23          	sw	a0,-1860(gp) # 78e4 <g_cost_t0>
                            bsp_printf("EV cmd path done: n=%d cycles=%d cyc/sprite=%d\r\n",
    1ff0:	8301a583          	lw	a1,-2000(gp) # 7858 <g_n>
    1ff4:	00b05463          	blez	a1,1ffc <main+0xef8>
    1ff8:	02b64433          	div	s0,a2,a1
    1ffc:	00040693          	mv	a3,s0
    2000:	00007537          	lui	a0,0x7
    2004:	36850513          	addi	a0,a0,872 # 7368 <_data+0x13b4>
    2008:	0ac020ef          	jal	40b4 <bsp_printf>
                                       g_n, (int)dt, (g_n > 0) ? ((int)dt / g_n) : 0);
                        }
                        g_cmd_t0 = 0;
    200c:	8c01a023          	sw	zero,-1856(gp) # 78e8 <g_cmd_t0>
    2010:	c45ff06f          	j	1c54 <main+0xb50>
                    if (r == ST_WAIT_TIMEO) { blt_recover("content wait", STW_CONTENT); break; }
    2014:	00300593          	li	a1,3
    2018:	00007537          	lui	a0,0x7
    201c:	35850513          	addi	a0,a0,856 # 7358 <_data+0x13a4>
    2020:	201030ef          	jal	5a20 <blt_recover>
    2024:	c31ff06f          	j	1c54 <main+0xb50>
                    }
                } else {
                    cpu_backoff(BLT_WAIT_NOP);
    2028:	03000513          	li	a0,48
    202c:	7c8000ef          	jal	27f4 <cpu_backoff>
    2030:	c25ff06f          	j	1c54 <main+0xb50>

00002034 <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    2034:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    2038:	01055513          	srli	a0,a0,0x10
    }
    203c:	0ff57513          	zext.b	a0,a0
    2040:	00008067          	ret

00002044 <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    2044:	ff010113          	addi	sp,sp,-16
    2048:	00112623          	sw	ra,12(sp)
    204c:	00812423          	sw	s0,8(sp)
    2050:	00912223          	sw	s1,4(sp)
    2054:	00050413          	mv	s0,a0
    2058:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    205c:	00040513          	mv	a0,s0
    2060:	fd5ff0ef          	jal	2034 <uart_writeAvailability>
    2064:	fe050ce3          	beqz	a0,205c <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    2068:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    206c:	00c12083          	lw	ra,12(sp)
    2070:	00812403          	lw	s0,8(sp)
    2074:	00412483          	lw	s1,4(sp)
    2078:	01010113          	addi	sp,sp,16
    207c:	00008067          	ret

00002080 <uart_applyConfig>:
*          value using data length, parity, and stop bit settings from the configuration
*          structure, and writes this value to the UART frame configuration register.
*
******************************************************************************/
    static void uart_applyConfig(u32 reg, Uart_Config *config){
        write_u32(config->clockDivider, reg + UART_CLOCK_DIVIDER);
    2080:	00c5a783          	lw	a5,12(a1)
    2084:	00f52423          	sw	a5,8(a0)
        write_u32(((config->dataLength-1) << 0) | (config->parity << 8) | (config->stop << 16), reg + UART_FRAME_CONFIG);
    2088:	0005a783          	lw	a5,0(a1)
    208c:	fff78793          	addi	a5,a5,-1
    2090:	0045a703          	lw	a4,4(a1)
    2094:	00871713          	slli	a4,a4,0x8
    2098:	00e7e7b3          	or	a5,a5,a4
    209c:	0085a703          	lw	a4,8(a1)
    20a0:	01071713          	slli	a4,a4,0x10
    20a4:	00e7e7b3          	or	a5,a5,a4
    20a8:	00f52623          	sw	a5,12(a0)
    }
    20ac:	00008067          	ret

000020b0 <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    20b0:	ff010113          	addi	sp,sp,-16
    20b4:	00112623          	sw	ra,12(sp)
    20b8:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    20bc:	f8010537          	lui	a0,0xf8010
    20c0:	f85ff0ef          	jal	2044 <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    20c4:	00c12083          	lw	ra,12(sp)
    20c8:	01010113          	addi	sp,sp,16
    20cc:	00008067          	ret

000020d0 <_putchar_s>:

    static void _putchar_s(char *p)
    {
    20d0:	ff010113          	addi	sp,sp,-16
    20d4:	00112623          	sw	ra,12(sp)
    20d8:	00812423          	sw	s0,8(sp)
    20dc:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    20e0:	00c0006f          	j	20ec <_putchar_s+0x1c>
            _putchar(*(p++));
    20e4:	00140413          	addi	s0,s0,1
    20e8:	fc9ff0ef          	jal	20b0 <_putchar>
        while (*p)
    20ec:	00044503          	lbu	a0,0(s0)
    20f0:	fe051ae3          	bnez	a0,20e4 <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    20f4:	00c12083          	lw	ra,12(sp)
    20f8:	00812403          	lw	s0,8(sp)
    20fc:	01010113          	addi	sp,sp,16
    2100:	00008067          	ret

00002104 <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    2104:	ff010113          	addi	sp,sp,-16
    2108:	00112623          	sw	ra,12(sp)
    210c:	00812423          	sw	s0,8(sp)
    2110:	00912223          	sw	s1,4(sp)
    2114:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2118:	01c00413          	li	s0,28
    211c:	0240006f          	j	2140 <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    2120:	0084d733          	srl	a4,s1,s0
    2124:	00f77713          	andi	a4,a4,15
    2128:	000067b7          	lui	a5,0x6
    212c:	fb478793          	addi	a5,a5,-76 # 5fb4 <_data>
    2130:	00e787b3          	add	a5,a5,a4
    2134:	0007c503          	lbu	a0,0(a5)
    2138:	f79ff0ef          	jal	20b0 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    213c:	ffc40413          	addi	s0,s0,-4
    2140:	fe0450e3          	bgez	s0,2120 <bsp_printHex+0x1c>
        }
    }
    2144:	00c12083          	lw	ra,12(sp)
    2148:	00812403          	lw	s0,8(sp)
    214c:	00412483          	lw	s1,4(sp)
    2150:	01010113          	addi	sp,sp,16
    2154:	00008067          	ret

00002158 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    2158:	ff010113          	addi	sp,sp,-16
    215c:	00112623          	sw	ra,12(sp)
    2160:	00812423          	sw	s0,8(sp)
    2164:	00912223          	sw	s1,4(sp)
    2168:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    216c:	01c00413          	li	s0,28
    2170:	0240006f          	j	2194 <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    2174:	0084d733          	srl	a4,s1,s0
    2178:	00f77713          	andi	a4,a4,15
    217c:	000067b7          	lui	a5,0x6
    2180:	fc878793          	addi	a5,a5,-56 # 5fc8 <_data+0x14>
    2184:	00e787b3          	add	a5,a5,a4
    2188:	0007c503          	lbu	a0,0(a5)
    218c:	f25ff0ef          	jal	20b0 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    2190:	ffc40413          	addi	s0,s0,-4
    2194:	fe0450e3          	bgez	s0,2174 <bsp_printHex_lower+0x1c>

        }
    }
    2198:	00c12083          	lw	ra,12(sp)
    219c:	00812403          	lw	s0,8(sp)
    21a0:	00412483          	lw	s1,4(sp)
    21a4:	01010113          	addi	sp,sp,16
    21a8:	00008067          	ret

000021ac <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    21ac:	ff010113          	addi	sp,sp,-16
    21b0:	00112623          	sw	ra,12(sp)
        _putchar(c);
    21b4:	0ff57513          	zext.b	a0,a0
    21b8:	ef9ff0ef          	jal	20b0 <_putchar>
    }
    21bc:	00c12083          	lw	ra,12(sp)
    21c0:	01010113          	addi	sp,sp,16
    21c4:	00008067          	ret

000021c8 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    21c8:	ff010113          	addi	sp,sp,-16
    21cc:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    21d0:	f01ff0ef          	jal	20d0 <_putchar_s>
    }
    21d4:	00c12083          	lw	ra,12(sp)
    21d8:	01010113          	addi	sp,sp,16
    21dc:	00008067          	ret

000021e0 <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    21e0:	fd010113          	addi	sp,sp,-48
    21e4:	02112623          	sw	ra,44(sp)
    21e8:	02812423          	sw	s0,40(sp)
    21ec:	02912223          	sw	s1,36(sp)
    21f0:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    21f4:	00054663          	bltz	a0,2200 <bsp_printf_d+0x20>
    {
    21f8:	00010413          	mv	s0,sp
    21fc:	02c0006f          	j	2228 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    2200:	02d00513          	li	a0,45
    2204:	fa9ff0ef          	jal	21ac <bsp_printf_c>
            val = -val;
    2208:	409004b3          	neg	s1,s1
    220c:	fedff06f          	j	21f8 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    2210:	00a00713          	li	a4,10
    2214:	02e4e7b3          	rem	a5,s1,a4
    2218:	03078793          	addi	a5,a5,48
    221c:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    2220:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    2224:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    2228:	fe0494e3          	bnez	s1,2210 <bsp_printf_d+0x30>
    222c:	00010793          	mv	a5,sp
    2230:	fef400e3          	beq	s0,a5,2210 <bsp_printf_d+0x30>
        }
        while (p != buffer)
    2234:	00010793          	mv	a5,sp
    2238:	00f40a63          	beq	s0,a5,224c <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    223c:	fff40413          	addi	s0,s0,-1
    2240:	00044503          	lbu	a0,0(s0)
    2244:	f69ff0ef          	jal	21ac <bsp_printf_c>
    2248:	fedff06f          	j	2234 <bsp_printf_d+0x54>
    }
    224c:	02c12083          	lw	ra,44(sp)
    2250:	02812403          	lw	s0,40(sp)
    2254:	02412483          	lw	s1,36(sp)
    2258:	03010113          	addi	sp,sp,48
    225c:	00008067          	ret

00002260 <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    2260:	ff010113          	addi	sp,sp,-16
    2264:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    2268:	00000713          	li	a4,0
    226c:	00700793          	li	a5,7
    2270:	02e7c063          	blt	a5,a4,2290 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    2274:	00271693          	slli	a3,a4,0x2
    2278:	ff000793          	li	a5,-16
    227c:	00d797b3          	sll	a5,a5,a3
    2280:	00f577b3          	and	a5,a0,a5
    2284:	00078663          	beqz	a5,2290 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    2288:	00170713          	addi	a4,a4,1
    228c:	fe1ff06f          	j	226c <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    2290:	ec9ff0ef          	jal	2158 <bsp_printHex_lower>
    }
    2294:	00c12083          	lw	ra,12(sp)
    2298:	01010113          	addi	sp,sp,16
    229c:	00008067          	ret

000022a0 <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    22a0:	ff010113          	addi	sp,sp,-16
    22a4:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    22a8:	00000713          	li	a4,0
    22ac:	00700793          	li	a5,7
    22b0:	02e7c063          	blt	a5,a4,22d0 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    22b4:	00271693          	slli	a3,a4,0x2
    22b8:	ff000793          	li	a5,-16
    22bc:	00d797b3          	sll	a5,a5,a3
    22c0:	00f577b3          	and	a5,a0,a5
    22c4:	00078663          	beqz	a5,22d0 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    22c8:	00170713          	addi	a4,a4,1
    22cc:	fe1ff06f          	j	22ac <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    22d0:	e35ff0ef          	jal	2104 <bsp_printHex>
        }
    22d4:	00c12083          	lw	ra,12(sp)
    22d8:	01010113          	addi	sp,sp,16
    22dc:	00008067          	ret

000022e0 <bsp_init>:
    *   1. UART baudrate
    *   2. 
    */
////////////////////////////////////////////////////////////////////////////////
    static void bsp_init()
    {
    22e0:	fe010113          	addi	sp,sp,-32
    22e4:	00112e23          	sw	ra,28(sp)
        Uart_Config uartConfig;
        uartConfig.dataLength   = BITS_8;
    22e8:	00800793          	li	a5,8
    22ec:	00f12023          	sw	a5,0(sp)
        uartConfig.parity       = NONE;
    22f0:	00012223          	sw	zero,4(sp)
        uartConfig.stop         = ONE;
    22f4:	00012423          	sw	zero,8(sp)
        uartConfig.clockDivider = BSP_CLINT_HZ/(BSP_UART_BAUDRATE*BSP_UART_DATA_LEN)-1;
    22f8:	06b00793          	li	a5,107
    22fc:	00f12623          	sw	a5,12(sp)
        uart_applyConfig(BSP_UART_TERMINAL, &uartConfig);    
    2300:	00010593          	mv	a1,sp
    2304:	f8010537          	lui	a0,0xf8010
    2308:	d79ff0ef          	jal	2080 <uart_applyConfig>
    }
    230c:	01c12083          	lw	ra,28(sp)
    2310:	02010113          	addi	sp,sp,32
    2314:	00008067          	ret

00002318 <attr_word>:
    return ((uint32_t)(blend & 0xFu) << 0)
    2318:	00f57513          	andi	a0,a0,15
         | ((uint32_t)(fmt   & 0x3u) << 4)
    231c:	00459593          	slli	a1,a1,0x4
    2320:	0305f593          	andi	a1,a1,48
    2324:	00b56533          	or	a0,a0,a1
         | ((uint32_t)(ga    & 0xFFu) << 6)
    2328:	00661613          	slli	a2,a2,0x6
    232c:	000047b7          	lui	a5,0x4
    2330:	fc078793          	addi	a5,a5,-64 # 3fc0 <content_plan+0x78>
    2334:	00f67633          	and	a2,a2,a5
    2338:	00c56533          	or	a0,a0,a2
         | ((uint32_t)(flags & 0x3u) << 24);
    233c:	01869693          	slli	a3,a3,0x18
    2340:	030007b7          	lui	a5,0x3000
    2344:	00f6f6b3          	and	a3,a3,a5
}
    2348:	00d56533          	or	a0,a0,a3
    234c:	00008067          	ret

00002350 <attr_blend>:
static unsigned attr_blend(uint32_t w) { return (unsigned)(w & 0xFu); }
    2350:	00f57513          	andi	a0,a0,15
    2354:	00008067          	ret

00002358 <attr_fmt>:
static unsigned attr_fmt(uint32_t w)   { return (unsigned)((w >> 4) & 0x3u); }
    2358:	00455513          	srli	a0,a0,0x4
    235c:	00357513          	andi	a0,a0,3
    2360:	00008067          	ret

00002364 <attr_ga>:
static unsigned attr_ga(uint32_t w)    { return (unsigned)((w >> 6) & 0xFFu); }
    2364:	00655513          	srli	a0,a0,0x6
    2368:	0ff57513          	zext.b	a0,a0
    236c:	00008067          	ret

00002370 <attr_flags>:
static unsigned attr_flags(uint32_t w) { return (unsigned)((w >> 24) & 0x3u); }
    2370:	01855513          	srli	a0,a0,0x18
    2374:	00357513          	andi	a0,a0,3
    2378:	00008067          	ret

0000237c <argb4444_pack>:
    return (uint16_t)(((a4 & A4444_MASK) << A4444_A_SH) |
    237c:	00c51513          	slli	a0,a0,0xc
    2380:	01051513          	slli	a0,a0,0x10
    2384:	01055513          	srli	a0,a0,0x10
                      ((r4 & A4444_MASK) << A4444_R_SH) |
    2388:	00859593          	slli	a1,a1,0x8
    238c:	000017b7          	lui	a5,0x1
    2390:	f0078793          	addi	a5,a5,-256 # f00 <CUSTOM2+0xea5>
    2394:	00f5f5b3          	and	a1,a1,a5
    return (uint16_t)(((a4 & A4444_MASK) << A4444_A_SH) |
    2398:	00b56533          	or	a0,a0,a1
                      ((g4 & A4444_MASK) << A4444_G_SH) |
    239c:	00461613          	slli	a2,a2,0x4
    23a0:	0f067613          	andi	a2,a2,240
                      ((r4 & A4444_MASK) << A4444_R_SH) |
    23a4:	00c56533          	or	a0,a0,a2
                      ((b4 & A4444_MASK) << A4444_B_SH));
    23a8:	00f6f693          	andi	a3,a3,15
}
    23ac:	00d56533          	or	a0,a0,a3
    23b0:	00008067          	ret

000023b4 <argb4444_a>:
static unsigned argb4444_a(uint16_t c) { return (unsigned)((c >> A4444_A_SH) & A4444_MASK); }
    23b4:	00c55513          	srli	a0,a0,0xc
    23b8:	00008067          	ret

000023bc <argb4444_r>:
static unsigned argb4444_r(uint16_t c) { return (unsigned)((c >> A4444_R_SH) & A4444_MASK); }
    23bc:	00855513          	srli	a0,a0,0x8
    23c0:	00f57513          	andi	a0,a0,15
    23c4:	00008067          	ret

000023c8 <argb4444_g>:
static unsigned argb4444_g(uint16_t c) { return (unsigned)((c >> A4444_G_SH) & A4444_MASK); }
    23c8:	00455513          	srli	a0,a0,0x4
    23cc:	00f57513          	andi	a0,a0,15
    23d0:	00008067          	ret

000023d4 <argb4444_b>:
static unsigned argb4444_b(uint16_t c) { return (unsigned)((c >> A4444_B_SH) & A4444_MASK); }
    23d4:	00f57513          	andi	a0,a0,15
    23d8:	00008067          	ret

000023dc <rep4to8>:
static unsigned rep4to8(unsigned v4) { v4 &= A4444_MASK; return (v4 << 4) | v4; }
    23dc:	00f57513          	andi	a0,a0,15
    23e0:	00451793          	slli	a5,a0,0x4
    23e4:	00a7e533          	or	a0,a5,a0
    23e8:	00008067          	ret

000023ec <lut_chan>:
    unsigned x = (v * fade + 127u) / 255u;
    23ec:	02b50533          	mul	a0,a0,a1
    23f0:	07f50513          	addi	a0,a0,127 # f801007f <__freertos_irq_stack_top+0xf7ff2e4f>
    23f4:	0ff00793          	li	a5,255
    23f8:	02f557b3          	divu	a5,a0,a5
    if (x > 255u) x = 255u;
    23fc:	00010737          	lui	a4,0x10
    2400:	eff70713          	addi	a4,a4,-257 # feff <__global_pointer$+0x7ed7>
    2404:	00a77463          	bgeu	a4,a0,240c <lut_chan+0x20>
    2408:	0ff00793          	li	a5,255
    x = x + ((255u - x) * flash + 127u) / 255u;
    240c:	0ff00713          	li	a4,255
    2410:	40f70533          	sub	a0,a4,a5
    2414:	02c50533          	mul	a0,a0,a2
    2418:	07f50513          	addi	a0,a0,127
    241c:	02e55533          	divu	a0,a0,a4
    2420:	00f50533          	add	a0,a0,a5
    if (x > 255u) x = 255u;
    2424:	00a76463          	bltu	a4,a0,242c <lut_chan+0x40>
}
    2428:	00008067          	ret
    if (x > 255u) x = 255u;
    242c:	0ff00513          	li	a0,255
    return x;
    2430:	00008067          	ret

00002434 <lut_addr>:
    return ((uint32_t)(ch & 3u) << BLT_LUT_CH_SH) | (uint32_t)(idx & 0xFFu);
    2434:	00851513          	slli	a0,a0,0x8
    2438:	30057513          	andi	a0,a0,768
    243c:	0ff5f593          	zext.b	a1,a1
}
    2440:	00b56533          	or	a0,a0,a1
    2444:	00008067          	ret

00002448 <lut_write_bank>:
static unsigned lut_write_bank(unsigned stat) { return (unsigned)(stat & 1u) ^ 1u; }
    2448:	00154513          	xori	a0,a0,1
    244c:	00157513          	andi	a0,a0,1
    2450:	00008067          	ret

00002454 <fx_elapsed_ms>:
    return (uint32_t)((now - t0) / MS_TICKS);
    2454:	40b50533          	sub	a0,a0,a1
    2458:	000187b7          	lui	a5,0x18
    245c:	6a078793          	addi	a5,a5,1696 # 186a0 <__global_pointer$+0x10678>
}
    2460:	02f55533          	divu	a0,a0,a5
    2464:	00008067          	ret

00002468 <fx_fade_of_ms>:
    ph_ms = ph_ms % FADE_PERIOD_MS;
    2468:	000017b7          	lui	a5,0x1
    246c:	e1078793          	addi	a5,a5,-496 # e10 <CUSTOM2+0xdb5>
    2470:	02f57533          	remu	a0,a0,a5
    if (ph_ms < 1200u) return 255u - (unsigned)((ph_ms * 255u) / 1200u);
    2474:	4af00793          	li	a5,1199
    2478:	02a7f063          	bgeu	a5,a0,2498 <fx_fade_of_ms+0x30>
    if (ph_ms < 1500u) return 0u;
    247c:	5db00793          	li	a5,1499
    2480:	04a7fa63          	bgeu	a5,a0,24d4 <fx_fade_of_ms+0x6c>
    if (ph_ms < 2700u) return (unsigned)(((ph_ms - 1500u) * 255u) / 1200u);
    2484:	000017b7          	lui	a5,0x1
    2488:	a8b78793          	addi	a5,a5,-1397 # a8b <CUSTOM2+0xa30>
    248c:	02a7f463          	bgeu	a5,a0,24b4 <fx_fade_of_ms+0x4c>
    return 255u;
    2490:	0ff00513          	li	a0,255
}
    2494:	00008067          	ret
    if (ph_ms < 1200u) return 255u - (unsigned)((ph_ms * 255u) / 1200u);
    2498:	00851793          	slli	a5,a0,0x8
    249c:	40a787b3          	sub	a5,a5,a0
    24a0:	4b000713          	li	a4,1200
    24a4:	02e7d7b3          	divu	a5,a5,a4
    24a8:	0ff00513          	li	a0,255
    24ac:	40f50533          	sub	a0,a0,a5
    24b0:	00008067          	ret
    if (ph_ms < 2700u) return (unsigned)(((ph_ms - 1500u) * 255u) / 1200u);
    24b4:	00851793          	slli	a5,a0,0x8
    24b8:	40a78533          	sub	a0,a5,a0
    24bc:	fffa37b7          	lui	a5,0xfffa3
    24c0:	9dc78793          	addi	a5,a5,-1572 # fffa29dc <__freertos_irq_stack_top+0xfff857ac>
    24c4:	00f50533          	add	a0,a0,a5
    24c8:	4b000793          	li	a5,1200
    24cc:	02f55533          	divu	a0,a0,a5
    24d0:	00008067          	ret
    if (ph_ms < 1500u) return 0u;
    24d4:	00000513          	li	a0,0
    24d8:	00008067          	ret

000024dc <fx_flash_of_ms>:
    if (left_ms > FLASH_MS) left_ms = FLASH_MS;
    24dc:	0dc00793          	li	a5,220
    24e0:	00a7f463          	bgeu	a5,a0,24e8 <fx_flash_of_ms+0xc>
    24e4:	0dc00513          	li	a0,220
    return (unsigned)((left_ms * 255u) / FLASH_MS);
    24e8:	00851793          	slli	a5,a0,0x8
    24ec:	40a787b3          	sub	a5,a5,a0
}
    24f0:	0dc00513          	li	a0,220
    24f4:	02a7d533          	divu	a0,a5,a0
    24f8:	00008067          	ret

000024fc <blk_idx>:
static int blk_idx(int sz) { int i; for (i = 0; i < BLK_N; i++) if (g_blk_tab[i] == sz) return i; return 0; }
    24fc:	00050693          	mv	a3,a0
    2500:	00000513          	li	a0,0
    2504:	0080006f          	j	250c <blk_idx+0x10>
    2508:	00150513          	addi	a0,a0,1
    250c:	00200793          	li	a5,2
    2510:	02a7c063          	blt	a5,a0,2530 <blk_idx+0x34>
    2514:	000077b7          	lui	a5,0x7
    2518:	00251713          	slli	a4,a0,0x2
    251c:	72c78793          	addi	a5,a5,1836 # 772c <g_blk_tab>
    2520:	00e787b3          	add	a5,a5,a4
    2524:	0007a783          	lw	a5,0(a5)
    2528:	fed790e3          	bne	a5,a3,2508 <blk_idx+0xc>
    252c:	00008067          	ret
    2530:	00000513          	li	a0,0
    2534:	00008067          	ret

00002538 <blk_next>:
static int blk_next(int sz) { return g_blk_tab[(blk_idx(sz) + 1) % BLK_N]; }
    2538:	ff010113          	addi	sp,sp,-16
    253c:	00112623          	sw	ra,12(sp)
    2540:	fbdff0ef          	jal	24fc <blk_idx>
    2544:	00150513          	addi	a0,a0,1
    2548:	00300793          	li	a5,3
    254c:	02f56533          	rem	a0,a0,a5
    2550:	000077b7          	lui	a5,0x7
    2554:	00251513          	slli	a0,a0,0x2
    2558:	72c78793          	addi	a5,a5,1836 # 772c <g_blk_tab>
    255c:	00a787b3          	add	a5,a5,a0
    2560:	0007a503          	lw	a0,0(a5)
    2564:	00c12083          	lw	ra,12(sp)
    2568:	01010113          	addi	sp,sp,16
    256c:	00008067          	ret

00002570 <disc_color>:
    int dx = i - SPR_W / 2, dy = j - SPR_H / 2;
    2570:	85c1a603          	lw	a2,-1956(gp) # 7884 <g_blk>
    2574:	01f65713          	srli	a4,a2,0x1f
    2578:	00c70733          	add	a4,a4,a2
    257c:	40175713          	srai	a4,a4,0x1
    2580:	40e00733          	neg	a4,a4
    2584:	00a706b3          	add	a3,a4,a0
    2588:	00b707b3          	add	a5,a4,a1
    int d2 = dx * dx + dy * dy;
    258c:	02d686b3          	mul	a3,a3,a3
    2590:	02f787b3          	mul	a5,a5,a5
    2594:	00f686b3          	add	a3,a3,a5
    int r2 = (SPR_W / 2) * (SPR_W / 2);
    2598:	02e70833          	mul	a6,a4,a4
    int ri = SPR_W / 2 - SPR_RING;       /* 白环内边界半径（外边界 = SPR_W/2） */
    259c:	41f65793          	srai	a5,a2,0x1f
    25a0:	0077f793          	andi	a5,a5,7
    25a4:	00c787b3          	add	a5,a5,a2
    25a8:	4037d793          	srai	a5,a5,0x3
    25ac:	40f007b3          	neg	a5,a5
    25b0:	40e787b3          	sub	a5,a5,a4
    if (d2 > r2)      return (uint16_t)KEY_COLOR;      /* 圆外（含四角）⇒ 色键 */
    25b4:	06d84863          	blt	a6,a3,2624 <disc_color+0xb4>
    if (d2 > ri * ri) return (uint16_t)COL_WHITE;      /* 白环 */
    25b8:	02f787b3          	mul	a5,a5,a5
    25bc:	06d7ca63          	blt	a5,a3,2630 <disc_color+0xc0>
    rr = (unsigned)((i * 31) / (SPR_W - 1));
    25c0:	00551793          	slli	a5,a0,0x5
    25c4:	40a78533          	sub	a0,a5,a0
    25c8:	fff60613          	addi	a2,a2,-1
    25cc:	02c54533          	div	a0,a0,a2
    gg = (unsigned)((j * 63) / (SPR_H - 1));
    25d0:	00659793          	slli	a5,a1,0x6
    25d4:	40b787b3          	sub	a5,a5,a1
    25d8:	02c7c7b3          	div	a5,a5,a2
    bb = (unsigned)(31 - ((d2 * 31) / (r2 ? r2 : 1)));
    25dc:	00569713          	slli	a4,a3,0x5
    25e0:	40d70733          	sub	a4,a4,a3
    25e4:	00081463          	bnez	a6,25ec <disc_color+0x7c>
    25e8:	00100813          	li	a6,1
    25ec:	03074733          	div	a4,a4,a6
    25f0:	01f00693          	li	a3,31
    25f4:	40e68733          	sub	a4,a3,a4
    return (uint16_t)((rr << 11) | (gg << 5) | bb);
    25f8:	00b51513          	slli	a0,a0,0xb
    25fc:	01051513          	slli	a0,a0,0x10
    2600:	01055513          	srli	a0,a0,0x10
    2604:	00579793          	slli	a5,a5,0x5
    2608:	01079793          	slli	a5,a5,0x10
    260c:	0107d793          	srli	a5,a5,0x10
    2610:	00f56533          	or	a0,a0,a5
    2614:	00e56533          	or	a0,a0,a4
    2618:	01051513          	slli	a0,a0,0x10
    261c:	01055513          	srli	a0,a0,0x10
    2620:	00008067          	ret
    if (d2 > r2)      return (uint16_t)KEY_COLOR;      /* 圆外（含四角）⇒ 色键 */
    2624:	00010537          	lui	a0,0x10
    2628:	81f50513          	addi	a0,a0,-2017 # f81f <__global_pointer$+0x77f7>
    262c:	00008067          	ret
    if (d2 > ri * ri) return (uint16_t)COL_WHITE;      /* 白环 */
    2630:	00010537          	lui	a0,0x10
    2634:	fff50513          	addi	a0,a0,-1 # ffff <__global_pointer$+0x7fd7>
}
    2638:	00008067          	ret

0000263c <glow_color>:
    int dx = i * 2 - SPR_W + 1, dy = j * 2 - SPR_H + 1;   /* 以中心为原点（x2 提精度） */
    263c:	00151793          	slli	a5,a0,0x1
    2640:	85c1a703          	lw	a4,-1956(gp) # 7884 <g_blk>
    2644:	40e787b3          	sub	a5,a5,a4
    2648:	00178793          	addi	a5,a5,1
    264c:	00159593          	slli	a1,a1,0x1
    2650:	40e585b3          	sub	a1,a1,a4
    2654:	00158593          	addi	a1,a1,1
    int d2 = dx * dx + dy * dy;
    2658:	02f787b3          	mul	a5,a5,a5
    265c:	02b585b3          	mul	a1,a1,a1
    2660:	00b787b3          	add	a5,a5,a1
    int r2 = SPR_W * SPR_W;
    2664:	02e70733          	mul	a4,a4,a4
    if (d2 >= r2) return 0x0000u;                    /* 圆外：全透明（加算 = 无贡献） */
    2668:	12e7d263          	bge	a5,a4,278c <glow_color+0x150>
{
    266c:	ff010113          	addi	sp,sp,-16
    2670:	00112623          	sw	ra,12(sp)
    t = (unsigned)((d2 * 255) / r2);                 /* 0 = 圆心，255 = 边缘 */
    2674:	00879693          	slli	a3,a5,0x8
    2678:	40f687b3          	sub	a5,a3,a5
    267c:	02e7c7b3          	div	a5,a5,a4
    a = 255u - t;
    2680:	0ff00693          	li	a3,255
    2684:	40f68733          	sub	a4,a3,a5
    a = (a * a) / 255u;                              /* 平方衰减：中心亮、边缘柔 */
    2688:	02e70733          	mul	a4,a4,a4
    268c:	02d75733          	divu	a4,a4,a3
    switch (v & 3) {
    2690:	00367613          	andi	a2,a2,3
    2694:	00100693          	li	a3,1
    2698:	04d60c63          	beq	a2,a3,26f0 <glow_color+0xb4>
    269c:	00200693          	li	a3,2
    26a0:	08d60263          	beq	a2,a3,2724 <glow_color+0xe8>
    26a4:	0a061c63          	bnez	a2,275c <glow_color+0x120>
    case 0:  r4 = 15u; g4 = 15u - (t * 10u) / 255u; b4 = 15u - (t * 14u) / 255u; break; /* 暖白 */
    26a8:	00279613          	slli	a2,a5,0x2
    26ac:	00f60633          	add	a2,a2,a5
    26b0:	00161613          	slli	a2,a2,0x1
    26b4:	0ff00513          	li	a0,255
    26b8:	02a65633          	divu	a2,a2,a0
    26bc:	00f00693          	li	a3,15
    26c0:	40c68633          	sub	a2,a3,a2
    26c4:	00379593          	slli	a1,a5,0x3
    26c8:	40f587b3          	sub	a5,a1,a5
    26cc:	00179793          	slli	a5,a5,0x1
    26d0:	02a7d7b3          	divu	a5,a5,a0
    26d4:	40f686b3          	sub	a3,a3,a5
    26d8:	00f00593          	li	a1,15
    return argb4444_pack(a >> 4, r4, g4, b4);        /* ★ A[15:12] R[11:8] G[7:4] B[3:0] */
    26dc:	00475513          	srli	a0,a4,0x4
    26e0:	c9dff0ef          	jal	237c <argb4444_pack>
}
    26e4:	00c12083          	lw	ra,12(sp)
    26e8:	01010113          	addi	sp,sp,16
    26ec:	00008067          	ret
    case 1:  r4 = 15u - (t * 12u) / 255u; g4 = 15u - (t * 6u) / 255u;  b4 = 15u; break; /* 青 */
    26f0:	00179693          	slli	a3,a5,0x1
    26f4:	00f685b3          	add	a1,a3,a5
    26f8:	00259593          	slli	a1,a1,0x2
    26fc:	0ff00513          	li	a0,255
    2700:	02a5d5b3          	divu	a1,a1,a0
    2704:	00f00613          	li	a2,15
    2708:	40b605b3          	sub	a1,a2,a1
    270c:	00f686b3          	add	a3,a3,a5
    2710:	00169693          	slli	a3,a3,0x1
    2714:	02a6d6b3          	divu	a3,a3,a0
    2718:	40d60633          	sub	a2,a2,a3
    271c:	00f00693          	li	a3,15
    2720:	fbdff06f          	j	26dc <glow_color+0xa0>
    case 2:  r4 = 15u; g4 = 15u - (t * 13u) / 255u; b4 = 15u - (t * 6u) / 255u;  break; /* 品红 */
    2724:	00179593          	slli	a1,a5,0x1
    2728:	00f58633          	add	a2,a1,a5
    272c:	00261613          	slli	a2,a2,0x2
    2730:	00f60633          	add	a2,a2,a5
    2734:	0ff00513          	li	a0,255
    2738:	02a65633          	divu	a2,a2,a0
    273c:	00f00693          	li	a3,15
    2740:	40c68633          	sub	a2,a3,a2
    2744:	00f585b3          	add	a1,a1,a5
    2748:	00159593          	slli	a1,a1,0x1
    274c:	02a5d5b3          	divu	a1,a1,a0
    2750:	40b686b3          	sub	a3,a3,a1
    2754:	00f00593          	li	a1,15
    2758:	f85ff06f          	j	26dc <glow_color+0xa0>
    default: r4 = 15u - (t * 8u) / 255u; g4 = 15u; b4 = 15u - (t * 10u) / 255u;  break; /* 绿 */
    275c:	00379593          	slli	a1,a5,0x3
    2760:	0ff00513          	li	a0,255
    2764:	02a5d5b3          	divu	a1,a1,a0
    2768:	00f00693          	li	a3,15
    276c:	40b685b3          	sub	a1,a3,a1
    2770:	00279613          	slli	a2,a5,0x2
    2774:	00f607b3          	add	a5,a2,a5
    2778:	00179793          	slli	a5,a5,0x1
    277c:	02a7d7b3          	divu	a5,a5,a0
    2780:	40f686b3          	sub	a3,a3,a5
    2784:	00f00613          	li	a2,15
    2788:	f55ff06f          	j	26dc <glow_color+0xa0>
    if (d2 >= r2) return 0x0000u;                    /* 圆外：全透明（加算 = 无贡献） */
    278c:	00000513          	li	a0,0
}
    2790:	00008067          	ret

00002794 <glyph_idx>:
{
    2794:	00050693          	mv	a3,a0
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    2798:	f9f50793          	addi	a5,a0,-97
    279c:	0ff7f793          	zext.b	a5,a5
    27a0:	01900713          	li	a4,25
    27a4:	00f76663          	bltu	a4,a5,27b0 <glyph_idx+0x1c>
    27a8:	fe050693          	addi	a3,a0,-32
    27ac:	0ff6f693          	zext.b	a3,a3
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return i;
    27b0:	00000513          	li	a0,0
    27b4:	02900793          	li	a5,41
    27b8:	02a7c463          	blt	a5,a0,27e0 <glyph_idx+0x4c>
    27bc:	000077b7          	lui	a5,0x7
    27c0:	00351713          	slli	a4,a0,0x3
    27c4:	00a70733          	add	a4,a4,a0
    27c8:	5b078793          	addi	a5,a5,1456 # 75b0 <g_font>
    27cc:	00e787b3          	add	a5,a5,a4
    27d0:	0007c783          	lbu	a5,0(a5)
    27d4:	00d78863          	beq	a5,a3,27e4 <glyph_idx+0x50>
    27d8:	00150513          	addi	a0,a0,1
    27dc:	fd9ff06f          	j	27b4 <glyph_idx+0x20>
    return 0;                                /* 未定义字符 → 空格（画面上只是少笔画） */
    27e0:	00000513          	li	a0,0
}
    27e4:	00008067          	ret

000027e8 <tick32>:
        return *((volatile u32*) address);
    27e8:	f8b0c7b7          	lui	a5,0xf8b0c
    27ec:	ff87a503          	lw	a0,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8aeedc8>
static uint32_t tick32(void) { return clint_getTimeLow(BSP_CLINT); }
    27f0:	00008067          	ret

000027f4 <cpu_backoff>:
    if (n == 0u) return;
    27f4:	00050663          	beqz	a0,2800 <cpu_backoff+0xc>
    __asm__ __volatile__ (
    27f8:	fff50513          	addi	a0,a0,-1
    27fc:	fe051ee3          	bnez	a0,27f8 <cpu_backoff+0x4>
}
    2800:	00008067          	ret

00002804 <blt_wr>:
static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
    2804:	f81007b7          	lui	a5,0xf8100
    2808:	00f50533          	add	a0,a0,a5
    280c:	00b52023          	sw	a1,0(a0)
    2810:	00008067          	ret

00002814 <blt_rd>:
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }
    2814:	f81007b7          	lui	a5,0xf8100
    2818:	00f50533          	add	a0,a0,a5
    281c:	00052503          	lw	a0,0(a0)
    2820:	00008067          	ret

00002824 <fb_of_sel>:
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
    2824:	00200793          	li	a5,2
    2828:	00f50e63          	beq	a0,a5,2844 <fb_of_sel+0x20>
    282c:	00100793          	li	a5,1
    2830:	00f50663          	beq	a0,a5,283c <fb_of_sel+0x18>
    2834:	00301537          	lui	a0,0x301
}
    2838:	00008067          	ret
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
    283c:	00501537          	lui	a0,0x501
    2840:	00008067          	ret
    2844:	00701537          	lui	a0,0x701
    2848:	00008067          	ret

0000284c <fb_stat_sel>:
static uint32_t fb_stat_sel(void) { return blt_rd(BLT_FB_STAT) & 3UL; }
    284c:	ff010113          	addi	sp,sp,-16
    2850:	00112623          	sw	ra,12(sp)
    2854:	02800513          	li	a0,40
    2858:	fbdff0ef          	jal	2814 <blt_rd>
    285c:	00357513          	andi	a0,a0,3
    2860:	00c12083          	lw	ra,12(sp)
    2864:	01010113          	addi	sp,sp,16
    2868:	00008067          	ret

0000286c <clr_stat>:
static uint32_t clr_stat(void)  { return blt_rd(BLT_CLR_STAT); }
    286c:	ff010113          	addi	sp,sp,-16
    2870:	00112623          	sw	ra,12(sp)
    2874:	04000513          	li	a0,64
    2878:	f9dff0ef          	jal	2814 <blt_rd>
    287c:	00c12083          	lw	ra,12(sp)
    2880:	01010113          	addi	sp,sp,16
    2884:	00008067          	ret

00002888 <clr_busy>:
static int      clr_busy(void)  { return (clr_stat() & BLT_CLR_STAT_BUSY) ? 1 : 0; }
    2888:	ff010113          	addi	sp,sp,-16
    288c:	00112623          	sw	ra,12(sp)
    2890:	fddff0ef          	jal	286c <clr_stat>
    2894:	00157513          	andi	a0,a0,1
    2898:	00c12083          	lw	ra,12(sp)
    289c:	01010113          	addi	sp,sp,16
    28a0:	00008067          	ret

000028a4 <clr_is_clean>:
static int      clr_is_clean(uint32_t k) { return (int)((clr_stat() >> (2u + k)) & 1u); }
    28a4:	ff010113          	addi	sp,sp,-16
    28a8:	00112623          	sw	ra,12(sp)
    28ac:	00812423          	sw	s0,8(sp)
    28b0:	00050413          	mv	s0,a0
    28b4:	fb9ff0ef          	jal	286c <clr_stat>
    28b8:	00240413          	addi	s0,s0,2
    28bc:	00855533          	srl	a0,a0,s0
    28c0:	00157513          	andi	a0,a0,1
    28c4:	00c12083          	lw	ra,12(sp)
    28c8:	00812403          	lw	s0,8(sp)
    28cc:	01010113          	addi	sp,sp,16
    28d0:	00008067          	ret

000028d4 <clr_wait_idle>:
{
    28d4:	ff010113          	addi	sp,sp,-16
    28d8:	00112623          	sw	ra,12(sp)
    28dc:	00812423          	sw	s0,8(sp)
    28e0:	00912223          	sw	s1,4(sp)
    uint32_t t0 = tick32();
    28e4:	f05ff0ef          	jal	27e8 <tick32>
    28e8:	00050493          	mv	s1,a0
{
    28ec:	00000413          	li	s0,0
    while (clr_busy()) {
    28f0:	f99ff0ef          	jal	2888 <clr_busy>
    28f4:	04050263          	beqz	a0,2938 <clr_wait_idle+0x64>
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
    28f8:	ef1ff0ef          	jal	27e8 <tick32>
    28fc:	40950533          	sub	a0,a0,s1
    2900:	000f47b7          	lui	a5,0xf4
    2904:	24078793          	addi	a5,a5,576 # f4240 <__freertos_irq_stack_top+0xd7010>
    2908:	00a7ee63          	bltu	a5,a0,2924 <clr_wait_idle+0x50>
        if (++guard > 64) { guard = 0; cpu_backoff(48u); }
    290c:	00140413          	addi	s0,s0,1
    2910:	04000793          	li	a5,64
    2914:	fc87dee3          	bge	a5,s0,28f0 <clr_wait_idle+0x1c>
    2918:	03000513          	li	a0,48
    291c:	ed9ff0ef          	jal	27f4 <cpu_backoff>
    2920:	fcdff06f          	j	28ec <clr_wait_idle+0x18>
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
    2924:	9601a783          	lw	a5,-1696(gp) # 7988 <g_clr_to>
    2928:	00178793          	addi	a5,a5,1
    292c:	96f1a023          	sw	a5,-1696(gp) # 7988 <g_clr_to>
    2930:	00000513          	li	a0,0
    2934:	0080006f          	j	293c <clr_wait_idle+0x68>
    return 1;
    2938:	00100513          	li	a0,1
}
    293c:	00c12083          	lw	ra,12(sp)
    2940:	00812403          	lw	s0,8(sp)
    2944:	00412483          	lw	s1,4(sp)
    2948:	01010113          	addi	sp,sp,16
    294c:	00008067          	ret

00002950 <clr_start>:
{
    2950:	ff010113          	addi	sp,sp,-16
    2954:	00112623          	sw	ra,12(sp)
    2958:	00812423          	sw	s0,8(sp)
    295c:	00912223          	sw	s1,4(sp)
    2960:	01212023          	sw	s2,0(sp)
    2964:	00050413          	mv	s0,a0
    2968:	00058913          	mv	s2,a1
    296c:	00060493          	mv	s1,a2
    blt_wr(BLT_CLR_ADDR,   fb_of_sel(k) + (uint32_t)y0 * FB_STRIDE);
    2970:	eb5ff0ef          	jal	2824 <fb_of_sel>
    2974:	00491793          	slli	a5,s2,0x4
    2978:	412787b3          	sub	a5,a5,s2
    297c:	00779793          	slli	a5,a5,0x7
    2980:	00f505b3          	add	a1,a0,a5
    2984:	02c00513          	li	a0,44
    2988:	e7dff0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CLR_STRIDE, FB_STRIDE);
    298c:	78000593          	li	a1,1920
    2990:	03000513          	li	a0,48
    2994:	e71ff0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CLR_WH,     ((uint32_t)h << 16) | (uint32_t)FB_WIDTH);
    2998:	01049593          	slli	a1,s1,0x10
    299c:	3c05e593          	ori	a1,a1,960
    29a0:	03400513          	li	a0,52
    29a4:	e61ff0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CLR_COLOR,  COL_BG);
    29a8:	00800593          	li	a1,8
    29ac:	03800513          	li	a0,56
    29b0:	e55ff0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CLR_CTRL,   ((uint32_t)k << 2) | BLT_CLR_GO);
    29b4:	00241593          	slli	a1,s0,0x2
    29b8:	0015e593          	ori	a1,a1,1
    29bc:	03c00513          	li	a0,60
    29c0:	e45ff0ef          	jal	2804 <blt_wr>
}
    29c4:	00c12083          	lw	ra,12(sp)
    29c8:	00812403          	lw	s0,8(sp)
    29cc:	00412483          	lw	s1,4(sp)
    29d0:	00012903          	lw	s2,0(sp)
    29d4:	01010113          	addi	sp,sp,16
    29d8:	00008067          	ret

000029dc <hw_pass_arm>:
{
    29dc:	fe010113          	addi	sp,sp,-32
    29e0:	00112e23          	sw	ra,28(sp)
    29e4:	00812c23          	sw	s0,24(sp)
    29e8:	00912a23          	sw	s1,20(sp)
    29ec:	01212823          	sw	s2,16(sp)
    29f0:	01312623          	sw	s3,12(sp)
    29f4:	01412423          	sw	s4,8(sp)
    29f8:	00050a13          	mv	s4,a0
    29fc:	00058993          	mv	s3,a1
    2a00:	00060493          	mv	s1,a2
    (void)clr_wait_idle();
    2a04:	ed1ff0ef          	jal	28d4 <clr_wait_idle>
    clean_k = clr_is_clean((uint32_t)g_draw3);
    2a08:	8541a503          	lw	a0,-1964(gp) # 787c <g_draw3>
    2a0c:	e99ff0ef          	jal	28a4 <clr_is_clean>
    2a10:	00050413          	mv	s0,a0
    blt_wr(BLT_DRAW_SEL, (uint32_t)g_draw3);
    2a14:	8541a583          	lw	a1,-1964(gp) # 787c <g_draw3>
    2a18:	04400513          	li	a0,68
    2a1c:	de9ff0ef          	jal	2804 <blt_wr>
    if (clr_stat() & BLT_CLR_STAT_ERR) {
    2a20:	e4dff0ef          	jal	286c <clr_stat>
    2a24:	04057793          	andi	a5,a0,64
    2a28:	04079263          	bnez	a5,2a6c <hw_pass_arm+0x90>
    if (want_clr && g_clr_need) { clr_start((uint32_t)g_clr3, y0, h); g_clr_need = 0; }
    2a2c:	06048e63          	beqz	s1,2aa8 <hw_pass_arm+0xcc>
    2a30:	96c1a783          	lw	a5,-1684(gp) # 7994 <g_clr_need>
    2a34:	04079e63          	bnez	a5,2a90 <hw_pass_arm+0xb4>
    if (!clean_k) g_clr_fb++;
    2a38:	00041863          	bnez	s0,2a48 <hw_pass_arm+0x6c>
    2a3c:	9641a783          	lw	a5,-1692(gp) # 798c <g_clr_fb>
    2a40:	00178793          	addi	a5,a5,1
    2a44:	96f1a223          	sw	a5,-1692(gp) # 798c <g_clr_fb>
    return clean_k ? 0 : 1;
    2a48:	00143513          	seqz	a0,s0
}
    2a4c:	01c12083          	lw	ra,28(sp)
    2a50:	01812403          	lw	s0,24(sp)
    2a54:	01412483          	lw	s1,20(sp)
    2a58:	01012903          	lw	s2,16(sp)
    2a5c:	00c12983          	lw	s3,12(sp)
    2a60:	00812a03          	lw	s4,8(sp)
    2a64:	02010113          	addi	sp,sp,32
    2a68:	00008067          	ret
        g_clr_err++;
    2a6c:	95c1a783          	lw	a5,-1700(gp) # 7984 <g_clr_err>
    2a70:	00178793          	addi	a5,a5,1
    2a74:	94f1ae23          	sw	a5,-1700(gp) # 7984 <g_clr_err>
        blt_wr(BLT_CLR_CTRL, ((uint32_t)g_draw3 << 2) | BLT_CLR_ERRCLR);
    2a78:	8541a583          	lw	a1,-1964(gp) # 787c <g_draw3>
    2a7c:	00259593          	slli	a1,a1,0x2
    2a80:	0105e593          	ori	a1,a1,16
    2a84:	03c00513          	li	a0,60
    2a88:	d7dff0ef          	jal	2804 <blt_wr>
    2a8c:	fa1ff06f          	j	2a2c <hw_pass_arm+0x50>
    if (want_clr && g_clr_need) { clr_start((uint32_t)g_clr3, y0, h); g_clr_need = 0; }
    2a90:	00098613          	mv	a2,s3
    2a94:	000a0593          	mv	a1,s4
    2a98:	8501a503          	lw	a0,-1968(gp) # 7878 <g_clr3>
    2a9c:	eb5ff0ef          	jal	2950 <clr_start>
    2aa0:	9601a623          	sw	zero,-1684(gp) # 7994 <g_clr_need>
    2aa4:	f95ff06f          	j	2a38 <hw_pass_arm+0x5c>
    if (!want_clr) return 1;
    2aa8:	00100513          	li	a0,1
    2aac:	fa1ff06f          	j	2a4c <hw_pass_arm+0x70>

00002ab0 <cache_evict>:
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
    2ab0:	00000793          	li	a5,0
    2ab4:	0200006f          	j	2ad4 <cache_evict+0x24>
    2ab8:	00279693          	slli	a3,a5,0x2
    2abc:	00601737          	lui	a4,0x601
    2ac0:	00d70733          	add	a4,a4,a3
    2ac4:	a5a506b7          	lui	a3,0xa5a50
    2ac8:	00d786b3          	add	a3,a5,a3
    2acc:	00d72023          	sw	a3,0(a4) # 601000 <__freertos_irq_stack_top+0x5e3dd0>
    2ad0:	00178793          	addi	a5,a5,1
    2ad4:	7ff00713          	li	a4,2047
    2ad8:	fef770e3          	bgeu	a4,a5,2ab8 <cache_evict+0x8>
}
    2adc:	00008067          	ret

00002ae0 <clip_cls_can_clip>:
static int clip_cls_can_clip(int cls) { return (cls == CLIP_CLS_FIELD) ? 1 : 0; }
    2ae0:	00153513          	seqz	a0,a0
    2ae4:	00008067          	ret

00002ae8 <blt_cnt>:
static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
    2ae8:	ff010113          	addi	sp,sp,-16
    2aec:	00112623          	sw	ra,12(sp)
    2af0:	00c00513          	li	a0,12
    2af4:	d21ff0ef          	jal	2814 <blt_rd>
    2af8:	00c12083          	lw	ra,12(sp)
    2afc:	01010113          	addi	sp,sp,16
    2b00:	00008067          	ret

00002b04 <blt_stat>:
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }
    2b04:	ff010113          	addi	sp,sp,-16
    2b08:	00112623          	sw	ra,12(sp)
    2b0c:	00400513          	li	a0,4
    2b10:	d05ff0ef          	jal	2814 <blt_rd>
    2b14:	00c12083          	lw	ra,12(sp)
    2b18:	01010113          	addi	sp,sp,16
    2b1c:	00008067          	ret

00002b20 <blt_idle_st>:
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
    2b20:	00e57513          	andi	a0,a0,14
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
    2b24:	ff650513          	addi	a0,a0,-10 # 700ff6 <__freertos_irq_stack_top+0x6e3dc6>
}
    2b28:	00153513          	seqz	a0,a0
    2b2c:	00008067          	ret

00002b30 <blt_push_room_of>:
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    2b30:	0c700793          	li	a5,199
    2b34:	00a7e863          	bltu	a5,a0,2b44 <blt_push_room_of+0x14>
    return (uint32_t)BLT_PUSH_LIMIT - cnt;
    2b38:	0c800793          	li	a5,200
    2b3c:	40a78533          	sub	a0,a5,a0
    2b40:	00008067          	ret
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    2b44:	00000513          	li	a0,0
}
    2b48:	00008067          	ret

00002b4c <blt_init>:
{
    2b4c:	ff010113          	addi	sp,sp,-16
    2b50:	00112623          	sw	ra,12(sp)
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    2b54:	00400593          	li	a1,4
    2b58:	00000513          	li	a0,0
    2b5c:	ca9ff0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_IRQ_STATUS, 0xFFFFFFFFu);               /* W1C：清掉所有挂起 */
    2b60:	fff00593          	li	a1,-1
    2b64:	01000513          	li	a0,16
    2b68:	c9dff0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_IRQ_EN, 0u);
    2b6c:	00000593          	li	a1,0
    2b70:	01400513          	li	a0,20
    2b74:	c91ff0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
    2b78:	00100593          	li	a1,1
    2b7c:	00000513          	li	a0,0
    2b80:	c85ff0ef          	jal	2804 <blt_wr>
}
    2b84:	00c12083          	lw	ra,12(sp)
    2b88:	01010113          	addi	sp,sp,16
    2b8c:	00008067          	ret

00002b90 <frame_count>:
static uint32_t frame_count(void) { return blt_rd(BLT_FB_STAT) >> 16; }
    2b90:	ff010113          	addi	sp,sp,-16
    2b94:	00112623          	sw	ra,12(sp)
    2b98:	02800513          	li	a0,40
    2b9c:	c79ff0ef          	jal	2814 <blt_rd>
    2ba0:	01055513          	srli	a0,a0,0x10
    2ba4:	00c12083          	lw	ra,12(sp)
    2ba8:	01010113          	addi	sp,sp,16
    2bac:	00008067          	ret

00002bb0 <lut_pub_bank>:
static unsigned lut_pub_bank(unsigned wr) { return (unsigned)((wr & 1u) ^ (unsigned)(g_lut_inv & 1)); }
    2bb0:	83c1a783          	lw	a5,-1988(gp) # 7864 <g_lut_inv>
    2bb4:	00a7c533          	xor	a0,a5,a0
    2bb8:	00157513          	andi	a0,a0,1
    2bbc:	00008067          	ret

00002bc0 <lut_fill_bank>:
{
    2bc0:	fe010113          	addi	sp,sp,-32
    2bc4:	00112e23          	sw	ra,28(sp)
    2bc8:	00812c23          	sw	s0,24(sp)
    2bcc:	00912a23          	sw	s1,20(sp)
    2bd0:	01212823          	sw	s2,16(sp)
    2bd4:	01312623          	sw	s3,12(sp)
    2bd8:	00058913          	mv	s2,a1
    2bdc:	00060993          	mv	s3,a2
    blt_wr(BLT_LUT_CTRL, (en ? BLT_LUT_EN : 0UL) | ((uint32_t)(bank & 1u) << 1));
    2be0:	02068263          	beqz	a3,2c04 <lut_fill_bank+0x44>
    2be4:	00100593          	li	a1,1
    2be8:	00151793          	slli	a5,a0,0x1
    2bec:	0027f793          	andi	a5,a5,2
    2bf0:	00b7e5b3          	or	a1,a5,a1
    2bf4:	0ac00513          	li	a0,172
    2bf8:	c0dff0ef          	jal	2804 <blt_wr>
    for (ch = 0; ch < BLT_LUT_CH_N; ch++) {
    2bfc:	00000493          	li	s1,0
    2c00:	0500006f          	j	2c50 <lut_fill_bank+0x90>
    blt_wr(BLT_LUT_CTRL, (en ? BLT_LUT_EN : 0UL) | ((uint32_t)(bank & 1u) << 1));
    2c04:	00000593          	li	a1,0
    2c08:	fe1ff06f          	j	2be8 <lut_fill_bank+0x28>
            blt_wr(BLT_LUT_ADDR, lut_addr(ch, i));         /* [9:8] = 0/1/2 = R/G/B（含蓝） */
    2c0c:	00040593          	mv	a1,s0
    2c10:	00048513          	mv	a0,s1
    2c14:	821ff0ef          	jal	2434 <lut_addr>
    2c18:	00050593          	mv	a1,a0
    2c1c:	0a400513          	li	a0,164
    2c20:	be5ff0ef          	jal	2804 <blt_wr>
            blt_wr(BLT_LUT_DATA, lut_chan(i, fade, flash));
    2c24:	00098613          	mv	a2,s3
    2c28:	00090593          	mv	a1,s2
    2c2c:	00040513          	mv	a0,s0
    2c30:	fbcff0ef          	jal	23ec <lut_chan>
    2c34:	00050593          	mv	a1,a0
    2c38:	0a800513          	li	a0,168
    2c3c:	bc9ff0ef          	jal	2804 <blt_wr>
        for (i = 0; i < 256u; i++) {
    2c40:	00140413          	addi	s0,s0,1
    2c44:	0ff00793          	li	a5,255
    2c48:	fc87f2e3          	bgeu	a5,s0,2c0c <lut_fill_bank+0x4c>
    for (ch = 0; ch < BLT_LUT_CH_N; ch++) {
    2c4c:	00148493          	addi	s1,s1,1
    2c50:	00200793          	li	a5,2
    2c54:	0097e663          	bltu	a5,s1,2c60 <lut_fill_bank+0xa0>
        for (i = 0; i < 256u; i++) {
    2c58:	00000413          	li	s0,0
    2c5c:	fe9ff06f          	j	2c44 <lut_fill_bank+0x84>
}
    2c60:	01c12083          	lw	ra,28(sp)
    2c64:	01812403          	lw	s0,24(sp)
    2c68:	01412483          	lw	s1,20(sp)
    2c6c:	01012903          	lw	s2,16(sp)
    2c70:	00c12983          	lw	s3,12(sp)
    2c74:	02010113          	addi	sp,sp,32
    2c78:	00008067          	ret

00002c7c <lut_identity_safe_off>:
    if (!g_feat_lut) return;
    2c7c:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    2c80:	00079463          	bnez	a5,2c88 <lut_identity_safe_off+0xc>
    2c84:	00008067          	ret
{
    2c88:	ff010113          	addi	sp,sp,-16
    2c8c:	00112623          	sw	ra,12(sp)
    2c90:	00812423          	sw	s0,8(sp)
    2c94:	00912223          	sw	s1,4(sp)
    d = (unsigned)(blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK);
    2c98:	0b000513          	li	a0,176
    2c9c:	b79ff0ef          	jal	2814 <blt_rd>
    2ca0:	00157413          	andi	s0,a0,1
    w = lut_write_bank(d);
    2ca4:	00040513          	mv	a0,s0
    2ca8:	fa0ff0ef          	jal	2448 <lut_write_bank>
    2cac:	00050493          	mv	s1,a0
    blt_wr(BLT_LUT_CTRL, (uint32_t)w << 1);          /* ① 先关使能（立即生效）⇒ 刷表屏幕无变化 */
    2cb0:	00151593          	slli	a1,a0,0x1
    2cb4:	0ac00513          	li	a0,172
    2cb8:	b4dff0ef          	jal	2804 <blt_wr>
    lut_fill_bank(w, 255u, 0u, 0);                   /* ② 非显示 bank = 恒等表 */
    2cbc:	00000693          	li	a3,0
    2cc0:	00000613          	li	a2,0
    2cc4:	0ff00593          	li	a1,255
    2cc8:	00048513          	mv	a0,s1
    2ccc:	ef5ff0ef          	jal	2bc0 <lut_fill_bank>
    lut_fill_bank(d, 255u, 0u, 0);                   /* ③ 显示 bank 也刷成恒等表（内容相同） */
    2cd0:	00000693          	li	a3,0
    2cd4:	00000613          	li	a2,0
    2cd8:	0ff00593          	li	a1,255
    2cdc:	00040513          	mv	a0,s0
    2ce0:	ee1ff0ef          	jal	2bc0 <lut_fill_bank>
    blt_wr(BLT_LUT_CTRL, (uint32_t)lut_pub_bank(d) << 1);   /* ④ 显示仍是 d、使能 = 0 */
    2ce4:	00040513          	mv	a0,s0
    2ce8:	ec9ff0ef          	jal	2bb0 <lut_pub_bank>
    2cec:	00151593          	slli	a1,a0,0x1
    2cf0:	0ac00513          	li	a0,172
    2cf4:	b11ff0ef          	jal	2804 <blt_wr>
    g_lut_en = 0; g_lut_f = 255u; g_lut_g = 0u; g_lut_stage_en = 0;
    2cf8:	9201a623          	sw	zero,-1748(gp) # 7954 <g_lut_en>
    2cfc:	0ff00713          	li	a4,255
    2d00:	82e1ac23          	sw	a4,-1992(gp) # 7860 <g_lut_f>
    2d04:	9201a423          	sw	zero,-1752(gp) # 7950 <g_lut_g>
    2d08:	9201a223          	sw	zero,-1756(gp) # 794c <g_lut_stage_en>
    g_lut_disp = d; g_lut_pend = -1; g_lut_pend_en = 0;
    2d0c:	9281aa23          	sw	s0,-1740(gp) # 795c <g_lut_disp>
    2d10:	fff00713          	li	a4,-1
    2d14:	84e1a023          	sw	a4,-1984(gp) # 7868 <g_lut_pend>
    2d18:	9201a823          	sw	zero,-1744(gp) # 7958 <g_lut_pend_en>
}
    2d1c:	00c12083          	lw	ra,12(sp)
    2d20:	00812403          	lw	s0,8(sp)
    2d24:	00412483          	lw	s1,4(sp)
    2d28:	01010113          	addi	sp,sp,16
    2d2c:	00008067          	ret

00002d30 <lut_write_table>:
{
    2d30:	fe010113          	addi	sp,sp,-32
    2d34:	00112e23          	sw	ra,28(sp)
    2d38:	00812c23          	sw	s0,24(sp)
    2d3c:	00912a23          	sw	s1,20(sp)
    2d40:	01212823          	sw	s2,16(sp)
    2d44:	01312623          	sw	s3,12(sp)
    2d48:	01412423          	sw	s4,8(sp)
    2d4c:	00050993          	mv	s3,a0
    2d50:	00058913          	mv	s2,a1
    2d54:	00060413          	mv	s0,a2
    unsigned disp = (unsigned)(blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK);   /* ① 现读显示 bank */
    2d58:	0b000513          	li	a0,176
    2d5c:	ab9ff0ef          	jal	2814 <blt_rd>
    2d60:	00157493          	andi	s1,a0,1
    unsigned wr   = lut_write_bank(disp);                                   /* ② 写另一半 */
    2d64:	00048513          	mv	a0,s1
    2d68:	ee0ff0ef          	jal	2448 <lut_write_bank>
    2d6c:	00050a13          	mv	s4,a0
    lut_fill_bank(wr, fade, flash, g_lut_en);       /* ③ 写表；使能保持"已发布"值 */
    2d70:	92c1a683          	lw	a3,-1748(gp) # 7954 <g_lut_en>
    2d74:	00090613          	mv	a2,s2
    2d78:	00098593          	mv	a1,s3
    2d7c:	e45ff0ef          	jal	2bc0 <lut_fill_bank>
    g_lut_f        = fade;
    2d80:	8331ac23          	sw	s3,-1992(gp) # 7860 <g_lut_f>
    g_lut_g        = flash;
    2d84:	9321a423          	sw	s2,-1752(gp) # 7950 <g_lut_g>
    g_lut_stage_en = want_en;
    2d88:	9281a223          	sw	s0,-1756(gp) # 794c <g_lut_stage_en>
    g_lut_disp     = disp;              /* 这一刻显示 bank 还没换（换在帧边界） */
    2d8c:	9291aa23          	sw	s1,-1740(gp) # 795c <g_lut_disp>
    g_lut_pend     = (int)wr;
    2d90:	8541a023          	sw	s4,-1984(gp) # 7868 <g_lut_pend>
    g_lut_pend_en  = want_en;
    2d94:	9281a823          	sw	s0,-1744(gp) # 7958 <g_lut_pend_en>
    g_lut_pend_t0  = tick32();
    2d98:	a51ff0ef          	jal	27e8 <tick32>
    2d9c:	92a1a023          	sw	a0,-1760(gp) # 7948 <g_lut_pend_t0>
}
    2da0:	01c12083          	lw	ra,28(sp)
    2da4:	01812403          	lw	s0,24(sp)
    2da8:	01412483          	lw	s1,20(sp)
    2dac:	01012903          	lw	s2,16(sp)
    2db0:	00c12983          	lw	s3,12(sp)
    2db4:	00812a03          	lw	s4,8(sp)
    2db8:	02010113          	addi	sp,sp,32
    2dbc:	00008067          	ret

00002dc0 <lut_publish>:
    if (!g_feat_lut || g_lut_pend < 0) return;
    2dc0:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    2dc4:	06078063          	beqz	a5,2e24 <lut_publish+0x64>
    2dc8:	8401a503          	lw	a0,-1984(gp) # 7868 <g_lut_pend>
    2dcc:	04054c63          	bltz	a0,2e24 <lut_publish+0x64>
{
    2dd0:	ff010113          	addi	sp,sp,-16
    2dd4:	00112623          	sw	ra,12(sp)
    pb = (uint32_t)lut_pub_bank((unsigned)g_lut_pend);          /* ④ bit1 = ~wr（权威语义） */
    2dd8:	dd9ff0ef          	jal	2bb0 <lut_pub_bank>
    blt_wr(BLT_LUT_CTRL, (g_lut_pend_en ? BLT_LUT_EN : 0UL) | (pb << 1));
    2ddc:	9301a783          	lw	a5,-1744(gp) # 7958 <g_lut_pend_en>
    2de0:	02078e63          	beqz	a5,2e1c <lut_publish+0x5c>
    2de4:	00100593          	li	a1,1
    2de8:	00151513          	slli	a0,a0,0x1
    2dec:	00b565b3          	or	a1,a0,a1
    2df0:	0ac00513          	li	a0,172
    2df4:	a11ff0ef          	jal	2804 <blt_wr>
    g_lut_en   = g_lut_pend_en;
    2df8:	9301a703          	lw	a4,-1744(gp) # 7958 <g_lut_pend_en>
    2dfc:	92e1a623          	sw	a4,-1748(gp) # 7954 <g_lut_en>
    g_lut_disp = (uint32_t)g_lut_pend;                          /* 帧边界起显示的就是它 */
    2e00:	8401a683          	lw	a3,-1984(gp) # 7868 <g_lut_pend>
    2e04:	92d1aa23          	sw	a3,-1740(gp) # 795c <g_lut_disp>
    g_lut_pend = -1;
    2e08:	fff00713          	li	a4,-1
    2e0c:	84e1a023          	sw	a4,-1984(gp) # 7868 <g_lut_pend>
}
    2e10:	00c12083          	lw	ra,12(sp)
    2e14:	01010113          	addi	sp,sp,16
    2e18:	00008067          	ret
    blt_wr(BLT_LUT_CTRL, (g_lut_pend_en ? BLT_LUT_EN : 0UL) | (pb << 1));
    2e1c:	00000593          	li	a1,0
    2e20:	fc9ff06f          	j	2de8 <lut_publish+0x28>
    2e24:	00008067          	ret

00002e28 <bg_px>:
    unsigned r5 = 2u + (gx * 6u) / 255u;
    2e28:	00151793          	slli	a5,a0,0x1
    2e2c:	00a787b3          	add	a5,a5,a0
    2e30:	00179793          	slli	a5,a5,0x1
    2e34:	0ff00613          	li	a2,255
    2e38:	02c7d7b3          	divu	a5,a5,a2
    2e3c:	00278793          	addi	a5,a5,2
    unsigned g5 = 2u + (gy * 5u) / 255u;
    2e40:	00259693          	slli	a3,a1,0x2
    2e44:	00b686b3          	add	a3,a3,a1
    2e48:	02c6d6b3          	divu	a3,a3,a2
    2e4c:	00268693          	addi	a3,a3,2 # a5a50002 <__freertos_irq_stack_top+0xa5a32dd2>
    unsigned b5 = 9u + (gy * 11u) / 255u;
    2e50:	00159713          	slli	a4,a1,0x1
    2e54:	00b70733          	add	a4,a4,a1
    2e58:	00271713          	slli	a4,a4,0x2
    2e5c:	40b70733          	sub	a4,a4,a1
    2e60:	02c75733          	divu	a4,a4,a2
    2e64:	00970713          	addi	a4,a4,9
    int dx = (int)gx - 128, dy = (int)gy - 128;
    2e68:	f8050613          	addi	a2,a0,-128
    2e6c:	f8058813          	addi	a6,a1,-128
    unsigned d2 = (unsigned)(dx * dx + dy * dy);
    2e70:	02c60633          	mul	a2,a2,a2
    2e74:	03080833          	mul	a6,a6,a6
    2e78:	01060633          	add	a2,a2,a6
    if (d2 < 16384u) {                                  /* 中心光晕 */
    2e7c:	00004837          	lui	a6,0x4
    2e80:	03067863          	bgeu	a2,a6,2eb0 <bg_px+0x88>
        unsigned halo = ((16384u - d2) * 9u) / 16384u;
    2e84:	00361813          	slli	a6,a2,0x3
    2e88:	00c80833          	add	a6,a6,a2
    2e8c:	00024637          	lui	a2,0x24
    2e90:	41060633          	sub	a2,a2,a6
    2e94:	00e65813          	srli	a6,a2,0xe
        b5 += halo; g5 += halo / 2u; r5 += halo / 3u;
    2e98:	01070733          	add	a4,a4,a6
    2e9c:	00f65813          	srli	a6,a2,0xf
    2ea0:	010686b3          	add	a3,a3,a6
    2ea4:	0000c837          	lui	a6,0xc
    2ea8:	03065633          	divu	a2,a2,a6
    2eac:	00c787b3          	add	a5,a5,a2
    if ((gx & 31u) == 0u || (gy & 31u) == 0u) { r5++; g5++; b5++; }   /* 细网格 */
    2eb0:	01f57513          	andi	a0,a0,31
    2eb4:	00050663          	beqz	a0,2ec0 <bg_px+0x98>
    2eb8:	01f5f593          	andi	a1,a1,31
    2ebc:	00059863          	bnez	a1,2ecc <bg_px+0xa4>
    2ec0:	00178793          	addi	a5,a5,1
    2ec4:	00168693          	addi	a3,a3,1
    2ec8:	00170713          	addi	a4,a4,1
    if (r5 > 31u) r5 = 31u;
    2ecc:	01f00613          	li	a2,31
    2ed0:	00f67463          	bgeu	a2,a5,2ed8 <bg_px+0xb0>
    2ed4:	01f00793          	li	a5,31
    if (g5 > 63u) g5 = 63u;
    2ed8:	03f00613          	li	a2,63
    2edc:	00d67463          	bgeu	a2,a3,2ee4 <bg_px+0xbc>
    2ee0:	03f00693          	li	a3,63
    if (b5 > 31u) b5 = 31u;
    2ee4:	01f00613          	li	a2,31
    2ee8:	00e67463          	bgeu	a2,a4,2ef0 <bg_px+0xc8>
    2eec:	01f00713          	li	a4,31
    return (uint16_t)((r5 << 11) | (g5 << 5) | b5);
    2ef0:	00b79513          	slli	a0,a5,0xb
    2ef4:	01051513          	slli	a0,a0,0x10
    2ef8:	01055513          	srli	a0,a0,0x10
    2efc:	00569793          	slli	a5,a3,0x5
    2f00:	01079793          	slli	a5,a5,0x10
    2f04:	0107d793          	srli	a5,a5,0x10
    2f08:	00f56533          	or	a0,a0,a5
    2f0c:	00e56533          	or	a0,a0,a4
}
    2f10:	01051513          	slli	a0,a0,0x10
    2f14:	01055513          	srli	a0,a0,0x10
    2f18:	00008067          	ret

00002f1c <lcg>:
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }
    2f1c:	00052783          	lw	a5,0(a0)
    2f20:	00196737          	lui	a4,0x196
    2f24:	60d70713          	addi	a4,a4,1549 # 19660d <__freertos_irq_stack_top+0x1793dd>
    2f28:	02e787b3          	mul	a5,a5,a4
    2f2c:	3c6ef737          	lui	a4,0x3c6ef
    2f30:	35f70713          	addi	a4,a4,863 # 3c6ef35f <__freertos_irq_stack_top+0x3c6d212f>
    2f34:	00e787b3          	add	a5,a5,a4
    2f38:	00f52023          	sw	a5,0(a0)
    2f3c:	0107d513          	srli	a0,a5,0x10
    2f40:	00008067          	ret

00002f44 <scene_init>:
{
    2f44:	fd010113          	addi	sp,sp,-48
    2f48:	02112623          	sw	ra,44(sp)
    2f4c:	02812423          	sw	s0,40(sp)
    2f50:	02912223          	sw	s1,36(sp)
    2f54:	03212023          	sw	s2,32(sp)
    2f58:	01312e23          	sw	s3,28(sp)
    2f5c:	01412c23          	sw	s4,24(sp)
    2f60:	01512a23          	sw	s5,20(sp)
    2f64:	01612823          	sw	s6,16(sp)
    2f68:	00050a93          	mv	s5,a0
    int xr = FB_WIDTH - SPR_W;              /* 起点上界（右/下各留一个精灵位） */
    2f6c:	85c1ab03          	lw	s6,-1956(gp) # 7884 <g_blk>
    2f70:	3c000993          	li	s3,960
    2f74:	416989b3          	sub	s3,s3,s6
    int yr = PLAY_H   - SPR_H;
    2f78:	20c00a13          	li	s4,524
    2f7c:	416a0a33          	sub	s4,s4,s6
    uint32_t s = seed;
    2f80:	00b12623          	sw	a1,12(sp)
    if (n > MAXPT) n = MAXPT;
    2f84:	000017b7          	lui	a5,0x1
    2f88:	77078793          	addi	a5,a5,1904 # 1770 <main+0x66c>
    2f8c:	00a7d463          	bge	a5,a0,2f94 <scene_init+0x50>
    2f90:	00078a93          	mv	s5,a5
    for (i = 0; i < n; i++) {
    2f94:	00000413          	li	s0,0
    2f98:	0300006f          	j	2fc8 <scene_init+0x84>
        p->tx = p->x; p->ty = p->y;
    2f9c:	000087b7          	lui	a5,0x8
    2fa0:	00341713          	slli	a4,s0,0x3
    2fa4:	40870733          	sub	a4,a4,s0
    2fa8:	00171713          	slli	a4,a4,0x1
    2fac:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    2fb0:	00e787b3          	add	a5,a5,a4
    2fb4:	00079703          	lh	a4,0(a5)
    2fb8:	00e79423          	sh	a4,8(a5)
    2fbc:	00279703          	lh	a4,2(a5)
    2fc0:	00e79523          	sh	a4,10(a5)
    for (i = 0; i < n; i++) {
    2fc4:	00140413          	addi	s0,s0,1
    2fc8:	15545463          	bge	s0,s5,3110 <scene_init+0x1cc>
        uint32_t r1 = lcg(&s), r2 = lcg(&s), r3 = lcg(&s);
    2fcc:	00c10513          	addi	a0,sp,12
    2fd0:	f4dff0ef          	jal	2f1c <lcg>
    2fd4:	00050913          	mv	s2,a0
    2fd8:	00c10513          	addi	a0,sp,12
    2fdc:	f41ff0ef          	jal	2f1c <lcg>
    2fe0:	00050493          	mv	s1,a0
    2fe4:	00c10513          	addi	a0,sp,12
    2fe8:	f35ff0ef          	jal	2f1c <lcg>
        p->vx = (int16_t)((int)(r1 % 7u) - 3);
    2fec:	00700713          	li	a4,7
    2ff0:	02e97733          	remu	a4,s2,a4
    2ff4:	ffd70713          	addi	a4,a4,-3
    2ff8:	000086b7          	lui	a3,0x8
    2ffc:	00341793          	slli	a5,s0,0x3
    3000:	408787b3          	sub	a5,a5,s0
    3004:	00179793          	slli	a5,a5,0x1
    3008:	a0c68693          	addi	a3,a3,-1524 # 7a0c <g_pt>
    300c:	00f686b3          	add	a3,a3,a5
    3010:	00e69223          	sh	a4,4(a3)
        p->vy = (int16_t)((int)(r2 % 5u) - 2);
    3014:	00500793          	li	a5,5
    3018:	02f4f7b3          	remu	a5,s1,a5
    301c:	ffe78793          	addi	a5,a5,-2
    3020:	00f69323          	sh	a5,6(a3)
        if (!p->vx) p->vx = 1;
    3024:	02071263          	bnez	a4,3048 <scene_init+0x104>
    3028:	00008737          	lui	a4,0x8
    302c:	00341693          	slli	a3,s0,0x3
    3030:	408686b3          	sub	a3,a3,s0
    3034:	00169693          	slli	a3,a3,0x1
    3038:	a0c70713          	addi	a4,a4,-1524 # 7a0c <g_pt>
    303c:	00d70733          	add	a4,a4,a3
    3040:	00100693          	li	a3,1
    3044:	00d71223          	sh	a3,4(a4)
        if (!p->vy) p->vy = 1;
    3048:	02079263          	bnez	a5,306c <scene_init+0x128>
    304c:	000087b7          	lui	a5,0x8
    3050:	00341713          	slli	a4,s0,0x3
    3054:	40870733          	sub	a4,a4,s0
    3058:	00171713          	slli	a4,a4,0x1
    305c:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    3060:	00e787b3          	add	a5,a5,a4
    3064:	00100713          	li	a4,1
    3068:	00e79323          	sh	a4,6(a5)
        p->x  = (int16_t)(r1 % (uint32_t)xr);
    306c:	03397933          	remu	s2,s2,s3
    3070:	01091913          	slli	s2,s2,0x10
    3074:	41095913          	srai	s2,s2,0x10
    3078:	000087b7          	lui	a5,0x8
    307c:	00341713          	slli	a4,s0,0x3
    3080:	40870733          	sub	a4,a4,s0
    3084:	00171713          	slli	a4,a4,0x1
    3088:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    308c:	00e787b3          	add	a5,a5,a4
    3090:	01279023          	sh	s2,0(a5)
        p->y  = (int16_t)((int)(r2 % (uint32_t)yr) + TOP_Y0);
    3094:	0344f4b3          	remu	s1,s1,s4
    3098:	01048493          	addi	s1,s1,16
    309c:	01049493          	slli	s1,s1,0x10
    30a0:	4104d493          	srai	s1,s1,0x10
    30a4:	00979123          	sh	s1,2(a5)
        p->a  = (uint8_t)(64u + (r3 & 0xBFu));            /* 每精灵 alpha：64..255 */
    30a8:	0bf57713          	andi	a4,a0,191
    30ac:	04070713          	addi	a4,a4,64
    30b0:	00e78623          	sb	a4,12(a5)
        p->v  = (uint8_t)((r3 >> 8) % (uint32_t)GLOW_VARIANTS);
    30b4:	00855513          	srli	a0,a0,0x8
    30b8:	00357513          	andi	a0,a0,3
    30bc:	00a786a3          	sb	a0,13(a5)
        if (p->x > xr) p->x = (int16_t)xr;
    30c0:	0329d063          	bge	s3,s2,30e0 <scene_init+0x19c>
    30c4:	000087b7          	lui	a5,0x8
    30c8:	00341713          	slli	a4,s0,0x3
    30cc:	40870733          	sub	a4,a4,s0
    30d0:	00171713          	slli	a4,a4,0x1
    30d4:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    30d8:	00e787b3          	add	a5,a5,a4
    30dc:	01379023          	sh	s3,0(a5)
        if (p->y > yr + TOP_Y0) p->y = (int16_t)(yr + TOP_Y0);
    30e0:	21c00793          	li	a5,540
    30e4:	416787b3          	sub	a5,a5,s6
    30e8:	ea97dae3          	bge	a5,s1,2f9c <scene_init+0x58>
    30ec:	010a0693          	addi	a3,s4,16
    30f0:	000087b7          	lui	a5,0x8
    30f4:	00341713          	slli	a4,s0,0x3
    30f8:	40870733          	sub	a4,a4,s0
    30fc:	00171713          	slli	a4,a4,0x1
    3100:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    3104:	00e787b3          	add	a5,a5,a4
    3108:	00d79123          	sh	a3,2(a5)
    310c:	e91ff06f          	j	2f9c <scene_init+0x58>
}
    3110:	02c12083          	lw	ra,44(sp)
    3114:	02812403          	lw	s0,40(sp)
    3118:	02412483          	lw	s1,36(sp)
    311c:	02012903          	lw	s2,32(sp)
    3120:	01c12983          	lw	s3,28(sp)
    3124:	01812a03          	lw	s4,24(sp)
    3128:	01412a83          	lw	s5,20(sp)
    312c:	01012b03          	lw	s6,16(sp)
    3130:	03010113          	addi	sp,sp,48
    3134:	00008067          	ret

00003138 <scene_step>:
    for (i = 0; i < n; i++) {
    3138:	00000793          	li	a5,0
    313c:	0880006f          	j	31c4 <scene_step+0x8c>
        if (x < xmin)          { x = xmin;     p->vx = (int16_t)(-p->vx); }
    3140:	01059593          	slli	a1,a1,0x10
    3144:	0105d593          	srli	a1,a1,0x10
    3148:	40b005b3          	neg	a1,a1
    314c:	000086b7          	lui	a3,0x8
    3150:	00379893          	slli	a7,a5,0x3
    3154:	40f888b3          	sub	a7,a7,a5
    3158:	00189893          	slli	a7,a7,0x1
    315c:	a0c68693          	addi	a3,a3,-1524 # 7a0c <g_pt>
    3160:	011686b3          	add	a3,a3,a7
    3164:	00b69223          	sh	a1,4(a3)
    3168:	00000693          	li	a3,0
        if (y < ymin)          { y = ymin;     p->vy = (int16_t)(-p->vy); }
    316c:	00f00593          	li	a1,15
    3170:	0cc5c863          	blt	a1,a2,3240 <scene_step+0x108>
    3174:	01071713          	slli	a4,a4,0x10
    3178:	01075713          	srli	a4,a4,0x10
    317c:	40e00733          	neg	a4,a4
    3180:	00008637          	lui	a2,0x8
    3184:	00379593          	slli	a1,a5,0x3
    3188:	40f585b3          	sub	a1,a1,a5
    318c:	00159593          	slli	a1,a1,0x1
    3190:	a0c60613          	addi	a2,a2,-1524 # 7a0c <g_pt>
    3194:	00b60633          	add	a2,a2,a1
    3198:	00e61323          	sh	a4,6(a2)
    319c:	01000613          	li	a2,16
        p->x = (int16_t)x;
    31a0:	00008737          	lui	a4,0x8
    31a4:	00379593          	slli	a1,a5,0x3
    31a8:	40f585b3          	sub	a1,a1,a5
    31ac:	00159593          	slli	a1,a1,0x1
    31b0:	a0c70713          	addi	a4,a4,-1524 # 7a0c <g_pt>
    31b4:	00b70733          	add	a4,a4,a1
    31b8:	00d71023          	sh	a3,0(a4)
        p->y = (int16_t)y;
    31bc:	00c71123          	sh	a2,2(a4)
    for (i = 0; i < n; i++) {
    31c0:	00178793          	addi	a5,a5,1
    31c4:	0aa7de63          	bge	a5,a0,3280 <scene_step+0x148>
        int x = p->x + p->vx, y = p->y + p->vy, w = SPR_W;
    31c8:	00008737          	lui	a4,0x8
    31cc:	00379693          	slli	a3,a5,0x3
    31d0:	40f686b3          	sub	a3,a3,a5
    31d4:	00169693          	slli	a3,a3,0x1
    31d8:	a0c70713          	addi	a4,a4,-1524 # 7a0c <g_pt>
    31dc:	00d70733          	add	a4,a4,a3
    31e0:	00071683          	lh	a3,0(a4)
    31e4:	00471583          	lh	a1,4(a4)
    31e8:	00b686b3          	add	a3,a3,a1
    31ec:	00271603          	lh	a2,2(a4)
    31f0:	00671703          	lh	a4,6(a4)
    31f4:	00e60633          	add	a2,a2,a4
    31f8:	85c1a803          	lw	a6,-1956(gp) # 7884 <g_blk>
        if (x < xmin)          { x = xmin;     p->vx = (int16_t)(-p->vx); }
    31fc:	f406c2e3          	bltz	a3,3140 <scene_step+0x8>
        else if (x + w > xmax) { x = xmax - w; p->vx = (int16_t)(-p->vx); }
    3200:	010688b3          	add	a7,a3,a6
    3204:	3c000313          	li	t1,960
    3208:	f71352e3          	bge	t1,a7,316c <scene_step+0x34>
    320c:	3c000693          	li	a3,960
    3210:	410686b3          	sub	a3,a3,a6
    3214:	01059593          	slli	a1,a1,0x10
    3218:	0105d593          	srli	a1,a1,0x10
    321c:	40b005b3          	neg	a1,a1
    3220:	000088b7          	lui	a7,0x8
    3224:	00379313          	slli	t1,a5,0x3
    3228:	40f30333          	sub	t1,t1,a5
    322c:	00131313          	slli	t1,t1,0x1
    3230:	a0c88893          	addi	a7,a7,-1524 # 7a0c <g_pt>
    3234:	006888b3          	add	a7,a7,t1
    3238:	00b89223          	sh	a1,4(a7)
    323c:	f31ff06f          	j	316c <scene_step+0x34>
        else if (y + w > ymax) { y = ymax - w; p->vy = (int16_t)(-p->vy); }
    3240:	010605b3          	add	a1,a2,a6
    3244:	21c00893          	li	a7,540
    3248:	f4b8dce3          	bge	a7,a1,31a0 <scene_step+0x68>
    324c:	21c00613          	li	a2,540
    3250:	41060633          	sub	a2,a2,a6
    3254:	01071713          	slli	a4,a4,0x10
    3258:	01075713          	srli	a4,a4,0x10
    325c:	40e00733          	neg	a4,a4
    3260:	000085b7          	lui	a1,0x8
    3264:	00379813          	slli	a6,a5,0x3
    3268:	40f80833          	sub	a6,a6,a5
    326c:	00181813          	slli	a6,a6,0x1
    3270:	a0c58593          	addi	a1,a1,-1524 # 7a0c <g_pt>
    3274:	010585b3          	add	a1,a1,a6
    3278:	00e59323          	sh	a4,6(a1)
    327c:	f25ff06f          	j	31a0 <scene_step+0x68>
}
    3280:	00008067          	ret

00003284 <scene_snap>:
    for (i = 0; i < n; i++) { g_pt[i].tx = g_pt[i].x; g_pt[i].ty = g_pt[i].y; }
    3284:	00000693          	li	a3,0
    3288:	0300006f          	j	32b8 <scene_snap+0x34>
    328c:	000087b7          	lui	a5,0x8
    3290:	00369713          	slli	a4,a3,0x3
    3294:	40d70733          	sub	a4,a4,a3
    3298:	00171713          	slli	a4,a4,0x1
    329c:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    32a0:	00e787b3          	add	a5,a5,a4
    32a4:	00079703          	lh	a4,0(a5)
    32a8:	00e79423          	sh	a4,8(a5)
    32ac:	00279703          	lh	a4,2(a5)
    32b0:	00e79523          	sh	a4,10(a5)
    32b4:	00168693          	addi	a3,a3,1
    32b8:	fca6cae3          	blt	a3,a0,328c <scene_snap+0x8>
}
    32bc:	00008067          	ret

000032c0 <app>:
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
    32c0:	0100006f          	j	32d0 <app+0x10>
    32c4:	00158593          	addi	a1,a1,1
    32c8:	00f50023          	sb	a5,0(a0)
    32cc:	00150513          	addi	a0,a0,1
    32d0:	0005c783          	lbu	a5,0(a1)
    32d4:	fe0798e3          	bnez	a5,32c4 <app+0x4>
    32d8:	00008067          	ret

000032dc <appn>:
{
    32dc:	ff010113          	addi	sp,sp,-16
    char d[12]; int n = 0, i;
    32e0:	00000793          	li	a5,0
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    32e4:	00a00813          	li	a6,10
    32e8:	0305f6b3          	remu	a3,a1,a6
    32ec:	03068693          	addi	a3,a3,48
    32f0:	01078713          	addi	a4,a5,16
    32f4:	00270733          	add	a4,a4,sp
    32f8:	00178793          	addi	a5,a5,1
    32fc:	fed70a23          	sb	a3,-12(a4)
    3300:	00058693          	mv	a3,a1
    3304:	0305d5b3          	divu	a1,a1,a6
    3308:	00900713          	li	a4,9
    330c:	02d77863          	bgeu	a4,a3,333c <appn+0x60>
    3310:	00a00713          	li	a4,10
    3314:	fcf758e3          	bge	a4,a5,32e4 <appn+0x8>
    3318:	00000713          	li	a4,0
    331c:	0140006f          	j	3330 <appn+0x54>
    for (i = 0; i < w - n; i++) *p++ = ' ';
    3320:	02000693          	li	a3,32
    3324:	00d50023          	sb	a3,0(a0)
    3328:	00170713          	addi	a4,a4,1
    332c:	00150513          	addi	a0,a0,1
    3330:	40f606b3          	sub	a3,a2,a5
    3334:	fed746e3          	blt	a4,a3,3320 <appn+0x44>
    3338:	0240006f          	j	335c <appn+0x80>
    333c:	00000713          	li	a4,0
    3340:	ff1ff06f          	j	3330 <appn+0x54>
    while (n) *p++ = d[--n];
    3344:	fff78793          	addi	a5,a5,-1
    3348:	01078713          	addi	a4,a5,16
    334c:	00270733          	add	a4,a4,sp
    3350:	ff474703          	lbu	a4,-12(a4)
    3354:	00e50023          	sb	a4,0(a0)
    3358:	00150513          	addi	a0,a0,1
    335c:	fe0794e3          	bnez	a5,3344 <appn+0x68>
}
    3360:	01010113          	addi	sp,sp,16
    3364:	00008067          	ret

00003368 <sseq>:
    while (*a && *a == *b) { a++; b++; }
    3368:	00c0006f          	j	3374 <sseq+0xc>
    336c:	00150513          	addi	a0,a0,1
    3370:	00158593          	addi	a1,a1,1
    3374:	00054783          	lbu	a5,0(a0)
    3378:	00078663          	beqz	a5,3384 <sseq+0x1c>
    337c:	0005c703          	lbu	a4,0(a1)
    3380:	fee786e3          	beq	a5,a4,336c <sseq+0x4>
    return (*a == *b) ? 1 : 0;
    3384:	0005c703          	lbu	a4,0(a1)
    3388:	40e78533          	sub	a0,a5,a4
}
    338c:	00153513          	seqz	a0,a0
    3390:	00008067          	ret

00003394 <scpy>:
static void scpy(char *d, const char *s) { while ((*d++ = *s++) != 0) { } }
    3394:	0005c703          	lbu	a4,0(a1)
    3398:	00158593          	addi	a1,a1,1
    339c:	00e50023          	sb	a4,0(a0)
    33a0:	00150513          	addi	a0,a0,1
    33a4:	fe0718e3          	bnez	a4,3394 <scpy>
    33a8:	00008067          	ret

000033ac <scene_name>:
    if (s == SC_FADE)  return "FADE";
    33ac:	00100793          	li	a5,1
    33b0:	02f50463          	beq	a0,a5,33d8 <scene_name+0x2c>
    if (s == SC_CLIP)  return "CLIP";
    33b4:	00200793          	li	a5,2
    33b8:	02f50663          	beq	a0,a5,33e4 <scene_name+0x38>
    if (s == SC_LAYER) return "LAYER";
    33bc:	00300793          	li	a5,3
    33c0:	02f50863          	beq	a0,a5,33f0 <scene_name+0x44>
    if (s == SC_THRU)  return "THRU";
    33c4:	00400793          	li	a5,4
    33c8:	02f50a63          	beq	a0,a5,33fc <scene_name+0x50>
    return "GLOW";
    33cc:	00006537          	lui	a0,0x6
    33d0:	ffc50513          	addi	a0,a0,-4 # 5ffc <_data+0x48>
    33d4:	00008067          	ret
    if (s == SC_FADE)  return "FADE";
    33d8:	00006537          	lui	a0,0x6
    33dc:	fdc50513          	addi	a0,a0,-36 # 5fdc <_data+0x28>
    33e0:	00008067          	ret
    if (s == SC_CLIP)  return "CLIP";
    33e4:	00006537          	lui	a0,0x6
    33e8:	fe450513          	addi	a0,a0,-28 # 5fe4 <_data+0x30>
    33ec:	00008067          	ret
    if (s == SC_LAYER) return "LAYER";
    33f0:	00006537          	lui	a0,0x6
    33f4:	fec50513          	addi	a0,a0,-20 # 5fec <_data+0x38>
    33f8:	00008067          	ret
    if (s == SC_THRU)  return "THRU";
    33fc:	00006537          	lui	a0,0x6
    3400:	ff450513          	addi	a0,a0,-12 # 5ff4 <_data+0x40>
}
    3404:	00008067          	ret

00003408 <fmt_stat>:
{
    3408:	fe010113          	addi	sp,sp,-32
    340c:	00112e23          	sw	ra,28(sp)
    3410:	00812c23          	sw	s0,24(sp)
    3414:	00912a23          	sw	s1,20(sp)
    3418:	01212823          	sw	s2,16(sp)
    341c:	01312623          	sw	s3,12(sp)
    3420:	01412423          	sw	s4,8(sp)
    3424:	01512223          	sw	s5,4(sp)
    3428:	01612023          	sw	s6,0(sp)
    342c:	00058993          	mv	s3,a1
    3430:	00060b13          	mv	s6,a2
    3434:	00068a13          	mv	s4,a3
    3438:	00070a93          	mv	s5,a4
    343c:	00078913          	mv	s2,a5
    3440:	00080413          	mv	s0,a6
    3444:	00088493          	mv	s1,a7
    if (fps   >   99u) fps   =   99u;    /* 钳位只为把最长串钉死在上界内 */
    3448:	06300793          	li	a5,99
    344c:	00b7f463          	bgeu	a5,a1,3454 <fmt_stat+0x4c>
    3450:	06300993          	li	s3,99
    if (mpx   > 9999u) mpx   = 9999u;
    3454:	000027b7          	lui	a5,0x2
    3458:	70f78793          	addi	a5,a5,1807 # 270f <glow_color+0xd3>
    345c:	0087f463          	bgeu	a5,s0,3464 <fmt_stat+0x5c>
    3460:	00078413          	mv	s0,a5
    if (alpha >  255u) alpha =  255u;
    3464:	0ff00793          	li	a5,255
    3468:	0127f463          	bgeu	a5,s2,3470 <fmt_stat+0x68>
    346c:	0ff00913          	li	s2,255
    if (busy  >  100u) busy  =  100u;
    3470:	06400793          	li	a5,100
    3474:	0097f463          	bgeu	a5,s1,347c <fmt_stat+0x74>
    3478:	06400493          	li	s1,100
    p = app(p, "FPS="); p = appn(p, fps, 2);
    347c:	000065b7          	lui	a1,0x6
    3480:	00458593          	addi	a1,a1,4 # 6004 <_data+0x50>
    3484:	e3dff0ef          	jal	32c0 <app>
    3488:	00200613          	li	a2,2
    348c:	00098593          	mv	a1,s3
    3490:	e4dff0ef          	jal	32dc <appn>
    p = app(p, " N=");  p = appn(p, (unsigned)n, 4);
    3494:	000065b7          	lui	a1,0x6
    3498:	00c58593          	addi	a1,a1,12 # 600c <_data+0x58>
    349c:	e25ff0ef          	jal	32c0 <app>
    34a0:	00400613          	li	a2,4
    34a4:	000b0593          	mv	a1,s6
    34a8:	e35ff0ef          	jal	32dc <appn>
    p = app(p, " SZ="); p = appn(p, (unsigned)sz, 2);
    34ac:	000065b7          	lui	a1,0x6
    34b0:	01058593          	addi	a1,a1,16 # 6010 <_data+0x5c>
    34b4:	e0dff0ef          	jal	32c0 <app>
    34b8:	00200613          	li	a2,2
    34bc:	000a8593          	mv	a1,s5
    34c0:	e1dff0ef          	jal	32dc <appn>
    p = app(p, " MPX=");p = appn(p, mpx, 4);
    34c4:	000065b7          	lui	a1,0x6
    34c8:	01858593          	addi	a1,a1,24 # 6018 <_data+0x64>
    34cc:	df5ff0ef          	jal	32c0 <app>
    34d0:	00400613          	li	a2,4
    34d4:	00040593          	mv	a1,s0
    34d8:	e05ff0ef          	jal	32dc <appn>
    p = app(p, " SC");  p = appn(p, (unsigned)(scene + 1), 1);
    34dc:	000065b7          	lui	a1,0x6
    34e0:	02058593          	addi	a1,a1,32 # 6020 <_data+0x6c>
    34e4:	dddff0ef          	jal	32c0 <app>
    34e8:	00100613          	li	a2,1
    34ec:	001a0593          	addi	a1,s4,1
    34f0:	dedff0ef          	jal	32dc <appn>
    p = app(p, ":");    p = app(p, scene_name(scene));
    34f4:	000065b7          	lui	a1,0x6
    34f8:	02458593          	addi	a1,a1,36 # 6024 <_data+0x70>
    34fc:	dc5ff0ef          	jal	32c0 <app>
    3500:	00050413          	mv	s0,a0
    3504:	000a0513          	mv	a0,s4
    3508:	ea5ff0ef          	jal	33ac <scene_name>
    350c:	00050593          	mv	a1,a0
    3510:	00040513          	mv	a0,s0
    3514:	dadff0ef          	jal	32c0 <app>
    p = app(p, " A=");  p = appn(p, alpha, 3);
    3518:	000065b7          	lui	a1,0x6
    351c:	02858593          	addi	a1,a1,40 # 6028 <_data+0x74>
    3520:	da1ff0ef          	jal	32c0 <app>
    3524:	00300613          	li	a2,3
    3528:	00090593          	mv	a1,s2
    352c:	db1ff0ef          	jal	32dc <appn>
    p = app(p, " B=");  p = appn(p, busy, 3);
    3530:	000065b7          	lui	a1,0x6
    3534:	02c58593          	addi	a1,a1,44 # 602c <_data+0x78>
    3538:	d89ff0ef          	jal	32c0 <app>
    353c:	00300613          	li	a2,3
    3540:	00048593          	mv	a1,s1
    3544:	d99ff0ef          	jal	32dc <appn>
    if (frame_adv) p = app(p, " FR");
    3548:	02012783          	lw	a5,32(sp)
    354c:	04079863          	bnez	a5,359c <fmt_stat+0x194>
    if (fx)        p = app(p, " F");
    3550:	02412783          	lw	a5,36(sp)
    3554:	04079c63          	bnez	a5,35ac <fmt_stat+0x1a4>
    if (scis)      p = app(p, " X");
    3558:	02812783          	lw	a5,40(sp)
    355c:	06079063          	bnez	a5,35bc <fmt_stat+0x1b4>
    if (attr)      p = app(p, " Y");
    3560:	02c12783          	lw	a5,44(sp)
    3564:	06079463          	bnez	a5,35cc <fmt_stat+0x1c4>
    if (autoq)     p = app(p, " Q");
    3568:	03012783          	lw	a5,48(sp)
    356c:	06079863          	bnez	a5,35dc <fmt_stat+0x1d4>
    *p = 0;
    3570:	00050023          	sb	zero,0(a0)
}
    3574:	01c12083          	lw	ra,28(sp)
    3578:	01812403          	lw	s0,24(sp)
    357c:	01412483          	lw	s1,20(sp)
    3580:	01012903          	lw	s2,16(sp)
    3584:	00c12983          	lw	s3,12(sp)
    3588:	00812a03          	lw	s4,8(sp)
    358c:	00412a83          	lw	s5,4(sp)
    3590:	00012b03          	lw	s6,0(sp)
    3594:	02010113          	addi	sp,sp,32
    3598:	00008067          	ret
    if (frame_adv) p = app(p, " FR");
    359c:	000065b7          	lui	a1,0x6
    35a0:	03058593          	addi	a1,a1,48 # 6030 <_data+0x7c>
    35a4:	d1dff0ef          	jal	32c0 <app>
    35a8:	fa9ff06f          	j	3550 <fmt_stat+0x148>
    if (fx)        p = app(p, " F");
    35ac:	000065b7          	lui	a1,0x6
    35b0:	03458593          	addi	a1,a1,52 # 6034 <_data+0x80>
    35b4:	d0dff0ef          	jal	32c0 <app>
    35b8:	fa1ff06f          	j	3558 <fmt_stat+0x150>
    if (scis)      p = app(p, " X");
    35bc:	000065b7          	lui	a1,0x6
    35c0:	03858593          	addi	a1,a1,56 # 6038 <_data+0x84>
    35c4:	cfdff0ef          	jal	32c0 <app>
    35c8:	f99ff06f          	j	3560 <fmt_stat+0x158>
    if (attr)      p = app(p, " Y");
    35cc:	000065b7          	lui	a1,0x6
    35d0:	03c58593          	addi	a1,a1,60 # 603c <_data+0x88>
    35d4:	cedff0ef          	jal	32c0 <app>
    35d8:	f91ff06f          	j	3568 <fmt_stat+0x160>
    if (autoq)     p = app(p, " Q");
    35dc:	000065b7          	lui	a1,0x6
    35e0:	04058593          	addi	a1,a1,64 # 6040 <_data+0x8c>
    35e4:	cddff0ef          	jal	32c0 <app>
    35e8:	f89ff06f          	j	3570 <fmt_stat+0x168>

000035ec <slen>:
static int slen(const char *s) { int n = 0; while (s[n]) n++; return n; }
    35ec:	00050713          	mv	a4,a0
    35f0:	00000513          	li	a0,0
    35f4:	0080006f          	j	35fc <slen+0x10>
    35f8:	00150513          	addi	a0,a0,1
    35fc:	00a707b3          	add	a5,a4,a0
    3600:	0007c783          	lbu	a5,0(a5)
    3604:	fe079ae3          	bnez	a5,35f8 <slen+0xc>
    3608:	00008067          	ret

0000360c <osd_build>:
{
    360c:	f8010113          	addi	sp,sp,-128
    3610:	06112e23          	sw	ra,124(sp)
    fmt_stat(tmp, g_fps, n, scene, g_blk, alpha, g_mpx, g_busy, frame_adv, fx, scis, attr, autoq);
    3614:	01112823          	sw	a7,16(sp)
    3618:	01012623          	sw	a6,12(sp)
    361c:	00f12423          	sw	a5,8(sp)
    3620:	00e12223          	sw	a4,4(sp)
    3624:	00d12023          	sw	a3,0(sp)
    3628:	9081a883          	lw	a7,-1784(gp) # 7930 <g_busy>
    362c:	90c1a803          	lw	a6,-1780(gp) # 7934 <g_mpx>
    3630:	00060793          	mv	a5,a2
    3634:	85c1a703          	lw	a4,-1956(gp) # 7884 <g_blk>
    3638:	00058693          	mv	a3,a1
    363c:	00050613          	mv	a2,a0
    3640:	9101a583          	lw	a1,-1776(gp) # 7938 <g_fps>
    3644:	02410513          	addi	a0,sp,36
    3648:	dc1ff0ef          	jal	3408 <fmt_stat>
    if (!sseq(tmp, g_osd_line)) { scpy(g_osd_line, tmp); g_osd_dirty = 1; }
    364c:	99818593          	addi	a1,gp,-1640 # 79c0 <g_osd_line>
    3650:	02410513          	addi	a0,sp,36
    3654:	d15ff0ef          	jal	3368 <sseq>
    3658:	00050863          	beqz	a0,3668 <osd_build+0x5c>
}
    365c:	07c12083          	lw	ra,124(sp)
    3660:	08010113          	addi	sp,sp,128
    3664:	00008067          	ret
    if (!sseq(tmp, g_osd_line)) { scpy(g_osd_line, tmp); g_osd_dirty = 1; }
    3668:	02410593          	addi	a1,sp,36
    366c:	99818513          	addi	a0,gp,-1640 # 79c0 <g_osd_line>
    3670:	d25ff0ef          	jal	3394 <scpy>
    3674:	00100713          	li	a4,1
    3678:	82e1aa23          	sw	a4,-1996(gp) # 785c <g_osd_dirty>
}
    367c:	fe1ff06f          	j	365c <osd_build+0x50>

00003680 <osd_service>:
{
    3680:	fe010113          	addi	sp,sp,-32
    3684:	00112e23          	sw	ra,28(sp)
    3688:	00812c23          	sw	s0,24(sp)
    368c:	01312623          	sw	s3,12(sp)
    3690:	00060413          	mv	s0,a2
    3694:	00078993          	mv	s3,a5
    uint32_t el = (uint32_t)(t_now - g_osd_t0);
    3698:	9141a603          	lw	a2,-1772(gp) # 793c <g_osd_t0>
    369c:	40c50633          	sub	a2,a0,a2
    if (el < (uint32_t)BSP_CLINT_HZ) return 0;
    36a0:	05f5e7b7          	lui	a5,0x5f5e
    36a4:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f40ecf>
    36a8:	0ec7f663          	bgeu	a5,a2,3794 <osd_service+0x114>
    36ac:	00912a23          	sw	s1,20(sp)
    36b0:	01212823          	sw	s2,16(sp)
    36b4:	01412423          	sw	s4,8(sp)
    36b8:	01512223          	sw	s5,4(sp)
    36bc:	00058313          	mv	t1,a1
    36c0:	00068493          	mv	s1,a3
    36c4:	00070913          	mv	s2,a4
    36c8:	00080a13          	mv	s4,a6
    36cc:	00088a93          	mv	s5,a7
    g_osd_t0 = t_now;
    36d0:	90a1aa23          	sw	a0,-1772(gp) # 793c <g_osd_t0>
    g_fps    = (uint32_t)(((uint64_t)scr_frames * (uint64_t)BSP_CLINT_HZ) / el);
    36d4:	05f5e537          	lui	a0,0x5f5e
    36d8:	10050513          	addi	a0,a0,256 # 5f5e100 <__freertos_irq_stack_top+0x5f40ed0>
    36dc:	02a5b5b3          	mulhu	a1,a1,a0
    36e0:	00000693          	li	a3,0
    36e4:	02a30533          	mul	a0,t1,a0
    36e8:	41c020ef          	jal	5b04 <__udivdi3>
    36ec:	90a1a823          	sw	a0,-1776(gp) # 7938 <g_fps>
    g_mpx = (unsigned)(((uint64_t)(uint32_t)n * (uint64_t)(uint32_t)(g_blk * g_blk) *
    36f0:	85c1a303          	lw	t1,-1956(gp) # 7884 <g_blk>
    36f4:	02630333          	mul	t1,t1,t1
    36f8:	026407b3          	mul	a5,s0,t1
    36fc:	02643333          	mulhu	t1,s0,t1
    3700:	02a30333          	mul	t1,t1,a0
    3704:	02f535b3          	mulhu	a1,a0,a5
                         (uint64_t)g_fps) / 1000000ull);
    3708:	000f4637          	lui	a2,0xf4
    370c:	24060613          	addi	a2,a2,576 # f4240 <__freertos_irq_stack_top+0xd7010>
    3710:	00000693          	li	a3,0
    3714:	02a78533          	mul	a0,a5,a0
    3718:	00b305b3          	add	a1,t1,a1
    371c:	3e8020ef          	jal	5b04 <__udivdi3>
    g_mpx = (unsigned)(((uint64_t)(uint32_t)n * (uint64_t)(uint32_t)(g_blk * g_blk) *
    3720:	90a1a623          	sw	a0,-1780(gp) # 7934 <g_mpx>
    g_busy = (g_busy_s > 0u) ? (unsigned)((g_busy_n * 100u) / g_busy_s) : 0u;
    3724:	9001a783          	lw	a5,-1792(gp) # 7928 <g_busy_s>
    3728:	00078a63          	beqz	a5,373c <osd_service+0xbc>
    372c:	9041a683          	lw	a3,-1788(gp) # 792c <g_busy_n>
    3730:	06400713          	li	a4,100
    3734:	02d70733          	mul	a4,a4,a3
    3738:	02f757b3          	divu	a5,a4,a5
    373c:	90f1a423          	sw	a5,-1784(gp) # 7930 <g_busy>
    g_busy_n = 0; g_busy_s = 0;
    3740:	9001a223          	sw	zero,-1788(gp) # 792c <g_busy_n>
    3744:	9001a023          	sw	zero,-1792(gp) # 7928 <g_busy_s>
    osd_build(n, scene, alpha, frame_adv, fx, scis, attr, autoq);
    3748:	02412883          	lw	a7,36(sp)
    374c:	02012803          	lw	a6,32(sp)
    3750:	000a8793          	mv	a5,s5
    3754:	000a0713          	mv	a4,s4
    3758:	00098693          	mv	a3,s3
    375c:	00090613          	mv	a2,s2
    3760:	00048593          	mv	a1,s1
    3764:	00040513          	mv	a0,s0
    3768:	ea5ff0ef          	jal	360c <osd_build>
    return 1;
    376c:	00100513          	li	a0,1
    3770:	01412483          	lw	s1,20(sp)
    3774:	01012903          	lw	s2,16(sp)
    3778:	00812a03          	lw	s4,8(sp)
    377c:	00412a83          	lw	s5,4(sp)
}
    3780:	01c12083          	lw	ra,28(sp)
    3784:	01812403          	lw	s0,24(sp)
    3788:	00c12983          	lw	s3,12(sp)
    378c:	02010113          	addi	sp,sp,32
    3790:	00008067          	ret
    if (el < (uint32_t)BSP_CLINT_HZ) return 0;
    3794:	00000513          	li	a0,0
    3798:	fe9ff06f          	j	3780 <osd_service+0x100>

0000379c <uart_status_raw>:
    return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS);
    379c:	f80107b7          	lui	a5,0xf8010
    37a0:	0047a503          	lw	a0,4(a5) # f8010004 <__freertos_irq_stack_top+0xf7ff2dd4>
}
    37a4:	00008067          	ret

000037a8 <uart_poll_char>:
{
    37a8:	ff010113          	addi	sp,sp,-16
    37ac:	00112623          	sw	ra,12(sp)
    if ((uart_status_raw() >> 24) == 0u) return 0;
    37b0:	fedff0ef          	jal	379c <uart_status_raw>
    37b4:	01855513          	srli	a0,a0,0x18
    37b8:	00050e63          	beqz	a0,37d4 <uart_poll_char+0x2c>
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
    37bc:	f80107b7          	lui	a5,0xf8010
    37c0:	0007a503          	lw	a0,0(a5) # f8010000 <__freertos_irq_stack_top+0xf7ff2dd0>
    37c4:	0ff57513          	zext.b	a0,a0
}
    37c8:	00c12083          	lw	ra,12(sp)
    37cc:	01010113          	addi	sp,sp,16
    37d0:	00008067          	ret
    if ((uart_status_raw() >> 24) == 0u) return 0;
    37d4:	00000513          	li	a0,0
    37d8:	ff1ff06f          	j	37c8 <uart_poll_char+0x20>

000037dc <nline_feed>:
{
    37dc:	00050793          	mv	a5,a0
    if (!g_nl_on) {
    37e0:	8f81a503          	lw	a0,-1800(gp) # 7920 <g_nl_on>
    37e4:	02051263          	bnez	a0,3808 <nline_feed+0x2c>
        if (c != '=') return NL_NONE;
    37e8:	03d00713          	li	a4,61
    37ec:	00e78463          	beq	a5,a4,37f4 <nline_feed+0x18>
}
    37f0:	00008067          	ret
        g_nl_on = 1; g_nl_n = 0;
    37f4:	00100713          	li	a4,1
    37f8:	8ee1ac23          	sw	a4,-1800(gp) # 7920 <g_nl_on>
    37fc:	8e01ae23          	sw	zero,-1796(gp) # 7924 <g_nl_n>
        return NL_MORE;
    3800:	00100513          	li	a0,1
    3804:	00008067          	ret
    if (c == '\n' || c == '\r') {
    3808:	00a00713          	li	a4,10
    380c:	04e78063          	beq	a5,a4,384c <nline_feed+0x70>
    3810:	00d00713          	li	a4,13
    3814:	02e78c63          	beq	a5,a4,384c <nline_feed+0x70>
    if (c < '0' || c > '9' || g_nl_n >= (unsigned)NLINE_MAX) {
    3818:	fd078713          	addi	a4,a5,-48
    381c:	00900693          	li	a3,9
    3820:	08e6ec63          	bltu	a3,a4,38b8 <nline_feed+0xdc>
    3824:	8fc1a683          	lw	a3,-1796(gp) # 7924 <g_nl_n>
    3828:	00b00713          	li	a4,11
    382c:	08d76663          	bltu	a4,a3,38b8 <nline_feed+0xdc>
    g_nl[g_nl_n++] = (char)c;
    3830:	00168613          	addi	a2,a3,1
    3834:	8ec1ae23          	sw	a2,-1796(gp) # 7924 <g_nl_n>
    3838:	98c18713          	addi	a4,gp,-1652 # 79b4 <g_nl>
    383c:	00d70733          	add	a4,a4,a3
    3840:	00f70023          	sb	a5,0(a4)
    return NL_MORE;
    3844:	00100513          	li	a0,1
    3848:	00008067          	ret
        g_nl_on = 0;
    384c:	8e01ac23          	sw	zero,-1800(gp) # 7920 <g_nl_on>
        if (g_nl_n == 0u) return NL_ERR;
    3850:	8fc1a603          	lw	a2,-1796(gp) # 7924 <g_nl_n>
    3854:	06060863          	beqz	a2,38c4 <nline_feed+0xe8>
        for (i = 0; i < g_nl_n; i++) {
    3858:	00000693          	li	a3,0
        v = 0u;
    385c:	00000793          	li	a5,0
    3860:	0080006f          	j	3868 <nline_feed+0x8c>
        for (i = 0; i < g_nl_n; i++) {
    3864:	00168693          	addi	a3,a3,1
    3868:	02c6fc63          	bgeu	a3,a2,38a0 <nline_feed+0xc4>
            v = v * 10u + (unsigned)(g_nl[i] - '0');
    386c:	00279713          	slli	a4,a5,0x2
    3870:	00f70733          	add	a4,a4,a5
    3874:	00171713          	slli	a4,a4,0x1
    3878:	98c18793          	addi	a5,gp,-1652 # 79b4 <g_nl>
    387c:	00d787b3          	add	a5,a5,a3
    3880:	0007c783          	lbu	a5,0(a5)
    3884:	00e787b3          	add	a5,a5,a4
    3888:	fd078793          	addi	a5,a5,-48
            if (v > (unsigned)N_MAX) v = (unsigned)N_MAX;       /* 边收边钳，不会溢出 */
    388c:	00001737          	lui	a4,0x1
    3890:	77070713          	addi	a4,a4,1904 # 1770 <main+0x66c>
    3894:	fcf778e3          	bgeu	a4,a5,3864 <nline_feed+0x88>
    3898:	00070793          	mv	a5,a4
    389c:	fc9ff06f          	j	3864 <nline_feed+0x88>
        if (v < (unsigned)N_MIN) v = (unsigned)N_MIN;
    38a0:	00f00713          	li	a4,15
    38a4:	00f76463          	bltu	a4,a5,38ac <nline_feed+0xd0>
    38a8:	01000793          	li	a5,16
        *out = (int)v;
    38ac:	00f5a023          	sw	a5,0(a1)
        return NL_OK;
    38b0:	00200513          	li	a0,2
    38b4:	00008067          	ret
        g_nl_on = 0;
    38b8:	8e01ac23          	sw	zero,-1800(gp) # 7920 <g_nl_on>
        return NL_ERR;
    38bc:	fff00513          	li	a0,-1
    38c0:	00008067          	ret
        if (g_nl_n == 0u) return NL_ERR;
    38c4:	fff00513          	li	a0,-1
    38c8:	00008067          	ret

000038cc <clip_local>:
    int x0 = CLIP_SX0 - dx, x1 = CLIP_SX1 - dx;
    38cc:	0c800793          	li	a5,200
    38d0:	40a787b3          	sub	a5,a5,a0
    38d4:	2f800893          	li	a7,760
    38d8:	40a888b3          	sub	a7,a7,a0
    int y0 = CLIP_SY0 - dy, y1 = CLIP_SY1 - dy;
    38dc:	07000813          	li	a6,112
    38e0:	40b80833          	sub	a6,a6,a1
    38e4:	1e800513          	li	a0,488
    38e8:	40b505b3          	sub	a1,a0,a1
    if (x0 < 0) x0 = 0;
    38ec:	0207cc63          	bltz	a5,3924 <clip_local+0x58>
    if (y0 < 0) y0 = 0;
    38f0:	02084e63          	bltz	a6,392c <clip_local+0x60>
    if (x1 > w) x1 = w;
    38f4:	01164463          	blt	a2,a7,38fc <clip_local+0x30>
    int x0 = CLIP_SX0 - dx, x1 = CLIP_SX1 - dx;
    38f8:	00088613          	mv	a2,a7
    if (y1 > h) y1 = h;
    38fc:	00b6c463          	blt	a3,a1,3904 <clip_local+0x38>
    int y0 = CLIP_SY0 - dy, y1 = CLIP_SY1 - dy;
    3900:	00058693          	mv	a3,a1
    out->x0 = x0; out->x1 = x1; out->y0 = y0; out->y1 = y1;
    3904:	00f72023          	sw	a5,0(a4)
    3908:	00c72223          	sw	a2,4(a4)
    390c:	01072423          	sw	a6,8(a4)
    3910:	00d72623          	sw	a3,12(a4)
    return (x0 < x1 && y0 < y1) ? 1 : 0;
    3914:	02c7d063          	bge	a5,a2,3934 <clip_local+0x68>
    3918:	02d84263          	blt	a6,a3,393c <clip_local+0x70>
    391c:	00000513          	li	a0,0
    3920:	00008067          	ret
    if (x0 < 0) x0 = 0;
    3924:	00000793          	li	a5,0
    3928:	fc9ff06f          	j	38f0 <clip_local+0x24>
    if (y0 < 0) y0 = 0;
    392c:	00000813          	li	a6,0
    3930:	fc5ff06f          	j	38f4 <clip_local+0x28>
    return (x0 < x1 && y0 < y1) ? 1 : 0;
    3934:	00000513          	li	a0,0
    3938:	00008067          	ret
    393c:	00100513          	li	a0,1
}
    3940:	00008067          	ret

00003944 <osd_strip_rect>:
static void osd_strip_rect(irect_t *r) { r->dx = 0;  r->dy = 0;         r->w = FB_WIDTH;   r->h = OSD_H; }
    3944:	00052023          	sw	zero,0(a0)
    3948:	00052223          	sw	zero,4(a0)
    394c:	3c000793          	li	a5,960
    3950:	00f52423          	sw	a5,8(a0)
    3954:	01000793          	li	a5,16
    3958:	00f52623          	sw	a5,12(a0)
    395c:	00008067          	ret

00003960 <osd_glyph_rect>:
                 : (FB_WIDTH - OSD_GLYPH_W * len + OSD_GLYPH_W * k);
    3960:	02068463          	beqz	a3,3988 <osd_glyph_rect+0x28>
    r->dx = left ? (OSD_TEXT_X0 + OSD_GLYPH_W * k)
    3964:	00150513          	addi	a0,a0,1
                 : (FB_WIDTH - OSD_GLYPH_W * len + OSD_GLYPH_W * k);
    3968:	00351793          	slli	a5,a0,0x3
    r->dx = left ? (OSD_TEXT_X0 + OSD_GLYPH_W * k)
    396c:	00f62023          	sw	a5,0(a2)
    r->dy = OSD_TEXT_Y; r->w = OSD_GLYPH_W; r->h = OSD_GLYPH_H;
    3970:	00400793          	li	a5,4
    3974:	00f62223          	sw	a5,4(a2)
    3978:	00800793          	li	a5,8
    397c:	00f62423          	sw	a5,8(a2)
    3980:	00f62623          	sw	a5,12(a2)
}
    3984:	00008067          	ret
                 : (FB_WIDTH - OSD_GLYPH_W * len + OSD_GLYPH_W * k);
    3988:	07800793          	li	a5,120
    398c:	40b787b3          	sub	a5,a5,a1
    3990:	00a78533          	add	a0,a5,a0
    3994:	00351793          	slli	a5,a0,0x3
    3998:	fd5ff06f          	j	396c <osd_glyph_rect+0xc>

0000399c <clip_edge_rect>:
    if (k == 0)      { r->dx = PLAY_X0;         r->dy = TOP_Y0 + PLAY_Y0 - 2; r->w = PLAY_X1 - PLAY_X0; r->h = 2; }
    399c:	02051463          	bnez	a0,39c4 <clip_edge_rect+0x28>
    39a0:	0c800793          	li	a5,200
    39a4:	00f5a023          	sw	a5,0(a1)
    39a8:	06e00793          	li	a5,110
    39ac:	00f5a223          	sw	a5,4(a1)
    39b0:	23000793          	li	a5,560
    39b4:	00f5a423          	sw	a5,8(a1)
    39b8:	00200793          	li	a5,2
    39bc:	00f5a623          	sw	a5,12(a1)
    39c0:	00008067          	ret
    else if (k == 1) { r->dx = PLAY_X0;         r->dy = TOP_Y0 + PLAY_Y1;     r->w = PLAY_X1 - PLAY_X0; r->h = 2; }
    39c4:	00100793          	li	a5,1
    39c8:	02f50863          	beq	a0,a5,39f8 <clip_edge_rect+0x5c>
    else if (k == 2) { r->dx = PLAY_X0 - 2;     r->dy = TOP_Y0 + PLAY_Y0;     r->w = 2;                 r->h = PLAY_Y1 - PLAY_Y0; }
    39cc:	00200793          	li	a5,2
    39d0:	04f50663          	beq	a0,a5,3a1c <clip_edge_rect+0x80>
    else             { r->dx = PLAY_X1;         r->dy = TOP_Y0 + PLAY_Y0;     r->w = 2;                 r->h = PLAY_Y1 - PLAY_Y0; }
    39d4:	2f800793          	li	a5,760
    39d8:	00f5a023          	sw	a5,0(a1)
    39dc:	07000793          	li	a5,112
    39e0:	00f5a223          	sw	a5,4(a1)
    39e4:	00200793          	li	a5,2
    39e8:	00f5a423          	sw	a5,8(a1)
    39ec:	17800793          	li	a5,376
    39f0:	00f5a623          	sw	a5,12(a1)
}
    39f4:	00008067          	ret
    else if (k == 1) { r->dx = PLAY_X0;         r->dy = TOP_Y0 + PLAY_Y1;     r->w = PLAY_X1 - PLAY_X0; r->h = 2; }
    39f8:	0c800793          	li	a5,200
    39fc:	00f5a023          	sw	a5,0(a1)
    3a00:	1e800793          	li	a5,488
    3a04:	00f5a223          	sw	a5,4(a1)
    3a08:	23000793          	li	a5,560
    3a0c:	00f5a423          	sw	a5,8(a1)
    3a10:	00200793          	li	a5,2
    3a14:	00f5a623          	sw	a5,12(a1)
    3a18:	00008067          	ret
    else if (k == 2) { r->dx = PLAY_X0 - 2;     r->dy = TOP_Y0 + PLAY_Y0;     r->w = 2;                 r->h = PLAY_Y1 - PLAY_Y0; }
    3a1c:	0c600793          	li	a5,198
    3a20:	00f5a023          	sw	a5,0(a1)
    3a24:	07000793          	li	a5,112
    3a28:	00f5a223          	sw	a5,4(a1)
    3a2c:	00200793          	li	a5,2
    3a30:	00f5a423          	sw	a5,8(a1)
    3a34:	17800793          	li	a5,376
    3a38:	00f5a623          	sw	a5,12(a1)
    3a3c:	00008067          	ret

00003a40 <hud_rect>:
    r->dx = HUD_X0; r->dy = TOP_Y0 + HUD_Y0; r->w = HUD_W; r->h = HUD_H;
    3a40:	30800793          	li	a5,776
    3a44:	00f5a023          	sw	a5,0(a1)
    3a48:	02800793          	li	a5,40
    3a4c:	00f5a223          	sw	a5,4(a1)
    3a50:	0b000793          	li	a5,176
    3a54:	00f5a423          	sw	a5,8(a1)
    3a58:	1fc00793          	li	a5,508
    3a5c:	00f5a623          	sw	a5,12(a1)
    if (k == 0) return;                                  /* 底板 */
    3a60:	02050e63          	beqz	a0,3a9c <hud_rect+0x5c>
    if (k <= 4) {                                        /* 4 条边框 */
    3a64:	00400793          	li	a5,4
    3a68:	02a7dc63          	bge	a5,a0,3aa0 <hud_rect+0x60>
        int i = k - 5;
    3a6c:	ffb50513          	addi	a0,a0,-5
        r->dx = HUD_X0 + 16; r->dy = TOP_Y0 + HUD_Y0 + 28 + i * 40; r->w = 144; r->h = 10;
    3a70:	31800793          	li	a5,792
    3a74:	00f5a023          	sw	a5,0(a1)
    3a78:	00251793          	slli	a5,a0,0x2
    3a7c:	00a787b3          	add	a5,a5,a0
    3a80:	00379793          	slli	a5,a5,0x3
    3a84:	04478793          	addi	a5,a5,68
    3a88:	00f5a223          	sw	a5,4(a1)
    3a8c:	09000793          	li	a5,144
    3a90:	00f5a423          	sw	a5,8(a1)
    3a94:	00a00793          	li	a5,10
    3a98:	00f5a623          	sw	a5,12(a1)
}
    3a9c:	00008067          	ret
        if (k == 1) { r->h = 2; }
    3aa0:	00100793          	li	a5,1
    3aa4:	02f50463          	beq	a0,a5,3acc <hud_rect+0x8c>
        else if (k == 2) { r->dy += HUD_H - 2; r->h = 2; }
    3aa8:	00200793          	li	a5,2
    3aac:	02f50663          	beq	a0,a5,3ad8 <hud_rect+0x98>
        else if (k == 3) { r->w = 2; }
    3ab0:	00300793          	li	a5,3
    3ab4:	02f50c63          	beq	a0,a5,3aec <hud_rect+0xac>
        else { r->dx += HUD_W - 2; r->w = 2; }
    3ab8:	3b600793          	li	a5,950
    3abc:	00f5a023          	sw	a5,0(a1)
    3ac0:	00200793          	li	a5,2
    3ac4:	00f5a423          	sw	a5,8(a1)
        return;
    3ac8:	00008067          	ret
        if (k == 1) { r->h = 2; }
    3acc:	00200793          	li	a5,2
    3ad0:	00f5a623          	sw	a5,12(a1)
    3ad4:	00008067          	ret
        else if (k == 2) { r->dy += HUD_H - 2; r->h = 2; }
    3ad8:	22200793          	li	a5,546
    3adc:	00f5a223          	sw	a5,4(a1)
    3ae0:	00200793          	li	a5,2
    3ae4:	00f5a623          	sw	a5,12(a1)
    3ae8:	00008067          	ret
        else if (k == 3) { r->w = 2; }
    3aec:	00200793          	li	a5,2
    3af0:	00f5a423          	sw	a5,8(a1)
    3af4:	00008067          	ret

00003af8 <clip_apply>:
    if (!g_feat_clip) { g_clip_on = 0; return; }
    3af8:	9541a783          	lw	a5,-1708(gp) # 797c <g_feat_clip>
    3afc:	0a078263          	beqz	a5,3ba0 <clip_apply+0xa8>
{
    3b00:	fe010113          	addi	sp,sp,-32
    3b04:	00112e23          	sw	ra,28(sp)
    3b08:	00812c23          	sw	s0,24(sp)
    3b0c:	00912a23          	sw	s1,20(sp)
    3b10:	01212823          	sw	s2,16(sp)
    3b14:	01312623          	sw	s3,12(sp)
    3b18:	01412423          	sw	s4,8(sp)
    3b1c:	00050413          	mv	s0,a0
    3b20:	00058a13          	mv	s4,a1
    3b24:	00060993          	mv	s3,a2
    3b28:	00068913          	mv	s2,a3
    3b2c:	00070493          	mv	s1,a4
    if (on) {
    3b30:	06050c63          	beqz	a0,3ba8 <clip_apply+0xb0>
        blt_wr(BLT_CLIP_X0, (uint32_t)x0);
    3b34:	09000513          	li	a0,144
    3b38:	ccdfe0ef          	jal	2804 <blt_wr>
        blt_wr(BLT_CLIP_X1, (uint32_t)x1);
    3b3c:	00098593          	mv	a1,s3
    3b40:	09400513          	li	a0,148
    3b44:	cc1fe0ef          	jal	2804 <blt_wr>
        blt_wr(BLT_CLIP_Y0, (uint32_t)y0);
    3b48:	00090593          	mv	a1,s2
    3b4c:	09800513          	li	a0,152
    3b50:	cb5fe0ef          	jal	2804 <blt_wr>
        blt_wr(BLT_CLIP_Y1, (uint32_t)y1);
    3b54:	00048593          	mv	a1,s1
    3b58:	09c00513          	li	a0,156
    3b5c:	ca9fe0ef          	jal	2804 <blt_wr>
        blt_wr(BLT_CLIP_CTRL, BLT_CLIP_EN);
    3b60:	00100593          	li	a1,1
    3b64:	0a000513          	li	a0,160
    3b68:	c9dfe0ef          	jal	2804 <blt_wr>
    g_clip_on = on; g_cx0 = x0; g_cx1 = x1; g_cy0 = y0; g_cy1 = y1;
    3b6c:	9481a223          	sw	s0,-1724(gp) # 796c <g_clip_on>
    3b70:	8f41aa23          	sw	s4,-1804(gp) # 791c <g_cx0>
    3b74:	8f31a823          	sw	s3,-1808(gp) # 7918 <g_cx1>
    3b78:	8f21a623          	sw	s2,-1812(gp) # 7914 <g_cy0>
    3b7c:	8e91a423          	sw	s1,-1816(gp) # 7910 <g_cy1>
}
    3b80:	01c12083          	lw	ra,28(sp)
    3b84:	01812403          	lw	s0,24(sp)
    3b88:	01412483          	lw	s1,20(sp)
    3b8c:	01012903          	lw	s2,16(sp)
    3b90:	00c12983          	lw	s3,12(sp)
    3b94:	00812a03          	lw	s4,8(sp)
    3b98:	02010113          	addi	sp,sp,32
    3b9c:	00008067          	ret
    if (!g_feat_clip) { g_clip_on = 0; return; }
    3ba0:	9401a223          	sw	zero,-1724(gp) # 796c <g_clip_on>
    3ba4:	00008067          	ret
        blt_wr(BLT_CLIP_CTRL, 0u);
    3ba8:	00000593          	li	a1,0
    3bac:	0a000513          	li	a0,160
    3bb0:	c55fe0ef          	jal	2804 <blt_wr>
    3bb4:	fb9ff06f          	j	3b6c <clip_apply+0x74>

00003bb8 <clip_off>:
static void clip_off(void) { clip_apply(0, 0, 0, 0, 0); }
    3bb8:	ff010113          	addi	sp,sp,-16
    3bbc:	00112623          	sw	ra,12(sp)
    3bc0:	00000713          	li	a4,0
    3bc4:	00000693          	li	a3,0
    3bc8:	00000613          	li	a2,0
    3bcc:	00000593          	li	a1,0
    3bd0:	00000513          	li	a0,0
    3bd4:	f25ff0ef          	jal	3af8 <clip_apply>
    3bd8:	00c12083          	lw	ra,12(sp)
    3bdc:	01010113          	addi	sp,sp,16
    3be0:	00008067          	ret

00003be4 <clip_forget>:
static void clip_forget(void) { g_clip_on = 0; g_cx0 = 0; g_cx1 = 0; g_cy0 = 0; g_cy1 = 0; }
    3be4:	9401a223          	sw	zero,-1724(gp) # 796c <g_clip_on>
    3be8:	8e01aa23          	sw	zero,-1804(gp) # 791c <g_cx0>
    3bec:	8e01a823          	sw	zero,-1808(gp) # 7918 <g_cx1>
    3bf0:	8e01a623          	sw	zero,-1812(gp) # 7914 <g_cy0>
    3bf4:	8e01a423          	sw	zero,-1816(gp) # 7910 <g_cy1>
    3bf8:	00008067          	ret

00003bfc <clip_arm>:
static void clip_arm(const iclip_t *w) { clip_apply(1, w->x0, w->x1, w->y0, w->y1); }
    3bfc:	ff010113          	addi	sp,sp,-16
    3c00:	00112623          	sw	ra,12(sp)
    3c04:	00c52703          	lw	a4,12(a0)
    3c08:	00852683          	lw	a3,8(a0)
    3c0c:	00452603          	lw	a2,4(a0)
    3c10:	00052583          	lw	a1,0(a0)
    3c14:	00100513          	li	a0,1
    3c18:	ee1ff0ef          	jal	3af8 <clip_apply>
    3c1c:	00c12083          	lw	ra,12(sp)
    3c20:	01010113          	addi	sp,sp,16
    3c24:	00008067          	ret

00003c28 <clip_same>:
    return (g_clip_on && w->x0 == g_cx0 && w->x1 == g_cx1 && w->y0 == g_cy0 && w->y1 == g_cy1) ? 1 : 0;
    3c28:	9441a783          	lw	a5,-1724(gp) # 796c <g_clip_on>
    3c2c:	04078a63          	beqz	a5,3c80 <clip_same+0x58>
    3c30:	00052703          	lw	a4,0(a0)
    3c34:	8f41a783          	lw	a5,-1804(gp) # 791c <g_cx0>
    3c38:	00f70663          	beq	a4,a5,3c44 <clip_same+0x1c>
    3c3c:	00000513          	li	a0,0
    3c40:	00008067          	ret
    3c44:	00452703          	lw	a4,4(a0)
    3c48:	8f01a783          	lw	a5,-1808(gp) # 7918 <g_cx1>
    3c4c:	00f70663          	beq	a4,a5,3c58 <clip_same+0x30>
    3c50:	00000513          	li	a0,0
    3c54:	00008067          	ret
    3c58:	00852703          	lw	a4,8(a0)
    3c5c:	8ec1a783          	lw	a5,-1812(gp) # 7914 <g_cy0>
    3c60:	00f70663          	beq	a4,a5,3c6c <clip_same+0x44>
    3c64:	00000513          	li	a0,0
    3c68:	00008067          	ret
    3c6c:	00c52703          	lw	a4,12(a0)
    3c70:	8e81a783          	lw	a5,-1816(gp) # 7910 <g_cy1>
    3c74:	00f70a63          	beq	a4,a5,3c88 <clip_same+0x60>
    3c78:	00000513          	li	a0,0
    3c7c:	00008067          	ret
    3c80:	00000513          	li	a0,0
    3c84:	00008067          	ret
    3c88:	00100513          	li	a0,1
}
    3c8c:	00008067          	ret

00003c90 <st_wait_state>:
    if (idle) { *cur_which = -1; return ST_WAIT_IDLE; }
    3c90:	02059463          	bnez	a1,3cb8 <st_wait_state+0x28>
    if (*cur_which != which) { *cur_which = which; *cur_t0 = now; }
    3c94:	00072803          	lw	a6,0(a4)
    3c98:	00a80663          	beq	a6,a0,3ca4 <st_wait_state+0x14>
    3c9c:	00a72023          	sw	a0,0(a4)
    3ca0:	00c7a023          	sw	a2,0(a5)
    if ((uint32_t)(now - *cur_t0) > ticks) return ST_WAIT_TIMEO;
    3ca4:	0007a783          	lw	a5,0(a5)
    3ca8:	40f60633          	sub	a2,a2,a5
    3cac:	00c6ee63          	bltu	a3,a2,3cc8 <st_wait_state+0x38>
    return ST_WAIT_MORE;
    3cb0:	00058513          	mv	a0,a1
    3cb4:	00008067          	ret
    if (idle) { *cur_which = -1; return ST_WAIT_IDLE; }
    3cb8:	fff00793          	li	a5,-1
    3cbc:	00f72023          	sw	a5,0(a4)
    3cc0:	00100513          	li	a0,1
    3cc4:	00008067          	ret
    if ((uint32_t)(now - *cur_t0) > ticks) return ST_WAIT_TIMEO;
    3cc8:	00200513          	li	a0,2
}
    3ccc:	00008067          	ret

00003cd0 <st_wait_progress>:
    if (cnt == *last) return 0;
    3cd0:	0005a783          	lw	a5,0(a1)
    3cd4:	00a78a63          	beq	a5,a0,3ce8 <st_wait_progress+0x18>
    *last = cnt;
    3cd8:	00a5a023          	sw	a0,0(a1)
    *cur_t0 = now;
    3cdc:	00c6a023          	sw	a2,0(a3)
    return 1;
    3ce0:	00100513          	li	a0,1
    3ce4:	00008067          	ret
    if (cnt == *last) return 0;
    3ce8:	00000513          	li	a0,0
}
    3cec:	00008067          	ret

00003cf0 <blt_idle_bounded>:
{
    3cf0:	ff010113          	addi	sp,sp,-16
    3cf4:	00112623          	sw	ra,12(sp)
    3cf8:	00812423          	sw	s0,8(sp)
    if ((g_it & BLT_WAIT_MASK) != 0u) { cpu_backoff(BLT_WAIT_NOP); return ST_WAIT_MORE; }
    3cfc:	8881a783          	lw	a5,-1912(gp) # 78b0 <g_it>
    3d00:	0037f793          	andi	a5,a5,3
    3d04:	04079463          	bnez	a5,3d4c <blt_idle_bounded+0x5c>
    3d08:	00912223          	sw	s1,4(sp)
    3d0c:	01212023          	sw	s2,0(sp)
    3d10:	00050913          	mv	s2,a0
    st  = blt_stat();
    3d14:	df1fe0ef          	jal	2b04 <blt_stat>
    3d18:	00050413          	mv	s0,a0
    cnt = blt_cnt();
    3d1c:	dcdfe0ef          	jal	2ae8 <blt_cnt>
    3d20:	00050493          	mv	s1,a0
    if (blt_idle_st(st)) { g_st_which = -1; g_st_prog = cnt; return ST_WAIT_IDLE; }
    3d24:	00040513          	mv	a0,s0
    3d28:	df9fe0ef          	jal	2b20 <blt_idle_st>
    3d2c:	04050063          	beqz	a0,3d6c <blt_idle_bounded+0x7c>
    3d30:	fff00713          	li	a4,-1
    3d34:	80e1ae23          	sw	a4,-2020(gp) # 7844 <g_st_which>
    3d38:	8091ac23          	sw	s1,-2024(gp) # 7840 <g_st_prog>
    3d3c:	00100413          	li	s0,1
    3d40:	00412483          	lw	s1,4(sp)
    3d44:	00012903          	lw	s2,0(sp)
    3d48:	0100006f          	j	3d58 <blt_idle_bounded+0x68>
    if ((g_it & BLT_WAIT_MASK) != 0u) { cpu_backoff(BLT_WAIT_NOP); return ST_WAIT_MORE; }
    3d4c:	03000513          	li	a0,48
    3d50:	aa5fe0ef          	jal	27f4 <cpu_backoff>
    3d54:	00000413          	li	s0,0
}
    3d58:	00040513          	mv	a0,s0
    3d5c:	00c12083          	lw	ra,12(sp)
    3d60:	00812403          	lw	s0,8(sp)
    3d64:	01010113          	addi	sp,sp,16
    3d68:	00008067          	ret
    (void)st_wait_progress(cnt, &g_st_prog, tick32(), &g_st_t0);
    3d6c:	a7dfe0ef          	jal	27e8 <tick32>
    3d70:	00050613          	mv	a2,a0
    3d74:	88018693          	addi	a3,gp,-1920 # 78a8 <g_st_t0>
    3d78:	81818593          	addi	a1,gp,-2024 # 7840 <g_st_prog>
    3d7c:	00048513          	mv	a0,s1
    3d80:	f51ff0ef          	jal	3cd0 <st_wait_progress>
    r = st_wait_state(which, 0, tick32(), (uint32_t)ST_WAIT_TICKS, &g_st_which, &g_st_t0);
    3d84:	a65fe0ef          	jal	27e8 <tick32>
    3d88:	00050613          	mv	a2,a0
    3d8c:	88018793          	addi	a5,gp,-1920 # 78a8 <g_st_t0>
    3d90:	81c18713          	addi	a4,gp,-2020 # 7844 <g_st_which>
    3d94:	013136b7          	lui	a3,0x1313
    3d98:	d0068693          	addi	a3,a3,-768 # 1312d00 <__freertos_irq_stack_top+0x12f5ad0>
    3d9c:	00000593          	li	a1,0
    3da0:	00090513          	mv	a0,s2
    3da4:	eedff0ef          	jal	3c90 <st_wait_state>
    3da8:	00050413          	mv	s0,a0
    if (r == ST_WAIT_MORE) cpu_backoff(BLT_WAIT_NOP);
    3dac:	00050863          	beqz	a0,3dbc <blt_idle_bounded+0xcc>
    3db0:	00412483          	lw	s1,4(sp)
    3db4:	00012903          	lw	s2,0(sp)
    3db8:	fa1ff06f          	j	3d58 <blt_idle_bounded+0x68>
    3dbc:	03000513          	li	a0,48
    3dc0:	a35fe0ef          	jal	27f4 <cpu_backoff>
    3dc4:	00412483          	lw	s1,4(sp)
    3dc8:	00012903          	lw	s2,0(sp)
    3dcc:	f8dff06f          	j	3d58 <blt_idle_bounded+0x68>

00003dd0 <blt_room_bounded>:
{
    3dd0:	ff010113          	addi	sp,sp,-16
    3dd4:	00112623          	sw	ra,12(sp)
    3dd8:	00812423          	sw	s0,8(sp)
    3ddc:	00912223          	sw	s1,4(sp)
    3de0:	01212023          	sw	s2,0(sp)
    3de4:	00050413          	mv	s0,a0
    uint32_t cnt = blt_cnt();
    3de8:	d01fe0ef          	jal	2ae8 <blt_cnt>
    3dec:	00050493          	mv	s1,a0
    *room = blt_push_room_of(cnt);
    3df0:	d41fe0ef          	jal	2b30 <blt_push_room_of>
    3df4:	00a42023          	sw	a0,0(s0)
    (void)st_wait_progress(cnt, &g_st_prog, tick32(), &g_st_t0);
    3df8:	9f1fe0ef          	jal	27e8 <tick32>
    3dfc:	00050613          	mv	a2,a0
    3e00:	88018693          	addi	a3,gp,-1920 # 78a8 <g_st_t0>
    3e04:	81818593          	addi	a1,gp,-2024 # 7840 <g_st_prog>
    3e08:	00048513          	mv	a0,s1
    3e0c:	ec5ff0ef          	jal	3cd0 <st_wait_progress>
    r = st_wait_state(STW_ROOM, (*room > 0u) ? 1 : 0, tick32(), (uint32_t)ST_WAIT_TICKS,
    3e10:	00042403          	lw	s0,0(s0)
    3e14:	9d5fe0ef          	jal	27e8 <tick32>
    3e18:	00050613          	mv	a2,a0
    3e1c:	88018793          	addi	a5,gp,-1920 # 78a8 <g_st_t0>
    3e20:	81c18713          	addi	a4,gp,-2020 # 7844 <g_st_which>
    3e24:	013136b7          	lui	a3,0x1313
    3e28:	d0068693          	addi	a3,a3,-768 # 1312d00 <__freertos_irq_stack_top+0x12f5ad0>
    3e2c:	008035b3          	snez	a1,s0
    3e30:	00400513          	li	a0,4
    3e34:	e5dff0ef          	jal	3c90 <st_wait_state>
    3e38:	00050413          	mv	s0,a0
    if (r == ST_WAIT_MORE) cpu_backoff(BLT_WAIT_NOP);
    3e3c:	02050063          	beqz	a0,3e5c <blt_room_bounded+0x8c>
}
    3e40:	00040513          	mv	a0,s0
    3e44:	00c12083          	lw	ra,12(sp)
    3e48:	00812403          	lw	s0,8(sp)
    3e4c:	00412483          	lw	s1,4(sp)
    3e50:	00012903          	lw	s2,0(sp)
    3e54:	01010113          	addi	sp,sp,16
    3e58:	00008067          	ret
    if (r == ST_WAIT_MORE) cpu_backoff(BLT_WAIT_NOP);
    3e5c:	03000513          	li	a0,48
    3e60:	995fe0ef          	jal	27f4 <cpu_backoff>
    return r;
    3e64:	fddff06f          	j	3e40 <blt_room_bounded+0x70>

00003e68 <content_total>:
static int content_total(void) { return g_n + ((g_scene == SC_CLIP) ? 2 : 0); }
    3e68:	8e41a783          	lw	a5,-1820(gp) # 790c <g_scene>
    3e6c:	00200713          	li	a4,2
    3e70:	00e78463          	beq	a5,a4,3e78 <content_total+0x10>
    3e74:	00000793          	li	a5,0
    3e78:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    3e7c:	00a78533          	add	a0,a5,a0
    3e80:	00008067          	ret

00003e84 <sweep_snap>:
    g_sw_y = PLAY_Y0 + (int)(g_anim % (uint32_t)(PLAY_Y1 - PLAY_Y0 - SWEEP_T));
    3e84:	8d81a783          	lw	a5,-1832(gp) # 7900 <g_anim>
    3e88:	17200713          	li	a4,370
    3e8c:	02e7f733          	remu	a4,a5,a4
    3e90:	06070713          	addi	a4,a4,96
    3e94:	80e1aa23          	sw	a4,-2028(gp) # 783c <g_sw_y>
    g_sw_x = PLAY_X0 + (int)((g_anim * 2u) % (uint32_t)(PLAY_X1 - PLAY_X0 - SWEEP_T));
    3e98:	00179793          	slli	a5,a5,0x1
    3e9c:	22a00713          	li	a4,554
    3ea0:	02e7f7b3          	remu	a5,a5,a4
    3ea4:	0c878793          	addi	a5,a5,200
    3ea8:	80f1a823          	sw	a5,-2032(gp) # 7838 <g_sw_x>
}
    3eac:	00008067          	ret

00003eb0 <content_rect>:
    if (k < g_n) {                                  /* 精灵 */
    3eb0:	8301a783          	lw	a5,-2000(gp) # 7858 <g_n>
    3eb4:	04f55463          	bge	a0,a5,3efc <content_rect+0x4c>
        r->dx = (int)g_pt[k].tx; r->dy = (int)g_pt[k].ty;
    3eb8:	000087b7          	lui	a5,0x8
    3ebc:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    3ec0:	00351713          	slli	a4,a0,0x3
    3ec4:	40a706b3          	sub	a3,a4,a0
    3ec8:	00169693          	slli	a3,a3,0x1
    3ecc:	00d786b3          	add	a3,a5,a3
    3ed0:	00869683          	lh	a3,8(a3)
    3ed4:	00d5a023          	sw	a3,0(a1)
    3ed8:	40a70733          	sub	a4,a4,a0
    3edc:	00171713          	slli	a4,a4,0x1
    3ee0:	00e787b3          	add	a5,a5,a4
    3ee4:	00a79783          	lh	a5,10(a5)
    3ee8:	00f5a223          	sw	a5,4(a1)
        r->w  = SPR_W;           r->h  = SPR_H;
    3eec:	85c1a783          	lw	a5,-1956(gp) # 7884 <g_blk>
    3ef0:	00f5a423          	sw	a5,8(a1)
    3ef4:	00f5a623          	sw	a5,12(a1)
    3ef8:	00008067          	ret
    } else if (k == g_n) {                          /* 横扫条：整屏宽 x SWEEP_T */
    3efc:	02a78463          	beq	a5,a0,3f24 <content_rect+0x74>
        r->dx = g_sw_x;          r->dy = TOP_Y0;
    3f00:	8101a783          	lw	a5,-2032(gp) # 7838 <g_sw_x>
    3f04:	00f5a023          	sw	a5,0(a1)
    3f08:	01000793          	li	a5,16
    3f0c:	00f5a223          	sw	a5,4(a1)
        r->w  = SWEEP_T;         r->h  = PLAY_H;
    3f10:	00600793          	li	a5,6
    3f14:	00f5a423          	sw	a5,8(a1)
    3f18:	20c00793          	li	a5,524
    3f1c:	00f5a623          	sw	a5,12(a1)
}
    3f20:	00008067          	ret
        r->dx = 0;               r->dy = TOP_Y0 + g_sw_y;
    3f24:	0005a023          	sw	zero,0(a1)
    3f28:	8141a783          	lw	a5,-2028(gp) # 783c <g_sw_y>
    3f2c:	01078793          	addi	a5,a5,16
    3f30:	00f5a223          	sw	a5,4(a1)
        r->w  = FB_WIDTH;        r->h  = SWEEP_T;
    3f34:	3c000793          	li	a5,960
    3f38:	00f5a423          	sw	a5,8(a1)
    3f3c:	00600793          	li	a5,6
    3f40:	00f5a623          	sw	a5,12(a1)
    3f44:	00008067          	ret

00003f48 <content_plan>:
{
    3f48:	fe010113          	addi	sp,sp,-32
    3f4c:	00112e23          	sw	ra,28(sp)
    3f50:	00812c23          	sw	s0,24(sp)
    3f54:	00912a23          	sw	s1,20(sp)
    3f58:	00050793          	mv	a5,a0
    3f5c:	00058413          	mv	s0,a1
    3f60:	00060493          	mv	s1,a2
    *need = 0;
    3f64:	00062023          	sw	zero,0(a2)
    if (!g_clip_pass) {                             /* 裁剪关（含 'x' 的 A/B）⇒ 逐位回到全屏 playfield */
    3f68:	9481a503          	lw	a0,-1720(gp) # 7970 <g_clip_pass>
    3f6c:	02051c63          	bnez	a0,3fa4 <content_plan+0x5c>
        if (g_clip_on) { *need = 1; w->x0 = w->x1 = w->y0 = w->y1 = 0; }
    3f70:	9441a783          	lw	a5,-1724(gp) # 796c <g_clip_on>
    3f74:	00078e63          	beqz	a5,3f90 <content_plan+0x48>
    3f78:	00100793          	li	a5,1
    3f7c:	00f62023          	sw	a5,0(a2)
    3f80:	0005a623          	sw	zero,12(a1)
    3f84:	0005a423          	sw	zero,8(a1)
    3f88:	0005a223          	sw	zero,4(a1)
    3f8c:	0005a023          	sw	zero,0(a1)
}
    3f90:	01c12083          	lw	ra,28(sp)
    3f94:	01812403          	lw	s0,24(sp)
    3f98:	01412483          	lw	s1,20(sp)
    3f9c:	02010113          	addi	sp,sp,32
    3fa0:	00008067          	ret
    content_rect(k, &r);
    3fa4:	00010593          	mv	a1,sp
    3fa8:	00078513          	mv	a0,a5
    3fac:	f05ff0ef          	jal	3eb0 <content_rect>
    if (!clip_local(r.dx, r.dy, r.w, r.h, w)) return 1;   /* 不相交 ⇒ 跳过 */
    3fb0:	00040713          	mv	a4,s0
    3fb4:	00c12683          	lw	a3,12(sp)
    3fb8:	00812603          	lw	a2,8(sp)
    3fbc:	00412583          	lw	a1,4(sp)
    3fc0:	00012503          	lw	a0,0(sp)
    3fc4:	909ff0ef          	jal	38cc <clip_local>
    3fc8:	00050e63          	beqz	a0,3fe4 <content_plan+0x9c>
    if (clip_same(w)) return 0;                           /* 窗口没变 ⇒ 不用重写寄存器 */
    3fcc:	00040513          	mv	a0,s0
    3fd0:	c59ff0ef          	jal	3c28 <clip_same>
    3fd4:	00051c63          	bnez	a0,3fec <content_plan+0xa4>
    *need = 1;
    3fd8:	00100793          	li	a5,1
    3fdc:	00f4a023          	sw	a5,0(s1)
    return 0;
    3fe0:	fb1ff06f          	j	3f90 <content_plan+0x48>
    if (!clip_local(r.dx, r.dy, r.w, r.h, w)) return 1;   /* 不相交 ⇒ 跳过 */
    3fe4:	00100513          	li	a0,1
    3fe8:	fa9ff06f          	j	3f90 <content_plan+0x48>
    if (clip_same(w)) return 0;                           /* 窗口没变 ⇒ 不用重写寄存器 */
    3fec:	00000513          	li	a0,0
    3ff0:	fa1ff06f          	j	3f90 <content_plan+0x48>

00003ff4 <fx_update>:
{
    3ff4:	ff010113          	addi	sp,sp,-16
    3ff8:	00112623          	sw	ra,12(sp)
    3ffc:	00812423          	sw	s0,8(sp)
    if (g_fx && g_feat_lut) {
    4000:	8281a603          	lw	a2,-2008(gp) # 7850 <g_fx>
    4004:	06060063          	beqz	a2,4064 <fx_update+0x70>
    4008:	9501a603          	lw	a2,-1712(gp) # 7978 <g_feat_lut>
    400c:	08060463          	beqz	a2,4094 <fx_update+0xa0>
        if (g_scene == SC_FADE)
    4010:	8e41a703          	lw	a4,-1820(gp) # 790c <g_scene>
    4014:	00100793          	li	a5,1
    4018:	02f70663          	beq	a4,a5,4044 <fx_update+0x50>
    unsigned f = 255u, g = 0u;
    401c:	0ff00413          	li	s0,255
        if (g_flash_ms > 0u)
    4020:	8cc1a583          	lw	a1,-1844(gp) # 78f4 <g_flash_ms>
    4024:	00058863          	beqz	a1,4034 <fx_update+0x40>
            g = fx_flash_of_ms(g_flash_ms);                   /* g_flash_ms 本来就是毫秒 */
    4028:	00058513          	mv	a0,a1
    402c:	cb0fe0ef          	jal	24dc <fx_flash_of_ms>
    4030:	00050593          	mv	a1,a0
        want_en = ((f != 255u) || (g != 0u)) ? 1 : 0;
    4034:	0ff00793          	li	a5,255
    4038:	02f40063          	beq	s0,a5,4058 <fx_update+0x64>
    403c:	00100613          	li	a2,1
    4040:	02c0006f          	j	406c <fx_update+0x78>
            f = fx_fade_of_ms(fx_elapsed_ms(now, g_t_fx0));   /* ★ 拍→毫秒只在这里换算一次 */
    4044:	8d01a583          	lw	a1,-1840(gp) # 78f8 <g_t_fx0>
    4048:	c0cfe0ef          	jal	2454 <fx_elapsed_ms>
    404c:	c1cfe0ef          	jal	2468 <fx_fade_of_ms>
    4050:	00050413          	mv	s0,a0
    4054:	fcdff06f          	j	4020 <fx_update+0x2c>
        want_en = ((f != 255u) || (g != 0u)) ? 1 : 0;
    4058:	04058463          	beqz	a1,40a0 <fx_update+0xac>
    405c:	00100613          	li	a2,1
    4060:	00c0006f          	j	406c <fx_update+0x78>
    unsigned f = 255u, g = 0u;
    4064:	00000593          	li	a1,0
    4068:	0ff00413          	li	s0,255
    if (f != g_lut_f || g != g_lut_g || want_en != g_lut_stage_en) {
    406c:	8381a783          	lw	a5,-1992(gp) # 7860 <g_lut_f>
    4070:	00879663          	bne	a5,s0,407c <fx_update+0x88>
    4074:	9281a783          	lw	a5,-1752(gp) # 7950 <g_lut_g>
    4078:	02b78863          	beq	a5,a1,40a8 <fx_update+0xb4>
        lut_write_table(f, g, want_en);
    407c:	00040513          	mv	a0,s0
    4080:	cb1fe0ef          	jal	2d30 <lut_write_table>
}
    4084:	00c12083          	lw	ra,12(sp)
    4088:	00812403          	lw	s0,8(sp)
    408c:	01010113          	addi	sp,sp,16
    4090:	00008067          	ret
    unsigned f = 255u, g = 0u;
    4094:	00000593          	li	a1,0
    4098:	0ff00413          	li	s0,255
    409c:	fd1ff06f          	j	406c <fx_update+0x78>
        want_en = ((f != 255u) || (g != 0u)) ? 1 : 0;
    40a0:	00000613          	li	a2,0
    40a4:	fc9ff06f          	j	406c <fx_update+0x78>
    if (f != g_lut_f || g != g_lut_g || want_en != g_lut_stage_en) {
    40a8:	9241a783          	lw	a5,-1756(gp) # 794c <g_lut_stage_en>
    40ac:	fcc798e3          	bne	a5,a2,407c <fx_update+0x88>
    40b0:	fd5ff06f          	j	4084 <fx_update+0x90>

000040b4 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    40b4:	fc010113          	addi	sp,sp,-64
    40b8:	00112e23          	sw	ra,28(sp)
    40bc:	00812c23          	sw	s0,24(sp)
    40c0:	00912a23          	sw	s1,20(sp)
    40c4:	00050493          	mv	s1,a0
    40c8:	02b12223          	sw	a1,36(sp)
    40cc:	02c12423          	sw	a2,40(sp)
    40d0:	02d12623          	sw	a3,44(sp)
    40d4:	02e12823          	sw	a4,48(sp)
    40d8:	02f12a23          	sw	a5,52(sp)
    40dc:	03012c23          	sw	a6,56(sp)
    40e0:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    40e4:	02410793          	addi	a5,sp,36
    40e8:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    40ec:	00000413          	li	s0,0
    40f0:	01c0006f          	j	410c <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    40f4:	00c12783          	lw	a5,12(sp)
    40f8:	00478713          	addi	a4,a5,4
    40fc:	00e12623          	sw	a4,12(sp)
    4100:	0007a503          	lw	a0,0(a5)
    4104:	8a8fe0ef          	jal	21ac <bsp_printf_c>
        for (i = 0; format[i]; i++)
    4108:	00140413          	addi	s0,s0,1
    410c:	008487b3          	add	a5,s1,s0
    4110:	0007c503          	lbu	a0,0(a5)
    4114:	0a050e63          	beqz	a0,41d0 <bsp_printf+0x11c>
            if (format[i] == '%') {
    4118:	02500793          	li	a5,37
    411c:	06f50e63          	beq	a0,a5,4198 <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    4120:	88cfe0ef          	jal	21ac <bsp_printf_c>
    4124:	fe5ff06f          	j	4108 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    4128:	00c12783          	lw	a5,12(sp)
    412c:	00478713          	addi	a4,a5,4
    4130:	00e12623          	sw	a4,12(sp)
    4134:	0007a503          	lw	a0,0(a5)
    4138:	890fe0ef          	jal	21c8 <bsp_printf_s>
                        break;
    413c:	fcdff06f          	j	4108 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    4140:	00c12783          	lw	a5,12(sp)
    4144:	00478713          	addi	a4,a5,4
    4148:	00e12623          	sw	a4,12(sp)
    414c:	0007a503          	lw	a0,0(a5)
    4150:	890fe0ef          	jal	21e0 <bsp_printf_d>
                        break;
    4154:	fb5ff06f          	j	4108 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    4158:	00c12783          	lw	a5,12(sp)
    415c:	00478713          	addi	a4,a5,4
    4160:	00e12623          	sw	a4,12(sp)
    4164:	0007a503          	lw	a0,0(a5)
    4168:	938fe0ef          	jal	22a0 <bsp_printf_X>
                        break;
    416c:	f9dff06f          	j	4108 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    4170:	00c12783          	lw	a5,12(sp)
    4174:	00478713          	addi	a4,a5,4
    4178:	00e12623          	sw	a4,12(sp)
    417c:	0007a503          	lw	a0,0(a5)
    4180:	8e0fe0ef          	jal	2260 <bsp_printf_x>
                        break;
    4184:	f85ff06f          	j	4108 <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    4188:	00006537          	lui	a0,0x6
    418c:	04450513          	addi	a0,a0,68 # 6044 <_data+0x90>
    4190:	838fe0ef          	jal	21c8 <bsp_printf_s>
                        break;
    4194:	f75ff06f          	j	4108 <bsp_printf+0x54>
                while (format[++i]) {
    4198:	00140413          	addi	s0,s0,1
    419c:	008487b3          	add	a5,s1,s0
    41a0:	0007c783          	lbu	a5,0(a5)
    41a4:	f60782e3          	beqz	a5,4108 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    41a8:	fa878793          	addi	a5,a5,-88
    41ac:	0ff7f693          	zext.b	a3,a5
    41b0:	02000713          	li	a4,32
    41b4:	fed762e3          	bltu	a4,a3,4198 <bsp_printf+0xe4>
    41b8:	00269793          	slli	a5,a3,0x2
    41bc:	00007737          	lui	a4,0x7
    41c0:	39c70713          	addi	a4,a4,924 # 739c <_data+0x13e8>
    41c4:	00e787b3          	add	a5,a5,a4
    41c8:	0007a783          	lw	a5,0(a5)
    41cc:	00078067          	jr	a5

        va_end(ap);
    }
    41d0:	01c12083          	lw	ra,28(sp)
    41d4:	01812403          	lw	s0,24(sp)
    41d8:	01412483          	lw	s1,20(sp)
    41dc:	04010113          	addi	sp,sp,64
    41e0:	00008067          	ret

000041e4 <banner>:
{
    41e4:	ff010113          	addi	sp,sp,-16
    41e8:	00112623          	sw	ra,12(sp)
    bsp_printf("\r\n===== AdDemo: hardware renderer only -- zero CPU pixels =====\r\n");
    41ec:	00006537          	lui	a0,0x6
    41f0:	09050513          	addi	a0,a0,144 # 6090 <_data+0xdc>
    41f4:	ec1ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("FB=%x BACK=%x BUF2=%x ATLAS=%x GLOW=%x FONT=%x BG=%x\r\n",
    41f8:	006058b7          	lui	a7,0x605
    41fc:	00221837          	lui	a6,0x221
    4200:	002117b7          	lui	a5,0x211
    4204:	00201737          	lui	a4,0x201
    4208:	007016b7          	lui	a3,0x701
    420c:	00501637          	lui	a2,0x501
    4210:	003015b7          	lui	a1,0x301
    4214:	00006537          	lui	a0,0x6
    4218:	0d450513          	addi	a0,a0,212 # 60d4 <_data+0x120>
    421c:	e99ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("layout: info 0-%d (engine-drawn) | render %d-%d (%dx%d)\r\n",
    4220:	20c00793          	li	a5,524
    4224:	3c000713          	li	a4,960
    4228:	21c00693          	li	a3,540
    422c:	01000613          	li	a2,16
    4230:	01000593          	li	a1,16
    4234:	00006537          	lui	a0,0x6
    4238:	10c50513          	addi	a0,a0,268 # 610c <_data+0x158>
    423c:	e79ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("sprite %dx%d, 'k' cycles %d/%d/%d (atlas+scene rebuilt)\r\n",
    4240:	85c1a583          	lw	a1,-1956(gp) # 7884 <g_blk>
    4244:	04000793          	li	a5,64
    4248:	02000713          	li	a4,32
    424c:	01000693          	li	a3,16
    4250:	00058613          	mv	a2,a1
    4254:	00006537          	lui	a0,0x6
    4258:	14850513          	addi	a0,a0,328 # 6148 <_data+0x194>
    425c:	e59ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("cmd: 1=GLOW 2=FADE 3=CLIP 4=LAYER 5=THRU  scene\r\n");
    4260:	00006537          	lui	a0,0x6
    4264:	18450513          	addi	a0,a0,388 # 6184 <_data+0x1d0>
    4268:	e4dff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("     n or +  N+%d   -  N-%d   =N exact N (%d..%d clamped, e.g. =1500)\r\n",
    426c:	00001737          	lui	a4,0x1
    4270:	77070713          	addi	a4,a4,1904 # 1770 <main+0x66c>
    4274:	01000693          	li	a3,16
    4278:	02000613          	li	a2,32
    427c:	02000593          	li	a1,32
    4280:	00006537          	lui	a0,0x6
    4284:	1b850513          	addi	a0,a0,440 # 61b8 <_data+0x204>
    4288:	e2dff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("     k  size 16/32/64   t  advance time/frame   a/A  master alpha -/+\r\n");
    428c:	00006537          	lui	a0,0x6
    4290:	20050513          	addi	a0,a0,512 # 6200 <_data+0x24c>
    4294:	e21ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("     f  LUT fade/flash on/off   b  flash now   x  scissor on/off (A/B)\r\n");
    4298:	00006537          	lui	a0,0x6
    429c:	24850513          	addi	a0,a0,584 # 6248 <_data+0x294>
    42a0:	e15ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("     y  attribute side-port on/off (A/B)   q  auto count ramp (scene 5)\r\n");
    42a4:	00006537          	lui	a0,0x6
    42a8:	29450513          	addi	a0,a0,660 # 6294 <_data+0x2e0>
    42ac:	e09ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("     r  reset scene (new seed)   ?  help\r\n");
    42b0:	00006537          	lui	a0,0x6
    42b4:	2e050513          	addi	a0,a0,736 # 62e0 <_data+0x32c>
    42b8:	dfdff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("     d  EV diag line now (it also prints once per second)\r\n");
    42bc:	00006537          	lui	a0,0x6
    42c0:	30c50513          	addi	a0,a0,780 # 630c <_data+0x358>
    42c4:	df1ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("attr: write ATTR_PORT BEFORE the 8 command words; 1 word per command\r\n");
    42c8:	00006537          	lui	a0,0x6
    42cc:	34850513          	addi	a0,a0,840 # 6348 <_data+0x394>
    42d0:	de5ff0ef          	jal	40b4 <bsp_printf>
               (unsigned)ATTR_DEFAULT);
    42d4:	00000693          	li	a3,0
    42d8:	0ff00613          	li	a2,255
    42dc:	00000593          	li	a1,0
    42e0:	00000513          	li	a0,0
    42e4:	834fe0ef          	jal	2318 <attr_word>
    42e8:	00050593          	mv	a1,a0
    bsp_printf("      1 command = 1 attr word + 8 cmd words (default=%X = blend0/565/ga255)\r\n",
    42ec:	00006537          	lui	a0,0x6
    42f0:	39050513          	addi	a0,a0,912 # 6390 <_data+0x3dc>
    42f4:	dc1ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("frozen: scissor [x0,x1)x[y0,y1) in DST-LOCAL coords | LUT 0xAC.bit1=WRITE bank,\r\n");
    42f8:	00006537          	lui	a0,0x6
    42fc:	3e050513          	addi	a0,a0,992 # 63e0 <_data+0x42c>
    4300:	db5ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("        display=~latched bit1, 0xB0=displayed bank: read 0xB0 -> write ~disp ->\r\n");
    4304:	00006537          	lui	a0,0x6
    4308:	43450513          	addi	a0,a0,1076 # 6434 <_data+0x480>
    430c:	da9ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("        publish 0xAC.bit1=disp (4 steps; polarity tested live, see 'EV lut' lines)\r\n");
    4310:	00006537          	lui	a0,0x6
    4314:	48850513          	addi	a0,a0,1160 # 6488 <_data+0x4d4>
    4318:	d9dff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("osd: FPS published | N sprites | MPX = N*SZ*SZ*FPS/1e6 | B = engine busy %c\r\n", '%');
    431c:	02500593          	li	a1,37
    4320:	00006537          	lui	a0,0x6
    4324:	4e050513          	addi	a0,a0,1248 # 64e0 <_data+0x52c>
    4328:	d8dff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("cost: EV cmd path done: n=.. cycles=.. cyc/sprite=.. (1 line/s)\r\n");
    432c:	00006537          	lui	a0,0x6
    4330:	53050513          	addi	a0,a0,1328 # 6530 <_data+0x57c>
    4334:	d81ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("diag: EV diag: fps=.. n=.. sz=.. scn=.. ab=.. un=.. st=.. clip=.. lut=.. lbank=.. stto=.. flp=.. flpt=..\r\n");
    4338:	00006537          	lui	a0,0x6
    433c:	57450513          	addi	a0,a0,1396 # 6574 <_data+0x5c0>
    4340:	d75ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("      (1 line/s + on demand with 'd'; scn=SCAN 0x20 raw, ab=[31:16], un=[15:0];\r\n");
    4344:	00006537          	lui	a0,0x6
    4348:	5e050513          	addi	a0,a0,1504 # 65e0 <_data+0x62c>
    434c:	d69ff0ef          	jal	40b4 <bsp_printf>
    bsp_printf("       ab/un climbing every second = scanout starved, flat = renderer problem)\r\n");
    4350:	00006537          	lui	a0,0x6
    4354:	63450513          	addi	a0,a0,1588 # 6634 <_data+0x680>
    4358:	d5dff0ef          	jal	40b4 <bsp_printf>
}
    435c:	00c12083          	lw	ra,12(sp)
    4360:	01010113          	addi	sp,sp,16
    4364:	00008067          	ret

00004368 <lut_bank_calib>:
{
    4368:	fe010113          	addi	sp,sp,-32
    436c:	00112e23          	sw	ra,28(sp)
    if (!g_feat_lut) {
    4370:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    4374:	0a078063          	beqz	a5,4414 <lut_bank_calib+0xac>
    4378:	00812c23          	sw	s0,24(sp)
    437c:	00912a23          	sw	s1,20(sp)
    4380:	01212823          	sw	s2,16(sp)
    4384:	01312623          	sw	s3,12(sp)
    d0 = blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK;
    4388:	0b000513          	li	a0,176
    438c:	c88fe0ef          	jal	2814 <blt_rd>
    4390:	00157993          	andi	s3,a0,1
    w  = lut_write_bank(d0);                              /* ② 非显示 bank */
    4394:	00098513          	mv	a0,s3
    4398:	8b0fe0ef          	jal	2448 <lut_write_bank>
    439c:	00050913          	mv	s2,a0
    lut_fill_bank(w, 255u, 0u, 0);                        /*    已知表 = 恒等表，使能 0 */
    43a0:	00000693          	li	a3,0
    43a4:	00000613          	li	a2,0
    43a8:	0ff00593          	li	a1,255
    43ac:	815fe0ef          	jal	2bc0 <lut_fill_bank>
    blt_wr(BLT_LUT_CTRL, (uint32_t)(w ^ 1u) << 1);         /* ③ 权威语义的发布值（= ~w） */
    43b0:	00191593          	slli	a1,s2,0x1
    43b4:	0025c593          	xori	a1,a1,2
    43b8:	0ac00513          	li	a0,172
    43bc:	c48fe0ef          	jal	2804 <blt_wr>
    fc0 = frame_count();
    43c0:	fd0fe0ef          	jal	2b90 <frame_count>
    43c4:	00050413          	mv	s0,a0
    t0  = tick32();
    43c8:	c20fe0ef          	jal	27e8 <tick32>
    43cc:	00050493          	mv	s1,a0
    while (frame_count() == fc0) {
    43d0:	fc0fe0ef          	jal	2b90 <frame_count>
    43d4:	04851c63          	bne	a0,s0,442c <lut_bank_calib+0xc4>
        if ((uint32_t)(tick32() - t0) > (uint32_t)LUT_CAL_TICKS) {
    43d8:	c10fe0ef          	jal	27e8 <tick32>
    43dc:	409506b3          	sub	a3,a0,s1
    43e0:	009897b7          	lui	a5,0x989
    43e4:	68078793          	addi	a5,a5,1664 # 989680 <__freertos_irq_stack_top+0x96c450>
    43e8:	fed7f4e3          	bgeu	a5,a3,43d0 <lut_bank_calib+0x68>
            g_lut_disp = d0;
    43ec:	9331aa23          	sw	s3,-1740(gp) # 795c <g_lut_disp>
            bsp_printf("EV lut WARN: polarity not confirmed (frame counter not moving); assuming display=~write\r\n");
    43f0:	00006537          	lui	a0,0x6
    43f4:	6e850513          	addi	a0,a0,1768 # 66e8 <_data+0x734>
    43f8:	cbdff0ef          	jal	40b4 <bsp_printf>
            lut_identity_safe_off();
    43fc:	881fe0ef          	jal	2c7c <lut_identity_safe_off>
            return;
    4400:	01812403          	lw	s0,24(sp)
    4404:	01412483          	lw	s1,20(sp)
    4408:	01012903          	lw	s2,16(sp)
    440c:	00c12983          	lw	s3,12(sp)
    4410:	0100006f          	j	4420 <lut_bank_calib+0xb8>
        bsp_printf("EV lut polarity: not tested (LUT registers readback failed)\r\n");
    4414:	00006537          	lui	a0,0x6
    4418:	6a850513          	addi	a0,a0,1704 # 66a8 <_data+0x6f4>
    441c:	c99ff0ef          	jal	40b4 <bsp_printf>
}
    4420:	01c12083          	lw	ra,28(sp)
    4424:	02010113          	addi	sp,sp,32
    4428:	00008067          	ret
    d1 = blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK;
    442c:	0b000513          	li	a0,176
    4430:	be4fe0ef          	jal	2814 <blt_rd>
    4434:	00157693          	andi	a3,a0,1
    g_lut_inv  = (d1 == w) ? 1 : 0;                       /* ④ 显示 bank 真的跟着走了吗 */
    4438:	40d907b3          	sub	a5,s2,a3
    443c:	0017b793          	seqz	a5,a5
    4440:	82f1ae23          	sw	a5,-1988(gp) # 7864 <g_lut_inv>
    g_lut_cal  = 1;
    4444:	00100613          	li	a2,1
    4448:	90c1ac23          	sw	a2,-1768(gp) # 7940 <g_lut_cal>
    g_lut_disp = d1;
    444c:	92d1aa23          	sw	a3,-1740(gp) # 795c <g_lut_disp>
    bsp_printf("EV lut polarity: %s (confirmed by live test) disp=%d->%d written=%d\r\n",
    4450:	02078c63          	beqz	a5,4488 <lut_bank_calib+0x120>
    4454:	000065b7          	lui	a1,0x6
    4458:	68858593          	addi	a1,a1,1672 # 6688 <_data+0x6d4>
    445c:	00090713          	mv	a4,s2
    4460:	00098613          	mv	a2,s3
    4464:	00006537          	lui	a0,0x6
    4468:	74450513          	addi	a0,a0,1860 # 6744 <_data+0x790>
    446c:	c49ff0ef          	jal	40b4 <bsp_printf>
    lut_identity_safe_off();                              /* 收尾：两个 bank 恒等 + 使能 0 */
    4470:	80dfe0ef          	jal	2c7c <lut_identity_safe_off>
    4474:	01812403          	lw	s0,24(sp)
    4478:	01412483          	lw	s1,20(sp)
    447c:	01012903          	lw	s2,16(sp)
    4480:	00c12983          	lw	s3,12(sp)
    4484:	f9dff06f          	j	4420 <lut_bank_calib+0xb8>
    bsp_printf("EV lut polarity: %s (confirmed by live test) disp=%d->%d written=%d\r\n",
    4488:	000065b7          	lui	a1,0x6
    448c:	69858593          	addi	a1,a1,1688 # 6698 <_data+0x6e4>
    4490:	fcdff06f          	j	445c <lut_bank_calib+0xf4>

00004494 <align_selfcheck>:
{
    4494:	ff010113          	addi	sp,sp,-16
    4498:	00112623          	sw	ra,12(sp)
    *(volatile uint32_t *)(FLUSH_SCRATCH + 1024u) = 0xF800F800UL;   /* 偶半字地址 32bit 存储 */
    449c:	00601737          	lui	a4,0x601
    44a0:	f80107b7          	lui	a5,0xf8010
    44a4:	80078793          	addi	a5,a5,-2048 # f800f800 <__freertos_irq_stack_top+0xf7ff25d0>
    44a8:	40f72023          	sw	a5,1024(a4) # 601400 <__freertos_irq_stack_top+0x5e41d0>
    *(volatile uint32_t *)(FLUSH_SCRATCH + 1026u) = 0x07E007E0UL;   /* ★ 奇半字地址（曾整机停死） */
    44ac:	006017b7          	lui	a5,0x601
    44b0:	4027d683          	lhu	a3,1026(a5) # 601402 <__freertos_irq_stack_top+0x5e41d2>
    44b4:	7e000693          	li	a3,2016
    44b8:	40d79123          	sh	a3,1026(a5)
    44bc:	4047d603          	lhu	a2,1028(a5)
    44c0:	40d79223          	sh	a3,1028(a5)
               (unsigned)p[0], (unsigned)p[1], (unsigned)p[2]);
    44c4:	40075583          	lhu	a1,1024(a4)
    44c8:	4027d603          	lhu	a2,1026(a5)
    44cc:	006017b7          	lui	a5,0x601
    44d0:	4047d683          	lhu	a3,1028(a5) # 601404 <__freertos_irq_stack_top+0x5e41d4>
    bsp_printf("aligncheck %x %x %x (expect f800 07e0 07e0; odd-addr 32bit store survived)\r\n",
    44d4:	00006537          	lui	a0,0x6
    44d8:	78c50513          	addi	a0,a0,1932 # 678c <_data+0x7d8>
    44dc:	bd9ff0ef          	jal	40b4 <bsp_printf>
}
    44e0:	00c12083          	lw	ra,12(sp)
    44e4:	01010113          	addi	sp,sp,16
    44e8:	00008067          	ret

000044ec <attr_selfcheck>:
{
    44ec:	fe010113          	addi	sp,sp,-32
    44f0:	00112e23          	sw	ra,28(sp)
    44f4:	00812c23          	sw	s0,24(sp)
    44f8:	00912a23          	sw	s1,20(sp)
    44fc:	01212823          	sw	s2,16(sp)
    4500:	01312623          	sw	s3,12(sp)
    4504:	01412423          	sw	s4,8(sp)
    uint32_t d = attr_word(ATTR_BLEND_OP, ATTR_FMT_565, 255u, 0u);
    4508:	00000693          	li	a3,0
    450c:	0ff00613          	li	a2,255
    4510:	00000593          	li	a1,0
    4514:	00000513          	li	a0,0
    4518:	e01fd0ef          	jal	2318 <attr_word>
    451c:	00050593          	mv	a1,a0
    bsp_printf("attr default=%x (FIFO empty = blend0/565/ga255) match=%d\r\n",
    4520:	00100613          	li	a2,1
    4524:	00006537          	lui	a0,0x6
    4528:	7dc50513          	addi	a0,a0,2012 # 67dc <_data+0x828>
    452c:	b89ff0ef          	jal	40b4 <bsp_printf>
    for (i = 0; i < 4; i++) {
    4530:	00000493          	li	s1,0
    4534:	07c0006f          	j	45b0 <attr_selfcheck+0xc4>
        uint32_t w = attr_word(t[i].blend, t[i].fmt, t[i].ga, t[i].fl);
    4538:	000077b7          	lui	a5,0x7
    453c:	00449713          	slli	a4,s1,0x4
    4540:	57078793          	addi	a5,a5,1392 # 7570 <t.0>
    4544:	00e787b3          	add	a5,a5,a4
    4548:	00c7a683          	lw	a3,12(a5)
    454c:	0087a603          	lw	a2,8(a5)
    4550:	0047a583          	lw	a1,4(a5)
    4554:	0007a503          	lw	a0,0(a5)
    4558:	dc1fd0ef          	jal	2318 <attr_word>
    455c:	00050413          	mv	s0,a0
                   (int)attr_blend(w), (int)attr_fmt(w), (int)attr_ga(w), (int)attr_flags(w));
    4560:	df1fd0ef          	jal	2350 <attr_blend>
    4564:	00050913          	mv	s2,a0
    4568:	00040513          	mv	a0,s0
    456c:	dedfd0ef          	jal	2358 <attr_fmt>
    4570:	00050993          	mv	s3,a0
    4574:	00040513          	mv	a0,s0
    4578:	dedfd0ef          	jal	2364 <attr_ga>
    457c:	00050a13          	mv	s4,a0
    4580:	00040513          	mv	a0,s0
    4584:	dedfd0ef          	jal	2370 <attr_flags>
        bsp_printf("attr[%d] w=%x blend=%d fmt=%d ga=%d flags=%d\r\n", i, (unsigned)w,
    4588:	00050813          	mv	a6,a0
    458c:	000a0793          	mv	a5,s4
    4590:	00098713          	mv	a4,s3
    4594:	00090693          	mv	a3,s2
    4598:	00040613          	mv	a2,s0
    459c:	00048593          	mv	a1,s1
    45a0:	00007537          	lui	a0,0x7
    45a4:	81850513          	addi	a0,a0,-2024 # 6818 <_data+0x864>
    45a8:	b0dff0ef          	jal	40b4 <bsp_printf>
    for (i = 0; i < 4; i++) {
    45ac:	00148493          	addi	s1,s1,1
    45b0:	00300793          	li	a5,3
    45b4:	f897d2e3          	bge	a5,s1,4538 <attr_selfcheck+0x4c>
    bsp_printf("attr pairing: every command goes through blt_emit() -> 1 attr per command\r\n");
    45b8:	00007537          	lui	a0,0x7
    45bc:	84850513          	addi	a0,a0,-1976 # 6848 <_data+0x894>
    45c0:	af5ff0ef          	jal	40b4 <bsp_printf>
}
    45c4:	01c12083          	lw	ra,28(sp)
    45c8:	01812403          	lw	s0,24(sp)
    45cc:	01412483          	lw	s1,20(sp)
    45d0:	01012903          	lw	s2,16(sp)
    45d4:	00c12983          	lw	s3,12(sp)
    45d8:	00812a03          	lw	s4,8(sp)
    45dc:	02010113          	addi	sp,sp,32
    45e0:	00008067          	ret

000045e4 <argb_selfcheck>:
{
    45e4:	fc010113          	addi	sp,sp,-64
    45e8:	02112e23          	sw	ra,60(sp)
    45ec:	02812c23          	sw	s0,56(sp)
    45f0:	02912a23          	sw	s1,52(sp)
    45f4:	03212823          	sw	s2,48(sp)
    45f8:	03312623          	sw	s3,44(sp)
    45fc:	03412423          	sw	s4,40(sp)
    4600:	03512223          	sw	s5,36(sp)
    4604:	03612023          	sw	s6,32(sp)
    4608:	01712e23          	sw	s7,28(sp)
    uint16_t c = glow_color(SPR_W / 2, SPR_H / 2, 0);        /* v=0 档圆心：白芯 */
    460c:	85c1a783          	lw	a5,-1956(gp) # 7884 <g_blk>
    4610:	01f7d513          	srli	a0,a5,0x1f
    4614:	00f50533          	add	a0,a0,a5
    4618:	40155513          	srai	a0,a0,0x1
    461c:	00000613          	li	a2,0
    4620:	00050593          	mv	a1,a0
    4624:	818fe0ef          	jal	263c <glow_color>
    4628:	00050413          	mv	s0,a0
               (unsigned)c, (int)argb4444_a(c), (int)argb4444_r(c),
    462c:	d89fd0ef          	jal	23b4 <argb4444_a>
    4630:	00050493          	mv	s1,a0
    4634:	00040513          	mv	a0,s0
    4638:	d85fd0ef          	jal	23bc <argb4444_r>
    463c:	00050913          	mv	s2,a0
               (int)argb4444_g(c), (int)argb4444_b(c),
    4640:	00040513          	mv	a0,s0
    4644:	d85fd0ef          	jal	23c8 <argb4444_g>
    4648:	00050993          	mv	s3,a0
    464c:	00040513          	mv	a0,s0
    4650:	d85fd0ef          	jal	23d4 <argb4444_b>
    4654:	00050a13          	mv	s4,a0
               (int)rep4to8(argb4444_a(c)), (int)rep4to8(argb4444_r(c)),
    4658:	00048513          	mv	a0,s1
    465c:	d81fd0ef          	jal	23dc <rep4to8>
    4660:	00050a93          	mv	s5,a0
    4664:	00090513          	mv	a0,s2
    4668:	d75fd0ef          	jal	23dc <rep4to8>
    466c:	00050b13          	mv	s6,a0
               (int)rep4to8(argb4444_g(c)), (int)rep4to8(argb4444_b(c)));
    4670:	00098513          	mv	a0,s3
    4674:	d69fd0ef          	jal	23dc <rep4to8>
    4678:	00050b93          	mv	s7,a0
    467c:	000a0513          	mv	a0,s4
    4680:	d5dfd0ef          	jal	23dc <rep4to8>
    bsp_printf("argb4444 c=%x a=%d r=%d g=%d b=%d -> a8=%d r8=%d g8=%d b8=%d\r\n",
    4684:	00a12223          	sw	a0,4(sp)
    4688:	01712023          	sw	s7,0(sp)
    468c:	000b0893          	mv	a7,s6
    4690:	000a8813          	mv	a6,s5
    4694:	000a0793          	mv	a5,s4
    4698:	00098713          	mv	a4,s3
    469c:	00090693          	mv	a3,s2
    46a0:	00048613          	mv	a2,s1
    46a4:	00040593          	mv	a1,s0
    46a8:	00007537          	lui	a0,0x7
    46ac:	89450513          	addi	a0,a0,-1900 # 6894 <_data+0x8e0>
    46b0:	a05ff0ef          	jal	40b4 <bsp_printf>
               (unsigned)argb4444_pack(1u, 2u, 3u, 4u), (unsigned)argb4444_pack(0u, 15u, 0u, 0u),
    46b4:	00400693          	li	a3,4
    46b8:	00300613          	li	a2,3
    46bc:	00200593          	li	a1,2
    46c0:	00100513          	li	a0,1
    46c4:	cb9fd0ef          	jal	237c <argb4444_pack>
    46c8:	00050413          	mv	s0,a0
    46cc:	00000693          	li	a3,0
    46d0:	00000613          	li	a2,0
    46d4:	00f00593          	li	a1,15
    46d8:	00000513          	li	a0,0
    46dc:	ca1fd0ef          	jal	237c <argb4444_pack>
    46e0:	00050493          	mv	s1,a0
               (unsigned)argb4444_pack(0u, 0u, 15u, 0u), (unsigned)argb4444_pack(0u, 0u, 0u, 15u),
    46e4:	00000693          	li	a3,0
    46e8:	00f00613          	li	a2,15
    46ec:	00000593          	li	a1,0
    46f0:	00000513          	li	a0,0
    46f4:	c89fd0ef          	jal	237c <argb4444_pack>
    46f8:	00050913          	mv	s2,a0
    46fc:	00f00693          	li	a3,15
    4700:	00000613          	li	a2,0
    4704:	00000593          	li	a1,0
    4708:	00000513          	li	a0,0
    470c:	c71fd0ef          	jal	237c <argb4444_pack>
    4710:	00050993          	mv	s3,a0
               (int)rep4to8(8u));
    4714:	00800513          	li	a0,8
    4718:	cc5fd0ef          	jal	23dc <rep4to8>
    471c:	00050793          	mv	a5,a0
    bsp_printf("argb4444 field probe 1234=%x 0f00=%x 00f0=%x 000f=%x (expect A/R/G/B, a8 of 8=%d)\r\n",
    4720:	00098713          	mv	a4,s3
    4724:	00090693          	mv	a3,s2
    4728:	00048613          	mv	a2,s1
    472c:	00040593          	mv	a1,s0
    4730:	00007537          	lui	a0,0x7
    4734:	8d450513          	addi	a0,a0,-1836 # 68d4 <_data+0x920>
    4738:	97dff0ef          	jal	40b4 <bsp_printf>
}
    473c:	03c12083          	lw	ra,60(sp)
    4740:	03812403          	lw	s0,56(sp)
    4744:	03412483          	lw	s1,52(sp)
    4748:	03012903          	lw	s2,48(sp)
    474c:	02c12983          	lw	s3,44(sp)
    4750:	02812a03          	lw	s4,40(sp)
    4754:	02412a83          	lw	s5,36(sp)
    4758:	02012b03          	lw	s6,32(sp)
    475c:	01c12b83          	lw	s7,28(sp)
    4760:	04010113          	addi	sp,sp,64
    4764:	00008067          	ret

00004768 <build_bg>:
{
    4768:	fe010113          	addi	sp,sp,-32
    476c:	00112e23          	sw	ra,28(sp)
    4770:	00812c23          	sw	s0,24(sp)
    4774:	00912a23          	sw	s1,20(sp)
    4778:	01212823          	sw	s2,16(sp)
    477c:	01312623          	sw	s3,12(sp)
    4780:	01412423          	sw	s4,8(sp)
    for (y = 0; y < PLAY_H; y++) {
    4784:	00000993          	li	s3,0
    4788:	0780006f          	j	4800 <build_bg+0x98>
            unsigned g0 = (unsigned)(x * 255 / (FB_WIDTH - 1));
    478c:	00841793          	slli	a5,s0,0x8
    4790:	408787b3          	sub	a5,a5,s0
    4794:	3bf00513          	li	a0,959
            unsigned g1 = (unsigned)((x + 1) * 255 / (FB_WIDTH - 1));
    4798:	00140713          	addi	a4,s0,1
    479c:	00871913          	slli	s2,a4,0x8
    47a0:	40e90933          	sub	s2,s2,a4
    47a4:	02a94933          	div	s2,s2,a0
                (uint32_t)bg_px(g0, gy) | ((uint32_t)bg_px(g1, gy) << 16);
    47a8:	000a0593          	mv	a1,s4
    47ac:	02a7c533          	div	a0,a5,a0
    47b0:	e78fe0ef          	jal	2e28 <bg_px>
    47b4:	00050493          	mv	s1,a0
    47b8:	000a0593          	mv	a1,s4
    47bc:	00090513          	mv	a0,s2
    47c0:	e68fe0ef          	jal	2e28 <bg_px>
    47c4:	01051513          	slli	a0,a0,0x10
            p[(y * FB_WIDTH + x) >> 1] =
    47c8:	00499793          	slli	a5,s3,0x4
    47cc:	413787b3          	sub	a5,a5,s3
    47d0:	00679793          	slli	a5,a5,0x6
    47d4:	008787b3          	add	a5,a5,s0
    47d8:	4017d793          	srai	a5,a5,0x1
    47dc:	00279793          	slli	a5,a5,0x2
    47e0:	00605737          	lui	a4,0x605
    47e4:	00f707b3          	add	a5,a4,a5
                (uint32_t)bg_px(g0, gy) | ((uint32_t)bg_px(g1, gy) << 16);
    47e8:	00a4e4b3          	or	s1,s1,a0
            p[(y * FB_WIDTH + x) >> 1] =
    47ec:	0097a023          	sw	s1,0(a5)
        for (x = 0; x < FB_WIDTH; x += 2) {
    47f0:	00240413          	addi	s0,s0,2
    47f4:	3bf00793          	li	a5,959
    47f8:	f887dae3          	bge	a5,s0,478c <build_bg+0x24>
    for (y = 0; y < PLAY_H; y++) {
    47fc:	00198993          	addi	s3,s3,1
    4800:	20b00793          	li	a5,523
    4804:	0137ce63          	blt	a5,s3,4820 <build_bg+0xb8>
        unsigned gy = (unsigned)(y * 255 / (PLAY_H - 1));
    4808:	00899a13          	slli	s4,s3,0x8
    480c:	413a0a33          	sub	s4,s4,s3
    4810:	20b00793          	li	a5,523
    4814:	02fa4a33          	div	s4,s4,a5
        for (x = 0; x < FB_WIDTH; x += 2) {
    4818:	00000413          	li	s0,0
    481c:	fd9ff06f          	j	47f4 <build_bg+0x8c>
    bsp_printf("bake: bg %dx%d @%x (one COPY per pass in scene 4)\r\n",
    4820:	006056b7          	lui	a3,0x605
    4824:	20c00613          	li	a2,524
    4828:	3c000593          	li	a1,960
    482c:	00007537          	lui	a0,0x7
    4830:	92850513          	addi	a0,a0,-1752 # 6928 <_data+0x974>
    4834:	881ff0ef          	jal	40b4 <bsp_printf>
}
    4838:	01c12083          	lw	ra,28(sp)
    483c:	01812403          	lw	s0,24(sp)
    4840:	01412483          	lw	s1,20(sp)
    4844:	01012903          	lw	s2,16(sp)
    4848:	00c12983          	lw	s3,12(sp)
    484c:	00812a03          	lw	s4,8(sp)
    4850:	02010113          	addi	sp,sp,32
    4854:	00008067          	ret

00004858 <clip_emit_guard>:
{
    4858:	ff010113          	addi	sp,sp,-16
    485c:	00112623          	sw	ra,12(sp)
    if (clip_cls_can_clip(g_emit_cls) || !g_clip_on) return 1;
    4860:	8441a503          	lw	a0,-1980(gp) # 786c <g_emit_cls>
    4864:	a7cfe0ef          	jal	2ae0 <clip_cls_can_clip>
    4868:	04051a63          	bnez	a0,48bc <clip_emit_guard+0x64>
    486c:	9441a783          	lw	a5,-1724(gp) # 796c <g_clip_on>
    4870:	04078e63          	beqz	a5,48cc <clip_emit_guard+0x74>
    4874:	00812423          	sw	s0,8(sp)
    g_clip_viol++;
    4878:	9401a783          	lw	a5,-1728(gp) # 7968 <g_clip_viol>
    487c:	00178793          	addi	a5,a5,1
    4880:	94f1a023          	sw	a5,-1728(gp) # 7968 <g_clip_viol>
    g_scis_on   = 0;                        /* 'x' 的 A/B 开关一起关掉：屏幕上立刻看得见 */
    4884:	8401a623          	sw	zero,-1972(gp) # 7874 <g_scis_on>
    g_clip_pass = 0;
    4888:	9401a423          	sw	zero,-1720(gp) # 7970 <g_clip_pass>
    if (!g_clip_warn) {
    488c:	93c1a403          	lw	s0,-1732(gp) # 7964 <g_clip_warn>
    4890:	00040663          	beqz	s0,489c <clip_emit_guard+0x44>
    4894:	00812403          	lw	s0,8(sp)
    4898:	0280006f          	j	48c0 <clip_emit_guard+0x68>
        g_clip_warn = 1;
    489c:	00100713          	li	a4,1
    48a0:	92e1ae23          	sw	a4,-1732(gp) # 7964 <g_clip_warn>
        bsp_printf("EV clip WARN: DECOR draw while scissor armed -> scissor disabled\r\n");
    48a4:	00007537          	lui	a0,0x7
    48a8:	95c50513          	addi	a0,a0,-1700 # 695c <_data+0x9a8>
    48ac:	809ff0ef          	jal	40b4 <bsp_printf>
    return 0;
    48b0:	00040513          	mv	a0,s0
    48b4:	00812403          	lw	s0,8(sp)
    48b8:	0080006f          	j	48c0 <clip_emit_guard+0x68>
    if (clip_cls_can_clip(g_emit_cls) || !g_clip_on) return 1;
    48bc:	00100513          	li	a0,1
}
    48c0:	00c12083          	lw	ra,12(sp)
    48c4:	01010113          	addi	sp,sp,16
    48c8:	00008067          	ret
    if (clip_cls_can_clip(g_emit_cls) || !g_clip_on) return 1;
    48cc:	00100513          	li	a0,1
    48d0:	ff1ff06f          	j	48c0 <clip_emit_guard+0x68>

000048d4 <blt_emit>:
{
    48d4:	fd010113          	addi	sp,sp,-48
    48d8:	02112623          	sw	ra,44(sp)
    48dc:	02812423          	sw	s0,40(sp)
    48e0:	02912223          	sw	s1,36(sp)
    48e4:	03212023          	sw	s2,32(sp)
    48e8:	01312e23          	sw	s3,28(sp)
    48ec:	01412c23          	sw	s4,24(sp)
    48f0:	01512a23          	sw	s5,20(sp)
    48f4:	01612823          	sw	s6,16(sp)
    48f8:	01712623          	sw	s7,12(sp)
    48fc:	00050b93          	mv	s7,a0
    4900:	00058b13          	mv	s6,a1
    4904:	00060a93          	mv	s5,a2
    4908:	00068a13          	mv	s4,a3
    490c:	00070993          	mv	s3,a4
    4910:	00078913          	mv	s2,a5
    4914:	00080413          	mv	s0,a6
    4918:	00088493          	mv	s1,a7
    (void)clip_emit_guard();                      /* ★ 屏幕骨架绝不在裁剪开着时下发 */
    491c:	f3dff0ef          	jal	4858 <clip_emit_guard>
    if (g_attr_on) blt_wr(BLT_ATTR_PORT, attr);   /* ★ 属性字必须在命令的 8 个字**之前** */
    4920:	9381a783          	lw	a5,-1736(gp) # 7960 <g_attr_on>
    4924:	08079e63          	bnez	a5,49c0 <blt_emit+0xec>
    blt_wr(BLT_CMD_FIFO_DATA, op);
    4928:	000b0593          	mv	a1,s6
    492c:	00800513          	li	a0,8
    4930:	ed5fd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, src);
    4934:	000a8593          	mv	a1,s5
    4938:	00800513          	li	a0,8
    493c:	ec9fd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    4940:	000a0593          	mv	a1,s4
    4944:	00800513          	li	a0,8
    4948:	ebdfd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    494c:	00098593          	mv	a1,s3
    4950:	00800513          	li	a0,8
    4954:	eb1fd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    4958:	00090593          	mv	a1,s2
    495c:	00800513          	li	a0,8
    4960:	ea5fd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    4964:	01049593          	slli	a1,s1,0x10
    4968:	01041413          	slli	s0,s0,0x10
    496c:	01045413          	srli	s0,s0,0x10
    4970:	0085e5b3          	or	a1,a1,s0
    4974:	00800513          	li	a0,8
    4978:	e8dfd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    497c:	03012583          	lw	a1,48(sp)
    4980:	00800513          	li	a0,8
    4984:	e81fd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, color);
    4988:	03412583          	lw	a1,52(sp)
    498c:	00800513          	li	a0,8
    4990:	e75fd0ef          	jal	2804 <blt_wr>
}
    4994:	02c12083          	lw	ra,44(sp)
    4998:	02812403          	lw	s0,40(sp)
    499c:	02412483          	lw	s1,36(sp)
    49a0:	02012903          	lw	s2,32(sp)
    49a4:	01c12983          	lw	s3,28(sp)
    49a8:	01812a03          	lw	s4,24(sp)
    49ac:	01412a83          	lw	s5,20(sp)
    49b0:	01012b03          	lw	s6,16(sp)
    49b4:	00c12b83          	lw	s7,12(sp)
    49b8:	03010113          	addi	sp,sp,48
    49bc:	00008067          	ret
    if (g_attr_on) blt_wr(BLT_ATTR_PORT, attr);   /* ★ 属性字必须在命令的 8 个字**之前** */
    49c0:	000b8593          	mv	a1,s7
    49c4:	08c00513          	li	a0,140
    49c8:	e3dfd0ef          	jal	2804 <blt_wr>
    49cc:	f5dff06f          	j	4928 <blt_emit+0x54>

000049d0 <e_fill>:
{ blt_emit(attr, BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color); }
    49d0:	fe010113          	addi	sp,sp,-32
    49d4:	00112e23          	sw	ra,28(sp)
    49d8:	00f12223          	sw	a5,4(sp)
    49dc:	0ff00793          	li	a5,255
    49e0:	00f12023          	sw	a5,0(sp)
    49e4:	00070893          	mv	a7,a4
    49e8:	00068813          	mv	a6,a3
    49ec:	00060793          	mv	a5,a2
    49f0:	00000713          	li	a4,0
    49f4:	00058693          	mv	a3,a1
    49f8:	00000613          	li	a2,0
    49fc:	00100593          	li	a1,1
    4a00:	ed5ff0ef          	jal	48d4 <blt_emit>
    4a04:	01c12083          	lw	ra,28(sp)
    4a08:	02010113          	addi	sp,sp,32
    4a0c:	00008067          	ret

00004a10 <blt_fill>:
{ e_fill(ATTR_DEFAULT, dst, ds, w, h, color); }
    4a10:	fe010113          	addi	sp,sp,-32
    4a14:	00112e23          	sw	ra,28(sp)
    4a18:	00812c23          	sw	s0,24(sp)
    4a1c:	00912a23          	sw	s1,20(sp)
    4a20:	01212823          	sw	s2,16(sp)
    4a24:	01312623          	sw	s3,12(sp)
    4a28:	01412423          	sw	s4,8(sp)
    4a2c:	00050413          	mv	s0,a0
    4a30:	00058493          	mv	s1,a1
    4a34:	00060913          	mv	s2,a2
    4a38:	00068993          	mv	s3,a3
    4a3c:	00070a13          	mv	s4,a4
    4a40:	00000693          	li	a3,0
    4a44:	0ff00613          	li	a2,255
    4a48:	00000593          	li	a1,0
    4a4c:	00000513          	li	a0,0
    4a50:	8c9fd0ef          	jal	2318 <attr_word>
    4a54:	000a0793          	mv	a5,s4
    4a58:	00098713          	mv	a4,s3
    4a5c:	00090693          	mv	a3,s2
    4a60:	00048613          	mv	a2,s1
    4a64:	00040593          	mv	a1,s0
    4a68:	f69ff0ef          	jal	49d0 <e_fill>
    4a6c:	01c12083          	lw	ra,28(sp)
    4a70:	01812403          	lw	s0,24(sp)
    4a74:	01412483          	lw	s1,20(sp)
    4a78:	01012903          	lw	s2,16(sp)
    4a7c:	00c12983          	lw	s3,12(sp)
    4a80:	00812a03          	lw	s4,8(sp)
    4a84:	02010113          	addi	sp,sp,32
    4a88:	00008067          	ret

00004a8c <decor_clip_edge_emit>:
{
    4a8c:	fe010113          	addi	sp,sp,-32
    4a90:	00112e23          	sw	ra,28(sp)
    clip_edge_rect(k, &r);
    4a94:	00010593          	mv	a1,sp
    4a98:	f05fe0ef          	jal	399c <clip_edge_rect>
    blt_fill(g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u,
    4a9c:	00412703          	lw	a4,4(sp)
    4aa0:	00471793          	slli	a5,a4,0x4
    4aa4:	40e787b3          	sub	a5,a5,a4
    4aa8:	00679513          	slli	a0,a5,0x6
    4aac:	00012783          	lw	a5,0(sp)
    4ab0:	00f50533          	add	a0,a0,a5
    4ab4:	00151513          	slli	a0,a0,0x1
    4ab8:	8581a783          	lw	a5,-1960(gp) # 7880 <g_fb_back>
    4abc:	00005737          	lui	a4,0x5
    4ac0:	a6970713          	addi	a4,a4,-1431 # 4a69 <blt_fill+0x59>
    4ac4:	00c12683          	lw	a3,12(sp)
    4ac8:	00812603          	lw	a2,8(sp)
    4acc:	78000593          	li	a1,1920
    4ad0:	00f50533          	add	a0,a0,a5
    4ad4:	f3dff0ef          	jal	4a10 <blt_fill>
}
    4ad8:	01c12083          	lw	ra,28(sp)
    4adc:	02010113          	addi	sp,sp,32
    4ae0:	00008067          	ret

00004ae4 <decor_hud_emit>:
{
    4ae4:	fe010113          	addi	sp,sp,-32
    4ae8:	00112e23          	sw	ra,28(sp)
    4aec:	00812c23          	sw	s0,24(sp)
    4af0:	00912a23          	sw	s1,20(sp)
    4af4:	00050493          	mv	s1,a0
    hud_rect(k, &r);
    4af8:	00010593          	mv	a1,sp
    4afc:	f45fe0ef          	jal	3a40 <hud_rect>
    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    4b00:	00412783          	lw	a5,4(sp)
    4b04:	00479413          	slli	s0,a5,0x4
    4b08:	40f40433          	sub	s0,s0,a5
    4b0c:	00641413          	slli	s0,s0,0x6
    4b10:	00012783          	lw	a5,0(sp)
    4b14:	00f40433          	add	s0,s0,a5
    4b18:	00141413          	slli	s0,s0,0x1
    4b1c:	8581a783          	lw	a5,-1960(gp) # 7880 <g_fb_back>
    4b20:	00f40433          	add	s0,s0,a5
    if (k == 0) { blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL); return; }
    4b24:	0a048663          	beqz	s1,4bd0 <decor_hud_emit+0xec>
    if (k <= 4) { blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL2); return; }
    4b28:	00400793          	li	a5,4
    4b2c:	0c97d263          	bge	a5,s1,4bf0 <decor_hud_emit+0x10c>
    4b30:	01212823          	sw	s2,16(sp)
        int      i     = k - 5;
    4b34:	ffb48493          	addi	s1,s1,-5
        uint32_t phase = (uint32_t)((g_anim / 3u + (uint32_t)i * 37u) % 200u);
    4b38:	8d81a783          	lw	a5,-1832(gp) # 7900 <g_anim>
    4b3c:	00300713          	li	a4,3
    4b40:	02e7d7b3          	divu	a5,a5,a4
    4b44:	00349713          	slli	a4,s1,0x3
    4b48:	00970733          	add	a4,a4,s1
    4b4c:	00271713          	slli	a4,a4,0x2
    4b50:	00970733          	add	a4,a4,s1
    4b54:	00e787b3          	add	a5,a5,a4
    4b58:	0c800713          	li	a4,200
    4b5c:	02e7f7b3          	remu	a5,a5,a4
        uint32_t w     = (phase < 100u) ? (phase * 2u) : ((200u - phase) * 2u);
    4b60:	06300713          	li	a4,99
    4b64:	0af76663          	bltu	a4,a5,4c10 <decor_hud_emit+0x12c>
    4b68:	00179913          	slli	s2,a5,0x1
        blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL2);
    4b6c:	00002737          	lui	a4,0x2
    4b70:	10470713          	addi	a4,a4,260 # 2104 <bsp_printHex>
    4b74:	00c12683          	lw	a3,12(sp)
    4b78:	00812603          	lw	a2,8(sp)
    4b7c:	78000593          	li	a1,1920
    4b80:	00040513          	mv	a0,s0
    4b84:	e8dff0ef          	jal	4a10 <blt_fill>
        blt_fill(dst, FB_STRIDE, (w * (uint32_t)r.w) / 200u, (uint32_t)r.h,
    4b88:	00812603          	lw	a2,8(sp)
    4b8c:	03260633          	mul	a2,a2,s2
    4b90:	0c800793          	li	a5,200
    4b94:	02f65633          	divu	a2,a2,a5
    4b98:	00c12683          	lw	a3,12(sp)
                 (i & 1) ? COL_AMBER : COL_CYAN);
    4b9c:	0014f493          	andi	s1,s1,1
        blt_fill(dst, FB_STRIDE, (w * (uint32_t)r.w) / 200u, (uint32_t)r.h,
    4ba0:	08048063          	beqz	s1,4c20 <decor_hud_emit+0x13c>
    4ba4:	00010737          	lui	a4,0x10
    4ba8:	d2070713          	addi	a4,a4,-736 # fd20 <__global_pointer$+0x7cf8>
    4bac:	78000593          	li	a1,1920
    4bb0:	00040513          	mv	a0,s0
    4bb4:	e5dff0ef          	jal	4a10 <blt_fill>
    4bb8:	01012903          	lw	s2,16(sp)
}
    4bbc:	01c12083          	lw	ra,28(sp)
    4bc0:	01812403          	lw	s0,24(sp)
    4bc4:	01412483          	lw	s1,20(sp)
    4bc8:	02010113          	addi	sp,sp,32
    4bcc:	00008067          	ret
    if (k == 0) { blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL); return; }
    4bd0:	00001737          	lui	a4,0x1
    4bd4:	08270713          	addi	a4,a4,130 # 1082 <__libc_init_array+0x12>
    4bd8:	00c12683          	lw	a3,12(sp)
    4bdc:	00812603          	lw	a2,8(sp)
    4be0:	78000593          	li	a1,1920
    4be4:	00040513          	mv	a0,s0
    4be8:	e29ff0ef          	jal	4a10 <blt_fill>
    4bec:	fd1ff06f          	j	4bbc <decor_hud_emit+0xd8>
    if (k <= 4) { blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, COL_PANEL2); return; }
    4bf0:	00002737          	lui	a4,0x2
    4bf4:	10470713          	addi	a4,a4,260 # 2104 <bsp_printHex>
    4bf8:	00c12683          	lw	a3,12(sp)
    4bfc:	00812603          	lw	a2,8(sp)
    4c00:	78000593          	li	a1,1920
    4c04:	00040513          	mv	a0,s0
    4c08:	e09ff0ef          	jal	4a10 <blt_fill>
    4c0c:	fb1ff06f          	j	4bbc <decor_hud_emit+0xd8>
        uint32_t w     = (phase < 100u) ? (phase * 2u) : ((200u - phase) * 2u);
    4c10:	0c800913          	li	s2,200
    4c14:	40f90933          	sub	s2,s2,a5
    4c18:	00191913          	slli	s2,s2,0x1
    4c1c:	f51ff06f          	j	4b6c <decor_hud_emit+0x88>
        blt_fill(dst, FB_STRIDE, (w * (uint32_t)r.w) / 200u, (uint32_t)r.h,
    4c20:	7ff00713          	li	a4,2047
    4c24:	f89ff06f          	j	4bac <decor_hud_emit+0xc8>

00004c28 <sweep_emit>:
{
    4c28:	fe010113          	addi	sp,sp,-32
    4c2c:	00112e23          	sw	ra,28(sp)
    4c30:	00812c23          	sw	s0,24(sp)
    4c34:	00050413          	mv	s0,a0
    content_rect(g_n + k, &r);                      /* k = 0 横扫 / 1 竖扫 */
    4c38:	8301a503          	lw	a0,-2000(gp) # 7858 <g_n>
    4c3c:	00010593          	mv	a1,sp
    4c40:	00a40533          	add	a0,s0,a0
    4c44:	a6cff0ef          	jal	3eb0 <content_rect>
    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    4c48:	00412703          	lw	a4,4(sp)
    4c4c:	00471793          	slli	a5,a4,0x4
    4c50:	40e787b3          	sub	a5,a5,a4
    4c54:	00679793          	slli	a5,a5,0x6
    4c58:	00012703          	lw	a4,0(sp)
    4c5c:	00e787b3          	add	a5,a5,a4
    4c60:	00179793          	slli	a5,a5,0x1
    4c64:	8581a703          	lw	a4,-1960(gp) # 7880 <g_fb_back>
    4c68:	00e78533          	add	a0,a5,a4
    blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, (k == 0) ? COL_CYAN : COL_AMBER);
    4c6c:	00812603          	lw	a2,8(sp)
    4c70:	00c12683          	lw	a3,12(sp)
    4c74:	02041063          	bnez	s0,4c94 <sweep_emit+0x6c>
    4c78:	7ff00713          	li	a4,2047
    4c7c:	78000593          	li	a1,1920
    4c80:	d91ff0ef          	jal	4a10 <blt_fill>
}
    4c84:	01c12083          	lw	ra,28(sp)
    4c88:	01812403          	lw	s0,24(sp)
    4c8c:	02010113          	addi	sp,sp,32
    4c90:	00008067          	ret
    blt_fill(dst, FB_STRIDE, (uint32_t)r.w, (uint32_t)r.h, (k == 0) ? COL_CYAN : COL_AMBER);
    4c94:	00010737          	lui	a4,0x10
    4c98:	d2070713          	addi	a4,a4,-736 # fd20 <__global_pointer$+0x7cf8>
    4c9c:	fe1ff06f          	j	4c7c <sweep_emit+0x54>

00004ca0 <e_copy>:
{ blt_emit(attr, BLT_OP_COPY, src, dst, ss, ds, w, h, 0xFFu, 0u); }
    4ca0:	fe010113          	addi	sp,sp,-32
    4ca4:	00112e23          	sw	ra,28(sp)
    4ca8:	00012223          	sw	zero,4(sp)
    4cac:	0ff00893          	li	a7,255
    4cb0:	01112023          	sw	a7,0(sp)
    4cb4:	00080893          	mv	a7,a6
    4cb8:	00078813          	mv	a6,a5
    4cbc:	00070793          	mv	a5,a4
    4cc0:	00068713          	mv	a4,a3
    4cc4:	00060693          	mv	a3,a2
    4cc8:	00058613          	mv	a2,a1
    4ccc:	00000593          	li	a1,0
    4cd0:	c05ff0ef          	jal	48d4 <blt_emit>
    4cd4:	01c12083          	lw	ra,28(sp)
    4cd8:	02010113          	addi	sp,sp,32
    4cdc:	00008067          	ret

00004ce0 <blt_copy>:
{ e_copy(ATTR_DEFAULT, src, dst, ss, ds, w, h); }
    4ce0:	fe010113          	addi	sp,sp,-32
    4ce4:	00112e23          	sw	ra,28(sp)
    4ce8:	00812c23          	sw	s0,24(sp)
    4cec:	00912a23          	sw	s1,20(sp)
    4cf0:	01212823          	sw	s2,16(sp)
    4cf4:	01312623          	sw	s3,12(sp)
    4cf8:	01412423          	sw	s4,8(sp)
    4cfc:	01512223          	sw	s5,4(sp)
    4d00:	00050413          	mv	s0,a0
    4d04:	00058493          	mv	s1,a1
    4d08:	00060913          	mv	s2,a2
    4d0c:	00068993          	mv	s3,a3
    4d10:	00070a13          	mv	s4,a4
    4d14:	00078a93          	mv	s5,a5
    4d18:	00000693          	li	a3,0
    4d1c:	0ff00613          	li	a2,255
    4d20:	00000593          	li	a1,0
    4d24:	00000513          	li	a0,0
    4d28:	df0fd0ef          	jal	2318 <attr_word>
    4d2c:	000a8813          	mv	a6,s5
    4d30:	000a0793          	mv	a5,s4
    4d34:	00098713          	mv	a4,s3
    4d38:	00090693          	mv	a3,s2
    4d3c:	00048613          	mv	a2,s1
    4d40:	00040593          	mv	a1,s0
    4d44:	f5dff0ef          	jal	4ca0 <e_copy>
    4d48:	01c12083          	lw	ra,28(sp)
    4d4c:	01812403          	lw	s0,24(sp)
    4d50:	01412483          	lw	s1,20(sp)
    4d54:	01012903          	lw	s2,16(sp)
    4d58:	00c12983          	lw	s3,12(sp)
    4d5c:	00812a03          	lw	s4,8(sp)
    4d60:	00412a83          	lw	s5,4(sp)
    4d64:	02010113          	addi	sp,sp,32
    4d68:	00008067          	ret

00004d6c <decor_repaint_emit>:
{
    4d6c:	ff010113          	addi	sp,sp,-16
    4d70:	00112623          	sw	ra,12(sp)
    uint32_t dst = g_fb_back + (uint32_t)TOP_Y0 * FB_STRIDE;
    4d74:	8581a503          	lw	a0,-1960(gp) # 7880 <g_fb_back>
    4d78:	000087b7          	lui	a5,0x8
    4d7c:	80078793          	addi	a5,a5,-2048 # 7800 <__clz_tab+0xc8>
    4d80:	00f50533          	add	a0,a0,a5
    if (g_scene == SC_LAYER)
    4d84:	8e41a703          	lw	a4,-1820(gp) # 790c <g_scene>
    4d88:	00300793          	li	a5,3
    4d8c:	02f70263          	beq	a4,a5,4db0 <decor_repaint_emit+0x44>
        blt_fill(dst, FB_STRIDE, FB_WIDTH, (uint32_t)PLAY_H, COL_BG);
    4d90:	00800713          	li	a4,8
    4d94:	20c00693          	li	a3,524
    4d98:	3c000613          	li	a2,960
    4d9c:	78000593          	li	a1,1920
    4da0:	c71ff0ef          	jal	4a10 <blt_fill>
}
    4da4:	00c12083          	lw	ra,12(sp)
    4da8:	01010113          	addi	sp,sp,16
    4dac:	00008067          	ret
        blt_copy(BG_BASE, dst, FB_STRIDE, FB_STRIDE, FB_WIDTH, (uint32_t)PLAY_H);
    4db0:	20c00793          	li	a5,524
    4db4:	3c000713          	li	a4,960
    4db8:	78000693          	li	a3,1920
    4dbc:	78000613          	li	a2,1920
    4dc0:	00050593          	mv	a1,a0
    4dc4:	00605537          	lui	a0,0x605
    4dc8:	f19ff0ef          	jal	4ce0 <blt_copy>
    4dcc:	fd9ff06f          	j	4da4 <decor_repaint_emit+0x38>

00004dd0 <e_key>:
{ blt_emit(attr, BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key); }
    4dd0:	fe010113          	addi	sp,sp,-32
    4dd4:	00112e23          	sw	ra,28(sp)
    4dd8:	01112223          	sw	a7,4(sp)
    4ddc:	0ff00893          	li	a7,255
    4de0:	01112023          	sw	a7,0(sp)
    4de4:	00080893          	mv	a7,a6
    4de8:	00078813          	mv	a6,a5
    4dec:	00070793          	mv	a5,a4
    4df0:	00068713          	mv	a4,a3
    4df4:	00060693          	mv	a3,a2
    4df8:	00058613          	mv	a2,a1
    4dfc:	00300593          	li	a1,3
    4e00:	ad5ff0ef          	jal	48d4 <blt_emit>
    4e04:	01c12083          	lw	ra,28(sp)
    4e08:	02010113          	addi	sp,sp,32
    4e0c:	00008067          	ret

00004e10 <blt_key>:
{ e_key(ATTR_DEFAULT, src, dst, ss, ds, w, h, key); }
    4e10:	fe010113          	addi	sp,sp,-32
    4e14:	00112e23          	sw	ra,28(sp)
    4e18:	00812c23          	sw	s0,24(sp)
    4e1c:	00912a23          	sw	s1,20(sp)
    4e20:	01212823          	sw	s2,16(sp)
    4e24:	01312623          	sw	s3,12(sp)
    4e28:	01412423          	sw	s4,8(sp)
    4e2c:	01512223          	sw	s5,4(sp)
    4e30:	01612023          	sw	s6,0(sp)
    4e34:	00050413          	mv	s0,a0
    4e38:	00058493          	mv	s1,a1
    4e3c:	00060913          	mv	s2,a2
    4e40:	00068993          	mv	s3,a3
    4e44:	00070a13          	mv	s4,a4
    4e48:	00078a93          	mv	s5,a5
    4e4c:	00080b13          	mv	s6,a6
    4e50:	00000693          	li	a3,0
    4e54:	0ff00613          	li	a2,255
    4e58:	00000593          	li	a1,0
    4e5c:	00000513          	li	a0,0
    4e60:	cb8fd0ef          	jal	2318 <attr_word>
    4e64:	000b0893          	mv	a7,s6
    4e68:	000a8813          	mv	a6,s5
    4e6c:	000a0793          	mv	a5,s4
    4e70:	00098713          	mv	a4,s3
    4e74:	00090693          	mv	a3,s2
    4e78:	00048613          	mv	a2,s1
    4e7c:	00040593          	mv	a1,s0
    4e80:	f51ff0ef          	jal	4dd0 <e_key>
    4e84:	01c12083          	lw	ra,28(sp)
    4e88:	01812403          	lw	s0,24(sp)
    4e8c:	01412483          	lw	s1,20(sp)
    4e90:	01012903          	lw	s2,16(sp)
    4e94:	00c12983          	lw	s3,12(sp)
    4e98:	00812a03          	lw	s4,8(sp)
    4e9c:	00412a83          	lw	s5,4(sp)
    4ea0:	00012b03          	lw	s6,0(sp)
    4ea4:	02010113          	addi	sp,sp,32
    4ea8:	00008067          	ret

00004eac <decor_step>:
    g_emit_cls = CLIP_CLS_DECOR;
    4eac:	00100713          	li	a4,1
    4eb0:	84e1a223          	sw	a4,-1980(gp) # 786c <g_emit_cls>
    while (*room > 0u) {
    4eb4:	00052783          	lw	a5,0(a0) # 605000 <__freertos_irq_stack_top+0x5e7dd0>
    4eb8:	2e078c63          	beqz	a5,51b0 <decor_step+0x304>
{
    4ebc:	fe010113          	addi	sp,sp,-32
    4ec0:	00112e23          	sw	ra,28(sp)
    4ec4:	00812c23          	sw	s0,24(sp)
    4ec8:	00912a23          	sw	s1,20(sp)
    4ecc:	00050413          	mv	s0,a0
        if (g_decor_st == DEC_REPAINT) {
    4ed0:	8b41a483          	lw	s1,-1868(gp) # 78dc <g_decor_st>
    4ed4:	04049463          	bnez	s1,4f1c <decor_step+0x70>
            if (g_repaint) { decor_repaint_emit(); g_repaint = 0; (*room)--; break; }
    4ed8:	8201a503          	lw	a0,-2016(gp) # 7848 <g_repaint>
    4edc:	02051263          	bnez	a0,4f00 <decor_step+0x54>
            g_decor_st = DEC_SCENE; g_decor_i = 0; break;
    4ee0:	00100713          	li	a4,1
    4ee4:	8ae1aa23          	sw	a4,-1868(gp) # 78dc <g_decor_st>
    4ee8:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
}
    4eec:	01c12083          	lw	ra,28(sp)
    4ef0:	01812403          	lw	s0,24(sp)
    4ef4:	01412483          	lw	s1,20(sp)
    4ef8:	02010113          	addi	sp,sp,32
    4efc:	00008067          	ret
            if (g_repaint) { decor_repaint_emit(); g_repaint = 0; (*room)--; break; }
    4f00:	e6dff0ef          	jal	4d6c <decor_repaint_emit>
    4f04:	8201a023          	sw	zero,-2016(gp) # 7848 <g_repaint>
    4f08:	00042783          	lw	a5,0(s0)
    4f0c:	fff78793          	addi	a5,a5,-1
    4f10:	00f42023          	sw	a5,0(s0)
    return 0;
    4f14:	00048513          	mv	a0,s1
            if (g_repaint) { decor_repaint_emit(); g_repaint = 0; (*room)--; break; }
    4f18:	fd5ff06f          	j	4eec <decor_step+0x40>
        if (g_decor_st == DEC_SCENE) {
    4f1c:	00100793          	li	a5,1
    4f20:	00f48a63          	beq	s1,a5,4f34 <decor_step+0x88>
        if (g_decor_st == DEC_BAR) {
    4f24:	00200793          	li	a5,2
    4f28:	08f48263          	beq	s1,a5,4fac <decor_step+0x100>
        return 1;                                    /* DEC_DONE */
    4f2c:	00100513          	li	a0,1
    4f30:	fbdff06f          	j	4eec <decor_step+0x40>
            if (g_scene == SC_CLIP) {
    4f34:	8e41a703          	lw	a4,-1820(gp) # 790c <g_scene>
    4f38:	00200793          	li	a5,2
    4f3c:	00f70c63          	beq	a4,a5,4f54 <decor_step+0xa8>
            g_decor_st = DEC_BAR; g_decor_i = 0; break;
    4f40:	00200713          	li	a4,2
    4f44:	8ae1aa23          	sw	a4,-1868(gp) # 78dc <g_decor_st>
    4f48:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
    return 0;
    4f4c:	00000513          	li	a0,0
            g_decor_st = DEC_BAR; g_decor_i = 0; break;
    4f50:	f9dff06f          	j	4eec <decor_step+0x40>
                if (g_decor_i < 4) { decor_clip_edge_emit(g_decor_i++); (*room)--; break; }
    4f54:	8b01a503          	lw	a0,-1872(gp) # 78d8 <g_decor_i>
    4f58:	00300793          	li	a5,3
    4f5c:	02a7d863          	bge	a5,a0,4f8c <decor_step+0xe0>
                if (g_decor_i < 4 + HUD_ITEMS) { decor_hud_emit(g_decor_i++ - 4); (*room)--; break; }
    4f60:	00c00793          	li	a5,12
    4f64:	fca7cee3          	blt	a5,a0,4f40 <decor_step+0x94>
    4f68:	00150713          	addi	a4,a0,1
    4f6c:	8ae1a823          	sw	a4,-1872(gp) # 78d8 <g_decor_i>
    4f70:	ffc50513          	addi	a0,a0,-4
    4f74:	b71ff0ef          	jal	4ae4 <decor_hud_emit>
    4f78:	00042783          	lw	a5,0(s0)
    4f7c:	fff78793          	addi	a5,a5,-1
    4f80:	00f42023          	sw	a5,0(s0)
    return 0;
    4f84:	00000513          	li	a0,0
                if (g_decor_i < 4 + HUD_ITEMS) { decor_hud_emit(g_decor_i++ - 4); (*room)--; break; }
    4f88:	f65ff06f          	j	4eec <decor_step+0x40>
                if (g_decor_i < 4) { decor_clip_edge_emit(g_decor_i++); (*room)--; break; }
    4f8c:	00150713          	addi	a4,a0,1
    4f90:	8ae1a823          	sw	a4,-1872(gp) # 78d8 <g_decor_i>
    4f94:	af9ff0ef          	jal	4a8c <decor_clip_edge_emit>
    4f98:	00042783          	lw	a5,0(s0)
    4f9c:	fff78793          	addi	a5,a5,-1
    4fa0:	00f42023          	sw	a5,0(s0)
    return 0;
    4fa4:	00000513          	li	a0,0
                if (g_decor_i < 4) { decor_clip_edge_emit(g_decor_i++); (*room)--; break; }
    4fa8:	f45ff06f          	j	4eec <decor_step+0x40>
            if (g_bar_need) {
    4fac:	8ac1a783          	lw	a5,-1876(gp) # 78d4 <g_bar_need>
    4fb0:	04078863          	beqz	a5,5000 <decor_step+0x154>
                if (g_decor_i == 0) {                     /* ① 一条黑底铺满整条信息条 */
    4fb4:	8b01a783          	lw	a5,-1872(gp) # 78d8 <g_decor_i>
    4fb8:	04078c63          	beqz	a5,5010 <decor_step+0x164>
                if (g_decor_i <= g_bar_len) {              /* ② 左串逐个字形（KEY 抠图） */
    4fbc:	8a81a583          	lw	a1,-1880(gp) # 78d0 <g_bar_len>
    4fc0:	0af5d663          	bge	a1,a5,506c <decor_step+0x1c0>
                if (g_decor_i <= g_bar_len + g_lbl_len) {  /* ③ 右标签（右对齐） */
    4fc4:	8a41a703          	lw	a4,-1884(gp) # 78cc <g_lbl_len>
    4fc8:	00e586b3          	add	a3,a1,a4
    4fcc:	12f6de63          	bge	a3,a5,5108 <decor_step+0x25c>
                if (g_osd_dirty) { g_bar_ok[0] = 0; g_bar_ok[1] = 0; g_bar_ok[2] = 0; g_osd_dirty = 0; }
    4fd0:	8341a783          	lw	a5,-1996(gp) # 785c <g_osd_dirty>
    4fd4:	00078c63          	beqz	a5,4fec <decor_step+0x140>
    4fd8:	94018c23          	sb	zero,-1704(gp) # 7980 <g_bar_ok>
    4fdc:	95818793          	addi	a5,gp,-1704 # 7980 <g_bar_ok>
    4fe0:	000780a3          	sb	zero,1(a5)
    4fe4:	00078123          	sb	zero,2(a5)
    4fe8:	8201aa23          	sw	zero,-1996(gp) # 785c <g_osd_dirty>
                g_bar_ok[(uint32_t)g_draw3] = 1;
    4fec:	8541a783          	lw	a5,-1964(gp) # 787c <g_draw3>
    4ff0:	95818713          	addi	a4,gp,-1704 # 7980 <g_bar_ok>
    4ff4:	00e787b3          	add	a5,a5,a4
    4ff8:	00100713          	li	a4,1
    4ffc:	00e78023          	sb	a4,0(a5)
            g_decor_st = DEC_DONE; break;
    5000:	00300713          	li	a4,3
    5004:	8ae1aa23          	sw	a4,-1868(gp) # 78dc <g_decor_st>
    return 0;
    5008:	00000513          	li	a0,0
            g_decor_st = DEC_DONE; break;
    500c:	ee1ff06f          	j	4eec <decor_step+0x40>
                    osd_strip_rect(&r);
    5010:	00010513          	mv	a0,sp
    5014:	931fe0ef          	jal	3944 <osd_strip_rect>
                    blt_fill(g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u,
    5018:	00412703          	lw	a4,4(sp)
    501c:	00471793          	slli	a5,a4,0x4
    5020:	40e787b3          	sub	a5,a5,a4
    5024:	00679793          	slli	a5,a5,0x6
    5028:	00012703          	lw	a4,0(sp)
    502c:	00e787b3          	add	a5,a5,a4
    5030:	00179793          	slli	a5,a5,0x1
    5034:	8581a503          	lw	a0,-1960(gp) # 7880 <g_fb_back>
    5038:	00000713          	li	a4,0
    503c:	00c12683          	lw	a3,12(sp)
    5040:	00812603          	lw	a2,8(sp)
    5044:	78000593          	li	a1,1920
    5048:	00a78533          	add	a0,a5,a0
    504c:	9c5ff0ef          	jal	4a10 <blt_fill>
                    g_decor_i = 1; (*room)--; break;
    5050:	00100713          	li	a4,1
    5054:	8ae1a823          	sw	a4,-1872(gp) # 78d8 <g_decor_i>
    5058:	00042783          	lw	a5,0(s0)
    505c:	fff78793          	addi	a5,a5,-1
    5060:	00f42023          	sw	a5,0(s0)
    return 0;
    5064:	00000513          	li	a0,0
    5068:	e85ff06f          	j	4eec <decor_step+0x40>
    506c:	01212823          	sw	s2,16(sp)
                    int c = g_decor_i - 1;
    5070:	fff78493          	addi	s1,a5,-1
                    osd_glyph_rect(c, g_bar_len, &r, 1);
    5074:	00100693          	li	a3,1
    5078:	00010613          	mv	a2,sp
    507c:	00048513          	mv	a0,s1
    5080:	8e1fe0ef          	jal	3960 <osd_glyph_rect>
                    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    5084:	00412783          	lw	a5,4(sp)
    5088:	00479913          	slli	s2,a5,0x4
    508c:	40f90933          	sub	s2,s2,a5
    5090:	00691913          	slli	s2,s2,0x6
    5094:	00012783          	lw	a5,0(sp)
    5098:	00f90933          	add	s2,s2,a5
    509c:	00191913          	slli	s2,s2,0x1
    50a0:	8581a783          	lw	a5,-1960(gp) # 7880 <g_fb_back>
    50a4:	00f90933          	add	s2,s2,a5
                    blt_key(FONT_BASE + FONT_GLYPH_OFF(glyph_idx(g_osd_line[c])),
    50a8:	99818793          	addi	a5,gp,-1640 # 79c0 <g_osd_line>
    50ac:	009787b3          	add	a5,a5,s1
    50b0:	0007c503          	lbu	a0,0(a5)
    50b4:	ee0fd0ef          	jal	2794 <glyph_idx>
    50b8:	000047b7          	lui	a5,0x4
    50bc:	42078793          	addi	a5,a5,1056 # 4420 <lut_bank_calib+0xb8>
    50c0:	00f50533          	add	a0,a0,a5
    50c4:	00010837          	lui	a6,0x10
    50c8:	81f80813          	addi	a6,a6,-2017 # f81f <__global_pointer$+0x77f7>
    50cc:	00c12783          	lw	a5,12(sp)
    50d0:	00812703          	lw	a4,8(sp)
    50d4:	78000693          	li	a3,1920
    50d8:	01000613          	li	a2,16
    50dc:	00090593          	mv	a1,s2
    50e0:	00751513          	slli	a0,a0,0x7
    50e4:	d2dff0ef          	jal	4e10 <blt_key>
                    g_decor_i++; (*room)--; break;
    50e8:	8b01a783          	lw	a5,-1872(gp) # 78d8 <g_decor_i>
    50ec:	00178793          	addi	a5,a5,1
    50f0:	8af1a823          	sw	a5,-1872(gp) # 78d8 <g_decor_i>
    50f4:	00042783          	lw	a5,0(s0)
    50f8:	fff78793          	addi	a5,a5,-1
    50fc:	00f42023          	sw	a5,0(s0)
    5100:	01012903          	lw	s2,16(sp)
    5104:	f61ff06f          	j	5064 <decor_step+0x1b8>
    5108:	01212823          	sw	s2,16(sp)
                    int c = g_decor_i - g_bar_len - 1;
    510c:	40b787b3          	sub	a5,a5,a1
    5110:	fff78493          	addi	s1,a5,-1
                    osd_glyph_rect(c, g_lbl_len, &r, 0);
    5114:	00000693          	li	a3,0
    5118:	00010613          	mv	a2,sp
    511c:	00070593          	mv	a1,a4
    5120:	00048513          	mv	a0,s1
    5124:	83dfe0ef          	jal	3960 <osd_glyph_rect>
                    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    5128:	00412783          	lw	a5,4(sp)
    512c:	00479913          	slli	s2,a5,0x4
    5130:	40f90933          	sub	s2,s2,a5
    5134:	00691913          	slli	s2,s2,0x6
    5138:	00012783          	lw	a5,0(sp)
    513c:	00f90933          	add	s2,s2,a5
    5140:	00191913          	slli	s2,s2,0x1
    5144:	8581a783          	lw	a5,-1960(gp) # 7880 <g_fb_back>
    5148:	00f90933          	add	s2,s2,a5
                    blt_key(FONT_BASE + FONT_GLYPH_OFF(glyph_idx(OSD_LABEL[c])),
    514c:	000077b7          	lui	a5,0x7
    5150:	9a078793          	addi	a5,a5,-1632 # 69a0 <_data+0x9ec>
    5154:	009787b3          	add	a5,a5,s1
    5158:	0007c503          	lbu	a0,0(a5)
    515c:	e38fd0ef          	jal	2794 <glyph_idx>
    5160:	000047b7          	lui	a5,0x4
    5164:	42078793          	addi	a5,a5,1056 # 4420 <lut_bank_calib+0xb8>
    5168:	00f50533          	add	a0,a0,a5
    516c:	00010837          	lui	a6,0x10
    5170:	81f80813          	addi	a6,a6,-2017 # f81f <__global_pointer$+0x77f7>
    5174:	00c12783          	lw	a5,12(sp)
    5178:	00812703          	lw	a4,8(sp)
    517c:	78000693          	li	a3,1920
    5180:	01000613          	li	a2,16
    5184:	00090593          	mv	a1,s2
    5188:	00751513          	slli	a0,a0,0x7
    518c:	c85ff0ef          	jal	4e10 <blt_key>
                    g_decor_i++; (*room)--; break;
    5190:	8b01a783          	lw	a5,-1872(gp) # 78d8 <g_decor_i>
    5194:	00178793          	addi	a5,a5,1
    5198:	8af1a823          	sw	a5,-1872(gp) # 78d8 <g_decor_i>
    519c:	00042783          	lw	a5,0(s0)
    51a0:	fff78793          	addi	a5,a5,-1
    51a4:	00f42023          	sw	a5,0(s0)
    51a8:	01012903          	lw	s2,16(sp)
    51ac:	eb9ff06f          	j	5064 <decor_step+0x1b8>
    return 0;
    51b0:	00000513          	li	a0,0
}
    51b4:	00008067          	ret

000051b8 <e_alpha>:
{ blt_emit(attr, BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha, 0u); }
    51b8:	fe010113          	addi	sp,sp,-32
    51bc:	00112e23          	sw	ra,28(sp)
    51c0:	00012223          	sw	zero,4(sp)
    51c4:	01112023          	sw	a7,0(sp)
    51c8:	00080893          	mv	a7,a6
    51cc:	00078813          	mv	a6,a5
    51d0:	00070793          	mv	a5,a4
    51d4:	00068713          	mv	a4,a3
    51d8:	00060693          	mv	a3,a2
    51dc:	00058613          	mv	a2,a1
    51e0:	00200593          	li	a1,2
    51e4:	ef0ff0ef          	jal	48d4 <blt_emit>
    51e8:	01c12083          	lw	ra,28(sp)
    51ec:	02010113          	addi	sp,sp,32
    51f0:	00008067          	ret

000051f4 <blt_glow>:
{
    51f4:	ff010113          	addi	sp,sp,-16
    51f8:	00112623          	sw	ra,12(sp)
    51fc:	00812423          	sw	s0,8(sp)
    5200:	00912223          	sw	s1,4(sp)
    5204:	00058413          	mv	s0,a1
    5208:	00060493          	mv	s1,a2
    if (g_attr_on)
    520c:	9381a783          	lw	a5,-1736(gp) # 7960 <g_attr_on>
    5210:	04078a63          	beqz	a5,5264 <blt_glow+0x70>
    5214:	01212023          	sw	s2,0(sp)
    5218:	00050913          	mv	s2,a0
        e_alpha(attr_word(ATTR_BLEND_ADD, ATTR_FMT_4444, ga, 0u), src, dst,
    521c:	00000693          	li	a3,0
    5220:	00200593          	li	a1,2
    5224:	00200513          	li	a0,2
    5228:	8f0fd0ef          	jal	2318 <attr_word>
                SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, 0xFFu);
    522c:	85c1a783          	lw	a5,-1956(gp) # 7884 <g_blk>
        e_alpha(attr_word(ATTR_BLEND_ADD, ATTR_FMT_4444, ga, 0u), src, dst,
    5230:	0ff00893          	li	a7,255
    5234:	00078813          	mv	a6,a5
    5238:	78000713          	li	a4,1920
    523c:	00179693          	slli	a3,a5,0x1
    5240:	00040613          	mv	a2,s0
    5244:	00090593          	mv	a1,s2
    5248:	f71ff0ef          	jal	51b8 <e_alpha>
    524c:	00012903          	lw	s2,0(sp)
}
    5250:	00c12083          	lw	ra,12(sp)
    5254:	00812403          	lw	s0,8(sp)
    5258:	00412483          	lw	s1,4(sp)
    525c:	01010113          	addi	sp,sp,16
    5260:	00008067          	ret
        e_alpha(ATTR_DEFAULT, ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, ga);
    5264:	00000693          	li	a3,0
    5268:	0ff00613          	li	a2,255
    526c:	00000593          	li	a1,0
    5270:	00000513          	li	a0,0
    5274:	8a4fd0ef          	jal	2318 <attr_word>
    5278:	85c1a783          	lw	a5,-1956(gp) # 7884 <g_blk>
    527c:	00048893          	mv	a7,s1
    5280:	00078813          	mv	a6,a5
    5284:	78000713          	li	a4,1920
    5288:	00179693          	slli	a3,a5,0x1
    528c:	00040613          	mv	a2,s0
    5290:	002015b7          	lui	a1,0x201
    5294:	f25ff0ef          	jal	51b8 <e_alpha>
}
    5298:	fb9ff06f          	j	5250 <blt_glow+0x5c>

0000529c <sprite_emit>:
{
    529c:	fe010113          	addi	sp,sp,-32
    52a0:	00112e23          	sw	ra,28(sp)
    52a4:	00812c23          	sw	s0,24(sp)
    52a8:	00912a23          	sw	s1,20(sp)
    52ac:	00050413          	mv	s0,a0
    unsigned ga = ((unsigned)p->a * g_alpha) / 255u;
    52b0:	000087b7          	lui	a5,0x8
    52b4:	00351713          	slli	a4,a0,0x3
    52b8:	40a70733          	sub	a4,a4,a0
    52bc:	00171713          	slli	a4,a4,0x1
    52c0:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    52c4:	00e787b3          	add	a5,a5,a4
    52c8:	00c7c783          	lbu	a5,12(a5)
    52cc:	82c1a703          	lw	a4,-2004(gp) # 7854 <g_alpha>
    52d0:	02e787b3          	mul	a5,a5,a4
    52d4:	0ff00713          	li	a4,255
    52d8:	02e7d4b3          	divu	s1,a5,a4
    content_rect(i, &r);
    52dc:	00010593          	mv	a1,sp
    52e0:	bd1fe0ef          	jal	3eb0 <content_rect>
    dst = g_fb_back + (uint32_t)r.dy * FB_STRIDE + (uint32_t)r.dx * 2u;
    52e4:	00412783          	lw	a5,4(sp)
    52e8:	00479593          	slli	a1,a5,0x4
    52ec:	40f585b3          	sub	a1,a1,a5
    52f0:	00659593          	slli	a1,a1,0x6
    52f4:	00012783          	lw	a5,0(sp)
    52f8:	00f585b3          	add	a1,a1,a5
    52fc:	00159593          	slli	a1,a1,0x1
    5300:	8581a783          	lw	a5,-1960(gp) # 7880 <g_fb_back>
    5304:	00f585b3          	add	a1,a1,a5
    if (g_scene == SC_CLIP)
    5308:	8e41a703          	lw	a4,-1820(gp) # 790c <g_scene>
    530c:	00200793          	li	a5,2
    5310:	04f70c63          	beq	a4,a5,5368 <sprite_emit+0xcc>
        blt_glow(GLOW_BASE + (uint32_t)p->v * GLOW_VAR_STRIDE, dst, ga);
    5314:	000087b7          	lui	a5,0x8
    5318:	00341713          	slli	a4,s0,0x3
    531c:	40870733          	sub	a4,a4,s0
    5320:	00171713          	slli	a4,a4,0x1
    5324:	a0c78793          	addi	a5,a5,-1524 # 7a0c <g_pt>
    5328:	00e787b3          	add	a5,a5,a4
    532c:	00d7c783          	lbu	a5,13(a5)
    5330:	85c1a503          	lw	a0,-1956(gp) # 7884 <g_blk>
    5334:	02a50533          	mul	a0,a0,a0
    5338:	02f50533          	mul	a0,a0,a5
    533c:	001097b7          	lui	a5,0x109
    5340:	80078793          	addi	a5,a5,-2048 # 108800 <__freertos_irq_stack_top+0xeb5d0>
    5344:	00f50533          	add	a0,a0,a5
    5348:	00048613          	mv	a2,s1
    534c:	00151513          	slli	a0,a0,0x1
    5350:	ea5ff0ef          	jal	51f4 <blt_glow>
}
    5354:	01c12083          	lw	ra,28(sp)
    5358:	01812403          	lw	s0,24(sp)
    535c:	01412483          	lw	s1,20(sp)
    5360:	02010113          	addi	sp,sp,32
    5364:	00008067          	ret
        blt_key(ATLAS_BASE, dst, SPR_STRIDE, FB_STRIDE, SPR_W, SPR_H, (uint32_t)KEY_COLOR);
    5368:	85c1a783          	lw	a5,-1956(gp) # 7884 <g_blk>
    536c:	00010837          	lui	a6,0x10
    5370:	81f80813          	addi	a6,a6,-2017 # f81f <__global_pointer$+0x77f7>
    5374:	00078713          	mv	a4,a5
    5378:	78000693          	li	a3,1920
    537c:	00179613          	slli	a2,a5,0x1
    5380:	00201537          	lui	a0,0x201
    5384:	a8dff0ef          	jal	4e10 <blt_key>
    5388:	fcdff06f          	j	5354 <sprite_emit+0xb8>

0000538c <content_emit>:
{
    538c:	ff010113          	addi	sp,sp,-16
    5390:	00112623          	sw	ra,12(sp)
    g_emit_cls = CLIP_CLS_FIELD;                    /* ★ 段 1 = playfield 内容：唯一允许被裁的一类 */
    5394:	8401a223          	sw	zero,-1980(gp) # 786c <g_emit_cls>
    if (k < g_n)                 sprite_emit(k);
    5398:	8301a783          	lw	a5,-2000(gp) # 7858 <g_n>
    539c:	00f54e63          	blt	a0,a5,53b8 <content_emit+0x2c>
    else if (g_scene == SC_CLIP) sweep_emit(k - g_n);
    53a0:	8e41a683          	lw	a3,-1820(gp) # 790c <g_scene>
    53a4:	00200713          	li	a4,2
    53a8:	00e68c63          	beq	a3,a4,53c0 <content_emit+0x34>
}
    53ac:	00c12083          	lw	ra,12(sp)
    53b0:	01010113          	addi	sp,sp,16
    53b4:	00008067          	ret
    if (k < g_n)                 sprite_emit(k);
    53b8:	ee5ff0ef          	jal	529c <sprite_emit>
    53bc:	ff1ff06f          	j	53ac <content_emit+0x20>
    else if (g_scene == SC_CLIP) sweep_emit(k - g_n);
    53c0:	40f50533          	sub	a0,a0,a5
    53c4:	865ff0ef          	jal	4c28 <sweep_emit>
}
    53c8:	fe5ff06f          	j	53ac <content_emit+0x20>

000053cc <osd_selfcheck>:
{
    53cc:	f8010113          	addi	sp,sp,-128
    53d0:	06112e23          	sw	ra,124(sp)
    fmt_stat(worst, 99u, N_MAX, SC_LAYER, BLK_HI, 255u, 9999u, 100u, 1, 1, 1, 1, 1);
    53d4:	00100793          	li	a5,1
    53d8:	00f12823          	sw	a5,16(sp)
    53dc:	00f12623          	sw	a5,12(sp)
    53e0:	00f12423          	sw	a5,8(sp)
    53e4:	00f12223          	sw	a5,4(sp)
    53e8:	00f12023          	sw	a5,0(sp)
    53ec:	06400893          	li	a7,100
    53f0:	00002837          	lui	a6,0x2
    53f4:	70f80813          	addi	a6,a6,1807 # 270f <glow_color+0xd3>
    53f8:	0ff00793          	li	a5,255
    53fc:	04000713          	li	a4,64
    5400:	00300693          	li	a3,3
    5404:	00001637          	lui	a2,0x1
    5408:	77060613          	addi	a2,a2,1904 # 1770 <main+0x66c>
    540c:	06300593          	li	a1,99
    5410:	02410513          	addi	a0,sp,36
    5414:	ff5fd0ef          	jal	3408 <fmt_stat>
    len = slen(worst);
    5418:	02410513          	addi	a0,sp,36
    541c:	9d0fe0ef          	jal	35ec <slen>
    5420:	00050593          	mv	a1,a0
               len, len * OSD_GLYPH_W, OSD_TEXT_X0, OSD_TEXT_X0 + len * OSD_GLYPH_W,
    5424:	00150713          	addi	a4,a0,1 # 201001 <__freertos_irq_stack_top+0x1e3dd1>
    bsp_printf("osd worst: len=%d px=%d text x=[%d,%d) strip x=[%d,%d) label x=[%d,%d) fit=%d\r\n",
    5428:	04952793          	slti	a5,a0,73
    542c:	00f12223          	sw	a5,4(sp)
    5430:	3c000793          	li	a5,960
    5434:	00f12023          	sw	a5,0(sp)
    5438:	38000893          	li	a7,896
    543c:	24800813          	li	a6,584
    5440:	00800793          	li	a5,8
    5444:	00371713          	slli	a4,a4,0x3
    5448:	00800693          	li	a3,8
    544c:	00351613          	slli	a2,a0,0x3
    5450:	00007537          	lui	a0,0x7
    5454:	9a850513          	addi	a0,a0,-1624 # 69a8 <_data+0x9f4>
    5458:	c5dfe0ef          	jal	40b4 <bsp_printf>
    bsp_printf("osd worst: \"%s\"\r\n", worst);
    545c:	02410593          	addi	a1,sp,36
    5460:	00007537          	lui	a0,0x7
    5464:	9f850513          	addi	a0,a0,-1544 # 69f8 <_data+0xa44>
    5468:	c4dfe0ef          	jal	40b4 <bsp_printf>
}
    546c:	07c12083          	lw	ra,124(sp)
    5470:	08010113          	addi	sp,sp,128
    5474:	00008067          	ret

00005478 <build_atlas>:
{
    5478:	fd010113          	addi	sp,sp,-48
    547c:	02112623          	sw	ra,44(sp)
    5480:	02812423          	sw	s0,40(sp)
    5484:	02912223          	sw	s1,36(sp)
    5488:	03212023          	sw	s2,32(sp)
    548c:	01312e23          	sw	s3,28(sp)
    5490:	01412c23          	sw	s4,24(sp)
    5494:	01512a23          	sw	s5,20(sp)
    for (j = 0; j < SPR_H; j++)
    5498:	00000993          	li	s3,0
    549c:	0340006f          	j	54d0 <build_atlas+0x58>
            d[j * SPR_W + i] = disc_color(i, j);                 /* ① RGB565 圆盘 */
    54a0:	033407b3          	mul	a5,s0,s3
    54a4:	009787b3          	add	a5,a5,s1
    54a8:	00179793          	slli	a5,a5,0x1
    54ac:	00201937          	lui	s2,0x201
    54b0:	00f90933          	add	s2,s2,a5
    54b4:	00098593          	mv	a1,s3
    54b8:	00048513          	mv	a0,s1
    54bc:	8b4fd0ef          	jal	2570 <disc_color>
    54c0:	00a91023          	sh	a0,0(s2) # 201000 <__freertos_irq_stack_top+0x1e3dd0>
        for (i = 0; i < SPR_W; i++)
    54c4:	00148493          	addi	s1,s1,1
    54c8:	fc84cce3          	blt	s1,s0,54a0 <build_atlas+0x28>
    for (j = 0; j < SPR_H; j++)
    54cc:	00198993          	addi	s3,s3,1
    54d0:	85c1a403          	lw	s0,-1956(gp) # 7884 <g_blk>
    54d4:	0089d663          	bge	s3,s0,54e0 <build_atlas+0x68>
        for (i = 0; i < SPR_W; i++)
    54d8:	00000493          	li	s1,0
    54dc:	fedff06f          	j	54c8 <build_atlas+0x50>
    for (v = 0; v < GLOW_VARIANTS; v++) {                        /* ② 4 档 ARGB4444 辉光 */
    54e0:	00000a93          	li	s5,0
    54e4:	0440006f          	j	5528 <build_atlas+0xb0>
        for (j = 0; j < SPR_H; j++)
    54e8:	00198993          	addi	s3,s3,1
    54ec:	0289dc63          	bge	s3,s0,5524 <build_atlas+0xac>
            for (i = 0; i < SPR_W; i++)
    54f0:	00000913          	li	s2,0
    54f4:	fe895ae3          	bge	s2,s0,54e8 <build_atlas+0x70>
                g[j * SPR_W + i] = glow_color(i, j, v);
    54f8:	033404b3          	mul	s1,s0,s3
    54fc:	012484b3          	add	s1,s1,s2
    5500:	00149493          	slli	s1,s1,0x1
    5504:	009a04b3          	add	s1,s4,s1
    5508:	000a8613          	mv	a2,s5
    550c:	00098593          	mv	a1,s3
    5510:	00090513          	mv	a0,s2
    5514:	928fd0ef          	jal	263c <glow_color>
    5518:	00a49023          	sh	a0,0(s1)
            for (i = 0; i < SPR_W; i++)
    551c:	00190913          	addi	s2,s2,1
    5520:	fd5ff06f          	j	54f4 <build_atlas+0x7c>
    for (v = 0; v < GLOW_VARIANTS; v++) {                        /* ② 4 档 ARGB4444 辉光 */
    5524:	001a8a93          	addi	s5,s5,1
    5528:	00300793          	li	a5,3
    552c:	0357c263          	blt	a5,s5,5550 <build_atlas+0xd8>
        volatile uint16_t *g = (volatile uint16_t *)(GLOW_BASE + (uint32_t)v * GLOW_VAR_STRIDE);
    5530:	02840a33          	mul	s4,s0,s0
    5534:	035a0a33          	mul	s4,s4,s5
    5538:	001097b7          	lui	a5,0x109
    553c:	80078793          	addi	a5,a5,-2048 # 108800 <__freertos_irq_stack_top+0xeb5d0>
    5540:	00fa0a33          	add	s4,s4,a5
    5544:	001a1a13          	slli	s4,s4,0x1
        for (j = 0; j < SPR_H; j++)
    5548:	00000993          	li	s3,0
    554c:	fa1ff06f          	j	54ec <build_atlas+0x74>
    for (v = 0; v < FONT_N; v++) {                               /* ③ 8x8 字形（白字 + 色键底） */
    5550:	00000813          	li	a6,0
    5554:	07c0006f          	j	55d0 <build_atlas+0x158>
                    (uint16_t)((bits & (uint8_t)(0x80u >> i)) ? COL_WHITE : KEY_COLOR);
    5558:	000106b7          	lui	a3,0x10
    555c:	81f68693          	addi	a3,a3,-2017 # f81f <__global_pointer$+0x77f7>
                p[j * (FONT_ROW_BYTES / 2) + i] =
    5560:	00361793          	slli	a5,a2,0x3
    5564:	00e787b3          	add	a5,a5,a4
    5568:	00179793          	slli	a5,a5,0x1
    556c:	00f507b3          	add	a5,a0,a5
    5570:	00d79023          	sh	a3,0(a5)
            for (i = 0; i < 8; i++)
    5574:	00170713          	addi	a4,a4,1
    5578:	00700793          	li	a5,7
    557c:	02e7c063          	blt	a5,a4,559c <build_atlas+0x124>
                    (uint16_t)((bits & (uint8_t)(0x80u >> i)) ? COL_WHITE : KEY_COLOR);
    5580:	08000793          	li	a5,128
    5584:	00e7d7b3          	srl	a5,a5,a4
    5588:	00b7f7b3          	and	a5,a5,a1
    558c:	fc0786e3          	beqz	a5,5558 <build_atlas+0xe0>
    5590:	000106b7          	lui	a3,0x10
    5594:	fff68693          	addi	a3,a3,-1 # ffff <__global_pointer$+0x7fd7>
    5598:	fc9ff06f          	j	5560 <build_atlas+0xe8>
        for (j = 0; j < 8; j++) {
    559c:	00160613          	addi	a2,a2,1
    55a0:	00700793          	li	a5,7
    55a4:	02c7c463          	blt	a5,a2,55cc <build_atlas+0x154>
            uint8_t bits = g_font[v].r[j];
    55a8:	000077b7          	lui	a5,0x7
    55ac:	00381713          	slli	a4,a6,0x3
    55b0:	01070733          	add	a4,a4,a6
    55b4:	5b078793          	addi	a5,a5,1456 # 75b0 <g_font>
    55b8:	00e787b3          	add	a5,a5,a4
    55bc:	00c787b3          	add	a5,a5,a2
    55c0:	0017c583          	lbu	a1,1(a5)
            for (i = 0; i < 8; i++)
    55c4:	00000713          	li	a4,0
    55c8:	fb1ff06f          	j	5578 <build_atlas+0x100>
    for (v = 0; v < FONT_N; v++) {                               /* ③ 8x8 字形（白字 + 色键底） */
    55cc:	00180813          	addi	a6,a6,1
    55d0:	02900793          	li	a5,41
    55d4:	0107ce63          	blt	a5,a6,55f0 <build_atlas+0x178>
        volatile uint16_t *p = (volatile uint16_t *)(FONT_BASE + FONT_GLYPH_OFF(v));
    55d8:	000047b7          	lui	a5,0x4
    55dc:	42078793          	addi	a5,a5,1056 # 4420 <lut_bank_calib+0xb8>
    55e0:	00f807b3          	add	a5,a6,a5
    55e4:	00779513          	slli	a0,a5,0x7
        for (j = 0; j < 8; j++) {
    55e8:	00000613          	li	a2,0
    55ec:	fb5ff06f          	j	55a0 <build_atlas+0x128>
    bsp_printf("bake: disc %dx%d @%x  glow %dx%d x%d @%x  font %d glyphs @%x\r\n",
    55f0:	002217b7          	lui	a5,0x221
    55f4:	00f12223          	sw	a5,4(sp)
    55f8:	02a00793          	li	a5,42
    55fc:	00f12023          	sw	a5,0(sp)
    5600:	002118b7          	lui	a7,0x211
    5604:	00400813          	li	a6,4
    5608:	00040793          	mv	a5,s0
    560c:	00040713          	mv	a4,s0
    5610:	002016b7          	lui	a3,0x201
    5614:	00040613          	mv	a2,s0
    5618:	00040593          	mv	a1,s0
    561c:	00007537          	lui	a0,0x7
    5620:	a0c50513          	addi	a0,a0,-1524 # 6a0c <_data+0xa58>
    5624:	a91fe0ef          	jal	40b4 <bsp_printf>
}
    5628:	02c12083          	lw	ra,44(sp)
    562c:	02812403          	lw	s0,40(sp)
    5630:	02412483          	lw	s1,36(sp)
    5634:	02012903          	lw	s2,32(sp)
    5638:	01c12983          	lw	s3,28(sp)
    563c:	01812a03          	lw	s4,24(sp)
    5640:	01412a83          	lw	s5,20(sp)
    5644:	03010113          	addi	sp,sp,48
    5648:	00008067          	ret

0000564c <lut_state_line>:
{
    564c:	fe010113          	addi	sp,sp,-32
    5650:	00112e23          	sw	ra,28(sp)
    5654:	00812c23          	sw	s0,24(sp)
    5658:	00912a23          	sw	s1,20(sp)
    565c:	00050493          	mv	s1,a0
    uint32_t ctl  = g_feat_lut ? blt_rd(BLT_LUT_CTRL) : 0UL;
    5660:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    5664:	06079663          	bnez	a5,56d0 <lut_state_line+0x84>
    5668:	00000413          	li	s0,0
    uint32_t disp = g_feat_lut ? (blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK) : 0UL;
    566c:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    5670:	06079863          	bnez	a5,56e0 <lut_state_line+0x94>
    5674:	00000693          	li	a3,0
    bsp_printf("EV lut %s: en=%d disp=%d write=%d polarity=%s fade=%d flash=%d pend=%d to=%d\r\n",
    5678:	00147613          	andi	a2,s0,1
               tag, (int)(ctl & BLT_LUT_EN), (int)disp, (int)((ctl >> 1) & 1UL),
    567c:	00145713          	srli	a4,s0,0x1
    bsp_printf("EV lut %s: en=%d disp=%d write=%d polarity=%s fade=%d flash=%d pend=%d to=%d\r\n",
    5680:	00177713          	andi	a4,a4,1
               g_lut_inv ? "display=~write" : "display=write",
    5684:	83c1a783          	lw	a5,-1988(gp) # 7864 <g_lut_inv>
    bsp_printf("EV lut %s: en=%d disp=%d write=%d polarity=%s fade=%d flash=%d pend=%d to=%d\r\n",
    5688:	06078463          	beqz	a5,56f0 <lut_state_line+0xa4>
    568c:	000067b7          	lui	a5,0x6
    5690:	68878793          	addi	a5,a5,1672 # 6688 <_data+0x6d4>
    5694:	91c1a583          	lw	a1,-1764(gp) # 7944 <g_lut_to>
    5698:	00b12223          	sw	a1,4(sp)
    569c:	8401a583          	lw	a1,-1984(gp) # 7868 <g_lut_pend>
    56a0:	00b12023          	sw	a1,0(sp)
    56a4:	9281a883          	lw	a7,-1752(gp) # 7950 <g_lut_g>
    56a8:	8381a803          	lw	a6,-1992(gp) # 7860 <g_lut_f>
    56ac:	00048593          	mv	a1,s1
    56b0:	00007537          	lui	a0,0x7
    56b4:	a4c50513          	addi	a0,a0,-1460 # 6a4c <_data+0xa98>
    56b8:	9fdfe0ef          	jal	40b4 <bsp_printf>
}
    56bc:	01c12083          	lw	ra,28(sp)
    56c0:	01812403          	lw	s0,24(sp)
    56c4:	01412483          	lw	s1,20(sp)
    56c8:	02010113          	addi	sp,sp,32
    56cc:	00008067          	ret
    uint32_t ctl  = g_feat_lut ? blt_rd(BLT_LUT_CTRL) : 0UL;
    56d0:	0ac00513          	li	a0,172
    56d4:	940fd0ef          	jal	2814 <blt_rd>
    56d8:	00050413          	mv	s0,a0
    56dc:	f91ff06f          	j	566c <lut_state_line+0x20>
    uint32_t disp = g_feat_lut ? (blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK) : 0UL;
    56e0:	0b000513          	li	a0,176
    56e4:	930fd0ef          	jal	2814 <blt_rd>
    56e8:	00157693          	andi	a3,a0,1
    56ec:	f8dff06f          	j	5678 <lut_state_line+0x2c>
    bsp_printf("EV lut %s: en=%d disp=%d write=%d polarity=%s fade=%d flash=%d pend=%d to=%d\r\n",
    56f0:	000067b7          	lui	a5,0x6
    56f4:	69878793          	addi	a5,a5,1688 # 6698 <_data+0x6e4>
    56f8:	f9dff06f          	j	5694 <lut_state_line+0x48>

000056fc <feat_probe>:
{
    56fc:	ff010113          	addi	sp,sp,-16
    5700:	00112623          	sw	ra,12(sp)
    5704:	00812423          	sw	s0,8(sp)
    blt_wr(BLT_CLIP_X0, 0x00000123UL); blt_wr(BLT_CLIP_X1, 0x00000456UL);
    5708:	12300593          	li	a1,291
    570c:	09000513          	li	a0,144
    5710:	8f4fd0ef          	jal	2804 <blt_wr>
    5714:	45600593          	li	a1,1110
    5718:	09400513          	li	a0,148
    571c:	8e8fd0ef          	jal	2804 <blt_wr>
    blt_wr(BLT_CLIP_Y0, 0x00000789UL); blt_wr(BLT_CLIP_Y1, 0x00000AB0UL);
    5720:	78900593          	li	a1,1929
    5724:	09800513          	li	a0,152
    5728:	8dcfd0ef          	jal	2804 <blt_wr>
    572c:	000015b7          	lui	a1,0x1
    5730:	ab058593          	addi	a1,a1,-1360 # ab0 <CUSTOM2+0xa55>
    5734:	09c00513          	li	a0,156
    5738:	8ccfd0ef          	jal	2804 <blt_wr>
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    573c:	09000513          	li	a0,144
    5740:	8d4fd0ef          	jal	2814 <blt_rd>
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);
    5744:	12300793          	li	a5,291
    5748:	06f50863          	beq	a0,a5,57b8 <feat_probe+0xbc>
    574c:	00000713          	li	a4,0
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    5750:	94e1aa23          	sw	a4,-1708(gp) # 797c <g_feat_clip>
    blt_wr(BLT_LUT_CTRL, 0u);
    5754:	00000593          	li	a1,0
    5758:	0ac00513          	li	a0,172
    575c:	8a8fd0ef          	jal	2804 <blt_wr>
    lc = blt_rd(BLT_LUT_CTRL) & 3UL;
    5760:	0ac00513          	li	a0,172
    5764:	8b0fd0ef          	jal	2814 <blt_rd>
    5768:	00357413          	andi	s0,a0,3
    blt_wr(BLT_LUT_CTRL, BLT_LUT_EN | BLT_LUT_BANK);
    576c:	00300593          	li	a1,3
    5770:	0ac00513          	li	a0,172
    5774:	890fd0ef          	jal	2804 <blt_wr>
    g_feat_lut = (lc == 0UL) && ((blt_rd(BLT_LUT_CTRL) & 3UL) == (BLT_LUT_EN | BLT_LUT_BANK));
    5778:	08040a63          	beqz	s0,580c <feat_probe+0x110>
    577c:	00000713          	li	a4,0
    5780:	94e1a823          	sw	a4,-1712(gp) # 7978 <g_feat_lut>
    blt_wr(BLT_LUT_CTRL, 0u);                       /* 先关掉；真正开是在第一次 lut_publish */
    5784:	00000593          	li	a1,0
    5788:	0ac00513          	li	a0,172
    578c:	878fd0ef          	jal	2804 <blt_wr>
    g_lut_disp  = blt_rd(BLT_LUT_STAT) & BLT_LUT_STAT_BANK;
    5790:	0b000513          	li	a0,176
    5794:	880fd0ef          	jal	2814 <blt_rd>
    5798:	00157513          	andi	a0,a0,1
    579c:	92a1aa23          	sw	a0,-1740(gp) # 795c <g_lut_disp>
    g_feat_attr = (g_feat_clip && g_feat_lut) ? 1 : 0;   /* 见文件头 (d) */
    57a0:	9541a583          	lw	a1,-1708(gp) # 797c <g_feat_clip>
    57a4:	08058663          	beqz	a1,5830 <feat_probe+0x134>
    57a8:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    57ac:	0a079063          	bnez	a5,584c <feat_probe+0x150>
    57b0:	00000693          	li	a3,0
    57b4:	0800006f          	j	5834 <feat_probe+0x138>
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    57b8:	09400513          	li	a0,148
    57bc:	858fd0ef          	jal	2814 <blt_rd>
    57c0:	45600793          	li	a5,1110
    57c4:	00f50663          	beq	a0,a5,57d0 <feat_probe+0xd4>
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);
    57c8:	00000713          	li	a4,0
    57cc:	f85ff06f          	j	5750 <feat_probe+0x54>
    57d0:	09800513          	li	a0,152
    57d4:	840fd0ef          	jal	2814 <blt_rd>
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    57d8:	78900793          	li	a5,1929
    57dc:	00f50663          	beq	a0,a5,57e8 <feat_probe+0xec>
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);
    57e0:	00000713          	li	a4,0
    57e4:	f6dff06f          	j	5750 <feat_probe+0x54>
    57e8:	09c00513          	li	a0,156
    57ec:	828fd0ef          	jal	2814 <blt_rd>
    57f0:	000017b7          	lui	a5,0x1
    57f4:	ab078793          	addi	a5,a5,-1360 # ab0 <CUSTOM2+0xa55>
    57f8:	00f50663          	beq	a0,a5,5804 <feat_probe+0x108>
    57fc:	00000713          	li	a4,0
    5800:	f51ff06f          	j	5750 <feat_probe+0x54>
    5804:	00100713          	li	a4,1
    5808:	f49ff06f          	j	5750 <feat_probe+0x54>
    g_feat_lut = (lc == 0UL) && ((blt_rd(BLT_LUT_CTRL) & 3UL) == (BLT_LUT_EN | BLT_LUT_BANK));
    580c:	0ac00513          	li	a0,172
    5810:	804fd0ef          	jal	2814 <blt_rd>
    5814:	00357513          	andi	a0,a0,3
    5818:	00300793          	li	a5,3
    581c:	00f50663          	beq	a0,a5,5828 <feat_probe+0x12c>
    5820:	00000713          	li	a4,0
    5824:	f5dff06f          	j	5780 <feat_probe+0x84>
    5828:	00100713          	li	a4,1
    582c:	f55ff06f          	j	5780 <feat_probe+0x84>
    g_feat_attr = (g_feat_clip && g_feat_lut) ? 1 : 0;   /* 见文件头 (d) */
    5830:	00000693          	li	a3,0
    5834:	94d1a623          	sw	a3,-1716(gp) # 7974 <g_feat_attr>
    g_attr_on   = (g_feat_attr && g_attr_user) ? 1 : 0;
    5838:	00068e63          	beqz	a3,5854 <feat_probe+0x158>
    583c:	8481a783          	lw	a5,-1976(gp) # 7870 <g_attr_user>
    5840:	06079a63          	bnez	a5,58b4 <feat_probe+0x1b8>
    5844:	00000713          	li	a4,0
    5848:	0100006f          	j	5858 <feat_probe+0x15c>
    g_feat_attr = (g_feat_clip && g_feat_lut) ? 1 : 0;   /* 见文件头 (d) */
    584c:	00100693          	li	a3,1
    5850:	fe5ff06f          	j	5834 <feat_probe+0x138>
    g_attr_on   = (g_feat_attr && g_attr_user) ? 1 : 0;
    5854:	00000713          	li	a4,0
    5858:	92e1ac23          	sw	a4,-1736(gp) # 7960 <g_attr_on>
    bsp_printf("feat: clip=%d lut=%d attr=%d (attr off => per-command default path)\r\n",
    585c:	9501a603          	lw	a2,-1712(gp) # 7978 <g_feat_lut>
    5860:	00007537          	lui	a0,0x7
    5864:	a9c50513          	addi	a0,a0,-1380 # 6a9c <_data+0xae8>
    5868:	84dfe0ef          	jal	40b4 <bsp_printf>
    if (!g_feat_clip)
    586c:	9541a783          	lw	a5,-1708(gp) # 797c <g_feat_clip>
    5870:	04078663          	beqz	a5,58bc <feat_probe+0x1c0>
    if (!g_feat_lut)
    5874:	9501a783          	lw	a5,-1712(gp) # 7978 <g_feat_lut>
    5878:	04078a63          	beqz	a5,58cc <feat_probe+0x1d0>
    if (!g_feat_attr)
    587c:	94c1a783          	lw	a5,-1716(gp) # 7974 <g_feat_attr>
    5880:	04078e63          	beqz	a5,58dc <feat_probe+0x1e0>
    bsp_printf("feat: LUT_STAT bank=%d (disp; write target = the other bank)\r\n", (int)g_lut_disp);
    5884:	9341a583          	lw	a1,-1740(gp) # 795c <g_lut_disp>
    5888:	00007537          	lui	a0,0x7
    588c:	be850513          	addi	a0,a0,-1048 # 6be8 <_data+0xc34>
    5890:	825fe0ef          	jal	40b4 <bsp_printf>
    lut_bank_calib();                               /* ★ 实测发布极性 + 两个 bank 灌恒等表 */
    5894:	ad5fe0ef          	jal	4368 <lut_bank_calib>
    lut_state_line("state");                        /* ★ 上板可直接读的 LUT 状态行 */
    5898:	00007537          	lui	a0,0x7
    589c:	c2850513          	addi	a0,a0,-984 # 6c28 <_data+0xc74>
    58a0:	dadff0ef          	jal	564c <lut_state_line>
}
    58a4:	00c12083          	lw	ra,12(sp)
    58a8:	00812403          	lw	s0,8(sp)
    58ac:	01010113          	addi	sp,sp,16
    58b0:	00008067          	ret
    g_attr_on   = (g_feat_attr && g_attr_user) ? 1 : 0;
    58b4:	00068713          	mv	a4,a3
    58b8:	fa1ff06f          	j	5858 <feat_probe+0x15c>
        bsp_printf("feat WARN: CLIP_* readback failed -> scissor disabled (scene 3 = full-screen playfield)\r\n");
    58bc:	00007537          	lui	a0,0x7
    58c0:	ae450513          	addi	a0,a0,-1308 # 6ae4 <_data+0xb30>
    58c4:	ff0fe0ef          	jal	40b4 <bsp_printf>
    58c8:	fadff06f          	j	5874 <feat_probe+0x178>
        bsp_printf("feat WARN: LUT_* readback failed -> fade/flash disabled (needs the next P&R)\r\n");
    58cc:	00007537          	lui	a0,0x7
    58d0:	b4050513          	addi	a0,a0,-1216 # 6b40 <_data+0xb8c>
    58d4:	fe0fe0ef          	jal	40b4 <bsp_printf>
    58d8:	fa5ff06f          	j	587c <feat_probe+0x180>
        bsp_printf("feat WARN: attribute side-port assumed ABSENT -> RGB565 + per-command alpha fallback\r\n");
    58dc:	00007537          	lui	a0,0x7
    58e0:	b9050513          	addi	a0,a0,-1136 # 6b90 <_data+0xbdc>
    58e4:	fd0fe0ef          	jal	40b4 <bsp_printf>
    58e8:	f9dff06f          	j	5884 <feat_probe+0x188>

000058ec <ev_diag_line>:
{
    58ec:	fc010113          	addi	sp,sp,-64
    58f0:	02112e23          	sw	ra,60(sp)
    58f4:	02812c23          	sw	s0,56(sp)
    58f8:	02912a23          	sw	s1,52(sp)
    58fc:	03212823          	sw	s2,48(sp)
    5900:	03312623          	sw	s3,44(sp)
    uint32_t scan = blt_rd(BLT_SCAN_DBG);      /* 0x20：{abort[31:16], underrun[15:0]}，现读 */
    5904:	02000513          	li	a0,32
    5908:	f0dfc0ef          	jal	2814 <blt_rd>
    590c:	00050413          	mv	s0,a0
    uint32_t stat = blt_stat();                /* 0x04：引擎状态，现读 */
    5910:	9f4fd0ef          	jal	2b04 <blt_stat>
    5914:	00050493          	mv	s1,a0
    uint32_t clip = blt_rd(BLT_CLIP_CTRL);     /* 0xA0：裁剪使能（回读 = 实机状态） */
    5918:	0a000513          	li	a0,160
    591c:	ef9fc0ef          	jal	2814 <blt_rd>
    5920:	00050913          	mv	s2,a0
    uint32_t lctl = blt_rd(BLT_LUT_CTRL);      /* 0xAC：LUT 使能 + 写 bank */
    5924:	0ac00513          	li	a0,172
    5928:	eedfc0ef          	jal	2814 <blt_rd>
    592c:	00050993          	mv	s3,a0
    uint32_t lst  = blt_rd(BLT_LUT_STAT);      /* 0xB0：正在显示的 bank */
    5930:	0b000513          	li	a0,176
    5934:	ee1fc0ef          	jal	2814 <blt_rd>
    bsp_printf("EV diag: fps=%d n=%d sz=%d scn=%x ab=%d un=%d st=%x clip=%x lut=%x lbank=%x stto=%d flp=%d flpt=%d\r\n",
    5938:	86c1a783          	lw	a5,-1940(gp) # 7894 <g_flip_bad>
    593c:	00f12a23          	sw	a5,20(sp)
    5940:	8701a783          	lw	a5,-1936(gp) # 7898 <g_flip_ok>
    5944:	00f12823          	sw	a5,16(sp)
    5948:	87c1a783          	lw	a5,-1924(gp) # 78a4 <g_st_to>
    594c:	00f12623          	sw	a5,12(sp)
    5950:	00a12423          	sw	a0,8(sp)
    5954:	01312223          	sw	s3,4(sp)
    5958:	01212023          	sw	s2,0(sp)
    595c:	00048893          	mv	a7,s1
    5960:	01041813          	slli	a6,s0,0x10
    5964:	01085813          	srli	a6,a6,0x10
    5968:	01045793          	srli	a5,s0,0x10
    596c:	00040713          	mv	a4,s0
    5970:	85c1a683          	lw	a3,-1956(gp) # 7884 <g_blk>
    5974:	8301a603          	lw	a2,-2000(gp) # 7858 <g_n>
    5978:	9101a583          	lw	a1,-1776(gp) # 7938 <g_fps>
    597c:	00007537          	lui	a0,0x7
    5980:	c3050513          	addi	a0,a0,-976 # 6c30 <_data+0xc7c>
    5984:	f30fe0ef          	jal	40b4 <bsp_printf>
}
    5988:	03c12083          	lw	ra,60(sp)
    598c:	03812403          	lw	s0,56(sp)
    5990:	03412483          	lw	s1,52(sp)
    5994:	03012903          	lw	s2,48(sp)
    5998:	02c12983          	lw	s3,44(sp)
    599c:	04010113          	addi	sp,sp,64
    59a0:	00008067          	ret

000059a4 <clip_off_verified>:
    if (!g_feat_clip) { g_clip_on = 0; return 0; }
    59a4:	9541a503          	lw	a0,-1708(gp) # 797c <g_feat_clip>
    59a8:	00051663          	bnez	a0,59b4 <clip_off_verified+0x10>
    59ac:	9401a223          	sw	zero,-1724(gp) # 796c <g_clip_on>
}
    59b0:	00008067          	ret
{
    59b4:	ff010113          	addi	sp,sp,-16
    59b8:	00112623          	sw	ra,12(sp)
    clip_off();
    59bc:	9fcfe0ef          	jal	3bb8 <clip_off>
    if (blt_rd(BLT_CLIP_CTRL) & BLT_CLIP_EN) {
    59c0:	0a000513          	li	a0,160
    59c4:	e51fc0ef          	jal	2814 <blt_rd>
    59c8:	00157513          	andi	a0,a0,1
    59cc:	00051a63          	bnez	a0,59e0 <clip_off_verified+0x3c>
    return 1;
    59d0:	00100513          	li	a0,1
}
    59d4:	00c12083          	lw	ra,12(sp)
    59d8:	01010113          	addi	sp,sp,16
    59dc:	00008067          	ret
        g_clip_on = 0; g_scis_on = 0; g_clip_pass = 0;
    59e0:	9401a223          	sw	zero,-1724(gp) # 796c <g_clip_on>
    59e4:	8401a623          	sw	zero,-1972(gp) # 7874 <g_scis_on>
    59e8:	9401a423          	sw	zero,-1720(gp) # 7970 <g_clip_pass>
        g_clip_viol++;
    59ec:	9401a783          	lw	a5,-1728(gp) # 7968 <g_clip_viol>
    59f0:	00178793          	addi	a5,a5,1
    59f4:	94f1a023          	sw	a5,-1728(gp) # 7968 <g_clip_viol>
        if (!g_clip_warn) {
    59f8:	93c1a783          	lw	a5,-1732(gp) # 7964 <g_clip_warn>
    59fc:	00078663          	beqz	a5,5a08 <clip_off_verified+0x64>
        return 0;
    5a00:	00000513          	li	a0,0
    5a04:	fd1ff06f          	j	59d4 <clip_off_verified+0x30>
            g_clip_warn = 1;
    5a08:	00100713          	li	a4,1
    5a0c:	92e1ae23          	sw	a4,-1732(gp) # 7964 <g_clip_warn>
            bsp_printf("EV clip WARN: CLIP_CTRL readback still enabled -> scissor disabled\r\n");
    5a10:	00007537          	lui	a0,0x7
    5a14:	c9850513          	addi	a0,a0,-872 # 6c98 <_data+0xce4>
    5a18:	e9cfe0ef          	jal	40b4 <bsp_printf>
    5a1c:	fe5ff06f          	j	5a00 <clip_off_verified+0x5c>

00005a20 <blt_recover>:
{
    5a20:	fe010113          	addi	sp,sp,-32
    5a24:	00112e23          	sw	ra,28(sp)
    5a28:	00912a23          	sw	s1,20(sp)
    5a2c:	01212823          	sw	s2,16(sp)
    5a30:	00050913          	mv	s2,a0
    5a34:	00058493          	mv	s1,a1
    uint32_t st = blt_stat();
    5a38:	8ccfd0ef          	jal	2b04 <blt_stat>
    g_st_to++;
    5a3c:	87c1a783          	lw	a5,-1924(gp) # 78a4 <g_st_to>
    5a40:	00178793          	addi	a5,a5,1
    5a44:	86f1ae23          	sw	a5,-1924(gp) # 78a4 <g_st_to>
    if (g_st_warn < 4) {
    5a48:	8781a783          	lw	a5,-1928(gp) # 78a0 <g_st_warn>
    5a4c:	00300713          	li	a4,3
    5a50:	06f75463          	bge	a4,a5,5ab8 <blt_recover+0x98>
    blt_init();                     /* 软复位 + GO：停机 ERROR 与 FIFO 一起清 */
    5a54:	8f8fd0ef          	jal	2b4c <blt_init>
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);   /* ★ 软复位会关帧中断 ⇒ 重新打开 */
    5a58:	01400513          	li	a0,20
    5a5c:	db9fc0ef          	jal	2814 <blt_rd>
    5a60:	00256593          	ori	a1,a0,2
    5a64:	01400513          	li	a0,20
    5a68:	d9dfc0ef          	jal	2804 <blt_wr>
    clip_forget();                  /* CLIP_* 被打回复位值 ⇒ 镜像一起忘掉 */
    5a6c:	978fe0ef          	jal	3be4 <clip_forget>
    g_clip_pass  = 0;
    5a70:	9401a423          	sw	zero,-1720(gp) # 7970 <g_clip_pass>
    g_pass_armed = 0;
    5a74:	9601a423          	sw	zero,-1688(gp) # 7990 <g_pass_armed>
    g_repaint    = 1;
    5a78:	00100713          	li	a4,1
    5a7c:	82e1a023          	sw	a4,-2016(gp) # 7848 <g_repaint>
    hw_i = 0; hw_frame_pushed = 0;
    5a80:	8a01a023          	sw	zero,-1888(gp) # 78c8 <hw_i>
    5a84:	8801ae23          	sw	zero,-1892(gp) # 78c4 <hw_frame_pushed>
    g_decor_st = DEC_REPAINT; g_decor_i = 0;
    5a88:	8a01aa23          	sw	zero,-1868(gp) # 78dc <g_decor_st>
    5a8c:	8a01a823          	sw	zero,-1872(gp) # 78d8 <g_decor_i>
    g_st = ST_RESTART;
    5a90:	8a01ac23          	sw	zero,-1864(gp) # 78e0 <g_st>
    g_st_which = -1;
    5a94:	fff00713          	li	a4,-1
    5a98:	80e1ae23          	sw	a4,-2020(gp) # 7844 <g_st_which>
    g_st_t0 = tick32();
    5a9c:	d4dfc0ef          	jal	27e8 <tick32>
    5aa0:	88a1a023          	sw	a0,-1920(gp) # 78a8 <g_st_t0>
}
    5aa4:	01c12083          	lw	ra,28(sp)
    5aa8:	01412483          	lw	s1,20(sp)
    5aac:	01012903          	lw	s2,16(sp)
    5ab0:	02010113          	addi	sp,sp,32
    5ab4:	00008067          	ret
    5ab8:	00812c23          	sw	s0,24(sp)
    5abc:	01312623          	sw	s3,12(sp)
    5ac0:	00050413          	mv	s0,a0
        g_st_warn++;
    5ac4:	00178793          	addi	a5,a5,1
    5ac8:	86f1ac23          	sw	a5,-1928(gp) # 78a0 <g_st_warn>
                   why, which, (unsigned)st, (int)blt_cnt(), (unsigned)clr_stat());
    5acc:	81cfd0ef          	jal	2ae8 <blt_cnt>
    5ad0:	00050993          	mv	s3,a0
    5ad4:	d99fc0ef          	jal	286c <clr_stat>
    5ad8:	00050793          	mv	a5,a0
        bsp_printf("\r\nEV st timeout: %s st=%d STATUS=%x COUNT=%d CLR=%x -> engine soft reset\r\n",
    5adc:	00098713          	mv	a4,s3
    5ae0:	00040693          	mv	a3,s0
    5ae4:	00048613          	mv	a2,s1
    5ae8:	00090593          	mv	a1,s2
    5aec:	00007537          	lui	a0,0x7
    5af0:	ce050513          	addi	a0,a0,-800 # 6ce0 <_data+0xd2c>
    5af4:	dc0fe0ef          	jal	40b4 <bsp_printf>
    5af8:	01812403          	lw	s0,24(sp)
    5afc:	00c12983          	lw	s3,12(sp)
    5b00:	f55ff06f          	j	5a54 <blt_recover+0x34>

00005b04 <__udivdi3>:
    5b04:	00060813          	mv	a6,a2
    5b08:	00050893          	mv	a7,a0
    5b0c:	00058713          	mv	a4,a1
    5b10:	0e069063          	bnez	a3,5bf0 <__udivdi3+0xec>
    5b14:	12c5fe63          	bgeu	a1,a2,5c50 <__udivdi3+0x14c>
    5b18:	000107b7          	lui	a5,0x10
    5b1c:	1ef66e63          	bltu	a2,a5,5d18 <__udivdi3+0x214>
    5b20:	010007b7          	lui	a5,0x1000
    5b24:	01800693          	li	a3,24
    5b28:	00f67463          	bgeu	a2,a5,5b30 <__udivdi3+0x2c>
    5b2c:	01000693          	li	a3,16
    5b30:	00d65333          	srl	t1,a2,a3
    5b34:	00002797          	auipc	a5,0x2
    5b38:	c0478793          	addi	a5,a5,-1020 # 7738 <__clz_tab>
    5b3c:	006787b3          	add	a5,a5,t1
    5b40:	0007c783          	lbu	a5,0(a5)
    5b44:	02000313          	li	t1,32
    5b48:	00d787b3          	add	a5,a5,a3
    5b4c:	40f306b3          	sub	a3,t1,a5
    5b50:	00f30c63          	beq	t1,a5,5b68 <__udivdi3+0x64>
    5b54:	00d59733          	sll	a4,a1,a3
    5b58:	00f557b3          	srl	a5,a0,a5
    5b5c:	00d61833          	sll	a6,a2,a3
    5b60:	00e7e733          	or	a4,a5,a4
    5b64:	00d518b3          	sll	a7,a0,a3
    5b68:	01085613          	srli	a2,a6,0x10
    5b6c:	02c75533          	divu	a0,a4,a2
    5b70:	01081693          	slli	a3,a6,0x10
    5b74:	0106d693          	srli	a3,a3,0x10
    5b78:	0108d793          	srli	a5,a7,0x10
    5b7c:	02c77733          	remu	a4,a4,a2
    5b80:	02a685b3          	mul	a1,a3,a0
    5b84:	01071713          	slli	a4,a4,0x10
    5b88:	00e7e7b3          	or	a5,a5,a4
    5b8c:	00b7fc63          	bgeu	a5,a1,5ba4 <__udivdi3+0xa0>
    5b90:	00f807b3          	add	a5,a6,a5
    5b94:	fff50713          	addi	a4,a0,-1
    5b98:	0107e463          	bltu	a5,a6,5ba0 <__udivdi3+0x9c>
    5b9c:	40b7e063          	bltu	a5,a1,5f9c <__udivdi3+0x498>
    5ba0:	00070513          	mv	a0,a4
    5ba4:	40b787b3          	sub	a5,a5,a1
    5ba8:	02c7d733          	divu	a4,a5,a2
    5bac:	01089893          	slli	a7,a7,0x10
    5bb0:	0108d893          	srli	a7,a7,0x10
    5bb4:	02c7f7b3          	remu	a5,a5,a2
    5bb8:	02e686b3          	mul	a3,a3,a4
    5bbc:	01079793          	slli	a5,a5,0x10
    5bc0:	00f8e8b3          	or	a7,a7,a5
    5bc4:	00d8fe63          	bgeu	a7,a3,5be0 <__udivdi3+0xdc>
    5bc8:	011808b3          	add	a7,a6,a7
    5bcc:	fff70793          	addi	a5,a4,-1
    5bd0:	0108e663          	bltu	a7,a6,5bdc <__udivdi3+0xd8>
    5bd4:	ffe70713          	addi	a4,a4,-2
    5bd8:	00d8e463          	bltu	a7,a3,5be0 <__udivdi3+0xdc>
    5bdc:	00078713          	mv	a4,a5
    5be0:	01051513          	slli	a0,a0,0x10
    5be4:	00e56533          	or	a0,a0,a4
    5be8:	00000593          	li	a1,0
    5bec:	00008067          	ret
    5bf0:	00d5f863          	bgeu	a1,a3,5c00 <__udivdi3+0xfc>
    5bf4:	00000593          	li	a1,0
    5bf8:	00000513          	li	a0,0
    5bfc:	00008067          	ret
    5c00:	000107b7          	lui	a5,0x10
    5c04:	1ef6e863          	bltu	a3,a5,5df4 <__udivdi3+0x2f0>
    5c08:	01000737          	lui	a4,0x1000
    5c0c:	01800793          	li	a5,24
    5c10:	00e6f463          	bgeu	a3,a4,5c18 <__udivdi3+0x114>
    5c14:	01000793          	li	a5,16
    5c18:	00f6d833          	srl	a6,a3,a5
    5c1c:	00002717          	auipc	a4,0x2
    5c20:	b1c70713          	addi	a4,a4,-1252 # 7738 <__clz_tab>
    5c24:	01070733          	add	a4,a4,a6
    5c28:	00074703          	lbu	a4,0(a4)
    5c2c:	02000893          	li	a7,32
    5c30:	00f70733          	add	a4,a4,a5
    5c34:	40e88833          	sub	a6,a7,a4
    5c38:	1ee89663          	bne	a7,a4,5e24 <__udivdi3+0x320>
    5c3c:	32b6e463          	bltu	a3,a1,5f64 <__udivdi3+0x460>
    5c40:	00c53533          	sltu	a0,a0,a2
    5c44:	00153513          	seqz	a0,a0
    5c48:	00000593          	li	a1,0
    5c4c:	00008067          	ret
    5c50:	0c060c63          	beqz	a2,5d28 <__udivdi3+0x224>
    5c54:	000107b7          	lui	a5,0x10
    5c58:	2ef67c63          	bgeu	a2,a5,5f50 <__udivdi3+0x44c>
    5c5c:	10063713          	sltiu	a4,a2,256
    5c60:	00173713          	seqz	a4,a4
    5c64:	00371713          	slli	a4,a4,0x3
    5c68:	00e656b3          	srl	a3,a2,a4
    5c6c:	00002797          	auipc	a5,0x2
    5c70:	acc78793          	addi	a5,a5,-1332 # 7738 <__clz_tab>
    5c74:	00d787b3          	add	a5,a5,a3
    5c78:	0007c783          	lbu	a5,0(a5)
    5c7c:	02000693          	li	a3,32
    5c80:	00e787b3          	add	a5,a5,a4
    5c84:	40f68eb3          	sub	t4,a3,a5
    5c88:	0cf69463          	bne	a3,a5,5d50 <__udivdi3+0x24c>
    5c8c:	40c587b3          	sub	a5,a1,a2
    5c90:	01065693          	srli	a3,a2,0x10
    5c94:	01061613          	slli	a2,a2,0x10
    5c98:	01065613          	srli	a2,a2,0x10
    5c9c:	00100593          	li	a1,1
    5ca0:	02d7d533          	divu	a0,a5,a3
    5ca4:	0108d713          	srli	a4,a7,0x10
    5ca8:	02d7f7b3          	remu	a5,a5,a3
    5cac:	02c50333          	mul	t1,a0,a2
    5cb0:	01079793          	slli	a5,a5,0x10
    5cb4:	00f767b3          	or	a5,a4,a5
    5cb8:	0067fc63          	bgeu	a5,t1,5cd0 <__udivdi3+0x1cc>
    5cbc:	00f807b3          	add	a5,a6,a5
    5cc0:	fff50713          	addi	a4,a0,-1
    5cc4:	0107e463          	bltu	a5,a6,5ccc <__udivdi3+0x1c8>
    5cc8:	2c67e463          	bltu	a5,t1,5f90 <__udivdi3+0x48c>
    5ccc:	00070513          	mv	a0,a4
    5cd0:	406787b3          	sub	a5,a5,t1
    5cd4:	02d7d733          	divu	a4,a5,a3
    5cd8:	01089893          	slli	a7,a7,0x10
    5cdc:	0108d893          	srli	a7,a7,0x10
    5ce0:	02d7f7b3          	remu	a5,a5,a3
    5ce4:	02c70633          	mul	a2,a4,a2
    5ce8:	01079793          	slli	a5,a5,0x10
    5cec:	00f8e8b3          	or	a7,a7,a5
    5cf0:	00c8fe63          	bgeu	a7,a2,5d0c <__udivdi3+0x208>
    5cf4:	011808b3          	add	a7,a6,a7
    5cf8:	fff70793          	addi	a5,a4,-1
    5cfc:	0108e663          	bltu	a7,a6,5d08 <__udivdi3+0x204>
    5d00:	ffe70713          	addi	a4,a4,-2
    5d04:	00c8e463          	bltu	a7,a2,5d0c <__udivdi3+0x208>
    5d08:	00078713          	mv	a4,a5
    5d0c:	01051513          	slli	a0,a0,0x10
    5d10:	00e56533          	or	a0,a0,a4
    5d14:	00008067          	ret
    5d18:	10063693          	sltiu	a3,a2,256
    5d1c:	0016b693          	seqz	a3,a3
    5d20:	00369693          	slli	a3,a3,0x3
    5d24:	e0dff06f          	j	5b30 <__udivdi3+0x2c>
    5d28:	00000693          	li	a3,0
    5d2c:	00002797          	auipc	a5,0x2
    5d30:	a0c78793          	addi	a5,a5,-1524 # 7738 <__clz_tab>
    5d34:	00d787b3          	add	a5,a5,a3
    5d38:	0007c783          	lbu	a5,0(a5)
    5d3c:	00000713          	li	a4,0
    5d40:	02000693          	li	a3,32
    5d44:	00e787b3          	add	a5,a5,a4
    5d48:	40f68eb3          	sub	t4,a3,a5
    5d4c:	f4f680e3          	beq	a3,a5,5c8c <__udivdi3+0x188>
    5d50:	01d61833          	sll	a6,a2,t4
    5d54:	00f5d333          	srl	t1,a1,a5
    5d58:	01085693          	srli	a3,a6,0x10
    5d5c:	02d35e33          	divu	t3,t1,a3
    5d60:	01081613          	slli	a2,a6,0x10
    5d64:	01d595b3          	sll	a1,a1,t4
    5d68:	01065613          	srli	a2,a2,0x10
    5d6c:	00f557b3          	srl	a5,a0,a5
    5d70:	00b7e7b3          	or	a5,a5,a1
    5d74:	0107d713          	srli	a4,a5,0x10
    5d78:	01d518b3          	sll	a7,a0,t4
    5d7c:	02d37333          	remu	t1,t1,a3
    5d80:	03c605b3          	mul	a1,a2,t3
    5d84:	01031313          	slli	t1,t1,0x10
    5d88:	00676733          	or	a4,a4,t1
    5d8c:	00b77e63          	bgeu	a4,a1,5da8 <__udivdi3+0x2a4>
    5d90:	00e80733          	add	a4,a6,a4
    5d94:	fffe0513          	addi	a0,t3,-1
    5d98:	1f076463          	bltu	a4,a6,5f80 <__udivdi3+0x47c>
    5d9c:	1eb77263          	bgeu	a4,a1,5f80 <__udivdi3+0x47c>
    5da0:	ffee0e13          	addi	t3,t3,-2
    5da4:	01070733          	add	a4,a4,a6
    5da8:	40b70733          	sub	a4,a4,a1
    5dac:	02d75533          	divu	a0,a4,a3
    5db0:	01079793          	slli	a5,a5,0x10
    5db4:	0107d793          	srli	a5,a5,0x10
    5db8:	02d77733          	remu	a4,a4,a3
    5dbc:	02a60333          	mul	t1,a2,a0
    5dc0:	01071713          	slli	a4,a4,0x10
    5dc4:	00e7e7b3          	or	a5,a5,a4
    5dc8:	0067fe63          	bgeu	a5,t1,5de4 <__udivdi3+0x2e0>
    5dcc:	00f807b3          	add	a5,a6,a5
    5dd0:	fff50713          	addi	a4,a0,-1
    5dd4:	1907ee63          	bltu	a5,a6,5f70 <__udivdi3+0x46c>
    5dd8:	1867fc63          	bgeu	a5,t1,5f70 <__udivdi3+0x46c>
    5ddc:	ffe50513          	addi	a0,a0,-2
    5de0:	010787b3          	add	a5,a5,a6
    5de4:	010e1593          	slli	a1,t3,0x10
    5de8:	406787b3          	sub	a5,a5,t1
    5dec:	00a5e5b3          	or	a1,a1,a0
    5df0:	eb1ff06f          	j	5ca0 <__udivdi3+0x19c>
    5df4:	1006b793          	sltiu	a5,a3,256
    5df8:	0017b793          	seqz	a5,a5
    5dfc:	00379793          	slli	a5,a5,0x3
    5e00:	00f6d833          	srl	a6,a3,a5
    5e04:	00002717          	auipc	a4,0x2
    5e08:	93470713          	addi	a4,a4,-1740 # 7738 <__clz_tab>
    5e0c:	01070733          	add	a4,a4,a6
    5e10:	00074703          	lbu	a4,0(a4)
    5e14:	02000893          	li	a7,32
    5e18:	00f70733          	add	a4,a4,a5
    5e1c:	40e88833          	sub	a6,a7,a4
    5e20:	e0e88ee3          	beq	a7,a4,5c3c <__udivdi3+0x138>
    5e24:	00e65e33          	srl	t3,a2,a4
    5e28:	010696b3          	sll	a3,a3,a6
    5e2c:	00de6e33          	or	t3,t3,a3
    5e30:	00e5d8b3          	srl	a7,a1,a4
    5e34:	010e5e93          	srli	t4,t3,0x10
    5e38:	03d8d7b3          	divu	a5,a7,t4
    5e3c:	010e1313          	slli	t1,t3,0x10
    5e40:	010595b3          	sll	a1,a1,a6
    5e44:	01035313          	srli	t1,t1,0x10
    5e48:	00e55733          	srl	a4,a0,a4
    5e4c:	00b76733          	or	a4,a4,a1
    5e50:	01075693          	srli	a3,a4,0x10
    5e54:	01061633          	sll	a2,a2,a6
    5e58:	03d8f8b3          	remu	a7,a7,t4
    5e5c:	02f305b3          	mul	a1,t1,a5
    5e60:	01089893          	slli	a7,a7,0x10
    5e64:	0116e6b3          	or	a3,a3,a7
    5e68:	00b6fe63          	bgeu	a3,a1,5e84 <__udivdi3+0x380>
    5e6c:	00de06b3          	add	a3,t3,a3
    5e70:	fff78893          	addi	a7,a5,-1
    5e74:	11c6ea63          	bltu	a3,t3,5f88 <__udivdi3+0x484>
    5e78:	10b6f863          	bgeu	a3,a1,5f88 <__udivdi3+0x484>
    5e7c:	ffe78793          	addi	a5,a5,-2
    5e80:	01c686b3          	add	a3,a3,t3
    5e84:	40b686b3          	sub	a3,a3,a1
    5e88:	03d6d5b3          	divu	a1,a3,t4
    5e8c:	01071713          	slli	a4,a4,0x10
    5e90:	01075713          	srli	a4,a4,0x10
    5e94:	03d6f6b3          	remu	a3,a3,t4
    5e98:	02b308b3          	mul	a7,t1,a1
    5e9c:	01069693          	slli	a3,a3,0x10
    5ea0:	00d76733          	or	a4,a4,a3
    5ea4:	01177e63          	bgeu	a4,a7,5ec0 <__udivdi3+0x3bc>
    5ea8:	00ee0733          	add	a4,t3,a4
    5eac:	fff58693          	addi	a3,a1,-1
    5eb0:	0dc76463          	bltu	a4,t3,5f78 <__udivdi3+0x474>
    5eb4:	0d177263          	bgeu	a4,a7,5f78 <__udivdi3+0x474>
    5eb8:	ffe58593          	addi	a1,a1,-2
    5ebc:	01c70733          	add	a4,a4,t3
    5ec0:	01079793          	slli	a5,a5,0x10
    5ec4:	00010eb7          	lui	t4,0x10
    5ec8:	00b7e7b3          	or	a5,a5,a1
    5ecc:	fffe8693          	addi	a3,t4,-1 # ffff <__global_pointer$+0x7fd7>
    5ed0:	00d7f5b3          	and	a1,a5,a3
    5ed4:	0107d313          	srli	t1,a5,0x10
    5ed8:	00d676b3          	and	a3,a2,a3
    5edc:	01065613          	srli	a2,a2,0x10
    5ee0:	02d58e33          	mul	t3,a1,a3
    5ee4:	41170733          	sub	a4,a4,a7
    5ee8:	02d306b3          	mul	a3,t1,a3
    5eec:	010e5893          	srli	a7,t3,0x10
    5ef0:	02c585b3          	mul	a1,a1,a2
    5ef4:	00d585b3          	add	a1,a1,a3
    5ef8:	00b885b3          	add	a1,a7,a1
    5efc:	02c30333          	mul	t1,t1,a2
    5f00:	00d5f463          	bgeu	a1,a3,5f08 <__udivdi3+0x404>
    5f04:	01d30333          	add	t1,t1,t4
    5f08:	0105d693          	srli	a3,a1,0x10
    5f0c:	006686b3          	add	a3,a3,t1
    5f10:	02d76a63          	bltu	a4,a3,5f44 <__udivdi3+0x440>
    5f14:	00d70863          	beq	a4,a3,5f24 <__udivdi3+0x420>
    5f18:	00078513          	mv	a0,a5
    5f1c:	00000593          	li	a1,0
    5f20:	00008067          	ret
    5f24:	000106b7          	lui	a3,0x10
    5f28:	fff68693          	addi	a3,a3,-1 # ffff <__global_pointer$+0x7fd7>
    5f2c:	00d5f733          	and	a4,a1,a3
    5f30:	01071713          	slli	a4,a4,0x10
    5f34:	00de7e33          	and	t3,t3,a3
    5f38:	01051533          	sll	a0,a0,a6
    5f3c:	01c70733          	add	a4,a4,t3
    5f40:	fce57ce3          	bgeu	a0,a4,5f18 <__udivdi3+0x414>
    5f44:	fff78513          	addi	a0,a5,-1
    5f48:	00000593          	li	a1,0
    5f4c:	00008067          	ret
    5f50:	010007b7          	lui	a5,0x1000
    5f54:	04f67a63          	bgeu	a2,a5,5fa8 <__udivdi3+0x4a4>
    5f58:	01065693          	srli	a3,a2,0x10
    5f5c:	01000713          	li	a4,16
    5f60:	d0dff06f          	j	5c6c <__udivdi3+0x168>
    5f64:	00000593          	li	a1,0
    5f68:	00100513          	li	a0,1
    5f6c:	00008067          	ret
    5f70:	00070513          	mv	a0,a4
    5f74:	e71ff06f          	j	5de4 <__udivdi3+0x2e0>
    5f78:	00068593          	mv	a1,a3
    5f7c:	f45ff06f          	j	5ec0 <__udivdi3+0x3bc>
    5f80:	00050e13          	mv	t3,a0
    5f84:	e25ff06f          	j	5da8 <__udivdi3+0x2a4>
    5f88:	00088793          	mv	a5,a7
    5f8c:	ef9ff06f          	j	5e84 <__udivdi3+0x380>
    5f90:	ffe50513          	addi	a0,a0,-2
    5f94:	010787b3          	add	a5,a5,a6
    5f98:	d39ff06f          	j	5cd0 <__udivdi3+0x1cc>
    5f9c:	ffe50513          	addi	a0,a0,-2
    5fa0:	010787b3          	add	a5,a5,a6
    5fa4:	c01ff06f          	j	5ba4 <__udivdi3+0xa0>
    5fa8:	01865693          	srli	a3,a2,0x18
    5fac:	01800713          	li	a4,24
    5fb0:	cbdff06f          	j	5c6c <__udivdi3+0x168>
