// THIS FILE IS AUTOGENERATED BY wb_intercon_gen
// ANY MANUAL CHANGES WILL BE LOST
wire [31:0] wb_m2s_or1k_i_adr;
wire [31:0] wb_m2s_or1k_i_dat;
wire  [3:0] wb_m2s_or1k_i_sel;
wire        wb_m2s_or1k_i_we;
wire        wb_m2s_or1k_i_cyc;
wire        wb_m2s_or1k_i_stb;
wire  [2:0] wb_m2s_or1k_i_cti;
wire  [1:0] wb_m2s_or1k_i_bte;
wire [31:0] wb_s2m_or1k_i_dat;
wire        wb_s2m_or1k_i_ack;
wire        wb_s2m_or1k_i_err;
wire        wb_s2m_or1k_i_rty;
wire [31:0] wb_m2s_or1k_d_adr;
wire [31:0] wb_m2s_or1k_d_dat;
wire  [3:0] wb_m2s_or1k_d_sel;
wire        wb_m2s_or1k_d_we;
wire        wb_m2s_or1k_d_cyc;
wire        wb_m2s_or1k_d_stb;
wire  [2:0] wb_m2s_or1k_d_cti;
wire  [1:0] wb_m2s_or1k_d_bte;
wire [31:0] wb_s2m_or1k_d_dat;
wire        wb_s2m_or1k_d_ack;
wire        wb_s2m_or1k_d_err;
wire        wb_s2m_or1k_d_rty;
wire [31:0] wb_m2s_dbg_adr;
wire [31:0] wb_m2s_dbg_dat;
wire  [3:0] wb_m2s_dbg_sel;
wire        wb_m2s_dbg_we;
wire        wb_m2s_dbg_cyc;
wire        wb_m2s_dbg_stb;
wire  [2:0] wb_m2s_dbg_cti;
wire  [1:0] wb_m2s_dbg_bte;
wire [31:0] wb_s2m_dbg_dat;
wire        wb_s2m_dbg_ack;
wire        wb_s2m_dbg_err;
wire        wb_s2m_dbg_rty;
wire [31:0] wb_m2s_flash0_adr;
wire [31:0] wb_m2s_flash0_dat;
wire  [3:0] wb_m2s_flash0_sel;
wire        wb_m2s_flash0_we;
wire        wb_m2s_flash0_cyc;
wire        wb_m2s_flash0_stb;
wire  [2:0] wb_m2s_flash0_cti;
wire  [1:0] wb_m2s_flash0_bte;
wire [31:0] wb_s2m_flash0_dat;
wire        wb_s2m_flash0_ack;
wire        wb_s2m_flash0_err;
wire        wb_s2m_flash0_rty;
wire [31:0] wb_m2s_eth_rx_dma_adr;
wire [31:0] wb_m2s_eth_rx_dma_dat;
wire  [3:0] wb_m2s_eth_rx_dma_sel;
wire        wb_m2s_eth_rx_dma_we;
wire        wb_m2s_eth_rx_dma_cyc;
wire        wb_m2s_eth_rx_dma_stb;
wire  [2:0] wb_m2s_eth_rx_dma_cti;
wire  [1:0] wb_m2s_eth_rx_dma_bte;
wire [31:0] wb_s2m_eth_rx_dma_dat;
wire        wb_s2m_eth_rx_dma_ack;
wire        wb_s2m_eth_rx_dma_err;
wire        wb_s2m_eth_rx_dma_rty;
wire [31:0] wb_m2s_eth_tx_dma_adr;
wire [31:0] wb_m2s_eth_tx_dma_dat;
wire  [3:0] wb_m2s_eth_tx_dma_sel;
wire        wb_m2s_eth_tx_dma_we;
wire        wb_m2s_eth_tx_dma_cyc;
wire        wb_m2s_eth_tx_dma_stb;
wire  [2:0] wb_m2s_eth_tx_dma_cti;
wire  [1:0] wb_m2s_eth_tx_dma_bte;
wire [31:0] wb_s2m_eth_tx_dma_dat;
wire        wb_s2m_eth_tx_dma_ack;
wire        wb_s2m_eth_tx_dma_err;
wire        wb_s2m_eth_tx_dma_rty;
wire [31:0] wb_m2s_ddr2_dbus_adr;
wire [31:0] wb_m2s_ddr2_dbus_dat;
wire  [3:0] wb_m2s_ddr2_dbus_sel;
wire        wb_m2s_ddr2_dbus_we;
wire        wb_m2s_ddr2_dbus_cyc;
wire        wb_m2s_ddr2_dbus_stb;
wire  [2:0] wb_m2s_ddr2_dbus_cti;
wire  [1:0] wb_m2s_ddr2_dbus_bte;
wire [31:0] wb_s2m_ddr2_dbus_dat;
wire        wb_s2m_ddr2_dbus_ack;
wire        wb_s2m_ddr2_dbus_err;
wire        wb_s2m_ddr2_dbus_rty;
wire [31:0] wb_m2s_ddr2_ibus_adr;
wire [31:0] wb_m2s_ddr2_ibus_dat;
wire  [3:0] wb_m2s_ddr2_ibus_sel;
wire        wb_m2s_ddr2_ibus_we;
wire        wb_m2s_ddr2_ibus_cyc;
wire        wb_m2s_ddr2_ibus_stb;
wire  [2:0] wb_m2s_ddr2_ibus_cti;
wire  [1:0] wb_m2s_ddr2_ibus_bte;
wire [31:0] wb_s2m_ddr2_ibus_dat;
wire        wb_s2m_ddr2_ibus_ack;
wire        wb_s2m_ddr2_ibus_err;
wire        wb_s2m_ddr2_ibus_rty;
wire [31:0] wb_m2s_ddr2_loader_adr;
wire [31:0] wb_m2s_ddr2_loader_dat;
wire  [3:0] wb_m2s_ddr2_loader_sel;
wire        wb_m2s_ddr2_loader_we;
wire        wb_m2s_ddr2_loader_cyc;
wire        wb_m2s_ddr2_loader_stb;
wire  [2:0] wb_m2s_ddr2_loader_cti;
wire  [1:0] wb_m2s_ddr2_loader_bte;
wire [31:0] wb_s2m_ddr2_loader_dat;
wire        wb_s2m_ddr2_loader_ack;
wire        wb_s2m_ddr2_loader_err;
wire        wb_s2m_ddr2_loader_rty;
wire [31:0] wb_m2s_ddr2_debug_adr;
wire [31:0] wb_m2s_ddr2_debug_dat;
wire  [3:0] wb_m2s_ddr2_debug_sel;
wire        wb_m2s_ddr2_debug_we;
wire        wb_m2s_ddr2_debug_cyc;
wire        wb_m2s_ddr2_debug_stb;
wire  [2:0] wb_m2s_ddr2_debug_cti;
wire  [1:0] wb_m2s_ddr2_debug_bte;
wire [31:0] wb_s2m_ddr2_debug_dat;
wire        wb_s2m_ddr2_debug_ack;
wire        wb_s2m_ddr2_debug_err;
wire        wb_s2m_ddr2_debug_rty;
wire [31:0] wb_m2s_ddr2_eth_rx_adr;
wire [31:0] wb_m2s_ddr2_eth_rx_dat;
wire  [3:0] wb_m2s_ddr2_eth_rx_sel;
wire        wb_m2s_ddr2_eth_rx_we;
wire        wb_m2s_ddr2_eth_rx_cyc;
wire        wb_m2s_ddr2_eth_rx_stb;
wire  [2:0] wb_m2s_ddr2_eth_rx_cti;
wire  [1:0] wb_m2s_ddr2_eth_rx_bte;
wire [31:0] wb_s2m_ddr2_eth_rx_dat;
wire        wb_s2m_ddr2_eth_rx_ack;
wire        wb_s2m_ddr2_eth_rx_err;
wire        wb_s2m_ddr2_eth_rx_rty;
wire [31:0] wb_m2s_ddr2_eth_tx_adr;
wire [31:0] wb_m2s_ddr2_eth_tx_dat;
wire  [3:0] wb_m2s_ddr2_eth_tx_sel;
wire        wb_m2s_ddr2_eth_tx_we;
wire        wb_m2s_ddr2_eth_tx_cyc;
wire        wb_m2s_ddr2_eth_tx_stb;
wire  [2:0] wb_m2s_ddr2_eth_tx_cti;
wire  [1:0] wb_m2s_ddr2_eth_tx_bte;
wire [31:0] wb_s2m_ddr2_eth_tx_dat;
wire        wb_s2m_ddr2_eth_tx_ack;
wire        wb_s2m_ddr2_eth_tx_err;
wire        wb_s2m_ddr2_eth_tx_rty;
wire [31:0] wb_m2s_uart0_adr;
wire  [7:0] wb_m2s_uart0_dat;
wire  [3:0] wb_m2s_uart0_sel;
wire        wb_m2s_uart0_we;
wire        wb_m2s_uart0_cyc;
wire        wb_m2s_uart0_stb;
wire  [2:0] wb_m2s_uart0_cti;
wire  [1:0] wb_m2s_uart0_bte;
wire  [7:0] wb_s2m_uart0_dat;
wire        wb_s2m_uart0_ack;
wire        wb_s2m_uart0_err;
wire        wb_s2m_uart0_rty;
wire [31:0] wb_m2s_gpio0_adr;
wire [31:0] wb_m2s_gpio0_dat;
wire  [3:0] wb_m2s_gpio0_sel;
wire        wb_m2s_gpio0_we;
wire        wb_m2s_gpio0_cyc;
wire        wb_m2s_gpio0_stb;
wire  [2:0] wb_m2s_gpio0_cti;
wire  [1:0] wb_m2s_gpio0_bte;
wire [31:0] wb_s2m_gpio0_dat;
wire        wb_s2m_gpio0_ack;
wire        wb_s2m_gpio0_err;
wire        wb_s2m_gpio0_rty;
wire [31:0] wb_m2s_spi0_adr;
wire  [7:0] wb_m2s_spi0_dat;
wire  [3:0] wb_m2s_spi0_sel;
wire        wb_m2s_spi0_we;
wire        wb_m2s_spi0_cyc;
wire        wb_m2s_spi0_stb;
wire  [2:0] wb_m2s_spi0_cti;
wire  [1:0] wb_m2s_spi0_bte;
wire  [7:0] wb_s2m_spi0_dat;
wire        wb_s2m_spi0_ack;
wire        wb_s2m_spi0_err;
wire        wb_s2m_spi0_rty;
wire [31:0] wb_m2s_sdr_reg_adr;
wire [31:0] wb_m2s_sdr_reg_dat;
wire  [3:0] wb_m2s_sdr_reg_sel;
wire        wb_m2s_sdr_reg_we;
wire        wb_m2s_sdr_reg_cyc;
wire        wb_m2s_sdr_reg_stb;
wire  [2:0] wb_m2s_sdr_reg_cti;
wire  [1:0] wb_m2s_sdr_reg_bte;
wire [31:0] wb_s2m_sdr_reg_dat;
wire        wb_s2m_sdr_reg_ack;
wire        wb_s2m_sdr_reg_err;
wire        wb_s2m_sdr_reg_rty;

