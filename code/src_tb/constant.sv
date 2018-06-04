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

`define TAILLE_PREAMBULE	8		// bits
`define TAILLE_ADRESSE		32		// bits
`define TAILLE_ENTETE		16		// bits
`define TAILLE_DEVICE_ADDR	32		// bits
`define TAILLE_MAX_DATA		(63*8)	// bits
`define TAILLE_SIZE_BLE		6		// bits
`define TAILLE_RSSI			8		// bits

`define TAILLE_SIZE_USB		8		// bits
`define TAILLE_CHANNEL		7		// bits
`define TAILLE_RESERVED		8		// bits

`define TAILLE_MAX_DATA_ADVERTISING		15	// 2⁴-1 bytes

`define OCTET				8		// bits
`define NB_OCTET_AVANT_DATA	10		// bytes

`define NB_FREQ	79					// Nombre de canaux Bluetooth

`define PREAMBULE			8'b01010101		// Valeur du préambule des trames BLE
`define FAUX_PREAMBULE		8'b00110011		// Valeur incorrect du préambule
`define ADDRESS_ADVERTISING	32'h12345678	// Adresse pour les trames d'advertising
`define ADDRESS_TEST		32'h1234ABCD	// Adresse quelconque d'un module BLE

`define NB_MAX_ADRESSE		16		// Nombre maximum d'adresse que le DUT peut stocker

`define NB_MAX_PAQUET_SEND	40		// Taille de tableaux de paquets BLE du scoreboard

`define TAILLE_DATA_O		8		// bits

`define TIME_WATCHDOG		25000	// Temps pour la gestion du watchdog

typedef logic[`TAILLE_ADRESSE-1:0] address_t;	// Definition du type address_t

`endif // CONSTANT_SV
