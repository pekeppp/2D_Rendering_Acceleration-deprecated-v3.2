
build/fbTest.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00002197          	auipc	gp,0x2
    1004:	ac018193          	addi	gp,gp,-1344 # 2ac0 <__global_pointer$>
.global smp_lottery_target
.global smp_lottery_lock
.global smp_slave


  sw x0, smp_lottery_lock, a1
    1008:	8201a023          	sw	zero,-2016(gp) # 22e0 <smp_lottery_lock>

0000100c <smp_tyranny>:

smp_tyranny:
  csrr a0, mhartid
    100c:	f1402573          	csrr	a0,mhartid
  beqz a0, init
    1010:	02050e63          	beqz	a0,104c <init>

00001014 <smp_slave>:

smp_slave:
	lw a0, smp_lottery_lock
    1014:	8201a503          	lw	a0,-2016(gp) # 22e0 <smp_lottery_lock>
	beqz a0, smp_slave
    1018:	fe050ee3          	beqz	a0,1014 <smp_slave>

	fence r, r
    101c:	0220000f          	fence	r,r
    1020:	0000100f          	.word	0x0000100f
	//li a1, -1
	//amoadd.w x0, a1,(a0)

	.word(0x100F) //i$ flush
	lw a5, smp_lottery_target
    1024:	81c1a783          	lw	a5,-2020(gp) # 22dc <__bss_start>
	li a0, 0
    1028:	00000513          	li	a0,0
	li a1, 0
    102c:	00000593          	li	a1,0
	li a2, 0
    1030:	00000613          	li	a2,0
	jr a5
    1034:	00078067          	jr	a5

00001038 <smp_unlock>:

.global   smp_unlock
.type    smp_unlock,%function
smp_unlock:
	sw a0, smp_lottery_target, a1
    1038:	80a1ae23          	sw	a0,-2020(gp) # 22dc <__bss_start>
	fence w, w
    103c:	0110000f          	fence	w,w
	li a0, 1
    1040:	00100513          	li	a0,1
	sw a0, smp_lottery_lock, a1
    1044:	82a1a023          	sw	a0,-2016(gp) # 22e0 <smp_lottery_lock>
    ret
    1048:	00008067          	ret

0000104c <init>:
#endif

init:
	la sp, _sp
    104c:	00002117          	auipc	sp,0x2
    1050:	2a410113          	addi	sp,sp,676 # 32f0 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1054:	00001517          	auipc	a0,0x1
    1058:	eb050513          	addi	a0,a0,-336 # 1f04 <_data>
	la a1, _data
    105c:	00001597          	auipc	a1,0x1
    1060:	ea858593          	addi	a1,a1,-344 # 1f04 <_data>
	la a2, _edata
    1064:	00001617          	auipc	a2,0x1
    1068:	27860613          	addi	a2,a2,632 # 22dc <__bss_start>
	bgeu a1, a2, 2f
    106c:	00c5fc63          	bgeu	a1,a2,1084 <init+0x38>
1:
	lw t0, (a0)
    1070:	00052283          	lw	t0,0(a0)
	sw t0, (a1)
    1074:	0055a023          	sw	t0,0(a1)
	addi a0, a0, 4
    1078:	00450513          	addi	a0,a0,4
	addi a1, a1, 4
    107c:	00458593          	addi	a1,a1,4
	bltu a1, a2, 1b
    1080:	fec5e8e3          	bltu	a1,a2,1070 <init+0x24>
2:

	/* Clear bss section */
	la a0, __bss_start
    1084:	00001517          	auipc	a0,0x1
    1088:	25850513          	addi	a0,a0,600 # 22dc <__bss_start>
	la a1, _end
    108c:	00001597          	auipc	a1,0x1
    1090:	25c58593          	addi	a1,a1,604 # 22e8 <_end>
	bgeu a0, a1, 2f
    1094:	00b57863          	bgeu	a0,a1,10a4 <init+0x58>
1:
	sw zero, (a0)
    1098:	00052023          	sw	zero,0(a0)
	addi a0, a0, 4
    109c:	00450513          	addi	a0,a0,4
	bltu a0, a1, 1b
    10a0:	feb56ce3          	bltu	a0,a1,1098 <init+0x4c>
2:

#ifndef NO_LIBC_INIT_ARRAY
	call __libc_init_array
    10a4:	010000ef          	jal	10b4 <__libc_init_array>
#endif

	call main
    10a8:	0a0000ef          	jal	1148 <main>

000010ac <mainDone>:
mainDone:
    j mainDone
    10ac:	0000006f          	j	10ac <mainDone>

000010b0 <_init>:


	.globl _init
_init:
    ret
    10b0:	00008067          	ret

Disassembly of section .text:

000010b4 <__libc_init_array>:
    10b4:	ff010113          	addi	sp,sp,-16
    10b8:	00812423          	sw	s0,8(sp)
    10bc:	01212023          	sw	s2,0(sp)
    10c0:	00001797          	auipc	a5,0x1
    10c4:	e4478793          	addi	a5,a5,-444 # 1f04 <_data>
    10c8:	00001417          	auipc	s0,0x1
    10cc:	e3c40413          	addi	s0,s0,-452 # 1f04 <_data>
    10d0:	00112623          	sw	ra,12(sp)
    10d4:	00912223          	sw	s1,4(sp)
    10d8:	40878933          	sub	s2,a5,s0
    10dc:	02878063          	beq	a5,s0,10fc <__libc_init_array+0x48>
    10e0:	40295913          	srai	s2,s2,0x2
    10e4:	00000493          	li	s1,0
    10e8:	00042783          	lw	a5,0(s0)
    10ec:	00148493          	addi	s1,s1,1
    10f0:	00440413          	addi	s0,s0,4
    10f4:	000780e7          	jalr	a5
    10f8:	ff24e8e3          	bltu	s1,s2,10e8 <__libc_init_array+0x34>
    10fc:	00001797          	auipc	a5,0x1
    1100:	e0878793          	addi	a5,a5,-504 # 1f04 <_data>
    1104:	00001417          	auipc	s0,0x1
    1108:	e0040413          	addi	s0,s0,-512 # 1f04 <_data>
    110c:	40878933          	sub	s2,a5,s0
    1110:	40295913          	srai	s2,s2,0x2
    1114:	00878e63          	beq	a5,s0,1130 <__libc_init_array+0x7c>
    1118:	00000493          	li	s1,0
    111c:	00042783          	lw	a5,0(s0)
    1120:	00148493          	addi	s1,s1,1
    1124:	00440413          	addi	s0,s0,4
    1128:	000780e7          	jalr	a5
    112c:	ff24e8e3          	bltu	s1,s2,111c <__libc_init_array+0x68>
    1130:	00c12083          	lw	ra,12(sp)
    1134:	00812403          	lw	s0,8(sp)
    1138:	00412483          	lw	s1,4(sp)
    113c:	00012903          	lw	s2,0(sp)
    1140:	01010113          	addi	sp,sp,16
    1144:	00008067          	ret

00001148 <main>:
    return 1;
}

