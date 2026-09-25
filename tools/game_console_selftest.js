/* =============================================================================
 * game_console_selftest.js —— 上位机协议层自检（Node，不需要浏览器）
 * -----------------------------------------------------------------------------
 * 做法与工程里既有的「抽标记段」习惯一致：把 HTML 里
 * `==== PROTO_BEGIN/END ====` 之间的**纯函数**原样抽出来（vm 里跑），
 * 用真实固件回包当作期望值，把它逐个钉住。
 *
 * 跑法（仓库根目录）：
 *     node tools/game_console_selftest.js                          # 默认 game_console.html
 *     node tools/game_console_selftest.js tools/game_console1.html # 增强版（多跑 [7] 组）
 * 退出码 0 = 全过；1 = 有失败；2 = 抽段失败（标记被删/改名）。
 *
 * ★ [7] 组只在被检文件**含 BUL_MODES**（即 game_console1.html 那种带敌弹显示模式的版本）
 *   时才跑 —— 这样同一份自检脚本能同时服务两个页面，不必复制一份。
 * ============================================================================= */
'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const HTML = process.argv[2]
    ? path.resolve(process.argv[2])
    : path.join(__dirname, 'game_console.html');
if (!fs.existsSync(HTML)) {
    console.error('找不到被检文件：' + HTML);
    process.exit(2);
}
const src = fs.readFileSync(HTML, 'utf8');
console.log('# 被检文件：' + path.relative(path.join(__dirname, '..'), HTML));

/* ★ 按**整行标记**抽段（与 tools/host_selfcheck/extract.ps1 同一条规矩）：
 *   标记行本身不参与，取的就是「BEGIN 行」与「END 行」之间的那些行 ——
 *   这样 HTML 里那两行可以写成普通注释，抽出来的仍然是完整合法的 JS。 */
const lines = src.split(/\r?\n/);
const i0 = lines.findIndex(l => l.indexOf('==== PROTO_BEGIN ====') >= 0);
const i1 = lines.findIndex(l => l.indexOf('==== PROTO_END ====') >= 0);
if (i0 < 0 || i1 < 0 || i1 <= i0) {
    console.error('抽段失败：game_console.html 里找不到成对的 ==== PROTO_BEGIN/END ==== 标记行。');
    process.exit(2);
}
const body = lines.slice(i0 + 1, i1).join('\n');
const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(body, sandbox, { filename: 'game_console.html#PROTO' });

let pass = 0, fail = 0;
function check(cond, name) {
    if (cond) { pass++; }
    else { fail++; console.log('  *** FAIL: ' + name); }
}

/* ------------------------------------------------------------------ *
 * 1) 按键映射：每一个受支持的物理键都要落到正确的位，未映射的必须返回 -1
 * ------------------------------------------------------------------ */
console.log('[1] 按键映射');
{
    const cases = [
        ['KeyW', 'w', 0], ['ArrowUp', 'ArrowUp', 0],
        ['KeyS', 's', 1], ['ArrowDown', 'ArrowDown', 1],
        ['KeyA', 'a', 2], ['ArrowLeft', 'ArrowLeft', 2],
        ['KeyD', 'd', 3], ['ArrowRight', 'ArrowRight', 3],
        ['KeyJ', 'j', 4], ['Space', ' ', 4],
        ['KeyK', 'k', 5], ['ShiftLeft', 'Shift', 5], ['ShiftRight', 'Shift', 5],
        ['KeyL', 'l', 6], ['KeyX', 'x', 6],
        ['KeyP', 'p', 7], ['Enter', 'Enter', 7], ['NumpadEnter', 'Enter', 7], ['Escape', 'Escape', 7],
    ];
    let bad = 0;
    for (const [code, key, want] of cases) {
        if (sandbox.bitOfKey(code, key) !== want) { bad++; console.log('      ' + code + ' -> 期望 ' + want); }
    }
    check(bad === 0, '1.1 ' + cases.length + ' 个物理键都映射到正确的位');

    /* code 认不出来时用 key 兜底（有些环境/输入法不给 code） */
    check(sandbox.bitOfKey('', 'W') === 0, '1.2 code 缺失时用 key 兜底');
    check(sandbox.bitOfKey('KeyZ', 'z') === -1, '1.3 未映射的键返回 -1');
    check(sandbox.bitOfKey('F1', 'F1') === -1, '1.4 功能键返回 -1');
    check(sandbox.shouldPreventDefault('ArrowUp') === true, '1.5 方向键要 preventDefault（否则滚页面）');
    check(sandbox.shouldPreventDefault('Space') === true, '1.6 空格要 preventDefault');
    check(sandbox.shouldPreventDefault('KeyZ') === false, '1.7 普通字母键不拦截');
}

