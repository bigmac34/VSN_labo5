/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: monitor.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Moniteur de la structure de test envoit au scoreboard et "reçoit" de l'interface de sortie
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef MONITOR_SV
`define MONITOR_SV


class Monitor;
		///< VKR exp: pas besoin de setter la valeur, ça vient de l'environment
    int testcase;
		int bytePos;
		int nbUsbPacketSent = 0;

		logic watchdogBite = 0;

		///< VKR exp: les interfaces sont en virtual pour que tous les objets puissent y accéder (voir comme un bus)
    virtual usb_itf vif;

		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    usb_fifo_t monitor_to_scoreboard_fifo;

		// Fonction eventuellement appellée par le watchdog (seulement si la task ne se termine pas)
		function void printStatus();
				$info("The monitor catch %0d UsbPackets\n", nbUsbPacketSent);
		endfunction

		///< VKR exp: tâche lancée dans l'environment
    task run();		// Pas forcéement besoin du watchdog (c'est le scoreboard qui arrête)

				automatic AnalyzerUsbPacket usb_packet;
				$display("Monitor : start");

				while (1) begin
						usb_packet = new;
						bytePos = 0;
						@(posedge vif.frame_o);
						while (vif.frame_o == 1) begin
								@(negedge vif.clk_i);
								if (vif.valid_o == 1) begin
										for (int y = 0; y < 8; y++)
												usb_packet.dataToSend[bytePos*8+y] = vif.data_o[y];
										bytePos ++;
								end
						end
						usb_packet.getFields();
						monitor_to_scoreboard_fifo.put(usb_packet);
						//$display("The monitor sent a %s", usb_packet.psprint());
						$display("The monitor sent an usbpacket\n");
						nbUsbPacketSent ++;
				end

/*
        while (1) begin
            // Récupération d'un paquet USB, et transmission au scoreboard


            monitor_to_scoreboard_fifo.put(usb_packet);
        end
*/
    $display("Monitor : end");
    endtask : run

	 	task watchdogDisable;
				$display("The watchdog stopped the monitor");
				disable run;
		endtask : watchdogDisable;

endclass : Monitor

`endif // MONITOR_SV
