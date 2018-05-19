/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: environment.sv
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
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef ENVIRONMENT_SV
`define ENVIRONMENT_SV

`include "interfaces.sv"

class Environment;

    int testcase;

		///< VKR exp: déclaration des différents objets
    Sequencer sequencer;
    Driver driver;
    Monitor monitor;
    Scoreboard scoreboard;

		///< VKR exp: les interfaces sont en virtual pour que tous les objets puissent y accéder (voir comme un bus)
    virtual ble_itf input_itf;
    virtual usb_itf output_itf;

		///< VKR exp: variable pour les différentes fifo (mailbox de TRANSACTIONS_SV)
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

		///< VKR exp: tâche appellée depuis le scoreboard
    task build;
		///< VKR exp: instanciation des fifo avec une taille max (bound)
		///< VKR exp: quand c'est plein, c'est suspendu est mis dès qu'il y a de la place)
    sequencer_to_driver_fifo     = new(10);
    sequencer_to_scoreboard_fifo = new(10);
    monitor_to_scoreboard_fifo   = new(100);

		///< VKR exp: instanciation des différents objets de la structure de test
    sequencer = new;
    driver = new;
    monitor = new;
    scoreboard = new;

		///< VKR exp: passage du paramètre testcase à tous les objets
    sequencer.testcase = testcase;
    driver.testcase = testcase;
    monitor.testcase = testcase;
    scoreboard.testcase = testcase;

		///< VKR exp: passage des interfaces d'entrée et de sortie
		///< VKR exp: c'est le moyen de communicationa avec le DUT
    driver.vif = input_itf;
    monitor.vif = output_itf;

		///< VKR exp: passage de la fifo entre le sequencer et le driver
    sequencer.sequencer_to_driver_fifo = sequencer_to_driver_fifo;
    driver.sequencer_to_driver_fifo = sequencer_to_driver_fifo;

		///< VKR exp: passage de la fifo entre le sequencer et le scoreboard
    sequencer.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;
    scoreboard.sequencer_to_scoreboard_fifo = sequencer_to_scoreboard_fifo;

		///< VKR exp: passage de la fifo entre le monitor et le scoreboard
    monitor.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;
    scoreboard.monitor_to_scoreboard_fifo = monitor_to_scoreboard_fifo;

    endtask : build

		///< VKR exp: tâche appellée depuis le scoreboard
    task run;
				///< VKR exp: lancement en parrallèle de tous les objets de la structure de test
        fork
            sequencer.run();
            driver.run();
            monitor.run();
            scoreboard.run();
        join;												///< VKR exp: attente de fin de TOUTES les tâches

	  endtask : run

endclass : Environment


`endif // ENVIRONMENT_SV
