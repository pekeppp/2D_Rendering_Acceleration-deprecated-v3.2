
build/fulltest.elf:     file format elf32-littleriscv


Disassembly of section .init:

00001000 <_start>:

_start:
#ifdef USE_GP
.option push
.option norelax
	la gp, __global_pointer$
    1000:	00009197          	auipc	gp,0x9
    1004:	ec018193          	addi	gp,gp,-320 # 9ec0 <__global_pointer$>

00001008 <init>:
	sw a0, smp_lottery_lock, a1
    ret
#endif

init:
	la sp, _sp
    1008:	0000c117          	auipc	sp,0xc
    100c:	ce810113          	addi	sp,sp,-792 # ccf0 <__freertos_irq_stack_top>

	/* Load data section */
	la a0, _data_lma
    1010:	00006517          	auipc	a0,0x6
    1014:	f4450513          	addi	a0,a0,-188 # 6f54 <_data>
	la a1, _data
    1018:	00006597          	auipc	a1,0x6
    101c:	f3c58593          	addi	a1,a1,-196 # 6f54 <_data>
	la a2, _edata
    1020:	00008617          	auipc	a2,0x8
    1024:	6d460613          	addi	a2,a2,1748 # 96f4 <g_perf_zero>
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
    1040:	00008517          	auipc	a0,0x8
    1044:	6b450513          	addi	a0,a0,1716 # 96f4 <g_perf_zero>
	la a1, _end
    1048:	0000b597          	auipc	a1,0xb
    104c:	ca058593          	addi	a1,a1,-864 # bce8 <_end>
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
    107c:	00006797          	auipc	a5,0x6
    1080:	ed878793          	addi	a5,a5,-296 # 6f54 <_data>
    1084:	00006417          	auipc	s0,0x6
    1088:	ed040413          	addi	s0,s0,-304 # 6f54 <_data>
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
    10b8:	00006797          	auipc	a5,0x6
    10bc:	e9c78793          	addi	a5,a5,-356 # 6f54 <_data>
    10c0:	00006417          	auipc	s0,0x6
    10c4:	e9440413          	addi	s0,s0,-364 # 6f54 <_data>
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
    item(tag, blt_rd(BLT_PERF), g_mis);
}

/* ======================= main ======================= */
int main(void)
{
    1104:	fe010113          	addi	sp,sp,-32
    1108:	00112e23          	sw	ra,28(sp)
    110c:	00812c23          	sw	s0,24(sp)
    1110:	00912a23          	sw	s1,20(sp)
    1114:	01212823          	sw	s2,16(sp)
    1118:	01312623          	sw	s3,12(sp)
    111c:	01412423          	sw	s4,8(sp)
    uint32_t ctrl, st, cnt, sink, dt, perf, got;
    uint64_t ta, tb;
    int idx, rc, ok, dead;

    bsp_init();                               /* UART 115200 8N1（与其它 demo 一致） */
    1120:	6c8000ef          	jal	17e8 <bsp_init>

    /* ---------------- [1] banner ---------------- */
    bsp_printf("\r\n\r\n***** fulltest v2.2 : 2DRA BitBlt end-to-end + 边界 + 多精灵压测(逐条等DONE/批量开关) *****\r\n");
    1124:	00009537          	lui	a0,0x9
    1128:	e2050513          	addi	a0,a0,-480 # 8e20 <_data+0x1ecc>
    112c:	359010ef          	jal	2c84 <bsp_printf>
    bsp_printf("[1] BLT_BASE =0x%x (APB slave0, 引擎寄存器)\r\n", (int)BLT_BASE);
    1130:	f81005b7          	lui	a1,0xf8100
    1134:	00009537          	lui	a0,0x9
    1138:	e9050513          	addi	a0,a0,-368 # 8e90 <_data+0x1f3c>
    113c:	349010ef          	jal	2c84 <bsp_printf>
    bsp_printf("    DDR_BASE =0x%x  FB_BASE=0x%x (HDMI 扫描输出)\r\n",
    1140:	00301637          	lui	a2,0x301
    1144:	000015b7          	lui	a1,0x1
    1148:	00009537          	lui	a0,0x9
    114c:	ec450513          	addi	a0,a0,-316 # 8ec4 <_data+0x1f70>
    1150:	335010ef          	jal	2c84 <bsp_printf>
               (int)DDR_BASE, (int)FB_BASE);
    bsp_printf("    FB1_BASE =0x%x  SPRITE_BASE=0x%x  FLUSH_SCRATCH=0x%x (冲刷 %d 字/%d B)\r\n",
    1154:	000027b7          	lui	a5,0x2
    1158:	00001737          	lui	a4,0x1
    115c:	80070713          	addi	a4,a4,-2048 # 800 <CUSTOM2+0x7a5>
    1160:	005016b7          	lui	a3,0x501
    1164:	00101637          	lui	a2,0x101
    1168:	004015b7          	lui	a1,0x401
    116c:	00009537          	lui	a0,0x9
    1170:	efc50513          	addi	a0,a0,-260 # 8efc <_data+0x1fa8>
    1174:	311010ef          	jal	2c84 <bsp_printf>
               (int)FB1_BASE, (int)SPRITE_BASE, (int)FLUSH_SCRATCH,
               (int)CACHE_EVICT_WORDS, (int)CACHE_EVICT_WORDS * 4);
    bsp_printf("    FB %dx%d RGB565 stride=%d B  size=%d B  FIFO=%d cmds x %d words\r\n",
    1178:	00800813          	li	a6,8
    117c:	10000793          	li	a5,256
    1180:	000fd737          	lui	a4,0xfd
    1184:	20070713          	addi	a4,a4,512 # fd200 <__freertos_irq_stack_top+0xf0510>
    1188:	78000693          	li	a3,1920
    118c:	21c00613          	li	a2,540
    1190:	3c000593          	li	a1,960
    1194:	00009537          	lui	a0,0x9
    1198:	f4c50513          	addi	a0,a0,-180 # 8f4c <_data+0x1ff8>
    119c:	2e9010ef          	jal	2c84 <bsp_printf>
               FB_WIDTH, FB_HEIGHT, FB_STRIDE, FB_BYTES, BLT_CMD_FIFO_DEPTH, BLT_CMD_WORDS);
    bsp_printf("    测试计划: [5]联通性+FIFO突发  [6]A-FILL B-COPY C-KEY D-ALPHA  [7]压测 N=25..800\r\n");
    11a0:	00009537          	lui	a0,0x9
    11a4:	f9450513          	addi	a0,a0,-108 # 8f94 <_data+0x2040>
    11a8:	2dd010ef          	jal	2c84 <bsp_printf>

    /* ---------------- [2] 时间基准自检 ---------------- */
    ta   = tick();
    11ac:	674000ef          	jal	1820 <tick>
    11b0:	00050493          	mv	s1,a0
    sink = busy_loop(20000u);
    11b4:	00005537          	lui	a0,0x5
    11b8:	e2050513          	addi	a0,a0,-480 # 4e20 <tc1+0x7c>
    11bc:	680000ef          	jal	183c <busy_loop>
    11c0:	00050413          	mv	s0,a0
    tb   = tick();
    11c4:	65c000ef          	jal	1820 <tick>
    dt   = (uint32_t)(tb - ta);
    11c8:	409506b3          	sub	a3,a0,s1
    g_tb_ok = (dt != 0u && dt < 100000000UL);
    11cc:	fff68793          	addi	a5,a3,-1 # 500fff <__freertos_irq_stack_top+0x4f430f>
    11d0:	05f5e737          	lui	a4,0x5f5e
    11d4:	0ff70713          	addi	a4,a4,255 # 5f5e0ff <__freertos_irq_stack_top+0x5f5140f>
    11d8:	00e7b7b3          	sltu	a5,a5,a4
    11dc:	80f1aa23          	sw	a5,-2028(gp) # 96d4 <g_tb_ok>
    bsp_printf("[2] timebase: CLINT mtime @0x%x %d Hz, 20000-loop=%d ticks (sink=0x%x) -> %s\r\n",
    11e0:	20078263          	beqz	a5,13e4 <main+0x2e0>
    11e4:	000077b7          	lui	a5,0x7
    11e8:	50c78793          	addi	a5,a5,1292 # 750c <_data+0x5b8>
    11ec:	00040713          	mv	a4,s0
    11f0:	05f5e637          	lui	a2,0x5f5e
    11f4:	10060613          	addi	a2,a2,256 # 5f5e100 <__freertos_irq_stack_top+0x5f51410>
    11f8:	f8b005b7          	lui	a1,0xf8b00
    11fc:	00009537          	lui	a0,0x9
    1200:	ff850513          	addi	a0,a0,-8 # 8ff8 <_data+0x20a4>
    1204:	281010ef          	jal	2c84 <bsp_printf>
               (int)BSP_CLINT, (int)BSP_CLINT_HZ, (int)dt, (int)sink,
               g_tb_ok ? "PASS" : "FAIL(时间基准异常，已关闭帧节流)");
    if (!g_tb_ok) { g_fail++; }
    1208:	8141a783          	lw	a5,-2028(gp) # 96d4 <g_tb_ok>
    120c:	00079863          	bnez	a5,121c <main+0x118>
    1210:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    1214:	00178793          	addi	a5,a5,1
    1218:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>

    /* ---------------- [3] 缓存一致性自检 ---------------- */
    idx = coherency_check();
    121c:	3e0010ef          	jal	25fc <coherency_check>
    if (idx != 0) {
    1220:	1c050863          	beqz	a0,13f0 <main+0x2ec>
        g_fail++;
    1224:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    1228:	00178793          	addi	a5,a5,1
    122c:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>
        bsp_printf("[3] coherency: FAIL at word %d (FB1 回读值与写入值不一致 -> D$ 一致性有问题)\r\n",
    1230:	fff50593          	addi	a1,a0,-1
    1234:	00009537          	lui	a0,0x9
    1238:	04850513          	addi	a0,a0,72 # 9048 <_data+0x20f4>
    123c:	249010ef          	jal	2c84 <bsp_printf>
    } else {
        bsp_printf("[3] coherency: PASS (FB1 写 256 字 -> cache_evict -> invalidate -> 回读比对)\r\n");
    }

    /* ---------------- [4] 引擎寄存器探测 + blt_init ---------------- */
    ctrl = blt_rd(BLT_CTRL);
    1240:	00000513          	li	a0,0
    1244:	648000ef          	jal	188c <blt_rd>
    1248:	00050413          	mv	s0,a0
    st   = blt_rd(BLT_STATUS);
    124c:	00400513          	li	a0,4
    1250:	63c000ef          	jal	188c <blt_rd>
    1254:	00050493          	mv	s1,a0
    cnt  = blt_rd(BLT_CMD_FIFO_COUNT);
    1258:	00c00513          	li	a0,12
    125c:	630000ef          	jal	188c <blt_rd>
    1260:	00050913          	mv	s2,a0
    bsp_printf("[4] reg probe: CTRL=0x%x STATUS=0x%x CMD_FIFO_COUNT=%d IRQ_STATUS=0x%x DBG=0x%x PERF=%d\r\n",
               (int)ctrl, (int)st, (int)cnt, (int)blt_rd(BLT_IRQ_STATUS),
    1264:	01000513          	li	a0,16
    1268:	624000ef          	jal	188c <blt_rd>
    126c:	00050993          	mv	s3,a0
               (int)blt_rd(BLT_DBG_CUR_CMD), (int)blt_rd(BLT_PERF));
    1270:	01800513          	li	a0,24
    1274:	618000ef          	jal	188c <blt_rd>
    1278:	00050a13          	mv	s4,a0
    127c:	01c00513          	li	a0,28
    1280:	60c000ef          	jal	188c <blt_rd>
    bsp_printf("[4] reg probe: CTRL=0x%x STATUS=0x%x CMD_FIFO_COUNT=%d IRQ_STATUS=0x%x DBG=0x%x PERF=%d\r\n",
    1284:	00050813          	mv	a6,a0
    1288:	000a0793          	mv	a5,s4
    128c:	00098713          	mv	a4,s3
    1290:	00090693          	mv	a3,s2
    1294:	00048613          	mv	a2,s1
    1298:	00040593          	mv	a1,s0
    129c:	00009537          	lui	a0,0x9
    12a0:	10050513          	addi	a0,a0,256 # 9100 <_data+0x21ac>
    12a4:	1e1010ef          	jal	2c84 <bsp_printf>

    dead = (ctrl == 0xFFFFFFFFUL) || (st == 0xFFFFFFFFUL) || (cnt == 0xFFFFFFFFUL) ||
    12a8:	fff00793          	li	a5,-1
    12ac:	00f40a63          	beq	s0,a5,12c0 <main+0x1bc>
    12b0:	00f48863          	beq	s1,a5,12c0 <main+0x1bc>
    12b4:	00f90663          	beq	s2,a5,12c0 <main+0x1bc>
           (ctrl == 0UL && st == 0UL);
    12b8:	00946433          	or	s0,s0,s1
    dead = (ctrl == 0xFFFFFFFFUL) || (st == 0xFFFFFFFFUL) || (cnt == 0xFFFFFFFFUL) ||
    12bc:	14041263          	bnez	s0,1400 <main+0x2fc>
    if (dead) {
        g_blt_alive = 0;
    12c0:	8001ac23          	sw	zero,-2024(gp) # 96d8 <g_blt_alive>
        g_fail++;
    12c4:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    12c8:	00178793          	addi	a5,a5,1
    12cc:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>
        bsp_printf("    警告：读数是全 F / 全 0 -> APB 窗口 0x%x 可能未接通！\r\n", (int)BLT_BASE);
    12d0:	f81005b7          	lui	a1,0xf8100
    12d4:	00009537          	lui	a0,0x9
    12d8:	21450513          	addi	a0,a0,532 # 9214 <_data+0x22c0>
    12dc:	1a9010ef          	jal	2c84 <bsp_printf>
        bsp_printf("    (排查：bitstream 是否已加载、APB slave0 地址译码、BLT_BASE 是否与 soc.h 一致)\r\n");
    12e0:	00009537          	lui	a0,0x9
    12e4:	26050513          	addi	a0,a0,608 # 9260 <_data+0x230c>
    12e8:	19d010ef          	jal	2c84 <bsp_printf>
        bsp_printf("    跳过 blt_init() 与后续全部引擎测试\r\n");
    12ec:	00009537          	lui	a0,0x9
    12f0:	2c850513          	addi	a0,a0,712 # 92c8 <_data+0x2374>
    12f4:	191010ef          	jal	2c84 <bsp_printf>
        bsp_printf("    blt_init(): SOFT_RST->0->清 IRQ->CTRL.GO 写一次; 现在 CTRL=0x%x STATUS=0x%x\r\n",
                   (int)blt_rd(BLT_CTRL), (int)blt_rd(BLT_STATUS));
    }

    /* ---------------- [5] 寄存器/指令联通性 ---------------- */
    bsp_printf("\r\n---------- [5] 联通性 + 指令 FIFO 背压 ----------\r\n");
    12f8:	00009537          	lui	a0,0x9
    12fc:	2fc50513          	addi	a0,a0,764 # 92fc <_data+0x23a8>
    1300:	185010ef          	jal	2c84 <bsp_printf>
    if (g_blt_alive) {
    1304:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    1308:	18078e63          	beqz	a5,14a4 <main+0x3a0>
        bsp_printf("  [5a] FILL %dx%d color=0x%x -> SPRITE+0xA000 (0x%x)\r\n",
    130c:	0010b737          	lui	a4,0x10b
    1310:	000106b7          	lui	a3,0x10
    1314:	80068693          	addi	a3,a3,-2048 # f800 <__freertos_irq_stack_top+0x2b10>
    1318:	00800613          	li	a2,8
    131c:	01000593          	li	a1,16
    1320:	00009537          	lui	a0,0x9
    1324:	33c50513          	addi	a0,a0,828 # 933c <_data+0x23e8>
    1328:	15d010ef          	jal	2c84 <bsp_printf>
                   LINK_W, LINK_H, (int)LINK_COLOR, (int)SA_LINK);
        rc   = blt_fill(SA_LINK, 32u, LINK_W, LINK_H, LINK_COLOR);
    132c:	00010737          	lui	a4,0x10
    1330:	80070713          	addi	a4,a4,-2048 # f800 <__freertos_irq_stack_top+0x2b10>
    1334:	00800693          	li	a3,8
    1338:	01000613          	li	a2,16
    133c:	02000593          	li	a1,32
    1340:	0010b537          	lui	a0,0x10b
    1344:	16c010ef          	jal	24b0 <blt_fill>
        perf = g_perf;
    1348:	8701a483          	lw	s1,-1936(gp) # 9730 <g_perf>
        if (rc == 0) {
    134c:	10051663          	bnez	a0,1458 <main+0x354>
            cache_invalidate();
    1350:	670000ef          	jal	19c0 <cache_invalidate>
            got = rd16(SA_LINK);
    1354:	0010b537          	lui	a0,0x10b
    1358:	51c000ef          	jal	1874 <rd16>
    135c:	00050413          	mv	s0,a0
            ok  = (got == LINK_COLOR);
            bsp_printf("      STATUS=0x%x CMD_FIFO_COUNT=%d DBG_CUR_CMD=0x%x(期望 op=FILL=0x%x) PERF=%d cycles\r\n",
                       (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT),
    1360:	00400513          	li	a0,4
    1364:	528000ef          	jal	188c <blt_rd>
    1368:	00050913          	mv	s2,a0
    136c:	00c00513          	li	a0,12
    1370:	51c000ef          	jal	188c <blt_rd>
    1374:	00050993          	mv	s3,a0
                       (int)blt_rd(BLT_DBG_CUR_CMD), (int)BLT_OP_FILL, (int)perf);
    1378:	01800513          	li	a0,24
    137c:	510000ef          	jal	188c <blt_rd>
    1380:	00050693          	mv	a3,a0
            bsp_printf("      STATUS=0x%x CMD_FIFO_COUNT=%d DBG_CUR_CMD=0x%x(期望 op=FILL=0x%x) PERF=%d cycles\r\n",
    1384:	00048793          	mv	a5,s1
    1388:	00100713          	li	a4,1
    138c:	00098613          	mv	a2,s3
    1390:	00090593          	mv	a1,s2
    1394:	00009537          	lui	a0,0x9
    1398:	37450513          	addi	a0,a0,884 # 9374 <_data+0x2420>
    139c:	0e9010ef          	jal	2c84 <bsp_printf>
            item("5a link FILL 16x8 -> SPRITE+0xA000", perf, ok ? 0 : 1);
    13a0:	ffff1637          	lui	a2,0xffff1
    13a4:	80060613          	addi	a2,a2,-2048 # ffff0800 <__freertos_irq_stack_top+0xfffe3b10>
    13a8:	00c40633          	add	a2,s0,a2
    13ac:	00c03633          	snez	a2,a2
    13b0:	00048593          	mv	a1,s1
    13b4:	00009537          	lui	a0,0x9
    13b8:	3d050513          	addi	a0,a0,976 # 93d0 <_data+0x247c>
    13bc:	0b0020ef          	jal	346c <item>
            if (!ok) bsp_printf("      像素(0,0)=0x%x 期望 0x%x\r\n", (int)got, (int)LINK_COLOR);
    13c0:	000107b7          	lui	a5,0x10
    13c4:	80078793          	addi	a5,a5,-2048 # f800 <__freertos_irq_stack_top+0x2b10>
    13c8:	0af40a63          	beq	s0,a5,147c <main+0x378>
    13cc:	00078613          	mv	a2,a5
    13d0:	00040593          	mv	a1,s0
    13d4:	00009537          	lui	a0,0x9
    13d8:	3f450513          	addi	a0,a0,1012 # 93f4 <_data+0x24a0>
    13dc:	0a9010ef          	jal	2c84 <bsp_printf>
    13e0:	09c0006f          	j	147c <main+0x378>
    bsp_printf("[2] timebase: CLINT mtime @0x%x %d Hz, 20000-loop=%d ticks (sink=0x%x) -> %s\r\n",
    13e4:	000097b7          	lui	a5,0x9
    13e8:	df078793          	addi	a5,a5,-528 # 8df0 <_data+0x1e9c>
    13ec:	e01ff06f          	j	11ec <main+0xe8>
        bsp_printf("[3] coherency: PASS (FB1 写 256 字 -> cache_evict -> invalidate -> 回读比对)\r\n");
    13f0:	00009537          	lui	a0,0x9
    13f4:	0a850513          	addi	a0,a0,168 # 90a8 <_data+0x2154>
    13f8:	08d010ef          	jal	2c84 <bsp_printf>
    13fc:	e45ff06f          	j	1240 <main+0x13c>
                   (int)((st >> 1) & 1u), (int)((st >> 3) & 1u),
    1400:	0014d593          	srli	a1,s1,0x1
    1404:	0034d613          	srli	a2,s1,0x3
                   (int)(st & 1u), (int)((st >> 2) & 1u));
    1408:	0024d713          	srli	a4,s1,0x2
        bsp_printf("    APB 窗口已接通：STATUS.DONE(bit1)=%d FIFO_EMPTY(bit3)=%d BUSY(bit0)=%d ERR(bit2)=%d\r\n",
    140c:	00177713          	andi	a4,a4,1
    1410:	0014f693          	andi	a3,s1,1
    1414:	00167613          	andi	a2,a2,1
    1418:	0015f593          	andi	a1,a1,1
    141c:	00009537          	lui	a0,0x9
    1420:	15c50513          	addi	a0,a0,348 # 915c <_data+0x2208>
    1424:	061010ef          	jal	2c84 <bsp_printf>
        blt_init();
    1428:	6e8000ef          	jal	1b10 <blt_init>
                   (int)blt_rd(BLT_CTRL), (int)blt_rd(BLT_STATUS));
    142c:	00000513          	li	a0,0
    1430:	45c000ef          	jal	188c <blt_rd>
    1434:	00050413          	mv	s0,a0
    1438:	00400513          	li	a0,4
    143c:	450000ef          	jal	188c <blt_rd>
    1440:	00050613          	mv	a2,a0
        bsp_printf("    blt_init(): SOFT_RST->0->清 IRQ->CTRL.GO 写一次; 现在 CTRL=0x%x STATUS=0x%x\r\n",
    1444:	00040593          	mv	a1,s0
    1448:	00009537          	lui	a0,0x9
    144c:	1bc50513          	addi	a0,a0,444 # 91bc <_data+0x2268>
    1450:	035010ef          	jal	2c84 <bsp_printf>
    1454:	ea5ff06f          	j	12f8 <main+0x1f4>
        } else {
            op_fail(rc, "5a link FILL");
    1458:	000095b7          	lui	a1,0x9
    145c:	41c58593          	addi	a1,a1,1052 # 941c <_data+0x24c8>
    1460:	4a9010ef          	jal	3108 <op_fail>
            item("5a link FILL 16x8 -> SPRITE+0xA000", 0u, -1);
    1464:	fff00613          	li	a2,-1
    1468:	00000593          	li	a1,0
    146c:	00009537          	lui	a0,0x9
    1470:	3d050513          	addi	a0,a0,976 # 93d0 <_data+0x247c>
    1474:	7f9010ef          	jal	346c <item>
            g_blt_alive = 0;
    1478:	8001ac23          	sw	zero,-2024(gp) # 96d8 <g_blt_alive>
        }
        if (g_blt_alive) test_burst(0);
    147c:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    1480:	00079c63          	bnez	a5,1498 <main+0x394>
        if (g_blt_alive) test_burst(1);
    1484:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    1488:	02078a63          	beqz	a5,14bc <main+0x3b8>
    148c:	00100513          	li	a0,1
    1490:	38c020ef          	jal	381c <test_burst>
    1494:	0280006f          	j	14bc <main+0x3b8>
        if (g_blt_alive) test_burst(0);
    1498:	00000513          	li	a0,0
    149c:	380020ef          	jal	381c <test_burst>
    14a0:	fe5ff06f          	j	1484 <main+0x380>
    } else {
        bsp_printf("  [5] SKIP（APB 窗口未接通）\r\n");
    14a4:	00009537          	lui	a0,0x9
    14a8:	42c50513          	addi	a0,a0,1068 # 942c <_data+0x24d8>
    14ac:	7d8010ef          	jal	2c84 <bsp_printf>
        g_fail += 3;
    14b0:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    14b4:	00378793          	addi	a5,a5,3
    14b8:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>
    }

    /* ---------------- [6] A/B/C/D 边界测试 ---------------- */
    if (g_blt_alive) {
    14bc:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    14c0:	02078863          	beqz	a5,14f0 <main+0x3ec>
        run_group_abcd();
    14c4:	641040ef          	jal	6304 <run_group_abcd>
        bsp_printf("[6] SKIP：引擎未响应（见 [4]/[5]）\r\n");
        g_fail += 17;
    }

    /* ---------------- [7] 多精灵压测 ---------------- */
    stress_all();
    14c8:	1fc050ef          	jal	66c4 <stress_all>

    /* ---------------- [8] 汇总 ---------------- */
    print_summary(g_fail);
    14cc:	8801a503          	lw	a0,-1920(gp) # 9740 <g_fail>
    14d0:	071050ef          	jal	6d40 <print_summary>

    /* ---------------- [demo] 保持上屏：简化版无限动画 ---------------- */
    bsp_printf("[demo] 测试与汇总结束，进入简化版无限演示（12 精灵 KEY/ALPHA 循环，程序不退出）\r\n");
    14d4:	00009537          	lui	a0,0x9
    14d8:	48450513          	addi	a0,a0,1156 # 9484 <_data+0x2530>
    14dc:	7a8010ef          	jal	2c84 <bsp_printf>
    bsp_printf("[demo] 说明：此循环只负责让 HDMI 持续有动画，不再做任何判定与打印，也不再返回。\r\n");
    14e0:	00009537          	lui	a0,0x9
    14e4:	4f450513          	addi	a0,a0,1268 # 94f4 <_data+0x25a0>
    14e8:	79c010ef          	jal	2c84 <bsp_printf>
    demo_loop();
    14ec:	08d050ef          	jal	6d78 <demo_loop>
        bsp_printf("[6] SKIP：引擎未响应（见 [4]/[5]）\r\n");
    14f0:	00009537          	lui	a0,0x9
    14f4:	45450513          	addi	a0,a0,1108 # 9454 <_data+0x2500>
    14f8:	78c010ef          	jal	2c84 <bsp_printf>
        g_fail += 17;
    14fc:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    1500:	01178793          	addi	a5,a5,17
    1504:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>
    1508:	fc1ff06f          	j	14c8 <main+0x3c4>

0000150c <uart_writeAvailability>:
#include "type.h"
#include "soc.h"


    static inline u32 read_u32(u32 address){
        return *((volatile u32*) address);
    150c:	00452503          	lw	a0,4(a0)
*          of available spaces for writing data from bits 23 to 16. It then
*          returns this value after masking with 0xFF.
*
******************************************************************************/
    static u32 uart_writeAvailability(u32 reg){
        return (read_u32(reg + UART_STATUS) >> 16) & 0xFF;
    1510:	01055513          	srli	a0,a0,0x10
    }
    1514:	0ff57513          	zext.b	a0,a0
    1518:	00008067          	ret

0000151c <uart_write>:
* @note    The function waits until there is available space in the UART buffer
*          for writing data. Once space is available, it writes the character
*          data to the UART data register.
*
******************************************************************************/
    static void uart_write(u32 reg, char data){
    151c:	ff010113          	addi	sp,sp,-16
    1520:	00112623          	sw	ra,12(sp)
    1524:	00812423          	sw	s0,8(sp)
    1528:	00912223          	sw	s1,4(sp)
    152c:	00050413          	mv	s0,a0
    1530:	00058493          	mv	s1,a1
        while(uart_writeAvailability(reg) == 0);
    1534:	00040513          	mv	a0,s0
    1538:	fd5ff0ef          	jal	150c <uart_writeAvailability>
    153c:	fe050ce3          	beqz	a0,1534 <uart_write+0x18>
    }
    
    static inline void write_u32(u32 data, u32 address){
        *((volatile u32*) address) = data;
    1540:	00942023          	sw	s1,0(s0)
        write_u32(data, reg + UART_DATA);
    }
    1544:	00c12083          	lw	ra,12(sp)
    1548:	00812403          	lw	s0,8(sp)
    154c:	00412483          	lw	s1,4(sp)
    1550:	01010113          	addi	sp,sp,16
    1554:	00008067          	ret

00001558 <uart_applyConfig>:
*          value using data length, parity, and stop bit settings from the configuration
*          structure, and writes this value to the UART frame configuration register.
*
******************************************************************************/
    static void uart_applyConfig(u32 reg, Uart_Config *config){
        write_u32(config->clockDivider, reg + UART_CLOCK_DIVIDER);
    1558:	00c5a783          	lw	a5,12(a1)
    155c:	00f52423          	sw	a5,8(a0)
        write_u32(((config->dataLength-1) << 0) | (config->parity << 8) | (config->stop << 16), reg + UART_FRAME_CONFIG);
    1560:	0005a783          	lw	a5,0(a1)
    1564:	fff78793          	addi	a5,a5,-1
    1568:	0045a703          	lw	a4,4(a1)
    156c:	00871713          	slli	a4,a4,0x8
    1570:	00e7e7b3          	or	a5,a5,a4
    1574:	0085a703          	lw	a4,8(a1)
    1578:	01071713          	slli	a4,a4,0x10
    157c:	00e7e7b3          	or	a5,a5,a4
    1580:	00f52623          	sw	a5,12(a0)
    }
    1584:	00008067          	ret

00001588 <clint_getTime>:
*          to guard against rollover. It checks if the high part remains unchanged
*          during the read operation to ensure consistency. The high and low parts
*          are then combined to form the 64-bit current time value.
*
******************************************************************************/
    static u64 clint_getTime(u32 p){
    1588:	00050693          	mv	a3,a0
    readReg_u32 (clint_getTimeHigh, CLINT_TIME_ADDR+4)
    158c:	0000c7b7          	lui	a5,0xc
    1590:	ffc78793          	addi	a5,a5,-4 # bffc <_end+0x314>
    1594:	00f687b3          	add	a5,a3,a5
        return *((volatile u32*) address);
    1598:	0007a583          	lw	a1,0(a5)
    readReg_u32 (clint_getTimeLow , CLINT_TIME_ADDR)
    159c:	0000c737          	lui	a4,0xc
    15a0:	ff870713          	addi	a4,a4,-8 # bff8 <_end+0x310>
    15a4:	00e68733          	add	a4,a3,a4
    15a8:	00072503          	lw	a0,0(a4)
    15ac:	0007a783          	lw	a5,0(a5)
    
        /* Likewise, must guard against rollover when reading */
        do {
            hi = clint_getTimeHigh(p);
            lo = clint_getTimeLow(p);
        } while (clint_getTimeHigh(p) != hi);
    15b0:	fcb79ee3          	bne	a5,a1,158c <clint_getTime+0x4>
    
        return (((u64)hi) << 32) | lo;
    }
    15b4:	00008067          	ret

000015b8 <_putchar>:
#include <math.h>
#include <string.h>
#include "bsp.h"

#if (ENABLE_BSP_PRINTF)
    static void _putchar(char character){
    15b8:	ff010113          	addi	sp,sp,-16
    15bc:	00112623          	sw	ra,12(sp)
    15c0:	00050593          	mv	a1,a0
        #if (ENABLE_SEMIHOSTING_PRINT == 1)
            sh_writec(character);
        #else
            bsp_putChar(character);
    15c4:	f8010537          	lui	a0,0xf8010
    15c8:	f55ff0ef          	jal	151c <uart_write>
        #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    15cc:	00c12083          	lw	ra,12(sp)
    15d0:	01010113          	addi	sp,sp,16
    15d4:	00008067          	ret

000015d8 <_putchar_s>:

    static void _putchar_s(char *p)
    {
    15d8:	ff010113          	addi	sp,sp,-16
    15dc:	00112623          	sw	ra,12(sp)
    15e0:	00812423          	sw	s0,8(sp)
    15e4:	00050413          	mv	s0,a0
    #if (ENABLE_SEMIHOSTING_PRINT == 1)
        sh_write0(p);
    #else
        while (*p)
    15e8:	00c0006f          	j	15f4 <_putchar_s+0x1c>
            _putchar(*(p++));
    15ec:	00140413          	addi	s0,s0,1
    15f0:	fc9ff0ef          	jal	15b8 <_putchar>
        while (*p)
    15f4:	00044503          	lbu	a0,0(s0)
    15f8:	fe051ae3          	bnez	a0,15ec <_putchar_s+0x14>
    #endif // (ENABLE_SEMIHOSTING_PRINT == 1)
    }
    15fc:	00c12083          	lw	ra,12(sp)
    1600:	00812403          	lw	s0,8(sp)
    1604:	01010113          	addi	sp,sp,16
    1608:	00008067          	ret

0000160c <bsp_printHex>:

        static void bsp_printHex(uint32_t val)
    {
    160c:	ff010113          	addi	sp,sp,-16
    1610:	00112623          	sw	ra,12(sp)
    1614:	00812423          	sw	s0,8(sp)
    1618:	00912223          	sw	s1,4(sp)
    161c:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1620:	01c00413          	li	s0,28
    1624:	0240006f          	j	1648 <bsp_printHex+0x3c>
            _putchar("0123456789ABCDEF"[(val >> i) % 16]);
    1628:	0084d733          	srl	a4,s1,s0
    162c:	00f77713          	andi	a4,a4,15
    1630:	000077b7          	lui	a5,0x7
    1634:	f5478793          	addi	a5,a5,-172 # 6f54 <_data>
    1638:	00e787b3          	add	a5,a5,a4
    163c:	0007c503          	lbu	a0,0(a5)
    1640:	f79ff0ef          	jal	15b8 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1644:	ffc40413          	addi	s0,s0,-4
    1648:	fe0450e3          	bgez	s0,1628 <bsp_printHex+0x1c>
        }
    }
    164c:	00c12083          	lw	ra,12(sp)
    1650:	00812403          	lw	s0,8(sp)
    1654:	00412483          	lw	s1,4(sp)
    1658:	01010113          	addi	sp,sp,16
    165c:	00008067          	ret

00001660 <bsp_printHex_lower>:

    static void bsp_printHex_lower(uint32_t val)
    {
    1660:	ff010113          	addi	sp,sp,-16
    1664:	00112623          	sw	ra,12(sp)
    1668:	00812423          	sw	s0,8(sp)
    166c:	00912223          	sw	s1,4(sp)
    1670:	00050493          	mv	s1,a0
        uint32_t digits;
        digits =8;

        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1674:	01c00413          	li	s0,28
    1678:	0240006f          	j	169c <bsp_printHex_lower+0x3c>
            _putchar("0123456789abcdef"[(val >> i) % 16]);
    167c:	0084d733          	srl	a4,s1,s0
    1680:	00f77713          	andi	a4,a4,15
    1684:	000077b7          	lui	a5,0x7
    1688:	f6878793          	addi	a5,a5,-152 # 6f68 <_data+0x14>
    168c:	00e787b3          	add	a5,a5,a4
    1690:	0007c503          	lbu	a0,0(a5)
    1694:	f25ff0ef          	jal	15b8 <_putchar>
        for (int i = (4*digits)-4; i >= 0; i -= 4) {
    1698:	ffc40413          	addi	s0,s0,-4
    169c:	fe0450e3          	bgez	s0,167c <bsp_printHex_lower+0x1c>

        }
    }
    16a0:	00c12083          	lw	ra,12(sp)
    16a4:	00812403          	lw	s0,8(sp)
    16a8:	00412483          	lw	s1,4(sp)
    16ac:	01010113          	addi	sp,sp,16
    16b0:	00008067          	ret

000016b4 <bsp_printf_c>:
*
* @param c: The character to be output.
*
******************************************************************************/
    static void bsp_printf_c(int c)
    {
    16b4:	ff010113          	addi	sp,sp,-16
    16b8:	00112623          	sw	ra,12(sp)
        _putchar(c);
    16bc:	0ff57513          	zext.b	a0,a0
    16c0:	ef9ff0ef          	jal	15b8 <_putchar>
    }
    16c4:	00c12083          	lw	ra,12(sp)
    16c8:	01010113          	addi	sp,sp,16
    16cc:	00008067          	ret

000016d0 <bsp_printf_s>:
*
* @param s: A pointer to the null-terminated string to be output.
*
*******************************************************************************/
    static void bsp_printf_s(char *p)
    {
    16d0:	ff010113          	addi	sp,sp,-16
    16d4:	00112623          	sw	ra,12(sp)
        _putchar_s(p);
    16d8:	f01ff0ef          	jal	15d8 <_putchar_s>
    }
    16dc:	00c12083          	lw	ra,12(sp)
    16e0:	01010113          	addi	sp,sp,16
    16e4:	00008067          	ret

000016e8 <bsp_printf_d>:
* - Handles negative numbers by printing a '-' sign.
* - Uses the 'bsp_printf_c' function to print each character.
*
******************************************************************************/
    static void bsp_printf_d(int val)
    {
    16e8:	fd010113          	addi	sp,sp,-48
    16ec:	02112623          	sw	ra,44(sp)
    16f0:	02812423          	sw	s0,40(sp)
    16f4:	02912223          	sw	s1,36(sp)
    16f8:	00050493          	mv	s1,a0
        char buffer[32];
        char *p = buffer;
        if (val < 0) {
    16fc:	00054663          	bltz	a0,1708 <bsp_printf_d+0x20>
    {
    1700:	00010413          	mv	s0,sp
    1704:	02c0006f          	j	1730 <bsp_printf_d+0x48>
            bsp_printf_c('-');
    1708:	02d00513          	li	a0,45
    170c:	fa9ff0ef          	jal	16b4 <bsp_printf_c>
            val = -val;
    1710:	409004b3          	neg	s1,s1
    1714:	fedff06f          	j	1700 <bsp_printf_d+0x18>
        }
        while (val || p == buffer) {
            *(p++) = '0' + val % 10;
    1718:	00a00713          	li	a4,10
    171c:	02e4e7b3          	rem	a5,s1,a4
    1720:	03078793          	addi	a5,a5,48
    1724:	00f40023          	sb	a5,0(s0)
            val = val / 10;
    1728:	02e4c4b3          	div	s1,s1,a4
            *(p++) = '0' + val % 10;
    172c:	00140413          	addi	s0,s0,1
        while (val || p == buffer) {
    1730:	fe0494e3          	bnez	s1,1718 <bsp_printf_d+0x30>
    1734:	00010793          	mv	a5,sp
    1738:	fef400e3          	beq	s0,a5,1718 <bsp_printf_d+0x30>
        }
        while (p != buffer)
    173c:	00010793          	mv	a5,sp
    1740:	00f40a63          	beq	s0,a5,1754 <bsp_printf_d+0x6c>
            bsp_printf_c(*(--p));
    1744:	fff40413          	addi	s0,s0,-1
    1748:	00044503          	lbu	a0,0(s0)
    174c:	f69ff0ef          	jal	16b4 <bsp_printf_c>
    1750:	fedff06f          	j	173c <bsp_printf_d+0x54>
    }
    1754:	02c12083          	lw	ra,44(sp)
    1758:	02812403          	lw	s0,40(sp)
    175c:	02412483          	lw	s1,36(sp)
    1760:	03010113          	addi	sp,sp,48
    1764:	00008067          	ret

00001768 <bsp_printf_x>:
* - Calls 'bsp_printHex_lower' to print the hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_x(int val)
    {
    1768:	ff010113          	addi	sp,sp,-16
    176c:	00112623          	sw	ra,12(sp)
        int i,digi=2;

        for(i=0;i<8;i++)
    1770:	00000713          	li	a4,0
    1774:	00700793          	li	a5,7
    1778:	02e7c063          	blt	a5,a4,1798 <bsp_printf_x+0x30>
        {
            if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    177c:	00271693          	slli	a3,a4,0x2
    1780:	ff000793          	li	a5,-16
    1784:	00d797b3          	sll	a5,a5,a3
    1788:	00f577b3          	and	a5,a0,a5
    178c:	00078663          	beqz	a5,1798 <bsp_printf_x+0x30>
        for(i=0;i<8;i++)
    1790:	00170713          	addi	a4,a4,1
    1794:	fe1ff06f          	j	1774 <bsp_printf_x+0xc>
            {
                digi=i+1;
                break;
            }
        }
        bsp_printHex_lower(val);
    1798:	ec9ff0ef          	jal	1660 <bsp_printHex_lower>
    }
    179c:	00c12083          	lw	ra,12(sp)
    17a0:	01010113          	addi	sp,sp,16
    17a4:	00008067          	ret

000017a8 <bsp_printf_X>:
* - Calls 'bsp_printHex' to print the uppercase hexadecimal representation.
* - Determines the number of leading zeros to be printed based on the value.
*
******************************************************************************/
    static void bsp_printf_X(int val)
        {
    17a8:	ff010113          	addi	sp,sp,-16
    17ac:	00112623          	sw	ra,12(sp)
            int i,digi=2;

            for(i=0;i<8;i++)
    17b0:	00000713          	li	a4,0
    17b4:	00700793          	li	a5,7
    17b8:	02e7c063          	blt	a5,a4,17d8 <bsp_printf_X+0x30>
            {
                if((val & (0xFFFFFFF0 <<(4*i))) == 0)
    17bc:	00271693          	slli	a3,a4,0x2
    17c0:	ff000793          	li	a5,-16
    17c4:	00d797b3          	sll	a5,a5,a3
    17c8:	00f577b3          	and	a5,a0,a5
    17cc:	00078663          	beqz	a5,17d8 <bsp_printf_X+0x30>
            for(i=0;i<8;i++)
    17d0:	00170713          	addi	a4,a4,1
    17d4:	fe1ff06f          	j	17b4 <bsp_printf_X+0xc>
                {
                    digi=i+1;
                    break;
                }
            }
            bsp_printHex(val);
    17d8:	e35ff0ef          	jal	160c <bsp_printHex>
        }
    17dc:	00c12083          	lw	ra,12(sp)
    17e0:	01010113          	addi	sp,sp,16
    17e4:	00008067          	ret

000017e8 <bsp_init>:
    *   1. UART baudrate
    *   2. 
    */
////////////////////////////////////////////////////////////////////////////////
    static void bsp_init()
    {
    17e8:	fe010113          	addi	sp,sp,-32
    17ec:	00112e23          	sw	ra,28(sp)
        Uart_Config uartConfig;
        uartConfig.dataLength   = BITS_8;
    17f0:	00800793          	li	a5,8
    17f4:	00f12023          	sw	a5,0(sp)
        uartConfig.parity       = NONE;
    17f8:	00012223          	sw	zero,4(sp)
        uartConfig.stop         = ONE;
    17fc:	00012423          	sw	zero,8(sp)
        uartConfig.clockDivider = BSP_CLINT_HZ/(BSP_UART_BAUDRATE*BSP_UART_DATA_LEN)-1;
    1800:	06b00793          	li	a5,107
    1804:	00f12623          	sw	a5,12(sp)
        uart_applyConfig(BSP_UART_TERMINAL, &uartConfig);    
    1808:	00010593          	mv	a1,sp
    180c:	f8010537          	lui	a0,0xf8010
    1810:	d49ff0ef          	jal	1558 <uart_applyConfig>
    }
    1814:	01c12083          	lw	ra,28(sp)
    1818:	02010113          	addi	sp,sp,32
    181c:	00008067          	ret

00001820 <tick>:
{
    1820:	ff010113          	addi	sp,sp,-16
    1824:	00112623          	sw	ra,12(sp)
    return clint_getTime(BSP_CLINT);          /* 只读 MMIO，绝不会异常 */
    1828:	f8b00537          	lui	a0,0xf8b00
    182c:	d5dff0ef          	jal	1588 <clint_getTime>
}
    1830:	00c12083          	lw	ra,12(sp)
    1834:	01010113          	addi	sp,sp,16
    1838:	00008067          	ret

0000183c <busy_loop>:
{
    183c:	ff010113          	addi	sp,sp,-16
    volatile uint32_t sink = 0;
    1840:	00012623          	sw	zero,12(sp)
    while (n--) sink += n;
    1844:	0140006f          	j	1858 <busy_loop+0x1c>
    1848:	00c12783          	lw	a5,12(sp)
    184c:	00e787b3          	add	a5,a5,a4
    1850:	00f12623          	sw	a5,12(sp)
    1854:	00070513          	mv	a0,a4
    1858:	fff50713          	addi	a4,a0,-1 # f8afffff <__freertos_irq_stack_top+0xf8af330f>
    185c:	fe0516e3          	bnez	a0,1848 <busy_loop+0xc>
    return sink;
    1860:	00c12503          	lw	a0,12(sp)
}
    1864:	01010113          	addi	sp,sp,16
    1868:	00008067          	ret

0000186c <wr16>:
    *(volatile uint16_t *)addr = v;
    186c:	00b51023          	sh	a1,0(a0)
}
    1870:	00008067          	ret

00001874 <rd16>:
    return *(volatile uint16_t *)addr;
    1874:	00055503          	lhu	a0,0(a0)
}
    1878:	00008067          	ret

0000187c <blt_wr>:
    *(volatile uint32_t *)(BLT_BASE + off) = val;
    187c:	f81007b7          	lui	a5,0xf8100
    1880:	00f50533          	add	a0,a0,a5
    1884:	00b52023          	sw	a1,0(a0)
}
    1888:	00008067          	ret

0000188c <blt_rd>:
    return *(volatile uint32_t *)(BLT_BASE + off);
    188c:	f81007b7          	lui	a5,0xf8100
    1890:	00f50533          	add	a0,a0,a5
    1894:	00052503          	lw	a0,0(a0)
}
    1898:	00008067          	ret

0000189c <fill_rect_cpu>:
{
    189c:	fd010113          	addi	sp,sp,-48
    18a0:	02112623          	sw	ra,44(sp)
    18a4:	02812423          	sw	s0,40(sp)
    18a8:	02912223          	sw	s1,36(sp)
    18ac:	03212023          	sw	s2,32(sp)
    18b0:	01312e23          	sw	s3,28(sp)
    18b4:	01412c23          	sw	s4,24(sp)
    18b8:	01512a23          	sw	s5,20(sp)
    18bc:	01612823          	sw	s6,16(sp)
    18c0:	01712623          	sw	s7,12(sp)
    18c4:	01812423          	sw	s8,8(sp)
    18c8:	01912223          	sw	s9,4(sp)
    18cc:	00050c93          	mv	s9,a0
    18d0:	00058c13          	mv	s8,a1
    18d4:	00060b93          	mv	s7,a2
    18d8:	00068b13          	mv	s6,a3
    18dc:	00070913          	mv	s2,a4
    18e0:	00078a93          	mv	s5,a5
    18e4:	00080993          	mv	s3,a6
    for (j = 0; j < h; j++) {
    18e8:	00000a13          	li	s4,0
    18ec:	0200006f          	j	190c <fill_rect_cpu+0x70>
            wr16(row + (uint32_t)i * 2u, color);
    18f0:	00141513          	slli	a0,s0,0x1
    18f4:	00098593          	mv	a1,s3
    18f8:	00950533          	add	a0,a0,s1
    18fc:	f71ff0ef          	jal	186c <wr16>
        for (i = 0; i < w; i++)
    1900:	00140413          	addi	s0,s0,1
    1904:	ff2446e3          	blt	s0,s2,18f0 <fill_rect_cpu+0x54>
    for (j = 0; j < h; j++) {
    1908:	001a0a13          	addi	s4,s4,1
    190c:	035a5063          	bge	s4,s5,192c <fill_rect_cpu+0x90>
        uint32_t row = base + (uint32_t)(y + j) * stride + (uint32_t)x * 2u;
    1910:	016a04b3          	add	s1,s4,s6
    1914:	038484b3          	mul	s1,s1,s8
    1918:	001b9793          	slli	a5,s7,0x1
    191c:	00f484b3          	add	s1,s1,a5
    1920:	019484b3          	add	s1,s1,s9
        for (i = 0; i < w; i++)
    1924:	00000413          	li	s0,0
    1928:	fddff06f          	j	1904 <fill_rect_cpu+0x68>
}
    192c:	02c12083          	lw	ra,44(sp)
    1930:	02812403          	lw	s0,40(sp)
    1934:	02412483          	lw	s1,36(sp)
    1938:	02012903          	lw	s2,32(sp)
    193c:	01c12983          	lw	s3,28(sp)
    1940:	01812a03          	lw	s4,24(sp)
    1944:	01412a83          	lw	s5,20(sp)
    1948:	01012b03          	lw	s6,16(sp)
    194c:	00c12b83          	lw	s7,12(sp)
    1950:	00812c03          	lw	s8,8(sp)
    1954:	00412c83          	lw	s9,4(sp)
    1958:	03010113          	addi	sp,sp,48
    195c:	00008067          	ret

00001960 <cache_evict>:
    for (i = 0; i < (uint32_t)CACHE_EVICT_WORDS; i++)
    1960:	00000793          	li	a5,0
    1964:	0200006f          	j	1984 <cache_evict+0x24>
        scratch[i] = 0xA5A50000UL + i;
    1968:	00279693          	slli	a3,a5,0x2
    196c:	00501737          	lui	a4,0x501
    1970:	00d70733          	add	a4,a4,a3
    1974:	a5a506b7          	lui	a3,0xa5a50
    1978:	00d786b3          	add	a3,a5,a3
    197c:	00d72023          	sw	a3,0(a4) # 501000 <__freertos_irq_stack_top+0x4f4310>
    for (i = 0; i < (uint32_t)CACHE_EVICT_WORDS; i++)
    1980:	00178793          	addi	a5,a5,1 # f8100001 <__freertos_irq_stack_top+0xf80f3311>
    1984:	7ff00713          	li	a4,2047
    1988:	fef770e3          	bgeu	a4,a5,1968 <cache_evict+0x8>
}
    198c:	00008067          	ret

00001990 <cache_evict_timed>:
{
    1990:	ff010113          	addi	sp,sp,-16
    1994:	00112623          	sw	ra,12(sp)
    1998:	00812423          	sw	s0,8(sp)
    uint64_t t0 = tick();
    199c:	e85ff0ef          	jal	1820 <tick>
    19a0:	00050413          	mv	s0,a0
    cache_evict();
    19a4:	fbdff0ef          	jal	1960 <cache_evict>
    return (uint32_t)(tick() - t0);
    19a8:	e79ff0ef          	jal	1820 <tick>
}
    19ac:	40850533          	sub	a0,a0,s0
    19b0:	00c12083          	lw	ra,12(sp)
    19b4:	00812403          	lw	s0,8(sp)
    19b8:	01010113          	addi	sp,sp,16
    19bc:	00008067          	ret

000019c0 <cache_invalidate>:
{
    19c0:	0000500f          	.word	0x0000500f
}
    19c4:	00008067          	ret

000019c8 <mis_reset>:
    g_mis = 0;
    19c8:	8601ae23          	sw	zero,-1924(gp) # 973c <g_mis>
    g_mis_shown = 0;
    19cc:	8601ac23          	sw	zero,-1928(gp) # 9738 <g_mis_shown>
}
    19d0:	00008067          	ret

000019d4 <exp5>:
static uint32_t exp5(uint32_t v) { return (v << 3) | (v >> 2); }
    19d4:	00351793          	slli	a5,a0,0x3
    19d8:	00255513          	srli	a0,a0,0x2
    19dc:	00a7e533          	or	a0,a5,a0
    19e0:	00008067          	ret

000019e4 <exp6>:
static uint32_t exp6(uint32_t v) { return (v << 2) | (v >> 4); }
    19e4:	00251793          	slli	a5,a0,0x2
    19e8:	00455513          	srli	a0,a0,0x4
    19ec:	00a7e533          	or	a0,a5,a0
    19f0:	00008067          	ret

000019f4 <alpha_ref>:
{
    19f4:	fe010113          	addi	sp,sp,-32
    19f8:	00112e23          	sw	ra,28(sp)
    19fc:	00812c23          	sw	s0,24(sp)
    1a00:	00912a23          	sw	s1,20(sp)
    1a04:	01212823          	sw	s2,16(sp)
    1a08:	01312623          	sw	s3,12(sp)
    1a0c:	01412423          	sw	s4,8(sp)
    1a10:	01512223          	sw	s5,4(sp)
    1a14:	01612023          	sw	s6,0(sp)
    1a18:	00050913          	mv	s2,a0
    1a1c:	00058b13          	mv	s6,a1
    1a20:	00060993          	mv	s3,a2
    uint32_t fr  = exp5((fg >> 11) & 0x1Fu);
    1a24:	00b55513          	srli	a0,a0,0xb
    1a28:	01f57513          	andi	a0,a0,31
    1a2c:	fa9ff0ef          	jal	19d4 <exp5>
    1a30:	00050413          	mv	s0,a0
    uint32_t fgc = exp6((fg >> 5) & 0x3Fu);
    1a34:	00595513          	srli	a0,s2,0x5
    1a38:	03f57513          	andi	a0,a0,63
    1a3c:	fa9ff0ef          	jal	19e4 <exp6>
    1a40:	00050493          	mv	s1,a0
    uint32_t fb  = exp5(fg & 0x1Fu);
    1a44:	01f97513          	andi	a0,s2,31
    1a48:	f8dff0ef          	jal	19d4 <exp5>
    1a4c:	00050913          	mv	s2,a0
    uint32_t br  = exp5((bg >> 11) & 0x1Fu);
    1a50:	00bb5513          	srli	a0,s6,0xb
    1a54:	01f57513          	andi	a0,a0,31
    1a58:	f7dff0ef          	jal	19d4 <exp5>
    1a5c:	00050a93          	mv	s5,a0
    uint32_t bgc = exp6((bg >> 5) & 0x3Fu);
    1a60:	005b5513          	srli	a0,s6,0x5
    1a64:	03f57513          	andi	a0,a0,63
    1a68:	f7dff0ef          	jal	19e4 <exp6>
    1a6c:	00050a13          	mv	s4,a0
    uint32_t bb  = exp5(bg & 0x1Fu);
    1a70:	01fb7513          	andi	a0,s6,31
    1a74:	f61ff0ef          	jal	19d4 <exp5>
    uint32_t ai  = 255u - a;
    1a78:	0ff00793          	li	a5,255
    1a7c:	413787b3          	sub	a5,a5,s3
    uint32_t r8  = (fr  * a + br  * ai + 127u) >> 8;
    1a80:	03340433          	mul	s0,s0,s3
    1a84:	02fa8ab3          	mul	s5,s5,a5
    1a88:	01540433          	add	s0,s0,s5
    1a8c:	07f40413          	addi	s0,s0,127
    uint32_t g8  = (fgc * a + bgc * ai + 127u) >> 8;
    1a90:	033484b3          	mul	s1,s1,s3
    1a94:	02fa0a33          	mul	s4,s4,a5
    1a98:	014484b3          	add	s1,s1,s4
    1a9c:	07f48493          	addi	s1,s1,127
    uint32_t b8  = (fb  * a + bb  * ai + 127u) >> 8;
    1aa0:	03390933          	mul	s2,s2,s3
    1aa4:	02f50533          	mul	a0,a0,a5
    1aa8:	00a90533          	add	a0,s2,a0
    1aac:	07f50513          	addi	a0,a0,127
    return ((r8 >> 3) << 11) | ((g8 >> 2) << 5) | (b8 >> 3);
    1ab0:	80047413          	andi	s0,s0,-2048
    1ab4:	00a4d493          	srli	s1,s1,0xa
    1ab8:	00549493          	slli	s1,s1,0x5
    1abc:	00946433          	or	s0,s0,s1
    1ac0:	00b55513          	srli	a0,a0,0xb
}
    1ac4:	00a46533          	or	a0,s0,a0
    1ac8:	01c12083          	lw	ra,28(sp)
    1acc:	01812403          	lw	s0,24(sp)
    1ad0:	01412483          	lw	s1,20(sp)
    1ad4:	01012903          	lw	s2,16(sp)
    1ad8:	00c12983          	lw	s3,12(sp)
    1adc:	00812a03          	lw	s4,8(sp)
    1ae0:	00412a83          	lw	s5,4(sp)
    1ae4:	00012b03          	lw	s6,0(sp)
    1ae8:	02010113          	addi	sp,sp,32
    1aec:	00008067          	ret

00001af0 <ch_r>:
static uint32_t ch_r(uint32_t p) { return (p >> 11) & 0x1Fu; }
    1af0:	00b55513          	srli	a0,a0,0xb
    1af4:	01f57513          	andi	a0,a0,31
    1af8:	00008067          	ret

00001afc <ch_g>:
static uint32_t ch_g(uint32_t p) { return (p >> 5)  & 0x3Fu; }
    1afc:	00555513          	srli	a0,a0,0x5
    1b00:	03f57513          	andi	a0,a0,63
    1b04:	00008067          	ret

00001b08 <ch_b>:
static uint32_t ch_b(uint32_t p) { return p & 0x1Fu; }
    1b08:	01f57513          	andi	a0,a0,31
    1b0c:	00008067          	ret

00001b10 <blt_init>:
{
    1b10:	ff010113          	addi	sp,sp,-16
    1b14:	00112623          	sw	ra,12(sp)
    blt_wr(BLT_IRQ_EN, 0);
    1b18:	00000593          	li	a1,0
    1b1c:	01400513          	li	a0,20
    1b20:	d5dff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_IRQ_STATUS, 1);            /* W1C 清 DONE */
    1b24:	00100593          	li	a1,1
    1b28:	01000513          	li	a0,16
    1b2c:	d51ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CTRL, BLT_CTRL_SOFT_RST);  /* SOFT_RST：1 拍脉冲 */
    1b30:	00400593          	li	a1,4
    1b34:	00000513          	li	a0,0
    1b38:	d45ff0ef          	jal	187c <blt_wr>
    busy_loop(BLT_SETTLE_LOOPS);
    1b3c:	0c800513          	li	a0,200
    1b40:	cfdff0ef          	jal	183c <busy_loop>
    blt_wr(BLT_CTRL, 0);
    1b44:	00000593          	li	a1,0
    1b48:	00000513          	li	a0,0
    1b4c:	d31ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_IRQ_STATUS, 1);
    1b50:	00100593          	li	a1,1
    1b54:	01000513          	li	a0,16
    1b58:	d25ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CTRL, BLT_CTRL_GO);        /* 写一次即可 */
    1b5c:	00100593          	li	a1,1
    1b60:	00000513          	li	a0,0
    1b64:	d19ff0ef          	jal	187c <blt_wr>
    busy_loop(BLT_SETTLE_LOOPS);
    1b68:	0c800513          	li	a0,200
    1b6c:	cd1ff0ef          	jal	183c <busy_loop>
}
    1b70:	00c12083          	lw	ra,12(sp)
    1b74:	01010113          	addi	sp,sp,16
    1b78:	00008067          	ret

00001b7c <blt_fifo_room>:
{
    1b7c:	ff010113          	addi	sp,sp,-16
    1b80:	00112623          	sw	ra,12(sp)
    1b84:	00812423          	sw	s0,8(sp)
    uint64_t t0 = tick();
    1b88:	c99ff0ef          	jal	1820 <tick>
    1b8c:	00050413          	mv	s0,a0
    while (blt_rd(BLT_CMD_FIFO_COUNT) >= BLT_FIFO_HIWATER) {
    1b90:	00c00513          	li	a0,12
    1b94:	cf9ff0ef          	jal	188c <blt_rd>
    1b98:	0c700793          	li	a5,199
    1b9c:	02a7f863          	bgeu	a5,a0,1bcc <blt_fifo_room+0x50>
        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) return -2;   /* 引擎 ERR：不会消费了 */
    1ba0:	00400513          	li	a0,4
    1ba4:	ce9ff0ef          	jal	188c <blt_rd>
    1ba8:	00457513          	andi	a0,a0,4
    1bac:	02051a63          	bnez	a0,1be0 <blt_fifo_room+0x64>
        if ((uint32_t)(tick() - t0) > BLT_TIMEOUT_TICKS) return -1;
    1bb0:	c71ff0ef          	jal	1820 <tick>
    1bb4:	40850533          	sub	a0,a0,s0
    1bb8:	0bebc7b7          	lui	a5,0xbebc
    1bbc:	20078793          	addi	a5,a5,512 # bebc200 <__freertos_irq_stack_top+0xbeaf510>
    1bc0:	fca7f8e3          	bgeu	a5,a0,1b90 <blt_fifo_room+0x14>
    1bc4:	fff00513          	li	a0,-1
    1bc8:	0080006f          	j	1bd0 <blt_fifo_room+0x54>
    return 0;
    1bcc:	00000513          	li	a0,0
}
    1bd0:	00c12083          	lw	ra,12(sp)
    1bd4:	00812403          	lw	s0,8(sp)
    1bd8:	01010113          	addi	sp,sp,16
    1bdc:	00008067          	ret
        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) return -2;   /* 引擎 ERR：不会消费了 */
    1be0:	ffe00513          	li	a0,-2
    1be4:	fedff06f          	j	1bd0 <blt_fifo_room+0x54>

00001be8 <blt_emit_cmd>:
{
    1be8:	fd010113          	addi	sp,sp,-48
    1bec:	02112623          	sw	ra,44(sp)
    1bf0:	02812423          	sw	s0,40(sp)
    1bf4:	02912223          	sw	s1,36(sp)
    1bf8:	03212023          	sw	s2,32(sp)
    1bfc:	01312e23          	sw	s3,28(sp)
    1c00:	01412c23          	sw	s4,24(sp)
    1c04:	01512a23          	sw	s5,20(sp)
    1c08:	01612823          	sw	s6,16(sp)
    1c0c:	01712623          	sw	s7,12(sp)
    1c10:	01812423          	sw	s8,8(sp)
    1c14:	01912223          	sw	s9,4(sp)
    1c18:	00050b93          	mv	s7,a0
    1c1c:	00058b13          	mv	s6,a1
    1c20:	00060a93          	mv	s5,a2
    1c24:	00068a13          	mv	s4,a3
    1c28:	00070993          	mv	s3,a4
    1c2c:	00078913          	mv	s2,a5
    1c30:	00080493          	mv	s1,a6
    1c34:	00088413          	mv	s0,a7
    1c38:	03012c83          	lw	s9,48(sp)
    blt_wr(BLT_CMD_FIFO_DATA, op);
    1c3c:	00050593          	mv	a1,a0
    1c40:	00800513          	li	a0,8
    1c44:	c39ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, src);
    1c48:	000b0593          	mv	a1,s6
    1c4c:	00800513          	li	a0,8
    1c50:	c2dff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, dst);
    1c54:	000a8593          	mv	a1,s5
    1c58:	00800513          	li	a0,8
    1c5c:	c21ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, sstride);
    1c60:	000a0593          	mv	a1,s4
    1c64:	00800513          	li	a0,8
    1c68:	c15ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, dstride);
    1c6c:	00098593          	mv	a1,s3
    1c70:	00800513          	li	a0,8
    1c74:	c09ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, ((h & 0xFFFFUL) << 16) | (w & 0xFFFFUL));
    1c78:	01049593          	slli	a1,s1,0x10
    1c7c:	00010c37          	lui	s8,0x10
    1c80:	fffc0c13          	addi	s8,s8,-1 # ffff <__freertos_irq_stack_top+0x330f>
    1c84:	018977b3          	and	a5,s2,s8
    1c88:	00f5e5b3          	or	a1,a1,a5
    1c8c:	00800513          	li	a0,8
    1c90:	bedff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, alpha & 0xFFUL);
    1c94:	0ff47593          	zext.b	a1,s0
    1c98:	00800513          	li	a0,8
    1c9c:	be1ff0ef          	jal	187c <blt_wr>
    blt_wr(BLT_CMD_FIFO_DATA, color & 0xFFFFUL);
    1ca0:	018cf5b3          	and	a1,s9,s8
    1ca4:	00800513          	li	a0,8
    1ca8:	bd5ff0ef          	jal	187c <blt_wr>
    g_last_cmd.op      = op;       g_last_cmd.src     = src;
    1cac:	0000c337          	lui	t1,0xc
    1cb0:	cc430313          	addi	t1,t1,-828 # bcc4 <g_last_cmd>
    1cb4:	01732023          	sw	s7,0(t1)
    1cb8:	01632223          	sw	s6,4(t1)
    g_last_cmd.dst     = dst;      g_last_cmd.sstride = sstride;
    1cbc:	01532423          	sw	s5,8(t1)
    1cc0:	01432623          	sw	s4,12(t1)
    g_last_cmd.dstride = dstride;  g_last_cmd.w       = w;
    1cc4:	01332823          	sw	s3,16(t1)
    1cc8:	01232a23          	sw	s2,20(t1)
    g_last_cmd.h       = h;        g_last_cmd.alpha   = alpha;
    1ccc:	00932c23          	sw	s1,24(t1)
    1cd0:	00832e23          	sw	s0,28(t1)
    g_last_cmd.color   = color;
    1cd4:	03932023          	sw	s9,32(t1)
    g_ins_total++;
    1cd8:	8601a783          	lw	a5,-1952(gp) # 9720 <g_ins_total>
    1cdc:	00178793          	addi	a5,a5,1
    1ce0:	86f1a023          	sw	a5,-1952(gp) # 9720 <g_ins_total>
}
    1ce4:	02c12083          	lw	ra,44(sp)
    1ce8:	02812403          	lw	s0,40(sp)
    1cec:	02412483          	lw	s1,36(sp)
    1cf0:	02012903          	lw	s2,32(sp)
    1cf4:	01c12983          	lw	s3,28(sp)
    1cf8:	01812a03          	lw	s4,24(sp)
    1cfc:	01412a83          	lw	s5,20(sp)
    1d00:	01012b03          	lw	s6,16(sp)
    1d04:	00c12b83          	lw	s7,12(sp)
    1d08:	00812c03          	lw	s8,8(sp)
    1d0c:	00412c83          	lw	s9,4(sp)
    1d10:	03010113          	addi	sp,sp,48
    1d14:	00008067          	ret

00001d18 <blt_push_cmd>:
{
    1d18:	fc010113          	addi	sp,sp,-64
    1d1c:	02112e23          	sw	ra,60(sp)
    1d20:	02812c23          	sw	s0,56(sp)
    1d24:	02912a23          	sw	s1,52(sp)
    1d28:	03212823          	sw	s2,48(sp)
    1d2c:	03312623          	sw	s3,44(sp)
    1d30:	03412423          	sw	s4,40(sp)
    1d34:	03512223          	sw	s5,36(sp)
    1d38:	03612023          	sw	s6,32(sp)
    1d3c:	01712e23          	sw	s7,28(sp)
    1d40:	01812c23          	sw	s8,24(sp)
    1d44:	00050493          	mv	s1,a0
    1d48:	00058913          	mv	s2,a1
    1d4c:	00060993          	mv	s3,a2
    1d50:	00068a13          	mv	s4,a3
    1d54:	00070a93          	mv	s5,a4
    1d58:	00078c13          	mv	s8,a5
    1d5c:	00080b13          	mv	s6,a6
    1d60:	00088b93          	mv	s7,a7
    int room = blt_fifo_room();                 /* 只在两条指令之间做 */
    1d64:	e19ff0ef          	jal	1b7c <blt_fifo_room>
    1d68:	00050413          	mv	s0,a0
    if (room != 0) return room;                 /* 失败：一个字都没写，边界干净 */
    1d6c:	02050c63          	beqz	a0,1da4 <blt_push_cmd+0x8c>
}
    1d70:	00040513          	mv	a0,s0
    1d74:	03c12083          	lw	ra,60(sp)
    1d78:	03812403          	lw	s0,56(sp)
    1d7c:	03412483          	lw	s1,52(sp)
    1d80:	03012903          	lw	s2,48(sp)
    1d84:	02c12983          	lw	s3,44(sp)
    1d88:	02812a03          	lw	s4,40(sp)
    1d8c:	02412a83          	lw	s5,36(sp)
    1d90:	02012b03          	lw	s6,32(sp)
    1d94:	01c12b83          	lw	s7,28(sp)
    1d98:	01812c03          	lw	s8,24(sp)
    1d9c:	04010113          	addi	sp,sp,64
    1da0:	00008067          	ret
    blt_emit_cmd(op, src, dst, sstride, dstride, w, h, alpha, color);   /* 连续 8 字 */
    1da4:	04012783          	lw	a5,64(sp)
    1da8:	00f12023          	sw	a5,0(sp)
    1dac:	000b8893          	mv	a7,s7
    1db0:	000b0813          	mv	a6,s6
    1db4:	000c0793          	mv	a5,s8
    1db8:	000a8713          	mv	a4,s5
    1dbc:	000a0693          	mv	a3,s4
    1dc0:	00098613          	mv	a2,s3
    1dc4:	00090593          	mv	a1,s2
    1dc8:	00048513          	mv	a0,s1
    1dcc:	e1dff0ef          	jal	1be8 <blt_emit_cmd>
    return 0;
    1dd0:	fa1ff06f          	j	1d70 <blt_push_cmd+0x58>

00001dd4 <blt_push_cmd_raw>:
{
    1dd4:	fe010113          	addi	sp,sp,-32
    1dd8:	00112e23          	sw	ra,28(sp)
    blt_emit_cmd(op, src, dst, sstride, dstride, w, h, alpha, color);
    1ddc:	02012303          	lw	t1,32(sp)
    1de0:	00612023          	sw	t1,0(sp)
    1de4:	e05ff0ef          	jal	1be8 <blt_emit_cmd>
}
    1de8:	01c12083          	lw	ra,28(sp)
    1dec:	02010113          	addi	sp,sp,32
    1df0:	00008067          	ret

00001df4 <blt_fifo_clean>:
{
    1df4:	ff010113          	addi	sp,sp,-16
    1df8:	00112623          	sw	ra,12(sp)
    1dfc:	00812423          	sw	s0,8(sp)
    uint32_t st  = blt_rd(BLT_STATUS);
    1e00:	00400513          	li	a0,4
    1e04:	a89ff0ef          	jal	188c <blt_rd>
    1e08:	00050413          	mv	s0,a0
    uint32_t cnt = blt_rd(BLT_CMD_FIFO_COUNT);
    1e0c:	00c00513          	li	a0,12
    1e10:	a7dff0ef          	jal	188c <blt_rd>
    if (st & BLT_STATUS_ERR) return 0;            /* 引擎停机：不算干净 */
    1e14:	00447793          	andi	a5,s0,4
    1e18:	02079063          	bnez	a5,1e38 <blt_fifo_clean+0x44>
    if (!(st & BLT_STATUS_DONE)) return 0;        /* 还在跑/POP：状态不稳，不能判 */
    1e1c:	00247793          	andi	a5,s0,2
    1e20:	02078663          	beqz	a5,1e4c <blt_fifo_clean+0x58>
    return (cnt == 0u && (st & BLT_STATUS_FIFO_EMPTY)) ? 1 : 0;
    1e24:	02051863          	bnez	a0,1e54 <blt_fifo_clean+0x60>
    1e28:	00847413          	andi	s0,s0,8
    1e2c:	00040863          	beqz	s0,1e3c <blt_fifo_clean+0x48>
    1e30:	00100513          	li	a0,1
    1e34:	0080006f          	j	1e3c <blt_fifo_clean+0x48>
    if (st & BLT_STATUS_ERR) return 0;            /* 引擎停机：不算干净 */
    1e38:	00000513          	li	a0,0
}
    1e3c:	00c12083          	lw	ra,12(sp)
    1e40:	00812403          	lw	s0,8(sp)
    1e44:	01010113          	addi	sp,sp,16
    1e48:	00008067          	ret
    if (!(st & BLT_STATUS_DONE)) return 0;        /* 还在跑/POP：状态不稳，不能判 */
    1e4c:	00000513          	li	a0,0
    1e50:	fedff06f          	j	1e3c <blt_fifo_clean+0x48>
    return (cnt == 0u && (st & BLT_STATUS_FIFO_EMPTY)) ? 1 : 0;
    1e54:	00000513          	li	a0,0
    1e58:	fe5ff06f          	j	1e3c <blt_fifo_clean+0x48>

00001e5c <blt_batch_ready>:
{
    1e5c:	fe010113          	addi	sp,sp,-32
    1e60:	00112e23          	sw	ra,28(sp)
    1e64:	00812c23          	sw	s0,24(sp)
    1e68:	00912a23          	sw	s1,20(sp)
    1e6c:	01212823          	sw	s2,16(sp)
    1e70:	01312623          	sw	s3,12(sp)
    1e74:	01412423          	sw	s4,8(sp)
    1e78:	01512223          	sw	s5,4(sp)
    uint64_t t0 = tick();
    1e7c:	9a5ff0ef          	jal	1820 <tick>
    1e80:	00050a13          	mv	s4,a0
    uint64_t t_drop = t0;
    1e84:	00050913          	mv	s2,a0
    int first = 1;
    1e88:	00100a93          	li	s5,1
    uint32_t last = 0xFFFFFFFFUL;
    1e8c:	fff00993          	li	s3,-1
    1e90:	03c0006f          	j	1ecc <blt_batch_ready+0x70>
        if (first || cnt < last) { last = cnt; t_drop = tick(); first = 0; }
    1e94:	98dff0ef          	jal	1820 <tick>
    1e98:	00050913          	mv	s2,a0
    1e9c:	00048993          	mv	s3,s1
        if ((uint32_t)(tick() - t_drop) > (uint32_t)STRESS_WD_STALL_TICKS)
    1ea0:	981ff0ef          	jal	1820 <tick>
    1ea4:	41250733          	sub	a4,a0,s2
    1ea8:	009897b7          	lui	a5,0x989
    1eac:	68078793          	addi	a5,a5,1664 # 989680 <__freertos_irq_stack_top+0x97c990>
    1eb0:	08e7e463          	bltu	a5,a4,1f38 <blt_batch_ready+0xdc>
        if ((uint32_t)(tick() - t0) > (uint32_t)STRESS_WD_TICKS)
    1eb4:	96dff0ef          	jal	1820 <tick>
    1eb8:	41450533          	sub	a0,a0,s4
    1ebc:	00000a93          	li	s5,0
    1ec0:	02faf7b7          	lui	a5,0x2faf
    1ec4:	08078793          	addi	a5,a5,128 # 2faf080 <__freertos_irq_stack_top+0x2fa2390>
    1ec8:	02a7ec63          	bltu	a5,a0,1f00 <blt_batch_ready+0xa4>
        uint32_t st  = blt_rd(BLT_STATUS);
    1ecc:	00400513          	li	a0,4
    1ed0:	9bdff0ef          	jal	188c <blt_rd>
    1ed4:	00050413          	mv	s0,a0
        uint32_t cnt = blt_rd(BLT_CMD_FIFO_COUNT);
    1ed8:	00c00513          	li	a0,12
    1edc:	9b1ff0ef          	jal	188c <blt_rd>
    1ee0:	00050493          	mv	s1,a0
        if (st & BLT_STATUS_ERR) return -2;
    1ee4:	00447413          	andi	s0,s0,4
    1ee8:	02041063          	bnez	s0,1f08 <blt_batch_ready+0xac>
        if (cnt <= (uint32_t)STRESS_BATCH_HEADROOM) return 0;
    1eec:	03000793          	li	a5,48
    1ef0:	04a7f063          	bgeu	a5,a0,1f30 <blt_batch_ready+0xd4>
        if (first || cnt < last) { last = cnt; t_drop = tick(); first = 0; }
    1ef4:	fa0a90e3          	bnez	s5,1e94 <blt_batch_ready+0x38>
    1ef8:	fb3574e3          	bgeu	a0,s3,1ea0 <blt_batch_ready+0x44>
    1efc:	f99ff06f          	j	1e94 <blt_batch_ready+0x38>
            return -1;
    1f00:	fff00513          	li	a0,-1
    1f04:	0080006f          	j	1f0c <blt_batch_ready+0xb0>
        if (st & BLT_STATUS_ERR) return -2;
    1f08:	ffe00513          	li	a0,-2
}
    1f0c:	01c12083          	lw	ra,28(sp)
    1f10:	01812403          	lw	s0,24(sp)
    1f14:	01412483          	lw	s1,20(sp)
    1f18:	01012903          	lw	s2,16(sp)
    1f1c:	00c12983          	lw	s3,12(sp)
    1f20:	00812a03          	lw	s4,8(sp)
    1f24:	00412a83          	lw	s5,4(sp)
    1f28:	02010113          	addi	sp,sp,32
    1f2c:	00008067          	ret
        if (cnt <= (uint32_t)STRESS_BATCH_HEADROOM) return 0;
    1f30:	00000513          	li	a0,0
    1f34:	fd9ff06f          	j	1f0c <blt_batch_ready+0xb0>
            return -3;                                     /* 引擎长时间不消费：判异常 */
    1f38:	ffd00513          	li	a0,-3
    1f3c:	fd1ff06f          	j	1f0c <blt_batch_ready+0xb0>

00001f40 <blt_wait_frame_done>:
{
    1f40:	fe010113          	addi	sp,sp,-32
    1f44:	00112e23          	sw	ra,28(sp)
    1f48:	00812c23          	sw	s0,24(sp)
    1f4c:	00912a23          	sw	s1,20(sp)
    1f50:	01212823          	sw	s2,16(sp)
    1f54:	01312623          	sw	s3,12(sp)
    1f58:	00050993          	mv	s3,a0
    uint64_t t0 = tick();
    1f5c:	8c5ff0ef          	jal	1820 <tick>
    1f60:	00050913          	mv	s2,a0
    int residual = 0;
    1f64:	00000493          	li	s1,0
    1f68:	0240006f          	j	1f8c <blt_wait_frame_done+0x4c>
            residual++;
    1f6c:	00148493          	addi	s1,s1,1
            if (residual >= STRESS_LOST_N) return -3;
    1f70:	00300793          	li	a5,3
    1f74:	0897c063          	blt	a5,s1,1ff4 <blt_wait_frame_done+0xb4>
            busy_loop(BLT_SETTLE_LOOPS);
    1f78:	0c800513          	li	a0,200
    1f7c:	8c1ff0ef          	jal	183c <busy_loop>
        if ((uint32_t)(tick() - t0) > timeout_ticks) return -1;
    1f80:	8a1ff0ef          	jal	1820 <tick>
    1f84:	41250533          	sub	a0,a0,s2
    1f88:	04a9e263          	bltu	s3,a0,1fcc <blt_wait_frame_done+0x8c>
        st  = blt_rd(BLT_STATUS);
    1f8c:	00400513          	li	a0,4
    1f90:	8fdff0ef          	jal	188c <blt_rd>
    1f94:	00050413          	mv	s0,a0
        cnt = blt_rd(BLT_CMD_FIFO_COUNT);
    1f98:	00c00513          	li	a0,12
    1f9c:	8f1ff0ef          	jal	188c <blt_rd>
        if (st & BLT_STATUS_ERR) return -2;
    1fa0:	00447793          	andi	a5,s0,4
    1fa4:	02079863          	bnez	a5,1fd4 <blt_wait_frame_done+0x94>
        if (st & BLT_STATUS_DONE) {                       /* 引擎 IDLE：只有这里状态稳定 */
    1fa8:	00247793          	andi	a5,s0,2
    1fac:	00078c63          	beqz	a5,1fc4 <blt_wait_frame_done+0x84>
            if (cnt == 0u && (st & BLT_STATUS_FIFO_EMPTY)) return 0;
    1fb0:	fa051ee3          	bnez	a0,1f6c <blt_wait_frame_done+0x2c>
    1fb4:	00847413          	andi	s0,s0,8
    1fb8:	fa040ae3          	beqz	s0,1f6c <blt_wait_frame_done+0x2c>
    1fbc:	00000513          	li	a0,0
    1fc0:	0180006f          	j	1fd8 <blt_wait_frame_done+0x98>
            residual = 0;                                 /* 引擎在跑/POP：状态不稳，不判 */
    1fc4:	00000493          	li	s1,0
    1fc8:	fb9ff06f          	j	1f80 <blt_wait_frame_done+0x40>
        if ((uint32_t)(tick() - t0) > timeout_ticks) return -1;
    1fcc:	fff00513          	li	a0,-1
    1fd0:	0080006f          	j	1fd8 <blt_wait_frame_done+0x98>
        if (st & BLT_STATUS_ERR) return -2;
    1fd4:	ffe00513          	li	a0,-2
}
    1fd8:	01c12083          	lw	ra,28(sp)
    1fdc:	01812403          	lw	s0,24(sp)
    1fe0:	01412483          	lw	s1,20(sp)
    1fe4:	01012903          	lw	s2,16(sp)
    1fe8:	00c12983          	lw	s3,12(sp)
    1fec:	02010113          	addi	sp,sp,32
    1ff0:	00008067          	ret
            if (residual >= STRESS_LOST_N) return -3;
    1ff4:	ffd00513          	li	a0,-3
    1ff8:	fe1ff06f          	j	1fd8 <blt_wait_frame_done+0x98>

00001ffc <blt_frame_begin>:
{
    1ffc:	ff010113          	addi	sp,sp,-16
    2000:	00112623          	sw	ra,12(sp)
    2004:	00812423          	sw	s0,8(sp)
    uint64_t t0 = tick();
    2008:	819ff0ef          	jal	1820 <tick>
    200c:	00050413          	mv	s0,a0
    2010:	00c0006f          	j	201c <blt_frame_begin+0x20>
        busy_loop(BLT_SETTLE_LOOPS);                      /* 采样拉开：等引擎把上一帧做完 */
    2014:	0c800513          	li	a0,200
    2018:	825ff0ef          	jal	183c <busy_loop>
        if (blt_fifo_clean()) return 0;                   /* 稳态干净：直接开帧 */
    201c:	dd9ff0ef          	jal	1df4 <blt_fifo_clean>
    2020:	02051863          	bnez	a0,2050 <blt_frame_begin+0x54>
        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) return -2;
    2024:	00400513          	li	a0,4
    2028:	865ff0ef          	jal	188c <blt_rd>
    202c:	00457513          	andi	a0,a0,4
    2030:	02051a63          	bnez	a0,2064 <blt_frame_begin+0x68>
        if ((uint32_t)(tick() - t0) > (uint32_t)STRESS_FRAME_TO_TICKS) return -1;
    2034:	fecff0ef          	jal	1820 <tick>
    2038:	40850533          	sub	a0,a0,s0
    203c:	02faf7b7          	lui	a5,0x2faf
    2040:	08078793          	addi	a5,a5,128 # 2faf080 <__freertos_irq_stack_top+0x2fa2390>
    2044:	fca7f8e3          	bgeu	a5,a0,2014 <blt_frame_begin+0x18>
    2048:	fff00513          	li	a0,-1
    204c:	0080006f          	j	2054 <blt_frame_begin+0x58>
        if (blt_fifo_clean()) return 0;                   /* 稳态干净：直接开帧 */
    2050:	00000513          	li	a0,0
}
    2054:	00c12083          	lw	ra,12(sp)
    2058:	00812403          	lw	s0,8(sp)
    205c:	01010113          	addi	sp,sp,16
    2060:	00008067          	ret
        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) return -2;
    2064:	ffe00513          	li	a0,-2
    2068:	fedff06f          	j	2054 <blt_frame_begin+0x58>

0000206c <blt_boundary_after_cmd>:
{
    206c:	ff010113          	addi	sp,sp,-16
    2070:	00112623          	sw	ra,12(sp)
    2074:	00812423          	sw	s0,8(sp)
    for (k = 0; k < 4; k++) {                 /* 多次采样，避免撞上 1 拍瞬态 */
    2078:	00000413          	li	s0,0
    207c:	00300793          	li	a5,3
    2080:	0087ce63          	blt	a5,s0,209c <blt_boundary_after_cmd+0x30>
        if (blt_fifo_clean()) return 0;
    2084:	d71ff0ef          	jal	1df4 <blt_fifo_clean>
    2088:	02051463          	bnez	a0,20b0 <blt_boundary_after_cmd+0x44>
        busy_loop(BLT_SETTLE_LOOPS);
    208c:	0c800513          	li	a0,200
    2090:	facff0ef          	jal	183c <busy_loop>
    for (k = 0; k < 4; k++) {                 /* 多次采样，避免撞上 1 拍瞬态 */
    2094:	00140413          	addi	s0,s0,1
    2098:	fe5ff06f          	j	207c <blt_boundary_after_cmd+0x10>
    return -3;
    209c:	ffd00513          	li	a0,-3
}
    20a0:	00c12083          	lw	ra,12(sp)
    20a4:	00812403          	lw	s0,8(sp)
    20a8:	01010113          	addi	sp,sp,16
    20ac:	00008067          	ret
        if (blt_fifo_clean()) return 0;
    20b0:	00000513          	li	a0,0
    20b4:	fedff06f          	j	20a0 <blt_boundary_after_cmd+0x34>

000020b8 <blt_wait_done>:
{
    20b8:	fe010113          	addi	sp,sp,-32
    20bc:	00112e23          	sw	ra,28(sp)
    20c0:	00812c23          	sw	s0,24(sp)
    20c4:	00912a23          	sw	s1,20(sp)
    20c8:	01212823          	sw	s2,16(sp)
    20cc:	01312623          	sw	s3,12(sp)
    20d0:	00050993          	mv	s3,a0
    uint64_t t0 = tick();
    20d4:	f4cff0ef          	jal	1820 <tick>
    20d8:	00050913          	mv	s2,a0
    int seen = 0;
    20dc:	00000493          	li	s1,0
    20e0:	0280006f          	j	2108 <blt_wait_done+0x50>
            seen = 1;                          /* 引擎已接手 / FIFO 还有货 */
    20e4:	00100493          	li	s1,1
    20e8:	0080006f          	j	20f0 <blt_wait_done+0x38>
    20ec:	00100493          	li	s1,1
        el = (uint32_t)(tick() - t0);
    20f0:	f30ff0ef          	jal	1820 <tick>
    20f4:	41250533          	sub	a0,a0,s2
        if (!seen && el > BLT_PICKUP_GUARD) {  /* DONE 已高且等待足够久：认为已完成 */
    20f8:	00049663          	bnez	s1,2104 <blt_wait_done+0x4c>
    20fc:	7d000793          	li	a5,2000
    2100:	04a7e263          	bltu	a5,a0,2144 <blt_wait_done+0x8c>
        if (el > timeout_ticks) return -1;
    2104:	04a9e663          	bltu	s3,a0,2150 <blt_wait_done+0x98>
        st  = blt_rd(BLT_STATUS);
    2108:	00400513          	li	a0,4
    210c:	f80ff0ef          	jal	188c <blt_rd>
    2110:	00050413          	mv	s0,a0
        cnt = blt_rd(BLT_CMD_FIFO_COUNT);
    2114:	00c00513          	li	a0,12
    2118:	f74ff0ef          	jal	188c <blt_rd>
        if (st & BLT_STATUS_ERR) return -2;
    211c:	00447793          	andi	a5,s0,4
    2120:	02079c63          	bnez	a5,2158 <blt_wait_done+0xa0>
        if (!(st & BLT_STATUS_DONE) || cnt != 0u)
    2124:	00247413          	andi	s0,s0,2
    2128:	fa040ee3          	beqz	s0,20e4 <blt_wait_done+0x2c>
    212c:	fc0510e3          	bnez	a0,20ec <blt_wait_done+0x34>
        else if (seen) {
    2130:	fc0480e3          	beqz	s1,20f0 <blt_wait_done+0x38>
            busy_loop(BLT_SETTLE_LOOPS);       /* 让 PERF/STATUS 的跨时钟域同步跟上 */
    2134:	0c800513          	li	a0,200
    2138:	f04ff0ef          	jal	183c <busy_loop>
            return 0;
    213c:	00000493          	li	s1,0
    2140:	01c0006f          	j	215c <blt_wait_done+0xa4>
            busy_loop(BLT_SETTLE_LOOPS);
    2144:	0c800513          	li	a0,200
    2148:	ef4ff0ef          	jal	183c <busy_loop>
            return 0;
    214c:	0100006f          	j	215c <blt_wait_done+0xa4>
        if (el > timeout_ticks) return -1;
    2150:	fff00493          	li	s1,-1
    2154:	0080006f          	j	215c <blt_wait_done+0xa4>
        if (st & BLT_STATUS_ERR) return -2;
    2158:	ffe00493          	li	s1,-2
}
    215c:	00048513          	mv	a0,s1
    2160:	01c12083          	lw	ra,28(sp)
    2164:	01812403          	lw	s0,24(sp)
    2168:	01412483          	lw	s1,20(sp)
    216c:	01012903          	lw	s2,16(sp)
    2170:	00c12983          	lw	s3,12(sp)
    2174:	02010113          	addi	sp,sp,32
    2178:	00008067          	ret

0000217c <push_cmd_fast>:
{
    217c:	fc010113          	addi	sp,sp,-64
    2180:	02112e23          	sw	ra,60(sp)
    2184:	03512223          	sw	s5,36(sp)
    2188:	00078a93          	mv	s5,a5
    if (g_push_err) return;                     /* 本帧已中止：后面一条都不再写 */
    218c:	8501a783          	lw	a5,-1968(gp) # 9710 <g_push_err>
    2190:	12079263          	bnez	a5,22b4 <push_cmd_fast+0x138>
    2194:	02812c23          	sw	s0,56(sp)
    2198:	02912a23          	sw	s1,52(sp)
    219c:	03212823          	sw	s2,48(sp)
    21a0:	03312623          	sw	s3,44(sp)
    21a4:	03412423          	sw	s4,40(sp)
    21a8:	03612023          	sw	s6,32(sp)
    21ac:	01712e23          	sw	s7,28(sp)
    21b0:	00050413          	mv	s0,a0
    21b4:	00058493          	mv	s1,a1
    21b8:	00060913          	mv	s2,a2
    21bc:	00068993          	mv	s3,a3
    21c0:	00070a13          	mv	s4,a4
    21c4:	00080b13          	mv	s6,a6
    21c8:	00088b93          	mv	s7,a7
    if (g_push_batch && !g_push_acct) {
    21cc:	8441a783          	lw	a5,-1980(gp) # 9704 <g_push_batch>
    21d0:	02078463          	beqz	a5,21f8 <push_cmd_fast+0x7c>
    21d4:	8401a783          	lw	a5,-1984(gp) # 9700 <g_push_acct>
    21d8:	02079063          	bnez	a5,21f8 <push_cmd_fast+0x7c>
        if (g_push_left <= 0) {                 /* 批量路径：只在跨批边界查一次 */
    21dc:	8481a783          	lw	a5,-1976(gp) # 9708 <g_push_left>
    21e0:	02f04063          	bgtz	a5,2200 <push_cmd_fast+0x84>
            rc = blt_batch_ready();
    21e4:	c79ff0ef          	jal	1e5c <blt_batch_ready>
            if (rc == 0) g_push_left = STRESS_PUSH_BATCH;
    21e8:	0a051663          	bnez	a0,2294 <push_cmd_fast+0x118>
    21ec:	0a000713          	li	a4,160
    21f0:	84e1a423          	sw	a4,-1976(gp) # 9708 <g_push_left>
    if (rc != 0) { g_push_err = rc; return; }    /* 失败：一个字都没写，边界干净 */
    21f4:	00c0006f          	j	2200 <push_cmd_fast+0x84>
        rc = blt_fifo_room();                   /* 逐条路径/记账帧：写之前查一次空间 */
    21f8:	985ff0ef          	jal	1b7c <blt_fifo_room>
    if (rc != 0) { g_push_err = rc; return; }    /* 失败：一个字都没写，边界干净 */
    21fc:	08051c63          	bnez	a0,2294 <push_cmd_fast+0x118>
    blt_emit_cmd(op, src, dst, sstride, dstride, w, h, alpha, color);
    2200:	04012783          	lw	a5,64(sp)
    2204:	00f12023          	sw	a5,0(sp)
    2208:	000b8893          	mv	a7,s7
    220c:	000b0813          	mv	a6,s6
    2210:	000a8793          	mv	a5,s5
    2214:	000a0713          	mv	a4,s4
    2218:	00098693          	mv	a3,s3
    221c:	00090613          	mv	a2,s2
    2220:	00048593          	mv	a1,s1
    2224:	00040513          	mv	a0,s0
    2228:	9c1ff0ef          	jal	1be8 <blt_emit_cmd>
    if (g_push_batch && !g_push_acct) g_push_left--;
    222c:	8441a703          	lw	a4,-1980(gp) # 9704 <g_push_batch>
    2230:	00070c63          	beqz	a4,2248 <push_cmd_fast+0xcc>
    2234:	8401a783          	lw	a5,-1984(gp) # 9700 <g_push_acct>
    2238:	00079863          	bnez	a5,2248 <push_cmd_fast+0xcc>
    223c:	8481a783          	lw	a5,-1976(gp) # 9708 <g_push_left>
    2240:	fff78793          	addi	a5,a5,-1
    2244:	84f1a423          	sw	a5,-1976(gp) # 9708 <g_push_left>
    g_ins_frame++;
    2248:	8641a783          	lw	a5,-1948(gp) # 9724 <g_ins_frame>
    224c:	00178793          	addi	a5,a5,1
    2250:	86f1a223          	sw	a5,-1948(gp) # 9724 <g_ins_frame>
    g_last_seq = g_ins_frame;
    2254:	86f1a423          	sw	a5,-1944(gp) # 9728 <g_last_seq>
    wait_each = (!g_push_batch || g_push_acct) ? 1 : 0;
    2258:	00070663          	beqz	a4,2264 <push_cmd_fast+0xe8>
    225c:	8401a783          	lw	a5,-1984(gp) # 9700 <g_push_acct>
    2260:	12078463          	beqz	a5,2388 <push_cmd_fast+0x20c>
        rc = blt_wait_done(g_wait_to);
    2264:	8101a503          	lw	a0,-2032(gp) # 96d0 <g_wait_to>
    2268:	e51ff0ef          	jal	20b8 <blt_wait_done>
        if (rc != 0) { g_push_err = rc; return; }
    226c:	04050c63          	beqz	a0,22c4 <push_cmd_fast+0x148>
    2270:	84a1a823          	sw	a0,-1968(gp) # 9710 <g_push_err>
    2274:	03812403          	lw	s0,56(sp)
    2278:	03412483          	lw	s1,52(sp)
    227c:	03012903          	lw	s2,48(sp)
    2280:	02c12983          	lw	s3,44(sp)
    2284:	02812a03          	lw	s4,40(sp)
    2288:	02012b03          	lw	s6,32(sp)
    228c:	01c12b83          	lw	s7,28(sp)
    2290:	0240006f          	j	22b4 <push_cmd_fast+0x138>
    if (rc != 0) { g_push_err = rc; return; }    /* 失败：一个字都没写，边界干净 */
    2294:	84a1a823          	sw	a0,-1968(gp) # 9710 <g_push_err>
    2298:	03812403          	lw	s0,56(sp)
    229c:	03412483          	lw	s1,52(sp)
    22a0:	03012903          	lw	s2,48(sp)
    22a4:	02c12983          	lw	s3,44(sp)
    22a8:	02812a03          	lw	s4,40(sp)
    22ac:	02012b03          	lw	s6,32(sp)
    22b0:	01c12b83          	lw	s7,28(sp)
}
    22b4:	03c12083          	lw	ra,60(sp)
    22b8:	02412a83          	lw	s5,36(sp)
    22bc:	04010113          	addi	sp,sp,64
    22c0:	00008067          	ret
        rc = blt_boundary_after_cmd();          /* 引擎 IDLE 稳态：FIFO 必须整条干净 */
    22c4:	da9ff0ef          	jal	206c <blt_boundary_after_cmd>
        if (rc != 0) { g_push_err = rc; return; }
    22c8:	02051663          	bnez	a0,22f4 <push_cmd_fast+0x178>
        if (g_push_acct) {
    22cc:	8401a783          	lw	a5,-1984(gp) # 9700 <g_push_acct>
    22d0:	04079463          	bnez	a5,2318 <push_cmd_fast+0x19c>
    22d4:	03812403          	lw	s0,56(sp)
    22d8:	03412483          	lw	s1,52(sp)
    22dc:	03012903          	lw	s2,48(sp)
    22e0:	02c12983          	lw	s3,44(sp)
    22e4:	02812a03          	lw	s4,40(sp)
    22e8:	02012b03          	lw	s6,32(sp)
    22ec:	01c12b83          	lw	s7,28(sp)
    22f0:	fc5ff06f          	j	22b4 <push_cmd_fast+0x138>
        if (rc != 0) { g_push_err = rc; return; }
    22f4:	84a1a823          	sw	a0,-1968(gp) # 9710 <g_push_err>
    22f8:	03812403          	lw	s0,56(sp)
    22fc:	03412483          	lw	s1,52(sp)
    2300:	03012903          	lw	s2,48(sp)
    2304:	02c12983          	lw	s3,44(sp)
    2308:	02812a03          	lw	s4,40(sp)
    230c:	02012b03          	lw	s6,32(sp)
    2310:	01c12b83          	lw	s7,28(sp)
    2314:	fa1ff06f          	j	22b4 <push_cmd_fast+0x138>
            uint32_t p = blt_rd(BLT_PERF);
    2318:	01c00513          	li	a0,28
    231c:	d70ff0ef          	jal	188c <blt_rd>
            if (p == 0u) g_perf_zero++;
    2320:	02051863          	bnez	a0,2350 <push_cmd_fast+0x1d4>
    2324:	8341a783          	lw	a5,-1996(gp) # 96f4 <g_perf_zero>
    2328:	00178793          	addi	a5,a5,1
    232c:	82f1aa23          	sw	a5,-1996(gp) # 96f4 <g_perf_zero>
    2330:	03812403          	lw	s0,56(sp)
    2334:	03412483          	lw	s1,52(sp)
    2338:	03012903          	lw	s2,48(sp)
    233c:	02c12983          	lw	s3,44(sp)
    2340:	02812a03          	lw	s4,40(sp)
    2344:	02012b03          	lw	s6,32(sp)
    2348:	01c12b83          	lw	s7,28(sp)
    234c:	f69ff06f          	j	22b4 <push_cmd_fast+0x138>
            else { g_perf_sum += p; g_perf_good++; }
    2350:	83c1a783          	lw	a5,-1988(gp) # 96fc <g_perf_sum>
    2354:	00a787b3          	add	a5,a5,a0
    2358:	82f1ae23          	sw	a5,-1988(gp) # 96fc <g_perf_sum>
    235c:	8381a783          	lw	a5,-1992(gp) # 96f8 <g_perf_good>
    2360:	00178793          	addi	a5,a5,1
    2364:	82f1ac23          	sw	a5,-1992(gp) # 96f8 <g_perf_good>
    2368:	03812403          	lw	s0,56(sp)
    236c:	03412483          	lw	s1,52(sp)
    2370:	03012903          	lw	s2,48(sp)
    2374:	02c12983          	lw	s3,44(sp)
    2378:	02812a03          	lw	s4,40(sp)
    237c:	02012b03          	lw	s6,32(sp)
    2380:	01c12b83          	lw	s7,28(sp)
    2384:	f31ff06f          	j	22b4 <push_cmd_fast+0x138>
    2388:	03812403          	lw	s0,56(sp)
    238c:	03412483          	lw	s1,52(sp)
    2390:	03012903          	lw	s2,48(sp)
    2394:	02c12983          	lw	s3,44(sp)
    2398:	02812a03          	lw	s4,40(sp)
    239c:	02012b03          	lw	s6,32(sp)
    23a0:	01c12b83          	lw	s7,28(sp)
    23a4:	f11ff06f          	j	22b4 <push_cmd_fast+0x138>

000023a8 <blt_op>:
{
    23a8:	fc010113          	addi	sp,sp,-64
    23ac:	02112e23          	sw	ra,60(sp)
    23b0:	02812c23          	sw	s0,56(sp)
    23b4:	02912a23          	sw	s1,52(sp)
    23b8:	03212823          	sw	s2,48(sp)
    23bc:	03312623          	sw	s3,44(sp)
    23c0:	03412423          	sw	s4,40(sp)
    23c4:	03512223          	sw	s5,36(sp)
    23c8:	03612023          	sw	s6,32(sp)
    23cc:	01712e23          	sw	s7,28(sp)
    23d0:	01812c23          	sw	s8,24(sp)
    23d4:	00050413          	mv	s0,a0
    23d8:	00058913          	mv	s2,a1
    23dc:	00060993          	mv	s3,a2
    23e0:	00068a13          	mv	s4,a3
    23e4:	00070a93          	mv	s5,a4
    23e8:	00078b13          	mv	s6,a5
    23ec:	00080b93          	mv	s7,a6
    23f0:	00088c13          	mv	s8,a7
    uint64_t t0 = tick();
    23f4:	c2cff0ef          	jal	1820 <tick>
    23f8:	00050493          	mv	s1,a0
    g_scene_ctx = 0;
    23fc:	8401aa23          	sw	zero,-1964(gp) # 9714 <g_scene_ctx>
    g_ins_frame = 0;
    2400:	8601a223          	sw	zero,-1948(gp) # 9724 <g_ins_frame>
    g_last_seq  = 0;
    2404:	8601a423          	sw	zero,-1944(gp) # 9728 <g_last_seq>
    rc = blt_push_cmd(op, src, dst, ss, ds, w, h, alpha, color);   /* 内含 FIFO 空间检查 */
    2408:	04012783          	lw	a5,64(sp)
    240c:	00f12023          	sw	a5,0(sp)
    2410:	000c0893          	mv	a7,s8
    2414:	000b8813          	mv	a6,s7
    2418:	000b0793          	mv	a5,s6
    241c:	000a8713          	mv	a4,s5
    2420:	000a0693          	mv	a3,s4
    2424:	00098613          	mv	a2,s3
    2428:	00090593          	mv	a1,s2
    242c:	00040513          	mv	a0,s0
    2430:	8e9ff0ef          	jal	1d18 <blt_push_cmd>
    2434:	00050413          	mv	s0,a0
    if (rc == 0) { g_ins_frame = 1; g_last_seq = 1; }
    2438:	04050863          	beqz	a0,2488 <blt_op+0xe0>
    ec = (uint32_t)(tick() - t0);
    243c:	be4ff0ef          	jal	1820 <tick>
    2440:	40950533          	sub	a0,a0,s1
    g_opticks = ec;
    2444:	86a1a623          	sw	a0,-1940(gp) # 972c <g_opticks>
    g_perf    = (rc == 0) ? blt_rd(BLT_PERF) : 0u;
    2448:	04040e63          	beqz	s0,24a4 <blt_op+0xfc>
    244c:	00000513          	li	a0,0
    2450:	86a1a823          	sw	a0,-1936(gp) # 9730 <g_perf>
}
    2454:	00040513          	mv	a0,s0
    2458:	03c12083          	lw	ra,60(sp)
    245c:	03812403          	lw	s0,56(sp)
    2460:	03412483          	lw	s1,52(sp)
    2464:	03012903          	lw	s2,48(sp)
    2468:	02c12983          	lw	s3,44(sp)
    246c:	02812a03          	lw	s4,40(sp)
    2470:	02412a83          	lw	s5,36(sp)
    2474:	02012b03          	lw	s6,32(sp)
    2478:	01c12b83          	lw	s7,28(sp)
    247c:	01812c03          	lw	s8,24(sp)
    2480:	04010113          	addi	sp,sp,64
    2484:	00008067          	ret
    if (rc == 0) { g_ins_frame = 1; g_last_seq = 1; }
    2488:	00100793          	li	a5,1
    248c:	86f1a223          	sw	a5,-1948(gp) # 9724 <g_ins_frame>
    2490:	86f1a423          	sw	a5,-1944(gp) # 9728 <g_last_seq>
    if (rc == 0) rc = blt_wait_done(g_wait_to);
    2494:	8101a503          	lw	a0,-2032(gp) # 96d0 <g_wait_to>
    2498:	c21ff0ef          	jal	20b8 <blt_wait_done>
    249c:	00050413          	mv	s0,a0
    24a0:	f9dff06f          	j	243c <blt_op+0x94>
    g_perf    = (rc == 0) ? blt_rd(BLT_PERF) : 0u;
    24a4:	01c00513          	li	a0,28
    24a8:	be4ff0ef          	jal	188c <blt_rd>
    24ac:	fa5ff06f          	j	2450 <blt_op+0xa8>

000024b0 <blt_fill>:
{
    24b0:	fe010113          	addi	sp,sp,-32
    24b4:	00112e23          	sw	ra,28(sp)
    24b8:	00060793          	mv	a5,a2
    return blt_op(BLT_OP_FILL, 0u, dst, 0u, dstride, w, h, 0xFFu, color);
    24bc:	00e12023          	sw	a4,0(sp)
    24c0:	0ff00893          	li	a7,255
    24c4:	00068813          	mv	a6,a3
    24c8:	00058713          	mv	a4,a1
    24cc:	00000693          	li	a3,0
    24d0:	00050613          	mv	a2,a0
    24d4:	00000593          	li	a1,0
    24d8:	00100513          	li	a0,1
    24dc:	ecdff0ef          	jal	23a8 <blt_op>
}
    24e0:	01c12083          	lw	ra,28(sp)
    24e4:	02010113          	addi	sp,sp,32
    24e8:	00008067          	ret

000024ec <blt_copy>:
{
    24ec:	fe010113          	addi	sp,sp,-32
    24f0:	00112e23          	sw	ra,28(sp)
    return blt_op(BLT_OP_COPY, src, dst, sstride, dstride, w, h, 0xFFu, 0u);
    24f4:	00012023          	sw	zero,0(sp)
    24f8:	0ff00893          	li	a7,255
    24fc:	00078813          	mv	a6,a5
    2500:	00070793          	mv	a5,a4
    2504:	00068713          	mv	a4,a3
    2508:	00060693          	mv	a3,a2
    250c:	00058613          	mv	a2,a1
    2510:	00050593          	mv	a1,a0
    2514:	00000513          	li	a0,0
    2518:	e91ff0ef          	jal	23a8 <blt_op>
}
    251c:	01c12083          	lw	ra,28(sp)
    2520:	02010113          	addi	sp,sp,32
    2524:	00008067          	ret

00002528 <blt_key>:
{
    2528:	fe010113          	addi	sp,sp,-32
    252c:	00112e23          	sw	ra,28(sp)
    return blt_op(BLT_OP_KEY, src, dst, sstride, dstride, w, h, 0xFFu, key);
    2530:	01012023          	sw	a6,0(sp)
    2534:	0ff00893          	li	a7,255
    2538:	00078813          	mv	a6,a5
    253c:	00070793          	mv	a5,a4
    2540:	00068713          	mv	a4,a3
    2544:	00060693          	mv	a3,a2
    2548:	00058613          	mv	a2,a1
    254c:	00050593          	mv	a1,a0
    2550:	00300513          	li	a0,3
    2554:	e55ff0ef          	jal	23a8 <blt_op>
}
    2558:	01c12083          	lw	ra,28(sp)
    255c:	02010113          	addi	sp,sp,32
    2560:	00008067          	ret

00002564 <blt_alpha>:
{
    2564:	fe010113          	addi	sp,sp,-32
    2568:	00112e23          	sw	ra,28(sp)
    return blt_op(BLT_OP_ALPHA, src, dst, sstride, dstride, w, h, alpha, 0u);
    256c:	00012023          	sw	zero,0(sp)
    2570:	00080893          	mv	a7,a6
    2574:	00078813          	mv	a6,a5
    2578:	00070793          	mv	a5,a4
    257c:	00068713          	mv	a4,a3
    2580:	00060693          	mv	a3,a2
    2584:	00058613          	mv	a2,a1
    2588:	00050593          	mv	a1,a0
    258c:	00200513          	li	a0,2
    2590:	e19ff0ef          	jal	23a8 <blt_op>
}
    2594:	01c12083          	lw	ra,28(sp)
    2598:	02010113          	addi	sp,sp,32
    259c:	00008067          	ret

000025a0 <frame_throttle>:
    if (!g_tb_ok) return;
    25a0:	8141a783          	lw	a5,-2028(gp) # 96d4 <g_tb_ok>
    25a4:	04078a63          	beqz	a5,25f8 <frame_throttle+0x58>
{
    25a8:	ff010113          	addi	sp,sp,-16
    25ac:	00112623          	sw	ra,12(sp)
    25b0:	00812423          	sw	s0,8(sp)
    25b4:	00912223          	sw	s1,4(sp)
    25b8:	00050493          	mv	s1,a0
    uint32_t guard = 0;
    25bc:	00000413          	li	s0,0
    while ((uint32_t)(tick() - t_frame) < FRAME_TICKS) {
    25c0:	a60ff0ef          	jal	1820 <tick>
    25c4:	40950533          	sub	a0,a0,s1
    25c8:	001977b7          	lui	a5,0x197
    25cc:	e6978793          	addi	a5,a5,-407 # 196e69 <__freertos_irq_stack_top+0x18a179>
    25d0:	00a7ea63          	bltu	a5,a0,25e4 <frame_throttle+0x44>
        if (++guard > 20000000UL) break;      /* 兜底：时间基准抽风也不死等 */
    25d4:	00140413          	addi	s0,s0,1
    25d8:	013137b7          	lui	a5,0x1313
    25dc:	d0078793          	addi	a5,a5,-768 # 1312d00 <__freertos_irq_stack_top+0x1306010>
    25e0:	fe87f0e3          	bgeu	a5,s0,25c0 <frame_throttle+0x20>
}
    25e4:	00c12083          	lw	ra,12(sp)
    25e8:	00812403          	lw	s0,8(sp)
    25ec:	00412483          	lw	s1,4(sp)
    25f0:	01010113          	addi	sp,sp,16
    25f4:	00008067          	ret
    25f8:	00008067          	ret

000025fc <coherency_check>:
{
    25fc:	ff010113          	addi	sp,sp,-16
    2600:	00112623          	sw	ra,12(sp)
    for (i = 0; i < 256u; i++) p[i] = 0x5A5A0000UL + i;
    2604:	00000793          	li	a5,0
    2608:	0200006f          	j	2628 <coherency_check+0x2c>
    260c:	00279693          	slli	a3,a5,0x2
    2610:	00401737          	lui	a4,0x401
    2614:	00d70733          	add	a4,a4,a3
    2618:	5a5a06b7          	lui	a3,0x5a5a0
    261c:	00d786b3          	add	a3,a5,a3
    2620:	00d72023          	sw	a3,0(a4) # 401000 <__freertos_irq_stack_top+0x3f4310>
    2624:	00178793          	addi	a5,a5,1
    2628:	0ff00713          	li	a4,255
    262c:	fef770e3          	bgeu	a4,a5,260c <coherency_check+0x10>
    cache_evict();
    2630:	b30ff0ef          	jal	1960 <cache_evict>
    cache_invalidate();
    2634:	b8cff0ef          	jal	19c0 <cache_invalidate>
    for (i = 0; i < 256u; i++)
    2638:	00000793          	li	a5,0
    263c:	0ff00713          	li	a4,255
    2640:	02f76c63          	bltu	a4,a5,2678 <coherency_check+0x7c>
        if (p[i] != (0x5A5A0000UL + i)) return (int)(i + 1u);
    2644:	00279693          	slli	a3,a5,0x2
    2648:	00401737          	lui	a4,0x401
    264c:	00d70733          	add	a4,a4,a3
    2650:	00072683          	lw	a3,0(a4) # 401000 <__freertos_irq_stack_top+0x3f4310>
    2654:	5a5a0737          	lui	a4,0x5a5a0
    2658:	00e78733          	add	a4,a5,a4
    265c:	00e69663          	bne	a3,a4,2668 <coherency_check+0x6c>
    for (i = 0; i < 256u; i++)
    2660:	00178793          	addi	a5,a5,1
    2664:	fd9ff06f          	j	263c <coherency_check+0x40>
        if (p[i] != (0x5A5A0000UL + i)) return (int)(i + 1u);
    2668:	00178513          	addi	a0,a5,1
}
    266c:	00c12083          	lw	ra,12(sp)
    2670:	01010113          	addi	sp,sp,16
    2674:	00008067          	ret
    return 0;
    2678:	00000513          	li	a0,0
    267c:	ff1ff06f          	j	266c <coherency_check+0x70>

00002680 <stress_prepare>:
    for (i = 0; i < n; i++) {
    2680:	00000693          	li	a3,0
    2684:	0cc0006f          	j	2750 <stress_prepare+0xd0>
        int sl = i & (STRESS_NSLOT - 1);
    2688:	0076f713          	andi	a4,a3,7
        int w  = (int)s_sprw[sl];
    268c:	000097b7          	lui	a5,0x9
    2690:	00171713          	slli	a4,a4,0x1
    2694:	6bc78793          	addi	a5,a5,1724 # 96bc <s_sprw>
    2698:	00e787b3          	add	a5,a5,a4
    269c:	0007d783          	lhu	a5,0(a5)
        int maxx = FB_WIDTH - w;
    26a0:	3c000713          	li	a4,960
    26a4:	40f70733          	sub	a4,a4,a5
        sp_x[i]  = (int16_t)((uint32_t)(i * 61) % (uint32_t)maxx);
    26a8:	00469793          	slli	a5,a3,0x4
    26ac:	40d787b3          	sub	a5,a5,a3
    26b0:	00279793          	slli	a5,a5,0x2
    26b4:	00d787b3          	add	a5,a5,a3
    26b8:	02e7f7b3          	remu	a5,a5,a4
    26bc:	01079793          	slli	a5,a5,0x10
    26c0:	4107d793          	srai	a5,a5,0x10
    26c4:	0000b737          	lui	a4,0xb
    26c8:	00169613          	slli	a2,a3,0x1
    26cc:	68470713          	addi	a4,a4,1668 # b684 <sp_x>
    26d0:	00c70733          	add	a4,a4,a2
    26d4:	00f71023          	sh	a5,0(a4)
        sp_y0[i] = (int16_t)(24u + (uint32_t)(i * 53) % 468u);
    26d8:	03500713          	li	a4,53
    26dc:	02e68733          	mul	a4,a3,a4
    26e0:	1d400593          	li	a1,468
    26e4:	02b77733          	remu	a4,a4,a1
    26e8:	01870713          	addi	a4,a4,24
    26ec:	ec418593          	addi	a1,gp,-316 # 9d84 <sp_y0>
    26f0:	00c585b3          	add	a1,a1,a2
    26f4:	00e59023          	sh	a4,0(a1)
        sp_y[i]  = sp_y0[i];
    26f8:	0000b5b7          	lui	a1,0xb
    26fc:	04458593          	addi	a1,a1,68 # b044 <sp_y>
    2700:	00c585b3          	add	a1,a1,a2
    2704:	00e59023          	sh	a4,0(a1)
        sp_vx[i] = (int8_t)(1 + (i & 3));
    2708:	0036f813          	andi	a6,a3,3
    270c:	00180813          	addi	a6,a6,1
    2710:	ba418593          	addi	a1,gp,-1116 # 9a64 <sp_vx>
    2714:	00d585b3          	add	a1,a1,a3
    2718:	01058023          	sb	a6,0(a1)
        sp_seen[i] = 0;
    271c:	000095b7          	lui	a1,0x9
    2720:	74458593          	addi	a1,a1,1860 # 9744 <sp_seen>
    2724:	00d585b3          	add	a1,a1,a3
    2728:	00058023          	sb	zero,0(a1)
        sp_px[i] = sp_x[i];
    272c:	0000b5b7          	lui	a1,0xb
    2730:	a0458593          	addi	a1,a1,-1532 # aa04 <sp_px>
    2734:	00c585b3          	add	a1,a1,a2
    2738:	00f59023          	sh	a5,0(a1)
        sp_py[i] = sp_y[i];
    273c:	0000a7b7          	lui	a5,0xa
    2740:	3c478793          	addi	a5,a5,964 # a3c4 <sp_py>
    2744:	00c787b3          	add	a5,a5,a2
    2748:	00e79023          	sh	a4,0(a5)
    for (i = 0; i < n; i++) {
    274c:	00168693          	addi	a3,a3,1 # 5a5a0001 <__freertos_irq_stack_top+0x5a593311>
    2750:	f2a6cce3          	blt	a3,a0,2688 <stress_prepare+0x8>
}
    2754:	00008067          	ret

00002758 <spr_move>:
    int sl   = i & (STRESS_NSLOT - 1);
    2758:	00757713          	andi	a4,a0,7
    int w    = (int)s_sprw[sl];
    275c:	000097b7          	lui	a5,0x9
    2760:	00171713          	slli	a4,a4,0x1
    2764:	6bc78793          	addi	a5,a5,1724 # 96bc <s_sprw>
    2768:	00e787b3          	add	a5,a5,a4
    276c:	0007d683          	lhu	a3,0(a5)
    int maxx = FB_WIDTH - w;
    2770:	3c000793          	li	a5,960
    2774:	40d786b3          	sub	a3,a5,a3
    int maxy = FB_HEIGHT - (int)s_sprh[sl];
    2778:	000097b7          	lui	a5,0x9
    277c:	6ac78793          	addi	a5,a5,1708 # 96ac <s_sprh>
    2780:	00e787b3          	add	a5,a5,a4
    2784:	0007d783          	lhu	a5,0(a5)
    2788:	21c00613          	li	a2,540
    278c:	40f60633          	sub	a2,a2,a5
    nx = (int)sp_x[i] + (int)sp_vx[i];
    2790:	0000b7b7          	lui	a5,0xb
    2794:	00151713          	slli	a4,a0,0x1
    2798:	68478793          	addi	a5,a5,1668 # b684 <sp_x>
    279c:	00e787b3          	add	a5,a5,a4
    27a0:	00079783          	lh	a5,0(a5)
    27a4:	ba418713          	addi	a4,gp,-1116 # 9a64 <sp_vx>
    27a8:	00a70733          	add	a4,a4,a0
    27ac:	00070703          	lb	a4,0(a4)
    27b0:	00e787b3          	add	a5,a5,a4
    if (nx < 0)              { nx = 0;    sp_vx[i] = (int8_t)(-(int)sp_vx[i]); }
    27b4:	0207c263          	bltz	a5,27d8 <spr_move+0x80>
    else if (nx > maxx)      { nx = maxx; sp_vx[i] = (int8_t)(-(int)sp_vx[i]); }
    27b8:	02f6dc63          	bge	a3,a5,27f0 <spr_move+0x98>
    27bc:	0ff77713          	zext.b	a4,a4
    27c0:	40e00733          	neg	a4,a4
    27c4:	ba418793          	addi	a5,gp,-1116 # 9a64 <sp_vx>
    27c8:	00a787b3          	add	a5,a5,a0
    27cc:	00e78023          	sb	a4,0(a5)
    27d0:	00068793          	mv	a5,a3
    27d4:	01c0006f          	j	27f0 <spr_move+0x98>
    if (nx < 0)              { nx = 0;    sp_vx[i] = (int8_t)(-(int)sp_vx[i]); }
    27d8:	0ff77713          	zext.b	a4,a4
    27dc:	40e00733          	neg	a4,a4
    27e0:	ba418793          	addi	a5,gp,-1116 # 9a64 <sp_vx>
    27e4:	00a787b3          	add	a5,a5,a0
    27e8:	00e78023          	sb	a4,0(a5)
    27ec:	00000793          	li	a5,0
    sp_x[i] = (int16_t)nx;
    27f0:	0000b737          	lui	a4,0xb
    27f4:	00151693          	slli	a3,a0,0x1
    27f8:	68470713          	addi	a4,a4,1668 # b684 <sp_x>
    27fc:	00d70733          	add	a4,a4,a3
    2800:	00f71023          	sh	a5,0(a4)
    off = (int)(((int32_t)sin_tab[((uint32_t)f * 2u + (uint32_t)i * 11u) & 63u] * 20) >> 7);
    2804:	00159593          	slli	a1,a1,0x1
    2808:	00a687b3          	add	a5,a3,a0
    280c:	00279793          	slli	a5,a5,0x2
    2810:	40a787b3          	sub	a5,a5,a0
    2814:	00f585b3          	add	a1,a1,a5
    2818:	03f5f593          	andi	a1,a1,63
    281c:	000097b7          	lui	a5,0x9
    2820:	00159593          	slli	a1,a1,0x1
    2824:	61c78793          	addi	a5,a5,1564 # 961c <sin_tab>
    2828:	00b787b3          	add	a5,a5,a1
    282c:	00079703          	lh	a4,0(a5)
    2830:	00271793          	slli	a5,a4,0x2
    2834:	00e787b3          	add	a5,a5,a4
    2838:	4057d793          	srai	a5,a5,0x5
    ny  = (int)sp_y0[i] + off;
    283c:	ec418713          	addi	a4,gp,-316 # 9d84 <sp_y0>
    2840:	00d70733          	add	a4,a4,a3
    2844:	00071703          	lh	a4,0(a4)
    2848:	00f707b3          	add	a5,a4,a5
    if (ny < 0)         ny = 0;
    284c:	0007c863          	bltz	a5,285c <spr_move+0x104>
    else if (ny > maxy) ny = maxy;
    2850:	00f64863          	blt	a2,a5,2860 <spr_move+0x108>
    ny  = (int)sp_y0[i] + off;
    2854:	00078613          	mv	a2,a5
    2858:	0080006f          	j	2860 <spr_move+0x108>
    if (ny < 0)         ny = 0;
    285c:	00000613          	li	a2,0
    sp_y[i] = (int16_t)ny;
    2860:	0000b7b7          	lui	a5,0xb
    2864:	00151513          	slli	a0,a0,0x1
    2868:	04478793          	addi	a5,a5,68 # b044 <sp_y>
    286c:	00a787b3          	add	a5,a5,a0
    2870:	00c79023          	sh	a2,0(a5)
}
    2874:	00008067          	ret

00002878 <spr_emit>:
{
    2878:	fc010113          	addi	sp,sp,-64
    287c:	02112e23          	sw	ra,60(sp)
    2880:	02812c23          	sw	s0,56(sp)
    2884:	02912a23          	sw	s1,52(sp)
    2888:	03212823          	sw	s2,48(sp)
    288c:	03312623          	sw	s3,44(sp)
    2890:	03412423          	sw	s4,40(sp)
    2894:	03512223          	sw	s5,36(sp)
    2898:	03612023          	sw	s6,32(sp)
    289c:	01712e23          	sw	s7,28(sp)
    28a0:	01812c23          	sw	s8,24(sp)
    28a4:	00050413          	mv	s0,a0
    int sl  = i & (STRESS_NSLOT - 1);
    28a8:	00757493          	andi	s1,a0,7
    int w   = (int)s_sprw[sl];
    28ac:	000097b7          	lui	a5,0x9
    28b0:	00149713          	slli	a4,s1,0x1
    28b4:	6bc78793          	addi	a5,a5,1724 # 96bc <s_sprw>
    28b8:	00e787b3          	add	a5,a5,a4
    28bc:	0007d983          	lhu	s3,0(a5)
    int h   = (int)s_sprh[sl];
    28c0:	000097b7          	lui	a5,0x9
    28c4:	6ac78793          	addi	a5,a5,1708 # 96ac <s_sprh>
    28c8:	00e787b3          	add	a5,a5,a4
    28cc:	0007da03          	lhu	s4,0(a5)
    uint32_t src = SA_ATLAS + (uint32_t)sl * ATLAS_SLOT;
    28d0:	22248913          	addi	s2,s1,546
    28d4:	00b91913          	slli	s2,s2,0xb
    int ox = (int)sp_px[i], oy = (int)sp_py[i];
    28d8:	0000b7b7          	lui	a5,0xb
    28dc:	00151c13          	slli	s8,a0,0x1
    28e0:	a0478793          	addi	a5,a5,-1532 # aa04 <sp_px>
    28e4:	018787b3          	add	a5,a5,s8
    28e8:	00079b83          	lh	s7,0(a5)
    28ec:	0000a7b7          	lui	a5,0xa
    28f0:	3c478793          	addi	a5,a5,964 # a3c4 <sp_py>
    28f4:	018787b3          	add	a5,a5,s8
    28f8:	00079b03          	lh	s6,0(a5)
    spr_move(i, f);                       /* 用旧位置判反向 -> 更新 sp_x/sp_y */
    28fc:	e5dff0ef          	jal	2758 <spr_move>
    nx = (int)sp_x[i];
    2900:	0000b7b7          	lui	a5,0xb
    2904:	68478793          	addi	a5,a5,1668 # b684 <sp_x>
    2908:	018787b3          	add	a5,a5,s8
    290c:	00079a83          	lh	s5,0(a5)
    ny = (int)sp_y[i];
    2910:	0000b7b7          	lui	a5,0xb
    2914:	04478793          	addi	a5,a5,68 # b044 <sp_y>
    2918:	018787b3          	add	a5,a5,s8
    291c:	00079c03          	lh	s8,0(a5)
    if (sp_seen[i]) {                     /* 擦旧矩形 */
    2920:	000097b7          	lui	a5,0x9
    2924:	74478793          	addi	a5,a5,1860 # 9744 <sp_seen>
    2928:	008787b3          	add	a5,a5,s0
    292c:	0007c783          	lbu	a5,0(a5)
    2930:	0e079463          	bnez	a5,2a18 <spr_emit+0x1a0>
    if (s_spra[sl])
    2934:	82018793          	addi	a5,gp,-2016 # 96e0 <s_spra>
    2938:	009787b3          	add	a5,a5,s1
    293c:	0007c783          	lbu	a5,0(a5)
    2940:	12078663          	beqz	a5,2a6c <spr_emit+0x1f4>
        push_cmd_fast(BLT_OP_ALPHA, src, PIX(FB_BASE, FB_STRIDE, nx, ny), ATLAS_STRIDE, FB_STRIDE,
    2944:	004c1613          	slli	a2,s8,0x4
    2948:	41860633          	sub	a2,a2,s8
    294c:	00661613          	slli	a2,a2,0x6
    2950:	01560633          	add	a2,a2,s5
    2954:	001817b7          	lui	a5,0x181
    2958:	80078793          	addi	a5,a5,-2048 # 180800 <__freertos_irq_stack_top+0x173b10>
    295c:	00f60633          	add	a2,a2,a5
    2960:	00012023          	sw	zero,0(sp)
    2964:	0a000893          	li	a7,160
    2968:	000a0813          	mv	a6,s4
    296c:	00098793          	mv	a5,s3
    2970:	78000713          	li	a4,1920
    2974:	04000693          	li	a3,64
    2978:	00161613          	slli	a2,a2,0x1
    297c:	00090593          	mv	a1,s2
    2980:	00200513          	li	a0,2
    2984:	ff8ff0ef          	jal	217c <push_cmd_fast>
    if (g_push_err) return g_push_err;
    2988:	8501a503          	lw	a0,-1968(gp) # 9710 <g_push_err>
    298c:	04051e63          	bnez	a0,29e8 <spr_emit+0x170>
    sp_px[i] = sp_x[i];
    2990:	0000b7b7          	lui	a5,0xb
    2994:	00141713          	slli	a4,s0,0x1
    2998:	68478793          	addi	a5,a5,1668 # b684 <sp_x>
    299c:	00e787b3          	add	a5,a5,a4
    29a0:	00079683          	lh	a3,0(a5)
    29a4:	0000b7b7          	lui	a5,0xb
    29a8:	a0478793          	addi	a5,a5,-1532 # aa04 <sp_px>
    29ac:	00e787b3          	add	a5,a5,a4
    29b0:	00d79023          	sh	a3,0(a5)
    sp_py[i] = sp_y[i];
    29b4:	0000b7b7          	lui	a5,0xb
    29b8:	04478793          	addi	a5,a5,68 # b044 <sp_y>
    29bc:	00e787b3          	add	a5,a5,a4
    29c0:	00079683          	lh	a3,0(a5)
    29c4:	0000a7b7          	lui	a5,0xa
    29c8:	3c478793          	addi	a5,a5,964 # a3c4 <sp_py>
    29cc:	00e787b3          	add	a5,a5,a4
    29d0:	00d79023          	sh	a3,0(a5)
    sp_seen[i] = 1;
    29d4:	000097b7          	lui	a5,0x9
    29d8:	74478793          	addi	a5,a5,1860 # 9744 <sp_seen>
    29dc:	008787b3          	add	a5,a5,s0
    29e0:	00100713          	li	a4,1
    29e4:	00e78023          	sb	a4,0(a5)
}
    29e8:	03c12083          	lw	ra,60(sp)
    29ec:	03812403          	lw	s0,56(sp)
    29f0:	03412483          	lw	s1,52(sp)
    29f4:	03012903          	lw	s2,48(sp)
    29f8:	02c12983          	lw	s3,44(sp)
    29fc:	02812a03          	lw	s4,40(sp)
    2a00:	02412a83          	lw	s5,36(sp)
    2a04:	02012b03          	lw	s6,32(sp)
    2a08:	01c12b83          	lw	s7,28(sp)
    2a0c:	01812c03          	lw	s8,24(sp)
    2a10:	04010113          	addi	sp,sp,64
    2a14:	00008067          	ret
        push_cmd_fast(BLT_OP_FILL, 0u, PIX(FB_BASE, FB_STRIDE, ox, oy), 0u, FB_STRIDE,
    2a18:	004b1613          	slli	a2,s6,0x4
    2a1c:	41660633          	sub	a2,a2,s6
    2a20:	00661613          	slli	a2,a2,0x6
    2a24:	01760633          	add	a2,a2,s7
    2a28:	001817b7          	lui	a5,0x181
    2a2c:	80078793          	addi	a5,a5,-2048 # 180800 <__freertos_irq_stack_top+0x173b10>
    2a30:	00f60633          	add	a2,a2,a5
    2a34:	01000793          	li	a5,16
    2a38:	00f12023          	sw	a5,0(sp)
    2a3c:	0ff00893          	li	a7,255
    2a40:	000a0813          	mv	a6,s4
    2a44:	00098793          	mv	a5,s3
    2a48:	78000713          	li	a4,1920
    2a4c:	00000693          	li	a3,0
    2a50:	00161613          	slli	a2,a2,0x1
    2a54:	00000593          	li	a1,0
    2a58:	00100513          	li	a0,1
    2a5c:	f20ff0ef          	jal	217c <push_cmd_fast>
        if (g_push_err) return g_push_err;
    2a60:	8501a503          	lw	a0,-1968(gp) # 9710 <g_push_err>
    2a64:	ec0508e3          	beqz	a0,2934 <spr_emit+0xbc>
    2a68:	f81ff06f          	j	29e8 <spr_emit+0x170>
        push_cmd_fast(BLT_OP_KEY, src, PIX(FB_BASE, FB_STRIDE, nx, ny), ATLAS_STRIDE, FB_STRIDE,
    2a6c:	004c1613          	slli	a2,s8,0x4
    2a70:	41860633          	sub	a2,a2,s8
    2a74:	00661613          	slli	a2,a2,0x6
    2a78:	01560633          	add	a2,a2,s5
    2a7c:	001817b7          	lui	a5,0x181
    2a80:	80078793          	addi	a5,a5,-2048 # 180800 <__freertos_irq_stack_top+0x173b10>
    2a84:	00f60633          	add	a2,a2,a5
    2a88:	000107b7          	lui	a5,0x10
    2a8c:	81f78793          	addi	a5,a5,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    2a90:	00f12023          	sw	a5,0(sp)
    2a94:	0ff00893          	li	a7,255
    2a98:	000a0813          	mv	a6,s4
    2a9c:	00098793          	mv	a5,s3
    2aa0:	78000713          	li	a4,1920
    2aa4:	04000693          	li	a3,64
    2aa8:	00161613          	slli	a2,a2,0x1
    2aac:	00090593          	mv	a1,s2
    2ab0:	00300513          	li	a0,3
    2ab4:	ec8ff0ef          	jal	217c <push_cmd_fast>
    2ab8:	ed1ff06f          	j	2988 <spr_emit+0x110>

00002abc <stress_frame>:
{
    2abc:	fc010113          	addi	sp,sp,-64
    2ac0:	02112e23          	sw	ra,60(sp)
    2ac4:	02812c23          	sw	s0,56(sp)
    2ac8:	03212823          	sw	s2,48(sp)
    2acc:	03312623          	sw	s3,44(sp)
    2ad0:	03412423          	sw	s4,40(sp)
    2ad4:	03512223          	sw	s5,36(sp)
    2ad8:	03612023          	sw	s6,32(sp)
    2adc:	01712e23          	sw	s7,28(sp)
    2ae0:	00050913          	mv	s2,a0
    2ae4:	00058993          	mv	s3,a1
    2ae8:	00060a13          	mv	s4,a2
    2aec:	00068a93          	mv	s5,a3
    2af0:	00070b13          	mv	s6,a4
    g_sent_seq++;
    2af4:	84c1a783          	lw	a5,-1972(gp) # 970c <g_sent_seq>
    2af8:	00178793          	addi	a5,a5,1
    2afc:	84f1a623          	sw	a5,-1972(gp) # 970c <g_sent_seq>
    sv = (uint16_t)(0x1000u + (g_sent_seq & 0xFFFu));   /* 每帧一个不同颜色（16bit 内唯一） */
    2b00:	00001737          	lui	a4,0x1
    2b04:	fff70713          	addi	a4,a4,-1 # fff <CUSTOM2+0xfa4>
    2b08:	00e7f7b3          	and	a5,a5,a4
    2b0c:	01079793          	slli	a5,a5,0x10
    2b10:	0107d793          	srli	a5,a5,0x10
    2b14:	00001737          	lui	a4,0x1
    2b18:	00e787b3          	add	a5,a5,a4
    2b1c:	01079b93          	slli	s7,a5,0x10
    g_ins_frame  = 0;
    2b20:	8601a223          	sw	zero,-1948(gp) # 9724 <g_ins_frame>
    g_push_err   = 0;
    2b24:	8401a823          	sw	zero,-1968(gp) # 9710 <g_push_err>
    g_scene_ctx  = 1;                     /* 现场上下文：[7] 压测帧内 */
    2b28:	00100713          	li	a4,1
    2b2c:	84e1aa23          	sw	a4,-1964(gp) # 9714 <g_scene_ctx>
    g_frame_no   = (uint32_t)f;
    2b30:	84b1ae23          	sw	a1,-1956(gp) # 971c <g_frame_no>
    g_rung_n     = (uint32_t)n;
    2b34:	84a1ac23          	sw	a0,-1960(gp) # 9718 <g_rung_n>
    g_push_acct  = perf_each ? 1 : 0;
    2b38:	00c03733          	snez	a4,a2
    2b3c:	84e1a023          	sw	a4,-1984(gp) # 9700 <g_push_acct>
    g_push_batch = (STRESS_BATCH_PUSH && !perf_each) ? 1 : 0;
    2b40:	8401a223          	sw	zero,-1980(gp) # 9704 <g_push_batch>
    rc = blt_frame_begin();               /* 帧首：必须是整条指令边界 */
    2b44:	cb8ff0ef          	jal	1ffc <blt_frame_begin>
    2b48:	00050413          	mv	s0,a0
    if (rc != 0) return rc;
    2b4c:	06051263          	bnez	a0,2bb0 <stress_frame+0xf4>
    2b50:	02912a23          	sw	s1,52(sp)
    2b54:	010bdb93          	srli	s7,s7,0x10
    g_push_left = STRESS_PUSH_BATCH;      /* 批量路径的批预算（帧首已确认边界干净） */
    2b58:	0a000713          	li	a4,160
    2b5c:	84e1a423          	sw	a4,-1976(gp) # 9708 <g_push_left>
    for (i = 0; i < n && rc == 0; i++)
    2b60:	00050493          	mv	s1,a0
    2b64:	0324d463          	bge	s1,s2,2b8c <stress_frame+0xd0>
    2b68:	02041263          	bnez	s0,2b8c <stress_frame+0xd0>
        rc = spr_emit(i, f, n, bbox);
    2b6c:	00000693          	li	a3,0
    2b70:	00090613          	mv	a2,s2
    2b74:	00098593          	mv	a1,s3
    2b78:	00048513          	mv	a0,s1
    2b7c:	cfdff0ef          	jal	2878 <spr_emit>
    2b80:	00050413          	mv	s0,a0
    for (i = 0; i < n && rc == 0; i++)
    2b84:	00148493          	addi	s1,s1,1
    2b88:	fddff06f          	j	2b64 <stress_frame+0xa8>
    if (rc == 0) {
    2b8c:	04040863          	beqz	s0,2bdc <stress_frame+0x120>
    if (rc == 0) {
    2b90:	08040a63          	beqz	s0,2c24 <stress_frame+0x168>
    if (evict) {
    2b94:	000b0463          	beqz	s6,2b9c <stress_frame+0xe0>
        *evict = 0u;                      /* 模式 1：本压测帧内 CPU 不写 DDR，不需要冲刷 */
    2b98:	000b2023          	sw	zero,0(s6)
    if (eng) *eng = perf_each ? g_perf_sum : 0u;
    2b9c:	0a0a8663          	beqz	s5,2c48 <stress_frame+0x18c>
    2ba0:	0a0a0063          	beqz	s4,2c40 <stress_frame+0x184>
    2ba4:	83c1a783          	lw	a5,-1988(gp) # 96fc <g_perf_sum>
    2ba8:	00faa023          	sw	a5,0(s5)
    2bac:	03412483          	lw	s1,52(sp)
}
    2bb0:	00040513          	mv	a0,s0
    2bb4:	03c12083          	lw	ra,60(sp)
    2bb8:	03812403          	lw	s0,56(sp)
    2bbc:	03012903          	lw	s2,48(sp)
    2bc0:	02c12983          	lw	s3,44(sp)
    2bc4:	02812a03          	lw	s4,40(sp)
    2bc8:	02412a83          	lw	s5,36(sp)
    2bcc:	02012b03          	lw	s6,32(sp)
    2bd0:	01c12b83          	lw	s7,28(sp)
    2bd4:	04010113          	addi	sp,sp,64
    2bd8:	00008067          	ret
        push_cmd_fast(BLT_OP_FILL, 0u, SA_SENT, 0u, FB_STRIDE, 1u, 1u, 0xFFu, (uint32_t)sv);
    2bdc:	01712023          	sw	s7,0(sp)
    2be0:	0ff00893          	li	a7,255
    2be4:	00100813          	li	a6,1
    2be8:	00100793          	li	a5,1
    2bec:	78000713          	li	a4,1920
    2bf0:	00000693          	li	a3,0
    2bf4:	004fa637          	lui	a2,0x4fa
    2bf8:	e0860613          	addi	a2,a2,-504 # 4f9e08 <__freertos_irq_stack_top+0x4ed118>
    2bfc:	00000593          	li	a1,0
    2c00:	00100513          	li	a0,1
    2c04:	d78ff0ef          	jal	217c <push_cmd_fast>
        rc = g_push_err;
    2c08:	8501a403          	lw	s0,-1968(gp) # 9710 <g_push_err>
    if (rc == 0) rc = blt_wait_frame_done((uint32_t)STRESS_FRAME_TO_TICKS);   /* 一帧只等一次 */
    2c0c:	f80414e3          	bnez	s0,2b94 <stress_frame+0xd8>
    2c10:	02faf537          	lui	a0,0x2faf
    2c14:	08050513          	addi	a0,a0,128 # 2faf080 <__freertos_irq_stack_top+0x2fa2390>
    2c18:	b28ff0ef          	jal	1f40 <blt_wait_frame_done>
    2c1c:	00050413          	mv	s0,a0
    2c20:	f71ff06f          	j	2b90 <stress_frame+0xd4>
        cache_invalidate();               /* 引擎写完 DDR -> CPU 回读前必须作废 D$ */
    2c24:	d9dfe0ef          	jal	19c0 <cache_invalidate>
        if (rd16(SA_SENT) != sv) rc = -3; /* 最后一条指令没落地 = 丢字/漏执行 */
    2c28:	004fa537          	lui	a0,0x4fa
    2c2c:	e0850513          	addi	a0,a0,-504 # 4f9e08 <__freertos_irq_stack_top+0x4ed118>
    2c30:	c45fe0ef          	jal	1874 <rd16>
    2c34:	f77500e3          	beq	a0,s7,2b94 <stress_frame+0xd8>
    2c38:	ffd00413          	li	s0,-3
    2c3c:	f59ff06f          	j	2b94 <stress_frame+0xd8>
    if (eng) *eng = perf_each ? g_perf_sum : 0u;
    2c40:	00000793          	li	a5,0
    2c44:	f65ff06f          	j	2ba8 <stress_frame+0xec>
    2c48:	03412483          	lw	s1,52(sp)
    2c4c:	f65ff06f          	j	2bb0 <stress_frame+0xf4>

00002c50 <ndig>:
{
    2c50:	00050793          	mv	a5,a0
    if (v < 0) { n = 2; v = -v; }
    2c54:	00054663          	bltz	a0,2c60 <ndig+0x10>
    int n = 1;
    2c58:	00100513          	li	a0,1
    2c5c:	01c0006f          	j	2c78 <ndig+0x28>
    if (v < 0) { n = 2; v = -v; }
    2c60:	40a007b3          	neg	a5,a0
    2c64:	00200513          	li	a0,2
    2c68:	0100006f          	j	2c78 <ndig+0x28>
    while (v >= 10) { v /= 10; n++; }
    2c6c:	00a00713          	li	a4,10
    2c70:	02e7c7b3          	div	a5,a5,a4
    2c74:	00150513          	addi	a0,a0,1
    2c78:	00900713          	li	a4,9
    2c7c:	fef748e3          	blt	a4,a5,2c6c <ndig+0x1c>
}
    2c80:	00008067          	ret

00002c84 <bsp_printf>:
* - Handles each format specifier by calling the appropriate helper function.
* - If floating-point support is disabled, prints a warning for the 'f' specifier.
*
******************************************************************************/
    static void bsp_printf(const char *format, ...)
    {
    2c84:	fc010113          	addi	sp,sp,-64
    2c88:	00112e23          	sw	ra,28(sp)
    2c8c:	00812c23          	sw	s0,24(sp)
    2c90:	00912a23          	sw	s1,20(sp)
    2c94:	00050493          	mv	s1,a0
    2c98:	02b12223          	sw	a1,36(sp)
    2c9c:	02c12423          	sw	a2,40(sp)
    2ca0:	02d12623          	sw	a3,44(sp)
    2ca4:	02e12823          	sw	a4,48(sp)
    2ca8:	02f12a23          	sw	a5,52(sp)
    2cac:	03012c23          	sw	a6,56(sp)
    2cb0:	03112e23          	sw	a7,60(sp)
        int i;
        va_list ap;

        va_start(ap, format);
    2cb4:	02410793          	addi	a5,sp,36
    2cb8:	00f12623          	sw	a5,12(sp)

        for (i = 0; format[i]; i++)
    2cbc:	00000413          	li	s0,0
    2cc0:	01c0006f          	j	2cdc <bsp_printf+0x58>
            if (format[i] == '%') {
                while (format[++i]) {
                    if (format[i] == 'c') {
                        bsp_printf_c(va_arg(ap,int));
    2cc4:	00c12783          	lw	a5,12(sp)
    2cc8:	00478713          	addi	a4,a5,4
    2ccc:	00e12623          	sw	a4,12(sp)
    2cd0:	0007a503          	lw	a0,0(a5)
    2cd4:	9e1fe0ef          	jal	16b4 <bsp_printf_c>
        for (i = 0; format[i]; i++)
    2cd8:	00140413          	addi	s0,s0,1
    2cdc:	008487b3          	add	a5,s1,s0
    2ce0:	0007c503          	lbu	a0,0(a5)
    2ce4:	0a050e63          	beqz	a0,2da0 <bsp_printf+0x11c>
            if (format[i] == '%') {
    2ce8:	02500793          	li	a5,37
    2cec:	06f50e63          	beq	a0,a5,2d68 <bsp_printf+0xe4>
                        break;
                    }
#endif //#if (ENABLE_FLOATING_POINT_SUPPORT)
                }
            } else
                bsp_printf_c(format[i]);
    2cf0:	9c5fe0ef          	jal	16b4 <bsp_printf_c>
    2cf4:	fe5ff06f          	j	2cd8 <bsp_printf+0x54>
                        bsp_printf_s(va_arg(ap,char*));
    2cf8:	00c12783          	lw	a5,12(sp)
    2cfc:	00478713          	addi	a4,a5,4
    2d00:	00e12623          	sw	a4,12(sp)
    2d04:	0007a503          	lw	a0,0(a5)
    2d08:	9c9fe0ef          	jal	16d0 <bsp_printf_s>
                        break;
    2d0c:	fcdff06f          	j	2cd8 <bsp_printf+0x54>
                        bsp_printf_d(va_arg(ap,int));
    2d10:	00c12783          	lw	a5,12(sp)
    2d14:	00478713          	addi	a4,a5,4
    2d18:	00e12623          	sw	a4,12(sp)
    2d1c:	0007a503          	lw	a0,0(a5)
    2d20:	9c9fe0ef          	jal	16e8 <bsp_printf_d>
                        break;
    2d24:	fb5ff06f          	j	2cd8 <bsp_printf+0x54>
                        bsp_printf_X(va_arg(ap,int));
    2d28:	00c12783          	lw	a5,12(sp)
    2d2c:	00478713          	addi	a4,a5,4
    2d30:	00e12623          	sw	a4,12(sp)
    2d34:	0007a503          	lw	a0,0(a5)
    2d38:	a71fe0ef          	jal	17a8 <bsp_printf_X>
                        break;
    2d3c:	f9dff06f          	j	2cd8 <bsp_printf+0x54>
                        bsp_printf_x(va_arg(ap,int));
    2d40:	00c12783          	lw	a5,12(sp)
    2d44:	00478713          	addi	a4,a5,4
    2d48:	00e12623          	sw	a4,12(sp)
    2d4c:	0007a503          	lw	a0,0(a5)
    2d50:	a19fe0ef          	jal	1768 <bsp_printf_x>
                        break;
    2d54:	f85ff06f          	j	2cd8 <bsp_printf+0x54>
                        bsp_printf_s("<Floating point printing not enable. Please Enable it at bsp.h first...>");
    2d58:	00007537          	lui	a0,0x7
    2d5c:	f7c50513          	addi	a0,a0,-132 # 6f7c <_data+0x28>
    2d60:	971fe0ef          	jal	16d0 <bsp_printf_s>
                        break;
    2d64:	f75ff06f          	j	2cd8 <bsp_printf+0x54>
                while (format[++i]) {
    2d68:	00140413          	addi	s0,s0,1
    2d6c:	008487b3          	add	a5,s1,s0
    2d70:	0007c783          	lbu	a5,0(a5)
    2d74:	f60782e3          	beqz	a5,2cd8 <bsp_printf+0x54>
                    if (format[i] == 'c') {
    2d78:	fa878793          	addi	a5,a5,-88
    2d7c:	0ff7f693          	zext.b	a3,a5
    2d80:	02000713          	li	a4,32
    2d84:	fed762e3          	bltu	a4,a3,2d68 <bsp_printf+0xe4>
    2d88:	00269793          	slli	a5,a3,0x2
    2d8c:	00009737          	lui	a4,0x9
    2d90:	56870713          	addi	a4,a4,1384 # 9568 <_data+0x2614>
    2d94:	00e787b3          	add	a5,a5,a4
    2d98:	0007a783          	lw	a5,0(a5)
    2d9c:	00078067          	jr	a5

        va_end(ap);
    }
    2da0:	01c12083          	lw	ra,28(sp)
    2da4:	01812403          	lw	s0,24(sp)
    2da8:	01412483          	lw	s1,20(sp)
    2dac:	04010113          	addi	sp,sp,64
    2db0:	00008067          	ret

00002db4 <blt_print_scene>:
{
    2db4:	fc010113          	addi	sp,sp,-64
    2db8:	02112e23          	sw	ra,60(sp)
    2dbc:	02812c23          	sw	s0,56(sp)
    2dc0:	02912a23          	sw	s1,52(sp)
    2dc4:	03212823          	sw	s2,48(sp)
    2dc8:	03312623          	sw	s3,44(sp)
    2dcc:	03412423          	sw	s4,40(sp)
    2dd0:	03512223          	sw	s5,36(sp)
    2dd4:	03612023          	sw	s6,32(sp)
    2dd8:	01712e23          	sw	s7,28(sp)
    2ddc:	01812c23          	sw	s8,24(sp)
    2de0:	01912a23          	sw	s9,20(sp)
    2de4:	00050b93          	mv	s7,a0
    2de8:	00058993          	mv	s3,a1
    uint32_t st  = blt_rd(BLT_STATUS);
    2dec:	00400513          	li	a0,4
    2df0:	a9dfe0ef          	jal	188c <blt_rd>
    2df4:	00050493          	mv	s1,a0
    uint32_t cnt = blt_rd(BLT_CMD_FIFO_COUNT);
    2df8:	00c00513          	li	a0,12
    2dfc:	a91fe0ef          	jal	188c <blt_rd>
    2e00:	00050413          	mv	s0,a0
    uint32_t dw  = blt_rd(BLT_DBG_CUR_CMD);
    2e04:	01800513          	li	a0,24
    2e08:	a85fe0ef          	jal	188c <blt_rd>
    2e0c:	00050913          	mv	s2,a0
    int      busy = (st & BLT_STATUS_BUSY) ? 1 : 0;
    2e10:	0014fc13          	andi	s8,s1,1
    int      done = (st & BLT_STATUS_DONE) ? 1 : 0;
    2e14:	0014da93          	srli	s5,s1,0x1
    2e18:	001afa93          	andi	s5,s5,1
    int      err  = (st & BLT_STATUS_ERR) ? 1 : 0;
    2e1c:	0024db13          	srli	s6,s1,0x2
    2e20:	001b7b13          	andi	s6,s6,1
    int      emp  = (st & BLT_STATUS_FIFO_EMPTY) ? 1 : 0;
    2e24:	0034da13          	srli	s4,s1,0x3
    2e28:	001a7a13          	andi	s4,s4,1
    int      residual  = (cnt == 0u && !emp) ? 1 : 0;
    2e2c:	00041863          	bnez	s0,2e3c <blt_print_scene+0x88>
    2e30:	120a0a63          	beqz	s4,2f64 <blt_print_scene+0x1b0>
    2e34:	00000c93          	li	s9,0
    2e38:	0080006f          	j	2e40 <blt_print_scene+0x8c>
    2e3c:	00000c93          	li	s9,0
    if (rc == -2)
    2e40:	ffe00793          	li	a5,-2
    2e44:	12f98463          	beq	s3,a5,2f6c <blt_print_scene+0x1b8>
    else if (rc == -3)
    2e48:	ffd00793          	li	a5,-3
    2e4c:	12f98c63          	beq	s3,a5,2f84 <blt_print_scene+0x1d0>
        bsp_printf("      %s: timeout! STATUS=0x%x FIFO_COUNT=%d\r\n", tag, (int)st, (int)cnt);
    2e50:	00040693          	mv	a3,s0
    2e54:	00048613          	mv	a2,s1
    2e58:	000b8593          	mv	a1,s7
    2e5c:	00007537          	lui	a0,0x7
    2e60:	09450513          	addi	a0,a0,148 # 7094 <_data+0x140>
    2e64:	e21ff0ef          	jal	2c84 <bsp_printf>
               busy, done, err, emp, (int)cnt, (int)(cnt * 8u), (int)(cnt * 8u + 7u),
    2e68:	00341813          	slli	a6,s0,0x3
    2e6c:	00780893          	addi	a7,a6,7
    bsp_printf("        现场: BUSY=%d DONE=%d ERR=%d FIFO_EMPTY=%d | CMD_FIFO_COUNT=%d 条(=floor(字数/8)，约 %d~%d 字) -> %s\r\n",
    2e70:	120c8a63          	beqz	s9,2fa4 <blt_print_scene+0x1f0>
    2e74:	000077b7          	lui	a5,0x7
    2e78:	fc878793          	addi	a5,a5,-56 # 6fc8 <_data+0x74>
    2e7c:	00f12023          	sw	a5,0(sp)
    2e80:	00040793          	mv	a5,s0
    2e84:	000a0713          	mv	a4,s4
    2e88:	000b0693          	mv	a3,s6
    2e8c:	000a8613          	mv	a2,s5
    2e90:	000c0593          	mv	a1,s8
    2e94:	00007537          	lui	a0,0x7
    2e98:	0c450513          	addi	a0,a0,196 # 70c4 <_data+0x170>
    2e9c:	de9ff0ef          	jal	2c84 <bsp_printf>
    if (g_scene_ctx) {
    2ea0:	8541a783          	lw	a5,-1964(gp) # 9714 <g_scene_ctx>
    2ea4:	10078a63          	beqz	a5,2fb8 <blt_print_scene+0x204>
        int stuck_ins = ((int)g_ins_frame - (int)cnt > 0) ? ((int)g_ins_frame - (int)cnt + 1) : 1;
    2ea8:	8641a583          	lw	a1,-1948(gp) # 9724 <g_ins_frame>
    2eac:	40858833          	sub	a6,a1,s0
    2eb0:	10084063          	bltz	a6,2fb0 <blt_print_scene+0x1fc>
        bsp_printf("        本帧已完整推入 %d 条（累计 %d 条），帧号=%d 档位 N=%d，FIFO 还剩 %d 条 -> 引擎大约卡在第 %d 条\r\n",
    2eb4:	00180813          	addi	a6,a6,1
    2eb8:	00040793          	mv	a5,s0
    2ebc:	8581a703          	lw	a4,-1960(gp) # 9718 <g_rung_n>
    2ec0:	85c1a683          	lw	a3,-1956(gp) # 971c <g_frame_no>
    2ec4:	8601a603          	lw	a2,-1952(gp) # 9720 <g_ins_total>
    2ec8:	00007537          	lui	a0,0x7
    2ecc:	13c50513          	addi	a0,a0,316 # 713c <_data+0x1e8>
    2ed0:	db5ff0ef          	jal	2c84 <bsp_printf>
               (int)g_last_seq, (int)g_last_cmd.op, (int)g_last_cmd.src, (int)g_last_cmd.dst,
    2ed4:	0000c637          	lui	a2,0xc
    2ed8:	cc460613          	addi	a2,a2,-828 # bcc4 <g_last_cmd>
               (int)g_last_cmd.w, (int)g_last_cmd.h, (int)g_last_cmd.alpha,
    2edc:	01862783          	lw	a5,24(a2)
    2ee0:	01c62703          	lw	a4,28(a2)
               (int)g_last_cmd.color);
    2ee4:	02062683          	lw	a3,32(a2)
    bsp_printf("        最后完整下发: #%d op=0x%x src=0x%x dst=0x%x ss=%d ds=%d w=%d h=%d alpha=%d color=0x%x\r\n",
    2ee8:	00d12423          	sw	a3,8(sp)
    2eec:	00e12223          	sw	a4,4(sp)
    2ef0:	00f12023          	sw	a5,0(sp)
    2ef4:	01462883          	lw	a7,20(a2)
    2ef8:	01062803          	lw	a6,16(a2)
    2efc:	00c62783          	lw	a5,12(a2)
    2f00:	00862703          	lw	a4,8(a2)
    2f04:	00462683          	lw	a3,4(a2)
    2f08:	00062603          	lw	a2,0(a2)
    2f0c:	8681a583          	lw	a1,-1944(gp) # 9728 <g_last_seq>
    2f10:	00007537          	lui	a0,0x7
    2f14:	24450513          	addi	a0,a0,580 # 7244 <_data+0x2f0>
    2f18:	d6dff0ef          	jal	2c84 <bsp_printf>
    bsp_printf("        引擎 DBG_CUR_CMD=0x%x（引擎正在执行的指令 op=0x%x；BUSY=1 时为它卡住的那条）\r\n",
    2f1c:	00397613          	andi	a2,s2,3
    2f20:	00090593          	mv	a1,s2
    2f24:	00007537          	lui	a0,0x7
    2f28:	2ac50513          	addi	a0,a0,684 # 72ac <_data+0x358>
    2f2c:	d59ff0ef          	jal	2c84 <bsp_printf>
}
    2f30:	03c12083          	lw	ra,60(sp)
    2f34:	03812403          	lw	s0,56(sp)
    2f38:	03412483          	lw	s1,52(sp)
    2f3c:	03012903          	lw	s2,48(sp)
    2f40:	02c12983          	lw	s3,44(sp)
    2f44:	02812a03          	lw	s4,40(sp)
    2f48:	02412a83          	lw	s5,36(sp)
    2f4c:	02012b03          	lw	s6,32(sp)
    2f50:	01c12b83          	lw	s7,28(sp)
    2f54:	01812c03          	lw	s8,24(sp)
    2f58:	01412c83          	lw	s9,20(sp)
    2f5c:	04010113          	addi	sp,sp,64
    2f60:	00008067          	ret
    int      residual  = (cnt == 0u && !emp) ? 1 : 0;
    2f64:	00100c93          	li	s9,1
    2f68:	ed9ff06f          	j	2e40 <blt_print_scene+0x8c>
        bsp_printf("      %s: engine ERR! STATUS=0x%x -> SOFT_RST 复位\r\n", tag, (int)st);
    2f6c:	00048613          	mv	a2,s1
    2f70:	000b8593          	mv	a1,s7
    2f74:	00007537          	lui	a0,0x7
    2f78:	00050513          	mv	a0,a0
    2f7c:	d09ff0ef          	jal	2c84 <bsp_printf>
    2f80:	ee9ff06f          	j	2e68 <blt_print_scene+0xb4>
        bsp_printf("      %s: FIFO 状态矛盾/丢字! STATUS=0x%x COUNT=%d FIFO_EMPTY=%d -> SOFT_RST 复位\r\n",
    2f84:	000a0713          	mv	a4,s4
    2f88:	00040693          	mv	a3,s0
    2f8c:	00048613          	mv	a2,s1
    2f90:	000b8593          	mv	a1,s7
    2f94:	00007537          	lui	a0,0x7
    2f98:	03850513          	addi	a0,a0,56 # 7038 <_data+0xe4>
    2f9c:	ce9ff0ef          	jal	2c84 <bsp_printf>
    2fa0:	ec9ff06f          	j	2e68 <blt_print_scene+0xb4>
    bsp_printf("        现场: BUSY=%d DONE=%d ERR=%d FIFO_EMPTY=%d | CMD_FIFO_COUNT=%d 条(=floor(字数/8)，约 %d~%d 字) -> %s\r\n",
    2fa4:	000077b7          	lui	a5,0x7
    2fa8:	fec78793          	addi	a5,a5,-20 # 6fec <_data+0x98>
    2fac:	ed1ff06f          	j	2e7c <blt_print_scene+0xc8>
        int stuck_ins = ((int)g_ins_frame - (int)cnt > 0) ? ((int)g_ins_frame - (int)cnt + 1) : 1;
    2fb0:	00000813          	li	a6,0
    2fb4:	f01ff06f          	j	2eb4 <blt_print_scene+0x100>
        bsp_printf("        本条操作已完整下发 %d 条（单条指令操作，不属于压测帧），累计 %d 条，FIFO 还剩 %d 条\r\n",
    2fb8:	00040693          	mv	a3,s0
    2fbc:	8601a603          	lw	a2,-1952(gp) # 9720 <g_ins_total>
    2fc0:	8641a583          	lw	a1,-1948(gp) # 9724 <g_ins_frame>
    2fc4:	00007537          	lui	a0,0x7
    2fc8:	1c450513          	addi	a0,a0,452 # 71c4 <_data+0x270>
    2fcc:	cb9ff0ef          	jal	2c84 <bsp_printf>
    2fd0:	f05ff06f          	j	2ed4 <blt_print_scene+0x120>

00002fd4 <blt_restore_boundary>:
{
    2fd4:	fe010113          	addi	sp,sp,-32
    2fd8:	00112e23          	sw	ra,28(sp)
    2fdc:	00912a23          	sw	s1,20(sp)
    2fe0:	01212823          	sw	s2,16(sp)
    2fe4:	00050913          	mv	s2,a0
    if (blt_fifo_clean()) return 0;               /* 常见情形：本来就在边界上 */
    2fe8:	e0dfe0ef          	jal	1df4 <blt_fifo_clean>
    2fec:	02050063          	beqz	a0,300c <blt_restore_boundary+0x38>
    2ff0:	00000493          	li	s1,0
}
    2ff4:	00048513          	mv	a0,s1
    2ff8:	01c12083          	lw	ra,28(sp)
    2ffc:	01412483          	lw	s1,20(sp)
    3000:	01012903          	lw	s2,16(sp)
    3004:	02010113          	addi	sp,sp,32
    3008:	00008067          	ret
    300c:	00812c23          	sw	s0,24(sp)
    3010:	01312623          	sw	s3,12(sp)
    3014:	00050493          	mv	s1,a0
               tag, (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT),
    3018:	00400513          	li	a0,4
    301c:	871fe0ef          	jal	188c <blt_rd>
    3020:	00050413          	mv	s0,a0
    3024:	00c00513          	li	a0,12
    3028:	865fe0ef          	jal	188c <blt_rd>
    302c:	00050993          	mv	s3,a0
               (int)((blt_rd(BLT_STATUS) & BLT_STATUS_FIFO_EMPTY) ? 1 : 0));
    3030:	00400513          	li	a0,4
    3034:	859fe0ef          	jal	188c <blt_rd>
    3038:	00857713          	andi	a4,a0,8
    bsp_printf("      %s: FIFO 不在整条指令边界(STATUS=0x%x COUNT=%d FIFO_EMPTY=%d) -> SOFT_RST 清 FIFO/引擎\r\n",
    303c:	00e03733          	snez	a4,a4
    3040:	00098693          	mv	a3,s3
    3044:	00040613          	mv	a2,s0
    3048:	00090593          	mv	a1,s2
    304c:	00007537          	lui	a0,0x7
    3050:	31c50513          	addi	a0,a0,796 # 731c <_data+0x3c8>
    3054:	c31ff0ef          	jal	2c84 <bsp_printf>
    blt_init();                                   /* SOFT_RST -> CTRL=0 -> 清 IRQ -> GO */
    3058:	ab9fe0ef          	jal	1b10 <blt_init>
    for (k = 0; k < 8; k++) {                     /* 复位后确认边界确实干净 */
    305c:	00048413          	mv	s0,s1
    3060:	00700793          	li	a5,7
    3064:	0487ca63          	blt	a5,s0,30b8 <blt_restore_boundary+0xe4>
        if (blt_fifo_clean()) {
    3068:	d8dfe0ef          	jal	1df4 <blt_fifo_clean>
    306c:	00051a63          	bnez	a0,3080 <blt_restore_boundary+0xac>
        busy_loop(BLT_SETTLE_LOOPS);
    3070:	0c800513          	li	a0,200
    3074:	fc8fe0ef          	jal	183c <busy_loop>
    for (k = 0; k < 8; k++) {                     /* 复位后确认边界确实干净 */
    3078:	00140413          	addi	s0,s0,1
    307c:	fe5ff06f          	j	3060 <blt_restore_boundary+0x8c>
                       tag, (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT));
    3080:	00400513          	li	a0,4
    3084:	809fe0ef          	jal	188c <blt_rd>
    3088:	00050413          	mv	s0,a0
    308c:	00c00513          	li	a0,12
    3090:	ffcfe0ef          	jal	188c <blt_rd>
    3094:	00050693          	mv	a3,a0
            bsp_printf("      %s: SOFT_RST 后边界已干净（STATUS=0x%x COUNT=%d FIFO_EMPTY=1）\r\n",
    3098:	00040613          	mv	a2,s0
    309c:	00090593          	mv	a1,s2
    30a0:	00007537          	lui	a0,0x7
    30a4:	38850513          	addi	a0,a0,904 # 7388 <_data+0x434>
    30a8:	bddff0ef          	jal	2c84 <bsp_printf>
            return 0;
    30ac:	01812403          	lw	s0,24(sp)
    30b0:	00c12983          	lw	s3,12(sp)
    30b4:	f41ff06f          	j	2ff4 <blt_restore_boundary+0x20>
               tag, (int)blt_rd(BLT_STATUS), (int)blt_rd(BLT_CMD_FIFO_COUNT),
    30b8:	00400513          	li	a0,4
    30bc:	fd0fe0ef          	jal	188c <blt_rd>
    30c0:	00050413          	mv	s0,a0
    30c4:	00c00513          	li	a0,12
    30c8:	fc4fe0ef          	jal	188c <blt_rd>
    30cc:	00050493          	mv	s1,a0
               (int)((blt_rd(BLT_STATUS) & BLT_STATUS_FIFO_EMPTY) ? 1 : 0));
    30d0:	00400513          	li	a0,4
    30d4:	fb8fe0ef          	jal	188c <blt_rd>
    30d8:	00857713          	andi	a4,a0,8
    bsp_printf("      %s: SOFT_RST 后 FIFO 仍不干净（STATUS=0x%x COUNT=%d FIFO_EMPTY=%d）\r\n",
    30dc:	00e03733          	snez	a4,a4
    30e0:	00048693          	mv	a3,s1
    30e4:	00040613          	mv	a2,s0
    30e8:	00090593          	mv	a1,s2
    30ec:	00007537          	lui	a0,0x7
    30f0:	3d850513          	addi	a0,a0,984 # 73d8 <_data+0x484>
    30f4:	b91ff0ef          	jal	2c84 <bsp_printf>
    return -1;
    30f8:	fff00493          	li	s1,-1
    30fc:	01812403          	lw	s0,24(sp)
    3100:	00c12983          	lw	s3,12(sp)
    3104:	ef1ff06f          	j	2ff4 <blt_restore_boundary+0x20>

00003108 <op_fail>:
{
    3108:	ff010113          	addi	sp,sp,-16
    310c:	00112623          	sw	ra,12(sp)
    3110:	00812423          	sw	s0,8(sp)
    3114:	00050413          	mv	s0,a0
    if (rc == 0) return 0;
    3118:	00051c63          	bnez	a0,3130 <op_fail+0x28>
}
    311c:	00040513          	mv	a0,s0
    3120:	00c12083          	lw	ra,12(sp)
    3124:	00812403          	lw	s0,8(sp)
    3128:	01010113          	addi	sp,sp,16
    312c:	00008067          	ret
    3130:	00912223          	sw	s1,4(sp)
    3134:	00058493          	mv	s1,a1
    g_eng_errs++;
    3138:	8741a783          	lw	a5,-1932(gp) # 9734 <g_eng_errs>
    313c:	00178793          	addi	a5,a5,1
    3140:	86f1aa23          	sw	a5,-1932(gp) # 9734 <g_eng_errs>
    blt_print_scene(tag, rc);              /* 现场：本帧条数/COUNT/STATUS/最后一条指令 */
    3144:	00050593          	mv	a1,a0
    3148:	00048513          	mv	a0,s1
    314c:	c69ff0ef          	jal	2db4 <blt_print_scene>
    if (blt_restore_boundary(tag) != 0) {
    3150:	00048513          	mv	a0,s1
    3154:	e81ff0ef          	jal	2fd4 <blt_restore_boundary>
    3158:	00050663          	beqz	a0,3164 <op_fail+0x5c>
        if (g_blt_alive) {
    315c:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3160:	02079063          	bnez	a5,3180 <op_fail+0x78>
    if (g_eng_errs > 3 && g_blt_alive) {
    3164:	8741a583          	lw	a1,-1932(gp) # 9734 <g_eng_errs>
    3168:	00300793          	li	a5,3
    316c:	04b7d263          	bge	a5,a1,31b0 <op_fail+0xa8>
    3170:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3174:	02079263          	bnez	a5,3198 <op_fail+0x90>
    3178:	00412483          	lw	s1,4(sp)
    317c:	fa1ff06f          	j	311c <op_fail+0x14>
            g_blt_alive = 0;
    3180:	8001ac23          	sw	zero,-2024(gp) # 96d8 <g_blt_alive>
            bsp_printf("      %s: 边界清不干净 -> 熔断，跳过后续引擎测试\r\n", tag);
    3184:	00048593          	mv	a1,s1
    3188:	00007537          	lui	a0,0x7
    318c:	42c50513          	addi	a0,a0,1068 # 742c <_data+0x4d8>
    3190:	af5ff0ef          	jal	2c84 <bsp_printf>
    3194:	fd1ff06f          	j	3164 <op_fail+0x5c>
        g_blt_alive = 0;
    3198:	8001ac23          	sw	zero,-2024(gp) # 96d8 <g_blt_alive>
        bsp_printf("      引擎连续失败 %d 次 -> 熔断：跳过后续引擎测试（不再每条等 2s）\r\n",
    319c:	00007537          	lui	a0,0x7
    31a0:	47050513          	addi	a0,a0,1136 # 7470 <_data+0x51c>
    31a4:	ae1ff0ef          	jal	2c84 <bsp_printf>
    31a8:	00412483          	lw	s1,4(sp)
    31ac:	f71ff06f          	j	311c <op_fail+0x14>
    31b0:	00412483          	lw	s1,4(sp)
    31b4:	f69ff06f          	j	311c <op_fail+0x14>

000031b8 <stress_rung>:
{
    31b8:	fb010113          	addi	sp,sp,-80
    31bc:	04112623          	sw	ra,76(sp)
    31c0:	04812423          	sw	s0,72(sp)
    31c4:	04912223          	sw	s1,68(sp)
    31c8:	05212023          	sw	s2,64(sp)
    31cc:	03312e23          	sw	s3,60(sp)
    31d0:	03412c23          	sw	s4,56(sp)
    31d4:	03512a23          	sw	s5,52(sp)
    31d8:	03612823          	sw	s6,48(sp)
    31dc:	03712623          	sw	s7,44(sp)
    31e0:	03812423          	sw	s8,40(sp)
    31e4:	03912223          	sw	s9,36(sp)
    31e8:	03a12023          	sw	s10,32(sp)
    31ec:	01b12e23          	sw	s11,28(sp)
    31f0:	00050d13          	mv	s10,a0
    31f4:	00058d93          	mv	s11,a1
    31f8:	00060a93          	mv	s5,a2
    uint32_t eng_sum = 0, wall_sum = 0, period_sum = 0, ins_sum = 0, ev_sum = 0;
    31fc:	00012623          	sw	zero,12(sp)
    row->n = n;
    3200:	00a62023          	sw	a0,0(a2)
    row->frames = 0;
    3204:	00062223          	sw	zero,4(a2)
    row->ins_avg = 0;
    3208:	00062423          	sw	zero,8(a2)
    row->eng_avg = 0;
    320c:	00062623          	sw	zero,12(a2)
    row->cpu_avg = 0;
    3210:	00062823          	sw	zero,16(a2)
    row->period_avg = 0;
    3214:	00062a23          	sw	zero,20(a2)
    row->evict_avg = 0;
    3218:	00062c23          	sw	zero,24(a2)
    row->fps = 0;
    321c:	00062e23          	sw	zero,28(a2)
    row->fps_period = 0;
    3220:	02062023          	sw	zero,32(a2)
    row->errs = 0;
    3224:	02062623          	sw	zero,44(a2)
    row->perf_good = 0;
    3228:	02062223          	sw	zero,36(a2)
    row->perf_zero = 0;
    322c:	02062423          	sw	zero,40(a2)
    stress_prepare(n);
    3230:	c50ff0ef          	jal	2680 <stress_prepare>
    if (g_blt_alive) {
    3234:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3238:	02079a63          	bnez	a5,326c <stress_rung+0xb4>
    if (STRESS_EVICT_MODE == 1) (void)cache_evict_timed();
    323c:	f54fe0ef          	jal	1990 <cache_evict_timed>
    g_wait_to = BLT_FAST_TICKS;      /* 逐条等 DONE 的超时（故障时快速失败，不长时间挂住） */
    3240:	013137b7          	lui	a5,0x1313
    3244:	d0078793          	addi	a5,a5,-768 # 1312d00 <__freertos_irq_stack_top+0x1306010>
    3248:	80f1a823          	sw	a5,-2032(gp) # 96d0 <g_wait_to>
    int f, errs = 0, done_frames = 0;
    324c:	00000a13          	li	s4,0
    for (f = 0; f < frames; f++) {
    3250:	00000493          	li	s1,0
    uint32_t eng_sum = 0, wall_sum = 0, period_sum = 0, ins_sum = 0, ev_sum = 0;
    3254:	00000b13          	li	s6,0
    3258:	00000b93          	li	s7,0
    325c:	00000c93          	li	s9,0
    3260:	00000c13          	li	s8,0
    uint64_t t_prev = 0;
    3264:	00000913          	li	s2,0
    for (f = 0; f < frames; f++) {
    3268:	08c0006f          	j	32f4 <stress_rung+0x13c>
        int brc = blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, STRESS_BG);
    326c:	01000713          	li	a4,16
    3270:	21c00693          	li	a3,540
    3274:	3c000613          	li	a2,960
    3278:	78000593          	li	a1,1920
    327c:	00301537          	lui	a0,0x301
    3280:	a30ff0ef          	jal	24b0 <blt_fill>
        if (brc != 0) op_fail(brc, "stress bg FILL");
    3284:	fa050ce3          	beqz	a0,323c <stress_rung+0x84>
    3288:	000075b7          	lui	a1,0x7
    328c:	4d058593          	addi	a1,a1,1232 # 74d0 <_data+0x57c>
    3290:	e79ff0ef          	jal	3108 <op_fail>
    3294:	fa9ff06f          	j	323c <stress_rung+0x84>
        if (f) period_sum += (uint32_t)(t_frame - t_prev);
    3298:	41250933          	sub	s2,a0,s2
    329c:	012c8cb3          	add	s9,s9,s2
        rc = stress_frame(n, f, STRESS_PERF_EACH, 0, &ev);
    32a0:	00810713          	addi	a4,sp,8
    32a4:	00000693          	li	a3,0
    32a8:	00000613          	li	a2,0
    32ac:	00048593          	mv	a1,s1
    32b0:	000d0513          	mv	a0,s10
    32b4:	809ff0ef          	jal	2abc <stress_frame>
    32b8:	00050913          	mv	s2,a0
        ev_sum += ev;
    32bc:	00812783          	lw	a5,8(sp)
    32c0:	00fb0b33          	add	s6,s6,a5
        if (rc != 0) { errs = rc; op_fail(rc, "stress frame"); break; }
    32c4:	04051663          	bnez	a0,3310 <stress_rung+0x158>
        ins_sum += g_ins_frame;
    32c8:	8641a783          	lw	a5,-1948(gp) # 9724 <g_ins_frame>
    32cc:	00fb8bb3          	add	s7,s7,a5
        wall_sum += (uint32_t)(tick() - t_frame);
    32d0:	d50fe0ef          	jal	1820 <tick>
    32d4:	40850533          	sub	a0,a0,s0
    32d8:	00ac0c33          	add	s8,s8,a0
        done_frames++;
    32dc:	001a0a13          	addi	s4,s4,1
        frame_throttle(t_frame);     /* 测量已完成，这里才补足到 ~60fps */
    32e0:	00040513          	mv	a0,s0
    32e4:	00098593          	mv	a1,s3
    32e8:	ab8ff0ef          	jal	25a0 <frame_throttle>
    for (f = 0; f < frames; f++) {
    32ec:	00148493          	addi	s1,s1,1
        t_prev = t_frame;
    32f0:	00040913          	mv	s2,s0
    for (f = 0; f < frames; f++) {
    32f4:	03b4d663          	bge	s1,s11,3320 <stress_rung+0x168>
        uint64_t t_frame = tick();
    32f8:	d28fe0ef          	jal	1820 <tick>
    32fc:	00050413          	mv	s0,a0
    3300:	00058993          	mv	s3,a1
        uint32_t ev = 0;
    3304:	00012423          	sw	zero,8(sp)
        if (f) period_sum += (uint32_t)(t_frame - t_prev);
    3308:	f80498e3          	bnez	s1,3298 <stress_rung+0xe0>
    330c:	f95ff06f          	j	32a0 <stress_rung+0xe8>
        if (rc != 0) { errs = rc; op_fail(rc, "stress frame"); break; }
    3310:	000075b7          	lui	a1,0x7
    3314:	4e058593          	addi	a1,a1,1248 # 74e0 <_data+0x58c>
    3318:	df1ff0ef          	jal	3108 <op_fail>
    331c:	0080006f          	j	3324 <stress_rung+0x16c>
    int f, errs = 0, done_frames = 0;
    3320:	00000913          	li	s2,0
    g_perf_sum = 0; g_perf_good = 0; g_perf_zero = 0;
    3324:	8201ae23          	sw	zero,-1988(gp) # 96fc <g_perf_sum>
    3328:	8201ac23          	sw	zero,-1992(gp) # 96f8 <g_perf_good>
    332c:	8201aa23          	sw	zero,-1996(gp) # 96f4 <g_perf_zero>
    if (g_blt_alive) {
    3330:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3334:	0c079a63          	bnez	a5,3408 <stress_rung+0x250>
    g_wait_to = BLT_TIMEOUT_TICKS;   /* 本档结束，恢复默认超时 */
    3338:	0bebc7b7          	lui	a5,0xbebc
    333c:	20078793          	addi	a5,a5,512 # bebc200 <__freertos_irq_stack_top+0xbeaf510>
    3340:	80f1a823          	sw	a5,-2032(gp) # 96d0 <g_wait_to>
    if (done_frames == 0) done_frames = 1;
    3344:	000a1463          	bnez	s4,334c <stress_rung+0x194>
    3348:	00100a13          	li	s4,1
    row->frames     = done_frames;
    334c:	014aa223          	sw	s4,4(s5)
    row->errs       = errs;
    3350:	032aa623          	sw	s2,44(s5)
    row->ins_avg    = ins_sum / (uint32_t)done_frames;
    3354:	000a0793          	mv	a5,s4
    3358:	034bdbb3          	divu	s7,s7,s4
    335c:	017aa423          	sw	s7,8(s5)
    row->eng_avg    = g_perf_good ? eng_sum : 0u;   /* 没采到有效样本时留 0，由表格标注 */
    3360:	8381a703          	lw	a4,-1992(gp) # 96f8 <g_perf_good>
    3364:	00070463          	beqz	a4,336c <stress_rung+0x1b4>
    3368:	00c12703          	lw	a4,12(sp)
    336c:	00eaa623          	sw	a4,12(s5)
    row->cpu_avg    = wall_sum / (uint32_t)done_frames;
    3370:	02fc5733          	divu	a4,s8,a5
    3374:	00eaa823          	sw	a4,16(s5)
    row->evict_avg  = ev_sum / (uint32_t)done_frames;
    3378:	02fb5b33          	divu	s6,s6,a5
    337c:	016aac23          	sw	s6,24(s5)
    row->period_avg = (done_frames > 1) ? (period_sum / (uint32_t)(done_frames - 1)) : row->cpu_avg;
    3380:	00100693          	li	a3,1
    3384:	0d46dc63          	bge	a3,s4,345c <stress_rung+0x2a4>
    3388:	fffa0a13          	addi	s4,s4,-1
    338c:	034cdcb3          	divu	s9,s9,s4
    3390:	019aaa23          	sw	s9,20(s5)
    row->fps        = row->cpu_avg ? ((uint32_t)TICK_HZ + row->cpu_avg / 2u) / row->cpu_avg : 0u;
    3394:	0cfc6863          	bltu	s8,a5,3464 <stress_rung+0x2ac>
    3398:	00175793          	srli	a5,a4,0x1
    339c:	05f5e6b7          	lui	a3,0x5f5e
    33a0:	10068693          	addi	a3,a3,256 # 5f5e100 <__freertos_irq_stack_top+0x5f51410>
    33a4:	00d787b3          	add	a5,a5,a3
    33a8:	02e7d7b3          	divu	a5,a5,a4
    33ac:	00faae23          	sw	a5,28(s5)
    row->fps_period = row->period_avg ? ((uint32_t)TICK_HZ + row->period_avg / 2u) / row->period_avg : 0u;
    33b0:	000c8c63          	beqz	s9,33c8 <stress_rung+0x210>
    33b4:	001cd793          	srli	a5,s9,0x1
    33b8:	05f5e737          	lui	a4,0x5f5e
    33bc:	10070713          	addi	a4,a4,256 # 5f5e100 <__freertos_irq_stack_top+0x5f51410>
    33c0:	00e787b3          	add	a5,a5,a4
    33c4:	0397dcb3          	divu	s9,a5,s9
    33c8:	039aa023          	sw	s9,32(s5)
}
    33cc:	04c12083          	lw	ra,76(sp)
    33d0:	04812403          	lw	s0,72(sp)
    33d4:	04412483          	lw	s1,68(sp)
    33d8:	04012903          	lw	s2,64(sp)
    33dc:	03c12983          	lw	s3,60(sp)
    33e0:	03812a03          	lw	s4,56(sp)
    33e4:	03412a83          	lw	s5,52(sp)
    33e8:	03012b03          	lw	s6,48(sp)
    33ec:	02c12b83          	lw	s7,44(sp)
    33f0:	02812c03          	lw	s8,40(sp)
    33f4:	02412c83          	lw	s9,36(sp)
    33f8:	02012d03          	lw	s10,32(sp)
    33fc:	01c12d83          	lw	s11,28(sp)
    3400:	05010113          	addi	sp,sp,80
    3404:	00008067          	ret
        uint32_t ev2 = 0;
    3408:	00012423          	sw	zero,8(sp)
        int rc2 = stress_frame(n, frames, 1, &eng_sum, &ev2);
    340c:	00810713          	addi	a4,sp,8
    3410:	00c10693          	addi	a3,sp,12
    3414:	00100613          	li	a2,1
    3418:	000d8593          	mv	a1,s11
    341c:	000d0513          	mv	a0,s10
    3420:	e9cff0ef          	jal	2abc <stress_frame>
    3424:	00050413          	mv	s0,a0
        row->perf_good = g_perf_good;
    3428:	8381a783          	lw	a5,-1992(gp) # 96f8 <g_perf_good>
    342c:	02faa223          	sw	a5,36(s5)
        row->perf_zero = g_perf_zero;
    3430:	8341a783          	lw	a5,-1996(gp) # 96f4 <g_perf_zero>
    3434:	02faa423          	sw	a5,40(s5)
        if (rc2 != 0) { errs = rc2; op_fail(rc2, "stress acct frame"); }
    3438:	00051863          	bnez	a0,3448 <stress_rung+0x290>
        else ev_sum += ev2;
    343c:	00812783          	lw	a5,8(sp)
    3440:	00fb0b33          	add	s6,s6,a5
    3444:	ef5ff06f          	j	3338 <stress_rung+0x180>
        if (rc2 != 0) { errs = rc2; op_fail(rc2, "stress acct frame"); }
    3448:	000075b7          	lui	a1,0x7
    344c:	4f058593          	addi	a1,a1,1264 # 74f0 <_data+0x59c>
    3450:	cb9ff0ef          	jal	3108 <op_fail>
    3454:	00040913          	mv	s2,s0
    3458:	ee1ff06f          	j	3338 <stress_rung+0x180>
    row->period_avg = (done_frames > 1) ? (period_sum / (uint32_t)(done_frames - 1)) : row->cpu_avg;
    345c:	00070c93          	mv	s9,a4
    3460:	f31ff06f          	j	3390 <stress_rung+0x1d8>
    row->fps        = row->cpu_avg ? ((uint32_t)TICK_HZ + row->cpu_avg / 2u) / row->cpu_avg : 0u;
    3464:	00000793          	li	a5,0
    3468:	f45ff06f          	j	33ac <stress_rung+0x1f4>

0000346c <item>:
{
    346c:	ff010113          	addi	sp,sp,-16
    3470:	00112623          	sw	ra,12(sp)
    3474:	00812423          	sw	s0,8(sp)
    3478:	00060413          	mv	s0,a2
    if (mis != 0) g_fail++;
    347c:	00060a63          	beqz	a2,3490 <item+0x24>
    3480:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    3484:	00178793          	addi	a5,a5,1
    3488:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>
    if (mis < 0)
    348c:	02064e63          	bltz	a2,34c8 <item+0x5c>
        bsp_printf("  %s  PERF=%d  mis=%d  -> %s\r\n",
    3490:	04040863          	beqz	s0,34e0 <item+0x74>
    3494:	00007737          	lui	a4,0x7
    3498:	50470713          	addi	a4,a4,1284 # 7504 <_data+0x5b0>
    349c:	00040693          	mv	a3,s0
    34a0:	00058613          	mv	a2,a1
    34a4:	00050593          	mv	a1,a0
    34a8:	00007537          	lui	a0,0x7
    34ac:	54c50513          	addi	a0,a0,1356 # 754c <_data+0x5f8>
    34b0:	fd4ff0ef          	jal	2c84 <bsp_printf>
}
    34b4:	00803533          	snez	a0,s0
    34b8:	00c12083          	lw	ra,12(sp)
    34bc:	00812403          	lw	s0,8(sp)
    34c0:	01010113          	addi	sp,sp,16
    34c4:	00008067          	ret
        bsp_printf("  %s  PERF=%d  -> FAIL (engine timeout/ERR, 见上)\r\n",
    34c8:	00058613          	mv	a2,a1
    34cc:	00050593          	mv	a1,a0
    34d0:	00007537          	lui	a0,0x7
    34d4:	51450513          	addi	a0,a0,1300 # 7514 <_data+0x5c0>
    34d8:	facff0ef          	jal	2c84 <bsp_printf>
    34dc:	fd9ff06f          	j	34b4 <item+0x48>
        bsp_printf("  %s  PERF=%d  mis=%d  -> %s\r\n",
    34e0:	00007737          	lui	a4,0x7
    34e4:	50c70713          	addi	a4,a4,1292 # 750c <_data+0x5b8>
    34e8:	fb5ff06f          	j	349c <item+0x30>

000034ec <expect_px>:
    if (got == exp) return;
    34ec:	02d60063          	beq	a2,a3,350c <expect_px+0x20>
    34f0:	00068713          	mv	a4,a3
    g_mis++;
    34f4:	87c1a783          	lw	a5,-1924(gp) # 973c <g_mis>
    34f8:	00178793          	addi	a5,a5,1
    34fc:	86f1ae23          	sw	a5,-1924(gp) # 973c <g_mis>
    if (g_mis_shown < MAX_MIS_PRINT) {
    3500:	8781a783          	lw	a5,-1928(gp) # 9738 <g_mis_shown>
    3504:	00700693          	li	a3,7
    3508:	00f6d463          	bge	a3,a5,3510 <expect_px+0x24>
    350c:	00008067          	ret
{
    3510:	ff010113          	addi	sp,sp,-16
    3514:	00112623          	sw	ra,12(sp)
        g_mis_shown++;
    3518:	00178793          	addi	a5,a5,1
    351c:	86f1ac23          	sw	a5,-1928(gp) # 9738 <g_mis_shown>
        bsp_printf("      mismatch (x=%d,y=%d) got=0x%x exp=0x%x\r\n",
    3520:	00060693          	mv	a3,a2
    3524:	00058613          	mv	a2,a1
    3528:	00050593          	mv	a1,a0
    352c:	00007537          	lui	a0,0x7
    3530:	56c50513          	addi	a0,a0,1388 # 756c <_data+0x618>
    3534:	f50ff0ef          	jal	2c84 <bsp_printf>
}
    3538:	00c12083          	lw	ra,12(sp)
    353c:	01010113          	addi	sp,sp,16
    3540:	00008067          	ret

00003544 <chk_rect>:
{
    3544:	fd010113          	addi	sp,sp,-48
    3548:	02112623          	sw	ra,44(sp)
    354c:	02812423          	sw	s0,40(sp)
    3550:	02912223          	sw	s1,36(sp)
    3554:	03212023          	sw	s2,32(sp)
    3558:	01312e23          	sw	s3,28(sp)
    355c:	01412c23          	sw	s4,24(sp)
    3560:	01512a23          	sw	s5,20(sp)
    3564:	01612823          	sw	s6,16(sp)
    3568:	01712623          	sw	s7,12(sp)
    356c:	01812423          	sw	s8,8(sp)
    3570:	01912223          	sw	s9,4(sp)
    3574:	01a12023          	sw	s10,0(sp)
    3578:	00050c93          	mv	s9,a0
    357c:	00058c13          	mv	s8,a1
    3580:	00060b93          	mv	s7,a2
    3584:	00068b13          	mv	s6,a3
    3588:	00070a13          	mv	s4,a4
    358c:	00078d13          	mv	s10,a5
    3590:	00080a93          	mv	s5,a6
    for (j = 0; j < h; j++)
    3594:	00000993          	li	s3,0
    3598:	0400006f          	j	35d8 <chk_rect+0x94>
            expect_px(x + i, y + j, rd16(PIX(base, stride, x + i, y + j)), exp);
    359c:	017404b3          	add	s1,s0,s7
    35a0:	01698933          	add	s2,s3,s6
    35a4:	03890533          	mul	a0,s2,s8
    35a8:	00149793          	slli	a5,s1,0x1
    35ac:	00f50533          	add	a0,a0,a5
    35b0:	01950533          	add	a0,a0,s9
    35b4:	ac0fe0ef          	jal	1874 <rd16>
    35b8:	00050613          	mv	a2,a0
    35bc:	000a8693          	mv	a3,s5
    35c0:	00090593          	mv	a1,s2
    35c4:	00048513          	mv	a0,s1
    35c8:	f25ff0ef          	jal	34ec <expect_px>
        for (i = 0; i < w; i++)
    35cc:	00140413          	addi	s0,s0,1
    35d0:	fd4446e3          	blt	s0,s4,359c <chk_rect+0x58>
    for (j = 0; j < h; j++)
    35d4:	00198993          	addi	s3,s3,1
    35d8:	01a9d663          	bge	s3,s10,35e4 <chk_rect+0xa0>
        for (i = 0; i < w; i++)
    35dc:	00000413          	li	s0,0
    35e0:	ff1ff06f          	j	35d0 <chk_rect+0x8c>
}
    35e4:	02c12083          	lw	ra,44(sp)
    35e8:	02812403          	lw	s0,40(sp)
    35ec:	02412483          	lw	s1,36(sp)
    35f0:	02012903          	lw	s2,32(sp)
    35f4:	01c12983          	lw	s3,28(sp)
    35f8:	01812a03          	lw	s4,24(sp)
    35fc:	01412a83          	lw	s5,20(sp)
    3600:	01012b03          	lw	s6,16(sp)
    3604:	00c12b83          	lw	s7,12(sp)
    3608:	00812c03          	lw	s8,8(sp)
    360c:	00412c83          	lw	s9,4(sp)
    3610:	00012d03          	lw	s10,0(sp)
    3614:	03010113          	addi	sp,sp,48
    3618:	00008067          	ret

0000361c <chk_outside>:
{
    361c:	fb010113          	addi	sp,sp,-80
    3620:	04112623          	sw	ra,76(sp)
    3624:	04812423          	sw	s0,72(sp)
    3628:	04912223          	sw	s1,68(sp)
    362c:	05212023          	sw	s2,64(sp)
    3630:	03312e23          	sw	s3,60(sp)
    3634:	03412c23          	sw	s4,56(sp)
    3638:	03512a23          	sw	s5,52(sp)
    363c:	03612823          	sw	s6,48(sp)
    3640:	03712623          	sw	s7,44(sp)
    3644:	03812423          	sw	s8,40(sp)
    3648:	03912223          	sw	s9,36(sp)
    364c:	03a12023          	sw	s10,32(sp)
    3650:	01b12e23          	sw	s11,28(sp)
    3654:	00050c93          	mv	s9,a0
    3658:	00058c13          	mv	s8,a1
    365c:	00060b93          	mv	s7,a2
    3660:	00068b13          	mv	s6,a3
    3664:	00070a93          	mv	s5,a4
    3668:	00f12623          	sw	a5,12(sp)
    366c:	00080993          	mv	s3,a6
    3670:	01112423          	sw	a7,8(sp)
    3674:	05012d83          	lw	s11,80(sp)
    3678:	05812d03          	lw	s10,88(sp)
    for (j = 0; j < h; j++) {
    367c:	00000a13          	li	s4,0
    3680:	0640006f          	j	36e4 <chk_outside+0xc8>
            expect_px(ax, ay, rd16(PIX(base, stride, ax, ay)), exp);
    3684:	03890533          	mul	a0,s2,s8
    3688:	00141793          	slli	a5,s0,0x1
    368c:	00f50533          	add	a0,a0,a5
    3690:	01950533          	add	a0,a0,s9
    3694:	9e0fe0ef          	jal	1874 <rd16>
    3698:	00050613          	mv	a2,a0
    369c:	000d0693          	mv	a3,s10
    36a0:	00090593          	mv	a1,s2
    36a4:	00040513          	mv	a0,s0
    36a8:	e45ff0ef          	jal	34ec <expect_px>
        for (i = 0; i < w; i++) {
    36ac:	00148493          	addi	s1,s1,1
    36b0:	0354d863          	bge	s1,s5,36e0 <chk_outside+0xc4>
            int ax = x + i, ay = y + j;
    36b4:	01748433          	add	s0,s1,s7
    36b8:	016a0933          	add	s2,s4,s6
            if (ax >= ix && ax < ix + iw && ay >= iy && ay < iy + ih) continue;
    36bc:	fd3444e3          	blt	s0,s3,3684 <chk_outside+0x68>
    36c0:	01b987b3          	add	a5,s3,s11
    36c4:	fcf450e3          	bge	s0,a5,3684 <chk_outside+0x68>
    36c8:	00812783          	lw	a5,8(sp)
    36cc:	faf94ce3          	blt	s2,a5,3684 <chk_outside+0x68>
    36d0:	05412703          	lw	a4,84(sp)
    36d4:	00e787b3          	add	a5,a5,a4
    36d8:	faf956e3          	bge	s2,a5,3684 <chk_outside+0x68>
    36dc:	fd1ff06f          	j	36ac <chk_outside+0x90>
    for (j = 0; j < h; j++) {
    36e0:	001a0a13          	addi	s4,s4,1
    36e4:	00c12783          	lw	a5,12(sp)
    36e8:	00fa5663          	bge	s4,a5,36f4 <chk_outside+0xd8>
        for (i = 0; i < w; i++) {
    36ec:	00000493          	li	s1,0
    36f0:	fc1ff06f          	j	36b0 <chk_outside+0x94>
}
    36f4:	04c12083          	lw	ra,76(sp)
    36f8:	04812403          	lw	s0,72(sp)
    36fc:	04412483          	lw	s1,68(sp)
    3700:	04012903          	lw	s2,64(sp)
    3704:	03c12983          	lw	s3,60(sp)
    3708:	03812a03          	lw	s4,56(sp)
    370c:	03412a83          	lw	s5,52(sp)
    3710:	03012b03          	lw	s6,48(sp)
    3714:	02c12b83          	lw	s7,44(sp)
    3718:	02812c03          	lw	s8,40(sp)
    371c:	02412c83          	lw	s9,36(sp)
    3720:	02012d03          	lw	s10,32(sp)
    3724:	01c12d83          	lw	s11,28(sp)
    3728:	05010113          	addi	sp,sp,80
    372c:	00008067          	ret

00003730 <chk_pat>:
{
    3730:	fc010113          	addi	sp,sp,-64
    3734:	02112e23          	sw	ra,60(sp)
    3738:	02812c23          	sw	s0,56(sp)
    373c:	02912a23          	sw	s1,52(sp)
    3740:	03212823          	sw	s2,48(sp)
    3744:	03312623          	sw	s3,44(sp)
    3748:	03412423          	sw	s4,40(sp)
    374c:	03512223          	sw	s5,36(sp)
    3750:	03612023          	sw	s6,32(sp)
    3754:	01712e23          	sw	s7,28(sp)
    3758:	01812c23          	sw	s8,24(sp)
    375c:	01912a23          	sw	s9,20(sp)
    3760:	01a12823          	sw	s10,16(sp)
    3764:	01b12623          	sw	s11,12(sp)
    3768:	00050d13          	mv	s10,a0
    376c:	00058c93          	mv	s9,a1
    3770:	00060c13          	mv	s8,a2
    3774:	00068b93          	mv	s7,a3
    3778:	00070a13          	mv	s4,a4
    377c:	00078d93          	mv	s11,a5
    3780:	00080b13          	mv	s6,a6
    3784:	00088a93          	mv	s5,a7
    for (j = 0; j < h; j++)
    3788:	00000993          	li	s3,0
    378c:	0480006f          	j	37d4 <chk_pat+0xa4>
            expect_px(x + i, y + j, rd16(PIX(base, stride, x + i, y + j)),
    3790:	018404b3          	add	s1,s0,s8
    3794:	01798933          	add	s2,s3,s7
    3798:	03990533          	mul	a0,s2,s9
    379c:	00149793          	slli	a5,s1,0x1
    37a0:	00f50533          	add	a0,a0,a5
    37a4:	01a50533          	add	a0,a0,s10
    37a8:	8ccfe0ef          	jal	1874 <rd16>
    37ac:	00050613          	mv	a2,a0
                      pat + (uint32_t)j * rowmul + (uint32_t)i);
    37b0:	035986b3          	mul	a3,s3,s5
    37b4:	016686b3          	add	a3,a3,s6
            expect_px(x + i, y + j, rd16(PIX(base, stride, x + i, y + j)),
    37b8:	008686b3          	add	a3,a3,s0
    37bc:	00090593          	mv	a1,s2
    37c0:	00048513          	mv	a0,s1
    37c4:	d29ff0ef          	jal	34ec <expect_px>
        for (i = 0; i < w; i++)
    37c8:	00140413          	addi	s0,s0,1
    37cc:	fd4442e3          	blt	s0,s4,3790 <chk_pat+0x60>
    for (j = 0; j < h; j++)
    37d0:	00198993          	addi	s3,s3,1
    37d4:	01b9d663          	bge	s3,s11,37e0 <chk_pat+0xb0>
        for (i = 0; i < w; i++)
    37d8:	00000413          	li	s0,0
    37dc:	ff1ff06f          	j	37cc <chk_pat+0x9c>
}
    37e0:	03c12083          	lw	ra,60(sp)
    37e4:	03812403          	lw	s0,56(sp)
    37e8:	03412483          	lw	s1,52(sp)
    37ec:	03012903          	lw	s2,48(sp)
    37f0:	02c12983          	lw	s3,44(sp)
    37f4:	02812a03          	lw	s4,40(sp)
    37f8:	02412a83          	lw	s5,36(sp)
    37fc:	02012b03          	lw	s6,32(sp)
    3800:	01c12b83          	lw	s7,28(sp)
    3804:	01812c03          	lw	s8,24(sp)
    3808:	01412c83          	lw	s9,20(sp)
    380c:	01012d03          	lw	s10,16(sp)
    3810:	00c12d83          	lw	s11,12(sp)
    3814:	04010113          	addi	sp,sp,64
    3818:	00008067          	ret

0000381c <test_burst>:
{
    381c:	fd010113          	addi	sp,sp,-48
    3820:	02112623          	sw	ra,44(sp)
    3824:	03212023          	sw	s2,32(sp)
    3828:	01312e23          	sw	s3,28(sp)
    382c:	00050993          	mv	s3,a0
                          : "5b FIFO 突发 300 条 1x1 FILL（带 CMD_FIFO_COUNT 等待）";
    3830:	06050463          	beqz	a0,3898 <test_burst+0x7c>
    3834:	00007937          	lui	s2,0x7
    3838:	59c90913          	addi	s2,s2,1436 # 759c <_data+0x648>
    SKIP_IF_DEAD(tag);
    383c:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3840:	06078263          	beqz	a5,38a4 <test_burst+0x88>
    3844:	02812423          	sw	s0,40(sp)
    3848:	02912223          	sw	s1,36(sp)
    384c:	01412c23          	sw	s4,24(sp)
    3850:	01512a23          	sw	s5,20(sp)
    3854:	01612823          	sw	s6,16(sp)
    fill_rect_cpu(FB1_BASE, FB_STRIDE, BURST_X, BURST_Y, BURST_COLS, BURST_N / BURST_COLS,
    3858:	00001837          	lui	a6,0x1
    385c:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    3860:	00f00793          	li	a5,15
    3864:	01400713          	li	a4,20
    3868:	19000693          	li	a3,400
    386c:	25800613          	li	a2,600
    3870:	78000593          	li	a1,1920
    3874:	00401537          	lui	a0,0x401
    3878:	824fe0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    387c:	8e4fe0ef          	jal	1960 <cache_evict>
    g_scene_ctx = 0;                 /* 现场上下文：突发不属于压测帧（只影响出错打印） */
    3880:	8401aa23          	sw	zero,-1964(gp) # 9714 <g_scene_ctx>
    g_ins_frame = 0;
    3884:	8601a223          	sw	zero,-1948(gp) # 9724 <g_ins_frame>
    g_last_seq  = 0;
    3888:	8601a423          	sw	zero,-1944(gp) # 9728 <g_last_seq>
    int i, stuck = 0;
    388c:	00000a13          	li	s4,0
    for (i = 0; i < BURST_N; i++) {
    3890:	00000493          	li	s1,0
    3894:	0680006f          	j	38fc <test_burst+0xe0>
                          : "5b FIFO 突发 300 条 1x1 FILL（带 CMD_FIFO_COUNT 等待）";
    3898:	00007937          	lui	s2,0x7
    389c:	5dc90913          	addi	s2,s2,1500 # 75dc <_data+0x688>
    38a0:	f9dff06f          	j	383c <test_burst+0x20>
    SKIP_IF_DEAD(tag);
    38a4:	fff00613          	li	a2,-1
    38a8:	00000593          	li	a1,0
    38ac:	00090513          	mv	a0,s2
    38b0:	bbdff0ef          	jal	346c <item>
    38b4:	1740006f          	j	3a28 <test_burst+0x20c>
                        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) { stuck = 1; break; }
    38b8:	00100a13          	li	s4,1
                    if (stuck) break;
    38bc:	120a1863          	bnez	s4,39ec <test_burst+0x1d0>
            blt_push_cmd_raw(BLT_OP_FILL, 0u, dst, 0u, FB_STRIDE, 1u, 1u, 0xFFu, color);
    38c0:	01512023          	sw	s5,0(sp)
    38c4:	0ff00893          	li	a7,255
    38c8:	00100813          	li	a6,1
    38cc:	00100793          	li	a5,1
    38d0:	78000713          	li	a4,1920
    38d4:	00000693          	li	a3,0
    38d8:	00040613          	mv	a2,s0
    38dc:	00000593          	li	a1,0
    38e0:	00100513          	li	a0,1
    38e4:	cf0fe0ef          	jal	1dd4 <blt_push_cmd_raw>
        g_ins_frame++;                 /* 现场计数：只影响出错打印，不影响任何判定 */
    38e8:	8641a783          	lw	a5,-1948(gp) # 9724 <g_ins_frame>
    38ec:	00178793          	addi	a5,a5,1
    38f0:	86f1a223          	sw	a5,-1948(gp) # 9724 <g_ins_frame>
        g_last_seq = g_ins_frame;
    38f4:	86f1a423          	sw	a5,-1944(gp) # 9728 <g_last_seq>
    for (i = 0; i < BURST_N; i++) {
    38f8:	00148493          	addi	s1,s1,1
    38fc:	12b00793          	li	a5,299
    3900:	0e97c663          	blt	a5,s1,39ec <test_burst+0x1d0>
        uint32_t dst   = PIX(FB1_BASE, FB_STRIDE, BURST_X + (i % BURST_COLS),
    3904:	01400793          	li	a5,20
    3908:	02f4c733          	div	a4,s1,a5
    390c:	19070713          	addi	a4,a4,400
    3910:	02f4e7b3          	rem	a5,s1,a5
    3914:	00471613          	slli	a2,a4,0x4
    3918:	40e60633          	sub	a2,a2,a4
    391c:	00661613          	slli	a2,a2,0x6
    3920:	00f60633          	add	a2,a2,a5
    3924:	002017b7          	lui	a5,0x201
    3928:	a5878793          	addi	a5,a5,-1448 # 200a58 <__freertos_irq_stack_top+0x1f3d68>
    392c:	00f60633          	add	a2,a2,a5
    3930:	00161413          	slli	s0,a2,0x1
        uint32_t color = 0x4000u + (uint32_t)i;
    3934:	000047b7          	lui	a5,0x4
    3938:	00f48ab3          	add	s5,s1,a5
        if (raw) {
    393c:	06098863          	beqz	s3,39ac <test_burst+0x190>
            if ((i & 31) == 0) {
    3940:	01f4f793          	andi	a5,s1,31
    3944:	f6079ee3          	bnez	a5,38c0 <test_burst+0xa4>
                if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) { stuck = 1; break; }
    3948:	00400513          	li	a0,4
    394c:	f41fd0ef          	jal	188c <blt_rd>
    3950:	00457513          	andi	a0,a0,4
    3954:	08051a63          	bnez	a0,39e8 <test_burst+0x1cc>
                if (blt_rd(BLT_CMD_FIFO_COUNT) >= (BLT_CMD_FIFO_DEPTH - 1)) {
    3958:	00c00513          	li	a0,12
    395c:	f31fd0ef          	jal	188c <blt_rd>
    3960:	0fe00793          	li	a5,254
    3964:	f4a7fee3          	bgeu	a5,a0,38c0 <test_burst+0xa4>
                    uint64_t wt = tick();
    3968:	eb9fd0ef          	jal	1820 <tick>
    396c:	00050b13          	mv	s6,a0
                    while (blt_rd(BLT_CMD_FIFO_COUNT) >= (BLT_CMD_FIFO_DEPTH - 1)) {
    3970:	00c00513          	li	a0,12
    3974:	f19fd0ef          	jal	188c <blt_rd>
    3978:	0fe00793          	li	a5,254
    397c:	f4a7f0e3          	bgeu	a5,a0,38bc <test_burst+0xa0>
                        if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) { stuck = 1; break; }
    3980:	00400513          	li	a0,4
    3984:	f09fd0ef          	jal	188c <blt_rd>
    3988:	00457513          	andi	a0,a0,4
    398c:	f20516e3          	bnez	a0,38b8 <test_burst+0x9c>
                        if ((uint32_t)(tick() - wt) > BLT_FAST_TICKS) { stuck = 1; break; }
    3990:	e91fd0ef          	jal	1820 <tick>
    3994:	41650533          	sub	a0,a0,s6
    3998:	013137b7          	lui	a5,0x1313
    399c:	d0078793          	addi	a5,a5,-768 # 1312d00 <__freertos_irq_stack_top+0x1306010>
    39a0:	fca7f8e3          	bgeu	a5,a0,3970 <test_burst+0x154>
    39a4:	00100a13          	li	s4,1
    39a8:	f15ff06f          	j	38bc <test_burst+0xa0>
            int pr = blt_push_cmd(BLT_OP_FILL, 0u, dst, 0u, FB_STRIDE, 1u, 1u, 0xFFu, color);
    39ac:	01512023          	sw	s5,0(sp)
    39b0:	0ff00893          	li	a7,255
    39b4:	00100813          	li	a6,1
    39b8:	00100793          	li	a5,1
    39bc:	78000713          	li	a4,1920
    39c0:	00000693          	li	a3,0
    39c4:	00040613          	mv	a2,s0
    39c8:	00000593          	li	a1,0
    39cc:	00100513          	li	a0,1
    39d0:	b48fe0ef          	jal	1d18 <blt_push_cmd>
            if (pr != 0) { op_fail(pr, "5b burst push"); stuck = 1; break; }
    39d4:	f0050ae3          	beqz	a0,38e8 <test_burst+0xcc>
    39d8:	000075b7          	lui	a1,0x7
    39dc:	63858593          	addi	a1,a1,1592 # 7638 <_data+0x6e4>
    39e0:	f28ff0ef          	jal	3108 <op_fail>
    if (stuck) {
    39e4:	00c0006f          	j	39f0 <test_burst+0x1d4>
                if (blt_rd(BLT_STATUS) & BLT_STATUS_ERR) { stuck = 1; break; }
    39e8:	00100a13          	li	s4,1
    if (stuck) {
    39ec:	040a0863          	beqz	s4,3a3c <test_burst+0x220>
        bsp_printf("      突发被中止：引擎 ERR / FIFO 长时间不消费（已灌入 %d/%d 条）\r\n",
    39f0:	12c00613          	li	a2,300
    39f4:	00048593          	mv	a1,s1
    39f8:	00007537          	lui	a0,0x7
    39fc:	64850513          	addi	a0,a0,1608 # 7648 <_data+0x6f4>
    3a00:	a84ff0ef          	jal	2c84 <bsp_printf>
        item(tag, 0u, -1);
    3a04:	fff00613          	li	a2,-1
    3a08:	00000593          	li	a1,0
    3a0c:	00090513          	mv	a0,s2
    3a10:	a5dff0ef          	jal	346c <item>
        return;
    3a14:	02812403          	lw	s0,40(sp)
    3a18:	02412483          	lw	s1,36(sp)
    3a1c:	01812a03          	lw	s4,24(sp)
    3a20:	01412a83          	lw	s5,20(sp)
    3a24:	01012b03          	lw	s6,16(sp)
}
    3a28:	02c12083          	lw	ra,44(sp)
    3a2c:	02012903          	lw	s2,32(sp)
    3a30:	01c12983          	lw	s3,28(sp)
    3a34:	03010113          	addi	sp,sp,48
    3a38:	00008067          	ret
    if (op_fail(blt_wait_done(BLT_TIMEOUT_TICKS), raw ? "5c burst raw" : "5b burst")) {
    3a3c:	0bebc537          	lui	a0,0xbebc
    3a40:	20050513          	addi	a0,a0,512 # bebc200 <__freertos_irq_stack_top+0xbeaf510>
    3a44:	e74fe0ef          	jal	20b8 <blt_wait_done>
    3a48:	02098263          	beqz	s3,3a6c <test_burst+0x250>
    3a4c:	000075b7          	lui	a1,0x7
    3a50:	61c58593          	addi	a1,a1,1564 # 761c <_data+0x6c8>
    3a54:	eb4ff0ef          	jal	3108 <op_fail>
    3a58:	00050493          	mv	s1,a0
    3a5c:	00051e63          	bnez	a0,3a78 <test_burst+0x25c>
    cache_invalidate();
    3a60:	f61fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    3a64:	f65fd0ef          	jal	19c8 <mis_reset>
    for (i = 0; i < BURST_N; i++)
    3a68:	0880006f          	j	3af0 <test_burst+0x2d4>
    if (op_fail(blt_wait_done(BLT_TIMEOUT_TICKS), raw ? "5c burst raw" : "5b burst")) {
    3a6c:	000075b7          	lui	a1,0x7
    3a70:	62c58593          	addi	a1,a1,1580 # 762c <_data+0x6d8>
    3a74:	fe1ff06f          	j	3a54 <test_burst+0x238>
        item(tag, 0u, -1);
    3a78:	fff00613          	li	a2,-1
    3a7c:	00000593          	li	a1,0
    3a80:	00090513          	mv	a0,s2
    3a84:	9e9ff0ef          	jal	346c <item>
        return;
    3a88:	02812403          	lw	s0,40(sp)
    3a8c:	02412483          	lw	s1,36(sp)
    3a90:	01812a03          	lw	s4,24(sp)
    3a94:	01412a83          	lw	s5,20(sp)
    3a98:	01012b03          	lw	s6,16(sp)
    3a9c:	f8dff06f          	j	3a28 <test_burst+0x20c>
        expect_px(BURST_X + (i % BURST_COLS), BURST_Y + (i / BURST_COLS),
    3aa0:	01400413          	li	s0,20
    3aa4:	0284e9b3          	rem	s3,s1,s0
    3aa8:	0284c433          	div	s0,s1,s0
    3aac:	19040413          	addi	s0,s0,400
                  rd16(PIX(FB1_BASE, FB_STRIDE, BURST_X + (i % BURST_COLS),
    3ab0:	00441513          	slli	a0,s0,0x4
    3ab4:	40850533          	sub	a0,a0,s0
    3ab8:	00651513          	slli	a0,a0,0x6
    3abc:	01350533          	add	a0,a0,s3
    3ac0:	002017b7          	lui	a5,0x201
    3ac4:	a5878793          	addi	a5,a5,-1448 # 200a58 <__freertos_irq_stack_top+0x1f3d68>
    3ac8:	00f50533          	add	a0,a0,a5
    3acc:	00151513          	slli	a0,a0,0x1
    3ad0:	da5fd0ef          	jal	1874 <rd16>
    3ad4:	00050613          	mv	a2,a0
        expect_px(BURST_X + (i % BURST_COLS), BURST_Y + (i / BURST_COLS),
    3ad8:	000046b7          	lui	a3,0x4
    3adc:	00d486b3          	add	a3,s1,a3
    3ae0:	00040593          	mv	a1,s0
    3ae4:	25898513          	addi	a0,s3,600
    3ae8:	a05ff0ef          	jal	34ec <expect_px>
    for (i = 0; i < BURST_N; i++)
    3aec:	00148493          	addi	s1,s1,1
    3af0:	12b00793          	li	a5,299
    3af4:	fa97d6e3          	bge	a5,s1,3aa0 <test_burst+0x284>
    item(tag, blt_rd(BLT_PERF), g_mis);
    3af8:	01c00513          	li	a0,28
    3afc:	d91fd0ef          	jal	188c <blt_rd>
    3b00:	00050593          	mv	a1,a0
    3b04:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    3b08:	00090513          	mv	a0,s2
    3b0c:	961ff0ef          	jal	346c <item>
    3b10:	02812403          	lw	s0,40(sp)
    3b14:	02412483          	lw	s1,36(sp)
    3b18:	01812a03          	lw	s4,24(sp)
    3b1c:	01412a83          	lw	s5,20(sp)
    3b20:	01012b03          	lw	s6,16(sp)
    3b24:	f05ff06f          	j	3a28 <test_burst+0x20c>

00003b28 <tf_a1>:
{
    3b28:	fe010113          	addi	sp,sp,-32
    3b2c:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("A1 FILL 32x16 aligned @FB1(0,0)");
    3b30:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3b34:	0e078a63          	beqz	a5,3c28 <tf_a1+0x100>
    bsp_printf("  A1: FILL 32x16 -> FB1(0,0) color=0x%x，四周哨兵 0x%x（dst 16B 对齐）\r\n",
    3b38:	00001637          	lui	a2,0x1
    3b3c:	23460613          	addi	a2,a2,564 # 1234 <main+0x130>
    3b40:	7e000593          	li	a1,2016
    3b44:	00007537          	lui	a0,0x7
    3b48:	6c050513          	addi	a0,a0,1728 # 76c0 <_data+0x76c>
    3b4c:	938ff0ef          	jal	2c84 <bsp_printf>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 0, 40, 18, (uint16_t)SENT);   /* 32x16 + 右侧/下方哨兵 */
    3b50:	00001837          	lui	a6,0x1
    3b54:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    3b58:	01200793          	li	a5,18
    3b5c:	02800713          	li	a4,40
    3b60:	00000693          	li	a3,0
    3b64:	00000613          	li	a2,0
    3b68:	78000593          	li	a1,1920
    3b6c:	00401537          	lui	a0,0x401
    3b70:	d2dfd0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    3b74:	dedfd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_fill(FB1_BASE, FB_STRIDE, 32u, 16u, C_GREEN), "A1 FILL")) {
    3b78:	7e000713          	li	a4,2016
    3b7c:	01000693          	li	a3,16
    3b80:	02000613          	li	a2,32
    3b84:	78000593          	li	a1,1920
    3b88:	00401537          	lui	a0,0x401
    3b8c:	925fe0ef          	jal	24b0 <blt_fill>
    3b90:	000075b7          	lui	a1,0x7
    3b94:	71458593          	addi	a1,a1,1812 # 7714 <_data+0x7c0>
    3b98:	d70ff0ef          	jal	3108 <op_fail>
    3b9c:	0a051263          	bnez	a0,3c40 <tf_a1+0x118>
    cache_invalidate();
    3ba0:	e21fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    3ba4:	e25fd0ef          	jal	19c8 <mis_reset>
    chk_rect(FB1_BASE, FB_STRIDE, 0, 0, 32, 16, C_GREEN);           /* 目标块全绿 */
    3ba8:	7e000813          	li	a6,2016
    3bac:	01000793          	li	a5,16
    3bb0:	02000713          	li	a4,32
    3bb4:	00000693          	li	a3,0
    3bb8:	00000613          	li	a2,0
    3bbc:	78000593          	li	a1,1920
    3bc0:	00401537          	lui	a0,0x401
    3bc4:	981ff0ef          	jal	3544 <chk_rect>
    chk_outside(FB1_BASE, FB_STRIDE, 0, 0, 40, 18, 0, 0, 32, 16, SENT);  /* 右侧/下方哨兵 */
    3bc8:	000017b7          	lui	a5,0x1
    3bcc:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    3bd0:	00f12423          	sw	a5,8(sp)
    3bd4:	01000793          	li	a5,16
    3bd8:	00f12223          	sw	a5,4(sp)
    3bdc:	02000793          	li	a5,32
    3be0:	00f12023          	sw	a5,0(sp)
    3be4:	00000893          	li	a7,0
    3be8:	00000813          	li	a6,0
    3bec:	01200793          	li	a5,18
    3bf0:	02800713          	li	a4,40
    3bf4:	00000693          	li	a3,0
    3bf8:	00000613          	li	a2,0
    3bfc:	78000593          	li	a1,1920
    3c00:	00401537          	lui	a0,0x401
    3c04:	a19ff0ef          	jal	361c <chk_outside>
    item("A1 FILL 32x16 aligned @FB1(0,0)", g_perf, g_mis);
    3c08:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    3c0c:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    3c10:	00007537          	lui	a0,0x7
    3c14:	6a050513          	addi	a0,a0,1696 # 76a0 <_data+0x74c>
    3c18:	855ff0ef          	jal	346c <item>
}
    3c1c:	01c12083          	lw	ra,28(sp)
    3c20:	02010113          	addi	sp,sp,32
    3c24:	00008067          	ret
    SKIP_IF_DEAD("A1 FILL 32x16 aligned @FB1(0,0)");
    3c28:	fff00613          	li	a2,-1
    3c2c:	00000593          	li	a1,0
    3c30:	00007537          	lui	a0,0x7
    3c34:	6a050513          	addi	a0,a0,1696 # 76a0 <_data+0x74c>
    3c38:	835ff0ef          	jal	346c <item>
    3c3c:	fe1ff06f          	j	3c1c <tf_a1+0xf4>
        item("A1 FILL 32x16 aligned @FB1(0,0)", 0u, -1);
    3c40:	fff00613          	li	a2,-1
    3c44:	00000593          	li	a1,0
    3c48:	00007537          	lui	a0,0x7
    3c4c:	6a050513          	addi	a0,a0,1696 # 76a0 <_data+0x74c>
    3c50:	81dff0ef          	jal	346c <item>
        return;
    3c54:	fc9ff06f          	j	3c1c <tf_a1+0xf4>

00003c58 <tf_a2>:
{
    3c58:	fe010113          	addi	sp,sp,-32
    3c5c:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("A2 FILL 32x16 @x=3 (dst unaligned)");
    3c60:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3c64:	0e078863          	beqz	a5,3d54 <tf_a2+0xfc>
    bsp_printf("  A2: FILL 32x16 -> FB1(3,40) color=0x%x（行首字节偏移 6，px_skip=3，覆盖读改写）\r\n",
    3c68:	7e000593          	li	a1,2016
    3c6c:	00007537          	lui	a0,0x7
    3c70:	74050513          	addi	a0,a0,1856 # 7740 <_data+0x7ec>
    3c74:	810ff0ef          	jal	2c84 <bsp_printf>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 39, 40, 18, (uint16_t)SENT);  /* x0..39, y39..56 */
    3c78:	00001837          	lui	a6,0x1
    3c7c:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    3c80:	01200793          	li	a5,18
    3c84:	02800713          	li	a4,40
    3c88:	02700693          	li	a3,39
    3c8c:	00000613          	li	a2,0
    3c90:	78000593          	li	a1,1920
    3c94:	00401537          	lui	a0,0x401
    3c98:	c05fd0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    3c9c:	cc5fd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_fill(PIX(FB1_BASE, FB_STRIDE, 3, 40), FB_STRIDE, 32u, 16u, C_GREEN), "A2 FILL")) {
    3ca0:	7e000713          	li	a4,2016
    3ca4:	01000693          	li	a3,16
    3ca8:	02000613          	li	a2,32
    3cac:	78000593          	li	a1,1920
    3cb0:	00414537          	lui	a0,0x414
    3cb4:	c0650513          	addi	a0,a0,-1018 # 413c06 <__freertos_irq_stack_top+0x406f16>
    3cb8:	ff8fe0ef          	jal	24b0 <blt_fill>
    3cbc:	000075b7          	lui	a1,0x7
    3cc0:	7a458593          	addi	a1,a1,1956 # 77a4 <_data+0x850>
    3cc4:	c44ff0ef          	jal	3108 <op_fail>
    3cc8:	0a051263          	bnez	a0,3d6c <tf_a2+0x114>
    cache_invalidate();
    3ccc:	cf5fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    3cd0:	cf9fd0ef          	jal	19c8 <mis_reset>
    chk_rect(FB1_BASE, FB_STRIDE, 3, 40, 32, 16, C_GREEN);   /* 目标块 */
    3cd4:	7e000813          	li	a6,2016
    3cd8:	01000793          	li	a5,16
    3cdc:	02000713          	li	a4,32
    3ce0:	02800693          	li	a3,40
    3ce4:	00300613          	li	a2,3
    3ce8:	78000593          	li	a1,1920
    3cec:	00401537          	lui	a0,0x401
    3cf0:	855ff0ef          	jal	3544 <chk_rect>
    chk_outside(FB1_BASE, FB_STRIDE, 0, 39, 40, 18, 3, 40, 32, 16, SENT);
    3cf4:	000017b7          	lui	a5,0x1
    3cf8:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    3cfc:	00f12423          	sw	a5,8(sp)
    3d00:	01000793          	li	a5,16
    3d04:	00f12223          	sw	a5,4(sp)
    3d08:	02000793          	li	a5,32
    3d0c:	00f12023          	sw	a5,0(sp)
    3d10:	02800893          	li	a7,40
    3d14:	00300813          	li	a6,3
    3d18:	01200793          	li	a5,18
    3d1c:	02800713          	li	a4,40
    3d20:	02700693          	li	a3,39
    3d24:	00000613          	li	a2,0
    3d28:	78000593          	li	a1,1920
    3d2c:	00401537          	lui	a0,0x401
    3d30:	8edff0ef          	jal	361c <chk_outside>
    item("A2 FILL 32x16 @x=3 (dst unaligned)", g_perf, g_mis);
    3d34:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    3d38:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    3d3c:	00007537          	lui	a0,0x7
    3d40:	71c50513          	addi	a0,a0,1820 # 771c <_data+0x7c8>
    3d44:	f28ff0ef          	jal	346c <item>
}
    3d48:	01c12083          	lw	ra,28(sp)
    3d4c:	02010113          	addi	sp,sp,32
    3d50:	00008067          	ret
    SKIP_IF_DEAD("A2 FILL 32x16 @x=3 (dst unaligned)");
    3d54:	fff00613          	li	a2,-1
    3d58:	00000593          	li	a1,0
    3d5c:	00007537          	lui	a0,0x7
    3d60:	71c50513          	addi	a0,a0,1820 # 771c <_data+0x7c8>
    3d64:	f08ff0ef          	jal	346c <item>
    3d68:	fe1ff06f          	j	3d48 <tf_a2+0xf0>
        item("A2 FILL 32x16 @x=3 (dst unaligned)", 0u, -1);
    3d6c:	fff00613          	li	a2,-1
    3d70:	00000593          	li	a1,0
    3d74:	00007537          	lui	a0,0x7
    3d78:	71c50513          	addi	a0,a0,1820 # 771c <_data+0x7c8>
    3d7c:	ef0ff0ef          	jal	346c <item>
        return;
    3d80:	fc9ff06f          	j	3d48 <tf_a2+0xf0>

00003d84 <tf_a4>:
{
    3d84:	fd010113          	addi	sp,sp,-48
    3d88:	02112623          	sw	ra,44(sp)
    SKIP_IF_DEAD("A4 FILL degenerate 1x64 & 200x1");
    3d8c:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3d90:	1c078663          	beqz	a5,3f5c <tf_a4+0x1d8>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 498, 8, 6, 68, (uint16_t)SENT);   /* x498..503, y8..75 */
    3d94:	00001837          	lui	a6,0x1
    3d98:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    3d9c:	04400793          	li	a5,68
    3da0:	00600713          	li	a4,6
    3da4:	00800693          	li	a3,8
    3da8:	1f200613          	li	a2,498
    3dac:	78000593          	li	a1,1920
    3db0:	00401537          	lui	a0,0x401
    3db4:	ae9fd0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    3db8:	ba9fd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_fill(PIX(FB1_BASE, FB_STRIDE, 500, 10), FB_STRIDE, 1u, 64u, C_RED), "A4 col")) {
    3dbc:	00010737          	lui	a4,0x10
    3dc0:	80070713          	addi	a4,a4,-2048 # f800 <__freertos_irq_stack_top+0x2b10>
    3dc4:	04000693          	li	a3,64
    3dc8:	00100613          	li	a2,1
    3dcc:	78000593          	li	a1,1920
    3dd0:	00406537          	lui	a0,0x406
    3dd4:	ee850513          	addi	a0,a0,-280 # 405ee8 <__freertos_irq_stack_top+0x3f91f8>
    3dd8:	ed8fe0ef          	jal	24b0 <blt_fill>
    3ddc:	000075b7          	lui	a1,0x7
    3de0:	7cc58593          	addi	a1,a1,1996 # 77cc <_data+0x878>
    3de4:	b24ff0ef          	jal	3108 <op_fail>
    3de8:	18051a63          	bnez	a0,3f7c <tf_a4+0x1f8>
    3dec:	02912223          	sw	s1,36(sp)
    pc = g_perf;
    3df0:	8701a483          	lw	s1,-1936(gp) # 9730 <g_perf>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 8, 298, 204, 5, (uint16_t)SENT);  /* x8..211, y298..302 */
    3df4:	00001837          	lui	a6,0x1
    3df8:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    3dfc:	00500793          	li	a5,5
    3e00:	0cc00713          	li	a4,204
    3e04:	12a00693          	li	a3,298
    3e08:	00800613          	li	a2,8
    3e0c:	78000593          	li	a1,1920
    3e10:	00401537          	lui	a0,0x401
    3e14:	a89fd0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    3e18:	b49fd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_fill(PIX(FB1_BASE, FB_STRIDE, 10, 300), FB_STRIDE, 200u, 1u, C_YELLOW), "A4 row")) {
    3e1c:	00010737          	lui	a4,0x10
    3e20:	fe070713          	addi	a4,a4,-32 # ffe0 <__freertos_irq_stack_top+0x32f0>
    3e24:	00100693          	li	a3,1
    3e28:	0c800613          	li	a2,200
    3e2c:	78000593          	li	a1,1920
    3e30:	0048e537          	lui	a0,0x48e
    3e34:	a1450513          	addi	a0,a0,-1516 # 48da14 <__freertos_irq_stack_top+0x480d24>
    3e38:	e78fe0ef          	jal	24b0 <blt_fill>
    3e3c:	000075b7          	lui	a1,0x7
    3e40:	7d458593          	addi	a1,a1,2004 # 77d4 <_data+0x880>
    3e44:	ac4ff0ef          	jal	3108 <op_fail>
    3e48:	14051663          	bnez	a0,3f94 <tf_a4+0x210>
    3e4c:	02812423          	sw	s0,40(sp)
    3e50:	03212023          	sw	s2,32(sp)
    3e54:	01312e23          	sw	s3,28(sp)
    pr = g_perf;
    3e58:	8701a903          	lw	s2,-1936(gp) # 9730 <g_perf>
    cache_invalidate();
    3e5c:	b65fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    3e60:	b69fd0ef          	jal	19c8 <mis_reset>
    chk_rect(FB1_BASE, FB_STRIDE, 500, 10, 1, 64, C_RED);
    3e64:	00010837          	lui	a6,0x10
    3e68:	80080813          	addi	a6,a6,-2048 # f800 <__freertos_irq_stack_top+0x2b10>
    3e6c:	04000793          	li	a5,64
    3e70:	00100713          	li	a4,1
    3e74:	00a00693          	li	a3,10
    3e78:	1f400613          	li	a2,500
    3e7c:	78000593          	li	a1,1920
    3e80:	00401537          	lui	a0,0x401
    3e84:	ec0ff0ef          	jal	3544 <chk_rect>
    chk_outside(FB1_BASE, FB_STRIDE, 498, 8, 6, 68, 500, 10, 1, 64, SENT);
    3e88:	00001437          	lui	s0,0x1
    3e8c:	23440413          	addi	s0,s0,564 # 1234 <main+0x130>
    3e90:	00812423          	sw	s0,8(sp)
    3e94:	04000793          	li	a5,64
    3e98:	00f12223          	sw	a5,4(sp)
    3e9c:	00100993          	li	s3,1
    3ea0:	01312023          	sw	s3,0(sp)
    3ea4:	00a00893          	li	a7,10
    3ea8:	1f400813          	li	a6,500
    3eac:	04400793          	li	a5,68
    3eb0:	00600713          	li	a4,6
    3eb4:	00800693          	li	a3,8
    3eb8:	1f200613          	li	a2,498
    3ebc:	78000593          	li	a1,1920
    3ec0:	00401537          	lui	a0,0x401
    3ec4:	f58ff0ef          	jal	361c <chk_outside>
    chk_rect(FB1_BASE, FB_STRIDE, 10, 300, 200, 1, C_YELLOW);
    3ec8:	00010837          	lui	a6,0x10
    3ecc:	fe080813          	addi	a6,a6,-32 # ffe0 <__freertos_irq_stack_top+0x32f0>
    3ed0:	00100793          	li	a5,1
    3ed4:	0c800713          	li	a4,200
    3ed8:	12c00693          	li	a3,300
    3edc:	00a00613          	li	a2,10
    3ee0:	78000593          	li	a1,1920
    3ee4:	00401537          	lui	a0,0x401
    3ee8:	e5cff0ef          	jal	3544 <chk_rect>
    chk_outside(FB1_BASE, FB_STRIDE, 8, 298, 204, 5, 10, 300, 200, 1, SENT);
    3eec:	00812423          	sw	s0,8(sp)
    3ef0:	01312223          	sw	s3,4(sp)
    3ef4:	0c800793          	li	a5,200
    3ef8:	00f12023          	sw	a5,0(sp)
    3efc:	12c00893          	li	a7,300
    3f00:	00a00813          	li	a6,10
    3f04:	00500793          	li	a5,5
    3f08:	0cc00713          	li	a4,204
    3f0c:	12a00693          	li	a3,298
    3f10:	00800613          	li	a2,8
    3f14:	78000593          	li	a1,1920
    3f18:	00401537          	lui	a0,0x401
    3f1c:	f00ff0ef          	jal	361c <chk_outside>
    bsp_printf("      竖条 PERF=%d cycles / 横条 PERF=%d cycles（横条行首偏移 4B，尾词只写 4B）\r\n",
    3f20:	00090613          	mv	a2,s2
    3f24:	00048593          	mv	a1,s1
    3f28:	00007537          	lui	a0,0x7
    3f2c:	7dc50513          	addi	a0,a0,2012 # 77dc <_data+0x888>
    3f30:	d55fe0ef          	jal	2c84 <bsp_printf>
    item("A4 FILL degenerate 1x64 & 200x1", pc + pr, g_mis);
    3f34:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    3f38:	012485b3          	add	a1,s1,s2
    3f3c:	00007537          	lui	a0,0x7
    3f40:	7ac50513          	addi	a0,a0,1964 # 77ac <_data+0x858>
    3f44:	d28ff0ef          	jal	346c <item>
    3f48:	02812403          	lw	s0,40(sp)
    3f4c:	02412483          	lw	s1,36(sp)
    3f50:	02012903          	lw	s2,32(sp)
    3f54:	01c12983          	lw	s3,28(sp)
    3f58:	0180006f          	j	3f70 <tf_a4+0x1ec>
    SKIP_IF_DEAD("A4 FILL degenerate 1x64 & 200x1");
    3f5c:	fff00613          	li	a2,-1
    3f60:	00000593          	li	a1,0
    3f64:	00007537          	lui	a0,0x7
    3f68:	7ac50513          	addi	a0,a0,1964 # 77ac <_data+0x858>
    3f6c:	d00ff0ef          	jal	346c <item>
}
    3f70:	02c12083          	lw	ra,44(sp)
    3f74:	03010113          	addi	sp,sp,48
    3f78:	00008067          	ret
        item("A4 FILL degenerate 1x64 & 200x1", 0u, -1);
    3f7c:	fff00613          	li	a2,-1
    3f80:	00000593          	li	a1,0
    3f84:	00007537          	lui	a0,0x7
    3f88:	7ac50513          	addi	a0,a0,1964 # 77ac <_data+0x858>
    3f8c:	ce0ff0ef          	jal	346c <item>
        return;
    3f90:	fe1ff06f          	j	3f70 <tf_a4+0x1ec>
        item("A4 FILL degenerate 1x64 & 200x1", pc, -1);
    3f94:	fff00613          	li	a2,-1
    3f98:	00048593          	mv	a1,s1
    3f9c:	00007537          	lui	a0,0x7
    3fa0:	7ac50513          	addi	a0,a0,1964 # 77ac <_data+0x858>
    3fa4:	cc8ff0ef          	jal	346c <item>
        return;
    3fa8:	02412483          	lw	s1,36(sp)
    3fac:	fc5ff06f          	j	3f70 <tf_a4+0x1ec>

00003fb0 <tf_a3>:
{
    3fb0:	ff010113          	addi	sp,sp,-16
    3fb4:	00112623          	sw	ra,12(sp)
    SKIP_IF_DEAD("A3 FILL fullscreen 960x540 -> FB");
    3fb8:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    3fbc:	1e078063          	beqz	a5,419c <tf_a3+0x1ec>
    bsp_printf("  A3: FILL 整屏 %dx%d -> FB_BASE(0x%x) color=0x%x（4 角+中心+末尾越界哨兵）\r\n",
    3fc0:	01000713          	li	a4,16
    3fc4:	003016b7          	lui	a3,0x301
    3fc8:	21c00613          	li	a2,540
    3fcc:	3c000593          	li	a1,960
    3fd0:	00008537          	lui	a0,0x8
    3fd4:	86450513          	addi	a0,a0,-1948 # 7864 <_data+0x910>
    3fd8:	cadfe0ef          	jal	2c84 <bsp_printf>
    wr16(FB_BASE + FB_BYTES, (uint16_t)SENT);
    3fdc:	000015b7          	lui	a1,0x1
    3fe0:	23458593          	addi	a1,a1,564 # 1234 <main+0x130>
    3fe4:	003fe537          	lui	a0,0x3fe
    3fe8:	20050513          	addi	a0,a0,512 # 3fe200 <__freertos_irq_stack_top+0x3f1510>
    3fec:	881fd0ef          	jal	186c <wr16>
    wr16(FB_BASE + FB_BYTES + 2u, (uint16_t)SENT);
    3ff0:	000015b7          	lui	a1,0x1
    3ff4:	23458593          	addi	a1,a1,564 # 1234 <main+0x130>
    3ff8:	003fe537          	lui	a0,0x3fe
    3ffc:	20250513          	addi	a0,a0,514 # 3fe202 <__freertos_irq_stack_top+0x3f1512>
    4000:	86dfd0ef          	jal	186c <wr16>
    cache_evict();
    4004:	95dfd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, STRESS_BG), "A3 FILL fullscreen")) {
    4008:	01000713          	li	a4,16
    400c:	21c00693          	li	a3,540
    4010:	3c000613          	li	a2,960
    4014:	78000593          	li	a1,1920
    4018:	00301537          	lui	a0,0x301
    401c:	c94fe0ef          	jal	24b0 <blt_fill>
    4020:	000085b7          	lui	a1,0x8
    4024:	8c058593          	addi	a1,a1,-1856 # 78c0 <_data+0x96c>
    4028:	8e0ff0ef          	jal	3108 <op_fail>
    402c:	18051463          	bnez	a0,41b4 <tf_a3+0x204>
    4030:	00812423          	sw	s0,8(sp)
    p_perf = g_perf;
    4034:	8701a403          	lw	s0,-1936(gp) # 9730 <g_perf>
    cache_invalidate();
    4038:	989fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    403c:	98dfd0ef          	jal	19c8 <mis_reset>
    expect_px(0, 0, rd16(PIX(FB_BASE, FB_STRIDE, 0, 0)), STRESS_BG);
    4040:	00301537          	lui	a0,0x301
    4044:	831fd0ef          	jal	1874 <rd16>
    4048:	00050613          	mv	a2,a0
    404c:	01000693          	li	a3,16
    4050:	00000593          	li	a1,0
    4054:	00000513          	li	a0,0
    4058:	c94ff0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 0, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 0)), STRESS_BG);
    405c:	00301537          	lui	a0,0x301
    4060:	77e50513          	addi	a0,a0,1918 # 30177e <__freertos_irq_stack_top+0x2f4a8e>
    4064:	811fd0ef          	jal	1874 <rd16>
    4068:	00050613          	mv	a2,a0
    406c:	01000693          	li	a3,16
    4070:	00000593          	li	a1,0
    4074:	3bf00513          	li	a0,959
    4078:	c74ff0ef          	jal	34ec <expect_px>
    expect_px(0, FB_HEIGHT - 1, rd16(PIX(FB_BASE, FB_STRIDE, 0, FB_HEIGHT - 1)), STRESS_BG);
    407c:	003fe537          	lui	a0,0x3fe
    4080:	a8050513          	addi	a0,a0,-1408 # 3fda80 <__freertos_irq_stack_top+0x3f0d90>
    4084:	ff0fd0ef          	jal	1874 <rd16>
    4088:	00050613          	mv	a2,a0
    408c:	01000693          	li	a3,16
    4090:	21b00593          	li	a1,539
    4094:	00000513          	li	a0,0
    4098:	c54ff0ef          	jal	34ec <expect_px>
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, FB_HEIGHT - 1)), STRESS_BG);
    409c:	003fe537          	lui	a0,0x3fe
    40a0:	1fe50513          	addi	a0,a0,510 # 3fe1fe <__freertos_irq_stack_top+0x3f150e>
    40a4:	fd0fd0ef          	jal	1874 <rd16>
    40a8:	00050613          	mv	a2,a0
    expect_px(FB_WIDTH - 1, FB_HEIGHT - 1,
    40ac:	01000693          	li	a3,16
    40b0:	21b00593          	li	a1,539
    40b4:	3bf00513          	li	a0,959
    40b8:	c34ff0ef          	jal	34ec <expect_px>
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH / 2, FB_HEIGHT / 2)), STRESS_BG);
    40bc:	00380537          	lui	a0,0x380
    40c0:	cc050513          	addi	a0,a0,-832 # 37fcc0 <__freertos_irq_stack_top+0x372fd0>
    40c4:	fb0fd0ef          	jal	1874 <rd16>
    40c8:	00050613          	mv	a2,a0
    expect_px(FB_WIDTH / 2, FB_HEIGHT / 2,
    40cc:	01000693          	li	a3,16
    40d0:	10e00593          	li	a1,270
    40d4:	1e000513          	li	a0,480
    40d8:	c14ff0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH / 2, 0, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH / 2, 0)), STRESS_BG);
    40dc:	00301537          	lui	a0,0x301
    40e0:	3c050513          	addi	a0,a0,960 # 3013c0 <__freertos_irq_stack_top+0x2f46d0>
    40e4:	f90fd0ef          	jal	1874 <rd16>
    40e8:	00050613          	mv	a2,a0
    40ec:	01000693          	li	a3,16
    40f0:	00000593          	li	a1,0
    40f4:	1e000513          	li	a0,480
    40f8:	bf4ff0ef          	jal	34ec <expect_px>
    expect_px(0, FB_HEIGHT / 2, rd16(PIX(FB_BASE, FB_STRIDE, 0, FB_HEIGHT / 2)), STRESS_BG);
    40fc:	00380537          	lui	a0,0x380
    4100:	90050513          	addi	a0,a0,-1792 # 37f900 <__freertos_irq_stack_top+0x372c10>
    4104:	f70fd0ef          	jal	1874 <rd16>
    4108:	00050613          	mv	a2,a0
    410c:	01000693          	li	a3,16
    4110:	10e00593          	li	a1,270
    4114:	00000513          	li	a0,0
    4118:	bd4ff0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH, FB_HEIGHT, rd16(FB_BASE + FB_BYTES), SENT);          /* 越界哨兵 */
    411c:	003fe537          	lui	a0,0x3fe
    4120:	20050513          	addi	a0,a0,512 # 3fe200 <__freertos_irq_stack_top+0x3f1510>
    4124:	f50fd0ef          	jal	1874 <rd16>
    4128:	00050613          	mv	a2,a0
    412c:	000016b7          	lui	a3,0x1
    4130:	23468693          	addi	a3,a3,564 # 1234 <main+0x130>
    4134:	21c00593          	li	a1,540
    4138:	3c000513          	li	a0,960
    413c:	bb0ff0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH + 1, FB_HEIGHT, rd16(FB_BASE + FB_BYTES + 2u), SENT);
    4140:	003fe537          	lui	a0,0x3fe
    4144:	20250513          	addi	a0,a0,514 # 3fe202 <__freertos_irq_stack_top+0x3f1512>
    4148:	f2cfd0ef          	jal	1874 <rd16>
    414c:	00050613          	mv	a2,a0
    4150:	000016b7          	lui	a3,0x1
    4154:	23468693          	addi	a3,a3,564 # 1234 <main+0x130>
    4158:	21c00593          	li	a1,540
    415c:	3c100513          	li	a0,961
    4160:	b8cff0ef          	jal	34ec <expect_px>
    bsp_printf("      PERF=%d cycles, CPU 侧下发到 DONE=%d ticks（含轮询/APB 开销）\r\n",
    4164:	86c1a603          	lw	a2,-1940(gp) # 972c <g_opticks>
    4168:	00040593          	mv	a1,s0
    416c:	00008537          	lui	a0,0x8
    4170:	8d450513          	addi	a0,a0,-1836 # 78d4 <_data+0x980>
    4174:	b11fe0ef          	jal	2c84 <bsp_printf>
    item("A3 FILL fullscreen 960x540 -> FB", p_perf, g_mis);
    4178:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    417c:	00040593          	mv	a1,s0
    4180:	00008537          	lui	a0,0x8
    4184:	84050513          	addi	a0,a0,-1984 # 7840 <_data+0x8ec>
    4188:	ae4ff0ef          	jal	346c <item>
    418c:	00812403          	lw	s0,8(sp)
}
    4190:	00c12083          	lw	ra,12(sp)
    4194:	01010113          	addi	sp,sp,16
    4198:	00008067          	ret
    SKIP_IF_DEAD("A3 FILL fullscreen 960x540 -> FB");
    419c:	fff00613          	li	a2,-1
    41a0:	00000593          	li	a1,0
    41a4:	00008537          	lui	a0,0x8
    41a8:	84050513          	addi	a0,a0,-1984 # 7840 <_data+0x8ec>
    41ac:	ac0ff0ef          	jal	346c <item>
    41b0:	fe1ff06f          	j	4190 <tf_a3+0x1e0>
        item("A3 FILL fullscreen 960x540 -> FB", 0u, -1);
    41b4:	fff00613          	li	a2,-1
    41b8:	00000593          	li	a1,0
    41bc:	00008537          	lui	a0,0x8
    41c0:	84050513          	addi	a0,a0,-1984 # 7840 <_data+0x8ec>
    41c4:	aa8ff0ef          	jal	346c <item>
        return;
    41c8:	fc9ff06f          	j	4190 <tf_a3+0x1e0>

000041cc <tb1>:
{
    41cc:	fe010113          	addi	sp,sp,-32
    41d0:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("B1 COPY 32x8 src(stride 64)->FB1(40,20)");
    41d4:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    41d8:	02078663          	beqz	a5,4204 <tb1+0x38>
    41dc:	00812c23          	sw	s0,24(sp)
    41e0:	00912a23          	sw	s1,20(sp)
    bsp_printf("  B1: COPY 32x8 src=0x%x(stride %d) -> FB1(40,20)(stride %d)\r\n",
    41e4:	78000693          	li	a3,1920
    41e8:	04000613          	li	a2,64
    41ec:	001025b7          	lui	a1,0x102
    41f0:	00008537          	lui	a0,0x8
    41f4:	95050513          	addi	a0,a0,-1712 # 7950 <_data+0x9fc>
    41f8:	a8dfe0ef          	jal	2c84 <bsp_printf>
    for (j = 0; j < 8; j++)
    41fc:	00000493          	li	s1,0
    4200:	0640006f          	j	4264 <tb1+0x98>
    SKIP_IF_DEAD("B1 COPY 32x8 src(stride 64)->FB1(40,20)");
    4204:	fff00613          	li	a2,-1
    4208:	00000593          	li	a1,0
    420c:	00008537          	lui	a0,0x8
    4210:	92850513          	addi	a0,a0,-1752 # 7928 <_data+0x9d4>
    4214:	a58ff0ef          	jal	346c <item>
    4218:	13c0006f          	j	4354 <tb1+0x188>
            wr16(PIX(SA_COPY, ATLAS_STRIDE, i, j), (uint16_t)(0x2000u + (uint32_t)j * 32u + (uint32_t)i));
    421c:	00004537          	lui	a0,0x4
    4220:	08050513          	addi	a0,a0,128 # 4080 <tf_a3+0xd0>
    4224:	00a48533          	add	a0,s1,a0
    4228:	00551513          	slli	a0,a0,0x5
    422c:	00850533          	add	a0,a0,s0
    4230:	10048593          	addi	a1,s1,256
    4234:	00559593          	slli	a1,a1,0x5
    4238:	01059593          	slli	a1,a1,0x10
    423c:	0105d593          	srli	a1,a1,0x10
    4240:	008585b3          	add	a1,a1,s0
    4244:	01059593          	slli	a1,a1,0x10
    4248:	0105d593          	srli	a1,a1,0x10
    424c:	00151513          	slli	a0,a0,0x1
    4250:	e1cfd0ef          	jal	186c <wr16>
        for (i = 0; i < 32; i++)
    4254:	00140413          	addi	s0,s0,1
    4258:	01f00793          	li	a5,31
    425c:	fc87d0e3          	bge	a5,s0,421c <tb1+0x50>
    for (j = 0; j < 8; j++)
    4260:	00148493          	addi	s1,s1,1
    4264:	00700793          	li	a5,7
    4268:	0097c663          	blt	a5,s1,4274 <tb1+0xa8>
        for (i = 0; i < 32; i++)
    426c:	00000413          	li	s0,0
    4270:	fe9ff06f          	j	4258 <tb1+0x8c>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 38, 18, 38, 12, (uint16_t)SENT);  /* x38..75, y18..29 */
    4274:	00001837          	lui	a6,0x1
    4278:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    427c:	00c00793          	li	a5,12
    4280:	02600713          	li	a4,38
    4284:	01200693          	li	a3,18
    4288:	02600613          	li	a2,38
    428c:	78000593          	li	a1,1920
    4290:	00401537          	lui	a0,0x401
    4294:	e08fd0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    4298:	ec8fd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_copy(SA_COPY, PIX(FB1_BASE, FB_STRIDE, 40, 20), ATLAS_STRIDE, FB_STRIDE,
    429c:	00800793          	li	a5,8
    42a0:	02000713          	li	a4,32
    42a4:	78000693          	li	a3,1920
    42a8:	04000613          	li	a2,64
    42ac:	0040a5b7          	lui	a1,0x40a
    42b0:	65058593          	addi	a1,a1,1616 # 40a650 <__freertos_irq_stack_top+0x3fd960>
    42b4:	00102537          	lui	a0,0x102
    42b8:	a34fe0ef          	jal	24ec <blt_copy>
    42bc:	000085b7          	lui	a1,0x8
    42c0:	99058593          	addi	a1,a1,-1648 # 7990 <_data+0xa3c>
    42c4:	e45fe0ef          	jal	3108 <op_fail>
    42c8:	08051c63          	bnez	a0,4360 <tb1+0x194>
    cache_invalidate();
    42cc:	ef4fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    42d0:	ef8fd0ef          	jal	19c8 <mis_reset>
    chk_pat(FB1_BASE, FB_STRIDE, 40, 20, 32, 8, 0x2000u, 32u);
    42d4:	02000893          	li	a7,32
    42d8:	00002837          	lui	a6,0x2
    42dc:	00800793          	li	a5,8
    42e0:	02000713          	li	a4,32
    42e4:	01400693          	li	a3,20
    42e8:	02800613          	li	a2,40
    42ec:	78000593          	li	a1,1920
    42f0:	00401537          	lui	a0,0x401
    42f4:	c3cff0ef          	jal	3730 <chk_pat>
    chk_outside(FB1_BASE, FB_STRIDE, 38, 18, 38, 12, 40, 20, 32, 8, SENT);
    42f8:	000017b7          	lui	a5,0x1
    42fc:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    4300:	00f12423          	sw	a5,8(sp)
    4304:	00800793          	li	a5,8
    4308:	00f12223          	sw	a5,4(sp)
    430c:	02000793          	li	a5,32
    4310:	00f12023          	sw	a5,0(sp)
    4314:	01400893          	li	a7,20
    4318:	02800813          	li	a6,40
    431c:	00c00793          	li	a5,12
    4320:	02600713          	li	a4,38
    4324:	01200693          	li	a3,18
    4328:	02600613          	li	a2,38
    432c:	78000593          	li	a1,1920
    4330:	00401537          	lui	a0,0x401
    4334:	ae8ff0ef          	jal	361c <chk_outside>
    item("B1 COPY 32x8 src(stride 64)->FB1(40,20)", g_perf, g_mis);
    4338:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    433c:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    4340:	00008537          	lui	a0,0x8
    4344:	92850513          	addi	a0,a0,-1752 # 7928 <_data+0x9d4>
    4348:	924ff0ef          	jal	346c <item>
    434c:	01812403          	lw	s0,24(sp)
    4350:	01412483          	lw	s1,20(sp)
}
    4354:	01c12083          	lw	ra,28(sp)
    4358:	02010113          	addi	sp,sp,32
    435c:	00008067          	ret
        item("B1 COPY 32x8 src(stride 64)->FB1(40,20)", 0u, -1);
    4360:	fff00613          	li	a2,-1
    4364:	00000593          	li	a1,0
    4368:	00008537          	lui	a0,0x8
    436c:	92850513          	addi	a0,a0,-1752 # 7928 <_data+0x9d4>
    4370:	8fcff0ef          	jal	346c <item>
        return;
    4374:	01812403          	lw	s0,24(sp)
    4378:	01412483          	lw	s1,20(sp)
    437c:	fd9ff06f          	j	4354 <tb1+0x188>

00004380 <tb2>:
{
    4380:	fe010113          	addi	sp,sp,-32
    4384:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("B2 COPY 20x8 src@+3px dst@x=13 (both unaligned)");
    4388:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    438c:	02078463          	beqz	a5,43b4 <tb2+0x34>
    4390:	00812c23          	sw	s0,24(sp)
    4394:	00912a23          	sw	s1,20(sp)
    bsp_printf("  B2: COPY 20x8 src=0x%x(行内 x=3 非对齐) -> FB1(13,60)(字节偏移 26)\r\n",
    4398:	001035b7          	lui	a1,0x103
    439c:	00658593          	addi	a1,a1,6 # 103006 <__freertos_irq_stack_top+0xf6316>
    43a0:	00008537          	lui	a0,0x8
    43a4:	9c850513          	addi	a0,a0,-1592 # 79c8 <_data+0xa74>
    43a8:	8ddfe0ef          	jal	2c84 <bsp_printf>
    for (j = 0; j < 8; j++)
    43ac:	00000493          	li	s1,0
    43b0:	0680006f          	j	4418 <tb2+0x98>
    SKIP_IF_DEAD("B2 COPY 20x8 src@+3px dst@x=13 (both unaligned)");
    43b4:	fff00613          	li	a2,-1
    43b8:	00000593          	li	a1,0
    43bc:	00008537          	lui	a0,0x8
    43c0:	99850513          	addi	a0,a0,-1640 # 7998 <_data+0xa44>
    43c4:	8a8ff0ef          	jal	346c <item>
    43c8:	1440006f          	j	450c <tb2+0x18c>
            wr16(PIX(SA_COPYB, ATLAS_STRIDE, 3 + i, j), (uint16_t)(0x3000u + (uint32_t)j * 32u + (uint32_t)i));
    43cc:	000047b7          	lui	a5,0x4
    43d0:	0c078793          	addi	a5,a5,192 # 40c0 <tf_a3+0x110>
    43d4:	00f48533          	add	a0,s1,a5
    43d8:	00551513          	slli	a0,a0,0x5
    43dc:	00850533          	add	a0,a0,s0
    43e0:	00350513          	addi	a0,a0,3
    43e4:	18048593          	addi	a1,s1,384
    43e8:	00559593          	slli	a1,a1,0x5
    43ec:	01059593          	slli	a1,a1,0x10
    43f0:	0105d593          	srli	a1,a1,0x10
    43f4:	008585b3          	add	a1,a1,s0
    43f8:	01059593          	slli	a1,a1,0x10
    43fc:	0105d593          	srli	a1,a1,0x10
    4400:	00151513          	slli	a0,a0,0x1
    4404:	c68fd0ef          	jal	186c <wr16>
        for (i = 0; i < 20; i++)
    4408:	00140413          	addi	s0,s0,1
    440c:	01300793          	li	a5,19
    4410:	fa87dee3          	bge	a5,s0,43cc <tb2+0x4c>
    for (j = 0; j < 8; j++)
    4414:	00148493          	addi	s1,s1,1
    4418:	00700793          	li	a5,7
    441c:	0097c663          	blt	a5,s1,4428 <tb2+0xa8>
        for (i = 0; i < 20; i++)
    4420:	00000413          	li	s0,0
    4424:	fe9ff06f          	j	440c <tb2+0x8c>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 10, 58, 28, 12, (uint16_t)SENT);  /* x10..37, y58..69 */
    4428:	00001837          	lui	a6,0x1
    442c:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    4430:	00c00793          	li	a5,12
    4434:	01c00713          	li	a4,28
    4438:	03a00693          	li	a3,58
    443c:	00a00613          	li	a2,10
    4440:	78000593          	li	a1,1920
    4444:	00401537          	lui	a0,0x401
    4448:	c54fd0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    444c:	d14fd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_copy(src, PIX(FB1_BASE, FB_STRIDE, 13, 60), ATLAS_STRIDE, FB_STRIDE,
    4450:	00800793          	li	a5,8
    4454:	01400713          	li	a4,20
    4458:	78000693          	li	a3,1920
    445c:	04000613          	li	a2,64
    4460:	0041d5b7          	lui	a1,0x41d
    4464:	21a58593          	addi	a1,a1,538 # 41d21a <__freertos_irq_stack_top+0x41052a>
    4468:	00103537          	lui	a0,0x103
    446c:	00650513          	addi	a0,a0,6 # 103006 <__freertos_irq_stack_top+0xf6316>
    4470:	87cfe0ef          	jal	24ec <blt_copy>
    4474:	000085b7          	lui	a1,0x8
    4478:	a1858593          	addi	a1,a1,-1512 # 7a18 <_data+0xac4>
    447c:	c8dfe0ef          	jal	3108 <op_fail>
    4480:	08051c63          	bnez	a0,4518 <tb2+0x198>
    cache_invalidate();
    4484:	d3cfd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    4488:	d40fd0ef          	jal	19c8 <mis_reset>
    chk_pat(FB1_BASE, FB_STRIDE, 13, 60, 20, 8, 0x3000u, 32u);
    448c:	02000893          	li	a7,32
    4490:	00003837          	lui	a6,0x3
    4494:	00800793          	li	a5,8
    4498:	01400713          	li	a4,20
    449c:	03c00693          	li	a3,60
    44a0:	00d00613          	li	a2,13
    44a4:	78000593          	li	a1,1920
    44a8:	00401537          	lui	a0,0x401
    44ac:	a84ff0ef          	jal	3730 <chk_pat>
    chk_outside(FB1_BASE, FB_STRIDE, 10, 58, 28, 12, 13, 60, 20, 8, SENT);
    44b0:	000017b7          	lui	a5,0x1
    44b4:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    44b8:	00f12423          	sw	a5,8(sp)
    44bc:	00800793          	li	a5,8
    44c0:	00f12223          	sw	a5,4(sp)
    44c4:	01400793          	li	a5,20
    44c8:	00f12023          	sw	a5,0(sp)
    44cc:	03c00893          	li	a7,60
    44d0:	00d00813          	li	a6,13
    44d4:	00c00793          	li	a5,12
    44d8:	01c00713          	li	a4,28
    44dc:	03a00693          	li	a3,58
    44e0:	00a00613          	li	a2,10
    44e4:	78000593          	li	a1,1920
    44e8:	00401537          	lui	a0,0x401
    44ec:	930ff0ef          	jal	361c <chk_outside>
    item("B2 COPY 20x8 src@+3px dst@x=13 (both unaligned)", g_perf, g_mis);
    44f0:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    44f4:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    44f8:	00008537          	lui	a0,0x8
    44fc:	99850513          	addi	a0,a0,-1640 # 7998 <_data+0xa44>
    4500:	f6dfe0ef          	jal	346c <item>
    4504:	01812403          	lw	s0,24(sp)
    4508:	01412483          	lw	s1,20(sp)
}
    450c:	01c12083          	lw	ra,28(sp)
    4510:	02010113          	addi	sp,sp,32
    4514:	00008067          	ret
        item("B2 COPY 20x8 src@+3px dst@x=13 (both unaligned)", 0u, -1);
    4518:	fff00613          	li	a2,-1
    451c:	00000593          	li	a1,0
    4520:	00008537          	lui	a0,0x8
    4524:	99850513          	addi	a0,a0,-1640 # 7998 <_data+0xa44>
    4528:	f45fe0ef          	jal	346c <item>
        return;
    452c:	01812403          	lw	s0,24(sp)
    4530:	01412483          	lw	s1,20(sp)
    4534:	fd9ff06f          	j	450c <tb2+0x18c>

00004538 <tb3>:
{
    4538:	fe010113          	addi	sp,sp,-32
    453c:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("B3 COPY 13x9 width%8!=0 (row tail)");
    4540:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    4544:	02078263          	beqz	a5,4568 <tb3+0x30>
    4548:	00812c23          	sw	s0,24(sp)
    454c:	00912a23          	sw	s1,20(sp)
    bsp_printf("  B3: COPY 13x9（宽 13 = 26B，行尾词只写 10B）src=0x%x -> FB1(200,100)\r\n",
    4550:	001025b7          	lui	a1,0x102
    4554:	00008537          	lui	a0,0x8
    4558:	a4450513          	addi	a0,a0,-1468 # 7a44 <_data+0xaf0>
    455c:	f28fe0ef          	jal	2c84 <bsp_printf>
    for (j = 0; j < 9; j++)
    4560:	00000493          	li	s1,0
    4564:	0640006f          	j	45c8 <tb3+0x90>
    SKIP_IF_DEAD("B3 COPY 13x9 width%8!=0 (row tail)");
    4568:	fff00613          	li	a2,-1
    456c:	00000593          	li	a1,0
    4570:	00008537          	lui	a0,0x8
    4574:	a2050513          	addi	a0,a0,-1504 # 7a20 <_data+0xacc>
    4578:	ef5fe0ef          	jal	346c <item>
    457c:	1380006f          	j	46b4 <tb3+0x17c>
            wr16(PIX(SA_COPY, ATLAS_STRIDE, i, j), (uint16_t)(0x4000u + (uint32_t)j * 16u + (uint32_t)i));
    4580:	00004537          	lui	a0,0x4
    4584:	08050513          	addi	a0,a0,128 # 4080 <tf_a3+0xd0>
    4588:	00a48533          	add	a0,s1,a0
    458c:	00551513          	slli	a0,a0,0x5
    4590:	00850533          	add	a0,a0,s0
    4594:	40048593          	addi	a1,s1,1024
    4598:	00459593          	slli	a1,a1,0x4
    459c:	01059593          	slli	a1,a1,0x10
    45a0:	0105d593          	srli	a1,a1,0x10
    45a4:	008585b3          	add	a1,a1,s0
    45a8:	01059593          	slli	a1,a1,0x10
    45ac:	0105d593          	srli	a1,a1,0x10
    45b0:	00151513          	slli	a0,a0,0x1
    45b4:	ab8fd0ef          	jal	186c <wr16>
        for (i = 0; i < 13; i++)
    45b8:	00140413          	addi	s0,s0,1
    45bc:	00c00793          	li	a5,12
    45c0:	fc87d0e3          	bge	a5,s0,4580 <tb3+0x48>
    for (j = 0; j < 9; j++)
    45c4:	00148493          	addi	s1,s1,1
    45c8:	00800793          	li	a5,8
    45cc:	0097c663          	blt	a5,s1,45d8 <tb3+0xa0>
        for (i = 0; i < 13; i++)
    45d0:	00000413          	li	s0,0
    45d4:	fe9ff06f          	j	45bc <tb3+0x84>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 198, 98, 22, 13, (uint16_t)SENT); /* x198..219, y98..110 */
    45d8:	00001837          	lui	a6,0x1
    45dc:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    45e0:	00d00793          	li	a5,13
    45e4:	01600713          	li	a4,22
    45e8:	06200693          	li	a3,98
    45ec:	0c600613          	li	a2,198
    45f0:	78000593          	li	a1,1920
    45f4:	00401537          	lui	a0,0x401
    45f8:	aa4fd0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    45fc:	b64fd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_copy(SA_COPY, PIX(FB1_BASE, FB_STRIDE, 200, 100), ATLAS_STRIDE, FB_STRIDE,
    4600:	00900793          	li	a5,9
    4604:	00d00713          	li	a4,13
    4608:	78000693          	li	a3,1920
    460c:	04000613          	li	a2,64
    4610:	004305b7          	lui	a1,0x430
    4614:	f9058593          	addi	a1,a1,-112 # 42ff90 <__freertos_irq_stack_top+0x4232a0>
    4618:	00102537          	lui	a0,0x102
    461c:	ed1fd0ef          	jal	24ec <blt_copy>
    4620:	000085b7          	lui	a1,0x8
    4624:	a9858593          	addi	a1,a1,-1384 # 7a98 <_data+0xb44>
    4628:	ae1fe0ef          	jal	3108 <op_fail>
    462c:	08051a63          	bnez	a0,46c0 <tb3+0x188>
    cache_invalidate();
    4630:	b90fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    4634:	b94fd0ef          	jal	19c8 <mis_reset>
    chk_pat(FB1_BASE, FB_STRIDE, 200, 100, 13, 9, 0x4000u, 16u);
    4638:	01000893          	li	a7,16
    463c:	00004837          	lui	a6,0x4
    4640:	00900793          	li	a5,9
    4644:	00d00713          	li	a4,13
    4648:	06400693          	li	a3,100
    464c:	0c800613          	li	a2,200
    4650:	78000593          	li	a1,1920
    4654:	00401537          	lui	a0,0x401
    4658:	8d8ff0ef          	jal	3730 <chk_pat>
    chk_outside(FB1_BASE, FB_STRIDE, 198, 98, 22, 13, 200, 100, 13, 9, SENT);
    465c:	000017b7          	lui	a5,0x1
    4660:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    4664:	00f12423          	sw	a5,8(sp)
    4668:	00900793          	li	a5,9
    466c:	00f12223          	sw	a5,4(sp)
    4670:	00d00793          	li	a5,13
    4674:	00f12023          	sw	a5,0(sp)
    4678:	06400893          	li	a7,100
    467c:	0c800813          	li	a6,200
    4680:	01600713          	li	a4,22
    4684:	06200693          	li	a3,98
    4688:	0c600613          	li	a2,198
    468c:	78000593          	li	a1,1920
    4690:	00401537          	lui	a0,0x401
    4694:	f89fe0ef          	jal	361c <chk_outside>
    item("B3 COPY 13x9 width%8!=0 (row tail)", g_perf, g_mis);
    4698:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    469c:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    46a0:	00008537          	lui	a0,0x8
    46a4:	a2050513          	addi	a0,a0,-1504 # 7a20 <_data+0xacc>
    46a8:	dc5fe0ef          	jal	346c <item>
    46ac:	01812403          	lw	s0,24(sp)
    46b0:	01412483          	lw	s1,20(sp)
}
    46b4:	01c12083          	lw	ra,28(sp)
    46b8:	02010113          	addi	sp,sp,32
    46bc:	00008067          	ret
        item("B3 COPY 13x9 width%8!=0 (row tail)", 0u, -1);
    46c0:	fff00613          	li	a2,-1
    46c4:	00000593          	li	a1,0
    46c8:	00008537          	lui	a0,0x8
    46cc:	a2050513          	addi	a0,a0,-1504 # 7a20 <_data+0xacc>
    46d0:	d9dfe0ef          	jal	346c <item>
        return;
    46d4:	01812403          	lw	s0,24(sp)
    46d8:	01412483          	lw	s1,20(sp)
    46dc:	fd9ff06f          	j	46b4 <tb3+0x17c>

000046e0 <tb5>:
{
    46e0:	fe010113          	addi	sp,sp,-32
    46e4:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("B5 COPY self-copy src==dst");
    46e8:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    46ec:	04078663          	beqz	a5,4738 <tb5+0x58>
    46f0:	00812c23          	sw	s0,24(sp)
    46f4:	00912a23          	sw	s1,20(sp)
    bsp_printf("  B5: COPY 32x8 src==dst==0x%x（自拷贝/重叠，结果须与原内容一致）\r\n", (int)dst);
    46f8:	004395b7          	lui	a1,0x439
    46fc:	72058593          	addi	a1,a1,1824 # 439720 <__freertos_irq_stack_top+0x42ca30>
    4700:	00008537          	lui	a0,0x8
    4704:	abc50513          	addi	a0,a0,-1348 # 7abc <_data+0xb68>
    4708:	d7cfe0ef          	jal	2c84 <bsp_printf>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 396, 116, 40, 16, (uint16_t)SENT);  /* 先铺哨兵... */
    470c:	00001837          	lui	a6,0x1
    4710:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    4714:	01000793          	li	a5,16
    4718:	02800713          	li	a4,40
    471c:	07400693          	li	a3,116
    4720:	18c00613          	li	a2,396
    4724:	78000593          	li	a1,1920
    4728:	00401537          	lui	a0,0x401
    472c:	970fd0ef          	jal	189c <fill_rect_cpu>
    for (j = 0; j < 8; j++)                                                /* ...再把图案盖回目标区 */
    4730:	00000493          	li	s1,0
    4734:	0700006f          	j	47a4 <tb5+0xc4>
    SKIP_IF_DEAD("B5 COPY self-copy src==dst");
    4738:	fff00613          	li	a2,-1
    473c:	00000593          	li	a1,0
    4740:	00008537          	lui	a0,0x8
    4744:	aa050513          	addi	a0,a0,-1376 # 7aa0 <_data+0xb4c>
    4748:	d25fe0ef          	jal	346c <item>
    474c:	1240006f          	j	4870 <tb5+0x190>
            wr16(PIX(FB1_BASE, FB_STRIDE, 400 + i, 120 + j),
    4750:	07848793          	addi	a5,s1,120
    4754:	00479513          	slli	a0,a5,0x4
    4758:	40f50533          	sub	a0,a0,a5
    475c:	00651513          	slli	a0,a0,0x6
    4760:	00850533          	add	a0,a0,s0
    4764:	002017b7          	lui	a5,0x201
    4768:	99078793          	addi	a5,a5,-1648 # 200990 <__freertos_irq_stack_top+0x1f3ca0>
    476c:	00f50533          	add	a0,a0,a5
                 (uint16_t)(0x5000u + (uint32_t)j * 32u + (uint32_t)i));
    4770:	28048593          	addi	a1,s1,640
    4774:	00559593          	slli	a1,a1,0x5
    4778:	01059593          	slli	a1,a1,0x10
    477c:	0105d593          	srli	a1,a1,0x10
            wr16(PIX(FB1_BASE, FB_STRIDE, 400 + i, 120 + j),
    4780:	008585b3          	add	a1,a1,s0
    4784:	01059593          	slli	a1,a1,0x10
    4788:	0105d593          	srli	a1,a1,0x10
    478c:	00151513          	slli	a0,a0,0x1
    4790:	8dcfd0ef          	jal	186c <wr16>
        for (i = 0; i < 32; i++)
    4794:	00140413          	addi	s0,s0,1
    4798:	01f00793          	li	a5,31
    479c:	fa87dae3          	bge	a5,s0,4750 <tb5+0x70>
    for (j = 0; j < 8; j++)                                                /* ...再把图案盖回目标区 */
    47a0:	00148493          	addi	s1,s1,1
    47a4:	00700793          	li	a5,7
    47a8:	0097c663          	blt	a5,s1,47b4 <tb5+0xd4>
        for (i = 0; i < 32; i++)
    47ac:	00000413          	li	s0,0
    47b0:	fe9ff06f          	j	4798 <tb5+0xb8>
    cache_evict();
    47b4:	9acfd0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_copy(dst, dst, FB_STRIDE, FB_STRIDE, 32u, 8u), "B5 COPY self")) {
    47b8:	00800793          	li	a5,8
    47bc:	02000713          	li	a4,32
    47c0:	78000693          	li	a3,1920
    47c4:	78000613          	li	a2,1920
    47c8:	004395b7          	lui	a1,0x439
    47cc:	72058593          	addi	a1,a1,1824 # 439720 <__freertos_irq_stack_top+0x42ca30>
    47d0:	00058513          	mv	a0,a1
    47d4:	d19fd0ef          	jal	24ec <blt_copy>
    47d8:	000085b7          	lui	a1,0x8
    47dc:	b1458593          	addi	a1,a1,-1260 # 7b14 <_data+0xbc0>
    47e0:	929fe0ef          	jal	3108 <op_fail>
    47e4:	08051c63          	bnez	a0,487c <tb5+0x19c>
    cache_invalidate();
    47e8:	9d8fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    47ec:	9dcfd0ef          	jal	19c8 <mis_reset>
    chk_pat(FB1_BASE, FB_STRIDE, 400, 120, 32, 8, 0x5000u, 32u);
    47f0:	02000893          	li	a7,32
    47f4:	00005837          	lui	a6,0x5
    47f8:	00800793          	li	a5,8
    47fc:	02000713          	li	a4,32
    4800:	07800693          	li	a3,120
    4804:	19000613          	li	a2,400
    4808:	78000593          	li	a1,1920
    480c:	00401537          	lui	a0,0x401
    4810:	f21fe0ef          	jal	3730 <chk_pat>
    chk_outside(FB1_BASE, FB_STRIDE, 396, 116, 40, 16, 400, 120, 32, 8, SENT);
    4814:	000017b7          	lui	a5,0x1
    4818:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    481c:	00f12423          	sw	a5,8(sp)
    4820:	00800793          	li	a5,8
    4824:	00f12223          	sw	a5,4(sp)
    4828:	02000793          	li	a5,32
    482c:	00f12023          	sw	a5,0(sp)
    4830:	07800893          	li	a7,120
    4834:	19000813          	li	a6,400
    4838:	01000793          	li	a5,16
    483c:	02800713          	li	a4,40
    4840:	07400693          	li	a3,116
    4844:	18c00613          	li	a2,396
    4848:	78000593          	li	a1,1920
    484c:	00401537          	lui	a0,0x401
    4850:	dcdfe0ef          	jal	361c <chk_outside>
    item("B5 COPY self-copy src==dst", g_perf, g_mis);
    4854:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    4858:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    485c:	00008537          	lui	a0,0x8
    4860:	aa050513          	addi	a0,a0,-1376 # 7aa0 <_data+0xb4c>
    4864:	c09fe0ef          	jal	346c <item>
    4868:	01812403          	lw	s0,24(sp)
    486c:	01412483          	lw	s1,20(sp)
}
    4870:	01c12083          	lw	ra,28(sp)
    4874:	02010113          	addi	sp,sp,32
    4878:	00008067          	ret
        item("B5 COPY self-copy src==dst", 0u, -1);
    487c:	fff00613          	li	a2,-1
    4880:	00000593          	li	a1,0
    4884:	00008537          	lui	a0,0x8
    4888:	aa050513          	addi	a0,a0,-1376 # 7aa0 <_data+0xb4c>
    488c:	be1fe0ef          	jal	346c <item>
        return;
    4890:	01812403          	lw	s0,24(sp)
    4894:	01412483          	lw	s1,20(sp)
    4898:	fd9ff06f          	j	4870 <tb5+0x190>

0000489c <tb4>:
{
    489c:	fe010113          	addi	sp,sp,-32
    48a0:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("B4 COPY fullscreen 960x540 (FB1->FB->FB1)");
    48a4:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    48a8:	42078863          	beqz	a5,4cd8 <tb4+0x43c>
    bsp_printf("  B4: 整屏 COPY %dx%d —— FB1 三段色带 -> FB -> FB1\r\n", FB_WIDTH, FB_HEIGHT);
    48ac:	21c00613          	li	a2,540
    48b0:	3c000593          	li	a1,960
    48b4:	00008537          	lui	a0,0x8
    48b8:	b5050513          	addi	a0,a0,-1200 # 7b50 <_data+0xbfc>
    48bc:	bc8fe0ef          	jal	2c84 <bsp_printf>
    if (op_fail(blt_fill(FB1_BASE, FB_STRIDE, FB_WIDTH, 180u, 0x07E0u), "B4 band0")) {
    48c0:	7e000713          	li	a4,2016
    48c4:	0b400693          	li	a3,180
    48c8:	3c000613          	li	a2,960
    48cc:	78000593          	li	a1,1920
    48d0:	00401537          	lui	a0,0x401
    48d4:	bddfd0ef          	jal	24b0 <blt_fill>
    48d8:	000085b7          	lui	a1,0x8
    48dc:	b9058593          	addi	a1,a1,-1136 # 7b90 <_data+0xc3c>
    48e0:	829fe0ef          	jal	3108 <op_fail>
    48e4:	40051a63          	bnez	a0,4cf8 <tb4+0x45c>
    48e8:	00812c23          	sw	s0,24(sp)
    p1 = g_perf;
    48ec:	8701a403          	lw	s0,-1936(gp) # 9730 <g_perf>
    if (op_fail(blt_fill(FB1_BASE + 180UL * FB_STRIDE, FB_STRIDE, FB_WIDTH, 180u, 0x001Fu), "B4 band1")) {
    48f0:	01f00713          	li	a4,31
    48f4:	0b400693          	li	a3,180
    48f8:	3c000613          	li	a2,960
    48fc:	78000593          	li	a1,1920
    4900:	00455537          	lui	a0,0x455
    4904:	60050513          	addi	a0,a0,1536 # 455600 <__freertos_irq_stack_top+0x448910>
    4908:	ba9fd0ef          	jal	24b0 <blt_fill>
    490c:	000085b7          	lui	a1,0x8
    4910:	b9c58593          	addi	a1,a1,-1124 # 7b9c <_data+0xc48>
    4914:	ff4fe0ef          	jal	3108 <op_fail>
    4918:	3e051c63          	bnez	a0,4d10 <tb4+0x474>
    491c:	00912a23          	sw	s1,20(sp)
    p2 = g_perf;
    4920:	8701a483          	lw	s1,-1936(gp) # 9730 <g_perf>
    if (op_fail(blt_fill(FB1_BASE + 360UL * FB_STRIDE, FB_STRIDE, FB_WIDTH, 180u, 0xFD20u), "B4 band2")) {
    4924:	00010737          	lui	a4,0x10
    4928:	d2070713          	addi	a4,a4,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    492c:	0b400693          	li	a3,180
    4930:	3c000613          	li	a2,960
    4934:	78000593          	li	a1,1920
    4938:	004aa537          	lui	a0,0x4aa
    493c:	c0050513          	addi	a0,a0,-1024 # 4a9c00 <__freertos_irq_stack_top+0x49cf10>
    4940:	b71fd0ef          	jal	24b0 <blt_fill>
    4944:	000085b7          	lui	a1,0x8
    4948:	ba858593          	addi	a1,a1,-1112 # 7ba8 <_data+0xc54>
    494c:	fbcfe0ef          	jal	3108 <op_fail>
    4950:	3c051e63          	bnez	a0,4d2c <tb4+0x490>
    4954:	01212823          	sw	s2,16(sp)
    p3 = g_perf;
    4958:	8701a903          	lw	s2,-1936(gp) # 9730 <g_perf>
    cache_invalidate();
    495c:	864fd0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    4960:	868fd0ef          	jal	19c8 <mis_reset>
    expect_px(0, 0, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 0)), 0x07E0u);
    4964:	00401537          	lui	a0,0x401
    4968:	f0dfc0ef          	jal	1874 <rd16>
    496c:	00050613          	mv	a2,a0
    4970:	7e000693          	li	a3,2016
    4974:	00000593          	li	a1,0
    4978:	00000513          	li	a0,0
    497c:	b71fe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 179, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 179)), 0x07E0u);
    4980:	00455537          	lui	a0,0x455
    4984:	5fe50513          	addi	a0,a0,1534 # 4555fe <__freertos_irq_stack_top+0x44890e>
    4988:	eedfc0ef          	jal	1874 <rd16>
    498c:	00050613          	mv	a2,a0
    4990:	7e000693          	li	a3,2016
    4994:	0b300593          	li	a1,179
    4998:	3bf00513          	li	a0,959
    499c:	b51fe0ef          	jal	34ec <expect_px>
    expect_px(0, 180, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 180)), 0x001Fu);
    49a0:	00455537          	lui	a0,0x455
    49a4:	60050513          	addi	a0,a0,1536 # 455600 <__freertos_irq_stack_top+0x448910>
    49a8:	ecdfc0ef          	jal	1874 <rd16>
    49ac:	00050613          	mv	a2,a0
    49b0:	01f00693          	li	a3,31
    49b4:	0b400593          	li	a1,180
    49b8:	00000513          	li	a0,0
    49bc:	b31fe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 359, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 359)), 0x001Fu);
    49c0:	004aa537          	lui	a0,0x4aa
    49c4:	bfe50513          	addi	a0,a0,-1026 # 4a9bfe <__freertos_irq_stack_top+0x49cf0e>
    49c8:	eadfc0ef          	jal	1874 <rd16>
    49cc:	00050613          	mv	a2,a0
    49d0:	01f00693          	li	a3,31
    49d4:	16700593          	li	a1,359
    49d8:	3bf00513          	li	a0,959
    49dc:	b11fe0ef          	jal	34ec <expect_px>
    expect_px(0, 360, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 360)), 0xFD20u);
    49e0:	004aa537          	lui	a0,0x4aa
    49e4:	c0050513          	addi	a0,a0,-1024 # 4a9c00 <__freertos_irq_stack_top+0x49cf10>
    49e8:	e8dfc0ef          	jal	1874 <rd16>
    49ec:	00050613          	mv	a2,a0
    49f0:	000106b7          	lui	a3,0x10
    49f4:	d2068693          	addi	a3,a3,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    49f8:	16800593          	li	a1,360
    49fc:	00000513          	li	a0,0
    4a00:	aedfe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 539, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 539)), 0xFD20u);
    4a04:	004fe537          	lui	a0,0x4fe
    4a08:	1fe50513          	addi	a0,a0,510 # 4fe1fe <__freertos_irq_stack_top+0x4f150e>
    4a0c:	e69fc0ef          	jal	1874 <rd16>
    4a10:	00050613          	mv	a2,a0
    4a14:	000106b7          	lui	a3,0x10
    4a18:	d2068693          	addi	a3,a3,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    4a1c:	21b00593          	li	a1,539
    4a20:	3bf00513          	li	a0,959
    4a24:	ac9fe0ef          	jal	34ec <expect_px>
    if (op_fail(blt_copy(FB1_BASE, FB_BASE, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT), "B4 fwd")) {
    4a28:	21c00793          	li	a5,540
    4a2c:	3c000713          	li	a4,960
    4a30:	78000693          	li	a3,1920
    4a34:	78000613          	li	a2,1920
    4a38:	003015b7          	lui	a1,0x301
    4a3c:	00401537          	lui	a0,0x401
    4a40:	aadfd0ef          	jal	24ec <blt_copy>
    4a44:	000085b7          	lui	a1,0x8
    4a48:	bb458593          	addi	a1,a1,-1100 # 7bb4 <_data+0xc60>
    4a4c:	ebcfe0ef          	jal	3108 <op_fail>
    4a50:	2e051e63          	bnez	a0,4d4c <tb4+0x4b0>
    4a54:	01312623          	sw	s3,12(sp)
    p4 = g_perf;
    4a58:	8701a983          	lw	s3,-1936(gp) # 9730 <g_perf>
    cache_invalidate();
    4a5c:	f65fc0ef          	jal	19c0 <cache_invalidate>
    expect_px(0, 0, rd16(PIX(FB_BASE, FB_STRIDE, 0, 0)), 0x07E0u);
    4a60:	00301537          	lui	a0,0x301
    4a64:	e11fc0ef          	jal	1874 <rd16>
    4a68:	00050613          	mv	a2,a0
    4a6c:	7e000693          	li	a3,2016
    4a70:	00000593          	li	a1,0
    4a74:	00000513          	li	a0,0
    4a78:	a75fe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 0, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 0)), 0x07E0u);
    4a7c:	00301537          	lui	a0,0x301
    4a80:	77e50513          	addi	a0,a0,1918 # 30177e <__freertos_irq_stack_top+0x2f4a8e>
    4a84:	df1fc0ef          	jal	1874 <rd16>
    4a88:	00050613          	mv	a2,a0
    4a8c:	7e000693          	li	a3,2016
    4a90:	00000593          	li	a1,0
    4a94:	3bf00513          	li	a0,959
    4a98:	a55fe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 179, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 179)), 0x07E0u);
    4a9c:	00355537          	lui	a0,0x355
    4aa0:	5fe50513          	addi	a0,a0,1534 # 3555fe <__freertos_irq_stack_top+0x34890e>
    4aa4:	dd1fc0ef          	jal	1874 <rd16>
    4aa8:	00050613          	mv	a2,a0
    4aac:	7e000693          	li	a3,2016
    4ab0:	0b300593          	li	a1,179
    4ab4:	3bf00513          	li	a0,959
    4ab8:	a35fe0ef          	jal	34ec <expect_px>
    expect_px(0, 180, rd16(PIX(FB_BASE, FB_STRIDE, 0, 180)), 0x001Fu);
    4abc:	00355537          	lui	a0,0x355
    4ac0:	60050513          	addi	a0,a0,1536 # 355600 <__freertos_irq_stack_top+0x348910>
    4ac4:	db1fc0ef          	jal	1874 <rd16>
    4ac8:	00050613          	mv	a2,a0
    4acc:	01f00693          	li	a3,31
    4ad0:	0b400593          	li	a1,180
    4ad4:	00000513          	li	a0,0
    4ad8:	a15fe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 359, rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, 359)), 0x001Fu);
    4adc:	003aa537          	lui	a0,0x3aa
    4ae0:	bfe50513          	addi	a0,a0,-1026 # 3a9bfe <__freertos_irq_stack_top+0x39cf0e>
    4ae4:	d91fc0ef          	jal	1874 <rd16>
    4ae8:	00050613          	mv	a2,a0
    4aec:	01f00693          	li	a3,31
    4af0:	16700593          	li	a1,359
    4af4:	3bf00513          	li	a0,959
    4af8:	9f5fe0ef          	jal	34ec <expect_px>
    expect_px(0, 360, rd16(PIX(FB_BASE, FB_STRIDE, 0, 360)), 0xFD20u);
    4afc:	003aa537          	lui	a0,0x3aa
    4b00:	c0050513          	addi	a0,a0,-1024 # 3a9c00 <__freertos_irq_stack_top+0x39cf10>
    4b04:	d71fc0ef          	jal	1874 <rd16>
    4b08:	00050613          	mv	a2,a0
    4b0c:	000106b7          	lui	a3,0x10
    4b10:	d2068693          	addi	a3,a3,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    4b14:	16800593          	li	a1,360
    4b18:	00000513          	li	a0,0
    4b1c:	9d1fe0ef          	jal	34ec <expect_px>
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH - 1, FB_HEIGHT - 1)), 0xFD20u);
    4b20:	003fe537          	lui	a0,0x3fe
    4b24:	1fe50513          	addi	a0,a0,510 # 3fe1fe <__freertos_irq_stack_top+0x3f150e>
    4b28:	d4dfc0ef          	jal	1874 <rd16>
    4b2c:	00050613          	mv	a2,a0
    expect_px(FB_WIDTH - 1, FB_HEIGHT - 1,
    4b30:	000106b7          	lui	a3,0x10
    4b34:	d2068693          	addi	a3,a3,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    4b38:	21b00593          	li	a1,539
    4b3c:	3bf00513          	li	a0,959
    4b40:	9adfe0ef          	jal	34ec <expect_px>
              rd16(PIX(FB_BASE, FB_STRIDE, FB_WIDTH / 2, FB_HEIGHT / 2)), 0x001Fu);
    4b44:	00380537          	lui	a0,0x380
    4b48:	cc050513          	addi	a0,a0,-832 # 37fcc0 <__freertos_irq_stack_top+0x372fd0>
    4b4c:	d29fc0ef          	jal	1874 <rd16>
    4b50:	00050613          	mv	a2,a0
    expect_px(FB_WIDTH / 2, FB_HEIGHT / 2,
    4b54:	01f00693          	li	a3,31
    4b58:	10e00593          	li	a1,270
    4b5c:	1e000513          	li	a0,480
    4b60:	98dfe0ef          	jal	34ec <expect_px>
    if (op_fail(blt_copy(FB_BASE, FB1_BASE, FB_STRIDE, FB_STRIDE, FB_WIDTH, FB_HEIGHT), "B4 back")) {
    4b64:	21c00793          	li	a5,540
    4b68:	3c000713          	li	a4,960
    4b6c:	78000693          	li	a3,1920
    4b70:	78000613          	li	a2,1920
    4b74:	004015b7          	lui	a1,0x401
    4b78:	00301537          	lui	a0,0x301
    4b7c:	971fd0ef          	jal	24ec <blt_copy>
    4b80:	000085b7          	lui	a1,0x8
    4b84:	bbc58593          	addi	a1,a1,-1092 # 7bbc <_data+0xc68>
    4b88:	d80fe0ef          	jal	3108 <op_fail>
    4b8c:	1e051463          	bnez	a0,4d74 <tb4+0x4d8>
    4b90:	01412423          	sw	s4,8(sp)
    p5 = g_perf;
    4b94:	8701aa03          	lw	s4,-1936(gp) # 9730 <g_perf>
    cache_invalidate();
    4b98:	e29fc0ef          	jal	19c0 <cache_invalidate>
    expect_px(0, 0, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 0)), 0x07E0u);
    4b9c:	00401537          	lui	a0,0x401
    4ba0:	cd5fc0ef          	jal	1874 <rd16>
    4ba4:	00050613          	mv	a2,a0
    4ba8:	7e000693          	li	a3,2016
    4bac:	00000593          	li	a1,0
    4bb0:	00000513          	li	a0,0
    4bb4:	939fe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 0, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 0)), 0x07E0u);
    4bb8:	00401537          	lui	a0,0x401
    4bbc:	77e50513          	addi	a0,a0,1918 # 40177e <__freertos_irq_stack_top+0x3f4a8e>
    4bc0:	cb5fc0ef          	jal	1874 <rd16>
    4bc4:	00050613          	mv	a2,a0
    4bc8:	7e000693          	li	a3,2016
    4bcc:	00000593          	li	a1,0
    4bd0:	3bf00513          	li	a0,959
    4bd4:	919fe0ef          	jal	34ec <expect_px>
    expect_px(0, 180, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 180)), 0x001Fu);
    4bd8:	00455537          	lui	a0,0x455
    4bdc:	60050513          	addi	a0,a0,1536 # 455600 <__freertos_irq_stack_top+0x448910>
    4be0:	c95fc0ef          	jal	1874 <rd16>
    4be4:	00050613          	mv	a2,a0
    4be8:	01f00693          	li	a3,31
    4bec:	0b400593          	li	a1,180
    4bf0:	00000513          	li	a0,0
    4bf4:	8f9fe0ef          	jal	34ec <expect_px>
    expect_px(FB_WIDTH - 1, 359, rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, 359)), 0x001Fu);
    4bf8:	004aa537          	lui	a0,0x4aa
    4bfc:	bfe50513          	addi	a0,a0,-1026 # 4a9bfe <__freertos_irq_stack_top+0x49cf0e>
    4c00:	c75fc0ef          	jal	1874 <rd16>
    4c04:	00050613          	mv	a2,a0
    4c08:	01f00693          	li	a3,31
    4c0c:	16700593          	li	a1,359
    4c10:	3bf00513          	li	a0,959
    4c14:	8d9fe0ef          	jal	34ec <expect_px>
    expect_px(0, 360, rd16(PIX(FB1_BASE, FB_STRIDE, 0, 360)), 0xFD20u);
    4c18:	004aa537          	lui	a0,0x4aa
    4c1c:	c0050513          	addi	a0,a0,-1024 # 4a9c00 <__freertos_irq_stack_top+0x49cf10>
    4c20:	c55fc0ef          	jal	1874 <rd16>
    4c24:	00050613          	mv	a2,a0
    4c28:	000106b7          	lui	a3,0x10
    4c2c:	d2068693          	addi	a3,a3,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    4c30:	16800593          	li	a1,360
    4c34:	00000513          	li	a0,0
    4c38:	8b5fe0ef          	jal	34ec <expect_px>
              rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH - 1, FB_HEIGHT - 1)), 0xFD20u);
    4c3c:	004fe537          	lui	a0,0x4fe
    4c40:	1fe50513          	addi	a0,a0,510 # 4fe1fe <__freertos_irq_stack_top+0x4f150e>
    4c44:	c31fc0ef          	jal	1874 <rd16>
    4c48:	00050613          	mv	a2,a0
    expect_px(FB_WIDTH - 1, FB_HEIGHT - 1,
    4c4c:	000106b7          	lui	a3,0x10
    4c50:	d2068693          	addi	a3,a3,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    4c54:	21b00593          	li	a1,539
    4c58:	3bf00513          	li	a0,959
    4c5c:	891fe0ef          	jal	34ec <expect_px>
              rd16(PIX(FB1_BASE, FB_STRIDE, FB_WIDTH / 2, FB_HEIGHT / 2)), 0x001Fu);
    4c60:	00480537          	lui	a0,0x480
    4c64:	cc050513          	addi	a0,a0,-832 # 47fcc0 <__freertos_irq_stack_top+0x472fd0>
    4c68:	c0dfc0ef          	jal	1874 <rd16>
    4c6c:	00050613          	mv	a2,a0
    expect_px(FB_WIDTH / 2, FB_HEIGHT / 2,
    4c70:	01f00693          	li	a3,31
    4c74:	10e00593          	li	a1,270
    4c78:	1e000513          	li	a0,480
    4c7c:	871fe0ef          	jal	34ec <expect_px>
    bsp_printf("      PERF 带0/带1/带2/前向整屏/回向整屏 = %d/%d/%d/%d/%d cycles\r\n",
    4c80:	000a0793          	mv	a5,s4
    4c84:	00098713          	mv	a4,s3
    4c88:	00090693          	mv	a3,s2
    4c8c:	00048613          	mv	a2,s1
    4c90:	00040593          	mv	a1,s0
    4c94:	00008537          	lui	a0,0x8
    4c98:	bc450513          	addi	a0,a0,-1084 # 7bc4 <_data+0xc70>
    4c9c:	fe9fd0ef          	jal	2c84 <bsp_printf>
    item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2 + p3 + p4 + p5, g_mis);
    4ca0:	009405b3          	add	a1,s0,s1
    4ca4:	012585b3          	add	a1,a1,s2
    4ca8:	013585b3          	add	a1,a1,s3
    4cac:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    4cb0:	014585b3          	add	a1,a1,s4
    4cb4:	00008537          	lui	a0,0x8
    4cb8:	b2450513          	addi	a0,a0,-1244 # 7b24 <_data+0xbd0>
    4cbc:	fb0fe0ef          	jal	346c <item>
    4cc0:	01812403          	lw	s0,24(sp)
    4cc4:	01412483          	lw	s1,20(sp)
    4cc8:	01012903          	lw	s2,16(sp)
    4ccc:	00c12983          	lw	s3,12(sp)
    4cd0:	00812a03          	lw	s4,8(sp)
    4cd4:	0180006f          	j	4cec <tb4+0x450>
    SKIP_IF_DEAD("B4 COPY fullscreen 960x540 (FB1->FB->FB1)");
    4cd8:	fff00613          	li	a2,-1
    4cdc:	00000593          	li	a1,0
    4ce0:	00008537          	lui	a0,0x8
    4ce4:	b2450513          	addi	a0,a0,-1244 # 7b24 <_data+0xbd0>
    4ce8:	f84fe0ef          	jal	346c <item>
}
    4cec:	01c12083          	lw	ra,28(sp)
    4cf0:	02010113          	addi	sp,sp,32
    4cf4:	00008067          	ret
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", 0u, -1);
    4cf8:	fff00613          	li	a2,-1
    4cfc:	00000593          	li	a1,0
    4d00:	00008537          	lui	a0,0x8
    4d04:	b2450513          	addi	a0,a0,-1244 # 7b24 <_data+0xbd0>
    4d08:	f64fe0ef          	jal	346c <item>
        return;
    4d0c:	fe1ff06f          	j	4cec <tb4+0x450>
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1, -1);
    4d10:	fff00613          	li	a2,-1
    4d14:	00040593          	mv	a1,s0
    4d18:	00008537          	lui	a0,0x8
    4d1c:	b2450513          	addi	a0,a0,-1244 # 7b24 <_data+0xbd0>
    4d20:	f4cfe0ef          	jal	346c <item>
        return;
    4d24:	01812403          	lw	s0,24(sp)
    4d28:	fc5ff06f          	j	4cec <tb4+0x450>
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2, -1);
    4d2c:	fff00613          	li	a2,-1
    4d30:	009405b3          	add	a1,s0,s1
    4d34:	00008537          	lui	a0,0x8
    4d38:	b2450513          	addi	a0,a0,-1244 # 7b24 <_data+0xbd0>
    4d3c:	f30fe0ef          	jal	346c <item>
        return;
    4d40:	01812403          	lw	s0,24(sp)
    4d44:	01412483          	lw	s1,20(sp)
    4d48:	fa5ff06f          	j	4cec <tb4+0x450>
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2 + p3, -1);
    4d4c:	009405b3          	add	a1,s0,s1
    4d50:	fff00613          	li	a2,-1
    4d54:	012585b3          	add	a1,a1,s2
    4d58:	00008537          	lui	a0,0x8
    4d5c:	b2450513          	addi	a0,a0,-1244 # 7b24 <_data+0xbd0>
    4d60:	f0cfe0ef          	jal	346c <item>
        return;
    4d64:	01812403          	lw	s0,24(sp)
    4d68:	01412483          	lw	s1,20(sp)
    4d6c:	01012903          	lw	s2,16(sp)
    4d70:	f7dff06f          	j	4cec <tb4+0x450>
        item("B4 COPY fullscreen 960x540 (FB1->FB->FB1)", p1 + p2 + p3 + p4, -1);
    4d74:	009405b3          	add	a1,s0,s1
    4d78:	012585b3          	add	a1,a1,s2
    4d7c:	fff00613          	li	a2,-1
    4d80:	013585b3          	add	a1,a1,s3
    4d84:	00008537          	lui	a0,0x8
    4d88:	b2450513          	addi	a0,a0,-1244 # 7b24 <_data+0xbd0>
    4d8c:	ee0fe0ef          	jal	346c <item>
        return;
    4d90:	01812403          	lw	s0,24(sp)
    4d94:	01412483          	lw	s1,20(sp)
    4d98:	01012903          	lw	s2,16(sp)
    4d9c:	00c12983          	lw	s3,12(sp)
    4da0:	f4dff06f          	j	4cec <tb4+0x450>

00004da4 <tc1>:
{
    4da4:	fd010113          	addi	sp,sp,-48
    4da8:	02112623          	sw	ra,44(sp)
    SKIP_IF_DEAD("C1 KEY 16x8 alternating key px");
    4dac:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    4db0:	02078c63          	beqz	a5,4de8 <tc1+0x44>
    4db4:	02812423          	sw	s0,40(sp)
    4db8:	02912223          	sw	s1,36(sp)
    4dbc:	01512a23          	sw	s5,20(sp)
    bsp_printf("  C1: KEY 16x8 key=0x%x src=0x%x(隔像素键色) -> FB1(40,140)(预填 0x%x)\r\n",
    4dc0:	000016b7          	lui	a3,0x1
    4dc4:	11168693          	addi	a3,a3,273 # 1111 <main+0xd>
    4dc8:	00104637          	lui	a2,0x104
    4dcc:	000105b7          	lui	a1,0x10
    4dd0:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    4dd4:	00008537          	lui	a0,0x8
    4dd8:	c3450513          	addi	a0,a0,-972 # 7c34 <_data+0xce0>
    4ddc:	ea9fd0ef          	jal	2c84 <bsp_printf>
    for (j = 0; j < 8; j++)
    4de0:	00000493          	li	s1,0
    4de4:	0600006f          	j	4e44 <tc1+0xa0>
    SKIP_IF_DEAD("C1 KEY 16x8 alternating key px");
    4de8:	fff00613          	li	a2,-1
    4dec:	00000593          	li	a1,0
    4df0:	00008537          	lui	a0,0x8
    4df4:	c1450513          	addi	a0,a0,-1004 # 7c14 <_data+0xcc0>
    4df8:	e74fe0ef          	jal	346c <item>
    4dfc:	2480006f          	j	5044 <tc1+0x2a0>
            wr16(PIX(SA_KEY, 32u, i, j), (i & 1) ? (uint16_t)C_CYAN : (uint16_t)KEY_COLOR);
    4e00:	000105b7          	lui	a1,0x10
    4e04:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    4e08:	a65fc0ef          	jal	186c <wr16>
        for (i = 0; i < 16; i++)
    4e0c:	00140413          	addi	s0,s0,1
    4e10:	00f00793          	li	a5,15
    4e14:	0287c663          	blt	a5,s0,4e40 <tc1+0x9c>
            wr16(PIX(SA_KEY, 32u, i, j), (i & 1) ? (uint16_t)C_CYAN : (uint16_t)KEY_COLOR);
    4e18:	000087b7          	lui	a5,0x8
    4e1c:	20078793          	addi	a5,a5,512 # 8200 <_data+0x12ac>
    4e20:	00f48533          	add	a0,s1,a5
    4e24:	00451513          	slli	a0,a0,0x4
    4e28:	00850533          	add	a0,a0,s0
    4e2c:	00151513          	slli	a0,a0,0x1
    4e30:	00147793          	andi	a5,s0,1
    4e34:	fc0786e3          	beqz	a5,4e00 <tc1+0x5c>
    4e38:	7ff00593          	li	a1,2047
    4e3c:	fcdff06f          	j	4e08 <tc1+0x64>
    for (j = 0; j < 8; j++)
    4e40:	00148493          	addi	s1,s1,1
    4e44:	00700793          	li	a5,7
    4e48:	0097c663          	blt	a5,s1,4e54 <tc1+0xb0>
        for (i = 0; i < 16; i++)
    4e4c:	00000413          	li	s0,0
    4e50:	fc1ff06f          	j	4e10 <tc1+0x6c>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 38, 138, 20, 12, (uint16_t)SENT);  /* x38..57, y138..149 */
    4e54:	00001837          	lui	a6,0x1
    4e58:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    4e5c:	00c00793          	li	a5,12
    4e60:	01400713          	li	a4,20
    4e64:	08a00693          	li	a3,138
    4e68:	02600613          	li	a2,38
    4e6c:	78000593          	li	a1,1920
    4e70:	00401537          	lui	a0,0x401
    4e74:	a29fc0ef          	jal	189c <fill_rect_cpu>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 40, 140, 16, 8, 0x1111u);          /* 目的预填 */
    4e78:	00001837          	lui	a6,0x1
    4e7c:	11180813          	addi	a6,a6,273 # 1111 <main+0xd>
    4e80:	00800793          	li	a5,8
    4e84:	01000713          	li	a4,16
    4e88:	08c00693          	li	a3,140
    4e8c:	02800613          	li	a2,40
    4e90:	78000593          	li	a1,1920
    4e94:	00401537          	lui	a0,0x401
    4e98:	a05fc0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    4e9c:	ac5fc0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_key(SA_KEY, PIX(FB1_BASE, FB_STRIDE, 40, 140), 32u, FB_STRIDE,
    4ea0:	00010837          	lui	a6,0x10
    4ea4:	81f80813          	addi	a6,a6,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    4ea8:	00800793          	li	a5,8
    4eac:	01000713          	li	a4,16
    4eb0:	78000693          	li	a3,1920
    4eb4:	02000613          	li	a2,32
    4eb8:	004435b7          	lui	a1,0x443
    4ebc:	a5058593          	addi	a1,a1,-1456 # 442a50 <__freertos_irq_stack_top+0x435d60>
    4ec0:	00104537          	lui	a0,0x104
    4ec4:	e64fd0ef          	jal	2528 <blt_key>
    4ec8:	000085b7          	lui	a1,0x8
    4ecc:	c8458593          	addi	a1,a1,-892 # 7c84 <_data+0xd30>
    4ed0:	a38fe0ef          	jal	3108 <op_fail>
    4ed4:	00050a93          	mv	s5,a0
    4ed8:	02051463          	bnez	a0,4f00 <tc1+0x15c>
    4edc:	03212023          	sw	s2,32(sp)
    4ee0:	01312e23          	sw	s3,28(sp)
    4ee4:	01412c23          	sw	s4,24(sp)
    cache_invalidate();
    4ee8:	ad9fc0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    4eec:	addfc0ef          	jal	19c8 <mis_reset>
    int i, j, keep_ok = 0, write_ok = 0;
    4ef0:	000a8a13          	mv	s4,s5
    4ef4:	000a8993          	mv	s3,s5
    for (j = 0; j < 8; j++) {
    4ef8:	000a8913          	mv	s2,s5
    4efc:	0b80006f          	j	4fb4 <tc1+0x210>
        item("C1 KEY 16x8 alternating key px", 0u, -1);
    4f00:	fff00613          	li	a2,-1
    4f04:	00000593          	li	a1,0
    4f08:	00008537          	lui	a0,0x8
    4f0c:	c1450513          	addi	a0,a0,-1004 # 7c14 <_data+0xcc0>
    4f10:	d5cfe0ef          	jal	346c <item>
        return;
    4f14:	02812403          	lw	s0,40(sp)
    4f18:	02412483          	lw	s1,36(sp)
    4f1c:	01412a83          	lw	s5,20(sp)
    4f20:	1240006f          	j	5044 <tc1+0x2a0>
                expect_px(40 + i, 140 + j, got, C_CYAN);
    4f24:	7ff00693          	li	a3,2047
    4f28:	00048593          	mv	a1,s1
    4f2c:	02840513          	addi	a0,s0,40
    4f30:	dbcfe0ef          	jal	34ec <expect_px>
        for (i = 0; i < 16; i++) {
    4f34:	00140413          	addi	s0,s0,1
    4f38:	00f00793          	li	a5,15
    4f3c:	0687ca63          	blt	a5,s0,4fb0 <tc1+0x20c>
            uint32_t got = rd16(PIX(FB1_BASE, FB_STRIDE, 40 + i, 140 + j));
    4f40:	08c90493          	addi	s1,s2,140
    4f44:	00449513          	slli	a0,s1,0x4
    4f48:	40950533          	sub	a0,a0,s1
    4f4c:	00651513          	slli	a0,a0,0x6
    4f50:	00850533          	add	a0,a0,s0
    4f54:	002017b7          	lui	a5,0x201
    4f58:	82878793          	addi	a5,a5,-2008 # 200828 <__freertos_irq_stack_top+0x1f3b38>
    4f5c:	00f50533          	add	a0,a0,a5
    4f60:	00151513          	slli	a0,a0,0x1
    4f64:	911fc0ef          	jal	1874 <rd16>
    4f68:	00050613          	mv	a2,a0
            if (i & 1) {
    4f6c:	00147793          	andi	a5,s0,1
    4f70:	00078a63          	beqz	a5,4f84 <tc1+0x1e0>
                if (got == C_CYAN) write_ok++;
    4f74:	7ff00793          	li	a5,2047
    4f78:	faf516e3          	bne	a0,a5,4f24 <tc1+0x180>
    4f7c:	001a0a13          	addi	s4,s4,1
    4f80:	fa5ff06f          	j	4f24 <tc1+0x180>
                if (got == 0x1111u) keep_ok++;
    4f84:	000017b7          	lui	a5,0x1
    4f88:	11178793          	addi	a5,a5,273 # 1111 <main+0xd>
    4f8c:	00f50e63          	beq	a0,a5,4fa8 <tc1+0x204>
                expect_px(40 + i, 140 + j, got, 0x1111u);
    4f90:	000016b7          	lui	a3,0x1
    4f94:	11168693          	addi	a3,a3,273 # 1111 <main+0xd>
    4f98:	00048593          	mv	a1,s1
    4f9c:	02840513          	addi	a0,s0,40
    4fa0:	d4cfe0ef          	jal	34ec <expect_px>
    4fa4:	f91ff06f          	j	4f34 <tc1+0x190>
                if (got == 0x1111u) keep_ok++;
    4fa8:	00198993          	addi	s3,s3,1
    4fac:	fe5ff06f          	j	4f90 <tc1+0x1ec>
    for (j = 0; j < 8; j++) {
    4fb0:	00190913          	addi	s2,s2,1
    4fb4:	00700793          	li	a5,7
    4fb8:	0127c663          	blt	a5,s2,4fc4 <tc1+0x220>
        for (i = 0; i < 16; i++) {
    4fbc:	000a8413          	mv	s0,s5
    4fc0:	f79ff06f          	j	4f38 <tc1+0x194>
    chk_outside(FB1_BASE, FB_STRIDE, 38, 138, 20, 12, 40, 140, 16, 8, SENT);
    4fc4:	000017b7          	lui	a5,0x1
    4fc8:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    4fcc:	00f12423          	sw	a5,8(sp)
    4fd0:	00800793          	li	a5,8
    4fd4:	00f12223          	sw	a5,4(sp)
    4fd8:	01000793          	li	a5,16
    4fdc:	00f12023          	sw	a5,0(sp)
    4fe0:	08c00893          	li	a7,140
    4fe4:	02800813          	li	a6,40
    4fe8:	00c00793          	li	a5,12
    4fec:	01400713          	li	a4,20
    4ff0:	08a00693          	li	a3,138
    4ff4:	02600613          	li	a2,38
    4ff8:	78000593          	li	a1,1920
    4ffc:	00401537          	lui	a0,0x401
    5000:	e1cfe0ef          	jal	361c <chk_outside>
    bsp_printf("      键色位保留 %d/64，非键色位写入 %d/64\r\n", keep_ok, write_ok);
    5004:	000a0613          	mv	a2,s4
    5008:	00098593          	mv	a1,s3
    500c:	00008537          	lui	a0,0x8
    5010:	c8c50513          	addi	a0,a0,-884 # 7c8c <_data+0xd38>
    5014:	c71fd0ef          	jal	2c84 <bsp_printf>
    item("C1 KEY 16x8 alternating key px", g_perf, g_mis);
    5018:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    501c:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    5020:	00008537          	lui	a0,0x8
    5024:	c1450513          	addi	a0,a0,-1004 # 7c14 <_data+0xcc0>
    5028:	c44fe0ef          	jal	346c <item>
    502c:	02812403          	lw	s0,40(sp)
    5030:	02412483          	lw	s1,36(sp)
    5034:	02012903          	lw	s2,32(sp)
    5038:	01c12983          	lw	s3,28(sp)
    503c:	01812a03          	lw	s4,24(sp)
    5040:	01412a83          	lw	s5,20(sp)
}
    5044:	02c12083          	lw	ra,44(sp)
    5048:	03010113          	addi	sp,sp,48
    504c:	00008067          	ret

00005050 <tc2>:
{
    5050:	fe010113          	addi	sp,sp,-32
    5054:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("C2 KEY 16x4 all-key -> dst untouched (byte exact)");
    5058:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    505c:	02078463          	beqz	a5,5084 <tc2+0x34>
    5060:	00812c23          	sw	s0,24(sp)
    5064:	00912a23          	sw	s1,20(sp)
    bsp_printf("  C2: KEY 16x4 源全键色 0x%x -> FB1(40,160)（目的梯度值，须逐字节原样）\r\n",
    5068:	000105b7          	lui	a1,0x10
    506c:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    5070:	00008537          	lui	a0,0x8
    5074:	cfc50513          	addi	a0,a0,-772 # 7cfc <_data+0xda8>
    5078:	c0dfd0ef          	jal	2c84 <bsp_printf>
    for (j = 0; j < 4; j++)
    507c:	00000493          	li	s1,0
    5080:	0500006f          	j	50d0 <tc2+0x80>
    SKIP_IF_DEAD("C2 KEY 16x4 all-key -> dst untouched (byte exact)");
    5084:	fff00613          	li	a2,-1
    5088:	00000593          	li	a1,0
    508c:	00008537          	lui	a0,0x8
    5090:	cc850513          	addi	a0,a0,-824 # 7cc8 <_data+0xd74>
    5094:	bd8fe0ef          	jal	346c <item>
    5098:	19c0006f          	j	5234 <tc2+0x1e4>
            wr16(PIX(SA_KEYROW, 32u, i, j), (uint16_t)KEY_COLOR);
    509c:	00008537          	lui	a0,0x8
    50a0:	38050513          	addi	a0,a0,896 # 8380 <_data+0x142c>
    50a4:	00a48533          	add	a0,s1,a0
    50a8:	00451513          	slli	a0,a0,0x4
    50ac:	00850533          	add	a0,a0,s0
    50b0:	000105b7          	lui	a1,0x10
    50b4:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    50b8:	00151513          	slli	a0,a0,0x1
    50bc:	fb0fc0ef          	jal	186c <wr16>
        for (i = 0; i < 16; i++)
    50c0:	00140413          	addi	s0,s0,1
    50c4:	00f00793          	li	a5,15
    50c8:	fc87dae3          	bge	a5,s0,509c <tc2+0x4c>
    for (j = 0; j < 4; j++)
    50cc:	00148493          	addi	s1,s1,1
    50d0:	00300793          	li	a5,3
    50d4:	0097c663          	blt	a5,s1,50e0 <tc2+0x90>
        for (i = 0; i < 16; i++)
    50d8:	00000413          	li	s0,0
    50dc:	fe9ff06f          	j	50c4 <tc2+0x74>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 32, 158, 32, 8, (uint16_t)SENT);   /* x32..63, y158..165 */
    50e0:	00001837          	lui	a6,0x1
    50e4:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    50e8:	00800793          	li	a5,8
    50ec:	02000713          	li	a4,32
    50f0:	09e00693          	li	a3,158
    50f4:	02000613          	li	a2,32
    50f8:	78000593          	li	a1,1920
    50fc:	00401537          	lui	a0,0x401
    5100:	f9cfc0ef          	jal	189c <fill_rect_cpu>
    for (j = 0; j < 4; j++)                                               /* 目的块：唯一梯度 */
    5104:	00000493          	li	s1,0
    5108:	0580006f          	j	5160 <tc2+0x110>
            wr16(PIX(FB1_BASE, FB_STRIDE, 40 + i, 160 + j), (uint16_t)(0x1000u + (uint32_t)j * 16u + (uint32_t)i));
    510c:	0a048793          	addi	a5,s1,160
    5110:	00479513          	slli	a0,a5,0x4
    5114:	40f50533          	sub	a0,a0,a5
    5118:	00651513          	slli	a0,a0,0x6
    511c:	00850533          	add	a0,a0,s0
    5120:	002017b7          	lui	a5,0x201
    5124:	82878793          	addi	a5,a5,-2008 # 200828 <__freertos_irq_stack_top+0x1f3b38>
    5128:	00f50533          	add	a0,a0,a5
    512c:	10048593          	addi	a1,s1,256
    5130:	00459593          	slli	a1,a1,0x4
    5134:	01059593          	slli	a1,a1,0x10
    5138:	0105d593          	srli	a1,a1,0x10
    513c:	008585b3          	add	a1,a1,s0
    5140:	01059593          	slli	a1,a1,0x10
    5144:	0105d593          	srli	a1,a1,0x10
    5148:	00151513          	slli	a0,a0,0x1
    514c:	f20fc0ef          	jal	186c <wr16>
        for (i = 0; i < 16; i++)
    5150:	00140413          	addi	s0,s0,1
    5154:	00f00793          	li	a5,15
    5158:	fa87dae3          	bge	a5,s0,510c <tc2+0xbc>
    for (j = 0; j < 4; j++)                                               /* 目的块：唯一梯度 */
    515c:	00148493          	addi	s1,s1,1
    5160:	00300793          	li	a5,3
    5164:	0097c663          	blt	a5,s1,5170 <tc2+0x120>
        for (i = 0; i < 16; i++)
    5168:	00000413          	li	s0,0
    516c:	fe9ff06f          	j	5154 <tc2+0x104>
    cache_evict();
    5170:	ff0fc0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_key(SA_KEYROW, PIX(FB1_BASE, FB_STRIDE, 40, 160), 32u, FB_STRIDE,
    5174:	00010837          	lui	a6,0x10
    5178:	81f80813          	addi	a6,a6,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    517c:	00400793          	li	a5,4
    5180:	01000713          	li	a4,16
    5184:	78000693          	li	a3,1920
    5188:	02000613          	li	a2,32
    518c:	0044c5b7          	lui	a1,0x44c
    5190:	05058593          	addi	a1,a1,80 # 44c050 <__freertos_irq_stack_top+0x43f360>
    5194:	00107537          	lui	a0,0x107
    5198:	b90fd0ef          	jal	2528 <blt_key>
    519c:	000085b7          	lui	a1,0x8
    51a0:	d5858593          	addi	a1,a1,-680 # 7d58 <_data+0xe04>
    51a4:	f65fd0ef          	jal	3108 <op_fail>
    51a8:	08051c63          	bnez	a0,5240 <tc2+0x1f0>
    cache_invalidate();
    51ac:	815fc0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    51b0:	819fc0ef          	jal	19c8 <mis_reset>
    chk_pat(FB1_BASE, FB_STRIDE, 40, 160, 16, 4, 0x1000u, 16u);   /* 目的块逐像素原样 */
    51b4:	01000893          	li	a7,16
    51b8:	00001837          	lui	a6,0x1
    51bc:	00400793          	li	a5,4
    51c0:	01000713          	li	a4,16
    51c4:	0a000693          	li	a3,160
    51c8:	02800613          	li	a2,40
    51cc:	78000593          	li	a1,1920
    51d0:	00401537          	lui	a0,0x401
    51d4:	d5cfe0ef          	jal	3730 <chk_pat>
    chk_outside(FB1_BASE, FB_STRIDE, 32, 158, 32, 8, 40, 160, 16, 4, SENT);
    51d8:	000017b7          	lui	a5,0x1
    51dc:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    51e0:	00f12423          	sw	a5,8(sp)
    51e4:	00400793          	li	a5,4
    51e8:	00f12223          	sw	a5,4(sp)
    51ec:	01000793          	li	a5,16
    51f0:	00f12023          	sw	a5,0(sp)
    51f4:	0a000893          	li	a7,160
    51f8:	02800813          	li	a6,40
    51fc:	00800793          	li	a5,8
    5200:	02000713          	li	a4,32
    5204:	09e00693          	li	a3,158
    5208:	02000613          	li	a2,32
    520c:	78000593          	li	a1,1920
    5210:	00401537          	lui	a0,0x401
    5214:	c08fe0ef          	jal	361c <chk_outside>
    item("C2 KEY 16x4 all-key -> dst untouched (byte exact)", g_perf, g_mis);
    5218:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    521c:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    5220:	00008537          	lui	a0,0x8
    5224:	cc850513          	addi	a0,a0,-824 # 7cc8 <_data+0xd74>
    5228:	a44fe0ef          	jal	346c <item>
    522c:	01812403          	lw	s0,24(sp)
    5230:	01412483          	lw	s1,20(sp)
}
    5234:	01c12083          	lw	ra,28(sp)
    5238:	02010113          	addi	sp,sp,32
    523c:	00008067          	ret
        item("C2 KEY 16x4 all-key -> dst untouched", 0u, -1);
    5240:	fff00613          	li	a2,-1
    5244:	00000593          	li	a1,0
    5248:	00008537          	lui	a0,0x8
    524c:	d6850513          	addi	a0,a0,-664 # 7d68 <_data+0xe14>
    5250:	a1cfe0ef          	jal	346c <item>
        return;
    5254:	01812403          	lw	s0,24(sp)
    5258:	01412483          	lw	s1,20(sp)
    525c:	fd9ff06f          	j	5234 <tc2+0x1e4>

00005260 <tc3>:
{
    5260:	fe010113          	addi	sp,sp,-32
    5264:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("C3 KEY 32x32 key-border sprite over checkerboard");
    5268:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    526c:	02078863          	beqz	a5,529c <tc3+0x3c>
    5270:	00812c23          	sw	s0,24(sp)
    5274:	00912a23          	sw	s1,20(sp)
    bsp_printf("  C3: KEY 32x32（边=键色 0x%x，内=0x%x）-> FB1(304,140) 棋盘背景\r\n",
    5278:	00010637          	lui	a2,0x10
    527c:	d2060613          	addi	a2,a2,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    5280:	000105b7          	lui	a1,0x10
    5284:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    5288:	00008537          	lui	a0,0x8
    528c:	dc450513          	addi	a0,a0,-572 # 7dc4 <_data+0xe70>
    5290:	9f5fd0ef          	jal	2c84 <bsp_printf>
    for (j = 0; j < 32; j++) {
    5294:	00000493          	li	s1,0
    5298:	0940006f          	j	532c <tc3+0xcc>
    SKIP_IF_DEAD("C3 KEY 32x32 key-border sprite over checkerboard");
    529c:	fff00613          	li	a2,-1
    52a0:	00000593          	li	a1,0
    52a4:	00008537          	lui	a0,0x8
    52a8:	d9050513          	addi	a0,a0,-624 # 7d90 <_data+0xe3c>
    52ac:	9c0fe0ef          	jal	346c <item>
    52b0:	38c0006f          	j	563c <tc3+0x3dc>
            if (i == 0 || j == 0 || i == 31 || j == 31) c = (uint16_t)KEY_COLOR;
    52b4:	000105b7          	lui	a1,0x10
    52b8:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    52bc:	00c0006f          	j	52c8 <tc3+0x68>
    52c0:	000105b7          	lui	a1,0x10
    52c4:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
            wr16(PIX(SA_SPR, ATLAS_STRIDE, i, j), c);
    52c8:	00004537          	lui	a0,0x4
    52cc:	20050513          	addi	a0,a0,512 # 4200 <tb1+0x34>
    52d0:	00a48533          	add	a0,s1,a0
    52d4:	00551513          	slli	a0,a0,0x5
    52d8:	00850533          	add	a0,a0,s0
    52dc:	00151513          	slli	a0,a0,0x1
    52e0:	d8cfc0ef          	jal	186c <wr16>
        for (i = 0; i < 32; i++) {
    52e4:	00140413          	addi	s0,s0,1
    52e8:	01f00793          	li	a5,31
    52ec:	0287ce63          	blt	a5,s0,5328 <tc3+0xc8>
            if (i == 0 || j == 0 || i == 31 || j == 31) c = (uint16_t)KEY_COLOR;
    52f0:	fc0408e3          	beqz	s0,52c0 <tc3+0x60>
    52f4:	00048e63          	beqz	s1,5310 <tc3+0xb0>
    52f8:	01f00793          	li	a5,31
    52fc:	02f40063          	beq	s0,a5,531c <tc3+0xbc>
    5300:	faf48ae3          	beq	s1,a5,52b4 <tc3+0x54>
            else                                        c = (uint16_t)C_ORANGE;
    5304:	000105b7          	lui	a1,0x10
    5308:	d2058593          	addi	a1,a1,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    530c:	fbdff06f          	j	52c8 <tc3+0x68>
            if (i == 0 || j == 0 || i == 31 || j == 31) c = (uint16_t)KEY_COLOR;
    5310:	000105b7          	lui	a1,0x10
    5314:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    5318:	fb1ff06f          	j	52c8 <tc3+0x68>
    531c:	000105b7          	lui	a1,0x10
    5320:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    5324:	fa5ff06f          	j	52c8 <tc3+0x68>
    for (j = 0; j < 32; j++) {
    5328:	00148493          	addi	s1,s1,1
    532c:	01f00793          	li	a5,31
    5330:	0097c663          	blt	a5,s1,533c <tc3+0xdc>
        for (i = 0; i < 32; i++) {
    5334:	00000413          	li	s0,0
    5338:	fb1ff06f          	j	52e8 <tc3+0x88>
    for (j = 136; j < 176; j++)
    533c:	08800493          	li	s1,136
    5340:	0580006f          	j	5398 <tc3+0x138>
            wr16(PIX(FB1_BASE, FB_STRIDE, i, j), (uint16_t)(((i + j) & 1) ? 0x1111u : 0x2222u));
    5344:	000025b7          	lui	a1,0x2
    5348:	22258593          	addi	a1,a1,546 # 2222 <push_cmd_fast+0xa6>
    534c:	d20fc0ef          	jal	186c <wr16>
        for (i = 300; i < 340; i++)
    5350:	00140413          	addi	s0,s0,1
    5354:	15300793          	li	a5,339
    5358:	0287ce63          	blt	a5,s0,5394 <tc3+0x134>
            wr16(PIX(FB1_BASE, FB_STRIDE, i, j), (uint16_t)(((i + j) & 1) ? 0x1111u : 0x2222u));
    535c:	00449513          	slli	a0,s1,0x4
    5360:	40950533          	sub	a0,a0,s1
    5364:	00651513          	slli	a0,a0,0x6
    5368:	00850533          	add	a0,a0,s0
    536c:	002017b7          	lui	a5,0x201
    5370:	80078793          	addi	a5,a5,-2048 # 200800 <__freertos_irq_stack_top+0x1f3b10>
    5374:	00f50533          	add	a0,a0,a5
    5378:	00151513          	slli	a0,a0,0x1
    537c:	009407b3          	add	a5,s0,s1
    5380:	0017f793          	andi	a5,a5,1
    5384:	fc0780e3          	beqz	a5,5344 <tc3+0xe4>
    5388:	000015b7          	lui	a1,0x1
    538c:	11158593          	addi	a1,a1,273 # 1111 <main+0xd>
    5390:	fbdff06f          	j	534c <tc3+0xec>
    for (j = 136; j < 176; j++)
    5394:	00148493          	addi	s1,s1,1
    5398:	0af00793          	li	a5,175
    539c:	0097c663          	blt	a5,s1,53a8 <tc3+0x148>
        for (i = 300; i < 340; i++)
    53a0:	12c00413          	li	s0,300
    53a4:	fb1ff06f          	j	5354 <tc3+0xf4>
    cache_evict();
    53a8:	db8fc0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_key(SA_SPR, PIX(FB1_BASE, FB_STRIDE, 304, 140), ATLAS_STRIDE, FB_STRIDE,
    53ac:	00010837          	lui	a6,0x10
    53b0:	81f80813          	addi	a6,a6,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    53b4:	02000793          	li	a5,32
    53b8:	02000713          	li	a4,32
    53bc:	78000693          	li	a3,1920
    53c0:	04000613          	li	a2,64
    53c4:	004435b7          	lui	a1,0x443
    53c8:	c6058593          	addi	a1,a1,-928 # 442c60 <__freertos_irq_stack_top+0x435f70>
    53cc:	00108537          	lui	a0,0x108
    53d0:	958fd0ef          	jal	2528 <blt_key>
    53d4:	000085b7          	lui	a1,0x8
    53d8:	e1458593          	addi	a1,a1,-492 # 7e14 <_data+0xec0>
    53dc:	d2dfd0ef          	jal	3108 <op_fail>
    53e0:	00050413          	mv	s0,a0
    53e4:	02051663          	bnez	a0,5410 <tc3+0x1b0>
    53e8:	01212823          	sw	s2,16(sp)
    53ec:	01312623          	sw	s3,12(sp)
    53f0:	01412423          	sw	s4,8(sp)
    53f4:	01512223          	sw	s5,4(sp)
    53f8:	01612023          	sw	s6,0(sp)
    cache_invalidate();
    53fc:	dc4fc0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    5400:	dc8fc0ef          	jal	19c8 <mis_reset>
    int i, j, border_ok = 0, inner_ok = 0;
    5404:	00040493          	mv	s1,s0
    for (j = 1; j < 31; j++) {
    5408:	00100a13          	li	s4,1
    540c:	0880006f          	j	5494 <tc3+0x234>
        item("C3 KEY 32x32 key-border sprite", 0u, -1);
    5410:	fff00613          	li	a2,-1
    5414:	00000593          	li	a1,0
    5418:	00008537          	lui	a0,0x8
    541c:	e2450513          	addi	a0,a0,-476 # 7e24 <_data+0xed0>
    5420:	84cfe0ef          	jal	346c <item>
        return;
    5424:	01812403          	lw	s0,24(sp)
    5428:	01412483          	lw	s1,20(sp)
    542c:	2100006f          	j	563c <tc3+0x3dc>
            expect_px(304 + i, 140 + j, got, C_ORANGE);
    5430:	000106b7          	lui	a3,0x10
    5434:	d2068693          	addi	a3,a3,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    5438:	00098593          	mv	a1,s3
    543c:	13090513          	addi	a0,s2,304
    5440:	8acfe0ef          	jal	34ec <expect_px>
        for (i = 1; i < 31; i++) {
    5444:	00190913          	addi	s2,s2,1
    5448:	01e00793          	li	a5,30
    544c:	0527c263          	blt	a5,s2,5490 <tc3+0x230>
            uint32_t got = rd16(PIX(FB1_BASE, FB_STRIDE, 304 + i, 140 + j));
    5450:	08ca0993          	addi	s3,s4,140
    5454:	00499513          	slli	a0,s3,0x4
    5458:	41350533          	sub	a0,a0,s3
    545c:	00651513          	slli	a0,a0,0x6
    5460:	01250533          	add	a0,a0,s2
    5464:	002017b7          	lui	a5,0x201
    5468:	93078793          	addi	a5,a5,-1744 # 200930 <__freertos_irq_stack_top+0x1f3c40>
    546c:	00f50533          	add	a0,a0,a5
    5470:	00151513          	slli	a0,a0,0x1
    5474:	c00fc0ef          	jal	1874 <rd16>
    5478:	00050613          	mv	a2,a0
            if (got == C_ORANGE) inner_ok++;
    547c:	000107b7          	lui	a5,0x10
    5480:	d2078793          	addi	a5,a5,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    5484:	faf516e3          	bne	a0,a5,5430 <tc3+0x1d0>
    5488:	00148493          	addi	s1,s1,1
    548c:	fa5ff06f          	j	5430 <tc3+0x1d0>
    for (j = 1; j < 31; j++) {
    5490:	001a0a13          	addi	s4,s4,1
    5494:	01e00793          	li	a5,30
    5498:	0147c663          	blt	a5,s4,54a4 <tc3+0x244>
        for (i = 1; i < 31; i++) {
    549c:	00100913          	li	s2,1
    54a0:	fa9ff06f          	j	5448 <tc3+0x1e8>
    int i, j, border_ok = 0, inner_ok = 0;
    54a4:	00040913          	mv	s2,s0
    for (j = 0; j < 32; j++) {
    54a8:	00040a13          	mv	s4,s0
    54ac:	0980006f          	j	5544 <tc3+0x2e4>
                uint32_t exp = (uint32_t)(((304 + i + 140 + j) & 1) ? 0x1111u : 0x2222u);
    54b0:	1bc98793          	addi	a5,s3,444
    54b4:	014787b3          	add	a5,a5,s4
    54b8:	0017f793          	andi	a5,a5,1
    54bc:	06078863          	beqz	a5,552c <tc3+0x2cc>
    54c0:	00001ab7          	lui	s5,0x1
    54c4:	111a8a93          	addi	s5,s5,273 # 1111 <main+0xd>
                uint32_t got = rd16(PIX(FB1_BASE, FB_STRIDE, 304 + i, 140 + j));
    54c8:	08ca0b13          	addi	s6,s4,140
    54cc:	004b1513          	slli	a0,s6,0x4
    54d0:	41650533          	sub	a0,a0,s6
    54d4:	00651513          	slli	a0,a0,0x6
    54d8:	01350533          	add	a0,a0,s3
    54dc:	002017b7          	lui	a5,0x201
    54e0:	93078793          	addi	a5,a5,-1744 # 200930 <__freertos_irq_stack_top+0x1f3c40>
    54e4:	00f50533          	add	a0,a0,a5
    54e8:	00151513          	slli	a0,a0,0x1
    54ec:	b88fc0ef          	jal	1874 <rd16>
    54f0:	00050613          	mv	a2,a0
                if (got == exp) border_ok++;
    54f4:	04aa8263          	beq	s5,a0,5538 <tc3+0x2d8>
                expect_px(304 + i, 140 + j, got, exp);
    54f8:	000a8693          	mv	a3,s5
    54fc:	000b0593          	mv	a1,s6
    5500:	13098513          	addi	a0,s3,304
    5504:	fe9fd0ef          	jal	34ec <expect_px>
        for (i = 0; i < 32; i++) {
    5508:	00198993          	addi	s3,s3,1
    550c:	01f00793          	li	a5,31
    5510:	0337c863          	blt	a5,s3,5540 <tc3+0x2e0>
            int isb = (i == 0 || j == 0 || i == 31 || j == 31);
    5514:	f8098ee3          	beqz	s3,54b0 <tc3+0x250>
    5518:	f80a0ce3          	beqz	s4,54b0 <tc3+0x250>
    551c:	01f00793          	li	a5,31
    5520:	f8f988e3          	beq	s3,a5,54b0 <tc3+0x250>
    5524:	f8fa06e3          	beq	s4,a5,54b0 <tc3+0x250>
    5528:	fe1ff06f          	j	5508 <tc3+0x2a8>
                uint32_t exp = (uint32_t)(((304 + i + 140 + j) & 1) ? 0x1111u : 0x2222u);
    552c:	00002ab7          	lui	s5,0x2
    5530:	222a8a93          	addi	s5,s5,546 # 2222 <push_cmd_fast+0xa6>
    5534:	f95ff06f          	j	54c8 <tc3+0x268>
                if (got == exp) border_ok++;
    5538:	00190913          	addi	s2,s2,1
    553c:	fbdff06f          	j	54f8 <tc3+0x298>
    for (j = 0; j < 32; j++) {
    5540:	001a0a13          	addi	s4,s4,1
    5544:	01f00793          	li	a5,31
    5548:	0147c663          	blt	a5,s4,5554 <tc3+0x2f4>
        for (i = 0; i < 32; i++) {
    554c:	00040993          	mv	s3,s0
    5550:	fbdff06f          	j	550c <tc3+0x2ac>
    for (j = 136; j < 176; j++) {
    5554:	08800993          	li	s3,136
    5558:	0900006f          	j	55e8 <tc3+0x388>
            if (i >= 304 && i < 336 && j >= 140 && j < 172) continue;   /* 块内已单独查过 */
    555c:	08b00793          	li	a5,139
    5560:	0737d663          	bge	a5,s3,55cc <tc3+0x36c>
    5564:	0ab00793          	li	a5,171
    5568:	0737c263          	blt	a5,s3,55cc <tc3+0x36c>
    556c:	0440006f          	j	55b0 <tc3+0x350>
            exp2 = (uint32_t)(((i + j) & 1) ? 0x1111u : 0x2222u);
    5570:	00002a37          	lui	s4,0x2
    5574:	222a0a13          	addi	s4,s4,546 # 2222 <push_cmd_fast+0xa6>
            expect_px(i, j, rd16(PIX(FB1_BASE, FB_STRIDE, i, j)), exp2);
    5578:	00499513          	slli	a0,s3,0x4
    557c:	41350533          	sub	a0,a0,s3
    5580:	00651513          	slli	a0,a0,0x6
    5584:	00e50533          	add	a0,a0,a4
    5588:	002017b7          	lui	a5,0x201
    558c:	80078793          	addi	a5,a5,-2048 # 200800 <__freertos_irq_stack_top+0x1f3b10>
    5590:	00f50533          	add	a0,a0,a5
    5594:	00151513          	slli	a0,a0,0x1
    5598:	adcfc0ef          	jal	1874 <rd16>
    559c:	00050613          	mv	a2,a0
    55a0:	000a0693          	mv	a3,s4
    55a4:	00098593          	mv	a1,s3
    55a8:	00040513          	mv	a0,s0
    55ac:	f41fd0ef          	jal	34ec <expect_px>
        for (i = 300; i < 340; i++) {
    55b0:	00140413          	addi	s0,s0,1
    55b4:	15300793          	li	a5,339
    55b8:	0287c663          	blt	a5,s0,55e4 <tc3+0x384>
            if (i >= 304 && i < 336 && j >= 140 && j < 172) continue;   /* 块内已单独查过 */
    55bc:	00040713          	mv	a4,s0
    55c0:	ed040793          	addi	a5,s0,-304
    55c4:	01f00693          	li	a3,31
    55c8:	f8f6fae3          	bgeu	a3,a5,555c <tc3+0x2fc>
            exp2 = (uint32_t)(((i + j) & 1) ? 0x1111u : 0x2222u);
    55cc:	013407b3          	add	a5,s0,s3
    55d0:	0017f793          	andi	a5,a5,1
    55d4:	f8078ee3          	beqz	a5,5570 <tc3+0x310>
    55d8:	00001a37          	lui	s4,0x1
    55dc:	111a0a13          	addi	s4,s4,273 # 1111 <main+0xd>
    55e0:	f99ff06f          	j	5578 <tc3+0x318>
    for (j = 136; j < 176; j++) {
    55e4:	00198993          	addi	s3,s3,1
    55e8:	0af00793          	li	a5,175
    55ec:	0137c663          	blt	a5,s3,55f8 <tc3+0x398>
        for (i = 300; i < 340; i++) {
    55f0:	12c00413          	li	s0,300
    55f4:	fc1ff06f          	j	55b4 <tc3+0x354>
    bsp_printf("      内部写入 %d/900，边框保留 %d/124\r\n", inner_ok, border_ok);
    55f8:	00090613          	mv	a2,s2
    55fc:	00048593          	mv	a1,s1
    5600:	00008537          	lui	a0,0x8
    5604:	e4450513          	addi	a0,a0,-444 # 7e44 <_data+0xef0>
    5608:	e7cfd0ef          	jal	2c84 <bsp_printf>
    item("C3 KEY 32x32 key-border sprite", g_perf, g_mis);
    560c:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    5610:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    5614:	00008537          	lui	a0,0x8
    5618:	e2450513          	addi	a0,a0,-476 # 7e24 <_data+0xed0>
    561c:	e51fd0ef          	jal	346c <item>
    5620:	01812403          	lw	s0,24(sp)
    5624:	01412483          	lw	s1,20(sp)
    5628:	01012903          	lw	s2,16(sp)
    562c:	00c12983          	lw	s3,12(sp)
    5630:	00812a03          	lw	s4,8(sp)
    5634:	00412a83          	lw	s5,4(sp)
    5638:	00012b03          	lw	s6,0(sp)
}
    563c:	01c12083          	lw	ra,28(sp)
    5640:	02010113          	addi	sp,sp,32
    5644:	00008067          	ret

00005648 <tc4>:
{
    5648:	fc010113          	addi	sp,sp,-64
    564c:	02112e23          	sw	ra,60(sp)
    SKIP_IF_DEAD("C4 KEY 16x8 @x=7 (dst unaligned)");
    5650:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    5654:	02078463          	beqz	a5,567c <tc4+0x34>
    5658:	02812c23          	sw	s0,56(sp)
    565c:	02912a23          	sw	s1,52(sp)
    5660:	01712e23          	sw	s7,28(sp)
    bsp_printf("  C4: KEY 16x8 src=0x%x -> FB1(7,200)（字节偏移 14，首词只写 1 个 lane）\r\n",
    5664:	001095b7          	lui	a1,0x109
    5668:	00008537          	lui	a0,0x8
    566c:	e9c50513          	addi	a0,a0,-356 # 7e9c <_data+0xf48>
    5670:	e14fd0ef          	jal	2c84 <bsp_printf>
    for (j = 0; j < 8; j++)
    5674:	00000493          	li	s1,0
    5678:	0600006f          	j	56d8 <tc4+0x90>
    SKIP_IF_DEAD("C4 KEY 16x8 @x=7 (dst unaligned)");
    567c:	fff00613          	li	a2,-1
    5680:	00000593          	li	a1,0
    5684:	00008537          	lui	a0,0x8
    5688:	e7850513          	addi	a0,a0,-392 # 7e78 <_data+0xf24>
    568c:	de1fd0ef          	jal	346c <item>
    5690:	2ac0006f          	j	593c <tc4+0x2f4>
            wr16(PIX(SA_KEYUN, 32u, i, j), (i & 1) ? (uint16_t)C_CYAN : (uint16_t)KEY_COLOR);
    5694:	000105b7          	lui	a1,0x10
    5698:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    569c:	9d0fc0ef          	jal	186c <wr16>
        for (i = 0; i < 16; i++)
    56a0:	00140413          	addi	s0,s0,1
    56a4:	00f00793          	li	a5,15
    56a8:	0287c663          	blt	a5,s0,56d4 <tc4+0x8c>
            wr16(PIX(SA_KEYUN, 32u, i, j), (i & 1) ? (uint16_t)C_CYAN : (uint16_t)KEY_COLOR);
    56ac:	000087b7          	lui	a5,0x8
    56b0:	48078793          	addi	a5,a5,1152 # 8480 <_data+0x152c>
    56b4:	00f48533          	add	a0,s1,a5
    56b8:	00451513          	slli	a0,a0,0x4
    56bc:	00850533          	add	a0,a0,s0
    56c0:	00151513          	slli	a0,a0,0x1
    56c4:	00147793          	andi	a5,s0,1
    56c8:	fc0786e3          	beqz	a5,5694 <tc4+0x4c>
    56cc:	7ff00593          	li	a1,2047
    56d0:	fcdff06f          	j	569c <tc4+0x54>
    for (j = 0; j < 8; j++)
    56d4:	00148493          	addi	s1,s1,1
    56d8:	00700793          	li	a5,7
    56dc:	0097c663          	blt	a5,s1,56e8 <tc4+0xa0>
        for (i = 0; i < 16; i++)
    56e0:	00000413          	li	s0,0
    56e4:	fc1ff06f          	j	56a4 <tc4+0x5c>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 199, 32, 10, (uint16_t)SENT);
    56e8:	00001837          	lui	a6,0x1
    56ec:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    56f0:	00a00793          	li	a5,10
    56f4:	02000713          	li	a4,32
    56f8:	0c700693          	li	a3,199
    56fc:	00000613          	li	a2,0
    5700:	78000593          	li	a1,1920
    5704:	00401537          	lui	a0,0x401
    5708:	994fc0ef          	jal	189c <fill_rect_cpu>
    for (j = 0; j < 8; j++)
    570c:	00000493          	li	s1,0
    5710:	0640006f          	j	5774 <tc4+0x12c>
            wr16(PIX(FB1_BASE, FB_STRIDE, 7 + i, 200 + j),
    5714:	0c848793          	addi	a5,s1,200
    5718:	00479513          	slli	a0,a5,0x4
    571c:	40f50533          	sub	a0,a0,a5
    5720:	00651513          	slli	a0,a0,0x6
    5724:	00850533          	add	a0,a0,s0
    5728:	002017b7          	lui	a5,0x201
    572c:	80778793          	addi	a5,a5,-2041 # 200807 <__freertos_irq_stack_top+0x1f3b17>
    5730:	00f50533          	add	a0,a0,a5
                 (uint16_t)(0x3000u + (uint32_t)j * 40u + (uint32_t)i));
    5734:	00249593          	slli	a1,s1,0x2
    5738:	00b485b3          	add	a1,s1,a1
    573c:	00359593          	slli	a1,a1,0x3
    5740:	008585b3          	add	a1,a1,s0
    5744:	01059593          	slli	a1,a1,0x10
    5748:	0105d593          	srli	a1,a1,0x10
            wr16(PIX(FB1_BASE, FB_STRIDE, 7 + i, 200 + j),
    574c:	000037b7          	lui	a5,0x3
    5750:	00f585b3          	add	a1,a1,a5
    5754:	01059593          	slli	a1,a1,0x10
    5758:	0105d593          	srli	a1,a1,0x10
    575c:	00151513          	slli	a0,a0,0x1
    5760:	90cfc0ef          	jal	186c <wr16>
        for (i = 0; i < 16; i++)
    5764:	00140413          	addi	s0,s0,1
    5768:	00f00793          	li	a5,15
    576c:	fa87d4e3          	bge	a5,s0,5714 <tc4+0xcc>
    for (j = 0; j < 8; j++)
    5770:	00148493          	addi	s1,s1,1
    5774:	00700793          	li	a5,7
    5778:	0097c663          	blt	a5,s1,5784 <tc4+0x13c>
        for (i = 0; i < 16; i++)
    577c:	00000413          	li	s0,0
    5780:	fe9ff06f          	j	5768 <tc4+0x120>
    cache_evict();
    5784:	9dcfc0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_key(SA_KEYUN, PIX(FB1_BASE, FB_STRIDE, 7, 200), 32u, FB_STRIDE,
    5788:	00010837          	lui	a6,0x10
    578c:	81f80813          	addi	a6,a6,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    5790:	00800793          	li	a5,8
    5794:	01000713          	li	a4,16
    5798:	78000693          	li	a3,1920
    579c:	02000613          	li	a2,32
    57a0:	0045f5b7          	lui	a1,0x45f
    57a4:	c0e58593          	addi	a1,a1,-1010 # 45ec0e <__freertos_irq_stack_top+0x451f1e>
    57a8:	00109537          	lui	a0,0x109
    57ac:	d7dfc0ef          	jal	2528 <blt_key>
    57b0:	000085b7          	lui	a1,0x8
    57b4:	ef458593          	addi	a1,a1,-268 # 7ef4 <_data+0xfa0>
    57b8:	951fd0ef          	jal	3108 <op_fail>
    57bc:	00050b93          	mv	s7,a0
    57c0:	02051863          	bnez	a0,57f0 <tc4+0x1a8>
    57c4:	03212823          	sw	s2,48(sp)
    57c8:	03312623          	sw	s3,44(sp)
    57cc:	03412423          	sw	s4,40(sp)
    57d0:	03512223          	sw	s5,36(sp)
    57d4:	03612023          	sw	s6,32(sp)
    cache_invalidate();
    57d8:	9e8fc0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    57dc:	9ecfc0ef          	jal	19c8 <mis_reset>
    int i, j, keep_ok = 0, write_ok = 0;
    57e0:	000b8b13          	mv	s6,s7
    57e4:	000b8a93          	mv	s5,s7
    for (j = 0; j < 8; j++) {
    57e8:	000b8993          	mv	s3,s7
    57ec:	0b80006f          	j	58a4 <tc4+0x25c>
        item("C4 KEY 16x8 @x=7 (dst unaligned)", 0u, -1);
    57f0:	fff00613          	li	a2,-1
    57f4:	00000593          	li	a1,0
    57f8:	00008537          	lui	a0,0x8
    57fc:	e7850513          	addi	a0,a0,-392 # 7e78 <_data+0xf24>
    5800:	c6dfd0ef          	jal	346c <item>
        return;
    5804:	03812403          	lw	s0,56(sp)
    5808:	03412483          	lw	s1,52(sp)
    580c:	01c12b83          	lw	s7,28(sp)
    5810:	12c0006f          	j	593c <tc4+0x2f4>
            else       { if (got == exp) keep_ok++;  }
    5814:	08a40263          	beq	s0,a0,5898 <tc4+0x250>
            expect_px(7 + i, 200 + j, got, exp);
    5818:	00040693          	mv	a3,s0
    581c:	00090593          	mv	a1,s2
    5820:	00748513          	addi	a0,s1,7
    5824:	cc9fd0ef          	jal	34ec <expect_px>
        for (i = 0; i < 16; i++) {
    5828:	00148493          	addi	s1,s1,1
    582c:	00f00793          	li	a5,15
    5830:	0697c863          	blt	a5,s1,58a0 <tc4+0x258>
            uint32_t orig = 0x3000u + (uint32_t)j * 40u + (uint32_t)i;
    5834:	00299413          	slli	s0,s3,0x2
    5838:	01340433          	add	s0,s0,s3
    583c:	00341413          	slli	s0,s0,0x3
    5840:	00048793          	mv	a5,s1
    5844:	00940433          	add	s0,s0,s1
    5848:	00003737          	lui	a4,0x3
    584c:	00e40433          	add	s0,s0,a4
            uint32_t exp  = (i & 1) ? C_CYAN : orig;
    5850:	0014fa13          	andi	s4,s1,1
    5854:	000a0463          	beqz	s4,585c <tc4+0x214>
    5858:	7ff00413          	li	s0,2047
            uint32_t got  = rd16(PIX(FB1_BASE, FB_STRIDE, 7 + i, 200 + j));
    585c:	0c898913          	addi	s2,s3,200
    5860:	00491513          	slli	a0,s2,0x4
    5864:	41250533          	sub	a0,a0,s2
    5868:	00651513          	slli	a0,a0,0x6
    586c:	00f50533          	add	a0,a0,a5
    5870:	002017b7          	lui	a5,0x201
    5874:	80778793          	addi	a5,a5,-2041 # 200807 <__freertos_irq_stack_top+0x1f3b17>
    5878:	00f50533          	add	a0,a0,a5
    587c:	00151513          	slli	a0,a0,0x1
    5880:	ff5fb0ef          	jal	1874 <rd16>
    5884:	00050613          	mv	a2,a0
            if (i & 1) { if (got == exp) write_ok++; }
    5888:	f80a06e3          	beqz	s4,5814 <tc4+0x1cc>
    588c:	f8a416e3          	bne	s0,a0,5818 <tc4+0x1d0>
    5890:	001b0b13          	addi	s6,s6,1
    5894:	f85ff06f          	j	5818 <tc4+0x1d0>
            else       { if (got == exp) keep_ok++;  }
    5898:	001a8a93          	addi	s5,s5,1
    589c:	f7dff06f          	j	5818 <tc4+0x1d0>
    for (j = 0; j < 8; j++) {
    58a0:	00198993          	addi	s3,s3,1
    58a4:	00700793          	li	a5,7
    58a8:	0137c663          	blt	a5,s3,58b4 <tc4+0x26c>
        for (i = 0; i < 16; i++) {
    58ac:	000b8493          	mv	s1,s7
    58b0:	f7dff06f          	j	582c <tc4+0x1e4>
    chk_outside(FB1_BASE, FB_STRIDE, 0, 199, 32, 10, 7, 200, 16, 8, SENT);
    58b4:	000017b7          	lui	a5,0x1
    58b8:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    58bc:	00f12423          	sw	a5,8(sp)
    58c0:	00800793          	li	a5,8
    58c4:	00f12223          	sw	a5,4(sp)
    58c8:	01000793          	li	a5,16
    58cc:	00f12023          	sw	a5,0(sp)
    58d0:	0c800893          	li	a7,200
    58d4:	00700813          	li	a6,7
    58d8:	00a00793          	li	a5,10
    58dc:	02000713          	li	a4,32
    58e0:	0c700693          	li	a3,199
    58e4:	00000613          	li	a2,0
    58e8:	78000593          	li	a1,1920
    58ec:	00401537          	lui	a0,0x401
    58f0:	d2dfd0ef          	jal	361c <chk_outside>
    bsp_printf("      键色位保留 %d/64，非键色位写入 %d/64\r\n", keep_ok, write_ok);
    58f4:	000b0613          	mv	a2,s6
    58f8:	000a8593          	mv	a1,s5
    58fc:	00008537          	lui	a0,0x8
    5900:	c8c50513          	addi	a0,a0,-884 # 7c8c <_data+0xd38>
    5904:	b80fd0ef          	jal	2c84 <bsp_printf>
    item("C4 KEY 16x8 @x=7 (dst unaligned)", g_perf, g_mis);
    5908:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    590c:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    5910:	00008537          	lui	a0,0x8
    5914:	e7850513          	addi	a0,a0,-392 # 7e78 <_data+0xf24>
    5918:	b55fd0ef          	jal	346c <item>
    591c:	03812403          	lw	s0,56(sp)
    5920:	03412483          	lw	s1,52(sp)
    5924:	03012903          	lw	s2,48(sp)
    5928:	02c12983          	lw	s3,44(sp)
    592c:	02812a03          	lw	s4,40(sp)
    5930:	02412a83          	lw	s5,36(sp)
    5934:	02012b03          	lw	s6,32(sp)
    5938:	01c12b83          	lw	s7,28(sp)
}
    593c:	03c12083          	lw	ra,60(sp)
    5940:	04010113          	addi	sp,sp,64
    5944:	00008067          	ret

00005948 <td1>:
{
    5948:	fe010113          	addi	sp,sp,-32
    594c:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("D1 ALPHA a=0 -> pure bg");
    5950:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    5954:	18078e63          	beqz	a5,5af0 <td1+0x1a8>
    5958:	00812c23          	sw	s0,24(sp)
    595c:	00912a23          	sw	s1,20(sp)
    exp = alpha_ref(0xFFFFu, 0xC618u, 0u);
    5960:	00000613          	li	a2,0
    5964:	0000c5b7          	lui	a1,0xc
    5968:	61858593          	addi	a1,a1,1560 # c618 <_end+0x930>
    596c:	000104b7          	lui	s1,0x10
    5970:	fff48513          	addi	a0,s1,-1 # ffff <__freertos_irq_stack_top+0x330f>
    5974:	880fc0ef          	jal	19f4 <alpha_ref>
    5978:	00050413          	mv	s0,a0
    bsp_printf("  D1: ALPHA α=0 fg=0xffff bg=0xc618 -> FB1(96,240)，期望 = 背景 0x%x\r\n", (int)exp);
    597c:	00050593          	mv	a1,a0
    5980:	00008537          	lui	a0,0x8
    5984:	f5050513          	addi	a0,a0,-176 # 7f50 <_data+0xffc>
    5988:	afcfd0ef          	jal	2c84 <bsp_printf>
    fill_rect_cpu(SA_ALPHA, 32u, 0, 0, 16, 8, 0xFFFFu);
    598c:	fff48813          	addi	a6,s1,-1
    5990:	00800793          	li	a5,8
    5994:	01000713          	li	a4,16
    5998:	00000693          	li	a3,0
    599c:	00000613          	li	a2,0
    59a0:	02000593          	li	a1,32
    59a4:	00106537          	lui	a0,0x106
    59a8:	ef5fb0ef          	jal	189c <fill_rect_cpu>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 92, 238, 28, 12, (uint16_t)SENT);   /* x92..119, y238..249 */
    59ac:	00001837          	lui	a6,0x1
    59b0:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    59b4:	00c00793          	li	a5,12
    59b8:	01c00713          	li	a4,28
    59bc:	0ee00693          	li	a3,238
    59c0:	05c00613          	li	a2,92
    59c4:	78000593          	li	a1,1920
    59c8:	00401537          	lui	a0,0x401
    59cc:	ed1fb0ef          	jal	189c <fill_rect_cpu>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 96, 240, 16, 8, 0xC618u);
    59d0:	0000c837          	lui	a6,0xc
    59d4:	61880813          	addi	a6,a6,1560 # c618 <_end+0x930>
    59d8:	00800793          	li	a5,8
    59dc:	01000713          	li	a4,16
    59e0:	0f000693          	li	a3,240
    59e4:	06000613          	li	a2,96
    59e8:	78000593          	li	a1,1920
    59ec:	00401537          	lui	a0,0x401
    59f0:	eadfb0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    59f4:	f6dfb0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_alpha(SA_ALPHA, PIX(FB1_BASE, FB_STRIDE, 96, 240), 32u, FB_STRIDE,
    59f8:	00000813          	li	a6,0
    59fc:	00800793          	li	a5,8
    5a00:	01000713          	li	a4,16
    5a04:	78000693          	li	a3,1920
    5a08:	02000613          	li	a2,32
    5a0c:	004725b7          	lui	a1,0x472
    5a10:	8c058593          	addi	a1,a1,-1856 # 4718c0 <__freertos_irq_stack_top+0x464bd0>
    5a14:	00106537          	lui	a0,0x106
    5a18:	b4dfc0ef          	jal	2564 <blt_alpha>
    5a1c:	000085b7          	lui	a1,0x8
    5a20:	fa058593          	addi	a1,a1,-96 # 7fa0 <_data+0x104c>
    5a24:	ee4fd0ef          	jal	3108 <op_fail>
    5a28:	0e051063          	bnez	a0,5b08 <td1+0x1c0>
    cache_invalidate();
    5a2c:	f95fb0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    5a30:	f99fb0ef          	jal	19c8 <mis_reset>
    chk_rect(FB1_BASE, FB_STRIDE, 96, 240, 16, 8, exp);
    5a34:	00040813          	mv	a6,s0
    5a38:	00800793          	li	a5,8
    5a3c:	01000713          	li	a4,16
    5a40:	0f000693          	li	a3,240
    5a44:	06000613          	li	a2,96
    5a48:	78000593          	li	a1,1920
    5a4c:	00401537          	lui	a0,0x401
    5a50:	af5fd0ef          	jal	3544 <chk_rect>
    chk_outside(FB1_BASE, FB_STRIDE, 92, 238, 28, 12, 96, 240, 16, 8, SENT);
    5a54:	000017b7          	lui	a5,0x1
    5a58:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    5a5c:	00f12423          	sw	a5,8(sp)
    5a60:	00800793          	li	a5,8
    5a64:	00f12223          	sw	a5,4(sp)
    5a68:	01000793          	li	a5,16
    5a6c:	00f12023          	sw	a5,0(sp)
    5a70:	0f000893          	li	a7,240
    5a74:	06000813          	li	a6,96
    5a78:	00c00793          	li	a5,12
    5a7c:	01c00713          	li	a4,28
    5a80:	0ee00693          	li	a3,238
    5a84:	05c00613          	li	a2,92
    5a88:	78000593          	li	a1,1920
    5a8c:	00401537          	lui	a0,0x401
    5a90:	b8dfd0ef          	jal	361c <chk_outside>
               (int)rd16(PIX(FB1_BASE, FB_STRIDE, 96, 240)), (int)exp,
    5a94:	00472537          	lui	a0,0x472
    5a98:	8c050513          	addi	a0,a0,-1856 # 4718c0 <__freertos_irq_stack_top+0x464bd0>
    5a9c:	dd9fb0ef          	jal	1874 <rd16>
    5aa0:	00050593          	mv	a1,a0
    bsp_printf("      got(0,0)=0x%x exp=0x%x，与原始背景 0xc618 %s\r\n",
    5aa4:	0000c7b7          	lui	a5,0xc
    5aa8:	61878793          	addi	a5,a5,1560 # c618 <_end+0x930>
    5aac:	06f40e63          	beq	s0,a5,5b28 <td1+0x1e0>
    5ab0:	000086b7          	lui	a3,0x8
    5ab4:	f1868693          	addi	a3,a3,-232 # 7f18 <_data+0xfc4>
    5ab8:	00040613          	mv	a2,s0
    5abc:	00008537          	lui	a0,0x8
    5ac0:	fb050513          	addi	a0,a0,-80 # 7fb0 <_data+0x105c>
    5ac4:	9c0fd0ef          	jal	2c84 <bsp_printf>
    item("D1 ALPHA a=0 -> pure bg", g_perf, g_mis);
    5ac8:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    5acc:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    5ad0:	00008537          	lui	a0,0x8
    5ad4:	f3850513          	addi	a0,a0,-200 # 7f38 <_data+0xfe4>
    5ad8:	995fd0ef          	jal	346c <item>
    5adc:	01812403          	lw	s0,24(sp)
    5ae0:	01412483          	lw	s1,20(sp)
}
    5ae4:	01c12083          	lw	ra,28(sp)
    5ae8:	02010113          	addi	sp,sp,32
    5aec:	00008067          	ret
    SKIP_IF_DEAD("D1 ALPHA a=0 -> pure bg");
    5af0:	fff00613          	li	a2,-1
    5af4:	00000593          	li	a1,0
    5af8:	00008537          	lui	a0,0x8
    5afc:	f3850513          	addi	a0,a0,-200 # 7f38 <_data+0xfe4>
    5b00:	96dfd0ef          	jal	346c <item>
    5b04:	fe1ff06f          	j	5ae4 <td1+0x19c>
        item("D1 ALPHA a=0 -> pure bg", 0u, -1);
    5b08:	fff00613          	li	a2,-1
    5b0c:	00000593          	li	a1,0
    5b10:	00008537          	lui	a0,0x8
    5b14:	f3850513          	addi	a0,a0,-200 # 7f38 <_data+0xfe4>
    5b18:	955fd0ef          	jal	346c <item>
        return;
    5b1c:	01812403          	lw	s0,24(sp)
    5b20:	01412483          	lw	s1,20(sp)
    5b24:	fc1ff06f          	j	5ae4 <td1+0x19c>
    bsp_printf("      got(0,0)=0x%x exp=0x%x，与原始背景 0xc618 %s\r\n",
    5b28:	000086b7          	lui	a3,0x8
    5b2c:	f0868693          	addi	a3,a3,-248 # 7f08 <_data+0xfb4>
    5b30:	f89ff06f          	j	5ab8 <td1+0x170>

00005b34 <td2>:
{
    5b34:	fe010113          	addi	sp,sp,-32
    5b38:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("D2 ALPHA a=255 -> pure fg");
    5b3c:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    5b40:	18078863          	beqz	a5,5cd0 <td2+0x19c>
    5b44:	00812c23          	sw	s0,24(sp)
    exp = alpha_ref(0xFD20u, 0x0010u, 255u);
    5b48:	0ff00613          	li	a2,255
    5b4c:	01000593          	li	a1,16
    5b50:	00010537          	lui	a0,0x10
    5b54:	d2050513          	addi	a0,a0,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    5b58:	e9dfb0ef          	jal	19f4 <alpha_ref>
    5b5c:	00050413          	mv	s0,a0
    bsp_printf("  D2: ALPHA α=255 fg=0xfd20 bg=0x0010 -> FB1(96,250)，期望 = 前景 0x%x\r\n", (int)exp);
    5b60:	00050593          	mv	a1,a0
    5b64:	00008537          	lui	a0,0x8
    5b68:	00850513          	addi	a0,a0,8 # 8008 <_data+0x10b4>
    5b6c:	918fd0ef          	jal	2c84 <bsp_printf>
    fill_rect_cpu(SA_ALPHA, 32u, 0, 0, 16, 8, 0xFD20u);
    5b70:	00010837          	lui	a6,0x10
    5b74:	d2080813          	addi	a6,a6,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    5b78:	00800793          	li	a5,8
    5b7c:	01000713          	li	a4,16
    5b80:	00000693          	li	a3,0
    5b84:	00000613          	li	a2,0
    5b88:	02000593          	li	a1,32
    5b8c:	00106537          	lui	a0,0x106
    5b90:	d0dfb0ef          	jal	189c <fill_rect_cpu>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 92, 248, 28, 12, (uint16_t)SENT);
    5b94:	00001837          	lui	a6,0x1
    5b98:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    5b9c:	00c00793          	li	a5,12
    5ba0:	01c00713          	li	a4,28
    5ba4:	0f800693          	li	a3,248
    5ba8:	05c00613          	li	a2,92
    5bac:	78000593          	li	a1,1920
    5bb0:	00401537          	lui	a0,0x401
    5bb4:	ce9fb0ef          	jal	189c <fill_rect_cpu>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 96, 250, 16, 8, 0x0010u);
    5bb8:	01000813          	li	a6,16
    5bbc:	00800793          	li	a5,8
    5bc0:	01000713          	li	a4,16
    5bc4:	0fa00693          	li	a3,250
    5bc8:	06000613          	li	a2,96
    5bcc:	78000593          	li	a1,1920
    5bd0:	00401537          	lui	a0,0x401
    5bd4:	cc9fb0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    5bd8:	d89fb0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_alpha(SA_ALPHA, PIX(FB1_BASE, FB_STRIDE, 96, 250), 32u, FB_STRIDE,
    5bdc:	0ff00813          	li	a6,255
    5be0:	00800793          	li	a5,8
    5be4:	01000713          	li	a4,16
    5be8:	78000693          	li	a3,1920
    5bec:	02000613          	li	a2,32
    5bf0:	004765b7          	lui	a1,0x476
    5bf4:	3c058593          	addi	a1,a1,960 # 4763c0 <__freertos_irq_stack_top+0x4696d0>
    5bf8:	00106537          	lui	a0,0x106
    5bfc:	969fc0ef          	jal	2564 <blt_alpha>
    5c00:	000085b7          	lui	a1,0x8
    5c04:	05858593          	addi	a1,a1,88 # 8058 <_data+0x1104>
    5c08:	d00fd0ef          	jal	3108 <op_fail>
    5c0c:	0c051e63          	bnez	a0,5ce8 <td2+0x1b4>
    cache_invalidate();
    5c10:	db1fb0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    5c14:	db5fb0ef          	jal	19c8 <mis_reset>
    chk_rect(FB1_BASE, FB_STRIDE, 96, 250, 16, 8, exp);
    5c18:	00040813          	mv	a6,s0
    5c1c:	00800793          	li	a5,8
    5c20:	01000713          	li	a4,16
    5c24:	0fa00693          	li	a3,250
    5c28:	06000613          	li	a2,96
    5c2c:	78000593          	li	a1,1920
    5c30:	00401537          	lui	a0,0x401
    5c34:	911fd0ef          	jal	3544 <chk_rect>
    chk_outside(FB1_BASE, FB_STRIDE, 92, 248, 28, 12, 96, 250, 16, 8, SENT);
    5c38:	000017b7          	lui	a5,0x1
    5c3c:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    5c40:	00f12423          	sw	a5,8(sp)
    5c44:	00800793          	li	a5,8
    5c48:	00f12223          	sw	a5,4(sp)
    5c4c:	01000793          	li	a5,16
    5c50:	00f12023          	sw	a5,0(sp)
    5c54:	0fa00893          	li	a7,250
    5c58:	06000813          	li	a6,96
    5c5c:	00c00793          	li	a5,12
    5c60:	01c00713          	li	a4,28
    5c64:	0f800693          	li	a3,248
    5c68:	05c00613          	li	a2,92
    5c6c:	78000593          	li	a1,1920
    5c70:	00401537          	lui	a0,0x401
    5c74:	9a9fd0ef          	jal	361c <chk_outside>
               (int)rd16(PIX(FB1_BASE, FB_STRIDE, 96, 250)), (int)exp,
    5c78:	00476537          	lui	a0,0x476
    5c7c:	3c050513          	addi	a0,a0,960 # 4763c0 <__freertos_irq_stack_top+0x4696d0>
    5c80:	bf5fb0ef          	jal	1874 <rd16>
    5c84:	00050593          	mv	a1,a0
    bsp_printf("      got(0,0)=0x%x exp=0x%x，与原始前景 0xfd20 %s\r\n",
    5c88:	000107b7          	lui	a5,0x10
    5c8c:	d2078793          	addi	a5,a5,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    5c90:	06f40a63          	beq	s0,a5,5d04 <td2+0x1d0>
    5c94:	000086b7          	lui	a3,0x8
    5c98:	f1868693          	addi	a3,a3,-232 # 7f18 <_data+0xfc4>
    5c9c:	00040613          	mv	a2,s0
    5ca0:	00008537          	lui	a0,0x8
    5ca4:	06850513          	addi	a0,a0,104 # 8068 <_data+0x1114>
    5ca8:	fddfc0ef          	jal	2c84 <bsp_printf>
    item("D2 ALPHA a=255 -> pure fg", g_perf, g_mis);
    5cac:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    5cb0:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    5cb4:	00008537          	lui	a0,0x8
    5cb8:	fec50513          	addi	a0,a0,-20 # 7fec <_data+0x1098>
    5cbc:	fb0fd0ef          	jal	346c <item>
    5cc0:	01812403          	lw	s0,24(sp)
}
    5cc4:	01c12083          	lw	ra,28(sp)
    5cc8:	02010113          	addi	sp,sp,32
    5ccc:	00008067          	ret
    SKIP_IF_DEAD("D2 ALPHA a=255 -> pure fg");
    5cd0:	fff00613          	li	a2,-1
    5cd4:	00000593          	li	a1,0
    5cd8:	00008537          	lui	a0,0x8
    5cdc:	fec50513          	addi	a0,a0,-20 # 7fec <_data+0x1098>
    5ce0:	f8cfd0ef          	jal	346c <item>
    5ce4:	fe1ff06f          	j	5cc4 <td2+0x190>
        item("D2 ALPHA a=255 -> pure fg", 0u, -1);
    5ce8:	fff00613          	li	a2,-1
    5cec:	00000593          	li	a1,0
    5cf0:	00008537          	lui	a0,0x8
    5cf4:	fec50513          	addi	a0,a0,-20 # 7fec <_data+0x1098>
    5cf8:	f74fd0ef          	jal	346c <item>
        return;
    5cfc:	01812403          	lw	s0,24(sp)
    5d00:	fc5ff06f          	j	5cc4 <td2+0x190>
    bsp_printf("      got(0,0)=0x%x exp=0x%x，与原始前景 0xfd20 %s\r\n",
    5d04:	000086b7          	lui	a3,0x8
    5d08:	f0868693          	addi	a3,a3,-248 # 7f08 <_data+0xfb4>
    5d0c:	f91ff06f          	j	5c9c <td2+0x168>

00005d10 <td3>:
{
    5d10:	fe010113          	addi	sp,sp,-32
    5d14:	00112e23          	sw	ra,28(sp)
    SKIP_IF_DEAD("D3 ALPHA a=128 white/black -> 0x7BEF");
    5d18:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    5d1c:	16078e63          	beqz	a5,5e98 <td3+0x188>
    bsp_printf("  D3: ALPHA α=128 fg=0xffff(白) bg=0x0000(黑) -> FB1(96,260)，硬件金标准 0x7bef\r\n");
    5d20:	00008537          	lui	a0,0x8
    5d24:	0cc50513          	addi	a0,a0,204 # 80cc <_data+0x1178>
    5d28:	f5dfc0ef          	jal	2c84 <bsp_printf>
    fill_rect_cpu(SA_ALPHA, 32u, 0, 0, 16, 8, 0xFFFFu);
    5d2c:	00010837          	lui	a6,0x10
    5d30:	fff80813          	addi	a6,a6,-1 # ffff <__freertos_irq_stack_top+0x330f>
    5d34:	00800793          	li	a5,8
    5d38:	01000713          	li	a4,16
    5d3c:	00000693          	li	a3,0
    5d40:	00000613          	li	a2,0
    5d44:	02000593          	li	a1,32
    5d48:	00106537          	lui	a0,0x106
    5d4c:	b51fb0ef          	jal	189c <fill_rect_cpu>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 92, 258, 28, 12, (uint16_t)SENT);
    5d50:	00001837          	lui	a6,0x1
    5d54:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    5d58:	00c00793          	li	a5,12
    5d5c:	01c00713          	li	a4,28
    5d60:	10200693          	li	a3,258
    5d64:	05c00613          	li	a2,92
    5d68:	78000593          	li	a1,1920
    5d6c:	00401537          	lui	a0,0x401
    5d70:	b2dfb0ef          	jal	189c <fill_rect_cpu>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 96, 260, 16, 8, 0x0000u);
    5d74:	00000813          	li	a6,0
    5d78:	00800793          	li	a5,8
    5d7c:	01000713          	li	a4,16
    5d80:	10400693          	li	a3,260
    5d84:	06000613          	li	a2,96
    5d88:	78000593          	li	a1,1920
    5d8c:	00401537          	lui	a0,0x401
    5d90:	b0dfb0ef          	jal	189c <fill_rect_cpu>
    cache_evict();
    5d94:	bcdfb0ef          	jal	1960 <cache_evict>
    if (op_fail(blt_alpha(SA_ALPHA, PIX(FB1_BASE, FB_STRIDE, 96, 260), 32u, FB_STRIDE,
    5d98:	08000813          	li	a6,128
    5d9c:	00800793          	li	a5,8
    5da0:	01000713          	li	a4,16
    5da4:	78000693          	li	a3,1920
    5da8:	02000613          	li	a2,32
    5dac:	0047b5b7          	lui	a1,0x47b
    5db0:	ec058593          	addi	a1,a1,-320 # 47aec0 <__freertos_irq_stack_top+0x46e1d0>
    5db4:	00106537          	lui	a0,0x106
    5db8:	facfc0ef          	jal	2564 <blt_alpha>
    5dbc:	000085b7          	lui	a1,0x8
    5dc0:	12858593          	addi	a1,a1,296 # 8128 <_data+0x11d4>
    5dc4:	b44fd0ef          	jal	3108 <op_fail>
    5dc8:	0e051463          	bnez	a0,5eb0 <td3+0x1a0>
    5dcc:	00812c23          	sw	s0,24(sp)
    cache_invalidate();
    5dd0:	bf1fb0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    5dd4:	bf5fb0ef          	jal	19c8 <mis_reset>
    chk_rect(FB1_BASE, FB_STRIDE, 96, 260, 16, 8, 0x7BEFu);
    5dd8:	00008837          	lui	a6,0x8
    5ddc:	bef80813          	addi	a6,a6,-1041 # 7bef <_data+0xc9b>
    5de0:	00800793          	li	a5,8
    5de4:	01000713          	li	a4,16
    5de8:	10400693          	li	a3,260
    5dec:	06000613          	li	a2,96
    5df0:	78000593          	li	a1,1920
    5df4:	00401537          	lui	a0,0x401
    5df8:	f4cfd0ef          	jal	3544 <chk_rect>
    chk_outside(FB1_BASE, FB_STRIDE, 92, 258, 28, 12, 96, 260, 16, 8, SENT);
    5dfc:	000017b7          	lui	a5,0x1
    5e00:	23478793          	addi	a5,a5,564 # 1234 <main+0x130>
    5e04:	00f12423          	sw	a5,8(sp)
    5e08:	00800793          	li	a5,8
    5e0c:	00f12223          	sw	a5,4(sp)
    5e10:	01000793          	li	a5,16
    5e14:	00f12023          	sw	a5,0(sp)
    5e18:	10400893          	li	a7,260
    5e1c:	06000813          	li	a6,96
    5e20:	00c00793          	li	a5,12
    5e24:	01c00713          	li	a4,28
    5e28:	10200693          	li	a3,258
    5e2c:	05c00613          	li	a2,92
    5e30:	78000593          	li	a1,1920
    5e34:	00401537          	lui	a0,0x401
    5e38:	fe4fd0ef          	jal	361c <chk_outside>
               (int)rd16(PIX(FB1_BASE, FB_STRIDE, 96, 260)),
    5e3c:	0047b537          	lui	a0,0x47b
    5e40:	ec050513          	addi	a0,a0,-320 # 47aec0 <__freertos_irq_stack_top+0x46e1d0>
    5e44:	a31fb0ef          	jal	1874 <rd16>
    5e48:	00050413          	mv	s0,a0
               (int)alpha_ref(0xFFFFu, 0x0000u, 128u));
    5e4c:	08000613          	li	a2,128
    5e50:	00000593          	li	a1,0
    5e54:	00010537          	lui	a0,0x10
    5e58:	fff50513          	addi	a0,a0,-1 # ffff <__freertos_irq_stack_top+0x330f>
    5e5c:	b99fb0ef          	jal	19f4 <alpha_ref>
    5e60:	00050613          	mv	a2,a0
    bsp_printf("      got(0,0)=0x%x exp=0x7bef（模型算出 0x%x）\r\n",
    5e64:	00040593          	mv	a1,s0
    5e68:	00008537          	lui	a0,0x8
    5e6c:	13850513          	addi	a0,a0,312 # 8138 <_data+0x11e4>
    5e70:	e15fc0ef          	jal	2c84 <bsp_printf>
    item("D3 ALPHA a=128 white/black -> 0x7BEF", g_perf, g_mis);
    5e74:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    5e78:	8701a583          	lw	a1,-1936(gp) # 9730 <g_perf>
    5e7c:	00008537          	lui	a0,0x8
    5e80:	0a450513          	addi	a0,a0,164 # 80a4 <_data+0x1150>
    5e84:	de8fd0ef          	jal	346c <item>
    5e88:	01812403          	lw	s0,24(sp)
}
    5e8c:	01c12083          	lw	ra,28(sp)
    5e90:	02010113          	addi	sp,sp,32
    5e94:	00008067          	ret
    SKIP_IF_DEAD("D3 ALPHA a=128 white/black -> 0x7BEF");
    5e98:	fff00613          	li	a2,-1
    5e9c:	00000593          	li	a1,0
    5ea0:	00008537          	lui	a0,0x8
    5ea4:	0a450513          	addi	a0,a0,164 # 80a4 <_data+0x1150>
    5ea8:	dc4fd0ef          	jal	346c <item>
    5eac:	fe1ff06f          	j	5e8c <td3+0x17c>
        item("D3 ALPHA a=128 white/black -> 0x7BEF", 0u, -1);
    5eb0:	fff00613          	li	a2,-1
    5eb4:	00000593          	li	a1,0
    5eb8:	00008537          	lui	a0,0x8
    5ebc:	0a450513          	addi	a0,a0,164 # 80a4 <_data+0x1150>
    5ec0:	dacfd0ef          	jal	346c <item>
        return;
    5ec4:	fc9ff06f          	j	5e8c <td3+0x17c>

00005ec8 <td4>:
{
    5ec8:	fa010113          	addi	sp,sp,-96
    5ecc:	04112e23          	sw	ra,92(sp)
    SKIP_IF_DEAD("D4 ALPHA sweep a=32..224 vs model");
    5ed0:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    5ed4:	02078263          	beqz	a5,5ef8 <td4+0x30>
    5ed8:	04812c23          	sw	s0,88(sp)
    5edc:	04912a23          	sw	s1,84(sp)
    5ee0:	05212823          	sw	s2,80(sp)
    bsp_printf("  D4: ALPHA α 扫描 fg=0xfd20(橙) bg=0x0010(深蓝) 1x1 -> FB1(0,200..205)\r\n");
    5ee4:	00008537          	lui	a0,0x8
    5ee8:	19450513          	addi	a0,a0,404 # 8194 <_data+0x1240>
    5eec:	d99fc0ef          	jal	2c84 <bsp_printf>
    for (k = 0; k < 6; k++)
    5ef0:	00000413          	li	s0,0
    5ef4:	03c0006f          	j	5f30 <td4+0x68>
    SKIP_IF_DEAD("D4 ALPHA sweep a=32..224 vs model");
    5ef8:	fff00613          	li	a2,-1
    5efc:	00000593          	li	a1,0
    5f00:	00008537          	lui	a0,0x8
    5f04:	17050513          	addi	a0,a0,368 # 8170 <_data+0x121c>
    5f08:	d64fd0ef          	jal	346c <item>
    5f0c:	3e00006f          	j	62ec <td4+0x424>
        wr16(SA_ALPH4 + (uint32_t)k * 32u, (uint16_t)0xFD20u);            /* strided 1 像素/α */
    5f10:	00008537          	lui	a0,0x8
    5f14:	50050513          	addi	a0,a0,1280 # 8500 <_data+0x15ac>
    5f18:	00a40533          	add	a0,s0,a0
    5f1c:	000105b7          	lui	a1,0x10
    5f20:	d2058593          	addi	a1,a1,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    5f24:	00551513          	slli	a0,a0,0x5
    5f28:	945fb0ef          	jal	186c <wr16>
    for (k = 0; k < 6; k++)
    5f2c:	00140413          	addi	s0,s0,1
    5f30:	00500793          	li	a5,5
    5f34:	fc87dee3          	bge	a5,s0,5f10 <td4+0x48>
    fill_rect_cpu(FB1_BASE, FB_STRIDE, 0, 199, 8, 8, (uint16_t)SENT);     /* x0..7, y199..206 */
    5f38:	00001837          	lui	a6,0x1
    5f3c:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    5f40:	00800793          	li	a5,8
    5f44:	00800713          	li	a4,8
    5f48:	0c700693          	li	a3,199
    5f4c:	00000613          	li	a2,0
    5f50:	78000593          	li	a1,1920
    5f54:	00401537          	lui	a0,0x401
    5f58:	945fb0ef          	jal	189c <fill_rect_cpu>
    for (k = 0; k < 6; k++)
    5f5c:	00000413          	li	s0,0
    5f60:	0280006f          	j	5f88 <td4+0xc0>
        wr16(PIX(FB1_BASE, FB_STRIDE, 0, 200 + k), 0x0010u);              /* 目的背景 */
    5f64:	0c840713          	addi	a4,s0,200
    5f68:	00471793          	slli	a5,a4,0x4
    5f6c:	40e787b3          	sub	a5,a5,a4
    5f70:	00779793          	slli	a5,a5,0x7
    5f74:	01000593          	li	a1,16
    5f78:	00401537          	lui	a0,0x401
    5f7c:	00a78533          	add	a0,a5,a0
    5f80:	8edfb0ef          	jal	186c <wr16>
    for (k = 0; k < 6; k++)
    5f84:	00140413          	addi	s0,s0,1
    5f88:	00500793          	li	a5,5
    5f8c:	fc87dce3          	bge	a5,s0,5f64 <td4+0x9c>
    cache_evict();
    5f90:	9d1fb0ef          	jal	1960 <cache_evict>
    for (k = 0; k < 6; k++) {
    5f94:	00000413          	li	s0,0
    uint32_t exp[6], gotv[6], psum = 0;
    5f98:	00000493          	li	s1,0
    for (k = 0; k < 6; k++) {
    5f9c:	00500793          	li	a5,5
    5fa0:	0c87c063          	blt	a5,s0,6060 <td4+0x198>
        if (op_fail(blt_alpha(SA_ALPH4 + (uint32_t)k * 32u,
    5fa4:	00008537          	lui	a0,0x8
    5fa8:	50050513          	addi	a0,a0,1280 # 8500 <_data+0x15ac>
    5fac:	00a40533          	add	a0,s0,a0
                              PIX(FB1_BASE, FB_STRIDE, 0, 200 + k),
    5fb0:	0c840793          	addi	a5,s0,200
    5fb4:	00479593          	slli	a1,a5,0x4
    5fb8:	40f585b3          	sub	a1,a1,a5
    5fbc:	00759593          	slli	a1,a1,0x7
                              32u, FB_STRIDE, 1u, 1u, av[k]), "D4 ALPHA sweep")) {
    5fc0:	000097b7          	lui	a5,0x9
    5fc4:	00241713          	slli	a4,s0,0x2
    5fc8:	60478793          	addi	a5,a5,1540 # 9604 <av.1>
    5fcc:	00e787b3          	add	a5,a5,a4
    5fd0:	0007a903          	lw	s2,0(a5)
        if (op_fail(blt_alpha(SA_ALPH4 + (uint32_t)k * 32u,
    5fd4:	00090813          	mv	a6,s2
    5fd8:	00100793          	li	a5,1
    5fdc:	00100713          	li	a4,1
    5fe0:	78000693          	li	a3,1920
    5fe4:	02000613          	li	a2,32
    5fe8:	004018b7          	lui	a7,0x401
    5fec:	011585b3          	add	a1,a1,a7
    5ff0:	00551513          	slli	a0,a0,0x5
    5ff4:	d70fc0ef          	jal	2564 <blt_alpha>
    5ff8:	000085b7          	lui	a1,0x8
    5ffc:	1e458593          	addi	a1,a1,484 # 81e4 <_data+0x1290>
    6000:	908fd0ef          	jal	3108 <op_fail>
    6004:	02051c63          	bnez	a0,603c <td4+0x174>
        psum += g_perf;
    6008:	8701a783          	lw	a5,-1936(gp) # 9730 <g_perf>
    600c:	00f484b3          	add	s1,s1,a5
        exp[k] = alpha_ref(0xFD20u, 0x0010u, av[k]);
    6010:	00090613          	mv	a2,s2
    6014:	01000593          	li	a1,16
    6018:	00010537          	lui	a0,0x10
    601c:	d2050513          	addi	a0,a0,-736 # fd20 <__freertos_irq_stack_top+0x3030>
    6020:	9d5fb0ef          	jal	19f4 <alpha_ref>
    6024:	00241793          	slli	a5,s0,0x2
    6028:	03078793          	addi	a5,a5,48
    602c:	002787b3          	add	a5,a5,sp
    6030:	fea7a423          	sw	a0,-24(a5)
    for (k = 0; k < 6; k++) {
    6034:	00140413          	addi	s0,s0,1
    6038:	f65ff06f          	j	5f9c <td4+0xd4>
            item("D4 ALPHA sweep a=32..224 vs model", psum, -1);
    603c:	fff00613          	li	a2,-1
    6040:	00048593          	mv	a1,s1
    6044:	00008537          	lui	a0,0x8
    6048:	17050513          	addi	a0,a0,368 # 8170 <_data+0x121c>
    604c:	c20fd0ef          	jal	346c <item>
            return;
    6050:	05812403          	lw	s0,88(sp)
    6054:	05412483          	lw	s1,84(sp)
    6058:	05012903          	lw	s2,80(sp)
    605c:	2900006f          	j	62ec <td4+0x424>
    6060:	05312623          	sw	s3,76(sp)
    6064:	05412423          	sw	s4,72(sp)
    6068:	05512223          	sw	s5,68(sp)
    606c:	05612023          	sw	s6,64(sp)
    6070:	03712e23          	sw	s7,60(sp)
    cache_invalidate();
    6074:	94dfb0ef          	jal	19c0 <cache_invalidate>
    mis_reset();
    6078:	951fb0ef          	jal	19c8 <mis_reset>
    for (k = 0; k < 6; k++) {
    607c:	00000413          	li	s0,0
    6080:	0540006f          	j	60d4 <td4+0x20c>
        gotv[k] = rd16(PIX(FB1_BASE, FB_STRIDE, 0, 200 + k));
    6084:	0c840913          	addi	s2,s0,200
    6088:	00491793          	slli	a5,s2,0x4
    608c:	412787b3          	sub	a5,a5,s2
    6090:	00779793          	slli	a5,a5,0x7
    6094:	00401537          	lui	a0,0x401
    6098:	00a78533          	add	a0,a5,a0
    609c:	fd8fb0ef          	jal	1874 <rd16>
    60a0:	00050613          	mv	a2,a0
    60a4:	00241693          	slli	a3,s0,0x2
    60a8:	03068793          	addi	a5,a3,48
    60ac:	00278733          	add	a4,a5,sp
    60b0:	fca72823          	sw	a0,-48(a4) # 2fd0 <blt_print_scene+0x21c>
        expect_px((int)av[k], 200 + k, gotv[k], exp[k]);
    60b4:	000097b7          	lui	a5,0x9
    60b8:	60478793          	addi	a5,a5,1540 # 9604 <av.1>
    60bc:	00d787b3          	add	a5,a5,a3
    60c0:	fe872683          	lw	a3,-24(a4)
    60c4:	00090593          	mv	a1,s2
    60c8:	0007a503          	lw	a0,0(a5)
    60cc:	c20fd0ef          	jal	34ec <expect_px>
    for (k = 0; k < 6; k++) {
    60d0:	00140413          	addi	s0,s0,1
    60d4:	00500793          	li	a5,5
    60d8:	fa87d6e3          	bge	a5,s0,6084 <td4+0x1bc>
    chk_rect(FB1_BASE, FB_STRIDE, 1, 199, 7, 8, SENT);
    60dc:	00001837          	lui	a6,0x1
    60e0:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    60e4:	00800793          	li	a5,8
    60e8:	00700713          	li	a4,7
    60ec:	0c700693          	li	a3,199
    60f0:	00100613          	li	a2,1
    60f4:	78000593          	li	a1,1920
    60f8:	00401537          	lui	a0,0x401
    60fc:	c48fd0ef          	jal	3544 <chk_rect>
    chk_rect(FB1_BASE, FB_STRIDE, 0, 199, 1, 1, SENT);
    6100:	00001837          	lui	a6,0x1
    6104:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    6108:	00100793          	li	a5,1
    610c:	00100713          	li	a4,1
    6110:	0c700693          	li	a3,199
    6114:	00000613          	li	a2,0
    6118:	78000593          	li	a1,1920
    611c:	00401537          	lui	a0,0x401
    6120:	c24fd0ef          	jal	3544 <chk_rect>
    chk_rect(FB1_BASE, FB_STRIDE, 0, 206, 1, 1, SENT);
    6124:	00001837          	lui	a6,0x1
    6128:	23480813          	addi	a6,a6,564 # 1234 <main+0x130>
    612c:	00100793          	li	a5,1
    6130:	00100713          	li	a4,1
    6134:	0ce00693          	li	a3,206
    6138:	00000613          	li	a2,0
    613c:	78000593          	li	a1,1920
    6140:	00401537          	lui	a0,0x401
    6144:	c00fd0ef          	jal	3544 <chk_rect>
    int k, mono_ok = 1;
    6148:	00100913          	li	s2,1
    for (k = 1; k < 6; k++) {
    614c:	00100413          	li	s0,1
    6150:	0080006f          	j	6158 <td4+0x290>
    6154:	00140413          	addi	s0,s0,1
    6158:	00500793          	li	a5,5
    615c:	0887c063          	blt	a5,s0,61dc <td4+0x314>
        if (ch_r(gotv[k]) < ch_r(gotv[k - 1])) mono_ok = 0;
    6160:	00241793          	slli	a5,s0,0x2
    6164:	03078793          	addi	a5,a5,48
    6168:	002787b3          	add	a5,a5,sp
    616c:	fd07a983          	lw	s3,-48(a5)
    6170:	00098513          	mv	a0,s3
    6174:	97dfb0ef          	jal	1af0 <ch_r>
    6178:	00050a93          	mv	s5,a0
    617c:	fff40793          	addi	a5,s0,-1
    6180:	00279793          	slli	a5,a5,0x2
    6184:	03078793          	addi	a5,a5,48
    6188:	002787b3          	add	a5,a5,sp
    618c:	fd07aa03          	lw	s4,-48(a5)
    6190:	000a0513          	mv	a0,s4
    6194:	95dfb0ef          	jal	1af0 <ch_r>
    6198:	00aaf463          	bgeu	s5,a0,61a0 <td4+0x2d8>
    619c:	00000913          	li	s2,0
        if (ch_g(gotv[k]) < ch_g(gotv[k - 1])) mono_ok = 0;
    61a0:	00098513          	mv	a0,s3
    61a4:	959fb0ef          	jal	1afc <ch_g>
    61a8:	00050a93          	mv	s5,a0
    61ac:	000a0513          	mv	a0,s4
    61b0:	94dfb0ef          	jal	1afc <ch_g>
    61b4:	00aaf463          	bgeu	s5,a0,61bc <td4+0x2f4>
    61b8:	00000913          	li	s2,0
        if (ch_b(gotv[k]) > ch_b(gotv[k - 1])) mono_ok = 0;
    61bc:	00098513          	mv	a0,s3
    61c0:	949fb0ef          	jal	1b08 <ch_b>
    61c4:	00050993          	mv	s3,a0
    61c8:	000a0513          	mv	a0,s4
    61cc:	93dfb0ef          	jal	1b08 <ch_b>
    61d0:	f93572e3          	bgeu	a0,s3,6154 <td4+0x28c>
    61d4:	00000913          	li	s2,0
    61d8:	f7dff06f          	j	6154 <td4+0x28c>
    bsp_printf("      ");
    61dc:	00008537          	lui	a0,0x8
    61e0:	1f450513          	addi	a0,a0,500 # 81f4 <_data+0x12a0>
    61e4:	aa1fc0ef          	jal	2c84 <bsp_printf>
    for (k = 0; k < 6; k++)
    61e8:	00000413          	li	s0,0
    61ec:	0380006f          	j	6224 <td4+0x35c>
        bsp_printf("a=%d exp=0x%x got=0x%x  ", (int)av[k], (int)exp[k], (int)gotv[k]);
    61f0:	000097b7          	lui	a5,0x9
    61f4:	00241713          	slli	a4,s0,0x2
    61f8:	60478793          	addi	a5,a5,1540 # 9604 <av.1>
    61fc:	00e787b3          	add	a5,a5,a4
    6200:	03070713          	addi	a4,a4,48
    6204:	00270733          	add	a4,a4,sp
    6208:	fd072683          	lw	a3,-48(a4)
    620c:	fe872603          	lw	a2,-24(a4)
    6210:	0007a583          	lw	a1,0(a5)
    6214:	00008537          	lui	a0,0x8
    6218:	1fc50513          	addi	a0,a0,508 # 81fc <_data+0x12a8>
    621c:	a69fc0ef          	jal	2c84 <bsp_printf>
    for (k = 0; k < 6; k++)
    6220:	00140413          	addi	s0,s0,1
    6224:	00500793          	li	a5,5
    6228:	fc87d4e3          	bge	a5,s0,61f0 <td4+0x328>
               (int)ch_r(gotv[0]), (int)ch_r(gotv[5]),
    622c:	00012b03          	lw	s6,0(sp)
    6230:	000b0513          	mv	a0,s6
    6234:	8bdfb0ef          	jal	1af0 <ch_r>
    6238:	00050413          	mv	s0,a0
    623c:	01412b83          	lw	s7,20(sp)
    6240:	000b8513          	mv	a0,s7
    6244:	8adfb0ef          	jal	1af0 <ch_r>
    6248:	00050993          	mv	s3,a0
               (int)ch_g(gotv[0]), (int)ch_g(gotv[5]),
    624c:	000b0513          	mv	a0,s6
    6250:	8adfb0ef          	jal	1afc <ch_g>
    6254:	00050a13          	mv	s4,a0
    6258:	000b8513          	mv	a0,s7
    625c:	8a1fb0ef          	jal	1afc <ch_g>
    6260:	00050a93          	mv	s5,a0
               (int)ch_b(gotv[0]), (int)ch_b(gotv[5]),
    6264:	000b0513          	mv	a0,s6
    6268:	8a1fb0ef          	jal	1b08 <ch_b>
    626c:	00050b13          	mv	s6,a0
    6270:	000b8513          	mv	a0,s7
    6274:	895fb0ef          	jal	1b08 <ch_b>
    6278:	00050813          	mv	a6,a0
    bsp_printf("\r\n      R 通道 %d..%d（↑）G %d..%d（↑）B %d..%d（↓）单调=%s\r\n",
    627c:	06090e63          	beqz	s2,62f8 <td4+0x430>
    6280:	000078b7          	lui	a7,0x7
    6284:	50c88893          	addi	a7,a7,1292 # 750c <_data+0x5b8>
    6288:	000b0793          	mv	a5,s6
    628c:	000a8713          	mv	a4,s5
    6290:	000a0693          	mv	a3,s4
    6294:	00098613          	mv	a2,s3
    6298:	00040593          	mv	a1,s0
    629c:	00008537          	lui	a0,0x8
    62a0:	21850513          	addi	a0,a0,536 # 8218 <_data+0x12c4>
    62a4:	9e1fc0ef          	jal	2c84 <bsp_printf>
    if (!mono_ok) g_mis++;
    62a8:	00091863          	bnez	s2,62b8 <td4+0x3f0>
    62ac:	87c1a783          	lw	a5,-1924(gp) # 973c <g_mis>
    62b0:	00178793          	addi	a5,a5,1
    62b4:	86f1ae23          	sw	a5,-1924(gp) # 973c <g_mis>
    item("D4 ALPHA sweep a=32..224 vs model", psum, g_mis);
    62b8:	87c1a603          	lw	a2,-1924(gp) # 973c <g_mis>
    62bc:	00048593          	mv	a1,s1
    62c0:	00008537          	lui	a0,0x8
    62c4:	17050513          	addi	a0,a0,368 # 8170 <_data+0x121c>
    62c8:	9a4fd0ef          	jal	346c <item>
    62cc:	05812403          	lw	s0,88(sp)
    62d0:	05412483          	lw	s1,84(sp)
    62d4:	05012903          	lw	s2,80(sp)
    62d8:	04c12983          	lw	s3,76(sp)
    62dc:	04812a03          	lw	s4,72(sp)
    62e0:	04412a83          	lw	s5,68(sp)
    62e4:	04012b03          	lw	s6,64(sp)
    62e8:	03c12b83          	lw	s7,60(sp)
}
    62ec:	05c12083          	lw	ra,92(sp)
    62f0:	06010113          	addi	sp,sp,96
    62f4:	00008067          	ret
    bsp_printf("\r\n      R 通道 %d..%d（↑）G %d..%d（↑）B %d..%d（↓）单调=%s\r\n",
    62f8:	000078b7          	lui	a7,0x7
    62fc:	50488893          	addi	a7,a7,1284 # 7504 <_data+0x5b0>
    6300:	f89ff06f          	j	6288 <td4+0x3c0>

00006304 <run_group_abcd>:
{
    6304:	ff010113          	addi	sp,sp,-16
    6308:	00112623          	sw	ra,12(sp)
    bsp_printf("\r\n---------- [6a] A. FILL 边界测试 ----------\r\n");
    630c:	00008537          	lui	a0,0x8
    6310:	26850513          	addi	a0,a0,616 # 8268 <_data+0x1314>
    6314:	971fc0ef          	jal	2c84 <bsp_printf>
    tf_a1(); tf_a2(); tf_a4(); tf_a3();
    6318:	811fd0ef          	jal	3b28 <tf_a1>
    631c:	93dfd0ef          	jal	3c58 <tf_a2>
    6320:	a65fd0ef          	jal	3d84 <tf_a4>
    6324:	c8dfd0ef          	jal	3fb0 <tf_a3>
    bsp_printf("\r\n---------- [6b] B. COPY 边界测试 ----------\r\n");
    6328:	00008537          	lui	a0,0x8
    632c:	29c50513          	addi	a0,a0,668 # 829c <_data+0x1348>
    6330:	955fc0ef          	jal	2c84 <bsp_printf>
    tb1(); tb2(); tb3(); tb5(); tb4();      /* B4 整屏会清掉 FB1，排在最后 */
    6334:	e99fd0ef          	jal	41cc <tb1>
    6338:	848fe0ef          	jal	4380 <tb2>
    633c:	9fcfe0ef          	jal	4538 <tb3>
    6340:	ba0fe0ef          	jal	46e0 <tb5>
    6344:	d58fe0ef          	jal	489c <tb4>
    bsp_printf("\r\n---------- [6c] C. KEY 边界测试 ----------\r\n");
    6348:	00008537          	lui	a0,0x8
    634c:	2d050513          	addi	a0,a0,720 # 82d0 <_data+0x137c>
    6350:	935fc0ef          	jal	2c84 <bsp_printf>
    tc1(); tc2(); tc3(); tc4();
    6354:	a51fe0ef          	jal	4da4 <tc1>
    6358:	cf9fe0ef          	jal	5050 <tc2>
    635c:	f05fe0ef          	jal	5260 <tc3>
    6360:	ae8ff0ef          	jal	5648 <tc4>
    bsp_printf("\r\n---------- [6d] D. ALPHA 边界测试 ----------\r\n");
    6364:	00008537          	lui	a0,0x8
    6368:	30450513          	addi	a0,a0,772 # 8304 <_data+0x13b0>
    636c:	919fc0ef          	jal	2c84 <bsp_printf>
    td1(); td2(); td3(); td4();
    6370:	dd8ff0ef          	jal	5948 <td1>
    6374:	fc0ff0ef          	jal	5b34 <td2>
    6378:	999ff0ef          	jal	5d10 <td3>
    637c:	b4dff0ef          	jal	5ec8 <td4>
}
    6380:	00c12083          	lw	ra,12(sp)
    6384:	01010113          	addi	sp,sp,16
    6388:	00008067          	ret

0000638c <stress_setup>:
{
    638c:	fe010113          	addi	sp,sp,-32
    6390:	00112e23          	sw	ra,28(sp)
    6394:	00812c23          	sw	s0,24(sp)
    6398:	00912a23          	sw	s1,20(sp)
    639c:	01212823          	sw	s2,16(sp)
    63a0:	01312623          	sw	s3,12(sp)
    63a4:	01412423          	sw	s4,8(sp)
    63a8:	01512223          	sw	s5,4(sp)
    for (s = 0; s < STRESS_NSLOT; s++) {
    63ac:	00000a93          	li	s5,0
    63b0:	0b40006f          	j	6464 <stress_setup+0xd8>
                else if (x >= 4 && x < 12 && y >= 4 && y < 12)
    63b4:	00300793          	li	a5,3
    63b8:	0497de63          	bge	a5,s1,6414 <stress_setup+0x88>
    63bc:	00b00793          	li	a5,11
    63c0:	0497ca63          	blt	a5,s1,6414 <stress_setup+0x88>
                    c = (uint16_t)C_BLACK;                           /* 方向标记 */
    63c4:	00000593          	li	a1,0
    63c8:	00c0006f          	j	63d4 <stress_setup+0x48>
                    c = (uint16_t)KEY_COLOR;                         /* 四周一圈键色 */
    63cc:	000105b7          	lui	a1,0x10
    63d0:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
                wr16(base + (uint32_t)y * ATLAS_STRIDE + (uint32_t)x * 2u, c);
    63d4:	00549513          	slli	a0,s1,0x5
    63d8:	00850533          	add	a0,a0,s0
    63dc:	00151513          	slli	a0,a0,0x1
    63e0:	01350533          	add	a0,a0,s3
    63e4:	c88fb0ef          	jal	186c <wr16>
            for (x = 0; x < w; x++) {
    63e8:	00140413          	addi	s0,s0,1
    63ec:	07245263          	bge	s0,s2,6450 <stress_setup+0xc4>
                if (x == 0 || y == 0 || x == w - 1 || y == h - 1)
    63f0:	fc040ee3          	beqz	s0,63cc <stress_setup+0x40>
    63f4:	02048c63          	beqz	s1,642c <stress_setup+0xa0>
    63f8:	fff90793          	addi	a5,s2,-1
    63fc:	02878e63          	beq	a5,s0,6438 <stress_setup+0xac>
    6400:	fffa0793          	addi	a5,s4,-1
    6404:	04978063          	beq	a5,s1,6444 <stress_setup+0xb8>
                else if (x >= 4 && x < 12 && y >= 4 && y < 12)
    6408:	ffc40793          	addi	a5,s0,-4
    640c:	00700713          	li	a4,7
    6410:	faf772e3          	bgeu	a4,a5,63b4 <stress_setup+0x28>
                    c = s_sprc[s];
    6414:	000097b7          	lui	a5,0x9
    6418:	001a9713          	slli	a4,s5,0x1
    641c:	69c78793          	addi	a5,a5,1692 # 969c <s_sprc>
    6420:	00e787b3          	add	a5,a5,a4
    6424:	0007d583          	lhu	a1,0(a5)
    6428:	fadff06f          	j	63d4 <stress_setup+0x48>
                    c = (uint16_t)KEY_COLOR;                         /* 四周一圈键色 */
    642c:	000105b7          	lui	a1,0x10
    6430:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    6434:	fa1ff06f          	j	63d4 <stress_setup+0x48>
    6438:	000105b7          	lui	a1,0x10
    643c:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    6440:	f95ff06f          	j	63d4 <stress_setup+0x48>
    6444:	000105b7          	lui	a1,0x10
    6448:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    644c:	f89ff06f          	j	63d4 <stress_setup+0x48>
        for (y = 0; y < h; y++) {
    6450:	00148493          	addi	s1,s1,1
    6454:	0144d663          	bge	s1,s4,6460 <stress_setup+0xd4>
            for (x = 0; x < w; x++) {
    6458:	00000413          	li	s0,0
    645c:	f91ff06f          	j	63ec <stress_setup+0x60>
    for (s = 0; s < STRESS_NSLOT; s++) {
    6460:	001a8a93          	addi	s5,s5,1
    6464:	00700793          	li	a5,7
    6468:	0357cc63          	blt	a5,s5,64a0 <stress_setup+0x114>
        uint32_t base = SA_ATLAS + (uint32_t)s * ATLAS_SLOT;
    646c:	222a8993          	addi	s3,s5,546
    6470:	00b99993          	slli	s3,s3,0xb
        int w = (int)s_sprw[s], h = (int)s_sprh[s];
    6474:	000097b7          	lui	a5,0x9
    6478:	001a9713          	slli	a4,s5,0x1
    647c:	6bc78793          	addi	a5,a5,1724 # 96bc <s_sprw>
    6480:	00e787b3          	add	a5,a5,a4
    6484:	0007d903          	lhu	s2,0(a5)
    6488:	000097b7          	lui	a5,0x9
    648c:	6ac78793          	addi	a5,a5,1708 # 96ac <s_sprh>
    6490:	00e787b3          	add	a5,a5,a4
    6494:	0007da03          	lhu	s4,0(a5)
        for (y = 0; y < h; y++) {
    6498:	00000493          	li	s1,0
    649c:	fb9ff06f          	j	6454 <stress_setup+0xc8>
    cache_evict();          /* CPU 写 -> 引擎读：必须挤出 D$ */
    64a0:	cc0fb0ef          	jal	1960 <cache_evict>
    cache_invalidate();     /* 再从 DDR 回读验证 */
    64a4:	d1cfb0ef          	jal	19c0 <cache_invalidate>
    int s, x, y, bad = 0;
    64a8:	00000993          	li	s3,0
    for (s = 0; s < STRESS_NSLOT; s++) {
    64ac:	00000493          	li	s1,0
    64b0:	0080006f          	j	64b8 <stress_setup+0x12c>
    64b4:	00148493          	addi	s1,s1,1
    64b8:	00700793          	li	a5,7
    64bc:	0897ce63          	blt	a5,s1,6558 <stress_setup+0x1cc>
        uint32_t base = SA_ATLAS + (uint32_t)s * ATLAS_SLOT;
    64c0:	22248913          	addi	s2,s1,546
    64c4:	00b91913          	slli	s2,s2,0xb
        int w = (int)s_sprw[s], h = (int)s_sprh[s];
    64c8:	000097b7          	lui	a5,0x9
    64cc:	00149713          	slli	a4,s1,0x1
    64d0:	6bc78793          	addi	a5,a5,1724 # 96bc <s_sprw>
    64d4:	00e787b3          	add	a5,a5,a4
    64d8:	0007da03          	lhu	s4,0(a5)
    64dc:	000097b7          	lui	a5,0x9
    64e0:	6ac78793          	addi	a5,a5,1708 # 96ac <s_sprh>
    64e4:	00e787b3          	add	a5,a5,a4
    64e8:	0007d403          	lhu	s0,0(a5)
        if (rd16(base) != (uint16_t)KEY_COLOR) bad++;
    64ec:	00090513          	mv	a0,s2
    64f0:	b84fb0ef          	jal	1874 <rd16>
    64f4:	000107b7          	lui	a5,0x10
    64f8:	81f78793          	addi	a5,a5,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    64fc:	00f50463          	beq	a0,a5,6504 <stress_setup+0x178>
    6500:	00198993          	addi	s3,s3,1
        if (rd16(base + (uint32_t)(w - 1) * 2u + (uint32_t)(h - 1) * ATLAS_STRIDE)
    6504:	fff40513          	addi	a0,s0,-1
    6508:	00551513          	slli	a0,a0,0x5
    650c:	01450533          	add	a0,a0,s4
    6510:	fff50513          	addi	a0,a0,-1
    6514:	00151513          	slli	a0,a0,0x1
    6518:	01250533          	add	a0,a0,s2
    651c:	b58fb0ef          	jal	1874 <rd16>
    6520:	000107b7          	lui	a5,0x10
    6524:	81f78793          	addi	a5,a5,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    6528:	00f50463          	beq	a0,a5,6530 <stress_setup+0x1a4>
            != (uint16_t)KEY_COLOR) bad++;
    652c:	00198993          	addi	s3,s3,1
        if (rd16(base + 12u * 2u + 12u * ATLAS_STRIDE) != (uint16_t)s_sprc[s]) bad++;
    6530:	31890513          	addi	a0,s2,792
    6534:	b40fb0ef          	jal	1874 <rd16>
    6538:	000097b7          	lui	a5,0x9
    653c:	00149713          	slli	a4,s1,0x1
    6540:	69c78793          	addi	a5,a5,1692 # 969c <s_sprc>
    6544:	00e787b3          	add	a5,a5,a4
    6548:	0007d783          	lhu	a5,0(a5)
    654c:	f6f504e3          	beq	a0,a5,64b4 <stress_setup+0x128>
    6550:	00198993          	addi	s3,s3,1
    6554:	f61ff06f          	j	64b4 <stress_setup+0x128>
    bsp_printf("      [7] 图集 8 张（4x32x32 + 4x16x16，键色边框 0x%x）@0x%x stride=%d，DDR 回读自检 %s\r\n",
    6558:	06098063          	beqz	s3,65b8 <stress_setup+0x22c>
    655c:	00007737          	lui	a4,0x7
    6560:	50470713          	addi	a4,a4,1284 # 7504 <_data+0x5b0>
    6564:	04000693          	li	a3,64
    6568:	00111637          	lui	a2,0x111
    656c:	000105b7          	lui	a1,0x10
    6570:	81f58593          	addi	a1,a1,-2017 # f81f <__freertos_irq_stack_top+0x2b2f>
    6574:	00008537          	lui	a0,0x8
    6578:	33c50513          	addi	a0,a0,828 # 833c <_data+0x13e8>
    657c:	f08fc0ef          	jal	2c84 <bsp_printf>
    if (bad) g_fail++;
    6580:	00098863          	beqz	s3,6590 <stress_setup+0x204>
    6584:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    6588:	00178793          	addi	a5,a5,1
    658c:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>
}
    6590:	00098513          	mv	a0,s3
    6594:	01c12083          	lw	ra,28(sp)
    6598:	01812403          	lw	s0,24(sp)
    659c:	01412483          	lw	s1,20(sp)
    65a0:	01012903          	lw	s2,16(sp)
    65a4:	00c12983          	lw	s3,12(sp)
    65a8:	00812a03          	lw	s4,8(sp)
    65ac:	00412a83          	lw	s5,4(sp)
    65b0:	02010113          	addi	sp,sp,32
    65b4:	00008067          	ret
    bsp_printf("      [7] 图集 8 张（4x32x32 + 4x16x16，键色边框 0x%x）@0x%x stride=%d，DDR 回读自检 %s\r\n",
    65b8:	00007737          	lui	a4,0x7
    65bc:	50c70713          	addi	a4,a4,1292 # 750c <_data+0x5b8>
    65c0:	fa5ff06f          	j	6564 <stress_setup+0x1d8>

000065c4 <pnum>:
{
    65c4:	ff010113          	addi	sp,sp,-16
    65c8:	00112623          	sw	ra,12(sp)
    65cc:	00812423          	sw	s0,8(sp)
    65d0:	00912223          	sw	s1,4(sp)
    65d4:	01212023          	sw	s2,0(sp)
    65d8:	00050493          	mv	s1,a0
    65dc:	00058913          	mv	s2,a1
    int n = ndig(v);
    65e0:	e70fc0ef          	jal	2c50 <ndig>
    65e4:	00050413          	mv	s0,a0
    bsp_printf("%d", v);
    65e8:	00048593          	mv	a1,s1
    65ec:	00008537          	lui	a0,0x8
    65f0:	3a850513          	addi	a0,a0,936 # 83a8 <_data+0x1454>
    65f4:	e90fc0ef          	jal	2c84 <bsp_printf>
    while (n++ < w) bsp_printf(" ");
    65f8:	0140006f          	j	660c <pnum+0x48>
    65fc:	00008537          	lui	a0,0x8
    6600:	3ac50513          	addi	a0,a0,940 # 83ac <_data+0x1458>
    6604:	e80fc0ef          	jal	2c84 <bsp_printf>
    6608:	00048413          	mv	s0,s1
    660c:	00140493          	addi	s1,s0,1
    6610:	ff2446e3          	blt	s0,s2,65fc <pnum+0x38>
}
    6614:	00c12083          	lw	ra,12(sp)
    6618:	00812403          	lw	s0,8(sp)
    661c:	00412483          	lw	s1,4(sp)
    6620:	00012903          	lw	s2,0(sp)
    6624:	01010113          	addi	sp,sp,16
    6628:	00008067          	ret

0000662c <ppct>:
{
    662c:	fe010113          	addi	sp,sp,-32
    6630:	00112e23          	sw	ra,28(sp)
    6634:	00812c23          	sw	s0,24(sp)
    6638:	00912a23          	sw	s1,20(sp)
    663c:	01212823          	sw	s2,16(sp)
    6640:	01312623          	sw	s3,12(sp)
    6644:	01412423          	sw	s4,8(sp)
    6648:	00058493          	mv	s1,a1
    664c:	00060913          	mv	s2,a2
    uint32_t pm = whole ? (part * 1000u) / whole : 0u;    /* 千分比 */
    6650:	00058863          	beqz	a1,6660 <ppct+0x34>
    6654:	3e800793          	li	a5,1000
    6658:	02f50533          	mul	a0,a0,a5
    665c:	02b554b3          	divu	s1,a0,a1
    int n = ndig((int)(pm / 10u)) + 3;                    /* 整数位 + '.' + 1 位 + '%' */
    6660:	00a00a13          	li	s4,10
    6664:	0344d9b3          	divu	s3,s1,s4
    6668:	00098513          	mv	a0,s3
    666c:	de4fc0ef          	jal	2c50 <ndig>
    6670:	00350413          	addi	s0,a0,3
    bsp_printf("%d.%d%%", (int)(pm / 10u), (int)(pm % 10u));
    6674:	0344f633          	remu	a2,s1,s4
    6678:	00098593          	mv	a1,s3
    667c:	00008537          	lui	a0,0x8
    6680:	3b050513          	addi	a0,a0,944 # 83b0 <_data+0x145c>
    6684:	e00fc0ef          	jal	2c84 <bsp_printf>
    while (n++ < w) bsp_printf(" ");
    6688:	0140006f          	j	669c <ppct+0x70>
    668c:	00008537          	lui	a0,0x8
    6690:	3ac50513          	addi	a0,a0,940 # 83ac <_data+0x1458>
    6694:	df0fc0ef          	jal	2c84 <bsp_printf>
    6698:	00048413          	mv	s0,s1
    669c:	00140493          	addi	s1,s0,1
    66a0:	ff2446e3          	blt	s0,s2,668c <ppct+0x60>
}
    66a4:	01c12083          	lw	ra,28(sp)
    66a8:	01812403          	lw	s0,24(sp)
    66ac:	01412483          	lw	s1,20(sp)
    66b0:	01012903          	lw	s2,16(sp)
    66b4:	00c12983          	lw	s3,12(sp)
    66b8:	00812a03          	lw	s4,8(sp)
    66bc:	02010113          	addi	sp,sp,32
    66c0:	00008067          	ret

000066c4 <stress_all>:
{
    66c4:	ea010113          	addi	sp,sp,-352
    66c8:	14112e23          	sw	ra,348(sp)
    66cc:	14812c23          	sw	s0,344(sp)
    66d0:	14912a23          	sw	s1,340(sp)
    66d4:	15212823          	sw	s2,336(sp)
    66d8:	15312623          	sw	s3,332(sp)
    66dc:	15412423          	sw	s4,328(sp)
    66e0:	15512223          	sw	s5,324(sp)
    66e4:	15612023          	sw	s6,320(sp)
    66e8:	13712e23          	sw	s7,316(sp)
    bsp_printf("\r\n---------- [7] 多精灵压测（每档 %d 帧，节流 %d ticks@%dHz） ----------\r\n",
    66ec:	05f5e6b7          	lui	a3,0x5f5e
    66f0:	10068693          	addi	a3,a3,256 # 5f5e100 <__freertos_irq_stack_top+0x5f51410>
    66f4:	00197637          	lui	a2,0x197
    66f8:	e6a60613          	addi	a2,a2,-406 # 196e6a <__freertos_irq_stack_top+0x18a17a>
    66fc:	03c00593          	li	a1,60
    6700:	00008537          	lui	a0,0x8
    6704:	40c50513          	addi	a0,a0,1036 # 840c <_data+0x14b8>
    6708:	d7cfc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("      优化开关: 批量下发=%d(每批%d条/开批允许残留%d条) 冲刷模式=%d(每%d帧,%d字) 擦除模式=%d 哨兵=%d 帧内读PERF=%d\r\n",
    670c:	00012223          	sw	zero,4(sp)
    6710:	00100793          	li	a5,1
    6714:	00f12023          	sw	a5,0(sp)
    6718:	00000893          	li	a7,0
    671c:	00001837          	lui	a6,0x1
    6720:	80080813          	addi	a6,a6,-2048 # 800 <CUSTOM2+0x7a5>
    6724:	00800793          	li	a5,8
    6728:	00100713          	li	a4,1
    672c:	03000693          	li	a3,48
    6730:	0a000613          	li	a2,160
    6734:	00000593          	li	a1,0
    6738:	00008537          	lui	a0,0x8
    673c:	46450513          	addi	a0,a0,1124 # 8464 <_data+0x1510>
    6740:	d44fc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("      擦除策略: %s\r\n", STRESS_ERASE_TAG);
    6744:	000085b7          	lui	a1,0x8
    6748:	4fc58593          	addi	a1,a1,1276 # 84fc <_data+0x15a8>
    674c:	00008537          	lui	a0,0x8
    6750:	52050513          	addi	a0,a0,1312 # 8520 <_data+0x15cc>
    6754:	d30fc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("      指令口径: %s；ins/frm = 每帧实际推入 FIFO 的指令条数（含哨兵）\r\n",
    6758:	000085b7          	lui	a1,0x8
    675c:	53c58593          	addi	a1,a1,1340 # 853c <_data+0x15e8>
    6760:	00008537          	lui	a0,0x8
    6764:	57450513          	addi	a0,a0,1396 # 8574 <_data+0x1620>
    6768:	d1cfc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("      下发路径: **逐条下发 + 每条等 DONE**（默认，最保守）：FIFO 里最多 1 条指令，"
    676c:	00008537          	lui	a0,0x8
    6770:	5d050513          	addi	a0,a0,1488 # 85d0 <_data+0x167c>
    6774:	d10fc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("      位置: 水平匀速弹跳 + 垂直正弦（整数表，无浮点）；帧末在引擎 IDLE 稳态校验"
    6778:	00008537          	lui	a0,0x8
    677c:	6a450513          	addi	a0,a0,1700 # 86a4 <_data+0x1750>
    6780:	d04fc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("      eng/frm 口径: 每档末尾 1 个「记账帧」逐条等 DONE 后读 BLT_PERF 求和"
    6784:	00008537          	lui	a0,0x8
    6788:	75050513          	addi	a0,a0,1872 # 8750 <_data+0x17fc>
    678c:	cf8fc0ef          	jal	2c84 <bsp_printf>
    stress_setup();
    6790:	bfdff0ef          	jal	638c <stress_setup>
        uint32_t acc = 0;
    6794:	00000493          	li	s1,0
        for (k = 0; k < 10; k++) acc += cache_evict_timed();
    6798:	00000413          	li	s0,0
    679c:	0100006f          	j	67ac <stress_all+0xe8>
    67a0:	9f0fb0ef          	jal	1990 <cache_evict_timed>
    67a4:	00a484b3          	add	s1,s1,a0
    67a8:	00140413          	addi	s0,s0,1
    67ac:	00900793          	li	a5,9
    67b0:	fe87d8e3          	bge	a5,s0,67a0 <stress_all+0xdc>
    bsp_printf("      基线：单次 cache_evict(%d 字) 的空帧开销 ≈ %d ticks；"
    67b4:	00100693          	li	a3,1
    67b8:	00a00613          	li	a2,10
    67bc:	02c4d633          	divu	a2,s1,a2
    67c0:	000015b7          	lui	a1,0x1
    67c4:	80058593          	addi	a1,a1,-2048 # 800 <CUSTOM2+0x7a5>
    67c8:	00008537          	lui	a0,0x8
    67cc:	7ec50513          	addi	a0,a0,2028 # 87ec <_data+0x1898>
    67d0:	cb4fc0ef          	jal	2c84 <bsp_printf>
    int r, ran = 0, last60 = 0, last55 = 0, best = -1;
    67d4:	fff00a13          	li	s4,-1
    67d8:	00000a93          	li	s5,0
    67dc:	00000b13          	li	s6,0
    67e0:	00000493          	li	s1,0
    for (r = 0; r < STRESS_NRUNG; r++) {
    67e4:	00000913          	li	s2,0
    67e8:	0700006f          	j	6858 <stress_all+0x194>
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=NA(未采到有效 PERF, 坏样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
    67ec:	000088b7          	lui	a7,0x8
    67f0:	3b888893          	addi	a7,a7,952 # 83b8 <_data+0x1464>
    67f4:	00009537          	lui	a0,0x9
    67f8:	87850513          	addi	a0,a0,-1928 # 8878 <_data+0x1924>
    67fc:	c88fc0ef          	jal	2c84 <bsp_printf>
        if (row[ran - 1].errs) { stop_n = n; break; }
    6800:	00149793          	slli	a5,s1,0x1
    6804:	009787b3          	add	a5,a5,s1
    6808:	00479793          	slli	a5,a5,0x4
    680c:	13078793          	addi	a5,a5,304
    6810:	002787b3          	add	a5,a5,sp
    6814:	f0c7a783          	lw	a5,-244(a5)
    6818:	20079a63          	bnez	a5,6a2c <stress_all+0x368>
        if (row[ran - 1].fps >= 60u) { last60 = n; best = ran - 1; }
    681c:	00149793          	slli	a5,s1,0x1
    6820:	009787b3          	add	a5,a5,s1
    6824:	00479793          	slli	a5,a5,0x4
    6828:	13078793          	addi	a5,a5,304
    682c:	002787b3          	add	a5,a5,sp
    6830:	efc7a783          	lw	a5,-260(a5)
    6834:	03b00713          	li	a4,59
    6838:	00f77663          	bgeu	a4,a5,6844 <stress_all+0x180>
    683c:	00048a13          	mv	s4,s1
    6840:	00098b13          	mv	s6,s3
        if (row[ran - 1].fps >= 55u) last55 = n;
    6844:	03600713          	li	a4,54
    6848:	1ef77663          	bgeu	a4,a5,6a34 <stress_all+0x370>
    for (r = 0; r < STRESS_NRUNG; r++) {
    684c:	00190913          	addi	s2,s2,1
        if (row[ran - 1].fps >= 55u) last55 = n;
    6850:	00098a93          	mv	s5,s3
        ran++;
    6854:	000b8493          	mv	s1,s7
    for (r = 0; r < STRESS_NRUNG; r++) {
    6858:	00500793          	li	a5,5
    685c:	1927ca63          	blt	a5,s2,69f0 <stress_all+0x32c>
        int n = ladder[r];
    6860:	000097b7          	lui	a5,0x9
    6864:	00291713          	slli	a4,s2,0x2
    6868:	5ec78793          	addi	a5,a5,1516 # 95ec <ladder.0>
    686c:	00e787b3          	add	a5,a5,a4
    6870:	0007a983          	lw	s3,0(a5)
        if (!g_blt_alive) break;
    6874:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    6878:	1a078663          	beqz	a5,6a24 <stress_all+0x360>
        stress_rung(n, STRESS_FRAMES, &row[ran]);
    687c:	00149413          	slli	s0,s1,0x1
    6880:	00940633          	add	a2,s0,s1
    6884:	00461613          	slli	a2,a2,0x4
    6888:	01010793          	addi	a5,sp,16
    688c:	00c78633          	add	a2,a5,a2
    6890:	03c00593          	li	a1,60
    6894:	00098513          	mv	a0,s3
    6898:	921fc0ef          	jal	31b8 <stress_rung>
        ran++;
    689c:	00148b93          	addi	s7,s1,1
        if (row[ran - 1].perf_good == 0)
    68a0:	00940433          	add	s0,s0,s1
    68a4:	00441413          	slli	s0,s0,0x4
    68a8:	13040793          	addi	a5,s0,304
    68ac:	00278433          	add	s0,a5,sp
    68b0:	f0442783          	lw	a5,-252(s0)
    68b4:	04079263          	bnez	a5,68f8 <stress_all+0x234>
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=NA(未采到有效 PERF, 坏样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
    68b8:	ee042583          	lw	a1,-288(s0)
    68bc:	ee442603          	lw	a2,-284(s0)
                       row[ran - 1].n, row[ran - 1].frames, (int)row[ran - 1].ins_avg,
    68c0:	ee842683          	lw	a3,-280(s0)
                       (int)row[ran - 1].perf_zero, (int)row[ran - 1].cpu_avg, (int)row[ran - 1].fps,
    68c4:	f0842703          	lw	a4,-248(s0)
    68c8:	ef042783          	lw	a5,-272(s0)
    68cc:	efc42803          	lw	a6,-260(s0)
                       (row[ran - 1].errs ? "ENGINE-ERR" :
    68d0:	f0c42503          	lw	a0,-244(s0)
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=NA(未采到有效 PERF, 坏样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
    68d4:	f0051ce3          	bnez	a0,67ec <stress_all+0x128>
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
    68d8:	03b00513          	li	a0,59
    68dc:	01057863          	bgeu	a0,a6,68ec <stress_all+0x228>
    68e0:	000088b7          	lui	a7,0x8
    68e4:	3c488893          	addi	a7,a7,964 # 83c4 <_data+0x1470>
    68e8:	f0dff06f          	j	67f4 <stress_all+0x130>
    68ec:	000078b7          	lui	a7,0x7
    68f0:	50488893          	addi	a7,a7,1284 # 7504 <_data+0x5b0>
    68f4:	f01ff06f          	j	67f4 <stress_all+0x130>
        else if (row[ran - 1].perf_zero)
    68f8:	00149793          	slli	a5,s1,0x1
    68fc:	009787b3          	add	a5,a5,s1
    6900:	00479793          	slli	a5,a5,0x4
    6904:	13078793          	addi	a5,a5,304
    6908:	002787b3          	add	a5,a5,sp
    690c:	f087a783          	lw	a5,-248(a5)
    6910:	06078a63          	beqz	a5,6984 <stress_all+0x2c0>
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d(坏PERF样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
    6914:	00149513          	slli	a0,s1,0x1
    6918:	00950533          	add	a0,a0,s1
    691c:	00451513          	slli	a0,a0,0x4
    6920:	13050713          	addi	a4,a0,304
    6924:	00270533          	add	a0,a4,sp
    6928:	ee052583          	lw	a1,-288(a0)
    692c:	ee452603          	lw	a2,-284(a0)
                       row[ran - 1].n, row[ran - 1].frames, (int)row[ran - 1].ins_avg,
    6930:	ee852683          	lw	a3,-280(a0)
                       (int)row[ran - 1].eng_avg, (int)row[ran - 1].perf_zero,
    6934:	eec52703          	lw	a4,-276(a0)
                       (int)row[ran - 1].cpu_avg, (int)row[ran - 1].fps,
    6938:	ef052803          	lw	a6,-272(a0)
    693c:	efc52883          	lw	a7,-260(a0)
                       (row[ran - 1].errs ? "ENGINE-ERR" :
    6940:	f0c52503          	lw	a0,-244(a0)
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d(坏PERF样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
    6944:	00051c63          	bnez	a0,695c <stress_all+0x298>
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
    6948:	03b00513          	li	a0,59
    694c:	03157663          	bgeu	a0,a7,6978 <stress_all+0x2b4>
    6950:	00008537          	lui	a0,0x8
    6954:	3c450513          	addi	a0,a0,964 # 83c4 <_data+0x1470>
    6958:	00c0006f          	j	6964 <stress_all+0x2a0>
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d(坏PERF样本%d条) cpu/frm=%d fps=%d -> 60fps %s\r\n",
    695c:	00008537          	lui	a0,0x8
    6960:	3b850513          	addi	a0,a0,952 # 83b8 <_data+0x1464>
    6964:	00a12023          	sw	a0,0(sp)
    6968:	00009537          	lui	a0,0x9
    696c:	8f050513          	addi	a0,a0,-1808 # 88f0 <_data+0x199c>
    6970:	b14fc0ef          	jal	2c84 <bsp_printf>
    6974:	e8dff06f          	j	6800 <stress_all+0x13c>
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
    6978:	00007537          	lui	a0,0x7
    697c:	50450513          	addi	a0,a0,1284 # 7504 <_data+0x5b0>
    6980:	fe5ff06f          	j	6964 <stress_all+0x2a0>
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d cpu/frm=%d fps=%d -> 60fps %s\r\n",
    6984:	00149513          	slli	a0,s1,0x1
    6988:	00950533          	add	a0,a0,s1
    698c:	00451513          	slli	a0,a0,0x4
    6990:	13050793          	addi	a5,a0,304
    6994:	00278533          	add	a0,a5,sp
    6998:	ee052583          	lw	a1,-288(a0)
    699c:	ee452603          	lw	a2,-284(a0)
                       row[ran - 1].n, row[ran - 1].frames, (int)row[ran - 1].ins_avg,
    69a0:	ee852683          	lw	a3,-280(a0)
                       (int)row[ran - 1].eng_avg, (int)row[ran - 1].cpu_avg, (int)row[ran - 1].fps,
    69a4:	eec52703          	lw	a4,-276(a0)
    69a8:	ef052783          	lw	a5,-272(a0)
    69ac:	efc52803          	lw	a6,-260(a0)
                       (row[ran - 1].errs ? "ENGINE-ERR" :
    69b0:	f0c52503          	lw	a0,-244(a0)
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d cpu/frm=%d fps=%d -> 60fps %s\r\n",
    69b4:	00051c63          	bnez	a0,69cc <stress_all+0x308>
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
    69b8:	03b00513          	li	a0,59
    69bc:	03057463          	bgeu	a0,a6,69e4 <stress_all+0x320>
    69c0:	000088b7          	lui	a7,0x8
    69c4:	3c488893          	addi	a7,a7,964 # 83c4 <_data+0x1470>
    69c8:	00c0006f          	j	69d4 <stress_all+0x310>
            bsp_printf("      STRESS N=%d frames=%d ins/frm=%d eng/frm=%d cpu/frm=%d fps=%d -> 60fps %s\r\n",
    69cc:	000088b7          	lui	a7,0x8
    69d0:	3b888893          	addi	a7,a7,952 # 83b8 <_data+0x1464>
    69d4:	00009537          	lui	a0,0x9
    69d8:	95850513          	addi	a0,a0,-1704 # 8958 <_data+0x1a04>
    69dc:	aa8fc0ef          	jal	2c84 <bsp_printf>
    69e0:	e21ff06f          	j	6800 <stress_all+0x13c>
                        (row[ran - 1].fps >= 60u ? "OK" : "FAIL")));
    69e4:	000078b7          	lui	a7,0x7
    69e8:	50488893          	addi	a7,a7,1284 # 7504 <_data+0x5b0>
    69ec:	fe9ff06f          	j	69d4 <stress_all+0x310>
    int stop_n = 0;
    69f0:	00000993          	li	s3,0
    bsp_printf("\r\n  ---- 同屏精灵数 vs 帧率（每档 %d 帧；eng/cpu/period 单位=100MHz 周期） ----\r\n",
    69f4:	03c00593          	li	a1,60
    69f8:	00009537          	lui	a0,0x9
    69fc:	9ac50513          	addi	a0,a0,-1620 # 89ac <_data+0x1a58>
    6a00:	a84fc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("  spr   frames  ins/frm  eng/frm  cpu/frm  period   fps    fps(period) evict%%  verdict\r\n");
    6a04:	00009537          	lui	a0,0x9
    6a08:	a1050513          	addi	a0,a0,-1520 # 8a10 <_data+0x1abc>
    6a0c:	a78fc0ef          	jal	2c84 <bsp_printf>
    bsp_printf("  (eng/frm 列: 记账帧逐条等 DONE 后采样 BLT_PERF 求和;"
    6a10:	00009537          	lui	a0,0x9
    6a14:	a6c50513          	addi	a0,a0,-1428 # 8a6c <_data+0x1b18>
    6a18:	a6cfc0ef          	jal	2c84 <bsp_printf>
    for (r = 0; r < ran; r++) {
    6a1c:	00000913          	li	s2,0
    6a20:	0c00006f          	j	6ae0 <stress_all+0x41c>
    int stop_n = 0;
    6a24:	00078993          	mv	s3,a5
    6a28:	fcdff06f          	j	69f4 <stress_all+0x330>
        ran++;
    6a2c:	000b8493          	mv	s1,s7
    6a30:	fc5ff06f          	j	69f4 <stress_all+0x330>
    6a34:	000b8493          	mv	s1,s7
    6a38:	fbdff06f          	j	69f4 <stress_all+0x330>
        bsp_printf("%c", (row[r].perf_good == 0) ? '?' : (row[r].perf_zero ? '!' : ' '));
    6a3c:	03f00593          	li	a1,63
    6a40:	00009537          	lui	a0,0x9
    6a44:	b2050513          	addi	a0,a0,-1248 # 8b20 <_data+0x1bcc>
    6a48:	a3cfc0ef          	jal	2c84 <bsp_printf>
        pnum((int)row[r].cpu_avg, 9);
    6a4c:	00191413          	slli	s0,s2,0x1
    6a50:	01240433          	add	s0,s0,s2
    6a54:	00441413          	slli	s0,s0,0x4
    6a58:	13040793          	addi	a5,s0,304
    6a5c:	00278433          	add	s0,a5,sp
    6a60:	00900593          	li	a1,9
    6a64:	ef042503          	lw	a0,-272(s0)
    6a68:	b5dff0ef          	jal	65c4 <pnum>
        pnum((int)row[r].period_avg, 9);
    6a6c:	00900593          	li	a1,9
    6a70:	ef442503          	lw	a0,-268(s0)
    6a74:	b51ff0ef          	jal	65c4 <pnum>
        pnum((int)row[r].fps, 7);
    6a78:	00700593          	li	a1,7
    6a7c:	efc42503          	lw	a0,-260(s0)
    6a80:	b45ff0ef          	jal	65c4 <pnum>
        pnum((int)row[r].fps_period, 13);
    6a84:	00d00593          	li	a1,13
    6a88:	f0042503          	lw	a0,-256(s0)
    6a8c:	b39ff0ef          	jal	65c4 <pnum>
        ppct(row[r].evict_avg, row[r].cpu_avg, 8);
    6a90:	00800613          	li	a2,8
    6a94:	ef042583          	lw	a1,-272(s0)
    6a98:	ef842503          	lw	a0,-264(s0)
    6a9c:	b91ff0ef          	jal	662c <ppct>
        bsp_printf("%s\r\n", row[r].errs ? "ENGINE-ERR" :
    6aa0:	f0c42783          	lw	a5,-244(s0)
    6aa4:	02079263          	bnez	a5,6ac8 <stress_all+0x404>
                            (row[r].fps >= 60u ? "OK" : "FAIL(<60fps)"));
    6aa8:	efc42703          	lw	a4,-260(s0)
    6aac:	03b00793          	li	a5,59
    6ab0:	08e7fe63          	bgeu	a5,a4,6b4c <stress_all+0x488>
    6ab4:	000085b7          	lui	a1,0x8
    6ab8:	3c458593          	addi	a1,a1,964 # 83c4 <_data+0x1470>
    6abc:	0140006f          	j	6ad0 <stress_all+0x40c>
        bsp_printf("%c", (row[r].perf_good == 0) ? '?' : (row[r].perf_zero ? '!' : ' '));
    6ac0:	02000593          	li	a1,32
    6ac4:	f7dff06f          	j	6a40 <stress_all+0x37c>
        bsp_printf("%s\r\n", row[r].errs ? "ENGINE-ERR" :
    6ac8:	000085b7          	lui	a1,0x8
    6acc:	3b858593          	addi	a1,a1,952 # 83b8 <_data+0x1464>
    6ad0:	00008537          	lui	a0,0x8
    6ad4:	53450513          	addi	a0,a0,1332 # 8534 <_data+0x15e0>
    6ad8:	9acfc0ef          	jal	2c84 <bsp_printf>
    for (r = 0; r < ran; r++) {
    6adc:	00190913          	addi	s2,s2,1
    6ae0:	06995c63          	bge	s2,s1,6b58 <stress_all+0x494>
        bsp_printf("  ");
    6ae4:	00008537          	lui	a0,0x8
    6ae8:	1f850513          	addi	a0,a0,504 # 81f8 <_data+0x12a4>
    6aec:	998fc0ef          	jal	2c84 <bsp_printf>
        pnum(row[r].n, 6);
    6af0:	00191413          	slli	s0,s2,0x1
    6af4:	01240433          	add	s0,s0,s2
    6af8:	00441413          	slli	s0,s0,0x4
    6afc:	13040793          	addi	a5,s0,304
    6b00:	00278433          	add	s0,a5,sp
    6b04:	00600593          	li	a1,6
    6b08:	ee042503          	lw	a0,-288(s0)
    6b0c:	ab9ff0ef          	jal	65c4 <pnum>
        pnum(row[r].frames, 8);
    6b10:	00800593          	li	a1,8
    6b14:	ee442503          	lw	a0,-284(s0)
    6b18:	aadff0ef          	jal	65c4 <pnum>
        pnum((int)row[r].ins_avg, 9);
    6b1c:	00900593          	li	a1,9
    6b20:	ee842503          	lw	a0,-280(s0)
    6b24:	aa1ff0ef          	jal	65c4 <pnum>
        pnum((int)row[r].eng_avg, 8);
    6b28:	00800593          	li	a1,8
    6b2c:	eec42503          	lw	a0,-276(s0)
    6b30:	a95ff0ef          	jal	65c4 <pnum>
        bsp_printf("%c", (row[r].perf_good == 0) ? '?' : (row[r].perf_zero ? '!' : ' '));
    6b34:	f0442783          	lw	a5,-252(s0)
    6b38:	f00782e3          	beqz	a5,6a3c <stress_all+0x378>
    6b3c:	f0842783          	lw	a5,-248(s0)
    6b40:	f80780e3          	beqz	a5,6ac0 <stress_all+0x3fc>
    6b44:	02100593          	li	a1,33
    6b48:	ef9ff06f          	j	6a40 <stress_all+0x37c>
                            (row[r].fps >= 60u ? "OK" : "FAIL(<60fps)"));
    6b4c:	000085b7          	lui	a1,0x8
    6b50:	3c858593          	addi	a1,a1,968 # 83c8 <_data+0x1474>
    6b54:	f7dff06f          	j	6ad0 <stress_all+0x40c>
    if (last60 == 0)
    6b58:	0c0b0663          	beqz	s6,6c24 <stress_all+0x560>
    else if (stop_n)
    6b5c:	0c098c63          	beqz	s3,6c34 <stress_all+0x570>
        bsp_printf("\r\n  MAX N @60FPS = %d（下一档 N=%d fps<55 -> 停止升档；N=%d 时 fps>=55）\r\n",
    6b60:	000a8693          	mv	a3,s5
    6b64:	00098613          	mv	a2,s3
    6b68:	000b0593          	mv	a1,s6
    6b6c:	00009537          	lui	a0,0x9
    6b70:	b5c50513          	addi	a0,a0,-1188 # 8b5c <_data+0x1c08>
    6b74:	910fc0ef          	jal	2c84 <bsp_printf>
    if (best >= 0) {
    6b78:	140a4e63          	bltz	s4,6cd4 <stress_all+0x610>
        uint32_t per_spr = (uint32_t)row[best].cpu_avg / (uint32_t)row[best].n;
    6b7c:	03000793          	li	a5,48
    6b80:	02fa07b3          	mul	a5,s4,a5
    6b84:	13078793          	addi	a5,a5,304
    6b88:	002787b3          	add	a5,a5,sp
    6b8c:	ef07a883          	lw	a7,-272(a5)
    6b90:	ee07a583          	lw	a1,-288(a5)
    6b94:	02b8d9b3          	divu	s3,a7,a1
        uint32_t lim     = per_spr ? ((uint32_t)FRAME_TICKS / per_spr) : 0u;
    6b98:	0ab8e863          	bltu	a7,a1,6c48 <stress_all+0x584>
    6b9c:	00197937          	lui	s2,0x197
    6ba0:	e6a90913          	addi	s2,s2,-406 # 196e6a <__freertos_irq_stack_top+0x18a17a>
    6ba4:	03395933          	divu	s2,s2,s3
        uint32_t eng_pm  = row[best].cpu_avg ? (row[best].eng_avg * 1000u) / row[best].cpu_avg : 0u;
    6ba8:	0a088463          	beqz	a7,6c50 <stress_all+0x58c>
    6bac:	03000793          	li	a5,48
    6bb0:	02fa07b3          	mul	a5,s4,a5
    6bb4:	13078793          	addi	a5,a5,304
    6bb8:	002787b3          	add	a5,a5,sp
    6bbc:	eec7a303          	lw	t1,-276(a5)
    6bc0:	3e800793          	li	a5,1000
    6bc4:	02f30333          	mul	t1,t1,a5
    6bc8:	03135333          	divu	t1,t1,a7
        uint32_t ev_pm   = row[best].cpu_avg ? (row[best].evict_avg * 1000u) / row[best].cpu_avg : 0u;
    6bcc:	08088663          	beqz	a7,6c58 <stress_all+0x594>
    6bd0:	03000793          	li	a5,48
    6bd4:	02fa07b3          	mul	a5,s4,a5
    6bd8:	13078793          	addi	a5,a5,304
    6bdc:	002787b3          	add	a5,a5,sp
    6be0:	ef87a503          	lw	a0,-264(a5)
    6be4:	3e800793          	li	a5,1000
    6be8:	02f50533          	mul	a0,a0,a5
    6bec:	03155533          	divu	a0,a0,a7
                   row[best].n, (int)row[best].ins_avg, (int)row[best].eng_avg,
    6bf0:	03000713          	li	a4,48
    6bf4:	02ea0733          	mul	a4,s4,a4
    6bf8:	13070793          	addi	a5,a4,304
    6bfc:	00278733          	add	a4,a5,sp
    6c00:	ee872603          	lw	a2,-280(a4)
    6c04:	eec72683          	lw	a3,-276(a4)
                   (row[best].perf_good == 0) ? "(NA:未采到有效 PERF)"
    6c08:	f0472783          	lw	a5,-252(a4)
        bsp_printf("  本档 N=%d: ins/frm=%d eng/frm=%d%s (占 cpu %d.%d%%) cpu/frm=%d "
    6c0c:	04078a63          	beqz	a5,6c60 <stress_all+0x59c>
                                              : (row[best].perf_zero ? "(有坏样本,见表)" : ""),
    6c10:	f0872783          	lw	a5,-248(a4)
    6c14:	10078c63          	beqz	a5,6d2c <stress_all+0x668>
    6c18:	00008737          	lui	a4,0x8
    6c1c:	3f470713          	addi	a4,a4,1012 # 83f4 <_data+0x14a0>
    6c20:	0480006f          	j	6c68 <stress_all+0x5a4>
        bsp_printf("\r\n  MAX N @60FPS = 0（连 N=25 都不到 60fps）\r\n");
    6c24:	00009537          	lui	a0,0x9
    6c28:	b2450513          	addi	a0,a0,-1244 # 8b24 <_data+0x1bd0>
    6c2c:	858fc0ef          	jal	2c84 <bsp_printf>
    6c30:	f49ff06f          	j	6b78 <stress_all+0x4b4>
        bsp_printf("\r\n  MAX N @60FPS = %d（最后一档仍 >=60fps，未探到上限）\r\n", last60);
    6c34:	000b0593          	mv	a1,s6
    6c38:	00009537          	lui	a0,0x9
    6c3c:	bb450513          	addi	a0,a0,-1100 # 8bb4 <_data+0x1c60>
    6c40:	844fc0ef          	jal	2c84 <bsp_printf>
    6c44:	f35ff06f          	j	6b78 <stress_all+0x4b4>
        uint32_t lim     = per_spr ? ((uint32_t)FRAME_TICKS / per_spr) : 0u;
    6c48:	00000913          	li	s2,0
    6c4c:	f5dff06f          	j	6ba8 <stress_all+0x4e4>
        uint32_t eng_pm  = row[best].cpu_avg ? (row[best].eng_avg * 1000u) / row[best].cpu_avg : 0u;
    6c50:	00088313          	mv	t1,a7
    6c54:	f79ff06f          	j	6bcc <stress_all+0x508>
        uint32_t ev_pm   = row[best].cpu_avg ? (row[best].evict_avg * 1000u) / row[best].cpu_avg : 0u;
    6c58:	00088513          	mv	a0,a7
    6c5c:	f95ff06f          	j	6bf0 <stress_all+0x52c>
        bsp_printf("  本档 N=%d: ins/frm=%d eng/frm=%d%s (占 cpu %d.%d%%) cpu/frm=%d "
    6c60:	00008737          	lui	a4,0x8
    6c64:	3d870713          	addi	a4,a4,984 # 83d8 <_data+0x1484>
                   (int)(eng_pm / 10u), (int)(eng_pm % 10u), (int)row[best].cpu_avg,
    6c68:	00a00793          	li	a5,10
                   (int)row[best].evict_avg, (int)(ev_pm / 10u), (int)(ev_pm % 10u));
    6c6c:	03000413          	li	s0,48
    6c70:	028a0433          	mul	s0,s4,s0
    6c74:	13040813          	addi	a6,s0,304
    6c78:	00280433          	add	s0,a6,sp
    6c7c:	ef842803          	lw	a6,-264(s0)
    6c80:	02f55e33          	divu	t3,a0,a5
    6c84:	02f57533          	remu	a0,a0,a5
        bsp_printf("  本档 N=%d: ins/frm=%d eng/frm=%d%s (占 cpu %d.%d%%) cpu/frm=%d "
    6c88:	00a12423          	sw	a0,8(sp)
    6c8c:	01c12223          	sw	t3,4(sp)
    6c90:	01012023          	sw	a6,0(sp)
    6c94:	02f37833          	remu	a6,t1,a5
    6c98:	02f357b3          	divu	a5,t1,a5
    6c9c:	00009537          	lui	a0,0x9
    6ca0:	bfc50513          	addi	a0,a0,-1028 # 8bfc <_data+0x1ca8>
    6ca4:	fe1fb0ef          	jal	2c84 <bsp_printf>
                   (int)(row[best].ins_avg ? ((uint32_t)row[best].cpu_avg / row[best].ins_avg) : 0u),
    6ca8:	ee842783          	lw	a5,-280(s0)
        bsp_printf("  60fps 预算 %d 周期/帧 -> 本档每精灵 %d 周期（每指令 %d），据此理论同屏上限 ≈ %d 精灵\r\n",
    6cac:	08078663          	beqz	a5,6d38 <stress_all+0x674>
                   (int)(row[best].ins_avg ? ((uint32_t)row[best].cpu_avg / row[best].ins_avg) : 0u),
    6cb0:	ef042683          	lw	a3,-272(s0)
    6cb4:	02f6d6b3          	divu	a3,a3,a5
        bsp_printf("  60fps 预算 %d 周期/帧 -> 本档每精灵 %d 周期（每指令 %d），据此理论同屏上限 ≈ %d 精灵\r\n",
    6cb8:	00090713          	mv	a4,s2
    6cbc:	00098613          	mv	a2,s3
    6cc0:	001975b7          	lui	a1,0x197
    6cc4:	e6a58593          	addi	a1,a1,-406 # 196e6a <__freertos_irq_stack_top+0x18a17a>
    6cc8:	00009537          	lui	a0,0x9
    6ccc:	c7050513          	addi	a0,a0,-912 # 8c70 <_data+0x1d1c>
    6cd0:	fb5fb0ef          	jal	2c84 <bsp_printf>
    if (ran == 0 || row[ran - 1].errs) g_fail++;
    6cd4:	02048063          	beqz	s1,6cf4 <stress_all+0x630>
    6cd8:	fff48793          	addi	a5,s1,-1
    6cdc:	03000713          	li	a4,48
    6ce0:	02e787b3          	mul	a5,a5,a4
    6ce4:	13078793          	addi	a5,a5,304
    6ce8:	002787b3          	add	a5,a5,sp
    6cec:	f0c7a783          	lw	a5,-244(a5)
    6cf0:	00078863          	beqz	a5,6d00 <stress_all+0x63c>
    6cf4:	8801a783          	lw	a5,-1920(gp) # 9740 <g_fail>
    6cf8:	00178793          	addi	a5,a5,1
    6cfc:	88f1a023          	sw	a5,-1920(gp) # 9740 <g_fail>
}
    6d00:	15c12083          	lw	ra,348(sp)
    6d04:	15812403          	lw	s0,344(sp)
    6d08:	15412483          	lw	s1,340(sp)
    6d0c:	15012903          	lw	s2,336(sp)
    6d10:	14c12983          	lw	s3,332(sp)
    6d14:	14812a03          	lw	s4,328(sp)
    6d18:	14412a83          	lw	s5,324(sp)
    6d1c:	14012b03          	lw	s6,320(sp)
    6d20:	13c12b83          	lw	s7,316(sp)
    6d24:	16010113          	addi	sp,sp,352
    6d28:	00008067          	ret
                                              : (row[best].perf_zero ? "(有坏样本,见表)" : ""),
    6d2c:	00009737          	lui	a4,0x9
    6d30:	c6c70713          	addi	a4,a4,-916 # 8c6c <_data+0x1d18>
    6d34:	f35ff06f          	j	6c68 <stress_all+0x5a4>
        bsp_printf("  60fps 预算 %d 周期/帧 -> 本档每精灵 %d 周期（每指令 %d），据此理论同屏上限 ≈ %d 精灵\r\n",
    6d38:	00000693          	li	a3,0
    6d3c:	f7dff06f          	j	6cb8 <stress_all+0x5f4>

00006d40 <print_summary>:
{
    6d40:	ff010113          	addi	sp,sp,-16
    6d44:	00112623          	sw	ra,12(sp)
    if (fails == 0)
    6d48:	00051e63          	bnez	a0,6d64 <print_summary+0x24>
        bsp_printf("\r\n========== fulltest ALL PASS ==========\r\n");
    6d4c:	00009537          	lui	a0,0x9
    6d50:	ce850513          	addi	a0,a0,-792 # 8ce8 <_data+0x1d94>
    6d54:	f31fb0ef          	jal	2c84 <bsp_printf>
}
    6d58:	00c12083          	lw	ra,12(sp)
    6d5c:	01010113          	addi	sp,sp,16
    6d60:	00008067          	ret
    6d64:	00050593          	mv	a1,a0
        bsp_printf("\r\n========== fulltest FAILED: %d ==========\r\n", fails);
    6d68:	00009537          	lui	a0,0x9
    6d6c:	d1450513          	addi	a0,a0,-748 # 8d14 <_data+0x1dc0>
    6d70:	f15fb0ef          	jal	2c84 <bsp_printf>
}
    6d74:	fe5ff06f          	j	6d58 <print_summary+0x18>

00006d78 <demo_loop>:
{
    6d78:	fb010113          	addi	sp,sp,-80
    6d7c:	04112623          	sw	ra,76(sp)
    6d80:	04812423          	sw	s0,72(sp)
    6d84:	04912223          	sw	s1,68(sp)
    6d88:	05212023          	sw	s2,64(sp)
    6d8c:	03312e23          	sw	s3,60(sp)
    6d90:	03412c23          	sw	s4,56(sp)
    6d94:	03512a23          	sw	s5,52(sp)
    6d98:	03612823          	sw	s6,48(sp)
    6d9c:	03712623          	sw	s7,44(sp)
    6da0:	03812423          	sw	s8,40(sp)
    6da4:	03912223          	sw	s9,36(sp)
    6da8:	03a12023          	sw	s10,32(sp)
    6dac:	01b12e23          	sw	s11,28(sp)
    stress_prepare(n);
    6db0:	00c00513          	li	a0,12
    6db4:	8cdfb0ef          	jal	2680 <stress_prepare>
    if (g_blt_alive) {
    6db8:	8181a783          	lw	a5,-2024(gp) # 96d8 <g_blt_alive>
    6dbc:	02078263          	beqz	a5,6de0 <demo_loop+0x68>
        if (blt_fill(FB_BASE, FB_STRIDE, FB_WIDTH, FB_HEIGHT, STRESS_BG) != 0) cpu_mode = 1;
    6dc0:	01000713          	li	a4,16
    6dc4:	21c00693          	li	a3,540
    6dc8:	3c000613          	li	a2,960
    6dcc:	78000593          	li	a1,1920
    6dd0:	00301537          	lui	a0,0x301
    6dd4:	edcfb0ef          	jal	24b0 <blt_fill>
    6dd8:	00050d93          	mv	s11,a0
    6ddc:	00050a63          	beqz	a0,6df0 <demo_loop+0x78>
    if (cpu_mode) bsp_printf("[demo] 引擎不可用，直接用 CPU 搬块（HDMI 动画继续）\r\n");
    6de0:	00009537          	lui	a0,0x9
    6de4:	d4450513          	addi	a0,a0,-700 # 8d44 <_data+0x1df0>
    6de8:	e9dfb0ef          	jal	2c84 <bsp_printf>
    6dec:	00100d93          	li	s11,1
    6df0:	00012623          	sw	zero,12(sp)
    6df4:	00000c13          	li	s8,0
    6df8:	1400006f          	j	6f38 <demo_loop+0x1c0>
            int rc = stress_frame(n, f, 0, 0, 0);
    6dfc:	00000713          	li	a4,0
    6e00:	00000693          	li	a3,0
    6e04:	00000613          	li	a2,0
    6e08:	000c0593          	mv	a1,s8
    6e0c:	00c00513          	li	a0,12
    6e10:	cadfb0ef          	jal	2abc <stress_frame>
    6e14:	00050413          	mv	s0,a0
            if (rc != 0) {
    6e18:	12050863          	beqz	a0,6f48 <demo_loop+0x1d0>
                errs++;
    6e1c:	00c12783          	lw	a5,12(sp)
    6e20:	00178493          	addi	s1,a5,1
    6e24:	00912623          	sw	s1,12(sp)
                op_fail(rc, "demo frame");
    6e28:	000095b7          	lui	a1,0x9
    6e2c:	d8c58593          	addi	a1,a1,-628 # 8d8c <_data+0x1e38>
    6e30:	ad8fc0ef          	jal	3108 <op_fail>
                if (errs >= 3) {
    6e34:	00200793          	li	a5,2
    6e38:	1097d863          	bge	a5,s1,6f48 <demo_loop+0x1d0>
                    bsp_printf("[demo] 引擎连续出错(最后 rc=%d)，改用 CPU 搬块（HDMI 动画继续）\r\n", rc);
    6e3c:	00040593          	mv	a1,s0
    6e40:	00009537          	lui	a0,0x9
    6e44:	d9850513          	addi	a0,a0,-616 # 8d98 <_data+0x1e44>
    6e48:	e3dfb0ef          	jal	2c84 <bsp_printf>
                    cpu_mode = 1;
    6e4c:	00100d93          	li	s11,1
    6e50:	0f80006f          	j	6f48 <demo_loop+0x1d0>
                int sl = i & (STRESS_NSLOT - 1);
    6e54:	007a7a93          	andi	s5,s4,7
                int w  = (int)s_sprw[sl];
    6e58:	000097b7          	lui	a5,0x9
    6e5c:	001a9a93          	slli	s5,s5,0x1
    6e60:	6bc78793          	addi	a5,a5,1724 # 96bc <s_sprw>
    6e64:	015787b3          	add	a5,a5,s5
    6e68:	0007db03          	lhu	s6,0(a5)
                int h  = (int)s_sprh[sl];
    6e6c:	000097b7          	lui	a5,0x9
    6e70:	6ac78793          	addi	a5,a5,1708 # 96ac <s_sprh>
    6e74:	015787b3          	add	a5,a5,s5
    6e78:	0007db83          	lhu	s7,0(a5)
                fill_rect_cpu(FB_BASE, FB_STRIDE, sp_px[i], sp_py[i], w, h, (uint16_t)STRESS_BG);
    6e7c:	0000b937          	lui	s2,0xb
    6e80:	001a1493          	slli	s1,s4,0x1
    6e84:	a0490913          	addi	s2,s2,-1532 # aa04 <sp_px>
    6e88:	00990933          	add	s2,s2,s1
    6e8c:	0000a437          	lui	s0,0xa
    6e90:	3c440413          	addi	s0,s0,964 # a3c4 <sp_py>
    6e94:	00940433          	add	s0,s0,s1
    6e98:	01000813          	li	a6,16
    6e9c:	000b8793          	mv	a5,s7
    6ea0:	000b0713          	mv	a4,s6
    6ea4:	00041683          	lh	a3,0(s0)
    6ea8:	00091603          	lh	a2,0(s2)
    6eac:	78000593          	li	a1,1920
    6eb0:	00301537          	lui	a0,0x301
    6eb4:	9e9fa0ef          	jal	189c <fill_rect_cpu>
                spr_move(i, f);
    6eb8:	000c0593          	mv	a1,s8
    6ebc:	000a0513          	mv	a0,s4
    6ec0:	899fb0ef          	jal	2758 <spr_move>
                fill_rect_cpu(FB_BASE, FB_STRIDE, sp_x[i], sp_y[i], w, h, s_sprc[sl]);
    6ec4:	0000b9b7          	lui	s3,0xb
    6ec8:	68498993          	addi	s3,s3,1668 # b684 <sp_x>
    6ecc:	009989b3          	add	s3,s3,s1
    6ed0:	0000b7b7          	lui	a5,0xb
    6ed4:	04478793          	addi	a5,a5,68 # b044 <sp_y>
    6ed8:	009784b3          	add	s1,a5,s1
    6edc:	000097b7          	lui	a5,0x9
    6ee0:	69c78793          	addi	a5,a5,1692 # 969c <s_sprc>
    6ee4:	015787b3          	add	a5,a5,s5
    6ee8:	0007d803          	lhu	a6,0(a5)
    6eec:	000b8793          	mv	a5,s7
    6ef0:	000b0713          	mv	a4,s6
    6ef4:	00049683          	lh	a3,0(s1)
    6ef8:	00099603          	lh	a2,0(s3)
    6efc:	78000593          	li	a1,1920
    6f00:	00301537          	lui	a0,0x301
    6f04:	999fa0ef          	jal	189c <fill_rect_cpu>
                sp_px[i] = sp_x[i];
    6f08:	00099783          	lh	a5,0(s3)
    6f0c:	00f91023          	sh	a5,0(s2)
                sp_py[i] = sp_y[i];
    6f10:	00049783          	lh	a5,0(s1)
    6f14:	00f41023          	sh	a5,0(s0)
            for (i = 0; i < n; i++) {
    6f18:	001a0a13          	addi	s4,s4,1
    6f1c:	00b00793          	li	a5,11
    6f20:	f347dae3          	bge	a5,s4,6e54 <demo_loop+0xdc>
            cache_evict();          /* CPU 写过 DDR -> 挤出 D$，屏幕内容才与内存一致 */
    6f24:	a3dfa0ef          	jal	1960 <cache_evict>
        frame_throttle(t0);
    6f28:	000d0513          	mv	a0,s10
    6f2c:	000c8593          	mv	a1,s9
    6f30:	e70fb0ef          	jal	25a0 <frame_throttle>
        f++;
    6f34:	001c0c13          	addi	s8,s8,1
        uint64_t t0 = tick();
    6f38:	8e9fa0ef          	jal	1820 <tick>
    6f3c:	00050d13          	mv	s10,a0
    6f40:	00058c93          	mv	s9,a1
        if (!cpu_mode) {
    6f44:	ea0d8ce3          	beqz	s11,6dfc <demo_loop+0x84>
        if (cpu_mode) {
    6f48:	fe0d80e3          	beqz	s11,6f28 <demo_loop+0x1b0>
            for (i = 0; i < n; i++) {
    6f4c:	00000a13          	li	s4,0
    6f50:	fcdff06f          	j	6f1c <demo_loop+0x1a4>
