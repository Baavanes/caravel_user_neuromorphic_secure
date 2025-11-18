/*--------------------------------------*/
/*Secure Top integrado                  */
/*--------------------------------------*/
module secure_top (
  
    input  wire clk,
    input  wire rst,
    input  wire start_logging,
    input  wire [7:0] sensor_data,
    input  wire power_fail_detected,
    input  wire [7:0] re_ram_bus_in,
    output wire [7:0] re_ram_bus_out,
    output wire [7:0] re_ram_oeb,
    output wire done_logging,
    output wire fail_safe,
    output wire ack
);

    wire [7:0] fifo_data_out;
    wire fifo_full, fifo_empty;
    wire log_done, log_fail, log_ack;

    fifo_buffer #(.DATA_WIDTH(8), .DEPTH(16)) fifo_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(start_logging & ~fifo_full),
        .rd_en(~fifo_empty),
        .data_in(sensor_data),
        .data_out(fifo_data_out),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    secure_logger_controller logger_inst (
        .clk(clk),
        .rst(rst),
        .start(start_logging),
        .fifo_data_in(fifo_data_out),
        .fifo_empty(fifo_empty),
        .power_fail(power_fail_detected),
        .re_ram_bus_out(re_ram_bus_out),
        .re_ram_oeb(re_ram_oeb),
        .done(log_done),
        .fail(log_fail),
        .ack(log_ack)
    );

    assign done_logging = log_done;
    assign fail_safe   = log_fail;
    assign ack         = log_ack;

endmodule
