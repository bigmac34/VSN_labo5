/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: environment.sv
-- Authors	: --
--
-- Date     : --
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Class contenant l'environnement de test mis en place dans le TB
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "interfaces.sv"

class Environment;

	int testcase;

	// Déclaration des différents objets
    Sequencer sequencer;
    Driver driver;
    Monitor monitor;
    Scoreboard scoreboard;
	Watchdog watchdog;

	// Les interfaces sont en virtual pour que tous les objets puissent y accéder (comme un bus)
    virtual ble_itf input_itf;
    virtual usb_itf output_itf;

	// Interface entre le watchdog et le scoreboard
	virtual run_itf wd_sb_itf;

	// Variables pour les différentes fifo (mailbox de TRANSACTIONS_SV)
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

	/*---------
	-- build --
	---------*/
	// Tâche appellée depuis le testbench
    task build;
	// Instanciation des fifos avec une taille max (bound)
	// Quand c'est plein, c'est suspendu est mis dès qu'il y a de la place
    sequencer_to_driver_fifo     = new(10);
    sequencer_to_scoreboard_fifo = new(10);
    monitor_to_scoreboard_fifo   = new(100);

	// Instanciation des différents objets de la structure de test
    sequencer = new;
    driver = new;
    monitor = new;
    scoreboard = new;
	watchdog = new;

	// Passage du paramètre testcase au sequencer
    sequencer.testcase = testcase;

	// Passage des interfaces d'entrée et de sortie
	// C'est le moyen de communicationa avec le DUT
    driver.vif = input_itf;
	sequencer.vif = input_itf;
    monitor.vif = output_itf;
	scoreboard.vif = output_itf;
	watchdog.vif = input_itf;
	watchdog.wd_sb_itf = wd_sb_itf;
	scoreboard.wd_sb_itf = wd_sb_itf;

	// Passage de la fifo entre le sequencer et le driver
    sequencer.sequencer_to_driver_fifo = sequencer_to_driver_fifo;
    driver.sequencer_to_driver_fifo = sequencer_to_driver_fifo;

	// Passage de la fifo entre le sequencer et le scoreboard
    sequencer.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;
    scoreboard.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;

	// Passage de la fifo entre le monitor et le scoreboard
    monitor.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;
    scoreboard.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;

    endtask : build

	/*-------
	-- run --
	-------*/
	// Tâche appellée depuis le testbench
    task run;
		// Lancement en parrallèle de tous les objets de la structure de test
    	fork
            sequencer.run();
            driver.run();
            monitor.run();
            scoreboard.run();
			watchdog.run(sequencer, driver, monitor, scoreboard);
        join;					// Attente de fin de TOUTES les tâches

		// Affichage des statuts de simulation
		$display("\n\n");
		$display("-------------- Displaying the simulation status ---------------\n\n");
		sequencer.printStatus();
		$display("\n");
		driver.printStatus();
		$display("\n");
		monitor.printStatus();
		$display("\n");
		scoreboard.printStatus();
		$display("\n\n");
	endtask : run
endclass : Environment

`endif // ENVIRONMENT_SV