/* ------------------------------------------------------------------ */
void main(void)
{
    1148:	f9010113          	addi	sp,sp,-112
    114c:	06112623          	sw	ra,108(sp)
    1150:	06812423          	sw	s0,104(sp)
    1154:	06912223          	sw	s1,100(sp)
    1158:	07212023          	sw	s2,96(sp)
    115c:	05312e23          	sw	s3,92(sp)
    1160:	05412c23          	sw	s4,88(sp)
    1164:	05512a23          	sw	s5,84(sp)
    1168:	05612823          	sw	s6,80(sp)
    116c:	05712623          	sw	s7,76(sp)
    1170:	05812423          	sw	s8,72(sp)
    1174:	05912223          	sw	s9,68(sp)
    1178:	05a12023          	sw	s10,64(sp)
    117c:	03b12e23          	sw	s11,60(sp)
    uint32_t probe_cyc, words, est_ticks, i, guard;
    uint64_t t0, t_prev, ta, tb;
    int throttle, ok;
    volatile uint32_t sink;

    bsp_printf("\r\n*** 2DRA: CPU writes DDR framebuffer -> HDMI scanout (v4) ***\r\n");
    1180:	00002537          	lui	a0,0x2
    1184:	fa050513          	addi	a0,a0,-96 # 1fa0 <_data+0x9c>
    1188:	44d000ef          	jal	1dd4 <bsp_printf>
    bsp_printf("FB0=0x%x FB1=0x%x %dx%d RGB565 stride=%d bytes=%d\r\n",
    118c:	000fd837          	lui	a6,0xfd
    1190:	20080813          	addi	a6,a6,512 # fd200 <__freertos_irq_stack_top+0xf9f10>
    1194:	78000793          	li	a5,1920
    1198:	21c00713          	li	a4,540
    119c:	3c000693          	li	a3,960
    11a0:	00401637          	lui	a2,0x401
    11a4:	003015b7          	lui	a1,0x301
    11a8:	00002537          	lui	a0,0x2
    11ac:	fe450513          	addi	a0,a0,-28 # 1fe4 <_data+0xe0>
    11b0:	425000ef          	jal	1dd4 <bsp_printf>
               (int)FB_BASE, (int)FB1_BASE,
               FB_WIDTH, FB_HEIGHT, FB_STRIDE, FB_BYTES);

    /* ---- 步骤 1：时间基准自检（换掉 mcycle：读未实现 CSR 会触发异常死机）---- */
    sink = 0;
    11b4:	02012623          	sw	zero,44(sp)
    ta   = tick();
    11b8:	738000ef          	jal	18f0 <tick>
    11bc:	00050413          	mv	s0,a0
    for (i = 0; i < 20000u; i++) sink += i;      /* volatile 累加，防止被优化掉 */
    11c0:	00000793          	li	a5,0
    11c4:	0140006f          	j	11d8 <main+0x90>
    11c8:	02c12703          	lw	a4,44(sp)
    11cc:	00f70733          	add	a4,a4,a5
    11d0:	02e12623          	sw	a4,44(sp)
    11d4:	00178793          	addi	a5,a5,1
    11d8:	00005737          	lui	a4,0x5
    11dc:	e1f70713          	addi	a4,a4,-481 # 4e1f <__freertos_irq_stack_top+0x1b2f>
    11e0:	fef774e3          	bgeu	a4,a5,11c8 <main+0x80>
    tb   = tick();
    11e4:	70c000ef          	jal	18f0 <tick>
    throttle = ((uint32_t)(tb - ta) > 1000u);
    11e8:	408507b3          	sub	a5,a0,s0
    11ec:	00078713          	mv	a4,a5
    11f0:	00f12e23          	sw	a5,28(sp)
    bsp_printf("step1 timebase: CLINT@0x%x mtime, 20000-loop = %d ticks -> %s\r\n",
    11f4:	3e800793          	li	a5,1000
    11f8:	04e7f663          	bgeu	a5,a4,1244 <main+0xfc>
    11fc:	000026b7          	lui	a3,0x2
    1200:	f7868693          	addi	a3,a3,-136 # 1f78 <_data+0x74>
    1204:	01c12603          	lw	a2,28(sp)
    1208:	f8b005b7          	lui	a1,0xf8b00
    120c:	00002537          	lui	a0,0x2
    1210:	01850513          	addi	a0,a0,24 # 2018 <_data+0x114>
    1214:	3c1000ef          	jal	1dd4 <bsp_printf>
               (int)BSP_CLINT, (int)(uint32_t)(tb - ta),
               throttle ? "OK" : "BAD(use delay loop)");

    /* ---- 步骤 2：一致性自检（CPU 写 → 挤出 D$ → 回读）---- */
    ok = coherency_check();
    1218:	339000ef          	jal	1d50 <coherency_check>
    bsp_printf("step2 coherency check: %s\r\n", ok ? "PASS" : "FAIL");
    121c:	02050a63          	beqz	a0,1250 <main+0x108>
    1220:	000025b7          	lui	a1,0x2
    1224:	f9058593          	addi	a1,a1,-112 # 1f90 <_data+0x8c>
    1228:	00002537          	lui	a0,0x2
    122c:	05850513          	addi	a0,a0,88 # 2058 <_data+0x154>
    1230:	3a5000ef          	jal	1dd4 <bsp_printf>

    /* ---- 步骤 3：实测单次 32bit 写 DDR 的开销（用 FB1，不影响画面）---- */
    ta = tick();
    1234:	6bc000ef          	jal	18f0 <tick>
    1238:	00050413          	mv	s0,a0
    for (i = 0; i < 4096u; i++)
    123c:	00000793          	li	a5,0
    1240:	0380006f          	j	1278 <main+0x130>
    bsp_printf("step1 timebase: CLINT@0x%x mtime, 20000-loop = %d ticks -> %s\r\n",
    1244:	000026b7          	lui	a3,0x2
    1248:	f7c68693          	addi	a3,a3,-132 # 1f7c <_data+0x78>
    124c:	fb9ff06f          	j	1204 <main+0xbc>
    bsp_printf("step2 coherency check: %s\r\n", ok ? "PASS" : "FAIL");
    1250:	000025b7          	lui	a1,0x2
    1254:	f9858593          	addi	a1,a1,-104 # 1f98 <_data+0x94>
    1258:	fd1ff06f          	j	1228 <main+0xe0>
        ((volatile uint32_t *)FB1_BASE)[i] = 0x12340000UL + i;
    125c:	00279693          	slli	a3,a5,0x2
    1260:	00401737          	lui	a4,0x401
    1264:	00d70733          	add	a4,a4,a3
    1268:	123406b7          	lui	a3,0x12340
    126c:	00d786b3          	add	a3,a5,a3
    1270:	00d72023          	sw	a3,0(a4) # 401000 <__freertos_irq_stack_top+0x3fdd10>
    for (i = 0; i < 4096u; i++)
    1274:	00178793          	addi	a5,a5,1
    1278:	00001737          	lui	a4,0x1
    127c:	fee7e0e3          	bltu	a5,a4,125c <main+0x114>
    tb = tick();
    1280:	670000ef          	jal	18f0 <tick>
    probe_cyc = (uint32_t)(tb - ta);
    1284:	408505b3          	sub	a1,a0,s0
    bsp_printf("step3 write probe: 4096 words in %d ticks = %d ticks/word\r\n",
               (int)probe_cyc, (int)(probe_cyc / 4096u));
    1288:	00c5d413          	srli	s0,a1,0xc
    bsp_printf("step3 write probe: 4096 words in %d ticks = %d ticks/word\r\n",
    128c:	00040613          	mv	a2,s0
    1290:	00002537          	lui	a0,0x2
    1294:	07450513          	addi	a0,a0,116 # 2074 <_data+0x170>
    1298:	33d000ef          	jal	1dd4 <bsp_printf>

    /* 每帧写次数预算：两个方块各"擦一次+画一次" + 冲刷缓冲 */
    words     = ((uint32_t)(BOX_W * BOX_H) / 2u + (uint32_t)(BOX2_W * BOX2_H) / 2u) * 2u
                + FLUSH_WORDS;
    est_ticks = words * (probe_cyc / 4096u);
    129c:	00841613          	slli	a2,s0,0x8
    12a0:	00860633          	add	a2,a2,s0
    12a4:	00661613          	slli	a2,a2,0x6
    bsp_printf("step3 budget: %d words/frame -> est %d ticks/frame (~%d fps)\r\n",
    12a8:	00060a63          	beqz	a2,12bc <main+0x174>
               (int)words, (int)est_ticks,
               (est_ticks ? (int)(TICK_HZ / est_ticks) : 0));
    12ac:	05f5e7b7          	lui	a5,0x5f5e
    12b0:	10078793          	addi	a5,a5,256 # 5f5e100 <__freertos_irq_stack_top+0x5f5ae10>
    12b4:	02c7d6b3          	divu	a3,a5,a2
    12b8:	0080006f          	j	12c0 <main+0x178>
    bsp_printf("step3 budget: %d words/frame -> est %d ticks/frame (~%d fps)\r\n",
    12bc:	00000693          	li	a3,0
    12c0:	000045b7          	lui	a1,0x4
    12c4:	04058593          	addi	a1,a1,64 # 4040 <__freertos_irq_stack_top+0xd50>
    12c8:	00002537          	lui	a0,0x2
    12cc:	0b050513          	addi	a0,a0,176 # 20b0 <_data+0x1ac>
    12d0:	305000ef          	jal	1dd4 <bsp_printf>

    /* ---- 步骤 4：静态画面（彩条 + 白边框 + 固定红块），并计时 ---- */
    ta = tick();
    12d4:	61c000ef          	jal	18f0 <tick>
    12d8:	00050413          	mv	s0,a0
    draw_bars();
    12dc:	11d000ef          	jal	1bf8 <draw_bars>
    tb = tick();
    12e0:	610000ef          	jal	18f0 <tick>
    bsp_printf("step4 bars: %d words in %d ticks (%d ticks/word avg)\r\n",
               (int)FB_WORDS, (int)(uint32_t)(tb - ta),
    12e4:	40850633          	sub	a2,a0,s0
               (int)((uint32_t)(tb - ta) / FB_WORDS));
    12e8:	0003f5b7          	lui	a1,0x3f
    12ec:	48058593          	addi	a1,a1,1152 # 3f480 <__freertos_irq_stack_top+0x3c190>
    bsp_printf("step4 bars: %d words in %d ticks (%d ticks/word avg)\r\n",
    12f0:	02b656b3          	divu	a3,a2,a1
    12f4:	00002537          	lui	a0,0x2
    12f8:	0f050513          	addi	a0,a0,240 # 20f0 <_data+0x1ec>
    12fc:	2d9000ef          	jal	1dd4 <bsp_printf>

    ta = tick();
    1300:	5f0000ef          	jal	18f0 <tick>
    1304:	00050413          	mv	s0,a0
    draw_static_marks();
    1308:	17d000ef          	jal	1c84 <draw_static_marks>
    cache_evict();
    130c:	215000ef          	jal	1d20 <cache_evict>
    tb = tick();
    1310:	5e0000ef          	jal	18f0 <tick>
    bsp_printf("step4 marks+flush done in %d ticks; static pattern on screen\r\n",
    1314:	408505b3          	sub	a1,a0,s0
    1318:	00002537          	lui	a0,0x2
    131c:	12850513          	addi	a0,a0,296 # 2128 <_data+0x224>
    1320:	2b5000ef          	jal	1dd4 <bsp_printf>
               (int)(uint32_t)(tb - ta));

    /* ---- 步骤 5：实时上屏自检（画块→延时→擦除 ×3）----
     * 不经过动画循环，直接验证"运行中的 CPU 写 → 扫描输出立刻可见"。 */
    bsp_printf("step5 blink test: watch the screen for 3 blinks...\r\n");
    1324:	00002537          	lui	a0,0x2
    1328:	16850513          	addi	a0,a0,360 # 2168 <_data+0x264>
    132c:	2a9000ef          	jal	1dd4 <bsp_printf>
    for (i = 0; i < 3u; i++) {
    1330:	00000413          	li	s0,0
    1334:	00200793          	li	a5,2
    1338:	0a87ea63          	bltu	a5,s0,13ec <main+0x2a4>
        fill_rect(400, 240, 160, 120, C_MAGENTA);
    133c:	00010737          	lui	a4,0x10
    1340:	81f70713          	addi	a4,a4,-2017 # f81f <__freertos_irq_stack_top+0xc52f>
    1344:	07800693          	li	a3,120
    1348:	0a000613          	li	a2,160
    134c:	0f000593          	li	a1,240
    1350:	19000513          	li	a0,400
    1354:	5b8000ef          	jal	190c <fill_rect>
        cache_evict();
    1358:	1c9000ef          	jal	1d20 <cache_evict>
        bsp_printf("  blink %d ON\r\n", (int)(i + 1u));
    135c:	00140413          	addi	s0,s0,1
    1360:	00040493          	mv	s1,s0
    1364:	00040593          	mv	a1,s0
    1368:	00002537          	lui	a0,0x2
    136c:	1a050513          	addi	a0,a0,416 # 21a0 <_data+0x29c>
    1370:	265000ef          	jal	1dd4 <bsp_printf>
        if (throttle) clint_uDelay(500000u, TICK_HZ, BSP_CLINT);
    1374:	3e800793          	li	a5,1000
    1378:	01c12703          	lw	a4,28(sp)
    137c:	04e7ea63          	bltu	a5,a4,13d0 <main+0x288>
        restore_bg(400, 240, 160, 120);
    1380:	07800693          	li	a3,120
    1384:	0a000613          	li	a2,160
    1388:	0f000593          	li	a1,240
    138c:	19000513          	li	a0,400
    1390:	6f8000ef          	jal	1a88 <restore_bg>
        cache_evict();
    1394:	18d000ef          	jal	1d20 <cache_evict>
        bsp_printf("  blink %d OFF\r\n", (int)(i + 1u));
    1398:	00048593          	mv	a1,s1
    139c:	00002537          	lui	a0,0x2
    13a0:	1b050513          	addi	a0,a0,432 # 21b0 <_data+0x2ac>
    13a4:	231000ef          	jal	1dd4 <bsp_printf>
        if (throttle) clint_uDelay(300000u, TICK_HZ, BSP_CLINT);
    13a8:	3e800793          	li	a5,1000
    13ac:	01c12703          	lw	a4,28(sp)
    13b0:	f8e7f2e3          	bgeu	a5,a4,1334 <main+0x1ec>
    13b4:	f8b00637          	lui	a2,0xf8b00
    13b8:	05f5e5b7          	lui	a1,0x5f5e
    13bc:	10058593          	addi	a1,a1,256 # 5f5e100 <__freertos_irq_stack_top+0x5f5ae10>
    13c0:	00049537          	lui	a0,0x49
    13c4:	3e050513          	addi	a0,a0,992 # 493e0 <__freertos_irq_stack_top+0x460f0>
    13c8:	2c4000ef          	jal	168c <clint_uDelay>
    13cc:	f69ff06f          	j	1334 <main+0x1ec>
        if (throttle) clint_uDelay(500000u, TICK_HZ, BSP_CLINT);
    13d0:	f8b00637          	lui	a2,0xf8b00
    13d4:	05f5e5b7          	lui	a1,0x5f5e
    13d8:	10058593          	addi	a1,a1,256 # 5f5e100 <__freertos_irq_stack_top+0x5f5ae10>
    13dc:	0007a537          	lui	a0,0x7a
    13e0:	12050513          	addi	a0,a0,288 # 7a120 <__freertos_irq_stack_top+0x76e30>
    13e4:	2a8000ef          	jal	168c <clint_uDelay>
    13e8:	f99ff06f          	j	1380 <main+0x238>
    }

    /* ---- 步骤 6：动态渲染主循环 ---- */
    bsp_printf("step6 entering main loop\r\n");
    13ec:	00002537          	lui	a0,0x2
    13f0:	1c450513          	addi	a0,a0,452 # 21c4 <_data+0x2c0>
    13f4:	1e1000ef          	jal	1dd4 <bsp_printf>
    t_prev = tick();
    13f8:	4f8000ef          	jal	18f0 <tick>
    13fc:	00a12c23          	sw	a0,24(sp)
    uint32_t frame = 0, draw_cyc, period_cyc;
    1400:	00000a93          	li	s5,0
    int dx2 = -12, dy2 = -8;
    1404:	ff800d93          	li	s11,-8
    1408:	ff400d13          	li	s10,-12
    int x2 = FB_WIDTH - BORDER - BOX2_W, y2 = FB_HEIGHT - BORDER - BOX2_H;
    140c:	1d800993          	li	s3,472
    1410:	37c00913          	li	s2,892
    int dx = 16, dy = 12;
    1414:	00c00c93          	li	s9,12
    1418:	01000c13          	li	s8,16
    int x = BORDER, y = BORDER;
    141c:	00800493          	li	s1,8
    1420:	00800413          	li	s0,8
    1424:	0540006f          	j	1478 <main+0x330>

        /* 5) 前 3 帧 + 每 60 帧打印统计 */
        if (frame <= 3u || (frame % 60u) == 0u) {
            period_cyc = (uint32_t)(tick() - t_prev);
            t_prev = tick();
            bsp_printf("frame=%d box=(%d,%d) small=(%d,%d) draw=%d cyc period=%d cyc (~%d fps)\r\n",
    1428:	00000793          	li	a5,0
    142c:	00f12023          	sw	a5,0(sp)
    1430:	000b8893          	mv	a7,s7
    1434:	000b0813          	mv	a6,s6
    1438:	00098793          	mv	a5,s3
    143c:	00090713          	mv	a4,s2
    1440:	00048693          	mv	a3,s1
    1444:	00040613          	mv	a2,s0
    1448:	00002537          	lui	a0,0x2
    144c:	1e050513          	addi	a0,a0,480 # 21e0 <_data+0x2dc>
    1450:	185000ef          	jal	1dd4 <bsp_printf>
                       (int)draw_cyc, (int)period_cyc,
                       (period_cyc ? (int)(TICK_HZ / period_cyc) : 0));
        }

        /* 6) 按固定周期节流（≈60fps）；带次数上限，时间基准异常也不卡死 */
        if (throttle) {
    1454:	3e800793          	li	a5,1000
    1458:	01c12703          	lw	a4,28(sp)
    145c:	18e7f463          	bgeu	a5,a4,15e4 <main+0x49c>
            guard = 0;
    1460:	00000b13          	li	s6,0
            while ((uint32_t)(tick() - t0) < FRAME_TICKS) {
    1464:	48c000ef          	jal	18f0 <tick>
    1468:	41450533          	sub	a0,a0,s4
    146c:	001977b7          	lui	a5,0x197
    1470:	e6978793          	addi	a5,a5,-407 # 196e69 <__freertos_irq_stack_top+0x193b79>
    1474:	14a7fe63          	bgeu	a5,a0,15d0 <main+0x488>
        t0 = tick();
    1478:	478000ef          	jal	18f0 <tick>
    147c:	00050a13          	mv	s4,a0
        restore_bg(x,  y,  BOX_W,  BOX_H);
    1480:	05a00693          	li	a3,90
    1484:	07800613          	li	a2,120
    1488:	00048593          	mv	a1,s1
    148c:	00040513          	mv	a0,s0
    1490:	5f8000ef          	jal	1a88 <restore_bg>
        restore_bg(x2, y2, BOX2_W, BOX2_H);
    1494:	03c00693          	li	a3,60
    1498:	03c00613          	li	a2,60
    149c:	00098593          	mv	a1,s3
    14a0:	00090513          	mv	a0,s2
    14a4:	5e4000ef          	jal	1a88 <restore_bg>
        x += dx;  y += dy;
    14a8:	01840433          	add	s0,s0,s8
    14ac:	019484b3          	add	s1,s1,s9
        if (x < BORDER) { x = BORDER; dx = -dx; }
    14b0:	00700793          	li	a5,7
    14b4:	0087c663          	blt	a5,s0,14c0 <main+0x378>
    14b8:	41800c33          	neg	s8,s8
    14bc:	00800413          	li	s0,8
        if (y < BORDER) { y = BORDER; dy = -dy; }
    14c0:	00700793          	li	a5,7
    14c4:	0097c663          	blt	a5,s1,14d0 <main+0x388>
    14c8:	41900cb3          	neg	s9,s9
    14cc:	00800493          	li	s1,8
        if (x > FB_WIDTH  - BORDER - BOX_W)  { x = FB_WIDTH  - BORDER - BOX_W;  dx = -dx; }
    14d0:	34000793          	li	a5,832
    14d4:	0087d663          	bge	a5,s0,14e0 <main+0x398>
    14d8:	41800c33          	neg	s8,s8
    14dc:	34000413          	li	s0,832
        if (y > FB_HEIGHT - BORDER - BOX_H)  { y = FB_HEIGHT - BORDER - BOX_H;  dy = -dy; }
    14e0:	1ba00793          	li	a5,442
    14e4:	0097d663          	bge	a5,s1,14f0 <main+0x3a8>
    14e8:	41900cb3          	neg	s9,s9
    14ec:	1ba00493          	li	s1,442
        x2 += dx2; y2 += dy2;
    14f0:	01a90933          	add	s2,s2,s10
    14f4:	01b989b3          	add	s3,s3,s11
        if (x2 < BORDER) { x2 = BORDER; dx2 = -dx2; }
    14f8:	00700793          	li	a5,7
    14fc:	0127c663          	blt	a5,s2,1508 <main+0x3c0>
    1500:	41a00d33          	neg	s10,s10
    1504:	00800913          	li	s2,8
        if (y2 < BORDER) { y2 = BORDER; dy2 = -dy2; }
    1508:	00700793          	li	a5,7
    150c:	0137c663          	blt	a5,s3,1518 <main+0x3d0>
    1510:	41b00db3          	neg	s11,s11
    1514:	00800993          	li	s3,8
        if (x2 > FB_WIDTH  - BORDER - BOX2_W) { x2 = FB_WIDTH  - BORDER - BOX2_W; dx2 = -dx2; }
    1518:	37c00793          	li	a5,892
    151c:	0127d663          	bge	a5,s2,1528 <main+0x3e0>
    1520:	41a00d33          	neg	s10,s10
    1524:	37c00913          	li	s2,892
        if (y2 > FB_HEIGHT - BORDER - BOX2_H) { y2 = FB_HEIGHT - BORDER - BOX2_H; dy2 = -dy2; }
    1528:	1d800793          	li	a5,472
    152c:	0137d663          	bge	a5,s3,1538 <main+0x3f0>
    1530:	41b00db3          	neg	s11,s11
    1534:	1d800993          	li	s3,472
        fill_rect(x,  y,  BOX_W,  BOX_H,  PAL8[frame & 7u]);
    1538:	007af713          	andi	a4,s5,7
    153c:	000027b7          	lui	a5,0x2
    1540:	00171713          	slli	a4,a4,0x1
    1544:	2b078793          	addi	a5,a5,688 # 22b0 <PAL8>
    1548:	00e787b3          	add	a5,a5,a4
    154c:	0007d703          	lhu	a4,0(a5)
    1550:	05a00693          	li	a3,90
    1554:	07800613          	li	a2,120
    1558:	00048593          	mv	a1,s1
    155c:	00040513          	mv	a0,s0
    1560:	3ac000ef          	jal	190c <fill_rect>
        fill_rect(x2, y2, BOX2_W, BOX2_H, C_WHITE);
    1564:	00010737          	lui	a4,0x10
    1568:	fff70713          	addi	a4,a4,-1 # ffff <__freertos_irq_stack_top+0xcd0f>
    156c:	03c00693          	li	a3,60
    1570:	03c00613          	li	a2,60
    1574:	00098593          	mv	a1,s3
    1578:	00090513          	mv	a0,s2
    157c:	390000ef          	jal	190c <fill_rect>
        cache_evict();
    1580:	7a0000ef          	jal	1d20 <cache_evict>
        draw_cyc = (uint32_t)(tick() - t0);
    1584:	36c000ef          	jal	18f0 <tick>
    1588:	41450b33          	sub	s6,a0,s4
        frame++;
    158c:	001a8a93          	addi	s5,s5,1
        if (frame <= 3u || (frame % 60u) == 0u) {
    1590:	00300793          	li	a5,3
    1594:	0157f863          	bgeu	a5,s5,15a4 <main+0x45c>
    1598:	03c00793          	li	a5,60
    159c:	02faf7b3          	remu	a5,s5,a5
    15a0:	ea079ae3          	bnez	a5,1454 <main+0x30c>
            period_cyc = (uint32_t)(tick() - t_prev);
    15a4:	34c000ef          	jal	18f0 <tick>
    15a8:	01812783          	lw	a5,24(sp)
    15ac:	40f50bb3          	sub	s7,a0,a5
            t_prev = tick();
    15b0:	340000ef          	jal	18f0 <tick>
    15b4:	00a12c23          	sw	a0,24(sp)
            bsp_printf("frame=%d box=(%d,%d) small=(%d,%d) draw=%d cyc period=%d cyc (~%d fps)\r\n",
    15b8:	000a8593          	mv	a1,s5
    15bc:	e60b86e3          	beqz	s7,1428 <main+0x2e0>
                       (period_cyc ? (int)(TICK_HZ / period_cyc) : 0));
    15c0:	05f5e7b7          	lui	a5,0x5f5e
    15c4:	10078793          	addi	a5,a5,256 # 5f5e100 <__freertos_irq_stack_top+0x5f5ae10>
    15c8:	0377d7b3          	divu	a5,a5,s7
    15cc:	e61ff06f          	j	142c <main+0x2e4>
                if (++guard > 40000000UL) break;
    15d0:	001b0b13          	addi	s6,s6,1
    15d4:	026267b7          	lui	a5,0x2626
    15d8:	a0078793          	addi	a5,a5,-1536 # 2625a00 <__freertos_irq_stack_top+0x2622710>
    15dc:	e967f4e3          	bgeu	a5,s6,1464 <main+0x31c>
    15e0:	e99ff06f          	j	1478 <main+0x330>
            }
        } else {
            sink = 0;
    15e4:	02012623          	sw	zero,44(sp)
            for (i = 0; i < FRAME_DELAY_LOOPS; i++) sink += i;
    15e8:	00000713          	li	a4,0
    15ec:	0140006f          	j	1600 <main+0x4b8>
    15f0:	02c12783          	lw	a5,44(sp)
    15f4:	00e787b3          	add	a5,a5,a4
    15f8:	02f12623          	sw	a5,44(sp)
    15fc:	00170713          	addi	a4,a4,1
    1600:	0002c7b7          	lui	a5,0x2c
    1604:	f1f78793          	addi	a5,a5,-225 # 2bf1f <__freertos_irq_stack_top+0x28c2f>
    1608:	fee7f4e3          	bgeu	a5,a4,15f0 <main+0x4a8>
    160c:	e6dff06f          	j	1478 <main+0x330>

00001610 <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    1610:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    1614:	01055513          	srli	a0,a0,0x10
    }
    1618:	0ff57513          	zext.b	a0,a0
    161c:	00008067          	ret

00001620 <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    1620:	ff010113          	addi	sp,sp,-16
    1624:	00112623          	sw	ra,12(sp)
    1628:	00812423          	sw	s0,8(sp)
    162c:	00912223          	sw	s1,4(sp)
    1630:	00050413          	mv	s0,a0
    1634:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    1638:	00040513          	mv	a0,s0
    163c:	fd5ff0ef          	jal	1610 <uart_writeAvailability>
    1640:	fe050ce3          	beqz	a0,1638 <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    1644:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    1648:	00c12083          	lw	ra,12(sp)
    164c:	00812403          	lw	s0,8(sp)
    1650:	00412483          	lw	s1,4(sp)
    1654:	01010113          	addi	sp,sp,16
    1658:	00008067          	ret

0000165c <clint_getTime>:
*          to guard against rollover. It checks if the high part remains unchanged
*          during the read operation to ensure consistency. The high and low parts
*          are then combined to form the 64-bit current time value.
*
******************************************************************************/
    static u64 clint_getTime(u32 p){
    165c:	00050693          	mv	a3,a0
    readReg_u32 (clint_getTimeHigh, CLINT_TIME_ADDR+4)
    1660:	0000c7b7          	lui	a5,0xc
    1664:	ffc78793          	addi	a5,a5,-4 # bffc <__freertos_irq_stack_top+0x8d0c>
    1668:	00f687b3          	add	a5,a3,a5
        return *((volatile u32*) address);
    166c:	0007a583          	lw	a1,0(a5)
    readReg_u32 (clint_getTimeLow , CLINT_TIME_ADDR)
    1670:	0000c737          	lui	a4,0xc
    1674:	ff870713          	addi	a4,a4,-8 # bff8 <__freertos_irq_stack_top+0x8d08>
    1678:	00e68733          	add	a4,a3,a4
    167c:	00072503          	lw	a0,0(a4)
    1680:	0007a783          	lw	a5,0(a5)
    
        /* Likewise, must guard against rollover when reading */
        do {
            hi = clint_getTimeHigh(p);
            lo = clint_getTimeLow(p);
        } while (clint_getTimeHigh(p) != hi);
    1684:	fcb79ee3          	bne	a5,a1,1660 <clint_getTime+0x4>
    
        return (((u64)hi) << 32) | lo;
    }
    1688:	00008067          	ret

0000168c <clint_uDelay>:
*          and the time limit is non-negative, indicating that the delay has
*          not yet elapsed.
*
******************************************************************************/
    static void clint_uDelay(u32 usec, u32 hz, u32 reg){
        u32 mTimePerUsec = hz/1000000;
    168c:	000f47b7          	lui	a5,0xf4
    1690:	24078793          	addi	a5,a5,576 # f4240 <__freertos_irq_stack_top+0xf0f50>
    1694:	02f5d5b3          	divu	a1,a1,a5
    readReg_u32 (clint_getTimeLow , CLINT_TIME_ADDR)
    1698:	0000c7b7          	lui	a5,0xc
    169c:	ff878793          	addi	a5,a5,-8 # bff8 <__freertos_irq_stack_top+0x8d08>
    16a0:	00f60633          	add	a2,a2,a5
    16a4:	00062783          	lw	a5,0(a2) # f8b00000 <__freertos_irq_stack_top+0xf8afcd10>
        u32 limit = clint_getTimeLow(reg) + usec*mTimePerUsec;
    16a8:	02a585b3          	mul	a1,a1,a0
    16ac:	00f58733          	add	a4,a1,a5
    16b0:	00062783          	lw	a5,0(a2)
        while((int32_t)(limit-(clint_getTimeLow(reg))) >= 0);
    16b4:	40f707b3          	sub	a5,a4,a5
    16b8:	fe07dce3          	bgez	a5,16b0 <clint_uDelay+0x24>
    16bc:	00008067          	ret

000016c0 <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    16c0:	ff010113          	addi	sp,sp,-16
    16c4:	00112623          	sw	ra,12(sp)
    16c8:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    16cc:	f8010537          	lui	a0,0xf8010
    16d0:	f51ff0ef          	jal	1620 <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    16d4:	00c12083          	lw	ra,12(sp)
    16d8:	01010113          	addi	sp,sp,16
    16dc:	00008067          	ret

000016e0 <_putchar_s>:

    static void _putchar_s(char *p)
    {
    16e0:	ff010113          	addi	sp,sp,-16
    16e4:	00112623          	sw	ra,12(sp)
    16e8:	00812423          	sw	s0,8(sp)
    16ec:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    16f0:	00c0006f          	j	16fc <_putchar_s+0x1c>
            _putchar(*(p++));
    16f4:	00140413          	addi	s0,s0,1
    16f8:	fc9ff0ef          	jal	16c0 <_putchar>
        while (*p)
    16fc:	00044503          	lbu	a0,0(s0)
    1700:	fe051ae3          	bnez	a0,16f4 <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    1704:	00c12083          	lw	ra,12(sp)
    1708:	00812403          	lw	s0,8(sp)
    170c:	01010113          	addi	sp,sp,16
    1710:	00008067          	ret

00001714 <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    1714:	ff010113          	addi	sp,sp,-16
    1718:	00112623          	sw	ra,12(sp)
    171c:	00812423          	sw	s0,8(sp)
    1720:	00912223          	sw	s1,4(sp)
    1724:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1728:	01c00413          	li	s0,28
    172c:	0240006f          	j	1750 <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    1730:	0084d733          	srl	a4,s1,s0
    1734:	00f77713          	andi	a4,a4,15
    1738:	000027b7          	lui	a5,0x2
    173c:	f0478793          	addi	a5,a5,-252 # 1f04 <_data>
    1740:	00e787b3          	add	a5,a5,a4
    1744:	0007c503          	lbu	a0,0(a5)
    1748:	f79ff0ef          	jal	16c0 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    174c:	ffc40413          	addi	s0,s0,-4
    1750:	fe0450e3          	bgez	s0,1730 <bsp_printHex+0x1c>
        }
    }
    1754:	00c12083          	lw	ra,12(sp)
    1758:	00812403          	lw	s0,8(sp)
    175c:	00412483          	lw	s1,4(sp)
    1760:	01010113          	addi	sp,sp,16
    1764:	00008067          	ret

00001768 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    1768:	ff010113          	addi	sp,sp,-16
    176c:	00112623          	sw	ra,12(sp)
    1770:	00812423          	sw	s0,8(sp)
    1774:	00912223          	sw	s1,4(sp)
    1778:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    177c:	01c00413          	li	s0,28
    1780:	0240006f          	j	17a4 <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    1784:	0084d733          	srl	a4,s1,s0
    1788:	00f77713          	andi	a4,a4,15
    178c:	000027b7          	lui	a5,0x2
    1790:	f1878793          	addi	a5,a5,-232 # 1f18 <_data+0x14>
    1794:	00e787b3          	add	a5,a5,a4
    1798:	0007c503          	lbu	a0,0(a5)
    179c:	f25ff0ef          	jal	16c0 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    17a0:	ffc40413          	addi	s0,s0,-4
    17a4:	fe0450e3          	bgez	s0,1784 <bsp_printHex_lower+0x1c>

        }
    }
    17a8:	00c12083          	lw	ra,12(sp)
    17ac:	00812403          	lw	s0,8(sp)
    17b0:	00412483          	lw	s1,4(sp)
    17b4:	01010113          	addi	sp,sp,16
    17b8:	00008067          	ret

000017bc <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    17bc:	ff010113          	addi	sp,sp,-16
    17c0:	00112623          	sw	ra,12(sp)
        _putchar(c);
    17c4:	0ff57513          	zext.b	a0,a0
    17c8:	ef9ff0ef          	jal	16c0 <_putchar>
    }
    17cc:	00c12083          	lw	ra,12(sp)
    17d0:	01010113          	addi	sp,sp,16
    17d4:	00008067          	ret

000017d8 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    17d8:	ff010113          	addi	sp,sp,-16
    17dc:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    17e0:	f01ff0ef          	jal	16e0 <_putchar_s>
    }
    17e4:	00c12083          	lw	ra,12(sp)
    17e8:	01010113          	addi	sp,sp,16
    17ec:	00008067          	ret

000017f0 <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    17f0:	fd010113          	addi	sp,sp,-48
    17f4:	02112623          	sw	ra,44(sp)
    17f8:	02812423          	sw	s0,40(sp)
    17fc:	02912223          	sw	s1,36(sp)
    1800:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    1804:	00054663          	bltz	a0,1810 <bsp_printf_d+0x20>
    {
    1808:	00010413          	mv	s0,sp
    180c:	02c0006f          	j	1838 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    1810:	02d00513          	li	a0,45
    1814:	fa9ff0ef          	jal	17bc <bsp_printf_c>
            val = -val;
    1818:	409004b3          	neg	s1,s1
    181c:	fedff06f          	j	1808 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    1820:	00a00713          	li	a4,10
    1824:	02e4e7b3          	rem	a5,s1,a4
    1828:	03078793          	addi	a5,a5,48
    182c:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    1830:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    1834:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    1838:	fe0494e3          	bnez	s1,1820 <bsp_printf_d+0x30>
    183c:	00010793          	mv	a5,sp
    1840:	fef400e3          	beq	s0,a5,1820 <bsp_printf_d+0x30>
        }
        while (p != buffer)
    1844:	00010793          	mv	a5,sp
    1848:	00f40a63          	beq	s0,a5,185c <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    184c:	fff40413          	addi	s0,s0,-1
    1850:	00044503          	lbu	a0,0(s0)
    1854:	f69ff0ef          	jal	17bc <bsp_printf_c>
    1858:	fedff06f          	j	1844 <bsp_printf_d+0x54>
    }
    185c:	02c12083          	lw	ra,44(sp)
    1860:	02812403          	lw	s0,40(sp)
    1864:	02412483          	lw	s1,36(sp)
    1868:	03010113          	addi	sp,sp,48
    186c:	00008067          	ret

00001870 <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    1870:	ff010113          	addi	sp,sp,-16
    1874:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    1878:	00000713          	li	a4,0
    187c:	00700793          	li	a5,7
    1880:	02e7c063          	blt	a5,a4,18a0 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    1884:	00271693          	slli	a3,a4,0x2
    1888:	ff000793          	li	a5,-16
    188c:	00d797b3          	sll	a5,a5,a3
    1890:	00f577b3          	and	a5,a0,a5
    1894:	00078663          	beqz	a5,18a0 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    1898:	00170713          	addi	a4,a4,1
    189c:	fe1ff06f          	j	187c <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    18a0:	ec9ff0ef          	jal	1768 <bsp_printHex_lower>
    }
    18a4:	00c12083          	lw	ra,12(sp)
    18a8:	01010113          	addi	sp,sp,16
    18ac:	00008067          	ret

