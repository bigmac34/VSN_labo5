/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: ble_packet_analyser_tb.sv
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
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`include "transactions.sv"
`include "interfaces.sv"
`include "sequencer.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "environment.sv"
`include "constant.sv"

///< VKR exp: Module = composant d'une hierarchie avec des ports d'entrée/sortie (dans la parenthese)
module packet_analyzer_tb#(int TESTCASE = 0, int ERRNO = 0);

		///< VKR exp: instanciation de deux interfaces pour la connection des entrées
		///< VKR exp: possible de travailler comme un bus (plusieurs modules connectés)
    ble_itf input_itf();
    usb_itf output_itf();

		///< VKR exp: instanciation du dut par nommage des ports
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

		///< VKR exp: lancement d'un processus (non synthetisable) (boucle sans fin)
    // génération de l'horloge
    always #5 input_itf.clk_i = ~input_itf.clk_i;

		///< VKR exp: assignation de l'output combinatoire du clock
    assign output_itf.clk_i = input_itf.clk_i;

    Environment env;

		///< VKR exp: lancement d'un processus (non synthetisable) une seule fois au lancement de la simulation
    initial begin

        env = new;										///< VKR exp: appel du constructeur de la class

        env.input_itf = input_itf;		///< VKR exp: assignation d'attributs
        env.output_itf = output_itf;
        env.testcase = TESTCASE;
        env.build;										///< VKR exp: appel de tasks (procedures) de Environment
        env.run();										///< VKR exp: run fait l'objet d'un fork (attente de fin de toutes les taches)
        $finish;
    end

endmodule