wb_intercon wb_intercon0
   (.wb_clk_i             (wb_clk),
    .wb_rst_i             (wb_rst),
    .wb_or1k_i_adr_i      (wb_m2s_or1k_i_adr),
    .wb_or1k_i_dat_i      (wb_m2s_or1k_i_dat),
    .wb_or1k_i_sel_i      (wb_m2s_or1k_i_sel),
    .wb_or1k_i_we_i       (wb_m2s_or1k_i_we),
    .wb_or1k_i_cyc_i      (wb_m2s_or1k_i_cyc),
    .wb_or1k_i_stb_i      (wb_m2s_or1k_i_stb),
    .wb_or1k_i_cti_i      (wb_m2s_or1k_i_cti),
    .wb_or1k_i_bte_i      (wb_m2s_or1k_i_bte),
    .wb_or1k_i_dat_o      (wb_s2m_or1k_i_dat),
    .wb_or1k_i_ack_o      (wb_s2m_or1k_i_ack),
    .wb_or1k_i_err_o      (wb_s2m_or1k_i_err),
    .wb_or1k_i_rty_o      (wb_s2m_or1k_i_rty),
    .wb_or1k_d_adr_i      (wb_m2s_or1k_d_adr),
    .wb_or1k_d_dat_i      (wb_m2s_or1k_d_dat),
    .wb_or1k_d_sel_i      (wb_m2s_or1k_d_sel),
    .wb_or1k_d_we_i       (wb_m2s_or1k_d_we),
    .wb_or1k_d_cyc_i      (wb_m2s_or1k_d_cyc),
    .wb_or1k_d_stb_i      (wb_m2s_or1k_d_stb),
    .wb_or1k_d_cti_i      (wb_m2s_or1k_d_cti),
    .wb_or1k_d_bte_i      (wb_m2s_or1k_d_bte),
    .wb_or1k_d_dat_o      (wb_s2m_or1k_d_dat),
    .wb_or1k_d_ack_o      (wb_s2m_or1k_d_ack),
    .wb_or1k_d_err_o      (wb_s2m_or1k_d_err),
    .wb_or1k_d_rty_o      (wb_s2m_or1k_d_rty),
    .wb_dbg_adr_i         (wb_m2s_dbg_adr),
    .wb_dbg_dat_i         (wb_m2s_dbg_dat),
    .wb_dbg_sel_i         (wb_m2s_dbg_sel),
    .wb_dbg_we_i          (wb_m2s_dbg_we),
    .wb_dbg_cyc_i         (wb_m2s_dbg_cyc),
    .wb_dbg_stb_i         (wb_m2s_dbg_stb),
    .wb_dbg_cti_i         (wb_m2s_dbg_cti),
    .wb_dbg_bte_i         (wb_m2s_dbg_bte),
    .wb_dbg_dat_o         (wb_s2m_dbg_dat),
    .wb_dbg_ack_o         (wb_s2m_dbg_ack),
    .wb_dbg_err_o         (wb_s2m_dbg_err),
    .wb_dbg_rty_o         (wb_s2m_dbg_rty),
    .wb_flash0_adr_i      (wb_m2s_flash0_adr),
    .wb_flash0_dat_i      (wb_m2s_flash0_dat),
    .wb_flash0_sel_i      (wb_m2s_flash0_sel),
    .wb_flash0_we_i       (wb_m2s_flash0_we),
    .wb_flash0_cyc_i      (wb_m2s_flash0_cyc),
    .wb_flash0_stb_i      (wb_m2s_flash0_stb),
    .wb_flash0_cti_i      (wb_m2s_flash0_cti),
    .wb_flash0_bte_i      (wb_m2s_flash0_bte),
    .wb_flash0_dat_o      (wb_s2m_flash0_dat),
    .wb_flash0_ack_o      (wb_s2m_flash0_ack),
    .wb_flash0_err_o      (wb_s2m_flash0_err),
    .wb_flash0_rty_o      (wb_s2m_flash0_rty),
    .wb_eth_rx_dma_adr_i  (wb_m2s_eth_rx_dma_adr),
    .wb_eth_rx_dma_dat_i  (wb_m2s_eth_rx_dma_dat),
    .wb_eth_rx_dma_sel_i  (wb_m2s_eth_rx_dma_sel),
    .wb_eth_rx_dma_we_i   (wb_m2s_eth_rx_dma_we),
    .wb_eth_rx_dma_cyc_i  (wb_m2s_eth_rx_dma_cyc),
    .wb_eth_rx_dma_stb_i  (wb_m2s_eth_rx_dma_stb),
    .wb_eth_rx_dma_cti_i  (wb_m2s_eth_rx_dma_cti),
    .wb_eth_rx_dma_bte_i  (wb_m2s_eth_rx_dma_bte),
    .wb_eth_rx_dma_dat_o  (wb_s2m_eth_rx_dma_dat),
    .wb_eth_rx_dma_ack_o  (wb_s2m_eth_rx_dma_ack),
    .wb_eth_rx_dma_err_o  (wb_s2m_eth_rx_dma_err),
    .wb_eth_rx_dma_rty_o  (wb_s2m_eth_rx_dma_rty),
    .wb_eth_tx_dma_adr_i  (wb_m2s_eth_tx_dma_adr),
    .wb_eth_tx_dma_dat_i  (wb_m2s_eth_tx_dma_dat),
    .wb_eth_tx_dma_sel_i  (wb_m2s_eth_tx_dma_sel),
    .wb_eth_tx_dma_we_i   (wb_m2s_eth_tx_dma_we),
    .wb_eth_tx_dma_cyc_i  (wb_m2s_eth_tx_dma_cyc),
    .wb_eth_tx_dma_stb_i  (wb_m2s_eth_tx_dma_stb),
    .wb_eth_tx_dma_cti_i  (wb_m2s_eth_tx_dma_cti),
    .wb_eth_tx_dma_bte_i  (wb_m2s_eth_tx_dma_bte),
    .wb_eth_tx_dma_dat_o  (wb_s2m_eth_tx_dma_dat),
    .wb_eth_tx_dma_ack_o  (wb_s2m_eth_tx_dma_ack),
    .wb_eth_tx_dma_err_o  (wb_s2m_eth_tx_dma_err),
    .wb_eth_tx_dma_rty_o  (wb_s2m_eth_tx_dma_rty),
    .wb_ddr2_dbus_adr_o   (wb_m2s_ddr2_dbus_adr),
    .wb_ddr2_dbus_dat_o   (wb_m2s_ddr2_dbus_dat),
    .wb_ddr2_dbus_sel_o   (wb_m2s_ddr2_dbus_sel),
    .wb_ddr2_dbus_we_o    (wb_m2s_ddr2_dbus_we),
    .wb_ddr2_dbus_cyc_o   (wb_m2s_ddr2_dbus_cyc),
    .wb_ddr2_dbus_stb_o   (wb_m2s_ddr2_dbus_stb),
    .wb_ddr2_dbus_cti_o   (wb_m2s_ddr2_dbus_cti),
    .wb_ddr2_dbus_bte_o   (wb_m2s_ddr2_dbus_bte),
    .wb_ddr2_dbus_dat_i   (wb_s2m_ddr2_dbus_dat),
    .wb_ddr2_dbus_ack_i   (wb_s2m_ddr2_dbus_ack),
    .wb_ddr2_dbus_err_i   (wb_s2m_ddr2_dbus_err),
    .wb_ddr2_dbus_rty_i   (wb_s2m_ddr2_dbus_rty),
    .wb_ddr2_ibus_adr_o   (wb_m2s_ddr2_ibus_adr),
    .wb_ddr2_ibus_dat_o   (wb_m2s_ddr2_ibus_dat),
    .wb_ddr2_ibus_sel_o   (wb_m2s_ddr2_ibus_sel),
    .wb_ddr2_ibus_we_o    (wb_m2s_ddr2_ibus_we),
    .wb_ddr2_ibus_cyc_o   (wb_m2s_ddr2_ibus_cyc),
    .wb_ddr2_ibus_stb_o   (wb_m2s_ddr2_ibus_stb),
    .wb_ddr2_ibus_cti_o   (wb_m2s_ddr2_ibus_cti),
    .wb_ddr2_ibus_bte_o   (wb_m2s_ddr2_ibus_bte),
    .wb_ddr2_ibus_dat_i   (wb_s2m_ddr2_ibus_dat),
    .wb_ddr2_ibus_ack_i   (wb_s2m_ddr2_ibus_ack),
    .wb_ddr2_ibus_err_i   (wb_s2m_ddr2_ibus_err),
    .wb_ddr2_ibus_rty_i   (wb_s2m_ddr2_ibus_rty),
    .wb_ddr2_loader_adr_o (wb_m2s_ddr2_loader_adr),
    .wb_ddr2_loader_dat_o (wb_m2s_ddr2_loader_dat),
    .wb_ddr2_loader_sel_o (wb_m2s_ddr2_loader_sel),
    .wb_ddr2_loader_we_o  (wb_m2s_ddr2_loader_we),
    .wb_ddr2_loader_cyc_o (wb_m2s_ddr2_loader_cyc),
    .wb_ddr2_loader_stb_o (wb_m2s_ddr2_loader_stb),
    .wb_ddr2_loader_cti_o (wb_m2s_ddr2_loader_cti),
    .wb_ddr2_loader_bte_o (wb_m2s_ddr2_loader_bte),
    .wb_ddr2_loader_dat_i (wb_s2m_ddr2_loader_dat),
    .wb_ddr2_loader_ack_i (wb_s2m_ddr2_loader_ack),
    .wb_ddr2_loader_err_i (wb_s2m_ddr2_loader_err),
    .wb_ddr2_loader_rty_i (wb_s2m_ddr2_loader_rty),
    .wb_ddr2_debug_adr_o  (wb_m2s_ddr2_debug_adr),
    .wb_ddr2_debug_dat_o  (wb_m2s_ddr2_debug_dat),
    .wb_ddr2_debug_sel_o  (wb_m2s_ddr2_debug_sel),
    .wb_ddr2_debug_we_o   (wb_m2s_ddr2_debug_we),
    .wb_ddr2_debug_cyc_o  (wb_m2s_ddr2_debug_cyc),
    .wb_ddr2_debug_stb_o  (wb_m2s_ddr2_debug_stb),
    .wb_ddr2_debug_cti_o  (wb_m2s_ddr2_debug_cti),
    .wb_ddr2_debug_bte_o  (wb_m2s_ddr2_debug_bte),
    .wb_ddr2_debug_dat_i  (wb_s2m_ddr2_debug_dat),
    .wb_ddr2_debug_ack_i  (wb_s2m_ddr2_debug_ack),
    .wb_ddr2_debug_err_i  (wb_s2m_ddr2_debug_err),
    .wb_ddr2_debug_rty_i  (wb_s2m_ddr2_debug_rty),
    .wb_ddr2_eth_rx_adr_o (wb_m2s_ddr2_eth_rx_adr),
    .wb_ddr2_eth_rx_dat_o (wb_m2s_ddr2_eth_rx_dat),
    .wb_ddr2_eth_rx_sel_o (wb_m2s_ddr2_eth_rx_sel),
    .wb_ddr2_eth_rx_we_o  (wb_m2s_ddr2_eth_rx_we),
    .wb_ddr2_eth_rx_cyc_o (wb_m2s_ddr2_eth_rx_cyc),
    .wb_ddr2_eth_rx_stb_o (wb_m2s_ddr2_eth_rx_stb),
    .wb_ddr2_eth_rx_cti_o (wb_m2s_ddr2_eth_rx_cti),
    .wb_ddr2_eth_rx_bte_o (wb_m2s_ddr2_eth_rx_bte),
    .wb_ddr2_eth_rx_dat_i (wb_s2m_ddr2_eth_rx_dat),
    .wb_ddr2_eth_rx_ack_i (wb_s2m_ddr2_eth_rx_ack),
    .wb_ddr2_eth_rx_err_i (wb_s2m_ddr2_eth_rx_err),
    .wb_ddr2_eth_rx_rty_i (wb_s2m_ddr2_eth_rx_rty),
    .wb_ddr2_eth_tx_adr_o (wb_m2s_ddr2_eth_tx_adr),
    .wb_ddr2_eth_tx_dat_o (wb_m2s_ddr2_eth_tx_dat),
    .wb_ddr2_eth_tx_sel_o (wb_m2s_ddr2_eth_tx_sel),
    .wb_ddr2_eth_tx_we_o  (wb_m2s_ddr2_eth_tx_we),
    .wb_ddr2_eth_tx_cyc_o (wb_m2s_ddr2_eth_tx_cyc),
    .wb_ddr2_eth_tx_stb_o (wb_m2s_ddr2_eth_tx_stb),
    .wb_ddr2_eth_tx_cti_o (wb_m2s_ddr2_eth_tx_cti),
    .wb_ddr2_eth_tx_bte_o (wb_m2s_ddr2_eth_tx_bte),
    .wb_ddr2_eth_tx_dat_i (wb_s2m_ddr2_eth_tx_dat),
    .wb_ddr2_eth_tx_ack_i (wb_s2m_ddr2_eth_tx_ack),
    .wb_ddr2_eth_tx_err_i (wb_s2m_ddr2_eth_tx_err),
    .wb_ddr2_eth_tx_rty_i (wb_s2m_ddr2_eth_tx_rty),
    .wb_uart0_adr_o       (wb_m2s_uart0_adr),
    .wb_uart0_dat_o       (wb_m2s_uart0_dat),
    .wb_uart0_sel_o       (wb_m2s_uart0_sel),
    .wb_uart0_we_o        (wb_m2s_uart0_we),
    .wb_uart0_cyc_o       (wb_m2s_uart0_cyc),
    .wb_uart0_stb_o       (wb_m2s_uart0_stb),
    .wb_uart0_cti_o       (wb_m2s_uart0_cti),
    .wb_uart0_bte_o       (wb_m2s_uart0_bte),
    .wb_uart0_dat_i       (wb_s2m_uart0_dat),
    .wb_uart0_ack_i       (wb_s2m_uart0_ack),
    .wb_uart0_err_i       (wb_s2m_uart0_err),
    .wb_uart0_rty_i       (wb_s2m_uart0_rty),
    .wb_gpio0_adr_o       (wb_m2s_gpio0_adr),
    .wb_gpio0_dat_o       (wb_m2s_gpio0_dat),
    .wb_gpio0_sel_o       (wb_m2s_gpio0_sel),
    .wb_gpio0_we_o        (wb_m2s_gpio0_we),
    .wb_gpio0_cyc_o       (wb_m2s_gpio0_cyc),
    .wb_gpio0_stb_o       (wb_m2s_gpio0_stb),
    .wb_gpio0_cti_o       (wb_m2s_gpio0_cti),
    .wb_gpio0_bte_o       (wb_m2s_gpio0_bte),
    .wb_gpio0_dat_i       (wb_s2m_gpio0_dat),
    .wb_gpio0_ack_i       (wb_s2m_gpio0_ack),
    .wb_gpio0_err_i       (wb_s2m_gpio0_err),
    .wb_gpio0_rty_i       (wb_s2m_gpio0_rty),
    .wb_spi0_adr_o        (wb_m2s_spi0_adr),
    .wb_spi0_dat_o        (wb_m2s_spi0_dat),
    .wb_spi0_sel_o        (wb_m2s_spi0_sel),
    .wb_spi0_we_o         (wb_m2s_spi0_we),
    .wb_spi0_cyc_o        (wb_m2s_spi0_cyc),
    .wb_spi0_stb_o        (wb_m2s_spi0_stb),
    .wb_spi0_cti_o        (wb_m2s_spi0_cti),
    .wb_spi0_bte_o        (wb_m2s_spi0_bte),
    .wb_spi0_dat_i        (wb_s2m_spi0_dat),
    .wb_spi0_ack_i        (wb_s2m_spi0_ack),
    .wb_spi0_err_i        (wb_s2m_spi0_err),
    .wb_spi0_rty_i        (wb_s2m_spi0_rty),
    .wb_sdr_reg_adr_o     (wb_m2s_sdr_reg_adr),
    .wb_sdr_reg_dat_o     (wb_m2s_sdr_reg_dat),
    .wb_sdr_reg_sel_o     (wb_m2s_sdr_reg_sel),
    .wb_sdr_reg_we_o      (wb_m2s_sdr_reg_we),
    .wb_sdr_reg_cyc_o     (wb_m2s_sdr_reg_cyc),
    .wb_sdr_reg_stb_o     (wb_m2s_sdr_reg_stb),
    .wb_sdr_reg_cti_o     (wb_m2s_sdr_reg_cti),
    .wb_sdr_reg_bte_o     (wb_m2s_sdr_reg_bte),
    .wb_sdr_reg_dat_i     (wb_s2m_sdr_reg_dat),
    .wb_sdr_reg_ack_i     (wb_s2m_sdr_reg_ack),
    .wb_sdr_reg_err_i     (wb_s2m_sdr_reg_err),
    .wb_sdr_reg_rty_i     (wb_s2m_sdr_reg_rty));

