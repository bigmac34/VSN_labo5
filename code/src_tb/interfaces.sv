`ifndef INTERFACES_SV
`define INTERFACES_SV

interface ble_itf;
    logic clk_i = 0;
    logic rst_i;
    logic serial_i;
    logic valid_i;
    logic[6:0] channel_i;
    logic[7:0] rssi_i;
endinterface : ble_itf

interface usb_itf;
    logic clk_i;
    logic[7:0] data_o;
    logic valid_o;
	logic frame_o;
endinterface : usb_itf

`endif // INTERFACES_SV
