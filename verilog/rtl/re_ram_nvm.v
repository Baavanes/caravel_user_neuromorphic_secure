/*--------------------------------------*/
/* ReRAM NVM                              */
/*--------------------------------------*/
module re_ram_nvm #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg  ack
);
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (rst) begin
            ack <= 0;
            data_out <= 0;
        end else if (we) begin
            mem[addr] <= data_in;
            ack <= 1;
        end else begin
            data_out <= mem[addr];
            ack <= 1;
        end
    end
endmodule


