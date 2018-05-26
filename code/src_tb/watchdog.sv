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
		virtual run_itf wd_sb_itf;

		///< VKR exp: tâche lancée dans l'environment
		task run(Sequencer sequencer, Driver driver, Monitor monitor, Scoreboard scoreboard);
				int i = 0;
				$display("Watchdog : start");
				while(i < 25000) begin		// Temps au bol (un peu mais pas trop)
						if(wd_sb_itf.isRunning == 0) begin
								i++;
						end
						else begin
								i = 0;
						end
						wd_sb_itf.isRunning = 0;
						@(posedge vif.clk_i); // Pour que le tache ne l'écrivent pas en même temps
						@(posedge vif.clk_i);
				end

				// Disable all the running task
				$display("\n");
				driver.watchdogDisable();
				monitor.watchdogDisable();
				scoreboard.watchdogDisable();
        $display("Watchdog : end");
    endtask : run

endclass : Watchdog

`endif // WATCHDOG_SV
