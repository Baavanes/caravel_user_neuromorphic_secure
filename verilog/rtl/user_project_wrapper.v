`timescale 1ns / 1ps
`default_nettype none

module user_project_wrapper #(
    parameter int BITS = 32
)(
`ifdef USE_POWER_PINS
    inout wire vdda1,
    inout wire vdda2,   // agregado
    inout wire vssa1,
    inout wire vssa2,   // agregado
    inout wire vccd1,
    inout wire vccd2,   // agregado
    inout wire vssd1,
    inout wire vssd2,   // agregado
`endif
    // Wishbone Slave
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        wbs_stb_i,
    input  wire        wbs_cyc_i,
    input  wire        wbs_we_i,
    input  wire [31:0] wbs_adr_i,
    input  wire [31:0] wbs_dat_i,
    output wire [31:0] wbs_dat_o,
    output wire        wbs_ack_o,

    // Logic Analyzer
    input  wire  [127:0] la_data_in,
    output wire  [127:0] la_data_out,
    input  wire  [127:0] la_oenb,

    // GPIO
    input  wire  [37:0] io_in,
    output wire [37:0] io_out,
    output wire [37:0] io_oeb,

    // Analog (no usado)
    inout  wire [28:0] analog_io,

    // IRQ
    output wire [2:0] user_irq,

    // Extra clocks / WB select
    input  wire user_clock2,
    input  wire [3:0] wbs_sel_i
);

    localparam [31:0] NEURO_BASE   = 32'h3000_0000;  // Neuromorphic module
    localparam [31:0] MATMUL_BASE  = 32'h3100_0000;  // Matrix multiplier
    localparam [31:0] MPRJ_MASK    = 32'hFFFF_F000;  // 4KB region mask
		
    wire sel_neuro  = ((wbs_adr_i & MPRJ_MASK) == NEURO_BASE);
    wire sel_matmul = ((wbs_adr_i & MPRJ_MASK) == MATMUL_BASE);

    // Gate cyc/stb for each module
    wire wbs_cyc_i_neuro  = wbs_cyc_i & sel_neuro;
    wire wbs_stb_i_neuro  = wbs_stb_i & sel_neuro;

    wire wbs_cyc_i_matmul = wbs_cyc_i & sel_matmul;
    wire wbs_stb_i_matmul = wbs_stb_i & sel_matmul;

    // Return paths from each module
    wire        wbs_ack_o_neuro,  wbs_ack_o_matmul;
    wire [31:0] wbs_dat_o_neuro,  wbs_dat_o_matmul;

    //-----------------------------------
    // Pines usados (sensores + RAM)
    //-----------------------------------
    wire [7:0] sensor_data_in  = io_in[7:0];
    wire [7:0] re_ram_bus_in   = io_in[15:8];
    wire [7:0] re_ram_bus_out;
    wire [7:0] re_ram_oeb;
    wire       done_logging;
    wire       fail_safe;
    wire       ack;

    assign io_oeb[7:0]   = 8'hFF;
    assign io_oeb[15:8]  = re_ram_oeb;
    assign io_oeb[37:16] = {22{1'b1}};

    //assign io_out[7:0]   = 8'b0;
    assign io_out[15:8]  = re_ram_bus_out;
    assign io_out[37:16] = {22{1'b0}};

    //-----------------------------------
    // Controlador Wishbone para logging
    //-----------------------------------
    wire start_logging_signal;
    logger_wb_controller logger_wb_inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i_matmul),
        .wbs_cyc_i(wbs_cyc_i_matmul),
        .wbs_we_i(wbs_we_i),
        .wbs_adr_i(wbs_adr_i[3:0]),
        .wbs_dat_i(wbs_dat_i),
        .wbs_dat_o(wbs_dat_o_matmul),
        .wbs_ack_o(wbs_ack_o_matmul),
        .start_logging(start_logging_signal)
    );

    //-----------------------------------
    // Instancia principal del core
    //-----------------------------------
    secure_top secure_top_inst (
        .clk(wb_clk_i),
        .rst(wb_rst_i),
        .start_logging(start_logging_signal),
        .sensor_data(sensor_data_in),
        .power_fail_detected(io_in[0]),
        .re_ram_bus_in(re_ram_bus_in),
        .re_ram_bus_out(re_ram_bus_out),
        .re_ram_oeb(re_ram_oeb),
        .done_logging(done_logging),
        .fail_safe(fail_safe),
        .ack(ack)

    );

Neuromorphic_X1_wb mprj (
`ifdef USE_POWER_PINS
        .VDDC (vccd1),
        .VDDA (vdda1),
        .VSS  (vssd1),
`endif

        // Clocks / resets
        .user_clk (wb_clk_i),
        .user_rst (wb_rst_i),
        .wb_clk_i (wb_clk_i),
        .wb_rst_i (wb_rst_i),

        // Wishbone (gated)
        .wbs_stb_i (wbs_stb_i_neuro),
        .wbs_cyc_i (wbs_cyc_i_neuro),
        .wbs_we_i  (wbs_we_i),
        .wbs_sel_i (wbs_sel_i),
        .wbs_dat_i (wbs_dat_i),
        .wbs_adr_i (wbs_adr_i),
        .wbs_dat_o (wbs_dat_o_neuro),
        .wbs_ack_o (wbs_ack_o_neuro),

        // Scan/Test
        .ScanInCC  (io_in[4]),
        .ScanInDL  (io_in[1]),
        .ScanInDR  (io_in[2]),
        .TM        (io_in[5]),
        .ScanOutCC (io_out[0]),

        // Analog / bias pins (drive from analog_io[] wires you already built)
        .Iref          (analog_io[0]),
        .Vcc_read      (analog_io[1]),
        .Vcomp         (analog_io[2]),
        .Bias_comp2    (analog_io[3]),
        .Vcc_wl_read   (analog_io[12]),
        .Vcc_wl_set    (analog_io[5]),
        .Vbias         (analog_io[6]),
        .Vcc_wl_reset  (analog_io[7]),
        .Vcc_set       (analog_io[8]),
        .Vcc_reset     (analog_io[9]),
        .Vcc_L         (analog_io[10]),
        .Vcc_Body      (analog_io[11])
    );

    //-----------------------------------
    // Interrupciones de usuario
    //-----------------------------------
    assign user_irq = {fail_safe, done_logging, ack};

    //-----------------------------------
    // LÃÂ³gica de LA
    //-----------------------------------
    assign la_data_out = 128'b0;

    //-----------------------------------
    // Pines no usados
    //-----------------------------------
    assign analog_io = 29'd0;
		
		assign wbs_ack_o = (sel_neuro  ? wbs_ack_o_neuro  : 1'b0)
                     | (sel_matmul ? wbs_ack_o_matmul : 1'b0);

    assign wbs_dat_o = sel_neuro  ? wbs_dat_o_neuro  :
                       sel_matmul ? wbs_dat_o_matmul :
                       32'h0000_0000;

endmodule

`default_nettype wire

