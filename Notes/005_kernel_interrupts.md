Kernel Interrupts

Scheduling çalışması için gerekli bazı interrupt'lar bulunur.

1. SVC Interrupt        `vPortSVCHandler`     : SVC Handler
2. PendSV Interrupt     `xPortPendSVHandler`  : Context Switch
3. SysTick Interrupt    `xPortSysTickHandler` : SysTick Handler for RTOS Tick Management

# RTOS Tick (`xPortSysTickHandler`)

Global `xTickCount` değişkeni her interrupt'da artırılır.

Bu interrupt handler içerisinde
- ready task'lar scan edilir ve bir sonraki çalışacak task aranır.
- eğer çalışacak task varsa PendSV Interrupt(`xPortPendSVHandler`) tetiklenir.PendSV içerisinde Context Switch yapılır.

# RTOS Tick Timer and Configuration

Timer, mimariye özel olduğundan bu işlem `xPortStartScheduler` içerisinde yapılır.
- en düşük priority değeri (en yüksek öncelik) verilmeye çalışılır.


    /* Make PendSV and SysTick the lowest priority interrupts, and make SVCall * the highest priority. */
    
    portNVIC_SHPR3_REG |= portNVIC_PENDSV_PRI;
    portNVIC_SHPR3_REG |= portNVIC_SYSTICK_PRI;
    portNVIC_SHPR2_REG = 0;

- timer tick rate değeri belirlenir. systick load register'ı içerisine bir değer koyarız.
    timer yukarı (veya aşağı) doğru sayarak bu değere (veya sıfıra) ulaşınca interrupt üretir.
    CPU'nun Clock speed'ine göre bu sayma işleminin süresi belirlenir.
    Default olarak bu clock 16MHz ancak biz 25MHz olarak konfigüre ediyoruz. (System Core Clock)

    CPU _CLK_HZ = 25000000 (25MHz)
    configTICK_RATE_HZ = 1000Hz
    portSYSTICK_NVIC_LOAD_REG = (25000000/1000) - 1 = 24999
    
    Bu durumda, SysTick timer çalışmaya başladığında 24999 dan 0'a kadar sayar ve sıfıra ulaştığında interrupt üretir. bu da 1 ms'ye denk gelir.

    /* Start the timer that generates the tick ISR.  Interrupts are disabled here already. */
    vPortSetupTimerInterrupt();

        /* Configure SysTick to interrupt at the requested rate. */
        portNVIC_SYSTICK_LOAD_REG = ( configSYSTICK_CLOCK_HZ / configTICK_RATE_HZ ) - 1UL;
        portNVIC_SYSTICK_CTRL_REG = ( portNVIC_SYSTICK_CLK_BIT_CONFIG | portNVIC_SYSTICK_INT_BIT | portNVIC_SYSTICK_ENABLE_BIT );


- interrupt enable edilir

RTOS Tik Rate 1000 olarak ayarlandığında her 1 ms'de bir tick interrupt oluşacak. 
peki bunu nerede ve kim tarafından ayarlıyoruz? bunun için



