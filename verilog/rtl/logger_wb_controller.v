/*--------------------------------------*/
/* Controlador Wishbone                  */
/*--------------------------------------*/
module logger_wb_controller #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32
)(
    input  wire wb_clk_i,
    input  wire wb_rst_i,
    input  wire wbs_stb_i,
    input  wire wbs_cyc_i,
    input  wire wbs_we_i,
    input  wire [ADDR_WIDTH-1:0] wbs_adr_i,
    input  wire [DATA_WIDTH-1:0] wbs_dat_i,
    output reg  [DATA_WIDTH-1:0] wbs_dat_o,
    output reg                   wbs_ack_o,
    output reg                   start_logging
);

    reg ctrl_reg;
    localparam CTRL_REG_ADDR = 0;

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            wbs_ack_o <= 0;
            wbs_dat_o <= 0;
            start_logging <= 0;
            ctrl_reg <= 0;
        end else begin
            wbs_ack_o <= 0;
            start_logging <= 0;
            if (wbs_cyc_i && wbs_stb_i && !wbs_ack_o) begin
                wbs_ack_o <= 1;
                if (wbs_we_i && wbs_adr_i == CTRL_REG_ADDR) begin
                    ctrl_reg <= wbs_dat_i[0];
                    start_logging <= wbs_dat_i[0];
                end else begin
                    wbs_dat_o <= {31'b0, ctrl_reg};
                end
            end
        end
    end
endmodule
