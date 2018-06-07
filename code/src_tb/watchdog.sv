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
	// Les interfaces sont en virtual pour que tous les objets puissent y accéder
	virtual ble_itf vif;
	virtual run_itf wd_sb_itf;

	// Tâche lancée dans l'environment
	task run(Sequencer sequencer, Driver driver, Monitor monitor, Scoreboard scoreboard);
		int i = 0;
		$display("Watchdog : start");
		// Vérifier si le temps d'inactivité dépasse le max défini
		while(i < `WATCHDOG_TIME) begin
			// Si aucune activité n'est détectée
			if(wd_sb_itf.isRunning == 0) begin
				i++;					// Incrémentation du compteur
			end
			// Si une activité est détectée
			else begin
				i = 0;					// Remet le compteur à 0
			end
			wd_sb_itf.isRunning = 0;	// Flag d'activité remis à 0

			// Attente de 2 coups de clock avant la prochaine vérification
			@(posedge vif.clk_i);
			@(posedge vif.clk_i);
		end

		// Désactivation des tâches actives
		$display("\n");
		driver.watchdogDisable();
		monitor.watchdogDisable();
		scoreboard.watchdogDisable();
    $display("Watchdog : end");
	endtask : run

endclass : Watchdog

`endif // WATCHDOG_SV
