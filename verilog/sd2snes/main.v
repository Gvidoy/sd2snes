`timescale 1 ns / 1 ns
//////////////////////////////////////////////////////////////////////////////////
// Company: Rehkopf
// Engineer: Rehkopf
//
// Create Date:    01:13:46 05/09/2009
// Design Name:
// Module Name:    main
// Project Name:
// Target Devices:
// Tool versions:
// Description: Master Control FSM
//
// Dependencies: address
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module main(
  /* input clock */
  input CLKIN,
  
  /* SNES signals */
  input [23:0] SNES_ADDR_IN,
  input SNES_READ_IN,
  input SNES_WRITE_IN,
  input SNES_ROMSEL_IN,
  inout [7:0] SNES_DATA,
  input SNES_CPU_CLK_IN,
  input SNES_REFRESH,
  output SNES_IRQ,
  output SNES_DATABUS_OE,
  output SNES_DATABUS_DIR,
  input SNES_SYSCLK,

  input [7:0] SNES_PA_IN,
  input SNES_PARD_IN,
  input SNES_PAWR_IN,

  /* SRAM signals */
  /* Bus 1: PSRAM, 128Mbit, 16bit, 70ns */
  inout [15:0] ROM_DATA,
  output [22:0] ROM_ADDR,
  output ROM_CE,
  output ROM_OE,
  output ROM_WE,
  output ROM_BHE,
  output ROM_BLE,

  /* Bus 2: SRAM, 4Mbit, 8bit, 45ns */
  inout [7:0] RAM_DATA,
  output [18:0] RAM_ADDR,
  output RAM_CE,
  output RAM_OE,
  output RAM_WE,

  /* MCU signals */
  input SPI_MOSI,
  inout SPI_MISO,
  input SPI_SS,
  inout SPI_SCK,
  input MCU_OVR,
  output MCU_RDY,

  output DAC_MCLK,
  output DAC_LRCK,
  output DAC_SDOUT,

  /* SD signals */
  input [3:0] SD_DAT,
  inout SD_CMD,
  inout SD_CLK,

  /* debug */
  output p113_out
);

`define upper(i) (8*(i+1)-1)
`define lower(i) (8*(i+0)-0)

wire CLK2;

wire dspx_dp_enable;

wire [7:0] spi_cmd_data;
wire [7:0] spi_param_data;
wire [7:0] spi_input_data;
wire [31:0] spi_byte_cnt;
wire [2:0] spi_bit_cnt;
wire [23:0] MCU_ADDR;
wire [2:0] MAPPER;
wire [23:0] SAVERAM_MASK;
wire [23:0] ROM_MASK;
wire [7:0] SD_DMA_SRAM_DATA;
wire [1:0] SD_DMA_TGT;
wire [10:0] SD_DMA_PARTIAL_START;
wire [10:0] SD_DMA_PARTIAL_END;

wire [10:0] dac_addr;
wire [2:0] dac_vol_select_out;
wire [8:0] dac_ptr_addr;
//wire [7:0] dac_volume;
wire [7:0] msu_volumerq_out;
wire [7:0] msu_data;
wire [31:0] msu_scaddr;
wire [7:0] msu_status_out;
wire [31:0] msu_addressrq_out;
wire [15:0] msu_trackrq_out;
wire [14:0] msu_write_addr;
wire [14:0] msu_ptr_addr;
wire [7:0] MSU_SNES_DATA_IN;
wire [7:0] MSU_SNES_DATA_OUT;
wire [5:0] msu_status_reset_bits;
wire [5:0] msu_status_set_bits;

//wire [7:0] USB_SNES_DATA_IN;
//wire [7:0] USB_SNES_DATA_OUT;
//wire [7:0] usb_status_reset_bits;
//wire [7:0] usb_status_set_bits;

wire [7:0] DMA_SNES_DATA_IN;
wire [7:0] DMA_SNES_DATA_OUT;

wire [7:0] CTX_SNES_DATA_IN;

wire [14:0] bsx_regs;
wire [7:0] BSX_SNES_DATA_IN;
wire [7:0] BSX_SNES_DATA_OUT;
wire [7:0] bsx_regs_reset_bits;
wire [7:0] bsx_regs_set_bits;

wire [59:0] rtc_data;
wire [55:0] rtc_data_in;
wire [59:0] srtc_rtc_data_out;
wire [3:0] SRTC_SNES_DATA_IN;
wire [7:0] SRTC_SNES_DATA_OUT;

wire [7:0] DSPX_SNES_DATA_IN;
wire [7:0] DSPX_SNES_DATA_OUT;

wire [23:0] dspx_pgm_data;
wire [10:0] dspx_pgm_addr;
wire dspx_pgm_we;

wire [15:0] dspx_dat_data;
wire [10:0] dspx_dat_addr;
wire dspx_dat_we;

wire [7:0] featurebits;

wire [23:0] MAPPED_SNES_ADDR;
wire ROM_ADDR0;

wire [9:0] bs_page;
wire [8:0] bs_page_offset;
wire bs_page_enable;

wire [4:0] DBG_srtc_state;
wire DBG_srtc_we_rising;
wire [3:0] DBG_srtc_ptr;
wire [5:0] DBG_srtc_we_sreg;
wire [14:0] DBG_msu_address;
wire DBG_msu_reg_oe_rising;
wire DBG_msu_reg_oe_falling;
wire DBG_msu_reg_we_rising;
wire [2:0] SD_DMA_DBG_clkcnt;
wire [10:0] SD_DMA_DBG_cyclecnt;

wire [10:0] snescmd_addr_mcu;
wire [7:0] snescmd_data_out_mcu;
wire [7:0] snescmd_data_in_mcu;

wire [7:0] reg_group;
wire [7:0] reg_index;
wire [7:0] reg_value;
wire [7:0] reg_invmask;
wire       reg_we;
wire [7:0] reg_read;
// unit level configuration output
wire [7:0] trc_config_data;

reg [7:0] SNES_PARDr;
reg [7:0] SNES_PAWRr;
reg [7:0] SNES_READr;
reg [7:0] SNES_WRITEr;
reg [7:0] SNES_CPU_CLKr;
reg [7:0] SNES_ROMSELr;
reg [23:0] SNES_ADDRr [6:0];
reg [7:0] SNES_PAr [6:0];
reg [7:0] SNES_DATAr [4:0];

reg SNES_DEADr; initial SNES_DEADr = 1;
reg SNES_reset_strobe; initial SNES_reset_strobe = 0;

reg free_strobe; initial free_strobe = 0;
reg loop_enable;
initial loop_enable = 0;
reg [7:0] loop_data;
initial loop_data = 8'h80; // BRA

// exe region
reg exe_present; initial exe_present = 0;

//wire cpureg_enable;
//wire [7:0] cpureg_data;

//assign bsx_data_ovr = 0;
//assign IS_FLASHWR = 0;

reg SNES_SNOOPRD_DATA_OE;
reg SNES_SNOOPWR_DATA_OE;
reg SNES_PAWR_DATA_OE;
reg SNES_PARD_DATA_OE;

reg [3:0] SNES_SNOOPRD_count;
reg [3:0] SNES_SNOOPWR_count;
reg [3:0] SNES_PAWR_count;
reg [3:0] SNES_PARD_count;
reg [7:0] CTX_DINr;
reg       CTX_DIRr;
reg [23:0] CTX_SNES_ADDRr;
reg [23:0] MSU_SNES_ADDRr;
reg [23:0] ADR_SNES_ADDRr;
reg [23:0] BSX_SNES_ADDRr;
reg [23:0] SRTC_SNES_ADDRr;

wire SNES_PARD_start = ((SNES_PARDr[6:1] | SNES_PARDr[7:2]) == 6'b111110);
//wire SNES_PARD_end = SNES_PARD_count == 5; // 5
wire SNES_PAWR_start = ((SNES_PAWRr[4:1] | SNES_PAWRr[5:2]) == 4'b1110);
//wire SNES_PAWR_end   = SNES_PAWR_count == 5; // 5
//wire SNES_SNOOPWR_end = SNES_SNOOPWR_count == 5; //5

//wire SNES_RD_start = ((SNES_READr[6:1] | SNES_READr[7:2]) == 6'b111100);
//wire SNES_RD_end = ((SNES_READr[6:1] & SNES_READr[7:2]) == 6'b000001);
//wire SNES_WR_start = ((SNES_WRITEr[6:1] | SNES_WRITEr[7:2]) == 6'b111000);
//wire SNES_WR_end = ((SNES_WRITEr[6:1] & SNES_WRITEr[7:2]) == 6'b000001);
//wire SNES_cycle_start = ((SNES_CPU_CLKr[7:2] & SNES_CPU_CLKr[6:1]) == 6'b000011);
//wire SNES_cycle_end = ((SNES_CPU_CLKr[7:2] | SNES_CPU_CLKr[6:1]) == 6'b111000);
//wire SNES_WRITE = SNES_WRITEr[2] & SNES_WRITEr[1];
//wire SNES_READ = SNES_READr[2] & SNES_READr[1];
//wire SNES_CPU_CLK = SNES_CPU_CLKr[2] & SNES_CPU_CLKr[1];
//wire SNES_PARD = SNES_PARDr[2] & SNES_PARDr[1];
//wire SNES_PAWR = SNES_PAWRr[2] & SNES_PAWRr[1];
//wire SNES_ROMSEL_EARLY = (SNES_ROMSELr[2] & SNES_ROMSELr[1]);

reg SNES_RD_start; initial SNES_RD_start = 0;
reg SNES_RD_end; initial SNES_RD_end = 0;
reg SNES_WR_start; initial SNES_WR_start = 0;
reg SNES_WR_end; initial SNES_WR_end = 0;

reg SNES_cycle_start; initial SNES_cycle_start = 0;
reg SNES_cycle_end; initial SNES_cycle_end = 0;
reg SNES_WRITE; initial SNES_WRITE = 0;
reg SNES_READ; initial SNES_READ = 0;
reg SNES_CPU_CLK; initial SNES_CPU_CLK = 0;
reg SNES_PARD; initial SNES_PARD = 0;
reg SNES_PAWR; initial SNES_PAWR = 0;
reg SNES_ROMSEL_EARLY; initial SNES_ROMSEL_EARLY = 0;

always @(posedge CLK2) begin
  SNES_RD_start <= ((SNES_READr[5:0] | SNES_READr[6:1]) == 6'b111100);
  SNES_RD_end <= ((SNES_READr[5:0] & SNES_READr[6:1]) == 6'b000001);
  SNES_WR_start <= ((SNES_WRITEr[5:0] | SNES_WRITEr[6:1]) == 6'b111000);
  SNES_WR_end <= ((SNES_WRITEr[5:0] & SNES_WRITEr[6:1]) == 6'b000001);

  SNES_cycle_start <= ((SNES_CPU_CLKr[6:1] & SNES_CPU_CLKr[5:0]) == 6'b000011);
  SNES_cycle_end <= ((SNES_CPU_CLKr[6:1] | SNES_CPU_CLKr[5:0]) == 6'b111000);
  SNES_WRITE <= SNES_WRITEr[1] & SNES_WRITEr[0];
  SNES_READ <= SNES_READr[1] & SNES_READr[0];
  SNES_CPU_CLK <= SNES_CPU_CLKr[1] & SNES_CPU_CLKr[0];
  SNES_PARD <= SNES_PARDr[1] & SNES_PARDr[0];
  SNES_PAWR <= SNES_PAWRr[1] & SNES_PAWRr[0];
  SNES_ROMSEL_EARLY <= (SNES_ROMSELr[1] & SNES_ROMSELr[0]);
end

reg SNES_PAWR_end;
reg SNES_PARD_end;
reg SNES_SNOOPRD_end;
reg SNES_SNOOPWR_end;

always @(posedge CLK2) begin
  if (SNES_reset_strobe) begin
    SNES_PARD_end <= 0;
    SNES_PAWR_end <= 0;
    SNES_SNOOPRD_end <= 0;
    SNES_SNOOPWR_end <= 0;
  end
  else begin
    SNES_PARD_end <= SNES_PARD_count == 4;
    SNES_PAWR_end <= SNES_PAWR_count == 4;
    SNES_SNOOPRD_end <= SNES_SNOOPRD_count == 4;
    SNES_SNOOPWR_end <= SNES_SNOOPWR_count == 4;
  end
end

//wire SNES_ROMSEL = (SNES_ROMSELr[5] & SNES_ROMSELr[4]);
reg SNES_ROMSEL;
wire [23:0] SNES_ADDR = (SNES_ADDRr[6] & SNES_ADDRr[5]);
wire [7:0] SNES_PA = (SNES_PAr[6] & SNES_PAr[5]);
wire [7:0] SNES_DATA_IN = (SNES_DATAr[3] & SNES_DATAr[2]);

always @(posedge CLK2) SNES_ROMSEL <= (SNES_ROMSELr[4] & SNES_ROMSELr[3]);

reg [7:0] BUS_DATA;
reg [7:0] CTX_BUS_DATA;

always @(posedge CLK2) begin
  if(~SNES_READ) BUS_DATA <= SNES_DATA;
  else if(~SNES_WRITE) BUS_DATA <= SNES_DATA_IN;
  
  // FIXME: is it ok to grab the flopped data?
  if (SNES_PAWR_DATA_OE | SNES_PARD_DATA_OE | SNES_SNOOPWR_DATA_OE) CTX_BUS_DATA <= SNES_DATAr[0];//SNES_DATA_IN;
end

wire SD_DMA_TO_ROM;

wire free_slot = (SNES_cycle_end | free_strobe) & ~SD_DMA_TO_ROM;

wire ROM_HIT;

assign DCM_RST=0;

always @(posedge CLK2) begin
  free_strobe <= 1'b0;
  if(SNES_cycle_start) free_strobe <= (~ROM_HIT | loop_enable);
end

integer j;
always @(posedge CLK2) begin
  SNES_PARDr <= {SNES_PARDr[6:0], SNES_PARD_IN};
  SNES_PAWRr <= {SNES_PAWRr[6:0], SNES_PAWR_IN};
  SNES_READr <= {SNES_READr[6:0], SNES_READ_IN};
  SNES_WRITEr <= {SNES_WRITEr[6:0], SNES_WRITE_IN};
  SNES_CPU_CLKr <= {SNES_CPU_CLKr[6:0], SNES_CPU_CLK_IN};
  SNES_ROMSELr <= {SNES_ROMSELr[6:0], SNES_ROMSEL_IN};
  SNES_ADDRr[6] <= SNES_ADDRr[5];
  SNES_ADDRr[5] <= SNES_ADDRr[4];
  SNES_ADDRr[4] <= SNES_ADDRr[3];
  SNES_ADDRr[3] <= SNES_ADDRr[2];
  SNES_ADDRr[2] <= SNES_ADDRr[1];
  SNES_ADDRr[1] <= SNES_ADDRr[0];
  SNES_ADDRr[0] <= SNES_ADDR_IN;
  SNES_PAr[6] <= SNES_PAr[5];
  SNES_PAr[5] <= SNES_PAr[4];
  SNES_PAr[4] <= SNES_PAr[3];
  SNES_PAr[3] <= SNES_PAr[2];
  SNES_PAr[2] <= SNES_PAr[1];
  SNES_PAr[1] <= SNES_PAr[0];
  SNES_PAr[0] <= SNES_PA_IN;
  
  SNES_DATAr[4] <= SNES_DATAr[3];
  SNES_DATAr[3] <= SNES_DATAr[2];
  SNES_DATAr[2] <= SNES_DATAr[1];
  SNES_DATAr[1] <= SNES_DATAr[0];
  SNES_DATAr[0] <= SNES_DATA;
  
  // count of write low
  if (SNES_reset_strobe | SNES_PAWR_end) begin
    SNES_PAWR_count <= 0;
    SNES_PAWR_DATA_OE <= 0;
  end
  else if (SNES_PAWR_start) begin 
    SNES_PAWR_count <= 1;
    SNES_PAWR_DATA_OE <= 1;
  end
  else if (|SNES_PAWR_count) begin
    SNES_PAWR_count <= SNES_PAWR_count + 1;
  end

  // count of write low
  if (SNES_reset_strobe | SNES_PARD_end) begin
    SNES_PARD_count <= 0;
    SNES_PARD_DATA_OE <= 0;
  end
  else if (SNES_PARD_start) begin 
    SNES_PARD_count <= 1;
    SNES_PARD_DATA_OE <= 1;
  end
  else if (|SNES_PARD_count) begin
    SNES_PARD_count <= SNES_PARD_count + 1;
  end

  // count of write low
  if (SNES_reset_strobe | SNES_SNOOPWR_end) begin
    SNES_SNOOPWR_count <= 0;
    SNES_SNOOPWR_DATA_OE <= 0;
  end
  else if (SNES_WR_start) begin 
    SNES_SNOOPWR_count <= 1;
    SNES_SNOOPWR_DATA_OE <= 1;
  end
  else if (|SNES_SNOOPWR_count) begin
    SNES_SNOOPWR_count <= SNES_SNOOPWR_count + 1;
  end

  // count of write low
  if (SNES_reset_strobe | SNES_SNOOPRD_end) begin
    SNES_SNOOPRD_count <= 0;
    SNES_SNOOPRD_DATA_OE <= 0;
  end
  else if (SNES_RD_start) begin 
    SNES_SNOOPRD_count <= 1;
    SNES_SNOOPRD_DATA_OE <= 1;
  end
  else if (|SNES_SNOOPRD_count) begin
    SNES_SNOOPRD_count <= SNES_SNOOPRD_count + 1;
  end


end

parameter ST_IDLE        = 11'b00000000001;
parameter ST_MCU_RD_ADDR = 11'b00000000010;
parameter ST_MCU_RD_END  = 11'b00000000100;
parameter ST_MCU_WR_ADDR = 11'b00000001000;
parameter ST_MCU_WR_END  = 11'b00000010000;
parameter ST_CTX_WR_ADDR = 11'b00000100000;
parameter ST_CTX_WR_END  = 11'b00001000000;
parameter ST_DMA_RD_ADDR = 11'b00010000000;
parameter ST_DMA_RD_END  = 11'b00100000000;
parameter ST_DMA_WR_ADDR = 11'b01000000000;
parameter ST_DMA_WR_END  = 11'b10000000000;

parameter SNES_DEAD_TIMEOUT = 17'd96000; // 1ms

parameter ROM_CYCLE_LEN = 4'd7;

reg [10:0] STATE;
initial STATE = ST_IDLE;

assign DSPX_SNES_DATA_IN = BUS_DATA;
assign SRTC_SNES_DATA_IN = BUS_DATA[3:0];
assign MSU_SNES_DATA_IN = BUS_DATA;
//assign USB_SNES_DATA_IN = BUS_DATA;
assign DMA_SNES_DATA_IN = BUS_DATA;
assign BSX_SNES_DATA_IN = BUS_DATA;
assign CTX_SNES_DATA_IN = CTX_DIRr ? CTX_DINr : SNES_DATAr[0]; //CTX_BUS_DATA;

sd_dma snes_sd_dma(
  .CLK(CLK2),
  .SD_DAT(SD_DAT),
  .SD_CLK(SD_CLK),
  .SD_DMA_EN(SD_DMA_EN),
  .SD_DMA_STATUS(SD_DMA_STATUS),
  .SD_DMA_SRAM_WE(SD_DMA_SRAM_WE),
  .SD_DMA_SRAM_DATA(SD_DMA_SRAM_DATA),
  .SD_DMA_NEXTADDR(SD_DMA_NEXTADDR),
  .SD_DMA_PARTIAL(SD_DMA_PARTIAL),
  .SD_DMA_PARTIAL_START(SD_DMA_PARTIAL_START),
  .SD_DMA_PARTIAL_END(SD_DMA_PARTIAL_END),
  .SD_DMA_START_MID_BLOCK(SD_DMA_START_MID_BLOCK),
  .SD_DMA_END_MID_BLOCK(SD_DMA_END_MID_BLOCK),
  .DBG_cyclecnt(SD_DMA_DBG_cyclecnt),
  .DBG_clkcnt(SD_DMA_DBG_clkcnt)
);

assign SD_DMA_TO_ROM = (SD_DMA_STATUS && (SD_DMA_TGT == 2'b00));

dac snes_dac(
  .clkin(CLK2),
  .sysclk(SNES_SYSCLK),
  .mclk_out(DAC_MCLK),
  .lrck_out(DAC_LRCK),
  .sdout(DAC_SDOUT),
  .we(SD_DMA_TGT==2'b01 ? SD_DMA_SRAM_WE : 1'b1),
  .pgm_address(dac_addr),
  .pgm_data(SD_DMA_SRAM_DATA),
  .DAC_STATUS(DAC_STATUS),
  .volume(msu_volumerq_out),
  .vol_latch(msu_volume_latch_out),
  .vol_select(dac_vol_select_out),
  .palmode(dac_palmode_out),
  .play(dac_play),
  .reset(dac_reset),
  .dac_address_ext(dac_ptr_addr)
);

srtc snes_srtc (
  .clkin(CLK2),
  .addr_in(SRTC_SNES_ADDRr[0]),
  .data_in(SRTC_SNES_DATA_IN),
  .data_out(SRTC_SNES_DATA_OUT),
  .rtc_data_in(rtc_data),
  .enable(srtc_enable),
  .rtc_data_out(srtc_rtc_data_out),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .rtc_we(srtc_rtc_we),
  .reset(srtc_reset),
  .srtc_state(DBG_srtc_state),
  .srtc_reg_we_rising(DBG_srtc_we_rising),
  .srtc_rtc_ptr(DBG_srtc_ptr),
  .srtc_we_sreg(DBG_srtc_we_sreg)
);

rtc snes_rtc (
  .clkin(CLKIN),
  .rtc_data(rtc_data),
  .rtc_data_in(rtc_data_in),
  .pgm_we(rtc_pgm_we),
  .rtc_data_in1(srtc_rtc_data_out),
  .we1(srtc_rtc_we)
);

wire feat_msu_enable = featurebits[3];
wire DBG_MSU;

msu snes_msu (
  .clkin(CLK2),
  .enable(msu_enable),
  .reset(SNES_reset_strobe),
  .pgm_address(msu_write_addr),
  .pgm_data(SD_DMA_SRAM_DATA),
  .pgm_we(SD_DMA_TGT==2'b10 ? SD_DMA_SRAM_WE : 1'b1),
  .reg_addr(MSU_SNES_ADDRr[3:0]),
  .reg_data_in(MSU_SNES_DATA_IN),
  .reg_data_out(MSU_SNES_DATA_OUT),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .status_out(msu_status_out),
  .volume_out(msu_volumerq_out),
  .volume_latch_out(msu_volume_latch_out),
  .addr_out(msu_addressrq_out),
  .track_out(msu_trackrq_out),
  .status_reset_bits(msu_status_reset_bits),
  .status_set_bits(msu_status_set_bits),
  .status_reset_we(msu_status_reset_we),
  .msu_address_ext(msu_ptr_addr),
  .msu_address_ext_write(msu_addr_reset),
  .feature_enable(feat_msu_enable),
  .SNES_RD_end(SNES_RD_end),
  .SNES_WR_end(SNES_WR_end),
  .SNES_PARD_end(SNES_PARD_end),
  .SNES_PAWR_end(SNES_PAWR_end),
  .SNES_ADDR(MSU_SNES_ADDRr),
  .SNES_PA(SNES_PA),
  .SNES_DATA(CTX_SNES_DATA_IN),
  .msu_data_out(msu_data),
  .msu_scaddr_out(msu_scaddr),
  .SNES_SNOOPRD_end(SNES_SNOOPRD_end),
  .OE_RD_ENABLE(msu_rd_enable),
  .DBG_msu_reg_oe_rising(DBG_msu_reg_oe_rising),
  .DBG_msu_reg_oe_falling(DBG_msu_reg_oe_falling),
  .DBG_msu_reg_we_rising(DBG_msu_reg_we_rising),
  .DBG_msu_address(DBG_msu_address),
  .DBG_msu_address_ext_write_rising(DBG_msu_address_ext_write_rising),
  .SNES_RD(SNES_READ),
  .SNES_WR(SNES_WRITE),
  .SNES_PARD(SNES_PARD),
  .SNES_PAWR(SNES_PAWR),
  .SNES_ROMSEL(SNES_ROMSEL_EARLY),
  .SNES_RD_start(SNES_RD_start),
  .SNES_WR_start(SNES_WR_start),
  .SNES_PARD_start(SNES_PARD_start),
  .SNES_PAWR_start(SNES_PAWR_start),
  .reg_group_in(reg_group),
  .reg_index_in(reg_index),
  .reg_value_in(reg_value),
  .reg_invmask_in(reg_invmask),
  .reg_we_in(reg_we),
  .reg_read_in(reg_read),
  .trc_config_data_out(trc_config_data),
  .DBG(DBG_MSU)
);

//usb snes_usb (
//  .clkin(CLK2),
//  .enable(usb_enable),
//  .reg_addr(SNES_ADDR[2:0]),
//  .reg_data_in(USB_SNES_DATA_IN),
//  .reg_data_out(USB_SNES_DATA_OUT),
//  .reg_oe_falling(SNES_RD_start),
//  .reg_oe_rising(SNES_RD_end),
//  .reg_we_rising(SNES_WR_end),
//  .status_reset_bits(usb_status_reset_bits),
//  .status_set_bits(usb_status_set_bits),
//  .status_reset_we(usb_status_reset_we)
//);

wire [23:0] CTX_ADDR;
wire [15:0] CTX_DOUT;

ctx snes_ctx (
  .clkin(CLK2),
  .reset(SNES_reset_strobe),

  .SNES_ADDR(CTX_SNES_ADDRr),
  .SNES_PA(SNES_PA),
  .SNES_RD_end(SNES_RD_end),
  .SNES_WR_end(SNES_SNOOPWR_end),
  //.SNES_WR_end(SNES_WR_end), // NOTE: leave this as the normal write timing in case the data comes from ROM.
  .SNES_PARD_end(SNES_PARD_end),
  .SNES_PAWR_end(SNES_PAWR_end),
  .SNES_DATA_IN(CTX_SNES_DATA_IN), // needs to handle PA accesses, too

  //.OE_RD_ENABLE(ctx_rd_enable),
  .OE_WR_ENABLE(ctx_wr_enable),
  .OE_PAWR_ENABLE(ctx_pawr_enable),
  .OE_PARD_ENABLE(ctx_pard_enable),

  .BUS_WRQ(CTX_WRQ),
  .BUS_RDY(CTX_RDY),

  .snescmd_unlock(snescmd_unlock),

  .ROM_ADDR(CTX_ADDR),
  .ROM_DATA(CTX_DOUT),
  .ROM_WORD_ENABLE(CTX_WORD),
  
  //.ROM_SNESCAST_ADDR(CTX_SNESCAST_ADDR),
  //.ROM_SNESCAST_DATA(CTX_SNESCAST_DOUT),
  //.ROM_SNESCAST_ENABLE(CTX_SNESCAST_ENABLE),
  
  .DBG(CTX_DBG)
);

wire [23:0] DMA_ADDR;
wire [15:0] DMA_DOUT;

reg [15:0] DMA_DINr;

dma snes_dma (
  .clkin(CLK2),
  .reset(SNES_reset_strobe),
  .enable(dma_enable),

  .reg_addr(SNES_ADDR[3:0]),
  .reg_data_in(DMA_SNES_DATA_IN),
  .reg_data_out(DMA_SNES_DATA_OUT),

  .reg_oe_falling(SNES_RD_start),
  .reg_we_rising(SNES_WR_end),
  
  .loop_enable(DMA_LOOP_ENABLE),
  
  .BUS_RDY(DMA_RDY),
  .BUS_RRQ(DMA_RRQ),
  .BUS_WRQ(DMA_WRQ),
  
  .ROM_ADDR(DMA_ADDR),
  .ROM_DATA_OUT(DMA_DOUT),
  .ROM_DATA_IN(DMA_DINr),
  .ROM_WORD_ENABLE(DMA_WORD)
);

bsx snes_bsx(
  .clkin(CLK2),
  .use_bsx(use_bsx),
  .pgm_we(bsx_regs_reset_we),
  .snes_addr(BSX_SNES_ADDRr),
  .reg_data_in(BSX_SNES_DATA_IN),
  .reg_data_out(BSX_SNES_DATA_OUT),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .regs_out(bsx_regs),
  .reg_reset_bits(bsx_regs_reset_bits),
  .reg_set_bits(bsx_regs_set_bits),
  .data_ovr(bsx_data_ovr),
  .flash_writable(IS_FLASHWR),
  .rtc_data(rtc_data[59:0]),
  .bs_page_out(bs_page), // support only page 0000-03ff
  .bs_page_enable(bs_page_enable),
  .bs_page_offset(bs_page_offset)

);

spi snes_spi(
  .clk(CLK2),
  .MOSI(SPI_MOSI),
  .MISO(SPI_MISO),
  .SSEL(SPI_SS),
  .SCK(SPI_SCK),
  .cmd_ready(spi_cmd_ready),
  .param_ready(spi_param_ready),
  .cmd_data(spi_cmd_data),
  .param_data(spi_param_data),
  .endmessage(spi_endmessage),
  .startmessage(spi_startmessage),
  .input_data(spi_input_data),
  .byte_cnt(spi_byte_cnt),
  .bit_cnt(spi_bit_cnt)
);

wire [15:0] dsp_feat;

upd77c25 snes_dspx (
  .DI(DSPX_SNES_DATA_IN),
  .DO(DSPX_SNES_DATA_OUT),
  .A0(DSPX_A0),
  .enable(dspx_enable),
  .reg_oe_falling(SNES_RD_start),
  .reg_oe_rising(SNES_RD_end),
  .reg_we_rising(SNES_WR_end),
  .RST(~dspx_reset),
  .CLK(CLK2),
  .PGM_WR(dspx_pgm_we),
  .PGM_DI(dspx_pgm_data),
  .PGM_WR_ADDR(dspx_pgm_addr),
  .DAT_WR(dspx_dat_we),
  .DAT_DI(dspx_dat_data),
  .DAT_WR_ADDR(dspx_dat_addr),
  .DP_enable(dspx_dp_enable),
  .DP_ADDR(SNES_ADDR[10:0]),
  .dsp_feat(dsp_feat)
);

reg [7:0] MCU_DINr;
wire [7:0] MCU_DOUT;
wire [31:0] cheat_pgm_data;
wire [7:0] cheat_data_out;
wire [2:0] cheat_pgm_idx;

wire feat_cmd_unlock = featurebits[5];
wire DBG_MCU;

mcu_cmd snes_mcu_cmd(
  .clk(CLK2),
  .snes_sysclk(SNES_SYSCLK),
  .cmd_ready(spi_cmd_ready),
  .param_ready(spi_param_ready),
  .cmd_data(spi_cmd_data),
  .param_data(spi_param_data),
  .mcu_mapper(MAPPER),
  .mcu_write(MCU_WRITE),
  .mcu_data_in(MCU_DINr),
  .mcu_data_out(MCU_DOUT),
  .spi_byte_cnt(spi_byte_cnt),
  .spi_bit_cnt(spi_bit_cnt),
  .spi_data_out(spi_input_data),
  .addr_out(MCU_ADDR),
  .saveram_mask_out(SAVERAM_MASK),
  .rom_mask_out(ROM_MASK),
  .SD_DMA_EN(SD_DMA_EN),
  .SD_DMA_STATUS(SD_DMA_STATUS),
  .SD_DMA_NEXTADDR(SD_DMA_NEXTADDR),
  .SD_DMA_SRAM_DATA(SD_DMA_SRAM_DATA),
  .SD_DMA_SRAM_WE(SD_DMA_SRAM_WE),
  .SD_DMA_TGT(SD_DMA_TGT),
  .SD_DMA_PARTIAL(SD_DMA_PARTIAL),
  .SD_DMA_PARTIAL_START(SD_DMA_PARTIAL_START),
  .SD_DMA_PARTIAL_END(SD_DMA_PARTIAL_END),
  .SD_DMA_START_MID_BLOCK(SD_DMA_START_MID_BLOCK),
  .SD_DMA_END_MID_BLOCK(SD_DMA_END_MID_BLOCK),
  .dac_addr_out(dac_addr),
  .DAC_STATUS(DAC_STATUS),
  .dac_play_out(dac_play),
  .dac_reset_out(dac_reset),
  .dac_vol_select_out(dac_vol_select_out),
  .dac_palmode_out(dac_palmode_out),
  .dac_ptr_out(dac_ptr_addr),
  .msu_addr_out(msu_write_addr),
  .MSU_STATUS(msu_status_out),
  .msu_status_reset_out(msu_status_reset_bits),
  .msu_status_set_out(msu_status_set_bits),
  .msu_status_reset_we(msu_status_reset_we),
  .msu_volumerq(msu_volumerq_out),
  .msu_data(msu_data),
  .msu_scaddr(msu_scaddr),
  .msu_addressrq(msu_addressrq_out),
  .msu_trackrq(msu_trackrq_out),
  .msu_ptr_out(msu_ptr_addr),
  .msu_reset_out(msu_addr_reset),
  //.usb_status_reset_out(usb_status_reset_bits),
  //.usb_status_set_out(usb_status_set_bits),
  //.usb_status_reset_we(usb_status_reset_we),
  .reg_group_out(reg_group),
  .reg_index_out(reg_index),
  .reg_value_out(reg_value),
  .reg_invmask_out(reg_invmask),
  .reg_we_out(reg_we),
  .reg_read_out(reg_read),
  .trc_config_data_in(trc_config_data),
  .bsx_regs_set_out(bsx_regs_set_bits),
  .bsx_regs_reset_out(bsx_regs_reset_bits),
  .bsx_regs_reset_we(bsx_regs_reset_we),
  .rtc_data_out(rtc_data_in),
  .rtc_pgm_we(rtc_pgm_we),
  .srtc_reset(srtc_reset),
  .dspx_pgm_data_out(dspx_pgm_data),
  .dspx_pgm_addr_out(dspx_pgm_addr),
  .dspx_pgm_we_out(dspx_pgm_we),
  .dspx_dat_data_out(dspx_dat_data),
  .dspx_dat_addr_out(dspx_dat_addr),
  .dspx_dat_we_out(dspx_dat_we),
  .dspx_reset_out(dspx_reset),
  .featurebits_out(featurebits),
  .mcu_rrq(MCU_RRQ),
  .mcu_wrq(MCU_WRQ),
  .mcu_rq_rdy(MCU_RDY),
  .region_out(mcu_region),
  .snescmd_addr_out(snescmd_addr_mcu),
  .snescmd_we_out(snescmd_we_mcu),
  .snescmd_data_out(snescmd_data_out_mcu),
  .snescmd_data_in(snescmd_data_in_mcu),
  .cheat_pgm_idx_out(cheat_pgm_idx),
  .cheat_pgm_data_out(cheat_pgm_data),
  .cheat_pgm_we_out(cheat_pgm_we),
  .dsp_feat_out(dsp_feat),
  .DBG(DBG_MCU)
);

wire [7:0] DCM_STATUS;
// dcm1: dfs 4x
my_dcm snes_dcm(
  .CLKIN(CLKIN),
  .CLKFX(CLK2),
  .LOCKED(DCM_LOCKED),
  .RST(DCM_RST),
  .STATUS(DCM_STATUS)
);

address snes_addr(
  .CLK(CLK2),
  .MAPPER(MAPPER),
  .featurebits_in(featurebits),
  .SNES_ADDR(ADR_SNES_ADDRr), // requested address from SNES
  .SNES_PA(SNES_PA),
  .SNES_ROMSEL(SNES_ROMSEL),
  .ROM_ADDR(MAPPED_SNES_ADDR),   // Address to request from SRAM (active low)
  .ROM_HIT(ROM_HIT),     // want to access RAM0
  .IS_SAVERAM(IS_SAVERAM),
  .IS_ROM(IS_ROM),
  .IS_WRITABLE(IS_WRITABLE),
  .SAVERAM_MASK(SAVERAM_MASK),
  .ROM_MASK(ROM_MASK),
  .map_unlock(map_unlock),
  //MSU-1
  .msu_enable(msu_enable),
  //USB-1
  //.usb_enable(usb_enable),
  //DMA-1
  .dma_enable(dma_enable),
  //BS-X
  .use_bsx(use_bsx),
  .bsx_regs(bsx_regs),
  .bs_page_offset(bs_page_offset),
  .bs_page(bs_page),
  .bs_page_enable(bs_page_enable),
  .bsx_tristate(bsx_tristate),
  //SRTC
  .srtc_enable(srtc_enable),
  //uPD77C25
  .dspx_enable(dspx_enable),
  .dspx_dp_enable(dspx_dp_enable),
  .dspx_a0(DSPX_A0),
  .r213f_enable(r213f_enable),
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .branch1_enable(branch1_enable),
  .branch2_enable(branch2_enable),
  .exe_enable(exe_enable)
);

reg pad_latch; initial pad_latch = 0;
reg [4:0] pad_cnt; initial pad_cnt = 0;

reg snes_ajr = 0;

cheat snes_cheat(
  .clk(CLK2),
  .SNES_ADDR(SNES_ADDR),
  .SNES_PA(SNES_PA),
  .SNES_DATA(SNES_DATA),
  .SNES_reset_strobe(SNES_reset_strobe),
  .SNES_cycle_start(SNES_cycle_start),
  .SNES_wr_strobe(SNES_WR_end),
  .SNES_rd_strobe(SNES_RD_start),
  .snescmd_enable(snescmd_enable),
  .nmicmd_enable(nmicmd_enable),
  .return_vector_enable(return_vector_enable),
  .branch1_enable(branch1_enable),
  .branch2_enable(branch2_enable),
  .exe_present(exe_present),
  .pad_latch(pad_latch),
  .snes_ajr(snes_ajr),
  .pgm_idx(cheat_pgm_idx),
  .pgm_we(cheat_pgm_we),
  .pgm_in(cheat_pgm_data),
  .data_out(cheat_data_out),
  .cheat_hit(cheat_hit),
  .snescmd_unlock(snescmd_unlock),
  .map_unlock(map_unlock)
);

wire [7:0] snescmd_dout;

reg [7:0] r213fr;
reg r213f_forceread;
reg [2:0] r213f_delay;
reg [1:0] r213f_state;
initial r213fr = 8'h55;
initial r213f_forceread = 0;
initial r213f_state = 2'b01;
initial r213f_delay = 3'b000;

wire snoop_4200_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04200;
wire r4016_enable = {SNES_ADDR[22], SNES_ADDR[15:0]} == 17'h04016;

always @(posedge CLK2) begin
  if(SNES_WR_end & snoop_4200_enable) begin
    snes_ajr <= SNES_DATA[0];
  end
end

always @(posedge CLK2) begin
  if(SNES_WR_end & r4016_enable) begin
    pad_latch <= 1'b1;
    pad_cnt <= 5'h0;
  end
  if(SNES_RD_start & r4016_enable) begin
    pad_cnt <= pad_cnt + 1;
    if(&pad_cnt[3:0]) begin
      pad_latch <= 1'b0;
    end
  end
end

//wire SNES_PAWR_DATA_OE = ~SNES_PAWR;
//wire SNES_PARD_DATA_OE = ~SNES_PARD;
//assign SNES_SNOOPRD_DATA_OE = |SNES_SNOOPRD_count;
//assign SNES_SNOOPWR_DATA_OE = |SNES_SNOOPWR_count;
//assign SNES_PAWR_DATA_OE = |SNES_PAWR_count;
//assign SNES_PARD_DATA_OE = |SNES_PARD_count;

// FIXME: Cleanup read equation.  Currently this matches DIR in order to snoop.  Just looking at ~SNES_READ corrupts SNES_DATA when we are trying to snoop data from the bus.
assign SNES_DATA = (r213f_enable & ~SNES_PARD & ~r213f_forceread) ? r213fr
                   :((~SNES_READ & ((~SNES_PAWR_DATA_OE & ~SNES_PARD_DATA_OE & ~(SNES_SNOOPRD_DATA_OE & msu_rd_enable)/*& ~ctx_rd_enable & ~msu_rd_enable*/) | ~SNES_ROMSEL_EARLY)) ^ (r213f_forceread & r213f_enable & ~SNES_PARD))
                                ? (srtc_enable ? SRTC_SNES_DATA_OUT
                                  :dspx_enable ? DSPX_SNES_DATA_OUT
                                  :dspx_dp_enable ? DSPX_SNES_DATA_OUT
                                  :msu_enable ? MSU_SNES_DATA_OUT
                                  //:usb_enable ? USB_SNES_DATA_OUT
                                  :dma_enable ? DMA_SNES_DATA_OUT
                                  :bsx_data_ovr ? BSX_SNES_DATA_OUT
                                  :(cheat_hit & ~feat_cmd_unlock) ? cheat_data_out
                                  // put spinloop below cheat so we don't overwrite jmp target after NMI
                                  :loop_enable ? loop_data
                                  //:cpureg_enable ? cpureg_data
                                  :((snescmd_unlock | feat_cmd_unlock) & snescmd_enable) ? snescmd_dout
                                  :(ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8])
                                  ) : 8'bZ;

reg [3:0] ST_MEM_DELAYr;
reg MCU_RD_PENDr; initial MCU_RD_PENDr = 0;
reg MCU_WR_PENDr; initial MCU_WR_PENDr = 0;
reg [23:0] ROM_ADDRr;
// CTX
reg CTX_WR_PENDr;
initial CTX_WR_PENDr = 0;
reg [23:0] CTX_ROM_ADDRr;
initial CTX_ROM_ADDRr = 24'h0;
reg [15:0] CTX_ROM_DATAr;
initial CTX_ROM_DATAr = 16'h0000;
reg CTX_ROM_WORDr;
initial CTX_ROM_WORDr = 1'b0;

//reg [23:0] CTX_ROM_SNESCAST_ADDRr;
//initial CTX_ROM_SNESCAST_ADDRr = 24'h0;
//reg [15:0] CTX_ROM_SNESCAST_DATAr;
//initial CTX_ROM_SNESCAST_DATAr = 16'h0000;
//reg CTX_ROM_SNESCAST_ENABLEr;
//initial CTX_ROM_SNESCAST_ENABLEr = 0;

// DMA
reg DMA_WR_PENDr;
initial DMA_WR_PENDr = 0;
reg DMA_RD_PENDr;
initial DMA_RD_PENDr = 0;
reg [23:0] DMA_ROM_ADDRr;
initial DMA_ROM_ADDRr = 24'h0;
reg [15:0] DMA_ROM_DATAr;
initial DMA_ROM_DATAr = 16'h0000;
reg DMA_ROM_WORDr;
initial DMA_ROM_WORDr = 1'b0;

reg RQ_MCU_RDYr;
initial RQ_MCU_RDYr = 1'b1;
assign MCU_RDY = RQ_MCU_RDYr;
// CTX
reg RQ_CTX_RDYr;
initial RQ_CTX_RDYr = 1'b1;
assign CTX_RDY = RQ_CTX_RDYr;
// DMA
reg RQ_DMA_RDYr;
initial RQ_DMA_RDYr = 1'b1;
assign DMA_RDY = RQ_DMA_RDYr;

wire MCU_WR_HIT = |(STATE & ST_MCU_WR_ADDR);
wire MCU_RD_HIT = |(STATE & ST_MCU_RD_ADDR);
wire MCU_HIT = MCU_WR_HIT | MCU_RD_HIT;
// CTX
wire CTX_WR_HIT = |(STATE & ST_CTX_WR_ADDR);
wire CTX_HIT = CTX_WR_HIT;
// DMA
wire DMA_WR_HIT = |(STATE & ST_DMA_WR_ADDR);
wire DMA_RD_HIT = |(STATE & ST_DMA_RD_ADDR);
wire DMA_HIT = DMA_WR_HIT | DMA_RD_HIT;

assign ROM_ADDR  = (SD_DMA_TO_ROM) ? MCU_ADDR[23:1] : CTX_HIT ? CTX_ROM_ADDRr[23:1] : DMA_HIT ? DMA_ROM_ADDRr[23:1] : MCU_HIT ? ROM_ADDRr[23:1] : MAPPED_SNES_ADDR[23:1];
assign ROM_ADDR0 = (SD_DMA_TO_ROM) ? MCU_ADDR[0] : CTX_HIT ? CTX_ROM_ADDRr[0] : DMA_HIT ? DMA_ROM_ADDRr[0] : MCU_HIT ? ROM_ADDRr[0] : MAPPED_SNES_ADDR[0];

reg[17:0] SNES_DEAD_CNTr;
initial SNES_DEAD_CNTr = 0;

// context engine request
always @(posedge CLK2) begin
  if(CTX_WRQ) begin
    CTX_WR_PENDr <= 1'b1;
    RQ_CTX_RDYr <= 1'b0;
    CTX_ROM_ADDRr <= CTX_ADDR;
    CTX_ROM_DATAr <= CTX_DOUT;
    CTX_ROM_WORDr <= CTX_WORD;
    
    //CTX_ROM_SNESCAST_ADDRr <= CTX_SNESCAST_ADDR;
    //CTX_ROM_SNESCAST_DATAr <= CTX_SNESCAST_DOUT;
    //CTX_ROM_SNESCAST_ENABLEr <= CTX_SNESCAST_ENABLE;
  end 
  else if(STATE & ST_CTX_WR_END) begin
    //if (!CTX_ROM_SNESCAST_ENABLEr) begin
      CTX_WR_PENDr <= 1'b0;
      RQ_CTX_RDYr <= 1'b1;
    //end
    //else begin
    //  // make a second pass immediately and write the snescast info
    //  CTX_ROM_SNESCAST_ENABLEr <= 0;
    //  CTX_ROM_ADDRr <= CTX_ROM_SNESCAST_ADDRr;
    //  CTX_ROM_DATAr <= CTX_ROM_SNESCAST_DATAr;
    //  CTX_ROM_WORDr <= 1'b1;
    //end
  end
end

always @(posedge CLK2) begin
  if(MCU_RRQ) begin
    MCU_RD_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
    ROM_ADDRr <= MCU_ADDR;
  end else if(MCU_WRQ) begin
    MCU_WR_PENDr <= 1'b1;
    RQ_MCU_RDYr <= 1'b0;
    ROM_ADDRr <= MCU_ADDR;
  end else if(STATE & (ST_MCU_RD_END | ST_MCU_WR_END)) begin
    MCU_RD_PENDr <= 1'b0;
    MCU_WR_PENDr <= 1'b0;
    RQ_MCU_RDYr <= 1'b1;
  end
end

// dma engine request
always @(posedge CLK2) begin
  if(DMA_RRQ) begin
    DMA_RD_PENDr <= 1'b1;
	  RQ_DMA_RDYr <= 1'b0;
	  DMA_ROM_ADDRr <= DMA_ADDR;
	  DMA_ROM_WORDr <= DMA_WORD;
  end 
  else if(DMA_WRQ) begin
    DMA_WR_PENDr <= 1'b1;
	  RQ_DMA_RDYr <= 1'b0;
	  DMA_ROM_ADDRr <= DMA_ADDR;
	  DMA_ROM_DATAr <= DMA_DOUT;
	  DMA_ROM_WORDr <= DMA_WORD;
  end
  else if(STATE & (ST_DMA_RD_END | ST_DMA_WR_END)) begin
    DMA_RD_PENDr <= 1'b0;
    DMA_WR_PENDr <= 1'b0;
	  RQ_DMA_RDYr <= 1'b1;
  end
end

always @(posedge CLK2) begin
  if(~SNES_CPU_CLKr[1]) SNES_DEAD_CNTr <= SNES_DEAD_CNTr + 1;
  else SNES_DEAD_CNTr <= 17'h0;
end

always @(posedge CLK2) begin
  SNES_reset_strobe <= 1'b0;
  if(SNES_CPU_CLKr[1]) begin
    SNES_DEADr <= 1'b0;
    if(SNES_DEADr) SNES_reset_strobe <= 1'b1;
  end
  else if(SNES_DEAD_CNTr > SNES_DEAD_TIMEOUT) SNES_DEADr <= 1'b1;
end

reg ROM_ADDR0_r;
always @(posedge CLK2) begin
  // timing
  ROM_ADDR0_r <= ROM_ADDR0;
  // always flop and only use when snooping ROM
  CTX_DINr <= (ROM_ADDR0_r ? ROM_DATA[7:0] : ROM_DATA[15:8]);
  CTX_DIRr <= SNES_DATABUS_DIR;
  CTX_SNES_ADDRr <= SNES_ADDRr[5] & SNES_ADDRr[4];
  MSU_SNES_ADDRr <= SNES_ADDRr[5] & SNES_ADDRr[4];
  ADR_SNES_ADDRr <= SNES_ADDRr[5] & SNES_ADDRr[4];
  SRTC_SNES_ADDRr <= SNES_ADDRr[5] & SNES_ADDRr[4];

  // special case to flop in the unit
  BSX_SNES_ADDRr <= SNES_ADDRr[4];
end

always @(posedge CLK2) begin
  if(SNES_DEADr & SNES_CPU_CLKr[1]) STATE <= ST_IDLE; // interrupt+restart an ongoing MCU access when the SNES comes alive
  else
  case(STATE)
    ST_IDLE: begin
      STATE <= ST_IDLE;
      if(free_slot | SNES_DEADr) begin
        if(CTX_WR_PENDr) begin
          STATE <= ST_CTX_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(MCU_RD_PENDr) begin
          STATE <= ST_MCU_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(MCU_WR_PENDr) begin
          STATE <= ST_MCU_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(DMA_RD_PENDr) begin
          STATE <= ST_DMA_RD_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
        else if(DMA_WR_PENDr) begin
          STATE <= ST_DMA_WR_ADDR;
          ST_MEM_DELAYr <= ROM_CYCLE_LEN;
        end
      end
    end
    ST_MCU_RD_ADDR: begin
      STATE <= ST_MCU_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_MCU_RD_END;
      MCU_DINr <= (ROM_ADDR0 ? ROM_DATA[7:0] : ROM_DATA[15:8]);
    end
    ST_MCU_WR_ADDR: begin
      STATE <= ST_MCU_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_MCU_WR_END;
    end
    ST_CTX_WR_ADDR: begin
      STATE <= ST_CTX_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_CTX_WR_END;
    end
    ST_DMA_RD_ADDR: begin
      STATE <= ST_DMA_RD_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_DMA_RD_END;
      // FIXME: seems like the lower byte is the upper byte (BIG ENDIAN)?  Maybe a bug in the DMA addressing logic.
      DMA_DINr <= (ROM_ADDR0 ? ROM_DATA : {ROM_DATA[7:0],ROM_DATA[15:8]});
    end
    ST_DMA_WR_ADDR: begin
      STATE <= ST_DMA_WR_ADDR;
      ST_MEM_DELAYr <= ST_MEM_DELAYr - 1;
      if(ST_MEM_DELAYr == 0) STATE <= ST_DMA_WR_END;
    end
//    ST_CTX_WR_END: begin
//      if (CTX_ROM_SNESCAST_ENABLEr) begin
//        // write the snescast address
//        STATE <= ST_CTX_WR_ADDR;
//        ST_MEM_DELAYr <= ROM_CYCLE_LEN;
//      end
//      else begin
//        STATE <= ST_IDLE;
//      end
//    end
    ST_MCU_RD_END, ST_MCU_WR_END, ST_CTX_WR_END, ST_DMA_RD_END, ST_DMA_WR_END: begin
      STATE <= ST_IDLE;
    end
  endcase
end

always @(posedge CLK2) begin
  if(SNES_cycle_end) r213f_forceread <= 1'b1;
  else if(SNES_PARD_start & r213f_enable) begin
//    r213f_delay <= 3'b000;
//    r213f_state <= 2'b10;
//  end else if(r213f_state == 2'b10) begin
//    r213f_delay <= r213f_delay - 1;
//    if(r213f_delay == 3'b000) begin
      r213f_forceread <= 1'b0;
      r213f_state <= 2'b01;
      r213fr <= {SNES_DATA[7:5], mcu_region, SNES_DATA[3:0]};
//    end
  end
end

reg MCU_WRITE_1;
always @(posedge CLK2) MCU_WRITE_1<= MCU_WRITE;

assign ROM_DATA[7:0] = (ROM_ADDR0 || (!SD_DMA_TO_ROM && CTX_HIT && CTX_ROM_WORDr) || (!SD_DMA_TO_ROM && DMA_HIT && DMA_ROM_WORDr))
                       ?(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        : CTX_WR_HIT ? CTX_ROM_DATAr[15:8]
                                        : DMA_WR_HIT ? DMA_ROM_DATAr[15:8]
                                        : ((ROM_HIT/* | cpureg_enable*/) & ~loop_enable & ~SNES_WRITE) ? SNES_DATA
                                        : MCU_WR_HIT ? MCU_DOUT : 8'bZ
                        )
                       :8'bZ;

assign ROM_DATA[15:8] = ROM_ADDR0 ? 8'bZ
                        :(SD_DMA_TO_ROM ? (!MCU_WRITE_1 ? MCU_DOUT : 8'bZ)
                                        : CTX_WR_HIT ? CTX_ROM_DATAr[7:0]
                                        : DMA_WR_HIT ? DMA_ROM_DATAr[7:0]
                                        : ((ROM_HIT/* | cpureg_enable*/) & ~loop_enable & ~SNES_WRITE) ? SNES_DATA
                                        : MCU_WR_HIT ? MCU_DOUT
                                        : 8'bZ
                         );

assign ROM_WE = SD_DMA_TO_ROM
                ?MCU_WRITE
                : CTX_WR_HIT ? 1'b0
                : DMA_WR_HIT ? 1'b0
                : ((ROM_HIT/* | cpureg_enable*/) & ~loop_enable & (IS_WRITABLE | IS_FLASHWR/* | cpureg_enable*/) & SNES_CPU_CLK) ? SNES_WRITE
                : MCU_WR_HIT ? 1'b0
                : 1'b1;

// OE always active. Overridden by WE when needed.
assign ROM_OE = 1'b0;

assign ROM_CE = 1'b0;

assign ROM_BHE = ROM_ADDR0;
assign ROM_BLE = !ROM_ADDR0 && !(!SD_DMA_TO_ROM && CTX_HIT && CTX_ROM_WORDr) && !(!SD_DMA_TO_ROM && DMA_HIT && DMA_ROM_WORDr);

wire cart_read_oe = ( (IS_ROM & SNES_ROMSEL)
                    | (!IS_ROM & !IS_SAVERAM & !(IS_WRITABLE/* | cpureg_enable*/) & !IS_FLASHWR)
                    | (SNES_READ & SNES_WRITE)
                    | (bsx_tristate)
                    );

assign SNES_DATABUS_OE = (dspx_enable | dspx_dp_enable) ? 1'b0 :
                         msu_enable ? 1'b0 :
                         //usb_enable ? 1'b0 :
                         dma_enable ? 1'b0 :
                         loop_enable ? SNES_READ :
                         bsx_data_ovr ? (SNES_READ & SNES_WRITE) :
                         srtc_enable ? (SNES_READ & SNES_WRITE) :
                         snescmd_enable ? (~(snescmd_unlock | feat_cmd_unlock) | (SNES_READ & SNES_WRITE)) :
                         bs_page_enable ? (SNES_READ) :
                         r213f_enable & !SNES_PARD ? 1'b0 :
                         snoop_4200_enable ? SNES_WRITE :
                         (ctx_wr_enable & SNES_SNOOPWR_DATA_OE) ? 1'b0 :
                         (ctx_pawr_enable & SNES_PAWR_DATA_OE)? 1'b0 :
                         (ctx_pard_enable & SNES_PARD_DATA_OE)? 1'b0 :
                         (msu_rd_enable & SNES_SNOOPRD_DATA_OE) ? 1'b0 :
                         cart_read_oe;

// snoop WR isn't necessary here because you can't assert RD and WR at the same time
assign SNES_DATABUS_DIR = ((~SNES_READ & ((~SNES_PAWR_DATA_OE & ~SNES_PARD_DATA_OE & ~(SNES_SNOOPRD_DATA_OE & msu_rd_enable)/*& ~ctx_rd_enable & ~msu_rd_enable*/) | ~SNES_ROMSEL_EARLY)) | (~SNES_PARD & (r213f_enable)))
                           ? 1'b1 ^ (r213f_forceread & r213f_enable & ~SNES_PARD)
                           : 1'b0;

assign SNES_IRQ = 1'b0;

//assign p113_out = 1'b0;
assign p113_out = CTX_DBG;

snescmd_buf snescmd (
  .clka(CLK2), // input clka
  .wea(SNES_WR_end & ((snescmd_unlock | feat_cmd_unlock) & snescmd_enable)), // input [0 : 0] wea
  // don't swizzle the address.  the first $200 bytes will not be used
  //.addra({SNES_ADDR[10:0]}), // input [10 : 0] addra
  .addra({SNES_ADDR[10:0]}), // input [10 : 0] addra
  .dina(SNES_DATA), // input [7 : 0] dina
  .douta(snescmd_dout), // output [7 : 0] douta
  .clkb(CLK2), // input clkb
  .web(snescmd_we_mcu), // input [0 : 0] web
  .addrb(snescmd_addr_mcu[10:0]), // input [10 : 0] addrb
  .dinb(snescmd_data_out_mcu), // input [7 : 0] dinb
  .doutb(snescmd_data_in_mcu) // output [7 : 0] doutb
);

always @(posedge CLK2) begin 
  if (SNES_WR_end & (snescmd_unlock | feat_cmd_unlock) & exe_enable) exe_present <= (SNES_DATA != 0) ? 1 : 0;
  else if (snescmd_we_mcu & (snescmd_addr_mcu == 11'h400))           exe_present <= (snescmd_data_out_mcu != 0) ? 1 : 0;
end

// spin loop state machine
// This is used to put the SNES into a spin loop.  It replaces the current instruction fetch with a branch
// to itself.  Upon release it lets the SNES fetch.
// TODO: add this to a more general-purpose debug module
reg loop_state;
initial loop_state = 0;
parameter [`upper(2):0] loop_code = { 8'h80, 8'hFE // BRA $FE
                                   };

