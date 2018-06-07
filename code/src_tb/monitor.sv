/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: monitor.sv
-- Authors	: Jérémie Macchi
--	   		  Vivien Kaltenrieder
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
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef MONITOR_SV
`define MONITOR_SV

`include "constant.sv"

class Monitor;

	int bytePos;					// Pour la position du byte à copier dans la trame récupérée
	int nbUsbPacketSent = 0;		// Nombre de paquets transmis au scoreboard

	// les interfaces sont en virtual pour que tous les objets puissent y accéder
	virtual usb_itf vif;

	// Pas besoin d'instancier les fifos, c'est reçu de l'environment
	usb_fifo_t monitor_to_scoreboard_fifo;

	/*---------------
	-- printStatus --
	---------------*/
	// Fonction appellée dans l'environment
	function void printStatus();
		$info("The monitor catch %0d UsbPackets\n", nbUsbPacketSent);
	endfunction

	/*-------
	-- run --
	-------*/
	// Tâche lancée dans l'environment
    task run();

		automatic AnalyzerUsbPacket usb_packet;
		$display("Monitor : start");

		// Boucle infinie stoppée par le watchdog
		while (1) begin
			usb_packet = new;			// Nouveau paquet USB
			bytePos = 0;				// Position du byte à copier initialisé à 0
			@(posedge vif.frame_o);		// Attend un flanc montant sur frame_o

			// Tant que la transmission n'est pas finie
			while (vif.frame_o == 1) begin
				@(negedge vif.clk_i);	// Attend un flanc descendant du clk
				// Si les datas sont valides
				if (vif.valid_o == 1) begin
					// Réceptionne un byte de donnée et le met dans le paquet USB
					for (int y = 0; y < `OCTET; y++)
						usb_packet.dataToSend[bytePos*`OCTET+y] = vif.data_o[y];
					bytePos ++;			// Incrémentation de la position du byte à copier
				end
			end
			usb_packet.getFields();						// Set les champs du paquet USB
			monitor_to_scoreboard_fifo.put(usb_packet);	// Envoi du paquet USB au scoreboard
			//$display("The monitor sent a %s", usb_packet.psprint());
			$display("The monitor sent an usbpacket\n");
			nbUsbPacketSent ++;							// Incrémentation du nombre de paquets USB
		end
    $display("Monitor : end");
    endtask : run

	/*-------------------
	-- watchdogDisable --
	-------------------*/
	// Appellé par le watchdog pour arreter la tâche run()
 	task watchdogDisable;
		$display("The watchdog stopped the monitor");
		disable run;
	endtask : watchdogDisable;

endclass : Monitor

`endif // MONITOR_SV