/* ------------------------------------------------------------------ *
 * 2) 数据包编码：必须是 '@' + 两位小写十六进制 + '\n'
 *    ★ 并且用**固件 kp_feed 的语法规则**做一次参考实现，把两端接起来：
 *      编码器产出的每一个包，固件都必须收下、且解出同一个位图。
 * ------------------------------------------------------------------ */
console.log('[2] 数据包编码 @HH\\n');
{
    let bad = 0, badRef = 0;
    for (let mask = 0; mask <= 255; mask++) {
        const p = sandbox.encodeKeyPacket(mask);
        const want = '@' + (mask < 16 ? '0' : '') + mask.toString(16) + '\n';
        if (p !== want) { bad++; if (bad < 4) console.log('      ' + mask + ' -> ' + JSON.stringify(p)); }
        /* ---- 固件 kp_feed 的参考实现（与 src/GameDemo.c 的 KEYPACK 段同一套规则） ---- */
        if (!(p.length === 4 && p[0] === '@' && p[3] === '\n')) { badRef++; continue; }
        const hv = (c) => (/^[0-9a-fA-F]$/.test(c) ? parseInt(c, 16) : -1);
        const h1 = hv(p[1]), h2 = hv(p[2]);
        if (h1 < 0 || h2 < 0) { badRef++; continue; }
        if (((h1 << 4) | h2) !== mask) badRef++;
    }
    check(bad === 0, '2.1 0..255 全部编码为 "@HH\\n"（小写十六进制、两位、带换行）');
    check(badRef === 0, '2.2 256 个包全部满足固件 kp_feed 的语法并解出同一位图');
    check(sandbox.encodeKeyPacket(0) === '@00\n', '2.3 全松 = @00');
    check(sandbox.encodeKeyPacket(0x18) === '@18\n', '2.4 右+开火 = @18');
    check(sandbox.encodeKeyPacket(0xff) === '@ff\n', '2.5 全按 = @ff');
}

/* ------------------------------------------------------------------ *
 * 3) 固件回包解析：ST 行（真实格式见 GameDemo.c 的 4Hz 状态行）
 * ------------------------------------------------------------------ */
console.log('[3] ST 状态行解析');
{
    const s = sandbox.parseStatusLine('ST fps=60 n=1280 on=1341 sc=20481 lv=3 hp=2 bm=1 md=HW');
    check(s !== null, '3.1 认得 ST 行');
    check(s && s.fps === 60 && s.n === 1280 && s.on === 1341 && s.sc === 20481 &&
          s.lv === 3 && s.hp === 2 && s.bm === 1 && s.md === 'HW', '3.2 八个字段逐个正确');

    const sw = sandbox.parseStatusLine('ST fps=7 n=256 on=268 sc=12 lv=1 hp=3 bm=3 md=SW');
    check(sw && sw.fps === 7 && sw.md === 'SW', '3.3 纯 CPU 路径（md=SW）');

    check(sandbox.parseStatusLine('EV N=1280') === null, '3.4 EV 行不是 ST 行');
    check(sandbox.parseStatusLine('') === null, '3.5 空行返回 null');
    check(sandbox.parseStatusLine(null) === null, '3.6 null 安全');
    check(sandbox.parseStatusLine('ST fps=118 n=2400 on=2412 sc=999999 lv=99 hp=0 bm=0 md=HW') !== null,
          '3.7 帧率过 100（118）也能解析');
}

/* ------------------------------------------------------------------ *
 * 4) LIMIT 行（自动爬坡结论）
 * ------------------------------------------------------------------ */
console.log('[4] LIMIT 行解析');
{
    const a = sandbox.parseLimitLine('LIMIT N=1152 fps=59 ON=1203 path=HW ACCEL (max stable at 60fps)');
    check(a !== null, '4.1 认得 LIMIT 行');
    check(a && a.n === 1152 && a.fps === 59 && a.on === 1203 && a.path === 'HW ACCEL',
          '4.2 N/fps/ON/path 逐个正确');
    const b = sandbox.parseLimitLine('LIMIT N=2400 fps=60 ON=2412 (hit N_MAX)');
    check(b && b.n === 2400 && b.fps === 60, '4.3 顶到上限那种形态（没有 path=）');
    check(sandbox.parseLimitLine('ST fps=60') === null, '4.4 ST 行不是 LIMIT 行');
}

