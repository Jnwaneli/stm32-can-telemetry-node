/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * STM32 CAN Telemetry Node Rev A
  * Starter firmware framework for planned ADC-to-CAN bring-up.
  *
  * Status:
  * - Firmware structure for GPIO, ADC, and CAN transmit logic.
  * - Intended CAN message: Standard ID 0x100, DLC 8.
  * - Hardware validation is planned after PCB assembly.
  * - This firmware has not yet been tested on physical Rev A hardware.
  *
  * Copyright (c) 2026 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "adc.h"
#include "can.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

#define CAN_TELEMETRY_ID        0x100U
#define CAN_TELEMETRY_DLC       8U
#define TELEMETRY_PERIOD_MS     100U

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

/*
 * Raw ADC values:
 * adc_values[0] = AIN1_RAW from PA0 / ADC_IN0
 * adc_values[1] = AIN2_RAW from PA1 / ADC_IN1
 * adc_values[2] = AIN3_RAW from PA2 / ADC_IN2
 * adc_values[3] = AIN4_RAW from PA3 / ADC_IN3
 */
uint16_t adc_values[4] = {0};

/*
 * CAN transmit objects for the planned telemetry frame.
 */
CAN_TxHeaderTypeDef TxHeader;
uint8_t TxData[8] = {0};
uint32_t TxMailbox;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);

/* USER CODE BEGIN PFP */

static void Read_ADC_Channels(void);
static void Pack_CAN_Data(void);
static void Init_CAN_Message(void);

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/*
 * Read_ADC_Channels
 *
 * Reads four ADC channels configured in ADC1 scan mode:
 * Rank 1: PA0 / ADC_IN0 / AIN1
 * Rank 2: PA1 / ADC_IN1 / AIN2
 * Rank 3: PA2 / ADC_IN2 / AIN3
 * Rank 4: PA3 / ADC_IN3 / AIN4
 *
 * Important:
 * ADC is started once, then each ranked conversion is read in order.
 * This avoids restarting the ADC sequence at Rank 1 every time.
 */
static void Read_ADC_Channels(void)
{
    HAL_ADC_Start(&hadc1);

    for (uint8_t i = 0; i < 4; i++)
    {
        if (HAL_ADC_PollForConversion(&hadc1, 10) == HAL_OK)
        {
            adc_values[i] = (uint16_t)HAL_ADC_GetValue(&hadc1);
        }
    }

    HAL_ADC_Stop(&hadc1);
}

/*
 * Pack_CAN_Data
 *
 * Packs four 16-bit raw ADC values into an 8-byte CAN payload.
 *
 * Payload format:
 * Byte 0-1: AIN1_RAW
 * Byte 2-3: AIN2_RAW
 * Byte 4-5: AIN3_RAW
 * Byte 6-7: AIN4_RAW
 *
 * Each uint16_t value is packed little-endian:
 * low byte first, high byte second.
 */
static void Pack_CAN_Data(void)
{
    TxData[0] = (uint8_t)(adc_values[0] & 0xFF);
    TxData[1] = (uint8_t)((adc_values[0] >> 8) & 0xFF);

    TxData[2] = (uint8_t)(adc_values[1] & 0xFF);
    TxData[3] = (uint8_t)((adc_values[1] >> 8) & 0xFF);

    TxData[4] = (uint8_t)(adc_values[2] & 0xFF);
    TxData[5] = (uint8_t)((adc_values[2] >> 8) & 0xFF);

    TxData[6] = (uint8_t)(adc_values[3] & 0xFF);
    TxData[7] = (uint8_t)((adc_values[3] >> 8) & 0xFF);
}

/*
 * Init_CAN_Message
 *
 * Configures the transmit header for the planned telemetry frame.
 *
 * CAN frame:
 * Standard 11-bit ID: 0x100
 * DLC: 8 bytes
 * Frame type: Data frame
 */
