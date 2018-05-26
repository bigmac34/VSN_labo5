/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: watchdog.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Watchdog pour le Moniteur et le scoreboard
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 26.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef WATCHDOG_SV
`define WATCHDOG_SV

`include "constant.sv"

class Watchdog;
		///< VKR exp: les interfaces sont en virtual pour que tous les objets puissent y accéder (voir comme un bus)
		virtual ble_itf vif;

		///< VKR exp: tâche lancée dans l'environment
		task run(Monitor monitor, Scoreboard scoreboard);
				int i = 0;
				$display("Watchdog : start");
				while(i < 300000 && (monitor.isRunning || scoreboard.isRunning)) begin
						@(posedge vif.clk_i);
						i = i+1;
				end

				if(monitor.isRunning) begin
						monitor.printStatus();
						monitor.watchdogDisable();
				end

				if(scoreboard.isRunning) begin
						scoreboard.printStatus();
						scoreboard.watchdogDisable();
				end
        $display("Watchdog : end");
    endtask : run

endclass : Watchdog

`endif // WATCHDOG_SV
