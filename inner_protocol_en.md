# Internal Circuit Protocol

Description of the data transfer system from the master bus to the slave buses and message generation from the slave bus to the master bus.

![Schema of the design](data/Schema_prace.drawio.png)

## Data Reception

![State machine of the master bus](data/Master_bus.drawio.png)  
![State machine of the router](data/Router.drawio.png)  
![State machine of the slave bus](data/Slave_bus.drawio.png)

## Data Transmission

![State machine of the collector](data/Selector.drawio.png)

# Konfigurační registry
| Registr | Přístup | <7> | <6> | <5> | <4> | <3> | <2> | <1> | <0> |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|    0    |    W    | přesměrován do vstupních dat (max 256 B)            ||||||||
|    1    |   RW    | Povolit timeout |Povolit parity bit|Povolit přerušení|Povolit příchozí data bez požadavku|Povolit automatické hlášení chyb|bitrate <2>|bitrate <1>|bitrate <0>|
|    2    |   RW    | Reset |Sudá/Lichá parita (0/1)| Timeout v počtu zpráv <5> | Timeout v počtu zpráv <4> | Timeout v počtu zpráv <3> | Timeout v počtu zpráv <2> | Timeout v počtu zpráv <1> | Timeout v počtu zpráv <0> |
|    3    |    R(W)    |Šum příznak|Neočekávaná zpráva|-----|-----|Špatná velikost příchozích dat|Parita příznak|Timeout příznak|Frame příznak|
|  Délka timeoutu  | REGISTR 2 | REGISTR 1 |
| :--------------: |:---------:|:---------:|
|   bez timeoutu   | xx000000  | 0xxxxxxx  |
|  6 + 0 * 4 = 6   | xx000000  | 1xxxxxxx  |
|  6 + 1 * 4 = 10  | xx000001  | 1xxxxxxx  |
|  6 + 2 * 4 = 14  | xx000011  | 1xxxxxxx  |
|  6 + 3 * 4 = 18  | xx000101  | 1xxxxxxx  |
|       ...        |   ...     |   ...     |
| 6 + 63 * 4 = 258 | xx111111  | 1xxxxxxx  |
## Poznámky
 Některá nastavení nejsou podporována na všech sběrnicích, jako například Enable interrupt a Timeout na I2C.
 
 Registr 3 (stavový registr) se resetuje po každém automatickém odeslání nebo při pokusu o zápis do registru 3.
 Reset bit resetuje ovladač sběrnice a ponechá hodnoty v konfiguračních registrech.
