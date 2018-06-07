/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: driver.sv
-- Authors	: Jérémie Macchi
--			  Vivien Kaltenrieder
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
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef DRIVER_SV
`define DRIVER_SV

`include "constant.sv"

class Driver;
	static logic[6:0] channel = 7'b0000000;	// Canal d'envoi des paquets
	int nbBlePacketPlayed = 0;				// Nombre de paquet joués

	// Pas besoin d'instancier les fifos, c'est reçu de l'environment
    ble_fifo_t sequencer_to_driver_fifo;

	// Les interfaces sont en virtual pour que tous les objets puissent y accéder
    virtual ble_itf vif;

	/*---------------
	-- printStatus --
	---------------*/
	// Fonction appellée dans l'environment
	function void printStatus();
		$info("The driver played %0d BlePackets\n", nbBlePacketPlayed);
	endfunction

	/*-------------
	-- drive_bit --
	-------------*/
	// Tâche utilisée dans run() pour jouer le paquet sur l'interface
    task drive_bit(BlePacket packet);
		// Si le paquet reçu est valide
		if(packet.valid) begin
			// Envoi d'un bit sur le DUT
			vif.serial_i <= packet.dataToSend[packet.sizeToSend - 1 - packet.position];
			vif.valid_i <= 1;			// Indique que la valeur peut être lue
			vif.channel_i <= channel;	// Indique le numéro du canal
			vif.rssi_i <= packet.rssi;	// Indique l'intensité du signal
			//$display("Channel: %d, Position packet: %d, Valid: %d, Serial: ", channel, packet.position, packet.valid, packet.dataToSend[packet.sizeToSend - 1 - packet.position]);
			packet.position++;			// Incrémentation de la position du bit à envoyer

			// Test la fin de l'envoi du paquet
			if (packet.position == packet.sizeToSend) begin
				packet.position = 0;	// Remise à 0 de la postion du bit à envoyer
				packet.valid = 0;		// le paquet n'est plus à envoyer
				$display("The driver just ended a transmission on the DUT \n");
			end
		end

		// Si le paquet est invalide
		else begin
			vif.serial_i <= 1;			// Valeur par défaut
			vif.valid_i <= 1;			// Indique que la valeur peut être lue
			vif.channel_i <= channel;	// Indique le numero du canal
			vif.rssi_i <= 0;			// Indique l'intensité du signal (la donnée ne sera de toute manière pas utilisée)
		end

		@(posedge vif.clk_i);		// Attend un flanc montant sur le clk
		// Revient au canal 0 après 79
		channel = (channel + 1) % `NB_FREQ;
    endtask

	/*-------
	-- run --
	--------*/
	task run();
       	automatic BlePacket tab_packet[`NB_FREQ];	// Tableau de paquet BLE

		// Création d'un nouveau paquet pour chaque case du tableau
		// Nécessaire pour avoir le champ valid !
		for(int i=0;i<`NB_FREQ;i++) begin
			tab_packet[i] = new;
		end

        $display("Driver : start");

		// Sorte de reset sur l'interface
    	vif.serial_i <= 0;
        vif.valid_i <= 0;
        vif.channel_i <= 0;
        vif.rssi_i <= 0;
        vif.rst_i <= 1;
        @(posedge vif.clk_i);
        vif.rst_i <= 0;
        @(posedge vif.clk_i);
        @(posedge vif.clk_i);

		// Boucle infinie stoppée par le watchdog
		while(1) begin
			// Test s'il y de la place dans le tableau (que les canaux pairs pour le BLE)
			for(int i=0;i<`NB_FREQ;i = i+2) begin
				// Si l'emplacement est libre
				if(tab_packet[i].valid == 0) begin
					// Essaie de copier un paquet dans le tableau
					if(sequencer_to_driver_fifo.try_peek(tab_packet[i])) begin
						// Si le paquet est un advertising et qu'il est sur un canal d'avertising
						if((i==0 || i ==24 || i==78) && (tab_packet[i].isAdv == 1)) begin
							// Retirer le paquet de la fifo et ajouter le packet dans le tableau
							sequencer_to_driver_fifo.get(tab_packet[i]);
							tab_packet[i].valid = 1;	// Indique que le paquet doit être joué
							nbBlePacketPlayed++;		// Incrémentation du nombre de paquets joués
						end
						// Si le paquet est un data et qu'il est sur un canal de data
						else if((i!=0 && i!=24 && i!=78) && (tab_packet[i].isAdv == 0)) begin
							// Retirer le paquet de la fifo et ajouter le packet dans le tableau
							sequencer_to_driver_fifo.get(tab_packet[i]);
							tab_packet[i].valid = 1;	// Indique que le paquet doit être joué
							nbBlePacketPlayed++;		// Incrémentation du nombre de paquets joués
						end
						// Si le type du paquet n'est pas sur le bon type de canal
						else begin
							tab_packet[i] = new;		// Paquet remplacé par un nouveau paquet
							tab_packet[i].valid = 0;	// Indique que le paquet ne doit pas être joué
						end
					end
				end
			end

			// Envoi d'un bit sur tous les canaux
			for(int i=0;i<`NB_FREQ;i++) begin
					drive_bit(tab_packet[i]);
			end
        end
        $display("Driver : end");
    endtask : run

	/*-------------------
	-- watchdogDisable --
	-------------------*/
	// Appellé par le watchdog pour arreter la tâche run()
	task watchdogDisable;
		$display("The watchdog stopped the driver");
		disable run;
	endtask : watchdogDisable;

endclass : Driver

`endif // DRIVER_SV
