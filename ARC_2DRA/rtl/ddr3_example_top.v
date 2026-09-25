//***************************************************************/
//
// Moudel Name    : ddr3_example_top.v
// Version        : 1.1
// Date Created   : 2023-02-23 10:37:59
// Last Modified  : 2023-02-24 15:27:41
// Abstract       : ---
//
//***************************************************************/
//Modification History
//1.initial
//***************************************************************/
`include "ddr3_controller/ddr3_parameter.vh"

`define Efinity_Debug
`timescale 1ps/1ps
// `define SOFT_JTAG

module ddr3_example_top #
(
parameter                       RANK_RATIO         = 1,       // # of unique CS outputs per rank
parameter                       CK_RATIO           = `CK_RATIO, 
parameter                       ASYN_AXI_CLK       = `ASYN_AXI_CLK, 
parameter                       RANKS              = `RANKS,
parameter                       CK_WIDTH           = `CK_WIDTH,       // # of CK/CK# outputs to memory   
parameter                       CKE_WIDTH          = `CKE_WIDTH,       // # of cke outputs
parameter                       CS_WIDTH           = `CS_WIDTH,       // # of unique CS outputs
parameter                       BANK_WIDTH         = `BANK_WIDTH,       // # of bank bits
parameter                       ROW_WIDTH          = `ROW_WIDTH,       // DRAM address bus width
parameter                       COL_WIDTH          = `COL_WIDTH,      // column address width
parameter                       DM_WIDTH           = `DM_WIDTH,       // # of DM (data mask)
parameter                       DQS_WIDTH          = `DQS_WIDTH,       // # of DQS (strobe)
parameter                       DQ_WIDTH           = `DQ_WIDTH,      // # of DQ (data)
parameter                       ODT_WIDTH          = `ODT_WIDTH,
parameter                       DQ_CNT_WIDTH       = `DQ_CNT_WIDTH,       // = ceil(log2(DQ_WIDTH))
parameter                       DQS_CNT_WIDTH      = `DQS_CNT_WIDTH,       // = ceil(log2(DQS_WIDTH))  
parameter                       DRAM_WIDTH         = `DRAM_WIDTH,       // # of DQ per DQS   
parameter                       DATA_WIDTH         = `DATA_WIDTH,
parameter                       ADDR_WIDTH         = `ADDR_WIDTH,    
parameter                       AXI_ID_WIDTH       = `AXI_ID_WIDTH,
parameter                       AXI_ADDR_WIDTH     = `AXI_ADDR_WIDTH,
parameter                       AXI_DATA_WIDTH     = `AXI_DATA_WIDTH
)
(

   // Clock and reset ports
   input                              axi_clk,      
   input                              core_clk,     // CORE CLK @ 100MHz
   input                              sdram_clk,    // SDRAM CK @ 400MHz
   input                              rx_cal_clk,   // SDRAM CK @ 400MHz
   input                              tx_cal_clk,   // SDRAM CK @ 400MHz
   input                              tx_cal_clk_90edge,   // SDRAM CK @ 400MHz
   input                              pll_locked,
   input                              user_pll_locked,

   //================= HDMI TX（复用板卡 03_hdmi_tx_demo 的引脚/时序定义） =================
   input                              hdmi_tx_locked,      // HDMI 视频 PLL 锁定（Interface Designer: pll_hdmi）
   input                              hdmi_tx_slow_clk,    // 像素时钟 148.75MHz（PLL_BR0 输出）
   output wire [9:0]                  tmds_clk_o,
   output wire [9:0]                  tmds_data0_o,
   output wire [9:0]                  tmds_data1_o,
   output wire [9:0]                  tmds_data2_o,
   output wire                        tmds_clk_TX_OE,
   output wire                        tmds_data0_TX_OE,
   output wire                        tmds_data1_TX_OE,
   output wire                        tmds_data2_TX_OE,
   output wire                        tmds_clk_TX_RST,
   output wire                        tmds_data0_TX_RST,
   output wire                        tmds_data1_TX_RST,
   output wire                        tmds_data2_TX_RST,

  //  input                              peripheralClk,
   //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
   output  wire                       system_uart_0_io_txd,
   input                              system_uart_0_io_rxd,   
   input  [3:0]                       soc_gpio_IN,
   output [3:0]                       soc_gpio_OUT,
   output [3:0]                       soc_gpio_OE,
    // debug core ports
`ifdef  Efinity_Debug  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& 
`ifdef SOFT_JTAG
  input                               io_jtag_tms,
  input                               io_jtag_tdi,
  output  wire                        io_jtag_tdo,
  input                               io_jtag_tck,
`else
  input                               jtag_inst1_CAPTURE ,
  input                               jtag_inst1_DRCK    ,
  input                               jtag_inst1_RESET   ,
  input                               jtag_inst1_RUNTEST ,
  input                               jtag_inst1_SEL     ,
  input                               jtag_inst1_SHIFT   ,
  input                               jtag_inst1_TCK     ,
  input                               jtag_inst1_TDI     ,
  input                               jtag_inst1_TMS     ,
  input                               jtag_inst1_UPDATE  ,
  output                              jtag_inst1_TDO     ,
`endif 

`endif  //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
   // PLL status flags  
   output [2:0]                       pll_shift,  
   output [4:0]                       pll_shift_sel,
   output                             pll_shift_ena,  
   // memory interface ports
   output                             ddr_ck_hi,
   output                             ddr_ck_lo,
   output                             ddr_reset_n,
   output [CKE_WIDTH-1:0]             ddr_cke,     
   output [ROW_WIDTH-1:0]             ddr_addr,
   output [BANK_WIDTH-1:0]            ddr_ba,
   output                             ddr_cas_n,

   output [CS_WIDTH*RANK_RATIO-1:0]   ddr_cs_n,
   output                             ddr_ras_n,
   output                             ddr_we_n,
   
   input  [DQS_WIDTH-1:0]             ddr_dqs_in_hi,
   input  [DQS_WIDTH-1:0]             ddr_dqs_in_lo,
   input  [DQ_WIDTH-1:0]              ddr_dq_in_hi,
   input  [DQ_WIDTH-1:0]              ddr_dq_in_lo,
   
   output [DQS_WIDTH-1:0]             ddr_dqs_oe,
   output [DQS_WIDTH-1:0]             ddr_dqs_oe_n,
   output [DQ_WIDTH-1:0]              ddr_dq_oe,  
   output [DQS_WIDTH-1:0]             ddr_dqs_out_hi,
   output [DQS_WIDTH-1:0]             ddr_dqs_out_lo,
   output [DQ_WIDTH-1:0]              ddr_dq_out_hi,
   output [DQ_WIDTH-1:0]              ddr_dq_out_lo,
   output [DM_WIDTH-1:0]              ddr_dm_hi,
   output [DM_WIDTH-1:0]              ddr_dm_lo,
   output [ODT_WIDTH-1:0]             ddr_odt,

   input                              system_spi_0_io_data_0_IN,
   input                              system_spi_0_io_data_1_IN,
   output                             system_spi_0_io_ss,
   output                             system_spi_0_io_sclk_write,
   output                             system_spi_0_io_data_0_OUT,
   output                             system_spi_0_io_data_0_OE,
   output                             system_spi_0_io_data_1_OUT,
   output                             system_spi_0_io_data_1_OE

   );


      
