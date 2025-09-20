# Komunikační protokol

## Tvar zprávy mezi ovládacím zařízením a systémem.

V tabulce níže je "/" použito k oddělení možných obsahů a `()` k obsahu při odpovědi. Zprávy jsou posílány po hlavní sběrnici a na vedlejší sběrnice se dostává pouze payload.

### Tvar zprávy hlavní sběrnice

| Hlavička  | Hlavička | Hlavička | Data |
|--------------------|---------|---------|--------------------|
|  1. bajt | 2. bajt | 3. bajt | 0–255 bajtů |
| 7–6: ID            | velikost dat k odeslání / konf. | velikost dat k přijetí (příznaky) | payload |
| 5: Special         |   -\|\|-  |  -\|\|-   |  -\|\|-          |
| 4–3: Register      |   -\|\|-  |  -\|\|-   |  -\|\|-          |
| 2–0: Bus           |   -\|\|-  |  -\|\|-   |  -\|\|-          |

**Popis polí:**
- **ID (bity 7–6):** Pomocná informace pro uživatele k identifikaci zprávy.
- **Special (bit 5):** V závislosti na typu cílové sběrnice aktivuje určitou funkci.
- **Register (bity 4–3):** Určuje, zda se jedná o konfigurační nebo datovou zprávu a cíl konfigurace.
- **Bus (bity 2–0):** Určuje cílovou sběrnici pro zprávu.
- **2. bajt:** Obsahuje velikost dat v bajtech k odeslání nebo konfigurační data (podle pole *Register*).
- **3. bajt:** Obsahuje velikost dat v bajtech k přijetí. Při odpovědi obsahuje chybové příznaky.
- **Data:** Pokud jsou odesílána data, bude zde uloženo až 255 bajtů.


## Příklady komunikace

### Ovládací zprávy

Všechny ID (bity 7-6 prvního bajtu) odpovídají sloupci komunikace (0-3)

| Bajt | Aktivace sběrnice 1 | Čtení registru 2 sběrnice 1 | Odeslání 2B dat přes sběrnici 1 | Pouze čtení 5B přes sběrnici 1 |
|------|---------------------|-----------------------------|---------------------------------|--------------------------------|
|  0   |      00000000       |           01110001          |           10000001              |            11100001            |
|  1   |      00000001       |           00000000          |           00000010              |            00000000            |
|  2   |      00000000       |           00000000          |           00000000              |            00000101            |
|  3   |                     |                             |           databits              |                                |
|  4   |                     |                             |           databits              |                                |

### Odpovědi

Odpovědi na příkladové ovládací zprávy

| Bajt | Aktivace sběrnice 1 | Čtení registru 2 sběrnice 1 | Odeslání 2B dat přes sběrnici 1 | Pouze čtení 5B přes sběrnici 1 |
|------|---------------------|-----------------------------|---------------------------------|--------------------------------|
|  0   |    bez odpovědi     |           01010001          |           bez odpovědi          |            11000001            |
|  1   |                     |           databits          |                                 |            00000101            |
|  2   |                     |           flag_reg          |                                 |            flag_reg            |
|  3   |                     |                             |                                 |            databits            |
|  4   |                     |                             |                                 |            databits            |
|  5   |                     |                             |                                 |            databits            |
|  6   |                     |                             |                                 |            databits            |
|  7   |                     |                             |                                 |            databits            |

# Vnitřní funkčnost je popsána [ZDE](inner_protocol_en.md).