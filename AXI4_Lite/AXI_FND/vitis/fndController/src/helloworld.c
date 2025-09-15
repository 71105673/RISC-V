/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <stdint.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"

typedef struct {
   uint32_t CR;
   uint32_t FDR;
} FND_TypeDef;

typedef struct{
   uint32_t CR;
   uint32_t ODR;
   uint32_t IDR;
} GPIO_TypeDef;

#define FND_BASEADDR  XPAR_FNDCONTROLLER_1_S00_AXI_BASEADDR
#define GPIO_BASEADDR XPAR_GPIO_1_S00_AXI_BASEADDR
#define FND         ((FND_TypeDef *)(FND_BASEADDR))
#define GPIO          ((GPIO_TypeDef *)(GPIO_BASEADDR))

void FND_Init(FND_TypeDef * fnd)
{
   fnd->CR = 0x01;
}

void FND_WriteData(FND_TypeDef * fnd, uint8_t data)
{
   fnd->FDR = data;
}

uint8_t FND_ReadData(FND_TypeDef * fnd)
{
   return fnd->FDR;
}

void GPIO_Init(GPIO_TypeDef * gpio, uint8_t data)
{
   gpio->CR = data;
}

void GPIO_WriteData(GPIO_TypeDef *gpio, uint8_t data)
{
   gpio->ODR = data;
}

uint8_t GPIO_ReadData(GPIO_TypeDef *gpio)
{
   return gpio->IDR;
}

int main()
{
   uint32_t counter = 0;
   uint8_t led = 0;

   FND_Init(FND);
   GPIO_Init(GPIO, 0x0f);

   while(1)
   {
      FND_WriteData(FND, counter);
      GPIO_WriteData(GPIO, led);
      counter++;
      led = led ^ 0x0f;
      usleep(100000);
   }

    return 0;
}
