# Firmware — STM32 CAN Telemetry Node Rev A

## Status

A starter STM32CubeMX / STM32CubeIDE firmware framework has been created for the STM32 CAN Telemetry Node Rev A board.

Current firmware status:

- STM32CubeMX configuration created for STM32F103C8T6 / STM32F103C8Tx
- STM32CubeIDE starter firmware generated
- SWD debug enabled
- HSE configured for the external 8 MHz crystal
- ADC1 configured for AIN1-AIN4 on PA0-PA3
- CAN configured on PA11 / PA12 for planned 500 kbps operation
- CAN frame structure implemented for telemetry ID `0x100`
- Starter firmware builds with 0 errors

This firmware has not yet been tested on physical Rev A hardware. Hardware validation is planned after PCB assembly.

## Target Hardware

- MCU: STM32F103C8T6, LQFP-48
- Programming/debug interface: SWD through J4
- SWDIO: PA13
- SWCLK: PA14
- External clock: 8 MHz HSE crystal
- CAN transceiver: SN65HVD230-style 3.3 V CAN transceiver
- Planned CAN bitrate: 500 kbps
- Planned telemetry transmit period: 100 ms
- Main CAN message ID: `0x100`

## Configured Pin Mapping

| Signal | STM32 Pin | Function |
|---|---|---|
| AIN1 | PA0 | ADC1_IN0 |
| AIN2 | PA1 | ADC1_IN1 |
| AIN3 | PA2 | ADC1_IN2 |
| AIN4 | PA3 | ADC1_IN3 |
| FREQ_IN | PA8 | TIM1_CH1 / planned frequency input |
| CAN_RX | PA11 | CAN receive |
| CAN_TX | PA12 | CAN transmit |
| SWDIO | PA13 | SWD debug |
| SWCLK | PA14 | SWD debug |
| OSC_IN | PD0 | HSE input |
| OSC_OUT | PD1 | HSE output |

## Implemented Starter Firmware Features

The current starter firmware includes:

- System clock initialization using the external 8 MHz HSE crystal
- GPIO initialization for debug LEDs and user input signals
- ADC setup for four analog telemetry inputs
- ADC calibration before first conversion
- CAN transmit header setup for standard ID `0x100`
- Packing of four raw 16-bit ADC readings into an 8-byte CAN payload
- 100 ms transmit-loop structure
- Status LED heartbeat behavior
- CAN activity LED toggle when a CAN message is queued
- Error LED behavior for CAN or ADC initialization issues

## CAN Message

| CAN ID | DLC | Bytes | Signal | Description |
|---|---:|---|---|---|
| 0x100 | 8 | Byte 0-1 | AIN1_RAW | Raw ADC value from AIN1 |
| 0x100 | 8 | Byte 2-3 | AIN2_RAW | Raw ADC value from AIN2 |
| 0x100 | 8 | Byte 4-5 | AIN3_RAW | Raw ADC value from AIN3 |
| 0x100 | 8 | Byte 6-7 | AIN4_RAW | Raw ADC value from AIN4 |

Payload format is little-endian for each 16-bit ADC value:

```text
Byte 0 = AIN1 low byte
Byte 1 = AIN1 high byte
Byte 2 = AIN2 low byte
Byte 3 = AIN2 high byte
Byte 4 = AIN3 low byte
Byte 5 = AIN3 high byte
Byte 6 = AIN4 low byte
Byte 7 = AIN4 high byte
```

## Main Loop Structure

```c
while (1)
{
    Read_ADC_Channels();
    Pack_CAN_Data();

    if (HAL_CAN_AddTxMessage(&hcan, &TxHeader, TxData, &TxMailbox) == HAL_OK)
    {
        HAL_GPIO_TogglePin(LED_CAN_GPIO_Port, LED_CAN_Pin);
    }
    else
    {
        HAL_GPIO_WritePin(LED_ERROR_GPIO_Port, LED_ERROR_Pin, GPIO_PIN_SET);
    }

    HAL_GPIO_TogglePin(LED_STATUS_GPIO_Port, LED_STATUS_Pin);

    HAL_Delay(100);
}
```

## Project Files

The firmware folder contains the STM32CubeMX / STM32CubeIDE starter firmware files.

Expected folder structure:

```text
Firmware/
├── README.md
└── STM32_CAN_Telemetry_Node_FW/
    ├── Core/
    ├── Drivers/
    └── STM32_CAN_Telemetry_Node_FW.ioc
```

Depending on upload method, hidden STM32CubeIDE/Eclipse project files such as `.project`, `.cproject`, or `.settings/` may not be present in GitHub. The `.ioc` file preserves the CubeMX peripheral configuration and can be used to regenerate the project if needed.

## Current Limitations

Because the Rev A PCB has not been assembled yet, the following items are still planned:

- Flashing firmware to physical hardware
- Verifying 3.3 V and 5 V rails before programming
- Confirming SWD connection
- Testing LED behavior
- Measuring ADC readings from real sensor inputs
- Verifying CAN transmission with a CAN analyzer
- Validating CAN bitrate and bus termination
- Testing error handling during board bring-up
- Implementing and validating frequency input capture for FREQ_IN
- Reading and reporting DIN1 and DIN2 digital input states

## Future Firmware Improvements

- Convert raw ADC counts into calibrated sensor values
- Add digital input reporting for DIN1 and DIN2
- Add timer input capture for FREQ_IN / wheel-speed signal
- Add CAN receive support for configuration commands
- Add timeout/error flags
- Add diagnostic CAN messages
- Add configurable transmit rate
- Add structured firmware documentation
- Add hardware-tested bring-up notes after Rev A assembly
