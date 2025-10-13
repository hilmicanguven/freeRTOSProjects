# Hook in OSs

Biraz formal tanımlarını ekleyelim.

- **Hook:** Control point that allows custom code to “intercept” or “attach” to certain system events or function calls. Hooks let developers insert their own functionality into the normal flow of an operating system or program — without modifying its main logic
- **Hook Point:** Specific location in the OS (or in a program’s code) where a hook can be attached.
- **Hook function:** (or “callback”) is the custom code you attach to a hook point. This function will be called automatically by the system when that point in the execution is reached.

## freeRTOS Hook Functions

freeRTOS içerisinde kullanılan Hook fonksiyonları,
- `vApplicationIdleHook()` : (configUSE_IDLE_HOOK == 1) : Idle task esnasına yapılmak istenen işlemler yapılabilir, 
    - MCU'yu low-power-mode'a gönderme gibi. (Reference Manuel Table 23)
    - ek bir task overhead'i oluşturmadan, idle task içerisinde background'da yapılmak istenen işlemler yapılabilmesi için
    - WFI instruction'ı ile bir IRQ isteği gelene kadar CPU bekler -> `HAL_PWR_EnterSleepMode(...)`
- `vApplicationTickHook()` : (configUSE_TICK_HOOK == 1)
- `vApplicationMallocFailedHook()` : (configUSE_MALLOC_FAILED_HOOK == 1)  : Malloc çağrısı esnasında eğer heap tükenir ve işlem hataya düşerse bu hook fonksiyon ile kullanıcı bildirilir.
- `vApplicationStackOverflowHook(...)` : (configCHECK_FOR_STACK_OVERFLOW == 1) : Stack overflow durumu esnasında çağırılır. task'ın sahip oldupu stack'ten taşması örnek verilebilir.


**_Not:_**  Enable edilip gerekli fonksiyonlar oluşturulmaz ise undefined reference hatası verecektir.

**_Not:_** Idle Task, vTaskScheduler tarafından otomatik oluşturulur. Priority değeri sıfırdır.
