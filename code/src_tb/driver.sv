/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: driver.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : driver de la structure de test, reçoit du sequencer et "joue" sur l'interface d'entrée
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef DRIVER_SV
`define DRIVER_SV

`include "constant.sv"

class Driver;
		///< VKR exp: pas besoin de setter la valeur, ça vient de l'environment
    int testcase;
		static logic[6:0] inc = 7'b0000000;

		logic testfin;

		///< VKR exp: pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_driver_fifo;

		///< VKR exp: les interfaces sont en virtual pour que tous les objets puissent y accéder (voir comme un bus)
    virtual ble_itf vif;

		///< VKR exp: tâche utilisée dans run pour jouer le packet sur l'interface
    task drive_bit(BlePacket packet);
//        packet.isAdv = 1;
//        void'(packet.randomize());
				if(packet.valid) begin
		        vif.serial_i <= packet.dataToSend[packet.sizeToSend - 1 - packet.position];
		        vif.valid_i <= 1;
		        vif.channel_i <= inc;
		        vif.rssi_i <= packet.rssi;
						//$display("Channel: %d, Position packet: %d, Valid: %d, Serial: ", inc, packet.position, packet.valid, packet.dataToSend[packet.sizeToSend - 1 - packet.position]);
						packet.position++;
						// Test la fin de l'envoi du paquet
						if (packet.position == packet.sizeToSend) begin
								packet.position = 0;
								packet.valid = 0;			// le paquet n'est plus à envoyer
								//$display("Fin d'une transmission de paquet par le driver \n");
								$display("The driver just ended a transmission on the DUT \n");
								//$display("Fin:Channel: %d, Position packet: %d \n", inc, packet.position);
						end
		        @(posedge vif.clk_i);
				end
				else begin
						vif.serial_i <= 1;		// Pour coller avec le préambule
						vif.valid_i <= 1;
						vif.channel_i <= inc;
						vif.rssi_i <= 0;
						@(posedge vif.clk_i);
				end
				// Revient à la au canal 0 apres 79
				inc = (inc + 1) % `NB_FREQ;
    endtask

    task run;
				///< VKR exp: normalement une variable dans une tâche de class n'est pas statique
				///< VKR exp: automatic pour la définir en statique ? Pas certain
       	automatic BlePacket tab_packet[`NB_FREQ];

				for(int i=0;i<`NB_FREQ;i++) begin
						tab_packet[i] = new;
				end

        $display("Driver : start");

				///< VKR exp: sorte de reset sur l'interface
        vif.serial_i <= 0;
        vif.valid_i <= 0;
        vif.channel_i <= 0;
        vif.rssi_i <= 0;
        vif.rst_i <= 1;
        @(posedge vif.clk_i);
        vif.rst_i <= 0;
        @(posedge vif.clk_i);
        @(posedge vif.clk_i);

				testfin = 1;
				while(testfin) begin
						// Variable de test pour savoir s'il y a encore des paquets à envoyer
						testfin = 0;
						// Test si il y de la place dans le tableau
						for(int i=0;i<`NB_FREQ;i = i+2) begin
								// Si l'emplacement est libre
								if(tab_packet[i].valid == 0) begin
										// Essai de le remplacer par des données valide
										if(sequencer_to_driver_fifo.try_peek(tab_packet[i])) begin
												// Test si le paquet est un advertising et qu'il est sur un canal d'avertising
												if((i==0 || i ==24 || i==78) && (tab_packet[i].isAdv == 1)) begin
														sequencer_to_driver_fifo.try_get(tab_packet[i]);
														tab_packet[i].valid = 1;
														testfin = 1;
												end
												// Test si le paquet est une data et qu'il est sur un canal de data
												else if((i!=0 && i!=24 && i!=78) && (tab_packet[i].isAdv == 0)) begin
														sequencer_to_driver_fifo.try_get(tab_packet[i]);
														tab_packet[i].valid = 1;
														testfin = 1;
												end
												else begin
														tab_packet[i] = new;
														tab_packet[i].valid = 0;
														testfin = 1;
												end
										end
								end
								else
										testfin = 1;
						end
						// Envoi de chaque bit sur tout les canaux
						for(int i=0;i<`NB_FREQ;i++) begin
								drive_bit(tab_packet[i]);
						end
        end

				///< VKR exp: simple attente de 99 coups de clock avant de terminer
        for(int i=0;i<99;i++)
            @(posedge vif.clk_i);

        $display("Driver : end");
    endtask : run

endclass : Driver

`endif // DRIVER_SV
