# Komunikační protokol

## Formát příchozí/ovládací zprávy

### První bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-6  | ID                   | Zprávy vygenerované na dané sběrnici budou obsahovat ID poslední odeslané/provedené zprávy  |
| 5    | Očekává odpověď      | Pokud je tento bit 1, je očekávána odpověď ze sběrnice (čtení)                              |
| 4-3  | Adresa registru      | Určuje registr sběrnice pro zápis/čtení                                                     |
| 2-0  | Adresa sběrnice      | Určuje sběrnici, pro kterou je zpráva určena                                                |

Adresa sběrnice 0 je rezervovaná pro celkové nastavení designu.

Adresa registru 0 je rezervovaná pro data určená k odeslání po dané sběrnici. Tyto registry budou dále označeny jako datové.  
Na adrese 0 registr obsahuje stav, který určuje, které sběrnice jsou zapnuté nebo vypnuté.

Adresa registru 3 (stavový registr) je rezervovaná pro stavové bity sběrnice/designu a nelze do ní zapisovat.

Při čtení konfiguračních a stavových registrů (všechny kromě registru 0 u adresy sběrnice > 0) je celá zpráva tvořena pouze tímto bajtem. V jiných případech jsou očekávány další informace.

### Druhý bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-0  | Data                 | Při zápisu do konfiguračního registru obsahuje tento bajt data a ukončuje zprávu            |
| 7-0  | Velikost dat         | Obsahuje informaci o množství dat, která mají být přenesena (zápis do registru 0)           |

### Třetí bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-0  | Data                 | Pokud se neočekává odpověď na sběrnici, tento bajt obsahuje první bajt dat k přenesení      |
| 7-0  | Velikost dat         | Obsahuje informaci o množství dat, která mají být přijata na sběrnici (čtení z registru 0)  |

Následující bajty jsou datové a jejich počet je určen druhým bajtem.

## Formát odchozí zprávy/odpovědi

### První bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-6  | ID                   | ID zprávy, která vygenerovala tuto odpověď                                                  |
| 5    | Chybová zpráva       | Pokud je tento bit 1, byla tato zpráva automaticky vygenerována ze stavového registru       |
| 4-3  | Adresa registru      | Určuje registr sběrnice, ze kterého zpráva pochází                                          |
| 2-0  | Adresa sběrnice      | Určuje sběrnici, ze které zpráva pochází                                                    |

### Druhý bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-0  | Data                 | Při čtení z konfiguračního/stavového registru je tento bajt datový a ukončuje zprávu        |
| 7-0  | Velikost dat         | Obsahuje informaci o množství dat, která mají být přenesena (čtení z registru 0)            |

Následující bajty jsou datové a jejich počet je určen druhým bajtem.


## Příklady komunikace

### Ovládací zprávy

Všechny ID (bity 7-6 prvního bajtu) odpovídají sloupci komunikace (0-3)

| Bajt | Aktivace sběrnice 1 | Čtení registru 2 sběrnice 1 | Odeslání 2B dat přes sběrnici 1 | Pouze čtení 5B přes sběrnici 1 |
|------|---------------------|-----------------------------|---------------------------------|--------------------------------|
|  0   |      00000000       |           01110001          |           10000001              |            11100001            |
|  1   |      00000001       |                             |           00000010              |            00000000            |
|  2   |                     |                             |           databits              |            00000101            |
|  3   |                     |                             |           databits              |                                |


### Odpovědi

Odpovědi na příkladové ovládací zprávy

| Bajt | Aktivace sběrnice 1 | Čtení registru 2 sběrnice 1 | Odeslání 2B dat přes sběrnici 1 | Pouze čtení 5B přes sběrnici 1 |
|------|---------------------|-----------------------------|---------------------------------|--------------------------------|
|  0   |    bez odpovědi     |           01010001          |           bez odpovědi          |            11000001            |
|  1   |                     |           databits          |                                 |            00000101            |
|  2   |                     |                             |                                 |            databits            |
|  3   |                     |                             |                                 |            databits            |
|  4   |                     |                             |                                 |            databits            |
|  5   |                     |                             |                                 |            databits            |
|  6   |                     |                             |                                 |            databits            |