static void Init_CAN_Message(void)
{
    TxHeader.StdId = CAN_TELEMETRY_ID;
    TxHeader.ExtId = 0x000;
    TxHeader.IDE = CAN_ID_STD;
    TxHeader.RTR = CAN_RTR_DATA;
    TxHeader.DLC = CAN_TELEMETRY_DLC;
    TxHeader.TransmitGlobalTime = DISABLE;
}

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /*
   * Reset of all peripherals, initializes the Flash interface,
   * and initializes the SysTick timer.
   */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /*
   * Configure the system clock.
   * Current setup uses the external 8 MHz HSE crystal and PLL x9
   * for 72 MHz SYSCLK.
   */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /*
   * Initialize all configured peripherals generated by STM32CubeMX.
   */
  MX_GPIO_Init();
  MX_ADC1_Init();
  MX_CAN_Init();

  /* USER CODE BEGIN 2 */

  /*
   * Initialize debug LEDs to a known OFF state.
   * Exact LED behavior will be verified during physical board bring-up.
   */
  HAL_GPIO_WritePin(LED_STATUS_GPIO_Port, LED_STATUS_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED_CAN_GPIO_Port, LED_CAN_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(LED_ERROR_GPIO_Port, LED_ERROR_Pin, GPIO_PIN_RESET);

  /*
   * Calibrate ADC1 before first conversion.
   * This is recommended for STM32F1 ADC accuracy.
   */
  if (HAL_ADCEx_Calibration_Start(&hadc1) != HAL_OK)
  {
      HAL_GPIO_WritePin(LED_ERROR_GPIO_Port, LED_ERROR_Pin, GPIO_PIN_SET);
  }

  /*
   * Prepare and start CAN peripheral.
   * If CAN start fails, LED_ERROR is set and remains set.
   */
  Init_CAN_Message();

  if (HAL_CAN_Start(&hcan) != HAL_OK)
  {
      HAL_GPIO_WritePin(LED_ERROR_GPIO_Port, LED_ERROR_Pin, GPIO_PIN_SET);
  }

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
      /*
       * Starter telemetry loop:
       * 1. Read four raw ADC channels.
       * 2. Pack values into CAN payload.
       * 3. Transmit CAN frame ID 0x100.
       * 4. Toggle LEDs for planned bring-up feedback.
       *
       * Note:
       * This loop has not been tested on Rev A hardware yet.
       */
      Read_ADC_Channels();
      Pack_CAN_Data();

      if (HAL_CAN_AddTxMessage(&hcan, &TxHeader, TxData, &TxMailbox) == HAL_OK)
      {
          /*
           * Planned behavior:
           * LED_CAN toggles whenever a CAN message is queued successfully.
           */
          HAL_GPIO_TogglePin(LED_CAN_GPIO_Port, LED_CAN_Pin);
      }
      else
      {
          /*
           * Planned behavior:
           * LED_ERROR turns on if CAN transmit queueing fails.
           */
          HAL_GPIO_WritePin(LED_ERROR_GPIO_Port, LED_ERROR_Pin, GPIO_PIN_SET);
      }

      /*
       * Planned firmware heartbeat.
       */
      HAL_GPIO_TogglePin(LED_STATUS_GPIO_Port, LED_STATUS_Pin);

      /*
       * Planned transmit period: 100 ms.
       */
      HAL_Delay(TELEMETRY_PERIOD_MS);

    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
  RCC_PeriphCLKInitTypeDef PeriphClkInit = {0};

  /*
   * Initializes the RCC Oscillators according to the specified parameters
   * in the RCC_OscInitTypeDef structure.
   *
   * HSE = external 8 MHz crystal
   * PLL = HSE x9
   * SYSCLK = 72 MHz
   */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;

  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /*
   * Initializes the CPU, AHB, and APB bus clocks.
   *
   * HCLK  = 72 MHz
   * PCLK1 = 36 MHz
   * PCLK2 = 72 MHz
   *
   * APB1 is divided by 2 because STM32F103 APB1 max is 36 MHz.
   */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK |
                                RCC_CLOCKTYPE_SYSCLK |
                                RCC_CLOCKTYPE_PCLK1 |
                                RCC_CLOCKTYPE_PCLK2;

  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }

  /*
   * ADC clock prescaler.
   * APB2 = 72 MHz, ADC prescaler /8 gives ADC clock = 9 MHz.
   * This is safe for STM32F1 ADC operation.
   */
  PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_ADC;
  PeriphClkInit.AdcClockSelection = RCC_ADCPCLK2_DIV8;

  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */

  /*
   * Error handler for starter firmware.
   * If available, turn on LED_ERROR and stay here.
   *
   * This behavior is intended for future board bring-up.
   */
  HAL_GPIO_WritePin(LED_ERROR_GPIO_Port, LED_ERROR_Pin, GPIO_PIN_SET);

  __disable_irq();

  while (1)
  {
      /*
       * Stay here on error.
       */
  }

  /* USER CODE END Error_Handler_Debug */
}

#ifdef USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */

  /*
   * User can add reporting here later, for example through UART or debug output.
   * Not implemented in this starter firmware.
   */

  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
