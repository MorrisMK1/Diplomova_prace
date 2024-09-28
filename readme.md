# Diplomová práce

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

- [x] Univerzální vnitřní rozhraní sběrnic
- [ ] Uart
  - [x] vytvoření komunikační logiky sběrnice
  - [ ] propojení s univerzálním rozhraním
  - [ ] otestovnání funkčnosti
- [ ] I2C
  - [ ] vytvoření komunikační logiky sběrnice
  - [ ] propojení s univerzálním rozhraním
  - [ ] otestovnání funkčnosti
- [?] SPI
  - [ ] vytvoření komunikační logiky sběrnice
  - [ ] propojení s univerzálním rozhraním
  - [ ] otestovnání funkčnosti
- [?] 1-wire
  - [ ] vytvoření komunikační logiky sběrnice
  - [ ] propojení s univerzálním rozhraním
  - [ ] otestovnání funkčnosti
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

