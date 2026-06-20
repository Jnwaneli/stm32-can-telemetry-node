# Firmware — STM32 CAN Telemetry Node Rev A

## Status

Firmware development is planned as the next phase of this project. The Rev A hardware design is complete, routed, DRC-clean, and prepared for manufacturing output. The firmware will be developed after physical assembly or during early board bring-up.

This folder is reserved for STM32CubeIDE firmware that will initialize the board, read sensor inputs, and transmit telemetry data over CAN.

## Target Hardware

- MCU: STM32F103C8T6
- Programming/debug interface: SWD through J4
- Planned CAN bitrate: 500 kbps
- Planned telemetry transmit period: 100 ms
- Main CAN message ID: 0x100

## Planned Firmware Features

The starter firmware will include:

- System clock initialization
- GPIO setup for LEDs and user button
- ADC setup for AIN1–AIN4
- Digital input reading for DIN1 and DIN2
- Timer input capture for FREQ_IN / wheel-speed signal
- CAN peripheral initialization
- CAN frame transmission using ID 0x100
- Status LED blink for firmware heartbeat
- CAN activity LED toggle when a frame is transmitted
- Error LED behavior for fault/debug conditions

## Planned CAN Message

| CAN ID | DLC | Bytes | Signal | Description |
|---|---:|---|---|---|
| 0x100 | 8 | Byte 0–1 | AIN1_RAW | Raw ADC value from AIN1 |
| 0x100 | 8 | Byte 2–3 | AIN2_RAW | Raw ADC value from AIN2 |
| 0x100 | 8 | Byte 4–5 | AIN3_RAW | Raw ADC value from AIN3 |
| 0x100 | 8 | Byte 6–7 | AIN4_RAW | Raw ADC value from AIN4 |

## Planned Main Loop

```c
while (1)
{
    read_adc_channels();
    read_digital_inputs();
    measure_frequency_input();

    pack_adc_values_into_can_frame();
    transmit_can_message(0x100);

    toggle_status_led();
    delay_ms(100);
}
```

## Bring-Up Firmware Steps

1. Create STM32CubeIDE project for STM32F103C8T6.
2. Configure system clock.
3. Configure GPIO pins for LEDs and user button.
4. Flash basic LED blink firmware through SWD.
5. Configure ADC channels for AIN1–AIN4.
6. Read ADC values and verify expected counts.
7. Configure CAN peripheral at 500 kbps.
8. Transmit CAN ID 0x100 every 100 ms.
9. Verify frames with a CAN analyzer.
10. Add error handling and LED indicators.

## Future Firmware Improvements

- Convert raw ADC counts into calibrated sensor values.
- Add CAN receive support for configuration commands.
- Add timeout/error flags.
- Add wheel-speed calculation from frequency input.
- Add diagnostic CAN messages.
- Add configurable transmit rate.
- Add bootloader/update support.
- Add structured firmware documentation.
