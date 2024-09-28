# Komunikační protokol

## Formát zprávy příchozí/ovládací zprávy

### První Bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-6  | ID                   | Zprávy vygenerované na dané sběrnici budou obsahovat ID poslední odeslané/provedené zprávy  |
| 5    | Očekává odpověď      | Pokud je tento bit 1 je očekávána odpověď ze sběrnice (čtení)                               |
| 4-3  | Adresa registru      | Určuje registr sběrnice pro zápis/čtení                                                     |
| 2-0  | Adresa sběrnice      | Určuje sběrnici pro kterou je zpráva určena                                                 |

Adresa sběrnice 0 je rezervovaná pro celkové nastavení designu.

Adresa registru 0 je rezervovaná pro data určená pro odeslání po dané sběrnici. Dále budou tyto registry označené jako datové. 
Na adrese 0 ale obsahuje registr určující vypnuté a zapnuté sběrnice.

Adresa registru 3 (stavový registr) je rezervovaná pro stavové bity sběrnice/designu, nelze zapsat.

Při čtení konfiguračních a stavových registrů (všechny kromě registrů 0 u adresy sběrnice > 0) je celá zpráva pouze tento byte.
V jiných případech jsou očekávány další informace

### Druhý Bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-0  | Data                 | Při zápisu do konfiguračního registru je tento bit datový a ukončuje zprávu                 |
| 7-0  | Velikost dat         | Obsahuje informaci o množství dat která mají být přenesena (zápis do registru 0)            |

### Třetí Bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-0  | Data                 | Pokud se neočekává odpověď na sběrnici tento byte obsahuje první byte dat k přenesení       |
| 7-0  | Velikost dat         | Obsahuje informaci o množství dat která mají být přijmuta na sběrnici (čtení z registru 0)  |


Následující byty jsou datové a jejich počet je určen Druhým bajtem.


## Formát zprávy odchozí/odpovědi

### První Bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-6  | ID                   | ID zprávy, která vygenerovala tuto odpověď                                                  |
| 5    | Chybová zpráva       | Pokud je tento bit 1 byla tato zpráva automaticky vygenerovaná ze stavového registru        |
| 4-3  | Adresa registru      | Určuje registr sběrnice, ze kterého zpráva pochází                                          |
| 2-0  | Adresa sběrnice      | Určuje sběrnici ze které zpráva pochází                                                     |


### Druhý Bajt

| Bity | Popis                | Význam                                                                                      |
|------|----------------------|---------------------------------------------------------------------------------------------|
| 7-0  | Data                 | Při čtení z konfiguračního/stavového registru je tento bit datový a ukončuje zprávu         |
| 7-0  | Velikost dat         | Obsahuje informaci o množství dat která mají být přenesena (čtení z registru 0)             |

Následující byty jsou datové a jejich počet je určen Druhým bajtem.