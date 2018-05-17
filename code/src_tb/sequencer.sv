`ifndef SEQUENCER_SV
`define SEQUENCER_SV

class Sequencer;

    int testcase;
    
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;

    task run;
        automatic BlePacket packet;
        $display("Sequencer : start");

        packet = new;
        packet.isAdv = 1;
        void'(packet.randomize());

        sequencer_to_driver_fifo.put(packet);
        sequencer_to_scoreboard_fifo.put(packet);

        $display("I sent an advertising packet!!!!");


        for(int i=0;i<9;i++) begin

            packet = new;
            packet.isAdv = 0;
            void'(packet.randomize());

            sequencer_to_driver_fifo.put(packet);
            sequencer_to_scoreboard_fifo.put(packet);

            $display("I sent a packet!!!!");
        end
        $display("Sequencer : end");
    endtask : run

endclass : Sequencer


`endif // SEQUENCER_SV
