/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: transactions.sv
-- Authors	: Jérémie Macchi
--			  Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Implémentation des class pour les transactions, packet Ble et Usb
--				 Définition des fifos (mailbox)
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     	Comments
-- 1.0	 19.05.2018		VKR			Explication sur la structure
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef TRANSACTIONS_SV
`define TRANSACTIONS_SV

`include "constant.sv"

/******************************************************************************
  BlePacket
******************************************************************************/
class BlePacket;

	logic[(`NB_MAX_DATA+`HEADER_FIELD_SIZE+`ADDRESS_FIELD_SIZE+`PREAMBLE_FIELD_SIZE):0] dataToSend;
 	int sizeToSend;

	// Pour la gestion de l'envoi bit par bit. Savoir quelles données ont été envoyées
	int position = 0;
	logic valid = 0;

	int numPaquet;	// Numéro du paquet

	// Indique un fonctionnement différent en fonction du testcase
	int testcase = 0;

  	logic isAdv;
  	logic dataValid = 1;
	logic[`ADDRESS_FIELD_SIZE-1:0] addr; // L'adresse est evoyée par le sequencer
	logic[`NB_MAX_DATA-1:0] data;
	logic[`PREAMBLE_FIELD_SIZE-1:0] preamble;

	// Champs générés aléatoirement
	rand logic[`HEADER_FIELD_SIZE-1:0] header;
	rand logic[`NB_MAX_DATA-1:0] rawData;
	rand logic[`BLE_SIZE_FIELD_SIZE-1:0] size;
	rand logic[`RSSI_FIELD_SIZE-1:0] rssi;

	// Envoi de paquets valides
	// Contrainte sur la taille des données en fonction du type de paquet
	constraint size_range_tc0 {
		(testcase != 1) && (testcase != 2) && (isAdv == 1) -> size inside {[4:15]};
		(testcase != 1) && (testcase != 2) && (isAdv == 0) -> size inside {[0:63]};
	}

	constraint size_dist_tc0 {
		// Contrainte sur la taille des données quand c'est un advertising
		(testcase != 1) && (testcase != 2) && (isAdv == 1) -> size dist {
			[4:6] 	:/ 1,
			[7:12]	:/ 1,
			[13:15]	:/ 1
		};
		// Contrainte sur la taille des données quand c'est un paquet de données
		(testcase != 1) && (testcase != 2) && (isAdv == 0) -> size dist {
			[1:4] 	:/ 1,
			[5:58]	:/ 1,
			[59:63]	:/ 1
		};
	}

	// Les paquets ont la taille minimale
	constraint size_range_tc1 {
		(testcase == 1) && (isAdv == 1) -> size inside {[4:4]};
		(testcase == 1) && (isAdv == 0) -> size inside {[0:0]};
	}

	// Les paquets ont la taille maximale
	constraint size_range_tc2 {
	    (testcase == 2) && (isAdv == 1) -> size inside {[15:15]};
	    (testcase == 2) && (isAdv == 0) -> size inside {[63:63]};
	}


	/*-----------
	-- psprint --
	-----------*/
	// Affiche les champs du paquet Ble
	function string psprint();
		$sformat(psprint, "BlePacket number %0d\nAdvert : %b\nAddress : %h\nSize : %d\nData : %h\n",
	                                                   this.numPaquet, this.isAdv, this.addr, size, data);
	endfunction : psprint

	/*----------------
	-- getDeviceAdd --
	----------------*/
	// Retourne l'adresse du paquet Ble dans le cas d'un advertising
	function address_t getDeviceAdd();
		address_t address;
		for(int i=0; i<`ADDRESS_FIELD_SIZE;i++)
			address[i] = rawData[size*8-`ADDRESS_FIELD_SIZE+i];
		$display("The device address in the advertising is %0h \n", address);
		return address;
	endfunction : getDeviceAdd


	/*------------------
	-- post_randomize --
	------------------*/
	// Fonction appellée automatiquement après la randomisation
	// En l'occurence construction d'un paquet
 	function void post_randomize();

		// Préambule correct (01010101)
		if (testcase != 4) begin
			preamble=`PREAMBLE;
		end
		// Préambule incorrect (testcase 4)
		else begin
			preamble=`BAD_PREAMBLE;
		end

		// Initialisation des données à envoyer
	  	dataToSend = 0;
	  	sizeToSend=size*8+`HEADER_FIELD_SIZE+`ADDRESS_FIELD_SIZE+`PREAMBLE_FIELD_SIZE;

		// Cas de l'envoi d'un paquet d'advertising
		if (isAdv == 1) begin
			// Ecrit l'adresse du device à enregistrer
	        for(int i=0; i<`ADDRESS_FIELD_SIZE;i++)
	            rawData[size*8-`ADDRESS_FIELD_SIZE+i] = addr[i];
			// L'adresse du paquet est un advertising
			addr = `ADVERTISING_ADDRESS;
		end


		// Ecriture des données à envoyer
		for(int i=0;i<`PREAMBLE_FIELD_SIZE;i++)								// Ecrit le préambule
			dataToSend[sizeToSend-`PREAMBLE_FIELD_SIZE+i]=preamble[i];
		for(int i=0;i<`ADDRESS_FIELD_SIZE;i++)									// Ecrit l'adresse
			dataToSend[sizeToSend-`PREAMBLE_FIELD_SIZE-`ADDRESS_FIELD_SIZE+i]=addr[i];
		//$display("Sending packet with address %h\n",addr);
		for(int i=0;i<`HEADER_FIELD_SIZE;i++)									// Ecrit l'entête
			dataToSend[sizeToSend-`PREAMBLE_FIELD_SIZE-`ADDRESS_FIELD_SIZE-`HEADER_FIELD_SIZE+i]=0; // Reset le header
		for(int i=0;i<`BLE_SIZE_FIELD_SIZE;i++)									// Ecrit la taille
			dataToSend[sizeToSend-`PREAMBLE_FIELD_SIZE-`ADDRESS_FIELD_SIZE-`HEADER_FIELD_SIZE+i]=size[i];
		data = 0;
		for(int i=0;i<size*8;i++) begin										// Ecrit les données
			dataToSend[sizeToSend-`PREAMBLE_FIELD_SIZE-`ADDRESS_FIELD_SIZE-`HEADER_FIELD_SIZE-1-i]=rawData[size*8-1-i];
			data[size*8-1-i] = rawData[size*8-1-i];
		end
 	endfunction : post_randomize

	/*--------
	-- copy --
	--------*/
	// Copie profonde de l'objet
	function BlePacket copy();
		BlePacket theCopy = new();
		theCopy.dataToSend = this.dataToSend;
		theCopy.sizeToSend = this.sizeToSend;
		theCopy.numPaquet = this.numPaquet;
		theCopy.position = this.position;
		theCopy.valid = this.valid;
		theCopy.isAdv = this.isAdv;
		theCopy.dataValid = this.dataValid;
		theCopy.data = this.data;
		theCopy.addr = this.addr;
		theCopy.header = this.header;
		theCopy.rawData = this.rawData;
		theCopy.size = this.size;
		theCopy.rssi = this.rssi;
		theCopy.preamble = this.preamble;

		return theCopy;
	endfunction

endclass : BlePacket

/******************************************************************************
  AnalyzerUsbPacket
******************************************************************************/
class AnalyzerUsbPacket;
	// Variable modifiée au niveau du monitor
	logic[(64*8+10*8)-1:0] dataToSend;		// pas plus de 64 bytes de données

	// Les champs d'un packet USB
	logic[`USB_FIELD_SIZE-1:0] size;
	logic[`RSSI_FIELD_SIZE-1:0] rssi;
	logic[`CHANNEL_FIELD_SIZE-1:0] channel;
	logic isAdv;
	logic[`ADDRESS_FIELD_SIZE-1:0] address;
	logic[`HEADER_FIELD_SIZE-1:0] header;
	logic[(`NB_MAX_DATA-1):0] data;

	/*-------------
	-- getFields --
	-------------*/
	// Permet de setter les champs une fois qu'un packet usb avant de l'envoyer
	function void getFields();
		for(int i = 0; i < `USB_FIELD_SIZE; i++)			// Récupération de la taille
			size[i] = dataToSend[i];
		for(int i = 0; i < `RSSI_FIELD_SIZE; i++)				// Récupération du RSSI
			rssi[i] = dataToSend[`USB_FIELD_SIZE+i];
		isAdv = dataToSend[`USB_FIELD_SIZE+`RSSI_FIELD_SIZE];	// Récupération du flag
		for(int i = 0; i < `CHANNEL_FIELD_SIZE; i++)			// Récupération du canal
			channel[i] = dataToSend[`USB_FIELD_SIZE+`RSSI_FIELD_SIZE+1+i]; // Zone reservée de 1 octet
		for(int i = 0; i < `ADDRESS_FIELD_SIZE; i++)			// Récupération de l'adresse
			address[i] = dataToSend[`USB_FIELD_SIZE+`RSSI_FIELD_SIZE+`CHANNEL_FIELD_SIZE+1+`RESERVED_FIELD_SIZE+i];
		for(int i = 0; i < `HEADER_FIELD_SIZE; i++)				// Récupération de l'entête
			header[i] = dataToSend[`USB_FIELD_SIZE+`RSSI_FIELD_SIZE+`CHANNEL_FIELD_SIZE+1+`RESERVED_FIELD_SIZE+`ADDRESS_FIELD_SIZE+i];
		data = 0;											// Pour effacer où on va pas écrire
		for(int i = 0; i < (size-`OCTECT_BEFORE_USB_DATA); i++)// Récupération des datas
			for(int y = 0; y < `OCTET; y++)
				data[(size-`OCTECT_BEFORE_USB_DATA-1-i)*`OCTET+y] = dataToSend[`OCTECT_BEFORE_USB_DATA*`OCTET+i*`OCTET+y];

	endfunction

	/*-----------
	-- psprint --
	-----------*/
	// Affiche les champs du paquet USB
	function string psprint();
		$sformat(psprint, "USB Packet \nSize : %d\nRssi : %d\nChannel : %d\nAdvert : %b\nAddress : %h\nHeader : %h\nData : %h\n",
							size, rssi, channel, isAdv, address, header, data);
	endfunction : psprint
endclass : AnalyzerUsbPacket

// Pour déclarer une fifo contenant des paquets Ble
typedef mailbox #(BlePacket) ble_fifo_t;

// Pour déclarer une fifo contenant des paquets Usb
typedef mailbox #(AnalyzerUsbPacket) usb_fifo_t;

`endif // TRANSACTIONS_SV