//Parameter Define
parameter FREQ = 200;			// default is 100 MHz.  Redefine as needed.
`ifndef SIM
    localparam CNT_INIT = 1.5*FREQ*1000;
`else
    localparam CNT_INIT = 10;
`endif    
  localparam   AIW               = AXI_ID_WIDTH      ;
  localparam   ADW               = AXI_DATA_WIDTH    ;
  localparam   ABN               = AXI_DATA_WIDTH/8   ;
  /////////////////////////////////////////////////////////
  // Wire declarations
  reg  [19:0]                       cnt;    
  wire                              clk;
  wire                              rst;
  wire                              mmcm_locked;
  reg                               aresetn;
  wire                              app_sr_active;
  wire                              app_ref_ack;
  wire                              app_zq_ack;

  wire                              cal_done;

  // Slave Interface Write Address Ports
  wire [AXI_ID_WIDTH-1:0]           s_axi_awid;
  wire [AXI_ADDR_WIDTH-1:0]         s_axi_awaddr;
  wire [7:0]                        s_axi_awlen;
  wire [2:0]                        s_axi_awsize;
  wire [1:0]                        s_axi_awburst;
  wire [0:0]                        s_axi_awlock;
  wire [3:0]                        s_axi_awcache;
  wire [2:0]                        s_axi_awprot;
  wire                              s_axi_awvalid;
  wire                              s_axi_awready;
   // Slave Interface Write Data Ports
  wire [AXI_DATA_WIDTH-1:0]         s_axi_wdata;
  wire [(AXI_DATA_WIDTH/8)-1:0]     s_axi_wstrb;
  wire                              s_axi_wlast;
  wire                              s_axi_wvalid;
  wire                              s_axi_wready;
   // Slave Interface Write Response Ports
  wire                              s_axi_bready;
  wire [AXI_ID_WIDTH-1:0]           s_axi_bid;
  wire [1:0]                        s_axi_bresp;
  wire                              s_axi_bvalid;
   // Slave Interface Read Address Ports
  wire [AXI_ID_WIDTH-1:0]           s_axi_arid;
  wire [AXI_ADDR_WIDTH-1:0]         s_axi_araddr;
  wire [7:0]                        s_axi_arlen;
  wire [2:0]                        s_axi_arsize;
  wire [1:0]                        s_axi_arburst;
  wire [0:0]                        s_axi_arlock;
  wire [3:0]                        s_axi_arcache;
  wire [2:0]                        s_axi_arprot;
  wire                              s_axi_arvalid;
  wire                              s_axi_arready;
   // Slave Interface Read Data Ports
  wire                              s_axi_rready;
  wire [AXI_ID_WIDTH-1:0]           s_axi_rid;
  wire [AXI_DATA_WIDTH-1:0]         s_axi_rdata;
  wire [1:0]                        s_axi_rresp;
  wire                              s_axi_rlast;
  wire                              s_axi_rvalid;

  //==================== HDMI 扫描输出通路连线（须在例化之前声明）====================
  // CPU 读通道（接 soc 的 io_ddrA_ar/r，经仲裁器共享 DDR 读口）
  wire [AXI_ADDR_WIDTH-1:0]         cpu_ar_addr;
  wire [7:0]                        cpu_ar_len;
  wire [2:0]                        cpu_ar_size;
  wire [1:0]                        cpu_ar_burst;
  wire [0:0]                        cpu_ar_lock;
  wire [AXI_ID_WIDTH-1:0]           cpu_ar_id;
  wire                              cpu_ar_valid;
  wire                              cpu_ar_ready;
  wire [AXI_DATA_WIDTH-1:0]         cpu_r_data;
  wire [1:0]                        cpu_r_resp;
  wire [AXI_ID_WIDTH-1:0]           cpu_r_id;
  wire                              cpu_r_last;
  wire                              cpu_r_valid;
  wire                              cpu_r_ready;

  // 扫描输出读通道
  wire [AXI_ADDR_WIDTH-1:0]         scan_ar_addr;
  wire [7:0]                        scan_ar_len;
  wire [2:0]                        scan_ar_size;
  wire [1:0]                        scan_ar_burst;
  wire                              scan_ar_valid;
  wire                              scan_ar_ready;
  wire [AXI_DATA_WIDTH-1:0]         scan_r_data;
  wire [1:0]                        scan_r_resp;
  wire                              scan_r_last;
  wire                              scan_r_valid;
  wire                              scan_r_ready;
  wire                              scan_hold;      // 扫描输出整行取数中（钉住读通道归属）

  //==================== APB slave 0（加速器寄存器窗口，0xF8100000）====================
  // 注意：这几个网线在本文件里原先**没有声明**，Verilog 会把它们当成 1 位隐式线网，
  //       于是 PADDR/PWDATA/PRDATA 全被截断（原 demo 的 apb3_top 只用到 1 位数据，
  //       且其 sig 输出悬空，所以这个坑一直没暴露）。接加速器前必须显式声明。
  wire [31:0]                       apb_paddr;
  wire [0:0]                        apb_psel;
  wire                              apb_penable;
  wire                              apb_pwrite;
  wire [31:0]                       apb_pwdata;
  wire [31:0]                       apb_prdata;
  wire                              apb_pready;
  wire                              apb_pslverror;

  //==================== BitBlt 2D 加速器接线（须在例化之前声明）====================
  // 读通道改成两级仲裁：L1 = CPU / BitBlt → L2 = (L1) / 扫描输出
  //   优先级：扫描输出 > BitBlt > CPU（扫描输出必须最高，防显示断流）
  wire [AXI_ADDR_WIDTH-1:0]         m1_ar_addr;
  wire [7:0]                        m1_ar_len;
  wire [2:0]                        m1_ar_size;
  wire [1:0]                        m1_ar_burst;
  wire [AXI_ID_WIDTH-1:0]           m1_ar_id;
  wire                              m1_ar_valid;
  wire                              m1_ar_ready;
  wire [AXI_DATA_WIDTH-1:0]         m1_r_data;
  wire [1:0]                        m1_r_resp;
  wire [AXI_ID_WIDTH-1:0]           m1_r_id;
  wire                              m1_r_last;
  wire                              m1_r_valid;
  wire                              m1_r_ready;

  // BitBlt 引擎读主机（源/背景搬运）
  wire [AXI_ADDR_WIDTH-1:0]         blt_ar_addr;
  wire [7:0]                        blt_ar_len;
  wire [2:0]                        blt_ar_size;
  wire [1:0]                        blt_ar_burst;
  wire                              blt_ar_valid;
  wire                              blt_ar_ready;
  wire [AXI_DATA_WIDTH-1:0]         blt_r_data;
  wire [1:0]                        blt_r_resp;
  wire                              blt_r_last;
  wire                              blt_r_valid;
  wire                              blt_r_ready;

  // CPU 写通道（接 soc io_ddrA_aw/w/b，经写仲裁器共享 DDR 写口）
  wire [AXI_ADDR_WIDTH-1:0]         cpu_aw_addr;
  wire [7:0]                        cpu_aw_len;
  wire [2:0]                        cpu_aw_size;
  wire [1:0]                        cpu_aw_burst;
  wire [AXI_ID_WIDTH-1:0]           cpu_aw_id;
  wire                              cpu_aw_valid;
  wire                              cpu_aw_ready;
  wire [AXI_DATA_WIDTH-1:0]         cpu_w_data;
  wire [(AXI_DATA_WIDTH/8)-1:0]     cpu_w_strb;
  wire                              cpu_w_last;
  wire                              cpu_w_valid;
  wire                              cpu_w_ready;
  wire                              cpu_b_valid;
  wire [1:0]                        cpu_b_resp;
  wire [AXI_ID_WIDTH-1:0]           cpu_b_id;
  wire                              cpu_b_ready;

  // BitBlt 引擎写主机（回写目的）
  wire [AXI_ADDR_WIDTH-1:0]         blt_aw_addr;
  wire [7:0]                        blt_aw_len;
  wire [2:0]                        blt_aw_size;
  wire [1:0]                        blt_aw_burst;
  wire                              blt_aw_valid;
  wire                              blt_aw_ready;
  wire [AXI_DATA_WIDTH-1:0]         blt_w_data;
  wire [(AXI_DATA_WIDTH/8)-1:0]     blt_w_strb;
  wire                              blt_w_last;
  wire                              blt_w_valid;
  wire                              blt_w_ready;
  wire                              blt_b_valid;
  wire [1:0]                        blt_b_resp;
  wire                              blt_b_ready;
  wire                              blt_irq_done;      // 引擎完成中断（可接 PLIC，当前仅引出）
  /* 扫描输出健康度（fb_scanout → 加速器寄存器 0x20 只读）：
   * [15:0]=欠载行数 [31:16]=取数看门狗中止次数，正常恒 0。
   * 必须在**两个例化之前**声明（隐式线网只有 1 位会截断 16 位）。 */
  wire [15:0]                       scan_underrun;
  wire [15:0]                       scan_abort;
  /* ★ 显示缓冲翻转（FLIP）：加速器寄存器块 0x24/0x28 ↔ fb_scanout 的
   *   fb_sel/fb_cur_sel/frame_cnt。两个例化（u_blt / u_fb_scanout）都在本文件内，
   *   所以**不需要动 Interface Designer / SoC IP**，直接在这里点对点连线即可。
   *   同样必须在两个例化之前声明（隐式线网会截断位宽）。
   *   ★v2.7：选择位 1 bit → 2 bit（三缓冲 FB0/FB1/FB2）；新增帧边界脉冲 frame_pulse，
   *   它同时喂给加速器中断块（IRQ_STATUS bit1，1 拍脉冲/场）。 */
  wire [1:0]                        fb_flip_sel;      // core 域：0x24 写下的请求（0/1/2）
  wire [1:0]                        fb_flip_cur;      // core 域：已生效的显示缓冲选择
  wire [15:0]                       fb_flip_fcnt;     // core 域：扫描输出场计数
  wire                              fb_frame_pulse;   // core 域：帧边界 1 拍脉冲
  /* ★S5（v3.2）扫描输出颜色 LUT：加速器寄存器块 0xA4~0xB0 ↔ fb_scanout 的 LUT 写口/
   *   bank 请求/已生效 bank。与 FLIP 同一套直连方式（两个例化都在本文件内 ⇒ 不动 SoC IP）。
   *   同样必须在两个例化之前声明（隐式线网会截断位宽）。 */
  wire                              lut_wr;          // 0xA8 写脉冲（1 拍，core 域）
  wire [1:0]                        lut_ch;          // 0=A 1=G 2=B
  wire [7:0]                        lut_idx;         // 表内下标
  wire [7:0]                        lut_data;        // 写入值
  wire                              lut_en;          // 0xAC bit0（请求）
  wire                              lut_bank_req;    // 0xAC bit1（请求）
  wire                              lut_bank_act;    // 0xB0 bit0：已生效 bank

  // 视频侧信号
  wire [7:0]                        vid_r, vid_g, vid_b;
  wire                              vid_de, vid_hs, vid_vs;
  wire [9:0]                        tmds_d0, tmds_d1, tmds_d2, tmds_ck;
  reg  [2:0]                        prst_sync;
  wire                              hdmi_prst_n;
  assign hdmi_prst_n = prst_sync[2];


//***************************************************************************
  wire [2:0]                        vio_pll_shift;  
  wire [4:0]                        vio_pll_shift_sel;
  wire                              vio_pll_shift_ena; 
  wire                              pos_pll_shift_ena; 
  wire [2:0]                        phy_pll_shift;  
  wire [4:0]                        phy_pll_shift_sel;
  wire                              phy_pll_shift_ena; 
  wire                              ddr_reset; 
  wire                              sys_rst;
  wire  [2:0]                       phy_wr_pll_shift;
  wire                              idelay_ld       ;
  wire                              mpr_rdlvl_dly   ;
  wire  [7:0]                       wrlvl_dq_check  ;
  wire  [7:0]                       rd_level_dqs_check;  
  wire  [2:0]                       rdlvl_shift;  
  wire  [2:0]                       wrlvl_shift;  
  wire  [15:0]                      debug_fifo;  
  wire  [15:0]                      overflow_fifo;  
  wire  [6:0]                       init_cur_state;  
  wire  [35:0]                      ddr_debug_port;  
  wire                              app_rdy;  
  wire                              user_clk;  
  wire                              ddr_rstn;  
  wire                                phy_rddata_valid;
  wire [2*CK_RATIO*DQ_WIDTH-1:0]      phy_rd_data;
  wire [2*CK_RATIO*DATA_WIDTH-1:0]    app_rd_data_to_axi; 
  wire                                app_rd_data_end;
  wire                                app_rd_data_valid;
  wire [2*CK_RATIO*DQ_WIDTH-1:0]      rd_data;          
  wire                                rd_data_en;            
  wire                                rd_data_end;   
   
  
// Start of User Design top instance
//***************************************************************************
// The User design is instantiated below. The memory interface ports are
// connected to the top-level and the application interface ports are
// connected to the traffic generator module. This provides a reference
// for connecting the memory controller to system.
//***************************************************************************
always @(posedge user_clk or negedge sys_rst) begin
	if (!sys_rst)
		cnt <= 0;
    else if (cnt != CNT_INIT) 
        cnt <= cnt + 20'd1;
	else 
        cnt <= cnt;
end
assign ddr_rstn = (cnt == CNT_INIT);


generate
if (ASYN_AXI_CLK) begin
assign user_clk = axi_clk;

end else begin
assign user_clk = core_clk;
end
endgenerate
//***************************************************************************
// The traffic generation module instantiated below drives traffic (patterns)
// on the application interface of the memory controller
//***************************************************************************
//***************************************************************************

assign sys_rst       = pll_locked & user_pll_locked;

//***************************************************************************
ddr3_top                 u_ddr3_top
      (
      
    .axi_clk                (user_clk             ),
    .core_clk               (core_clk            ),
    .sdram_clk              (sdram_clk           ),  
    .rx_cal_clk             (rx_cal_clk          ),
    .tx_cal_clk             (tx_cal_clk          ),
    .tx_cal_clk_90edge      (tx_cal_clk_90edge   ),
    .rstn                   (ddr_rstn            ),      
    .pll_shift              (pll_shift           ),
    .pll_shift_sel          (pll_shift_sel       ),
    .pll_shift_ena          (pll_shift_ena       ), 
///////////////DDR BUS
    .ddr_ck_hi              (ddr_ck_hi           ),
    .ddr_ck_lo              (ddr_ck_lo           ),
    .ddr_cke                (ddr_cke             ),    
    .ddr_reset_n            (ddr_reset_n         ),
    .ddr_cs_n               (ddr_cs_n            ),
    .ddr_ras_n              (ddr_ras_n           ),
    .ddr_cas_n              (ddr_cas_n           ),
    .ddr_we_n               (ddr_we_n            ),     
    .ddr_addr               (ddr_addr            ),
    .ddr_ba                 (ddr_ba              ),

    .ddr_dqs_oe             (ddr_dqs_oe          ),
    .ddr_dqs_oe_n           (ddr_dqs_oe_n        ),
    .ddr_dq_oe              (ddr_dq_oe           ),
    .ddr_dqs_in_hi          (ddr_dqs_in_hi       ),
    .ddr_dqs_in_lo          (ddr_dqs_in_lo       ),
    .ddr_dq_in_hi           (ddr_dq_in_hi        ),
    .ddr_dq_in_lo           (ddr_dq_in_lo        ),

    .ddr_dqs_out_hi         (ddr_dqs_out_hi      ),
    .ddr_dqs_out_lo         (ddr_dqs_out_lo      ),
    .ddr_dq_out_hi          (ddr_dq_out_hi       ),
    .ddr_dq_out_lo          (ddr_dq_out_lo       ),
    
    .ddr_dm_hi              (ddr_dm_hi           ),
    .ddr_dm_lo              (ddr_dm_lo           ),
    .ddr_odt                (ddr_odt             ),

// Application interface ports
       .app_sr_req                     (1'b0),
       .app_ref_req                    (1'b0),
       .app_zq_req                     (1'b0),
       .app_sr_active                  (app_sr_active),
       .app_ref_ack                    (app_ref_ack),
       .app_zq_ack                     (app_zq_ack),

// Slave Interface Write Address Ports
       .s_axi_awid                     (s_axi_awid        ),
       .s_axi_awaddr                   (s_axi_awaddr      ),
       .s_axi_awlen                    (s_axi_awlen       ),
       .s_axi_awsize                   (s_axi_awsize      ),
       .s_axi_awburst                  (s_axi_awburst     ),
       .s_axi_awlock                   (s_axi_awlock      ),
       .s_axi_awcache                  (s_axi_awcache     ),
       .s_axi_awprot                   (s_axi_awprot      ),
       .s_axi_awqos                    (4'h0              ),
       .s_axi_awvalid                  (s_axi_awvalid     ),
       .s_axi_awready                  (s_axi_awready     ),
// Slave Interface Write Data Ports
       .s_axi_wdata                    (s_axi_wdata       ),
       .s_axi_wstrb                    (s_axi_wstrb       ),
       .s_axi_wlast                    (s_axi_wlast       ),
       .s_axi_wvalid                   (s_axi_wvalid      ),
       .s_axi_wready                   (s_axi_wready      ),
// Slave Interface Write Response Ports
       .s_axi_bid                      (s_axi_bid         ),
       .s_axi_bresp                    (s_axi_bresp       ),
       .s_axi_bvalid                   (s_axi_bvalid      ),
       .s_axi_bready                   (s_axi_bready      ),
// Slave Interface Read Address Ports
       .s_axi_arid                     (s_axi_arid        ),
       .s_axi_araddr                   (s_axi_araddr      ),
       .s_axi_arlen                    (s_axi_arlen       ),
       .s_axi_arsize                   (s_axi_arsize      ),
       .s_axi_arburst                  (s_axi_arburst     ),
       .s_axi_arlock                   (s_axi_arlock      ),
       .s_axi_arcache                  (s_axi_arcache     ),
       .s_axi_arprot                   (s_axi_arprot      ),
       .s_axi_arqos                    (4'h0              ),
       .s_axi_arvalid                  (s_axi_arvalid     ),
       .s_axi_arready                  (s_axi_arready     ),
// Slave Interface Read Data Ports
       .s_axi_rid                      (s_axi_rid         ),
       .s_axi_rdata                    (s_axi_rdata       ),
       .s_axi_rresp                    (s_axi_rresp       ),
       .s_axi_rlast                    (s_axi_rlast       ),
       .s_axi_rvalid                   (s_axi_rvalid      ),
       .s_axi_rready                   (s_axi_rready      ),
//DEBUG       
       .wrlvl_dq_check                 (wrlvl_dq_check    ) ,
       .rd_level_dqs_check             (rd_level_dqs_check) ,
       .rdlvl_shift                    (rdlvl_shift) ,
       .wrlvl_shift                    (wrlvl_shift) ,
       .init_cur_state                 (init_cur_state    ) ,
       .idelay_ld                      (idelay_ld         ) ,
       .mpr_rdlvl_dly                  (mpr_rdlvl_dly     ) ,
       .ddr_debug_port                 (ddr_debug_port    ) ,
       .cal_done                       (cal_done          ) 
       );
// End of User Design top instance

//***************************************************************************


//***************************************************************************
soc u_sapphire_soc(
    .io_asyncReset                      (!pll_locked                        ),
    .io_systemClk                       (user_clk                           ),

    //UART 0
    .system_uart_0_io_txd               (system_uart_0_io_txd               ),
    .system_uart_0_io_rxd               (system_uart_0_io_rxd               ),
    .io_memoryClk                       (user_clk                           ),
    .io_memoryReset                     (                                   ),
    .io_systemReset                     (                                   ),
    //External Memory AXI4 Interface
    .io_ddrA_aw_payload_prot            (                                  ),//(                                  ),
    .io_ddrA_aw_payload_qos             (                                  ),//(                                  ),
    .io_ddrA_aw_payload_cache           (                                  ),//(                                  ),
    .io_ddrA_aw_payload_lock            (s_axi_awlock                     ),//(m1_axi_awlock                     ),
    .io_ddrA_aw_payload_burst           (cpu_aw_burst                     ),//(m1_axi_awburst                    ),
    .io_ddrA_aw_payload_size            (cpu_aw_size                      ),//(m1_axi_awsize                     ),
    .io_ddrA_aw_payload_len             (cpu_aw_len                       ),//(m1_axi_awlen                      ),
    .io_ddrA_aw_payload_region          (                                 ),//(                                  ),
    .io_ddrA_aw_payload_id              (cpu_aw_id                        ),//(m1_axi_awid                       ),
    .io_ddrA_aw_payload_addr            (cpu_aw_addr                      ),//(m1_axi_awaddr                     ),
    .io_ddrA_aw_ready                   (cpu_aw_ready                     ),//(m1_axi_awready                    ),
    .io_ddrA_aw_valid                   (cpu_aw_valid                     ),//(m1_axi_awvalid                    ),
    .io_ddrA_w_payload_last             (cpu_w_last                       ),//(m1_axi_wlast                      ),
    .io_ddrA_w_ready                    (cpu_w_ready                      ),//(m1_axi_wready                     ),
    .io_ddrA_w_valid                    (cpu_w_valid                      ),  //(m1_axi_wvalid                     ),    
    .io_ddrA_w_payload_strb             (cpu_w_strb                       ),//(m1_axi_wstrb                      ),
    .io_ddrA_w_payload_data             (cpu_w_data                       ),//(m1_axi_wdata                      ),
    .io_ddrA_b_payload_resp             (                                 ),//(                                  ),
    .io_ddrA_b_payload_id               (cpu_b_id                         ),//(m1_axi_bid                        ),
    .io_ddrA_b_ready                    (cpu_b_ready                      ),//(m1_axi_bready                     ),
    .io_ddrA_b_valid                    (cpu_b_valid                      ),//(m1_axi_bvalid                     ),
    .io_ddrA_ar_payload_prot            (                                 ),//(                                  ),
    .io_ddrA_ar_payload_qos             (                                 ),//(                                  ),
    .io_ddrA_ar_payload_cache           (                                 ),//(                                  ),
    .io_ddrA_ar_payload_region          (                                 ),//(                                  ),
    .io_ddrA_ar_payload_lock            (cpu_ar_lock                      ),//(m1_axi_arlock                     ),
    .io_ddrA_ar_payload_burst           (cpu_ar_burst                     ),//(m1_axi_arburst                    ),
    .io_ddrA_ar_payload_size            (cpu_ar_size                      ),//(m1_axi_arsize                     ),
    .io_ddrA_ar_payload_len             (cpu_ar_len                       ),//(m1_axi_arlen                      ),
    .io_ddrA_ar_payload_id              (cpu_ar_id                        ),//(m1_axi_arid                       ),
    .io_ddrA_ar_payload_addr            (cpu_ar_addr                      ),//(m1_axi_araddr                     ),
    .io_ddrA_ar_ready                   (cpu_ar_ready                     ),//(m1_axi_arready                    ),
    .io_ddrA_ar_valid                   (cpu_ar_valid                     ),//(m1_axi_arvalid                    ),
    .io_ddrA_r_payload_last             (cpu_r_last                       ),//(m1_axi_rlast                      ),
    .io_ddrA_r_payload_resp             (cpu_r_resp                       ),//(m1_axi_rresp                      ),
    .io_ddrA_r_payload_id               (cpu_r_id                         ),//(m1_axi_rid                        ),
    .io_ddrA_r_payload_data             (cpu_r_data                       ),//(m1_axi_rdata                      ),
    .io_ddrA_r_ready                    (cpu_r_ready                      ),//(m1_axi_rready                     ),
    .io_ddrA_r_valid                    (cpu_r_valid                      ),//(m1_axi_rvalid                     ),
     //SPI 0
    .system_spi_0_io_sclk_write         (system_spi_0_io_sclk_write         ),
    .system_spi_0_io_data_0_writeEnable (system_spi_0_io_data_0_OE ),
    .system_spi_0_io_data_0_read        (system_spi_0_io_data_0_IN        ),
    .system_spi_0_io_data_0_write       (system_spi_0_io_data_0_OUT       ),
    .system_spi_0_io_data_1_writeEnable (system_spi_0_io_data_1_OE ),
    .system_spi_0_io_data_1_read        (system_spi_0_io_data_1_IN        ),
    .system_spi_0_io_data_1_write       (system_spi_0_io_data_1_OUT       ),
    .system_spi_0_io_data_2_writeEnable (                                   ),
    .system_spi_0_io_data_2_read        (                                   ),
    .system_spi_0_io_data_2_write       (                                   ),
    .system_spi_0_io_data_3_writeEnable (                                   ),
    .system_spi_0_io_data_3_read        (                                   ),
    .system_spi_0_io_data_3_write       (                                   ),
    .system_spi_0_io_ss                 (system_spi_0_io_ss                 ),
    //APB 0
    .io_apbSlave_0_PADDR                (apb_paddr                          ),
    .io_apbSlave_0_PSEL                 (apb_psel                           ),
    .io_apbSlave_0_PENABLE              (apb_penable                        ),
    .io_apbSlave_0_PREADY               (apb_pready                         ),
    .io_apbSlave_0_PWRITE               (apb_pwrite                         ),
    .io_apbSlave_0_PWDATA               (apb_pwdata                         ),
    .io_apbSlave_0_PRDATA               (apb_prdata                         ),
    .io_apbSlave_0_PSLVERROR            (apb_pslverror                      ),

    .system_gpio_0_io_write             ( soc_gpio_OUT                      ),//,
    .system_gpio_0_io_read              ( soc_gpio_IN                       ),//
    .system_gpio_0_io_writeEnable       ( soc_gpio_OE                       ),//, 


    //Hard Jtag Tap
    .jtagCtrl_tck                       (jtag_inst1_TCK                     ),
    .jtagCtrl_tdi                       (jtag_inst1_TDI                     ),
    .jtagCtrl_tdo                       (jtag_inst1_TDO                     ),
    .jtagCtrl_enable                    (jtag_inst1_SEL                     ),
    .jtagCtrl_capture                   (jtag_inst1_CAPTURE                 ),
    .jtagCtrl_shift                     (jtag_inst1_SHIFT                   ),
    .jtagCtrl_update                    (jtag_inst1_UPDATE                  ),
    .jtagCtrl_reset                     (jtag_inst1_RESET                   ),

    /* ★v2.7：把加速器的中断线真正接进 SoC（soc.v 的 userInterruptA → PLIC 源，claim ID = 0x10）。
     *   默认**不改变任何行为**：IRQ_EN 复位为 0，而 IRQ_STATUS 的置位都以使能为条件
     *   ⇒ irq_done 恒 0，PLIC 那边 IE 也默认 0。只有软件主动开 IRQ_EN[0]/[1] 才会来中断。 */
    .userInterruptA                     (blt_irq_done                       )
);


/* ---- BitBlt 2D 加速器：APB slave 0（0xF8100000）寄存器口 + DDR AXI 主机 ----
 * 替换掉原 demo 的 apb3_top（那个只是中断演示外设，其 sig 输出在本工程未使用）。
 * 软件侧用 *(volatile uint32_t*)(0xF8100000 + off) 读写寄存器、下发渲染指令。 */
blt_apb_top #(.AXI_DATA_W(AXI_DATA_WIDTH), .CMD_DEPTH(256)) u_blt (
    .clk                                (user_clk                           ),
    .reset                              (!ddr_rstn                          ),
    .apb_paddr                          (apb_paddr                          ),
    .apb_psel                           (apb_psel                           ),
    .apb_penable                        (apb_penable                        ),
    .apb_pready                         (apb_pready                         ),
    .apb_pwrite                         (apb_pwrite                         ),
    .apb_pwdata                         (apb_pwdata                         ),
    .apb_prdata                         (apb_prdata                         ),
    .apb_pslverror                      (apb_pslverror                      ),
    .irq_done                           (blt_irq_done                       ),
    .scan_underrun                      (scan_underrun                      ),
    .scan_abort                         (scan_abort                         ),
    /* FLIP：0x24 写请求 → u_fb_scanout.fb_sel；u_fb_scanout 的已生效选择与场计数 → 0x28 */
    .fb_sel                             (fb_flip_sel                        ),
    .fb_cur_sel                         (fb_flip_cur                        ),
    .fb_frame_cnt                       (fb_flip_fcnt                       ),
    /* ★v2.7：帧边界脉冲 → 加速器中断块 IRQ_STATUS[1]（W1C）/ IRQ_EN[1] */
    .frame_pulse                        (fb_frame_pulse                     ),
    /* ★S5（v3.2）扫描输出颜色 LUT：0xA4~0xB0 ↔ u_fb_scanout 的 LUT 口 */
    .lut_wr                             (lut_wr                             ),
    .lut_ch                             (lut_ch                             ),
    .lut_idx                            (lut_idx                            ),
    .lut_data                           (lut_data                           ),
    .lut_en                             (lut_en                             ),
    .lut_bank_req                       (lut_bank_req                       ),
    .lut_bank_act                       (lut_bank_act                       ),
    /* 读主机（源/背景） */
    .m_axi_araddr                       (blt_ar_addr                        ),
    .m_axi_arlen                        (blt_ar_len                         ),
    .m_axi_arsize                       (blt_ar_size                        ),
    .m_axi_arburst                      (blt_ar_burst                       ),
    .m_axi_arvalid                      (blt_ar_valid                       ),
    .m_axi_arready                      (blt_ar_ready                       ),
    .m_axi_rdata                        (blt_r_data                         ),
    .m_axi_rresp                        (blt_r_resp                         ),
    .m_axi_rlast                        (blt_r_last                         ),
    .m_axi_rvalid                       (blt_r_valid                        ),
    .m_axi_rready                       (blt_r_ready                        ),
    /* 写主机（回写目的） */
    .m_axi_awaddr                       (blt_aw_addr                        ),
    .m_axi_awlen                        (blt_aw_len                         ),
    .m_axi_awsize                       (blt_aw_size                        ),
    .m_axi_awburst                      (blt_aw_burst                       ),
    .m_axi_awvalid                      (blt_aw_valid                       ),
    .m_axi_awready                      (blt_aw_ready                       ),
    .m_axi_wdata                        (blt_w_data                         ),
    .m_axi_wstrb                        (blt_w_strb                         ),
    .m_axi_wlast                        (blt_w_last                         ),
    .m_axi_wvalid                       (blt_w_valid                        ),
    .m_axi_wready                       (blt_w_ready                        ),
    .m_axi_bvalid                       (blt_b_valid                        ),
    .m_axi_bresp                        (blt_b_resp                         ),
    .m_axi_bready                       (blt_b_ready                        )
);

/* ============================================================================
 * DDR AXI 口仲裁（三个读主机、两个写主机 → DDR 控制器单口）
 *   读：L1 = CPU / BitBlt → L2 = (L1) / 扫描输出   ⇒ 优先级 扫描 > BitBlt > CPU
 *   写：CPU / BitBlt（B 响应按 owner 分路，突发未收完不切换）
 * ========================================================================= */
// ---- 读 L1：CPU 与 BitBlt（BitBlt 侧为 "S"，即 BitBlt 优先于 CPU）----
axi_rd_arb #(.AW(AXI_ADDR_WIDTH), .DW(AXI_DATA_WIDTH), .IDW(AXI_ID_WIDTH)) u_rd_arb_l1 (
    .clk        (user_clk), .rst_n(ddr_rstn),
    .c_araddr   (cpu_ar_addr),  .c_arlen(cpu_ar_len),  .c_arsize(cpu_ar_size),
    .c_arburst  (cpu_ar_burst), .c_arid (cpu_ar_id),   .c_arvalid(cpu_ar_valid),
    .c_arready  (cpu_ar_ready),
    .c_rdata    (cpu_r_data),   .c_rresp(cpu_r_resp),  .c_rid(cpu_r_id),
    .c_rlast    (cpu_r_last),   .c_rvalid(cpu_r_valid), .c_rready(cpu_r_ready),
    .s_araddr   (blt_ar_addr),  .s_arlen(blt_ar_len),  .s_arsize(blt_ar_size),
    .s_arburst  (blt_ar_burst), .s_arvalid(blt_ar_valid), .s_arready(blt_ar_ready),
    .s_hold     (1'b0),                      // 引擎不提供"整行钉住"（它按信用突发）
    .s_rdata    (blt_r_data),   .s_rresp(blt_r_resp),  .s_rlast(blt_r_last),
    .s_rvalid   (blt_r_valid),  .s_rready(blt_r_ready),
    .m_araddr   (m1_ar_addr),   .m_arlen(m1_ar_len),   .m_arsize(m1_ar_size),
    .m_arburst  (m1_ar_burst),  .m_arid (m1_ar_id),    .m_arvalid(m1_ar_valid),
    .m_arready  (m1_ar_ready),
    .m_rdata    (m1_r_data),    .m_rresp(m1_r_resp),   .m_rid(m1_r_id),
    .m_rlast    (m1_r_last),    .m_rvalid(m1_r_valid), .m_rready(m1_r_ready)
);

// ---- 写：CPU 与 BitBlt（CPU 侧直通；引擎空闲时与"CPU 直连 DDR"完全等价）----
axi_wr_arb #(.AW(AXI_ADDR_WIDTH), .DW(AXI_DATA_WIDTH), .IDW(AXI_ID_WIDTH)) u_wr_arb (
    .clk        (user_clk), .rst_n(ddr_rstn),
    .c_awaddr   (cpu_aw_addr),  .c_awlen(cpu_aw_len),  .c_awsize(cpu_aw_size),
    .c_awburst  (cpu_aw_burst), .c_awid (cpu_aw_id),   .c_awvalid(cpu_aw_valid),
    .c_awready  (cpu_aw_ready),
    .c_wdata    (cpu_w_data),   .c_wstrb(cpu_w_strb),  .c_wlast(cpu_w_last),
    .c_wvalid   (cpu_w_valid),  .c_wready(cpu_w_ready),
    .c_bvalid   (cpu_b_valid),  .c_bresp(cpu_b_resp),  .c_bid(cpu_b_id),
    .c_bready   (cpu_b_ready),
    .b_awaddr   (blt_aw_addr),  .b_awlen(blt_aw_len),  .b_awsize(blt_aw_size),
    .b_awburst  (blt_aw_burst), .b_awvalid(blt_aw_valid), .b_awready(blt_aw_ready),
    .b_wdata    (blt_w_data),   .b_wstrb(blt_w_strb),  .b_wlast(blt_w_last),
    .b_wvalid   (blt_w_valid),  .b_wready(blt_w_ready),
    .b_bvalid   (blt_b_valid),  .b_bresp(blt_b_resp),  .b_bready(blt_b_ready),
    .m_awaddr   (s_axi_awaddr), .m_awlen(s_axi_awlen), .m_awsize(s_axi_awsize),
    .m_awburst  (s_axi_awburst), .m_awid(s_axi_awid),  .m_awvalid(s_axi_awvalid),
    .m_awready  (s_axi_awready),
    .m_wdata    (s_axi_wdata),  .m_wstrb(s_axi_wstrb), .m_wlast(s_axi_wlast),
    .m_wvalid   (s_axi_wvalid), .m_wready(s_axi_wready),
    .m_bvalid   (s_axi_bvalid), .m_bresp(s_axi_bresp), .m_bid(s_axi_bid),
    .m_bready   (s_axi_bready)
);

//***************************************************************************
// HDMI 扫描输出通路
//   读通道（CPU/扫描输出/BitBlt 三主机）经两级仲裁共享 DDR 的 AXI 读口；
//   写通道（AW/W/B）经写仲裁器共享（CPU/BitBlt）。
//   （所有连线已在模块前部声明）
//***************************************************************************
/* 读地址锁类型由 CPU 直通（仅 CPU 会用到） */
assign s_axi_arlock = cpu_ar_lock;
assign s_axi_arprot = 3'b000;
assign s_axi_arcache= 4'b0000;

/* 像素域复位：随 hdmi_tx_locked 异步复位、同步释放 */
always @(posedge hdmi_tx_slow_clk or negedge hdmi_tx_locked) begin
    if (!hdmi_tx_locked)
        prst_sync <= 3'b000;
    else
        prst_sync <= {prst_sync[1:0], 1'b1};
end

/* 扫描输出健康度接到加速器寄存器窗口的 0x20（见 blt_regs_axi_lite.v）：
 * 软件读 0xF8100000+0x20 即可量化"显示是否被 DDR 竞争拖垮"。 */

/* ---- 帧缓冲扫描输出：960×540 窗口 + 黑边，1080p@60 时序 ----
 * ★ v2.6：显示基址由 FB_BASE/FB_BASE1 两个**参数**给出，fb_sel 在帧边界二选一。
 *   FB_BASE1 = 0x501000 = 软件侧 FB_BACK（两个缓冲都在 DDR 里，互不重叠）。
 * ★ v2.7：三缓冲 —— 再加 FB_BASE2 = 0x701000（软件侧 FB_BUF2）；fb_sel 变 2 bit，
 *   基址由 fb_scanout 里的 base_of_sel() 查表给出（地址仍然全是参数，没写死）。 */
fb_scanout #(
    .FB_BASE  (32'h0030_1000),   // = DDR_BASE(0x1000) + 0x300000，与软件侧 FB_BASE 一致
    .FB_BASE1 (32'h0050_1000),   // = DDR_BASE(0x1000) + 0x500000，与软件侧 FB_BACK 一致
    .FB_BASE2 (32'h0070_1000),   // = DDR_BASE(0x1000) + 0x700000，与软件侧 FB_BUF2 一致
    .FB_STRIDE(32'd1920),        // 960*2
    .FB_W     (12'd960),
    .FB_H     (12'd540),
    .WIN_X    (12'd0),
    .WIN_Y    (12'd0)
) u_fb_scanout (
    .clk                    (user_clk           ),
    .rst_n                  (ddr_rstn           ),
    .fb_sel                 (fb_flip_sel        ),
    .fb_cur_sel             (fb_flip_cur        ),
    .frame_cnt              (fb_flip_fcnt       ),
    .frame_pulse            (fb_frame_pulse     ),
    /* ★S5（v3.2）扫描输出颜色 LUT（3 通道 × 2 bank × 256 项，8bit in/out）：
     *   写口在 core 域，读口在 pclk 域；bank/使能在**帧边界**锁存（见 fb_scanout.v）。 */
    .lut_wr                 (lut_wr             ),
    .lut_ch                 (lut_ch             ),
    .lut_idx                (lut_idx            ),
    .lut_data               (lut_data           ),
    .lut_en                 (lut_en             ),
    .lut_bank_req           (lut_bank_req       ),
    .lut_bank_act           (lut_bank_act       ),
    .m_axi_araddr           (scan_ar_addr       ),
    .m_axi_arlen            (scan_ar_len        ),
    .m_axi_arsize           (scan_ar_size       ),
    .m_axi_arburst          (scan_ar_burst      ),
    .m_axi_arid             (                   ),
    .m_axi_arvalid          (scan_ar_valid      ),
    .m_axi_arready          (scan_ar_ready      ),
    .m_axi_rdata            (scan_r_data        ),
    .m_axi_rresp            (scan_r_resp        ),
    .m_axi_rid              (4'h1               ),
    .m_axi_rlast            (scan_r_last        ),
    .m_axi_rvalid           (scan_r_valid       ),
    .m_axi_rready           (scan_r_ready       ),
    .m_axi_hold             (scan_hold          ),
    .pclk                   (hdmi_tx_slow_clk   ),
    .prst_n                 (hdmi_prst_n        ),
    .vde                    (vid_de             ),
    .vhs                    (vid_hs             ),
    .vvs                    (vid_vs             ),
    .vr                     (vid_r              ),
    .vg                     (vid_g              ),
    .vb                     (vid_b              ),
    .frame_tick             (                   ),
    .dbg_line               (                   ),
    .dbg_underrun           (scan_underrun      ),
    .dbg_abort              (scan_abort         )
);

/* ---- 读 L2：(CPU/BitBlt) 与 扫描输出（扫描输出为 "S"，即最高优先）
 *      S_PRIO 暂时关掉（=0，回到 20:59 那次**已知可启动**的让位行为）。
 *      原因：仿真证明开了 S_PRIO 之后，一旦 CPU 也在猛读 DDR，扫描输出的
 *      arvalid 会在本行中途因 AR_OUT 额度用尽而落下，通道随即被 CPU 抢走、
 *      再也抢不回来（48000 周期只取到 11 行，需要 ~240 行）→ 画面卡死。
 *      等板子先能起来，再按"有界优先 + 整行钉住"重做（见 功能清单 §13）。 */
axi_rd_arb #(.AW(AXI_ADDR_WIDTH), .DW(AXI_DATA_WIDTH), .IDW(AXI_ID_WIDTH), .S_PRIO(0)) u_axi_rd_arb (
    .clk                    (user_clk           ),
    .rst_n                  (ddr_rstn           ),
    /* L1 汇总侧（CPU + BitBlt） */
    .c_araddr               (m1_ar_addr         ),
    .c_arlen                (m1_ar_len          ),
    .c_arsize               (m1_ar_size         ),
    .c_arburst              (m1_ar_burst        ),
    .c_arid                 (m1_ar_id           ),
    .c_arvalid              (m1_ar_valid        ),
    .c_arready              (m1_ar_ready        ),
    .c_rdata                (m1_r_data          ),
    .c_rresp                (m1_r_resp          ),
    .c_rid                  (m1_r_id            ),
    .c_rlast                (m1_r_last          ),
    .c_rvalid               (m1_r_valid         ),
    .c_rready               (m1_r_ready         ),
    /* 扫描输出侧 */
    .s_araddr               (scan_ar_addr       ),
    .s_arlen                (scan_ar_len        ),
    .s_arsize               (scan_ar_size       ),
    .s_arburst              (scan_ar_burst      ),
    .s_arvalid              (scan_ar_valid      ),
    .s_arready              (scan_ar_ready      ),
    .s_hold                 (scan_hold          ),   // 扫描输出整行取数期间钉住归属
    .s_rdata                (scan_r_data        ),
    .s_rresp                (scan_r_resp        ),
    .s_rlast                (scan_r_last        ),
    .s_rvalid               (scan_r_valid       ),
    .s_rready               (scan_r_ready       ),
    /* DDR 控制器 AXI 从口（读） */
    .m_araddr               (s_axi_araddr       ),
    .m_arlen                (s_axi_arlen        ),
    .m_arsize               (s_axi_arsize       ),
    .m_arburst              (s_axi_arburst      ),
    .m_arid                 (s_axi_arid         ),
    .m_arvalid              (s_axi_arvalid      ),
    .m_arready              (s_axi_arready      ),
    .m_rdata                (s_axi_rdata        ),
    .m_rresp                (s_axi_rresp        ),
    .m_rid                  (s_axi_rid          ),
    .m_rlast                (s_axi_rlast        ),
    .m_rvalid               (s_axi_rvalid       ),
    .m_rready               (s_axi_rready       )
);

/* ---- TMDS 编码（直接复用板卡 demo 的 dvi_encoder，未做任何修改） ---- */
dvi_encoder u_dvi_encoder (
    .pixelclk               (hdmi_tx_slow_clk   ),
    .rstin                  (~hdmi_prst_n       ),
    .blue_din               (vid_b              ),
    .green_din              (vid_g              ),
    .red_din                (vid_r              ),
    .hsync                  (vid_hs             ),
    .vsync                  (vid_vs             ),
    .de                     (vid_de             ),
    .tmds_data0             (tmds_d0            ),
    .tmds_data1             (tmds_d1            ),
    .tmds_data2             (tmds_d2            ),
    .tmds_clk               (tmds_ck            )
);

assign tmds_clk_o   = ~tmds_ck;
assign tmds_data0_o = ~tmds_d0;
assign tmds_data1_o = ~tmds_d1;
assign tmds_data2_o = ~tmds_d2;

assign tmds_clk_TX_OE    = 1'b1;
assign tmds_data0_TX_OE  = 1'b1;
assign tmds_data1_TX_OE  = 1'b1;
assign tmds_data2_TX_OE  = 1'b1;
assign tmds_clk_TX_RST   = 1'b0;
assign tmds_data0_TX_RST = 1'b0;
assign tmds_data1_TX_RST = 1'b0;
assign tmds_data2_TX_RST = 1'b0;

//***************************************************************************

endmodule
