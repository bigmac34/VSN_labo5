/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: interfaces.sv
-- Authors	: --
--
-- Date     : --
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Interfaces d'entrée et de sortie du DUT
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef INTERFACES_SV
`define INTERFACES_SV

`include "constant.sv"

// Création des interfaces pour la connection des entrées/sorties du DUT
// Possible de travailler comme un bus (plusieurs modules connectés)
interface ble_itf;
	logic clk_i = 0;
    logic rst_i;
    logic serial_i;
    logic valid_i;
    logic[`CHANNEL_FIELD_SIZE-1:0] channel_i;
    logic[`RSSI_FIELD_SIZE-1:0] rssi_i;
endinterface : ble_itf

interface usb_itf;
    logic clk_i;
    logic[`DATA_O_SIZE-1:0] data_o;
    logic valid_o;
	logic frame_o;
endinterface : usb_itf

// Interface de communication entre le Watchdog et le Scoreboard.
interface run_itf;
    logic isRunning = 1;
endinterface : run_itf

`endif // INTERFACES_SV
