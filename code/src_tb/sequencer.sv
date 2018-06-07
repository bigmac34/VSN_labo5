/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: sequencer.sv
-- Authors	: Jérémie Macchi
--			  Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Sequencer de la structure de test envoit au scoreboard et au driver
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
--------------------------------------------------------------------------------
-- TESTCASE:
-- 		0: Fonctionnement classique, tous les advertising puis tous les data
--		1: Envoi de paquets de données avec une taille minimale
--		2: Envoi de paquets de données avec une taille maximale
--		3: Envoi de paquets de données sans paquet d'avertising avant
--		4: Envoi de paquets dont le préambule est incorrect
--		5: Envoi de paquets sur plus de 16 addresses
--		6: Envoi d'un advertising puis d'un data, ainsi de suite
------------------------------------------------------------------------------*/
`ifndef SEQUENCER_SV
`define SEQUENCER_SV

`include "constant.sv"

class Sequencer;
	// Pas besoin de setter les valeurs, elles viennent de l'environment
	int testcase;
	virtual ble_itf vif;

	int nbPaquetSend = 0;	// Initialisation du nombre de paquets envoyés à 0

	// Pas besoin d'instancier les fifos, elles viennent de l'environment
    ble_fifo_t sequencer_to_driver_fifo;
    ble_fifo_t sequencer_to_scoreboard_fifo;

	/*---------------
	-- printStatus --
	----------------*/
	// Fonction appellée dans l'environment
	function void printStatus();
		$info("The sequencer send %0d BlePackets \n", nbPaquetSend);
	endfunction

	/*-----------------
	-- sendBlePacket --
	-----------------*/
	// Envoi d'un paquet BLE aux FIFOs
	task sendBlePacket(int testcase, logic isAdv, logic[`ADDRESS_FIELD_SIZE-1:0] addr,int numPaquet);

		automatic BlePacket packet, packet2;

		// Initialisation du packet
		packet = new;					// Il ne faut pas réutiliser celui qui est dans la mailbox
		packet.testcase = testcase;
		packet.isAdv = isAdv;
		packet.addr = addr;
		packet.numPaquet = numPaquet;

		void'(packet.randomize());		// Randomisation du paquet
		packet2 = packet.copy();		// Copie profonde du paquet

		// Envoi dans les deux FIFOs
		sequencer_to_driver_fifo.put(packet);
		sequencer_to_scoreboard_fifo.put(packet2);

		//$display("The sequencer sent a %s", packet.psprint());
		if(isAdv) begin
			$display("The sequencer sent a advertising blepacket\n");
		end
		else begin
			$display("The sequencer sent a blepacket\n");
		end
	endtask;

	/*-------
	-- run --
	-------*/
	// Tâche lancée dans l'environment
	task run;
		// Valeurs utilisées pour définir combien de packets vont être envoyés
		int nbPacket = 10;
		int nbAdvertising = 0;
		int nbData = 9;

		$display("Sequencer : start");

		// Séquence d'envoi classique: advertising puis data
		if(testcase < 5) begin

			// Pas d'envoi de paquets d'advertising
			if(testcase == 3) begin
				nbAdvertising = 0;
			end
			// Nombres d'advertising inférieurs à 16
			else begin
				nbAdvertising = 1;
			end

			// Envoi des Advertising
			for(int i=0;i<nbAdvertising;i++) begin
				sendBlePacket(testcase, 1, `TEST_ADDRESS, nbPaquetSend); // Envoie du paquet
				nbPaquetSend++;
			end

			// Envoie de packets de données random encore 9 fois
	        for(int i=0;i<nbData;i++) begin
				sendBlePacket(testcase, 0, `TEST_ADDRESS, nbPaquetSend); // Envoie du paquet
				nbPaquetSend++;
			end
		end

		// Envoi sur plus de 16 advertising
		else if(testcase == 5) begin
			logic[`ADDRESS_FIELD_SIZE-1:0] address[`NB_MAX_ADDRESS + 3];
			// Envoi des Advertising (plus que le maximum que peut enregistrer le DUT)
			for(int i=0;i<`NB_MAX_ADDRESS+3;i++) begin
				address[i] = $random;									// Adresse aléatoire
				sendBlePacket(testcase, 1, address[i], nbPaquetSend);	// Envoi du paquet
				nbPaquetSend++;
			end

			// Pour attendre que les advertising soient traités par le DUT avant d'envoyer les datas
			//#((`PREAMBLE_FIELD_SIZE+`ADDRESS_FIELD_SIZE+`HEADER_FIELD_SIZE+`NB_MAX_ADVERTISING_DATA*`OCTET)*`NB_FREQ*10)ns; // 10 : période
			#140us;

			// Envoi de packets de données (plus que le maximum que peut enregistrer le DUT)
			for(int i=0;i<`NB_MAX_ADDRESS+3;i++) begin
				sendBlePacket(testcase, 0, address[i], nbPaquetSend);	// Envoi du paquet
				nbPaquetSend++;											// Incrémentation du nombre de paquets envoyés
			end
		end

		// Envoi d'un advertising puis d'un data, ainsi de suite
		else if(testcase == 6) begin
			logic[`ADDRESS_FIELD_SIZE-1:0] address;
			for(int i=0;i<nbPacket;i++) begin
				address = $random;									// Adresse aléatoire
				sendBlePacket(testcase, 1, address, nbPaquetSend);	// Envoi de l'advertising
				nbPaquetSend++;										// Incrémentation du nombre de paquets envoyés
				// Pour attendre que les advertising soient traités par le DUT avant d'envoyer les datas
				//#((`PREAMBLE_FIELD_SIZE+`ADDRESS_FIELD_SIZE+`HEADER_FIELD_SIZE+`NB_MAX_ADVERTISING_DATA*`OCTET)*`NB_FREQ*10)ns; // 10 : periode
				#140us;

				sendBlePacket(testcase, 0, address, nbPaquetSend); 	// Envoi du paquet de données
				nbPaquetSend++;										// Incrémentation du nombre de paquets envoyés
			end
		end

		// Si testcase est invalide
		else begin
			$error("Sequencer : testcase invalid");
		end

        $display("Sequencer : end");
    endtask : run

endclass : Sequencer

`endif // SEQUENCER_SV