always @(posedge CLK2) begin

  if (!loop_enable) begin
    loop_enable <= DMA_LOOP_ENABLE;
  end  
  else begin
    case (loop_state)
      0: begin
        if (SNES_RD_end) begin
          loop_state <= 1;
          loop_data <= loop_code[`upper(0):`lower(0)];
        end
      end
      1: begin
        if (SNES_RD_end) begin
          loop_state <= 0;
          loop_data <= loop_code[`upper(1):`lower(1)];
          loop_enable <= DMA_LOOP_ENABLE;
        end
      end
    endcase
  end
end

//// CPU reg NMI exit state machine
//// TODO: this should probably be on an enable since it can cause timing differences
//reg [1:0] cpureg_state;
//reg [4:0] cpureg_index;
//reg [7:0] cpureg_nmistack[3:0];
//reg [23:0] cpureg_ret;
//
//wire cpureg_nmijmp_start = ({SNES_ADDR == 24'h00FFEA}) && SNES_RD_start;
//wire cpureg_nmiret_start = (SNES_ADDR == cpureg_ret) && SNES_RD_start;
//
//reg [7:0] cpureg_code[30:0];
//initial begin
//  cpureg_code[0]  = 8'h00; cpureg_code[1]  = 8'hEA;                                                   // BRK
//  cpureg_code[2]  = 8'h00; cpureg_code[3]  = 8'h80;                                                   // $8000 BRK target
//  cpureg_code[4]  = 8'hC2; cpureg_code[5]  = 8'h20;                                                   // REP #20
//  cpureg_code[6]  = 8'h48;                                                                            // PHA
//  cpureg_code[7]  = 8'hAF; cpureg_code[8]  = 8'h18; cpureg_code[9]  = 8'h42; cpureg_code[10] = 8'h00; // LDA.l $004218
//  cpureg_code[11] = 8'h8F; cpureg_code[12] = 8'h18; cpureg_code[13] = 8'h07; cpureg_code[14] = 8'hF9; // STA.l $F90718
//  cpureg_code[15] = 8'hAF; cpureg_code[16] = 8'h1A; cpureg_code[17] = 8'h42; cpureg_code[18] = 8'h00; // LDA.l $00421A
//  cpureg_code[19] = 8'h8F; cpureg_code[20] = 8'h1A; cpureg_code[21] = 8'h07; cpureg_code[22] = 8'hF9; // STA.l $F9071A
//  cpureg_code[23] = 8'hA3; cpureg_code[24] = 8'h04;                                                   // LDA 4,s
//  cpureg_code[25] = 8'h3A; cpureg_code[26] = 8'h3A;                                                   // DEC, DEC
//  cpureg_code[27] = 8'h83; cpureg_code[28] = 8'h04;                                                   // STA 4,s
//  cpureg_code[29] = 8'h68;                                                                            // PLA
//  cpureg_code[30] = 8'h40;                                                                            // RTI
//end
//
//assign cpureg_enable = (cpureg_state == 2) && ~SNES_ROMSEL;
//assign cpureg_data = cpureg_code[cpureg_index];
//
//always @(posedge CLK2) begin
//  if (SNES_reset_strobe) begin
//    cpureg_state <= 0;
//    cpureg_index <= 0;
//  end
//  else begin
//
//    // Rely on context engine to enable the level shifter
//    if (SNES_WR_end) begin
//      cpureg_nmistack[3] <= cpureg_nmistack[2];
//      cpureg_nmistack[2] <= cpureg_nmistack[1];
//      cpureg_nmistack[1] <= cpureg_nmistack[0];
//      cpureg_nmistack[0] <= SNES_DATA;
//    end
//
//    if (cpureg_state == 0) begin
//      if (cpureg_nmijmp_start) begin
//        cpureg_state <= 1;
//        cpureg_ret <= {cpureg_nmistack[3],cpureg_nmistack[2],cpureg_nmistack[1]};
//      end
//    end
//    else if (cpureg_state == 1) begin
//      if (cpureg_nmiret_start) begin
//        if (~SNES_ROMSEL) begin
//          cpureg_state <= 2;
//        end
//        else begin
//          cpureg_state <= 0;
//          cpureg_index <= 0;
//        end
//      end
//    end
//    else begin
//      if (cpureg_nmijmp_start) begin
//        cpureg_state <= 1;
//        // FIXME: the stack is broken here because the wrong return address is present
//        // we could provide a read interface to it and overwrite it.
//        cpureg_ret <= {cpureg_nmistack[3],cpureg_nmistack[2],cpureg_nmistack[1]};
//      end
//      else if (SNES_RD_end && ~SNES_ROMSEL) begin
//        if (cpureg_index == 30) begin
//          cpureg_index <= 0;
//          cpureg_state <= 0;
//        end
//        else begin
//          cpureg_index <= cpureg_index + 1;
//        end
//      end      
//    end
//    
//  end
//end

