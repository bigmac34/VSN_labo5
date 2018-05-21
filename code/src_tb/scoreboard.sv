/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: scoreboard.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Scoreboard de la structure de test (reçoit du sequencer et du moniteur)
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

///< VKR exp: la solution des class paramétrées paraît pas mal, mais là on utilise des mailbox, je cois que c'est dans le même but !?!
class Scoreboard;

		///< VKR exp: pas besoin de setter la valeur, ça vient de l'environment
    int testcase;

		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_scoreboard_fifo;
    usb_fifo_t monitor_to_scoreboard_fifo;

		///< fonction de comparaison des packets
		task comparePackets(AnalyzerUsbPacket usb_packet, BlePacket ble_packet, int i);
			if(usb_packet.size-10 != ble_packet.size)					// Se les tailles des datas sont différentes
				$display("Bad size on comparison : %d\n", i);
			if(usb_packet.isAdv != ble_packet.isAdv)					// Si les flag ne sont pas les mêmes
				$display("Bad flag on comparison : %d\n", i);
			if(usb_packet.address != ble_packet.addr)					// Si les adresses ne sont pas les mêmes
				$display("Bad address on comparison : %d\n", i);
			if(usb_packet.data != ble_packet.data)						// Si les datas ne sont pas les mêmes
				$display("Bad data on comparison : %d\n", i);
		endtask

		///< VKR exp: tâche lancée dans l'environment
    task run;
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
        automatic BlePacket ble_packet = new;
        automatic AnalyzerUsbPacket usb_packet = new;

        $display("Scoreboard : Start");

				///< VKR exp: je sais pas si c'est optimal de faire avec un for, même problème que dans le dernier
				///< VKR exp: est-ce qu'il y a un moyen de faire sans savoir le nombre qu'on en envoit ??
        for(int i=0; i< 10; i++) begin
            sequencer_to_scoreboard_fifo.get(ble_packet);
            monitor_to_scoreboard_fifo.get(usb_packet);
            // Check that everything is fine
						$display(ble_packet.psprint());
						usb_packet.getFields();										// Pour setter les attributs de la class (affichage)
						$display(usb_packet.psprint());
						comparePackets(usb_packet, ble_packet, i);
        end

        $display("Scoreboard : End");
    endtask : run

endclass : Scoreboard

`endif // SCOREBOARD_SV
