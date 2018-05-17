`ifndef MONITOR_SV
`define MONITOR_SV


class Monitor;

    int testcase;
    
    virtual usb_itf vif;

    usb_fifo_t monitor_to_scoreboard_fifo;

    task run;
        AnalyzerUsbPacket usb_packet = new;
        $display("Monitor : start");


/*
        while (1) begin
            // Récupération d'un paquet USB, et transmission au scoreboard


            monitor_to_scoreboard_fifo.put(usb_packet);
        end
*/

    $display("Monitor : end");
    endtask : run

endclass : Monitor

`endif // MONITOR_SV