000018b0 <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    18b0:	ff010113          	addi	sp,sp,-16
    18b4:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    18b8:	00000713          	li	a4,0
    18bc:	00700793          	li	a5,7
    18c0:	02e7c063          	blt	a5,a4,18e0 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    18c4:	00271693          	slli	a3,a4,0x2
    18c8:	ff000793          	li	a5,-16
    18cc:	00d797b3          	sll	a5,a5,a3
    18d0:	00f577b3          	and	a5,a0,a5
    18d4:	00078663          	beqz	a5,18e0 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    18d8:	00170713          	addi	a4,a4,1
    18dc:	fe1ff06f          	j	18bc <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    18e0:	e35ff0ef          	jal	1714 <bsp_printHex>
        }
    18e4:	00c12083          	lw	ra,12(sp)
    18e8:	01010113          	addi	sp,sp,16
    18ec:	00008067          	ret

000018f0 <tick>:
{
    18f0:	ff010113          	addi	sp,sp,-16
    18f4:	00112623          	sw	ra,12(sp)
    return clint_getTime(BSP_CLINT);
    18f8:	f8b00537          	lui	a0,0xf8b00
    18fc:	d61ff0ef          	jal	165c <clint_getTime>
}
    1900:	00c12083          	lw	ra,12(sp)
    1904:	01010113          	addi	sp,sp,16
    1908:	00008067          	ret

