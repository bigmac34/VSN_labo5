/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: ble_packet_analyser_tb.sv
-- Authors	: --
--
-- Date     : --
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Testbench, instancie le DUT et met en place l'environnement
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person		Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`include "transactions.sv"
`include "interfaces.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "watchdog.sv"
`include "environment.sv"
`include "constant.sv"

// Module = composant d'une hierarchie avec des ports d'entrée/sortie (dans la parenthese)
module packet_analyzer_tb#(int TESTCASE = 0, int ERRNO = 0);

	// Instanciation de deux interfaces pour la connexion des entrées
	// Possible de travailler comme un bus (plusieurs modules connectés)
	ble_itf input_itf();
	usb_itf output_itf();
	run_itf wd_sb_itf();

	// Instanciation du dut par nommage des ports
	ble_packet_analyzer#(ERRNO,0) dut(
		.clk_i(input_itf.clk_i),
		.rst_i(input_itf.rst_i),
		.serial_i(input_itf.serial_i),
		.valid_i(input_itf.valid_i),
		.channel_i(input_itf.channel_i),
		.rssi_i(input_itf.rssi_i),
		.data_o(output_itf.data_o),
		.valid_o(output_itf.valid_o),
		.frame_o(output_itf.frame_o)
		);

		// Lancement d'un processus (non synthetisable) (boucle sans fin)
		// Génération de l'horloge
		always #5 input_itf.clk_i = ~input_itf.clk_i;

		// Assignation de l'output combinatoire du clock
		assign output_itf.clk_i = input_itf.clk_i;

		Environment env;

		// Lancement d'un processus (non synthetisable) une seule fois au lancement de la simulation
		initial begin

		// Message d'information de quels TESTCASE et ERRNO utilisées
		$info("------------------------------------------------------\n         -            ERRNO : %0d      TESTCASE : %0d             -\n         ------------------------------------------------------",  ERRNO, TESTCASE);

		// Appel du constructeur de la class
		env = new;

		// Assignation d'attributs
		env.input_itf = input_itf;
		env.output_itf = output_itf;
		env.wd_sb_itf = wd_sb_itf;
		env.testcase = TESTCASE;

		env.build;					// Appel de tasks (procedures) de Environment
		env.run();					// Run fait l'objet d'un fork (attente de fin de toutes les taches)

		$finish;
	end
endmodule