/*
wire [35:0] CONTROL0;

chipscope_icon icon (
    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
);

chipscope_ila ila (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(CLK2), // IN
    .TRIG0(SNES_ADDR), // IN BUS [23:0]
    .TRIG1(SNES_DATA), // IN BUS [7:0]
    .TRIG2({SNES_READ, SNES_WRITE, SNES_CPU_CLK, SNES_cycle_start, SNES_cycle_end, SNES_DEADr, MCU_RRQ, MCU_WRQ, MCU_RDY, ROM_WEr, ROM_WE, ROM_DOUT_ENr, ROM_SA, DBG_mcu_nextaddr, SNES_DATABUS_DIR, SNES_DATABUS_OE}),   // IN BUS [15:0]
    .TRIG3({bsx_data_ovr, r213f_forceread, r213f_enable, SNES_PARD, spi_cmd_ready, spi_param_ready, spi_input_data, SD_DAT}), // IN BUS [17:0]
    .TRIG4(ROM_ADDRr), // IN BUS [23:0]
    .TRIG5(ROM_DATA), // IN BUS [15:0]
    .TRIG6(MCU_DINr), // IN BUS [7:0]
   .TRIG7(spi_byte_cnt[3:0])
);

ila_srtc ila (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(CLK2), // IN
    .TRIG0(SD_DMA_DBG_cyclecnt), // IN BUS [23:0]
    .TRIG1(SD_DMA_SRAM_DATA), // IN BUS [7:0]
    .TRIG2({SPI_SCK, SPI_MOSI, SPI_MISO, spi_cmd_ready, SD_DMA_SRAM_WE, SD_DMA_EN, SD_CLK, SD_DAT, SD_DMA_NEXTADDR, SD_DMA_STATUS, 3'b000}),   // IN BUS [15:0]
    .TRIG3({spi_cmd_data, spi_param_data}), // IN BUS [17:0]
    .TRIG4(ROM_ADDRr), // IN BUS [23:0]
    .TRIG5(ROM_DATA), // IN BUS [15:0]
    .TRIG6(MCU_DINr), // IN BUS [7:0]
   .TRIG7(ST_MEM_DELAYr)
);
*/

endmodule
