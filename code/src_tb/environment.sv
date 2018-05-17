`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "interfaces.sv"
class Environment;

    int testcase;

    Sequencer sequencer;
    Driver driver;
    Monitor monitor;
    Scoreboard scoreboard;

    virtual ble_itf input_itf;
    virtual usb_itf output_itf;

    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

    task build;
    sequencer_to_driver_fifo     = new(10);
    sequencer_to_scoreboard_fifo = new(10);
    monitor_to_scoreboard_fifo   = new(100);

    sequencer = new;
    driver = new;
    monitor = new;
    scoreboard = new;

    sequencer.testcase = testcase;
    driver.testcase = testcase;
    monitor.testcase = testcase;
    scoreboard.testcase = testcase;

    driver.vif = input_itf;
    monitor.vif = output_itf;

    sequencer.sequencer_to_driver_fifo = sequencer_to_driver_fifo;
    driver.sequencer_to_driver_fifo = sequencer_to_driver_fifo;

    sequencer.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;
    scoreboard.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;

    monitor.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;
    scoreboard.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;

    endtask : build

    task run;

        fork
            sequencer.run();
            driver.run();
            monitor.run();
            scoreboard.run();
        join;

    endtask : run

endclass : Environment


`endif // ENVIRONMENT_SV
