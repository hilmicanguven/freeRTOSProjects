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


# Priority (Task Priority vs Hardware Priority)

Task priority, User Priority ve Application Priority, olarak da diyebiliriz. aslında bunlar "thread mode" da çalışan basit fonksiyonlar için verilen önceliklerdir. Hardware priority ise, Processor tarafından üretilen sistem exception'ları için verilen önceliklerdir. Genellikle bir "interrupt line'ın dan" işlemciye doğru yollar aracılığı ile üretilir. farklı mimarilerden mimariye göre değişir. çeşitli peripheral'lardan (ADC, UART, Timer vb) üretilebilir. "handler mode" da çalışırlar. 

bu ikisi birbirinden oldukça farklı konseptdir.
- Task Priortiy değeri yüksekse önceliği yüksektir. daha önemli ve öncelikli çalışır.
- Interrupt Priortiy değeri yüksekse daha önceliği düşüktür.

## Configurable freeRTOS Kernel Interrupt Priorites

- freeRTOS da STM32F4XX için priority için 4-bit ayrılmış durumdadır. `__NVIC_PRIO_BITS` ile kaç olduğunu görebiliriz. bu durumda 16 tane farklı priority değeri belirleyebiliriz (0x00 en yüksek öncelikli, 0xf0 en düşük öncelikli). 1 byte'ın yalnızca MSB 4bit'i ile konfigüre edilebilir.
- `configKERNEL_INTERRUPT_PRIORITY` , Kernel interruptları (sysTick, pendSV, SVC Handlers) için belirlenen priority değeridir. Verilebilecek en düşük sayısal değer verilmeye çalışılır.
- `configMAX_SYSCALL_INTERRUPT_PRIORITY` (yeni freeRTOS da ismi farklı -> `configMAX_API_CALL_INTERRUPT_PRIORITY` ), freeRTOS içerisinde bazı fonksiyonlar "XXX_FromISR" ile biter. bunların bir ISR'den çağırılabilmesi için bu definiton'ın belirttiği değerden ISR'in priority değeri büyük olmamalıdır. yani bu priority'den daha yüksek önceliğe sahip olmalıdır (daha az sayısal değere sahip olmalıdır).
- Bir örnek ile daha iyi açıklayalım. 8 priority level'e sahip bir işlemci düşünelim. priority 0 - en düşük öncelik ve priority 7 en yüksek öncelik. kernel interrupt'lara en yüksek önceliği veririz ve `configKERNEL_INTERRUPT_PRIORITY = 0` olsun. `configMAX_SYSCALL_INTERRUPT_PRIORITY = 4` olsun. priority eşik değeri.
    - bu doğrultuda, "FromISR" ile biten API'leri çağıran bir ISR'ımız olsun. eğer bu API'leri çağırmak isterse Priority değeri 0-1-2-3-4 olmalıdır. yani eşik değerine eşit veya daha düşük önceliğe sahip olmalıdır. **_ÇÜNKÜ BU EŞİK DEĞERİNİN ÜSTÜNDEKİ ÖNCELİĞE SAHİP ISR'LAR KESİNLİKLE BAŞKA BİR ŞEY TARAFINDAN DELAY EDİLEMEMELİDİR_**
- **Not:** "FromISR" ile biten freeRTOS API'lar interrupt safe olarak adlandırılır. ancak bu API'ler yeterli yüksek önceliğe (`configMAX_SYSCALL_INTERRUPT_PRIORITY` den daha ) sahip ISR'lar tarafından çağırılmamalıdır.
- **Not:** cortex-m interrupt'lar default olarak 0(zero) set edilir. eğer interrupt safe freeRTOS API's kullanılacaksa default değeri ile bırakmayıp konfigüre ediniz..


# Interrupt Safe APIs

Neden ayrı API'lere ihtiyaç duyarız bunu incelemek gerekirse 
- RTOS, çağıran task'ı blocked state'e geçirebilir ancak bunu ISR için değil de Task için yapılmasının bir mantığı olabilir ancak ISR için buna gerek yoktur. Kodları daha basit yapmak adına bu iki API'yi ayırır x() vs xFromISR()

- bazı API'ler için gereksiz yere parametre eklemiş oluruz. aslında kullanılmaz. xSemaphoreTake() düşünürsek "xTicksToWait" parametresi interrupt için anlamsızdır çünkü ISR'i blocked state de tutmayız. xSemaphoreTakeFromISR() için de yine sadece bunda kullanılan parametre bulunur ve diğerine eklemek gereksizdir.

Dezavantaj olarak,
- 3rd parti uygulamaların içerisinde eğer xFromISR() kullanılmıyorsa kodu düzenleyip bunu yapacak şekilde güncellemek gerekir.