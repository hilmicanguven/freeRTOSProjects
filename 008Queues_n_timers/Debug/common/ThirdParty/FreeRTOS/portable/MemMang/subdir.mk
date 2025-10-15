################################################################################
# Automatically-generated file. Do not edit!
# Toolchain: GNU Tools for STM32 (11.3.rel1)
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
D:/freeRTOS/rtos_workspace/common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.c 

OBJS += \
./common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.o 

C_DEPS += \
./common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.d 


# Each subdirectory must supply rules for building sources it contributes
common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.o: D:/freeRTOS/rtos_workspace/common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.c common/ThirdParty/FreeRTOS/portable/MemMang/subdir.mk
	arm-none-eabi-gcc "$<" -mcpu=cortex-m4 -std=gnu11 -g3 -DUSE_HAL_DRIVER -DDEBUG -DSTM32F407xx -c -I../Drivers/CMSIS/Include -I../Drivers/STM32F4xx_HAL_Driver/Inc -I../Core/Inc -I../Drivers/CMSIS/Device/ST/STM32F4xx/Include -I../Drivers/STM32F4xx_HAL_Driver/Inc/Legacy -I"D:/freeRTOS/rtos_workspace/common/ThirdParty/FreeRTOS/include" -I"D:/freeRTOS/rtos_workspace/common/ThirdParty/FreeRTOS/portable/GCC/ARM_CM4F" -I"D:/freeRTOS/rtos_workspace/common/ThirdParty/SEGGER/Config" -I"D:/freeRTOS/rtos_workspace/common/ThirdParty/SEGGER/OS" -I"D:/freeRTOS/rtos_workspace/common/ThirdParty/SEGGER/SEGGER" -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -fcyclomatic-complexity -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -o "$@"

clean: clean-common-2f-ThirdParty-2f-FreeRTOS-2f-portable-2f-MemMang

clean-common-2f-ThirdParty-2f-FreeRTOS-2f-portable-2f-MemMang:
	-$(RM) ./common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.cyclo ./common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.d ./common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.o ./common/ThirdParty/FreeRTOS/portable/MemMang/heap_4.su

.PHONY: clean-common-2f-ThirdParty-2f-FreeRTOS-2f-portable-2f-MemMang

