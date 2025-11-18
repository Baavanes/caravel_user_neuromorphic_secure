`timescale 1ns/1ps
`default_nettype none

/*--------------------------------------*/
/* FIFO buffer para almacenar datos      */
/*--------------------------------------*/
module fifo_buffer #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire clk,
    input  wire rst,
    input  wire wr_en,
    input  wire rd_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output wire empty,
    output wire full
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr = 0, rd_ptr = 0;
    reg [PTR_WIDTH:0] count = 0;

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            data_out <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= data_in;
                wr_ptr <= wr_ptr + 1;
                count <= count + 1;
            end
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
                count <= count - 1;
            end
        end
    end
endmodule
