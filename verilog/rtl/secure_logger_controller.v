/*--------------------------------------*/
/* Logger seguro                           */
/*--------------------------------------*/
module secure_logger_controller (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire [7:0] fifo_data_in,
    input  wire fifo_empty,
    input  wire power_fail,
    output reg  [7:0] re_ram_bus_out,
    output reg  [7:0] re_ram_oeb,
    output reg  done,
    output reg  fail,
    output reg  ack
);

    reg [7:0] addr;
    reg logging;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr <= 0;
            logging <= 0;
            re_ram_bus_out <= 0;
            re_ram_oeb <= 8'hFF;
            done <= 0;
            fail <= 0;
            ack <= 0;
        end else begin
            if (start) begin
                logging <= 1;
                done <= 0;
                fail <= 0;
                addr <= 0;
            end

            if (logging && !fifo_empty) begin
                re_ram_bus_out <= fifo_data_in;
                re_ram_oeb <= 8'h00; // Habilita escritura
                ack <= 1;
                addr <= addr + 1;
                if (addr == 15) begin
                    logging <= 0;
                    done <= 1;
                    re_ram_oeb <= 8'hFF;
                end
            end

            if (power_fail) begin
                logging <= 0;
                fail <= 1;
                re_ram_oeb <= 8'hFF;
            end
        end
    end
endmodule
