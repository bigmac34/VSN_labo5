
`include "transactions.sv"
`include "interfaces.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"


module packet_analyzer_tb#(int TESTCASE = 0, int ERRNO = 0);

    ble_itf input_itf();
    usb_itf output_itf();

    ble_packet_analyzer#(ERRNO,0) dut(
        .clk_i(input_itf.clk_i),
        .rst_i(input_itf.rst_i),
        .serial_i(input_itf.serial_i),
        .valid_i(input_itf.valid_i),
        .channel_i(input_itf.channel_i),
        .rssi_i(input_itf.rssi_i),
        .data_o(output_itf.data_o),
        .valid_o(output_itf.valid_o),
        .frame_o(output_itf.frame_o)
    );

    // génération de l'horloge
    always #5 input_itf.clk_i = ~input_itf.clk_i;

    assign output_itf.clk_i = input_itf.clk_i;

    Environment env;


    initial begin

        env = new;

        env.input_itf = input_itf;
        env.output_itf = output_itf;
        env.testcase = TESTCASE;
        env.build;
        env.run();
        $finish;
    end

endmodule
