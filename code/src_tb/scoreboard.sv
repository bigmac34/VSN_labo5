`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV


class Scoreboard;

    int testcase;
    
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

    task run;
        automatic BlePacket ble_packet = new;
        automatic AnalyzerUsbPacket usb_packet = new;

        $display("Scoreboard : Start");


        for(int i=0; i< 10; i++) begin
            sequencer_to_scoreboard_fifo.get(ble_packet);
//            monitor_to_scoreboard_fifo.get(usb_packet);
            // Check that everything is fine

        end

        $display("Scoreboard : End");
    endtask : run

endclass : Scoreboard

`endif // SCOREBOARD_SV
