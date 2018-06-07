/*-----------------------------------------------------------------------------
-- HES-SO Master
-- Haute Ecole Specialisee de Suisse Occidentale
-------------------------------------------------------------------------------
-- Cours VSN
--------------------------------------------------------------------------------
--
-- File		: constant.sv
-- Authors	: Jérémie Macchi
--			  Vivien Kaltenrieder
--
-- Date     : 20.05.2018
--
-- Context  : Labo5 VSN
--
--------------------------------------------------------------------------------
-- Description : Contient toutes les constantes utilisées pour le projet
--
--------------------------------------------------------------------------------
-- Modifications :
-- Ver   Date        	Person     	Comments
-- 1.0	 20.05.2018		JMI			Création
-- 2.0	 04.06.2018		JMI			Finalisation
------------------------------------------------------------------------------*/
`ifndef CONSTANT_SV
`define CONSTANT_SV

`define PREAMBLE_FIELD_SIZE         8		// bits
`define ADDRESS_FIELD_SIZE		    32		// bits
`define HEADER_FIELD_SIZE           16		// bits
`define NB_MAX_DATA                 (63*8)	// bits (2^6 - 1)
`define NB_MAX_ADVERTISING_DATA		15	// 2⁴-1 bytes
`define BLE_SIZE_FIELD_SIZE         6		// bits
`define RSSI_FIELD_SIZE             8		// bits

`define USB_FIELD_SIZE              8		// bits
`define CHANNEL_FIELD_SIZE          7		// bits
`define RESERVED_FIELD_SIZE         8		// bits



`define OCTET                       8		// bits
`define OCTECT_BEFORE_USB_DATA      10		// bytes

`define NB_FREQ	                    79				// Nombre de canaux Bluetooth

`define PREAMBLE                    8'b01010101		// Valeur du préambule des trames BLE
`define BAD_PREAMBLE                8'b00110011		// Valeur incorrecte du préambule
`define ADVERTISING_ADDRESS	        32'h12345678	// Adresse pour les trames d'advertising
`define TEST_ADDRESS                32'h1234ABCD	// Adresse quelconque d'un module BLE

`define NB_MAX_ADDRESS              16		// Nombre maximum d'adresses que le DUT peut stocker

`define NB_MAX_BLE_PAQUET           40		// Taille du tableaux de paquets BLE du scoreboard

`define DATA_O_SIZE                 8		// bits

`define WATCHDOG_TIME               25000	// Temps pour la gestion du watchdog (500 us)

typedef logic[`ADDRESS_FIELD_SIZE-1:0] address_t;	// Definition du type address_t

`endif // CONSTANT_SV
