//-----------------------------------------------------------------
// TOP
//-----------------------------------------------------------------
module top
(
     input           clk50_i
    ,output          led_o

    // UART
    ,input           uart_txd_i
    ,output          uart_rxd_o

    // SPI-Flash
    ,output          flash_sck_o
    ,output          flash_cs_o
    ,output          flash_si_o
    ,input           flash_so_i
);

//-----------------------------------------------------------------
// Reset
//-----------------------------------------------------------------
wire rst;

reset_gen
u_rst
(
    .clk_i(clk50_i),
    .rst_o(rst)
);

//-----------------------------------------------------------------
// Core
//-----------------------------------------------------------------
wire       dbg_txd_w;
wire       uart_txd_w;

wire       spi_clk_w;
wire       spi_so_w;
wire       spi_si_w;
wire [7:0] spi_cs_w;

fpga_top
#(
    .CLK_FREQ(50000000)
   ,.BAUDRATE(1000000)   // SoC UART baud rate
   ,.UART_SPEED(1000000) // Debug bridge UART baud (should match BAUDRATE)
   ,.C_SCK_RATIO(50)     // SPI clock divider (SPI_CLK=CLK_FREQ/C_SCK_RATIO)
`ifdef CPU_SELECT_ARMV6M
   ,.CPU("armv6m")       // riscv or armv6m
`else
   ,.CPU("riscv")        // riscv or armv6m
`endif
)
u_top
(
     .clk_i(clk50_i)
    ,.rst_i(rst)

    ,.dbg_rxd_o(dbg_txd_w)
    ,.dbg_txd_i(uart_txd_i)

    ,.uart_tx_o(uart_txd_w)
    ,.uart_rx_i(uart_txd_i)

    ,.spi_clk_o(spi_clk_w)
    ,.spi_mosi_o(spi_si_w)
    ,.spi_miso_i(spi_so_w)
    ,.spi_cs_o(spi_cs_w)

    ,.gpio_input_i(32'b0)
    ,.gpio_output_o()
    ,.gpio_output_enable_o()
);

assign flash_sck_o = spi_clk_w;
assign flash_si_o  = spi_si_w;
assign flash_cs_o  = spi_cs_w[0];
assign spi_so_w    = flash_so_i;

//-----------------------------------------------------------------
// UART Tx combine
//-----------------------------------------------------------------
// Xilinx placement pragmas:
//synthesis attribute IOB of txd_q is "TRUE"
reg txd_q;

always @ (posedge clk50_i or posedge rst)
if (rst)
    txd_q <= 1'b1;
else
    txd_q <= dbg_txd_w & uart_txd_w;

// 'OR' two UARTs together
assign uart_rxd_o  = txd_q;
assign led_o       = uart_rxd_o;

endmodule
