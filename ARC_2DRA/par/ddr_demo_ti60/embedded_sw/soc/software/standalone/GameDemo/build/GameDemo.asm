
build/GameDemo.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00007197          	auipc	gp,0x7
    1004:	0e818193          	addi	gp,gp,232 # 80e8 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	00018117          	auipc	sp,0x18
    100c:	1f810113          	addi	sp,sp,504 # 19200 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00005517          	auipc	a0,0x5
    1014:	4e850513          	addi	a0,a0,1256 # 64f8 <_data>
	la a1, _data
    1018:	00005597          	auipc	a1,0x5
    101c:	4e058593          	addi	a1,a1,1248 # 64f8 <_data>
	la a2, _edata
    1020:	00007617          	auipc	a2,0x7
    1024:	91c60613          	addi	a2,a2,-1764 # 793c <g_bul_live>
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
    1044:	8fc50513          	addi	a0,a0,-1796 # 793c <g_bul_live>
	la a1, _end
    1048:	00017597          	auipc	a1,0x17
    104c:	1b058593          	addi	a1,a1,432 # 181f8 <_end>
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
    1080:	47c78793          	addi	a5,a5,1148 # 64f8 <_data>
    1084:	00005417          	auipc	s0,0x5
    1088:	47440413          	addi	s0,s0,1140 # 64f8 <_data>
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
    10bc:	44078793          	addi	a5,a5,1088 # 64f8 <_data>
    10c0:	00005417          	auipc	s0,0x5
    10c4:	43840413          	addi	s0,s0,1080 # 64f8 <_data>
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
    g_dl_i = 0;
    g_clr_fb++;
}

int main(int argc, char **argv)
{
    1104:	fa010113          	addi	sp,sp,-96
    1108:	04112e23          	sw	ra,92(sp)
    110c:	04812c23          	sw	s0,88(sp)
    1110:	04912a23          	sw	s1,84(sp)
    1114:	05212823          	sw	s2,80(sp)
    1118:	05312623          	sw	s3,76(sp)
    111c:	05412423          	sw	s4,72(sp)
    1120:	05512223          	sw	s5,68(sp)
    1124:	05612023          	sw	s6,64(sp)
    1128:	03712e23          	sw	s7,60(sp)
    112c:	03812c23          	sw	s8,56(sp)
    1130:	03912a23          	sw	s9,52(sp)
    1134:	03a12823          	sw	s10,48(sp)
    1138:	03b12623          	sw	s11,44(sp)
    uint32_t back_t0 = 0;
    int      repaint = 1;

    (void)argc; (void)argv;

    bsp_init();                       /* ★ 必须最先调用：UART 时钟分频在这里配置 */
    113c:	19d000ef          	jal	1ad8 <bsp_init>

    bsp_printf("\r\n===== GameDemo: high-load interactive danmaku, serial-controlled =====\r\n");
    1140:	00007537          	lui	a0,0x7
    1144:	ff450513          	addi	a0,a0,-12 # 6ff4 <_data+0xafc>
    1148:	600030ef          	jal	4748 <bsp_printf>
    bsp_printf("FB=%x BACK=%x BUF2=%x ATLAS=%x bytes=%d\r\n",
    114c:	000027b7          	lui	a5,0x2
    1150:	c0078793          	addi	a5,a5,-1024 # 1c00 <spr_player+0x44>
    1154:	00201737          	lui	a4,0x201
    1158:	007016b7          	lui	a3,0x701
    115c:	00501637          	lui	a2,0x501
    1160:	003015b7          	lui	a1,0x301
    1164:	00007537          	lui	a0,0x7
    1168:	04050513          	addi	a0,a0,64 # 7040 <_data+0xb48>
    116c:	5dc030ef          	jal	4748 <bsp_printf>
               (unsigned)FB_BASE, (unsigned)FB_BACK, (unsigned)FB_BUF2,
               (unsigned)ATLAS_BASE, (int)ATLAS_BYTES);
    bsp_printf("playfield: x 0..%d  y %d..%d (info bar y<16 is CPU text)\r\n",
    1170:	21c00693          	li	a3,540
    1174:	01000613          	li	a2,16
    1178:	3c000593          	li	a1,960
    117c:	00007537          	lui	a0,0x7
    1180:	06c50513          	addi	a0,a0,108 # 706c <_data+0xb74>
    1184:	5c4030ef          	jal	4748 <bsp_printf>
               FB_WIDTH, PLAY_Y0, PLAY_Y1);
    bsp_printf("publish: FLIP x3 (no full-screen COPY) + concurrent clear engine\r\n");
    1188:	00007537          	lui	a0,0x7
    118c:	0a850513          	addi	a0,a0,168 # 70a8 <_data+0xbb0>
    1190:	5b8030ef          	jal	4748 <bsp_printf>
    bsp_printf("default: N=%d path=HW stars=%d sprites 16x16 glow + 32x32 keyed\r\n",
    1194:	8241a603          	lw	a2,-2012(gp) # 790c <g_star_n>
    1198:	81c1a583          	lw	a1,-2020(gp) # 7904 <g_ncap>
    119c:	00007537          	lui	a0,0x7
    11a0:	0ec50513          	addi	a0,a0,236 # 70ec <_data+0xbf4>
    11a4:	5a4030ef          	jal	4748 <bsp_printf>
               g_ncap, g_star_n);
    bsp_printf("input: PC keyboard over UART 115200 -> '@'+2 hex digits+'\\n'\r\n");
    11a8:	00007537          	lui	a0,0x7
    11ac:	13050513          	addi	a0,a0,304 # 7130 <_data+0xc38>
    11b0:	598030ef          	jal	4748 <bsp_printf>
    bsp_printf("       bit0 up 1 down 2 left 3 right 4 fire 5 focus 6 bomb 7 pause\r\n");
    11b4:	00007537          	lui	a0,0x7
    11b8:	17050513          	addi	a0,a0,368 # 7170 <_data+0xc78>
    11bc:	58c030ef          	jal	4748 <bsp_printf>
    bsp_printf("cmd: 1/2/3/4 presets, n/+/-/=N, c=CPU h=HW, g=auto-ramp, b, p, r, d, ?\r\n");
    11c0:	00007537          	lui	a0,0x7
    11c4:	1b850513          	addi	a0,a0,440 # 71b8 <_data+0xcc0>
    11c8:	580030ef          	jal	4748 <bsp_printf>
    bsp_printf("     f=cycle enemy-bullet op FILL/ALPHA/ADD/KEY (also 5/6/7/8)\r\n");
    11cc:	00007537          	lui	a0,0x7
    11d0:	20450513          	addi	a0,a0,516 # 7204 <_data+0xd0c>
    11d4:	574030ef          	jal	4748 <bsp_printf>

    /* ---- 图集：开机由 CPU 生成（引擎与 CPU 参考实现都从这里取数） ---- */
    {
        int id, i, j;
        for (id = 0; id < S_N; id++) {
    11d8:	00000a13          	li	s4,0
    11dc:	0440006f          	j	1220 <main+0x11c>
            volatile uint16_t *p = (volatile uint16_t *)(ATLAS_BASE + g_spr_off[id]);
            int w = (int)g_spr_sz[id];
            for (j = 0; j < w; j++)
                for (i = 0; i < w; i++)
                    p[j * w + i] = spr_pixel(id, i, j);
    11e0:	03390433          	mul	s0,s2,s3
    11e4:	00940433          	add	s0,s0,s1
    11e8:	00141413          	slli	s0,s0,0x1
    11ec:	008a8433          	add	s0,s5,s0
    11f0:	00090613          	mv	a2,s2
    11f4:	00048593          	mv	a1,s1
    11f8:	000a0513          	mv	a0,s4
    11fc:	3d5000ef          	jal	1dd0 <spr_pixel>
    1200:	00a41023          	sh	a0,0(s0)
                for (i = 0; i < w; i++)
    1204:	00148493          	addi	s1,s1,1
    1208:	fd34cce3          	blt	s1,s3,11e0 <main+0xdc>
            for (j = 0; j < w; j++)
    120c:	00190913          	addi	s2,s2,1
    1210:	01395663          	bge	s2,s3,121c <main+0x118>
                for (i = 0; i < w; i++)
    1214:	00000493          	li	s1,0
    1218:	ff1ff06f          	j	1208 <main+0x104>
        for (id = 0; id < S_N; id++) {
    121c:	001a0a13          	addi	s4,s4,1
    1220:	00700793          	li	a5,7
    1224:	0347ca63          	blt	a5,s4,1258 <main+0x154>
            volatile uint16_t *p = (volatile uint16_t *)(ATLAS_BASE + g_spr_off[id]);
    1228:	000077b7          	lui	a5,0x7
    122c:	002a1713          	slli	a4,s4,0x2
    1230:	7d478793          	addi	a5,a5,2004 # 77d4 <g_spr_off>
    1234:	00e787b3          	add	a5,a5,a4
    1238:	0007aa83          	lw	s5,0(a5)
    123c:	002017b7          	lui	a5,0x201
    1240:	00fa8ab3          	add	s5,s5,a5
            int w = (int)g_spr_sz[id];
    1244:	84018793          	addi	a5,gp,-1984 # 7928 <g_spr_sz>
    1248:	014787b3          	add	a5,a5,s4
    124c:	0007c983          	lbu	s3,0(a5) # 201000 <__freertos_irq_stack_top+0x1e7e00>
            for (j = 0; j < w; j++)
    1250:	00000913          	li	s2,0
    1254:	fbdff06f          	j	1210 <main+0x10c>
        }
    }
    cache_evict();
    1258:	55d000ef          	jal	1fb4 <cache_evict>

    /* ---- 引擎与位流能力 ---- */
    blt_init();
    125c:	250010ef          	jal	24ac <blt_init>
    feat_probe();
    1260:	618030ef          	jal	4878 <feat_probe>
    g_disp_sel = fb_stat_sel();                 /* 与实际在屏的缓冲对齐（重跑程序也安全） */
    1264:	531000ef          	jal	1f94 <fb_stat_sel>
    1268:	00050793          	mv	a5,a0
    126c:	8ea1a423          	sw	a0,-1816(gp) # 79d0 <g_disp_sel>
    g_draw3    = (int)((g_disp_sel + 1u) % 3u);
    1270:	00150513          	addi	a0,a0,1
    1274:	00300713          	li	a4,3
    1278:	02e57533          	remu	a0,a0,a4
    127c:	82a1a823          	sw	a0,-2000(gp) # 7918 <g_draw3>
    g_clr3     = (int)((g_disp_sel + 2u) % 3u);
    1280:	00278793          	addi	a5,a5,2
    1284:	02e7f7b3          	remu	a5,a5,a4
    1288:	82f1a623          	sw	a5,-2004(gp) # 7914 <g_clr3>
    g_clr_need = 1;
    128c:	00100713          	li	a4,1
    1290:	8ce1ae23          	sw	a4,-1828(gp) # 79c4 <g_clr_need>
    g_fb_back  = fb_of_sel((uint32_t)g_draw3);
    1294:	4d9000ef          	jal	1f6c <fb_of_sel>
    1298:	82a1aa23          	sw	a0,-1996(gp) # 791c <g_fb_back>

    /* ---- 三块缓冲各自铺一次底（此后背景由清屏引擎负责） ---- */
    stars_reset();
    129c:	274030ef          	jal	4510 <stars_reset>
    {
        int k;
        uint32_t sv = g_fb_back;
    12a0:	8341a483          	lw	s1,-1996(gp) # 791c <g_fb_back>
        for (k = 0; k < 3; k++) {
    12a4:	00000413          	li	s0,0
    12a8:	0380006f          	j	12e0 <main+0x1dc>
            g_fb_back = fb_of_sel((uint32_t)k);
    12ac:	00040513          	mv	a0,s0
    12b0:	4bd000ef          	jal	1f6c <fb_of_sel>
    12b4:	82a1aa23          	sw	a0,-1996(gp) # 791c <g_fb_back>
            cpu_fill32(g_fb_back, 0, 0, FB_WIDTH, FB_HEIGHT, COL_BG);
    12b8:	00800793          	li	a5,8
    12bc:	21c00713          	li	a4,540
    12c0:	3c000693          	li	a3,960
    12c4:	00000613          	li	a2,0
    12c8:	00000593          	li	a1,0
    12cc:	519000ef          	jal	1fe4 <cpu_fill32>
            g_bar_ok[k] = 0;
    12d0:	8d818793          	addi	a5,gp,-1832 # 79c0 <g_bar_ok>
    12d4:	00f407b3          	add	a5,s0,a5
    12d8:	00078023          	sb	zero,0(a5)
        for (k = 0; k < 3; k++) {
    12dc:	00140413          	addi	s0,s0,1
    12e0:	00200793          	li	a5,2
    12e4:	fc87d4e3          	bge	a5,s0,12ac <main+0x1a8>
        }
        g_fb_back = sv;
    12e8:	8291aa23          	sw	s1,-1996(gp) # 791c <g_fb_back>
    }
    g_flip_req = g_disp_sel;
    12ec:	8e81a703          	lw	a4,-1816(gp) # 79d0 <g_disp_sel>
    12f0:	8ee1a223          	sw	a4,-1820(gp) # 79cc <g_flip_req>
    cache_evict();
    12f4:	4c1000ef          	jal	1fb4 <cache_evict>
    bsp_printf("publish: FLIPx3 (disp=%d draw=%d clr=%d)\r\n",
    12f8:	82c1a683          	lw	a3,-2004(gp) # 7914 <g_clr3>
    12fc:	8301a603          	lw	a2,-2000(gp) # 7918 <g_draw3>
    1300:	8e81a583          	lw	a1,-1816(gp) # 79d0 <g_disp_sel>
    1304:	00007537          	lui	a0,0x7
    1308:	24850513          	addi	a0,a0,584 # 7248 <_data+0xd50>
    130c:	43c030ef          	jal	4748 <bsp_printf>
               (int)g_disp_sel, g_draw3, g_clr3);

    /* ---- 帧边界中断使能：翻转确认由扫描输出的场边界事件驱动（不依赖 trap） ---- */
    blt_wr(BLT_IRQ_EN, blt_rd(BLT_IRQ_EN) | BLT_IRQ_FRAME);
    1310:	01400513          	li	a0,20
    1314:	449000ef          	jal	1f5c <blt_rd>
    1318:	00256593          	ori	a1,a0,2
    131c:	01400513          	li	a0,20
    1320:	42d000ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME);
    1324:	00200593          	li	a1,2
    1328:	01000513          	li	a0,16
    132c:	421000ef          	jal	1f4c <blt_wr>

    /* ---- 开机自检：未对齐存储 / 精灵夹紧 / 属性字 / 定点混合 / 图集 / 信息条 / 帧预算 ---- */
    {
        uint16_t px0, px1;
        ent_t t;
        cpu_fill32(g_fb_back, 33, 500, 8, 2, 0xF800u);
    1330:	000107b7          	lui	a5,0x10
    1334:	80078793          	addi	a5,a5,-2048 # f800 <__global_pointer$+0x7718>
    1338:	00200713          	li	a4,2
    133c:	00800693          	li	a3,8
    1340:	1f400613          	li	a2,500
    1344:	02100593          	li	a1,33
    1348:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    134c:	499000ef          	jal	1fe4 <cpu_fill32>
        cpu_fill32(g_fb_back, 32, 502, 9, 2, 0x07E0u);
    1350:	7e000793          	li	a5,2016
    1354:	00200713          	li	a4,2
    1358:	00900693          	li	a3,9
    135c:	1f600613          	li	a2,502
    1360:	02000593          	li	a1,32
    1364:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    1368:	47d000ef          	jal	1fe4 <cpu_fill32>
        px0 = *(volatile uint16_t *)(g_fb_back + 500u * FB_STRIDE + 33u * 2u);
    136c:	8341a703          	lw	a4,-1996(gp) # 791c <g_fb_back>
    1370:	000ea7b7          	lui	a5,0xea
    1374:	64278793          	addi	a5,a5,1602 # ea642 <__freertos_irq_stack_top+0xd1442>
    1378:	00f707b3          	add	a5,a4,a5
    137c:	0007d583          	lhu	a1,0(a5)
        px1 = *(volatile uint16_t *)(g_fb_back + 502u * FB_STRIDE + 40u * 2u);
    1380:	000eb7b7          	lui	a5,0xeb
    1384:	55078793          	addi	a5,a5,1360 # eb550 <__freertos_irq_stack_top+0xd2350>
    1388:	00f70733          	add	a4,a4,a5
    138c:	00075603          	lhu	a2,0(a4) # 201000 <__freertos_irq_stack_top+0x1e7e00>
        bsp_printf("aligncheck %x %x (expect f800 07e0)\r\n", (unsigned)px0, (unsigned)px1);
    1390:	00007537          	lui	a0,0x7
    1394:	27450513          	addi	a0,a0,628 # 7274 <_data+0xd7c>
    1398:	3b0030ef          	jal	4748 <bsp_printf>
        /* ent_clamp 的边界行为（与主机自检里跑的是同一份源码） */
        t.x = (int16_t)FP(-50); t.y = (int16_t)FP(PLAY_Y1 + 99); t.vx = 8; t.vy = 8;
    139c:	e7000793          	li	a5,-400
    13a0:	00f11a23          	sh	a5,20(sp)
    13a4:	000017b7          	lui	a5,0x1
    13a8:	3f878793          	addi	a5,a5,1016 # 13f8 <main+0x2f4>
    13ac:	00f11b23          	sh	a5,22(sp)
    13b0:	00800793          	li	a5,8
    13b4:	00f11c23          	sh	a5,24(sp)
    13b8:	00f11d23          	sh	a5,26(sp)
        t.sz = SZ_B; t.r = 4; t.kind = S_B0; t.life = 1;
    13bc:	01000793          	li	a5,16
    13c0:	00f10ea3          	sb	a5,29(sp)
    13c4:	00400793          	li	a5,4
    13c8:	00f10f23          	sb	a5,30(sp)
    13cc:	00300793          	li	a5,3
    13d0:	00f10e23          	sb	a5,28(sp)
    13d4:	00100a13          	li	s4,1
    13d8:	01410fa3          	sb	s4,31(sp)
        ent_clamp(&t);
    13dc:	01410513          	addi	a0,sp,20
    13e0:	5f0010ef          	jal	29d0 <ent_clamp>
        bsp_printf("clampcheck x=%d y=%d vx=%d (expect 0 %d neg)\r\n",
                   PX(t.x), PX(t.y), (int)t.vx, PLAY_Y1 - SZ_B);
    13e4:	01411583          	lh	a1,20(sp)
    13e8:	01611603          	lh	a2,22(sp)
        bsp_printf("clampcheck x=%d y=%d vx=%d (expect 0 %d neg)\r\n",
    13ec:	20c00713          	li	a4,524
    13f0:	01811683          	lh	a3,24(sp)
    13f4:	40365613          	srai	a2,a2,0x3
    13f8:	4035d593          	srai	a1,a1,0x3
    13fc:	00007537          	lui	a0,0x7
    1400:	29c50513          	addi	a0,a0,668 # 729c <_data+0xda4>
    1404:	344030ef          	jal	4748 <bsp_printf>
        bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x DL_VER=%x\r\n",
                   (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG),
    1408:	048010ef          	jal	2450 <blt_stat>
    140c:	00050413          	mv	s0,a0
    1410:	024010ef          	jal	2434 <blt_cnt>
    1414:	00050493          	mv	s1,a0
    1418:	02000513          	li	a0,32
    141c:	341000ef          	jal	1f5c <blt_rd>
    1420:	00050913          	mv	s2,a0
                   (unsigned)blt_rd(BLT_DL_VERSION));
    1424:	08000513          	li	a0,128
    1428:	335000ef          	jal	1f5c <blt_rd>
    142c:	00050713          	mv	a4,a0
        bsp_printf("selfcheck: STATUS=%x COUNT=%d SCAN=%x DL_VER=%x\r\n",
    1430:	00090693          	mv	a3,s2
    1434:	00048613          	mv	a2,s1
    1438:	00040593          	mv	a1,s0
    143c:	00007537          	lui	a0,0x7
    1440:	2cc50513          	addi	a0,a0,716 # 72cc <_data+0xdd4>
    1444:	304030ef          	jal	4748 <bsp_printf>
    }
    boot_selfcheck();
    1448:	5d4030ef          	jal	4a1c <boot_selfcheck>

    game_reset();
    144c:	178030ef          	jal	45c4 <game_reset>
    g_state = GS_TITLE;
    1450:	8a01a223          	sw	zero,-1884(gp) # 798c <g_state>
    osd_build();
    1454:	5e1020ef          	jal	4234 <osd_build>
    osd_blit();
    1458:	685020ef          	jal	42dc <osd_blit>
    g_bar_ok[g_draw3] = 1;
    145c:	8301a783          	lw	a5,-2000(gp) # 7918 <g_draw3>
    1460:	8d818713          	addi	a4,gp,-1832 # 79c0 <g_bar_ok>
    1464:	00e787b3          	add	a5,a5,a4
    1468:	01478023          	sb	s4,0(a5)
    cache_evict();
    146c:	349000ef          	jal	1fb4 <cache_evict>

    t_now = tick32(); g_t_fps = t_now; t_st = t_now;
    1470:	2c1000ef          	jal	1f30 <tick32>
    1474:	00050a93          	mv	s5,a0
    1478:	86a1a023          	sw	a0,-1952(gp) # 7948 <g_t_fps>
    uint32_t back_t0 = 0;
    147c:	00000993          	li	s3,0
    int      back_busy = 0;
    1480:	00000913          	li	s2,0
    int      frame_started = 0;
    1484:	00000a13          	li	s4,0
    uint32_t it = 0;
    1488:	00000413          	li	s0,0
    148c:	2480006f          	j	16d4 <main+0x5d0>
    for (;;) {
        it++;

        /* ---------- 串口：每 4 圈一次（输入延迟 ≈ 几十 µs，远小于一帧） ---------- */
        if ((it & 3u) == 0u) {
            serial_drain();
    1490:	761030ef          	jal	53f0 <serial_drain>
            if ((it & 255u) == 0u) {
    1494:	0ff47793          	zext.b	a5,s0
    1498:	24079463          	bnez	a5,16e0 <main+0x5dc>
                t_now = tick32();
    149c:	295000ef          	jal	1f30 <tick32>
    14a0:	00050b13          	mv	s6,a0
                /* 按键看门狗：500ms 没收到包 ⇒ 全部松开（标签切走/拔线都安全） */
                if (g_keys_live && (uint32_t)(t_now - g_key_t) > (uint32_t)KEY_WD_TICKS) {
    14a4:	8781a783          	lw	a5,-1928(gp) # 7960 <g_keys_live>
    14a8:	02078063          	beqz	a5,14c8 <main+0x3c4>
    14ac:	87c1a703          	lw	a4,-1924(gp) # 7964 <g_key_t>
    14b0:	40e50733          	sub	a4,a0,a4
    14b4:	02faf7b7          	lui	a5,0x2faf
    14b8:	08078793          	addi	a5,a5,128 # 2faf080 <__freertos_irq_stack_top+0x2f95e80>
    14bc:	00e7f663          	bgeu	a5,a4,14c8 <main+0x3c4>
                    g_keys_live = 0;
    14c0:	8601ac23          	sw	zero,-1928(gp) # 7960 <g_keys_live>
                    g_keymask = 0u;
    14c4:	8801a223          	sw	zero,-1916(gp) # 796c <g_keymask>
                }
                /* 1Hz 帧率窗口：两个路径各记一个数，**都留在屏幕上** */
                if ((uint32_t)(t_now - g_t_fps) >= (uint32_t)BSP_CLINT_HZ) {
    14c8:	8601ab83          	lw	s7,-1952(gp) # 7948 <g_t_fps>
    14cc:	417b0bb3          	sub	s7,s6,s7
    14d0:	05f5e7b7          	lui	a5,0x5f5e
    14d4:	0ff78793          	addi	a5,a5,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f44eff>
    14d8:	2177f463          	bgeu	a5,s7,16e0 <main+0x5dc>
                    uint32_t el = (uint32_t)(t_now - g_t_fps);
                    int f_hw = (int)(((uint64_t)g_hw_frames * (uint64_t)BSP_CLINT_HZ) / el);
    14dc:	8681a503          	lw	a0,-1944(gp) # 7950 <g_hw_frames>
    14e0:	05f5ec37          	lui	s8,0x5f5e
    14e4:	100c0c13          	addi	s8,s8,256 # 5f5e100 <__freertos_irq_stack_top+0x5f44f00>
    14e8:	038535b3          	mulhu	a1,a0,s8
    14ec:	000b8613          	mv	a2,s7
    14f0:	00000693          	li	a3,0
    14f4:	03850533          	mul	a0,a0,s8
    14f8:	351040ef          	jal	6048 <__udivdi3>
    14fc:	00050c93          	mv	s9,a0
                    int f_sw = (int)(((uint64_t)g_sw_frames * (uint64_t)BSP_CLINT_HZ) / el);
    1500:	8641a503          	lw	a0,-1948(gp) # 794c <g_sw_frames>
    1504:	038535b3          	mulhu	a1,a0,s8
    1508:	000b8613          	mv	a2,s7
    150c:	00000693          	li	a3,0
    1510:	03850533          	mul	a0,a0,s8
    1514:	335040ef          	jal	6048 <__udivdi3>
    1518:	00050b93          	mv	s7,a0
                    int fps_now;
                    g_t_fps = t_now;
    151c:	8761a023          	sw	s6,-1952(gp) # 7948 <g_t_fps>
                    g_hw_frames = 0; g_sw_frames = 0;
    1520:	8601a423          	sw	zero,-1944(gp) # 7950 <g_hw_frames>
    1524:	8601a223          	sw	zero,-1948(gp) # 794c <g_sw_frames>
                    if (g_mode == MD_HW) { g_hw_fps = (uint32_t)f_hw; fps_now = f_hw; }
    1528:	8201a703          	lw	a4,-2016(gp) # 7908 <g_mode>
    152c:	00200793          	li	a5,2
    1530:	04f70e63          	beq	a4,a5,158c <main+0x488>
                    else                 { g_sw_fps = (uint32_t)f_sw; fps_now = f_sw; }
    1534:	86a1a623          	sw	a0,-1940(gp) # 7954 <g_sw_fps>
                    /* ★ 自动爬坡：每秒一步（规则见 ramp_apply） */
                    {
                        int r = ramp_apply(fps_now, &g_ncap, &g_lim_n, &g_auto);
    1538:	89c18693          	addi	a3,gp,-1892 # 7984 <g_auto>
    153c:	85818613          	addi	a2,gp,-1960 # 7940 <g_lim_n>
    1540:	81c18593          	addi	a1,gp,-2020 # 7904 <g_ncap>
    1544:	000b8513          	mv	a0,s7
    1548:	345010ef          	jal	308c <ramp_apply>
                        if (r == 1)
    154c:	00100793          	li	a5,1
    1550:	04f50463          	beq	a0,a5,1598 <main+0x494>
                            bsp_printf("\r\nEV ramp N=%d fps=%d\r\n", g_ncap, fps_now);
                        else if (r == 2)
    1554:	00200793          	li	a5,2
    1558:	04f50c63          	beq	a0,a5,15b0 <main+0x4ac>
                            bsp_printf("\r\nLIMIT N=%d fps=%d ON=%d (hit N_MAX)\r\n",
                                       g_lim_n, fps_now, g_on_screen);
                        else if (r < 0)
    155c:	18055263          	bgez	a0,16e0 <main+0x5dc>
                            bsp_printf("\r\nLIMIT N=%d fps=%d ON=%d path=%s (max stable at 60fps)\r\n",
    1560:	8581ab03          	lw	s6,-1960(gp) # 7940 <g_lim_n>
    1564:	85c1ac03          	lw	s8,-1956(gp) # 7944 <g_on_screen>
    1568:	4a9020ef          	jal	4210 <path_label>
    156c:	00050713          	mv	a4,a0
    1570:	000c0693          	mv	a3,s8
    1574:	000b8613          	mv	a2,s7
    1578:	000b0593          	mv	a1,s6
    157c:	00007537          	lui	a0,0x7
    1580:	34050513          	addi	a0,a0,832 # 7340 <_data+0xe48>
    1584:	1c4030ef          	jal	4748 <bsp_printf>
    1588:	1580006f          	j	16e0 <main+0x5dc>
                    if (g_mode == MD_HW) { g_hw_fps = (uint32_t)f_hw; fps_now = f_hw; }
    158c:	8791a823          	sw	s9,-1936(gp) # 7958 <g_hw_fps>
    1590:	000c8b93          	mv	s7,s9
    1594:	fa5ff06f          	j	1538 <main+0x434>
                            bsp_printf("\r\nEV ramp N=%d fps=%d\r\n", g_ncap, fps_now);
    1598:	000b8613          	mv	a2,s7
    159c:	81c1a583          	lw	a1,-2020(gp) # 7904 <g_ncap>
    15a0:	00007537          	lui	a0,0x7
    15a4:	30050513          	addi	a0,a0,768 # 7300 <_data+0xe08>
    15a8:	1a0030ef          	jal	4748 <bsp_printf>
    15ac:	1340006f          	j	16e0 <main+0x5dc>
                            bsp_printf("\r\nLIMIT N=%d fps=%d ON=%d (hit N_MAX)\r\n",
    15b0:	85c1a683          	lw	a3,-1956(gp) # 7944 <g_on_screen>
    15b4:	000b8613          	mv	a2,s7
    15b8:	8581a583          	lw	a1,-1960(gp) # 7940 <g_lim_n>
    15bc:	00007537          	lui	a0,0x7
    15c0:	31850513          	addi	a0,a0,792 # 7318 <_data+0xe20>
    15c4:	184030ef          	jal	4748 <bsp_printf>
    15c8:	1180006f          	j	16e0 <main+0x5dc>
                uint32_t irq = blt_rd(BLT_IRQ_STATUS);
                if (irq & BLT_IRQ_FRAME) { blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME); flip_ev = 1; }
                if (flip_ev && (fb_stat_sel() == g_flip_req)) {
                    int old_disp;
                    back_busy  = 0;
                    old_disp   = (int)g_disp_sel;
    15cc:	8e81a683          	lw	a3,-1816(gp) # 79d0 <g_disp_sel>
                    g_disp_sel = g_flip_req;
    15d0:	8ef1a423          	sw	a5,-1816(gp) # 79d0 <g_disp_sel>
                    g_draw3    = g_clr3;
    15d4:	82c1a503          	lw	a0,-2004(gp) # 7914 <g_clr3>
    15d8:	82a1a823          	sw	a0,-2000(gp) # 7918 <g_draw3>
                    g_clr3     = old_disp;
    15dc:	82d1a623          	sw	a3,-2004(gp) # 7914 <g_clr3>
                    g_clr_need = 1;
    15e0:	00100493          	li	s1,1
    15e4:	8c91ae23          	sw	s1,-1828(gp) # 79c4 <g_clr_need>
                    g_fb_back  = fb_of_sel((uint32_t)g_draw3);
    15e8:	185000ef          	jal	1f6c <fb_of_sel>
    15ec:	82a1aa23          	sw	a0,-1996(gp) # 791c <g_fb_back>
                    if (g_mode == MD_SW) g_sw_frames++; else g_hw_frames++;
    15f0:	8201a783          	lw	a5,-2016(gp) # 7908 <g_mode>
    15f4:	02978863          	beq	a5,s1,1624 <main+0x520>
    15f8:	8681a783          	lw	a5,-1944(gp) # 7950 <g_hw_frames>
    15fc:	00178793          	addi	a5,a5,1
    1600:	86f1a423          	sw	a5,-1944(gp) # 7950 <g_hw_frames>
                    frame_started = 0;                 /* 下一圈开新的一帧 */
                    /* ★ 4Hz 状态行：给上位机做记分板用。
                     *   为什么不每帧打：115200 下 ~87µs/字节是**阻塞**的（uart_write 等 TX 余量），
                     *   每帧一行的串口时间会直接吃掉帧预算。4Hz × ~48B ≈ 190B/s ≈ 1.7% CPU。 */
                    if ((uint32_t)(tick32() - t_st) >= (uint32_t)ST_PERIOD_TICKS) {
    1604:	12d000ef          	jal	1f30 <tick32>
    1608:	41550733          	sub	a4,a0,s5
    160c:	017d87b7          	lui	a5,0x17d8
    1610:	83f78793          	addi	a5,a5,-1985 # 17d783f <__freertos_irq_stack_top+0x17be63f>
    1614:	02e7e063          	bltu	a5,a4,1634 <main+0x530>
                    back_busy  = 0;
    1618:	00000913          	li	s2,0
                    frame_started = 0;                 /* 下一圈开新的一帧 */
    161c:	00000a13          	li	s4,0
                    cpu_backoff(BLT_WAIT_NOP);
                }
            } else {
                cpu_backoff(BLT_WAIT_NOP);
            }
            continue;
    1620:	0b40006f          	j	16d4 <main+0x5d0>
                    if (g_mode == MD_SW) g_sw_frames++; else g_hw_frames++;
    1624:	8641a783          	lw	a5,-1948(gp) # 794c <g_sw_frames>
    1628:	00178793          	addi	a5,a5,1
    162c:	86f1a223          	sw	a5,-1948(gp) # 794c <g_sw_frames>
    1630:	fd5ff06f          	j	1604 <main+0x500>
                        t_st = tick32();
    1634:	0fd000ef          	jal	1f30 <tick32>
    1638:	00050a93          	mv	s5,a0
                                   (g_mode == MD_SW) ? (int)g_sw_fps : (int)g_hw_fps,
    163c:	8201a503          	lw	a0,-2016(gp) # 7908 <g_mode>
                        bsp_printf("ST fps=%d n=%d on=%d sc=%d lv=%d hp=%d bm=%d md=%s\r\n",
    1640:	00100793          	li	a5,1
    1644:	04f50663          	beq	a0,a5,1690 <main+0x58c>
                                   (g_mode == MD_SW) ? (int)g_sw_fps : (int)g_hw_fps,
    1648:	8701a583          	lw	a1,-1936(gp) # 7958 <g_hw_fps>
                        bsp_printf("ST fps=%d n=%d on=%d sc=%d lv=%d hp=%d bm=%d md=%s\r\n",
    164c:	81c1a603          	lw	a2,-2020(gp) # 7904 <g_ncap>
    1650:	85c1a683          	lw	a3,-1956(gp) # 7944 <g_on_screen>
    1654:	8901a703          	lw	a4,-1904(gp) # 7978 <g_score>
    1658:	8101a783          	lw	a5,-2032(gp) # 78f8 <g_level>
    165c:	8181a803          	lw	a6,-2024(gp) # 7900 <g_hp>
    1660:	8141a883          	lw	a7,-2028(gp) # 78fc <g_bomb>
    1664:	00100313          	li	t1,1
    1668:	02650863          	beq	a0,t1,1698 <main+0x594>
    166c:	00007537          	lui	a0,0x7
    1670:	ff050513          	addi	a0,a0,-16 # 6ff0 <_data+0xaf8>
    1674:	00a12023          	sw	a0,0(sp)
    1678:	00007537          	lui	a0,0x7
    167c:	37c50513          	addi	a0,a0,892 # 737c <_data+0xe84>
    1680:	0c8030ef          	jal	4748 <bsp_printf>
                    back_busy  = 0;
    1684:	00000913          	li	s2,0
                    frame_started = 0;                 /* 下一圈开新的一帧 */
    1688:	00000a13          	li	s4,0
    168c:	0480006f          	j	16d4 <main+0x5d0>
                                   (g_mode == MD_SW) ? (int)g_sw_fps : (int)g_hw_fps,
    1690:	86c1a583          	lw	a1,-1940(gp) # 7954 <g_sw_fps>
    1694:	fb9ff06f          	j	164c <main+0x548>
                        bsp_printf("ST fps=%d n=%d on=%d sc=%d lv=%d hp=%d bm=%d md=%s\r\n",
    1698:	00007537          	lui	a0,0x7
    169c:	fec50513          	addi	a0,a0,-20 # 6fec <_data+0xaf4>
    16a0:	fd5ff06f          	j	1674 <main+0x570>
                                   (unsigned)blt_rd(BLT_FB_STAT));
    16a4:	02800513          	li	a0,40
    16a8:	0b5000ef          	jal	1f5c <blt_rd>
    16ac:	00050593          	mv	a1,a0
                        bsp_printf("\r\nEV flip timeout, FB_STAT=%x\r\n",
    16b0:	00007537          	lui	a0,0x7
    16b4:	3b450513          	addi	a0,a0,948 # 73b4 <_data+0xebc>
    16b8:	090030ef          	jal	4748 <bsp_printf>
    16bc:	07c0006f          	j	1738 <main+0x634>
                    cpu_backoff(BLT_WAIT_NOP);
    16c0:	03000513          	li	a0,48
    16c4:	079000ef          	jal	1f3c <cpu_backoff>
    16c8:	00c0006f          	j	16d4 <main+0x5d0>
                cpu_backoff(BLT_WAIT_NOP);
    16cc:	03000513          	li	a0,48
    16d0:	06d000ef          	jal	1f3c <cpu_backoff>
        it++;
    16d4:	00140413          	addi	s0,s0,1
        if ((it & 3u) == 0u) {
    16d8:	00347493          	andi	s1,s0,3
    16dc:	da048ae3          	beqz	s1,1490 <main+0x38c>
        if (back_busy) {
    16e0:	06090863          	beqz	s2,1750 <main+0x64c>
            if ((it & BLT_WAIT_MASK) == 0u) {
    16e4:	fe0494e3          	bnez	s1,16cc <main+0x5c8>
                uint32_t irq = blt_rd(BLT_IRQ_STATUS);
    16e8:	01000513          	li	a0,16
    16ec:	071000ef          	jal	1f5c <blt_rd>
                if (irq & BLT_IRQ_FRAME) { blt_wr(BLT_IRQ_STATUS, BLT_IRQ_FRAME); flip_ev = 1; }
    16f0:	00257513          	andi	a0,a0,2
    16f4:	00050e63          	beqz	a0,1710 <main+0x60c>
    16f8:	00200593          	li	a1,2
    16fc:	01000513          	li	a0,16
    1700:	04d000ef          	jal	1f4c <blt_wr>
                if (flip_ev && (fb_stat_sel() == g_flip_req)) {
    1704:	091000ef          	jal	1f94 <fb_stat_sel>
    1708:	8e41a783          	lw	a5,-1820(gp) # 79cc <g_flip_req>
    170c:	ecf500e3          	beq	a0,a5,15cc <main+0x4c8>
                } else if ((uint32_t)(tick32() - back_t0) > (uint32_t)FLIP_TIMEOUT_TICKS) {
    1710:	021000ef          	jal	1f30 <tick32>
    1714:	41350533          	sub	a0,a0,s3
    1718:	009897b7          	lui	a5,0x989
    171c:	68078793          	addi	a5,a5,1664 # 989680 <__freertos_irq_stack_top+0x970480>
    1720:	faa7f0e3          	bgeu	a5,a0,16c0 <main+0x5bc>
                    g_flip_to++;
    1724:	8e01a783          	lw	a5,-1824(gp) # 79c8 <g_flip_to>
    1728:	00178793          	addi	a5,a5,1
    172c:	8ef1a023          	sw	a5,-1824(gp) # 79c8 <g_flip_to>
                    if (g_flip_to == 1u)
    1730:	00100713          	li	a4,1
    1734:	f6e788e3          	beq	a5,a4,16a4 <main+0x5a0>
                    blt_wr(BLT_FB_SEL, g_flip_req);    /* 重发请求，继续有界等待 */
    1738:	8e41a583          	lw	a1,-1820(gp) # 79cc <g_flip_req>
    173c:	02400513          	li	a0,36
    1740:	00d000ef          	jal	1f4c <blt_wr>
                    back_t0 = tick32();
    1744:	7ec000ef          	jal	1f30 <tick32>
    1748:	00050993          	mv	s3,a0
    174c:	f89ff06f          	j	16d4 <main+0x5d0>
        }

        /* ---------- 本帧起点：推进一帧游戏 + 组清单 + 画信息条 ---------- */
        if (!frame_started) {
    1750:	040a0a63          	beqz	s4,17a4 <main+0x6a0>
            frame_started = 1;
            continue;
        }

        /* ---------- 纯 CPU 对照路径：整帧由 CPU 画（诚实分母） ---------- */
        if (g_mode == MD_SW) {
    1754:	8201a483          	lw	s1,-2016(gp) # 7908 <g_mode>
    1758:	00100793          	li	a5,1
    175c:	08f48263          	beq	s1,a5,17e0 <main+0x6dc>
            back_t0    = tick32();
            continue;
        }

        /* ---------- 硬件路径：分块把本帧清单推进 FIFO ---------- */
        if (g_dl_i < g_dl_n) { push_chunk(); continue; }
    1760:	8ac1a703          	lw	a4,-1876(gp) # 7994 <g_dl_i>
    1764:	8b01a783          	lw	a5,-1872(gp) # 7998 <g_dl_n>
    1768:	0af74463          	blt	a4,a5,1810 <main+0x70c>

        /* ---------- 清单推完：等引擎空闲（有界）→ 画中央字幕 → 请求翻转 ---------- */
        if (!wait_engine_idle()) { blt_recover("engine never went idle"); frame_started = 0; continue; }
    176c:	75d020ef          	jal	46c8 <wait_engine_idle>
    1770:	00050493          	mv	s1,a0
    1774:	0a050263          	beqz	a0,1818 <main+0x714>
        overlay_draw();                        /* ★ 必须等引擎画完再写，否则会被引擎覆盖 */
    1778:	4bd020ef          	jal	4434 <overlay_draw>
        cache_evict();
    177c:	039000ef          	jal	1fb4 <cache_evict>
        blt_wr(BLT_FB_SEL, (uint32_t)g_draw3);
    1780:	8301a583          	lw	a1,-2000(gp) # 7918 <g_draw3>
    1784:	02400513          	li	a0,36
    1788:	7c4000ef          	jal	1f4c <blt_wr>
        g_flip_req = (uint32_t)g_draw3;
    178c:	8301a703          	lw	a4,-2000(gp) # 7918 <g_draw3>
    1790:	8ee1a223          	sw	a4,-1820(gp) # 79cc <g_flip_req>
        back_busy  = 1;
        back_t0    = tick32();
    1794:	79c000ef          	jal	1f30 <tick32>
    1798:	00050993          	mv	s3,a0
        back_busy  = 1;
    179c:	000a0913          	mv	s2,s4
    17a0:	f35ff06f          	j	16d4 <main+0x5d0>
            game_tick();
    17a4:	7d5030ef          	jal	5778 <game_tick>
            repaint = hw_pass_arm();
    17a8:	69d000ef          	jal	2644 <hw_pass_arm>
            build_draw_list(repaint);
    17ac:	3b5010ef          	jal	3360 <build_draw_list>
            g_on_screen = dl_sprite_count();
    17b0:	611010ef          	jal	35c0 <dl_sprite_count>
    17b4:	84a1ae23          	sw	a0,-1956(gp) # 7944 <g_on_screen>
            osd_build();
    17b8:	27d020ef          	jal	4234 <osd_build>
            osd_blit();
    17bc:	321020ef          	jal	42dc <osd_blit>
            g_bar_ok[g_draw3] = 1;
    17c0:	8301a783          	lw	a5,-2000(gp) # 7918 <g_draw3>
    17c4:	8d818713          	addi	a4,gp,-1832 # 79c0 <g_bar_ok>
    17c8:	00e787b3          	add	a5,a5,a4
    17cc:	00100713          	li	a4,1
    17d0:	00e78023          	sb	a4,0(a5)
            g_dl_i = 0;
    17d4:	8a01a623          	sw	zero,-1876(gp) # 7994 <g_dl_i>
            frame_started = 1;
    17d8:	00100a13          	li	s4,1
            continue;
    17dc:	ef9ff06f          	j	16d4 <main+0x5d0>
            cpu_render_frame();
    17e0:	484020ef          	jal	3c64 <cpu_render_frame>
            overlay_draw();
    17e4:	451020ef          	jal	4434 <overlay_draw>
            cache_evict();
    17e8:	7cc000ef          	jal	1fb4 <cache_evict>
            blt_wr(BLT_FB_SEL, (uint32_t)g_draw3);
    17ec:	8301a583          	lw	a1,-2000(gp) # 7918 <g_draw3>
    17f0:	02400513          	li	a0,36
    17f4:	758000ef          	jal	1f4c <blt_wr>
            g_flip_req = (uint32_t)g_draw3;
    17f8:	8301a703          	lw	a4,-2000(gp) # 7918 <g_draw3>
    17fc:	8ee1a223          	sw	a4,-1820(gp) # 79cc <g_flip_req>
            back_t0    = tick32();
    1800:	730000ef          	jal	1f30 <tick32>
    1804:	00050993          	mv	s3,a0
            back_busy  = 1;
    1808:	00048913          	mv	s2,s1
            continue;
    180c:	ec9ff06f          	j	16d4 <main+0x5d0>
        if (g_dl_i < g_dl_n) { push_chunk(); continue; }
    1810:	679010ef          	jal	3688 <push_chunk>
    1814:	ec1ff06f          	j	16d4 <main+0x5d0>
        if (!wait_engine_idle()) { blt_recover("engine never went idle"); frame_started = 0; continue; }
    1818:	00007537          	lui	a0,0x7
    181c:	3d450513          	addi	a0,a0,980 # 73d4 <_data+0xedc>
    1820:	7b4040ef          	jal	5fd4 <blt_recover>
    1824:	00048a13          	mv	s4,s1
    1828:	eadff06f          	j	16d4 <main+0x5d0>

0000182c <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    182c:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    1830:	01055513          	srli	a0,a0,0x10
    }
    1834:	0ff57513          	zext.b	a0,a0
    1838:	00008067          	ret

0000183c <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    183c:	ff010113          	addi	sp,sp,-16
    1840:	00112623          	sw	ra,12(sp)
    1844:	00812423          	sw	s0,8(sp)
    1848:	00912223          	sw	s1,4(sp)
    184c:	00050413          	mv	s0,a0
    1850:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    1854:	00040513          	mv	a0,s0
    1858:	fd5ff0ef          	jal	182c <uart_writeAvailability>
    185c:	fe050ce3          	beqz	a0,1854 <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    1860:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    1864:	00c12083          	lw	ra,12(sp)
    1868:	00812403          	lw	s0,8(sp)
    186c:	00412483          	lw	s1,4(sp)
    1870:	01010113          	addi	sp,sp,16
    1874:	00008067          	ret

00001878 <uart_applyConfig>:
*          value using data length, parity, and stop bit settings from the configuration
*          structure, and writes this value to the UART frame configuration register.
*
******************************************************************************/
    static void uart_applyConfig(u32 reg, Uart_Config *config){
        write_u32(config->clockDivider, reg + UART_CLOCK_DIVIDER);
    1878:	00c5a783          	lw	a5,12(a1) # 30100c <__freertos_irq_stack_top+0x2e7e0c>
    187c:	00f52423          	sw	a5,8(a0)
        write_u32(((config->dataLength-1) << 0) | (config->parity << 8) | (config->stop << 16), reg + UART_FRAME_CONFIG);
    1880:	0005a783          	lw	a5,0(a1)
    1884:	fff78793          	addi	a5,a5,-1
    1888:	0045a703          	lw	a4,4(a1)
    188c:	00871713          	slli	a4,a4,0x8
    1890:	00e7e7b3          	or	a5,a5,a4
    1894:	0085a703          	lw	a4,8(a1)
    1898:	01071713          	slli	a4,a4,0x10
    189c:	00e7e7b3          	or	a5,a5,a4
    18a0:	00f52623          	sw	a5,12(a0)
    }
    18a4:	00008067          	ret

000018a8 <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    18a8:	ff010113          	addi	sp,sp,-16
    18ac:	00112623          	sw	ra,12(sp)
    18b0:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    18b4:	f8010537          	lui	a0,0xf8010
    18b8:	f85ff0ef          	jal	183c <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    18bc:	00c12083          	lw	ra,12(sp)
    18c0:	01010113          	addi	sp,sp,16
    18c4:	00008067          	ret

000018c8 <_putchar_s>:

    static void _putchar_s(char *p)
    {
    18c8:	ff010113          	addi	sp,sp,-16
    18cc:	00112623          	sw	ra,12(sp)
    18d0:	00812423          	sw	s0,8(sp)
    18d4:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    18d8:	00c0006f          	j	18e4 <_putchar_s+0x1c>
            _putchar(*(p++));
    18dc:	00140413          	addi	s0,s0,1
    18e0:	fc9ff0ef          	jal	18a8 <_putchar>
        while (*p)
    18e4:	00044503          	lbu	a0,0(s0)
    18e8:	fe051ae3          	bnez	a0,18dc <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    18ec:	00c12083          	lw	ra,12(sp)
    18f0:	00812403          	lw	s0,8(sp)
    18f4:	01010113          	addi	sp,sp,16
    18f8:	00008067          	ret

000018fc <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    18fc:	ff010113          	addi	sp,sp,-16
    1900:	00112623          	sw	ra,12(sp)
    1904:	00812423          	sw	s0,8(sp)
    1908:	00912223          	sw	s1,4(sp)
    190c:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1910:	01c00413          	li	s0,28
    1914:	0240006f          	j	1938 <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    1918:	0084d733          	srl	a4,s1,s0
    191c:	00f77713          	andi	a4,a4,15
    1920:	000067b7          	lui	a5,0x6
    1924:	4f878793          	addi	a5,a5,1272 # 64f8 <_data>
    1928:	00e787b3          	add	a5,a5,a4
    192c:	0007c503          	lbu	a0,0(a5)
    1930:	f79ff0ef          	jal	18a8 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1934:	ffc40413          	addi	s0,s0,-4
    1938:	fe0450e3          	bgez	s0,1918 <bsp_printHex+0x1c>
        }
    }
    193c:	00c12083          	lw	ra,12(sp)
    1940:	00812403          	lw	s0,8(sp)
    1944:	00412483          	lw	s1,4(sp)
    1948:	01010113          	addi	sp,sp,16
    194c:	00008067          	ret

00001950 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    1950:	ff010113          	addi	sp,sp,-16
    1954:	00112623          	sw	ra,12(sp)
    1958:	00812423          	sw	s0,8(sp)
    195c:	00912223          	sw	s1,4(sp)
    1960:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1964:	01c00413          	li	s0,28
    1968:	0240006f          	j	198c <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    196c:	0084d733          	srl	a4,s1,s0
    1970:	00f77713          	andi	a4,a4,15
    1974:	000067b7          	lui	a5,0x6
    1978:	50c78793          	addi	a5,a5,1292 # 650c <_data+0x14>
    197c:	00e787b3          	add	a5,a5,a4
    1980:	0007c503          	lbu	a0,0(a5)
    1984:	f25ff0ef          	jal	18a8 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1988:	ffc40413          	addi	s0,s0,-4
    198c:	fe0450e3          	bgez	s0,196c <bsp_printHex_lower+0x1c>

        }
    }
    1990:	00c12083          	lw	ra,12(sp)
    1994:	00812403          	lw	s0,8(sp)
    1998:	00412483          	lw	s1,4(sp)
    199c:	01010113          	addi	sp,sp,16
    19a0:	00008067          	ret

000019a4 <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    19a4:	ff010113          	addi	sp,sp,-16
    19a8:	00112623          	sw	ra,12(sp)
        _putchar(c);
    19ac:	0ff57513          	zext.b	a0,a0
    19b0:	ef9ff0ef          	jal	18a8 <_putchar>
    }
    19b4:	00c12083          	lw	ra,12(sp)
    19b8:	01010113          	addi	sp,sp,16
    19bc:	00008067          	ret

000019c0 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    19c0:	ff010113          	addi	sp,sp,-16
    19c4:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    19c8:	f01ff0ef          	jal	18c8 <_putchar_s>
    }
    19cc:	00c12083          	lw	ra,12(sp)
    19d0:	01010113          	addi	sp,sp,16
    19d4:	00008067          	ret

000019d8 <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    19d8:	fd010113          	addi	sp,sp,-48
    19dc:	02112623          	sw	ra,44(sp)
    19e0:	02812423          	sw	s0,40(sp)
    19e4:	02912223          	sw	s1,36(sp)
    19e8:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    19ec:	00054663          	bltz	a0,19f8 <bsp_printf_d+0x20>
    {
    19f0:	00010413          	mv	s0,sp
    19f4:	02c0006f          	j	1a20 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    19f8:	02d00513          	li	a0,45
    19fc:	fa9ff0ef          	jal	19a4 <bsp_printf_c>
            val = -val;
    1a00:	409004b3          	neg	s1,s1
    1a04:	fedff06f          	j	19f0 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    1a08:	00a00713          	li	a4,10
    1a0c:	02e4e7b3          	rem	a5,s1,a4
    1a10:	03078793          	addi	a5,a5,48
    1a14:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    1a18:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    1a1c:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    1a20:	fe0494e3          	bnez	s1,1a08 <bsp_printf_d+0x30>
    1a24:	00010793          	mv	a5,sp
    1a28:	fef400e3          	beq	s0,a5,1a08 <bsp_printf_d+0x30>
        }
        while (p != buffer)
    1a2c:	00010793          	mv	a5,sp
    1a30:	00f40a63          	beq	s0,a5,1a44 <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    1a34:	fff40413          	addi	s0,s0,-1
    1a38:	00044503          	lbu	a0,0(s0)
    1a3c:	f69ff0ef          	jal	19a4 <bsp_printf_c>
    1a40:	fedff06f          	j	1a2c <bsp_printf_d+0x54>
    }
    1a44:	02c12083          	lw	ra,44(sp)
    1a48:	02812403          	lw	s0,40(sp)
    1a4c:	02412483          	lw	s1,36(sp)
    1a50:	03010113          	addi	sp,sp,48
    1a54:	00008067          	ret

00001a58 <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    1a58:	ff010113          	addi	sp,sp,-16
    1a5c:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    1a60:	00000713          	li	a4,0
    1a64:	00700793          	li	a5,7
    1a68:	02e7c063          	blt	a5,a4,1a88 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1a6c:	00271693          	slli	a3,a4,0x2
    1a70:	ff000793          	li	a5,-16
    1a74:	00d797b3          	sll	a5,a5,a3
    1a78:	00f577b3          	and	a5,a0,a5
    1a7c:	00078663          	beqz	a5,1a88 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    1a80:	00170713          	addi	a4,a4,1
    1a84:	fe1ff06f          	j	1a64 <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    1a88:	ec9ff0ef          	jal	1950 <bsp_printHex_lower>
    }
    1a8c:	00c12083          	lw	ra,12(sp)
    1a90:	01010113          	addi	sp,sp,16
    1a94:	00008067          	ret

00001a98 <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    1a98:	ff010113          	addi	sp,sp,-16
    1a9c:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    1aa0:	00000713          	li	a4,0
    1aa4:	00700793          	li	a5,7
    1aa8:	02e7c063          	blt	a5,a4,1ac8 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1aac:	00271693          	slli	a3,a4,0x2
    1ab0:	ff000793          	li	a5,-16
    1ab4:	00d797b3          	sll	a5,a5,a3
    1ab8:	00f577b3          	and	a5,a0,a5
    1abc:	00078663          	beqz	a5,1ac8 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    1ac0:	00170713          	addi	a4,a4,1
    1ac4:	fe1ff06f          	j	1aa4 <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    1ac8:	e35ff0ef          	jal	18fc <bsp_printHex>
        }
    1acc:	00c12083          	lw	ra,12(sp)
    1ad0:	01010113          	addi	sp,sp,16
    1ad4:	00008067          	ret

00001ad8 <bsp_init>:
    *   1. UART baudrate
    *   2. 
    */
////////////////////////////////////////////////////////////////////////////////
    static void bsp_init()
    {
    1ad8:	fe010113          	addi	sp,sp,-32
    1adc:	00112e23          	sw	ra,28(sp)
        Uart_Config uartConfig;
        uartConfig.dataLength   = BITS_8;
    1ae0:	00800793          	li	a5,8
    1ae4:	00f12023          	sw	a5,0(sp)
        uartConfig.parity       = NONE;
    1ae8:	00012223          	sw	zero,4(sp)
        uartConfig.stop         = ONE;
    1aec:	00012423          	sw	zero,8(sp)
        uartConfig.clockDivider = BSP_CLINT_HZ/(BSP_UART_BAUDRATE*BSP_UART_DATA_LEN)-1;
    1af0:	06b00793          	li	a5,107
    1af4:	00f12623          	sw	a5,12(sp)
        uart_applyConfig(BSP_UART_TERMINAL, &uartConfig);    
    1af8:	00010593          	mv	a1,sp
    1afc:	f8010537          	lui	a0,0xf8010
    1b00:	d79ff0ef          	jal	1878 <uart_applyConfig>
    }
    1b04:	01c12083          	lw	ra,28(sp)
    1b08:	02010113          	addi	sp,sp,32
    1b0c:	00008067          	ret

00001b10 <attr_word>:
    return ((uint32_t)(blend & 0xFu) << 0)
    1b10:	00f57513          	andi	a0,a0,15
         | ((uint32_t)(fmt   & 0x3u) << 4)
    1b14:	00459593          	slli	a1,a1,0x4
    1b18:	0305f593          	andi	a1,a1,48
    1b1c:	00b56533          	or	a0,a0,a1
         | ((uint32_t)(ga    & 0xFFu) << 6)
    1b20:	00661613          	slli	a2,a2,0x6
    1b24:	000047b7          	lui	a5,0x4
    1b28:	fc078793          	addi	a5,a5,-64 # 3fc0 <fmt_stat+0xdc>
    1b2c:	00f67633          	and	a2,a2,a5
    1b30:	00c56533          	or	a0,a0,a2
         | ((uint32_t)(flags & 0x3u) << 24);
    1b34:	01869693          	slli	a3,a3,0x18
    1b38:	030007b7          	lui	a5,0x3000
    1b3c:	00f6f6b3          	and	a3,a3,a5
}
    1b40:	00d56533          	or	a0,a0,a3
    1b44:	00008067          	ret

00001b48 <attr_blend>:
static unsigned attr_blend(uint32_t w) { return (unsigned)(w & 0xFu); }
    1b48:	00f57513          	andi	a0,a0,15
    1b4c:	00008067          	ret

00001b50 <attr_fmt>:
static unsigned attr_fmt(uint32_t w)   { return (unsigned)((w >> 4) & 0x3u); }
    1b50:	00455513          	srli	a0,a0,0x4
    1b54:	00357513          	andi	a0,a0,3
    1b58:	00008067          	ret

00001b5c <attr_ga>:
static unsigned attr_ga(uint32_t w)    { return (unsigned)((w >> 6) & 0xFFu); }
    1b5c:	00655513          	srli	a0,a0,0x6
    1b60:	0ff57513          	zext.b	a0,a0
    1b64:	00008067          	ret

00001b68 <attr_flags>:
static unsigned attr_flags(uint32_t w) { return (unsigned)((w >> 24) & 0x3u); }
    1b68:	01855513          	srli	a0,a0,0x18
    1b6c:	00357513          	andi	a0,a0,3
    1b70:	00008067          	ret

00001b74 <bulm_eff_name>:
    if (g_bulm == BULM_ADD && !g_glow) return g_bulm_name[BULM_KEY];
    1b74:	8381a703          	lw	a4,-1992(gp) # 7920 <g_bulm>
    1b78:	00200793          	li	a5,2
    1b7c:	00f70e63          	beq	a4,a5,1b98 <bulm_eff_name+0x24>
    return g_bulm_name[g_bulm];
    1b80:	000077b7          	lui	a5,0x7
    1b84:	00271713          	slli	a4,a4,0x2
    1b88:	7c478793          	addi	a5,a5,1988 # 77c4 <g_bulm_name>
    1b8c:	00e787b3          	add	a5,a5,a4
    1b90:	0007a503          	lw	a0,0(a5)
    1b94:	00008067          	ret
    if (g_bulm == BULM_ADD && !g_glow) return g_bulm_name[BULM_KEY];
    1b98:	8f81a783          	lw	a5,-1800(gp) # 79e0 <g_glow>
    1b9c:	fe0792e3          	bnez	a5,1b80 <bulm_eff_name+0xc>
    1ba0:	00006537          	lui	a0,0x6
    1ba4:	52050513          	addi	a0,a0,1312 # 6520 <_data+0x28>
}
    1ba8:	00008067          	ret

00001bac <iabs>:
static int iabs(int v) { return (v < 0) ? -v : v; }
    1bac:	41f55793          	srai	a5,a0,0x1f
    1bb0:	00a7c533          	xor	a0,a5,a0
    1bb4:	40f50533          	sub	a0,a0,a5
    1bb8:	00008067          	ret

00001bbc <spr_player>:
    if (j < 2 || j > 29) return TRANS_KEY;
    1bbc:	ffe58713          	addi	a4,a1,-2
    1bc0:	01b00793          	li	a5,27
    1bc4:	08e7e463          	bltu	a5,a4,1c4c <spr_player+0x90>
{
    1bc8:	ff010113          	addi	sp,sp,-16
    1bcc:	00112623          	sw	ra,12(sp)
    1bd0:	00812423          	sw	s0,8(sp)
    1bd4:	00912223          	sw	s1,4(sp)
    1bd8:	01212023          	sw	s2,0(sp)
    1bdc:	00058413          	mv	s0,a1
    1be0:	ff050513          	addi	a0,a0,-16
    halfw = 1 + (j * 12) / 29;                 /* j=2 → 1 ; j=29 → 13 */
    1be4:	00159493          	slli	s1,a1,0x1
    1be8:	00b484b3          	add	s1,s1,a1
    1bec:	00249493          	slli	s1,s1,0x2
    1bf0:	01d00793          	li	a5,29
    1bf4:	02f4c4b3          	div	s1,s1,a5
    1bf8:	00148913          	addi	s2,s1,1
    if (iabs(ax) > halfw) return TRANS_KEY;
    1bfc:	fb1ff0ef          	jal	1bac <iabs>
    1c00:	04a94a63          	blt	s2,a0,1c54 <spr_player+0x98>
    if (j >= 20 && iabs(ax) > halfw - 3) return COL_DIM;      /* 机翼 */
    1c04:	01300793          	li	a5,19
    1c08:	0087d663          	bge	a5,s0,1c14 <spr_player+0x58>
    1c0c:	fff48493          	addi	s1,s1,-1
    1c10:	04955663          	bge	a0,s1,1c5c <spr_player+0xa0>
    if (iabs(ax) <= 3 && j < 22)         return COL_CYAN;     /* 座舱 */
    1c14:	00300793          	li	a5,3
    1c18:	00a7c663          	blt	a5,a0,1c24 <spr_player+0x68>
    1c1c:	01500793          	li	a5,21
    1c20:	0487d463          	bge	a5,s0,1c68 <spr_player+0xac>
    if (j > 26)                          return COL_AMBER;    /* 尾焰口 */
    1c24:	01a00793          	li	a5,26
    1c28:	0487c463          	blt	a5,s0,1c70 <spr_player+0xb4>
    return COL_WHITE;
    1c2c:	00010537          	lui	a0,0x10
    1c30:	fff50513          	addi	a0,a0,-1 # ffff <__global_pointer$+0x7f17>
}
    1c34:	00c12083          	lw	ra,12(sp)
    1c38:	00812403          	lw	s0,8(sp)
    1c3c:	00412483          	lw	s1,4(sp)
    1c40:	00012903          	lw	s2,0(sp)
    1c44:	01010113          	addi	sp,sp,16
    1c48:	00008067          	ret
    if (j < 2 || j > 29) return TRANS_KEY;
    1c4c:	00000513          	li	a0,0
}
    1c50:	00008067          	ret
    if (iabs(ax) > halfw) return TRANS_KEY;
    1c54:	00000513          	li	a0,0
    1c58:	fddff06f          	j	1c34 <spr_player+0x78>
    if (j >= 20 && iabs(ax) > halfw - 3) return COL_DIM;      /* 机翼 */
    1c5c:	00002537          	lui	a0,0x2
    1c60:	8e350513          	addi	a0,a0,-1821 # 18e3 <_putchar_s+0x1b>
    1c64:	fd1ff06f          	j	1c34 <spr_player+0x78>
    if (iabs(ax) <= 3 && j < 22)         return COL_CYAN;     /* 座舱 */
    1c68:	7ff00513          	li	a0,2047
    1c6c:	fc9ff06f          	j	1c34 <spr_player+0x78>
    if (j > 26)                          return COL_AMBER;    /* 尾焰口 */
    1c70:	00010537          	lui	a0,0x10
    1c74:	d2050513          	addi	a0,a0,-736 # fd20 <__global_pointer$+0x7c38>
    1c78:	fbdff06f          	j	1c34 <spr_player+0x78>

00001c7c <spr_enemy>:
{
    1c7c:	ff010113          	addi	sp,sp,-16
    1c80:	00112623          	sw	ra,12(sp)
    1c84:	00812423          	sw	s0,8(sp)
    1c88:	00912223          	sw	s1,4(sp)
    1c8c:	00058493          	mv	s1,a1
    int m  = iabs(i - cx) + iabs(j - cx);
    1c90:	ff050513          	addi	a0,a0,-16
    1c94:	f19ff0ef          	jal	1bac <iabs>
    1c98:	00050413          	mv	s0,a0
    1c9c:	ff048513          	addi	a0,s1,-16
    1ca0:	f0dff0ef          	jal	1bac <iabs>
    1ca4:	00a40533          	add	a0,s0,a0
    if (m > 14) return TRANS_KEY;
    1ca8:	00e00793          	li	a5,14
    1cac:	02a7c463          	blt	a5,a0,1cd4 <spr_enemy+0x58>
    if (m > 11) return 0x7800u;                               /* 深红外壳 */
    1cb0:	00b00793          	li	a5,11
    1cb4:	02a7cc63          	blt	a5,a0,1cec <spr_enemy+0x70>
    if (m > 6)  return COL_RED;
    1cb8:	00600793          	li	a5,6
    1cbc:	02a7ce63          	blt	a5,a0,1cf8 <spr_enemy+0x7c>
    if (m > 2)  return COL_AMBER;
    1cc0:	00200793          	li	a5,2
    1cc4:	04a7c063          	blt	a5,a0,1d04 <spr_enemy+0x88>
    return COL_WHITE;
    1cc8:	00010537          	lui	a0,0x10
    1ccc:	fff50513          	addi	a0,a0,-1 # ffff <__global_pointer$+0x7f17>
    1cd0:	0080006f          	j	1cd8 <spr_enemy+0x5c>
    if (m > 14) return TRANS_KEY;
    1cd4:	00000513          	li	a0,0
}
    1cd8:	00c12083          	lw	ra,12(sp)
    1cdc:	00812403          	lw	s0,8(sp)
    1ce0:	00412483          	lw	s1,4(sp)
    1ce4:	01010113          	addi	sp,sp,16
    1ce8:	00008067          	ret
    if (m > 11) return 0x7800u;                               /* 深红外壳 */
    1cec:	00008537          	lui	a0,0x8
    1cf0:	80050513          	addi	a0,a0,-2048 # 7800 <__clz_tab+0xc>
    1cf4:	fe5ff06f          	j	1cd8 <spr_enemy+0x5c>
    if (m > 6)  return COL_RED;
    1cf8:	00010537          	lui	a0,0x10
    1cfc:	80050513          	addi	a0,a0,-2048 # f800 <__global_pointer$+0x7718>
    1d00:	fd9ff06f          	j	1cd8 <spr_enemy+0x5c>
    if (m > 2)  return COL_AMBER;
    1d04:	00010537          	lui	a0,0x10
    1d08:	d2050513          	addi	a0,a0,-736 # fd20 <__global_pointer$+0x7c38>
    1d0c:	fcdff06f          	j	1cd8 <spr_enemy+0x5c>

00001d10 <spr_glow>:
    int dx = i * 2 - n + 1;
    1d10:	00151793          	slli	a5,a0,0x1
    1d14:	ff178793          	addi	a5,a5,-15
    int dy = j * 2 - n + 1;
    1d18:	00159593          	slli	a1,a1,0x1
    1d1c:	ff158593          	addi	a1,a1,-15
    int d2 = dx * dx + dy * dy;
    1d20:	02f787b3          	mul	a5,a5,a5
    1d24:	02b585b3          	mul	a1,a1,a1
    1d28:	00b787b3          	add	a5,a5,a1
    if (d2 >= r2) return TRANS_KEY;
    1d2c:	0ff00713          	li	a4,255
    1d30:	08f74863          	blt	a4,a5,1dc0 <spr_glow+0xb0>
    t  = (unsigned)((d2 * 255) / r2);          /* 0 圆心 .. 255 边缘 */
    1d34:	00879713          	slli	a4,a5,0x8
    1d38:	40f70733          	sub	a4,a4,a5
    1d3c:	41f75793          	srai	a5,a4,0x1f
    1d40:	0ff7f793          	zext.b	a5,a5
    1d44:	00e787b3          	add	a5,a5,a4
    1d48:	4087d793          	srai	a5,a5,0x8
    i8 = 255u - t;
    1d4c:	0ff00713          	li	a4,255
    1d50:	40f707b3          	sub	a5,a4,a5
    i8 = (i8 * i8) / 255u;                     /* 平方衰减：中心亮、边缘柔 */
    1d54:	02f787b3          	mul	a5,a5,a5
    1d58:	02e7d733          	divu	a4,a5,a4
    if (i8 < 32u) return TRANS_KEY;
    1d5c:	000026b7          	lui	a3,0x2
    1d60:	fdf68693          	addi	a3,a3,-33 # 1fdf <cache_evict+0x2b>
    1d64:	06f6f263          	bgeu	a3,a5,1dc8 <spr_glow+0xb8>
    r = (unsigned)(((base >> 11) & 0x1Fu) * i8 / 255u);
    1d68:	00b65513          	srli	a0,a2,0xb
    1d6c:	02e50533          	mul	a0,a0,a4
    1d70:	0ff00693          	li	a3,255
    1d74:	02d55533          	divu	a0,a0,a3
    g = (unsigned)(((base >>  5) & 0x3Fu) * i8 / 255u);
    1d78:	00565793          	srli	a5,a2,0x5
    1d7c:	03f7f793          	andi	a5,a5,63
    1d80:	02e787b3          	mul	a5,a5,a4
    1d84:	02d7d7b3          	divu	a5,a5,a3
    b = (unsigned)(( base        & 0x1Fu) * i8 / 255u);
    1d88:	01f67613          	andi	a2,a2,31
    1d8c:	02e60633          	mul	a2,a2,a4
    1d90:	02d65633          	divu	a2,a2,a3
    return (uint16_t)((r << 11) | (g << 5) | b);
    1d94:	00b51513          	slli	a0,a0,0xb
    1d98:	01051513          	slli	a0,a0,0x10
    1d9c:	01055513          	srli	a0,a0,0x10
    1da0:	00579793          	slli	a5,a5,0x5
    1da4:	01079793          	slli	a5,a5,0x10
    1da8:	0107d793          	srli	a5,a5,0x10
    1dac:	00f56533          	or	a0,a0,a5
    1db0:	00c56533          	or	a0,a0,a2
    1db4:	01051513          	slli	a0,a0,0x10
    1db8:	01055513          	srli	a0,a0,0x10
    1dbc:	00008067          	ret
    if (d2 >= r2) return TRANS_KEY;
    1dc0:	00000513          	li	a0,0
    1dc4:	00008067          	ret
    if (i8 < 32u) return TRANS_KEY;
    1dc8:	00000513          	li	a0,0
}
    1dcc:	00008067          	ret

00001dd0 <spr_pixel>:
{
    1dd0:	ff010113          	addi	sp,sp,-16
    1dd4:	00112623          	sw	ra,12(sp)
    1dd8:	00050793          	mv	a5,a0
    1ddc:	00058513          	mv	a0,a1
    1de0:	00060593          	mv	a1,a2
    switch (id) {
    1de4:	00600713          	li	a4,6
    1de8:	06f76c63          	bltu	a4,a5,1e60 <spr_pixel+0x90>
    1dec:	00279793          	slli	a5,a5,0x2
    1df0:	00007737          	lui	a4,0x7
    1df4:	3f870713          	addi	a4,a4,1016 # 73f8 <_data+0xf00>
    1df8:	00e787b3          	add	a5,a5,a4
    1dfc:	0007a783          	lw	a5,0(a5)
    1e00:	00078067          	jr	a5
    case S_PR: return spr_player(i, j);
    1e04:	db9ff0ef          	jal	1bbc <spr_player>
}
    1e08:	00c12083          	lw	ra,12(sp)
    1e0c:	01010113          	addi	sp,sp,16
    1e10:	00008067          	ret
    case S_EN: return spr_enemy(i, j);
    1e14:	e69ff0ef          	jal	1c7c <spr_enemy>
    1e18:	ff1ff06f          	j	1e08 <spr_pixel+0x38>
    case S_SH: return spr_glow(i, j, COL_CYAN);
    1e1c:	7ff00613          	li	a2,2047
    1e20:	ef1ff0ef          	jal	1d10 <spr_glow>
    1e24:	fe5ff06f          	j	1e08 <spr_pixel+0x38>
    case S_B0: return spr_glow(i, j, 0xF81Fu);
    1e28:	00010637          	lui	a2,0x10
    1e2c:	81f60613          	addi	a2,a2,-2017 # f81f <__global_pointer$+0x7737>
    1e30:	ee1ff0ef          	jal	1d10 <spr_glow>
    1e34:	fd5ff06f          	j	1e08 <spr_pixel+0x38>
    case S_B1: return spr_glow(i, j, 0x07FFu);
    1e38:	7ff00613          	li	a2,2047
    1e3c:	ed5ff0ef          	jal	1d10 <spr_glow>
    1e40:	fc9ff06f          	j	1e08 <spr_pixel+0x38>
    case S_B2: return spr_glow(i, j, COL_AMBER);
    1e44:	00010637          	lui	a2,0x10
    1e48:	d2060613          	addi	a2,a2,-736 # fd20 <__global_pointer$+0x7c38>
    1e4c:	ec5ff0ef          	jal	1d10 <spr_glow>
    1e50:	fb9ff06f          	j	1e08 <spr_pixel+0x38>
    case S_B3: return spr_glow(i, j, COL_GREEN);
    1e54:	7e000613          	li	a2,2016
    1e58:	eb9ff0ef          	jal	1d10 <spr_glow>
    1e5c:	fadff06f          	j	1e08 <spr_pixel+0x38>
    default:   return spr_glow(i, j, COL_WHITE);
    1e60:	00010637          	lui	a2,0x10
    1e64:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f17>
    1e68:	ea9ff0ef          	jal	1d10 <spr_glow>
    1e6c:	f9dff06f          	j	1e08 <spr_pixel+0x38>

00001e70 <glyph_found>:
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    1e70:	f9f50793          	addi	a5,a0,-97
    1e74:	0ff7f793          	zext.b	a5,a5
    1e78:	01900713          	li	a4,25
    1e7c:	00f76663          	bltu	a4,a5,1e88 <glyph_found+0x18>
    1e80:	fe050513          	addi	a0,a0,-32
    1e84:	0ff57513          	zext.b	a0,a0
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return 1;
    1e88:	00000713          	li	a4,0
    1e8c:	02900793          	li	a5,41
    1e90:	02e7c463          	blt	a5,a4,1eb8 <glyph_found+0x48>
    1e94:	000077b7          	lui	a5,0x7
    1e98:	00371693          	slli	a3,a4,0x3
    1e9c:	00e686b3          	add	a3,a3,a4
    1ea0:	63878793          	addi	a5,a5,1592 # 7638 <g_font>
    1ea4:	00d787b3          	add	a5,a5,a3
    1ea8:	0007c783          	lbu	a5,0(a5)
    1eac:	00a78a63          	beq	a5,a0,1ec0 <glyph_found+0x50>
    1eb0:	00170713          	addi	a4,a4,1
    1eb4:	fd9ff06f          	j	1e8c <glyph_found+0x1c>
    return 0;
    1eb8:	00000513          	li	a0,0
    1ebc:	00008067          	ret
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return 1;
    1ec0:	00100513          	li	a0,1
}
    1ec4:	00008067          	ret

00001ec8 <glyph_of>:
    if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
    1ec8:	f9f50793          	addi	a5,a0,-97
    1ecc:	0ff7f793          	zext.b	a5,a5
    1ed0:	01900713          	li	a4,25
    1ed4:	00f76663          	bltu	a4,a5,1ee0 <glyph_of+0x18>
    1ed8:	fe050513          	addi	a0,a0,-32
    1edc:	0ff57513          	zext.b	a0,a0
    for (i = 0; i < FONT_N; i++) if (g_font[i].c == c) return g_font[i].r;
    1ee0:	00000713          	li	a4,0
    1ee4:	02900793          	li	a5,41
    1ee8:	02e7ce63          	blt	a5,a4,1f24 <glyph_of+0x5c>
    1eec:	000077b7          	lui	a5,0x7
    1ef0:	00371693          	slli	a3,a4,0x3
    1ef4:	00e686b3          	add	a3,a3,a4
    1ef8:	63878793          	addi	a5,a5,1592 # 7638 <g_font>
    1efc:	00d787b3          	add	a5,a5,a3
    1f00:	0007c783          	lbu	a5,0(a5)
    1f04:	00a78663          	beq	a5,a0,1f10 <glyph_of+0x48>
    1f08:	00170713          	addi	a4,a4,1
    1f0c:	fd9ff06f          	j	1ee4 <glyph_of+0x1c>
    1f10:	000077b7          	lui	a5,0x7
    1f14:	63878793          	addi	a5,a5,1592 # 7638 <g_font>
    1f18:	00f68533          	add	a0,a3,a5
    1f1c:	00150513          	addi	a0,a0,1
    1f20:	00008067          	ret
    return g_font[0].r;
    1f24:	00007537          	lui	a0,0x7
    1f28:	63950513          	addi	a0,a0,1593 # 7639 <g_font+0x1>
}
    1f2c:	00008067          	ret

00001f30 <tick32>:
        return *((volatile u32*) address);
    1f30:	f8b0c7b7          	lui	a5,0xf8b0c
    1f34:	ff87a503          	lw	a0,-8(a5) # f8b0bff8 <__freertos_irq_stack_top+0xf8af2df8>
static uint32_t tick32(void) { return clint_getTimeLow(BSP_CLINT); }
    1f38:	00008067          	ret

00001f3c <cpu_backoff>:
    if (n == 0u) return;
    1f3c:	00050663          	beqz	a0,1f48 <cpu_backoff+0xc>
    __asm__ __volatile__ (
    1f40:	fff50513          	addi	a0,a0,-1
    1f44:	fe051ee3          	bnez	a0,1f40 <cpu_backoff+0x4>
}
    1f48:	00008067          	ret

00001f4c <blt_wr>:
static void     blt_wr(uint32_t off, uint32_t v) { *(volatile uint32_t *)(BLT_BASE + off) = v; }
    1f4c:	f81007b7          	lui	a5,0xf8100
    1f50:	00f50533          	add	a0,a0,a5
    1f54:	00b52023          	sw	a1,0(a0)
    1f58:	00008067          	ret

00001f5c <blt_rd>:
static uint32_t blt_rd(uint32_t off)             { return *(volatile uint32_t *)(BLT_BASE + off); }
    1f5c:	f81007b7          	lui	a5,0xf8100
    1f60:	00f50533          	add	a0,a0,a5
    1f64:	00052503          	lw	a0,0(a0)
    1f68:	00008067          	ret

00001f6c <fb_of_sel>:
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
    1f6c:	00200793          	li	a5,2
    1f70:	00f50e63          	beq	a0,a5,1f8c <fb_of_sel+0x20>
    1f74:	00100793          	li	a5,1
    1f78:	00f50663          	beq	a0,a5,1f84 <fb_of_sel+0x18>
    1f7c:	00301537          	lui	a0,0x301
}
    1f80:	00008067          	ret
    return (s == 2u) ? FB_BUF2 : ((s == 1u) ? FB_BACK : FB_BASE);
    1f84:	00501537          	lui	a0,0x501
    1f88:	00008067          	ret
    1f8c:	00701537          	lui	a0,0x701
    1f90:	00008067          	ret

00001f94 <fb_stat_sel>:
static uint32_t fb_stat_sel(void) { return blt_rd(BLT_FB_STAT) & 3UL; }
    1f94:	ff010113          	addi	sp,sp,-16
    1f98:	00112623          	sw	ra,12(sp)
    1f9c:	02800513          	li	a0,40
    1fa0:	fbdff0ef          	jal	1f5c <blt_rd>
    1fa4:	00357513          	andi	a0,a0,3
    1fa8:	00c12083          	lw	ra,12(sp)
    1fac:	01010113          	addi	sp,sp,16
    1fb0:	00008067          	ret

00001fb4 <cache_evict>:
    for (i = 0; i < (uint32_t)FLUSH_WORDS; i++) s[i] = 0xA5A50000UL + i;
    1fb4:	00000793          	li	a5,0
    1fb8:	0200006f          	j	1fd8 <cache_evict+0x24>
    1fbc:	00279693          	slli	a3,a5,0x2
    1fc0:	00601737          	lui	a4,0x601
    1fc4:	00d70733          	add	a4,a4,a3
    1fc8:	a5a506b7          	lui	a3,0xa5a50
    1fcc:	00d786b3          	add	a3,a5,a3
    1fd0:	00d72023          	sw	a3,0(a4) # 601000 <__freertos_irq_stack_top+0x5e7e00>
    1fd4:	00178793          	addi	a5,a5,1 # f8100001 <__freertos_irq_stack_top+0xf80e6e01>
    1fd8:	7ff00713          	li	a4,2047
    1fdc:	fef770e3          	bgeu	a4,a5,1fbc <cache_evict+0x8>
}
    1fe0:	00008067          	ret

00001fe4 <cpu_fill32>:
    uint32_t two = (uint32_t)color | ((uint32_t)color << 16);
    1fe4:	01079e93          	slli	t4,a5,0x10
    1fe8:	00fe8eb3          	add	t4,t4,a5
    int odd = (x & 1);
    1fec:	0015ff93          	andi	t6,a1,1
    if (w <= 0 || h <= 0) return;
    1ff0:	08d05663          	blez	a3,207c <cpu_fill32+0x98>
    1ff4:	08e05463          	blez	a4,207c <cpu_fill32+0x98>
    for (j = 0; j < h; j++) {
    1ff8:	00000f13          	li	t5,0
    1ffc:	0480006f          	j	2044 <cpu_fill32+0x60>
        int rem = w;
    2000:	00068e13          	mv	t3,a3
    2004:	0700006f          	j	2074 <cpu_fill32+0x90>
            for (i = 0; i < (rem >> 1); i++) q[i] = two;
    2008:	00281893          	slli	a7,a6,0x2
    200c:	011308b3          	add	a7,t1,a7
    2010:	01d8a023          	sw	t4,0(a7)
    2014:	00180813          	addi	a6,a6,1
    2018:	401e5893          	srai	a7,t3,0x1
    201c:	ff1846e3          	blt	a6,a7,2008 <cpu_fill32+0x24>
        if (rem & 1) p[rem - 1] = color;
    2020:	001e7813          	andi	a6,t3,1
    2024:	00080e63          	beqz	a6,2040 <cpu_fill32+0x5c>
    2028:	80000837          	lui	a6,0x80000
    202c:	fff80813          	addi	a6,a6,-1 # 7fffffff <__freertos_irq_stack_top+0x7ffe6dff>
    2030:	010e0e33          	add	t3,t3,a6
    2034:	001e1e13          	slli	t3,t3,0x1
    2038:	01c30333          	add	t1,t1,t3
    203c:	00f31023          	sh	a5,0(t1)
    for (j = 0; j < h; j++) {
    2040:	001f0f13          	addi	t5,t5,1
    2044:	02ef5c63          	bge	t5,a4,207c <cpu_fill32+0x98>
        volatile uint16_t *p = (volatile uint16_t *)(base + (uint32_t)(y + j) * FB_STRIDE
    2048:	00cf0833          	add	a6,t5,a2
                                                          + (uint32_t)x * 2u);
    204c:	00481313          	slli	t1,a6,0x4
    2050:	41030333          	sub	t1,t1,a6
    2054:	00631313          	slli	t1,t1,0x6
    2058:	00b30333          	add	t1,t1,a1
    205c:	00131313          	slli	t1,t1,0x1
    2060:	00a30333          	add	t1,t1,a0
        if (odd) { *p++ = color; rem--; }
    2064:	f80f8ee3          	beqz	t6,2000 <cpu_fill32+0x1c>
    2068:	00f31023          	sh	a5,0(t1)
    206c:	fff68e13          	addi	t3,a3,-1 # a5a4ffff <__freertos_irq_stack_top+0xa5a36dff>
    2070:	00230313          	addi	t1,t1,2
            for (i = 0; i < (rem >> 1); i++) q[i] = two;
    2074:	00000813          	li	a6,0
    2078:	fa1ff06f          	j	2018 <cpu_fill32+0x34>
}
    207c:	00008067          	ret

00002080 <blt_emit>:
{
    2080:	fe010113          	addi	sp,sp,-32
    2084:	00112e23          	sw	ra,28(sp)
    2088:	00812c23          	sw	s0,24(sp)
    208c:	00912a23          	sw	s1,20(sp)
    2090:	01212823          	sw	s2,16(sp)
    2094:	01312623          	sw	s3,12(sp)
    2098:	01412423          	sw	s4,8(sp)
    209c:	01512223          	sw	s5,4(sp)
    20a0:	01612023          	sw	s6,0(sp)
    20a4:	00058b13          	mv	s6,a1
    20a8:	00060a93          	mv	s5,a2
    20ac:	00068a13          	mv	s4,a3
    20b0:	00070993          	mv	s3,a4
    20b4:	00078913          	mv	s2,a5
    20b8:	00080413          	mv	s0,a6
    20bc:	00088493          	mv	s1,a7
    if (g_attr_on) blt_wr(BLT_ATTR_PORT, attr);       /* ★ 必须在 8 个命令字之前 */
    20c0:	8ec1a783          	lw	a5,-1812(gp) # 79d4 <g_attr_on>
    20c4:	08079c63          	bnez	a5,215c <blt_emit+0xdc>
    blt_wr(BLT_CMD_FIFO_DATA, op);
    20c8:	000b0593          	mv	a1,s6
    20cc:	00800513          	li	a0,8
    20d0:	e7dff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, src);
    20d4:	000a8593          	mv	a1,s5
    20d8:	00800513          	li	a0,8
    20dc:	e71ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    20e0:	000a0593          	mv	a1,s4
    20e4:	00800513          	li	a0,8
    20e8:	e65ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ss);
    20ec:	00098593          	mv	a1,s3
    20f0:	00800513          	li	a0,8
    20f4:	e59ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ds);
    20f8:	00090593          	mv	a1,s2
    20fc:	00800513          	li	a0,8
    2100:	e4dff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, (h << 16) | (w & 0xFFFFu));
    2104:	01049593          	slli	a1,s1,0x10
    2108:	01041413          	slli	s0,s0,0x10
    210c:	01045413          	srli	s0,s0,0x10
    2110:	0085e5b3          	or	a1,a1,s0
    2114:	00800513          	li	a0,8
    2118:	e35ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, alpha);
    211c:	02012583          	lw	a1,32(sp)
    2120:	00800513          	li	a0,8
    2124:	e29ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, color);
    2128:	02412583          	lw	a1,36(sp)
    212c:	00800513          	li	a0,8
    2130:	e1dff0ef          	jal	1f4c <blt_wr>
}
    2134:	01c12083          	lw	ra,28(sp)
    2138:	01812403          	lw	s0,24(sp)
    213c:	01412483          	lw	s1,20(sp)
    2140:	01012903          	lw	s2,16(sp)
    2144:	00c12983          	lw	s3,12(sp)
    2148:	00812a03          	lw	s4,8(sp)
    214c:	00412a83          	lw	s5,4(sp)
    2150:	00012b03          	lw	s6,0(sp)
    2154:	02010113          	addi	sp,sp,32
    2158:	00008067          	ret
    if (g_attr_on) blt_wr(BLT_ATTR_PORT, attr);       /* ★ 必须在 8 个命令字之前 */
    215c:	00050593          	mv	a1,a0
    2160:	08c00513          	li	a0,140
    2164:	de9ff0ef          	jal	1f4c <blt_wr>
    2168:	f61ff06f          	j	20c8 <blt_emit+0x48>

0000216c <e_fill>:
{ blt_emit(ATTR_DEFAULT, BLT_OP_FILL, 0u, dst, 0u, ds, w, h, 0xFFu, color); }
    216c:	fd010113          	addi	sp,sp,-48
    2170:	02112623          	sw	ra,44(sp)
    2174:	02812423          	sw	s0,40(sp)
    2178:	02912223          	sw	s1,36(sp)
    217c:	03212023          	sw	s2,32(sp)
    2180:	01312e23          	sw	s3,28(sp)
    2184:	01412c23          	sw	s4,24(sp)
    2188:	00050413          	mv	s0,a0
    218c:	00058493          	mv	s1,a1
    2190:	00060913          	mv	s2,a2
    2194:	00068993          	mv	s3,a3
    2198:	00070a13          	mv	s4,a4
    219c:	00000693          	li	a3,0
    21a0:	0ff00613          	li	a2,255
    21a4:	00000593          	li	a1,0
    21a8:	00000513          	li	a0,0
    21ac:	965ff0ef          	jal	1b10 <attr_word>
    21b0:	01412223          	sw	s4,4(sp)
    21b4:	0ff00793          	li	a5,255
    21b8:	00f12023          	sw	a5,0(sp)
    21bc:	00098893          	mv	a7,s3
    21c0:	00090813          	mv	a6,s2
    21c4:	00048793          	mv	a5,s1
    21c8:	00000713          	li	a4,0
    21cc:	00040693          	mv	a3,s0
    21d0:	00000613          	li	a2,0
    21d4:	00100593          	li	a1,1
    21d8:	ea9ff0ef          	jal	2080 <blt_emit>
    21dc:	02c12083          	lw	ra,44(sp)
    21e0:	02812403          	lw	s0,40(sp)
    21e4:	02412483          	lw	s1,36(sp)
    21e8:	02012903          	lw	s2,32(sp)
    21ec:	01c12983          	lw	s3,28(sp)
    21f0:	01812a03          	lw	s4,24(sp)
    21f4:	03010113          	addi	sp,sp,48
    21f8:	00008067          	ret

000021fc <e_key>:
{ blt_emit(ATTR_DEFAULT, BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, key); }
    21fc:	fd010113          	addi	sp,sp,-48
    2200:	02112623          	sw	ra,44(sp)
    2204:	02812423          	sw	s0,40(sp)
    2208:	02912223          	sw	s1,36(sp)
    220c:	03212023          	sw	s2,32(sp)
    2210:	01312e23          	sw	s3,28(sp)
    2214:	01412c23          	sw	s4,24(sp)
    2218:	01512a23          	sw	s5,20(sp)
    221c:	01612823          	sw	s6,16(sp)
    2220:	00050413          	mv	s0,a0
    2224:	00058493          	mv	s1,a1
    2228:	00060913          	mv	s2,a2
    222c:	00068993          	mv	s3,a3
    2230:	00070a13          	mv	s4,a4
    2234:	00078a93          	mv	s5,a5
    2238:	00080b13          	mv	s6,a6
    223c:	00000693          	li	a3,0
    2240:	0ff00613          	li	a2,255
    2244:	00000593          	li	a1,0
    2248:	00000513          	li	a0,0
    224c:	8c5ff0ef          	jal	1b10 <attr_word>
    2250:	01612223          	sw	s6,4(sp)
    2254:	0ff00793          	li	a5,255
    2258:	00f12023          	sw	a5,0(sp)
    225c:	000a8893          	mv	a7,s5
    2260:	000a0813          	mv	a6,s4
    2264:	00098793          	mv	a5,s3
    2268:	00090713          	mv	a4,s2
    226c:	00048693          	mv	a3,s1
    2270:	00040613          	mv	a2,s0
    2274:	00300593          	li	a1,3
    2278:	e09ff0ef          	jal	2080 <blt_emit>
    227c:	02c12083          	lw	ra,44(sp)
    2280:	02812403          	lw	s0,40(sp)
    2284:	02412483          	lw	s1,36(sp)
    2288:	02012903          	lw	s2,32(sp)
    228c:	01c12983          	lw	s3,28(sp)
    2290:	01812a03          	lw	s4,24(sp)
    2294:	01412a83          	lw	s5,20(sp)
    2298:	01012b03          	lw	s6,16(sp)
    229c:	03010113          	addi	sp,sp,48
    22a0:	00008067          	ret

000022a4 <e_glow>:
{
    22a4:	fd010113          	addi	sp,sp,-48
    22a8:	02112623          	sw	ra,44(sp)
    22ac:	02812423          	sw	s0,40(sp)
    22b0:	02912223          	sw	s1,36(sp)
    22b4:	03212023          	sw	s2,32(sp)
    22b8:	01312e23          	sw	s3,28(sp)
    22bc:	01412c23          	sw	s4,24(sp)
    22c0:	01512a23          	sw	s5,20(sp)
    22c4:	00050413          	mv	s0,a0
    22c8:	00058493          	mv	s1,a1
    22cc:	00060913          	mv	s2,a2
    22d0:	00068993          	mv	s3,a3
    22d4:	00070a13          	mv	s4,a4
    22d8:	00078a93          	mv	s5,a5
    if (g_attr_on)
    22dc:	8ec1a783          	lw	a5,-1812(gp) # 79d4 <g_attr_on>
    22e0:	06078463          	beqz	a5,2348 <e_glow+0xa4>
    22e4:	00080613          	mv	a2,a6
        blt_emit(attr_word(ATTR_BLEND_ADD, ATTR_FMT_565, ga, 0u),
    22e8:	00000693          	li	a3,0
    22ec:	00000593          	li	a1,0
    22f0:	00200513          	li	a0,2
    22f4:	81dff0ef          	jal	1b10 <attr_word>
    22f8:	00012223          	sw	zero,4(sp)
    22fc:	0ff00793          	li	a5,255
    2300:	00f12023          	sw	a5,0(sp)
    2304:	000a8893          	mv	a7,s5
    2308:	000a0813          	mv	a6,s4
    230c:	00098793          	mv	a5,s3
    2310:	00090713          	mv	a4,s2
    2314:	00048693          	mv	a3,s1
    2318:	00040613          	mv	a2,s0
    231c:	00200593          	li	a1,2
    2320:	d61ff0ef          	jal	2080 <blt_emit>
}
    2324:	02c12083          	lw	ra,44(sp)
    2328:	02812403          	lw	s0,40(sp)
    232c:	02412483          	lw	s1,36(sp)
    2330:	02012903          	lw	s2,32(sp)
    2334:	01c12983          	lw	s3,28(sp)
    2338:	01812a03          	lw	s4,24(sp)
    233c:	01412a83          	lw	s5,20(sp)
    2340:	03010113          	addi	sp,sp,48
    2344:	00008067          	ret
        blt_emit(ATTR_DEFAULT, BLT_OP_KEY, src, dst, ss, ds, w, h, 0xFFu, TRANS_KEY);
    2348:	00000693          	li	a3,0
    234c:	0ff00613          	li	a2,255
    2350:	00000593          	li	a1,0
    2354:	00000513          	li	a0,0
    2358:	fb8ff0ef          	jal	1b10 <attr_word>
    235c:	00012223          	sw	zero,4(sp)
    2360:	0ff00793          	li	a5,255
    2364:	00f12023          	sw	a5,0(sp)
    2368:	000a8893          	mv	a7,s5
    236c:	000a0813          	mv	a6,s4
    2370:	00098793          	mv	a5,s3
    2374:	00090713          	mv	a4,s2
    2378:	00048693          	mv	a3,s1
    237c:	00040613          	mv	a2,s0
    2380:	00300593          	li	a1,3
    2384:	cfdff0ef          	jal	2080 <blt_emit>
}
    2388:	f9dff06f          	j	2324 <e_glow+0x80>

0000238c <e_alpha>:
{
    238c:	fd010113          	addi	sp,sp,-48
    2390:	02112623          	sw	ra,44(sp)
    2394:	02812423          	sw	s0,40(sp)
    2398:	02912223          	sw	s1,36(sp)
    239c:	03212023          	sw	s2,32(sp)
    23a0:	01312e23          	sw	s3,28(sp)
    23a4:	01412c23          	sw	s4,24(sp)
    23a8:	01512a23          	sw	s5,20(sp)
    23ac:	01612823          	sw	s6,16(sp)
    23b0:	00050493          	mv	s1,a0
    23b4:	00058913          	mv	s2,a1
    23b8:	00060993          	mv	s3,a2
    23bc:	00068a13          	mv	s4,a3
    23c0:	00070a93          	mv	s5,a4
    23c4:	00078b13          	mv	s6,a5
    23c8:	00080413          	mv	s0,a6
    blt_emit(ATTR_DEFAULT, BLT_OP_ALPHA, src, dst, ss, ds, w, h, alpha & 0xFFu, 0u);
    23cc:	00000693          	li	a3,0
    23d0:	0ff00613          	li	a2,255
    23d4:	00000593          	li	a1,0
    23d8:	00000513          	li	a0,0
    23dc:	f34ff0ef          	jal	1b10 <attr_word>
    23e0:	00012223          	sw	zero,4(sp)
    23e4:	0ff47413          	zext.b	s0,s0
    23e8:	00812023          	sw	s0,0(sp)
    23ec:	000b0893          	mv	a7,s6
    23f0:	000a8813          	mv	a6,s5
    23f4:	000a0793          	mv	a5,s4
    23f8:	00098713          	mv	a4,s3
    23fc:	00090693          	mv	a3,s2
    2400:	00048613          	mv	a2,s1
    2404:	00200593          	li	a1,2
    2408:	c79ff0ef          	jal	2080 <blt_emit>
}
    240c:	02c12083          	lw	ra,44(sp)
    2410:	02812403          	lw	s0,40(sp)
    2414:	02412483          	lw	s1,36(sp)
    2418:	02012903          	lw	s2,32(sp)
    241c:	01c12983          	lw	s3,28(sp)
    2420:	01812a03          	lw	s4,24(sp)
    2424:	01412a83          	lw	s5,20(sp)
    2428:	01012b03          	lw	s6,16(sp)
    242c:	03010113          	addi	sp,sp,48
    2430:	00008067          	ret

00002434 <blt_cnt>:
static uint32_t blt_cnt(void)  { return blt_rd(BLT_CMD_FIFO_COUNT); }
    2434:	ff010113          	addi	sp,sp,-16
    2438:	00112623          	sw	ra,12(sp)
    243c:	00c00513          	li	a0,12
    2440:	b1dff0ef          	jal	1f5c <blt_rd>
    2444:	00c12083          	lw	ra,12(sp)
    2448:	01010113          	addi	sp,sp,16
    244c:	00008067          	ret

00002450 <blt_stat>:
static uint32_t blt_stat(void) { return blt_rd(BLT_STATUS); }
    2450:	ff010113          	addi	sp,sp,-16
    2454:	00112623          	sw	ra,12(sp)
    2458:	00400513          	li	a0,4
    245c:	b01ff0ef          	jal	1f5c <blt_rd>
    2460:	00c12083          	lw	ra,12(sp)
    2464:	01010113          	addi	sp,sp,16
    2468:	00008067          	ret

0000246c <blt_idle_st>:
    return ((st & BLT_STATUS_DONE) && (st & BLT_STATUS_FIFO_EMPTY) &&
    246c:	00e57513          	andi	a0,a0,14
            !(st & BLT_STATUS_ERR)) ? 1 : 0;
    2470:	ff650513          	addi	a0,a0,-10 # 700ff6 <__freertos_irq_stack_top+0x6e7df6>
}
    2474:	00153513          	seqz	a0,a0
    2478:	00008067          	ret

0000247c <blt_push_room>:
{
    247c:	ff010113          	addi	sp,sp,-16
    2480:	00112623          	sw	ra,12(sp)
    uint32_t cnt = blt_cnt();
    2484:	fb1ff0ef          	jal	2434 <blt_cnt>
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    2488:	0c700793          	li	a5,199
    248c:	00a7ec63          	bltu	a5,a0,24a4 <blt_push_room+0x28>
    return (uint32_t)BLT_PUSH_LIMIT - cnt;
    2490:	0c800793          	li	a5,200
    2494:	40a78533          	sub	a0,a5,a0
}
    2498:	00c12083          	lw	ra,12(sp)
    249c:	01010113          	addi	sp,sp,16
    24a0:	00008067          	ret
    if (cnt > (uint32_t)(BLT_PUSH_LIMIT - 1u)) return 0u;
    24a4:	00000513          	li	a0,0
    24a8:	ff1ff06f          	j	2498 <blt_push_room+0x1c>

000024ac <blt_init>:
{
    24ac:	ff010113          	addi	sp,sp,-16
    24b0:	00112623          	sw	ra,12(sp)
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);
    24b4:	00400593          	li	a1,4
    24b8:	00000513          	li	a0,0
    24bc:	a91ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_IRQ_STATUS, 7u);                        /* W1C 三位全清 */
    24c0:	00700593          	li	a1,7
    24c4:	01000513          	li	a0,16
    24c8:	a85ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_IRQ_EN, 0u);
    24cc:	00000593          	li	a1,0
    24d0:	01400513          	li	a0,20
    24d4:	a79ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CTRL, BLT_CTRL_GO);
    24d8:	00100593          	li	a1,1
    24dc:	00000513          	li	a0,0
    24e0:	a6dff0ef          	jal	1f4c <blt_wr>
}
    24e4:	00c12083          	lw	ra,12(sp)
    24e8:	01010113          	addi	sp,sp,16
    24ec:	00008067          	ret

000024f0 <clr_stat>:
static uint32_t clr_stat(void) { return blt_rd(BLT_CLR_STAT); }
    24f0:	ff010113          	addi	sp,sp,-16
    24f4:	00112623          	sw	ra,12(sp)
    24f8:	04000513          	li	a0,64
    24fc:	a61ff0ef          	jal	1f5c <blt_rd>
    2500:	00c12083          	lw	ra,12(sp)
    2504:	01010113          	addi	sp,sp,16
    2508:	00008067          	ret

0000250c <clr_busy>:
static int      clr_busy(void) { return (clr_stat() & BLT_CLR_STAT_BUSY) ? 1 : 0; }
    250c:	ff010113          	addi	sp,sp,-16
    2510:	00112623          	sw	ra,12(sp)
    2514:	fddff0ef          	jal	24f0 <clr_stat>
    2518:	00157513          	andi	a0,a0,1
    251c:	00c12083          	lw	ra,12(sp)
    2520:	01010113          	addi	sp,sp,16
    2524:	00008067          	ret

00002528 <clr_is_clean>:
static int      clr_is_clean(uint32_t k) { return (int)((clr_stat() >> (2u + k)) & 1u); }
    2528:	ff010113          	addi	sp,sp,-16
    252c:	00112623          	sw	ra,12(sp)
    2530:	00812423          	sw	s0,8(sp)
    2534:	00050413          	mv	s0,a0
    2538:	fb9ff0ef          	jal	24f0 <clr_stat>
    253c:	00240413          	addi	s0,s0,2
    2540:	00855533          	srl	a0,a0,s0
    2544:	00157513          	andi	a0,a0,1
    2548:	00c12083          	lw	ra,12(sp)
    254c:	00812403          	lw	s0,8(sp)
    2550:	01010113          	addi	sp,sp,16
    2554:	00008067          	ret

00002558 <clr_wait_idle>:
{
    2558:	ff010113          	addi	sp,sp,-16
    255c:	00112623          	sw	ra,12(sp)
    2560:	00812423          	sw	s0,8(sp)
    2564:	00912223          	sw	s1,4(sp)
    uint32_t t0 = tick32();
    2568:	9c9ff0ef          	jal	1f30 <tick32>
    256c:	00050493          	mv	s1,a0
{
    2570:	00000413          	li	s0,0
    while (clr_busy()) {
    2574:	f99ff0ef          	jal	250c <clr_busy>
    2578:	04050263          	beqz	a0,25bc <clr_wait_idle+0x64>
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
    257c:	9b5ff0ef          	jal	1f30 <tick32>
    2580:	40950533          	sub	a0,a0,s1
    2584:	000f47b7          	lui	a5,0xf4
    2588:	24078793          	addi	a5,a5,576 # f4240 <__freertos_irq_stack_top+0xdb040>
    258c:	00a7ee63          	bltu	a5,a0,25a8 <clr_wait_idle+0x50>
        if (++guard > 64) { guard = 0; cpu_backoff(48u); }
    2590:	00140413          	addi	s0,s0,1
    2594:	04000793          	li	a5,64
    2598:	fc87dee3          	bge	a5,s0,2574 <clr_wait_idle+0x1c>
    259c:	03000513          	li	a0,48
    25a0:	99dff0ef          	jal	1f3c <cpu_backoff>
    25a4:	fcdff06f          	j	2570 <clr_wait_idle+0x18>
        if ((uint32_t)(tick32() - t0) > (uint32_t)CLR_WAIT_TICKS) { g_clr_to++; return 0; }
    25a8:	8d01a783          	lw	a5,-1840(gp) # 79b8 <g_clr_to>
    25ac:	00178793          	addi	a5,a5,1
    25b0:	8cf1a823          	sw	a5,-1840(gp) # 79b8 <g_clr_to>
    25b4:	00000513          	li	a0,0
    25b8:	0080006f          	j	25c0 <clr_wait_idle+0x68>
    return 1;
    25bc:	00100513          	li	a0,1
}
    25c0:	00c12083          	lw	ra,12(sp)
    25c4:	00812403          	lw	s0,8(sp)
    25c8:	00412483          	lw	s1,4(sp)
    25cc:	01010113          	addi	sp,sp,16
    25d0:	00008067          	ret

000025d4 <clr_start>:
{
    25d4:	ff010113          	addi	sp,sp,-16
    25d8:	00112623          	sw	ra,12(sp)
    25dc:	00812423          	sw	s0,8(sp)
    25e0:	00050413          	mv	s0,a0
    blt_wr(BLT_CLR_ADDR,   fb_of_sel(k) + (uint32_t)PLAY_Y0 * FB_STRIDE);
    25e4:	989ff0ef          	jal	1f6c <fb_of_sel>
    25e8:	000085b7          	lui	a1,0x8
    25ec:	80058593          	addi	a1,a1,-2048 # 7800 <__clz_tab+0xc>
    25f0:	00b505b3          	add	a1,a0,a1
    25f4:	02c00513          	li	a0,44
    25f8:	955ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CLR_STRIDE, FB_STRIDE);
    25fc:	78000593          	li	a1,1920
    2600:	03000513          	li	a0,48
    2604:	949ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CLR_WH,     ((uint32_t)PLAY_H << 16) | (uint32_t)PLAY_W);
    2608:	020c05b7          	lui	a1,0x20c0
    260c:	3c058593          	addi	a1,a1,960 # 20c03c0 <__freertos_irq_stack_top+0x20a71c0>
    2610:	03400513          	li	a0,52
    2614:	939ff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CLR_COLOR,  COL_BG);
    2618:	00800593          	li	a1,8
    261c:	03800513          	li	a0,56
    2620:	92dff0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CLR_CTRL,   ((uint32_t)k << 2) | BLT_CLR_GO);
    2624:	00241593          	slli	a1,s0,0x2
    2628:	0015e593          	ori	a1,a1,1
    262c:	03c00513          	li	a0,60
    2630:	91dff0ef          	jal	1f4c <blt_wr>
}
    2634:	00c12083          	lw	ra,12(sp)
    2638:	00812403          	lw	s0,8(sp)
    263c:	01010113          	addi	sp,sp,16
    2640:	00008067          	ret

00002644 <hw_pass_arm>:
{
    2644:	ff010113          	addi	sp,sp,-16
    2648:	00112623          	sw	ra,12(sp)
    264c:	00812423          	sw	s0,8(sp)
    2650:	00912223          	sw	s1,4(sp)
    (void)clr_wait_idle();                                     /* ① 超时交给硬件互斥兜底 */
    2654:	f05ff0ef          	jal	2558 <clr_wait_idle>
    clean_k = clr_is_clean((uint32_t)g_draw3);                 /* ② */
    2658:	8301a503          	lw	a0,-2000(gp) # 7918 <g_draw3>
    265c:	ecdff0ef          	jal	2528 <clr_is_clean>
    2660:	00050413          	mv	s0,a0
    blt_wr(BLT_DRAW_SEL, (uint32_t)g_draw3);                   /* ③ */
    2664:	8301a583          	lw	a1,-2000(gp) # 7918 <g_draw3>
    2668:	04400513          	li	a0,68
    266c:	8e1ff0ef          	jal	1f4c <blt_wr>
    if (clr_stat() & BLT_CLR_STAT_ERR) {                       /*    清掉互斥留下的 sticky 错误 */
    2670:	e81ff0ef          	jal	24f0 <clr_stat>
    2674:	04057513          	andi	a0,a0,64
    2678:	02051a63          	bnez	a0,26ac <hw_pass_arm+0x68>
    if (!clean_k) g_clr_fb++;                                  /* ④ */
    267c:	00041863          	bnez	s0,268c <hw_pass_arm+0x48>
    2680:	8d41a783          	lw	a5,-1836(gp) # 79bc <g_clr_fb>
    2684:	00178793          	addi	a5,a5,1
    2688:	8cf1aa23          	sw	a5,-1836(gp) # 79bc <g_clr_fb>
    if (g_clr_need) { clr_start((uint32_t)g_clr3); g_clr_need = 0; }   /* ⑤ */
    268c:	8dc1a783          	lw	a5,-1828(gp) # 79c4 <g_clr_need>
    2690:	04079063          	bnez	a5,26d0 <hw_pass_arm+0x8c>
}
    2694:	00143513          	seqz	a0,s0
    2698:	00c12083          	lw	ra,12(sp)
    269c:	00812403          	lw	s0,8(sp)
    26a0:	00412483          	lw	s1,4(sp)
    26a4:	01010113          	addi	sp,sp,16
    26a8:	00008067          	ret
        g_clr_err++;
    26ac:	8cc1a783          	lw	a5,-1844(gp) # 79b4 <g_clr_err>
    26b0:	00178793          	addi	a5,a5,1
    26b4:	8cf1a623          	sw	a5,-1844(gp) # 79b4 <g_clr_err>
        blt_wr(BLT_CLR_CTRL, ((uint32_t)g_draw3 << 2) | BLT_CLR_ERRCLR);
    26b8:	8301a583          	lw	a1,-2000(gp) # 7918 <g_draw3>
    26bc:	00259593          	slli	a1,a1,0x2
    26c0:	0105e593          	ori	a1,a1,16
    26c4:	03c00513          	li	a0,60
    26c8:	885ff0ef          	jal	1f4c <blt_wr>
    26cc:	fb1ff06f          	j	267c <hw_pass_arm+0x38>
    if (g_clr_need) { clr_start((uint32_t)g_clr3); g_clr_need = 0; }   /* ⑤ */
    26d0:	82c1a503          	lw	a0,-2004(gp) # 7914 <g_clr3>
    26d4:	f01ff0ef          	jal	25d4 <clr_start>
    26d8:	8c01ae23          	sw	zero,-1828(gp) # 79c4 <g_clr_need>
    26dc:	fb9ff06f          	j	2694 <hw_pass_arm+0x50>

000026e0 <uart_status_raw>:
    return *(volatile uint32_t *)(UART_TERM + UART_STATUS_OFS);
    26e0:	f80107b7          	lui	a5,0xf8010
    26e4:	0047a503          	lw	a0,4(a5) # f8010004 <__freertos_irq_stack_top+0xf7ff6e04>
}
    26e8:	00008067          	ret

000026ec <uart_poll_char>:
{
    26ec:	ff010113          	addi	sp,sp,-16
    26f0:	00112623          	sw	ra,12(sp)
    if ((uart_status_raw() >> 24) == 0u) return 0;
    26f4:	fedff0ef          	jal	26e0 <uart_status_raw>
    26f8:	01855513          	srli	a0,a0,0x18
    26fc:	00050e63          	beqz	a0,2718 <uart_poll_char+0x2c>
    return (int)(*(volatile uint32_t *)(UART_TERM + UART_DATA_OFS) & 0xFFu);
    2700:	f80107b7          	lui	a5,0xf8010
    2704:	0007a503          	lw	a0,0(a5) # f8010000 <__freertos_irq_stack_top+0xf7ff6e00>
    2708:	0ff57513          	zext.b	a0,a0
}
    270c:	00c12083          	lw	ra,12(sp)
    2710:	01010113          	addi	sp,sp,16
    2714:	00008067          	ret
    if ((uart_status_raw() >> 24) == 0u) return 0;
    2718:	00000513          	li	a0,0
    271c:	ff1ff06f          	j	270c <uart_poll_char+0x20>

00002720 <kp_hexval>:
    if (c >= '0' && c <= '9') return c - '0';
    2720:	fd050713          	addi	a4,a0,-48
    2724:	00900793          	li	a5,9
    2728:	02e7f263          	bgeu	a5,a4,274c <kp_hexval+0x2c>
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    272c:	f9f50793          	addi	a5,a0,-97
    2730:	00500713          	li	a4,5
    2734:	02f77063          	bgeu	a4,a5,2754 <kp_hexval+0x34>
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    2738:	fbf50793          	addi	a5,a0,-65
    273c:	00500713          	li	a4,5
    2740:	00f76e63          	bltu	a4,a5,275c <kp_hexval+0x3c>
    2744:	fc950513          	addi	a0,a0,-55
    2748:	00008067          	ret
    if (c >= '0' && c <= '9') return c - '0';
    274c:	00070513          	mv	a0,a4
    2750:	00008067          	ret
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    2754:	fa950513          	addi	a0,a0,-87
    2758:	00008067          	ret
    return -1;
    275c:	fff00513          	li	a0,-1
}
    2760:	00008067          	ret

00002764 <kp_feed>:
{
    2764:	00050793          	mv	a5,a0
    if (!g_kp_on) {
    2768:	8c41a503          	lw	a0,-1852(gp) # 79ac <g_kp_on>
    276c:	02051463          	bnez	a0,2794 <kp_feed+0x30>
        if (c != '@') return KP_NONE;        /* 与本包无关：原样交回命令分支 */
    2770:	04000713          	li	a4,64
    2774:	00e78463          	beq	a5,a4,277c <kp_feed+0x18>
}
    2778:	00008067          	ret
        g_kp_on = 1; g_kp_n = 0; g_kp_v = 0u;
    277c:	00100713          	li	a4,1
    2780:	8ce1a223          	sw	a4,-1852(gp) # 79ac <g_kp_on>
    2784:	8c01a023          	sw	zero,-1856(gp) # 79a8 <g_kp_n>
    2788:	8a01ae23          	sw	zero,-1860(gp) # 79a4 <g_kp_v>
        return KP_MORE;
    278c:	00100513          	li	a0,1
    2790:	00008067          	ret
    if (c == '\n' || c == '\r') {            /* 行结束：结算，必须恰好两位 */
    2794:	00a00713          	li	a4,10
    2798:	04e78a63          	beq	a5,a4,27ec <kp_feed+0x88>
    279c:	00d00713          	li	a4,13
    27a0:	04e78663          	beq	a5,a4,27ec <kp_feed+0x88>
{
    27a4:	ff010113          	addi	sp,sp,-16
    27a8:	00112623          	sw	ra,12(sp)
    h = kp_hexval(c);
    27ac:	00078513          	mv	a0,a5
    27b0:	f71ff0ef          	jal	2720 <kp_hexval>
    if (h < 0 || g_kp_n >= 2) { g_kp_on = 0; return KP_ERR; }   /* 非十六进制 / 太长：作废 */
    27b4:	04054a63          	bltz	a0,2808 <kp_feed+0xa4>
    27b8:	8c01a703          	lw	a4,-1856(gp) # 79a8 <g_kp_n>
    27bc:	00100793          	li	a5,1
    27c0:	04e7c463          	blt	a5,a4,2808 <kp_feed+0xa4>
    g_kp_v = (g_kp_v << 4) | (unsigned)h;
    27c4:	8bc1a783          	lw	a5,-1860(gp) # 79a4 <g_kp_v>
    27c8:	00479793          	slli	a5,a5,0x4
    27cc:	00a7e533          	or	a0,a5,a0
    27d0:	8aa1ae23          	sw	a0,-1860(gp) # 79a4 <g_kp_v>
    g_kp_n++;
    27d4:	00170713          	addi	a4,a4,1
    27d8:	8ce1a023          	sw	a4,-1856(gp) # 79a8 <g_kp_n>
    return KP_MORE;
    27dc:	00100513          	li	a0,1
}
    27e0:	00c12083          	lw	ra,12(sp)
    27e4:	01010113          	addi	sp,sp,16
    27e8:	00008067          	ret
        g_kp_on = 0;
    27ec:	8c01a223          	sw	zero,-1852(gp) # 79ac <g_kp_on>
        if (g_kp_n != 2) return KP_ERR;
    27f0:	8c01a503          	lw	a0,-1856(gp) # 79a8 <g_kp_n>
    27f4:	00200793          	li	a5,2
    27f8:	00f51e63          	bne	a0,a5,2814 <kp_feed+0xb0>
        *mask = g_kp_v & 0xFFu;
    27fc:	8bc1c783          	lbu	a5,-1860(gp) # 79a4 <g_kp_v>
    2800:	00f5a023          	sw	a5,0(a1)
        return KP_OK;
    2804:	00008067          	ret
    if (h < 0 || g_kp_n >= 2) { g_kp_on = 0; return KP_ERR; }   /* 非十六进制 / 太长：作废 */
    2808:	8c01a223          	sw	zero,-1852(gp) # 79ac <g_kp_on>
    280c:	fff00513          	li	a0,-1
    2810:	fd1ff06f          	j	27e0 <kp_feed+0x7c>
        if (g_kp_n != 2) return KP_ERR;
    2814:	fff00513          	li	a0,-1
    2818:	00008067          	ret

0000281c <nline_feed>:
{
    281c:	00050793          	mv	a5,a0
    if (!g_nl_on) {
    2820:	8b41a503          	lw	a0,-1868(gp) # 799c <g_nl_on>
    2824:	02051263          	bnez	a0,2848 <nline_feed+0x2c>
        if (c != '=') return NL_NONE;
    2828:	03d00713          	li	a4,61
    282c:	00e78463          	beq	a5,a4,2834 <nline_feed+0x18>
}
    2830:	00008067          	ret
        g_nl_on = 1; g_nl_n = 0;
    2834:	00100713          	li	a4,1
    2838:	8ae1aa23          	sw	a4,-1868(gp) # 799c <g_nl_on>
    283c:	8a01ac23          	sw	zero,-1864(gp) # 79a0 <g_nl_n>
        return NL_MORE;
    2840:	00100513          	li	a0,1
    2844:	00008067          	ret
    if (c == '\n' || c == '\r') {
    2848:	00a00713          	li	a4,10
    284c:	04e78263          	beq	a5,a4,2890 <nline_feed+0x74>
    2850:	00d00713          	li	a4,13
    2854:	02e78e63          	beq	a5,a4,2890 <nline_feed+0x74>
    if (c < '0' || c > '9' || g_nl_n >= (unsigned)NLINE_MAX) { g_nl_on = 0; return NL_ERR; }
    2858:	fd078713          	addi	a4,a5,-48
    285c:	00900693          	li	a3,9
    2860:	08e6ec63          	bltu	a3,a4,28f8 <nline_feed+0xdc>
    2864:	8b81a683          	lw	a3,-1864(gp) # 79a0 <g_nl_n>
    2868:	00b00713          	li	a4,11
    286c:	08d76663          	bltu	a4,a3,28f8 <nline_feed+0xdc>
    g_nl[g_nl_n++] = (char)c;
    2870:	00168613          	addi	a2,a3,1
    2874:	8ac1ac23          	sw	a2,-1864(gp) # 79a0 <g_nl_n>
    2878:	00018737          	lui	a4,0x18
    287c:	1e870713          	addi	a4,a4,488 # 181e8 <g_nl>
    2880:	00d70733          	add	a4,a4,a3
    2884:	00f70023          	sb	a5,0(a4)
    return NL_MORE;
    2888:	00100513          	li	a0,1
    288c:	00008067          	ret
        g_nl_on = 0;
    2890:	8a01aa23          	sw	zero,-1868(gp) # 799c <g_nl_on>
        if (g_nl_n == 0u) return NL_ERR;
    2894:	8b81a883          	lw	a7,-1864(gp) # 79a0 <g_nl_n>
    2898:	06088663          	beqz	a7,2904 <nline_feed+0xe8>
        for (i = 0; i < g_nl_n; i++) {
    289c:	00000513          	li	a0,0
        v = 0u;
    28a0:	00000813          	li	a6,0
    28a4:	0080006f          	j	28ac <nline_feed+0x90>
        for (i = 0; i < g_nl_n; i++) {
    28a8:	00150513          	addi	a0,a0,1
    28ac:	03157c63          	bgeu	a0,a7,28e4 <nline_feed+0xc8>
            v = v * 10u + (unsigned)(g_nl[i] - '0');
    28b0:	00281713          	slli	a4,a6,0x2
    28b4:	01070733          	add	a4,a4,a6
    28b8:	00171713          	slli	a4,a4,0x1
    28bc:	000187b7          	lui	a5,0x18
    28c0:	1e878793          	addi	a5,a5,488 # 181e8 <g_nl>
    28c4:	00a787b3          	add	a5,a5,a0
    28c8:	0007c783          	lbu	a5,0(a5)
    28cc:	00e787b3          	add	a5,a5,a4
    28d0:	fd078793          	addi	a5,a5,-48
            if (v > (unsigned)nmax) v = (unsigned)nmax;
    28d4:	00068813          	mv	a6,a3
    28d8:	fcf6e8e3          	bltu	a3,a5,28a8 <nline_feed+0x8c>
            v = v * 10u + (unsigned)(g_nl[i] - '0');
    28dc:	00078813          	mv	a6,a5
    28e0:	fc9ff06f          	j	28a8 <nline_feed+0x8c>
        if (v < (unsigned)nmin) v = (unsigned)nmin;
    28e4:	00c86463          	bltu	a6,a2,28ec <nline_feed+0xd0>
    28e8:	00080613          	mv	a2,a6
        *out = (int)v;
    28ec:	00c5a023          	sw	a2,0(a1)
        return NL_OK;
    28f0:	00200513          	li	a0,2
    28f4:	00008067          	ret
    if (c < '0' || c > '9' || g_nl_n >= (unsigned)NLINE_MAX) { g_nl_on = 0; return NL_ERR; }
    28f8:	8a01aa23          	sw	zero,-1868(gp) # 799c <g_nl_on>
    28fc:	fff00513          	li	a0,-1
    2900:	00008067          	ret
        if (g_nl_n == 0u) return NL_ERR;
    2904:	fff00513          	li	a0,-1
    2908:	00008067          	ret

0000290c <lcg>:
static uint32_t lcg(uint32_t *s) { *s = *s * 1664525u + 1013904223u; return (*s >> 16); }
    290c:	00052783          	lw	a5,0(a0)
    2910:	00196737          	lui	a4,0x196
    2914:	60d70713          	addi	a4,a4,1549 # 19660d <__freertos_irq_stack_top+0x17d40d>
    2918:	02e787b3          	mul	a5,a5,a4
    291c:	3c6ef737          	lui	a4,0x3c6ef
    2920:	35f70713          	addi	a4,a4,863 # 3c6ef35f <__freertos_irq_stack_top+0x3c6d615f>
    2924:	00e787b3          	add	a5,a5,a4
    2928:	00f52023          	sw	a5,0(a0)
    292c:	0107d513          	srli	a0,a5,0x10
    2930:	00008067          	ret

00002934 <rnd>:
static uint32_t rnd(void) { return lcg(&g_seed); }
    2934:	ff010113          	addi	sp,sp,-16
    2938:	00112623          	sw	ra,12(sp)
    293c:	82818513          	addi	a0,gp,-2008 # 7910 <g_seed>
    2940:	fcdff0ef          	jal	290c <lcg>
    2944:	00c12083          	lw	ra,12(sp)
    2948:	01010113          	addi	sp,sp,16
    294c:	00008067          	ret

00002950 <isin>:
static int isin(int a) { return (int)g_sin64[a & 63]; }
    2950:	03f57513          	andi	a0,a0,63
    2954:	000077b7          	lui	a5,0x7
    2958:	00151513          	slli	a0,a0,0x1
    295c:	5b878793          	addi	a5,a5,1464 # 75b8 <g_sin64>
    2960:	00a787b3          	add	a5,a5,a0
    2964:	00079503          	lh	a0,0(a5)
    2968:	00008067          	ret

0000296c <icos>:
static int icos(int a) { return (int)g_sin64[(a + 16) & 63]; }
    296c:	01050513          	addi	a0,a0,16
    2970:	03f57513          	andi	a0,a0,63
    2974:	000077b7          	lui	a5,0x7
    2978:	00151513          	slli	a0,a0,0x1
    297c:	5b878793          	addi	a5,a5,1464 # 75b8 <g_sin64>
    2980:	00a787b3          	add	a5,a5,a0
    2984:	00079503          	lh	a0,0(a5)
    2988:	00008067          	ret

0000298c <isqrt32>:
{
    298c:	00050713          	mv	a4,a0
    uint32_t r = 0u, b = 1u << 30;
    2990:	400007b7          	lui	a5,0x40000
    while (b > v) b >>= 2;
    2994:	0080006f          	j	299c <isqrt32+0x10>
    2998:	0027d793          	srli	a5,a5,0x2
    299c:	fef76ee3          	bltu	a4,a5,2998 <isqrt32+0xc>
    uint32_t r = 0u, b = 1u << 30;
    29a0:	00000513          	li	a0,0
    29a4:	00c0006f          	j	29b0 <isqrt32+0x24>
        if (v >= r + b) { v -= r + b; r = (r >> 1) + b; } else { r >>= 1; }
    29a8:	00155513          	srli	a0,a0,0x1
        b >>= 2;
    29ac:	0027d793          	srli	a5,a5,0x2
    while (b) {
    29b0:	00078e63          	beqz	a5,29cc <isqrt32+0x40>
        if (v >= r + b) { v -= r + b; r = (r >> 1) + b; } else { r >>= 1; }
    29b4:	00f506b3          	add	a3,a0,a5
    29b8:	fed768e3          	bltu	a4,a3,29a8 <isqrt32+0x1c>
    29bc:	40d70733          	sub	a4,a4,a3
    29c0:	00155513          	srli	a0,a0,0x1
    29c4:	00f50533          	add	a0,a0,a5
    29c8:	fe5ff06f          	j	29ac <isqrt32+0x20>
}
    29cc:	00008067          	ret

000029d0 <ent_clamp>:
    int sz = (int)e->sz;
    29d0:	00954603          	lbu	a2,9(a0)
    int x = PX(e->x), y = PX(e->y);
    29d4:	00051683          	lh	a3,0(a0)
    29d8:	4036d713          	srai	a4,a3,0x3
    29dc:	00251783          	lh	a5,2(a0)
    29e0:	4037d793          	srai	a5,a5,0x3
    if (x < 0) { x = 0; e->vx = (int16_t)(-e->vx); }
    29e4:	0606c463          	bltz	a3,2a4c <ent_clamp+0x7c>
    if (x > PLAY_W - sz) { x = PLAY_W - sz; e->vx = (int16_t)(-e->vx); }
    29e8:	3c000693          	li	a3,960
    29ec:	40c686b3          	sub	a3,a3,a2
    29f0:	00e6da63          	bge	a3,a4,2a04 <ent_clamp+0x34>
    29f4:	00455703          	lhu	a4,4(a0)
    29f8:	40e00733          	neg	a4,a4
    29fc:	00e51223          	sh	a4,4(a0)
    2a00:	00068713          	mv	a4,a3
    if (y < PLAY_Y0) { y = PLAY_Y0; e->vy = (int16_t)(-e->vy); }
    2a04:	00f00693          	li	a3,15
    2a08:	00f6ca63          	blt	a3,a5,2a1c <ent_clamp+0x4c>
    2a0c:	00655783          	lhu	a5,6(a0)
    2a10:	40f007b3          	neg	a5,a5
    2a14:	00f51323          	sh	a5,6(a0)
    2a18:	01000793          	li	a5,16
    if (y > PLAY_Y1 - sz) { y = PLAY_Y1 - sz; e->vy = (int16_t)(-e->vy); }
    2a1c:	21c00693          	li	a3,540
    2a20:	40c686b3          	sub	a3,a3,a2
    2a24:	00f6da63          	bge	a3,a5,2a38 <ent_clamp+0x68>
    2a28:	00655783          	lhu	a5,6(a0)
    2a2c:	40f007b3          	neg	a5,a5
    2a30:	00f51323          	sh	a5,6(a0)
    2a34:	00068793          	mv	a5,a3
    e->x = (int16_t)FP(x); e->y = (int16_t)FP(y);
    2a38:	00371713          	slli	a4,a4,0x3
    2a3c:	00e51023          	sh	a4,0(a0)
    2a40:	00379793          	slli	a5,a5,0x3
    2a44:	00f51123          	sh	a5,2(a0)
}
    2a48:	00008067          	ret
    if (x < 0) { x = 0; e->vx = (int16_t)(-e->vx); }
    2a4c:	00455703          	lhu	a4,4(a0)
    2a50:	40e00733          	neg	a4,a4
    2a54:	00e51223          	sh	a4,4(a0)
    2a58:	00000713          	li	a4,0
    2a5c:	f8dff06f          	j	29e8 <ent_clamp+0x18>

00002a60 <bul_alloc>:
    for (i = from; i < to; i++) if (g_bul[i].life == 0) return i;
    2a60:	0080006f          	j	2a68 <bul_alloc+0x8>
    2a64:	00150513          	addi	a0,a0,1
    2a68:	02b55463          	bge	a0,a1,2a90 <bul_alloc+0x30>
    2a6c:	000117b7          	lui	a5,0x11
    2a70:	00151713          	slli	a4,a0,0x1
    2a74:	00a70733          	add	a4,a4,a0
    2a78:	00271713          	slli	a4,a4,0x2
    2a7c:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    2a80:	00e787b3          	add	a5,a5,a4
    2a84:	00b7c783          	lbu	a5,11(a5)
    2a88:	fc079ee3          	bnez	a5,2a64 <bul_alloc+0x4>
    2a8c:	00008067          	ret
    return -1;
    2a90:	fff00513          	li	a0,-1
}
    2a94:	00008067          	ret

00002a98 <bul_alloc_enemy>:
    if (g_bul_live >= g_ncap) return -1;          /* 快路径：池满直接拒绝，不扫描 */
    2a98:	8541a783          	lw	a5,-1964(gp) # 793c <g_bul_live>
    2a9c:	81c1a583          	lw	a1,-2020(gp) # 7904 <g_ncap>
    2aa0:	02b7d263          	bge	a5,a1,2ac4 <bul_alloc_enemy+0x2c>
{
    2aa4:	ff010113          	addi	sp,sp,-16
    2aa8:	00112623          	sw	ra,12(sp)
    return bul_alloc(PLR_SLOTS, PLR_SLOTS + g_ncap);
    2aac:	02058593          	addi	a1,a1,32
    2ab0:	02000513          	li	a0,32
    2ab4:	fadff0ef          	jal	2a60 <bul_alloc>
}
    2ab8:	00c12083          	lw	ra,12(sp)
    2abc:	01010113          	addi	sp,sp,16
    2ac0:	00008067          	ret
    if (g_bul_live >= g_ncap) return -1;          /* 快路径：池满直接拒绝，不扫描 */
    2ac4:	fff00513          	li	a0,-1
}
    2ac8:	00008067          	ret

00002acc <bul_fire>:
{
    2acc:	fe010113          	addi	sp,sp,-32
    2ad0:	00112e23          	sw	ra,28(sp)
    2ad4:	00912a23          	sw	s1,20(sp)
    2ad8:	01212823          	sw	s2,16(sp)
    2adc:	01412423          	sw	s4,8(sp)
    2ae0:	01512223          	sw	s5,4(sp)
    2ae4:	01612023          	sw	s6,0(sp)
    2ae8:	00050b13          	mv	s6,a0
    2aec:	00058913          	mv	s2,a1
    2af0:	00060a93          	mv	s5,a2
    2af4:	00068a13          	mv	s4,a3
    2af8:	00070493          	mv	s1,a4
    int i = bul_alloc_enemy();
    2afc:	f9dff0ef          	jal	2a98 <bul_alloc_enemy>
    if (i < 0) return;
    2b00:	0c054663          	bltz	a0,2bcc <bul_fire+0x100>
    2b04:	00812c23          	sw	s0,24(sp)
    2b08:	01312623          	sw	s3,12(sp)
    2b0c:	00050413          	mv	s0,a0
    b->x = (int16_t)x; b->y = (int16_t)y;
    2b10:	000119b7          	lui	s3,0x11
    2b14:	00151793          	slli	a5,a0,0x1
    2b18:	00a787b3          	add	a5,a5,a0
    2b1c:	00279793          	slli	a5,a5,0x2
    2b20:	fe898993          	addi	s3,s3,-24 # 10fe8 <g_bul>
    2b24:	00f989b3          	add	s3,s3,a5
    2b28:	01699023          	sh	s6,0(s3)
    2b2c:	01299123          	sh	s2,2(s3)
    b->vx = (int16_t)((icos(ang) * spd) >> 8);
    2b30:	000a8513          	mv	a0,s5
    2b34:	e39ff0ef          	jal	296c <icos>
    2b38:	03450933          	mul	s2,a0,s4
    2b3c:	40895913          	srai	s2,s2,0x8
    2b40:	01091913          	slli	s2,s2,0x10
    2b44:	41095913          	srai	s2,s2,0x10
    2b48:	01299223          	sh	s2,4(s3)
    b->vy = (int16_t)((isin(ang) * spd) >> 8);
    2b4c:	000a8513          	mv	a0,s5
    2b50:	e01ff0ef          	jal	2950 <isin>
    2b54:	03450533          	mul	a0,a0,s4
    2b58:	40855513          	srai	a0,a0,0x8
    2b5c:	01051513          	slli	a0,a0,0x10
    2b60:	41055513          	srai	a0,a0,0x10
    2b64:	00a99323          	sh	a0,6(s3)
    if (b->vx == 0 && b->vy == 0) b->vy = 8;
    2b68:	00091863          	bnez	s2,2b78 <bul_fire+0xac>
    2b6c:	00051663          	bnez	a0,2b78 <bul_fire+0xac>
    2b70:	00800713          	li	a4,8
    2b74:	00e99323          	sh	a4,6(s3)
    b->kind = (uint8_t)(S_B0 + (variant & 3));
    2b78:	0034f493          	andi	s1,s1,3
    2b7c:	00348493          	addi	s1,s1,3
    2b80:	00011737          	lui	a4,0x11
    2b84:	fe870713          	addi	a4,a4,-24 # 10fe8 <g_bul>
    2b88:	00141693          	slli	a3,s0,0x1
    2b8c:	008687b3          	add	a5,a3,s0
    2b90:	00279793          	slli	a5,a5,0x2
    2b94:	00f707b3          	add	a5,a4,a5
    2b98:	00978423          	sb	s1,8(a5)
    b->sz   = SZ_B;
    2b9c:	01000613          	li	a2,16
    2ba0:	00c784a3          	sb	a2,9(a5)
    b->r    = 4;                       /* 敌弹判定半径（比看起来小：弹幕礼仪） */
    2ba4:	00400613          	li	a2,4
    2ba8:	00c78523          	sb	a2,10(a5)
    b->life = BULLET_LIFE;
    2bac:	00078713          	mv	a4,a5
    2bb0:	ff000793          	li	a5,-16
    2bb4:	00f705a3          	sb	a5,11(a4)
    g_bul_live++;
    2bb8:	8541a783          	lw	a5,-1964(gp) # 793c <g_bul_live>
    2bbc:	00178793          	addi	a5,a5,1
    2bc0:	84f1aa23          	sw	a5,-1964(gp) # 793c <g_bul_live>
    2bc4:	01812403          	lw	s0,24(sp)
    2bc8:	00c12983          	lw	s3,12(sp)
}
    2bcc:	01c12083          	lw	ra,28(sp)
    2bd0:	01412483          	lw	s1,20(sp)
    2bd4:	01012903          	lw	s2,16(sp)
    2bd8:	00812a03          	lw	s4,8(sp)
    2bdc:	00412a83          	lw	s5,4(sp)
    2be0:	00012b03          	lw	s6,0(sp)
    2be4:	02010113          	addi	sp,sp,32
    2be8:	00008067          	ret

00002bec <bul_fire_aim>:
{
    2bec:	fd010113          	addi	sp,sp,-48
    2bf0:	02112623          	sw	ra,44(sp)
    2bf4:	01312e23          	sw	s3,28(sp)
    2bf8:	01412c23          	sw	s4,24(sp)
    2bfc:	01512a23          	sw	s5,20(sp)
    2c00:	01612823          	sw	s6,16(sp)
    2c04:	01712623          	sw	s7,12(sp)
    2c08:	00050b93          	mv	s7,a0
    2c0c:	00058b13          	mv	s6,a1
    2c10:	00060a13          	mv	s4,a2
    2c14:	00068a93          	mv	s5,a3
    2c18:	00070993          	mv	s3,a4
    int i = bul_alloc_enemy();
    2c1c:	e7dff0ef          	jal	2a98 <bul_alloc_enemy>
    if (i < 0) return;
    2c20:	14054263          	bltz	a0,2d64 <bul_fire_aim+0x178>
    2c24:	02812423          	sw	s0,40(sp)
    2c28:	02912223          	sw	s1,36(sp)
    2c2c:	03212023          	sw	s2,32(sp)
    2c30:	00050913          	mv	s2,a0
    dx = (int)g_px - x; dy = (int)g_py - y;
    2c34:	89a19403          	lh	s0,-1894(gp) # 7982 <g_px>
    2c38:	41740433          	sub	s0,s0,s7
    2c3c:	89819483          	lh	s1,-1896(gp) # 7980 <g_py>
    2c40:	416484b3          	sub	s1,s1,s6
    d  = isqrt32((uint32_t)(dx * dx + dy * dy));
    2c44:	02840533          	mul	a0,s0,s0
    2c48:	029487b3          	mul	a5,s1,s1
    2c4c:	00f50533          	add	a0,a0,a5
    2c50:	d3dff0ef          	jal	298c <isqrt32>
    if (d < 1) d = 1;
    2c54:	12a05863          	blez	a0,2d84 <bul_fire_aim+0x198>
    px = (-dy * 256) / d; py = (dx * 256) / d;      /* 垂直单位向量（定标 256） */
    2c58:	40900733          	neg	a4,s1
    2c5c:	00871713          	slli	a4,a4,0x8
    2c60:	02a74733          	div	a4,a4,a0
    2c64:	00841693          	slli	a3,s0,0x8
    2c68:	02a6c633          	div	a2,a3,a0
    b->x = (int16_t)x; b->y = (int16_t)y;
    2c6c:	000117b7          	lui	a5,0x11
    2c70:	00191693          	slli	a3,s2,0x1
    2c74:	012686b3          	add	a3,a3,s2
    2c78:	00269693          	slli	a3,a3,0x2
    2c7c:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    2c80:	00d787b3          	add	a5,a5,a3
    2c84:	01779023          	sh	s7,0(a5)
    2c88:	01679123          	sh	s6,2(a5)
    b->vx = (int16_t)((dx * spd) / d + (px * off) / 256);
    2c8c:	03540433          	mul	s0,s0,s5
    2c90:	02a44433          	div	s0,s0,a0
    2c94:	03470733          	mul	a4,a4,s4
    2c98:	41f75693          	srai	a3,a4,0x1f
    2c9c:	0ff6f693          	zext.b	a3,a3
    2ca0:	00e68733          	add	a4,a3,a4
    2ca4:	40875713          	srai	a4,a4,0x8
    2ca8:	00e40433          	add	s0,s0,a4
    2cac:	01041413          	slli	s0,s0,0x10
    2cb0:	41045413          	srai	s0,s0,0x10
    2cb4:	00879223          	sh	s0,4(a5)
    b->vy = (int16_t)((dy * spd) / d + (py * off) / 256);
    2cb8:	035484b3          	mul	s1,s1,s5
    2cbc:	02a4c4b3          	div	s1,s1,a0
    2cc0:	034606b3          	mul	a3,a2,s4
    2cc4:	41f6d713          	srai	a4,a3,0x1f
    2cc8:	0ff77713          	zext.b	a4,a4
    2ccc:	00d70733          	add	a4,a4,a3
    2cd0:	40875713          	srai	a4,a4,0x8
    2cd4:	00e484b3          	add	s1,s1,a4
    2cd8:	01049493          	slli	s1,s1,0x10
    2cdc:	4104d493          	srai	s1,s1,0x10
    2ce0:	00979323          	sh	s1,6(a5)
    if (b->vx == 0 && b->vy == 0) b->vy = 8;
    2ce4:	02041463          	bnez	s0,2d0c <bul_fire_aim+0x120>
    2ce8:	02049263          	bnez	s1,2d0c <bul_fire_aim+0x120>
    2cec:	000117b7          	lui	a5,0x11
    2cf0:	00191713          	slli	a4,s2,0x1
    2cf4:	01270733          	add	a4,a4,s2
    2cf8:	00271713          	slli	a4,a4,0x2
    2cfc:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    2d00:	00e787b3          	add	a5,a5,a4
    2d04:	00800713          	li	a4,8
    2d08:	00e79323          	sh	a4,6(a5)
    b->kind = (uint8_t)(S_B0 + (variant & 3));
    2d0c:	0039f993          	andi	s3,s3,3
    2d10:	00398993          	addi	s3,s3,3
    2d14:	00011737          	lui	a4,0x11
    2d18:	fe870713          	addi	a4,a4,-24 # 10fe8 <g_bul>
    2d1c:	00191693          	slli	a3,s2,0x1
    2d20:	012687b3          	add	a5,a3,s2
    2d24:	00279793          	slli	a5,a5,0x2
    2d28:	00f707b3          	add	a5,a4,a5
    2d2c:	01378423          	sb	s3,8(a5)
    b->sz   = SZ_B;
    2d30:	01000613          	li	a2,16
    2d34:	00c784a3          	sb	a2,9(a5)
    b->r    = 4;
    2d38:	00400613          	li	a2,4
    2d3c:	00c78523          	sb	a2,10(a5)
    b->life = BULLET_LIFE;
    2d40:	00078713          	mv	a4,a5
    2d44:	ff000793          	li	a5,-16
    2d48:	00f705a3          	sb	a5,11(a4)
    g_bul_live++;
    2d4c:	8541a783          	lw	a5,-1964(gp) # 793c <g_bul_live>
    2d50:	00178793          	addi	a5,a5,1
    2d54:	84f1aa23          	sw	a5,-1964(gp) # 793c <g_bul_live>
    2d58:	02812403          	lw	s0,40(sp)
    2d5c:	02412483          	lw	s1,36(sp)
    2d60:	02012903          	lw	s2,32(sp)
}
    2d64:	02c12083          	lw	ra,44(sp)
    2d68:	01c12983          	lw	s3,28(sp)
    2d6c:	01812a03          	lw	s4,24(sp)
    2d70:	01412a83          	lw	s5,20(sp)
    2d74:	01012b03          	lw	s6,16(sp)
    2d78:	00c12b83          	lw	s7,12(sp)
    2d7c:	03010113          	addi	sp,sp,48
    2d80:	00008067          	ret
    if (d < 1) d = 1;
    2d84:	00100513          	li	a0,1
    2d88:	ed1ff06f          	j	2c58 <bul_fire_aim+0x6c>

00002d8c <ent_step>:
    if (e->life == 0) return 0;
    2d8c:	00b54783          	lbu	a5,11(a0)
    2d90:	08078a63          	beqz	a5,2e24 <ent_step+0x98>
    e->life--;
    2d94:	fff78793          	addi	a5,a5,-1
    2d98:	00f505a3          	sb	a5,11(a0)
    e->x = (int16_t)(e->x + e->vx);
    2d9c:	00055783          	lhu	a5,0(a0)
    2da0:	00455703          	lhu	a4,4(a0)
    2da4:	00e787b3          	add	a5,a5,a4
    2da8:	01079793          	slli	a5,a5,0x10
    2dac:	4107d793          	srai	a5,a5,0x10
    2db0:	00f51023          	sh	a5,0(a0)
    e->y = (int16_t)(e->y + e->vy);
    2db4:	00255703          	lhu	a4,2(a0)
    2db8:	00655683          	lhu	a3,6(a0)
    2dbc:	00d70733          	add	a4,a4,a3
    2dc0:	01071713          	slli	a4,a4,0x10
    2dc4:	41075713          	srai	a4,a4,0x10
    2dc8:	00e51123          	sh	a4,2(a0)
    x = PX(e->x); y = PX(e->y);
    2dcc:	4037d793          	srai	a5,a5,0x3
    2dd0:	40375713          	srai	a4,a4,0x3
    if (wrap) { ent_clamp(e); return 1; }
    2dd4:	02059463          	bnez	a1,2dfc <ent_step+0x70>
    if (x < -32 || x > PLAY_W + 32 || y < PLAY_Y0 - 48 || y > PLAY_Y1 + 48) { e->life = 0; return 0; }
    2dd8:	02078793          	addi	a5,a5,32
    2ddc:	40000693          	li	a3,1024
    2de0:	02f6ec63          	bltu	a3,a5,2e18 <ent_step+0x8c>
    2de4:	fe000793          	li	a5,-32
    2de8:	02f74863          	blt	a4,a5,2e18 <ent_step+0x8c>
    2dec:	24c00793          	li	a5,588
    2df0:	02e7c463          	blt	a5,a4,2e18 <ent_step+0x8c>
    return 1;
    2df4:	00100513          	li	a0,1
}
    2df8:	00008067          	ret
{
    2dfc:	ff010113          	addi	sp,sp,-16
    2e00:	00112623          	sw	ra,12(sp)
    if (wrap) { ent_clamp(e); return 1; }
    2e04:	bcdff0ef          	jal	29d0 <ent_clamp>
    2e08:	00100513          	li	a0,1
}
    2e0c:	00c12083          	lw	ra,12(sp)
    2e10:	01010113          	addi	sp,sp,16
    2e14:	00008067          	ret
    if (x < -32 || x > PLAY_W + 32 || y < PLAY_Y0 - 48 || y > PLAY_Y1 + 48) { e->life = 0; return 0; }
    2e18:	000505a3          	sb	zero,11(a0)
    2e1c:	00058513          	mv	a0,a1
    2e20:	00008067          	ret
    if (e->life == 0) return 0;
    2e24:	00000513          	li	a0,0
    2e28:	00008067          	ret

00002e2c <hit_cc>:
    int dx = ax - bx, dy = ay - by, rr = ar + br;
    2e2c:	40d50533          	sub	a0,a0,a3
    2e30:	40e585b3          	sub	a1,a1,a4
    2e34:	00f60633          	add	a2,a2,a5
    return (dx * dx + dy * dy) <= (rr * rr);
    2e38:	02a50533          	mul	a0,a0,a0
    2e3c:	02b585b3          	mul	a1,a1,a1
    2e40:	00b50533          	add	a0,a0,a1
    2e44:	02c60633          	mul	a2,a2,a2
    2e48:	00a62533          	slt	a0,a2,a0
}
    2e4c:	00153513          	seqz	a0,a0
    2e50:	00008067          	ret

00002e54 <enemy_fire>:
{
    2e54:	fe010113          	addi	sp,sp,-32
    2e58:	00112e23          	sw	ra,28(sp)
    2e5c:	00912a23          	sw	s1,20(sp)
    2e60:	01212823          	sw	s2,16(sp)
    2e64:	01312623          	sw	s3,12(sp)
    2e68:	00050493          	mv	s1,a0
    spd = 14 + level * 2; if (spd > 34) spd = 34;
    2e6c:	00758913          	addi	s2,a1,7
    2e70:	00191913          	slli	s2,s2,0x1
    2e74:	02200793          	li	a5,34
    2e78:	0127d463          	bge	a5,s2,2e80 <enemy_fire+0x2c>
    2e7c:	02200913          	li	s2,34
    ph  = (int)e->phase;
    2e80:	00c4c983          	lbu	s3,12(s1)
    switch (e->kind & 3) {
    2e84:	00a4c783          	lbu	a5,10(s1)
    2e88:	0037f793          	andi	a5,a5,3
    2e8c:	04078263          	beqz	a5,2ed0 <enemy_fire+0x7c>
    2e90:	00100713          	li	a4,1
    2e94:	0ce78063          	beq	a5,a4,2f54 <enemy_fire+0x100>
        bul_fire(e->x, e->y, ph, spd + 4, 2);
    2e98:	00490913          	addi	s2,s2,4
    2e9c:	00200713          	li	a4,2
    2ea0:	00090693          	mv	a3,s2
    2ea4:	00098613          	mv	a2,s3
    2ea8:	00249583          	lh	a1,2(s1)
    2eac:	00049503          	lh	a0,0(s1)
    2eb0:	c1dff0ef          	jal	2acc <bul_fire>
        bul_fire(e->x, e->y, ph + 32, spd + 4, 2);
    2eb4:	00200713          	li	a4,2
    2eb8:	00090693          	mv	a3,s2
    2ebc:	02098613          	addi	a2,s3,32
    2ec0:	00249583          	lh	a1,2(s1)
    2ec4:	00049503          	lh	a0,0(s1)
    2ec8:	c05ff0ef          	jal	2acc <bul_fire>
        break;
    2ecc:	0680006f          	j	2f34 <enemy_fire+0xe0>
    2ed0:	00812c23          	sw	s0,24(sp)
    2ed4:	01412423          	sw	s4,8(sp)
        k = 8 + level * 2 + g_ncap / 192; if (k > 24) k = 24;
    2ed8:	00458413          	addi	s0,a1,4
    2edc:	00141413          	slli	s0,s0,0x1
    2ee0:	81c1a783          	lw	a5,-2020(gp) # 7904 <g_ncap>
    2ee4:	0c000713          	li	a4,192
    2ee8:	02e7c7b3          	div	a5,a5,a4
    2eec:	00f40433          	add	s0,s0,a5
    2ef0:	01800793          	li	a5,24
    2ef4:	0087d463          	bge	a5,s0,2efc <enemy_fire+0xa8>
    2ef8:	01800413          	li	s0,24
        for (i = 0; i < k; i++) bul_fire(e->x, e->y, ph + (i * 64) / k, spd, i);
    2efc:	00000a13          	li	s4,0
    2f00:	0280006f          	j	2f28 <enemy_fire+0xd4>
    2f04:	006a1613          	slli	a2,s4,0x6
    2f08:	02864633          	div	a2,a2,s0
    2f0c:	000a0713          	mv	a4,s4
    2f10:	00090693          	mv	a3,s2
    2f14:	01360633          	add	a2,a2,s3
    2f18:	00249583          	lh	a1,2(s1)
    2f1c:	00049503          	lh	a0,0(s1)
    2f20:	badff0ef          	jal	2acc <bul_fire>
    2f24:	001a0a13          	addi	s4,s4,1
    2f28:	fc8a4ee3          	blt	s4,s0,2f04 <enemy_fire+0xb0>
    2f2c:	01812403          	lw	s0,24(sp)
    2f30:	00812a03          	lw	s4,8(sp)
    e->phase = (uint8_t)(ph + 5);
    2f34:	00598993          	addi	s3,s3,5
    2f38:	01348623          	sb	s3,12(s1)
}
    2f3c:	01c12083          	lw	ra,28(sp)
    2f40:	01412483          	lw	s1,20(sp)
    2f44:	01012903          	lw	s2,16(sp)
    2f48:	00c12983          	lw	s3,12(sp)
    2f4c:	02010113          	addi	sp,sp,32
    2f50:	00008067          	ret
    2f54:	00812c23          	sw	s0,24(sp)
    2f58:	01412423          	sw	s4,8(sp)
        k = 3 + level; if (k > 7) k = 7;
    2f5c:	00358413          	addi	s0,a1,3
    2f60:	00700793          	li	a5,7
    2f64:	0087d463          	bge	a5,s0,2f6c <enemy_fire+0x118>
    2f68:	00700413          	li	s0,7
        for (i = 0; i < k; i++) bul_fire_aim(e->x, e->y, (i - (k - 1) / 2) * 26, spd + 6, 1);
    2f6c:	00000a13          	li	s4,0
    2f70:	0380006f          	j	2fa8 <enemy_fire+0x154>
    2f74:	fff40713          	addi	a4,s0,-1
    2f78:	01f75793          	srli	a5,a4,0x1f
    2f7c:	00e787b3          	add	a5,a5,a4
    2f80:	4017d793          	srai	a5,a5,0x1
    2f84:	40fa07b3          	sub	a5,s4,a5
    2f88:	00100713          	li	a4,1
    2f8c:	00690693          	addi	a3,s2,6
    2f90:	01a00613          	li	a2,26
    2f94:	02c78633          	mul	a2,a5,a2
    2f98:	00249583          	lh	a1,2(s1)
    2f9c:	00049503          	lh	a0,0(s1)
    2fa0:	c4dff0ef          	jal	2bec <bul_fire_aim>
    2fa4:	001a0a13          	addi	s4,s4,1
    2fa8:	fc8a46e3          	blt	s4,s0,2f74 <enemy_fire+0x120>
    2fac:	01812403          	lw	s0,24(sp)
    2fb0:	00812a03          	lw	s4,8(sp)
    2fb4:	f81ff06f          	j	2f34 <enemy_fire+0xe0>

00002fb8 <cyc_of>:
    if (op == DRAW_KEY)                                 { a = CYC_A_KEY;   b = CYC_B_KEY;   }
    2fb8:	00200793          	li	a5,2
    2fbc:	02f50e63          	beq	a0,a5,2ff8 <cyc_of+0x40>
    else if (op == DRAW_GLOW || op == DRAW_ALPHA)       { a = CYC_A_ALPHA; b = CYC_B_ALPHA; }
    2fc0:	ffd50513          	addi	a0,a0,-3
    2fc4:	00100793          	li	a5,1
    2fc8:	02a7f263          	bgeu	a5,a0,2fec <cyc_of+0x34>
    else                                                { a = CYC_A_FILL;  b = CYC_B_FILL;  }
    2fcc:	40100793          	li	a5,1025
    2fd0:	0fc00513          	li	a0,252
    return a + ((uint32_t)(sz * sz) * b) / 1000u;
    2fd4:	02b585b3          	mul	a1,a1,a1
    2fd8:	02f585b3          	mul	a1,a1,a5
    2fdc:	3e800793          	li	a5,1000
    2fe0:	02f5d5b3          	divu	a1,a1,a5
}
    2fe4:	00a58533          	add	a0,a1,a0
    2fe8:	00008067          	ret
    else if (op == DRAW_GLOW || op == DRAW_ALPHA)       { a = CYC_A_ALPHA; b = CYC_B_ALPHA; }
    2fec:	5fd00793          	li	a5,1533
    2ff0:	1d000513          	li	a0,464
    2ff4:	fe1ff06f          	j	2fd4 <cyc_of+0x1c>
    if (op == DRAW_KEY)                                 { a = CYC_A_KEY;   b = CYC_B_KEY;   }
    2ff8:	4e700793          	li	a5,1255
    2ffc:	18e00513          	li	a0,398
    3000:	fd5ff06f          	j	2fd4 <cyc_of+0x1c>

00003004 <cost_capacity>:
{
    3004:	ff010113          	addi	sp,sp,-16
    3008:	00112623          	sw	ra,12(sp)
    300c:	00812423          	sw	s0,8(sp)
    3010:	00912223          	sw	s1,4(sp)
    3014:	01212023          	sw	s2,0(sp)
    3018:	00050413          	mv	s0,a0
    301c:	00060493          	mv	s1,a2
    3020:	00068913          	mv	s2,a3
    uint32_t per = cyc_of(op, sz);
    3024:	f95ff0ef          	jal	2fb8 <cyc_of>
                 : ((op == DRAW_GLOW || op == DRAW_ALPHA) ? CYC_A_ALPHA : CYC_A_FILL);
    3028:	00200793          	li	a5,2
    302c:	04f40c63          	beq	s0,a5,3084 <cost_capacity+0x80>
    3030:	ffd40413          	addi	s0,s0,-3
    3034:	00100793          	li	a5,1
    3038:	0487f263          	bgeu	a5,s0,307c <cost_capacity+0x78>
    303c:	0fc00713          	li	a4,252
    uint32_t budget = (FRAME_TICKS_60FPS / 100u) * (uint32_t)pct;
    3040:	000047b7          	lui	a5,0x4
    3044:	11a78793          	addi	a5,a5,282 # 411a <osd_text+0x66>
    3048:	02f484b3          	mul	s1,s1,a5
    if (dual) per = a + (per - a) / 2u;
    304c:	00090863          	beqz	s2,305c <cost_capacity+0x58>
    3050:	40e50533          	sub	a0,a0,a4
    3054:	00155513          	srli	a0,a0,0x1
    3058:	00e50533          	add	a0,a0,a4
    if (per == 0u) return 0u;
    305c:	00050463          	beqz	a0,3064 <cost_capacity+0x60>
    return budget / per;
    3060:	02a4d533          	divu	a0,s1,a0
}
    3064:	00c12083          	lw	ra,12(sp)
    3068:	00812403          	lw	s0,8(sp)
    306c:	00412483          	lw	s1,4(sp)
    3070:	00012903          	lw	s2,0(sp)
    3074:	01010113          	addi	sp,sp,16
    3078:	00008067          	ret
                 : ((op == DRAW_GLOW || op == DRAW_ALPHA) ? CYC_A_ALPHA : CYC_A_FILL);
    307c:	1d000713          	li	a4,464
    3080:	fc1ff06f          	j	3040 <cost_capacity+0x3c>
    3084:	18e00713          	li	a4,398
    3088:	fb9ff06f          	j	3040 <cost_capacity+0x3c>

0000308c <ramp_apply>:
{
    308c:	00050793          	mv	a5,a0
    int prev = *ncap;
    3090:	0005a703          	lw	a4,0(a1)
    if (!*auto_on) return 0;
    3094:	0006a503          	lw	a0,0(a3)
    3098:	0a050063          	beqz	a0,3138 <ramp_apply+0xac>
    if (fps <= 0) return 0;                       /* 还没有效窗口 */
    309c:	08f05c63          	blez	a5,3134 <ramp_apply+0xa8>
    if (fps >= 58) {
    30a0:	03900513          	li	a0,57
    30a4:	04f55c63          	bge	a0,a5,30fc <ramp_apply+0x70>
        step = prev / 8;
    30a8:	41f75793          	srai	a5,a4,0x1f
    30ac:	0077f793          	andi	a5,a5,7
    30b0:	00e787b3          	add	a5,a5,a4
    30b4:	4037d793          	srai	a5,a5,0x3
        if (step < N_STEP) step = N_STEP;
    30b8:	1ff00513          	li	a0,511
    30bc:	00e54463          	blt	a0,a4,30c4 <ramp_apply+0x38>
    30c0:	04000793          	li	a5,64
        if (prev + step >= N_MAX) { *ncap = N_MAX; *lim_n = N_MAX; *auto_on = 0; return 2; }
    30c4:	00e787b3          	add	a5,a5,a4
    30c8:	00001737          	lui	a4,0x1
    30cc:	95f70713          	addi	a4,a4,-1697 # 95f <CUSTOM2+0x904>
    30d0:	00f74863          	blt	a4,a5,30e0 <ramp_apply+0x54>
        *ncap = prev + step;
    30d4:	00f5a023          	sw	a5,0(a1)
        return 1;
    30d8:	00100513          	li	a0,1
    30dc:	00008067          	ret
        if (prev + step >= N_MAX) { *ncap = N_MAX; *lim_n = N_MAX; *auto_on = 0; return 2; }
    30e0:	000017b7          	lui	a5,0x1
    30e4:	96078793          	addi	a5,a5,-1696 # 960 <CUSTOM2+0x905>
    30e8:	00f5a023          	sw	a5,0(a1)
    30ec:	00f62023          	sw	a5,0(a2)
    30f0:	0006a023          	sw	zero,0(a3)
    30f4:	00200513          	li	a0,2
    30f8:	00008067          	ret
    *ncap = (prev > N_MIN) ? (prev - prev / 8) : N_MIN;
    30fc:	04000793          	li	a5,64
    3100:	02e7d663          	bge	a5,a4,312c <ramp_apply+0xa0>
    3104:	41f75793          	srai	a5,a4,0x1f
    3108:	0077f793          	andi	a5,a5,7
    310c:	00e787b3          	add	a5,a5,a4
    3110:	4037d793          	srai	a5,a5,0x3
    3114:	40f70733          	sub	a4,a4,a5
    3118:	00e5a023          	sw	a4,0(a1)
    *lim_n = *ncap;
    311c:	00e62023          	sw	a4,0(a2)
    *auto_on = 0;
    3120:	0006a023          	sw	zero,0(a3)
    return -1;
    3124:	fff00513          	li	a0,-1
    3128:	00008067          	ret
    *ncap = (prev > N_MIN) ? (prev - prev / 8) : N_MIN;
    312c:	04000713          	li	a4,64
    3130:	fe9ff06f          	j	3118 <ramp_apply+0x8c>
    if (fps <= 0) return 0;                       /* 还没有效窗口 */
    3134:	00000513          	li	a0,0
}
    3138:	00008067          	ret

0000313c <dl_push>:
    if (g_dl_n >= DRAW_MAX) return;
    313c:	8b01ae03          	lw	t3,-1872(gp) # 7998 <g_dl_n>
    3140:	00001337          	lui	t1,0x1
    3144:	a1f30313          	addi	t1,t1,-1505 # a1f <CUSTOM2+0x9c4>
    3148:	05c34863          	blt	t1,t3,3198 <dl_push+0x5c>
    d = &g_dl[g_dl_n++];
    314c:	001e0e93          	addi	t4,t3,1
    3150:	8bd1a823          	sw	t4,-1872(gp) # 7998 <g_dl_n>
    d->x = (int16_t)x; d->y = (int16_t)y;
    3154:	00008eb7          	lui	t4,0x8
    3158:	c28e8e93          	addi	t4,t4,-984 # 7c28 <g_dl>
    315c:	003e1f13          	slli	t5,t3,0x3
    3160:	41cf0333          	sub	t1,t5,t3
    3164:	00131313          	slli	t1,t1,0x1
    3168:	006e8333          	add	t1,t4,t1
    316c:	00b31023          	sh	a1,0(t1)
    3170:	00c31123          	sh	a2,2(t1)
    d->arg = arg; d->op = op;
    3174:	00d31223          	sh	a3,4(t1)
    3178:	00a30323          	sb	a0,6(t1)
    d->w = (uint8_t)w; d->h = (uint8_t)h;
    317c:	00e303a3          	sb	a4,7(t1)
    3180:	00f30423          	sb	a5,8(t1)
    d->ga = ga; d->sx = sx; d->sy = sy; d->rsv = 0;
    3184:	010304a3          	sb	a6,9(t1)
    3188:	01130523          	sb	a7,10(t1)
    318c:	00014783          	lbu	a5,0(sp)
    3190:	00f305a3          	sb	a5,11(t1)
    3194:	00030623          	sb	zero,12(t1)
}
    3198:	00008067          	ret

0000319c <dl_rect_op>:
{
    319c:	00058e13          	mv	t3,a1
    int x0 = PX(cx) - sz / 2, y0 = PX(cy) - sz / 2;
    31a0:	40365893          	srai	a7,a2,0x3
    31a4:	01f75613          	srli	a2,a4,0x1f
    31a8:	00e60633          	add	a2,a2,a4
    31ac:	40165613          	srai	a2,a2,0x1
    31b0:	40c00633          	neg	a2,a2
    31b4:	00c885b3          	add	a1,a7,a2
    31b8:	4036d693          	srai	a3,a3,0x3
    31bc:	00d60633          	add	a2,a2,a3
    int x1 = x0 + sz, y1 = y0 + sz;
    31c0:	00b70333          	add	t1,a4,a1
    31c4:	00c70733          	add	a4,a4,a2
    if (x0 < 0)                { sx = -x0; x0 = 0; }
    31c8:	0405c663          	bltz	a1,3214 <dl_rect_op+0x78>
    int sx = 0, sy = 0;
    31cc:	00000893          	li	a7,0
    if (y0 < PLAY_Y0)          { sy = PLAY_Y0 - y0; y0 = PLAY_Y0; }
    31d0:	00f00693          	li	a3,15
    31d4:	04c6c663          	blt	a3,a2,3220 <dl_rect_op+0x84>
    31d8:	01000693          	li	a3,16
    31dc:	40c686b3          	sub	a3,a3,a2
    31e0:	01000613          	li	a2,16
    if (x1 > FB_WIDTH)         x1 = FB_WIDTH;
    31e4:	3c000813          	li	a6,960
    31e8:	00685463          	bge	a6,t1,31f0 <dl_rect_op+0x54>
    31ec:	3c000313          	li	t1,960
    if (y1 > FB_HEIGHT)        y1 = FB_HEIGHT;
    31f0:	21c00813          	li	a6,540
    31f4:	00e85463          	bge	a6,a4,31fc <dl_rect_op+0x60>
    31f8:	21c00713          	li	a4,540
    if (x1 <= x0 || y1 <= y0)  { g_clip_drop++; return; }      /* 完全在区外 */
    31fc:	0065d463          	bge	a1,t1,3204 <dl_rect_op+0x68>
    3200:	02e64463          	blt	a2,a4,3228 <dl_rect_op+0x8c>
    3204:	8a81a783          	lw	a5,-1880(gp) # 7990 <g_clip_drop>
    3208:	00178793          	addi	a5,a5,1
    320c:	8af1a423          	sw	a5,-1880(gp) # 7990 <g_clip_drop>
    3210:	00008067          	ret
    if (x0 < 0)                { sx = -x0; x0 = 0; }
    3214:	40b008b3          	neg	a7,a1
    3218:	00000593          	li	a1,0
    321c:	fb5ff06f          	j	31d0 <dl_rect_op+0x34>
    int sx = 0, sy = 0;
    3220:	00000693          	li	a3,0
    3224:	fc1ff06f          	j	31e4 <dl_rect_op+0x48>
{
    3228:	fe010113          	addi	sp,sp,-32
    322c:	00112e23          	sw	ra,28(sp)
    dl_push((uint8_t)op, x0, y0, arg, x1 - x0, y1 - y0, ga, (uint8_t)sx, (uint8_t)sy);
    3230:	0ff6f693          	zext.b	a3,a3
    3234:	00d12023          	sw	a3,0(sp)
    3238:	0ff8f893          	zext.b	a7,a7
    323c:	00078813          	mv	a6,a5
    3240:	40c707b3          	sub	a5,a4,a2
    3244:	40b30733          	sub	a4,t1,a1
    3248:	000e0693          	mv	a3,t3
    324c:	0ff57513          	zext.b	a0,a0
    3250:	eedff0ef          	jal	313c <dl_push>
}
    3254:	01c12083          	lw	ra,28(sp)
    3258:	02010113          	addi	sp,sp,32
    325c:	00008067          	ret

00003260 <dl_sprite>:
{
    3260:	ff010113          	addi	sp,sp,-16
    3264:	00112623          	sw	ra,12(sp)
    3268:	00050813          	mv	a6,a0
    326c:	00068793          	mv	a5,a3
    dl_rect_op((spr == S_PR || spr == S_EN) ? DRAW_KEY : DRAW_GLOW,
    3270:	00100713          	li	a4,1
    3274:	02a77a63          	bgeu	a4,a0,32a8 <dl_sprite+0x48>
    3278:	00300513          	li	a0,3
               (uint16_t)spr, cx, cy, (int)g_spr_sz[spr], ga);
    327c:	84018713          	addi	a4,gp,-1984 # 7928 <g_spr_sz>
    3280:	01070733          	add	a4,a4,a6
    dl_rect_op((spr == S_PR || spr == S_EN) ? DRAW_KEY : DRAW_GLOW,
    3284:	00074703          	lbu	a4,0(a4)
    3288:	00060693          	mv	a3,a2
    328c:	00058613          	mv	a2,a1
    3290:	01081593          	slli	a1,a6,0x10
    3294:	0105d593          	srli	a1,a1,0x10
    3298:	f05ff0ef          	jal	319c <dl_rect_op>
}
    329c:	00c12083          	lw	ra,12(sp)
    32a0:	01010113          	addi	sp,sp,16
    32a4:	00008067          	ret
    dl_rect_op((spr == S_PR || spr == S_EN) ? DRAW_KEY : DRAW_GLOW,
    32a8:	00200513          	li	a0,2
    32ac:	fd1ff06f          	j	327c <dl_sprite+0x1c>

000032b0 <dl_bullet>:
{
    32b0:	ff010113          	addi	sp,sp,-16
    32b4:	00112623          	sw	ra,12(sp)
    int sz = (int)b->sz;
    32b8:	00954703          	lbu	a4,9(a0)
    switch (g_bulm) {
    32bc:	8381a783          	lw	a5,-1992(gp) # 7920 <g_bulm>
    32c0:	00100693          	li	a3,1
    32c4:	04d78463          	beq	a5,a3,330c <dl_bullet+0x5c>
    32c8:	00200693          	li	a3,2
    32cc:	04d78e63          	beq	a5,a3,3328 <dl_bullet+0x78>
    32d0:	06079a63          	bnez	a5,3344 <dl_bullet+0x94>
        dl_rect_op(DRAW_FILL, g_spr_fill[b->kind], b->x, b->y, sz, 0u);
    32d4:	00854783          	lbu	a5,8(a0)
    32d8:	000075b7          	lui	a1,0x7
    32dc:	00179793          	slli	a5,a5,0x1
    32e0:	7b458593          	addi	a1,a1,1972 # 77b4 <g_spr_fill>
    32e4:	00f585b3          	add	a1,a1,a5
    32e8:	00000793          	li	a5,0
    32ec:	00251683          	lh	a3,2(a0)
    32f0:	00051603          	lh	a2,0(a0)
    32f4:	0005d583          	lhu	a1,0(a1)
    32f8:	00100513          	li	a0,1
    32fc:	ea1ff0ef          	jal	319c <dl_rect_op>
}
    3300:	00c12083          	lw	ra,12(sp)
    3304:	01010113          	addi	sp,sp,16
    3308:	00008067          	ret
        dl_rect_op(DRAW_ALPHA, (uint16_t)b->kind, b->x, b->y, sz, BUL_ALPHA_V);
    330c:	0a000793          	li	a5,160
    3310:	00251683          	lh	a3,2(a0)
    3314:	00051603          	lh	a2,0(a0)
    3318:	00854583          	lbu	a1,8(a0)
    331c:	00400513          	li	a0,4
    3320:	e7dff0ef          	jal	319c <dl_rect_op>
        break;
    3324:	fddff06f          	j	3300 <dl_bullet+0x50>
        dl_rect_op(DRAW_GLOW, (uint16_t)b->kind, b->x, b->y, sz, 255u);
    3328:	0ff00793          	li	a5,255
    332c:	00251683          	lh	a3,2(a0)
    3330:	00051603          	lh	a2,0(a0)
    3334:	00854583          	lbu	a1,8(a0)
    3338:	00300513          	li	a0,3
    333c:	e61ff0ef          	jal	319c <dl_rect_op>
        break;
    3340:	fc1ff06f          	j	3300 <dl_bullet+0x50>
        dl_rect_op(DRAW_KEY, (uint16_t)b->kind, b->x, b->y, sz, 0u);
    3344:	00000793          	li	a5,0
    3348:	00251683          	lh	a3,2(a0)
    334c:	00051603          	lh	a2,0(a0)
    3350:	00854583          	lbu	a1,8(a0)
    3354:	00200513          	li	a0,2
    3358:	e45ff0ef          	jal	319c <dl_rect_op>
}
    335c:	fa5ff06f          	j	3300 <dl_bullet+0x50>

00003360 <build_draw_list>:
{
    3360:	fe010113          	addi	sp,sp,-32
    3364:	00112e23          	sw	ra,28(sp)
    3368:	00812c23          	sw	s0,24(sp)
    g_dl_n = 0;
    336c:	8a01a823          	sw	zero,-1872(gp) # 7998 <g_dl_n>
    g_clip_drop = 0;
    3370:	8a01a423          	sw	zero,-1880(gp) # 7990 <g_clip_drop>
    if (repaint) dl_push(DRAW_FILL_FULL, 0, PLAY_Y0, COL_BG, 0, 0, 0u, 0u, 0u);
    3374:	00051663          	bnez	a0,3380 <build_draw_list+0x20>
        if (sy > PLAY_Y1 - 2)  sy = PLAY_Y1 - 2;
    3378:	00000413          	li	s0,0
    337c:	0640006f          	j	33e0 <build_draw_list+0x80>
    if (repaint) dl_push(DRAW_FILL_FULL, 0, PLAY_Y0, COL_BG, 0, 0, 0u, 0u, 0u);
    3380:	00012023          	sw	zero,0(sp)
    3384:	00000893          	li	a7,0
    3388:	00000813          	li	a6,0
    338c:	00000793          	li	a5,0
    3390:	00000713          	li	a4,0
    3394:	00800693          	li	a3,8
    3398:	01000613          	li	a2,16
    339c:	00000593          	li	a1,0
    33a0:	00000513          	li	a0,0
    33a4:	d99ff0ef          	jal	313c <dl_push>
    33a8:	fd1ff06f          	j	3378 <build_draw_list+0x18>
        dl_push(DRAW_FILL, sx, sy, g_star[i].col, 2, 2, 0u, 0u, 0u);
    33ac:	000086b7          	lui	a3,0x8
    33b0:	00341793          	slli	a5,s0,0x3
    33b4:	a2868693          	addi	a3,a3,-1496 # 7a28 <g_star>
    33b8:	00f686b3          	add	a3,a3,a5
    33bc:	00012023          	sw	zero,0(sp)
    33c0:	00000893          	li	a7,0
    33c4:	00000813          	li	a6,0
    33c8:	00200793          	li	a5,2
    33cc:	00200713          	li	a4,2
    33d0:	0046d683          	lhu	a3,4(a3)
    33d4:	00100513          	li	a0,1
    33d8:	d65ff0ef          	jal	313c <dl_push>
    for (i = 0; i < g_star_n; i++) {
    33dc:	00140413          	addi	s0,s0,1
    33e0:	8241a783          	lw	a5,-2012(gp) # 790c <g_star_n>
    33e4:	02f45c63          	bge	s0,a5,341c <build_draw_list+0xbc>
        int sx = g_star[i].x, sy = g_star[i].y;
    33e8:	000087b7          	lui	a5,0x8
    33ec:	00341713          	slli	a4,s0,0x3
    33f0:	a2878793          	addi	a5,a5,-1496 # 7a28 <g_star>
    33f4:	00e787b3          	add	a5,a5,a4
    33f8:	00079583          	lh	a1,0(a5)
    33fc:	00279603          	lh	a2,2(a5)
        if (sx > FB_WIDTH - 2) sx = FB_WIDTH - 2;               /* 2x2 不许出右边界 */
    3400:	3be00793          	li	a5,958
    3404:	00b7d463          	bge	a5,a1,340c <build_draw_list+0xac>
    3408:	3be00593          	li	a1,958
        if (sy > PLAY_Y1 - 2)  sy = PLAY_Y1 - 2;
    340c:	21a00793          	li	a5,538
    3410:	f8c7dee3          	bge	a5,a2,33ac <build_draw_list+0x4c>
    3414:	21a00613          	li	a2,538
    3418:	f95ff06f          	j	33ac <build_draw_list+0x4c>
    for (i = 0; i < BUL_TOTAL; i++)
    341c:	00000413          	li	s0,0
    3420:	0340006f          	j	3454 <build_draw_list+0xf4>
            if (i < PLR_SLOTS) dl_sprite(g_bul[i].kind, g_bul[i].x, g_bul[i].y, 255u); /* 自机弹固定加算 */
    3424:	000117b7          	lui	a5,0x11
    3428:	00141713          	slli	a4,s0,0x1
    342c:	00870733          	add	a4,a4,s0
    3430:	00271713          	slli	a4,a4,0x2
    3434:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    3438:	00e787b3          	add	a5,a5,a4
    343c:	0ff00693          	li	a3,255
    3440:	00279603          	lh	a2,2(a5)
    3444:	00079583          	lh	a1,0(a5)
    3448:	0087c503          	lbu	a0,8(a5)
    344c:	e15ff0ef          	jal	3260 <dl_sprite>
    for (i = 0; i < BUL_TOTAL; i++)
    3450:	00140413          	addi	s0,s0,1
    3454:	000017b7          	lui	a5,0x1
    3458:	97f78793          	addi	a5,a5,-1665 # 97f <CUSTOM2+0x924>
    345c:	0487c663          	blt	a5,s0,34a8 <build_draw_list+0x148>
        if (g_bul[i].life) {
    3460:	000117b7          	lui	a5,0x11
    3464:	00141713          	slli	a4,s0,0x1
    3468:	00870733          	add	a4,a4,s0
    346c:	00271713          	slli	a4,a4,0x2
    3470:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    3474:	00e787b3          	add	a5,a5,a4
    3478:	00b7c783          	lbu	a5,11(a5)
    347c:	fc078ae3          	beqz	a5,3450 <build_draw_list+0xf0>
            if (i < PLR_SLOTS) dl_sprite(g_bul[i].kind, g_bul[i].x, g_bul[i].y, 255u); /* 自机弹固定加算 */
    3480:	01f00793          	li	a5,31
    3484:	fa87d0e3          	bge	a5,s0,3424 <build_draw_list+0xc4>
            else               dl_bullet(&g_bul[i]);                                  /* 敌弹按 g_bulm */
    3488:	00141793          	slli	a5,s0,0x1
    348c:	008787b3          	add	a5,a5,s0
    3490:	00279793          	slli	a5,a5,0x2
    3494:	00011537          	lui	a0,0x11
    3498:	fe850513          	addi	a0,a0,-24 # 10fe8 <g_bul>
    349c:	00f50533          	add	a0,a0,a5
    34a0:	e11ff0ef          	jal	32b0 <dl_bullet>
    34a4:	fadff06f          	j	3450 <build_draw_list+0xf0>
    for (i = 0; i < ENEMY_MAX; i++)
    34a8:	00000413          	li	s0,0
    34ac:	0080006f          	j	34b4 <build_draw_list+0x154>
    34b0:	00140413          	addi	s0,s0,1
    34b4:	01700793          	li	a5,23
    34b8:	0487c063          	blt	a5,s0,34f8 <build_draw_list+0x198>
        if (g_en[i].t) dl_sprite(S_EN, g_en[i].x, g_en[i].y, 0u);
    34bc:	000117b7          	lui	a5,0x11
    34c0:	00441713          	slli	a4,s0,0x4
    34c4:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    34c8:	00e787b3          	add	a5,a5,a4
    34cc:	00e79783          	lh	a5,14(a5)
    34d0:	fe0780e3          	beqz	a5,34b0 <build_draw_list+0x150>
    34d4:	000117b7          	lui	a5,0x11
    34d8:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    34dc:	00e787b3          	add	a5,a5,a4
    34e0:	00000693          	li	a3,0
    34e4:	00279603          	lh	a2,2(a5)
    34e8:	00079583          	lh	a1,0(a5)
    34ec:	00100513          	li	a0,1
    34f0:	d71ff0ef          	jal	3260 <dl_sprite>
    34f4:	fbdff06f          	j	34b0 <build_draw_list+0x150>
    if (g_state != GS_OVER && !(g_invuln && ((g_frames >> 1) & 1u)))
    34f8:	8a41a703          	lw	a4,-1884(gp) # 798c <g_state>
    34fc:	00200793          	li	a5,2
    3500:	02f70663          	beq	a4,a5,352c <build_draw_list+0x1cc>
    3504:	8941a783          	lw	a5,-1900(gp) # 797c <g_invuln>
    3508:	00078863          	beqz	a5,3518 <build_draw_list+0x1b8>
    350c:	8741a783          	lw	a5,-1932(gp) # 795c <g_frames>
    3510:	0027f793          	andi	a5,a5,2
    3514:	00079c63          	bnez	a5,352c <build_draw_list+0x1cc>
        dl_sprite(S_PR, g_px, g_py, 0u);
    3518:	00000693          	li	a3,0
    351c:	89819603          	lh	a2,-1896(gp) # 7980 <g_py>
    3520:	89a19583          	lh	a1,-1894(gp) # 7982 <g_px>
    3524:	00000513          	li	a0,0
    3528:	d39ff0ef          	jal	3260 <dl_sprite>
        if (a > 255u) a = 255u;
    352c:	00000413          	li	s0,0
    3530:	0340006f          	j	3564 <build_draw_list+0x204>
        dl_sprite(S_SP, g_spk[i].x, g_spk[i].y, (uint8_t)a);
    3534:	000117b7          	lui	a5,0x11
    3538:	00141713          	slli	a4,s0,0x1
    353c:	00870733          	add	a4,a4,s0
    3540:	00271713          	slli	a4,a4,0x2
    3544:	b6878793          	addi	a5,a5,-1176 # 10b68 <g_spk>
    3548:	00e787b3          	add	a5,a5,a4
    354c:	0ff6f693          	zext.b	a3,a3
    3550:	00279603          	lh	a2,2(a5)
    3554:	00079583          	lh	a1,0(a5)
    3558:	00700513          	li	a0,7
    355c:	d05ff0ef          	jal	3260 <dl_sprite>
    for (i = 0; i < SPARK_MAX; i++) {
    3560:	00140413          	addi	s0,s0,1
    3564:	05f00793          	li	a5,95
    3568:	0487c463          	blt	a5,s0,35b0 <build_draw_list+0x250>
        if (!g_spk[i].life) continue;
    356c:	000117b7          	lui	a5,0x11
    3570:	00141713          	slli	a4,s0,0x1
    3574:	00870733          	add	a4,a4,s0
    3578:	00271713          	slli	a4,a4,0x2
    357c:	b6878793          	addi	a5,a5,-1176 # 10b68 <g_spk>
    3580:	00e787b3          	add	a5,a5,a4
    3584:	00b7c703          	lbu	a4,11(a5)
    3588:	fc070ce3          	beqz	a4,3560 <build_draw_list+0x200>
        a = (unsigned)g_spk[i].life * 255u / 20u;
    358c:	00871793          	slli	a5,a4,0x8
    3590:	40e787b3          	sub	a5,a5,a4
    3594:	01400693          	li	a3,20
    3598:	02d7d6b3          	divu	a3,a5,a3
        if (a > 255u) a = 255u;
    359c:	00001737          	lui	a4,0x1
    35a0:	3ff70713          	addi	a4,a4,1023 # 13ff <main+0x2fb>
    35a4:	f8f778e3          	bgeu	a4,a5,3534 <build_draw_list+0x1d4>
    35a8:	0ff00693          	li	a3,255
    35ac:	f89ff06f          	j	3534 <build_draw_list+0x1d4>
}
    35b0:	01c12083          	lw	ra,28(sp)
    35b4:	01812403          	lw	s0,24(sp)
    35b8:	02010113          	addi	sp,sp,32
    35bc:	00008067          	ret

000035c0 <dl_sprite_count>:
    int i, n = 0;
    35c0:	00000513          	li	a0,0
    for (i = 0; i < g_dl_n; i++) if (g_dl[i].op != DRAW_FILL_FULL) n++;
    35c4:	00000713          	li	a4,0
    35c8:	0080006f          	j	35d0 <dl_sprite_count+0x10>
    35cc:	00170713          	addi	a4,a4,1
    35d0:	8b01a783          	lw	a5,-1872(gp) # 7998 <g_dl_n>
    35d4:	02f75663          	bge	a4,a5,3600 <dl_sprite_count+0x40>
    35d8:	000087b7          	lui	a5,0x8
    35dc:	00371693          	slli	a3,a4,0x3
    35e0:	40e686b3          	sub	a3,a3,a4
    35e4:	00169613          	slli	a2,a3,0x1
    35e8:	c2878793          	addi	a5,a5,-984 # 7c28 <g_dl>
    35ec:	00c787b3          	add	a5,a5,a2
    35f0:	0067c783          	lbu	a5,6(a5)
    35f4:	fc078ce3          	beqz	a5,35cc <dl_sprite_count+0xc>
    35f8:	00150513          	addi	a0,a0,1
    35fc:	fd1ff06f          	j	35cc <dl_sprite_count+0xc>
}
    3600:	00008067          	ret

00003604 <spark_add>:
    for (i = 0; i < SPARK_MAX; i++) {
    3604:	00000693          	li	a3,0
    3608:	05f00793          	li	a5,95
    360c:	06d7cc63          	blt	a5,a3,3684 <spark_add+0x80>
        if (g_spk[i].life == 0) {
    3610:	000117b7          	lui	a5,0x11
    3614:	00169713          	slli	a4,a3,0x1
    3618:	00d70733          	add	a4,a4,a3
    361c:	00271713          	slli	a4,a4,0x2
    3620:	b6878793          	addi	a5,a5,-1176 # 10b68 <g_spk>
    3624:	00e787b3          	add	a5,a5,a4
    3628:	00b7c783          	lbu	a5,11(a5)
    362c:	00078663          	beqz	a5,3638 <spark_add+0x34>
    for (i = 0; i < SPARK_MAX; i++) {
    3630:	00168693          	addi	a3,a3,1
    3634:	fd5ff06f          	j	3608 <spark_add+0x4>
            g_spk[i].x = (int16_t)cx; g_spk[i].y = (int16_t)cy;
    3638:	00011737          	lui	a4,0x11
    363c:	b6870713          	addi	a4,a4,-1176 # 10b68 <g_spk>
    3640:	00169613          	slli	a2,a3,0x1
    3644:	00d607b3          	add	a5,a2,a3
    3648:	00279793          	slli	a5,a5,0x2
    364c:	00f707b3          	add	a5,a4,a5
    3650:	00a79023          	sh	a0,0(a5)
    3654:	00b79123          	sh	a1,2(a5)
            g_spk[i].vx = 0; g_spk[i].vy = 0;
    3658:	00079223          	sh	zero,4(a5)
    365c:	00079323          	sh	zero,6(a5)
            g_spk[i].kind = S_SP; g_spk[i].sz = SZ_SP; g_spk[i].r = 0;
    3660:	00700593          	li	a1,7
    3664:	00b78423          	sb	a1,8(a5)
    3668:	01000593          	li	a1,16
    366c:	00b784a3          	sb	a1,9(a5)
    3670:	00078523          	sb	zero,10(a5)
            g_spk[i].life = 20;
    3674:	00078713          	mv	a4,a5
    3678:	01400793          	li	a5,20
    367c:	00f705a3          	sb	a5,11(a4)
            return;
    3680:	00008067          	ret
}
    3684:	00008067          	ret

00003688 <push_chunk>:
{
    3688:	ff010113          	addi	sp,sp,-16
    368c:	00112623          	sw	ra,12(sp)
    uint32_t room = blt_push_room();
    3690:	dedfe0ef          	jal	247c <blt_push_room>
    if (room == 0u) { cpu_backoff(BLT_WAIT_NOP); return; }   /* 引擎没跟上：纯 ALU 退避 */
    3694:	00050c63          	beqz	a0,36ac <push_chunk+0x24>
    3698:	00812423          	sw	s0,8(sp)
    369c:	00912223          	sw	s1,4(sp)
    36a0:	00050413          	mv	s0,a0
    uint32_t budget = HW_PUSH_BUDGET;
    36a4:	04000713          	li	a4,64
    36a8:	0600006f          	j	3708 <push_chunk+0x80>
    if (room == 0u) { cpu_backoff(BLT_WAIT_NOP); return; }   /* 引擎没跟上：纯 ALU 退避 */
    36ac:	03000513          	li	a0,48
    36b0:	88dfe0ef          	jal	1f3c <cpu_backoff>
    36b4:	2200006f          	j	38d4 <push_chunk+0x24c>
            e_fill(g_fb_back + (uint32_t)PLAY_Y0 * FB_STRIDE, FB_STRIDE, PLAY_W, PLAY_H, d->arg);
    36b8:	00008737          	lui	a4,0x8
    36bc:	00379693          	slli	a3,a5,0x3
    36c0:	40f686b3          	sub	a3,a3,a5
    36c4:	00169693          	slli	a3,a3,0x1
    36c8:	c2870793          	addi	a5,a4,-984 # 7c28 <g_dl>
    36cc:	00d787b3          	add	a5,a5,a3
    36d0:	8341a803          	lw	a6,-1996(gp) # 791c <g_fb_back>
    36d4:	00008537          	lui	a0,0x8
    36d8:	80050513          	addi	a0,a0,-2048 # 7800 <__clz_tab+0xc>
    36dc:	0047d703          	lhu	a4,4(a5)
    36e0:	20c00693          	li	a3,524
    36e4:	3c000613          	li	a2,960
    36e8:	78000593          	li	a1,1920
    36ec:	00a80533          	add	a0,a6,a0
    36f0:	a7dfe0ef          	jal	216c <e_fill>
        g_dl_i++;
    36f4:	8ac1a783          	lw	a5,-1876(gp) # 7994 <g_dl_i>
    36f8:	00178793          	addi	a5,a5,1
    36fc:	8af1a623          	sw	a5,-1876(gp) # 7994 <g_dl_i>
        room--;
    3700:	fff40413          	addi	s0,s0,-1
    while (g_dl_i < g_dl_n && room > 0u && budget-- > 0u) {
    3704:	00048713          	mv	a4,s1
    3708:	8ac1a783          	lw	a5,-1876(gp) # 7994 <g_dl_i>
    370c:	8b01a683          	lw	a3,-1872(gp) # 7998 <g_dl_n>
    3710:	1ad7de63          	bge	a5,a3,38cc <push_chunk+0x244>
    3714:	1c040663          	beqz	s0,38e0 <push_chunk+0x258>
    3718:	fff70493          	addi	s1,a4,-1
    371c:	1a070263          	beqz	a4,38c0 <push_chunk+0x238>
        if (d->op == DRAW_FILL_FULL) {
    3720:	00008737          	lui	a4,0x8
    3724:	00379693          	slli	a3,a5,0x3
    3728:	40f686b3          	sub	a3,a3,a5
    372c:	00169693          	slli	a3,a3,0x1
    3730:	c2870713          	addi	a4,a4,-984 # 7c28 <g_dl>
    3734:	00d70733          	add	a4,a4,a3
    3738:	00674803          	lbu	a6,6(a4)
    373c:	f6080ee3          	beqz	a6,36b8 <push_chunk+0x30>
        } else if (d->op == DRAW_FILL) {
    3740:	00100713          	li	a4,1
    3744:	0ce80463          	beq	a6,a4,380c <push_chunk+0x184>
            uint32_t ss  = (uint32_t)g_spr_sz[d->arg] * 2u;
    3748:	00008737          	lui	a4,0x8
    374c:	00379693          	slli	a3,a5,0x3
    3750:	40f686b3          	sub	a3,a3,a5
    3754:	00169693          	slli	a3,a3,0x1
    3758:	c2870713          	addi	a4,a4,-984 # 7c28 <g_dl>
    375c:	00d70733          	add	a4,a4,a3
    3760:	00475583          	lhu	a1,4(a4)
    3764:	84018693          	addi	a3,gp,-1984 # 7928 <g_spr_sz>
    3768:	00b686b3          	add	a3,a3,a1
    376c:	0006c603          	lbu	a2,0(a3)
    3770:	00161613          	slli	a2,a2,0x1
            uint32_t src = ATLAS_BASE + g_spr_off[d->arg]
    3774:	000076b7          	lui	a3,0x7
    3778:	00259593          	slli	a1,a1,0x2
    377c:	7d468693          	addi	a3,a3,2004 # 77d4 <g_spr_off>
    3780:	00b686b3          	add	a3,a3,a1
    3784:	0006a683          	lw	a3,0(a3)
                         + (uint32_t)d->sy * ss + (uint32_t)d->sx * 2u;   /* ★ 源裁剪偏移 */
    3788:	00b74583          	lbu	a1,11(a4)
    378c:	02c585b3          	mul	a1,a1,a2
    3790:	00b686b3          	add	a3,a3,a1
    3794:	00a74583          	lbu	a1,10(a4)
    3798:	00159593          	slli	a1,a1,0x1
    379c:	00b686b3          	add	a3,a3,a1
            uint32_t src = ATLAS_BASE + g_spr_off[d->arg]
    37a0:	002015b7          	lui	a1,0x201
    37a4:	00b68533          	add	a0,a3,a1
            uint32_t dst = g_fb_back + (uint32_t)d->y * FB_STRIDE + (uint32_t)d->x * 2u;
    37a8:	00271683          	lh	a3,2(a4)
    37ac:	00071583          	lh	a1,0(a4)
    37b0:	00469713          	slli	a4,a3,0x4
    37b4:	40d70733          	sub	a4,a4,a3
    37b8:	00671713          	slli	a4,a4,0x6
    37bc:	00b70733          	add	a4,a4,a1
    37c0:	00171713          	slli	a4,a4,0x1
    37c4:	8341a683          	lw	a3,-1996(gp) # 791c <g_fb_back>
    37c8:	00d705b3          	add	a1,a4,a3
            if (d->op == DRAW_GLOW)       e_glow(src, dst, ss, FB_STRIDE, d->w, d->h, d->ga);
    37cc:	00300713          	li	a4,3
    37d0:	08e80863          	beq	a6,a4,3860 <push_chunk+0x1d8>
            else if (d->op == DRAW_ALPHA) e_alpha(src, dst, ss, FB_STRIDE, d->w, d->h, d->ga);
    37d4:	00400713          	li	a4,4
    37d8:	0ae80c63          	beq	a6,a4,3890 <push_chunk+0x208>
            else                          e_key(src, dst, ss, FB_STRIDE, d->w, d->h, TRANS_KEY);
    37dc:	00008737          	lui	a4,0x8
    37e0:	c2870713          	addi	a4,a4,-984 # 7c28 <g_dl>
    37e4:	00379693          	slli	a3,a5,0x3
    37e8:	40f688b3          	sub	a7,a3,a5
    37ec:	00189893          	slli	a7,a7,0x1
    37f0:	011708b3          	add	a7,a4,a7
    37f4:	00000813          	li	a6,0
    37f8:	0088c783          	lbu	a5,8(a7)
    37fc:	0078c703          	lbu	a4,7(a7)
    3800:	78000693          	li	a3,1920
    3804:	9f9fe0ef          	jal	21fc <e_key>
    3808:	eedff06f          	j	36f4 <push_chunk+0x6c>
            e_fill(g_fb_back + (uint32_t)d->y * FB_STRIDE + (uint32_t)d->x * 2u,
    380c:	00008737          	lui	a4,0x8
    3810:	c2870713          	addi	a4,a4,-984 # 7c28 <g_dl>
    3814:	00379693          	slli	a3,a5,0x3
    3818:	40f68633          	sub	a2,a3,a5
    381c:	00161613          	slli	a2,a2,0x1
    3820:	00c70633          	add	a2,a4,a2
    3824:	00261583          	lh	a1,2(a2)
    3828:	00061803          	lh	a6,0(a2)
    382c:	00459513          	slli	a0,a1,0x4
    3830:	40b50533          	sub	a0,a0,a1
    3834:	00651513          	slli	a0,a0,0x6
    3838:	01050533          	add	a0,a0,a6
    383c:	00151513          	slli	a0,a0,0x1
    3840:	8341a803          	lw	a6,-1996(gp) # 791c <g_fb_back>
    3844:	00465703          	lhu	a4,4(a2)
    3848:	00864683          	lbu	a3,8(a2)
    384c:	00764603          	lbu	a2,7(a2)
    3850:	78000593          	li	a1,1920
    3854:	01050533          	add	a0,a0,a6
    3858:	915fe0ef          	jal	216c <e_fill>
    385c:	e99ff06f          	j	36f4 <push_chunk+0x6c>
            if (d->op == DRAW_GLOW)       e_glow(src, dst, ss, FB_STRIDE, d->w, d->h, d->ga);
    3860:	000086b7          	lui	a3,0x8
    3864:	c2868693          	addi	a3,a3,-984 # 7c28 <g_dl>
    3868:	00379813          	slli	a6,a5,0x3
    386c:	40f80733          	sub	a4,a6,a5
    3870:	00171713          	slli	a4,a4,0x1
    3874:	00e68733          	add	a4,a3,a4
    3878:	00974803          	lbu	a6,9(a4)
    387c:	00874783          	lbu	a5,8(a4)
    3880:	00774703          	lbu	a4,7(a4)
    3884:	78000693          	li	a3,1920
    3888:	a1dfe0ef          	jal	22a4 <e_glow>
    388c:	e69ff06f          	j	36f4 <push_chunk+0x6c>
            else if (d->op == DRAW_ALPHA) e_alpha(src, dst, ss, FB_STRIDE, d->w, d->h, d->ga);
    3890:	000086b7          	lui	a3,0x8
    3894:	c2868693          	addi	a3,a3,-984 # 7c28 <g_dl>
    3898:	00379813          	slli	a6,a5,0x3
    389c:	40f80733          	sub	a4,a6,a5
    38a0:	00171713          	slli	a4,a4,0x1
    38a4:	00e68733          	add	a4,a3,a4
    38a8:	00974803          	lbu	a6,9(a4)
    38ac:	00874783          	lbu	a5,8(a4)
    38b0:	00774703          	lbu	a4,7(a4)
    38b4:	78000693          	li	a3,1920
    38b8:	ad5fe0ef          	jal	238c <e_alpha>
    38bc:	e39ff06f          	j	36f4 <push_chunk+0x6c>
    38c0:	00812403          	lw	s0,8(sp)
    38c4:	00412483          	lw	s1,4(sp)
    38c8:	00c0006f          	j	38d4 <push_chunk+0x24c>
    38cc:	00812403          	lw	s0,8(sp)
    38d0:	00412483          	lw	s1,4(sp)
}
    38d4:	00c12083          	lw	ra,12(sp)
    38d8:	01010113          	addi	sp,sp,16
    38dc:	00008067          	ret
    38e0:	00812403          	lw	s0,8(sp)
    38e4:	00412483          	lw	s1,4(sp)
    38e8:	fedff06f          	j	38d4 <push_chunk+0x24c>

000038ec <blend565>:
{
    38ec:	00060693          	mv	a3,a2
    unsigned fr = (fg >> 11) & 0x1Fu, fgc = (fg >> 5) & 0x3Fu, fb = fg & 0x1Fu;
    38f0:	00b55713          	srli	a4,a0,0xb
    38f4:	00555613          	srli	a2,a0,0x5
    38f8:	03f67613          	andi	a2,a2,63
    38fc:	01f57513          	andi	a0,a0,31
    unsigned br = (bg >> 11) & 0x1Fu, bgc = (bg >> 5) & 0x3Fu, bb = bg & 0x1Fu;
    3900:	00b5d893          	srli	a7,a1,0xb
    3904:	0055d813          	srli	a6,a1,0x5
    3908:	03f87813          	andi	a6,a6,63
    390c:	01f5f593          	andi	a1,a1,31
    unsigned f8r = (fr << 3) | (fr >> 2), f8g = (fgc << 2) | (fgc >> 4), f8b = (fb << 3) | (fb >> 2);
    3910:	00371793          	slli	a5,a4,0x3
    3914:	00275713          	srli	a4,a4,0x2
    3918:	00e7e7b3          	or	a5,a5,a4
    391c:	00261713          	slli	a4,a2,0x2
    3920:	00465613          	srli	a2,a2,0x4
    3924:	00c76733          	or	a4,a4,a2
    3928:	00351613          	slli	a2,a0,0x3
    392c:	00255513          	srli	a0,a0,0x2
    3930:	00a66633          	or	a2,a2,a0
    unsigned b8r = (br << 3) | (br >> 2), b8g = (bgc << 2) | (bgc >> 4), b8b = (bb << 3) | (bb >> 2);
    3934:	00389513          	slli	a0,a7,0x3
    3938:	0028d893          	srli	a7,a7,0x2
    393c:	011568b3          	or	a7,a0,a7
    3940:	00281513          	slli	a0,a6,0x2
    3944:	00485813          	srli	a6,a6,0x4
    3948:	01056833          	or	a6,a0,a6
    394c:	00359513          	slli	a0,a1,0x3
    3950:	0025d593          	srli	a1,a1,0x2
    3954:	00b565b3          	or	a1,a0,a1
    unsigned ai  = 255u - a;
    3958:	0ff00e13          	li	t3,255
    395c:	40de0333          	sub	t1,t3,a3
    unsigned r = (f8r * a + b8r * ai + 127u) >> 8;
    3960:	02d787b3          	mul	a5,a5,a3
    3964:	02688533          	mul	a0,a7,t1
    3968:	00a787b3          	add	a5,a5,a0
    396c:	07f78793          	addi	a5,a5,127
    3970:	0087d793          	srli	a5,a5,0x8
    unsigned g = (f8g * a + b8g * ai + 127u) >> 8;
    3974:	02d70733          	mul	a4,a4,a3
    3978:	02680533          	mul	a0,a6,t1
    397c:	00a70733          	add	a4,a4,a0
    3980:	07f70713          	addi	a4,a4,127
    3984:	00875713          	srli	a4,a4,0x8
    unsigned b = (f8b * a + b8b * ai + 127u) >> 8;
    3988:	02d60633          	mul	a2,a2,a3
    398c:	026586b3          	mul	a3,a1,t1
    3990:	00d60633          	add	a2,a2,a3
    3994:	07f60613          	addi	a2,a2,127
    3998:	00865613          	srli	a2,a2,0x8
    if (r > 255u) r = 255u;
    399c:	00fe7463          	bgeu	t3,a5,39a4 <blend565+0xb8>
    39a0:	0ff00793          	li	a5,255
    if (g > 255u) g = 255u;
    39a4:	0ff00693          	li	a3,255
    39a8:	00e6f463          	bgeu	a3,a4,39b0 <blend565+0xc4>
    39ac:	0ff00713          	li	a4,255
    if (b > 255u) b = 255u;
    39b0:	0ff00693          	li	a3,255
    39b4:	00c6f463          	bgeu	a3,a2,39bc <blend565+0xd0>
    39b8:	0ff00613          	li	a2,255
    return (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
    39bc:	0037d513          	srli	a0,a5,0x3
    39c0:	00b51513          	slli	a0,a0,0xb
    39c4:	01051513          	slli	a0,a0,0x10
    39c8:	01055513          	srli	a0,a0,0x10
    39cc:	00275713          	srli	a4,a4,0x2
    39d0:	00571713          	slli	a4,a4,0x5
    39d4:	01071713          	slli	a4,a4,0x10
    39d8:	01075713          	srli	a4,a4,0x10
    39dc:	00e56533          	or	a0,a0,a4
    39e0:	00365613          	srli	a2,a2,0x3
    39e4:	00c56533          	or	a0,a0,a2
}
    39e8:	01051513          	slli	a0,a0,0x10
    39ec:	01055513          	srli	a0,a0,0x10
    39f0:	00008067          	ret

000039f4 <add565>:
{
    39f4:	00060893          	mv	a7,a2
    unsigned fr = (fg >> 11) & 0x1Fu, fgc = (fg >> 5) & 0x3Fu, fb = fg & 0x1Fu;
    39f8:	00b55713          	srli	a4,a0,0xb
    39fc:	00555813          	srli	a6,a0,0x5
    3a00:	03f87813          	andi	a6,a6,63
    3a04:	01f57513          	andi	a0,a0,31
    unsigned br = (bg >> 11) & 0x1Fu, bgc = (bg >> 5) & 0x3Fu, bb = bg & 0x1Fu;
    3a08:	00b5d313          	srli	t1,a1,0xb
    3a0c:	0055d693          	srli	a3,a1,0x5
    3a10:	03f6f693          	andi	a3,a3,63
    3a14:	01f5f593          	andi	a1,a1,31
    unsigned f8r = (fr << 3) | (fr >> 2), f8g = (fgc << 2) | (fgc >> 4), f8b = (fb << 3) | (fb >> 2);
    3a18:	00371793          	slli	a5,a4,0x3
    3a1c:	00275713          	srli	a4,a4,0x2
    3a20:	00e7e7b3          	or	a5,a5,a4
    3a24:	00281713          	slli	a4,a6,0x2
    3a28:	00485813          	srli	a6,a6,0x4
    3a2c:	01076733          	or	a4,a4,a6
    3a30:	00351613          	slli	a2,a0,0x3
    3a34:	00255513          	srli	a0,a0,0x2
    3a38:	00a66633          	or	a2,a2,a0
    unsigned b8r = (br << 3) | (br >> 2), b8g = (bgc << 2) | (bgc >> 4), b8b = (bb << 3) | (bb >> 2);
    3a3c:	00331813          	slli	a6,t1,0x3
    3a40:	00235313          	srli	t1,t1,0x2
    3a44:	00686833          	or	a6,a6,t1
    3a48:	00269513          	slli	a0,a3,0x2
    3a4c:	0046d693          	srli	a3,a3,0x4
    3a50:	00d56533          	or	a0,a0,a3
    3a54:	00359693          	slli	a3,a1,0x3
    3a58:	0025d593          	srli	a1,a1,0x2
    3a5c:	00b6e5b3          	or	a1,a3,a1
    unsigned r = f8r * ga / 255u + b8r;
    3a60:	031787b3          	mul	a5,a5,a7
    3a64:	0ff00693          	li	a3,255
    3a68:	02d7d7b3          	divu	a5,a5,a3
    3a6c:	010787b3          	add	a5,a5,a6
    unsigned g = f8g * ga / 255u + b8g;
    3a70:	03170733          	mul	a4,a4,a7
    3a74:	02d75733          	divu	a4,a4,a3
    3a78:	00a70733          	add	a4,a4,a0
    unsigned b = f8b * ga / 255u + b8b;
    3a7c:	03160633          	mul	a2,a2,a7
    3a80:	02d65633          	divu	a2,a2,a3
    3a84:	00b60633          	add	a2,a2,a1
    if (r > 255u) r = 255u;
    3a88:	00f6f463          	bgeu	a3,a5,3a90 <add565+0x9c>
    3a8c:	0ff00793          	li	a5,255
    if (g > 255u) g = 255u;
    3a90:	0ff00693          	li	a3,255
    3a94:	00e6f463          	bgeu	a3,a4,3a9c <add565+0xa8>
    3a98:	0ff00713          	li	a4,255
    if (b > 255u) b = 255u;
    3a9c:	0ff00693          	li	a3,255
    3aa0:	00c6f463          	bgeu	a3,a2,3aa8 <add565+0xb4>
    3aa4:	0ff00613          	li	a2,255
    return (uint16_t)(((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3));
    3aa8:	0037d513          	srli	a0,a5,0x3
    3aac:	00b51513          	slli	a0,a0,0xb
    3ab0:	01051513          	slli	a0,a0,0x10
    3ab4:	01055513          	srli	a0,a0,0x10
    3ab8:	00275713          	srli	a4,a4,0x2
    3abc:	00571713          	slli	a4,a4,0x5
    3ac0:	01071713          	slli	a4,a4,0x10
    3ac4:	01075713          	srli	a4,a4,0x10
    3ac8:	00e56533          	or	a0,a0,a4
    3acc:	00365613          	srli	a2,a2,0x3
    3ad0:	00c56533          	or	a0,a0,a2
}
    3ad4:	01051513          	slli	a0,a0,0x10
    3ad8:	01055513          	srli	a0,a0,0x10
    3adc:	00008067          	ret

00003ae0 <cpu_blit>:
{
    3ae0:	fb010113          	addi	sp,sp,-80
    3ae4:	04112623          	sw	ra,76(sp)
    3ae8:	04812423          	sw	s0,72(sp)
    3aec:	04912223          	sw	s1,68(sp)
    3af0:	05212023          	sw	s2,64(sp)
    3af4:	03312e23          	sw	s3,60(sp)
    3af8:	03412c23          	sw	s4,56(sp)
    3afc:	03512a23          	sw	s5,52(sp)
    3b00:	03612823          	sw	s6,48(sp)
    3b04:	03712623          	sw	s7,44(sp)
    3b08:	03812423          	sw	s8,40(sp)
    3b0c:	03912223          	sw	s9,36(sp)
    3b10:	03a12023          	sw	s10,32(sp)
    3b14:	01b12e23          	sw	s11,28(sp)
    3b18:	00058d13          	mv	s10,a1
    3b1c:	00c12223          	sw	a2,4(sp)
    3b20:	00068a93          	mv	s5,a3
    3b24:	00070c93          	mv	s9,a4
    3b28:	00f12423          	sw	a5,8(sp)
    3b2c:	01012623          	sw	a6,12(sp)
    3b30:	00088c13          	mv	s8,a7
    3b34:	05012983          	lw	s3,80(sp)
    const volatile uint16_t *s = (const volatile uint16_t *)(ATLAS_BASE + g_spr_off[spr]);
    3b38:	000077b7          	lui	a5,0x7
    3b3c:	00251713          	slli	a4,a0,0x2
    3b40:	7d478793          	addi	a5,a5,2004 # 77d4 <g_spr_off>
    3b44:	00e787b3          	add	a5,a5,a4
    3b48:	0007ab03          	lw	s6,0(a5)
    3b4c:	002017b7          	lui	a5,0x201
    3b50:	00fb0b33          	add	s6,s6,a5
    int sw = (int)g_spr_sz[spr];
    3b54:	84018793          	addi	a5,gp,-1984 # 7928 <g_spr_sz>
    3b58:	00a78533          	add	a0,a5,a0
    3b5c:	00054d83          	lbu	s11,0(a0)
    for (j = 0; j < h; j++) {
    3b60:	00000b93          	li	s7,0
    3b64:	0800006f          	j	3be4 <cpu_blit+0x104>
            if (mode == 1)      d[i] = add565(c, d[i], ga);        /* 加算 */
    3b68:	00141493          	slli	s1,s0,0x1
    3b6c:	009904b3          	add	s1,s2,s1
    3b70:	0004d583          	lhu	a1,0(s1)
    3b74:	000c0613          	mv	a2,s8
    3b78:	e7dff0ef          	jal	39f4 <add565>
    3b7c:	00a49023          	sh	a0,0(s1)
        for (i = 0; i < w; i++) {
    3b80:	00140413          	addi	s0,s0,1
    3b84:	05545e63          	bge	s0,s5,3be0 <cpu_blit+0x100>
            uint16_t c = sr[i];
    3b88:	008a07b3          	add	a5,s4,s0
    3b8c:	00179793          	slli	a5,a5,0x1
    3b90:	00fb07b3          	add	a5,s6,a5
    3b94:	0007d503          	lhu	a0,0(a5) # 201000 <__freertos_irq_stack_top+0x1e7e00>
    3b98:	01051513          	slli	a0,a0,0x10
    3b9c:	01055513          	srli	a0,a0,0x10
            if (mode == 1)      d[i] = add565(c, d[i], ga);        /* 加算 */
    3ba0:	00100793          	li	a5,1
    3ba4:	fcf982e3          	beq	s3,a5,3b68 <cpu_blit+0x88>
            else if (mode == 2) d[i] = blend565(c, d[i], ga);      /* 经典半透明 */
    3ba8:	00200793          	li	a5,2
    3bac:	00f98c63          	beq	s3,a5,3bc4 <cpu_blit+0xe4>
            else if (c != TRANS_KEY) d[i] = c;                     /* Color Key */
    3bb0:	fc0508e3          	beqz	a0,3b80 <cpu_blit+0xa0>
    3bb4:	00141493          	slli	s1,s0,0x1
    3bb8:	009904b3          	add	s1,s2,s1
    3bbc:	00a49023          	sh	a0,0(s1)
    3bc0:	fc1ff06f          	j	3b80 <cpu_blit+0xa0>
            else if (mode == 2) d[i] = blend565(c, d[i], ga);      /* 经典半透明 */
    3bc4:	00141493          	slli	s1,s0,0x1
    3bc8:	009904b3          	add	s1,s2,s1
    3bcc:	0004d583          	lhu	a1,0(s1)
    3bd0:	000c0613          	mv	a2,s8
    3bd4:	d19ff0ef          	jal	38ec <blend565>
    3bd8:	00a49023          	sh	a0,0(s1)
    3bdc:	fa5ff06f          	j	3b80 <cpu_blit+0xa0>
    for (j = 0; j < h; j++) {
    3be0:	001b8b93          	addi	s7,s7,1
    3be4:	059bd263          	bge	s7,s9,3c28 <cpu_blit+0x148>
                                + (uint32_t)(y + j) * FB_STRIDE + (uint32_t)x * 2u);
    3be8:	00412783          	lw	a5,4(sp)
    3bec:	00fb87b3          	add	a5,s7,a5
    3bf0:	00479913          	slli	s2,a5,0x4
    3bf4:	40f90933          	sub	s2,s2,a5
    3bf8:	00691913          	slli	s2,s2,0x6
    3bfc:	01a90933          	add	s2,s2,s10
    3c00:	00191913          	slli	s2,s2,0x1
    3c04:	8341a783          	lw	a5,-1996(gp) # 791c <g_fb_back>
    3c08:	00f90933          	add	s2,s2,a5
        const volatile uint16_t *sr = s + (j + sy) * sw + sx;
    3c0c:	00c12783          	lw	a5,12(sp)
    3c10:	00fb8a33          	add	s4,s7,a5
    3c14:	03ba0a33          	mul	s4,s4,s11
    3c18:	00812783          	lw	a5,8(sp)
    3c1c:	00fa0a33          	add	s4,s4,a5
        for (i = 0; i < w; i++) {
    3c20:	00000413          	li	s0,0
    3c24:	f61ff06f          	j	3b84 <cpu_blit+0xa4>
}
    3c28:	04c12083          	lw	ra,76(sp)
    3c2c:	04812403          	lw	s0,72(sp)
    3c30:	04412483          	lw	s1,68(sp)
    3c34:	04012903          	lw	s2,64(sp)
    3c38:	03c12983          	lw	s3,60(sp)
    3c3c:	03812a03          	lw	s4,56(sp)
    3c40:	03412a83          	lw	s5,52(sp)
    3c44:	03012b03          	lw	s6,48(sp)
    3c48:	02c12b83          	lw	s7,44(sp)
    3c4c:	02812c03          	lw	s8,40(sp)
    3c50:	02412c83          	lw	s9,36(sp)
    3c54:	02012d03          	lw	s10,32(sp)
    3c58:	01c12d83          	lw	s11,28(sp)
    3c5c:	05010113          	addi	sp,sp,80
    3c60:	00008067          	ret

00003c64 <cpu_render_frame>:
{
    3c64:	fe010113          	addi	sp,sp,-32
    3c68:	00112e23          	sw	ra,28(sp)
    3c6c:	00812c23          	sw	s0,24(sp)
    cpu_fill32(g_fb_back, 0, PLAY_Y0, PLAY_W, PLAY_H, COL_BG);   /* 纯软件：整屏铺底也自己干 */
    3c70:	00800793          	li	a5,8
    3c74:	20c00713          	li	a4,524
    3c78:	3c000693          	li	a3,960
    3c7c:	01000613          	li	a2,16
    3c80:	00000593          	li	a1,0
    3c84:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    3c88:	b5cfe0ef          	jal	1fe4 <cpu_fill32>
    for (i = 0; i < g_dl_n; i++) {
    3c8c:	00000413          	li	s0,0
    3c90:	0300006f          	j	3cc0 <cpu_render_frame+0x5c>
        if (d->op == DRAW_FILL_FULL)      cpu_fill32(g_fb_back, 0, PLAY_Y0, PLAY_W, PLAY_H, d->arg);
    3c94:	000087b7          	lui	a5,0x8
    3c98:	c2878793          	addi	a5,a5,-984 # 7c28 <g_dl>
    3c9c:	00d787b3          	add	a5,a5,a3
    3ca0:	0047d783          	lhu	a5,4(a5)
    3ca4:	20c00713          	li	a4,524
    3ca8:	3c000693          	li	a3,960
    3cac:	01000613          	li	a2,16
    3cb0:	00000593          	li	a1,0
    3cb4:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    3cb8:	b2cfe0ef          	jal	1fe4 <cpu_fill32>
    for (i = 0; i < g_dl_n; i++) {
    3cbc:	00140413          	addi	s0,s0,1
    3cc0:	8b01a783          	lw	a5,-1872(gp) # 7998 <g_dl_n>
    3cc4:	14f45463          	bge	s0,a5,3e0c <cpu_render_frame+0x1a8>
        if (d->op == DRAW_FILL_FULL)      cpu_fill32(g_fb_back, 0, PLAY_Y0, PLAY_W, PLAY_H, d->arg);
    3cc8:	000087b7          	lui	a5,0x8
    3ccc:	00341713          	slli	a4,s0,0x3
    3cd0:	40870733          	sub	a4,a4,s0
    3cd4:	00171693          	slli	a3,a4,0x1
    3cd8:	c2878793          	addi	a5,a5,-984 # 7c28 <g_dl>
    3cdc:	00d787b3          	add	a5,a5,a3
    3ce0:	0067c783          	lbu	a5,6(a5)
    3ce4:	fa0788e3          	beqz	a5,3c94 <cpu_render_frame+0x30>
        else if (d->op == DRAW_FILL)      cpu_fill32(g_fb_back, d->x, d->y, d->w, d->h, d->arg);
    3ce8:	00100713          	li	a4,1
    3cec:	04e78c63          	beq	a5,a4,3d44 <cpu_render_frame+0xe0>
        else if (d->op == DRAW_GLOW)      cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, d->ga, 1);
    3cf0:	00300713          	li	a4,3
    3cf4:	08e78463          	beq	a5,a4,3d7c <cpu_render_frame+0x118>
        else if (d->op == DRAW_ALPHA)     cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, d->ga, 2);
    3cf8:	00400713          	li	a4,4
    3cfc:	0ce78463          	beq	a5,a4,3dc4 <cpu_render_frame+0x160>
        else                              cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, 0u, 0);
    3d00:	00008537          	lui	a0,0x8
    3d04:	00341793          	slli	a5,s0,0x3
    3d08:	408787b3          	sub	a5,a5,s0
    3d0c:	00179713          	slli	a4,a5,0x1
    3d10:	c2850513          	addi	a0,a0,-984 # 7c28 <g_dl>
    3d14:	00e50533          	add	a0,a0,a4
    3d18:	00012023          	sw	zero,0(sp)
    3d1c:	00000893          	li	a7,0
    3d20:	00b54803          	lbu	a6,11(a0)
    3d24:	00a54783          	lbu	a5,10(a0)
    3d28:	00854703          	lbu	a4,8(a0)
    3d2c:	00754683          	lbu	a3,7(a0)
    3d30:	00251603          	lh	a2,2(a0)
    3d34:	00051583          	lh	a1,0(a0)
    3d38:	00455503          	lhu	a0,4(a0)
    3d3c:	da5ff0ef          	jal	3ae0 <cpu_blit>
    3d40:	f7dff06f          	j	3cbc <cpu_render_frame+0x58>
        else if (d->op == DRAW_FILL)      cpu_fill32(g_fb_back, d->x, d->y, d->w, d->h, d->arg);
    3d44:	000085b7          	lui	a1,0x8
    3d48:	00341793          	slli	a5,s0,0x3
    3d4c:	408787b3          	sub	a5,a5,s0
    3d50:	00179713          	slli	a4,a5,0x1
    3d54:	c2858593          	addi	a1,a1,-984 # 7c28 <g_dl>
    3d58:	00e585b3          	add	a1,a1,a4
    3d5c:	0045d783          	lhu	a5,4(a1)
    3d60:	0085c703          	lbu	a4,8(a1)
    3d64:	0075c683          	lbu	a3,7(a1)
    3d68:	00259603          	lh	a2,2(a1)
    3d6c:	00059583          	lh	a1,0(a1)
    3d70:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    3d74:	a70fe0ef          	jal	1fe4 <cpu_fill32>
    3d78:	f45ff06f          	j	3cbc <cpu_render_frame+0x58>
        else if (d->op == DRAW_GLOW)      cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, d->ga, 1);
    3d7c:	00008537          	lui	a0,0x8
    3d80:	00341793          	slli	a5,s0,0x3
    3d84:	408787b3          	sub	a5,a5,s0
    3d88:	00179713          	slli	a4,a5,0x1
    3d8c:	c2850513          	addi	a0,a0,-984 # 7c28 <g_dl>
    3d90:	00e50533          	add	a0,a0,a4
    3d94:	00100793          	li	a5,1
    3d98:	00f12023          	sw	a5,0(sp)
    3d9c:	00954883          	lbu	a7,9(a0)
    3da0:	00b54803          	lbu	a6,11(a0)
    3da4:	00a54783          	lbu	a5,10(a0)
    3da8:	00854703          	lbu	a4,8(a0)
    3dac:	00754683          	lbu	a3,7(a0)
    3db0:	00251603          	lh	a2,2(a0)
    3db4:	00051583          	lh	a1,0(a0)
    3db8:	00455503          	lhu	a0,4(a0)
    3dbc:	d25ff0ef          	jal	3ae0 <cpu_blit>
    3dc0:	efdff06f          	j	3cbc <cpu_render_frame+0x58>
        else if (d->op == DRAW_ALPHA)     cpu_blit(d->arg, d->x, d->y, d->w, d->h, d->sx, d->sy, d->ga, 2);
    3dc4:	00008537          	lui	a0,0x8
    3dc8:	00341793          	slli	a5,s0,0x3
    3dcc:	408787b3          	sub	a5,a5,s0
    3dd0:	00179713          	slli	a4,a5,0x1
    3dd4:	c2850513          	addi	a0,a0,-984 # 7c28 <g_dl>
    3dd8:	00e50533          	add	a0,a0,a4
    3ddc:	00200793          	li	a5,2
    3de0:	00f12023          	sw	a5,0(sp)
    3de4:	00954883          	lbu	a7,9(a0)
    3de8:	00b54803          	lbu	a6,11(a0)
    3dec:	00a54783          	lbu	a5,10(a0)
    3df0:	00854703          	lbu	a4,8(a0)
    3df4:	00754683          	lbu	a3,7(a0)
    3df8:	00251603          	lh	a2,2(a0)
    3dfc:	00051583          	lh	a1,0(a0)
    3e00:	00455503          	lhu	a0,4(a0)
    3e04:	cddff0ef          	jal	3ae0 <cpu_blit>
    3e08:	eb5ff06f          	j	3cbc <cpu_render_frame+0x58>
}
    3e0c:	01c12083          	lw	ra,28(sp)
    3e10:	01812403          	lw	s0,24(sp)
    3e14:	02010113          	addi	sp,sp,32
    3e18:	00008067          	ret

00003e1c <app>:
static char *app(char *p, const char *s) { while (*s) *p++ = *s++; return p; }
    3e1c:	0100006f          	j	3e2c <app+0x10>
    3e20:	00158593          	addi	a1,a1,1
    3e24:	00f50023          	sb	a5,0(a0)
    3e28:	00150513          	addi	a0,a0,1
    3e2c:	0005c783          	lbu	a5,0(a1)
    3e30:	fe0798e3          	bnez	a5,3e20 <app+0x4>
    3e34:	00008067          	ret

00003e38 <appn>:
{
    3e38:	ff010113          	addi	sp,sp,-16
    char d[12]; int n = 0, i;
    3e3c:	00000793          	li	a5,0
    do { d[n++] = (char)('0' + (v % 10u)); v /= 10u; } while (v && n < 11);
    3e40:	00a00813          	li	a6,10
    3e44:	0305f6b3          	remu	a3,a1,a6
    3e48:	03068693          	addi	a3,a3,48
    3e4c:	01078713          	addi	a4,a5,16
    3e50:	00270733          	add	a4,a4,sp
    3e54:	00178793          	addi	a5,a5,1
    3e58:	fed70a23          	sb	a3,-12(a4)
    3e5c:	00058693          	mv	a3,a1
    3e60:	0305d5b3          	divu	a1,a1,a6
    3e64:	00900713          	li	a4,9
    3e68:	02d77863          	bgeu	a4,a3,3e98 <appn+0x60>
    3e6c:	00a00713          	li	a4,10
    3e70:	fcf758e3          	bge	a4,a5,3e40 <appn+0x8>
    3e74:	00000713          	li	a4,0
    3e78:	0140006f          	j	3e8c <appn+0x54>
    for (i = 0; i < w - n; i++) *p++ = ' ';
    3e7c:	02000693          	li	a3,32
    3e80:	00d50023          	sb	a3,0(a0)
    3e84:	00170713          	addi	a4,a4,1
    3e88:	00150513          	addi	a0,a0,1
    3e8c:	40f606b3          	sub	a3,a2,a5
    3e90:	fed746e3          	blt	a4,a3,3e7c <appn+0x44>
    3e94:	0240006f          	j	3eb8 <appn+0x80>
    3e98:	00000713          	li	a4,0
    3e9c:	ff1ff06f          	j	3e8c <appn+0x54>
    while (n) *p++ = d[--n];
    3ea0:	fff78793          	addi	a5,a5,-1
    3ea4:	01078713          	addi	a4,a5,16
    3ea8:	00270733          	add	a4,a4,sp
    3eac:	ff474703          	lbu	a4,-12(a4)
    3eb0:	00e50023          	sb	a4,0(a0)
    3eb4:	00150513          	addi	a0,a0,1
    3eb8:	fe0794e3          	bnez	a5,3ea0 <appn+0x68>
}
    3ebc:	01010113          	addi	sp,sp,16
    3ec0:	00008067          	ret

00003ec4 <slen>:
static int slen(const char *s) { int n = 0; while (s[n]) n++; return n; }
    3ec4:	00050713          	mv	a4,a0
    3ec8:	00000513          	li	a0,0
    3ecc:	0080006f          	j	3ed4 <slen+0x10>
    3ed0:	00150513          	addi	a0,a0,1
    3ed4:	00a707b3          	add	a5,a4,a0
    3ed8:	0007c783          	lbu	a5,0(a5)
    3edc:	fe079ae3          	bnez	a5,3ed0 <slen+0xc>
    3ee0:	00008067          	ret

00003ee4 <fmt_stat>:
{
    3ee4:	fd010113          	addi	sp,sp,-48
    3ee8:	02112623          	sw	ra,44(sp)
    3eec:	02812423          	sw	s0,40(sp)
    3ef0:	02912223          	sw	s1,36(sp)
    3ef4:	03212023          	sw	s2,32(sp)
    3ef8:	01312e23          	sw	s3,28(sp)
    3efc:	01412c23          	sw	s4,24(sp)
    3f00:	01512a23          	sw	s5,20(sp)
    3f04:	01612823          	sw	s6,16(sp)
    3f08:	01712623          	sw	s7,12(sp)
    3f0c:	00058a93          	mv	s5,a1
    3f10:	00060a13          	mv	s4,a2
    3f14:	00068b93          	mv	s7,a3
    3f18:	00070913          	mv	s2,a4
    3f1c:	00078493          	mv	s1,a5
    3f20:	00080993          	mv	s3,a6
    3f24:	00088413          	mv	s0,a7
    3f28:	03012b03          	lw	s6,48(sp)
    if (hw_fps > 999u) hw_fps = 999u;
    3f2c:	3e700793          	li	a5,999
    3f30:	00b7f463          	bgeu	a5,a1,3f38 <fmt_stat+0x54>
    3f34:	3e700a93          	li	s5,999
    if (sw_fps > 999u) sw_fps = 999u;
    3f38:	3e700793          	li	a5,999
    3f3c:	0147f463          	bgeu	a5,s4,3f44 <fmt_stat+0x60>
    3f40:	3e700a13          	li	s4,999
    if (score > SCORE_CAP) score = SCORE_CAP;
    3f44:	000f47b7          	lui	a5,0xf4
    3f48:	23f78793          	addi	a5,a5,575 # f423f <__freertos_irq_stack_top+0xdb03f>
    3f4c:	0097d463          	bge	a5,s1,3f54 <fmt_stat+0x70>
    3f50:	00078493          	mv	s1,a5
    if (non > 9999) non = 9999;
    3f54:	000027b7          	lui	a5,0x2
    3f58:	70f78793          	addi	a5,a5,1807 # 270f <uart_poll_char+0x23>
    3f5c:	0127d463          	bge	a5,s2,3f64 <fmt_stat+0x80>
    3f60:	00078913          	mv	s2,a5
    p = app(p, "HW=");  p = appn(p, hw_fps, 3);
    3f64:	000065b7          	lui	a1,0x6
    3f68:	52858593          	addi	a1,a1,1320 # 6528 <_data+0x30>
    3f6c:	eb1ff0ef          	jal	3e1c <app>
    3f70:	00300613          	li	a2,3
    3f74:	000a8593          	mv	a1,s5
    3f78:	ec1ff0ef          	jal	3e38 <appn>
    p = app(p, " SW="); p = appn(p, sw_fps, 3);
    3f7c:	000065b7          	lui	a1,0x6
    3f80:	52c58593          	addi	a1,a1,1324 # 652c <_data+0x34>
    3f84:	e99ff0ef          	jal	3e1c <app>
    3f88:	00300613          	li	a2,3
    3f8c:	000a0593          	mv	a1,s4
    3f90:	ea9ff0ef          	jal	3e38 <appn>
    p = app(p, " N=");  p = appn(p, (unsigned)ncap, 4);
    3f94:	000065b7          	lui	a1,0x6
    3f98:	53458593          	addi	a1,a1,1332 # 6534 <_data+0x3c>
    3f9c:	e81ff0ef          	jal	3e1c <app>
    3fa0:	00400613          	li	a2,4
    3fa4:	000b8593          	mv	a1,s7
    3fa8:	e91ff0ef          	jal	3e38 <appn>
    p = app(p, " ON="); p = appn(p, (unsigned)non, 4);
    3fac:	000065b7          	lui	a1,0x6
    3fb0:	53858593          	addi	a1,a1,1336 # 6538 <_data+0x40>
    3fb4:	e69ff0ef          	jal	3e1c <app>
    3fb8:	00400613          	li	a2,4
    3fbc:	00090593          	mv	a1,s2
    3fc0:	e79ff0ef          	jal	3e38 <appn>
    p = app(p, " SC="); p = appn(p, (unsigned)score, 6);
    3fc4:	000065b7          	lui	a1,0x6
    3fc8:	54058593          	addi	a1,a1,1344 # 6540 <_data+0x48>
    3fcc:	e51ff0ef          	jal	3e1c <app>
    3fd0:	00600613          	li	a2,6
    3fd4:	00048593          	mv	a1,s1
    3fd8:	e61ff0ef          	jal	3e38 <appn>
    p = app(p, " LV="); p = appn(p, (unsigned)(level > 99 ? 99 : level), 2);
    3fdc:	000065b7          	lui	a1,0x6
    3fe0:	54858593          	addi	a1,a1,1352 # 6548 <_data+0x50>
    3fe4:	e39ff0ef          	jal	3e1c <app>
    3fe8:	00098593          	mv	a1,s3
    3fec:	06300793          	li	a5,99
    3ff0:	0137d463          	bge	a5,s3,3ff8 <fmt_stat+0x114>
    3ff4:	06300593          	li	a1,99
    3ff8:	00200613          	li	a2,2
    3ffc:	e3dff0ef          	jal	3e38 <appn>
    p = app(p, " HP="); p = appn(p, (unsigned)(hp < 0 ? 0 : (hp > 9 ? 9 : hp)), 1);
    4000:	000065b7          	lui	a1,0x6
    4004:	55058593          	addi	a1,a1,1360 # 6550 <_data+0x58>
    4008:	e15ff0ef          	jal	3e1c <app>
    400c:	06044a63          	bltz	s0,4080 <fmt_stat+0x19c>
    4010:	00900793          	li	a5,9
    4014:	0087d463          	bge	a5,s0,401c <fmt_stat+0x138>
    4018:	00900413          	li	s0,9
    401c:	00040593          	mv	a1,s0
    4020:	00100613          	li	a2,1
    4024:	e15ff0ef          	jal	3e38 <appn>
    p = app(p, " OP="); p = app(p, op ? op : "?");
    4028:	000065b7          	lui	a1,0x6
    402c:	55858593          	addi	a1,a1,1368 # 6558 <_data+0x60>
    4030:	dedff0ef          	jal	3e1c <app>
    4034:	040b0a63          	beqz	s6,4088 <fmt_stat+0x1a4>
    4038:	000b0593          	mv	a1,s6
    403c:	de1ff0ef          	jal	3e1c <app>
    if (star) p = app(p, " S");
    4040:	03412783          	lw	a5,52(sp)
    4044:	04079863          	bnez	a5,4094 <fmt_stat+0x1b0>
    if (autq) p = app(p, " G");
    4048:	03812783          	lw	a5,56(sp)
    404c:	04079c63          	bnez	a5,40a4 <fmt_stat+0x1c0>
    *p = 0;
    4050:	00050023          	sb	zero,0(a0)
}
    4054:	02c12083          	lw	ra,44(sp)
    4058:	02812403          	lw	s0,40(sp)
    405c:	02412483          	lw	s1,36(sp)
    4060:	02012903          	lw	s2,32(sp)
    4064:	01c12983          	lw	s3,28(sp)
    4068:	01812a03          	lw	s4,24(sp)
    406c:	01412a83          	lw	s5,20(sp)
    4070:	01012b03          	lw	s6,16(sp)
    4074:	00c12b83          	lw	s7,12(sp)
    4078:	03010113          	addi	sp,sp,48
    407c:	00008067          	ret
    p = app(p, " HP="); p = appn(p, (unsigned)(hp < 0 ? 0 : (hp > 9 ? 9 : hp)), 1);
    4080:	00000593          	li	a1,0
    4084:	f9dff06f          	j	4020 <fmt_stat+0x13c>
    p = app(p, " OP="); p = app(p, op ? op : "?");
    4088:	00006b37          	lui	s6,0x6
    408c:	524b0b13          	addi	s6,s6,1316 # 6524 <_data+0x2c>
    4090:	fa9ff06f          	j	4038 <fmt_stat+0x154>
    if (star) p = app(p, " S");
    4094:	000065b7          	lui	a1,0x6
    4098:	56058593          	addi	a1,a1,1376 # 6560 <_data+0x68>
    409c:	d81ff0ef          	jal	3e1c <app>
    40a0:	fa9ff06f          	j	4048 <fmt_stat+0x164>
    if (autq) p = app(p, " G");
    40a4:	000065b7          	lui	a1,0x6
    40a8:	56458593          	addi	a1,a1,1380 # 6564 <_data+0x6c>
    40ac:	d71ff0ef          	jal	3e1c <app>
    40b0:	fa1ff06f          	j	4050 <fmt_stat+0x16c>

000040b4 <osd_text>:
{
    40b4:	fe010113          	addi	sp,sp,-32
    40b8:	00112e23          	sw	ra,28(sp)
    40bc:	00812c23          	sw	s0,24(sp)
    40c0:	00912a23          	sw	s1,20(sp)
    40c4:	01212823          	sw	s2,16(sp)
    40c8:	01312623          	sw	s3,12(sp)
    40cc:	00050493          	mv	s1,a0
    40d0:	00058913          	mv	s2,a1
    40d4:	00060993          	mv	s3,a2
    40d8:	00068413          	mv	s0,a3
    while (*s) {
    40dc:	1000006f          	j	41dc <osd_text+0x128>
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    40e0:	00000613          	li	a2,0
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    40e4:	01871593          	slli	a1,a4,0x18
    40e8:	4185d593          	srai	a1,a1,0x18
    40ec:	0205c063          	bltz	a1,410c <osd_text+0x58>
    40f0:	00000593          	li	a1,0
    40f4:	00b66633          	or	a2,a2,a1
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    40f8:	00c7a023          	sw	a2,0(a5)
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    40fc:	01077613          	andi	a2,a4,16
    4100:	00060a63          	beqz	a2,4114 <osd_text+0x60>
    4104:	01041613          	slli	a2,s0,0x10
    4108:	0100006f          	j	4118 <osd_text+0x64>
                 | ((bits & 0x80u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    410c:	00040593          	mv	a1,s0
    4110:	fe5ff06f          	j	40f4 <osd_text+0x40>
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    4114:	00000613          	li	a2,0
                 | ((bits & 0x20u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    4118:	02077593          	andi	a1,a4,32
    411c:	00058663          	beqz	a1,4128 <osd_text+0x74>
    4120:	00040593          	mv	a1,s0
    4124:	0080006f          	j	412c <osd_text+0x78>
    4128:	00000593          	li	a1,0
    412c:	00b66633          	or	a2,a2,a1
            p[1] = ((bits & 0x10u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    4130:	00c7a223          	sw	a2,4(a5)
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    4134:	00477613          	andi	a2,a4,4
    4138:	00060663          	beqz	a2,4144 <osd_text+0x90>
    413c:	01041613          	slli	a2,s0,0x10
    4140:	0080006f          	j	4148 <osd_text+0x94>
    4144:	00000613          	li	a2,0
                 | ((bits & 0x08u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    4148:	00877593          	andi	a1,a4,8
    414c:	00058663          	beqz	a1,4158 <osd_text+0xa4>
    4150:	00040593          	mv	a1,s0
    4154:	0080006f          	j	415c <osd_text+0xa8>
    4158:	00000593          	li	a1,0
    415c:	00b66633          	or	a2,a2,a1
            p[2] = ((bits & 0x04u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    4160:	00c7a423          	sw	a2,8(a5)
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    4164:	00177613          	andi	a2,a4,1
    4168:	00060663          	beqz	a2,4174 <osd_text+0xc0>
    416c:	01041613          	slli	a2,s0,0x10
    4170:	0080006f          	j	4178 <osd_text+0xc4>
    4174:	00000613          	li	a2,0
                 | ((bits & 0x02u) ? (uint32_t)fg : (uint32_t)COL_OSD_BG);
    4178:	00277713          	andi	a4,a4,2
    417c:	00070663          	beqz	a4,4188 <osd_text+0xd4>
    4180:	00040713          	mv	a4,s0
    4184:	0080006f          	j	418c <osd_text+0xd8>
    4188:	00000713          	li	a4,0
    418c:	00e66733          	or	a4,a2,a4
            p[3] = ((bits & 0x01u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    4190:	00e7a623          	sw	a4,12(a5)
        for (row = 0; row < 8; row++) {
    4194:	00168693          	addi	a3,a3,1
    4198:	00700793          	li	a5,7
    419c:	02d7ce63          	blt	a5,a3,41d8 <osd_text+0x124>
            uint8_t bits = rp[row];
    41a0:	00d507b3          	add	a5,a0,a3
    41a4:	0007c703          	lbu	a4,0(a5)
                                    + (uint32_t)(y + row) * FB_STRIDE + (uint32_t)x * 2u);
    41a8:	01268633          	add	a2,a3,s2
    41ac:	00461793          	slli	a5,a2,0x4
    41b0:	40c787b3          	sub	a5,a5,a2
    41b4:	00679793          	slli	a5,a5,0x6
    41b8:	009787b3          	add	a5,a5,s1
    41bc:	00179793          	slli	a5,a5,0x1
    41c0:	8341a603          	lw	a2,-1996(gp) # 791c <g_fb_back>
    41c4:	00c787b3          	add	a5,a5,a2
            p[0] = ((bits & 0x40u) ? ((uint32_t)fg << 16) : ((uint32_t)COL_OSD_BG << 16))
    41c8:	04077613          	andi	a2,a4,64
    41cc:	f0060ae3          	beqz	a2,40e0 <osd_text+0x2c>
    41d0:	01041613          	slli	a2,s0,0x10
    41d4:	f11ff06f          	j	40e4 <osd_text+0x30>
        x += OSD_GLYPH_W;
    41d8:	00848493          	addi	s1,s1,8
    while (*s) {
    41dc:	0009c503          	lbu	a0,0(s3)
    41e0:	00050a63          	beqz	a0,41f4 <osd_text+0x140>
        const uint8_t *rp = glyph_of(*s++);
    41e4:	00198993          	addi	s3,s3,1
    41e8:	ce1fd0ef          	jal	1ec8 <glyph_of>
        for (row = 0; row < 8; row++) {
    41ec:	00000693          	li	a3,0
    41f0:	fa9ff06f          	j	4198 <osd_text+0xe4>
}
    41f4:	01c12083          	lw	ra,28(sp)
    41f8:	01812403          	lw	s0,24(sp)
    41fc:	01412483          	lw	s1,20(sp)
    4200:	01012903          	lw	s2,16(sp)
    4204:	00c12983          	lw	s3,12(sp)
    4208:	02010113          	addi	sp,sp,32
    420c:	00008067          	ret

00004210 <path_label>:
static const char *path_label(void) { return (g_mode == MD_SW) ? "PURE CPU" : "HW ACCEL"; }
    4210:	8201a703          	lw	a4,-2016(gp) # 7908 <g_mode>
    4214:	00100793          	li	a5,1
    4218:	00f70863          	beq	a4,a5,4228 <path_label+0x18>
    421c:	00006537          	lui	a0,0x6
    4220:	57450513          	addi	a0,a0,1396 # 6574 <_data+0x7c>
    4224:	00008067          	ret
    4228:	00006537          	lui	a0,0x6
    422c:	56850513          	addi	a0,a0,1384 # 6568 <_data+0x70>
    4230:	00008067          	ret

00004234 <osd_build>:
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
    fmt_stat(g_osd_line, g_hw_fps, g_sw_fps, g_ncap, g_on_screen, g_score, g_level, g_hp,
    4258:	8701a403          	lw	s0,-1936(gp) # 7958 <g_hw_fps>
    425c:	86c1a483          	lw	s1,-1940(gp) # 7954 <g_sw_fps>
    4260:	81c1a903          	lw	s2,-2020(gp) # 7904 <g_ncap>
    4264:	85c1a983          	lw	s3,-1956(gp) # 7944 <g_on_screen>
    4268:	8901aa03          	lw	s4,-1904(gp) # 7978 <g_score>
    426c:	8101aa83          	lw	s5,-2032(gp) # 78f8 <g_level>
    4270:	8181ab03          	lw	s6,-2024(gp) # 7900 <g_hp>
    4274:	901fd0ef          	jal	1b74 <bulm_eff_name>
    4278:	89c1a783          	lw	a5,-1892(gp) # 7984 <g_auto>
    427c:	00f12423          	sw	a5,8(sp)
    4280:	8241a783          	lw	a5,-2012(gp) # 790c <g_star_n>
    4284:	00f027b3          	sgtz	a5,a5
    4288:	00f12223          	sw	a5,4(sp)
    428c:	00a12023          	sw	a0,0(sp)
    4290:	000b0893          	mv	a7,s6
    4294:	000a8813          	mv	a6,s5
    4298:	000a0793          	mv	a5,s4
    429c:	00098713          	mv	a4,s3
    42a0:	00090693          	mv	a3,s2
    42a4:	00048613          	mv	a2,s1
    42a8:	00040593          	mv	a1,s0
    42ac:	8fc18513          	addi	a0,gp,-1796 # 79e4 <g_osd_line>
    42b0:	c35ff0ef          	jal	3ee4 <fmt_stat>
}
    42b4:	02c12083          	lw	ra,44(sp)
    42b8:	02812403          	lw	s0,40(sp)
    42bc:	02412483          	lw	s1,36(sp)
    42c0:	02012903          	lw	s2,32(sp)
    42c4:	01c12983          	lw	s3,28(sp)
    42c8:	01812a03          	lw	s4,24(sp)
    42cc:	01412a83          	lw	s5,20(sp)
    42d0:	01012b03          	lw	s6,16(sp)
    42d4:	03010113          	addi	sp,sp,48
    42d8:	00008067          	ret

000042dc <osd_blit>:
{
    42dc:	ff010113          	addi	sp,sp,-16
    42e0:	00112623          	sw	ra,12(sp)
    42e4:	00812423          	sw	s0,8(sp)
    42e8:	00912223          	sw	s1,4(sp)
    const char *lbl = path_label();
    42ec:	f25ff0ef          	jal	4210 <path_label>
    42f0:	00050413          	mv	s0,a0
    int lw = slen(g_osd_line);
    42f4:	8fc18513          	addi	a0,gp,-1796 # 79e4 <g_osd_line>
    42f8:	bcdff0ef          	jal	3ec4 <slen>
    int lx = OSD_GLYPH_W * lw;
    42fc:	00351693          	slli	a3,a0,0x3
    if (lw > OSD_LEFT_CH) { lw = OSD_LEFT_CH; lx = OSD_LEFT_PX; }
    4300:	04000793          	li	a5,64
    4304:	00a7d463          	bge	a5,a0,430c <osd_blit+0x30>
    4308:	20000693          	li	a3,512
    cpu_fill32(g_fb_back, OSD_TEXT_X0, 0, lx, OSD_H, COL_OSD_BG);
    430c:	00000793          	li	a5,0
    4310:	01000713          	li	a4,16
    4314:	00000613          	li	a2,0
    4318:	00800593          	li	a1,8
    431c:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    4320:	cc5fd0ef          	jal	1fe4 <cpu_fill32>
    cpu_fill32(g_fb_back, FB_WIDTH - OSD_RIGHT_PX, 0, OSD_RIGHT_PX, OSD_H, COL_OSD_BG);
    4324:	00000793          	li	a5,0
    4328:	01000713          	li	a4,16
    432c:	04000693          	li	a3,64
    4330:	00000613          	li	a2,0
    4334:	38000593          	li	a1,896
    4338:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    433c:	ca9fd0ef          	jal	1fe4 <cpu_fill32>
    osd_text(OSD_TEXT_X0, OSD_TEXT_Y, g_osd_line, COL_WHITE);
    4340:	000106b7          	lui	a3,0x10
    4344:	fff68693          	addi	a3,a3,-1 # ffff <__global_pointer$+0x7f17>
    4348:	8fc18613          	addi	a2,gp,-1796 # 79e4 <g_osd_line>
    434c:	00400593          	li	a1,4
    4350:	00800513          	li	a0,8
    4354:	d61ff0ef          	jal	40b4 <osd_text>
    osd_text(FB_WIDTH - OSD_GLYPH_W * slen(lbl), OSD_TEXT_Y, lbl, COL_CYAN);
    4358:	00040513          	mv	a0,s0
    435c:	b69ff0ef          	jal	3ec4 <slen>
    4360:	07800793          	li	a5,120
    4364:	40a78533          	sub	a0,a5,a0
    4368:	7ff00693          	li	a3,2047
    436c:	00040613          	mv	a2,s0
    4370:	00400593          	li	a1,4
    4374:	00351513          	slli	a0,a0,0x3
    4378:	d3dff0ef          	jal	40b4 <osd_text>
}
    437c:	00c12083          	lw	ra,12(sp)
    4380:	00812403          	lw	s0,8(sp)
    4384:	00412483          	lw	s1,4(sp)
    4388:	01010113          	addi	sp,sp,16
    438c:	00008067          	ret

00004390 <center_text>:
{
    4390:	fe010113          	addi	sp,sp,-32
    4394:	00112e23          	sw	ra,28(sp)
    4398:	00812c23          	sw	s0,24(sp)
    439c:	00912a23          	sw	s1,20(sp)
    43a0:	01212823          	sw	s2,16(sp)
    43a4:	01312623          	sw	s3,12(sp)
    43a8:	00050913          	mv	s2,a0
    43ac:	00058493          	mv	s1,a1
    43b0:	00060993          	mv	s3,a2
    int n = slen(s);
    43b4:	b11ff0ef          	jal	3ec4 <slen>
    int x = (FB_WIDTH - OSD_GLYPH_W * n) / 2;
    43b8:	07800413          	li	s0,120
    43bc:	40a40433          	sub	s0,s0,a0
    43c0:	00241413          	slli	s0,s0,0x2
    if (x < 8) x = 8;
    43c4:	00700793          	li	a5,7
    43c8:	0087c463          	blt	a5,s0,43d0 <center_text+0x40>
    43cc:	00800413          	li	s0,8
    if (x + OSD_GLYPH_W * n + 8 > FB_WIDTH) return;
    43d0:	00351793          	slli	a5,a0,0x3
    43d4:	008787b3          	add	a5,a5,s0
    43d8:	3b800713          	li	a4,952
    43dc:	02f75063          	bge	a4,a5,43fc <center_text+0x6c>
}
    43e0:	01c12083          	lw	ra,28(sp)
    43e4:	01812403          	lw	s0,24(sp)
    43e8:	01412483          	lw	s1,20(sp)
    43ec:	01012903          	lw	s2,16(sp)
    43f0:	00c12983          	lw	s3,12(sp)
    43f4:	02010113          	addi	sp,sp,32
    43f8:	00008067          	ret
    cpu_fill32(g_fb_back, x - 8, y - 4, OSD_GLYPH_W * n + 16, OSD_GLYPH_H + 8, COL_OSD_BG);
    43fc:	00250693          	addi	a3,a0,2
    4400:	00000793          	li	a5,0
    4404:	01000713          	li	a4,16
    4408:	00369693          	slli	a3,a3,0x3
    440c:	ffc48613          	addi	a2,s1,-4
    4410:	ff840593          	addi	a1,s0,-8
    4414:	8341a503          	lw	a0,-1996(gp) # 791c <g_fb_back>
    4418:	bcdfd0ef          	jal	1fe4 <cpu_fill32>
    osd_text(x, y, s, fg);
    441c:	00098693          	mv	a3,s3
    4420:	00090613          	mv	a2,s2
    4424:	00048593          	mv	a1,s1
    4428:	00040513          	mv	a0,s0
    442c:	c89ff0ef          	jal	40b4 <osd_text>
    4430:	fb1ff06f          	j	43e0 <center_text+0x50>

00004434 <overlay_draw>:
{
    4434:	ff010113          	addi	sp,sp,-16
    4438:	00112623          	sw	ra,12(sp)
    if (g_state == GS_TITLE) {
    443c:	8a41a783          	lw	a5,-1884(gp) # 798c <g_state>
    4440:	02078063          	beqz	a5,4460 <overlay_draw+0x2c>
    } else if (g_pause) {
    4444:	8a01a703          	lw	a4,-1888(gp) # 7988 <g_pause>
    4448:	06071c63          	bnez	a4,44c0 <overlay_draw+0x8c>
    } else if (g_state == GS_OVER) {
    444c:	00200713          	li	a4,2
    4450:	08e78663          	beq	a5,a4,44dc <overlay_draw+0xa8>
}
    4454:	00c12083          	lw	ra,12(sp)
    4458:	01010113          	addi	sp,sp,16
    445c:	00008067          	ret
        center_text("DANMAKU SURVIVAL", y - 40, COL_CYAN);
    4460:	7ff00613          	li	a2,2047
    4464:	0b000593          	li	a1,176
    4468:	00006537          	lui	a0,0x6
    446c:	58050513          	addi	a0,a0,1408 # 6580 <_data+0x88>
    4470:	f21ff0ef          	jal	4390 <center_text>
        center_text("HW 2D ACCEL DEMO", y - 16, COL_WHITE);
    4474:	00010637          	lui	a2,0x10
    4478:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f17>
    447c:	0c800593          	li	a1,200
    4480:	00006537          	lui	a0,0x6
    4484:	59450513          	addi	a0,a0,1428 # 6594 <_data+0x9c>
    4488:	f09ff0ef          	jal	4390 <center_text>
        center_text("PRESS FIRE (J / SPACE)", y + 28, COL_AMBER);
    448c:	00010637          	lui	a2,0x10
    4490:	d2060613          	addi	a2,a2,-736 # fd20 <__global_pointer$+0x7c38>
    4494:	0f400593          	li	a1,244
    4498:	00006537          	lui	a0,0x6
    449c:	5a850513          	addi	a0,a0,1448 # 65a8 <_data+0xb0>
    44a0:	ef1ff0ef          	jal	4390 <center_text>
        center_text("WASD MOVE  K FOCUS  L BOMB", y + 52, COL_GRAY);
    44a4:	00008637          	lui	a2,0x8
    44a8:	41060613          	addi	a2,a2,1040 # 8410 <__global_pointer$+0x328>
    44ac:	10c00593          	li	a1,268
    44b0:	00006537          	lui	a0,0x6
    44b4:	5c050513          	addi	a0,a0,1472 # 65c0 <_data+0xc8>
    44b8:	ed9ff0ef          	jal	4390 <center_text>
    44bc:	f99ff06f          	j	4454 <overlay_draw+0x20>
        center_text("PAUSED", y, COL_AMBER);
    44c0:	00010637          	lui	a2,0x10
    44c4:	d2060613          	addi	a2,a2,-736 # fd20 <__global_pointer$+0x7c38>
    44c8:	0d800593          	li	a1,216
    44cc:	00006537          	lui	a0,0x6
    44d0:	5dc50513          	addi	a0,a0,1500 # 65dc <_data+0xe4>
    44d4:	ebdff0ef          	jal	4390 <center_text>
    44d8:	f7dff06f          	j	4454 <overlay_draw+0x20>
        center_text("GAME OVER", y - 16, COL_RED);
    44dc:	00010637          	lui	a2,0x10
    44e0:	80060613          	addi	a2,a2,-2048 # f800 <__global_pointer$+0x7718>
    44e4:	0c800593          	li	a1,200
    44e8:	00006537          	lui	a0,0x6
    44ec:	5e450513          	addi	a0,a0,1508 # 65e4 <_data+0xec>
    44f0:	ea1ff0ef          	jal	4390 <center_text>
        center_text("PRESS FIRE TO RESTART", y + 20, COL_WHITE);
    44f4:	00010637          	lui	a2,0x10
    44f8:	fff60613          	addi	a2,a2,-1 # ffff <__global_pointer$+0x7f17>
    44fc:	0ec00593          	li	a1,236
    4500:	00006537          	lui	a0,0x6
    4504:	5f050513          	addi	a0,a0,1520 # 65f0 <_data+0xf8>
    4508:	e89ff0ef          	jal	4390 <center_text>
}
    450c:	f49ff06f          	j	4454 <overlay_draw+0x20>

00004510 <stars_reset>:
{
    4510:	ff010113          	addi	sp,sp,-16
    4514:	00112623          	sw	ra,12(sp)
    4518:	00812423          	sw	s0,8(sp)
    451c:	00912223          	sw	s1,4(sp)
    for (i = 0; i < STAR_MAX; i++) {
    4520:	00000493          	li	s1,0
    4524:	0380006f          	j	455c <stars_reset+0x4c>
        g_star[i].col = (uint16_t)((rnd() & 1u) ? 0x18E3u : 0x0841u);
    4528:	000017b7          	lui	a5,0x1
    452c:	84178793          	addi	a5,a5,-1983 # 841 <CUSTOM2+0x7e6>
    4530:	00008437          	lui	s0,0x8
    4534:	00349713          	slli	a4,s1,0x3
    4538:	a2840413          	addi	s0,s0,-1496 # 7a28 <g_star>
    453c:	00e40433          	add	s0,s0,a4
    4540:	00f41223          	sh	a5,4(s0)
        g_star[i].spd = (uint8_t)(1u + (rnd() % 3u));
    4544:	bf0fe0ef          	jal	2934 <rnd>
    4548:	00300793          	li	a5,3
    454c:	02f57533          	remu	a0,a0,a5
    4550:	00150513          	addi	a0,a0,1
    4554:	00a40323          	sb	a0,6(s0)
    for (i = 0; i < STAR_MAX; i++) {
    4558:	00148493          	addi	s1,s1,1
    455c:	03f00793          	li	a5,63
    4560:	0497c863          	blt	a5,s1,45b0 <stars_reset+0xa0>
        g_star[i].x = (int16_t)(rnd() % (uint32_t)(FB_WIDTH - 2));
    4564:	bd0fe0ef          	jal	2934 <rnd>
    4568:	3be00793          	li	a5,958
    456c:	02f57533          	remu	a0,a0,a5
    4570:	00008437          	lui	s0,0x8
    4574:	00349793          	slli	a5,s1,0x3
    4578:	a2840413          	addi	s0,s0,-1496 # 7a28 <g_star>
    457c:	00f40433          	add	s0,s0,a5
    4580:	00a41023          	sh	a0,0(s0)
        g_star[i].y = (int16_t)(PLAY_Y0 + (rnd() % (uint32_t)(PLAY_H - 2)));
    4584:	bb0fe0ef          	jal	2934 <rnd>
    4588:	20a00793          	li	a5,522
    458c:	02f57533          	remu	a0,a0,a5
    4590:	01050513          	addi	a0,a0,16
    4594:	00a41123          	sh	a0,2(s0)
        g_star[i].col = (uint16_t)((rnd() & 1u) ? 0x18E3u : 0x0841u);
    4598:	b9cfe0ef          	jal	2934 <rnd>
    459c:	00157513          	andi	a0,a0,1
    45a0:	f80504e3          	beqz	a0,4528 <stars_reset+0x18>
    45a4:	000027b7          	lui	a5,0x2
    45a8:	8e378793          	addi	a5,a5,-1821 # 18e3 <_putchar_s+0x1b>
    45ac:	f85ff06f          	j	4530 <stars_reset+0x20>
}
    45b0:	00c12083          	lw	ra,12(sp)
    45b4:	00812403          	lw	s0,8(sp)
    45b8:	00412483          	lw	s1,4(sp)
    45bc:	01010113          	addi	sp,sp,16
    45c0:	00008067          	ret

000045c4 <game_reset>:
    for (i = 0; i < BUL_TOTAL; i++) g_bul[i].life = 0;
    45c4:	00000713          	li	a4,0
    45c8:	0240006f          	j	45ec <game_reset+0x28>
    45cc:	000117b7          	lui	a5,0x11
    45d0:	00171693          	slli	a3,a4,0x1
    45d4:	00e686b3          	add	a3,a3,a4
    45d8:	00269613          	slli	a2,a3,0x2
    45dc:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    45e0:	00c787b3          	add	a5,a5,a2
    45e4:	000785a3          	sb	zero,11(a5)
    45e8:	00170713          	addi	a4,a4,1
    45ec:	000017b7          	lui	a5,0x1
    45f0:	97f78793          	addi	a5,a5,-1665 # 97f <CUSTOM2+0x924>
    45f4:	fce7dce3          	bge	a5,a4,45cc <game_reset+0x8>
    for (i = 0; i < SPARK_MAX; i++) g_spk[i].life = 0;
    45f8:	00000713          	li	a4,0
    45fc:	0240006f          	j	4620 <game_reset+0x5c>
    4600:	000117b7          	lui	a5,0x11
    4604:	00171693          	slli	a3,a4,0x1
    4608:	00e686b3          	add	a3,a3,a4
    460c:	00269613          	slli	a2,a3,0x2
    4610:	b6878793          	addi	a5,a5,-1176 # 10b68 <g_spk>
    4614:	00c787b3          	add	a5,a5,a2
    4618:	000785a3          	sb	zero,11(a5)
    461c:	00170713          	addi	a4,a4,1
    4620:	05f00793          	li	a5,95
    4624:	fce7dee3          	bge	a5,a4,4600 <game_reset+0x3c>
    g_bul_live = 0;
    4628:	8401aa23          	sw	zero,-1964(gp) # 793c <g_bul_live>
    for (i = 0; i < ENEMY_MAX; i++) {
    462c:	00000713          	li	a4,0
    4630:	03c0006f          	j	466c <game_reset+0xa8>
        g_en[i].t = 0; g_en[i].x = 0; g_en[i].y = 0; g_en[i].vx = 0; g_en[i].vy = 0;
    4634:	000117b7          	lui	a5,0x11
    4638:	00471693          	slli	a3,a4,0x4
    463c:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    4640:	00d787b3          	add	a5,a5,a3
    4644:	00079723          	sh	zero,14(a5)
    4648:	00079023          	sh	zero,0(a5)
    464c:	00079123          	sh	zero,2(a5)
    4650:	00079223          	sh	zero,4(a5)
    4654:	00079323          	sh	zero,6(a5)
        g_en[i].hp = 0; g_en[i].kind = 0; g_en[i].fire = 0; g_en[i].phase = 0;
    4658:	00079423          	sh	zero,8(a5)
    465c:	00078523          	sb	zero,10(a5)
    4660:	000785a3          	sb	zero,11(a5)
    4664:	00078623          	sb	zero,12(a5)
    for (i = 0; i < ENEMY_MAX; i++) {
    4668:	00170713          	addi	a4,a4,1
    466c:	01700793          	li	a5,23
    4670:	fce7d2e3          	bge	a5,a4,4634 <game_reset+0x70>
    g_px = (int16_t)FP(FB_WIDTH / 2);
    4674:	000017b7          	lui	a5,0x1
    4678:	f0078793          	addi	a5,a5,-256 # f00 <CUSTOM2+0xea5>
    467c:	88f19d23          	sh	a5,-1894(gp) # 7982 <g_px>
    g_py = (int16_t)FP(PLAY_Y1 - 70);
    4680:	000017b7          	lui	a5,0x1
    4684:	eb078793          	addi	a5,a5,-336 # eb0 <CUSTOM2+0xe55>
    4688:	88f19c23          	sh	a5,-1896(gp) # 7980 <g_py>
    g_invuln = 90; g_hp = 3; g_bomb = 3; g_level = 1; g_score = 0;
    468c:	05a00713          	li	a4,90
    4690:	88e1aa23          	sw	a4,-1900(gp) # 797c <g_invuln>
    4694:	00300793          	li	a5,3
    4698:	80f1ac23          	sw	a5,-2024(gp) # 7900 <g_hp>
    469c:	80f1aa23          	sw	a5,-2028(gp) # 78fc <g_bomb>
    46a0:	00100793          	li	a5,1
    46a4:	80f1a823          	sw	a5,-2032(gp) # 78f8 <g_level>
    46a8:	8801a823          	sw	zero,-1904(gp) # 7978 <g_score>
    g_shot_t = 0; g_level_t = 0; g_bomb_req = 0;
    46ac:	8801a623          	sw	zero,-1908(gp) # 7974 <g_shot_t>
    46b0:	8801a423          	sw	zero,-1912(gp) # 7970 <g_level_t>
    46b4:	8801a023          	sw	zero,-1920(gp) # 7968 <g_bomb_req>
    g_state = GS_PLAY; g_pause = 0;
    46b8:	8af1a223          	sw	a5,-1884(gp) # 798c <g_state>
    46bc:	8a01a023          	sw	zero,-1888(gp) # 7988 <g_pause>
    g_frames = 0;
    46c0:	8601aa23          	sw	zero,-1932(gp) # 795c <g_frames>
}
    46c4:	00008067          	ret

000046c8 <wait_engine_idle>:
{
    46c8:	ff010113          	addi	sp,sp,-16
    46cc:	00112623          	sw	ra,12(sp)
    46d0:	00812423          	sw	s0,8(sp)
    46d4:	00912223          	sw	s1,4(sp)
    46d8:	01212023          	sw	s2,0(sp)
    uint32_t t0 = tick32();
    46dc:	855fd0ef          	jal	1f30 <tick32>
    46e0:	00050913          	mv	s2,a0
    uint32_t spin = 0;
    46e4:	00000413          	li	s0,0
    46e8:	0100006f          	j	46f8 <wait_engine_idle+0x30>
        spin++;
    46ec:	00140413          	addi	s0,s0,1
        cpu_backoff(BLT_WAIT_NOP);
    46f0:	03000513          	li	a0,48
    46f4:	849fd0ef          	jal	1f3c <cpu_backoff>
        if ((spin & BLT_WAIT_MASK) == 0u) {
    46f8:	00347793          	andi	a5,s0,3
    46fc:	fe0798e3          	bnez	a5,46ec <wait_engine_idle+0x24>
            if (blt_idle_st(blt_stat())) return 1;
    4700:	d51fd0ef          	jal	2450 <blt_stat>
    4704:	d69fd0ef          	jal	246c <blt_idle_st>
    4708:	00050493          	mv	s1,a0
    470c:	00051e63          	bnez	a0,4728 <wait_engine_idle+0x60>
            if ((uint32_t)(tick32() - t0) > (uint32_t)ENGINE_TO_TICKS) return 0;
    4710:	821fd0ef          	jal	1f30 <tick32>
    4714:	41250533          	sub	a0,a0,s2
    4718:	000f47b7          	lui	a5,0xf4
    471c:	24078793          	addi	a5,a5,576 # f4240 <__freertos_irq_stack_top+0xdb040>
    4720:	fca7f6e3          	bgeu	a5,a0,46ec <wait_engine_idle+0x24>
    4724:	0080006f          	j	472c <wait_engine_idle+0x64>
            if (blt_idle_st(blt_stat())) return 1;
    4728:	00100493          	li	s1,1
}
    472c:	00048513          	mv	a0,s1
    4730:	00c12083          	lw	ra,12(sp)
    4734:	00812403          	lw	s0,8(sp)
    4738:	00412483          	lw	s1,4(sp)
    473c:	00012903          	lw	s2,0(sp)
    4740:	01010113          	addi	sp,sp,16
    4744:	00008067          	ret

00004748 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    4748:	fc010113          	addi	sp,sp,-64
    474c:	00112e23          	sw	ra,28(sp)
    4750:	00812c23          	sw	s0,24(sp)
    4754:	00912a23          	sw	s1,20(sp)
    4758:	00050493          	mv	s1,a0
    475c:	02b12223          	sw	a1,36(sp)
    4760:	02c12423          	sw	a2,40(sp)
    4764:	02d12623          	sw	a3,44(sp)
    4768:	02e12823          	sw	a4,48(sp)
    476c:	02f12a23          	sw	a5,52(sp)
    4770:	03012c23          	sw	a6,56(sp)
    4774:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    4778:	02410793          	addi	a5,sp,36
    477c:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    4780:	00000413          	li	s0,0
    4784:	01c0006f          	j	47a0 <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    4788:	00c12783          	lw	a5,12(sp)
    478c:	00478713          	addi	a4,a5,4
    4790:	00e12623          	sw	a4,12(sp)
    4794:	0007a503          	lw	a0,0(a5)
    4798:	a0cfd0ef          	jal	19a4 <bsp_printf_c>
        for (i = 0; format[i]; i++)
    479c:	00140413          	addi	s0,s0,1
    47a0:	008487b3          	add	a5,s1,s0
    47a4:	0007c503          	lbu	a0,0(a5)
    47a8:	0a050e63          	beqz	a0,4864 <bsp_printf+0x11c>
            if (format[i] == '%') {
    47ac:	02500793          	li	a5,37
    47b0:	06f50e63          	beq	a0,a5,482c <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    47b4:	9f0fd0ef          	jal	19a4 <bsp_printf_c>
    47b8:	fe5ff06f          	j	479c <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    47bc:	00c12783          	lw	a5,12(sp)
    47c0:	00478713          	addi	a4,a5,4
    47c4:	00e12623          	sw	a4,12(sp)
    47c8:	0007a503          	lw	a0,0(a5)
    47cc:	9f4fd0ef          	jal	19c0 <bsp_printf_s>
                        break;
    47d0:	fcdff06f          	j	479c <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    47d4:	00c12783          	lw	a5,12(sp)
    47d8:	00478713          	addi	a4,a5,4
    47dc:	00e12623          	sw	a4,12(sp)
    47e0:	0007a503          	lw	a0,0(a5)
    47e4:	9f4fd0ef          	jal	19d8 <bsp_printf_d>
                        break;
    47e8:	fb5ff06f          	j	479c <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    47ec:	00c12783          	lw	a5,12(sp)
    47f0:	00478713          	addi	a4,a5,4
    47f4:	00e12623          	sw	a4,12(sp)
    47f8:	0007a503          	lw	a0,0(a5)
    47fc:	a9cfd0ef          	jal	1a98 <bsp_printf_X>
                        break;
    4800:	f9dff06f          	j	479c <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    4804:	00c12783          	lw	a5,12(sp)
    4808:	00478713          	addi	a4,a5,4
    480c:	00e12623          	sw	a4,12(sp)
    4810:	0007a503          	lw	a0,0(a5)
    4814:	a44fd0ef          	jal	1a58 <bsp_printf_x>
                        break;
    4818:	f85ff06f          	j	479c <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    481c:	00006537          	lui	a0,0x6
    4820:	60850513          	addi	a0,a0,1544 # 6608 <_data+0x110>
    4824:	99cfd0ef          	jal	19c0 <bsp_printf_s>
                        break;
    4828:	f75ff06f          	j	479c <bsp_printf+0x54>
                while (format[++i]) {
    482c:	00140413          	addi	s0,s0,1
    4830:	008487b3          	add	a5,s1,s0
    4834:	0007c783          	lbu	a5,0(a5)
    4838:	f60782e3          	beqz	a5,479c <bsp_printf+0x54>
                    if (format[i] == 'c') {
    483c:	fa878793          	addi	a5,a5,-88
    4840:	0ff7f693          	zext.b	a3,a5
    4844:	02000713          	li	a4,32
    4848:	fed762e3          	bltu	a4,a3,482c <bsp_printf+0xe4>
    484c:	00269793          	slli	a5,a3,0x2
    4850:	00007737          	lui	a4,0x7
    4854:	41470713          	addi	a4,a4,1044 # 7414 <_data+0xf1c>
    4858:	00e787b3          	add	a5,a5,a4
    485c:	0007a783          	lw	a5,0(a5)
    4860:	00078067          	jr	a5

        va_end(ap);
    }
    4864:	01c12083          	lw	ra,28(sp)
    4868:	01812403          	lw	s0,24(sp)
    486c:	01412483          	lw	s1,20(sp)
    4870:	04010113          	addi	sp,sp,64
    4874:	00008067          	ret

00004878 <feat_probe>:
{
    4878:	ff010113          	addi	sp,sp,-16
    487c:	00112623          	sw	ra,12(sp)
    4880:	00812423          	sw	s0,8(sp)
    blt_wr(BLT_CLIP_X0, 0x00000123UL); blt_wr(BLT_CLIP_X1, 0x00000456UL);
    4884:	12300593          	li	a1,291
    4888:	09000513          	li	a0,144
    488c:	ec0fd0ef          	jal	1f4c <blt_wr>
    4890:	45600593          	li	a1,1110
    4894:	09400513          	li	a0,148
    4898:	eb4fd0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_CLIP_Y0, 0x00000789UL); blt_wr(BLT_CLIP_Y1, 0x00000AB0UL);
    489c:	78900593          	li	a1,1929
    48a0:	09800513          	li	a0,152
    48a4:	ea8fd0ef          	jal	1f4c <blt_wr>
    48a8:	000015b7          	lui	a1,0x1
    48ac:	ab058593          	addi	a1,a1,-1360 # ab0 <CUSTOM2+0xa55>
    48b0:	09c00513          	li	a0,156
    48b4:	e98fd0ef          	jal	1f4c <blt_wr>
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    48b8:	09000513          	li	a0,144
    48bc:	ea0fd0ef          	jal	1f5c <blt_rd>
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);
    48c0:	12300793          	li	a5,291
    48c4:	06f50663          	beq	a0,a5,4930 <feat_probe+0xb8>
    48c8:	00000713          	li	a4,0
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    48cc:	8ee1aa23          	sw	a4,-1804(gp) # 79dc <g_feat_clip>
    blt_wr(BLT_CLIP_CTRL, 0UL);                 /* ★ 本 Demo 不用裁剪：必须显式关掉 */
    48d0:	00000593          	li	a1,0
    48d4:	0a000513          	li	a0,160
    48d8:	e74fd0ef          	jal	1f4c <blt_wr>
    blt_wr(BLT_LUT_CTRL, 0UL);
    48dc:	00000593          	li	a1,0
    48e0:	0ac00513          	li	a0,172
    48e4:	e68fd0ef          	jal	1f4c <blt_wr>
    lc = blt_rd(BLT_LUT_CTRL) & 3UL;
    48e8:	0ac00513          	li	a0,172
    48ec:	e70fd0ef          	jal	1f5c <blt_rd>
    48f0:	00357413          	andi	s0,a0,3
    blt_wr(BLT_LUT_CTRL, BLT_LUT_EN | BLT_LUT_BANK);
    48f4:	00300593          	li	a1,3
    48f8:	0ac00513          	li	a0,172
    48fc:	e50fd0ef          	jal	1f4c <blt_wr>
    g_feat_lut = (lc == 0UL) && ((blt_rd(BLT_LUT_CTRL) & 3UL) == (BLT_LUT_EN | BLT_LUT_BANK));
    4900:	08040263          	beqz	s0,4984 <feat_probe+0x10c>
    4904:	00000713          	li	a4,0
    4908:	8ee1a823          	sw	a4,-1808(gp) # 79d8 <g_feat_lut>
    blt_wr(BLT_LUT_CTRL, 0UL);                  /* 关掉：没写表就不是恒等表，开了会黑屏 */
    490c:	00000593          	li	a1,0
    4910:	0ac00513          	li	a0,172
    4914:	e38fd0ef          	jal	1f4c <blt_wr>
    g_glow = (g_feat_clip && g_feat_lut) ? 1 : 0;
    4918:	8f41a583          	lw	a1,-1804(gp) # 79dc <g_feat_clip>
    491c:	08058663          	beqz	a1,49a8 <feat_probe+0x130>
    4920:	8f01a783          	lw	a5,-1808(gp) # 79d8 <g_feat_lut>
    4924:	0c079c63          	bnez	a5,49fc <feat_probe+0x184>
    4928:	00000693          	li	a3,0
    492c:	0800006f          	j	49ac <feat_probe+0x134>
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    4930:	09400513          	li	a0,148
    4934:	e28fd0ef          	jal	1f5c <blt_rd>
    4938:	45600793          	li	a5,1110
    493c:	00f50663          	beq	a0,a5,4948 <feat_probe+0xd0>
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);
    4940:	00000713          	li	a4,0
    4944:	f89ff06f          	j	48cc <feat_probe+0x54>
    4948:	09800513          	li	a0,152
    494c:	e10fd0ef          	jal	1f5c <blt_rd>
    g_feat_clip = (blt_rd(BLT_CLIP_X0) == 0x123UL) && (blt_rd(BLT_CLIP_X1) == 0x456UL) &&
    4950:	78900793          	li	a5,1929
    4954:	00f50663          	beq	a0,a5,4960 <feat_probe+0xe8>
                  (blt_rd(BLT_CLIP_Y0) == 0x789UL) && (blt_rd(BLT_CLIP_Y1) == 0xAB0UL);
    4958:	00000713          	li	a4,0
    495c:	f71ff06f          	j	48cc <feat_probe+0x54>
    4960:	09c00513          	li	a0,156
    4964:	df8fd0ef          	jal	1f5c <blt_rd>
    4968:	000017b7          	lui	a5,0x1
    496c:	ab078793          	addi	a5,a5,-1360 # ab0 <CUSTOM2+0xa55>
    4970:	00f50663          	beq	a0,a5,497c <feat_probe+0x104>
    4974:	00000713          	li	a4,0
    4978:	f55ff06f          	j	48cc <feat_probe+0x54>
    497c:	00100713          	li	a4,1
    4980:	f4dff06f          	j	48cc <feat_probe+0x54>
    g_feat_lut = (lc == 0UL) && ((blt_rd(BLT_LUT_CTRL) & 3UL) == (BLT_LUT_EN | BLT_LUT_BANK));
    4984:	0ac00513          	li	a0,172
    4988:	dd4fd0ef          	jal	1f5c <blt_rd>
    498c:	00357513          	andi	a0,a0,3
    4990:	00300793          	li	a5,3
    4994:	00f50663          	beq	a0,a5,49a0 <feat_probe+0x128>
    4998:	00000713          	li	a4,0
    499c:	f6dff06f          	j	4908 <feat_probe+0x90>
    49a0:	00100713          	li	a4,1
    49a4:	f65ff06f          	j	4908 <feat_probe+0x90>
    g_glow = (g_feat_clip && g_feat_lut) ? 1 : 0;
    49a8:	00000693          	li	a3,0
    49ac:	8ed1ac23          	sw	a3,-1800(gp) # 79e0 <g_glow>
    g_attr_on = g_glow;                         /* ★ 属性字只在确认存在时才写（配对纪律） */
    49b0:	8ed1a623          	sw	a3,-1812(gp) # 79d4 <g_attr_on>
    g_bulm = g_glow ? BULM_ADD : BULM_KEY;
    49b4:	04068863          	beqz	a3,4a04 <feat_probe+0x18c>
    49b8:	00200713          	li	a4,2
    49bc:	82e1ac23          	sw	a4,-1992(gp) # 7920 <g_bulm>
    bsp_printf("feat: clip=%d lut=%d attr=%d (attr=>glow ADD, else KEY fallback)\r\n",
    49c0:	8f01a603          	lw	a2,-1808(gp) # 79d8 <g_feat_lut>
    49c4:	00006537          	lui	a0,0x6
    49c8:	65450513          	addi	a0,a0,1620 # 6654 <_data+0x15c>
    49cc:	d7dff0ef          	jal	4748 <bsp_printf>
    bsp_printf("bulm: default=%s  (f cycles, 5=FILL 6=ALPHA 7=ADD 8=KEY)\r\n",
    49d0:	9a4fd0ef          	jal	1b74 <bulm_eff_name>
    49d4:	00050593          	mv	a1,a0
    49d8:	00006537          	lui	a0,0x6
    49dc:	69850513          	addi	a0,a0,1688 # 6698 <_data+0x1a0>
    49e0:	d69ff0ef          	jal	4748 <bsp_printf>
    if (!g_glow)
    49e4:	8f81a783          	lw	a5,-1800(gp) # 79e0 <g_glow>
    49e8:	02078263          	beqz	a5,4a0c <feat_probe+0x194>
}
    49ec:	00c12083          	lw	ra,12(sp)
    49f0:	00812403          	lw	s0,8(sp)
    49f4:	01010113          	addi	sp,sp,16
    49f8:	00008067          	ret
    g_glow = (g_feat_clip && g_feat_lut) ? 1 : 0;
    49fc:	00100693          	li	a3,1
    4a00:	fadff06f          	j	49ac <feat_probe+0x134>
    g_bulm = g_glow ? BULM_ADD : BULM_KEY;
    4a04:	00300713          	li	a4,3
    4a08:	fb5ff06f          	j	49bc <feat_probe+0x144>
        bsp_printf("feat WARN: v3.2 attr side-port ABSENT -> bullets use Color Key (still correct)\r\n");
    4a0c:	00006537          	lui	a0,0x6
    4a10:	6d450513          	addi	a0,a0,1748 # 66d4 <_data+0x1dc>
    4a14:	d35ff0ef          	jal	4748 <bsp_printf>
}
    4a18:	fd5ff06f          	j	49ec <feat_probe+0x174>

00004a1c <boot_selfcheck>:
{
    4a1c:	f8010113          	addi	sp,sp,-128
    4a20:	06112e23          	sw	ra,124(sp)
    4a24:	06812c23          	sw	s0,120(sp)
    4a28:	06912a23          	sw	s1,116(sp)
    4a2c:	07212823          	sw	s2,112(sp)
    4a30:	07312623          	sw	s3,108(sp)
    4a34:	07412423          	sw	s4,104(sp)
    4a38:	07512223          	sw	s5,100(sp)
    4a3c:	07612023          	sw	s6,96(sp)
        tv[0].blend = ATTR_BLEND_OP;    tv[0].fmt = ATTR_FMT_565;  tv[0].ga = 255u; tv[0].fl = 0u;
    4a40:	00012e23          	sw	zero,28(sp)
    4a44:	02012023          	sw	zero,32(sp)
    4a48:	0ff00793          	li	a5,255
    4a4c:	02f12223          	sw	a5,36(sp)
    4a50:	02012423          	sw	zero,40(sp)
        tv[1].blend = ATTR_BLEND_ALPHA; tv[1].fmt = ATTR_FMT_4444; tv[1].ga = 128u; tv[1].fl = 0u;
    4a54:	00100793          	li	a5,1
    4a58:	02f12623          	sw	a5,44(sp)
    4a5c:	00200713          	li	a4,2
    4a60:	02e12823          	sw	a4,48(sp)
    4a64:	08000693          	li	a3,128
    4a68:	02d12a23          	sw	a3,52(sp)
    4a6c:	02012c23          	sw	zero,56(sp)
        tv[2].blend = ATTR_BLEND_ADD;   tv[2].fmt = ATTR_FMT_565;  tv[2].ga = 96u;  tv[2].fl = 0u;
    4a70:	02e12e23          	sw	a4,60(sp)
    4a74:	04012023          	sw	zero,64(sp)
    4a78:	06000713          	li	a4,96
    4a7c:	04e12223          	sw	a4,68(sp)
    4a80:	04012423          	sw	zero,72(sp)
        tv[3].blend = ATTR_BLEND_MUL;   tv[3].fmt = ATTR_FMT_1555; tv[3].ga = 64u;
    4a84:	00300713          	li	a4,3
    4a88:	04e12623          	sw	a4,76(sp)
    4a8c:	04f12823          	sw	a5,80(sp)
    4a90:	04000713          	li	a4,64
    4a94:	04e12a23          	sw	a4,84(sp)
        tv[3].fl = ATTR_FLAG_ATEST;
    4a98:	04f12c23          	sw	a5,88(sp)
        int i, bad = 0;
    4a9c:	00000993          	li	s3,0
        for (i = 0; i < 4; i++) {
    4aa0:	00000413          	li	s0,0
    4aa4:	00c0006f          	j	4ab0 <boot_selfcheck+0x94>
                attr_ga(w) != tv[i].ga || attr_flags(w) != tv[i].fl) bad++;
    4aa8:	00198993          	addi	s3,s3,1
        for (i = 0; i < 4; i++) {
    4aac:	00140413          	addi	s0,s0,1
    4ab0:	00300793          	li	a5,3
    4ab4:	0687c463          	blt	a5,s0,4b1c <boot_selfcheck+0x100>
            uint32_t w = attr_word(tv[i].blend, tv[i].fmt, tv[i].ga, tv[i].fl);
    4ab8:	00441793          	slli	a5,s0,0x4
    4abc:	06078793          	addi	a5,a5,96
    4ac0:	002787b3          	add	a5,a5,sp
    4ac4:	fbc7a903          	lw	s2,-68(a5)
    4ac8:	fc07aa03          	lw	s4,-64(a5)
    4acc:	fc47aa83          	lw	s5,-60(a5)
    4ad0:	fc87ab03          	lw	s6,-56(a5)
    4ad4:	000b0693          	mv	a3,s6
    4ad8:	000a8613          	mv	a2,s5
    4adc:	000a0593          	mv	a1,s4
    4ae0:	00090513          	mv	a0,s2
    4ae4:	82cfd0ef          	jal	1b10 <attr_word>
    4ae8:	00050493          	mv	s1,a0
            if (attr_blend(w) != tv[i].blend || attr_fmt(w) != tv[i].fmt ||
    4aec:	85cfd0ef          	jal	1b48 <attr_blend>
    4af0:	faa91ce3          	bne	s2,a0,4aa8 <boot_selfcheck+0x8c>
    4af4:	00048513          	mv	a0,s1
    4af8:	858fd0ef          	jal	1b50 <attr_fmt>
    4afc:	faaa16e3          	bne	s4,a0,4aa8 <boot_selfcheck+0x8c>
                attr_ga(w) != tv[i].ga || attr_flags(w) != tv[i].fl) bad++;
    4b00:	00048513          	mv	a0,s1
    4b04:	858fd0ef          	jal	1b5c <attr_ga>
            if (attr_blend(w) != tv[i].blend || attr_fmt(w) != tv[i].fmt ||
    4b08:	faaa90e3          	bne	s5,a0,4aa8 <boot_selfcheck+0x8c>
                attr_ga(w) != tv[i].ga || attr_flags(w) != tv[i].fl) bad++;
    4b0c:	00048513          	mv	a0,s1
    4b10:	858fd0ef          	jal	1b68 <attr_flags>
    4b14:	f8ab1ae3          	bne	s6,a0,4aa8 <boot_selfcheck+0x8c>
    4b18:	f95ff06f          	j	4aac <boot_selfcheck+0x90>
        d = attr_word(ATTR_BLEND_OP, ATTR_FMT_565, 255u, 0u);
    4b1c:	00000693          	li	a3,0
    4b20:	0ff00613          	li	a2,255
    4b24:	00000593          	li	a1,0
    4b28:	00000513          	li	a0,0
    4b2c:	fe5fc0ef          	jal	1b10 <attr_word>
    4b30:	00050613          	mv	a2,a0
        bsp_printf("selfcheck attr: decode_err=%d default=%x match=%d\r\n",
    4b34:	00100693          	li	a3,1
    4b38:	00098593          	mv	a1,s3
    4b3c:	00006537          	lui	a0,0x6
    4b40:	72850513          	addi	a0,a0,1832 # 6728 <_data+0x230>
    4b44:	c05ff0ef          	jal	4748 <bsp_printf>
               (unsigned)blend565(0xF800u, 0x001Fu, 128u),
    4b48:	08000613          	li	a2,128
    4b4c:	01f00593          	li	a1,31
    4b50:	00010537          	lui	a0,0x10
    4b54:	80050513          	addi	a0,a0,-2048 # f800 <__global_pointer$+0x7718>
    4b58:	d95fe0ef          	jal	38ec <blend565>
    4b5c:	00050413          	mv	s0,a0
               (unsigned)add565(0xF800u, 0x001Fu, 255u),
    4b60:	0ff00613          	li	a2,255
    4b64:	01f00593          	li	a1,31
    4b68:	00010537          	lui	a0,0x10
    4b6c:	80050513          	addi	a0,a0,-2048 # f800 <__global_pointer$+0x7718>
    4b70:	e85fe0ef          	jal	39f4 <add565>
    4b74:	00050493          	mv	s1,a0
               (unsigned)add565(0x0000u, 0x1234u, 255u));
    4b78:	0ff00613          	li	a2,255
    4b7c:	000015b7          	lui	a1,0x1
    4b80:	23458593          	addi	a1,a1,564 # 1234 <main+0x130>
    4b84:	00000513          	li	a0,0
    4b88:	e6dfe0ef          	jal	39f4 <add565>
    4b8c:	00050693          	mv	a3,a0
    bsp_printf("selfcheck mix: blend=%x (exp 780F) add=%x (exp F81F) addblack=%x (exp 1234)\r\n",
    4b90:	00048613          	mv	a2,s1
    4b94:	00040593          	mv	a1,s0
    4b98:	00006537          	lui	a0,0x6
    4b9c:	75c50513          	addi	a0,a0,1884 # 675c <_data+0x264>
    4ba0:	ba9ff0ef          	jal	4748 <bsp_printf>
        int id, bad = 0;
    4ba4:	00000913          	li	s2,0
        for (id = 0; id < S_N; id++) {
    4ba8:	00000413          	li	s0,0
    4bac:	0080006f          	j	4bb4 <boot_selfcheck+0x198>
    4bb0:	00140413          	addi	s0,s0,1
    4bb4:	00700793          	li	a5,7
    4bb8:	0487ce63          	blt	a5,s0,4c14 <boot_selfcheck+0x1f8>
            int w = (int)g_spr_sz[id];
    4bbc:	84018793          	addi	a5,gp,-1984 # 7928 <g_spr_sz>
    4bc0:	008787b3          	add	a5,a5,s0
    4bc4:	0007c483          	lbu	s1,0(a5)
            if (spr_pixel(id, 0, 0) != TRANS_KEY) bad++;                 /* 左上角（圆/三角外） */
    4bc8:	00000613          	li	a2,0
    4bcc:	00000593          	li	a1,0
    4bd0:	00040513          	mv	a0,s0
    4bd4:	9fcfd0ef          	jal	1dd0 <spr_pixel>
    4bd8:	00050463          	beqz	a0,4be0 <boot_selfcheck+0x1c4>
    4bdc:	00190913          	addi	s2,s2,1
            if (spr_pixel(id, w - 1, 0) != TRANS_KEY) bad++;             /* 右上角 */
    4be0:	00000613          	li	a2,0
    4be4:	fff48593          	addi	a1,s1,-1
    4be8:	00040513          	mv	a0,s0
    4bec:	9e4fd0ef          	jal	1dd0 <spr_pixel>
    4bf0:	00050463          	beqz	a0,4bf8 <boot_selfcheck+0x1dc>
    4bf4:	00190913          	addi	s2,s2,1
            if (spr_pixel(id, w / 2, w / 2) == TRANS_KEY) bad++;         /* 中心必须实心 */
    4bf8:	0014d593          	srli	a1,s1,0x1
    4bfc:	00058613          	mv	a2,a1
    4c00:	00040513          	mv	a0,s0
    4c04:	9ccfd0ef          	jal	1dd0 <spr_pixel>
    4c08:	fa0514e3          	bnez	a0,4bb0 <boot_selfcheck+0x194>
    4c0c:	00190913          	addi	s2,s2,1
    4c10:	fa1ff06f          	j	4bb0 <boot_selfcheck+0x194>
        bsp_printf("selfcheck atlas: corner_err=%d bytes=%d\r\n", bad, (int)ATLAS_BYTES);
    4c14:	00002637          	lui	a2,0x2
    4c18:	c0060613          	addi	a2,a2,-1024 # 1c00 <spr_player+0x44>
    4c1c:	00090593          	mv	a1,s2
    4c20:	00006537          	lui	a0,0x6
    4c24:	7ac50513          	addi	a0,a0,1964 # 67ac <_data+0x2b4>
    4c28:	b21ff0ef          	jal	4748 <bsp_printf>
        fmt_stat(worst, 999u, 999u, N_MAX, 9999, SCORE_CAP, 99, 9, "ALPHA", 1, 1);
    4c2c:	00100793          	li	a5,1
    4c30:	00f12423          	sw	a5,8(sp)
    4c34:	00f12223          	sw	a5,4(sp)
    4c38:	000067b7          	lui	a5,0x6
    4c3c:	7d878793          	addi	a5,a5,2008 # 67d8 <_data+0x2e0>
    4c40:	00f12023          	sw	a5,0(sp)
    4c44:	00900893          	li	a7,9
    4c48:	06300813          	li	a6,99
    4c4c:	000f47b7          	lui	a5,0xf4
    4c50:	23f78793          	addi	a5,a5,575 # f423f <__freertos_irq_stack_top+0xdb03f>
    4c54:	00002737          	lui	a4,0x2
    4c58:	70f70713          	addi	a4,a4,1807 # 270f <uart_poll_char+0x23>
    4c5c:	000016b7          	lui	a3,0x1
    4c60:	96068693          	addi	a3,a3,-1696 # 960 <CUSTOM2+0x905>
    4c64:	3e700613          	li	a2,999
    4c68:	3e700593          	li	a1,999
    4c6c:	01c10513          	addi	a0,sp,28
    4c70:	a74ff0ef          	jal	3ee4 <fmt_stat>
        int i, miss = 0;
    4c74:	00000493          	li	s1,0
        for (i = 0; worst[i]; i++) if (!glyph_found(worst[i])) miss++;
    4c78:	00000413          	li	s0,0
    4c7c:	0080006f          	j	4c84 <boot_selfcheck+0x268>
    4c80:	00140413          	addi	s0,s0,1
    4c84:	06040793          	addi	a5,s0,96
    4c88:	002787b3          	add	a5,a5,sp
    4c8c:	fbc7c503          	lbu	a0,-68(a5)
    4c90:	00050a63          	beqz	a0,4ca4 <boot_selfcheck+0x288>
    4c94:	9dcfd0ef          	jal	1e70 <glyph_found>
    4c98:	fe0514e3          	bnez	a0,4c80 <boot_selfcheck+0x264>
    4c9c:	00148493          	addi	s1,s1,1
    4ca0:	fe1ff06f          	j	4c80 <boot_selfcheck+0x264>
        for (i = 0; path_label()[i]; i++) if (!glyph_found(path_label()[i])) miss++;
    4ca4:	00000413          	li	s0,0
    4ca8:	0080006f          	j	4cb0 <boot_selfcheck+0x294>
    4cac:	00140413          	addi	s0,s0,1
    4cb0:	d60ff0ef          	jal	4210 <path_label>
    4cb4:	00850533          	add	a0,a0,s0
    4cb8:	00054503          	lbu	a0,0(a0)
    4cbc:	00050a63          	beqz	a0,4cd0 <boot_selfcheck+0x2b4>
    4cc0:	9b0fd0ef          	jal	1e70 <glyph_found>
    4cc4:	fe0514e3          	bnez	a0,4cac <boot_selfcheck+0x290>
    4cc8:	00148493          	addi	s1,s1,1
    4ccc:	fe1ff06f          	j	4cac <boot_selfcheck+0x290>
        bsp_printf("selfcheck osd: len=%d px=%d limit=%d gap=%d missing_glyph=%d\r\n",
    4cd0:	01c10513          	addi	a0,sp,28
    4cd4:	9f0ff0ef          	jal	3ec4 <slen>
    4cd8:	00050593          	mv	a1,a0
                   (FB_WIDTH - OSD_RIGHT_PX) - slen(worst) * OSD_GLYPH_W, miss);
    4cdc:	07000713          	li	a4,112
    4ce0:	40a70733          	sub	a4,a4,a0
        bsp_printf("selfcheck osd: len=%d px=%d limit=%d gap=%d missing_glyph=%d\r\n",
    4ce4:	00048793          	mv	a5,s1
    4ce8:	00371713          	slli	a4,a4,0x3
    4cec:	20000693          	li	a3,512
    4cf0:	00351613          	slli	a2,a0,0x3
    4cf4:	00006537          	lui	a0,0x6
    4cf8:	7e050513          	addi	a0,a0,2016 # 67e0 <_data+0x2e8>
    4cfc:	a4dff0ef          	jal	4748 <bsp_printf>
        int i, miss = 0;
    4d00:	00000913          	li	s2,0
        for (i = 0; i < BULM_N; i++)
    4d04:	00000493          	li	s1,0
    4d08:	03c0006f          	j	4d44 <boot_selfcheck+0x328>
            { int k; for (k = 0; g_bulm_name[i][k]; k++) if (!glyph_found(g_bulm_name[i][k])) miss++; }
    4d0c:	00140413          	addi	s0,s0,1
    4d10:	000077b7          	lui	a5,0x7
    4d14:	00249713          	slli	a4,s1,0x2
    4d18:	7c478793          	addi	a5,a5,1988 # 77c4 <g_bulm_name>
    4d1c:	00e787b3          	add	a5,a5,a4
    4d20:	0007a783          	lw	a5,0(a5)
    4d24:	008787b3          	add	a5,a5,s0
    4d28:	0007c503          	lbu	a0,0(a5)
    4d2c:	00050a63          	beqz	a0,4d40 <boot_selfcheck+0x324>
    4d30:	940fd0ef          	jal	1e70 <glyph_found>
    4d34:	fc051ce3          	bnez	a0,4d0c <boot_selfcheck+0x2f0>
    4d38:	00190913          	addi	s2,s2,1
    4d3c:	fd1ff06f          	j	4d0c <boot_selfcheck+0x2f0>
        for (i = 0; i < BULM_N; i++)
    4d40:	00148493          	addi	s1,s1,1
    4d44:	00300793          	li	a5,3
    4d48:	0097c663          	blt	a5,s1,4d54 <boot_selfcheck+0x338>
            { int k; for (k = 0; g_bulm_name[i][k]; k++) if (!glyph_found(g_bulm_name[i][k])) miss++; }
    4d4c:	00000413          	li	s0,0
    4d50:	fc1ff06f          	j	4d10 <boot_selfcheck+0x2f4>
        bsp_printf("selfcheck bulm: cur=%s eff=%s names_glyph_missing=%d (keys f cycle, 5=FILL 6=ALPHA 7=ADD 8=KEY)\r\n",
    4d54:	000077b7          	lui	a5,0x7
    4d58:	8381a703          	lw	a4,-1992(gp) # 7920 <g_bulm>
    4d5c:	00271713          	slli	a4,a4,0x2
    4d60:	7c478793          	addi	a5,a5,1988 # 77c4 <g_bulm_name>
    4d64:	00e787b3          	add	a5,a5,a4
    4d68:	0007a403          	lw	s0,0(a5)
    4d6c:	e09fc0ef          	jal	1b74 <bulm_eff_name>
    4d70:	00050613          	mv	a2,a0
    4d74:	00090693          	mv	a3,s2
    4d78:	00040593          	mv	a1,s0
    4d7c:	00007537          	lui	a0,0x7
    4d80:	82050513          	addi	a0,a0,-2016 # 6820 <_data+0x328>
    4d84:	9c5ff0ef          	jal	4748 <bsp_printf>
               (int)cost_capacity(DRAW_FILL,  SZ_B, 70, 0),
    4d88:	00000693          	li	a3,0
    4d8c:	04600613          	li	a2,70
    4d90:	01000593          	li	a1,16
    4d94:	00100513          	li	a0,1
    4d98:	a6cfe0ef          	jal	3004 <cost_capacity>
    4d9c:	00050413          	mv	s0,a0
               (int)cost_capacity(DRAW_ALPHA, SZ_B, 70, 0),
    4da0:	00000693          	li	a3,0
    4da4:	04600613          	li	a2,70
    4da8:	01000593          	li	a1,16
    4dac:	00400513          	li	a0,4
    4db0:	a54fe0ef          	jal	3004 <cost_capacity>
    4db4:	00050493          	mv	s1,a0
               (int)cost_capacity(DRAW_KEY,   SZ_B, 70, 0));
    4db8:	00000693          	li	a3,0
    4dbc:	04600613          	li	a2,70
    4dc0:	01000593          	li	a1,16
    4dc4:	00200513          	li	a0,2
    4dc8:	a3cfe0ef          	jal	3004 <cost_capacity>
    4dcc:	00050693          	mv	a3,a0
    bsp_printf("cap model 16x16 70pct budget: FILL=%d ALPHA=%d KEY=%d (single-lane board cal)\r\n",
    4dd0:	00048613          	mv	a2,s1
    4dd4:	00040593          	mv	a1,s0
    4dd8:	00007537          	lui	a0,0x7
    4ddc:	88450513          	addi	a0,a0,-1916 # 6884 <_data+0x38c>
    4de0:	969ff0ef          	jal	4748 <bsp_printf>
               (int)cost_capacity(DRAW_FILL,  SZ_B, 70, 1),
    4de4:	00100693          	li	a3,1
    4de8:	04600613          	li	a2,70
    4dec:	01000593          	li	a1,16
    4df0:	00100513          	li	a0,1
    4df4:	a10fe0ef          	jal	3004 <cost_capacity>
    4df8:	00050413          	mv	s0,a0
               (int)cost_capacity(DRAW_ALPHA, SZ_B, 70, 1),
    4dfc:	00100693          	li	a3,1
    4e00:	04600613          	li	a2,70
    4e04:	01000593          	li	a1,16
    4e08:	00400513          	li	a0,4
    4e0c:	9f8fe0ef          	jal	3004 <cost_capacity>
    4e10:	00050493          	mv	s1,a0
               (int)cost_capacity(DRAW_KEY,   SZ_B, 70, 1));
    4e14:	00100693          	li	a3,1
    4e18:	04600613          	li	a2,70
    4e1c:	01000593          	li	a1,16
    4e20:	00200513          	li	a0,2
    4e24:	9e0fe0ef          	jal	3004 <cost_capacity>
    4e28:	00050693          	mv	a3,a0
    bsp_printf("cap model 16x16 70pct budget: ... dual-lane estimate FILL=%d ALPHA=%d KEY=%d\r\n",
    4e2c:	00048613          	mv	a2,s1
    4e30:	00040593          	mv	a1,s0
    4e34:	00007537          	lui	a0,0x7
    4e38:	8d450513          	addi	a0,a0,-1836 # 68d4 <_data+0x3dc>
    4e3c:	90dff0ef          	jal	4748 <bsp_printf>
}
    4e40:	07c12083          	lw	ra,124(sp)
    4e44:	07812403          	lw	s0,120(sp)
    4e48:	07412483          	lw	s1,116(sp)
    4e4c:	07012903          	lw	s2,112(sp)
    4e50:	06c12983          	lw	s3,108(sp)
    4e54:	06812a03          	lw	s4,104(sp)
    4e58:	06412a83          	lw	s5,100(sp)
    4e5c:	06012b03          	lw	s6,96(sp)
    4e60:	08010113          	addi	sp,sp,128
    4e64:	00008067          	ret

00004e68 <serial_apply_key>:
{
    4e68:	ff010113          	addi	sp,sp,-16
    4e6c:	00112623          	sw	ra,12(sp)
    4e70:	00812423          	sw	s0,8(sp)
    4e74:	00912223          	sw	s1,4(sp)
    4e78:	00050413          	mv	s0,a0
    unsigned old = g_keymask;
    4e7c:	8841a483          	lw	s1,-1916(gp) # 796c <g_keymask>
    g_keymask = mask;
    4e80:	88a1a223          	sw	a0,-1916(gp) # 796c <g_keymask>
    g_key_t = tick32();
    4e84:	8acfd0ef          	jal	1f30 <tick32>
    4e88:	86a1ae23          	sw	a0,-1924(gp) # 7964 <g_key_t>
    g_keys_live = 1;
    4e8c:	00100713          	li	a4,1
    4e90:	86e1ac23          	sw	a4,-1928(gp) # 7960 <g_keys_live>
    if ((mask & KEY_PAUSE) && !(old & KEY_PAUSE) && g_state == GS_PLAY) {
    4e94:	08047793          	andi	a5,s0,128
    4e98:	00078c63          	beqz	a5,4eb0 <serial_apply_key+0x48>
    4e9c:	0804f793          	andi	a5,s1,128
    4ea0:	00079863          	bnez	a5,4eb0 <serial_apply_key+0x48>
    4ea4:	8a41a703          	lw	a4,-1884(gp) # 798c <g_state>
    4ea8:	00100793          	li	a5,1
    4eac:	02f70863          	beq	a4,a5,4edc <serial_apply_key+0x74>
    if ((mask & KEY_BOMB) && !(old & KEY_BOMB)) g_bomb_req = 1;   /* 上升沿 */
    4eb0:	04047413          	andi	s0,s0,64
    4eb4:	00040a63          	beqz	s0,4ec8 <serial_apply_key+0x60>
    4eb8:	0404f793          	andi	a5,s1,64
    4ebc:	00079663          	bnez	a5,4ec8 <serial_apply_key+0x60>
    4ec0:	00100713          	li	a4,1
    4ec4:	88e1a023          	sw	a4,-1920(gp) # 7968 <g_bomb_req>
}
    4ec8:	00c12083          	lw	ra,12(sp)
    4ecc:	00812403          	lw	s0,8(sp)
    4ed0:	00412483          	lw	s1,4(sp)
    4ed4:	01010113          	addi	sp,sp,16
    4ed8:	00008067          	ret
        g_pause = !g_pause;
    4edc:	8a01a583          	lw	a1,-1888(gp) # 7988 <g_pause>
    4ee0:	0015b593          	seqz	a1,a1
    4ee4:	8ab1a023          	sw	a1,-1888(gp) # 7988 <g_pause>
        bsp_printf("\r\nEV pause=%d\r\n", g_pause);
    4ee8:	00007537          	lui	a0,0x7
    4eec:	92450513          	addi	a0,a0,-1756 # 6924 <_data+0x42c>
    4ef0:	859ff0ef          	jal	4748 <bsp_printf>
    4ef4:	fbdff06f          	j	4eb0 <serial_apply_key+0x48>

00004ef8 <serial_cmd>:
    switch (c) {
    4ef8:	fd550793          	addi	a5,a0,-43
    4efc:	04700713          	li	a4,71
    4f00:	4ef76663          	bltu	a4,a5,53ec <serial_cmd+0x4f4>
{
    4f04:	fd010113          	addi	sp,sp,-48
    4f08:	02112623          	sw	ra,44(sp)
    switch (c) {
    4f0c:	00279793          	slli	a5,a5,0x2
    4f10:	00007737          	lui	a4,0x7
    4f14:	49870713          	addi	a4,a4,1176 # 7498 <_data+0xfa0>
    4f18:	00e787b3          	add	a5,a5,a4
    4f1c:	0007a783          	lw	a5,0(a5)
    4f20:	00078067          	jr	a5
    case '1': g_ncap = 256;  g_auto = 0; bsp_printf("\r\nEV N=%d (preset low)\r\n", g_ncap); break;
    4f24:	10000713          	li	a4,256
    4f28:	80e1ae23          	sw	a4,-2020(gp) # 7904 <g_ncap>
    4f2c:	8801ae23          	sw	zero,-1892(gp) # 7984 <g_auto>
    4f30:	10000593          	li	a1,256
    4f34:	00007537          	lui	a0,0x7
    4f38:	93450513          	addi	a0,a0,-1740 # 6934 <_data+0x43c>
    4f3c:	80dff0ef          	jal	4748 <bsp_printf>
}
    4f40:	02c12083          	lw	ra,44(sp)
    4f44:	03010113          	addi	sp,sp,48
    4f48:	00008067          	ret
    case '2': g_ncap = 640;  g_auto = 0; bsp_printf("\r\nEV N=%d (preset mid)\r\n", g_ncap); break;
    4f4c:	28000713          	li	a4,640
    4f50:	80e1ae23          	sw	a4,-2020(gp) # 7904 <g_ncap>
    4f54:	8801ae23          	sw	zero,-1892(gp) # 7984 <g_auto>
    4f58:	28000593          	li	a1,640
    4f5c:	00007537          	lui	a0,0x7
    4f60:	95050513          	addi	a0,a0,-1712 # 6950 <_data+0x458>
    4f64:	fe4ff0ef          	jal	4748 <bsp_printf>
    4f68:	fd9ff06f          	j	4f40 <serial_cmd+0x48>
    case '3': g_ncap = 1280; g_auto = 0; bsp_printf("\r\nEV N=%d (preset high)\r\n", g_ncap); break;
    4f6c:	50000713          	li	a4,1280
    4f70:	80e1ae23          	sw	a4,-2020(gp) # 7904 <g_ncap>
    4f74:	8801ae23          	sw	zero,-1892(gp) # 7984 <g_auto>
    4f78:	50000593          	li	a1,1280
    4f7c:	00007537          	lui	a0,0x7
    4f80:	96c50513          	addi	a0,a0,-1684 # 696c <_data+0x474>
    4f84:	fc4ff0ef          	jal	4748 <bsp_printf>
    4f88:	fb9ff06f          	j	4f40 <serial_cmd+0x48>
    case '4': g_ncap = 2400; g_auto = 0; bsp_printf("\r\nEV N=%d (preset max)\r\n", g_ncap); break;
    4f8c:	000015b7          	lui	a1,0x1
    4f90:	96058593          	addi	a1,a1,-1696 # 960 <CUSTOM2+0x905>
    4f94:	80b1ae23          	sw	a1,-2020(gp) # 7904 <g_ncap>
    4f98:	8801ae23          	sw	zero,-1892(gp) # 7984 <g_auto>
    4f9c:	00007537          	lui	a0,0x7
    4fa0:	98850513          	addi	a0,a0,-1656 # 6988 <_data+0x490>
    4fa4:	fa4ff0ef          	jal	4748 <bsp_printf>
    4fa8:	f99ff06f          	j	4f40 <serial_cmd+0x48>
        g_ncap += N_STEP; if (g_ncap > N_MAX) g_ncap = N_MIN; g_auto = 0;
    4fac:	81c1a783          	lw	a5,-2020(gp) # 7904 <g_ncap>
    4fb0:	04078793          	addi	a5,a5,64
    4fb4:	80f1ae23          	sw	a5,-2020(gp) # 7904 <g_ncap>
    4fb8:	00001737          	lui	a4,0x1
    4fbc:	96070713          	addi	a4,a4,-1696 # 960 <CUSTOM2+0x905>
    4fc0:	00f75663          	bge	a4,a5,4fcc <serial_cmd+0xd4>
    4fc4:	04000713          	li	a4,64
    4fc8:	80e1ae23          	sw	a4,-2020(gp) # 7904 <g_ncap>
    4fcc:	8801ae23          	sw	zero,-1892(gp) # 7984 <g_auto>
        bsp_printf("\r\nEV N=%d\r\n", g_ncap); break;
    4fd0:	81c1a583          	lw	a1,-2020(gp) # 7904 <g_ncap>
    4fd4:	00007537          	lui	a0,0x7
    4fd8:	9a450513          	addi	a0,a0,-1628 # 69a4 <_data+0x4ac>
    4fdc:	f6cff0ef          	jal	4748 <bsp_printf>
    4fe0:	f61ff06f          	j	4f40 <serial_cmd+0x48>
        g_ncap -= N_STEP; if (g_ncap < N_MIN) g_ncap = N_MAX; g_auto = 0;
    4fe4:	81c1a783          	lw	a5,-2020(gp) # 7904 <g_ncap>
    4fe8:	fc078793          	addi	a5,a5,-64
    4fec:	80f1ae23          	sw	a5,-2020(gp) # 7904 <g_ncap>
    4ff0:	03f00713          	li	a4,63
    4ff4:	00f74863          	blt	a4,a5,5004 <serial_cmd+0x10c>
    4ff8:	000017b7          	lui	a5,0x1
    4ffc:	96078793          	addi	a5,a5,-1696 # 960 <CUSTOM2+0x905>
    5000:	80f1ae23          	sw	a5,-2020(gp) # 7904 <g_ncap>
    5004:	8801ae23          	sw	zero,-1892(gp) # 7984 <g_auto>
        bsp_printf("\r\nEV N=%d\r\n", g_ncap); break;
    5008:	81c1a583          	lw	a1,-2020(gp) # 7904 <g_ncap>
    500c:	00007537          	lui	a0,0x7
    5010:	9a450513          	addi	a0,a0,-1628 # 69a4 <_data+0x4ac>
    5014:	f34ff0ef          	jal	4748 <bsp_printf>
    5018:	f29ff06f          	j	4f40 <serial_cmd+0x48>
        g_mode = MD_SW; g_sw_fps = 0; g_sw_frames = 0;
    501c:	00100713          	li	a4,1
    5020:	82e1a023          	sw	a4,-2016(gp) # 7908 <g_mode>
    5024:	8601a623          	sw	zero,-1940(gp) # 7954 <g_sw_fps>
    5028:	8601a223          	sw	zero,-1948(gp) # 794c <g_sw_frames>
        g_t_fps = tick32();     /* ★ 1Hz 窗口从头开始：否则切换那一秒会读到一个"半个窗口"的假帧率 */
    502c:	f05fc0ef          	jal	1f30 <tick32>
    5030:	86a1a023          	sw	a0,-1952(gp) # 7948 <g_t_fps>
        bsp_printf("\r\nEV path=SW pure CPU (same scene, honest per-pixel blit)\r\n"); break;
    5034:	00007537          	lui	a0,0x7
    5038:	9b050513          	addi	a0,a0,-1616 # 69b0 <_data+0x4b8>
    503c:	f0cff0ef          	jal	4748 <bsp_printf>
    5040:	f01ff06f          	j	4f40 <serial_cmd+0x48>
        g_mode = MD_HW; g_hw_fps = 0; g_hw_frames = 0;
    5044:	00200713          	li	a4,2
    5048:	82e1a023          	sw	a4,-2016(gp) # 7908 <g_mode>
    504c:	8601a823          	sw	zero,-1936(gp) # 7958 <g_hw_fps>
    5050:	8601a423          	sw	zero,-1944(gp) # 7950 <g_hw_frames>
        g_t_fps = tick32();
    5054:	eddfc0ef          	jal	1f30 <tick32>
    5058:	86a1a023          	sw	a0,-1952(gp) # 7948 <g_t_fps>
        bsp_printf("\r\nEV path=HW accel\r\n"); break;
    505c:	00007537          	lui	a0,0x7
    5060:	9ec50513          	addi	a0,a0,-1556 # 69ec <_data+0x4f4>
    5064:	ee4ff0ef          	jal	4748 <bsp_printf>
    5068:	ed9ff06f          	j	4f40 <serial_cmd+0x48>
        g_auto = !g_auto;
    506c:	89c1a583          	lw	a1,-1892(gp) # 7984 <g_auto>
    5070:	0015b593          	seqz	a1,a1
    5074:	88b1ae23          	sw	a1,-1892(gp) # 7984 <g_auto>
        bsp_printf("\r\nEV auto=%d (ramp N while fps>=58; LIMIT line on stop)\r\n", g_auto);
    5078:	00007537          	lui	a0,0x7
    507c:	a0450513          	addi	a0,a0,-1532 # 6a04 <_data+0x50c>
    5080:	ec8ff0ef          	jal	4748 <bsp_printf>
        break;
    5084:	ebdff06f          	j	4f40 <serial_cmd+0x48>
        g_star_n = g_star_n ? 0 : STAR_MAX;
    5088:	8241a783          	lw	a5,-2012(gp) # 790c <g_star_n>
    508c:	00078e63          	beqz	a5,50a8 <serial_cmd+0x1b0>
    5090:	00000593          	li	a1,0
    5094:	82b1a223          	sw	a1,-2012(gp) # 790c <g_star_n>
        bsp_printf("\r\nEV stars=%d\r\n", g_star_n); break;
    5098:	00007537          	lui	a0,0x7
    509c:	a4050513          	addi	a0,a0,-1472 # 6a40 <_data+0x548>
    50a0:	ea8ff0ef          	jal	4748 <bsp_printf>
    50a4:	e9dff06f          	j	4f40 <serial_cmd+0x48>
        g_star_n = g_star_n ? 0 : STAR_MAX;
    50a8:	04000593          	li	a1,64
    50ac:	fe9ff06f          	j	5094 <serial_cmd+0x19c>
    50b0:	02812423          	sw	s0,40(sp)
    50b4:	02912223          	sw	s1,36(sp)
                 : (c - '5');
    50b8:	06600793          	li	a5,102
    50bc:	00f50a63          	beq	a0,a5,50d0 <serial_cmd+0x1d8>
        int next = (c == 'f' || c == 'F') ? ((g_bulm + 1) % BULM_N)
    50c0:	04600793          	li	a5,70
    50c4:	00f50663          	beq	a0,a5,50d0 <serial_cmd+0x1d8>
                 : (c - '5');
    50c8:	fcb50513          	addi	a0,a0,-53
    50cc:	0200006f          	j	50ec <serial_cmd+0x1f4>
        int next = (c == 'f' || c == 'F') ? ((g_bulm + 1) % BULM_N)
    50d0:	8381a783          	lw	a5,-1992(gp) # 7920 <g_bulm>
    50d4:	00178793          	addi	a5,a5,1
                 : (c - '5');
    50d8:	41f7d713          	srai	a4,a5,0x1f
    50dc:	01e75713          	srli	a4,a4,0x1e
    50e0:	00e78533          	add	a0,a5,a4
    50e4:	00357513          	andi	a0,a0,3
    50e8:	40e50533          	sub	a0,a0,a4
        g_bulm = next;
    50ec:	82a1ac23          	sw	a0,-1992(gp) # 7920 <g_bulm>
        bsp_printf("\r\nEV bulm=%s (requested; effective=%s)\r\n",
    50f0:	000077b7          	lui	a5,0x7
    50f4:	00251513          	slli	a0,a0,0x2
    50f8:	7c478793          	addi	a5,a5,1988 # 77c4 <g_bulm_name>
    50fc:	00a787b3          	add	a5,a5,a0
    5100:	0007a483          	lw	s1,0(a5)
    5104:	a71fc0ef          	jal	1b74 <bulm_eff_name>
    5108:	00050613          	mv	a2,a0
    510c:	00048593          	mv	a1,s1
    5110:	00007537          	lui	a0,0x7
    5114:	a5050513          	addi	a0,a0,-1456 # 6a50 <_data+0x558>
    5118:	e30ff0ef          	jal	4748 <bsp_printf>
        if (g_bulm == BULM_ALPHA)
    511c:	8381a703          	lw	a4,-1992(gp) # 7920 <g_bulm>
    5120:	00100793          	li	a5,1
    5124:	02f70263          	beq	a4,a5,5148 <serial_cmd+0x250>
        if (g_bulm == BULM_ADD && !g_glow)
    5128:	8381a703          	lw	a4,-1992(gp) # 7920 <g_bulm>
    512c:	00200793          	li	a5,2
    5130:	02f70663          	beq	a4,a5,515c <serial_cmd+0x264>
        if (g_bulm == BULM_FILL)
    5134:	8381a783          	lw	a5,-1992(gp) # 7920 <g_bulm>
    5138:	02078e63          	beqz	a5,5174 <serial_cmd+0x27c>
    513c:	02812403          	lw	s0,40(sp)
    5140:	02412483          	lw	s1,36(sp)
    5144:	dfdff06f          	j	4f40 <serial_cmd+0x48>
            bsp_printf("     ALPHA: rect sprite + alpha %d -> corners darken the bg (that is why KEY exists)\r\n",
    5148:	0a000593          	li	a1,160
    514c:	00007537          	lui	a0,0x7
    5150:	a7c50513          	addi	a0,a0,-1412 # 6a7c <_data+0x584>
    5154:	df4ff0ef          	jal	4748 <bsp_printf>
    5158:	fd1ff06f          	j	5128 <serial_cmd+0x230>
        if (g_bulm == BULM_ADD && !g_glow)
    515c:	8f81a783          	lw	a5,-1800(gp) # 79e0 <g_glow>
    5160:	fc079ae3          	bnez	a5,5134 <serial_cmd+0x23c>
            bsp_printf("     WARN: attr side-port absent -> ADD falls back to Color Key\r\n");
    5164:	00007537          	lui	a0,0x7
    5168:	ad450513          	addi	a0,a0,-1324 # 6ad4 <_data+0x5dc>
    516c:	ddcff0ef          	jal	4748 <bsp_printf>
    5170:	fc5ff06f          	j	5134 <serial_cmd+0x23c>
            bsp_printf("     FILL: solid %dx%d squares, no src/key/alpha -> cheapest op\r\n",
    5174:	01000613          	li	a2,16
    5178:	01000593          	li	a1,16
    517c:	00007537          	lui	a0,0x7
    5180:	b1850513          	addi	a0,a0,-1256 # 6b18 <_data+0x620>
    5184:	dc4ff0ef          	jal	4748 <bsp_printf>
    5188:	02812403          	lw	s0,40(sp)
    518c:	02412483          	lw	s1,36(sp)
    5190:	db1ff06f          	j	4f40 <serial_cmd+0x48>
        if (g_state == GS_PLAY) { g_pause = !g_pause; bsp_printf("\r\nEV pause=%d\r\n", g_pause); }
    5194:	8a41a703          	lw	a4,-1884(gp) # 798c <g_state>
    5198:	00100793          	li	a5,1
    519c:	daf712e3          	bne	a4,a5,4f40 <serial_cmd+0x48>
    51a0:	8a01a583          	lw	a1,-1888(gp) # 7988 <g_pause>
    51a4:	0015b593          	seqz	a1,a1
    51a8:	8ab1a023          	sw	a1,-1888(gp) # 7988 <g_pause>
    51ac:	00007537          	lui	a0,0x7
    51b0:	92450513          	addi	a0,a0,-1756 # 6924 <_data+0x42c>
    51b4:	d94ff0ef          	jal	4748 <bsp_printf>
    51b8:	d89ff06f          	j	4f40 <serial_cmd+0x48>
        g_seed += 0x9E3779B9u; game_reset();
    51bc:	8281a783          	lw	a5,-2008(gp) # 7910 <g_seed>
    51c0:	9e378737          	lui	a4,0x9e378
    51c4:	9b970713          	addi	a4,a4,-1607 # 9e3779b9 <__freertos_irq_stack_top+0x9e35e7b9>
    51c8:	00e787b3          	add	a5,a5,a4
    51cc:	82f1a423          	sw	a5,-2008(gp) # 7910 <g_seed>
    51d0:	bf4ff0ef          	jal	45c4 <game_reset>
        bsp_printf("\r\nEV reset\r\n"); break;
    51d4:	00007537          	lui	a0,0x7
    51d8:	b5c50513          	addi	a0,a0,-1188 # 6b5c <_data+0x664>
    51dc:	d6cff0ef          	jal	4748 <bsp_printf>
    51e0:	d61ff06f          	j	4f40 <serial_cmd+0x48>
    51e4:	02812423          	sw	s0,40(sp)
    51e8:	02912223          	sw	s1,36(sp)
    51ec:	03212023          	sw	s2,32(sp)
    51f0:	01312e23          	sw	s3,28(sp)
    51f4:	01412c23          	sw	s4,24(sp)
    51f8:	01512a23          	sw	s5,20(sp)
    51fc:	01612823          	sw	s6,16(sp)
        bsp_printf("\r\nEV diag: N=%d ON=%d HW=%d SW=%d SC=%d LV=%d HP=%d BOMB=%d\r\n",
    5200:	8141a783          	lw	a5,-2028(gp) # 78fc <g_bomb>
    5204:	00f12023          	sw	a5,0(sp)
    5208:	8181a883          	lw	a7,-2024(gp) # 7900 <g_hp>
    520c:	8101a803          	lw	a6,-2032(gp) # 78f8 <g_level>
    5210:	8901a783          	lw	a5,-1904(gp) # 7978 <g_score>
    5214:	86c1a703          	lw	a4,-1940(gp) # 7954 <g_sw_fps>
    5218:	8701a683          	lw	a3,-1936(gp) # 7958 <g_hw_fps>
    521c:	85c1a603          	lw	a2,-1956(gp) # 7944 <g_on_screen>
    5220:	81c1a583          	lw	a1,-2020(gp) # 7904 <g_ncap>
    5224:	00007537          	lui	a0,0x7
    5228:	b6c50513          	addi	a0,a0,-1172 # 6b6c <_data+0x674>
    522c:	d1cff0ef          	jal	4748 <bsp_printf>
                   (unsigned)blt_stat(), (unsigned)blt_cnt(), (unsigned)blt_rd(BLT_SCAN_DBG),
    5230:	a20fd0ef          	jal	2450 <blt_stat>
    5234:	00050413          	mv	s0,a0
    5238:	9fcfd0ef          	jal	2434 <blt_cnt>
    523c:	00050493          	mv	s1,a0
    5240:	02000513          	li	a0,32
    5244:	d19fc0ef          	jal	1f5c <blt_rd>
    5248:	00050913          	mv	s2,a0
                   (unsigned)blt_rd(BLT_FB_STAT), (unsigned)blt_rd(BLT_DRAW_SEL),
    524c:	02800513          	li	a0,40
    5250:	d0dfc0ef          	jal	1f5c <blt_rd>
    5254:	00050993          	mv	s3,a0
    5258:	04400513          	li	a0,68
    525c:	d01fc0ef          	jal	1f5c <blt_rd>
    5260:	00050a13          	mv	s4,a0
                   (unsigned)blt_rd(BLT_CLR_STAT), (unsigned)blt_rd(BLT_CLIP_CTRL),
    5264:	04000513          	li	a0,64
    5268:	cf5fc0ef          	jal	1f5c <blt_rd>
    526c:	00050a93          	mv	s5,a0
    5270:	0a000513          	li	a0,160
    5274:	ce9fc0ef          	jal	1f5c <blt_rd>
    5278:	00050b13          	mv	s6,a0
                   (unsigned)blt_rd(BLT_LUT_CTRL));
    527c:	0ac00513          	li	a0,172
    5280:	cddfc0ef          	jal	1f5c <blt_rd>
        bsp_printf("     STATUS=%x COUNT=%d SCAN=%x FBSTAT=%x DRAW=%x CLR=%x clip=%x lut=%x\r\n",
    5284:	00a12023          	sw	a0,0(sp)
    5288:	000b0893          	mv	a7,s6
    528c:	000a8813          	mv	a6,s5
    5290:	000a0793          	mv	a5,s4
    5294:	00098713          	mv	a4,s3
    5298:	00090693          	mv	a3,s2
    529c:	00048613          	mv	a2,s1
    52a0:	00040593          	mv	a1,s0
    52a4:	00007537          	lui	a0,0x7
    52a8:	bac50513          	addi	a0,a0,-1108 # 6bac <_data+0x6b4>
    52ac:	c9cff0ef          	jal	4748 <bsp_printf>
        bsp_printf("     flipto=%d clr fb=%d to=%d err=%d stto=%d attr=%d glow=%d clipdrop=%d\r\n",
    52b0:	8a81a783          	lw	a5,-1880(gp) # 7990 <g_clip_drop>
    52b4:	00f12023          	sw	a5,0(sp)
    52b8:	8f81a883          	lw	a7,-1800(gp) # 79e0 <g_glow>
    52bc:	8ec1a803          	lw	a6,-1812(gp) # 79d4 <g_attr_on>
    52c0:	8c81a783          	lw	a5,-1848(gp) # 79b0 <g_stto>
    52c4:	8cc1a703          	lw	a4,-1844(gp) # 79b4 <g_clr_err>
    52c8:	8d01a683          	lw	a3,-1840(gp) # 79b8 <g_clr_to>
    52cc:	8d41a603          	lw	a2,-1836(gp) # 79bc <g_clr_fb>
    52d0:	8e01a583          	lw	a1,-1824(gp) # 79c8 <g_flip_to>
    52d4:	00007537          	lui	a0,0x7
    52d8:	bf850513          	addi	a0,a0,-1032 # 6bf8 <_data+0x700>
    52dc:	c6cff0ef          	jal	4748 <bsp_printf>
        bsp_printf("     bulm=%s (req) %s (eff) alpha=%d | 16x16 70pct cap: FILL=%d ALPHA=%d KEY=%d\r\n",
    52e0:	000077b7          	lui	a5,0x7
    52e4:	8381a703          	lw	a4,-1992(gp) # 7920 <g_bulm>
    52e8:	00271713          	slli	a4,a4,0x2
    52ec:	7c478793          	addi	a5,a5,1988 # 77c4 <g_bulm_name>
    52f0:	00e787b3          	add	a5,a5,a4
    52f4:	0007a983          	lw	s3,0(a5)
    52f8:	87dfc0ef          	jal	1b74 <bulm_eff_name>
    52fc:	00050413          	mv	s0,a0
                   (int)cost_capacity(DRAW_FILL,  SZ_B, 70, 0),
    5300:	00000693          	li	a3,0
    5304:	04600613          	li	a2,70
    5308:	01000593          	li	a1,16
    530c:	00100513          	li	a0,1
    5310:	cf5fd0ef          	jal	3004 <cost_capacity>
    5314:	00050493          	mv	s1,a0
                   (int)cost_capacity(DRAW_ALPHA, SZ_B, 70, 0),
    5318:	00000693          	li	a3,0
    531c:	04600613          	li	a2,70
    5320:	01000593          	li	a1,16
    5324:	00400513          	li	a0,4
    5328:	cddfd0ef          	jal	3004 <cost_capacity>
    532c:	00050913          	mv	s2,a0
                   (int)cost_capacity(DRAW_KEY,   SZ_B, 70, 0));
    5330:	00000693          	li	a3,0
    5334:	04600613          	li	a2,70
    5338:	01000593          	li	a1,16
    533c:	00200513          	li	a0,2
    5340:	cc5fd0ef          	jal	3004 <cost_capacity>
        bsp_printf("     bulm=%s (req) %s (eff) alpha=%d | 16x16 70pct cap: FILL=%d ALPHA=%d KEY=%d\r\n",
    5344:	00050813          	mv	a6,a0
    5348:	00090793          	mv	a5,s2
    534c:	00048713          	mv	a4,s1
    5350:	0a000693          	li	a3,160
    5354:	00040613          	mv	a2,s0
    5358:	00098593          	mv	a1,s3
    535c:	00007537          	lui	a0,0x7
    5360:	c4450513          	addi	a0,a0,-956 # 6c44 <_data+0x74c>
    5364:	be4ff0ef          	jal	4748 <bsp_printf>
                   (int)cost_capacity(DRAW_GLOW, SZ_B, 70, 0),
    5368:	00000693          	li	a3,0
    536c:	04600613          	li	a2,70
    5370:	01000593          	li	a1,16
    5374:	00300513          	li	a0,3
    5378:	c8dfd0ef          	jal	3004 <cost_capacity>
    537c:	00050413          	mv	s0,a0
                   (int)cost_capacity(DRAW_GLOW, SZ_B, 70, 1));
    5380:	00100693          	li	a3,1
    5384:	04600613          	li	a2,70
    5388:	01000593          	li	a1,16
    538c:	00300513          	li	a0,3
    5390:	c75fd0ef          	jal	3004 <cost_capacity>
    5394:	00050613          	mv	a2,a0
        bsp_printf("     cap16 glow 70pct budget: single-lane %d, dual-lane %d sprites/frame\r\n",
    5398:	00040593          	mv	a1,s0
    539c:	00007537          	lui	a0,0x7
    53a0:	c9850513          	addi	a0,a0,-872 # 6c98 <_data+0x7a0>
    53a4:	ba4ff0ef          	jal	4748 <bsp_printf>
        break;
    53a8:	02812403          	lw	s0,40(sp)
    53ac:	02412483          	lw	s1,36(sp)
    53b0:	02012903          	lw	s2,32(sp)
    53b4:	01c12983          	lw	s3,28(sp)
    53b8:	01812a03          	lw	s4,24(sp)
    53bc:	01412a83          	lw	s5,20(sp)
    53c0:	01012b03          	lw	s6,16(sp)
    53c4:	b7dff06f          	j	4f40 <serial_cmd+0x48>
        bsp_printf("\r\ncmd: 1/2/3/4=load presets N=256/640/1280/2400\r\n"
    53c8:	00001737          	lui	a4,0x1
    53cc:	96070713          	addi	a4,a4,-1696 # 960 <CUSTOM2+0x905>
    53d0:	04000693          	li	a3,64
    53d4:	04000613          	li	a2,64
    53d8:	04000593          	li	a1,64
    53dc:	00007537          	lui	a0,0x7
    53e0:	ce450513          	addi	a0,a0,-796 # 6ce4 <_data+0x7ec>
    53e4:	b64ff0ef          	jal	4748 <bsp_printf>
}
    53e8:	b59ff06f          	j	4f40 <serial_cmd+0x48>
    53ec:	00008067          	ret

000053f0 <serial_drain>:
{
    53f0:	fe010113          	addi	sp,sp,-32
    53f4:	00112e23          	sw	ra,28(sp)
    53f8:	00812c23          	sw	s0,24(sp)
    53fc:	00912a23          	sw	s1,20(sp)
    int guard = 64;
    5400:	04000793          	li	a5,64
    while (guard-- > 0) {
    5404:	0100006f          	j	5414 <serial_drain+0x24>
        if (kp == KP_OK) { serial_apply_key(mask); continue; }
    5408:	00c12503          	lw	a0,12(sp)
    540c:	a5dff0ef          	jal	4e68 <serial_apply_key>
{
    5410:	00048793          	mv	a5,s1
    while (guard-- > 0) {
    5414:	fff78493          	addi	s1,a5,-1
    5418:	08f05a63          	blez	a5,54ac <serial_drain+0xbc>
        int c = uart_poll_char();
    541c:	ad0fd0ef          	jal	26ec <uart_poll_char>
    5420:	00050413          	mv	s0,a0
        int kp, nl, ncmd = 0;
    5424:	00012423          	sw	zero,8(sp)
        unsigned mask = 0u;
    5428:	00012623          	sw	zero,12(sp)
        if (!c) break;
    542c:	08050063          	beqz	a0,54ac <serial_drain+0xbc>
        kp = kp_feed(c, &mask);
    5430:	00c10593          	addi	a1,sp,12
    5434:	b30fd0ef          	jal	2764 <kp_feed>
        if (kp == KP_OK) { serial_apply_key(mask); continue; }
    5438:	00200793          	li	a5,2
    543c:	fcf506e3          	beq	a0,a5,5408 <serial_drain+0x18>
        if (kp != KP_NONE) continue;                  /* KP_MORE / KP_ERR：本函数已消费 */
    5440:	fc0518e3          	bnez	a0,5410 <serial_drain+0x20>
        nl = nline_feed(c, &ncmd, N_MIN, N_MAX);
    5444:	000016b7          	lui	a3,0x1
    5448:	96068693          	addi	a3,a3,-1696 # 960 <CUSTOM2+0x905>
    544c:	04000613          	li	a2,64
    5450:	00810593          	addi	a1,sp,8
    5454:	00040513          	mv	a0,s0
    5458:	bc4fd0ef          	jal	281c <nline_feed>
        if (nl == NL_OK) { g_ncap = ncmd; g_auto = 0; bsp_printf("\r\nEV N=%d\r\n", g_ncap); continue; }
    545c:	00200793          	li	a5,2
    5460:	02f50063          	beq	a0,a5,5480 <serial_drain+0x90>
        if (nl == NL_ERR) { bsp_printf("\r\nEV N=ERR\r\n"); continue; }
    5464:	fff00793          	li	a5,-1
    5468:	02f50a63          	beq	a0,a5,549c <serial_drain+0xac>
        if (nl == NL_MORE) continue;
    546c:	00100793          	li	a5,1
    5470:	faf500e3          	beq	a0,a5,5410 <serial_drain+0x20>
        serial_cmd(c);                                /* ★ 单字符命令的唯一实现 */
    5474:	00040513          	mv	a0,s0
    5478:	a81ff0ef          	jal	4ef8 <serial_cmd>
    547c:	f95ff06f          	j	5410 <serial_drain+0x20>
        if (nl == NL_OK) { g_ncap = ncmd; g_auto = 0; bsp_printf("\r\nEV N=%d\r\n", g_ncap); continue; }
    5480:	00812583          	lw	a1,8(sp)
    5484:	80b1ae23          	sw	a1,-2020(gp) # 7904 <g_ncap>
    5488:	8801ae23          	sw	zero,-1892(gp) # 7984 <g_auto>
    548c:	00007537          	lui	a0,0x7
    5490:	9a450513          	addi	a0,a0,-1628 # 69a4 <_data+0x4ac>
    5494:	ab4ff0ef          	jal	4748 <bsp_printf>
    5498:	f79ff06f          	j	5410 <serial_drain+0x20>
        if (nl == NL_ERR) { bsp_printf("\r\nEV N=ERR\r\n"); continue; }
    549c:	00007537          	lui	a0,0x7
    54a0:	f2c50513          	addi	a0,a0,-212 # 6f2c <_data+0xa34>
    54a4:	aa4ff0ef          	jal	4748 <bsp_printf>
    54a8:	f69ff06f          	j	5410 <serial_drain+0x20>
}
    54ac:	01c12083          	lw	ra,28(sp)
    54b0:	01812403          	lw	s0,24(sp)
    54b4:	01412483          	lw	s1,20(sp)
    54b8:	02010113          	addi	sp,sp,32
    54bc:	00008067          	ret

000054c0 <player_step>:
{
    54c0:	fe010113          	addi	sp,sp,-32
    54c4:	00112e23          	sw	ra,28(sp)
    54c8:	00812c23          	sw	s0,24(sp)
    54cc:	00912a23          	sw	s1,20(sp)
    54d0:	01212823          	sw	s2,16(sp)
    int spd = (g_keymask & KEY_FOCUS) ? PLR_SPD_F : PLR_SPD;   /* Q3/帧 */
    54d4:	8841a783          	lw	a5,-1916(gp) # 796c <g_keymask>
    54d8:	0207f713          	andi	a4,a5,32
    54dc:	06070063          	beqz	a4,553c <player_step+0x7c>
    54e0:	01400713          	li	a4,20
    int nx = (int)g_px, ny = (int)g_py;
    54e4:	89a19403          	lh	s0,-1894(gp) # 7982 <g_px>
    54e8:	89819483          	lh	s1,-1896(gp) # 7980 <g_py>
    if (g_keymask & KEY_LEFT)  nx -= spd;
    54ec:	0047f693          	andi	a3,a5,4
    54f0:	00068463          	beqz	a3,54f8 <player_step+0x38>
    54f4:	40e40433          	sub	s0,s0,a4
    if (g_keymask & KEY_RIGHT) nx += spd;
    54f8:	0087f693          	andi	a3,a5,8
    54fc:	00068463          	beqz	a3,5504 <player_step+0x44>
    5500:	00e40433          	add	s0,s0,a4
    if (g_keymask & KEY_UP)    ny -= spd;
    5504:	0017f693          	andi	a3,a5,1
    5508:	00068463          	beqz	a3,5510 <player_step+0x50>
    550c:	40e484b3          	sub	s1,s1,a4
    if (g_keymask & KEY_DOWN)  ny += spd;
    5510:	0027f693          	andi	a3,a5,2
    5514:	00068463          	beqz	a3,551c <player_step+0x5c>
    5518:	00e484b3          	add	s1,s1,a4
    if (nx < FP(16)) nx = FP(16);
    551c:	07f00713          	li	a4,127
    5520:	02875263          	bge	a4,s0,5544 <player_step+0x84>
    if (nx > FP(FB_WIDTH - 16)) nx = FP(FB_WIDTH - 16);
    5524:	00002737          	lui	a4,0x2
    5528:	d8070713          	addi	a4,a4,-640 # 1d80 <spr_glow+0x70>
    552c:	00875e63          	bge	a4,s0,5548 <player_step+0x88>
    5530:	00002437          	lui	s0,0x2
    5534:	d8040413          	addi	s0,s0,-640 # 1d80 <spr_glow+0x70>
    5538:	0100006f          	j	5548 <player_step+0x88>
    int spd = (g_keymask & KEY_FOCUS) ? PLR_SPD_F : PLR_SPD;   /* Q3/帧 */
    553c:	02800713          	li	a4,40
    5540:	fa5ff06f          	j	54e4 <player_step+0x24>
    if (nx < FP(16)) nx = FP(16);
    5544:	08000413          	li	s0,128
    if (ny < FP(PLAY_Y0 + 16)) ny = FP(PLAY_Y0 + 16);
    5548:	0ff00713          	li	a4,255
    554c:	00975e63          	bge	a4,s1,5568 <player_step+0xa8>
    if (ny > FP(PLAY_Y1 - 16)) ny = FP(PLAY_Y1 - 16);
    5550:	00001737          	lui	a4,0x1
    5554:	06070713          	addi	a4,a4,96 # 1060 <init+0x58>
    5558:	00975a63          	bge	a4,s1,556c <player_step+0xac>
    555c:	000014b7          	lui	s1,0x1
    5560:	06048493          	addi	s1,s1,96 # 1060 <init+0x58>
    5564:	0080006f          	j	556c <player_step+0xac>
    if (ny < FP(PLAY_Y0 + 16)) ny = FP(PLAY_Y0 + 16);
    5568:	10000493          	li	s1,256
    g_px = (int16_t)nx; g_py = (int16_t)ny;
    556c:	88819d23          	sh	s0,-1894(gp) # 7982 <g_px>
    5570:	88919c23          	sh	s1,-1896(gp) # 7980 <g_py>
    if (g_state == GS_PLAY && (g_keymask & KEY_FIRE)) {
    5574:	8a41a903          	lw	s2,-1884(gp) # 798c <g_state>
    5578:	00100713          	li	a4,1
    557c:	02e90863          	beq	s2,a4,55ac <player_step+0xec>
    if (g_bomb_req) {
    5580:	8801a783          	lw	a5,-1920(gp) # 7968 <g_bomb_req>
    5584:	00078863          	beqz	a5,5594 <player_step+0xd4>
        g_bomb_req = 0;
    5588:	8801a023          	sw	zero,-1920(gp) # 7968 <g_bomb_req>
        if (g_state == GS_PLAY && g_bomb > 0) {
    558c:	00100793          	li	a5,1
    5590:	0ef90263          	beq	s2,a5,5674 <player_step+0x1b4>
}
    5594:	01c12083          	lw	ra,28(sp)
    5598:	01812403          	lw	s0,24(sp)
    559c:	01412483          	lw	s1,20(sp)
    55a0:	01012903          	lw	s2,16(sp)
    55a4:	02010113          	addi	sp,sp,32
    55a8:	00008067          	ret
    if (g_state == GS_PLAY && (g_keymask & KEY_FIRE)) {
    55ac:	0107f793          	andi	a5,a5,16
    55b0:	fc0788e3          	beqz	a5,5580 <player_step+0xc0>
        if (--g_shot_t <= 0) {
    55b4:	88c1a783          	lw	a5,-1908(gp) # 7974 <g_shot_t>
    55b8:	fff78793          	addi	a5,a5,-1
    55bc:	88f1a623          	sw	a5,-1908(gp) # 7974 <g_shot_t>
    55c0:	fcf040e3          	bgtz	a5,5580 <player_step+0xc0>
    55c4:	01312623          	sw	s3,12(sp)
            g_shot_t = PLR_SHOT_T;
    55c8:	00070793          	mv	a5,a4
    55cc:	00700713          	li	a4,7
    55d0:	88e1a623          	sw	a4,-1908(gp) # 7974 <g_shot_t>
            for (i = 0; i < 2; i++) {
    55d4:	00000993          	li	s3,0
    55d8:	0700006f          	j	5648 <player_step+0x188>
                    b->x = (int16_t)(g_px + (i ? FP(6) : -FP(6)));
    55dc:	000107b7          	lui	a5,0x10
    55e0:	fd078793          	addi	a5,a5,-48 # ffd0 <__global_pointer$+0x7ee8>
    55e4:	00878633          	add	a2,a5,s0
    55e8:	00011737          	lui	a4,0x11
    55ec:	fe870713          	addi	a4,a4,-24 # 10fe8 <g_bul>
    55f0:	00151693          	slli	a3,a0,0x1
    55f4:	00a687b3          	add	a5,a3,a0
    55f8:	00279793          	slli	a5,a5,0x2
    55fc:	00f707b3          	add	a5,a4,a5
    5600:	00c79023          	sh	a2,0(a5)
                    b->y = (int16_t)(g_py - FP(20));
    5604:	f6048613          	addi	a2,s1,-160
    5608:	00c79123          	sh	a2,2(a5)
                    b->vx = 0; b->vy = (int16_t)(-56);
    560c:	00079223          	sh	zero,4(a5)
    5610:	fc800613          	li	a2,-56
    5614:	00c79323          	sh	a2,6(a5)
                    b->kind = S_SH; b->sz = SZ_B; b->r = 4; b->life = 90;
    5618:	00200613          	li	a2,2
    561c:	00c78423          	sb	a2,8(a5)
    5620:	01000613          	li	a2,16
    5624:	00c784a3          	sb	a2,9(a5)
    5628:	00400613          	li	a2,4
    562c:	00c78523          	sb	a2,10(a5)
    5630:	00a687b3          	add	a5,a3,a0
    5634:	00279793          	slli	a5,a5,0x2
    5638:	00f70733          	add	a4,a4,a5
    563c:	05a00793          	li	a5,90
    5640:	00f705a3          	sb	a5,11(a4)
            for (i = 0; i < 2; i++) {
    5644:	00198993          	addi	s3,s3,1
    5648:	00100793          	li	a5,1
    564c:	0337c063          	blt	a5,s3,566c <player_step+0x1ac>
                int k = bul_alloc(0, PLR_SLOTS);
    5650:	02000593          	li	a1,32
    5654:	00000513          	li	a0,0
    5658:	c08fd0ef          	jal	2a60 <bul_alloc>
                if (k >= 0) {
    565c:	fe0544e3          	bltz	a0,5644 <player_step+0x184>
                    b->x = (int16_t)(g_px + (i ? FP(6) : -FP(6)));
    5660:	f6098ee3          	beqz	s3,55dc <player_step+0x11c>
    5664:	03000793          	li	a5,48
    5668:	f7dff06f          	j	55e4 <player_step+0x124>
    566c:	00c12983          	lw	s3,12(sp)
    5670:	f11ff06f          	j	5580 <player_step+0xc0>
        if (g_state == GS_PLAY && g_bomb > 0) {
    5674:	8141a783          	lw	a5,-2028(gp) # 78fc <g_bomb>
    5678:	f0f05ee3          	blez	a5,5594 <player_step+0xd4>
        int k = 0;
    567c:	00000693          	li	a3,0
            for (i = PLR_SLOTS; i < BUL_TOTAL; i++)
    5680:	02000413          	li	s0,32
    5684:	04c0006f          	j	56d0 <player_step+0x210>
                    if ((k++ & 3) == 0) spark_add(g_bul[i].x, g_bul[i].y);
    5688:	000117b7          	lui	a5,0x11
    568c:	00141713          	slli	a4,s0,0x1
    5690:	00870733          	add	a4,a4,s0
    5694:	00271713          	slli	a4,a4,0x2
    5698:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    569c:	00e787b3          	add	a5,a5,a4
    56a0:	00279583          	lh	a1,2(a5)
    56a4:	00079503          	lh	a0,0(a5)
    56a8:	f5dfd0ef          	jal	3604 <spark_add>
                    g_bul[i].life = 0;
    56ac:	000117b7          	lui	a5,0x11
    56b0:	00141713          	slli	a4,s0,0x1
    56b4:	00870733          	add	a4,a4,s0
    56b8:	00271713          	slli	a4,a4,0x2
    56bc:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    56c0:	00e787b3          	add	a5,a5,a4
    56c4:	000785a3          	sb	zero,11(a5)
                    if ((k++ & 3) == 0) spark_add(g_bul[i].x, g_bul[i].y);
    56c8:	00048693          	mv	a3,s1
            for (i = PLR_SLOTS; i < BUL_TOTAL; i++)
    56cc:	00140413          	addi	s0,s0,1
    56d0:	000017b7          	lui	a5,0x1
    56d4:	97f78793          	addi	a5,a5,-1665 # 97f <CUSTOM2+0x924>
    56d8:	0287ca63          	blt	a5,s0,570c <player_step+0x24c>
                if (g_bul[i].life) {
    56dc:	000117b7          	lui	a5,0x11
    56e0:	00141713          	slli	a4,s0,0x1
    56e4:	00870733          	add	a4,a4,s0
    56e8:	00271713          	slli	a4,a4,0x2
    56ec:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    56f0:	00e787b3          	add	a5,a5,a4
    56f4:	00b7c783          	lbu	a5,11(a5)
    56f8:	fc078ae3          	beqz	a5,56cc <player_step+0x20c>
                    if ((k++ & 3) == 0) spark_add(g_bul[i].x, g_bul[i].y);
    56fc:	00168493          	addi	s1,a3,1
    5700:	0036f693          	andi	a3,a3,3
    5704:	fa0694e3          	bnez	a3,56ac <player_step+0x1ec>
    5708:	f81ff06f          	j	5688 <player_step+0x1c8>
            for (i = 0; i < ENEMY_MAX; i++) if (g_en[i].t) g_en[i].hp -= 3;
    570c:	00000713          	li	a4,0
    5710:	0080006f          	j	5718 <player_step+0x258>
    5714:	00170713          	addi	a4,a4,1
    5718:	01700793          	li	a5,23
    571c:	02e7cc63          	blt	a5,a4,5754 <player_step+0x294>
    5720:	000117b7          	lui	a5,0x11
    5724:	00471693          	slli	a3,a4,0x4
    5728:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    572c:	00d787b3          	add	a5,a5,a3
    5730:	00e79783          	lh	a5,14(a5)
    5734:	fe0780e3          	beqz	a5,5714 <player_step+0x254>
    5738:	000117b7          	lui	a5,0x11
    573c:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5740:	00d787b3          	add	a5,a5,a3
    5744:	0087d683          	lhu	a3,8(a5)
    5748:	ffd68693          	addi	a3,a3,-3
    574c:	00d79423          	sh	a3,8(a5)
    5750:	fc5ff06f          	j	5714 <player_step+0x254>
            g_bomb--; g_invuln = 60;
    5754:	8141a583          	lw	a1,-2028(gp) # 78fc <g_bomb>
    5758:	fff58593          	addi	a1,a1,-1
    575c:	80b1aa23          	sw	a1,-2028(gp) # 78fc <g_bomb>
    5760:	03c00713          	li	a4,60
    5764:	88e1aa23          	sw	a4,-1900(gp) # 797c <g_invuln>
            bsp_printf("\r\nEV bomb left=%d\r\n", g_bomb);
    5768:	00007537          	lui	a0,0x7
    576c:	f3c50513          	addi	a0,a0,-196 # 6f3c <_data+0xa44>
    5770:	fd9fe0ef          	jal	4748 <bsp_printf>
}
    5774:	e21ff06f          	j	5594 <player_step+0xd4>

00005778 <game_tick>:
{
    5778:	fe010113          	addi	sp,sp,-32
    577c:	00112e23          	sw	ra,28(sp)
    if (g_state == GS_TITLE) {
    5780:	8a41a783          	lw	a5,-1884(gp) # 798c <g_state>
    5784:	02078063          	beqz	a5,57a4 <game_tick+0x2c>
    if (g_state == GS_OVER) {
    5788:	00200713          	li	a4,2
    578c:	0ae78263          	beq	a5,a4,5830 <game_tick+0xb8>
    5790:	00912a23          	sw	s1,20(sp)
    if (g_pause) return;
    5794:	8a01a483          	lw	s1,-1888(gp) # 7988 <g_pause>
    5798:	0c048e63          	beqz	s1,5874 <game_tick+0xfc>
    579c:	01412483          	lw	s1,20(sp)
    57a0:	05c0006f          	j	57fc <game_tick+0x84>
        g_px = (int16_t)FP(FB_WIDTH / 2 + (isin((int)(g_frames & 63)) * 120) / 256);
    57a4:	8741a503          	lw	a0,-1932(gp) # 795c <g_frames>
    57a8:	03f57513          	andi	a0,a0,63
    57ac:	9a4fd0ef          	jal	2950 <isin>
    57b0:	00451713          	slli	a4,a0,0x4
    57b4:	40a70733          	sub	a4,a4,a0
    57b8:	00371713          	slli	a4,a4,0x3
    57bc:	41f75793          	srai	a5,a4,0x1f
    57c0:	0ff7f793          	zext.b	a5,a5
    57c4:	00e787b3          	add	a5,a5,a4
    57c8:	4087d793          	srai	a5,a5,0x8
    57cc:	1e078793          	addi	a5,a5,480
    57d0:	00379793          	slli	a5,a5,0x3
    57d4:	88f19d23          	sh	a5,-1894(gp) # 7982 <g_px>
        g_py = (int16_t)FP(PLAY_Y1 - 70);
    57d8:	000017b7          	lui	a5,0x1
    57dc:	eb078793          	addi	a5,a5,-336 # eb0 <CUSTOM2+0xe55>
    57e0:	88f19c23          	sh	a5,-1896(gp) # 7980 <g_py>
        if (g_keymask & KEY_FIRE) { g_seed += 0x9E3779B9u; game_reset(); bsp_printf("\r\nEV start\r\n"); }
    57e4:	8841a783          	lw	a5,-1916(gp) # 796c <g_keymask>
    57e8:	0107f793          	andi	a5,a5,16
    57ec:	00079e63          	bnez	a5,5808 <game_tick+0x90>
        g_frames++;
    57f0:	8741a783          	lw	a5,-1932(gp) # 795c <g_frames>
    57f4:	00178793          	addi	a5,a5,1
    57f8:	86f1aa23          	sw	a5,-1932(gp) # 795c <g_frames>
}
    57fc:	01c12083          	lw	ra,28(sp)
    5800:	02010113          	addi	sp,sp,32
    5804:	00008067          	ret
        if (g_keymask & KEY_FIRE) { g_seed += 0x9E3779B9u; game_reset(); bsp_printf("\r\nEV start\r\n"); }
    5808:	8281a783          	lw	a5,-2008(gp) # 7910 <g_seed>
    580c:	9e378737          	lui	a4,0x9e378
    5810:	9b970713          	addi	a4,a4,-1607 # 9e3779b9 <__freertos_irq_stack_top+0x9e35e7b9>
    5814:	00e787b3          	add	a5,a5,a4
    5818:	82f1a423          	sw	a5,-2008(gp) # 7910 <g_seed>
    581c:	da9fe0ef          	jal	45c4 <game_reset>
    5820:	00007537          	lui	a0,0x7
    5824:	f5050513          	addi	a0,a0,-176 # 6f50 <_data+0xa58>
    5828:	f21fe0ef          	jal	4748 <bsp_printf>
    582c:	fc5ff06f          	j	57f0 <game_tick+0x78>
        if (g_keymask & KEY_FIRE) { g_seed += 0x9E3779B9u; game_reset(); bsp_printf("\r\nEV restart\r\n"); }
    5830:	8841a783          	lw	a5,-1916(gp) # 796c <g_keymask>
    5834:	0107f793          	andi	a5,a5,16
    5838:	00079a63          	bnez	a5,584c <game_tick+0xd4>
        g_frames++;
    583c:	8741a783          	lw	a5,-1932(gp) # 795c <g_frames>
    5840:	00178793          	addi	a5,a5,1
    5844:	86f1aa23          	sw	a5,-1932(gp) # 795c <g_frames>
        return;
    5848:	fb5ff06f          	j	57fc <game_tick+0x84>
        if (g_keymask & KEY_FIRE) { g_seed += 0x9E3779B9u; game_reset(); bsp_printf("\r\nEV restart\r\n"); }
    584c:	8281a783          	lw	a5,-2008(gp) # 7910 <g_seed>
    5850:	9e378737          	lui	a4,0x9e378
    5854:	9b970713          	addi	a4,a4,-1607 # 9e3779b9 <__freertos_irq_stack_top+0x9e35e7b9>
    5858:	00e787b3          	add	a5,a5,a4
    585c:	82f1a423          	sw	a5,-2008(gp) # 7910 <g_seed>
    5860:	d65fe0ef          	jal	45c4 <game_reset>
    5864:	00007537          	lui	a0,0x7
    5868:	f6050513          	addi	a0,a0,-160 # 6f60 <_data+0xa68>
    586c:	eddfe0ef          	jal	4748 <bsp_printf>
    5870:	fcdff06f          	j	583c <game_tick+0xc4>
    5874:	00812c23          	sw	s0,24(sp)
    5878:	01212823          	sw	s2,16(sp)
    587c:	01312623          	sw	s3,12(sp)
    5880:	01412423          	sw	s4,8(sp)
    5884:	01512223          	sw	s5,4(sp)
    g_frames++;
    5888:	8741a783          	lw	a5,-1932(gp) # 795c <g_frames>
    588c:	00178793          	addi	a5,a5,1
    5890:	86f1aa23          	sw	a5,-1932(gp) # 795c <g_frames>
    player_step();
    5894:	c2dff0ef          	jal	54c0 <player_step>
    if (g_invuln > 0) g_invuln--;
    5898:	8941a783          	lw	a5,-1900(gp) # 797c <g_invuln>
    589c:	00f05663          	blez	a5,58a8 <game_tick+0x130>
    58a0:	fff78793          	addi	a5,a5,-1
    58a4:	88f1aa23          	sw	a5,-1900(gp) # 797c <g_invuln>
    if (++g_level_t >= LEVEL_TICKS) {
    58a8:	8881a783          	lw	a5,-1912(gp) # 7970 <g_level_t>
    58ac:	00178793          	addi	a5,a5,1
    58b0:	88f1a423          	sw	a5,-1912(gp) # 7970 <g_level_t>
    58b4:	70700713          	li	a4,1799
    58b8:	02f75663          	bge	a4,a5,58e4 <game_tick+0x16c>
        g_level_t = 0;
    58bc:	8801a423          	sw	zero,-1912(gp) # 7970 <g_level_t>
        if (g_level < 99) g_level++;
    58c0:	8101a783          	lw	a5,-2032(gp) # 78f8 <g_level>
    58c4:	06200713          	li	a4,98
    58c8:	00f74663          	blt	a4,a5,58d4 <game_tick+0x15c>
    58cc:	00178793          	addi	a5,a5,1
    58d0:	80f1a823          	sw	a5,-2032(gp) # 78f8 <g_level>
        bsp_printf("\r\nEV level=%d\r\n", g_level);
    58d4:	8101a583          	lw	a1,-2032(gp) # 78f8 <g_level>
    58d8:	00007537          	lui	a0,0x7
    58dc:	f7050513          	addi	a0,a0,-144 # 6f70 <_data+0xa78>
    58e0:	e69fe0ef          	jal	4748 <bsp_printf>
    if ((g_frames % (uint32_t)SCORE_TICK_DIV) == 0) g_score += SCORE_PER_TICK;
    58e4:	8741a783          	lw	a5,-1932(gp) # 795c <g_frames>
    58e8:	00a00713          	li	a4,10
    58ec:	02e7f733          	remu	a4,a5,a4
    58f0:	00071863          	bnez	a4,5900 <game_tick+0x188>
    58f4:	8901a703          	lw	a4,-1904(gp) # 7978 <g_score>
    58f8:	00170713          	addi	a4,a4,1
    58fc:	88e1a823          	sw	a4,-1904(gp) # 7978 <g_score>
    if (g_score > SCORE_CAP) g_score = SCORE_CAP;
    5900:	8901a683          	lw	a3,-1904(gp) # 7978 <g_score>
    5904:	000f4737          	lui	a4,0xf4
    5908:	23f70713          	addi	a4,a4,575 # f423f <__freertos_irq_stack_top+0xdb03f>
    590c:	00d75863          	bge	a4,a3,591c <game_tick+0x1a4>
    5910:	000f4737          	lui	a4,0xf4
    5914:	23f70713          	addi	a4,a4,575 # f423f <__freertos_irq_stack_top+0xdb03f>
    5918:	88e1a823          	sw	a4,-1904(gp) # 7978 <g_score>
    if ((g_frames % (uint32_t)ENEMY_SPAWN_T) == 0) {
    591c:	00f7f793          	andi	a5,a5,15
    5920:	2a079663          	bnez	a5,5bcc <game_tick+0x454>
        int want = 2 + g_ncap / 80;
    5924:	81c1a783          	lw	a5,-2020(gp) # 7904 <g_ncap>
    5928:	05000713          	li	a4,80
    592c:	02e7c7b3          	div	a5,a5,a4
    5930:	00278613          	addi	a2,a5,2
        if (want > ENEMY_MAX) want = ENEMY_MAX;
    5934:	01800793          	li	a5,24
    5938:	00c7d463          	bge	a5,a2,5940 <game_tick+0x1c8>
    593c:	01800613          	li	a2,24
        int alive = 0, topup;
    5940:	00048593          	mv	a1,s1
        for (i = 0; i < ENEMY_MAX; i++) if (g_en[i].t) alive++;
    5944:	00048713          	mv	a4,s1
    5948:	0080006f          	j	5950 <game_tick+0x1d8>
    594c:	00170713          	addi	a4,a4,1
    5950:	01700793          	li	a5,23
    5954:	02e7c263          	blt	a5,a4,5978 <game_tick+0x200>
    5958:	000117b7          	lui	a5,0x11
    595c:	00471693          	slli	a3,a4,0x4
    5960:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5964:	00d787b3          	add	a5,a5,a3
    5968:	00e79783          	lh	a5,14(a5)
    596c:	fe0780e3          	beqz	a5,594c <game_tick+0x1d4>
    5970:	00158593          	addi	a1,a1,1
    5974:	fd9ff06f          	j	594c <game_tick+0x1d4>
        topup = want - alive;
    5978:	40b607b3          	sub	a5,a2,a1
        if (topup > ENEMY_TOPUP) topup = ENEMY_TOPUP;
    597c:	00400713          	li	a4,4
    5980:	08f75863          	bge	a4,a5,5a10 <game_tick+0x298>
    5984:	00400793          	li	a5,4
    5988:	0880006f          	j	5a10 <game_tick+0x298>
                    e->kind  = (uint8_t)(rnd() % 3u);
    598c:	fa9fc0ef          	jal	2934 <rnd>
    5990:	00300993          	li	s3,3
    5994:	03357533          	remu	a0,a0,s3
    5998:	000117b7          	lui	a5,0x11
    599c:	00441413          	slli	s0,s0,0x4
    59a0:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    59a4:	00878433          	add	s0,a5,s0
    59a8:	00a40523          	sb	a0,10(s0)
                    e->x     = (int16_t)FP(60 + (int)(rnd() % (uint32_t)(FB_WIDTH - 120)));
    59ac:	f89fc0ef          	jal	2934 <rnd>
    59b0:	34800793          	li	a5,840
    59b4:	02f577b3          	remu	a5,a0,a5
    59b8:	03c78793          	addi	a5,a5,60
    59bc:	00379793          	slli	a5,a5,0x3
    59c0:	00f41023          	sh	a5,0(s0)
                    e->y     = (int16_t)FP(PLAY_Y0 + 40);
    59c4:	1c000793          	li	a5,448
    59c8:	00f41123          	sh	a5,2(s0)
                    e->vx    = 0;
    59cc:	00041223          	sh	zero,4(s0)
                    e->vy    = (int16_t)(4 + (int)(rnd() % 4u));
    59d0:	f65fc0ef          	jal	2934 <rnd>
    59d4:	00357793          	andi	a5,a0,3
    59d8:	00478793          	addi	a5,a5,4
    59dc:	00f41323          	sh	a5,6(s0)
                    e->hp    = 3;
    59e0:	01341423          	sh	s3,8(s0)
                    e->t     = ENEMY_LIFE;
    59e4:	25800793          	li	a5,600
    59e8:	00f41723          	sh	a5,14(s0)
                    e->fire  = (uint8_t)(20 + (int)(rnd() % 30u));
    59ec:	f49fc0ef          	jal	2934 <rnd>
    59f0:	01e00793          	li	a5,30
    59f4:	02f577b3          	remu	a5,a0,a5
    59f8:	01478793          	addi	a5,a5,20
    59fc:	00f405a3          	sb	a5,11(s0)
                    e->phase = (uint8_t)(rnd() & 63u);
    5a00:	f35fc0ef          	jal	2934 <rnd>
    5a04:	03f57513          	andi	a0,a0,63
    5a08:	00a40623          	sb	a0,12(s0)
        if (topup > ENEMY_TOPUP) topup = ENEMY_TOPUP;
    5a0c:	00090793          	mv	a5,s2
        while (topup-- > 0) {
    5a10:	fff78913          	addi	s2,a5,-1
    5a14:	1af05c63          	blez	a5,5bcc <game_tick+0x454>
            for (i = 0; i < ENEMY_MAX; i++) {
    5a18:	00048413          	mv	s0,s1
    5a1c:	01700793          	li	a5,23
    5a20:	fe87c6e3          	blt	a5,s0,5a0c <game_tick+0x294>
                if (g_en[i].t == 0) {
    5a24:	000117b7          	lui	a5,0x11
    5a28:	00441713          	slli	a4,s0,0x4
    5a2c:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5a30:	00e787b3          	add	a5,a5,a4
    5a34:	00e79783          	lh	a5,14(a5)
    5a38:	f4078ae3          	beqz	a5,598c <game_tick+0x214>
            for (i = 0; i < ENEMY_MAX; i++) {
    5a3c:	00140413          	addi	s0,s0,1
    5a40:	fddff06f          	j	5a1c <game_tick+0x2a4>
        if (e->fire == 0) { enemy_fire(e, g_level); e->fire = ENEMY_FIRE_T; }
    5a44:	8101a583          	lw	a1,-2032(gp) # 78f8 <g_level>
    5a48:	00098513          	mv	a0,s3
    5a4c:	c08fd0ef          	jal	2e54 <enemy_fire>
    5a50:	000117b7          	lui	a5,0x11
    5a54:	00441713          	slli	a4,s0,0x4
    5a58:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5a5c:	00e787b3          	add	a5,a5,a4
    5a60:	02e00713          	li	a4,46
    5a64:	00e785a3          	sb	a4,11(a5)
    5a68:	12c0006f          	j	5b94 <game_tick+0x41c>
    for (i = 0; i < ENEMY_MAX; i++) {
    5a6c:	00140413          	addi	s0,s0,1
    5a70:	01700793          	li	a5,23
    5a74:	1687c063          	blt	a5,s0,5bd4 <game_tick+0x45c>
        enemy_t *e = &g_en[i];
    5a78:	00441993          	slli	s3,s0,0x4
    5a7c:	000117b7          	lui	a5,0x11
    5a80:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5a84:	00f989b3          	add	s3,s3,a5
        if (!e->t) continue;
    5a88:	00e99783          	lh	a5,14(s3)
    5a8c:	fe0780e3          	beqz	a5,5a6c <game_tick+0x2f4>
        e->t--;
    5a90:	fff78793          	addi	a5,a5,-1
    5a94:	00f99723          	sh	a5,14(s3)
        e->y = (int16_t)(e->y + e->vy);
    5a98:	0029da03          	lhu	s4,2(s3)
    5a9c:	0069d783          	lhu	a5,6(s3)
    5aa0:	00fa0a33          	add	s4,s4,a5
    5aa4:	010a1a13          	slli	s4,s4,0x10
    5aa8:	410a5a13          	srai	s4,s4,0x10
    5aac:	01499123          	sh	s4,2(s3)
        e->x = (int16_t)(e->x + (isin((int)((g_frames + (uint32_t)i * 8u) & 63u)) * 2));
    5ab0:	0009da83          	lhu	s5,0(s3)
    5ab4:	00341513          	slli	a0,s0,0x3
    5ab8:	8741a783          	lw	a5,-1932(gp) # 795c <g_frames>
    5abc:	00f50533          	add	a0,a0,a5
    5ac0:	03f57513          	andi	a0,a0,63
    5ac4:	e8dfc0ef          	jal	2950 <isin>
    5ac8:	00151513          	slli	a0,a0,0x1
    5acc:	00aa87b3          	add	a5,s5,a0
    5ad0:	01079793          	slli	a5,a5,0x10
    5ad4:	4107d793          	srai	a5,a5,0x10
    5ad8:	00f99023          	sh	a5,0(s3)
        if (PX(e->x) < 40) e->x = (int16_t)FP(40);
    5adc:	4037d793          	srai	a5,a5,0x3
    5ae0:	02700713          	li	a4,39
    5ae4:	00f74663          	blt	a4,a5,5af0 <game_tick+0x378>
    5ae8:	14000713          	li	a4,320
    5aec:	00e99023          	sh	a4,0(s3)
        if (PX(e->x) > FB_WIDTH - 40) e->x = (int16_t)FP(FB_WIDTH - 40);
    5af0:	000117b7          	lui	a5,0x11
    5af4:	00441713          	slli	a4,s0,0x4
    5af8:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5afc:	00e787b3          	add	a5,a5,a4
    5b00:	00079783          	lh	a5,0(a5)
    5b04:	4037d793          	srai	a5,a5,0x3
    5b08:	39800713          	li	a4,920
    5b0c:	02f75063          	bge	a4,a5,5b2c <game_tick+0x3b4>
    5b10:	000117b7          	lui	a5,0x11
    5b14:	00441713          	slli	a4,s0,0x4
    5b18:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5b1c:	00e787b3          	add	a5,a5,a4
    5b20:	00002737          	lui	a4,0x2
    5b24:	cc070713          	addi	a4,a4,-832 # 1cc0 <spr_enemy+0x44>
    5b28:	00e79023          	sh	a4,0(a5)
        if (PX(e->y) > PLAY_Y0 + 220) e->vy = 0;
    5b2c:	403a5a13          	srai	s4,s4,0x3
    5b30:	0ec00793          	li	a5,236
    5b34:	0147dc63          	bge	a5,s4,5b4c <game_tick+0x3d4>
    5b38:	000117b7          	lui	a5,0x11
    5b3c:	00441713          	slli	a4,s0,0x4
    5b40:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5b44:	00e787b3          	add	a5,a5,a4
    5b48:	00079323          	sh	zero,6(a5)
        if (e->fire > 0) e->fire--;
    5b4c:	000117b7          	lui	a5,0x11
    5b50:	00441713          	slli	a4,s0,0x4
    5b54:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5b58:	00e787b3          	add	a5,a5,a4
    5b5c:	00b7c783          	lbu	a5,11(a5)
    5b60:	00078e63          	beqz	a5,5b7c <game_tick+0x404>
    5b64:	00011737          	lui	a4,0x11
    5b68:	00441693          	slli	a3,s0,0x4
    5b6c:	9e870713          	addi	a4,a4,-1560 # 109e8 <g_en>
    5b70:	00d70733          	add	a4,a4,a3
    5b74:	fff78793          	addi	a5,a5,-1
    5b78:	00f705a3          	sb	a5,11(a4)
        if (e->fire == 0) { enemy_fire(e, g_level); e->fire = ENEMY_FIRE_T; }
    5b7c:	000117b7          	lui	a5,0x11
    5b80:	00441713          	slli	a4,s0,0x4
    5b84:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5b88:	00e787b3          	add	a5,a5,a4
    5b8c:	00b7c783          	lbu	a5,11(a5)
    5b90:	ea078ae3          	beqz	a5,5a44 <game_tick+0x2cc>
        if (e->y > FP(PLAY_Y1 + 60)) e->t = 0;
    5b94:	000117b7          	lui	a5,0x11
    5b98:	00441713          	slli	a4,s0,0x4
    5b9c:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5ba0:	00e787b3          	add	a5,a5,a4
    5ba4:	00279703          	lh	a4,2(a5)
    5ba8:	000017b7          	lui	a5,0x1
    5bac:	2c078793          	addi	a5,a5,704 # 12c0 <main+0x1bc>
    5bb0:	eae7dee3          	bge	a5,a4,5a6c <game_tick+0x2f4>
    5bb4:	000117b7          	lui	a5,0x11
    5bb8:	00441713          	slli	a4,s0,0x4
    5bbc:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5bc0:	00e787b3          	add	a5,a5,a4
    5bc4:	00079723          	sh	zero,14(a5)
    5bc8:	ea5ff06f          	j	5a6c <game_tick+0x2f4>
        if (topup > ENEMY_TOPUP) topup = ENEMY_TOPUP;
    5bcc:	00048413          	mv	s0,s1
    5bd0:	ea1ff06f          	j	5a70 <game_tick+0x2f8>
    for (i = 0; i < BUL_TOTAL; i++) {
    5bd4:	00048413          	mv	s0,s1
    5bd8:	1180006f          	j	5cf0 <game_tick+0x578>
                        e->t = 0;
    5bdc:	00071723          	sh	zero,14(a4)
                        spark_add(e->x, e->y);
    5be0:	000b0593          	mv	a1,s6
    5be4:	00098513          	mv	a0,s3
    5be8:	a1dfd0ef          	jal	3604 <spark_add>
                        g_score += SCORE_PER_ENEMY * g_level;
    5bec:	8101a703          	lw	a4,-2032(gp) # 78f8 <g_level>
    5bf0:	06400793          	li	a5,100
    5bf4:	02e787b3          	mul	a5,a5,a4
    5bf8:	8901a683          	lw	a3,-1904(gp) # 7978 <g_score>
    5bfc:	00d787b3          	add	a5,a5,a3
    5c00:	88f1a823          	sw	a5,-1904(gp) # 7978 <g_score>
                        if (g_score > SCORE_CAP) g_score = SCORE_CAP;
    5c04:	000f4737          	lui	a4,0xf4
    5c08:	23f70713          	addi	a4,a4,575 # f423f <__freertos_irq_stack_top+0xdb03f>
    5c0c:	28f75c63          	bge	a4,a5,5ea4 <game_tick+0x72c>
    5c10:	00070793          	mv	a5,a4
    5c14:	88f1a823          	sw	a5,-1904(gp) # 7978 <g_score>
    5c18:	00012b03          	lw	s6,0(sp)
    5c1c:	0d00006f          	j	5cec <game_tick+0x574>
            for (k = 0; k < ENEMY_MAX; k++) {
    5c20:	00190913          	addi	s2,s2,1
    5c24:	01700793          	li	a5,23
    5c28:	0d27c063          	blt	a5,s2,5ce8 <game_tick+0x570>
                if (!e->t) continue;
    5c2c:	000117b7          	lui	a5,0x11
    5c30:	00491713          	slli	a4,s2,0x4
    5c34:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5c38:	00e787b3          	add	a5,a5,a4
    5c3c:	00e79783          	lh	a5,14(a5)
    5c40:	fe0780e3          	beqz	a5,5c20 <game_tick+0x4a8>
                if (hit_cc(bx, by, (int)b->r, PX(e->x), PX(e->y), 15)) {
    5c44:	00011637          	lui	a2,0x11
    5c48:	00141793          	slli	a5,s0,0x1
    5c4c:	008787b3          	add	a5,a5,s0
    5c50:	00279793          	slli	a5,a5,0x2
    5c54:	fe860613          	addi	a2,a2,-24 # 10fe8 <g_bul>
    5c58:	00f60633          	add	a2,a2,a5
    5c5c:	000117b7          	lui	a5,0x11
    5c60:	9e878793          	addi	a5,a5,-1560 # 109e8 <g_en>
    5c64:	00e787b3          	add	a5,a5,a4
    5c68:	00079983          	lh	s3,0(a5)
    5c6c:	00279b03          	lh	s6,2(a5)
    5c70:	00f00793          	li	a5,15
    5c74:	403b5713          	srai	a4,s6,0x3
    5c78:	4039d693          	srai	a3,s3,0x3
    5c7c:	00a64603          	lbu	a2,10(a2)
    5c80:	000a8593          	mv	a1,s5
    5c84:	000a0513          	mv	a0,s4
    5c88:	9a4fd0ef          	jal	2e2c <hit_cc>
    5c8c:	f8050ae3          	beqz	a0,5c20 <game_tick+0x4a8>
                    b->life = 0;
    5c90:	000117b7          	lui	a5,0x11
    5c94:	00141713          	slli	a4,s0,0x1
    5c98:	00870733          	add	a4,a4,s0
    5c9c:	00271713          	slli	a4,a4,0x2
    5ca0:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    5ca4:	00e787b3          	add	a5,a5,a4
    5ca8:	000785a3          	sb	zero,11(a5)
                    if (--e->hp <= 0) {
    5cac:	00011737          	lui	a4,0x11
    5cb0:	00491793          	slli	a5,s2,0x4
    5cb4:	9e870713          	addi	a4,a4,-1560 # 109e8 <g_en>
    5cb8:	00f70733          	add	a4,a4,a5
    5cbc:	00871783          	lh	a5,8(a4)
    5cc0:	fff78793          	addi	a5,a5,-1
    5cc4:	01079793          	slli	a5,a5,0x10
    5cc8:	4107d793          	srai	a5,a5,0x10
    5ccc:	00f71423          	sh	a5,8(a4)
    5cd0:	f0f056e3          	blez	a5,5bdc <game_tick+0x464>
    5cd4:	00012b03          	lw	s6,0(sp)
    5cd8:	0140006f          	j	5cec <game_tick+0x574>
    5cdc:	01612023          	sw	s6,0(sp)
            for (k = 0; k < ENEMY_MAX; k++) {
    5ce0:	00048913          	mv	s2,s1
    5ce4:	f41ff06f          	j	5c24 <game_tick+0x4ac>
    5ce8:	00012b03          	lw	s6,0(sp)
    for (i = 0; i < BUL_TOTAL; i++) {
    5cec:	00140413          	addi	s0,s0,1
    5cf0:	000017b7          	lui	a5,0x1
    5cf4:	97f78793          	addi	a5,a5,-1665 # 97f <CUSTOM2+0x924>
    5cf8:	1a87ca63          	blt	a5,s0,5eac <game_tick+0x734>
        ent_t *b = &g_bul[i];
    5cfc:	00141513          	slli	a0,s0,0x1
    5d00:	00850533          	add	a0,a0,s0
    5d04:	00251513          	slli	a0,a0,0x2
    5d08:	000117b7          	lui	a5,0x11
    5d0c:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    5d10:	00f50533          	add	a0,a0,a5
        if (!b->life) continue;
    5d14:	00b54783          	lbu	a5,11(a0)
    5d18:	fc078ae3          	beqz	a5,5cec <game_tick+0x574>
        if (!ent_step(b, 0)) continue;
    5d1c:	00000593          	li	a1,0
    5d20:	86cfd0ef          	jal	2d8c <ent_step>
    5d24:	fc0504e3          	beqz	a0,5cec <game_tick+0x574>
        bx = PX(b->x); by = PX(b->y);
    5d28:	000117b7          	lui	a5,0x11
    5d2c:	00141713          	slli	a4,s0,0x1
    5d30:	00870733          	add	a4,a4,s0
    5d34:	00271713          	slli	a4,a4,0x2
    5d38:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    5d3c:	00e787b3          	add	a5,a5,a4
    5d40:	00079903          	lh	s2,0(a5)
    5d44:	40395a13          	srai	s4,s2,0x3
    5d48:	00279983          	lh	s3,2(a5)
    5d4c:	4039da93          	srai	s5,s3,0x3
        if (i < PLR_SLOTS) {                         /* 自机弹 → 打敌机 */
    5d50:	01f00793          	li	a5,31
    5d54:	f887d4e3          	bge	a5,s0,5cdc <game_tick+0x564>
            if (g_invuln == 0 && g_state == GS_PLAY &&
    5d58:	8941a783          	lw	a5,-1900(gp) # 797c <g_invuln>
    5d5c:	f80798e3          	bnez	a5,5cec <game_tick+0x574>
    5d60:	8a41a703          	lw	a4,-1884(gp) # 798c <g_state>
    5d64:	00100793          	li	a5,1
    5d68:	f8f712e3          	bne	a4,a5,5cec <game_tick+0x574>
                hit_cc(bx, by, (int)b->r, PX(g_px), PX(g_py), PLR_HIT_R)) {
    5d6c:	00011637          	lui	a2,0x11
    5d70:	00141793          	slli	a5,s0,0x1
    5d74:	008787b3          	add	a5,a5,s0
    5d78:	00279793          	slli	a5,a5,0x2
    5d7c:	fe860613          	addi	a2,a2,-24 # 10fe8 <g_bul>
    5d80:	00f60633          	add	a2,a2,a5
    5d84:	89819703          	lh	a4,-1896(gp) # 7980 <g_py>
    5d88:	89a19683          	lh	a3,-1894(gp) # 7982 <g_px>
    5d8c:	00400793          	li	a5,4
    5d90:	40375713          	srai	a4,a4,0x3
    5d94:	4036d693          	srai	a3,a3,0x3
    5d98:	00a64603          	lbu	a2,10(a2)
    5d9c:	000a8593          	mv	a1,s5
    5da0:	000a0513          	mv	a0,s4
    5da4:	888fd0ef          	jal	2e2c <hit_cc>
            if (g_invuln == 0 && g_state == GS_PLAY &&
    5da8:	f40502e3          	beqz	a0,5cec <game_tick+0x574>
                b->life = 0;
    5dac:	000117b7          	lui	a5,0x11
    5db0:	00141713          	slli	a4,s0,0x1
    5db4:	00870733          	add	a4,a4,s0
    5db8:	00271713          	slli	a4,a4,0x2
    5dbc:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    5dc0:	00e787b3          	add	a5,a5,a4
    5dc4:	000785a3          	sb	zero,11(a5)
                spark_add(b->x, b->y);
    5dc8:	00098593          	mv	a1,s3
    5dcc:	00090513          	mv	a0,s2
    5dd0:	835fd0ef          	jal	3604 <spark_add>
                g_hp--;
    5dd4:	8181a583          	lw	a1,-2024(gp) # 7900 <g_hp>
    5dd8:	fff58593          	addi	a1,a1,-1
    5ddc:	80b1ac23          	sw	a1,-2024(gp) # 7900 <g_hp>
                g_invuln = INVULN_T;
    5de0:	06400713          	li	a4,100
    5de4:	88e1aa23          	sw	a4,-1900(gp) # 797c <g_invuln>
                bsp_printf("\r\nEV hit hp=%d\r\n", g_hp);
    5de8:	00007537          	lui	a0,0x7
    5dec:	f8050513          	addi	a0,a0,-128 # 6f80 <_data+0xa88>
    5df0:	959fe0ef          	jal	4748 <bsp_printf>
                if (g_hp <= 0) {
    5df4:	8181a783          	lw	a5,-2024(gp) # 7900 <g_hp>
    5df8:	eef04ae3          	bgtz	a5,5cec <game_tick+0x574>
                    for (q = PLR_SLOTS; q < BUL_TOTAL; q++)
    5dfc:	02000413          	li	s0,32
    5e00:	0080006f          	j	5e08 <game_tick+0x690>
    5e04:	00140413          	addi	s0,s0,1
    5e08:	000017b7          	lui	a5,0x1
    5e0c:	97f78793          	addi	a5,a5,-1665 # 97f <CUSTOM2+0x924>
    5e10:	0487ca63          	blt	a5,s0,5e64 <game_tick+0x6ec>
                        if (g_bul[q].life && (q & 7) == 0) spark_add(g_bul[q].x, g_bul[q].y);
    5e14:	000117b7          	lui	a5,0x11
    5e18:	00141713          	slli	a4,s0,0x1
    5e1c:	00870733          	add	a4,a4,s0
    5e20:	00271713          	slli	a4,a4,0x2
    5e24:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    5e28:	00e787b3          	add	a5,a5,a4
    5e2c:	00b7c783          	lbu	a5,11(a5)
    5e30:	fc078ae3          	beqz	a5,5e04 <game_tick+0x68c>
    5e34:	00747793          	andi	a5,s0,7
    5e38:	fc0796e3          	bnez	a5,5e04 <game_tick+0x68c>
    5e3c:	000117b7          	lui	a5,0x11
    5e40:	00141713          	slli	a4,s0,0x1
    5e44:	00870733          	add	a4,a4,s0
    5e48:	00271713          	slli	a4,a4,0x2
    5e4c:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    5e50:	00e787b3          	add	a5,a5,a4
    5e54:	00279583          	lh	a1,2(a5)
    5e58:	00079503          	lh	a0,0(a5)
    5e5c:	fa8fd0ef          	jal	3604 <spark_add>
    5e60:	fa5ff06f          	j	5e04 <game_tick+0x68c>
                    g_state = GS_OVER;
    5e64:	00200713          	li	a4,2
    5e68:	8ae1a223          	sw	a4,-1884(gp) # 798c <g_state>
                    bsp_printf("\r\nEV gameover score=%d level=%d on=%d n=%d\r\n",
    5e6c:	81c1a703          	lw	a4,-2020(gp) # 7904 <g_ncap>
    5e70:	85c1a683          	lw	a3,-1956(gp) # 7944 <g_on_screen>
    5e74:	8101a603          	lw	a2,-2032(gp) # 78f8 <g_level>
    5e78:	8901a583          	lw	a1,-1904(gp) # 7978 <g_score>
    5e7c:	00007537          	lui	a0,0x7
    5e80:	f9450513          	addi	a0,a0,-108 # 6f94 <_data+0xa9c>
    5e84:	8c5fe0ef          	jal	4748 <bsp_printf>
                    return;
    5e88:	01812403          	lw	s0,24(sp)
    5e8c:	01412483          	lw	s1,20(sp)
    5e90:	01012903          	lw	s2,16(sp)
    5e94:	00c12983          	lw	s3,12(sp)
    5e98:	00812a03          	lw	s4,8(sp)
    5e9c:	00412a83          	lw	s5,4(sp)
    5ea0:	95dff06f          	j	57fc <game_tick+0x84>
    5ea4:	00012b03          	lw	s6,0(sp)
    5ea8:	e45ff06f          	j	5cec <game_tick+0x574>
    for (i = 0; i < SPARK_MAX; i++) if (g_spk[i].life) g_spk[i].life--;
    5eac:	00048793          	mv	a5,s1
    5eb0:	0080006f          	j	5eb8 <game_tick+0x740>
    5eb4:	00178793          	addi	a5,a5,1
    5eb8:	05f00713          	li	a4,95
    5ebc:	04f74463          	blt	a4,a5,5f04 <game_tick+0x78c>
    5ec0:	00011737          	lui	a4,0x11
    5ec4:	00179693          	slli	a3,a5,0x1
    5ec8:	00f686b3          	add	a3,a3,a5
    5ecc:	00269693          	slli	a3,a3,0x2
    5ed0:	b6870713          	addi	a4,a4,-1176 # 10b68 <g_spk>
    5ed4:	00d70733          	add	a4,a4,a3
    5ed8:	00b74703          	lbu	a4,11(a4)
    5edc:	fc070ce3          	beqz	a4,5eb4 <game_tick+0x73c>
    5ee0:	000116b7          	lui	a3,0x11
    5ee4:	00179613          	slli	a2,a5,0x1
    5ee8:	00f60633          	add	a2,a2,a5
    5eec:	00261613          	slli	a2,a2,0x2
    5ef0:	b6868693          	addi	a3,a3,-1176 # 10b68 <g_spk>
    5ef4:	00c686b3          	add	a3,a3,a2
    5ef8:	fff70713          	addi	a4,a4,-1
    5efc:	00e685a3          	sb	a4,11(a3)
    5f00:	fb5ff06f          	j	5eb4 <game_tick+0x73c>
        int live = 0;
    5f04:	00048613          	mv	a2,s1
        for (i = PLR_SLOTS; i < BUL_TOTAL; i++) if (g_bul[i].life) live++;
    5f08:	02000693          	li	a3,32
    5f0c:	0080006f          	j	5f14 <game_tick+0x79c>
    5f10:	00168693          	addi	a3,a3,1
    5f14:	000017b7          	lui	a5,0x1
    5f18:	97f78793          	addi	a5,a5,-1665 # 97f <CUSTOM2+0x924>
    5f1c:	02d7c663          	blt	a5,a3,5f48 <game_tick+0x7d0>
    5f20:	000117b7          	lui	a5,0x11
    5f24:	00169713          	slli	a4,a3,0x1
    5f28:	00d70733          	add	a4,a4,a3
    5f2c:	00271713          	slli	a4,a4,0x2
    5f30:	fe878793          	addi	a5,a5,-24 # 10fe8 <g_bul>
    5f34:	00e787b3          	add	a5,a5,a4
    5f38:	00b7c783          	lbu	a5,11(a5)
    5f3c:	fc078ae3          	beqz	a5,5f10 <game_tick+0x798>
    5f40:	00160613          	addi	a2,a2,1
    5f44:	fcdff06f          	j	5f10 <game_tick+0x798>
        g_bul_live = live;
    5f48:	84c1aa23          	sw	a2,-1964(gp) # 793c <g_bul_live>
    for (i = 0; i < g_star_n; i++) {
    5f4c:	0080006f          	j	5f54 <game_tick+0x7dc>
    5f50:	00148493          	addi	s1,s1,1
    5f54:	8241a783          	lw	a5,-2012(gp) # 790c <g_star_n>
    5f58:	06f4d063          	bge	s1,a5,5fb8 <game_tick+0x840>
        g_star[i].y = (int16_t)(g_star[i].y + (int)g_star[i].spd);
    5f5c:	000087b7          	lui	a5,0x8
    5f60:	00349713          	slli	a4,s1,0x3
    5f64:	a2878793          	addi	a5,a5,-1496 # 7a28 <g_star>
    5f68:	00e787b3          	add	a5,a5,a4
    5f6c:	0027d703          	lhu	a4,2(a5)
    5f70:	0067c683          	lbu	a3,6(a5)
    5f74:	00d70733          	add	a4,a4,a3
    5f78:	01071713          	slli	a4,a4,0x10
    5f7c:	41075713          	srai	a4,a4,0x10
    5f80:	00e79123          	sh	a4,2(a5)
        if (g_star[i].y > PLAY_Y1) {
    5f84:	21c00793          	li	a5,540
    5f88:	fce7d4e3          	bge	a5,a4,5f50 <game_tick+0x7d8>
            g_star[i].y = (int16_t)PLAY_Y0;
    5f8c:	00008437          	lui	s0,0x8
    5f90:	00349793          	slli	a5,s1,0x3
    5f94:	a2840413          	addi	s0,s0,-1496 # 7a28 <g_star>
    5f98:	00f40433          	add	s0,s0,a5
    5f9c:	01000793          	li	a5,16
    5fa0:	00f41123          	sh	a5,2(s0)
            g_star[i].x = (int16_t)(rnd() % FB_WIDTH);
    5fa4:	991fc0ef          	jal	2934 <rnd>
    5fa8:	3c000793          	li	a5,960
    5fac:	02f57533          	remu	a0,a0,a5
    5fb0:	00a41023          	sh	a0,0(s0)
    5fb4:	f9dff06f          	j	5f50 <game_tick+0x7d8>
    5fb8:	01812403          	lw	s0,24(sp)
    5fbc:	01412483          	lw	s1,20(sp)
    5fc0:	01012903          	lw	s2,16(sp)
    5fc4:	00c12983          	lw	s3,12(sp)
    5fc8:	00812a03          	lw	s4,8(sp)
    5fcc:	00412a83          	lw	s5,4(sp)
    5fd0:	82dff06f          	j	57fc <game_tick+0x84>

00005fd4 <blt_recover>:
{
    5fd4:	ff010113          	addi	sp,sp,-16
    5fd8:	00112623          	sw	ra,12(sp)
    5fdc:	00812423          	sw	s0,8(sp)
    5fe0:	00912223          	sw	s1,4(sp)
    5fe4:	00050413          	mv	s0,a0
    g_stto++;
    5fe8:	8c81a783          	lw	a5,-1848(gp) # 79b0 <g_stto>
    5fec:	00178793          	addi	a5,a5,1
    5ff0:	8cf1a423          	sw	a5,-1848(gp) # 79b0 <g_stto>
               why, (unsigned)blt_stat(), (unsigned)blt_cnt());
    5ff4:	c5cfc0ef          	jal	2450 <blt_stat>
    5ff8:	00050493          	mv	s1,a0
    5ffc:	c38fc0ef          	jal	2434 <blt_cnt>
    6000:	00050693          	mv	a3,a0
    bsp_printf("\r\nEV recover (%s) STATUS=%x COUNT=%d\r\n",
    6004:	00048613          	mv	a2,s1
    6008:	00040593          	mv	a1,s0
    600c:	00007537          	lui	a0,0x7
    6010:	fc450513          	addi	a0,a0,-60 # 6fc4 <_data+0xacc>
    6014:	f34fe0ef          	jal	4748 <bsp_printf>
    blt_init();
    6018:	c94fc0ef          	jal	24ac <blt_init>
    g_clr_need = 1;
    601c:	00100713          	li	a4,1
    6020:	8ce1ae23          	sw	a4,-1828(gp) # 79c4 <g_clr_need>
    g_dl_i = 0;
    6024:	8a01a623          	sw	zero,-1876(gp) # 7994 <g_dl_i>
    g_clr_fb++;
    6028:	8d41a783          	lw	a5,-1836(gp) # 79bc <g_clr_fb>
    602c:	00178793          	addi	a5,a5,1
    6030:	8cf1aa23          	sw	a5,-1836(gp) # 79bc <g_clr_fb>
}
    6034:	00c12083          	lw	ra,12(sp)
    6038:	00812403          	lw	s0,8(sp)
    603c:	00412483          	lw	s1,4(sp)
    6040:	01010113          	addi	sp,sp,16
    6044:	00008067          	ret

00006048 <__udivdi3>:
    6048:	00060813          	mv	a6,a2
    604c:	00050893          	mv	a7,a0
    6050:	00058713          	mv	a4,a1
    6054:	0e069063          	bnez	a3,6134 <__udivdi3+0xec>
    6058:	12c5fe63          	bgeu	a1,a2,6194 <__udivdi3+0x14c>
    605c:	000107b7          	lui	a5,0x10
    6060:	1ef66e63          	bltu	a2,a5,625c <__udivdi3+0x214>
    6064:	010007b7          	lui	a5,0x1000
    6068:	01800693          	li	a3,24
    606c:	00f67463          	bgeu	a2,a5,6074 <__udivdi3+0x2c>
    6070:	01000693          	li	a3,16
    6074:	00d65333          	srl	t1,a2,a3
    6078:	00001797          	auipc	a5,0x1
    607c:	77c78793          	addi	a5,a5,1916 # 77f4 <__clz_tab>
    6080:	006787b3          	add	a5,a5,t1
    6084:	0007c783          	lbu	a5,0(a5)
    6088:	02000313          	li	t1,32
    608c:	00d787b3          	add	a5,a5,a3
    6090:	40f306b3          	sub	a3,t1,a5
    6094:	00f30c63          	beq	t1,a5,60ac <__udivdi3+0x64>
    6098:	00d59733          	sll	a4,a1,a3
    609c:	00f557b3          	srl	a5,a0,a5
    60a0:	00d61833          	sll	a6,a2,a3
    60a4:	00e7e733          	or	a4,a5,a4
    60a8:	00d518b3          	sll	a7,a0,a3
    60ac:	01085613          	srli	a2,a6,0x10
    60b0:	02c75533          	divu	a0,a4,a2
    60b4:	01081693          	slli	a3,a6,0x10
    60b8:	0106d693          	srli	a3,a3,0x10
    60bc:	0108d793          	srli	a5,a7,0x10
    60c0:	02c77733          	remu	a4,a4,a2
    60c4:	02a685b3          	mul	a1,a3,a0
    60c8:	01071713          	slli	a4,a4,0x10
    60cc:	00e7e7b3          	or	a5,a5,a4
    60d0:	00b7fc63          	bgeu	a5,a1,60e8 <__udivdi3+0xa0>
    60d4:	00f807b3          	add	a5,a6,a5
    60d8:	fff50713          	addi	a4,a0,-1
    60dc:	0107e463          	bltu	a5,a6,60e4 <__udivdi3+0x9c>
    60e0:	40b7e063          	bltu	a5,a1,64e0 <__udivdi3+0x498>
    60e4:	00070513          	mv	a0,a4
    60e8:	40b787b3          	sub	a5,a5,a1
    60ec:	02c7d733          	divu	a4,a5,a2
    60f0:	01089893          	slli	a7,a7,0x10
    60f4:	0108d893          	srli	a7,a7,0x10
    60f8:	02c7f7b3          	remu	a5,a5,a2
    60fc:	02e686b3          	mul	a3,a3,a4
    6100:	01079793          	slli	a5,a5,0x10
    6104:	00f8e8b3          	or	a7,a7,a5
    6108:	00d8fe63          	bgeu	a7,a3,6124 <__udivdi3+0xdc>
    610c:	011808b3          	add	a7,a6,a7
    6110:	fff70793          	addi	a5,a4,-1
    6114:	0108e663          	bltu	a7,a6,6120 <__udivdi3+0xd8>
    6118:	ffe70713          	addi	a4,a4,-2
    611c:	00d8e463          	bltu	a7,a3,6124 <__udivdi3+0xdc>
    6120:	00078713          	mv	a4,a5
    6124:	01051513          	slli	a0,a0,0x10
    6128:	00e56533          	or	a0,a0,a4
    612c:	00000593          	li	a1,0
    6130:	00008067          	ret
    6134:	00d5f863          	bgeu	a1,a3,6144 <__udivdi3+0xfc>
    6138:	00000593          	li	a1,0
    613c:	00000513          	li	a0,0
    6140:	00008067          	ret
    6144:	000107b7          	lui	a5,0x10
    6148:	1ef6e863          	bltu	a3,a5,6338 <__udivdi3+0x2f0>
    614c:	01000737          	lui	a4,0x1000
    6150:	01800793          	li	a5,24
    6154:	00e6f463          	bgeu	a3,a4,615c <__udivdi3+0x114>
    6158:	01000793          	li	a5,16
    615c:	00f6d833          	srl	a6,a3,a5
    6160:	00001717          	auipc	a4,0x1
    6164:	69470713          	addi	a4,a4,1684 # 77f4 <__clz_tab>
    6168:	01070733          	add	a4,a4,a6
    616c:	00074703          	lbu	a4,0(a4)
    6170:	02000893          	li	a7,32
    6174:	00f70733          	add	a4,a4,a5
    6178:	40e88833          	sub	a6,a7,a4
    617c:	1ee89663          	bne	a7,a4,6368 <__udivdi3+0x320>
    6180:	32b6e463          	bltu	a3,a1,64a8 <__udivdi3+0x460>
    6184:	00c53533          	sltu	a0,a0,a2
    6188:	00153513          	seqz	a0,a0
    618c:	00000593          	li	a1,0
    6190:	00008067          	ret
    6194:	0c060c63          	beqz	a2,626c <__udivdi3+0x224>
    6198:	000107b7          	lui	a5,0x10
    619c:	2ef67c63          	bgeu	a2,a5,6494 <__udivdi3+0x44c>
    61a0:	10063713          	sltiu	a4,a2,256
    61a4:	00173713          	seqz	a4,a4
    61a8:	00371713          	slli	a4,a4,0x3
    61ac:	00e656b3          	srl	a3,a2,a4
    61b0:	00001797          	auipc	a5,0x1
    61b4:	64478793          	addi	a5,a5,1604 # 77f4 <__clz_tab>
    61b8:	00d787b3          	add	a5,a5,a3
    61bc:	0007c783          	lbu	a5,0(a5)
    61c0:	02000693          	li	a3,32
    61c4:	00e787b3          	add	a5,a5,a4
    61c8:	40f68eb3          	sub	t4,a3,a5
    61cc:	0cf69463          	bne	a3,a5,6294 <__udivdi3+0x24c>
    61d0:	40c587b3          	sub	a5,a1,a2
    61d4:	01065693          	srli	a3,a2,0x10
    61d8:	01061613          	slli	a2,a2,0x10
    61dc:	01065613          	srli	a2,a2,0x10
    61e0:	00100593          	li	a1,1
    61e4:	02d7d533          	divu	a0,a5,a3
    61e8:	0108d713          	srli	a4,a7,0x10
    61ec:	02d7f7b3          	remu	a5,a5,a3
    61f0:	02c50333          	mul	t1,a0,a2
    61f4:	01079793          	slli	a5,a5,0x10
    61f8:	00f767b3          	or	a5,a4,a5
    61fc:	0067fc63          	bgeu	a5,t1,6214 <__udivdi3+0x1cc>
    6200:	00f807b3          	add	a5,a6,a5
    6204:	fff50713          	addi	a4,a0,-1
    6208:	0107e463          	bltu	a5,a6,6210 <__udivdi3+0x1c8>
    620c:	2c67e463          	bltu	a5,t1,64d4 <__udivdi3+0x48c>
    6210:	00070513          	mv	a0,a4
    6214:	406787b3          	sub	a5,a5,t1
    6218:	02d7d733          	divu	a4,a5,a3
    621c:	01089893          	slli	a7,a7,0x10
    6220:	0108d893          	srli	a7,a7,0x10
    6224:	02d7f7b3          	remu	a5,a5,a3
    6228:	02c70633          	mul	a2,a4,a2
    622c:	01079793          	slli	a5,a5,0x10
    6230:	00f8e8b3          	or	a7,a7,a5
    6234:	00c8fe63          	bgeu	a7,a2,6250 <__udivdi3+0x208>
    6238:	011808b3          	add	a7,a6,a7
    623c:	fff70793          	addi	a5,a4,-1
    6240:	0108e663          	bltu	a7,a6,624c <__udivdi3+0x204>
    6244:	ffe70713          	addi	a4,a4,-2
    6248:	00c8e463          	bltu	a7,a2,6250 <__udivdi3+0x208>
    624c:	00078713          	mv	a4,a5
    6250:	01051513          	slli	a0,a0,0x10
    6254:	00e56533          	or	a0,a0,a4
    6258:	00008067          	ret
    625c:	10063693          	sltiu	a3,a2,256
    6260:	0016b693          	seqz	a3,a3
    6264:	00369693          	slli	a3,a3,0x3
    6268:	e0dff06f          	j	6074 <__udivdi3+0x2c>
    626c:	00000693          	li	a3,0
    6270:	00001797          	auipc	a5,0x1
    6274:	58478793          	addi	a5,a5,1412 # 77f4 <__clz_tab>
    6278:	00d787b3          	add	a5,a5,a3
    627c:	0007c783          	lbu	a5,0(a5)
    6280:	00000713          	li	a4,0
    6284:	02000693          	li	a3,32
    6288:	00e787b3          	add	a5,a5,a4
    628c:	40f68eb3          	sub	t4,a3,a5
    6290:	f4f680e3          	beq	a3,a5,61d0 <__udivdi3+0x188>
    6294:	01d61833          	sll	a6,a2,t4
    6298:	00f5d333          	srl	t1,a1,a5
    629c:	01085693          	srli	a3,a6,0x10
    62a0:	02d35e33          	divu	t3,t1,a3
    62a4:	01081613          	slli	a2,a6,0x10
    62a8:	01d595b3          	sll	a1,a1,t4
    62ac:	01065613          	srli	a2,a2,0x10
    62b0:	00f557b3          	srl	a5,a0,a5
    62b4:	00b7e7b3          	or	a5,a5,a1
    62b8:	0107d713          	srli	a4,a5,0x10
    62bc:	01d518b3          	sll	a7,a0,t4
    62c0:	02d37333          	remu	t1,t1,a3
    62c4:	03c605b3          	mul	a1,a2,t3
    62c8:	01031313          	slli	t1,t1,0x10
    62cc:	00676733          	or	a4,a4,t1
    62d0:	00b77e63          	bgeu	a4,a1,62ec <__udivdi3+0x2a4>
    62d4:	00e80733          	add	a4,a6,a4
    62d8:	fffe0513          	addi	a0,t3,-1
    62dc:	1f076463          	bltu	a4,a6,64c4 <__udivdi3+0x47c>
    62e0:	1eb77263          	bgeu	a4,a1,64c4 <__udivdi3+0x47c>
    62e4:	ffee0e13          	addi	t3,t3,-2
    62e8:	01070733          	add	a4,a4,a6
    62ec:	40b70733          	sub	a4,a4,a1
    62f0:	02d75533          	divu	a0,a4,a3
    62f4:	01079793          	slli	a5,a5,0x10
    62f8:	0107d793          	srli	a5,a5,0x10
    62fc:	02d77733          	remu	a4,a4,a3
    6300:	02a60333          	mul	t1,a2,a0
    6304:	01071713          	slli	a4,a4,0x10
    6308:	00e7e7b3          	or	a5,a5,a4
    630c:	0067fe63          	bgeu	a5,t1,6328 <__udivdi3+0x2e0>
    6310:	00f807b3          	add	a5,a6,a5
    6314:	fff50713          	addi	a4,a0,-1
    6318:	1907ee63          	bltu	a5,a6,64b4 <__udivdi3+0x46c>
    631c:	1867fc63          	bgeu	a5,t1,64b4 <__udivdi3+0x46c>
    6320:	ffe50513          	addi	a0,a0,-2
    6324:	010787b3          	add	a5,a5,a6
    6328:	010e1593          	slli	a1,t3,0x10
    632c:	406787b3          	sub	a5,a5,t1
    6330:	00a5e5b3          	or	a1,a1,a0
    6334:	eb1ff06f          	j	61e4 <__udivdi3+0x19c>
    6338:	1006b793          	sltiu	a5,a3,256
    633c:	0017b793          	seqz	a5,a5
    6340:	00379793          	slli	a5,a5,0x3
    6344:	00f6d833          	srl	a6,a3,a5
    6348:	00001717          	auipc	a4,0x1
    634c:	4ac70713          	addi	a4,a4,1196 # 77f4 <__clz_tab>
    6350:	01070733          	add	a4,a4,a6
    6354:	00074703          	lbu	a4,0(a4)
    6358:	02000893          	li	a7,32
    635c:	00f70733          	add	a4,a4,a5
    6360:	40e88833          	sub	a6,a7,a4
    6364:	e0e88ee3          	beq	a7,a4,6180 <__udivdi3+0x138>
    6368:	00e65e33          	srl	t3,a2,a4
    636c:	010696b3          	sll	a3,a3,a6
    6370:	00de6e33          	or	t3,t3,a3
    6374:	00e5d8b3          	srl	a7,a1,a4
    6378:	010e5e93          	srli	t4,t3,0x10
    637c:	03d8d7b3          	divu	a5,a7,t4
    6380:	010e1313          	slli	t1,t3,0x10
    6384:	010595b3          	sll	a1,a1,a6
    6388:	01035313          	srli	t1,t1,0x10
    638c:	00e55733          	srl	a4,a0,a4
    6390:	00b76733          	or	a4,a4,a1
    6394:	01075693          	srli	a3,a4,0x10
    6398:	01061633          	sll	a2,a2,a6
    639c:	03d8f8b3          	remu	a7,a7,t4
    63a0:	02f305b3          	mul	a1,t1,a5
    63a4:	01089893          	slli	a7,a7,0x10
    63a8:	0116e6b3          	or	a3,a3,a7
    63ac:	00b6fe63          	bgeu	a3,a1,63c8 <__udivdi3+0x380>
    63b0:	00de06b3          	add	a3,t3,a3
    63b4:	fff78893          	addi	a7,a5,-1
    63b8:	11c6ea63          	bltu	a3,t3,64cc <__udivdi3+0x484>
    63bc:	10b6f863          	bgeu	a3,a1,64cc <__udivdi3+0x484>
    63c0:	ffe78793          	addi	a5,a5,-2
    63c4:	01c686b3          	add	a3,a3,t3
    63c8:	40b686b3          	sub	a3,a3,a1
    63cc:	03d6d5b3          	divu	a1,a3,t4
    63d0:	01071713          	slli	a4,a4,0x10
    63d4:	01075713          	srli	a4,a4,0x10
    63d8:	03d6f6b3          	remu	a3,a3,t4
    63dc:	02b308b3          	mul	a7,t1,a1
    63e0:	01069693          	slli	a3,a3,0x10
    63e4:	00d76733          	or	a4,a4,a3
    63e8:	01177e63          	bgeu	a4,a7,6404 <__udivdi3+0x3bc>
    63ec:	00ee0733          	add	a4,t3,a4
    63f0:	fff58693          	addi	a3,a1,-1
    63f4:	0dc76463          	bltu	a4,t3,64bc <__udivdi3+0x474>
    63f8:	0d177263          	bgeu	a4,a7,64bc <__udivdi3+0x474>
    63fc:	ffe58593          	addi	a1,a1,-2
    6400:	01c70733          	add	a4,a4,t3
    6404:	01079793          	slli	a5,a5,0x10
    6408:	00010eb7          	lui	t4,0x10
    640c:	00b7e7b3          	or	a5,a5,a1
    6410:	fffe8693          	addi	a3,t4,-1 # ffff <__global_pointer$+0x7f17>
    6414:	00d7f5b3          	and	a1,a5,a3
    6418:	0107d313          	srli	t1,a5,0x10
    641c:	00d676b3          	and	a3,a2,a3
    6420:	01065613          	srli	a2,a2,0x10
    6424:	02d58e33          	mul	t3,a1,a3
    6428:	41170733          	sub	a4,a4,a7
    642c:	02d306b3          	mul	a3,t1,a3
    6430:	010e5893          	srli	a7,t3,0x10
    6434:	02c585b3          	mul	a1,a1,a2
    6438:	00d585b3          	add	a1,a1,a3
    643c:	00b885b3          	add	a1,a7,a1
    6440:	02c30333          	mul	t1,t1,a2
    6444:	00d5f463          	bgeu	a1,a3,644c <__udivdi3+0x404>
    6448:	01d30333          	add	t1,t1,t4
    644c:	0105d693          	srli	a3,a1,0x10
    6450:	006686b3          	add	a3,a3,t1
    6454:	02d76a63          	bltu	a4,a3,6488 <__udivdi3+0x440>
    6458:	00d70863          	beq	a4,a3,6468 <__udivdi3+0x420>
    645c:	00078513          	mv	a0,a5
    6460:	00000593          	li	a1,0
    6464:	00008067          	ret
    6468:	000106b7          	lui	a3,0x10
    646c:	fff68693          	addi	a3,a3,-1 # ffff <__global_pointer$+0x7f17>
    6470:	00d5f733          	and	a4,a1,a3
    6474:	01071713          	slli	a4,a4,0x10
    6478:	00de7e33          	and	t3,t3,a3
    647c:	01051533          	sll	a0,a0,a6
    6480:	01c70733          	add	a4,a4,t3
    6484:	fce57ce3          	bgeu	a0,a4,645c <__udivdi3+0x414>
    6488:	fff78513          	addi	a0,a5,-1
    648c:	00000593          	li	a1,0
    6490:	00008067          	ret
    6494:	010007b7          	lui	a5,0x1000
    6498:	04f67a63          	bgeu	a2,a5,64ec <__udivdi3+0x4a4>
    649c:	01065693          	srli	a3,a2,0x10
    64a0:	01000713          	li	a4,16
    64a4:	d0dff06f          	j	61b0 <__udivdi3+0x168>
    64a8:	00000593          	li	a1,0
    64ac:	00100513          	li	a0,1
    64b0:	00008067          	ret
    64b4:	00070513          	mv	a0,a4
    64b8:	e71ff06f          	j	6328 <__udivdi3+0x2e0>
    64bc:	00068593          	mv	a1,a3
    64c0:	f45ff06f          	j	6404 <__udivdi3+0x3bc>
    64c4:	00050e13          	mv	t3,a0
    64c8:	e25ff06f          	j	62ec <__udivdi3+0x2a4>
    64cc:	00088793          	mv	a5,a7
    64d0:	ef9ff06f          	j	63c8 <__udivdi3+0x380>
    64d4:	ffe50513          	addi	a0,a0,-2
    64d8:	010787b3          	add	a5,a5,a6
    64dc:	d39ff06f          	j	6214 <__udivdi3+0x1cc>
    64e0:	ffe50513          	addi	a0,a0,-2
    64e4:	010787b3          	add	a5,a5,a6
    64e8:	c01ff06f          	j	60e8 <__udivdi3+0xa0>
    64ec:	01865693          	srli	a3,a2,0x18
    64f0:	01800713          	li	a4,24
    64f4:	cbdff06f          	j	61b0 <__udivdi3+0x168>
