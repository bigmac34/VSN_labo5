/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File			: transactions.sv
-- Authors	: Jérémie Macchi
--						Vivien Kaltenrieder
--
-- Date     : 19.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Implémentation des class pour les transactions, packet Ble et Usb
--							 Définition des fifos (mailbox)
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     			Comments
-- 1.0	 19.05.2018		VKR							Explication sur la structure
------------------------------------------------------------------------------*/
`ifndef TRANSACTIONS_SV
`define TRANSACTIONS_SV

`include "constant.sv"

/******************************************************************************
  Input transaction
******************************************************************************/
class BlePacket;

	///< VKR exp: le 64 c'est 2 puissance 6 (6 bits pour la taille des données)
  logic[(`TAILLE_MAX_DATA+`TAILLE_ENTETE+`TAILLE_ADRESSE+`TAILLE_PREAMBULE):0] dataToSend;
  int sizeToSend;

	///< JMI: Pour la gestion de l'envoi bit par bit. Ssvoir quel données on été envoyé
	int position = 0;
	logic valid = 0;


	logic[`TAILLE_ADRESSE-1:0] fixed_address = 32'h12355678;
	logic[`TAILLE_ADRESSE-1:0] fixed_address2 = 32'h55555555;

  /* Champs generes aleatoirement */
  logic isAdv;
  logic dataValid = 1;
	logic[`TAILLE_MAX_DATA-1:0] data;
	///< VKR exp: avec le rand c'est ce qui va être randomisé à l'appel de .randomize() sur la class
  rand logic[`TAILLE_ADRESSE-1:0] addr;
  rand logic[`TAILLE_ENTETE-1:0] header;
  rand logic[`TAILLE_MAX_DATA-1:0] rawData;
  rand logic[`TAILLE_SIZE_BLE-1:0] size;
  rand logic[`TAILLE_RSSI-1:0] rssi;

  /* Contrainte sur la taille des donnees en fonction du type de paquet */
  constraint size_range {
    (isAdv == 1) -> size inside {[4:4]};
    (isAdv == 0) -> size inside {[0:63]};
  }

  function string psprint();
    $sformat(psprint, "BlePacket\nAdvert : %b\nAddress : %h\nSize : %d\nData : %h\n",
                                                       this.isAdv, this.addr, size, data);
  endfunction : psprint

	///< VKR exp: fonction appellée automatiquement après la randomisation
	///< VKR exp: en l'occurence construction d'un paquet
  function void post_randomize();

	logic[`TAILLE_PREAMBULE-1:0] preamble=`PREAMBULE;   // 01010101 fixe

	/* Initialisation des données à envoyer */
  	dataToSend = 0;
  	sizeToSend=size*8+`TAILLE_ENTETE+`TAILLE_ADRESSE+`TAILLE_PREAMBULE;

	/* Cas de l'envoi d'un paquet d'advertizing */
	if (isAdv == 1) begin
			addr = `ADDRESS_ADVERTISING;
        // DeviceAddr = 0. Pour l'exemple
        for(int i=0; i<`TAILLE_ADRESSE;i++)
            rawData[size*8-`TAILLE_ADRESSE+i] = fixed_address[i];
	end

	/* Cas de l'envoi d'un paquet de données */
    else if (isAdv == 0) begin
  			// Peut-être que l'adresse devra être définie d'une certaine manière
				addr = fixed_address;
    end


	/* Affectation des données à envoyer */
	for(int i=0;i<`TAILLE_PREAMBULE;i++)
 		dataToSend[sizeToSend-`TAILLE_PREAMBULE+i]=preamble[i];
	for(int i=0;i<`TAILLE_ADRESSE;i++)
		dataToSend[sizeToSend-`TAILLE_PREAMBULE-`TAILLE_ADRESSE+i]=addr[i];
  $display("Sending packet with address %h\n",addr);
	for(int i=0;i<`TAILLE_ENTETE;i++)
		dataToSend[sizeToSend-`TAILLE_PREAMBULE-`TAILLE_ADRESSE-`TAILLE_ENTETE+i]=0; // reseting the header
	for(int i=0;i<`TAILLE_SIZE_BLE;i++)
		dataToSend[sizeToSend-`TAILLE_PREAMBULE-`TAILLE_ADRESSE-`TAILLE_ENTETE+i]=size[i];	// Puting the size
	data = 0;
	for(int i=0;i<size*8;i++) begin
		dataToSend[sizeToSend-`TAILLE_PREAMBULE-`TAILLE_ADRESSE-`TAILLE_ENTETE-1-i]=rawData[size*8-1-i];
		data[size*8-1-i] = rawData[size*8-1-i];
	end

  if (isAdv) begin
      logic[`TAILLE_DEVICE_ADDR-1:0] ad;
      for(int i=0; i < `TAILLE_DEVICE_ADDR; i++)
          ad[i] = dataToSend[sizeToSend-`TAILLE_PREAMBULE-`TAILLE_ADRESSE-`TAILLE_ENTETE-`TAILLE_DEVICE_ADDR+i];
      $display("Advertising with address %h\n",ad);
  end
  endfunction : post_randomize

	function BlePacket copy();
			BlePacket theCopy = new();
			theCopy.dataToSend = this.dataToSend;
			theCopy.sizeToSend = this.sizeToSend;
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

			return theCopy;
	endfunction

endclass : BlePacket

// A écrire, c'est pour les packets USB
class AnalyzerUsbPacket;
	// Variable modifiée au niveau du monitor
	logic[(64*8+10*8)-1:0] dataToSend;		// pas plus de 64 byte de données

	// Les champs d'un packet USB
	logic[`TAILLE_SIZE_USB-1:0] size;
	logic[`TAILLE_RSSI-1:0] rssi;
	logic[`TAILLE_CHANNEL-1:0] channel;
	logic	isAdv;
	logic[`TAILLE_ADRESSE-1:0] address;
	logic[`TAILLE_ENTETE-1:0] header;
	logic[(`TAILLE_MAX_DATA-1):0] data;

	///< Permet de setter les champs une fois qu'un packet usb est reçu en entier
	function void getFields();
		for(int i = 0; i < `TAILLE_SIZE_USB; i++)		// Récupération de la taille
			size[i] = dataToSend[i];
		for(int i = 0; i < `TAILLE_RSSI; i++)		// Récupération du RSSI
			rssi[i] = dataToSend[`TAILLE_SIZE_USB+i];
		isAdv = dataToSend[`TAILLE_SIZE_USB+`TAILLE_RSSI];				// Récupération du flag
		for(int i = 0; i < `TAILLE_CHANNEL; i++)		// Récupération du canal
			channel[i] = dataToSend[`TAILLE_SIZE_USB+`TAILLE_RSSI+1+i];
																	// Zone reservée de 1 octet
		for(int i = 0; i < `TAILLE_ADRESSE; i++)		// Récupération de l'adresse
			address[i] = dataToSend[`TAILLE_SIZE_USB+`TAILLE_RSSI+`TAILLE_CHANNEL+1+`TAILLE_RESERVED+i];
		for(int i = 0; i < `TAILLE_ENTETE; i++)		// Récupération de l'entête
			header[i] = dataToSend[`TAILLE_SIZE_USB+`TAILLE_RSSI+`TAILLE_CHANNEL+1+`TAILLE_RESERVED+`TAILLE_ADRESSE+i];
		data = 0;	// Pour effacer où on va pas écrire
		for(int i = 0; i < (size-`NB_OCTET_AVANT_DATA); i++)	// Récupération des datas
			for(int y = 0; y < `OCTET; y++)
				data[(size-`NB_OCTET_AVANT_DATA-1-i)*`OCTET+y] = dataToSend[`NB_OCTET_AVANT_DATA*`OCTET+i*`OCTET+y];

	endfunction

	function string psprint();
		$sformat(psprint, "USB Packet \nSize : %d\nRssi : %d\nChannel : %d\nAdvert : %b\nAddress : %h\nHeader : %h\nData : %h\n",
							size, rssi, channel, isAdv, address, header, data);
	endfunction : psprint

endclass : AnalyzerUsbPacket

/// VKR exp: pour déclarer une fifo contenant des paquets Ble
typedef mailbox #(BlePacket) ble_fifo_t;
/// VKR exp: pour déclarer une fifo contenant des paquets Usb
typedef mailbox #(AnalyzerUsbPacket) usb_fifo_t;

`endif // TRANSACTIONS_SV
