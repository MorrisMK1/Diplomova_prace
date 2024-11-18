# Diplomová práce

Obvod expanderu datových sběrnic

Data Bus Expander circuit

## Popis
Vytvoření designu kontroleru ovládajícího přenos dat z hlavní sběrnice na jednu z více vedlejších a zpět.  
Komunikační protokol je popsán [ZDE](comm_protocol.md).  
Vnitřní funkčnost je popsána [ZDE](inner_protocol.md).

Designing a controller to manage data transfer from the master bus to one of several slave buses and back.  
The communication protocol is described [HERE](comm_protocol_en.md).  
The internal functionality is described [HERE](inner_protocol_en.md).

## Technologie

- Jazyk: VHDL/Verilog
- Testovací software: Modelsim

- Language: VHDL/Verilog
- Testing software: Modelsim

## Úkoly

- [ ] Univerzální vnitřní rozhraní sběrnic
  - [x] navržení registrů a logiky
  - [ ] otestovnání funkčnosti
- [x] Uart
  - [x] vytvoření komunikační logiky sběrnice
  - [x] otestovnání funkčnosti
  - [x] propojení s univerzálním rozhraním
- [ ] I2C
  - [ ] vytvoření komunikační logiky sběrnice
  - [ ] otestovnání funkčnosti
  - [ ] propojení s univerzálním rozhraním
- [?] SPI
  - [ ] vytvoření komunikační logiky sběrnice
  - [ ] otestovnání funkčnosti
  - [ ] propojení s univerzálním rozhraním
- [?] 1-wire
  - [ ] vytvoření komunikační logiky sběrnice
  - [ ] otestovnání funkčnosti
  - [ ] propojení s univerzálním rozhraním
- [ ] Vyrovnávací paměť
  - [ ] vytvořit fifo obvod
  - [ ] test funkčnosti
  - [ ] zapojení pro data, ID a velikostní paměti
  - [ ] test zapojení s univerzálním rozhraním
- [ ] Kontroler komunikace
  - [ ] Hlavní sběrnice
    - [ ] dekódování zprávy
    - [ ] routování zprávy
    - [ ] otestování zpracování zprávy 
  - [ ] Vedlejší sběrnice
    - [ ] zakódování zprávy
    - [ ] routování zprávy
    - [ ] otestování zpracování zprávy
- [ ] Konfigurace logiky
  - [ ] vytvoření konfiguračních registrů a logiky
  - [ ] otestování nastavení designu

