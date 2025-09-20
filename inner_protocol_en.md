# Internal Circuit Protocol

- **TODO** Create schema in english.

Description of the system for transferring data from the main bus to secondary buses and generating messages from the secondary bus for the main bus.

![Schema_prace](data/Full_schema_teorie-cz.PNG)

## Data Processing

![Data flow in the system](data/data_flow.png)

## The following tables describe register maps:

- **Overall Design Registers**  
- **UART Bus Registers**  
- **I2C Bus Registers**  
- **SPI Bus Registers**  
- **Baudrate Settings Map**

### Overall Design Registers

| Position | Name      | Size   | Default | Description                                  |
|----------|-----------|--------|---------|----------------------------------------------|
| **1st Register**     |         |        |         |                                              |
| 2:0      | clk_div   | 3b     | 0       | baudrate selection, see "Baudrate Options" table |
| 5        | par_en    | 1b     | 0       | parity bit enable                           |
| 6        | par_odd   | 1b     | 0       | switch to odd parity                        |
| **2nd Register**     |         |        |         |                                              |
| 4:0      | timeout   | 5b     | 0       | number of bytes (+1) until timeout          |
| **3rd Register**     |         |        |         |                                              |
| 7:0      | enable    | 8b     | 0       | bus enable signals                          |
| **Error Register**   |         |        |         |                                              |
| 0        | frame     | 1b     | 0       | frame end error                             |
| 1        | parity    | 1b     | 0       | parity error                                |
| 3        | data      | 1b     | 0       | data size error                             |
| 6        | disconnect| 1b     | 0       | device not detected                         |
| 7        | noise     | 1b     | 0       | noise level error                           |

### UART Bus Registers

| Position | Name      | Size   | Default | Description                                  |
|----------|-----------|--------|---------|----------------------------------------------|
| **1st Register**     |         |        |         |                                              |
| 2:0      | clk_div   | 3b     | 0       | baudrate selection, see "Baudrate Options" table |
| 4:3      | word      | 2b     | 0       | word length (+5) in bits                     |
| 5        | par_en    | 1b     | 0       | parity bit enable                           |
| 6        | par_odd   | 1b     | 0       | switch to odd parity                        |
| 7        | rst       | 1b     | 0       | bus reset                                   |
| **2nd Register**     |         |        |         |                                              |
| 4:0      | timeout   | 5b     | 0       | number of bytes (+1) until timeout          |
| 5        | ready_en  | 1b     | 0       | CTS-RTS enable                              |
| 6        | ready_dir | 1b     | 0       | CTS-RTS direction (0 => RTS inward)         |
| 7        | polarity  | 1b     | 0       | bus polarity                                |
| **Error Register**   |         |        |         |                                              |
| 0        | frame     | 1b     | 0       | frame end error                             |
| 1        | parity    | 1b     | 0       | parity error                                |
| 3        | data      | 1b     | 0       | data size error                             |
| 5        | timeout   | 1b     | 0       | timeout during transmission                 |
| 7        | noise     | 1b     | 0       | noise level error                           |

### I2C Bus Registers

| Position | Name        | Size   | Default | Description                                  |
|----------|-------------|--------|---------|----------------------------------------------|
| **1st Register**       |         |        |         |                                              |
| 2:0      | clk_div     | 3b     | 0       | baudrate selection, see "Baudrate Options" table |
| 4        | inter_en    | 1b     | 0       | interrupt enable                            |
| 5        | slv_en      | 1b     | 0       | slave mode (not implemented)                |
| 6        | multimaster | 1b     | 0       | multimaster enable                          |
| 7        | rst         | 1b     | 0       | bus reset                                   |
| **2nd Register**       |         |        |         |                                              |
| 6:0      | address     | 5b     | 0       | address for slave mode                      |
| **Error Register**     |         |        |         |                                              |
| 0        | frame       | 1b     | 0       | frame end error                             |
| 1        | ack         | 1b     | 0       | error: no ack received                      |
| 2        | data_size   | 1b     | 0       | data size error                             |
| 3        | data_owf    | 1b     | 0       | data overflow error                         |
| 4        | interrupt   | 1b     | 0       | interrupt detected                          |
| 5        | disconnect  | 1b     | 0       | disconnected from bus                       |
| 6        | block       | 1b     | 0       | bus blocked error                           |
| 7        | noise       | 1b     | 0       | noise level error                           |

### SPI Bus Registers

| Position | Name      | Size   | Default | Description                                  |
|----------|-----------|--------|---------|----------------------------------------------|
| **1st Register**     |         |        |         |                                              |
| 2:0      | clk_div   | 3b     | 0       | baudrate selection, see "Baudrate Options" table |
| 3        | data_dir  | 1b     | 0       | 0 => MSB first                              |
| 4        | SPOL      | 1b     | 0       | CS polarity (0 = active low)                 |
| 5        | CPOL      | 1b     | 0       | clock polarity                              |
| 6        | CPHA      | 1b     | 0       | read edge (0 = first edge)                  |
| 7        | rst       | 1b     | 0       | bus reset                                   |
| **2nd Register**     |         |        |         |                                              |
| 2:0      | address   | 3b     | 0       | 3 => 8 CS logic                             |
| **Error Register**   |         |        |         |                                              |
| 1        | block_reg | 1b     | 0       | error: cannot write to register             |
| 3        | data_owf  | 1b     | 0       | data overflow error                         |
| 7        | noise     | 1b     | 0       | noise level error                           |

### Baudrate Options

| clk_div | UART        | I2C        | SPI      |
|---------|-------------|------------|----------|
| 0       | 9.6 Kbps    | 1.5 Kbps   | 20 Kbps  |
| 1       | 19.2 Kbps   | 2 Kbps     | 50 Kbps  |
| 2       | 28.8 Kbps   | 5 Kbps     | 100 Kbps |
| 3       | 57.6 Kbps   | 10 Kbps    | 200 Kbps |
| 4       | 76.8 Kbps   | 50 Kbps    | 400 Kbps |
| 5       | 115.2 Kbps  | 100 Kbps   | 1 Mbps   |
| 6       | 460.8 Kbps  | 200 Kbps   | 2 Mbps   |
| 7       | 921.6 Kbps  | 400 Kbps   | 4 Mbps   |

Each bus has its own configuration and error registers. These tables only describe the meaning of individual bits for each bus type. Thus, buses can have independent settings. Only the overall design settings affect all other registers. The state of each bus is reset when its *enable* signal changes.

## Notes
  Some settings are not supported on all buses, such as enabling unexpected incoming data on I2C.
  
  Register 3 (status register) is reset after each automatic transmission or when attempting to write to register 3.
  The reset bit resets the bus driver and keeps values in configuration registers.

# The communication protocol is described [HERE](comm_protocol_en.md).  