0000190c <fill_rect>:
    uint32_t v = ((uint32_t)color << 16) | (uint32_t)color;
    190c:	01071e93          	slli	t4,a4,0x10
    1910:	00ee8eb3          	add	t4,t4,a4
    if (w <= 0 || h <= 0) return;
    1914:	0ec05463          	blez	a2,19fc <fill_rect+0xf0>
    1918:	0ed05263          	blez	a3,19fc <fill_rect+0xf0>
    if (x < 0) { w += x; x = 0; }
    191c:	04054063          	bltz	a0,195c <fill_rect+0x50>
    if (y < 0) { h += y; y = 0; }
    1920:	0405c463          	bltz	a1,1968 <fill_rect+0x5c>
    if (x + w > FB_WIDTH)  w = FB_WIDTH  - x;
    1924:	00c507b3          	add	a5,a0,a2
    1928:	3c000813          	li	a6,960
    192c:	00f85663          	bge	a6,a5,1938 <fill_rect+0x2c>
    1930:	3c000613          	li	a2,960
    1934:	40a60633          	sub	a2,a2,a0
    if (y + h > FB_HEIGHT) h = FB_HEIGHT - y;
    1938:	00d587b3          	add	a5,a1,a3
    193c:	21c00813          	li	a6,540
    1940:	00f85663          	bge	a6,a5,194c <fill_rect+0x40>
    1944:	21c00693          	li	a3,540
    1948:	40b686b3          	sub	a3,a3,a1
    if (w <= 0 || h <= 0) return;
    194c:	0ac05863          	blez	a2,19fc <fill_rect+0xf0>
    1950:	0ad05663          	blez	a3,19fc <fill_rect+0xf0>
    for (j = 0; j < h; j++) {
    1954:	00000f13          	li	t5,0
    1958:	06c0006f          	j	19c4 <fill_rect+0xb8>
    if (x < 0) { w += x; x = 0; }
    195c:	00a60633          	add	a2,a2,a0
    1960:	00000513          	li	a0,0
    1964:	fbdff06f          	j	1920 <fill_rect+0x14>
    if (y < 0) { h += y; y = 0; }
    1968:	00b686b3          	add	a3,a3,a1
    196c:	00000593          	li	a1,0
    1970:	fb5ff06f          	j	1924 <fill_rect+0x18>
        for (i = 0; i < n; i++) row[i] = v;
    1974:	00f308b3          	add	a7,t1,a5
    1978:	00289893          	slli	a7,a7,0x2
    197c:	00301837          	lui	a6,0x301
    1980:	01180833          	add	a6,a6,a7
    1984:	01d82023          	sw	t4,0(a6) # 301000 <__freertos_irq_stack_top+0x2fdd10>
    1988:	00178793          	addi	a5,a5,1
    198c:	ffc7c4e3          	blt	a5,t3,1974 <fill_rect+0x68>
        if (w & 1)
    1990:	00167793          	andi	a5,a2,1
    1994:	02078663          	beqz	a5,19c0 <fill_rect+0xb4>
            FB16[(uint32_t)(y + j) * FB_WIDTH + x + w - 1] = color;
    1998:	004f9793          	slli	a5,t6,0x4
    199c:	41f787b3          	sub	a5,a5,t6
    19a0:	00679793          	slli	a5,a5,0x6
    19a4:	00f507b3          	add	a5,a0,a5
    19a8:	00f607b3          	add	a5,a2,a5
    19ac:	00179793          	slli	a5,a5,0x1
    19b0:	00301837          	lui	a6,0x301
    19b4:	ffe80813          	addi	a6,a6,-2 # 300ffe <__freertos_irq_stack_top+0x2fdd0e>
    19b8:	010787b3          	add	a5,a5,a6
    19bc:	00e79023          	sh	a4,0(a5)
    for (j = 0; j < h; j++) {
    19c0:	001f0f13          	addi	t5,t5,1
    19c4:	02df5c63          	bge	t5,a3,19fc <fill_rect+0xf0>
        volatile uint32_t *row = FB32 + (uint32_t)(y + j) * (FB_WIDTH / 2) + (x / 2);
    19c8:	01e58fb3          	add	t6,a1,t5
    19cc:	01f55793          	srli	a5,a0,0x1f
    19d0:	00a787b3          	add	a5,a5,a0
    19d4:	4017d793          	srai	a5,a5,0x1
    19d8:	004f9313          	slli	t1,t6,0x4
    19dc:	41f30333          	sub	t1,t1,t6
    19e0:	00531313          	slli	t1,t1,0x5
    19e4:	00f30333          	add	t1,t1,a5
        int n = w / 2;
    19e8:	01f65e13          	srli	t3,a2,0x1f
    19ec:	00ce0e33          	add	t3,t3,a2
    19f0:	401e5e13          	srai	t3,t3,0x1
        for (i = 0; i < n; i++) row[i] = v;
    19f4:	00000793          	li	a5,0
    19f8:	f95ff06f          	j	198c <fill_rect+0x80>
}
    19fc:	00008067          	ret

00001a00 <redraw_marks>:
{
    1a00:	00050793          	mv	a5,a0
    1a04:	00058713          	mv	a4,a1
    int sx = (x > MARK_X) ? x : MARK_X;
    1a08:	33400593          	li	a1,820
    1a0c:	00b55463          	bge	a0,a1,1a14 <redraw_marks+0x14>
    1a10:	33400513          	li	a0,820
    int sy = (y > MARK_Y) ? y : MARK_Y;
    1a14:	00070593          	mv	a1,a4
    1a18:	01000813          	li	a6,16
    1a1c:	01075463          	bge	a4,a6,1a24 <redraw_marks+0x24>
    1a20:	01000593          	li	a1,16
    int ex = ((x + w - 1) < (MARK_X + MARK_W - 1)) ? (x + w - 1) : (MARK_X + MARK_W - 1);
    1a24:	00c787b3          	add	a5,a5,a2
    1a28:	3a400613          	li	a2,932
    1a2c:	00f65463          	bge	a2,a5,1a34 <redraw_marks+0x34>
    1a30:	3a400793          	li	a5,932
    1a34:	fff78793          	addi	a5,a5,-1
    int ey = ((y + h - 1) < (MARK_Y + MARK_H - 1)) ? (y + h - 1) : (MARK_Y + MARK_H - 1);
    1a38:	00d70733          	add	a4,a4,a3
    1a3c:	06000693          	li	a3,96
    1a40:	00e6d463          	bge	a3,a4,1a48 <redraw_marks+0x48>
    1a44:	06000713          	li	a4,96
    1a48:	fff70713          	addi	a4,a4,-1
    if (sx > ex || sy > ey) return;
    1a4c:	00a7c463          	blt	a5,a0,1a54 <redraw_marks+0x54>
    1a50:	00b75463          	bge	a4,a1,1a58 <redraw_marks+0x58>
    1a54:	00008067          	ret
{
    1a58:	ff010113          	addi	sp,sp,-16
    1a5c:	00112623          	sw	ra,12(sp)
    fill_rect(sx, sy, ex - sx + 1, ey - sy + 1, C_RED);
    1a60:	40a787b3          	sub	a5,a5,a0
    1a64:	40b706b3          	sub	a3,a4,a1
    1a68:	00010737          	lui	a4,0x10
    1a6c:	80070713          	addi	a4,a4,-2048 # f800 <__freertos_irq_stack_top+0xc510>
    1a70:	00168693          	addi	a3,a3,1 # 12340001 <__freertos_irq_stack_top+0x1233cd11>
    1a74:	00178613          	addi	a2,a5,1
    1a78:	e95ff0ef          	jal	190c <fill_rect>
}
    1a7c:	00c12083          	lw	ra,12(sp)
    1a80:	01010113          	addi	sp,sp,16
    1a84:	00008067          	ret

00001a88 <restore_bg>:
    if (w <= 0 || h <= 0) return;
    1a88:	16c05663          	blez	a2,1bf4 <restore_bg+0x16c>
    1a8c:	16d05463          	blez	a3,1bf4 <restore_bg+0x16c>
    if (x < 0) { w += x; x = 0; }
    1a90:	04054663          	bltz	a0,1adc <restore_bg+0x54>
    if (y < 0) { h += y; y = 0; }
    1a94:	0405ca63          	bltz	a1,1ae8 <restore_bg+0x60>
    if (x + w > FB_WIDTH)  w = FB_WIDTH  - x;
    1a98:	00c507b3          	add	a5,a0,a2
    1a9c:	3c000713          	li	a4,960
    1aa0:	00f75663          	bge	a4,a5,1aac <restore_bg+0x24>
    1aa4:	3c000613          	li	a2,960
    1aa8:	40a60633          	sub	a2,a2,a0
    if (y + h > FB_HEIGHT) h = FB_HEIGHT - y;
    1aac:	00d587b3          	add	a5,a1,a3
    1ab0:	21c00713          	li	a4,540
    1ab4:	00f75663          	bge	a4,a5,1ac0 <restore_bg+0x38>
    1ab8:	21c00693          	li	a3,540
    1abc:	40b686b3          	sub	a3,a3,a1
    if (w <= 0 || h <= 0) return;
    1ac0:	12c05a63          	blez	a2,1bf4 <restore_bg+0x16c>
    1ac4:	12d05863          	blez	a3,1bf4 <restore_bg+0x16c>
{
    1ac8:	ff010113          	addi	sp,sp,-16
    1acc:	00112623          	sw	ra,12(sp)
    1ad0:	00812423          	sw	s0,8(sp)
    for (b = 0; b < 8; b++) {
    1ad4:	00000f93          	li	t6,0
    1ad8:	0240006f          	j	1afc <restore_bg+0x74>
    if (x < 0) { w += x; x = 0; }
    1adc:	00a60633          	add	a2,a2,a0
    1ae0:	00000513          	li	a0,0
    1ae4:	fb1ff06f          	j	1a94 <restore_bg+0xc>
    if (y < 0) { h += y; y = 0; }
    1ae8:	00b686b3          	add	a3,a3,a1
    1aec:	00000593          	li	a1,0
    1af0:	fa9ff06f          	j	1a98 <restore_bg+0x10>
        if (sx > ex) continue;
    1af4:	03e2de63          	bge	t0,t5,1b30 <restore_bg+0xa8>
    for (b = 0; b < 8; b++) {
    1af8:	001f8f93          	addi	t6,t6,1
    1afc:	00700793          	li	a5,7
    1b00:	0ff7c063          	blt	a5,t6,1be0 <restore_bg+0x158>
        int bx0 = b * BAR_COLS;
    1b04:	004f9793          	slli	a5,t6,0x4
    1b08:	41f787b3          	sub	a5,a5,t6
    1b0c:	00379793          	slli	a5,a5,0x3
        int bx1 = bx0 + BAR_COLS - 1;
    1b10:	07778293          	addi	t0,a5,119
        int sx  = (x > bx0) ? x : bx0;
    1b14:	00050f13          	mv	t5,a0
    1b18:	00f55463          	bge	a0,a5,1b20 <restore_bg+0x98>
    1b1c:	00078f13          	mv	t5,a5
        int ex  = ((x + w - 1) < bx1) ? (x + w - 1) : bx1;
    1b20:	00c507b3          	add	a5,a0,a2
    1b24:	fcf2c8e3          	blt	t0,a5,1af4 <restore_bg+0x6c>
    1b28:	fff78293          	addi	t0,a5,-1
    1b2c:	fc9ff06f          	j	1af4 <restore_bg+0x6c>
        c = BARS[b];
    1b30:	000027b7          	lui	a5,0x2
    1b34:	001f9713          	slli	a4,t6,0x1
    1b38:	2c078793          	addi	a5,a5,704 # 22c0 <BARS>
    1b3c:	00e787b3          	add	a5,a5,a4
    1b40:	0007d083          	lhu	ra,0(a5)
        v = ((uint32_t)c << 16) | (uint32_t)c;
    1b44:	01009e13          	slli	t3,ra,0x10
    1b48:	001e0e33          	add	t3,t3,ra
        n = (ex - sx + 1) / 2;
    1b4c:	41e283b3          	sub	t2,t0,t5
    1b50:	00138393          	addi	t2,t2,1
    1b54:	01f3d313          	srli	t1,t2,0x1f
    1b58:	00730333          	add	t1,t1,t2
    1b5c:	40135313          	srai	t1,t1,0x1
        for (j = y; j < y + h; j++) {
    1b60:	00058e93          	mv	t4,a1
    1b64:	04c0006f          	j	1bb0 <restore_bg+0x128>
            for (k = 0; k < n; k++) row[k] = v;
    1b68:	00f88833          	add	a6,a7,a5
    1b6c:	00281813          	slli	a6,a6,0x2
    1b70:	00301737          	lui	a4,0x301
    1b74:	01070733          	add	a4,a4,a6
    1b78:	01c72023          	sw	t3,0(a4) # 301000 <__freertos_irq_stack_top+0x2fdd10>
    1b7c:	00178793          	addi	a5,a5,1
    1b80:	fe67c4e3          	blt	a5,t1,1b68 <restore_bg+0xe0>
            if ((ex - sx + 1) & 1)
    1b84:	0013f793          	andi	a5,t2,1
    1b88:	02078263          	beqz	a5,1bac <restore_bg+0x124>
                FB16[(uint32_t)j * FB_WIDTH + ex] = c;
    1b8c:	00441793          	slli	a5,s0,0x4
    1b90:	408787b3          	sub	a5,a5,s0
    1b94:	00679793          	slli	a5,a5,0x6
    1b98:	00f287b3          	add	a5,t0,a5
    1b9c:	00179793          	slli	a5,a5,0x1
    1ba0:	00301737          	lui	a4,0x301
    1ba4:	00f707b3          	add	a5,a4,a5
    1ba8:	00179023          	sh	ra,0(a5)
        for (j = y; j < y + h; j++) {
    1bac:	001e8e93          	addi	t4,t4,1
    1bb0:	00d587b3          	add	a5,a1,a3
    1bb4:	f4fed2e3          	bge	t4,a5,1af8 <restore_bg+0x70>
            volatile uint32_t *row = FB32 + (uint32_t)j * (FB_WIDTH / 2) + (sx / 2);
    1bb8:	000e8413          	mv	s0,t4
    1bbc:	01ff5793          	srli	a5,t5,0x1f
    1bc0:	01e787b3          	add	a5,a5,t5
    1bc4:	4017d793          	srai	a5,a5,0x1
    1bc8:	004e9893          	slli	a7,t4,0x4
    1bcc:	41d888b3          	sub	a7,a7,t4
    1bd0:	00589893          	slli	a7,a7,0x5
    1bd4:	00f888b3          	add	a7,a7,a5
            for (k = 0; k < n; k++) row[k] = v;
    1bd8:	00000793          	li	a5,0
    1bdc:	fa5ff06f          	j	1b80 <restore_bg+0xf8>
    redraw_marks(x, y, w, h);
    1be0:	e21ff0ef          	jal	1a00 <redraw_marks>
}
    1be4:	00c12083          	lw	ra,12(sp)
    1be8:	00812403          	lw	s0,8(sp)
    1bec:	01010113          	addi	sp,sp,16
    1bf0:	00008067          	ret
    1bf4:	00008067          	ret

00001bf8 <draw_bars>:
    for (y = 0; y < FB_HEIGHT; y++) {
    1bf8:	00000813          	li	a6,0
    1bfc:	0680006f          	j	1c64 <draw_bars+0x6c>
                row[b * (BAR_COLS / 2) + k] = v;
    1c00:	00461713          	slli	a4,a2,0x4
    1c04:	40c70733          	sub	a4,a4,a2
    1c08:	00271793          	slli	a5,a4,0x2
    1c0c:	00d787b3          	add	a5,a5,a3
    1c10:	00279793          	slli	a5,a5,0x2
    1c14:	00f507b3          	add	a5,a0,a5
    1c18:	00301737          	lui	a4,0x301
    1c1c:	00f707b3          	add	a5,a4,a5
    1c20:	00b7a023          	sw	a1,0(a5)
            for (k = 0; k < BAR_COLS / 2; k++)
    1c24:	00168693          	addi	a3,a3,1
    1c28:	03b00793          	li	a5,59
    1c2c:	fcd7dae3          	bge	a5,a3,1c00 <draw_bars+0x8>
        for (b = 0; b < 8; b++) {
    1c30:	00160613          	addi	a2,a2,1
    1c34:	00700793          	li	a5,7
    1c38:	02c7c463          	blt	a5,a2,1c60 <draw_bars+0x68>
            uint32_t v = ((uint32_t)BARS[b] << 16) | (uint32_t)BARS[b];
    1c3c:	000027b7          	lui	a5,0x2
    1c40:	00161713          	slli	a4,a2,0x1
    1c44:	2c078793          	addi	a5,a5,704 # 22c0 <BARS>
    1c48:	00e787b3          	add	a5,a5,a4
    1c4c:	0007d783          	lhu	a5,0(a5)
    1c50:	01079593          	slli	a1,a5,0x10
    1c54:	00f585b3          	add	a1,a1,a5
            for (k = 0; k < BAR_COLS / 2; k++)
    1c58:	00000693          	li	a3,0
    1c5c:	fcdff06f          	j	1c28 <draw_bars+0x30>
    for (y = 0; y < FB_HEIGHT; y++) {
    1c60:	00180813          	addi	a6,a6,1
    1c64:	21b00793          	li	a5,539
    1c68:	0107cc63          	blt	a5,a6,1c80 <draw_bars+0x88>
        volatile uint32_t *row = FB32 + (uint32_t)y * (FB_WIDTH / 2);
    1c6c:	00481793          	slli	a5,a6,0x4
    1c70:	410787b3          	sub	a5,a5,a6
    1c74:	00779513          	slli	a0,a5,0x7
        for (b = 0; b < 8; b++) {
    1c78:	00000613          	li	a2,0
    1c7c:	fb9ff06f          	j	1c34 <draw_bars+0x3c>
}
    1c80:	00008067          	ret

00001c84 <draw_static_marks>:
{
    1c84:	ff010113          	addi	sp,sp,-16
    1c88:	00112623          	sw	ra,12(sp)
    1c8c:	00812423          	sw	s0,8(sp)
    fill_rect(0, 0, FB_WIDTH, BORDER, C_WHITE);                      /* 上边 */
    1c90:	00010437          	lui	s0,0x10
    1c94:	fff40713          	addi	a4,s0,-1 # ffff <__freertos_irq_stack_top+0xcd0f>
    1c98:	00800693          	li	a3,8
    1c9c:	3c000613          	li	a2,960
    1ca0:	00000593          	li	a1,0
    1ca4:	00000513          	li	a0,0
    1ca8:	c65ff0ef          	jal	190c <fill_rect>
    fill_rect(0, FB_HEIGHT - BORDER, FB_WIDTH, BORDER, C_WHITE);     /* 下边 */
    1cac:	fff40713          	addi	a4,s0,-1
    1cb0:	00800693          	li	a3,8
    1cb4:	3c000613          	li	a2,960
    1cb8:	21400593          	li	a1,532
    1cbc:	00000513          	li	a0,0
    1cc0:	c4dff0ef          	jal	190c <fill_rect>
    fill_rect(0, 0, BORDER, FB_HEIGHT, C_WHITE);                     /* 左边 */
    1cc4:	fff40713          	addi	a4,s0,-1
    1cc8:	21c00693          	li	a3,540
    1ccc:	00800613          	li	a2,8
    1cd0:	00000593          	li	a1,0
    1cd4:	00000513          	li	a0,0
    1cd8:	c35ff0ef          	jal	190c <fill_rect>
    fill_rect(FB_WIDTH - BORDER, 0, BORDER, FB_HEIGHT, C_WHITE);     /* 右边 */
    1cdc:	fff40713          	addi	a4,s0,-1
    1ce0:	21c00693          	li	a3,540
    1ce4:	00800613          	li	a2,8
    1ce8:	00000593          	li	a1,0
    1cec:	3b800513          	li	a0,952
    1cf0:	c1dff0ef          	jal	190c <fill_rect>
    fill_rect(MARK_X, MARK_Y, MARK_W, MARK_H, C_RED);                /* 固定红块 */
    1cf4:	00010737          	lui	a4,0x10
    1cf8:	80070713          	addi	a4,a4,-2048 # f800 <__freertos_irq_stack_top+0xc510>
    1cfc:	05000693          	li	a3,80
    1d00:	07000613          	li	a2,112
    1d04:	01000593          	li	a1,16
    1d08:	33400513          	li	a0,820
    1d0c:	c01ff0ef          	jal	190c <fill_rect>
}
    1d10:	00c12083          	lw	ra,12(sp)
    1d14:	00812403          	lw	s0,8(sp)
    1d18:	01010113          	addi	sp,sp,16
    1d1c:	00008067          	ret

00001d20 <cache_evict>:
    for (i = 0; i < FLUSH_WORDS; i++)
    1d20:	00000793          	li	a5,0
    1d24:	0200006f          	j	1d44 <cache_evict+0x24>
        scratch[i] = 0xA5A50000UL + i;
    1d28:	00279693          	slli	a3,a5,0x2
    1d2c:	00501737          	lui	a4,0x501
    1d30:	00d70733          	add	a4,a4,a3
    1d34:	a5a506b7          	lui	a3,0xa5a50
    1d38:	00d786b3          	add	a3,a5,a3
    1d3c:	00d72023          	sw	a3,0(a4) # 501000 <__freertos_irq_stack_top+0x4fdd10>
    for (i = 0; i < FLUSH_WORDS; i++)
    1d40:	00178793          	addi	a5,a5,1
    1d44:	7ff00713          	li	a4,2047
    1d48:	fef770e3          	bgeu	a4,a5,1d28 <cache_evict+0x8>
}
    1d4c:	00008067          	ret

00001d50 <coherency_check>:
{
    1d50:	ff010113          	addi	sp,sp,-16
    1d54:	00112623          	sw	ra,12(sp)
    for (i = 0; i < 256; i++) p[i] = 0x5A5A0000UL + i;
    1d58:	00000793          	li	a5,0
    1d5c:	0200006f          	j	1d7c <coherency_check+0x2c>
    1d60:	00279693          	slli	a3,a5,0x2
    1d64:	00401737          	lui	a4,0x401
    1d68:	00d70733          	add	a4,a4,a3
    1d6c:	5a5a06b7          	lui	a3,0x5a5a0
    1d70:	00d786b3          	add	a3,a5,a3
    1d74:	00d72023          	sw	a3,0(a4) # 401000 <__freertos_irq_stack_top+0x3fdd10>
    1d78:	00178793          	addi	a5,a5,1
    1d7c:	0ff00713          	li	a4,255
    1d80:	fef770e3          	bgeu	a4,a5,1d60 <coherency_check+0x10>
    cache_evict();
    1d84:	f9dff0ef          	jal	1d20 <cache_evict>
    1d88:	0000500f          	.word	0x0000500f
    for (i = 0; i < 256; i++)
    1d8c:	00000793          	li	a5,0
    1d90:	0ff00713          	li	a4,255
    1d94:	02f76463          	bltu	a4,a5,1dbc <coherency_check+0x6c>
        if (p[i] != (0x5A5A0000UL + i)) return 0;
    1d98:	00279693          	slli	a3,a5,0x2
    1d9c:	00401737          	lui	a4,0x401
    1da0:	00d70733          	add	a4,a4,a3
    1da4:	00072683          	lw	a3,0(a4) # 401000 <__freertos_irq_stack_top+0x3fdd10>
    1da8:	5a5a0737          	lui	a4,0x5a5a0
    1dac:	00e78733          	add	a4,a5,a4
    1db0:	00e69a63          	bne	a3,a4,1dc4 <coherency_check+0x74>
    for (i = 0; i < 256; i++)
    1db4:	00178793          	addi	a5,a5,1
    1db8:	fd9ff06f          	j	1d90 <coherency_check+0x40>
    return 1;
    1dbc:	00100513          	li	a0,1
    1dc0:	0080006f          	j	1dc8 <coherency_check+0x78>
        if (p[i] != (0x5A5A0000UL + i)) return 0;
    1dc4:	00000513          	li	a0,0
}
    1dc8:	00c12083          	lw	ra,12(sp)
    1dcc:	01010113          	addi	sp,sp,16
    1dd0:	00008067          	ret

00001dd4 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    1dd4:	fc010113          	addi	sp,sp,-64
    1dd8:	00112e23          	sw	ra,28(sp)
    1ddc:	00812c23          	sw	s0,24(sp)
    1de0:	00912a23          	sw	s1,20(sp)
    1de4:	00050493          	mv	s1,a0
    1de8:	02b12223          	sw	a1,36(sp)
    1dec:	02c12423          	sw	a2,40(sp)
    1df0:	02d12623          	sw	a3,44(sp)
    1df4:	02e12823          	sw	a4,48(sp)
    1df8:	02f12a23          	sw	a5,52(sp)
    1dfc:	03012c23          	sw	a6,56(sp)
    1e00:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    1e04:	02410793          	addi	a5,sp,36
    1e08:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    1e0c:	00000413          	li	s0,0
    1e10:	01c0006f          	j	1e2c <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    1e14:	00c12783          	lw	a5,12(sp)
    1e18:	00478713          	addi	a4,a5,4
    1e1c:	00e12623          	sw	a4,12(sp)
    1e20:	0007a503          	lw	a0,0(a5)
    1e24:	999ff0ef          	jal	17bc <bsp_printf_c>
        for (i = 0; format[i]; i++)
    1e28:	00140413          	addi	s0,s0,1
    1e2c:	008487b3          	add	a5,s1,s0
    1e30:	0007c503          	lbu	a0,0(a5)
    1e34:	0a050e63          	beqz	a0,1ef0 <bsp_printf+0x11c>
            if (format[i] == '%') {
    1e38:	02500793          	li	a5,37
    1e3c:	06f50e63          	beq	a0,a5,1eb8 <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    1e40:	97dff0ef          	jal	17bc <bsp_printf_c>
    1e44:	fe5ff06f          	j	1e28 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    1e48:	00c12783          	lw	a5,12(sp)
    1e4c:	00478713          	addi	a4,a5,4
    1e50:	00e12623          	sw	a4,12(sp)
    1e54:	0007a503          	lw	a0,0(a5)
    1e58:	981ff0ef          	jal	17d8 <bsp_printf_s>
                        break;
    1e5c:	fcdff06f          	j	1e28 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    1e60:	00c12783          	lw	a5,12(sp)
    1e64:	00478713          	addi	a4,a5,4
    1e68:	00e12623          	sw	a4,12(sp)
    1e6c:	0007a503          	lw	a0,0(a5)
    1e70:	981ff0ef          	jal	17f0 <bsp_printf_d>
                        break;
    1e74:	fb5ff06f          	j	1e28 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    1e78:	00c12783          	lw	a5,12(sp)
    1e7c:	00478713          	addi	a4,a5,4
    1e80:	00e12623          	sw	a4,12(sp)
    1e84:	0007a503          	lw	a0,0(a5)
    1e88:	a29ff0ef          	jal	18b0 <bsp_printf_X>
                        break;
    1e8c:	f9dff06f          	j	1e28 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    1e90:	00c12783          	lw	a5,12(sp)
    1e94:	00478713          	addi	a4,a5,4
    1e98:	00e12623          	sw	a4,12(sp)
    1e9c:	0007a503          	lw	a0,0(a5)
    1ea0:	9d1ff0ef          	jal	1870 <bsp_printf_x>
                        break;
    1ea4:	f85ff06f          	j	1e28 <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    1ea8:	00002537          	lui	a0,0x2
    1eac:	f2c50513          	addi	a0,a0,-212 # 1f2c <_data+0x28>
    1eb0:	929ff0ef          	jal	17d8 <bsp_printf_s>
                        break;
    1eb4:	f75ff06f          	j	1e28 <bsp_printf+0x54>
                while (format[++i]) {
    1eb8:	00140413          	addi	s0,s0,1
    1ebc:	008487b3          	add	a5,s1,s0
    1ec0:	0007c783          	lbu	a5,0(a5)
    1ec4:	f60782e3          	beqz	a5,1e28 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    1ec8:	fa878793          	addi	a5,a5,-88
    1ecc:	0ff7f693          	zext.b	a3,a5
    1ed0:	02000713          	li	a4,32
    1ed4:	fed762e3          	bltu	a4,a3,1eb8 <bsp_printf+0xe4>
    1ed8:	00269793          	slli	a5,a3,0x2
    1edc:	00002737          	lui	a4,0x2
    1ee0:	22c70713          	addi	a4,a4,556 # 222c <_data+0x328>
    1ee4:	00e787b3          	add	a5,a5,a4
    1ee8:	0007a783          	lw	a5,0(a5)
    1eec:	00078067          	jr	a5

        va_end(ap);
    }
    1ef0:	01c12083          	lw	ra,28(sp)
    1ef4:	01812403          	lw	s0,24(sp)
    1ef8:	01412483          	lw	s1,20(sp)
    1efc:	04010113          	addi	sp,sp,64
    1f00:	00008067          	ret
