# atlas/ —— 图集（精灵 / 大图）资源目录

把你要用的图片放进这个目录，用附带脚本转成引擎能直接读的格式。
（本轮"大图快速切换"**先不做**，这里只提供格式约定与入 flash 的机制，方便你先挑图。）

---

## 1. 图片格式要求（硬性）

| 项目 | 要求 | 说明 |
|---|---|---|
| 像素格式 | **RGB565，每像素 16bit，小端** | byte0 = `G[2:0]<<5 \| B[4:0]`，byte1 = `R[4:0]<<3 \| G[5:3]` |
| 色彩深度 | 无 alpha 通道 | **引擎的半透明是"每条指令一个全局 α（0~255）"**，不支持逐像素 alpha |
| 透明方式 | **色键（color key）**：一个 RGB565 值代表"不写" | 默认用 `0xF81F`（洋红）。注意：真实照片里若出现同色像素会被一起抠掉 |
| 行序 | 行主序，从上到下 | 需要时可加 `-FlipY` |
| 行跨距 stride | **字节数**，随指令传入 | 不要求等于 `宽×2`；`-Pad64` 可把每行补齐到 64B 的倍数（DDR/突发更友好） |
| 文件头 | **无**（裸像素流） | 宽高由指令里的 `(h<<16)\|w` 给出，不从文件里读 |
| 对齐 | 引擎支持任意目的地址（含奇数 x）；**CPU 侧 32bit 写要求 x 为偶数** | 这条踩过大坑，见仓库 `rtl/功能清单.md` §18 |

**尺寸建议**：宽高都取偶数；若要做精灵，建议单张 ≤ 128×128（放进图集拼接）。

---

## 2. 转换工具（本目录）

```powershell
# 在仓库根目录执行
powershell -NoProfile -ExecutionPolicy Bypass -File atlas\convert_rgb565.ps1 `
    -In atlas\my.png -Out atlas\my -Key
```

| 参数 | 作用 |
|---|---|
| `-In` / `-Out` | 源图 / 输出前缀（不带扩展名） |
| `-Key` | 把全透明像素（alpha<128）写成色键色 `0xF81F`（做精灵抠图用） |
| `-Pad64` | 每行字节数补齐到 64 的倍数 |
| `-FlipY` | 上下翻转 |

产物：
- `my.raw` —— 裸 RGB565 小端像素流（**走 flash 路线**用这个）
- `my.h` —— C 数组（**只适合小图**，见下）

已实测（`atlas/_selftest.png`，48×32）：透明角→`0xF81F`、纯红(255,0,0)→`0xF800`、纯绿(0,255,0)→`0x07E0` ✓

---

## 3. 两条"把图片交给引擎"的路线

### 路线 A：编进 App（C 数组）—— 简单，但受 App 内存限制

把 `my.h` include 进 `comptest2.c`，像这样用：

```c
#include "my.h"                                  /* 提供 MY_W / MY_H / MY_STRIDE / MY[] */
blt_key((uint32_t)MY, dst, MY_STRIDE, FB_STRIDE, MY_W, MY_H, 0xF81F);   /* 色键抠图 */
blt_alpha((uint32_t)MY, dst, MY_STRIDE, FB_STRIDE, MY_W, MY_H, 128);    /* 半透明叠加 */
```

**容量限制**：链接脚本是 `ram : ORIGIN = 0x0000_1000, LENGTH = 124K` ——
**整个 App（代码+数据+栈）只有 124KB**。当前 `comptest2` 用了约 21KB，剩约 100KB。
⇒ 一张 320×160 的 RGB565 就是 100KB，基本就到顶了；**整屏大图（约 1MB）放不下**。

### 路线 B：裸数据烧进配置 flash，运行时搬进 DDR —— 大图必须走这条

仓库里 `bootloader` 自己就是这么把 App 搬进 DDR 的（**已验证的实际配方**，
见 `standalone/bootloader/src/bootloaderConfig.h`）：

```c
#include "spiFlash.h"
#define SPI     SYSTEM_SPI_0_IO_CTRL
#define SPI_CS  0

/* bootloader 的实测参数：App 在 flash 0x00380000，大小 0x01F000，搬到 DDR 0x00001000 */
spiFlash_init(SPI, SPI_CS);
spiFlash_wake(SPI, SPI_CS);
spiFlash_exit4ByteAddr(SPI, SPI_CS);
spiFlash_f2m(SPI, SPI_CS, flash_addr, ddr_addr, size);      /* flash -> 内存 */
```

你只需要把 `flash_addr` 换成你自己的图片偏移、`ddr_addr` 换成 DDR 里的落点：

```c
#define IMG_FLASH_ADDR  0x00580000UL    /* 见下面的地址规划 */
#define IMG_DDR_ADDR    0x00700000UL
#define IMG_SIZE        (960*540*2)     /* 960x540 RGB565 = 1,036,800 B */
spiFlash_f2m(SPI, SPI_CS, IMG_FLASH_ADDR, IMG_DDR_ADDR, IMG_SIZE);
/* 之后引擎直接从 DDR 取数：blt_copy(IMG_DDR_ADDR, dst, 1920, FB_STRIDE, 960, 540, ...) */
```

**地址规划（当前工程实际占用）**：

| 区域 | 地址 | 备注 |
|---|---|---|
| App（flash 内） | `0x00380000` .. `0x0057F000` | 大小 `0x01F000`，搬到 DDR `0x00001000` |
| **图片建议放** | **`0x00580000` 往后** | 别和 App 重叠；flash 总容量请按你板上的型号确认 |
| DDR 帧缓冲 | `0x00301000`（960×540×2B = 1MB） | 显示缓冲 |
| DDR 图集区 | `0x00200000` | `comptest2` 开机生成的 32×32 精灵就放这里 |
| **大图建议落点** | **`0x00700000` 往后** | DDR 共 256MB，空间充足 |

**怎么把 `.raw` 烧到 flash**：它就是一段纯数据，和烧比特流/App 是同一套流程 ——
把它作为一段二进制追加到该偏移（或单独烧写该区域）即可；具体工具取决于你的烧录流程。

---

## 4. 大图快速切换（下一步做的时候怎么用）

引擎的 `COPY` 就是干这个的：**源/目的各自独立 stride**，一条指令搬一整张图。

```c
/* 把 DDR 里的第 k 张大图整屏搬上屏（960x540） */
blt_copy(IMG_DDR_ADDR + k * IMG_SIZE, FB_BASE, 1920, FB_STRIDE, 960, 540, 0xFF, 0);
```

三种典型做法（都可以只改软件）：
1. **双缓冲切换**：两张图各占一块 DDR，按键/串口切换"显示哪一块"；
2. **图集 + 窗口**：所有图拼进一张大图集，用 `src = 基址 + y*stride + x*2` 取子矩形；
3. **闪存直搬**：连搬都不用预搬，切图时 `spiFlash_f2m()` 把目标图直接搬进 DDR 再 `blt_copy` 上屏。

> 注意：整屏 COPY 实测约 1.89M 周期 ≈ 19ms（≈53fps 上限）。若要更高帧率，
> 需要先优化引擎写通路的突发合并（见 `rtl/功能清单.md` 里记的 `axi_wr_master` 那条）。

---

## 5. 目录内容

| 文件 | 说明 |
|---|---|
| `convert_rgb565.ps1` | 图片 → RGB565 转换脚本（已实测） |
| `_selftest.png` / `.raw` / `.h` | 脚本自测用的样例（48×32），可删 |
| `README.md` | 本文件 |