/* ------------------------------------------------------------------ *
 * 5) =N 行命令：钳位规则必须与固件一致（只钳不拒）
 * ------------------------------------------------------------------ */
console.log('[5] =N 行命令编码');
{
    check(sandbox.encodeSetN(1375, 64, 2400) === '=1375\n', '5.1 常规值原样发');
    check(sandbox.encodeSetN(10, 64, 2400) === '=64\n', '5.2 低于下限钳到 64');
    check(sandbox.encodeSetN(9999, 64, 2400) === '=2400\n', '5.3 高于上限钳到 2400');
    check(sandbox.encodeSetN('640abc', 64, 2400) === '=640\n', '5.4 parseInt 前缀解析（与输入框行为一致）');
    check(sandbox.encodeSetN('', 64, 2400) === null, '5.5 空输入返回 null');
    check(sandbox.encodeSetN('abc', 64, 2400) === null, '5.6 非数字返回 null');
    check(sandbox.encodeSetN('1375', 64, 2400) === '=1375\n', '5.7 字符串数字也吃');
}

/* ------------------------------------------------------------------ *
 * 6) 与固件的边界一致性（把两端的常量对一遍，防止以后单边改）
 * ------------------------------------------------------------------ */
console.log('[6] 与固件常量的一致性');
{
    const fw = path.join(__dirname, '..', 'ARC_2DRA', 'par', 'ddr_demo_ti60', 'embedded_sw',
                          'soc', 'software', 'standalone', 'GameDemo', 'src', 'GameDemo.c');
    if (!fs.existsSync(fw)) {
        console.log('  (跳过：找不到固件源码，可能只拷贝了 tools/)');
    } else {
        const c = fs.readFileSync(fw, 'utf8');
        const g = (re) => { const r = c.match(re); return r ? parseInt(r[1], 10) : null; };
        const N_MIN = g(/#define\s+N_MIN\s+(\d+)/);
        const N_MAX = g(/#define\s+N_MAX\s+(\d+)/);
        check(N_MIN === 64 && N_MAX === 2400, '6.1 固件的 N 区间是 64..2400（与页面一致）');
        /* 页面上写死的钳位值必须与固件同源 */
        check(sandbox.encodeSetN(0, N_MIN, N_MAX) === '=64\n', '6.2 用固件常量钳下界');
        check(sandbox.encodeSetN(1e9, N_MIN, N_MAX) === '=2400\n', '6.3 用固件常量钳上界');
        /* ★ 按键位定义必须一致：KEY_UP=0x01 .. KEY_PAUSE=0x80
         *   （抓的是十六进制字面量的数字部分，所以要按 16 进制解 —— 用 10 进制解
         *     "10"/"20"/"40"/"80" 会得到 10/20/40/80，正好把高四位全弄错） */
        const bits = ['KEY_UP','KEY_DOWN','KEY_LEFT','KEY_RIGHT','KEY_FIRE','KEY_FOCUS','KEY_BOMB','KEY_PAUSE']
            .map(n => {
                const r = c.match(new RegExp('#define\\s+' + n + '\\s+0x([0-9A-Fa-f]+)u'));
                return r ? parseInt(r[1], 16) : null;
            });
        const want = [0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80];
        check(JSON.stringify(bits) === JSON.stringify(want),
              '6.4 固件 KEY_* 位定义 = 0x01/02/04/08/10/20/40/80（与页面 bit0..7 对齐）实际=' +
              JSON.stringify(bits));
    }
}

/* ------------------------------------------------------------------ *
 * 7) ★ 敌弹显示模式 —— 只有增强版页面（含 BUL_MODES）才跑这一段
 *    跑法：node tools/game_console_selftest.js tools/game_console1.html
 * ------------------------------------------------------------------ */
if (sandbox.BUL_MODES) {
    console.log('[7] 敌弹显示模式（增强版新增）');
    const M = sandbox.BUL_MODES;
    check(Array.isArray(M) && M.length === 4, '7.1 BUL_MODES 是 4 档');
    check(M.map(x => x.name).join(',') === 'FILL,ALPHA,ADD,KEY',
          '7.2 档序 = FILL,ALPHA,ADD,KEY（与固件 BULM_* 枚举同序）');
    check(M.map(x => x.cmd).join('') === '5678', '7.3 命令字 = 5/6/7/8');
    check(M.every(x => typeof x.desc === 'string' && x.desc.length > 8),
          '7.4 每一档都有说明文字（点按钮时能给出提示）');

    /* 档名 → 命令字 */
    check(sandbox.encodeBulMode('FILL') === '5' && sandbox.encodeBulMode('alpha') === '6' &&
          sandbox.encodeBulMode('Add') === '7' && sandbox.encodeBulMode('KEY') === '8',
          '7.5 encodeBulMode 大小写不敏感');
    check(sandbox.encodeBulMode('FIL') === null && sandbox.encodeBulMode('nope') === null &&
          sandbox.encodeBulMode(null) === null && sandbox.encodeBulMode(undefined) === null,
          '7.6 未知/非字符串档名返回 null（不会静默发错命令）');
    check(sandbox.encodeBulCycle() === 'f', '7.7 循环命令 = f');
    check(sandbox.bulModeByIndex(0).name === 'FILL' && sandbox.bulModeByIndex(3).name === 'KEY' &&
          sandbox.bulModeByIndex(4) === null && sandbox.bulModeByIndex(-1) === null,
          '7.8 bulModeByIndex 边界');
    check(sandbox.bulModeByName(' fill ') !== null && sandbox.bulModeByName('') === null,
          '7.9 bulModeByName 去空白 + 空串安全');

    /* ST 行里的 OP= 字段（固件 4Hz 状态行末段） */
    {
        const s1 = sandbox.parseStatusLine(
            'ST fps=60 n=2400 on=812 sc=20481 lv=3 hp=2 bm=1 md=HW OP=ALPHA');
        check(s1 && s1.op === 'ALPHA', '7.10 解析 ST 行末段的 OP=ALPHA');
        const s2 = sandbox.parseStatusLine(
            'ST fps=59 n=256 on=300 sc=1 lv=1 hp=3 bm=3 md=HW OP=FILL');
        check(s2 && s2.op === 'FILL' && s2.fps === 59 && s2.md === 'HW',
              '7.11 OP 与其它字段同时解析正确');
        const s3 = sandbox.parseStatusLine(
            'ST fps=60 n=256 on=300 sc=1 lv=1 hp=3 bm=3 md=HW');
        check(s3 && s3.op === null, '7.12 老格式（无 OP=）op 为 null，不误判');
        const s4 = sandbox.parseStatusLine('ST x=1 OP=BOGUS');
        check(!s4 || s4.op === null, '7.13 非法档名不解析');
    }

    /* ★ 与固件源码对账：档名/档序/枚举/命令字，改一边忘另一边会当场红 */
    const fw = path.join(__dirname, '..', 'ARC_2DRA', 'par', 'ddr_demo_ti60', 'embedded_sw',
                          'soc', 'software', 'standalone', 'GameDemo', 'src', 'GameDemo.c');
    if (!fs.existsSync(fw)) {
        console.log('  (跳过与固件对账：找不到 src/GameDemo.c)');
    } else {
        const c = fs.readFileSync(fw, 'utf8');
        const nm = c.match(/g_bulm_name\[BULM_N\]\s*=\s*\{([^}]*)\}/);
        const names = nm ? (nm[1].match(/"([A-Z]+)"/g) || []).map(x => x.replace(/"/g, '')) : [];
        check(names.join(',') === M.map(x => x.name).join(','),
              '7.14 档名与档序和固件 g_bulm_name[] 完全一致（实际=' + names.join(',') + '）');
        const defs = ['BULM_FILL', 'BULM_ALPHA', 'BULM_ADD', 'BULM_KEY'].map(n => {
            const r = c.match(new RegExp('#define\\s+' + n + '\\s+(\\d+)'));
            return r ? parseInt(r[1], 10) : null;
        });
        check(JSON.stringify(defs) === JSON.stringify([0, 1, 2, 3]),
              '7.15 固件 BULM_* 枚举 = 0/1/2/3（实际=' + JSON.stringify(defs) + '）');
        check(/#define\s+BULM_N\s+4\b/.test(c), '7.16 固件 BULM_N = 4');
        check(/case '5': case '6': case '7': case '8': case 'f': case 'F':/.test(c),
              '7.17 固件 serial_cmd 里有 5/6/7/8/f 的分支');
        check(/\(c - '5'\)/.test(c),
              "7.18 固件把 '5'..'8' 映射成下标 0..3（与 BUL_MODES 顺序同源）");
        check(/EV bulm=%s/.test(c), '7.19 固件切档时会回一行 EV bulm=…（页面上能看到回执）');
    }
}

console.log('\n===== game_console protocol self-test: ' + pass + ' passed / ' + fail + ' failed =====');
process.exit(fail === 0 ? 0 : 1);
