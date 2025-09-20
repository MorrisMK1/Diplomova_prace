# Diplomová práce

Obvod expanderu datových sběrnic

Data Bus Expander circuit

## Popis
Vytvoření designu kontroleru ovládajícího přenos dat z hlavní sběrnice na jednu z více vedlejších a zpět.  
Komunikační protokol je popsán [ZDE](comm_protocol.md).  
Vnitřní funkčnost je popsána [ZDE](inner_protocol.md).

Tento systém umožňuje jinému zařízení připojení a ovládání více sběrnic pomocí rozhraní UART.
Umožňuje samostatné nastavení ovládaných(podřízených) sběrnic i hlavní sběrnice.
Obsahuje vnitřní buffer umožňující bufferování zpráv a jednoduché přenosy mezi různě rychlými sběrnicemi.

## Description
Designing a controller to manage data transfer from the master bus to one of several slave buses and back.  
The communication protocol is described [HERE](comm_protocol_en.md).  
The internal functionality is described [HERE](inner_protocol_en.md).

This system allows another device to connect and control multiple buses via the UART interface.
It enables independent configuration of both the controlled (slave) buses and the master bus.
It includes an internal buffer for message buffering and simple transfers between buses with different speeds.

## Technologie

- Jazyk: VHDL/Verilog
- Testovací software: Modelsim

- Language: VHDL/Verilog
- Testing software: Modelsim
