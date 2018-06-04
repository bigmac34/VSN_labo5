/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: watchdog.sv
-- Authors	: Jérémie Macchi
--			  Vivien Kaltenrieder
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
-- Ver   Date        	Person     	Comments
-- 1.0	 26.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef WATCHDOG_SV
`define WATCHDOG_SV

`include "constant.sv"

class Watchdog;
	// Les interfaces sont en virtual pour que tous les objets puissent y accéder (voir comme un bus)
	virtual ble_itf vif;
	virtual run_itf wd_sb_itf;

	// Tâche lancée dans l'environment
	task run(Sequencer sequencer, Driver driver, Monitor monitor, Scoreboard scoreboard);
		int i = 0;
		$display("Watchdog : start");
		// Faire un certain nombre de fois avant d'arrêter le test
		while(i < `TIME_WATCHDOG) begin
			// Si aucune activité détectée
			if(wd_sb_itf.isRunning == 0) begin
				i++;
			end
			// Si activité détectée
			else begin
				i = 0;					// Remet le compteur à 0
			end
			wd_sb_itf.isRunning = 0;	// Flag d'activité remis à 0

			// Pour que la tache ne l'écrivent pas en même temps
			@(posedge vif.clk_i);
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
