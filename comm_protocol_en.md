# Communication Protocol

## Incoming/Control Message Format

### First Byte

| Bits | Description           | Meaning                                                                                  |
|------|-----------------------|------------------------------------------------------------------------------------------|
| 7-6  | ID                    | Messages generated on the given bus will contain the ID of the last sent/executed message|
| 5    | Expecting Response    | If this bit is 1, a response from the bus is expected (read operation)                   |
| 4-3  | Register Address      | Specifies the bus register for write/read operations                                     |
| 2-0  | Bus Address           | Specifies the bus for which the message is intended                                      |

Bus address 0 is reserved for overall system configuration.

Register address 0 is reserved for data intended for transmission on the respective bus. These registers will be referred to as data registers.  
However, at address 0, the register contains the configuration that controls which buses are enabled or disabled.

Register address 3 (status register) is reserved for the status bits of the bus/system and cannot be written to.

When reading configuration and status registers (all except register 0 at bus address > 0), the entire message is just this byte. In other cases, additional information is expected.

### Second Byte

| Bits | Description           | Meaning                                                                                  |
|------|-----------------------|------------------------------------------------------------------------------------------|
| 7-0  | Data                  | When writing to a configuration register, this byte contains data and terminates the message|
| 7-0  | Data Size             | Contains information about the amount of data to be transferred (write to register 0)     |

### Third Byte

| Bits | Description           | Meaning                                                                                  |
|------|-----------------------|------------------------------------------------------------------------------------------|
| 7-0  | Data                  | If no response from the bus is expected, this byte contains the first byte of data to be transmitted |
| 7-0  | Data Size             | Contains information about the amount of data to be received from the bus (read from register 0) |

The following bytes are data, and their count is determined by the second byte.

## Outgoing/Response Message Format

### First Byte

| Bits | Description           | Meaning                                                                                  |
|------|-----------------------|------------------------------------------------------------------------------------------|
| 7-6  | ID                    | ID of the message that generated this response                                           |
| 5    | Error Message         | If this bit is 1, this message was automatically generated from the status register      |
| 4-3  | Register Address      | Specifies the bus register from which the message originated                             |
| 2-0  | Bus Address           | Specifies the bus from which the message originated                                      |

### Second Byte

| Bits | Description           | Meaning                                                                                  |
|------|-----------------------|------------------------------------------------------------------------------------------|
| 7-0  | Data                  | When reading from the configuration/status register, this byte contains data and terminates the message |
| 7-0  | Data Size             | Contains information about the amount of data to be transferred (read from register 0)    |

The following bytes are data, and their count is determined by the second byte.
